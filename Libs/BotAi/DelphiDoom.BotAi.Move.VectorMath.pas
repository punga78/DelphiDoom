{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotVectorMath, the vector functions of the movement   }
{                                                                              }
{  The macros and the functions of code\game\q_shared.h and q_math.c that      }
{  be_ai_move.c and be_ai_goal.c call, with the arithmetic of the original     }
{  (every float operation rounded on its own, as SSE does): VectorMA in its    }
{  two forms, VectorNormalize2 and vectoangles. Based on the Quake III Arena   }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.VectorMath;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types;

type
  TBotVectorMath = class
  public
    /// <summary>VectorMA(v, s, b, o) with a float scale: o[i] = v[i] + b[i] * s, the product rounded to a float</summary>
    class procedure MultiplyAdd(const AVector: TVec3; const AScale: Single; const ADirection: TVec3;
      var AOut: TVec3); static;
    /// <summary>
    ///   VectorMA with a double scale (the scale is an expression that has a double literal in it): the product and
    ///   the sum are doubles
    /// </summary>
    class procedure MultiplyAddDouble(const AVector: TVec3; const AScale: Double; const ADirection: TVec3;
      var AOut: TVec3); static;
    /// <summary>VectorNormalize2: the length; the output is the null vector if the length is zero</summary>
    class function Normalize2(const AVector: TVec3; var AOut: TVec3): Single; static;
    /// <summary>VectorLengthSquared</summary>
    class function LengthSquared(const AVector: TVec3): Single; static;
    /// <summary>vectoangles (Vector2Angles)</summary>
    class procedure ToAngles(const AValue: TVec3; var AAngles: TVec3); static;
  end;

implementation

uses
  System.Math;

const
  /// <summary>M_PI: a double literal in the original</summary>
  M_PI: Double = 3.14159265358979323846;

{ TBotVectorMath }

class procedure TBotVectorMath.MultiplyAdd(const AVector: TVec3; const AScale: Single; const ADirection: TVec3;
  var AOut: TVec3);
var
  LProduct: Single;
  LSum: Single;
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
  begin
    LProduct := ADirection[LIndex] * AScale;
    LSum := AVector[LIndex] + LProduct;
    AOut[LIndex] := LSum;
  end;
end;

class procedure TBotVectorMath.MultiplyAddDouble(const AVector: TVec3; const AScale: Double;
  const ADirection: TVec3; var AOut: TVec3);
var
  LProduct: Double;
  LSum: Double;
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
  begin
    LProduct := ADirection[LIndex] * AScale;
    LSum := AVector[LIndex] + LProduct;
    AOut[LIndex] := LSum;
  end;
end;

class function TBotVectorMath.LengthSquared(const AVector: TVec3): Single;
var
  LX, LY, LZ: Single;
begin
  LX := AVector[0] * AVector[0];
  LY := AVector[1] * AVector[1];
  LZ := AVector[2] * AVector[2];
  LX := LX + LY;
  Result := LX + LZ;
end;

class function TBotVectorMath.Normalize2(const AVector: TVec3; var AOut: TVec3): Single;
var
  LSum: Single;
  LInverse: Single;
  LRoot: Double;
begin
  LSum := LengthSquared(AVector);
  LRoot := Sqrt(Double(LSum));
  Result := LRoot;
  if Result <> 0 then
  begin
    LInverse := 1 / Result;
    AOut[0] := AVector[0] * LInverse;
    AOut[1] := AVector[1] * LInverse;
    AOut[2] := AVector[2] * LInverse;
  end
  else
  begin
    AOut[0] := 0;
    AOut[1] := 0;
    AOut[2] := 0;
  end;
end;

class procedure TBotVectorMath.ToAngles(const AValue: TVec3; var AAngles: TVec3);
var
  LForward: Single;
  LYaw: Single;
  LPitch: Single;
  LSquareX: Single;
  LSquareY: Single;
  LDouble: Double;
begin
  if (AValue[1] = 0) and (AValue[0] = 0) then
  begin
    LYaw := 0;
    if AValue[2] > 0 then
      LPitch := 90
    else
      LPitch := 270;
  end
  else
  begin
    if AValue[0] <> 0 then
    begin
      LDouble := ArcTan2(Double(AValue[1]), Double(AValue[0])) * 180 / M_PI;
      LYaw := LDouble;
    end
    else if AValue[1] > 0 then
      LYaw := 90
    else
      LYaw := 270;
    if LYaw < 0 then
      LYaw := LYaw + 360;
    LSquareX := AValue[0] * AValue[0];
    LSquareY := AValue[1] * AValue[1];
    LSquareX := LSquareX + LSquareY;
    LDouble := Sqrt(Double(LSquareX));
    LForward := LDouble;
    LDouble := ArcTan2(Double(AValue[2]), Double(LForward)) * 180 / M_PI;
    LPitch := LDouble;
    if LPitch < 0 then
      LPitch := LPitch + 360;
  end;
  AAngles[0] := -LPitch;
  AAngles[1] := LYaw;
  AAngles[2] := 0;
end;

end.
