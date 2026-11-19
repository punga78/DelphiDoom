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

  

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TUdmfSpecRoutines = class sealed
  public
    //==============================================================================
    //
    // P_FindSectorFromTag
    //
    //==============================================================================
    class function P_FindSectorFromTag(tag: integer; var start: integer): integer; static;

    //==============================================================================
    //
    // P_FindSectorFromTag2
    //
    //==============================================================================
    class function P_FindSectorFromTag2(tag: integer; var start: integer): integer; static;

    //==============================================================================
    //
    // P_FindLine
    //
    //==============================================================================
    class function P_FindLine(lineTag: integer; searchPosition: PInteger): Pline_t; static;

    //==============================================================================
    //
    // P_ConfigureLineSpecials
    //
    // Gives the registry that runs the line specials (the composition root creates it)
    //
    //==============================================================================
    class procedure P_ConfigureLineSpecials(const ARegistry: ISpecialRegistry); static;

    //==============================================================================
    //
    // P_ExecuteLineSpecial
    //
    //==============================================================================
    class function P_ExecuteLineSpecial(special: integer; args: PByteArray; line: Pline_t;
      side: integer; mo: Pmobj_t): boolean; static;

    //==============================================================================
    //
    // P_ActivateLine
    //
    //==============================================================================
    class function P_ActivateLine(line: Pline_t; mo: Pmobj_t; side: integer; activationType: integer): boolean; static;

    //==============================================================================
    //
    // P_LineToArgs
    //
    //==============================================================================
    class procedure P_LineToArgs(line: Pline_t; const args: PByteArray); static;

    //==============================================================================
    //
    // P_ArgsToLine
    //
    //==============================================================================
    class procedure P_ArgsToLine(line: Pline_t; const args: PByteArray); static;

    //==============================================================================
    //
    // P_ExecuteActorSpecial
    //
    //==============================================================================
    class function P_ExecuteActorSpecial(special: integer; args: PIntegerArray; mo: Pmobj_t): boolean; static;

    //==============================================================================
    //
    // P_ForceLightning
    //
    //==============================================================================
    class procedure P_ForceLightning(const tics: Integer = 0); static;

    //==============================================================================
    //
    // P_InitLightning
    //
    //==============================================================================
    class procedure P_InitLightning; static;

    //==============================================================================
    //
    // P_LightningFlash
    //
    //==============================================================================
    class procedure P_LightningFlash; static;
  end;

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
  DelphiDoom.Engine.World.MobjRules,
  p_setup,
  p_sounds,
  p_spec_h,
  DelphiDoom.Engine.World.SpecRules,
  p_spec,
  DelphiDoom.Engine.World.SwitchRules,
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

var
  lineSpecials: ISpecialRegistry;

type
  /// <summary>
  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines
  ///   (issue #185, wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TUdmfSpecLocalRoutines = class sealed
  public
    class function EVH_SectorSoundChange(args: PByteArray): boolean; static;
    class function CheckedLockedDoor(mo: Pmobj_t; lock: byte): boolean; static;
    class procedure P_LocalEarthQuakeEx(const actor: Pmobj_t; const tics: integer; const intensity: fixed_t; const maxtdist, maxddist: fixed_t); static;
    class function U_LocalQuake(args: PByteArray; actor: Pmobj_t): boolean; static;
    class procedure P_RegisterLineSpecials(const ARegistry: ISpecialRegistry); static;
    class function Special1(const AContext: TSpecialContext): boolean; static;
    class function Special2(const AContext: TSpecialContext): boolean; static;
    class function Special3(const AContext: TSpecialContext): boolean; static;
    class function Special4(const AContext: TSpecialContext): boolean; static;
    class function Special5(const AContext: TSpecialContext): boolean; static;
    class function Special6(const AContext: TSpecialContext): boolean; static;
    class function Special7(const AContext: TSpecialContext): boolean; static;
    class function Special8(const AContext: TSpecialContext): boolean; static;
    class function Special10(const AContext: TSpecialContext): boolean; static;
    class function Special11(const AContext: TSpecialContext): boolean; static;
    class function Special12(const AContext: TSpecialContext): boolean; static;
    class function Special13(const AContext: TSpecialContext): boolean; static;
    class function Special20(const AContext: TSpecialContext): boolean; static;
    class function Special21(const AContext: TSpecialContext): boolean; static;
    class function Special22(const AContext: TSpecialContext): boolean; static;
    class function Special23(const AContext: TSpecialContext): boolean; static;
    class function Special24(const AContext: TSpecialContext): boolean; static;
    class function Special25(const AContext: TSpecialContext): boolean; static;
    class function Special26(const AContext: TSpecialContext): boolean; static;
    class function Special27(const AContext: TSpecialContext): boolean; static;
    class function Special28(const AContext: TSpecialContext): boolean; static;
    class function Special29(const AContext: TSpecialContext): boolean; static;
    class function Special30(const AContext: TSpecialContext): boolean; static;
    class function Special31(const AContext: TSpecialContext): boolean; static;
    class function Special32(const AContext: TSpecialContext): boolean; static;
    class function Special35(const AContext: TSpecialContext): boolean; static;
    class function Special36(const AContext: TSpecialContext): boolean; static;
    class function Special40(const AContext: TSpecialContext): boolean; static;
    class function Special41(const AContext: TSpecialContext): boolean; static;
    class function Special42(const AContext: TSpecialContext): boolean; static;
    class function Special43(const AContext: TSpecialContext): boolean; static;
    class function Special44(const AContext: TSpecialContext): boolean; static;
    class function Special45(const AContext: TSpecialContext): boolean; static;
    class function Special46(const AContext: TSpecialContext): boolean; static;
    class function Special60(const AContext: TSpecialContext): boolean; static;
    class function Special61(const AContext: TSpecialContext): boolean; static;
    class function Special62(const AContext: TSpecialContext): boolean; static;
    class function Special63(const AContext: TSpecialContext): boolean; static;
    class function Special64(const AContext: TSpecialContext): boolean; static;
    class function Special65(const AContext: TSpecialContext): boolean; static;
    class function Special66(const AContext: TSpecialContext): boolean; static;
    class function Special67(const AContext: TSpecialContext): boolean; static;
    class function Special68(const AContext: TSpecialContext): boolean; static;
    class function Special69(const AContext: TSpecialContext): boolean; static;
    class function Special70(const AContext: TSpecialContext): boolean; static;
    class function Special71(const AContext: TSpecialContext): boolean; static;
    class function Special72(const AContext: TSpecialContext): boolean; static;
    class function Special73(const AContext: TSpecialContext): boolean; static;
{$IFDEF STRIFE}
    class function Special74(const AContext: TSpecialContext): boolean; static;
{$ENDIF}
    class function Special75(const AContext: TSpecialContext): boolean; static;
    class function Special80(const AContext: TSpecialContext): boolean; static;
    class function Special81(const AContext: TSpecialContext): boolean; static;
    class function Special82(const AContext: TSpecialContext): boolean; static;
    class function Special83(const AContext: TSpecialContext): boolean; static;
    class function Special90(const AContext: TSpecialContext): boolean; static;
    class function Special91(const AContext: TSpecialContext): boolean; static;
    class function Special92(const AContext: TSpecialContext): boolean; static;
    class function Special93(const AContext: TSpecialContext): boolean; static;
    class function Special94(const AContext: TSpecialContext): boolean; static;
    class function Special95(const AContext: TSpecialContext): boolean; static;
    class function Special96(const AContext: TSpecialContext): boolean; static;
    class function Special109(const AContext: TSpecialContext): boolean; static;
    class function Special110(const AContext: TSpecialContext): boolean; static;
    class function Special111(const AContext: TSpecialContext): boolean; static;
    class function Special112(const AContext: TSpecialContext): boolean; static;
    class function Special113(const AContext: TSpecialContext): boolean; static;
    class function Special114(const AContext: TSpecialContext): boolean; static;
    class function Special115(const AContext: TSpecialContext): boolean; static;
    class function Special116(const AContext: TSpecialContext): boolean; static;
    class function Special120(const AContext: TSpecialContext): boolean; static;
    class function Special130(const AContext: TSpecialContext): boolean; static;
    class function Special131(const AContext: TSpecialContext): boolean; static;
    class function Special132(const AContext: TSpecialContext): boolean; static;
    class function Special133(const AContext: TSpecialContext): boolean; static;
    class function Special134(const AContext: TSpecialContext): boolean; static;
    class function Special135(const AContext: TSpecialContext): boolean; static;
    class function Special136(const AContext: TSpecialContext): boolean; static;
    class function Special137(const AContext: TSpecialContext): boolean; static;
    class function Special138(const AContext: TSpecialContext): boolean; static;
    class function Special140(const AContext: TSpecialContext): boolean; static;
  end;

//==============================================================================
//
// P_FindSectorFromTag
//
//==============================================================================
class function TUdmfSpecRoutines.P_FindSectorFromTag(tag: integer; var start: integer): integer;
begin
  result := P_FindSectorFromTag2(tag, start);
end;

//==============================================================================
//
// P_FindSectorFromTag2
//
//==============================================================================
class function TUdmfSpecRoutines.P_FindSectorFromTag2(tag: integer; var start: integer): integer;
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
class function TUdmfSpecRoutines.P_FindLine(lineTag: integer; searchPosition: PInteger): Pline_t;
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
class procedure TUdmfSpecRoutines.P_LightningFlash;
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
    TSoundRoutines.S_StartSound(nil, SND_THUNDR);
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
      if (P_Random < 128) and (TTickState.LevelTime and 32 = 0) then
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
class procedure TUdmfSpecRoutines.P_ForceLightning(const tics: Integer = 0);
begin
  NextLightningFlash := tics;
end;

//==============================================================================
//
// P_InitLightning
//
//==============================================================================
class procedure TUdmfSpecRoutines.P_InitLightning;
var
  i: integer;
  secCount: integer;
begin
  if (TGameSession.GameMapInfo <> nil) and not TGameSession.GameMapInfo.lightning then
  begin
    LevelHasLightning := false;
    LightningFlash := 0;
    exit;
  end
  else if TGameSession.GameMapInfo = nil then
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
class function TUdmfSpecLocalRoutines.EVH_SectorSoundChange(args: PByteArray): boolean;
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
  while TUdmfSpecRoutines.P_FindSectorFromTag2(args[0], secNum) >= 0 do
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
class function TUdmfSpecLocalRoutines.CheckedLockedDoor(mo: Pmobj_t; lock: byte): boolean;
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
      TSoundRoutines.S_StartSound(mo, Ord(sfx_oof));
      {$ENDIF}
      {$IFDEF HERETIC}
      TSoundRoutines.S_StartSound(mo, Ord(sfx_plroof));
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
class procedure TUdmfSpecLocalRoutines.P_LocalEarthQuakeEx(const actor: Pmobj_t; const tics: integer; const intensity: fixed_t; const maxtdist, maxddist: fixed_t);
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
    TSoundRoutines.S_StartSound(actor, SND_QUAKE);

  for i := 0 to MAXPLAYERS - 1 do
    if TGameSession.PlayerInGame[i] then
    begin
      pmo := TGameSession.Players[i].mo;
      dist := TMapUtilRoutines.P_AproxDistance(actor.x - pmo.x, actor.y - pmo.y);
      dist := TMapUtilRoutines.P_AproxDistance(actor.z - pmo.z, dist); // 3d distance
      if dist <= maxtdist then
      begin
        if TGameSession.Players[i].quaketics < tics then
          TGameSession.Players[i].quaketics := tics;
        frac := FixedDiv(dist, maxtdist) * (FINEANGLES div 4);
        testintensity := FixedMul(finecosine[frac shr ANGLETOFINESHIFT], intensity); // JVAL: 20200508 - Curved
        if TGameSession.Players[i].quakeintensity < testintensity then
          TGameSession.Players[i].quakeintensity := testintensity;
      end;
      if (dist < maxddist) and (pmo.z <= pmo.floorz) then
      begin
        if P_Random < 50 then
          P_DamageMobj(TGameSession.Players[i].mo, nil, nil, (1 + (P_Random and 7)));
        // Thrust player around
        rnd := P_Random;
        an := pmo.angle + ANG1 * rnd;
        TCommonMovementActions.P_ThrustMobj(pmo, an, intensity div 2);
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
class function TUdmfSpecLocalRoutines.U_LocalQuake(args: PByteArray; actor: Pmobj_t): boolean;
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
  lastfound := @TTickState.ThinkerCap;
  repeat
    focus := TUdmfMobjRoutines.P_FindMobjFromTID(args[4], Pointer(lastfound));
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
// Special 1 - Poly Start Line
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special1(const AContext: TSpecialContext): boolean;
begin
  result := false;
end;

//==============================================================================
//
// Special 2 - Poly Rotate Left
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special2(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TPolyobjRoutines.EVH_RotatePoly(line, args, 1, false);
end;

//==============================================================================
//
// Special 3 - Poly Rotate Right
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special3(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TPolyobjRoutines.EVH_RotatePoly(line, args, -1, false);
end;

//==============================================================================
//
// Special 4 - Poly Move
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special4(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TPolyobjRoutines.EVH_MovePoly(line, args, false, false);
end;

//==============================================================================
//
// Special 5 - Poly Explicit Line:  Only used in initialization
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special5(const AContext: TSpecialContext): boolean;
begin
  result := false;
end;

//==============================================================================
//
// Special 6 - Poly Move Times 8
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special6(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TPolyobjRoutines.EVH_MovePoly(line, args, true, false);
end;

//==============================================================================
//
// Special 7 - Poly Door Swing
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special7(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TPolyobjRoutines.EVH_OpenPolyDoor(line, args, PODOOR_SWING);
end;

//==============================================================================
//
// Special 8 - Poly Door Slide
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special8(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TPolyobjRoutines.EVH_OpenPolyDoor(line, args, PODOOR_SLIDE);
end;

//==============================================================================
//
// Special 10 - Door Close
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special10(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfDoorRoutines.EVH_DoDoor(line, args, DREV_CLOSE);
end;

//==============================================================================
//
// Special 11 - Door Open
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special11(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  mo := Pmobj_t(AContext.Actor);
  result := false;
  if args[0] = 0 then
    result := TUdmfDoorRoutines.EVH_VerticalDoor(line, mo)
  else
    result := TUdmfDoorRoutines.EVH_DoDoor(line, args, DREV_OPEN);
end;

//==============================================================================
//
// Special 12 - Door Raise
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special12(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  mo := Pmobj_t(AContext.Actor);
  result := false;
  if args[0] = 0 then
    result := TUdmfDoorRoutines.EVH_VerticalDoor(line, mo)
  else
    result := TUdmfDoorRoutines.EVH_DoDoor(line, args, DREV_NORMAL);
end;

//==============================================================================
//
// Special 13 - Door Locked_Raise
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special13(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  mo := Pmobj_t(AContext.Actor);
  result := false;
  if TUdmfSpecLocalRoutines.CheckedLockedDoor(mo, args[3]) then
  begin
    if args[0] = 0 then
      result := TUdmfDoorRoutines.EVH_VerticalDoor(line, mo)
    else
      result := TUdmfDoorRoutines.EVH_DoDoor(line, args, DREV_NORMAL);
  end;
end;

//==============================================================================
//
// Special 20 - Floor Lower by Value
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special20(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_LOWERFLOORBYVALUE);
end;

//==============================================================================
//
// Special 21 - Floor Lower to Lowest
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special21(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_LOWERFLOORTOLOWEST);
end;

//==============================================================================
//
// Special 22 - Floor Lower to Nearest
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special22(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_LOWERFLOOR);
end;

//==============================================================================
//
// Special 23 - Floor Raise by Value
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special23(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_RAISEFLOORBYVALUE);
end;

//==============================================================================
//
// Special 24 - Floor Raise to Highest
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special24(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_RAISEFLOOR);
end;

//==============================================================================
//
// Special 25 - Floor Raise to Nearest
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special25(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_RAISEFLOORTONEAREST);
end;

//==============================================================================
//
// Special 26 - Stairs Build Down Normal
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special26(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_BuildStairs(line, args, -1, STAIRS_NORMAL);
end;

//==============================================================================
//
// Special 27 - Build Stairs Up Normal
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special27(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_BuildStairs(line, args, 1, STAIRS_NORMAL);
end;

//==============================================================================
//
// Special 28 - Floor Raise and Crush
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special28(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_RAISEFLOORCRUSH);
end;

//==============================================================================
//
// Special 29 - Build Pillar (no crushing)
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special29(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_BuildPillar(line, args, false);
end;

//==============================================================================
//
// Special 30 - Open Pillar
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special30(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_OpenPillar(line, args);
end;

//==============================================================================
//
// Special 31 - Stairs Build Down Sync
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special31(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_BuildStairs(line, args, -1, STAIRS_SYNC);
end;

//==============================================================================
//
// Special 32 - Build Stairs Up Sync
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special32(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_BuildStairs(line, args, 1, STAIRS_SYNC);
end;

//==============================================================================
//
// Special 35 - Raise Floor by Value Times 8
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special35(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_RAISEBYVALUETIMES8);
end;

//==============================================================================
//
// Special 36 - Lower Floor by Value Times 8
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special36(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_LOWERBYVALUETIMES8);
end;

//==============================================================================
//
// Special 40 - Ceiling Lower by Value
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special40(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfCeilingRoutines.EVH_DoCeiling(line, args, CLEV_LOWERBYVALUE);
end;

//==============================================================================
//
// Special 41 - Ceiling Raise by Value
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special41(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfCeilingRoutines.EVH_DoCeiling(line, args, CLEV_RAISEBYVALUE);
end;

//==============================================================================
//
// Special 42 - Ceiling Crush and Raise
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special42(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfCeilingRoutines.EVH_DoCeiling(line, args, CLEV_CRUSHANDRAISE);
end;

//==============================================================================
//
// Special 43 - Ceiling Lower and Crush
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special43(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfCeilingRoutines.EVH_DoCeiling(line, args, CLEV_LOWERANDCRUSH);
end;

//==============================================================================
//
// Special 44 - Ceiling Crush Stop
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special44(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfCeilingRoutines.EVH_CeilingCrushStop(line, args);
end;

//==============================================================================
//
// Special 45 - Ceiling Crush Raise and Stay
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special45(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfCeilingRoutines.EVH_DoCeiling(line, args, CLEV_CRUSHRAISEANDSTAY);
end;

//==============================================================================
//
// Special 46 - Floor Crush Stop
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special46(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_FloorCrushStop(line, args);
end;

//==============================================================================
//
// Special 60 - Plat Perpetual Raise
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special60(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfPlatRoutines.EVH_DoPlat(line, args, PLAT_PERPETUALRAISE, 0);
end;

//==============================================================================
//
// Special 61 - Plat Stop
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special61(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := false;
  TUdmfPlatRoutines.EVH_StopPlat(line, args);
end;

//==============================================================================
//
// Special 62 - Plat Down-Wait-Up-Stay
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special62(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfPlatRoutines.EVH_DoPlat(line, args, PLAT_DOWNWAITUPSTAY, 0);
end;

//==============================================================================
//
// Special 63 - Plat Down-by-Value*8-Wait-Up-Stay
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special63(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfPlatRoutines.EVH_DoPlat(line, args, PLAT_DOWNBYVALUEWAITUPSTAY, 0);
end;

//==============================================================================
//
// Special 64 - Plat Up-Wait-Down-Stay
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special64(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfPlatRoutines.EVH_DoPlat(line, args, PLAT_UPWAITDOWNSTAY, 0);
end;

//==============================================================================
//
// Special 65 - Plat Up-by-Value*8-Wait-Down-Stay
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special65(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfPlatRoutines.EVH_DoPlat(line, args, PLAT_UPBYVALUEWAITDOWNSTAY, 0);
end;

//==============================================================================
//
// Special 66 - Floor Lower Instant * 8
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special66(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_LOWERTIMES8INSTANT);
end;

//==============================================================================
//
// Special 67 - Floor Raise Instant * 8
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special67(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_RAISETIMES8INSTANT);
end;

//==============================================================================
//
// Special 68 - Floor Move to Value * 8
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special68(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloor(line, args, FLEV_MOVETOVALUETIMES8);
end;

//==============================================================================
//
// Special 69 - Ceiling Move to Value * 8
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special69(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfCeilingRoutines.EVH_DoCeiling(line, args, CLEV_MOVETOVALUETIMES8);
end;

//==============================================================================
//
// Special 70 - Teleport
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special70(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  side: integer;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  side := AContext.Side;
  mo := Pmobj_t(AContext.Actor);
  result := false;
  if side = 0 then
  begin // Only teleport when crossing the front side of a line
    result := TUdmfTeleportRoutines.EVH_Teleport(args[0], mo, true);
  end;
end;

//==============================================================================
//
// Special 71 - Teleport, no fog
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special71(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  side: integer;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  side := AContext.Side;
  mo := Pmobj_t(AContext.Actor);
  result := false;
  if side = 0 then
  begin // Only teleport when crossing the front side of a line
    result := TUdmfTeleportRoutines.EVH_Teleport(args[0], mo, false);
  end;
end;

//==============================================================================
//
// Special 72 - Thrust Mobj
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special72(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  side: integer;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  side := AContext.Side;
  mo := Pmobj_t(AContext.Actor);
  result := false;
  if side = 0 then // Only thrust on side 0
  begin
    TCommonMovementActions.P_ThrustMobj(mo, args[0] * (ANG90 div 64), args[1] * FRACUNIT);
    result := true;
  end;
end;

//==============================================================================
//
// Special 73 - Damage Mobj
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special73(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  mo := Pmobj_t(AContext.Actor);
  result := false;
  if args[0] <> 0 then
    P_DamageMobj(mo, nil, nil, args[0])
  else  // If arg1 is zero, then guarantee a kill
    P_DamageMobj(mo, nil, nil, 10000);
  result := true;
end;

{$IFDEF STRIFE}
//==============================================================================
//
// Special 74 - Teleport_NewMap
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special74(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  side: integer;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  side := AContext.Side;
  mo := Pmobj_t(AContext.Actor);
  result := false;
  if side = 0 then
  begin // Only teleport when crossing the front side of a line
    if not ((mo <> nil) and (mo.player <> nil) and (Pplayer_t(mo.player).playerstate = PST_DEAD)) then // Players must be alive to teleport
    begin
      result := true;
      G_RiftExitLevel(args[0], args[1], args[2] * ANGLEMAX_DIV_256);
    end;
  end;
end;
{$ENDIF}

//==============================================================================
//
// Special 75 - Teleport_EndGame
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special75(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  side: integer;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  side := AContext.Side;
  mo := Pmobj_t(AContext.Actor);
  result := false;
  if side = 0 then
  begin // Only teleport when crossing the front side of a line
    if not ((mo <> nil) and (mo.player <> nil) and (Pplayer_t(mo.player).playerstate = PST_DEAD)) then // Players must be alive to teleport
    begin
      result := true;
      G_ExitLevel{$IFDEF STRIFE}(args[0]){$ENDIF};
    end;
  end;
end;

//==============================================================================
//
// Special 80 - ACS_Execute
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special80(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
  side: integer;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  side := AContext.Side;
  mo := Pmobj_t(AContext.Actor);
  result := P_StartACS(args[0], args[1], @args[2], mo, line, side);
end;

//==============================================================================
//
// Special 81 - ACS_Suspend
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special81(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := P_SuspendACS(args[0], args[1]);
end;

//==============================================================================
//
// Special 82 - ACS_Terminate
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special82(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := P_TerminateACS(args[0], args[1]);
end;

//==============================================================================
//
// Special 83 - ACS_LockedExecute
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special83(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
  side: integer;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  side := AContext.Side;
  mo := Pmobj_t(AContext.Actor);
  result := P_StartLockedACS(line, args, mo, side);
end;

//==============================================================================
//
// Special 90 - Poly Rotate Left Override
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special90(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TPolyobjRoutines.EVH_RotatePoly(line, args, 1, true);
end;

//==============================================================================
//
// Special 91 - Poly Rotate Right Override
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special91(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TPolyobjRoutines.EVH_RotatePoly(line, args, -1, true);
end;

//==============================================================================
//
// Special 92 - Poly Move Override
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special92(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TPolyobjRoutines.EVH_MovePoly(line, args, false, true);
end;

//==============================================================================
//
// Special 93 - Poly Move Times 8 Override
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special93(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TPolyobjRoutines.EVH_MovePoly(line, args, true, true);
end;

//==============================================================================
//
// Special 94 - Build Pillar Crush
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special94(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_BuildPillar(line, args, true);
end;

//==============================================================================
//
// Special 95 - Lower Floor and Ceiling
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special95(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloorAndCeiling(line, args, false);
end;

//==============================================================================
//
// Special 96 - Raise Floor and Ceiling
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special96(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfFloorRoutines.EVH_DoFloorAndCeiling(line, args, true);
end;

//==============================================================================
//
// Special 109 - Force Lightning
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special109(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := true;
  TUdmfSpecRoutines.P_ForceLightning(args[0]);
end;

//==============================================================================
//
// Special 110 - Light Raise by Value
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special110(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfLightRoutines.EVH_SpawnLight(line, args, LITE_RAISEBYVALUE);
end;

//==============================================================================
//
// Special 111 - Light Lower by Value
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special111(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfLightRoutines.EVH_SpawnLight(line, args, LITE_LOWERBYVALUE);
end;

//==============================================================================
//
// Special 112 - Light Change to Value
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special112(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfLightRoutines.EVH_SpawnLight(line, args, LITE_CHANGETOVALUE);
end;

//==============================================================================
//
// Special 113 - Light Fade
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special113(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfLightRoutines.EVH_SpawnLight(line, args, LITE_FADE);
end;

//==============================================================================
//
// Special 114 - Light Glow
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special114(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfLightRoutines.EVH_SpawnLight(line, args, LITE_GLOW);
end;

//==============================================================================
//
// Special 115 - Light Flicker
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special115(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfLightRoutines.EVH_SpawnLight(line, args, LITE_FLICKER);
end;

//==============================================================================
//
// Special 116 - Light Strobe
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special116(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  line: Pline_t;
begin
  args := PByteArray(AContext.Args);
  line := Pline_t(AContext.Line);
  result := TUdmfLightRoutines.EVH_SpawnLight(line, args, LITE_STROBE);
end;

//==============================================================================
//
// Special 120 - Quake Tremor
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special120(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
  mo: Pmobj_t;
begin
  args := PByteArray(AContext.Args);
  mo := Pmobj_t(AContext.Actor);
  result := TUdmfSpecLocalRoutines.U_LocalQuake(args, mo);
end;

//==============================================================================
//
// Special 130 - Thing_Activate
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special130(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := TUdmfThingRoutines.EVH_ThingActivate(args[0]);
end;

//==============================================================================
//
// Special 131 - Thing_Deactivate
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special131(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := TUdmfThingRoutines.EVH_ThingDeactivate(args[0]);
end;

//==============================================================================
//
// Special 132 - Thing_Remove
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special132(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := TUdmfThingRoutines.EVH_ThingRemove(args[0]);
end;

//==============================================================================
//
// Special 133 - Thing_Destroy
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special133(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := TUdmfThingRoutines.EVH_ThingDestroy(args[0]);
end;

//==============================================================================
//
// Special 134 - Thing_Projectile
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special134(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := TUdmfThingRoutines.EVH_ThingProjectile(args, false);
end;

//==============================================================================
//
// Special 135 - Thing_Spawn
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special135(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := TUdmfThingRoutines.EVH_ThingSpawn(args, true);
end;

//==============================================================================
//
// Special 136 - Thing_ProjectileGravity
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special136(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := TUdmfThingRoutines.EVH_ThingProjectile(args, true);
end;

//==============================================================================
//
// Special 137 - Thing_SpawnNoFog
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special137(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := TUdmfThingRoutines.EVH_ThingSpawn(args, false);
end;

//==============================================================================
//
// Special 138 - Floor_Waggle
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special138(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := TUdmfFloorRoutines.EVH_StartFloorWaggle(args[0], args[1], args[2], args[3], args[4]);
end;

//==============================================================================
//
// Special 140 - Sector_SoundChange
//
//==============================================================================
class function TUdmfSpecLocalRoutines.Special140(const AContext: TSpecialContext): boolean;
var
  args: PByteArray;
begin
  args := PByteArray(AContext.Args);
  result := TUdmfSpecLocalRoutines.EVH_SectorSoundChange(args);
end;

//==============================================================================
//
// P_RegisterLineSpecials
//
//==============================================================================
class procedure TUdmfSpecLocalRoutines.P_RegisterLineSpecials(const ARegistry: ISpecialRegistry);
begin
  ARegistry.Register(1, Special1); // Poly Start Line
  ARegistry.Register(2, Special2); // Poly Rotate Left
  ARegistry.Register(3, Special3); // Poly Rotate Right
  ARegistry.Register(4, Special4); // Poly Move
  ARegistry.Register(5, Special5); // Poly Explicit Line:  Only used in initialization
  ARegistry.Register(6, Special6); // Poly Move Times 8
  ARegistry.Register(7, Special7); // Poly Door Swing
  ARegistry.Register(8, Special8); // Poly Door Slide
  ARegistry.Register(10, Special10); // Door Close
  ARegistry.Register(11, Special11); // Door Open
  ARegistry.Register(12, Special12); // Door Raise
  ARegistry.Register(13, Special13); // Door Locked_Raise
  ARegistry.Register(20, Special20); // Floor Lower by Value
  ARegistry.Register(21, Special21); // Floor Lower to Lowest
  ARegistry.Register(22, Special22); // Floor Lower to Nearest
  ARegistry.Register(23, Special23); // Floor Raise by Value
  ARegistry.Register(24, Special24); // Floor Raise to Highest
  ARegistry.Register(25, Special25); // Floor Raise to Nearest
  ARegistry.Register(26, Special26); // Stairs Build Down Normal
  ARegistry.Register(27, Special27); // Build Stairs Up Normal
  ARegistry.Register(28, Special28); // Floor Raise and Crush
  ARegistry.Register(29, Special29); // Build Pillar (no crushing)
  ARegistry.Register(30, Special30); // Open Pillar
  ARegistry.Register(31, Special31); // Stairs Build Down Sync
  ARegistry.Register(32, Special32); // Build Stairs Up Sync
  ARegistry.Register(35, Special35); // Raise Floor by Value Times 8
  ARegistry.Register(36, Special36); // Lower Floor by Value Times 8
  ARegistry.Register(40, Special40); // Ceiling Lower by Value
  ARegistry.Register(41, Special41); // Ceiling Raise by Value
  ARegistry.Register(42, Special42); // Ceiling Crush and Raise
  ARegistry.Register(43, Special43); // Ceiling Lower and Crush
  ARegistry.Register(44, Special44); // Ceiling Crush Stop
  ARegistry.Register(45, Special45); // Ceiling Crush Raise and Stay
  ARegistry.Register(46, Special46); // Floor Crush Stop
  ARegistry.Register(60, Special60); // Plat Perpetual Raise
  ARegistry.Register(61, Special61); // Plat Stop
  ARegistry.Register(62, Special62); // Plat Down-Wait-Up-Stay
  ARegistry.Register(63, Special63); // Plat Down-by-Value*8-Wait-Up-Stay
  ARegistry.Register(64, Special64); // Plat Up-Wait-Down-Stay
  ARegistry.Register(65, Special65); // Plat Up-by-Value*8-Wait-Down-Stay
  ARegistry.Register(66, Special66); // Floor Lower Instant * 8
  ARegistry.Register(67, Special67); // Floor Raise Instant * 8
  ARegistry.Register(68, Special68); // Floor Move to Value * 8
  ARegistry.Register(69, Special69); // Ceiling Move to Value * 8
  ARegistry.Register(70, Special70); // Teleport
  ARegistry.Register(71, Special71); // Teleport, no fog
  ARegistry.Register(72, Special72); // Thrust Mobj
  ARegistry.Register(73, Special73); // Damage Mobj
{$IFDEF STRIFE}
  ARegistry.Register(74, Special74); // Teleport_NewMap
{$ENDIF}
  ARegistry.Register(75, Special75); // Teleport_EndGame
  ARegistry.Register(80, Special80); // ACS_Execute
  ARegistry.Register(81, Special81); // ACS_Suspend
  ARegistry.Register(82, Special82); // ACS_Terminate
  ARegistry.Register(83, Special83); // ACS_LockedExecute
  ARegistry.Register(90, Special90); // Poly Rotate Left Override
  ARegistry.Register(91, Special91); // Poly Rotate Right Override
  ARegistry.Register(92, Special92); // Poly Move Override
  ARegistry.Register(93, Special93); // Poly Move Times 8 Override
  ARegistry.Register(94, Special94); // Build Pillar Crush
  ARegistry.Register(95, Special95); // Lower Floor and Ceiling
  ARegistry.Register(96, Special96); // Raise Floor and Ceiling
  ARegistry.Register(109, Special109); // Force Lightning
  ARegistry.Register(110, Special110); // Light Raise by Value
  ARegistry.Register(111, Special111); // Light Lower by Value
  ARegistry.Register(112, Special112); // Light Change to Value
  ARegistry.Register(113, Special113); // Light Fade
  ARegistry.Register(114, Special114); // Light Glow
  ARegistry.Register(115, Special115); // Light Flicker
  ARegistry.Register(116, Special116); // Light Strobe
  ARegistry.Register(120, Special120); // Quake Tremor
  ARegistry.Register(130, Special130); // Thing_Activate
  ARegistry.Register(131, Special131); // Thing_Deactivate
  ARegistry.Register(132, Special132); // Thing_Remove
  ARegistry.Register(133, Special133); // Thing_Destroy
  ARegistry.Register(134, Special134); // Thing_Projectile
  ARegistry.Register(135, Special135); // Thing_Spawn
  ARegistry.Register(136, Special136); // Thing_ProjectileGravity
  ARegistry.Register(137, Special137); // Thing_SpawnNoFog
  ARegistry.Register(138, Special138); // Floor_Waggle
  ARegistry.Register(140, Special140); // Sector_SoundChange

  // 129: UsePuzzleItem (TSpecRoutines.EVH_LineSearchForPuzzleItem) is not registered

  // Line specials only processed during level initialization
  // 100: Scroll_Texture_Left
  // 101: Scroll_Texture_Right
  // 102: Scroll_Texture_Up
  // 103: Scroll_Texture_Down
  // 121: Line_SetIdentification
end;

//==============================================================================
//
// P_ExecuteLineSpecial
//
//==============================================================================
class function TUdmfSpecRoutines.P_ExecuteLineSpecial(special: integer; args: PByteArray; line: Pline_t;
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
class procedure TUdmfSpecRoutines.P_ConfigureLineSpecials(const ARegistry: ISpecialRegistry);
begin
  TUdmfSpecLocalRoutines.P_RegisterLineSpecials(ARegistry);
  lineSpecials := ARegistry;
end;

//==============================================================================
//
// P_ActivateLine
//
//==============================================================================
class function TUdmfSpecRoutines.P_ActivateLine(line: Pline_t; mo: Pmobj_t; side: integer; activationType: integer): boolean;
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
    TSwitchRoutines.P_ChangeSwitchTexture(line, dorepeat);

  result := true;
end;

//==============================================================================
//
// P_LineToArgs
//
//==============================================================================
class procedure TUdmfSpecRoutines.P_LineToArgs(line: Pline_t; const args: PByteArray);
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
class procedure TUdmfSpecRoutines.P_ArgsToLine(line: Pline_t; const args: PByteArray);
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
class function TUdmfSpecRoutines.P_ExecuteActorSpecial(special: integer; args: PIntegerArray; mo: Pmobj_t): boolean;
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
