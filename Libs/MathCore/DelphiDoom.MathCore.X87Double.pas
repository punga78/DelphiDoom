{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the Double results of the 32 bit FPU, fast  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.X87Double;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   What the 32 bit code (x87 FPU, 64 bits of mantissa) gives when a floating point expression is stored
  ///   in a Double or converted to an integer, for the hot paths of the 64 bit code (SSE, 53 bits): the
  ///   native result is used whenever it is proved equal to the one of the FPU, and only the rare doubtful
  ///   case (about one in a thousand for a sum, far less for a conversion) goes to TSoftExtended. With the 32
  ///   bit compiler every function is the native expression
  /// </summary>
  /// <remarks>
  ///   No virtual calls: the functions are static and the fast part is inline. The rounding of the FPU and of
  ///   the SSE unit must be the default one (to the nearest even)
  /// </remarks>
  TX87Double = class
  public
    const
      // the relative error allowed to the native expression: 2^-45 (some operations rounded at 53 bits
      // give 2^-52 each; the rest is margin)
      NATIVE_TOLERANCE = 2.842170943040401E-14;
      INTEGER_LIMIT = 2147483000.0;
    // the slow, always exact way of each expression (TSoftExtended): public because the inline fast parts
    // call them from the units that use this class
    class function AddExact(const A, B: Double): Double; static;
    class function TruncMulAddExact(const ABase: Double; ACount: Integer; const AStep: Double): Integer; static;
    class function TruncOffsetDivideExact(const AValue: Double; AFirst, ASecond, ADivisor: Integer): Integer; static;
    class function RoundMulDivideExact(const AValue: Double; AMultiplier, ADivisor, ASecondDivisor: Integer): Integer;
      static;
    class function RoundQuotientExact(const ANumerator, ADenominator: Double): Integer; static;
    class function RoundProductExact(const A, B: Double): Integer; static;
    class function TruncQuotientExact(const ANumerator, ADenominator: Double): Integer; static;
    class function TruncMulDivideExact(const AValue: Double; AMultiplier, ADivisor: Integer): Integer; static;
    class function RoundScaledInverseExact(AScale, ANumerator, ADenominator: Integer): Integer; static;
    class function TruncReciprocalProductExact(AScale, AFirst, ASecond: Integer): Integer; static;

    /// <summary>A + B stored in a Double: rounded to 64 bits and then to 53, as "fadd, fstp qword" do</summary>
    class function Add(const A, B: Double): Double; static; inline;
    /// <summary>
    ///   True when Trunc(AValue) is certainly the Trunc of the FPU for the same expression: AValue is the
    ///   native result of an expression of a few operations whose intermediate values are not bigger than
    ///   AMagnitude; false when AValue is so near to an integer that the last bits decide (compute it with
    ///   TSoftExtended) or out of the range of an Integer
    /// </summary>
    class function CanTruncate(const AValue, AMagnitude: Double): Boolean; static; inline;
    /// <summary>The same for Round(AValue): false when AValue is near to the middle between two integers</summary>
    class function CanRound(const AValue, AMagnitude: Double): Boolean; static; inline;
    /// <summary>Trunc(ABase + ACount * AStep)</summary>
    class function TruncMulAdd(const ABase: Double; ACount: Integer; const AStep: Double): Integer; static; inline;
    /// <summary>Trunc((AValue + AFirst + ASecond) / ADivisor), the two integers added one after the other</summary>
    class function TruncOffsetDivide(const AValue: Double; AFirst, ASecond, ADivisor: Integer): Integer; static;
      inline;
    /// <summary>Round(AValue * AMultiplier / ADivisor / ASecondDivisor)</summary>
    class function RoundMulDivide(const AValue: Double; AMultiplier, ADivisor: Integer;
      ASecondDivisor: Integer = 1): Integer; static; inline;
    /// <summary>Round(ANumerator / ADenominator)</summary>
    class function RoundQuotient(const ANumerator, ADenominator: Double): Integer; static; inline;
    /// <summary>Round(A * B)</summary>
    class function RoundProduct(const A, B: Double): Integer; static; inline;
    /// <summary>Trunc(ANumerator / ADenominator)</summary>
    class function TruncQuotient(const ANumerator, ADenominator: Double): Integer; static; inline;
    /// <summary>Trunc(AMultiplier * AValue / ADivisor)</summary>
    class function TruncMulDivide(const AValue: Double; AMultiplier, ADivisor: Integer): Integer; static; inline;
    /// <summary>
    ///   Round(AScale / (ANumerator / ADenominator) * AScale), integers; AScale is a power of two. 0 when
    ///   ANumerator is 0 (the FPU gives the "integer indefinite", whose low 32 bits are 0)
    /// </summary>
    class function RoundScaledInverse(AScale, ANumerator, ADenominator: Integer): Integer; static; inline;
    /// <summary>
    ///   Trunc((AScale / AFirst) * (AScale / ASecond) * AScale), integers; AScale is a power of two. 0 when a
    ///   divisor is 0
    /// </summary>
    class function TruncReciprocalProduct(AScale, AFirst, ASecond: Integer): Integer; static; inline;
    /// <summary>
    ///   Trunc((65536 / AValue) * 65536): 2^32 div AValue, exactly (the quotient rounded to 64 bits never
    ///   reaches the next integer, because AValue has at most 31 bits); 0 when AValue is 0, as the low 32
    ///   bits of what the FPU gives
    /// </summary>
    class function TruncFixedReciprocal(AValue: Integer): Integer; static; inline;
    /// <summary>A * B stored in a Double (always the exact way: not for the hot paths)</summary>
    class function Multiply(const A, B: Double): Double; static;
    /// <summary>AMinuend - A * B stored in a Double (always the exact way)</summary>
    class function SubtractProduct(const AMinuend, A, B: Double): Double; static;
    /// <summary>(AEnd - AStart) / ACount stored in a Double (always the exact way)</summary>
    class function DifferenceQuotient(const AEnd, AStart: Double; ACount: Integer): Double; static;
  end;

implementation

uses
  DelphiDoom.MathCore.SoftExtended;


{ TX87Double }

class function TX87Double.AddExact(const A, B: Double): Double;
begin
  Result := (TSoftExtended.FromDouble(A) + TSoftExtended.FromDouble(B)).ToDouble;
end;

class function TX87Double.Add(const A, B: Double): Double;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := A + B;
end;
{$ELSE}
var
  LSum: Double;
  LVirtual: Double;
  LError: Double;
  LHalfUnit: Double;
  LBits: UInt64;
  LExponent: Integer;
begin
  LSum := A + B;
  // the exact error of the sum (Knuth): A + B = LSum + LError
  LVirtual := LSum - A;
  LError := (A - (LSum - LVirtual)) + (B - LVirtual);
  if LError = 0 then
    Exit(LSum);
  LBits := PUInt64(@LSum)^;
  LExponent := Integer((LBits shr 52) and $7FF);
  // a power of two has a smaller unit below it; tiny and huge numbers are left to the exact sum
  if (LExponent < 64) or (LExponent > 2000) or ((LBits and $000FFFFFFFFFFFFF) = 0) then
    Exit(AddExact(A, B));
  // the FPU rounds first to a 2048th of the unit of the last place: the two results differ only when the
  // exact sum is that near to the middle between two Doubles
  PUInt64(@LHalfUnit)^ := UInt64(LExponent - 53) shl 52;
  if Abs(LError) >= LHalfUnit * 0.99 then
    Exit(AddExact(A, B));
  Result := LSum;
end;
{$IFEND}

class function TX87Double.CanTruncate(const AValue, AMagnitude: Double): Boolean;
var
  LDistance: Double;
begin
  if not (Abs(AValue) < INTEGER_LIMIT) then
    Exit(False);
  LDistance := Abs(AValue - Round(AValue));
  Result := LDistance > AMagnitude * NATIVE_TOLERANCE;
end;

class function TX87Double.CanRound(const AValue, AMagnitude: Double): Boolean;
var
  LDistance: Double;
begin
  if not (Abs(AValue) < INTEGER_LIMIT) then
    Exit(False);
  LDistance := 0.5 - Abs(AValue - Round(AValue));
  Result := LDistance > AMagnitude * NATIVE_TOLERANCE;
end;

class function TX87Double.TruncMulAddExact(const ABase: Double; ACount: Integer; const AStep: Double): Integer;
begin
  Result := Integer((TSoftExtended.FromDouble(ABase) +
    TSoftExtended.FromInt64(ACount) * TSoftExtended.FromDouble(AStep)).Truncate);
end;

class function TX87Double.TruncMulAdd(const ABase: Double; ACount: Integer; const AStep: Double): Integer;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Integer(Trunc(ABase + ACount * AStep));
end;
{$ELSE}
var
  LProduct: Double;
  LValue: Double;
begin
  LProduct := ACount * AStep;
  LValue := ABase + LProduct;
  if CanTruncate(LValue, Abs(ABase) + Abs(LProduct)) then
    Result := Trunc(LValue)
  else
    Result := TruncMulAddExact(ABase, ACount, AStep);
end;
{$IFEND}

class function TX87Double.TruncOffsetDivideExact(const AValue: Double; AFirst, ASecond, ADivisor: Integer): Integer;
begin
  Result := Integer((((TSoftExtended.FromDouble(AValue) + TSoftExtended.FromInt64(AFirst)) +
    TSoftExtended.FromInt64(ASecond)) / TSoftExtended.FromInt64(ADivisor)).Truncate);
end;

class function TX87Double.TruncOffsetDivide(const AValue: Double; AFirst, ASecond, ADivisor: Integer): Integer;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Integer(Trunc((AValue + AFirst + ASecond) / ADivisor));
end;
{$ELSE}
var
  LValue: Double;
begin
  LValue := (AValue + AFirst + ASecond) / ADivisor;
  if CanTruncate(LValue, (Abs(AValue) + Abs(AFirst) + Abs(ASecond)) / Abs(ADivisor)) then
    Result := Trunc(LValue)
  else
    Result := TruncOffsetDivideExact(AValue, AFirst, ASecond, ADivisor);
end;
{$IFEND}

class function TX87Double.RoundMulDivideExact(const AValue: Double; AMultiplier, ADivisor,
  ASecondDivisor: Integer): Integer;
var
  LValue: TSoftExtended;
begin
  LValue := TSoftExtended.FromDouble(AValue) * TSoftExtended.FromInt64(AMultiplier) /
    TSoftExtended.FromInt64(ADivisor);
  if ASecondDivisor <> 1 then
    LValue := LValue / TSoftExtended.FromInt64(ASecondDivisor);
  Result := Integer(LValue.Round);
end;

class function TX87Double.RoundMulDivide(const AValue: Double; AMultiplier, ADivisor: Integer;
  ASecondDivisor: Integer): Integer;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  if ASecondDivisor <> 1 then
    Result := Integer(Round(AValue * AMultiplier / ADivisor / ASecondDivisor))
  else
    Result := Integer(Round(AValue * AMultiplier / ADivisor));
end;
{$ELSE}
var
  LValue: Double;
begin
  LValue := AValue * AMultiplier / ADivisor / ASecondDivisor;
  if CanRound(LValue, Abs(LValue)) then
    Result := Round(LValue)
  else
    Result := RoundMulDivideExact(AValue, AMultiplier, ADivisor, ASecondDivisor);
end;
{$IFEND}

class function TX87Double.RoundQuotientExact(const ANumerator, ADenominator: Double): Integer;
begin
  Result := Integer((TSoftExtended.FromDouble(ANumerator) / TSoftExtended.FromDouble(ADenominator)).Round);
end;

class function TX87Double.RoundQuotient(const ANumerator, ADenominator: Double): Integer;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Integer(Round(ANumerator / ADenominator));
end;
{$ELSE}
var
  LValue: Double;
begin
  LValue := ANumerator / ADenominator;
  if CanRound(LValue, Abs(LValue)) then
    Result := Round(LValue)
  else
    Result := RoundQuotientExact(ANumerator, ADenominator);
end;
{$IFEND}

class function TX87Double.RoundProductExact(const A, B: Double): Integer;
begin
  Result := Integer((TSoftExtended.FromDouble(A) * TSoftExtended.FromDouble(B)).Round);
end;

class function TX87Double.RoundProduct(const A, B: Double): Integer;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Integer(Round(A * B));
end;
{$ELSE}
var
  LValue: Double;
begin
  LValue := A * B;
  if CanRound(LValue, Abs(LValue)) then
    Result := Round(LValue)
  else
    Result := RoundProductExact(A, B);
end;
{$IFEND}

class function TX87Double.TruncQuotientExact(const ANumerator, ADenominator: Double): Integer;
begin
  if ADenominator = 0 then
    Exit(0);
  Result := Integer((TSoftExtended.FromDouble(ANumerator) / TSoftExtended.FromDouble(ADenominator)).Truncate);
end;

class function TX87Double.TruncQuotient(const ANumerator, ADenominator: Double): Integer;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Integer(Trunc(ANumerator / ADenominator));
end;
{$ELSE}
var
  LValue: Double;
begin
  LValue := ANumerator / ADenominator;
  if CanTruncate(LValue, Abs(LValue)) then
    Result := Trunc(LValue)
  else
    Result := TruncQuotientExact(ANumerator, ADenominator);
end;
{$IFEND}

class function TX87Double.TruncMulDivideExact(const AValue: Double; AMultiplier, ADivisor: Integer): Integer;
begin
  if ADivisor = 0 then
    Exit(0);
  Result := Integer((TSoftExtended.FromInt64(AMultiplier) * TSoftExtended.FromDouble(AValue) /
    TSoftExtended.FromInt64(ADivisor)).Truncate);
end;

class function TX87Double.TruncMulDivide(const AValue: Double; AMultiplier, ADivisor: Integer): Integer;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Integer(Trunc(AMultiplier * AValue / ADivisor));
end;
{$ELSE}
var
  LValue: Double;
begin
  LValue := AMultiplier * AValue / ADivisor;
  if CanTruncate(LValue, Abs(LValue)) then
    Result := Trunc(LValue)
  else
    Result := TruncMulDivideExact(AValue, AMultiplier, ADivisor);
end;
{$IFEND}

class function TX87Double.RoundScaledInverseExact(AScale, ANumerator, ADenominator: Integer): Integer;
var
  LScale: TSoftExtended;
begin
  if (ANumerator = 0) or (ADenominator = 0) then
    Exit(0);
  LScale := TSoftExtended.FromInt64(AScale);
  Result := Integer((LScale / (TSoftExtended.FromInt64(ANumerator) / TSoftExtended.FromInt64(ADenominator)) *
    LScale).Round);
end;

class function TX87Double.RoundScaledInverse(AScale, ANumerator, ADenominator: Integer): Integer;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Integer(Round(AScale / (ANumerator / ADenominator) * AScale));
end;
{$ELSE}
var
  LValue: Double;
begin
  if (ANumerator = 0) or (ADenominator = 0) then
    Exit(0);
  LValue := AScale / (ANumerator / ADenominator) * AScale;
  if CanRound(LValue, Abs(LValue)) then
    Result := Round(LValue)
  else
    Result := RoundScaledInverseExact(AScale, ANumerator, ADenominator);
end;
{$IFEND}

class function TX87Double.TruncReciprocalProductExact(AScale, AFirst, ASecond: Integer): Integer;
var
  LScale: TSoftExtended;
begin
  if (AFirst = 0) or (ASecond = 0) then
    Exit(0);
  LScale := TSoftExtended.FromInt64(AScale);
  Result := Integer(((LScale / TSoftExtended.FromInt64(AFirst)) * (LScale / TSoftExtended.FromInt64(ASecond)) *
    LScale).Truncate);
end;

class function TX87Double.TruncReciprocalProduct(AScale, AFirst, ASecond: Integer): Integer;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Integer(Trunc((AScale / AFirst) * (AScale / ASecond) * AScale));
end;
{$ELSE}
var
  LValue: Double;
begin
  if (AFirst = 0) or (ASecond = 0) then
    Exit(0);
  LValue := (AScale / AFirst) * (AScale / ASecond) * AScale;
  if CanTruncate(LValue, Abs(LValue)) then
    Result := Trunc(LValue)
  else
    Result := TruncReciprocalProductExact(AScale, AFirst, ASecond);
end;
{$IFEND}

class function TX87Double.TruncFixedReciprocal(AValue: Integer): Integer;
begin
  if AValue = 0 then
    Result := 0
  else
    Result := Integer(Int64($100000000) div AValue);
end;

class function TX87Double.Multiply(const A, B: Double): Double;
begin
{$IF SizeOf(Extended) > SizeOf(Double)}
  Result := A * B;
{$ELSE}
  Result := (TSoftExtended.FromDouble(A) * TSoftExtended.FromDouble(B)).ToDouble;
{$IFEND}
end;

class function TX87Double.SubtractProduct(const AMinuend, A, B: Double): Double;
begin
{$IF SizeOf(Extended) > SizeOf(Double)}
  Result := AMinuend - A * B;
{$ELSE}
  Result := (TSoftExtended.FromDouble(AMinuend) -
    TSoftExtended.FromDouble(A) * TSoftExtended.FromDouble(B)).ToDouble;
{$IFEND}
end;

class function TX87Double.DifferenceQuotient(const AEnd, AStart: Double; ACount: Integer): Double;
begin
{$IF SizeOf(Extended) > SizeOf(Double)}
  Result := (AEnd - AStart) / ACount;
{$ELSE}
  Result := ((TSoftExtended.FromDouble(AEnd) - TSoftExtended.FromDouble(AStart)) /
    TSoftExtended.FromInt64(ACount)).ToDouble;
{$IFEND}
end;

end.
