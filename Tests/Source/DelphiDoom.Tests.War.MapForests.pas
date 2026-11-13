{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the forests of the map               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapForests;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Map.Types,
  DelphiDoom.War.Map.Intf, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Map.Fog, DelphiDoom.War.Map.Forest,
  DelphiDoom.War.Map.Forests, DelphiDoom.Tests.War.MapSupport;

type
  [TestFixture]
  [Category('war')]
  TTestWarMapForests = class(TObject)
  private
    FGrid: TWarPathGrid;
    FFog: TWarFogOfWar;
    FPainterObject: TFakeTilePainter;
    FPainter: IWarTilePainter;
    FForests: TWarMapForests;
    FNextId: Word;
    procedure Create(const APassable: TArray<Word>; ATilesetType: Integer = WAR_TILESET_FOREST);
    function AllocateId: Word;
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFareUnBoscoPerOgniGruppoDiCaselleDiLegno;
    [Test]
    procedure DovrebbeLegareGliAlberiDiagonaliAlloStessoBosco;
    [Test]
    procedure DovrebbeOccuparLaGrigliaConLIdDelBosco;
    [Test]
    procedure DovrebbeDecidereLaTegolaDaiVicini;
    [Test]
    procedure DovrebbeTrovareUnBoscoDallId;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLaMappaPassabileECorta;
    [Test]
    procedure DovrebbePiantareDueAlberiSuUnaCasellaVuota;
    [Test]
    procedure DovrebbePiantareUnSoloAlberoSeLaCasellaSopraEOccupata;
    [Test]
    procedure NonDovrebbePiantareSuUnaCasellaOccupata;
    [Test]
    procedure DovrebbePiantareInAltoSoloSeCEUnAlberoSotto;
    [Test]
    procedure DovrebbeTogliereLegnoDaUnAlbero;
    [Test]
    procedure DovrebbeDareSoloIlLegnoCheCeIn;
    [Test]
    procedure DovrebbeAbbattereLAlberoSenzaLegnoELiberareLaCasella;
    [Test]
    procedure DovrebbeUsareLaTegolaDellaPaludePerGliAlberiAbbattutiFuoriDallaForesta;
    [Test]
    procedure DovrebbeAbbattereGliAlberiCheNonStannoPiu;
    [Test]
    procedure DovrebbeSollevareEccezioneSeNonCeUnAlberoDaTagliare;
    [Test]
    procedure DovrebbeTrovareUnAlberoRaggiungibileEInVista;
    [Test]
    procedure DovrebbeCercareTraIVicini;
    [Test]
    procedure NonDovrebbeTrovareUnAlberoSenzaLegnoOFuoriVista;
    [Test]
    procedure DovrebbeDecidereLeTegoleDiTuttiIBoschi;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Autotile.Data;

function NewTestTree(AX, AY: Integer): TWarTree;
begin
  Result := Default(TWarTree);
  Result.TileX := AX;
  Result.TileY := AY;
  Result.Amount := WAR_TREE_MAX_WOOD;
end;

{ TTestWarMapForests }

function TTestWarMapForests.AllocateId: Word;
begin
  Inc(FNextId);
  Result := FNextId;
end;

procedure TTestWarMapForests.Create(const APassable: TArray<Word>; ATilesetType: Integer);
begin
  FNextId := 0;
  FGrid := TWarPathGrid.Create(APassable);
  FFog := TWarFogOfWar.Create;
  FPainterObject := TFakeTilePainter.Create;
  FPainter := FPainterObject;
  FForests := TWarMapForests.Create(FGrid, FFog, FPainter, ATilesetType);
  FForests.CreateFromPassable(APassable, AllocateId);
  FForests.EditingForest := FForests.AddForest(AllocateId);
end;

procedure TTestWarMapForests.TearDown;
begin
  FForests.Free;
  FForests := nil;
  FPainter := nil;
  FPainterObject := nil;
  FFog.Free;
  FFog := nil;
  FGrid.Free;
  FGrid := nil;
end;

procedure TTestWarMapForests.DovrebbeFareUnBoscoPerOgniGruppoDiCaselleDiLegno;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  TMapFixtures.PutWood(LPassable, 20, 20, 4, 4);
  Create(LPassable);
  // two groups and the forest of the game
  Assert.AreEqual<Integer>(3, FForests.Count);
  Assert.AreEqual<Integer>(9, FForests[0].Trees.Count);
  Assert.AreEqual<Integer>(16, FForests[1].Trees.Count);
  Assert.AreEqual<Integer>(0, FForests[2].Trees.Count);
  Assert.AreEqual<Integer>(1, Integer(FForests[0].Id));
  Assert.AreEqual<Integer>(2, Integer(FForests[1].Id));
  Assert.AreEqual<Integer>(3, Integer(FForests.EditingForest.Id));
  Assert.AreEqual<Integer>(WAR_TREE_MAX_WOOD, FForests[0].Trees[0].Amount);
end;

procedure TTestWarMapForests.DovrebbeLegareGliAlberiDiagonaliAlloStessoBosco;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 10, 10, 2, 2);
  TMapFixtures.PutWood(LPassable, 12, 12, 2, 2);
  Create(LPassable);
  Assert.AreEqual<Integer>(2, FForests.Count);
  Assert.AreEqual<Integer>(8, FForests[0].Trees.Count);
end;

procedure TTestWarMapForests.DovrebbeOccuparLaGrigliaConLIdDelBosco;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  Assert.IsTrue(FGrid.IsStatic(6, 6));
  Assert.AreEqual<Integer>(1, Integer(FGrid.GetTileEntityId(6, 6)));
  Assert.IsNotNull(FForests.FindForest(1));
end;

procedure TTestWarMapForests.DovrebbeDecidereLaTegolaDaiVicini;
var
  LPassable: TArray<Word>;
  LTree: TWarTree;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  Assert.IsTrue(FForests[0].TryGetTreeAt(6, 6, LTree));
  // the center has the eight neighbors
  Assert.AreEqual<Integer>(WAR_TREE_TILE_TYPE_MAP[255], Integer(LTree.TileType));
  Assert.IsTrue(FForests[0].TryGetTreeAt(5, 5, LTree));
  // the top left corner has the right, bottom right and bottom neighbors
  Assert.AreEqual<Integer>(WAR_TREE_TILE_TYPE_MAP[(1 shl 3) or (1 shl 4) or (1 shl 5)], Integer(LTree.TileType));
end;

procedure TTestWarMapForests.DovrebbeTrovareUnBoscoDallId;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  Assert.IsNull(FForests.FindForest(99));
  Assert.IsTrue(FForests.FindForest(1) = FForests[0]);
end;

procedure TTestWarMapForests.DovrebbeSollevareEccezioneSeLaMappaPassabileECorta;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  Create(LPassable);
  Assert.WillRaise(
    procedure
    begin
      FForests.CreateFromPassable(nil, AllocateId);
    end, EWarException);
end;

procedure TTestWarMapForests.DovrebbePiantareDueAlberiSuUnaCasellaVuota;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  Create(LPassable);
  FForests.PlantTree(FForests.EditingForest, 30, 30);
  Assert.AreEqual<Integer>(2, FForests.EditingForest.Trees.Count);
  Assert.IsTrue(FForests.EditingForest.HasTreeAt(30, 30));
  Assert.IsTrue(FForests.EditingForest.HasTreeAt(30, 29));
  Assert.IsFalse(FGrid.IsEmpty(30, 29));
  Assert.AreEqual<Integer>(Integer(FForests.EditingForest.Id), Integer(FGrid.GetTileEntityId(30, 30)));
end;

procedure TTestWarMapForests.DovrebbePiantareUnSoloAlberoSeLaCasellaSopraEOccupata;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  LPassable[29 * WAR_MAP_TILES_WIDTH + 30] := 64;
  Create(LPassable);
  FForests.PlantTree(FForests.EditingForest, 30, 30);
  Assert.AreEqual<Integer>(1, FForests.EditingForest.Trees.Count);
end;

procedure TTestWarMapForests.NonDovrebbePiantareSuUnaCasellaOccupata;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  LPassable[30 * WAR_MAP_TILES_WIDTH + 30] := 64;
  Create(LPassable);
  FForests.PlantTree(FForests.EditingForest, 30, 30);
  Assert.AreEqual<Integer>(0, FForests.EditingForest.Trees.Count);
end;

procedure TTestWarMapForests.DovrebbePiantareInAltoSoloSeCEUnAlberoSotto;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  Create(LPassable);
  FForests.PlantTree(FForests.EditingForest, 10, 0);
  Assert.AreEqual<Integer>(0, FForests.EditingForest.Trees.Count);
  // on the second row the tree and the one above it are planted
  FForests.PlantTree(FForests.EditingForest, 10, 1);
  Assert.AreEqual<Integer>(2, FForests.EditingForest.Trees.Count);
  // the top row is not empty any more
  FForests.PlantTree(FForests.EditingForest, 10, 0);
  Assert.AreEqual<Integer>(2, FForests.EditingForest.Trees.Count);
  // a tree below an empty tile of the top row: one tree, nothing above it
  FForests.EditingForest.Trees.Add(NewTestTree(14, 1));
  FForests.PlantTree(FForests.EditingForest, 14, 0);
  Assert.AreEqual<Integer>(4, FForests.EditingForest.Trees.Count);
  Assert.IsTrue(FForests.EditingForest.HasTreeAt(14, 0));
  Assert.IsTrue(FGrid.IsStatic(14, 0));
end;

procedure TTestWarMapForests.DovrebbeTogliereLegnoDaUnAlbero;
var
  LPassable: TArray<Word>;
  LTree: TWarTree;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  Assert.AreEqual<Integer>(30, FForests.ChopTree(FForests[0], 6, 6, 30));
  Assert.IsTrue(FForests[0].TryGetTreeAt(6, 6, LTree));
  Assert.AreEqual<Integer>(70, LTree.Amount);
  Assert.AreEqual<Integer>(0, FPainterObject.Calls.Count);
end;

procedure TTestWarMapForests.DovrebbeDareSoloIlLegnoCheCeIn;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  Assert.AreEqual<Integer>(100, FForests.ChopTree(FForests[0], 5, 5, 250));
  Assert.AreEqual<Integer>(8, FForests[0].Trees.Count);
end;

procedure TTestWarMapForests.DovrebbeAbbattereLAlberoSenzaLegnoELiberareLaCasella;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  FForests.ChopTree(FForests[0], 6, 6, 100);
  Assert.IsFalse(FForests[0].HasTreeAt(6, 6));
  Assert.IsTrue(FGrid.IsEmpty(6, 6));
  // the trees above and below the center have no tree above or below them any more: they fall too
  Assert.AreEqual<Integer>(3, FPainterObject.Calls.Count);
  Assert.AreEqual<Integer>(6, FPainterObject.Calls[0][0]);
  Assert.AreEqual<Integer>(6, FPainterObject.Calls[0][1]);
  Assert.AreEqual<Integer>(WAR_TREE_DATA[WAR_TREE_CHOPPED].Forest, FPainterObject.Calls[0][2]);
  Assert.IsTrue(FGrid.IsEmpty(6, 5));
  Assert.IsTrue(FGrid.IsEmpty(6, 7));
  Assert.IsTrue(FForests[0].Trees.Count <= 6);
end;

procedure TTestWarMapForests.DovrebbeUsareLaTegolaDellaPaludePerGliAlberiAbbattutiFuoriDallaForesta;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable, WAR_TILESET_DUNGEON);
  FForests.ChopTree(FForests[0], 6, 6, 100);
  Assert.AreEqual<Integer>(WAR_TREE_DATA[WAR_TREE_CHOPPED].Swamp, FPainterObject.Calls[0][2]);
end;

procedure TTestWarMapForests.DovrebbeAbbattereGliAlberiCheNonStannoPiu;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  Create(LPassable);
  // a column of three: when the middle falls the other two have nothing above or below and fall too
  FForests.EditingForest.Trees.Add(NewTestTree(20, 20));
  FForests.EditingForest.Trees.Add(NewTestTree(20, 21));
  FForests.EditingForest.Trees.Add(NewTestTree(20, 22));
  Assert.IsTrue(FForests.IsValidTree(FForests.EditingForest, FForests.EditingForest.Trees[0]));
  FForests.ChopTree(FForests.EditingForest, 20, 21, 100);
  Assert.AreEqual<Integer>(0, FForests.EditingForest.Trees.Count);
  Assert.AreEqual<Integer>(3, FPainterObject.Calls.Count);
  Assert.IsFalse(FForests.IsValidTree(FForests.EditingForest, NewTestTree(40, 40)));
end;

procedure TTestWarMapForests.DovrebbeSollevareEccezioneSeNonCeUnAlberoDaTagliare;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  Assert.WillRaise(
    procedure
    begin
      FForests.ChopTree(FForests[0], 40, 40, 10);
    end, EWarException);
end;

procedure TTestWarMapForests.DovrebbeTrovareUnAlberoRaggiungibileEInVista;
var
  LPassable: TArray<Word>;
  LTree: TWarTree;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  FFog.SetState(2, 2, 10, 10, wtsVisible);
  // the corner has empty tiles around it
  Assert.IsTrue(FForests.FindAccessibleTree(FForests[0], 5, 5, LTree));
  Assert.AreEqual<Integer>(5, LTree.TileX);
  Assert.AreEqual<Integer>(5, LTree.TileY);
  // a tree in fog is found too
  FFog.BeginUpdate;
  Assert.IsTrue(FForests.FindAccessibleTree(FForests[0], 5, 5, LTree));
end;

procedure TTestWarMapForests.DovrebbeCercareTraIVicini;
var
  LPassable: TArray<Word>;
  LTree: TWarTree;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  FFog.SetState(2, 2, 10, 10, wtsVisible);
  // from the center (which no one can reach) to the first neighbor that can be reached: the one above, then the corners
  Assert.IsTrue(FForests.FindAccessibleTree(FForests[0], 6, 6, LTree));
  Assert.AreEqual<Integer>(6, LTree.TileX);
  Assert.AreEqual<Integer>(5, LTree.TileY);
  // from far away: the search spreads over the whole map
  Assert.IsTrue(FForests.FindAccessibleTree(FForests[0], 40, 40, LTree));
end;

procedure TTestWarMapForests.NonDovrebbeTrovareUnAlberoSenzaLegnoOFuoriVista;
var
  LPassable: TArray<Word>;
  LTree: TWarTree;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  // in the unknown nothing is found
  Assert.IsFalse(FForests.FindAccessibleTree(FForests[0], 5, 5, LTree));
  Assert.AreEqual<Integer>(0, LTree.Amount);
  // an empty forest has nothing to find
  FFog.SetState(2, 2, 10, 10, wtsVisible);
  Assert.IsFalse(FForests.FindAccessibleTree(FForests.EditingForest, 5, 5, LTree));
end;

procedure TTestWarMapForests.DovrebbeDecidereLeTegoleDiTuttiIBoschi;
var
  LPassable: TArray<Word>;
  LIndex: Integer;
  LTree: TWarTree;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Create(LPassable);
  LIndex := FForests[0].IndexOfTile(6, 6);
  LTree := FForests[0].Trees[LIndex];
  LTree.TileType := 0;
  FForests[0].Trees[LIndex] := LTree;
  FForests.DetermineAllTiles;
  Assert.AreEqual<Integer>(WAR_TREE_TILE_TYPE_MAP[255], Integer(FForests[0].Trees[LIndex].TileType));
end;

end.
