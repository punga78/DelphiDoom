{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a battlescape terrain (RuleTerrain)       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleTerrain;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.ModOffsets, DelphiDoom.XcomMod.RuleRegistry, DelphiDoom.XcomMod.MapDataSet,
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.Random;

type
  /// <summary>
  ///   A terrain of the battlescape: the map data files it uses, its blocks of map, civilians, music, depth,
  ///   ambient sound and map script (RuleTerrain). It owns its blocks; the data files belong to the ruleset
  /// </summary>
  TXcomRuleTerrain = class
  strict private
    FMapDataSets: TList<TXcomMapDataSet>;
    FMapBlocks: TObjectList<TXcomMapBlock>;
    FName: string;
    FScript: string;
    FCivilianTypes: TArray<string>;
    FMusic: TArray<string>;
    FMinDepth: Integer;
    FMaxDepth: Integer;
    FAmbience: Integer;
    FAmbientVolume: Double;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    /// <summary>
    ///   Loads the terrain from a YAML node. A data file is looked up by name in AMapDataSets and made if
    ///   it is new (Mod::getMapDataSet); the ambient sound is a sound of BATTLE.CAT
    /// </summary>
    procedure Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets;
      const AMapDataSets: TXcomRuleRegistry<TXcomMapDataSet>);
    /// <summary>
    ///   getRandomMapBlock: a block at random among those of the right size (an exact size, or smaller if
    ///   AForce is false; the C++ default is true) that are in the group; nil if there is none
    /// </summary>
    function GetRandomMapBlock(AMaxSizeX, AMaxSizeY, AGroup: Integer; const ARandom: IXcomRandom;
      AForce: Boolean = True): TXcomMapBlock;
    /// <summary>getMapBlock: a block by name; nil if there is none</summary>
    function GetMapBlock(const AName: string): TXcomMapBlock;
    /// <summary>
    ///   getMapData: the part AId counted over the sets of the terrain in order; AId becomes the index in its
    ///   set and AMapDataSetId counts the sets passed. A reference past the last set is BLANKS part 0. The sets
    ///   must be loaded
    /// </summary>
    function GetMapData(var AId: Cardinal; var AMapDataSetId: Integer): TXcomMapData;
    property Name: string read FName;
    property Script: string read FScript;
    property MapDataSets: TList<TXcomMapDataSet> read FMapDataSets;
    property MapBlocks: TObjectList<TXcomMapBlock> read FMapBlocks;
    property CivilianTypes: TArray<string> read FCivilianTypes;
    property Music: TArray<string> read FMusic;
    property MinDepth: Integer read FMinDepth;
    property MaxDepth: Integer read FMaxDepth;
    property Ambience: Integer read FAmbience;
    property AmbientVolume: Double read FAmbientVolume;
  end;

implementation

function TXcomRuleTerrain.GetRandomMapBlock(AMaxSizeX, AMaxSizeY, AGroup: Integer; const ARandom: IXcomRandom;
  AForce: Boolean): TXcomMapBlock;
var
  LBlock: TXcomMapBlock;
  LCompliant: TList<TXcomMapBlock>;
begin
  LCompliant := TList<TXcomMapBlock>.Create;
  try
    for LBlock in FMapBlocks do
      if ((LBlock.SizeX = AMaxSizeX) or (not AForce and (LBlock.SizeX < AMaxSizeX))) and
        ((LBlock.SizeY = AMaxSizeY) or (not AForce and (LBlock.SizeY < AMaxSizeY))) and LBlock.IsInGroup(AGroup) then
        LCompliant.Add(LBlock);
    if LCompliant.Count = 0 then
      Exit(nil);
    Result := LCompliant[ARandom.Generate(0, LCompliant.Count - 1)];
  finally
    LCompliant.Free;
  end;
end;

function TXcomRuleTerrain.GetMapData(var AId: Cardinal; var AMapDataSetId: Integer): TXcomMapData;
var
  LIndex: Integer;
  LSet: TXcomMapDataSet;
begin
  LSet := nil;
  LIndex := 0;
  while LIndex < FMapDataSets.Count do
  begin
    LSet := FMapDataSets[LIndex];
    if AId < Cardinal(LSet.Size) then
      Break;
    Dec(AId, Cardinal(LSet.Size));
    Inc(AMapDataSetId);
    Inc(LIndex);
  end;
  if LIndex = FMapDataSets.Count then
  begin
    // a broken tile reference of the original maps: BLANKS part 0
    LSet := FMapDataSets[0];
    AId := 0;
    AMapDataSetId := 0;
  end;
  Result := LSet.GetObject(AId);
end;

function TXcomRuleTerrain.GetMapBlock(const AName: string): TXcomMapBlock;
var
  LBlock: TXcomMapBlock;
begin
  for LBlock in FMapBlocks do
    if LBlock.Name = AName then
      Exit(LBlock);
  Result := nil;
end;

const
  /// <summary>The default of ambientVolume (0.5)</summary>
  DEFAULT_AMBIENT_VOLUME: Double = 0.5;

{ TXcomRuleTerrain }

constructor TXcomRuleTerrain.Create(const AName: string);
begin
  inherited Create;
  FMapDataSets := TList<TXcomMapDataSet>.Create;
  FMapBlocks := TObjectList<TXcomMapBlock>.Create(True);
  FName := AName;
  FScript := 'DEFAULT';
  FAmbience := -1;
  FAmbientVolume := DEFAULT_AMBIENT_VOLUME;
  FCivilianTypes := TArray<string>.Create('MALE_CIVILIAN', 'FEMALE_CIVILIAN');
end;

destructor TXcomRuleTerrain.Destroy;
begin
  FMapBlocks.Free;
  FMapDataSets.Free;
  inherited Destroy;
end;

procedure TXcomRuleTerrain.Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets;
  const AMapDataSets: TXcomRuleRegistry<TXcomMapDataSet>);
var
  LField, LItem: IYamlNode;
  LBlock: TXcomMapBlock;
begin
  LField := TXcomNodeReader.Field(ANode, 'mapDataSets');
  if LField.IsDefined then
  begin
    FMapDataSets.Clear;
    for LItem in LField.Items do
      FMapDataSets.Add(AMapDataSets.GetOrCreate(TXcomNodeReader.TextOf(LItem)));
  end;
  LField := TXcomNodeReader.Field(ANode, 'mapBlocks');
  if LField.IsDefined then
  begin
    FMapBlocks.Clear;
    for LItem in LField.Items do
    begin
      LBlock := TXcomMapBlock.Create(TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'name')));
      FMapBlocks.Add(LBlock);
      LBlock.Load(LItem);
    end;
  end;
  FName := TXcomNodeReader.ReadString(ANode, 'name', FName);
  LField := TXcomNodeReader.Field(ANode, 'civilianTypes');
  if LField.IsDefined then
    FCivilianTypes := TXcomNodeReader.ReadStrings(ANode, 'civilianTypes', FCivilianTypes);
  for LItem in TXcomNodeReader.Field(ANode, 'music').Items do
  begin
    SetLength(FMusic, Length(FMusic) + 1);
    // (*i).as<std::string>(""): an item that is not a scalar gives ""
    FMusic[High(FMusic)] := TXcomNodeReader.TextOf(LItem, '');
  end;
  LField := TXcomNodeReader.Field(ANode, 'depth');
  if LField.IsDefined then
  begin
    // node["depth"][0] of a const node: a missing item is an undefined node and gives the default
    FMinDepth := LField.Find(0).AsInteger(FMinDepth);
    FMaxDepth := LField.Find(1).AsInteger(FMaxDepth);
  end;
  AOffsets.LoadSoundOffset(FName, FAmbience, TXcomNodeReader.Field(ANode, 'ambience'), 'BATTLE.CAT');
  FAmbientVolume := TXcomNodeReader.ReadDouble(ANode, 'ambientVolume', FAmbientVolume);
  FScript := TXcomNodeReader.ReadString(ANode, 'script', FScript);
end;

end.
