{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III shader time functions                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Q3ShaderCalc;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Decl.Q3Shader.Types,
  DelphiDoom.Decl.Q3Shader.Calc.Types, DelphiDoom.Decl.Q3Shader.Calc.Kit;

type
  [TestFixture]
  [Category('Decl')]
  TTestQ3CMath = class
  public
    [Test]
    procedure DovrebbeTroncareVersoLoZero;
    [Test]
    procedure DovrebbeDareIlValoreIndefinitoFuoriScalaENan;
    [Test]
    procedure DovrebbeCalcolareIlPavimentoDiUnDouble;
    [Test]
    procedure DovrebbeApprossimareLInversoDellaRadice;
    [Test]
    procedure DovrebbeNormalizzareUnVettoreNelBuffer;
    [Test]
    procedure DovrebbeRifiutareUnBufferTroppoCorto;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3FuncTables = class
  strict private
    FKit: TQ3ShaderCalc;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereLeTabelleDelSeno;
    [Test]
    procedure DovrebbeAvereLeTabelleDiQuadratoETriangolo;
    [Test]
    procedure DovrebbeAvereLeTabelleDelDenteDiSega;
    [Test]
    procedure DovrebbeRifiutareLeFunzioniSenzaTabella;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3Noise = class
  strict private
    FKit: TQ3ShaderCalc;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEssereRipetibile;
    [Test]
    procedure DovrebbeTenersiNellIntervalloDellaTabella;
    [Test]
    procedure DovrebbeInterpolareFraIPuntiIntieri;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3WaveEvaluator = class
  strict private
    FKit: TQ3ShaderCalc;
    function Wave(const AFunc: TQ3GenFunc; const ABase, AAmplitude, APhase, AFrequency: Single): TQ3WaveForm;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeValutareLaOndaAlTempoDato;
    [Test]
    procedure DovrebbeLimitareLOndaFraZeroEUno;
    [Test]
    procedure DovrebbeLasciarePassareUnNan;
    [Test]
    procedure DovrebbeRifiutareIlRumoreComeTabella;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3ColorCalc = class
  strict private
    FKit: TQ3ShaderCalc;
    function Wave(const AFunc: TQ3GenFunc; const ABase, AAmplitude, APhase, AFrequency: Single): TQ3WaveForm;
    function Entity: TQ3EntityShading;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeColorareDiGrigioConLOndaELuceIdentita;
    [Test]
    procedure DovrebbeColorareDiGrigioConIlRumore;
    [Test]
    procedure DovrebbeTenereIlGrigioFraZeroEDuecentocinquantacinque;
    [Test]
    procedure DovrebbeScrivereSoloLAlfaDellOnda;
    [Test]
    procedure DovrebbePrendereIColoriDallEntita;
    [Test]
    procedure DovrebbeNonFareNienteSenzaEntita;
    [Test]
    procedure DovrebbeRifiutareUnBufferDiColoriTroppoCorto;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3TexCoordCalc = class
  strict private
    FKit: TQ3ShaderCalc;
    FTess: TQ3ShaderTess;
    FTexCoords: TArray<Single>;
    function Wave(const AFunc: TQ3GenFunc; const ABase, AAmplitude, APhase, AFrequency: Single): TQ3WaveForm;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScalareLeCoordinate;
    [Test]
    procedure DovrebbeScorrereEMantenereLaFrazione;
    [Test]
    procedure DovrebbeTrasformareConLaMatrice;
    [Test]
    procedure DovrebbeRuotareDiNovantaGradi;
    [Test]
    procedure DovrebbeAllungareConUnaOnda;
    [Test]
    procedure DovrebbeFareTurbolenzaConUnaOnda;
    [Test]
    procedure DovrebbeGenerareLeCoordinateDellAmbiente;
    [Test]
    procedure DovrebbeGenerareLeCoordinateIdentitaETexture;
    [Test]
    procedure DovrebbeGenerareLeCoordinateDellaLightmapEDelVettore;
    [Test]
    procedure DovrebbeFermarsiAlPrimoTcModNessuno;
    [Test]
    procedure DovrebbeLasciareLeCoordinateConUnTcGenNonValido;
    [Test]
    procedure DovrebbeScorrereConLeCoordinateDellEntita;
    [Test]
    procedure DovrebbeRifiutareIlTcModDellEntitaSenzaEntita;
    [Test]
    procedure DovrebbeRifiutareLaNebbia;
    [Test]
    procedure DovrebbeRifiutareUnBufferDiCoordinateTroppoCorto;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3DeformCalc = class
  strict private
    FKit: TQ3ShaderCalc;
    FTess: TQ3ShaderTess;
    function Deform(const AKind: TQ3Deform): TQ3DeformStage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSpostareLungoLaNormaleConUnOndaSenzaFrequenza;
    [Test]
    procedure DovrebbeSpostareLungoLaNormaleConUnOndaDiFase;
    [Test]
    procedure DovrebbeMuovereTuttiIVertici;
    [Test]
    procedure DovrebbeGonfiareConLeCoordinateDellaTexture;
    [Test]
    procedure DovrebbeAgitareLeNormaliEMantenerleUnitarie;
    [Test]
    procedure DovrebbeApplicareSoloLeDeformazioniPortate;
    [Test]
    procedure DovrebbeRifiutareUnOndaSenzaTabella;
  end;

  /// <summary>The catalog is the one of the tests of the parity: a double of the table of shaders of the renderer</summary>
  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderRemapper = class
  public
    [Test]
    procedure DovrebbeRimappareTuttiGliShaderConLoStessoNome;
    [Test]
    procedure DovrebbeTogliereLaRimappaturaSulloShaderStesso;
    [Test]
    procedure DovrebbeAvvisareSeLoShaderNonSiTrova;
    [Test]
    procedure DovrebbeAvvisareSeIlNuovoShaderNonSiTrova;
    [Test]
    procedure DovrebbeImpostareLoScartoDiTempoDelNuovoShader;
    [Test]
    procedure DovrebbeTrovareLoShaderFallitoAllaSecondaVolta;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderCalcKit = class
  public
    [Test]
    procedure DovrebbeCreareELegareLeClassi;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Tests.Scanner.IdFakes, DelphiDoom.Decl.Q3Shader.Calc.Intf,
  DelphiDoom.Decl.Q3Shader.Calc.Remapper, DelphiDoom.Decl.Q3Shader.Calc.ColorCalc,
  DelphiDoom.Decl.Q3Shader.Calc.TexCoordCalc, DelphiDoom.Decl.Q3Shader.Calc.FuncTables,
  DelphiDoom.Decl.Q3Shader.Calc.WaveEvaluator, DelphiDoom.Decl.Q3Shader.Calc.FloatMask,
  DelphiDoom.Tests.Decl.Q3ShaderCalcSupport;

function MakeWave(const AFunc: TQ3GenFunc; const ABase, AAmplitude, APhase, AFrequency: Single): TQ3WaveForm;
begin
  Result.Func := AFunc;
  Result.Base := ABase;
  Result.Amplitude := AAmplitude;
  Result.Phase := APhase;
  Result.Frequency := AFrequency;
end;

function Near(const AExpected, AActual: Single; const ATolerance: Double = 0.0001): Boolean;
begin
  Result := Abs(Double(AExpected) - Double(AActual)) <= ATolerance;
end;

{ TTestQ3CMath }

procedure TTestQ3CMath.DovrebbeTroncareVersoLoZero;
begin
  Assert.AreEqual(2, TQ3CMath.FloatToInt(2.9));
  Assert.AreEqual(-2, TQ3CMath.FloatToInt(-2.9));
  Assert.AreEqual(0, TQ3CMath.FloatToInt(0.99));
end;

procedure TTestQ3CMath.DovrebbeDareIlValoreIndefinitoFuoriScalaENan;
begin
  Assert.AreEqual(Integer($80000000), TQ3CMath.FloatToInt(3.0E9));
  Assert.AreEqual(Integer($80000000), TQ3CMath.FloatToInt(-3.0E9));
  Assert.AreEqual(Integer($80000000), TQ3CMath.FloatToInt(NaN));
  Assert.AreEqual(Integer($80000000), TQ3CMath.FloatToInt(-2147483648.0));
end;

procedure TTestQ3CMath.DovrebbeCalcolareIlPavimentoDiUnDouble;
begin
  Assert.AreEqual(Double(2.0), TQ3CMath.FloorValue(2.5));
  Assert.AreEqual(Double(-3.0), TQ3CMath.FloorValue(-2.5));
  Assert.AreEqual(Double(-2.0), TQ3CMath.FloorValue(-2.0));
end;

procedure TTestQ3CMath.DovrebbeApprossimareLInversoDellaRadice;
var
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  Assert.IsTrue(Near(0.5, TQ3CMath.Rsqrt(4), 0.002));
  Assert.IsTrue(Near(0.1, TQ3CMath.Rsqrt(100), 0.0005));
  // a negative number goes through the arithmetic shift of the original and gives a number, not an error
  TQ3CMath.Rsqrt(-4);
end;

procedure TTestQ3CMath.DovrebbeNormalizzareUnVettoreNelBuffer;
var
  LBuffer: TArray<Single>;
begin
  LBuffer := [0, 3, 0, 4, 1];
  TQ3CMath.NormalizeFast(LBuffer, 1);
  Assert.IsTrue(Near(0.6, LBuffer[1], 0.005));
  Assert.IsTrue(Near(0.8, LBuffer[3], 0.005));
  Assert.AreEqual(Double(0), Double(LBuffer[0]));
  Assert.AreEqual(Double(1), Double(LBuffer[4]));
end;

procedure TTestQ3CMath.DovrebbeRifiutareUnBufferTroppoCorto;
var
  LBuffer: TArray<Single>;
  LBytes: TBytes;
begin
  SetLength(LBuffer, 7);
  SetLength(LBytes, 7);
  Assert.WillRaise(
    procedure
    begin
      TQ3CMath.RequireFloats(LBuffer, 2, 4, 'xyz');
    end, EDeclQ3ShaderCalcException);
  Assert.WillRaise(
    procedure
    begin
      TQ3CMath.RequireBytes(LBytes, 2);
    end, EDeclQ3ShaderCalcException);
  TQ3CMath.RequireFloats(LBuffer, 1, 7, 'ok');
end;

{ TTestQ3FuncTables }

procedure TTestQ3FuncTables.Setup;
begin
  FKit := TQ3ShaderCalc.Create;
end;

procedure TTestQ3FuncTables.TearDown;
begin
  FKit.Free;
end;

procedure TTestQ3FuncTables.DovrebbeAvereLeTabelleDelSeno;
var
  LTable: TQ3FuncTable;
begin
  LTable := FKit.Tables.TableFor(gfSin);
  Assert.AreEqual(Q3_FUNCTABLE_SIZE, Integer(Length(LTable)));
  Assert.AreEqual(Double(0), Double(LTable[0]));
  Assert.IsTrue(Near(1, LTable[256], 0.0001));
  Assert.IsTrue(Near(0, LTable[511], 0.01));
  Assert.IsTrue(Near(-1, LTable[767], 0.0001));
  // the last entry is a full turn: the table is built on 1023 steps
  Assert.IsTrue(Near(0, LTable[1023], 0.0001));
  Assert.IsTrue(Near(LTable[5], FKit.Tables.SinTable[5]));
end;

procedure TTestQ3FuncTables.DovrebbeAvereLeTabelleDiQuadratoETriangolo;
var
  LSquare, LTriangle: TQ3FuncTable;
begin
  LSquare := FKit.Tables.TableFor(gfSquare);
  Assert.AreEqual(Double(1), Double(LSquare[0]));
  Assert.AreEqual(Double(1), Double(LSquare[511]));
  Assert.AreEqual(Double(-1), Double(LSquare[512]));
  Assert.AreEqual(Double(-1), Double(LSquare[1023]));
  LTriangle := FKit.Tables.TableFor(gfTriangle);
  Assert.AreEqual(Double(0), Double(LTriangle[0]));
  Assert.AreEqual(Double(0.5), Double(LTriangle[128]));
  Assert.AreEqual(Double(0.5), Double(LTriangle[384]));
  Assert.AreEqual(Double(-0.5), Double(LTriangle[640]));
  Assert.AreEqual(Double(-0.5), Double(LTriangle[896]));
  Assert.AreEqual(Double(1), Double(LTriangle[256]));
  Assert.AreEqual(Double(Double(255) / 256), Double(LTriangle[255]));
  Assert.AreEqual(Double(-1), Double(LTriangle[768]));
end;

procedure TTestQ3FuncTables.DovrebbeAvereLeTabelleDelDenteDiSega;
var
  LSawTooth, LInverse: TQ3FuncTable;
begin
  LSawTooth := FKit.Tables.TableFor(gfSawtooth);
  LInverse := FKit.Tables.TableFor(gfInverseSawtooth);
  Assert.AreEqual(Double(0), Double(LSawTooth[0]));
  Assert.AreEqual(Double(0.5), Double(LSawTooth[512]));
  Assert.AreEqual(Double(1), Double(LInverse[0]));
  Assert.AreEqual(Double(0.5), Double(LInverse[512]));
end;

procedure TTestQ3FuncTables.DovrebbeRifiutareLeFunzioniSenzaTabella;
var
  LTables: TQ3FuncTables;
begin
  LTables := FKit.Tables;
  Assert.WillRaise(
    procedure
    var
      LIgnored: TQ3FuncTable;
    begin
      LIgnored := LTables.TableFor(gfNone);
    end, EDeclQ3ShaderCalcException);
  Assert.WillRaise(
    procedure
    var
      LIgnored: TQ3FuncTable;
    begin
      LIgnored := LTables.TableFor(gfNoise);
    end, EDeclQ3ShaderCalcException);
end;

{ TTestQ3Noise }

procedure TTestQ3Noise.Setup;
begin
  FKit := TQ3ShaderCalc.Create;
end;

procedure TTestQ3Noise.TearDown;
begin
  FKit.Free;
end;

procedure TTestQ3Noise.DovrebbeEssereRipetibile;
var
  LOther: TQ3ShaderCalc;
begin
  LOther := TQ3ShaderCalc.Create;
  try
    Assert.AreEqual(Double(FKit.Noise.Get4f(1.5, -2.25, 3, 4.75)), Double(LOther.Noise.Get4f(1.5, -2.25, 3, 4.75)));
  finally
    LOther.Free;
  end;
end;

procedure TTestQ3Noise.DovrebbeTenersiNellIntervalloDellaTabella;
var
  LIndex: Integer;
  LValue: Single;
begin
  for LIndex := 0 to 200 do
  begin
    LValue := FKit.Noise.Get4f(LIndex * 0.37, LIndex * -0.11, LIndex * 0.05, LIndex * 0.9);
    Assert.IsTrue((LValue >= -1.0001) and (LValue <= 1.0001));
  end;
end;

procedure TTestQ3Noise.DovrebbeInterpolareFraIPuntiIntieri;
var
  LLow, LHigh, LMiddle: Single;
begin
  LLow := FKit.Noise.Get4f(3, 4, 5, 6);
  LHigh := FKit.Noise.Get4f(4, 4, 5, 6);
  LMiddle := FKit.Noise.Get4f(3.5, 4, 5, 6);
  Assert.IsTrue(Near((LLow + LHigh) / 2, LMiddle, 0.0001));
end;

{ TTestQ3WaveEvaluator }

procedure TTestQ3WaveEvaluator.Setup;
begin
  FKit := TQ3ShaderCalc.Create;
end;

procedure TTestQ3WaveEvaluator.TearDown;
begin
  FKit.Free;
end;

function TTestQ3WaveEvaluator.Wave(const AFunc: TQ3GenFunc; const ABase, AAmplitude, APhase,
  AFrequency: Single): TQ3WaveForm;
begin
  Result := MakeWave(AFunc, ABase, AAmplitude, APhase, AFrequency);
end;

procedure TTestQ3WaveEvaluator.DovrebbeValutareLaOndaAlTempoDato;
begin
  // a quarter of a period of a one hertz sine
  Assert.IsTrue(Near(1.5, FKit.Waves.EvalWaveForm(Wave(gfSin, 0.5, 1, 0, 1), 0.25), 0.001));
  Assert.IsTrue(Near(0.5, FKit.Waves.EvalWaveForm(Wave(gfSin, 0.5, 1, 0, 1), 0), 0.001));
  Assert.IsTrue(Near(-0.5, FKit.Waves.EvalWaveForm(Wave(gfSquare, 0, 0.5, 0, 1), 0.75), 0.001));
  Assert.IsTrue(Near(0.25, FKit.Waves.EvalWaveForm(Wave(gfSawtooth, 0, 1, 0, 1), 0.25), 0.001));
  // the time wraps with the table
  Assert.IsTrue(Near(FKit.Waves.EvalWaveForm(Wave(gfSin, 0, 1, 0, 1), 0.125),
    FKit.Waves.EvalWaveForm(Wave(gfSin, 0, 1, 0, 1), 3.125), 0.0001));
end;

procedure TTestQ3WaveEvaluator.DovrebbeLimitareLOndaFraZeroEUno;
begin
  Assert.AreEqual(Double(1), Double(FKit.Waves.EvalWaveFormClamped(Wave(gfSquare, 3, 1, 0, 1), 0)));
  Assert.AreEqual(Double(0), Double(FKit.Waves.EvalWaveFormClamped(Wave(gfSquare, -3, 1, 0, 1), 0)));
  Assert.IsTrue(Near(0.6, FKit.Waves.EvalWaveFormClamped(Wave(gfSquare, 0.5, 0.1, 0, 1), 0)));
end;

procedure TTestQ3WaveEvaluator.DovrebbeLasciarePassareUnNan;
begin
  Assert.IsTrue(IsNan(FKit.Waves.EvalWaveFormClamped(Wave(gfSquare, NaN, 1, 0, 1), 0)));
end;

procedure TTestQ3WaveEvaluator.DovrebbeRifiutareIlRumoreComeTabella;
var
  LWaves: TQ3WaveEvaluator;
  LWave: TQ3WaveForm;
begin
  LWaves := FKit.Waves;
  LWave := Wave(gfNoise, 0, 1, 0, 1);
  Assert.WillRaise(
    procedure
    var
      LIgnored: Single;
    begin
      LIgnored := LWaves.EvalWaveForm(LWave, 0);
    end, EDeclQ3ShaderCalcException);
end;

{ TTestQ3ColorCalc }

procedure TTestQ3ColorCalc.Setup;
begin
  FKit := TQ3ShaderCalc.Create;
end;

procedure TTestQ3ColorCalc.TearDown;
begin
  FKit.Free;
end;

function TTestQ3ColorCalc.Wave(const AFunc: TQ3GenFunc; const ABase, AAmplitude, APhase,
  AFrequency: Single): TQ3WaveForm;
begin
  Result := MakeWave(AFunc, ABase, AAmplitude, APhase, AFrequency);
end;

function TTestQ3ColorCalc.Entity: TQ3EntityShading;
begin
  Result.Present := True;
  Result.ShaderRGBA[0] := 200;
  Result.ShaderRGBA[1] := 100;
  Result.ShaderRGBA[2] := 50;
  Result.ShaderRGBA[3] := 25;
  Result.ShaderTexCoord[0] := 0;
  Result.ShaderTexCoord[1] := 0;
end;

procedure TTestQ3ColorCalc.DovrebbeColorareDiGrigioConLOndaELuceIdentita;
var
  LColors: TBytes;
begin
  SetLength(LColors, 8);
  FKit.Colors.CalcWaveColor(Wave(gfSquare, 0.5, 0, 0, 1), 0, 1, 2, LColors);
  Assert.AreEqual(127, Integer(LColors[0]));
  Assert.AreEqual(127, Integer(LColors[2]));
  Assert.AreEqual(255, Integer(LColors[3]));
  Assert.AreEqual(127, Integer(LColors[4]));
  FKit.Colors.CalcWaveColor(Wave(gfSquare, 0.5, 0, 0, 1), 0, 0.5, 2, LColors);
  Assert.AreEqual(63, Integer(LColors[5]));
end;

procedure TTestQ3ColorCalc.DovrebbeColorareDiGrigioConIlRumore;
var
  LColors: TBytes;
  LExpected: Single;
begin
  SetLength(LColors, 4);
  FKit.Colors.CalcWaveColor(Wave(gfNoise, 0.5, 0.25, 0.5, 2), 1, 1, 1, LColors);
  LExpected := 0.5 + FKit.Noise.Get4f(0, 0, 0, 3) * 0.25;
  Assert.AreEqual(Integer(Trunc(255 * LExpected)), Integer(LColors[0]));
  Assert.AreEqual(Integer(LColors[0]), Integer(LColors[1]));
end;

procedure TTestQ3ColorCalc.DovrebbeTenereIlGrigioFraZeroEDuecentocinquantacinque;
var
  LColors: TBytes;
begin
  SetLength(LColors, 4);
  FKit.Colors.CalcWaveColor(Wave(gfSquare, 3, 0, 0, 1), 0, 1, 1, LColors);
  Assert.AreEqual(255, Integer(LColors[0]));
  FKit.Colors.CalcWaveColor(Wave(gfSquare, -3, 0, 0, 1), 0, 1, 1, LColors);
  Assert.AreEqual(0, Integer(LColors[0]));
  FKit.Colors.CalcWaveColor(Wave(gfSquare, NaN, 0, 0, 1), 0, 1, 1, LColors);
  Assert.AreEqual(0, Integer(LColors[0]));
end;

procedure TTestQ3ColorCalc.DovrebbeScrivereSoloLAlfaDellOnda;
var
  LColors: TBytes;
begin
  LColors := [1, 2, 3, 4, 5, 6, 7, 8];
  FKit.Colors.CalcWaveAlpha(Wave(gfSquare, 0.5, 0, 0, 1), 0, 2, LColors);
  Assert.AreEqual(1, Integer(LColors[0]));
  Assert.AreEqual(127, Integer(LColors[3]));
  Assert.AreEqual(5, Integer(LColors[4]));
  Assert.AreEqual(127, Integer(LColors[7]));
end;

procedure TTestQ3ColorCalc.DovrebbePrendereIColoriDallEntita;
var
  LColors: TBytes;
begin
  SetLength(LColors, 8);
  TQ3ColorCalc.CalcColorFromEntity(Entity, 2, LColors);
  Assert.AreEqual(200, Integer(LColors[0]));
  Assert.AreEqual(25, Integer(LColors[3]));
  Assert.AreEqual(50, Integer(LColors[6]));
  TQ3ColorCalc.CalcColorFromOneMinusEntity(Entity, 2, LColors);
  Assert.AreEqual(55, Integer(LColors[0]));
  Assert.AreEqual(230, Integer(LColors[3]));
  TQ3ColorCalc.CalcAlphaFromEntity(Entity, 2, LColors);
  Assert.AreEqual(25, Integer(LColors[7]));
  Assert.AreEqual(55, Integer(LColors[0]));
  TQ3ColorCalc.CalcAlphaFromOneMinusEntity(Entity, 2, LColors);
  Assert.AreEqual(230, Integer(LColors[7]));
end;

procedure TTestQ3ColorCalc.DovrebbeNonFareNienteSenzaEntita;
var
  LColors: TBytes;
  LEntity: TQ3EntityShading;
begin
  LColors := [9, 9, 9, 9];
  LEntity := Entity;
  LEntity.Present := False;
  TQ3ColorCalc.CalcColorFromEntity(LEntity, 1, LColors);
  TQ3ColorCalc.CalcColorFromOneMinusEntity(LEntity, 1, LColors);
  TQ3ColorCalc.CalcAlphaFromEntity(LEntity, 1, LColors);
  TQ3ColorCalc.CalcAlphaFromOneMinusEntity(LEntity, 1, LColors);
  Assert.AreEqual(36, Integer(LColors[0]) + Integer(LColors[1]) + Integer(LColors[2]) + Integer(LColors[3]));
end;

procedure TTestQ3ColorCalc.DovrebbeRifiutareUnBufferDiColoriTroppoCorto;
var
  LColors: TBytes;
  LCalc: TQ3ColorCalc;
  LWave: TQ3WaveForm;
  LEntity: TQ3EntityShading;
begin
  SetLength(LColors, 3);
  LCalc := FKit.Colors;
  LWave := Wave(gfSin, 0, 1, 0, 1);
  LEntity := Entity;
  Assert.WillRaise(
    procedure
    begin
      LCalc.CalcWaveColor(LWave, 0, 1, 1, LColors);
    end, EDeclQ3ShaderCalcException);
  Assert.WillRaise(
    procedure
    begin
      LCalc.CalcWaveAlpha(LWave, 0, 1, LColors);
    end, EDeclQ3ShaderCalcException);
  Assert.WillRaise(
    procedure
    begin
      TQ3ColorCalc.CalcColorFromEntity(LEntity, 1, LColors);
    end, EDeclQ3ShaderCalcException);
end;

{ TTestQ3TexCoordCalc }

procedure TTestQ3TexCoordCalc.Setup;
begin
  FKit := TQ3ShaderCalc.Create;
  // one instance runs every test of the fixture: the record starts clean each time
  FTess := Default(TQ3ShaderTess);
  FTess.NumVertexes := 2;
  FTess.Xyz := [0, 0, 0, 1, 8, 16, 24, 1];
  FTess.Normal := [0, 0, 1, 0, 1, 0, 0, 0];
  FTess.TexCoords := [0.25, 0.5, 0.75, 1, 1, 2, 3, 4];
  FTess.ViewOrigin[0] := 0;
  FTess.ViewOrigin[1] := 0;
  FTess.ViewOrigin[2] := 100;
  FTexCoords := [0.5, 0.25, 1, 2];
end;

procedure TTestQ3TexCoordCalc.TearDown;
begin
  FKit.Free;
end;

function TTestQ3TexCoordCalc.Wave(const AFunc: TQ3GenFunc; const ABase, AAmplitude, APhase,
  AFrequency: Single): TQ3WaveForm;
begin
  Result := MakeWave(AFunc, ABase, AAmplitude, APhase, AFrequency);
end;

procedure TTestQ3TexCoordCalc.DovrebbeScalareLeCoordinate;
begin
  TQ3TexCoordCalc.CalcScale(2, 4, 2, FTexCoords);
  Assert.AreEqual(Double(1), Double(FTexCoords[0]));
  Assert.AreEqual(Double(1), Double(FTexCoords[1]));
  Assert.AreEqual(Double(2), Double(FTexCoords[2]));
  Assert.AreEqual(Double(8), Double(FTexCoords[3]));
end;

procedure TTestQ3TexCoordCalc.DovrebbeScorrereEMantenereLaFrazione;
begin
  // 3.25 seconds at 1 and -0.5 per second: the scroll keeps the fractional part
  TQ3TexCoordCalc.CalcScroll(1, -0.5, 3.25, 2, FTexCoords);
  Assert.AreEqual(Double(0.75), Double(FTexCoords[0]));
  Assert.AreEqual(Double(0.25 + 0.375), Double(FTexCoords[1]));
  Assert.AreEqual(Double(1.25), Double(FTexCoords[2]));
end;

procedure TTestQ3TexCoordCalc.DovrebbeTrasformareConLaMatrice;
var
  LMod: TQ3TexMod;
begin
  FillChar(LMod, SizeOf(LMod), 0);
  LMod.Matrix[0][0] := 2;
  LMod.Matrix[1][0] := 1;
  LMod.Matrix[0][1] := 0;
  LMod.Matrix[1][1] := 4;
  LMod.Translate[0] := 0.5;
  LMod.Translate[1] := -1;
  TQ3TexCoordCalc.CalcTransform(LMod, 1, FTexCoords);
  Assert.AreEqual(Double(0.5 * 2 + 0.25 * 1 + 0.5), Double(FTexCoords[0]));
  Assert.AreEqual(Double(0.25 * 4 - 1), Double(FTexCoords[1]));
end;

procedure TTestQ3TexCoordCalc.DovrebbeRuotareDiNovantaGradi;
begin
  // a quarter turn around the middle of the texture in one second
  FTexCoords := [0.5, 0.5, 1, 0.5];
  FKit.TexCoords.CalcRotate(-90, 1, 2, FTexCoords);
  Assert.IsTrue(Near(0.5, FTexCoords[0], 0.01));
  Assert.IsTrue(Near(0.5, FTexCoords[1], 0.01));
  Assert.IsTrue(Near(0.5, FTexCoords[2], 0.01));
  Assert.IsTrue(Near(1, FTexCoords[3], 0.01));
end;

procedure TTestQ3TexCoordCalc.DovrebbeAllungareConUnaOnda;
begin
  // a constant wave of 2: the coordinates are halved around the middle
  FKit.TexCoords.CalcStretch(Wave(gfSquare, 2, 0, 0, 1), 0, 2, FTexCoords);
  Assert.IsTrue(Near(0.5, FTexCoords[0], 0.0001));
  Assert.IsTrue(Near(0.375, FTexCoords[1], 0.0001));
  Assert.IsTrue(Near(0.75, FTexCoords[2], 0.0001));
  Assert.IsTrue(Near(1.25, FTexCoords[3], 0.0001));
end;

procedure TTestQ3TexCoordCalc.DovrebbeFareTurbolenzaConUnaOnda;
var
  LExpected: Single;
begin
  FKit.TexCoords.CalcTurbulent(Wave(gfSin, 0, 0.1, 0, 0.5), 2, 2, FTess.Xyz, FTexCoords);
  Assert.IsTrue(Near(0.5, FTexCoords[0], 0.11));
  // the second vertex: ( x + z ) / 128 * 0.125 + now = ( 8 + 24 ) / 1024 + 1 = 1.03125
  LExpected := 1 + FKit.Tables.SinTable[Trunc(1.03125 * 1024) and 1023] * 0.1;
  Assert.IsTrue(Near(LExpected, FTexCoords[2], 0.0001));
end;

procedure TTestQ3TexCoordCalc.DovrebbeGenerareLeCoordinateDellAmbiente;
var
  LBundle: TQ3TextureBundle;
begin
  FillChar(LBundle, SizeOf(LBundle), 0);
  LBundle.TcGen := tgEnvironmentMapped;
  FKit.TexCoords.Compute(LBundle, FTess, FTexCoords);
  // the first vertex looks at the viewer straight on: the reflection is the normal and the point is the middle
  Assert.IsTrue(Near(0.5, FTexCoords[0], 0.01));
  Assert.IsTrue(Near(0.5 - 0.5, FTexCoords[1], 0.02));
end;

procedure TTestQ3TexCoordCalc.DovrebbeGenerareLeCoordinateIdentitaETexture;
var
  LBundle: TQ3TextureBundle;
begin
  FillChar(LBundle, SizeOf(LBundle), 0);
  LBundle.TcGen := tgIdentity;
  FKit.TexCoords.Compute(LBundle, FTess, FTexCoords);
  Assert.AreEqual(Double(0), Double(FTexCoords[3]));
  LBundle.TcGen := tgTexture;
  FKit.TexCoords.Compute(LBundle, FTess, FTexCoords);
  Assert.AreEqual(Double(0.25), Double(FTexCoords[0]));
  Assert.AreEqual(Double(1), Double(FTexCoords[2]));
  Assert.AreEqual(Double(2), Double(FTexCoords[3]));
end;

procedure TTestQ3TexCoordCalc.DovrebbeGenerareLeCoordinateDellaLightmapEDelVettore;
var
  LBundle: TQ3TextureBundle;
begin
  FillChar(LBundle, SizeOf(LBundle), 0);
  LBundle.TcGen := tgLightmap;
  FKit.TexCoords.Compute(LBundle, FTess, FTexCoords);
  Assert.AreEqual(Double(0.75), Double(FTexCoords[0]));
  Assert.AreEqual(Double(1), Double(FTexCoords[1]));
  Assert.AreEqual(Double(3), Double(FTexCoords[2]));
  LBundle.TcGen := tgVector;
  LBundle.TcGenVectors[0][0] := 1;
  LBundle.TcGenVectors[1][2] := 0.5;
  FKit.TexCoords.Compute(LBundle, FTess, FTexCoords);
  Assert.AreEqual(Double(0), Double(FTexCoords[0]));
  Assert.AreEqual(Double(8), Double(FTexCoords[2]));
  Assert.AreEqual(Double(12), Double(FTexCoords[3]));
end;

procedure TTestQ3TexCoordCalc.DovrebbeFermarsiAlPrimoTcModNessuno;
var
  LBundle: TQ3TextureBundle;
begin
  FillChar(LBundle, SizeOf(LBundle), 0);
  LBundle.TcGen := tgTexture;
  LBundle.NumTexMods := 3;
  LBundle.TexMods[0].ModType := tmScale;
  LBundle.TexMods[0].Scale[0] := 2;
  LBundle.TexMods[0].Scale[1] := 2;
  LBundle.TexMods[1].ModType := tmNone;
  LBundle.TexMods[2].ModType := tmScale;
  LBundle.TexMods[2].Scale[0] := 100;
  LBundle.TexMods[2].Scale[1] := 100;
  FKit.TexCoords.Compute(LBundle, FTess, FTexCoords);
  Assert.AreEqual(Double(0.5), Double(FTexCoords[0]));
  Assert.AreEqual(Double(2), Double(FTexCoords[2]));
end;

procedure TTestQ3TexCoordCalc.DovrebbeLasciareLeCoordinateConUnTcGenNonValido;
var
  LBundle: TQ3TextureBundle;
begin
  FillChar(LBundle, SizeOf(LBundle), 0);
  LBundle.TcGen := tgBad;
  LBundle.NumTexMods := 1;
  LBundle.TexMods[0].ModType := tmScale;
  LBundle.TexMods[0].Scale[0] := 2;
  LBundle.TexMods[0].Scale[1] := 2;
  FKit.TexCoords.Compute(LBundle, FTess, FTexCoords);
  Assert.AreEqual(Double(0.5), Double(FTexCoords[0]));
  Assert.AreEqual(Double(2), Double(FTexCoords[3]));
end;

procedure TTestQ3TexCoordCalc.DovrebbeScorrereConLeCoordinateDellEntita;
var
  LBundle: TQ3TextureBundle;
begin
  FillChar(LBundle, SizeOf(LBundle), 0);
  LBundle.TcGen := tgIdentity;
  LBundle.NumTexMods := 1;
  LBundle.TexMods[0].ModType := tmEntityTranslate;
  FTess.Entity.Present := True;
  FTess.Entity.ShaderTexCoord[0] := 0.25;
  FTess.Entity.ShaderTexCoord[1] := 0.5;
  FTess.ShaderTime := 1.5;
  FKit.TexCoords.Compute(LBundle, FTess, FTexCoords);
  Assert.AreEqual(Double(0.375), Double(FTexCoords[0]));
  Assert.AreEqual(Double(0.75), Double(FTexCoords[1]));
end;

procedure TTestQ3TexCoordCalc.DovrebbeRifiutareIlTcModDellEntitaSenzaEntita;
var
  LBundle: TQ3TextureBundle;
begin
  FillChar(LBundle, SizeOf(LBundle), 0);
  LBundle.TcGen := tgIdentity;
  LBundle.NumTexMods := 1;
  LBundle.TexMods[0].ModType := tmEntityTranslate;
  Assert.WillRaise(
    procedure
    begin
      FKit.TexCoords.Compute(LBundle, FTess, FTexCoords);
    end, EDeclQ3ShaderCalcException);
end;

procedure TTestQ3TexCoordCalc.DovrebbeRifiutareLaNebbia;
var
  LBundle: TQ3TextureBundle;
begin
  FillChar(LBundle, SizeOf(LBundle), 0);
  LBundle.TcGen := tgFog;
  Assert.WillRaise(
    procedure
    begin
      FKit.TexCoords.Compute(LBundle, FTess, FTexCoords);
    end, EDeclQ3ShaderCalcException);
end;

procedure TTestQ3TexCoordCalc.DovrebbeRifiutareUnBufferDiCoordinateTroppoCorto;
var
  LShort: TArray<Single>;
begin
  SetLength(LShort, 3);
  Assert.WillRaise(
    procedure
    begin
      TQ3TexCoordCalc.CalcScale(1, 1, 2, LShort);
    end, EDeclQ3ShaderCalcException);
  Assert.WillRaise(
    procedure
    begin
      FKit.TexCoords.CalcTurbulent(Wave(gfSin, 0, 1, 0, 1), 0, 2, FTess.Xyz, LShort);
    end, EDeclQ3ShaderCalcException);
end;

{ TTestQ3DeformCalc }

procedure TTestQ3DeformCalc.Setup;
begin
  FKit := TQ3ShaderCalc.Create;
  FTess.NumVertexes := 2;
  FTess.Xyz := [0, 0, 0, 1, 8, 16, 24, 1];
  FTess.Normal := [0, 0, 1, 0, 1, 0, 0, 0];
  FTess.TexCoords := [0.25, 0.5, 0.75, 1, 1, 2, 3, 4];
end;

procedure TTestQ3DeformCalc.TearDown;
begin
  FKit.Free;
end;

function TTestQ3DeformCalc.Deform(const AKind: TQ3Deform): TQ3DeformStage;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Deformation := AKind;
end;

procedure TTestQ3DeformCalc.DovrebbeSpostareLungoLaNormaleConUnOndaSenzaFrequenza;
var
  LDeform: TQ3DeformStage;
begin
  LDeform := Deform(dfWave);
  LDeform.DeformationWave := MakeWave(gfSquare, 2, 0, 0, 0);
  Assert.IsTrue(FKit.Deforms.Apply(LDeform, FTess));
  Assert.AreEqual(Double(2), Double(FTess.Xyz[2]));
  Assert.AreEqual(Double(10), Double(FTess.Xyz[4]));
  Assert.AreEqual(Double(16), Double(FTess.Xyz[5]));
  Assert.AreEqual(Double(24), Double(FTess.Xyz[6]));
end;

procedure TTestQ3DeformCalc.DovrebbeSpostareLungoLaNormaleConUnOndaDiFase;
var
  LDeform: TQ3DeformStage;
begin
  LDeform := Deform(dfWave);
  LDeform.DeformationWave := MakeWave(gfSquare, 1, 0, 0, 1);
  LDeform.DeformationSpread := 0.01;
  FKit.Deforms.CalcDeformVertexes(LDeform, FTess);
  Assert.AreEqual(Double(1), Double(FTess.Xyz[2]));
  Assert.AreEqual(Double(9), Double(FTess.Xyz[4]));
end;

procedure TTestQ3DeformCalc.DovrebbeMuovereTuttiIVertici;
var
  LDeform: TQ3DeformStage;
begin
  LDeform := Deform(dfMove);
  LDeform.DeformationWave := MakeWave(gfSquare, 2, 0, 0, 1);
  LDeform.MoveVector[0] := 1;
  LDeform.MoveVector[1] := 2;
  LDeform.MoveVector[2] := 3;
  Assert.IsTrue(FKit.Deforms.Apply(LDeform, FTess));
  Assert.AreEqual(Double(2), Double(FTess.Xyz[0]));
  Assert.AreEqual(Double(4), Double(FTess.Xyz[1]));
  Assert.AreEqual(Double(6), Double(FTess.Xyz[2]));
  Assert.AreEqual(Double(1), Double(FTess.Xyz[3]));
  Assert.AreEqual(Double(10), Double(FTess.Xyz[4]));
end;

procedure TTestQ3DeformCalc.DovrebbeGonfiareConLeCoordinateDellaTexture;
var
  LDeform: TQ3DeformStage;
  LExpected: Single;
begin
  LDeform := Deform(dfBulge);
  LDeform.BulgeWidth := 2;
  LDeform.BulgeHeight := 3;
  LDeform.BulgeSpeed := 1;
  FTess.RefDefTime := 500;
  Assert.IsTrue(FKit.Deforms.Apply(LDeform, FTess));
  // st[0] * width + now = 0.5 + 0.5; sin( 1 * 1024 / 2 pi ) with the float constants of the original
  LExpected := FKit.Tables.SinTable[Trunc(1024 / (3.14159274 * 2) * 1.0) and 1023] * 3;
  Assert.IsTrue(Near(LExpected, FTess.Xyz[2], 0.01));
end;

procedure TTestQ3DeformCalc.DovrebbeAgitareLeNormaliEMantenerleUnitarie;
var
  LDeform: TQ3DeformStage;
  LLength: Double;
begin
  LDeform := Deform(dfNormals);
  LDeform.DeformationWave := MakeWave(gfNone, 0, 0.5, 0, 1);
  FTess.ShaderTime := 2.5;
  Assert.IsTrue(FKit.Deforms.Apply(LDeform, FTess));
  LLength := Sqrt(Sqr(Double(FTess.Normal[0])) + Sqr(Double(FTess.Normal[1])) + Sqr(Double(FTess.Normal[2])));
  Assert.IsTrue(Abs(LLength - 1) < 0.01);
  // the positions do not change
  Assert.AreEqual(Double(8), Double(FTess.Xyz[4]));
end;

procedure TTestQ3DeformCalc.DovrebbeApplicareSoloLeDeformazioniPortate;
begin
  Assert.IsTrue(FKit.Deforms.Apply(Deform(dfNone), FTess));
  Assert.IsFalse(FKit.Deforms.Apply(Deform(dfAutoSprite), FTess));
  Assert.IsFalse(FKit.Deforms.Apply(Deform(dfAutoSprite2), FTess));
  Assert.IsFalse(FKit.Deforms.Apply(Deform(dfProjectionShadow), FTess));
  Assert.IsFalse(FKit.Deforms.Apply(Deform(dfText3), FTess));
end;

procedure TTestQ3DeformCalc.DovrebbeRifiutareUnOndaSenzaTabella;
var
  LDeform: TQ3DeformStage;
begin
  LDeform := Deform(dfWave);
  LDeform.DeformationWave := MakeWave(gfNoise, 0, 1, 0, 0);
  Assert.WillRaise(
    procedure
    var
      LIgnored: Boolean;
    begin
      LIgnored := FKit.Deforms.Apply(LDeform, FTess);
    end, EDeclQ3ShaderCalcException);
  LDeform := Deform(dfMove);
  LDeform.DeformationWave := MakeWave(gfNone, 0, 1, 0, 1);
  Assert.WillRaise(
    procedure
    var
      LIgnored: Boolean;
    begin
      LIgnored := FKit.Deforms.Apply(LDeform, FTess);
    end, EDeclQ3ShaderCalcException);
end;

{ TTestQ3ShaderRemapper }

procedure TTestQ3ShaderRemapper.DovrebbeRimappareTuttiGliShaderConLoStessoNome;
var
  LCatalog: TFakeShaderCatalog;
  LIntf: IQ3ShaderCatalog;
  LRemapper: TQ3ShaderRemapper;
begin
  LCatalog := TFakeShaderCatalog.Create;
  LIntf := LCatalog;
  LCatalog.Register('a', -1);
  LCatalog.Register('a', 3);
  LCatalog.Register('b', -1);
  LRemapper := TQ3ShaderRemapper.Create(LIntf, TFakeIdLibLog.Create);
  try
    LRemapper.Remap('a.tga', 'b');
    Assert.IsTrue(LRemapper.IsRemapped(2));
    Assert.IsTrue(LRemapper.IsRemapped(3));
    Assert.AreEqual(4, LRemapper.RemappedShader(2));
    Assert.AreEqual(4, LRemapper.RemappedShader(3));
    Assert.IsFalse(LRemapper.IsRemapped(4));
    Assert.AreEqual(4, LRemapper.RemappedShader(4));
  finally
    LRemapper.Free;
  end;
end;

procedure TTestQ3ShaderRemapper.DovrebbeTogliereLaRimappaturaSulloShaderStesso;
var
  LCatalog: TFakeShaderCatalog;
  LIntf: IQ3ShaderCatalog;
  LRemapper: TQ3ShaderRemapper;
begin
  LCatalog := TFakeShaderCatalog.Create;
  LIntf := LCatalog;
  LCatalog.Register('a', -1);
  LCatalog.Register('b', -1);
  LRemapper := TQ3ShaderRemapper.Create(LIntf, TFakeIdLibLog.Create);
  try
    LRemapper.Remap('a', 'b');
    Assert.IsTrue(LRemapper.IsRemapped(2));
    LRemapper.Remap('b', 'b');
    Assert.IsFalse(LRemapper.IsRemapped(3));
    LRemapper.Remap('a', 'a');
    Assert.IsFalse(LRemapper.IsRemapped(2));
  finally
    LRemapper.Free;
  end;
end;

procedure TTestQ3ShaderRemapper.DovrebbeAvvisareSeLoShaderNonSiTrova;
var
  LLog: TFakeIdLibLog;
  LLogIntf: IIdLibLog;
  LRemapper: TQ3ShaderRemapper;
begin
  LLog := TFakeIdLibLog.Create;
  LLogIntf := LLog;
  LRemapper := TQ3ShaderRemapper.Create(TFakeShaderCatalog.Create, LLogIntf);
  try
    LRemapper.Remap('nofile/a', 'b');
    Assert.AreEqual(1, LLog.Lines.Count);
    Assert.AreEqual('W: R_RemapShader: shader nofile/a not found', LLog.Lines[0]);
  finally
    LRemapper.Free;
  end;
end;

procedure TTestQ3ShaderRemapper.DovrebbeAvvisareSeIlNuovoShaderNonSiTrova;
var
  LLog: TFakeIdLibLog;
  LLogIntf: IIdLibLog;
  LRemapper: TQ3ShaderRemapper;
begin
  LLog := TFakeIdLibLog.Create;
  LLogIntf := LLog;
  LRemapper := TQ3ShaderRemapper.Create(TFakeShaderCatalog.Create, LLogIntf);
  try
    LRemapper.Remap('a', 'nofile/b');
    Assert.AreEqual(1, LLog.Lines.Count);
    Assert.AreEqual('W: R_RemapShader: new shader nofile/b not found', LLog.Lines[0]);
  finally
    LRemapper.Free;
  end;
end;

procedure TTestQ3ShaderRemapper.DovrebbeImpostareLoScartoDiTempoDelNuovoShader;
var
  LCatalog: TFakeShaderCatalog;
  LIntf: IQ3ShaderCatalog;
  LRemapper: TQ3ShaderRemapper;
begin
  LCatalog := TFakeShaderCatalog.Create;
  LIntf := LCatalog;
  LCatalog.Register('a', -1);
  LCatalog.Register('b', -1);
  LRemapper := TQ3ShaderRemapper.Create(LIntf, nil);
  try
    Assert.AreEqual(Double(0), Double(LRemapper.TimeOffset(3)));
    LRemapper.Remap('a', 'b', '1.5', True);
    Assert.AreEqual(Double(1.5), Double(LRemapper.TimeOffset(3)));
    Assert.AreEqual(Double(0), Double(LRemapper.TimeOffset(2)));
    // a text that is not a number is zero, as atof
    LRemapper.Remap('a', 'b', 'abc', True);
    Assert.AreEqual(Double(0), Double(LRemapper.TimeOffset(3)));
  finally
    LRemapper.Free;
  end;
end;

procedure TTestQ3ShaderRemapper.DovrebbeTrovareLoShaderFallitoAllaSecondaVolta;
var
  LCatalog: TFakeShaderCatalog;
  LIntf: IQ3ShaderCatalog;
  LLog: TFakeIdLibLog;
  LLogIntf: IIdLibLog;
  LRemapper: TQ3ShaderRemapper;
begin
  // the renderer keeps a default shader under the name of a failed one: the second call finds it (a quirk of the C)
  LCatalog := TFakeShaderCatalog.Create;
  LIntf := LCatalog;
  LLog := TFakeIdLibLog.Create;
  LLogIntf := LLog;
  LCatalog.Register('b', -1);
  LRemapper := TQ3ShaderRemapper.Create(LIntf, LLogIntf);
  try
    LRemapper.Remap('nofile/y', 'b');
    Assert.AreEqual(1, LLog.Lines.Count);
    LRemapper.Remap('nofile/y', 'b');
    Assert.AreEqual(1, LLog.Lines.Count);
    Assert.AreEqual(2, LRemapper.RemappedShader(3));
  finally
    LRemapper.Free;
  end;
end;

procedure TTestQ3ShaderRemapper.DovrebbeFunzionareSenzaLog;
var
  LRemapper: TQ3ShaderRemapper;
begin
  LRemapper := TQ3ShaderRemapper.Create(TFakeShaderCatalog.Create, nil);
  try
    LRemapper.Remap('nofile/a', 'b');
    Assert.IsFalse(LRemapper.IsRemapped(2));
  finally
    LRemapper.Free;
  end;
end;

{ TTestQ3ShaderCalcKit }

procedure TTestQ3ShaderCalcKit.DovrebbeCreareELegareLeClassi;
var
  LKit: TQ3ShaderCalc;
begin
  LKit := TQ3ShaderCalc.Create;
  try
    Assert.IsNotNull(LKit.Tables);
    Assert.IsNotNull(LKit.Noise);
    Assert.IsNotNull(LKit.Waves);
    Assert.IsNotNull(LKit.Colors);
    Assert.IsNotNull(LKit.TexCoords);
    Assert.IsNotNull(LKit.Deforms);
    Assert.IsTrue(LKit.Waves.Tables = LKit.Tables);
  finally
    LKit.Free;
  end;
end;

end.
