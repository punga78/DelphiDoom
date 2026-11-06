{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the ACTOR definitions                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.ActorReader;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Scanner, DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.Intf, DelphiDoom.ActorDef.StateOwner, DelphiDoom.ActorDef.StateReader,
  DelphiDoom.ActorDef.FlagReader;

type
  /// <summary>
  ///   Reads an ACTOR: the name, what it inherits from or replaces, the number, the
  ///   properties, the flags and the states. The values of the actor that it inherits from come
  ///   from the catalog of the actors of the engine
  /// </summary>
  TActorDefActorReader = class
  private
    FScanner: TScriptScanner;
    FLog: ILog;
    FProfile: TActorDefProfile;
    FFlags: TActorDefFlagReader;
    FNames: IActorDefNameCatalog;
    FActors: IActorDefActorCatalog;
    FStates: TActorDefStateReader;
    FSink: IActorDefDefinitionSink;
    FOwner: IActorDefStateOwner;
    FActor: TActorDefActor;
    FPending: Boolean;
    procedure Warn(const AMessage: string);
    procedure InitActor;
    procedure CopyFromBase(const ABase: TActorDefActor);
    function IsDefinitionKeyword(const AToken: string): Boolean;
    procedure ReadInteger(var AField: Integer);
    procedure ReadString(var AField: string);
    procedure ReadFixed(var AField: Integer);
    procedure ReadFloat(var AField: Single);
    procedure ReadScaledFloat(var AField: Single; ALimit: Single);
    procedure AddImpactFlags;
    function ReadFlag: Boolean;
    function ReadReplaces: Boolean;
    procedure ReadStates;
  public
    constructor Create(AScanner: TScriptScanner; const ALog: ILog; const AProfile: TActorDefProfile;
      AFlags: TActorDefFlagReader; const ANames: IActorDefNameCatalog;
      const AActors: IActorDefActorCatalog; AStates: TActorDefStateReader;
      const ASink: IActorDefDefinitionSink);
    /// <summary>
    ///   ACTOR is the current word. False if the text ended while reading the head of the actor:
    ///   nothing else can be read
    /// </summary>
    function Read: Boolean;
    /// <summary>The actor is over: it goes to the sink (nothing happens if there is none)</summary>
    procedure Submit;
    property Pending: Boolean read FPending;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings, DelphiDoom.ActorDef.Text, DelphiDoom.ActorDef.ActorStateOwner;

{ TActorDefActorReader }

constructor TActorDefActorReader.Create(AScanner: TScriptScanner; const ALog: ILog;
  const AProfile: TActorDefProfile; AFlags: TActorDefFlagReader; const ANames: IActorDefNameCatalog;
  const AActors: IActorDefActorCatalog; AStates: TActorDefStateReader;
  const ASink: IActorDefDefinitionSink);
begin
  inherited Create;
  FScanner := AScanner;
  FLog := ALog;
  FProfile := AProfile;
  FFlags := AFlags;
  FNames := ANames;
  FActors := AActors;
  FStates := AStates;
  FSink := ASink;
  FOwner := TActorDefActorStateOwner.Create(@FActor);
end;

procedure TActorDefActorReader.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

function TActorDefActorReader.IsDefinitionKeyword(const AToken: string): Boolean;
begin
  Result := (AToken = 'ACTOR') or
    (AToken = 'WEAPON') or
    (AToken = 'ACTORALIAS') or
    (AToken = 'DEH_PARSE') or
    (AToken = 'DEH_PARSE_ALL') or
    (AToken = 'COMPILED') or
    (AToken = 'PRECOMPILED') or
    (AToken = 'EXTERNAL') or
    (AToken = 'SCRIPT') or
    (AToken = 'THINKER') or
    (AToken = 'GLOBAL');
end;

procedure TActorDefActorReader.InitActor;
begin
  FActor := Default(TActorDefActor);
  FActor.SpawnState := -1;
  FActor.SeeState := -1;
  FActor.PainState := -1;
  FActor.MeleeState := -1;
  FActor.MissileState := -1;
  FActor.DeathState := -1;
  FActor.XDeathState := -1;
  FActor.RaiseState := -1;
  FActor.HealState := -1;
  FActor.CrashState := -1;
  FActor.CrushState := -1;
  FActor.InteractState := -1;
  FActor.Scale := 1.0;
  FActor.PushFactor := 0.25; // the default push factor of the engine
  FActor.Friction := 0.90625; // the original friction
  FActor.Gravity := 1.0;
  FActor.ReplacesId := -1;
end;

procedure TActorDefActorReader.CopyFromBase(const ABase: TActorDefActor);
begin
  FActor.SpawnHealth := ABase.SpawnHealth;
  FActor.SeeSound := ABase.SeeSound;
  FActor.ReactionTime := ABase.ReactionTime;
  FActor.AttackSound := ABase.AttackSound;
  FActor.PainChance := ABase.PainChance;
  FActor.PainSound := ABase.PainSound;
  FActor.DeathSound := ABase.DeathSound;
  FActor.Speed := ABase.Speed;
  FActor.Radius := ABase.Radius;
  FActor.Height := ABase.Height;
  FActor.Mass := ABase.Mass;
  FActor.Damage := ABase.Damage;
  FActor.ActiveSound := ABase.ActiveSound;
  FActor.Flags := FActor.Flags + ABase.Flags;
  if FProfile.HasFlags2 then
    FActor.Flags2 := FActor.Flags2 + ABase.Flags2;
  FActor.FlagsEx := FActor.FlagsEx + ABase.FlagsEx;
  FActor.Flags2Ex := FActor.Flags2Ex + ABase.Flags2Ex;
  FActor.Flags3Ex := FActor.Flags3Ex + ABase.Flags3Ex;
  FActor.Flags4Ex := FActor.Flags4Ex + ABase.Flags4Ex;
  FActor.Flags5Ex := FActor.Flags5Ex + ABase.Flags5Ex;
  FActor.Flags6Ex := FActor.Flags6Ex + ABase.Flags6Ex;
  FActor.CustomSound1 := ABase.CustomSound1;
  FActor.CustomSound2 := ABase.CustomSound2;
  FActor.CustomSound3 := ABase.CustomSound3;
  FActor.DropItem := ABase.DropItem;
  FActor.MissileType := ABase.MissileType;
  FActor.ExplosionDamage := ABase.ExplosionDamage;
  FActor.ExplosionRadius := ABase.ExplosionRadius;
  FActor.MeleeDamage := ABase.MeleeDamage;
  FActor.MeleeSound := ABase.MeleeSound;
  FActor.RenderStyle := ABase.RenderStyle;
  FActor.Alpha := ABase.Alpha;
  FActor.MissileHeight := ABase.MissileHeight;
  FActor.MeleeThreshold := ABase.MeleeThreshold;
  FActor.VSpeed := ABase.VSpeed;
  FActor.PushFactor := ABase.PushFactor;
  FActor.Scale := ABase.Scale;
  FActor.Gravity := ABase.Gravity;
  FActor.MinMissileChance := ABase.MinMissileChance;
  FActor.FloatSpeed := ABase.FloatSpeed;
  FActor.NormalSpeed := ABase.NormalSpeed;
  FActor.FastSpeed := ABase.FastSpeed;
  FActor.Obituary := ABase.Obituary;
  FActor.HitObituary := ABase.HitObituary;
  FActor.Gender := ABase.Gender;
  FActor.MeleeRange := ABase.MeleeRange;
  FActor.MaxStepHeight := ABase.MaxStepHeight;
  FActor.MaxDropoffHeight := ABase.MaxDropoffHeight;
  FActor.GibHealth := ABase.GibHealth;
  FActor.MaxTargetRange := ABase.MaxTargetRange;
  FActor.WeaveIndexXY := ABase.WeaveIndexXY;
  FActor.WeaveIndexZ := ABase.WeaveIndexZ;
  FActor.SpriteDX := ABase.SpriteDX;
  FActor.SpriteDY := ABase.SpriteDY;
  FActor.RipSound := ABase.RipSound;
  FActor.BloodColor := ABase.BloodColor;
  FActor.Translation := ABase.Translation;

  FActor.SpawnState := ABase.SpawnState;
  FActor.SeeState := ABase.SeeState;
  FActor.PainState := ABase.PainState;
  FActor.MeleeState := ABase.MeleeState;
  FActor.MissileState := ABase.MissileState;
  FActor.DeathState := ABase.DeathState;
  FActor.XDeathState := ABase.XDeathState;
  FActor.RaiseState := ABase.RaiseState;
  FActor.HealState := ABase.HealState;
  FActor.CrashState := ABase.CrashState;
  FActor.CrushState := ABase.CrushState;
  FActor.InteractState := ABase.InteractState;
  // the state 0 of the engine (the marker itself) is the null state: not a label
  if FActor.SpawnState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_SPAWN;
  if FActor.SeeState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_SEE;
  if FActor.MeleeState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_MELEE;
  if FActor.MissileState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_MISSILE;
  if FActor.PainState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_PAIN;
  if FActor.DeathState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_DEATH;
  if FActor.XDeathState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_XDEATH;
  if FActor.RaiseState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_RAISE;
  if FActor.HealState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_HEAL;
  if FActor.CrashState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_CRASH;
  if FActor.CrushState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_CRUSH;
  if FActor.InteractState > ACTORDEF_ORIGINAL_STATE_MARKER then
    FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_INTERACT;
end;

procedure TActorDefActorReader.ReadInteger(var AField: Integer);
begin
  FScanner.GetInteger;
  AField := FScanner.AsInteger;
  FScanner.GetString;
end;

procedure TActorDefActorReader.ReadString(var AField: string);
begin
  FScanner.GetString;
  AField := FScanner.AsString;
  FScanner.GetString;
end;

procedure TActorDefActorReader.ReadFixed(var AField: Integer);
begin
  FScanner.GetFloat;
  AField := Round(FScanner.AsFloat * ACTORDEF_FRACUNIT);
  FScanner.GetString;
end;

procedure TActorDefActorReader.ReadFloat(var AField: Single);
begin
  FScanner.GetFloat;
  AField := FScanner.AsFloat;
  FScanner.GetString;
end;

procedure TActorDefActorReader.ReadScaledFloat(var AField: Single; ALimit: Single);
begin
  FScanner.GetFloat;
  AField := FScanner.AsFloat;
  // a value in fixed point is scaled back
  if Abs(AField) > ALimit then
    AField := AField / ACTORDEF_FRACUNIT;
  FScanner.GetString;
end;

procedure TActorDefActorReader.AddImpactFlags;
begin
  if FProfile.KeywordsUseFlags2 then
    FActor.Flags2 := FActor.Flags2 + 'MF2_IMPACT MF2_PCROSS '
  else
    FActor.Flags5Ex := FActor.Flags5Ex + 'MF5_EX_IMPACT MF5_EX_PCROSS ';
end;

function TActorDefActorReader.ReadFlag: Boolean;
var
  LCategory: TActorDefFlagCategory;
begin
  Result := True;
  for LCategory := TActorDefFlagCategory.Flags to TActorDefFlagCategory.Flags6Ex do
  begin
    if (LCategory = TActorDefFlagCategory.Flags2) and not FProfile.HasFlags2 then
      Continue;
    case LCategory of
      TActorDefFlagCategory.Flags:
        if FFlags.TryAdd(LCategory, FActor.Flags) then Exit;
      TActorDefFlagCategory.Flags2:
        if FFlags.TryAdd(LCategory, FActor.Flags2) then Exit;
      TActorDefFlagCategory.FlagsEx:
        if FFlags.TryAdd(LCategory, FActor.FlagsEx) then Exit;
      TActorDefFlagCategory.Flags2Ex:
        if FFlags.TryAdd(LCategory, FActor.Flags2Ex) then Exit;
      TActorDefFlagCategory.Flags3Ex:
        if FFlags.TryAdd(LCategory, FActor.Flags3Ex) then Exit;
      TActorDefFlagCategory.Flags4Ex:
        if FFlags.TryAdd(LCategory, FActor.Flags4Ex) then Exit;
      TActorDefFlagCategory.Flags5Ex:
        if FFlags.TryAdd(LCategory, FActor.Flags5Ex) then Exit;
      TActorDefFlagCategory.Flags6Ex:
        if FFlags.TryAdd(LCategory, FActor.Flags6Ex) then Exit;
    end;
  end;
  for LCategory := TActorDefFlagCategory.Flags to TActorDefFlagCategory.Flags6Ex do
  begin
    if (LCategory = TActorDefFlagCategory.Flags2) and not FProfile.HasFlags2 then
      Continue;
    case LCategory of
      TActorDefFlagCategory.Flags:
        if FFlags.TryRemove(LCategory, FActor.Flags) then Exit;
      TActorDefFlagCategory.Flags2:
        if FFlags.TryRemove(LCategory, FActor.Flags2) then Exit;
      TActorDefFlagCategory.FlagsEx:
        if FFlags.TryRemove(LCategory, FActor.FlagsEx) then Exit;
      TActorDefFlagCategory.Flags2Ex:
        if FFlags.TryRemove(LCategory, FActor.Flags2Ex) then Exit;
      TActorDefFlagCategory.Flags3Ex:
        if FFlags.TryRemove(LCategory, FActor.Flags3Ex) then Exit;
      TActorDefFlagCategory.Flags4Ex:
        if FFlags.TryRemove(LCategory, FActor.Flags4Ex) then Exit;
      TActorDefFlagCategory.Flags5Ex:
        if FFlags.TryRemove(LCategory, FActor.Flags5Ex) then Exit;
      TActorDefFlagCategory.Flags6Ex:
        if FFlags.TryRemove(LCategory, FActor.Flags6Ex) then Exit;
    end;
  end;
  Result := False;
end;

function TActorDefActorReader.ReadReplaces: Boolean;
var
  LIndex: Integer;
  LOther: TActorDefActor;
begin
  Result := True;
  if not FScanner.GetString then
    Exit(False);
  if FActors.Find(FScanner.AsString, LIndex, LOther) then
  begin
    if (FActor.DoomedNum > 0) and (LOther.DoomedNum <> FActor.DoomedNum) then
      Warn(Format('SC_ActordefToDEH(): Replaces keyword found but points to a new doomednum %d, old doomednum=%d',
        [LOther.DoomedNum, FActor.DoomedNum]))
    else
    begin
      FActor.DoomedNum := LOther.DoomedNum;
      FActor.ReplacesId := LIndex;
    end;
  end
  else
    Warn(Format('SC_ActordefToDEH(): Replaces keyword points to an unknown mobj %s'#13#10,
      [FScanner.AsString]));
  FScanner.GetString;
end;

function TActorDefActorReader.Read: Boolean;
var
  LToken: string;
  LIsReplace: Boolean;
  LIsInherit: Boolean;
  LIndex: Integer;
  LBase: TActorDefActor;
  LFoundStates: Boolean;
  LText: string;
begin
  Result := True;
  FPending := True;
  InitActor;
  FScanner.GetString;
  FActor.Name := FScanner.AsString;
  LIsReplace := False;
  if Pos(':', FActor.Name) = Length(FActor.Name) then
  begin
    if FActor.Name <> '' then
      SetLength(FActor.Name, Length(FActor.Name) - 1);
    FScanner.GetString;
    FActor.InheritsFrom := FScanner.AsString;
    LIsInherit := True;
  end
  else
  begin
    if not FScanner.GetString then
      Exit(False);

    LIsInherit := FScanner.MatchString(':') or FScanner.MatchString('inherits') or
      FScanner.MatchString('inheritsfrom');
    LIsReplace := FScanner.MatchString('replaces');

    if LIsReplace or LIsInherit then
    begin
      if not FScanner.GetString then
        Exit(False);
      FActor.InheritsFrom := FScanner.AsString;
    end;
  end;

  if FActor.InheritsFrom <> '' then
  begin
    if FActors.Find(FActor.InheritsFrom, LIndex, LBase) then
    begin
      if LIsReplace then
      begin
        FActor.DoomedNum := LBase.DoomedNum;
        FActor.ReplacesId := LIndex;
      end;
      CopyFromBase(LBase);
    end;

    if not FScanner.GetString then
      Exit(False);
  end;

  if FScanner.NewLine then
  begin
    if LIsInherit then
      FActor.DoomedNum := -1;
  end
  else
  begin
    if TActorDefText.IsInteger(FScanner.AsString) then
    begin
      FActor.DoomedNum := TScannerStrings.ToInteger(FScanner.AsString);
      if not FScanner.GetString then
        Exit(False);
    end;
  end;

  LFoundStates := False;
  repeat
    LToken := TScannerStrings.UpperAscii(FScanner.AsString);
    if FProfile.HasStrifeName and ((LToken = 'NAME') or (LToken = 'STRIFENAME')) then
    begin
      FScanner.GetString;
      FActor.Name2 := FScanner.AsString;
      FScanner.GetString;
    end
    else if LToken = 'HEALTH' then
      ReadInteger(FActor.SpawnHealth)
    // when "inherits" is after the first line of the actor the properties are not copied
    else if (LToken = 'INHERITS') or (LToken = 'INHERITSFROM') then
    begin
      if not FScanner.GetString then
        Break;
      FActor.InheritsFrom := FScanner.AsString;
    end
    else if LToken = 'REPLACES' then
    begin
      if not ReadReplaces then
        Break;
    end
    else if (LToken = 'MONSTER') or (LToken = '+MONSTER') then
    begin
      FActor.Flags := FActor.Flags + 'MF_SOLID MF_SHOOTABLE MF_COUNTKILL ';
      if FProfile.KeywordsUseFlags2 then
        FActor.Flags2 := FActor.Flags2 + 'MF2_PUSHWALL MF2_MCROSS '
      else
        FActor.Flags5Ex := FActor.Flags5Ex + 'MF5_EX_PUSHWALL MF5_EX_MCROSS ';
      FScanner.GetString;
    end
    else if (LToken = 'PROJECTILE') or (LToken = '+PROJECTILE') then
    begin
      FActor.Flags := FActor.Flags + 'MF_NOGRAVITY MF_DROPOFF MF_MISSILE ';
      AddImpactFlags;
      FScanner.GetString;
    end
    else if LToken = 'RENDERSTYLE' then
    begin
      FScanner.GetString;
      FActor.RenderStyle := FNames.RenderStyleToken(FScanner.AsString);
      FScanner.GetString;
    end
    else if LToken = 'GENDER' then
    begin
      FScanner.GetString;
      FActor.Gender := FNames.GenderName(FScanner.AsString);
      FScanner.GetString;
    end
    else if LToken = 'MELEERANGE' then
      ReadInteger(FActor.MeleeRange)
    else if LToken = 'MAXSTEPHEIGHT' then
      ReadFixed(FActor.MaxStepHeight)
    else if LToken = 'MAXDROPOFFHEIGHT' then
      ReadFixed(FActor.MaxDropoffHeight)
    else if LToken = 'GIBHEALTH' then
      ReadInteger(FActor.GibHealth)
    else if LToken = 'MAXTARGETRANGE' then
      ReadInteger(FActor.MaxTargetRange)
    else if LToken = 'WEAVEINDEXXY' then
      ReadInteger(FActor.WeaveIndexXY)
    else if LToken = 'WEAVEINDEXZ' then
      ReadInteger(FActor.WeaveIndexZ)
    else if LToken = 'SPRITEDX' then
      ReadScaledFloat(FActor.SpriteDX, 256)
    else if LToken = 'SPRITEDY' then
      ReadScaledFloat(FActor.SpriteDY, 256)
    else if LToken = 'BLOODCOLOR' then
      ReadString(FActor.BloodColor)
    else if LToken = 'TRANSLATION' then
      ReadString(FActor.Translation)
    else if LToken = 'ALPHA' then
      ReadFixed(FActor.Alpha)
    else if ReadFlag then
      FScanner.GetString
    else if (LToken = 'DEFAULTMISSILE') or (LToken = '+DEFAULTMISSILE') then // DelphiDoom specific
    begin
      FActor.Flags := FActor.Flags + 'NOGRAVITY MISSILE NOBLOCKMAP DROPOFF ';
      AddImpactFlags;
      FScanner.GetString;
    end
    else if (LToken = 'DEFAULTTRANSPARENT') or (LToken = '+DEFAULTTRANSPARENT') then // DelphiDoom specific
    begin
      FActor.RenderStyle := 'TRANSLUCENT';
      FActor.Alpha := Round(0.67 * ACTORDEF_FRACUNIT);
      FScanner.GetString;
    end
    else if (LToken = 'DEFAULTADDITIVE') or (LToken = '+DEFAULTADDITIVE') then // DelphiDoom specific
    begin
      FActor.RenderStyle := 'ADD';
      FActor.Alpha := Round(0.67 * ACTORDEF_FRACUNIT);
      FScanner.GetString;
    end
    else if (LToken = 'FULLVOLSOUND') or (LToken = 'FULLVOLSOUNDS') or
      (LToken = '+FULLVOLSOUND') or (LToken = '+FULLVOLSOUNDS') then
    begin
      FActor.Flags2Ex := FActor.Flags2Ex + 'FULLVOLDEATH FULLVOLSEE ';
      FScanner.GetString;
    end
    else if (LToken = 'RADIUS') or (LToken = 'WIDTH') then // width is DelphiDoom specific
      ReadInteger(FActor.Radius)
    else if LToken = 'HEIGHT' then
      ReadInteger(FActor.Height)
    else if LToken = 'VSPEED' then
      ReadFloat(FActor.VSpeed)
    else if LToken = 'MINMISSILECHANCE' then
      ReadInteger(FActor.MinMissileChance)
    // the normal values of the push factor, the friction, the scale and the gravity are 0..1 in
    // an ACTORDEF lump and 0..FRACUNIT in the tables of the engine: a big value is in fixed point
    else if LToken = 'PUSHFACTOR' then
      ReadScaledFloat(FActor.PushFactor, 64)
    else if LToken = 'FRICTION' then
      ReadScaledFloat(FActor.Friction, 64)
    else if LToken = 'SCALE' then
      ReadScaledFloat(FActor.Scale, 64)
    else if LToken = 'GRAVITY' then
      ReadScaledFloat(FActor.Gravity, 64)
    else if LToken = 'SPEED' then
      ReadInteger(FActor.Speed)
    else if LToken = 'DAMAGE' then
      ReadInteger(FActor.Damage)
    else if LToken = 'PAINCHANCE' then
      ReadInteger(FActor.PainChance)
    else if LToken = 'MASS' then
      ReadInteger(FActor.Mass)
    else if LToken = 'REACTIONTIME' then
      ReadInteger(FActor.ReactionTime)
    else if LToken = 'DROPITEM' then
      ReadString(FActor.DropItem)
    else if LToken = 'MISSILETYPE' then
      ReadString(FActor.MissileType)
    else if LToken = 'EXPLOSIONDAMAGE' then
      ReadInteger(FActor.ExplosionDamage)
    else if LToken = 'EXPLOSIONRADIUS' then
      ReadInteger(FActor.ExplosionRadius)
    else if LToken = 'MELEEDAMAGE' then
      ReadInteger(FActor.MeleeDamage)
    else if LToken = 'SEESOUND' then
      ReadString(FActor.SeeSound)
    else if LToken = 'ATTACKSOUND' then
      ReadString(FActor.AttackSound)
    else if LToken = 'PAINSOUND' then
      ReadString(FActor.PainSound)
    else if LToken = 'DEATHSOUND' then
      ReadString(FActor.DeathSound)
    else if LToken = 'ACTIVESOUND' then
      ReadString(FActor.ActiveSound)
    else if LToken = 'CUSTOMSOUND1' then
      ReadString(FActor.CustomSound1)
    else if LToken = 'CUSTOMSOUND2' then
      ReadString(FActor.CustomSound2)
    else if LToken = 'CUSTOMSOUND3' then
      ReadString(FActor.CustomSound3)
    else if LToken = 'RIPSOUND' then
      ReadString(FActor.RipSound)
    else if LToken = 'MELEESOUND' then
      ReadString(FActor.MeleeSound)
    else if LToken = 'FLOATSPEED' then
      ReadInteger(FActor.FloatSpeed)
    else if LToken = 'NORMALSPEED' then
      ReadInteger(FActor.NormalSpeed)
    else if LToken = 'FASTSPEED' then
      // the old code kept the value in the normal speed: kept
      ReadInteger(FActor.NormalSpeed)
    else if LToken = 'OBITUARY' then
      ReadString(FActor.Obituary)
    else if LToken = 'HITOBITUARY' then
      ReadString(FActor.HitObituary)
    else if LToken = 'MISSILEHEIGHT' then
      ReadInteger(FActor.MissileHeight)
    else if LToken = 'MELEETHRESHOLD' then
      ReadInteger(FActor.MeleeThreshold)
    else if LToken = 'STATES' then
      LFoundStates := True
    else
    begin
      if IsDefinitionKeyword(LToken) then
      begin
        FScanner.UnGet;
        Break;
      end
      else
      begin
        if FActor.Name <> '' then
          LText := ' while parsing mobj "' + FActor.Name + '"'
        else
          LText := '';
        if FActor.DoomedNum > -1 then
          LText := LText + ' (doomednum=' + IntToStr(FActor.DoomedNum) + ')';
        Warn(Format('SC_ActordefToDEH(): Unknown token "%s" found%s'#13#10,
          [FScanner.AsString, LText]));
        FScanner.GetString;
      end;
    end;
  until LFoundStates or FScanner.Finished;

  if TScannerStrings.Trim(FActor.Flags) = '' then
    FActor.Flags := '0';
  if FProfile.HasFlags2 then
    if TScannerStrings.Trim(FActor.Flags2) = '' then
      FActor.Flags2 := '0';
  if TScannerStrings.Trim(FActor.FlagsEx) = '' then
    FActor.FlagsEx := '0';
  if TScannerStrings.Trim(FActor.Flags2Ex) = '' then
    FActor.Flags2Ex := '0';
  if TScannerStrings.Trim(FActor.Flags3Ex) = '' then
    FActor.Flags3Ex := '0';
  if TScannerStrings.Trim(FActor.Flags4Ex) = '' then
    FActor.Flags4Ex := '0';
  if TScannerStrings.Trim(FActor.Flags5Ex) = '' then
    FActor.Flags5Ex := '0';
  if TScannerStrings.Trim(FActor.Flags6Ex) = '' then
    FActor.Flags6Ex := '0';

  ReadStates;
end;

procedure TActorDefActorReader.ReadStates;
var
  LToken: string;
begin
  FStates.Start(FOwner);
  while FScanner.GetString do
  begin
    LToken := TScannerStrings.UpperAscii(FScanner.AsString);
    if IsDefinitionKeyword(LToken) then
    begin
      FScanner.UnGet;
      Break;
    end;
    if FScanner.MatchString('spawn:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_SPAWN;
      FActor.SpawnState := FStates.Count;
      repeat until not FStates.Read(FActor.SpawnState);
    end
    else if FScanner.MatchString('see:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_SEE;
      FActor.SeeState := FStates.Count;
      repeat until not FStates.Read(FActor.SeeState);
    end
    else if FScanner.MatchString('heal:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_HEAL;
      FActor.HealState := FStates.Count;
      repeat until not FStates.Read(FActor.HealState);
    end
    else if FScanner.MatchString('crash:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_CRASH;
      FActor.CrashState := FStates.Count;
      repeat until not FStates.Read(FActor.CrashState);
    end
    else if FScanner.MatchString('crush:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_CRUSH;
      FActor.CrushState := FStates.Count;
      repeat until not FStates.Read(FActor.CrushState);
    end
    else if FScanner.MatchString('interact:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_INTERACT;
      FActor.InteractState := FStates.Count;
      repeat until not FStates.Read(FActor.InteractState);
    end
    else if FScanner.MatchString('melee:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_MELEE;
      FActor.MeleeState := FStates.Count;
      repeat until not FStates.Read(FActor.MeleeState);
    end
    else if FScanner.MatchString('missile:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_MISSILE;
      FActor.MissileState := FStates.Count;
      repeat until not FStates.Read(FActor.MissileState);
    end
    else if FScanner.MatchString('pain:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_PAIN;
      FActor.PainState := FStates.Count;
      repeat until not FStates.Read(FActor.PainState);
    end
    else if FScanner.MatchString('death:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_DEATH;
      FActor.DeathState := FStates.Count;
      repeat until not FStates.Read(FActor.DeathState);
    end
    else if FScanner.MatchString('xdeath:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_XDEATH;
      FActor.XDeathState := FStates.Count;
      repeat until not FStates.Read(FActor.XDeathState);
    end
    else if FScanner.MatchString('raise:') then
    begin
      FActor.StatesDefined := FActor.StatesDefined or ACTORDEF_ST_RAISE;
      FActor.RaiseState := FStates.Count;
      repeat until not FStates.Read(FActor.RaiseState);
    end;
  end;
end;

procedure TActorDefActorReader.Submit;
begin
  if not FPending then
    Exit;
  FPending := False;
  FStates.CloseLastState;
  FActor.States := FStates.States;
  if Assigned(FSink) then
    FSink.SubmitActor(FActor);
end;

end.
