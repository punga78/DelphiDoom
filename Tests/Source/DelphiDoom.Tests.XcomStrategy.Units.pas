{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - the small pieces on   }
{  a real saved game: the events that nobody listens to, the crafts of a base, }
{  the regions of a point, the loss of a craft and the end of the game         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.Units;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.Region, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.Events.Intf, DelphiDoom.XcomStrategy.NullEvents,
  DelphiDoom.XcomStrategy.DefaultSettings, DelphiDoom.XcomStrategy.Factory, DelphiDoom.XcomStrategy.Simulation,
  DelphiDoom.XcomStrategy.BaseCrafts, DelphiDoom.XcomStrategy.Geography, DelphiDoom.Tests.XcomSave.Sim;

type
  [TestFixture]
  [Category('xcom-strategy')]
  TTestXcomStrategyUnits = class(TObject)
  strict private
    FSim: TXcomSim;
    FRandom: IXcomRandom;
    function Load(AIndex: Integer): TXcomSavedGame;
    function Simulation(const AGame: TXcomSavedGame; const AEvents: IXcomGeoscapeEvents): TXcomGeoscapeSimulation;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeIgnorareTuttiGliEventiConGliEventiNulli;
    [Test]
    procedure DovrebbeContareIVelivoliDiUnTipoEScaricareQuelloCheSiToglie;
    [Test]
    procedure DovrebbeTrovareRegioneEPaeseDiUnPunto;
    [Test]
    procedure DovrebbeConvertireLeMiglia;
    [Test]
    procedure DovrebbeUccidereUnSoldatoDiUnaBase;
    [Test]
    procedure DovrebbePerdereUnVelivoloDistruttoConIlSuoEquipaggio;
    [Test]
    procedure DovrebbeFinireLaPartitaSenzaBasi;
  end;

implementation

type
  /// <summary>Counts the events of one kind (the end of the game)</summary>
  TXcomCountingEvents = class(TXcomNullGeoscapeEvents)
  public
    Lost: Integer;
    procedure GameLost; override;
  end;

procedure TXcomCountingEvents.GameLost;
begin
  Inc(Lost);
end;

{ TTestXcomStrategyUnits }

procedure TTestXcomStrategyUnits.SetupFixture;
begin
  FSim := TXcomSim.Create;
end;

procedure TTestXcomStrategyUnits.TearDownFixture;
begin
  FSim.Free;
end;

function TTestXcomStrategyUnits.Load(AIndex: Integer): TXcomSavedGame;
begin
  FRandom := TXcomRandom.Create(1);
  Result := FSim.LoadSave(AIndex, FRandom);
end;

function TTestXcomStrategyUnits.Simulation(const AGame: TXcomSavedGame; const AEvents: IXcomGeoscapeEvents)
  : TXcomGeoscapeSimulation;
begin
  Result := TXcomStrategyFactory.CreateSimulation(AGame, FSim.Ruleset, nil, FRandom, nil, AEvents,
    TXcomDefaultStrategySettings.Create, FSim.Settings);
end;

procedure TTestXcomStrategyUnits.DovrebbeIgnorareTuttiGliEventiConGliEventiNulli;
var
  LEvents: IXcomGeoscapeEvents;
  LGame: TXcomSavedGame;
  LWaypoint: TXcomWaypoint;
begin
  if not FSim.Available then
  begin
    Assert.Pass('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  LGame := Load(2);
  try
    LEvents := TXcomNullGeoscapeEvents.Create;
    LEvents.GameLost;
    LEvents.UfoDetected(nil, True);
    LEvents.UfoLost(nil);
    LEvents.MissionDetected(nil);
    LEvents.BaseAttacked(LGame.Bases.First, nil);
    LWaypoint := TXcomWaypoint.Create;
    // the waypoint is the receiver's: the null events free it
    LEvents.CraftNeedsOrders(nil, LWaypoint);
    LEvents.DogfightRequested(nil, nil);
    LEvents.DogfightImpossible(nil, 'x');
    LEvents.LandingPossible(nil, nil);
    LEvents.CraftPatrolling(nil);
    LEvents.LowFuel(nil);
    LEvents.CraftShortage(LGame.Bases.First, nil, 'x', True);
    LEvents.ItemsArriving;
    LEvents.ProductionFinished(LGame.Bases.First, 'x', ppComplete);
    LEvents.FacilityBuilt(LGame.Bases.First, nil);
    LEvents.ResearchFinished(LGame.Bases.First, 'x');
    LEvents.StorageExceeded(LGame.Bases.First);
    LEvents.AlienBaseDiscovered(nil);
    LEvents.AutosaveDue(False);
    LEvents.MonthlyReport(True);
    Assert.IsTrue(True);
  finally
    LEvents := nil;
    LGame.Free;
  end;
end;

procedure TTestXcomStrategyUnits.DovrebbeContareIVelivoliDiUnTipoEScaricareQuelloCheSiToglie;
var
  LGame: TXcomSavedGame;
  LBase: TXcomBase;
  LCraft, LRemoved: TXcomCraft;
  LType: string;
  LBefore, LCount: Integer;
begin
  if not FSim.Available then
  begin
    Assert.Pass('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  LGame := Load(2);
  try
    LBase := LGame.Bases.First;
    Assert.IsTrue(LBase.Crafts.Count > 0, 'la base ha dei velivoli');
    LCraft := LBase.Crafts.First;
    LType := LCraft.Rules.CraftType;
    LCount := 0;
    for LRemoved in LBase.Crafts do
      if LRemoved.Rules.CraftType = LType then
        Inc(LCount);
    Assert.AreEqual(LCount, TXcomBaseCrafts.Count(LBase, LType), 'velivoli del tipo');
    Assert.AreEqual(0, TXcomBaseCrafts.Count(LBase, 'STR_NONE'), 'tipo che non c''e');
    LBefore := LBase.Crafts.Count;
    LRemoved := TXcomBaseCrafts.Remove(LBase, LCraft, True, FSim.Ruleset);
    try
      Assert.AreSame(LCraft, LRemoved, 'il velivolo tolto e'' lo stesso');
      Assert.AreEqual(LBefore - 1, LBase.Crafts.Count, 'e'' uscito dalla base');
    finally
      LRemoved.Free;
    end;
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomStrategyUnits.DovrebbeTrovareRegioneEPaeseDiUnPunto;
var
  LGame: TXcomSavedGame;
  LBase: TXcomBase;
  LRegion: TXcomRegion;
  LBefore, LActivity: Integer;
begin
  if not FSim.Available then
  begin
    Assert.Pass('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  LGame := Load(2);
  try
    LBase := LGame.Bases.First;
    LRegion := TXcomGeography.LocateRegion(LGame, LBase.Longitude, LBase.Latitude);
    Assert.IsNotNull(LRegion, 'regione della base');
    // the sea has no country: the first region that holds the point is found, a country only if there is one
    TXcomGeography.LocateCountry(LGame, LBase.Longitude, LBase.Latitude);
    LBefore := Length(LRegion.ActivityAlien);
    LActivity := LRegion.ActivityAlien[High(LRegion.ActivityAlien)];
    TXcomGeography.AddAlienActivity(LGame, LBase.Longitude, LBase.Latitude, 7);
    Assert.AreEqual(LActivity + 7, LRegion.ActivityAlien[High(LRegion.ActivityAlien)], 'punti');
    Assert.AreEqual(LBefore, Length(LRegion.ActivityAlien), 'stesso mese');
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomStrategyUnits.DovrebbeConvertireLeMiglia;
begin
  // 60 nautical miles are one degree
  Assert.AreEqual(Double(3.14159265358979323846 / 180.0), TXcomGeography.Nautical(60), 1E-15);
  Assert.AreEqual(Double(0), TXcomGeography.Nautical(0), 0);
end;

procedure TTestXcomStrategyUnits.DovrebbeUccidereUnSoldatoDiUnaBase;
var
  LGame: TXcomSavedGame;
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
  LSoldiers, LDead: Integer;
begin
  if not FSim.Available then
  begin
    Assert.Pass('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  LGame := Load(2);
  try
    LBase := LGame.Bases.First;
    LSoldier := LBase.Soldiers.First;
    LSoldiers := LBase.Soldiers.Count;
    LDead := LGame.DeadSoldiers.Count;
    Assert.AreSame(LBase, TXcomGeography.KillSoldier(LGame, LSoldier), 'la base del soldato');
    Assert.AreEqual(LSoldiers - 1, LBase.Soldiers.Count, 'esce dalla base');
    Assert.AreEqual(LDead + 1, LGame.DeadSoldiers.Count, 'va tra i morti');
    // a soldier that is in no base is nobody's
    Assert.IsNull(TXcomGeography.KillSoldier(LGame, LGame.DeadSoldiers.Last), 'un morto non e'' in nessuna base');
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomStrategyUnits.DovrebbePerdereUnVelivoloDistruttoConIlSuoEquipaggio;
var
  LGame: TXcomSavedGame;
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LSimulation: TXcomGeoscapeSimulation;
  LHolder: IInterface;
  LCrew, LCrafts, LDead: Integer;
begin
  if not FSim.Available then
  begin
    Assert.Pass('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  LGame := Load(2);
  try
    LBase := LGame.Bases.First;
    LCraft := nil;
    for LCrafts := 0 to LBase.Crafts.Count - 1 do
      if LBase.Crafts[LCrafts].NumSoldiers(LBase.Soldiers) > 0 then
        LCraft := LBase.Crafts[LCrafts];
    Assert.IsNotNull(LCraft, 'un velivolo con equipaggio');
    LCrew := LCraft.NumSoldiers(LBase.Soldiers);
    LCrafts := LBase.Crafts.Count;
    LDead := LGame.DeadSoldiers.Count;
    LCraft.SetDamage(LCraft.Rules.MaxDamage);
    LSimulation := Simulation(LGame, TXcomNullGeoscapeEvents.Create);
    LHolder := LSimulation;
    LSimulation.Time5Seconds;
    Assert.AreEqual(LCrafts - 1, LBase.Crafts.Count, 'velivolo perso');
    Assert.AreEqual(LDead + LCrew, LGame.DeadSoldiers.Count, 'equipaggio morto');
  finally
    LHolder := nil;
    LGame.Free;
  end;
end;

procedure TTestXcomStrategyUnits.DovrebbeFinireLaPartitaSenzaBasi;
var
  LGame: TXcomSavedGame;
  LEvents: TXcomCountingEvents;
  LHolder: IXcomGeoscapeEvents;
  LSimulation: TXcomGeoscapeSimulation;
  LSimHolder: IInterface;
begin
  if not FSim.Available then
  begin
    Assert.Pass('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  LGame := Load(2);
  try
    LEvents := TXcomCountingEvents.Create;
    LHolder := LEvents;
    LSimulation := Simulation(LGame, LHolder);
    LSimHolder := LSimulation;
    LGame.Bases.Clear;
    LSimulation.Time5Seconds;
    Assert.AreEqual(2, LGame.EndingKind, 'fine: persa');
    Assert.AreEqual(1, LEvents.Lost, 'l''evento');
  finally
    LSimHolder := nil;
    LHolder := nil;
    LGame.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomStrategyUnits);

end.
