{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ODE solvers of id Tech 4 - values computed by       }
{  hand, limit cases                                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Ode.Values;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>Values of the ODE solvers that can be computed by hand, and the contract of the classes</summary>
  [TestFixture]
  [Category('mathcore')]
  TTestOdeValues = class(TObject)
  private
    procedure CheckNear(const AExpected, AActual, ATolerance: Double; const AMessage: string = '');
  public
    [Test]
    procedure EulerDovrebbeAggiungereIlPassoPerLaDerivata;
    [Test]
    procedure EulerDovrebbeChiamareLaDerivataUnaVoltaAlTempoIniziale;
    [Test]
    procedure IlPuntoMedioDovrebbeUsareLaDerivataAMetaPasso;
    [Test]
    procedure IlPuntoMedioDovrebbeChiamareLaDerivataADueTempi;
    [Test]
    procedure RungeKutta4DovrebbeDareLaSerieDiTaylorDelDecadimento;
    [Test]
    procedure RungeKutta4DovrebbeEssereEsattoPerUnPolinomioDiTerzoGrado;
    [Test]
    procedure RungeKutta4DovrebbeChiamareLaDerivataQuattroVolte;
    [Test]
    procedure RungeKutta4AdattivoDovrebbeQuadruplicareUnPassoAccettabile;
    [Test]
    procedure RungeKutta4AdattivoDovrebbeChiamareLaDerivataUndiciVolteSePassaAlPrimoTentativo;
    [Test]
    procedure RungeKutta4AdattivoDovrebbeRifiutareSempreUnaDerivataNonNulla;
    [Test]
    procedure RungeKutta4AdattivoDovrebbeAccettareUnErroreMassimoGrande;
    [Test]
    procedure ErroreMassimoDovrebbeValereUnCentesimoEIgnorareValoriNonPositivi;
    [Test]
    procedure UnSistemaDiDimensioneZeroNonDovrebbeFarNulla;
    [Test]
    procedure UnaDerivataNullaDovrebbeSollevareUnErrore;
    [Test]
    procedure UnaDimensioneNegativaDovrebbeSollevareUnErrore;
    [Test]
    procedure UnVettoreDiStatoCortoDovrebbeSollevareUnErrore;
    [Test]
    procedure PiuComponentiDovrebberoEvolversiInsieme;
    [Test]
    procedure LeInterfaccePossonoEssereUsateInsiemeAllaClasseAdattiva;
  end;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.MathCore.Float.Ode.Intf,
  DelphiDoom.MathCore.Float.Ode.Euler, DelphiDoom.MathCore.Float.Ode.Midpoint,
  DelphiDoom.MathCore.Float.Ode.RK4, DelphiDoom.MathCore.Float.Ode.RK4Adaptive;

procedure TTestOdeValues.CheckNear(const AExpected, AActual, ATolerance: Double;
  const AMessage: string);
begin
  Assert.IsTrue(System.Abs(AExpected - AActual) <= ATolerance,
    Format('%s atteso %g, ottenuto %g', [AMessage, AExpected, AActual]));
end;

function DecayDerivative: TIdOdeDeriveProc;
begin
  // y' = -y
  Result :=
    procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
    begin
      ADerivatives[0] := -AState[0];
    end;
end;

function RecordingDerivative(const ATimes: TList<Single>; const ASlope: Single): TIdOdeDeriveProc;
begin
  Result :=
    procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
    begin
      if Assigned(ATimes) then
        ATimes.Add(ATime);
      ADerivatives[0] := ASlope;
    end;
end;

function StiffDerivative: TIdOdeDeriveProc;
begin
  // y' = -50 (y - t)
  Result :=
    procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
    begin
      ADerivatives[0] := -50.0 * (AState[0] - ATime);
    end;
end;

procedure TTestOdeValues.EulerDovrebbeAggiungereIlPassoPerLaDerivata;
var
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
  LStep: Single;
begin
  LSolver := TIdOdeEuler.Create(1, RecordingDerivative(nil, 2.0));
  LState := [1.0];
  SetLength(LNewState, 1);
  LStep := LSolver.Evaluate(LState, LNewState, 0.0, 0.5);
  Assert.AreEqual(Single(0.5), LStep, 'passo');
  Assert.AreEqual(Single(2.0), LNewState[0], '1 + 0.5 * 2');
end;

procedure TTestOdeValues.EulerDovrebbeChiamareLaDerivataUnaVoltaAlTempoIniziale;
var
  LTimes: TList<Single>;
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  LTimes := TList<Single>.Create;
  try
    LSolver := TIdOdeEuler.Create(1, RecordingDerivative(LTimes, 1.0));
    LState := [0.0];
    SetLength(LNewState, 1);
    LSolver.Evaluate(LState, LNewState, 3.0, 3.25);
    Assert.AreEqual(1, LTimes.Count, 'chiamate');
    Assert.AreEqual(Single(3.0), LTimes[0], 'tempo');
  finally
    LTimes.Free;
  end;
end;

procedure TTestOdeValues.IlPuntoMedioDovrebbeUsareLaDerivataAMetaPasso;
var
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  // y' = -y, h = 0.1: y1 = 1 - h * (1 - h / 2) = 0.905
  LSolver := TIdOdeMidpoint.Create(1, DecayDerivative());
  LState := [1.0];
  SetLength(LNewState, 1);
  LSolver.Evaluate(LState, LNewState, 0.0, 0.1);
  CheckNear(0.905, LNewState[0], 1E-6);
end;

procedure TTestOdeValues.IlPuntoMedioDovrebbeChiamareLaDerivataADueTempi;
var
  LTimes: TList<Single>;
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  LTimes := TList<Single>.Create;
  try
    LSolver := TIdOdeMidpoint.Create(1, RecordingDerivative(LTimes, 1.0));
    LState := [0.0];
    SetLength(LNewState, 1);
    LSolver.Evaluate(LState, LNewState, 1.0, 2.0);
    Assert.AreEqual(2, LTimes.Count, 'chiamate');
    Assert.AreEqual(Single(1.0), LTimes[0]);
    Assert.AreEqual(Single(1.5), LTimes[1]);
  finally
    LTimes.Free;
  end;
end;

procedure TTestOdeValues.RungeKutta4DovrebbeDareLaSerieDiTaylorDelDecadimento;
var
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  // y' = -y, h = 0.1: 1 - h + h^2 / 2 - h^3 / 6 + h^4 / 24
  LSolver := TIdOdeRK4.Create(1, DecayDerivative());
  LState := [1.0];
  SetLength(LNewState, 1);
  LSolver.Evaluate(LState, LNewState, 0.0, 0.1);
  CheckNear(0.9048375, LNewState[0], 1E-6);
end;

procedure TTestOdeValues.RungeKutta4DovrebbeEssereEsattoPerUnPolinomioDiTerzoGrado;
var
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  // y' = t^3 from t = 0 to 1 gives 1/4 (Simpson's rule is exact up to the third degree)
  LSolver := TIdOdeRK4.Create(1,
    procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
    begin
      ADerivatives[0] := ATime * ATime * ATime;
    end);
  LState := [0.0];
  SetLength(LNewState, 1);
  LSolver.Evaluate(LState, LNewState, 0.0, 1.0);
  CheckNear(0.25, LNewState[0], 1E-6);
end;

procedure TTestOdeValues.RungeKutta4DovrebbeChiamareLaDerivataQuattroVolte;
var
  LTimes: TList<Single>;
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  LTimes := TList<Single>.Create;
  try
    LSolver := TIdOdeRK4.Create(1, RecordingDerivative(LTimes, 1.0));
    LState := [0.0];
    SetLength(LNewState, 1);
    LSolver.Evaluate(LState, LNewState, 0.0, 2.0);
    Assert.AreEqual(4, LTimes.Count, 'chiamate');
    Assert.AreEqual(Single(0.0), LTimes[0]);
    Assert.AreEqual(Single(1.0), LTimes[1]);
    Assert.AreEqual(Single(1.0), LTimes[2]);
    Assert.AreEqual(Single(2.0), LTimes[3]);
    Assert.AreEqual(Single(2.0), LNewState[0], 'integrale di 1');
  finally
    LTimes.Free;
  end;
end;

procedure TTestOdeValues.RungeKutta4AdattivoDovrebbeQuadruplicareUnPassoAccettabile;
var
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
  LStep: Single;
begin
  // a zero derivative has no error: the first try is accepted
  LSolver := TIdOdeRK4Adaptive.Create(1,
    procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
    begin
      ADerivatives[0] := 0.0;
    end);
  LState := [1.5];
  SetLength(LNewState, 1);
  LStep := LSolver.Evaluate(LState, LNewState, 0.0, 0.1);
  Assert.AreEqual(Single(0.4), LStep, 'il passo restituito e'' il quadruplo');
  Assert.AreEqual(Single(1.5), LNewState[0], 'lo stato non cambia');
end;

procedure TTestOdeValues.RungeKutta4AdattivoDovrebbeChiamareLaDerivataUndiciVolteSePassaAlPrimoTentativo;
var
  LTimes: TList<Single>;
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  LTimes := TList<Single>.Create;
  try
    LSolver := TIdOdeRK4Adaptive.Create(1, RecordingDerivative(LTimes, 0.0));
    LState := [0.0];
    SetLength(LNewState, 1);
    LSolver.Evaluate(LState, LNewState, 0.0, 1.0);
    Assert.AreEqual(11, LTimes.Count, 'chiamate di un tentativo');
  finally
    LTimes.Free;
  end;
end;

procedure TTestOdeValues.RungeKutta4AdattivoDovrebbeRifiutareSempreUnaDerivataNonNulla;
var
  LTimes: TList<Single>;
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
  LStep: Single;
begin
  // Defect of the original, kept: the second half step starts again from the initial state
  // instead of the midpoint, so the two half steps never agree with the full step when the
  // derivative is not zero. Every try is rejected: four tries of eleven calls, and the step
  // that comes back is the initial one divided by 4 four times (0.1 / 256).
  LTimes := TList<Single>.Create;
  try
    LSolver := TIdOdeRK4Adaptive.Create(1, RecordingDerivative(LTimes, 1.0));
    LState := [0.0];
    SetLength(LNewState, 1);
    LStep := LSolver.Evaluate(LState, LNewState, 0.0, 0.1);
    Assert.AreEqual(44, LTimes.Count, 'chiamate');
    Assert.AreEqual(Single(0.1 / 256.0), LStep, 'passo');
  finally
    LTimes.Free;
  end;
end;

procedure TTestOdeValues.RungeKutta4AdattivoDovrebbeAccettareUnErroreMassimoGrande;
var
  LSolver: IIdOdeAdaptive;
  LState, LNewState: TArray<Single>;
  LStep: Single;
begin
  // the error estimate of the broken half step is of the order of the derivative: a huge limit accepts it
  LSolver := TIdOdeRK4Adaptive.Create(1, DecayDerivative());
  LSolver.SetMaxError(1E9);
  LState := [1.0];
  SetLength(LNewState, 1);
  LStep := LSolver.Evaluate(LState, LNewState, 0.0, 0.1);
  Assert.AreEqual(Single(0.4), LStep, 'passo restituito');
end;
procedure TTestOdeValues.ErroreMassimoDovrebbeValereUnCentesimoEIgnorareValoriNonPositivi;
var
  LSolver: IIdOdeAdaptive;
begin
  LSolver := TIdOdeRK4Adaptive.Create(1, DecayDerivative());
  Assert.AreEqual(Single(0.01), LSolver.MaxError, 'predefinito');
  LSolver.SetMaxError(0.5);
  Assert.AreEqual(Single(0.5), LSolver.MaxError, 'valido');
  LSolver.SetMaxError(0.0);
  Assert.AreEqual(Single(0.5), LSolver.MaxError, 'zero ignorato');
  LSolver.SetMaxError(-1.0);
  Assert.AreEqual(Single(0.5), LSolver.MaxError, 'negativo ignorato');
end;

procedure TTestOdeValues.UnSistemaDiDimensioneZeroNonDovrebbeFarNulla;
var
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  LSolver := TIdOdeEuler.Create(0,
    procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
    begin
    end);
  Assert.AreEqual(0, LSolver.Dimension, 'dimensione');
  Assert.AreEqual(Single(0.25), LSolver.Evaluate(LState, LNewState, 1.0, 1.25), 'passo');
end;

procedure TTestOdeValues.UnaDerivataNullaDovrebbeSollevareUnErrore;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdOdeRK4.Create(1, nil);
    end, EArgumentNilException);
end;

procedure TTestOdeValues.UnaDimensioneNegativaDovrebbeSollevareUnErrore;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdOdeMidpoint.Create(-1, DecayDerivative());
    end, EArgumentOutOfRangeException);
end;

procedure TTestOdeValues.UnVettoreDiStatoCortoDovrebbeSollevareUnErrore;
var
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  LSolver := TIdOdeEuler.Create(2,
    procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
    begin
      ADerivatives[0] := 0.0;
    end);
  LState := [1.0];
  SetLength(LNewState, 2);
  Assert.WillRaise(
    procedure
    begin
      LSolver.Evaluate(LState, LNewState, 0.0, 1.0);
    end, EArgumentOutOfRangeException);
end;

procedure TTestOdeValues.PiuComponentiDovrebberoEvolversiInsieme;
var
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  // x' = v, v' = 0: x advances by v * h, v stays
  LSolver := TIdOdeRK4.Create(2,
    procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
    begin
      ADerivatives[0] := AState[1];
      ADerivatives[1] := 0.0;
    end);
  LState := [1.0, 3.0];
  SetLength(LNewState, 2);
  LSolver.Evaluate(LState, LNewState, 0.0, 0.5);
  CheckNear(2.5, LNewState[0], 1E-6, 'x');
  CheckNear(3.0, LNewState[1], 1E-6, 'v');
end;

procedure TTestOdeValues.LeInterfaccePossonoEssereUsateInsiemeAllaClasseAdattiva;
var
  LAdaptive: IIdOdeAdaptive;
  LSolver: IIdOde;
  LState, LNewState: TArray<Single>;
begin
  LAdaptive := TIdOdeRK4Adaptive.Create(1, DecayDerivative());
  LAdaptive.SetMaxError(1E9);
  LSolver := LAdaptive;
  Assert.AreEqual(1, LSolver.Dimension, 'dimensione');
  LState := [1.0];
  SetLength(LNewState, 1);
  Assert.AreEqual(Single(0.4), LSolver.Evaluate(LState, LNewState, 0.0, 0.1) , 'passo');
end;

end.