{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiMarkerWindow (markerDef)                      }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\MarkerWindow.h,         }
{  MarkerWindow.cpp (idMarkerWindow: the parse). Copyright (C) 1999-2011 id    }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Marker;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context,
  DelphiDoom.Gui.Window, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Material.Intf, DelphiDoom.Gui.Window.Keys;

type
  /// <summary>markerData_t: a marker of a demo (the time, the picture and where it is drawn)</summary>
  TGuiMarkerData = record
    Time: Integer;
    Material: IGuiMaterial;
    Rect: TGuiRectangle;
  end;

  /// <summary>
  ///   idMarkerWindow: the keys <c>markerMat</c>, <c>markerStop</c> (material names) and <c>markerColor</c>.
  ///   It reads the logged statistics of a demo (<c>statData</c>), draws the markers and the position of the cursor in\n  ///   time, and asks the game to go to a marker. The picture of the statistics goes to <c>IGuiScratchImages</c>.
  /// </summary>
  TGuiMarkerWindow = class(TGuiWindow)
  strict private
    FMarkerMaterial: AnsiString;
    FMarkerStopMaterial: AnsiString;
    FMarkerColor: TIdVec4;
    FMarkerMat: IGuiMaterial;
    FMarkerStop: IGuiMaterial;
    FMarkers: TList<TGuiMarkerData>;
    FStatData: AnsiString;
    FNumStats: Integer;
    FCurrentMarker: Integer;
    FCurrentTime: Integer;
    FStopTime: Integer;
    procedure Point(const AX, AY: Integer; var AImage: TArray<Cardinal>; const AColor: Cardinal);
    procedure Line(AX1, AY1, AX2, AY2: Integer; var AImage: TArray<Cardinal>; const AColor: Cardinal);
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString; override;
    function RouteMouseCoords(const AX, AY: Single): AnsiString; override;
    procedure Draw(const ATime: Integer; const AX, AY: Single); override;
    procedure Activate(const AActivate: Boolean; var AAct: AnsiString); override;
    property Markers: TList<TGuiMarkerData> read FMarkers;
    property CurrentMarker: Integer read FCurrentMarker;
    property CurrentTime: Integer read FCurrentTime;
    property StopTime: Integer read FStopTime;
    property NumStats: Integer read FNumStats;
    property MarkerMaterial: AnsiString read FMarkerMaterial;
    property MarkerStopMaterial: AnsiString read FMarkerStopMaterial;
    property MarkerColor: TIdVec4 read FMarkerColor;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Gui.Window.Types, DelphiDoom.Gui.DrawContext;

const
  HEALTH_MAX = 100;
  COMBAT_MAX = 100;
  RATE_MAX = 125;
  STAMINA_MAX = 12;
  MAX_LOGGED_STATS = 3600;

constructor TGuiMarkerWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FMarkerColor.Zero;
  FMarkers := TList<TGuiMarkerData>.Create;
  FCurrentTime := -1;
  FCurrentMarker := -1;
  FStopTime := -1;
end;

destructor TGuiMarkerWindow.Destroy;
begin
  FMarkers.Free;
  inherited Destroy;
end;

function TGuiMarkerWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
begin
  Result := True;
  if TIdStrings.Icmp(AName, 'markerMat') = 0 then
  begin
    ParseString(ASource, FMarkerMaterial);
    if Assigned(Context.Materials) then
    begin
      FMarkerMat := Context.Materials.FindMaterial(FMarkerMaterial);
      FMarkerMat.SetGuiSort;
    end;
  end
  else if TIdStrings.Icmp(AName, 'markerStop') = 0 then
  begin
    ParseString(ASource, FMarkerStopMaterial);
    if Assigned(Context.Materials) then
    begin
      FMarkerStop := Context.Materials.FindMaterial(FMarkerStopMaterial);
      FMarkerStop.SetGuiSort;
    end;
  end
  else if TIdStrings.Icmp(AName, 'markerColor') = 0 then
    ParseVec4(ASource, FMarkerColor)
  else
    Result := inherited ParseInternalVar(AName, ASource);
end;

// idStr::StripPath and StripFileExtension
function BaseName(const AName: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := AName;
  for LIndex := Length(Result) downto 1 do
    if (Result[LIndex] = '/') or (Result[LIndex] = '\') then
    begin
      Result := Copy(Result, LIndex + 1, MaxInt);
      Break;
    end;
  for LIndex := Length(Result) downto 1 do
    if Result[LIndex] = '.' then
    begin
      Result := Copy(Result, 1, LIndex - 1);
      Break;
    end;
end;

function TimeText(const ATime: Integer): AnsiString;
begin
  Result := AnsiString(Format('%.2d:%.2d', [ATime div 60 div 60, (ATime div 60) mod 60]));
end;

function TGuiMarkerWindow.HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString;
var
  LKey, LIndex, LLength: Integer;
  LPct: Single;
  LData: TGuiMarkerData;
  LDesktop: TGuiWindow;
begin
  Result := '';
  if not ((AEvent.EventType = GUI_SE_KEY) and (AEvent.Value2 <> 0)) then
    Exit;
  LKey := AEvent.Value;
  LDesktop := Context.Desktop as TGuiWindow;
  if (AEvent.Value2 <> 0) and (LKey = GUI_K_MOUSE1) then
  begin
    LDesktop.SetChildWinVarVal('markerText', 'text', '');
    LIndex := 0;
    while LIndex < FMarkers.Count do
    begin
      LData := FMarkers[LIndex];
      if LData.Rect.Contains(Context.CursorX, Context.CursorY) then
      begin
        FCurrentMarker := LIndex;
        Context.StateDict.SetInt('currentMarker', LData.Time);
        FStopTime := LData.Time;
        LDesktop.SetChildWinVarVal('markerText', 'text', 'Marker set at ' + TimeText(LData.Time));
        LDesktop.SetChildWinVarVal('markerText', 'visible', '1');
        LDesktop.SetChildWinVarVal('markerBackground', 'matcolor', '1 1 1 1');
        LDesktop.SetChildWinVarVal('markerBackground', 'text', '');
        LDesktop.SetChildWinVarVal('markerBackground', 'background', LData.Material.GetName);
        Break;
      end;
      Inc(LIndex);
    end;
    if LIndex = FMarkers.Count then
    begin
      FCurrentMarker := -1;
      Context.StateDict.SetInt('currentMarker', FCurrentTime);
      FStopTime := FCurrentTime;
      LDesktop.SetChildWinVarVal('markerText', 'text', 'Marker set at ' + TimeText(FCurrentTime));
      LDesktop.SetChildWinVarVal('markerText', 'visible', '1');
      LDesktop.SetChildWinVarVal('markerBackground', 'matcolor', '0 0 0 0');
      LDesktop.SetChildWinVarVal('markerBackground', 'text', 'No Preview');
    end;
    LPct := Context.StateDict.GetFloat('loadPct');
    LLength := Context.StateDict.GetInt('loadLength');
    if FStopTime > LLength * LPct then
      Result := 'cmdDemoGotoMarker';
  end
  else if LKey = GUI_K_MOUSE2 then
  begin
    FStopTime := -1;
    LDesktop.SetChildWinVarVal('markerText', 'text', '');
    Context.StateDict.SetInt('currentMarker', -1);
    Result := 'cmdDemoGotoMarker';
  end
  else if LKey = GUI_K_SPACE then
    Result := 'cmdDemoPauseFrame';
end;

procedure TGuiMarkerWindow.Draw(const ATime: Integer; const AX, AY: Single);
var
  LRect: TGuiRectangle;
  LLength, LIndex: Integer;
  LData: TGuiMarkerData;
  LPct, LTemp: Single;
  LDc: TGuiDrawContext;
begin
  LDc := Context.DrawContext;
  if (not Assigned(FMarkerMat)) and Assigned(Context.Materials) and (FMarkerMaterial <> '') then
  begin
    FMarkerMat := Context.Materials.FindMaterial(FMarkerMaterial);
    FMarkerMat.SetGuiSort;
  end;
  if (not Assigned(FMarkerStop)) and Assigned(Context.Materials) and (FMarkerStopMaterial <> '') then
  begin
    FMarkerStop := Context.Materials.FindMaterial(FMarkerStopMaterial);
    FMarkerStop.SetGuiSort;
  end;
  LRect := ClientRect;
  LLength := Context.StateDict.GetInt('loadLength');
  if LLength = 0 then
    LLength := 1;
  if (FNumStats > 1) and (FMarkers.Count > 0) then
    for LIndex := 0 to FMarkers.Count - 1 do
    begin
      LData := FMarkers[LIndex];
      if LData.Rect.W = 0 then
      begin
        LTemp := LData.Time;
        LTemp := LTemp / LLength;
        LTemp := LRect.W * LTemp;
        LTemp := LRect.X + LTemp;
        LData.Rect.X := LTemp - 8;
        LData.Rect.Y := LRect.Y + LRect.H - 20;
        LData.Rect.W := 16;
        LData.Rect.H := 16;
        FMarkers[LIndex] := LData;
      end;
      LDc.DrawMaterial(LData.Rect.X, LData.Rect.Y, LData.Rect.W, LData.Rect.H, FMarkerMat, FMarkerColor);
    end;
  LRect.Y := LRect.Y + 10;
  if (LRect.W > 0) and LRect.Contains(Context.CursorX, Context.CursorY) then
  begin
    LPct := Context.CursorX - LRect.X;
    LPct := LPct / LRect.W;
    LTemp := LLength * LPct;
    FCurrentTime := TIdMath.Ftoi(LTemp);
    if Context.CursorX > LRect.X + LRect.W - 40 then
      LRect.X := Context.CursorX - 40
    else
      LRect.X := Context.CursorX;
    LRect.Y := Context.CursorY - 15;
    LRect.W := 40;
    LRect.H := 20;
    LDc.DrawText(TimeText(FCurrentTime), 0.25, 0, LDc.ColorWhite, LRect, False);
  end;
  if (FStopTime >= 0) and Assigned(FMarkerStop) then
  begin
    LRect := ClientRect;
    LRect.Y := LRect.Y + (LRect.H - 32) / 2;
    LPct := FStopTime;
    LPct := LPct / LLength;
    LTemp := LRect.W * LPct;
    LRect.X := LRect.X + LTemp - 16;
    LDc.DrawMaterial(LRect.X, LRect.Y, 32, 32, FMarkerStop, TIdVec4.Create(1, 1, 1, 0.65));
  end;
end;

function TGuiMarkerWindow.RouteMouseCoords(const AX, AY: Single): AnsiString;
var
  LIndex: Integer;
  LData: TGuiMarkerData;
  LDesktop: TGuiWindow;
begin
  Result := inherited RouteMouseCoords(AX, AY);
  LDesktop := Context.Desktop as TGuiWindow;
  LIndex := 0;
  while LIndex < FMarkers.Count do
  begin
    LData := FMarkers[LIndex];
    // the original gives the coordinates of the cursor to Contains the wrong way round
    if LData.Rect.Contains(Context.CursorY, Context.CursorX) then
    begin
      LDesktop.SetChildWinVarVal('markerBackground', 'background', LData.Material.GetName);
      LDesktop.SetChildWinVarVal('markerBackground', 'matcolor', '1 1 1 1');
      LDesktop.SetChildWinVarVal('markerBackground', 'text', '');
      Break;
    end;
    Inc(LIndex);
  end;
  if LIndex >= FMarkers.Count then
  begin
    if FCurrentMarker = -1 then
    begin
      LDesktop.SetChildWinVarVal('markerBackground', 'matcolor', '0 0 0 0');
      LDesktop.SetChildWinVarVal('markerBackground', 'text', 'No Preview');
    end
    else if FCurrentMarker < FMarkers.Count then
    begin
      LData := FMarkers[FCurrentMarker];
      LDesktop.SetChildWinVarVal('markerBackground', 'background', LData.Material.GetName);
      LDesktop.SetChildWinVarVal('markerBackground', 'matcolor', '1 1 1 1');
      LDesktop.SetChildWinVarVal('markerBackground', 'text', '');
    end;
  end;
end;

procedure TGuiMarkerWindow.Point(const AX, AY: Integer; var AImage: TArray<Cardinal>; const AColor: Cardinal);
var
  LIndex: Integer;
begin
  LIndex := (63 - AY) * 512 + AX;
  if (LIndex >= 0) and (LIndex < 512 * 64) then
    AImage[LIndex] := AColor
  else
    Warning(Format('Out of bounds on point %d : %d', [AX, AY]));
end;

procedure TGuiMarkerWindow.Line(AX1, AY1, AX2, AY2: Integer; var AImage: TArray<Cardinal>; const AColor: Cardinal);
var
  LDeltaX, LDeltaY, LIncX, LIncY, LRight, LUp, LDir: Integer;
begin
  LDeltaX := Abs(AX2 - AX1);
  LDeltaY := Abs(AY2 - AY1);
  if AX1 > AX2 then
    LIncX := -1
  else
    LIncX := 1;
  if AY1 > AY2 then
    LIncY := -1
  else
    LIncY := 1;
  if LDeltaX > LDeltaY then
  begin
    LRight := LDeltaY * 2;
    LUp := LRight - LDeltaX * 2;
    LDir := LRight - LDeltaX;
    while LDeltaX >= 0 do
    begin
      Dec(LDeltaX);
      Point(AX1, AY1, AImage, AColor);
      Inc(AX1, LIncX);
      if LDir > 0 then
        Inc(AY1, LIncY);
      if LDir > 0 then
        Inc(LDir, LUp)
      else
        Inc(LDir, LRight);
    end;
  end
  else
  begin
    LRight := LDeltaX * 2;
    LUp := LRight - LDeltaY * 2;
    LDir := LRight - LDeltaY;
    while LDeltaY >= 0 do
    begin
      Dec(LDeltaY);
      Point(AX1, AY1, AImage, AColor);
      if LDir > 0 then
        Inc(AX1, LIncX);
      Inc(AY1, LIncY);
      if LDir > 0 then
        Inc(LDir, LUp)
      else
        Inc(LDir, LRight);
    end;
  end;
end;

procedure TGuiMarkerWindow.Activate(const AActivate: Boolean; var AAct: AnsiString);
type
  TStat = record
    Health: Integer;
    HeartRate: Integer;
    Stamina: Integer;
    Combat: Integer;
  end;
var
  LFile: TIdLibFileData;
  LStats: array of TStat;
  LImage: TArray<Cardinal>;
  LIndex: Integer;
  LNames: TArray<AnsiString>;
  LName: AnsiString;
  LData: TGuiMarkerData;
  LStep, LX1, LY1, LX2, LY2: Single;
  LDesktop: TGuiWindow;

  function StatAt(const AIndex: Integer): TStat;
  begin
    Result := LStats[AIndex];
  end;

  function Scaled(const AFactor, AValue, AMax: Integer): Single;
  begin
    Result := AValue;
    Result := Result / AMax;
    Result := AFactor * Result;
  end;

begin
  inherited Activate(AActivate, AAct);
  if not AActivate then
    Exit;
  LDesktop := Context.Desktop as TGuiWindow;
  LDesktop.SetChildWinVarVal('markerText', 'text', '');
  FMarkers.Clear;
  FCurrentMarker := -1;
  FCurrentTime := -1;
  FStopTime := -1;
  FStatData := Context.StateDict.GetString('statData');
  FNumStats := 0;
  if (FStatData <> '') and Assigned(Context.FileSystem) and Context.FileSystem.TryReadFile(FStatData, False, LFile) then
  begin
    if Length(LFile.Data) >= 4 then
      Move(LFile.Data[0], FNumStats, 4);
    if (FNumStats < 0) or (FNumStats > MAX_LOGGED_STATS) or (Length(LFile.Data) < 4 + FNumStats * 16) then
      raise EGuiWindowException.CreateFmt('the log of the statistics has %d entries', [FNumStats]);
    SetLength(LStats, FNumStats);
    if FNumStats > 0 then
      Move(LFile.Data[4], LStats[0], FNumStats * 16);
    for LIndex := 0 to FNumStats - 1 do
    begin
      if LStats[LIndex].Health < 0 then
        LStats[LIndex].Health := 0;
      if LStats[LIndex].Stamina < 0 then
        LStats[LIndex].Stamina := 0;
      if LStats[LIndex].HeartRate < 0 then
        LStats[LIndex].HeartRate := 0;
      if LStats[LIndex].Combat < 0 then
        LStats[LIndex].Combat := 0;
    end;
  end;
  if (FNumStats > 1) and (GetBackground <> nil) then
  begin
    if Assigned(Context.FileLister) then
    begin
      LNames := Context.FileLister.ListFiles(ExtractFilePath(string(FStatData)), '.tga');
      for LName in LNames do
      begin
        LData.Material := Context.Materials.FindMaterial(LName);
        LData.Material.SetGuiSort;
        LData.Time := TIdCNumbers.Atoi(BaseName(LName));
        LData.Rect := TGuiRectangle.Create(0, 0, 0, 0);
        FMarkers.Add(LData);
      end;
    end;
    SetLength(LImage, 512 * 64);
    LStep := 511.0 / (FNumStats - 1);
    LX1 := 0 - LStep;
    for LIndex := 0 to FNumStats - 2 do
    begin
      LX1 := LX1 + LStep;
      LX2 := LX1 + LStep;
      LY1 := Scaled(63, StatAt(LIndex).Health, HEALTH_MAX);
      LY2 := Scaled(63, StatAt(LIndex + 1).Health, HEALTH_MAX);
      Line(TIdMath.Ftoi(LX1), TIdMath.Ftoi(LY1), TIdMath.Ftoi(LX2), TIdMath.Ftoi(LY2), LImage, $FF0000FF);
      LY1 := Scaled(63, StatAt(LIndex).HeartRate, RATE_MAX);
      LY2 := Scaled(63, StatAt(LIndex + 1).HeartRate, RATE_MAX);
      Line(TIdMath.Ftoi(LX1), TIdMath.Ftoi(LY1), TIdMath.Ftoi(LX2), TIdMath.Ftoi(LY2), LImage, $FF00FF00);
      LY1 := Scaled(62, StatAt(LIndex).Stamina, STAMINA_MAX);
      LY2 := Scaled(62, StatAt(LIndex + 1).Stamina, STAMINA_MAX);
      Line(TIdMath.Ftoi(LX1), TIdMath.Ftoi(LY1), TIdMath.Ftoi(LX2), TIdMath.Ftoi(LY2), LImage, $FFFF0000);
      LY1 := Scaled(63, StatAt(LIndex).Combat, COMBAT_MAX);
      LY2 := Scaled(63, StatAt(LIndex + 1).Combat, COMBAT_MAX);
      Line(TIdMath.Ftoi(LX1), TIdMath.Ftoi(LY1), TIdMath.Ftoi(LX2), TIdMath.Ftoi(LY2), LImage, $FF00FFFF);
    end;
    if Assigned(Context.ScratchImages) then
      Context.ScratchImages.UploadScratch(GetBackground, LImage, 512, 64);
  end;
end;

end.