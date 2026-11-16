{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixBounceRules                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the bounces of P_XYMovement, P_ZMovement and                        }
{  P_ResolveBounceBehaviour (p_mobj.pas of Rad-X)                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Physics.Bounce;

// Fixed point arithmetic (16.16): the products are made in 64 bit, nothing wraps
{$Q-}
{$R-}

interface

{$SCOPEDENUMS ON}

type
  /// <summary>What a thing that reaches the floor or the ceiling does</summary>
  TRadixPlaneHit = (
    /// <summary>It stops there (a missile explodes)</summary>
    Clip,
    /// <summary>It bounces back</summary>
    Bounce,
    /// <summary>A missile that bounces on floors and has reached a sky floor explodes</summary>
    Explode);

  /// <summary>What a bouncing missile does when a wall stopped it and it did not bounce</summary>
  TRadixMissileSkim = (
    /// <summary>It keeps flying along the wall</summary>
    None,
    /// <summary>It explodes (it bounces neither on floors nor on ceilings)</summary>
    Explode,
    /// <summary>It lies on a sky plane: it is removed without a sound</summary>
    Remove,
    /// <summary>It lies on the floor: it leaves it with its speed</summary>
    Up,
    /// <summary>It lies on the ceiling: it leaves it with its speed</summary>
    Down);

  /// <summary>
  ///   The bounces of the things of Radix: what Rad-X changed in the movement of Doom. A count
  ///   can limit the bounces (A_LimitBounceControl), a factor scales the momentum after a wall
  ///   (A_WallBounceFactor), a missile keeps its vertical speed, a wall that can be shot is
  ///   never a mirror. Momenta and heights are 16.16 fixed point
  /// </summary>
  TRadixBounceRules = class
  public
    /// <summary>
    ///   A bounce is taken away from a thing with a limited count (MF3_EX_LIMITBOUNCECONTROL).
    ///   True when the thing must lose its three bounce flags
    /// </summary>
    class function CountDown(ALimited: Boolean; var ACount: Integer): Boolean; static;
    /// <summary>
    ///   True when the line that stopped a thing is a mirror for it. A wall that can still be
    ///   shot never is; a one sided or blocking line always is; a two sided one only when the
    ///   thing is outside its opening
    /// </summary>
    /// <param name="ASolid">The line blocks everything or has one side only</param>
    /// <param name="AOpeningBottom">The higher floor of the two sides</param>
    /// <param name="AOpeningTop">The lower ceiling of the two sides</param>
    class function BouncesOnLine(ASolid, AShootable: Boolean; AZ, AOpeningBottom, AOpeningTop: Integer): Boolean; static;
    /// <summary>
    ///   True when the momentum must be mirrored on the line: the thing crosses it in this step,
    ///   or stays on its side and comes nearer (square distances)
    /// </summary>
    class function Reflects(ASideNow, ASideNext: Boolean; ADistanceNow, ADistanceNext: Integer): Boolean; static;
    /// <summary>
    ///   The momentum on one axis after a bounce on something that is not a line: scaled by the
    ///   factor of the thing when it has one, halved otherwise
    /// </summary>
    class function SlowDown(AMomentum: Integer; AHasFactor: Boolean; AFactor: Integer): Integer; static;
    /// <summary>
    ///   The bounce on something that is not a line: the momentum is turned on the axis that is
    ///   blocked (y when the move mirrored on x is free, x otherwise)
    /// </summary>
    class procedure Mirror(var AMomentumX, AMomentumY: Integer; AMirroredMoveIsFree: Boolean); static;
    /// <summary>What a thing does on the floor</summary>
    class function FloorHit(AFloorBounce, AMissile, AFloorIsSky: Boolean): TRadixPlaneHit; static;
    /// <summary>What a thing that rises does on the ceiling</summary>
    class function CeilingHit(ACeilingBounce, ACeilingIsSky: Boolean): TRadixPlaneHit; static;
    /// <summary>The vertical momentum after a bounce: a missile keeps its speed, the rest loses half</summary>
    class function PlaneMomentum(AMomentumZ: Integer; AMissile: Boolean): Integer; static;
    /// <summary>True when the floor ends the bounces of a thing: a liquid (terrain type above the sky)</summary>
    class function FloorEndsBounces(ALiquidFloor: Boolean): Boolean; static;
    /// <summary>What a bouncing missile does when a wall stopped it and it did not bounce on it</summary>
    class function MissileSkim(AFloorBounce, ACeilingBounce, AOnFloor, AOnCeiling, AFloorIsSky,
      ACeilingIsSky: Boolean): TRadixMissileSkim; static;
    /// <summary>The 16.16 product, rounded down as FixedMul of the engine</summary>
    class function FixedMul(AFirst, ASecond: Integer): Integer; static;
  end;

implementation

{ TRadixBounceRules }

class function TRadixBounceRules.FixedMul(AFirst, ASecond: Integer): Integer;
var
  LProduct: Int64;
begin
  LProduct := Int64(AFirst) * ASecond;
  // shr does not keep the sign
  if LProduct >= 0 then
    Result := Integer(LProduct shr 16)
  else
    Result := Integer(-((-LProduct - 1) shr 16) - 1);
end;

class function TRadixBounceRules.CountDown(ALimited: Boolean; var ACount: Integer): Boolean;
begin
  Result := False;
  if not ALimited then
    Exit;
  if ACount > 0 then
    Dec(ACount);
  Result := ACount = 0;
end;

class function TRadixBounceRules.BouncesOnLine(ASolid, AShootable: Boolean; AZ, AOpeningBottom,
  AOpeningTop: Integer): Boolean;
begin
  if AShootable then
    Result := False
  else if ASolid then
    Result := True
  else
    Result := (AZ < AOpeningBottom) or (AZ > AOpeningTop);
end;

class function TRadixBounceRules.Reflects(ASideNow, ASideNext: Boolean; ADistanceNow, ADistanceNext: Integer): Boolean;
begin
  Result := (ASideNow <> ASideNext) or (ADistanceNext < ADistanceNow);
end;

class function TRadixBounceRules.SlowDown(AMomentum: Integer; AHasFactor: Boolean; AFactor: Integer): Integer;
begin
  if AHasFactor then
    Result := FixedMul(AMomentum, AFactor)
  else
    Result := AMomentum div 2;
end;

class procedure TRadixBounceRules.Mirror(var AMomentumX, AMomentumY: Integer; AMirroredMoveIsFree: Boolean);
begin
  if AMirroredMoveIsFree then
    AMomentumY := -AMomentumY
  else
    AMomentumX := -AMomentumX;
end;

class function TRadixBounceRules.FloorHit(AFloorBounce, AMissile, AFloorIsSky: Boolean): TRadixPlaneHit;
begin
  if not AFloorBounce then
    Result := TRadixPlaneHit.Clip
  else if not AFloorIsSky then
    Result := TRadixPlaneHit.Bounce
  else if AMissile then
    Result := TRadixPlaneHit.Explode
  else
    Result := TRadixPlaneHit.Clip;
end;

class function TRadixBounceRules.CeilingHit(ACeilingBounce, ACeilingIsSky: Boolean): TRadixPlaneHit;
begin
  if ACeilingBounce and not ACeilingIsSky then
    Result := TRadixPlaneHit.Bounce
  else
    Result := TRadixPlaneHit.Clip;
end;

class function TRadixBounceRules.PlaneMomentum(AMomentumZ: Integer; AMissile: Boolean): Integer;
begin
  if AMissile then
    Result := -AMomentumZ
  else
    Result := -AMomentumZ div 2;
end;

class function TRadixBounceRules.FloorEndsBounces(ALiquidFloor: Boolean): Boolean;
begin
  Result := ALiquidFloor;
end;

class function TRadixBounceRules.MissileSkim(AFloorBounce, ACeilingBounce, AOnFloor, AOnCeiling, AFloorIsSky,
  ACeilingIsSky: Boolean): TRadixMissileSkim;
begin
  if not (AFloorBounce or ACeilingBounce) then
    Result := TRadixMissileSkim.Explode
  else if AFloorBounce and AOnFloor then
  begin
    if AFloorIsSky then
      Result := TRadixMissileSkim.Remove
    else
      Result := TRadixMissileSkim.Up;
  end
  else if ACeilingBounce and AOnCeiling then
  begin
    if ACeilingIsSky then
      Result := TRadixMissileSkim.Remove
    else
      Result := TRadixMissileSkim.Down;
  end
  else
    Result := TRadixMissileSkim.None;
end;

end.
