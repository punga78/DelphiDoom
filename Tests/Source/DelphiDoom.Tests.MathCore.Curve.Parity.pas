{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the curves of id Tech 4 - parity with the C++ idLib    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Curve.Parity;

{$Q-}
{$R-}

interface

uses
  System.Classes, System.Math, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the real idCurve templates of Doom 3 (Tests\Data\MathCore\curve.golden.txt:
  ///   lines written by idCurve, idCurve_Bezier, QuadraticBezier, CubicBezier, CatmullRomSpline,
  ///   KochanekBartelsSpline, BSpline, UniformCubicBSpline, NonUniformBSpline, NURBS and
  ///   NaturalCubicSpline compiled with bcc32c on the x87 for float, idVec2, idVec3 and idVec4).
  ///   A line carries the whole curve (kind, value type, boundary, order, close time, knots) and
  ///   the queries, then "|" and the answers; every line is recomputed from its own inputs.
  ///   Only the queries the original defines are asked: the natural spline only up to the last
  ///   but one knot, the Kochanek-Bartels spline only after the first knot (the original reads
  ///   outside its lists otherwise), the arc length only for the types with components.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestCurveParity = class(TObject)
  private
    FLines: TStringList;
    FOldMask: TArithmeticExceptionMask;
    procedure Run(const APrefixes: array of string; const AMaxUlps: Integer;
      const AAbsTolerance: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LeCurveABlocchiEDiBezierDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LaSplineDiCatmullRomDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LaSplineDiKochanekBartelsDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LaSplineNaturaleCubicaDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeBSplineDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeNurbsDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeLunghezzeDarcoDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LaVelocitaCostanteDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeModificheDovrebberoDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.MathCore.Float.Curve.Types,
  DelphiDoom.MathCore.Float.Curve.Intf, DelphiDoom.MathCore.Float.Curve,
  DelphiDoom.MathCore.Float.Curve.Bezier, DelphiDoom.MathCore.Float.Curve.QuadraticBezier,
  DelphiDoom.MathCore.Float.Curve.CubicBezier, DelphiDoom.MathCore.Float.Curve.Spline,
  DelphiDoom.MathCore.Float.Curve.NaturalCubicSpline,
  DelphiDoom.MathCore.Float.Curve.CatmullRomSpline,
  DelphiDoom.MathCore.Float.Curve.KochanekBartelsSpline, DelphiDoom.MathCore.Float.Curve.BSpline,
  DelphiDoom.MathCore.Float.Curve.UniformCubicBSpline,
  DelphiDoom.MathCore.Float.Curve.NonUniformBSpline, DelphiDoom.MathCore.Float.Curve.NURBS,
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Scalar, DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec2,
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec3, DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec4,
  DelphiDoom.Tests.IdLib.Golden, DelphiDoom.Tests.MathCore.GoldenLines;

type
  /// <summary>Computes the answers of a line for one value type</summary>
  TCurveLineRunner<T> = class
  strict private
    FArithmetic: IIdCurveArithmetic<T>;
    FDimension: Integer;
    FKind: string;
    FOrder: Integer;
    function ReadValue(var AReader: TGoldenLineReader): T;
    procedure PutValue(var ALine: string; const AValue: T);
    function Build(var AReader: TGoldenLineReader): TIdCurve<T>;
  public
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>; const ADimension: Integer);
    function Compute(const ALine: string): string;
  end;

{ TCurveLineRunner<T> }

constructor TCurveLineRunner<T>.Create(const AArithmetic: IIdCurveArithmetic<T>;
  const ADimension: Integer);
begin
  inherited Create;
  FArithmetic := AArithmetic;
  FDimension := ADimension;
end;

function TCurveLineRunner<T>.ReadValue(var AReader: TGoldenLineReader): T;
var
  LIndex: Integer;
begin
  Result := Default(T);
  for LIndex := 0 to FDimension - 1 do
    FArithmetic.SetComponent(Result, LIndex, AReader.Float);
end;

procedure TCurveLineRunner<T>.PutValue(var ALine: string; const AValue: T);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FDimension - 1 do
    TGoldenLines.PutFloat(ALine, FArithmetic.GetComponent(AValue, LIndex));
end;

function TCurveLineRunner<T>.Build(var AReader: TGoldenLineReader): TIdCurve<T>;
var
  LBoundary, LCount, LIndex: Integer;
  LCloseTime, LTime, LWeight, LTension, LContinuity, LBias: Single;
  LValue: T;
begin
  AReader.Int; // the dimension, already used to choose the runner
  LBoundary := AReader.Int;
  FOrder := AReader.Int;
  LCloseTime := AReader.Float;
  LCount := AReader.Int;

  if FKind = 'base' then
    Result := TIdCurve<T>.Create(FArithmetic)
  else if FKind = 'bezier' then
    Result := TIdCurveBezier<T>.Create(FArithmetic)
  else if FKind = 'qbezier' then
    Result := TIdCurveQuadraticBezier<T>.Create(FArithmetic)
  else if FKind = 'cbezier' then
    Result := TIdCurveCubicBezier<T>.Create(FArithmetic)
  else if FKind = 'natural' then
    Result := TIdCurveNaturalCubicSpline<T>.Create(FArithmetic)
  else if FKind = 'catmull' then
    Result := TIdCurveCatmullRomSpline<T>.Create(FArithmetic)
  else if FKind = 'kb' then
    Result := TIdCurveKochanekBartelsSpline<T>.Create(FArithmetic)
  else if FKind = 'bspline' then
    Result := TIdCurveBSpline<T>.Create(FArithmetic)
  else if FKind = 'ubspline' then
    Result := TIdCurveUniformCubicBSpline<T>.Create(FArithmetic)
  else if FKind = 'nubs' then
    Result := TIdCurveNonUniformBSpline<T>.Create(FArithmetic)
  else if FKind = 'nurbs' then
    Result := TIdCurveNURBS<T>.Create(FArithmetic)
  else
    raise Exception.Create('curva sconosciuta ' + FKind);

  for LIndex := 0 to LCount - 1 do
  begin
    LTime := AReader.Float;
    LValue := ReadValue(AReader);
    if FKind = 'nurbs' then
    begin
      LWeight := AReader.Float;
      TIdCurveNURBS<T>(Result).AddValue(LTime, LValue, LWeight);
    end
    else if FKind = 'kb' then
    begin
      LTension := AReader.Float;
      LContinuity := AReader.Float;
      LBias := AReader.Float;
      TIdCurveKochanekBartelsSpline<T>(Result).AddValue(LTime, LValue, LTension, LContinuity, LBias);
    end
    else
      Result.AddValue(LTime, LValue);
  end;

  if Result is TIdCurveSpline<T> then
  begin
    TIdCurveSpline<T>(Result).BoundaryType := TIdCurveBoundary(LBoundary);
    TIdCurveSpline<T>(Result).CloseTime := LCloseTime;
  end;
  // an order of 0 in the line means that the C++ left the default order
  if ((FKind = 'bspline') or (FKind = 'nubs') or (FKind = 'nurbs')) and (FOrder > 0) then
    TIdCurveBSpline<T>(Result).Order := FOrder;
end;

function TCurveLineRunner<T>.Compute(const ALine: string): string;
var
  LReader: TGoldenLineReader;
  LCurve: TIdCurve<T>;
  LName: string;
  LQueryCount, LIndex, LCount, LAdded: Integer;
  LTimes: TArray<Single>;
  LTime, LTotal, LDelta, LShift, LMidTime: Single;
  LInsertTime: Single;
  LInserted, LTranslation, LValue: T;
  LLow, LHigh, LSpan: Single;
  LLengths: array[0..3] of Single;
begin
  LReader.Start(ALine);
  LName := LReader.Tokens[0];
  FKind := Copy(LName, Pos('_', Copy(LName, 4, MaxInt)) + 4, MaxInt);
  Result := '';
  LCurve := Build(LReader);
  try
    if LName.StartsWith('CV_eval_') then
    begin
      LQueryCount := LReader.Int;
      SetLength(LTimes, LQueryCount);
      for LIndex := 0 to LQueryCount - 1 do
        LTimes[LIndex] := LReader.Float;
      LReader.SkipBar;
      Result := TGoldenLines.HeadOf(ALine);
      for LIndex := 0 to LQueryCount - 1 do
      begin
        PutValue(Result, LCurve.GetCurrentValue(LTimes[LIndex]));
        PutValue(Result, LCurve.GetCurrentFirstDerivative(LTimes[LIndex]));
        PutValue(Result, LCurve.GetCurrentSecondDerivative(LTimes[LIndex]));
        TGoldenLines.PutBool(Result, LCurve.IsDone(LTimes[LIndex]));
      end;
    end
    else if LName.StartsWith('CV_len_') then
    begin
      LReader.SkipBar;
      Result := TGoldenLines.HeadOf(ALine);
      LCount := LCurve.GetNumValues;
      LLow := LCurve.GetTime(0);
      LHigh := LCurve.GetTime(LCount - 1);
      LSpan := LHigh - LLow;
      LTotal := LCurve.GetLengthBetweenKnots(0, LCount - 1);
      TGoldenLines.PutFloat(Result, LTotal);
      TGoldenLines.PutFloat(Result, LCurve.GetLengthForTime(LLow + LSpan * Single(0.35)));
      TGoldenLines.PutFloat(Result, LCurve.GetLengthForTime(LLow + LSpan * Single(0.8)));
      TGoldenLines.PutFloat(Result, LCurve.GetLengthForTime(LHigh));
      LLengths[0] := LTotal * Single(0.25);
      LLengths[1] := LTotal * Single(0.6);
      LLengths[2] := LTotal * Single(1.5);
      LLengths[3] := -1.0;
      for LIndex := 0 to 3 do
        TGoldenLines.PutFloat(Result, LCurve.GetTimeForLength(LLengths[LIndex], Single(0.01)));
      TGoldenLines.PutFloat(Result, LCurve.GetTimeForLength(LTotal * Single(0.4)));
    end
    else if LName.StartsWith('CV_const_') then
    begin
      LTotal := LReader.Float;
      LReader.SkipBar;
      Result := TGoldenLines.HeadOf(ALine);
      LCurve.SetConstantSpeed(LTotal);
      LCount := LCurve.GetNumValues;
      for LIndex := 0 to LCount - 1 do
        TGoldenLines.PutFloat(Result, LCurve.GetTime(LIndex));
      TGoldenLines.PutFloat(Result, LCurve.GetLengthBetweenKnots(0, LCount - 1));
      for LIndex := 0 to LCount - 2 do
        TGoldenLines.PutFloat(Result, LCurve.GetLengthBetweenKnots(LIndex, LIndex + 1));
    end
    else if LName.StartsWith('CV_edit_') then
    begin
      LInsertTime := LReader.Float;
      LInserted := ReadValue(LReader);
      LTranslation := ReadValue(LReader);
      LShift := LReader.Float;
      LTotal := LReader.Float;
      LReader.SkipBar;
      Result := TGoldenLines.HeadOf(ALine);
      LAdded := LCurve.AddValue(LInsertTime, LInserted);
      TGoldenLines.PutInt(Result, LAdded);
      TGoldenLines.PutInt(Result, LCurve.GetNumValues);
      for LIndex := 0 to LCurve.GetNumValues - 1 do
      begin
        TGoldenLines.PutFloat(Result, LCurve.GetTime(LIndex));
        PutValue(Result, LCurve.GetValue(LIndex));
      end;
      LCurve.RemoveIndex(1);
      TGoldenLines.PutInt(Result, LCurve.GetNumValues);
      for LIndex := 0 to LCurve.GetNumValues - 1 do
        TGoldenLines.PutFloat(Result, LCurve.GetTime(LIndex));
      LCurve.Translate(LTranslation);
      PutValue(Result, LCurve.GetValue(0));
      PutValue(Result, LCurve.GetValue(LCurve.GetNumValues - 1));
      LCurve.ShiftTime(LShift);
      TGoldenLines.PutFloat(Result, LCurve.GetTime(0));
      TGoldenLines.PutFloat(Result, LCurve.GetTime(LCurve.GetNumValues - 1));
      LCurve.MakeUniform(LTotal);
      for LIndex := 0 to LCurve.GetNumValues - 1 do
        TGoldenLines.PutFloat(Result, LCurve.GetTime(LIndex));
      LMidTime := LTotal * Single(0.5);
      TGoldenLines.PutBool(Result, LCurve.IsDone(LMidTime));
      TGoldenLines.PutBool(Result, LCurve.IsDone(LTotal));
      LDelta := LTotal * Single(2.0);
      TGoldenLines.PutBool(Result, LCurve.IsDone(LDelta));
      PutValue(Result, LCurve.GetCurrentValue(LMidTime));
      PutValue(Result, LCurve.GetCurrentFirstDerivative(LMidTime));
      LCurve.SetValue(0, LInserted);
      PutValue(Result, LCurve.GetValue(0));
      LCurve.Clear;
      TGoldenLines.PutInt(Result, LCurve.GetNumValues);
      LValue := LInserted;
      TGoldenLines.PutInt(Result, LCurve.AddValue(1.0, LValue));
      TGoldenLines.PutInt(Result, LCurve.AddValue(0.5, LTranslation));
      TGoldenLines.PutInt(Result, LCurve.AddValue(0.75, LValue));
      TGoldenLines.PutInt(Result, LCurve.GetNumValues);
      for LIndex := 0 to LCurve.GetNumValues - 1 do
        TGoldenLines.PutFloat(Result, LCurve.GetTime(LIndex));
    end
    else
      raise Exception.Create('operazione sconosciuta ' + LName);
  finally
    LCurve.Free;
  end;
end;

function ComputeLine(const ALine: string): string;
var
  LDimension: Integer;
begin
  LDimension := StrToInt(ALine.Split([' '])[1]);
  case LDimension of
    1:
      with TCurveLineRunner<Single>.Create(TIdCurveScalarArithmetic.Create, 1) do
      try
        Result := Compute(ALine);
      finally
        Free;
      end;
    2:
      with TCurveLineRunner<TIdVec2>.Create(TIdCurveVec2Arithmetic.Create, 2) do
      try
        Result := Compute(ALine);
      finally
        Free;
      end;
    3:
      with TCurveLineRunner<TIdVec3>.Create(TIdCurveVec3Arithmetic.Create, 3) do
      try
        Result := Compute(ALine);
      finally
        Free;
      end;
  else
    with TCurveLineRunner<TIdVec4>.Create(TIdCurveVec4Arithmetic.Create, 4) do
    try
      Result := Compute(ALine);
    finally
      Free;
    end;
  end;
end;

{ TTestCurveParity }

procedure TTestCurveParity.Setup;
begin
  // the C++ divides by zero and produces infinities without traps (the second derivative of a
  // B-spline of order 2): mask the FPU exceptions
  FOldMask := SetExceptionMask(exAllArithmeticExceptions);
  FLines := TStringList.Create;
  FLines.LoadFromFile(TIdLibGolden.DataPath('..\MathCore\curve.golden.txt'));
end;

procedure TTestCurveParity.TearDown;
begin
  SetExceptionMask(FOldMask);
  FLines.Free;
end;

procedure TTestCurveParity.Run(const APrefixes: array of string; const AMaxUlps: Integer;
  const AAbsTolerance: Single);
var
  LIndex, LPrefix: Integer;
  LActual, LExpected: TStringList;
begin
  LActual := TStringList.Create;
  LExpected := TStringList.Create;
  try
    for LIndex := 0 to FLines.Count - 1 do
      for LPrefix := 0 to High(APrefixes) do
        if FLines[LIndex].StartsWith(APrefixes[LPrefix] + ' ') then
        begin
          LExpected.Add(FLines[LIndex]);
          LActual.Add(ComputeLine(FLines[LIndex]));
          Break;
        end;
    Assert.IsTrue(LExpected.Count > 0, 'nessuna riga nel golden');
    TGoldenLines.Compare(LExpected, LActual, AMaxUlps, AAbsTolerance);
  finally
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestCurveParity.LeCurveABlocchiEDiBezierDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['CV_eval_base', 'CV_eval_bezier', 'CV_eval_qbezier', 'CV_eval_cbezier'], 2, 1E-4);
end;

procedure TTestCurveParity.LaSplineDiCatmullRomDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run(['CV_eval_catmull', 'CV_eval_ubspline'], 2, 1E-4);
end;

procedure TTestCurveParity.LaSplineDiKochanekBartelsDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run(['CV_eval_kb'], 2, 1E-4);
end;

procedure TTestCurveParity.LaSplineNaturaleCubicaDovrebbeDareLeStesseRispostePerIlCpp;
begin
  // the closed boundary solves a linear system: the sums of the C++ are rounded in a different
  // order, tolerance of 1e-3
  Run(['CV_eval_natural'], 4, 1E-3);
end;

procedure TTestCurveParity.LeBSplineDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['CV_eval_bspline', 'CV_eval_nubs'], 2, 1E-4);
end;

procedure TTestCurveParity.LeNurbsDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['CV_eval_nurbs'], 2, 1E-4);
end;

procedure TTestCurveParity.LeLunghezzeDarcoDovrebberoDareLeStesseRispostePerIlCpp;
begin
  // Romberg integration of a speed computed with idMath::Sqrt (x * InvSqrt(x), 1e-3 relative
  // error of the approximation, the same in both) and a Newton iteration that stops at a
  // threshold: lengths and times are compared with 1e-3
  Run(['CV_len_bezier', 'CV_len_qbezier', 'CV_len_cbezier', 'CV_len_catmull', 'CV_len_ubspline',
    'CV_len_nubs', 'CV_len_bspline', 'CV_len_nurbs'], 8, 1E-3);
end;

procedure TTestCurveParity.LaVelocitaCostanteDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run(['CV_const_catmull', 'CV_const_ubspline', 'CV_const_nubs', 'CV_const_bezier'], 8, 1E-3);
end;

procedure TTestCurveParity.LeModificheDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['CV_edit_base', 'CV_edit_catmull', 'CV_edit_nurbs', 'CV_edit_kb'], 2, 1E-4);
end;

end.
