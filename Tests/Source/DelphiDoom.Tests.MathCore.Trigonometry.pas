{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the trigonometric tables       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Trigonometry;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.MathCore.Golden,
  DelphiDoom.Tests.MathCore.PairRunner;

type
  /// <summary>
  ///   Parity with the tables and the angle functions of the old tables unit (golden file
  ///   trigonometry.golden.txt: a fingerprint of each table and of the functions)
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreTrigonometry = class(TObject)
  private
    FGolden: TGoldenFile;
    FRunner: TPairRunner;
    procedure CheckTable(const AKey: string; const ACount: Integer;
      const AReader: TFunc<Integer, Integer>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAvereLaTabellaDelSenoUgualeAlVecchia;
    [Test]
    procedure DovrebbeAvereLaTabellaDelCosenoUgualeAlVecchio;
    [Test]
    procedure DovrebbeAvereLaTabellaDellaTangenteUgualeAlVecchia;
    [Test]
    procedure DovrebbeAvereLeTabelleDellArcoTangenteUgualiAlleVecchie;
    [Test]
    procedure DovrebbeAvereLeTabelleDelSenoFissoUgualiAlleVecchie;
    [Test]
    procedure DovrebbeCalcolareLaPendenzaCometSlopeDiv;
    [Test]
    procedure DovrebbeCalcolareLaPendenzaEsattaCometSlopeDivEx;
    [Test]
    procedure DovrebbeConvertireUnAngoloInGradiECometFixedToAngle;
    [Test]
    procedure DovrebbeConvertireUnAngoloInFissoCometAngleToFixed;
    [Test]
    procedure DovrebbeConvertireGradiInPendenzaCometDegToSlope;

    [Test]
    procedure DovrebbeDareSenoECosenoNotevoli;
    [Test]
    procedure DovrebbeDareLaPendenzaDegliAngoliLimite;
    [Test]
    procedure DovrebbeLimitareLaPendenzaOltreNovantaGradi;
    [Test]
    procedure DovrebbeSaturareLaPendenzaConDenominatorePiccolo;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.Trigonometry, DelphiDoom.Tests.MathCore.Fingerprint;

{ TTestMathCoreTrigonometry }

procedure TTestMathCoreTrigonometry.Setup;
begin
  FGolden := TGoldenFile.Create('trigonometry.golden.txt');
  FRunner := TPairRunner.Create(FGolden);
end;

procedure TTestMathCoreTrigonometry.TearDown;
begin
  FRunner.Free;
  FGolden.Free;
end;

procedure TTestMathCoreTrigonometry.CheckTable(const AKey: string; const ACount: Integer;
  const AReader: TFunc<Integer, Integer>);
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to ACount - 1 do
      LFingerprint.AddInteger(AReader(LIndex));
    FGolden.Check(AKey, LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreTrigonometry.DovrebbeAvereLaTabellaDelSenoUgualeAlVecchia;
begin
  CheckTable('trig.FineSine', 10240, function(AIndex: Integer): Integer begin Result := TTrigonometry.FineSine(AIndex); end);
end;

procedure TTestMathCoreTrigonometry.DovrebbeAvereLaTabellaDelCosenoUgualeAlVecchio;
begin
  CheckTable('trig.FineCosine', FINEANGLES, function(AIndex: Integer): Integer begin Result := TTrigonometry.FineCosine(AIndex); end);
end;

procedure TTestMathCoreTrigonometry.DovrebbeAvereLaTabellaDellaTangenteUgualeAlVecchia;
begin
  CheckTable('trig.FineTangent', 4097, function(AIndex: Integer): Integer begin Result := TTrigonometry.FineTangent(AIndex); end);
end;

procedure TTestMathCoreTrigonometry.DovrebbeAvereLeTabelleDellArcoTangenteUgualiAlleVecchie;
begin
  CheckTable('trig.TanToAngle', 2049, function(AIndex: Integer): Integer begin Result := Integer(TTrigonometry.TanToAngle(AIndex)); end);
  CheckTable('trig.TanToAngleEx', 65537, function(AIndex: Integer): Integer begin Result := Integer(TTrigonometry.TanToAngleEx(AIndex)); end);
end;

procedure TTestMathCoreTrigonometry.DovrebbeAvereLeTabelleDelSenoFissoUgualiAlleVecchie;
begin
  CheckTable('trig.FixedSine', 81920, function(AIndex: Integer): Integer begin Result := TTrigonometry.FixedSine(AIndex); end);
  CheckTable('trig.FixedCosine', FIXEDANGLES, function(AIndex: Integer): Integer begin Result := TTrigonometry.FixedCosine(AIndex); end);
end;

procedure TTestMathCoreTrigonometry.DovrebbeCalcolareLaPendenzaCometSlopeDiv;
begin
  FRunner.BinUnsigned('trig.SlopeDiv',
    function(A, B: Cardinal): Cardinal begin Result := TTrigonometry.SlopeDiv(Integer(A), Integer(B)); end);
end;

procedure TTestMathCoreTrigonometry.DovrebbeCalcolareLaPendenzaEsattaCometSlopeDivEx;
begin
  FRunner.BinUnsigned('trig.SlopeDivEx',
    function(A, B: Cardinal): Cardinal begin Result := TTrigonometry.SlopeDivEx(Integer(A), Integer(B)); end);
end;

procedure TTestMathCoreTrigonometry.DovrebbeConvertireUnAngoloInGradiECometFixedToAngle;
begin
  FRunner.BinUnsigned('trig.FixedToAngle',
    function(A, B: Cardinal): Cardinal begin Result := TTrigonometry.FixedToAngle(Integer(A)); end);
end;

procedure TTestMathCoreTrigonometry.DovrebbeConvertireUnAngoloInFissoCometAngleToFixed;
begin
  FRunner.Bin('trig.AngleToFixed',
    function(A, B: Integer): Integer begin Result := TTrigonometry.AngleToFixed(Cardinal(A)); end);
end;

procedure TTestMathCoreTrigonometry.DovrebbeConvertireGradiInPendenzaCometDegToSlope;
begin
  FRunner.Unary('trig.DegreesToSlope',
    function(A: Integer): Integer begin Result := TTrigonometry.DegreesToSlope(A); end);
end;

procedure TTestMathCoreTrigonometry.DovrebbeDareSenoECosenoNotevoli;
begin
  Assert.AreEqual(25, TTrigonometry.FineSine(0));
  // the cosine of 0 is the sine of a quarter of a turn
  Assert.AreEqual(TTrigonometry.FineSine(FINEANGLES div 4), TTrigonometry.FineCosine(0));
  Assert.AreEqual(65535, TTrigonometry.FixedSine(FIXEDANGLES div 4 - 1));
  Assert.AreEqual(65535, TTrigonometry.FixedCosine(0));
  Assert.AreEqual(Cardinal(ANG45), TTrigonometry.TanToAngle(SLOPERANGE));
end;

procedure TTestMathCoreTrigonometry.DovrebbeDareLaPendenzaDegliAngoliLimite;
begin
  Assert.AreEqual(TTrigonometry.FineTangent(FINEANGLES div 4), TTrigonometry.AngleToSlope(0));
  Assert.AreEqual(TTrigonometry.FineTangent(0), TTrigonometry.AngleToSlope(ANG90 + 1));
  // exactly -90 degrees: the old code read before the table, this one the last entry of it
  Assert.AreEqual(TTrigonometry.FineTangent(FINEANGLES div 2), TTrigonometry.AngleToSlope(-ANG90));
end;

procedure TTestMathCoreTrigonometry.DovrebbeLimitareLaPendenzaOltreNovantaGradi;
begin
  Assert.AreEqual(TTrigonometry.FineTangent(FINEANGLES div 2 - 1),
    TTrigonometry.AngleToSlope(-ANG90 - 1));
  Assert.AreEqual(TTrigonometry.FineTangent(FINEANGLES div 2 - 1),
    TTrigonometry.AngleToSlope(Integer($80000000)));
end;

procedure TTestMathCoreTrigonometry.DovrebbeSaturareLaPendenzaConDenominatorePiccolo;
begin
  Assert.AreEqual(Cardinal(SLOPERANGE), TTrigonometry.SlopeDiv(100, 511));
  Assert.AreEqual(Cardinal(SLOPERANGE_EX), TTrigonometry.SlopeDivEx(100, 31));
  Assert.AreEqual(Cardinal(SLOPERANGE), TTrigonometry.SlopeDiv(1000, 1000));
end;

end.
