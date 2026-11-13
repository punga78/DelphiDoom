{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - the noise                     }
{                                                                              }
{  Port of renderer\tr_noise.c of Quake III Arena (id Software, GPL v2 or      }
{  later): R_NoiseInit and R_NoiseGet4f. Based on the Quake III Arena GPL      }
{  Source Code (id Software).                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.Noise;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The noise of the "noise" waveform and of <c>deformVertexes normal</c>: a table of 256 values and a
  ///   permutation, filled by <c>R_NoiseInit</c> with <c>srand(1001)</c> and <c>rand()</c> of the Microsoft
  ///   runtime (a linear congruential generator; the table is therefore the same on every machine). The tables
  ///   are instance fields (the original has two <c>static</c> arrays).
  /// </summary>
  TQ3Noise = class
  strict private
    FTable: array[0..255] of Single;
    FPermutation: array[0..255] of Integer;
    function Value(const AX, AY, AZ, AT: Integer): Single;
  public
    /// <summary>R_NoiseInit</summary>
    constructor Create;
    /// <summary>R_NoiseGet4f: the noise at a point of space and time</summary>
    function Get4f(const AX, AY, AZ, AT: Single): Single;
  end;

implementation

uses
  DelphiDoom.Decl.Q3Shader.Calc.Types, DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

const
  RAND_MAX = $7FFF;

function Lerp(const AFirst, ASecond, AWeight: Single): Single;
var
  LInverse, LLeft, LRight: Single;
begin
  // ( a * ( 1.0f - w ) + b * w ): each operation rounded to a float
  LInverse := 1.0 - AWeight;
  LLeft := AFirst * LInverse;
  LRight := ASecond * AWeight;
  Result := LLeft + LRight;
end;

{ TQ3Noise }

constructor TQ3Noise.Create;
var
  LIndex: Integer;
  LSeed: Cardinal;
  LRatio, LScaled: Single;
  LValue: Double;

  function NextRand: Integer;
  begin
    LSeed := LSeed * 214013 + 2531011;
    Result := (LSeed shr 16) and RAND_MAX;
  end;

begin
  inherited Create;
  LSeed := 1001;
  for LIndex := 0 to 255 do
  begin
    // ( ( rand() / ( float ) RAND_MAX ) * 2.0 - 1.0 )
    LRatio := NextRand;
    LRatio := LRatio / Single(RAND_MAX);
    LValue := Double(LRatio) * 2.0 - 1.0;
    FTable[LIndex] := LValue;
    // ( unsigned char ) ( rand() / ( float ) RAND_MAX * 255 )
    LRatio := NextRand;
    LRatio := LRatio / Single(RAND_MAX);
    LScaled := LRatio * 255;
    FPermutation[LIndex] := TQ3CMath.FloatToInt(LScaled) and $FF;
  end;
end;

function TQ3Noise.Value(const AX, AY, AZ, AT: Integer): Single;
var
  LIndex: Integer;
begin
  // INDEX( x, y, z, t ) = VAL( x + VAL( y + VAL( z + VAL( t ) ) ) ), VAL( a ) = perm[ a & NOISE_MASK ]
  LIndex := FPermutation[AT and 255];
  LIndex := FPermutation[(AZ + LIndex) and 255];
  LIndex := FPermutation[(AY + LIndex) and 255];
  LIndex := FPermutation[(AX + LIndex) and 255];
  Result := FTable[LIndex];
end;

function TQ3Noise.Get4f(const AX, AY, AZ, AT: Single): Single;
var
  LStep: Integer;
  LIx, LIy, LIz, LIt: Integer;
  LFx, LFy, LFz, LFt: Single;
  LFront, LBack: array[0..3] of Single;
  LFrontValue, LBackValue: Single;
  LValues: array[0..1] of Single;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  LIx := TQ3CMath.FloatToInt(TQ3CMath.FloorValue(AX));
  LFx := AX - Single(LIx);
  LIy := TQ3CMath.FloatToInt(TQ3CMath.FloorValue(AY));
  LFy := AY - Single(LIy);
  LIz := TQ3CMath.FloatToInt(TQ3CMath.FloorValue(AZ));
  LFz := AZ - Single(LIz);
  LIt := TQ3CMath.FloatToInt(TQ3CMath.FloorValue(AT));
  LFt := AT - Single(LIt);
  for LStep := 0 to 1 do
  begin
    LFront[0] := Value(LIx, LIy, LIz, LIt + LStep);
    LFront[1] := Value(LIx + 1, LIy, LIz, LIt + LStep);
    LFront[2] := Value(LIx, LIy + 1, LIz, LIt + LStep);
    LFront[3] := Value(LIx + 1, LIy + 1, LIz, LIt + LStep);
    LBack[0] := Value(LIx, LIy, LIz + 1, LIt + LStep);
    LBack[1] := Value(LIx + 1, LIy, LIz + 1, LIt + LStep);
    LBack[2] := Value(LIx, LIy + 1, LIz + 1, LIt + LStep);
    LBack[3] := Value(LIx + 1, LIy + 1, LIz + 1, LIt + LStep);
    LFrontValue := Lerp(Lerp(LFront[0], LFront[1], LFx), Lerp(LFront[2], LFront[3], LFx), LFy);
    LBackValue := Lerp(Lerp(LBack[0], LBack[1], LFx), Lerp(LBack[2], LBack[3], LFx), LFy);
    LValues[LStep] := Lerp(LFrontValue, LBackValue, LFz);
  end;
  Result := Lerp(LValues[0], LValues[1], LFt);
end;

end.
