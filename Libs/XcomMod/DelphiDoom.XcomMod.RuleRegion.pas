{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a geographical region (RuleRegion)        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleRegion;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Areas, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.WeightedOptions;

type
  /// <summary>MissionArea: a box (radians) where a mission can happen; a point with a name is a city</summary>
  TXcomMissionArea = record
    LonMin: Double;
    LonMax: Double;
    LatMin: Double;
    LatMax: Double;
    /// <summary>Not read when the row has less than five numbers; the C++ leaves it uninitialized</summary>
    Texture: Integer;
    Name: string;
  end;

  /// <summary>MissionZone: the areas where a kind of mission can happen</summary>
  TXcomMissionZone = record
    Areas: TArray<TXcomMissionArea>;
  end;

  /// <summary>
  ///   Represents a region of the world: the cost of a base there, the area it covers, the zones for missions
  ///   and the weights of the missions (RuleRegion). The list of cities (getCities) is not here: a city is an
  ///   area that is a point with a name
  /// </summary>
  TXcomRuleRegion = class
  strict private
    FType: string;
    FCost: Integer;
    FAreas: TXcomGlobeAreas;
    FMissionZones: TArray<TXcomMissionZone>;
    FMissionWeights: TXcomWeightedOptions;
    FRegionWeight: Cardinal;
    FMissionRegion: string;
    class function ReadMissionArea(const ANode: IYamlNode): TXcomMissionArea; static;
    class function ReadMissionZones(const ANode: IYamlNode; const ADefault: TArray<TXcomMissionZone>)
      : TArray<TXcomMissionZone>; static;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const ANode: IYamlNode);
    property RegionType: string read FType;
    property BaseCost: Integer read FCost;
    /// <summary>The boxes of the region (getLonMin, getLonMax, getLatMin, getLatMax), in radians</summary>
    property Areas: TXcomGlobeAreas read FAreas;
    property Weight: Cardinal read FRegionWeight;
    property MissionRegion: string read FMissionRegion;
    property MissionZones: TArray<TXcomMissionZone> read FMissionZones;
    property MissionWeights: TXcomWeightedOptions read FMissionWeights;
    /// <summary>insideRegion</summary>
    function IsInside(ALongitude, ALatitude: Double): Boolean;
    /// <summary>
    ///   getRandomPoint: a random point (longitude, latitude) in a random area of a zone. A zone that does not
    ///   exist (assert in the C++) or has no area (undefined) is EXcomModException
    /// </summary>
    procedure GetRandomPoint(AZone: Cardinal; const ARandom: IXcomRandom; out ALongitude, ALatitude: Double);
  end;

implementation

{ TXcomRuleRegion }

constructor TXcomRuleRegion.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FMissionWeights := TXcomWeightedOptions.Create;
end;

destructor TXcomRuleRegion.Destroy;
begin
  FMissionWeights.Free;
  inherited Destroy;
end;

class function TXcomRuleRegion.ReadMissionArea(const ANode: IYamlNode): TXcomMissionArea;
var
  LCells: TArray<IYamlNode>;
  LSwap: Double;
begin
  // convert<MissionArea>::decode: a sequence of at least four numbers
  if not ANode.IsSequence or (ANode.Size < 4) then
    raise EYamlBadConversion.Create(ANode.Mark, 'bad conversion');
  LCells := ANode.Items;
  Result.LonMin := XcomDegToRad(LCells[0].AsDouble);
  Result.LonMax := XcomDegToRad(LCells[1].AsDouble);
  Result.LatMin := XcomDegToRad(LCells[2].AsDouble);
  Result.LatMax := XcomDegToRad(LCells[3].AsDouble);
  if Result.LatMin > Result.LatMax then
  begin
    LSwap := Result.LatMin;
    Result.LatMin := Result.LatMax;
    Result.LatMax := LSwap;
  end;
  Result.Texture := 0;
  Result.Name := '';
  if Length(LCells) >= 5 then
    Result.Texture := LCells[4].AsInteger;
  if Length(LCells) >= 6 then
    Result.Name := TXcomNodeReader.TextOf(LCells[5]);
end;

class function TXcomRuleRegion.ReadMissionZones(const ANode: IYamlNode;
  const ADefault: TArray<TXcomMissionZone>): TArray<TXcomMissionZone>;
var
  LField, LZone: IYamlNode;
  LItems, LAreas: TArray<IYamlNode>;
  LIndex, LArea: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, 'missionZones');
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LItems := LField.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
  begin
    LZone := LItems[LIndex];
    // convert<MissionZone>::decode needs a sequence; its areas are read as a vector (a bad one raises)
    if not LZone.IsSequence then
      raise EYamlBadConversion.Create(LZone.Mark, 'bad conversion');
    LAreas := LZone.Items;
    SetLength(Result[LIndex].Areas, Length(LAreas));
    for LArea := 0 to High(LAreas) do
      Result[LIndex].Areas[LArea] := ReadMissionArea(LAreas[LArea]);
  end;
end;

procedure TXcomRuleRegion.Load(const ANode: IYamlNode);
var
  LWeights: IYamlNode;
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FCost := TXcomNodeReader.ReadInteger(ANode, 'cost', FCost);
  FAreas.Load(ANode);
  FMissionZones := ReadMissionZones(ANode, FMissionZones);
  LWeights := TXcomNodeReader.Field(ANode, 'missionWeights');
  // if (const YAML::Node &weights = node["missionWeights"]): a defined node (even a scalar) is loaded
  if LWeights.IsDefined then
    FMissionWeights.Load(LWeights);
  FRegionWeight := TXcomNodeReader.ReadSize(ANode, 'regionWeight', FRegionWeight);
  FMissionRegion := TXcomNodeReader.ReadString(ANode, 'missionRegion', FMissionRegion);
end;

function TXcomRuleRegion.IsInside(ALongitude, ALatitude: Double): Boolean;
begin
  Result := FAreas.Contains(ALongitude, ALatitude);
end;

procedure TXcomRuleRegion.GetRandomPoint(AZone: Cardinal; const ARandom: IXcomRandom; out ALongitude,
  ALatitude: Double);
var
  LArea: Integer;
  LLonMin, LLonMax, LLatMin, LLatMax, LSwap: Double;
begin
  if AZone >= Cardinal(Length(FMissionZones)) then
    raise EXcomModException.Create('Xcom: invalid zone number');
  if Length(FMissionZones[AZone].Areas) = 0 then
    raise EXcomModException.Create('Xcom: the zone has no area');
  LArea := ARandom.Generate(0, Length(FMissionZones[AZone].Areas) - 1);
  LLonMin := FMissionZones[AZone].Areas[LArea].LonMin;
  LLonMax := FMissionZones[AZone].Areas[LArea].LonMax;
  LLatMin := FMissionZones[AZone].Areas[LArea].LatMin;
  LLatMax := FMissionZones[AZone].Areas[LArea].LatMax;
  if LLonMin > LLonMax then
  begin
    LSwap := LLonMin;
    LLonMin := LLonMax;
    LLonMax := LSwap;
  end;
  if LLatMin > LLatMax then
  begin
    LSwap := LLatMin;
    LLatMin := LLatMax;
    LLatMax := LSwap;
  end;
  ALongitude := ARandom.Generate(LLonMin, LLonMax);
  ALatitude := ARandom.Generate(LLatMin, LLatMax);
end;

end.
