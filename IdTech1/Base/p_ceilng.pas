//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Ceiling aninmation (lowering, crushing, raising)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_ceilng;

interface

uses
  z_zone,
  p_spec_h,
  p_spec,
  r_defs,
  s_sound,
  sounddata;


//==============================================================================
//
// T_MoveCeiling
//
//==============================================================================
procedure T_MoveCeiling(ceiling: Pceiling_t);

//==============================================================================
//
// EV_DoCeiling
//
//==============================================================================
function EV_DoCeiling(line: Pline_t; _type: ceiling_e): integer;

//==============================================================================
//
// P_AddActiveCeiling
//
//==============================================================================
procedure P_AddActiveCeiling(c: Pceiling_t);

//==============================================================================
//
// EV_CeilingCrushStop
//
//==============================================================================
function EV_CeilingCrushStop(line: Pline_t): integer;

//==============================================================================
//
// P_ActivateInStasisCeiling
//
//==============================================================================
function P_ActivateInStasisCeiling(line: Pline_t): integer;

implementation

uses
  i_system,
  p_tick,
  p_setup,
  p_slopes,
  p_floor,
  DelphiDoom.Thinkers.Plane.Types,
  DelphiDoom.Thinkers.Ceiling.Types,
  DelphiDoom.Thinkers.Ceiling.Machine,
  DelphiDoom.Engine.Plane.Services,
  DelphiDoom.Engine.Ceiling.Thinker;

//==============================================================================
// P_AddActiveCeiling
//
// Add an active ceiling
//
//==============================================================================
procedure P_AddActiveCeiling(c: Pceiling_t);
var
  i: integer;
begin
  for i := 0 to TTickRoutines.P_World.ActiveCeilings.Capacity - 1 do
    if Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]) = nil then
    begin
      TTickRoutines.P_World.ActiveCeilings.Add(c);
      exit;
    end;
  I_Warning('P_AddActiveCeiling(): Can not add ceiling, limit %d reached'#13#10, [MAXCEILINGS]);
end;

//==============================================================================
// P_RemoveActiveCeiling
//
// Remove a ceiling's thinker
//
//==============================================================================
procedure P_RemoveActiveCeiling(c: Pceiling_t);
var
  i: integer;
begin
  for i := 0 to TTickRoutines.P_World.ActiveCeilings.Capacity - 1 do
    if Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]) = c then
    begin
      CeilingAttach(Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).sector, nil);
      TTickRoutines.P_RemoveThinker(@Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).thinker);
      TTickRoutines.P_World.ActiveCeilings.Release(i);
      exit;
    end;
end;

//==============================================================================
// P_ActivateInStasisCeiling
//
// Restart a ceiling that's in-stasis
//
//==============================================================================
function P_ActivateInStasisCeiling(line: Pline_t): integer;
var
  i: integer;
begin
  result := 0;
  for i := 0 to TTickRoutines.P_World.ActiveCeilings.Capacity - 1 do
    if (Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]) <> nil) and
       (Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).tag = line.tag) and
       (Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).direction = 0) then
    begin
      Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).direction := Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).olddirection;
      Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).thinker._function.acp1 := @T_MoveCeiling;
      result := 1;
    end;
end;

//==============================================================================
//
// T_MoveCeiling
//
// The tic of a ceiling of Doom, Heretic and Strife: the step is T_MovePlane,
// what follows it is TCeilingMachine (IdTech1\Thinkers); the thinker stays the
// record that the savegames know
//
//==============================================================================
procedure T_MoveCeiling(ceiling: Pceiling_t);
var
  res: result_e;
  moved: TPlaneMoveResult;
  state: TCeilingState;
  actions: TCeilingActions;
begin
  case ceiling.direction of
    1:
    // UP
      res := TFloorRoutines.T_MovePlane(ceiling.sector,
        ceiling.speed,
        ceiling.topheight,
        false, 1, ceiling.direction);
   -1:
    // DOWN
      res := TFloorRoutines.T_MovePlane(ceiling.sector,
        ceiling.speed,
        ceiling.bottomheight,
        ceiling.crush, 1, ceiling.direction);
  else
    // IN STASIS
    exit;
  end;

  if res = pastdest then
    moved := TPlaneMoveResult.PastDest
  else if res = crushed then
    moved := TPlaneMoveResult.Crushed
  else
    moved := TPlaneMoveResult.Ok;

  CeilingLoadState(ceiling, state);
  actions := TCeilingMachine.AfterMove(CeilingKindOf(ceiling._type), state, moved,
    TTickState.LevelTime and 7 = 0);
  CeilingStoreState(ceiling, state);

  if actions <> [] then
  begin
    CeilingApply(ceiling, actions);
    if TCeilingAction.Remove in actions then
      P_RemoveActiveCeiling(ceiling);
  end;
end;

//==============================================================================
//
// EV_DoCeiling
// Move a ceiling up/down and all around!
//
//==============================================================================
function EV_DoCeiling(line: Pline_t; _type: ceiling_e): integer;
var
  initial: boolean;
  secnum: integer;
  sec: Psector_t;
  ceiling: Pceiling_t;
  kind: TCeilingKind;
  profile: TCeilingProfile;
  spawn: TCeilingSpawn;
begin
  secnum := -1;
  kind := CeilingKindOf(_type);
  profile := CeilingProfile;

  // Reactivate in-stasis ceilings...for certain types.
  result := 0;
  if TCeilingMachine.WakesUpStopped(kind) then
  begin
    result := P_ActivateInStasisCeiling(line);
    if not profile.WakeUpCounts then
      result := 0;
  end;

  initial := true;
  while (secnum >= 0) or initial do
  begin
    initial := false;
    secnum := P_FindSectorFromLineTag(line, secnum);
    if secnum < 0 then
      break;

    sec := @sectors[secnum];
    if CeilingSectorBusy(sec) then
      continue;

    // new door thinker
    result := 1;
    ceiling := Z_Malloc(SizeOf(ceiling_t), PU_LEVSPEC, nil);
    TTickRoutines.P_AddThinker(@ceiling.thinker);
    CeilingAttach(sec, ceiling);
    ceiling.thinker._function.acp1 := @T_MoveCeiling;
    ceiling.sector := sec;
    ceiling.crush := false;

    // the values of the kind with the rules of the game (TCeilingMachine); a
    // field that the kind does not set stays as the memory of the thinker had it
    spawn.Crush := ceiling.crush;
    spawn.TopHeight := ceiling.topheight;
    spawn.BottomHeight := ceiling.bottomheight;
    spawn.Direction := ceiling.direction;
    spawn.Speed := ceiling.speed;
    case TCeilingMachine.Configure(kind, sec.floorheight, sec.ceilingheight, profile, spawn) of
      TCeilingNeighbor.TopHighestCeiling:
        spawn.TopHeight := P_FindHighestCeilingSurrounding(sec);
      TCeilingNeighbor.BottomLowestCeiling:
        spawn.BottomHeight := P_FindLowestCeilingSurrounding(sec);
      TCeilingNeighbor.BottomHighestFloor:
        spawn.BottomHeight := P_FindHighestFloorSurrounding(sec);
    end;
    ceiling.crush := spawn.Crush;
    ceiling.topheight := spawn.TopHeight;
    ceiling.bottomheight := spawn.BottomHeight;
    ceiling.direction := spawn.Direction;
    ceiling.speed := spawn.Speed;

    ceiling.tag := sec.tag;
    ceiling._type := _type;
    P_AddActiveCeiling(ceiling);
    TSlopeRoutines.P_DynamicSlope(sec);  // JVAL: Slopes
  end;
end;

//==============================================================================
//
// EV_CeilingCrushStop
// Stop a ceiling from crushing!
//
//==============================================================================
function EV_CeilingCrushStop(line: Pline_t): integer;
var
  i: integer;
begin
  result := 0;
  for i := 0 to TTickRoutines.P_World.ActiveCeilings.Capacity - 1 do
    if (Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]) <> nil) and
       (Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).tag = line.tag) and
       (Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).direction <> 0) then
    begin
      Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).olddirection := Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).direction;
      Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).thinker._function.acv := nil;
      Pceiling_t(TTickRoutines.P_World.ActiveCeilings[i]).direction := 0; // in-stasis
      result := 1;
    end;
end;

end.
