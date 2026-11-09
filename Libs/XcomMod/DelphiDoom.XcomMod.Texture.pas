{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a ground texture of the globe with the    }
{  deployments and terrains of its missions (Texture)                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.Texture;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Areas, DelphiDoom.XcomMod.Random;

type
  /// <summary>TerrainCriteria: a terrain a texture can give, its weight and the box (radians) where it applies</summary>
  TXcomTerrainCriteria = record
    Name: string;
    Weight: Integer;
    LonMin: Double;
    LonMax: Double;
    LatMin: Double;
    LatMax: Double;
    /// <summary>The constructor of TerrainCriteria: weight 1 and the whole globe (in degrees, as the C++ does)</summary>
    class function Default: TXcomTerrainCriteria; static;
    /// <summary>
    ///   convert&lt;TerrainCriteria&gt;::decode: a map; "area" is four numbers in degrees (the C++ reads a shorter
    ///   list out of its bounds: here EXcomModException). Anything but a map is a bad conversion
    /// </summary>
    class function Decode(const ANode: IYamlNode): TXcomTerrainCriteria; static;
  end;

  /// <summary>The ground texture of the globe: which missions and terrains happen on it (Texture)</summary>
  TXcomTexture = class
  strict private
    FId: Integer;
    FDeployments: TXcomStringMap<Integer>;
    FTerrain: TArray<TXcomTerrainCriteria>;
  public
    constructor Create(AId: Integer);
    destructor Destroy; override;
    procedure Load(const ANode: IYamlNode);
    property Id: Integer read FId;
    /// <summary>getTerrain</summary>
    property Terrain: TArray<TXcomTerrainCriteria> read FTerrain;
    /// <summary>getDeployments: the weights by deployment, in the order of the names</summary>
    property Deployments: TXcomStringMap<Integer> read FDeployments;
    /// <summary>
    ///   getRandomTerrain: a terrain at the point (radians) picked by weight among those whose box holds the
    ///   point; "" if none. The weights that overflow an int are undefined in the C++: EXcomModException
    /// </summary>
    function GetRandomTerrain(ALongitude, ALatitude: Double; const ARandom: IXcomRandom): string;
    /// <summary>getRandomDeployment: a deployment picked by weight; "" if there is none or the weights are below 1</summary>
    function GetRandomDeployment(const ARandom: IXcomRandom): string;
  end;

implementation

const
  SShortArea = 'Xcom: the area of a terrain needs four numbers';
  SWeightOverflow = 'Xcom: the weights of the terrains overflow';

{ TXcomTerrainCriteria }

class function TXcomTerrainCriteria.Default: TXcomTerrainCriteria;
begin
  Result.Name := '';
  Result.Weight := 1;
  Result.LonMin := 0.0;
  Result.LonMax := 360.0;
  Result.LatMin := -90.0;
  Result.LatMax := 90.0;
end;

class function TXcomTerrainCriteria.Decode(const ANode: IYamlNode): TXcomTerrainCriteria;
var
  LArea: IYamlNode;
  LValues: TArray<Double>;
begin
  if not ANode.IsMap then
    raise TXcomNodeReader.BadConversion(ANode);
  Result := Default;
  Result.Name := TXcomNodeReader.ReadString(ANode, 'name', Result.Name);
  Result.Weight := TXcomNodeReader.ReadInteger(ANode, 'weight', Result.Weight);
  LArea := TXcomNodeReader.Field(ANode, 'area');
  if LArea.IsDefined then
  begin
    LValues := TXcomNodeReader.DoublesOf(LArea);
    if Length(LValues) < 4 then
      raise EXcomModException.Create(SShortArea);
    Result.LonMin := XcomDegToRad(LValues[0]);
    Result.LonMax := XcomDegToRad(LValues[1]);
    Result.LatMin := XcomDegToRad(LValues[2]);
    Result.LatMax := XcomDegToRad(LValues[3]);
  end;
end;

{ TXcomTexture }

constructor TXcomTexture.Create(AId: Integer);
begin
  inherited Create;
  FId := AId;
  FDeployments := TXcomStringMap<Integer>.Create;
end;

destructor TXcomTexture.Destroy;
begin
  FDeployments.Free;
  inherited Destroy;
end;

procedure TXcomTexture.Load(const ANode: IYamlNode);
var
  LField: IYamlNode;
  LItems: TArray<IYamlNode>;
  LIndex: Integer;
begin
  FId := TXcomNodeReader.ReadInteger(ANode, 'id', FId);
  TXcomNodeReader.ReadStringIntMap(ANode, 'deployments', FDeployments);
  LField := TXcomNodeReader.Field(ANode, 'terrain');
  // as<std::vector<TerrainCriteria>>(fallback): anything but a sequence keeps the terrains
  if LField.IsDefined and LField.IsSequence then
  begin
    LItems := LField.Items;
    SetLength(FTerrain, 0);
    SetLength(FTerrain, Length(LItems));
    for LIndex := 0 to High(LItems) do
      FTerrain[LIndex] := TXcomTerrainCriteria.Decode(LItems[LIndex]);
  end;
end;

function TXcomTexture.GetRandomTerrain(ALongitude, ALatitude: Double; const ARandom: IXcomRandom): string;
var
  LTotal: Int64;
  LPick, LIndex: Integer;
  LNames: TArray<string>;
  LLimits: TArray<Int64>;
  LCount: Integer;
begin
  LTotal := 0;
  LCount := 0;
  SetLength(LNames, Length(FTerrain));
  SetLength(LLimits, Length(FTerrain));
  for LIndex := 0 to High(FTerrain) do
  begin
    if (FTerrain[LIndex].Weight > 0) and (ALongitude >= FTerrain[LIndex].LonMin) and
      (ALongitude < FTerrain[LIndex].LonMax) and (ALatitude >= FTerrain[LIndex].LatMin) and
      (ALatitude < FTerrain[LIndex].LatMax) then
    begin
      Inc(LTotal, FTerrain[LIndex].Weight);
      if LTotal > High(Integer) then
        raise EXcomModException.Create(SWeightOverflow);
      // possibilities[totalWeight] = name: the keys only grow, so a list in order is the same map
      LNames[LCount] := FTerrain[LIndex].Name;
      LLimits[LCount] := LTotal;
      Inc(LCount);
    end;
  end;
  Result := '';
  if LTotal > 0 then
  begin
    LPick := ARandom.Generate(1, Integer(LTotal));
    for LIndex := 0 to LCount - 1 do
      if LPick <= LLimits[LIndex] then
        Exit(LNames[LIndex]);
  end;
end;

function TXcomTexture.GetRandomDeployment(const ARandom: IXcomRandom): string;
var
  LTotal: Int64;
  LPick, LIndex: Integer;
begin
  Result := '';
  if FDeployments.Count = 0 then
    Exit;
  if FDeployments.Count = 1 then
    Exit(FDeployments.Key(0));
  LTotal := 0;
  for LIndex := 0 to FDeployments.Count - 1 do
    Inc(LTotal, FDeployments.Value(LIndex));
  if (LTotal > High(Integer)) or (LTotal < Low(Integer)) then
    raise EXcomModException.Create(SWeightOverflow);
  if LTotal >= 1 then
  begin
    LPick := ARandom.Generate(1, Integer(LTotal));
    for LIndex := 0 to FDeployments.Count - 1 do
    begin
      if LPick <= FDeployments.Value(LIndex) then
        Exit(FDeployments.Key(LIndex))
      else
        Dec(LPick, FDeployments.Value(LIndex));
    end;
  end;
end;

end.
