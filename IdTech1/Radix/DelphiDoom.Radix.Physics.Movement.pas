{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixMovementRules                             }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of P_VelocityHandler and of the top speed of P_XYMovement              }
{  (p_mobj.pas), of the steps of P_TryMove and of P_SectorJumpOverhead         }
{  (p_map.pas) of Rad-X                                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Physics.Movement;

// Fixed point arithmetic (16.16): the products are made in 64 bit, nothing wraps
{$Q-}
{$R-}

interface

{$SCOPEDENUMS ON}

type
  /// <summary>What a thing that explodes when it stands still does in a tic</summary>
  TRadixIdleAction = (
    /// <summary>Nothing</summary>
    None,
    /// <summary>It explodes: it is as slow as its limit, or slower</summary>
    Explode,
    /// <summary>It is slow (under a quarter of its speed): its momentum grows by a quarter</summary>
    Accelerate);

  /// <summary>
  ///   The movement of the things of Radix: things without a top speed (MF3_EX_NOMAXMOVE), the
  ///   steps of a fast move, the missiles that explode when they stand still (A_IdleExplode),
  ///   the things that fly through a sky (MF3_EX_THRUSKY). Lengths are 16.16 fixed point
  /// </summary>
  TRadixMovementRules = class
  public const
    /// <summary>The top speed of a thing on one axis (MAXMOVE of the engine: 30 map units a tic)</summary>
    MAX_MOVE = 30 * 65536;
    /// <summary>How far above a sky ceiling, or below a sky floor, a thing can fly (64 map units)</summary>
    THRU_SKY_OFFSET = 64 * 65536;
    /// <summary>The fewest steps of the move of a missile or of a thing without a top speed</summary>
    MIN_STEPS = 8;
  public
    /// <summary>The momentum on one axis that a thing moves with: clipped to MAX_MOVE unless it has no top speed</summary>
    class function ClampMomentum(AMomentum: Integer; ANoMaxMove: Boolean): Integer; static;
    /// <summary>
    ///   True when the move of a thing is checked step by step along its way: a missile, or a
    ///   thing without a top speed (the others are checked at the end of the move only)
    /// </summary>
    class function MovesInSteps(AMissile, ANoMaxMove: Boolean): Boolean; static;
    /// <summary>
    ///   How many steps the way is cut in: 8 for a thing without a radius, 1 for a thing that
    ///   does not move, otherwise the larger of 8 and distance / radius + 4
    /// </summary>
    class function StepCount(ADistance, ARadius: Integer): Integer; static;
    /// <summary>
    ///   One coordinate of the step AStep (1..ASteps) between AFrom and ATo:
    ///   (AFrom div ASteps) * (ASteps - AStep) + (ATo div ASteps) * AStep
    /// </summary>
    class function StepPosition(AFrom, ATo, ASteps, AStep: Integer): Integer; static;
    /// <summary>The speed of a thing from its last move on the two axes (P_AproxDistance of the engine)</summary>
    class function ApproximateDistance(ADeltaX, ADeltaY: Integer): Integer; static;
    /// <summary>What a thing that explodes when it stands still does: AVelocity is its real speed of the last tic</summary>
    /// <param name="AIdleSpeed">The limit of A_IdleExplode</param>
    /// <param name="ASpeed">The speed of the definition of the thing</param>
    class function IdleAction(AVelocity, AIdleSpeed, ASpeed: Integer): TRadixIdleAction; static;
    /// <summary>The momentum on one axis of a slow thing that accelerates: 5/4</summary>
    class function Accelerate(AMomentum: Integer): Integer; static;
    /// <summary>
    ///   How far past a sky plane a thing can go: THRU_SKY_OFFSET for a missile or a thing that
    ///   flies through the sky, unless it is forbidden to (MF3_EX_PREVENTTHRYSKY); 0 otherwise
    /// </summary>
    class function SkyOverhead(APlaneIsSky, AMissile, AThruSky, APreventThruSky: Boolean): Integer; static;
    /// <summary>
    ///   P_SectorJumpOverhead (ACeiling) or P_SectorJumpUnderhead of Rad-X without the offset of the
    ///   players under a sloped plane: how far past the ceiling (or below the floor) of a sector a thing can
    ///   go. A sector with a middle sector (3D floors) gives nothing to a thing that is not on the side
    ///   of the middle sector that the plane belongs to
    /// </summary>
    /// <param name="AHasMiddleSector">The sector has a 3D floor</param>
    /// <param name="AMiddleLimit">The floor of the middle sector for a ceiling, its ceiling for a floor</param>
    class function SectorSkyOffset(ACeiling, AHasMiddleSector: Boolean; AThingZ, AMiddleLimit: Integer;
      APlaneIsSky, AMissile, AThruSky, APreventThruSky: Boolean): Integer; static;
  end;

implementation

{ TRadixMovementRules }

class function TRadixMovementRules.ClampMomentum(AMomentum: Integer; ANoMaxMove: Boolean): Integer;
begin
  Result := AMomentum;
  if ANoMaxMove then
    Exit;
  if Result > MAX_MOVE then
    Result := MAX_MOVE
  else if Result < -MAX_MOVE then
    Result := -MAX_MOVE;
end;

class function TRadixMovementRules.MovesInSteps(AMissile, ANoMaxMove: Boolean): Boolean;
begin
  Result := AMissile or ANoMaxMove;
end;

class function TRadixMovementRules.StepCount(ADistance, ARadius: Integer): Integer;
var
  LQuotient: Int64;
begin
  if ARadius = 0 then
    Result := MIN_STEPS
  else if ADistance = 0 then
    Result := 1
  else
  begin
    // FixedDiv(distance, radius) div FRACUNIT is the whole quotient; FixedDiv of the engine
    // gives MAXINT when the quotient does not fit (distance shr 14 >= radius)
    if (Abs(Int64(ADistance)) shr 14) >= Abs(Int64(ARadius)) then
      LQuotient := 32767 + 4
    else
      LQuotient := Int64(ADistance) div ARadius + 4;
    if LQuotient < MIN_STEPS then
      Result := MIN_STEPS
    else
      Result := Integer(LQuotient);
  end;
end;

class function TRadixMovementRules.StepPosition(AFrom, ATo, ASteps, AStep: Integer): Integer;
begin
  Result := (AFrom div ASteps) * (ASteps - AStep) + (ATo div ASteps) * AStep;
end;

class function TRadixMovementRules.ApproximateDistance(ADeltaX, ADeltaY: Integer): Integer;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  LDeltaX := Abs(ADeltaX);
  LDeltaY := Abs(ADeltaY);
  if LDeltaX < LDeltaY then
    Result := LDeltaX + LDeltaY - LDeltaX div 2
  else
    Result := LDeltaX + LDeltaY - LDeltaY div 2;
end;

class function TRadixMovementRules.IdleAction(AVelocity, AIdleSpeed, ASpeed: Integer): TRadixIdleAction;
begin
  if AVelocity <= AIdleSpeed then
    Result := TRadixIdleAction.Explode
  else if AVelocity < ASpeed div 4 then
    Result := TRadixIdleAction.Accelerate
  else
    Result := TRadixIdleAction.None;
end;

class function TRadixMovementRules.Accelerate(AMomentum: Integer): Integer;
begin
  Result := Integer(Int64(AMomentum) * 5 div 4);
end;

class function TRadixMovementRules.SkyOverhead(APlaneIsSky, AMissile, AThruSky, APreventThruSky: Boolean): Integer;
begin
  if APlaneIsSky and (AMissile or AThruSky) and not APreventThruSky then
    Result := THRU_SKY_OFFSET
  else
    Result := 0;
end;

class function TRadixMovementRules.SectorSkyOffset(ACeiling, AHasMiddleSector: Boolean; AThingZ, AMiddleLimit: Integer;
  APlaneIsSky, AMissile, AThruSky, APreventThruSky: Boolean): Integer;
begin
  if AHasMiddleSector then
  begin
    if ACeiling and (AThingZ < AMiddleLimit) then
      Exit(0);
    if not ACeiling and (AThingZ >= AMiddleLimit) then
      Exit(0);
  end;
  Result := SkyOverhead(APlaneIsSky, AMissile, AThruSky, APreventThruSky);
end;

end.
