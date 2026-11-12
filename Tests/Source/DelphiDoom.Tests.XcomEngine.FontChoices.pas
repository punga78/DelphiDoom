{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the choice of the fonts in the advanced options    }
{  (TXcomFontChoices, TXcomFontSettingsWriter, TXcomExtraOptionSet,             }
{  TXcomFontReloader and the notices of TXcomRasterFontOverlay), issue 184      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.FontChoices;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.ExtraOptions.Intf, DelphiDoom.XcomEngine.ExtraChoiceOptions.Intf,
  DelphiDoom.XcomEngine.SystemFonts.Intf, DelphiDoom.XcomEngine.FontSettingsSource.Intf,
  DelphiDoom.XcomEngine.FontReloader.Intf, DelphiDoom.XcomEngine.FontReapplier.Intf,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.FontChoices, DelphiDoom.XcomEngine.FontSettingsWriter,
  DelphiDoom.XcomEngine.FontSettingsReader, DelphiDoom.XcomEngine.ExtraOptionSet,
  DelphiDoom.XcomEngine.FontReloader, DelphiDoom.XcomEngine.RasterFontOverlay,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.FontOverlay.Intf,
  DelphiDoom.XcomSurface.GlyphRasterizer.Intf, DelphiDoom.Tests.XcomEngine.World,
  DelphiDoom.Tests.XcomEngine.FontFakes, DelphiDoom.Tests.XcomSurface.FakeRasterizer;

type
  /// <summary>IXcomSystemFonts with the families it was given</summary>
  TFakeSystemFonts = class(TInterfacedObject, IXcomSystemFonts)
  strict private
    FFamilies: TArray<string>;
  public
    constructor Create(const AFamilies: TArray<string>);
    function Families: TArray<string>;
  end;

  /// <summary>Resources that can change their fonts: keeps the overlay it was given and says how often</summary>
  TReapplyingResources = class(TFakeResources, IXcomFontReapplier)
  public
    Overlay: IXcomFontOverlay;
    Calls: Integer;
    procedure ReapplyFonts(const AOverlay: IXcomFontOverlay);
  end;

  /// <summary>IXcomFontSettingsSource of the tests</summary>
  TFakeSettingsSource = class(TInterfacedObject, IXcomFontSettingsSource)
  public
    Entries: TArray<TXcomFontOverlaySettings>;
    Commits: Integer;
    function Settings: TArray<TXcomFontOverlaySettings>;
    procedure Commit;
  end;

  /// <summary>A group of toggles, as TXcomTrueColorOption is</summary>
  TFakeToggles = class(TInterfacedObject, IXcomExtraOptions)
  strict private
    FValues: TArray<Boolean>;
  public
    constructor Create(ACount: Integer);
    function Heading: string;
    function Count: Integer;
    function Title(AIndex: Integer): string;
    function Description(AIndex: Integer): string;
    function IsOn(AIndex: Integer): Boolean;
    procedure SetOn(AIndex: Integer; AValue: Boolean);
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomFontChoices = class
  strict private
    const
      USER_FILE = 'user\fonts.cfg';
    var
      FFiles: TFakeFileSystem;
      FFilesRef: IXcomFileSystem;
      FLog: TFontTestLog;
      FLogRef: IXcomLog;
    function Choices(const AInstalled: TArray<string>; const AHand: string = ''; const ALocked: string = ''): IXcomExtraOptions;
    function Written: string;
    function Parsed(const AText: string): TArray<TXcomFontOverlaySettings>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereCinqueRigheOgniFontDelGioco;
    [Test]
    procedure DovrebbePartireDaOriginalSenzaFile;
    [Test]
    procedure LeRigheDiUnFontOriginalNonDovrebberoEssereModificabili;
    [Test]
    procedure UnClickSulFontDovrebbeScegliereIlPrimoInstallato;
    [Test]
    procedure IlFontScelto_DovrebbeAvereLaMisuraELeOpzioniPredefiniteDelSuoFont;
    [Test]
    procedure IlClickDestroDaOriginalDovrebbeScegliereLUltimo;
    [Test]
    procedure DovrebbeOffrireSoloIFontInstallati;
    [Test]
    procedure DopoLUltimoFontDovrebbeTornareOriginalERimuovereLaVoce;
    [Test]
    procedure LaMisuraDovrebbeFareIlGiroTraIlMinimoEIlMassimo;
    [Test]
    procedure DovrebbeCambiareGrassettoBordiERestringimento;
    [Test]
    procedure ConfermareDovrebbeScrivereFontsCfgCheSiRilegge;
    [Test]
    procedure ConfermareSenzaCambiamentiNonDovrebbeScrivereNulla;
    [Test]
    procedure AnnullareDovrebbeDimenticareLeModifiche;
    [Test]
    procedure DovrebbeLeggereIlFileGiaScrittoELasciareLeChiaviCheNonMostra;
    [Test]
    procedure UnFontScrittoAManoDovrebbeRestareNellElenco;
    [Test]
    procedure UnFileDovrebbeEssereSostituitoDallaFamigliaMantenendoLeAltreChiavi;
    [Test]
    procedure ConFontsDellaRigaDiComandoDovrebbeEsserciUnaRigaSolaNonModificabile;
    [Test]
    procedure ConFontsDellaRigaDiComandoLeImpostazioniSonoQuelleDelFile;
    [Test]
    procedure ConFontsDellaRigaDiComandoConfermareNonDovrebbeScrivereFontsCfg;
    [Test]
    procedure DovrebbeRifiutareFileSystemNil;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomFontSettingsWriter = class
  public
    [Test]
    procedure UnElencoVuotoDovrebbeEssereUnaSequenzaVuota;
    [Test]
    procedure DovrebbeScrivereCioCheIlLettoreRilegge;
    [Test]
    procedure DovrebbeProteggereIPercorsiELeApici;
    [Test]
    procedure NonDovrebbeScrivereLeChiaviPredefinite;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomExtraOptionSet = class
  strict private
    FToggles: IXcomExtraOptions;
    FChoices: IXcomExtraOptions;
    FFiles: TFakeFileSystem;
    FFilesRef: IXcomFileSystem;
    FSet: IXcomExtraOptions;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSommareLeRighe;
    [Test]
    procedure DovrebbeDareLIntestazioneDelPrimo;
    [Test]
    procedure LeRigheDiUnaParteSenzaScelteDovrebberoEssereInterruttori;
    [Test]
    procedure DovrebbeInoltrareIlPassoEIlTitoloAllaParteGiusta;
    [Test]
    procedure DovrebbeInoltrareGliInterruttori;
    [Test]
    procedure AnnullareDovrebbeArrivareATutteLeParti;
    [Test]
    procedure UnIndiceFuoriDallElencoDovrebbeSollevareUnEccezione;
    [Test]
    procedure DovrebbeRifiutareUnaParteNil;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomFontReloader = class
  strict private
    FSource: TFakeSettingsSource;
    FSourceRef: IXcomFontSettingsSource;
    FResources: TReapplyingResources;
    FResourcesRef: IXcomResources;
    FRasterizer: TFakeGlyphRasterizer;
    FFactory: TFakeGlyphRasterizerFactory;
    FFactoryRef: IXcomGlyphRasterizerFactory;
    FLog: TFontTestLog;
    FLogRef: IXcomLog;
    function Reloader: IXcomFontReloader;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeConfermareLaScelta;
    [Test]
    procedure DovrebbeDareLeRisorseUnOverlayPerLeVoci;
    [Test]
    procedure SenzaVociDovrebbeDareLeRisorseUnOverlayNil;
    [Test]
    procedure DovrebbeDareGliAvvisiPerIlPlayer;
    [Test]
    procedure RisorseCheNonCambianoIFontDovrebbeSoloConfermare;
    [Test]
    procedure DovrebbeRifiutareArgomentiNil;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomRasterFontNotices = class
  strict private
    FRasterizer: TFakeGlyphRasterizer;
    FFactory: TFakeGlyphRasterizerFactory;
    FFactoryRef: IXcomGlyphRasterizerFactory;
    FFont: TXcomFont;
    function Run(const ASettings: TXcomFontOverlaySettings; const AFontId: string): TArray<string>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnFontCheEntraNonDovrebbeAvereAvvisiPerIlPlayer;
    [Test]
    procedure UnFontNonInstallatoDovrebbeDirloAlPlayer;
    [Test]
    procedure UnFontTroppoGrandeDovrebbeSuggerireDiRestringere;
    [Test]
    procedure UnFontRestrettoDovrebbeDireLaNuovaMisura;
    [Test]
    procedure UnFontSenzaICaratteriDovrebbeDirloAlPlayer;
    [Test]
    procedure IlNomeDelFontDelGiocoDovrebbeEssereInParole;
  end;

implementation

function Usual: TArray<string>;
begin
  Result := ['Tahoma', 'Verdana', 'Consolas'];
end;

{ TFakeSystemFonts }

constructor TFakeSystemFonts.Create(const AFamilies: TArray<string>);
begin
  inherited Create;
  FFamilies := AFamilies;
end;

function TFakeSystemFonts.Families: TArray<string>;
begin
  Result := FFamilies;
end;

{ TReapplyingResources }

procedure TReapplyingResources.ReapplyFonts(const AOverlay: IXcomFontOverlay);
var
  LFont: TXcomFont;
begin
  Overlay := AOverlay;
  Inc(Calls);
  // as the real resources do: every font goes through the overlay
  if Assigned(AOverlay) then
  begin
    LFont := TFontFixtures.Font('AB?');
    try
      AOverlay.Apply('FONT_BIG', LFont);
    finally
      LFont.Free;
    end;
  end;
end;

{ TFakeSettingsSource }

function TFakeSettingsSource.Settings: TArray<TXcomFontOverlaySettings>;
begin
  Result := Entries;
end;

procedure TFakeSettingsSource.Commit;
begin
  Inc(Commits);
end;

{ TFakeToggles }

constructor TFakeToggles.Create(ACount: Integer);
begin
  inherited Create;
  SetLength(FValues, ACount);
end;

function TFakeToggles.Heading: string;
begin
  Result := 'FIRST';
end;

function TFakeToggles.Count: Integer;
begin
  Result := Length(FValues);
end;

function TFakeToggles.Title(AIndex: Integer): string;
begin
  Result := 'toggle ' + IntToStr(AIndex);
end;

function TFakeToggles.Description(AIndex: Integer): string;
begin
  Result := 'about toggle ' + IntToStr(AIndex);
end;

function TFakeToggles.IsOn(AIndex: Integer): Boolean;
begin
  Result := FValues[AIndex];
end;

procedure TFakeToggles.SetOn(AIndex: Integer; AValue: Boolean);
begin
  FValues[AIndex] := AValue;
end;

{ TTestXcomFontChoices }

procedure TTestXcomFontChoices.Setup;
begin
  FFiles := TFakeFileSystem.Create;
  FFilesRef := FFiles;
  FLog := TFontTestLog.Create;
  FLogRef := FLog;
end;

procedure TTestXcomFontChoices.TearDown;
begin
  FLogRef := nil;
  FFilesRef := nil;
end;

function TTestXcomFontChoices.Choices(const AInstalled: TArray<string>; const AHand, ALocked: string): IXcomExtraOptions;
var
  LFonts: IXcomSystemFonts;
begin
  if AHand <> '' then
    FFiles.Put(USER_FILE, AHand);
  // in a variable: an object made inside the argument of a const interface parameter is not counted
  LFonts := TFakeSystemFonts.Create(AInstalled);
  Result := TXcomFontChoices.Create(FFilesRef, TYamlFactory.CreateParser, USER_FILE, ALocked, LFonts, FLogRef);
end;

function TTestXcomFontChoices.Written: string;
begin
  Result := TEncoding.UTF8.GetString(FFiles.ReadAll(USER_FILE));
end;

function TTestXcomFontChoices.Parsed(const AText: string): TArray<TXcomFontOverlaySettings>;
begin
  Result := TXcomFontSettingsReader.Read(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(AText)));
end;

procedure TTestXcomFontChoices.DovrebbeAvereCinqueRigheOgniFontDelGioco;
var
  LOptions: IXcomExtraOptions;
begin
  LOptions := Choices(Usual);
  Assert.AreEqual(20, LOptions.Count);
  Assert.AreEqual('DELPHIDOOM', LOptions.Heading);
  Assert.AreEqual('Big font: Original', LOptions.Title(0));
  Assert.AreEqual('Small font: Original', LOptions.Title(5));
  Assert.AreEqual('Geoscape big font: Original', LOptions.Title(10));
  Assert.AreEqual('Geoscape small font: Original', LOptions.Title(15));
  Assert.AreEqual('Geoscape small font shrink to fit', LOptions.Title(19));
  Assert.IsTrue(LOptions.Description(3) <> '');
end;

procedure TTestXcomFontChoices.DovrebbePartireDaOriginalSenzaFile;
var
  LSource: IXcomFontSettingsSource;
begin
  LSource := Choices(Usual) as IXcomFontSettingsSource;
  Assert.AreEqual(0, Length(LSource.Settings));
  Assert.IsFalse(FFiles.FileExists(USER_FILE));
end;

procedure TTestXcomFontChoices.LeRigheDiUnFontOriginalNonDovrebberoEssereModificabili;
var
  LOptions: IXcomExtraOptions;
  LKinds: IXcomExtraChoiceOptions;
begin
  LOptions := Choices(Usual);
  LKinds := LOptions as IXcomExtraChoiceOptions;
  Assert.AreEqual(Ord(ekChoice), Ord(LKinds.Kind(0)));
  Assert.AreEqual(Ord(ekInfo), Ord(LKinds.Kind(1)));
  Assert.AreEqual(Ord(ekInfo), Ord(LKinds.Kind(2)));
  Assert.AreEqual(Ord(ekInfo), Ord(LKinds.Kind(3)));
  Assert.AreEqual(Ord(ekInfo), Ord(LKinds.Kind(4)));
  Assert.AreEqual('Big font size: -', LOptions.Title(1));
end;

procedure TTestXcomFontChoices.UnClickSulFontDovrebbeScegliereIlPrimoInstallato;
var
  LOptions: IXcomExtraOptions;
  LKinds: IXcomExtraChoiceOptions;
begin
  LOptions := Choices(['Verdana', 'Consolas']);
  LKinds := LOptions as IXcomExtraChoiceOptions;
  LKinds.Step(0, 1);
  // Tahoma is not installed: the first one of the usual list that is
  Assert.AreEqual('Big font: Verdana', LOptions.Title(0));
  Assert.AreEqual(Ord(ekChoice), Ord(LKinds.Kind(1)));
  Assert.AreEqual(Ord(ekToggle), Ord(LKinds.Kind(2)));
  Assert.AreEqual(Ord(ekToggle), Ord(LKinds.Kind(3)));
  Assert.AreEqual(Ord(ekToggle), Ord(LKinds.Kind(4)));
end;

procedure TTestXcomFontChoices.IlFontScelto_DovrebbeAvereLaMisuraELeOpzioniPredefiniteDelSuoFont;
var
  LOptions: IXcomExtraOptions;
  LSource: IXcomFontSettingsSource;
  LEntries: TArray<TXcomFontOverlaySettings>;
begin
  LOptions := Choices(Usual);
  LSource := LOptions as IXcomFontSettingsSource;
  (LOptions as IXcomExtraChoiceOptions).Step(0, 1);
  (LOptions as IXcomExtraChoiceOptions).Step(15, 1);
  LEntries := LSource.Settings;
  Assert.AreEqual(2, Length(LEntries));
  Assert.AreEqual('FONT_BIG', LEntries[0].FontId);
  Assert.AreEqual(13, LEntries[0].Face.Size);
  Assert.IsTrue(LEntries[0].Face.Bold);
  Assert.IsTrue(LEntries[0].Face.Antialias);
  Assert.IsTrue(LEntries[0].Shrink);
  Assert.AreEqual('FONT_GEO_SMALL', LEntries[1].FontId);
  Assert.AreEqual(6, LEntries[1].Face.Size);
  Assert.IsFalse(LEntries[1].Face.Bold);
  Assert.AreEqual('Big font size: 13', LOptions.Title(1));
  Assert.IsTrue(LOptions.IsOn(2));
  Assert.IsTrue(LOptions.IsOn(3));
  Assert.IsTrue(LOptions.IsOn(4));
end;

procedure TTestXcomFontChoices.IlClickDestroDaOriginalDovrebbeScegliereLUltimo;
var
  LOptions: IXcomExtraOptions;
begin
  LOptions := Choices(Usual);
  (LOptions as IXcomExtraChoiceOptions).Step(0, -1);
  Assert.AreEqual('Big font: Consolas', LOptions.Title(0));
end;

procedure TTestXcomFontChoices.DovrebbeOffrireSoloIFontInstallati;
var
  LOptions: IXcomExtraOptions;
  LKinds: IXcomExtraChoiceOptions;
begin
  // the comparison does not look at the case, and a font that is not a usual one is not offered
  LOptions := Choices(['verdana', 'Comic Sans MS']);
  LKinds := LOptions as IXcomExtraChoiceOptions;
  LKinds.Step(0, 1);
  Assert.AreEqual('Big font: Verdana', LOptions.Title(0));
  LKinds.Step(0, 1);
  Assert.AreEqual('Big font: Original', LOptions.Title(0));
end;

procedure TTestXcomFontChoices.DopoLUltimoFontDovrebbeTornareOriginalERimuovereLaVoce;
var
  LOptions: IXcomExtraOptions;
  LSource: IXcomFontSettingsSource;
begin
  LOptions := Choices(Usual);
  LSource := LOptions as IXcomFontSettingsSource;
  (LOptions as IXcomExtraChoiceOptions).Step(5, 1);
  (LOptions as IXcomExtraChoiceOptions).Step(5, 1);
  (LOptions as IXcomExtraChoiceOptions).Step(5, 1);
  Assert.AreEqual('Small font: Consolas', LOptions.Title(5));
  Assert.AreEqual(1, Length(LSource.Settings));
  (LOptions as IXcomExtraChoiceOptions).Step(5, 1);
  Assert.AreEqual('Small font: Original', LOptions.Title(5));
  Assert.AreEqual(0, Length(LSource.Settings));
  Assert.AreEqual(Ord(ekInfo), Ord((LOptions as IXcomExtraChoiceOptions).Kind(6)));
end;

procedure TTestXcomFontChoices.LaMisuraDovrebbeFareIlGiroTraIlMinimoEIlMassimo;
var
  LOptions: IXcomExtraOptions;
  LKinds: IXcomExtraChoiceOptions;
begin
  LOptions := Choices(Usual);
  LKinds := LOptions as IXcomExtraChoiceOptions;
  // the geoscape small font starts at 6
  LKinds.Step(15, 1);
  LKinds.Step(16, 1);
  Assert.AreEqual('Geoscape small font size: 7', LOptions.Title(16));
  LKinds.Step(16, -1);
  LKinds.Step(16, -1);
  Assert.AreEqual('Geoscape small font size: 5', LOptions.Title(16));
  LKinds.Step(16, -1);
  Assert.AreEqual('Geoscape small font size: 4', LOptions.Title(16));
  LKinds.Step(16, -1);
  Assert.AreEqual('Geoscape small font size: 32', LOptions.Title(16));
  LKinds.Step(16, 1);
  Assert.AreEqual('Geoscape small font size: 4', LOptions.Title(16));
end;

procedure TTestXcomFontChoices.DovrebbeCambiareGrassettoBordiERestringimento;
var
  LOptions: IXcomExtraOptions;
  LSource: IXcomFontSettingsSource;
begin
  LOptions := Choices(Usual);
  LSource := LOptions as IXcomFontSettingsSource;
  (LOptions as IXcomExtraChoiceOptions).Step(5, 1);
  LOptions.SetOn(7, True);
  LOptions.SetOn(8, False);
  LOptions.SetOn(9, False);
  Assert.IsTrue(LSource.Settings[0].Face.Bold);
  Assert.IsFalse(LSource.Settings[0].Face.Antialias);
  Assert.IsFalse(LSource.Settings[0].Shrink);
  Assert.IsTrue(LOptions.IsOn(7));
  Assert.IsFalse(LOptions.IsOn(8));
  // the rows of a font that is Original do nothing
  LOptions.SetOn(2, True);
  Assert.IsFalse(LOptions.IsOn(2));
end;

procedure TTestXcomFontChoices.ConfermareDovrebbeScrivereFontsCfgCheSiRilegge;
var
  LOptions: IXcomExtraOptions;
  LEntries: TArray<TXcomFontOverlaySettings>;
  LAgain: IXcomExtraOptions;
begin
  LOptions := Choices(Usual);
  (LOptions as IXcomExtraChoiceOptions).Step(0, 1);
  (LOptions as IXcomExtraChoiceOptions).Step(1, 1);
  (LOptions as IXcomFontSettingsSource).Commit;
  Assert.IsTrue(FFiles.FileExists(USER_FILE));
  LEntries := Parsed(Written);
  Assert.AreEqual(1, Length(LEntries));
  Assert.AreEqual('FONT_BIG', LEntries[0].FontId);
  Assert.AreEqual('Tahoma', LEntries[0].Face.Name);
  Assert.AreEqual(14, LEntries[0].Face.Size);
  // a new start reads it back
  LAgain := Choices(Usual);
  Assert.AreEqual('Big font: Tahoma', LAgain.Title(0));
  Assert.AreEqual('Big font size: 14', LAgain.Title(1));
end;

procedure TTestXcomFontChoices.ConfermareSenzaCambiamentiNonDovrebbeScrivereNulla;
var
  LOptions: IXcomExtraOptions;
begin
  LOptions := Choices(Usual);
  (LOptions as IXcomFontSettingsSource).Commit;
  Assert.IsFalse(FFiles.FileExists(USER_FILE));
end;

procedure TTestXcomFontChoices.AnnullareDovrebbeDimenticareLeModifiche;
var
  LOptions: IXcomExtraOptions;
begin
  LOptions := Choices(Usual);
  (LOptions as IXcomExtraChoiceOptions).Step(0, 1);
  (LOptions as IXcomFontSettingsSource).Commit;
  (LOptions as IXcomExtraChoiceOptions).Step(0, 1);
  (LOptions as IXcomExtraChoiceOptions).Step(5, 1);
  Assert.AreEqual('Big font: Verdana', LOptions.Title(0));
  (LOptions as IXcomExtraChoiceOptions).Discard;
  Assert.AreEqual('Big font: Tahoma', LOptions.Title(0));
  Assert.AreEqual('Small font: Original', LOptions.Title(5));
end;

procedure TTestXcomFontChoices.DovrebbeLeggereIlFileGiaScrittoELasciareLeChiaviCheNonMostra;
var
  LOptions: IXcomExtraOptions;
  LEntries: TArray<TXcomFontOverlaySettings>;
begin
  LOptions := Choices(Usual,
    'fonts:'#10'  - id: FONT_SMALL'#10'    name: Tahoma'#10'    size: 8'#10'    spacing: -1'#10'    tolerance: 40'#10 +
    '    offsetY: 1'#10'    outline: false'#10);
  Assert.AreEqual('Small font: Tahoma', LOptions.Title(5));
  (LOptions as IXcomExtraChoiceOptions).Step(6, 1);
  (LOptions as IXcomFontSettingsSource).Commit;
  LEntries := Parsed(Written);
  Assert.AreEqual(9, LEntries[0].Face.Size);
  Assert.IsTrue(LEntries[0].HasSpacing);
  Assert.AreEqual(-1, LEntries[0].Spacing);
  Assert.AreEqual(40, LEntries[0].Tolerance);
  Assert.AreEqual(1, LEntries[0].OffsetY);
  Assert.AreEqual(Ord(goOff), Ord(LEntries[0].Outline));
end;

procedure TTestXcomFontChoices.UnFontScrittoAManoDovrebbeRestareNellElenco;
var
  LOptions: IXcomExtraOptions;
  LKinds: IXcomExtraChoiceOptions;
begin
  LOptions := Choices(Usual, 'fonts:'#10'  - id: FONT_BIG'#10'    name: Papyrus'#10'    size: 12'#10);
  LKinds := LOptions as IXcomExtraChoiceOptions;
  Assert.AreEqual('Big font: Papyrus', LOptions.Title(0));
  // next to Original: Original, Papyrus, Tahoma...
  LKinds.Step(0, 1);
  Assert.AreEqual('Big font: Tahoma', LOptions.Title(0));
  // it is in the list only while it is the one chosen: leaving it, it is gone until the options are cancelled
  LKinds.Step(0, -1);
  Assert.AreEqual('Big font: Original', LOptions.Title(0));
  LKinds.Discard;
  LKinds.Step(0, -1);
  Assert.AreEqual('Big font: Original', LOptions.Title(0));
end;

procedure TTestXcomFontChoices.UnFileDovrebbeEssereSostituitoDallaFamigliaMantenendoLeAltreChiavi;
var
  LOptions: IXcomExtraOptions;
  LSource: IXcomFontSettingsSource;
begin
  LOptions := Choices(Usual, 'fonts:'#10'  - id: FONT_BIG'#10'    file: ''C:\x\my.ttf'''#10'    size: 12'#10 +
    '    tolerance: 60'#10);
  LSource := LOptions as IXcomFontSettingsSource;
  Assert.AreEqual('Big font: my.ttf', LOptions.Title(0));
  (LOptions as IXcomExtraChoiceOptions).Step(0, -1);
  // the file is not in the list: Original, my.ttf, Tahoma... going back from it gives Original
  Assert.AreEqual('Big font: Original', LOptions.Title(0));
  (LOptions as IXcomExtraChoiceOptions).Discard;
  (LOptions as IXcomExtraChoiceOptions).Step(0, 1);
  Assert.AreEqual('Big font: Tahoma', LOptions.Title(0));
  Assert.AreEqual('', LSource.Settings[0].Face.FileName);
  Assert.AreEqual(60, LSource.Settings[0].Tolerance);
  Assert.AreEqual(12, LSource.Settings[0].Face.Size);
end;

procedure TTestXcomFontChoices.ConFontsDellaRigaDiComandoDovrebbeEsserciUnaRigaSolaNonModificabile;
var
  LOptions: IXcomExtraOptions;
  LKinds: IXcomExtraChoiceOptions;
begin
  FFiles.Put('cli.cfg', 'fonts:'#10'  - id: FONT_BIG'#10'    name: Verdana'#10'    size: 12'#10);
  LOptions := Choices(Usual, '', 'cli.cfg');
  LKinds := LOptions as IXcomExtraChoiceOptions;
  Assert.AreEqual(1, LOptions.Count);
  Assert.AreEqual(Ord(ekInfo), Ord(LKinds.Kind(0)));
  Assert.IsTrue(LOptions.Title(0).Contains('-fonts'));
  LKinds.Step(0, 1);
  LOptions.SetOn(0, True);
  Assert.AreEqual(Ord(ekInfo), Ord(LKinds.Kind(0)));
  Assert.IsFalse(LOptions.IsOn(0));
end;

procedure TTestXcomFontChoices.ConFontsDellaRigaDiComandoLeImpostazioniSonoQuelleDelFile;
var
  LSource: IXcomFontSettingsSource;
begin
  // the file of the user folder is there too and does not count
  FFiles.Put('cli.cfg', 'fonts:'#10'  - id: FONT_BIG'#10'    name: Verdana'#10'    size: 12'#10);
  LSource := Choices(Usual, 'fonts:'#10'  - id: FONT_SMALL'#10'    name: Tahoma'#10'    size: 8'#10, 'cli.cfg')
    as IXcomFontSettingsSource;
  Assert.AreEqual(1, Length(LSource.Settings));
  Assert.AreEqual('Verdana', LSource.Settings[0].Face.Name);
end;

procedure TTestXcomFontChoices.ConFontsDellaRigaDiComandoConfermareNonDovrebbeScrivereFontsCfg;
var
  LOptions: IXcomExtraOptions;
begin
  FFiles.Put('cli.cfg', 'fonts:'#10'  - id: FONT_BIG'#10'    name: Verdana'#10'    size: 12'#10);
  LOptions := Choices(Usual, '', 'cli.cfg');
  (LOptions as IXcomFontSettingsSource).Commit;
  Assert.IsFalse(FFiles.FileExists(USER_FILE));
end;

procedure TTestXcomFontChoices.DovrebbeRifiutareFileSystemNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomFontChoices.Create(nil, TYamlFactory.CreateParser, '', '', nil, nil);
    end, EArgumentNilException);
end;

{ TTestXcomFontSettingsWriter }

procedure TTestXcomFontSettingsWriter.UnElencoVuotoDovrebbeEssereUnaSequenzaVuota;
var
  LText: string;
begin
  LText := TXcomFontSettingsWriter.Write(nil);
  Assert.AreEqual('fonts: []'#10, LText);
  Assert.AreEqual(0, Length(TXcomFontSettingsReader.Read(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(LText)))));
end;

procedure TTestXcomFontSettingsWriter.DovrebbeScrivereCioCheIlLettoreRilegge;
var
  LSettings: TXcomFontOverlaySettings;
  LText: string;
  LBack: TArray<TXcomFontOverlaySettings>;
begin
  LSettings := TXcomFontOverlaySettings.Make('FONT_GEO_BIG', 'Segoe UI', 9);
  LSettings.Face.Bold := True;
  LSettings.Face.Antialias := False;
  LSettings.Outline := goOn;
  LSettings.HasSpacing := True;
  LSettings.Spacing := -2;
  LSettings.Tolerance := 0;
  LSettings.Shrink := True;
  LSettings.OffsetY := 2;
  LText := TXcomFontSettingsWriter.Write([LSettings, TXcomFontOverlaySettings.Make('FONT_SMALL', 'Tahoma', 8)]);
  LBack := TXcomFontSettingsReader.Read(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(LText)));
  Assert.AreEqual(2, Length(LBack));
  Assert.AreEqual('FONT_GEO_BIG', LBack[0].FontId);
  Assert.AreEqual('Segoe UI', LBack[0].Face.Name);
  Assert.AreEqual(9, LBack[0].Face.Size);
  Assert.IsTrue(LBack[0].Face.Bold);
  Assert.IsFalse(LBack[0].Face.Antialias);
  Assert.AreEqual(Ord(goOn), Ord(LBack[0].Outline));
  Assert.AreEqual(-2, LBack[0].Spacing);
  Assert.IsTrue(LBack[0].HasSpacing);
  Assert.AreEqual(0, LBack[0].Tolerance);
  Assert.IsTrue(LBack[0].Shrink);
  Assert.AreEqual(2, LBack[0].OffsetY);
  Assert.AreEqual('Tahoma', LBack[1].Face.Name);
end;

procedure TTestXcomFontSettingsWriter.DovrebbeProteggereIPercorsiELeApici;
var
  LSettings: TXcomFontOverlaySettings;
  LBack: TArray<TXcomFontOverlaySettings>;
begin
  LSettings := TXcomFontOverlaySettings.Make('FONT_BIG', 'Bob''s: Font #1', 12);
  LSettings.Face.FileName := 'C:\Fonts\a b\my.ttf';
  LBack := TXcomFontSettingsReader.Read(TYamlFactory.CreateParser.Load(
    TEncoding.UTF8.GetBytes(TXcomFontSettingsWriter.Write([LSettings]))));
  Assert.AreEqual(1, Length(LBack));
  Assert.AreEqual('Bob''s: Font #1', LBack[0].Face.Name);
  Assert.AreEqual('C:\Fonts\a b\my.ttf', LBack[0].Face.FileName);
end;

procedure TTestXcomFontSettingsWriter.NonDovrebbeScrivereLeChiaviPredefinite;
var
  LText: string;
begin
  LText := TXcomFontSettingsWriter.Write([TXcomFontOverlaySettings.Make('FONT_BIG', 'Tahoma', 13)]);
  Assert.IsFalse(LText.Contains('outline'));
  Assert.IsFalse(LText.Contains('spacing'));
  Assert.IsFalse(LText.Contains('tolerance'));
  Assert.IsFalse(LText.Contains('offsetY'));
  Assert.IsFalse(LText.Contains('file'));
end;

{ TTestXcomExtraOptionSet }

procedure TTestXcomExtraOptionSet.Setup;
var
  LFonts: IXcomSystemFonts;
begin
  FFiles := TFakeFileSystem.Create;
  FFilesRef := FFiles;
  FToggles := TFakeToggles.Create(2);
  LFonts := TFakeSystemFonts.Create(['Tahoma']);
  FChoices := TXcomFontChoices.Create(FFilesRef, TYamlFactory.CreateParser, '', '', LFonts, nil);
  FSet := TXcomExtraOptionSet.Create([FToggles, FChoices]);
end;

procedure TTestXcomExtraOptionSet.TearDown;
begin
  FSet := nil;
  FChoices := nil;
  FToggles := nil;
  FFilesRef := nil;
end;

procedure TTestXcomExtraOptionSet.DovrebbeSommareLeRighe;
begin
  Assert.AreEqual(22, FSet.Count);
end;

procedure TTestXcomExtraOptionSet.DovrebbeDareLIntestazioneDelPrimo;
begin
  Assert.AreEqual('FIRST', FSet.Heading);
end;

procedure TTestXcomExtraOptionSet.LeRigheDiUnaParteSenzaScelteDovrebberoEssereInterruttori;
var
  LKinds: IXcomExtraChoiceOptions;
begin
  LKinds := FSet as IXcomExtraChoiceOptions;
  Assert.AreEqual(Ord(ekToggle), Ord(LKinds.Kind(0)));
  Assert.AreEqual(Ord(ekToggle), Ord(LKinds.Kind(1)));
  Assert.AreEqual(Ord(ekChoice), Ord(LKinds.Kind(2)));
  Assert.AreEqual(Ord(ekInfo), Ord(LKinds.Kind(3)));
end;

procedure TTestXcomExtraOptionSet.DovrebbeInoltrareIlPassoEIlTitoloAllaParteGiusta;
begin
  Assert.AreEqual('toggle 1', FSet.Title(1));
  Assert.AreEqual('Big font: Original', FSet.Title(2));
  // a step on a toggle does nothing, on the font moves it
  (FSet as IXcomExtraChoiceOptions).Step(0, 1);
  (FSet as IXcomExtraChoiceOptions).Step(2, 1);
  Assert.AreEqual('Big font: Tahoma', FSet.Title(2));
  Assert.IsTrue(FSet.Description(1).Contains('toggle 1'));
  Assert.IsTrue(FSet.Description(2).Contains('big font'));
end;

procedure TTestXcomExtraOptionSet.DovrebbeInoltrareGliInterruttori;
begin
  FSet.SetOn(1, True);
  Assert.IsTrue(FSet.IsOn(1));
  Assert.IsTrue(FToggles.IsOn(1));
  Assert.IsFalse(FSet.IsOn(0));
  (FSet as IXcomExtraChoiceOptions).Step(2, 1);
  // shrink to fit of the first font starts on
  Assert.IsTrue(FSet.IsOn(6));
  FSet.SetOn(6, False);
  Assert.IsFalse(FSet.IsOn(6));
end;

procedure TTestXcomExtraOptionSet.AnnullareDovrebbeArrivareATutteLeParti;
begin
  (FSet as IXcomExtraChoiceOptions).Step(2, 1);
  (FSet as IXcomExtraChoiceOptions).Discard;
  Assert.AreEqual('Big font: Original', FSet.Title(2));
end;

procedure TTestXcomExtraOptionSet.UnIndiceFuoriDallElencoDovrebbeSollevareUnEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      FSet.Title(22);
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      FSet.Title(-1);
    end, EArgumentOutOfRangeException);
end;

procedure TTestXcomExtraOptionSet.DovrebbeRifiutareUnaParteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomExtraOptionSet.Create([nil]);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TXcomExtraOptionSet.Create(nil);
    end, EArgumentNilException);
end;

{ TTestXcomFontReloader }

procedure TTestXcomFontReloader.Setup;
begin
  FSource := TFakeSettingsSource.Create;
  FSourceRef := FSource;
  FResources := TReapplyingResources.Create;
  FResourcesRef := FResources;
  FRasterizer := TFakeGlyphRasterizer.Create(3, 5, 2);
  FFactory := TFakeGlyphRasterizerFactory.Create;
  FFactoryRef := FFactory;
  FFactory.Rasterizer := FRasterizer;
  FLog := TFontTestLog.Create;
  FLogRef := FLog;
end;

procedure TTestXcomFontReloader.TearDown;
begin
  FResourcesRef := nil;
  FFactoryRef := nil;
  FSourceRef := nil;
  FLogRef := nil;
end;

function TTestXcomFontReloader.Reloader: IXcomFontReloader;
begin
  Result := TXcomFontReloader.Create(FSourceRef,
    function(const ASettings: TArray<TXcomFontOverlaySettings>): IXcomFontOverlay
    begin
      if Length(ASettings) = 0 then
        Result := nil
      else
        Result := TXcomRasterFontOverlay.Create(ASettings, FFactoryRef, FLogRef);
    end);
end;

procedure TTestXcomFontReloader.DovrebbeConfermareLaScelta;
begin
  Reloader.Reload(FResourcesRef);
  Assert.AreEqual(1, FSource.Commits);
end;

procedure TTestXcomFontReloader.DovrebbeDareLeRisorseUnOverlayPerLeVoci;
var
  LFont: TXcomFont;
begin
  FSource.Entries := [TXcomFontOverlaySettings.Make('FONT_SMALL', 'Tahoma', 8)];
  Reloader.Reload(FResourcesRef);
  Assert.AreEqual(1, FResources.Calls);
  Assert.IsTrue(Assigned(FResources.Overlay));
  LFont := TFontFixtures.Font('AB?');
  try
    FResources.Overlay.Apply('FONT_SMALL', LFont);
    Assert.AreEqual(2, LFont.ImageCount);
  finally
    LFont.Free;
  end;
end;

procedure TTestXcomFontReloader.SenzaVociDovrebbeDareLeRisorseUnOverlayNil;
begin
  FResources.Overlay := TXcomRasterFontOverlay.Create(nil, FFactoryRef, nil);
  Reloader.Reload(FResourcesRef);
  // the fonts still go back to the pictures of the game
  Assert.AreEqual(1, FResources.Calls);
  Assert.IsFalse(Assigned(FResources.Overlay));
end;

procedure TTestXcomFontReloader.DovrebbeDareGliAvvisiPerIlPlayer;
var
  LNotices: TArray<string>;
begin
  FFactory.Rasterizer := nil;
  FFactory.Reason := 'no such font';
  FSource.Entries := [TXcomFontOverlaySettings.Make('FONT_BIG', 'Papyrus', 13)];
  LNotices := Reloader.Reload(FResourcesRef);
  Assert.AreEqual(1, Length(LNotices));
  Assert.AreEqual('The font "Papyrus" is not installed, so the big font stays the original one.', LNotices[0]);
end;

procedure TTestXcomFontReloader.RisorseCheNonCambianoIFontDovrebbeSoloConfermare;
var
  LResources: IXcomResources;
  LNotices: TArray<string>;
begin
  LResources := TFakeResources.Create;
  FSource.Entries := [TXcomFontOverlaySettings.Make('FONT_BIG', 'Tahoma', 13)];
  LNotices := Reloader.Reload(LResources);
  Assert.AreEqual(1, FSource.Commits);
  Assert.AreEqual(0, Length(LNotices));
end;

procedure TTestXcomFontReloader.DovrebbeRifiutareArgomentiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomFontReloader.Create(nil,
        function(const ASettings: TArray<TXcomFontOverlaySettings>): IXcomFontOverlay
        begin
          Result := nil;
        end);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TXcomFontReloader.Create(FSourceRef, nil);
    end, EArgumentNilException);
end;

{ TTestXcomRasterFontNotices }

procedure TTestXcomRasterFontNotices.Setup;
begin
  FRasterizer := TFakeGlyphRasterizer.Create(3, 5, 2);
  FFactory := TFakeGlyphRasterizerFactory.Create;
  FFactoryRef := FFactory;
  FFactory.Rasterizer := FRasterizer;
  FFont := TFontFixtures.Font('AB?');
end;

procedure TTestXcomRasterFontNotices.TearDown;
begin
  FFont.Free;
  FFactoryRef := nil;
end;

function TTestXcomRasterFontNotices.Run(const ASettings: TXcomFontOverlaySettings;
  const AFontId: string): TArray<string>;
var
  LOverlay: IXcomFontOverlay;
begin
  LOverlay := TXcomRasterFontOverlay.Create([ASettings], FFactoryRef, nil);
  LOverlay.Apply(AFontId, FFont);
  Result := (LOverlay as IXcomFontNotices).Notices;
end;

procedure TTestXcomRasterFontNotices.UnFontCheEntraNonDovrebbeAvereAvvisiPerIlPlayer;
begin
  Assert.AreEqual(0, Length(Run(TXcomFontOverlaySettings.Make('FONT_SMALL', 'Tahoma', 8), 'FONT_SMALL')));
end;

procedure TTestXcomRasterFontNotices.UnFontNonInstallatoDovrebbeDirloAlPlayer;
var
  LNotices: TArray<string>;
begin
  FFactory.Rasterizer := nil;
  FFactory.Reason := 'no such font';
  LNotices := Run(TXcomFontOverlaySettings.Make('FONT_SMALL', 'Papyrus', 8), 'FONT_SMALL');
  Assert.AreEqual(1, Length(LNotices));
  Assert.AreEqual('The font "Papyrus" is not installed, so the small font stays the original one.', LNotices[0]);
end;

procedure TTestXcomRasterFontNotices.UnFontTroppoGrandeDovrebbeSuggerireDiRestringere;
var
  LNotices: TArray<string>;
begin
  FRasterizer.DefaultHeight := 11;
  LNotices := Run(TXcomFontOverlaySettings.Make('FONT_BIG', 'Tahoma', 13), 'FONT_BIG');
  Assert.AreEqual(1, Length(LNotices));
  Assert.IsTrue(LNotices[0].Contains('"Tahoma" at size 13 does not fit the big font'));
  Assert.IsTrue(LNotices[0].Contains('shrink to fit'));
  // too wide says the same
  FRasterizer.DefaultHeight := 5;
  FRasterizer.DefaultWidth := 9;
  LNotices := Run(TXcomFontOverlaySettings.Make('FONT_BIG', 'Tahoma', 13), 'FONT_BIG');
  Assert.AreEqual(1, Length(LNotices));
  Assert.IsTrue(LNotices[0].Contains('does not fit'));
end;

procedure TTestXcomRasterFontNotices.UnFontRestrettoDovrebbeDireLaNuovaMisura;
var
  LSettings: TXcomFontOverlaySettings;
  LTall: IXcomGlyphRasterizer;
  LNotices: TArray<string>;
begin
  LTall := TFakeGlyphRasterizer.Create(3, 11, 2);
  FFactory.BySize := [nil, nil, nil, nil, nil, nil, nil, LTall, LTall];
  LSettings := TXcomFontOverlaySettings.Make('FONT_GEO_BIG', 'Tahoma', 8);
  LSettings.Shrink := True;
  LNotices := Run(LSettings, 'FONT_GEO_BIG');
  Assert.AreEqual(1, Length(LNotices));
  Assert.AreEqual('The geoscape big font was made smaller to fit: size 6 instead of 8.', LNotices[0]);
end;

procedure TTestXcomRasterFontNotices.UnFontSenzaICaratteriDovrebbeDirloAlPlayer;
var
  LNotices: TArray<string>;
begin
  FRasterizer.Remove(Ord('A'));
  FRasterizer.Remove(Ord('B'));
  FRasterizer.Remove(Ord('?'));
  LNotices := Run(TXcomFontOverlaySettings.Make('FONT_SMALL', 'Wingdings', 8), 'FONT_SMALL');
  Assert.AreEqual(1, Length(LNotices));
  Assert.IsTrue(LNotices[0].Contains('has none of the characters'));
end;

procedure TTestXcomRasterFontNotices.IlNomeDelFontDelGiocoDovrebbeEssereInParole;
var
  LNotices: TArray<string>;
begin
  FFactory.Rasterizer := nil;
  LNotices := Run(TXcomFontOverlaySettings.Make('FONT_GEO_SMALL', 'X', 6), 'FONT_GEO_SMALL');
  Assert.IsTrue(LNotices[0].Contains('geoscape small font'));
  LNotices := Run(TXcomFontOverlaySettings.Make('FONT_OTHER', 'X', 6), 'FONT_OTHER');
  Assert.IsTrue(LNotices[0].Contains('FONT_OTHER'));
end;

end.
