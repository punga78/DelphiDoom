{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixActorProperties                           }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the Radix properties of SC_ActordefToDEH (sc_actordef.pas of Rad-X)  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.ActorProperties;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.Logging.Intf, DelphiDoom.ActorDef.Types, DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Intf;

{$SCOPEDENUMS ON}

const
  RADIX_AMMO_TYPES = 4;
  RADIX_WEAPONS = 9;

type
  /// <summary>The flags of an actor that the engine of Doom does not have</summary>
  TRadixActorFlag = (
    /// <summary>A pickup that gives what its INVENTORY block says</summary>
    CustomPickup,
    ThruSky,
    NoCrash,
    DontBlockSpecies,
    CanDamageWalls,
    DamageOnPlayerTouch,
    UseAltDamage,
    Bobing,
    PreventThruSky,
    LimitPatrolRange,
    CanSpawnChildren,
    /// <summary>Shown in the automap as a teleport fog / as a force field</summary>
    AmTeleportFog,
    AmForceField,
    /// <summary>The missile is not moved down when it is born too near the ceiling</summary>
    NoAdjustMissileCeiling,
    AlienBlood);
  TRadixActorFlags = set of TRadixActorFlag;

  /// <summary>
  ///   What Rad-X added to mobjinfo_t: what a pickup gives (the INVENTORY block) and the numbers
  ///   of the enemies that the engine of Doom does not have. A "Set" of -1 means not given
  /// </summary>
  TRadixActorInfo = record
    Flags: TRadixActorFlags;
    ArmorSet, ArmorInc: Integer;
    EnergySet, EnergyInc: Integer;
    ShieldSet, ShieldInc: Integer;
    AmmoInc: array[0..RADIX_AMMO_TYPES - 1] of Integer;
    WeaponInc: array[0..RADIX_WEAPONS - 1] of Boolean;
    /// <summary>The tics of each power up that the pickup gives</summary>
    RapidShield, RapidEnergy, ManeuverJets, NightVision, Alds: Integer;
    PlasmaBomb: Integer;
    PickupMessage: string;
    PickupSound: string;
    TouchDamage: Integer;
    AltDamage: Integer;
    PatrolRange: Integer;
    /// <summary>The pickup gives something (a pickup with an empty block is taken for nothing)</summary>
    function GivesSomething: Boolean;
    /// <summary>Nothing of Radix was said of the actor</summary>
    function IsEmpty: Boolean;
    class function Empty: TRadixActorInfo; static;
  end;

  /// <summary>The Radix part of the definitions of the actors, by the name of the actor</summary>
  IRadixActorTable = interface
    ['{C41A7F0E-63B2-4D59-8E17-0A9D5B2C6E43}']
    /// <summary>False for an actor that has nothing of Radix (the info is then empty)</summary>
    function TryGet(const AName: string; out AInfo: TRadixActorInfo): Boolean;
    /// <summary>
    ///   The info that a patch (a Thing block of DEHACKED with the fields of Rad-X) gave to the thing
    ///   with that number, from 0 as mobjinfo; false when the patch said nothing but zeros
    /// </summary>
    function TryGetByNumber(ANumber: Integer; out AInfo: TRadixActorInfo): Boolean;
    function GetCount: Integer;
    property Count: Integer read GetCount;
  end;

  /// <summary>
  ///   Reads the properties of Radix of the ACTORs while the parser of Libs\ActorDef reads the
  ///   rest, and keeps them by name. An actor that inherits starts from the info of its parent
  ///   (the old code copied the whole mobjinfo). Names are compared without case.
  ///   It also reads the same properties as the fields that Rad-X added to the Thing blocks of
  ///   DEHACKED (ARMOR INC, AMMO ADD, PICKUP MESSAGE ...: deh_main.pas of Rad-X), asked by the reader
  ///   of the things of Libs\Dehacked: a thing with a number is kept by its number, a new thing by
  ///   its name. There a "Set" of 0 means not given, as in Rad-X
  /// </summary>
  TRadixActorProperties = class(TInterfacedObject, IActorDefExtraProperties, IDehackedExtraThingFields,
    IRadixActorTable)
  strict private
    FLog: ILog;
    FInfos: TDictionary<string, TRadixActorInfo>;
    FNumbered: TDictionary<Integer, TRadixActorInfo>;
    FCurrentName: string;
    FCurrent: TRadixActorInfo;
    FTouched: Boolean;
    procedure Store;
    procedure Warn(const AMessage: string);
    function ReadThingField(const AKey, AValue: string; var AInfo: TRadixActorInfo): Boolean;
    function NextInteger(const ATokens: IActorDefTokenCursor; out AValue: Integer): Boolean;
    function ReadSetOrInc(const AToken: string; const ATokens: IActorDefTokenCursor;
      var ASet, AInc: Integer): Boolean;
    function ReadFlag(const AToken: string): Boolean;
    class function WeaponOf(const AToken: string): Integer; static;
    class function Key(const AName: string): string; static;
  public
    /// <param name="ALog">Where the problems of the text go; may be nil</param>
    constructor Create(const ALog: ILog);
    destructor Destroy; override;
    procedure BeginActor(const AName, AInheritsFrom: string);
    function TryRead(const AToken: string; const ATokens: IActorDefTokenCursor): Boolean; overload;
    /// <summary>IDehackedExtraThingFields: a field of Rad-X of a Thing block of a patch</summary>
    function TryRead(const AThing: TDehackedReference; const AKey, AValue: string): Boolean; overload;
    function TryGet(const AName: string; out AInfo: TRadixActorInfo): Boolean;
    function TryGetByNumber(ANumber: Integer; out AInfo: TRadixActorInfo): Boolean;
    function GetCount: Integer;
  end;

implementation

const
  NOT_SET = -1;
  FLAG_NAMES: array[TRadixActorFlag] of string = ('CUSTOMPICKUP', 'THRUSKY', 'NOCRASH',
    'DONTBLOCKSPECIES', 'CANDAMAGEWALLS', 'DAMAGEONPLAYERTOUCH', 'USEALTDAMAGE', 'BOBING',
    'PREVENTTHRYSKY', 'LIMITPATROLRANGE', 'CANSPAWNCHILDREN', 'AMTELEPORTFOG', 'AMFORCEFIELD',
    'NOADJUSTMISSILECEILING', 'ALIENBLOOD');
  FLAG_PREFIXES: array[0..4] of string = ('MF4_EX_', 'MF3_EX_', 'MF2_EX_', 'MF_EX_', 'MF_');
  // the names of the weapons in an INVENTORY block, beside WEAPON0..WEAPON8
  WEAPON_NAMES: array[0..RADIX_WEAPONS - 1] of string = ('NEUTRONCANNONS', 'STANDARDEPC',
    'PLASMASPREADER', 'SEEKINGMISSILES', 'NUKE', 'PHASETORPEDOES', 'GRAVITYWAVE', 'ENCHANCEDEPC',
    'SUPEREPC');
  SBadSetOrInc = 'Radix actor "%s": "%s" found after %s, "SET", "ADD" or "INC" expected'#13#10;
  SBadInteger = 'Radix actor "%s": "%s" found after %s, a number expected'#13#10;
  // the two warnings of deh_main.pas of Rad-X
  SBadAmmoValues = 'DEH_Parse(): Wrong ammo values = %s (Count is = %d).'#13#10;
  SBadWeaponValues = 'DEH_Parse(): Wrong weapon values = %s (Count is = %d).'#13#10;
  THING_LIST_SEPARATORS: array[0..2] of Char = (' ', ',', '|');

{ TRadixActorInfo }

class function TRadixActorInfo.Empty: TRadixActorInfo;
begin
  Result := Default(TRadixActorInfo);
  Result.ArmorSet := NOT_SET;
  Result.EnergySet := NOT_SET;
  Result.ShieldSet := NOT_SET;
end;

function TRadixActorInfo.GivesSomething: Boolean;
var
  LIndex: Integer;
begin
  Result := (ArmorSet >= 0) or (ArmorInc > 0) or (EnergySet >= 0) or (EnergyInc > 0) or
    (ShieldSet >= 0) or (ShieldInc > 0) or (RapidShield > 0) or (RapidEnergy > 0) or
    (ManeuverJets > 0) or (NightVision > 0) or (Alds > 0) or (PlasmaBomb > 0);
  for LIndex := 0 to RADIX_AMMO_TYPES - 1 do
    Result := Result or (AmmoInc[LIndex] > 0);
  for LIndex := 0 to RADIX_WEAPONS - 1 do
    Result := Result or WeaponInc[LIndex];
end;

function TRadixActorInfo.IsEmpty: Boolean;
begin
  Result := (Flags = []) and not GivesSomething and (PickupMessage = '') and (PickupSound = '') and
    (TouchDamage = 0) and (AltDamage = 0) and (PatrolRange = 0);
end;

{ TRadixActorProperties }

constructor TRadixActorProperties.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
  FInfos := TDictionary<string, TRadixActorInfo>.Create;
  FNumbered := TDictionary<Integer, TRadixActorInfo>.Create;
  FCurrent := TRadixActorInfo.Empty;
end;

destructor TRadixActorProperties.Destroy;
begin
  FNumbered.Free;
  FInfos.Free;
  inherited Destroy;
end;

class function TRadixActorProperties.Key(const AName: string): string;
begin
  Result := UpperCase(Trim(AName));
end;

procedure TRadixActorProperties.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

procedure TRadixActorProperties.Store;
begin
  if FTouched and (FCurrentName <> '') then
    FInfos.AddOrSetValue(Key(FCurrentName), FCurrent);
end;

procedure TRadixActorProperties.BeginActor(const AName, AInheritsFrom: string);
begin
  FCurrentName := AName;
  FTouched := (AInheritsFrom <> '') and FInfos.TryGetValue(Key(AInheritsFrom), FCurrent);
  if not FTouched then
    FCurrent := TRadixActorInfo.Empty;
  Store;
end;

function TRadixActorProperties.NextInteger(const ATokens: IActorDefTokenCursor; out AValue: Integer): Boolean;
begin
  Result := ATokens.Next and TryStrToInt(Trim(ATokens.Current), AValue);
  if not Result then
    AValue := 0;
end;

function TRadixActorProperties.ReadSetOrInc(const AToken: string; const ATokens: IActorDefTokenCursor;
  var ASet, AInc: Integer): Boolean;
var
  LKind: string;
  LValue: Integer;
begin
  Result := True;
  if not ATokens.Next then
    Exit;
  LKind := UpperCase(ATokens.Current);
  if (LKind <> 'SET') and (LKind <> 'INC') and (LKind <> 'ADD') then
  begin
    Warn(Format(SBadSetOrInc, [FCurrentName, ATokens.Current, AToken]));
    Exit;
  end;
  if not NextInteger(ATokens, LValue) then
  begin
    Warn(Format(SBadInteger, [FCurrentName, ATokens.Current, AToken]));
    Exit;
  end;
  if LKind = 'SET' then
    ASet := LValue
  else
    AInc := LValue;
end;

function TRadixActorProperties.ReadFlag(const AToken: string): Boolean;
var
  LName: string;
  LPrefix: string;
  LFlag: TRadixActorFlag;
begin
  Result := False;
  if (AToken = '') or ((AToken[1] <> '+') and (AToken[1] <> '-')) then
    Exit;
  LName := Copy(AToken, 2, MaxInt);
  for LPrefix in FLAG_PREFIXES do
    if LName.StartsWith(LPrefix) then
    begin
      LName := Copy(LName, Length(LPrefix) + 1, MaxInt);
      Break;
    end;
  for LFlag := Low(TRadixActorFlag) to High(TRadixActorFlag) do
    if FLAG_NAMES[LFlag] = LName then
    begin
      if AToken[1] = '+' then
        Include(FCurrent.Flags, LFlag)
      else
        Exclude(FCurrent.Flags, LFlag);
      Exit(True);
    end;
end;

class function TRadixActorProperties.WeaponOf(const AToken: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to RADIX_WEAPONS - 1 do
    if (AToken = WEAPON_NAMES[LIndex]) or (AToken = 'WEAPON' + IntToStr(LIndex)) then
      Exit(LIndex);
  Result := -1;
end;

function TRadixActorProperties.TryRead(const AToken: string; const ATokens: IActorDefTokenCursor): Boolean;

  procedure ReadNumber(var AField: Integer);
  begin
    if not NextInteger(ATokens, AField) then
      Warn(Format(SBadInteger, [FCurrentName, ATokens.Current, AToken]));
  end;

var
  LIndex: Integer;
  LWeapon: Integer;
  LText: string;
begin
  Result := True;
  LWeapon := WeaponOf(AToken);
  if ReadFlag(AToken) then
    // nothing else to read
  else if AToken = 'INVENTORY' then
    // the block has no meaning of its own: its braces are not words
  else if AToken = 'ARMOR' then
    ReadSetOrInc(AToken, ATokens, FCurrent.ArmorSet, FCurrent.ArmorInc)
  else if AToken = 'ENERGY' then
    ReadSetOrInc(AToken, ATokens, FCurrent.EnergySet, FCurrent.EnergyInc)
  else if AToken = 'SHIELD' then
    ReadSetOrInc(AToken, ATokens, FCurrent.ShieldSet, FCurrent.ShieldInc)
  else if AToken = 'AMMO' then
  begin
    for LIndex := 0 to RADIX_AMMO_TYPES - 1 do
      ReadNumber(FCurrent.AmmoInc[LIndex]);
  end
  else if AToken = 'WEAPON' then
  begin
    for LIndex := 0 to RADIX_WEAPONS - 1 do
      if ATokens.Next then
      begin
        LText := UpperCase(ATokens.Current);
        FCurrent.WeaponInc[LIndex] := (LText = 'TRUE') or (LText = 'YES') or (LText = '1');
      end;
  end
  else if LWeapon >= 0 then
    FCurrent.WeaponInc[LWeapon] := True
  else if AToken = 'RAPIDSHIELD' then
    ReadNumber(FCurrent.RapidShield)
  else if AToken = 'RAPIDENERGY' then
    ReadNumber(FCurrent.RapidEnergy)
  else if AToken = 'MANEUVERJETS' then
    ReadNumber(FCurrent.ManeuverJets)
  else if AToken = 'NIGHTVISION' then
    ReadNumber(FCurrent.NightVision)
  else if AToken = 'ALDS' then
    ReadNumber(FCurrent.Alds)
  else if AToken = 'PLASMABOMB' then
    ReadNumber(FCurrent.PlasmaBomb)
  else if AToken = 'PICKUPMESSAGE' then
  begin
    if ATokens.Next then
      FCurrent.PickupMessage := ATokens.Current;
  end
  else if AToken = 'PICKUPSOUND' then
  begin
    if ATokens.Next then
      FCurrent.PickupSound := ATokens.Current;
  end
  else if AToken = 'TOUCHDAMAGE' then
    ReadNumber(FCurrent.TouchDamage)
  else if AToken = 'ALTDAMAGE' then
    ReadNumber(FCurrent.AltDamage)
  else if AToken = 'PATROLRANGE' then
    ReadNumber(FCurrent.PatrolRange)
  else
    Result := False;

  if Result then
  begin
    FTouched := True;
    Store;
  end;
end;

function TRadixActorProperties.ReadThingField(const AKey, AValue: string; var AInfo: TRadixActorInfo): Boolean;

  function Number: Integer;
  begin
    Result := StrToIntDef(Trim(AValue), 0);
  end;

  function SetNumber: Integer;
  begin
    // a patch writes 0 for a "Set" that the thing has not
    Result := Number;
    if Result <= 0 then
      Result := NOT_SET;
  end;

  function Text: string;
  begin
    // the sounds of a patch of Rad-X are numbers: 0 is no sound
    Result := Trim(AValue);
    if Result = '0' then
      Result := '';
  end;

var
  LWords: TArray<string>;
  LIndex: Integer;
  LWord: string;
begin
  Result := True;
  if AKey = 'ARMOR INC' then
    AInfo.ArmorInc := Number
  else if AKey = 'ENERGY INC' then
    AInfo.EnergyInc := Number
  else if AKey = 'SHIELD INC' then
    AInfo.ShieldInc := Number
  else if AKey = 'ARMOR SET' then
    AInfo.ArmorSet := SetNumber
  else if AKey = 'ENERGY SET' then
    AInfo.EnergySet := SetNumber
  else if AKey = 'SHIELD SET' then
    AInfo.ShieldSet := SetNumber
  else if AKey = 'AMMO ADD' then
  begin
    LWords := AValue.Split(THING_LIST_SEPARATORS, TStringSplitOptions.ExcludeEmpty);
    if Length(LWords) <> RADIX_AMMO_TYPES then
      Warn(Format(SBadAmmoValues, [AValue, Length(LWords)]))
    else
      for LIndex := 0 to RADIX_AMMO_TYPES - 1 do
        AInfo.AmmoInc[LIndex] := StrToIntDef(LWords[LIndex], 0);
  end
  else if AKey = 'WEAPON ADD' then
  begin
    LWords := AValue.Split(THING_LIST_SEPARATORS, TStringSplitOptions.ExcludeEmpty);
    if Length(LWords) <> RADIX_WEAPONS then
      Warn(Format(SBadWeaponValues, [AValue, Length(LWords)]))
    else
      for LIndex := 0 to RADIX_WEAPONS - 1 do
      begin
        LWord := UpperCase(LWords[LIndex]);
        AInfo.WeaponInc[LIndex] := (LWord = 'TRUE') or (LWord = 'YES') or (LWord = '1');
      end;
  end
  else if AKey = 'PICKUP MESSAGE' then
    AInfo.PickupMessage := Trim(AValue)
  else if AKey = 'PICKUP SOUND' then
    AInfo.PickupSound := Text
  else if AKey = 'RAPID SHIELD' then
    AInfo.RapidShield := Number
  else if AKey = 'RAPID ENERGY' then
    AInfo.RapidEnergy := Number
  else if AKey = 'MANEUVER JETS' then
    AInfo.ManeuverJets := Number
  else if AKey = 'NIGHT VISION' then
    AInfo.NightVision := Number
  else if AKey = 'A.L.D.S.' then
    AInfo.Alds := Number
  else if AKey = 'PLASMA BOMB' then
    AInfo.PlasmaBomb := Number
  else if AKey = 'TOUCH DAMAGE' then
    AInfo.TouchDamage := Number
  else if AKey = 'PATROL RANGE' then
    AInfo.PatrolRange := Number
  else if AKey = 'MISSILE ALT DAMAGE' then
    AInfo.AltDamage := Number
  else
    Result := False;
end;

function TRadixActorProperties.TryRead(const AThing: TDehackedReference; const AKey, AValue: string): Boolean;
var
  LInfo: TRadixActorInfo;
  LByName: Boolean;
  LHad: Boolean;
begin
  LByName := AThing.IsNew or (AThing.Number < 1);
  if LByName then
    LHad := FInfos.TryGetValue(Key(AThing.Name), LInfo)
  else
    LHad := FNumbered.TryGetValue(AThing.Number - 1, LInfo);
  if not LHad then
    LInfo := TRadixActorInfo.Empty;

  Result := ReadThingField(UpperCase(Trim(AKey)), AValue, LInfo);
  // the blocks that a dump of the tables writes are all zeros: such a thing has nothing of Radix
  if not Result or (LInfo.IsEmpty and not LHad) then
    Exit;
  if LByName then
  begin
    if Key(AThing.Name) <> '' then
      FInfos.AddOrSetValue(Key(AThing.Name), LInfo);
  end
  else
    FNumbered.AddOrSetValue(AThing.Number - 1, LInfo);
end;

function TRadixActorProperties.TryGetByNumber(ANumber: Integer; out AInfo: TRadixActorInfo): Boolean;
begin
  Result := FNumbered.TryGetValue(ANumber, AInfo);
  if not Result then
    AInfo := TRadixActorInfo.Empty;
end;

function TRadixActorProperties.TryGet(const AName: string; out AInfo: TRadixActorInfo): Boolean;
begin
  Result := FInfos.TryGetValue(Key(AName), AInfo);
  if not Result then
    AInfo := TRadixActorInfo.Empty;
end;

function TRadixActorProperties.GetCount: Integer;
begin
  Result := FInfos.Count;
end;

end.
