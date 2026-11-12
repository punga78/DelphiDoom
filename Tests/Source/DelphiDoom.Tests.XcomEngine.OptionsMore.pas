{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the table of the options, the generic access to    }
{  them, the saving of options.cfg, the names of the keys and the screens of    }
{  controls, geoscape, battlescape, advanced and folders                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.OptionsMore;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.OptionInfo, DelphiDoom.XcomEngine.OptionTable, DelphiDoom.XcomEngine.KeyNames,
  DelphiDoom.XcomEngine.ExtraOptions.Intf,
  DelphiDoom.XcomEngine.SoundConverter, DelphiDoom.XcomEngine.FileOptionsStore, DelphiDoom.XcomEngine.OptionsStore.Intf, DelphiDoom.XcomEngine.FolderOpener.Intf, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Slider, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf,
  DelphiDoom.XcomMenu.OptionsControlsState, DelphiDoom.XcomMenu.OptionsAdvancedState,
  DelphiDoom.XcomMenu.OptionsGeoscapeState, DelphiDoom.XcomMenu.OptionsBattlescapeState,
  DelphiDoom.XcomMenu.OptionsFoldersState, DelphiDoom.XcomMenu.MenuOptionsNavigator, DelphiDoom.XcomMenu.MainMenuState,
  DelphiDoom.XcomMenu.SetWindowedRootState,
  DelphiDoom.Tests.XcomEngine.World;

type
  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomOptionTable = class
  public
    [Test]
    procedure HaTuttiGliIdentificatoriDiversi;
    [Test]
    procedure UnTastoHaIlCodiceDiSdlComePredefinito;
    [Test]
    procedure UnaOpzioneSconosciutaNonSiTrova;
    [Test]
    procedure LeOpzioniDiUnaCategoriaHannoUnaDescrizione;
    [Test]
    procedure IPredefinitiDelleVelocitaSonoQuelliDelLoro;
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomOptionsGeneric = class
  public
    [Test]
    procedure UnaOpzioneSenzaCampoStaInUnDizionario;
    [Test]
    procedure UnaOpzioneConCampoPassaDalCampo;
    [Test]
    procedure LeStringheDelleOpzioniSiLeggonoESiScrivono;
    [Test]
    procedure LeChiaviSconosciuteSiConservano;
    [Test]
    procedure IlSalvataggioEOrdinatoEContieneTutto;
    [Test]
    procedure IlSalvataggioEIlCaricamentoTornano;
    [Test]
    procedure UnaStringaVuotaSiScriveConLeVirgolette;
    [Test]
    procedure LaPosizioneDellaFinestraUsaIlNomeDiOpenXcom;
    [Test]
    procedure UnValoreSbagliatoLasciaQuelloCorrente;
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomOptionsFile = class
  strict private
    FFiles: TFakeFileSystem;
    FFilesRef: IXcomFileSystem;
    function Text: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SalvaConservaLeAltreSezioni;
    [Test]
    procedure SalvaConservaLeChiaviSconosciute;
    [Test]
    procedure SenzaFileScriveSoloLeOpzioni;
    [Test]
    procedure UnFileSenzaOpzioniLeAggiungeInFondo;
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomKeyNames = class
  public
    [TestCase('return', '13,return')]
    [TestCase('escape', '27,escape')]
    [TestCase('lettera', '97,a')]
    [TestCase('piu', '43,+')]
    [TestCase('f12', '293,f12')]
    [TestCase('su', '273,up')]
    [TestCase('pagina su', '280,page up')]
    [TestCase('shift', '304,left shift')]
    [TestCase('keypad', '260,[4]')]
    [TestCase('delete', '127,delete')]
    [TestCase('mondo', '165,world 5')]
    [TestCase('sconosciuto', '9999,unknown key')]
    procedure IlNomeDelTasto(ACode: Integer; const AName: string);
    [Test]
    procedure LeParoleHannoLIniziale;
    [Test]
    procedure UnTastoSconosciutoNonSiMostra;
    [Test]
    procedure UnaStringaVuotaRestaVuota;
  end;

  [TestFixture]
  [Category('XcomSound')]
  TTestXcomSoundConverter = class
  public
    [Test]
    procedure UnSuonoGrezzoDiventaUnFileWavA11025Hz;
    [Test]
    procedure ILCampioniSiScalanoEGiranoAOttoBit;
    [Test]
    procedure UnSuonoTroppoCortoNonDaNulla;
    [Test]
    procedure UnSuonoPerIndiceHaCampioniConSegnoA11025HzSenzaRicampionare;
    [Test]
    procedure IlVolumeScalaIntornoAlSilenzio;
    [Test]
    procedure UnFileNonPcmAOttoBitRestaCom;
  end;

  TFakeFolderOpener = class(TInterfacedObject, IXcomFolderOpener)
  public
    Opened: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Open(const APath: string);
  end;

  /// <summary>Two settings that OpenXcom does not have, the second one on</summary>
  TFakeExtraOptions = class(TInterfacedObject, IXcomExtraOptions)
  public
    Values: array[0..1] of Boolean;
    function Heading: string;
    function Count: Integer;
    function Title(AIndex: Integer): string;
    function Description(AIndex: Integer): string;
    function IsOn(AIndex: Integer): Boolean;
    procedure SetOn(AIndex: Integer; AValue: Boolean);
  end;

  TFakeNav = class(TInterfacedObject, IXcomOptionsNavigator)
  public
    function CreateCategory(ACategory: TXcomOptionsCategory; AOrigin: TXcomOptionsOrigin;
      AHost: TXcomStateHost): TXcomState;
    procedure Restart(AOrigin: TXcomOptionsOrigin; AHost: TXcomStateHost);
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomOptionsMoreScreens = class
  strict private
    FWorld: TTestWorld;
    FNavigator: IXcomOptionsNavigator;
    FOpener: TFakeFolderOpener;
    FOpenerRef: IXcomFolderOpener;
    procedure ClickAt(AX, AY: Integer);
    procedure RightClickAt(AX, AY: Integer);
    procedure PressKey(AKey: Integer);
    procedure MoveTo(AX, AY: Integer);
    procedure ClickRow(AList: TObject; ARow: Integer; AButton: Integer = 1);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlNavigatoreCreaTutteLeCategorie;
    [Test]
    procedure ControlsElencaITastiPerGruppo;
    [Test]
    procedure ControlsUnClicEUnTastoCambiaLOpzione;
    [Test]
    procedure ControlsIlTastoDestroSvuotaLOpzione;
    [Test]
    procedure ControlsUnClicSuUnTitoloNonSelezionaNulla;
    [Test]
    procedure AdvancedUnSiNoSiInverte;
    [Test]
    procedure AdvancedUnNumeroSaleEGira;
    [Test]
    procedure AdvancedIlTastoDestroAbbassa;
    [Test]
    procedure AdvancedLeVelocitaSaltanoDiDieci;
[Test]
    procedure AdvancedSenzaImpostazioniInPiuHaLeRigheDiOpenXcom;
    [Test]
    procedure AdvancedLeImpostazioniInPiuSeguonoLUltimaSezione;
    [Test]
    procedure AdvancedUnClicSuUnaImpostazioneInPiuLaInverte;
    [Test]
    procedure AdvancedUnaImpostazioneInPiuHaLaSuaDescrizione;
    [Test]
    procedure GeoscapeIlCursoreDellaVelocitaCambiaLOpzione;
    [Test]
    procedure GeoscapeUnPulsanteInvertePerOpzione;
    [Test]
    procedure BattlescapeIlPercorsoUsaDueBit;
    [Test]
    procedure FoldersUnClicChiedeDiAprireLaCartella;
    [Test]
    procedure SliderUnaGammaAlContrarioPosizionaIlCursoreEsatto;
    [Test]
    procedure GeoscapeITreCursoriEIMenuCambianoLeOpzioni;
    [Test]
    procedure BattlescapeICursoriEIPulsantiCambianoLeOpzioni;
    [Test]
    procedure IlNavigatoreDelMenuRiportaAlMenuPrincipale;
    [Test]
    procedure LeOpzioniDiUnaBattagliaDovrebberoTornareAlloStatoCheLeHaAperte;
    [Test]
    procedure LaPosizioneDellaFinestraSiImpostaConOk;
    [Test]
    procedure LaPosizioneDellaFinestraAnnullaChiamaIlGestore;
  end;

implementation

uses
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.ToggleTextButton;

{ TTestXcomOptionTable }

procedure TTestXcomOptionTable.HaTuttiGliIdentificatoriDiversi;
var
  LSeen: TDictionary<string, Boolean>;
  LInfo: TXcomOptionInfo;
begin
  LSeen := TDictionary<string, Boolean>.Create;
  try
    for LInfo in TXcomOptionTable.All do
    begin
      Assert.IsFalse(LSeen.ContainsKey(LInfo.Id), LInfo.Id);
      LSeen.Add(LInfo.Id, True);
    end;
    Assert.IsTrue(LSeen.Count > 150);
  finally
    LSeen.Free;
  end;
end;

procedure TTestXcomOptionTable.UnTastoHaIlCodiceDiSdlComePredefinito;
var
  LInfo: TXcomOptionInfo;
begin
  Assert.IsTrue(TXcomOptionTable.TryFind('keyOk', LInfo));
  Assert.AreEqual(Ord(okKey), Ord(LInfo.Kind));
  Assert.AreEqual(13, LInfo.DefaultValue);
  Assert.AreEqual('STR_OK', LInfo.Description);
  Assert.AreEqual('STR_GENERAL', LInfo.Category);
  Assert.IsTrue(TXcomOptionTable.TryFind('keyBattleCenterEnemy10', LInfo));
  Assert.AreEqual(48, LInfo.DefaultValue);
end;

procedure TTestXcomOptionTable.UnaOpzioneSconosciutaNonSiTrova;
var
  LInfo: TXcomOptionInfo;
begin
  Assert.IsFalse(TXcomOptionTable.TryFind('ambienceVolume', LInfo));
  // the id is compared as it is written
  Assert.IsFalse(TXcomOptionTable.TryFind('fps', LInfo));
  Assert.IsTrue(TXcomOptionTable.TryFind('FPS', LInfo));
end;

procedure TTestXcomOptionTable.LeOpzioniDiUnaCategoriaHannoUnaDescrizione;
var
  LInfo: TXcomOptionInfo;
  LKeys: Integer;
  LSettings: Integer;
begin
  LKeys := 0;
  LSettings := 0;
  for LInfo in TXcomOptionTable.All do
    if LInfo.Category <> '' then
    begin
      Assert.IsTrue(LInfo.Description <> '', LInfo.Id);
      if LInfo.Kind = okKey then
        Inc(LKeys)
      else
        Inc(LSettings);
    end;
  // 6 general, 28 geoscape and 42 battlescape keys; 43 settings with a description
  Assert.AreEqual(76, LKeys);
  Assert.AreEqual(43, LSettings);
end;

procedure TTestXcomOptionTable.IPredefinitiDelleVelocitaSonoQuelliDelLoro;
var
  LInfo: TXcomOptionInfo;
begin
  Assert.IsTrue(TXcomOptionTable.TryFind('dogfightSpeed', LInfo));
  Assert.AreEqual(30, LInfo.DefaultValue);
  Assert.IsTrue(TXcomOptionTable.TryFind('soundVolume', LInfo));
  Assert.AreEqual(84, LInfo.DefaultValue);
  Assert.IsTrue(TXcomOptionTable.TryFind('uiVolume', LInfo));
  Assert.AreEqual(42, LInfo.DefaultValue);
  Assert.IsTrue(TXcomOptionTable.TryFind('useOpenGLShader', LInfo));
  Assert.AreEqual(Ord(okString), Ord(LInfo.Kind));
  Assert.AreEqual('Shaders/Raw.OpenGL.shader', LInfo.DefaultText);
end;

{ TTestXcomOptionsGeneric }

procedure TTestXcomOptionsGeneric.UnaOpzioneSenzaCampoStaInUnDizionario;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    Assert.AreEqual(5, LOptions.GetValue('autosaveFrequency'));
    Assert.IsTrue(LOptions.GetBool('autosave'));
    LOptions.SetValue('autosaveFrequency', 3);
    LOptions.SetBool('autosave', False);
    Assert.AreEqual(3, LOptions.GetValue('autosaveFrequency'));
    Assert.IsFalse(LOptions.GetBool('autosave'));
    LOptions.ResetDefaults;
    Assert.AreEqual(5, LOptions.GetValue('autosaveFrequency'));
    Assert.AreEqual(0, LOptions.GetValue('notAnOption'));
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsGeneric.UnaOpzioneConCampoPassaDalCampo;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.SetBool('fpsCounter', True);
    Assert.IsTrue(LOptions.FpsCounter);
    LOptions.FPS := 45;
    Assert.AreEqual(45, LOptions.GetValue('FPS'));
    LOptions.SetValue('wordwrap', 2);
    Assert.AreEqual(2, Integer(Ord(LOptions.Wordwrap)));
    LOptions.SetValue('keyboardMode', 0);
    Assert.AreEqual(Ord(kmOff), Ord(LOptions.KeyboardMode));
    LOptions.SetValue('keyOk', 65);
    Assert.AreEqual(65, LOptions.KeyOk);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsGeneric.LeStringheDelleOpzioniSiLeggonoESiScrivono;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    Assert.AreEqual('Shaders/Raw.OpenGL.shader', LOptions.GetText('useOpenGLShader'));
    LOptions.SetText('language', 'it');
    Assert.AreEqual('it', LOptions.Language);
    Assert.AreEqual('', LOptions.GetText('displayWidth'));
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsGeneric.LeChiaviSconosciuteSiConservano;
var
  LOptions: TXcomOptions;
  LCopy: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  LCopy := TXcomOptions.Create;
  try
    LOptions.Load(TTestWorld.Parse('options:'#10'  ambienceVolume: 17'#10'  newThing: "a b"'#10'  displayWidth: 800'#10));
    Assert.AreEqual('17', LOptions.UnknownOptions['ambienceVolume']);
    Assert.AreEqual('a b', LOptions.UnknownOptions['newThing']);
    Assert.AreEqual(2, LOptions.UnknownOptions.Count);
    Assert.AreEqual(800, LOptions.DisplayWidth);
    LCopy.Load(TTestWorld.Parse(LOptions.Save));
    Assert.AreEqual('17', LCopy.UnknownOptions['ambienceVolume']);
    Assert.AreEqual('a b', LCopy.UnknownOptions['newThing']);
  finally
    LCopy.Free;
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsGeneric.IlSalvataggioEOrdinatoEContieneTutto;
var
  LOptions: TXcomOptions;
  LText: string;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.Load(TTestWorld.Parse('options:'#10'  ambienceVolume: 17'#10));
    LText := LOptions.Save;
    Assert.IsTrue(LText.StartsWith('options:'#10'  FPS: 60'#10'  FPSInactive: 30'#10));
    Assert.IsTrue(Pos('  keyOk: 13'#10, LText) > 0);
    Assert.IsTrue(Pos('  ambienceVolume: 17'#10, LText) > Pos('  allowResize: false'#10, LText));
    Assert.IsTrue(Pos('  autosave: true'#10, LText) > 0);
    Assert.IsTrue(Pos('  useOpenGLShader: Shaders/Raw.OpenGL.shader'#10, LText) > 0);
    // the keys that only the options have: the pending video ones are not written
    Assert.AreEqual(0, Pos('newDisplayWidth', LText));
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsGeneric.IlSalvataggioEIlCaricamentoTornano;
var
  LOptions: TXcomOptions;
  LCopy: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  LCopy := TXcomOptions.Create;
  try
    LOptions.SetValue('battleXcomSpeed', 12);
    LOptions.SetValue('keyGeoBases', 99);
    LOptions.SetBool('globeSeasons', True);
    LOptions.SetValue('windowedModePositionX', 77);
    LOptions.SetText('language', 'de');
    LCopy.Load(TTestWorld.Parse(LOptions.Save));
    Assert.AreEqual(12, LCopy.GetValue('battleXcomSpeed'));
    Assert.AreEqual(99, LCopy.GetValue('keyGeoBases'));
    Assert.IsTrue(LCopy.GetBool('globeSeasons'));
    Assert.AreEqual(77, LCopy.WindowedModePositionX);
    Assert.AreEqual('de', LCopy.Language);
  finally
    LCopy.Free;
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsGeneric.UnaStringaVuotaSiScriveConLeVirgolette;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    Assert.IsTrue(Pos('  language: ""'#10, LOptions.Save) > 0);
    LOptions.SetText('language', 'a: b');
    Assert.IsTrue(Pos('  language: "a: b"'#10, LOptions.Save) > 0);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsGeneric.LaPosizioneDellaFinestraUsaIlNomeDiOpenXcom;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.Load(TTestWorld.Parse('options:'#10'  windowedModePositionX: 5'#10'  windowedModePositionY: 6'#10));
    Assert.AreEqual(5, LOptions.WindowedModePositionX);
    Assert.AreEqual(6, LOptions.WindowedModePositionY);
    Assert.AreEqual(5, LOptions.NewWindowedModePositionX);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsGeneric.UnValoreSbagliatoLasciaQuelloCorrente;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.Load(TTestWorld.Parse('options:'#10'  autosaveFrequency: many'#10'  autosave: [1]'#10'  keyOk: x'#10));
    Assert.AreEqual(5, LOptions.GetValue('autosaveFrequency'));
    Assert.IsTrue(LOptions.GetBool('autosave'));
    Assert.AreEqual(13, LOptions.KeyOk);
    // a map or a list is not an unknown scalar: it is not kept
    Assert.AreEqual(0, LOptions.UnknownOptions.Count);
  finally
    LOptions.Free;
  end;
end;

{ TTestXcomOptionsFile }

procedure TTestXcomOptionsFile.Setup;
begin
  FFiles := TFakeFileSystem.Create;
  FFilesRef := FFiles;
end;

procedure TTestXcomOptionsFile.TearDown;
begin
  FFilesRef := nil;
end;

function TTestXcomOptionsFile.Text: string;
begin
  Result := TEncoding.UTF8.GetString(FFilesRef.ReadAll('user\options.cfg'));
end;

procedure TTestXcomOptionsFile.SalvaConservaLeAltreSezioni;
var
  LStore: TXcomFileOptionsStore;
  LStoreRef: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put('user\options.cfg', 'mods:'#10'  - active: true'#10'    id: xcom2'#10'options:'#10'  displayWidth: 100'#10 +
    'recentlyLoaded:'#10'  - a'#10);
  LStore := TXcomFileOptionsStore.Create(FFilesRef, TYamlFactory.CreateParser, 'user');
  LStoreRef := LStore;
  LOptions := TXcomOptions.Create;
  try
    LOptions.DisplayWidth := 1024;
    LStoreRef.Save(LOptions);
    Assert.IsTrue(Text.StartsWith('mods:'#10'  - active: true'#10'    id: xcom2'#10'options:'#10));
    Assert.IsTrue(Pos('  displayWidth: 1024'#10, Text) > 0);
    Assert.AreEqual(0, Pos('displayWidth: 100'#10, Text));
    Assert.IsTrue(Text.EndsWith('recentlyLoaded:'#10'  - a'#10));
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsFile.SalvaConservaLeChiaviSconosciute;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
  LCopy: TXcomOptions;
begin
  FFiles.Put('user\options.cfg', 'options:'#10'  ambienceVolume: 17'#10'  keyOk: 14'#10);
  LStore := TXcomFileOptionsStore.Create(FFilesRef, TYamlFactory.CreateParser, 'user');
  LOptions := TXcomOptions.Create;
  LCopy := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    Assert.AreEqual(14, LOptions.KeyOk);
    LOptions.SetValue('autosaveFrequency', 2);
    LStore.Save(LOptions);
    LStore.Load(LCopy);
    Assert.AreEqual('17', LCopy.UnknownOptions['ambienceVolume']);
    Assert.AreEqual(2, LCopy.GetValue('autosaveFrequency'));
    Assert.AreEqual(14, LCopy.KeyOk);
  finally
    LCopy.Free;
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsFile.SenzaFileScriveSoloLeOpzioni;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  LStore := TXcomFileOptionsStore.Create(FFilesRef, TYamlFactory.CreateParser, 'user');
  LOptions := TXcomOptions.Create;
  try
    LStore.Save(LOptions);
    Assert.IsTrue(Text.StartsWith('options:'#10));
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsFile.UnFileSenzaOpzioniLeAggiungeInFondo;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put('user\options.cfg', 'mods:'#10'  - id: x'#10);
  LStore := TXcomFileOptionsStore.Create(FFilesRef, TYamlFactory.CreateParser, 'user');
  LOptions := TXcomOptions.Create;
  try
    LStore.Save(LOptions);
    Assert.IsTrue(Text.StartsWith('mods:'#10'  - id: x'#10'options:'#10));
  finally
    LOptions.Free;
  end;
end;

{ TTestXcomKeyNames }

procedure TTestXcomKeyNames.IlNomeDelTasto(ACode: Integer; const AName: string);
begin
  Assert.AreEqual(AName, TXcomKeyNames.Name(ACode));
end;

procedure TTestXcomKeyNames.LeParoleHannoLIniziale;
begin
  Assert.AreEqual('Page Up', TXcomKeyNames.UpperWords('page up'));
  Assert.AreEqual('Left Shift', TXcomKeyNames.Display(304));
  Assert.AreEqual('A', TXcomKeyNames.UpperWords('a'));
  Assert.AreEqual('Ab ', TXcomKeyNames.UpperWords('ab '));
end;

procedure TTestXcomKeyNames.UnTastoSconosciutoNonSiMostra;
begin
  Assert.AreEqual('', TXcomKeyNames.Display(0));
end;

procedure TTestXcomKeyNames.UnaStringaVuotaRestaVuota;
begin
  Assert.AreEqual('', TXcomKeyNames.UpperWords(''));
end;

{ TTestXcomSoundConverter }

procedure TTestXcomSoundConverter.UnSuonoGrezzoDiventaUnFileWavA11025Hz;
var
  LWave: TBytes;
begin
  // five bytes of garbage, four samples and the null at the end
  LWave := TXcomSoundConverter.RawToWave([9, 9, 9, 9, 9, 1, 2, 3, 4, 0]);
  Assert.AreEqual('RIFF', TEncoding.ASCII.GetString(LWave, 0, 4));
  Assert.AreEqual('WAVE', TEncoding.ASCII.GetString(LWave, 8, 4));
  Assert.AreEqual(11025, Integer(PCardinal(@LWave[24])^));
  Assert.AreEqual(8, Integer(PWord(@LWave[34])^));
  // 4 samples at 8000 Hz are 6 at 11025 Hz
  Assert.AreEqual(44 + 6, Integer(Length(LWave)));
  Assert.AreEqual(6, Integer(PCardinal(@LWave[40])^));
  Assert.AreEqual(6 + 36, Integer(PCardinal(@LWave[4])^));
end;

procedure TTestXcomSoundConverter.ILCampioniSiScalanoEGiranoAOttoBit;
var
  LWave: TBytes;
begin
  LWave := TXcomSoundConverter.RawToWave([0, 0, 0, 0, 0, 1, 2, 3, 4, 64, 0]);
  // the samples are multiplied by 4 keeping the low byte (64 * 4 = 0), and repeated by the change of rate
  Assert.AreEqual(4, Integer(LWave[44]));
  Assert.AreEqual(4, Integer(LWave[45]));
  Assert.AreEqual(8, Integer(LWave[46]));
  Assert.AreEqual(12, Integer(LWave[47]));
  Assert.AreEqual(12, Integer(LWave[48]));
  Assert.AreEqual(16, Integer(LWave[49]));
end;

procedure TTestXcomSoundConverter.UnSuonoTroppoCortoNonDaNulla;
begin
  Assert.AreEqual(0, Integer(Length(TXcomSoundConverter.RawToWave(nil))));
  Assert.AreEqual(0, Integer(Length(TXcomSoundConverter.RawToWave([1, 2, 3, 4, 5]))));
  Assert.AreEqual(0, Integer(Length(TXcomSoundConverter.RawToWave([1, 2, 3, 4, 5, 6]))));
end;

procedure TTestXcomSoundConverter.UnSuonoPerIndiceHaCampioniConSegnoA11025HzSenzaRicampionare;
var
  LWave: TBytes;
begin
  // SoundSet::loadCatbyIndex: five bytes of name, signed samples, a null at the end
  LWave := TXcomSoundConverter.IndexedToWave([9, 9, 9, 9, 9, 0, 1, 127, 128, 255, 0]);
  Assert.AreEqual(44 + 5, Integer(Length(LWave)));
  Assert.AreEqual(11025, Integer(PCardinal(@LWave[24])^));
  Assert.AreEqual(5, Integer(PCardinal(@LWave[40])^));
  Assert.AreEqual(128, Integer(LWave[44]));
  Assert.AreEqual(129, Integer(LWave[45]));
  Assert.AreEqual(255, Integer(LWave[46]));
  Assert.AreEqual(0, Integer(LWave[47]));
  Assert.AreEqual(127, Integer(LWave[48]));
  Assert.AreEqual(0, Integer(Length(TXcomSoundConverter.IndexedToWave(nil))));
  // five bytes or fewer: only the header, as the C++ that then fails to load it
  Assert.AreEqual(44, Integer(Length(TXcomSoundConverter.IndexedToWave([1, 2, 3]))));
end;

procedure TTestXcomSoundConverter.IlVolumeScalaIntornoAlSilenzio;
var
  LWave: TBytes;
begin
  LWave := TXcomSoundConverter.RawToWave([0, 0, 0, 0, 0, 63, 0, 0]);
  // 63 * 4 = 252: 124 over the silence
  Assert.AreEqual(252, Integer(LWave[44]));
  Assert.AreEqual(128 + 124 div 2, Integer(TXcomSoundConverter.WithVolume(LWave, 64)[44]));
  Assert.AreEqual(128, Integer(TXcomSoundConverter.WithVolume(LWave, 0)[44]));
  Assert.AreEqual(252, Integer(TXcomSoundConverter.WithVolume(LWave, 128)[44]));
  Assert.AreEqual(252, Integer(TXcomSoundConverter.WithVolume(LWave, 999)[44]));
end;

procedure TTestXcomSoundConverter.UnFileNonPcmAOttoBitRestaCom;
var
  LWave: TBytes;
begin
  LWave := TXcomSoundConverter.RawToWave([0, 0, 0, 0, 0, 63, 0, 0]);
  LWave[34] := 16;
  Assert.AreEqual(Integer(LWave[44]), Integer(TXcomSoundConverter.WithVolume(LWave, 10)[44]));
  Assert.AreEqual(3, Integer(Length(TXcomSoundConverter.WithVolume([1, 2, 3], 10))));
end;

{ TFakeExtraOptions }

function TFakeExtraOptions.Heading: string;
begin
  Result := 'EXTRA';
end;

function TFakeExtraOptions.Count: Integer;
begin
  Result := Length(Values);
end;

function TFakeExtraOptions.Title(AIndex: Integer): string;
begin
  Result := 'Setting ' + IntToStr(AIndex);
end;

function TFakeExtraOptions.Description(AIndex: Integer): string;
begin
  Result := 'What the setting ' + IntToStr(AIndex) + ' does';
end;

function TFakeExtraOptions.IsOn(AIndex: Integer): Boolean;
begin
  Result := Values[AIndex];
end;

procedure TFakeExtraOptions.SetOn(AIndex: Integer; AValue: Boolean);
begin
  Values[AIndex] := AValue;
end;

{ TFakeFolderOpener }

constructor TFakeFolderOpener.Create;
begin
  inherited Create;
  Opened := TStringList.Create;
end;

destructor TFakeFolderOpener.Destroy;
begin
  Opened.Free;
  inherited Destroy;
end;

procedure TFakeFolderOpener.Open(const APath: string);
begin
  Opened.Add(APath);
end;

{ TFakeNav }

function TFakeNav.CreateCategory(ACategory: TXcomOptionsCategory; AOrigin: TXcomOptionsOrigin;
  AHost: TXcomStateHost): TXcomState;
begin
  Result := nil;
end;

procedure TFakeNav.Restart(AOrigin: TXcomOptionsOrigin; AHost: TXcomStateHost);
begin
end;

{ TTestXcomOptionsMoreScreens }

procedure TTestXcomOptionsMoreScreens.Setup;
begin
  FWorld := TTestWorld.Create;
  FNavigator := TFakeNav.Create;
  FOpener := TFakeFolderOpener.Create;
  FOpenerRef := FOpener;
  FWorld.Game.SetFolderOpener(FOpenerRef);
end;

procedure TTestXcomOptionsMoreScreens.TearDown;
begin
  FNavigator := nil;
  FOpenerRef := nil;
  FWorld.Free;
end;

procedure TTestXcomOptionsMoreScreens.ClickAt(AX, AY: Integer);
begin
  FWorld.Click(Round(AX * FWorld.Game.Screen.XScale), Round(AY * FWorld.Game.Screen.YScale));
end;

procedure TTestXcomOptionsMoreScreens.RightClickAt(AX, AY: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := Round(AX * FWorld.Game.Screen.XScale);
  LEvent.Y := Round(AY * FWorld.Game.Screen.YScale);
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
  LEvent.Kind := ekMouseDown;
  LEvent.Button := XCOM_BUTTON_RIGHT;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
  LEvent.Kind := ekMouseUp;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
end;

procedure TTestXcomOptionsMoreScreens.MoveTo(AX, AY: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := Round(AX * FWorld.Game.Screen.XScale);
  LEvent.Y := Round(AY * FWorld.Game.Screen.YScale);
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
end;

procedure TTestXcomOptionsMoreScreens.PressKey(AKey: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
  LEvent.Kind := ekKeyUp;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
end;

procedure TTestXcomOptionsMoreScreens.ClickRow(AList: TObject; ARow: Integer; AButton: Integer);
var
  LList: TXcomTextList;
  LX: Integer;
  LY: Integer;
begin
  LList := TXcomTextList(AList);
  LX := LList.X + 20;
  // the mouse goes down the list until the row under it is the one wanted
  LY := LList.Y;
  while (LY < LList.Y + LList.Height) do
  begin
    MoveTo(LX, LY);
    if LList.GetSelectedRow = ARow then
      Break;
    Inc(LY);
  end;
  Assert.AreEqual(ARow, LList.GetSelectedRow);
  if AButton = XCOM_BUTTON_RIGHT then
    RightClickAt(LX, LY)
  else
    ClickAt(LX, LY);
end;

procedure TTestXcomOptionsMoreScreens.IlNavigatoreCreaTutteLeCategorie;
var
  LNavigator: IXcomOptionsNavigator;
  LCategory: TXcomOptionsCategory;
  LState: TXcomState;
begin
  LNavigator := TXcomMenuOptionsNavigator.Create('v');
  for LCategory := Low(TXcomOptionsCategory) to High(TXcomOptionsCategory) do
  begin
    // the video screen needs the languages of a real folder: it is in the tests of the video options
    if LCategory = ocVideo then
      Continue;
    LState := LNavigator.CreateCategory(LCategory, ooMenu, FWorld.Game);
    try
      Assert.IsNotNull(LState, IntToStr(Ord(LCategory)));
    finally
      LState.Free;
    end;
  end;
end;

procedure TTestXcomOptionsMoreScreens.ControlsElencaITastiPerGruppo;
var
  LState: TXcomOptionsControlsState;
  LInfo: TXcomOptionInfo;
  LKeys: Integer;
begin
  LKeys := 0;
  for LInfo in TXcomOptionTable.All do
    if (LInfo.Kind = okKey) and (LInfo.Description <> '') then
      Inc(LKeys);
  LState := TXcomOptionsControlsState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  // the keys, three headings and two blank rows (a description that wraps takes two lines)
  Assert.IsTrue(LState.List.GetRows >= LKeys + 5);
  Assert.AreEqual('Return', LState.List.GetCellText(1, 1));
  Assert.AreEqual('Escape', LState.List.GetCellText(2, 1));
  Assert.AreEqual('F12', LState.List.GetCellText(3, 1));
  Assert.AreEqual('F9', LState.List.GetCellText(6, 1));
  Assert.AreEqual('', LState.List.GetCellText(7, 1));
  Assert.AreEqual('', LState.List.GetCellText(7, 0));
  Assert.AreEqual('STR_GEOSCAPE', LState.List.GetCellText(8, 0));
end;

procedure TTestXcomOptionsMoreScreens.ControlsUnClicEUnTastoCambiaLOpzione;
var
  LState: TXcomOptionsControlsState;
begin
  LState := TXcomOptionsControlsState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  // row 1 is the key OK
  ClickRow(LState.List, 1);
  PressKey(Ord('x'));
  Assert.AreEqual(Ord('x'), FWorld.Game.Options.KeyOk);
  Assert.AreEqual('X', LState.List.GetCellText(1, 1));
  // a key without a selected row changes nothing
  PressKey(Ord('y'));
  Assert.AreEqual(Ord('x'), FWorld.Game.Options.KeyOk);
end;

procedure TTestXcomOptionsMoreScreens.ControlsIlTastoDestroSvuotaLOpzione;
var
  LState: TXcomOptionsControlsState;
begin
  LState := TXcomOptionsControlsState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  ClickRow(LState.List, 2, XCOM_BUTTON_RIGHT);
  Assert.AreEqual(0, FWorld.Game.Options.KeyCancel);
  Assert.AreEqual('', LState.List.GetCellText(2, 1));
end;

procedure TTestXcomOptionsMoreScreens.ControlsUnClicSuUnTitoloNonSelezionaNulla;
var
  LState: TXcomOptionsControlsState;
begin
  LState := TXcomOptionsControlsState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  ClickRow(LState.List, 0);
  PressKey(Ord('x'));
  Assert.AreEqual(13, FWorld.Game.Options.KeyOk);
end;

procedure TTestXcomOptionsMoreScreens.AdvancedUnSiNoSiInverte;
var
  LState: TXcomOptionsAdvancedState;
begin
  LState := TXcomOptionsAdvancedState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  // rows: 0 General, 1 Play intro, 2 Autosave
  Assert.IsTrue(FWorld.Game.Options.GetBool('autosave'));
  ClickRow(LState.List, 2);
  Assert.IsFalse(FWorld.Game.Options.GetBool('autosave'));
  ClickRow(LState.List, 2);
  Assert.IsTrue(FWorld.Game.Options.GetBool('autosave'));
end;

procedure TTestXcomOptionsMoreScreens.AdvancedSenzaImpostazioniInPiuHaLeRigheDiOpenXcom;
var
  LState: TXcomOptionsAdvancedState;
  LInfo: TXcomOptionInfo;
  LRows: Integer;
begin
  LState := TXcomOptionsAdvancedState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  // three headings, two empty rows between the sections and a row for every setting with a description
  LRows := 5;
  for LInfo in TXcomOptionTable.All do
    if (LInfo.Kind <> okKey) and (LInfo.Description <> '') and ((LInfo.Category = 'STR_GENERAL')
      or (LInfo.Category = 'STR_GEOSCAPE') or (LInfo.Category = 'STR_BATTLESCAPE')) then
      Inc(LRows);
  Assert.AreEqual(LRows, LState.List.GetRows);
end;

procedure TTestXcomOptionsMoreScreens.AdvancedLeImpostazioniInPiuSeguonoLUltimaSezione;
var
  LState: TXcomOptionsAdvancedState;
  LExtra: TFakeExtraOptions;
  LExtraRef: IXcomExtraOptions;
  LPlain: Integer;
  LRows: Integer;
begin
  LState := TXcomOptionsAdvancedState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  LPlain := LState.List.GetRows;
  FWorld.Game.PopState;
  LExtra := TFakeExtraOptions.Create;
  LExtraRef := LExtra;
  LExtra.Values[1] := True;
  FWorld.Game.SetExtraOptions(LExtraRef);
  LState := TXcomOptionsAdvancedState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  LRows := LState.List.GetRows;
  // an empty row, the heading and the two settings; the rows of OpenXcom are where they were
  Assert.AreEqual(LPlain + 4, LRows);
  Assert.AreEqual('', LState.List.GetCellText(LPlain, 0));
  Assert.AreEqual('EXTRA', LState.List.GetCellText(LPlain + 1, 0));
  Assert.AreEqual('Setting 0', LState.List.GetCellText(LPlain + 2, 0));
  Assert.AreEqual(FWorld.Game.Language.GetString('STR_NO').Text, LState.List.GetCellText(LPlain + 2, 1));
  Assert.AreEqual('Setting 1', LState.List.GetCellText(LPlain + 3, 0));
  Assert.AreEqual(FWorld.Game.Language.GetString('STR_YES').Text, LState.List.GetCellText(LPlain + 3, 1));
end;

procedure TTestXcomOptionsMoreScreens.AdvancedUnClicSuUnaImpostazioneInPiuLaInverte;
var
  LState: TXcomOptionsAdvancedState;
  LExtra: TFakeExtraOptions;
  LExtraRef: IXcomExtraOptions;
  LLast: Integer;
begin
  LExtra := TFakeExtraOptions.Create;
  LExtraRef := LExtra;
  FWorld.Game.SetExtraOptions(LExtraRef);
  LState := TXcomOptionsAdvancedState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  LState.List.ScrollDown(True);
  LLast := LState.List.GetRows - 1;
  ClickRow(LState.List, LLast);
  Assert.IsTrue(LExtra.Values[1]);
  Assert.IsFalse(LExtra.Values[0]);
  Assert.AreEqual(FWorld.Game.Language.GetString('STR_YES').Text, LState.List.GetCellText(LLast, 1));
  ClickRow(LState.List, LLast);
  Assert.IsFalse(LExtra.Values[1]);
  // the heading and the empty row before it are not settings
  ClickRow(LState.List, LLast - 2);
  Assert.IsFalse(LExtra.Values[0] or LExtra.Values[1]);
end;

procedure TTestXcomOptionsMoreScreens.AdvancedUnaImpostazioneInPiuHaLaSuaDescrizione;
var
  LState: TXcomOptionsAdvancedState;
  LExtraRef: IXcomExtraOptions;
  LY: Integer;
begin
  LExtraRef := TFakeExtraOptions.Create;
  FWorld.Game.SetExtraOptions(LExtraRef);
  LState := TXcomOptionsAdvancedState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  LState.List.ScrollDown(True);
  LY := LState.List.Y;
  while LY < LState.List.Y + LState.List.Height do
  begin
    MoveTo(LState.List.X + 20, LY);
    if LState.List.GetSelectedRow = LState.List.GetRows - 2 then
      Break;
    Inc(LY);
  end;
  Assert.AreEqual('What the setting 0 does', LState.TooltipText);
end;

procedure TTestXcomOptionsMoreScreens.AdvancedUnNumeroSaleEGira;
var
  LState: TXcomOptionsAdvancedState;
  LIndex: Integer;
begin
  LState := TXcomOptionsAdvancedState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  // row 3: the frequency of the autosave, from 1 to 5, now 5
  ClickRow(LState.List, 3);
  Assert.AreEqual(1, FWorld.Game.Options.GetValue('autosaveFrequency'));
  Assert.AreEqual('1', LState.List.GetCellText(3, 1));
  for LIndex := 1 to 4 do
    ClickRow(LState.List, 3);
  Assert.AreEqual(5, FWorld.Game.Options.GetValue('autosaveFrequency'));
end;

procedure TTestXcomOptionsMoreScreens.AdvancedIlTastoDestroAbbassa;
var
  LState: TXcomOptionsAdvancedState;
begin
  LState := TXcomOptionsAdvancedState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  ClickRow(LState.List, 3, XCOM_BUTTON_RIGHT);
  Assert.AreEqual(4, FWorld.Game.Options.GetValue('autosaveFrequency'));
  // at the lowest it goes to the highest
  FWorld.Game.Options.SetValue('autosaveFrequency', 1);
  ClickRow(LState.List, 3, XCOM_BUTTON_RIGHT);
  Assert.AreEqual(5, FWorld.Game.Options.GetValue('autosaveFrequency'));
end;

procedure TTestXcomOptionsMoreScreens.AdvancedLeVelocitaSaltanoDiDieci;
var
  LState: TXcomOptionsAdvancedState;
  LRow: Integer;
  LInfo: TXcomOptionInfo;
  LGeneral: Integer;
begin
  LState := TXcomOptionsAdvancedState.Create(FWorld.Game, ooMenu, FNavigator);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  // the position of FPS among the general settings
  LRow := 0;
  LGeneral := 0;
  for LInfo in TXcomOptionTable.All do
    if (LInfo.Kind <> okKey) and (LInfo.Category = 'STR_GENERAL') and (LInfo.Description <> '') then
    begin
      Inc(LGeneral);
      if LInfo.Id = 'FPS' then
        LRow := LGeneral;
    end;
  Assert.IsTrue(LRow > 0);
  FWorld.Game.Options.SetValue('FPS', 60);
  ClickRow(LState.List, LRow);
  Assert.AreEqual(70, FWorld.Game.Options.GetValue('FPS'));
  FWorld.Game.Options.SetValue('FPS', 120);
  ClickRow(LState.List, LRow);
  Assert.AreEqual(0, FWorld.Game.Options.GetValue('FPS'));
end;

procedure TTestXcomOptionsMoreScreens.GeoscapeIlCursoreDellaVelocitaCambiaLOpzione;
begin
  FWorld.Game.PushState(TXcomOptionsGeoscapeState.Create(FWorld.Game, ooMenu, FNavigator));
  FWorld.Wait(400);
  Assert.AreEqual(30, FWorld.Game.Options.GetValue('dogfightSpeed'));
  // the slider of the dogfight is at 206,50 and goes from 50 (left) to 20 (right)
  ClickAt(206 + 102, 58);
  Assert.AreEqual(20, FWorld.Game.Options.GetValue('dogfightSpeed'));
  ClickAt(206 + 10, 58);
  Assert.IsTrue(FWorld.Game.Options.GetValue('dogfightSpeed') >= 45);
end;

procedure TTestXcomOptionsMoreScreens.GeoscapeUnPulsanteInvertePerOpzione;
begin
  FWorld.Game.PushState(TXcomOptionsGeoscapeState.Create(FWorld.Game, ooMenu, FNavigator));
  FWorld.Wait(400);
  Assert.IsFalse(FWorld.Game.Options.GetBool('showFundsOnGeoscape'));
  // Show Funds is at 206,92
  ClickAt(250, 100);
  Assert.IsTrue(FWorld.Game.Options.GetBool('showFundsOnGeoscape'));
  ClickAt(250, 100);
  Assert.IsFalse(FWorld.Game.Options.GetBool('showFundsOnGeoscape'));
  // the countries of the globe start on
  Assert.IsTrue(FWorld.Game.Options.GetBool('globeDetail'));
  ClickAt(150, 100);
  Assert.IsFalse(FWorld.Game.Options.GetBool('globeDetail'));
end;

procedure TTestXcomOptionsMoreScreens.BattlescapeIlPercorsoUsaDueBit;
begin
  FWorld.Game.PushState(TXcomOptionsBattlescapeState.Create(FWorld.Game, ooMenu, FNavigator));
  FWorld.Wait(400);
  Assert.AreEqual(0, FWorld.Game.Options.GetValue('battleNewPreviewPath'));
  // the arrows are at 94,110 and the time unit cost at 94,128
  ClickAt(150, 118);
  Assert.AreEqual(1, FWorld.Game.Options.GetValue('battleNewPreviewPath'));
  ClickAt(150, 136);
  Assert.AreEqual(3, FWorld.Game.Options.GetValue('battleNewPreviewPath'));
  ClickAt(150, 118);
  Assert.AreEqual(2, FWorld.Game.Options.GetValue('battleNewPreviewPath'));
end;

procedure TTestXcomOptionsMoreScreens.FoldersUnClicChiedeDiAprireLaCartella;
begin
  FWorld.Game.Options.UserFolder := 'C:\user\';
  FWorld.Game.PushState(TXcomOptionsFoldersState.Create(FWorld.Game, ooMenu, FNavigator));
  FWorld.Wait(400);
  // the user folder is at 94,69
  ClickAt(120, 72);
  Assert.AreEqual(1, FOpener.Opened.Count);
  Assert.AreEqual('C:\user\', FOpener.Opened[0]);
end;

procedure TTestXcomOptionsMoreScreens.SliderUnaGammaAlContrarioPosizionaIlCursoreEsatto;
var
  LSlider: TXcomSlider;
  LExpected: Integer;
begin
  LSlider := TXcomSlider.Create(104, 16, 0, 0);
  try
    LSlider.SetRange(50, 20);
    LSlider.SetValue(30);
    // the knob runs 78 pixels (88 of the frame minus the 10 of the knob): 2/3 of 78 is exactly 52, a double gives 51.99
    LExpected := LSlider.Button.X;
    LSlider.SetValue(50);
    Assert.AreEqual(LExpected - 52, LSlider.Button.X);
    LSlider.SetValue(20);
    Assert.AreEqual(LExpected - 52 + 78, LSlider.Button.X);
    LSlider.SetValue(35);
    Assert.AreEqual(LExpected - 52 + 39, LSlider.Button.X);
  finally
    LSlider.Free;
  end;
end;

procedure TTestXcomOptionsMoreScreens.GeoscapeITreCursoriEIMenuCambianoLeOpzioni;
begin
  FWorld.Game.PushState(TXcomOptionsGeoscapeState.Create(FWorld.Game, ooMenu, FNavigator));
  FWorld.Wait(400);
  // scroll speed (94,18) from 100 to 10; clock speed (94,50) from 250 to 10; right ends
  ClickAt(94 + 102, 26);
  Assert.AreEqual(10, FWorld.Game.Options.GetValue('geoScrollSpeed'));
  ClickAt(94 + 102, 58);
  Assert.AreEqual(10, FWorld.Game.Options.GetValue('geoClockSpeed'));
  // the radars and the flight paths of the globe (94,110 and 94,128)
  ClickAt(150, 118);
  Assert.IsFalse(FWorld.Game.Options.GetBool('globeRadarLines'));
  ClickAt(150, 136);
  Assert.IsFalse(FWorld.Game.Options.GetBool('globeFlightPaths'));
end;

procedure TTestXcomOptionsMoreScreens.BattlescapeICursoriEIPulsantiCambianoLeOpzioni;
begin
  FWorld.Game.PushState(TXcomOptionsBattlescapeState.Create(FWorld.Game, ooMenu, FNavigator));
  FWorld.Wait(400);
  // scroll (94,50) 2..20, fire (206,50) 1..20, player (94,82) 40..1, computer (206,82) 40..1
  ClickAt(94 + 102, 58);
  Assert.AreEqual(20, FWorld.Game.Options.GetValue('battleScrollSpeed'));
  ClickAt(206 + 102, 58);
  Assert.AreEqual(20, FWorld.Game.Options.GetValue('battleFireSpeed'));
  ClickAt(94 + 102, 90);
  Assert.AreEqual(1, FWorld.Game.Options.GetValue('battleXcomSpeed'));
  ClickAt(206 + 102, 90);
  Assert.AreEqual(1, FWorld.Game.Options.GetValue('battleAlienSpeed'));
  // tooltips (206,110) start on, the death notifications (206,128) start off
  ClickAt(250, 118);
  Assert.IsFalse(FWorld.Game.Options.GetBool('battleTooltips'));
  ClickAt(250, 136);
  Assert.IsTrue(FWorld.Game.Options.GetBool('battleNotifyDeath'));
end;

procedure TTestXcomOptionsMoreScreens.IlNavigatoreDelMenuRiportaAlMenuPrincipale;
var
  LNavigator: IXcomOptionsNavigator;
begin
  LNavigator := TXcomMenuOptionsNavigator.Create('v');
  LNavigator.Restart(ooMenu, FWorld.Game);
  FWorld.Wait(400);
  Assert.IsTrue(FWorld.Game.TopState is TXcomMainMenuState);
  // a single state is never taken away: the options of a geoscape or a battle go back to the state below them
  LNavigator.Restart(ooGeoscape, FWorld.Game);
  FWorld.Wait(100);
  Assert.IsTrue(FWorld.Game.TopState is TXcomMainMenuState);
end;

procedure TTestXcomOptionsMoreScreens.LeOpzioniDiUnaBattagliaDovrebberoTornareAlloStatoCheLeHaAperte;
var
  LNavigator: IXcomOptionsNavigator;
  LOrigin: TXcomState;
begin
  // Origin (the geoscape or the battle), Pause, Options: OK of the options takes the last two away
  LOrigin := TXcomMainMenuState.Create(FWorld.Game, 'v');
  FWorld.Game.SetState(LOrigin);
  FWorld.Game.PushState(TXcomMainMenuState.Create(FWorld.Game, 'v'));
  FWorld.Game.PushState(TXcomMainMenuState.Create(FWorld.Game, 'v'));
  FWorld.Wait(100);
  Assert.AreEqual(3, FWorld.Game.StateCount);
  LNavigator := TXcomMenuOptionsNavigator.Create('v');
  LNavigator.Restart(ooBattlescape, FWorld.Game);
  FWorld.Wait(100);
  Assert.AreEqual(1, FWorld.Game.StateCount);
  Assert.IsTrue(FWorld.Game.IsState(LOrigin));
end;

procedure TTestXcomOptionsMoreScreens.LaPosizioneDellaFinestraSiImpostaConOk;
begin
  FWorld.Game.Options.NewWindowedModePositionX := 7;
  FWorld.Game.PushState(TXcomSetWindowedRootState.Create(FWorld.Game, ooMenu, nil));
  FWorld.Wait(400);
  PressKey(FWorld.Game.Options.KeyOk);
  FWorld.Wait(50);
  Assert.IsTrue(FWorld.Game.Options.NewRootWindowedMode);
  Assert.AreEqual(7, FWorld.Game.Options.NewWindowedModePositionX);
end;

procedure TTestXcomOptionsMoreScreens.LaPosizioneDellaFinestraAnnullaChiamaIlGestore;
var
  LCalled: Boolean;
begin
  LCalled := False;
  FWorld.Game.PushState(TXcomSetWindowedRootState.Create(FWorld.Game, ooMenu,
    procedure
    begin
      LCalled := True;
    end));
  FWorld.Wait(400);
  PressKey(FWorld.Game.Options.KeyCancel);
  FWorld.Wait(50);
  Assert.IsTrue(LCalled);
  Assert.IsFalse(FWorld.Game.TopState is TXcomSetWindowedRootState);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomOptionTable);
  TDUnitX.RegisterTestFixture(TTestXcomOptionsGeneric);
  TDUnitX.RegisterTestFixture(TTestXcomOptionsFile);
  TDUnitX.RegisterTestFixture(TTestXcomKeyNames);
  TDUnitX.RegisterTestFixture(TTestXcomSoundConverter);
  TDUnitX.RegisterTestFixture(TTestXcomOptionsMoreScreens);

end.