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
  d_net,
  d_englsh,
  dstrings,
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
  p_musinfo,
  p_sounds,
  p_simpledialog,
  psi_overlay,
  sc_states,
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
  deh_strings._array[deh_strings.numstrings].name := ShortString(name);
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

  SC_FillStateNames;

  mobj_tokens := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_tokens, deh_tokens.ThingFields);



  mobj_flags := TDTextList.Create;
  TEngineDehackedTokenLists.Fill(mobj_flags, deh_tokens.MobjFlags);


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

  DEH_AddAction(@A_Light0, 'A_Light0()'); // 1
  DEH_AddAction(@TDoomWeaponActions.A_WeaponReady, 'A_WeaponReady()'); // 2
  DEH_AddAction(@A_Lower, 'A_Lower()'); // 3
  DEH_AddAction(@A_Raise, 'A_Raise()'); // 4
  DEH_AddAction(@TDoomWeaponActions.A_Punch, 'A_Punch()'); // 5
  DEH_AddAction(@A_ReFire, 'A_ReFire()'); // 6
  DEH_AddAction(@TDoomWeaponActions.A_FirePistol, 'A_FirePistol()'); // 7
  DEH_AddAction(@TDoomWeaponActions.A_Light1, 'A_Light1()'); // 8
  DEH_AddAction(@TDoomWeaponActions.A_FireShotgun, 'A_FireShotgun()'); // 9
  DEH_AddAction(@TDoomWeaponActions.A_Light2, 'A_Light2()'); // 10
  DEH_AddAction(@TDoomWeaponActions.A_FireShotgun2, 'A_FireShotgun2()'); // 11
  DEH_AddAction(@TDoomWeaponActions.A_CheckReload, 'A_CheckReload()'); // 12
  DEH_AddAction(@TDoomMonsterActions.A_OpenShotgun2, 'A_OpenShotgun2()'); // 13
  DEH_AddAction(@TDoomMonsterActions.A_LoadShotgun2, 'A_LoadShotgun2()'); // 14
  DEH_AddAction(@TDoomMonsterActions.A_CloseShotgun2, 'A_CloseShotgun2()'); // 15
  DEH_AddAction(@TDoomWeaponActions.A_FireCGun, 'A_FireCGun()'); // 16
  DEH_AddAction(@TDoomWeaponActions.A_GunFlash, 'A_GunFlash()'); // 17
  DEH_AddAction(@TDoomWeaponActions.A_FireMissile, 'A_FireMissile()'); // 18
  DEH_AddAction(@TDoomWeaponActions.A_Saw, 'A_Saw()'); // 19
  DEH_AddAction(@TDoomWeaponActions.A_FirePlasma, 'A_FirePlasma()'); // 20
  DEH_AddAction(@TDoomWeaponActions.A_BFGsound, 'A_BFGsound()'); // 21
  DEH_AddAction(@TDoomWeaponActions.A_FireBFG, 'A_FireBFG()'); // 22
  DEH_AddAction(@TDoomWeaponActions.A_BFGSpray, 'A_BFGSpray()'); // 23
  DEH_AddAction(@TDoomMonsterActions.A_Explode, 'A_Explode()'); // 24
  DEH_AddAction(@TDoomMonsterActions.A_Pain, 'A_Pain()'); // 25
  DEH_AddAction(@TDoomMonsterActions.A_PlayerScream, 'A_PlayerScream()'); // 26
  DEH_AddAction(@TDoomMonsterActions.A_Fall, 'A_Fall()'); // 27
  DEH_AddAction(@TDoomMonsterActions.A_XScream, 'A_XScream()'); // 28
  DEH_AddAction(@TDoomMonsterActions.A_Look, 'A_Look()'); // 29
  DEH_AddAction(@TMonsterBaseActions.A_Chase, 'A_Chase()'); // 30
  DEH_AddAction(@A_FaceTarget, 'A_FaceTarget()'); // 31
  DEH_AddAction(@TDoomMonsterActions.A_PosAttack, 'A_PosAttack()'); // 32
  DEH_AddAction(@TMonsterBaseActions.A_Scream, 'A_Scream()'); // 33
  DEH_AddAction(@TDoomMonsterActions.A_SPosAttack, 'A_SPosAttack()'); // 34
  DEH_AddAction(@TDoomMonsterActions.A_VileChase, 'A_VileChase()'); // 35
  DEH_AddAction(@TDoomMonsterActions.A_VileStart, 'A_VileStart()'); // 36
  DEH_AddAction(@TDoomMonsterActions.A_VileTarget, 'A_VileTarget()'); // 37
  DEH_AddAction(@TDoomMonsterActions.A_VileAttack, 'A_VileAttack()'); // 38
  DEH_AddAction(@TDoomMonsterActions.A_StartFire, 'A_StartFire()'); // 39
  DEH_AddAction(@TDoomMonsterActions.A_Fire, 'A_Fire()'); // 40
  DEH_AddAction(@TDoomMonsterActions.A_FireCrackle, 'A_FireCrackle()'); // 41
  DEH_AddAction(@TDoomMonsterActions.A_Tracer, 'A_Tracer()'); // 42
  DEH_AddAction(@TDoomMonsterActions.A_SkelWhoosh, 'A_SkelWhoosh()'); // 43
  DEH_AddAction(@TDoomMonsterActions.A_SkelFist, 'A_SkelFist()'); // 44
  DEH_AddAction(@TDoomMonsterActions.A_SkelMissile, 'A_SkelMissile()'); // 45
  DEH_AddAction(@TDoomMonsterActions.A_FatRaise, 'A_FatRaise()'); // 46
  DEH_AddAction(@TDoomMonsterActions.A_FatAttack1, 'A_FatAttack1()'); // 47
  DEH_AddAction(@TDoomMonsterActions.A_FatAttack2, 'A_FatAttack2()'); // 48
  DEH_AddAction(@TDoomMonsterActions.A_FatAttack3, 'A_FatAttack3()'); // 49
  DEH_AddAction(@TDoomMonsterActions.A_BossDeath, 'A_BossDeath()'); // 50
  DEH_AddAction(@TDoomMonsterActions.A_CPosAttack, 'A_CPosAttack()'); // 51
  DEH_AddAction(@TDoomMonsterActions.A_CPosRefire, 'A_CPosRefire()'); // 52
  DEH_AddAction(@TDoomMonsterActions.A_TroopAttack, 'A_TroopAttack()'); // 53
  DEH_AddAction(@TDoomMonsterActions.A_SargAttack, 'A_SargAttack()'); // 54
  DEH_AddAction(@TDoomMonsterActions.A_HeadAttack, 'A_HeadAttack()'); // 55
  DEH_AddAction(@TDoomMonsterActions.A_BruisAttack, 'A_BruisAttack()'); // 56
  DEH_AddAction(@TDoomMonsterActions.A_SkullAttack, 'A_SkullAttack()'); // 57
  DEH_AddAction(@TDoomMonsterActions.A_Metal, 'A_Metal()'); // 58
  DEH_AddAction(@TDoomMonsterActions.A_SpidRefire, 'A_SpidRefire()'); // 59
  DEH_AddAction(@TDoomMonsterActions.A_BabyMetal, 'A_BabyMetal()'); // 60
  DEH_AddAction(@TDoomMonsterActions.A_BspiAttack, 'A_BspiAttack()'); // 61
  DEH_AddAction(@TDoomMonsterActions.A_Hoof, 'A_Hoof()'); // 62
  DEH_AddAction(@TDoomMonsterActions.A_CyberAttack, 'A_CyberAttack()'); // 63
  DEH_AddAction(@TDoomMonsterActions.A_PainAttack, 'A_PainAttack()'); // 64
  DEH_AddAction(@TDoomMonsterActions.A_PainDie, 'A_PainDie()'); // 65
  DEH_AddAction(@TDoomMonsterActions.A_KeenDie, 'A_KeenDie()'); // 66
  DEH_AddAction(@TDoomMonsterActions.A_BrainPain, 'A_BrainPain()'); // 67
  DEH_AddAction(@TDoomMonsterActions.A_BrainScream, 'A_BrainScream()'); // 68
  DEH_AddAction(@TDoomMonsterActions.A_BrainDie, 'A_BrainDie()'); // 69
  DEH_AddAction(@TDoomMonsterActions.A_BrainAwake, 'A_BrainAwake()'); // 70
  DEH_AddAction(@TDoomMonsterActions.A_BrainSpit, 'A_BrainSpit()'); // 71
  DEH_AddAction(@TDoomMonsterActions.A_SpawnSound, 'A_SpawnSound()'); // 72
  DEH_AddAction(@TDoomMonsterActions.A_SpawnFly, 'A_SpawnFly()'); // 73
  DEH_AddAction(@TDoomMonsterActions.A_BrainExplode, 'A_BrainExplode()'); // 74
  // Custom actions
  DEH_AddAction(@TCommonSoundActions.A_CustomSound1, 'A_CustomSound1()'); // 75
  DEH_AddAction(@TCommonSoundActions.A_CustomSound2, 'A_CustomSound2()'); // 76
  DEH_AddAction(@TCommonSoundActions.A_CustomSound3, 'A_CustomSound3()'); // 77
  DEH_AddAction(@TCommonSoundActions.A_RandomPainSound, 'A_RandomPainSound()'); // 78
  DEH_AddAction(@TCommonSoundActions.A_RandomSeeSound, 'A_RandomSeeSound()'); // 79
  DEH_AddAction(@TCommonSoundActions.A_RandomAttackSound, 'A_RandomAttackSound()'); // 80
  DEH_AddAction(@TCommonSoundActions.A_RandomDeathSound, 'A_RandomDeathSound()'); // 81
  DEH_AddAction(@TCommonSoundActions.A_RandomActiveSound, 'A_RandomActiveSound()'); // 82
  DEH_AddAction(@TCommonSoundActions.A_RandomCustomSound1, 'A_RandomCustomSound1()'); // 83
  DEH_AddAction(@TCommonSoundActions.A_RandomCustomSound2, 'A_RandomCustomSound2()'); // 84
  DEH_AddAction(@TCommonSoundActions.A_RandomCustomSound3, 'A_RandomCustomSound3()'); // 85
  DEH_AddAction(@TCommonSoundActions.A_RandomCustomSound, 'A_RandomCustomSound()'); // 86
  DEH_AddAction(@TExtraRoutines.A_AnnihilatorAttack, 'A_AnnihilatorAttack()'); // 87
  DEH_AddAction(@TCommonSoundActions.A_Playsound, 'A_Playsound(sound: string)'); // 88
  DEH_AddAction(@TCommonSoundActions.A_RandomSound, 'A_RandomSound(sound1: string, [sound2: string], ...)'); // 89
  DEH_AddAction(@TCommonMovementActions.A_Stop, 'A_Stop()'); // 90
  DEH_AddAction(@TCommonJumpActions.A_Jump, 'A_Jump(propability: random_t, offset1: integer, [offset2: integer], ...)'); // 91
  DEH_AddAction(@TCommonSpawnActions.A_CustomMissile, 'A_CustomMissile(missiletype: string, [height: integer], [offset: integer], [angle: integer], [aimmode: integer], [pitch: integer])'); // 92
  DEH_AddAction(@TExtraRoutines.A_NoGravity, 'A_NoGravity()'); // 93
  DEH_AddAction(@TExtraRoutines.A_Gravity, 'A_Gravity()'); // 94
  DEH_AddAction(@TExtraRoutines.A_NoBlocking, 'A_NoBlocking()'); // 95
  DEH_AddAction(@TExtraRoutines.A_MeleeAttack, 'A_MeleeAttack([mindamage: integer], [maxdamage: integer])'); // 96
  DEH_AddAction(@TCommonSpawnActions.A_SpawnItem, 'A_SpawnItem(type: string, [distance: float], [zheight: float], [angle: angle])'); // 97
  DEH_AddAction(@TCommonSpawnActions.A_SeekerMissile, 'A_SeekerMissile(threshold_angle: angle, [turnMax_angle: angle])'); // 98
  DEH_AddAction(@TCommonGameDependentActions.A_CStaffMissileSlither, 'A_CStaffMissileSlither()'); // 99
  DEH_AddAction(@TCommonAppearanceActions.A_SetTranslucent, 'A_SetTranslucent(alpha: float, [style: integer])'); // 100
  DEH_AddAction(@TExtraRoutines.A_Die, 'A_Die()'); // 101
  DEH_AddAction(@TExtraRoutines.A_CustomBulletAttack, 'A_CustomBulletAttack(spread_xy: angle, numbullets: integer, damageperbullet: integer, [range: integer])'); // 102
  DEH_AddAction(@TCommonAppearanceActions.A_FadeOut, 'A_FadeOut(fade: float)'); // 103
  DEH_AddAction(@TCommonAppearanceActions.A_FadeIn, 'A_FadeIn(fade: float)'); // 104
  DEH_AddAction(@TCommonAttackActions.A_MissileAttack, 'A_MissileAttack([missiletype: string])'); // 105
  DEH_AddAction(@TCommonMovementActions.A_AdjustSideSpot, 'A_AdjustSideSpot(sideoffset: float)'); // 106
  DEH_AddAction(@TExtraRoutines.A_Countdown, 'A_Countdown()'); // 107
  DEH_AddAction(@TExtraRoutines.A_FastChase, 'A_FastChase()'); // 108
  DEH_AddAction(@TExtraRoutines.A_LowGravity, 'A_LowGravity()'); // 109
  DEH_AddAction(@TCommonMovementActions.A_ThrustZ, 'A_ThrustZ(momz: float)'); // 110
  DEH_AddAction(@TCommonMovementActions.A_ThrustXY, 'A_ThrustXY(mom: float, ang: angle)'); // 111
  DEH_AddAction(@TCommonMovementActions.A_Turn, 'A_Turn(value: angle)'); // 112
  DEH_AddAction(@TCommonJumpActions.A_JumpIfCloser, 'A_JumpIfCloser(distancetotarget: float, offset: integer)'); // 113
  DEH_AddAction(@TCommonJumpActions.A_JumpIfHealthLower, 'A_JumpIfHealthLower(health: integer, offset: integer)'); // 114
  DEH_AddAction(@TCommonDamageActions.A_ScreamAndUnblock, 'A_ScreamAndUnblock()'); // 115
  DEH_AddAction(@TCommonSoundActions.A_PlayWeaponsound, 'A_PlayWeaponsound(sound: string)'); // 116
  DEH_AddAction(@TExtraRoutines.A_SetInvulnerable, 'A_SetInvulnerable()'); // 117
  DEH_AddAction(@TExtraRoutines.A_UnSetInvulnerable, 'A_UnSetInvulnerable()'); // 118
  DEH_AddAction(@TCommonSoundActions.A_RandomMeleeSound, 'A_RandomMeleeSound()'); // 119
  DEH_AddAction(@TExtraRoutines.A_FloatBob, 'A_FloatBob()'); // 120
  DEH_AddAction(@TExtraRoutines.A_NoFloatBob, 'A_NoFloatBob()'); // 121
  DEH_AddAction(@TCommonStateBitActions.A_Missile, 'A_Missile()'); // 122
  DEH_AddAction(@TCommonStateBitActions.A_NoMissile, 'A_NoMissile()'); // 123
  DEH_AddAction(@TExtraRoutines.A_ComboAttack, 'A_ComboAttack()'); // 124
  DEH_AddAction(@TExtraRoutines.A_BulletAttack, 'A_BulletAttack([numbullets: integer])'); // 125
  DEH_AddAction(@TExtraRoutines.A_MediumGravity, 'A_MediumGravity()'); // 126
  DEH_AddAction(@TCommonMovementActions.A_Wander, 'A_Wander()'); // 127
  DEH_AddAction(@TCommonAppearanceActions.A_FadeOut10, 'A_FadeOut10()'); // 128
  DEH_AddAction(@TCommonAppearanceActions.A_FadeOut20, 'A_FadeOut20()'); // 129
  DEH_AddAction(@TCommonAppearanceActions.A_FadeOut30, 'A_FadeOut30()'); // 130
  DEH_AddAction(@TCommonAppearanceActions.A_FadeIn10, 'A_FadeIn10()'); // 131
  DEH_AddAction(@TCommonAppearanceActions.A_FadeIn20, 'A_FadeIn20()'); // 132
  DEH_AddAction(@TCommonAppearanceActions.A_FadeIn30, 'A_FadeIn30()'); // 133
  DEH_AddAction(@TCommonSpawnActions.A_SpawnItemEx, 'A_SpawnItemEx(itemtype: string, [xofs: float], [yofs: float], [zofs: float], [momx: float], [momy: float], [momz: float], [ang: angle], [flags: integer], [chance: integer])'); // 134
  DEH_AddAction(@TCommonSpawnActions.A_RandomMissile, 'A_RandomMissile(missile1: string, [missile2: string], ...)'); // 135
  DEH_AddAction(@TExtraRoutines.A_HideThing, 'A_HideThing()'); // 136
  DEH_AddAction(@TExtraRoutines.A_UnHideThing, 'A_UnHideThing()'); // 137
  DEH_AddAction(@TExtraRoutines.A_SpawnDebris, 'A_SpawnDebris(debristype: string, [count: integer = 1], [horz_mom: integer], [vert_mom: integer])'); // 138
  DEH_AddAction(@TCommonMovementActions.A_Turn5, 'A_Turn5()'); // 139
  DEH_AddAction(@TCommonMovementActions.A_Turn10, 'A_Turn10()'); // 140
  DEH_AddAction(@TExtraRoutines.A_SpawnSmokeUp, 'A_SpawnSmokeUp()'); // 141
  DEH_AddAction(@TExtraRoutines.A_SpawnSmokeDown, 'A_SpawnSmokeDown()'); // 142
  DEH_AddAction(@TExtraRoutines.A_SpawnSmokeHorz, 'A_SpawnSmokeHorz(height: integer)'); // 143
  DEH_AddAction(@TCommonStateBitActions.A_SetInteractive, 'A_SetInteractive()'); // 144
  DEH_AddAction(@TCommonStateBitActions.A_UnSetInteractive, 'A_UnSetInteractive()'); // 145
  DEH_AddAction(@TCommonStateBitActions.A_SetMonsterInfight, 'A_SetMonsterInfight()'); // 146
  DEH_AddAction(@TCommonStateBitActions.A_UnSetMonsterInfight, 'A_UnSetMonsterInfight()'); // 147
  DEH_AddAction(@P_RemoveMobj, 'A_RemoveSelf()'); // 148
  DEH_AddAction(@TCommonSearchActions.A_NoiseAlert, 'A_NoiseAlert()'); // 149
  DEH_AddAction(@TCommonStateParamActions.A_ConsoleCommand, 'A_ConsoleCommand(cmd: string, [parm1: string], [parm2: string], ...)'); // 150
  DEH_AddAction(@TCommonCustomParamActions.A_SetCustomParam, 'A_SetCustomParam(param: string, value: integer)'); // 151
  DEH_AddAction(@TCommonCustomParamActions.A_AddCustomParam, 'A_AddCustomParam(param: string, value: integer)'); // 152
  DEH_AddAction(@TCommonCustomParamActions.A_SubtractCustomParam, 'A_SubtractCustomParam(param: string, value: integer)'); // 153
  DEH_AddAction(@TCommonCustomParamActions.A_SetTargetCustomParam, 'A_SetTargetCustomParam(param: string, value: integer)'); // 154
  DEH_AddAction(@TCommonCustomParamActions.A_AddTargetCustomParam, 'A_AddTargetCustomParam(param: string, value: integer)'); // 155
  DEH_AddAction(@TCommonCustomParamActions.A_SubtractTargetCustomParam, 'A_SubtractTargetCustomParam(param: string, value: integer)'); // 156
  DEH_AddAction(@TCommonJumpActions.A_JumpIfCustomParam, 'A_JumpIfCustomParam(param: string, value: integer, offset: integer)'); // 157
  DEH_AddAction(@TCommonJumpActions.A_JumpIfCustomParamLess, 'A_JumpIfCustomParamLess(param: string, value: integer, offset: integer)'); // 158
  DEH_AddAction(@TCommonJumpActions.A_JumpIfCustomParamGreater, 'A_JumpIfCustomParamGreater(param: string, value: integer, offset: integer)'); // 159
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetCustomParam, 'A_JumpIfTargetCustomParam(param: string, value: integer, offset: integer)'); // 160
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetCustomParamLess, 'A_JumpIfTargetCustomParamLess(param: string, value: integer, offset: integer)'); // 161
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetCustomParamGreater, 'A_JumpIfTargetCustomParamGreater(param: string, value: integer, offset: integer)'); // 162
  DEH_AddAction(@TExtraRoutines.A_SetShootable, 'A_SetShootable()'); // 163
  DEH_AddAction(@TExtraRoutines.A_UnSetShootable, 'A_UnSetShootable()'); // 164
  DEH_AddAction(@TExtraRoutines.A_PlayerMessage, 'A_PlayerMessage(msg1: string, [msg2: string], ...)'); // 165
  DEH_AddAction(@TExtraRoutines.A_PlayerFaceMe, 'A_PlayerFaceMe(tics: integer)'); // 166
  DEH_AddAction(@TCommonJumpActions.A_GoTo, 'A_GoTo(propability: random_t, state: state_t)'); // 167
  DEH_AddAction(@TCommonJumpActions.A_GoToIfCloser, 'A_GoToIfCloser(distancetotarget: float, state: state_t)'); // 168
  DEH_AddAction(@TCommonJumpActions.A_GoToIfHealthLower, 'A_GoToIfHealthLower(health: integer, state: state_t)'); // 169
  DEH_AddAction(@TCommonJumpActions.A_GoToIfCustomParam, 'A_GoToIfCustomParam(param: string, value: integer, state: state_t)'); // 170
  DEH_AddAction(@TCommonJumpActions.A_GoToIfCustomParamLess, 'A_GoToIfCustomParamLess(param: string, value: integer, state: state_t)'); // 171
  DEH_AddAction(@TCommonJumpActions.A_GoToIfCustomParamGreater, 'A_GoToIfCustomParamGreater(param: string, value: integer, state: state_t)'); // 172
  DEH_AddAction(@TCommonJumpActions.A_GoToIfTargetCustomParam, 'A_GoToIfTargetCustomParam(param: string, value: integer, state: state_t)'); // 173
  DEH_AddAction(@TCommonJumpActions.A_GoToIfTargetCustomParamLess, 'A_GoToIfTargetCustomParamLess(param: string, value: integer, state: state_t)'); // 174
  DEH_AddAction(@TCommonJumpActions.A_GoToIfTargetCustomParamGreater, 'A_GoToIfTargetCustomParamGreater(param: string, value: integer, state: state_t)'); // 175
  DEH_AddAction(@TExtraRoutines.A_SetFloorClip, 'A_SetFloorClip()'); // 176
  DEH_AddAction(@TExtraRoutines.A_UnSetFloorClip, 'A_UnSetFloorClip()'); // 177
  DEH_AddAction(@TCommonStateBitActions.A_SetFrightened, 'A_SetFrightened()'); // 178
  DEH_AddAction(@TCommonStateBitActions.A_UnSetFrightened, 'A_UnSetFrightened()'); // 179
  DEH_AddAction(@TCommonStateBitActions.A_SetNoDamage, 'A_SetNoDamage()'); // 180
  DEH_AddAction(@TCommonStateBitActions.A_UnSetNoDamage, 'A_UnSetNoDamage()'); // 181
  DEH_AddAction(@A_RunScript, 'A_RunScript(script1: string, [script2: string], ...)'); // 182
  DEH_AddAction(@TCommonAppearanceActions.A_GhostOn, 'A_GhostOn()'); // 183
  DEH_AddAction(@TCommonAppearanceActions.A_GhostOff, 'A_GhostOff()'); // 184
  DEH_AddAction(@TCommonStateBitActions.A_Blocking, 'A_Blocking()'); // 185
  DEH_AddAction(@TCommonStateBitActions.A_DoNotRunScripts, 'A_DoNotRunScripts()'); // 186
  DEH_AddAction(@TCommonStateBitActions.A_DoRunScripts, 'A_DoRunScripts()'); // 187
  DEH_AddAction(@TCommonStateParamActions.A_TargetDropItem, 'A_TargetDropItem(dropitemtype: string)'); // 188
  DEH_AddAction(@TCommonStateParamActions.A_DefaultTargetDropItem, 'A_DefaultTargetDropItem()'); // 189
  DEH_AddAction(@TCommonStateParamActions.A_SetDropItem, 'A_SetDropItem(dropitemtype: string)'); // 190
  DEH_AddAction(@TCommonStateParamActions.A_SetDefaultDropItem, 'A_SetDefaultDropItem()'); // 191
  DEH_AddAction(@TCommonSearchActions.A_GlobalEarthQuake, 'A_GlobalEarthQuake(tics: integer)'); // 192
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapStringEqual, 'A_JumpIfMapStringEqual(parm: string, value: string, offset; integer)'); // 193
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapStringLess, 'A_JumpIfMapStringLess(parm: string, value: string, offset; integer)'); // 194
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapStringGreater, 'A_JumpIfMapStringGreater(parm: string, value: string, offset; integer)'); // 195
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapIntegerEqual, 'A_JumpIfMapIntegerEqual(parm: string, value: integer, offset: integer)'); // 196
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapIntegerLess, 'A_JumpIfMapIntegerLess(parm: string, value: integer, offset: integer)'); // 197
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapIntegerGreater, 'A_JumpIfMapIntegerGreater(parm: string, value: integer, offset: integer)'); // 198
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapFloatEqual, 'A_JumpIfMapFloatEqual(parm: string, value: float, offset: integer)'); // 199
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapFloatLess, 'A_JumpIfMapFloatLess(parm: string, value: float, offset: integer)'); // 200
  DEH_AddAction(@TCommonJumpActions.A_JumpIfMapFloatGreater, 'A_JumpIfMapFloatGreater(parm: string, value: float, offset: integer)'); // 201
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldStringEqual, 'A_JumpIfWorldStringEqual(parm: string, value: string, offset: integer)'); // 202
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldStringLess, 'A_JumpIfWorldStringLess(parm: string, value: string, offset: integer)'); // 203
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldStringGreater, 'A_JumpIfWorldStringGreater(parm: string, value: string, offset: integer)'); // 204
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldIntegerEqual, 'A_JumpIfWorldIntegerEqual(parm: string, value: integer, offset: integer)'); // 205
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldIntegerLess, 'A_JumpIfWorldIntegerLess(parm: string, value: integer, offset: integer)'); // 206
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldIntegerGreater, 'A_JumpIfWorldIntegerGreater(parm: string, value: integer, offset: integer)'); // 207
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldFloatEqual, 'A_JumpIfWorldFloatEqual(parm: string, value: float, offset: integer)'); // 208
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldFloatLess, 'A_JumpIfWorldFloatLess(parm: string, value: float, offset: integer)'); // 209
  DEH_AddAction(@TCommonJumpActions.A_JumpIfWorldFloatGreater, 'A_JumpIfWorldFloatGreater(parm: string, value: float, offset: integer)'); // 210
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapStringEqual, 'A_GoToIfMapStringEqual(parm: string, value: string, state: state_t)'); // 211
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapStringLess, 'A_GoToIfMapStringLess(parm: string, value: string, state: state_t)'); // 212
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapStringGreater, 'A_GoToIfMapStringGreater(parm: string, value: string, state: state_t)'); // 213
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapIntegerEqual, 'A_GoToIfMapIntegerEqual(parm: string, value: integer, state: state_t)'); // 214
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapIntegerLess, 'A_GoToIfMapIntegerLess(parm: string, value: integer, state: state_t)'); // 215
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapIntegerGreater, 'A_GoToIfMapIntegerGreater(parm: string, value: integer, state: state_t)'); // 216
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapFloatEqual, 'A_GoToIfMapFloatEqual(parm: string, value: float, state: state_t)'); // 217
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapFloatLess, 'A_GoToIfMapFloatLess(parm: string, value: float, state: state_t)'); // 218
  DEH_AddAction(@TCommonJumpActions.A_GoToIfMapFloatGreater, 'A_GoToIfMapFloatGreater(parm: string, value: float, state: state_t)'); // 219
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldStringEqual, 'A_GoToIfWorldStringEqual(parm: string, value: string, state: state_t)'); // 220
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldStringLess, 'A_GoToIfWorldStringLess(parm: string, value: string, state: state_t)'); // 221
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldStringGreater, 'A_GoToIfWorldStringGreater(parm: string, value: string, state: state_t)'); // 222
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldIntegerEqual, 'A_GoToIfWorldIntegerEqual(parm: string, value: integer, state: state_t)'); // 223
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldIntegerLess, 'A_GoToIfWorldIntegerLess(parm: string, value: integer, state: state_t)'); // 224
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldIntegerGreater, 'A_GoToIfWorldIntegerGreater(parm: string, value: integer, state: state_t)'); // 225
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldFloatEqual, 'A_GoToIfWorldFloatEqual(parm: string, value: float, state: state_t)'); // 226
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldFloatLess, 'A_GoToIfWorldFloatLess(parm: string, value: float, state: state_t)'); // 227
  DEH_AddAction(@TCommonJumpActions.A_GoToIfWorldFloatGreater, 'A_GoToIfWorldFloatGreater(parm: string, value: float, state: state_t)'); // 228
  DEH_AddAction(@TCommonCustomParamActions.A_SetMapStr, 'A_SetMapStr(mvar: string, value1: string, [value2: string],...)'); // 229
  DEH_AddAction(@TCommonCustomParamActions.A_SetWorldStr, 'A_SetWorldStr(wvar: string, value1: string, [value2: string],...)'); // 230
  DEH_AddAction(@TCommonCustomParamActions.A_SetMapInt, 'A_SetMapInt(mvar: string, value: integer)'); // 231
  DEH_AddAction(@TCommonCustomParamActions.A_SetWorldInt, 'A_SetWorldInt(wvar: string, value: integer)'); // 232
  DEH_AddAction(@TCommonCustomParamActions.A_SetMapFloat, 'A_SetMapFloat(mvar: string, value: float)'); // 233
  DEH_AddAction(@TCommonCustomParamActions.A_SetWorldFloat, 'A_SetWorldFloat(wvar: string, value: float)'); // 234
  DEH_AddAction(@TCommonJumpActions.A_RandomGoto, 'A_RandomGoto(state1: state_t; [state2: state_t],...)'); // 235
  DEH_AddAction(@TCommonDamageActions.A_ResetHealth, 'A_ResetHealth()'); // 236
  DEH_AddAction(@TCommonMovementActions.A_Recoil, 'A_Recoil(xymom: float)'); // 237
  DEH_AddAction(@TCommonStateBitActions.A_SetSolid, 'A_SetSolid()'); // 238
  DEH_AddAction(@TCommonStateBitActions.A_UnSetSolid, 'A_UnSetSolid()'); // 239
  DEH_AddAction(@TCommonStateBitActions.A_SetFloat, 'A_SetFloat()'); // 240
  DEH_AddAction(@TCommonStateBitActions.A_UnSetFloat, 'A_UnSetFloat()'); // 241
  DEH_AddAction(@TCommonDamageActions.A_SetHealth, 'A_SetHealth(h: integer)'); // 242
  DEH_AddAction(@TCommonDamageActions.A_ResetTargetHealth, 'A_ResetTargetHealth()'); // 243
  DEH_AddAction(@TCommonDamageActions.A_SetTargetHealth, 'A_SetTargetHealth(h: integer)'); // 244
  DEH_AddAction(@TCommonMovementActions.A_ScaleVelocity, 'A_ScaleVelocity(scale: float)'); // 245
  DEH_AddAction(@TCommonMovementActions.A_ChangeVelocity, 'A_ChangeVelocity(velx: float, vely: float, velz: float, flags: float)'); // 246
  DEH_AddAction(@TCommonJumpActions.A_JumpIf, 'A_JumpIf(propability: boolean, offset1: integer, [offset2: integer], ...)'); // 247
  DEH_AddAction(@A_MusicChanger, 'A_MusicChanger()'); // 248
  DEH_AddAction(@TCommonStateBitActions.A_SetPushFactor, 'A_SetPushFactor(f: float)'); // 249
  DEH_AddAction(@TCommonAppearanceActions.A_SetScale, 'A_SetScale(s: float)'); // 250
  DEH_AddAction(@TCommonStateBitActions.A_SetGravity, 'A_SetGravity(g: float)'); // 251
  DEH_AddAction(@TCommonStateBitActions.A_SetFloorBounce, 'A_SetFloorBounce()'); // 252
  DEH_AddAction(@TCommonStateBitActions.A_UnSetFloorBounce, 'A_UnSetFloorBounce()'); // 253
  DEH_AddAction(@TCommonStateBitActions.A_SetCeilingBounce, 'A_SetCeilingBounce()'); // 254
  DEH_AddAction(@TCommonStateBitActions.A_UnSetCeilingBounce, 'A_UnSetCeilingBounce()'); // 255
  DEH_AddAction(@TCommonStateBitActions.A_SetWallBounce, 'A_SetWallBounce()'); // 256
  DEH_AddAction(@TCommonStateBitActions.A_UnSetWallBounce, 'A_UnSetWallBounce()'); // 257
  DEH_AddAction(@TCommonAppearanceActions.A_GlowLight, 'A_GlowLight(color: string)'); // 258
  DEH_AddAction(@TCommonMovementActions.A_TraceNearestPlayer, 'A_TraceNearestPlayer(pct: integer, [maxturn: angle_t])'); // 259
  DEH_AddAction(@TCommonGameDependentActions.A_ChangeFlag, 'A_ChangeFlag(flag: string, onoff: boolean)'); // 260
  DEH_AddAction(@TCommonSearchActions.A_CheckFloor, 'A_CheckFloor(offset: integer)'); // 261
  DEH_AddAction(@TCommonSearchActions.A_CheckCeiling, 'A_CheckCeiling(offset: integer)'); // 262
  DEH_AddAction(@TCommonSoundActions.A_StopSound, 'A_StopSound()'); // 263
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetOutsideMeleeRange, 'A_JumpIfTargetOutsideMeleeRange(offset: integer)'); // 264
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTargetInsideMeleeRange, 'A_JumpIfTargetInsideMeleeRange(offset: integer)'); // 265
  DEH_AddAction(@TCommonJumpActions.A_JumpIfTracerCloser, 'A_JumpIfTracerCloser(distancetotarget: float, offset: integer)'); // 266
  DEH_AddAction(@TCommonStateBitActions.A_SetMass, 'A_SetMass(mass: integer)'); // 267
  DEH_AddAction(@TCommonStateBitActions.A_SetTargetMass, 'A_SetTargetMass(mass: integer)'); // 268
  DEH_AddAction(@TCommonStateBitActions.A_SetTracerMass, 'A_SetTracerMass(mass: integer)'); // 269
  DEH_AddAction(@TCommonSearchActions.A_CheckSight, 'A_CheckSight(offset: integer)'); // 270
  DEH_AddAction(@TCommonSearchActions.A_CheckSightOrRange, 'A_CheckSightOrRange(distance: float, offset: integer, [twodi: boolean=false])'); // 271
  DEH_AddAction(@TCommonSearchActions.A_CheckRange, 'A_CheckRange(distance: float, offset: integer, [twodi: boolean=false])'); // 272
  DEH_AddAction(@TCommonStateParamActions.A_CountdownArg, 'A_CountdownArg(arg: integer, offset: integer)'); // 273
  DEH_AddAction(@TCommonStateParamActions.A_SetArg, 'A_SetArg(arg: integer, value: integer)'); // 274
  DEH_AddAction(@TCommonStateParamActions.A_SetSpecial, 'A_SetSpecial(special: integer, [arg1, arg2, arg3, arg4, arg5: integer])'); // 275
  DEH_AddAction(@TCommonGameDependentActions.A_CheckFlag, 'A_CheckFlag(flag: string, offset: integer, [aaprt: AAPTR])'); // 276
  DEH_AddAction(@TCommonMovementActions.A_SetAngle, 'A_SetAngle(angle: integer, [flags: integer], [aaprt: AAPTR])'); // 277
  DEH_AddAction(@TCommonCustomParamActions.A_SetUserVar, 'A_SetUserVar(varname: string, value: integer)'); // 278
  DEH_AddAction(@TCommonCustomParamActions.A_SetUserArray, 'A_SetUserArray(varname: string, index: integer, value: integer)'); // 279
  DEH_AddAction(@TCommonStateParamActions.A_SetTics, 'A_SetTics(tics: integer)'); // 280
  DEH_AddAction(@TCommonGameDependentActions.A_DropItem, 'A_DropItem(spawntype: string, amount: integer, chance: integer)'); // 281
  DEH_AddAction(@TCommonDamageActions.A_DamageSelf, 'A_DamageSelf(actor: Pmobj_t)'); // 282
  DEH_AddAction(@TCommonDamageActions.A_DamageTarget, 'A_DamageTarget(const damage: integer)'); // 283
  DEH_AddAction(@TCommonDamageActions.A_DamageTracer, 'A_DamageTracer(const damage: integer)'); // 284
  DEH_AddAction(@TCommonDamageActions.A_KillTarget, 'A_KillTarget()'); // 285
  DEH_AddAction(@TCommonDamageActions.A_KillTracer, 'A_KillTracer()'); // 286
  DEH_AddAction(@TCommonDamageActions.A_RemoveTarget, 'A_RemoveTarget([flags: integer])'); // 287
  DEH_AddAction(@TCommonDamageActions.A_RemoveTracer, 'A_RemoveTracer([flags: integer])'); // 288
  DEH_AddAction(@TCommonDamageActions.A_Remove, 'A_Remove(aaprt: AAPTR, [flags: integer])'); // 289
  DEH_AddAction(@TCommonStateBitActions.A_SetFloatBobPhase, 'A_SetFloatBobPhase(bob: integer)'); // 290
  DEH_AddAction(@TCommonGameDependentActions.A_Detonate, 'A_Detonate()'); // 291
  DEH_AddAction(@TExtraRoutines.A_Mushroom, 'A_Mushroom()'); // 292
  DEH_AddAction(@TExtraRoutines.A_BetaSkullAttack, 'A_BetaSkullAttack()'); // 293
  DEH_AddAction(@TExtraRoutines.A_FireOldBFG, 'A_FireOldBFG()'); // 294
  DEH_AddAction(@TCommonSpawnActions.A_Spawn, 'A_Spawn()'); // 295
  DEH_AddAction(@TCommonMovementActions.A_Face, 'A_Face()'); // 296
  DEH_AddAction(@TCommonAttackActions.A_Scratch, 'A_Scratch()'); // 297
  DEH_AddAction(@TCommonJumpActions.A_RandomJump, 'A_RandomJump()'); // 298
  DEH_AddAction(@TCommonStateParamActions.A_LineEffect, 'A_LineEffect()'); // 299
  DEH_AddAction(@TCommonAppearanceActions.A_FlipSprite, 'A_FlipSprite()'); // 300
  DEH_AddAction(@TCommonAppearanceActions.A_NoFlipSprite, 'A_NoFlipSprite()'); // 301
  DEH_AddAction(@TCommonAppearanceActions.A_RandomFlipSprite, 'A_RandomFlipSprite(chance: integer)'); // 302
  DEH_AddAction(@TCommonAppearanceActions.A_RandomNoFlipSprite, 'A_RandomNoFlipSprite(chance: integer)'); // 303
  DEH_AddAction(@TCommonAttackActions.A_CustomMeleeAttack, 'A_CustomMeleeAttack(damage: integer, meleesound: string, misssound: string)'); // 304
  DEH_AddAction(@TCommonAttackActions.A_CustomComboAttack, 'A_CustomComboAttack(missiletype: string, spawnheight: integer, damage: integer, meleesound: string)'); // 305
  DEH_AddAction(@TCommonAppearanceActions.A_SetRenderStyle, 'A_SetRenderStyle(style: renderstyle_t, alpha: float)'); // 306
  DEH_AddAction(@TCommonAppearanceActions.A_FadeTo, 'A_FadeTo(targ: integer, ammount: integer, flags: integer)'); // 307
  DEH_AddAction(@TCommonStateBitActions.A_SetSize, 'A_SetSize(newradius: integer, newheight: integer, testpos: boolean)'); // 308
  DEH_AddAction(@TCommonDamageActions.A_RaiseMaster, 'A_RaiseMaster(copyfriendliness: boolean)'); // 309
  DEH_AddAction(@TCommonDamageActions.A_RaiseChildren, 'A_RaiseChildren(copyfriendliness: boolean)'); // 310
  DEH_AddAction(@TCommonDamageActions.A_RaiseSiblings, 'A_RaiseSiblings(copyfriendliness: boolean)'); // 311
  DEH_AddAction(@TCommonStateBitActions.A_SetMasterMass, 'A_SetMasterMass(mass: integer)'); // 312
  DEH_AddAction(@TCommonDamageActions.A_KillMaster, 'A_KillMaster()'); // 313
  DEH_AddAction(@TCommonDamageActions.A_DamageMaster, 'A_DamageMaster(const damage: integer)'); // 314
  DEH_AddAction(@TCommonGameDependentActions.A_HealThing, 'A_HealThing(amount: integer, max: integer)'); // 315
  DEH_AddAction(@TCommonDamageActions.A_RemoveMaster, 'A_RemoveMaster([flags: integer])'); // 316
  DEH_AddAction(@TCommonAttackActions.A_BasicAttack, 'A_BasicAttack(MeleeDamage: integer, MeleeSound: integer, MissileType: integer, MissileHeight: float)'); // 317
  DEH_AddAction(@TCommonStateParamActions.A_SetMasterArg, 'A_SetMasterArg(arg: integer; value: integer)'); // 318
  DEH_AddAction(@TCommonStateParamActions.A_SetTargetArg, 'A_SetTargetArg(arg: integer; value: integer)'); // 319
  DEH_AddAction(@TCommonStateParamActions.A_SetTracerArg, 'A_SetTracerArg(arg: integer; value: integer)'); // 320
  DEH_AddAction(@TCommonMovementActions.A_Tracer2, 'A_Tracer2()'); // 321
  DEH_AddAction(@TExtraRoutines.A_SinglePainAttack, 'A_SinglePainAttack([classname: string])'); // 322
  DEH_AddAction(@TExtraRoutines.A_DualPainAttack, 'A_DualPainAttack([classname: string])'); // 323
  DEH_AddAction(@TCommonSearchActions.A_MonsterRefire, 'A_MonsterRefire(prob: integer, offset: state_t)'); // 324
  DEH_AddAction(@TCommonStateParamActions.A_RearrangePointers, 'A_RearrangePointers(ptr_target: integer, ptr_master: integer, ptr_tracer: integer, flags: integer)'); // 325
  DEH_AddAction(@TCommonStateParamActions.A_TransferPointer, 'A_TransferPointer(ptr_source: integer, ptr_recipient: integer, ptr_sourcefield: integer, [ptr_recipientfield: integer], [flags: integer])'); // 326
  DEH_AddAction(@TCommonSearchActions.A_AlertMonsters, 'A_AlertMonsters(maxdist: integer, flags: integer)'); // 327
  DEH_AddAction(@TCommonSearchActions.A_LocalEarthQuake, 'A_LocalEarthQuake(tics: integer; [intensity: float = 1.0]; [maxdist: float = MAXINT] ;)'); // 328
  DEH_AddAction(@TCommonSearchActions.A_LocalEarthQuake, 'A_Quake(tics: integer; [intensity: float = 1.0]; [maxdist: float = MAXINT] ;)'); // 329
  DEH_AddAction(@TCommonDamageActions.A_RemoveChildren, 'A_RemoveChildren([flags: integer])'); // 330
  DEH_AddAction(@TCommonDamageActions.A_RemoveSiblings, 'A_RemoveSiblings([flags: integer])'); // 331
  DEH_AddAction(@TCommonDamageActions.A_KillChildren, 'A_KillChildren()'); // 332
  DEH_AddAction(@TCommonDamageActions.A_KillSiblings, 'A_KillSiblings()'); // 333
  DEH_AddAction(@TCommonMovementActions.A_Weave, 'A_Weave(xyspeed: integer = 2, zspeed: integer = 2, xydist: float = 2.0, zdist: float = 1.0)'); // 334
  DEH_AddAction(@TCommonMovementActions.A_SetWeaveIndexXY, 'A_SetWeaveIndexXY(weavexy: integer)'); // 335
  DEH_AddAction(@TCommonMovementActions.A_SetWeaveIndexZ, 'A_SetWeaveIndexZ(weavez: integer)'); // 336
  DEH_AddAction(@TCommonMovementActions.A_SetWeaveIndexes, 'A_SetWeaveIndexes(weavexy: integer, weavez: integer)'); // 337
  DEH_AddAction(@TCommonStateBitActions.A_SetHeight, 'A_SetHeight(newheight: float)'); // 338
  DEH_AddAction(@A_OverlayClear, 'A_OverlayClear()'); // 339
  DEH_AddAction(@A_OverlayDrawPatch, 'A_OverlayDrawPatch(ticks: Integer; patchname: string; x, y: Integer ;)'); // 340
  DEH_AddAction(@A_OverlayDrawPatchStretched, 'A_OverlayDrawPatchStretched(ticks: Integer; patchname: string; x1, y1, x2, y2: Integer ;)'); // 341
  DEH_AddAction(@A_OverlayDrawPixel, 'A_OverlayDrawPixel(ticks: Integer; red, green, blue: byte; x, y: Integer ;)'); // 342
  DEH_AddAction(@A_OverlayDrawRect, 'A_OverlayDrawRect(ticks: Integer; red, green, blue: byte; x1, y1, x2, y2: Integer ;)'); // 343
  DEH_AddAction(@A_OverlayDrawLine, 'A_OverlayDrawLine(ticks: Integer; red, green, blue: byte; x1, y1, x2, y2: Integer ;)'); // 344
  DEH_AddAction(@A_OverlayDrawText, 'A_OverlayDrawText(ticks: Integer; txt: string; align: Integer; x, y: Integer ;)'); // 345
  DEH_AddAction(@A_OverlayDrawLeftText, 'A_OverlayDrawLeftText(ticks: Integer; txt: string; x, y: Integer ;)'); // 346
  DEH_AddAction(@A_OverlayDrawRightText, 'A_OverlayDrawRightText(ticks: Integer; txt: string; x, y: Integer ;)'); // 347
  DEH_AddAction(@A_OverlayDrawCenterText, 'A_OverlayDrawCenterText(ticks: Integer; txt: string; x, y: Integer ;)'); // 348
  DEH_AddAction(@TCommonStateBitActions.A_SetFriction, 'A_SetFriction(newfriction: float)'); // 349
  DEH_AddAction(@TCommonDamageActions.A_PlayerHurtExplode, 'A_PlayerHurtExplode(damage: integer, radius: integer)'); // 350
  DEH_AddAction(@TCommonGameDependentActions.A_SetPushable, 'A_SetPushable()'); // 351
  DEH_AddAction(@TCommonGameDependentActions.A_UnSetPushable, 'A_UnSetPushable()'); // 352
  DEH_AddAction(@TCommonStateBitActions.A_SetPainChance, 'A_SetPainChance(newchance: integer)'); // 353
  DEH_AddAction(@TCommonAppearanceActions.A_SetSpriteDX, 'A_SetSpriteDX(dx: float)'); // 354
  DEH_AddAction(@TCommonAppearanceActions.A_SetSpriteDY, 'A_SetSpriteDY(dy: float)'); // 355
  DEH_AddAction(@A_SeeSound1, 'A_SeeSound()'); // 356
  DEH_AddAction(@A_PainSound1, 'A_PainSound()'); // 357
  DEH_AddAction(@A_AttackSound1, 'A_AttackSound()'); // 358
  DEH_AddAction(@A_MeleeSound1, 'A_MeleeSound()'); // 359
  DEH_AddAction(@A_DeathSound1, 'A_DeathSound()'); // 360
  DEH_AddAction(@A_ActiveSound1, 'A_ActiveSound()'); // 361
  DEH_AddAction(@TCommonMovementActions.A_MatchTargetZ, 'A_MatchTargetZ(zspeed: integer; threshold: integer; maxmomz: integer)'); // 362
  DEH_AddAction(@A_SimpleDialog, 'A_SimpleDialog(dialog1: string; [dialog2...])'); // 363
  DEH_AddAction(@TDoomMonsterActions.A_TurretChase, 'A_TurretChase()'); // 364
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
  DEH_AddAction(@A_RipSound1, 'A_RipSound()');
  DEH_AddAction(@TCommonAppearanceActions.A_ChangeSpriteFlip, 'A_ChangeSpriteFlip(propability: integer)');
  DEH_AddAction(@TCommonSpawnActions.A_SpawnObject, 'A_SpawnObject(dehackedtyp: integer; anglefixeddeg: integer; xoffs, yoffs, zoffs: integer; xvel, yvel, zvel: integer)', [0, 0, 0, 0, 0, 0, 0, 0]);
  DEH_AddAction(@TCommonSpawnActions.A_MonsterProjectile, 'A_MonsterProjectile(dehackedtyp: integer; anglefixeddeg: integer; pitchfixeddeg: integer; xyoffs, zoffs: integer)', [0, 0, 0, 0, 0]);
  DEH_AddAction(@TCommonAttackActions.A_MonsterBulletAttack, 'A_MonsterBulletAttack(anglefixed_hspread, anglefixed_vspread: integer; nbullets: integer; basedamage: integer; damagemod: integer)', [0, 0, 1, 3, 5]);
  DEH_AddAction(@TCommonAttackActions.A_MonsterMeleeAttack, 'A_MonsterMeleeAttack(basedamage: integer; damagemod: integer; soundid: integer; fixxedrange: integer);', [3, 8, 0, 0]);
  DEH_AddAction(@TCommonDamageActions.A_RadiusDamage, 'A_RadiusDamage(damage: integer; radius: integer);', [0, 0]);
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
  DEH_AddAction(@TDoomMonsterActions.A_BrainAwakeVanilla, 'A_BrainAwakeVanilla();');
  DEH_AddAction(@TDoomMonsterActions.A_BrainSpitVanilla, 'A_BrainSpitVanilla();');

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
  for i := 1 to 4 do
    for j := 1 to 9 do
    begin
      TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnames[k], 'HUSTR_E' + itoa(i) + 'M' + itoa(j));
      inc(k);
    end;

  for i := 0 to 8 do
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnames2[i], 'HUSTR_' + itoa(i + 1));

  for i := 0 to 8 do
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnames2[i], 'HUSTR_' + IntToStrZFill(2, i + 1));

  for i := 9 to 32 do // Doom2 BFG
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnames2[i], 'HUSTR_' + itoa(i + 1));

  for i := 0 to 8 do
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnamesp[i], 'PHUSTR_' + itoa(i + 1));

  for i := 0 to 8 do
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnamesp[i], 'PHUSTR_' + IntToStrZFill(2, i + 1));

  for i := 9 to 31 do
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnamesp[i], 'PHUSTR_' + itoa(i + 1));

  for i := 0 to 8 do
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnamest[i], 'THUSTR_' + itoa(i + 1));

  for i := 0 to 8 do
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnamest[i], 'THUSTR_' + IntToStrZFill(2, i + 1));

  for i := 9 to 31 do
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @mapnamest[i], 'THUSTR_' + itoa(i + 1));

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[0].name, 'CC_ZOMBIE');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[1].name, 'CC_SHOTGUN');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[2].name, 'CC_HEAVY');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[3].name, 'CC_IMP');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[4].name, 'CC_DEMON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[5].name, 'CC_LOST');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[6].name, 'CC_CACO');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[7].name, 'CC_HELL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[8].name, 'CC_BARON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[9].name, 'CC_ARACH');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[10].name, 'CC_PAIN');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[11].name, 'CC_REVEN');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[12].name, 'CC_MANCU');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[13].name, 'CC_ARCH');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[14].name, 'CC_SPIDER');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[15].name, 'CC_CYBER');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @castorder[16].name, 'CC_HERO');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_CREDIT, 'PAGE_CREDIT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_HELP, 'PAGE_HELP');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_HELP1, 'PAGE_HELP1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_HELP2, 'PAGE_HELP2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_VICTORY2, 'PAGE_VICTORY2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_ENDPIC, 'PAGE_ENDPIC');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_TITLE, 'PAGE_TITLE');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @pg_DMENUPIC, 'PAGE_TITLE_BFG2');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflatE1, 'BGFLATE1');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflatE2, 'BGFLATE2');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflatE3, 'BGFLATE3');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflatE4, 'BGFLATE4');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflat06, 'BGFLAT06');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflat11, 'BGFLAT11');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflat20, 'BGFLAT20');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflat30, 'BGFLAT30');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflat15, 'BGFLAT15');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgflat31, 'BGFLAT31');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @bgcastcall, 'BGCASTCALL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @EndLumpName, 'END_TEXT_LUMP');
  for i := 0 to 9 do
  begin
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @chat_macros[i], 'HUSTR_CHATMACR' + itoa(i));
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @chat_macros[i], 'HUSTR_CHATMACR' + IntToStrZFill(2, i));
  end;

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @QUITMSG, 'QUITMSG');
  for i := 0 to 9 do
  begin
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @endmsg[i], 'ENDMSG' + itoa(i));
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @endmsg[i], 'ENDMSG' + IntToStrZFill(2, i));
  end;

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @S_ERR_DIF_NET, 'S_ERR_DIF_NET');

  for i := 10 to NUM_QUITMESSAGES do
  begin
    TDehMainLocalRoutines.DEH_AddString(@deh_strings, @endmsg[i], 'ENDMSG' + itoa(i));
  end;

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
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_DQDON, 'STSTR_DQDON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_DQDOFF, 'STSTR_DQDOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_KEYSADDED, 'STSTR_KEYSADDED');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_KFAADDED, 'STSTR_KFAADDED');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_FAADDED, 'STSTR_FAADDED');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_NCON, 'STSTR_NCON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_NCOFF, 'STSTR_NCOFF');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_BEHOLD, 'STSTR_BEHOLD');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_BEHOLDX, 'STSTR_BEHOLDX');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_CHOPPERS, 'STSTR_CHOPPERS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_CLEV, 'STSTR_CLEV');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_LGON, 'STSTR_LGON');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_LGOFF, 'STSTR_LGOFF');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @STSTR_MASSACRE, 'STSTR_MASSACRE');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @E1TEXT, 'E1TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @E2TEXT, 'E2TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @E3TEXT, 'E3TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @E4TEXT, 'E4TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @C1TEXT, 'C1TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @C2TEXT, 'C2TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @C3TEXT, 'C3TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @C4TEXT, 'C4TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @C5TEXT, 'C5TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @C6TEXT, 'C6TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @P1TEXT, 'P1TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @P2TEXT, 'P2TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @P3TEXT, 'P3TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @P4TEXT, 'P4TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @P5TEXT, 'P5TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @P6TEXT, 'P6TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @T1TEXT, 'T1TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @T2TEXT, 'T2TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @T3TEXT, 'T3TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @T4TEXT, 'T4TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @T5TEXT, 'T5TEXT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @T6TEXT, 'T6TEXT');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSG_MODIFIEDGAME, 'MSG_MODIFIEDGAME');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSG_SHAREWARE, 'MSG_SHAREWARE');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSG_COMMERCIAL, 'MSG_COMMERCIAL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @MSG_UNDETERMINED, 'MSG_UNDETERMINED');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTARMOR, 'GOTARMOR');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTMEGA, 'GOTMEGA');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTHTHBONUS, 'GOTHTHBONUS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTARMBONUS, 'GOTARMBONUS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTSTIM, 'GOTSTIM');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTMEDINEED, 'GOTMEDINEED');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTMEDIKIT, 'GOTMEDIKIT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTSUPER, 'GOTSUPER');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTBLUECARD, 'GOTBLUECARD');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTYELWCARD, 'GOTYELWCARD');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTREDCARD, 'GOTREDCARD');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTBLUESKUL, 'GOTBLUESKUL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTYELWSKUL, 'GOTYELWSKUL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTREDSKULL, 'GOTREDSKULL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTINVUL, 'GOTINVUL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTBERSERK, 'GOTBERSERK');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTINVIS, 'GOTINVIS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTSUIT, 'GOTSUIT');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTMAP, 'GOTMAP');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTVISOR, 'GOTVISOR');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTMSPHERE, 'GOTMSPHERE');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTCLIP, 'GOTCLIP');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTCLIPBOX, 'GOTCLIPBOX');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTROCKET, 'GOTROCKET');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTROCKBOX, 'GOTROCKBOX');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTCELL, 'GOTCELL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTCELLBOX, 'GOTCELLBOX');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTSHELLS, 'GOTSHELLS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTONESHELL, 'GOTONESHELL');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTMANYSHELLS, 'GOTMANYSHELLS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTSHELLBOX, 'GOTSHELLBOX');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTBACKPACK, 'GOTBACKPACK');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTBFG9000, 'GOTBFG9000');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTCHAINGUN, 'GOTCHAINGUN');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTCHAINSAW, 'GOTCHAINSAW');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTLAUNCHER, 'GOTLAUNCHER');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTPLASMA, 'GOTPLASMA');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTSHOTGUN, 'GOTSHOTGUN');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @GOTSHOTGUN2, 'GOTSHOTGUN2');
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

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_BLUEO, 'PD_BLUEO');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_REDO, 'PD_REDO');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_YELLOWO, 'PD_YELLOWO');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_BLUEK, 'PD_BLUEK');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_REDK, 'PD_REDK');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_YELLOWK, 'PD_YELLOWK');

  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_BLUEC, 'PD_BLUEC');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_REDC, 'PD_REDC');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_YELLOWC, 'PD_YELLOWC');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_BLUES, 'PD_BLUES');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_REDS, 'PD_REDS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_YELLOWS, 'PD_YELLOWS');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_ANY, 'PD_ANY');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_ALL3, 'PD_ALL3');
  TDehMainLocalRoutines.DEH_AddString(@deh_strings, @PD_ALL6, 'PD_ALL6');

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

