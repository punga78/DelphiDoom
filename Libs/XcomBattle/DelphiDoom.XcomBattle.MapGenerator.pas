{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the map of a battle (the map script)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.MapGenerator;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.McdPatch,
  DelphiDoom.XcomMod.MapScript, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleInventory,
  DelphiDoom.XcomMod.RuleTerrain, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomMod.RuleUfo,
  DelphiDoom.XcomSave.Node, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.GeneratorState;

const
  /// <summary>Node::CRAFTSEGMENT and Node::UFOSEGMENT</summary>
  NODE_CRAFT_SEGMENT = 1000;
  NODE_UFO_SEGMENT = 2000;
  /// <summary>MapBlockType</summary>
  BLOCK_LANDINGZONE = 1;
  BLOCK_EWROAD = 2;
  BLOCK_NSROAD = 3;
  BLOCK_CROSSING = 4;
  /// <summary>SpecialTileType</summary>
  SPECIAL_START_POINT = 1;

type
  /// <summary>
  ///   Builds the map of a battle out of the blocks of a terrain, as the commands of a map script say (the map
  ///   part of BattlescapeGenerator: generateMap, the blocks, lines, craft and UFO, tunnels, the base of a base
  ///   defense, and the nodes of every block)
  /// </summary>
  TXcomMapGenerator = class
  strict private
    FState: TXcomGeneratorState;
    FBlocks: TArray<TArray<TXcomMapBlock>>;
    FLandingZone: TArray<TArray<Boolean>>;
    FSegments: TArray<TArray<Integer>>;
    FDrillMap: TArray<TArray<Integer>>;
    FBlocksToDo: Integer;
    FDummy: TXcomMapBlock;
    FUfoPositions: TList<TXcomScriptRect>;
    procedure Init(AResetTerrain: Boolean);
    function LoadMap(const ABlock: TXcomMapBlock; AXOffset, AYOffset: Integer; const ATerrain: TXcomRuleTerrain;
      AMapDataSetOffset: Integer; ADiscovered: Boolean = False; ACraft: Boolean = False): Integer;
    procedure LoadRoutes(const ABlock: TXcomMapBlock; AXOffset, AYOffset, ASegment: Integer);
    procedure GenerateBaseMap;
    procedure ClearModule(AX, AY, ASizeX, ASizeY: Integer);
    procedure LoadNodes;
    procedure AttachNodeLinks;
    function SelectPosition(const ARects: TArray<TXcomScriptRect>; out AX, AY: Integer;
      ASizeX, ASizeY: Integer): Boolean;
    function AddCraft(const ACraftMap: TXcomMapBlock; const ACommand: TXcomMapScript;
      var ACraftPos: TXcomScriptRect): Boolean;
    function AddLine(ADirection: Integer; const ARects: TArray<TXcomScriptRect>): Boolean;
    function AddBlock(AX, AY: Integer; const ABlock: TXcomMapBlock): Boolean;
    procedure DrillModules(const AData: TXcomTunnelData; const ARects: TArray<TXcomScriptRect>; ADirection: Integer);
    function RemoveBlocks(const ACommand: TXcomMapScript): Boolean;
    function ModuleData(const AReplacement: TXcomMcdReplacement): TXcomMapData;
    procedure LoadTerrainSets(const ATerrain: TXcomRuleTerrain);
    class function InGroups(const ABlock: TXcomMapBlock; const AGroups: TArray<Integer>): Boolean; static;
  public
    constructor Create(const AState: TXcomGeneratorState);
    destructor Destroy; override;
    /// <summary>generateMap: the tiles, the map data sets, the nodes of the blocks and the craft and UFO</summary>
    procedure Generate(const AScript: TObjectList<TXcomMapScript>);
  end;

implementation

const
  SMapFileNotFound = '%s not found';
  SMapTooHigh = 'Height of map %s too big for this mission, block is %d, expected: %d';
  SMapWrongSize = 'Map block is not of the size specified %s is %dx%d , expected: %dx%d';
  SBaseWrong = 'Something is wrong with your base, check your log file for additional information.';
  SCraftTooTall = 'Something is wrong in your map definitions, craft/ufo map is too tall?';
  SInvalidMap = 'Invalid MAP file: %s';
  SInvalidRoutes = 'Invalid RMP file: %s';
  SMapTooFar = 'MAP file %s has more tiles than its size says';
  SSharedLabel = 'Map generator encountered an error: multiple commands are sharing the same label.';
  SMissingLabel =
    'Map generator encountered an error: conditional command expected a label that did not exist before this command.';
  SResizeBase = 'Map Generator encountered an error: Base defense map cannot be resized.';
  SResizeAfter = 'Map Generator encountered an error: One does not simply resize the map after adding blocks.';
  SNotGenerated = 'Map failed to fully generate.';
  SNoBlock = 'Map generator encountered an error: the script has no block to put on the map.';
  SNoModule = 'Map generator encountered an error: base module %s not found.';

{ TXcomMapGenerator }

constructor TXcomMapGenerator.Create(const AState: TXcomGeneratorState);
begin
  inherited Create;
  FState := AState;
  FUfoPositions := TList<TXcomScriptRect>.Create;
end;

destructor TXcomMapGenerator.Destroy;
begin
  FUfoPositions.Free;
  FDummy.Free;
  inherited Destroy;
end;

procedure TXcomMapGenerator.Init(AResetTerrain: Boolean);
var
  LColumns: Integer;
  LRows: Integer;
  LColumn: Integer;
  LRow: Integer;
begin
  LColumns := FState.MapSizeX div 10;
  LRows := FState.MapSizeY div 10;
  SetLength(FBlocks, LColumns);
  SetLength(FLandingZone, LColumns);
  SetLength(FSegments, LColumns);
  SetLength(FDrillMap, LColumns);
  for LColumn := 0 to LColumns - 1 do
  begin
    SetLength(FBlocks[LColumn], LRows);
    SetLength(FLandingZone[LColumn], LRows);
    SetLength(FSegments[LColumn], LRows);
    SetLength(FDrillMap[LColumn], LRows);
    for LRow := 0 to LRows - 1 do
    begin
      FBlocks[LColumn][LRow] := nil;
      FLandingZone[LColumn][LRow] := False;
      FSegments[LColumn][LRow] := 0;
      FDrillMap[LColumn][LRow] := TXcomMapScript.MD_NONE;
    end;
  end;
  FBlocksToDo := LColumns * LRows;
  FState.Save.InitMap(FState.MapSizeX, FState.MapSizeY, FState.MapSizeZ, AResetTerrain);
end;

class function TXcomMapGenerator.InGroups(const ABlock: TXcomMapBlock; const AGroups: TArray<Integer>): Boolean;
var
  LGroup: Integer;
begin
  for LGroup in AGroups do
    if ABlock.IsInGroup(LGroup) then
      Exit(True);
  Result := False;
end;

function TXcomMapGenerator.ModuleData(const AReplacement: TXcomMcdReplacement): TXcomMapData;
begin
  Result := FState.Terrain.MapDataSets[AReplacement.TileSet].GetObject(AReplacement.Entry);
end;

procedure TXcomMapGenerator.LoadTerrainSets(const ATerrain: TXcomRuleTerrain);
var
  LSet: TXcomMapDataSet;
  LPatch: TXcomMcdPatch;
begin
  for LSet in ATerrain.MapDataSets do
  begin
    if not FState.Ruleset.McdPatches.TryGetValue(LSet.Name, LPatch) then
      LPatch := nil;
    FState.MapLoader.LoadData(LSet, LPatch);
    FState.Save.MapDataSets.Add(LSet);
  end;
end;

function TXcomMapGenerator.LoadMap(const ABlock: TXcomMapBlock; AXOffset, AYOffset: Integer;
  const ATerrain: TXcomRuleTerrain; AMapDataSetOffset: Integer; ADiscovered, ACraft: Boolean): Integer;
var
  LBytes: TBytes;
  LName: string;
  LSizeX: Integer;
  LSizeY: Integer;
  LSizeZ: Integer;
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LLevel: Integer;
  LOffset: Integer;
  LPart: Integer;
  LObjectId: Cardinal;
  LMapDataId: Cardinal;
  LMapDataSetId: Integer;
  LData: TXcomMapData;
  LTile: TXcomTile;
  LPair: Integer;
  LRules: TXcomRuleItem;
  LPositions: TArray<TXcomPosition>;
  LPosition: TXcomPosition;
  LItem: TXcomBattleItem;
  LGround: TXcomRuleInventory;
begin
  LName := 'MAPS/' + ABlock.Name + '.MAP';
  try
    LBytes := FState.Files.LoadBytes(LName);
  except
    on E: Exception do
      raise EXcomBattleException.CreateFmt(SMapFileNotFound, [LName]);
  end;
  if Length(LBytes) < 3 then
    raise EXcomBattleException.CreateFmt(SInvalidMap, [LName]);
  LSizeY := ShortInt(LBytes[0]);
  LSizeX := ShortInt(LBytes[1]);
  LSizeZ := ShortInt(LBytes[2]);
  ABlock.SizeZ := LSizeZ;
  if LSizeZ > FState.Save.MapSizeZ then
    raise EXcomBattleException.CreateFmt(SMapTooHigh, [LName, LSizeZ, FState.Save.MapSizeZ]);
  if (LSizeX <> ABlock.SizeX) or (LSizeY <> ABlock.SizeY) then
    raise EXcomBattleException.CreateFmt(SMapWrongSize, [LName, LSizeX, LSizeY, ABlock.SizeX, ABlock.SizeY]);
  LX := AXOffset;
  LY := AYOffset;
  LZ := LSizeZ - 1;
  for LLevel := FState.MapSizeZ - 1 downto 1 do
  begin
    if Assigned(FState.Save.TileAt(TXcomPosition.Make(LX, LY, LLevel)).MapData[XCOM_PART_FLOOR]) then
    begin
      Inc(LZ, LLevel);
      if ACraft then
        FState.CraftZ := LLevel;
      Break;
    end;
  end;
  if LZ > FState.Save.MapSizeZ - 1 then
  begin
    if FState.Save.MissionType = 'STR_BASE_DEFENSE' then
      raise EXcomBattleException.Create(SBaseWrong);
    raise EXcomBattleException.Create(SCraftTooTall);
  end;
  LOffset := 3;
  while LOffset + 4 <= Length(LBytes) do
  begin
    LTile := FState.Save.TileAt(TXcomPosition.Make(LX, LY, LZ));
    if not Assigned(LTile) then
      raise EXcomBattleException.CreateFmt(SMapTooFar, [LName]);
    for LPart := XCOM_PART_FLOOR to XCOM_PART_OBJECT do
    begin
      LObjectId := LBytes[LOffset + LPart];
      if LObjectId > 0 then
      begin
        LMapDataSetId := AMapDataSetOffset;
        LMapDataId := LObjectId;
        LData := ATerrain.GetMapData(LMapDataId, LMapDataSetId);
        if AMapDataSetOffset > 0 then
          LTile.SetMapData(nil, -1, -1, XCOM_PART_OBJECT);
        LTile.SetMapData(LData, Integer(LMapDataId), LMapDataSetId, LPart);
      end;
    end;
    LTile.SetDiscovered(ADiscovered or ABlock.IsFloorRevealed(LZ), 2);
    Inc(LOffset, 4);
    Inc(LX);
    if LX = LSizeX + AXOffset then
    begin
      LX := AXOffset;
      Inc(LY);
    end;
    if LY = LSizeY + AYOffset then
    begin
      LY := AYOffset;
      Dec(LZ);
    end;
  end;
  if FState.GenerateFuel then
    FState.GenerateFuel := ABlock.Items.Count = 0;
  LGround := FState.Equipper.Inventory('STR_GROUND');
  for LPair := 0 to ABlock.Items.Count - 1 do
  begin
    LRules := FState.ItemRules(ABlock.Items.Key(LPair));
    LPositions := ABlock.Items.Value(LPair);
    for LPosition in LPositions do
    begin
      LItem := FState.NewItem(LRules);
      FState.Save.Items.Add(LItem);
      FState.Save.TileAt(LPosition + TXcomPosition.Make(AXOffset, AYOffset, 0)).AddItem(LItem, LGround);
    end;
  end;
  Result := LSizeZ;
end;

procedure TXcomMapGenerator.LoadRoutes(const ABlock: TXcomMapBlock; AXOffset, AYOffset, ASegment: Integer);
const
  RECORD_SIZE = 24;
var
  LBytes: TBytes;
  LName: string;
  LOffset: Integer;
  LNodeOffset: Integer;
  LBadNodes: TList<Integer>;
  LNodesAdded: Integer;
  LNode: TXcomNode;
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LLink: Integer;
  LConnect: Integer;
  LLinks: TArray<Integer>;
  LBad: Integer;
  LCounter: Integer;
  LIndex: Integer;
  LLinkIndex: Integer;
begin
  LName := 'ROUTES/' + ABlock.Name + '.RMP';
  try
    LBytes := FState.Files.LoadBytes(LName);
  except
    on E: Exception do
      raise EXcomBattleException.CreateFmt(SMapFileNotFound, [LName]);
  end;
  LNodeOffset := FState.Save.Nodes.Count;
  LBadNodes := TList<Integer>.Create;
  try
    LNodesAdded := 0;
    LOffset := 0;
    while LOffset + RECORD_SIZE <= Length(LBytes) do
    begin
      LX := LBytes[LOffset + 1];
      LY := LBytes[LOffset];
      LZ := LBytes[LOffset + 2];
      if (LX >= 0) and (LX < ABlock.SizeX) and (LY >= 0) and (LY < ABlock.SizeY) and (LZ >= 0) and
        (LZ < ABlock.SizeZ) then
      begin
        LNode := TXcomNode.Create(FState.Save.Nodes.Count,
          TXcomPosition.Make(AXOffset + LX, AYOffset + LY, ABlock.SizeZ - 1 - LZ), ASegment,
          LBytes[LOffset + 19], LBytes[LOffset + 20], LBytes[LOffset + 21], LBytes[LOffset + 22],
          LBytes[LOffset + 23]);
        SetLength(LLinks, 0);
        for LLink := 0 to 4 do
        begin
          LConnect := LBytes[LOffset + 4 + LLink * 3];
          if LConnect <= 250 then
            Inc(LConnect, LNodeOffset)
          else
            Dec(LConnect, 256);
          SetLength(LLinks, Length(LLinks) + 1);
          LLinks[High(LLinks)] := LConnect;
        end;
        LNode.Links := LLinks;
      end
      else
      begin
        LNode := TXcomNode.Create;
        LNode.Dummy := True;
        LBadNodes.Add(LNodesAdded);
      end;
      FState.Save.Nodes.Add(LNode);
      Inc(LNodesAdded);
      Inc(LOffset, RECORD_SIZE);
    end;
    // the links to a node that was dropped end (the C++ looks at the last nodesAdded nodes of the list)
    for LBad in LBadNodes do
    begin
      LCounter := LNodesAdded;
      LIndex := FState.Save.Nodes.Count - 1;
      while (LIndex >= 0) and (LCounter > 0) do
      begin
        LNode := FState.Save.Nodes[LIndex];
        if not LNode.Dummy then
        begin
          LLinks := LNode.Links;
          for LLinkIndex := 0 to High(LLinks) do
            if Cardinal(LLinks[LLinkIndex]) - Cardinal(LNodeOffset) = Cardinal(LBad) then
              LLinks[LLinkIndex] := -1;
        end;
        Dec(LCounter);
        Dec(LIndex);
      end;
    end;
  finally
    LBadNodes.Free;
  end;
end;

procedure TXcomMapGenerator.GenerateBaseMap;
var
  LFacility: TXcomBaseFacility;
  LRules: TXcomRuleBaseFacility;
  LNumber: Integer;
  LXLimit: Integer;
  LYLimit: Integer;
  LX: Integer;
  LY: Integer;
  LMapName: string;
  LNewName: string;
  LMapNumber: Integer;
  LGroundLevel: Integer;
  LK: Integer;
  LL: Integer;
  LTile: TXcomTile;
  LEast: TXcomTile;
  LSouth: TXcomTile;
  LBlock: TXcomMapBlock;
begin
  for LFacility in FState.Base.Facilities do
  begin
    if LFacility.BuildTime = 0 then
    begin
      LRules := FState.Ruleset.Facilities.Find(LFacility.Rules.FacilityType);
      LNumber := 0;
      LXLimit := LFacility.X + LRules.Size - 1;
      LYLimit := LFacility.Y + LRules.Size - 1;
      for LY := LFacility.Y to LYLimit do
      begin
        for LX := LFacility.X to LXLimit do
        begin
          LMapName := LRules.MapName;
          LNewName := Copy(LMapName, 1, Length(LMapName) - 2);
          LMapNumber := StrToIntDef(Copy(LMapName, Length(LMapName) - 1, 2), 0);
          Inc(LMapNumber, LNumber);
          if LMapNumber < 10 then
            LNewName := LNewName + '0';
          LNewName := LNewName + IntToStr(LMapNumber);
          LBlock := FState.Terrain.GetMapBlock(LNewName);
          if not Assigned(LBlock) then
            raise EXcomBattleException.CreateFmt(SNoModule, [LNewName]);
          AddBlock(LX, LY, LBlock);
          FDrillMap[LX][LY] := TXcomMapScript.MD_NONE;
          Inc(LNumber);
          if LRules.Storage > 0 then
          begin
            LGroundLevel := FState.MapSizeZ - 1;
            while LGroundLevel >= 0 do
            begin
              if not FState.Save.TileAt(TXcomPosition.Make(LX * 10, LY * 10, LGroundLevel)).HasNoFloor(nil) then
                Break;
              Dec(LGroundLevel);
            end;
            for LK := LX * 10 to (LX + 1) * 10 - 1 do
            begin
              for LL := LY * 10 to (LY + 1) * 10 - 1 do
              begin
                if (LK + LL) mod 2 = 0 then
                begin
                  LTile := FState.Save.TileAt(TXcomPosition.Make(LK, LL, LGroundLevel));
                  LEast := FState.Save.TileAt(TXcomPosition.Make(LK + 1, LL, LGroundLevel));
                  LSouth := FState.Save.TileAt(TXcomPosition.Make(LK, LL + 1, LGroundLevel));
                  if Assigned(LTile) and Assigned(LTile.MapData[XCOM_PART_FLOOR]) and
                    (not Assigned(LTile.MapData[XCOM_PART_OBJECT])) and Assigned(LEast) and
                    (not Assigned(LEast.MapData[XCOM_PART_WESTWALL])) and Assigned(LSouth) and
                    (not Assigned(LSouth.MapData[XCOM_PART_NORTHWALL])) then
                    FState.Save.StorageSpace.Add(TXcomPosition.Make(LK, LL, LGroundLevel));
                end;
              end;
            end;
            if not Assigned(FState.CraftInventoryTile) then
              FState.CraftInventoryTile := FState.Save.TileAt(TXcomPosition.Make(LX * 10 + 5, LY * 10 + 5,
                LGroundLevel - 1));
          end;
        end;
      end;
      for LX := LFacility.X to LXLimit do
        FDrillMap[LX][LYLimit] := TXcomMapScript.MD_VERTICAL;
      for LY := LFacility.Y to LYLimit do
        FDrillMap[LXLimit][LY] := TXcomMapScript.MD_HORIZONTAL;
      FDrillMap[LXLimit][LYLimit] := TXcomMapScript.MD_BOTH;
    end;
  end;
  FState.Save.CalculateModuleMap;
end;

procedure TXcomMapGenerator.ClearModule(AX, AY, ASizeX, ASizeY: Integer);
var
  LZ: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;
  LTile: TXcomTile;
  LPart: Integer;
begin
  for LZ := 0 to FState.MapSizeZ - 1 do
    for LDeltaX := AX to AX + ASizeX - 1 do
      for LDeltaY := AY to AY + ASizeY - 1 do
      begin
        LTile := FState.Save.TileAt(TXcomPosition.Make(LDeltaX, LDeltaY, LZ));
        for LPart := XCOM_PART_FLOOR to XCOM_PART_OBJECT do
          LTile.SetMapData(nil, -1, -1, LPart);
      end;
end;

procedure TXcomMapGenerator.LoadNodes;
var
  LSegment: Integer;
  LY: Integer;
  LX: Integer;
begin
  LSegment := 0;
  for LY := 0 to FState.MapSizeY div 10 - 1 do
    for LX := 0 to FState.MapSizeX div 10 - 1 do
    begin
      FSegments[LX][LY] := LSegment;
      if Assigned(FBlocks[LX][LY]) and (FBlocks[LX][LY] <> FDummy) then
      begin
        if not (FBlocks[LX][LY].IsInGroup(BLOCK_LANDINGZONE) and FLandingZone[LX][LY]) then
        begin
          LoadRoutes(FBlocks[LX][LY], LX * 10, LY * 10, LSegment);
          Inc(LSegment);
        end;
      end;
    end;
end;

procedure TXcomMapGenerator.AttachNodeLinks;
const
  NEIGHBOUR_DIRECTIONS: array[0..3] of Integer = (-2, -3, -4, -5);
  NEIGHBOUR_DIRECTIONS_INVERTED: array[0..3] of Integer = (-4, -5, -2, -3);
var
  LNode: TXcomNode;
  LOther: TXcomNode;
  LSegmentX: Integer;
  LSegmentY: Integer;
  LNeighbour: array[0..3] of Integer;
  LJ: Integer;
  LN: Integer;
  LL: Integer;
begin
  for LNode in FState.Save.Nodes do
  begin
    if LNode.Dummy then
      Continue;
    LSegmentX := LNode.Position.X div 10;
    LSegmentY := LNode.Position.Y div 10;
    if LSegmentX = FState.MapSizeX div 10 - 1 then
      LNeighbour[0] := -1
    else
      LNeighbour[0] := FSegments[LSegmentX + 1][LSegmentY];
    if LSegmentY = FState.MapSizeY div 10 - 1 then
      LNeighbour[1] := -1
    else
      LNeighbour[1] := FSegments[LSegmentX][LSegmentY + 1];
    if LSegmentX = 0 then
      LNeighbour[2] := -1
    else
      LNeighbour[2] := FSegments[LSegmentX - 1][LSegmentY];
    if LSegmentY = 0 then
      LNeighbour[3] := -1
    else
      LNeighbour[3] := FSegments[LSegmentX][LSegmentY - 1];
    for LJ := 0 to High(LNode.Links) do
      for LN := 0 to 3 do
        if LNode.Links[LJ] = NEIGHBOUR_DIRECTIONS[LN] then
          for LOther in FState.Save.Nodes do
          begin
            if LOther.Dummy then
              Continue;
            if LOther.Segment = LNeighbour[LN] then
              for LL := 0 to High(LOther.Links) do
                if LOther.Links[LL] = NEIGHBOUR_DIRECTIONS_INVERTED[LN] then
                begin
                  LOther.Links[LL] := LNode.Id;
                  LNode.Links[LJ] := LOther.Id;
                end;
          end;
  end;
end;

function TXcomMapGenerator.SelectPosition(const ARects: TArray<TXcomScriptRect>; out AX, AY: Integer;
  ASizeX, ASizeY: Integer): Boolean;
var
  LAvailable: TArray<TXcomScriptRect>;
  LWhole: TXcomScriptRect;
  LRect: TXcomScriptRect;
  LValid: TList<TPair<Integer, Integer>>;
  LX: Integer;
  LY: Integer;
  LCheckX: Integer;
  LCheckY: Integer;
  LAdd: Boolean;
  LIndex: Integer;
  LFound: Boolean;
  LSelection: TPair<Integer, Integer>;
begin
  AX := 0;
  AY := 0;
  LWhole.X := 0;
  LWhole.Y := 0;
  LWhole.W := FState.MapSizeX div 10;
  LWhole.H := FState.MapSizeY div 10;
  ASizeX := ASizeX div 10;
  ASizeY := ASizeY div 10;
  if Length(ARects) = 0 then
  begin
    SetLength(LAvailable, 1);
    LAvailable[0] := LWhole;
  end
  else
    LAvailable := ARects;
  LValid := TList<TPair<Integer, Integer>>.Create;
  try
    for LRect in LAvailable do
    begin
      if (ASizeX > LRect.W) or (ASizeY > LRect.H) then
        Continue;
      LX := LRect.X;
      while (LX + ASizeX <= LRect.X + LRect.W) and (LX + ASizeX <= LWhole.W) do
      begin
        LY := LRect.Y;
        while (LY + ASizeY <= LRect.Y + LRect.H) and (LY + ASizeY <= LWhole.H) do
        begin
          LFound := False;
          for LIndex := 0 to LValid.Count - 1 do
            if (LValid[LIndex].Key = LX) and (LValid[LIndex].Value = LY) then
            begin
              LFound := True;
              Break;
            end;
          if not LFound then
          begin
            LAdd := True;
            for LCheckX := LX to LX + ASizeX - 1 do
              for LCheckY := LY to LY + ASizeY - 1 do
                if Assigned(FBlocks[LCheckX][LCheckY]) then
                  LAdd := False;
            if LAdd then
              LValid.Add(TPair<Integer, Integer>.Create(LX, LY));
          end;
          Inc(LY);
        end;
        Inc(LX);
      end;
    end;
    if LValid.Count = 0 then
      Exit(False);
    LSelection := LValid[FState.Random.Generate(0, LValid.Count - 1)];
    AX := LSelection.Key;
    AY := LSelection.Value;
    Result := True;
  finally
    LValid.Free;
  end;
end;

function TXcomMapGenerator.AddCraft(const ACraftMap: TXcomMapBlock; const ACommand: TXcomMapScript;
  var ACraftPos: TXcomScriptRect): Boolean;
var
  LX: Integer;
  LY: Integer;
  LBlock: TXcomMapBlock;
begin
  ACraftPos.W := ACraftMap.SizeX;
  ACraftPos.H := ACraftMap.SizeY;
  Result := SelectPosition(ACommand.Rects, LX, LY, ACraftPos.W, ACraftPos.H);
  if Result then
  begin
    ACraftPos.X := LX;
    ACraftPos.Y := LY;
    ACraftPos.W := ACraftPos.W div 10;
    ACraftPos.H := ACraftPos.H div 10;
    for LX := 0 to ACraftPos.W - 1 do
      for LY := 0 to ACraftPos.H - 1 do
      begin
        FLandingZone[ACraftPos.X + LX][ACraftPos.Y + LY] := True;
        LBlock := ACommand.GetNextBlock(FState.Terrain, FState.Random);
        if Assigned(LBlock) and (not Assigned(FBlocks[ACraftPos.X + LX][ACraftPos.Y + LY])) then
        begin
          FBlocks[ACraftPos.X + LX][ACraftPos.Y + LY] := LBlock;
          Dec(FBlocksToDo);
        end;
      end;
  end;
end;

function TXcomMapGenerator.AddLine(ADirection: Integer; const ARects: TArray<TXcomScriptRect>): Boolean;
var
  LTries: Integer;
  LPlaced: Boolean;
  LRoadX: Integer;
  LRoadY: Integer;
  LComparator: Integer;
  LTypeToAdd: Integer;
  LLimit: Integer;
  LVertical: Boolean;
  LIterator: Integer;
begin
  if ADirection = TXcomMapScript.MD_BOTH then
  begin
    if AddLine(TXcomMapScript.MD_VERTICAL, ARects) then
    begin
      AddLine(TXcomMapScript.MD_HORIZONTAL, ARects);
      Exit(True);
    end;
    Exit(False);
  end;
  LTries := 0;
  LPlaced := False;
  LRoadX := 0;
  LRoadY := 0;
  LComparator := BLOCK_NSROAD;
  LTypeToAdd := BLOCK_EWROAD;
  LLimit := FState.MapSizeX div 10;
  LVertical := ADirection = TXcomMapScript.MD_VERTICAL;
  if LVertical then
  begin
    LComparator := BLOCK_EWROAD;
    LTypeToAdd := BLOCK_NSROAD;
    LLimit := FState.MapSizeY div 10;
  end;
  while not LPlaced do
  begin
    SelectPosition(ARects, LRoadX, LRoadY, 10, 10);
    LPlaced := True;
    for LIterator := 0 to LLimit - 1 do
    begin
      if LVertical then
        LRoadY := LIterator
      else
        LRoadX := LIterator;
      if Assigned(FBlocks[LRoadX][LRoadY]) and (not FBlocks[LRoadX][LRoadY].IsInGroup(LComparator)) then
      begin
        LPlaced := False;
        Break;
      end;
    end;
    Inc(LTries);
    if LTries - 1 > 20 then
      Exit(False);
  end;
  for LIterator := 0 to LLimit - 1 do
  begin
    if LVertical then
      LRoadY := LIterator
    else
      LRoadX := LIterator;
    if not Assigned(FBlocks[LRoadX][LRoadY]) then
      AddBlock(LRoadX, LRoadY, FState.Terrain.GetRandomMapBlock(10, 10, LTypeToAdd, FState.Random))
    else if FBlocks[LRoadX][LRoadY].IsInGroup(LComparator) then
    begin
      FBlocks[LRoadX][LRoadY] := FState.Terrain.GetRandomMapBlock(10, 10, BLOCK_CROSSING, FState.Random);
      ClearModule(LRoadX * 10, LRoadY * 10, 10, 10);
      LoadMap(FBlocks[LRoadX][LRoadY], LRoadX * 10, LRoadY * 10, FState.Terrain, 0);
    end;
  end;
  Result := True;
end;

function TXcomMapGenerator.AddBlock(AX, AY: Integer; const ABlock: TXcomMapBlock): Boolean;
var
  LSizeX: Integer;
  LSizeY: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;
  LVisible: Boolean;
begin
  if not Assigned(ABlock) then
    raise EXcomBattleException.Create(SNoBlock);
  LSizeX := (ABlock.SizeX - 1) div 10;
  LSizeY := (ABlock.SizeY - 1) div 10;
  // the second loop stops one row short, as in the C++
  for LDeltaX := 0 to LSizeX do
    for LDeltaY := 0 to LSizeY - 1 do
      if Assigned(FBlocks[AX + LDeltaX][AY + LDeltaY]) then
        Exit(False);
  for LDeltaX := 0 to LSizeX do
    for LDeltaY := 0 to LSizeY do
    begin
      FBlocks[AX + LDeltaX][AY + LDeltaY] := FDummy;
      Dec(FBlocksToDo);
    end;
  for LDeltaX := 0 to LSizeX do
    FDrillMap[AX + LDeltaX][AY + LSizeY] := TXcomMapScript.MD_VERTICAL;
  for LDeltaY := 0 to LSizeY do
    FDrillMap[AX + LSizeX][AY + LDeltaY] := TXcomMapScript.MD_HORIZONTAL;
  FDrillMap[AX + LSizeX][AY + LSizeY] := TXcomMapScript.MD_BOTH;
  FBlocks[AX][AY] := ABlock;
  LVisible := FState.Save.MissionType = 'STR_BASE_DEFENSE';
  LoadMap(FBlocks[AX][AY], AX * 10, AY * 10, FState.Terrain, 0, LVisible);
  Result := True;
end;

procedure TXcomMapGenerator.DrillModules(const AData: TXcomTunnelData; const ARects: TArray<TXcomScriptRect>;
  ADirection: Integer);
var
  LWestWall: TXcomMcdReplacement;
  LNorthWall: TXcomMcdReplacement;
  LCorner: TXcomMcdReplacement;
  LFloor: TXcomMcdReplacement;
  LHasWestWall: Boolean;
  LHasNorthWall: Boolean;
  LHasCorner: Boolean;
  LHasFloor: Boolean;
  LRect: TXcomScriptRect;
  LI: Integer;
  LJ: Integer;
  LK: Integer;
  LData: TXcomMapData;
  LTile: TXcomTile;
  LObject: TXcomMapData;
begin
  LHasWestWall := AData.Replacements.TryGetValue('westWall', LWestWall);
  LHasNorthWall := AData.Replacements.TryGetValue('northWall', LNorthWall);
  LHasCorner := AData.Replacements.TryGetValue('corner', LCorner);
  LHasFloor := AData.Replacements.TryGetValue('floor', LFloor);
  LRect.X := 3;
  LRect.Y := 3;
  LRect.W := 3;
  LRect.H := 3;
  if Length(ARects) > 0 then
    LRect := ARects[0];
  for LI := 0 to FState.MapSizeX div 10 - 1 do
  begin
    for LJ := 0 to FState.MapSizeY div 10 - 1 do
    begin
      if not Assigned(FBlocks[LI][LJ]) then
        Continue;
      if ADirection <> TXcomMapScript.MD_VERTICAL then
      begin
        if (LI < FState.MapSizeX div 10 - 1) and
          ((FDrillMap[LI][LJ] = TXcomMapScript.MD_HORIZONTAL) or (FDrillMap[LI][LJ] = TXcomMapScript.MD_BOTH)) and
          Assigned(FBlocks[LI + 1][LJ]) then
        begin
          for LK := LRect.Y to LRect.Y + LRect.H - 1 do
          begin
            LTile := FState.Save.TileAt(TXcomPosition.Make(LI * 10 + 9, LJ * 10 + LK, AData.Level));
            if Assigned(LTile) then
            begin
              LTile.SetMapData(nil, -1, -1, XCOM_PART_WESTWALL);
              LTile.SetMapData(nil, -1, -1, XCOM_PART_OBJECT);
              if LHasFloor then
              begin
                LData := ModuleData(LFloor);
                LTile.SetMapData(LData, LFloor.Entry, LFloor.TileSet, XCOM_PART_FLOOR);
              end;
              LTile := FState.Save.TileAt(TXcomPosition.Make((LI + 1) * 10, LJ * 10 + LK, AData.Level));
              LTile.SetMapData(nil, -1, -1, XCOM_PART_WESTWALL);
              LObject := LTile.MapData[XCOM_PART_OBJECT];
              if Assigned(LObject) and (LObject.GetTuCost(MT_WALK) = 0) then
                LTile.SetMapData(nil, -1, -1, XCOM_PART_OBJECT);
            end;
          end;
          if LHasNorthWall then
          begin
            LData := ModuleData(LNorthWall);
            LTile := FState.Save.TileAt(TXcomPosition.Make(LI * 10 + 9, LJ * 10 + LRect.Y, AData.Level));
            LTile.SetMapData(LData, LNorthWall.Entry, LNorthWall.TileSet, XCOM_PART_NORTHWALL);
            LTile := FState.Save.TileAt(TXcomPosition.Make(LI * 10 + 9, LJ * 10 + LRect.Y + LRect.H, AData.Level));
            LTile.SetMapData(LData, LNorthWall.Entry, LNorthWall.TileSet, XCOM_PART_NORTHWALL);
          end;
          if LHasCorner then
          begin
            LData := ModuleData(LCorner);
            LTile := FState.Save.TileAt(TXcomPosition.Make((LI + 1) * 10, LJ * 10 + LRect.Y, AData.Level));
            if not Assigned(LTile.MapData[XCOM_PART_NORTHWALL]) then
              LTile.SetMapData(LData, LCorner.Entry, LCorner.TileSet, XCOM_PART_NORTHWALL);
          end;
        end;
      end;
      if ADirection <> TXcomMapScript.MD_HORIZONTAL then
      begin
        if (LJ < FState.MapSizeY div 10 - 1) and
          ((FDrillMap[LI][LJ] = TXcomMapScript.MD_VERTICAL) or (FDrillMap[LI][LJ] = TXcomMapScript.MD_BOTH)) and
          Assigned(FBlocks[LI][LJ + 1]) then
        begin
          for LK := LRect.X to LRect.X + LRect.W - 1 do
          begin
            LTile := FState.Save.TileAt(TXcomPosition.Make(LI * 10 + LK, LJ * 10 + 9, AData.Level));
            if Assigned(LTile) then
            begin
              LTile.SetMapData(nil, -1, -1, XCOM_PART_NORTHWALL);
              LTile.SetMapData(nil, -1, -1, XCOM_PART_OBJECT);
              if LHasFloor then
              begin
                LData := ModuleData(LFloor);
                LTile.SetMapData(LData, LFloor.Entry, LFloor.TileSet, XCOM_PART_FLOOR);
              end;
              LTile := FState.Save.TileAt(TXcomPosition.Make(LI * 10 + LK, (LJ + 1) * 10, AData.Level));
              LTile.SetMapData(nil, -1, -1, XCOM_PART_NORTHWALL);
              LObject := LTile.MapData[XCOM_PART_OBJECT];
              if Assigned(LObject) and (LObject.GetTuCost(MT_WALK) = 0) then
                LTile.SetMapData(nil, -1, -1, XCOM_PART_OBJECT);
            end;
          end;
          if LHasWestWall then
          begin
            LData := ModuleData(LWestWall);
            LTile := FState.Save.TileAt(TXcomPosition.Make(LI * 10 + LRect.X, LJ * 10 + 9, AData.Level));
            LTile.SetMapData(LData, LWestWall.Entry, LWestWall.TileSet, XCOM_PART_WESTWALL);
            LTile := FState.Save.TileAt(TXcomPosition.Make(LI * 10 + LRect.X + LRect.W, LJ * 10 + 9, AData.Level));
            LTile.SetMapData(LData, LWestWall.Entry, LWestWall.TileSet, XCOM_PART_WESTWALL);
          end;
          if LHasCorner then
          begin
            LData := ModuleData(LCorner);
            LTile := FState.Save.TileAt(TXcomPosition.Make(LI * 10 + LRect.X, (LJ + 1) * 10, AData.Level));
            if not Assigned(LTile.MapData[XCOM_PART_WESTWALL]) then
              LTile.SetMapData(LData, LCorner.Entry, LCorner.TileSet, XCOM_PART_WESTWALL);
          end;
        end;
      end;
    end;
  end;
end;

function TXcomMapGenerator.RemoveBlocks(const ACommand: TXcomMapScript): Boolean;
var
  LDeleted: TList<TPair<Integer, Integer>>;
  LRect: TXcomScriptRect;
  LX: Integer;
  LY: Integer;
  LGroup: Integer;
  LBlockIndex: Integer;
  LPosition: TPair<Integer, Integer>;
  LFound: Boolean;
  LDeleteX: Integer;
  LDeleteY: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;

  procedure MarkDeleted;
  var
    LIndex: Integer;
  begin
    LFound := False;
    for LIndex := 0 to LDeleted.Count - 1 do
      if (LDeleted[LIndex].Key = LPosition.Key) and (LDeleted[LIndex].Value = LPosition.Value) then
      begin
        LFound := True;
        Break;
      end;
    if not LFound then
      LDeleted.Add(LPosition);
  end;

begin
  Result := False;
  LDeleted := TList<TPair<Integer, Integer>>.Create;
  try
    for LRect in ACommand.Rects do
    begin
      LX := LRect.X;
      while (LX <> LRect.X + LRect.W) and (LX <> FState.MapSizeX div 10) do
      begin
        LY := LRect.Y;
        while (LY <> LRect.Y + LRect.H) and (LY <> FState.MapSizeY div 10) do
        begin
          if Assigned(FBlocks[LX][LY]) and (FBlocks[LX][LY] <> FDummy) then
          begin
            LPosition := TPair<Integer, Integer>.Create(LX, LY);
            if Length(ACommand.Groups) > 0 then
            begin
              for LGroup in ACommand.Groups do
                if FBlocks[LX][LY].IsInGroup(LGroup) then
                  MarkDeleted;
            end
            else if Length(ACommand.Blocks) > 0 then
            begin
              for LBlockIndex in ACommand.Blocks do
                if Cardinal(LBlockIndex) < Cardinal(FState.Terrain.MapBlocks.Count) then
                  MarkDeleted;
            end
            else
              MarkDeleted;
          end;
          Inc(LY);
        end;
        Inc(LX);
      end;
    end;
    for LPosition in LDeleted do
    begin
      LDeleteX := LPosition.Key;
      LDeleteY := LPosition.Value;
      ClearModule(LDeleteX * 10, LDeleteY * 10, FBlocks[LDeleteX][LDeleteY].SizeX, FBlocks[LDeleteX][LDeleteY].SizeY);
      LDeltaX := FBlocks[LDeleteX][LDeleteY].SizeX div 10;
      LDeltaY := FBlocks[LDeleteX][LDeleteY].SizeY div 10;
      for LX := LDeleteX to LDeleteX + LDeltaX - 1 do
        for LY := LDeleteY to LDeleteY + LDeltaY - 1 do
        begin
          FBlocks[LX][LY] := nil;
          Inc(FBlocksToDo);
        end;
      Result := True;
    end;
  finally
    LDeleted.Free;
  end;
end;

procedure TXcomMapGenerator.Generate(const AScript: TObjectList<TXcomMapScript>);
var
  LCraftMap: TXcomMapBlock;
  LUfoMaps: TList<TXcomMapBlock>;
  LMapDataSetIdOffset: Integer;
  LCraftDataSetIdOffset: Integer;
  LConditionals: TDictionary<Integer, Boolean>;
  LUfoTerrain: TXcomRuleTerrain;
  LCommand: TXcomMapScript;
  LSuccess: Boolean;
  LExecute: Boolean;
  LCondition: Integer;
  LExecution: Integer;
  LX: Integer;
  LY: Integer;
  LBlock: TXcomMapBlock;
  LRect: TXcomScriptRect;
  LGroup: Integer;
  LBlockIndex: Integer;
  LUfoRules: TXcomRuleUfo;
  LUfoMap: TXcomMapBlock;
  LUfoPosition: TXcomScriptRect;
  LValue: Boolean;
  LIndex: Integer;
  LSet: TXcomMapDataSet;
  LPatch: TXcomMcdPatch;
  LOffset: Integer;
  LScorched: TXcomMapData;
  LBlankSet: TXcomMapDataSet;
  LKnown: Boolean;
begin
  FState.Save.Ambience := FState.Terrain.Ambience;
  FState.Save.AmbientVolume := FState.Terrain.AmbientVolume;
  FDummy := TXcomMapBlock.Create('dummy');
  Init(True);
  LCraftMap := nil;
  LUfoTerrain := nil;
  LUfoMaps := TList<TXcomMapBlock>.Create;
  LConditionals := TDictionary<Integer, Boolean>.Create;
  try
    LMapDataSetIdOffset := 0;
    LCraftDataSetIdOffset := 0;
    for LSet in FState.Terrain.MapDataSets do
    begin
      if not FState.Ruleset.McdPatches.TryGetValue(LSet.Name, LPatch) then
        LPatch := nil;
      FState.MapLoader.LoadData(LSet, LPatch);
      FState.Save.MapDataSets.Add(LSet);
      Inc(LMapDataSetIdOffset);
    end;
    if FState.Save.MissionType = 'STR_BASE_DEFENSE' then
      GenerateBaseMap;
    for LCommand in AScript do
    begin
      if (LCommand.ScriptLabel > 0) and LConditionals.ContainsKey(LCommand.ScriptLabel) then
        raise EXcomBattleException.Create(SSharedLabel);
      LSuccess := False;
      LConditionals.AddOrSetValue(LCommand.ScriptLabel, False);
      if Length(LCommand.Conditionals) > 0 then
      begin
        LExecute := True;
        for LCondition in LCommand.Conditionals do
        begin
          LKnown := LConditionals.TryGetValue(Abs(LCondition), LValue);
          if LKnown then
          begin
            if ((LCondition > 0) and (not LValue)) or ((LCondition < 0) and LValue) then
            begin
              LExecute := False;
              Break;
            end;
          end
          else
            raise EXcomBattleException.Create(SMissingLabel);
        end;
        if not LExecute then
          Continue;
      end;
      if TXcomBattleRandom.Percent(FState.Random, LCommand.ChancesOfExecution) then
      begin
        LCommand.Init;
        for LExecution := 0 to LCommand.Executions - 1 do
        begin
          LX := 0;
          LY := 0;
          case LCommand.CommandType of
            TXcomMapScript.MSC_ADDBLOCK:
              begin
                LBlock := LCommand.GetNextBlock(FState.Terrain, FState.Random);
                if Assigned(LBlock) and SelectPosition(LCommand.Rects, LX, LY, LBlock.SizeX, LBlock.SizeY) then
                  LSuccess := AddBlock(LX, LY, LBlock) or LSuccess;
              end;
            TXcomMapScript.MSC_ADDLINE:
              LSuccess := AddLine(LCommand.Direction, LCommand.Rects);
            TXcomMapScript.MSC_ADDCRAFT:
              if Assigned(FState.Craft) then
              begin
                LCraftMap := FState.Craft.Rules.BattlescapeTerrainData.GetRandomMapBlock(999, 999, 0,
                  FState.Random, False);
                if not Assigned(LCraftMap) then
                  raise EXcomBattleException.Create(SNoBlock);
                if AddCraft(LCraftMap, LCommand, FState.CraftPos) then
                begin
                  for LX := FState.CraftPos.X to FState.CraftPos.X + FState.CraftPos.W - 1 do
                    for LY := FState.CraftPos.Y to FState.CraftPos.Y + FState.CraftPos.H - 1 do
                      if Assigned(FBlocks[LX][LY]) then
                        LoadMap(FBlocks[LX][LY], LX * 10, LY * 10, FState.Terrain, 0);
                  FState.CraftDeployed := True;
                  LSuccess := True;
                end;
              end;
            TXcomMapScript.MSC_ADDUFO:
              begin
                LUfoRules := FState.Ruleset.Ufos.Find(LCommand.UfoName);
                if Assigned(LUfoRules) then
                  LUfoTerrain := LUfoRules.BattlescapeTerrainData
                else if Assigned(FState.Ufo) then
                  LUfoTerrain := FState.Ufo.Rules.BattlescapeTerrainData;
                if Assigned(LUfoTerrain) then
                begin
                  LUfoMap := LUfoTerrain.GetRandomMapBlock(999, 999, 0, FState.Random, False);
                  if not Assigned(LUfoMap) then
                    raise EXcomBattleException.Create(SNoBlock);
                  if AddCraft(LUfoMap, LCommand, LUfoPosition) then
                  begin
                    FUfoPositions.Add(LUfoPosition);
                    LUfoMaps.Add(LUfoMap);
                    for LX := LUfoPosition.X to LUfoPosition.X + LUfoPosition.W - 1 do
                      for LY := LUfoPosition.Y to LUfoPosition.Y + LUfoPosition.H - 1 do
                        if Assigned(FBlocks[LX][LY]) then
                          LoadMap(FBlocks[LX][LY], LX * 10, LY * 10, FState.Terrain, 0);
                    LSuccess := True;
                  end;
                end;
              end;
            TXcomMapScript.MSC_DIGTUNNEL:
              begin
                DrillModules(LCommand.TunnelData, LCommand.Rects, LCommand.Direction);
                LSuccess := True;
              end;
            TXcomMapScript.MSC_FILLAREA:
              begin
                LBlock := LCommand.GetNextBlock(FState.Terrain, FState.Random);
                while Assigned(LBlock) do
                begin
                  if SelectPosition(LCommand.Rects, LX, LY, LBlock.SizeX, LBlock.SizeY) then
                    LSuccess := AddBlock(LX, LY, LBlock) or LSuccess
                  else
                    Break;
                  LBlock := LCommand.GetNextBlock(FState.Terrain, FState.Random);
                end;
              end;
            TXcomMapScript.MSC_CHECKBLOCK:
              for LRect in LCommand.Rects do
              begin
                if LSuccess then
                  Break;
                LX := LRect.X;
                while (LX <> LRect.X + LRect.W) and (LX <> FState.MapSizeX div 10) and (not LSuccess) do
                begin
                  LY := LRect.Y;
                  while (LY <> LRect.Y + LRect.H) and (LY <> FState.MapSizeY div 10) and (not LSuccess) do
                  begin
                    if Length(LCommand.Groups) > 0 then
                    begin
                      for LGroup in LCommand.Groups do
                      begin
                        if LSuccess then
                          Break;
                        LSuccess := FBlocks[LX][LY].IsInGroup(LGroup);
                      end;
                    end
                    else if Length(LCommand.Blocks) > 0 then
                    begin
                      for LBlockIndex in LCommand.Blocks do
                      begin
                        if LSuccess then
                          Break;
                        if Cardinal(LBlockIndex) < Cardinal(FState.Terrain.MapBlocks.Count) then
                          LSuccess := FBlocks[LX][LY] = FState.Terrain.MapBlocks[LBlockIndex];
                      end;
                    end
                    else
                      LSuccess := Assigned(FBlocks[LX][LY]);
                    Inc(LY);
                  end;
                  Inc(LX);
                end;
              end;
            TXcomMapScript.MSC_REMOVE:
              LSuccess := RemoveBlocks(LCommand);
            TXcomMapScript.MSC_RESIZE:
              begin
                if FState.Save.MissionType = 'STR_BASE_DEFENSE' then
                  raise EXcomBattleException.Create(SResizeBase);
                if FBlocksToDo < (FState.MapSizeX div 10) * (FState.MapSizeY div 10) then
                  raise EXcomBattleException.Create(SResizeAfter);
                if (LCommand.SizeX > 0) and (LCommand.SizeX <> FState.MapSizeX div 10) then
                  FState.MapSizeX := LCommand.SizeX * 10;
                if (LCommand.SizeY > 0) and (LCommand.SizeY <> FState.MapSizeY div 10) then
                  FState.MapSizeY := LCommand.SizeY * 10;
                if (LCommand.SizeZ > 0) and (LCommand.SizeZ <> FState.MapSizeZ) then
                  FState.MapSizeZ := LCommand.SizeZ;
                Init(False);
              end;
          end;
          LConditionals.AddOrSetValue(LCommand.ScriptLabel, LSuccess);
        end;
      end;
    end;
    if FBlocksToDo <> 0 then
      raise EXcomBattleException.Create(SNotGenerated);
    LoadNodes;
    if (LUfoMaps.Count > 0) and Assigned(LUfoTerrain) then
    begin
      for LSet in LUfoTerrain.MapDataSets do
      begin
        if not FState.Ruleset.McdPatches.TryGetValue(LSet.Name, LPatch) then
          LPatch := nil;
        FState.MapLoader.LoadData(LSet, LPatch);
        FState.Save.MapDataSets.Add(LSet);
        Inc(LCraftDataSetIdOffset);
      end;
      for LIndex := 0 to LUfoMaps.Count - 1 do
      begin
        LUfoPosition := FUfoPositions[LIndex];
        LoadMap(LUfoMaps[LIndex], LUfoPosition.X * 10, LUfoPosition.Y * 10, LUfoTerrain, LMapDataSetIdOffset);
        LoadRoutes(LUfoMaps[LIndex], LUfoPosition.X * 10, LUfoPosition.Y * 10, NODE_UFO_SEGMENT);
        for LX := 0 to LUfoMaps[LIndex].SizeX div 10 - 1 do
          for LY := 0 to LUfoMaps[LIndex].SizeY div 10 - 1 do
            FSegments[LUfoPosition.X + LX][LUfoPosition.Y + LY] := NODE_UFO_SEGMENT;
      end;
    end;
    if Assigned(LCraftMap) then
    begin
      for LSet in FState.Craft.Rules.BattlescapeTerrainData.MapDataSets do
      begin
        if not FState.Ruleset.McdPatches.TryGetValue(LSet.Name, LPatch) then
          LPatch := nil;
        FState.MapLoader.LoadData(LSet, LPatch);
        FState.Save.MapDataSets.Add(LSet);
      end;
      LoadMap(LCraftMap, FState.CraftPos.X * 10, FState.CraftPos.Y * 10, FState.Craft.Rules.BattlescapeTerrainData,
        LMapDataSetIdOffset + LCraftDataSetIdOffset, True, True);
      LoadRoutes(LCraftMap, FState.CraftPos.X * 10, FState.CraftPos.Y * 10, NODE_CRAFT_SEGMENT);
      for LX := 0 to LCraftMap.SizeX div 10 - 1 do
        for LY := 0 to LCraftMap.SizeY div 10 - 1 do
          FSegments[FState.CraftPos.X + LX][FState.CraftPos.Y + LY] := NODE_CRAFT_SEGMENT;
      for LX := FState.CraftPos.X * 10 - 1 to FState.CraftPos.X * 10 + LCraftMap.SizeX do
        for LY := FState.CraftPos.Y * 10 - 1 to FState.CraftPos.Y * 10 + LCraftMap.SizeY do
          for LOffset := FState.MapSizeZ - 1 downto FState.CraftZ do
            if Assigned(FState.Save.TileAt(TXcomPosition.Make(LX, LY, LOffset))) then
              FState.Save.TileAt(TXcomPosition.Make(LX, LY, LOffset)).SetDiscovered(True, 2);
    end;
    // the scorched earth of the BLANKS set
    LScorched := nil;
    LBlankSet := FState.Ruleset.MapDataSets.Find('BLANKS');
    if Assigned(LBlankSet) then
      LScorched := LBlankSet.ScorchedEarthTile;
    FState.Save.ScorchedEarth := LScorched;
    for LX := 0 to FState.MapSizeX - 1 do
      for LY := 0 to FState.MapSizeY - 1 do
        if not Assigned(FState.Save.TileAt(TXcomPosition.Make(LX, LY, 0)).MapData[XCOM_PART_FLOOR]) then
          FState.Save.TileAt(TXcomPosition.Make(LX, LY, 0)).SetMapData(LScorched, 1, 0, XCOM_PART_FLOOR);
    AttachNodeLinks;
  finally
    LConditionals.Free;
    LUfoMaps.Free;
  end;
end;

end.
