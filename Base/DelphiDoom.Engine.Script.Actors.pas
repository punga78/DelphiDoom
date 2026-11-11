{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the mobjs for the actor functions of scripts           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
{$Q-}
{$R-}
// the squares of the distance between two far actors wrap on purpose (the old code did)
unit DelphiDoom.Engine.Script.Actors;

interface

uses
  p_mobj_h,
  DelphiDoom.Engine.Script.ActorContext.Intf,
  DelphiDoom.ScriptHost.Actors.Intf,
  DelphiDoom.ScriptHost.Actors.KeyList;

type
  /// <summary>
  ///   The mobjs for the scripts. The only class that reads and writes mobj_t for the actor
  ///   functions (they were in psi_game.pas); the library checks the number of a type and of a
  ///   state, so here nothing of the kind is checked, but a key that is no actor is: the methods
  ///   that read answer what they are told, the ones that write do nothing
  /// </summary>
  TEngineScriptActors = class(TInterfacedObject, IScriptActorSource)
  strict private
    FContext: IEngineScriptActorContext;
    function MobjOfKey(const AKey: Cardinal): Pmobj_t;
    function FlagWord(const AMobj: Pmobj_t; const AFlag: Cardinal; out AMask: Integer): System.PInteger;
  public
    /// <exception cref="EArgumentNilException">If the context is nil</exception>
    constructor Create(const AContext: IEngineScriptActorContext);
    /// <summary>Plays a sound (or a random list of sounds) by name from an origin (nil: no origin)</summary>
    class procedure PlaySoundAt(const AOrigin: Pointer; const AName: string); static;
    /// <summary>Adds the keys of the actors of the selection; the sectors outside of the level are ignored</summary>
    class procedure CollectKeys(const ASelection: TScriptActorSelection; const AArgument: Integer;
      const AKeys: TScriptActorKeyList); static;
    function KeyOf(const AKey: Cardinal): Cardinal;
    function GetNumber(const AKey: Cardinal; const AField: TScriptActorField;
      const ANotFound: Integer): Integer;
    function GetText(const AKey: Cardinal; const AField: TScriptActorText): string;
    function RelatedKey(const AKey: Cardinal; const ARelation: TScriptActorRelation): Cardinal;
    function CustomParam(const AKey: Cardinal; const AName: string): Integer;
    function CheckFlag(const AKey: Cardinal; const AFlag: Cardinal): Boolean;
    function Distance(const AKey1, AKey2: Cardinal; const AWithZ: Boolean): Integer;
    function PlayerNumber(const AKey: Cardinal): Integer;
    function MobjTypeCount: Integer;
    function MobjTypeFromName(const AName: string): Integer;
    function MobjTypeFromEditorNumber(const ANumber: Integer): Integer;
    function CheckSight(const AKey1, AKey2: Cardinal): Boolean;
    procedure Collect(const ASelection: TScriptActorSelection; const AArgument: Integer;
      const AKeys: TScriptActorKeyList);
    function Exists(const AKey: Cardinal): Boolean;
    procedure SetNumber(const AKey: Cardinal; const AField: TScriptActorField; const AValue: Integer);
    procedure SetText(const AKey: Cardinal; const AField: TScriptActorText; const AValue: string);
    procedure SetRelated(const AKey: Cardinal; const ARelation: TScriptActorRelation;
      const ATargetKey: Cardinal);
    procedure SetPosition(const AKey: Cardinal; const AX, AY, AZ: Integer);
    procedure SetCustomParam(const AKey: Cardinal; const AName: string; const AValue: Integer);
    procedure SetDefaultDropItem(const AKey: Cardinal);
    procedure SetFlag(const AKey: Cardinal; const AFlag: Cardinal; const AOn: Boolean);
    function StateCount: Integer;
    procedure SetState(const AKey: Cardinal; const AState: Integer);
    procedure PlayActorSound(const AKey: Cardinal; const AName: string);
    procedure PlayGlobalSound(const AName: string);
    function Spawn(const AX, AY, AZ: Integer; const AType: Integer): Cardinal;
    procedure Remove(const AKey: Cardinal);
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  d_player,
  d_think,
  doomdata,
  doomdef,
  g_game,
  info,
  info_common,
  info_h,
  m_fixed,
  m_rnd,
  p_common,
  p_inter,
  p_local,
  p_map,
  p_maputl,
  p_params,
  p_mobj,
  p_setup,
  p_sight,
  p_tick,
  r_defs,
  r_translations,
  DelphiDoom.Palette.TranslationBlood,
  DelphiDoom.ScriptHost.World.Intf,
  s_sound,
  sounds,
  tables;

{ TEngineScriptActors }

constructor TEngineScriptActors.Create(const AContext: IEngineScriptActorContext);
begin
  inherited Create;
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('AContext');
  FContext := AContext;
end;

function TEngineScriptActors.MobjOfKey(const AKey: Cardinal): Pmobj_t;
begin
  Result := FContext.MobjFromKey(AKey);
end;

class procedure TEngineScriptActors.PlaySoundAt(const AOrigin: Pointer; const AName: string);
var
  LName: string;
  LRandomList: TDNumberList;
  LSoundNumber: Integer;
begin
  LName := strupper(strtrim(AName));
  if (LName = '') or (LName = 'DS') then
    Exit;
  LSoundNumber := S_GetSoundNumForName(LName);
  LRandomList := S_GetRandomSoundList(LSoundNumber);
  if LRandomList <> nil then
    if LRandomList.Count > 0 then
      LSoundNumber := LRandomList[N_Random mod LRandomList.Count];
  S_StartSound(AOrigin, LSoundNumber);
end;

// where a flag of the scripts is kept: the numbers of the scripts are 32 for each word of flags
// of the mobj (the second word exists in Heretic and Hexen only). The old code had the sixth
// extra word twice for the last 32 flags (flags5_ex where a mobjinfo has flags6_ex): kept
function TEngineScriptActors.FlagWord(const AMobj: Pmobj_t; const AFlag: Cardinal;
  out AMask: Integer): System.PInteger;
begin
  Result := nil;
  AMask := 0;
  if AFlag < 32 then
  begin
    Result := @AMobj.flags;
    AMask := 1 shl AFlag;
  end
  else if AFlag < 64 then
  begin
{$IFDEF HERETIC_OR_HEXEN}
    Result := @AMobj.flags2;
    AMask := 1 shl (AFlag - 32);
{$ENDIF}
  end
  else if AFlag < 96 then
  begin
    Result := @AMobj.flags_ex;
    AMask := 1 shl (AFlag - 64);
  end
  else if AFlag < 128 then
  begin
    Result := @AMobj.flags2_ex;
    AMask := 1 shl (AFlag - 96);
  end
  else if AFlag < 160 then
  begin
    Result := @AMobj.flags3_ex;
    AMask := 1 shl (AFlag - 128);
  end
  else if AFlag < 192 then
  begin
    Result := @AMobj.flags4_ex;
    AMask := 1 shl (AFlag - 160);
  end
  else if AFlag < 224 then
  begin
    Result := @AMobj.flags5_ex;
    AMask := 1 shl (AFlag - 192);
  end
  else if AFlag < 256 then
  begin
    Result := @AMobj.flags5_ex;
    AMask := 1 shl (AFlag - 224);
  end;
end;

function TEngineScriptActors.KeyOf(const AKey: Cardinal): Cardinal;
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
    Result := SCRIPT_INVALID_ID
  else
    Result := LMobj.key;
end;

function TEngineScriptActors.Exists(const AKey: Cardinal): Boolean;
begin
  Result := MobjOfKey(AKey) <> nil;
end;

function TEngineScriptActors.GetNumber(const AKey: Cardinal; const AField: TScriptActorField;
  const ANotFound: Integer): Integer;
var
  LMobj: Pmobj_t;
  LX: Integer;
  LY: Integer;
  LZ: Integer;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
  begin
    Result := ANotFound;
    Exit;
  end;
  case AField of
    acfX: Result := LMobj.x;
    acfY: Result := LMobj.y;
    acfZ: Result := LMobj.z;
    acfMomX: Result := LMobj.momx;
    acfMomY: Result := LMobj.momy;
    acfMomZ: Result := LMobj.momz;
    acfFloorZ: Result := LMobj.floorz;
    acfCeilingZ: Result := LMobj.ceilingz;
    acfSpeed:
      begin
        LX := LMobj.momx;
        LY := LMobj.momy;
        LZ := LMobj.momz;
        Result := FixedSqrt(FixedMul(LX, LX) + FixedMul(LY, LY) + FixedMul(LZ, LZ));
      end;
    acfAngle: Result := Integer(LMobj.angle);
    acfHealth: Result := LMobj.health;
    acfMass: Result := LMobj.mass;
    acfHeight: Result := LMobj.height;
    acfScale: Result := LMobj.scale;
    acfPushFactor: Result := LMobj.pushfactor;
    acfGravity: Result := LMobj.gravity;
    acfSpecial: Result := LMobj.special;
    acfArg1: Result := LMobj.args[0];
    acfArg2: Result := LMobj.args[1];
    acfArg3: Result := LMobj.args[2];
    acfArg4: Result := LMobj.args[3];
    acfArg5: Result := LMobj.args[4];
    acfWeaveIndexXY: Result := LMobj.WeaveIndexXY;
    acfWeaveIndexZ: Result := LMobj.WeaveIndexZ;
    acfFriction: Result := LMobj.friction;
    acfPainChance: Result := LMobj.painchance;
    acfSpriteDX: Result := LMobj.spriteDX;
    acfSpriteDY: Result := LMobj.spriteDY;
    acfInfightingGroup: Result := LMobj.infighting_group;
    acfProjectileGroup: Result := LMobj.projectile_group;
    acfSplashGroup: Result := LMobj.splash_group;
    acfCustomDropItem: Result := LMobj.dropitem;
    acfSpawnHealth: Result := LMobj.info.spawnhealth;
    acfSector: Result := Psubsector_t(LMobj.subsector).sector.iSectorID;
    acfMobjType: Result := LMobj._type;
    acfEditorNumber: Result := LMobj.info.doomednum;
    acfState: Result := pDiff(LMobj.state, @states[0], SizeOf(state_t));
  else
    Result := ANotFound;
  end;
end;

procedure TEngineScriptActors.SetNumber(const AKey: Cardinal; const AField: TScriptActorField;
  const AValue: Integer);
var
  LMobj: Pmobj_t;
  LPlayer: Pplayer_t;
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LCurrentSpeed: Integer;
  LScale: Double;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
    Exit;
  case AField of
    acfX:
      begin
        P_UnsetThingPosition(LMobj);
        LMobj.x := AValue;
        P_SetThingPosition(LMobj);
      end;
    acfY:
      begin
        P_UnsetThingPosition(LMobj);
        LMobj.y := AValue;
        P_SetThingPosition(LMobj);
      end;
    acfZ: LMobj.z := AValue;
    acfMomX: LMobj.momx := AValue;
    acfMomY: LMobj.momy := AValue;
    acfMomZ: LMobj.momz := AValue;
    acfFloorZ: LMobj.floorz := AValue;
    acfCeilingZ: LMobj.ceilingz := AValue;
    acfSpeed:
      begin
        LX := LMobj.momx;
        LY := LMobj.momy;
        LZ := LMobj.momz;
        LCurrentSpeed := FixedSqrt(FixedMul(LX, LX) + FixedMul(LY, LY) + FixedMul(LZ, LZ));
        if LCurrentSpeed = 0 then
          Exit;
        LScale := AValue / LCurrentSpeed;
        LMobj.momx := Round(LX * LScale);
        LMobj.momy := Round(LY * LScale);
        LMobj.momz := Round(LZ * LScale);
      end;
    acfAngle: LMobj.angle := angle_t(AValue);
    acfHealth:
      if AValue <= 0 then
        P_DamageMobj(LMobj, nil, nil, 10000)
      else
      begin
        LMobj.health := AValue;
        LPlayer := LMobj.player;
        if LPlayer <> nil then
          LPlayer.health := AValue;
      end;
    acfMass: LMobj.mass := AValue;
    acfHeight: LMobj.height := AValue;
    acfScale: LMobj.scale := AValue;
    acfPushFactor: LMobj.pushfactor := AValue;
    acfGravity: LMobj.gravity := AValue;
    acfSpecial: LMobj.special := AValue;
    acfArg1: LMobj.args[0] := AValue;
    acfArg2: LMobj.args[1] := AValue;
    acfArg3: LMobj.args[2] := AValue;
    acfArg4: LMobj.args[3] := AValue;
    acfArg5: LMobj.args[4] := AValue;
    acfWeaveIndexXY: LMobj.WeaveIndexXY := AValue;
    acfWeaveIndexZ: LMobj.WeaveIndexZ := AValue;
    acfFriction: LMobj.friction := AValue;
    acfPainChance: LMobj.painchance := AValue;
    acfSpriteDX: LMobj.spriteDX := AValue;
    acfSpriteDY: LMobj.spriteDY := AValue;
    acfInfightingGroup: LMobj.infighting_group := AValue;
    acfProjectileGroup: LMobj.projectile_group := AValue;
    acfSplashGroup: LMobj.splash_group := AValue;
    acfCustomDropItem:
      begin
        LMobj.dropitem := AValue;
        LMobj.flags2_ex := LMobj.flags2_ex or MF2_EX_CUSTOMDROPITEM;
      end;
  end;
end;

function TEngineScriptActors.GetText(const AKey: Cardinal; const AField: TScriptActorText): string;
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
  begin
    Result := '';
    Exit;
  end;
  case AField of
    actTranslation: Result := string(LMobj.translationname);
    actBloodColor: Result := TTranslationBlood.NameOf(LMobj.bloodcolor);
    actName: Result := string(LMobj.info.name);
    actName2:
{$IFDEF STRIFE}
      Result := string(LMobj.info.name2);
{$ELSE}
      Result := '';
{$ENDIF}
    actSeeSound: Result := S_GetSoundNameForNum(LMobj.info.seesound);
    actAttackSound: Result := S_GetSoundNameForNum(LMobj.info.attacksound);
    actPainSound: Result := S_GetSoundNameForNum(LMobj.info.painsound);
    actDeathSound: Result := S_GetSoundNameForNum(LMobj.info.deathsound);
    actActiveSound: Result := S_GetSoundNameForNum(LMobj.info.activesound);
    actCustomSound1: Result := S_GetSoundNameForNum(LMobj.info.customsound1);
    actCustomSound2: Result := S_GetSoundNameForNum(LMobj.info.customsound2);
    actCustomSound3: Result := S_GetSoundNameForNum(LMobj.info.customsound3);
    actMeleeSound: Result := S_GetSoundNameForNum(LMobj.info.meleesound);
  else
    Result := '';
  end;
end;

procedure TEngineScriptActors.SetText(const AKey: Cardinal; const AField: TScriptActorText;
  const AValue: string);
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
    Exit;
  case AField of
    actTranslation:
      begin
        LMobj.translationname := ShortString(AValue);
        R_InitMobjTranslation(LMobj);
      end;
    actBloodColor: LMobj.bloodcolor := TTranslationBlood.IdForName(AValue);
  end;
end;

function TEngineScriptActors.RelatedKey(const AKey: Cardinal;
  const ARelation: TScriptActorRelation): Cardinal;
var
  LMobj: Pmobj_t;
  LRelated: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
  begin
    Result := SCRIPT_INVALID_ID;
    Exit;
  end;
  case ARelation of
    acrTarget: LRelated := P_ActorTarget(LMobj);
    acrTracer: LRelated := LMobj.tracer;
  else
    LRelated := LMobj.master;
  end;
  if LRelated <> nil then
    Result := LRelated.key
  else
    Result := SCRIPT_INVALID_ID;
end;

procedure TEngineScriptActors.SetRelated(const AKey: Cardinal; const ARelation: TScriptActorRelation;
  const ATargetKey: Cardinal);
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
    Exit;
  case ARelation of
    acrTarget: LMobj.target := MobjOfKey(ATargetKey);
    acrTracer: LMobj.tracer := MobjOfKey(ATargetKey);
  else
    LMobj.master := MobjOfKey(ATargetKey);
  end;
end;

procedure TEngineScriptActors.SetPosition(const AKey: Cardinal; const AX, AY, AZ: Integer);
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
    Exit;
  P_UnsetThingPosition(LMobj);
  LMobj.x := AX;
  LMobj.y := AY;
  LMobj.z := AZ;
  P_SetThingPosition(LMobj);
end;

function TEngineScriptActors.CustomParam(const AKey: Cardinal; const AName: string): Integer;
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
    Result := 0
  else
    Result := P_GetMobjCustomParamValue(LMobj, AName);
end;

procedure TEngineScriptActors.SetCustomParam(const AKey: Cardinal; const AName: string;
  const AValue: Integer);
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj <> nil then
    P_SetMobjCustomParam(LMobj, AName, AValue);
end;

procedure TEngineScriptActors.SetDefaultDropItem(const AKey: Cardinal);
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
    Exit;
  LMobj.dropitem := 0;
  LMobj.flags2_ex := LMobj.flags2_ex and not MF2_EX_CUSTOMDROPITEM;
end;

function TEngineScriptActors.CheckFlag(const AKey: Cardinal; const AFlag: Cardinal): Boolean;
var
  LMobj: Pmobj_t;
  LWord: System.PInteger;
  LMask: Integer;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
  begin
    Result := False;
    Exit;
  end;
  LWord := FlagWord(LMobj, AFlag, LMask);
  Result := (LWord <> nil) and (LWord^ and LMask <> 0);
end;

procedure TEngineScriptActors.SetFlag(const AKey: Cardinal; const AFlag: Cardinal; const AOn: Boolean);
var
  LMobj: Pmobj_t;
  LWord: System.PInteger;
  LMask: Integer;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
    Exit;
  LWord := FlagWord(LMobj, AFlag, LMask);
  if LWord = nil then
    Exit;
  if AOn then
    LWord^ := LWord^ or LMask
  else
    LWord^ := LWord^ and not LMask;
end;

function TEngineScriptActors.Distance(const AKey1, AKey2: Cardinal; const AWithZ: Boolean): Integer;
var
  LFirst: Pmobj_t;
  LSecond: Pmobj_t;
  LDX: fixed_t;
  LDY: fixed_t;
  LDZ: fixed_t;
begin
  LFirst := MobjOfKey(AKey1);
  if LFirst = nil then
  begin
    Result := 0;
    Exit;
  end;
  LSecond := MobjOfKey(AKey2);
  if LSecond = nil then
  begin
    Result := 0;
    Exit;
  end;
  // the squares are 32 bit integers: far actors wrap, as they always did
  LDX := LFirst.x - LSecond.x;
  LDY := LFirst.y - LSecond.y;
  if AWithZ then
  begin
    LDZ := LFirst.z - LSecond.z;
    Result := FixedSqrt(LDX * LDX + LDY * LDY + LDZ * LDZ);
  end
  else
    Result := FixedSqrt(LDX * LDX + LDY * LDY);
end;

function TEngineScriptActors.PlayerNumber(const AKey: Cardinal): Integer;
var
  LMobj: Pmobj_t;
begin
  Result := -1;
  LMobj := MobjOfKey(AKey);
  if LMobj = nil then
    Exit;
  if LMobj.player = nil then
    Exit;
  Result := pDiff(LMobj.player, @players[0], SizeOf(player_t));
  if (Result < 0) or (Result >= doomdef.MAXPLAYERS) then
    Result := -1
  else if not playeringame[Result] then
    Result := -1;
end;

function TEngineScriptActors.MobjTypeCount: Integer;
begin
  Result := nummobjtypes;
end;

function TEngineScriptActors.MobjTypeFromName(const AName: string): Integer;
begin
  Result := Info_GetMobjNumForName(AName);
end;

function TEngineScriptActors.MobjTypeFromEditorNumber(const ANumber: Integer): Integer;
begin
  Result := Info_GetMobjNumForDoomNum(ANumber);
end;

function TEngineScriptActors.CheckSight(const AKey1, AKey2: Cardinal): Boolean;
begin
  Result := P_CheckSight(MobjOfKey(AKey1), MobjOfKey(AKey2));
end;

class procedure TEngineScriptActors.CollectKeys(const ASelection: TScriptActorSelection;
  const AArgument: Integer; const AKeys: TScriptActorKeyList);
var
  LThinker: Pthinker_t;
  LMobj: Pmobj_t;
  LInfo: Pmobjinfo_t;
  LSector: Integer;

  // a mobj that is not a player (the four player starts of Heretic have editor numbers above MAXPLAYERS)
  function IsNotPlayer(const AInfo: Pmobjinfo_t): Boolean;
  begin
    Result := (AInfo.doomednum > doomdef.MAXPLAYERS)
{$IFDEF HERETIC}
      and (AInfo.doomednum <> 9100) and (AInfo.doomednum <> 9101) and
      (AInfo.doomednum <> 9102) and (AInfo.doomednum <> 9103)
{$ENDIF}
      ;
  end;

  // shootable and either counted as a kill or able to attack
  function IsMonster(const AInfo: Pmobjinfo_t): Boolean;
  begin
    Result := IsNotPlayer(AInfo) and (AInfo.flags and MF_SHOOTABLE <> 0) and
      ((AInfo.flags and MF_COUNTKILL <> 0) or (AInfo.missilestate <> 0) or (AInfo.meleestate <> 0));
  end;

  procedure AddSector(const AIndex: Integer);
  var
    LThing: Pmobj_t;
  begin
    if (AIndex < 0) or (AIndex >= numsectors) then
      Exit;
    LThing := sectors[AIndex].thinglist;
    while LThing <> nil do
    begin
      AKeys.Add(LThing.key);
      LThing := LThing.snext;
    end;
  end;

begin
  case ASelection of
    acsSector:
      AddSector(AArgument);
    acsSectorTag:
      for LSector := 0 to numsectors - 1 do
        if sectors[LSector].tag = AArgument then
          AddSector(LSector);
  else
    LThinker := thinkercap.next;
    while Pointer(LThinker) <> Pointer(@thinkercap) do
    begin
      if @LThinker._function.acp1 = @P_MobjThinker then
      begin
        LMobj := Pmobj_t(LThinker);
        LInfo := LMobj.info;
        case ASelection of
          acsAll:
            AKeys.Add(LMobj.key);
          acsMonstersAlive:
            if (LMobj.health > 0) and IsMonster(LInfo) then
              AKeys.Add(LMobj.key);
          acsMonstersDead:
            if (LMobj.health <= 0) and IsMonster(LInfo) then
              AKeys.Add(LMobj.key);
          acsMonsters:
            if IsMonster(LInfo) then
              AKeys.Add(LMobj.key);
          acsMissiles:
            if IsNotPlayer(LInfo) and (LInfo.flags and MF_MISSILE <> 0) then
              AKeys.Add(LMobj.key);
          acsEditorNumber:
            if LInfo.doomednum = AArgument then
              AKeys.Add(LMobj.key);
          acsType:
            if LMobj._type = AArgument then
              AKeys.Add(LMobj.key);
        end;
      end;
      LThinker := LThinker.next;
    end;
  end;
end;

procedure TEngineScriptActors.Collect(const ASelection: TScriptActorSelection;
  const AArgument: Integer; const AKeys: TScriptActorKeyList);
begin
  CollectKeys(ASelection, AArgument, AKeys);
end;

function TEngineScriptActors.StateCount: Integer;
begin
  Result := numstates;
end;

procedure TEngineScriptActors.SetState(const AKey: Cardinal; const AState: Integer);
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj <> nil then
    P_SetMobjState(LMobj, statenum_t(AState));
end;

procedure TEngineScriptActors.PlayActorSound(const AKey: Cardinal; const AName: string);
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj <> nil then
    PlaySoundAt(LMobj, AName);
end;

procedure TEngineScriptActors.PlayGlobalSound(const AName: string);
begin
  PlaySoundAt(nil, AName);
end;

function TEngineScriptActors.Spawn(const AX, AY, AZ: Integer; const AType: Integer): Cardinal;
var
  LMobj: Pmobj_t;
begin
  LMobj := P_SpawnMobj(AX, AY, AZ, AType);
  if LMobj <> nil then
    Result := LMobj.key
  else
    Result := SCRIPT_INVALID_ID;
end;

procedure TEngineScriptActors.Remove(const AKey: Cardinal);
var
  LMobj: Pmobj_t;
begin
  LMobj := MobjOfKey(AKey);
  if LMobj <> nil then
    P_RemoveMobj(LMobj);
end;

end.
