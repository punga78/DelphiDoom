{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of MathCore - extrapolation, interpolation and the        }
{  curves on vectors of any size, with values calculated by hand               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Interpolate.Values;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('mathcore')]
  TTestInterpolateValues = class(TObject)
  public
    [Test]
    procedure TIdExtrapolateSenzaVelocitaDovrebbeRestareFermo;
    [Test]
    procedure TIdExtrapolateLineareDovrebbeSommareLeVelocita;
    [Test]
    procedure TIdExtrapolateDovrebbeFermarsiAllaFineSalvoNoStop;
    [Test]
    procedure TIdExtrapolateConDurataZeroDovrebbeDareIlValoreIniziale;
    [Test]
    procedure TIdExtrapolateDovrebbeConservareLaCacheDelTempoPrimaDellInizio;
    [Test]
    procedure TIdExtrapolateDovrebbeDareLaVelocitaDiOgniTipo;
    [Test]
    procedure TIdExtrapolateDovrebbeRifiutareUnaAritmeticaNulla;
    [Test]
    procedure TIdInterpolateDovrebbeInterpolareLinearmente;
    [Test]
    procedure TIdInterpolateDovrebbeRifiutareUnaAritmeticaNulla;
    [Test]
    procedure TIdInterpolateAccelDecelLinearDovrebbeArrivareAlValoreFinale;
    [Test]
    procedure TIdInterpolateAccelDecelDovrebbeRiscalareLeFasiTroppoLunghe;
    [Test]
    procedure TIdInterpolateAccelDecelSineDovrebbeArrivareAlValoreFinale;
    [Test]
    procedure TIdInterpolateAccelDecelConDurataNullaNonDovrebbeInizializzare;
    [Test]
    procedure TIdInterpolateAccelDecelDovrebbeRifiutareUnaAritmeticaNulla;
    [Test]
    procedure LeCurveSuVettoriDiQualsiasiDimensioneDovrebberoDareGliStessiValoriDelleCurveSuVec3;
    [Test]
    procedure LaCurvaNaturaleSuVettoriDiQualsiasiDimensioneDovrebbeDareGliStessiValoriDiVec3;
    [Test]
    procedure LAritmeticaDeiVettoriDiQualsiasiDimensioneDovrebbeSommareESottrarre;
    [Test]
    procedure LAritmeticaDeiVettoriDiQualsiasiDimensioneDovrebbeRifiutareDimensioniDiverse;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Curve.Arithmetic.Scalar,
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec3, DelphiDoom.MathCore.Float.Curve.Arithmetic.VecX,
  DelphiDoom.MathCore.Float.Curve.CatmullRomSpline,
  DelphiDoom.MathCore.Float.Curve.NaturalCubicSpline, DelphiDoom.MathCore.Float.Curve.Intf,
  DelphiDoom.MathCore.Float.Curve.Types, DelphiDoom.MathCore.Float.Extrapolate,
  DelphiDoom.MathCore.Float.Interpolate, DelphiDoom.MathCore.Float.Interpolate.AccelDecel,
  DelphiDoom.MathCore.Float.Interpolate.AccelDecelLinear,
  DelphiDoom.MathCore.Float.Interpolate.AccelDecelSine;

const
  Eps = 1E-4;

function Scalar: IIdCurveArithmetic<Single>;
begin
  Result := TIdCurveScalarArithmetic.Create;
end;

procedure TTestInterpolateValues.TIdExtrapolateSenzaVelocitaDovrebbeRestareFermo;
var
  LExtrapolate: TIdExtrapolate<Single>;
begin
  LExtrapolate := TIdExtrapolate<Single>.Create(Scalar);
  try
    // no extrapolation: the base speed only; 1000 ms at 2 units per second
    LExtrapolate.Init(100.0, 1000.0, 5.0, 2.0, 100.0, ID_EXTRAPOLATION_NONE);
    Assert.AreEqual(5.0, LExtrapolate.GetCurrentValue(50.0), Eps, 'prima dell''inizio');
    Assert.AreEqual(7.0, LExtrapolate.GetCurrentValue(1100.0), Eps, 'alla fine');
    Assert.AreEqual(2.0, LExtrapolate.GetCurrentSpeed(500.0), Eps);
    Assert.IsTrue(LExtrapolate.IsDone(1100.0));
    Assert.IsFalse(LExtrapolate.IsDone(1099.0));
    Assert.AreEqual(1100.0, LExtrapolate.GetEndTime, Eps);
    Assert.AreEqual(1000.0, LExtrapolate.GetDuration, Eps);
    Assert.AreEqual(100.0, LExtrapolate.GetStartTime, Eps);
    Assert.AreEqual(5.0, LExtrapolate.GetStartValue, Eps);
    Assert.AreEqual(2.0, LExtrapolate.GetBaseSpeed, Eps);
    Assert.AreEqual(100.0, LExtrapolate.GetSpeed, Eps);
    Assert.AreEqual(ID_EXTRAPOLATION_NONE, LExtrapolate.GetExtrapolationType);
  finally
    LExtrapolate.Free;
  end;
end;

procedure TTestInterpolateValues.TIdExtrapolateLineareDovrebbeSommareLeVelocita;
var
  LExtrapolate: TIdExtrapolate<Single>;
begin
  LExtrapolate := TIdExtrapolate<Single>.Create(Scalar);
  try
    LExtrapolate.Init(0.0, 2000.0, 1.0, 2.0, 3.0, ID_EXTRAPOLATION_LINEAR);
    // 1 + 0.5 s * (2 + 3)
    Assert.AreEqual(3.5, LExtrapolate.GetCurrentValue(500.0), Eps);
    Assert.AreEqual(5.0, LExtrapolate.GetCurrentSpeed(500.0), Eps);
  finally
    LExtrapolate.Free;
  end;
end;

procedure TTestInterpolateValues.TIdExtrapolateDovrebbeFermarsiAllaFineSalvoNoStop;
var
  LStops, LContinues: TIdExtrapolate<Single>;
begin
  LStops := TIdExtrapolate<Single>.Create(Scalar);
  LContinues := TIdExtrapolate<Single>.Create(Scalar);
  try
    LStops.Init(0.0, 1000.0, 0.0, 1.0, 0.0, ID_EXTRAPOLATION_NONE);
    LContinues.Init(0.0, 1000.0, 0.0, 1.0, 0.0, ID_EXTRAPOLATION_NONE or ID_EXTRAPOLATION_NOSTOP);
    Assert.AreEqual(1.0, LStops.GetCurrentValue(3000.0), Eps, 'si ferma');
    Assert.AreEqual(3.0, LContinues.GetCurrentValue(3000.0), Eps, 'continua');
    Assert.IsFalse(LContinues.IsDone(3000.0));
    Assert.AreEqual(0.0, LContinues.GetEndTime, Eps);
    Assert.AreEqual(0.0, LStops.GetCurrentSpeed(3000.0), Eps, 'fermo dopo la fine');
    Assert.AreEqual(1.0, LContinues.GetCurrentSpeed(3000.0), Eps);
  finally
    LContinues.Free;
    LStops.Free;
  end;
end;

procedure TTestInterpolateValues.TIdExtrapolateConDurataZeroDovrebbeDareIlValoreIniziale;
var
  LExtrapolate: TIdExtrapolate<Single>;
  LKind: Integer;
begin
  LExtrapolate := TIdExtrapolate<Single>.Create(Scalar);
  try
    for LKind in [ID_EXTRAPOLATION_ACCELLINEAR, ID_EXTRAPOLATION_DECELLINEAR,
      ID_EXTRAPOLATION_ACCELSINE, ID_EXTRAPOLATION_DECELSINE] do
    begin
      LExtrapolate.Init(10.0, 0.0, 4.0, 1.0, 1.0, LKind);
      Assert.AreEqual(4.0, LExtrapolate.GetCurrentValue(10.0), Eps);
      Assert.AreEqual(0.0, LExtrapolate.GetCurrentSpeed(10.0), Eps);
    end;
    Assert.AreEqual(0.0, LExtrapolate.GetEndTime, Eps, 'senza durata non c''e'' fine');
  finally
    LExtrapolate.Free;
  end;
end;

procedure TTestInterpolateValues.TIdExtrapolateDovrebbeConservareLaCacheDelTempoPrimaDellInizio;
var
  LExtrapolate: TIdExtrapolate<Single>;
begin
  LExtrapolate := TIdExtrapolate<Single>.Create(Scalar);
  try
    LExtrapolate.Init(100.0, 1000.0, 5.0, 2.0, 0.0, ID_EXTRAPOLATION_NONE);
    Assert.AreEqual(6.0, LExtrapolate.GetCurrentValue(600.0), Eps);
    // a time before the start returns the start value and is cached with the old value: as the C++
    Assert.AreEqual(5.0, LExtrapolate.GetCurrentValue(50.0), Eps);
    Assert.AreEqual(6.0, LExtrapolate.GetCurrentValue(50.0), Eps, 'valore in cache');
    LExtrapolate.SetStartTime(0.0);
    Assert.AreEqual(5.1, LExtrapolate.GetCurrentValue(50.0), Eps, 'SetStartTime svuota la cache');
    // the time 50 is now after the start: 5 + 0.05 s * 2
  finally
    LExtrapolate.Free;
  end;
end;

procedure TTestInterpolateValues.TIdExtrapolateDovrebbeDareLaVelocitaDiOgniTipo;
var
  LExtrapolate: TIdExtrapolate<Single>;
begin
  LExtrapolate := TIdExtrapolate<Single>.Create(Scalar);
  try
    LExtrapolate.Init(0.0, 1000.0, 0.0, 1.0, 4.0, ID_EXTRAPOLATION_ACCELLINEAR);
    Assert.AreEqual(1.0 + 0.5 * 4.0, LExtrapolate.GetCurrentSpeed(500.0), Eps);
    LExtrapolate.Init(0.0, 1000.0, 0.0, 1.0, 4.0, ID_EXTRAPOLATION_DECELLINEAR);
    Assert.AreEqual(1.0 + 0.5 * 4.0, LExtrapolate.GetCurrentSpeed(500.0), Eps);
    LExtrapolate.Init(0.0, 1000.0, 0.0, 1.0, 4.0, ID_EXTRAPOLATION_ACCELSINE);
    Assert.AreEqual(1.0 + 4.0 * Sqrt(0.5), LExtrapolate.GetCurrentSpeed(500.0), Eps);
    LExtrapolate.Init(0.0, 1000.0, 0.0, 1.0, 4.0, ID_EXTRAPOLATION_DECELSINE);
    Assert.AreEqual(1.0 + 4.0 * Sqrt(0.5), LExtrapolate.GetCurrentSpeed(500.0), Eps);
    // an unknown type falls back to the base speed
    LExtrapolate.Init(0.0, 1000.0, 0.0, 1.0, 4.0, $00);
    Assert.AreEqual(1.0, LExtrapolate.GetCurrentSpeed(500.0), Eps);
    Assert.AreEqual(0.0, LExtrapolate.GetCurrentValue(500.0), Eps);
  finally
    LExtrapolate.Free;
  end;
end;

procedure TTestInterpolateValues.TIdExtrapolateDovrebbeRifiutareUnaAritmeticaNulla;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdExtrapolate<Single>.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestInterpolateValues.TIdInterpolateDovrebbeInterpolareLinearmente;
var
  LInterpolate: TIdInterpolate<Single>;
begin
  LInterpolate := TIdInterpolate<Single>.Create(Scalar);
  try
    LInterpolate.Init(100.0, 400.0, 10.0, 20.0);
    Assert.AreEqual(10.0, LInterpolate.GetCurrentValue(50.0), Eps, 'prima');
    Assert.AreEqual(15.0, LInterpolate.GetCurrentValue(300.0), Eps, 'a meta''');
    Assert.AreEqual(20.0, LInterpolate.GetCurrentValue(900.0), Eps, 'dopo');
    Assert.IsTrue(LInterpolate.IsDone(500.0));
    Assert.AreEqual(500.0, LInterpolate.GetEndTime, Eps);
    Assert.AreEqual(400.0, LInterpolate.GetDuration, Eps);
    Assert.AreEqual(100.0, LInterpolate.GetStartTime, Eps);
    Assert.AreEqual(10.0, LInterpolate.GetStartValue, Eps);
    Assert.AreEqual(20.0, LInterpolate.GetEndValue, Eps);
    LInterpolate.SetStartTime(0.0);
    LInterpolate.SetDuration(100.0);
    LInterpolate.SetStartValue(0.0);
    LInterpolate.SetEndValue(1.0);
    Assert.AreEqual(0.25, LInterpolate.GetCurrentValue(25.0), Eps);
  finally
    LInterpolate.Free;
  end;
end;

procedure TTestInterpolateValues.TIdInterpolateDovrebbeRifiutareUnaAritmeticaNulla;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdInterpolate<Single>.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestInterpolateValues.TIdInterpolateAccelDecelLinearDovrebbeArrivareAlValoreFinale;
var
  LInterpolate: TIdInterpolateAccelDecelLinear<Single>;
begin
  LInterpolate := TIdInterpolateAccelDecelLinear<Single>.Create(Scalar);
  try
    LInterpolate.Init(0.0, 200.0, 200.0, 1000.0, 0.0, 10.0);
    Assert.AreEqual(0.0, LInterpolate.GetCurrentValue(0.0), Eps);
    Assert.AreEqual(5.0, LInterpolate.GetCurrentValue(500.0), 1E-3, 'a meta'' del percorso');
    Assert.AreEqual(10.0, LInterpolate.GetCurrentValue(1000.0), 1E-3);
    Assert.IsTrue(LInterpolate.IsDone(1000.0));
    Assert.AreEqual(1000.0, LInterpolate.GetEndTime, Eps);
    Assert.AreEqual(1000.0, LInterpolate.GetDuration, Eps);
    Assert.AreEqual(200.0, LInterpolate.GetAcceleration, Eps);
    Assert.AreEqual(200.0, LInterpolate.GetDeceleration, Eps);
    Assert.AreEqual(0.0, LInterpolate.GetStartTime, Eps);
    Assert.AreEqual(0.0, LInterpolate.GetStartValue, Eps);
    Assert.AreEqual(10.0, LInterpolate.GetEndValue, Eps);
    // the speed in the linear phase: 10 units over (600 + 200) ms
    Assert.AreEqual(12.5, LInterpolate.GetCurrentSpeed(500.0), 1E-3);
    LInterpolate.SetStartTime(0.0);
    LInterpolate.SetStartValue(0.0);
    LInterpolate.SetEndValue(10.0);
  finally
    LInterpolate.Free;
  end;
end;

procedure TTestInterpolateValues.TIdInterpolateAccelDecelDovrebbeRiscalareLeFasiTroppoLunghe;
var
  LInterpolate: TIdInterpolateAccelDecelLinear<Single>;
begin
  LInterpolate := TIdInterpolateAccelDecelLinear<Single>.Create(Scalar);
  try
    LInterpolate.Init(0.0, 800.0, 800.0, 1000.0, 0.0, 10.0);
    Assert.AreEqual(500.0, LInterpolate.GetAcceleration, Eps, 'accelerazione ridotta');
    Assert.AreEqual(500.0, LInterpolate.GetDeceleration, Eps, 'decelerazione ridotta');
    Assert.AreEqual(10.0, LInterpolate.GetCurrentValue(1000.0), 1E-3);
    // acceleration only (no linear phase): the first extrapolation is the acceleration
    LInterpolate.Init(0.0, 1000.0, 0.0, 1000.0, 0.0, 10.0);
    Assert.AreEqual(10.0, LInterpolate.GetCurrentValue(1000.0), 1E-2, 'solo accelerazione');
    // deceleration only
    LInterpolate.Init(0.0, 0.0, 1000.0, 1000.0, 0.0, 10.0);
    Assert.AreEqual(10.0, LInterpolate.GetCurrentValue(1000.0), 1E-2, 'sola decelerazione');
    // linear phase only: 10 units in one second
    LInterpolate.Init(0.0, 0.0, 0.0, 1000.0, 0.0, 10.0);
    Assert.AreEqual(5.0, LInterpolate.GetCurrentValue(500.0), 1E-3, 'solo fase lineare');
  finally
    LInterpolate.Free;
  end;
end;

procedure TTestInterpolateValues.TIdInterpolateAccelDecelSineDovrebbeArrivareAlValoreFinale;
var
  LInterpolate: TIdInterpolateAccelDecelSine<Single>;
begin
  LInterpolate := TIdInterpolateAccelDecelSine<Single>.Create(Scalar);
  try
    LInterpolate.Init(0.0, 300.0, 300.0, 1000.0, 2.0, 12.0);
    Assert.AreEqual(2.0, LInterpolate.GetCurrentValue(0.0), Eps);
    Assert.AreEqual(7.0, LInterpolate.GetCurrentValue(500.0), 1E-2, 'simmetrico a meta''');
    Assert.AreEqual(12.0, LInterpolate.GetCurrentValue(1000.0), 1E-2);
  finally
    LInterpolate.Free;
  end;
end;

procedure TTestInterpolateValues.TIdInterpolateAccelDecelConDurataNullaNonDovrebbeInizializzare;
var
  LInterpolate: TIdInterpolateAccelDecelSine<Single>;
begin
  LInterpolate := TIdInterpolateAccelDecelSine<Single>.Create(Scalar);
  try
    LInterpolate.Init(5.0, 10.0, 10.0, 0.0, 1.0, 2.0);
    // the phases are kept and the extrapolation is not started: no linear phase
    Assert.AreEqual(20.0, LInterpolate.GetDuration, Eps);
    Assert.AreEqual(1.0, LInterpolate.GetStartValue, Eps);
  finally
    LInterpolate.Free;
  end;
end;

procedure TTestInterpolateValues.TIdInterpolateAccelDecelDovrebbeRifiutareUnaAritmeticaNulla;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdInterpolateAccelDecelLinear<Single>.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestInterpolateValues.LeCurveSuVettoriDiQualsiasiDimensioneDovrebberoDareGliStessiValoriDelleCurveSuVec3;
var
  LVec3Curve: TIdCurveCatmullRomSpline<TIdVec3>;
  LVecXCurve: TIdCurveCatmullRomSpline<TIdVecXValue>;
  LIndex, LComponent: Integer;
  LValue3: TIdVec3;
  LValueX: TIdVecXValue;
  LTime: Single;
begin
  LVec3Curve := TIdCurveCatmullRomSpline<TIdVec3>.Create(TIdCurveVec3Arithmetic.Create);
  LVecXCurve := TIdCurveCatmullRomSpline<TIdVecXValue>.Create(TIdCurveVecXArithmetic.Create);
  try
    for LIndex := 0 to 5 do
    begin
      LTime := LIndex * 100.0;
      LVec3Curve.AddValue(LTime, TIdVec3.Create(LIndex * 1.5, Sqr(LIndex) - 3.0, 2.0 - LIndex));
      LVecXCurve.AddValue(LTime, TIdVecXValue.Create(LIndex * 1.5, Sqr(LIndex) - 3.0, 2.0 - LIndex));
    end;
    for LIndex := 0 to 40 do
    begin
      LTime := LIndex * 12.5;
      LValue3 := LVec3Curve.GetCurrentValue(LTime);
      LValueX := LVecXCurve.GetCurrentValue(LTime);
      Assert.AreEqual<Integer>(3, Length(LValueX));
      for LComponent := 0 to 2 do
      begin
        // the same arithmetic on the same floats: the same bits
        Assert.IsTrue(LValue3[LComponent] = LValueX[LComponent],
          Format('tempo %g componente %d', [LTime, LComponent]));
      end;
    end;
  finally
    LVecXCurve.Free;
    LVec3Curve.Free;
  end;
end;

procedure TTestInterpolateValues.LaCurvaNaturaleSuVettoriDiQualsiasiDimensioneDovrebbeDareGliStessiValoriDiVec3;
var
  LVec3Curve: TIdCurveNaturalCubicSpline<TIdVec3>;
  LVecXCurve: TIdCurveNaturalCubicSpline<TIdVecXValue>;
  LIndex, LComponent: Integer;
  LValue3: TIdVec3;
  LValueX: TIdVecXValue;
begin
  LVec3Curve := TIdCurveNaturalCubicSpline<TIdVec3>.Create(TIdCurveVec3Arithmetic.Create);
  LVecXCurve := TIdCurveNaturalCubicSpline<TIdVecXValue>.Create(TIdCurveVecXArithmetic.Create);
  try
    for LIndex := 0 to 5 do
    begin
      LVec3Curve.AddValue(LIndex * 100.0, TIdVec3.Create(LIndex * 1.5, Sqr(LIndex) - 3.0, 2.0 - LIndex));
      LVecXCurve.AddValue(LIndex * 100.0,
        TIdVecXValue.Create(LIndex * 1.5, Sqr(LIndex) - 3.0, 2.0 - LIndex));
    end;
    for LIndex := 0 to 20 do
    begin
      LValue3 := LVec3Curve.GetCurrentValue(LIndex * 25.0);
      LValueX := LVecXCurve.GetCurrentValue(LIndex * 25.0);
      for LComponent := 0 to 2 do
      begin
        Assert.AreEqual(Double(LValue3[LComponent]), Double(LValueX[LComponent]), 1E-5);
      end;
    end;
  finally
    LVecXCurve.Free;
    LVec3Curve.Free;
  end;
end;

procedure TTestInterpolateValues.LAritmeticaDeiVettoriDiQualsiasiDimensioneDovrebbeSommareESottrarre;
var
  LArithmetic: IIdCurveArithmetic<TIdVecXValue>;
  LA, LB, LResult: TIdVecXValue;
begin
  LArithmetic := TIdCurveVecXArithmetic.Create;
  LA := TIdVecXValue.Create(1.0, 2.0, 3.0, 4.0);
  LB := TIdVecXValue.Create(0.5, 0.5, 0.5, 0.5);
  LResult := LArithmetic.Add(LA, LB);
  Assert.AreEqual<Integer>(4, Length(LResult));
  Assert.AreEqual(1.5, LResult[0], Eps);
  LResult := LArithmetic.Subtract(LA, LB);
  Assert.AreEqual(3.5, LResult[3], Eps);
  LResult := LArithmetic.Multiply(LA, 2.0);
  Assert.AreEqual(6.0, LResult[2], Eps);
  LResult := LArithmetic.Divide(LA, 4.0);
  Assert.AreEqual(0.5, LResult[1], Eps);
  Assert.AreEqual(4, LArithmetic.GetDimension(LA));
  Assert.AreEqual(3.0, LArithmetic.GetComponent(LA, 2), Eps);
  LArithmetic.SetComponent(LA, 2, 9.0);
  Assert.AreEqual(9.0, LA[2], Eps);
end;

procedure TTestInterpolateValues.LAritmeticaDeiVettoriDiQualsiasiDimensioneDovrebbeRifiutareDimensioniDiverse;
var
  LArithmetic: IIdCurveArithmetic<TIdVecXValue>;
begin
  LArithmetic := TIdCurveVecXArithmetic.Create;
  Assert.WillRaise(
    procedure
    begin
      LArithmetic.Add(TIdVecXValue.Create(1.0), TIdVecXValue.Create(1.0, 2.0));
    end, EArgumentException);
  Assert.WillRaise(
    procedure
    begin
      LArithmetic.Subtract(TIdVecXValue.Create(1.0), TIdVecXValue.Create(1.0, 2.0));
    end, EArgumentException);
end;

end.
