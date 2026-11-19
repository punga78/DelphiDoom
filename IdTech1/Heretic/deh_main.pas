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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit deh_main;

interface

// JVAL
// Support for DeHackEd patch files
// Support for both DEH and BEX files

uses
  d_delphi,
  DelphiDoom.Dehacked.GameData,
  info_h;

// A patch is read and applied by TEngineDehackedApplier
// (DelphiDoom.Engine.Dehacked.Applier); here are the tables of the names that it
// and the table export use

type
  deh_string_t = record
    pstr: PString;
    name: string[24];
  end;
  deh_string_tArray = array[0..$FFFF] of deh_string_t;
  Pdeh_string_tArray = ^deh_string_tArray;

  deh_strings_t = record
    numstrings: integer;
    realnumstrings: integer;
    _array: Pdeh_string_tArray;
  end;
  Pdeh_strings_t = ^deh_strings_t;

var
  mobj_tokens: TDTextList;
  mobj_flags: TDTextList;
  mobj_flags2: TDTextList;
  mobj_flags_ex: TDTextList;
  mobj_flags2_ex: TDTextList;
  mobj_flags3_ex: TDTextList;
  mobj_flags4_ex: TDTextList;
  mobj_flags5_ex: TDTextList;
  mobj_flags6_ex: TDTextList;
  mobj_flags_mbf21: TDTextList; // MBF21
  state_tokens: TDTextList;
  state_flags_ex: TDTextList;
  state_flags_mbf21: TDTextList;  // MBF21
  ammo_tokens: TDTextList;
  weapon_tokens: TDTextList;
  weapon_flags_mbf21: TDTextList; // MBF21
  sound_tokens: TDTextList;
  renderstyle_tokens: TDTextList;
  misc_tokens: TDTextList;
  weapontype_tokens: TDTextList;
  ammotype_tokens: TDTextList;
  // MBF21
  infighting_groups: TDTextList;
  projectile_groups: TDTextList;
  splash_groups: TDTextList;

  deh_strings: deh_strings_t;

var
  ismbf21: boolean = false; // MBF21

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TDehMainRoutines = class sealed
  public
    //==============================================================================
    //
    // DEH_ConfigureTokens
    // Gives the names of the fields and of the flags of the game (TDehackedGames.DataOf: ComposeEngine);
    // DEH_Init fills the lists of names from them
    //
    //==============================================================================
    class procedure DEH_ConfigureTokens(const AData: TDehackedGameData); static;

    //==============================================================================
    //
    // DEH_Init
    //
    //==============================================================================
    class procedure DEH_Init; static;

    //==============================================================================
    //
    // DEH_ShutDown
    //
    //==============================================================================
    class procedure DEH_ShutDown; static;
  end;


implementation

uses
  TypInfo,
  DelphiDoom.Engine.Dehacked.TokenLists,
  i_system,
  c_cmds,
  doomdef,
  deh_base,
  h_strings,
  f_finale,
  g_game,
  hu_stuff,
  info_common,
  m_argv,
  m_fixed,
  ps_main,
  p_mobj,
  p_mobj_h,
  p_enemy,
  DelphiDoom.Engine.World.EnemyRules,
  p_extra,
  p_common,
  p_pspr,
  DelphiDoom.Engine.World.PspriteRules,
  DelphiDoom.Engine.World.SpecialRespawn,
  p_musinfo,
  p_sounds,
  p_simpledialog,
  psi_overlay,
  v_data;

type
  /// <summary>
  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines
  ///   (issue #185, wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TDehMainLocalRoutines = class sealed
  public
    class procedure DEH_AddString(deh_strings: Pdeh_strings_t; pstr: PString; const name: string); static;
  end;

//==============================================================================
//
// DEH_AddString
//
//==============================================================================
class procedure TDehMainLocalRoutines.DEH_AddString(deh_strings: Pdeh_strings_t; pstr: PString; const name: string);
begin
  if deh_strings.numstrings = deh_strings.realnumstrings then
  begin
    deh_strings.realnumstrings := deh_strings.realnumstrings + 64;
    realloc(
      pointer(deh_strings._array),
      deh_strings.numstrings * SizeOf(deh_string_t),
      deh_strings.realnumstrings * SizeOf(deh_string_t));
  end;

  deh_strings._array[deh_strings.numstrings].pstr := pstr;
  deh_strings._array[deh_strings.numstrings].name := name;
  inc(deh_strings.numstrings);
end;

var
  // given by the composition root (DEH_ConfigureTokens)
  deh_tokens: TDehackedGameData;
  deh_tokens_given: boolean = false;

//==============================================================================
//
// DEH_ConfigureTokens
//
//==============================================================================
class procedure TDehMainRoutines.DEH_ConfigureTokens(const AData: TDehackedGameData);
begin
  deh_tokens := AData;
  deh_tokens_given := true;
end;

var
  deh_initialized: boolean = false;

//==============================================================================
//
// DEH_Init
//
// JVAL
// Initializing DEH tokens
//
//==============================================================================
class procedure TDehMainRoutines.DEH_Init;
var
  i, j, k: integer;
begin
  if deh_initialized then
    exit;

  if not deh_tokens_given then
    I_Error('DEH_Init(): the names of the tables were not given (DEH_ConfigureTokens was not called)');

  deh_initialized := true;

  mobj_tokens := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_tokens, deh_tokens.ThingFields);



  mobj_flags := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_flags, deh_tokens.MobjFlags);


  mobj_flags2 := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_flags2, deh_tokens.MobjFlags2);


  mobj_flags_ex := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_flags_ex, deh_tokens.MobjFlagsEx);


  mobj_flags2_ex := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_flags2_ex, deh_tokens.MobjFlags2Ex);
  // JVAL: VERSION 204
  // JVAL: VERSION 205


  mobj_flags3_ex := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_flags3_ex, deh_tokens.MobjFlags3Ex);
  // JVAL: VERSION 206
  // JVAL: VERSION 207


  mobj_flags4_ex := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_flags4_ex, deh_tokens.MobjFlags4Ex);


  mobj_flags5_ex := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_flags5_ex, deh_tokens.MobjFlags5Ex);


  mobj_flags6_ex := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_flags6_ex, deh_tokens.MobjFlags6Ex);


  // MBF21
  mobj_flags_mbf21 := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_flags_mbf21, deh_tokens.MobjFlagsMbf21);


  infighting_groups := TDTextList.Create;
  infighting_groups.Add('IG_DEFAULT');

  projectile_groups := TDTextList.Create;
  projectile_groups.Add('PG_DEFAULT');
  projectile_groups.Add('PG_BARON');

  splash_groups := TDTextList.Create;
  splash_groups.Add('SG_DEFAULT');

  // JVAL: 20200330 - State flags
  state_flags_ex := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(state_flags_ex, deh_tokens.StateFlagsEx);

  state_flags_mbf21 := TDTextList.Create; // MBF21
  TEngineDehackedTokenLists.Fill(state_flags_mbf21, deh_tokens.StateFlagsMbf21);

  state_tokens := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(state_tokens, deh_tokens.FrameFields);

  DEH_AddNullAction;

  DEH_AddAction(@THereticMonsterActions.A_AccTeleGlitter, 'A_AccTeleGlitter()'); // 1
  DEH_AddAction(@THereticMonsterActions.A_AddPlayerCorpse, 'A_AddPlayerCorpse()'); // 2
  DEH_AddAction(@THereticWeaponActions.A_AddPlayerRain, 'A_AddPlayerRain()'); // 3
  DEH_AddAction(@THereticWeaponActions.A_BeakAttackPL1, 'A_BeakAttackPL1()'); // 4
  DEH_AddAction(@THereticWeaponActions.A_BeakAttackPL2, 'A_BeakAttackPL2()'); // 5
  DEH_AddAction(@THereticWeaponActions.A_BeakRaise, 'A_BeakRaise()'); // 6
  DEH_AddAction(@THereticWeaponActions.A_BeakReady, 'A_BeakReady()'); // 7
  DEH_AddAction(@THereticMonsterActions.A_BeastAttack, 'A_BeastAttack()'); // 8
  DEH_AddAction(@THereticMonsterActions.A_BeastPuff, 'A_BeastPuff()'); // 9
  DEH_AddAction(@THereticMonsterActions.A_BlueSpark, 'A_BlueSpark()'); // 10
  DEH_AddAction(@THereticWeaponActions.A_BoltSpark, 'A_BoltSpark()'); // 11
  DEH_AddAction(@THereticMonsterActions.A_BossDeath, 'A_BossDeath()'); // 12
  DEH_AddAction(@TMonsterBaseActions.A_Chase, 'A_Chase()'); // 13
  DEH_AddAction(@THereticMonsterActions.A_CheckBurnGone, 'A_CheckBurnGone()'); // 14
  DEH_AddAction(@THereticMonsterActions.A_CheckSkullDone, 'A_CheckSkullDone()'); // 15
  DEH_AddAction(@THereticMonsterActions.A_CheckSkullFloor, 'A_CheckSkullFloor()'); // 16
  DEH_AddAction(@THereticMonsterActions.A_ChicAttack, 'A_ChicAttack()'); // 17
  DEH_AddAction(@THereticMonsterActions.A_ChicChase, 'A_ChicChase()'); // 18
  DEH_AddAction(@THereticMonsterActions.A_ChicLook, 'A_ChicLook()'); // 19
  DEH_AddAction(@THereticMonsterActions.A_ChicPain, 'A_ChicPain()'); // 20
  DEH_AddAction(@THereticMonsterActions.A_ClinkAttack, 'A_ClinkAttack()'); // 21
  DEH_AddAction(@THereticMonsterActions.A_ContMobjSound, 'A_ContMobjSound()'); // 22
  DEH_AddAction(@THereticWeaponActions.A_DeathBallImpact, 'A_DeathBallImpact()'); // 23
  DEH_AddAction(@THereticMonsterActions.A_DripBlood, 'A_DripBlood()'); // 24
  DEH_AddAction(@THereticMonsterActions.A_ESound, 'A_ESound()'); // 25
  DEH_AddAction(@THereticMonsterActions.A_Explode, 'A_Explode()'); // 26
  DEH_AddAction(@A_FaceTarget, 'A_FaceTarget()'); // 27
  DEH_AddAction(@THereticMonsterActions.A_Feathers, 'A_Feathers()'); // 28
  DEH_AddAction(@THereticWeaponActions.A_FireBlasterPL1, 'A_FireBlasterPL1()'); // 29
  DEH_AddAction(@THereticWeaponActions.A_FireBlasterPL2, 'A_FireBlasterPL2()'); // 30
  DEH_AddAction(@THereticWeaponActions.A_FireCrossbowPL1, 'A_FireCrossbowPL1()'); // 31
  DEH_AddAction(@THereticWeaponActions.A_FireCrossbowPL2, 'A_FireCrossbowPL2()'); // 32
  DEH_AddAction(@THereticWeaponActions.A_FireGoldWandPL1, 'A_FireGoldWandPL1()'); // 33
  DEH_AddAction(@THereticWeaponActions.A_FireGoldWandPL2, 'A_FireGoldWandPL2()'); // 34
  DEH_AddAction(@THereticWeaponActions.A_FireMacePL1, 'A_FireMacePL1()'); // 35
  DEH_AddAction(@THereticWeaponActions.A_FireMacePL2, 'A_FireMacePL2()'); // 36
  DEH_AddAction(@THereticWeaponActions.A_FirePhoenixPL1, 'A_FirePhoenixPL1()'); // 37
  DEH_AddAction(@THereticWeaponActions.A_FirePhoenixPL2, 'A_FirePhoenixPL2()'); // 38
  DEH_AddAction(@THereticWeaponActions.A_FireSkullRodPL1, 'A_FireSkullRodPL1()'); // 39
  DEH_AddAction(@THereticWeaponActions.A_FireSkullRodPL2, 'A_FireSkullRodPL2()'); // 40
  DEH_AddAction(@THereticWeaponActions.A_FlameEnd, 'A_FlameEnd()'); // 41
  DEH_AddAction(@THereticMonsterActions.A_FlameSnd, 'A_FlameSnd()'); // 42
  DEH_AddAction(@THereticWeaponActions.A_FloatPuff, 'A_FloatPuff()'); // 43
  DEH_AddAction(@THereticMonsterActions.A_FreeTargMobj, 'A_FreeTargMobj()'); // 44
  DEH_AddAction(@THereticWeaponActions.A_GauntletAttack, 'A_GauntletAttack()'); // 45
  DEH_AddAction(@THereticMonsterActions.A_GenWizard, 'A_GenWizard()'); // 46
  DEH_AddAction(@TCommonAppearanceActions.A_GhostOff, 'A_GhostOff()'); // 47
  DEH_AddAction(@THereticMonsterActions.A_HeadAttack, 'A_HeadAttack()'); // 48
  DEH_AddAction(@THereticMonsterActions.A_HeadFireGrow, 'A_HeadFireGrow()'); // 49
  DEH_AddAction(@THereticMonsterActions.A_HeadIceImpact, 'A_HeadIceImpact()'); // 50
  DEH_AddAction(@THereticWeaponActions.A_HideInCeiling, 'A_HideInCeiling()'); // 51
  DEH_AddAction(@THereticMonsterActions.A_HideThing, 'A_HideThing()'); // 52
  DEH_AddAction(@THereticMonsterActions.A_ImpDeath, 'A_ImpDeath()'); // 53
  DEH_AddAction(@THereticMonsterActions.A_ImpExplode, 'A_ImpExplode()'); // 54
  DEH_AddAction(@THereticMonsterActions.A_ImpMeAttack, 'A_ImpMeAttack()'); // 55
  DEH_AddAction(@THereticMonsterActions.A_ImpMsAttack, 'A_ImpMsAttack()'); // 56
  DEH_AddAction(@THereticMonsterActions.A_ImpMsAttack2, 'A_ImpMsAttack2()'); // 57
  DEH_AddAction(@THereticMonsterActions.A_ImpXDeath1, 'A_ImpXDeath1()'); // 58
  DEH_AddAction(@THereticMonsterActions.A_ImpXDeath2, 'A_ImpXDeath2()'); // 59
  DEH_AddAction(@THereticMonsterActions.A_InitKeyGizmo, 'A_InitKeyGizmo()'); // 60
  DEH_AddAction(@THereticWeaponActions.A_InitPhoenixPL2, 'A_InitPhoenixPL2()'); // 61
  DEH_AddAction(@THereticMonsterActions.A_KnightAttack, 'A_KnightAttack()'); // 62
  DEH_AddAction(@A_Light0, 'A_Light0()'); // 63
  DEH_AddAction(@THereticMonsterActions.A_Look, 'A_Look()'); // 64
  DEH_AddAction(@A_Lower, 'A_Lower()'); // 65
  DEH_AddAction(@THereticWeaponActions.A_MaceBallImpact, 'A_MaceBallImpact()'); // 66
  DEH_AddAction(@THereticWeaponActions.A_MaceBallImpact2, 'A_MaceBallImpact2()'); // 67
  DEH_AddAction(@THereticWeaponActions.A_MacePL1Check, 'A_MacePL1Check()'); // 68
  DEH_AddAction(@THereticMonsterActions.A_MakePod, 'A_MakePod()'); // 69
  DEH_AddAction(@THereticMonsterActions.A_MinotaurAtk1, 'A_MinotaurAtk1()'); // 70
  DEH_AddAction(@THereticMonsterActions.A_MinotaurAtk2, 'A_MinotaurAtk2()'); // 71
  DEH_AddAction(@THereticMonsterActions.A_MinotaurAtk3, 'A_MinotaurAtk3()'); // 72
  DEH_AddAction(@THereticMonsterActions.A_MinotaurCharge, 'A_MinotaurCharge()'); // 73
  DEH_AddAction(@THereticMonsterActions.A_MinotaurDecide, 'A_MinotaurDecide()'); // 74
  DEH_AddAction(@THereticMonsterActions.A_MntrFloorFire, 'A_MntrFloorFire()'); // 75
  DEH_AddAction(@THereticMonsterActions.A_MummyAttack, 'A_MummyAttack()'); // 76
  DEH_AddAction(@THereticMonsterActions.A_MummyAttack2, 'A_MummyAttack2()'); // 77
  DEH_AddAction(@THereticMonsterActions.A_MummyFX1Seek, 'A_MummyFX1Seek()'); // 78
  DEH_AddAction(@THereticMonsterActions.A_MummySoul, 'A_MummySoul()'); // 79
  DEH_AddAction(@A_NoBlocking, 'A_NoBlocking()'); // 80
  DEH_AddAction(@THereticMonsterActions.A_Pain, 'A_Pain()'); // 81
  DEH_AddAction(@THereticWeaponActions.A_PhoenixPuff, 'A_PhoenixPuff()'); // 82
  DEH_AddAction(@THereticMonsterActions.A_PodPain, 'A_PodPain()'); // 83
  DEH_AddAction(@THereticWeaponActions.A_RainImpact, 'A_RainImpact()'); // 84
  DEH_AddAction(@A_Raise, 'A_Raise()'); // 85
  DEH_AddAction(@A_ReFire, 'A_ReFire()'); // 86
  DEH_AddAction(@THereticMonsterActions.A_RemovePod, 'A_RemovePod()'); // 87
  DEH_AddAction(@A_RestoreArtifact, 'A_RestoreArtifact()'); // 88
  DEH_AddAction(@A_RestoreSpecialThing1, 'A_RestoreSpecialThing1()'); // 89
  DEH_AddAction(@A_RestoreSpecialThing2, 'A_RestoreSpecialThing2()'); // 90
  DEH_AddAction(@TMonsterBaseActions.A_Scream, 'A_Scream()'); // 91
  DEH_AddAction(@THereticWeaponActions.A_ShutdownPhoenixPL2, 'A_ShutdownPhoenixPL2()'); // 92
  DEH_AddAction(@THereticMonsterActions.A_SkullPop, 'A_SkullPop()'); // 93
  DEH_AddAction(@THereticWeaponActions.A_SkullRodPL2Seek, 'A_SkullRodPL2Seek()'); // 94
  DEH_AddAction(@THereticWeaponActions.A_SkullRodStorm, 'A_SkullRodStorm()'); // 95
  DEH_AddAction(@THereticMonsterActions.A_SnakeAttack, 'A_SnakeAttack()'); // 96
  DEH_AddAction(@THereticMonsterActions.A_SnakeAttack2, 'A_SnakeAttack2()'); // 97
  DEH_AddAction(@THereticMonsterActions.A_Sor1Chase, 'A_Sor1Chase()'); // 98
  DEH_AddAction(@THereticMonsterActions.A_Sor1Pain, 'A_Sor1Pain()'); // 99
  DEH_AddAction(@THereticMonsterActions.A_Sor2DthInit, 'A_Sor2DthInit()'); // 100
  DEH_AddAction(@THereticMonsterActions.A_Sor2DthLoop, 'A_Sor2DthLoop()'); // 101
  DEH_AddAction(@THereticMonsterActions.A_SorcererRise, 'A_SorcererRise()'); // 102
  DEH_AddAction(@THereticMonsterActions.A_SorDBon, 'A_SorDBon()'); // 103
  DEH_AddAction(@THereticMonsterActions.A_SorDExp, 'A_SorDExp()'); // 104
  DEH_AddAction(@THereticMonsterActions.A_SorDSph, 'A_SorDSph()'); // 105
  DEH_AddAction(@THereticMonsterActions.A_SorRise, 'A_SorRise()'); // 106
  DEH_AddAction(@THereticMonsterActions.A_SorSightSnd, 'A_SorSightSnd()'); // 107
  DEH_AddAction(@THereticMonsterActions.A_SorZap, 'A_SorZap()'); // 108
  DEH_AddAction(@THereticWeaponActions.A_SpawnRippers, 'A_SpawnRippers()'); // 109
  DEH_AddAction(@THereticMonsterActions.A_SpawnTeleGlitter, 'A_SpawnTeleGlitter()'); // 110
  DEH_AddAction(@THereticMonsterActions.A_SpawnTeleGlitter2, 'A_SpawnTeleGlitter2()'); // 111
  DEH_AddAction(@THereticMonsterActions.A_Srcr1Attack, 'A_Srcr1Attack()'); // 112
  DEH_AddAction(@THereticMonsterActions.A_Srcr2Attack, 'A_Srcr2Attack()'); // 113
  DEH_AddAction(@THereticMonsterActions.A_Srcr2Decide, 'A_Srcr2Decide()'); // 114
  DEH_AddAction(@THereticWeaponActions.A_StaffAttackPL1, 'A_StaffAttackPL1()'); // 115
  DEH_AddAction(@THereticWeaponActions.A_StaffAttackPL2, 'A_StaffAttackPL2()'); // 116
  DEH_AddAction(@THereticMonsterActions.A_UnHideThing, 'A_UnHideThing()'); // 117
  DEH_AddAction(@THereticMonsterActions.A_VolcanoBlast, 'A_VolcanoBlast()'); // 118
  DEH_AddAction(@THereticMonsterActions.A_VolcanoSet, 'A_VolcanoSet()'); // 119
  DEH_AddAction(@THereticMonsterActions.A_VolcBallImpact, 'A_VolcBallImpact()'); // 120
  DEH_AddAction(@THereticWeaponActions.A_WeaponReady, 'A_WeaponReady()'); // 121
  DEH_AddAction(@THereticMonsterActions.A_WhirlwindSeek, 'A_WhirlwindSeek()'); // 122
  DEH_AddAction(@THereticMonsterActions.A_WizAtk1, 'A_WizAtk1()'); // 123
  DEH_AddAction(@THereticMonsterActions.A_WizAtk2, 'A_WizAtk2()'); // 124
  DEH_AddAction(@THereticMonsterActions.A_WizAtk3, 'A_WizAtk3()'); // 125
  DEH_AddAction(@TCommonSoundActions.A_CustomSound1, 'A_CustomSound1()'); // 126
  DEH_AddAction(@TCommonSoundActions.A_CustomSound2, 'A_CustomSound2()'); // 127
  DEH_AddAction(@TCommonSoundActions.A_CustomSound3, 'A_CustomSound3()'); // 128
  DEH_AddAction(@TCommonSoundActions.A_RandomPainSound, 'A_RandomPainSound()'); // 129
  DEH_AddAction(@TCommonSoundActions.A_RandomSeeSound, 'A_RandomSeeSound()'); // 130
  DEH_AddAction(@TCommonSoundActions.A_RandomAttackSound, 'A_RandomAttackSound()'); // 131
  DEH_AddAction(@TCommonSoundActions.A_RandomDeathSound, 'A_RandomDeathSound()'); // 132
  DEH_AddAction(@TCommonSoundActions.A_RandomActiveSound, 'A_RandomActiveSound()'); // 133
  DEH_AddAction(@TCommonSoundActions.A_RandomCustomSound1, 'A_RandomCustomSound1()'); // 134
  DEH_AddAction(@TCommonSoundActions.A_RandomCustomSound2, 'A_RandomCustomSound2()'); // 135
  DEH_AddAction(@TCommonSoundActions.A_RandomCustomSound3, 'A_RandomCustomSound3()'); // 136
  DEH_AddAction(@TCommonSoundActions.A_RandomCustomSound, 'A_RandomCustomSound()'); // 137
  DEH_AddAction(@TCommonMovementActions.A_Wander, 'A_Wander()'); // 138
  DEH_AddAction(@TCommonSoundActions.A_Playsound, 'A_Playsound(sound: string)'); // 139
  DEH_AddAction(@TCommonSoundActions.A_RandomSound, 'A_RandomSound(sound1: string, [sound2: string], ...)'); // 140
  DEH_AddAction(@TCommonMovementActions.A_Stop, 'A_Stop()'); // 141
  DEH_AddAction(@TCommonJumpActions.A_Jump, 'A_Jump(propability: random_t, offset1: integer, [offset2: integer], ...)'); // 142
  DEH_AddAction(@TCommonSpawnActions.A_CustomMissile, 'A_CustomMissile(missiletype: string, [height: integer], [offset: integer], [angle: integer], [aimmode: integer], [pitch: integer])'); // 143
  DEH_AddAction(@TExtraRoutines.A_NoGravity, 'A_NoGravity()'); // 144
  DEH_AddAction(@TExtraRoutines.A_Gravity, 'A_Gravity()'); // 145
  DEH_AddAction(@A_NoBlocking, 'A_NoBlocking()'); // 146
  DEH_AddAction(@TExtraRoutines.A_MeleeAttack, 'A_MeleeAttack([mindamage: integer], [maxdamage: integer])'); // 147
  DEH_AddAction(@TCommonSpawnActions.A_SpawnItem, 'A_SpawnItem(type: string, [distance: float], [zheight: float], [angle: angle])'); // 148
  DEH_AddAction(@TCommonSpawnActions.A_SeekerMissile, 'A_SeekerMissile(threshold_angle: angle, [turnMax_angle: angle])'); // 149
  DEH_AddAction(@TCommonGameDependentActions.A_CStaffMissileSlither, 'A_CStaffMissileSlither()'); // 150
  DEH_AddAction(@TCommonAppearanceActions.A_SetTranslucent, 'A_SetTranslucent(alpha: float, [style: integer])'); // 151
  DEH_AddAction(@TExtraRoutines.A_Die, 'A_Die()'); // 152
  DEH_AddAction(@TExtraRoutines.A_CustomBulletAttack, 'A_CustomBulletAttack(spread_xy: angle, numbullets: integer, damageperbullet: integer, [range: integer])'); // 153
  DEH_AddAction(@TCommonAppearanceActions.A_FadeOut, 'A_FadeOut(fade: float)'); // 154
  DEH_AddAction(@TCommonAppearanceActions.A_FadeIn, 'A_FadeIn(fade: float)'); // 155
  DEH_AddAction(@TCommonAttackActions.A_MissileAttack, 'A_MissileAttack([missiletype: string])'); // 156
  DEH_AddAction(@TCommonMovementActions.A_AdjustSideSpot, 'A_AdjustSideSpot(sideoffset: float)'); // 157
  DEH_AddAction(@TExtraRoutines.A_Countdown, 'A_Countdown()'); // 158
  DEH_AddAction(@TExtraRoutines.A_FastChase, 'A_FastChase()'); // 159
  DEH_AddAction(@TExtraRoutines.A_LowGravity, 'A_LowGravity()'); // 160
  DEH_AddAction(@TCommonMovementActions.A_ThrustZ, 'A_ThrustZ(momz: float)'); // 161
  DEH_AddAction(@TCommonMovementActions.A_ThrustXY, 'A_ThrustXY(mom: float, ang: angle)'); // 162
  DEH_AddAction(@TCommonMovementActions.A_Turn, 'A_Turn(value: angle)'); // 163
  DEH_AddAction(@TCommonJumpActions.A_JumpIfCloser, 'A_JumpIfCloser(distancetotarget: float, offset: integer)'); // 164
  DEH_AddAction(@TCommonJumpActions.A_JumpIfHealthLower, 'A_JumpIfHealthLower(health: integer, offset: integer)'); // 165
  DEH_AddAction(@TCommonDamageActions.A_ScreamAndUnblock, 'A_ScreamAndUnblock()'); // 166
  DEH_AddAction(@TCommonSoundActions.A_PlayWeaponsound, 'A_PlayWeaponsound(sound: string)'); // 167
  DEH_AddAction(@TExtraRoutines.A_SetInvulnerable, 'A_SetInvulnerable()'); // 168
  DEH_AddAction(@TExtraRoutines.A_UnSetInvulnerable, 'A_UnSetInvulnerable()'); // 169
  DEH_AddAction(@TCommonSoundActions.A_RandomMeleeSound, 'A_RandomMeleeSound()'); // 170
  DEH_AddAction(@TExtraRoutines.A_FloatBob, 'A_FloatBob()'); // 171
  DEH_AddAction(@TExtraRoutines.A_NoFloatBob, 'A_NoFloatBob()'); // 172
  DEH_AddAction(@TCommonStateBitActions.A_Missile, 'A_Missile()'); // 173
  DEH_AddAction(@TCommonStateBitActions.A_NoMissile, 'A_NoMissile()'); // 174
  DEH_AddAction(@TExtraRoutines.A_ComboAttack, 'A_ComboAttack()'); // 175
  DEH_AddAction(@TExtraRoutines.A_BulletAttack, 'A_BulletAttack([numbullets: integer])'); // 176
  DEH_AddAction(@TExtraRoutines.A_MediumGravity, 'A_MediumGravity()'); // 177
  DEH_AddAction(@TCommonAppearanceActions.A_FadeOut10, 'A_FadeOut10()'); // 178
  DEH_AddAction(@TCommonAppearanceActions.A_FadeOut20, 'A_FadeOut20()'); // 179
  DEH_AddAction(@TCommonAppearanceActions.A_FadeOut30, 'A_FadeOut30()'); // 180
  DEH_AddAction(@TCommonAppearanceActions.A_FadeIn10, 'A_FadeIn10()'); // 181
  DEH_AddAction(@TCommonAppearanceActions.A_FadeIn20, 'A_FadeIn20()'); // 182
  DEH_AddAction(@TCommonAppearanceActions.A_FadeIn30, 'A_FadeIn30()'); // 183
  DEH_AddAction(@TCommonSpawnActions.A_SpawnItemEx, 'A_SpawnItemEx(itemtype: string, [xofs: float], [yofs: float], [zofs: float], [momx: float], [momy: float], [momz: float], [ang: angle], [flags: integer], [chance: integer])'); // 184
  DEH_AddAction(@TCommonSpawnActions.A_RandomMissile, 'A_RandomMissile(missile1: string, [missile2: string], ...)'); // 185
  DEH_AddAction(@P_RemoveMobj, 'A_RemoveSelf()'); // 186
  DEH_AddAction(@TCommonJumpActions.A_GoTo, 'A_GoTo(propability: random_t, state: state_t)'); // 187
  DEH_AddAction(@TCommonJumpActions.A_GoToIfCloser, 'A_GoToIfCloser(distancetotarget: float, state: state_t)'); // 188
  DEH_AddAction(@TCommonJumpActions.A_GoToIfHealthLower, 'A_GoToIfHealthLower(health: integer, state: state_t)'); // 189
  DEH_AddAction(@TCommonStateParamActions.A_ConsoleCommand, 'A_ConsoleCommand(cmd: string, [parm1: string], [parm2: string], ...)'); // 190
  DEH_AddAction(@TCommonStateBitActions.A_SetFrightened, 'A_SetFrightened()'); // 191
  DEH_AddAction(@TCommonStateBitActions.A_UnSetFrightened, 'A_UnSetFrightened()'); // 192
  DEH_AddAction(@TCommonCustomParamActions.A_SetCustomParam, 'A_SetCustomParam(param: string, value: integer)'); // 193
  DEH_AddAction(@TCommonCustomParamActions.A_AddCustomParam, 'A_AddCustomParam(param: string, value: integer)'); // 194
  DEH_AddAction(@TCommonCustomParamActions.A_SubtractCustomParam, 'A_SubtractCustomParam(param: string, value: integer)'); // 195
  DEH_AddAction(@TCommonCustomParamActions.A_SetTargetCustomParam, 'A_SetTargetCustomParam(param: string, value: integer)'); // 196
  DEH_AddAction(@TCommonCustomParamActions.A_AddTargetCustomParam, 'A_AddTargetCustomParam(param: string, value: integer)'); // 197
  DEH_AddAction(@TCommonCustomParamActions.A_SubtractTargetCustomParam, 'A_SubtractTargetCustomParam(param: string, value: integer)'); // 198
  DEH_AddAction(@TCommonJumpActions.A_JumpIfCustomParam, 'A_JumpIfCustomParam(param: string, value: integer, offset: integer)'); // 199
  DEH_AddAction(@TCommonJumpActions.A_JumpIfCustomParamLess, 'A_JumpIfCustomParamLess(param: string, value: integer, offset: integer)'); // 200
  DEH_AddAction(@TCommonJumpActions.A_JumpIfCustomParamGreater, 'A_JumpIfCustomParamGreater(param: string, value: integer, offset: integer)'); // 201
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetCustomParam, 'A_JumpIfTargetCustomParam(param: string, value: integer, offset: integer)'); // 202
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetCustomParamLess, 'A_JumpIfTargetCustomParamLess(param: string, value: integer, offset: integer)'); // 203
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetCustomParamGreater, 'A_JumpIfTargetCustomParamGreater(param: string, value: integer, offset: integer)'); // 204
  DEH_AddAction(@TCommonJumpActions.A_GoToIfCustomParam, 'A_GoToIfCustomParam(param: string, value: integer, state: state_t)'); // 205
  DEH_AddAction(@TCommonJumpActions.A_GoToIfCustomParamLess, 'A_GoToIfCustomParamLess(param: string, value: integer, state: state_t)'); // 206
  DEH_AddAction(@TCommonJumpActions.A_GoToIfCustomParamGreater, 'A_GoToIfCustomParamGreater(param: string, value: integer, state: state_t)'); // 207
  DEH_AddAction(@TCommonJumpActions.A_GoToIfTargetCustomParam, 'A_GoToIfTargetCustomParam(param: string, value: integer, state: state_t)'); // 208
  DEH_AddAction(@TCommonJumpActions.A_GoToIfTargetCustomParamLess, 'A_GoToIfTargetCustomParamLess(param: string, value: integer, state: state_t)'); // 209
  DEH_AddAction(@TCommonJumpActions.A_GoToIfTargetCustomParamGreater, 'A_GoToIfTargetCustomParamGreater(param: string, value: integer, state: state_t)'); // 210
  DEH_AddAction(@TCommonAppearanceActions.A_GhostOn, 'A_GhostOn()'); // 211
  DEH_AddAction(@A_RunScript, 'A_RunScript(script1: string, [script2: string], ...)'); // 212
  DEH_AddAction(@TCommonMovementActions.A_Turn5, 'A_Turn5()'); // 213
  DEH_AddAction(@TCommonMovementActions.A_Turn10, 'A_Turn10()'); // 214
  DEH_AddAction(@TCommonStateBitActions.A_Blocking, 'A_Blocking()'); // 215
  DEH_AddAction(@TCommonStateBitActions.A_DoNotRunScripts, 'A_DoNotRunScripts()'); // 216
  DEH_AddAction(@TCommonStateBitActions.A_DoRunScripts, 'A_DoRunScripts()'); // 217
  DEH_AddAction(@TCommonStateParamActions.A_TargetDropItem, 'A_TargetDropItem(dropitemtype: string)'); // 218
  DEH_AddAction(@TCommonStateParamActions.A_DefaultTargetDropItem, 'A_DefaultTargetDropItem()'); // 219
  DEH_AddAction(@TCommonStateParamActions.A_SetDropItem, 'A_SetDropItem(dropitemtype: string)'); // 220
  DEH_AddAction(@TCommonStateParamActions.A_SetDefaultDropItem, 'A_SetDefaultDropItem()'); // 221
  DEH_AddAction(@TCommonSearchActions.A_GlobalEarthQuake, 'A_GlobalEarthQuake(tics: integer)'); // 222
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapStringEqual, 'A_JumpIfMapStringEqual(parm: string, value: string, offset; integer)'); // 223
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapStringLess, 'A_JumpIfMapStringLess(parm: string, value: string, offset; integer)'); // 224
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapStringGreater, 'A_JumpIfMapStringGreater(parm: string, value: string, offset; integer)'); // 225
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapIntegerEqual, 'A_JumpIfMapIntegerEqual(parm: string, value: integer, offset: integer)'); // 226
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapIntegerLess, 'A_JumpIfMapIntegerLess(parm: string, value: integer, offset: integer)'); // 227
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapIntegerGreater, 'A_JumpIfMapIntegerGreater(parm: string, value: integer, offset: integer)'); // 228
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapFloatEqual, 'A_JumpIfMapFloatEqual(parm: string, value: float, offset: integer)'); // 229
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapFloatLess, 'A_JumpIfMapFloatLess(parm: string, value: float, offset: integer)'); // 230
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapFloatGreater, 'A_JumpIfMapFloatGreater(parm: string, value: float, offset: integer)'); // 231
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldStringEqual, 'A_JumpIfWorldStringEqual(parm: string, value: string, offset: integer)'); // 232
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldStringLess, 'A_JumpIfWorldStringLess(parm: string, value: string, offset: integer)'); // 233
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldStringGreater, 'A_JumpIfWorldStringGreater(parm: string, value: string, offset: integer)'); // 234
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldIntegerEqual, 'A_JumpIfWorldIntegerEqual(parm: string, value: integer, offset: integer)'); // 235
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldIntegerLess, 'A_JumpIfWorldIntegerLess(parm: string, value: integer, offset: integer)'); // 236
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldIntegerGreater, 'A_JumpIfWorldIntegerGreater(parm: string, value: integer, offset: integer)'); // 237
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldFloatEqual, 'A_JumpIfWorldFloatEqual(parm: string, value: float, offset: integer)'); // 238
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldFloatLess, 'A_JumpIfWorldFloatLess(parm: string, value: float, offset: integer)'); // 239
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldFloatGreater, 'A_JumpIfWorldFloatGreater(parm: string, value: float, offset: integer)'); // 240
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapStringEqual, 'A_GoToIfMapStringEqual(parm: string, value: string, state: state_t)'); // 241
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapStringLess, 'A_GoToIfMapStringLess(parm: string, value: string, state: state_t)'); // 242
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapStringGreater, 'A_GoToIfMapStringGreater(parm: string, value: string, state: state_t)'); // 243
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapIntegerEqual, 'A_GoToIfMapIntegerEqual(parm: string, value: integer, state: state_t)'); // 244
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapIntegerLess, 'A_GoToIfMapIntegerLess(parm: string, value: integer, state: state_t)'); // 245
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapIntegerGreater, 'A_GoToIfMapIntegerGreater(parm: string, value: integer, state: state_t)'); // 246
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapFloatEqual, 'A_GoToIfMapFloatEqual(parm: string, value: float, state: state_t)'); // 247
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapFloatLess, 'A_GoToIfMapFloatLess(parm: string, value: float, state: state_t)'); // 248
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapFloatGreater, 'A_GoToIfMapFloatGreater(parm: string, value: float, state: state_t)'); // 249
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldStringEqual, 'A_GoToIfWorldStringEqual(parm: string, value: string, state: state_t)'); // 250
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldStringLess, 'A_GoToIfWorldStringLess(parm: string, value: string, state: state_t)'); // 251
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldStringGreater, 'A_GoToIfWorldStringGreater(parm: string, value: string, state: state_t)'); // 252
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldIntegerEqual, 'A_GoToIfWorldIntegerEqual(parm: string, value: integer, state: state_t)'); // 253
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldIntegerLess, 'A_GoToIfWorldIntegerLess(parm: string, value: integer, state: state_t)'); // 254
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldIntegerGreater, 'A_GoToIfWorldIntegerGreater(parm: string, value: integer, state: state_t)'); // 255
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldFloatEqual, 'A_GoToIfWorldFloatEqual(parm: string, value: float, state: state_t)'); // 256
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldFloatLess, 'A_GoToIfWorldFloatLess(parm: string, value: float, state: state_t)'); // 257
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldFloatGreater, 'A_GoToIfWorldFloatGreater(parm: string, value: float, state: state_t)'); // 258
  DEH_AddAction(@TExtraRoutines.A_PlayerMessage, 'A_PlayerMessage(msg1: string, [msg2: string], ...)'); // 259
  DEH_AddAction(@TCommonCustomParamActions.A_SetMapStr, 'A_SetMapStr(mvar: string; value1: string; [value2: string],...)'); // 260
  DEH_AddAction(@TCommonCustomParamActions.A_SetWorldStr, 'A_SetWorldStr(wvar: string; value1: string; [value2: string],...)'); // 261
  DEH_AddAction(@TCommonCustomParamActions.A_SetMapInt, 'A_SetMapInt(mvar: string; value: integer)'); // 262
  DEH_AddAction(@TCommonCustomParamActions.A_SetWorldInt, 'A_SetWorldInt(wvar: string; value: integer)'); // 263
  DEH_AddAction(@TCommonCustomParamActions.A_SetMapFloat, 'A_SetMapFloat(mvar: string; value: float)'); // 264
  DEH_AddAction(@TCommonCustomParamActions.A_SetWorldFloat, 'A_SetWorldFloat(wvar: string; value: float)'); // 265
  DEH_AddAction(@TCommonJumpActions.A_RandomGoto, 'A_RandomGoto(state1: state_t; [state2: state_t],...)'); // 266
  DEH_AddAction(@TCommonDamageActions.A_ResetHealth, 'A_ResetHealth()'); // 267
  DEH_AddAction(@TCommonMovementActions.A_Recoil, 'A_Recoil(xymom: float)'); // 268
  DEH_AddAction(@TCommonStateBitActions.A_SetSolid, 'A_SetSolid()'); // 269
  DEH_AddAction(@TCommonStateBitActions.A_UnSetSolid, 'A_UnSetSolid()'); // 270
  DEH_AddAction(@TCommonStateBitActions.A_SetFloat, 'A_SetFloat()'); // 271
  DEH_AddAction(@TCommonStateBitActions.A_UnSetFloat, 'A_UnSetFloat()'); // 272
  DEH_AddAction(@TCommonDamageActions.A_SetHealth, 'A_SetHealth(h: integer)'); // 273
  DEH_AddAction(@TCommonDamageActions.A_ResetTargetHealth, 'A_ResetTargetHealth()'); // 274
  DEH_AddAction(@TCommonDamageActions.A_SetTargetHealth, 'A_SetTargetHealth(h: integer)'); // 275
  DEH_AddAction(@TCommonMovementActions.A_ScaleVelocity, 'A_ScaleVelocity(scale: float)'); // 276
  DEH_AddAction(@TCommonMovementActions.A_ChangeVelocity, 'A_ChangeVelocity(velx: float, vely: float, velz: float, flags: float)'); // 277
  DEH_AddAction(@TCommonJumpActions.A_JumpIf, 'A_JumpIf(propability: boolean, offset1: integer, [offset2: integer], ...)'); // 278
  DEH_AddAction(@A_MusicChanger, 'A_MusicChanger()'); // 279
  DEH_AddAction(@TCommonStateBitActions.A_SetPushFactor, 'A_SetPushFactor(f: float)'); // 280
  DEH_AddAction(@TCommonAppearanceActions.A_SetScale, 'A_SetScale(s: float)'); // 281
  DEH_AddAction(@TCommonStateBitActions.A_SetGravity, 'A_SetGravity(g: float)'); // 282
  DEH_AddAction(@TCommonStateBitActions.A_SetFloorBounce, 'A_SetFloorBounce()'); // 283
  DEH_AddAction(@TCommonStateBitActions.A_UnSetFloorBounce, 'A_UnSetFloorBounce()'); // 284
  DEH_AddAction(@TCommonStateBitActions.A_SetCeilingBounce, 'A_SetCeilingBounce()'); // 285
  DEH_AddAction(@TCommonStateBitActions.A_UnSetCeilingBounce, 'A_UnSetCeilingBounce()'); // 286
  DEH_AddAction(@TCommonStateBitActions.A_SetWallBounce, 'A_SetWallBounce()'); // 287
  DEH_AddAction(@TCommonStateBitActions.A_UnSetWallBounce, 'A_UnSetWallBounce()'); // 288
  DEH_AddAction(@TCommonAppearanceActions.A_GlowLight, 'A_GlowLight(color: string)'); // 289
  DEH_AddAction(@TCommonMovementActions.A_TraceNearestPlayer, 'A_TraceNearestPlayer(pct: integer, [maxturn: angle_t])'); // 290
  DEH_AddAction(@TCommonGameDependentActions.A_ChangeFlag, 'A_ChangeFlag(flag: string, onoff: boolean)'); // 291
  DEH_AddAction(@TCommonSearchActions.A_CheckFloor, 'A_CheckFloor(offset: integer)'); // 292
  DEH_AddAction(@TCommonSearchActions.A_CheckCeiling, 'A_CheckCeiling(offset: integer)'); // 293
  DEH_AddAction(@TCommonSoundActions.A_StopSound, 'A_StopSound()'); // 294
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetOutsideMeleeRange, 'A_JumpIfTargetOutsideMeleeRange(offset: integer)'); // 295
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetInsideMeleeRange, 'A_JumpIfTargetInsideMeleeRange(offset: integer)'); // 296
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTracerCloser, 'A_JumpIfTracerCloser(distancetotarget: float, offset: integer)'); // 297
  DEH_AddAction(@TCommonStateBitActions.A_SetMass, 'A_SetMass(mass: integer)'); // 298
  DEH_AddAction(@TCommonStateBitActions.A_SetTargetMass, 'A_SetTargetMass(mass: integer)'); // 299
  DEH_AddAction(@TCommonStateBitActions.A_SetTracerMass, 'A_SetTracerMass(mass: integer)'); // 300
  DEH_AddAction(@TCommonSearchActions.A_CheckSight, 'A_CheckSight(offset: integer)'); // 301
  DEH_AddAction(@TCommonSearchActions.A_CheckSightOrRange, 'A_CheckSightOrRange(distance: float, offset: integer, [twodi: boolean=false])'); // 302
  DEH_AddAction(@TCommonSearchActions.A_CheckRange, 'A_CheckRange(distance: float, offset: integer, [twodi: boolean=false])'); // 303
  DEH_AddAction(@TCommonStateParamActions.A_CountdownArg, 'A_CountdownArg(arg: integer, offset: integer)'); // 304
  DEH_AddAction(@TCommonStateParamActions.A_SetArg, 'A_SetArg(arg: integer, value: integer)'); // 305
  DEH_AddAction(@TCommonStateParamActions.A_SetSpecial, 'A_SetSpecial(special: integer, [arg1, arg2, arg3, arg4, arg5: integer])'); // 306
  DEH_AddAction(@TCommonGameDependentActions.A_CheckFlag, 'A_CheckFlag(flag: string, offset: integer, [aaprt: AAPTR])'); // 307
  DEH_AddAction(@TCommonMovementActions.A_SetAngle, 'A_SetAngle(angle: integer, [flags: integer], [aaprt: AAPTR])'); // 308
  DEH_AddAction(@TCommonCustomParamActions.A_SetUserVar, 'A_SetUserVar(varname: string, value: integer)'); // 309
  DEH_AddAction(@TCommonCustomParamActions.A_SetUserArray, 'A_SetUserArray(varname: string, index: integer, value: integer)'); // 310
  DEH_AddAction(@TCommonStateParamActions.A_SetTics, 'A_SetTics(tics: integer)'); // 311
  DEH_AddAction(@TCommonGameDependentActions.A_DropItem, 'A_DropItem(spawntype: string, amount: integer, chance: integer)'); // 312
  DEH_AddAction(@TCommonDamageActions.A_DamageSelf, 'A_DamageSelf(actor: Pmobj_t)'); // 313
  DEH_AddAction(@TCommonDamageActions.A_DamageTarget, 'A_DamageTarget(const damage: integer)'); // 314
  DEH_AddAction(@TCommonDamageActions.A_DamageTracer, 'A_DamageTracer(const damage: integer)'); // 315
  DEH_AddAction(@TCommonDamageActions.A_KillTarget, 'A_KillTarget()'); // 316
  DEH_AddAction(@TCommonDamageActions.A_KillTracer, 'A_KillTracer()'); // 317
  DEH_AddAction(@TCommonDamageActions.A_RemoveTarget, 'A_RemoveTarget([flags: integer])'); // 318
  DEH_AddAction(@TCommonDamageActions.A_RemoveTracer, 'A_RemoveTracer([flags: integer])'); // 319
  DEH_AddAction(@TCommonDamageActions.A_Remove, 'A_Remove(aaprt: AAPTR, [flags: integer])'); // 320
  DEH_AddAction(@TCommonStateBitActions.A_SetFloatBobPhase, 'A_SetFloatBobPhase(bob: integer)'); // 321
  DEH_AddAction(@TCommonGameDependentActions.A_Detonate, 'A_Detonate()'); // 322
  DEH_AddAction(@TCommonSpawnActions.A_Spawn, 'A_Spawn()'); // 323
  DEH_AddAction(@TCommonMovementActions.A_Face, 'A_Face()'); // 324
  DEH_AddAction(@TCommonAttackActions.A_Scratch, 'A_Scratch()'); // 325
  DEH_AddAction(@TCommonJumpActions.A_RandomJump, 'A_RandomJump()'); // 326
  DEH_AddAction(@TCommonStateParamActions.A_LineEffect, 'A_LineEffect()'); // 327
  DEH_AddAction(@TCommonAppearanceActions.A_FlipSprite, 'A_FlipSprite()'); // 328
  DEH_AddAction(@TCommonAppearanceActions.A_NoFlipSprite, 'A_NoFlipSprite()'); // 329
  DEH_AddAction(@TCommonAppearanceActions.A_RandomFlipSprite, 'A_RandomFlipSprite(chance: integer)'); // 330
  DEH_AddAction(@TCommonAppearanceActions.A_RandomNoFlipSprite, 'A_RandomNoFlipSprite(chance: integer)'); // 331
  DEH_AddAction(@TCommonAttackActions.A_CustomMeleeAttack, 'A_CustomMeleeAttack(damage: integer, meleesound: string, misssound: string)'); // 332
  DEH_AddAction(@TCommonAttackActions.A_CustomComboAttack, 'A_CustomComboAttack(missiletype: string, spawnheight: integer, damage: integer, meleesound: string)'); // 333
  DEH_AddAction(@TCommonAppearanceActions.A_SetRenderStyle, 'A_SetRenderStyle(style: renderstyle_t, alpha: float)'); // 334
  DEH_AddAction(@TCommonAppearanceActions.A_FadeTo, 'A_FadeTo(targ: integer, ammount: integer, flags: integer)'); // 335
  DEH_AddAction(@TCommonStateBitActions.A_SetSize, 'A_SetSize(newradius: integer, newheight: integer, testpos: boolean)'); // 336
  DEH_AddAction(@TCommonDamageActions.A_RaiseMaster, 'A_RaiseMaster(copyfriendliness: boolean)'); // 337
  DEH_AddAction(@TCommonDamageActions.A_RaiseChildren, 'A_RaiseChildren(copyfriendliness: boolean)'); // 338
  DEH_AddAction(@TCommonDamageActions.A_RaiseSiblings, 'A_RaiseSiblings(copyfriendliness: boolean)'); // 339
  DEH_AddAction(@TCommonStateBitActions.A_SetMasterMass, 'A_SetMasterMass(mass: integer)'); // 340
  DEH_AddAction(@TCommonDamageActions.A_KillMaster, 'A_KillMaster()'); // 341
  DEH_AddAction(@TCommonDamageActions.A_DamageMaster, 'A_DamageMaster(const damage: integer)'); // 342
  DEH_AddAction(@TCommonGameDependentActions.A_HealThing, 'A_HealThing(amount: integer, max: integer)'); // 343
  DEH_AddAction(@TCommonDamageActions.A_RemoveMaster, 'A_RemoveMaster([flags: integer])'); // 344
  DEH_AddAction(@TCommonAttackActions.A_BasicAttack, 'A_BasicAttack(MeleeDamage: integer, MeleeSound: integer, MissileType: integer, MissileHeight: float)'); // 345
  DEH_AddAction(@TCommonStateParamActions.A_SetMasterArg, 'A_SetMasterArg(arg: integer; value: integer)'); // 346
  DEH_AddAction(@TCommonStateParamActions.A_SetTargetArg, 'A_SetTargetArg(arg: integer; value: integer)'); // 347
  DEH_AddAction(@TCommonStateParamActions.A_SetTracerArg, 'A_SetTracerArg(arg: integer; value: integer)'); // 348
  DEH_AddAction(@TCommonMovementActions.A_Tracer2, 'A_Tracer2()'); // 349
  DEH_AddAction(@TCommonSearchActions.A_MonsterRefire, 'A_MonsterRefire(prob: integer, offset: state_t)'); // 350
  DEH_AddAction(@TCommonStateParamActions.A_RearrangePointers, 'A_RearrangePointers(ptr_target: integer, ptr_master: integer, ptr_tracer: integer, flags: integer)'); // 351
  DEH_AddAction(@TCommonStateParamActions.A_TransferPointer, 'A_TransferPointer(ptr_source: integer, ptr_recipient: integer, ptr_sourcefield: integer, [ptr_recipientfield: integer], [flags: integer])'); // 352
  DEH_AddAction(@TCommonSearchActions.A_AlertMonsters, 'A_AlertMonsters(maxdist: integer, flags: integer)'); // 353
  DEH_AddAction(@TCommonSearchActions.A_LocalEarthQuake, 'A_LocalEarthQuake(tics: integer; [intensity: float = 1.0]; [maxdist: float = MAXINT] ;)'); // 354
  DEH_AddAction(@TCommonSearchActions.A_LocalEarthQuake, 'A_Quake(tics: integer; [intensity: float = 1.0]; [maxdist: float = MAXINT] ;)'); // 355
  DEH_AddAction(@TCommonDamageActions.A_RemoveChildren, 'A_RemoveChildren([flags: integer])'); // 356
  DEH_AddAction(@TCommonDamageActions.A_RemoveSiblings, 'A_RemoveSiblings([flags: integer])'); // 357
  DEH_AddAction(@TCommonDamageActions.A_KillChildren, 'A_KillChildren()'); // 358
  DEH_AddAction(@TCommonDamageActions.A_KillSiblings, 'A_KillSiblings()'); // 359
  DEH_AddAction(@TCommonMovementActions.A_Weave, 'A_Weave(xyspeed: integer = 2, zspeed: integer = 2, xydist: float = 2.0, zdist: float = 1.0)'); // 360
  DEH_AddAction(@TCommonMovementActions.A_SetWeaveIndexXY, 'A_SetWeaveIndexXY(weavexy: integer)'); // 361
  DEH_AddAction(@TCommonMovementActions.A_SetWeaveIndexZ, 'A_SetWeaveIndexZ(weavez: integer)'); // 362
  DEH_AddAction(@TCommonMovementActions.A_SetWeaveIndexes, 'A_SetWeaveIndexes(weavexy: integer, weavez: integer)'); // 363
  DEH_AddAction(@TCommonStateBitActions.A_SetHeight, 'A_SetHeight(newheight: float)'); // 364
  DEH_AddAction(@A_OverlayClear, 'A_OverlayClear()'); // 365
  DEH_AddAction(@A_OverlayDrawPatch, 'A_OverlayDrawPatch(ticks: Integer; patchname: string; x, y: Integer ;)'); // 366
  DEH_AddAction(@A_OverlayDrawPatchStretched, 'A_OverlayDrawPatchStretched(ticks: Integer; patchname: string; x1, y1, x2, y2: Integer ;)'); // 367
  DEH_AddAction(@A_OverlayDrawPixel, 'A_OverlayDrawPixel(ticks: Integer; red, green, blue: byte; x, y: Integer ;)'); // 368
  DEH_AddAction(@A_OverlayDrawRect, 'A_OverlayDrawRect(ticks: Integer; red, green, blue: byte; x1, y1, x2, y2: Integer ;)'); // 369
  DEH_AddAction(@A_OverlayDrawLine, 'A_OverlayDrawLine(ticks: Integer; red, green, blue: byte; x1, y1, x2, y2: Integer ;)'); // 370
  DEH_AddAction(@A_OverlayDrawText, 'A_OverlayDrawText(ticks: Integer; txt: string; align: Integer; x, y: Integer ;)'); // 371
  DEH_AddAction(@A_OverlayDrawLeftText, 'A_OverlayDrawLeftText(ticks: Integer; txt: string; x, y: Integer ;)'); // 372
  DEH_AddAction(@A_OverlayDrawRightText, 'A_OverlayDrawRightText(ticks: Integer; txt: string; x, y: Integer ;)'); // 373
  DEH_AddAction(@A_OverlayDrawCenterText, 'A_OverlayDrawCenterText(ticks: Integer; txt: string; x, y: Integer ;)'); // 374
  DEH_AddAction(@TCommonStateBitActions.A_SetFriction, 'A_SetFriction(newfriction: float)'); // 375
  DEH_AddAction(@TCommonDamageActions.A_PlayerHurtExplode, 'A_PlayerHurtExplode(damage: integer, radius: integer)'); // 376
  DEH_AddAction(@TCommonGameDependentActions.A_SetPushable, 'A_SetPushable()'); // 377
  DEH_AddAction(@TCommonGameDependentActions.A_UnSetPushable, 'A_UnSetPushable()'); // 378
  DEH_AddAction(@TCommonStateBitActions.A_SetPainChance, 'A_SetPainChance(newchance: integer)'); // 379
  DEH_AddAction(@TCommonAppearanceActions.A_SetSpriteDX, 'A_SetSpriteDX(dx: float)'); // 380
  DEH_AddAction(@TCommonAppearanceActions.A_SetSpriteDY, 'A_SetSpriteDY(dy: float)'); // 381
  DEH_AddAction(@A_SeeSound1, 'A_SeeSound()'); // 382
  DEH_AddAction(@A_PainSound1, 'A_PainSound()'); // 383
  DEH_AddAction(@A_AttackSound1, 'A_AttackSound()'); // 384
  DEH_AddAction(@A_MeleeSound1, 'A_MeleeSound()'); // 385
  DEH_AddAction(@A_DeathSound1, 'A_DeathSound()'); // 386
  DEH_AddAction(@A_ActiveSound1, 'A_ActiveSound()'); // 387
  DEH_AddAction(@TCommonMovementActions.A_MatchTargetZ, 'A_MatchTargetZ(zspeed: integer; threshold: integer; maxmomz: integer)'); // 388
  DEH_AddAction(@TCommonStateBitActions.A_SetInteractive, 'A_SetInteractive()'); // 389
  DEH_AddAction(@TCommonStateBitActions.A_UnSetInteractive, 'A_UnSetInteractive()'); // 390
  DEH_AddAction(@A_SimpleDialog, 'A_SimpleDialog(dialog1: string; [dialog2...])'); // 391
  DEH_AddAction(@TCommonCustomParamActions.A_SetMasterCustomParam, 'A_SetMasterCustomParam(param: string, value: integer)');
  DEH_AddAction(@TCommonCustomParamActions.A_AddMasterCustomParam, 'A_AddMasterCustomParam(param: string, value: integer)');
  DEH_AddAction(@TCommonCustomParamActions.A_SubtractMasterCustomParam, 'A_SubtractMasterCustomParam(param: string, value: integer)');
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMasterCustomParam, 'A_JumpIfMasterCustomParam(param: string, value: integer, offset: integer)');
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMasterCustomParamLess, 'A_JumpIfMasterCustomParamLess(param: string, value: integer, offset: integer)');
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMasterCustomParamGreater, 'A_JumpIfMasterCustomParamGreater(param: string, value: integer, offset: integer)');
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMasterCustomParam, 'A_GoToIfMasterCustomParam(param: string, value: integer, state: state_t)');
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMasterCustomParamLess, 'A_GoToIfMasterCustomParamLess(param: string, value: integer, state: state_t)');
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMasterCustomParamGreater, 'A_GoToIfMasterCustomParamGreater(param: string, value: integer, state: state_t)');
  DEH_AddAction(@TCommonCustomParamActions.A_SetTracerCustomParam, 'A_SetTracerCustomParam(param: string, value: integer)');
  DEH_AddAction(@TCommonCustomParamActions.A_AddTracerCustomParam, 'A_AddTracerCustomParam(param: string, value: integer)');
  DEH_AddAction(@TCommonCustomParamActions.A_SubtractTracerCustomParam, 'A_SubtractTracerCustomParam(param: string, value: integer)');
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTracerCustomParam, 'A_JumpIfTracerCustomParam(param: string, value: integer, offset: integer)');
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTracerCustomParamLess, 'A_JumpIfTracerCustomParamLess(param: string, value: integer, offset: integer)');
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTracerCustomParamGreater, 'A_JumpIfTracerCustomParamGreater(param: string, value: integer, offset: integer)');
  DEH_AddAction(@TCommonJumpActions.A_GoToIfTracerCustomParam, 'A_GoToIfTracerCustomParam(param: string, value: integer, state: state_t)');
  DEH_AddAction(@TCommonJumpActions.A_GoToIfTracerCustomParamLess, 'A_GoToIfTracerCustomParamLess(param: string, value: integer, state: state_t)');
  DEH_AddAction(@TCommonJumpActions.A_GoToIfTracerCustomParamGreater, 'A_GoToIfTracerCustomParamGreater(param: string, value: integer, state: state_t)');
  DEH_AddAction(@TCommonStateBitActions.A_SetMonsterInfight, 'A_SetMonsterInfight()');
  DEH_AddAction(@TCommonStateBitActions.A_UnSetMonsterInfight, 'A_UnSetMonsterInfight()');
  DEH_AddAction(@A_RipSound1, 'A_RipSound()');
  DEH_AddAction(@TCommonAppearanceActions.A_ChangeSpriteFlip, 'A_ChangeSpriteFlip(propability: integer)');
  DEH_AddAction(@TCommonSpawnActions.A_SpawnObject, 'A_SpawnObject(dehackedtyp: integer; anglefixeddeg: integer; xoffs, yoffs, zoffs: integer; xvel, yvel, zvel: integer)', [0, 0, 0, 0, 0, 0, 0, 0]);
  DEH_AddAction(@TCommonSpawnActions.A_MonsterProjectile, 'A_MonsterProjectile(dehackedtyp: integer; anglefixeddeg: integer; pitchfixeddeg: integer; xyoffs, zoffs: integer)', [0, 0, 0, 0, 0]);
  DEH_AddAction(@TCommonAttackActions.A_MonsterBulletAttack, 'A_MonsterBulletAttack(anglefixed_hspread, anglefixed_vspread: integer; nbullets: integer; basedamage: integer; damagemod: integer)', [0, 0, 1, 3, 5]);
  DEH_AddAction(@TCommonAttackActions.A_MonsterMeleeAttack, 'A_MonsterMeleeAttack(basedamage: integer; damagemod: integer; soundid: integer; fixxedrange: integer);', [3, 8, 0, 0]);
  DEH_AddAction(@TCommonDamageActions.A_RadiusDamage, 'A_RadiusDamage(damage: integer; radius: integer);', [0, 0]);
  DEH_AddAction(@TCommonSearchActions.A_NoiseAlert, 'A_NoiseAlert()');
  DEH_AddAction(@TCommonDamageActions.A_HealChase, 'A_HealChase(state: state_t; sound: sound_t);', [0, 0]);
  DEH_AddAction(@TCommonSearchActions.A_SeekTracer, 'A_SeekTracer(anglefixed_threshold: integer; anglefixed_maxturn: integer)', [0, 0]);
  DEH_AddAction(@TCommonSearchActions.A_FindTracer, 'A_FindTracer(anglefixed_fov: integer; mapblocks: integer);', [0, 10]);
  DEH_AddAction(@TCommonSearchActions.A_ClearTracer, 'A_ClearTracer();');
  DEH_AddAction(@TCommonJumpActions.A_JumpIfHealthBelow, 'A_JumpIfHealthBelow(state: state_t; health_threshold: integer)', [0, 0]);
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetInSight, 'A_JumpIfTargetInSight(state: state_t; anglefixed_fov: integer)', [0, 0]);
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetCloser, 'A_JumpIfTargetCloser(state: state_t; distance: fixed_t)', [0, 0]);
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTracerInSight, 'A_JumpIfTracerInSight(state: state_t; anglefixed_fov: integer)', [0, 0]);
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTracerCloserMBF21, 'A_JumpIfTracerCloserMBF21(state: state_t; distance: fixed_t)', [0, 0]);
  DEH_AddAction(@TCommonSoundActions.A_RandomRipSound, 'A_RandomRipSound();');
  DEH_AddAction(@TCommonJumpActions.A_JumpIfFlagsSet, 'A_JumpIfFlagsSet(state: state_t; bits, mbf21bits: integer);', [0, 0, 0]);
  DEH_AddAction(@TCommonFlagActions.A_AddFlags, 'A_AddFlags(bits, mbf21bits: integer);', [0, 0]);
  DEH_AddAction(@TCommonFlagActions.A_RemoveFlags, 'A_RemoveFlags(bits, mbf21bits: integer);', [0, 0]);
  DEH_AddAction(@TCommonSpawnActions.A_WeaponProjectile, 'A_WeaponProjectile(typ: integer; anglefixed_ang: integer; anglefixed_pitch: integer; offs_xy: fixed_t; offs_z: fixed_t);', [0, 0, 0, 0, 0]);
  DEH_AddAction(@TCommonAttackActions.A_WeaponBulletAttack, 'A_WeaponBulletAttack(anglefixed_hspread, anglefixed_vspread: integer; numbullets: integer; attackdamage, attackmod: integer);', [0, 0, 1, 5, 3]);
  DEH_AddAction(@TCommonGameDependentActions.A_WeaponMeleeAttack, 'A_WeaponMeleeAttack(attackdamage, attackmod: integer; bersekdamagemul: fixed_t; sound: sound_t; range: fixed_t);', [2, 10, 1 * FRACUNIT, 0, 0]);
  DEH_AddAction(@TCommonSoundActions.A_WeaponSound, 'A_WeaponSound(sound: sound_t; fullvolume: integer);', [0, 0]);
  DEH_AddAction(@TCommonSearchActions.A_WeaponAlert, 'A_WeaponAlert();');
  DEH_AddAction(@TCommonJumpActions.A_WeaponJump, 'A_WeaponJump(statenum: integer; chance: integer);', [0, 0]);
  DEH_AddAction(@TCommonGameDependentActions.A_ConsumeAmmo, 'A_ConsumeAmmo(ammo: integer);', [0]);
  DEH_AddAction(@TCommonGameDependentActions.A_CheckAmmo, 'A_CheckAmmo(state: integer; minammo: integer);', [0, 0]);
  DEH_AddAction(@TCommonWeaponActions.A_RefireTo, 'A_RefireTo(state: integer; skipammo: integer);', [0, 0]);
  DEH_AddAction(@TCommonGameDependentActions.A_GunFlashTo, 'A_GunFlashTo(state: integer; noplayerstatechange: integer);', [0, 0]);
  DEH_AddAction(@TCommonFriendActions.A_SetProjectileGroup, 'A_SetProjectileGroup(group: string);');
  DEH_AddAction(@TCommonFriendActions.A_SetInfightingGroup, 'A_SetInfightingGroup(group: string);');
  DEH_AddAction(@TCommonFriendActions.A_SetSplashGroup, 'A_SetSplashGroup(group: string);');
  DEH_AddAction(@TCommonWeaponActions.A_Delayfire, 'A_Delayfire(tics: integer = TICRATE);');
  DEH_AddAction(@TCommonAppearanceActions.A_SetTranslation, 'A_SetTranslation(trans: string);');
  DEH_AddAction(@TCommonAppearanceActions.A_SetBloodColor, 'A_SetBloodColor(color: string);');

  weapontype_tokens := TDTextList.Create;
  for i := 0 to Ord(NUMWEAPONS) do
    weapontype_tokens.Add(strupper(GetENumName(TypeInfo(weapontype_t), i)));

  ammotype_tokens := TDTextList.Create;
  for i := 0 to Ord(NUMAMMO) + 1 do
    ammotype_tokens.Add(strupper(GetENumName(TypeInfo(ammotype_t), i)));

  deh_strings.numstrings := 0;
  deh_strings.realnumstrings := 0;
  deh_strings._array := nil;

  k := 0;
  for i := 1 to 5 do
    for j := 1 to 9 do
    begin
      TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnames[k], 'HUSTR_E' + itoa(i) + 'M' + itoa(j));
      inc(k);
    end;

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_CREDIT, 'PAGE_CREDIT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_TITLE, 'PAGE_TITLE');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_ORDER, 'PAGE_ORDER');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_HELP1, 'PAGE_HELP1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_HELP2, 'PAGE_HELP2');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflatE1, 'BGFLATE1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflatE2, 'BGFLATE2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflatE3, 'BGFLATE3');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflatE4, 'BGFLATE4');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflatE5, 'BGFLATE5');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @EndLumpName, 'END_TEXT_LUMP');
  for i := 0 to 9 do
  begin
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @chat_macros[i], 'HUSTR_CHATMACR' + itoa(i));
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @chat_macros[i], 'HUSTR_CHATMACR' + IntToStrZFill(2, i));
  end;

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @QUITMSG, 'QUITMSG');

  for i := 0 to NUM_STARTUPMESSAGES - 1 do
  begin
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @startmsg[i], 'STARTUP' + itoa(i));
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @startmsg[i], 'STARTUP' + IntToStrZFill(2, i));
  end;

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_TALKTOSELF1, 'HUSTR_TALKTOSELF1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_TALKTOSELF2, 'HUSTR_TALKTOSELF2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_TALKTOSELF3, 'HUSTR_TALKTOSELF3');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_TALKTOSELF4, 'HUSTR_TALKTOSELF4');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_TALKTOSELF5, 'HUSTR_TALKTOSELF5');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_MESSAGESENT, 'HUSTR_MESSAGESENT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_MSGU, 'HUSTR_MSGU');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_PLRGREEN, 'HUSTR_PLRGREEN');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_PLRINDIGO, 'HUSTR_PLRINDIGO');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_PLRBROWN, 'HUSTR_PLRBROWN');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @HUSTR_PLRRED, 'HUSTR_PLRRED');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @destination_keys[0], 'HUSTR_KEYGREEN');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @destination_keys[1], 'HUSTR_KEYINDIGO');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @destination_keys[2], 'HUSTR_KEYBROWN');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @destination_keys[3], 'HUSTR_KEYRED');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @AMSTR_FOLLOWON, 'AMSTR_FOLLOWON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @AMSTR_FOLLOWOFF, 'AMSTR_FOLLOWOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @AMSTR_GRIDON, 'AMSTR_GRIDON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @AMSTR_GRIDOFF, 'AMSTR_GRIDOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @AMSTR_ROTATEON, 'AMSTR_ROTATEON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @AMSTR_ROTATEOFF, 'AMSTR_ROTATEOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @AMSTR_MARKEDSPOT, 'AMSTR_MARKEDSPOT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @AMSTR_MARKSCLEARED, 'AMSTR_MARKSCLEARED');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_MUS, 'STSTR_MUS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_NOMUS, 'STSTR_NOMUS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_KFAADDED, 'STSTR_KFAADDED');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_FAADDED, 'STSTR_FAADDED');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_NCON, 'STSTR_NCON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_NCOFF, 'STSTR_NCOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_CHOPPERS, 'STSTR_CHOPPERS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_CLEV, 'STSTR_CLEV');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_LGON, 'STSTR_LGON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_LGOFF, 'STSTR_LGOFF');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @E1TEXT, 'E1TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @E2TEXT, 'E2TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @E3TEXT, 'E3TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @E4TEXT, 'E4TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @E5TEXT, 'E5TEXT');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_GOTBLUEKEY, 'TXT_GOTBLUEKEY');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_GOTYELLOWKEY, 'TXT_GOTYELLOWKEY');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_GOTGREENKEY, 'TXT_GOTGREENKEY');

// Artifacts

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTIHEALTH, 'TXT_ARTIHEALTH');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTIFLY, 'TXT_ARTIFLY');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTIINVULNERABILITY, 'TXT_ARTIINVULNERABILITY');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTITOMEOFPOWER, 'TXT_ARTITOMEOFPOWER');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTIINVISIBILITY, 'TXT_ARTIINVISIBILITY');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTIEGG, 'TXT_ARTIEGG');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTISUPERHEALTH, 'TXT_ARTISUPERHEALTH');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTITORCH, 'TXT_ARTITORCH');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTIFIREBOMB, 'TXT_ARTIFIREBOMB');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTITELEPORT, 'TXT_ARTITELEPORT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ARTIALL, 'TXT_ARTIALL');

// Items

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ITEMHEALTH, 'TXT_ITEMHEALTH');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ITEMBAGOFHOLDING, 'TXT_ITEMBAGOFHOLDING');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ITEMSHIELD1, 'TXT_ITEMSHIELD1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ITEMSHIELD2, 'TXT_ITEMSHIELD2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_ITEMSUPERMAP, 'TXT_ITEMSUPERMAP');

// Ammo

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOGOLDWAND1, 'TXT_AMMOGOLDWAND1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOGOLDWAND2, 'TXT_AMMOGOLDWAND2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOMACE1, 'TXT_AMMOMACE1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOMACE2, 'TXT_AMMOMACE2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOCROSSBOW1, 'TXT_AMMOCROSSBOW1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOCROSSBOW2, 'TXT_AMMOCROSSBOW2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOBLASTER1, 'TXT_AMMOBLASTER1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOBLASTER2, 'TXT_AMMOBLASTER2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOSKULLROD1, 'TXT_AMMOSKULLROD1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOSKULLROD2, 'TXT_AMMOSKULLROD2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOPHOENIXROD1, 'TXT_AMMOPHOENIXROD1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_AMMOPHOENIXROD2, 'TXT_AMMOPHOENIXROD2');

// Weapons

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_WPNMACE, 'TXT_WPNMACE');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_WPNCROSSBOW, 'TXT_WPNCROSSBOW');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_WPNBLASTER, 'TXT_WPNBLASTER');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_WPNSKULLROD, 'TXT_WPNSKULLROD');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_WPNPHOENIXROD, 'TXT_WPNPHOENIXROD');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_WPNGAUNTLETS, 'TXT_WPNGAUNTLETS');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATGODON, 'TXT_CHEATGODON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATGODOFF, 'TXT_CHEATGODOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATNOCLIPON, 'TXT_CHEATNOCLIPON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATNOCLIPOFF, 'TXT_CHEATNOCLIPOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATWEAPONS, 'TXT_CHEATWEAPONS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATKEYS, 'TXT_CHEATKEYS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATFLIGHTON, 'TXT_CHEATFLIGHTON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATFLIGHTOFF, 'TXT_CHEATFLIGHTOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATPOWERON, 'TXT_CHEATPOWERON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATPOWEROFF, 'TXT_CHEATPOWEROFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATHEALTH, 'TXT_CHEATHEALTH');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATSOUNDON, 'TXT_CHEATSOUNDON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATSOUNDOFF, 'TXT_CHEATSOUNDOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATTICKERON, 'TXT_CHEATTICKERON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATTICKEROFF, 'TXT_CHEATTICKEROFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATARTIFACTS1, 'TXT_CHEATARTIFACTS1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATARTIFACTS2, 'TXT_CHEATARTIFACTS2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATARTIFACTS3, 'TXT_CHEATARTIFACTS3');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATARTIFACTSFAIL, 'TXT_CHEATARTIFACTSFAIL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATWARP, 'TXT_CHEATWARP');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATSCREENSHOT, 'TXT_CHEATSCREENSHOT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATCHICKENON, 'TXT_CHEATCHICKENON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATCHICKENOFF, 'TXT_CHEATCHICKENOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATMASSACRE, 'TXT_CHEATMASSACRE');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATIDDQD, 'TXT_CHEATIDDQD');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @TXT_CHEATIDKFA, 'TXT_CHEATIDKFA');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSG_MODIFIEDGAME, 'MSG_MODIFIEDGAME');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSG_SHAREWARE, 'MSG_SHAREWARE');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSG_COMMERCIAL, 'MSG_COMMERCIAL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSG_UNDETERMINED, 'MSG_UNDETERMINED');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSGSECRETSECTOR, 'MSGSECRETSECTOR');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DETAILULTRA, 'DETAILULTRA');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DETAILHI, 'DETAILHI');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DETAILHI, 'DETAILHIGH');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DETAILNORM, 'DETAILNORM');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DETAILNORM, 'DETAILNORMAL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DETAILMED, 'DETAILMED');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DETAILMED, 'DETAILMEDIUM');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DETAILLOW, 'DETAILLO');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DETAILLOW, 'DETAILLOW');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DETAILLOWEST, 'DETAILLOWEST');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GAMMALVL0, 'GAMMALVL0');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GAMMALVL1, 'GAMMALVL1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GAMMALVL2, 'GAMMALVL2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GAMMALVL3, 'GAMMALVL3');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GAMMALVL4, 'GAMMALVL4');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @EMPTYSTRING, 'EMPTYSTRING');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @D_DEVSTR, 'D_DEVSTR');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @D_CDROM, 'D_CDROM');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PRESSKEY, 'PRESSKEY');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PRESSYN, 'PRESSYN');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @LOADNET, 'LOADNET');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @QLOADNET, 'QLOADNET');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @QSAVESPOT, 'QSAVESPOT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @SAVEDEAD, 'SAVEDEAD');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @QSPROMPT, 'QSPROMPT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @QLPROMPT, 'QLPROMPT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @SNEWGAME, 'SNEWGAME');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @SNIGHTMARE, 'SNIGHTMARE');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @SWSTRING, 'SWSTRING');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSGOFF, 'MSGOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSGON, 'MSGON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @NETEND, 'NETEND');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @SENDGAME, 'SENDGAME');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @DOSY, 'DOSY');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GGSAVED, 'GGSAVED');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @SAVEGAMENAME, 'SAVEGAMENAME');

  ammo_tokens := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(ammo_tokens, deh_tokens.AmmoFields);


  weapon_tokens := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(weapon_tokens, deh_tokens.WeaponFields);


  // MBF21
  weapon_flags_mbf21 := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(weapon_flags_mbf21, deh_tokens.WeaponFlagsMbf21);

  sound_tokens := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(sound_tokens, deh_tokens.SoundFields);


  renderstyle_tokens := TDTextList.Create;

  renderstyle_tokens.Add('NORMAL');
  renderstyle_tokens.Add('TRANSLUCENT');
  renderstyle_tokens.Add('ADD');
  renderstyle_tokens.Add('SUBTRACT');

  misc_tokens := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(misc_tokens, deh_tokens.MiscFields);


  C_AddCmd('DEH_ParseFile, BEX_ParseFile', @DEH_ParseFile);
  C_AddCmd('DEH_ParseLump, BEX_ParseLump', @DEH_ParseLumpName);
  C_AddCmd('DEH_PrintCurrentSettings, DEH_PrintSettings, BEX_PrintCurrentSettings, BEX_PrintSettings', @DEH_PrintCurrentSettings);
  C_AddCmd('DEH_SaveCurrentSettings, DEH_SaveToFile, BEX_SaveCurrentSettings, BEX_SaveToFile', @DEH_SaveCurrentSettings);
  C_AddCmd('DEH_SaveMobjInfoCSV, BEX_SaveMobjInfoCSV', @DEH_SaveMobjInfoCSV);
  C_AddCmd('DEH_SaveStatesCSV, BEX_SaveStatesCSV', @DEH_SaveStatesCSV);
  C_AddCmd('DEH_SaveSpritesCSV, BEX_SaveSpritesCSV', @DEH_SaveSpritesCSV);
  C_AddCmd('DEH_PrintActions, DEH_ShowActions, BEX_PrintActions, BEX_ShowActions', @DEH_PrintActions);
end;

//==============================================================================
//
// DEH_ShutDown
//
//==============================================================================
class procedure TDehMainRoutines.DEH_ShutDown;
begin
  if not deh_initialized then
    exit;

  FreeAndNil(mobj_tokens);
  FreeAndNil(mobj_flags);
  FreeAndNil(mobj_flags2);
  FreeAndNil(mobj_flags_ex);
  FreeAndNil(mobj_flags2_ex);
  FreeAndNil(mobj_flags3_ex);
  FreeAndNil(mobj_flags4_ex);
  FreeAndNil(mobj_flags5_ex);
  FreeAndNil(mobj_flags6_ex);
  FreeAndNil(mobj_flags_mbf21); // MBF21
  FreeAndNil(state_flags_ex);
  FreeAndNil(state_flags_mbf21);  // MBF21
  FreeAndNil(state_tokens);
  FreeAndNil(ammo_tokens);
  FreeAndNil(weapon_tokens);
  FreeAndNil(weapon_flags_mbf21); // MBF21
  FreeAndNil(sound_tokens);
  FreeAndNil(renderstyle_tokens);
  FreeAndNil(misc_tokens);
  FreeAndNil(weapontype_tokens);
  FreeAndNil(ammotype_tokens);
  // MBF21
  FreeAndNil(infighting_groups);
  FreeAndNil(projectile_groups);
  FreeAndNil(splash_groups);



  realloc(pointer(deh_strings._array), deh_strings.realnumstrings * SizeOf(deh_string_t), 0);
end;

end.

