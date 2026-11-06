{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the input of the parity tests  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Samples;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>
  ///   The inputs of the parity tests: the edge values, a generator of pseudo random numbers
  ///   that always gives the same series, and the pairs built from them. The temporary harness
  ///   that wrote the golden files from the old code uses this same unit.
  /// </summary>
  TMathCoreSamples = class
  public
    const
      RANDOM_PAIRS = 4000;
      RANDOM_FLOATS = 3000;
      INITIAL_STATE = $2545F491;
    /// <summary>Values at the edge of the 16.16 numbers: 0, signs, 1.0, 0.5, limits, bit patterns</summary>
    class function EdgeValues: TArray<Integer>; static;
    /// <summary>xorshift32: the next number of the series</summary>
    class function NextRandom(var AState: Cardinal): Cardinal; static;
    /// <summary>All the pairs of edge values, then RANDOM_PAIRS pairs of the series</summary>
    class procedure BuildPairs(out AFirst, ASecond: TArray<Integer>); static;
    /// <summary>A number with a fraction, between -2^15 and 2^15 (nice for the float functions)</summary>
    class function NextFloat(var AState: Cardinal): Double; static;
    class function NextVector3(var AState: Cardinal): TVec3; static;
    class function NextVector2(var AState: Cardinal): TVec2; static;
    /// <summary>A text of 0..24 characters; with AWide the characters go up to 2000</summary>
    class function NextText(var AState: Cardinal; const AWide: Boolean): string; static;
  end;

implementation

{ TMathCoreSamples }

class function TMathCoreSamples.EdgeValues: TArray<Integer>;
begin
  Result := TArray<Integer>.Create(
    0, 1, -1, 2, -2, 3, 7, 255, 256, 511, 512, 513, 32767, 32768, 65535, 65536, 65537,
    -65535, -65536, -65537, 98304, -98304, 1048576, 16777216, 1073741823, 1073741824,
    -1073741824, -1073741823, 2147483647, -2147483647, Integer($80000000), 2147483646,
    305419896, -305419896, 16711935, Integer($F0F0F0F0), 123456, -123456, 40000, 524288);
end;

class function TMathCoreSamples.NextRandom(var AState: Cardinal): Cardinal;
begin
  AState := AState xor (AState shl 13);
  AState := AState xor (AState shr 17);
  AState := AState xor (AState shl 5);
  Result := AState;
end;

class procedure TMathCoreSamples.BuildPairs(out AFirst, ASecond: TArray<Integer>);
var
  LEdges: TArray<Integer>;
  LState: Cardinal;
  LIndex: Integer;
  LJndex: Integer;
  LCount: Integer;
begin
  LEdges := EdgeValues;
  SetLength(AFirst, Length(LEdges) * Length(LEdges) + RANDOM_PAIRS);
  SetLength(ASecond, Length(AFirst));
  LCount := 0;
  for LIndex := 0 to High(LEdges) do
    for LJndex := 0 to High(LEdges) do
    begin
      AFirst[LCount] := LEdges[LIndex];
      ASecond[LCount] := LEdges[LJndex];
      Inc(LCount);
    end;
  LState := INITIAL_STATE;
  for LIndex := 1 to RANDOM_PAIRS do
  begin
    // a mix of sizes: full numbers, medium ones and small ones
    case LIndex mod 3 of
      0:
        begin
          AFirst[LCount] := Integer(NextRandom(LState));
          ASecond[LCount] := Integer(NextRandom(LState));
        end;
      1:
        begin
          AFirst[LCount] := Integer(NextRandom(LState)) div 4096;
          ASecond[LCount] := Integer(NextRandom(LState)) div 1024;
        end;
    else
      begin
        AFirst[LCount] := Integer(NextRandom(LState)) div 65536;
        ASecond[LCount] := Integer(NextRandom(LState)) div 16;
      end;
    end;
    Inc(LCount);
  end;
end;

class function TMathCoreSamples.NextFloat(var AState: Cardinal): Double;
begin
  Result := Integer(NextRandom(AState)) / 65536.0;
end;

class function TMathCoreSamples.NextVector3(var AState: Cardinal): TVec3;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
    Result[LIndex] := Integer(NextRandom(AState)) / 1048576.0;
end;

class function TMathCoreSamples.NextVector2(var AState: Cardinal): TVec2;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result[LIndex] := Integer(NextRandom(AState)) / 1048576.0;
end;

class function TMathCoreSamples.NextText(var AState: Cardinal; const AWide: Boolean): string;
var
  LLength: Integer;
  LIndex: Integer;
  LLimit: Cardinal;
begin
  LLength := NextRandom(AState) mod 25;
  if AWide then
    LLimit := 2000
  else
    LLimit := 255;
  SetLength(Result, LLength);
  for LIndex := 1 to LLength do
    Result[LIndex] := Char(1 + NextRandom(AState) mod LLimit);
end;

end.
