{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the avoidance between units and the  }
{  flow fields in the movement                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelFlowSteering;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Rvo,
  DelphiDoom.War.Model.FlowSteering, DelphiDoom.Tests.War.ModelRig;

type
  /// <summary>wrvo_computeNewVelocity: the choice among the 34 velocities (the parity with the C is in PathParity)</summary>
  [TestFixture]
  [Category('war')]
  TTestWarRvo = class(TObject)
  private
    function Vec(AX, AY: Single): TWarVec2;
    function NoNeighbours: TWarRvoNeighbours;
  public
    [Test]
    procedure DovrebbeDareLaVelocitaPreferitaSeNonCiSonoVicini;
    [Test]
    procedure DovrebbeTagliareLaVelocitaPreferitaAllaMassima;
    [Test]
    procedure DovrebbeDareLaVelocitaNullaSeNonSiVuoleAndareDaNessunaParte;
    [Test]
    procedure DovrebbeProvareTrentaquattroVelocita;
    [Test]
    procedure DovrebbeDeviareDaUnVicinoCheVieneIncontro;
    [Test]
    procedure DovrebbeSegnareCheOgniVelocitaCollideSeSiELGiaSovrapposti;
    [Test]
    procedure DovrebbeNonSegnareCollisioniConUnVicinoLontano;
    [Test]
    procedure DovrebbeDareSempreUnaVelocitaNonPiuLungaDellaMassima;
    [Test]
    procedure DovrebbeIgnorareIlPassoDelTempo;
    [Test]
    procedure DovrebbeNonDareDebugSeNonLoSiChiede;
  end;

  /// <summary>The units that go around the obstacles and each other (TWarFlowSteering)</summary>
  [TestFixture]
  [Category('war')]
  TTestWarFlowSteering = class(TObject)
  private
    FRig: TModelRig;
    FSteering: TWarFlowSteering;
    function Center(ASlot: Integer): TWarVec2;
    function Pixel(ATileX, ATileY: Integer): TWarVec2;
    procedure Walk(ASlot, ATileX, ATileY: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNonUsareNessunPercorsoSeNonCEIlCercatore;
    [Test]
    procedure DovrebbeGirareAttornoAUnMuroSenzaMaiEntrarviEArrivare;
    [Test]
    procedure DovrebbeFermarsiDavantiAUnMuroLungoPerLaDistanzaDalGoalCheNonScende;
    [Test]
    procedure DovrebbeFarePassareUnaUnitaAttornoAUnaFermaSullaStradaDaCaselleOccupate;
    [Test]
    procedure DovrebbeTenereDistanzeFraDueUnitaCheSiIncrociano;
    [Test]
    procedure DovrebbeFareIlCampoDiFlussoDelBersaglioQuandoUnComandoDiMovimentoHaUnaSelezione;
    [Test]
    procedure DovrebbeNonFareIlCampoDiFlussoSeUnComandoDiMovimentoNonHaSelezione;
    [Test]
    procedure DovrebbeFarePartireIlCampoDiFlussoDelBersaglioDiUnOrdineDiMovimento;
    [Test]
    procedure DovrebbeUsareLoStessoCampoDiFlussoPerPiuUnitaVersoLaStessaCasella;
    [Test]
    procedure DovrebbeRifareIlCampoDiFlussoDellaCasellaDelProssimoPuntoAllaPrimaRipresa;
    [Test]
    procedure DovrebbeDareDieciSeiViciniAlPiu;
    [Test]
    procedure DovrebbeEscludereSeStessaEChiENelRaggio;
    [Test]
    procedure DovrebbeDareLaVelocitaDelloStatoDiMovimentoAnchePiuInBassoNellaPila;
    [Test]
    procedure DovrebbeNonDareViciniSeNessunoCostruisceLaGriglia;
    [Test]
    procedure DovrebbeLeggereLaGrigliaDelTicPrecedente;
    [Test]
    procedure DovrebbeDareLaVelocitaMassimaSuUnPercorsoLiberoELentaVicinoAlGoal;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.Commands.Types, DelphiDoom.War.Path.FlowFields, DelphiDoom.Tests.War.CommandRig;

{ TTestWarRvo }

function TTestWarRvo.Vec(AX, AY: Single): TWarVec2;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function TTestWarRvo.NoNeighbours: TWarRvoNeighbours;
begin
  Result.Count := 0;
end;

procedure TTestWarRvo.DovrebbeDareLaVelocitaPreferitaSeNonCiSonoVicini;
var
  LResult: TWarVec2;
begin
  LResult := TWarRvo.ComputeNewVelocity(Vec(3, 4), Vec(100, 100), Vec(0, 0), 7.2, 10, 0.016, NoNeighbours);
  Assert.IsTrue((LResult.X = 3) and (LResult.Y = 4));
end;

procedure TTestWarRvo.DovrebbeTagliareLaVelocitaPreferitaAllaMassima;
var
  LResult: TWarVec2;
begin
  LResult := TWarRvo.ComputeNewVelocity(Vec(30, 40), Vec(100, 100), Vec(0, 0), 7.2, 10, 0.016, NoNeighbours);
  Assert.IsTrue(Abs(Sqrt(LResult.X * LResult.X + LResult.Y * LResult.Y) - 10) < 0.001);
  Assert.IsTrue(Abs(LResult.X - 6) < 0.001);
  Assert.IsTrue(Abs(LResult.Y - 8) < 0.001);
end;

procedure TTestWarRvo.DovrebbeDareLaVelocitaNullaSeNonSiVuoleAndareDaNessunaParte;
var
  LResult: TWarVec2;
begin
  LResult := TWarRvo.ComputeNewVelocity(Vec(0, 0), Vec(100, 100), Vec(0, 0), 7.2, 10, 0.016, NoNeighbours);
  Assert.IsTrue((LResult.X = 0) and (LResult.Y = 0));
end;

procedure TTestWarRvo.DovrebbeProvareTrentaquattroVelocita;
var
  LDebug: TWarRvoDebug;
begin
  TWarRvo.ComputeNewVelocity(Vec(5, 0), Vec(100, 100), Vec(0, 0), 7.2, 10, 0.016, NoNeighbours, @LDebug);
  Assert.AreEqual(WAR_RVO_MAX_CANDIDATES, LDebug.Count);
  Assert.AreEqual(34, LDebug.Count);
  // the first one is the preferred velocity and the last is the stop
  Assert.IsTrue((LDebug.Candidates[0].X = 5) and (LDebug.Candidates[0].Y = 0));
  Assert.IsTrue((LDebug.Candidates[33].X = 0) and (LDebug.Candidates[33].Y = 0));
  // the first of the list wins a tie: nobody is near, the preferred velocity costs nothing
  Assert.AreEqual(0, LDebug.BestIndex);
end;

procedure TTestWarRvo.DovrebbeDeviareDaUnVicinoCheVieneIncontro;
var
  LNeighbours: TWarRvoNeighbours;
  LResult: TWarVec2;
begin
  LNeighbours.Count := 1;
  LNeighbours.Items[0].Position := Vec(140, 100);
  LNeighbours.Items[0].Velocity := Vec(-10, 0);
  LNeighbours.Items[0].Radius := 7.2;
  LResult := TWarRvo.ComputeNewVelocity(Vec(10, 0), Vec(100, 100), Vec(10, 0), 7.2, 10, 0.016, LNeighbours);
  // it does not go on straight at the neighbor
  Assert.IsFalse((LResult.X = 10) and (LResult.Y = 0));
end;

procedure TTestWarRvo.DovrebbeSegnareCheOgniVelocitaCollideSeSiELGiaSovrapposti;
var
  LNeighbours: TWarRvoNeighbours;
  LDebug: TWarRvoDebug;
  LIndex: Integer;
begin
  LNeighbours.Count := 1;
  LNeighbours.Items[0].Position := Vec(104, 100);
  LNeighbours.Items[0].Velocity := Vec(0, 0);
  LNeighbours.Items[0].Radius := 7.2;
  TWarRvo.ComputeNewVelocity(Vec(10, 0), Vec(100, 100), Vec(0, 0), 7.2, 10, 0.016, LNeighbours, @LDebug);
  for LIndex := 0 to LDebug.Count - 1 do
    Assert.IsTrue(LDebug.HadCollision[LIndex], 'la velocita ' + IntToStr(LIndex));
end;

procedure TTestWarRvo.DovrebbeNonSegnareCollisioniConUnVicinoLontano;
var
  LNeighbours: TWarRvoNeighbours;
  LDebug: TWarRvoDebug;
  LIndex: Integer;
begin
  LNeighbours.Count := 1;
  LNeighbours.Items[0].Position := Vec(1000, 1000);
  LNeighbours.Items[0].Velocity := Vec(0, 0);
  LNeighbours.Items[0].Radius := 7.2;
  TWarRvo.ComputeNewVelocity(Vec(10, 0), Vec(100, 100), Vec(0, 0), 7.2, 10, 0.016, LNeighbours, @LDebug);
  for LIndex := 0 to LDebug.Count - 1 do
    Assert.IsFalse(LDebug.HadCollision[LIndex]);
end;

procedure TTestWarRvo.DovrebbeDareSempreUnaVelocitaNonPiuLungaDellaMassima;
var
  LResult: TWarVec2;
  LLength: Single;
begin
  LResult := TWarRvo.ComputeNewVelocity(Vec(300, -400), Vec(100, 100), Vec(0, 0), 7.2, 12, 0.016, NoNeighbours);
  LLength := Sqrt(LResult.X * LResult.X + LResult.Y * LResult.Y);
  Assert.IsTrue(LLength <= 12.001);
end;

procedure TTestWarRvo.DovrebbeIgnorareIlPassoDelTempo;
var
  LFirst: TWarVec2;
  LSecond: TWarVec2;
begin
  LFirst := TWarRvo.ComputeNewVelocity(Vec(30, 40), Vec(100, 100), Vec(0, 0), 7.2, 10, 0.016, NoNeighbours);
  LSecond := TWarRvo.ComputeNewVelocity(Vec(30, 40), Vec(100, 100), Vec(0, 0), 7.2, 10, 5.0, NoNeighbours);
  Assert.IsTrue((LFirst.X = LSecond.X) and (LFirst.Y = LSecond.Y));
end;

procedure TTestWarRvo.DovrebbeNonDareDebugSeNonLoSiChiede;
begin
  // nil is the case of the game: no output to fill
  Assert.WillNotRaise(
    procedure
    begin
      TWarRvo.ComputeNewVelocity(Vec(1, 1), Vec(0, 0), Vec(0, 0), 7.2, 10, 0.016, NoNeighbours, nil);
    end);
end;

{ TTestWarFlowSteering }

procedure TTestWarFlowSteering.Setup;
begin
  FRig := TModelRig.Create;
  TWarModelFactory.AttachFlowSteering(FRig.World, FRig.Grid);
  FSteering := FRig.World.Context.Steering as TWarFlowSteering;
end;

procedure TTestWarFlowSteering.TearDown;
begin
  FSteering := nil;
  FRig.Free;
end;

function TTestWarFlowSteering.Center(ASlot: Integer): TWarVec2;
begin
  Result := TWarUnitGeometry.CenterPosition(FRig.Entity(ASlot));
end;

function TTestWarFlowSteering.Pixel(ATileX, ATileY: Integer): TWarVec2;
begin
  Result.X := ATileX * 16 + 8;
  Result.Y := ATileY * 16 + 8;
end;

procedure TTestWarFlowSteering.Walk(ASlot, ATileX, ATileY: Integer);
begin
  FRig.Move(ASlot, [Center(ASlot), Pixel(ATileX, ATileY)]);
end;

procedure TTestWarFlowSteering.DovrebbeNonUsareNessunPercorsoSeNonCEIlCercatore;
var
  LRig: TModelRig;
begin
  LRig := TModelRig.Create;
  try
    Assert.IsFalse(Assigned(LRig.World.Context.Steering));
  finally
    LRig.Free;
  end;
end;

procedure TTestWarFlowSteering.DovrebbeGirareAttornoAUnMuroSenzaMaiEntrarviEArrivare;
var
  LSlot: Integer;
  LTic: Integer;
  LTile: TWarVec2;
  LInside: Boolean;
  LCrossing: Single;
begin
  FRig.Grid.SetStaticEntity(20, 14, 1, 3, 9);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 14, 15);
  Walk(LSlot, 26, 15);
  LInside := False;
  LCrossing := -1;
  for LTic := 1 to 3600 do
  begin
    FRig.TickAll;
    // the units are not stopped by the static tiles (nothing in the original does it): they follow the flow field, which
    // never points into a static tile. What it shows is where the unit is when it passes the column of the wall
    if (LCrossing < 0) and (Center(LSlot).X >= Pixel(20, 15).X) then
    begin
      LCrossing := Center(LSlot).Y;
      LTile.Y := LCrossing;
    end;
    if FRig.ActiveType(LSlot) = WAR_STATE_IDLE then
      Break;
  end;
  // going straight it would pass the column at the height of the middle of the wall (y = 248); the flow field deflects it
  LInside := Abs(LCrossing - Pixel(20, 15).Y) < 8;
  Assert.IsTrue(LCrossing >= 0, 'passa la colonna del muro');
  Assert.IsFalse(LInside, 'la unita passa deviata dal muro: ' + FloatToStr(LCrossing));
  Assert.AreEqual(WAR_STATE_IDLE, FRig.ActiveType(LSlot), 'e arrivata');
  Assert.IsTrue(Abs(Center(LSlot).X - Pixel(26, 15).X) < 1.0, Format('x %f', [Center(LSlot).X]));
  Assert.IsTrue(Abs(Center(LSlot).Y - Pixel(26, 15).Y) < 1.0, Format('y %f', [Center(LSlot).Y]));
end;

procedure TTestWarFlowSteering.DovrebbeFermarsiDavantiAUnMuroLungoPerLaDistanzaDalGoalCheNonScende;
var
  LSlot: Integer;
  LTic: Integer;
  LState: PWarStateBase;
begin
  // defect of the original kept: the progress of a unit is its distance from the next waypoint in a straight line, and a
  // unit that goes around a long wall moves away from it: after 3 seconds without getting 4 pixels closer the move ends
  // with BLOCKED and the unit stands where it is, short of the goal
  FRig.Grid.SetStaticEntity(20, 0, 1, 30, 9);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 14, 15);
  Walk(LSlot, 26, 15);
  for LTic := 1 to 3600 do
  begin
    FRig.TickAll;
    LState := FRig.World.Machine.ActiveState(LSlot);
    if Assigned(LState) and (LState^.StateType = WAR_STATE_IDLE) then
      Break;
  end;
  Assert.AreEqual(WAR_STATE_IDLE, FRig.ActiveType(LSlot));
  Assert.IsTrue(Center(LSlot).X < Pixel(20, 15).X, 'resta da questa parte del muro');
end;

procedure TTestWarFlowSteering.DovrebbeFarePassareUnaUnitaAttornoAUnaFermaSullaStradaDaCaselleOccupate;
var
  LMover: Integer;
  LStanding: Integer;
  LTic: Integer;
  LCloser: Single;
  LDistance: Single;
  LDx: Single;
  LDy: Single;
begin
  LStanding := FRig.AddDude(WAR_UNIT_FOOTMAN, 20, 15);
  LMover := FRig.AddDude(WAR_UNIT_FOOTMAN, 12, 15);
  Walk(LMover, 28, 15);
  LCloser := 1000;
  for LTic := 1 to 3600 do
  begin
    FRig.TickAll;
    LDx := Center(LMover).X - Center(LStanding).X;
    LDy := Center(LMover).Y - Center(LStanding).Y;
    LDistance := Sqrt(LDx * LDx + LDy * LDy);
    if LDistance < LCloser then
      LCloser := LDistance;
    if FRig.ActiveType(LMover) = WAR_STATE_IDLE then
      Break;
  end;
  // a unit that stands still is static on the grid: the flow field goes around its tile
  Assert.IsTrue(LCloser >= 8, 'passa addosso');
  Assert.AreEqual(WAR_STATE_IDLE, FRig.ActiveType(LMover));
end;

procedure TTestWarFlowSteering.DovrebbeTenereDistanzeFraDueUnitaCheSiIncrociano;
var
  LLeft: Integer;
  LRight: Integer;
  LTic: Integer;
  LMinimum: Single;
  LDx: Single;
  LDy: Single;
  LDistance: Single;
begin
  LLeft := FRig.AddDude(WAR_UNIT_FOOTMAN, 8, 30);
  LRight := FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30);
  Walk(LLeft, 30, 30);
  Walk(LRight, 8, 30);
  LMinimum := 1000;
  for LTic := 1 to 3600 do
  begin
    FRig.TickAll;
    LDx := Center(LLeft).X - Center(LRight).X;
    LDy := Center(LLeft).Y - Center(LRight).Y;
    LDistance := Sqrt(LDx * LDx + LDy * LDy);
    if LDistance < LMinimum then
      LMinimum := LDistance;
  end;
  // each one is a disc of 7.2 pixels for the avoidance: they do not go through each other
  Assert.IsTrue(LMinimum > 6.0, 'distanza minima ' + FloatToStr(LMinimum));
end;

procedure TTestWarFlowSteering.DovrebbeFareIlCampoDiFlussoDelBersaglioQuandoUnComandoDiMovimentoHaUnaSelezione;
var
  LRig: TCommandRig;
  LSteering: TWarFlowSteering;
  LSlot: Integer;
begin
  LRig := TCommandRig.Create;
  try
    TWarModelFactory.AttachFlowSteering(LRig.World, LRig.Grid);
    LSteering := LRig.Context.Steering as TWarFlowSteering;
    LSlot := LRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
    LRig.Select([LSlot]);
    // wcmd_executeMoveCommand makes the flow field of the target before it gives the orders
    Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, LRig.Commands.Execute(WAR_COMMAND_MOVE, LRig.TilePoint(30, 12)));
    Assert.AreEqual(1, LSteering.Fields.ComputeCount);
    Assert.IsNotNull(LSteering.Fields.Get(30, 12));
    // and again for every order
    LRig.Commands.Execute(WAR_COMMAND_MOVE, LRig.TilePoint(30, 12));
    Assert.AreEqual(2, LSteering.Fields.ComputeCount);
  finally
    LRig.Free;
  end;
end;

procedure TTestWarFlowSteering.DovrebbeNonFareIlCampoDiFlussoSeUnComandoDiMovimentoNonHaSelezione;
var
  LRig: TCommandRig;
  LSteering: TWarFlowSteering;
begin
  LRig := TCommandRig.Create;
  try
    TWarModelFactory.AttachFlowSteering(LRig.World, LRig.Grid);
    LSteering := LRig.Context.Steering as TWarFlowSteering;
    LRig.Commands.Execute(WAR_COMMAND_MOVE, LRig.TilePoint(30, 12));
    Assert.AreEqual(0, LSteering.Fields.ComputeCount);
  finally
    LRig.Free;
  end;
end;

procedure TTestWarFlowSteering.DovrebbeFarePartireIlCampoDiFlussoDelBersaglioDiUnOrdineDiMovimento;
begin
  Assert.AreEqual(0, FSteering.Fields.Count);
  FSteering.PlanMove(Pixel(30, 12));
  Assert.AreEqual(1, FSteering.Fields.Count);
  Assert.IsNotNull(FSteering.Fields.Get(30, 12));
  Assert.AreEqual(1, FSteering.Fields.ComputeCount);
  // an order to the same point makes it again, as wcmd_executeMoveCommand does
  FSteering.PlanMove(Pixel(30, 12));
  Assert.AreEqual(2, FSteering.Fields.ComputeCount);
end;

procedure TTestWarFlowSteering.DovrebbeUsareLoStessoCampoDiFlussoPerPiuUnitaVersoLaStessaCasella;
var
  LFirst: Integer;
  LSecond: Integer;
begin
  LFirst := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5);
  LSecond := FRig.AddDude(WAR_UNIT_GRUNT, 5, 9);
  Walk(LFirst, 40, 20);
  Walk(LSecond, 40, 20);
  FRig.TickAll(3);
  // the field of the goal tile is made once, by the first unit that asks
  Assert.AreEqual(1, FSteering.Fields.Count);
  Assert.AreEqual(1, FSteering.Fields.ComputeCount);
end;

procedure TTestWarFlowSteering.DovrebbeRifareIlCampoDiFlussoDellaCasellaDelProssimoPuntoAllaPrimaRipresa;
begin
  FSteering.RefreshFlowField(Pixel(33, 7));
  Assert.IsNotNull(FSteering.Fields.Get(33, 7));
  Assert.AreEqual(1, FSteering.Fields.ComputeCount);
  FSteering.RefreshFlowField(Pixel(33, 7));
  Assert.AreEqual(2, FSteering.Fields.ComputeCount);
end;

procedure TTestWarFlowSteering.DovrebbeDareDieciSeiViciniAlPiu;
var
  LIndex: Integer;
  LSlots: array[0..19] of Integer;
  LNeighbours: TWarRvoNeighbours;
begin
  for LIndex := 0 to 19 do
    LSlots[LIndex] := FRig.AddDude(WAR_UNIT_FOOTMAN, 30 + (LIndex mod 5), 30 + (LIndex div 5));
  FRig.TickAll;
  FSteering.Neighbours(0, Pixel(32, 31), 80, LNeighbours);
  Assert.AreEqual(WAR_RVO_MAX_NEIGHBOURS, LNeighbours.Count);
end;

procedure TTestWarFlowSteering.DovrebbeEscludereSeStessaEChiENelRaggio;
var
  LSelf: Integer;
  LNear: Integer;
  LFar: Integer;
  LNeighbours: TWarRvoNeighbours;
begin
  LSelf := FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30);
  LNear := FRig.AddDude(WAR_UNIT_FOOTMAN, 33, 30);
  LFar := FRig.AddDude(WAR_UNIT_FOOTMAN, 50, 30);
  FRig.TickAll;
  FSteering.Neighbours(FRig.Entity(LSelf)^.Id, Center(LSelf), 80, LNeighbours);
  Assert.AreEqual(1, LNeighbours.Count);
  Assert.IsTrue(LNeighbours.Items[0].Position.X = Center(LNear).X, 'posizione');
  Assert.IsTrue(LNeighbours.Items[0].Radius = Single(7.2), 'raggio');
  // the one at 20 tiles is out of the 5 tiles
  Assert.IsTrue(Center(LFar).X - Center(LSelf).X > 80, 'il lontano');
end;

procedure TTestWarFlowSteering.DovrebbeDareLaVelocitaDelloStatoDiMovimentoAnchePiuInBassoNellaPila;
var
  LMover: Integer;
  LWatcher: Integer;
  LNeighbours: TWarRvoNeighbours;
  LState: PWarStateMove;
  LWait: PWarStateWait;
begin
  LWatcher := FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30);
  LMover := FRig.AddDude(WAR_UNIT_FOOTMAN, 33, 30);
  Walk(LMover, 50, 30);
  FRig.TickAll(5);
  LState := PWarStateMove(FRig.World.Machine.FindState(LMover, WAR_STATE_MOVE));
  Assert.IsTrue(LState^.RvoVelocity.X > 0, 'si muove');
  // a wait on top of the move: the move is not the active state but it is still in the stack
  LWait := FRig.World.Machine.CreateWait(LMover, 5.0);
  FRig.World.Machine.PushState(LMover, PWarStateBase(LWait), WAR_CAUSE_AI_ORDER);
  FRig.TickAll(2);
  FSteering.Neighbours(FRig.Entity(LWatcher)^.Id, Center(LWatcher), 80, LNeighbours);
  Assert.AreEqual(1, LNeighbours.Count);
  Assert.IsTrue(LNeighbours.Items[0].Velocity.X = LState^.RvoVelocity.X);
end;

procedure TTestWarFlowSteering.DovrebbeNonDareViciniSeNessunoCostruisceLaGriglia;
var
  LOne: Integer;
  LNeighbours: TWarRvoNeighbours;
  LGrid: TObject;
begin
  LOne := FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30);
  FRig.AddDude(WAR_UNIT_FOOTMAN, 31, 30);
  FRig.TickAll;
  LGrid := FRig.World.Context.UnitGrid;
  Assert.IsNotNull(LGrid);
  FRig.World.Context.UnitGrid := nil;
  FSteering.Neighbours(FRig.Entity(LOne)^.Id, Center(LOne), 80, LNeighbours);
  Assert.AreEqual(0, LNeighbours.Count);
end;

procedure TTestWarFlowSteering.DovrebbeLeggereLaGrigliaDelTicPrecedente;
var
  LOne: Integer;
  LTwo: Integer;
  LNeighbours: TWarRvoNeighbours;
begin
  LOne := FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30);
  // the grid is built after the states: a unit that has just been made is not in the grid of the tic before
  LTwo := FRig.AddDude(WAR_UNIT_FOOTMAN, 31, 30);
  FSteering.Neighbours(FRig.Entity(LOne)^.Id, Center(LOne), 80, LNeighbours);
  // the rig ticks only the states: the grid is still the empty one
  Assert.AreEqual(0, LNeighbours.Count);
  FRig.TickAll;
  FSteering.Neighbours(FRig.Entity(LOne)^.Id, Center(LOne), 80, LNeighbours);
  Assert.AreEqual(1, LNeighbours.Count);
  Assert.IsTrue(LTwo <> 0);
end;

procedure TTestWarFlowSteering.DovrebbeDareLaVelocitaMassimaSuUnPercorsoLiberoELentaVicinoAlGoal;
var
  LSlot: Integer;
  LState: PWarStateMove;
  LSpeed: Single;
  LLength: Single;
  LTic: Integer;
begin
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 30);
  Walk(LSlot, 50, 30);
  FRig.TickAll(10);
  LState := PWarStateMove(FRig.World.Machine.FindState(LSlot, WAR_STATE_MOVE));
  LSpeed := FRig.World.Context.UnitSpeed(FRig.Entity(LSlot)^.UnitData.UnitType, FRig.Entity(LSlot)^.UnitData.Speed);
  LLength := Sqrt(LState^.RvoAdjustedVelocity.X * LState^.RvoAdjustedVelocity.X +
    LState^.RvoAdjustedVelocity.Y * LState^.RvoAdjustedVelocity.Y);
  Assert.IsTrue(Abs(LLength - LSpeed) < 0.01, 'a regime e'' la velocita massima');
  for LTic := 1 to 6000 do
  begin
    FRig.TickAll;
    if Abs(Center(LSlot).X - Pixel(50, 30).X) < 40 then
      Break;
  end;
  LState := PWarStateMove(FRig.World.Machine.FindState(LSlot, WAR_STATE_MOVE));
  Assert.IsTrue(Assigned(LState));
  LLength := Sqrt(LState^.RvoAdjustedVelocity.X * LState^.RvoAdjustedVelocity.X +
    LState^.RvoAdjustedVelocity.Y * LState^.RvoAdjustedVelocity.Y);
  // within 3 tiles of the last waypoint the unit slows down, down to a quarter
  Assert.IsTrue(LLength < LSpeed, 'rallenta');
end;

end.
