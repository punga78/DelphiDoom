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
//    Door animation code (opening/closing)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_doors;

interface

uses
  z_zone,
  doomdef,
  p_mobj_h,
  p_spec,
  r_defs,
  s_sound,
  sounddata,
  dstrings,
  d_englsh;

//==============================================================================
//
// T_VerticalDoor
//
//==============================================================================
procedure T_VerticalDoor(door: Pvldoor_t);

//==============================================================================
//
// EV_DoLockedDoor
//
//==============================================================================
function EV_DoLockedDoor(line: Pline_t; _type: vldoor_e; thing: Pmobj_t): integer;

//==============================================================================
//
// EV_DoDoor
//
//==============================================================================
function EV_DoDoor(line: Pline_t; _type: vldoor_e): integer;

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
  g_game,
  p_genlin,
  p_lights,
  p_plats,
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
    door.sector.ceilingdata := nil;
    P_RemoveThinker(@door.thinker); // unlink and free
  end;
end;

//==============================================================================
//
// EV_DoLockedDoor
// Move a locked door up/down
//
//==============================================================================
function EV_DoLockedDoor(line: Pline_t; _type: vldoor_e; thing: Pmobj_t): integer;
var
  p: Pplayer_t;
begin
  p := thing.player;

  // only players can open locked doors
  if p = nil then
  begin
    result := 0;
    exit;
  end;

  case line.special of
    99,  // Blue Lock
   133:
      begin
        if (not p.cards[Ord(it_bluecard)]) and
           (not p.cards[Ord(it_blueskull)]) then
        begin
          p._message := PD_BLUEO;
          S_StartSound(nil, Ord(sfx_oof));
          result := 0;
          exit;
        end;
      end;

   134, // Red Lock
   135:
      begin
        if (not p.cards[Ord(it_redcard)]) and
           (not p.cards[Ord(it_redskull)]) then
        begin
          p._message := PD_REDO;
          S_StartSound(nil, Ord(sfx_oof));
          result := 0;
          exit;
        end;
      end;

   136,  // Yellow Lock
   137:
      begin
        if (not p.cards[Ord(it_yellowcard)]) and
           (not p.cards[Ord(it_yellowskull)]) then
        begin
          p._message := PD_YELLOWO;
          S_StartSound(nil, Ord(sfx_oof));
          result := 0;
          exit;
        end;
      end;
  end;

  result := EV_DoDoor(line, _type);
end;

//==============================================================================
//
// EV_DoDoor
//
//==============================================================================
function EV_DoDoor(line: Pline_t; _type: vldoor_e): integer;
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
    if P_SectorActive(ceiling_special, sec) then
      continue;

    // new door thinker
    result := 1;
    door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);
    P_AddThinker(@door.thinker);
    sec.ceilingdata := door;

    door.thinker._function.acp1 := @T_VerticalDoor;
    door.sector := sec;
    door.line := nil;
    // direction, top, speed and sound of the kind: Libs\Thinkers
    DoorInitTagged(door, _type, VDOORSPEED, VDOORWAIT, false);
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
  plat: Pplat_t;
  sd: integer;
  action: TDoorRetrigger;
begin
  // Check for locks
  player := thing.player;

  case line.special of
    26, // Blue Lock
    32:
      begin
        if player = nil then
          exit;

        if not player.cards[Ord(it_bluecard)] and
           not player.cards[Ord(it_blueskull)] then
        begin
          player._message := PD_BLUEK;
          S_StartSound(player.mo, Ord(sfx_oof));
          exit;
        end;
      end;
    27, // Yellow Lock
    34:
      begin
        if player = nil then
          exit;

        if not player.cards[Ord(it_yellowcard)] and
           not player.cards[Ord(it_yellowskull)] then
        begin
          player._message := PD_YELLOWK;
          S_StartSound(player.mo, Ord(sfx_oof));
          exit;
        end;
      end;
    28, // Red Lock
    33:
      begin
        if player = nil then
          exit;

        if not player.cards[Ord(it_redcard)] and
           not player.cards[Ord(it_redskull)] then
        begin
          player._message := PD_REDK;
          S_StartSound(player.mo, Ord(sfx_oof));
          exit;
        end;
      end;
  end;

  // if the sector has an active thinker, use it

  sd := line.sidenum[1];

  // if the wrong side of door is pushed, give oof sound
  if sd = -1 then
  begin
    if player <> nil then                     // JVAL: 20210203
      S_StartSound(player.mo, Ord(sfx_oof));  // killough 3/20/98
    exit;
  end;

  // back sides
  sec := sides[sd].sector;

  if P_SectorActive(ceiling_special, sec) then
  begin
    door := sec.ceilingdata;
    if DoorRetrigger(line.special, door.direction, thing.player <> nil, false, action) then
    begin
      case action of
        TDoorRetrigger.GoUp:
          door.direction := 1; // go back up
        TDoorRetrigger.GoDown:
          begin
            // JVAL: 20210203 - From chocolate-doom
            // When is a door not a door?
            // In Vanilla, door->direction is set, even though
            // "specialdata" might not actually point at a door.
            if @door.thinker._function.acp1 = @ T_VerticalDoor then
              door.direction := -1  // start going down immediately
            else if @door.thinker._function.acp1 = @T_PlatRaise then
            begin
              // Erm, this is a plat, not a door.
              // This notably causes a problem in ep1-0500.lmp where
              // a plat and a door are cross-referenced; the door
              // doesn't open on 64-bit.
              // The direction field in vldoor_t corresponds to the wait
              // field in plat_t.  Let's set that to -1 instead.
              plat := sec.ceilingdata;
              plat.wait := -1;
            end;
          end;
      end;
      exit;
    end;
  end;

  // new door thinker
  door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);
  P_AddThinker(@door.thinker);
  sec.ceilingdata := door;
  door.thinker._function.acp1 := @T_VerticalDoor;
  door.sector := sec;
  door.line := nil;

  // kind, speed, top and sound (blazing doors and locked doors have their own)
  // of the special of the line: Libs\Thinkers
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

  sec.ceilingdata := door;
  sec.special := 0;

  door.thinker._function.acp1 := @T_VerticalDoor;
  door.sector := sec;
  door.line := nil; // remember line that triggered us
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

  sec.ceilingdata := door;
  sec.special := 0;

  door.thinker._function.acp1 := @T_VerticalDoor;
  door.sector := sec;
  door.line := nil; // remember line that triggered us
  DoorInitRaiseIn5Mins(door);
end;

end.
