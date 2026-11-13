{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - a level becomes a game map           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf,
  DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Builder, DelphiDoom.War.Map.Game;

type
  [TestFixture]
  [Category('war')]
  TTestWarMapBuilder = class(TObject)
  private
    FBuilder: TWarMapBuilder;
    FMap: TWarGameMap;
    function MakeInfo: TWarLevelInfo;
    function MakeMap(const AInfo: TWarLevelInfo): TWarGameMap;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareGliIdNellOrdineDelCodiceOriginale;
    [Test]
    procedure DovrebbeFareIGiocatoriDelLivello;
    [Test]
    procedure DovrebbePartireDaDoveDiceIlLivello;
    [Test]
    procedure DovrebbeCreareLeUnitaIniziali;
    [Test]
    procedure DovrebbeOccuparLaGrigliaConLeUnita;
    [Test]
    procedure DovrebbeCreareStradeEMuriDiPartenza;
    [Test]
    procedure DovrebbeIgnorareLeCostruzioniDiUnAltroTipo;
    [Test]
    procedure DovrebbeFareIBoschiDallaMappaPassabile;
    [Test]
    procedure DovrebbePartireConTuttoSconosciutoESenzaVista;
    [Test]
    procedure DovrebbeVedereCioCheVedonoLeUnitaDelGiocatore;
    [Test]
    procedure DovrebbeDisegnareLaMinimapDelleUnita;
    [Test]
    procedure DovrebbeTenereLaCopiaDellaMappaVisivaDelLivello;
    [Test]
    procedure DovrebbeGenerareNuoveUnitaConIdSuccessivi;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnaUnitaNonHaTabella;
    [Test]
    procedure DovrebbeSollevareEccezioneSeServeUnCatalogoMaNonCe;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLImmagineDelTilesetEBreve;
    [Test]
    procedure DovrebbeCreareIlBuilderDallaFabbrica;
  end;

implementation

uses
  DelphiDoom.War.Map.Factory, DelphiDoom.War.Map.Intf, DelphiDoom.Tests.War.MapSupport;

{ TTestWarMapBuilder }

procedure TTestWarMapBuilder.Setup;
begin
  FBuilder := TWarMapFactory.CreateBuilder;
end;

procedure TTestWarMapBuilder.TearDown;
begin
  FMap.Free;
  FMap := nil;
  FBuilder.Free;
end;

function TTestWarMapBuilder.MakeInfo: TWarLevelInfo;
var
  LRoad: TWarLevelConstruct;
begin
  Result := TMapFixtures.BasicInfo;
  Result.StartEntities := [
    TMapFixtures.StartUnit(10, 10, WAR_UNIT_TOWNHALL_HUMANS, 0, wrkNone, 0),
    TMapFixtures.StartUnit(14, 10, WAR_UNIT_FOOTMAN, 0, wrkNone, 0),
    TMapFixtures.StartUnit(40, 40, WAR_UNIT_TOWNHALL_ORCS, 1, wrkNone, 0),
    TMapFixtures.StartUnit(20, 20, WAR_UNIT_GOLDMINE, 4, wrkGold, 10000)];
  LRoad := Default(TWarLevelConstruct);
  LRoad.ConstructType := wctRoad;
  LRoad.X1 := 30;
  LRoad.Y1 := 30;
  LRoad.X2 := 33;
  LRoad.Y2 := 30;
  Result.StartRoads := [LRoad];
  LRoad.ConstructType := wctWall;
  LRoad.X1 := 50;
  LRoad.Y1 := 50;
  LRoad.X2 := 50;
  LRoad.Y2 := 52;
  Result.StartWalls := [LRoad];
end;

function TTestWarMapBuilder.MakeMap(const AInfo: TWarLevelInfo): TWarGameMap;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  Result := FBuilder.Build(TMapFixtures.MakeLevel(AInfo, LPassable), TMapFixtures.Tileset);
end;

procedure TTestWarMapBuilder.DovrebbeDareGliIdNellOrdineDelCodiceOriginale;
begin
  FMap := MakeMap(MakeInfo);
  // the forest, the forest of the game, the road, the wall, the ruins, then the units
  Assert.AreEqual<Integer>(1, Integer(FMap.Forests[0].Id));
  Assert.AreEqual<Integer>(2, Integer(FMap.Forests.EditingForest.Id));
  Assert.AreEqual<Integer>(3, Integer(FMap.RoadId));
  Assert.AreEqual<Integer>(4, Integer(FMap.WallId));
  Assert.AreEqual<Integer>(5, Integer(FMap.RuinsId));
  Assert.AreEqual<Integer>(6, Integer(FMap.Units[0].Id));
  Assert.AreEqual<Integer>(9, Integer(FMap.Units[3].Id));
  Assert.AreEqual<Integer>(9, Integer(FMap.LastEntityId));
end;

procedure TTestWarMapBuilder.DovrebbeFareIGiocatoriDelLivello;
begin
  FMap := MakeMap(MakeInfo);
  Assert.AreEqual<Integer>(2, FMap.PlayersCount);
  Assert.IsTrue(FMap.Players[0].Race = wraHumans);
  Assert.AreEqual<Integer>(2000, FMap.Players[0].Gold);
  Assert.AreEqual<Integer>(800, FMap.Players[1].Wood);
  Assert.AreEqual<Integer>(4, Integer(FMap.Players[4].Index));
  Assert.AreEqual<Integer>(1, Integer(FMap.Players[0].Features[1]));
  Assert.AreEqual<Integer>(0, Integer(FMap.Players[0].Features[2]));
  Assert.AreEqual<Integer>(1, Integer(FMap.Players[1].Upgrades[2].Allowed));
  Assert.AreEqual<Integer>(0, Integer(FMap.Players[0].Upgrades[2].Allowed));
  Assert.AreEqual<Integer>(0, Integer(FMap.Players[1].Upgrades[2].Level));
end;

procedure TTestWarMapBuilder.DovrebbePartireDaDoveDiceIlLivello;
begin
  FMap := MakeMap(MakeInfo);
  Assert.AreEqual<Integer>(5 * 16, FMap.Viewport.X);
  Assert.AreEqual<Integer>(7 * 16, FMap.Viewport.Y);
  Assert.AreEqual<Integer>(WAR_MAP_VIEWPORT_WIDTH, FMap.Viewport.Width);
  Assert.AreEqual<Integer>(117, FMap.Info.Index);
end;

procedure TTestWarMapBuilder.DovrebbeCreareLeUnitaIniziali;
begin
  FMap := MakeMap(MakeInfo);
  Assert.AreEqual<Integer>(4, FMap.Units.Count);
  Assert.AreEqual<Integer>(2500, FMap.Units[0].Hp);
  Assert.AreEqual<Integer>(60, FMap.Units[1].Hp);
  Assert.AreEqual<Integer>(10000, FMap.Units[3].Amount);
  Assert.IsTrue(FMap.Units[3].ResourceKind = wrkGold);
end;

procedure TTestWarMapBuilder.DovrebbeOccuparLaGrigliaConLeUnita;
begin
  FMap := MakeMap(MakeInfo);
  Assert.IsTrue(FMap.Grid.IsStatic(11, 11));
  Assert.AreEqual<Integer>(Integer(FMap.Units[0].Id), Integer(FMap.Grid.GetTileEntityId(12, 12)));
  Assert.IsTrue(FMap.Grid.IsEmpty(13, 10));
  Assert.AreEqual<Integer>(Integer(FMap.Units[1].Id), Integer(FMap.Grid.GetTileEntityId(14, 10)));
end;

procedure TTestWarMapBuilder.DovrebbeCreareStradeEMuriDiPartenza;
begin
  FMap := MakeMap(MakeInfo);
  Assert.IsTrue(FMap.Road.Count > 0);
  Assert.IsTrue(FMap.Road.HasPieceAt(31, 30));
  Assert.IsTrue(FMap.Wall.HasPieceAt(50, 51));
  Assert.AreEqual<Integer>(0, FMap.Ruins.Count);
end;

procedure TTestWarMapBuilder.DovrebbeIgnorareLeCostruzioniDiUnAltroTipo;
var
  LInfo: TWarLevelInfo;
  LConstruct: TWarLevelConstruct;
begin
  LInfo := MakeInfo;
  LConstruct := LInfo.StartRoads[0];
  LConstruct.ConstructType := wctWall;
  LInfo.StartRoads := [LConstruct];
  LConstruct := LInfo.StartWalls[0];
  LConstruct.ConstructType := wctRoad;
  LInfo.StartWalls := [LConstruct];
  FMap := MakeMap(LInfo);
  Assert.AreEqual<Integer>(0, FMap.Road.Count);
  Assert.AreEqual<Integer>(0, FMap.Wall.Count);
end;

procedure TTestWarMapBuilder.DovrebbeFareIBoschiDallaMappaPassabile;
begin
  FMap := MakeMap(MakeInfo);
  Assert.AreEqual<Integer>(2, FMap.Forests.Count);
  Assert.AreEqual<Integer>(9, FMap.Forests[0].Trees.Count);
  Assert.IsTrue(FMap.Grid.IsStatic(6, 6));
end;

procedure TTestWarMapBuilder.DovrebbePartireConTuttoSconosciutoESenzaVista;
begin
  FMap := MakeMap(MakeInfo);
  Assert.AreEqual<Integer>(WAR_MAP_TILE_COUNT, FMap.Fog.CountState(wtsUnknown));
  Assert.IsFalse(FMap.Units[0].HasBeenSeen);
end;

procedure TTestWarMapBuilder.DovrebbeVedereCioCheVedonoLeUnitaDelGiocatore;
begin
  FMap := MakeMap(MakeInfo);
  FMap.UpdateFog;
  Assert.IsTrue(FMap.Fog.IsTileVisible(11, 11));
  Assert.IsTrue(FMap.Fog.IsTileVisible(14, 10));
  Assert.IsTrue(FMap.Fog.IsTileUnknown(40, 40));
  Assert.IsTrue(FMap.Units[0].HasBeenSeen);
  Assert.IsFalse(FMap.Units[2].HasBeenSeen);
end;

procedure TTestWarMapBuilder.DovrebbeDisegnareLaMinimapDelleUnita;
var
  LPixels: TBytes;
begin
  FMap := MakeMap(MakeInfo);
  FMap.UpdateFog;
  LPixels := FMap.RenderMinimap;
  Assert.AreEqual<Integer>(WAR_MINIMAP_BYTES, Length(LPixels));
  // the town hall of the player is yellow, the terrain around it is the average color of the tile 3
  Assert.AreEqual<Integer>(255, Integer(LPixels[(10 * 64 + 10) * 4]));
  Assert.AreEqual<Integer>(255, Integer(LPixels[(10 * 64 + 10) * 4 + 1]));
  Assert.AreEqual<Integer>(3, Integer(LPixels[(9 * 64 + 10) * 4]));
  Assert.AreEqual<Integer>(0, Integer(LPixels[(30 * 64 + 30) * 4]));
end;

procedure TTestWarMapBuilder.DovrebbeTenereLaCopiaDellaMappaVisivaDelLivello;
var
  LPassable: TArray<Word>;
  LLevel: IWarLevel;
begin
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  LLevel := TMapFixtures.MakeLevel(MakeInfo, LPassable);
  FMap := FBuilder.Build(LLevel, TMapFixtures.Tileset);
  FMap.Forests.ChopTree(FMap.Forests[0], 6, 6, 100);
  Assert.AreNotEqual<Integer>(3, Integer(FMap.Visual[6 * 64 + 6]));
  Assert.AreEqual<Integer>(3, Integer(LLevel.VisualAt(6, 6)));
end;

procedure TTestWarMapBuilder.DovrebbeGenerareNuoveUnitaConIdSuccessivi;
var
  LUnit: TWarMapUnit;
begin
  FMap := MakeMap(MakeInfo);
  LUnit := FMap.SpawnUnit(WAR_UNIT_ARCHER, 30, 40, 0, wrkNone, 0);
  Assert.AreEqual<Integer>(10, Integer(LUnit.Id));
  Assert.AreEqual<Integer>(5, FMap.Units.Count);
  Assert.IsTrue(FMap.Grid.IsStatic(30, 40));
end;

procedure TTestWarMapBuilder.DovrebbeSollevareEccezioneSeUnaUnitaNonHaTabella;
var
  LInfo: TWarLevelInfo;
begin
  LInfo := MakeInfo;
  LInfo.StartEntities := [TMapFixtures.StartUnit(1, 1, WAR_UNIT_WOUNDED, 0, wrkNone, 0)];
  Assert.WillRaise(
    procedure
    begin
      MakeMap(LInfo).Free;
    end, EWarException);
end;

procedure TTestWarMapBuilder.DovrebbeSollevareEccezioneSeServeUnCatalogoMaNonCe;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarMapBuilder.Create(nil).Free;
    end, EWarException);
end;

procedure TTestWarMapBuilder.DovrebbeSollevareEccezioneSeLImmagineDelTilesetEBreve;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable), nil).Free;
    end, EWarException);
end;

procedure TTestWarMapBuilder.DovrebbeCreareIlBuilderDallaFabbrica;
begin
  Assert.IsNotNull(FBuilder);
  Assert.IsNotNull(TWarMapFactory.CreateUnitCatalog);
end;

end.
