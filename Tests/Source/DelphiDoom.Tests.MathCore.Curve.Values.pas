{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the curves of id Tech 4 - values computed by hand,      }
{  limit cases                                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Curve.Values;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>Values of the curves that can be computed by hand, and the contract of the classes</summary>
  [TestFixture]
  [Category('mathcore')]
  TTestCurveValues = class(TObject)
  private
    procedure CheckNear(const AExpected, AActual, ATolerance: Double; const AMessage: string = '');
  public
    [Test]
    procedure LeDimensioniDeiTipiDovrebberoEssereQuelleDelCpp;
    [Test]
    procedure UnaAritmeticaNullaDovrebbeSollevareUnErrore;
    [Test]
    procedure LeAritmeticheDovrebberoDareLeOperazioniDelTipo;
    [Test]
    procedure LAritmeticaScalareDovrebbeAvereUnaSolaComponente;
    [Test]
    procedure UnaCurvaDovrebbeTenereIPuntiInOrdineDiTempo;
    [Test]
    procedure UnaCurvaBaseDovrebbeEssereUnaFunzioneAGradini;
    [Test]
    procedure LeDerivateDiUnaCurvaBaseDovrebberoEssereNulle;
    [Test]
    procedure UnaCurvaDovrebbeFinireQuandoIlTempoNonPrecedeLUltimoPunto;
    [Test]
    procedure RimuovereEPulireUnaCurvaDovrebbeAggiornareIPunti;
    [Test]
    procedure ShiftTranslateEMakeUniformDovrebberoModificarePuntiETempi;
    [Test]
    procedure UnaBezierDiGradoUnoDovrebbeInterpolareLinearmente;
    [Test]
    procedure UnaBezierDiGradoTreDovrebbeAvereLaFormaDiBernstein;
    [Test]
    procedure LaBezierQuadraticaDovrebbeDareIValoriDiBernstein;
    [Test]
    procedure LaBezierCubicaConPuntiAllineatiDovrebbeEssereUnaRetta;
    [Test]
    procedure LeBezierDiGradoFissoDovrebberoVerificareIlNumeroDiPunti;
    [Test]
    procedure LaCatmullRomDovrebbePassareDaiPunti;
    [Test]
    procedure LaCatmullRomSuPuntiAllineatiDovrebbeEssereUnaRetta;
    [Test]
    procedure IlBordoVincolatoDovrebbeFermareIlTempoAgliEstremi;
    [Test]
    procedure IlBordoChiusoNonDovrebbeEssereMaiFinito;
    [Test]
    procedure IlTempoDiChiusuraDovrebbeValereZeroSeIlBordoNonEChiuso;
    [Test]
    procedure KochanekBartelsSenzaParametriDovrebbeEssereLaCatmullRom;
    [Test]
    procedure LeBSplineUniformiConPuntiCostantiDovrebberoDareLaCostante;
    [Test]
    procedure LaBSplineNonUniformeDovrebbeAvereUnaPartizioneDellUnita;
    [Test]
    procedure LaNurbsConPesiUgualiDovrebbeEssereUnaBSplineNonUniforme;
    [Test]
    procedure LaNurbsDovrebbeTenerePesiEPuntiAllineatiDopoUnaRimozione;
    [Test]
    procedure UnOrdineFuoriDaUnoANoveDovrebbeSollevareUnErrore;
    [Test]
    procedure LaSplineNaturaleDovrebbePassareDaiPunti;
    [Test]
    procedure LaSplineNaturaleDovrebbeRicalcolareIPolinomiDopoUnaModifica;
    [Test]
    procedure LaSplineNaturaleChiusaDovrebbeRisolvereIlSistema;
    [Test]
    procedure IlRisolutoreLuDovrebbeRisolvereUnSistemaNoto;
    [Test]
    procedure IlRisolutoreLuDovrebbeSegnalareUnPivotNullo;
    [Test]
    procedure LaLunghezzaDiUnSegmentoDovrebbeEssereLaDistanza;
    [Test]
    procedure LaLunghezzaDiUnaCurvaScalareDovrebbeEssereLaDifferenza;
    [Test]
    procedure IlTempoPerUnaLunghezzaDovrebbeInvertireLaLunghezzaPerTempo;
    [Test]
    procedure LaVelocitaCostanteDovrebbeDistribuireITempiSullaLunghezza;
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.MathCore.Float.Curve.Types,
  DelphiDoom.MathCore.Float.Curve.Intf, DelphiDoom.MathCore.Float.Curve,
  DelphiDoom.MathCore.Float.Curve.Bezier, DelphiDoom.MathCore.Float.Curve.QuadraticBezier,
  DelphiDoom.MathCore.Float.Curve.CubicBezier, DelphiDoom.MathCore.Float.Curve.Spline,
  DelphiDoom.MathCore.Float.Curve.LuSolver, DelphiDoom.MathCore.Float.Curve.NaturalCubicSpline,
  DelphiDoom.MathCore.Float.Curve.CatmullRomSpline,
  DelphiDoom.MathCore.Float.Curve.KochanekBartelsSpline, DelphiDoom.MathCore.Float.Curve.BSpline,
  DelphiDoom.MathCore.Float.Curve.UniformCubicBSpline,
  DelphiDoom.MathCore.Float.Curve.NonUniformBSpline, DelphiDoom.MathCore.Float.Curve.NURBS,
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Scalar, DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec2,
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec3, DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec4;

procedure TTestCurveValues.CheckNear(const AExpected, AActual, ATolerance: Double;
  const AMessage: string);
begin
  Assert.IsTrue(System.Abs(AExpected - AActual) <= ATolerance,
    Format('%s atteso %g, ottenuto %g', [AMessage, AExpected, AActual]));
end;

function Scalar: IIdCurveArithmetic<Single>;
begin
  Result := TIdCurveScalarArithmetic.Create;
end;

function Space: IIdCurveArithmetic<TIdVec3>;
begin
  Result := TIdCurveVec3Arithmetic.Create;
end;

procedure TTestCurveValues.LeDimensioniDeiTipiDovrebberoEssereQuelleDelCpp;
begin
  Assert.AreEqual(8, SizeOf(TIdVec2), 'idVec2');
  Assert.AreEqual(12, SizeOf(TIdVec3), 'idVec3');
  Assert.AreEqual(16, SizeOf(TIdVec4), 'idVec4');
  Assert.AreEqual(16, SizeOf(TIdCurveBasis4), 'float bvals[4]');
end;

procedure TTestCurveValues.UnaAritmeticaNullaDovrebbeSollevareUnErrore;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdCurve<Single>.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestCurveValues.LeAritmeticheDovrebberoDareLeOperazioniDelTipo;
var
  LVec2: IIdCurveArithmetic<TIdVec2>;
  LVec3: IIdCurveArithmetic<TIdVec3>;
  LVec4: IIdCurveArithmetic<TIdVec4>;
  LA3, LB3, LC3: TIdVec3;
  LA2: TIdVec2;
  LA4: TIdVec4;
begin
  LVec2 := TIdCurveVec2Arithmetic.Create;
  LVec3 := TIdCurveVec3Arithmetic.Create;
  LVec4 := TIdCurveVec4Arithmetic.Create;
  Assert.AreEqual(2, LVec2.GetDimension(Default(TIdVec2)));
  Assert.AreEqual(3, LVec3.GetDimension(Default(TIdVec3)));
  Assert.AreEqual(4, LVec4.GetDimension(Default(TIdVec4)));

  LA3 := TIdVec3.Create(1, 2, 3);
  LB3 := TIdVec3.Create(10, 20, 30);
  LC3 := LVec3.Add(LA3, LB3);
  Assert.AreEqual(Single(22), LC3.Y, 'somma');
  LC3 := LVec3.Subtract(LB3, LA3);
  Assert.AreEqual(Single(27), LC3.Z, 'differenza');
  LC3 := LVec3.Multiply(LA3, 2.0);
  Assert.AreEqual(Single(6), LC3.Z, 'prodotto per uno scalare');
  LC3 := LVec3.Divide(LB3, 4.0);
  Assert.AreEqual(Single(5), LC3.Y, 'divisione');
  Assert.AreEqual(Single(2), LVec3.GetComponent(LA3, 1), 'componente');
  LVec3.SetComponent(LA3, 2, 9.0);
  Assert.AreEqual(Single(9), LA3.Z, 'componente scritta');

  LA2 := TIdVec2.Create(1, 2);
  LVec2.SetComponent(LA2, 0, 7.0);
  Assert.AreEqual(Single(7), LVec2.GetComponent(LA2, 0));
  LA4 := TIdVec4.Create(1, 2, 3, 4);
  Assert.AreEqual(Single(4), LVec4.GetComponent(LA4, 3));
  Assert.AreEqual(Single(8), LVec4.Multiply(LA4, 2.0).W, 'vettore a quattro componenti');
end;

procedure TTestCurveValues.LAritmeticaScalareDovrebbeAvereUnaSolaComponente;
var
  LArithmetic: IIdCurveArithmetic<Single>;
  LValue, LExpected: Single;
  LRaised: Boolean;
begin
  LArithmetic := Scalar;
  Assert.AreEqual(1, LArithmetic.GetDimension(0.0));
  // a Single is divided, a vector is multiplied by the reciprocal
  LExpected := 1.0;
  LExpected := LExpected / 3.0;
  Assert.AreEqual(LExpected, LArithmetic.Divide(1.0, 3.0), 'divisione');
  LValue := 1.0;
  LArithmetic.SetComponent(LValue, 0, 4.0);
  Assert.AreEqual(Single(4), LArithmetic.GetComponent(LValue, 0));
  LRaised := False;
  try
    LArithmetic.GetComponent(LValue, 1);
  except
    on EIdCurveException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'componente 1 di uno scalare');
end;

procedure TTestCurveValues.UnaCurvaDovrebbeTenereIPuntiInOrdineDiTempo;
var
  LCurve: TIdCurve<Single>;
begin
  LCurve := TIdCurve<Single>.Create(Scalar);
  try
    Assert.AreEqual(0, LCurve.AddValue(2.0, 20.0), 'primo');
    Assert.AreEqual(0, LCurve.AddValue(1.0, 10.0), 'prima del primo');
    Assert.AreEqual(2, LCurve.AddValue(3.0, 30.0), 'in fondo');
    Assert.AreEqual(1, LCurve.AddValue(1.5, 15.0), 'in mezzo');
    Assert.AreEqual(4, LCurve.GetNumValues);
    Assert.AreEqual(Single(1.0), LCurve.GetTime(0));
    Assert.AreEqual(Single(1.5), LCurve.GetTime(1));
    Assert.AreEqual(Single(15.0), LCurve.GetValue(1));
    Assert.AreEqual(Single(30.0), LCurve.GetValue(3));
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.UnaCurvaBaseDovrebbeEssereUnaFunzioneAGradini;
var
  LCurve: TIdCurve<Single>;
begin
  LCurve := TIdCurve<Single>.Create(Scalar);
  try
    LCurve.AddValue(1.0, 10.0);
    LCurve.AddValue(2.0, 20.0);
    LCurve.AddValue(3.0, 30.0);
    Assert.AreEqual(Single(10), LCurve.GetCurrentValue(0.0), 'prima del primo');
    Assert.AreEqual(Single(10), LCurve.GetCurrentValue(1.0), 'sul primo');
    Assert.AreEqual(Single(20), LCurve.GetCurrentValue(1.5), 'tra due punti: il primo non precedente');
    Assert.AreEqual(Single(30), LCurve.GetCurrentValue(3.0), 'sull''ultimo');
    Assert.AreEqual(Single(30), LCurve.GetCurrentValue(9.0), 'dopo l''ultimo');
    // the cached index must not change the answers
    Assert.AreEqual(Single(20), LCurve.GetCurrentValue(2.0), 'dopo la cache');
    Assert.AreEqual(Single(10), LCurve.GetCurrentValue(0.5), 'all''indietro');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.LeDerivateDiUnaCurvaBaseDovrebberoEssereNulle;
var
  LCurve: TIdCurve<TIdVec3>;
  LValue: TIdVec3;
begin
  LCurve := TIdCurve<TIdVec3>.Create(Space);
  try
    LCurve.AddValue(0.0, TIdVec3.Create(1, 2, 3));
    LValue := LCurve.GetCurrentFirstDerivative(0.5);
    CheckNear(0.0, System.Abs(LValue.X) + System.Abs(LValue.Y) + System.Abs(LValue.Z), 0.0, 'prima');
    LValue := LCurve.GetCurrentSecondDerivative(0.5);
    CheckNear(0.0, System.Abs(LValue.X) + System.Abs(LValue.Y) + System.Abs(LValue.Z), 0.0, 'seconda');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.UnaCurvaDovrebbeFinireQuandoIlTempoNonPrecedeLUltimoPunto;
var
  LCurve: TIdCurve<Single>;
begin
  LCurve := TIdCurve<Single>.Create(Scalar);
  try
    LCurve.AddValue(1.0, 0.0);
    LCurve.AddValue(2.0, 0.0);
    Assert.IsFalse(LCurve.IsDone(1.5));
    Assert.IsTrue(LCurve.IsDone(2.0));
    Assert.IsTrue(LCurve.IsDone(5.0));
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.RimuovereEPulireUnaCurvaDovrebbeAggiornareIPunti;
var
  LCurve: TIdCurve<Single>;
  LRaised: Boolean;
begin
  LCurve := TIdCurve<Single>.Create(Scalar);
  try
    LCurve.AddValue(1.0, 10.0);
    LCurve.AddValue(2.0, 20.0);
    LCurve.AddValue(3.0, 30.0);
    LCurve.RemoveIndex(1);
    Assert.AreEqual(2, LCurve.GetNumValues);
    Assert.AreEqual(Single(3.0), LCurve.GetTime(1));
    LCurve.SetValue(0, 99.0);
    Assert.AreEqual(Single(99), LCurve.GetValue(0));
    LCurve.Clear;
    Assert.AreEqual(0, LCurve.GetNumValues);
    Assert.AreEqual(0, LCurve.AddValue(5.0, 1.0), 'dopo la pulizia');
    LRaised := False;
    try
      LCurve.GetTime(3);
    except
      on EArgumentOutOfRangeException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'indice fuori dai punti');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.ShiftTranslateEMakeUniformDovrebberoModificarePuntiETempi;
var
  LCurve: TIdCurve<TIdVec3>;
begin
  LCurve := TIdCurve<TIdVec3>.Create(Space);
  try
    LCurve.AddValue(1.0, TIdVec3.Create(0, 0, 0));
    LCurve.AddValue(5.0, TIdVec3.Create(1, 1, 1));
    LCurve.AddValue(6.0, TIdVec3.Create(2, 2, 2));
    LCurve.ShiftTime(1.0);
    Assert.AreEqual(Single(2.0), LCurve.GetTime(0), 'ShiftTime');
    Assert.AreEqual(Single(7.0), LCurve.GetTime(2));
    LCurve.Translate(TIdVec3.Create(10, 20, 30));
    Assert.AreEqual(Single(11), LCurve.GetValue(1).X, 'Translate');
    Assert.AreEqual(Single(32), LCurve.GetValue(2).Z);
    LCurve.MakeUniform(4.0);
    Assert.AreEqual(Single(0.0), LCurve.GetTime(0), 'MakeUniform');
    Assert.AreEqual(Single(2.0), LCurve.GetTime(1));
    Assert.AreEqual(Single(4.0), LCurve.GetTime(2));
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.UnaBezierDiGradoUnoDovrebbeInterpolareLinearmente;
var
  LCurve: TIdCurveBezier<Single>;
begin
  LCurve := TIdCurveBezier<Single>.Create(Scalar);
  try
    LCurve.AddValue(0.0, 0.0);
    LCurve.AddValue(2.0, 10.0);
    CheckNear(5.0, LCurve.GetCurrentValue(1.0), 1E-6, 'valore');
    CheckNear(5.0, LCurve.GetCurrentFirstDerivative(1.0), 1E-6, 'derivata prima');
    CheckNear(0.0, LCurve.GetCurrentSecondDerivative(1.0), 1E-6, 'derivata seconda');
    CheckNear(10.0, LCurve.GetCurrentValue(2.0), 1E-6, 'ultimo');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.UnaBezierDiGradoTreDovrebbeAvereLaFormaDiBernstein;
var
  LCurve: TIdCurveBezier<Single>;
begin
  // control points 0, 4, 8, 0 over [0, 1]: B(1/2) = (0 + 3 * 4 + 3 * 8 + 0) / 8 = 4.5
  LCurve := TIdCurveBezier<Single>.Create(Scalar);
  try
    LCurve.AddValue(0.0, 0.0);
    LCurve.AddValue(1.0 / 3.0, 4.0);
    LCurve.AddValue(2.0 / 3.0, 8.0);
    LCurve.AddValue(1.0, 0.0);
    CheckNear(4.5, LCurve.GetCurrentValue(0.5), 1E-5, 'valore');
    // B'(1/2) = 3 * ((4 - 0) + 2 * (8 - 4) + (0 - 8)) / 4 = 3 * 4 / 4 = 3
    CheckNear(3.0, LCurve.GetCurrentFirstDerivative(0.5), 1E-4, 'derivata prima');
    // B''(1/2) = 6 * ((8 - 2 * 4 + 0) + (0 - 2 * 8 + 4)) / 2 = 6 * (0 - 12) / 2 = -36
    CheckNear(-36.0, LCurve.GetCurrentSecondDerivative(0.5), 1E-3, 'derivata seconda');
    CheckNear(0.0, LCurve.GetCurrentValue(0.0), 1E-6, 'primo');
    CheckNear(0.0, LCurve.GetCurrentValue(1.0), 1E-6, 'ultimo');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.LaBezierQuadraticaDovrebbeDareIValoriDiBernstein;
var
  LCurve: TIdCurveQuadraticBezier<Single>;
begin
  // points 0, 4, 0 over [0, 2]: B(1) = (0 + 2 * 4 + 0) / 4 = 2, B' = 0, B'' = (0 - 8 + 0) / 4 = -2
  LCurve := TIdCurveQuadraticBezier<Single>.Create(Scalar);
  try
    LCurve.AddValue(0.0, 0.0);
    LCurve.AddValue(1.0, 4.0);
    LCurve.AddValue(2.0, 0.0);
    CheckNear(2.0, LCurve.GetCurrentValue(1.0), 1E-6, 'valore');
    CheckNear(0.0, LCurve.GetCurrentFirstDerivative(1.0), 1E-6, 'derivata prima');
    CheckNear(-4.0, LCurve.GetCurrentSecondDerivative(1.0), 1E-6, 'derivata seconda');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.LaBezierCubicaConPuntiAllineatiDovrebbeEssereUnaRetta;
var
  LCurve: TIdCurveCubicBezier<Single>;
begin
  LCurve := TIdCurveCubicBezier<Single>.Create(Scalar);
  try
    LCurve.AddValue(0.0, 0.0);
    LCurve.AddValue(1.0, 1.0);
    LCurve.AddValue(2.0, 2.0);
    LCurve.AddValue(3.0, 3.0);
    CheckNear(1.25, LCurve.GetCurrentValue(1.25), 1E-5, 'valore');
    CheckNear(1.0, LCurve.GetCurrentFirstDerivative(1.25), 1E-5, 'derivata prima');
    CheckNear(0.0, LCurve.GetCurrentSecondDerivative(1.25), 1E-5, 'derivata seconda');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.LeBezierDiGradoFissoDovrebberoVerificareIlNumeroDiPunti;
var
  LQuadratic: TIdCurveQuadraticBezier<Single>;
  LCubic: TIdCurveCubicBezier<Single>;
  LRaised: Boolean;
begin
  LQuadratic := TIdCurveQuadraticBezier<Single>.Create(Scalar);
  LCubic := TIdCurveCubicBezier<Single>.Create(Scalar);
  try
    LQuadratic.AddValue(0.0, 0.0);
    LQuadratic.AddValue(1.0, 1.0);
    LCubic.AddValue(0.0, 0.0);
    LCubic.AddValue(1.0, 1.0);
    LCubic.AddValue(2.0, 1.0);
    LRaised := False;
    try
      LQuadratic.GetCurrentValue(0.5);
    except
      on EIdCurveException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'quadratica con due punti');
    LRaised := False;
    try
      LCubic.GetCurrentFirstDerivative(0.5);
    except
      on EIdCurveException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'cubica con tre punti');
  finally
    LCubic.Free;
    LQuadratic.Free;
  end;
end;

procedure TTestCurveValues.LaCatmullRomDovrebbePassareDaiPunti;
var
  LCurve: TIdCurveCatmullRomSpline<TIdVec3>;
  LIndex: Integer;
  LValue: TIdVec3;
begin
  LCurve := TIdCurveCatmullRomSpline<TIdVec3>.Create(Space);
  try
    LCurve.AddValue(0.0, TIdVec3.Create(0, 0, 0));
    LCurve.AddValue(1.0, TIdVec3.Create(1, 5, -2));
    LCurve.AddValue(2.5, TIdVec3.Create(4, 2, 7));
    LCurve.AddValue(3.0, TIdVec3.Create(-3, 1, 1));
    LCurve.AddValue(4.0, TIdVec3.Create(2, 2, 2));
    for LIndex := 0 to LCurve.GetNumValues - 1 do
    begin
      LValue := LCurve.GetCurrentValue(LCurve.GetTime(LIndex));
      CheckNear(LCurve.GetValue(LIndex).X, LValue.X, 1E-5, 'X del punto ' + IntToStr(LIndex));
      CheckNear(LCurve.GetValue(LIndex).Y, LValue.Y, 1E-5, 'Y del punto ' + IntToStr(LIndex));
      CheckNear(LCurve.GetValue(LIndex).Z, LValue.Z, 1E-5, 'Z del punto ' + IntToStr(LIndex));
    end;
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.LaCatmullRomSuPuntiAllineatiDovrebbeEssereUnaRetta;
var
  LCurve: TIdCurveCatmullRomSpline<Single>;
begin
  LCurve := TIdCurveCatmullRomSpline<Single>.Create(Scalar);
  try
    LCurve.AddValue(0.0, 0.0);
    LCurve.AddValue(1.0, 2.0);
    LCurve.AddValue(2.0, 4.0);
    LCurve.AddValue(3.0, 6.0);
    LCurve.AddValue(4.0, 8.0);
    CheckNear(5.0, LCurve.GetCurrentValue(2.5), 1E-5, 'valore');
    CheckNear(2.0, LCurve.GetCurrentFirstDerivative(2.5), 1E-5, 'derivata prima');
    CheckNear(0.0, LCurve.GetCurrentSecondDerivative(2.5), 1E-5, 'derivata seconda');
    // a free curve goes on along the last segment
    CheckNear(10.0, LCurve.GetCurrentValue(5.0), 1E-4, 'estrapolazione');
    CheckNear(-2.0, LCurve.GetCurrentValue(-1.0), 1E-4, 'prima del primo');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.IlBordoVincolatoDovrebbeFermareIlTempoAgliEstremi;
var
  LCurve: TIdCurveCatmullRomSpline<Single>;
begin
  LCurve := TIdCurveCatmullRomSpline<Single>.Create(Scalar);
  try
    LCurve.AddValue(0.0, 1.0);
    LCurve.AddValue(1.0, 3.0);
    LCurve.AddValue(2.0, 2.0);
    LCurve.AddValue(3.0, 7.0);
    LCurve.BoundaryType := TIdCurveBoundary.Clamped;
    CheckNear(7.0, LCurve.GetCurrentValue(10.0), 1E-5, 'dopo l''ultimo');
    CheckNear(1.0, LCurve.GetCurrentValue(-5.0), 1E-5, 'prima del primo');
    Assert.IsTrue(LCurve.IsDone(3.0), 'finita');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.IlBordoChiusoNonDovrebbeEssereMaiFinito;
var
  LCurve: TIdCurveCatmullRomSpline<Single>;
begin
  LCurve := TIdCurveCatmullRomSpline<Single>.Create(Scalar);
  try
    LCurve.AddValue(0.0, 1.0);
    LCurve.AddValue(1.0, 3.0);
    LCurve.AddValue(2.0, 2.0);
    LCurve.AddValue(3.0, 7.0);
    LCurve.AddValue(4.0, 5.0);
    LCurve.AddValue(5.0, 4.0);
    LCurve.AddValue(6.0, 3.0);
    LCurve.BoundaryType := TIdCurveBoundary.Closed;
    LCurve.CloseTime := 1.0;
    Assert.IsFalse(LCurve.IsDone(100.0));
    Assert.AreEqual(TIdCurveBoundary.Closed, LCurve.GetBoundaryType);
    // the closing segment goes from the last knot to the first one, one close time later
    CheckNear(3.0, LCurve.GetCurrentValue(6.0), 1E-4, 'ultimo punto');
    CheckNear(1.0, LCurve.GetCurrentValue(7.0), 1E-4, 'primo punto, dopo il tempo di chiusura');
    Assert.IsTrue(System.Abs(LCurve.GetCurrentValue(6.5)) < 50.0, 'segmento di chiusura');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.IlTempoDiChiusuraDovrebbeValereZeroSeIlBordoNonEChiuso;
var
  LCurve: TIdCurveCatmullRomSpline<Single>;
begin
  LCurve := TIdCurveCatmullRomSpline<Single>.Create(Scalar);
  try
    LCurve.CloseTime := 2.5;
    Assert.AreEqual(Single(0.0), LCurve.CloseTime, 'libero');
    LCurve.BoundaryType := TIdCurveBoundary.Closed;
    Assert.AreEqual(Single(2.5), LCurve.CloseTime, 'chiuso');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.KochanekBartelsSenzaParametriDovrebbeEssereLaCatmullRom;
var
  LKochanek: TIdCurveKochanekBartelsSpline<TIdVec3>;
  LCatmull: TIdCurveCatmullRomSpline<TIdVec3>;
  LValues: array[0..4] of TIdVec3;
  LIndex: Integer;
  LTime: Single;
  LA, LB: TIdVec3;
begin
  LKochanek := TIdCurveKochanekBartelsSpline<TIdVec3>.Create(Space);
  LCatmull := TIdCurveCatmullRomSpline<TIdVec3>.Create(Space);
  try
    LValues[0] := TIdVec3.Create(0, 0, 0);
    LValues[1] := TIdVec3.Create(1, 5, -2);
    LValues[2] := TIdVec3.Create(4, 2, 7);
    LValues[3] := TIdVec3.Create(-3, 1, 1);
    LValues[4] := TIdVec3.Create(2, 2, 2);
    for LIndex := 0 to 4 do
    begin
      LKochanek.AddValue(LIndex, LValues[LIndex]);
      LCatmull.AddValue(LIndex, LValues[LIndex]);
    end;
    for LIndex := 1 to 7 do
    begin
      LTime := LIndex * 0.5;
      LA := LKochanek.GetCurrentValue(LTime);
      LB := LCatmull.GetCurrentValue(LTime);
      CheckNear(LB.X, LA.X, 1E-4, 'X a ' + FloatToStr(LTime));
      CheckNear(LB.Y, LA.Y, 1E-4, 'Y a ' + FloatToStr(LTime));
      CheckNear(LB.Z, LA.Z, 1E-4, 'Z a ' + FloatToStr(LTime));
    end;
  finally
    LCatmull.Free;
    LKochanek.Free;
  end;
end;

procedure TTestCurveValues.LeBSplineUniformiConPuntiCostantiDovrebberoDareLaCostante;
var
  LUniform: TIdCurveUniformCubicBSpline<Single>;
  LRecursive: TIdCurveBSpline<Single>;
  LIndex: Integer;
begin
  LUniform := TIdCurveUniformCubicBSpline<Single>.Create(Scalar);
  LRecursive := TIdCurveBSpline<Single>.Create(Scalar);
  try
    for LIndex := 0 to 6 do
    begin
      LUniform.AddValue(LIndex, 5.0);
      LRecursive.AddValue(LIndex, 5.0);
    end;
    CheckNear(5.0, LUniform.GetCurrentValue(2.4), 1E-5, 'uniforme');
    CheckNear(0.0, LUniform.GetCurrentFirstDerivative(2.4), 1E-5, 'uniforme, derivata prima');
    CheckNear(0.0, LUniform.GetCurrentSecondDerivative(2.4), 1E-5, 'uniforme, derivata seconda');
    CheckNear(5.0, LRecursive.GetCurrentValue(2.4), 1E-5, 'ricorsiva');
    Assert.AreEqual(4, LRecursive.Order, 'cubica per predefinizione');
    Assert.AreEqual(4, LUniform.Order, 'sempre cubica');
  finally
    LRecursive.Free;
    LUniform.Free;
  end;
end;

procedure TTestCurveValues.LaBSplineNonUniformeDovrebbeAvereUnaPartizioneDellUnita;
var
  LCurve: TIdCurveNonUniformBSpline<Single>;
  LOrder, LIndex: Integer;
begin
  LCurve := TIdCurveNonUniformBSpline<Single>.Create(Scalar);
  try
    LCurve.AddValue(0.0, 3.0);
    LCurve.AddValue(0.7, 3.0);
    LCurve.AddValue(1.1, 3.0);
    LCurve.AddValue(2.0, 3.0);
    LCurve.AddValue(2.2, 3.0);
    LCurve.AddValue(3.5, 3.0);
    LCurve.AddValue(4.0, 3.0);
    LCurve.AddValue(5.0, 3.0);
    for LOrder := 2 to 6 do
    begin
      LCurve.Order := LOrder;
      for LIndex := 0 to 6 do
        CheckNear(3.0, LCurve.GetCurrentValue(0.5 + LIndex * 0.6), 1E-5,
          Format('ordine %d, tempo %d', [LOrder, LIndex]));
    end;
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.LaNurbsConPesiUgualiDovrebbeEssereUnaBSplineNonUniforme;
var
  LNurbs: TIdCurveNURBS<TIdVec3>;
  LNubs: TIdCurveNonUniformBSpline<TIdVec3>;
  LTimes: array[0..5] of Single;
  LValues: array[0..5] of TIdVec3;
  LIndex: Integer;
  LTime: Single;
  LA, LB: TIdVec3;
begin
  LNurbs := TIdCurveNURBS<TIdVec3>.Create(Space);
  LNubs := TIdCurveNonUniformBSpline<TIdVec3>.Create(Space);
  try
    LTimes[0] := 0.0; LTimes[1] := 0.8; LTimes[2] := 1.5; LTimes[3] := 2.1; LTimes[4] := 3.0;
    LTimes[5] := 4.0;
    for LIndex := 0 to 5 do
    begin
      LValues[LIndex] := TIdVec3.Create(LIndex * LIndex, 5 - LIndex, LIndex * 0.5);
      LNurbs.AddValue(LTimes[LIndex], LValues[LIndex], 2.0);
      LNubs.AddValue(LTimes[LIndex], LValues[LIndex]);
    end;
    for LIndex := 1 to 8 do
    begin
      LTime := LIndex * 0.45;
      LA := LNurbs.GetCurrentValue(LTime);
      LB := LNubs.GetCurrentValue(LTime);
      CheckNear(LB.X, LA.X, 1E-4, 'X a ' + FloatToStr(LTime));
      CheckNear(LB.Y, LA.Y, 1E-4, 'Y a ' + FloatToStr(LTime));
      CheckNear(LB.Z, LA.Z, 1E-4, 'Z a ' + FloatToStr(LTime));
    end;
  finally
    LNubs.Free;
    LNurbs.Free;
  end;
end;

procedure TTestCurveValues.LaNurbsDovrebbeTenerePesiEPuntiAllineatiDopoUnaRimozione;
var
  LCurve: TIdCurveNURBS<Single>;
  LIndex: Integer;
begin
  LCurve := TIdCurveNURBS<Single>.Create(Scalar);
  try
    for LIndex := 0 to 6 do
      LCurve.AddValue(LIndex, 4.0, 1.0 + LIndex * 0.1);
    LCurve.RemoveIndex(3);
    Assert.AreEqual(6, LCurve.GetNumValues);
    CheckNear(4.0, LCurve.GetCurrentValue(2.5), 1E-5, 'costante con pesi diversi');
    LCurve.Clear;
    Assert.AreEqual(0, LCurve.GetNumValues);
    LCurve.AddValue(0.0, 1.0);
    LCurve.AddValue(1.0, 1.0);
    LCurve.AddValue(2.0, 1.0);
    LCurve.AddValue(3.0, 1.0);
    CheckNear(1.0, LCurve.GetCurrentValue(1.5), 1E-5, 'dopo Clear, peso uno');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.UnOrdineFuoriDaUnoANoveDovrebbeSollevareUnErrore;
var
  LCurve: TIdCurveBSpline<Single>;
  LRaised: Boolean;
begin
  LCurve := TIdCurveBSpline<Single>.Create(Scalar);
  try
    LCurve.Order := 9;
    Assert.AreEqual(9, LCurve.Order);
    LRaised := False;
    try
      LCurve.Order := 10;
    except
      on EIdCurveException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'ordine 10');
    LRaised := False;
    try
      LCurve.Order := 0;
    except
      on EIdCurveException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'ordine 0');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.LaSplineNaturaleDovrebbePassareDaiPunti;
var
  LCurve: TIdCurveNaturalCubicSpline<TIdVec3>;
  LIndex: Integer;
  LValue: TIdVec3;
begin
  LCurve := TIdCurveNaturalCubicSpline<TIdVec3>.Create(Space);
  try
    LCurve.AddValue(0.0, TIdVec3.Create(0, 0, 0));
    LCurve.AddValue(1.0, TIdVec3.Create(1, 5, -2));
    LCurve.AddValue(2.5, TIdVec3.Create(4, 2, 7));
    LCurve.AddValue(3.0, TIdVec3.Create(-3, 1, 1));
    LCurve.AddValue(4.0, TIdVec3.Create(2, 2, 2));
    // up to the last but one knot the original defines the answers
    for LIndex := 0 to LCurve.GetNumValues - 2 do
    begin
      LValue := LCurve.GetCurrentValue(LCurve.GetTime(LIndex));
      CheckNear(LCurve.GetValue(LIndex).X, LValue.X, 1E-5, 'X del punto ' + IntToStr(LIndex));
      CheckNear(LCurve.GetValue(LIndex).Z, LValue.Z, 1E-5, 'Z del punto ' + IntToStr(LIndex));
    end;
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.LaSplineNaturaleDovrebbeRicalcolareIPolinomiDopoUnaModifica;
var
  LEdited, LFresh: TIdCurveNaturalCubicSpline<TIdVec3>;
  LBefore, LAfter, LExpected: TIdVec3;
begin
  LEdited := TIdCurveNaturalCubicSpline<TIdVec3>.Create(Space);
  LFresh := TIdCurveNaturalCubicSpline<TIdVec3>.Create(Space);
  try
    LEdited.AddValue(0.0, TIdVec3.Create(0, 0, 0));
    LEdited.AddValue(1.0, TIdVec3.Create(1, 5, -2));
    LEdited.AddValue(2.0, TIdVec3.Create(4, 2, 7));
    LEdited.AddValue(3.0, TIdVec3.Create(-3, 1, 1));
    LEdited.AddValue(4.0, TIdVec3.Create(2, 2, 2));
    LBefore := LEdited.GetCurrentValue(1.5);
    LEdited.SetValue(3, TIdVec3.Create(8, 8, 8));
    LAfter := LEdited.GetCurrentValue(1.5);

    LFresh.AddValue(0.0, TIdVec3.Create(0, 0, 0));
    LFresh.AddValue(1.0, TIdVec3.Create(1, 5, -2));
    LFresh.AddValue(2.0, TIdVec3.Create(4, 2, 7));
    LFresh.AddValue(3.0, TIdVec3.Create(8, 8, 8));
    LFresh.AddValue(4.0, TIdVec3.Create(2, 2, 2));
    LExpected := LFresh.GetCurrentValue(1.5);

    Assert.IsTrue(System.Abs(LBefore.X - LAfter.X) > 1E-3, 'il valore deve cambiare');
    CheckNear(LExpected.X, LAfter.X, 1E-5, 'X');
    CheckNear(LExpected.Y, LAfter.Y, 1E-5, 'Y');
    CheckNear(LExpected.Z, LAfter.Z, 1E-5, 'Z');
  finally
    LFresh.Free;
    LEdited.Free;
  end;
end;

procedure TTestCurveValues.LaSplineNaturaleChiusaDovrebbeRisolvereIlSistema;
var
  LCurve: TIdCurveNaturalCubicSpline<Single>;
  LIndex: Integer;
  LValue: Single;
begin
  // a closed curve: knots on a period of 6 (5 knots plus the closing time)
  LCurve := TIdCurveNaturalCubicSpline<Single>.Create(Scalar);
  try
    for LIndex := 0 to 5 do
      LCurve.AddValue(LIndex, 2.0);
    LCurve.BoundaryType := TIdCurveBoundary.Closed;
    LCurve.CloseTime := 1.0;
    // constant values: the second derivatives c are all zero, so the curve is the constant
    for LIndex := 0 to 3 do
    begin
      LValue := LCurve.GetCurrentValue(LIndex + 0.5);
      CheckNear(2.0, LValue, 1E-5, 'costante a ' + IntToStr(LIndex));
    end;
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.IlRisolutoreLuDovrebbeRisolvereUnSistemaNoto;
var
  LMatrix, LVector: TArray<Single>;
begin
  // the classic system 4x + 3y = 24, 3x + 4y - z = 30, -y + 4z = -24: x = 3, y = 4, z = -5
  LMatrix := [4, 3, 0, 3, 4, -1, 0, -1, 4];
  LVector := [24, 30, -24];
  Assert.IsTrue(TIdCurveLuSolver.Factor(LMatrix, 3), 'fattorizzazione');
  TIdCurveLuSolver.Solve(LMatrix, 3, LVector);
  CheckNear(3.0, LVector[0], 1E-5, 'x');
  CheckNear(4.0, LVector[1], 1E-5, 'y');
  CheckNear(-5.0, LVector[2], 1E-5, 'z');
end;

procedure TTestCurveValues.IlRisolutoreLuDovrebbeSegnalareUnPivotNullo;
var
  LMatrix: TArray<Single>;
begin
  // no pivoting: a zero on the diagonal cannot be factored
  LMatrix := [0, 1, 1, 0];
  Assert.IsFalse(TIdCurveLuSolver.Factor(LMatrix, 2));
end;

procedure TTestCurveValues.LaLunghezzaDiUnSegmentoDovrebbeEssereLaDistanza;
var
  LCurve: TIdCurveBezier<TIdVec3>;
begin
  LCurve := TIdCurveBezier<TIdVec3>.Create(Space);
  try
    LCurve.AddValue(0.0, TIdVec3.Create(0, 0, 0));
    LCurve.AddValue(1.0, TIdVec3.Create(3, 4, 0));
    // idMath::Sqrt is x * InvSqrt(x), accurate to about 1e-3 of the value
    CheckNear(5.0, LCurve.GetLengthBetweenKnots(0, 1), 0.02, 'lunghezza');
    CheckNear(2.5, LCurve.GetLengthForTime(0.5), 0.02, 'lunghezza a meta''');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.LaLunghezzaDiUnaCurvaScalareDovrebbeEssereLaDifferenza;
var
  LCurve: TIdCurveBezier<Single>;
begin
  // the original cannot compile this (a float has no GetDimension); a Single has one component
  LCurve := TIdCurveBezier<Single>.Create(Scalar);
  try
    LCurve.AddValue(0.0, 0.0);
    LCurve.AddValue(2.0, 10.0);
    CheckNear(10.0, LCurve.GetLengthBetweenKnots(0, 1), 0.05, 'lunghezza');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.IlTempoPerUnaLunghezzaDovrebbeInvertireLaLunghezzaPerTempo;
var
  LCurve: TIdCurveBezier<TIdVec3>;
begin
  LCurve := TIdCurveBezier<TIdVec3>.Create(Space);
  try
    LCurve.AddValue(0.0, TIdVec3.Create(0, 0, 0));
    LCurve.AddValue(2.0, TIdVec3.Create(6, 8, 0));
    CheckNear(0.0, LCurve.GetTimeForLength(0.0, 0.001), 1E-6, 'lunghezza zero');
    CheckNear(1.0, LCurve.GetTimeForLength(5.0, 0.001), 0.01, 'meta''');
    CheckNear(2.0, LCurve.GetTimeForLength(50.0, 0.001), 1E-6, 'oltre la fine');
  finally
    LCurve.Free;
  end;
end;

procedure TTestCurveValues.LaVelocitaCostanteDovrebbeDistribuireITempiSullaLunghezza;
var
  LCurve: TIdCurveBezier<TIdVec3>;
begin
  // a quadratic Bezier on a line: x(s) = 2 s + 2 s^2 for the points 0, 1, 4, so the knot at s = 1/2 is at x = 1.5
  // of a total length 4: after SetConstantSpeed it is reached at 1.5 / 4 of the total time
  LCurve := TIdCurveBezier<TIdVec3>.Create(Space);
  try
    LCurve.AddValue(0.0, TIdVec3.Create(0, 0, 0));
    LCurve.AddValue(0.5, TIdVec3.Create(1, 0, 0));
    LCurve.AddValue(1.0, TIdVec3.Create(4, 0, 0));
    LCurve.SetConstantSpeed(8.0);
    CheckNear(0.0, LCurve.GetTime(0), 1E-6, 'primo');
    CheckNear(3.0, LCurve.GetTime(1), 0.05, 'secondo');
    CheckNear(8.0, LCurve.GetTime(2), 1E-6, 'ultimo');
  finally
    LCurve.Free;
  end;
end;

end.
