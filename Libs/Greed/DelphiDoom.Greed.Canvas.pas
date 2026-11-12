{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the 8 bit buffer of the status bar and the HUD   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the drawing routines of     }
{  d_video.pas and I_TranslateBuffer and I_FinishUpdate8 of i_video.pas         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Canvas;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Frame.Intf;

const
  /// <summary>MAX_VIEW_WIDTH and MAX_VIEW_HEIGHT: the size of the viewbuffer of the original</summary>
  GREED_CANVAS_WIDTH = 320;
  GREED_CANVAS_HEIGHT = 200;
  /// <summary>The lump TRANSPARENCY: 256 tables of 256 colors</summary>
  GREED_TRANSPARENCY_BYTES = 256 * 256;

type
  /// <summary>
  ///   The viewbuffer of the original (screen, ylookup and, after UpdateView has set the view size back, viewylookup
  ///   are all this buffer): 320 x 200 color indexes, a row after the other, cleared to 0 at each frame. The weapon,
  ///   the status bar, the HUD and the messages are drawn here; the color 0 is "nothing here" and the 640 x 400
  ///   picture of the level shows through it (ComposeOnto), which is why the original turns the 0 of a solid picture
  ///   into the color of the palette nearest to the color 0 (ApproxZero). A picture is the lump as it is (pic_t:
  ///   width, height, origin x and y as words, then the rows).
  ///   Difference from the original: what falls outside the buffer is not drawn (the original has no check in most
  ///   routines: a pixel beyond the right edge lands on the next row and one beyond the last row outside the buffer)
  /// </summary>
  TGreedCanvas = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FPixels: TBytes;
    FApproxZero: Byte;
    FTransparency: TBytes;
    class procedure ReadHeader(const APicture: TBytes; out AWidth, AHeight, AOriginX, AOriginY: Integer); static;
    procedure DrawSolid(AX, AY: Integer; const APicture: TBytes);
  public
    constructor Create(AWidth: Integer = GREED_CANVAS_WIDTH; AHeight: Integer = GREED_CANVAS_HEIGHT);
    /// <summary>memset(viewbuffer, 0): what SetupFrame does before each picture</summary>
    procedure Clear;
    /// <summary>ylookup[y][x]; 0 outside the buffer</summary>
    function GetPixel(AX, AY: Integer): Byte; inline;
    /// <summary>ylookup[y][x] := value (the low byte of the value); nothing outside the buffer</summary>
    procedure PutPixel(AX, AY, AValue: Integer); inline;
    /// <summary>
    ///   memset(@ylookup[y][x], value, count): bytes that follow each other in the buffer (past the end of a row
    ///   they go on in the next one, as in the original); the part outside the buffer is not written
    /// </summary>
    procedure FillRow(AX, AY, ACount, AValue: Integer);
    /// <summary>I_TranslateBuffer: each 0 becomes ApproxZero</summary>
    procedure TranslateBuffer(var ABuffer: TBytes; AOffset, ACount: Integer);
    /// <summary>
    ///   VI_DrawPicSolid: the rows of the picture are copied, the origin is not used. As in the original the
    ///   PICTURE ITSELF is changed first (its 0 become ApproxZero and stay so: the hearts of the status bar are
    ///   later drawn "masked" and by then have no 0 left)
    /// </summary>
    procedure DrawPicSolid(AX, AY: Integer; const APicture: TBytes);
    /// <summary>VI_DrawPicSolidUntranslated: the rows are copied as they are</summary>
    procedure DrawPicSolidUntranslated(AX, AY: Integer; const APicture: TBytes);
    /// <summary>VI_DrawMaskedPic: the origin of the picture goes on the position, the color 0 is not drawn</summary>
    procedure DrawMaskedPic(AX, AY: Integer; const APicture: TBytes);
    /// <summary>VI_DrawMaskedPicToBuffer: the same on the view buffer (here the same buffer)</summary>
    procedure DrawMaskedPicToBuffer(AX, AY: Integer; const APicture: TBytes);
    /// <summary>
    ///   VI_DrawMaskedPicToBuffer2 without the choice of the color table (the caller gives the 256 bytes of the
    ///   light where the player stands): the origin is not used, the picture is cut at AWindowHeight, a color that
    ///   the table turns into 0 becomes ApproxZero
    /// </summary>
    procedure DrawMaskedPicToBuffer2(AX, AY: Integer; const APicture: TBytes; AColormap: PByte;
      AWindowHeight: Integer);
    /// <summary>
    ///   VI_DrawTransPicToBuffer: each color but 0 is mixed with what is below through the table of the lump
    ///   TRANSPARENCY (translookup[color - 1][below]). Nothing is drawn if the table was not given
    /// </summary>
    procedure DrawTransPicToBuffer(AX, AY: Integer; const APicture: TBytes);
    /// <summary>
    ///   The second half of I_FinishUpdate8: each pixel of the buffer that is not 0 covers the pixels of the frame
    ///   it stands for (the frame is a whole number of times as large: 640 x 400 for 320 x 200)
    /// </summary>
    procedure ComposeOnto(var AFrame: TGreedFrame);
    /// <summary>The lump TRANSPARENCY (65536 bytes), for DrawTransPicToBuffer</summary>
    procedure SetTransparency(const ATable: TBytes);
    /// <summary>pic.width and pic.height of a picture lump; 0 if the lump has no header</summary>
    class function PictureWidth(const APicture: TBytes): Integer; static;
    class function PictureHeight(const APicture: TBytes): Integer; static;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    /// <summary>The buffer itself, Width * Height bytes</summary>
    property Pixels: TBytes read FPixels;
    /// <summary>approx_zero of i_video.pas: see TGreedPaletteFader.ApproximateZero</summary>
    property ApproxZero: Byte read FApproxZero write FApproxZero;
  end;

implementation

uses
  DelphiDoom.Greed.LittleEndian;

{ TGreedCanvas }

constructor TGreedCanvas.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  if (AWidth < 1) or (AHeight < 1) then
    raise EGreedException.CreateFmt(SGreedImageSize, [AWidth, AHeight, 'canvas']);
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FPixels, AWidth * AHeight);
  Clear;
end;

procedure TGreedCanvas.Clear;
begin
  FillChar(FPixels[0], Length(FPixels), 0);
end;

function TGreedCanvas.GetPixel(AX, AY: Integer): Byte;
begin
  if (AX < 0) or (AX >= FWidth) or (AY < 0) or (AY >= FHeight) then
    Result := 0
  else
    Result := FPixels[AY * FWidth + AX];
end;

procedure TGreedCanvas.PutPixel(AX, AY, AValue: Integer);
begin
  if (AX >= 0) and (AX < FWidth) and (AY >= 0) and (AY < FHeight) then
    FPixels[AY * FWidth + AX] := Byte(AValue and $FF);
end;

procedure TGreedCanvas.FillRow(AX, AY, ACount, AValue: Integer);
var
  LFirst: Integer;
  LLast: Integer;
begin
  LFirst := AY * FWidth + AX;
  LLast := LFirst + ACount - 1;
  if LFirst < 0 then
    LFirst := 0;
  if LLast > High(FPixels) then
    LLast := High(FPixels);
  if LLast >= LFirst then
    FillChar(FPixels[LFirst], LLast - LFirst + 1, Byte(AValue and $FF));
end;

procedure TGreedCanvas.TranslateBuffer(var ABuffer: TBytes; AOffset, ACount: Integer);
var
  LIndex: Integer;
begin
  if AOffset < 0 then
  begin
    ACount := ACount + AOffset;
    AOffset := 0;
  end;
  if AOffset + ACount > Length(ABuffer) then
    ACount := Length(ABuffer) - AOffset;
  for LIndex := AOffset to AOffset + ACount - 1 do
    if ABuffer[LIndex] = 0 then
      ABuffer[LIndex] := FApproxZero;
end;

class procedure TGreedCanvas.ReadHeader(const APicture: TBytes; out AWidth, AHeight, AOriginX,
  AOriginY: Integer);
begin
  if Length(APicture) < GREED_PICTURE_HEADER_BYTES then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort,
      ['picture', Length(APicture), GREED_PICTURE_HEADER_BYTES]);
  AWidth := TGreedLittleEndian.ReadSmallInt(APicture, 0);
  AHeight := TGreedLittleEndian.ReadSmallInt(APicture, 2);
  AOriginX := TGreedLittleEndian.ReadSmallInt(APicture, 4);
  AOriginY := TGreedLittleEndian.ReadSmallInt(APicture, 6);
  if (AWidth < 0) or (AHeight < 0) or
    (Length(APicture) < GREED_PICTURE_HEADER_BYTES + Int64(AWidth) * AHeight) then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort,
      ['picture', Length(APicture), GREED_PICTURE_HEADER_BYTES + Int64(AWidth) * AHeight]);
end;

class function TGreedCanvas.PictureWidth(const APicture: TBytes): Integer;
begin
  if Length(APicture) < GREED_PICTURE_HEADER_BYTES then
    Result := 0
  else
    Result := TGreedLittleEndian.ReadSmallInt(APicture, 0);
end;

class function TGreedCanvas.PictureHeight(const APicture: TBytes): Integer;
begin
  if Length(APicture) < GREED_PICTURE_HEADER_BYTES then
    Result := 0
  else
    Result := TGreedLittleEndian.ReadSmallInt(APicture, 2);
end;

procedure TGreedCanvas.DrawSolid(AX, AY: Integer; const APicture: TBytes);
var
  LWidth, LHeight, LOriginX, LOriginY: Integer;
  LRow: Integer;
  LFirst: Integer;
  LCount: Integer;
  LY: Integer;
begin
  ReadHeader(APicture, LWidth, LHeight, LOriginX, LOriginY);
  // the part of each row that is inside the buffer
  LFirst := 0;
  if AX < 0 then
    LFirst := -AX;
  LCount := LWidth - LFirst;
  if AX + LWidth > FWidth then
    LCount := FWidth - AX - LFirst;
  if LCount <= 0 then
    Exit;
  for LRow := 0 to LHeight - 1 do
  begin
    LY := AY + LRow;
    if (LY >= 0) and (LY < FHeight) then
      Move(APicture[GREED_PICTURE_HEADER_BYTES + LRow * LWidth + LFirst], FPixels[LY * FWidth + AX + LFirst],
        LCount);
  end;
end;

procedure TGreedCanvas.DrawPicSolid(AX, AY: Integer; const APicture: TBytes);
var
  LWidth, LHeight, LOriginX, LOriginY: Integer;
  LPicture: TBytes;
begin
  ReadHeader(APicture, LWidth, LHeight, LOriginX, LOriginY);
  // the same array as the caller's: a dynamic array is a reference, the picture of the caller changes
  LPicture := APicture;
  TranslateBuffer(LPicture, GREED_PICTURE_HEADER_BYTES, LWidth * LHeight);
  DrawSolid(AX, AY, APicture);
end;

procedure TGreedCanvas.DrawPicSolidUntranslated(AX, AY: Integer; const APicture: TBytes);
begin
  DrawSolid(AX, AY, APicture);
end;

procedure TGreedCanvas.DrawMaskedPic(AX, AY: Integer; const APicture: TBytes);
var
  LWidth, LHeight, LOriginX, LOriginY: Integer;
  LRow: Integer;
  LColumn: Integer;
  LX, LY: Integer;
  LSource: Integer;
  LColor: Byte;
begin
  ReadHeader(APicture, LWidth, LHeight, LOriginX, LOriginY);
  AX := AX - LOriginX;
  AY := AY - LOriginY;
  for LRow := 0 to LHeight - 1 do
  begin
    LY := AY + LRow;
    if (LY < 0) or (LY >= FHeight) then
      Continue;
    LSource := GREED_PICTURE_HEADER_BYTES + LRow * LWidth;
    for LColumn := 0 to LWidth - 1 do
    begin
      LX := AX + LColumn;
      LColor := APicture[LSource + LColumn];
      if (LX >= 0) and (LX < FWidth) and (LColor <> 0) then
        FPixels[LY * FWidth + LX] := LColor;
    end;
  end;
end;

procedure TGreedCanvas.DrawMaskedPicToBuffer(AX, AY: Integer; const APicture: TBytes);
begin
  DrawMaskedPic(AX, AY, APicture);
end;

procedure TGreedCanvas.DrawMaskedPicToBuffer2(AX, AY: Integer; const APicture: TBytes; AColormap: PByte;
  AWindowHeight: Integer);
var
  LWidth, LHeight, LOriginX, LOriginY: Integer;
  LRow: Integer;
  LColumn: Integer;
  LX, LY: Integer;
  LSource: Integer;
  LColor: Byte;
begin
  if not Assigned(AColormap) then
    raise EArgumentNilException.Create('AColormap');
  ReadHeader(APicture, LWidth, LHeight, LOriginX, LOriginY);
  if LHeight + AY > AWindowHeight then
    LHeight := AWindowHeight - AY;
  for LRow := 0 to LHeight - 1 do
  begin
    LY := AY + LRow;
    if (LY < 0) or (LY >= FHeight) then
      Continue;
    LSource := GREED_PICTURE_HEADER_BYTES + LRow * LWidth;
    for LColumn := 0 to LWidth - 1 do
    begin
      LX := AX + LColumn;
      LColor := APicture[LSource + LColumn];
      if (LColor <> 0) and (LX >= 0) and (LX < FWidth) then
      begin
        LColor := PByte(NativeUInt(AColormap) + LColor)^;
        if LColor = 0 then
          LColor := FApproxZero;
        FPixels[LY * FWidth + LX] := LColor;
      end;
    end;
  end;
end;

procedure TGreedCanvas.DrawTransPicToBuffer(AX, AY: Integer; const APicture: TBytes);
var
  LWidth, LHeight, LOriginX, LOriginY: Integer;
  LRow: Integer;
  LColumn: Integer;
  LX, LY: Integer;
  LSource: Integer;
  LColor: Byte;
  LDest: Integer;
begin
  ReadHeader(APicture, LWidth, LHeight, LOriginX, LOriginY);
  if Length(FTransparency) < GREED_TRANSPARENCY_BYTES then
    Exit;
  AX := AX - LOriginX;
  AY := AY - LOriginY;
  for LRow := 0 to LHeight - 1 do
  begin
    LY := AY + LRow;
    if (LY < 0) or (LY >= FHeight) then
      Continue;
    LSource := GREED_PICTURE_HEADER_BYTES + LRow * LWidth;
    for LColumn := 0 to LWidth - 1 do
    begin
      LX := AX + LColumn;
      LColor := APicture[LSource + LColumn];
      if (LColor <> 0) and (LX >= 0) and (LX < FWidth) then
      begin
        LDest := LY * FWidth + LX;
        FPixels[LDest] := FTransparency[(LColor - 1) * 256 + FPixels[LDest]];
      end;
    end;
  end;
end;

procedure TGreedCanvas.ComposeOnto(var AFrame: TGreedFrame);
var
  LScaleX, LScaleY: Integer;
  LX, LY: Integer;
  LRow: Integer;
  LColor: Byte;
begin
  if (AFrame.Width < FWidth) or (AFrame.Height < FHeight) or (AFrame.Width mod FWidth <> 0) or
    (AFrame.Height mod FHeight <> 0) or (Length(AFrame.Pixels) < AFrame.Width * AFrame.Height) then
    raise EGreedException.CreateFmt(SGreedImageSize, [AFrame.Width, AFrame.Height, 'frame under the canvas']);
  LScaleX := AFrame.Width div FWidth;
  LScaleY := AFrame.Height div FHeight;
  for LY := 0 to AFrame.Height - 1 do
  begin
    LRow := (LY div LScaleY) * FWidth;
    for LX := 0 to AFrame.Width - 1 do
    begin
      LColor := FPixels[LRow + LX div LScaleX];
      if LColor <> 0 then
        AFrame.Pixels[LY * AFrame.Width + LX] := LColor;
    end;
  end;
end;

procedure TGreedCanvas.SetTransparency(const ATable: TBytes);
begin
  FTransparency := ATable;
end;

end.
