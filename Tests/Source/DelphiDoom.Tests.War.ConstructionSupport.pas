{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - what building and training lean on:   }
{  the steps of the actions, the nearness of units, the walls, the free tiles   }
{  and the money                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ConstructionSupport;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.ConstructionRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarConstructionSupport = class(TObject)
  private
    FRig: TConstructionRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // the steps of the actions
    [Test]
    procedure DovrebbeLasciareStareUnAzioneSenzaTipo;
    [Test]
    procedure DovrebbeNonTornareSuUnAzioneFinita;
    [Test]
    procedure DovrebbeFermareUnAzioneCheIlTipoDiUnitaNonHa;
    [Test]
    procedure DovrebbeAspettareLaFineDellAttesaPrimaDelPassoSuccessivo;
    [Test]
    procedure DovrebbeSegnareIlColpoDelMartelloDelContadino;
    [Test]
    procedure DovrebbeSegnareIlSuonoDiUnPasso;
    [Test]
    procedure DovrebbeSpecchiareIFotogrammiDelleDirezioniAOvest;
    [Test]
    procedure DovrebbeSommareAlFotogrammaLaDirezioneNellePose;
    [Test]
    procedure DovrebbeRicominciareUnAzioneCheGira;
    [Test]
    procedure DovrebbeFinireUnAzioneCheNonGira;
    [Test]
    procedure DovrebbeRiavviareUnAzioneConIndiceNegativo;
    [Test]
    procedure DovrebbeIgnorareIlFotogrammaSeLEntitaNonHaLoSprite;
    [Test]
    procedure DovrebbeScalareLAttesaDelPassoConLaScalaDellAzione;
    // the nearness of the units
    [Test]
    procedure DovrebbeDareIlPuntoPiuVicinoDelRettangoloInOgniZona;
    [Test]
    procedure DovrebbeDareLaCasellaDelBersaglioPiuVicinaAllUnita;
    [Test]
    procedure DovrebbeDireSeIlBersaglioEInPortata;
    [Test]
    procedure DovrebbeDareIlPuntoInPixelPiuVicinoAlBersaglio;
    // the free tiles
    [Test]
    procedure DovrebbeDareLaStessaCasellaSeEVuota;
    [Test]
    procedure DovrebbeCercareLaCasellaVuotaNellOrdineDelleDirezioni;
    [Test]
    procedure DovrebbeCercareLontanoSeVicinoENonVuoto;
    [Test]
    procedure DovrebbeDareLaCasellaDiPartenzaSeLaMappaEPiena;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLaPartenzaEFuoriDallaMappa;
    [Test]
    procedure DovrebbeRispondereAlleDomandeSulleCaselleDalGrigliaDiOccupazione;
    [Test]
    procedure DovrebbeUsareLeRispostePredefiniteSenzaGrigliaNeOspite;
    [Test]
    procedure DovrebbeRipristinareLeRispostePredefiniteSeSiDaNil;
    [Test]
    procedure DovrebbeRegistrareGliStatiEPrendereLaGrigliaDallOccupazione;
    // the money
    [Test]
    procedure DovrebbeDireSeBastaIlDenaroDelPortafoglio;
    [Test]
    procedure DovrebbeSpendereTuttoONienteDalPortafoglio;
    [Test]
    procedure DovrebbeRestituireIlDenaroAlPortafoglio;
    // the walls and the ruins
    [Test]
    procedure DovrebbeCostruireUnPezzoDiMuroPagandoEDeterminandoNeIlTipo;
    [Test]
    procedure DovrebbeRifiutareUnMuroSuUnaCasellaOccupata;
    [Test]
    procedure DovrebbeRifiutareUnMuroSenzaOro;
    [Test]
    procedure DovrebbeCambiareIlTipoDeiPezziVicini;
    [Test]
    procedure DovrebbeToglierePuntiFeritaAiPezziDiMuro;
    [Test]
    procedure DovrebbeLiberareLaCasellaDiUnPezzoSenzaPuntiFerita;
    [Test]
    procedure DovrebbeOccuparePerIdLeCaselleDelMuroAdOgniTic;
    [Test]
    procedure DovrebbeSollevareEccezioneSeIlPezzoDiMuroNonEsiste;
    [Test]
    procedure DovrebbeAggiungerePezziDaUnaCostruzioneDelLivelloConPuntiFeritaPieni;
    [Test]
    procedure DovrebbeCercareUnPezzoDiMuroPerCasella;
    [Test]
    procedure DovrebbeTrattareUnPezzoSenzaMassimoComeSenzaPuntiFerita;
    [Test]
    procedure DovrebbeCrearePerPrimeLeEntitaDelMuroEDelleRovine;
    [Test]
    procedure DovrebbeNonCrearePiuEntitaDiquantePuoLaPiscina;
    // the host and the context
    [Test]
    procedure DovrebbeDareRisposteNulleDalOspitePredefinito;
    [Test]
    procedure DovrebbeTornareAlOspitePredefinitoSeSiDaNil;
    [Test]
    procedure DovrebbeDareUnImmagineDelleCostruzioniDelLaTabellaDelC;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.PathGrid,
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.ActionRunner, DelphiDoom.War.Model.TargetGeometry,
  DelphiDoom.War.Model.Purse, DelphiDoom.War.Model.Walls, DelphiDoom.War.Model.Construction.Types,
  DelphiDoom.War.Model.Construction.Intf, DelphiDoom.War.Model.Construction.NullHost,
  DelphiDoom.War.Model.GridOccupancy, DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.NullServices,
  DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.TerrainEntities,
  DelphiDoom.War.Model.ActionTable, DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.World,
  DelphiDoom.War.Autotile.Data,
  DelphiDoom.War.Sound.Intf, DelphiDoom.Tests.War.ModelObserver;

{ TTestWarConstructionSupport }

procedure TTestWarConstructionSupport.Setup;
begin
  FRig := TConstructionRig.Create;
end;

procedure TTestWarConstructionSupport.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarConstructionSupport.DovrebbeLasciareStareUnAzioneSenzaTipo;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  TWarActionTable.SetAction(FRig.Entity(LFootman)^.UnitData, WAR_ACTION_NONE, True, 1.0);
  FRig.Tick(5);
  Assert.AreEqual<Integer>(WAR_ACTION_NONE, FRig.Entity(LFootman)^.UnitData.ActionType);
end;

procedure TTestWarConstructionSupport.DovrebbeNonTornareSuUnAzioneFinita;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].Status := WAR_ACTION_FINISHED;
  FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].StepIndex := 7;
  FRig.Tick(5);
  Assert.AreEqual<Integer>(7, FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].StepIndex);
  Assert.AreEqual<Integer>(WAR_ACTION_FINISHED, FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].Status);
end;

procedure TTestWarConstructionSupport.DovrebbeFermareUnAzioneCheIlTipoDiUnitaNonHa;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  // the footman has no build action: set by hand, the stepper stops it
  FRig.Entity(LFootman)^.UnitData.ActionType := WAR_ACTION_BUILD;
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_ACTION_NONE, FRig.Entity(LFootman)^.UnitData.ActionType);
  Assert.AreEqual<Integer>(WAR_ACTION_FINISHED, FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_BUILD].Status);
end;

procedure TTestWarConstructionSupport.DovrebbeAspettareLaFineDellAttesaPrimaDelPassoSuccessivo;
var
  LFootman: Integer;
  LStep: Integer;
  LCount: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Tick;
  LStep := FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].StepIndex;
  // the first wait of the idle action is 3 frames of a sixtieth of a second: the next tic does not end it
  FRig.Tick;
  Assert.AreEqual<Integer>(LStep, FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].StepIndex);
  // but in a few tics the step goes on
  for LCount := 1 to 10 do
  begin
    FRig.Tick;
    if FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].StepIndex <> LStep then
      Break;
  end;
  Assert.IsTrue(FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].StepIndex <> LStep);
end;

procedure TTestWarConstructionSupport.DovrebbeSegnareIlColpoDelMartelloDelContadino;
var
  LWorker: Integer;
  LHits: Integer;
  LIndex: Integer;
begin
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  TWarActionTable.SetAction(FRig.Entity(LWorker)^.UnitData, WAR_ACTION_REPAIR, True, 1.0);
  LHits := 0;
  for LIndex := 1 to 120 do
  begin
    FRig.Tick;
    if FRig.Entity(LWorker)^.UnitData.Actions[WAR_ACTION_REPAIR].LastActionStep = WAR_ACTION_STEP_ATTACK then
    begin
      Inc(LHits);
      FRig.Entity(LWorker)^.UnitData.Actions[WAR_ACTION_REPAIR].LastActionStep := WAR_ACTION_STEP_NONE;
    end;
  end;
  // the repair action lasts 32 frames and loops: in two seconds (120 tics) there are three or four blows
  Assert.IsTrue(LHits >= 3);
  Assert.IsTrue(LHits <= 4);
end;

procedure TTestWarConstructionSupport.DovrebbeSegnareIlSuonoDiUnPasso;
var
  LFootman: Integer;
  LSeen: Boolean;
  LIndex: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  TWarActionTable.SetAction(FRig.Entity(LFootman)^.UnitData, WAR_ACTION_ATTACK, True, 1.0);
  LSeen := False;
  for LIndex := 1 to 60 do
  begin
    FRig.Tick;
    if FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_ATTACK].LastSoundStep = WAR_ACTION_STEP_SOUND_SWORD then
      LSeen := True;
  end;
  Assert.IsTrue(LSeen);
end;

procedure TTestWarConstructionSupport.DovrebbeSpecchiareIFotogrammiDelleDirezioniAOvest;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Entity(LFootman)^.UnitData.Direction := WAR_DIRECTION_WEST;
  TWarActionTable.SetAction(FRig.Entity(LFootman)^.UnitData, WAR_ACTION_IDLE, True, 1.0);
  FRig.Tick;
  Assert.AreEqual(-1.0, Double(FRig.Entity(LFootman)^.ScaleX), 0.0);
  FRig.Entity(LFootman)^.UnitData.Direction := WAR_DIRECTION_EAST;
  TWarActionTable.SetAction(FRig.Entity(LFootman)^.UnitData, WAR_ACTION_IDLE, True, 1.0);
  FRig.Tick;
  Assert.AreEqual(1.0, Double(FRig.Entity(LFootman)^.ScaleX), 0.0);
end;

procedure TTestWarConstructionSupport.DovrebbeSommareAlFotogrammaLaDirezioneNellePose;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  // the first frame of the idle action is 0, plus 4 - |4 - direction|
  FRig.Entity(LFootman)^.UnitData.Direction := WAR_DIRECTION_SOUTH;
  TWarActionTable.SetAction(FRig.Entity(LFootman)^.UnitData, WAR_ACTION_IDLE, True, 1.0);
  FRig.Tick;
  Assert.AreEqual<Integer>(4, FRig.Entity(LFootman)^.SpriteFrame);
  FRig.Entity(LFootman)^.UnitData.Direction := WAR_DIRECTION_NORTH_WEST;
  TWarActionTable.SetAction(FRig.Entity(LFootman)^.UnitData, WAR_ACTION_IDLE, True, 1.0);
  FRig.Tick;
  Assert.AreEqual<Integer>(1, FRig.Entity(LFootman)^.SpriteFrame);
end;

procedure TTestWarConstructionSupport.DovrebbeRicominciareUnAzioneCheGira;
var
  LFootman: Integer;
  LRound: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  // the idle action of the footman loops: after a few seconds it is still running, never finished
  for LRound := 1 to 5 do
  begin
    FRig.Run(1);
    Assert.AreNotEqual<Integer>(WAR_ACTION_FINISHED, FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].Status);
  end;
end;

procedure TTestWarConstructionSupport.DovrebbeFinireUnAzioneCheNonGira;
var
  LFarm: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  // the construction action of a building does not loop: 150 frames
  TWarActionTable.SetAction(FRig.Entity(LFarm)^.UnitData, WAR_ACTION_BUILD, True, 1.0);
  FRig.Run(4);
  Assert.AreEqual<Integer>(WAR_ACTION_FINISHED, FRig.Entity(LFarm)^.UnitData.Actions[WAR_ACTION_BUILD].Status);
end;

procedure TTestWarConstructionSupport.DovrebbeRiavviareUnAzioneConIndiceNegativo;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].StepIndex := -1;
  FRig.Tick;
  Assert.IsTrue(FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].StepIndex >= 0);
  Assert.AreEqual<Integer>(WAR_ACTION_RUNNING, FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE].Status);
end;

procedure TTestWarConstructionSupport.DovrebbeIgnorareIlFotogrammaSeLEntitaNonHaLoSprite;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Entity(LFootman)^.HasSprite := False;
  FRig.Entity(LFootman)^.SpriteFrame := 99;
  FRig.Entity(LFootman)^.UnitData.Direction := WAR_DIRECTION_SOUTH;
  TWarActionTable.SetAction(FRig.Entity(LFootman)^.UnitData, WAR_ACTION_IDLE, True, 1.0);
  FRig.Tick;
  Assert.AreEqual<Integer>(99, FRig.Entity(LFootman)^.SpriteFrame);
end;

procedure TTestWarConstructionSupport.DovrebbeScalareLAttesaDelPassoConLaScalaDellAzione;
var
  LFootman: Integer;
  LAction: ^TWarUnitAction;
  LNormal: Double;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  TWarActionTable.SetAction(FRig.Entity(LFootman)^.UnitData, WAR_ACTION_IDLE, True, 1.0);
  FRig.Tick;
  LAction := @FRig.Entity(LFootman)^.UnitData.Actions[WAR_ACTION_IDLE];
  LNormal := LAction^.WaitEndGameTime - FRig.Context.Clock^.GameTime;
  TWarActionTable.SetAction(FRig.Entity(LFootman)^.UnitData, WAR_ACTION_IDLE, True, 0.5);
  FRig.Tick;
  Assert.IsTrue(LAction^.WaitEndGameTime - FRig.Context.Clock^.GameTime < LNormal);
end;

procedure TTestWarConstructionSupport.DovrebbeDareIlPuntoPiuVicinoDelRettangoloInOgniZona;
var
  LPoint: TWarVec2;
begin
  // the rectangle of 3 by 2 cells from (10, 20): the last column is 12 and the last row 21
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 20, 3, 2, TWarModelMath.Vec(5, 15));
  Assert.AreEqual(Double(10), Double(LPoint.X), 0);
  Assert.AreEqual(Double(20), Double(LPoint.Y), 0);
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 20, 3, 2, TWarModelMath.Vec(11, 15));
  Assert.AreEqual(Double(11), Double(LPoint.X), 0);
  Assert.AreEqual(Double(20), Double(LPoint.Y), 0);
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 20, 3, 2, TWarModelMath.Vec(30, 15));
  Assert.AreEqual(Double(12), Double(LPoint.X), 0);
  Assert.AreEqual(Double(20), Double(LPoint.Y), 0);
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 20, 3, 2, TWarModelMath.Vec(30, 20.5));
  Assert.AreEqual(Double(12), Double(LPoint.X), 0);
  Assert.AreEqual(Double(20.5), Double(LPoint.Y), 0);
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 20, 3, 2, TWarModelMath.Vec(30, 30));
  Assert.AreEqual(Double(12), Double(LPoint.X), 0);
  Assert.AreEqual(Double(21), Double(LPoint.Y), 0);
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 20, 3, 2, TWarModelMath.Vec(11, 30));
  Assert.AreEqual(Double(11), Double(LPoint.X), 0);
  Assert.AreEqual(Double(21), Double(LPoint.Y), 0);
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 20, 3, 2, TWarModelMath.Vec(1, 30));
  Assert.AreEqual(Double(10), Double(LPoint.X), 0);
  Assert.AreEqual(Double(21), Double(LPoint.Y), 0);
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 20, 3, 2, TWarModelMath.Vec(1, 20.5));
  Assert.AreEqual(Double(10), Double(LPoint.X), 0);
  Assert.AreEqual(Double(20.5), Double(LPoint.Y), 0);
  // inside
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 20, 3, 2, TWarModelMath.Vec(11, 20.5));
  Assert.AreEqual(Double(11), Double(LPoint.X), 0);
  Assert.AreEqual(Double(20.5), Double(LPoint.Y), 0);
  LPoint := TWarTargetGeometry.ClosestPointOnRect(10, 20, 3, 2, TWarModelMath.Vec(30, 15));
  Assert.AreEqual(Double(12), Double(LPoint.X), 0);
end;

procedure TTestWarConstructionSupport.DovrebbeDareLaCasellaDelBersaglioPiuVicinaAllUnita;
var
  LTownHall: Integer;
  LWorker: Integer;
  LTile: TWarVec2;
begin
  LTownHall := FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, 10, 10);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 20, 12);
  LTile := TWarTargetGeometry.TileOnTarget(FRig.Entity(LWorker), FRig.Entity(LTownHall));
  Assert.AreEqual(Double(12), Double(LTile.X), 0);
  Assert.AreEqual(Double(12), Double(LTile.Y), 0);
  Assert.AreEqual<Integer>(8, TWarTargetGeometry.DistanceInTiles(FRig.Entity(LWorker), FRig.Entity(LTownHall)));
end;

procedure TTestWarConstructionSupport.DovrebbeDireSeIlBersaglioEInPortata;
var
  LTownHall: Integer;
  LWorker: Integer;
begin
  LTownHall := FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, 10, 10);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 13, 11);
  Assert.IsTrue(TWarTargetGeometry.UnitInRange(FRig.Entity(LWorker), FRig.Entity(LTownHall), 1));
  Assert.IsTrue(TWarTargetGeometry.UnitInRange(FRig.Entity(LWorker), FRig.Entity(LTownHall), 3));
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 15, 11);
  Assert.IsFalse(TWarTargetGeometry.UnitInRange(FRig.Entity(LWorker), FRig.Entity(LTownHall), 1));
  Assert.IsTrue(TWarTargetGeometry.UnitInRange(FRig.Entity(LWorker), FRig.Entity(LTownHall), 3));
end;

procedure TTestWarConstructionSupport.DovrebbeDareIlPuntoInPixelPiuVicinoAlBersaglio;
var
  LTownHall: Integer;
  LWorker: Integer;
  LPoint: TWarVec2;
begin
  LTownHall := FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, 10, 10);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 20, 11);
  LPoint := TWarTargetGeometry.PointOnTarget(FRig.Entity(LWorker), FRig.Entity(LTownHall));
  // the town hall is 48 pixels wide from x = 160: its last pixel column is 207
  Assert.AreEqual(207.0, Double(LPoint.X), 0);
  Assert.AreEqual(Double(11 * WAR_MEGA_TILE_SIZE + 8), Double(LPoint.Y), 0);
end;

procedure TTestWarConstructionSupport.DovrebbeDareLaStessaCasellaSeEVuota;
var
  LX: Integer;
  LY: Integer;
begin
  LX := FRig.Grid.FindEmptyTile(5, 6).X;
  LY := FRig.Grid.FindEmptyTile(5, 6).Y;
  Assert.AreEqual<Integer>(5, LX);
  Assert.AreEqual<Integer>(6, LY);
end;

procedure TTestWarConstructionSupport.DovrebbeCercareLaCasellaVuotaNellOrdineDelleDirezioni;
var
  LX: Integer;
  LY: Integer;
begin
  FRig.Grid.SetStaticEntity(5, 6, 1, 1, 1);
  // the first neighbor that the original looks at is the one above
  LX := FRig.Grid.FindEmptyTile(5, 6).X;
  LY := FRig.Grid.FindEmptyTile(5, 6).Y;
  Assert.AreEqual<Integer>(5, LX);
  Assert.AreEqual<Integer>(5, LY);
  FRig.Grid.SetStaticEntity(5, 5, 1, 1, 1);
  LX := FRig.Grid.FindEmptyTile(5, 6).X;
  LY := FRig.Grid.FindEmptyTile(5, 6).Y;
  // up and up-left... the second is up and to the right
  Assert.AreEqual<Integer>(6, LX);
  Assert.AreEqual<Integer>(5, LY);
end;

procedure TTestWarConstructionSupport.DovrebbeCercareLontanoSeVicinoENonVuoto;
var
  LX: Integer;
  LY: Integer;
begin
  FRig.Grid.SetStaticEntity(4, 4, 5, 5, 1);
  LX := FRig.Grid.FindEmptyTile(6, 6).X;
  LY := FRig.Grid.FindEmptyTile(6, 6).Y;
  Assert.IsTrue(FRig.Grid.IsEmpty(LX, LY));
  Assert.IsTrue((LX = 3) or (LX = 9) or (LY = 3) or (LY = 9));
end;

procedure TTestWarConstructionSupport.DovrebbeDareLaCasellaDiPartenzaSeLaMappaEPiena;
var
  LX: Integer;
  LY: Integer;
begin
  FRig.Grid.SetStaticEntity(0, 0, WAR_MAP_TILES_WIDTH, WAR_MAP_TILES_HEIGHT, 1);
  LX := FRig.Grid.FindEmptyTile(30, 31).X;
  LY := FRig.Grid.FindEmptyTile(30, 31).Y;
  Assert.AreEqual<Integer>(30, LX);
  Assert.AreEqual<Integer>(31, LY);
end;

procedure TTestWarConstructionSupport.DovrebbeSollevareEccezioneSeLaPartenzaEFuoriDallaMappa;
begin
  Assert.WillRaise(
    procedure
    var
      LX: Integer;
      LY: Integer;
    begin
      LX := FRig.Grid.FindEmptyTile(-1, 5).X;
      LY := FRig.Grid.FindEmptyTile(-1, 5).Y;
    end, EWarException);
end;

procedure TTestWarConstructionSupport.DovrebbeRispondereAlleDomandeSulleCaselleDalGrigliaDiOccupazione;
var
  LProbe: IWarOccupancyProbe;
  LOccupancy: IWarOccupancy;
  LX: Integer;
  LY: Integer;
begin
  LOccupancy := TWarGridOccupancy.Create(FRig.Grid);
  Assert.IsTrue(Supports(LOccupancy, IWarOccupancyProbe, LProbe));
  Assert.IsTrue(LProbe.IsEmpty(3, 3));
  LOccupancy.SetStaticEntity(3, 3, 1, 1, 9);
  Assert.IsFalse(LProbe.IsEmpty(3, 3));
  LProbe.FindEmptyTile(3, 3, LX, LY);
  Assert.AreEqual<Integer>(3, LX);
  Assert.AreEqual<Integer>(2, LY);
end;

procedure TTestWarConstructionSupport.DovrebbeUsareLeRispostePredefiniteSenzaGrigliaNeOspite;
var
  LProbe: IWarOccupancyProbe;
  LHost: IWarConstructionHost;
  LX: Integer;
  LY: Integer;
begin
  LProbe := TWarNullOccupancyProbe.Create;
  Assert.IsTrue(LProbe.IsEmpty(1, 1));
  LProbe.FindEmptyTile(4, 5, LX, LY);
  Assert.AreEqual<Integer>(4, LX);
  Assert.AreEqual<Integer>(5, LY);
  LHost := TWarNullConstructionHost.Create;
  Assert.AreEqual<Integer>(0, LHost.UnitFrames(WAR_UNIT_FOOTMAN));
  Assert.AreEqual<Integer>(0, LHost.ConstructionFrames(WAR_UNIT_FARM_HUMANS));
  Assert.IsTrue(LHost.IsTileKnown(1, 1));
  LHost.PlaySound(1);
  LHost.PlayRandomSound(1, 2);
  LHost.Acknowledge(0);
end;

procedure TTestWarConstructionSupport.DovrebbeRipristinareLeRispostePredefiniteSeSiDaNil;
var
  LContext: TWarModelContext;
begin
  LContext := FRig.Context;
  LContext.Probe := nil;
  Assert.IsTrue(LContext.Probe.IsEmpty(1, 1));
  LContext.ConstructionHost := nil;
  Assert.AreEqual<Integer>(0, LContext.ConstructionHost.ConstructionFrames(WAR_UNIT_FARM_HUMANS));
end;

procedure TTestWarConstructionSupport.DovrebbeRegistrareGliStatiEPrendereLaGrigliaDallOccupazione;
const
  TYPES: array[0..5] of Integer = (WAR_STATE_COLLAPSE, WAR_STATE_TRAIN, WAR_STATE_UPGRADE, WAR_STATE_BUILD,
    WAR_STATE_REPAIR, WAR_STATE_REPAIRING);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(TYPES) do
    Assert.IsTrue(Assigned(FRig.Machine.Descriptors[TYPES[LIndex]].UpdateAll), Format('stato %d', [TYPES[LIndex]]));
  Assert.IsTrue(Assigned(FRig.Machine.Descriptors[WAR_STATE_BUILD].OnEnter));
  Assert.IsTrue(Assigned(FRig.Machine.Descriptors[WAR_STATE_BUILD].OnExit));
  Assert.IsFalse(Assigned(FRig.Machine.Descriptors[WAR_STATE_COLLAPSE].OnExit));
  Assert.IsFalse(Assigned(FRig.Machine.Descriptors[WAR_STATE_REPAIR].OnEnter));
  // the grid of the rig can answer, so the free tiles are the ones of the grid
  FRig.Grid.SetStaticEntity(2, 2, 1, 1, 5);
  Assert.IsFalse(FRig.Context.Probe.IsEmpty(2, 2));
end;

procedure TTestWarConstructionSupport.DovrebbeDireSeBastaIlDenaroDelPortafoglio;
var
  LPlayer: PWarPlayerInfo;
begin
  LPlayer := FRig.Context.Players[0];
  Assert.IsTrue(TWarPurse.Enough(LPlayer, 5000, 5000));
  Assert.IsFalse(TWarPurse.Enough(LPlayer, 5001, 0));
  Assert.IsFalse(TWarPurse.Enough(LPlayer, 0, 5001));
end;

procedure TTestWarConstructionSupport.DovrebbeSpendereTuttoONienteDalPortafoglio;
var
  LPlayer: PWarPlayerInfo;
begin
  LPlayer := FRig.Context.Players[0];
  Assert.IsTrue(TWarPurse.Decrease(FRig.Context, LPlayer, 100, 200));
  Assert.AreEqual<Integer>(4900, LPlayer^.Gold);
  Assert.AreEqual<Integer>(4800, LPlayer^.Wood);
  Assert.IsFalse(TWarPurse.Decrease(FRig.Context, LPlayer, 5000, 5000));
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughGold), Ord(FRig.Observer.LastMessage));
  Assert.IsFalse(TWarPurse.Decrease(FRig.Context, LPlayer, 100, 5000));
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughLumber), Ord(FRig.Observer.LastMessage));
  Assert.AreEqual<Integer>(4900, LPlayer^.Gold);
end;

procedure TTestWarConstructionSupport.DovrebbeRestituireIlDenaroAlPortafoglio;
var
  LPlayer: PWarPlayerInfo;
begin
  LPlayer := FRig.Context.Players[0];
  TWarPurse.Increase(LPlayer, 10, 20);
  Assert.AreEqual<Integer>(5010, LPlayer^.Gold);
  Assert.AreEqual<Integer>(5020, LPlayer^.Wood);
end;

procedure TTestWarConstructionSupport.DovrebbeCostruireUnPezzoDiMuroPagandoEDeterminandoNeIlTipo;
begin
  Assert.IsTrue(FRig.Commands.PlaceWall(0, 20, 20));
  Assert.AreEqual<Integer>(5000 - WAR_WALL_GOLD_COST, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(1, FRig.Context.Walls.Count);
  Assert.AreEqual<Integer>(WAR_WALL_MAX_HP, FRig.Context.Walls[0]^.Hp);
  Assert.AreEqual<Integer>(WAR_WALL_MAX_HP, FRig.Context.Walls[0]^.MaxHp);
  Assert.AreEqual<Integer>(0, FRig.Context.Walls[0]^.Player);
  Assert.AreEqual<Integer>(WAR_SOUND_BUILD_ROAD, FRig.Observer.LastSound);
end;

procedure TTestWarConstructionSupport.DovrebbeRifiutareUnMuroSuUnaCasellaOccupata;
begin
  FRig.AddDude(WAR_UNIT_FOOTMAN, 20, 20);
  Assert.IsFalse(FRig.Commands.PlaceWall(0, 20, 20));
  Assert.AreEqual<Integer>(0, FRig.Context.Walls.Count);
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(Ord(wsmCantBuildThere), Ord(FRig.Observer.LastMessage));
  Assert.AreEqual<Integer>(WAR_SOUND_UI_CANCEL, FRig.Observer.LastSound);
end;

procedure TTestWarConstructionSupport.DovrebbeRifiutareUnMuroSenzaOro;
begin
  FRig.Context.Players[0]^.Gold := 99;
  Assert.IsFalse(FRig.Commands.PlaceWall(0, 20, 20));
  Assert.AreEqual<Integer>(0, FRig.Context.Walls.Count);
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughGold), Ord(FRig.Observer.LastMessage));
end;

procedure TTestWarConstructionSupport.DovrebbeCambiareIlTipoDeiPezziVicini;
begin
  FRig.Commands.PlaceWall(0, 20, 20);
  // a piece with no neighbor is the first of the table
  Assert.AreEqual<Integer>(WAR_WALL_TILE_TYPE_MAP[0], FRig.Context.Walls[0]^.PieceType);
  FRig.Commands.PlaceWall(0, 21, 20);
  Assert.AreEqual<Integer>(2, FRig.Context.Walls.Count);
  // the neighbors are up, right, down and left: bit 0, 1, 2, 3
  Assert.AreEqual<Integer>(WAR_WALL_TILE_TYPE_MAP[1 shl 1], FRig.Context.Walls[0]^.PieceType);
  Assert.AreEqual<Integer>(WAR_WALL_TILE_TYPE_MAP[1 shl 3], FRig.Context.Walls[1]^.PieceType);
  FRig.Commands.PlaceWall(0, 22, 20);
  Assert.AreEqual<Integer>(WAR_WALL_TILE_TYPE_MAP[(1 shl 1) or (1 shl 3)], FRig.Context.Walls[1]^.PieceType);
end;

procedure TTestWarConstructionSupport.DovrebbeToglierePuntiFeritaAiPezziDiMuro;
begin
  FRig.Commands.PlaceWall(0, 20, 20);
  FRig.Context.Walls.TakeDamage(0, 10, 15);
  Assert.AreEqual<Integer>(WAR_WALL_MAX_HP - 25, FRig.Context.Walls[0]^.Hp);
  // the armor of a wall is nothing and a negative random part counts as nothing
  FRig.Context.Walls.TakeDamage(0, 5, -4);
  Assert.AreEqual<Integer>(WAR_WALL_MAX_HP - 30, FRig.Context.Walls[0]^.Hp);
  FRig.Context.Walls.TakeDamage(0, 500, 0);
  Assert.AreEqual<Integer>(0, FRig.Context.Walls[0]^.Hp);
end;

procedure TTestWarConstructionSupport.DovrebbeLiberareLaCasellaDiUnPezzoSenzaPuntiFerita;
var
  LWall: Integer;
begin
  LWall := TWarTerrainEntities.CreateWall(FRig.Context, FRig.Machine);
  FRig.Commands.PlaceWall(0, 20, 20);
  FRig.Tick;
  Assert.IsFalse(FRig.Grid.IsEmpty(20, 20));
  Assert.AreEqual<Integer>(FRig.Entity(LWall)^.Id, FRig.Grid.GetTileEntityId(20, 20));
  FRig.Context.Walls.TakeDamage(0, 500, 0);
  FRig.Tick;
  Assert.IsTrue(FRig.Grid.IsEmpty(20, 20));
end;

procedure TTestWarConstructionSupport.DovrebbeOccuparePerIdLeCaselleDelMuroAdOgniTic;
var
  LWall: Integer;
begin
  LWall := TWarTerrainEntities.CreateWall(FRig.Context, FRig.Machine);
  FRig.Commands.PlaceWall(0, 20, 20);
  FRig.Commands.PlaceWall(0, 21, 20);
  // the wall idle state has no delay: the first tic fills both tiles
  FRig.Tick;
  Assert.IsFalse(FRig.Grid.IsEmpty(21, 20));
  FRig.Grid.SetFreeTiles(21, 20, 1, 1);
  FRig.Tick;
  Assert.IsFalse(FRig.Grid.IsEmpty(21, 20));
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWall));
end;

procedure TTestWarConstructionSupport.DovrebbeSollevareEccezioneSeIlPezzoDiMuroNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Context.Walls.TakeDamage(0, 1, 1);
    end, EWarException);
  Assert.WillRaise(
    procedure
    var
      LPiece: PWarWallPiece;
    begin
      LPiece := FRig.Context.Walls[-1];
      Assert.IsNull(LPiece);
    end, EWarException);
end;

procedure TTestWarConstructionSupport.DovrebbeAggiungerePezziDaUnaCostruzioneDelLivelloConPuntiFeritaPieni;
var
  LConstruct: TWarLevelConstruct;
begin
  LConstruct := Default(TWarLevelConstruct);
  LConstruct.X1 := 10;
  LConstruct.Y1 := 10;
  LConstruct.X2 := 12;
  LConstruct.Y2 := 11;
  LConstruct.Player := 2;
  FRig.Context.Walls.AddFromConstruct(LConstruct);
  // three cells along X then the corner and the last one again (the original adds them twice)
  Assert.IsTrue(FRig.Context.Walls.Count >= 5);
  Assert.AreEqual<Integer>(WAR_WALL_MAX_HP, FRig.Context.Walls[0]^.Hp);
  Assert.AreEqual<Integer>(WAR_WALL_MAX_HP, FRig.Context.Walls[FRig.Context.Walls.Count - 1]^.MaxHp);
  Assert.AreEqual<Integer>(2, FRig.Context.Walls[0]^.Player);
  FRig.Context.Walls.DetermineTypes;
  Assert.AreEqual<Integer>(WAR_WALL_TILE_TYPE_MAP[1 shl 1], FRig.Context.Walls[0]^.PieceType);
  // pieces already there are kept
  FRig.Context.Walls.AddFromConstruct(LConstruct);
  Assert.IsTrue(FRig.Context.Walls.Count >= 10);
end;

procedure TTestWarConstructionSupport.DovrebbeCercareUnPezzoDiMuroPerCasella;
begin
  FRig.Commands.PlaceWall(0, 20, 20);
  FRig.Commands.PlaceWall(0, 25, 20);
  Assert.AreEqual<Integer>(0, FRig.Context.Walls.IndexAt(20, 20));
  Assert.AreEqual<Integer>(1, FRig.Context.Walls.IndexAt(25, 20));
  Assert.AreEqual<Integer>(-1, FRig.Context.Walls.IndexAt(22, 20));
  Assert.IsTrue(FRig.Context.Walls.HasPieceAt(25, 20));
  Assert.IsFalse(FRig.Context.Walls.HasPieceAt(26, 20));
end;

procedure TTestWarConstructionSupport.DovrebbeTrattareUnPezzoSenzaMassimoComeSenzaPuntiFerita;
var
  LWall: Integer;
  LIndex: Integer;
begin
  LWall := TWarTerrainEntities.CreateWall(FRig.Context, FRig.Machine);
  LIndex := FRig.Context.Walls.Add(30, 30, 0);
  Assert.AreEqual<Integer>(0, LIndex);
  FRig.Grid.SetStaticEntity(30, 30, 1, 1, 7);
  FRig.Tick;
  // no hit points and no maximum: the original divides by zero, here the tile is free
  Assert.IsTrue(FRig.Grid.IsEmpty(30, 30));
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWall));
end;

procedure TTestWarConstructionSupport.DovrebbeCrearePerPrimeLeEntitaDelMuroEDelleRovine;
var
  LWall: Integer;
  LRuins: Integer;
begin
  LWall := TWarTerrainEntities.CreateWall(FRig.Context, FRig.Machine);
  LRuins := TWarTerrainEntities.CreateRuins(FRig.Context);
  Assert.AreEqual<Integer>(WAR_ENTITY_WALL, FRig.Entity(LWall)^.EntityType);
  Assert.AreEqual<Integer>(WAR_ENTITY_RUIN, FRig.Entity(LRuins)^.EntityType);
  Assert.IsTrue(FRig.Entity(LWall)^.HasStateMachine);
  Assert.IsFalse(FRig.Entity(LRuins)^.HasStateMachine);
  Assert.IsTrue(FRig.Entity(LWall)^.Id < FRig.Entity(LRuins)^.Id);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWall));
end;

procedure TTestWarConstructionSupport.DovrebbeNonCrearePiuEntitaDiquantePuoLaPiscina;
var
  LCount: Integer;
begin
  for LCount := 1 to WAR_MODEL_MAX_ENTITIES do
    if FRig.World.Entities.CreateDude(WAR_UNIT_FOOTMAN, 30, 30, 1, False) = 0 then
      Break;
  Assert.AreEqual<Integer>(0, TWarTerrainEntities.CreateWall(FRig.Context, FRig.Machine));
  Assert.AreEqual<Integer>(0, TWarTerrainEntities.CreateRuins(FRig.Context));
end;

procedure TTestWarConstructionSupport.DovrebbeDareRisposteNulleDalOspitePredefinito;
var
  LWorld: TWarModelWorld;
  LRandom: IWarRandom;
begin
  LRandom := TModelObserver.Create(1);
  LWorld := TWarModelFactory.CreateWorld(LRandom);
  try
    Assert.AreEqual<Integer>(0, LWorld.Context.ConstructionHost.ConstructionFrames(WAR_UNIT_FARM_HUMANS));
    Assert.IsTrue(LWorld.Context.ConstructionHost.IsTileKnown(0, 0));
    // the null occupancy cannot answer: the probe is the default one, where every tile is empty
    Assert.IsTrue(LWorld.Context.Probe.IsEmpty(0, 0));
  finally
    LWorld.Free;
  end;
end;

procedure TTestWarConstructionSupport.DovrebbeTornareAlOspitePredefinitoSeSiDaNil;
begin
  FRig.Context.ConstructionHost := nil;
  Assert.IsTrue(FRig.Context.ConstructionHost.IsTileKnown(5, 5));
  Assert.AreEqual<Integer>(0, FRig.Context.ConstructionHost.UnitFrames(WAR_UNIT_FOOTMAN));
end;

procedure TTestWarConstructionSupport.DovrebbeDareUnImmagineDelleCostruzioniDelLaTabellaDelC;
begin
  // 331 + 1 mod 4 ... the tests give 1 + resource mod 4 frames to the 16 buildings
  Assert.AreEqual<Integer>(1 + 331 mod 4, FRig.Observer.ConstructionFrames(WAR_UNIT_FARM_HUMANS));
  Assert.AreEqual<Integer>(1 + 346 mod 4, FRig.Observer.ConstructionFrames(WAR_UNIT_BLACKSMITH_ORCS));
  Assert.AreEqual<Integer>(0, FRig.Observer.ConstructionFrames(WAR_UNIT_FOOTMAN));
  Assert.AreEqual<Integer>(0, FRig.Observer.ConstructionFrames(WAR_UNIT_COUNT));
end;

end.
