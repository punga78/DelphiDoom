{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ODE solvers of id Tech 4 - parity with the C++     }
{  idLib                                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Ode.Parity;

{$Q-}
{$R-}

interface

uses
  System.Classes, System.Math, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the real idODE classes of Doom 3 (Tests\Data\MathCore\ode.golden.txt: lines
  ///   written by idODE_Euler, idODE_Midpoint, idODE_RK4 and idODE_RK4Adaptive compiled with
  ///   bcc32c on the x87, "name system steps h t0 maxError dim state | step state...", four
  ///   small systems with polynomial derivatives). Every line is recomputed from its own inputs.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestOdeParity = class(TObject)
  private
    FLines: TStringList;
    FOldMask: TArithmeticExceptionMask;
    procedure Run(const AName: string; const AMaxUlps: Integer; const AAbsTolerance: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure EulerDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure IlPuntoMedioDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure RungeKutta4DovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure RungeKutta4AdattivoDovrebbeDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Float.Ode.Intf, DelphiDoom.MathCore.Float.Ode.Euler,
  DelphiDoom.MathCore.Float.Ode.Midpoint, DelphiDoom.MathCore.Float.Ode.RK4,
  DelphiDoom.MathCore.Float.Ode.RK4Adaptive, DelphiDoom.Tests.IdLib.Golden,
  DelphiDoom.Tests.MathCore.GoldenLines;

const
  // the float constants of the C++ derivatives
  K_DECAY: Single = 0.7;
  K_SPRING: Single = 4.0;
  K_FRICTION: Single = 0.1;
  K_COUPLING: Single = 0.3;
  K_DRIVE: Single = 0.1;
  K_PRODUCT: Single = 0.05;
  K_STIFF: Single = 50.0;

function DeriveFor(const ASystem: Integer): TIdOdeDeriveProc;
begin
  case ASystem of
    0:
      Result :=
        procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
        begin
          ADerivatives[0] := -K_DECAY * AState[0];
        end;
    1:
      Result :=
        procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
        begin
          ADerivatives[0] := AState[1];
          ADerivatives[1] := -K_SPRING * AState[0] - K_FRICTION * AState[1];
        end;
    2:
      Result :=
        procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
        var
          LProduct: Single;
        begin
          ADerivatives[0] := AState[1] - K_COUPLING * AState[0];
          ADerivatives[1] := K_DRIVE * ATime - AState[0];
          LProduct := K_PRODUCT * AState[0];
          LProduct := LProduct * AState[1];
          ADerivatives[2] := LProduct - AState[2];
        end;
  else
    Result :=
      procedure(const ATime: Single; const AState: TArray<Single>; var ADerivatives: TArray<Single>)
      begin
        ADerivatives[0] := -K_STIFF * (AState[0] - ATime);
      end;
  end;
end;

function ComputeLine(const ALine: string): string;
var
  LReader: TGoldenLineReader;
  LName: string;
  LSystem, LSteps, LDimension, LIndex, LStep: Integer;
  LStepSize, LTime0, LMaxError, LTime, LTime1, LReturned: Single;
  LState, LNewState: TArray<Single>;
  LSolver: IIdOde;
  LAdaptive: TIdOdeRK4Adaptive;
  LMethod: string;
begin
  LReader.Start(ALine);
  LName := LReader.Tokens[0];
  LMethod := Copy(LName, 5, MaxInt);
  LSystem := LReader.Int;
  LSteps := LReader.Int;
  LStepSize := LReader.Float;
  LTime0 := LReader.Float;
  LMaxError := LReader.Float;
  LDimension := LReader.Int;
  SetLength(LState, LDimension);
  SetLength(LNewState, LDimension);
  Result := TGoldenLines.HeadOf(ALine);
  for LIndex := 0 to LDimension - 1 do
    LState[LIndex] := LReader.Float;

  if LMethod = 'euler' then
    LSolver := TIdOdeEuler.Create(LDimension, DeriveFor(LSystem))
  else if LMethod = 'mid' then
    LSolver := TIdOdeMidpoint.Create(LDimension, DeriveFor(LSystem))
  else if LMethod = 'rk4' then
    LSolver := TIdOdeRK4.Create(LDimension, DeriveFor(LSystem))
  else
  begin
    LAdaptive := TIdOdeRK4Adaptive.Create(LDimension, DeriveFor(LSystem));
    LSolver := LAdaptive;
    LAdaptive.SetMaxError(LMaxError);
  end;

  LTime := LTime0;
  for LStep := 1 to LSteps do
  begin
    LTime1 := LTime + LStepSize;
    LReturned := LSolver.Evaluate(LState, LNewState, LTime, LTime1);
    TGoldenLines.PutFloat(Result, LReturned);
    for LIndex := 0 to LDimension - 1 do
    begin
      TGoldenLines.PutFloat(Result, LNewState[LIndex]);
      LState[LIndex] := LNewState[LIndex];
    end;
    LTime := LTime + LReturned;
  end;
end;

{ TTestOdeParity }

procedure TTestOdeParity.Setup;
begin
  // the C++ divides by zero without traps: mask the FPU exceptions
  FOldMask := SetExceptionMask(exAllArithmeticExceptions);
  FLines := TStringList.Create;
  FLines.LoadFromFile(TIdLibGolden.DataPath('..\MathCore\ode.golden.txt'));
end;

procedure TTestOdeParity.TearDown;
begin
  SetExceptionMask(FOldMask);
  FLines.Free;
end;

procedure TTestOdeParity.Run(const AName: string; const AMaxUlps: Integer;
  const AAbsTolerance: Single);
var
  LIndex: Integer;
  LActual, LExpected: TStringList;
begin
  LActual := TStringList.Create;
  LExpected := TStringList.Create;
  try
    for LIndex := 0 to FLines.Count - 1 do
      if FLines[LIndex].StartsWith(AName + ' ') then
      begin
        LExpected.Add(FLines[LIndex]);
        LActual.Add(ComputeLine(FLines[LIndex]));
      end;
    Assert.IsTrue(LExpected.Count > 0, 'nessuna riga nel golden');
    TGoldenLines.Compare(LExpected, LActual, AMaxUlps, AAbsTolerance);
  finally
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestOdeParity.EulerDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('ODE_euler', 2, 1E-5);
end;

procedure TTestOdeParity.IlPuntoMedioDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('ODE_mid', 2, 1E-5);
end;

procedure TTestOdeParity.RungeKutta4DovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('ODE_rk4', 2, 1E-5);
end;

procedure TTestOdeParity.RungeKutta4AdattivoDovrebbeDareLeStesseRispostePerIlCpp;
begin
  // the number of halvings and the returned step depend on a comparison of the error with the
  // limit: the lines are compared with the same tolerance, they are far from the limit
  Run('ODE_rk4a', 2, 1E-5);
end;

end.
