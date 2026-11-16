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
//  DESCRIPTION:  none
//   Implements special effects:
//   Texture animation, height or lighting changes
//    according to adjacent sectors, respective
//    utility functions, etc.
//   Line Tag handling. Line and Sector triggers.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.World.SpecRules;

interface

uses
  doomdef,
  m_fixed,
  d_player,
  d_think,
  p_mobj_h,
  r_defs,
  p_spec_h;

//==============================================================================
// P_InitPicAnims
//
// at game start
//
//==============================================================================
procedure P_InitPicAnims;

//==============================================================================
// P_SpawnSpecials
//
// at map load
//
//==============================================================================
procedure P_SpawnSpecials;

//==============================================================================
// P_UpdateSpecials
//
// every tic
//
//==============================================================================
procedure P_UpdateSpecials;

//==============================================================================
//
// P_InitLava
//
//==============================================================================
procedure P_InitLava;

//==============================================================================
// P_ShootSpecialLine
//
// when needed
//
//==============================================================================
procedure P_ShootSpecialLine(thing: Pmobj_t; line: Pline_t);

//==============================================================================
//
// P_CrossSpecialLine
//
//==============================================================================
procedure P_CrossSpecialLine(linenum: integer; side: integer; thing: Pmobj_t);

//==============================================================================
//
// P_CrossSpecialLinePtr
//
//==============================================================================
procedure P_CrossSpecialLinePtr(line: Pline_t; side: integer; thing: Pmobj_t);

//==============================================================================
//
// P_PlayerInSpecialSector
//
//==============================================================================
procedure P_PlayerInSpecialSector(player: Pplayer_t; const sector: Psector_t; const height: fixed_t);  // JVAL: 3d Floors

//==============================================================================
//
// getSector
//
//==============================================================================
function getSector(currentSector: integer; line: integer; side: integer): Psector_t;

//==============================================================================
// EV_DoDonut
//
// SPECIAL
//
//==============================================================================
function EV_DoDonut(line: Pline_t): integer;

type
  /// <summary>
  ///   What Heretic does differently in the sector utilities of IdTech1\Base\p_spec.pas (issue #185, step 2g)
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TSpecGameRules = class sealed
  public
    /// <summary>The line is two-sided when ML_TWOSIDED is set (otherwise when it has a second side)</summary>
    class function TwoSidedByFlag: boolean; static;
    /// <summary>getNextSector works as in the original game: no neighbour through a one-sided line</summary>
    class function NextSectorCompatible: boolean; static;
    /// <summary>The height where P_FindHighestFloorSurrounding starts from</summary>
    class function HighestFloorStart: fixed_t; static;
    /// <summary>The height where P_FindLowestCeilingSurrounding starts from</summary>
    class function LowestCeilingStart: fixed_t; static;
    /// <summary>The height where P_FindHighestCeilingSurrounding starts from</summary>
    class function HighestCeilingStart: fixed_t; static;
    /// <summary>How many adjoining sectors P_FindNextHighestFloor accepts</summary>
    class function AdjoiningSectorsLimit: integer; static;
    /// <summary>The tag of the sectors that the line refers to (Hexen: the first argument of the special)</summary>
    class function LineSectorTag(line: Pline_t): integer; static;
    /// <summary>The special that a sector keeps once a light thinker has been spawned on it</summary>
    class function SectorSpecialAfterLight(special: integer): integer; static;
    /// <summary>A light thinker is already running on the sector</summary>
    class function LightingBusy(sec: Psector_t): boolean; static;
  end;

implementation

uses
  p_spec,
  d_delphi,
  doomdata,
  h_strings,
  i_system,
  z_zone,
  m_argv,
  w_wad,
  r_data,
  r_main,
  r_ripple,
  info_h,
  g_game,
  p_setup,
  p_inter,
  DelphiDoom.Engine.World.SwitchRules,
  p_switch,
  p_ceilng,
  p_plats,
  p_lights,
  p_doors,
  p_mobj,
  p_user,
  p_floor,
  p_telept,
  p_common,
  p_tick,
  p_udmf,
  udmf_ceilng,
  udmf_plats,
  udmf_lights,
  udmf_spec,
  tables,
  s_sound,
// Data.
  sounddata;

//
// Animating textures and planes
//
type
  anim_t = record
    istexture: boolean;
    picnum: integer;
    basepic: integer;
    numpics: integer;
    speed: integer;
  end;
  Panim_t = ^anim_t;
  anim_tArray = array[0..$FFFF] of anim_t;
  Panim_tArray = ^anim_tArray;

//
//      source animation definition
//
  animdef_t = record
    istexture: boolean; // if false, it is a flat
    endname: string[8];
    startname: string[8];
    speed: integer;
  end;
  Panimdef_t = ^animdef_t;
  animdef_tArray = array[0..$FFFF] of animdef_t;
  Panimdef_tArray = ^animdef_tArray;

const
  MAXANIMS = 32;
  NUMANIMDEFS = 8;

//
// P_InitPicAnims
//

// Floor/ceiling animation sequences,
//  defined by first and last frame,
//  i.e. the flat (64x64 tile) name to
//  be used.
// The full animation sequence is given
//  using all the flats between the start
//  and end entry, in the order found in
//  the WAD file.
//
  animdefs: array[0..NUMANIMDEFS] of animdef_t = (
    // Heretic animations
    (istexture: false; endname: 'FLTWAWA3'; startname: 'FLTWAWA1'; speed: 8), // Water
    (istexture: false; endname: 'FLTSLUD3'; startname: 'FLTSLUD1'; speed: 8), // Sludge
    (istexture: false; endname: 'FLTTELE4'; startname: 'FLTTELE1'; speed: 6), // Teleport
    (istexture: false; endname: 'FLTFLWW3'; startname: 'FLTFLWW1'; speed: 9), // River - West
    (istexture: false; endname: 'FLTLAVA4'; startname: 'FLTLAVA1'; speed: 8), // Lava
    (istexture: false; endname: 'FLATHUH4'; startname: 'FLATHUH1'; speed: 8), // Super Lava
    (istexture: true;  endname: 'LAVAFL3';  startname: 'LAVAFL1';  speed: 6), // Texture: Lavaflow
    (istexture: true;  endname: 'WATRWAL3'; startname: 'WATRWAL1'; speed: 4), // Texture: Waterfall

    (istexture: false; endname: '';         startname: '';         speed: 0)
  );

var
  anims: array[0..MAXANIMS - 1] of anim_t;
  lastanim: integer;

const
//
//      Animating line specials
//
  MAXLINEANIMS = 1024; // JVAL Originally was 64

//==============================================================================
//
// P_InitPicAnims
//
//==============================================================================
procedure P_InitPicAnims;
var
  i, j: integer;
begin
  //  Init animation
  lastanim := 0;
  i := 0;
  while animdefs[i].speed <> 0 do
  begin
    if animdefs[i].istexture then
    begin
      // different episode ?
      if R_CheckTextureNumForName(animdefs[i].startname) = -1 then
      begin
        inc(i);
        continue;
      end;

      anims[lastanim].picnum := R_TextureNumForName(animdefs[i].endname);
      anims[lastanim].basepic := R_TextureNumForName(animdefs[i].startname);
      anims[lastanim].istexture := true;
      anims[lastanim].numpics := anims[lastanim].picnum - anims[lastanim].basepic + 1;
    end
    else
    begin
      if W_CheckNumForName(animdefs[i].startname) = -1 then
      begin
        inc(i);
        continue;
      end;

      anims[lastanim].picnum := R_FlatNumForName(animdefs[i].endname);
      anims[lastanim].basepic := R_FlatNumForName(animdefs[i].startname);
      anims[lastanim].istexture := false;
      anims[lastanim].numpics := flats[anims[lastanim].picnum].lump - flats[anims[lastanim].basepic].lump + 1;
      // JVAL
      // Create new flats as nessesary
      for j := anims[lastanim].basepic to anims[lastanim].basepic + anims[lastanim].numpics - 1 do
        R_FlatNumForName(W_GetNameForNum(j));
    end;

    if anims[lastanim].numpics < 2 then
      I_Error('P_InitPicAnims(): bad cycle from %s to %s',
        [animdefs[i].startname, animdefs[i].endname]);

    anims[lastanim].speed := animdefs[i].speed;
    inc(lastanim);
    inc(i);
  end;
end;

//==============================================================================
//
// getSector()
// Will return a sector_t*
//  given the number of the current sector,
//  the line number and the side (0/1) that you want.
//
//==============================================================================
function getSector(currentSector: integer; line: integer; side: integer): Psector_t;
begin
  result := sides[(sectors[currentSector].lines[line]).sidenum[side]].sector;
end;

//==============================================================================
//
// P_FindShortestTextureAround()
//
// Passed a sector number, returns the shortest lower texture on a
// linedef bounding the sector.
//
// Note: If no lower texture exists 32000*FRACUNIT is returned.
//       but if compatibility then MAXINT is returned
//
// jff 02/03/98 Add routine to find shortest lower texture
//
// JVAL BOOM compatibility
//
//==============================================================================
function P_FindShortestTextureAround(secnum: integer): fixed_t;
var
  side: Pside_t;
  i: integer;
  sec: Psector_t;
begin
  sec := @sectors[secnum];

  result := 32000 * FRACUNIT; //jff 3/13/98 prevent overflow in height calcs

  for i := 0 to sec.linecount - 1 do
    if twoSided(secnum, i) then
    begin
      side := getSide(secnum, i, 0);
      if side.bottomtexture > 0 then  //jff 8/14/98 texture 0 is a placeholder
        if textureheight[side.bottomtexture] < result then
          result := textureheight[side.bottomtexture];
      side := getSide(secnum, i, 1);
      if side.bottomtexture > 0 then  //jff 8/14/98 texture 0 is a placeholder
        if textureheight[side.bottomtexture] < result then
          result := textureheight[side.bottomtexture];
    end;

end;

//==============================================================================
//
// EVENTS
// Events are operations triggered by using, crossing,
// or shooting special lines, or by timed thinkers.
//
// P_CrossSpecialLine - TRIGGER
// Called every time a thing origin is about
//  to cross a line with a non 0 special.
//
//==============================================================================
procedure P_CrossSpecialLine(linenum: integer; side: integer; thing: Pmobj_t);
begin
  P_CrossSpecialLinePtr(@lines[linenum], side, thing);
end;

//==============================================================================
//
// P_CrossSpecialLinePtr
//
//==============================================================================
procedure P_CrossSpecialLinePtr(line: Pline_t; side: integer; thing: Pmobj_t);
begin

  //  Triggers that other things can activate
  if thing.player = nil then
  begin

    case line.special of
      39, // TELEPORT TRIGGER
      97, // TELEPORT RETRIGGER
       4: // RAISE DOOR
        ;
      else
        exit;
    end;
  end;

  // Note: could use some const's here.
  case line.special of
  // TRIGGERS.
  // All from here to RETRIGGERS.
     2:
      begin
        // Open Door
        EV_DoDoor(line, open);
        line.special := 0;
      end;

     3:
      begin
        // Close Door
        EV_DoDoor(line, close);
        line.special := 0;
      end;

     4:
      begin
        // Raise Door
        EV_DoDoor(line, normal);
        line.special := 0;
      end;

     5:
      begin
        // Raise Floor
        EV_DoFloor(line, raiseFloor);
        line.special := 0;
      end;

     6:
      begin
        // Fast Ceiling Crush & Raise
        EV_DoCeiling(line, fastCrushAndRaise);
        line.special := 0;
      end;

     8:
      begin
        // Build Stairs
        EV_BuildStairs(line, 8 * FRACUNIT);
        line.special := 0;
      end;

   106:
      begin
        // Build Stairs
        EV_BuildStairs(line, 16 * FRACUNIT);
        line.special := 0;
      end;

    10:
      begin
        // PlatDownWaitUp
        EV_DoPlat(line, downWaitUpStay, 0);
        line.special := 0;
      end;

    12:
      begin
        // Light Turn On - brightest near
        EV_LightTurnOn(line, 0);
        line.special := 0;
      end;

    13:
      begin
        // Light Turn On 255
        EV_LightTurnOn(line, 255);
        line.special := 0;
      end;

    16:
      begin
        // Close Door 30
        EV_DoDoor(line, close30ThenOpen);
        line.special := 0;
      end;

    17:
      begin
        // Start Light Strobing
        EV_StartLightStrobing(line);
        line.special := 0;
      end;

    19:
      begin
        // Lower Floor
        EV_DoFloor(line, lowerFloor);
        line.special := 0;
      end;

    22:
      begin
        // Raise floor to nearest height and change texture
        EV_DoPlat(line, raiseToNearestAndChange, 0);
        line.special := 0;
      end;

    25:
      begin
        // Ceiling Crush and Raise
        EV_DoCeiling(line, crushAndRaise);
        line.special := 0;
      end;

    30:
      begin
        // Raise floor to shortest texture height
        //  on either side of lines.
        EV_DoFloor(line, raiseToTexture);
        line.special := 0;
      end;

    35:
      begin
        // Lights Very Dark
        EV_LightTurnOn(line, 35);
        line.special := 0;
      end;

    36:
      begin
        // Lower Floor (TURBO)
        EV_DoFloor(line, turboLower);
        line.special := 0;
      end;

    37:
      begin
        // LowerAndChange
        EV_DoFloor(line, lowerAndChange);
        line.special := 0;
      end;

    38:
      begin
        // Lower Floor To Lowest
        EV_DoFloor(line, lowerFloorToLowest);
        line.special := 0;
      end;

    39:
      begin
        // TELEPORT!
        EV_Teleport(line, side, thing);
        line.special := 0;
      end;

    40:
      begin
        // RaiseCeilingLowerFloor
        EV_DoCeiling(line, raiseToHighest);
        EV_DoFloor(line, lowerFloorToLowest);
        line.special := 0;
      end;

    44:
      begin
        // Ceiling Crush
        EV_DoCeiling(line, lowerAndCrush);
        line.special := 0;
      end;

    52:
      begin
        // EXIT!
        G_ExitLevel;
        line.special := 0;
      end;

    53:
      begin
        // Perpetual Platform Raise
        EV_DoPlat(line, perpetualRaise, 0);
        line.special := 0;
      end;

    54:
      begin
        // Platform Stop
        EV_StopPlat(line);
        line.special := 0;
      end;

    56:
      begin
        // Raise Floor Crush
        EV_DoFloor(line, raiseFloorCrush);
        line.special := 0;
      end;

    57:
      begin
        // Ceiling Crush Stop
        EV_CeilingCrushStop(line);
        line.special := 0;
      end;

    58:
      begin
        // Raise Floor 24
        EV_DoFloor(line, raiseFloor24);
        line.special := 0;
      end;

    59:
      begin
        // Raise Floor 24 And Change
        EV_DoFloor(line, raiseFloor24AndChange);
        line.special := 0;
      end;

   104:
      begin
        // Turn lights off in sector(tag)
        EV_TurnTagLightsOff(line);
        line.special := 0;
      end;

   105:
      begin
        // Secret EXIT
        G_SecretExitLevel;
      end;

  // RE-DOABLE TRIGGERS
    72:
      begin
        // Ceiling Crush
        EV_DoCeiling(line, lowerAndCrush);
      end;

    73:
      begin
        // Ceiling Crush and Raise
        EV_DoCeiling(line, crushAndRaise);
      end;

    74:
      begin
        // Ceiling Crush Stop
        EV_CeilingCrushStop(line);
      end;

    75:
      begin
        // Close Door
        EV_DoDoor(line, close);
      end;

    76:
      begin
        // Close Door 30
        EV_DoDoor(line, close30ThenOpen);
      end;

    77:
      begin
        // Fast Ceiling Crush & Raise
        EV_DoCeiling(line, fastCrushAndRaise);
      end;

    79:
      begin
        // Lights Very Dark
        EV_LightTurnOn(line, 35);
      end;

    80:
      begin
        // Light Turn On - brightest near
        EV_LightTurnOn(line, 0);
      end;

    81:
      begin
        // Light Turn On 255
        EV_LightTurnOn(line, 255);
      end;

    82:
      begin
        // Lower Floor To Lowest
        EV_DoFloor(line, lowerFloorToLowest);
      end;

    83:
      begin
        // Lower Floor
        EV_DoFloor(line, lowerFloor);
      end;

    84:
      begin
        // LowerAndChange
        EV_DoFloor(line, lowerAndChange);
      end;

    86:
      begin
        // Open Door
        EV_DoDoor(line, open);
      end;

    87:
      begin
        // Perpetual Platform Raise
        EV_DoPlat(line, perpetualRaise, 0);
      end;

    88:
      begin
        // PlatDownWaitUp
        EV_DoPlat(line, downWaitUpStay, 0);
      end;

    89:
      begin
        // Platform Stop
        EV_StopPlat(line);
      end;

    90:
      begin
        // Raise Door
        EV_DoDoor(line, normal);
      end;

   100:
      begin
        // Retrigger_Raise_Door_Turbo
        EV_DoDoor(line, normal, VDOORSPEED * 3);
      end;

    91:
      begin
        // Raise Floor
        EV_DoFloor(line, raiseFloor);
      end;

    92:
      begin
        // Raise Floor 24
        EV_DoFloor(line, raiseFloor24);
      end;

    93:
      begin
        // Raise Floor 24 And Change
        EV_DoFloor(line, raiseFloor24AndChange);
      end;

    94:
      begin
        // Raise Floor Crush
        EV_DoFloor(line, raiseFloorCrush);
      end;

    95:
      begin
        // Raise floor to nearest height
        // and change texture.
        EV_DoPlat(line, raiseToNearestAndChange, 0);
      end;

    96:
      begin
        // Raise floor to shortest texture height
        // on either side of lines.
        EV_DoFloor(line, raiseToTexture);
      end;

    97:
      begin
        // TELEPORT!
        EV_Teleport(line, side, thing);
      end;

    98:
      begin
        // Lower Floor (TURBO)
        EV_DoFloor(line, turboLower);
      end;

  end;
end;

//==============================================================================
//
// P_ShootSpecialLine - IMPACT SPECIALS
// Called when a thing shoots a special line.
//
//==============================================================================
procedure P_ShootSpecialLine(thing: Pmobj_t; line: Pline_t);
begin
  //  Impacts that other things can activate.
  if thing.player = nil then
    case line.special of
      46: ; // OPEN DOOR IMPACT
    else
      exit;
    end;

  case line.special of
    24:
      begin
        // RAISE FLOOR
        EV_DoFloor(line, raiseFloor);
        P_ChangeSwitchTexture(line, false);
      end;

    46:
      begin
        // OPEN DOOR
        EV_DoDoor(line, open);
        P_ChangeSwitchTexture(line, true);
      end;

    47:
      begin
        // RAISE FLOOR NEAR AND CHANGE
        EV_DoPlat(line, raiseToNearestAndChange, 0);
        P_ChangeSwitchTexture(line, false);
      end;
  end;
end;

var
  LavaInflictor: mobj_t;

//==============================================================================
//
// P_InitLava
//
//==============================================================================
procedure P_InitLava;
begin
  memset(@LavaInflictor, 0, SizeOf(mobj_t));
  LavaInflictor._type := Ord(MT_PHOENIXFX2);
  LavaInflictor.flags2 := MF2_FIREDAMAGE or MF2_NODMGTHRUST;
end;

//
// P_PlayerInSpecialSector
// Called every tic frame
//  that the player origin is in a special sector
//
const
  pushTab: array[0..4] of integer = (
    2048 * 5,
    2048 * 10,
    2048 * 25,
    2048 * 30,
    2048 * 35
  );

//==============================================================================
//
// P_PlayerInSpecialSector
//
//==============================================================================
procedure P_PlayerInSpecialSector(player: Pplayer_t; const sector: Psector_t; const height: fixed_t);  // JVAL: 3d Floors
begin
  // Falling, not all the way down yet?
  if player.mo.z <> height then
    exit;

  // Ignore all other UDMF line specials:
  // -LIGHT_SEQUENCE_START
  // -LIGHT_SEQUENCE
  // -LIGHT_SEQUENCE_ALT
  // -LIGHTNING_SPECIAL
  // -LIGHTNING_SPECIAL2
  // -STAIR_SECTOR_TYPE
  // -STAIR_SECTOR_TYPE + 1
  if sector.special > 51 then
    exit;

  // Has hitten ground.
  case sector.special of
     5:
      begin
        // Damage_LavaWimpy
        if leveltime and 15 = 0 then
          P_DamageMobj(player.mo, @LavaInflictor, nil, 5);
      end;

     7:
      begin
        // Damage_Sludge
        if leveltime and 31 = 0 then
          P_DamageMobj(player.mo, nil, nil, 4);
      end;

    16: // Damage_LavaHefty
      begin
        if leveltime and 15 = 0 then
        begin
          P_DamageMobj(player.mo, @LavaInflictor, nil, 8);
          P_HitFloor(player.mo);
        end;
      end;
     4: // Scroll_EastLavaDamage
      begin
        P_Thrust(player, 0, 2048 * 28);
        if leveltime and 15 = 0 then
        begin
          P_DamageMobj(player.mo, @LavaInflictor, nil, 5);
          P_HitFloor(player.mo);
        end;
      end;

     9:
      begin
        // SECRET SECTOR
        player.secretcount := player.secretcount + 1;
        player._message := MSGSECRETSECTOR;
        sector.special := 0;
      end;

    25, 26, 27, 28, 29: // Scroll_North
      begin
        P_Thrust(player, ANG90, pushTab[sector.special - 25]);
      end;

    20, 21, 22, 23, 24: // Scroll_East
      begin
        P_Thrust(player, 0, pushTab[sector.special - 20]);
      end;

    30, 31, 32, 33, 34: // Scroll_South
      begin
        P_Thrust(player, ANG270, pushTab[sector.special - 30]);
      end;

    35, 36, 37, 38, 39: // Scroll_West
      begin
        P_Thrust(player, ANG180, pushTab[sector.special - 35]);
      end;

    40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51:
      begin // Wind specials are handled in (P_mobj):P_XYMovement
      end;

    15: // Friction_Low
      begin // Only used in (P_mobj):P_XYMovement and (P_user):P_Thrust
      end;

  else
    I_Error('P_PlayerInSpecialSector(): unknown special %d', [sector.special]);
  end;
end;

var
  numlinespecials: smallint;
  linespeciallist: array[0..MAXLINEANIMS - 1] of Pline_t;

//
// P_UpdateSpecials
// Animate planes, scroll walls, etc.
//
var
  levelTimer: boolean;
  levelTimeCount: integer;

//==============================================================================
//
// P_UpdateSpecials
//
//==============================================================================
procedure P_UpdateSpecials;
var
  anim: Panim_t;
  pic: integer;
  i: integer;
  j: integer;
  line: Pline_t;
  button: Pbutton_t;
begin
  // LEVEL TIMER
  if levelTimer then
  begin
    dec(levelTimeCount);
    if levelTimeCount = 0 then
      G_ExitLevel;
  end;

  // ANIMATE FLATS AND TEXTURES GLOBALLY
  for j := 0 to lastanim - 1 do
  begin
    anim := @anims[j];
    for i := anim.basepic to anim.basepic + anim.numpics - 1 do
    begin
      pic := anim.basepic + ((leveltime div anim.speed + i) mod anim.numpics);
      if anim.istexture then
        texturetranslation[i] := pic
      else
        flats[i].translation := pic;
    end;
  end;

  curripple := @r_defripple[leveltime and 31];

  // ANIMATE LINE SPECIALS
  for i := 0 to numlinespecials - 1 do
  begin
    line := linespeciallist[i];
    case line.special of
      48: inc(sides[line.sidenum[0]].textureoffset, FRACUNIT);
      99: dec(sides[line.sidenum[0]].textureoffset, FRACUNIT);
    // JVAL
    // Added new line specials for scrolling
     142: dec(sides[line.sidenum[0]].textureoffset, FRACUNIT);
     143: inc(sides[line.sidenum[0]].rowoffset, FRACUNIT);
     144: dec(sides[line.sidenum[0]].rowoffset, FRACUNIT);
     145: inc(sides[line.sidenum[0]].textureoffset, 2 * FRACUNIT);
     146: dec(sides[line.sidenum[0]].textureoffset, 2 * FRACUNIT);
     147: inc(sides[line.sidenum[0]].rowoffset, 2 * FRACUNIT);
     148: dec(sides[line.sidenum[0]].rowoffset, 2 * FRACUNIT);

     UDMF_SPECIAL_START + 100: // Scroll_Texture_Left
        sides[line.sidenum[0]].textureoffset := sides[line.sidenum[0]].textureoffset + _SHL(line.arg1, 10);

     UDMF_SPECIAL_START + 101: // Scroll_Texture_Right
        sides[line.sidenum[0]].textureoffset := sides[line.sidenum[0]].textureoffset - _SHL(line.arg1, 10);

     UDMF_SPECIAL_START + 102: // Scroll_Texture_Up
        sides[line.sidenum[0]].rowoffset := sides[line.sidenum[0]].rowoffset + _SHL(line.arg1, 10);

     UDMF_SPECIAL_START + 103: // Scroll_Texture_Down
        sides[line.sidenum[0]].rowoffset := sides[line.sidenum[0]].rowoffset - _SHL(line.arg1, 10);
    end;
  end;

  // HANDLE LIGHTNING
  if LevelHasLightning then
  begin
    if (NextLightningFlash = 0) or (LightningFlash <> 0) then
      P_LightningFlash
    else
      dec(NextLightningFlash);
  end;

  // DO BUTTONS
  button := @buttonlist[0];
  for i := 0 to MAXBUTTONS - 1 do
  begin
    if button.btimer <> 0 then
    begin
      button.btimer := buttonlist[i].btimer - 1;

      if button.btimer = 0 then
      begin
        case button.where of
          top:
            sides[button.line.sidenum[0]].toptexture := button.btexture;

          middle:
            sides[button.line.sidenum[0]].midtexture := button.btexture;

          bottom:
            sides[button.line.sidenum[0]].bottomtexture := button.btexture;
        end;
        S_StartSound(@button.soundorg, Ord(sfx_switch));
        ZeroMemory(button, SizeOf(button_t));
      end;

    end;
    inc(button);
  end;
end;

//==============================================================================
// EV_DoDonut
//
// Special Stuff that can not be categorized
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
  result := 0;
  secnum := P_FindSectorFromLineTag(line, -1);
  while secnum >= 0 do
  begin
    s1 := @sectors[secnum];
    secnum := P_FindSectorFromLineTag(line, secnum);

    // ALREADY MOVING?  IF SO, KEEP GOING...
    if s1.specialdata <> nil then
      continue;

    result := 1;
    s2 := getNextSector(s1.lines[0], s1);
    for i := 0 to s2.linecount - 1 do
    begin
      if (s2.lines[i].flags and ML_TWOSIDED = 0) or
         (s2.lines[i].backsector = s1) then
        continue;
      s3 := s2.lines[i].backsector;
      if s3 = nil then
        continue;

      //  Spawn rising slime
      floor := Z_Malloc(SizeOf(floormove_t), PU_LEVSPEC, nil);
      P_AddThinker(@floor.thinker);
      s2.specialdata := floor;
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
      P_AddThinker(@floor.thinker);
      s1.specialdata := floor;
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
// P_SpawnSpecials
// After the map has been loaded, scan for specials
//  that spawn thinkers
//
// Parses command line parameters.
//
//==============================================================================
procedure P_SpawnSpecials;
var
  sector: Psector_t;
  i: integer;
  time: integer;
  s: integer;
  ang: angle_t;
begin
  if W_CheckNumForName('texture2') < 0 then
    gameepisode := 1; // ???

  // See if -TIMER needs to be used.
  levelTimer := false;

  i := M_CheckParm('-avg');
  if (i <> 0) and (deathmatch <> 0) then
  begin
    levelTimer := true;
    levelTimeCount := 20 * 60 * TICRATE;
  end;

  i := M_CheckParm('-timer');
  if (i <> 0) and (deathmatch <> 0) then
  begin
    time := atoi(myargv[i + 1]) * 60 * TICRATE;
    levelTimer := true;
    levelTimeCount := time;
  end;

  //  Init special SECTORs.
  sector := @sectors[0];
  dec(sector);
  for i := 0 to numsectors - 1 do
  begin
    inc(sector);
    if sector.special = 0 then
      continue;

    case sector.special of
     1:
      begin
        // FLICKERING LIGHTS
        P_SpawnLightFlash(sector);
      end;

     2:
      begin
        // STROBE FAST
        P_SpawnStrobeFlash(sector, FASTDARK, 0);
      end;

     3:
      begin
        // STROBE SLOW
        P_SpawnStrobeFlash(sector, SLOWDARK, 0);
      end;

     4:
      begin
        // STROBE FAST/DEATH SLIME
        P_SpawnStrobeFlash(sector, FASTDARK, 0);
        sector.special := 4;
      end;

     8:
      begin
        // GLOWING LIGHT
        P_SpawnGlowingLight(sector);
      end;

     9:
      begin
        // SECRET SECTOR
        P_World.Totals.CountSecret;
      end;

    10:
      begin
        // DOOR CLOSE IN 30 SECONDS
        P_SpawnDoorCloseIn30(sector);
      end;

    12:
      begin
        // SYNC STROBE SLOW
        P_SpawnStrobeFlash(sector, SLOWDARK, 1);
      end;

    13:
      begin
        // SYNC STROBE FAST
        P_SpawnStrobeFlash(sector, FASTDARK, 1);
      end;

    14:
      begin
        // DOOR RAISE IN 5 MINUTES
        P_SpawnDoorRaiseIn5Mins(sector, i);
      end;

    17:
      begin
        // fire flickering
        P_SpawnFireFlicker(sector);
      end;

    LIGHT_SEQUENCE_START:
      begin
        // Phased light sequence start
        P_SpawnLightSequence(sector, 1);
      end;
    end;
  end;

    //  Init line EFFECTs
  numlinespecials := 0;
  for i := 0 to numlines - 1 do
  begin
    case lines[i].special of
      48, 99, 142, 143, 144, 145, 146, 147, 148,
      UDMF_SPECIAL_START + 100,
      UDMF_SPECIAL_START + 101,
      UDMF_SPECIAL_START + 102,
      UDMF_SPECIAL_START + 103: // JVAL: Scrolling specials
        begin
          // EFFECT FIRSTCOL SCROLL+
          if numlinespecials < MAXLINEANIMS then
          begin
            linespeciallist[numlinespecials] := @lines[i];
            inc(numlinespecials);
          end;
        end;
    end;
  end;

  //  Init other misc stuff
  P_World.ActiveCeilings.Clear;
  P_World.UdmfCeilings.Clear;
  P_World.ActivePlats.Clear;
  P_World.UdmfPlats.Clear;

  for i := 0 to MAXBUTTONS - 1 do
    ZeroMemory(@buttonlist[i], SizeOf(button_t));

    // UNUSED: no horizonal sliders.
    //  P_InitSlidingDoorFrames();
  for i := 0 to numlines - 1 do
    case lines[i].special of
      // JVAL: ripple effect to tagged sectors floor
      279:
        begin
          s := -1;
          while P_FindSectorFromLineTag2(@lines[i], s) >= 0 do
            sectors[s].renderflags := sectors[s].renderflags or SRF_RIPPLE_FLOOR;
        end;
      // JVAL: ripple effect to tagged sectors ceiling
      280:
        begin
          s := -1;
          while P_FindSectorFromLineTag2(@lines[i], s) >= 0 do
            sectors[s].renderflags := sectors[s].renderflags or SRF_RIPPLE_CEILING;
        end;
      // JVAL: ladder to tagged sectors (when sliding)
      282:
        begin
          s := -1;
          while P_FindSectorFromLineTag2(@lines[i], s) >= 0 do
            sectors[s].flags := sectors[s].flags or SF_LADDER;
        end;
      // JVAL: Slip while descenting a sloped sector
      283:
        begin
          s := -1;
          while P_FindSectorFromLineTag2(@lines[i], s) >= 0 do
            sectors[s].flags := sectors[s].flags or SF_SLIPSLOPEDESCENT;
        end;
      // JVAL: 20200517 - Rotate sector floor
      284:
        begin
          ang := R_PointToAngle2(lines[i].v1.x, lines[i].v1.y, lines[i].v2.x, lines[i].v2.y);
          s := -1;
          while P_FindSectorFromLineTag2(@lines[i], s) >= 0 do
          begin
            sectors[s].floorangle := ang;
            sectors[s].flooranglex := lines[i].v1.x;
            sectors[s].floorangley := lines[i].v1.y;
          end;
        end;
      // JVAL: 20200517 - Rotate sector ceiling
      285:
        begin
          ang := R_PointToAngle2(lines[i].v1.x, lines[i].v1.y, lines[i].v2.x, lines[i].v2.y);
          s := -1;
          while P_FindSectorFromLineTag2(@lines[i], s) >= 0 do
          begin
            sectors[s].ceilingangle := ang;
            sectors[s].ceilinganglex := lines[i].v1.x;
            sectors[s].ceilingangley := lines[i].v1.y;
          end;
        end;
    end;
end;

//==============================================================================
//
// TSpecGameRules.TwoSidedByFlag
//
//==============================================================================
class function TSpecGameRules.TwoSidedByFlag: boolean;
begin
  result := true;
end;

//==============================================================================
//
// TSpecGameRules.NextSectorCompatible
//
//==============================================================================
class function TSpecGameRules.NextSectorCompatible: boolean;
begin
  result := true;
end;

//==============================================================================
//
// TSpecGameRules.HighestFloorStart
//
//==============================================================================
class function TSpecGameRules.HighestFloorStart: fixed_t;
begin
  if G_PlayingEngineVersion >= VERSION207 then
    result := -32000 * FRACUNIT
  else
    result := -500 * FRACUNIT;
end;

//==============================================================================
//
// TSpecGameRules.LowestCeilingStart
//
//==============================================================================
class function TSpecGameRules.LowestCeilingStart: fixed_t;
begin
  if G_PlayingEngineVersion > VERSION207 then
    result := 32000 * FRACUNIT
  else
    result := MAXINT;
end;

//==============================================================================
//
// TSpecGameRules.HighestCeilingStart
//
//==============================================================================
class function TSpecGameRules.HighestCeilingStart: fixed_t;
begin
  if G_PlayingEngineVersion > VERSION114 then
    result := -32000 * FRACUNIT
  else
    result := 0;
end;

//==============================================================================
//
// TSpecGameRules.AdjoiningSectorsLimit
//
//==============================================================================
class function TSpecGameRules.AdjoiningSectorsLimit: integer;
begin
  if G_NeedsCompatibilityMode then
    result := 20
  else
    result := MAX_ADJOINING_SECTORS;
end;

//==============================================================================
//
// TSpecGameRules.LineSectorTag
//
//==============================================================================
class function TSpecGameRules.LineSectorTag(line: Pline_t): integer;
begin
  result := line.tag;
end;

//==============================================================================
//
// TSpecGameRules.SectorSpecialAfterLight
//
//==============================================================================
class function TSpecGameRules.SectorSpecialAfterLight(special: integer): integer;
begin
  // Heretic clears every bit: its wind and current specials are above 31
  result := 0;
end;

//==============================================================================
//
// TSpecGameRules.LightingBusy
//
//==============================================================================
class function TSpecGameRules.LightingBusy(sec: Psector_t): boolean;
begin
  result := sec.specialdata <> nil;
end;
end.
