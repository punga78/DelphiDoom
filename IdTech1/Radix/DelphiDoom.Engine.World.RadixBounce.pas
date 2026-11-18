{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - the bounces of the things in the engine            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the bounces of P_XYMovement and P_ZMovement (p_mobj.pas of Rad-X)   }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.RadixBounce;

interface

uses
  m_fixed,
  p_mobj_h;

type
  /// <summary>
  ///   The bounces of the things of Rad-X where the movement of the engine (TMobjGameRules.ZHitFloor,
  ///   ZHitCeiling, BlockedMove) asks the extension of the game: the decisions are the ones of
  ///   TRadixBounceRules, here the mobj is read and written. The fields that Rad-X added to the
  ///   mobj_t are custom parameters (A_LimitBounceControl: the count of bounces, and its presence is
  ///   MF3_EX_LIMITBOUNCECONTROL; A_WallBounceFactor: the factor, and its presence is
  ///   MF3_EX_WALLBOUNCEFACTOR)
  /// </summary>
  /// <remarks>Class of static methods: the path of every thing at every tic, no virtual call</remarks>
  TRadixBounceEngine = class sealed
  public
    /// <summary>
    ///   P_ZMovement, the thing is at or under the floor: the bounce on the floor. False when the
    ///   missile has exploded (a sky floor) and the movement is over. ABouncing tells that the thing
    ///   bounced
    /// </summary>
    class function FloorBounce(mo: Pmobj_t; var ABouncing: Boolean): Boolean; static;
    /// <summary>
    ///   P_ZMovement, the thing is above the ceiling: the bounce on the ceiling, or the end of a
    ///   missile. False when the missile has exploded
    /// </summary>
    class function CeilingBounce(mo: Pmobj_t; var ABouncing: Boolean): Boolean; static;
    /// <summary>
    ///   P_XYMovement, a thing with WALLBOUNCE (not a player) was blocked: it bounces on the line
    ///   (unless it is a wall that can be shot, or the thing is within the opening of a line with
    ///   two sides) or, with no line, scales its momentum and turns it. A missile that did not
    ///   bounce flies along the floor or the ceiling, is removed against a sky, or explodes.
    ///   Always true (all is done, also the explosion of the missile, as against a wall in
    ///   TMobjGameRules.BlockedMove); ARemoved is true when the missile has been removed and the
    ///   movement is over
    /// </summary>
    class function WallBounce(mo: Pmobj_t; var xmove, ymove: fixed_t; var ARemoved: Boolean): Boolean; static;
  end;

implementation

uses
  d_delphi,
  doomdata,
  info_h,
  p_bouncing,
  p_local,
  p_map,
  p_mobj,
  p_params,
  p_setup,
  r_defs,
  r_main,
  r_sky,
  radix_codepointers,
  radix_walls,
  DelphiDoom.Radix.Physics.Bounce;

procedure LoadState(mo: Pmobj_t; var AState: TRadixBounceState);
var
  LParameter: Pmobjcustomparam_t;
begin
  AState.Missile := mo.flags and MF_MISSILE <> 0;
  AState.FloorBounce := mo.flags3_ex and MF3_EX_FLOORBOUNCE <> 0;
  AState.CeilingBounce := mo.flags3_ex and MF3_EX_CEILINGBOUNCE <> 0;
  AState.WallBounce := mo.flags3_ex and MF3_EX_WALLBOUNCE <> 0;
  LParameter := P_GetMobjCustomParam(mo, S_PARAM_BOUNCECNT);
  AState.Limited := LParameter <> nil;
  if AState.Limited then
    AState.Count := LParameter.value
  else
    AState.Count := 0;
  AState.MomentumZ := mo.momz;
  AState.ReactionTime := mo.reactiontime;
end;

procedure StoreState(mo: Pmobj_t; const AState: TRadixBounceState);
begin
  mo.flags3_ex := mo.flags3_ex and not MF3_EX_BOUNCE;
  if AState.FloorBounce then
    mo.flags3_ex := mo.flags3_ex or MF3_EX_FLOORBOUNCE;
  if AState.CeilingBounce then
    mo.flags3_ex := mo.flags3_ex or MF3_EX_CEILINGBOUNCE;
  if AState.WallBounce then
    mo.flags3_ex := mo.flags3_ex or MF3_EX_WALLBOUNCE;
  if AState.Limited then
    P_SetMobjCustomParam(mo, S_PARAM_BOUNCECNT, AState.Count);
  mo.momz := AState.MomentumZ;
  mo.reactiontime := AState.ReactionTime;
end;

class function TRadixBounceEngine.FloorBounce(mo: Pmobj_t; var ABouncing: Boolean): Boolean;
var
  LState: TRadixBounceState;
begin
  // the thing at rest on the floor asks every tic: only a thing that bounces on floors has anything to do
  if mo.flags3_ex and MF3_EX_FLOORBOUNCE = 0 then
  begin
    Result := True;
    Exit;
  end;
  LoadState(mo, LState);
  LState.Bouncing := ABouncing;
  Result := TRadixBounceRules.FloorImpact(LState,
    Psubsector_t(mo.subsector).sector.floorpic = skyflatnum, P_GetThingFloorType(mo) <> FLOOR_SOLID);
  ABouncing := LState.Bouncing;
  StoreState(mo, LState);
  if not Result then
    P_ExplodeMissile(mo);
end;

class function TRadixBounceEngine.CeilingBounce(mo: Pmobj_t; var ABouncing: Boolean): Boolean;
var
  LState: TRadixBounceState;
begin
  if mo.momz <= 0 then
  begin
    Result := True;
    Exit;
  end;
  // no bounce on ceilings: a missile explodes, the rest stops (no need to look for the count)
  if mo.flags3_ex and MF3_EX_CEILINGBOUNCE = 0 then
  begin
    Result := mo.flags and MF_MISSILE = 0;
    if Result then
    begin
      mo.momz := 0;
      ABouncing := True;
    end
    else
      P_ExplodeMissile(mo);
    Exit;
  end;
  LoadState(mo, LState);
  LState.Bouncing := ABouncing;
  Result := TRadixBounceRules.CeilingImpact(LState, Psubsector_t(mo.subsector).sector.ceilingpic = skyflatnum);
  ABouncing := LState.Bouncing;
  if Result then
    StoreState(mo, LState)
  else
    P_ExplodeMissile(mo);
end;

class function TRadixBounceEngine.WallBounce(mo: Pmobj_t; var xmove, ymove: fixed_t; var ARemoved: Boolean): Boolean;
var
  LState: TRadixBounceState;
  LLine: Pline_t;
  LFront, LBack: Psector_t;
  LSolid, LBounced: Boolean;
  LOpeningBottom, LOpeningTop: fixed_t;
  LParameter: Pmobjcustomparam_t;
  LSector: Psector_t;
begin
  ARemoved := False;
  Result := True;
  LLine := TMapCheck.BounceLine;
  if LLine <> nil then
  begin
    LSolid := (LLine.flags and ML_BLOCKING <> 0) or (LLine.sidenum[1] = -1) or (LLine.sidenum[0] = -1);
    LOpeningBottom := 0;
    LOpeningTop := 0;
    if not LSolid then
    begin
      LFront := sides[LLine.sidenum[0]].sector;
      LBack := sides[LLine.sidenum[1]].sector;
      LOpeningTop := LFront.ceilingheight;
      if LBack.ceilingheight < LOpeningTop then
        LOpeningTop := LBack.ceilingheight;
      LOpeningBottom := LFront.floorheight;
      if LBack.floorheight > LOpeningBottom then
        LOpeningBottom := LBack.floorheight;
    end;
    LBounced := TRadixBounceRules.BouncesOnLine(LSolid, RX_ShootableLine(pDiff(LLine, @lines[0], SizeOf(line_t))),
      mo.z, LOpeningBottom, LOpeningTop);
    if LBounced then
      P_WallBounceMobj(mo, LLine);
  end
  else
  begin
    // not a line: scale the momentum, then turn it on the axis that is blocked
    LBounced := True;
    LParameter := P_GetMobjCustomParam(mo, S_PARAM_WALLBOUNCEFACTOR);
    if LParameter <> nil then
    begin
      mo.momx := TRadixBounceRules.SlowDown(mo.momx, True, LParameter.value);
      mo.momy := TRadixBounceRules.SlowDown(mo.momy, True, LParameter.value);
    end
    else
    begin
      mo.momx := TRadixBounceRules.SlowDown(mo.momx, False, 0);
      mo.momy := TRadixBounceRules.SlowDown(mo.momy, False, 0);
    end;
    TRadixBounceRules.Mirror(mo.momx, mo.momy, P_TryMove(mo, mo.x - xmove, ymove + mo.y));
    mo.angle := TRendererMain.R_PointToAngle2(0, 0, -mo.momx, -mo.momy);
  end;

  // read after the movement: P_WallBounceMobj and P_TryMove ran
  LoadState(mo, LState);
  if LBounced then
  begin
    TRadixBounceRules.Resolve(LState);
    StoreState(mo, LState);
    xmove := 0;
    ymove := 0;
  end
  else if LState.Missile then
  begin
    LSector := Psubsector_t(mo.subsector).sector;
    case TRadixBounceRules.MissileSkim(LState.FloorBounce, LState.CeilingBounce, mo.z <= mo.floorz,
      mo.z >= mo.ceilingz, LSector.floorpic = skyflatnum, LSector.ceilingpic = skyflatnum) of
      TRadixMissileSkim.Explode:
        // as the missile of the engine against a wall (TMobjGameRules.BlockedMove): not against a sky
        if (TMapCheck.CeilingLine <> nil) and (TMapCheck.CeilingLine.backsector <> nil) and
           (TMapCheck.CeilingLine.backsector.ceilingpic = skyflatnum) and
           (mo.z > TMapCheck.CeilingLine.backsector.ceilingheight) then
        begin
          P_RemoveMobj(mo);
          ARemoved := True;
        end
        else
          P_ExplodeMissile(mo);
      TRadixMissileSkim.Remove:
        begin
          P_RemoveMobj(mo);
          ARemoved := True;
        end;
      TRadixMissileSkim.Up:
        mo.momz := mo.info.speed;
      TRadixMissileSkim.Down:
        mo.momz := -mo.info.speed;
    end;
  end;
end;

end.
