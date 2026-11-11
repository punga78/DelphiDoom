{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the overlay drawer                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of TOverlayDrawer of psi_overlay.pas. The drawing code is the one of   }
{  the old class (the same pixels in the same order); what it read from the    }
{  engine (video, lumps, font, level time) comes from an IOverlayCanvas.       }
{                                                                              }
{******************************************************************************}
// The arithmetic of the fixed point steps of the stretched patch wraps on purpose
{$Q-}
{$R-}
unit DelphiDoom.ScriptHost.Overlay.Drawer;

interface

uses
  DelphiDoom.ScriptHost.Overlay.Intf,
  DelphiDoom.ScriptHost.Overlay.Types;

type
  /// <summary>
  ///   What scripts draw over the game: a list of things to draw for some tics (the "drawers"),
  ///   drawn into a 320x200 buffer of palette indexes, and the table that maps the pixels of the
  ///   screen to the pixels of that buffer. It is the class Overlay of the scripts (TOverlay)
  /// </summary>
  TOverlayDrawer = class(TObject)
  strict private
    FCanvas: IOverlayCanvas;
    FOverlayScreen: POverlayBuffer;
    FBackBuffer: POverlayBuffer;
    FOverlayLookup: POverlayLookup;
    FOverlayLookupSize: Integer;
    FFirstOverlayLookup: TOverlayIndexes;
    FLastOverlayLookup: TOverlayIndexes;
    FDrawers: POverlayDrawerRecordArray;
    FNumDrawers: Integer;
    FRealNumDrawers: Integer;
    FModified: Boolean;
    FLastDrawCount: Integer;
    FStart: Integer;
    FEnd: Integer;
    procedure Setup(const ACanvas: IOverlayCanvas);
    procedure CalcOverlayLookUp;
    procedure ClearScreen;
    procedure Grow;
    function NewDrawer(const AKind, ATicks: Integer): POverlayDrawerRecord;
    function PatchLump(const APatchName: string): Integer;
    procedure DrawPatch(const X, Y: Integer; const ALump: Integer); overload;
    procedure DrawPatch(const X, Y: Integer; const APatch: Pointer); overload;
    procedure DrawPatchStretched(const X1, Y1, X2, Y2: Integer; const ALump: Integer); overload;
    procedure DrawPatchStretched(const X1, Y1, X2, Y2: Integer; const APatch: Pointer); overload;
    procedure DrawPixel(const X, Y: Integer; const ARed, AGreen, ABlue: Byte);
    procedure DrawRect(const X1, Y1, X2, Y2: Integer; const ARed, AGreen, ABlue: Byte);
    procedure DrawLine(const X1, Y1, X2, Y2: Integer; const ARed, AGreen, ABlue: Byte);
    procedure DrawText(const AText: string; const AAlign: Integer; const X, Y: Integer);
    procedure DrawDrawer(const AIndex: Integer);
    procedure NotifyDrawSize(const AStart, AEnd: Integer);
    function BufferPosition(const X, Y: Integer): Integer;
  public
    /// <summary>
    ///   The constructor that a script calls (TOverlay.Create): an overlay with no screen, whose
    ///   canvas has no patches and no font
    /// </summary>
    constructor Create; virtual;
    /// <summary>The overlay of the game, over the screen and the lumps of the canvas</summary>
    /// <exception cref="EArgumentNilException">If the canvas is nil</exception>
    constructor CreateWithCanvas(const ACanvas: IOverlayCanvas);
    destructor Destroy; override;
    /// <summary>Writes the drawers on a savegame (the count and the records) and moves the pointer past them</summary>
    procedure SaveToBuffer(var ABuffer: Pointer);
    /// <summary>Reads the drawers from a savegame and moves the pointer past them</summary>
    procedure LoadFromBuffer(var ABuffer: Pointer);
    /// <summary>The number of bytes that SaveToBuffer writes</summary>
    function SaveSize: Integer;
    /// <summary>Forgets every drawer and clears the buffer</summary>
    procedure Clear; virtual;
    procedure AddPatch(const ATicks: Integer; const APatchName: string; const X, Y: Integer);
    procedure AddPatchStretched(const ATicks: Integer; const APatchName: string;
      const X1, Y1, X2, Y2: Integer);
    procedure AddPixel(const ATicks: Integer; const ARed, AGreen, ABlue: Byte; const X, Y: Integer);
    procedure AddRect(const ATicks: Integer; const ARed, AGreen, ABlue: Byte;
      const X1, Y1, X2, Y2: Integer);
    procedure AddLine(const ATicks: Integer; const ARed, AGreen, ABlue: Byte;
      const X1, Y1, X2, Y2: Integer);
    procedure AddText(const ATicks: Integer; const AText: string; const AAlign: Integer;
      const X, Y: Integer);
    procedure AddLeftText(const ATicks: Integer; const AText: string; const X, Y: Integer);
    procedure AddRightText(const ATicks: Integer; const AText: string; const X, Y: Integer);
    procedure AddCenterText(const ATicks: Integer; const AText: string; const X, Y: Integer);
    /// <summary>Puts the overlay over the frame (nothing if no drawer is alive or nothing was drawn)</summary>
    procedure FlashToScreen;
    /// <summary>The lines of the screen that the overlay covers, from the top: for the OpenGL texture</summary>
    function GetOverlayHeight: Integer;
    /// <summary>Makes the table of the screen pixels again (the screen has a new size)</summary>
    procedure ReCalcOverlayLookUp;
    /// <summary>Clears the buffer and draws again every drawer that is alive, forgetting those that are over</summary>
    procedure DrawDrawers;
    /// <summary>True if the last DrawDrawers drew a different number of drawers than the one before</summary>
    property Modified: Boolean read FModified;
    /// <summary>The 320x200 buffer of palette indexes (0 is transparent)</summary>
    property OverlayScreen: POverlayBuffer read FOverlayScreen;
    property NumDrawers: Integer read FNumDrawers;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  DelphiDoom.ScriptHost.Overlay.NullCanvas;

const
  OVR_GROWSTEP = 8;
  OVR_FRACUNIT = 65536;
  /// <summary>The offset of the first column of a patch: after the header</summary>
  OVR_COLUMNS_OFFSET = SizeOf(TOverlayPatchHeader);

type
  /// <summary>The patch of a lump, as Doom stores it, seen byte by byte</summary>
  TOverlayPatchView = record
    class function Column(const APatch: Pointer; const AIndex: Integer): POverlayPatchPost; static;
    class function Next(const AColumn: POverlayPatchPost): POverlayPatchPost; static;
    class function Pixels(const AColumn: POverlayPatchPost): PByte; static;
  end;

class function TOverlayPatchView.Column(const APatch: Pointer;
  const AIndex: Integer): POverlayPatchPost;
begin
  Result := POverlayPatchPost(PByte(APatch) +
    PInteger(PByte(APatch) + OVR_COLUMNS_OFFSET + AIndex * SizeOf(Integer))^);
end;

class function TOverlayPatchView.Next(const AColumn: POverlayPatchPost): POverlayPatchPost;
begin
  Result := POverlayPatchPost(PByte(AColumn) + AColumn.Length + 4);
end;

class function TOverlayPatchView.Pixels(const AColumn: POverlayPatchPost): PByte;
begin
  Result := PByte(AColumn) + 3;
end;

// the characters of the text that is stored: only a..z become upper case (as the old strupper)
function OverlayUpperCase(const AText: string): string;
var
  LIndex: Integer;
  LChar: Char;
begin
  SetLength(Result, Length(AText));
  for LIndex := 1 to Length(AText) do
  begin
    LChar := AText[LIndex];
    if (LChar >= 'a') and (LChar <= 'z') then
      Dec(LChar, 32);
    Result[LIndex] := LChar;
  end;
end;

{ TOverlayDrawer }

constructor TOverlayDrawer.Create;
begin
  inherited Create;
  Setup(TOverlayNullCanvas.Create);
end;

constructor TOverlayDrawer.CreateWithCanvas(const ACanvas: IOverlayCanvas);
begin
  inherited Create;
  if not Assigned(ACanvas) then
    raise EArgumentNilException.Create('ACanvas');
  Setup(ACanvas);
end;

procedure TOverlayDrawer.Setup(const ACanvas: IOverlayCanvas);
begin
  FCanvas := ACanvas;
  GetMem(FOverlayScreen, OVERLAYSIZE);
  FBackBuffer := AllocMem(OVERLAYSIZE);
  FOverlayLookupSize := FCanvas.ScreenWidth * FCanvas.ScreenHeight * SizeOf(PByte);
  GetMem(FOverlayLookup, FOverlayLookupSize);
  CalcOverlayLookUp;
  GetMem(FDrawers, OVR_GROWSTEP * SizeOf(TOverlayDrawerRecord));
  FNumDrawers := 0;
  FRealNumDrawers := OVR_GROWSTEP;
  FStart := 0;
  FEnd := OVERLAYSIZE - 1;
  ClearScreen;
  FModified := False;
  FLastDrawCount := 0;
end;

destructor TOverlayDrawer.Destroy;
begin
  FreeMem(FDrawers);
  FreeMem(FOverlayLookup);
  FreeMem(FOverlayScreen);
  FreeMem(FBackBuffer);
  inherited;
end;

procedure TOverlayDrawer.CalcOverlayLookUp;
var
  LIndex: Integer;
  LX, LY: Integer;
  LWidth, LHeight: Integer;
  LTargetX, LTargetY: Integer;
  LPosition: Integer;
begin
  for LIndex := 0 to OVERLAYSIZE - 1 do
  begin
    FFirstOverlayLookup[LIndex] := MaxInt;
    FLastOverlayLookup[LIndex] := 0;
  end;
  LIndex := 0;
  LWidth := FCanvas.ScreenWidth;
  LHeight := FCanvas.ScreenHeight;
  for LY := 0 to LHeight - 1 do
  begin
    LTargetY := Trunc(LY / LHeight * OVERLAYHEIGHT);
    if LTargetY >= OVERLAYHEIGHT then
      LTargetY := OVERLAYHEIGHT - 1
    else if LTargetY < 0 then
      LTargetY := 0;
    for LX := 0 to LWidth - 1 do
    begin
      LTargetX := Trunc(LX / LWidth * OVERLAYWIDTH);
      if LTargetX >= OVERLAYWIDTH then
        LTargetX := OVERLAYWIDTH - 1
      else if LTargetX < 0 then
        LTargetX := 0;
      LPosition := BufferPosition(LTargetX, LTargetY);
      FOverlayLookup[LIndex] := @FOverlayScreen[LPosition];
      if FFirstOverlayLookup[LPosition] > LIndex then
        FFirstOverlayLookup[LPosition] := LIndex;
      if FLastOverlayLookup[LPosition] < LIndex then
        FLastOverlayLookup[LPosition] := LIndex;
      Inc(LIndex);
    end;
  end;
end;

procedure TOverlayDrawer.ReCalcOverlayLookUp;
begin
  FreeMem(FOverlayLookup);
  FOverlayLookupSize := FCanvas.ScreenWidth * FCanvas.ScreenHeight * SizeOf(PByte);
  GetMem(FOverlayLookup, FOverlayLookupSize);
  CalcOverlayLookUp;
end;

procedure TOverlayDrawer.SaveToBuffer(var ABuffer: Pointer);
var
  LSize: Integer;
begin
  PInteger(ABuffer)^ := FNumDrawers;
  ABuffer := PByte(ABuffer) + SizeOf(Integer);
  LSize := FNumDrawers * SizeOf(TOverlayDrawerRecord);
  if LSize > 0 then
    Move(FDrawers[0], ABuffer^, LSize);
  ABuffer := PByte(ABuffer) + LSize;
end;

procedure TOverlayDrawer.LoadFromBuffer(var ABuffer: Pointer);
var
  LSize: Integer;
begin
  FNumDrawers := PInteger(ABuffer)^;
  // a negative count would ask for a negative block
  if FNumDrawers < 0 then
    FNumDrawers := 0;
  ABuffer := PByte(ABuffer) + SizeOf(Integer);
  LSize := FNumDrawers * SizeOf(TOverlayDrawerRecord);
  ReallocMem(FDrawers, LSize);
  FRealNumDrawers := FNumDrawers;
  if LSize > 0 then
    Move(ABuffer^, FDrawers[0], LSize);
  ABuffer := PByte(ABuffer) + LSize;
  ClearScreen;
end;

function TOverlayDrawer.SaveSize: Integer;
begin
  Result := SizeOf(Integer) + FNumDrawers * SizeOf(TOverlayDrawerRecord);
end;

procedure TOverlayDrawer.Clear;
begin
  FNumDrawers := 0;
  ReallocMem(FDrawers, OVR_GROWSTEP * SizeOf(TOverlayDrawerRecord));
  FRealNumDrawers := OVR_GROWSTEP;
  ClearScreen;
end;

procedure TOverlayDrawer.ClearScreen;
begin
  if FStart <= FEnd then
    FillChar(FOverlayScreen[FStart], FEnd - FStart + 1, 0);
  FStart := OVERLAYSIZE;
  FEnd := -1;
end;

procedure TOverlayDrawer.Grow;
begin
  if FNumDrawers = FRealNumDrawers then
  begin
    ReallocMem(FDrawers, (FRealNumDrawers + OVR_GROWSTEP) * SizeOf(TOverlayDrawerRecord));
    FRealNumDrawers := FRealNumDrawers + OVR_GROWSTEP;
  end;
end;

function TOverlayDrawer.NewDrawer(const AKind, ATicks: Integer): POverlayDrawerRecord;
begin
  Grow;
  Result := @FDrawers[FNumDrawers];
  Inc(FNumDrawers);
  // the old class left the fields that a kind does not use as they were in memory
  FillChar(Result^, SizeOf(TOverlayDrawerRecord), 0);
  Result.Kind := AKind;
  Result.Tick := FCanvas.LevelTime + ATicks;
end;

procedure TOverlayDrawer.DrawPatch(const X, Y: Integer; const ALump: Integer);
var
  LPatch: Pointer;
begin
  if ALump < 0 then
    Exit;

  LPatch := FCanvas.CachePatch(ALump);
  if Assigned(LPatch) then
    DrawPatch(X, Y, LPatch);
end;

procedure TOverlayDrawer.DrawPatch(const X, Y: Integer; const APatch: Pointer);
var
  LHeader: POverlayPatchHeader;
  LFirstX: Integer;
  LPosition: Integer;
  LDestinationTop: PByte;
  LWidth, LColumnIndex: Integer;
  LColumn: POverlayPatchPost;
  LDestination: PByte;
  LSource: PByte;
  LCount: Integer;
  LStart, LFinish, LCurrent: Integer;
  LDelta, LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LHeader := APatch;
  LFirstX := X - LHeader.LeftOffset;
  LPosition := BufferPosition(LFirstX, Y - LHeader.TopOffset);

  LDestinationTop := PByte(FOverlayScreen) + LPosition;

  LColumnIndex := 0;
  LWidth := LHeader.Width;
  if LWidth = 0 then
    Exit;

  while LColumnIndex < LWidth do
  begin
    LColumn := TOverlayPatchView.Column(APatch, LColumnIndex);
    LDelta := 0;
    LTallPatch := False;
    // step through the posts in a column
    while LColumn.TopDelta <> $FF do
    begin
      LSource := TOverlayPatchView.Pixels(LColumn);
      LDelta := LDelta + LColumn.TopDelta;
      LDestination := LDestinationTop + LDelta * OVERLAYWIDTH;
      LCount := LColumn.Length;

      LStart := Integer(NativeInt(LDestination) - NativeInt(FOverlayScreen));
      LFinish := LStart + OVERLAYWIDTH * (LCount - 1);
      if ((LStart >= 0) and (LStart < OVERLAYSIZE)) or
         ((LFinish >= 0) and (LFinish < OVERLAYSIZE)) then
        if (LFirstX >= 0) and (LFirstX < OVERLAYWIDTH) then
        begin
          LCurrent := LStart;
          while LCount > 0 do
          begin
            if (LCurrent >= 0) and (LCurrent < OVERLAYSIZE) then
              LDestination^ := LSource^;
            Inc(LSource);
            Inc(LDestination, OVERLAYWIDTH);
            Inc(LCurrent, OVERLAYWIDTH);
            Dec(LCount);
          end;
          NotifyDrawSize(LStart, LFinish);
        end;
      if not LTallPatch then
      begin
        LPreviousDelta := LColumn.TopDelta;
        LColumn := TOverlayPatchView.Next(LColumn);
        if LColumn.TopDelta > LPreviousDelta then
          LDelta := 0
        else
          LTallPatch := True;
      end
      else
        LColumn := TOverlayPatchView.Next(LColumn);
    end;
    Inc(LColumnIndex);
    Inc(LFirstX);
    Inc(LDestinationTop);
  end;
end;

procedure TOverlayDrawer.DrawPatchStretched(const X1, Y1, X2, Y2: Integer; const ALump: Integer);
var
  LPatch: Pointer;
begin
  if ALump < 0 then
    Exit;

  LPatch := FCanvas.CachePatch(ALump);
  if Assigned(LPatch) then
    DrawPatchStretched(X1, Y1, X2, Y2, LPatch);
end;

procedure TOverlayDrawer.DrawPatchStretched(const X1, Y1, X2, Y2: Integer; const APatch: Pointer);
var
  LHeader: POverlayPatchHeader;
  LDestinationTop: PByte;
  LWidth, LColumnIndex: Integer;
  LColumn: POverlayPatchPost;
  LDestination: PByte;
  LSource: PByte;
  LCount: Integer;
  LStart, LFinish: Integer;
  LDelta, LPreviousDelta: Integer;
  LTallPatch: Boolean;
  LMinSize, LMaxSize: Integer;
  LFracXStep, LFracYStep: Integer;
  LFracX, LFracY: Integer;
  LScreenRows: POverlayRows;
  LBufferRows: POverlayRows;
  X, Y: Integer;
  LXStep, LYStep: Integer;
  LValue: Byte;
begin
  if (X1 = X2) or (Y1 = Y2) then
    Exit;

  LHeader := APatch;
  LDestinationTop := PByte(FBackBuffer);

  LColumnIndex := 0;
  LWidth := LHeader.Width;
  if LWidth = 0 then
    Exit;

  LMaxSize := 0;
  LMinSize := OVERLAYSIZE;

  while LColumnIndex < LWidth do
  begin
    LColumn := TOverlayPatchView.Column(APatch, LColumnIndex);
    LDelta := 0;
    LTallPatch := False;
    // step through the posts in a column
    while LColumn.TopDelta <> $FF do
    begin
      LSource := TOverlayPatchView.Pixels(LColumn);
      LDelta := LDelta + LColumn.TopDelta;
      LDestination := LDestinationTop + LDelta * OVERLAYWIDTH;
      LCount := LColumn.Length;

      LStart := Integer(NativeInt(LDestination) - NativeInt(FBackBuffer));
      LFinish := LStart + OVERLAYWIDTH * (LCount - 1);
      if (LStart >= 0) and (LStart < OVERLAYSIZE) and
         (LFinish >= 0) and (LFinish < OVERLAYSIZE) then
      begin
        while LCount > 0 do
        begin
          LDestination^ := LSource^;
          Inc(LSource);
          Inc(LDestination, OVERLAYWIDTH);
          Dec(LCount);
        end;
        if LMaxSize < LFinish then
          LMaxSize := LFinish;
        if LMinSize > LStart then
          LMinSize := LStart;
      end;
      if not LTallPatch then
      begin
        LPreviousDelta := LColumn.TopDelta;
        LColumn := TOverlayPatchView.Next(LColumn);
        if LColumn.TopDelta > LPreviousDelta then
          LDelta := 0
        else
          LTallPatch := True;
      end
      else
        LColumn := TOverlayPatchView.Next(LColumn);
    end;
    Inc(LColumnIndex);
    Inc(LDestinationTop);
  end;

  if LMinSize > LMaxSize then
    Exit;

  LScreenRows := POverlayRows(FOverlayScreen);
  LBufferRows := POverlayRows(FBackBuffer);

  LFracXStep := (LHeader.Width * OVR_FRACUNIT) div (X2 - X1);
  LFracYStep := (LHeader.Height * OVR_FRACUNIT) div (Y2 - Y1);

  if X1 < X2 then
    LXStep := 1
  else
  begin
    LXStep := -1;
    LFracXStep := -LFracXStep;
  end;
  if Y1 < Y2 then
    LYStep := 1
  else
  begin
    LYStep := -1;
    LFracYStep := -LFracYStep;
  end;

  LFracY := 0;
  Y := Y1;
  while Y <> Y2 do
  begin
    if (Y >= 0) and (Y < OVERLAYHEIGHT) then
    begin
      LFracX := 0;
      X := X1;
      while X <> X2 do
      begin
        LValue := LBufferRows[LFracY div OVR_FRACUNIT, LFracX div OVR_FRACUNIT];
        if LValue <> 0 then
          if (X >= 0) and (X < OVERLAYWIDTH) then
            LScreenRows[Y, X] := LValue;
        LFracX := LFracX + LFracXStep;
        X := X + LXStep;
      end;
    end;
    LFracY := LFracY + LFracYStep;
    Y := Y + LYStep;
  end;

  NotifyDrawSize(BufferPosition(Min(X1, X2), Min(Y1, Y2)), BufferPosition(Max(X1, X2), Max(Y1, Y2)));
  FillChar(FBackBuffer[LMinSize], LMaxSize - LMinSize + 1, 0);
end;

procedure TOverlayDrawer.DrawPixel(const X, Y: Integer; const ARed, AGreen, ABlue: Byte);
var
  LPosition: Integer;
begin
  LPosition := BufferPosition(X, Y);
  if (LPosition >= 0) and (LPosition < OVERLAYSIZE) then
  begin
    FOverlayScreen[LPosition] := FCanvas.FindColorIndex(ARed, AGreen, ABlue);
    NotifyDrawSize(LPosition, LPosition);
  end;
end;

procedure TOverlayDrawer.DrawRect(const X1, Y1, X2, Y2: Integer; const ARed, AGreen, ABlue: Byte);
var
  LPosition1: Integer;
  LPosition2: Integer;
  LPixel: PByte;
  LColor: Byte;
  X, Y: Integer;
  LLeft, LRight, LTop, LBottom: Integer;
begin
  LColor := FCanvas.FindColorIndex(ARed, AGreen, ABlue);

  LLeft := EnsureRange(X1, 0, OVERLAYWIDTH - 1);
  LRight := EnsureRange(X2, 0, OVERLAYWIDTH - 1);
  // the old code clamped the rows with the width: a rectangle taller than the buffer wrote
  // past it (corrected, a test covers it)
  LTop := EnsureRange(Y1, 0, OVERLAYHEIGHT - 1);
  LBottom := EnsureRange(Y2, 0, OVERLAYHEIGHT - 1);
  for Y := LTop to LBottom do
  begin
    LPosition1 := BufferPosition(LLeft, Y);
    LPixel := @FOverlayScreen[LPosition1];
    for X := LLeft to LRight do
    begin
      LPixel^ := LColor;
      Inc(LPixel);
    end;
  end;
  LPosition1 := BufferPosition(LLeft, LTop);
  LPosition2 := BufferPosition(LRight, LBottom);
  NotifyDrawSize(LPosition1, LPosition2);
end;

// Bresenham's Line Algorithm.  Byte, March 1988, pp. 249-253.
// Modified from http://www.efg2.com/Lab/Library/Delphi/Graphics/Bresenham.txt and tested.
procedure TOverlayDrawer.DrawLine(const X1, Y1, X2, Y2: Integer; const ARed, AGreen, ABlue: Byte);
var
  LColor: Byte;
  LPosition1: Integer;
  LPosition2: Integer;
  LPixel: PByte;
  LLeft, LRight, LTop, LBottom: Integer;
  A, B: Integer;           // displacements in x and y
  D: Integer;              // decision variable
  LDiagonalIncrement: Integer;
  LDiagonalX: Integer;
  LNonDiagonalX: Integer;
  LDiagonalY: Integer;
  LNonDiagonalY: Integer;
  I: Integer;              // loop index
  LNonDiagonalIncrement: Integer;
  LSwap: Integer;
  X, Y: Integer;           // current x and y coordinates
begin
  LColor := FCanvas.FindColorIndex(ARed, AGreen, ABlue);
  LPosition1 := BufferPosition(X1, Y1);
  LPosition2 := BufferPosition(X2, Y2);
  NotifyDrawSize(LPosition1, LPosition2); // JVAL: Inaccurate, since we haven't check clipping yet

  // Special case - Horizontal line
  if Y1 = Y2 then
  begin
    if (Y1 >= 0) and (Y1 <= OVERLAYHEIGHT - 1) then
    begin
      LLeft := EnsureRange(X1, 0, OVERLAYWIDTH - 1);
      LRight := EnsureRange(X2, 0, OVERLAYWIDTH - 1);
      LPosition1 := BufferPosition(LLeft, Y1);
      LPixel := @FOverlayScreen[LPosition1];
      for X := LLeft to LRight do
      begin
        LPixel^ := LColor;
        Inc(LPixel);
      end;
    end;
    Exit;
  end;

  // Special case - Verical line
  if X1 = X2 then
  begin
    if (X1 >= 0) and (X1 <= OVERLAYWIDTH - 1) then
    begin
      LTop := EnsureRange(Y1, 0, OVERLAYHEIGHT - 1);
      LBottom := EnsureRange(Y2, 0, OVERLAYHEIGHT - 1);
      LPosition1 := BufferPosition(X1, LTop);
      LPixel := @FOverlayScreen[LPosition1];
      for Y := LTop to LBottom do
      begin
        LPixel^ := LColor;
        Inc(LPixel, OVERLAYWIDTH);
      end;
    end;
    Exit;
  end;

  X := X1;              // line starting point
  Y := Y1;
  // Determine drawing direction and step to the next pixel.
  A := X2 - X1;         // difference in x dimension
  B := Y2 - Y1;         // difference in y dimension
  // Determine whether end point lies to right or left of start point.
  if A < 0 then         // drawing towards smaller x values?
  begin
    A := -A;            // make 'a' positive
    LDiagonalX := -1
  end
  else
    LDiagonalX := 1;

  // Determine whether end point lies above or below start point.
  if B < 0 then         // drawing towards smaller x values?
  begin
    B := -B;            // make 'a' positive
    LDiagonalY := -1
  end
  else
    LDiagonalY := 1;

  // Identify octant containing end point.
  if A < B then
  begin
    LSwap := A;
    A := B;
    B := LSwap;
    LNonDiagonalX := 0;
    LNonDiagonalY := LDiagonalY
  end
  else
  begin
    LNonDiagonalX := LDiagonalX;
    LNonDiagonalY := 0
  end;

  D := B + B - A;       // initial value for d is 2*b - a
  LNonDiagonalIncrement := B + B; // set initial d increment values
  LDiagonalIncrement := B + B - A - A;
  for I := 0 to A do
  begin   /// draw the a+1 pixels
    LPosition1 := BufferPosition(X, Y);
    // the old test was (x >= 0) and (y < OVERLAYSIZE): a line that went above the buffer or far
    // below it wrote outside of it (corrected, a test covers it)
    if (X >= 0) and (LPosition1 >= 0) and (LPosition1 < OVERLAYSIZE) then
      FOverlayScreen[LPosition1] := LColor;
    if D < 0 then       // is midpoint above the line?
    begin               // step nondiagonally
      X := X + LNonDiagonalX;
      Y := Y + LNonDiagonalY;
      D := D + LNonDiagonalIncrement  // update decision variable
    end
    else
    begin               // midpoint is above the line; step diagonally}
      X := X + LDiagonalX;
      Y := Y + LDiagonalY;
      D := D + LDiagonalIncrement
    end;
  end;
end;

procedure TOverlayDrawer.DrawText(const AText: string; const AAlign: Integer;
  const X, Y: Integer);
var
  LIndex: Integer;
  LLength: Integer;
  LTextWidth: Integer;
  LPatch: Pointer;
  LFirstX: Integer;

  procedure CalcTextWidth;
  begin
    LIndex := 1;
    LTextWidth := 0;
    while LIndex <= LLength do
    begin
      LPatch := FCanvas.FontPatch(AText[LIndex]);
      if Assigned(LPatch) then
        LTextWidth := LTextWidth + POverlayPatchHeader(LPatch).Width + 1
      else
        LTextWidth := LTextWidth + 4;
      Inc(LIndex);
    end;
  end;

begin
  LLength := Length(AText);

  if AAlign = OVR_ALIGN_CENTER then
  begin
    CalcTextWidth;
    LFirstX := X - LTextWidth div 2;
  end
  else if AAlign = OVR_ALIGN_RIGHT then
  begin
    CalcTextWidth;
    LFirstX := X - LTextWidth;
  end
  else
    LFirstX := X;

  LIndex := 1;
  while LIndex <= LLength do
  begin
    LPatch := FCanvas.FontPatch(AText[LIndex]);
    if Assigned(LPatch) then
    begin
      DrawPatch(LFirstX, Y, LPatch);
      LFirstX := LFirstX + (POverlayPatchHeader(LPatch).Width + 1);
    end
    else
      LFirstX := LFirstX + 4;
    Inc(LIndex);
  end;
end;

procedure TOverlayDrawer.DrawDrawer(const AIndex: Integer);
var
  LDrawer: POverlayDrawerRecord;
begin
  LDrawer := @FDrawers[AIndex];
  case LDrawer.Kind of
    OVR_DRAWTEXT:
      DrawText(string(LDrawer.TextParameter), LDrawer.Parameter1, LDrawer.X, LDrawer.Y);
    OVR_DRAWPATCH:
      DrawPatch(LDrawer.X, LDrawer.Y, LDrawer.Parameter1);
    OVR_DRAWPIXEL:
      DrawPixel(LDrawer.X, LDrawer.Y, LDrawer.Parameter1, LDrawer.Parameter2, LDrawer.Parameter3);
    OVR_DRAWRECT:
      DrawRect(LDrawer.X, LDrawer.Y, LDrawer.X2, LDrawer.Y2, LDrawer.Parameter1,
        LDrawer.Parameter2, LDrawer.Parameter3);
    OVR_DRAWLINE:
      DrawLine(LDrawer.X, LDrawer.Y, LDrawer.X2, LDrawer.Y2, LDrawer.Parameter1,
        LDrawer.Parameter2, LDrawer.Parameter3);
    OVR_DRAWPATCHSTRETCHED:
      DrawPatchStretched(LDrawer.X, LDrawer.Y, LDrawer.X2, LDrawer.Y2, LDrawer.Parameter1);
  else
    FCanvas.Warning(Format('TOverlayDrawer.DrawDrawer(): Unknown drawer type "%d"'#13#10,
      [LDrawer.Kind]));
  end;
end;

procedure TOverlayDrawer.NotifyDrawSize(const AStart, AEnd: Integer);
begin
  if AStart < FStart then
  begin
    FStart := AStart;
    if FStart < 0 then
      FStart := 0
    else if FStart >= OVERLAYSIZE then
      FStart := OVERLAYSIZE - 1;
  end;
  if AEnd > FEnd then
  begin
    FEnd := AEnd;
    if FEnd < 0 then
      FEnd := 0
    else if FEnd >= OVERLAYSIZE then
      FEnd := OVERLAYSIZE - 1;
  end;
end;

function TOverlayDrawer.BufferPosition(const X, Y: Integer): Integer;
begin
  Result := X + Y * OVERLAYWIDTH;
end;

function TOverlayDrawer.PatchLump(const APatchName: string): Integer;
var
  LName: string;
begin
  LName := APatchName;
  if Length(LName) > 8 then
  begin
    SetLength(LName, 8);
    FCanvas.Warning(Format('TOverlayDrawer.AddPatch(): Patch name "%s" has more than 8 characters, truncated to "%s"'#13#10,
      [APatchName, LName]));
  end;
  Result := FCanvas.FindPatchLump(LName);
  if Result < 0 then
    FCanvas.Warning(Format('TOverlayDrawer.AddPatch(): Invalid patch "%s"'#13#10, [LName]));
end;

procedure TOverlayDrawer.AddPatch(const ATicks: Integer; const APatchName: string;
  const X, Y: Integer);
var
  LLump: Integer;
  LDrawer: POverlayDrawerRecord;
begin
  if ATicks < 0 then
    Exit;

  LLump := PatchLump(APatchName);
  if LLump < 0 then
    Exit;

  LDrawer := NewDrawer(OVR_DRAWPATCH, ATicks);
  LDrawer.X := X;
  LDrawer.Y := Y;
  LDrawer.Parameter1 := LLump;
  LDrawer.TextParameter := ShortString(APatchName);
end;

procedure TOverlayDrawer.AddPatchStretched(const ATicks: Integer; const APatchName: string;
  const X1, Y1, X2, Y2: Integer);
var
  LLump: Integer;
  LDrawer: POverlayDrawerRecord;
begin
  if ATicks < 0 then
    Exit;

  LLump := PatchLump(APatchName);
  if LLump < 0 then
    Exit;

  LDrawer := NewDrawer(OVR_DRAWPATCHSTRETCHED, ATicks);
  LDrawer.X := X1;
  LDrawer.Y := Y1;
  LDrawer.X2 := X2;
  LDrawer.Y2 := Y2;
  LDrawer.Parameter1 := LLump;
  LDrawer.TextParameter := ShortString(APatchName);
end;

procedure TOverlayDrawer.AddPixel(const ATicks: Integer; const ARed, AGreen, ABlue: Byte;
  const X, Y: Integer);
var
  LDrawer: POverlayDrawerRecord;
begin
  if ATicks < 0 then
    Exit;

  LDrawer := NewDrawer(OVR_DRAWPIXEL, ATicks);
  LDrawer.X := X;
  LDrawer.Y := Y;
  LDrawer.Parameter1 := ARed;
  LDrawer.Parameter2 := AGreen;
  LDrawer.Parameter3 := ABlue;
end;

procedure TOverlayDrawer.AddRect(const ATicks: Integer; const ARed, AGreen, ABlue: Byte;
  const X1, Y1, X2, Y2: Integer);
var
  LDrawer: POverlayDrawerRecord;
begin
  if ATicks < 0 then
    Exit;

  LDrawer := NewDrawer(OVR_DRAWRECT, ATicks);
  LDrawer.X := X1;
  LDrawer.Y := Y1;
  LDrawer.X2 := X2;
  LDrawer.Y2 := Y2;
  LDrawer.Parameter1 := ARed;
  LDrawer.Parameter2 := AGreen;
  LDrawer.Parameter3 := ABlue;
end;

procedure TOverlayDrawer.AddLine(const ATicks: Integer; const ARed, AGreen, ABlue: Byte;
  const X1, Y1, X2, Y2: Integer);
var
  LDrawer: POverlayDrawerRecord;
begin
  if ATicks < 0 then
    Exit;

  LDrawer := NewDrawer(OVR_DRAWLINE, ATicks);
  LDrawer.X := X1;
  LDrawer.Y := Y1;
  LDrawer.X2 := X2;
  LDrawer.Y2 := Y2;
  LDrawer.Parameter1 := ARed;
  LDrawer.Parameter2 := AGreen;
  LDrawer.Parameter3 := ABlue;
end;

procedure TOverlayDrawer.AddText(const ATicks: Integer; const AText: string;
  const AAlign: Integer; const X, Y: Integer);
var
  LDrawer: POverlayDrawerRecord;
begin
  if ATicks < 0 then
    Exit;

  LDrawer := NewDrawer(OVR_DRAWTEXT, ATicks);
  LDrawer.X := X;
  LDrawer.Y := Y;
  LDrawer.TextParameter := ShortString(OverlayUpperCase(AText));
  LDrawer.Parameter1 := AAlign;
end;

procedure TOverlayDrawer.AddLeftText(const ATicks: Integer; const AText: string;
  const X, Y: Integer);
begin
  AddText(ATicks, AText, OVR_ALIGN_LEFT, X, Y);
end;

procedure TOverlayDrawer.AddRightText(const ATicks: Integer; const AText: string;
  const X, Y: Integer);
begin
  AddText(ATicks, AText, OVR_ALIGN_RIGHT, X, Y);
end;

procedure TOverlayDrawer.AddCenterText(const ATicks: Integer; const AText: string;
  const X, Y: Integer);
begin
  AddText(ATicks, AText, OVR_ALIGN_CENTER, X, Y);
end;

procedure TOverlayDrawer.DrawDrawers;
var
  I, J: Integer;
  LDead, LDrawn: Integer;
  LLevelTime: Integer;
begin
  ClearScreen;
  LLevelTime := FCanvas.LevelTime;
  LDead := 0;
  LDrawn := 0;
  for I := 0 to FNumDrawers - 1 do
    if LLevelTime <= FDrawers[I].Tick then
    begin
      DrawDrawer(I);
      Inc(LDrawn);
    end
    else
    begin
      Inc(LDead);
      FDrawers[I].Kind := 0;
    end;

  if LDead > 0 then
  begin
    J := 0;
    for I := 0 to FNumDrawers - 1 do
    begin
      if J < I then
      begin
        if FDrawers[I].Kind <> 0 then
        begin
          FDrawers[J] := FDrawers[I];
          Inc(J);
        end;
      end
      else if FDrawers[I].Kind <> 0 then
        Inc(J);
    end;
    FNumDrawers := J;
  end;
  FModified := FLastDrawCount <> LDrawn;
  FLastDrawCount := LDrawn;
  if FModified then
    FCanvas.MarkScreenDirty;
end;

function TOverlayDrawer.GetOverlayHeight: Integer;
var
  LLast: Integer;
  LWidth: Integer;
begin
  if FEnd < 0 then
    Exit(0);
  LLast := FLastOverlayLookup[FEnd];
  LWidth := FCanvas.ScreenWidth;
  Result := (LLast + LWidth) div LWidth;
  if Result > FCanvas.ScreenHeight then
    Result := FCanvas.ScreenHeight;
end;

procedure TOverlayDrawer.FlashToScreen;
var
  LData: TOverlayFlashData;
begin
  if FNumDrawers = 0 then
    Exit;

  if FCanvas.IsFirstInterpolation then
    DrawDrawers;

  if FEnd - FStart < 0 then
    Exit;

  LData.Lookup := FOverlayLookup;
  LData.FirstLookup := @FFirstOverlayLookup;
  LData.LastLookup := @FLastOverlayLookup;
  LData.Start := FStart;
  LData.Finish := FEnd;
  FCanvas.Flash(LData);
end;

end.
