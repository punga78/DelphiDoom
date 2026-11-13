{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of the game map with the C    }
{  of the remake on the real DATA.WAR                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapParity;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.War.Types,
  DelphiDoom.War.Intf, DelphiDoom.War.Level.Intf, DelphiDoom.War.Graphics.Intf, DelphiDoom.War.Map.Game,
  DelphiDoom.Tests.War.RealData;

type
  /// <summary>
  ///   map.maps.golden.txt, map.trees.golden.txt and map.tables.golden.txt are the output of war_map_ref.exe: the
  ///   ORIGINAL wmap_enterMap (initPathFinder, createMapAndMinimapSprites, createForestEntities, createStartingRoads,
  ///   createStartingWalls, initPlayersInfo, createStartingEntities), updateFoW, determineFoWTypes, the minimap loop of
  ///   renderMinimap, we_createUnit and war_trees.c of war1, extracted as they are, compiled with gcc and run on DATA.WAR
  ///   (Tools\Verifica\193). The levels are entered one by one; the trees are 60 scenarios of random operations
  ///   with a fixed seed
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarMapParity = class(TObject)
  private
    FLoader: IWarLevelLoader;
    FGraphics: IWarGraphics;
    FRng: Cardinal;
    function Golden(const AName: string): TStringList;
    procedure OpenData;
    function BuildMap(AIndex: Integer): TWarGameMap;
    procedure Seed(ASeed: Cardinal);
    function RngNext: Cardinal;
    function RngRange(ACount: Integer): Integer;
    function Clamp(AValue, AMin, AMax: Integer): Integer;
    function LevelsOfTheScenarios: TArray<Integer>;
    function Tail(const AMap: TWarGameMap): string;
  public
    [Test]
    procedure DovrebbeDareLeStesseImprontiDelCodiceOriginaleSuTuttiILivelli;
    [Test]
    procedure DovrebbeRifiutareIlLivelloCheIlCodiceOriginaleNonSaCreare;
    [Test]
    procedure DovrebbeDareGliStessiAlberiDelCodiceOriginaleInSessantaScenari;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Factory, DelphiDoom.War.Level.Factory, DelphiDoom.War.Level.Types,
  DelphiDoom.War.Autotile.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Forest, DelphiDoom.War.Map.Factory,
  DelphiDoom.War.Map.Builder, DelphiDoom.Tests.War.MapDump;

{ TTestWarMapParity }

function TTestWarMapParity.Golden(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TWarRealData.GoldenPath(AName));
  // an empty last line is not a line of the golden
  while (Result.Count > 0) and (Result[Result.Count - 1] = '') do
    Result.Delete(Result.Count - 1);
end;

procedure TTestWarMapParity.OpenData;
var
  LCatalog: IWarCatalog;
  LArchive: IWarArchive;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LArchive := TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog);
  FLoader := TWarLevelFactory.CreateLevelLoader(LArchive, LCatalog);
  FGraphics := TWarFactory.CreateGraphics(LArchive, LCatalog);
end;

function TTestWarMapParity.BuildMap(AIndex: Integer): TWarGameMap;
var
  LLevel: IWarLevel;
  LBuilder: TWarMapBuilder;
begin
  LLevel := FLoader.Load(AIndex);
  LBuilder := TWarMapFactory.CreateBuilder;
  try
    Result := LBuilder.Build(LLevel, FGraphics.GetTileset(LLevel.Info.TilesetIndex).Pixels);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestWarMapParity.Seed(ASeed: Cardinal);
begin
  FRng := ASeed;
end;

function TTestWarMapParity.RngNext: Cardinal;
begin
  FRng := FRng * 1103515245 + 12345;
  Result := (FRng shr 16) and $7FFF;
end;

function TTestWarMapParity.RngRange(ACount: Integer): Integer;
begin
  Result := Integer(RngNext mod Cardinal(ACount));
end;

function TTestWarMapParity.Clamp(AValue, AMin, AMax: Integer): Integer;
begin
  Result := Min(Max(AValue, AMin), AMax);
end;

function TTestWarMapParity.LevelsOfTheScenarios: TArray<Integer>;
var
  LPosition: Integer;
  LIndex: Integer;
  LMap: TWarGameMap;
  LList: TList<Integer>;
begin
  LList := TList<Integer>.Create;
  try
    for LPosition := 0 to FLoader.LevelCount - 1 do
    begin
      LIndex := FLoader.GetLevelIndex(LPosition);
      try
        LMap := BuildMap(LIndex);
        LMap.Free;
        LList.Add(LIndex);
      except
        on EWarException do
          ; // a level the original cannot make either (it stops on an assert): not in the scenarios
      end;
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

procedure TTestWarMapParity.DovrebbeDareLeStesseImprontiDelCodiceOriginaleSuTuttiILivelli;
var
  LGolden: TStringList;
  LActual: TStringList;
  LPosition: Integer;
  LIndex: Integer;
  LMap: TWarGameMap;
  LLevels: Integer;
begin
  OpenData;
  LGolden := Golden('map.maps.golden.txt');
  LActual := TStringList.Create;
  try
    LLevels := 0;
    for LPosition := 0 to FLoader.LevelCount - 1 do
    begin
      LIndex := FLoader.GetLevelIndex(LPosition);
      if (LIndex = 123) then
        Continue; // the original stops on an assert: see the next test
      LMap := BuildMap(LIndex);
      try
        TWarMapDump.DumpMap(LMap, LIndex, LActual);
        LMap.UpdateFog;
        TWarMapDump.DumpFog(LMap, LIndex, LActual);
        LMap.RenderMinimap;
        TWarMapDump.DumpMinimap(LMap, LIndex, 'B', LActual);
        LMap.Fog.Enabled := False;
        LMap.RenderMinimap;
        TWarMapDump.DumpMinimap(LMap, LIndex, 'b', LActual);
        Inc(LLevels);
      finally
        LMap.Free;
      end;
    end;
    // the golden has the line Z of the level that stops; the levels are in the order of the table
    for LIndex := LGolden.Count - 1 downto 0 do
      if LGolden[LIndex][1] = 'Z' then
        LGolden.Delete(LIndex);
    Assert.AreEqual<Integer>(65, LLevels, 'livelli istanziati');
    Assert.AreEqual<Integer>(LGolden.Count, LActual.Count, 'righe');
    for LIndex := 0 to LGolden.Count - 1 do
      Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'riga ' + IntToStr(LIndex));
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarMapParity.DovrebbeRifiutareIlLivelloCheIlCodiceOriginaleNonSaCreare;
var
  LGolden: TStringList;
  LLine: string;
  LStopped: Integer;
begin
  OpenData;
  LGolden := Golden('map.maps.golden.txt');
  try
    LStopped := 0;
    for LLine in LGolden do
      if LLine[1] = 'Z' then
      begin
        Inc(LStopped);
        // "Z <level> <unit type>": the start units have a type without statistics
        Assert.AreEqual('Z 123 16', LLine);
        Assert.WillRaise(
          procedure
          begin
            BuildMap(123).Free;
          end, EWarException);
      end;
    Assert.AreEqual<Integer>(1, LStopped);
  finally
    LGolden.Free;
  end;
end;

function TTestWarMapParity.Tail(const AMap: TWarGameMap): string;
var
  LForests: Integer;
  LTrees: Integer;
  LForestsText: string;
begin
  LForestsText := TWarMapDump.ForestsChecksum(AMap, LForests, LTrees);
  Result := Format(' | %d %d %s %s %s %s %s', [LForests, LTrees, LForestsText,
    TWarMapDump.ForestChecksum(AMap.Forests.EditingForest), TWarMapDump.Words(AMap.Grid.ToArray),
    TWarMapDump.Words(AMap.Visual), TWarMapDump.Hex(AMap.Minimap.Terrain)]);
end;

procedure TTestWarMapParity.DovrebbeDareGliStessiAlberiDelCodiceOriginaleInSessantaScenari;
var
  LGolden: TStringList;
  LActual: TStringList;
  LLevels: TArray<Integer>;
  LScenario: Integer;
  LOperations: Integer;
  LStep: Integer;
  LOperation: Integer;
  LIndex: Integer;
  LMap: TWarGameMap;
  LForest: TWarMapForest;
  LTree: TWarTree;
  LX: Integer;
  LY: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;
  LAmount: Integer;
  LGot: Integer;
  LBest: Integer;
  LDistance: Integer;
  LFirstUnit: TWarMapUnit;
  LFound: TWarTree;
  LLine: string;
begin
  OpenData;
  LGolden := Golden('map.trees.golden.txt');
  LActual := TStringList.Create;
  try
    LLevels := LevelsOfTheScenarios;
    for LScenario := 0 to 59 do
    begin
      Seed(7000 + Cardinal(LScenario));
      LIndex := LLevels[LScenario mod Length(LLevels)];
      LMap := BuildMap(LIndex);
      try
        LMap.UpdateFog;
        LActual.Add(Format('X %d %d', [LScenario, LIndex]));
        LOperations := 6 + RngRange(10);
        for LStep := 0 to LOperations - 1 do
        begin
          LOperation := RngRange(4);
          if LOperation = 0 then
          begin
            LX := RngRange(WAR_MAP_TILES_WIDTH);
            LY := RngRange(WAR_MAP_TILES_HEIGHT);
            if (RngRange(2) = 0) and (LMap.Forests.Count > 0) then
            begin
              LForest := LMap.Forests[RngRange(LMap.Forests.Count)];
              if LForest.Trees.Count > 0 then
              begin
                LTree := LForest.Trees[RngRange(LForest.Trees.Count)];
                LDeltaX := RngRange(5) - 2;
                LDeltaY := RngRange(5) - 2;
                LX := Clamp(LTree.TileX + LDeltaX, 0, WAR_MAP_TILES_WIDTH - 1);
                LY := Clamp(LTree.TileY + LDeltaY, 0, WAR_MAP_TILES_HEIGHT - 1);
              end;
            end;
            LMap.Forests.PlantTree(LMap.Forests.EditingForest, LX, LY);
            LMap.Forests.DetermineTiles(LMap.Forests.EditingForest);
            LLine := Format('t %d %d P %d %d', [LScenario, LStep, LX, LY]);
          end
          else if (LOperation = 1) or (LOperation = 2) then
          begin
            LForest := LMap.Forests[RngRange(LMap.Forests.Count)];
            if RngRange(2) = 0 then
              LAmount := 100 + RngRange(21)
            else
              LAmount := 1 + RngRange(60);
            if LForest.Trees.Count = 0 then
              LLine := Format('t %d %d C empty', [LScenario, LStep])
            else
            begin
              LTree := LForest.Trees[RngRange(LForest.Trees.Count)];
              LGot := LMap.Forests.ChopTree(LForest, LTree.TileX, LTree.TileY, LAmount);
              LLine := Format('t %d %d C %d %d %d %d', [LScenario, LStep, LTree.TileX, LTree.TileY, LAmount, LGot]);
            end;
          end
          else
          begin
            LForest := LMap.Forests[RngRange(LMap.Forests.Count)];
            LX := RngRange(WAR_MAP_TILES_WIDTH);
            LY := RngRange(WAR_MAP_TILES_HEIGHT);
            if (LForest.Trees.Count > 0) and (RngRange(3) <> 0) then
            begin
              LTree := LForest.Trees[RngRange(LForest.Trees.Count)];
              LX := LTree.TileX;
              LY := LTree.TileY;
            end;
            if (LMap.Units.Count > 0) and (LForest.Trees.Count > 0) and (RngRange(2) = 0) then
            begin
              // the tree of the forest nearest to the first unit: the one that is in sight
              LFirstUnit := LMap.Units[0];
              LBest := MaxInt;
              for LTree in LForest.Trees do
              begin
                LDeltaX := LTree.TileX - LFirstUnit.TileX;
                LDeltaY := LTree.TileY - LFirstUnit.TileY;
                LDistance := LDeltaX * LDeltaX + LDeltaY * LDeltaY;
                if LDistance < LBest then
                begin
                  LBest := LDistance;
                  LX := LTree.TileX;
                  LY := LTree.TileY;
                end;
              end;
            end;
            if LMap.Forests.FindAccessibleTree(LForest, LX, LY, LFound) then
              LLine := Format('t %d %d A %d %d %d %d %d', [LScenario, LStep, LX, LY, LFound.TileX, LFound.TileY,
                LFound.Amount])
            else
              LLine := Format('t %d %d A %d %d -1 -1 -1', [LScenario, LStep, LX, LY]);
          end;
          LActual.Add(LLine + Tail(LMap));
        end;
      finally
        LMap.Free;
      end;
    end;
    Assert.AreEqual<Integer>(LGolden.Count, LActual.Count, 'righe');
    for LIndex := 0 to LGolden.Count - 1 do
      Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'riga ' + IntToStr(LIndex));
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

end.
