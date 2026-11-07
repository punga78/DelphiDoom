{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the ACTORDEF library asks of the game             }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.ActorDef.Catalog;

{$I Doom32.inc}

interface

uses
  DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.Intf;

type
  /// <summary>
  ///   The flag words, the numbers of the weapons and ammos, the actors and the state names of
  ///   the engine, as the parser of ACTORDEF asks for them. One class for four small
  ///   interfaces: each user of the library sees only its own
  /// </summary>
  TEngineActorDefCatalog = class(TInterfacedObject, IActorDefFlagCatalog, IActorDefNameCatalog,
    IActorDefActorCatalog, IActorDefStateCatalog)
  private
    FFlagWords: array[TActorDefFlagCategory] of TArray<string>;
    FFlagWordsLoaded: array[TActorDefFlagCategory] of Boolean;
    class function WordsOf(ACategory: TActorDefFlagCategory): TArray<string>; static;
    function BitsToWords(ABits: Integer; ACategory: TActorDefFlagCategory): string;
  public
    function Flags(ACategory: TActorDefFlagCategory): TArray<string>;
    function WeaponType(const AName: string): Integer;
    function AmmoType(const AName: string): Integer;
    function PlayerClass(const AName: string): Integer;
    function RenderStyleToken(const AName: string): string;
    function GenderName(const AName: string): string;
    function Find(const AName: string; out AIndex: Integer; out AActor: TActorDefActor): Boolean;
    function NameOf(AIndex: Integer): string;
    function AddAlias(const AName, AOtherName: string): Boolean;
    function IndexOfToken(const AToken: string): Integer;
    procedure Add(const AEntry: string);
  end;

implementation

uses
  d_delphi,
  deh_base,
  deh_main,
  info,
  info_h,
  info_common,
  DelphiDoom.Obituary.Genders,
  p_mobj_h,
  r_renderstyle,
  sc_states;

{ TEngineActorDefCatalog }

class function TEngineActorDefCatalog.WordsOf(ACategory: TActorDefFlagCategory): TArray<string>;
var
  LList: TDTextList;
  LIndex: Integer;
begin
  LList := nil;
  case ACategory of
    TActorDefFlagCategory.Flags:
      LList := mobj_flags;
{$IFDEF HERETIC_OR_HEXEN}
    TActorDefFlagCategory.Flags2:
      LList := mobj_flags2;
{$ENDIF}
    TActorDefFlagCategory.FlagsEx:
      LList := mobj_flags_ex;
    TActorDefFlagCategory.Flags2Ex:
      LList := mobj_flags2_ex;
    TActorDefFlagCategory.Flags3Ex:
      LList := mobj_flags3_ex;
    TActorDefFlagCategory.Flags4Ex:
      LList := mobj_flags4_ex;
    TActorDefFlagCategory.Flags5Ex:
      LList := mobj_flags5_ex;
    TActorDefFlagCategory.Flags6Ex:
      LList := mobj_flags6_ex;
    TActorDefFlagCategory.Weapon:
      LList := weapon_flags_mbf21;
  end;
  if not Assigned(LList) then
    Exit(nil);
  SetLength(Result, LList.Count);
  for LIndex := 0 to LList.Count - 1 do
    Result[LIndex] := LList[LIndex];
end;

function TEngineActorDefCatalog.Flags(ACategory: TActorDefFlagCategory): TArray<string>;
begin
  // the lists exist after the DEH subsystem started: they are read the first time they are asked
  if not FFlagWordsLoaded[ACategory] then
  begin
    FFlagWords[ACategory] := WordsOf(ACategory);
    FFlagWordsLoaded[ACategory] := True;
  end;
  Result := FFlagWords[ACategory];
end;

function TEngineActorDefCatalog.BitsToWords(ABits: Integer; ACategory: TActorDefFlagCategory): string;
var
  LWords: TArray<string>;
  LPosition: Integer;
begin
  Result := '';
  LWords := Flags(ACategory);
  for LPosition := 0 to 31 do
    if (ABits and (1 shl LPosition) <> 0) and (LPosition < Length(LWords)) then
      Result := Result + LWords[LPosition] + ' ';
end;

function TEngineActorDefCatalog.WeaponType(const AName: string): Integer;
begin
  Result := DEH_WeaponType(AName);
end;

function TEngineActorDefCatalog.AmmoType(const AName: string): Integer;
begin
  Result := DEH_AmmoType(AName);
end;

function TEngineActorDefCatalog.PlayerClass(const AName: string): Integer;
begin
{$IFDEF HEXEN}
  Result := DEH_PlayerClass(AName);
{$ELSE}
  Result := -1;
{$ENDIF}
end;

function TEngineActorDefCatalog.RenderStyleToken(const AName: string): string;
begin
  Result := renderstyle_tokens[Ord(R_GetRenderstyleForName(AName))];
end;

function TEngineActorDefCatalog.GenderName(const AName: string): string;
begin
  Result := TObituaryGenders.NameOf(TObituaryGenders.FindByName(AName));
end;

function TEngineActorDefCatalog.Find(const AName: string; out AIndex: Integer;
  out AActor: TActorDefActor): Boolean;
var
  LInfo: Pmobjinfo_t;

  function Marked(AState: Integer): Integer;
  begin
    Result := ACTORDEF_ORIGINAL_STATE_MARKER + AState;
  end;

  procedure MarkDefined(AState: Integer; ABit: Cardinal);
  begin
    if Marked(AState) > ACTORDEF_ORIGINAL_STATE_MARKER then
      AActor.StatesDefined := AActor.StatesDefined or ABit;
  end;

begin
  AIndex := Info_GetMobjNumForName(AName);
  Result := (AIndex >= 0) and (AIndex < nummobjtypes);
  if not Result then
    Exit;
  LInfo := @mobjinfo[AIndex];
  AActor := Default(TActorDefActor);
  AActor.Name := Info_GetMobjName(AIndex);
  AActor.DoomedNum := LInfo.doomednum;
  AActor.SpawnHealth := LInfo.spawnhealth;
  AActor.SeeSound := itoa(LInfo.seesound);
  AActor.ReactionTime := LInfo.reactiontime;
  AActor.AttackSound := itoa(LInfo.attacksound);
  AActor.PainChance := LInfo.painchance;
  AActor.PainSound := itoa(LInfo.painsound);
  AActor.DeathSound := itoa(LInfo.deathsound);
  AActor.Speed := LInfo.speed;
  AActor.Radius := LInfo.radius div ACTORDEF_FRACUNIT;
  AActor.Height := LInfo.height div ACTORDEF_FRACUNIT;
  AActor.Mass := LInfo.mass;
  AActor.Damage := LInfo.damage;
  AActor.ActiveSound := itoa(LInfo.activesound);
  AActor.Flags := BitsToWords(LInfo.flags, TActorDefFlagCategory.Flags);
{$IFDEF HERETIC_OR_HEXEN}
  AActor.Flags2 := BitsToWords(LInfo.flags2, TActorDefFlagCategory.Flags2);
{$ENDIF}
  AActor.FlagsEx := BitsToWords(LInfo.flags_ex, TActorDefFlagCategory.FlagsEx);
  AActor.Flags2Ex := BitsToWords(LInfo.flags2_ex, TActorDefFlagCategory.Flags2Ex);
  AActor.Flags3Ex := BitsToWords(LInfo.flags3_ex, TActorDefFlagCategory.Flags3Ex);
  AActor.Flags4Ex := BitsToWords(LInfo.flags4_ex, TActorDefFlagCategory.Flags4Ex);
  AActor.Flags5Ex := BitsToWords(LInfo.flags5_ex, TActorDefFlagCategory.Flags5Ex);
  AActor.Flags6Ex := BitsToWords(LInfo.flags6_ex, TActorDefFlagCategory.Flags6Ex);
  AActor.CustomSound1 := itoa(LInfo.customsound1);
  AActor.CustomSound2 := itoa(LInfo.customsound2);
  AActor.CustomSound3 := itoa(LInfo.customsound3);
  AActor.DropItem := itoa(LInfo.dropitem);
  AActor.MissileType := itoa(LInfo.missiletype);
  AActor.ExplosionDamage := LInfo.explosiondamage;
  AActor.ExplosionRadius := LInfo.explosionradius;
  AActor.MeleeDamage := LInfo.meleedamage;
  AActor.MeleeSound := itoa(LInfo.meleesound);
  AActor.RenderStyle := itoa(Ord(LInfo.renderstyle));
  AActor.Alpha := LInfo.alpha;
  AActor.MissileHeight := LInfo.missileheight;
  AActor.MeleeThreshold := LInfo.meleethreshold;
  AActor.VSpeed := LInfo.vspeed / ACTORDEF_FRACUNIT;
  AActor.PushFactor := LInfo.pushfactor / ACTORDEF_FRACUNIT;
  // the friction is not inherited: the parser starts every actor with the original one
  AActor.Friction := 0.90625;
  AActor.Scale := LInfo.scale / ACTORDEF_FRACUNIT;
  AActor.Gravity := LInfo.gravity / ACTORDEF_FRACUNIT;
  AActor.MinMissileChance := LInfo.minmissilechance;
  AActor.FloatSpeed := LInfo.floatspeed;
  AActor.NormalSpeed := LInfo.normalspeed;
  AActor.FastSpeed := LInfo.fastspeed;
  AActor.Obituary := string(LInfo.obituary);
  AActor.HitObituary := string(LInfo.hitobituary);
  AActor.Gender := itoa(Ord(LInfo.gender));
  AActor.MeleeRange := LInfo.meleerange;
  AActor.MaxStepHeight := LInfo.maxstepheight;
  AActor.MaxDropoffHeight := LInfo.maxdropoffheight;
  AActor.GibHealth := LInfo.gibhealth;
  AActor.MaxTargetRange := LInfo.maxtargetrange;
  AActor.WeaveIndexXY := LInfo.WeaveIndexXY;
  AActor.WeaveIndexZ := LInfo.WeaveIndexZ;
  AActor.SpriteDX := LInfo.spriteDX;
  AActor.SpriteDY := LInfo.spriteDY;
  AActor.RipSound := itoa(LInfo.ripsound);
  AActor.BloodColor := itoa(LInfo.bloodcolor);
  AActor.Translation := string(LInfo.translationname);

  AActor.SpawnState := Marked(LInfo.spawnstate);
  AActor.SeeState := Marked(LInfo.seestate);
  AActor.PainState := Marked(LInfo.painstate);
  AActor.MeleeState := Marked(LInfo.meleestate);
  AActor.MissileState := Marked(LInfo.missilestate);
  AActor.DeathState := Marked(LInfo.deathstate);
  AActor.XDeathState := Marked(LInfo.xdeathstate);
  AActor.RaiseState := Marked(LInfo.raisestate);
  AActor.HealState := Marked(LInfo.healstate);
  AActor.CrashState := Marked(LInfo.crashstate);
  AActor.CrushState := Marked(LInfo.crushstate);
  AActor.InteractState := Marked(LInfo.interactstate);
  AActor.ReplacesId := -1;
  MarkDefined(LInfo.spawnstate, ACTORDEF_ST_SPAWN);
  MarkDefined(LInfo.seestate, ACTORDEF_ST_SEE);
  MarkDefined(LInfo.meleestate, ACTORDEF_ST_MELEE);
  MarkDefined(LInfo.missilestate, ACTORDEF_ST_MISSILE);
  MarkDefined(LInfo.painstate, ACTORDEF_ST_PAIN);
  MarkDefined(LInfo.deathstate, ACTORDEF_ST_DEATH);
  MarkDefined(LInfo.xdeathstate, ACTORDEF_ST_XDEATH);
  MarkDefined(LInfo.raisestate, ACTORDEF_ST_RAISE);
  MarkDefined(LInfo.healstate, ACTORDEF_ST_HEAL);
  MarkDefined(LInfo.crashstate, ACTORDEF_ST_CRASH);
  MarkDefined(LInfo.crushstate, ACTORDEF_ST_CRUSH);
  MarkDefined(LInfo.interactstate, ACTORDEF_ST_INTERACT);
end;

function TEngineActorDefCatalog.NameOf(AIndex: Integer): string;
begin
  Result := Info_GetMobjName(AIndex);
end;

function TEngineActorDefCatalog.AddAlias(const AName, AOtherName: string): Boolean;
begin
  Result := Info_AddMobjNameAlias(AName, AOtherName);
end;

function TEngineActorDefCatalog.IndexOfToken(const AToken: string): Integer;
begin
  Result := statenames.IndexOfToken(AToken);
end;

procedure TEngineActorDefCatalog.Add(const AEntry: string);
begin
  statenames.Add(AEntry);
end;

end.
