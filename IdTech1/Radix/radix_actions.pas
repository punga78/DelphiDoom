{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - the actions of the levels                          }
{  Copyright (C) 1995 by Epic MegaGames, Inc.                                  }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_actions.pas of Rad-X (the 44 kinds of action of RADIX.DAT)    }
{  and of the case of RX_RunAction of radix_logic.pas, on the engine of today. }
{                                                                              }
{  As in Rad-X an action keeps its own state in its parameters, after the ones }
{  of RADIX.DAT (the fields under "RTL" of every record: they are zero in the  }
{  lump). The records are packed and have the layout of RADIX.DAT.             }
{                                                                              }
{  Differences from Rad-X: the fields that Rad-X added to line_t, sector_t,    }
{  player_t and mobj_t are in radixwallinfo/radixsectorinfo (radix_map_extra), }
{  radixlevelplayers (radix_logic), radixplayers (radix_playerstate) and in    }
{  the tid of the mobj (the number of a thing of RADIX.DAT, set when the map   }
{  things are spawned); a wall, a sector, a trigger or a bitmap that the level }
{  does not have is skipped instead of being read out of the arrays; a delay   }
{  of zero tics does not divide by zero; the sounds are not "full volume" and  }
{  the explosions of the massive explosions are not silenced (MF3_EX_NOSOUND   }
{  is not in the engine)                                                       }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit radix_actions;

interface

uses
  radix_logic;

//==============================================================================
//
// RX_RunAction
// Runs an action for one tic, by its kind (action_type)
//
//==============================================================================
procedure RX_RunAction(const action: Pradixaction_t);

implementation

uses
  d_delphi,
  doomdef,
  d_player,
  d_think,
  g_game,
  m_rnd,
  m_fixed,
  tables,
  p_inter,
  p_map,
  p_mobj_h,
  p_mobj,
  p_tick,
  p_setup,
  p_genlin,
  p_user,
  info_common,
  r_data,
  r_main,
  r_defs,
  s_sound,
  w_wad,
  radix_codepointers,
  radix_map_extra,
  radix_playerstate,
  radix_teleport,
  radix_walls,
  radix_pilotsound,
  DelphiDoom.Radix.LevelLogic.Types,
  DelphiDoom.Radix.Action.Rules,
  DelphiDoom.Radix.Messages,
  DelphiDoom.Radix.Pilot.Rules,
  DelphiDoom.Radix.Thing.Spawn;

const
  RX_WALL_PREFIX = 'RDXW';
  RX_FLAT_PREFIX = 'RDXF';
  // the wall of a missile wall that is alive and the one of a dead one
  RX_MISSILEWALL_BITMAP = '0064';
  RX_DEADMISSILEWALL_BITMAP = '0083';
  ACTION_INITIALIZED = $FFFFDDDD;
  TELEPORTZOOM = 15 * FRACUNIT;
  PLAYERMAXSHIELD = 200;

//==============================================================================
//
// RA_ValidSector
//
//==============================================================================
function RA_ValidSector(const secid: integer): boolean;
begin
  result := (secid >= 0) and (secid < numsectors);
end;

//==============================================================================
//
// RA_LineSides
// The two sides of a wall (nil for the side that is not there); false for a
// wall that the level does not have
//
//==============================================================================
function RA_LineSides(const lineid: integer; out s1, s2: Pside_t): boolean;
var
  li: Pline_t;
begin
  s1 := nil;
  s2 := nil;
  result := RX_ValidLine(lineid);
  if not result then
    exit;
  li := @lines[lineid];
  if li.sidenum[0] >= 0 then
    s1 := @sides[li.sidenum[0]];
  if li.sidenum[1] >= 0 then
    s2 := @sides[li.sidenum[1]];
end;

//==============================================================================
//
// RA_WallTexture
// The texture of a wall bitmap of RADIX.DAT; -1 when it is not there
//
//==============================================================================
function RA_WallTexture(const bitmap: integer): integer;
begin
  result := R_CheckTextureNumForName(RX_WALL_PREFIX + IntToStrZfill(4, bitmap + 1));
end;

//==============================================================================
//
// RA_FlatTexture
// The flat of a bitmap of RADIX.DAT; -1 when it is not there
//
//==============================================================================
function RA_FlatTexture(const bitmap: integer): integer;
var
  name: string;
begin
  name := RX_FLAT_PREFIX + IntToStrZfill(4, bitmap + 1);
  if TWadRoutines.W_CheckNumForName(name) < 0 then
    result := -1
  else
    result := R_FlatNumForName(name);
end;

//==============================================================================
//
// RA_Sound
// A sound of RADIX.DAT at a place of the map
//
//==============================================================================
procedure RA_Sound(const x, y: fixed_t; const radix_snd: integer);
var
  name: string;
begin
  name := RX_SoundName(radix_snd);
  if name <> '' then
    RX_AmbientSound(x, y, name);
end;

//==============================================================================
//
// RA_SoundRepeat
// The tics before a sound that repeats is played again
//
//==============================================================================
function RA_SoundRepeat(const radix_snd: integer): integer;
begin
  result := RX_SoundDuration(radix_snd);
  if result < 0 then
    result := TRadixActionRules.UNKNOWN_SOUND_REPEAT; // JVAL: 10 seconds to replay sound
end;

//==============================================================================
//
// RA_RandomInRange
// P_RandomInRange of Rad-X
//
//==============================================================================
function RA_RandomInRange(const l, h: integer): integer;
begin
  result := l + round((h - l) / 255 * P_Random);
end;

//==============================================================================
//
// RA_PlayerBlocksSurface
// True when a craft is in the sector and would not fit between fl and cl
//
//==============================================================================
function RA_PlayerBlocksSurface(const sec: Psector_t; const fl, cl: fixed_t): boolean;
var
  i: integer;
  mo: Pmobj_t;
begin
  for i := 0 to MAXPLAYERS - 1 do
    if TGameSession.PlayerInGame[i] then
    begin
      mo := TGameSession.Players[i].mo;
      if mo = nil then
        continue;
      if cl - fl <= mo.height then
        if (Psubsector_t(mo.subsector).sector = sec) or
           (TRendererMain.R_PointInSubsector(mo.x - mo.radius, mo.y - mo.radius).sector = sec) or
           (TRendererMain.R_PointInSubsector(mo.x + mo.radius, mo.y - mo.radius).sector = sec) or
           (TRendererMain.R_PointInSubsector(mo.x + mo.radius, mo.y + mo.radius).sector = sec) or
           (TRendererMain.R_PointInSubsector(mo.x - mo.radius, mo.y + mo.radius).sector = sec) then
        begin
          result := true;
          exit;
        end;
    end;
  result := false;
end;

//==============================================================================
//
// RA_RadixThingAlive
// True when an enemy that the map of RADIX.DAT names with one of the numbers
// (a negative number names none) is still alive
//
//==============================================================================
function RA_RadixThingAlive(const ids: PIntegerArray; const numids: integer): boolean;
var
  think: Pthinker_t;
  mo: Pmobj_t;
  i: integer;
  any: boolean;
begin
  result := false;

  any := false;
  for i := 0 to numids - 1 do
    if ids[i] >= 0 then
      any := true;
  if not any then
    exit;

  think := TTickState.ThinkerCap.next;
  while think <> @TTickState.ThinkerCap do
  begin
    if @think._function.acp1 = @P_MobjThinker then
    begin
      mo := Pmobj_t(think);
      if (mo.tid <> TRadixThingSpawnRules.NO_THING_ID) and (mo.player = nil) then
        if (mo.flags and MF_SHOOTABLE <> 0) and (mo.health > 0) then
          for i := 0 to numids - 1 do
            if (ids[i] >= 0) and (TRadixThingSpawnRules.ThingId(ids[i]) = mo.tid) then
            begin
              result := true;
              exit;
            end;
    end;
    think := think.next;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 0
type
  radixscrollingwall_t = packed record
    wall_number: smallint;
    direction: byte; // Only 0 (right) in radix.dat - Extended to left, up & down
    speed: byte;
  end;
  radixscrollingwall_p = ^radixscrollingwall_t;

//==============================================================================
//
// RA_ScrollingWall
//
//==============================================================================
procedure RA_ScrollingWall(const action: Pradixaction_t);
var
  parms: radixscrollingwall_p;
  s1, s2: Pside_t;
  dx: fixed_t;
begin
  parms := radixscrollingwall_p(@action.params);

  dx := parms.speed * FRACUNIT;
  if dx = 0 then
    exit; // No scroll

  if not RA_LineSides(parms.wall_number, s1, s2) then
    exit;

  // JVAL: 20200307 - Set interpolate flag
  radixwallinfo[parms.wall_number].Flags := radixwallinfo[parms.wall_number].Flags or RWF_FORCEINTERPOLATE;

  case parms.direction of
    0:  // Only 0 in radix.dat v2 remix (right)
      begin
        if s1 <> nil then
          s1.textureoffset := s1.textureoffset - dx;
        if s2 <> nil then
          s2.textureoffset := s2.textureoffset - dx;
      end;
    // JVAL: 20200307 - Let's extend the direction field
    //   1 -> scroll left
    //   2 -> scroll up
    //   3 -> scroll down
    1, 255:  // left
      begin
        if s1 <> nil then
          s1.textureoffset := s1.textureoffset + dx;
        if s2 <> nil then
          s2.textureoffset := s2.textureoffset + dx;
      end;
    2:  // up
      begin
        if s1 <> nil then
          s1.rowoffset := s1.rowoffset + dx;
        if s2 <> nil then
          s2.rowoffset := s2.rowoffset + dx;
      end;
    3:  // down
      begin
        if s1 <> nil then
          s1.rowoffset := s1.rowoffset - dx;
        if s2 <> nil then
          s2.rowoffset := s2.rowoffset - dx;
      end;
  end;
end;

const
  MOVINGSURFACETHRESHHOLD = TRadixActionRules.SURFACE_SPEED_THRESHOLD;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 1
type
  radixmovingsurface_t = packed record
    surface: smallint;
    max_height: smallint;
    min_height: smallint;
    max_delay: smallint;  // JVAL: 20200416 -> 0, 35, 70 in RADIX.DAT
    speed: byte;          // JVAL: 20200416 -> 0, 1, 3, 4, 6, 7, 8, 9, 10 & 12 in RADIX.DAT
    surface_type: byte;   // JVAL: 20200416 -> 0, 1 in RADIX.DAT
    direction: byte;      // JVAL: 20200416 -> 1, 255 in RADIX.DAT
    stop_position: byte;  // JVAL: 20200416 -> 1, 2 in RADIX.DAT
  end;
  radixmovingsurface_p = ^radixmovingsurface_t;

//==============================================================================
//
// RA_MovingSurface
//
//==============================================================================
procedure RA_MovingSurface(const action: Pradixaction_t);
var
  parms: radixmovingsurface_p;
  sec: Psector_t;
  dest_height: fixed_t;
  step: fixed_t;
  finished: boolean;
begin
  parms := radixmovingsurface_p(@action.params);

  if parms.max_delay > 0 then
  begin
    dec(parms.max_delay);
    exit;
  end;

  if not RA_ValidSector(parms.surface) then
    exit;
  sec := @sectors[parms.surface];

  if parms.direction = 1 then // Up
  begin
    dest_height := parms.max_height * FRACUNIT;
    step := TRadixActionRules.SurfaceStep(parms.speed, false) * FRACUNIT;
  end
  else if parms.direction = $FF then // Down
  begin
    dest_height := parms.min_height * FRACUNIT;
    step := -TRadixActionRules.SurfaceStep(parms.speed, false) * FRACUNIT;
  end
  else
    exit; // ouch

  // JVAL: 20200403 - Avoid interpolation for fast moving sectors
  if parms.speed > MOVINGSURFACETHRESHHOLD - 2 then
    sec.renderflags := sec.renderflags or SRF_NO_INTERPOLATE;

  case parms.surface_type of
    1: // floor
      begin
        if step > 0 then
          if RA_PlayerBlocksSurface(sec, sec.floorheight + step, sec.ceilingheight) then
            exit;

        sec.floorheight := sec.floorheight + step;

        if parms.direction = 1 then // Up
          finished := sec.floorheight >= dest_height
        else // if parms.direction = -1 then // Down
          finished := sec.floorheight <= dest_height;
        if finished then
        begin
          sec.floorheight := dest_height;
          action.suspend := 1;  // JVAL: 20200306 - Disable action
        end;
      end;
    0: // ceiling
      begin
        if step < 0 then
          if RA_PlayerBlocksSurface(sec, sec.floorheight, sec.ceilingheight + step) then
            exit;

        sec.ceilingheight := sec.ceilingheight + step;

        if parms.direction = 1 then // Up
          finished := sec.ceilingheight >= dest_height
        else // if parms.direction = -1 then // Down
          finished := sec.ceilingheight <= dest_height;
        if finished then
        begin
          sec.ceilingheight := dest_height;
          action.suspend := 1;  // JVAL: 202003 - Disable action
        end;
      end;
  end;

  P_ChangeSector(sec, true);  // JVAL: 20200313
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 2
type
  radixswitchwallbitmap_t = packed record
    element_number: smallint;
    switch_bitmap: smallint;
    do_floor: smallint;
  end;
  radixswitchwallbitmap_p = ^radixswitchwallbitmap_t;

//==============================================================================
//
// RA_SwitchWallBitmap
//
//==============================================================================
procedure RA_SwitchWallBitmap(const action: Pradixaction_t);
var
  parms: radixswitchwallbitmap_p;
  s1, s2: Pside_t;
  texid: integer;
begin
  parms := radixswitchwallbitmap_p(@action.params);

  action.suspend := 1;

  if not RA_LineSides(parms.element_number, s1, s2) then
    exit;

  texid := RA_WallTexture(parms.switch_bitmap);
  if texid < 0 then
    exit;

  if parms.do_floor = 0 then  // Ceiling or mid
  begin
    if s1 <> nil then
    begin
      if s1.toptexture <> 0 then
        s1.toptexture := texid;
      if s1.midtexture <> 0 then
        s1.midtexture := texid;
    end;
    if s2 <> nil then
    begin
      if s2.toptexture <> 0 then
        s2.toptexture := texid;
      if s2.midtexture <> 0 then
        s2.midtexture := texid;
    end;
  end
  else if parms.do_floor = 256 then  // Floor or mid
  begin
    if s1 <> nil then
    begin
      if s1.bottomtexture <> 0 then
        s1.bottomtexture := texid;
      if s1.midtexture <> 0 then
        s1.midtexture := texid;
    end;
    if s2 <> nil then
    begin
      if s2.bottomtexture <> 0 then
        s2.bottomtexture := texid;
      if s2.midtexture <> 0 then
        s2.midtexture := texid;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 3
type
  radixswitchsecbitmap_t = packed record
    element_number: smallint; // sector id
    switch_bitmap: smallint;
    do_floor: smallint;
  end;
  radixswitchsecbitmap_p = ^radixswitchsecbitmap_t;

//==============================================================================
//
// RA_SwitchSecBitmap
//
//==============================================================================
procedure RA_SwitchSecBitmap(const action: Pradixaction_t);
var
  parms: radixswitchsecbitmap_p;
  texid: integer;
begin
  parms := radixswitchsecbitmap_p(@action.params);

  action.suspend := 1; // Disable action

  if not RA_ValidSector(parms.element_number) then
    exit;

  texid := RA_FlatTexture(parms.switch_bitmap);
  if texid < 0 then
    exit;

  if parms.do_floor = 257 then  // floor texture
    sectors[parms.element_number].floorpic := texid
  else
    sectors[parms.element_number].ceilingpic := texid;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 4 - Not presend in radix.dat
type
  radixtogglewallbitmap_t = packed record
    element_number: smallint;
    switch_bitmap: smallint;
    do_floor: smallint;
    // RTL
    initialize_flag: LongWord;
    new_switch_bitmap_top1: char8_t;
    new_switch_bitmap_mid1: char8_t;
    new_switch_bitmap_bot1: char8_t;
    new_switch_bitmap_top2: char8_t;
    new_switch_bitmap_mid2: char8_t;
    new_switch_bitmap_bot2: char8_t;
  end;
  radixtogglewallbitmap_p = ^radixtogglewallbitmap_t;

//==============================================================================
//
// RA_ToggleWallBitmap
//
//==============================================================================
procedure RA_ToggleWallBitmap(const action: Pradixaction_t);
var
  parms: radixtogglewallbitmap_p;
  s1, s2: Pside_t;
  texid_top1: integer;
  texid_mid1: integer;
  texid_bot1: integer;
  texid_top2: integer;
  texid_mid2: integer;
  texid_bot2: integer;
begin
  parms := radixtogglewallbitmap_p(@action.params);

  action.suspend := 1;

  if not RA_LineSides(parms.element_number, s1, s2) then
    exit;

  if parms.initialize_flag <> ACTION_INITIALIZED then
  begin
    parms.new_switch_bitmap_top1 := TWadRoutines.stringtochar8(RX_WALL_PREFIX + IntToStrZfill(4, parms.switch_bitmap + 1));
    parms.new_switch_bitmap_bot1 := parms.new_switch_bitmap_top1;
    parms.new_switch_bitmap_mid1 := parms.new_switch_bitmap_top1;
    parms.new_switch_bitmap_top2 := parms.new_switch_bitmap_top1;
    parms.new_switch_bitmap_bot2 := parms.new_switch_bitmap_top1;
    parms.new_switch_bitmap_mid2 := parms.new_switch_bitmap_top1;
    parms.initialize_flag := ACTION_INITIALIZED;
  end;

  texid_top1 := R_SafeTextureNumForName(TWadRoutines.char8tostring(parms.new_switch_bitmap_top1));
  texid_mid1 := R_SafeTextureNumForName(TWadRoutines.char8tostring(parms.new_switch_bitmap_mid1));
  texid_bot1 := R_SafeTextureNumForName(TWadRoutines.char8tostring(parms.new_switch_bitmap_bot1));
  texid_top2 := R_SafeTextureNumForName(TWadRoutines.char8tostring(parms.new_switch_bitmap_top2));
  texid_mid2 := R_SafeTextureNumForName(TWadRoutines.char8tostring(parms.new_switch_bitmap_mid2));
  texid_bot2 := R_SafeTextureNumForName(TWadRoutines.char8tostring(parms.new_switch_bitmap_bot2));

  if s1 <> nil then
  begin
    parms.new_switch_bitmap_top1 := R_NameForSideTexture(s1.toptexture);
    parms.new_switch_bitmap_bot1 := R_NameForSideTexture(s1.bottomtexture);
    parms.new_switch_bitmap_mid1 := R_NameForSideTexture(s1.midtexture);
  end
  else
  begin
    parms.new_switch_bitmap_top1 := TWadRoutines.stringtochar8('-');
    parms.new_switch_bitmap_bot1 := TWadRoutines.stringtochar8('-');
    parms.new_switch_bitmap_mid1 := TWadRoutines.stringtochar8('-');
  end;

  if s2 <> nil then
  begin
    parms.new_switch_bitmap_top2 := R_NameForSideTexture(s2.toptexture);
    parms.new_switch_bitmap_bot2 := R_NameForSideTexture(s2.bottomtexture);
    parms.new_switch_bitmap_mid2 := R_NameForSideTexture(s2.midtexture);
  end
  else
  begin
    parms.new_switch_bitmap_top2 := TWadRoutines.stringtochar8('-');
    parms.new_switch_bitmap_bot2 := TWadRoutines.stringtochar8('-');
    parms.new_switch_bitmap_mid2 := TWadRoutines.stringtochar8('-');
  end;

  if parms.do_floor = 0 then  // Ceiling or mid
  begin
    if s1 <> nil then
    begin
      if s1.toptexture <> 0 then
        s1.toptexture := texid_top1;
      if s1.midtexture <> 0 then
        s1.midtexture := texid_mid1;
    end;
    if s2 <> nil then
    begin
      if s2.toptexture <> 0 then
        s2.toptexture := texid_top2;
      if s2.midtexture <> 0 then
        s2.midtexture := texid_mid2;
    end;
  end
  else if parms.do_floor = 256 then  // Floor or mid
  begin
    if s1 <> nil then
    begin
      if s1.bottomtexture <> 0 then
        s1.bottomtexture := texid_bot1;
      if s1.midtexture <> 0 then
        s1.midtexture := texid_mid1;
    end;
    if s2 <> nil then
    begin
      if s2.bottomtexture <> 0 then
        s2.bottomtexture := texid_bot2;
      if s2.midtexture <> 0 then
        s2.midtexture := texid_mid2;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 5 - Not presend in radix.dat
type
  radixtongglesecbitmap_t = packed record
    element_number: smallint; // sector id
    switch_bitmap: smallint;
    do_floor: smallint;
    // RTL
    initialize_flag: LongWord;
    new_switch_bitmap: integer;
  end;
  radixtongglesecbitmap_p = ^radixtongglesecbitmap_t;

//==============================================================================
//
// RA_ToggleSecBitmap
//
//==============================================================================
procedure RA_ToggleSecBitmap(const action: Pradixaction_t);
var
  parms: radixtongglesecbitmap_p;
  texid: integer;
begin
  parms := radixtongglesecbitmap_p(@action.params);

  action.suspend := 1; // Disable action

  if not RA_ValidSector(parms.element_number) then
    exit;

  if parms.initialize_flag <> ACTION_INITIALIZED then
  begin
    parms.new_switch_bitmap := RA_FlatTexture(parms.switch_bitmap);
    parms.initialize_flag := ACTION_INITIALIZED;
  end;

  texid := parms.new_switch_bitmap;
  if texid < 0 then
    exit;

  if parms.do_floor = 257 then  // floor texture
  begin
    parms.new_switch_bitmap := sectors[parms.element_number].floorpic;
    sectors[parms.element_number].floorpic := texid;
  end
  else
  begin
    parms.new_switch_bitmap := sectors[parms.element_number].ceilingpic;
    sectors[parms.element_number].ceilingpic := texid;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 6
type
  radixcirclebitmap_t = packed record
    max_delay: integer;
    bitmap_1: smallint;
    bitmap_2: smallint;
    bitmap_3: smallint;
    // RTL params here
    calced: boolean;
    flat_1: integer;
    flat_2: integer;
    flat_3: integer;
    texture_1: integer;
    texture_2: integer;
    texture_3: integer;
    tick: integer;
  end;
  radixcirclebitmap_p = ^radixcirclebitmap_t;

//==============================================================================
//
// RA_CircleBitmap
//
//==============================================================================
procedure RA_CircleBitmap(const action: Pradixaction_t);
var
  parms: radixcirclebitmap_p;
  flat: integer;
  texture: integer;
begin
  parms := radixcirclebitmap_p(@action.params);

  if parms.max_delay <= 0 then
    exit;

  if not parms.calced then
  begin
    parms.flat_1 := RA_FlatTexture(parms.bitmap_1);
    parms.flat_2 := RA_FlatTexture(parms.bitmap_2);
    parms.flat_3 := RA_FlatTexture(parms.bitmap_3);
    parms.texture_1 := RA_WallTexture(parms.bitmap_1);
    parms.texture_2 := RA_WallTexture(parms.bitmap_2);
    parms.texture_3 := RA_WallTexture(parms.bitmap_3);
    parms.calced := true;
    parms.tick := 0;
  end;

  if parms.tick = 0 then
    parms.tick := 3 * parms.max_delay;

  dec(parms.tick);
  case parms.tick div parms.max_delay of
    0:
      begin
        flat := parms.flat_1;
        texture := parms.texture_1;
      end;
    1:
      begin
        flat := parms.flat_2;
        texture := parms.texture_2;
      end;
  else
    begin
      flat := parms.flat_3;
      texture := parms.texture_3;
    end;
  end;

  if (parms.flat_1 >= 0) and (flat >= 0) then
    flats[parms.flat_1].translation := flat;
  if (parms.texture_1 >= 0) and (texture >= 0) then
    texturetranslation[parms.texture_1] := texture;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 7
type
  radixlightflicker_t = packed record
    off_delay: smallint;
    on_delay: integer;
    off_light_level: smallint;  // 0-63
    on_light_level: smallint; // 0-63
    sector: smallint;
    // RTL
    countdown: integer;
    oncountdown: boolean;
  end;
  radixlightflicker_p = ^radixlightflicker_t;

//==============================================================================
//
// RA_LightFlicker
//
//==============================================================================
procedure RA_LightFlicker(const action: Pradixaction_t);
var
  parms: radixlightflicker_p;
begin
  parms := radixlightflicker_p(@action.params);

  if parms.countdown > 0 then
  begin
    dec(parms.countdown);
    exit;
  end;

  if parms.oncountdown then
  begin
    RX_SetSectorLight(parms.sector, parms.on_light_level);
    parms.countdown := parms.on_delay;
  end
  else
  begin
    RX_SetSectorLight(parms.sector, parms.off_light_level);
    parms.countdown := parms.off_delay;
  end;

  parms.oncountdown := not parms.oncountdown;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 8
type
  radixlightsoff_t = packed record
    foo1, foo2, foo3: smallint;
    off_light_level: integer; // 0-63
    sector: smallint;
  end;
  radixlightsoff_p = ^radixlightsoff_t;

//==============================================================================
//
// RA_LightsOff
//
//==============================================================================
procedure RA_LightsOff(const action: Pradixaction_t);
var
  parms: radixlightsoff_p;
begin
  parms := radixlightsoff_p(@action.params);

  RX_SetSectorLight(parms.sector, parms.off_light_level);

  action.suspend := 1; // Disable action
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 9
type
  radixlightson_t = packed record
    foo1, foo2, foo3, foo4: smallint; // Always 0 inside radix.dat
    on_light_level: smallint; // 0-63
    sector: smallint;
  end;
  radixlightson_p = ^radixlightson_t;

//==============================================================================
//
// RA_LightsOn
//
//==============================================================================
procedure RA_LightsOn(const action: Pradixaction_t);
var
  parms: radixlightson_p;
begin
  parms := radixlightson_p(@action.params);

  RX_SetSectorLight(parms.sector, parms.on_light_level);

  action.suspend := 1; // Disable action
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 10
type
  radixlightoscilate_t = packed record
    max_light: smallint; // JVAL: Values > 63 in radix.dat (fog ?)
    min_light: smallint; // JVAL: Values > 63 in radix.dat (fog ?)
    direction: smallint;
    speed: smallint;
    sector: smallint;
    // RTL
    curlevel: integer;
  end;
  radixlightoscilate_p = ^radixlightoscilate_t;

//==============================================================================
//
// RA_LightOscilate
//
//==============================================================================
procedure RA_LightOscilate(const action: Pradixaction_t);
var
  parms: radixlightoscilate_p;
  rising: boolean;
begin
  parms := radixlightoscilate_p(@action.params);

  rising := parms.direction = 0;
  parms.curlevel := TRadixActionRules.Oscillate(parms.curlevel, parms.min_light, parms.max_light, rising);
  if rising then
    parms.direction := 0
  else
    parms.direction := 1;

  RX_SetSectorLight(parms.sector, parms.curlevel);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 11
type
  radixplaneteleport_t = packed record
    new_angle: smallint; // 0-256
    new_x: integer;
    new_y: integer;
    change_height: byte;
    new_height: smallint;
    change_speed: byte;
    new_speed:  smallint;
    new_height_angle: smallint; // 0-256
    delay: smallint;
  end;
  radixplaneteleport_p = ^radixplaneteleport_t;

//==============================================================================
//
// RA_PlaneTeleport
// Missing from Rad-X: new_speed and new_height_angle were not used there either
//
//==============================================================================
procedure RA_PlaneTeleport(const action: Pradixaction_t);
var
  parms: radixplaneteleport_p;
  p: Pplayer_t;
  x, y: fixed_t;
  s, c: fixed_t;
  momx, momy: fixed_t;
  angle: angle_t;
  deltaviewheight: integer;
begin
  parms := radixplaneteleport_p(@action.params);

  if parms.delay > 0 then
  begin
    dec(parms.delay);
    exit;
  end;

  p := @TGameSession.Players[radixplayer];
  if p.mo = nil then
    exit;

  x := RX_RadixX2Doom(parms.new_x, parms.new_y) * FRACUNIT;
  y := RX_RadixY2Doom(parms.new_x, parms.new_y) * FRACUNIT;

  // Momentum of thing crossing teleporter linedef
  momx := p.mo.momx;
  momy := p.mo.momy;

  // JVAL: 20200504 - Disappear teleport fog
  RX_SpawnTeleportForceField(p.mo);

  if not P_TeleportMove(p.mo, x, y) then
    exit;

  angle := LongWord(parms.new_angle) * (ANGLE_MAX div 256);

  // Sine, cosine of angle adjustment
  s := finesine[angle shr ANGLETOFINESHIFT];
  c := finecosine[angle shr ANGLETOFINESHIFT];

  if parms.change_height <> 0 then
    p.mo.z := parms.new_height * FRACUNIT;

  if p.mo.z < p.mo.floorz then
    p.mo.z := p.mo.floorz
  else if p.mo.z > p.mo.ceilingz - p.mo.height then
    p.mo.z := p.mo.ceilingz - p.mo.height;

  p.mo.angle := angle;

  // Rotate thing's momentum to come out of exit just like it entered
  p.mo.momx := FixedMul(momx, c) - FixedMul(momy, s);
  p.mo.momy := FixedMul(momy, c) + FixedMul(momx, s);

  // Save the current deltaviewheight, used in stepping
  deltaviewheight := p.deltaviewheight;

  // Clear deltaviewheight, since we don't want any changes
  p.deltaviewheight := 0;

  // Set player's view according to the newly set parameters
  P_CalcHeight(p);

  // Reset the delta to have the same dynamics as before
  p.deltaviewheight := deltaviewheight;

  p.mo.reactiontime := 18;
  p.teleporttics := TELEPORTZOOM;

  // JVAL: 20200504 - Reappear teleport fog
  RX_SpawnTeleportForceField(p.mo);

  action.suspend := 1;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 12 (forcefield)
type
  radixplanetranspo_t = packed record
    target_x: integer;
    target_y: integer;
    target_height: smallint; // can be negative ?
    approx_start_x: integer;
    approx_start_y: integer;
    approx_start_height: integer; // can be negative ?
    tick_count: smallint;
    line_angle: word;
  end;
  radixplanetranspo_p = ^radixplanetranspo_t;

//==============================================================================
//
// RA_PlaneTranspo
// The craft is carried by RX_PlaneTranspoMove (radix_logic) in the next tics.
// Missing from Rad-X: the pilot keeps the controls of the view, P_MovePlayer
// is not stopped (its thrust is replaced every tic by the one of the transporter)
//
//==============================================================================
procedure RA_PlaneTranspo(const action: Pradixaction_t);
var
  parms: radixplanetranspo_p;
  p: Pplayer_t;
  lp: Pradixlevelplayer_t;
begin
  parms := radixplanetranspo_p(@action.params);

  action.suspend := 1;

  p := @TGameSession.Players[radixplayer];
  lp := @radixlevelplayers[radixplayer];
  if p.mo = nil then
    exit;

  if lp.planetranspo_tics > 0 then
    exit; // Already transported

  if parms.tick_count <= 0 then
    exit;

  lp.planetranspo_start_x := p.mo.x;
  lp.planetranspo_start_y := p.mo.y;
  lp.planetranspo_start_z := p.mo.z;
  lp.planetranspo_start_a := p.mo.angle;
  lp.planetranspo_target_x := RX_RadixX2Doom(parms.target_x, parms.target_y) * FRACUNIT;
  lp.planetranspo_target_y := RX_RadixY2Doom(parms.target_x, parms.target_y) * FRACUNIT;
  lp.planetranspo_target_z := parms.target_height * FRACUNIT;
  lp.planetranspo_target_a := LongWord(parms.line_angle) * (ANGLE_MAX div 256);
  lp.planetranspo_start_tics := parms.tick_count;
  lp.planetranspo_tics := parms.tick_count;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 13
type
  radixnewmovingsurface_t = packed record
    surface: smallint;
    max_height: smallint;
    min_height: smallint;
    max_delay: integer;
    speed: byte;
    surface_type: byte; // 1-> floor, 0-> ceiling
    direction: byte;  // 1-> up, 0-> delayed, -1($FF) -> down
    stop_position: byte; // 0-> no stop, 1-> maxstop, 2-> minstop, 3-> allstop
    approx_x: integer;
    approx_y: integer;
    start_sound: smallint;
    stop_sound: smallint;
    activate_trig: smallint;
    trigger_number: smallint;
    // RTL
    sound_initialized: boolean;
    delay_saved: boolean;
    save_delay: integer;
    dir_initialized: boolean;
    initial_direction: byte;
  end;
  radixnewmovingsurface_p = ^radixnewmovingsurface_t;

//==============================================================================
//
// RA_NewMovingSurface
//
//==============================================================================
procedure RA_NewMovingSurface(const action: Pradixaction_t);
var
  parms: radixnewmovingsurface_p;
  sec: Psector_t;
  dest_height: fixed_t;
  step: fixed_t;
  finished: boolean;
  changed_direction: boolean;

  // After finishing checks if need to change direction
  procedure finishcheck;
  begin
    // JVAL: 20200405
    //  If "direction" is Up (1) and "stop position" is Min (2)
    //  We continue changing movement down
    if (parms.direction = 1) and (parms.stop_position = 2) then
    begin
      changed_direction := true;
      parms.direction := $FF;
      parms.stop_position := 1;
    end
    // JVAL: 20200405
    //  If "direction" is Down ($FF) and "stop position" is Max (1)
    //  We continue changing movement up
    else if (parms.direction = $FF) and (parms.stop_position = 1) then
    begin
      changed_direction := true;
      parms.direction := 1;
      parms.stop_position := 2;
    end;
  end;

begin
  parms := radixnewmovingsurface_p(@action.params);

  if not parms.delay_saved then
  begin
    parms.save_delay := parms.max_delay;
    parms.delay_saved := true;
  end;

  if parms.max_delay > 0 then
  begin
    dec(parms.max_delay);
    exit;
  end;

  if not RA_ValidSector(parms.surface) then
  begin
    action.suspend := 1;
    exit;
  end;
  sec := @sectors[parms.surface];

  if not parms.sound_initialized then
  begin
    RA_Sound(sec.soundorg.x, sec.soundorg.y, parms.start_sound);
    parms.sound_initialized := true;
  end;

  if not parms.dir_initialized then
  begin
    parms.initial_direction := parms.direction;
    parms.dir_initialized := true;
  end;

  if parms.direction = 1 then // Up
  begin
    dest_height := parms.max_height * FRACUNIT;
    step := TRadixActionRules.SurfaceStep(parms.speed, true) * FRACUNIT;
  end
  else if (parms.direction = $FF) or ((parms.direction = 0) and (parms.stop_position = 2)) then // Down
  begin
    dest_height := parms.min_height * FRACUNIT;
    step := -TRadixActionRules.SurfaceStep(parms.speed, true) * FRACUNIT;
  end
  else if parms.direction = 0 then
  begin
    if parms.surface_type = 1 then // floor
    begin
      parms.direction := $FF; // Down
      parms.stop_position := 1;
    end
    else
    begin
      parms.direction := 1; // Up
      parms.stop_position := 2;
    end;
    exit; // ouch
  end
  else
    exit;

  changed_direction := false;

  // JVAL: 20200403 - Avoid interpolation for fast moving sectors
  if parms.speed > MOVINGSURFACETHRESHHOLD div 2 then
    sec.renderflags := sec.renderflags or SRF_NO_INTERPOLATE;

  finished := false;
  case parms.surface_type of
    1: // floor
      begin
        if step > 0 then
          if RA_PlayerBlocksSurface(sec, sec.floorheight + step, sec.ceilingheight) then
            exit;

        sec.floorheight := sec.floorheight + step;

        if parms.direction = 1 then // Up
          finished := sec.floorheight >= dest_height
        else // if parms.direction = -1 then // Down
          finished := sec.floorheight <= dest_height;
        if finished then
        begin
          sec.floorheight := dest_height;
          finishcheck;
        end;
      end;
    0: // ceiling
      begin
        if step < 0 then
          if RA_PlayerBlocksSurface(sec, sec.floorheight, sec.ceilingheight + step) then
            exit;

        sec.ceilingheight := sec.ceilingheight + step;

        if parms.direction = 1 then // Up
          finished := sec.ceilingheight >= dest_height
        else // if parms.direction = -1 then // Down
          finished := sec.ceilingheight <= dest_height;
        if finished then
        begin
          sec.ceilingheight := dest_height;
          finishcheck;
        end;
      end;
  end;

  P_ChangeSector(sec, true);  // JVAL: 20200313

  if not finished then
    exit;

  RA_Sound(sec.soundorg.x, sec.soundorg.y, parms.stop_sound);
  parms.sound_initialized := false;

  if not changed_direction then
    action.suspend := 1  // JVAL: 202003 - Disable action
  else if (parms.initial_direction = parms.direction) and (parms.stop_position in [1, 2]) then
    action.suspend := 1;

  parms.max_delay := parms.save_delay;  // JVAL: 20200405 - Restore old delay

  if parms.activate_trig <> 0 then
    RX_ActivateAndRunTrigger(parms.trigger_number);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 14
type
  radixplaysound_t = packed record
    sound_number: smallint; // Values 17 - 31
    repeating: smallint;
    x_pos: integer;
    y_pos: integer;
    // RTL
    doom_x: fixed_t;
    doom_y: fixed_t;
    countdown: integer;
    calced: boolean;
  end;
  radixplaysound_p = ^radixplaysound_t;

//==============================================================================
//
// RA_PlaySound
//
//==============================================================================
procedure RA_PlaySound(const action: Pradixaction_t);
var
  parms: radixplaysound_p;
begin
  parms := radixplaysound_p(@action.params);

  if parms.countdown > 0 then
  begin
    dec(parms.countdown);
    exit;
  end;

  if not parms.calced then
  begin
    parms.doom_x := RX_RadixX2Doom(parms.x_pos, parms.y_pos) * FRACUNIT;
    parms.doom_y := RX_RadixY2Doom(parms.x_pos, parms.y_pos) * FRACUNIT;
    parms.calced := true;
  end;

  RA_Sound(parms.doom_x, parms.doom_y, parms.sound_number);

  if parms.repeating = 0 then
    action.suspend := 1
  else
    parms.countdown := RA_SoundRepeat(parms.sound_number); // JVAL: 20200312 - Restart sound after it finishes
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 15
type
  radixrandlightsflicker_t = packed record
    off_countdown: smallint;  // RTL
    on_countdown: smallint;   // RTL
    off_min_delay: smallint;
    off_max_delay: smallint;
    on_min_delay: smallint;
    on_max_delay: smallint;
    on_off: smallint;         // RTL
    off_light_level: smallint;
    on_light_level: smallint;
    sector: smallint;
  end;
  radixrandlightsflicker_p = ^radixrandlightsflicker_t;

//==============================================================================
//
// RA_RandLightsFlicker
//
//==============================================================================
procedure RA_RandLightsFlicker(const action: Pradixaction_t);
var
  parms: radixrandlightsflicker_p;
begin
  parms := radixrandlightsflicker_p(@action.params);

  if parms.on_off = 0 then
  begin
    if parms.off_countdown <= 0 then
    begin
      RX_SetSectorLight(parms.sector, parms.on_light_level);
      parms.on_countdown := RA_RandomInRange(parms.on_min_delay, parms.on_max_delay);
      parms.on_off := 1;
    end
    else
      dec(parms.off_countdown);
  end
  else
  begin
    if parms.on_countdown <= 0 then
    begin
      RX_SetSectorLight(parms.sector, parms.off_light_level);
      parms.off_countdown := RA_RandomInRange(parms.off_min_delay, parms.off_max_delay);
      parms.on_off := 0;
    end
    else
      dec(parms.on_countdown);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 16
type
  radixendoflevel_t = packed record
    // return_value = -1 -> End of episode
    // return_value = 9 -> End level, go to secret level (E?M9)
    // return_value = 0 -> End level, go to next level
    // return_value <> 0 -> End secret level, go to next level normal (non secret) level
    return_value: smallint;
    foo1, foo2, foo3: smallint; // the rest of the parameters of RADIX.DAT (0, 257, 0)
    // RTL
    initialized: boolean;
    tics: integer;
  end;
  radixendoflevel_p = ^radixendoflevel_t;

//==============================================================================
//
// RA_EndOfLevel
//
//==============================================================================
procedure RA_EndOfLevel(const action: Pradixaction_t);
var
  parms: radixendoflevel_p;
  mo: Pmobj_t;
begin
  parms := radixendoflevel_p(@action.params);

  if not parms.initialized then
  begin
    parms.tics := RX_SoundDuration(TRadixMessages.SOUND_END_OF_LEVEL) + 1;
    mo := TGameSession.Players[radixplayer].mo;
    if mo <> nil then
      RA_Sound(mo.x, mo.y, TRadixMessages.SOUND_END_OF_LEVEL);
    parms.initialized := true;
    exit;
  end;

  if parms.tics > 0 then
  begin
    dec(parms.tics);
    exit;
  end;

  action.suspend := 1; // the level ends once
  RX_ExitLevel(parms.return_value);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 17
type
  radixspritetriggeractivate_t = packed record
    trigger_number: integer;
    the_sprites: packed array[0..4] of integer; // JVAL: 20200310 - sprite in editor
  end;
  radixspritetriggeractivate_p = ^radixspritetriggeractivate_t;

//==============================================================================
//
// RA_SpriteTriggerActivate
//
//==============================================================================
procedure RA_SpriteTriggerActivate(const action: Pradixaction_t);
var
  parms: radixspritetriggeractivate_p;
begin
  parms := radixspritetriggeractivate_p(@action.params);

  if RA_RadixThingAlive(@parms.the_sprites, 5) then
    exit;

  RX_ActivateAndRunTrigger(parms.trigger_number);

  action.suspend := 1;  // JVAL: 20200411 - Disable action
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 18
type
  radixsectorbasedgravity_t = packed record
    direction: smallint; // 1/-1 inside radix.dat
    strength: smallint; // from 0 to 3 inside radix.dat
    sector_id: smallint;
    approx_x: integer;
    approx_y: integer;
    // RTL
    doom_x: fixed_t;
    doom_y: fixed_t;
    sndcountdown: integer;
    sndcalced: boolean;
  end;
  radixsectorbasedgravity_p = ^radixsectorbasedgravity_t;

//==============================================================================
//
// RA_SectorBasedGravity
//
//==============================================================================
procedure RA_SectorBasedGravity(const action: Pradixaction_t);
var
  parms: radixsectorbasedgravity_p;
  i: integer;
  mo: Pmobj_t;
begin
  parms := radixsectorbasedgravity_p(@action.params);

  for i := 0 to MAXPLAYERS - 1 do
    if TGameSession.PlayerInGame[i] then
    begin
      mo := TGameSession.Players[i].mo;
      if mo <> nil then
        if RX_SectorIndex(Psubsector_t(mo.subsector).sector) = parms.sector_id then
          mo.momz := TRadixActionRules.GravityMomentum(mo.momz, parms.direction, parms.strength);
    end;

  if not parms.sndcalced then
  begin
    parms.doom_x := RX_RadixX2Doom(parms.approx_x, parms.approx_y) * FRACUNIT;
    parms.doom_y := RX_RadixY2Doom(parms.approx_x, parms.approx_y) * FRACUNIT;
    parms.sndcalced := true;
  end;

  if parms.sndcountdown > 0 then
  begin
    dec(parms.sndcountdown);
    exit;
  end;

  RA_Sound(parms.doom_x, parms.doom_y, TRadixMessages.SOUND_GRAVITY_WELL);

  parms.sndcountdown := RA_SoundRepeat(TRadixMessages.SOUND_GRAVITY_WELL); // JVAL: 20200415 - Restart sound after it finishes
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 19
type
  radixdeactivatetrigger_t = packed record
    trigger: byte;
  end;
  radixdeactivatetrigger_p = ^radixdeactivatetrigger_t;

//==============================================================================
//
// RA_DeactivateTrigger
//
//==============================================================================
procedure RA_DeactivateTrigger(const action: Pradixaction_t);
var
  parms: radixdeactivatetrigger_p;
begin
  parms := radixdeactivatetrigger_p(@action.params);

  radixlogic.DeactivateTrigger(parms.trigger);

  action.suspend := 1;  // JVAL: 202003 - Disable action
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 20
type
  radixactivatetrigger_t = packed record
    trigger: byte;
  end;
  radixactivatetrigger_p = ^radixactivatetrigger_t;

//==============================================================================
//
// RA_ActivateTrigger
//
//==============================================================================
procedure RA_ActivateTrigger(const action: Pradixaction_t);
var
  parms: radixactivatetrigger_p;
begin
  parms := radixactivatetrigger_p(@action.params);

  radixlogic.ActivateTrigger(parms.trigger);

  action.suspend := 1;  // JVAL: 202003 - Disable action
end;

const
  WALLMISSILEOFFSET = 16;

////////////////////////////////////////////////////////////////////////////////
// Sprite types = 21, 24, 25, 30: the walls that fire missiles
type
  radixmissilewall_t = packed record
    wall_number: smallint;
    //RTL
    initialized: boolean;
    mobjid: LongWord;
    linelength: integer;
    baseangle: angle_t;
    nextticfire: integer;
    destheight: fixed_t;  // only the floor and the ceiling walls (24, 25)
  end;
  radixmissilewall_p = ^radixmissilewall_t;

var
  wallmissile_id: integer = -1;
  radixenemymissile_id: integer = -1;
  radixenemyseekermissile_id: integer = -1;

//==============================================================================
//
// RA_SwapDeadWallTexture
//
//==============================================================================
procedure RA_SwapDeadWallTexture(var texture: smallint);
var
  alive, dead: integer;
begin
  alive := R_CheckTextureNumForName(RX_WALL_PREFIX + RX_MISSILEWALL_BITMAP);
  dead := R_CheckTextureNumForName(RX_WALL_PREFIX + RX_DEADMISSILEWALL_BITMAP);
  if (alive >= 0) and (dead >= 0) and (texture = alive) then
    texture := dead;
end;

//==============================================================================
//
// RA_InitMissileWall
// The target of the missiles of a wall: an object in the middle of it
//
//==============================================================================
procedure RA_InitMissileWall(const parms: radixmissilewall_p; const li: Pline_t);
var
  target: Pmobj_t;
begin
  if wallmissile_id < 0 then
    wallmissile_id := Info_GetMobjNumForName('MT_MISSILEWALL');
  parms.mobjid := 0;
  if wallmissile_id >= 0 then
  begin
    target :=
      P_SpawnMobj(
        li.v1.x div 2 + li.v2.x div 2,
        li.v1.y div 2 + li.v2.y div 2,
        li.frontsector.ceilingheight div 2 + li.frontsector.floorheight div 2,
        wallmissile_id
      );
    parms.mobjid := target.key;
  end;
  parms.linelength := round(RX_LineLengthf(li));
  parms.baseangle := TRendererMain.R_PointToAngle2(li.v1.x, li.v1.y, li.v2.x, li.v2.y) - ANG90;
  parms.nextticfire := -1;
  parms.initialized := true;
end;

//==============================================================================
//
// RA_FireWallMissile
// A missile from a random place of the wall, between the heights z1 and z2
// (zlen: the height in pieces of 64 units)
//
//==============================================================================
procedure RA_FireWallMissile(const parms: radixmissilewall_p; const li: Pline_t;
  const z1, z2: fixed_t; const zlen: integer; const seeker: boolean);
var
  x, y, z: integer;
  xlen: integer;
  xpos, zpos: integer;
  an: angle_t;
  c, s: fixed_t;
  mo: Pmobj_t;
  missile_id: integer;
begin
  if seeker then
  begin
    if radixenemyseekermissile_id < 0 then
      radixenemyseekermissile_id := Info_GetMobjNumForName('MT_ENEMYSEEKERMISSILE');
    missile_id := radixenemyseekermissile_id;
  end
  else
  begin
    if radixenemymissile_id < 0 then
      radixenemymissile_id := Info_GetMobjNumForName('MT_ENEMYMISSILE');
    missile_id := radixenemymissile_id;
  end;
  if missile_id < 0 then
    exit; // the actors of Radix are not loaded

  xlen := (parms.linelength + 64) div 128;

  if xlen = 0 then
  begin
    x := li.v1.x div 2 + li.v2.x div 2;
    y := li.v1.y div 2 + li.v2.y div 2;
  end
  else
  begin
    xpos := Sys_Random mod xlen;
    x := round((li.v1.x div xlen) * (xpos + 0.5) + (li.v2.x div xlen) * (xlen - xpos - 0.5));
    y := round((li.v1.y div xlen) * (xpos + 0.5) + (li.v2.y div xlen) * (xlen - xpos - 0.5));
  end;

  if zlen = 0 then
    z := z1 div 2 + z2 div 2
  else
  begin
    zpos := Sys_Random mod zlen;
    z := round((z1 div zlen) * (zpos + 0.5) + (z2 div zlen) * (zlen - zpos - 0.5));
  end;

  an := parms.baseangle + _SHLW(P_Random - P_Random, 21);
  c := finecosine[an shr ANGLETOFINESHIFT];
  s := finesine[an shr ANGLETOFINESHIFT];
  x := x + WALLMISSILEOFFSET * c;
  y := y + WALLMISSILEOFFSET * s;

  mo := P_SpawnMobj(x, y, z, missile_id);
  if mo = nil then
    exit;

  mo.angle := an;
  if parms.mobjid <> 0 then
    mo.target := P_FindMobjFromKey(parms.mobjid);
  mo.momx := FixedMul(mo.info.speed, c);
  mo.momy := FixedMul(mo.info.speed, s);
  P_CheckMissileSpawn(mo);
end;

//==============================================================================
//
// RA_DoCompleteMissileWall
// A one sided wall that fires from its whole height (types 21 and 30)
//
//==============================================================================
procedure RA_DoCompleteMissileWall(const action: Pradixaction_t; const seeker: boolean);
var
  parms: radixmissilewall_p;
  li: Pline_t;
  zlen: integer;
begin
  parms := radixmissilewall_p(@action.params);

  if not RX_ValidLine(parms.wall_number) then
    exit;

  li := @lines[parms.wall_number];
  if (li.backsector <> nil) or (li.frontsector = nil) or (li.sidenum[0] < 0) then
    exit;

  if RX_LineHitPoints(parms.wall_number) <= 0 then  // Died
  begin
    RA_SwapDeadWallTexture(sides[li.sidenum[0]].midtexture);
    action.suspend := 1;
    exit;
  end;

  if not parms.initialized then
    RA_InitMissileWall(parms, li);

  if TTickState.LevelTime < parms.nextticfire then
    exit;
  parms.nextticfire := TTickState.LevelTime + TICRATE;

  zlen := (li.frontsector.ceilingheight div FRACUNIT - li.frontsector.floorheight div FRACUNIT + 32) div 64;
  RA_FireWallMissile(parms, li, li.frontsector.ceilingheight, li.frontsector.floorheight, zlen, seeker);
end;

//==============================================================================
//
// RA_CompleteMissileWall
// Sprite type = 21
//
//==============================================================================
procedure RA_CompleteMissileWall(const action: Pradixaction_t);
begin
  RA_DoCompleteMissileWall(action, false);
end;

//==============================================================================
//
// RA_SeekCompleteMissileWall
// Sprite type = 30
//
//==============================================================================
procedure RA_SeekCompleteMissileWall(const action: Pradixaction_t);
begin
  RA_DoCompleteMissileWall(action, true);
end;

//==============================================================================
//
// RA_FloorMissileWall
// Sprite type = 24
//
//==============================================================================
procedure RA_FloorMissileWall(const action: Pradixaction_t);
var
  parms: radixmissilewall_p;
  li: Pline_t;
  zlen: integer;
begin
  parms := radixmissilewall_p(@action.params);

  if not RX_ValidLine(parms.wall_number) then
    exit;

  li := @lines[parms.wall_number];
  if (li.backsector = nil) or (li.frontsector = nil) or (li.sidenum[0] < 0) or (li.sidenum[1] < 0) then
    exit;

  if RX_LineHitPoints(parms.wall_number) <= 0 then  // Died
  begin
    RA_SwapDeadWallTexture(sides[li.sidenum[0]].bottomtexture);
    RA_SwapDeadWallTexture(sides[li.sidenum[1]].bottomtexture);
    action.suspend := 1;
    exit;
  end;

  if not parms.initialized then
  begin
    RA_InitMissileWall(parms, li);
    parms.destheight := li.backsector.ceilingheight;
  end;

  // JVAL: 20200413 - Raise backsector's floor
  if li.backsector.floorheight < parms.destheight then
  begin
    li.backsector.floorheight := li.backsector.floorheight + 2 * FRACUNIT;
    if li.backsector.floorheight > parms.destheight then
      li.backsector.floorheight := parms.destheight;
  end;

  if TTickState.LevelTime < parms.nextticfire then
    exit;
  parms.nextticfire := TTickState.LevelTime + TICRATE;

  if li.frontsector.floorheight > li.backsector.floorheight then
    zlen := (li.frontsector.floorheight div FRACUNIT - li.backsector.floorheight div FRACUNIT + 32) div 64  // back side
  else
    zlen := (li.backsector.floorheight div FRACUNIT - li.frontsector.floorheight div FRACUNIT + 32) div 64; // front side
  if zlen = 0 then
    exit;

  RA_FireWallMissile(parms, li, li.frontsector.floorheight, li.backsector.floorheight, zlen, false);
end;

//==============================================================================
//
// RA_CeilingMissileWall
// Sprite type = 25
//
//==============================================================================
procedure RA_CeilingMissileWall(const action: Pradixaction_t);
var
  parms: radixmissilewall_p;
  li: Pline_t;
  zlen: integer;
begin
  parms := radixmissilewall_p(@action.params);

  if not RX_ValidLine(parms.wall_number) then
    exit;

  li := @lines[parms.wall_number];
  if (li.backsector = nil) or (li.frontsector = nil) or (li.sidenum[0] < 0) or (li.sidenum[1] < 0) then
    exit;

  if RX_LineHitPoints(parms.wall_number) <= 0 then  // Died
  begin
    RA_SwapDeadWallTexture(sides[li.sidenum[0]].toptexture);
    RA_SwapDeadWallTexture(sides[li.sidenum[1]].toptexture);
    action.suspend := 1;
    exit;
  end;

  if not parms.initialized then
  begin
    RA_InitMissileWall(parms, li);
    parms.destheight := li.backsector.floorheight;
  end;

  // JVAL: 20200414 - Lower backsector's ceiling
  if li.backsector.ceilingheight > parms.destheight then
  begin
    li.backsector.ceilingheight := li.backsector.ceilingheight - 2 * FRACUNIT;
    if li.backsector.ceilingheight < parms.destheight then
      li.backsector.ceilingheight := parms.destheight;
  end;

  if TTickState.LevelTime < parms.nextticfire then
    exit;
  parms.nextticfire := TTickState.LevelTime + TICRATE;

  if li.frontsector.ceilingheight > li.backsector.ceilingheight then
    zlen := (li.frontsector.ceilingheight div FRACUNIT - li.backsector.ceilingheight div FRACUNIT + 32) div 64  // front side
  else
    zlen := (li.backsector.ceilingheight div FRACUNIT - li.frontsector.ceilingheight div FRACUNIT + 32) div 64; // back side
  if zlen = 0 then
    exit;

  RA_FireWallMissile(parms, li, li.frontsector.ceilingheight, li.backsector.ceilingheight, zlen, false);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 22
type
  radixscannerjam_t = packed record
    on_off: smallint; // 1-> jam radar, 0-> enable radar
  end;
  radixscannerjam_p = ^radixscannerjam_t;

//==============================================================================
//
// RA_ScannerJam
//
//==============================================================================
procedure RA_ScannerJam(const action: Pradixaction_t);
var
  parms: radixscannerjam_p;
begin
  parms := radixscannerjam_p(@action.params);

  RX_PlayerState(@TGameSession.Players[radixplayer]).scannerjam := parms.on_off = 1;
end;

//==============================================================================
//
// RA_MessageSound
// The voice of a message, not before the one of the last time has finished
//
//==============================================================================
procedure RA_MessageSound(const msgid: integer; var nextsoundtime: integer);
var
  snd: integer;
  name: string;
begin
  if TTickState.LevelTime < nextsoundtime then
    exit;

  snd := TRadixMessages.Get(msgid).Sound;
  if snd >= 0 then
  begin
    name := RX_SoundName(snd);
    if (name <> '') and (TGameSession.Players[radixplayer].mo <> nil) then
      TSoundRoutines.S_StartSound(RX_PilotMessageOrigin(radixplayer, @TGameSession.Players[radixplayer]), name);
  end;
  nextsoundtime := TTickState.LevelTime + RX_SoundDuration(snd) + 1;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 23
type
  radixprintmessage_t = packed record
    message_id: integer; // id's 0-12
    // RTL
    nextsoundtime: integer;
    initialized: boolean;
    playcount: integer;
  end;
  radixprintmessage_p = ^radixprintmessage_t;

//==============================================================================
//
// RA_PrintMessage
//
//==============================================================================
procedure RA_PrintMessage(const action: Pradixaction_t);
var
  parms: radixprintmessage_p;
begin
  parms := radixprintmessage_p(@action.params);

  if not parms.initialized then
  begin
    parms.nextsoundtime := -1;
    parms.initialized := true;
    parms.playcount := 0;
  end;

  if TRadixMessages.IsMessage(parms.message_id) then
    if not TRadixMessages.Get(parms.message_id).AutoDisable or (parms.playcount = 0) then  // Avoid repeating some messages
      if RX_PlayerMessage(@TGameSession.Players[radixplayer], parms.message_id) then
      begin
        inc(parms.playcount);
        RA_MessageSound(parms.message_id, parms.nextsoundtime);
      end;

  action.suspend := 1;  // JVAL: 20200306 - Disable action
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 26
type
  radixbigspritetrig_t = packed record
    trigger_number: integer;
    the_sprites: packed array[0..19] of integer; // Negative do not count
  end;
  radixbigspritetrig_p = ^radixbigspritetrig_t;

//==============================================================================
//
// RA_BigSpriteTrig
//
//==============================================================================
procedure RA_BigSpriteTrig(const action: Pradixaction_t);
var
  parms: radixbigspritetrig_p;
begin
  parms := radixbigspritetrig_p(@action.params);

  if RA_RadixThingAlive(@parms.the_sprites, 20) then
    exit;

  RX_ActivateAndRunTrigger(parms.trigger_number);

  action.suspend := 1; // JVAL: 20200315 - Disable action
end;

//==============================================================================
//
// RA_SpawnExplosions
// cnt big explosions around a point (x1, y1, z1), not farther than three times
// radious_one_third on each axis; the last one is returned in x, y, z
//
//==============================================================================
procedure RA_SpawnExplosions(const x1, y1, z1: fixed_t; const radious_one_third: integer;
  const cnt: integer; out x, y, z: fixed_t);
var
  i: integer;
  rnd: integer;
begin
  x := x1;
  y := y1;
  z := z1;
  for i := 0 to cnt - 1 do
  begin
    rnd := P_Random - P_Random;
    x := x1 + (2 * rnd * radious_one_third) * (FRACUNIT div 256);
    rnd := P_Random - P_Random;
    y := y1 + (2 * rnd * radious_one_third) * (FRACUNIT div 256);
    rnd := P_Random - P_Random;
    z := z1 + (2 * rnd * radious_one_third) * (FRACUNIT div 256);
    RX_SpawnRadixBigExplosion(x, y, z);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 27
type
  radixmassiveexplosion_t = packed record
    number_of_explosions: integer;
    x_coord: integer;
    y_coord: integer;
    height: integer;
    delta_x: integer;
    delta_y: integer;
    delay_length: integer;
    radious_one_third: integer;
    number_of_bitmaps_per: smallint;
    // RTL
    delay_cnt: integer;
  end;
  radixmassiveexplosion_p = ^radixmassiveexplosion_t;

//==============================================================================
//
// RA_MassiveExplosion
//
//==============================================================================
procedure RA_MassiveExplosion(const action: Pradixaction_t);
var
  parms: radixmassiveexplosion_p;
  x, y, z: fixed_t;
  x1, y1, z1: fixed_t;
begin
  parms := radixmassiveexplosion_p(@action.params);

  if parms.number_of_explosions <= 0 then
  begin
    action.suspend := 1;
    exit;
  end;

  if parms.delay_cnt <= 0 then
  begin
    x1 := RX_RadixX2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    y1 := RX_RadixY2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    z1 := parms.height * FRACUNIT;
    RA_SpawnExplosions(x1, y1, z1, parms.radious_one_third, parms.number_of_bitmaps_per, x, y, z);
    if parms.number_of_explosions and 1 <> 0 then // JVAL: 20200506 - Do not bottleneck sound system
      RX_AmbientSound(x1, y1, 'radix/SndExplode');
    parms.x_coord := parms.x_coord + parms.delta_x;
    parms.y_coord := parms.y_coord + parms.delta_y;
    parms.delay_cnt := parms.delay_length;
    dec(parms.number_of_explosions);
  end
  else
    dec(parms.delay_cnt);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 28
type
  radixwalldeadcheck_t = packed record
    trigger: integer;
    the_walls: packed array[0..4] of integer; // Wall values can be negative
  end;
  radixwalldeadcheck_p = ^radixwalldeadcheck_t;

//==============================================================================
//
// RA_WallDeadCheck
//
//==============================================================================
procedure RA_WallDeadCheck(const action: Pradixaction_t);
var
  parms: radixwalldeadcheck_p;
  i: integer;
  w: integer;
begin
  parms := radixwalldeadcheck_p(@action.params);

  for i := 0 to 4 do
  begin
    w := parms.the_walls[i];
    if w >= 0 then
      if RX_LineHitPoints(w) > 0 then
        exit;
  end;

  RX_ActivateAndRunTrigger(parms.trigger);
  action.suspend := 1;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 29
type
  radixsecondaryobjective_t = packed record
    return_value: integer;
    foo1, foo2: smallint; // the rest of the parameters of RADIX.DAT (257, 0)
    // RTL
    nextsoundtime: integer;
    initialized: boolean;
  end;
  radixsecondaryobjective_p = ^radixsecondaryobjective_t;

//==============================================================================
//
// RA_SecondaryObjective
//
//==============================================================================
procedure RA_SecondaryObjective(const action: Pradixaction_t);
var
  parms: radixsecondaryobjective_p;
begin
  parms := radixsecondaryobjective_p(@action.params);

  if not parms.initialized then
  begin
    parms.nextsoundtime := -1;
    parms.initialized := true;
  end;

  radixlevelplayers[radixplayer].secondaryobjective := true;
  if RX_PlayerMessage(@TGameSession.Players[radixplayer], TRadixMessages.SECONDARY_OBJECTIVE_COMPLETED) then
    RA_MessageSound(TRadixMessages.SECONDARY_OBJECTIVE_COMPLETED, parms.nextsoundtime);

  action.suspend := 1; // Disable action;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 31
type
  radixspritelightmovement_t = packed record
    on_level: smallint;   // light level from 0 to 63
    off_level: smallint;  // light level from 0 to 63
    delay: smallint;
    the_sectors: packed array[0..3] of smallint;  // Sector can be -1
    // RTL
    tick: integer;
  end;
  radixspritelightmovement_p = ^radixspritelightmovement_t;

//==============================================================================
//
// RA_LightMovement
// The light goes from one of the four sectors to the next
//
//==============================================================================
procedure RA_LightMovement(const action: Pradixaction_t);
var
  parms: radixspritelightmovement_p;
  i: integer;
  lit: integer;
begin
  parms := radixspritelightmovement_p(@action.params);

  if parms.delay <= 0 then
    exit;

  if parms.tick = 0 then
    parms.tick := 4 * parms.delay;

  dec(parms.tick);

  lit := parms.tick div parms.delay;
  for i := 0 to 3 do
    if parms.the_sectors[i] >= 0 then
    begin
      if i = lit then
        RX_SetSectorLight(parms.the_sectors[i], parms.on_level)
      else
        RX_SetSectorLight(parms.the_sectors[i], parms.off_level);
    end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 32
type
  radixmultlightoscilate_t = packed record
    max_light: smallint; // light level from 0 to 63, grater values mask to sector color ?
    min_light: smallint; // light level from 0 to 63
    direction: smallint;
    speed: smallint;
    the_sectors: packed array[0..29] of smallint; // Negative values (-1) means no sector
    // RTL
    curlevel: integer;
  end;
  radixmultlightoscilate_p = ^radixmultlightoscilate_t;

//==============================================================================
//
// RA_MultLightOscilate
//
//==============================================================================
procedure RA_MultLightOscilate(const action: Pradixaction_t);
var
  parms: radixmultlightoscilate_p;
  i: integer;
  rising: boolean;
begin
  parms := radixmultlightoscilate_p(@action.params);

  rising := parms.direction = 0;
  parms.curlevel := TRadixActionRules.Oscillate(parms.curlevel, parms.min_light, parms.max_light, rising);
  if rising then
    parms.direction := 0
  else
    parms.direction := 1;

  for i := 0 to 29 do
    if parms.the_sectors[i] >= 0 then
      RX_SetSectorLight(parms.the_sectors[i], parms.curlevel);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 33
type
  radixmultrandlightsinfo_t = packed record
    off_light_level: smallint; // Range is 0-63
    on_light_level: smallint; // Range is 0-63
    sector: smallint; // Sector value can be negative (-1)
  end;

  radixmultrandlightsflicker_t = packed record
    foo: LongWord;
    off_min_delay: smallint;
    off_max_delay: smallint;
    on_min_delay: smallint;
    on_max_delay: integer;
    info: packed array[0..4] of radixmultrandlightsinfo_t;
    // RTL
    on_off: byte;
    off_countdown: integer;
    on_countdown: integer;
  end;
  radixmultrandlightsflicker_p = ^radixmultrandlightsflicker_t;

//==============================================================================
//
// RA_MultRandLightsFlicker
//
//==============================================================================
procedure RA_MultRandLightsFlicker(const action: Pradixaction_t);
var
  parms: radixmultrandlightsflicker_p;
  i: integer;
begin
  parms := radixmultrandlightsflicker_p(@action.params);

  if parms.on_off = 0 then
  begin
    if parms.off_countdown <= 0 then
    begin
      for i := 0 to 4 do
        if parms.info[i].sector >= 0 then
          RX_SetSectorLight(parms.info[i].sector, parms.info[i].on_light_level);
      parms.on_countdown := RA_RandomInRange(parms.on_min_delay, parms.on_max_delay);
      parms.on_off := 1;
    end
    else
      dec(parms.off_countdown);
  end
  else
  begin
    if parms.on_countdown <= 0 then
    begin
      for i := 0 to 4 do
        if parms.info[i].sector >= 0 then
          RX_SetSectorLight(parms.info[i].sector, parms.info[i].off_light_level);
      parms.off_countdown := RA_RandomInRange(parms.off_min_delay, parms.off_max_delay);
      parms.on_off := 0;
    end
    else
      dec(parms.on_countdown);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 34
type
  radixkillratio_t = packed record
    trigger_number: integer;
    percentage: smallint;
  end;
  radixkillratio_p = ^radixkillratio_t;

//==============================================================================
//
// RA_KillRatio
//
//==============================================================================
procedure RA_KillRatio(const action: Pradixaction_t);
var
  parms: radixkillratio_p;
  runtrigger: boolean;
  mo: Pmobj_t;
  think: Pthinker_t;
  living: integer;
begin
  parms := radixkillratio_p(@action.params);

  runtrigger := TRadixActionRules.KillRatioReached(totalradixkills, P_World.Totals.Kills,
    TGameSession.Players[radixplayer].killcount, parms.percentage);

  if not runtrigger and (TTickState.LevelTime and 31 = 0) then
  begin
    // JVAL: 20200429 - To compensate for dead enemies that the player didn't kill (count living radix map enemies)
    living := 0;
    think := TTickState.ThinkerCap.next;
    while think <> @TTickState.ThinkerCap do
    begin
      if @think._function.acp1 = @P_MobjThinker then
      begin
        mo := Pmobj_t(think);
        if (mo.flags and MF_COUNTKILL <> 0) and (mo.health > 0) and (mo.player = nil) then
          if mo.tid <> TRadixThingSpawnRules.NO_THING_ID then
            inc(living);
      end;
      think := think.next;
    end;
    runtrigger := TRadixActionRules.KillRatioReachedByLiving(totalradixkills, living, P_World.Totals.Kills,
      parms.percentage);
  end;

  if runtrigger then
  begin
    RX_ActivateAndRunTrigger(parms.trigger_number);
    action.suspend := 1; // JVAL: 20200414 - Disable action
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 35
type
  radixhurtplayerexplosion_t = packed record
    hit_points_at_center: integer;
    number_of_explosions: integer;
    x_coord: integer;
    y_coord: integer;
    height: integer;
    delta_x: integer;
    delta_y: integer;
    delay_length: integer;
    radious_one_third: integer;
    // RTL
    delay_cnt: integer;
  end;
  radixhurtplayerexplosion_p = ^radixhurtplayerexplosion_t;

//==============================================================================
//
// RA_HurtPlayerExplosion
//
//==============================================================================
procedure RA_HurtPlayerExplosion(const action: Pradixaction_t);
var
  parms: radixhurtplayerexplosion_p;
  x, y, z: fixed_t;
  x1, y1, z1: fixed_t;
  mo: Pmobj_t;
  i: integer;
  dist, maxdist: fixed_t;
  damage: integer;
  max_radius: integer;
begin
  parms := radixhurtplayerexplosion_p(@action.params);

  if parms.number_of_explosions <= 0 then
  begin
    action.suspend := 1;
    exit;
  end;

  if parms.delay_cnt <= 0 then
  begin
    x1 := RX_RadixX2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    y1 := RX_RadixY2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    z1 := parms.height * FRACUNIT;
    RA_SpawnExplosions(x1, y1, z1, parms.radious_one_third, 1, x, y, z);
    parms.x_coord := parms.x_coord + parms.delta_x;
    parms.y_coord := parms.y_coord + parms.delta_y;
    parms.delay_cnt := parms.delay_length;
    dec(parms.number_of_explosions);

    max_radius := parms.radious_one_third * 3;
    for i := 0 to MAXPLAYERS - 1 do
      if TGameSession.PlayerInGame[i] then
      begin
        mo := TGameSession.Players[i].mo;
        if mo <> nil then
        begin
          maxdist := 0;
          dist := abs(x - mo.x);
          if dist > maxdist then
            maxdist := dist;
          dist := abs(y - mo.y);
          if dist > maxdist then
            maxdist := dist;
          dist := abs(z - mo.z);
          if dist > maxdist then
            maxdist := dist;
          damage := TRadixActionRules.ExplosionDamage(parms.hit_points_at_center, PLAYERSPAWNSHIELD,
            max_radius, maxdist div FRACUNIT);
          if damage > 0 then
            P_DamageMobj(mo, nil, nil, damage);
        end;
      end;
  end
  else
    dec(parms.delay_cnt);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 36
type
  radixswitchshadetype_t = packed record
    sector_id: smallint;
    new_light_level: smallint; // Can be > 63, first 6 bits (0-63) is lightlevel, bits 7 & 8 are shade type?
  end;
  radixswitchshadetype_p = ^radixswitchshadetype_t;

//==============================================================================
//
// RA_SwitchShadeType
//
//==============================================================================
procedure RA_SwitchShadeType(const action: Pradixaction_t);
var
  parms: radixswitchshadetype_p;
begin
  parms := radixswitchshadetype_p(@action.params);

  RX_SetSectorLight(parms.sector_id, parms.new_light_level);

  action.suspend := 1;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 37
type
  radix6lightmovement_t = packed record
    on_level: smallint; // 0-63
    off_level: smallint;  // 0-63
    delay: smallint; // 1-20 in radix.dat v2
    the_sectors: packed array[0..11] of smallint; // -1 -> no sector
    // RTL
    currid: integer;
    countdown: integer;
    initialized: boolean;
  end;
  radix6lightmovement_p = ^radix6lightmovement_t;

//==============================================================================
//
// RA_SixLightMovement
// As in Rad-X the delay of RADIX.DAT is not used: the light moves every tic
//
//==============================================================================
procedure RA_SixLightMovement(const action: Pradixaction_t);
var
  parms: radix6lightmovement_p;
  i: integer;
  secid: integer;
begin
  parms := radix6lightmovement_p(@action.params);

  if not parms.initialized then
  begin
    parms.currid := -1;
    parms.initialized := true;
  end;

  if parms.countdown > 0 then
  begin
    dec(parms.countdown);
    exit;
  end;

  inc(parms.currid);
  if (parms.currid < 0) or (parms.currid >= 12) then
    parms.currid := 0
  else if parms.the_sectors[parms.currid] = -1 then
    parms.currid := 0;

  for i := 0 to 11 do
  begin
    secid := parms.the_sectors[i];
    if secid >= 0 then
    begin
      if i = parms.currid then
        RX_SetSectorLight(secid, parms.on_level)
      else
        RX_SetSectorLight(secid, parms.off_level);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 38
type
  radixsurfacepowerup_t = packed record
    sector_id: smallint;
    armour_inc: smallint;
    shield_inc: smallint;
    energy_inc: smallint;
  end;
  radixsurfacepowerup_p = ^radixsurfacepowerup_t;

//==============================================================================
//
// RA_SurfacePowerUp
// A craft in the sector gets armour, shield and energy every eight tics. The
// shield of the craft is the health of the player of Doom and of its body
//
//==============================================================================
procedure RA_SurfacePowerUp(const action: Pradixaction_t);
var
  parms: radixsurfacepowerup_p;
  i: integer;
  p: Pplayer_t;
  rp: Pradixplayer_t;
  limits: TRadixPilotLimits;
begin
  parms := radixsurfacepowerup_p(@action.params);

  if TTickState.LevelTime and 7 <> 0 then
    exit;

  limits := TRadixPilotLimits.Default;
  for i := 0 to MAXPLAYERS - 1 do
    if TGameSession.PlayerInGame[i] and (TGameSession.Players[i].mo <> nil) then
    begin
      p := @TGameSession.Players[i];
      if p.playerstate <> PST_LIVE then
        continue;
      if RX_SectorIndex(Psubsector_t(p.mo.subsector).sector) <> parms.sector_id then
        continue;
      rp := RX_PlayerState(p);
      p.armorpoints := GetIntegerInRange(p.armorpoints + parms.armour_inc, 0, limits.MaxArmor);
      p.health := GetIntegerInRange(p.health + parms.shield_inc, 0, PLAYERMAXSHIELD);
      if p.health < 1 then
        p.health := 1; // the surface does not kill: the old code left a craft with no shield alive
      p.mo.health := p.health;
      rp.energy := GetIntegerInRange(rp.energy + parms.energy_inc, 0, limits.MaxEnergy);
    end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 39
type
  radixsecretsprite_t = packed record
    the_sectors: packed array[0..14] of smallint; // Sector value can be -1
  end;
  radixsecretsprite_p = ^radixsecretsprite_t;

//==============================================================================
//
// RA_SecretSprite
//
//==============================================================================
procedure RA_SecretSprite(const action: Pradixaction_t);
var
  parms: radixsecretsprite_p;
  i: integer;
  secid: integer;
begin
  parms := radixsecretsprite_p(@action.params);

  for i := 0 to 14 do
  begin
    secid := parms.the_sectors[i];
    if RA_ValidSector(secid) then
      if sectors[secid].special and SECRET_MASK = 0 then
      begin
        sectors[secid].special := sectors[secid].special or SECRET_MASK; // JVAL: 20200311 -> Use BOOM generalized type
        P_World.Totals.CountSecret;
      end;
  end;

  action.suspend := 1;
end;

//==============================================================================
//
// RA_BossEyeHandler
// Sprite type 40: nothing in Rad-X either (the wall of the eye of the boss)
//
//==============================================================================
procedure RA_BossEyeHandler(const action: Pradixaction_t);
begin
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 41
type
  radixvertexplosion_t = packed record
    number_of_explosions: integer;
    x_coord: integer;
    y_coord: integer;
    height: integer;
    delta_x: integer;
    delta_y: integer;
    delta_height: integer;
    delay_length: integer; // Value 2-3 inside dat files
    radious_one_third: integer;
    number_of_bitmaps_per: smallint;
    // RTL
    delay_cnt: integer;
  end;
  radixvertexplosion_p = ^radixvertexplosion_t;

//==============================================================================
//
// RA_VertExplosion
//
//==============================================================================
procedure RA_VertExplosion(const action: Pradixaction_t);
var
  parms: radixvertexplosion_p;
  x, y, z: fixed_t;
  x1, y1, z1: fixed_t;
begin
  parms := radixvertexplosion_p(@action.params);

  if parms.number_of_explosions <= 0 then
  begin
    action.suspend := 1;
    exit;
  end;

  if parms.delay_cnt <= 0 then
  begin
    x1 := RX_RadixX2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    y1 := RX_RadixY2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    z1 := parms.height * FRACUNIT;
    RA_SpawnExplosions(x1, y1, z1, parms.radious_one_third, parms.number_of_bitmaps_per, x, y, z);
    if parms.number_of_explosions and 1 <> 0 then // JVAL: 20200506 - Do not bottleneck sound system
      RX_AmbientSound(x1, y1, 'radix/SndExplode');
    parms.x_coord := parms.x_coord + parms.delta_x;
    parms.y_coord := parms.y_coord + parms.delta_y;
    parms.height := parms.height + parms.delta_height;
    parms.delay_cnt := parms.delay_length;
    dec(parms.number_of_explosions);
  end
  else
    dec(parms.delay_cnt);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 42
type
  radixchangeflooroffsets_t = packed record
    sector: smallint;
    x_offs: smallint;
    y_offs: smallint;
  end;
  radixchangeflooroffsets_p = ^radixchangeflooroffsets_t;

//==============================================================================
//
// RA_ChangeFloorOffsets
//
//==============================================================================
procedure RA_ChangeFloorOffsets(const action: Pradixaction_t);
var
  parms: radixchangeflooroffsets_p;
  sec: Psector_t;
begin
  parms := radixchangeflooroffsets_p(@action.params);

  if not RA_ValidSector(parms.sector) then
    exit;

  sec := @sectors[parms.sector];
  sec.floor_xoffs := sec.floor_xoffs + parms.x_offs * FRACUNIT;
  sec.floor_yoffs := sec.floor_yoffs + parms.y_offs * FRACUNIT;
end;

const
  MASSIVELIGHTSECTORS = 41;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 43
type
  radixmassivelightmovement_t = packed record
    on_light_level: smallint;
    off_light_level: smallint;
    speed: smallint;
    the_sectors: packed array[0..MASSIVELIGHTSECTORS - 1] of smallint;  // Sector can be -1
    //RTL
    currsectoridx: integer;
    countdown: integer;
  end;
  radixmassivelightmovement_p = ^radixmassivelightmovement_t;

//==============================================================================
//
// RA_MassiveLightMovement
//
//==============================================================================
procedure RA_MassiveLightMovement(const action: Pradixaction_t);
var
  parms: radixmassivelightmovement_p;
  i: integer;
  secid: integer;
begin
  parms := radixmassivelightmovement_p(@action.params);

  if parms.countdown <= 0 then
    parms.countdown := parms.speed;

  dec(parms.countdown);
  if parms.countdown <= 0 then
  begin
    for i := 0 to MASSIVELIGHTSECTORS - 1 do
    begin
      secid := parms.the_sectors[i];
      if secid >= 0 then
      begin
        if i = parms.currsectoridx then
          RX_SetSectorLight(secid, parms.on_light_level)
        else
          RX_SetSectorLight(secid, parms.off_light_level);
      end;
    end;
    inc(parms.currsectoridx);
    if (parms.currsectoridx < 0) or (parms.currsectoridx >= MASSIVELIGHTSECTORS) then
      parms.currsectoridx := 0
    else if parms.the_sectors[parms.currsectoridx] < 0 then
      parms.currsectoridx := 0;
  end;
end;

//==============================================================================
//
// RX_RunAction
//
//==============================================================================
procedure RX_RunAction(const action: Pradixaction_t);
begin
  case action.ActionType of
    RADIX_ACTION_SCROLLING_WALL: RA_ScrollingWall(action);
    RADIX_ACTION_MOVING_SURFACE: RA_MovingSurface(action);
    RADIX_ACTION_SWITCH_WALL_BITMAP: RA_SwitchWallBitmap(action);
    RADIX_ACTION_SWITCH_SECTOR_BITMAP: RA_SwitchSecBitmap(action);
    RADIX_ACTION_TOGGLE_WALL_BITMAP: RA_ToggleWallBitmap(action);
    RADIX_ACTION_TOGGLE_SECTOR_BITMAP: RA_ToggleSecBitmap(action);
    RADIX_ACTION_CIRCLE_BITMAP: RA_CircleBitmap(action);
    RADIX_ACTION_LIGHT_FLICKER: RA_LightFlicker(action);
    RADIX_ACTION_LIGHTS_OFF: RA_LightsOff(action);
    RADIX_ACTION_LIGHTS_ON: RA_LightsOn(action);
    RADIX_ACTION_LIGHT_OSCILLATE: RA_LightOscilate(action);
    RADIX_ACTION_PLANE_TELEPORT: RA_PlaneTeleport(action);
    RADIX_ACTION_PLANE_TRANSPO: RA_PlaneTranspo(action);
    RADIX_ACTION_NEW_MOVING_SURFACE: RA_NewMovingSurface(action);
    RADIX_ACTION_PLAY_SOUND: RA_PlaySound(action);
    RADIX_ACTION_RANDOM_LIGHTS_FLICKER: RA_RandLightsFlicker(action);
    RADIX_ACTION_END_OF_LEVEL: RA_EndOfLevel(action);
    RADIX_ACTION_SPRITE_TRIGGER_ACTIVATE: RA_SpriteTriggerActivate(action);
    RADIX_ACTION_SECTOR_BASED_GRAVITY: RA_SectorBasedGravity(action);
    RADIX_ACTION_DEACTIVATE_TRIGGER: RA_DeactivateTrigger(action);
    RADIX_ACTION_ACTIVATE_TRIGGER: RA_ActivateTrigger(action);
    RADIX_ACTION_COMPLETE_MISSILE_WALL: RA_CompleteMissileWall(action);
    RADIX_ACTION_SCANNER_JAM: RA_ScannerJam(action);
    RADIX_ACTION_PRINT_MESSAGE: RA_PrintMessage(action);
    RADIX_ACTION_FLOOR_MISSILE_WALL: RA_FloorMissileWall(action);
    RADIX_ACTION_CEILING_MISSILE_WALL: RA_CeilingMissileWall(action);
    RADIX_ACTION_BIG_SPRITE_TRIGGER: RA_BigSpriteTrig(action);
    RADIX_ACTION_MASSIVE_EXPLOSION: RA_MassiveExplosion(action);
    RADIX_ACTION_WALL_DEAD_CHECK: RA_WallDeadCheck(action);
    RADIX_ACTION_SECONDARY_OBJECTIVE: RA_SecondaryObjective(action);
    RADIX_ACTION_SEEK_COMPLETE_MISSILE_WALL: RA_SeekCompleteMissileWall(action);
    RADIX_ACTION_LIGHT_MOVEMENT: RA_LightMovement(action);
    RADIX_ACTION_MULTIPLE_LIGHT_OSCILLATE: RA_MultLightOscilate(action);
    RADIX_ACTION_MULTIPLE_RANDOM_LIGHTS_FLICKER: RA_MultRandLightsFlicker(action);
    RADIX_ACTION_KILL_RATIO: RA_KillRatio(action);
    RADIX_ACTION_HURT_PLAYER_EXPLOSION: RA_HurtPlayerExplosion(action);
    RADIX_ACTION_SWITCH_SHADE_TYPE: RA_SwitchShadeType(action);
    RADIX_ACTION_SIX_LIGHT_MOVEMENT: RA_SixLightMovement(action);
    RADIX_ACTION_SURFACE_POWER_UP: RA_SurfacePowerUp(action);
    RADIX_ACTION_SECRET_SPRITE: RA_SecretSprite(action);
    RADIX_ACTION_BOSS_EYE_HANDLER: RA_BossEyeHandler(action);
    RADIX_ACTION_VERTICAL_EXPLOSION: RA_VertExplosion(action);
    RADIX_ACTION_CHANGE_FLOOR_OFFSETS: RA_ChangeFloorOffsets(action);
    RADIX_ACTION_MASSIVE_LIGHT_MOVEMENT: RA_MassiveLightMovement(action);
  end;
end;

end.
