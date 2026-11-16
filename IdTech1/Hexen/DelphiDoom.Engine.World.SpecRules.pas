//------------------------------------------------------------------------------
//
//  DelphiHexen is a source port of the game Hexen and it is
//  based on original Linux Doom as published by "id Software", on
//  Hexen source as published by "Raven" software and DelphiDoom
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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.World.SpecRules;

interface

uses
  d_delphi,
  m_fixed,
  d_player,
  d_think,
  p_local,
  p_mobj_h,
  p_tick,
  r_defs,
  p_spec_h;

//==============================================================================
//
// P_InitLava
//
//==============================================================================
procedure P_InitLava;

//==============================================================================
//
// P_FindSectorFromTag
//
//==============================================================================
function P_FindSectorFromTag(tag: integer; start: integer): integer;

//==============================================================================
//
// P_FindSectorFromTag2
//
//==============================================================================
function P_FindSectorFromTag2(const tag: integer; var sec: integer): integer;

//==============================================================================
//
// EVH_SectorSoundChange
//
//==============================================================================
function EVH_SectorSoundChange(args: PByteArray): boolean;

//==============================================================================
//
// CheckedLockedDoor
//
//==============================================================================
function CheckedLockedDoor(mo: Pmobj_t; lock: byte): boolean;

//==============================================================================
//
// EVH_LineSearchForPuzzleItem
//
//==============================================================================
function EVH_LineSearchForPuzzleItem(line: Pline_t; args: PByteArray; mo: Pmobj_t): boolean;

//==============================================================================
//
// P_ExecuteLineSpecial
//
//==============================================================================
function P_ExecuteLineSpecial(special: integer; args: PByteArray; line: Pline_t;

  side: integer; mo: Pmobj_t): boolean;

//==============================================================================
//
// P_ActivateLine
//
//==============================================================================
function P_ActivateLine(line: Pline_t; mo: Pmobj_t; side: integer;

  activationType: integer): boolean;

//==============================================================================
//
// P_PlayerInSpecialSector
//
//==============================================================================
procedure P_PlayerInSpecialSector(player: Pplayer_t; const sector: Psector_t; const height: fixed_t);  // JVAL: 3d Floors

//==============================================================================
//
// P_PlayerOnSpecialFlat
//
//==============================================================================
procedure P_PlayerOnSpecialFlat(player: Pplayer_t; floorType: integer);

//==============================================================================
//
// P_UpdateSpecials
//
//==============================================================================
procedure P_UpdateSpecials;

//==============================================================================
//
// P_SpawnSpecials
//
//==============================================================================
procedure P_SpawnSpecials;

//==============================================================================
//
// P_FindLine
//
//==============================================================================
function P_FindLine(lineTag: integer; searchPosition: PInteger): Pline_t;

type
  /// <summary>
  ///   What Hexen does differently in the sector utilities of IdTech1\Base\p_spec.pas (issue #185, step 2g)
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
  end;

implementation

uses
  p_spec,
  a_action,
  xn_strings,
  doomdef,
  doomdata,
  i_system,
  info_h,
  r_ripple,
  g_game,
  p_mapinfo,
  p_setup,
  p_inter,
  DelphiDoom.Engine.World.InterRules,
  DelphiDoom.Engine.World.SwitchRules,
  p_switch,
  udmf_ceilng,
  udmf_plats,
  udmf_lights,
  udmf_doors,
  p_mobj,
  p_user,
  DelphiDoom.Engine.World.UserRules,
  DelphiDoom.Engine.World.PlayerArtifacts,
  udmf_floor,
  udmf_telept,
  p_acs,
  p_anim,
  p_things,
  po_man,
  p_common,
  tables,
  sb_bar,
  s_sound,
  s_sndseq,
  sounddata;

//==============================================================================
//
// P_InitLava
//
//==============================================================================
procedure P_InitLava;
begin
  memset(@LavaInflictor, 0, SizeOf(mobj_t));
  LavaInflictor._type := Ord(MT_CIRCLEFLAME);
  LavaInflictor.flags2 := MF2_FIREDAMAGE or MF2_NODMGTHRUST;
end;

//==============================================================================
//
// P_FindSectorFromTag
//
//==============================================================================
function P_FindSectorFromTag(tag: integer; start: integer): integer;
var
  i: integer;
begin
  for i := start + 1 to numsectors - 1 do
    if sectors[i].tag = tag then
    begin
      result := i;
      exit;
    end;

  result := -1;
end;

//==============================================================================
//
// P_FindSectorFromTag2
//
//==============================================================================
function P_FindSectorFromTag2(const tag: integer; var sec: integer): integer;
begin
  result := P_FindSectorFromTag(tag, sec);
  sec := result;
end;

const
  MAX_TAGGED_LINES = 64;

// PRIVATE DATA DEFINITIONS ------------------------------------------------
type
  taggedlineitem_t = record
    line: Pline_t;
    lineTag: integer;
  end;

var
  TaggedLines: array[0..MAX_TAGGED_LINES - 1] of taggedlineitem_t;
  TaggedLineCount: integer = 0;

//==============================================================================
//
// EVH_SectorSoundChange
//
//==============================================================================
function EVH_SectorSoundChange(args: PByteArray): boolean;
var
  secNum: integer;
begin

  if args[0] = 0 then
  begin
    result := false;
    exit;
  end;

  result := false;
  secNum := -1;
  while P_FindSectorFromTag2(args[0], secNum) >= 0 do
  begin
    sectors[secNum].seqType := seqtype_t(args[1]);
    result := true;
  end;
end;

//==============================================================================
//
// CheckedLockedDoor
//
//==============================================================================
function CheckedLockedDoor(mo: Pmobj_t; lock: byte): boolean;
var
  LockedBuffer: string;
begin
  if mo.player = nil then
  begin
    result := false;
    exit;
  end;

  if lock = 0 then
  begin
    result := true;
    exit;
  end;

  if Pplayer_t(mo.player).keys and _SHL(1, lock - 1) = 0 then
  begin
    sprintf(LockedBuffer, 'YOU NEED THE %s', [TextKeyMessages[lock - 1]]);
    P_SetMessage(mo.player, LockedBuffer, true);
    S_StartSound(mo, Ord(SFX_DOOR_LOCKED));
    result := false;
    exit;
  end;

  result := true;
end;

//==============================================================================
//
// EVH_LineSearchForPuzzleItem
//
//==============================================================================
function EVH_LineSearchForPuzzleItem(line: Pline_t; args: PByteArray; mo: Pmobj_t): boolean;
var
  player: Pplayer_t;
  i: integer;
  arti: artitype_t;
  _type: integer;
begin
  if mo = nil then
  begin
    result := false;
    exit;
  end;

  player := mo.player;
  if player = nil then
  begin
    result := false;
    exit;
  end;

  // Search player's inventory for puzzle items
  for i := 0 to player.artifactCount - 1 do
  begin
    arti := artitype_t(player.inventory[i]._type);
    _type := Ord(arti) - arti_firstpuzzitem;
    if _type < 0 then
      continue;

    if _type = line.arg1 then
    begin
      // A puzzle item was found for the line
      if P_UseArtifact(player, arti) then
      begin
        // A puzzle item was found for the line
        P_PlayerRemoveArtifact(player, i);
        if player = @players[TGameSession.ConsolePlayer] then
        begin
          if Ord(arti) < arti_firstpuzzitem then
            S_StartSound(nil, Ord(SFX_ARTIFACT_USE))
          else
            S_StartSound(nil, Ord(SFX_PUZZLE_SUCCESS));
          ArtifactFlash := 4;
        end;
        result := true;
        exit;
      end;
    end;
  end;

  result := false;
end;

//
//
// EVENTS
//
// Events are operations triggered by using, crossing, or shooting special lines,
// or by timed thinkers
//
//

//==============================================================================
//
// P_ExecuteLineSpecial
//
//==============================================================================
function P_ExecuteLineSpecial(special: integer; args: PByteArray; line: Pline_t;
  side: integer; mo: Pmobj_t): boolean;
begin
  result := false;

  case special of

    1: // Poly Start Line
      begin
      end;

    2: // Poly Rotate Left
      begin
        result := EVH_RotatePoly(line, args, 1, false);
      end;

    3: // Poly Rotate Right
      begin
        result := EVH_RotatePoly(line, args, -1, false);
      end;

    4: // Poly Move
      begin
        result := EVH_MovePoly(line, args, false, false);
      end;

    5: // Poly Explicit Line:  Only used in initialization
      begin
      end;

    6: // Poly Move Times 8
      begin
        result := EVH_MovePoly(line, args, true, false);
      end;

    7: // Poly Door Swing
      begin
        result := EVH_OpenPolyDoor(line, args, PODOOR_SWING);
      end;

    8: // Poly Door Slide
      begin
        result := EVH_OpenPolyDoor(line, args, PODOOR_SLIDE);
      end;

    10: // Door Close
      begin
        result := EVH_DoDoor(line, args, DREV_CLOSE);
      end;

    11: // Door Open
      begin
        if args[0] = 0 then
          result := EVH_VerticalDoor(line, mo)
        else
          result := EVH_DoDoor(line, args, DREV_OPEN);
      end;

    12: // Door Raise
      begin
        if args[0] = 0 then
          result := EVH_VerticalDoor(line, mo)
        else
          result := EVH_DoDoor(line, args, DREV_NORMAL);
      end;

    13: // Door Locked_Raise
      begin
        if CheckedLockedDoor(mo, args[3]) then
        begin
          if args[0] = 0 then
            result := EVH_VerticalDoor(line, mo)
          else
            result := EVH_DoDoor(line, args, DREV_NORMAL);
        end;
      end;

    20: // Floor Lower by Value
      begin
        result := EVH_DoFloor(line, args, FLEV_LOWERFLOORBYVALUE);
      end;

    21: // Floor Lower to Lowest
      begin
        result := EVH_DoFloor(line, args, FLEV_LOWERFLOORTOLOWEST);
      end;

    22: // Floor Lower to Nearest
      begin
        result := EVH_DoFloor(line, args, FLEV_LOWERFLOOR);
      end;

    23: // Floor Raise by Value
      begin
        result := EVH_DoFloor(line, args, FLEV_RAISEFLOORBYVALUE);
      end;

    24: // Floor Raise to Highest
      begin
        result := EVH_DoFloor(line, args, FLEV_RAISEFLOOR);
      end;

    25: // Floor Raise to Nearest
      begin
        result := EVH_DoFloor(line, args, FLEV_RAISEFLOORTONEAREST);
      end;

    26: // Stairs Build Down Normal
      begin
        result := EVH_BuildStairs(line, args, -1, STAIRS_NORMAL);
      end;

    27: // Build Stairs Up Normal
      begin
        result := EVH_BuildStairs(line, args, 1, STAIRS_NORMAL);
      end;

    28: // Floor Raise and Crush
      begin
        result := EVH_DoFloor(line, args, FLEV_RAISEFLOORCRUSH);
      end;

    29: // Build Pillar (no crushing)
      begin
        result := EVH_BuildPillar(line, args, false);
      end;

    30: // Open Pillar
      begin
        result := EVH_OpenPillar(line, args);
      end;

    31: // Stairs Build Down Sync
      begin
        result := EVH_BuildStairs(line, args, -1, STAIRS_SYNC);
      end;

    32: // Build Stairs Up Sync
      begin
        result := EVH_BuildStairs(line, args, 1, STAIRS_SYNC);
      end;

    35: // Raise Floor by Value Times 8
      begin
        result := EVH_DoFloor(line, args, FLEV_RAISEBYVALUETIMES8);
      end;

    36: // Lower Floor by Value Times 8
      begin
        result := EVH_DoFloor(line, args, FLEV_LOWERBYVALUETIMES8);
      end;

    40: // Ceiling Lower by Value
      begin
        result := EVH_DoCeiling(line, args, CLEV_LOWERBYVALUE);
      end;

    41: // Ceiling Raise by Value
      begin
        result := EVH_DoCeiling(line, args, CLEV_RAISEBYVALUE);
      end;

    42: // Ceiling Crush and Raise
      begin
        result := EVH_DoCeiling(line, args, CLEV_CRUSHANDRAISE);
      end;

    43: // Ceiling Lower and Crush
      begin
        result := EVH_DoCeiling(line, args, CLEV_LOWERANDCRUSH);
      end;

    44: // Ceiling Crush Stop
      begin
        result := EVH_CeilingCrushStop(line, args);
      end;

    45: // Ceiling Crush Raise and Stay
      begin
        result := EVH_DoCeiling(line, args, CLEV_CRUSHRAISEANDSTAY);
      end;

    46: // Floor Crush Stop
      begin
        result := EVH_FloorCrushStop(line, args);
      end;

    60: // Plat Perpetual Raise
      begin
        result := EVH_DoPlat(line, args, PLAT_PERPETUALRAISE, 0);
      end;

    61: // Plat Stop
      begin
        EVH_StopPlat(line, args);
      end;

    62: // Plat Down-Wait-Up-Stay
      begin
        result := EVH_DoPlat(line, args, PLAT_DOWNWAITUPSTAY, 0);
      end;

    63: // Plat Down-by-Value*8-Wait-Up-Stay
      begin
        result := EVH_DoPlat(line, args, PLAT_DOWNBYVALUEWAITUPSTAY, 0);
      end;

    64: // Plat Up-Wait-Down-Stay
      begin
        result := EVH_DoPlat(line, args, PLAT_UPWAITDOWNSTAY, 0);
      end;

    65: // Plat Up-by-Value*8-Wait-Down-Stay
      begin
        result := EVH_DoPlat(line, args, PLAT_UPBYVALUEWAITDOWNSTAY, 0);
      end;

    66: // Floor Lower Instant * 8
      begin
        result := EVH_DoFloor(line, args, FLEV_LOWERTIMES8INSTANT);
      end;

    67: // Floor Raise Instant * 8
      begin
        result := EVH_DoFloor(line, args, FLEV_RAISETIMES8INSTANT);
      end;

    68: // Floor Move to Value * 8
      begin
        result := EVH_DoFloor(line, args, FLEV_MOVETOVALUETIMES8);
      end;

    69: // Ceiling Move to Value * 8
      begin
        result := EVH_DoCeiling(line, args, CLEV_MOVETOVALUETIMES8);
      end;

    70: // Teleport
      begin
        if side = 0 then
        begin // Only teleport when crossing the front side of a line
          result := EVH_Teleport(args[0], mo, true);
        end;
      end;

    71: // Teleport, no fog
      begin
        if side = 0 then
        begin // Only teleport when crossing the front side of a line
          result := EVH_Teleport(args[0], mo, false);
        end;
      end;

    72: // Thrust Mobj
      begin
        if side = 0 then // Only thrust on side 0
        begin
          P_ThrustMobj(mo, args[0] * (ANG90 div 64), args[1] * FRACUNIT);
          result := true;
        end;
      end;

    73: // Damage Mobj
      begin
        if args[0] <> 0 then
          P_DamageMobj(mo, nil, nil, args[0])
        else  // If arg1 is zero, then guarantee a kill
          P_DamageMobj(mo, nil, nil, 10000);
        result := true;
      end;

    74: // Teleport_NewMap
      begin
        if side = 0 then
        begin // Only teleport when crossing the front side of a line
          if not ((mo <> nil) and (mo.player <> nil) and (Pplayer_t(mo.player).playerstate = PST_DEAD)) then // Players must be alive to teleport
          begin
            if P_GetMapCluster(args[0]) = 0 then
            begin
              P_SetMessage(mo.player, GACCESSDENIEDDEMO);
              result := false;
            end
            else
            begin
              G_Completed(args[0], args[1]);
              result := true;
            end;
          end;
        end;
      end;

    75: // Teleport_EndGame
      begin
        if side = 0 then
        begin // Only teleport when crossing the front side of a line
          if not ((mo <> nil) and (mo.player <> nil) and (Pplayer_t(mo.player).playerstate = PST_DEAD)) then // Players must be alive to teleport
          begin
            result := true;
            if TGameSession.DeathMatch <> 0 then
            begin // Winning in deathmatch just goes back to map 1
              G_Completed(1, 0);
            end
            else
            begin // Passing -1, -1 to G_Completed starts the Finale
              G_Completed(-1, -1);
            end;
          end;
        end;
      end;

    80: // ACS_Execute
      begin
        result := P_StartACS(args[0], args[1], @args[2], mo, line, side);
      end;

    81: // ACS_Suspend
      begin
        result := P_SuspendACS(args[0], args[1]);
      end;

    82: // ACS_Terminate
      begin
        result := P_TerminateACS(args[0], args[1]);
      end;

    83: // ACS_LockedExecute
      begin
        result := P_StartLockedACS(line, args, mo, side);
      end;

    90: // Poly Rotate Left Override
      begin
        result := EVH_RotatePoly(line, args, 1, true);
      end;

    91: // Poly Rotate Right Override
      begin
        result := EVH_RotatePoly(line, args, -1, true);
      end;

    92: // Poly Move Override
      begin
        result := EVH_MovePoly(line, args, false, true);
      end;

    93: // Poly Move Times 8 Override
      begin
        result := EVH_MovePoly(line, args, true, true);
      end;

    94: // Build Pillar Crush
      begin
        result := EVH_BuildPillar(line, args, true);
      end;

    95: // Lower Floor and Ceiling
      begin
        result := EVH_DoFloorAndCeiling(line, args, false);
      end;

    96: // Raise Floor and Ceiling
      begin
        result := EVH_DoFloorAndCeiling(line, args, true);
      end;

    109: // Force Lightning
      begin
        result := true;
        P_ForceLightning;
      end;

    110: // Light Raise by Value
      begin
        result := EVH_SpawnLight(line, args, LITE_RAISEBYVALUE);
      end;

    111: // Light Lower by Value
      begin
        result := EVH_SpawnLight(line, args, LITE_LOWERBYVALUE);
      end;

    112: // Light Change to Value
      begin
        result := EVH_SpawnLight(line, args, LITE_CHANGETOVALUE);
      end;

    113: // Light Fade
      begin
        result := EVH_SpawnLight(line, args, LITE_FADE);
      end;

    114: // Light Glow
      begin
        result := EVH_SpawnLight(line, args, LITE_GLOW);
      end;

    115: // Light Flicker
      begin
        result := EVH_SpawnLight(line, args, LITE_FLICKER);
      end;

    116: // Light Strobe
      begin
        result := EVH_SpawnLight(line, args, LITE_STROBE);
      end;

    120: // Quake Tremor
      begin
        result := A_LocalQuake(args, mo);
      end;

    129: // UsePuzzleItem
      begin
        result := EVH_LineSearchForPuzzleItem(line, args, mo);
      end;

    130: // Thing_Activate
      begin
        result := EVH_ThingActivate(args[0]);
      end;

    131: // Thing_Deactivate
      begin
        result := EVH_ThingDeactivate(args[0]);
      end;

    132: // Thing_Remove
      begin
        result := EVH_ThingRemove(args[0]);
      end;

    133: // Thing_Destroy
      begin
        result := EVH_ThingDestroy(args[0]);
      end;

    134: // Thing_Projectile
      begin
        result := EVH_ThingProjectile(args, false);
      end;

    135: // Thing_Spawn
      begin
        result := EVH_ThingSpawn(args, true);
      end;

    136: // Thing_ProjectileGravity
      begin
        result := EVH_ThingProjectile(args, true);
      end;

    137: // Thing_SpawnNoFog
      begin
        result := EVH_ThingSpawn(args, false);
      end;

    138: // Floor_Waggle
      begin
        result := EVH_StartFloorWaggle(args[0], args[1], args[2], args[3], args[4]);
      end;

    140: // Sector_SoundChange
      begin
        result := EVH_SectorSoundChange(args);
      end;

    // Line specials only processed during level initialization
    // 100: Scroll_Texture_Left
    // 101: Scroll_Texture_Right
    // 102: Scroll_Texture_Up
    // 103: Scroll_Texture_Down
    // 121: Line_SetIdentification

    // Inert Line specials
  end;
end;

//==============================================================================
//
// P_ActivateLine
//
//==============================================================================
function P_ActivateLine(line: Pline_t; mo: Pmobj_t; side: integer; activationType: integer): boolean;
var
  lineActivation: integer;
  dorepeat: boolean;
  buttonSuccess: boolean;
begin
  lineActivation := _SHR(line.flags and ML_SPAC_MASK, ML_SPAC_SHIFT);
  if lineActivation <> activationType then
  begin
    result := false;
    exit;
  end;

  if (mo.player = nil) and (mo.flags and MF_MISSILE = 0) then
  begin

    if lineActivation <> SPAC_MCROSS then
    begin // currently, monsters can only activate the MCROSS activation type
       result := false;
       exit;
    end;

    if line.flags and ML_SECRET <> 0 then
    begin
      result := false;  // never open secret doors
      exit;
    end;

  end;

  dorepeat := line.flags and ML_REPEAT_SPECIAL <> 0;
  buttonSuccess := P_ExecuteLineSpecial(line.special, @line.arg1, line, side, mo);

  if not dorepeat and buttonSuccess then
  begin // clear the special on non-retriggerable lines
    line.special := 0;
  end;

  if ((lineActivation = SPAC_USE) or (lineActivation = SPAC_IMPACT)) and buttonSuccess then
    P_ChangeSwitchTexture(line, dorepeat);

  result := true;
end;

//----------------------------------------------------------------------------
//
// PROC P_PlayerInSpecialSector
//
// Called every tic frame that the player origin is in a special sector.
//
//----------------------------------------------------------------------------

const
  pushTab: array[0..2] of integer = (
     5 * 2048,
    10 * 2048,
    25 * 2048
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

  case sector.special of
    9: // SecretArea
      begin
        inc(player.secretcount);
        player._message := MSGSECRETSECTOR;
        sector.special := 0;
      end;

    201, 202, 203: // Scroll_North_xxx
      begin
        P_Thrust(player, ANG90, pushTab[sector.special - 201]);
      end;

    204, 205, 206: // Scroll_East_xxx
      begin
        P_Thrust(player, 0, pushTab[sector.special - 204]);
      end;

    207, 208, 209: // Scroll_South_xxx
      begin
        P_Thrust(player, ANG270, pushTab[sector.special - 207]);
      end;

    210, 211, 212: // Scroll_West_xxx
      begin
        P_Thrust(player, ANG180, pushTab[sector.special - 210]);
      end;

    213, 214, 215: // Scroll_NorthWest_xxx
      begin
        P_Thrust(player, ANG90 + ANG45, pushTab[sector.special - 213]);
      end;

    216, 217, 218: // Scroll_NorthEast_xxx
      begin
        P_Thrust(player, ANG45, pushTab[sector.special - 216]);
      end;

    219, 220, 221: // Scroll_SouthEast_xxx
      begin
        P_Thrust(player, ANG270 + ANG45, pushTab[sector.special - 219]);
      end;

    222, 223, 224: // Scroll_SouthWest_xxx
      begin
        P_Thrust(player, ANG180 + ANG45, pushTab[sector.special - 222]);
      end;

    40, 41, 42, 43, 44, 45,
    46, 47, 48, 49, 50, 51:
      // Wind specials are handled in (P_mobj):P_XYMovement
      begin
      end;

    26: ;// Stairs_Special1
    27: ;// Stairs_Special2
      // Used in (P_floor):ProcessStairSector

    198: ; // Lightning Special
    199: ; // Lightning Flash special
    200: ; // Sky2
      // Used in (R_plane):R_Drawplanes
    else
      I_Error('P_PlayerInSpecialSector(): unknown special %d', [sector.special]);
  end;
end;

//==============================================================================
//
// P_PlayerOnSpecialFlat
//
//==============================================================================
procedure P_PlayerOnSpecialFlat(player: Pplayer_t; floorType: integer);
begin
  if player.mo.z <> player.mo.floorz then
  begin // Player is not touching the floor
    exit;
  end;

  if floorType = FLOOR_LAVA then
  begin
    if TTickState.LevelTime and 31 = 0 then
    begin
      P_DamageMobj(player.mo, @LavaInflictor, nil, 10);
      S_StartSound(player.mo, Ord(SFX_LAVA_SIZZLE));
    end;
  end;

end;

//----------------------------------------------------------------------------
//
// PROC P_UpdateSpecials
//
//----------------------------------------------------------------------------
//
//==============================================================================
procedure P_UpdateSpecials;
var
  i: integer;
begin
  // Handle buttons
  for i := 0 to MAXBUTTONS - 1 do
  begin
    if buttonlist[i].btimer > 0 then
    begin
      dec(buttonlist[i].btimer);
      if buttonlist[i].btimer = 0 then
      begin
        case buttonlist[i].where of
          SWTCH_TOP:
            sides[buttonlist[i].line.sidenum[0]].toptexture := buttonlist[i].btexture;

          SWTCH_MIDDLE:
            sides[buttonlist[i].line.sidenum[0]].midtexture := buttonlist[i].btexture;

          SWTCH_BOTTOM:
            sides[buttonlist[i].line.sidenum[0]].bottomtexture := buttonlist[i].btexture;

        end;
        //S_StartSound((mobj_t *)&buttonlist[i].soundorg, sfx_switch);
        memset(@buttonlist[i], 0, SizeOf(button_t));
      end;
    end;
  end;

  curripple := @r_defripple[TTickState.LevelTime and 31];

end;

//==============================================================================
//
// P_SpawnSpecials
//
// After the map has been loaded, scan for specials that
// spawn thinkers
//
//==============================================================================
procedure P_SpawnSpecials;
var
  sector: Psector_t;
  i: integer;
  s: integer;
begin
  //
  //      Init special SECTORs
  //
  for i := 0 to numsectors - 1 do
  begin
    sector := @sectors[i];
    if sector.special = 0 then
      continue;

    case sector.special of
      1: // Phased light
         // Hardcoded base, use sector.lightlevel as the index
        P_SpawnPhasedLight(sector, 80, -1);

      2: // Phased light sequence start
        P_SpawnLightSequence(sector, 1);
      // Specials 3 & 4 are used by the phased light sequences

    end;

  end;

  //
  //      Init line EFFECTs
  //
  numlinespecials := 0;
  TaggedLineCount := 0;
  for i := 0 to numlines - 1 do
  begin
    case lines[i].special of
      100, // Scroll_Texture_Left
      101, // Scroll_Texture_Right
      102, // Scroll_Texture_Up
      103: // Scroll_Texture_Down
        begin
          if numlinespecials < MAXLINEANIMS then
          begin
            linespeciallist[numlinespecials] := @lines[i];
            inc(numlinespecials);
          end;
        end;
      121: // Line_SetIdentification
        begin
          if lines[i].arg1 <> 0 then
          begin
            if TaggedLineCount = MAX_TAGGED_LINES then
              I_Error('P_SpawnSpecials(): MAX_TAGGED_LINES (%d) exceeded.', [MAX_TAGGED_LINES]);
            TaggedLines[TaggedLineCount].line := @lines[i];
            TaggedLines[TaggedLineCount].lineTag := lines[i].arg1;
            inc(TaggedLineCount);
          end;
          lines[i].special := 0;
        end;
    end;
  end;

  //
  //      Init other misc stuff
  //
  P_World.ActiveCeilings.Clear;
  P_World.UdmfCeilings.Clear;
  P_World.ActivePlats.Clear;
  P_World.UdmfPlats.Clear;

  for i := 0 to MAXBUTTONS - 1 do
    memset(@buttonlist[i], 0, SizeOf(button_t));

  // Initialize flat and texture animations
  P_InitFTAnims;

  for i := 0 to numlines - 1 do
    case lines[i].special of
      // JVAL: Slip while descenting a sloped sector
      251:
        begin
          s := -1;
          while P_FindSectorFromLineTag2(@lines[i], s) >= 0 do
            sectors[s].flags := sectors[s].flags or SF_SLIPSLOPEDESCENT;
        end;
      // JVAL: Ladder
      254:
        begin
          s := -1;
          while P_FindSectorFromLineTag2(@lines[i], s) >= 0 do
            sectors[s].flags := sectors[s].flags or SF_LADDER;
        end;
      // JVAL: ripple effect to tagged sectors floor/Ceiling
      255:
        begin
          s := -1;
          while P_FindSectorFromLineTag2(@lines[i], s) >= 0 do
          begin
            if lines[i].arg2 <> 0 then
              sectors[s].renderflags := sectors[s].renderflags or SRF_RIPPLE_FLOOR;
            if lines[i].arg3 <> 0 then
              sectors[s].renderflags := sectors[s].renderflags or SRF_RIPPLE_CEILING;
          end;
        end;
    end;
end;

//==============================================================================
//
// P_FindLine
//
//==============================================================================
function P_FindLine(lineTag: integer; searchPosition: PInteger): Pline_t;
var
  i: integer;
begin
  for i := searchPosition^ + 1 to TaggedLineCount - 1 do
  begin
    if TaggedLines[i].lineTag = lineTag then
    begin
      searchPosition^ := i;
      result := TaggedLines[i].line;
      exit;
    end;
  end;
  searchPosition^ := -1;
  result := nil;
end;

//==============================================================================
//
// TSpecGameRules.TwoSidedByFlag
//
//==============================================================================
class function TSpecGameRules.TwoSidedByFlag: boolean;
begin
  result := false;
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
  result := MAXINT;
end;

//==============================================================================
//
// TSpecGameRules.HighestCeilingStart
//
//==============================================================================
class function TSpecGameRules.HighestCeilingStart: fixed_t;
begin
  if G_PlayingEngineVersion > VERSION141 then
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
  result := line.arg1;
end;
end.
