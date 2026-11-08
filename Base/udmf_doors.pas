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
//  Door animation code (opening/closing) (UDMF & Hexen)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit udmf_doors;

interface

uses
  d_delphi,
  z_zone,
  doomdef,
  m_fixed,
  p_mobj_h,
  p_spec,
  r_defs;

//==============================================================================
//
// TH_VerticalDoor
//
//==============================================================================
procedure TH_VerticalDoor(door: Pvldoor_t);

//==============================================================================
//
// EVH_DoDoor
//
//==============================================================================
function EVH_DoDoor(line: Pline_t; args: PByteArray; _type: vldoor_e): boolean;

//==============================================================================
//
// EVH_VerticalDoor
//
//==============================================================================
function EVH_VerticalDoor(line: Pline_t; thing: Pmobj_t): boolean;

implementation

uses
  p_tick,
  p_acs,
  {$IFNDEF HEXEN}
  udmf_spec,
  {$ENDIF}
  p_setup,
  DelphiDoom.Engine.Door.Thinker;

//==============================================================================
//
// VERTICAL DOORS
//
// TH_VerticalDoor
//
// The state machine of the door (waiting, going down, going up, the sounds and
// the sequences) is in Libs\Thinkers (DelphiDoom.Thinkers.Door.*); the thinker
// stays the vldoor_t of the zone memory
//
//==============================================================================
procedure TH_VerticalDoor(door: Pvldoor_t);
begin
  if DoorTickUdmf(door) then
  begin
    door.sector.specialdata := nil;
    P_TagFinished(door.sector.tag);
    P_RemoveThinker(@door.thinker); // unlink and free
  end;
end;

//==============================================================================
//
// EVH_DoDoor
//
// Move a door up/down
//
//==============================================================================
function EVH_DoDoor(line: Pline_t; args: PByteArray; _type: vldoor_e): boolean;
var
  initial: boolean;
  secnum: integer;
  sec: Psector_t;
  door: Pvldoor_t;
  speed: fixed_t;
begin
  speed := args[1] * (FRACUNIT div 8);
  secnum := -1;
  result := false;

  initial := true;
  while (secnum >= 0) or initial do
  begin
    initial := false;
    secnum := P_FindSectorFromTag(args[0], secnum);
    if secnum < 0 then
      break;

    sec := @sectors[secnum];
    if sec.specialdata <> nil then
      continue;

    // new door thinker
    result := true;
    door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);
    P_AddThinker(@door.thinker);
    sec.specialdata := door;

    door.thinker._function.acp1 := @TH_VerticalDoor;
    door.sector := sec;
    // direction, top, wait and sound of the kind: Libs\Thinkers
    DoorInitTagged(door, _type, speed, args[2], true);
  end;
end;

//==============================================================================
//
// EVH_VerticalDoor : open a door manually, no tag value
//
//==============================================================================
function EVH_VerticalDoor(line: Pline_t; thing: Pmobj_t): boolean;
var
  sec: Psector_t;
  door: Pvldoor_t;
  side: integer;
begin
  side := 0; // only front sides can be used

  // if the sector has an active thinker, use it
  sec := sides[line.sidenum[side xor 1]].sector;
  if sec.specialdata <> nil then
  begin
    result := false;
    exit;
  end;

  //
  // new door thinker
  //
  door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);
  P_AddThinker(@door.thinker);
  sec.specialdata := door;
  door.thinker._function.acp1 := @TH_VerticalDoor;
  door.sector := sec;

  // kind, speed, wait, top and sound of the special of the line: Libs\Thinkers
  if DoorInitManual(door, line.special, line.arg2 * (FRACUNIT div 8), line.arg3, true) then
    line.special := 0;
  result := true;
end;

end.
