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
  tables,
  p_local,
  p_mobj_h,
  r_defs;

//==============================================================================
// EV_Teleport
//
// TELEPORTATION
//
//==============================================================================
function EV_Teleport(line: Pline_t; side: integer; thing: Pmobj_t): boolean;

//==============================================================================
//
// P_Teleport
//
//==============================================================================
function P_Teleport(thing: Pmobj_t; x, y: fixed_t; angle: angle_t; destfogdz: fixed_t = 0): boolean;

implementation

uses
  d_delphi,
  doomdef,
  d_think,
  d_player,
  g_game,
  info_h,
  p_3dfloors,
  p_setup,
  p_tick,
  p_mobj,
  p_map,
  s_sound,
  sounddata,
  udmf_telept,
  DelphiDoom.Thinkers.Teleport.Geometry,
  DelphiDoom.Thinkers.Teleport.Placement,
  DelphiDoom.Engine.Teleport.Services;

//==============================================================================
//
// EV_Teleport
//
//==============================================================================
function EV_Teleport(line: Pline_t; side: integer; thing: Pmobj_t): boolean;
var
  i: integer;
  tag: integer;
  m: Pmobj_t;
  thinker: Pthinker_t;
  sector: Psector_t;
  destfogdz: fixed_t; // JVAL: 3d Floors
  dz: fixed_t;
begin
  // don't teleport missiles
  if thing.flags and MF_MISSILE <> 0 then
  begin
    result := false;
    exit;
  end;

  if thing.flags2 and MF2_NOTELEPORT <> 0 then
  begin
    result := false;
    exit;
  end;

  // Don't teleport if hit back of line,
  //  so you can get out of teleporter.
  if side = 1 then
  begin
    result := false;
    exit;
  end;

  tag := line.tag;
  for i := 0 to numsectors - 1 do
  begin
    if sectors[i].tag = tag then
    begin
      thinker := thinkercap.next;
      while thinker <> @thinkercap do
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

        // JVAL: 3d Floors
        if (G_PlayingEngineVersion >= VERSION115) and (P_3dFloorNumber(m) > 0) then
        begin
          destfogdz := m.floorz - Psubsector_t(m.subsector).sector.floorheight;
          dz := thing.z - thing.floorz;
          result := P_Teleport(thing, m.x, m.y, m.angle, destfogdz);
          thing.floorz := m.floorz;
          thing.ceilingz := m.ceilingz;
          thing.z := thing.floorz + dz;
        end
        else
          result := P_Teleport(thing, m.x, m.y, m.angle);

        exit;
      end;
    end;
  end;
  result := false;
end;

//----------------------------------------------------------------------------
//
// FUNC P_Teleport
//
//----------------------------------------------------------------------------
//
//==============================================================================
function P_Teleport(thing: Pmobj_t; x, y: fixed_t; angle: angle_t; destfogdz: fixed_t = 0): boolean;
var
  oldx: fixed_t;
  oldy: fixed_t;
  oldz: fixed_t;
  aboveFloor: fixed_t;
  fogDelta: fixed_t;
  player: Pplayer_t;
  settleinput: TTeleportSettleInput;
  settleoutput: TTeleportSettleOutput;
begin
  oldx := thing.x;
  oldy := thing.y;
  oldz := thing.z;
  aboveFloor := thing.z - thing.floorz;
  if not P_TeleportMove(thing, x, y) then
  begin
    result := false;
    exit;
  end;

  // The height of the thing at the destination (TTeleportPlacement, Libs\Thinkers): on the
  // floor, except a flying player and a missile, which keep their height above it
  player := thing.player;
  settleinput.IsPlayer := player <> nil;
  settleinput.IsMissile := thing.flags and MF_MISSILE <> 0;
  settleinput.IsFlying := (player <> nil) and (player.powers[Ord(pw_flight)] <> 0);
  settleinput.AboveFloor := aboveFloor;
  settleinput.FloorZ := thing.floorz;
  settleinput.CeilingZ := thing.ceilingz;
  settleinput.Height := thing.height;
  settleinput.UseFog := true;
  TTeleportPlacement.Settle(settleinput, settleoutput);
  thing.z := settleoutput.Z;
  if settleoutput.UpdatesViewHeight then
    player.viewz := thing.z + player.viewheight;
  if settleoutput.ResetsLook then
  begin
    player.lookdir := 0;
    player.lookdir16 := 0; // JVAL Smooth Look Up/Down
  end;

  // Spawn teleport fog at source and destination
  fogDelta := TTeleportGeometry.FogHeight(thing.flags and MF_MISSILE <> 0);
  TeleportFogSpawner.SpawnFog(oldx, oldy, oldz + fogDelta, true);
  TeleportFogSpawner.SpawnFog(TTeleportGeometry.FogX(x, angle), TTeleportGeometry.FogY(y, angle),
    thing.z + fogDelta + destfogdz, true);
  if (thing.player <> nil) and (Pplayer_t(thing.player).powers[Ord(pw_weaponlevel2)] = 0) then // Freeze player for about .5 sec
    thing.reactiontime := 18;

  if thing.player <> nil then
    Pplayer_t(thing.player).teleporttics := TELEPORTZOOM;

  thing.angle := angle;
  if (thing.flags2 and MF2_FOOTCLIP <> 0) and (P_GetThingFloorType(thing) <> FLOOR_SOLID) then
    thing.flags2 := thing.flags2 or MF2_FEETARECLIPPED
  else if thing.flags2 and MF2_FEETARECLIPPED <> 0 then
    thing.flags2 := thing.flags2 and not MF2_FEETARECLIPPED;

  if thing.flags and MF_MISSILE <> 0 then
  begin
    thing.momx := TTeleportGeometry.MissileMomentumX(thing.info.speed, angle);
    thing.momy := TTeleportGeometry.MissileMomentumY(thing.info.speed, angle);
  end
  else
  begin
    thing.momx := 0;
    thing.momy := 0;
    thing.momz := 0;
  end;
  result := true;
end;

end.
