{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingImageProgram, with a fake source of images     }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.ImageProgram;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Imaging.Rgba.Image, DelphiDoom.Imaging.ImageProgram.Intf,
  DelphiDoom.Imaging.ImageProgram.Interpreter, DelphiDoom.Tests.IdImages.Golden;

type
  /// <summary>Images by name; remembers what was asked and whether pixels were wanted</summary>
  TFakeImageSource = class(TInterfacedObject, IImagingProgramSource)
  strict private
    FImages: TDictionary<string, TImagingRgbaImage>;
    FStamps: TDictionary<string, Int64>;
    FRequests: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddImage(const AName: string; const AImage: TImagingRgbaImage; const AStamp: Int64);
    function TryLoad(const AName: string; const AWantPixels: Boolean; out AImage: TImagingRgbaImage;
      out ATimestamp: Int64): Boolean;
    /// <summary>"name:P" when pixels were asked, "name:T" for the timestamp only</summary>
    property Requests: TStringList read FRequests;
  end;

  [TestFixture]
  [Category('IdImages')]
  TTestImagingImageProgram = class
  strict private
    FSource: TFakeImageSource;
    FSourceIntf: IImagingProgramSource;
    FProgram: TImagingImageProgram;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareUnNomeSemplice;
    [Test]
    procedure DovrebbeDareFalsoSeMancaUnaImmagine;
    [Test]
    procedure DovrebbeApplicareUnaOperazioneUnaria;
    [Test]
    procedure DovrebbeSommareImmaginiDiDimensioniDiverse;
    [Test]
    procedure DovrebbeCombinareINormaliESegnareBump;
    [Test]
    procedure DovrebbeFareLaHeightmapEScrivereIlNomeCanonico;
    [Test]
    procedure DovrebbeScrivereIlNomeCanonicoDiUnProgrammaAnnidato;
    [Test]
    procedure DovrebbeLeggereLeQuattroScaleDiScale;
    [Test]
    procedure DovrebbeLeggereIPercorsiComeUnSoloToken;
    [Test]
    procedure DovrebbeIgnorareLeMaiuscoleNeiNomiDelleOperazioni;
    [Test]
    procedure DovrebbeDareIlTimestampPiuRecenteSenzaPixel;
    [Test]
    procedure DovrebbeFallireSeFallisceUnArgomentoAnnidato;
    [Test]
    procedure DovrebbeTroncareIlNomeCanonicoA255;
    [Test]
    procedure DovrebbeSaltareUnProgrammaDaUnLexerSenzaCaricare;
    [Test]
    procedure DovrebbeUsareMakeIntensityEMakeAlpha;
    [Test]
    procedure DovrebbeRifiutareUnTimestampNonTrovatoDallaSorgente;
  end;

implementation

uses
  DelphiDoom.Imaging.Types, DelphiDoom.Imaging.ImageProgram.Operations, DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.IdLib.Text.Types;

{ TFakeImageSource }

constructor TFakeImageSource.Create;
begin
  inherited Create;
  FImages := TDictionary<string, TImagingRgbaImage>.Create;
  FStamps := TDictionary<string, Int64>.Create;
  FRequests := TStringList.Create;
end;

destructor TFakeImageSource.Destroy;
begin
  FRequests.Free;
  FStamps.Free;
  FImages.Free;
  inherited Destroy;
end;

procedure TFakeImageSource.AddImage(const AName: string; const AImage: TImagingRgbaImage;
  const AStamp: Int64);
begin
  FImages.AddOrSetValue(AName, AImage);
  FStamps.AddOrSetValue(AName, AStamp);
end;

function TFakeImageSource.TryLoad(const AName: string; const AWantPixels: Boolean;
  out AImage: TImagingRgbaImage; out ATimestamp: Int64): Boolean;
var
  LSuffix: string;
begin
  if AWantPixels then
    LSuffix := ':P'
  else
    LSuffix := ':T';
  FRequests.Add(AName + LSuffix);
  AImage := Default(TImagingRgbaImage);
  Result := FImages.ContainsKey(AName);
  if not Result then
  begin
    ATimestamp := IMAGING_TIMESTAMP_NOT_FOUND;
    Exit;
  end;
  ATimestamp := FStamps[AName];
  if AWantPixels then
  begin
    AImage := FImages[AName];
    // the caller owns what it gets: a copy
    AImage.Pixels := Copy(AImage.Pixels);
  end;
end;

{ TTestImagingImageProgram }

procedure TTestImagingImageProgram.Setup;
begin
  FSource := TFakeImageSource.Create;
  FSourceIntf := FSource;
  FProgram := TImagingImageProgram.Create(FSourceIntf);
  FSource.AddImage('a', TIdImagesGolden.Generate(8, 8, 1, False), 100);
  FSource.AddImage('b', TIdImagesGolden.Generate(4, 4, 2, False), 250);
  FSource.AddImage('textures/base_wall/foo', TIdImagesGolden.Generate(2, 2, 3, False), 7);
  FSource.AddImage('n1', TIdImagesGolden.Generate(8, 8, 4, True), 5);
  FSource.AddImage('n2', TIdImagesGolden.Generate(4, 4, 5, True), 6);
end;

procedure TTestImagingImageProgram.TearDown;
begin
  FProgram.Free;
  FSourceIntf := nil;
end;

procedure TTestImagingImageProgram.DovrebbeCaricareUnNomeSemplice;
var
  LResult: TImagingProgramResult;
begin
  Assert.IsTrue(FProgram.Load('a', LResult));
  Assert.IsTrue(LResult.Image.SameAs(TIdImagesGolden.Generate(8, 8, 1, False)));
  Assert.AreEqual<Int64>(100, LResult.Timestamp);
  Assert.IsFalse(LResult.IsBump);
  Assert.AreEqual('a', string(FProgram.CanonicalName));
end;

procedure TTestImagingImageProgram.DovrebbeDareFalsoSeMancaUnaImmagine;
var
  LResult: TImagingProgramResult;
begin
  Assert.IsFalse(FProgram.Load('missing', LResult));
  Assert.IsTrue(LResult.Image.IsEmpty);
end;

procedure TTestImagingImageProgram.DovrebbeApplicareUnaOperazioneUnaria;
var
  LResult: TImagingProgramResult;
  LExpected: TImagingRgbaImage;
begin
  LExpected := TIdImagesGolden.Generate(8, 8, 1, False);
  TImagingProgramOperations.InvertAlpha(LExpected);
  Assert.IsTrue(FProgram.Load('invertAlpha( a )', LResult));
  Assert.IsTrue(LResult.Image.SameAs(LExpected));
  Assert.AreEqual('invertAlpha( a)', string(FProgram.CanonicalName));
  LExpected := TIdImagesGolden.Generate(8, 8, 1, False);
  TImagingProgramOperations.InvertColor(LExpected);
  Assert.IsTrue(FProgram.Load('invertColor(a)', LResult));
  Assert.IsTrue(LResult.Image.SameAs(LExpected));
end;

procedure TTestImagingImageProgram.DovrebbeSommareImmaginiDiDimensioniDiverse;
var
  LResult: TImagingProgramResult;
  LExpected: TImagingRgbaImage;
begin
  LExpected := TIdImagesGolden.Generate(8, 8, 1, False);
  TImagingProgramOperations.Add(LExpected, TIdImagesGolden.Generate(4, 4, 2, False));
  Assert.IsTrue(FProgram.Load('add( a, b )', LResult));
  Assert.IsTrue(LResult.Image.SameAs(LExpected));
  // the timestamp is the newest of the images that were read
  Assert.AreEqual<Int64>(250, LResult.Timestamp);
  Assert.AreEqual('add( a, b)', string(FProgram.CanonicalName));
end;

procedure TTestImagingImageProgram.DovrebbeCombinareINormaliESegnareBump;
var
  LResult: TImagingProgramResult;
  LExpected: TImagingRgbaImage;
begin
  LExpected := TIdImagesGolden.Generate(8, 8, 4, True);
  TImagingProgramOperations.AddNormalMaps(LExpected, TIdImagesGolden.Generate(4, 4, 5, True));
  TImagingProgramOperations.SmoothNormalMap(LExpected);
  Assert.IsTrue(FProgram.Load('smoothnormals( addnormals( n1, n2 ) )', LResult));
  Assert.IsTrue(LResult.Image.SameAs(LExpected));
  Assert.IsTrue(LResult.IsBump);
end;

procedure TTestImagingImageProgram.DovrebbeFareLaHeightmapEScrivereIlNomeCanonico;
var
  LResult: TImagingProgramResult;
  LExpected: TImagingRgbaImage;
begin
  LExpected := TIdImagesGolden.Generate(8, 8, 1, False);
  TImagingProgramOperations.HeightmapToNormalMap(LExpected, 4);
  Assert.IsTrue(FProgram.Load('heightmap( a, 4 )', LResult));
  Assert.IsTrue(LResult.Image.SameAs(LExpected));
  Assert.IsTrue(LResult.IsBump);
  // the tokens have a space before them, ( , ) have none
  Assert.AreEqual('heightmap( a, 4)', string(FProgram.CanonicalName));
end;

procedure TTestImagingImageProgram.DovrebbeScrivereIlNomeCanonicoDiUnProgrammaAnnidato;
var
  LResult: TImagingProgramResult;
begin
  Assert.IsTrue(FProgram.Load('addnormals(n1,heightmap(a,2.5))', LResult));
  Assert.AreEqual('addnormals( n1, heightmap( a, 2.5))', string(FProgram.CanonicalName));
end;

procedure TTestImagingImageProgram.DovrebbeLeggereLeQuattroScaleDiScale;
var
  LResult: TImagingProgramResult;
  LExpected: TImagingRgbaImage;
begin
  LExpected := TIdImagesGolden.Generate(8, 8, 1, False);
  TImagingProgramOperations.Scale(LExpected, [0.5, 0.25, 2, 1]);
  Assert.IsTrue(FProgram.Load('scale( a, 0.5, 0.25, 2, 1 )', LResult));
  Assert.IsTrue(LResult.Image.SameAs(LExpected));
  Assert.AreEqual('scale( a, 0.5, 0.25, 2, 1)', string(FProgram.CanonicalName));
end;

procedure TTestImagingImageProgram.DovrebbeLeggereIPercorsiComeUnSoloToken;
var
  LResult: TImagingProgramResult;
begin
  Assert.IsTrue(FProgram.Load('invertColor( textures/base_wall/foo )', LResult));
  Assert.AreEqual('textures/base_wall/foo:P', FSource.Requests[0]);
end;

procedure TTestImagingImageProgram.DovrebbeIgnorareLeMaiuscoleNeiNomiDelleOperazioni;
var
  LResult: TImagingProgramResult;
begin
  Assert.IsTrue(FProgram.Load('INVERTALPHA( a )', LResult));
  Assert.IsTrue(FProgram.Load('MakeIntensity( a )', LResult));
  Assert.IsTrue(FProgram.Load('HEIGHTMAP( a, 1 )', LResult));
  Assert.IsTrue(LResult.IsBump);
end;

procedure TTestImagingImageProgram.DovrebbeDareIlTimestampPiuRecenteSenzaPixel;
var
  LStamp: Int64;
begin
  Assert.IsTrue(FProgram.GetTimestamp('add( a, scale( b, 1, 1, 1, 1 ) )', LStamp));
  Assert.AreEqual<Int64>(250, LStamp);
  Assert.AreEqual('a:T', FSource.Requests[0]);
  Assert.AreEqual('b:T', FSource.Requests[1]);
  Assert.AreEqual<Integer>(2, FSource.Requests.Count);
  Assert.IsFalse(FProgram.GetTimestamp('missing', LStamp));
end;

procedure TTestImagingImageProgram.DovrebbeFallireSeFallisceUnArgomentoAnnidato;
var
  LResult: TImagingProgramResult;
begin
  Assert.IsFalse(FProgram.Load('add( a, missing )', LResult));
  Assert.IsTrue(LResult.Image.IsEmpty);
  Assert.IsFalse(FProgram.Load('scale( missing, 1, 1, 1, 1 )', LResult));
  Assert.IsFalse(FProgram.Load('invertAlpha( missing )', LResult));
  Assert.IsFalse(FProgram.Load('heightmap( missing, 1 )', LResult));
end;

procedure TTestImagingImageProgram.DovrebbeTroncareIlNomeCanonicoA255;
var
  LResult: TImagingProgramResult;
  LName: string;
begin
  LName := StringOfChar('x', 300);
  FSource.AddImage(LName, TIdImagesGolden.Generate(2, 2, 9, False), 1);
  Assert.IsTrue(FProgram.Load(LName, LResult));
  Assert.AreEqual<Integer>(IMAGING_PROGRAM_MAX_NAME - 1, Length(FProgram.CanonicalName));
end;

procedure TTestImagingImageProgram.DovrebbeSaltareUnProgrammaDaUnLexerSenzaCaricare;
var
  LLexer: TIdLexer;
  LText: AnsiString;
  LName: string;
begin
  LText := 'heightmap( a, 2 ) next';
  LLexer := TIdLexer.Create(LEXFL_NOFATALERRORS or LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS
    or LEXFL_ALLOWPATHNAMES);
  try
    LLexer.LoadMemory(LText, Length(LText), 'test');
    LName := FProgram.SkipProgram(LLexer);
    Assert.AreEqual('heightmap( a, 2)', LName);
    Assert.AreEqual<Integer>(0, FSource.Requests.Count);
    LName := FProgram.SkipProgram(LLexer);
    Assert.AreEqual('next', LName);
  finally
    LLexer.Free;
  end;
end;

procedure TTestImagingImageProgram.DovrebbeUsareMakeIntensityEMakeAlpha;
var
  LResult: TImagingProgramResult;
  LExpected: TImagingRgbaImage;
begin
  LExpected := TIdImagesGolden.Generate(8, 8, 1, False);
  TImagingProgramOperations.MakeIntensity(LExpected);
  Assert.IsTrue(FProgram.Load('makeIntensity( a )', LResult));
  Assert.IsTrue(LResult.Image.SameAs(LExpected));
  LExpected := TIdImagesGolden.Generate(8, 8, 1, False);
  TImagingProgramOperations.MakeAlpha(LExpected);
  Assert.IsTrue(FProgram.Load('makeAlpha( a )', LResult));
  Assert.IsTrue(LResult.Image.SameAs(LExpected));
end;

procedure TTestImagingImageProgram.DovrebbeRifiutareUnTimestampNonTrovatoDallaSorgente;
var
  LResult: TImagingProgramResult;
begin
  // a source that finds an image but says that its timestamp is "not found" is a missing image
  FSource.AddImage('odd', TIdImagesGolden.Generate(2, 2, 1, False), IMAGING_TIMESTAMP_NOT_FOUND);
  Assert.IsFalse(FProgram.Load('odd', LResult));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestImagingImageProgram);

end.
