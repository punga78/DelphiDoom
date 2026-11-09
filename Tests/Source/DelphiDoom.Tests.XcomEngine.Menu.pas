{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom menus - the start screen and the main     }
{  menu on fakes, and the real game data (skipped when it is not there)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.Menu;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Factory,
  DelphiDoom.Xcom.Types,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.GameLoader.Intf,
  DelphiDoom.XcomEngine.GameLoadTask, DelphiDoom.XcomEngine.HeldLoadTask, DelphiDoom.XcomEngine.ImmediateLoadTask,
  DelphiDoom.XcomEngine.ThreadLoadTask, DelphiDoom.XcomEngine.Game, DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>An IXcomGameLoader that gives the fake resources and a few strings (or fails)</summary>
  TFakeLoader = class(TInterfacedObject, IXcomGameLoader)
  strict private
    FFail: Boolean;
  public
    constructor Create(AFail: Boolean = False);
    procedure Load(out AResources: IXcomResources; out ALanguage: TXcomLanguage);
  end;

  [TestFixture]
  [Category('XcomMenu')]
  TTestXcomStartState = class
  strict private
    FWorld: TTestWorld;
    FTask: TXcomHeldLoadTask;
    procedure StartScreen(AFail: Boolean = False);
    function LitPixels: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure MostraLaRigaDelPromptEOgnuno;
    [Test]
    procedure IlCursoreLampeggia;
    [Test]
    procedure FinitoIlCaricamentoVaAlMenuPrincipale;
    [Test]
    procedure SeIlCaricamentoFallisceMostraLErroreEAspettaUnTasto;
    [Test]
    procedure UnTastoDopoLErroreEsce;
    [Test]
    procedure IlCursoreDelMouseNonSiVedeFinoAlCaricamento;
    [Test]
    procedure ILCaricamentoImmediatoCompletaSubito;
    [Test]
    procedure ILCaricamentoInUnThreadFinisce;
  end;

  [TestFixture]
  [Category('XcomMenu')]
  TTestXcomMainMenuState = class
  strict private
    FWorld: TTestWorld;
    procedure OpenMainMenu;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DisegnaLaFinestraEIPulsanti;
    [Test]
    procedure QuitChiudeIlGioco;
    [Test]
    procedure LaFinestraSiApreConIlPopup;
    [Test]
    procedure IPulsantiDaiTestiDellaLingua;
  end;

  [TestFixture]
  [Category('XcomMenu')]
  TTestXcomNewGameState = class
  strict private
    FWorld: TTestWorld;
    procedure OpenNewGame;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlPulsanteNewGameApreLaScelta;
    [Test]
    procedure CancelTornaAlMenuPrincipale;
    [Test]
    procedure ELTastoEscapeAnnullaPure;
    [Test]
    procedure ClicSuUnaDifficoltaLaSeleziona;
    [Test]
    procedure LaDifficoltaPredefinitaEPrincipiante;
    [Test]
    procedure IronmanSiAccendeEdAAzzera;
    [Test]
    procedure OkNonFaNullaPerOra;
  end;

  [TestFixture]
  [Category('XcomRealData')]
  TTestXcomRealData = class
  strict private
    FReference: string;
    FGameFolder: string;
    FDataFolder: string;
    FUserFolder: string;
    function Hash(AWorld: TTestWorld): string;
    function Golden(const AName: string): string;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure ILMenuPrincipaleELoStessoDiOpenXcomVero;
    [Test]
    procedure LaSchermataDiAvvioELaStessaDiOpenXcomVero;
    [Test]
    procedure LaSceltaDellaDifficoltaELaStessaDiOpenXcomVero;
    [Test]
    procedure IDatiVeriDannoLeStringheLePaletteEIFont;
  end;

implementation

uses
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomMenu.StartState, DelphiDoom.XcomMenu.MainMenuState,
  DelphiDoom.XcomMenu.NewGameState,
  DelphiDoom.XcomEngine.ModGameLoader, DelphiDoom.XcomEngine.DiskFileSystem, DelphiDoom.XcomEngine.ModResources,
  DelphiDoom.Png.Provider;

{ TFakeLoader }

constructor TFakeLoader.Create(AFail: Boolean);
begin
  inherited Create;
  FFail := AFail;
end;

procedure TFakeLoader.Load(out AResources: IXcomResources; out ALanguage: TXcomLanguage);
var
  LFiles: TFakeFileSystem;
  LFilesRef: IXcomFileSystem;
begin
  if FFail then
    raise EXcomEngineException.Create('No X-COM installation found');
  LFiles := TFakeFileSystem.Create;
  LFilesRef := LFiles;
  LFiles.Put('l.yml', 'en-US:'#10'  STR_NEW_GAME: "New Game"'#10'  STR_NEW_BATTLE: "New Battle"'#10 +
    '  STR_LOAD_SAVED_GAME: "Load Game"'#10'  STR_OPTIONS: "Options"'#10'  STR_MODS: "Mods"'#10 +
    '  STR_QUIT: "Quit"'#10'  STR_OPENXCOM: "OpenXcom"'#10);
  ALanguage := TXcomLanguage.Create('en-US', twAuto, LFilesRef, TYamlFactory.CreateParser);
  ALanguage.LoadFile('l.yml');
  AResources := TFakeResources.Create;
end;

{ TTestXcomStartState }

procedure TTestXcomStartState.Setup;
begin
  FWorld := TTestWorld.Create;
end;

procedure TTestXcomStartState.TearDown;
begin
  FWorld.Free;
end;

procedure TTestXcomStartState.StartScreen(AFail: Boolean);
begin
  FTask := TXcomHeldLoadTask.Create(TFakeLoader.Create(AFail));
  FWorld.Game.SetState(TXcomStartState.Create(FWorld.Game, FTask, 'C:\GAMES\OPENXCOM', '1.0 Dev'));
end;

function TTestXcomStartState.LitPixels: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to Length(FWorld.Device.Pixels) - 1 do
    if FWorld.Device.Pixels[LIndex] <> 0 then
      Inc(Result);
end;

procedure TTestXcomStartState.MostraLaRigaDelPromptEOgnuno;
begin
  StartScreen;
  FWorld.Wait(100);
  Assert.IsTrue(LitPixels > 100);
  Assert.AreEqual(640, FWorld.Device.Width);
  // the terminal palette: color 1 is light grey
  Assert.AreEqual(185, Integer(FWorld.Device.Palette[1].Red));
  Assert.AreEqual(0, Integer(FWorld.Device.Palette[0].Red));
end;

procedure TTestXcomStartState.IlCursoreLampeggia;
var
  LFirst: Integer;
  LSecond: Integer;
begin
  StartScreen;
  FWorld.Wait(160);
  LFirst := LitPixels;
  FWorld.Wait(150);
  LSecond := LitPixels;
  Assert.AreNotEqual(LFirst, LSecond);
end;

procedure TTestXcomStartState.FinitoIlCaricamentoVaAlMenuPrincipale;
begin
  StartScreen;
  FWorld.Wait(100);
  Assert.IsTrue(FWorld.Game.TopState is TXcomStartState);
  FTask.Finish;
  FWorld.Wait(50);
  Assert.IsTrue(FWorld.Game.TopState is TXcomMainMenuState);
  Assert.IsTrue(FWorld.Game.Cursor.Visible);
  Assert.AreEqual(320, FWorld.Game.Options.BaseXResolution);
  Assert.AreEqual(200, FWorld.Game.Options.BaseYResolution);
end;

procedure TTestXcomStartState.SeIlCaricamentoFallisceMostraLErroreEAspettaUnTasto;
var
  LBefore: Integer;
begin
  StartScreen;
  FWorld.Wait(100);
  LBefore := LitPixels;
  FTask.Fail('Something broke');
  FWorld.Wait(100);
  Assert.IsTrue(LitPixels > LBefore);
  Assert.IsFalse(FWorld.Game.IsQuitting);
end;

procedure TTestXcomStartState.UnTastoDopoLErroreEsce;
var
  LEvent: TXcomInputEvent;
begin
  StartScreen(True);
  FWorld.Wait(20);
  FTask.Finish;
  FWorld.Wait(50);
  Assert.IsFalse(FWorld.Game.IsQuitting);
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := 65;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(10);
  Assert.IsTrue(FWorld.Game.IsQuitting);
end;

procedure TTestXcomStartState.IlCursoreDelMouseNonSiVedeFinoAlCaricamento;
begin
  StartScreen;
  FWorld.Wait(20);
  Assert.IsFalse(FWorld.Game.Cursor.Visible);
  Assert.IsFalse(FWorld.Game.FpsCounter.Visible);
end;

procedure TTestXcomStartState.ILCaricamentoImmediatoCompletaSubito;
var
  LTask: TXcomImmediateLoadTask;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
begin
  LTask := TXcomImmediateLoadTask.Create(TFakeLoader.Create);
  try
    Assert.IsTrue(LTask.Status = lsNotStarted);
    LTask.Start;
    Assert.IsTrue(LTask.Status = lsSuccessful);
    LTask.TakeResult(LResources, LLanguage);
    Assert.IsNotNull(LResources);
    Assert.AreEqual('New Game', LLanguage.GetString('STR_NEW_GAME').Text);
    LLanguage.Free;
  finally
    LTask.Free;
  end;
  LTask := TXcomImmediateLoadTask.Create(TFakeLoader.Create(True));
  try
    LTask.Start;
    Assert.IsTrue(LTask.Status = lsFailed);
    Assert.AreEqual('No X-COM installation found', LTask.Error);
  finally
    LTask.Free;
  end;
end;

procedure TTestXcomStartState.ILCaricamentoInUnThreadFinisce;
var
  LTask: TXcomThreadLoadTask;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
  LWaited: Integer;
begin
  LTask := TXcomThreadLoadTask.Create(TFakeLoader.Create);
  try
    Assert.IsTrue(LTask.Status = lsNotStarted);
    LTask.Start;
    LTask.Start;
    LWaited := 0;
    while (LTask.Status = lsRunning) and (LWaited < 5000) do
    begin
      TThread.Sleep(5);
      Inc(LWaited, 5);
    end;
    Assert.IsTrue(LTask.Status = lsSuccessful);
    LTask.TakeResult(LResources, LLanguage);
    LLanguage.Free;
  finally
    LTask.Free;
  end;
end;

{ TTestXcomMainMenuState }

procedure TTestXcomMainMenuState.Setup;
begin
  FWorld := TTestWorld.Create;
end;

procedure TTestXcomMainMenuState.TearDown;
begin
  FWorld.Free;
end;

procedure TTestXcomMainMenuState.OpenMainMenu;
var
  LLoader: IXcomGameLoader;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
begin
  LLoader := TFakeLoader.Create;
  LLoader.Load(LResources, LLanguage);
  FWorld.Game.AdoptData(LResources, LLanguage);
  FWorld.Game.SetState(TXcomMainMenuState.Create(FWorld.Game, '1.0 Dev'));
end;

procedure TTestXcomMainMenuState.DisegnaLaFinestraEIPulsanti;
begin
  OpenMainMenu;
  FWorld.Wait(500);
  // the window of 256 x 160 at 32, 20 has its border in the 640 x 400 display (scale 2)
  Assert.AreNotEqual(0, Integer(FWorld.Pixel(64, 40)));
  Assert.AreEqual(0, Integer(FWorld.Pixel(620, 390)));
end;

procedure TTestXcomMainMenuState.QuitChiudeIlGioco;
begin
  OpenMainMenu;
  FWorld.Wait(500);
  FWorld.Click(420, 312);
  Assert.IsTrue(FWorld.Game.IsQuitting);
end;

procedure TTestXcomMainMenuState.LaFinestraSiApreConIlPopup;
begin
  OpenMainMenu;
  FWorld.Wait(30);
  // the popup has just started: the window is not drawn yet
  Assert.AreEqual(0, Integer(FWorld.Pixel(64, 40)));
  FWorld.Wait(400);
  Assert.AreNotEqual(0, Integer(FWorld.Pixel(64, 40)));
end;

procedure TTestXcomMainMenuState.IPulsantiDaiTestiDellaLingua;
begin
  OpenMainMenu;
  FWorld.Wait(500);
  Assert.AreEqual('New Game', FWorld.Game.Language.GetString('STR_NEW_GAME').Text);
  // a click on a button that is not ported does not close the game
  FWorld.Click(128, 190);
  Assert.IsFalse(FWorld.Game.IsQuitting);
end;

{ TTestXcomNewGameState }

procedure TTestXcomNewGameState.Setup;
begin
  FWorld := TTestWorld.Create;
end;

procedure TTestXcomNewGameState.TearDown;
begin
  FWorld.Free;
end;

procedure TTestXcomNewGameState.OpenNewGame;
var
  LLoader: IXcomGameLoader;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
begin
  LLoader := TFakeLoader.Create;
  LLoader.Load(LResources, LLanguage);
  FWorld.Game.AdoptData(LResources, LLanguage);
  FWorld.Game.SetState(TXcomMainMenuState.Create(FWorld.Game, '1.0 Dev'));
  FWorld.Wait(500);
  FWorld.Click(220, 200);
  FWorld.Wait(500);
end;

procedure TTestXcomNewGameState.IlPulsanteNewGameApreLaScelta;
begin
  OpenNewGame;
  Assert.IsTrue(FWorld.Game.TopState is TXcomNewGameState);
end;

procedure TTestXcomNewGameState.CancelTornaAlMenuPrincipale;
begin
  OpenNewGame;
  FWorld.Click(402, 344);
  FWorld.Wait(50);
  Assert.IsTrue(FWorld.Game.TopState is TXcomMainMenuState);
end;

procedure TTestXcomNewGameState.ELTastoEscapeAnnullaPure;
var
  LEvent: TXcomInputEvent;
begin
  OpenNewGame;
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := XCOM_KEY_ESCAPE;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(50);
  Assert.IsTrue(FWorld.Game.TopState is TXcomMainMenuState);
end;

procedure TTestXcomNewGameState.ClicSuUnaDifficoltaLaSeleziona;
begin
  OpenNewGame;
  // the button of the genius level: 80, 92 of 160 x 18, in the 640 x 400 display
  FWorld.Click(320, 202);
  Assert.AreEqual(3, TXcomNewGameState(FWorld.Game.TopState).Difficulty);
  FWorld.Click(320, 122);
  Assert.AreEqual(1, TXcomNewGameState(FWorld.Game.TopState).Difficulty);
  FWorld.Click(320, 162);
  Assert.AreEqual(2, TXcomNewGameState(FWorld.Game.TopState).Difficulty);
  FWorld.Click(320, 242);
  Assert.AreEqual(4, TXcomNewGameState(FWorld.Game.TopState).Difficulty);
end;

procedure TTestXcomNewGameState.LaDifficoltaPredefinitaEPrincipiante;
begin
  OpenNewGame;
  Assert.AreEqual(0, TXcomNewGameState(FWorld.Game.TopState).Difficulty);
end;

procedure TTestXcomNewGameState.IronmanSiAccendeEdAAzzera;
var
  LBefore: Byte;
begin
  OpenNewGame;
  LBefore := FWorld.Pixel(170, 276);
  FWorld.Click(200, 276);
  Assert.AreNotEqual(Integer(LBefore), Integer(FWorld.Pixel(170, 276)));
  FWorld.Click(200, 276);
  Assert.AreEqual(Integer(LBefore), Integer(FWorld.Pixel(170, 276)));
end;

procedure TTestXcomNewGameState.OkNonFaNullaPerOra;
begin
  OpenNewGame;
  FWorld.Click(238, 328);
  Assert.IsTrue(FWorld.Game.TopState is TXcomNewGameState);
  Assert.IsFalse(FWorld.Game.IsQuitting);
end;

{ TTestXcomRealData }

procedure TTestXcomRealData.Setup;
var
  LFolder: string;
begin
  FReference := '';
  LFolder := ExtractFilePath(ParamStr(0));
  while (LFolder <> '') and (FReference = '') do
  begin
    if TDirectory.Exists(TPath.Combine(LFolder, 'Reference\_dati\xcom_tftd\TFTD')) then
      FReference := TPath.Combine(LFolder, 'Reference');
    if LFolder = ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder)) then
      Break;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  if FReference = '' then
    Exit;
  FGameFolder := TPath.Combine(FReference, '_dati\xcom_tftd\TFTD');
  FDataFolder := TPath.Combine(FReference, 'OpenXcom\bin');
  FUserFolder := TPath.Combine(FReference, '_dati\xcom_tftd\openxcom_user_cmp');
  if not TDirectory.Exists(TPath.Combine(FDataFolder, 'common')) then
    FReference := '';
end;

function TTestXcomRealData.Hash(AWorld: TTestWorld): string;
var
  LHash: Cardinal;
  LIndex: Integer;
  LColor: TXcomColor;
begin
  // FNV-1a over the R, G, B bytes of every pixel, as the tool of the screenshots computes it
  LHash := 2166136261;
  for LIndex := 0 to Length(AWorld.Device.Pixels) - 1 do
  begin
    LColor := AWorld.Device.Palette[AWorld.Device.Pixels[LIndex]];
    LHash := (LHash xor LColor.Red) * 16777619;
    LHash := (LHash xor LColor.Green) * 16777619;
    LHash := (LHash xor LColor.Blue) * 16777619;
  end;
  Result := Format('%dx%d %s', [AWorld.Device.Width, AWorld.Device.Height, LowerCase(IntToHex(LHash, 8))]);
end;

function TTestXcomRealData.Golden(const AName: string): string;
var
  LFolder: string;
  LLine: string;
  LPath: string;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  LPath := '';
  while LFolder <> '' do
  begin
    if TFile.Exists(TPath.Combine(LFolder, 'Tests\Data\XcomEngine\frames.golden.txt')) then
    begin
      LPath := TPath.Combine(LFolder, 'Tests\Data\XcomEngine\frames.golden.txt');
      Break;
    end;
    if LFolder = ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder)) then
      Break;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Assert.IsTrue(LPath <> '', 'frames.golden.txt not found');
  for LLine in TFile.ReadAllLines(LPath) do
    if LLine.StartsWith(AName + ' ') then
      Exit(Copy(LLine, Length(AName) + 2, MaxInt).Trim);
  Result := '';
end;

procedure TTestXcomRealData.ILMenuPrincipaleELoStessoDiOpenXcomVero;
var
  LWorld: TTestWorld;
  LLoader: IXcomGameLoader;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
  LSettings: TXcomLoaderSettings;
begin
  if FReference = '' then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  LSettings.DataFolder := FDataFolder;
  LSettings.GameFolder := FGameFolder;
  LSettings.ModId := 'xcom2';
  LSettings.LanguageId := 'en-US';
  LSettings.Wordwrap := twAuto;
  LLoader := TXcomModGameLoader.Create(LSettings, TXcomDiskFileSystem.Create, TYamlFactory.CreateParser,
    TPngProvider.Client);
  LLoader.Load(LResources, LLanguage);
  LWorld := TTestWorld.Create;
  try
    LWorld.Game.AdoptData(LResources, LLanguage);
    LWorld.Game.Options.BaseXResolution := 320;
    LWorld.Game.Options.BaseYResolution := 200;
    LWorld.Game.SetState(TXcomMainMenuState.Create(LWorld.Game, '1.0 git 2026-06-05 22:05'));
    // the mouse is outside of the window, as in the frame of the real game
    LWorld.Click(5000, 5000);
    LWorld.Wait(1500);
    Assert.AreEqual(Golden('menu_main'), Hash(LWorld));
  finally
    LWorld.Free;
  end;
end;

procedure TTestXcomRealData.LaSchermataDiAvvioELaStessaDiOpenXcomVero;
var
  LWorld: TTestWorld;
  LTask: TXcomHeldLoadTask;
begin
  if FReference = '' then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  LWorld := TTestWorld.Create;
  try
    LTask := TXcomHeldLoadTask.Create(TFakeLoader.Create);
    LWorld.Game.Options.DisplayWidth := 640;
    LWorld.Game.Options.DisplayHeight := 400;
    LWorld.Game.Options.BaseXResolution := 640;
    LWorld.Game.Options.BaseYResolution := 400;
    LWorld.Game.Screen.ResetDisplay;
    LWorld.Game.SetState(TXcomStartState.Create(LWorld.Game, LTask,
      'C:\PROGETTI\DELPHI~1\REFERE~1\_DATI\XCOM_T~1\OPENXCOM', '1.0 git 2026-06-05 22:05'));
    LWorld.Wait(2330);
    Assert.AreEqual(Golden('start'), Hash(LWorld));
  finally
    LWorld.Free;
  end;
end;

procedure TTestXcomRealData.LaSceltaDellaDifficoltaELaStessaDiOpenXcomVero;
var
  LWorld: TTestWorld;
  LLoader: IXcomGameLoader;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
  LSettings: TXcomLoaderSettings;
begin
  if FReference = '' then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  LSettings.DataFolder := FDataFolder;
  LSettings.GameFolder := FGameFolder;
  LSettings.ModId := 'xcom2';
  LSettings.LanguageId := 'en-US';
  LSettings.Wordwrap := twAuto;
  LLoader := TXcomModGameLoader.Create(LSettings, TXcomDiskFileSystem.Create, TYamlFactory.CreateParser,
    TPngProvider.Client);
  LLoader.Load(LResources, LLanguage);
  LWorld := TTestWorld.Create;
  try
    LWorld.Game.AdoptData(LResources, LLanguage);
    LWorld.Game.SetState(TXcomMainMenuState.Create(LWorld.Game, '1.0 git 2026-06-05 22:05'));
    LWorld.Click(5000, 5000);
    LWorld.Wait(500);
    // a click on New Game; the cursor stays where it clicked, as in the frame of the real game
    LWorld.Click(220, 200);
    LWorld.Wait(500);
    Assert.AreEqual(Golden('newgame'), Hash(LWorld));
  finally
    LWorld.Free;
  end;
end;

procedure TTestXcomRealData.IDatiVeriDannoLeStringheLePaletteEIFont;
var
  LLoader: IXcomGameLoader;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
  LSettings: TXcomLoaderSettings;
begin
  if FReference = '' then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  LSettings.DataFolder := FDataFolder;
  LSettings.GameFolder := FGameFolder;
  LSettings.ModId := 'xcom2';
  LSettings.LanguageId := '';
  LSettings.Wordwrap := twAuto;
  LLoader := TXcomModGameLoader.Create(LSettings, TXcomDiskFileSystem.Create, TYamlFactory.CreateParser,
    TPngProvider.Client);
  LLoader.Load(LResources, LLanguage);
  try
    Assert.AreEqual('en-US', LLanguage.LanguageId);
    Assert.AreEqual('New Game', LLanguage.GetString('STR_NEW_GAME').Text);
    Assert.IsTrue(LLanguage.Count > 1000);
    Assert.AreEqual(320, LResources.GetSurface('BACK01.SCR').Width);
    Assert.AreEqual(200, LResources.GetSurface('back01.scr').Height);
    Assert.AreEqual(16, LResources.GetFont('FONT_BIG').Height);
    Assert.AreEqual(9, LResources.GetFont('FONT_SMALL').Height);
    Assert.IsNotNull(LResources.GetInterface('mainMenu'));
    Assert.IsNull(LResources.GetInterface('nope'));
    Assert.AreEqual(252, LResources.CursorColor('PAL_GEOSCAPE'));
    Assert.AreEqual(144, LResources.CursorColor('PAL_BATTLESCAPE'));
    Assert.AreEqual(0, Integer(LResources.GetPalette('PAL_GEOSCAPE')^.Alpha));
    Assert.WillRaise(
      procedure
      begin
        LResources.GetFont('FONT_NOPE');
      end, EXcomEngineException);
    Assert.WillRaise(
      procedure
      begin
        LResources.GetPalette('NOPE');
      end, EXcomEngineException);
    Assert.WillRaise(
      procedure
      begin
        LResources.GetSurface('NOPE.SCR');
      end, EXcomEngineException);
  finally
    LLanguage.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomStartState);
  TDUnitX.RegisterTestFixture(TTestXcomMainMenuState);
  TDUnitX.RegisterTestFixture(TTestXcomNewGameState);
  TDUnitX.RegisterTestFixture(TTestXcomRealData);

end.
