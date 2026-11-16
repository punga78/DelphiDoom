{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - the profiles of the four games            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.Profiles;

interface

uses
  DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Profile;

type
  /// <summary>
  ///   The fields that each game writes, in the order of its patches. The labels are the
  ///   tokens of the patches (the engine writes them as "Initial Frame")
  /// </summary>
  TExportProfiles = class
  strict private
    class function ThingDoomLines: TArray<TExportLine>; static;
    class function ThingHereticLines: TArray<TExportLine>; static;
    class function ThingHexenLines: TArray<TExportLine>; static;
    class function ThingStrifeLines: TArray<TExportLine>; static;
    class function PascalThingDoomLines: TArray<TExportPascalLine>; static;
    class function PascalThingHereticLines: TArray<TExportPascalLine>; static;
    class function PascalThingHexenLines: TArray<TExportPascalLine>; static;
    class function PascalThingStrifeLines: TArray<TExportPascalLine>; static;
    class function StateLines(const AGameName: string): TArray<TExportLine>; static;
    class function PascalStateLines: TArray<TExportPascalLine>; static;
    class function WeaponLines(const AAmmoToken: string; AWithLevel: Boolean): TArray<TExportLine>; static;
    class function MiscLines(const ATokens: array of string): TArray<TExportLine>; static;
  public
    class function ForGame(AGame: TExportGame): TExportProfile; static;
    /// <summary>DOOM, HERETIC, HEXEN or STRIFE</summary>
    class function NameOf(AGame: TExportGame): string; static;
    /// <summary>The game of a name, whatever the case of the letters; false if it is none of the four</summary>
    class function TryFromName(const AName: string; out AGame: TExportGame): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

function MakeLine(const AToken: string; AKind: TExportLineKind; AIndex: Integer): TExportLine;
begin
  Result := Default(TExportLine);
  Result.Token := AToken;
  Result.Kind := AKind;
  Result.Index := AIndex;
end;

function LNum(const AToken: string; AIndex: Integer): TExportLine;
begin
  Result := MakeLine(AToken, lkNumber, AIndex);
end;

function LFlags(const AToken: string; AIndex: Integer; ASet: TExportFlagSet): TExportLine;
begin
  Result := MakeLine(AToken, lkFlags, AIndex);
  Result.FlagSet := ASet;
end;

function LName(const AToken: string; AIndex: Integer): TExportLine;
begin
  Result := MakeLine(AToken, lkName, AIndex);
end;

function LQuoted(const AToken: string; AIndex: Integer): TExportLine;
begin
  Result := MakeLine(AToken, lkQuoted, AIndex);
end;

function LKind(AKind: TExportLineKind; const AToken: string; AIndex: Integer): TExportLine;
begin
  Result := MakeLine(AToken, AKind, AIndex);
end;

function LGroup(const AToken: string; AIndex: Integer; AGroup: TExportGroup): TExportLine;
begin
  Result := MakeLine(AToken, lkGroup, AIndex);
  Result.Group := AGroup;
end;

function LComment(const AText: string): TExportLine;
begin
  Result := MakeLine(AText, lkComment, 0);
end;

function MakePascal(const AName: string; AKind: TExportPascalKind; AIndex: Integer): TExportPascalLine;
begin
  Result := Default(TExportPascalLine);
  Result.Name := AName;
  Result.Kind := AKind;
  Result.Index := AIndex;
end;

function PL(const AName: string; AKind: TExportPascalKind; AIndex: Integer): TExportPascalLine;
begin
  Result := MakePascal(AName, AKind, AIndex);
end;

function PLF(const AName: string; AIndex: Integer; ASet: TExportFlagSet): TExportPascalLine;
begin
  Result := MakePascal(AName, pkFlags, AIndex);
  Result.FlagSet := ASet;
end;

function PLG(const AName: string; AIndex: Integer; AGroup: TExportGroup): TExportPascalLine;
begin
  Result := MakePascal(AName, pkGroup, AIndex);
  Result.Group := AGroup;
end;

{ TExportProfiles }

class function TExportProfiles.ThingDoomLines: TArray<TExportLine>;
begin
  Result := [
    LName('NAME', Ord(ttName)),
    LNum('INHERITSFROM', Ord(tfInheritsFrom)),
    LNum('ID #', Ord(tfDoomedNum)),
    LNum('INITIAL FRAME', Ord(tfSpawnState)),
    LNum('HIT POINTS', Ord(tfSpawnHealth)),
    LNum('FIRST MOVING FRAME', Ord(tfSeeState)),
    LNum('ALERT SOUND', Ord(tfSeeSound)),
    LNum('REACTION TIME', Ord(tfReactionTime)),
    LNum('ATTACK SOUND', Ord(tfAttackSound)),
    LNum('INJURY FRAME', Ord(tfPainState)),
    LNum('PAIN CHANCE', Ord(tfPainChance)),
    LNum('PAIN SOUND', Ord(tfPainSound)),
    LNum('CLOSE ATTACK FRAME', Ord(tfMeleeState)),
    LNum('FAR ATTACK FRAME', Ord(tfMissileState)),
    LNum('DEATH FRAME', Ord(tfDeathState)),
    LNum('EXPLODING FRAME', Ord(tfXDeathState)),
    LNum('DEATH SOUND', Ord(tfDeathSound)),
    LNum('SPEED', Ord(tfSpeed)),
    LNum('WIDTH', Ord(tfRadius)),
    LNum('HEIGHT', Ord(tfHeight)),
    LNum('MASS', Ord(tfMass)),
    LNum('MISSILE DAMAGE', Ord(tfDamage)),
    LNum('ACTION SOUND', Ord(tfActiveSound)),
    LNum('RESPAWN FRAME', Ord(tfRaiseState)),
    LFlags('BITS', Ord(tfFlags), fsMobjFlags),
    LComment('# The following fields are DelphiDoom specific enhancements'),
    LFlags('FLAGS_EX', Ord(tfFlagsEx), fsMobjFlagsEx),
    LFlags('FLAGS2_EX', Ord(tfFlags2Ex), fsMobjFlags2Ex),
    LNum('CUSTOM SOUND 1', Ord(tfCustomSound1)),
    LNum('CUSTOM SOUND 2', Ord(tfCustomSound2)),
    LNum('CUSTOM SOUND 3', Ord(tfCustomSound3)),
    LNum('EXPLOSION DAMAGE', Ord(tfExplosionDamage)),
    LNum('EXPLOSION RADIUS', Ord(tfExplosionRadius)),
    LNum('MELEE DAMAGE', Ord(tfMeleeDamage)),
    LNum('MELEE SOUND', Ord(tfMeleeSound)),
    LKind(lkRenderStyle, 'RENDERSTYLE', Ord(tfRenderStyle)),
    LNum('ALPHA', Ord(tfAlpha)),
    LNum('DROPITEM', Ord(tfDropItem)),
    LNum('MISSILETYPE', Ord(tfMissileType)),
    LNum('HEAL FRAME', Ord(tfHealState)),
    LNum('CRASH FRAME', Ord(tfCrashState)),
    LNum('INTERACT FRAME', Ord(tfInteractState)),
    LNum('MISSILEHEIGHT', Ord(tfMissileHeight)),
    LNum('VSPEED', Ord(tfVSpeed)),
    LNum('PUSHFACTOR', Ord(tfPushFactor)),
    LNum('SCALE', Ord(tfScale)),
    LNum('GRAVITY', Ord(tfGravity)),
    LFlags('FLAGS3_EX', Ord(tfFlags3Ex), fsMobjFlags3Ex),
    LFlags('FLAGS4_EX', Ord(tfFlags4Ex), fsMobjFlags4Ex),
    LNum('MINMISSILECHANCE', Ord(tfMinMissileChance)),
    LNum('FLOAT SPEED', Ord(tfFloatSpeed)),
    LNum('NORMAL SPEED', Ord(tfNormalSpeed)),
    LNum('FAST SPEED', Ord(tfFastSpeed)),
    LQuoted('OBITUARY', Ord(ttObituary)),
    LQuoted('HIT OBITUARY', Ord(ttHitObituary)),
    LKind(lkGender, 'GENDER', Ord(tfGender)),
    LNum('MELEE RANGE', Ord(tfMeleeRange)),
    LNum('MAX STEP HEIGHT', Ord(tfMaxStepHeight)),
    LNum('MAX DROPOFF HEIGHT', Ord(tfMaxDropoffHeight)),
    LNum('GIB HEALTH', Ord(tfGibHealth)),
    LNum('MAX TARGET RANGE', Ord(tfMaxTargetRange)),
    LNum('WEAVE INDEX XY', Ord(tfWeaveIndexXY)),
    LNum('WEAVE INDEX Z', Ord(tfWeaveIndexZ)),
    LNum('FRICTION', Ord(tfFriction)),
    LNum('SPRITE DX', Ord(tfSpriteDX)),
    LNum('SPRITE DY', Ord(tfSpriteDY)),
    LFlags('FLAGS5_EX', Ord(tfFlags5Ex), fsMobjFlags5Ex),
    LFlags('FLAGS6_EX', Ord(tfFlags6Ex), fsMobjFlags6Ex),
    LGroup('INFIGHTING GROUP', Ord(tfInfightingGroup), egInfighting),
    LGroup('PROJECTILE GROUP', Ord(tfProjectileGroup), egProjectile),
    LGroup('SPLASH GROUP', Ord(tfSplashGroup), egSplash),
    LNum('RIP SOUND', Ord(tfRipSound)),
    LNum('CRUSH FRAME', Ord(tfCrushState)),
    LNum('BLOOD COLOR', Ord(tfBloodColor)),
    LQuoted('TRANSLATION', Ord(ttTranslation)),
    LNum('MELEE THRESHOLD', Ord(tfMeleeThreshold))
  ];
end;

class function TExportProfiles.PascalThingDoomLines: TArray<TExportPascalLine>;
begin
  Result := [
    PL('name', pkText, Ord(ttName)),
    PL('inheritsfrom', pkInteger, Ord(tfInheritsFrom)),
    PL('doomednum', pkInteger, Ord(tfDoomedNum)),
    PL('spawnstate', pkState, Ord(tfSpawnState)),
    PL('spawnhealth', pkInteger, Ord(tfSpawnHealth)),
    PL('seestate', pkState, Ord(tfSeeState)),
    PL('seesound', pkSound, Ord(tfSeeSound)),
    PL('reactiontime', pkInteger, Ord(tfReactionTime)),
    PL('attacksound', pkSound, Ord(tfAttackSound)),
    PL('painstate', pkState, Ord(tfPainState)),
    PL('painchance', pkInteger, Ord(tfPainChance)),
    PL('painsound', pkSound, Ord(tfPainSound)),
    PL('meleestate', pkState, Ord(tfMeleeState)),
    PL('missilestate', pkState, Ord(tfMissileState)),
    PL('deathstate', pkState, Ord(tfDeathState)),
    PL('xdeathstate', pkState, Ord(tfXDeathState)),
    PL('deathsound', pkSound, Ord(tfDeathSound)),
    PL('speed', pkFixed, Ord(tfSpeed)),
    PL('radius', pkFixed, Ord(tfRadius)),
    PL('height', pkFixed, Ord(tfHeight)),
    PL('mass', pkInteger, Ord(tfMass)),
    PL('damage', pkInteger, Ord(tfDamage)),
    PL('activesound', pkSound, Ord(tfActiveSound)),
    PLF('flags', Ord(tfFlags), fsMobjFlags),
    PLF('flags_ex', Ord(tfFlagsEx), fsMobjFlagsEx),
    PLF('flags2_ex', Ord(tfFlags2Ex), fsMobjFlags2Ex),
    PL('raisestate', pkState, Ord(tfRaiseState)),
    PL('customsound1', pkSound, Ord(tfCustomSound1)),
    PL('customsound2', pkSound, Ord(tfCustomSound2)),
    PL('customsound3', pkSound, Ord(tfCustomSound3)),
    PL('meleesound', pkSound, Ord(tfMeleeSound)),
    PL('dropitem', pkInteger, Ord(tfDropItem)),
    PL('missiletype', pkInteger, Ord(tfMissileType)),
    PL('explosiondamage', pkInteger, Ord(tfExplosionDamage)),
    PL('explosionradius', pkInteger, Ord(tfExplosionRadius)),
    PL('meleedamage', pkInteger, Ord(tfMeleeDamage)),
    PL('renderstyle', pkRenderStyle, Ord(tfRenderStyle)),
    PL('alpha', pkInteger, Ord(tfAlpha)),
    PL('healstate', pkState, Ord(tfHealState)),
    PL('crashstate', pkState, Ord(tfCrashState)),
    PL('crushstate', pkState, Ord(tfCrushState)),
    PL('interactstate', pkState, Ord(tfInteractState)),
    PL('missileheight', pkInteger, Ord(tfMissileHeight)),
    PL('vspeed', pkInteger, Ord(tfVSpeed)),
    PL('pushfactor', pkPushFactor, Ord(tfPushFactor)),
    PL('friction', pkFriction, Ord(tfFriction)),
    PL('scale', pkFixed, Ord(tfScale)),
    PL('gravity', pkFixed, Ord(tfGravity)),
    PLF('flags3_ex', Ord(tfFlags3Ex), fsMobjFlags3Ex),
    PLF('flags4_ex', Ord(tfFlags4Ex), fsMobjFlags4Ex),
    PL('minmissilechance', pkInteger, Ord(tfMinMissileChance)),
    PL('floatspeed', pkFixed, Ord(tfFloatSpeed)),
    PL('normalspeed', pkFixed, Ord(tfNormalSpeed)),
    PL('fastspeed', pkFixed, Ord(tfFastSpeed)),
    PL('obituary', pkText, Ord(ttObituary)),
    PL('hitobituary', pkText, Ord(ttHitObituary)),
    PL('gender', pkGender, Ord(tfGender)),
    PL('meleerange', pkInteger, Ord(tfMeleeRange)),
    PL('maxstepheight', pkInteger, Ord(tfMaxStepHeight)),
    PL('maxdropoffheight', pkInteger, Ord(tfMaxDropoffHeight)),
    PL('gibhealth', pkInteger, Ord(tfGibHealth)),
    PL('maxtargetrange', pkInteger, Ord(tfMaxTargetRange)),
    PL('WeaveIndexXY', pkInteger, Ord(tfWeaveIndexXY)),
    PL('WeaveIndexZ', pkInteger, Ord(tfWeaveIndexZ)),
    PL('spriteDX', pkFixed, Ord(tfSpriteDX)),
    PL('spriteDY', pkFixed, Ord(tfSpriteDY)),
    PLF('flags5_ex', Ord(tfFlags5Ex), fsMobjFlags5Ex),
    PLF('flags6_ex', Ord(tfFlags6Ex), fsMobjFlags6Ex),
    PLG('infighting_group', Ord(tfInfightingGroup), egInfighting),
    PLG('projectile_group', Ord(tfProjectileGroup), egProjectile),
    PLG('splash_group', Ord(tfSplashGroup), egSplash),
    PL('ripsound', pkSound, Ord(tfRipSound)),
    PL('bloodcolor', pkInteger, Ord(tfBloodColor)),
    PL('translationname', pkText, Ord(ttTranslation)),
    PL('meleethreshold', pkInteger, Ord(tfMeleeThreshold))
  ];
end;

class function TExportProfiles.ThingHereticLines: TArray<TExportLine>;
begin
  Result := [
    LName('NAME', Ord(ttName)),
    LNum('INHERITSFROM', Ord(tfInheritsFrom)),
    LNum('ID #', Ord(tfDoomedNum)),
    LNum('INITIAL FRAME', Ord(tfSpawnState)),
    LNum('HIT POINTS', Ord(tfSpawnHealth)),
    LNum('FIRST MOVING FRAME', Ord(tfSeeState)),
    LNum('ALERT SOUND', Ord(tfSeeSound)),
    LNum('REACTION TIME', Ord(tfReactionTime)),
    LNum('ATTACK SOUND', Ord(tfAttackSound)),
    LNum('INJURY FRAME', Ord(tfPainState)),
    LNum('PAIN CHANCE', Ord(tfPainChance)),
    LNum('PAIN SOUND', Ord(tfPainSound)),
    LNum('CLOSE ATTACK FRAME', Ord(tfMeleeState)),
    LNum('FAR ATTACK FRAME', Ord(tfMissileState)),
    LNum('DEATH FRAME', Ord(tfDeathState)),
    LNum('EXPLODING FRAME', Ord(tfXDeathState)),
    LNum('DEATH SOUND', Ord(tfDeathSound)),
    LNum('SPEED', Ord(tfSpeed)),
    LNum('WIDTH', Ord(tfRadius)),
    LNum('HEIGHT', Ord(tfHeight)),
    LNum('MASS', Ord(tfMass)),
    LNum('MISSILE DAMAGE', Ord(tfDamage)),
    LNum('ACTION SOUND', Ord(tfActiveSound)),
    LNum('RESPAWN FRAME', Ord(tfRaiseState)),
    LFlags('BITS', Ord(tfFlags), fsMobjFlags),
    LFlags('BITS2', Ord(tfFlags2), fsMobjFlags2),
    LComment('# The following fields are DelphiHeretic specific enhancements'),
    LFlags('FLAGS_EX', Ord(tfFlagsEx), fsMobjFlagsEx),
    LFlags('FLAGS2_EX', Ord(tfFlags2Ex), fsMobjFlags2Ex),
    LNum('CUSTOM SOUND 1', Ord(tfCustomSound1)),
    LNum('CUSTOM SOUND 2', Ord(tfCustomSound2)),
    LNum('CUSTOM SOUND 3', Ord(tfCustomSound3)),
    LNum('EXPLOSION DAMAGE', Ord(tfExplosionDamage)),
    LNum('EXPLOSION RADIUS', Ord(tfExplosionRadius)),
    LNum('MELEE DAMAGE', Ord(tfMeleeDamage)),
    LNum('MELEE SOUND', Ord(tfMeleeSound)),
    LKind(lkRenderStyle, 'RENDERSTYLE', Ord(tfRenderStyle)),
    LNum('ALPHA', Ord(tfAlpha)),
    LNum('DROPITEM', Ord(tfDropItem)),
    LNum('MISSILETYPE', Ord(tfMissileType)),
    LNum('HEAL FRAME', Ord(tfHealState)),
    LNum('CRASH FRAME', Ord(tfCrashState)),
    LNum('VSPEED', Ord(tfVSpeed)),
    LNum('PUSHFACTOR', Ord(tfPushFactor)),
    LNum('SCALE', Ord(tfScale)),
    LNum('GRAVITY', Ord(tfGravity)),
    LFlags('FLAGS3_EX', Ord(tfFlags3Ex), fsMobjFlags3Ex),
    LFlags('FLAGS4_EX', Ord(tfFlags4Ex), fsMobjFlags4Ex),
    LNum('MINMISSILECHANCE', Ord(tfMinMissileChance)),
    LNum('FLOAT SPEED', Ord(tfFloatSpeed)),
    LNum('NORMAL SPEED', Ord(tfNormalSpeed)),
    LNum('FAST SPEED', Ord(tfFastSpeed)),
    LQuoted('OBITUARY', Ord(ttObituary)),
    LQuoted('HIT OBITUARY', Ord(ttHitObituary)),
    LKind(lkGender, 'GENDER', Ord(tfGender)),
    LNum('MELEE RANGE', Ord(tfMeleeRange)),
    LNum('MAX STEP HEIGHT', Ord(tfMaxStepHeight)),
    LNum('MAX DROPOFF HEIGHT', Ord(tfMaxDropoffHeight)),
    LNum('GIB HEALTH', Ord(tfGibHealth)),
    LNum('MAX TARGET RANGE', Ord(tfMaxTargetRange)),
    LNum('WEAVE INDEX XY', Ord(tfWeaveIndexXY)),
    LNum('WEAVE INDEX Z', Ord(tfWeaveIndexZ)),
    LNum('FRICTION', Ord(tfFriction)),
    LNum('SPRITE DX', Ord(tfSpriteDX)),
    LNum('SPRITE DY', Ord(tfSpriteDY)),
    LNum('INTERACT FRAME', Ord(tfInteractState)),
    LFlags('FLAGS5_EX', Ord(tfFlags5Ex), fsMobjFlags5Ex),
    LFlags('FLAGS6_EX', Ord(tfFlags6Ex), fsMobjFlags6Ex),
    LGroup('INFIGHTING GROUP', Ord(tfInfightingGroup), egInfighting),
    LGroup('PROJECTILE GROUP', Ord(tfProjectileGroup), egProjectile),
    LGroup('SPLASH GROUP', Ord(tfSplashGroup), egSplash),
    LNum('RIP SOUND', Ord(tfRipSound)),
    LNum('CRUSH FRAME', Ord(tfCrushState)),
    LNum('BLOOD COLOR', Ord(tfBloodColor)),
    LQuoted('TRANSLATION', Ord(ttTranslation)),
    LNum('MISSILEHEIGHT', Ord(tfMissileHeight)),
    LNum('MELEE THRESHOLD', Ord(tfMeleeThreshold))
  ];
end;

class function TExportProfiles.PascalThingHereticLines: TArray<TExportPascalLine>;
begin
  Result := [
    PL('name', pkText, Ord(ttName)),
    PL('inheritsfrom', pkInteger, Ord(tfInheritsFrom)),
    PL('doomednum', pkInteger, Ord(tfDoomedNum)),
    PL('spawnstate', pkState, Ord(tfSpawnState)),
    PL('spawnhealth', pkInteger, Ord(tfSpawnHealth)),
    PL('seestate', pkState, Ord(tfSeeState)),
    PL('seesound', pkSound, Ord(tfSeeSound)),
    PL('reactiontime', pkInteger, Ord(tfReactionTime)),
    PL('attacksound', pkSound, Ord(tfAttackSound)),
    PL('painstate', pkState, Ord(tfPainState)),
    PL('painchance', pkInteger, Ord(tfPainChance)),
    PL('painsound', pkSound, Ord(tfPainSound)),
    PL('meleestate', pkState, Ord(tfMeleeState)),
    PL('missilestate', pkState, Ord(tfMissileState)),
    PL('deathstate', pkState, Ord(tfDeathState)),
    PL('xdeathstate', pkState, Ord(tfXDeathState)),
    PL('deathsound', pkSound, Ord(tfDeathSound)),
    PL('speed', pkFixed, Ord(tfSpeed)),
    PL('radius', pkFixed, Ord(tfRadius)),
    PL('height', pkFixed, Ord(tfHeight)),
    PL('mass', pkInteger, Ord(tfMass)),
    PL('damage', pkInteger, Ord(tfDamage)),
    PL('activesound', pkSound, Ord(tfActiveSound)),
    PLF('flags', Ord(tfFlags), fsMobjFlags),
    PLF('flags2', Ord(tfFlags2), fsMobjFlags2),
    PLF('flags_ex', Ord(tfFlagsEx), fsMobjFlagsEx),
    PLF('flags2_ex', Ord(tfFlags2Ex), fsMobjFlags2Ex),
    PL('raisestate', pkState, Ord(tfRaiseState)),
    PL('customsound1', pkSound, Ord(tfCustomSound1)),
    PL('customsound2', pkSound, Ord(tfCustomSound2)),
    PL('customsound3', pkSound, Ord(tfCustomSound3)),
    PL('meleesound', pkSound, Ord(tfMeleeSound)),
    PL('dropitem', pkInteger, Ord(tfDropItem)),
    PL('missiletype', pkInteger, Ord(tfMissileType)),
    PL('explosiondamage', pkInteger, Ord(tfExplosionDamage)),
    PL('explosionradius', pkInteger, Ord(tfExplosionRadius)),
    PL('meleedamage', pkInteger, Ord(tfMeleeDamage)),
    PL('renderstyle', pkRenderStyle, Ord(tfRenderStyle)),
    PL('alpha', pkInteger, Ord(tfAlpha)),
    PL('healstate', pkState, Ord(tfHealState)),
    PL('crashstate', pkState, Ord(tfCrashState)),
    PL('crushstate', pkState, Ord(tfCrushState)),
    PL('interactstate', pkState, Ord(tfInteractState)),
    PL('missileheight', pkInteger, Ord(tfMissileHeight)),
    PL('vspeed', pkInteger, Ord(tfVSpeed)),
    PL('pushfactor', pkPushFactor, Ord(tfPushFactor)),
    PL('friction', pkFriction, Ord(tfFriction)),
    PL('scale', pkFixed, Ord(tfScale)),
    PL('gravity', pkFixed, Ord(tfGravity)),
    PLF('flags3_ex', Ord(tfFlags3Ex), fsMobjFlags3Ex),
    PLF('flags4_ex', Ord(tfFlags4Ex), fsMobjFlags4Ex),
    PL('minmissilechance', pkInteger, Ord(tfMinMissileChance)),
    PL('floatspeed', pkFixed, Ord(tfFloatSpeed)),
    PL('normalspeed', pkFixed, Ord(tfNormalSpeed)),
    PL('fastspeed', pkFixed, Ord(tfFastSpeed)),
    PL('obituary', pkText, Ord(ttObituary)),
    PL('hitobituary', pkText, Ord(ttHitObituary)),
    PL('gender', pkGender, Ord(tfGender)),
    PL('meleerange', pkInteger, Ord(tfMeleeRange)),
    PL('maxstepheight', pkInteger, Ord(tfMaxStepHeight)),
    PL('maxdropoffheight', pkInteger, Ord(tfMaxDropoffHeight)),
    PL('gibhealth', pkInteger, Ord(tfGibHealth)),
    PL('maxtargetrange', pkInteger, Ord(tfMaxTargetRange)),
    PL('WeaveIndexXY', pkInteger, Ord(tfWeaveIndexXY)),
    PL('WeaveIndexZ', pkInteger, Ord(tfWeaveIndexZ)),
    PL('spriteDX', pkFixed, Ord(tfSpriteDX)),
    PL('spriteDY', pkFixed, Ord(tfSpriteDY)),
    PLF('flags5_ex', Ord(tfFlags5Ex), fsMobjFlags5Ex),
    PLF('flags6_ex', Ord(tfFlags6Ex), fsMobjFlags6Ex),
    PLG('infighting_group', Ord(tfInfightingGroup), egInfighting),
    PLG('projectile_group', Ord(tfProjectileGroup), egProjectile),
    PLG('splash_group', Ord(tfSplashGroup), egSplash),
    PL('ripsound', pkSound, Ord(tfRipSound)),
    PL('bloodcolor', pkInteger, Ord(tfBloodColor)),
    PL('translationname', pkText, Ord(ttTranslation)),
    PL('meleethreshold', pkInteger, Ord(tfMeleeThreshold))
  ];
end;

class function TExportProfiles.ThingHexenLines: TArray<TExportLine>;
begin
  Result := [
    LName('NAME', Ord(ttName)),
    LNum('INHERITSFROM', Ord(tfInheritsFrom)),
    LNum('ID #', Ord(tfDoomedNum)),
    LNum('INITIAL FRAME', Ord(tfSpawnState)),
    LNum('HIT POINTS', Ord(tfSpawnHealth)),
    LNum('FIRST MOVING FRAME', Ord(tfSeeState)),
    LNum('ALERT SOUND', Ord(tfSeeSound)),
    LNum('REACTION TIME', Ord(tfReactionTime)),
    LNum('ATTACK SOUND', Ord(tfAttackSound)),
    LNum('INJURY FRAME', Ord(tfPainState)),
    LNum('PAIN CHANCE', Ord(tfPainChance)),
    LNum('PAIN SOUND', Ord(tfPainSound)),
    LNum('CLOSE ATTACK FRAME', Ord(tfMeleeState)),
    LNum('FAR ATTACK FRAME', Ord(tfMissileState)),
    LNum('DEATH FRAME', Ord(tfDeathState)),
    LNum('EXPLODING FRAME', Ord(tfXDeathState)),
    LNum('DEATH SOUND', Ord(tfDeathSound)),
    LNum('SPEED', Ord(tfSpeed)),
    LNum('WIDTH', Ord(tfRadius)),
    LNum('HEIGHT', Ord(tfHeight)),
    LNum('MASS', Ord(tfMass)),
    LNum('MISSILE DAMAGE', Ord(tfDamage)),
    LNum('ACTION SOUND', Ord(tfActiveSound)),
    LNum('RESPAWN FRAME', Ord(tfRaiseState)),
    LFlags('BITS', Ord(tfFlags), fsMobjFlags),
    LFlags('BITS2', Ord(tfFlags2), fsMobjFlags2),
    LComment('# The following fields are DelphiHexen specific enhancements'),
    LFlags('FLAGS_EX', Ord(tfFlagsEx), fsMobjFlagsEx),
    LFlags('FLAGS2_EX', Ord(tfFlags2Ex), fsMobjFlags2Ex),
    LNum('CUSTOM SOUND 1', Ord(tfCustomSound1)),
    LNum('CUSTOM SOUND 2', Ord(tfCustomSound2)),
    LNum('CUSTOM SOUND 3', Ord(tfCustomSound3)),
    LNum('EXPLOSION DAMAGE', Ord(tfExplosionDamage)),
    LNum('EXPLOSION RADIUS', Ord(tfExplosionRadius)),
    LNum('MELEE DAMAGE', Ord(tfMeleeDamage)),
    LNum('MELEE SOUND', Ord(tfMeleeSound)),
    LKind(lkRenderStyle, 'RENDERSTYLE', Ord(tfRenderStyle)),
    LNum('ALPHA', Ord(tfAlpha)),
    LNum('DROPITEM', Ord(tfDropItem)),
    LNum('MISSILETYPE', Ord(tfMissileType)),
    LNum('HEAL FRAME', Ord(tfHealState)),
    LNum('CRASH FRAME', Ord(tfCrashState)),
    LNum('VSPEED', Ord(tfVSpeed)),
    LNum('PUSHFACTOR', Ord(tfPushFactor)),
    LNum('SCALE', Ord(tfScale)),
    LNum('GRAVITY', Ord(tfGravity)),
    LFlags('FLAGS3_EX', Ord(tfFlags3Ex), fsMobjFlags3Ex),
    LFlags('FLAGS4_EX', Ord(tfFlags4Ex), fsMobjFlags4Ex),
    LNum('MINMISSILECHANCE', Ord(tfMinMissileChance)),
    LNum('FLOAT SPEED', Ord(tfFloatSpeed)),
    LNum('NORMAL SPEED', Ord(tfNormalSpeed)),
    LNum('FAST SPEED', Ord(tfFastSpeed)),
    LQuoted('OBITUARY', Ord(ttObituary)),
    LQuoted('HIT OBITUARY', Ord(ttHitObituary)),
    LKind(lkGender, 'GENDER', Ord(tfGender)),
    LNum('MELEE RANGE', Ord(tfMeleeRange)),
    LNum('MAX STEP HEIGHT', Ord(tfMaxStepHeight)),
    LNum('MAX DROPOFF HEIGHT', Ord(tfMaxDropoffHeight)),
    LNum('GIB HEALTH', Ord(tfGibHealth)),
    LNum('MAX TARGET RANGE', Ord(tfMaxTargetRange)),
    LNum('WEAVE INDEX XY', Ord(tfWeaveIndexXY)),
    LNum('WEAVE INDEX Z', Ord(tfWeaveIndexZ)),
    LNum('FRICTION', Ord(tfFriction)),
    LNum('SPRITE DX', Ord(tfSpriteDX)),
    LNum('SPRITE DY', Ord(tfSpriteDY)),
    LNum('INTERACT FRAME', Ord(tfInteractState)),
    LFlags('FLAGS5_EX', Ord(tfFlags5Ex), fsMobjFlags5Ex),
    LFlags('FLAGS6_EX', Ord(tfFlags6Ex), fsMobjFlags6Ex),
    LGroup('INFIGHTING GROUP', Ord(tfInfightingGroup), egInfighting),
    LGroup('PROJECTILE GROUP', Ord(tfProjectileGroup), egProjectile),
    LGroup('SPLASH GROUP', Ord(tfSplashGroup), egSplash),
    LNum('RIP SOUND', Ord(tfRipSound)),
    LNum('CRUSH FRAME', Ord(tfCrushState)),
    LNum('BLOOD COLOR', Ord(tfBloodColor)),
    LQuoted('TRANSLATION', Ord(ttTranslation)),
    LNum('MISSILEHEIGHT', Ord(tfMissileHeight)),
    LNum('MELEE THRESHOLD', Ord(tfMeleeThreshold))
  ];
end;

class function TExportProfiles.PascalThingHexenLines: TArray<TExportPascalLine>;
begin
  Result := [
    PL('name', pkText, Ord(ttName)),
    PL('inheritsfrom', pkInteger, Ord(tfInheritsFrom)),
    PL('doomednum', pkInteger, Ord(tfDoomedNum)),
    PL('spawnstate', pkState, Ord(tfSpawnState)),
    PL('spawnhealth', pkInteger, Ord(tfSpawnHealth)),
    PL('seestate', pkState, Ord(tfSeeState)),
    PL('seesound', pkSound, Ord(tfSeeSound)),
    PL('reactiontime', pkInteger, Ord(tfReactionTime)),
    PL('attacksound', pkSound, Ord(tfAttackSound)),
    PL('painstate', pkState, Ord(tfPainState)),
    PL('painchance', pkInteger, Ord(tfPainChance)),
    PL('painsound', pkSound, Ord(tfPainSound)),
    PL('meleestate', pkState, Ord(tfMeleeState)),
    PL('missilestate', pkState, Ord(tfMissileState)),
    PL('deathstate', pkState, Ord(tfDeathState)),
    PL('xdeathstate', pkState, Ord(tfXDeathState)),
    PL('deathsound', pkSound, Ord(tfDeathSound)),
    PL('speed', pkFixed, Ord(tfSpeed)),
    PL('radius', pkFixed, Ord(tfRadius)),
    PL('height', pkFixed, Ord(tfHeight)),
    PL('mass', pkInteger, Ord(tfMass)),
    PL('damage', pkInteger, Ord(tfDamage)),
    PL('activesound', pkSound, Ord(tfActiveSound)),
    PLF('flags', Ord(tfFlags), fsMobjFlags),
    PLF('flags2', Ord(tfFlags2), fsMobjFlags2),
    PLF('flags_ex', Ord(tfFlagsEx), fsMobjFlagsEx),
    PLF('flags2_ex', Ord(tfFlags2Ex), fsMobjFlags2Ex),
    PL('raisestate', pkState, Ord(tfRaiseState)),
    PL('customsound1', pkSound, Ord(tfCustomSound1)),
    PL('customsound2', pkSound, Ord(tfCustomSound2)),
    PL('customsound3', pkSound, Ord(tfCustomSound3)),
    PL('meleesound', pkSound, Ord(tfMeleeSound)),
    PL('dropitem', pkInteger, Ord(tfDropItem)),
    PL('missiletype', pkInteger, Ord(tfMissileType)),
    PL('explosiondamage', pkInteger, Ord(tfExplosionDamage)),
    PL('explosionradius', pkInteger, Ord(tfExplosionRadius)),
    PL('meleedamage', pkInteger, Ord(tfMeleeDamage)),
    PL('renderstyle', pkRenderStyle, Ord(tfRenderStyle)),
    PL('alpha', pkInteger, Ord(tfAlpha)),
    PL('healstate', pkState, Ord(tfHealState)),
    PL('crashstate', pkState, Ord(tfCrashState)),
    PL('crushstate', pkState, Ord(tfCrushState)),
    PL('interactstate', pkState, Ord(tfInteractState)),
    PL('missileheight', pkInteger, Ord(tfMissileHeight)),
    PL('vspeed', pkInteger, Ord(tfVSpeed)),
    PL('pushfactor', pkPushFactor, Ord(tfPushFactor)),
    PL('friction', pkFriction, Ord(tfFriction)),
    PL('scale', pkFixed, Ord(tfScale)),
    PL('gravity', pkFixed, Ord(tfGravity)),
    PLF('flags3_ex', Ord(tfFlags3Ex), fsMobjFlags3Ex),
    PLF('flags4_ex', Ord(tfFlags4Ex), fsMobjFlags4Ex),
    PL('minmissilechance', pkInteger, Ord(tfMinMissileChance)),
    PL('floatspeed', pkFixed, Ord(tfFloatSpeed)),
    PL('normalspeed', pkFixed, Ord(tfNormalSpeed)),
    PL('fastspeed', pkFixed, Ord(tfFastSpeed)),
    PL('obituary', pkText, Ord(ttObituary)),
    PL('hitobituary', pkText, Ord(ttHitObituary)),
    PL('gender', pkGender, Ord(tfGender)),
    PL('meleerange', pkInteger, Ord(tfMeleeRange)),
    PL('maxstepheight', pkInteger, Ord(tfMaxStepHeight)),
    PL('maxdropoffheight', pkInteger, Ord(tfMaxDropoffHeight)),
    PL('gibhealth', pkInteger, Ord(tfGibHealth)),
    PL('maxtargetrange', pkInteger, Ord(tfMaxTargetRange)),
    PL('WeaveIndexXY', pkInteger, Ord(tfWeaveIndexXY)),
    PL('WeaveIndexZ', pkInteger, Ord(tfWeaveIndexZ)),
    PL('spriteDX', pkFixed, Ord(tfSpriteDX)),
    PL('spriteDY', pkFixed, Ord(tfSpriteDY)),
    PLF('flags5_ex', Ord(tfFlags5Ex), fsMobjFlags5Ex),
    PLF('flags6_ex', Ord(tfFlags6Ex), fsMobjFlags6Ex),
    PLG('infighting_group', Ord(tfInfightingGroup), egInfighting),
    PLG('projectile_group', Ord(tfProjectileGroup), egProjectile),
    PLG('splash_group', Ord(tfSplashGroup), egSplash),
    PL('ripsound', pkSound, Ord(tfRipSound)),
    PL('bloodcolor', pkInteger, Ord(tfBloodColor)),
    PL('translationname', pkText, Ord(ttTranslation)),
    PL('meleethreshold', pkInteger, Ord(tfMeleeThreshold))
  ];
end;

class function TExportProfiles.ThingStrifeLines: TArray<TExportLine>;
begin
  Result := [
    LName('NAME', Ord(ttName)),
    LNum('INHERITSFROM', Ord(tfInheritsFrom)),
    LNum('ID #', Ord(tfDoomedNum)),
    LNum('INITIAL FRAME', Ord(tfSpawnState)),
    LNum('HIT POINTS', Ord(tfSpawnHealth)),
    LNum('FIRST MOVING FRAME', Ord(tfSeeState)),
    LNum('ALERT SOUND', Ord(tfSeeSound)),
    LNum('REACTION TIME', Ord(tfReactionTime)),
    LNum('ATTACK SOUND', Ord(tfAttackSound)),
    LNum('INJURY FRAME', Ord(tfPainState)),
    LNum('PAIN CHANCE', Ord(tfPainChance)),
    LNum('PAIN SOUND', Ord(tfPainSound)),
    LNum('CLOSE ATTACK FRAME', Ord(tfMeleeState)),
    LNum('FAR ATTACK FRAME', Ord(tfMissileState)),
    LNum('DEATH FRAME', Ord(tfDeathState)),
    LNum('EXPLODING FRAME', Ord(tfXDeathState)),
    LNum('DEATH SOUND', Ord(tfDeathSound)),
    LNum('SPEED', Ord(tfSpeed)),
    LNum('WIDTH', Ord(tfRadius)),
    LNum('HEIGHT', Ord(tfHeight)),
    LNum('MASS', Ord(tfMass)),
    LNum('MISSILE DAMAGE', Ord(tfDamage)),
    LNum('ACTION SOUND', Ord(tfActiveSound)),
    LNum('RESPAWN FRAME', Ord(tfRaiseState)),
    LFlags('BITS', Ord(tfFlags), fsMobjFlags),
    LComment('# The following fields are DelphiStrife specific enhancements'),
    LFlags('FLAGS_EX', Ord(tfFlagsEx), fsMobjFlagsEx),
    LFlags('FLAGS2_EX', Ord(tfFlags2Ex), fsMobjFlags2Ex),
    LNum('CUSTOM SOUND 1', Ord(tfCustomSound1)),
    LNum('CUSTOM SOUND 2', Ord(tfCustomSound2)),
    LNum('CUSTOM SOUND 3', Ord(tfCustomSound3)),
    LNum('EXPLOSION DAMAGE', Ord(tfExplosionDamage)),
    LNum('EXPLOSION RADIUS', Ord(tfExplosionRadius)),
    LNum('MELEE DAMAGE', Ord(tfMeleeDamage)),
    LNum('MELEE SOUND', Ord(tfMeleeSound)),
    LKind(lkRenderStyle, 'RENDERSTYLE', Ord(tfRenderStyle)),
    LNum('ALPHA', Ord(tfAlpha)),
    LNum('DROPITEM', Ord(tfDropItem)),
    LNum('MISSILETYPE', Ord(tfMissileType)),
    LNum('HEAL FRAME', Ord(tfHealState)),
    LNum('CRASH FRAME', Ord(tfCrashState)),
    LNum('INTERACT FRAME', Ord(tfInteractState)),
    LNum('MISSILEHEIGHT', Ord(tfMissileHeight)),
    LName('NAME2', Ord(ttName2)),
    LNum('VSPEED', Ord(tfVSpeed)),
    LNum('PUSHFACTOR', Ord(tfPushFactor)),
    LNum('SCALE', Ord(tfScale)),
    LNum('GRAVITY', Ord(tfGravity)),
    LFlags('FLAGS3_EX', Ord(tfFlags3Ex), fsMobjFlags3Ex),
    LFlags('FLAGS4_EX', Ord(tfFlags4Ex), fsMobjFlags4Ex),
    LNum('MINMISSILECHANCE', Ord(tfMinMissileChance)),
    LNum('FLOAT SPEED', Ord(tfFloatSpeed)),
    LNum('NORMAL SPEED', Ord(tfNormalSpeed)),
    LNum('FAST SPEED', Ord(tfFastSpeed)),
    LQuoted('OBITUARY', Ord(ttObituary)),
    LQuoted('HIT OBITUARY', Ord(ttHitObituary)),
    LKind(lkGender, 'GENDER', Ord(tfGender)),
    LNum('MELEE RANGE', Ord(tfMeleeRange)),
    LNum('MAX STEP HEIGHT', Ord(tfMaxStepHeight)),
    LNum('MAX DROPOFF HEIGHT', Ord(tfMaxDropoffHeight)),
    LNum('GIB HEALTH', Ord(tfGibHealth)),
    LNum('MAX TARGET RANGE', Ord(tfMaxTargetRange)),
    LNum('WEAVE INDEX XY', Ord(tfWeaveIndexXY)),
    LNum('WEAVE INDEX Z', Ord(tfWeaveIndexZ)),
    LNum('FRICTION', Ord(tfFriction)),
    LNum('SPRITE DX', Ord(tfSpriteDX)),
    LNum('SPRITE DY', Ord(tfSpriteDY)),
    LFlags('FLAGS5_EX', Ord(tfFlags5Ex), fsMobjFlags5Ex),
    LFlags('FLAGS6_EX', Ord(tfFlags6Ex), fsMobjFlags6Ex),
    LGroup('INFIGHTING GROUP', Ord(tfInfightingGroup), egInfighting),
    LGroup('PROJECTILE GROUP', Ord(tfProjectileGroup), egProjectile),
    LGroup('SPLASH GROUP', Ord(tfSplashGroup), egSplash),
    LNum('RIP SOUND', Ord(tfRipSound)),
    LNum('CRUSH FRAME', Ord(tfCrushState)),
    LNum('BLOOD COLOR', Ord(tfBloodColor)),
    LQuoted('TRANSLATION', Ord(ttTranslation)),
    LNum('MELEE THRESHOLD', Ord(tfMeleeThreshold))
  ];
end;

class function TExportProfiles.PascalThingStrifeLines: TArray<TExportPascalLine>;
begin
  Result := [
    PL('name', pkText, Ord(ttName)),
    PL('name2', pkText, Ord(ttName2)),
    PL('inheritsfrom', pkInteger, Ord(tfInheritsFrom)),
    PL('doomednum', pkInteger, Ord(tfDoomedNum)),
    PL('spawnstate', pkState, Ord(tfSpawnState)),
    PL('spawnhealth', pkInteger, Ord(tfSpawnHealth)),
    PL('seestate', pkState, Ord(tfSeeState)),
    PL('seesound', pkSound, Ord(tfSeeSound)),
    PL('reactiontime', pkInteger, Ord(tfReactionTime)),
    PL('attacksound', pkSound, Ord(tfAttackSound)),
    PL('painstate', pkState, Ord(tfPainState)),
    PL('painchance', pkInteger, Ord(tfPainChance)),
    PL('painsound', pkSound, Ord(tfPainSound)),
    PL('meleestate', pkState, Ord(tfMeleeState)),
    PL('missilestate', pkState, Ord(tfMissileState)),
    PL('deathstate', pkState, Ord(tfDeathState)),
    PL('xdeathstate', pkState, Ord(tfXDeathState)),
    PL('deathsound', pkSound, Ord(tfDeathSound)),
    PL('speed', pkFixed, Ord(tfSpeed)),
    PL('radius', pkFixed, Ord(tfRadius)),
    PL('height', pkFixed, Ord(tfHeight)),
    PL('mass', pkInteger, Ord(tfMass)),
    PL('damage', pkInteger, Ord(tfDamage)),
    PL('activesound', pkSound, Ord(tfActiveSound)),
    PLF('flags', Ord(tfFlags), fsMobjFlags),
    PLF('flags_ex', Ord(tfFlagsEx), fsMobjFlagsEx),
    PLF('flags2_ex', Ord(tfFlags2Ex), fsMobjFlags2Ex),
    PL('raisestate', pkState, Ord(tfRaiseState)),
    PL('customsound1', pkSound, Ord(tfCustomSound1)),
    PL('customsound2', pkSound, Ord(tfCustomSound2)),
    PL('customsound3', pkSound, Ord(tfCustomSound3)),
    PL('meleesound', pkSound, Ord(tfMeleeSound)),
    PL('dropitem', pkInteger, Ord(tfDropItem)),
    PL('missiletype', pkInteger, Ord(tfMissileType)),
    PL('explosiondamage', pkInteger, Ord(tfExplosionDamage)),
    PL('explosionradius', pkInteger, Ord(tfExplosionRadius)),
    PL('meleedamage', pkInteger, Ord(tfMeleeDamage)),
    PL('renderstyle', pkRenderStyle, Ord(tfRenderStyle)),
    PL('alpha', pkInteger, Ord(tfAlpha)),
    PL('healstate', pkState, Ord(tfHealState)),
    PL('crashstate', pkState, Ord(tfCrashState)),
    PL('crushstate', pkState, Ord(tfCrushState)),
    PL('interactstate', pkState, Ord(tfInteractState)),
    PL('missileheight', pkInteger, Ord(tfMissileHeight)),
    PL('vspeed', pkInteger, Ord(tfVSpeed)),
    PL('pushfactor', pkPushFactor, Ord(tfPushFactor)),
    PL('friction', pkFriction, Ord(tfFriction)),
    PL('scale', pkFixed, Ord(tfScale)),
    PL('gravity', pkFixed, Ord(tfGravity)),
    PLF('flags3_ex', Ord(tfFlags3Ex), fsMobjFlags3Ex),
    PLF('flags4_ex', Ord(tfFlags4Ex), fsMobjFlags4Ex),
    PL('minmissilechance', pkInteger, Ord(tfMinMissileChance)),
    PL('floatspeed', pkFixed, Ord(tfFloatSpeed)),
    PL('normalspeed', pkFixed, Ord(tfNormalSpeed)),
    PL('fastspeed', pkFixed, Ord(tfFastSpeed)),
    PL('obituary', pkText, Ord(ttObituary)),
    PL('hitobituary', pkText, Ord(ttHitObituary)),
    PL('gender', pkGender, Ord(tfGender)),
    PL('meleerange', pkInteger, Ord(tfMeleeRange)),
    PL('maxstepheight', pkInteger, Ord(tfMaxStepHeight)),
    PL('maxdropoffheight', pkInteger, Ord(tfMaxDropoffHeight)),
    PL('gibhealth', pkInteger, Ord(tfGibHealth)),
    PL('maxtargetrange', pkInteger, Ord(tfMaxTargetRange)),
    PL('WeaveIndexXY', pkInteger, Ord(tfWeaveIndexXY)),
    PL('WeaveIndexZ', pkInteger, Ord(tfWeaveIndexZ)),
    PL('spriteDX', pkFixed, Ord(tfSpriteDX)),
    PL('spriteDY', pkFixed, Ord(tfSpriteDY)),
    PLF('flags5_ex', Ord(tfFlags5Ex), fsMobjFlags5Ex),
    PLF('flags6_ex', Ord(tfFlags6Ex), fsMobjFlags6Ex),
    PLG('infighting_group', Ord(tfInfightingGroup), egInfighting),
    PLG('projectile_group', Ord(tfProjectileGroup), egProjectile),
    PLG('splash_group', Ord(tfSplashGroup), egSplash),
    PL('ripsound', pkSound, Ord(tfRipSound)),
    PL('bloodcolor', pkInteger, Ord(tfBloodColor)),
    PL('translationname', pkText, Ord(ttTranslation)),
    PL('meleethreshold', pkInteger, Ord(tfMeleeThreshold))
  ];
end;

class function TExportProfiles.StateLines(const AGameName: string): TArray<TExportLine>;
begin
  Result := [
    LNum('SPRITE NUMBER', Ord(sfSprite)),
    LNum('SPRITE SUBNUMBER', Ord(sfFrame)),
    LNum('DURATION', Ord(sfTics)),
    LNum('DURATION 2', Ord(sfTics2)),
    LNum('NEXT FRAME', Ord(sfNextState)),
    LKind(lkAction, 'CODEP FRAME', 0),
    LNum('UNKNOWN 1', Ord(sfMisc1)),
    LNum('UNKNOWN 2', Ord(sfMisc2)),
    LComment('# Flags_ex is Delphi' + AGameName + ' specific and declares transparency and light effects'),
    LFlags('FLAGS_EX', Ord(sfFlagsEx), fsStateFlagsEx),
    LFlags('MBF21 BITS', Ord(sfMbf21Bits), fsStateFlagsMbf21)
  ];
end;

class function TExportProfiles.PascalStateLines: TArray<TExportPascalLine>;
begin
  Result := [
    PL('sprite', pkSprite, Ord(sfSprite)),
    PL('frame', pkInteger, Ord(sfFrame)),
    PL('tics', pkInteger, Ord(sfTics)),
    PL('tics2', pkInteger, Ord(sfTics2)),
    PL('action.acp1', pkAction, 0),
    PL('nextstate', pkNextState, Ord(sfNextState)),
    PL('misc1', pkInteger, Ord(sfMisc1)),
    PL('misc2', pkInteger, Ord(sfMisc2)),
    PLF('flags_ex', Ord(sfFlagsEx), fsStateFlagsEx)
  ];
end;

class function TExportProfiles.WeaponLines(const AAmmoToken: string; AWithLevel: Boolean): TArray<TExportLine>;
var
  LLines: TArray<TExportLine>;
begin
  LLines := [
    LKind(lkAmmo, AAmmoToken, Ord(wfAmmo)),
    LNum('DESELECT FRAME', Ord(wfUpState)),
    LNum('SELECT FRAME', Ord(wfDownState)),
    LNum('BOBBING FRAME', Ord(wfReadyState)),
    LNum('SHOOTING FRAME', Ord(wfAttackState)),
    LNum('HOLD SHOOTING FRAME', Ord(wfHoldAttackState)),
    LNum('FIRING FRAME', Ord(wfFlashState)),
    LNum('AMMO PER SHOT', Ord(wfAmmoPerShot)),
    LFlags('MBF21 BITS', Ord(wfMbf21Bits), fsWeaponFlagsMbf21)
  ];
  if AWithLevel then
    Result := [LKind(lkLevel, 'LEVEL', 0)] + LLines
  else
    Result := LLines;
end;

class function TExportProfiles.MiscLines(const ATokens: array of string): TArray<TExportLine>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ATokens));
  for LIndex := 0 to High(ATokens) do
    Result[LIndex] := LNum(ATokens[LIndex], LIndex);
end;

class function TExportProfiles.NameOf(AGame: TExportGame): string;
const
  GAME_NAMES: array[TExportGame] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE');
begin
  Result := GAME_NAMES[AGame];
end;

class function TExportProfiles.TryFromName(const AName: string; out AGame: TExportGame): Boolean;
var
  LGame: TExportGame;
begin
  for LGame := Low(TExportGame) to High(TExportGame) do
    if SameText(NameOf(LGame), AName) then
    begin
      AGame := LGame;
      Exit(True);
    end;
  AGame := TExportGame.Doom;
  Result := False;
end;

class function TExportProfiles.ForGame(AGame: TExportGame): TExportProfile;
const
  DISPLAY_NAMES: array[TExportGame] of string = ('Doom', 'Heretic', 'Hexen', 'Strife');
begin
  Result := Default(TExportProfile);
  Result.Game := AGame;
  Result.GameName := DISPLAY_NAMES[AGame];
  Result.StateLines := StateLines(Result.GameName);
  Result.PascalStateLines := PascalStateLines;
  Result.ParMaps := 9;
  case AGame of
    TExportGame.Doom:
      begin
        Result.ThingLines := ThingDoomLines;
        Result.PascalThingLines := PascalThingDoomLines;
        Result.WeaponLines := WeaponLines('AMMO TYPE', False);
        Result.AmmoLines := [LNum('MAX AMMO', 0), LNum('PER AMMO', 1)];
        Result.MiscLines := MiscLines(['MAX HEALTH', 'SOULSPHERE HEALTH', 'MEGASPHERE HEALTH',
          'MEDIKIT HEALTH', 'STIMPACK HEALTH', 'HEALTHBONUS HEALTH', 'MAX ARMOR', 'GREEN ARMOR CLASS',
          'BLUE ARMOR CLASS', 'INITIAL BULLETS', 'BFG CELLS/SHOT', 'IDFA ARMOR', 'IDFA ARMOR CLASS',
          'IDKFA ARMOR', 'IDKFA ARMOR CLASS', 'MAX SOULSPHERE']);
        Result.ParEpisodes := 3;
        Result.ParEpisodeHeader := '# Doom 1';
        Result.ParCommercialMaps := 32;
      end;
    TExportGame.Heretic:
      begin
        Result.ThingLines := ThingHereticLines;
        Result.PascalThingLines := PascalThingHereticLines;
        Result.WeaponLines := WeaponLines('AMMO TYPE', True);
        Result.AmmoLines := [LNum('MAX AMMO', 0)];
        Result.MiscLines := MiscLines(['MAX HEALTH', 'SOULSPHERE HEALTH', 'MEGASPHERE HEALTH',
          'MEDIKIT HEALTH', 'STIMPACK HEALTH', 'HEALTHBONUS HEALTH', 'MAX ARMOR', 'GREEN ARMOR CLASS',
          'BLUE ARMOR CLASS', 'MAX CHICKEN HEALTH', 'MAX ARTIFACTS']);
        Result.ParEpisodes := 5;
        Result.ParEpisodeHeader := '# Heretic';
      end;
    TExportGame.Hexen:
      begin
        Result.ThingLines := ThingHexenLines;
        Result.PascalThingLines := PascalThingHexenLines;
        Result.WeaponLines := WeaponLines('MANA TYPE', False);
        Result.WeaponHeaderHasClass := True;
        Result.MiscLines := MiscLines(['MAX MORPH HEALTH', 'MAX ARTIFACTS', 'QUARTZ FLASK HEALTH',
          'MYSTIC URN HEALTH', 'MAX MANA']);
      end;
    TExportGame.Strife:
      begin
        Result.ThingLines := ThingStrifeLines;
        Result.PascalThingLines := PascalThingStrifeLines;
        Result.WeaponLines := WeaponLines('AMMO TYPE', False);
        Result.AmmoLines := [LNum('MAX AMMO', 0), LNum('PER AMMO', 1)];
        Result.MiscLines := MiscLines(['MAX HEALTH', 'SOULSPHERE HEALTH', 'MEGASPHERE HEALTH',
          'MEDIKIT HEALTH', 'STIMPACK HEALTH', 'HEALTHBONUS HEALTH', 'MAX ARMOR', 'GREEN ARMOR CLASS',
          'BLUE ARMOR CLASS']);
      end;
  end;
end;

end.