//------------------------------------------------------------------------------
//
//  DelphiStrife is a source port of the game Strife.
//
//  Based on:
//    - Linux Doom by "id Software"
//    - Chocolate Strife by "Simon Howard"
//    - DelphiDoom by "Jim Valavanis"
//
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2005 Simon Howard
//  Copyright (C) 2010 James Haley, Samuel Villarreal
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
//  Teleportation.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_telept;

interface

uses
  m_fixed,
  p_mobj_h,
  r_defs;

//==============================================================================
// EV_Teleport
//
// TELEPORTATION
//
//==============================================================================
function EV_Teleport(line: Pline_t; side: integer; thing: Pmobj_t; flags: integer): integer;

implementation

uses
  d_delphi,
  doomdef,
  d_think,
  d_player,
  info_h,
  g_game,
  p_3dfloors,
  p_setup,
  p_tick,
  p_mobj,
  p_map,
  DelphiDoom.Engine.World.SectorSearch,
  p_spec_h,
  DelphiDoom.Engine.World.SpecRules,
  p_spec,
  p_user,
  r_main,
  sounddata,
  udmf_telept,
  tables,
  DelphiDoom.Thinkers.Teleport.Geometry,
  DelphiDoom.Thinkers.Teleport.LineExit,
  DelphiDoom.Engine.Teleport.Services,
  DelphiDoom.Engine.Teleport.LineSide;

//==============================================================================
// EV_Teleport
//
// TELEPORTATION
//
// haleyjd 09/22/10: [STRIFE] Modified to take a flags parameter to control
// silent teleportation. Rogue also removed the check for missiles, and the
// z-set was replaced with one in P_TeleportMove.
//
//==============================================================================
function EV_Teleport(line: Pline_t; side: integer; thing: Pmobj_t; flags: integer): integer;
var
  i: integer;
  tag: integer;
  m: Pmobj_t;
  thinker: Pthinker_t;
  sector: Psector_t;
  p: Pplayer_t;
  oldx: fixed_t;
  oldy: fixed_t;
  oldz: fixed_t;
  dz: fixed_t; // JVAL: 3d Floors
begin
  // 19/9/2009 JVAL: NO TELEPORT FLAG
  if thing.flags2_ex and MF2_EX_NOTELEPORT <> 0 then
  begin
    result := 0;
    exit;
  end;

  // Don't teleport if hit back of line,
  //  so you can get out of teleporter.
  if side = 1 then
  begin
    result := 0;
    exit;
  end;

  tag := line.tag;
  for i := 0 to numsectors - 1 do
  begin
    if sectors[i].tag = tag then
    begin
      thinker := TTickState.ThinkerCap.next;
      while thinker <> @TTickState.ThinkerCap do
      begin
        // not a mobj
        if @thinker._function.acp1 <> @P_MobjThinker then
        begin
          thinker := thinker.next;
          continue;
        end;

        m := Pmobj_t(thinker);

        // not a teleportman
        if m._type <> Ord(MT_TELEPORTMAN) then
        begin
          thinker := thinker.next;
          continue;
        end;

        sector := Psubsector_t(m.subsector).sector;
        // wrong sector
        if sector <> @sectors[i] then
        begin
          thinker := thinker.next;
          continue;
        end;

        oldx := thing.x;
        oldy := thing.y;
        oldz := thing.z;
        dz := oldz - thing.floorz;

        if not P_TeleportMove(thing, m.x, m.y) then
        begin
          result := 0;
          exit;
        end;

        // JVAL: 3d Floors
        if (G_PlayingEngineVersion >= VERSION122) and (T3dFloorRoutines.P_3dFloorNumber(m) > 0) then
        begin
          thing.floorz := m.floorz;
          thing.ceilingz := m.ceilingz;
          thing.z := thing.floorz + dz;
        end;

        p := Pplayer_t(thing.player);
        if p <> nil then
        begin
          p.viewz := thing.z + p.viewheight;
          p.lookdir := 0;
          p.lookdir16 := 0; // JVAL Smooth Look Up/Down
        end;

        // spawn teleport fog at source and destination
        // haleyjd 09/22/10: [STRIFE] controlled by teleport flags
        // BUG: Behavior would be undefined if this function were passed
        // any combination of teleflags that has the NO*FOG but not the
        // corresponding NO*SND flag - fortunately this is never done
        // anywhere in the code.
        if flags and TF_NOSRCFOG = 0 then
          TeleportFogSpawner.SpawnFog(oldx, oldy, oldz, flags and TF_NOSRCSND = 0);
        if flags and TF_NOSRCFOG = 0 then
          // emit sound, where? at the destination fog
          TeleportFogSpawner.SpawnFog(TTeleportGeometry.FogX(m.x, m.angle),
                                      TTeleportGeometry.FogY(m.y, m.angle),
                                      thing.z, flags and TF_NOSRCSND = 0);

        // don't move for a bit
        if thing.player <> nil then
        begin
          thing.reactiontime := 18;
          Pplayer_t(thing.player).teleporttics := TELEPORTZOOM;
        end;

        thing.angle := m.angle;
        thing.momx := 0;
        thing.momy := 0;
        thing.momz := 0;
        result := 1;
        exit;
      end;
    end;
  end;
  result := 0;
end;

end.

