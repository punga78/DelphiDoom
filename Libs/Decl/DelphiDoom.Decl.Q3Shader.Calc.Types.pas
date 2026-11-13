{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - types and C arithmetic        }
{                                                                              }
{  The constants and the buffers of renderer\tr_shade_calc.c of Quake III      }
{  Arena (id Software, GPL v2 or later): FUNCTABLE_SIZE, tess.xyz/normal/      }
{  texCoords, backEnd.currentEntity->e and the conversions (myftol, Q_rsqrt)   }
{  the functions use. Based on the Quake III Arena GPL Source Code             }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.Types;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions;

const
  /// <summary>FUNCTABLE_SIZE: the length of the sine, square, triangle and sawtooth tables</summary>
  Q3_FUNCTABLE_SIZE = 1024;
  /// <summary>FUNCTABLE_MASK</summary>
  Q3_FUNCTABLE_MASK = Q3_FUNCTABLE_SIZE - 1;

type
  /// <summary>One of the function tables (tr.sinTable ...), Q3_FUNCTABLE_SIZE values</summary>
  TQ3FuncTable = TArray<Single>;

  /// <summary>
  ///   What the functions read of <c>backEnd.currentEntity-&gt;e</c>: <c>shaderRGBA</c> and
  ///   <c>shaderTexCoord</c>. <c>Present</c> false is <c>currentEntity == NULL</c>.
  /// </summary>
  TQ3EntityShading = record
    Present: Boolean;
    ShaderRGBA: array[0..3] of Byte;
    ShaderTexCoord: array[0..1] of Single;
  end;

  /// <summary>
  ///   The part of <c>tess</c> and <c>backEnd</c> the shader time functions use. The buffers are the arrays of
  ///   the original flattened: <c>Xyz</c> and <c>Normal</c> four floats per vertex (<c>vec4_t</c>, the fourth is
  ///   not touched), <c>TexCoords</c> four floats per vertex (<c>vec2_t texCoords[][2]</c>: the texture set
  ///   then the lightmap set). The time is an argument: nothing reads a clock.
  /// </summary>
  TQ3ShaderTess = record
    NumVertexes: Integer;
    /// <summary>tess.shaderTime (seconds, with the time offset of the shader already taken)</summary>
    ShaderTime: Single;
    /// <summary>backEnd.refdef.time (milliseconds, for the bulge)</summary>
    RefDefTime: Integer;
    Xyz: TArray<Single>;
    Normal: TArray<Single>;
    TexCoords: TArray<Single>;
    /// <summary>backEnd.or.viewOrigin</summary>
    ViewOrigin: array[0..2] of Single;
    Entity: TQ3EntityShading;
  end;

  /// <summary>
  ///   <c>ri.Error(ERR_DROP, ...)</c> of the time functions (a function that has no table, a buffer that is too
  ///   short): the original drops the frame, here the exception goes to the caller
  /// </summary>
  EDeclQ3ShaderCalcException = class(EIdLibException);

  /// <summary>The conversions of C that the functions use, with the result of the x86 for what C leaves undefined</summary>
  TQ3CMath = class sealed
  public
    /// <summary>
    ///   <c>(int)f</c> and <c>myftol(f)</c> without the x86 asm (<c>#define myftol(x) ((int)(x))</c>): truncation;
    ///   NaN and a value out of the range of an int give the "integer indefinite" of the processor, $80000000
    /// </summary>
    class function FloatToInt(const AValue: Double): Integer; static;
    /// <summary><c>floor(x)</c> of the C library (a double, not an integer)</summary>
    class function FloorValue(const AValue: Double): Double; static;
    /// <summary>
    ///   <c>Q_rsqrt</c> of q_math.c: the first iteration of the Newton method from the magic constant
    ///   ($5f3759df); every operation is rounded to a float. It does not mask the FPU exceptions (it runs
    ///   for every vertex): the caller holds a <c>TQ3FloatMask</c>.
    /// </summary>
    class function Rsqrt(const ANumber: Single): Single; static;
    /// <summary>
    ///   <c>VectorNormalizeFast</c> on the three floats at <c>AIndex</c> of a buffer (the vector is multiplied
    ///   by <c>Q_rsqrt(v . v)</c>, so a null vector stays null only by luck: as the original)
    /// </summary>
    class procedure NormalizeFast(var ABuffer: TArray<Single>; const AIndex: Integer); static;
    /// <summary>A buffer that must hold at least <c>ACount * AStride</c> floats</summary>
    class procedure RequireFloats(const ABuffer: TArray<Single>; const ACount, AStride: Integer;
      const AName: string); static;
    /// <summary>A byte buffer of four bytes per vertex</summary>
    class procedure RequireBytes(const ABuffer: TBytes; const ACount: Integer); static;
  end;

implementation

uses
  System.Math;

const
  SBufferTooShort = 'buffer %s is too short for %d vertexes';

class function TQ3CMath.FloatToInt(const AValue: Double): Integer;
begin
  // IsNan does not compare: an ordered compare with a NaN may raise the invalid operation exception of the FPU
  if IsNan(AValue) or (AValue >= 2147483648.0) or (AValue < -2147483648.0) then
    Result := Integer($80000000)
  else
    Result := Trunc(AValue);
end;

class function TQ3CMath.FloorValue(const AValue: Double): Double;
begin
  Result := Int(AValue);
  if (AValue < 0) and (Result <> AValue) then
    Result := Result - 1;
end;

class function TQ3CMath.Rsqrt(const ANumber: Single): Single;
const
  ThreeHalfs: Single = 1.5;
var
  LHalf, LY, LStep: Single;
  LBits: Integer;
begin
  LHalf := ANumber * 0.5;
  LY := ANumber;
  LBits := PInteger(@LY)^;
  // i >> 1 on a signed long: arithmetic
  if LBits < 0 then
    LBits := $5f3759df - ((LBits shr 1) or Integer($80000000))
  else
    LBits := $5f3759df - (LBits shr 1);
  LY := PSingle(@LBits)^;
  LStep := LHalf * LY;
  LStep := LStep * LY;
  LStep := ThreeHalfs - LStep;
  Result := LY * LStep;
end;

class procedure TQ3CMath.NormalizeFast(var ABuffer: TArray<Single>; const AIndex: Integer);
var
  LSum, LInverse, LTerm: Single;
begin
  LSum := ABuffer[AIndex] * ABuffer[AIndex];
  LTerm := ABuffer[AIndex + 1] * ABuffer[AIndex + 1];
  LSum := LSum + LTerm;
  LTerm := ABuffer[AIndex + 2] * ABuffer[AIndex + 2];
  LSum := LSum + LTerm;
  LInverse := Rsqrt(LSum);
  ABuffer[AIndex] := ABuffer[AIndex] * LInverse;
  ABuffer[AIndex + 1] := ABuffer[AIndex + 1] * LInverse;
  ABuffer[AIndex + 2] := ABuffer[AIndex + 2] * LInverse;
end;

class procedure TQ3CMath.RequireFloats(const ABuffer: TArray<Single>; const ACount, AStride: Integer;
  const AName: string);
begin
  if Length(ABuffer) < ACount * AStride then
    raise EDeclQ3ShaderCalcException.CreateFmt(SBufferTooShort, [AName, ACount]);
end;

class procedure TQ3CMath.RequireBytes(const ABuffer: TBytes; const ACount: Integer);
begin
  if Length(ABuffer) < ACount * 4 then
    raise EDeclQ3ShaderCalcException.CreateFmt(SBufferTooShort, ['colors', ACount]);
end;

end.
