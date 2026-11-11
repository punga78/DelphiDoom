{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom engine - a small game made of fakes: a memory  }
{  display, a manual clock, a queue of events, and resources with a font drawn  }
{  by code (no file of the original game)                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.World;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.RuleInterface,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.ManualClock, DelphiDoom.XcomEngine.QueueEventSource,
  DelphiDoom.XcomEngine.MemoryVideoDevice, DelphiDoom.XcomEngine.InteractiveSurface;

type
  /// <summary>IXcomResources made by code: a font of 6 x 7 boxes, two palettes, a picture and one interface</summary>
  TFakeResources = class(TInterfacedObject, IXcomResources)
  strict private
    FSurfaces: TObjectDictionary<string, TXcomSurface>;
    FFonts: TObjectDictionary<string, TXcomFont>;
    FInterfaces: TObjectDictionary<string, TXcomRuleInterface>;
    FPalette: array[0..255] of TXcomColor;
    FBack: array[0..255] of TXcomColor;
    FPaletteCalls: Integer;
    WaveBytes: TBytes;
    FRules: TArray<TXcomMusicRule>;
    FSoundFiles: TDictionary<string, TBytes>;
    function NewFont(AWidth, AHeight: Integer): TXcomFont;
  public
    constructor Create;
    destructor Destroy; override;
    function GetSurface(const AName: string): TXcomSurface;
    function GetFont(const AName: string): TXcomFont;
    function GetInterface(const AId: string): TXcomRuleInterface;
    function GetPalette(const AName: string): PXcomColor;
    function CursorColor(const APalette: string): Integer;
    function HasSoundDefinitions: Boolean;
    function SoundWave(const ASet: string; AIndex: Integer): TBytes;
    /// <summary>What SoundWave gives (nothing by default)</summary>
    property Wave: TBytes read WaveBytes write WaveBytes;
    /// <summary>What MusicRules gives (nothing by default)</summary>
    property Rules: TArray<TXcomMusicRule> read FRules write FRules;
    /// <summary>The files of the SOUND folder that SoundFile finds, by lower case name</summary>
    property SoundFiles: TDictionary<string, TBytes> read FSoundFiles;
    function Constant(const AName: string; ADefault: Integer): Integer;
    function MusicRules: TArray<TXcomMusicRule>;
    function SoundFile(const AName: string): TBytes;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256);
    property PaletteCalls: Integer read FPaletteCalls;
  end;

  /// <summary>IXcomFileSystem in memory: the files are strings by path (case does not matter)</summary>
  TFakeFileSystem = class(TInterfacedObject, IXcomFileSystem)
  strict private
    FFiles: TDictionary<string, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Put(const APath, AText: string);
    function FileExists(const APath: string): Boolean;
    function FolderExists(const APath: string): Boolean;
    function ReadAll(const APath: string): TBytes;
    procedure WriteAll(const APath: string; const ABytes: TBytes);
    function FolderContents(const AFolder, AExtension: string): TArray<string>;
  end;

  /// <summary>The game of a test: everything the engine needs with fakes, and ways to push time and events</summary>
  TTestWorld = class
  strict private
    FClock: TXcomManualClock;
    FClockRef: IXcomClock;
    FEvents: TXcomQueueEventSource;
    FEventsRef: IXcomEventSource;
    FDevice: TXcomMemoryVideoDevice;
    FDeviceRef: IXcomVideoDevice;
    FResources: TFakeResources;
    FResourcesRef: IXcomResources;
    FGame: TXcomGame;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Wait(AMilliseconds: Integer);
    procedure Click(AX, AY: Integer);
    /// <summary>A click that keeps the button down for AHoldMilliseconds (the timers of the arrows run while it is down)</summary>
    procedure ClickHeld(AX, AY, AHoldMilliseconds: Integer);
    function Pixel(AX, AY: Integer): Byte;
    class function Parse(const AText: string): IYamlNode; static;
    property Game: TXcomGame read FGame;
    property Clock: TXcomManualClock read FClock;
    property Events: TXcomQueueEventSource read FEvents;
    property Device: TXcomMemoryVideoDevice read FDevice;
    property Resources: TFakeResources read FResources;
  end;

const
  /// <summary>The characters of the fake font, in the order of its cells (16 per row)</summary>
  FAKE_CHARS = ' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_';

implementation

uses
  DelphiDoom.XcomUi.Cursor, DelphiDoom.XcomUi.FpsCounter;

{ TFakeFileSystem }

constructor TFakeFileSystem.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TFakeFileSystem.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeFileSystem.Put(const APath, AText: string);
begin
  FFiles.AddOrSetValue(LowerCase(APath), TEncoding.UTF8.GetBytes(AText));
end;

function TFakeFileSystem.FileExists(const APath: string): Boolean;
begin
  Result := FFiles.ContainsKey(LowerCase(APath));
end;

function TFakeFileSystem.FolderExists(const APath: string): Boolean;
var
  LKey: string;
  LPrefix: string;
begin
  LPrefix := LowerCase(IncludeTrailingPathDelimiter(APath));
  for LKey in FFiles.Keys do
    if Pos(LPrefix, LKey) = 1 then
      Exit(True);
  Result := False;
end;

function TFakeFileSystem.ReadAll(const APath: string): TBytes;
begin
  if not FFiles.TryGetValue(LowerCase(APath), Result) then
    raise EXcomEngineException.Create('no file ' + APath);
end;

procedure TFakeFileSystem.WriteAll(const APath: string; const ABytes: TBytes);
begin
  FFiles.AddOrSetValue(LowerCase(APath), ABytes);
end;

function TFakeFileSystem.FolderContents(const AFolder, AExtension: string): TArray<string>;
var
  LKey: string;
  LPrefix: string;
  LList: TList<string>;
begin
  LPrefix := LowerCase(IncludeTrailingPathDelimiter(AFolder));
  LList := TList<string>.Create;
  try
    for LKey in FFiles.Keys do
      if (Pos(LPrefix, LKey) = 1) and (ExtractFileExt(LKey) = '.' + LowerCase(AExtension)) and
        (Pos(PathDelim, Copy(LKey, Length(LPrefix) + 1, MaxInt)) = 0) then
        LList.Add(ChangeFileExt(ExtractFileName(LKey), ''));
    LList.Sort;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

{ TFakeResources }

constructor TFakeResources.Create;
var
  LIndex: Integer;
  LBack: TXcomSurface;
  LX: Integer;
  LY: Integer;
  LRule: TXcomRuleInterface;
  LName: string;
begin
  inherited Create;
  FSurfaces := TObjectDictionary<string, TXcomSurface>.Create([doOwnsValues]);
  FFonts := TObjectDictionary<string, TXcomFont>.Create([doOwnsValues]);
  FInterfaces := TObjectDictionary<string, TXcomRuleInterface>.Create([doOwnsValues]);
  FSoundFiles := TDictionary<string, TBytes>.Create;
  for LIndex := 0 to 255 do
  begin
    FPalette[LIndex].Red := LIndex;
    FPalette[LIndex].Green := 255 - LIndex;
    FPalette[LIndex].Blue := (LIndex * 7) and $FF;
    FPalette[LIndex].Alpha := 255;
    FBack[LIndex].Red := 255 - LIndex;
    FBack[LIndex].Green := LIndex;
    FBack[LIndex].Blue := 0;
    FBack[LIndex].Alpha := 255;
  end;
  FFonts.Add('FONT_BIG', NewFont(10, 10));
  FFonts.Add('FONT_SMALL', NewFont(8, 8));
  LBack := TXcomSurface.Create(320, 200);
  for LY := 0 to 199 do
    for LX := 0 to 319 do
      LBack.SetPixel(LX, LY, Byte(((LX div 8) + (LY div 8)) and 7) + 40);
  FSurfaces.Add('BACK01.SCR', LBack);
  // the pictures of the popups of the geoscape
  for LName in ['BACK12.SCR', 'BACK15.SCR'] do
  begin
    LBack := TXcomSurface.Create(320, 200);
    for LY := 0 to 199 do
      for LX := 0 to 319 do
        LBack.SetPixel(LX, LY, Byte(((LX div 8) + (LY div 8)) and 7) + 40);
    FSurfaces.Add(LName, LBack);
  end;
  LRule := TXcomRuleInterface.Create('testMenu');
  FInterfaces.Add('testMenu', LRule);
  LRule := TXcomRuleInterface.Create('newGameMenu');
  LRule.Load(TYamlFactory.CreateParser.Load('elements:'#10'  - id: window'#10'    color: 1'#10'  - id: text'#10'    color: 1'#10 +
    '  - id: ironman'#10'    color: 239'#10'  - id: button'#10'    color: 1'#10));
  FInterfaces.Add('newGameMenu', LRule);
  LRule := TXcomRuleInterface.Create('musicMenu');
  LRule.Load(TYamlFactory.CreateParser.Load('music: GMTEST'#10'elements:'#10'  - id: window'#10'    color: 1'#10));
  FInterfaces.Add('musicMenu', LRule);
end;

destructor TFakeResources.Destroy;
begin
  FSoundFiles.Free;
  FInterfaces.Free;
  FFonts.Free;
  FSurfaces.Free;
  inherited Destroy;
end;

function TFakeResources.NewFont(AWidth, AHeight: Integer): TXcomFont;
var
  LSurface: TXcomSurface;
  LCell: Integer;
  LX: Integer;
  LY: Integer;
begin
  LSurface := TXcomSurface.Create(AWidth * 16, AHeight * 4);
  for LCell := 1 to 63 do
    for LY := 1 to AHeight - 2 do
      for LX := 1 to AWidth - 4 do
        LSurface.SetPixel((LCell mod 16) * AWidth + LX, (LCell div 16) * AHeight + LY, 1);
  Result := TXcomFont.Create;
  Result.AddImage(AWidth, AHeight, 1, LSurface);
  Result.Init(0, TXcomFont.CodePoints(FAKE_CHARS));
end;

function TFakeResources.GetSurface(const AName: string): TXcomSurface;
begin
  if not FSurfaces.TryGetValue(AName, Result) then
    raise EXcomEngineException.Create('no surface ' + AName);
end;

function TFakeResources.GetFont(const AName: string): TXcomFont;
begin
  if not FFonts.TryGetValue(AName, Result) then
    raise EXcomEngineException.Create('no font ' + AName);
end;

function TFakeResources.GetInterface(const AId: string): TXcomRuleInterface;
begin
  if not FInterfaces.TryGetValue(AId, Result) then
    Result := nil;
end;

function TFakeResources.GetPalette(const AName: string): PXcomColor;
begin
  if AName = 'BACKPALS.DAT' then
    Result := @FBack[0]
  else
    Result := @FPalette[0];
end;

function TFakeResources.CursorColor(const APalette: string): Integer;
begin
  if APalette = 'PAL_BATTLESCAPE' then
    Result := 144
  else
    Result := 252;
end;

function TFakeResources.SoundWave(const ASet: string; AIndex: Integer): TBytes;
begin
  Result := WaveBytes;
end;

function TFakeResources.Constant(const AName: string; ADefault: Integer): Integer;
begin
  Result := ADefault;
end;

function TFakeResources.MusicRules: TArray<TXcomMusicRule>;
begin
  Result := FRules;
end;

function TFakeResources.SoundFile(const AName: string): TBytes;
begin
  if not FSoundFiles.TryGetValue(LowerCase(AName), Result) then
    Result := nil;
end;

function TFakeResources.HasSoundDefinitions: Boolean;
begin
  Result := True;
end;

procedure TFakeResources.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  Inc(FPaletteCalls);
end;

{ TTestWorld }

constructor TTestWorld.Create;
var
  LOptions: TXcomOptions;
begin
  inherited Create;
  FClock := TXcomManualClock.Create;
  FClockRef := FClock;
  FEvents := TXcomQueueEventSource.Create;
  FEventsRef := FEvents;
  FDevice := TXcomMemoryVideoDevice.Create;
  FDeviceRef := FDevice;
  FResources := TFakeResources.Create;
  FResourcesRef := FResources;
  LOptions := TXcomOptions.Create;
  LOptions.BaseXResolution := 320;
  LOptions.BaseYResolution := 200;
  FGame := TXcomGame.Create(LOptions, TXcomScreen.Create(LOptions, FDeviceRef), TXcomCursor.Create(9, 13),
    TXcomFpsCounter.Create(FClockRef, 15, 5, 0, 0, False, 288),
    TXcomLanguage.Create('en-US', twAuto, nil, nil), FClockRef, FEventsRef);
  FGame.AdoptData(FResourcesRef, nil);
end;

destructor TTestWorld.Destroy;
begin
  FGame.Free;
  inherited Destroy;
end;

procedure TTestWorld.Wait(AMilliseconds: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to AMilliseconds do
  begin
    FGame.RunFrame;
    FClock.Advance(1);
  end;
end;

procedure TTestWorld.Click(AX, AY: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := AX;
  LEvent.Y := AY;
  FEvents.Enqueue(LEvent);
  Wait(20);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Button := XCOM_BUTTON_LEFT;
  FEvents.Enqueue(LEvent);
  Wait(20);
  LEvent.Kind := ekMouseUp;
  FEvents.Enqueue(LEvent);
  Wait(20);
end;

procedure TTestWorld.ClickHeld(AX, AY, AHoldMilliseconds: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := AX;
  LEvent.Y := AY;
  FEvents.Enqueue(LEvent);
  Wait(20);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Button := XCOM_BUTTON_LEFT;
  FEvents.Enqueue(LEvent);
  Wait(AHoldMilliseconds);
  LEvent.Kind := ekMouseUp;
  FEvents.Enqueue(LEvent);
  Wait(40);
end;

class function TTestWorld.Parse(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(AText);
end;

function TTestWorld.Pixel(AX, AY: Integer): Byte;
begin
  Result := FDevice.Pixels[AY * FDevice.Width + AX];
end;

end.
