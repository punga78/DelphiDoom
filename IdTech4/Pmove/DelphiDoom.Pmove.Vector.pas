{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the vector operations of the movement           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): the macros and  }
{  functions of q_shared.h and q_math.c that the movement uses (VectorLength,  }
{  VectorNormalize, VectorNormalize2, VectorMA, CrossProduct) and              }
{  PM_ClipVelocity of bg_pmove.c. Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Vector;

// the C code rounds every float operation on its own (SSE, no fused multiply-add): the operations here are
// one per statement, into a Single, which gives the same bits at Win32 (x87) and at Win64 (SSE)
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Collision.Q3.Types;

type
  /// <summary>
  ///   The vector functions of Quake III with the rounding of the C code: a float operation at a time, the
  ///   square root through a Double. The vector arguments may alias the result, as the macros allow
  /// </summary>
  TPmoveVector = class
  public
    /// <summary>VectorCopy</summary>
    class procedure Copy(const ASource: TQ3Vec3; out ADest: TQ3Vec3); static; inline;
    /// <summary>VectorClear</summary>
    class procedure Clear(out AVector: TQ3Vec3); static; inline;
    /// <summary>VectorAdd</summary>
    class procedure Add(const AFirst, ASecond: TQ3Vec3; out AResult: TQ3Vec3); static;
    /// <summary>VectorSubtract</summary>
    class procedure Subtract(const AFirst, ASecond: TQ3Vec3; out AResult: TQ3Vec3); static;
    /// <summary>VectorScale</summary>
    class procedure Scale(const AVector: TQ3Vec3; const AScale: Single; out AResult: TQ3Vec3); static;
    /// <summary>VectorMA: AResult = AVector + AScale * ADirection</summary>
    class procedure MultiplyAdd(const AVector: TQ3Vec3; const AScale: Single; const ADirection: TQ3Vec3;
      out AResult: TQ3Vec3); static;
    /// <summary>CrossProduct</summary>
    class procedure Cross(const AFirst, ASecond: TQ3Vec3; out AResult: TQ3Vec3); static;
    /// <summary>DotProduct</summary>
    class function Dot(const AFirst, ASecond: TQ3Vec3): Single; static;
    /// <summary>VectorLength: the square root of the float sum, taken as a double</summary>
    class function Length(const AVector: TQ3Vec3): Single; static;
    /// <summary>VectorNormalize: returns the length, the vector is left alone when it is zero</summary>
    class function Normalize(var AVector: TQ3Vec3): Single; static;
    /// <summary>VectorNormalize2</summary>
    class function Normalize2(const AVector: TQ3Vec3; out AResult: TQ3Vec3): Single; static;
    /// <summary>PM_ClipVelocity: slide off of the impacting surface</summary>
    class procedure ClipVelocity(const AIn, ANormal: TQ3Vec3; out AOut: TQ3Vec3; const AOverBounce: Single); static;
    /// <summary>The square root as the C code takes it: a float operand, a double root, a float result</summary>
    class function SquareRoot(const AValue: Single): Single; static;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Math;

class procedure TPmoveVector.Copy(const ASource: TQ3Vec3; out ADest: TQ3Vec3);
begin
  ADest[0] := ASource[0];
  ADest[1] := ASource[1];
  ADest[2] := ASource[2];
end;

class procedure TPmoveVector.Clear(out AVector: TQ3Vec3);
begin
  AVector[0] := 0;
  AVector[1] := 0;
  AVector[2] := 0;
end;

class procedure TPmoveVector.Add(const AFirst, ASecond: TQ3Vec3; out AResult: TQ3Vec3);
var
  LValue: Single;
begin
  LValue := AFirst[0] + ASecond[0];
  AResult[0] := LValue;
  LValue := AFirst[1] + ASecond[1];
  AResult[1] := LValue;
  LValue := AFirst[2] + ASecond[2];
  AResult[2] := LValue;
end;

class procedure TPmoveVector.Subtract(const AFirst, ASecond: TQ3Vec3; out AResult: TQ3Vec3);
var
  LValue: Single;
begin
  LValue := AFirst[0] - ASecond[0];
  AResult[0] := LValue;
  LValue := AFirst[1] - ASecond[1];
  AResult[1] := LValue;
  LValue := AFirst[2] - ASecond[2];
  AResult[2] := LValue;
end;

class procedure TPmoveVector.Scale(const AVector: TQ3Vec3; const AScale: Single; out AResult: TQ3Vec3);
var
  LValue: Single;
begin
  LValue := AVector[0] * AScale;
  AResult[0] := LValue;
  LValue := AVector[1] * AScale;
  AResult[1] := LValue;
  LValue := AVector[2] * AScale;
  AResult[2] := LValue;
end;

class procedure TPmoveVector.MultiplyAdd(const AVector: TQ3Vec3; const AScale: Single; const ADirection: TQ3Vec3;
  out AResult: TQ3Vec3);
var
  LProduct, LValue: Single;
begin
  LProduct := AScale * ADirection[0];
  LValue := AVector[0] + LProduct;
  AResult[0] := LValue;
  LProduct := AScale * ADirection[1];
  LValue := AVector[1] + LProduct;
  AResult[1] := LValue;
  LProduct := AScale * ADirection[2];
  LValue := AVector[2] + LProduct;
  AResult[2] := LValue;
end;

class procedure TPmoveVector.Cross(const AFirst, ASecond: TQ3Vec3; out AResult: TQ3Vec3);
var
  LLeft, LRight, LValue: Single;
begin
  LLeft := AFirst[1] * ASecond[2];
  LRight := AFirst[2] * ASecond[1];
  LValue := LLeft - LRight;
  AResult[0] := LValue;
  LLeft := AFirst[2] * ASecond[0];
  LRight := AFirst[0] * ASecond[2];
  LValue := LLeft - LRight;
  AResult[1] := LValue;
  LLeft := AFirst[0] * ASecond[1];
  LRight := AFirst[1] * ASecond[0];
  LValue := LLeft - LRight;
  AResult[2] := LValue;
end;

class function TPmoveVector.Dot(const AFirst, ASecond: TQ3Vec3): Single;
begin
  Result := TQ3Math.Dot(AFirst, ASecond);
end;

class function TPmoveVector.SquareRoot(const AValue: Single): Single;
var
  LRoot: Double;
begin
  LRoot := Sqrt(Double(AValue));
  Result := LRoot;
end;

class function TPmoveVector.Length(const AVector: TQ3Vec3): Single;
var
  LSum: Single;
begin
  LSum := TQ3Math.Dot(AVector, AVector);
  Result := SquareRoot(LSum);
end;

class function TPmoveVector.Normalize(var AVector: TQ3Vec3): Single;
var
  LLength, LInverse, LValue: Single;
begin
  LLength := Length(AVector);
  if LLength <> 0 then
  begin
    LInverse := 1 / LLength;
    LValue := AVector[0] * LInverse;
    AVector[0] := LValue;
    LValue := AVector[1] * LInverse;
    AVector[1] := LValue;
    LValue := AVector[2] * LInverse;
    AVector[2] := LValue;
  end;
  Result := LLength;
end;

class function TPmoveVector.Normalize2(const AVector: TQ3Vec3; out AResult: TQ3Vec3): Single;
var
  LLength, LInverse, LValue: Single;
begin
  LLength := Length(AVector);
  if LLength <> 0 then
  begin
    LInverse := 1 / LLength;
    LValue := AVector[0] * LInverse;
    AResult[0] := LValue;
    LValue := AVector[1] * LInverse;
    AResult[1] := LValue;
    LValue := AVector[2] * LInverse;
    AResult[2] := LValue;
  end
  else
    Clear(AResult);
  Result := LLength;
end;

class procedure TPmoveVector.ClipVelocity(const AIn, ANormal: TQ3Vec3; out AOut: TQ3Vec3;
  const AOverBounce: Single);
var
  LBackoff, LChange, LValue: Single;
begin
  LBackoff := TQ3Math.Dot(AIn, ANormal);
  if LBackoff < 0 then
    LBackoff := LBackoff * AOverBounce
  else
    LBackoff := LBackoff / AOverBounce;
  LChange := ANormal[0] * LBackoff;
  LValue := AIn[0] - LChange;
  AOut[0] := LValue;
  LChange := ANormal[1] * LBackoff;
  LValue := AIn[1] - LChange;
  AOut[1] := LValue;
  LChange := ANormal[2] * LBackoff;
  LValue := AIn[2] - LChange;
  AOut[2] := LValue;
end;

end.
