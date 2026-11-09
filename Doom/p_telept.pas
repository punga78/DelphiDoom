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
function EV_Teleport(line: Pline_t; side: integer; thing: Pmobj_t): integer;

//==============================================================================
//
// EV_SilentTeleport
//
//==============================================================================
function EV_SilentTeleport(line: Pline_t; side: integer; thing: Pmobj_t): integer;

//==============================================================================
//
// EV_SilentLineTeleport
//
//==============================================================================
function EV_SilentLineTeleport(line: Pline_t; side: integer; thing: Pmobj_t; reverse: boolean): integer;

implementation

uses
  d_delphi,
  doomdef,
  doomstat,
  d_think,
  d_player,
  info_h,
  g_game,
  p_3dfloors,
  p_setup,
  p_tick,
  p_mobj,
  p_map,
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
//
// EV_Teleport
//
//==============================================================================
function EV_Teleport(line: Pline_t; side: integer; thing: Pmobj_t): integer;
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
  // don't teleport missiles
  if thing.flags and MF_MISSILE <> 0 then
  begin
    result := 0;
    exit;
  end;

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

        oldx := thing.x;
        oldy := thing.y;
        oldz := thing.z;
        dz := oldz - thing.floorz;

        if not P_TeleportMove(thing, m.x, m.y) then
        begin
          result := 0;
          exit;
        end;

        // fraggle: this was changed in final doom,
        // problem between normal doom2 1.9 and final doom
        //
        // Note that although chex.exe is based on Final Doom,
        // it does not have this quirk.

        if (gameversion < exe_final) or (gameversion = exe_chex) or (G_PlayingEngineVersion in [VERSION111..VERSION118]) then
          thing.z := thing.floorz;  //fixme: not needed?

        // JVAL: 3d Floors
        if (G_PlayingEngineVersion >= VERSION122) and (P_3dFloorNumber(m) > 0) then
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
        TeleportFogSpawner.SpawnFog(oldx, oldy, oldz, true);
        // emit sound, where? at the destination fog
        TeleportFogSpawner.SpawnFog(TTeleportGeometry.FogX(m.x, m.angle),
                                    TTeleportGeometry.FogY(m.y, m.angle),
                                    thing.z, true);

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

//==============================================================================
// EV_SilentTeleport
//
// Silent TELEPORTATION, by Lee Killough
// Primarily for rooms-over-rooms etc.
//
//==============================================================================
function EV_SilentTeleport(line: Pline_t; side: integer; thing: Pmobj_t): integer;
var
  i: integer;
  m: Pmobj_t;
  th: Pthinker_t;
  z: fixed_t;
  s: fixed_t;
  c: fixed_t;
  momx: fixed_t;
  momy: fixed_t;
  angle: angle_t;
  player: Pplayer_t;
  deltaviewheight: fixed_t;
begin

  // don't teleport missiles
  // Don't teleport if hit back of line,
  // so you can get out of teleporter.

  if (side <> 0) or (thing.flags and MF_MISSILE <> 0) then
  begin
    result := 0;
    exit;
  end;

  i := -1;
  while P_FindSectorFromLineTag2(line, i) >= 0 do
  begin
    th := thinkercap.next;
    while th <> @thinkercap do
    begin
      m := Pmobj_t(th);
      if (@th._function.acp1 = @P_MobjThinker) and
         (m._type = Ord(MT_TELEPORTMAN)) and
         (pDiff(Psubsector_t(m.subsector).sector, sectors, SizeOf(sector_t)) = i) then
        begin
          // Height of thing above ground, in of mid-air teleports:
          z := thing.z - thing.floorz;

          // Get the angle between the exit thing and source linedef.
          // Rotate 90 degrees, so that walking perpendicularly across
          // teleporter linedef causes thing to exit in the direction
          // indicated by the exit thing.
          angle := TTeleportGeometry.SilentExitAngle(R_PointToAngle2(0, 0, line.dx, line.dy), m.angle);

          // Sine, cosine of angle adjustment
          s := TTeleportGeometry.SineOf(angle);
          c := TTeleportGeometry.CosineOf(angle);

          // Momentum of thing crossing teleporter linedef
          momx := thing.momx;
          momy := thing.momy;

          // Whether this is a player, and if so, a pointer to its player_t
          player := thing.player;

          // Attempt to teleport, aborting if blocked
          if not P_TeleportMove(thing, m.x, m.y) then
          begin
            result := 0;
            exit;
          end;

          // Rotate thing according to difference in angles
          thing.angle := thing.angle + angle;

          // Adjust z position to be same height above ground as before
          thing.z := z + thing.floorz;

          // Rotate thing's momentum to come out of exit just like it entered
          thing.momx := TTeleportGeometry.RotatedMomentumX(momx, momy, s, c);
          thing.momy := TTeleportGeometry.RotatedMomentumY(momx, momy, s, c);

          // Adjust player's view, in there has been a height change
          // Voodoo dolls are excluded by making sure player.mo = thing.
          if player <> nil then
            if player.mo = thing then
            begin
              // Save the current deltaviewheight, used in stepping
              deltaviewheight := player.deltaviewheight;

              // Clear deltaviewheight, since we don't want any changes
              player.deltaviewheight := 0;

              // Set player's view according to the newly set parameters
              P_CalcHeight(player);

              // Reset the delta to have the same dynamics as before
              player.deltaviewheight := deltaviewheight;
            end;
          result := 1;
          exit;
        end;
        th := th.next;
      end;
  end;
  result := 0;
end;

//
// Silent linedef-based TELEPORTATION, by Lee Killough
// Primarily for rooms-over-rooms etc.
// This is the complete player-preserving kind of teleporter.
// It has advantages over the teleporter with thing exits.
//

// (the maximum fixed_t units to move object to avoid hiccups is
// TELEPORT_FUDGE_FACTOR of TTeleportLineExit)

//==============================================================================
//
// EV_SilentLineTeleport
//
//==============================================================================
function EV_SilentLineTeleport(line: Pline_t; side: integer; thing: Pmobj_t; reverse: boolean): integer;
var
  i: integer;
  l: Pline_t;
  angle: angle_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  s: fixed_t;
  c: fixed_t;
  lineinput: TTeleportLineInput;
  lineoutput: TTeleportLineOutput;
  player: Pplayer_t;
  stepdown: boolean;
  deltaviewheight: fixed_t;
begin
  if (side <> 0) or (thing.flags and MF_MISSILE <> 0) then
  begin
    result := 0;
    exit;
  end;

  i := -1;
  while P_FindLineFromLineTag2(line, i) >= 0 do
  begin
    l := @lines[i];
    if (l <> line) and (l.backsector <> nil) then
    begin
      // Whether this is a player, and if so, a pointer to its player_t.
      // Voodoo dolls are excluded by making sure thing.player.mo==thing.
      player := nil;
      if thing.player <> nil then
        if Pplayer_t(thing.player).mo = thing then
          player := thing.player;

      // Whether walking towards first side of exit linedef steps down
      stepdown := l.frontsector.floorheight < l.backsector.floorheight;

      // Height of thing above ground
      z := thing.z - thing.floorz;

      // The exit position and the rotation (TTeleportLineExit, Libs\Thinkers): the position of
      // the thing along the source linedef, the angle between the two linedefs (180 degrees more,
      // or the position flipped across the exit linedef, if reversed), the interpolated position
      // across the exit linedef and the sine and cosine of the angle. The position is moved
      // by at most FUDGEFACTOR units until it is on the correct side of the exit linedef:
      // the side is 1 for a reversed teleporter or a player that steps down, 0 otherwise.
      lineinput.SourceDx := line.dx;
      lineinput.SourceDy := line.dy;
      lineinput.SourceStartX := line.v1.x;
      lineinput.SourceStartY := line.v1.y;
      lineinput.SourceAngle := R_PointToAngle2(0, 0, line.dx, line.dy);
      lineinput.ExitDx := l.dx;
      lineinput.ExitDy := l.dy;
      lineinput.ExitEndX := l.v2.x;
      lineinput.ExitEndY := l.v2.y;
      lineinput.ExitAngle := R_PointToAngle2(0, 0, l.dx, l.dy);
      lineinput.ThingX := thing.x;
      lineinput.ThingY := thing.y;
      lineinput.Reverse := reverse;
      lineinput.ThingIsPlayer := player <> nil;
      lineinput.StepDown := stepdown;
      TTeleportLineExit.Compute(lineinput, TEngineTeleportLineSide.Create(l), lineoutput);
      x := lineoutput.X;
      y := lineoutput.Y;
      angle := lineoutput.Angle;
      s := lineoutput.Sine;
      c := lineoutput.Cosine;

      // Attempt to teleport, aborting if blocked
      if not P_TeleportMove(thing, x, y) then
      begin
        result := 0;
        exit;
      end;

      // Adjust z position to be same height above ground as before.
      // Ground level at the exit is measured as the higher of the
      // two floor heights at the exit linedef.
      thing.z := z + sides[l.sidenum[intval(stepdown)]].sector.floorheight;

      // Rotate thing's orientation according to difference in linedef angles
      thing.angle := thing.angle + angle;

      // Momentum of thing crossing teleporter linedef
      x := thing.momx;
      y := thing.momy;

      // Rotate thing's momentum to come out of exit just like it entered
      thing.momx := TTeleportGeometry.RotatedMomentumX(x, y, s, c);
      thing.momy := TTeleportGeometry.RotatedMomentumY(x, y, s, c);

      // Adjust a player's view, in there has been a height change
      if player <> nil then
      begin
        // Save the current deltaviewheight, used in stepping
        deltaviewheight := player.deltaviewheight;

        // Clear deltaviewheight, since we don't want any changes now
        player.deltaviewheight := 0;

        // Set player's view according to the newly set parameters
        P_CalcHeight(player);

        // Reset the delta to have the same dynamics as before
        player.deltaviewheight := deltaviewheight;
      end;

      result := 1;
      exit;
    end;
  end;
  result := 0;
end;

end.

