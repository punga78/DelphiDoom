{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom engine - actions, texts, languages,       }
{  options, interface rules, virtual files                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.Core;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.LocalizedText,
  DelphiDoom.XcomEngine.LanguagePlurality, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomEngine.FileMap, DelphiDoom.XcomEngine.YamlFields,
  DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.DiskFileSystem, DelphiDoom.XcomEngine.QueueEventSource,
  DelphiDoom.XcomEngine.MemoryVideoDevice, DelphiDoom.XcomEngine.ManualClock;

type
  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomAction = class
  public
    [Test]
    procedure IlMouseSenzaAzioneDaMenoUno;
    [Test]
    procedure LePosizioniTolgonoLeFasceNere;
    [Test]
    procedure LePosizioniAssolutePassanoDallaScala;
    [Test]
    procedure LaPosizioneRelativaTogliePosizioneDellaSuperficie;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomLocalizedText = class
  public
    [Test]
    procedure SostituisceIlMarcatoreDelloArgomento;
    [Test]
    procedure GliArgomentiAvanzanoUnoDopoLAltro;
    [Test]
    procedure SenzaMarcatoreIlTestoNonCambia;
    [Test]
    procedure SiConvertePerStringa;
    [Test]
    procedure SostituisceTutteLeOccorrenze;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomLanguagePlurality = class
  public
    [TestCase('inglese uno', 'en-US,1,_one')]
    [TestCase('inglese due', 'en-US,2,_other')]
    [TestCase('inglese zero', 'en-US,0,_other')]
    [TestCase('francese zero', 'fr,0,_one')]
    [TestCase('francese due', 'fr,2,_other')]
    [TestCase('ungherese uno', 'hu,1,_other')]
    [TestCase('ceco tre', 'cs,3,_few')]
    [TestCase('ceco cinque', 'cs,5,_other')]
    [TestCase('polacco ventidue', 'pl,22,_few')]
    [TestCase('polacco cinque', 'pl,5,_many')]
    [TestCase('polacco venticinque', 'pl,25,_many')]
    [TestCase('rumeno zero', 'ro,0,_few')]
    [TestCase('rumeno venti', 'ro,20,_other')]
    [TestCase('russo ventuno', 'ru,21,_one')]
    [TestCase('russo undici', 'ru,11,_many')]
    [TestCase('russo ventitre', 'ru,23,_few')]
    [TestCase('croato ventuno', 'hr,21,_one')]
    [TestCase('croato tre', 'hr,3,_few')]
    [TestCase('croato cinque', 'hr,5,_other')]
    procedure DaIlSuffissoDellaLingua(const ALanguage: string; ANumber: Integer; const AExpected: string);
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomLanguage = class
  strict private
    FFiles: IXcomFileSystem;
    FParser: IYamlParser;
    function NewLanguage(const AId: string; AWrap: TXcomTextWrapping = twAuto): TXcomLanguage;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure CaricaLeStringheDiUnFile;
    [Test]
    procedure UnaMappaDiStringheDiventaUnaChiaveConSuffisso;
    [Test]
    procedure UnFileMancanteSiIgnora;
    [Test]
    procedure UnFileDopoLAltroSovrascrive;
    [Test]
    procedure IMarcatoriSpecialiDiventanoCaratteriDiControllo;
    [Test]
    procedure UnaChiaveMancanteDaLaChiaveStessa;
    [Test]
    procedure ScegliePluraleESostituisceIlNumero;
    [Test]
    procedure ConZeroUsaLaChiaveZero;
    [Test]
    procedure ConLaChiaveVuotaDaVuoto;
    [Test]
    procedure LeStringheExtraSostituisconoQuelleDelFile;
    [Test]
    procedure IlGiapponeVaACapoPerLettere;
    [Test]
    procedure InglesePerParoleEWrapEsplicito;
    [Test]
    procedure UnYamlSbagliatoDaUnErroreConIlNomeDelFile;
    [Test]
    procedure ConteELingua;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomOptions = class
  public
    [Test]
    procedure IPredefinitiSonoQuelliDiOpenXcom;
    [Test]
    procedure CaricaLeOpzioniDallaMappaOptions;
    [Test]
    procedure UnaChiaveMancanteOSbagliataTieneIlValore;
    [Test]
    procedure UnDocumentoSenzaOptionsNonCambiaNulla;
    [Test]
    procedure SalvaLeOpzioniPrincipali;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomRuleInterface = class
  strict private
    function Load(const AText: string): TXcomRuleInterface;
  public
    [Test]
    procedure LeggePaletteGenitoreEMusica;
    [Test]
    procedure LeggeGliElementiConPosizioneEDimensione;
    [Test]
    procedure UnElementoSenzaCampiLiLasciaNonDefiniti;
    [Test]
    procedure UnElementoMancanteDaFalso;
    [Test]
    procedure UnElementoRimpiazzaQuelloDelloStessoNome;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomFileMap = class
  public
    [Test]
    procedure LUltimaRadiceVinceSuLePrecedenti;
    [Test]
    procedure TrovaIlFileSoloInUnaRadice;
    [Test]
    procedure UnFileMancanteSollevaUnErrore;
    [Test]
    procedure LeCartelleVirtualiSonoLeCartelleChiEsistono;
    [Test]
    procedure LeggeIlContenuto;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomDiskFileSystem = class
  public
    [Test]
    procedure ScriveELeggeUnFile;
    [Test]
    procedure ElencaIFileDiUnaCartellaPerEstensione;
    [Test]
    procedure UnFileMancanteSollevaUnErrore;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomDevices = class
  public
    [Test]
    procedure LaCodaDaGliEventiNelLoroOrdineETieneIlMouse;
    [Test]
    procedure IlPulsanteSiAccendeESiSpegne;
    [Test]
    procedure LOrologioManualeAvanzaSoloSeGliSiDice;
    [Test]
    procedure IlVideoInMemoriaTieneLUltimaImmagine;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.XcomEngine.World;

{ TTestXcomAction }

procedure TTestXcomAction.IlMouseSenzaAzioneDaMenoUno;
var
  LAction: TXcomAction;
begin
  LAction := TXcomAction.Create(TXcomInputEvent.Make(ekKeyDown), 2.0, 2.0, 0, 0);
  try
    Assert.IsFalse(LAction.IsMouseAction);
    Assert.AreEqual(-1.0, LAction.AbsoluteXMouse, 0.0001);
    Assert.AreEqual(-1.0, LAction.AbsoluteYMouse, 0.0001);
    Assert.AreEqual(-1.0, LAction.RelativeXMouse, 0.0001);
    Assert.AreEqual(-1.0, LAction.RelativeYMouse, 0.0001);
  finally
    LAction.Free;
  end;
end;

procedure TTestXcomAction.LePosizioniTolgonoLeFasceNere;
var
  LAction: TXcomAction;
begin
  LAction := TXcomAction.Create(TXcomInputEvent.Make(ekMouseMotion), 2.0, 2.0, 10, 20);
  try
    LAction.SetMouseAction(100, 60, 0, 0);
    Assert.IsTrue(LAction.IsMouseAction);
    Assert.AreEqual(80, LAction.XMouse);
    Assert.AreEqual(50, LAction.YMouse);
    Assert.AreEqual(10, LAction.TopBlackBand);
    Assert.AreEqual(20, LAction.LeftBlackBand);
  finally
    LAction.Free;
  end;
end;

procedure TTestXcomAction.LePosizioniAssolutePassanoDallaScala;
var
  LAction: TXcomAction;
begin
  LAction := TXcomAction.Create(TXcomInputEvent.Make(ekMouseMotion), 2.0, 4.0, 0, 0);
  try
    LAction.SetMouseAction(100, 100, 0, 0);
    Assert.AreEqual(50.0, LAction.AbsoluteXMouse, 0.0001);
    Assert.AreEqual(25.0, LAction.AbsoluteYMouse, 0.0001);
    Assert.AreEqual(2.0, LAction.XScale, 0.0001);
    Assert.AreEqual(4.0, LAction.YScale, 0.0001);
  finally
    LAction.Free;
  end;
end;

procedure TTestXcomAction.LaPosizioneRelativaTogliePosizioneDellaSuperficie;
var
  LAction: TXcomAction;
begin
  LAction := TXcomAction.Create(TXcomInputEvent.Make(ekMouseMotion), 2.0, 2.0, 0, 0);
  try
    LAction.SetMouseAction(100, 60, 10, 5);
    Assert.AreEqual(80.0, LAction.RelativeXMouse, 0.0001);
    Assert.AreEqual(50.0, LAction.RelativeYMouse, 0.0001);
    Assert.IsNull(LAction.Sender);
    LAction.Sender := LAction;
    Assert.IsNotNull(LAction.Sender);
  finally
    LAction.Free;
  end;
end;

{ TTestXcomLocalizedText }

procedure TTestXcomLocalizedText.SostituisceIlMarcatoreDelloArgomento;
var
  LText: TXcomLocalizedText;
begin
  LText := TXcomLocalizedText.Create('Hello {0}');
  Assert.AreEqual('Hello world', LText.Arg('world').Text);
end;

procedure TTestXcomLocalizedText.GliArgomentiAvanzanoUnoDopoLAltro;
var
  LText: TXcomLocalizedText;
begin
  LText := TXcomLocalizedText.Create('{0} and {1}');
  Assert.AreEqual('a and b', LText.Arg('a').Arg('b').Text);
  Assert.AreEqual('3 and 4', LText.Arg(3).Arg(4).Text);
end;

procedure TTestXcomLocalizedText.SenzaMarcatoreIlTestoNonCambia;
var
  LText: TXcomLocalizedText;
begin
  LText := TXcomLocalizedText.Create('plain');
  Assert.AreEqual('plain', LText.Arg('x').Text);
end;

procedure TTestXcomLocalizedText.SiConvertePerStringa;
var
  LText: TXcomLocalizedText;
  LString: string;
begin
  LText := 'abc';
  LString := LText;
  Assert.AreEqual('abc', LString);
end;

procedure TTestXcomLocalizedText.SostituisceTutteLeOccorrenze;
var
  LText: TXcomLocalizedText;
begin
  LText := TXcomLocalizedText.Create('{0}-{0}');
  Assert.AreEqual('x-x', LText.Arg('x').Text);
end;

{ TTestXcomLanguagePlurality }

procedure TTestXcomLanguagePlurality.DaIlSuffissoDellaLingua(const ALanguage: string; ANumber: Integer;
  const AExpected: string);
var
  LPlurality: TXcomLanguagePlurality;
begin
  LPlurality := TXcomLanguagePlurality.ForLanguage(ALanguage);
  try
    Assert.AreEqual(AExpected, LPlurality.Suffix(Cardinal(ANumber)));
  finally
    LPlurality.Free;
  end;
end;

{ TTestXcomLanguage }

procedure TTestXcomLanguage.Setup;
begin
  FFiles := TFakeFileSystem.Create;
  FParser := TYamlFactory.CreateParser;
end;

function TTestXcomLanguage.NewLanguage(const AId: string; AWrap: TXcomTextWrapping): TXcomLanguage;
begin
  Result := TXcomLanguage.Create(AId, AWrap, FFiles, FParser);
end;

procedure TTestXcomLanguage.CaricaLeStringheDiUnFile;
var
  LLanguage: TXcomLanguage;
begin
  TFakeFileSystem(FFiles).Put('a.yml', 'en-US:'#10'  STR_A: "Alpha"'#10'  STR_B: "Beta"'#10);
  LLanguage := NewLanguage('en-US');
  try
    LLanguage.LoadFile('a.yml');
    Assert.AreEqual('Alpha', LLanguage.GetString('STR_A').Text);
    Assert.AreEqual('Beta', LLanguage.GetString('STR_B').Text);
    Assert.AreEqual(2, LLanguage.Count);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.UnaMappaDiStringheDiventaUnaChiaveConSuffisso;
var
  LLanguage: TXcomLanguage;
begin
  TFakeFileSystem(FFiles).Put('a.yml', 'en-US:'#10'  STR_X:'#10'    one: "one thing"'#10'    other: "{N} things"'#10);
  LLanguage := NewLanguage('en-US');
  try
    LLanguage.LoadFile('a.yml');
    Assert.AreEqual('one thing', LLanguage.GetString('STR_X', 1).Text);
    Assert.AreEqual('5 things', LLanguage.GetString('STR_X', 5).Text);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.UnFileMancanteSiIgnora;
var
  LLanguage: TXcomLanguage;
begin
  LLanguage := NewLanguage('en-US');
  try
    LLanguage.LoadFile('missing.yml');
    Assert.AreEqual(0, LLanguage.Count);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.UnFileDopoLAltroSovrascrive;
var
  LLanguage: TXcomLanguage;
begin
  TFakeFileSystem(FFiles).Put('a.yml', 'en-US:'#10'  STR_A: "one"'#10'  STR_C: "kept"'#10);
  TFakeFileSystem(FFiles).Put('b.yml', 'it:'#10'  STR_A: "uno"'#10);
  LLanguage := NewLanguage('it');
  try
    LLanguage.LoadFile('a.yml');
    LLanguage.LoadFile('b.yml');
    Assert.AreEqual('uno', LLanguage.GetString('STR_A').Text);
    Assert.AreEqual('kept', LLanguage.GetString('STR_C').Text);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.IMarcatoriSpecialiDiventanoCaratteriDiControllo;
var
  LLanguage: TXcomLanguage;
begin
  TFakeFileSystem(FFiles).Put('a.yml',
    'en-US:'#10'  STR_A: "x{NEWLINE}y{SMALLLINE}z{ALT}w"'#10);
  LLanguage := NewLanguage('en-US');
  try
    LLanguage.LoadFile('a.yml');
    Assert.AreEqual('x'#10'y'#2'z'#1'w', LLanguage.GetString('STR_A').Text);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.UnaChiaveMancanteDaLaChiaveStessa;
var
  LLanguage: TXcomLanguage;
begin
  LLanguage := NewLanguage('en-US');
  try
    Assert.AreEqual('STR_NOPE', LLanguage.GetString('STR_NOPE').Text);
    Assert.AreEqual('STR_NOPE', LLanguage.GetString('STR_NOPE', 3).Text);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.ScegliePluraleESostituisceIlNumero;
var
  LLanguage: TXcomLanguage;
begin
  TFakeFileSystem(FFiles).Put('a.yml', 'ru:'#10'  STR_X:'#10'    one: "{N} a"'#10'    few: "{N} b"'#10'    many: "{N} c"'#10'    other: "{N} d"'#10);
  LLanguage := NewLanguage('ru');
  try
    LLanguage.LoadFile('a.yml');
    Assert.AreEqual('21 a', LLanguage.GetString('STR_X', 21).Text);
    Assert.AreEqual('3 b', LLanguage.GetString('STR_X', 3).Text);
    Assert.AreEqual('7 c', LLanguage.GetString('STR_X', 7).Text);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.ConZeroUsaLaChiaveZero;
var
  LLanguage: TXcomLanguage;
begin
  TFakeFileSystem(FFiles).Put('a.yml', 'en-US:'#10'  STR_X:'#10'    zero: "none"'#10'    one: "one"'#10'    other: "many"'#10);
  LLanguage := NewLanguage('en-US');
  try
    LLanguage.LoadFile('a.yml');
    Assert.AreEqual('none', LLanguage.GetString('STR_X', 0).Text);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.ConLaChiaveVuotaDaVuoto;
var
  LLanguage: TXcomLanguage;
begin
  LLanguage := NewLanguage('en-US');
  try
    Assert.AreEqual('', LLanguage.GetString('').Text);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.LeStringheExtraSostituisconoQuelleDelFile;
var
  LLanguage: TXcomLanguage;
  LStrings: TDictionary<string, string>;
begin
  TFakeFileSystem(FFiles).Put('a.yml', 'en-US:'#10'  STR_A: "file"'#10);
  LLanguage := NewLanguage('en-US');
  LStrings := TDictionary<string, string>.Create;
  try
    LStrings.Add('STR_A', 'extra{NEWLINE}');
    LLanguage.LoadFile('a.yml');
    LLanguage.AddStrings(LStrings);
    Assert.AreEqual('extra'#10, LLanguage.GetString('STR_A').Text);
  finally
    LStrings.Free;
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.IlGiapponeVaACapoPerLettere;
var
  LLanguage: TXcomLanguage;
begin
  LLanguage := NewLanguage('ja');
  try
    Assert.IsTrue(LLanguage.TextWrapping = twLetters);
    Assert.IsTrue(LLanguage.TextDirection = tdLeftToRight);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.InglesePerParoleEWrapEsplicito;
var
  LLanguage: TXcomLanguage;
begin
  LLanguage := NewLanguage('en-US');
  try
    Assert.IsTrue(LLanguage.TextWrapping = twWords);
  finally
    LLanguage.Free;
  end;
  LLanguage := NewLanguage('en-US', twLetters);
  try
    Assert.IsTrue(LLanguage.TextWrapping = twLetters);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.UnYamlSbagliatoDaUnErroreConIlNomeDelFile;
var
  LLanguage: TXcomLanguage;
begin
  TFakeFileSystem(FFiles).Put('bad.yml', 'a: [1, 2'#10'b: {');
  LLanguage := NewLanguage('en-US');
  try
    Assert.WillRaise(
      procedure
      begin
        LLanguage.LoadFile('bad.yml');
      end, EXcomEngineException);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguage.ConteELingua;
var
  LLanguage: TXcomLanguage;
begin
  LLanguage := NewLanguage('it');
  try
    Assert.AreEqual('it', LLanguage.LanguageId);
    Assert.AreEqual('Italiano', TXcomLanguage.NameOf('it'));
    Assert.AreEqual('xx', TXcomLanguage.NameOf('xx'));
  finally
    LLanguage.Free;
  end;
end;

{ TTestXcomOptions }

procedure TTestXcomOptions.IPredefinitiSonoQuelliDiOpenXcom;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    Assert.AreEqual(640, LOptions.DisplayWidth);
    Assert.AreEqual(400, LOptions.DisplayHeight);
    Assert.AreEqual(60, LOptions.FPS);
    Assert.AreEqual(XCOM_KEY_RETURN, LOptions.KeyOk);
    Assert.AreEqual(XCOM_KEY_ESCAPE, LOptions.KeyCancel);
    Assert.AreEqual(XCOM_KEY_F12, LOptions.KeyScreenshot);
    Assert.IsTrue(LOptions.KeepAspectRatio);
    Assert.IsFalse(LOptions.Fullscreen);
    Assert.AreEqual('', LOptions.Language);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptions.CaricaLeOpzioniDallaMappaOptions;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.Load(TYamlFactory.CreateParser.Load(
      'options:'#10'  displayWidth: 1280'#10'  displayHeight: 800'#10'  fullscreen: true'#10 +
      '  language: it'#10'  wordwrap: 2'#10'  fpsCounter: true'#10'  geoscapeScale: 3'#10'  keyOk: 99'#10));
    Assert.AreEqual(1280, LOptions.DisplayWidth);
    Assert.AreEqual(800, LOptions.DisplayHeight);
    Assert.IsTrue(LOptions.Fullscreen);
    Assert.AreEqual('it', LOptions.Language);
    Assert.IsTrue(LOptions.Wordwrap = twLetters);
    Assert.IsTrue(LOptions.FpsCounter);
    Assert.AreEqual(3, LOptions.GeoscapeScale);
    Assert.AreEqual(99, LOptions.KeyOk);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptions.UnaChiaveMancanteOSbagliataTieneIlValore;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.Load(TYamlFactory.CreateParser.Load('options:'#10'  displayWidth: abc'#10'  fullscreen: [1]'#10));
    Assert.AreEqual(640, LOptions.DisplayWidth);
    Assert.IsFalse(LOptions.Fullscreen);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptions.UnDocumentoSenzaOptionsNonCambiaNulla;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.Load(TYamlFactory.CreateParser.Load('mods:'#10'  - id: x'#10));
    Assert.AreEqual(640, LOptions.DisplayWidth);
    LOptions.Load(TYamlFactory.CreateParser.Load('plain scalar'));
    Assert.AreEqual(640, LOptions.DisplayWidth);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptions.SalvaLeOpzioniPrincipali;
var
  LOptions: TXcomOptions;
  LCopy: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  LCopy := TXcomOptions.Create;
  try
    LOptions.DisplayWidth := 800;
    LOptions.Language := 'de';
    LCopy.Load(TYamlFactory.CreateParser.Load(LOptions.Save));
    Assert.AreEqual(800, LCopy.DisplayWidth);
    Assert.AreEqual('de', LCopy.Language);
  finally
    LCopy.Free;
    LOptions.Free;
  end;
end;

{ TTestXcomRuleInterface }

function TTestXcomRuleInterface.Load(const AText: string): TXcomRuleInterface;
begin
  Result := TXcomRuleInterface.Create('x');
  Result.Load(TYamlFactory.CreateParser.Load(AText));
end;

procedure TTestXcomRuleInterface.LeggePaletteGenitoreEMusica;
var
  LRule: TXcomRuleInterface;
begin
  LRule := Load('palette: PAL_X'#10'parent: base'#10'music: SONG'#10);
  try
    Assert.AreEqual('PAL_X', LRule.Palette);
    Assert.AreEqual('base', LRule.Parent);
    Assert.AreEqual('SONG', LRule.Music);
    Assert.AreEqual('x', LRule.InterfaceType);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomRuleInterface.LeggeGliElementiConPosizioneEDimensione;
var
  LRule: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
begin
  LRule := Load('elements:'#10'  - id: window'#10'    size: [10, 20]'#10'    pos: [3, 4]'#10'    color: 5'#10 +
    '    color2: 6'#10'    border: 7'#10'    TFTDMode: true'#10);
  try
    Assert.IsTrue(LRule.TryGetElement('window', LElement));
    Assert.AreEqual(10, LElement.W);
    Assert.AreEqual(20, LElement.H);
    Assert.AreEqual(3, LElement.X);
    Assert.AreEqual(4, LElement.Y);
    Assert.AreEqual(5, LElement.Color);
    Assert.AreEqual(6, LElement.Color2);
    Assert.AreEqual(7, LElement.Border);
    Assert.IsTrue(LElement.TftdMode);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomRuleInterface.UnElementoSenzaCampiLiLasciaNonDefiniti;
var
  LRule: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
begin
  LRule := Load('elements:'#10'  - id: text'#10);
  try
    Assert.IsTrue(LRule.TryGetElement('text', LElement));
    Assert.AreEqual(XCOM_UNSET, LElement.W);
    Assert.AreEqual(XCOM_UNSET, LElement.X);
    Assert.AreEqual(XCOM_UNSET, LElement.Color);
    Assert.AreEqual(XCOM_UNSET, LElement.Color2);
    Assert.AreEqual(XCOM_UNSET, LElement.Border);
    Assert.IsFalse(LElement.TftdMode);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomRuleInterface.UnElementoMancanteDaFalso;
var
  LRule: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
begin
  LRule := Load('elements: []'#10);
  try
    Assert.IsFalse(LRule.TryGetElement('nope', LElement));
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomRuleInterface.UnElementoRimpiazzaQuelloDelloStessoNome;
var
  LRule: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
begin
  LRule := Load('elements:'#10'  - id: a'#10'    color: 1'#10);
  try
    LRule.Load(TYamlFactory.CreateParser.Load('elements:'#10'  - id: a'#10'    border: 9'#10));
    Assert.IsTrue(LRule.TryGetElement('a', LElement));
    Assert.AreEqual(XCOM_UNSET, LElement.Color);
    Assert.AreEqual(9, LElement.Border);
  finally
    LRule.Free;
  end;
end;

{ TTestXcomFileMap }

procedure TTestXcomFileMap.LUltimaRadiceVinceSuLePrecedenti;
var
  LFiles: TFakeFileSystem;
  LMap: TXcomFileMap;
begin
  LFiles := TFakeFileSystem.Create;
  LMap := TXcomFileMap.Create(LFiles);
  try
    LFiles.Put('c:\one\a.txt', 'one');
    LFiles.Put('c:\two\a.txt', 'two');
    LMap.AddRoot('c:\one');
    LMap.AddRoot('c:\two');
    Assert.AreEqual('two', TEncoding.UTF8.GetString(LMap.ReadAll('a.txt')));
    Assert.AreEqual('c:\two\a.txt', LMap.FilePath('A.TXT'));
  finally
    LMap.Free;
  end;
end;

procedure TTestXcomFileMap.TrovaIlFileSoloInUnaRadice;
var
  LFiles: TFakeFileSystem;
  LMap: TXcomFileMap;
begin
  LFiles := TFakeFileSystem.Create;
  LMap := TXcomFileMap.Create(LFiles);
  try
    LFiles.Put('c:\one\only.txt', 'x');
    LMap.AddRoot('c:\one');
    LMap.AddRoot('c:\two');
    Assert.IsTrue(LMap.Exists('only.txt'));
    Assert.IsFalse(LMap.Exists('none.txt'));
    Assert.IsTrue(LMap.Exists('sub/only.txt') = False);
  finally
    LMap.Free;
  end;
end;

procedure TTestXcomFileMap.UnFileMancanteSollevaUnErrore;
var
  LMap: TXcomFileMap;
begin
  LMap := TXcomFileMap.Create(TFakeFileSystem.Create);
  try
    Assert.WillRaise(
      procedure
      begin
        LMap.FilePath('x.txt');
      end, EXcomEngineException);
  finally
    LMap.Free;
  end;
end;

procedure TTestXcomFileMap.LeCartelleVirtualiSonoLeCartelleChiEsistono;
var
  LFiles: TFakeFileSystem;
  LMap: TXcomFileMap;
  LFolders: TArray<string>;
begin
  LFiles := TFakeFileSystem.Create;
  LMap := TXcomFileMap.Create(LFiles);
  try
    LFiles.Put('c:\one\SOUND\a.cat', 'x');
    LFiles.Put('c:\three\SOUND\b.cat', 'x');
    LMap.AddRoot('c:\one');
    LMap.AddRoot('c:\two');
    LMap.AddRoot('c:\three');
    LFolders := LMap.Folders('SOUND');
    Assert.AreEqual(2, Length(LFolders));
    Assert.AreEqual('c:\one\SOUND', LFolders[0]);
  finally
    LMap.Free;
  end;
end;

procedure TTestXcomFileMap.LeggeIlContenuto;
var
  LFiles: TFakeFileSystem;
  LMap: TXcomFileMap;
begin
  LFiles := TFakeFileSystem.Create;
  LMap := TXcomFileMap.Create(LFiles);
  try
    LFiles.Put('c:\one\Language\a.yml', 'abc');
    LMap.AddRoot('c:\one');
    Assert.AreEqual(3, Length(LMap.ReadAll('Language/a.yml')));
  finally
    LMap.Free;
  end;
end;

{ TTestXcomDiskFileSystem }

procedure TTestXcomDiskFileSystem.ScriveELeggeUnFile;
var
  LFiles: IXcomFileSystem;
  LPath: string;
begin
  LFiles := TXcomDiskFileSystem.Create;
  LPath := TPath.Combine(TPath.GetTempPath, 'xcom_engine_test\sub\a.bin');
  try
    LFiles.WriteAll(LPath, [1, 2, 3]);
    Assert.IsTrue(LFiles.FileExists(LPath));
    Assert.IsTrue(LFiles.FolderExists(ExtractFilePath(LPath)));
    Assert.AreEqual(3, Length(LFiles.ReadAll(LPath)));
  finally
    TDirectory.Delete(TPath.Combine(TPath.GetTempPath, 'xcom_engine_test'), True);
  end;
end;

procedure TTestXcomDiskFileSystem.ElencaIFileDiUnaCartellaPerEstensione;
var
  LFiles: IXcomFileSystem;
  LFolder: string;
  LNames: TArray<string>;
begin
  LFiles := TXcomDiskFileSystem.Create;
  LFolder := TPath.Combine(TPath.GetTempPath, 'xcom_engine_test2');
  try
    LFiles.WriteAll(TPath.Combine(LFolder, 'b.yml'), [1]);
    LFiles.WriteAll(TPath.Combine(LFolder, 'a.YML'), [1]);
    LFiles.WriteAll(TPath.Combine(LFolder, 'c.txt'), [1]);
    LNames := LFiles.FolderContents(LFolder, 'yml');
    Assert.AreEqual(2, Length(LNames));
    Assert.AreEqual('a', LNames[0]);
    Assert.AreEqual('b', LNames[1]);
    Assert.AreEqual(0, Length(LFiles.FolderContents(TPath.Combine(LFolder, 'none'), 'yml')));
  finally
    TDirectory.Delete(LFolder, True);
  end;
end;

procedure TTestXcomDiskFileSystem.UnFileMancanteSollevaUnErrore;
var
  LFiles: IXcomFileSystem;
begin
  LFiles := TXcomDiskFileSystem.Create;
  Assert.WillRaise(
    procedure
    begin
      LFiles.ReadAll('Z:\none\none.bin');
    end, EXcomEngineException);
end;

{ TTestXcomDevices }

procedure TTestXcomDevices.LaCodaDaGliEventiNelLoroOrdineETieneIlMouse;
var
  LSource: TXcomQueueEventSource;
  LRef: IXcomEventSource;
  LEvent: TXcomInputEvent;
  LX: Integer;
  LY: Integer;
begin
  LSource := TXcomQueueEventSource.Create;
  LRef := LSource;
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := 7;
  LEvent.Y := 9;
  LSource.Enqueue(LEvent);
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := 65;
  LSource.Enqueue(LEvent);
  Assert.AreEqual(2, LSource.Pending);
  Assert.IsTrue(LRef.Poll(LEvent));
  Assert.IsTrue(LEvent.Kind = ekMouseMotion);
  Assert.AreEqual(0, LRef.MouseState(LX, LY));
  Assert.AreEqual(7, LX);
  Assert.AreEqual(9, LY);
  Assert.IsTrue(LRef.Poll(LEvent));
  Assert.AreEqual(65, LEvent.Key);
  Assert.IsFalse(LRef.Poll(LEvent));
end;

procedure TTestXcomDevices.IlPulsanteSiAccendeESiSpegne;
var
  LSource: TXcomQueueEventSource;
  LRef: IXcomEventSource;
  LEvent: TXcomInputEvent;
  LX: Integer;
  LY: Integer;
begin
  LSource := TXcomQueueEventSource.Create;
  LRef := LSource;
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.Button := XCOM_BUTTON_RIGHT;
  LSource.Enqueue(LEvent);
  LRef.Poll(LEvent);
  Assert.AreEqual(4, LRef.MouseState(LX, LY));
  LEvent.Kind := ekMouseUp;
  LSource.Enqueue(LEvent);
  LRef.Poll(LEvent);
  Assert.AreEqual(0, LRef.MouseState(LX, LY));
  LSource.SetModifiers(XCOM_KMOD_SHIFT);
  Assert.AreEqual(XCOM_KMOD_SHIFT, LRef.ModifierState);
end;

procedure TTestXcomDevices.LOrologioManualeAvanzaSoloSeGliSiDice;
var
  LClock: TXcomManualClock;
  LRef: IXcomClock;
begin
  LClock := TXcomManualClock.Create(100);
  LRef := LClock;
  Assert.AreEqual(Cardinal(100), LRef.Ticks);
  LRef.Delay(5);
  LClock.Advance(10);
  Assert.AreEqual(Cardinal(115), LRef.Ticks);
end;

procedure TTestXcomDevices.IlVideoInMemoriaTieneLUltimaImmagine;
var
  LDevice: TXcomMemoryVideoDevice;
  LRef: IXcomVideoDevice;
  LWidth: Integer;
  LHeight: Integer;
  LColors: TXcomColors;
begin
  LDevice := TXcomMemoryVideoDevice.Create;
  LRef := LDevice;
  LWidth := 4;
  LHeight := 2;
  LRef.SetMode(LWidth, LHeight, False);
  LRef.SetTitle('t');
  FillChar(LColors, SizeOf(LColors), 0);
  LColors[1].Red := 9;
  LRef.Present([0, 1, 1, 0, 1, 1, 0, 0], 4, 2, LColors);
  Assert.AreEqual(1, LDevice.Presented);
  Assert.AreEqual(8, Length(LDevice.Pixels));
  Assert.AreEqual(9, Integer(LDevice.Palette[1].Red));
  Assert.AreEqual('t', LDevice.Title);
  Assert.AreEqual(4, LDevice.Width);
  Assert.AreEqual(2, LDevice.Height);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomAction);
  TDUnitX.RegisterTestFixture(TTestXcomLocalizedText);
  TDUnitX.RegisterTestFixture(TTestXcomLanguagePlurality);
  TDUnitX.RegisterTestFixture(TTestXcomLanguage);
  TDUnitX.RegisterTestFixture(TTestXcomOptions);
  TDUnitX.RegisterTestFixture(TTestXcomRuleInterface);
  TDUnitX.RegisterTestFixture(TTestXcomFileMap);
  TDUnitX.RegisterTestFixture(TTestXcomDiskFileSystem);
  TDUnitX.RegisterTestFixture(TTestXcomDevices);

end.
