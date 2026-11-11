{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a craft of the player (Craft)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Craft;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.RuleCraft, DelphiDoom.XcomSave.NodeWriter,
  DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Target,
  DelphiDoom.XcomSave.MovingTarget, DelphiDoom.XcomSave.ItemContainer, DelphiDoom.XcomSave.CraftWeapon,
  DelphiDoom.XcomSave.Vehicle, DelphiDoom.XcomSave.TargetLookup.Intf, DelphiDoom.XcomSave.Types;

type
  /// <summary>CraftId: the type and the id that identify a craft</summary>
  TXcomCraftId = record
    CraftType: string;
    Id: Integer;
  end;

  /// <summary>
  ///   A craft of the player: fuel, damage, weapons (a slot can be empty), equipment, vehicles, status and the
  ///   destination (Craft). The base it belongs to is a reference to its target (not owned). Not ported: the
  ///   names for the interface, the radar (detect needs the UFO), rearm and unload (they need the storage and
  ///   the rules of the clips of the base) and the soldiers on board (they are counted by the base)
  /// </summary>
  TXcomCraft = class(TXcomMovingTarget)
  strict private
    FRules: TXcomRuleCraft;
    FBase: TXcomTarget;
    FFuel: Integer;
    FDamage: Integer;
    FSpeedMaxRadian: Double;
    FWeapons: TObjectList<TXcomCraftWeapon>;
    FItems: TXcomItemContainer;
    FVehicles: TObjectList<TXcomVehicle>;
    FStatus: string;
    FLowFuel: Boolean;
    FMission: Boolean;
    FInBattlescape: Boolean;
    FInDogfight: Boolean;
    FInterceptionOrder: Integer;
    FTakeoff: Integer;
    procedure ClearWeaponSlots;
    procedure FillWeaponSlots;
    procedure FindDestination(const ANode: IYamlNode; const ATargets: IXcomTargetLookup);
  public
    /// <param name="ARules">The rules of the craft (owned by the ruleset)</param>
    /// <param name="ABase">The target of the base; nil while the craft is loaded</param>
    /// <param name="AId">The id; 0 keeps the one that load will read</param>
    constructor Create(const ARules: TXcomRuleCraft; const ABase: TXcomTarget; AId: Integer);
    destructor Destroy; override;
    /// <summary>
    ///   load: a weapon of a type that does not exist is an empty slot (the C++ logs it); items and vehicles
    ///   the ruleset does not know are dropped; the destination is looked up among the targets of the saved
    ///   game and, for a base, the craft returns to it. A weapon or vehicle without a type is EYamlBadConversion
    /// </summary>
    procedure Load(const ANode: IYamlNode; const ARules: TXcomRulesetRules; const ATargets: IXcomTargetLookup);
      reintroduce;
    function Save: IYamlNode; override;
    /// <summary>loadId: the unique id in a node (type and id)</summary>
    class function LoadId(const ANode: IYamlNode): TXcomCraftId; static;
    function TargetType: string; override;
    function Marker: Integer; override;
    property Rules: TXcomRuleCraft read FRules;
    /// <summary>changeRules: the empty weapon slots of the new rules</summary>
    procedure ChangeRules(const ARules: TXcomRuleCraft);
    property Base: TXcomTarget read FBase;
    /// <summary>setBase: the craft goes to the position of the base if AMove</summary>
    procedure SetBase(const ABase: TXcomTarget; AMove: Boolean = True);
    property Status: string read FStatus write FStatus;
    property Fuel: Integer read FFuel;
    property Damage: Integer read FDamage;
    property Weapons: TObjectList<TXcomCraftWeapon> read FWeapons;
    property Items: TXcomItemContainer read FItems;
    property Vehicles: TObjectList<TXcomVehicle> read FVehicles;
    property LowFuel: Boolean read FLowFuel write FLowFuel;
    property MissionComplete: Boolean read FMission write FMission;
    property InBattlescape: Boolean read FInBattlescape;
    property InDogfight: Boolean read FInDogfight write FInDogfight;
    property InterceptionOrder: Integer read FInterceptionOrder write FInterceptionOrder;
    property Takeoff: Integer read FTakeoff write FTakeoff;
    /// <summary>setInBattlescape: a craft in a battle stops</summary>
    procedure SetInBattlescape(AInBattle: Boolean);
    /// <summary>setDestination: a craft that is not out takes 60 ticks to take off; the speed is the maximum (half if none)</summary>
    procedure SetDestination(const ADestination: TXcomTarget); reintroduce;
    /// <summary>getUniqueId</summary>
    function UniqueId: TXcomCraftId;
    function NumWeapons: Integer;
    function NumEquipment: Integer;
    function NumVehicles: Integer;
    /// <summary>setFuel: kept between 0 and the maximum</summary>
    procedure SetFuel(AFuel: Integer);
    /// <summary>setDamage: not below 0</summary>
    procedure SetDamage(ADamage: Integer);
    function FuelPercentage: Integer;
    function DamagePercentage: Integer;
    /// <summary>getFuelConsumption: 1 for a craft that burns an item, otherwise speed / 100</summary>
    function FuelConsumption: Integer; overload;
    function FuelConsumption(ASpeed: Integer): Integer; overload;
    function FuelLimit(const ABase: TXcomTarget): Integer;
    function BaseRange: Double;
    procedure ReturnToBase;
    /// <summary>checkup: the status when the craft is at the base (repairs, rearming or refuelling)</summary>
    procedure Checkup;
    /// <summary>think: a step of the craft; the craft that reached its base is checked and stops</summary>
    procedure Think;
    procedure ConsumeFuel;
    /// <summary>repair</summary>
    procedure Repair;
    /// <summary>
    ///   refuel: one step of refuelling from the storage of the base (nil if the craft needs no item); returns
    ///   the item that is missing, or ''
    /// </summary>
    function Refuel(const AStorage: TXcomItemContainer): string;
    function IsDestroyed: Boolean;
    function SpaceUsedByVehicles: Integer;
    function VehicleCount(const AVehicle: string): Integer;
    /// <summary>insideRadarRange: whether the target is within the radar range (nautical miles)</summary>
    function InsideRadarRange(const ATarget: TXcomTarget): Boolean;
    /// <summary>reuseItem</summary>
    procedure ReuseItem(const AItem: string);
  end;

implementation

const
  SNoWeaponType = 'Xcom: a craft weapon needs a type';

{ TXcomCraft }

constructor TXcomCraft.Create(const ARules: TXcomRuleCraft; const ABase: TXcomTarget; AId: Integer);
begin
  inherited Create;
  FRules := ARules;
  FBase := ABase;
  FStatus := 'STR_READY';
  FItems := TXcomItemContainer.Create;
  FWeapons := TObjectList<TXcomCraftWeapon>.Create(True);
  FVehicles := TObjectList<TXcomVehicle>.Create(True);
  if AId <> 0 then
    Id := AId;
  FillWeaponSlots;
  if Assigned(ABase) then
    SetBase(ABase);
  FSpeedMaxRadian := CalculateRadianSpeed(FRules.MaxSpeed) * 120;
end;

destructor TXcomCraft.Destroy;
begin
  FVehicles.Free;
  FItems.Free;
  FWeapons.Free;
  inherited Destroy;
end;

procedure TXcomCraft.FillWeaponSlots;
var
  LIndex: Integer;
begin
  for LIndex := 1 to FRules.Weapons do
    FWeapons.Add(nil);
end;

procedure TXcomCraft.ClearWeaponSlots;
begin
  FWeapons.Clear;
end;

function TXcomCraft.TargetType: string;
begin
  // Craft::getType is the type of the rules (STR_TRITON...), also in the ids of the targets
  Result := FRules.CraftType;
end;

function TXcomCraft.Marker: Integer;
begin
  if FStatus <> 'STR_OUT' then
    Exit(-1);
  if FRules.Marker = -1 then
    Exit(1);
  Result := FRules.Marker;
end;

procedure TXcomCraft.ChangeRules(const ARules: TXcomRuleCraft);
begin
  FRules := ARules;
  ClearWeaponSlots;
  FillWeaponSlots;
end;

procedure TXcomCraft.SetBase(const ABase: TXcomTarget; AMove: Boolean);
begin
  FBase := ABase;
  if AMove then
  begin
    SetLongitude(ABase.Longitude);
    SetLatitude(ABase.Latitude);
  end;
end;

procedure TXcomCraft.FindDestination(const ANode: IYamlNode; const ATargets: IXcomTargetLookup);
var
  LType: string;
  LId: Integer;
  LFound: TXcomTarget;
begin
  if not TXcomNodeReader.Field(ANode, 'type').IsDefined then
    raise TXcomNodeReader.BadConversion(ANode);
  // the C++ of a craft in a transfer passes no saved game (a null pointer that it would use)
  if not Assigned(ATargets) then
    raise EXcomSaveException.Create('Xcom: a craft with a destination needs the targets of the saved game');
  LType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(ANode, 'type'));
  LId := TXcomNodeReader.Field(ANode, 'id').AsInteger;
  if LType = 'STR_BASE' then
    ReturnToBase
  else if LType = 'STR_UFO' then
  begin
    LFound := ATargets.FindUfo(LId);
    if Assigned(LFound) then
      SetDestination(LFound);
  end
  else if LType = 'STR_WAY_POINT' then
  begin
    LFound := ATargets.FindWaypoint(LId);
    if Assigned(LFound) then
      SetDestination(LFound);
  end
  else
  begin
    // backwards compatibility
    if LType = 'STR_ALIEN_TERROR' then
      LType := 'STR_TERROR_SITE';
    LFound := ATargets.FindMissionSite(LId, LType);
    if not Assigned(LFound) then
      LFound := ATargets.FindAlienBase(LId, LType);
    if Assigned(LFound) then
      SetDestination(LFound);
  end;
end;

procedure TXcomCraft.Load(const ANode: IYamlNode; const ARules: TXcomRulesetRules;
  const ATargets: IXcomTargetLookup);
var
  LItem, LField, LTypeNode: IYamlNode;
  LSlot: Integer;
  LType: string;
  LWeaponRules: IXcomCraftWeaponRule;
  LWeapon: TXcomCraftWeapon;
  LItemRules: IXcomItemRule;
  LVehicle: TXcomVehicle;
  LNames: TArray<string>;
  LName: string;
begin
  inherited Load(ANode);
  FFuel := TXcomNodeReader.ReadInteger(ANode, 'fuel', FFuel);
  FDamage := TXcomNodeReader.ReadInteger(ANode, 'damage', FDamage);
  LSlot := 0;
  for LItem in TXcomNodeReader.Field(ANode, 'weapons').Items do
  begin
    if FRules.Weapons > LSlot then
    begin
      LTypeNode := TXcomNodeReader.Field(LItem, 'type');
      if not LTypeNode.IsDefined then
        raise TXcomNodeReader.BadConversion(LItem);
      LType := TXcomNodeReader.TextOf(LTypeNode);
      LWeaponRules := nil;
      if LType <> '0' then
        LWeaponRules := ARules.CraftWeapon(LType);
      if Assigned(LWeaponRules) then
      begin
        LWeapon := TXcomCraftWeapon.Create(LWeaponRules, 0);
        LWeapon.Load(LItem);
        FWeapons[LSlot] := LWeapon;
      end
      else
        // an unknown weapon is an empty slot (the C++ writes the error to the log)
        FWeapons[LSlot] := nil;
      Inc(LSlot);
    end;
  end;
  FItems.Load(TXcomNodeReader.Field(ANode, 'items'));
  // some old saves have bad items: they are dropped
  LNames := nil;
  for LSlot := 0 to FItems.Contents.Count - 1 do
    if not Assigned(ARules.Item(FItems.Contents.Key(LSlot))) then
    begin
      SetLength(LNames, Length(LNames) + 1);
      LNames[High(LNames)] := FItems.Contents.Key(LSlot);
    end;
  for LName in LNames do
    FItems.Contents.Remove(LName);
  for LItem in TXcomNodeReader.Field(ANode, 'vehicles').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'type');
    if not LTypeNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    LItemRules := ARules.Item(TXcomNodeReader.TextOf(LTypeNode));
    if Assigned(LItemRules) then
    begin
      LVehicle := TXcomVehicle.Create(LItemRules, 0, 4);
      LVehicle.Load(LItem);
      FVehicles.Add(LVehicle);
    end;
  end;
  FStatus := TXcomNodeReader.ReadString(ANode, 'status', FStatus);
  FLowFuel := TXcomNodeReader.ReadBoolean(ANode, 'lowFuel', FLowFuel);
  FMission := TXcomNodeReader.ReadBoolean(ANode, 'mission', FMission);
  FInterceptionOrder := TXcomNodeReader.ReadInteger(ANode, 'interceptionOrder', FInterceptionOrder);
  LField := TXcomNodeReader.Field(ANode, 'dest');
  if LField.IsDefined then
    FindDestination(LField, ATargets);
  FTakeoff := TXcomNodeReader.ReadInteger(ANode, 'takeoff', FTakeoff);
  FInBattlescape := TXcomNodeReader.ReadBoolean(ANode, 'inBattlescape', FInBattlescape);
  if FInBattlescape then
    SetSpeed(0);
end;

function TXcomCraft.Save: IYamlNode;
var
  LWeapon: TXcomCraftWeapon;
  LSubnode: IYamlNode;
  LVehicle: TXcomVehicle;
begin
  Result := inherited Save;
  TXcomNodeWriter.SetString(Result, 'type', FRules.CraftType);
  TXcomNodeWriter.SetInteger(Result, 'fuel', FFuel);
  TXcomNodeWriter.SetInteger(Result, 'damage', FDamage);
  for LWeapon in FWeapons do
  begin
    if Assigned(LWeapon) then
      LSubnode := LWeapon.Save
    else
    begin
      LSubnode := TXcomNodeWriter.NewMap;
      TXcomNodeWriter.SetString(LSubnode, 'type', '0');
    end;
    TXcomNodeWriter.PushBack(Result, 'weapons', LSubnode);
  end;
  TXcomNodeWriter.SetNode(Result, 'items', FItems.Save);
  for LVehicle in FVehicles do
    TXcomNodeWriter.PushBack(Result, 'vehicles', LVehicle.Save);
  TXcomNodeWriter.SetString(Result, 'status', FStatus);
  if FLowFuel then
    TXcomNodeWriter.SetBoolean(Result, 'lowFuel', True);
  if FMission then
    TXcomNodeWriter.SetBoolean(Result, 'mission', True);
  if FInBattlescape then
    TXcomNodeWriter.SetBoolean(Result, 'inBattlescape', True);
  if FInterceptionOrder <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'interceptionOrder', FInterceptionOrder);
  if FTakeoff <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'takeoff', FTakeoff);
end;

class function TXcomCraft.LoadId(const ANode: IYamlNode): TXcomCraftId;
var
  LType, LId: IYamlNode;
begin
  LType := TXcomNodeReader.Field(ANode, 'type');
  LId := TXcomNodeReader.Field(ANode, 'id');
  if not LType.IsDefined or not LId.IsDefined then
    raise TXcomNodeReader.BadConversion(ANode);
  Result.CraftType := TXcomNodeReader.TextOf(LType);
  Result.Id := LId.AsInteger;
end;

function TXcomCraft.UniqueId: TXcomCraftId;
begin
  Result.CraftType := FRules.CraftType;
  Result.Id := Id;
end;

procedure TXcomCraft.SetInBattlescape(AInBattle: Boolean);
begin
  if AInBattle then
    SetSpeed(0);
  FInBattlescape := AInBattle;
end;

procedure TXcomCraft.SetDestination(const ADestination: TXcomTarget);
begin
  if FStatus <> 'STR_OUT' then
    FTakeoff := 60;
  if not Assigned(ADestination) then
    SetSpeed(FRules.MaxSpeed div 2)
  else
    SetSpeed(FRules.MaxSpeed);
  inherited SetDestination(ADestination);
end;

function TXcomCraft.NumWeapons: Integer;
var
  LWeapon: TXcomCraftWeapon;
begin
  Result := 0;
  if FRules.Weapons = 0 then
    Exit;
  for LWeapon in FWeapons do
    if Assigned(LWeapon) then
      Inc(Result);
end;

function TXcomCraft.NumEquipment: Integer;
begin
  Result := FItems.TotalQuantity;
end;

function TXcomCraft.NumVehicles: Integer;
begin
  Result := FVehicles.Count;
end;

procedure TXcomCraft.SetFuel(AFuel: Integer);
begin
  FFuel := AFuel;
  if FFuel > FRules.MaxFuel then
    FFuel := FRules.MaxFuel
  else if FFuel < 0 then
    FFuel := 0;
end;

procedure TXcomCraft.SetDamage(ADamage: Integer);
begin
  FDamage := ADamage;
  if FDamage < 0 then
    FDamage := 0;
end;

function TXcomCraft.FuelPercentage: Integer;
begin
  if FRules.MaxFuel = 0 then
    raise EXcomSaveException.Create('Xcom: the craft has no maximum fuel');
  Result := Floor(FFuel / FRules.MaxFuel * 100.0);
end;

function TXcomCraft.DamagePercentage: Integer;
begin
  if FRules.MaxDamage = 0 then
    raise EXcomSaveException.Create('Xcom: the craft has no maximum damage');
  Result := Floor(FDamage / FRules.MaxDamage * 100);
end;

function TXcomCraft.FuelConsumption: Integer;
begin
  Result := FuelConsumption(Speed);
end;

function TXcomCraft.FuelConsumption(ASpeed: Integer): Integer;
begin
  if FRules.RefuelItem <> '' then
    Exit(1);
  Result := Floor(ASpeed / 100.0);
end;

function TXcomCraft.FuelLimit(const ABase: TXcomTarget): Integer;
begin
  if FSpeedMaxRadian = 0 then
    raise EXcomSaveException.Create('Xcom: the craft has no speed');
  Result := Floor(FuelConsumption(FRules.MaxSpeed) * Distance(ABase) / FSpeedMaxRadian);
end;

function TXcomCraft.BaseRange: Double;
begin
  if FuelConsumption(FRules.MaxSpeed) = 0 then
    raise EXcomSaveException.Create('Xcom: the craft burns no fuel');
  Result := FFuel / 2.0 / FuelConsumption(FRules.MaxSpeed) * FSpeedMaxRadian;
end;

procedure TXcomCraft.ReturnToBase;
begin
  SetDestination(FBase);
end;

procedure TXcomCraft.Think;
begin
  if FTakeoff = 0 then
    Move
  else
  begin
    Dec(FTakeoff);
    ResetMeetPoint;
  end;
  if ReachedDestination and (Destination = FBase) then
  begin
    FInterceptionOrder := 0;
    Checkup;
    SetDestination(nil);
    SetSpeed(0);
    FLowFuel := False;
    FMission := False;
    FTakeoff := 0;
  end;
end;

procedure TXcomCraft.Checkup;
var
  LAvailable, LFull: Integer;
  LWeapon: TXcomCraftWeapon;
begin
  LAvailable := 0;
  LFull := 0;
  for LWeapon in FWeapons do
  begin
    if not Assigned(LWeapon) then
      Continue;
    Inc(LAvailable);
    if LWeapon.Ammo >= LWeapon.Rules.AmmoMax then
      Inc(LFull)
    else
      LWeapon.Rearming := True;
  end;
  if FDamage > 0 then
    FStatus := 'STR_REPAIRS'
  else if LAvailable <> LFull then
    FStatus := 'STR_REARMING'
  else
    FStatus := 'STR_REFUELLING';
end;

procedure TXcomCraft.ConsumeFuel;
begin
  SetFuel(FFuel - FuelConsumption);
end;

procedure TXcomCraft.Repair;
begin
  SetDamage(FDamage - FRules.RepairRate);
  if FDamage <= 0 then
    FStatus := 'STR_REARMING';
end;

function TXcomCraft.Refuel(const AStorage: TXcomItemContainer): string;
var
  LItem: string;
  LWeapon: TXcomCraftWeapon;
begin
  Result := '';
  if FFuel < FRules.MaxFuel then
  begin
    LItem := FRules.RefuelItem;
    if LItem = '' then
      SetFuel(FFuel + FRules.RefuelRate)
    else
    begin
      if AStorage.GetItem(LItem) > 0 then
      begin
        AStorage.RemoveItem(LItem);
        SetFuel(FFuel + FRules.RefuelRate);
        FLowFuel := False;
      end
      else if not FLowFuel then
      begin
        Result := LItem;
        if FFuel > 0 then
          FStatus := 'STR_READY'
        else
          FLowFuel := True;
      end;
    end;
  end;
  if FFuel >= FRules.MaxFuel then
  begin
    FStatus := 'STR_READY';
    for LWeapon in FWeapons do
      if Assigned(LWeapon) and LWeapon.Rearming then
      begin
        FStatus := 'STR_REARMING';
        Break;
      end;
  end;
end;

function TXcomCraft.IsDestroyed: Boolean;
begin
  Result := FDamage >= FRules.MaxDamage;
end;

function TXcomCraft.SpaceUsedByVehicles: Integer;
var
  LVehicle: TXcomVehicle;
begin
  Result := 0;
  for LVehicle in FVehicles do
    Inc(Result, LVehicle.Size);
end;

function TXcomCraft.VehicleCount(const AVehicle: string): Integer;
var
  LVehicle: TXcomVehicle;
begin
  Result := 0;
  for LVehicle in FVehicles do
    if LVehicle.Rules.ItemType = AVehicle then
      Inc(Result);
end;

function TXcomCraft.InsideRadarRange(const ATarget: TXcomTarget): Boolean;
var
  LRange: Double;
begin
  // Nautical(x) = x * (1 / 60.0) * (M_PI / 180.0)
  LRange := FRules.RadarRange * (1 / 60.0);
  LRange := LRange * (3.14159265358979323846 / 180.0);
  Result := Distance(ATarget) <= LRange;
end;

procedure TXcomCraft.ReuseItem(const AItem: string);
begin
  if FStatus <> 'STR_READY' then
    Exit;
  // the check of the clip items of the weapons (the C++ compares with getClipItem) is not ported: the
  // weapon rules the saved game sees have no clip item
  if (AItem = FRules.RefuelItem) and (FFuel < FRules.MaxFuel) then
    FStatus := 'STR_REFUELLING';
end;

end.
