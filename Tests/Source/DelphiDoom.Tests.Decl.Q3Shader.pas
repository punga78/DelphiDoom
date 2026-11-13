{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III shaders (issue #119)                     }
{                                                                              }
{  The tokenizer, the scanner of .shader files, the keywords of a shader, the  }
{  registration, and the reading of the files through the manager.             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Q3Shader;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Source.Memory, DelphiDoom.Decl.Q3Shader.Types,
  DelphiDoom.Decl.Q3Shader.Intf, DelphiDoom.Tests.Scanner.IdFakes;

type
  /// <summary>A manager with only the type "shader", over files in memory, and the log it writes to</summary>
  TQ3ShaderKit = class
  strict private
    FSource: TDeclMemorySource;
    FSourceIntf: IInterface;
    FLogObject: TFakeIdLibLog;
    FLog: IIdLibLog;
    FManager: IDeclManager;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Builds the manager after the files are added (a folder is read when it is registered)</summary>
    procedure Start(const AOptions: TQ3ShaderOptions; const ALoadFolder: Boolean = True);
    /// <summary>The shader of that name; the text of its declaration is "name { body }" in a file of the folder</summary>
    function Find(const AName: AnsiString): IDeclQ3Shader;
    property Source: TDeclMemorySource read FSource;
    property Manager: IDeclManager read FManager;
    function Lines: TStrings;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderTokenizer = class
  public
    [Test]
    procedure DovrebbeLeggereParoleSeparateDaBlank;
    [Test]
    procedure DovrebbeDareVuotoAFineRigaSenzaPermettereAndareACapo;
    [Test]
    procedure DovrebbeSaltareLaRigaSeAndareACapoEPermesso;
    [Test]
    procedure DovrebbeSaltareICommentiDiRigaEDiBlocco;
    [Test]
    procedure DovrebbeMantenereIBlankTraVirgolette;
    [Test]
    procedure DovrebbeTerminareSeLeVirgoletteNonSiChiudono;
    [Test]
    procedure DovrebbeScartareUnaParolaDiMilleventiquattroCaratteri;
    [Test]
    procedure DovrebbeTrattareIByteAltiComeBlank;
    [Test]
    procedure DovrebbeNonSepararareUnaGraffaAttaccataAUnaParola;
    [Test]
    procedure DovrebbeSaltareIlRestoDellaRiga;
    [Test]
    procedure DovrebbeSaltareUnaSezioneConGraffeAnnidate;
    [Test]
    procedure DovrebbeSaltareUnaSolaParolaSeNonCEUnaGraffa;
    [Test]
    procedure DovrebbeFermarsiAllaFineDelTestoNellaSezioneAperta;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderCompressor = class
  public
    [Test]
    procedure DovrebbeRiunireIBlankELeRigheInUnoSolo;
    [Test]
    procedure DovrebbeTogliereICommenti;
    [Test]
    procedure DovrebbeUnireLeParoleSeUnCommentoLeSepara;
    [Test]
    procedure DovrebbeTagliareUnaParolaAUnCommentoAttaccato;
    [Test]
    procedure DovrebbeCopiareLeVirgoletteSenzaToccarle;
    [Test]
    procedure DovrebbeTrattareUnCRSoloComeAndareACapo;
    [Test]
    procedure DovrebbeFermarsiAlPrimoNul;
    [Test]
    procedure DovrebbeDareLaPosizioneNelTestoDiOgniCarattere;
    [Test]
    procedure DovrebbeDareVuotoPerUnTestoDiSoliCommenti;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderFileScanner = class
  public
    [Test]
    procedure DovrebbeTrovareNomeOffsetELineaDiOgniShader;
    [Test]
    procedure DovrebbeLeggereUnFileConIRitorniACapoDelMacintosh;
    [Test]
    procedure DovrebbeNonTrovareNullaInUnFileVuoto;
    [Test]
    procedure DovrebbeIncludereICommentiSopraLaDefinizione;
    [Test]
    procedure DovrebbeFinireAFineTestoConUnaSezioneAperta;
    [Test]
    procedure DovrebbeFermarsiConUnaParolaVuotaTraVirgolette;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderKeywords = class
  strict private
    FKit: TQ3ShaderKit;
    function Shader(const ABody: AnsiString): IDeclQ3Shader;
    function Log: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereUnoStageConLeImmagini;
    [Test]
    procedure DovrebbeLeggereAnimMapFinoAOttoImmagini;
    [Test]
    procedure DovrebbeLeggereVideoMap;
    [Test]
    procedure DovrebbeUsareIlLightmapENomiDelleImmaginiDelRenderer;
    [Test]
    procedure DovrebbeCalcolareIBitDiStatoDiBlendEDepth;
    [Test]
    procedure DovrebbeDisattivareIlBlendUnoZero;
    [Test]
    procedure DovrebbeScegliereIlColoreDiDefaultDallaBlend;
    [Test]
    procedure DovrebbeLeggereIlColoreCostanteInByte;
    [Test]
    procedure DovrebbeLeggereUnaOnda;
    [Test]
    procedure DovrebbeLeggereITcMod;
    [Test]
    procedure DovrebbeContareUnTcModTroncatoComeTipoNessuno;
    [TestCase('turb senza parametri', 'tcMod turb,missing tcMod turb parms')]
    [TestCase('turb con uno', 'tcMod turb 1,missing tcMod turb in shader')]
    [TestCase('turb con due', 'tcMod turb 1 2,missing tcMod turb in shader')]
    [TestCase('turb con tre', 'tcMod turb 1 2 3,missing tcMod turb in shader')]
    [TestCase('scale senza parametri', 'tcMod scale,missing scale parms')]
    [TestCase('scroll senza parametri', 'tcMod scroll,missing scale scroll parms')]
    [TestCase('stretch senza parametri', 'tcMod stretch,missing stretch parms')]
    [TestCase('stretch con la funzione', 'tcMod stretch sin,missing stretch parms')]
    [TestCase('stretch con la base', 'tcMod stretch sin 1,missing stretch parms')]
    [TestCase('stretch con l ampiezza', 'tcMod stretch sin 1 2,missing stretch parms')]
    [TestCase('stretch con la fase', 'tcMod stretch sin 1 2 3,missing stretch parms')]
    [TestCase('transform senza parametri', 'tcMod transform,missing transform parms')]
    [TestCase('transform con uno', 'tcMod transform 1,missing transform parms')]
    [TestCase('transform con due', 'tcMod transform 1 2,missing transform parms')]
    [TestCase('transform con tre', 'tcMod transform 1 2 3,missing transform parms')]
    [TestCase('transform con quattro', 'tcMod transform 1 2 3 4,missing transform parms')]
    [TestCase('transform con cinque', 'tcMod transform 1 2 3 4 5,missing transform parms')]
    [TestCase('rotate senza parametri', 'tcMod rotate,missing tcMod rotate parms')]
    [TestCase('tipo sconosciuto', 'tcMod wobble 1,unknown tcMod ''wobble''')]
    procedure DovrebbeAvvisareUnTcModIncompleto(const ALine, AMessage: string);
    [TestCase('onda senza funzione', 'rgbGen wave')]
    [TestCase('onda senza base', 'rgbGen wave sin')]
    [TestCase('onda senza ampiezza', 'rgbGen wave sin 1')]
    [TestCase('onda senza fase', 'rgbGen wave sin 1 2')]
    [TestCase('onda senza frequenza', 'rgbGen wave sin 1 2 3')]
    procedure DovrebbeAvvisareUnaOndaIncompleta(const ALine: string);
    [TestCase('senza parentesi aperta', 'rgbGen const 1 2 3,missing parenthesis')]
    [TestCase('senza elemento', 'rgbGen const ( 1 2,missing vector element')]
    [TestCase('senza parentesi chiusa', 'rgbGen const ( 1 2 3,missing parenthesis')]
    procedure DovrebbeAvvisareUnVettoreSbagliato(const ALine, AMessage: string);
    [Test]
    procedure DovrebbeLeggereIVettoriDelTcGen;
    [Test]
    procedure DovrebbeTenereLeCoordinateLetteSeUnVettoreEIncompleto;
    [Test]
    procedure DovrebbeLeggereLeDeformazioni;
    [Test]
    procedure DovrebbeLeggereIlSole;
    [Test]
    procedure DovrebbeLeggereIlCielo;
    [Test]
    procedure DovrebbeLeggereLaNebbiaESaltareIlResto;
    [Test]
    procedure DovrebbeLeggereIFlagDelleSuperfici;
    [Test]
    procedure DovrebbeCalcolareLOrdinamento;
    [Test]
    procedure DovrebbeRifiutareUnoShaderSenzaStageSeNonESkyONebbia;
    [Test]
    procedure DovrebbeSegnareDefaultUnoShaderConUnErrore;
    [Test]
    procedure DovrebbeRifiutareIlNonoStage;
    [Test]
    procedure DovrebbeTrasformareUnTcModDiTroppoInUnErroreDelloShader;
    [Test]
    procedure DovrebbeTogliereLoStageSenzaImmagine;
    [Test]
    procedure DovrebbeNonSeparareUnaGraffaAttaccataAUnaParolaDelloStage;
    [Test]
    procedure DovrebbeTogliereGliStageDetailSeDisattivati;
    [Test]
    procedure DovrebbeFarePartireLAlphaGenDaIdentityVersoSkip;
    [Test]
    procedure DovrebbeDareUnaEccezioneFuoriDalNumeroDeglistage;
    [Test]
    procedure DovrebbeLeggereUnTestoDiDefaultSenzaNome;
    [Test]
    procedure DovrebbeFareUnoShaderDaUnImmagineSenzaTesto;
    [Test]
    procedure DovrebbeNonAggiungereLEstensioneSeCeGia;
    [Test]
    procedure DovrebbeTrovareLoShaderSenzaDistinguereLeMaiuscole;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderContext = class
  public
    [Test]
    procedure DovrebbeConvertireUnFloatInByteComeIlC;
    [Test]
    procedure DovrebbeAvvisareSenzaLogSenzaErrori;
    [Test]
    procedure DovrebbeDareLeOpzioniStandard;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderManager = class
  strict private
    FKit: TQ3ShaderKit;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRegistrareIlTipoShaderConIlSuoNumero;
    [Test]
    procedure DovrebbeLasciareIlNumeroACuiLoSalta;
    [Test]
    procedure DovrebbeAggiungersiAlManagerStandardSenzaCambiareIlResto;
    [Test]
    procedure DovrebbeAvvisareUnoShaderDefinitoDueVolte;
    [Test]
    procedure DovrebbeNonConfondereLeParoleDelTipoConIlNome;
    [Test]
    procedure DovrebbeRileggereUnFileCambiato;
    [Test]
    procedure DovrebbeMettereInDefaultUnoShaderTolto;
    [Test]
    procedure DovrebbeLeggereIFileDiUnaCartellaInOrdine;
  end;

implementation

uses
  System.Math, System.StrUtils, System.Generics.Collections, DelphiDoom.Decl.Factory, DelphiDoom.Decl.StandardTypes,
  DelphiDoom.Decl.FileScanner.Intf, DelphiDoom.Decl.Q3Shader.Context, DelphiDoom.Decl.Q3Shader.Tokenizer,
  DelphiDoom.Decl.Q3Shader.FileScanner, DelphiDoom.Decl.Q3Shader.Compressor, DelphiDoom.Decl.Q3Shader.Registration;

const
  // the single ' of the library is a quote
  Q = '''';

{ TQ3ShaderKit }

constructor TQ3ShaderKit.Create;
begin
  inherited Create;
  FSource := TDeclMemorySource.Create;
  FSourceIntf := FSource;
  FLogObject := TFakeIdLibLog.Create;
  FLog := FLogObject;
end;

destructor TQ3ShaderKit.Destroy;
begin
  FManager := nil;
  FLog := nil;
  FSourceIntf := nil;
  inherited Destroy;
end;

procedure TQ3ShaderKit.Start(const AOptions: TQ3ShaderOptions; const ALoadFolder: Boolean);
begin
  FManager := TDeclFactory.CreateManager(FSource, FLog);
  TQ3ShaderRegistration.RegisterType(FManager.GetRegistry, [], AOptions);
  if ALoadFolder then
    TQ3ShaderRegistration.RegisterFolder(FManager.GetRegistry);
end;

function TQ3ShaderKit.Find(const AName: AnsiString): IDeclQ3Shader;
var
  LDecl: IDecl;
begin
  LDecl := FManager.FindType(DECL_Q3SHADER, AName);
  if not Supports(LDecl, IDeclQ3Shader, Result) then
    Result := nil;
end;

function TQ3ShaderKit.Lines: TStrings;
begin
  Result := FLogObject.Lines;
end;

{ TTestQ3ShaderTokenizer }

procedure TTestQ3ShaderTokenizer.DovrebbeLeggereParoleSeparateDaBlank;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('  uno'#9'due   tre');
  try
    Assert.AreEqual('uno', string(LTokenizer.ParseExt(True)));
    Assert.AreEqual('due', string(LTokenizer.ParseExt(True)));
    Assert.AreEqual('tre', string(LTokenizer.ParseExt(True)));
    Assert.AreEqual('', string(LTokenizer.ParseExt(True)));
    Assert.IsTrue(LTokenizer.Ended);
    Assert.AreEqual('', string(LTokenizer.ParseExt(True)));
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeDareVuotoAFineRigaSenzaPermettereAndareACapo;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('uno'#10'due');
  try
    Assert.AreEqual('uno', string(LTokenizer.ParseExt(False)));
    Assert.AreEqual('', string(LTokenizer.ParseExt(False)));
    Assert.IsFalse(LTokenizer.Ended);
    // the new line was consumed: the next word is on the next line
    Assert.AreEqual('due', string(LTokenizer.ParseExt(False)));
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeSaltareLaRigaSeAndareACapoEPermesso;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('uno'#13#10#13#10'due');
  try
    Assert.AreEqual('uno', string(LTokenizer.ParseExt(True)));
    Assert.AreEqual('due', string(LTokenizer.ParseExt(True)));
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeSaltareICommentiDiRigaEDiBlocco;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('a // x y'#10'/* b'#10'c */ d /* aperto');
  try
    Assert.AreEqual('a', string(LTokenizer.ParseExt(True)));
    Assert.AreEqual('d', string(LTokenizer.ParseExt(True)));
    Assert.AreEqual('', string(LTokenizer.ParseExt(True)));
    Assert.IsTrue(LTokenizer.Ended);
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeMantenereIBlankTraVirgolette;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('"due parole" fine');
  try
    Assert.AreEqual('due parole', string(LTokenizer.ParseExt(True)));
    Assert.AreEqual('fine', string(LTokenizer.ParseExt(True)));
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeTerminareSeLeVirgoletteNonSiChiudono;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('"senza fine');
  try
    Assert.AreEqual('senza fine', string(LTokenizer.ParseExt(True)));
    Assert.IsTrue(LTokenizer.Ended);
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeScartareUnaParolaDiMilleventiquattroCaratteri;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create(AnsiString(StringOfChar('x', 1024)) + ' ' +
    AnsiString(StringOfChar('y', 1023)) + ' fine');
  try
    Assert.AreEqual('', string(LTokenizer.ParseExt(True)));
    Assert.AreEqual<Integer>(1023, Length(LTokenizer.ParseExt(True)));
    Assert.AreEqual('fine', string(LTokenizer.ParseExt(True)));
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeTrattareIByteAltiComeBlank;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  // a char is signed: 200 is negative, so it is a blank and it ends a word
  LTokenizer := TQ3ShaderTokenizer.Create('ab' + AnsiChar(#200) + 'cd');
  try
    Assert.AreEqual('ab', string(LTokenizer.ParseExt(True)));
    Assert.AreEqual('cd', string(LTokenizer.ParseExt(True)));
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeNonSepararareUnaGraffaAttaccataAUnaParola;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('nome{ }');
  try
    Assert.AreEqual('nome{', string(LTokenizer.ParseExt(True)));
    Assert.AreEqual('}', string(LTokenizer.ParseExt(True)));
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeSaltareIlRestoDellaRiga;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('a b c'#10'd');
  try
    Assert.AreEqual('a', string(LTokenizer.ParseExt(True)));
    LTokenizer.SkipRestOfLine;
    Assert.AreEqual('d', string(LTokenizer.ParseExt(True)));
    LTokenizer.SkipRestOfLine;
    Assert.IsTrue(LTokenizer.Ended);
    // at the end it stays there
    LTokenizer.SkipRestOfLine;
    Assert.AreEqual('', string(LTokenizer.ParseExt(True)));
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeSaltareUnaSezioneConGraffeAnnidate;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('{ a { b } c } dopo');
  try
    LTokenizer.SkipBracedSection;
    Assert.AreEqual('dopo', string(LTokenizer.ParseExt(True)));
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeSaltareUnaSolaParolaSeNonCEUnaGraffa;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('uno due tre');
  try
    LTokenizer.SkipBracedSection;
    Assert.AreEqual('due', string(LTokenizer.ParseExt(True)));
  finally
    LTokenizer.Free;
  end;
end;

procedure TTestQ3ShaderTokenizer.DovrebbeFermarsiAllaFineDelTestoNellaSezioneAperta;
var
  LTokenizer: TQ3ShaderTokenizer;
begin
  LTokenizer := TQ3ShaderTokenizer.Create('{ a { b }');
  try
    LTokenizer.SkipBracedSection;
    Assert.IsTrue(LTokenizer.Ended);
  finally
    LTokenizer.Free;
  end;
end;

{ TTestQ3ShaderCompressor }

procedure TTestQ3ShaderCompressor.DovrebbeRiunireIBlankELeRigheInUnoSolo;
var
  LMap: TArray<Integer>;
begin
  Assert.AreEqual('a b', string(TQ3ShaderCompressor.Compress('a  '#9' b', LMap)));
  Assert.AreEqual('a'#10'b', string(TQ3ShaderCompressor.Compress('a'#13#10' '#9#10'  b', LMap)));
  // a blank or a new line at the end is not kept
  Assert.AreEqual('a', string(TQ3ShaderCompressor.Compress('a '#10' ', LMap)));
end;

procedure TTestQ3ShaderCompressor.DovrebbeTogliereICommenti;
var
  LMap: TArray<Integer>;
begin
  Assert.AreEqual('a'#10'b', string(TQ3ShaderCompressor.Compress('a // c d'#10'b', LMap)));
  Assert.AreEqual('a b', string(TQ3ShaderCompressor.Compress('a /* c'#10'd */ b', LMap)));
  Assert.AreEqual('a', string(TQ3ShaderCompressor.Compress('a /* mai chiuso', LMap)));
end;

procedure TTestQ3ShaderCompressor.DovrebbeUnireLeParoleSeUnCommentoLeSepara;
var
  LMap: TArray<Integer>;
begin
  Assert.AreEqual('ab', string(TQ3ShaderCompressor.Compress('a/* x */b', LMap)));
end;

procedure TTestQ3ShaderCompressor.DovrebbeTagliareUnaParolaAUnCommentoAttaccato;
var
  LMap: TArray<Integer>;
begin
  // COM_ParseExt reads "a//b" as one word; COM_Compress cuts it, and the scan sees the cut text
  Assert.AreEqual('a', string(TQ3ShaderCompressor.Compress('a//b', LMap)));
end;

procedure TTestQ3ShaderCompressor.DovrebbeCopiareLeVirgoletteSenzaToccarle;
var
  LMap: TArray<Integer>;
begin
  Assert.AreEqual('"a  //b'#10'c" d', string(TQ3ShaderCompressor.Compress('"a  //b'#10'c"   d', LMap)));
  // an open quote is copied to the end
  Assert.AreEqual('x "a  b', string(TQ3ShaderCompressor.Compress('x  "a  b', LMap)));
end;

procedure TTestQ3ShaderCompressor.DovrebbeTrattareUnCRSoloComeAndareACapo;
var
  LMap: TArray<Integer>;
begin
  Assert.AreEqual('a'#10'b', string(TQ3ShaderCompressor.Compress('a'#13'b', LMap)));
end;

procedure TTestQ3ShaderCompressor.DovrebbeFermarsiAlPrimoNul;
var
  LMap: TArray<Integer>;
begin
  Assert.AreEqual('a', string(TQ3ShaderCompressor.Compress('a'#0'b', LMap)));
end;

procedure TTestQ3ShaderCompressor.DovrebbeDareLaPosizioneNelTestoDiOgniCarattere;
var
  LMap: TArray<Integer>;
begin
  Assert.AreEqual('ab', string(TQ3ShaderCompressor.Compress('a/*x*/b', LMap)));
  Assert.AreEqual<Integer>(2, Length(LMap));
  Assert.AreEqual(1, LMap[0]);
  Assert.AreEqual(7, LMap[1]);
  // the blank that is kept belongs to the word after it
  TQ3ShaderCompressor.Compress('a   b', LMap);
  Assert.AreEqual(1, LMap[0]);
  Assert.AreEqual(5, LMap[1]);
  Assert.AreEqual(5, LMap[2]);
end;

procedure TTestQ3ShaderCompressor.DovrebbeDareVuotoPerUnTestoDiSoliCommenti;
var
  LMap: TArray<Integer>;
begin
  Assert.AreEqual('', string(TQ3ShaderCompressor.Compress('// niente'#10'/* nulla */', LMap)));
  Assert.AreEqual<Integer>(0, Length(LMap));
  Assert.AreEqual('', string(TQ3ShaderCompressor.Compress('', LMap)));
end;

{ TTestQ3ShaderFileScanner }

procedure TTestQ3ShaderFileScanner.DovrebbeTrovareNomeOffsetELineaDiOgniShader;
var
  LBlocks: TArray<TDeclScannedBlock>;
  LNumLines: Integer;
  LText: AnsiString;
begin
  LText := 'uno'#10'{'#10'  { map a }'#10'}'#10'due { }'#10;
  LBlocks := TQ3ShaderFileScanner.Scan(LText, 30, LNumLines);
  Assert.AreEqual<Integer>(2, Length(LBlocks));
  Assert.AreEqual('uno', string(LBlocks[0].Name));
  Assert.AreEqual(30, LBlocks[0].TypeId);
  Assert.AreEqual(0, LBlocks[0].Offset);
  Assert.AreEqual(1, LBlocks[0].Line);
  Assert.AreEqual('uno'#10'{'#10'  { map a }'#10'}', string(Copy(LText, LBlocks[0].Offset + 1, LBlocks[0].Length)));
  Assert.AreEqual('due', string(LBlocks[1].Name));
  // the text of a declaration starts where the one before ended, so it begins with the new line
  Assert.AreEqual(4, LBlocks[1].Line);
  Assert.AreEqual(#10'due { }', string(Copy(LText, LBlocks[1].Offset + 1, LBlocks[1].Length)));
  Assert.AreEqual(6, LNumLines);
  // the declaration holds the compressed text; the offset and the length are those of the file
  Assert.AreEqual('uno'#10'{'#10'{ map a }'#10'}', string(LBlocks[0].Text));
  Assert.AreEqual(#10'due { }', string(LBlocks[1].Text));
end;

procedure TTestQ3ShaderFileScanner.DovrebbeLeggereUnFileConIRitorniACapoDelMacintosh;
var
  LBlocks: TArray<TDeclScannedBlock>;
  LNumLines: Integer;
begin
  // a lone CR is a new line for COM_Compress: "qer_editorimage" ends its line there
  LBlocks := TQ3ShaderFileScanner.Scan('uno'#13'{ }'#13'due'#13'{ }', 30, LNumLines);
  Assert.AreEqual<Integer>(2, Length(LBlocks));
  Assert.AreEqual('uno'#10'{ }', string(LBlocks[0].Text));
  Assert.AreEqual('uno'#13'{ }', string(Copy('uno'#13'{ }'#13'due'#13'{ }', LBlocks[0].Offset + 1, LBlocks[0].Length)));
  Assert.AreEqual(#10'due'#10'{ }', string(LBlocks[1].Text));
end;

procedure TTestQ3ShaderFileScanner.DovrebbeNonTrovareNullaInUnFileVuoto;
var
  LNumLines: Integer;
begin
  Assert.AreEqual<Integer>(0, Length(TQ3ShaderFileScanner.Scan('', 30, LNumLines)));
  Assert.AreEqual(1, LNumLines);
  Assert.AreEqual<Integer>(0, Length(TQ3ShaderFileScanner.Scan('// solo un commento'#10, 30, LNumLines)));
end;

procedure TTestQ3ShaderFileScanner.DovrebbeIncludereICommentiSopraLaDefinizione;
var
  LBlocks: TArray<TDeclScannedBlock>;
  LNumLines: Integer;
begin
  LBlocks := TQ3ShaderFileScanner.Scan('// sopra'#10'nome'#10'{ }', 30, LNumLines);
  Assert.AreEqual<Integer>(1, Length(LBlocks));
  Assert.AreEqual(0, LBlocks[0].Offset);
  Assert.AreEqual('nome', string(LBlocks[0].Name));
end;

procedure TTestQ3ShaderFileScanner.DovrebbeFinireAFineTestoConUnaSezioneAperta;
var
  LBlocks: TArray<TDeclScannedBlock>;
  LNumLines: Integer;
begin
  LBlocks := TQ3ShaderFileScanner.Scan('nome'#10'{'#10'{ map a }', 30, LNumLines);
  Assert.AreEqual<Integer>(1, Length(LBlocks));
  Assert.AreEqual<Integer>(Length('nome'#10'{'#10'{ map a }'), LBlocks[0].Length);
end;

procedure TTestQ3ShaderFileScanner.DovrebbeFermarsiConUnaParolaVuotaTraVirgolette;
var
  LNumLines: Integer;
begin
  // an empty word is the end of the file, also when it is a pair of quotes
  Assert.AreEqual<Integer>(1, Length(TQ3ShaderFileScanner.Scan('uno { } "" due { }', 30, LNumLines)));
end;

{ TTestQ3ShaderKeywords }

procedure TTestQ3ShaderKeywords.Setup;
begin
  FKit := TQ3ShaderKit.Create;
end;

procedure TTestQ3ShaderKeywords.TearDown;
begin
  FKit.Free;
end;

function TTestQ3ShaderKeywords.Shader(const ABody: AnsiString): IDeclQ3Shader;
begin
  FKit.Source.Add('scripts/t.shader', 'textures/t'#10'{'#10 + ABody + #10'}'#10);
  FKit.Start(TQ3ShaderOptions.Standard);
  Result := FKit.Find('textures/t');
  Assert.IsNotNull(Result);
end;

function TTestQ3ShaderKeywords.Log: string;
begin
  Result := FKit.Lines.Text;
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereUnoStageConLeImmagini;
var
  LShader: IDeclQ3Shader;
begin
  LShader := Shader('{ map textures/a.tga } { clampmap textures/b.tga }');
  Assert.AreEqual(2, LShader.GetStageCount);
  Assert.AreEqual('textures/a.tga', string(LShader.GetStage(0).Bundle.ImageNames[0]));
  Assert.AreEqual('textures/b.tga', string(LShader.GetStage(1).Bundle.ImageNames[0]));
  Assert.IsTrue(LShader.IsExplicitlyDefined);
  Assert.IsFalse(LShader.IsDefaultShader);
  Assert.AreEqual(Ord(tgTexture), Ord(LShader.GetStage(0).Bundle.TcGen));
  Assert.AreEqual(Ord(SS_OPAQUE), Integer(Round(LShader.GetData.Sort)));
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereAnimMapFinoAOttoImmagini;
var
  LBundle: TQ3TextureBundle;
begin
  // animMap reads the rest of the line
  LBundle := Shader('{ animMap 2.5 a b c d e f g h i j'#10'}').GetStage(0).Bundle;
  Assert.AreEqual(8, LBundle.NumImageAnimations);
  Assert.AreEqual('h', string(LBundle.ImageNames[7]));
  Assert.AreEqual(2.5, LBundle.ImageAnimationSpeed, 0.0001);
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereVideoMap;
var
  LBundle: TQ3TextureBundle;
begin
  LBundle := Shader('{ videoMap video/film.roq }').GetStage(0).Bundle;
  Assert.IsTrue(LBundle.IsVideoMap);
  Assert.AreEqual('video/film.roq', string(LBundle.VideoMapName));
  Assert.AreEqual('$scratch', string(LBundle.ImageNames[0]));
end;

procedure TTestQ3ShaderKeywords.DovrebbeUsareIlLightmapENomiDelleImmaginiDelRenderer;
var
  LShader: IDeclQ3Shader;
begin
  LShader := Shader('{ map $lightmap } { map $whiteimage blendfunc filter }');
  Assert.IsTrue(LShader.GetStage(0).Bundle.IsLightmap);
  Assert.AreEqual(Ord(tgLightmap), Ord(LShader.GetStage(0).Bundle.TcGen));
  Assert.AreEqual('$whiteimage', string(LShader.GetStage(1).Bundle.ImageNames[0]));
  Assert.IsFalse(LShader.GetStage(1).Bundle.IsLightmap);
end;

procedure TTestQ3ShaderKeywords.DovrebbeCalcolareIBitDiStatoDiBlendEDepth;
var
  LStage: TQ3ShaderStage;
begin
  LStage := Shader('{ map a blendfunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA alphaFunc GE128 depthfunc equal }').GetStage(0);
  Assert.AreEqual(Cardinal(GLS_SRCBLEND_SRC_ALPHA or GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA or GLS_ATEST_GE_80 or
    GLS_DEPTHFUNC_EQUAL), LStage.StateBits);
  Assert.AreEqual(Ord(acModulateAlpha), Ord(LStage.AdjustColorsForFog));
end;

procedure TTestQ3ShaderKeywords.DovrebbeDisattivareIlBlendUnoZero;
var
  LStage: TQ3ShaderStage;
begin
  LStage := Shader('{ map a blendfunc GL_ONE GL_ZERO }').GetStage(0);
  Assert.AreEqual(Cardinal(GLS_DEPTHMASK_TRUE), LStage.StateBits);
  Assert.AreEqual(Ord(cgIdentityLighting), Ord(LStage.RgbGen));
end;

procedure TTestQ3ShaderKeywords.DovrebbeScegliereIlColoreDiDefaultDallaBlend;
var
  LShader: IDeclQ3Shader;
begin
  LShader := Shader('{ map a blendfunc filter } { map b blendfunc add } { map c blendfunc GL_DST_ALPHA GL_ZERO }');
  Assert.AreEqual(Ord(cgIdentity), Ord(LShader.GetStage(0).RgbGen));
  Assert.AreEqual(Ord(cgIdentityLighting), Ord(LShader.GetStage(1).RgbGen));
  Assert.AreEqual(Ord(cgIdentity), Ord(LShader.GetStage(2).RgbGen));
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereIlColoreCostanteInByte;
var
  LStage: TQ3ShaderStage;
begin
  LStage := Shader('{ map a rgbGen const ( 1 0.5 2 ) alphaGen const 0.5 }').GetStage(0);
  Assert.AreEqual(255, Integer(LStage.ConstantColor[0]));
  Assert.AreEqual(127, Integer(LStage.ConstantColor[1]));
  // 255 * 2 = 510 and the low byte is 254
  Assert.AreEqual(254, Integer(LStage.ConstantColor[2]));
  Assert.AreEqual(127, Integer(LStage.ConstantColor[3]));
  Assert.AreEqual(Ord(cgConst), Ord(LStage.RgbGen));
  Assert.AreEqual(Ord(agConst), Ord(LStage.AlphaGen));
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereUnaOnda;
var
  LStage: TQ3ShaderStage;
begin
  LStage := Shader('{ map a rgbGen wave square 1 2 3 4 }').GetStage(0);
  Assert.AreEqual(Ord(gfSquare), Ord(LStage.RgbWave.Func));
  Assert.AreEqual(1, LStage.RgbWave.Base, 0.0001);
  Assert.AreEqual(2, LStage.RgbWave.Amplitude, 0.0001);
  Assert.AreEqual(3, LStage.RgbWave.Phase, 0.0001);
  Assert.AreEqual(4, LStage.RgbWave.Frequency, 0.0001);
  Assert.AreEqual(Ord(cgWaveform), Ord(LStage.RgbGen));
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereITcMod;
var
  LBundle: TQ3TextureBundle;
begin
  // a tcMod is a whole line
  LBundle := Shader('{ map a'#10'tcMod scroll 1 2'#10'tcMod scale 3 4'#10'tcMod transform 1 2 3 4 5 6'#10 +
    'tcMod rotate 7'#10'}').GetStage(0).Bundle;
  Assert.AreEqual(4, LBundle.NumTexMods);
  Assert.AreEqual(Ord(tmScroll), Ord(LBundle.TexMods[0].ModType));
  Assert.AreEqual(2, LBundle.TexMods[0].Scroll[1], 0.0001);
  Assert.AreEqual(Ord(tmScale), Ord(LBundle.TexMods[1].ModType));
  Assert.AreEqual(4, LBundle.TexMods[1].Scale[1], 0.0001);
  Assert.AreEqual(Ord(tmTransform), Ord(LBundle.TexMods[2].ModType));
  Assert.AreEqual(3, LBundle.TexMods[2].Matrix[1, 0], 0.0001);
  Assert.AreEqual(6, LBundle.TexMods[2].Translate[1], 0.0001);
  Assert.AreEqual(Ord(tmRotate), Ord(LBundle.TexMods[3].ModType));
  Assert.AreEqual(7, LBundle.TexMods[3].RotateSpeed, 0.0001);
end;

procedure TTestQ3ShaderKeywords.DovrebbeContareUnTcModTroncatoComeTipoNessuno;
var
  LBundle: TQ3TextureBundle;
begin
  LBundle := Shader('{ map a'#10'tcMod scale 3'#10'}').GetStage(0).Bundle;
  Assert.AreEqual(1, LBundle.NumTexMods);
  Assert.AreEqual(Ord(tmNone), Ord(LBundle.TexMods[0].ModType));
  Assert.AreEqual(3, LBundle.TexMods[0].Scale[0], 0.0001);
  Assert.IsTrue(ContainsText(Log, 'missing scale parms'));
end;

procedure TTestQ3ShaderKeywords.DovrebbeAvvisareUnTcModIncompleto(const ALine, AMessage: string);
begin
  Shader(AnsiString('{ map a'#10 + ALine + #10'}'));
  Assert.IsTrue(ContainsText(Log, AMessage), Log);
end;

procedure TTestQ3ShaderKeywords.DovrebbeAvvisareUnaOndaIncompleta(const ALine: string);
begin
  Shader(AnsiString('{ map a'#10 + ALine + #10'}'));
  Assert.IsTrue(ContainsText(Log, 'missing waveform parm'), Log);
end;

procedure TTestQ3ShaderKeywords.DovrebbeAvvisareUnVettoreSbagliato(const ALine, AMessage: string);
begin
  Shader(AnsiString('{ map a'#10 + ALine + #10'}'));
  Assert.IsTrue(ContainsText(Log, AMessage), Log);
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereIVettoriDelTcGen;
var
  LBundle: TQ3TextureBundle;
begin
  LBundle := Shader('{ map a tcGen vector ( 1 2 3 ) ( 4 5 6 ) }').GetStage(0).Bundle;
  Assert.AreEqual(Ord(tgVector), Ord(LBundle.TcGen));
  Assert.AreEqual(2, LBundle.TcGenVectors[0, 1], 0.0001);
  Assert.AreEqual(6, LBundle.TcGenVectors[1, 2], 0.0001);
end;

procedure TTestQ3ShaderKeywords.DovrebbeTenereLeCoordinateLetteSeUnVettoreEIncompleto;
var
  LBundle: TQ3TextureBundle;
begin
  LBundle := Shader('{ map a tcGen vector ( 1 2 ) }').GetStage(0).Bundle;
  Assert.AreEqual(1, LBundle.TcGenVectors[0, 0], 0.0001);
  Assert.AreEqual(2, LBundle.TcGenVectors[0, 1], 0.0001);
  Assert.IsTrue(ContainsText(Log, 'missing parenthesis'));
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereLeDeformazioni;
var
  LData: TQ3ShaderData;
begin
  LData := Shader('deformVertexes wave 100 sin 1 2 3 4 deformVertexes bulge 5 6 7 deformVertexes text4 { map a }').GetData;
  Assert.AreEqual(3, LData.NumDeforms);
  Assert.AreEqual(Ord(dfWave), Ord(LData.Deforms[0].Deformation));
  Assert.AreEqual(0.01, LData.Deforms[0].DeformationSpread, 0.00001);
  Assert.AreEqual(4, LData.Deforms[0].DeformationWave.Frequency, 0.0001);
  Assert.AreEqual(Ord(dfBulge), Ord(LData.Deforms[1].Deformation));
  Assert.AreEqual(7, LData.Deforms[1].BulgeSpeed, 0.0001);
  Assert.AreEqual(Ord(dfText4), Ord(LData.Deforms[2].Deformation));
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereIlSole;
var
  LData: TQ3ShaderData;
begin
  LData := Shader('q3map_sun 0 0 5 100 0 90 { map a }').GetData;
  Assert.IsTrue(LData.HasSun);
  Assert.AreEqual(0, LData.SunLight[0], 0.0001);
  Assert.AreEqual(100, LData.SunLight[2], 0.001);
  Assert.AreEqual(0, LData.SunDirection[0], 0.0001);
  Assert.AreEqual(1, LData.SunDirection[2], 0.0001);
  Assert.IsFalse(Shader('{ map a }').GetData.HasSun);
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereIlCielo;
var
  LData: TQ3ShaderData;
begin
  LData := Shader('skyParms env/sky 0 - ').GetData;
  Assert.IsTrue(LData.IsSky);
  Assert.AreEqual(512, LData.Sky.CloudHeight, 0.0001);
  Assert.AreEqual('env/sky_rt.tga', string(LData.Sky.OuterBox[0]));
  Assert.AreEqual('env/sky_dn.tga', string(LData.Sky.OuterBox[5]));
  Assert.AreEqual('', string(LData.Sky.InnerBox[0]));
  // a sky without stage ends as SS_FOG: FinishShader sets it when there are no passes
  Assert.AreEqual(Ord(SS_FOG), Integer(Round(LData.Sort)));
  Assert.IsTrue(LData.ExplicitlyDefined);
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereLaNebbiaESaltareIlResto;
var
  LData: TQ3ShaderData;
begin
  LData := Shader('surfaceparm fog fogParms ( 0.5 0.25 1 ) 300 0 0 1'#10'cull back').GetData;
  Assert.AreEqual(0.25, LData.FogParms.Color[1], 0.0001);
  Assert.AreEqual(300, LData.FogParms.DepthForOpaque, 0.0001);
  Assert.AreEqual(Ord(ctBackSided), Ord(LData.CullType));
  Assert.AreEqual(Ord(SS_FOG), Integer(Round(LData.Sort)));
  Assert.AreEqual(Ord(fpLE), Ord(LData.FogPass));
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereIFlagDelleSuperfici;
var
  LData: TQ3ShaderData;
begin
  LData := Shader('surfaceparm water surfaceparm nodraw surfaceparm nodrop surfaceparm unknown { map a }').GetData;
  Assert.AreEqual(CONTENTS_WATER or CONTENTS_NODROP, LData.ContentFlags);
  Assert.AreEqual(SURF_NODRAW, LData.SurfaceFlags);
end;

procedure TTestQ3ShaderKeywords.DovrebbeCalcolareLOrdinamento;
begin
  Assert.AreEqual(Ord(SS_SEE_THROUGH), Integer(Round(Shader('{ map a blendfunc blend depthwrite } { map b blendfunc add }')
    .GetData.Sort)));
  FKit.Free;
  FKit := TQ3ShaderKit.Create;
  Assert.AreEqual(Ord(SS_BLEND0), Integer(Round(Shader('{ map a blendfunc blend } { map b blendfunc add }').GetData.Sort)));
  FKit.Free;
  FKit := TQ3ShaderKit.Create;
  Assert.AreEqual(Ord(SS_DECAL), Integer(Round(Shader('polygonOffset { map a }').GetData.Sort)));
  FKit.Free;
  FKit := TQ3ShaderKit.Create;
  Assert.AreEqual(7.5, Shader('sort 7.5 { map a }').GetData.Sort, 0.0001);
end;

procedure TTestQ3ShaderKeywords.DovrebbeRifiutareUnoShaderSenzaStageSeNonESkyONebbia;
var
  LShader: IDeclQ3Shader;
begin
  LShader := Shader('surfaceparm nodraw');
  Assert.IsTrue(LShader.IsDefaultShader);
  Assert.IsFalse(LShader.IsExplicitlyDefined);
  Assert.AreEqual(0, LShader.GetStageCount);
  Assert.AreEqual(Ord(SS_FOG), Integer(Round(LShader.GetData.Sort)));
end;

procedure TTestQ3ShaderKeywords.DovrebbeSegnareDefaultUnoShaderConUnErrore;
var
  LShader: IDeclQ3Shader;
begin
  LShader := Shader('bogus { map a }');
  Assert.IsTrue(LShader.IsDefaultShader);
  Assert.IsTrue(ContainsText(Log, 'unknown general shader parameter ''bogus'' in ''textures/t'''));
end;

procedure TTestQ3ShaderKeywords.DovrebbeRifiutareIlNonoStage;
var
  LShader: IDeclQ3Shader;
  LBody: AnsiString;
  LIndex: Integer;
begin
  LBody := '';
  for LIndex := 1 to 9 do
    LBody := LBody + '{ map a } ';
  LShader := Shader(LBody);
  Assert.IsTrue(LShader.IsDefaultShader);
  Assert.IsTrue(ContainsText(Log, 'too many stages in shader ''textures/t'''));
  Assert.AreEqual(Q3_MAX_SHADER_STAGES, LShader.GetStageCount);
end;

procedure TTestQ3ShaderKeywords.DovrebbeTrasformareUnTcModDiTroppoInUnErroreDelloShader;
var
  LShader: IDeclQ3Shader;
begin
  LShader := Shader('{ map a'#10'tcMod rotate 1'#10'tcMod rotate 1'#10'tcMod rotate 1'#10'tcMod rotate 1'#10 +
    'tcMod rotate 1'#10'}');
  Assert.IsTrue(LShader.IsDefaultShader);
  Assert.IsTrue(ContainsText(Log, 'ERROR: too many tcMod stages in shader ''textures/t'''));
  // the original drops the frame before FinishShader: no passes were counted
  Assert.AreEqual(0, LShader.GetStageCount);
end;

procedure TTestQ3ShaderKeywords.DovrebbeTogliereLoStageSenzaImmagine;
var
  LShader: IDeclQ3Shader;
begin
  LShader := Shader('{ rgbGen identity } { map b }');
  Assert.IsTrue(ContainsText(Log, 'Shader textures/t has a stage with no image'));
  // the stage is switched off and counted: the passes end at the first inactive stage after it
  Assert.AreEqual(2, LShader.GetStageCount);
  Assert.IsFalse(LShader.GetStage(0).Active);
  Assert.IsTrue(LShader.GetStage(1).Active);
end;

procedure TTestQ3ShaderKeywords.DovrebbeNonSeparareUnaGraffaAttaccataAUnaParolaDelloStage;
begin
  // a "{" glued to a word is part of the word: the stage is not closed and the shader has no end
  Assert.IsTrue(Shader('{ map a blendfunc{ add }').IsDefaultShader);
end;

procedure TTestQ3ShaderKeywords.DovrebbeTogliereGliStageDetailSeDisattivati;
var
  LOptions: TQ3ShaderOptions;
  LShader: IDeclQ3Shader;
begin
  FKit.Source.Add('scripts/t.shader', 'textures/t { { map a detail } { map b blendfunc filter } { map c } }');
  LOptions := TQ3ShaderOptions.Standard;
  FKit.Start(LOptions);
  Assert.AreEqual(3, FKit.Find('textures/t').GetStageCount);
  Assert.IsTrue(FKit.Find('textures/t').GetStage(0).IsDetail);
  FKit.Free;
  FKit := TQ3ShaderKit.Create;
  FKit.Source.Add('scripts/t.shader', 'textures/t { { map a detail } { map b blendfunc filter } { map c } }');
  LOptions.DetailTextures := False;
  FKit.Start(LOptions);
  LShader := FKit.Find('textures/t');
  // the stages move down by one and the one after the detail stage is cleared (the original does just that)
  Assert.AreEqual('b', string(LShader.GetStage(0).Bundle.ImageNames[0]));
  Assert.IsFalse(LShader.GetData.Stages[1].Active);
  Assert.AreEqual(1, LShader.GetStageCount);
end;

procedure TTestQ3ShaderKeywords.DovrebbeFarePartireLAlphaGenDaIdentityVersoSkip;
var
  LShader: IDeclQ3Shader;
begin
  // the original compares alphaGen with CGEN_IDENTITY, which is AGEN_ENTITY: only an entity alpha is skipped
  LShader := Shader('{ map a rgbGen identity alphaGen entity } { map b rgbGen identity }');
  Assert.AreEqual(Ord(agSkip), Ord(LShader.GetStage(0).AlphaGen));
  Assert.AreEqual(Ord(agIdentity), Ord(LShader.GetStage(1).AlphaGen));
end;

procedure TTestQ3ShaderKeywords.DovrebbeDareUnaEccezioneFuoriDalNumeroDeglistage;
var
  LShader: IDeclQ3Shader;
  LStage: TQ3ShaderStage;
  LRaised: Integer;
begin
  LShader := Shader('{ map a }');
  LRaised := 0;
  try
    LStage := LShader.GetStage(1);
  except
    on ERangeError do
      Inc(LRaised);
  end;
  try
    LStage := LShader.GetStage(-1);
  except
    on ERangeError do
      Inc(LRaised);
  end;
  Assert.AreEqual(2, LRaised);
  // a stage that exists is read
  LStage := LShader.GetStage(0);
  Assert.IsTrue(LStage.Active);
end;

procedure TTestQ3ShaderKeywords.DovrebbeLeggereUnTestoDiDefaultSenzaNome;
var
  LDecl: IDecl;
  LShader: IDeclQ3Shader;
begin
  FKit.Start(TQ3ShaderOptions.Standard, False);
  LDecl := FKit.Manager.FindType(DECL_Q3SHADER, 'textures/x');
  Assert.IsTrue(Supports(LDecl, IDeclQ3Shader, LShader));
  // an image of that name is the shader; the default definition "{ }" is the empty one
  Assert.AreEqual(1, LShader.GetStageCount);
  LDecl.MakeDefault;
  Assert.IsTrue(LShader.IsDefaultShader);
  Assert.AreEqual(0, LShader.GetStageCount);
  Assert.IsTrue(LShader.GetData.DefaultShader);
end;

procedure TTestQ3ShaderKeywords.DovrebbeFareUnoShaderDaUnImmagineSenzaTesto;
var
  LShader: IDeclQ3Shader;
  LStage: TQ3ShaderStage;
begin
  FKit.Start(TQ3ShaderOptions.Standard, False);
  LShader := FKit.Find('gfx/pic');
  LStage := LShader.GetStage(0);
  Assert.AreEqual('gfx/pic.tga', string(LStage.Bundle.ImageNames[0]));
  Assert.AreEqual(Ord(cgLightingDiffuse), Ord(LStage.RgbGen));
  Assert.AreEqual(Cardinal(GLS_DEFAULT), LStage.StateBits);
  Assert.IsFalse(LShader.IsExplicitlyDefined);
  Assert.IsFalse(LShader.IsDefaultShader);
  Assert.AreEqual(Ord(SS_OPAQUE), Integer(Round(LShader.GetData.Sort)));
end;

procedure TTestQ3ShaderKeywords.DovrebbeNonAggiungereLEstensioneSeCeGia;
begin
  FKit.Start(TQ3ShaderOptions.Standard, False);
  // the manager drops the extension of the name (as COM_StripExtension does): the image is always .tga
  Assert.AreEqual('gfx/pic.tga', string(FKit.Find('gfx/pic.jpg').GetStage(0).Bundle.ImageNames[0]));
  Assert.AreEqual('gfx/pic.tga', string(FKit.Find('GFX\Pic').GetStage(0).Bundle.ImageNames[0]));
end;

procedure TTestQ3ShaderKeywords.DovrebbeTrovareLoShaderSenzaDistinguereLeMaiuscole;
begin
  Shader('{ map a }');
  Assert.AreEqual(1, FKit.Find('TEXTURES/T').GetStageCount);
end;

{ TTestQ3ShaderContext }

procedure TTestQ3ShaderContext.DovrebbeConvertireUnFloatInByteComeIlC;
begin
  Assert.AreEqual(127, Integer(TQ3ShaderContext.FloatToByte(127.9)));
  Assert.AreEqual(254, Integer(TQ3ShaderContext.FloatToByte(510)));
  Assert.AreEqual(255, Integer(TQ3ShaderContext.FloatToByte(-1)));
  // out of the range of an int, and not a number: the integer indefinite, whose low byte is zero
  Assert.AreEqual(0, Integer(TQ3ShaderContext.FloatToByte(1E20)));
  Assert.AreEqual(0, Integer(TQ3ShaderContext.FloatToByte(-1E20)));
  Assert.AreEqual(0, Integer(TQ3ShaderContext.FloatToByte(Double(NaN))));
end;

procedure TTestQ3ShaderContext.DovrebbeAvvisareSenzaLogSenzaErrori;
var
  LContext: TQ3ShaderContext;
begin
  LContext := TQ3ShaderContext.Create('nome', nil, TQ3ShaderOptions.Standard);
  try
    LContext.Warn('niente %s', ['log']);
    Assert.AreEqual('nome', string(LContext.Data.Name));
    Assert.IsTrue(LContext.Options.DetailTextures);
  finally
    LContext.Free;
  end;
end;

procedure TTestQ3ShaderContext.DovrebbeDareLeOpzioniStandard;
begin
  Assert.IsTrue(TQ3ShaderOptions.Standard.DetailTextures);
end;

{ TTestQ3ShaderManager }

procedure TTestQ3ShaderManager.Setup;
begin
  FKit := TQ3ShaderKit.Create;
end;

procedure TTestQ3ShaderManager.TearDown;
begin
  FKit.Free;
end;

procedure TTestQ3ShaderManager.DovrebbeRegistrareIlTipoShaderConIlSuoNumero;
begin
  FKit.Start(TQ3ShaderOptions.Standard, False);
  Assert.AreEqual(DECL_Q3SHADER, FKit.Manager.GetRegistry.GetDeclTypeFromName('shader'));
  Assert.AreEqual('shader', string(FKit.Manager.GetRegistry.GetDeclNameFromType(DECL_Q3SHADER)));
end;

procedure TTestQ3ShaderManager.DovrebbeLasciareIlNumeroACuiLoSalta;
var
  LManager: IDeclManager;
begin
  LManager := TDeclFactory.CreateManager(FKit.Source, nil);
  TQ3ShaderRegistration.RegisterType(LManager.GetRegistry, [DECL_Q3SHADER]);
  Assert.AreEqual(DECL_MAX_TYPES, LManager.GetRegistry.GetDeclTypeFromName('shader'));
end;

procedure TTestQ3ShaderManager.DovrebbeAggiungersiAlManagerStandardSenzaCambiareIlResto;
var
  LManager: IDeclManager;
begin
  // the standard manager is the one of Doom 3: it has no type "shader" until a Quake III game registers it
  LManager := TDeclFactory.CreateStandardManager(FKit.Source, nil, False);
  Assert.AreEqual(DECL_MAX_TYPES, LManager.GetRegistry.GetDeclTypeFromName('shader'));
  TQ3ShaderRegistration.RegisterType(LManager.GetRegistry, []);
  Assert.AreEqual(DECL_Q3SHADER, LManager.GetRegistry.GetDeclTypeFromName('shader'));
  // the Doom 3 types are where they were
  Assert.AreEqual(DECL_MATERIAL, LManager.GetRegistry.GetDeclTypeFromName('material'));
end;

procedure TTestQ3ShaderManager.DovrebbeAvvisareUnoShaderDefinitoDueVolte;
begin
  FKit.Source.Add('scripts/t.shader', 'uno { { map a } } uno { { map b } }');
  FKit.Start(TQ3ShaderOptions.Standard);
  Assert.IsTrue(ContainsText(FKit.Lines.Text, 'shader ''uno'' previously defined at scripts/t.shader:1'));
  // the first one wins
  Assert.AreEqual('a', string(FKit.Find('uno').GetStage(0).Bundle.ImageNames[0]));
end;

procedure TTestQ3ShaderManager.DovrebbeNonConfondereLeParoleDelTipoConIlNome;
begin
  // in a .shader file there is no type word: a shader may have the name of a Doom 3 type
  FKit.Source.Add('scripts/t.shader', 'shader { { map a } } skin { { map b } }');
  FKit.Start(TQ3ShaderOptions.Standard);
  Assert.AreEqual('a', string(FKit.Find('shader').GetStage(0).Bundle.ImageNames[0]));
  Assert.AreEqual('b', string(FKit.Find('skin').GetStage(0).Bundle.ImageNames[0]));
end;

procedure TTestQ3ShaderManager.DovrebbeRileggereUnFileCambiato;
begin
  FKit.Source.Add('scripts/t.shader', 'uno { { map a } }');
  FKit.Start(TQ3ShaderOptions.Standard);
  Assert.AreEqual('a', string(FKit.Find('uno').GetStage(0).Bundle.ImageNames[0]));
  FKit.Source.Add('scripts/t.shader', 'uno { { map b } } due { { map c } }');
  FKit.Manager.ReloadFile('scripts/t.shader', True);
  // the shader that was in use is parsed again at once
  Assert.AreEqual('b', string(FKit.Find('uno').GetStage(0).Bundle.ImageNames[0]));
  Assert.AreEqual('c', string(FKit.Find('due').GetStage(0).Bundle.ImageNames[0]));
end;

procedure TTestQ3ShaderManager.DovrebbeMettereInDefaultUnoShaderTolto;
var
  LShader: IDeclQ3Shader;
begin
  FKit.Source.Add('scripts/t.shader', 'uno { { map a } } due { { map b } }');
  FKit.Start(TQ3ShaderOptions.Standard);
  LShader := FKit.Find('due');
  Assert.AreEqual(1, LShader.GetStageCount);
  FKit.Source.Add('scripts/t.shader', 'uno { { map a } }');
  FKit.Manager.ReloadFile('scripts/t.shader', True);
  Assert.IsTrue(LShader.IsDefaultShader);
end;

procedure TTestQ3ShaderManager.DovrebbeLeggereIFileDiUnaCartellaInOrdine;
begin
  FKit.Source.Add('scripts/b.shader', 'uno { { map b } }');
  FKit.Source.Add('scripts/a.shader', 'uno { { map a } } due { { map c } }');
  FKit.Source.Add('scripts/other.txt', 'tre { { map d } }');
  FKit.Start(TQ3ShaderOptions.Standard);
  Assert.AreEqual('a', string(FKit.Find('uno').GetStage(0).Bundle.ImageNames[0]));
  Assert.AreEqual('c', string(FKit.Find('due').GetStage(0).Bundle.ImageNames[0]));
  // a file with another extension is not read: "tre" is an image
  Assert.AreEqual('tre.tga', string(FKit.Find('tre').GetStage(0).Bundle.ImageNames[0]));
end;

end.
