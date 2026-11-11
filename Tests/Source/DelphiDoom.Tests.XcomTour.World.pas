{******************************************************************************}
{                                                                              }
{  DelphiDoom: the whole game of OpenXcom for the tests of the strategic       }
{  screens (the composition of the program, a memory display, a manual clock)  }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.World;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.ManualClock,
  DelphiDoom.XcomEngine.QueueEventSource, DelphiDoom.XcomEngine.MemoryVideoDevice, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomGeoscape.Globe;

type
  /// <summary>
  ///   The game as the program composes it (TXcomGameComposition, with the navigator and the simulation of the
  ///   program) on the data of X-COM: Terror from the Deep that the repository does not have
  ///   (Reference\_dati\xcom_tftd, found by climbing from the executable). The display is in memory, the clock is
  ///   manual and the events are the ones the test gives, in the pixels of the 640 x 400 window. The folder of the
  ///   player is a new temporary one, deleted with the world
  /// </summary>
  TXcomTourWorld = class
  strict private
    FRoot: string;
    FUserFolder: string;
    FClock: TXcomManualClock;
    FClockRef: IXcomClock;
    FEvents: TXcomQueueEventSource;
    FEventsRef: IXcomEventSource;
    FDevice: TXcomMemoryVideoDevice;
    FDeviceRef: IXcomVideoDevice;
    FGame: TXcomGame;
    class function FindUp(const ARelative: string): string; static;
    function LoadSave(const AFolder, AName: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The data is there: without it the game is nil and a test has nothing to check</summary>
    function HasData: Boolean;
    /// <summary>Lets the time pass one millisecond at a time, with a turn of the game for each</summary>
    procedure Wait(AMilliseconds: Integer);
    /// <summary>A left click, then the time for the screen that opens to show its surfaces</summary>
    procedure Click(AX, AY: Integer);
    /// <summary>A key (a printable one also types its character), then the time for the screen to change</summary>
    procedure Key(AKey: Integer);
    /// <summary>Types the lower case letters and digits of the text</summary>
    procedure TypeText(const AText: string);
    /// <summary>From the start of the program to the geoscape of a new game with its first base, named "ab"</summary>
    procedure StartNewGame;
    /// <summary>
    ///   From the start of the program to the geoscape of a saved game of Tests\Data\XcomSave\variants (its header
    ///   is adapted to the catalog of the saved games, as the scripts of Tools\Verifica\176 do). False: no file
    /// </summary>
    function LoadVariant(const AName: string): Boolean;
    /// <summary>
    ///   The same for a saved game of Tests\Data\XcomSave\missions (Tools\Verifica\176\Make-XcomMissionSave.ps1: a
    ///   craft with soldiers over its target, a UFO over the base). False: no file
    /// </summary>
    function LoadMission(const AName: string): Boolean;
    /// <summary>The class of the state on top ('' when there is none)</summary>
    function Top: string;
    function Save: TXcomSavedGame;
    function FirstBase: TXcomBase;
    /// <summary>The zoom of the globe of the geoscape, which must be the state on top</summary>
    function GlobeZoom: Integer;
    /// <summary>The globe of the geoscape, which must be the state on top</summary>
    function Globe: TXcomGlobe;
    /// <summary>A copy of the picture on the display (640 x 400 palette indexes)</summary>
    function Picture: TBytes;
    property Game: TXcomGame read FGame;
    property UserFolder: string read FUserFolder;
  end;

const
  /// <summary>The column of the buttons of the basescape and their rows, in the pixels of the window</summary>
  TOUR_BASE_BUTTON_X = 510;
  TOUR_NEW_BASE_Y = 128;
  TOUR_BASE_INFO_Y = 154;
  TOUR_SOLDIERS_Y = 180;
  TOUR_CRAFTS_Y = 206;
  TOUR_FACILITIES_Y = 232;
  TOUR_RESEARCH_Y = 258;
  TOUR_MANUFACTURE_Y = 284;
  TOUR_TRANSFER_Y = 310;
  TOUR_PURCHASE_Y = 336;
  TOUR_SELL_Y = 362;
  /// <summary>The column of the buttons of the geoscape and their rows</summary>
  TOUR_GEO_BUTTON_X = 575;
  TOUR_INTERCEPT_Y = 10;
  TOUR_BASES_Y = 34;
  TOUR_GRAPHS_Y = 58;
  TOUR_OPTIONS_Y = 106;
  TOUR_FUNDING_Y = 130;

implementation

uses
  System.IOUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomGeoscape.GeoscapeState,
  DelphiDoom.Xcom.GameComposition;

class function TXcomTourWorld.FindUp(const ARelative: string): string;
var
  LFolder: string;
  LParent: string;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  while LFolder <> '' do
  begin
    if TDirectory.Exists(TPath.Combine(LFolder, ARelative)) then
      Exit(TPath.Combine(LFolder, ARelative));
    LParent := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
    if LParent = LFolder then
      Break;
    LFolder := LParent;
  end;
  Result := '';
end;

constructor TXcomTourWorld.Create;
var
  LSettings: TXcomGameSettings;
begin
  inherited Create;
  FRoot := FindUp('Reference\_dati\xcom_tftd');
  if (FRoot = '') or not TDirectory.Exists(TPath.Combine(FRoot, 'openxcom\standard\xcom2')) or
    not TDirectory.Exists(TPath.Combine(FRoot, 'TFTD\GEODATA')) then
  begin
    FRoot := '';
    Exit;
  end;
  FUserFolder := TPath.Combine(TPath.GetTempPath, 'DelphiDoomXcomTour_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FUserFolder);
  FClock := TXcomManualClock.Create;
  FClockRef := FClock;
  FEvents := TXcomQueueEventSource.Create;
  FEventsRef := FEvents;
  FDevice := TXcomMemoryVideoDevice.Create;
  FDeviceRef := FDevice;
  LSettings := Default(TXcomGameSettings);
  LSettings.DataFolder := TPath.Combine(FRoot, 'openxcom');
  LSettings.GameFolder := TPath.Combine(FRoot, 'TFTD');
  LSettings.UserFolder := FUserFolder;
  LSettings.ModId := 'xcom2';
  LSettings.VersionText := 'test';
  LSettings.LoadMode := lmImmediate;
  // the same game at every run: funds, soldiers and alien missions
  LSettings.Seed := 176;
  FGame := TXcomGameComposition.CreateGame(LSettings, FDeviceRef, FClockRef, FEvents);
end;

destructor TXcomTourWorld.Destroy;
begin
  FGame.Free;
  if (FUserFolder <> '') and TDirectory.Exists(FUserFolder) then
    TDirectory.Delete(FUserFolder, True);
  inherited Destroy;
end;

function TXcomTourWorld.HasData: Boolean;
begin
  Result := Assigned(FGame);
end;

procedure TXcomTourWorld.Wait(AMilliseconds: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to AMilliseconds do
  begin
    FClock.Advance(1);
    FGame.RunFrame;
  end;
end;

procedure TXcomTourWorld.Click(AX, AY: Integer);
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
  Wait(40);
  LEvent.Kind := ekMouseUp;
  FEvents.Enqueue(LEvent);
  // the window of a screen shows its surfaces when it has opened
  Wait(500);
end;

procedure TXcomTourWorld.Key(AKey: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  if (AKey >= 32) and (AKey <= 126) then
    LEvent.Character := Cardinal(AKey);
  FEvents.Enqueue(LEvent);
  Wait(20);
  LEvent.Kind := ekKeyUp;
  FEvents.Enqueue(LEvent);
  Wait(480);
end;

procedure TXcomTourWorld.TypeText(const AText: string);
var
  LChar: Char;
begin
  for LChar in AText do
    Key(Ord(LChar));
end;

procedure TXcomTourWorld.StartNewGame;
begin
  // the start screen, then the main menu
  Wait(5000);
  // New Game, OK of the difficulty, the site of the base on the globe, its name
  Click(220, 200);
  Click(238, 344);
  Wait(1000);
  Click(250, 200);
  TypeText('ab');
  Key(XCOM_KEY_RETURN);
  Wait(500);
end;

function TXcomTourWorld.LoadVariant(const AName: string): Boolean;
begin
  Result := LoadSave('Tests\Data\XcomSave\variants', AName);
end;

function TXcomTourWorld.LoadMission(const AName: string): Boolean;
begin
  Result := LoadSave('Tests\Data\XcomSave\missions', AName);
end;

function TXcomTourWorld.LoadSave(const AFolder, AName: string): Boolean;
var
  LFolder: string;
  LText: string;
begin
  LFolder := FindUp(AFolder);
  Result := (LFolder <> '') and TFile.Exists(TPath.Combine(LFolder, AName + '.sav'));
  if not Result then
    Exit;
  LText := TFile.ReadAllText(TPath.Combine(LFolder, AName + '.sav'), TEncoding.UTF8);
  LText := LText.Replace('name: ""', 'name: "Variant"').Replace('  - "xcom2 ver: 1.0"', '  - xcom2').Replace(#13#10, #10);
  TDirectory.CreateDirectory(TPath.Combine(FUserFolder, 'xcom2'));
  // no byte order mark: the catalog reads the header as YAML
  TFile.WriteAllBytes(TPath.Combine(FUserFolder, 'xcom2\' + AName + '.sav'), TEncoding.UTF8.GetBytes(LText));
  // the start screen, the main menu, Load Game, the only saved game of the list
  Wait(5000);
  Click(220, 256);
  Click(60, 93);
  Wait(2500);
end;

function TXcomTourWorld.Top: string;
begin
  if FGame.TopState = nil then
    Result := ''
  else
    Result := FGame.TopState.ClassName;
end;

function TXcomTourWorld.Save: TXcomSavedGame;
begin
  Result := TXcomStrategy.SavedGame(FGame);
end;

function TXcomTourWorld.GlobeZoom: Integer;
begin
  Result := Globe.Zoom;
end;

function TXcomTourWorld.Globe: TXcomGlobe;
begin
  Result := (FGame.TopState as TXcomGeoscapeState).Globe;
end;

function TXcomTourWorld.Picture: TBytes;
begin
  Result := Copy(FDevice.Pixels);
end;

function TXcomTourWorld.FirstBase: TXcomBase;
begin
  Result := Save.Bases.First;
end;

end.
