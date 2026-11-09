{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a craft (RuleCraft)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleCraft;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.RuleRegistry, DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.RuleTerrain;

type
  /// <summary>
  ///   Constant data of a type of craft: costs, speed, capacities, fuel, radar and the terrain of its own
  ///   battlescape map (RuleCraft). It owns that terrain
  /// </summary>
  TXcomRuleCraft = class
  strict private
    FType: string;
    FRequires: TArray<string>;
    FSprite: Integer;
    FMarker: Integer;
    FFuelMax: Integer;
    FDamageMax: Integer;
    FSpeedMax: Integer;
    FAccel: Integer;
    FWeapons: Integer;
    FSoldiers: Integer;
    FVehicles: Integer;
    FCostBuy: Integer;
    FCostRent: Integer;
    FCostSell: Integer;
    FRefuelItem: string;
    FRepairRate: Integer;
    FRefuelRate: Integer;
    FRadarRange: Integer;
    FRadarChance: Integer;
    FSightRange: Integer;
    FTransferTime: Integer;
    FScore: Integer;
    FBattlescapeTerrainData: TXcomRuleTerrain;
    FSpacecraft: Boolean;
    FListOrder: Integer;
    FMaxItems: Integer;
    FMaxAltitude: Integer;
    FDeployment: TArray<TArray<Integer>>;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    /// <summary>
    ///   Loads the craft from a YAML node. The sprite moves by the offset of the mod when it is over 4 and
    ///   the marker when it is over 8; AListOrder is the default of listOrder
    /// </summary>
    procedure Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets;
      const AMapDataSets: TXcomRuleRegistry<TXcomMapDataSet>; AListOrder: Integer);
    property CraftType: string read FType;
    property Requirements: TArray<string> read FRequires;
    property Sprite: Integer read FSprite;
    property Marker: Integer read FMarker;
    property MaxFuel: Integer read FFuelMax;
    property MaxDamage: Integer read FDamageMax;
    property MaxSpeed: Integer read FSpeedMax;
    property Acceleration: Integer read FAccel;
    property Weapons: Integer read FWeapons;
    property Soldiers: Integer read FSoldiers;
    property Vehicles: Integer read FVehicles;
    property BuyCost: Integer read FCostBuy;
    property RentCost: Integer read FCostRent;
    property SellCost: Integer read FCostSell;
    property RefuelItem: string read FRefuelItem;
    property RepairRate: Integer read FRepairRate;
    property RefuelRate: Integer read FRefuelRate;
    property RadarRange: Integer read FRadarRange;
    property RadarChance: Integer read FRadarChance;
    property SightRange: Integer read FSightRange;
    property TransferTime: Integer read FTransferTime;
    property Score: Integer read FScore;
    /// <summary>The terrain of the battle map of the craft; nil if it does not have one</summary>
    property BattlescapeTerrainData: TXcomRuleTerrain read FBattlescapeTerrainData;
    property Spacecraft: Boolean read FSpacecraft;
    property ListOrder: Integer read FListOrder;
    property MaxItems: Integer read FMaxItems;
    property MaxAltitude: Integer read FMaxAltitude;
    property Deployment: TArray<TArray<Integer>> read FDeployment;
  end;

implementation

{ TXcomRuleCraft }

constructor TXcomRuleCraft.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FSprite := -1;
  FMarker := -1;
  FRepairRate := 1;
  FRefuelRate := 1;
  FRadarRange := 672;
  FRadarChance := 100;
  FSightRange := 1696;
  FMaxAltitude := -1;
end;

destructor TXcomRuleCraft.Destroy;
begin
  FBattlescapeTerrainData.Free;
  inherited Destroy;
end;

procedure TXcomRuleCraft.Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets;
  const AMapDataSets: TXcomRuleRegistry<TXcomMapDataSet>; AListOrder: Integer);
var
  LTerrain: IYamlNode;
  LRule: TXcomRuleTerrain;
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FRequires := TXcomNodeReader.ReadStrings(ANode, 'requires', FRequires);
  if TXcomNodeReader.Field(ANode, 'sprite').IsDefined then
    // the index in the surface set is baseOffset + sprite + (sprite > 4 ? modOffset : 0)
    FSprite := AOffsets.GetOffset(TXcomNodeReader.ReadInteger(ANode, 'sprite', FSprite), 4);
  if TXcomNodeReader.Field(ANode, 'marker').IsDefined then
    FMarker := AOffsets.GetOffset(TXcomNodeReader.ReadInteger(ANode, 'marker', FMarker), 8);
  FFuelMax := TXcomNodeReader.ReadInteger(ANode, 'fuelMax', FFuelMax);
  FDamageMax := TXcomNodeReader.ReadInteger(ANode, 'damageMax', FDamageMax);
  FSpeedMax := TXcomNodeReader.ReadInteger(ANode, 'speedMax', FSpeedMax);
  FAccel := TXcomNodeReader.ReadInteger(ANode, 'accel', FAccel);
  FWeapons := TXcomNodeReader.ReadInteger(ANode, 'weapons', FWeapons);
  FSoldiers := TXcomNodeReader.ReadInteger(ANode, 'soldiers', FSoldiers);
  FVehicles := TXcomNodeReader.ReadInteger(ANode, 'vehicles', FVehicles);
  FCostBuy := TXcomNodeReader.ReadInteger(ANode, 'costBuy', FCostBuy);
  FCostRent := TXcomNodeReader.ReadInteger(ANode, 'costRent', FCostRent);
  FCostSell := TXcomNodeReader.ReadInteger(ANode, 'costSell', FCostSell);
  FRefuelItem := TXcomNodeReader.ReadString(ANode, 'refuelItem', FRefuelItem);
  FRepairRate := TXcomNodeReader.ReadInteger(ANode, 'repairRate', FRepairRate);
  FRefuelRate := TXcomNodeReader.ReadInteger(ANode, 'refuelRate', FRefuelRate);
  FRadarRange := TXcomNodeReader.ReadInteger(ANode, 'radarRange', FRadarRange);
  FRadarChance := TXcomNodeReader.ReadInteger(ANode, 'radarChance', FRadarChance);
  FSightRange := TXcomNodeReader.ReadInteger(ANode, 'sightRange', FSightRange);
  FTransferTime := TXcomNodeReader.ReadInteger(ANode, 'transferTime', FTransferTime);
  FScore := TXcomNodeReader.ReadInteger(ANode, 'score', FScore);
  LTerrain := TXcomNodeReader.Field(ANode, 'battlescapeTerrainData');
  if LTerrain.IsDefined then
  begin
    LRule := TXcomRuleTerrain.Create(TXcomNodeReader.TextOf(TXcomNodeReader.Field(LTerrain, 'name')));
    try
      LRule.Load(LTerrain, AOffsets, AMapDataSets);
    except
      LRule.Free;
      raise;
    end;
    // the C++ leaks the terrain it replaces
    FBattlescapeTerrainData.Free;
    FBattlescapeTerrainData := LRule;
  end;
  FDeployment := TXcomNodeReader.ReadIntegerRows(ANode, 'deployment', FDeployment);
  FSpacecraft := TXcomNodeReader.ReadBoolean(ANode, 'spacecraft', FSpacecraft);
  FListOrder := TXcomNodeReader.ReadInteger(ANode, 'listOrder', FListOrder);
  if FListOrder = 0 then
    FListOrder := AListOrder;
  FMaxAltitude := TXcomNodeReader.ReadInteger(ANode, 'maxAltitude', FMaxAltitude);
  FMaxItems := TXcomNodeReader.ReadInteger(ANode, 'maxItems', FMaxItems);
end;

end.
