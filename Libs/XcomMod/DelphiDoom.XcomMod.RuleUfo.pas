{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a type of UFO (RuleUfo)                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleUfo;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.RuleRegistry, DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.RuleTerrain;

type
  /// <summary>
  ///   Constant data of a type of UFO: size, sprites, markers, damage, speed, weapon, score and the terrain of
  ///   its battle map (RuleUfo). It owns that terrain
  /// </summary>
  TXcomRuleUfo = class
  strict private
    FType: string;
    FSize: string;
    FSprite: Integer;
    FMarker: Integer;
    FMarkerLand: Integer;
    FMarkerCrash: Integer;
    FDamageMax: Integer;
    FSpeedMax: Integer;
    FPower: Integer;
    FRange: Integer;
    FScore: Integer;
    FReload: Integer;
    FBreakOffTime: Integer;
    FSightRange: Integer;
    FMissionScore: Integer;
    FBattlescapeTerrainData: TXcomRuleTerrain;
    FModSprite: string;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    /// <summary>Loads the UFO from a YAML node; the markers move by the offset of the mod when they are over 8</summary>
    procedure Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets;
      const AMapDataSets: TXcomRuleRegistry<TXcomMapDataSet>);
    /// <summary>getRadius: the radius in the dogfight window that goes with the size (0 for an unknown size)</summary>
    function Radius: Integer;
    property UfoType: string read FType;
    property Size: string read FSize;
    property Sprite: Integer read FSprite;
    property Marker: Integer read FMarker;
    property LandMarker: Integer read FMarkerLand;
    property CrashMarker: Integer read FMarkerCrash;
    property MaxDamage: Integer read FDamageMax;
    property MaxSpeed: Integer read FSpeedMax;
    property WeaponPower: Integer read FPower;
    property WeaponRange: Integer read FRange;
    property Score: Integer read FScore;
    property WeaponReload: Integer read FReload;
    property BreakOffTime: Integer read FBreakOffTime;
    property SightRange: Integer read FSightRange;
    property MissionScore: Integer read FMissionScore;
    /// <summary>The terrain of the battle map of the UFO; nil if it does not have one</summary>
    property BattlescapeTerrainData: TXcomRuleTerrain read FBattlescapeTerrainData;
    property ModSprite: string read FModSprite;
  end;

implementation

{ TXcomRuleUfo }

constructor TXcomRuleUfo.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FSize := 'STR_VERY_SMALL';
  FSprite := -1;
  FMarker := -1;
  FMarkerLand := -1;
  FMarkerCrash := -1;
  FSightRange := 268;
  FMissionScore := 1;
end;

destructor TXcomRuleUfo.Destroy;
begin
  FBattlescapeTerrainData.Free;
  inherited Destroy;
end;

procedure TXcomRuleUfo.Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets;
  const AMapDataSets: TXcomRuleRegistry<TXcomMapDataSet>);
var
  LTerrain: IYamlNode;
  LRule: TXcomRuleTerrain;
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FSize := TXcomNodeReader.ReadString(ANode, 'size', FSize);
  FSprite := TXcomNodeReader.ReadInteger(ANode, 'sprite', FSprite);
  if TXcomNodeReader.Field(ANode, 'marker').IsDefined then
    FMarker := AOffsets.GetOffset(TXcomNodeReader.ReadInteger(ANode, 'marker', FMarker), 8);
  if TXcomNodeReader.Field(ANode, 'markerLand').IsDefined then
    FMarkerLand := AOffsets.GetOffset(TXcomNodeReader.ReadInteger(ANode, 'markerLand', FMarkerLand), 8);
  if TXcomNodeReader.Field(ANode, 'markerCrash').IsDefined then
    FMarkerCrash := AOffsets.GetOffset(TXcomNodeReader.ReadInteger(ANode, 'markerCrash', FMarkerCrash), 8);
  FDamageMax := TXcomNodeReader.ReadInteger(ANode, 'damageMax', FDamageMax);
  FSpeedMax := TXcomNodeReader.ReadInteger(ANode, 'speedMax', FSpeedMax);
  FPower := TXcomNodeReader.ReadInteger(ANode, 'power', FPower);
  FRange := TXcomNodeReader.ReadInteger(ANode, 'range', FRange);
  FScore := TXcomNodeReader.ReadInteger(ANode, 'score', FScore);
  FReload := TXcomNodeReader.ReadInteger(ANode, 'reload', FReload);
  FBreakOffTime := TXcomNodeReader.ReadInteger(ANode, 'breakOffTime', FBreakOffTime);
  FSightRange := TXcomNodeReader.ReadInteger(ANode, 'sightRange', FSightRange);
  FMissionScore := TXcomNodeReader.ReadInteger(ANode, 'missionScore', FMissionScore);
  LTerrain := TXcomNodeReader.Field(ANode, 'battlescapeTerrainData');
  if LTerrain.IsDefined then
  begin
    FreeAndNil(FBattlescapeTerrainData);
    LRule := TXcomRuleTerrain.Create(TXcomNodeReader.TextOf(TXcomNodeReader.Field(LTerrain, 'name')));
    try
      LRule.Load(LTerrain, AOffsets, AMapDataSets);
    except
      LRule.Free;
      raise;
    end;
    FBattlescapeTerrainData := LRule;
  end;
  FModSprite := TXcomNodeReader.ReadString(ANode, 'modSprite', FModSprite);
end;

function TXcomRuleUfo.Radius: Integer;
begin
  if FSize = 'STR_VERY_SMALL' then
    Result := 2
  else if FSize = 'STR_SMALL' then
    Result := 3
  else if FSize = 'STR_MEDIUM_UC' then
    Result := 4
  else if FSize = 'STR_LARGE' then
    Result := 5
  else if FSize = 'STR_VERY_LARGE' then
    Result := 6
  else
    Result := 0;
end;

end.
