{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the states of the gatherers          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.GatherStates;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.GatherRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarGatherStates = class(TObject)
  private
    FRig: TGatherRig;
    function ActiveType(ASlot: Integer): Integer;
    procedure Order(ASlot: Integer; AState: Pointer);
    procedure OrderGold(ASlot: Integer; AMineId: Word);
    procedure OrderWood(ASlot: Integer; AForestId: Word; ATileX, ATileY: Integer);
    procedure OrderDeliver(ASlot: Integer; ATownHallId: Word);
    function IdOf(ASlot: Integer): Word;
    procedure Near(AExpected, AActual, ATolerance: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAndareInattivoSeLaMinieraNonEsiste;
    [Test]
    procedure DovrebbeAndareInattivoSeLaMinieraStaCrollando;
    [Test]
    procedure DovrebbeSeguireLaMinieraSeELontana;
    [Test]
    procedure DovrebbeRaggiungereLaMinieraConIlSeguimentoVero;
    [Test]
    procedure DovrebbeEntrareNellaMinieraSeELaVicina;
    [Test]
    procedure DovrebbeNascondereIlLavoratoreNellaMiniera;
    [Test]
    procedure DovrebbePortareCentoOroAlMunicipioDopoDueSecondi;
    [Test]
    procedure DovrebbeFarCrollareLaMinieraEsauritaEDareSoloQuelloCheResta;
    [Test]
    procedure DovrebbeFarUscireSenzaOroChiEntraInUnaMinieraCheNonEsistePiu;
    [Test]
    procedure DovrebbeRendereVisibileChiEscePerLaMinieraCheCrolla;
    [Test]
    procedure DovrebbeAndareInattivoSeNonCeUnMunicipioDopoLaMiniera;
    [Test]
    procedure DovrebbeAndareInattivoSeLaForestaNonEsiste;
    [Test]
    procedure DovrebbeAndareInattivoSeNonRestanoAlberiRaggiungibili;
    [Test]
    procedure DovrebbeCamminareFinoAlAlberoSeELontano;
    [Test]
    procedure DovrebbeSceglierePiuVicinoUnAlberoRaggiungibileSeQuelloEFinito;
    [Test]
    procedure DovrebbeTagliareUnAlberoEFarloCadere;
    [Test]
    procedure DovrebbeGuardareVersoLAlberoEOccupareLaSuaCasella;
    [Test]
    procedure DovrebbePortareLaLegnaAlMunicipioQuandoNeHaCento;
    [Test]
    procedure DovrebbeAndareInattivoSeNonCeUnMunicipioDopoLaLegna;
    [Test]
    procedure DovrebbeAndareInattivoSeLaForestaScompareMentreTaglia;
    [Test]
    procedure DovrebbeConsegnareOroELegnaAlGiocatore;
    [Test]
    procedure DovrebbeUscireDalMunicipioEAndareInattivoDopoUnSecondo;
    [Test]
    procedure DovrebbeTornareAlloStatoSottostanteDopoLaConsegna;
    [Test]
    procedure DovrebbeRicominciareDallaMinieraSeLaConsegnaECiclica;
    [Test]
    procedure DovrebbeRicominciareDallAlberoSeLaConsegnaECiclica;
    [Test]
    procedure DovrebbeAndareInattivoSeIlMunicipioNonEsiste;
    [Test]
    procedure DovrebbeSeguireIlMunicipioSeELontano;
    [Test]
    procedure DovrebbeConsegnareIlCaricoUnaVoltaSola;
    // the defects of the C that are kept
    [Test]
    procedure DovrebbeConservareIlDifettoDellaLegnaDispariCheNonArrivaMaACento;
    [Test]
    procedure DovrebbeConservareIlDifettoDelLavoratoreNascostoSeRiceveUnOrdine;
    [Test]
    procedure DovrebbeConservareIlDifettoDellOroSommatoAllaLegnaTrasportata;
    // the difference that is wanted
    [Test]
    procedure DovrebbeSostituireLoSpriteSeNeAggiungiUnAltro;
    [Test]
    procedure DovrebbeDareEccezioneSeMancaLaMappaDeiRaccoglitori;
    [Test]
    procedure DovrebbeDareEccezioneSeIlTipoNonEUnLavoratore;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Forest, DelphiDoom.War.Autotile.Types,
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.State.GatherFactory, DelphiDoom.War.Model.UnitSprites,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.World,
  DelphiDoom.War.Model.GatherWorld;

const
  PEASANT_SPRITE = 281;
  PEASANT_CARRYING_GOLD = 329;
  PEASANT_CARRYING_WOOD = 327;

{ TTestWarGatherStates }

procedure TTestWarGatherStates.Setup;
begin
  FRig := TGatherRig.Create(7);
end;

procedure TTestWarGatherStates.TearDown;
begin
  FRig.Free;
end;

function TTestWarGatherStates.ActiveType(ASlot: Integer): Integer;
begin
  Result := FRig.Rig.ActiveType(ASlot);
end;

procedure TTestWarGatherStates.Near(AExpected, AActual, ATolerance: Single);
begin
  Assert.IsTrue(Abs(AExpected - AActual) <= ATolerance, Format('atteso %f, trovato %f', [AExpected, AActual]));
end;

function TTestWarGatherStates.IdOf(ASlot: Integer): Word;
begin
  Result := FRig.Rig.Entity(ASlot)^.Id;
end;

procedure TTestWarGatherStates.Order(ASlot: Integer; AState: Pointer);
begin
  FRig.Rig.World.Machine.ResetState(ASlot, PWarStateBase(AState), WAR_CAUSE_PLAYER_ORDER);
end;

procedure TTestWarGatherStates.OrderGold(ASlot: Integer; AMineId: Word);
begin
  Order(ASlot, TWarGatherStateFactory.NewGold(FRig.Rig.World.Machine, ASlot, AMineId));
end;

procedure TTestWarGatherStates.OrderWood(ASlot: Integer; AForestId: Word; ATileX, ATileY: Integer);
begin
  Order(ASlot, TWarGatherStateFactory.NewWood(FRig.Rig.World.Machine, ASlot, AForestId, FRig.TileCenter(ATileX, ATileY)));
end;

procedure TTestWarGatherStates.OrderDeliver(ASlot: Integer; ATownHallId: Word);
begin
  Order(ASlot, TWarGatherStateFactory.NewDeliver(FRig.Rig.World.Machine, ASlot, ATownHallId));
end;

procedure TTestWarGatherStates.DovrebbeAndareInattivoSeLaMinieraNonEsiste;
var
  LWorker: Integer;
begin
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderGold(LWorker, 999);
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
end;

procedure TTestWarGatherStates.DovrebbeAndareInattivoSeLaMinieraStaCrollando;
var
  LWorker: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(11, 10, 500);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  FRig.Rig.World.Machine.ResetState(LMine, PWarStateBase(FRig.Rig.World.Machine.CreateCollapse(LMine)), WAR_CAUSE_LIFECYCLE);
  OrderGold(LWorker, IdOf(LMine));
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
end;

procedure TTestWarGatherStates.DovrebbeSeguireLaMinieraSeELontana;
var
  LWorker: Integer;
  LMine: Integer;
  LFollow: PWarStateFollow;
begin
  LMine := FRig.AddMine(30, 30, 500);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderGold(LWorker, IdOf(LMine));
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_FOLLOW, ActiveType(LWorker));
  LFollow := PWarStateFollow(FRig.Rig.World.Machine.ActiveState(LWorker));
  Assert.AreEqual<Integer>(IdOf(LMine), LFollow^.TargetEntityId);
  // the range of a peasant is one tile, 16 pixels
  Assert.AreEqual<Integer>(16, LFollow^.TargetDistance);
  Assert.AreEqual<Integer>(2, Ord(FRig.Rig.Entity(LWorker)^.StateMachine.Depth));
end;

procedure TTestWarGatherStates.DovrebbeRaggiungereLaMinieraConIlSeguimentoVero;
var
  LMine: Integer;
  LWorker: Integer;
  LIndex: Integer;
  LInside: Boolean;
begin
  // the follow of the attack slice is the one that the gatherers push: the worker walks to the mine, then mines
  FRig.Free;
  FRig := TGatherRig.Create(7, True);
  LMine := FRig.AddMine(14, 10, 500);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 8, 10);
  OrderGold(LWorker, IdOf(LMine));
  LInside := False;
  for LIndex := 1 to 1800 do
  begin
    FRig.Rig.TickAll;
    if ActiveType(LWorker) = WAR_STATE_MINING then
    begin
      LInside := True;
      Break;
    end;
  end;
  Assert.IsTrue(LInside, 'the worker reaches the mine by walking');
  Assert.IsFalse(FRig.Rig.Entity(LWorker)^.SpriteEnabled);
end;

procedure TTestWarGatherStates.DovrebbeEntrareNellaMinieraSeELaVicina;
var
  LWorker: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(11, 10, 500);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderGold(LWorker, IdOf(LMine));
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_MINING, ActiveType(LWorker));
  Near(2.0, PWarStateMining(FRig.Rig.World.Machine.ActiveState(LWorker))^.MiningTime, 0.1);
end;

procedure TTestWarGatherStates.DovrebbeNascondereIlLavoratoreNellaMiniera;
var
  LWorker: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(11, 10, 500);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  Assert.AreEqual(PEASANT_SPRITE, FRig.Rig.Entity(LWorker)^.SpriteResource);
  OrderGold(LWorker, IdOf(LMine));
  FRig.Rig.TickAll(4);
  Assert.AreEqual(0, FRig.Rig.Entity(LWorker)^.SpriteResource);
  Assert.IsFalse(FRig.Rig.Entity(LWorker)^.SpriteEnabled);
  Assert.IsTrue(FRig.Rig.Observer.LeftSelection > 0);
end;

procedure TTestWarGatherStates.DovrebbePortareCentoOroAlMunicipioDopoDueSecondi;
var
  LWorker: Integer;
  LMine: Integer;
  LTownHall: Integer;
  LDeliver: PWarStateDeliver;
begin
  LMine := FRig.AddMine(11, 10, 500);
  LTownHall := FRig.AddTownHall(4, 10);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderGold(LWorker, IdOf(LMine));
  FRig.Rig.RunAll(2.2);
  // the town hall is far: the delivery is under the walk to it
  Assert.AreEqual(WAR_STATE_FOLLOW, ActiveType(LWorker));
  Assert.AreEqual(100, FRig.Rig.Entity(LWorker)^.UnitData.Amount);
  Assert.AreEqual(Ord(wrkGold), Ord(FRig.Rig.Entity(LWorker)^.UnitData.ResourceKind));
  Assert.AreEqual(400, FRig.Rig.Entity(LMine)^.UnitData.Amount);
  Assert.AreEqual(PEASANT_CARRYING_GOLD, FRig.Rig.Entity(LWorker)^.SpriteResource);
  LDeliver := PWarStateDeliver(FRig.Rig.World.Machine.FindState(LWorker, WAR_STATE_DELIVER));
  Assert.IsNotNull(LDeliver);
  Assert.AreEqual<Integer>(IdOf(LTownHall), LDeliver^.TownHallId);
  Assert.IsTrue(LDeliver^.Cycle);
  Assert.AreEqual(Ord(wrkGold), Ord(LDeliver^.SourceKind));
  Assert.AreEqual<Integer>(IdOf(LMine), LDeliver^.SourceId);
  // the worker came out of the mine on an empty tile
  Assert.IsTrue(FRig.Rig.Grid.IsEmpty(Trunc(TWarUnitGeometry.CenterTile(FRig.Rig.Entity(LWorker)).X),
    Trunc(TWarUnitGeometry.CenterTile(FRig.Rig.Entity(LWorker)).Y)));
end;

procedure TTestWarGatherStates.DovrebbeFarCrollareLaMinieraEsauritaEDareSoloQuelloCheResta;
var
  LWorker: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(11, 10, 60);
  FRig.AddTownHall(4, 10);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderGold(LWorker, IdOf(LMine));
  FRig.Rig.RunAll(2.2);
  Assert.AreEqual(60, FRig.Rig.Entity(LWorker)^.UnitData.Amount);
  Assert.AreEqual(0, FRig.Rig.Entity(LMine)^.UnitData.Amount);
  Assert.IsTrue(FRig.Rig.World.Machine.IsCollapsing(LMine) or FRig.Rig.World.Machine.IsGoingToCollapse(LMine));
  // the collapse is asked for once, with its sound
  Assert.AreEqual(1, FRig.Rig.Observer.Collapsing);
  FRig.Rig.RunAll(0.5);
  Assert.AreEqual(1, FRig.Rig.Observer.Collapsing);
end;

procedure TTestWarGatherStates.DovrebbeFarUscireSenzaOroChiEntraInUnaMinieraCheNonEsistePiu;
var
  LWorker: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(11, 10, 500);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderGold(LWorker, IdOf(LMine));
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_MINING, ActiveType(LWorker));
  FRig.Rig.World.Entities.RemoveEntityById(IdOf(LMine));
  FRig.Rig.TickAll(3);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
  Assert.AreEqual(0, FRig.Rig.Entity(LWorker)^.UnitData.Amount);
  Assert.AreEqual(PEASANT_SPRITE, FRig.Rig.Entity(LWorker)^.SpriteResource);
  Assert.IsTrue(FRig.Rig.Entity(LWorker)^.SpriteEnabled);
end;

procedure TTestWarGatherStates.DovrebbeRendereVisibileChiEscePerLaMinieraCheCrolla;
var
  LWorker: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(11, 10, 500);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderGold(LWorker, IdOf(LMine));
  FRig.Rig.TickAll(4);
  FRig.Rig.World.Machine.ResetState(LMine, PWarStateBase(FRig.Rig.World.Machine.CreateCollapse(LMine)), WAR_CAUSE_LIFECYCLE);
  FRig.Rig.TickAll(3);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
  Assert.AreEqual(PEASANT_SPRITE, FRig.Rig.Entity(LWorker)^.SpriteResource);
  Assert.IsTrue(FRig.Rig.Entity(LWorker)^.SpriteEnabled);
  Assert.AreEqual(0, FRig.Rig.Entity(LWorker)^.UnitData.Amount);
end;

procedure TTestWarGatherStates.DovrebbeAndareInattivoSeNonCeUnMunicipioDopoLaMiniera;
var
  LWorker: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(11, 10, 500);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderGold(LWorker, IdOf(LMine));
  FRig.Rig.RunAll(2.2);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
  // it carries the gold anyway
  Assert.AreEqual(100, FRig.Rig.Entity(LWorker)^.UnitData.Amount);
end;

procedure TTestWarGatherStates.DovrebbeAndareInattivoSeLaForestaNonEsiste;
var
  LWorker: Integer;
begin
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderWood(LWorker, 999, 12, 10);
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
end;

procedure TTestWarGatherStates.DovrebbeAndareInattivoSeNonRestanoAlberiRaggiungibili;
var
  LWorker: Integer;
  LForest: Word;
begin
  LForest := FRig.AddForestBlock(12, 10, 4, 3, 0);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderWood(LWorker, LForest, 12, 10);
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
end;

procedure TTestWarGatherStates.DovrebbeCamminareFinoAlAlberoSeELontano;
var
  LWorker: Integer;
  LForest: Word;
begin
  LForest := FRig.AddForestBlock(30, 10, 4, 3, 50);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  OrderWood(LWorker, LForest, 30, 10);
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_MOVE, ActiveType(LWorker));
  Assert.AreEqual<Integer>(2, PWarStateMove(FRig.Rig.World.Machine.ActiveState(LWorker))^.WaypointsCount);
  // it walks 19 tiles at 1.2 tiles a second and then chops
  FRig.Rig.RunAll(20);
  Assert.AreEqual(WAR_STATE_CHOPPING, ActiveType(LWorker));
end;

procedure TTestWarGatherStates.DovrebbeSceglierePiuVicinoUnAlberoRaggiungibileSeQuelloEFinito;
var
  LWorker: Integer;
  LForest: Word;
  LState: PWarStateWood;
begin
  // the first tree has no wood: the worker takes the one next to it and remembers it
  LForest := FRig.AddForestBlock(12, 10, 4, 3, 50);
  FRig.SetWood(LForest, 12, 10, 0);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 11, 10);
  OrderWood(LWorker, LForest, 12, 10);
  FRig.Rig.TickAll(2);
  LState := PWarStateWood(FRig.Rig.World.Machine.FindState(LWorker, WAR_STATE_WOOD));
  Assert.IsNotNull(LState);
  Near(FRig.TileCenter(13, 10).X, LState^.Position.X, 0.001);
  Near(FRig.TileCenter(13, 10).Y, LState^.Position.Y, 0.001);
end;

procedure TTestWarGatherStates.DovrebbeTagliareUnAlberoEFarloCadere;
var
  LWorker: Integer;
  LForest: Word;
begin
  LForest := FRig.AddForestBlock(12, 10, 4, 3, 100);
  FRig.SetWood(LForest, 12, 10, 6);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 11, 10);
  OrderWood(LWorker, LForest, 12, 10);
  FRig.Rig.RunAll(8);
  // 3 blows of 2 wood: the tree is gone, its tile is free and the map shows the felled tile
  Assert.IsTrue(FRig.Rig.Entity(LWorker)^.UnitData.Amount >= 6);
  Assert.AreEqual(Ord(wrkWood), Ord(FRig.Rig.Entity(LWorker)^.UnitData.ResourceKind));
  Assert.AreEqual<Integer>(11, FRig.Forests.FindForest(LForest).Trees.Count);
  Assert.IsTrue(FRig.Rig.Grid.IsEmpty(12, 10));
  Assert.AreEqual<Cardinal>(1, FRig.Painter.Writes);
  Assert.IsTrue(FRig.Rig.Observer.Chops >= 3);
  // the worker goes on with another tree
  Assert.IsTrue(ActiveType(LWorker) in [WAR_STATE_WOOD, WAR_STATE_MOVE, WAR_STATE_CHOPPING]);
end;

procedure TTestWarGatherStates.DovrebbeGuardareVersoLAlberoEOccupareLaSuaCasella;
var
  LWorker: Integer;
  LForest: Word;
begin
  LForest := FRig.AddForestBlock(12, 10, 4, 3, 50);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 11, 10);
  OrderWood(LWorker, LForest, 12, 10);
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_CHOPPING, ActiveType(LWorker));
  Assert.AreEqual(WAR_DIRECTION_EAST, FRig.Rig.Entity(LWorker)^.UnitData.Direction);
  Assert.AreEqual(WAR_ACTION_HARVEST, FRig.Rig.Entity(LWorker)^.UnitData.ActionType);
  Assert.IsFalse(FRig.Rig.Grid.IsEmpty(11, 10));
end;

procedure TTestWarGatherStates.DovrebbePortareLaLegnaAlMunicipioQuandoNeHaCento;
var
  LWorker: Integer;
  LForest: Word;
  LTownHall: Integer;
  LDeliver: PWarStateDeliver;
begin
  LTownHall := FRig.AddTownHall(4, 10);
  LForest := FRig.AddForestBlock(12, 10, 4, 3, 100);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 11, 10);
  FRig.Rig.Entity(LWorker)^.UnitData.Amount := 98;
  OrderWood(LWorker, LForest, 12, 10);
  FRig.Rig.RunAll(3);
  // the town hall is far: the delivery is under the walk to it
  Assert.AreEqual(WAR_STATE_FOLLOW, ActiveType(LWorker));
  Assert.AreEqual(100, FRig.Rig.Entity(LWorker)^.UnitData.Amount);
  Assert.AreEqual(PEASANT_CARRYING_WOOD, FRig.Rig.Entity(LWorker)^.SpriteResource);
  LDeliver := PWarStateDeliver(FRig.Rig.World.Machine.FindState(LWorker, WAR_STATE_DELIVER));
  Assert.IsNotNull(LDeliver);
  Assert.AreEqual<Integer>(IdOf(LTownHall), LDeliver^.TownHallId);
  Assert.AreEqual(Ord(wrkWood), Ord(LDeliver^.SourceKind));
  Assert.AreEqual<Integer>(LForest, LDeliver^.SourceId);
  Near(FRig.TileCenter(12, 10).X, LDeliver^.SourcePosition.X, 0.001);
end;

procedure TTestWarGatherStates.DovrebbeAndareInattivoSeNonCeUnMunicipioDopoLaLegna;
var
  LWorker: Integer;
  LForest: Word;
begin
  LForest := FRig.AddForestBlock(12, 10, 4, 3, 100);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 11, 10);
  FRig.Rig.Entity(LWorker)^.UnitData.Amount := 98;
  OrderWood(LWorker, LForest, 12, 10);
  FRig.Rig.RunAll(3);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
  Assert.AreEqual(100, FRig.Rig.Entity(LWorker)^.UnitData.Amount);
end;

procedure TTestWarGatherStates.DovrebbeAndareInattivoSeLaForestaScompareMentreTaglia;
var
  LWorker: Integer;
  LForest: Word;
begin
  LForest := FRig.AddForestBlock(12, 10, 4, 3, 100);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 11, 10);
  OrderWood(LWorker, LForest, 12, 10);
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_CHOPPING, ActiveType(LWorker));
  FRig.Rig.World.Entities.RemoveEntityById(LForest);
  FRig.Rig.TickAll(3);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
end;

procedure TTestWarGatherStates.DovrebbeConsegnareOroELegnaAlGiocatore;
var
  LWorker: Integer;
  LOther: Integer;
  LTownHall: Integer;
  LGold: Integer;
  LWood: Integer;
begin
  LTownHall := FRig.AddTownHall(10, 10);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  LOther := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 9, 11);
  LGold := FRig.Rig.World.Context.Players[0]^.Gold;
  LWood := FRig.Rig.World.Context.Players[0]^.Wood;
  FRig.Rig.Entity(LWorker)^.UnitData.ResourceKind := wrkGold;
  FRig.Rig.Entity(LWorker)^.UnitData.Amount := 70;
  FRig.Rig.Entity(LOther)^.UnitData.ResourceKind := wrkWood;
  FRig.Rig.Entity(LOther)^.UnitData.Amount := 30;
  OrderDeliver(LWorker, IdOf(LTownHall));
  OrderDeliver(LOther, IdOf(LTownHall));
  FRig.Rig.TickAll(3);
  Assert.AreEqual(LGold + 70, FRig.Rig.World.Context.Players[0]^.Gold);
  Assert.AreEqual(LWood + 30, FRig.Rig.World.Context.Players[0]^.Wood);
  Assert.AreEqual(0, FRig.Rig.Entity(LWorker)^.UnitData.Amount);
  Assert.AreEqual(Ord(wrkNone), Ord(FRig.Rig.Entity(LWorker)^.UnitData.ResourceKind));
  Assert.IsTrue(PWarStateDeliver(FRig.Rig.World.Machine.ActiveState(LWorker))^.InsideBuilding);
  // inside the building the worker is not drawn
  Assert.IsFalse(FRig.Rig.Entity(LWorker)^.SpriteEnabled);
end;

procedure TTestWarGatherStates.DovrebbeUscireDalMunicipioEAndareInattivoDopoUnSecondo;
var
  LWorker: Integer;
  LTownHall: Integer;
begin
  LTownHall := FRig.AddTownHall(10, 10);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  OrderDeliver(LWorker, IdOf(LTownHall));
  FRig.Rig.TickAll(3);
  Assert.AreEqual(WAR_STATE_DELIVER, ActiveType(LWorker));
  FRig.Rig.RunAll(0.9);
  Assert.AreEqual(WAR_STATE_DELIVER, ActiveType(LWorker));
  FRig.Rig.RunAll(0.4);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
  Assert.IsTrue(FRig.Rig.Entity(LWorker)^.SpriteEnabled);
  Assert.AreEqual(PEASANT_SPRITE, FRig.Rig.Entity(LWorker)^.SpriteResource);
end;

procedure TTestWarGatherStates.DovrebbeTornareAlloStatoSottostanteDopoLaConsegna;
var
  LWorker: Integer;
  LTownHall: Integer;
  LForest: Word;
begin
  LTownHall := FRig.AddTownHall(10, 10);
  LForest := FRig.AddForestBlock(20, 20, 4, 3, 50);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  OrderWood(LWorker, LForest, 20, 20);
  FRig.Rig.TickAll(2);
  // a delivery pushed on top of the walk to the tree (depth 2 or more): when it ends the state below is back
  FRig.Rig.World.Machine.PushState(LWorker, PWarStateBase(TWarGatherStateFactory.NewDeliver(FRig.Rig.World.Machine,
    LWorker, IdOf(LTownHall))), WAR_CAUSE_COMPLETION);
  FRig.Rig.TickAll(3);
  Assert.AreEqual(WAR_STATE_DELIVER, ActiveType(LWorker));
  FRig.Rig.RunAll(1.4);
  // the delivery ended without a cycle and with a state under it: that one is active again
  Assert.AreEqual(WAR_STATE_MOVE, ActiveType(LWorker));
end;

procedure TTestWarGatherStates.DovrebbeRicominciareDallaMinieraSeLaConsegnaECiclica;
var
  LWorker: Integer;
  LTownHall: Integer;
  LMine: Integer;
  LDeliver: PWarStateDeliver;
begin
  LTownHall := FRig.AddTownHall(10, 10);
  LMine := FRig.AddMine(14, 10, 500);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  LDeliver := TWarGatherStateFactory.NewDeliver(FRig.Rig.World.Machine, LWorker, IdOf(LTownHall));
  LDeliver^.Cycle := True;
  LDeliver^.SourceKind := wrkGold;
  LDeliver^.SourceId := IdOf(LMine);
  Order(LWorker, LDeliver);
  FRig.Rig.RunAll(1.5);
  Assert.IsTrue(ActiveType(LWorker) in [WAR_STATE_GOLD, WAR_STATE_FOLLOW, WAR_STATE_MINING]);
end;

procedure TTestWarGatherStates.DovrebbeRicominciareDallAlberoSeLaConsegnaECiclica;
var
  LWorker: Integer;
  LTownHall: Integer;
  LForest: Word;
  LDeliver: PWarStateDeliver;
begin
  LTownHall := FRig.AddTownHall(10, 10);
  LForest := FRig.AddForestBlock(14, 10, 4, 3, 50);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  LDeliver := TWarGatherStateFactory.NewDeliver(FRig.Rig.World.Machine, LWorker, IdOf(LTownHall));
  LDeliver^.Cycle := True;
  LDeliver^.SourceKind := wrkWood;
  LDeliver^.SourceId := LForest;
  LDeliver^.SourcePosition := FRig.TileCenter(14, 10);
  Order(LWorker, LDeliver);
  FRig.Rig.RunAll(1.5);
  Assert.IsTrue(ActiveType(LWorker) in [WAR_STATE_WOOD, WAR_STATE_MOVE, WAR_STATE_CHOPPING]);
end;

procedure TTestWarGatherStates.DovrebbeAndareInattivoSeIlMunicipioNonEsiste;
var
  LWorker: Integer;
begin
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  OrderDeliver(LWorker, 999);
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
end;

procedure TTestWarGatherStates.DovrebbeSeguireIlMunicipioSeELontano;
var
  LWorker: Integer;
  LTownHall: Integer;
  LFollow: PWarStateFollow;
begin
  LTownHall := FRig.AddTownHall(30, 30);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  OrderDeliver(LWorker, IdOf(LTownHall));
  FRig.Rig.TickAll(4);
  Assert.AreEqual(WAR_STATE_FOLLOW, ActiveType(LWorker));
  LFollow := PWarStateFollow(FRig.Rig.World.Machine.ActiveState(LWorker));
  Assert.AreEqual<Integer>(IdOf(LTownHall), LFollow^.TargetEntityId);
  // the point of the building that is closest to the worker (its corner)
  Near(480, LFollow^.TargetPosition.X, 0.01);
  Near(480, LFollow^.TargetPosition.Y, 0.01);
end;

procedure TTestWarGatherStates.DovrebbeConsegnareIlCaricoUnaVoltaSola;
var
  LWorker: Integer;
  LTownHall: Integer;
begin
  LTownHall := FRig.AddTownHall(10, 10);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  FRig.Rig.Entity(LWorker)^.UnitData.ResourceKind := wrkGold;
  FRig.Rig.Entity(LWorker)^.UnitData.Amount := 100;
  OrderDeliver(LWorker, IdOf(LTownHall));
  FRig.Rig.RunAll(3);
  Assert.AreEqual(WAR_STATE_IDLE, ActiveType(LWorker));
  // 1000 gold at the start of the rig and one delivery of 100
  Assert.AreEqual(1100, FRig.Rig.World.Context.Players[0]^.Gold);
end;

procedure TTestWarGatherStates.DovrebbeConservareIlDifettoDellaLegnaDispariCheNonArrivaMaACento;
var
  LWorker: Integer;
  LForest: Word;
begin
  // each blow takes 2 and the carrying ends when the wood is exactly 100: with an odd amount it never ends
  LForest := FRig.AddForestBlock(12, 10, 4, 3, 100);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 11, 10);
  FRig.Rig.Entity(LWorker)^.UnitData.Amount := 97;
  OrderWood(LWorker, LForest, 12, 10);
  FRig.Rig.RunAll(4);
  Assert.AreEqual(WAR_STATE_CHOPPING, ActiveType(LWorker));
  Assert.IsTrue(FRig.Rig.Entity(LWorker)^.UnitData.Amount > 100);
end;

procedure TTestWarGatherStates.DovrebbeConservareIlDifettoDelLavoratoreNascostoSeRiceveUnOrdine;
var
  LWorker: Integer;
  LTownHall: Integer;
begin
  // a worker that is inside a building and is given another order is never shown again
  LTownHall := FRig.AddTownHall(10, 10);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  OrderDeliver(LWorker, IdOf(LTownHall));
  FRig.Rig.TickAll(3);
  Assert.IsFalse(FRig.Rig.Entity(LWorker)^.SpriteEnabled);
  FRig.Rig.Move(LWorker, [FRig.TileCenter(9, 10), FRig.TileCenter(9, 20)]);
  FRig.Rig.TickAll(5);
  Assert.AreEqual(WAR_STATE_MOVE, ActiveType(LWorker));
  Assert.IsFalse(FRig.Rig.Entity(LWorker)^.SpriteEnabled);
end;

procedure TTestWarGatherStates.DovrebbeConservareIlDifettoDellOroSommatoAllaLegnaTrasportata;
var
  LWorker: Integer;
  LMine: Integer;
begin
  // the gold is added to what the worker carries, whatever it is: 30 wood and 100 gold are 130 gold
  LMine := FRig.AddMine(11, 10, 500);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  FRig.Rig.Entity(LWorker)^.UnitData.ResourceKind := wrkWood;
  FRig.Rig.Entity(LWorker)^.UnitData.Amount := 30;
  OrderGold(LWorker, IdOf(LMine));
  FRig.Rig.RunAll(2.2);
  Assert.AreEqual(130, FRig.Rig.Entity(LWorker)^.UnitData.Amount);
  Assert.AreEqual(Ord(wrkGold), Ord(FRig.Rig.Entity(LWorker)^.UnitData.ResourceKind));
end;

procedure TTestWarGatherStates.DovrebbeSostituireLoSpriteSeNeAggiungiUnAltro;
var
  LEntity: TWarEntity;
begin
  LEntity := Default(TWarEntity);
  TWarUnitSprites.Add(@LEntity, 329);
  TWarUnitSprites.Add(@LEntity, 281);
  Assert.AreEqual(281, LEntity.SpriteResource);
  Assert.IsTrue(LEntity.SpriteEnabled);
  Assert.IsTrue(LEntity.HasSprite);
  TWarUnitSprites.Remove(@LEntity);
  Assert.AreEqual(0, LEntity.SpriteResource);
  Assert.IsFalse(LEntity.HasSprite);
  TWarUnitSprites.Disable(@LEntity);
  Assert.IsFalse(LEntity.SpriteEnabled);
end;

procedure TTestWarGatherStates.DovrebbeDareEccezioneSeMancaLaMappaDeiRaccoglitori;
var
  LWorker: Integer;
  LForest: Word;
  LContext: TWarModelContext;
begin
  LForest := FRig.AddForestBlock(12, 10, 4, 3, 20);
  LWorker := FRig.Rig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  LContext := FRig.Rig.World.Context;
  LContext.Gather := nil;
  OrderWood(LWorker, LForest, 12, 10);
  Assert.WillRaise(
    procedure
    begin
      FRig.Rig.TickAll(4);
    end, EWarException);
  LContext.Gather := FRig.Gather;
end;

procedure TTestWarGatherStates.DovrebbeDareEccezioneSeIlTipoNonEUnLavoratore;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarUnitSprites.CarryingGold(WAR_UNIT_FOOTMAN);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarUnitSprites.CarryingWood(WAR_UNIT_FOOTMAN);
    end, EWarException);
end;

end.
