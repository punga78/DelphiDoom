{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of MathCore - parity with the C++ idLib of idExtrapolate  }
{  and idInterpolate (linear, accel/decel linear and accel/decel sine)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Interpolate.Parity;

{$Q-}
{$R-}

interface

uses
  System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the real idlib\math of Doom 3 (Tests\Data\MathCore\interp.golden.txt, 258
  ///   lines written by <c>idExtrapolate</c>, <c>idInterpolate</c>, <c>idInterpolateAccelDecelLinear</c>
  ///   and <c>idInterpolateAccelDecelSine</c> of type float and idVec3 compiled with bcc32c, harness
  ///   in Tests\Data\MathCore\harness\ext: <c>matx.exe interp</c>). Every line is recomputed from
  ///   its inputs. The sine phases and <c>cos</c>/<c>sin</c> make the tolerance a few ULPs.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestInterpolateParity = class(TObject)
  private
    FLines: TStringList;
    procedure Run(const APrefix: string; const AMaxUlps: Integer; const ARelative,
      AAbsolute: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TIdExtrapolateDiSingleDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdExtrapolateDiVettoriDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdInterpolateDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdInterpolateAccelDecelLinearDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdInterpolateAccelDecelSineDovrebbeDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Curve.Arithmetic.Scalar,
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec3, DelphiDoom.MathCore.Float.Curve.Intf,
  DelphiDoom.MathCore.Float.Extrapolate, DelphiDoom.MathCore.Float.Interpolate,
  DelphiDoom.MathCore.Float.Interpolate.AccelDecel,
  DelphiDoom.MathCore.Float.Interpolate.AccelDecelLinear,
  DelphiDoom.MathCore.Float.Interpolate.AccelDecelSine, DelphiDoom.MathCore.Float.Types,
  DelphiDoom.Tests.MathCore.Matrix.Lines;

type
  /// <summary>Makes the value of a type from its floats and writes a value on a line</summary>
  TMakeValue<T> = reference to function(const AFloats: TFloats; const AStart: Integer): T;
  TPutValue<T> = reference to procedure(var ALine: string; const AValue: T);

  TValueAdapter<T> = record
    Arithmetic: IIdCurveArithmetic<T>;
    Make: TMakeValue<T>;
    Put: TPutValue<T>;
  end;

  TParityComputer<T> = class sealed
  public
    class procedure Extrapolate(const AAdapter: TValueAdapter<T>; const AFloats: TFloats;
      var ALine: string); static;
    class procedure Interpolate(const AAdapter: TValueAdapter<T>; const AFloats: TFloats;
      var ALine: string); static;
    class procedure AccelDecel(const AAdapter: TValueAdapter<T>; const ASine: Boolean;
      const AFloats: TFloats; var ALine: string); static;
  end;

class procedure TParityComputer<T>.Extrapolate(const AAdapter: TValueAdapter<T>;
  const AFloats: TFloats; var ALine: string);
var
  LExtrapolate: TIdExtrapolate<T>;
  LKind, LIndex: Integer;
  LStart, LDuration, LTime: Single;
  LValue: T;
begin
  LKind := Round(AFloats[0]);
  LStart := AFloats[1];
  LDuration := AFloats[2];
  LExtrapolate := TIdExtrapolate<T>.Create(AAdapter.Arithmetic);
  try
    LExtrapolate.Init(LStart, LDuration, AAdapter.Make(AFloats, 3), AAdapter.Make(AFloats, 6),
      AAdapter.Make(AFloats, 9), LKind);
    for LIndex := 0 to 7 do
    begin
      LTime := AFloats[12 + LIndex];
      LValue := LExtrapolate.GetCurrentValue(LTime);
      AAdapter.Put(ALine, LValue);
      LValue := LExtrapolate.GetCurrentValue(LTime);
      AAdapter.Put(ALine, LValue);
      LValue := LExtrapolate.GetCurrentSpeed(LTime);
      AAdapter.Put(ALine, LValue);
      TMatrixLines.PutFlag(ALine, LExtrapolate.IsDone(LTime));
    end;
    TMatrixLines.Put(ALine, LExtrapolate.GetEndTime);
    TMatrixLines.Put(ALine, LExtrapolate.GetDuration);
    TMatrixLines.Put(ALine, LExtrapolate.GetStartTime);
    TMatrixLines.PutInt(ALine, LExtrapolate.GetExtrapolationType);
    LExtrapolate.SetStartTime(LStart + 10.0);
    LValue := LExtrapolate.GetCurrentValue(LStart + 10.0 + LDuration * 0.5);
    AAdapter.Put(ALine, LValue);
    LExtrapolate.SetStartValue(AAdapter.Make(AFloats, 6));
    LValue := LExtrapolate.GetCurrentValue(LStart + 10.0 + LDuration * 0.5);
    AAdapter.Put(ALine, LValue);
  finally
    LExtrapolate.Free;
  end;
end;

class procedure TParityComputer<T>.Interpolate(const AAdapter: TValueAdapter<T>;
  const AFloats: TFloats; var ALine: string);
var
  LInterpolate: TIdInterpolate<T>;
  LIndex: Integer;
  LStart, LDuration, LTime: Single;
  LValue: T;
begin
  LStart := AFloats[0];
  LDuration := AFloats[1];
  LInterpolate := TIdInterpolate<T>.Create(AAdapter.Arithmetic);
  try
    LInterpolate.Init(LStart, LDuration, AAdapter.Make(AFloats, 2), AAdapter.Make(AFloats, 5));
    for LIndex := 0 to 7 do
    begin
      LTime := AFloats[8 + LIndex];
      LValue := LInterpolate.GetCurrentValue(LTime);
      AAdapter.Put(ALine, LValue);
      LValue := LInterpolate.GetCurrentValue(LTime);
      AAdapter.Put(ALine, LValue);
      TMatrixLines.PutFlag(ALine, LInterpolate.IsDone(LTime));
    end;
    TMatrixLines.Put(ALine, LInterpolate.GetEndTime);
    TMatrixLines.Put(ALine, LInterpolate.GetDuration);
    TMatrixLines.Put(ALine, LInterpolate.GetStartTime);
    LInterpolate.SetStartTime(LStart + 5.0);
    LInterpolate.SetDuration(LDuration * 0.5 + 1.0);
    LInterpolate.SetStartValue(AAdapter.Make(AFloats, 5));
    LInterpolate.SetEndValue(AAdapter.Make(AFloats, 2));
    LValue := LInterpolate.GetCurrentValue(LStart + 5.0 + LDuration * 0.25);
    AAdapter.Put(ALine, LValue);
  finally
    LInterpolate.Free;
  end;
end;

class procedure TParityComputer<T>.AccelDecel(const AAdapter: TValueAdapter<T>;
  const ASine: Boolean; const AFloats: TFloats; var ALine: string);
var
  LInterpolate: TIdInterpolateAccelDecel<T>;
  LIndex: Integer;
  LStart, LDuration, LTime: Single;
  LValue: T;
begin
  LStart := AFloats[0];
  LDuration := AFloats[3];
  if ASine then
    LInterpolate := TIdInterpolateAccelDecelSine<T>.Create(AAdapter.Arithmetic)
  else
    LInterpolate := TIdInterpolateAccelDecelLinear<T>.Create(AAdapter.Arithmetic);
  try
    LInterpolate.Init(LStart, AFloats[1], AFloats[2], LDuration, AAdapter.Make(AFloats, 4),
      AAdapter.Make(AFloats, 7));
    for LIndex := 0 to 7 do
    begin
      LTime := AFloats[10 + LIndex];
      LValue := LInterpolate.GetCurrentValue(LTime);
      AAdapter.Put(ALine, LValue);
      LValue := LInterpolate.GetCurrentSpeed(LTime);
      AAdapter.Put(ALine, LValue);
      TMatrixLines.PutFlag(ALine, LInterpolate.IsDone(LTime));
    end;
    TMatrixLines.Put(ALine, LInterpolate.GetEndTime);
    TMatrixLines.Put(ALine, LInterpolate.GetDuration);
    TMatrixLines.Put(ALine, LInterpolate.GetAcceleration);
    TMatrixLines.Put(ALine, LInterpolate.GetDeceleration);
    TMatrixLines.Put(ALine, LInterpolate.GetStartTime);
    LInterpolate.SetStartTime(LStart + 7.0);
    LValue := LInterpolate.GetCurrentValue(LStart + 7.0 + LDuration * 0.5);
    AAdapter.Put(ALine, LValue);
    LInterpolate.SetStartValue(AAdapter.Make(AFloats, 7));
    LValue := LInterpolate.GetCurrentValue(LStart + 7.0 + LDuration * 0.3);
    AAdapter.Put(ALine, LValue);
    LInterpolate.SetEndValue(AAdapter.Make(AFloats, 4));
    LValue := LInterpolate.GetCurrentValue(LStart + 7.0 + LDuration * 0.9);
    AAdapter.Put(ALine, LValue);
  finally
    LInterpolate.Free;
  end;
end;

function ScalarAdapter: TValueAdapter<Single>;
begin
  Result.Arithmetic := TIdCurveScalarArithmetic.Create;
  Result.Make := function(const AFloats: TFloats; const AStart: Integer): Single
    begin
      Result := AFloats[AStart];
    end;
  Result.Put := procedure(var ALine: string; const AValue: Single)
    begin
      TMatrixLines.Put(ALine, AValue);
    end;
end;

function Vec3Adapter: TValueAdapter<TIdVec3>;
begin
  Result.Arithmetic := TIdCurveVec3Arithmetic.Create;
  Result.Make := function(const AFloats: TFloats; const AStart: Integer): TIdVec3
    begin
      Result := TIdVec3.Create(AFloats[AStart], AFloats[AStart + 1], AFloats[AStart + 2]);
    end;
  Result.Put := procedure(var ALine: string; const AValue: TIdVec3)
    begin
      TMatrixLines.Put(ALine, AValue.X);
      TMatrixLines.Put(ALine, AValue.Y);
      TMatrixLines.Put(ALine, AValue.Z);
    end;
end;

{ TTestInterpolateParity }

procedure TTestInterpolateParity.Setup;
begin
  FLines := TStringList.Create;
  FLines.LoadFromFile(TMatrixLines.DataPath('interp.golden.txt'));
end;

procedure TTestInterpolateParity.TearDown;
begin
  FLines.Free;
end;

procedure TTestInterpolateParity.Run(const APrefix: string; const AMaxUlps: Integer;
  const ARelative, AAbsolute: Single);
var
  LIndex: Integer;
  LName, LLine: string;
  LFloats: TFloats;
  LActual, LExpected: TStringList;
begin
  LActual := TStringList.Create;
  LExpected := TStringList.Create;
  try
    for LIndex := 0 to FLines.Count - 1 do
    begin
      if not FLines[LIndex].StartsWith(APrefix) then
        Continue;
      LFloats := TMatrixLines.ParseInputs(FLines[LIndex], LName);
      LLine := TMatrixLines.HeadOf(FLines[LIndex]);
      if LName = 'EXf' then
        TParityComputer<Single>.Extrapolate(ScalarAdapter, LFloats, LLine)
      else if LName = 'EXv' then
        TParityComputer<TIdVec3>.Extrapolate(Vec3Adapter, LFloats, LLine)
      else if LName = 'IPf' then
        TParityComputer<Single>.Interpolate(ScalarAdapter, LFloats, LLine)
      else if LName = 'IPv' then
        TParityComputer<TIdVec3>.Interpolate(Vec3Adapter, LFloats, LLine)
      else if LName = 'ALf' then
        TParityComputer<Single>.AccelDecel(ScalarAdapter, False, LFloats, LLine)
      else if LName = 'ALv' then
        TParityComputer<TIdVec3>.AccelDecel(Vec3Adapter, False, LFloats, LLine)
      else if LName = 'ASf' then
        TParityComputer<Single>.AccelDecel(ScalarAdapter, True, LFloats, LLine)
      else if LName = 'ASv' then
        TParityComputer<TIdVec3>.AccelDecel(Vec3Adapter, True, LFloats, LLine)
      else
        Assert.Fail('operazione sconosciuta ' + LName);
      LActual.Add(LLine);
      LExpected.Add(FLines[LIndex]);
    end;
    Assert.IsTrue(LExpected.Count > 0, 'nessuna riga nel golden per ' + APrefix);
    TMatrixLines.CompareLines(LExpected, LActual, AMaxUlps, ARelative, AAbsolute);
  finally
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestInterpolateParity.TIdExtrapolateDiSingleDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('EXf ', 4, 4E-5, 1E-4);
end;

procedure TTestInterpolateParity.TIdExtrapolateDiVettoriDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('EXv ', 4, 4E-5, 1E-4);
end;

procedure TTestInterpolateParity.TIdInterpolateDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('IPf ', 4, 4E-5, 1E-4);
  Run('IPv ', 4, 4E-5, 1E-4);
end;

procedure TTestInterpolateParity.TIdInterpolateAccelDecelLinearDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('ALf ', 4, 4E-5, 1E-4);
  Run('ALv ', 4, 4E-5, 1E-4);
end;

procedure TTestInterpolateParity.TIdInterpolateAccelDecelSineDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('ASf ', 4, 4E-5, 1E-4);
  Run('ASv ', 4, 4E-5, 1E-4);
end;

end.
