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
//  Floor animation: raising stairs.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_floor;

interface

uses
  z_zone,
  DelphiDoom.Engine.World.SectorSearch,
  p_spec_h,
  DelphiDoom.Engine.World.SpecRules,
  p_spec,
  m_fixed,
  r_defs,
  s_sound,
  sounddata;

//==============================================================================
// T_MovePlane
//
// FLOORS
//
//==============================================================================
function T_MovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;

//==============================================================================
//
// T_MoveFloor
//
//==============================================================================
procedure T_MoveFloor(floor: Pfloormove_t);

//==============================================================================
//
// T_MoveElevator
//
//==============================================================================
procedure T_MoveElevator(elevator: Pelevator_t);

//==============================================================================
//
// EV_DoFloor
//
//==============================================================================
function EV_DoFloor(line: Pline_t; floortype: floor_e): integer;

//==============================================================================
//
// EV_BuildStairs
//
//==============================================================================
function EV_BuildStairs(line: Pline_t; _type: stair_e): integer;

//==============================================================================
//
// EV_DoDonut
//
//==============================================================================
function EV_DoDonut(line: Pline_t): integer;

//==============================================================================
//
// EV_DoChange
//
//==============================================================================
function EV_DoChange(line: Pline_t; changetype: change_e): integer;

//==============================================================================
//
// EV_DoElevator
//
//==============================================================================
function EV_DoElevator(line: Pline_t; elevtype: elevator_e): integer;

implementation

uses
  d_delphi,
  doomdata,
  p_map,
  p_tick,
  p_setup,
  p_slopes,
  r_data,
  DelphiDoom.Thinkers.Plane.Types,
  DelphiDoom.Thinkers.Floor.Types,
  DelphiDoom.Thinkers.Floor.Machine,
  DelphiDoom.Engine.Plane.Services,
  DelphiDoom.Engine.Floor.Thinker;

//==============================================================================
// T_MovePlane
//
// Move a plane (floor or ceiling) and check for crushing
//
//==============================================================================
function T_MovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;
begin
  case PlaneMove(sector, speed, dest, crush, floorOrCeiling, direction,
    FloorPlaneRules) of
    TPlaneMoveResult.Crushed:
      result := crushed;
    TPlaneMoveResult.PastDest:
      result := pastdest;
  else
    result := ok;
  end;
end;

//==============================================================================
// T_MoveFloor
//
// MOVE A FLOOR TO IT'S DESTINATION (UP OR DOWN)
//
//==============================================================================
procedure T_MoveFloor(floor: Pfloormove_t);
var
  res: result_e;
  sec: Psector_t;
  actions: TFloorActions;
begin
  res := T_MovePlane(floor.sector, floor.speed, floor.floordestheight,
            floor.crush, 0, floor.direction);

  if TTickState.LevelTime and 7 = 0 then
    TSoundRoutines.S_StartSound(@floor.sector.soundorg, Ord(sfx_stnmov));

  if res = pastdest then
  begin
    floor.sector.floordata := nil;

    // what the kind of the floor changes in its sector (TFloorMachine, IdTech1\Thinkers)
    actions := TFloorMachine.Arrival(FloorKindOf(floor._type), floor.direction);
    if actions <> [] then
    begin
      if TFloorAction.TransferSpecial in actions then
        floor.sector.special := floor.newspecial;
      //jff add to fix bug in special transfers from changes
      if TFloorAction.TransferOldSpecial in actions then
        floor.sector.oldspecial := floor.oldspecial;
      if TFloorAction.ChangeTexture in actions then
        floor.sector.floorpic := floor.texture;
    end;

    floor.sector.floordata := nil;
    TTickRoutines.P_RemoveThinker(@floor.thinker);

    //jff 2/26/98 implement stair retrigger lockout while still building
    // note this only applies to the retriggerable generalized stairs

    if floor.sector.stairlock = -2 then // if this sector is stairlocked
    begin
       sec := floor.sector;
        sec.stairlock := -1;              // thinker done, promote lock to -1

      while (sec.prevsec <> -1) and (sectors[sec.prevsec].stairlock <> -2) do
        sec := @sectors[sec.prevsec]; // search for a non-done thinker
      if sec.prevsec = -1 then           // if all thinkers previous are done
      begin
        sec := floor.sector;          // search forward
        while (sec.nextsec <> -1) and (sectors[sec.nextsec].stairlock <> -2) do
          sec := @sectors[sec.nextsec];
        if sec.nextsec = -1 then         // if all thinkers ahead are done too
        begin
          while sec.prevsec <> -1 do    // clear all locks
          begin
            sec.stairlock := 0;
            sec := @sectors[sec.prevsec];
          end;
          sec.stairlock := 0;
        end;
      end;
    end;

    TSoundRoutines.S_StartSound(@floor.sector.soundorg, Ord(sfx_pstop));
  end;
end;

//==============================================================================
//
// T_MoveElevator
//
// Move an elevator to it's destination (up or down)
// Called once per tick for each moving floor.
//
// Passed an elevator_t structure that contains all pertinent info about the
// move. See P_SPEC.H for fields.
// No return.
//
// jff 02/22/98 added to support parallel floor/ceiling motion
//
//==============================================================================
procedure T_MoveElevator(elevator: Pelevator_t);
var
  res: result_e;
begin
  if elevator.direction < 0 then      // moving down
  begin
    res := T_MovePlane             //jff 4/7/98 reverse order of ceiling/floor
    (
      elevator.sector,
      elevator.speed,
      elevator.ceilingdestheight,
      false,
      1,                          // move floor
      elevator.direction
    );
    if (res = ok) or (res = pastdest) then// jff 4/7/98 don't move ceil if blocked
      T_MovePlane
      (
        elevator.sector,
        elevator.speed,
        elevator.floordestheight,
        false,
        0,                        // move ceiling
        elevator.direction
      );
  end
  else // up
  begin
    res := T_MovePlane             //jff 4/7/98 reverse order of ceiling/floor
    (
      elevator.sector,
      elevator.speed,
      elevator.floordestheight,
      false,
      0,                          // move ceiling
      elevator.direction
    );
    if (res = ok) or (res = pastdest) then // jff 4/7/98 don't move floor if blocked
      T_MovePlane
      (
        elevator.sector,
        elevator.speed,
        elevator.ceilingdestheight,
        false,
        1,                        // move floor
        elevator.direction
      );
  end;

  // make floor move sound
  if TTickState.LevelTime and 7 = 0 then
    TSoundRoutines.S_StartSound(@elevator.sector.soundorg, Ord(sfx_stnmov));

  if res = pastdest then            // if destination height acheived
  begin
    elevator.sector.floordata := nil;     //jff 2/22/98
    elevator.sector.ceilingdata := nil;   //jff 2/22/98
    TTickRoutines.P_RemoveThinker(@elevator.thinker);    // remove elevator from actives

    // make floor stop sound
    TSoundRoutines.S_StartSound(@elevator.sector.soundorg, Ord(sfx_pstop));
  end;
end;

//==============================================================================
// EV_DoFloor
//
// HANDLE FLOOR TYPES
//
//==============================================================================
function EV_DoFloor(line: Pline_t; floortype: floor_e): integer;
var
  secnum: integer;
  i: integer;
  sec: Psector_t;
  floor: Pfloormove_t;
  minsize: integer;
  side: Pside_t;
  kind: TFloorKind;
  profile: TFloorProfile;
  plan: TFloorPlan;
  modern: boolean;
  neighbor: fixed_t;
begin
  secnum := -1;
  result := 0;
  kind := FloorKindOf(floortype);
  profile := FloorProfile;
  repeat
    secnum := P_FindSectorFromLineTag(line, secnum);
    if secnum < 0 then
      exit;

    sec := @sectors[secnum];

    // ALREADY MOVING?  IF SO, KEEP GOING...
    if P_SectorActive(floor_special, sec) then
      continue;

    // new floor thinker
    result := 1;
    floor := Z_Malloc(SizeOf(floormove_t), PU_LEVSPEC, nil);
    TTickRoutines.P_AddThinker(@floor.thinker);
    sec.floordata := floor;
    floor.thinker._function.acp1 := @T_MoveFloor;
    floor._type := floortype;
    floor.crush := false;

    // the values of the kind with the rules of the game (TFloorMachine,
    // IdTech1\Thinkers); a kind that is not made here leaves the thinker as it is
    if TFloorMachine.Plan(kind, plan) then
    begin
      if plan.Crush then
        floor.crush := true;
      floor.direction := plan.Direction;
      floor.sector := sec;
      floor.speed := plan.Speed;

      if plan.Target = TFloorTarget.ShortestTexture then
      begin
        modern := FloorModernEngine;
        minsize := TFloorMachine.TextureStartSize(modern);
        for i := 0 to sec.linecount - 1 do
        begin
          if twoSided(secnum, i) then
          begin
            side := getSide(secnum, i, 0);
            if side.bottomtexture >= 0 then
              if textureheight[side.bottomtexture] < minsize then
                minsize := textureheight[side.bottomtexture];
            side := getSide(secnum, i, 1);
            if side.bottomtexture >= 0 then
              if textureheight[side.bottomtexture] < minsize then
                minsize := textureheight[side.bottomtexture];
          end;
        end;
        floor.floordestheight := TFloorMachine.TextureDestination(sec.floorheight,
          minsize, modern);
      end
      else
      begin
        case plan.Target of
          TFloorTarget.HighestFloor:
            neighbor := P_FindHighestFloorSurrounding(sec);
          TFloorTarget.LowestFloor:
            neighbor := P_FindLowestFloorSurrounding(sec);
          TFloorTarget.NextLowestFloor:
            neighbor := P_FindNextLowestFloor(sec, sec.floorheight);
          TFloorTarget.NextHighestFloor:
            neighbor := P_FindNextHighestFloor(sec, sec.floorheight);
          TFloorTarget.LowestCeiling:
            neighbor := P_FindLowestCeilingSurrounding(sec);
        else
          neighbor := 0;
        end;
        floor.floordestheight := TFloorMachine.Destination(kind, plan, sec.floorheight,
          sec.ceilingheight, neighbor, profile);
      end;

      if plan.ChangeFromLine then
      begin
        sec.floorpic := line.frontsector.floorpic;
        sec.special := line.frontsector.special;
        //jff 3/14/98 transfer both old and new special
        if plan.ChangeOldSpecialToo then
          sec.oldspecial := line.frontsector.oldspecial;
      end;

      if plan.CarriesModel then
      begin
        floor.texture := sec.floorpic;

        // jff 1/24/98 make sure floor.newspecial gets initialized
        // in no surrounding sector is at floordestheight
        // -. should not affect compatibility <--
        floor.newspecial := sec.special;
        //jff 3/14/98 transfer both old and new special
        floor.oldspecial := sec.oldspecial;

        //jff 5/23/98 use model subroutine to unify fixes and handling
        sec := P_FindModelFloorSector(floor.floordestheight, pDiff(sec, sectors, SizeOf(sector_t)));
        if sec <> nil then
        begin
          floor.texture := sec.floorpic;
          floor.newspecial := sec.special;
          //jff 3/14/98 transfer both old and new special
          floor.oldspecial := sec.oldspecial;
        end;
      end;
    end;
    TSlopeRoutines.P_DynamicSlope(sec);  // JVAL: Slopes
  until secnum < 0;
end;

//==============================================================================
//
// EV_DoChange
//
// Handle pure change types. These change floor texture and sector type
// by trigger or numeric model without moving the floor.
//
// The linedef causing the change and the type of change is passed
// Returns true if any sector changes
//
// jff 3/15/98 added to better support generalized sector types
//
//==============================================================================
function EV_DoChange(line: Pline_t; changetype: change_e): integer;
var
  secnum: integer;
  sec: Psector_t;
  secm: Psector_t;
begin
  result := 0;
  secnum := -1;
  // change all sectors with the same tag as the linedef
  while P_FindSectorFromLineTag2(line, secnum) >= 0 do
  begin
    sec := @sectors[secnum];

    result := 1;

    // handle trigger or numeric change type
    case changetype of
      trigChangeOnly:
        begin
          sec.floorpic := line.frontsector.floorpic;
          sec.special := line.frontsector.special;
          sec.oldspecial := line.frontsector.oldspecial;
        end;
      numChangeOnly:
        begin
          secm := P_FindModelFloorSector(sec.floorheight,secnum);
          if secm <> nil then // if no model, no change
          begin
            sec.floorpic := secm.floorpic;
            sec.special := secm.special;
            sec.oldspecial := secm.oldspecial;
          end;
        end;
    end;
  end;
end;

//==============================================================================
// EV_BuildStairs
//
// BUILD A STAIRCASE!
//
//==============================================================================
function EV_BuildStairs(line: Pline_t; _type: stair_e): integer;
var
  secnum: integer;
  height: integer;
  i: integer;
  newsecnum: integer;
  texture: integer;
  ok: boolean;
  sec: Psector_t;
  tsec: Psector_t;
  floor: Pfloormove_t;
  stairsize: fixed_t;
  speed: fixed_t;
  plan: TStairPlan;
begin
  secnum := -1;
  result := 0;

  repeat
    secnum := P_FindSectorFromLineTag(line, secnum);
    if secnum < 0 then
      exit;

    sec := @sectors[secnum];

    // ALREADY MOVING?  IF SO, KEEP GOING...
    if P_SectorActive(floor_special, sec) then
      continue;

    // new floor thinker
    result := 1;
    floor := Z_Malloc(SizeOf(floormove_t), PU_LEVSPEC, nil);
    ZeroMemory(floor, SizeOf(floormove_t));
    TTickRoutines.P_AddThinker(@floor.thinker);
    sec.floordata := floor;
    floor.thinker._function.acp1 := @T_MoveFloor;
    // speed, step, direction and crushing of the kind with the rules of the
    // game and of the version of the engine (TFloorMachine, IdTech1\Thinkers)
    plan := TFloorMachine.StairPlan(StairKindOf(_type), FloorModernEngine, FloorProfile);
    speed := plan.Speed;
    stairsize := plan.StepSize;
    if plan.ClearFirstTag then
      sec.tag := 0; // haleyjd 20140919: [STRIFE] clears tag of first stair sector
    floor.direction := plan.Direction;
    floor.sector := sec;
    if plan.FirstIsStair then
      floor._type := buildStair;
    floor.crush := plan.FirstCrush;
    floor.speed := speed;

    height := sec.floorheight + stairsize;
    floor.floordestheight := height;

    texture := sec.floorpic;

    // Find next sector to raise
    // 1.  Find 2-sided line with same sector side[0]
    // 2.  Other side is the next sector to raise
    repeat
      ok := false;
      for i := 0 to sec.linecount - 1 do
      begin
        if sec.lines[i].flags and ML_TWOSIDED = 0 then
          continue;

        tsec := sec.lines[i].frontsector;
        newsecnum := pDiff(tsec, @sectors[0], SizeOf(sector_t));

        if secnum <> newsecnum then
          continue;

        tsec := sec.lines[i].backsector;
        if tsec = nil then
          continue;
        newsecnum := pDiff(tsec, @sectors[0], SizeOf(sector_t));

        if tsec.floorpic <> texture then
          continue;

        height := height + stairsize;

        if P_SectorActive(floor_special, tsec) then
          continue;

        sec := tsec;
        secnum := newsecnum;
        floor := Z_Malloc(SizeOf(floormove_t), PU_LEVSPEC, nil);
        ZeroMemory(floor, SizeOf(floormove_t));
        TTickRoutines.P_AddThinker(@floor.thinker);

        sec.floordata := floor;
        floor.thinker._function.acp1 := @T_MoveFloor;
        floor.direction := plan.Direction;
        floor.sector := sec;
        floor.speed := speed;
        floor.floordestheight := height;
        floor._type := buildStair;
        floor.crush := plan.NextCrush;
        ok := true;
        break;
      end;
    until not ok;
  until secnum < 0;
end;

//==============================================================================
//
// EV_DoDonut2
//
// Handle donut function: lower pillar, raise surrounding pool, both to height,
// texture and type of the sector surrounding the pool.
//
// Passed the linedef that triggered the donut
// Returns whether a thinker was created
//
//==============================================================================
function EV_DoDonut2(line: Pline_t): integer;
var
  s1: Psector_t;
  s2: Psector_t;
  s3: Psector_t;
  secnum: integer;
  i: integer;
  floor: Pfloormove_t;
begin
  secnum := -1;
  result := 0;
  // do function on all sectors with same tag as linedef
  while P_FindSectorFromLineTag2(line, secnum) >= 0 do
  begin
    s1 := @sectors[secnum];                // s1 is pillar's sector

    // do not start the donut if the pillar is already moving
    if P_SectorActive(floor_special, s1) then //jff 2/22/98
      continue;

    s2 := getNextSector(s1.lines[0], s1); // s2 is pool's sector
    if s2 = nil then                      // note lowest numbered line around
      continue;                           // pillar must be two-sided

    // do not start the donut if the pool is already moving
    if P_SectorActive(floor_special, s2) then
      continue;

    // find a two sided line around the pool whose other side isn't the pillar
    for i := 0 to s2.linecount - 1 do
    begin
      //jff 3/29/98 use true two-sidedness, not the flag
      if (s2.lines[i].backsector = nil) or (s2.lines[i].backsector = s1) then
        continue;

      result := 1; //jff 1/26/98 no donut action - no switch change on return

      s3 := s2.lines[i].backsector;      // s3 is model sector for changes

      //  Spawn rising slime
      floor := Z_Malloc(SizeOf(floormove_t), PU_LEVSPEC, nil);
      TTickRoutines.P_AddThinker(@floor.thinker);
      s2.floordata := floor; //jff 2/22/98
      floor.thinker._function.acp1 := @T_MoveFloor;
      floor._type := donutRaise;
      floor.crush := false;
      floor.direction := 1;
      floor.sector := s2;
      floor.speed := FLOORSPEED div 2;
      floor.texture := s3.floorpic;
      floor.newspecial := 0;
      floor.floordestheight := s3.floorheight;

      //  Spawn lowering donut-hole pillar
      floor := Z_Malloc(SizeOf(floormove_t), PU_LEVSPEC, nil);
      TTickRoutines.P_AddThinker (@floor.thinker);
      s1.floordata := floor; //jff 2/22/98
      floor.thinker._function.acp1 := @T_MoveFloor;
      floor._type := lowerFloor;
      floor.crush := false;
      floor.direction := -1;
      floor.sector := s1;
      floor.speed := FLOORSPEED div 2;
      floor.floordestheight := s3.floorheight;
      break;
    end;
  end;
end;

//==============================================================================
//
// EV_DoDonut
//
//==============================================================================
function EV_DoDonut(line: Pline_t): integer;
var
  s1: Psector_t;
  s2: Psector_t;
  s3: Psector_t;
  secnum: integer;
  i: integer;
  floor: Pfloormove_t;
begin
  if FloorModernEngine then
  begin
    result := EV_DoDonut2(line);
    exit;
  end;

  result := 0;
  secnum := P_FindSectorFromLineTag(line, -1);
  while secnum >= 0 do
  begin
    s1 := @sectors[secnum];
    secnum := P_FindSectorFromLineTag(line, secnum);

    // ALREADY MOVING?  IF SO, KEEP GOING...
    if P_SectorActive(floor_special, s1) then
      continue;

    s2 := getNextSector(s1.lines[0], s1); // s2 is pool's sector
    if s2 = nil then
     continue;

    result := 1;
    for i := 0 to s2.linecount - 1 do
    begin
      if (s2.lines[i].flags and ML_TWOSIDED = 0) or
         (s2.lines[i].backsector = s1) then
        continue;
      s3 := s2.lines[i].backsector;

      //  Spawn rising slime
      floor := Z_Malloc(SizeOf(floormove_t), PU_LEVSPEC, nil);
      TTickRoutines.P_AddThinker(@floor.thinker);
      s2.floordata := floor;
      floor.thinker._function.acp1 := @T_MoveFloor;
      floor._type := donutRaise;
      floor.crush := false;
      floor.direction := 1;
      floor.sector := s2;
      floor.speed := FLOORSPEED div 2;
      floor.texture := s3.floorpic;
      floor.newspecial := 0;
      floor.floordestheight := s3.floorheight;

      //  Spawn lowering donut-hole
      floor := Z_Malloc(SizeOf(floormove_t), PU_LEVSPEC, nil);
      TTickRoutines.P_AddThinker(@floor.thinker);
      s1.floordata := floor;
      floor.thinker._function.acp1 := @T_MoveFloor;
      floor._type := lowerFloor;
      floor.crush := false;
      floor.direction := -1;
      floor.sector := s1;
      floor.speed := FLOORSPEED div 2;
      floor.floordestheight := s3.floorheight;
      break;
    end;
  end;
end;

//==============================================================================
//
// EV_DoElevator
//
// Handle elevator linedef types
//
// Passed the linedef that triggered the elevator and the elevator action
//
// jff 2/22/98 new type to move floor and ceiling in parallel
//
//==============================================================================
function EV_DoElevator(line: Pline_t; elevtype: elevator_e): integer;
var
  secnum: integer;
  sec: Psector_t;
  elevator: Pelevator_t;
begin
  result := 0;
  secnum := -1;
  // act on all sectors with the same tag as the triggering linedef
  while P_FindSectorFromLineTag2(line, secnum) >= 0 do
  begin
    sec := @sectors[secnum];

    // If either floor or ceiling is already activated, skip it
    if (sec.floordata <> nil) or (sec.ceilingdata <> nil) then //jff 2/22/98
      continue;

    // create and initialize new elevator thinker
    result := 1;
    elevator := Z_Malloc(SizeOf(elevator_t), PU_LEVSPEC, nil);
    TTickRoutines.P_AddThinker(@elevator.thinker);
    sec.floordata := elevator; //jff 2/22/98
    sec.ceilingdata := elevator; //jff 2/22/98
    elevator.thinker._function.acp1 := @T_MoveElevator;
    elevator._type := elevtype;

    // set up the fields according to the type of elevator action
    case elevtype of
        // elevator down to next floor
      elevateDown:
        begin
          elevator.direction := -1;
          elevator.sector := sec;
          elevator.speed := ELEVATORSPEED;
          elevator.floordestheight := P_FindNextLowestFloor(sec,sec.floorheight);
          elevator.ceilingdestheight := elevator.floordestheight + sec.ceilingheight - sec.floorheight;
        end;

        // elevator up to next floor
      elevateUp:
        begin
          elevator.direction := 1;
          elevator.sector := sec;
          elevator.speed := ELEVATORSPEED;
          elevator.floordestheight := P_FindNextHighestFloor(sec,sec.floorheight);
          elevator.ceilingdestheight := elevator.floordestheight + sec.ceilingheight - sec.floorheight;
        end;

        // elevator to floor height of activating switch's front sector
      elevateCurrent:
        begin
          elevator.sector := sec;
          elevator.speed := ELEVATORSPEED;
          elevator.floordestheight := line.frontsector.floorheight;
          elevator.ceilingdestheight := elevator.floordestheight + sec.ceilingheight - sec.floorheight;
          if elevator.floordestheight > sec.floorheight then
            elevator.direction := 1
          else
            elevator.direction := -1;
        end;
    end;
  end;
end;

end.

