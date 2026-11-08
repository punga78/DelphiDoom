{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the assembler replacements - the parity runner         }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Asm.Parity;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  TParityBinary = reference to function(A, B: Integer): Integer;
  TParityBinaryUnsigned = reference to function(A, B: Cardinal): Cardinal;
  TParityUnary = reference to function(A: Integer): Integer;

  /// <summary>
  ///   Runs two functions (the old assembler and the Pascal one) on the limit values and on a lot
  ///   of pseudo random inputs, and fails with the first input on which they differ. The inputs
  ///   are always the same (the generator has a fixed seed). Two functions are equal if they
  ///   give the same number or if both raise an exception (the old code raised the exception of
  ///   the processor, the Pascal one an exception of its own).
  /// </summary>
  TParityRunner = class
  strict private
    class function Describe(AValue: Cardinal; ARaised: Boolean): string; static;
    class function CallBinary(const AFunction: TParityBinary; A, B: Integer;
      out AResult: Integer): Boolean; static;
    class function CallUnsigned(const AFunction: TParityBinaryUnsigned; A, B: Cardinal;
      out AResult: Cardinal): Boolean; static;
  public
    /// <summary>The values that sit on the borders of 32 bit arithmetic and of 16.16 numbers</summary>
    class function EdgeValues: TArray<Integer>; static;
    /// <summary>The next number of a xorshift32 generator; the state must not be zero</summary>
    class function NextRandom(var AState: Cardinal): Cardinal; static;
    /// <summary>
    ///   A pseudo random number whose size changes from call to call: from 1 bit to 32 bits, positive
    ///   or negative, so that the small, the big and the overflowing cases all happen
    /// </summary>
    class function NextScaled(var AState: Cardinal): Integer; static;

    class procedure CompareBinary(const AName: string; const AOracle, ACandidate: TParityBinary;
      ARandomPairs: Integer); static;
    class procedure CompareBinaryUnsigned(const AName: string;
      const AOracle, ACandidate: TParityBinaryUnsigned; ARandomPairs: Integer); static;
    class procedure CompareUnary(const AName: string; const AOracle, ACandidate: TParityUnary;
      ARandomValues: Integer); static;
  end;

implementation

{ TParityRunner }

class function TParityRunner.Describe(AValue: Cardinal; ARaised: Boolean): string;
begin
  if ARaised then
    Result := 'exception'
  else
    Result := Format('$%.8x (%d)', [AValue, Integer(AValue)]);
end;

class function TParityRunner.CallBinary(const AFunction: TParityBinary; A, B: Integer;
  out AResult: Integer): Boolean;
begin
  Result := True;
  AResult := 0;
  try
    AResult := AFunction(A, B);
  except
    on E: Exception do
      Result := False;
  end;
end;

class function TParityRunner.CallUnsigned(const AFunction: TParityBinaryUnsigned; A, B: Cardinal;
  out AResult: Cardinal): Boolean;
begin
  Result := True;
  AResult := 0;
  try
    AResult := AFunction(A, B);
  except
    on E: Exception do
      Result := False;
  end;
end;

class function TParityRunner.EdgeValues: TArray<Integer>;
begin
  Result := [
    0, 1, -1, 2, -2, 3, -3, 7, 8, 9, 15, 16, 17, 31, 32, 33, 63, 64, 65,
    127, 128, 129, -127, -128, -129, 255, 256, 257, -255, -256, -257,
    $3FFF, $4000, $4001, -$3FFF, -$4000, -$4001,
    $7FFF, $8000, $8001, -$7FFF, -$8000, -$8001,
    $FFFF, $10000, $10001, -$FFFF, -$10000, -$10001,
    $1FFFF, $20000, $20001, $2AAAA, $55555, $7FFFF, $80000,
    3 * $10000, -3 * $10000, 100 * $10000, -100 * $10000,
    $7FFFFF, $800000, $FFFFFF, $1000000, $7FFFFFF, $8000000,
    $12345678, -$12345678, $1234567, $7FFFFFFE, $7FFFFFFF,
    Integer($80000000), Integer($80000001), Integer($80000002),
    Integer($FFFF0000), Integer($FFFF8000), Integer($AAAAAAAA), $55555555];
end;

class function TParityRunner.NextRandom(var AState: Cardinal): Cardinal;
begin
  AState := AState xor (AState shl 13);
  AState := AState xor (AState shr 17);
  AState := AState xor (AState shl 5);
  Result := AState;
end;

class function TParityRunner.NextScaled(var AState: Cardinal): Integer;
var
  LBits: Integer;
  LValue: Cardinal;
begin
  LValue := NextRandom(AState);
  LBits := Integer(NextRandom(AState) and 31) + 1;
  if LBits < 32 then
    LValue := LValue and ((Cardinal(1) shl LBits) - 1);
  if (NextRandom(AState) and 1) <> 0 then
    Result := -Integer(LValue)
  else
    Result := Integer(LValue);
end;

class procedure TParityRunner.CompareBinary(const AName: string;
  const AOracle, ACandidate: TParityBinary; ARandomPairs: Integer);
var
  LEdges: TArray<Integer>;
  LState: Cardinal;
  LIndexA: Integer;
  LIndexB: Integer;
  LCount: Integer;
  A: Integer;
  B: Integer;

  procedure Check(AFirst, ASecond: Integer);
  var
    LOracleValue: Integer;
    LCandidateValue: Integer;
    LOracleOk: Boolean;
    LCandidateOk: Boolean;
  begin
    LOracleOk := CallBinary(AOracle, AFirst, ASecond, LOracleValue);
    LCandidateOk := CallBinary(ACandidate, AFirst, ASecond, LCandidateValue);
    if (LOracleOk <> LCandidateOk) or (LOracleOk and (LOracleValue <> LCandidateValue)) then
      Assert.Fail(Format('%s: a=$%.8x b=$%.8x old=%s new=%s',
        [AName, Cardinal(AFirst), Cardinal(ASecond),
         Describe(Cardinal(LOracleValue), not LOracleOk),
         Describe(Cardinal(LCandidateValue), not LCandidateOk)]));
  end;

begin
  LEdges := EdgeValues;
  for LIndexA := 0 to High(LEdges) do
    for LIndexB := 0 to High(LEdges) do
      Check(LEdges[LIndexA], LEdges[LIndexB]);

  LState := $2545F491;
  for LCount := 1 to ARandomPairs do
  begin
    A := NextScaled(LState);
    B := NextScaled(LState);
    Check(A, B);
    // also the plain 32 bit values, whatever their size
    Check(Integer(NextRandom(LState)), Integer(NextRandom(LState)));
  end;
end;

class procedure TParityRunner.CompareBinaryUnsigned(const AName: string;
  const AOracle, ACandidate: TParityBinaryUnsigned; ARandomPairs: Integer);
var
  LEdges: TArray<Integer>;
  LState: Cardinal;
  LIndexA: Integer;
  LIndexB: Integer;
  LCount: Integer;

  procedure Check(AFirst, ASecond: Cardinal);
  var
    LOracleValue: Cardinal;
    LCandidateValue: Cardinal;
    LOracleOk: Boolean;
    LCandidateOk: Boolean;
  begin
    LOracleOk := CallUnsigned(AOracle, AFirst, ASecond, LOracleValue);
    LCandidateOk := CallUnsigned(ACandidate, AFirst, ASecond, LCandidateValue);
    if (LOracleOk <> LCandidateOk) or (LOracleOk and (LOracleValue <> LCandidateValue)) then
      Assert.Fail(Format('%s: a=$%.8x b=$%.8x old=%s new=%s',
        [AName, AFirst, ASecond,
         Describe(LOracleValue, not LOracleOk), Describe(LCandidateValue, not LCandidateOk)]));
  end;

begin
  LEdges := EdgeValues;
  for LIndexA := 0 to High(LEdges) do
    for LIndexB := 0 to High(LEdges) do
      Check(Cardinal(LEdges[LIndexA]), Cardinal(LEdges[LIndexB]));

  LState := $1B873593;
  for LCount := 1 to ARandomPairs do
  begin
    Check(Cardinal(NextScaled(LState)), Cardinal(NextScaled(LState)));
    Check(NextRandom(LState), NextRandom(LState));
  end;
end;

class procedure TParityRunner.CompareUnary(const AName: string;
  const AOracle, ACandidate: TParityUnary; ARandomValues: Integer);
var
  LEdges: TArray<Integer>;
  LState: Cardinal;
  LIndex: Integer;
  LCount: Integer;
  LValue: Integer;

  procedure Check(AValue: Integer);
  var
    LOracleValue: Integer;
    LCandidateValue: Integer;
  begin
    LOracleValue := AOracle(AValue);
    LCandidateValue := ACandidate(AValue);
    if LOracleValue <> LCandidateValue then
      Assert.Fail(Format('%s: x=$%.8x old=$%.8x new=$%.8x',
        [AName, Cardinal(AValue), Cardinal(LOracleValue), Cardinal(LCandidateValue)]));
  end;

begin
  LEdges := EdgeValues;
  for LIndex := 0 to High(LEdges) do
    Check(LEdges[LIndex]);

  LState := $6C078965;
  for LCount := 1 to ARandomValues do
  begin
    LValue := NextScaled(LState);
    Check(LValue);
    Check(Integer(NextRandom(LState)));
  end;
end;

end.
