//------------------------------------------------------------------------------
//
//  DelphiHeretic is a source port of the game Heretic and it is
//  based on original Linux Doom as published by "id Software", on
//  Heretic source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION: Door animation code (opening/closing)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_doors;

interface

uses
  doomdef,
  z_zone,
  m_fixed,
  p_mobj_h,
  p_spec,
  r_defs,
  s_sound,
// State.
  
// Data.
  sounddata;

//==============================================================================
//
// T_VerticalDoor
//
//==============================================================================
procedure T_VerticalDoor(door: Pvldoor_t);

//==============================================================================
//
// EV_DoDoor
//
//==============================================================================
function EV_DoDoor(line: Pline_t; _type: vldoor_e; speed: fixed_t = VDOORSPEED): integer;

//==============================================================================
//
// EV_VerticalDoor
//
//==============================================================================
procedure EV_VerticalDoor(line: Pline_t; thing: Pmobj_t);

//==============================================================================
//
// P_SpawnDoorCloseIn30
//
//==============================================================================
procedure P_SpawnDoorCloseIn30(sec: Psector_t);

//==============================================================================
//
// P_SpawnDoorRaiseIn5Mins
//
//==============================================================================
procedure P_SpawnDoorRaiseIn5Mins(sec: Psector_t; secnum: integer);

implementation

uses
  d_player,
  h_strings,
  p_tick,
  p_setup,
  p_floor,
  DelphiDoom.Thinkers.Door.Types,
  DelphiDoom.Engine.Door.Thinker;

//==============================================================================
//
// VERTICAL DOORS
//
// T_VerticalDoor
//
//==============================================================================
procedure T_VerticalDoor(door: Pvldoor_t);
begin
  // the state machine of the door is in Libs\Thinkers (DelphiDoom.Thinkers.Door.*)
  if DoorTickClassic(door) then
  begin
    door.sector.specialdata := nil;
    P_RemoveThinker(@door.thinker); // unlink and free
  end;
end;

//==============================================================================
//
// EV_DoDoor
//
//==============================================================================
function EV_DoDoor(line: Pline_t; _type: vldoor_e; speed: fixed_t = VDOORSPEED): integer;
var
  initial: boolean;
  secnum: integer;
  sec: Psector_t;
  door: Pvldoor_t;
begin
  secnum := -1;
  result := 0;

  initial := true;
  while (secnum >= 0) or initial do
  begin
    initial := false;
    secnum := P_FindSectorFromLineTag(line, secnum);
    if secnum < 0 then
      break;

    sec := @sectors[secnum];
    if sec.specialdata <> nil then
      continue;

    // new door thinker
    result := 1;
    door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);
    P_AddThinker(@door.thinker);
    sec.specialdata := door;

    door.thinker._function.acp1 := @T_VerticalDoor;
    door.sector := sec;
    // direction, top, speed and sound of the kind: Libs\Thinkers
    DoorInitTagged(door, _type, speed, VDOORWAIT, false);
  end;
end;

//==============================================================================
//
// EV_VerticalDoor : open a door manually, no tag value
//
//==============================================================================
procedure EV_VerticalDoor(line: Pline_t; thing: Pmobj_t);
var
  player: Pplayer_t;
  sec: Psector_t;
  door: Pvldoor_t;
  side: integer;
  action: TDoorRetrigger;
begin
  side := 0;  // only front sides can be used

  // Check for locks
  player := thing.player;

  case line.special of
    26, // Blue Lock
    32:
      begin
        if player = nil then
          exit;

        if not player.keys[Ord(key_blue)] then
        begin
          player._message := TXT_NEEDBLUEKEY;
          S_StartSound(nil, Ord(sfx_plroof));
          exit;
        end;
      end;
    27, // Yellow Lock
    34:
      begin
        if player = nil then
          exit;

        if not player.keys[Ord(key_yellow)] then
        begin
          player._message := TXT_NEEDYELLOWKEY;
          S_StartSound(nil, Ord(sfx_plroof));
          exit;
        end;
      end;
    28, // Green Lock
    33:
      begin
        if player = nil then
          exit;

        if not player.keys[Ord(key_green)] then
        begin
          player._message := TXT_NEEDGREENKEY;
          S_StartSound(nil, Ord(sfx_plroof));
          exit;
        end;
      end;
  end;

  // if the sector has an active thinker, use it
  sec := sides[line.sidenum[side xor 1]].sector;

  if sec.specialdata <> nil then
  begin
    door := sec.specialdata;
    if DoorRetrigger(line.special, door.direction, thing.player <> nil, false, action) then
    begin
      case action of
        TDoorRetrigger.GoUp:
          door.direction := 1; // go back up
        TDoorRetrigger.GoDown:
          door.direction := -1; // start going down immediately
      end;
      exit;
    end;
  end;

  // new door thinker
  door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);
  P_AddThinker(@door.thinker);
  sec.specialdata := door;
  door.thinker._function.acp1 := @T_VerticalDoor;
  door.sector := sec;

  // kind, speed, top and sound of the special of the line: Libs\Thinkers
  if DoorInitManual(door, line.special, VDOORSPEED, VDOORWAIT, false) then
    line.special := 0;
end;

//==============================================================================
// P_SpawnDoorCloseIn30
//
// Spawn a door that closes after 30 seconds
//
//==============================================================================
procedure P_SpawnDoorCloseIn30(sec: Psector_t);
var
  door: Pvldoor_t;
begin
  door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);

  P_AddThinker(@door.thinker);

  sec.specialdata := door;
  sec.special := 0;

  door.thinker._function.acp1 := @T_VerticalDoor;
  door.sector := sec;
  DoorInitCloseIn30(door);
end;

//==============================================================================
// P_SpawnDoorRaiseIn5Mins
//
// Spawn a door that opens after 5 minutes
//
//==============================================================================
procedure P_SpawnDoorRaiseIn5Mins(sec: Psector_t; secnum: integer);
var
  door: Pvldoor_t;
begin
  door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);

  P_AddThinker(@door.thinker);

  sec.specialdata := door;
  sec.special := 0;

  door.thinker._function.acp1 := @T_VerticalDoor;
  door.sector := sec;
  DoorInitRaiseIn5Mins(door);
end;

end.
