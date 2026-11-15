{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the setup of a custom game            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiCustom;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf, DelphiDoom.War.Map.Intf,
  DelphiDoom.War.Sound.Intf, DelphiDoom.War.Map.CustomGame;

type
  /// <summary>A generator that gives the numbers it was told, in order, and remembers the limits it was asked</summary>
  TScriptedRandom = class(TInterfacedObject, IWarRandom)
  strict private
    FValues: TArray<Integer>;
    FNext: Integer;
  public
    Limits: TArray<Integer>;
    constructor Create(const AValues: array of Integer);
    function Below(ALimit: Integer): Integer;
  end;

  /// <summary>wmap_createCustomMap: the draws, the units of the start, the camera, and the level that carries them</summary>
  [TestFixture]
  [Category('war')]
  TTestWarCustomGame = class(TObject)
  strict private
    FUnits: IWarUnitCatalog;
    function MakeInfo: TWarLevelInfo;
    function MakeOptions(APlayer, AEnemy: TWarRace): TWarCustomGameOptions;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeTirareLeRazzeLeMinierePoiLaPosizioneNellOrdine;
    [Test]
    procedure DovrebbeNonTirareLeRazzeScelte;
    [Test]
    procedure DovrebbeMettereLeMiniereEPoiLeUnitaDellaPosizioneConIlTipoDellaRazza;
    [Test]
    procedure DovrebbeMettereLaCameraSulMunicipioSeCeOSulPrimoSeNo;
    [Test]
    procedure DovrebbeNonAvereLaCameraSeIlGiocatoreNonHaUnita;
    [Test]
    procedure DovrebbeSostituireOroELegnaDeiDueGiocatori;
    [Test]
    procedure DovrebbeNonCambiareIlLivelloCheDiventaUnAltro;
    [Test]
    procedure DovrebbeRifiutareUnSeme;
    [Test]
    procedure DovrebbeRifiutareUnLivelloCheNonEPersonalizzatoOSenzaPosizioni;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiUnitaCheNonHaTabelle;
    [Test]
    procedure DovrebbeDareIlLivelloConLeInfoDellaPartitaEIDatiDelBase;
    [Test]
    procedure DovrebbeCominciareLaCameraDovePiaceAllaPartitaEDentroLaMappa;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Game, DelphiDoom.War.Map.Builder,
  DelphiDoom.War.Map.Factory,
  DelphiDoom.War.Level.CustomLevel, DelphiDoom.War.Model.Types, DelphiDoom.Tests.War.MapSupport;

{ TScriptedRandom }

constructor TScriptedRandom.Create(const AValues: array of Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FValues, Length(AValues));
  for LIndex := 0 to High(AValues) do
    FValues[LIndex] := AValues[LIndex];
end;

function TScriptedRandom.Below(ALimit: Integer): Integer;
begin
  Limits := Limits + [ALimit];
  if FNext < Length(FValues) then
    Result := FValues[FNext]
  else
    Result := 0;
  Inc(FNext);
end;

{ TTestWarCustomGame }

procedure TTestWarCustomGame.Setup;
begin
  FUnits := TWarMapFactory.CreateUnitCatalog;
end;

function TTestWarCustomGame.MakeInfo: TWarLevelInfo;
var
  LConfiguration: TWarCustomMapConfiguration;
begin
  Result := TMapFixtures.BasicInfo;
  Result.Index := 150;
  Result.CustomMap := True;
  Result.StartEntities := [TMapFixtures.StartUnit(1, 1, WAR_UNIT_FOOTMAN, 0, wrkNone, 0)];
  Result.StartGoldmines := [TMapFixtures.StartUnit(20, 20, WAR_UNIT_GOLDMINE, 4, wrkGold, 100),
    TMapFixtures.StartUnit(30, 30, WAR_UNIT_GOLDMINE, 4, wrkGold, 100)];
  // two positions: the first has the footman before the town hall, the second only a farm for the player
  LConfiguration.StartEntities := [TMapFixtures.StartUnit(10, 12, WAR_UNIT_FOOTMAN, 0, wrkNone, 0),
    TMapFixtures.StartUnit(14, 12, WAR_UNIT_TOWNHALL_HUMANS, 0, wrkNone, 0),
    TMapFixtures.StartUnit(40, 40, WAR_UNIT_TOWNHALL_HUMANS, 1, wrkNone, 0)];
  Result.StartConfigurations := [LConfiguration];
  LConfiguration.StartEntities := [TMapFixtures.StartUnit(10, 12, WAR_UNIT_FARM_HUMANS, 0, wrkNone, 0),
    TMapFixtures.StartUnit(40, 40, WAR_UNIT_TOWNHALL_HUMANS, 1, wrkNone, 0)];
  Result.StartConfigurations := Result.StartConfigurations + [LConfiguration];
  LConfiguration.StartEntities := [TMapFixtures.StartUnit(40, 40, WAR_UNIT_TOWNHALL_HUMANS, 1, wrkNone, 0)];
  Result.StartConfigurations := Result.StartConfigurations + [LConfiguration];
end;

function TTestWarCustomGame.MakeOptions(APlayer, AEnemy: TWarRace): TWarCustomGameOptions;
begin
  Result := Default(TWarCustomGameOptions);
  Result.PlayerRace := APlayer;
  Result.EnemyRace := AEnemy;
  Result.StartConfigurationIndex := -1;
end;

procedure TTestWarCustomGame.DovrebbeTirareLeRazzeLeMinierePoiLaPosizioneNellOrdine;
var
  LRandom: TScriptedRandom;
  LRandomRef: IWarRandom;
  LGame: TWarCustomGame;
begin
  // the player is an orc (1), the enemy a human (0), the gold of the two mines 25 and 9999 more than 20000, the position 1
  LRandom := TScriptedRandom.Create([1, 0, 25, 9999, 1]);
  LRandomRef := LRandom;
  LGame := TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable),
    MakeOptions(wraNeutral, wraNeutral), FUnits, LRandomRef);
  Assert.AreEqual<Integer>(5, Length(LRandom.Limits));
  Assert.AreEqual(2, LRandom.Limits[0]);
  Assert.AreEqual(2, LRandom.Limits[1]);
  Assert.AreEqual(10000, LRandom.Limits[2]);
  Assert.AreEqual(10000, LRandom.Limits[3]);
  Assert.AreEqual(3, LRandom.Limits[4]);
  Assert.IsTrue(LGame.Options.PlayerRace = wraOrcs);
  Assert.IsTrue(LGame.Options.EnemyRace = wraHumans);
  Assert.AreEqual(1, LGame.Options.StartConfigurationIndex);
  Assert.IsTrue(LGame.Options.Enabled);
  Assert.IsTrue(LGame.Info.Races[0] = wraOrcs);
  Assert.IsTrue(LGame.Info.Races[1] = wraHumans);
end;

procedure TTestWarCustomGame.DovrebbeNonTirareLeRazzeScelte;
var
  LRandom: TScriptedRandom;
  LRandomRef: IWarRandom;
begin
  LRandom := TScriptedRandom.Create([0, 0, 0]);
  LRandomRef := LRandom;
  TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable),
    MakeOptions(wraHumans, wraOrcs), FUnits, LRandomRef);
  // only the two mines and the position
  Assert.AreEqual<Integer>(3, Length(LRandom.Limits));
  Assert.AreEqual(10000, LRandom.Limits[0]);
  // the enemy alone is drawn: the player is chosen
  LRandom := TScriptedRandom.Create([1, 0, 0, 0]);
  LRandomRef := LRandom;
  TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable),
    MakeOptions(wraOrcs, wraNeutral), FUnits, LRandomRef);
  Assert.AreEqual<Integer>(4, Length(LRandom.Limits));
  Assert.AreEqual(2, LRandom.Limits[0]);
end;

procedure TTestWarCustomGame.DovrebbeMettereLeMiniereEPoiLeUnitaDellaPosizioneConIlTipoDellaRazza;
var
  LRandomRef: IWarRandom;
  LGame: TWarCustomGame;
begin
  // the player is an orc and the enemy a human; the position is the first
  LRandomRef := TScriptedRandom.Create([7, 8, 0]);
  LGame := TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable),
    MakeOptions(wraOrcs, wraHumans), FUnits, LRandomRef);
  Assert.AreEqual<Integer>(5, Length(LGame.Info.StartEntities));
  Assert.AreEqual<Integer>(WAR_UNIT_GOLDMINE, LGame.Info.StartEntities[0].UnitType);
  Assert.IsTrue(LGame.Info.StartEntities[0].ResourceKind = wrkGold);
  Assert.AreEqual<Integer>(20007, LGame.Info.StartEntities[0].Amount);
  Assert.AreEqual<Integer>(20008, LGame.Info.StartEntities[1].Amount);
  Assert.AreEqual<Integer>(4, LGame.Info.StartEntities[0].Player);
  Assert.AreEqual<Integer>(WAR_UNIT_GRUNT, LGame.Info.StartEntities[2].UnitType);
  Assert.AreEqual<Integer>(WAR_UNIT_TOWNHALL_ORCS, LGame.Info.StartEntities[3].UnitType);
  Assert.AreEqual<Integer>(WAR_UNIT_TOWNHALL_HUMANS, LGame.Info.StartEntities[4].UnitType);
  Assert.AreEqual<Integer>(1, LGame.Info.StartEntities[4].Player);
  Assert.IsTrue(LGame.Info.StartEntities[2].ResourceKind = wrkNone);
end;

procedure TTestWarCustomGame.DovrebbeMettereLaCameraSulMunicipioSeCeOSulPrimoSeNo;
var
  LRandomRef: IWarRandom;
  LGame: TWarCustomGame;
  LData: TWarUnitData;
begin
  // the first position has a footman and then a town hall: the camera is on the town hall (x 14, y 12)
  LRandomRef := TScriptedRandom.Create([0, 0, 0]);
  LGame := TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable),
    MakeOptions(wraHumans, wraOrcs), FUnits, LRandomRef);
  Assert.IsTrue(LGame.HasCameraStart);
  Assert.IsTrue(FUnits.TryGetData(WAR_UNIT_TOWNHALL_HUMANS, LData));
  Assert.AreEqual(14 * WAR_MEGA_TILE_SIZE + LData.SizeX * WAR_MEGA_TILE_SIZE div 2, LGame.CameraCenterX);
  Assert.AreEqual(12 * WAR_MEGA_TILE_SIZE + LData.SizeY * WAR_MEGA_TILE_SIZE div 2, LGame.CameraCenterY);
  // the second position has a farm only: the camera is on it
  LRandomRef := TScriptedRandom.Create([0, 0, 1]);
  LGame := TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable),
    MakeOptions(wraHumans, wraOrcs), FUnits, LRandomRef);
  Assert.IsTrue(FUnits.TryGetData(WAR_UNIT_FARM_HUMANS, LData));
  Assert.AreEqual(10 * WAR_MEGA_TILE_SIZE + LData.SizeX * WAR_MEGA_TILE_SIZE div 2, LGame.CameraCenterX);
end;

procedure TTestWarCustomGame.DovrebbeNonAvereLaCameraSeIlGiocatoreNonHaUnita;
var
  LRandomRef: IWarRandom;
  LGame: TWarCustomGame;
begin
  // the third position has only the enemy
  LRandomRef := TScriptedRandom.Create([0, 0, 2]);
  LGame := TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable),
    MakeOptions(wraHumans, wraOrcs), FUnits, LRandomRef);
  Assert.IsFalse(LGame.HasCameraStart);
end;

procedure TTestWarCustomGame.DovrebbeSostituireOroELegnaDeiDueGiocatori;
var
  LRandomRef: IWarRandom;
  LGame: TWarCustomGame;
  LOptions: TWarCustomGameOptions;
begin
  LOptions := MakeOptions(wraHumans, wraOrcs);
  LOptions.HasGold := True;
  LOptions.Gold := 777;
  LOptions.HasWood := True;
  LOptions.Wood := 555;
  LRandomRef := TScriptedRandom.Create([0, 0, 0]);
  LGame := TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable), LOptions, FUnits,
    LRandomRef);
  Assert.AreEqual<Cardinal>(777, LGame.Info.Gold[0]);
  Assert.AreEqual<Cardinal>(777, LGame.Info.Gold[1]);
  Assert.AreEqual<Cardinal>(555, LGame.Info.Lumber[0]);
  Assert.AreEqual<Cardinal>(555, LGame.Info.Lumber[1]);
  Assert.AreEqual<Cardinal>(MakeInfo.Gold[2], LGame.Info.Gold[2]);
end;

procedure TTestWarCustomGame.DovrebbeNonCambiareIlLivelloCheDiventaUnAltro;
var
  LLevel: IWarLevel;
  LRandomRef: IWarRandom;
begin
  LLevel := TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable);
  LRandomRef := TScriptedRandom.Create([0, 0, 0]);
  TWarCustomGameMaker.Make(LLevel, MakeOptions(wraOrcs, wraOrcs), FUnits, LRandomRef);
  // the original changed the record of the archive; here the level is as it was
  Assert.AreEqual<Integer>(1, Length(LLevel.Info.StartEntities));
  Assert.IsTrue(LLevel.Info.Races[0] = wraHumans);
end;

procedure TTestWarCustomGame.DovrebbeRifiutareUnSeme;
var
  LOptions: TWarCustomGameOptions;
begin
  LOptions := MakeOptions(wraHumans, wraOrcs);
  LOptions.HasSeed := True;
  LOptions.Seed := 5;
  Assert.WillRaise(
    procedure
    begin
      TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable), LOptions, FUnits,
        TScriptedRandom.Create([]));
    end, EWarException);
end;

procedure TTestWarCustomGame.DovrebbeRifiutareUnLivelloCheNonEPersonalizzatoOSenzaPosizioni;
var
  LInfo: TWarLevelInfo;
begin
  LInfo := MakeInfo;
  LInfo.CustomMap := False;
  Assert.WillRaise(
    procedure
    begin
      TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(LInfo, TMapFixtures.EmptyPassable), MakeOptions(wraHumans,
        wraOrcs), FUnits, TScriptedRandom.Create([]));
    end, EWarException);
  LInfo := MakeInfo;
  LInfo.StartConfigurations := nil;
  Assert.WillRaise(
    procedure
    begin
      TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(LInfo, TMapFixtures.EmptyPassable), MakeOptions(wraHumans,
        wraOrcs), FUnits, TScriptedRandom.Create([]));
    end, EWarException);
end;

procedure TTestWarCustomGame.DovrebbeRifiutareUnTipoDiUnitaCheNonHaTabelle;
var
  LInfo: TWarLevelInfo;
  LConfiguration: TWarCustomMapConfiguration;
begin
  LInfo := MakeInfo;
  // the type 250 is no unit (a unit of the player is the one that sets the camera and needs its size)
  LConfiguration.StartEntities := [TMapFixtures.StartUnit(10, 12, 250, 0, wrkNone, 0)];
  LInfo.StartConfigurations := [LConfiguration];
  Assert.WillRaise(
    procedure
    begin
      TWarCustomGameMaker.Make(TMapFixtures.MakeLevel(LInfo, TMapFixtures.EmptyPassable), MakeOptions(wraHumans,
        wraOrcs), FUnits, TScriptedRandom.Create([0, 0, 0]));
    end, EWarException);
end;

procedure TTestWarCustomGame.DovrebbeDareIlLivelloConLeInfoDellaPartitaEIDatiDelBase;
var
  LBase: IWarLevel;
  LLevel: IWarLevel;
  LInfo: TWarLevelInfo;
  LVisual: TArray<Word>;
begin
  LBase := TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable);
  LInfo := LBase.Info;
  LInfo.Index := 999;
  LLevel := TWarCustomLevel.Create(LBase, LInfo);
  Assert.AreEqual<Integer>(999, LLevel.Info.Index);
  Assert.AreEqual<Integer>(150, LBase.Info.Index);
  // the maps are those of the base level, shared
  Assert.AreEqual<Integer>(Length(LBase.Visual), Length(LLevel.Visual));
  Assert.AreEqual<Integer>(Length(LBase.Passable), Length(LLevel.Passable));
  Assert.AreEqual<Integer>(Integer(LBase.VisualAt(3, 3)), Integer(LLevel.VisualAt(3, 3)));
  Assert.AreEqual<Integer>(Integer(LBase.PassableAt(3, 3)), Integer(LLevel.PassableAt(3, 3)));
  LVisual := LLevel.Visual;
  LVisual[0] := 77;
  Assert.AreEqual<Integer>(77, Integer(LBase.Visual[0]));
end;

procedure TTestWarCustomGame.DovrebbeCominciareLaCameraDovePiaceAllaPartitaEDentroLaMappa;
var
  LBuilder: TWarMapBuilder;
  LLevel: IWarLevel;
  LMap: TWarGameMap;
begin
  LBuilder := TWarMapFactory.CreateBuilder;
  try
    LLevel := TMapFixtures.MakeLevel(MakeInfo, TMapFixtures.EmptyPassable);
    // in the middle: the point is the middle of the screen of 240 x 176
    LMap := LBuilder.Build(LLevel, TMapFixtures.Tileset, True, 500, 400);
    try
      Assert.AreEqual<Integer>(500 - 120, Integer(Round(LMap.Viewport.X)));
      Assert.AreEqual<Integer>(400 - 88, Integer(Round(LMap.Viewport.Y)));
    finally
      LMap.Free;
    end;
    // a point at the corners is held inside the map
    LMap := LBuilder.Build(LLevel, TMapFixtures.Tileset, True, 5, 5);
    try
      Assert.AreEqual<Integer>(0, Integer(Round(LMap.Viewport.X)));
      Assert.AreEqual<Integer>(0, Integer(Round(LMap.Viewport.Y)));
    finally
      LMap.Free;
    end;
    LMap := LBuilder.Build(LLevel, TMapFixtures.Tileset, True, 1020, 1020);
    try
      Assert.AreEqual<Integer>(1024 - 240, Integer(Round(LMap.Viewport.X)));
      Assert.AreEqual<Integer>(1024 - 176, Integer(Round(LMap.Viewport.Y)));
    finally
      LMap.Free;
    end;
  finally
    LBuilder.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarCustomGame);

end.
