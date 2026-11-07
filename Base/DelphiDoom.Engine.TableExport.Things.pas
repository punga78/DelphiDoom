{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the things (mobjinfo) for the table exports            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.TableExport.Things;

interface

uses
  DelphiDoom.TableExport.Types,
  DelphiDoom.TableExport.Intf;

type
  /// <summary>The things of the game: the current table, or the one built in the program</summary>
  TEngineExportThings = class(TInterfacedObject, IExportThingSource)
  strict private
    FBuiltIn: Boolean;
  public
    /// <param name="ABuiltIn">True for the table that the game had before any patch</param>
    constructor Create(ABuiltIn: Boolean);
    function Count: Integer;
    function Get(AIndex: Integer): TExportThing;
  end;

implementation

uses
  info_h,
  info,
  info_common;

{ TEngineExportThings }

constructor TEngineExportThings.Create(ABuiltIn: Boolean);
begin
  inherited Create;
  FBuiltIn := ABuiltIn;
end;

function TEngineExportThings.Count: Integer;
begin
  Result := nummobjtypes;
end;

function TEngineExportThings.Get(AIndex: Integer): TExportThing;
var
  LInfo: Pmobjinfo_t;

  function CharsToText(const AChars: PAnsiChar): string;
  var
    LIndex: Integer;
  begin
    Result := '';
    for LIndex := 0 to MOBJINFONAMESIZE - 1 do
      if AChars[LIndex] = #0 then
        Exit
      else
        Result := Result + Char(AChars[LIndex]);
  end;

begin
  Result := Default(TExportThing);
  if FBuiltIn then
    LInfo := @pDO_mobjinfo[AIndex]
  else
    LInfo := @mobjinfo[AIndex];

  Result.Texts[ttName] := Info_GetMobjName(LInfo);
  {$IFDEF STRIFE}
  Result.Texts[ttName2] := CharsToText(@LInfo.name2[0]);
  {$ENDIF}
  Result.Texts[ttObituary] := LInfo.obituary;
  Result.Texts[ttHitObituary] := LInfo.hitobituary;
  Result.Texts[ttTranslation] := LInfo.translationname;

  Result.Numbers[tfInheritsFrom] := LInfo.inheritsfrom;
  Result.Numbers[tfDoomedNum] := LInfo.doomednum;
  Result.Numbers[tfSpawnState] := LInfo.spawnstate;
  Result.Numbers[tfSpawnHealth] := LInfo.spawnhealth;
  Result.Numbers[tfSeeState] := LInfo.seestate;
  Result.Numbers[tfSeeSound] := LInfo.seesound;
  Result.Numbers[tfReactionTime] := LInfo.reactiontime;
  Result.Numbers[tfAttackSound] := LInfo.attacksound;
  Result.Numbers[tfPainState] := LInfo.painstate;
  Result.Numbers[tfPainChance] := LInfo.painchance;
  Result.Numbers[tfPainSound] := LInfo.painsound;
  Result.Numbers[tfMeleeState] := LInfo.meleestate;
  Result.Numbers[tfMissileState] := LInfo.missilestate;
  Result.Numbers[tfDeathState] := LInfo.deathstate;
  Result.Numbers[tfXDeathState] := LInfo.xdeathstate;
  Result.Numbers[tfDeathSound] := LInfo.deathsound;
  Result.Numbers[tfSpeed] := LInfo.speed;
  Result.Numbers[tfRadius] := LInfo.radius;
  Result.Numbers[tfHeight] := LInfo.height;
  Result.Numbers[tfMass] := LInfo.mass;
  Result.Numbers[tfDamage] := LInfo.damage;
  Result.Numbers[tfActiveSound] := LInfo.activesound;
  Result.Numbers[tfRaiseState] := LInfo.raisestate;
  Result.Numbers[tfFlags] := LInfo.flags;
  {$IFDEF HERETIC_OR_HEXEN}
  Result.Numbers[tfFlags2] := LInfo.flags2;
  {$ENDIF}
  Result.Numbers[tfFlagsEx] := LInfo.flags_ex;
  Result.Numbers[tfFlags2Ex] := LInfo.flags2_ex;
  Result.Numbers[tfFlags3Ex] := LInfo.flags3_ex;
  Result.Numbers[tfFlags4Ex] := LInfo.flags4_ex;
  Result.Numbers[tfFlags5Ex] := LInfo.flags5_ex;
  Result.Numbers[tfFlags6Ex] := LInfo.flags6_ex;
  Result.Numbers[tfCustomSound1] := LInfo.customsound1;
  Result.Numbers[tfCustomSound2] := LInfo.customsound2;
  Result.Numbers[tfCustomSound3] := LInfo.customsound3;
  Result.Numbers[tfExplosionDamage] := LInfo.explosiondamage;
  Result.Numbers[tfExplosionRadius] := LInfo.explosionradius;
  Result.Numbers[tfMeleeDamage] := LInfo.meleedamage;
  Result.Numbers[tfMeleeSound] := LInfo.meleesound;
  Result.Numbers[tfRenderStyle] := Ord(LInfo.renderstyle);
  Result.Numbers[tfAlpha] := LInfo.alpha;
  Result.Numbers[tfDropItem] := LInfo.dropitem;
  Result.Numbers[tfMissileType] := LInfo.missiletype;
  Result.Numbers[tfHealState] := LInfo.healstate;
  Result.Numbers[tfCrashState] := LInfo.crashstate;
  Result.Numbers[tfCrushState] := LInfo.crushstate;
  Result.Numbers[tfInteractState] := LInfo.interactstate;
  Result.Numbers[tfMissileHeight] := LInfo.missileheight;
  Result.Numbers[tfVSpeed] := LInfo.vspeed;
  Result.Numbers[tfPushFactor] := LInfo.pushfactor;
  Result.Numbers[tfFriction] := LInfo.friction;
  Result.Numbers[tfScale] := LInfo.scale;
  Result.Numbers[tfGravity] := LInfo.gravity;
  Result.Numbers[tfMinMissileChance] := LInfo.minmissilechance;
  Result.Numbers[tfFloatSpeed] := LInfo.floatspeed;
  Result.Numbers[tfNormalSpeed] := LInfo.normalspeed;
  Result.Numbers[tfFastSpeed] := LInfo.fastspeed;
  Result.Numbers[tfGender] := Ord(LInfo.gender);
  Result.Numbers[tfMeleeRange] := LInfo.meleerange;
  Result.Numbers[tfMaxStepHeight] := LInfo.maxstepheight;
  Result.Numbers[tfMaxDropoffHeight] := LInfo.maxdropoffheight;
  Result.Numbers[tfGibHealth] := LInfo.gibhealth;
  Result.Numbers[tfMaxTargetRange] := LInfo.maxtargetrange;
  Result.Numbers[tfWeaveIndexXY] := LInfo.WeaveIndexXY;
  Result.Numbers[tfWeaveIndexZ] := LInfo.WeaveIndexZ;
  Result.Numbers[tfSpriteDX] := LInfo.spriteDX;
  Result.Numbers[tfSpriteDY] := LInfo.spriteDY;
  Result.Numbers[tfInfightingGroup] := LInfo.infighting_group;
  Result.Numbers[tfProjectileGroup] := LInfo.projectile_group;
  Result.Numbers[tfSplashGroup] := LInfo.splash_group;
  Result.Numbers[tfRipSound] := LInfo.ripsound;
  Result.Numbers[tfBloodColor] := LInfo.bloodcolor;
  Result.Numbers[tfMeleeThreshold] := LInfo.meleethreshold;
end;

end.
