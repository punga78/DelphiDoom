{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurve, the base of the curves    }
{                                                                              }
{  Port of idCurve (idlib\math\Curve.h) of the Doom 3 GPL Source Code.         }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve;

{$Q-}
{$R-}

interface

uses
  System.Generics.Collections, DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>
  ///   A list of timed values (idCurve&lt;type&gt;), the base of all the curves. As a class on its
  ///   own it is a step function: the value at a time is the value of the first knot whose time
  ///   is not before it, and the derivatives are zero. The C++ template is generic on the value
  ///   type with the arithmetic of the type; here the generic argument <c>T</c> comes with an
  ///   <c>IIdCurveArithmetic&lt;T&gt;</c> given to the constructor. Knot times must be added in
  ///   any order (AddValue keeps them sorted) and be distinct.
  ///   Differences from the original: an index out of range raises EArgumentOutOfRangeException
  ///   (the C++ reads outside the list), and <c>GetValueAddress</c> (a pointer into the list) is
  ///   not ported: use <c>GetValue</c> and <c>SetValue</c>.
  /// </summary>
  TIdCurve<T> = class
  strict private
    FArithmetic: IIdCurveArithmetic<T>;
  protected
    /// <summary>The knots</summary>
    FTimes: TList<Single>;
    /// <summary>The value of every knot</summary>
    FValues: TList<T>;
    /// <summary>Cached index for fast lookup (the <c>mutable currentIndex</c>)</summary>
    FCurrentIndex: Integer;
    /// <summary>Set whenever the curve changes (the <c>mutable changed</c>)</summary>
    FChanged: Boolean;
    /// <summary>The first index whose time is greater than or equal to the given one</summary>
    function IndexForTime(const ATime: Single): Integer;
    function TimeForIndex(const AIndex: Integer): Single;
    /// <summary>The value of a knot, extrapolated linearly outside the list</summary>
    function ValueForIndex(const AIndex: Integer): T;
    function GetSpeed(const ATime: Single): Single;
    function RombergIntegral(const AT0, AT1: Single; const AOrder: Integer): Single;
    property Arithmetic: IIdCurveArithmetic<T> read FArithmetic;
  public
    /// <param name="AArithmetic">The arithmetic of the value type, not nil</param>
    constructor Create(const AArithmetic: IIdCurveArithmetic<T>);
    destructor Destroy; override;
    /// <summary>Adds a timed value; returns the index where it was inserted</summary>
    function AddValue(const ATime: Single; const AValue: T): Integer; virtual;
    procedure RemoveIndex(const AIndex: Integer); virtual;
    procedure Clear; virtual;
    function GetCurrentValue(const ATime: Single): T; virtual;
    function GetCurrentFirstDerivative(const ATime: Single): T; virtual;
    function GetCurrentSecondDerivative(const ATime: Single): T; virtual;
    /// <summary>True when the time is not before the last knot</summary>
    function IsDone(const ATime: Single): Boolean; virtual;
    function GetNumValues: Integer;
    procedure SetValue(const AIndex: Integer; const AValue: T);
    function GetValue(const AIndex: Integer): T;
    function GetTime(const AIndex: Integer): Single;
    /// <summary>Arc length from the first knot to the time (Romberg integration of the speed)</summary>
    function GetLengthForTime(const ATime: Single): Single;
    /// <summary>The time at which the arc length reaches ALength (Newton iteration)</summary>
    function GetTimeForLength(const ALength: Single; const AEpsilon: Single = 0.1): Single;
    function GetLengthBetweenKnots(const AIndex0, AIndex1: Integer): Single;
    /// <summary>Spreads the knots evenly over the total time, starting at time 0</summary>
    procedure MakeUniform(const ATotalTime: Single);
    /// <summary>Moves the knots so that the speed along the curve is constant</summary>
    procedure SetConstantSpeed(const ATotalTime: Single);
    procedure ShiftTime(const ADeltaTime: Single);
    /// <summary>Adds the translation to every value</summary>
    procedure Translate(const ATranslation: T);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math;

{ TIdCurve<T> }

constructor TIdCurve<T>.Create(const AArithmetic: IIdCurveArithmetic<T>);
begin
  inherited Create;
  if not Assigned(AArithmetic) then
    raise EArgumentNilException.Create('AArithmetic');
  FArithmetic := AArithmetic;
  FTimes := TList<Single>.Create;
  FValues := TList<T>.Create;
  FCurrentIndex := -1;
  FChanged := False;
end;

destructor TIdCurve<T>.Destroy;
begin
  FValues.Free;
  FTimes.Free;
  inherited Destroy;
end;

function TIdCurve<T>.AddValue(const ATime: Single; const AValue: T): Integer;
begin
  Result := IndexForTime(ATime);
  FTimes.Insert(Result, ATime);
  FValues.Insert(Result, AValue);
  FChanged := True;
end;

procedure TIdCurve<T>.RemoveIndex(const AIndex: Integer);
begin
  FValues.Delete(AIndex);
  FTimes.Delete(AIndex);
  FChanged := True;
end;

procedure TIdCurve<T>.Clear;
begin
  FValues.Clear;
  FTimes.Clear;
  FCurrentIndex := -1;
  FChanged := True;
end;

function TIdCurve<T>.GetCurrentValue(const ATime: Single): T;
var
  LIndex: Integer;
begin
  LIndex := IndexForTime(ATime);
  if LIndex >= FValues.Count then
    Result := FValues[FValues.Count - 1]
  else
    Result := FValues[LIndex];
end;

function TIdCurve<T>.GetCurrentFirstDerivative(const ATime: Single): T;
begin
  Result := FArithmetic.Subtract(FValues[0], FValues[0]);
end;

function TIdCurve<T>.GetCurrentSecondDerivative(const ATime: Single): T;
begin
  Result := FArithmetic.Subtract(FValues[0], FValues[0]);
end;

function TIdCurve<T>.IsDone(const ATime: Single): Boolean;
begin
  Result := ATime >= FTimes[FTimes.Count - 1];
end;

function TIdCurve<T>.GetNumValues: Integer;
begin
  Result := FValues.Count;
end;

procedure TIdCurve<T>.SetValue(const AIndex: Integer; const AValue: T);
begin
  FValues[AIndex] := AValue;
  FChanged := True;
end;

function TIdCurve<T>.GetValue(const AIndex: Integer): T;
begin
  Result := FValues[AIndex];
end;

function TIdCurve<T>.GetTime(const AIndex: Integer): Single;
begin
  Result := FTimes[AIndex];
end;

function TIdCurve<T>.GetSpeed(const ATime: Single): Single;
var
  LValue: T;
  LIndex: Integer;
  LSpeed, LComponent, LSquare: Single;
begin
  LValue := GetCurrentFirstDerivative(ATime);
  LSpeed := 0.0;
  for LIndex := 0 to FArithmetic.GetDimension(LValue) - 1 do
  begin
    LComponent := FArithmetic.GetComponent(LValue, LIndex);
    LSquare := LComponent * LComponent;
    LSpeed := LSpeed + LSquare;
  end;
  Result := TIdMath.Sqrt(LSpeed);
end;

function TIdCurve<T>.RombergIntegral(const AT0, AT1: Single; const AOrder: Integer): Single;
var
  LTemp0, LTemp1: TArray<Single>;
  LIndex, LJ, LK, LM, LN: Integer;
  LSum, LDelta, LHalf, LStep, LSpeed0, LSpeed1, LTime, LProduct, LValue: Single;
begin
  SetLength(LTemp0, AOrder);
  SetLength(LTemp1, AOrder);
  LDelta := AT1 - AT0;
  LSpeed0 := GetSpeed(AT0);
  LSpeed1 := GetSpeed(AT1);
  LHalf := 0.5 * LDelta;
  LValue := LSpeed0 + LSpeed1;
  LTemp0[0] := LHalf * LValue;

  LIndex := 2;
  LM := 1;
  while LIndex <= AOrder do
  begin
    // approximate using the trapezoid rule
    LSum := 0.0;
    for LJ := 1 to LM do
    begin
      LStep := LJ - Single(0.5);
      LProduct := LDelta * LStep;
      LTime := AT0 + LProduct;
      LSpeed0 := GetSpeed(LTime);
      LSum := LSum + LSpeed0;
    end;

    // Richardson extrapolation
    LProduct := LDelta * LSum;
    LValue := LTemp0[0] + LProduct;
    LTemp1[0] := 0.5 * LValue;
    LN := 4;
    for LK := 1 to LIndex - 1 do
    begin
      LProduct := LN * LTemp1[LK - 1];
      LValue := LProduct - LTemp0[LK - 1];
      LTemp1[LK] := LValue / (LN - 1);
      LN := LN * 4;
    end;

    for LJ := 0 to LIndex - 1 do
      LTemp0[LJ] := LTemp1[LJ];

    Inc(LIndex);
    LM := LM * 2;
    LDelta := LDelta * 0.5;
  end;
  Result := LTemp0[AOrder - 1];
end;

function TIdCurve<T>.GetLengthBetweenKnots(const AIndex0, AIndex1: Integer): Single;
var
  LIndex: Integer;
  LPart: Single;
begin
  Result := 0.0;
  for LIndex := AIndex0 to AIndex1 - 1 do
  begin
    LPart := RombergIntegral(FTimes[LIndex], FTimes[LIndex + 1], 5);
    Result := Result + LPart;
  end;
end;

function TIdCurve<T>.GetLengthForTime(const ATime: Single): Single;
var
  LIndex, LKnot: Integer;
  LPart: Single;
begin
  Result := 0.0;
  LIndex := IndexForTime(ATime);
  for LKnot := 0 to LIndex - 1 do
  begin
    LPart := RombergIntegral(FTimes[LKnot], FTimes[LKnot + 1], 5);
    Result := Result + LPart;
  end;
  LPart := RombergIntegral(FTimes[LIndex], ATime, 5);
  Result := Result + LPart;
end;

function TIdCurve<T>.GetTimeForLength(const ALength: Single; const AEpsilon: Single): Single;
var
  LIndex, LTry: Integer;
  LAccumLength: TArray<Single>;
  LTotalLength, LLen0, LLen1, LTime, LDiff, LPart, LSpeed: Single;
begin
  if ALength <= 0.0 then
  begin
    Result := FTimes[0];
    Exit;
  end;

  SetLength(LAccumLength, FValues.Count);
  LTotalLength := 0.0;
  LIndex := 0;
  while LIndex < FValues.Count - 1 do
  begin
    LPart := GetLengthBetweenKnots(LIndex, LIndex + 1);
    LTotalLength := LTotalLength + LPart;
    LAccumLength[LIndex] := LTotalLength;
    if ALength < LAccumLength[LIndex] then
      Break;
    Inc(LIndex);
  end;

  if LIndex >= FValues.Count - 1 then
  begin
    Result := FTimes[FTimes.Count - 1];
    Exit;
  end;

  if LIndex = 0 then
  begin
    LLen0 := ALength;
    LLen1 := LAccumLength[0];
  end
  else
  begin
    LLen0 := ALength - LAccumLength[LIndex - 1];
    LLen1 := LAccumLength[LIndex] - LAccumLength[LIndex - 1];
  end;

  // invert the arc length integral using Newton's method
  LTime := FTimes[LIndex + 1] - FTimes[LIndex];
  LTime := LTime * LLen0;
  LTime := LTime / LLen1;
  for LTry := 0 to 31 do
  begin
    LPart := FTimes[LIndex] + LTime;
    LDiff := RombergIntegral(FTimes[LIndex], LPart, 5);
    LDiff := LDiff - LLen0;
    if TIdMath.Fabs(LDiff) <= AEpsilon then
    begin
      Result := FTimes[LIndex] + LTime;
      Exit;
    end;
    LSpeed := GetSpeed(FTimes[LIndex] + LTime);
    LPart := LDiff / LSpeed;
    LTime := LTime - LPart;
  end;
  Result := FTimes[LIndex] + LTime;
end;

procedure TIdCurve<T>.MakeUniform(const ATotalTime: Single);
var
  LIndex, LLast: Integer;
  LProduct: Single;
begin
  LLast := FTimes.Count - 1;
  for LIndex := 0 to LLast do
  begin
    LProduct := LIndex * ATotalTime;
    FTimes[LIndex] := LProduct / LLast;
  end;
  FChanged := True;
end;

procedure TIdCurve<T>.SetConstantSpeed(const ATotalTime: Single);
var
  LIndex: Integer;
  LLength: TArray<Single>;
  LTotalLength, LScale, LTime, LProduct: Single;
begin
  SetLength(LLength, FValues.Count);
  LTotalLength := 0.0;
  for LIndex := 0 to FValues.Count - 2 do
  begin
    LLength[LIndex] := GetLengthBetweenKnots(LIndex, LIndex + 1);
    LTotalLength := LTotalLength + LLength[LIndex];
  end;
  LScale := ATotalTime / LTotalLength;
  LTime := 0.0;
  for LIndex := 0 to FTimes.Count - 2 do
  begin
    FTimes[LIndex] := LTime;
    LProduct := LScale * LLength[LIndex];
    LTime := LTime + LProduct;
  end;
  FTimes[FTimes.Count - 1] := ATotalTime;
  FChanged := True;
end;

procedure TIdCurve<T>.ShiftTime(const ADeltaTime: Single);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FTimes.Count - 1 do
    FTimes[LIndex] := FTimes[LIndex] + ADeltaTime;
  FChanged := True;
end;

procedure TIdCurve<T>.Translate(const ATranslation: T);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FValues.Count - 1 do
    FValues[LIndex] := FArithmetic.Add(FValues[LIndex], ATranslation);
  FChanged := True;
end;

function TIdCurve<T>.IndexForTime(const ATime: Single): Integer;
var
  LLength, LMid, LOffset, LStep: Integer;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex <= FTimes.Count) then
  begin
    // use the cached index if it is still valid
    if FCurrentIndex = 0 then
    begin
      if ATime <= FTimes[FCurrentIndex] then
      begin
        Result := FCurrentIndex;
        Exit;
      end;
    end
    else if FCurrentIndex = FTimes.Count then
    begin
      if ATime > FTimes[FCurrentIndex - 1] then
      begin
        Result := FCurrentIndex;
        Exit;
      end;
    end
    else if (ATime > FTimes[FCurrentIndex - 1]) and (ATime <= FTimes[FCurrentIndex]) then
    begin
      Result := FCurrentIndex;
      Exit;
    end
    else if (ATime > FTimes[FCurrentIndex]) and
      ((FCurrentIndex + 1 = FTimes.Count) or (ATime <= FTimes[FCurrentIndex + 1])) then
    begin
      // use the next index
      Inc(FCurrentIndex);
      Result := FCurrentIndex;
      Exit;
    end;
  end;

  // use binary search to find the index for the given time
  LLength := FTimes.Count;
  LMid := LLength;
  LOffset := 0;
  LStep := 0;
  while LMid > 0 do
  begin
    LMid := LLength shr 1;
    if ATime = FTimes[LOffset + LMid] then
    begin
      Result := LOffset + LMid;
      Exit;
    end
    else if ATime > FTimes[LOffset + LMid] then
    begin
      LOffset := LOffset + LMid;
      LLength := LLength - LMid;
      LStep := 1;
    end
    else
    begin
      LLength := LLength - LMid;
      LStep := 0;
    end;
  end;
  FCurrentIndex := LOffset + LStep;
  Result := FCurrentIndex;
end;

function TIdCurve<T>.ValueForIndex(const AIndex: Integer): T;
var
  LLast: Integer;
begin
  LLast := FValues.Count - 1;
  if AIndex < 0 then
    Result := FArithmetic.Add(FValues[0], FArithmetic.Multiply(
      FArithmetic.Subtract(FValues[1], FValues[0]), AIndex))
  else if AIndex > LLast then
    Result := FArithmetic.Add(FValues[LLast], FArithmetic.Multiply(
      FArithmetic.Subtract(FValues[LLast], FValues[LLast - 1]), AIndex - LLast))
  else
    Result := FValues[AIndex];
end;

function TIdCurve<T>.TimeForIndex(const AIndex: Integer): Single;
var
  LLast: Integer;
begin
  LLast := FTimes.Count - 1;
  if AIndex < 0 then
    Result := FTimes[0] + AIndex * (FTimes[1] - FTimes[0])
  else if AIndex > LLast then
    Result := FTimes[LLast] + (AIndex - LLast) * (FTimes[LLast] - FTimes[LLast - 1])
  else
    Result := FTimes[AIndex];
end;

end.
