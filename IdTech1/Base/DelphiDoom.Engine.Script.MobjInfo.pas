{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - mobjinfo for the functions of scripts                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.MobjInfo;

interface

uses
  DelphiDoom.ScriptHost.MobjInfo.Intf;

type
  /// <summary>
  ///   mobjinfo[] for the scripts. The only class that reads it for the mobjinfo functions (they
  ///   were in psi_game.pas); the library checks the number of the type, so here nothing is
  ///   checked
  /// </summary>
  TEngineScriptMobjInfo = class(TInterfacedObject, IScriptMobjInfoSource)
  public
    function Count: Integer;
    function Number(const AType: Integer; const AField: TScriptMobjInfoField): Integer;
    function Text(const AType: Integer; const AField: TScriptMobjInfoField): string;
    function Flag(const AType: Integer; const AFlag: Integer): Boolean;
    function TypeFromEditorNumber(const ANumber: Integer): Integer;
  end;

implementation

uses
  info_common,
  info_h,
  info,
  psi_game,
  sounds;

{ TEngineScriptMobjInfo }

function TEngineScriptMobjInfo.Count: Integer;
begin
  Result := nummobjtypes;
end;

function TEngineScriptMobjInfo.Number(const AType: Integer; const AField: TScriptMobjInfoField): Integer;
begin
  case AField of
    mifInheritsFrom: Result := mobjinfo[AType].inheritsfrom;
    mifDoomEdNum: Result := mobjinfo[AType].doomednum;
    mifSpawnState: Result := mobjinfo[AType].spawnstate;
    mifSpawnHealth: Result := mobjinfo[AType].spawnhealth;
    mifSeeState: Result := mobjinfo[AType].seestate;
    mifReactionTime: Result := mobjinfo[AType].reactiontime;
    mifPainState: Result := mobjinfo[AType].painstate;
    mifPainChance: Result := mobjinfo[AType].painchance;
    mifMeleeState: Result := mobjinfo[AType].meleestate;
    mifMissileState: Result := mobjinfo[AType].missilestate;
    mifDeathState: Result := mobjinfo[AType].deathstate;
    mifXdeathState: Result := mobjinfo[AType].xdeathstate;
    mifSpeed: Result := mobjinfo[AType].speed;
    mifVSpeed: Result := mobjinfo[AType].vspeed;
    mifMinMissileChance: Result := mobjinfo[AType].minmissilechance;
    mifPushFactor: Result := mobjinfo[AType].pushfactor;
    mifScale: Result := mobjinfo[AType].scale;
    mifGravity: Result := mobjinfo[AType].gravity;
    mifRadius: Result := mobjinfo[AType].radius;
    mifHeight: Result := mobjinfo[AType].height;
    mifMass: Result := mobjinfo[AType].mass;
    mifDamage: Result := mobjinfo[AType].damage;
    mifRaiseState: Result := mobjinfo[AType].raisestate;
    mifDropItem: Result := mobjinfo[AType].dropitem;
    mifMissiletype: Result := mobjinfo[AType].missiletype;
    mifExplosionDamage: Result := mobjinfo[AType].explosiondamage;
    mifExplosionRadius: Result := mobjinfo[AType].explosionradius;
    mifMeleeDamage: Result := mobjinfo[AType].meleedamage;
    mifRenderStyle: Result := Ord(mobjinfo[AType].renderstyle);
    mifAlpha: Result := mobjinfo[AType].alpha;
    mifHealState: Result := mobjinfo[AType].healstate;
    mifCrashState: Result := mobjinfo[AType].crashstate;
    mifCrushState: Result := mobjinfo[AType].crushstate;
    mifFloatSpeed: Result := mobjinfo[AType].floatspeed;
    mifNormalSpeed: Result := mobjinfo[AType].normalspeed;
    mifFastSpeed: Result := mobjinfo[AType].fastspeed;
    mifGender: Result := Ord(mobjinfo[AType].gender);
    mifMeleeRange: Result := mobjinfo[AType].meleerange;
    mifMaxStepHeight: Result := mobjinfo[AType].maxstepheight;
    mifMaxDropOffHeight: Result := mobjinfo[AType].maxdropoffheight;
    mifGibHealth: Result := mobjinfo[AType].gibhealth;
    mifMaxTargetRange: Result := mobjinfo[AType].maxtargetrange;
    mifWeaveIndexXY: Result := mobjinfo[AType].WeaveIndexXY;
    mifWeaveIndexZ: Result := mobjinfo[AType].WeaveIndexZ;
    mifFriction: Result := mobjinfo[AType].friction;
    mifSpriteDX: Result := mobjinfo[AType].spriteDX;
    mifSpriteDY: Result := mobjinfo[AType].spriteDY;
    mifInteractState: Result := mobjinfo[AType].interactstate;
    mifInfightingGroup: Result := mobjinfo[AType].infighting_group;
    mifProjectileGroup: Result := mobjinfo[AType].projectile_group;
    mifSplashGroup: Result := mobjinfo[AType].splash_group;
    mifMissileHeight: Result := mobjinfo[AType].missileheight;
    mifMeleeThreshold: Result := mobjinfo[AType].meleethreshold;
  else
    Result := 0;
  end;
end;

function TEngineScriptMobjInfo.Text(const AType: Integer; const AField: TScriptMobjInfoField): string;
begin
  case AField of
    mifName: Result := string(mobjinfo[AType].name);
    mifSeeSound: Result := S_GetSoundNameForNum(mobjinfo[AType].seesound);
    mifAttackSound: Result := S_GetSoundNameForNum(mobjinfo[AType].attacksound);
    mifPainSound: Result := S_GetSoundNameForNum(mobjinfo[AType].painsound);
    mifDeathSound: Result := S_GetSoundNameForNum(mobjinfo[AType].deathsound);
    mifActiveSound: Result := S_GetSoundNameForNum(mobjinfo[AType].activesound);
    mifCustomSound1: Result := S_GetSoundNameForNum(mobjinfo[AType].customsound1);
    mifCustomSound2: Result := S_GetSoundNameForNum(mobjinfo[AType].customsound2);
    mifCustomSound3: Result := S_GetSoundNameForNum(mobjinfo[AType].customsound3);
    mifMeleeSound: Result := S_GetSoundNameForNum(mobjinfo[AType].meleesound);
    mifObituary: Result := string(mobjinfo[AType].obituary);
    mifHitObituary: Result := string(mobjinfo[AType].hitobituary);
    mifRipSound: Result := S_GetSoundNameForNum(mobjinfo[AType].ripsound);
  else
    Result := '';
  end;
end;

function TEngineScriptMobjInfo.Flag(const AType: Integer; const AFlag: Integer): Boolean;
begin
  Result := psi_game.PS_GetMobjInfoFlag(AType, AFlag);
end;

function TEngineScriptMobjInfo.TypeFromEditorNumber(const ANumber: Integer): Integer;
begin
  Result := Info_GetMobjNumForDoomNum(ANumber);
end;

end.