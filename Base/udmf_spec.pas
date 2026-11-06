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
//  UDMF Special effects
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit udmf_spec;

interface

uses
  d_delphi,
  p_mobj_h,
  r_defs,
  udmf_doors,
  DelphiDoom.Specials.Intf;

//==============================================================================
//
// P_FindSectorFromTag
//
//==============================================================================
function P_FindSectorFromTag(tag: integer; var start: integer): integer;

//==============================================================================
//
// P_FindSectorFromTag2
//
//==============================================================================
function P_FindSectorFromTag2(tag: integer; var start: integer): integer;

//==============================================================================
//
// P_FindLine
//
//==============================================================================
function P_FindLine(lineTag: integer; searchPosition: PInteger): Pline_t;

//==============================================================================
//
// P_ConfigureLineSpecials
//
// Gives the registry that runs the line specials (the composition root creates it)
//
//==============================================================================
procedure P_ConfigureLineSpecials(const ARegistry: ISpecialRegistry);

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
function P_ActivateLine(line: Pline_t; mo: Pmobj_t; side: integer; activationType: integer): boolean;

//==============================================================================
//
// P_LineToArgs
//
//==============================================================================
procedure P_LineToArgs(line: Pline_t; const args: PByteArray);

//==============================================================================
//
// P_ArgsToLine
//
//==============================================================================
procedure P_ArgsToLine(line: Pline_t; const args: PByteArray);

//==============================================================================
//
// P_ExecuteActorSpecial
//
//==============================================================================
function P_ExecuteActorSpecial(special: integer; args: PIntegerArray; mo: Pmobj_t): boolean;

const
  {$IFDEF DOOM_OR_STRIFE}
  LIGHTNING_SPECIAL = 20;
  LIGHTNING_SPECIAL2 = 19;
  LIGHTNING_SPECIAL_MASK = 31;
  {$ENDIF}
  {$IFDEF HERETIC}
  LIGHTNING_SPECIAL = 56;
  LIGHTNING_SPECIAL2 = 55;
  LIGHTNING_SPECIAL_MASK = 255;
  {$ENDIF}

var
  LevelHasLightning: boolean;
  NextLightningFlash: integer;
  LightningFlash: integer;

//==============================================================================
//
// P_ForceLightning
//
//==============================================================================
procedure P_ForceLightning(const tics: Integer = 0);

//==============================================================================
//
// P_InitLightning
//
//==============================================================================
procedure P_InitLightning;

//==============================================================================
//
// P_LightningFlash
//
//==============================================================================
procedure P_LightningFlash;
  
implementation

uses
  doomdef,
  doomdata,
  d_think,
  d_player,
  g_game,
  m_fixed,
  m_rnd,
  tables,
  i_system,
  p_acs,
  p_common,
  p_inter,
  p_maputl,
  p_mobj,
  p_setup,
  p_sounds,
  p_spec,
  p_switch,
  p_tick,
  p_udmf,
  po_man,
  r_sky,
  sounddata,
  s_sound,
  udmf_ceilng,
  udmf_floor,
  udmf_lights,
  udmf_mobj,
  udmf_plats,
  udmf_telept,
  udmf_things;

type
  /// <summary>A special with the types of the engine</summary>
  TLineSpecial = reference to function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean;

var
  lineSpecials: ISpecialRegistry;

//==============================================================================
//
// RegisterLineSpecial
//
//==============================================================================
procedure RegisterLineSpecial(const ARegistry: ISpecialRegistry; ANumber: integer; const AHandler: TLineSpecial);
begin
  ARegistry.Register(ANumber,
    function(const AContext: TSpecialContext): Boolean
    begin
      result := AHandler(PByteArray(AContext.Args), Pline_t(AContext.Line), AContext.Side, Pmobj_t(AContext.Actor));
    end);
end;

//==============================================================================
//
// P_FindSectorFromTag
//
//==============================================================================
function P_FindSectorFromTag(tag: integer; var start: integer): integer;
begin
  result := P_FindSectorFromTag2(tag, start);
end;

//==============================================================================
//
// P_FindSectorFromTag2
//
//==============================================================================
function P_FindSectorFromTag2(tag: integer; var start: integer): integer;
var
  i: integer;
  b: Byte;
begin
  if IsIntegerInRange(tag, 0, 255) then
  begin
    b := tag;
    for i := start + 1 to numsectors - 1 do
    begin
      if b in sectors[i].moreids then
      begin
        result := i;
        start := result;
        exit;
      end;
      if sectors[i].tag = tag then
      begin
        result := i;
        start := result;
        exit;
      end;
    end;
  end
  else
  begin
    for i := start + 1 to numsectors - 1 do
      if sectors[i].tag = tag then
      begin
        result := i;
        start := result;
        exit;
      end;
  end;

  result := -1;
  start := -1;
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
  for i := searchPosition^ + 1 to numlines - 1 do
    if lines[i].tag = lineTag then
    begin
      result := @lines[i];
      searchPosition^ := i;
      exit;
    end;
  searchPosition^ := -1;
  result := nil;
end;

//==============================================================================
//
// P_LightningFlash
//
//==============================================================================
procedure P_LightningFlash;
const
  SND_THUNDR = 'THUNDR';
var
  i: integer;
  tempSec: Psector_t;
  foundSec: boolean;
  flashLight: integer;
begin
  if LightningFlash <> 0 then
  begin
    dec(LightningFlash);
    if LightningFlash <> 0 then
    begin
      tempSec := @sectors[0];
      for i := 0 to numsectors - 1 do
      begin
        if (tempSec.ceilingpic = skyflatnum) or
           (tempSec.special and LIGHTNING_SPECIAL_MASK = LIGHTNING_SPECIAL) or
           (tempSec.special and LIGHTNING_SPECIAL_MASK = LIGHTNING_SPECIAL2) then
        begin
          if tempSec.lightninglightlevel < tempSec.lightlevel - 4 then
            tempSec.lightlevel := tempSec.lightlevel - 4;
        end;
        inc(tempSec);
      end;
    end
    else
    begin // remove the alternate lightning flash special
      tempSec := @sectors[0];
      for i := 0 to numsectors - 1 do
      begin
        if (tempSec.ceilingpic = skyflatnum) or
           (tempSec.special and LIGHTNING_SPECIAL_MASK = LIGHTNING_SPECIAL) or
           (tempSec.special and LIGHTNING_SPECIAL_MASK = LIGHTNING_SPECIAL2) then
        begin
          tempSec.lightlevel := tempSec.lightninglightlevel;
        end;
        inc(tempSec);
      end;
      skytexture := skytexture1;
    end;
    exit;
  end;
  LightningFlash := (P_Random and 7) + 8;
  flashLight := 200 + (P_Random and 31);
  tempSec := @sectors[0];
  foundSec := false;
  for i := 0 to numsectors - 1 do
  begin
    if (tempSec.ceilingpic = skyflatnum) or
       (tempSec.special and LIGHTNING_SPECIAL_MASK = LIGHTNING_SPECIAL) or
       (tempSec.special and LIGHTNING_SPECIAL_MASK = LIGHTNING_SPECIAL2) then
    begin
      tempSec.lightninglightlevel := tempSec.lightlevel;
      if tempSec.special and LIGHTNING_SPECIAL_MASK = LIGHTNING_SPECIAL then
      begin
        tempSec.lightlevel := tempSec.lightlevel + 64;
        if tempSec.lightlevel > flashLight then
          tempSec.lightlevel := flashLight;
      end
      else if tempSec.special and LIGHTNING_SPECIAL_MASK = LIGHTNING_SPECIAL2 then
      begin
        tempSec.lightlevel := tempSec.lightlevel + 32;
        if tempSec.lightlevel > flashLight then
          tempSec.lightlevel := flashLight;
      end
      else
        tempSec.lightlevel := flashLight;
      if tempSec.lightlevel < tempSec.lightninglightlevel then
      begin
        tempSec.lightlevel := tempSec.lightninglightlevel;
      end;
      foundSec := true;
    end;
    inc(tempSec);
  end;
  if foundSec then
  begin
    skytexture := skytexture2;
    S_StartSound(nil, SND_THUNDR);
  end;
  // Calculate the next lighting flash
  if NextLightningFlash = 0 then
  begin
    if P_Random < 50 then
    begin // Immediate Quick flash
      NextLightningFlash := (P_Random and 15) + 16;
    end
    else
    begin
      if (P_Random < 128) and (leveltime and 32 = 0) then
        NextLightningFlash := ((P_Random and 7) + 2) * TICRATE
      else
        NextLightningFlash := ((P_Random and 15) + 5) * TICRATE;
    end;
  end;
end;

//==============================================================================
//
// P_ForceLightning
//
//==============================================================================
procedure P_ForceLightning(const tics: Integer = 0);
begin
  NextLightningFlash := tics;
end;

//==============================================================================
//
// P_InitLightning
//
//==============================================================================
procedure P_InitLightning;
var
  i: integer;
  secCount: integer;
begin
  if (gamemapinfo <> nil) and not gamemapinfo.lightning then
  begin
    LevelHasLightning := false;
    LightningFlash := 0;
    exit;
  end
  else if gamemapinfo = nil then
  begin
    LevelHasLightning := false;
    LightningFlash := 0;
    exit;
  end;

  LightningFlash := 0;
  secCount := 0;
  for i := 0 to numsectors - 1 do
    if (sectors[i].ceilingpic = skyflatnum) or
       (sectors[i].special and LIGHTNING_SPECIAL_MASK = LIGHTNING_SPECIAL) or
       (sectors[i].special and LIGHTNING_SPECIAL_MASK = LIGHTNING_SPECIAL2) then
      inc(secCount);

  if secCount > 0 then
    LevelHasLightning := true
  else
  begin
    LevelHasLightning := false;
    exit;
  end;

  NextLightningFlash := ((P_Random and 15) + 5) * TICRATE; // don't flash at level start
end;

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
    sectors[secNum].seqType := args[1];
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

  if lock <> 0 then
  begin
    {$IFDEF DOOM_OR_STRIFE}
    if not IsIntegerInRange(lock, 1, Ord(NUMCARDS)) or not Pplayer_t(mo.player).cards[lock - 1] then
    {$ENDIF}
    {$IFDEF HERETIC}
    if not IsIntegerInRange(lock, 1, Ord(NUMKEYCARDS)) or not Pplayer_t(mo.player).keys[lock - 1] then
    {$ENDIF}
    begin
      {$IFDEF DOOM_OR_STRIFE}
      if not IsIntegerInRange(lock, 1, Ord(NUMCARDS)) then
        LockedBuffer := 'YOU NEED A KEY'
      else
      {$ENDIF}
      {$IFDEF HERETIC}
      if not IsIntegerInRange(lock, 1, Ord(NUMKEYCARDS)) then
        LockedBuffer := 'YOU NEED A KEY'
      else
      {$ENDIF}
      sprintf(LockedBuffer, 'YOU NEED THE %s', [TextKeyMessages[lock - 1]]);
      Pplayer_t(mo.player)._message := LockedBuffer;
      {$IFDEF DOOM_OR_STRIFE}
      S_StartSound(mo, Ord(sfx_oof));
      {$ENDIF}
      {$IFDEF HERETIC}
      S_StartSound(mo, Ord(sfx_plroof));
      {$ENDIF}
      result := false;
      exit;
    end;
  end;
  result := true;
end;

//==============================================================================
//
// P_LocalEarthQuakeEx
//
//==============================================================================
procedure P_LocalEarthQuakeEx(const actor: Pmobj_t; const tics: integer; const intensity: fixed_t; const maxtdist, maxddist: fixed_t);
const
  SND_QUAKE = 'QUAKE2';
var
  i: integer;
  dist: fixed_t;
  frac: fixed_t;
  testintensity: fixed_t;
  pmo: Pmobj_t;
  rnd: integer;
  an: angle_t;
begin
  // JVAL: Actor's active sound is the quake sound
  if actor.info.activesound <> 0 then
    A_ActiveSound(actor, actor)
  else
    S_StartSound(actor, SND_QUAKE);

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
    begin
      pmo := players[i].mo;
      dist := P_AproxDistance(actor.x - pmo.x, actor.y - pmo.y);
      dist := P_AproxDistance(actor.z - pmo.z, dist); // 3d distance
      if dist <= maxtdist then
      begin
        if players[i].quaketics < tics then
          players[i].quaketics := tics;
        frac := FixedDiv(dist, maxtdist) * (FINEANGLES div 4);
        testintensity := FixedMul(finecosine[frac shr ANGLETOFINESHIFT], intensity); // JVAL: 20200508 - Curved
        if players[i].quakeintensity < testintensity then
          players[i].quakeintensity := testintensity;
      end;
      if (dist < maxddist) and (pmo.z <= pmo.floorz) then
      begin
        if P_Random < 50 then
          P_DamageMobj(players[i].mo, nil, nil, (1 + (P_Random and 7)));
        // Thrust player around
        rnd := P_Random;
        an := pmo.angle + ANG1 * rnd;
        P_ThrustMobj(pmo, an, intensity div 2);
      end;
    end;
end;

//==============================================================================
//
// U_LocalQuake
//
// Quake variables
//
//    args[0]    Intensity on richter scale (2..9)
//    args[1]    Duration in tics
//    args[2]    Radius for damage
//    args[3]    Radius for tremor
//    args[4]    TID of map thing for focus of quake
//
//==============================================================================
function U_LocalQuake(args: PByteArray; actor: Pmobj_t): boolean;
const
  QUAKEINTENSITIES: array[2..9] of fixed_t = (
    FRACUNIT div 4,
    FRACUNIT div 2,
    (FRACUNIT * 3) div 4,
    FRACUNIT,
    FRACUNIT + FRACUNIT div 4,
    FRACUNIT + FRACUNIT div 2,
    FRACUNIT + (FRACUNIT * 3) div 4,
    2 * FRACUNIT
  );
var
  focus: Pmobj_t;
  lastfound: Pthinker_t;
begin
  result := false;
  lastfound := @thinkercap;
  repeat
    focus := P_FindMobjFromTID(args[4], Pointer(lastfound));
    if focus <> nil then
      P_LocalEarthQuakeEx(
        focus,
        args[1] * FRACUNIT,
        QUAKEINTENSITIES[GetIntegerInRange(args[0], 2, 9)],
        args[3] * FRACUNIT * 64,
        args[2] * FRACUNIT * 64
      );
  until focus = nil;
end;

//==============================================================================
//
// P_RegisterLineSpecials
//
//==============================================================================
procedure P_RegisterLineSpecials(const ARegistry: ISpecialRegistry);
begin

  // Poly Start Line
  RegisterLineSpecial(ARegistry, 1,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
    end);

  // Poly Rotate Left
  RegisterLineSpecial(ARegistry, 2,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_RotatePoly(line, args, 1, false);
    end);

  // Poly Rotate Right
  RegisterLineSpecial(ARegistry, 3,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_RotatePoly(line, args, -1, false);
    end);

  // Poly Move
  RegisterLineSpecial(ARegistry, 4,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_MovePoly(line, args, false, false);
    end);

  // Poly Explicit Line:  Only used in initialization
  RegisterLineSpecial(ARegistry, 5,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
    end);

  // Poly Move Times 8
  RegisterLineSpecial(ARegistry, 6,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_MovePoly(line, args, true, false);
    end);

  // Poly Door Swing
  RegisterLineSpecial(ARegistry, 7,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_OpenPolyDoor(line, args, PODOOR_SWING);
    end);

  // Poly Door Slide
  RegisterLineSpecial(ARegistry, 8,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_OpenPolyDoor(line, args, PODOOR_SLIDE);
    end);

  // Door Close
  RegisterLineSpecial(ARegistry, 10,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoDoor(line, args, DREV_CLOSE);
    end);

  // Door Open
  RegisterLineSpecial(ARegistry, 11,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      if args[0] = 0 then
        result := EVH_VerticalDoor(line, mo)
      else
        result := EVH_DoDoor(line, args, DREV_OPEN);
    end);

  // Door Raise
  RegisterLineSpecial(ARegistry, 12,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      if args[0] = 0 then
        result := EVH_VerticalDoor(line, mo)
      else
        result := EVH_DoDoor(line, args, DREV_NORMAL);
    end);

  // Door Locked_Raise
  RegisterLineSpecial(ARegistry, 13,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      if CheckedLockedDoor(mo, args[3]) then
      begin
        if args[0] = 0 then
          result := EVH_VerticalDoor(line, mo)
        else
          result := EVH_DoDoor(line, args, DREV_NORMAL);
      end;
    end);

  // Floor Lower by Value
  RegisterLineSpecial(ARegistry, 20,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_LOWERFLOORBYVALUE);
    end);

  // Floor Lower to Lowest
  RegisterLineSpecial(ARegistry, 21,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_LOWERFLOORTOLOWEST);
    end);

  // Floor Lower to Nearest
  RegisterLineSpecial(ARegistry, 22,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_LOWERFLOOR);
    end);

  // Floor Raise by Value
  RegisterLineSpecial(ARegistry, 23,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_RAISEFLOORBYVALUE);
    end);

  // Floor Raise to Highest
  RegisterLineSpecial(ARegistry, 24,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_RAISEFLOOR);
    end);

  // Floor Raise to Nearest
  RegisterLineSpecial(ARegistry, 25,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_RAISEFLOORTONEAREST);
    end);

  // Stairs Build Down Normal
  RegisterLineSpecial(ARegistry, 26,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_BuildStairs(line, args, -1, STAIRS_NORMAL);
    end);

  // Build Stairs Up Normal
  RegisterLineSpecial(ARegistry, 27,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_BuildStairs(line, args, 1, STAIRS_NORMAL);
    end);

  // Floor Raise and Crush
  RegisterLineSpecial(ARegistry, 28,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_RAISEFLOORCRUSH);
    end);

  // Build Pillar (no crushing)
  RegisterLineSpecial(ARegistry, 29,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_BuildPillar(line, args, false);
    end);

  // Open Pillar
  RegisterLineSpecial(ARegistry, 30,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_OpenPillar(line, args);
    end);

  // Stairs Build Down Sync
  RegisterLineSpecial(ARegistry, 31,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_BuildStairs(line, args, -1, STAIRS_SYNC);
    end);

  // Build Stairs Up Sync
  RegisterLineSpecial(ARegistry, 32,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_BuildStairs(line, args, 1, STAIRS_SYNC);
    end);

  // Raise Floor by Value Times 8
  RegisterLineSpecial(ARegistry, 35,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_RAISEBYVALUETIMES8);
    end);

  // Lower Floor by Value Times 8
  RegisterLineSpecial(ARegistry, 36,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_LOWERBYVALUETIMES8);
    end);

  // Ceiling Lower by Value
  RegisterLineSpecial(ARegistry, 40,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoCeiling(line, args, CLEV_LOWERBYVALUE);
    end);

  // Ceiling Raise by Value
  RegisterLineSpecial(ARegistry, 41,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoCeiling(line, args, CLEV_RAISEBYVALUE);
    end);

  // Ceiling Crush and Raise
  RegisterLineSpecial(ARegistry, 42,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoCeiling(line, args, CLEV_CRUSHANDRAISE);
    end);

  // Ceiling Lower and Crush
  RegisterLineSpecial(ARegistry, 43,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoCeiling(line, args, CLEV_LOWERANDCRUSH);
    end);

  // Ceiling Crush Stop
  RegisterLineSpecial(ARegistry, 44,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_CeilingCrushStop(line, args);
    end);

  // Ceiling Crush Raise and Stay
  RegisterLineSpecial(ARegistry, 45,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoCeiling(line, args, CLEV_CRUSHRAISEANDSTAY);
    end);

  // Floor Crush Stop
  RegisterLineSpecial(ARegistry, 46,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_FloorCrushStop(line, args);
    end);

  // Plat Perpetual Raise
  RegisterLineSpecial(ARegistry, 60,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoPlat(line, args, PLAT_PERPETUALRAISE, 0);
    end);

  // Plat Stop
  RegisterLineSpecial(ARegistry, 61,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      EVH_StopPlat(line, args);
    end);

  // Plat Down-Wait-Up-Stay
  RegisterLineSpecial(ARegistry, 62,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoPlat(line, args, PLAT_DOWNWAITUPSTAY, 0);
    end);

  // Plat Down-by-Value*8-Wait-Up-Stay
  RegisterLineSpecial(ARegistry, 63,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoPlat(line, args, PLAT_DOWNBYVALUEWAITUPSTAY, 0);
    end);

  // Plat Up-Wait-Down-Stay
  RegisterLineSpecial(ARegistry, 64,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoPlat(line, args, PLAT_UPWAITDOWNSTAY, 0);
    end);

  // Plat Up-by-Value*8-Wait-Down-Stay
  RegisterLineSpecial(ARegistry, 65,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoPlat(line, args, PLAT_UPBYVALUEWAITDOWNSTAY, 0);
    end);

  // Floor Lower Instant * 8
  RegisterLineSpecial(ARegistry, 66,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_LOWERTIMES8INSTANT);
    end);

  // Floor Raise Instant * 8
  RegisterLineSpecial(ARegistry, 67,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_RAISETIMES8INSTANT);
    end);

  // Floor Move to Value * 8
  RegisterLineSpecial(ARegistry, 68,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloor(line, args, FLEV_MOVETOVALUETIMES8);
    end);

  // Ceiling Move to Value * 8
  RegisterLineSpecial(ARegistry, 69,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoCeiling(line, args, CLEV_MOVETOVALUETIMES8);
    end);

  // Teleport
  RegisterLineSpecial(ARegistry, 70,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      if side = 0 then
      begin // Only teleport when crossing the front side of a line
        result := EVH_Teleport(args[0], mo, true);
      end;
    end);

  // Teleport, no fog
  RegisterLineSpecial(ARegistry, 71,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      if side = 0 then
      begin // Only teleport when crossing the front side of a line
        result := EVH_Teleport(args[0], mo, false);
      end;
    end);

  // Thrust Mobj
  RegisterLineSpecial(ARegistry, 72,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      if side = 0 then // Only thrust on side 0
      begin
        P_ThrustMobj(mo, args[0] * (ANG90 div 64), args[1] * FRACUNIT);
        result := true;
      end;
    end);

  // Damage Mobj
  RegisterLineSpecial(ARegistry, 73,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      if args[0] <> 0 then
        P_DamageMobj(mo, nil, nil, args[0])
      else  // If arg1 is zero, then guarantee a kill
        P_DamageMobj(mo, nil, nil, 10000);
      result := true;
    end);

  {$IFDEF STRIFE}
  // Teleport_NewMap
  RegisterLineSpecial(ARegistry, 74,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      if side = 0 then
      begin // Only teleport when crossing the front side of a line
        if not ((mo <> nil) and (mo.player <> nil) and (Pplayer_t(mo.player).playerstate = PST_DEAD)) then // Players must be alive to teleport
        begin
          result := true;
          G_RiftExitLevel(args[0], args[1], args[2] * ANGLEMAX_DIV_256);
        end;
      end;
    end);
  {$ENDIF}

  // Teleport_EndGame
  RegisterLineSpecial(ARegistry, 75,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      if side = 0 then
      begin // Only teleport when crossing the front side of a line
        if not ((mo <> nil) and (mo.player <> nil) and (Pplayer_t(mo.player).playerstate = PST_DEAD)) then // Players must be alive to teleport
        begin
          result := true;
          G_ExitLevel{$IFDEF STRIFE}(args[0]){$ENDIF};
        end;
      end;
    end);

  // ACS_Execute
  RegisterLineSpecial(ARegistry, 80,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := P_StartACS(args[0], args[1], @args[2], mo, line, side);
    end);

  // ACS_Suspend
  RegisterLineSpecial(ARegistry, 81,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := P_SuspendACS(args[0], args[1]);
    end);

  // ACS_Terminate
  RegisterLineSpecial(ARegistry, 82,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := P_TerminateACS(args[0], args[1]);
    end);

  // ACS_LockedExecute
  RegisterLineSpecial(ARegistry, 83,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := P_StartLockedACS(line, args, mo, side);
    end);

  // Poly Rotate Left Override
  RegisterLineSpecial(ARegistry, 90,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_RotatePoly(line, args, 1, true);
    end);

  // Poly Rotate Right Override
  RegisterLineSpecial(ARegistry, 91,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_RotatePoly(line, args, -1, true);
    end);

  // Poly Move Override
  RegisterLineSpecial(ARegistry, 92,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_MovePoly(line, args, false, true);
    end);

  // Poly Move Times 8 Override
  RegisterLineSpecial(ARegistry, 93,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_MovePoly(line, args, true, true);
    end);

  // Build Pillar Crush
  RegisterLineSpecial(ARegistry, 94,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_BuildPillar(line, args, true);
    end);

  // Lower Floor and Ceiling
  RegisterLineSpecial(ARegistry, 95,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloorAndCeiling(line, args, false);
    end);

  // Raise Floor and Ceiling
  RegisterLineSpecial(ARegistry, 96,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_DoFloorAndCeiling(line, args, true);
    end);

  // Force Lightning
  RegisterLineSpecial(ARegistry, 109,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := true;
      P_ForceLightning(args[0]);
    end);

  // Light Raise by Value
  RegisterLineSpecial(ARegistry, 110,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_SpawnLight(line, args, LITE_RAISEBYVALUE);
    end);

  // Light Lower by Value
  RegisterLineSpecial(ARegistry, 111,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_SpawnLight(line, args, LITE_LOWERBYVALUE);
    end);

  // Light Change to Value
  RegisterLineSpecial(ARegistry, 112,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_SpawnLight(line, args, LITE_CHANGETOVALUE);
    end);

  // Light Fade
  RegisterLineSpecial(ARegistry, 113,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_SpawnLight(line, args, LITE_FADE);
    end);

  // Light Glow
  RegisterLineSpecial(ARegistry, 114,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_SpawnLight(line, args, LITE_GLOW);
    end);

  // Light Flicker
  RegisterLineSpecial(ARegistry, 115,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_SpawnLight(line, args, LITE_FLICKER);
    end);

  // Light Strobe
  RegisterLineSpecial(ARegistry, 116,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_SpawnLight(line, args, LITE_STROBE);
    end);

  // Quake Tremor
  RegisterLineSpecial(ARegistry, 120,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := U_LocalQuake(args, mo);
    end);

  {  129: // UsePuzzleItem
      begin
        result := EVH_LineSearchForPuzzleItem(line, args, mo);
      end;}

  // Thing_Activate
  RegisterLineSpecial(ARegistry, 130,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_ThingActivate(args[0]);
    end);

  // Thing_Deactivate
  RegisterLineSpecial(ARegistry, 131,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_ThingDeactivate(args[0]);
    end);

  // Thing_Remove
  RegisterLineSpecial(ARegistry, 132,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_ThingRemove(args[0]);
    end);

  // Thing_Destroy
  RegisterLineSpecial(ARegistry, 133,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_ThingDestroy(args[0]);
    end);

  // Thing_Projectile
  RegisterLineSpecial(ARegistry, 134,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_ThingProjectile(args, false);
    end);

  // Thing_Spawn
  RegisterLineSpecial(ARegistry, 135,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_ThingSpawn(args, true);
    end);

  // Thing_ProjectileGravity
  RegisterLineSpecial(ARegistry, 136,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_ThingProjectile(args, true);
    end);

  // Thing_SpawnNoFog
  RegisterLineSpecial(ARegistry, 137,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_ThingSpawn(args, false);
    end);

  // Floor_Waggle
  RegisterLineSpecial(ARegistry, 138,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_StartFloorWaggle(args[0], args[1], args[2], args[3], args[4]);
    end);

  // Sector_SoundChange
  RegisterLineSpecial(ARegistry, 140,
    function(args: PByteArray; line: Pline_t; side: integer; mo: Pmobj_t): boolean
    begin
      result := false;
      result := EVH_SectorSoundChange(args);
    end);

  // Line specials only processed during level initialization
  // 100: Scroll_Texture_Left
  // 101: Scroll_Texture_Right
  // 102: Scroll_Texture_Up
  // 103: Scroll_Texture_Down
  // 121: Line_SetIdentification

  // Inert Line specials
end;

//==============================================================================
//
// P_ExecuteLineSpecial
//
//==============================================================================
function P_ExecuteLineSpecial(special: integer; args: PByteArray; line: Pline_t;
  side: integer; mo: Pmobj_t): boolean;
var
  context: TSpecialContext;
begin
  if lineSpecials = nil then
    I_Error('P_ExecuteLineSpecial(): the specials were not configured (P_ConfigureLineSpecials)');
  context.Special := special;
  context.Args := System.PByte(args);
  context.Line := line;
  context.Side := side;
  context.Actor := mo;
  result := lineSpecials.Execute(context);
end;

//==============================================================================
//
// P_ConfigureLineSpecials
//
//==============================================================================
procedure P_ConfigureLineSpecials(const ARegistry: ISpecialRegistry);
begin
  P_RegisterLineSpecials(ARegistry);
  lineSpecials := ARegistry;
end;

//==============================================================================
//
// P_ActivateLine
//
//==============================================================================
function P_ActivateLine(line: Pline_t; mo: Pmobj_t; side: integer; activationType: integer): boolean;
var
  dorepeat: boolean;
  buttonSuccess: boolean;
  args: array[0..4] of Byte;
begin
  if not IsIntegerInRange(line.special and 1023, UDMF_SPECIAL_START, UDMF_SPECIAL_FINISH) then
  begin
    result := false;
    exit;
  end;

  if line.activators and activationType = 0 then
  begin
    result := false;
    exit;
  end;

  if (mo.player = nil) and (mo.flags and MF_MISSILE = 0) then
  begin

    if line.activators and (ULAC_MCROSS or ULAC_MPUSH) = 0 then
    begin // currently, monsters can only activate the MCROSS & MPUSH activation types
       result := false;
       exit;
    end;

    if line.flags and ML_SECRET <> 0 then
    begin
      result := false;  // never open secret doors
      exit;
    end;

  end;

  dorepeat := line.activators and ULAC_REPEAT <> 0;
  P_LineToArgs(line, @args);
  buttonSuccess := P_ExecuteLineSpecial(line.special, @args, line, side, mo);
  P_ArgsToLine(line, @args);

  if not dorepeat and buttonSuccess then
  begin // clear the special on non-retriggerable lines - keep generalized specials
    line.special := line.special and not 1023;
  end;

  if ((line.activators and ULAC_USE <> 0) or (line.activators and ULAC_IMPACT <> 0)) and buttonSuccess then
    P_ChangeSwitchTexture(line, dorepeat);

  result := true;
end;

//==============================================================================
//
// P_LineToArgs
//
//==============================================================================
procedure P_LineToArgs(line: Pline_t; const args: PByteArray);
begin
  args[0] := line.arg1;
  args[1] := line.arg2;
  args[2] := line.arg3;
  args[3] := line.arg4;
  args[4] := line.arg5;
  line.special := line.special - UDMF_SPECIAL_START;
end;

//==============================================================================
//
// P_ArgsToLine
//
//==============================================================================
procedure P_ArgsToLine(line: Pline_t; const args: PByteArray);
begin
  line.arg1 := args[0];
  line.arg2 := args[1];
  line.arg3 := args[2];
  line.arg4 := args[3];
  line.arg5 := args[4];
  line.special := line.special + UDMF_SPECIAL_START;
end;

//==============================================================================
//
// P_ExecuteActorSpecial
// Note: args are Integers
//
//==============================================================================
function P_ExecuteActorSpecial(special: integer; args: PIntegerArray; mo: Pmobj_t): boolean;
var
  bargs: packed array[0..4] of Byte;
begin
  bargs[0] := args[0];
  bargs[1] := args[1];
  bargs[2] := args[2];
  bargs[3] := args[3];
  bargs[4] := args[4];
  result := P_ExecuteLineSpecial(special - UDMF_SPECIAL_START, @bargs, nil, 0, mo);
  args[0] := bargs[0];
  args[1] := bargs[1];
  args[2] := bargs[2];
  args[3] := bargs[3];
  args[4] := bargs[4];
end;

end.
