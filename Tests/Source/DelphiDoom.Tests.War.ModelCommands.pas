{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the commands of the model             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelCommands;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.Commands.Types, DelphiDoom.Tests.War.CommandRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarCommandFamilies = class(TObject)
  private
    FRig: TCommandRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMuovereLeSoleUnitaMobiliDelGiocatore;
    [Test]
    procedure DovrebbeDareLoStessoPuntoATutteLeUnita;
    [Test]
    procedure DovrebbeAggiungereUnPuntoAChiSiMuoveConLaCoda;
    [Test]
    procedure DovrebbeAggiungereUnPuntoAncheAllaPattugliaConLaCoda;
    [Test]
    procedure DovrebbeRicominciareIlMovimentoDiChiAttaccaConLaCoda;
    [Test]
    procedure DovrebbeSollevareSeUnSelezionatoNonEsistePiu;
    [Test]
    procedure DovrebbeFarSeguireLeSoleUnitaMobili;
    [Test]
    procedure DovrebbeFermareAncheGliEdifici;
    [Test]
    procedure DovrebbeFarAttaccareIGuerrieriEFarSeguireILavoratori;
    [Test]
    procedure DovrebbeNonFarAttaccareSeStessi;
    [Test]
    procedure DovrebbeMandareLeUnitaMobiliAllAttaccoDiUnPunto;
    [Test]
    procedure DovrebbeNonDareLAttaccoDiUnPuntoAUnEdificio;
    [Test]
    procedure DovrebbeNonFarSeguireUnMuroAUnLavoratore;
    [Test]
    procedure DovrebbeMandareILavoratoriAllaMinieraEGliAltriVicino;
    [Test]
    procedure DovrebbeMandareILavoratoriAllAlbero;
    [Test]
    procedure DovrebbeFarConsegnarePrimaChiPortaUnCaricoPieno;
    [Test]
    procedure DovrebbeConfermareAncheSenzaMunicipioPerChiPortaUnCarico;
    [Test]
    procedure DovrebbeRifiutareDiRaccogliereCioCheNonEMinieraNeForesta;
    [Test]
    procedure DovrebbeFarConsegnareChiPortaEFarSeguireGliAltri;
    [Test]
    procedure DovrebbeSollevareSeNonCEUnMunicipioPerConsegnare;
    [Test]
    procedure DovrebbeEvocareFinoAEsaurireIlMana;
    [Test]
    procedure DovrebbeEvocareAncheConUnEvocatoreNemicoSelezionato;
    [Test]
    procedure DovrebbeNonEvocareSeNessunoPuo;
    [Test]
    procedure DovrebbeMettereGliEvocatoriNelloStatoDiPioggiaENube;
    [Test]
    procedure DovrebbeGuarireSoloUnitaMobiliEMaiSeStessi;
    [Test]
    procedure DovrebbeLanciareInvisibilitaEArmaturaSuUnaUnitaMobile;
    [Test]
    procedure DovrebbeScegliereLaVistaDellaRazzaDiChiLancia;
    [Test]
    procedure DovrebbeMettereIChiericiNelloStatoDiResurrezione;
    [Test]
    procedure DovrebbeDareGliOrdiniDelComputerAlleSueUnita;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarCommands = class(TObject)
  private
    FRig: TCommandRig;
    function Golden: TStringList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereLeTabelleDeiComandiDelC;
    [Test]
    procedure DovrebbeNonEseguireIMenuDegliEdificiNeNessunComando;
    [Test]
    procedure DovrebbeSollevarePerUnComandoCheNonEsiste;
    [Test]
    procedure DovrebbeLasciarSostituireChiEsegueUnComando;
    [Test]
    procedure DovrebbeMuovereEFermareConIComandi;
    [Test]
    procedure DovrebbeRaccogliereDallaMinieraSottoIlPunto;
    [Test]
    procedure DovrebbeMuovereVersoUnaMinieraSconosciuta;
    [Test]
    procedure DovrebbeRaccogliereDallAlberoSottoIlPunto;
    [Test]
    procedure DovrebbeCercareUnAlberoRaggiungibileSeLaCasellaNonSiVede;
    [Test]
    procedure DovrebbeMuovereSeNessunAlberoERaggiungibile;
    [Test]
    procedure DovrebbeNonFareNullaSeSottoIlPuntoNonCENulla;
    [Test]
    procedure DovrebbeConsegnareConIlComando;
    [Test]
    procedure DovrebbeRiparareLEdificioSottoIlPunto;
    [Test]
    procedure DovrebbeNonRiparareCioCheNonSiVede;
    [Test]
    procedure DovrebbeAttaccareLUnitaSottoIlPunto;
    [Test]
    procedure DovrebbeAttaccareIlPuntoSeLUnitaNonSiVede;
    [Test]
    procedure DovrebbeAttaccareIlMuroSottoIlPunto;
    [Test]
    procedure DovrebbeAttaccareIlPuntoSeIlMuroNonSiVede;
    [Test]
    procedure DovrebbeAddestrareDallEdificioSelezionato;
    [Test]
    procedure DovrebbeSollevareSeLEdificioNonAddestraQuellUnita;
    [Test]
    procedure DovrebbeSollevareSenzaUnSoloEdificioSelezionato;
    [Test]
    procedure DovrebbeMigliorareDallEdificioSelezionato;
    [Test]
    procedure DovrebbeCostruireConIlPrimoSelezionato;
    [Test]
    procedure DovrebbeSuonareLAnnullaSeNonSiPuoCostruireLi;
    [Test]
    procedure DovrebbeSollevareSeNessunoESelezionatoPerCostruire;
    [Test]
    procedure DovrebbeCostruireMuraEStradeDalMunicipio;
    [Test]
    procedure DovrebbeSollevareSeIlSelezionatoNonEIlMunicipio;
    [Test]
    procedure DovrebbeNonCostruireLaStradaSuUnaCasellaOccupataOSenzaOro;
    [Test]
    procedure DovrebbeEvocareELanciareOgniIncantesimoConIComandi;
    [Test]
    procedure DovrebbeAnnullareCioCheFannoGliEdificiSelezionati;
    [Test]
    procedure DovrebbeNonFareNullaConIlClicDestroSenzaSelezione;
    [Test]
    procedure DovrebbeMuovereConIlClicDestroSulVuoto;
    [Test]
    procedure DovrebbeRaccogliereConIlClicDestroSuMinieraEAlbero;
    [Test]
    procedure DovrebbeConsegnareConIlClicDestroSulProprioMunicipio;
    [Test]
    procedure DovrebbeAttaccareConIlClicDestroSulMunicipioNemico;
    [Test]
    procedure DovrebbeMuovereConIlClicDestroSuUnMunicipioSconosciuto;
    [Test]
    procedure DovrebbeMuovereConIlClicDestroSulMuro;
    [Test]
    procedure DovrebbeAttaccareIlNemicoESeguireLAmicoConIlClicDestro;
    [Test]
    procedure DovrebbeNonTrovareNessunoSenzaLaMappa;
    [Test]
    procedure DovrebbeRisponderePerLaNebbiaDallaMappaDeiComandi;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarWallAttack = class(TObject)
  private
    FRig: TCommandRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAbbattereUnPezzoDiMuroACorpoACorpo;
    [Test]
    procedure DovrebbeAvvicinarsiAlMuroFuoriPortata;
    [Test]
    procedure DovrebbeColpireIlMuroConUnaFreccia;
    [Test]
    procedure DovrebbeFermareIlMagoSenzaManaDavantiAlMuro;
    [Test]
    procedure DovrebbeFerireIPezziViciniConLaCatapulta;
    [Test]
    procedure DovrebbeFerireIPezziDiMuroConLaPioggiaDiFuoco;
    [Test]
    procedure DovrebbeColpireSenzaFineDoveNonCEUnPezzo;
    [Test]
    procedure DovrebbeNonFerireLeMuraSenzaLEntitaDelMuro;
    [Test]
    procedure DovrebbeMostrareLImmagineDelCantiereMentreSiCostruisce;
    [Test]
    procedure DovrebbeFareUnTicInteroConTick;
    [Test]
    procedure DovrebbeAddestrarePerOrdineDelComputer;
    [Test]
    procedure DovrebbeCreareLEntitaDellaStrada;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.Selection, DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.TerrainEntities,
  DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Model.Commands.Intf,
  DelphiDoom.War.Model.Commands.Dispatcher, DelphiDoom.War.Model.Commands.GridMap,
  DelphiDoom.War.Model.BuildingResources.Data, DelphiDoom.War.Model.UnitSprites,
  DelphiDoom.Tests.War.RealData;

type
  TSpyHandler = class
  public
    Calls: Integer;
    function Handle(const ACommand: TWarCommand): TWarCommandOutcome;
  end;

function TSpyHandler.Handle(const ACommand: TWarCommand): TWarCommandOutcome;
begin
  Inc(Calls);
  Result := wcoExecuted;
end;

{ TTestWarCommandFamilies }

procedure TTestWarCommandFamilies.Setup;
begin
  FRig := TCommandRig.Create;
end;

procedure TTestWarCommandFamilies.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarCommandFamilies.DovrebbeMuovereLeSoleUnitaMobiliDelGiocatore;
var
  LFootman: Integer;
  LFarm: Integer;
  LGrunt: Integer;
  LAcknowledged: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 14, 10);
  LGrunt := FRig.AddDude(WAR_UNIT_GRUNT, 50, 50, 1);
  FRig.Select([LFootman, LFarm, LGrunt]);
  LAcknowledged := FRig.Observer.Acknowledged;
  Assert.IsTrue(FRig.Commands.Movement.Move(FRig.TilePoint(20, 20)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(LFootman));
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFarm));
  Assert.AreNotEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(LGrunt), 'un nemico selezionato non obbedisce');
  Assert.AreEqual(LAcknowledged + 1, FRig.Observer.Acknowledged, 'una sola conferma');
  FRig.Select([LFarm]);
  Assert.IsFalse(FRig.Commands.Movement.Move(FRig.TilePoint(20, 20)));
  FRig.Select([]);
  Assert.IsFalse(FRig.Commands.Movement.Move(FRig.TilePoint(20, 20)));
end;

procedure TTestWarCommandFamilies.DovrebbeDareLoStessoPuntoATutteLeUnita;
var
  LFirst: Integer;
  LSecond: Integer;
  LMove: PWarStateMove;
  LOther: PWarStateMove;
begin
  LFirst := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LSecond := FRig.AddDude(WAR_UNIT_ARCHER, 12, 10);
  FRig.Select([LFirst, LSecond]);
  FRig.Commands.Movement.Move(TWarModelMath.Vec(333, 444));
  FRig.Tick;
  LMove := PWarStateMove(FRig.Machine.FindState(LFirst, WAR_STATE_MOVE));
  LOther := PWarStateMove(FRig.Machine.FindState(LSecond, WAR_STATE_MOVE));
  // the original has no formation: every unit gets the very same point
  Assert.AreEqual<Single>(333, LMove^.Waypoints[1].X);
  Assert.AreEqual<Single>(444, LMove^.Waypoints[1].Y);
  Assert.AreEqual<Single>(333, LOther^.Waypoints[1].X);
  Assert.AreEqual<Single>(444, LOther^.Waypoints[1].Y);
end;

procedure TTestWarCommandFamilies.DovrebbeAggiungereUnPuntoAChiSiMuoveConLaCoda;
var
  LFootman: Integer;
  LMove: PWarStateMove;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Select([LFootman]);
  // with nothing to add to, the queue starts a move like any other
  Assert.IsTrue(FRig.Commands.Movement.Move(FRig.TilePoint(30, 10), True));
  FRig.Tick;
  Assert.IsTrue(FRig.Commands.Movement.Move(FRig.TilePoint(30, 30), True));
  LMove := PWarStateMove(FRig.Machine.FindState(LFootman, WAR_STATE_MOVE));
  Assert.AreEqual(3, LMove^.WaypointsCount);
  Assert.AreEqual<Single>(FRig.TilePoint(30, 30).Y, LMove^.Waypoints[2].Y);
  // the list of the waypoints is full: nothing more is added
  LMove^.WaypointsCount := WAR_MODEL_MAX_WAYPOINTS;
  FRig.Commands.Movement.Move(FRig.TilePoint(40, 40), True);
  Assert.AreEqual(WAR_MODEL_MAX_WAYPOINTS, LMove^.WaypointsCount);
end;

procedure TTestWarCommandFamilies.DovrebbeAggiungereUnPuntoAncheAllaPattugliaConLaCoda;
var
  LFootman: Integer;
  LPatrol: PWarStatePatrol;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LPatrol := FRig.Machine.CreatePatrol(LFootman, [FRig.Center(LFootman), FRig.TilePoint(30, 10)]);
  FRig.Machine.ResetState(LFootman, PWarStateBase(LPatrol), WAR_CAUSE_PLAYER_ORDER);
  FRig.Tick(3);
  Assert.IsTrue(FRig.Machine.Contains(LFootman, WAR_STATE_MOVE), 'la pattuglia cammina');
  FRig.Select([LFootman]);
  FRig.Commands.Movement.Move(FRig.TilePoint(30, 30), True);
  LPatrol := PWarStatePatrol(FRig.Machine.FindState(LFootman, WAR_STATE_PATROL));
  Assert.AreEqual(3, LPatrol^.WaypointsCount);
  Assert.AreEqual(3, PWarStateMove(FRig.Machine.FindState(LFootman, WAR_STATE_MOVE))^.WaypointsCount);
  LPatrol^.WaypointsCount := WAR_MODEL_MAX_WAYPOINTS;
  FRig.Commands.Movement.Move(FRig.TilePoint(40, 40), True);
  Assert.AreEqual(WAR_MODEL_MAX_WAYPOINTS, LPatrol^.WaypointsCount);
end;

procedure TTestWarCommandFamilies.DovrebbeRicominciareIlMovimentoDiChiAttaccaConLaCoda;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Select([LFootman]);
  FRig.Commands.Attack.Attack(0, FRig.TilePoint(40, 10));
  FRig.Tick(3);
  Assert.IsTrue(FRig.Machine.Contains(LFootman, WAR_STATE_MOVE) and FRig.Machine.IsAttacking(LFootman));
  FRig.Commands.Movement.Move(FRig.TilePoint(10, 40), True);
  FRig.Tick;
  Assert.IsFalse(FRig.Machine.IsAttacking(LFootman), 'un movimento nuovo al posto dell''attacco');
  Assert.AreEqual(2, PWarStateMove(FRig.Machine.FindState(LFootman, WAR_STATE_MOVE))^.WaypointsCount);
end;

procedure TTestWarCommandFamilies.DovrebbeSollevareSeUnSelezionatoNonEsistePiu;
var
  LFootman: Integer;
  LFarm: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Select([LFootman]);
  FRig.World.Entities.RemoveEntity(LFootman);
  // defect of the original kept: the removed entity stays selected; its assert is an exception here
  Assert.AreEqual(1, FRig.Context.Selection.Count);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Movement.Stop;
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Cancel;
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Spells.Sight(FRig.TilePoint(10, 10));
    end, EWarException);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 30, 30);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(WAR_COMMAND_REPAIR, FRig.Center(LFarm));
    end, EWarException);
  // an order that finds nothing under its point does not look at the selection
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_REPAIR, FRig.TilePoint(50, 50)));
end;

procedure TTestWarCommandFamilies.DovrebbeFarSeguireLeSoleUnitaMobili;
var
  LFootman: Integer;
  LFarm: Integer;
  LTarget: Integer;
  LFollow: PWarStateFollow;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 14, 10);
  LTarget := FRig.AddDude(WAR_UNIT_PEASANT, 30, 30);
  FRig.Select([LFootman, LFarm]);
  Assert.IsTrue(FRig.Commands.Movement.Follow(LTarget));
  FRig.Tick;
  LFollow := PWarStateFollow(FRig.Machine.FindState(LFootman, WAR_STATE_FOLLOW));
  Assert.IsNotNull(LFollow);
  Assert.AreEqual(Integer(FRig.IdOf(LTarget)), Integer(LFollow^.TargetEntityId));
  Assert.AreEqual(WAR_MODEL_MEGA_TILE, LFollow^.TargetDistance);
  // wanted difference: the original gives the order to the building too and stops on an assert
  Assert.IsFalse(FRig.Machine.Contains(LFarm, WAR_STATE_FOLLOW));
  FRig.Select([LFarm]);
  Assert.IsFalse(FRig.Commands.Movement.Follow(LTarget));
end;

procedure TTestWarCommandFamilies.DovrebbeFermareAncheGliEdifici;
var
  LFootman: Integer;
  LBarracks: Integer;
  LGold: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 14, 10);
  FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  LGold := FRig.Context.Players[0]^.Gold;
  Assert.IsTrue(FRig.Commands.Construction.OrderTrain(LBarracks, WAR_UNIT_FOOTMAN));
  FRig.Tick;
  Assert.IsTrue(FRig.Context.Players[0]^.Gold < LGold);
  FRig.Select([LFootman, LBarracks]);
  FRig.Commands.Movement.Move(FRig.TilePoint(30, 30));
  FRig.Tick;
  Assert.IsTrue(FRig.Commands.Movement.Stop);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFootman));
  // defect of the original kept: the stop reaches the building that trains
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LBarracks));
  FRig.Select([]);
  Assert.IsFalse(FRig.Commands.Movement.Stop);
end;

procedure TTestWarCommandFamilies.DovrebbeFarAttaccareIGuerrieriEFarSeguireILavoratori;
var
  LFootman: Integer;
  LPeasant: Integer;
  LEnemy: Integer;
  LAttack: PWarStateAttack;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 12);
  LEnemy := FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 30, 30, 1);
  FRig.Select([LFootman, LPeasant]);
  Assert.IsTrue(FRig.Commands.Attack.Attack(LEnemy, FRig.Center(LEnemy)));
  FRig.Tick;
  LAttack := PWarStateAttack(FRig.Machine.FindState(LFootman, WAR_STATE_ATTACK));
  Assert.IsNotNull(LAttack);
  Assert.AreEqual(Integer(FRig.IdOf(LEnemy)), Integer(LAttack^.TargetEntityId));
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_FOLLOW), 'il lavoratore segue il bersaglio');
  // only workers: they follow, but nobody attacks and nothing is acknowledged
  FRig.Select([LPeasant]);
  Assert.IsFalse(FRig.Commands.Attack.Attack(LEnemy, FRig.Center(LEnemy)));
end;

procedure TTestWarCommandFamilies.DovrebbeNonFarAttaccareSeStessi;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Select([LFootman]);
  Assert.IsFalse(FRig.Commands.Attack.Attack(LFootman, FRig.Center(LFootman)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFootman));
end;

procedure TTestWarCommandFamilies.DovrebbeMandareLeUnitaMobiliAllAttaccoDiUnPunto;
var
  LFootman: Integer;
  LPeasant: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 12);
  FRig.Select([LFootman, LPeasant]);
  Assert.IsTrue(FRig.Commands.Attack.Attack(0, FRig.TilePoint(30, 30)));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.IsAttacking(LFootman));
  Assert.IsTrue(FRig.Machine.IsAttacking(LPeasant), 'difetto conservato: anche il lavoratore va al punto');
end;

procedure TTestWarCommandFamilies.DovrebbeNonDareLAttaccoDiUnPuntoAUnEdificio;
var
  LFarm: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 14, 10);
  FRig.Select([LFarm]);
  // wanted difference: the attack state of a building stops the original on an assert
  Assert.IsFalse(FRig.Commands.Attack.Attack(0, FRig.TilePoint(30, 30)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFarm));
end;

procedure TTestWarCommandFamilies.DovrebbeNonFarSeguireUnMuroAUnLavoratore;
var
  LPeasant: Integer;
begin
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  FRig.AddWallPiece(20, 10);
  FRig.Select([LPeasant]);
  // wanted difference: the original makes the worker follow an entity that has no place, and stops on an assert
  Assert.IsFalse(FRig.Commands.Attack.Attack(FRig.WallSlot, FRig.TilePoint(20, 10)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LPeasant));
end;

procedure TTestWarCommandFamilies.DovrebbeMandareILavoratoriAllaMinieraEGliAltriVicino;
var
  LPeasant: Integer;
  LFootman: Integer;
  LFarm: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(30, 10, 500);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 12);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 14, 14);
  FRig.Select([LPeasant, LFootman, LFarm]);
  Assert.IsTrue(FRig.Commands.Gather.Harvest(LMine, 30, 10));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_GOLD));
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(LFootman));
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFarm));
  FRig.Select([LFarm]);
  Assert.IsFalse(FRig.Commands.Gather.Harvest(LMine, 30, 10));
end;

procedure TTestWarCommandFamilies.DovrebbeMandareILavoratoriAllAlbero;
var
  LPeon: Integer;
  LForest: Integer;
  LWood: PWarStateWood;
begin
  LForest := FRig.AddTree(30, 12, 50);
  LPeon := FRig.AddDude(WAR_UNIT_PEON, 10, 10);
  FRig.Select([LPeon]);
  Assert.IsTrue(FRig.Commands.Gather.Harvest(LForest, 30, 12));
  FRig.Tick;
  LWood := PWarStateWood(FRig.Machine.FindState(LPeon, WAR_STATE_WOOD));
  Assert.IsNotNull(LWood);
  Assert.AreEqual(Integer(FRig.IdOf(LForest)), Integer(LWood^.ForestId));
  Assert.AreEqual<Single>(FRig.TilePoint(30, 12).X, LWood^.Position.X);
end;

procedure TTestWarCommandFamilies.DovrebbeFarConsegnarePrimaChiPortaUnCaricoPieno;
var
  LPeasant: Integer;
  LMine: Integer;
  LForest: Integer;
  LTownHall: Integer;
  LDeliver: PWarStateDeliver;
begin
  LTownHall := FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, 6, 6);
  LMine := FRig.AddMine(30, 10, 500);
  LForest := FRig.AddTree(30, 20, 50);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 12, 10);
  FRig.UnitOf(LPeasant)^.ResourceKind := wrkWood;
  FRig.UnitOf(LPeasant)^.Amount := WAR_MODEL_MAX_CARRY;
  FRig.Select([LPeasant]);
  Assert.IsTrue(FRig.Commands.Gather.Harvest(LMine, 30, 10));
  FRig.Tick;
  LDeliver := PWarStateDeliver(FRig.Machine.FindState(LPeasant, WAR_STATE_DELIVER));
  Assert.IsNotNull(LDeliver);
  Assert.IsTrue(LDeliver^.Cycle);
  Assert.AreEqual(wrkGold, LDeliver^.SourceKind);
  Assert.AreEqual(Integer(FRig.IdOf(LMine)), Integer(LDeliver^.SourceId));
  Assert.AreEqual(Integer(FRig.IdOf(LTownHall)), Integer(LDeliver^.TownHallId));
  Assert.IsTrue(FRig.Commands.Gather.Harvest(LForest, 30, 20));
  FRig.Tick;
  LDeliver := PWarStateDeliver(FRig.Machine.FindState(LPeasant, WAR_STATE_DELIVER));
  Assert.AreEqual(wrkWood, LDeliver^.SourceKind);
  Assert.AreEqual<Single>(FRig.TilePoint(30, 20).Y, LDeliver^.SourcePosition.Y);
  // a load that is not full is not a load: the worker leaves for the new harvest with what it carries
  FRig.UnitOf(LPeasant)^.Amount := 60;
  FRig.Commands.Gather.Harvest(LMine, 30, 10);
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_GOLD));
end;

procedure TTestWarCommandFamilies.DovrebbeConfermareAncheSenzaMunicipioPerChiPortaUnCarico;
var
  LPeasant: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(30, 10, 500);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 12, 10);
  FRig.UnitOf(LPeasant)^.ResourceKind := wrkGold;
  FRig.UnitOf(LPeasant)^.Amount := WAR_MODEL_MAX_CARRY;
  FRig.Select([LPeasant]);
  // defect of the original kept: nothing is ordered and the order is acknowledged anyway
  Assert.IsTrue(FRig.Commands.Gather.Harvest(LMine, 30, 10));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LPeasant));
end;

procedure TTestWarCommandFamilies.DovrebbeRifiutareDiRaccogliereCioCheNonEMinieraNeForesta;
var
  LPeasant: Integer;
  LFarm: Integer;
begin
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 12, 10);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  FRig.Select([LPeasant]);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Gather.Harvest(LFarm, 20, 10);
    end, EWarException);
end;

procedure TTestWarCommandFamilies.DovrebbeFarConsegnareChiPortaEFarSeguireGliAltri;
var
  LPeasant: Integer;
  LEmpty: Integer;
  LFootman: Integer;
  LFarm: Integer;
  LTownHall: Integer;
begin
  LTownHall := FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, 6, 6);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 30, 30);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 20, 10);
  LEmpty := FRig.AddDude(WAR_UNIT_PEASANT, 20, 12);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 20, 14);
  FRig.UnitOf(LPeasant)^.ResourceKind := wrkGold;
  FRig.UnitOf(LPeasant)^.Amount := WAR_MODEL_MAX_CARRY;
  FRig.Select([LPeasant, LEmpty, LFootman, LFarm]);
  Assert.IsTrue(FRig.Commands.Gather.Deliver(0));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_DELIVER));
  Assert.IsTrue(FRig.Machine.Contains(LEmpty, WAR_STATE_FOLLOW), 'chi non porta nulla va al municipio');
  Assert.IsTrue(FRig.Machine.Contains(LFootman, WAR_STATE_FOLLOW));
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFarm));
  Assert.AreEqual(Integer(FRig.IdOf(LTownHall)),
    Integer(PWarStateFollow(FRig.Machine.FindState(LFootman, WAR_STATE_FOLLOW))^.TargetEntityId));
  FRig.Select([LFarm]);
  Assert.IsFalse(FRig.Commands.Gather.Deliver(LTownHall));
end;

procedure TTestWarCommandFamilies.DovrebbeSollevareSeNonCEUnMunicipioPerConsegnare;
var
  LPeon: Integer;
begin
  FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, 6, 6);
  LPeon := FRig.AddDude(WAR_UNIT_PEON, 20, 10);
  FRig.Select([LPeon]);
  // the town hall is the one of the race of the unit: an orc worker of the humans has none (an assert of the original)
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Gather.Deliver(0);
    end, EWarException);
end;

procedure TTestWarCommandFamilies.DovrebbeEvocareFinoAEsaurireIlMana;
var
  LConjurer: Integer;
  LFlashes: Cardinal;
  LEffects: Integer;
begin
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 10, 10);
  FRig.UnitOf(LConjurer)^.Mana := 120;
  FRig.UnitOf(LConjurer)^.Invisible := True;
  LFlashes := FRig.Observer.FlashCount;
  LEffects := FRig.CountEntities(WAR_ENTITY_ANIMATION);
  FRig.Select([LConjurer]);
  Assert.IsTrue(FRig.Commands.Spells.Summon(WAR_SUMMON_SCORPION));
  Assert.AreEqual(2, FRig.CountOfType(WAR_UNIT_SCORPION), 'uno scorpione ogni 51 di mana');
  Assert.AreEqual(18, FRig.UnitOf(LConjurer)^.Mana);
  Assert.IsFalse(FRig.UnitOf(LConjurer)^.Invisible);
  Assert.AreEqual(LFlashes + 1, FRig.Observer.FlashCount, 'finisce sempre con "manca il mana"');
  Assert.AreEqual(LEffects + 2, FRig.CountEntities(WAR_ENTITY_ANIMATION), 'un lampo per unita'' evocata');
  Assert.AreEqual(WAR_SOUND_NORMAL_SPELL, FRig.Observer.LastSound);
  // each summoned unit takes its own tile
  Assert.AreNotEqual(
    FRig.Entity(FRig.Context.Pool.UnitsOfType[WAR_UNIT_SCORPION][0])^.Position.X * 1000 +
    FRig.Entity(FRig.Context.Pool.UnitsOfType[WAR_UNIT_SCORPION][0])^.Position.Y,
    FRig.Entity(FRig.Context.Pool.UnitsOfType[WAR_UNIT_SCORPION][1])^.Position.X * 1000 +
    FRig.Entity(FRig.Context.Pool.UnitsOfType[WAR_UNIT_SCORPION][1])^.Position.Y);
  Assert.AreEqual(0, Integer(FRig.UnitOf(FRig.Context.Pool.UnitsOfType[WAR_UNIT_SCORPION][0])^.Player));
end;

procedure TTestWarCommandFamilies.DovrebbeEvocareAncheConUnEvocatoreNemicoSelezionato;
var
  LWarlock: Integer;
begin
  LWarlock := FRig.AddDude(WAR_UNIT_WARLOCK, 40, 40, 1);
  FRig.Select([LWarlock]);
  // defect of the original kept: nobody asks whose the caster is
  Assert.IsTrue(FRig.Commands.Spells.Summon(WAR_SUMMON_SPIDER));
  Assert.AreEqual(1, FRig.CountOfType(WAR_UNIT_SPIDER));
  Assert.AreEqual(1, Integer(FRig.UnitOf(FRig.Context.Pool.UnitsOfType[WAR_UNIT_SPIDER][0])^.Player));
end;

procedure TTestWarCommandFamilies.DovrebbeNonEvocareSeNessunoPuo;
var
  LCleric: Integer;
  LConjurer: Integer;
  LSound: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 12, 10);
  FRig.UnitOf(LConjurer)^.Mana := 10;
  LSound := FRig.Observer.LastSound;
  FRig.Select([LCleric, LConjurer]);
  Assert.IsFalse(FRig.Commands.Spells.Summon(WAR_SUMMON_DAEMON));
  Assert.AreEqual(0, FRig.CountOfType(WAR_UNIT_DAEMON));
  Assert.AreEqual(LSound, FRig.Observer.LastSound, 'nessun suono se non si evoca nulla');
  // a full pool stops the summon (the original would crash)
  FRig.UnitOf(LConjurer)^.Mana := 255;
  while FRig.Context.Pool.CreateEntity(WAR_ENTITY_IMAGE, False) <> 0 do
    ;
  Assert.IsFalse(FRig.Commands.Spells.Summon(WAR_SUMMON_SPIDER));
end;

procedure TTestWarCommandFamilies.DovrebbeMettereGliEvocatoriNelloStatoDiPioggiaENube;
var
  LConjurer: Integer;
  LWarlock: Integer;
  LCleric: Integer;
  LCast: PWarStateCast;
begin
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 10, 10);
  LWarlock := FRig.AddDude(WAR_UNIT_WARLOCK, 12, 10);
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 14, 10);
  FRig.Select([LConjurer, LCleric]);
  Assert.IsTrue(FRig.Commands.Spells.RainOfFire(FRig.TilePoint(30, 30)));
  FRig.Tick;
  LCast := PWarStateCast(FRig.Machine.FindState(LConjurer, WAR_STATE_CAST));
  Assert.IsNotNull(LCast);
  Assert.AreEqual<Integer>(WAR_SPELL_RAIN_OF_FIRE, LCast^.SpellType);
  Assert.AreEqual(0, Integer(LCast^.TargetEntityId));
  Assert.IsFalse(FRig.Machine.Contains(LCleric, WAR_STATE_CAST), 'un chierico non fa piovere fuoco');
  FRig.Select([LWarlock]);
  Assert.IsTrue(FRig.Commands.Spells.PoisonCloud(FRig.TilePoint(30, 30)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_SPELL_POISON_CLOUD,
    PWarStateCast(FRig.Machine.FindState(LWarlock, WAR_STATE_CAST))^.SpellType);
  FRig.Select([LCleric]);
  Assert.IsFalse(FRig.Commands.Spells.PoisonCloud(FRig.TilePoint(30, 30)));
end;

procedure TTestWarCommandFamilies.DovrebbeGuarireSoloUnitaMobiliEMaiSeStessi;
var
  LCleric: Integer;
  LOther: Integer;
  LFarm: Integer;
  LCast: PWarStateCast;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  LOther := FRig.AddDude(WAR_UNIT_CLERIC, 12, 10);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  FRig.Select([LCleric, LOther]);
  Assert.IsFalse(FRig.Commands.Spells.Healing(LFarm, FRig.Center(LFarm)), 'un edificio non si guarisce');
  Assert.IsFalse(FRig.Commands.Spells.Healing(0, FRig.TilePoint(30, 30)));
  Assert.IsTrue(FRig.Commands.Spells.Healing(LCleric, FRig.Center(LCleric)));
  FRig.Tick;
  Assert.IsFalse(FRig.Machine.Contains(LCleric, WAR_STATE_CAST), 'non guarisce se stesso');
  LCast := PWarStateCast(FRig.Machine.FindState(LOther, WAR_STATE_CAST));
  Assert.IsNotNull(LCast);
  Assert.AreEqual<Integer>(WAR_SPELL_HEALING, LCast^.SpellType);
  Assert.AreEqual(Integer(FRig.IdOf(LCleric)), Integer(LCast^.TargetEntityId));
end;

procedure TTestWarCommandFamilies.DovrebbeLanciareInvisibilitaEArmaturaSuUnaUnitaMobile;
var
  LCleric: Integer;
  LNecrolyte: Integer;
  LFarm: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  LNecrolyte := FRig.AddDude(WAR_UNIT_NECROLYTE, 12, 10);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  FRig.Select([LCleric]);
  Assert.IsFalse(FRig.Commands.Spells.Invisibility(LFarm, FRig.Center(LFarm)));
  // the caster can make itself invisible (only the healing is not for oneself)
  Assert.IsTrue(FRig.Commands.Spells.Invisibility(LCleric, FRig.Center(LCleric)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_SPELL_INVISIBILITY,
    PWarStateCast(FRig.Machine.FindState(LCleric, WAR_STATE_CAST))^.SpellType);
  FRig.Select([LNecrolyte]);
  Assert.IsFalse(FRig.Commands.Spells.UnholyArmor(LFarm, FRig.Center(LFarm)));
  Assert.IsTrue(FRig.Commands.Spells.UnholyArmor(LCleric, FRig.Center(LCleric)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_SPELL_UNHOLY_ARMOR,
    PWarStateCast(FRig.Machine.FindState(LNecrolyte, WAR_STATE_CAST))^.SpellType);
end;

procedure TTestWarCommandFamilies.DovrebbeScegliereLaVistaDellaRazzaDiChiLancia;
var
  LCleric: Integer;
  LNecrolyte: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  LNecrolyte := FRig.AddDude(WAR_UNIT_NECROLYTE, 12, 10);
  FRig.Select([LCleric, LNecrolyte]);
  Assert.IsTrue(FRig.Commands.Spells.Sight(FRig.TilePoint(40, 40)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_SPELL_FAR_SIGHT, PWarStateCast(FRig.Machine.FindState(LCleric, WAR_STATE_CAST))^.SpellType);
  Assert.AreEqual<Integer>(WAR_SPELL_DARK_VISION,
    PWarStateCast(FRig.Machine.FindState(LNecrolyte, WAR_STATE_CAST))^.SpellType);
end;

procedure TTestWarCommandFamilies.DovrebbeMettereIChiericiNelloStatoDiResurrezione;
var
  LNecrolyte: Integer;
  LBuilding: Integer;
begin
  LNecrolyte := FRig.AddDude(WAR_UNIT_NECROLYTE, 12, 10);
  LBuilding := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  FRig.Select([LBuilding, LNecrolyte]);
  Assert.IsTrue(FRig.Commands.Spells.RaiseDead(FRig.TilePoint(14, 10)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_SPELL_RAISE_DEAD,
    PWarStateCast(FRig.Machine.FindState(LNecrolyte, WAR_STATE_CAST))^.SpellType);
end;

procedure TTestWarCommandFamilies.DovrebbeDareGliOrdiniDelComputerAlleSueUnita;
var
  LGrunt: Integer;
  LFootman: Integer;
begin
  LGrunt := FRig.AddDude(WAR_UNIT_GRUNT, 40, 40, 1);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.AiSelection.Assign([FRig.IdOf(LGrunt), FRig.IdOf(LFootman)]);
  Assert.AreEqual(1, FRig.AiCommands.Commander.Player);
  Assert.AreEqual<Integer>(WAR_CAUSE_AI_ORDER, FRig.AiCommands.Commander.Cause);
  Assert.AreEqual<Integer>(WAR_INTERRUPT_AI_ORDER, FRig.AiCommands.Commander.Interrupt);
  Assert.AreEqual<Integer>(WAR_INTERRUPT_PLAYER_ORDER, FRig.Commands.Commander.Interrupt);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.AiCommands.Execute(WAR_COMMAND_MOVE, FRig.TilePoint(30, 30)));
  // the request of the computer waits with its own cause
  Assert.AreEqual<Integer>(WAR_CAUSE_AI_ORDER, FRig.Entity(LGrunt)^.StateMachine.Pending.Cause);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(LGrunt));
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFootman), 'le unita'' del giocatore non sono sue');
  Assert.AreEqual(0, FRig.Context.Selection.Count, 'la selezione del giocatore non c''entra');
end;

{ TTestWarCommands }

procedure TTestWarCommands.Setup;
begin
  FRig := TCommandRig.Create;
end;

procedure TTestWarCommands.TearDown;
begin
  FRig.Free;
end;

function TTestWarCommands.Golden: TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TWarRealData.GoldenPath('model.commands.tables.golden.txt'));
end;

procedure TTestWarCommands.DovrebbeAvereLeTabelleDeiComandiDelC;
var
  LGolden: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LUnit: Integer;
  LBuilding: Integer;
  LCounts: array['A'..'Z'] of Integer;
  LKey: Char;
begin
  for LKey := 'A' to 'Z' do
    LCounts[LKey] := 0;
  LGolden := Golden;
  try
    for LLine in LGolden do
    begin
      if (LLine = '') or (LLine[1] = '#') then
        Continue;
      LParts := LLine.Split([' ']);
      Inc(LCounts[LLine[1]]);
      case LLine[1] of
        'T':
          begin
            Assert.IsTrue(TWarCommands.TrainOf(StrToInt(LParts[1]), LUnit, LBuilding), LLine);
            Assert.AreEqual(StrToInt(LParts[2]), LUnit, LLine);
            Assert.AreEqual(StrToInt(LParts[3]), LBuilding, LLine);
          end;
        'U':
          Assert.AreEqual(StrToInt(LParts[2]), TWarCommands.UpgradeOf(StrToInt(LParts[1])), LLine);
        'B':
          Assert.AreEqual(StrToInt(LParts[2]), TWarCommands.BuildingOf(StrToInt(LParts[1])), LLine);
        'S':
          // the spell of a spell command is the command less the first spell command
          Assert.AreEqual(StrToInt(LParts[2]), StrToInt(LParts[1]) - WAR_COMMAND_SPELL_HEALING, LLine);
        'K':
          begin
            Assert.AreEqual(StrToInt(LParts[1]), WAR_ROAD_GOLD_COST);
            Assert.AreEqual(StrToInt(LParts[2]), WAR_ROAD_WOOD_COST);
            Assert.AreEqual(StrToInt(LParts[3]), WAR_MODEL_MAX_SELECTED);
            Assert.AreEqual(StrToInt(LParts[4]), WAR_MODEL_SELECTION_GROUPS);
            Assert.AreEqual(StrToInt(LParts[5]), WAR_MODEL_POISON_CLOUD_DAMAGE);
            Assert.AreEqual(StrToInt(LParts[6]), WAR_SOUND_NORMAL_SPELL);
            Assert.AreEqual(StrToInt(LParts[7]), WAR_COMMAND_CANCEL);
          end;
        'C':
          begin
            Assert.AreEqual(StrToInt(LParts[1]), WAR_COMMAND_NONE);
            Assert.AreEqual(StrToInt(LParts[2]), WAR_COMMAND_MOVE);
            Assert.AreEqual(StrToInt(LParts[3]), WAR_COMMAND_STOP);
            Assert.AreEqual(StrToInt(LParts[4]), WAR_COMMAND_HARVEST);
            Assert.AreEqual(StrToInt(LParts[5]), WAR_COMMAND_DELIVER);
            Assert.AreEqual(StrToInt(LParts[6]), WAR_COMMAND_REPAIR);
            Assert.AreEqual(StrToInt(LParts[7]), WAR_COMMAND_ATTACK);
            Assert.AreEqual(StrToInt(LParts[8]), WAR_COMMAND_BUILD_BASIC);
            Assert.AreEqual(StrToInt(LParts[9]), WAR_COMMAND_BUILD_ADVANCED);
            Assert.AreEqual(StrToInt(LParts[10]), WAR_COMMAND_BUILD_ROAD);
            Assert.AreEqual(StrToInt(LParts[11]), WAR_COMMAND_BUILD_WALL);
          end;
      end;
    end;
  finally
    LGolden.Free;
  end;
  Assert.AreEqual(14, LCounts['T']);
  Assert.AreEqual(20, LCounts['U']);
  Assert.AreEqual(16, LCounts['B']);
  Assert.AreEqual(12, LCounts['S']);
  Assert.AreEqual(1, LCounts['K']);
  Assert.AreEqual(1, LCounts['C']);
  Assert.IsFalse(TWarCommands.TrainOf(WAR_COMMAND_MOVE, LUnit, LBuilding));
  Assert.AreEqual(-1, TWarCommands.UpgradeOf(WAR_COMMAND_MOVE));
  Assert.AreEqual(-1, TWarCommands.BuildingOf(WAR_COMMAND_MOVE));
end;

procedure TTestWarCommands.DovrebbeNonEseguireIMenuDegliEdificiNeNessunComando;
begin
  Assert.AreEqual<TWarCommandOutcome>(wcoNotExecuted, FRig.Commands.Execute(WAR_COMMAND_NONE));
  Assert.AreEqual<TWarCommandOutcome>(wcoNotExecuted, FRig.Commands.Execute(WAR_COMMAND_BUILD_BASIC));
  Assert.AreEqual<TWarCommandOutcome>(wcoNotExecuted, FRig.Commands.Execute(WAR_COMMAND_BUILD_ADVANCED));
end;

procedure TTestWarCommands.DovrebbeSollevarePerUnComandoCheNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(WAR_COMMAND_COUNT);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(-1);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.RegisterHandler(WAR_COMMAND_COUNT, nil);
    end, EWarException);
  FRig.Commands.RegisterHandler(WAR_COMMAND_STOP, nil);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(WAR_COMMAND_STOP);
    end, EWarException, 'un tipo senza chi lo esegue');
end;

procedure TTestWarCommands.DovrebbeLasciarSostituireChiEsegueUnComando;
var
  LSpy: TSpyHandler;
begin
  LSpy := TSpyHandler.Create;
  try
    FRig.Commands.RegisterHandler(WAR_COMMAND_STOP, LSpy.Handle);
    Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_STOP));
    Assert.AreEqual(1, LSpy.Calls);
  finally
    LSpy.Free;
  end;
end;

procedure TTestWarCommands.DovrebbeMuovereEFermareConIComandi;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Select([LFootman]);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_MOVE, FRig.TilePoint(30, 30)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(LFootman));
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_STOP));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFootman));
end;

procedure TTestWarCommands.DovrebbeRaccogliereDallaMinieraSottoIlPunto;
var
  LPeasant: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(30, 10, 500);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  FRig.Select([LPeasant]);
  FRig.Commands.Execute(WAR_COMMAND_HARVEST, FRig.Center(LMine));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_GOLD));
end;

procedure TTestWarCommands.DovrebbeMuovereVersoUnaMinieraSconosciuta;
var
  LRig: TCommandRig;
  LPeasant: Integer;
  LMine: Integer;
begin
  LRig := TCommandRig.Create(1, True);
  try
    LMine := LRig.AddMine(30, 10, 500);
    LPeasant := LRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
    LRig.Select([LPeasant]);
    LRig.Commands.Execute(WAR_COMMAND_HARVEST, LRig.Center(LMine));
    LRig.Tick;
    Assert.AreEqual<Integer>(WAR_STATE_MOVE, LRig.ActiveType(LPeasant));
    Assert.IsFalse(LRig.Machine.Contains(LPeasant, WAR_STATE_GOLD));
    // the right click does the same
    LRig.Commands.Execute(WAR_COMMAND_STOP);
    LRig.Tick;
    LRig.Commands.RightClick(LRig.Center(LMine));
    LRig.Tick;
    Assert.AreEqual<Integer>(WAR_STATE_MOVE, LRig.ActiveType(LPeasant));
  finally
    LRig.Free;
  end;
end;

procedure TTestWarCommands.DovrebbeRaccogliereDallAlberoSottoIlPunto;
var
  LPeasant: Integer;
begin
  FRig.AddTree(30, 12, 50);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  FRig.Select([LPeasant]);
  FRig.Commands.Execute(WAR_COMMAND_HARVEST, FRig.TilePoint(30, 12));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_WOOD));
end;

procedure TTestWarCommands.DovrebbeCercareUnAlberoRaggiungibileSeLaCasellaNonSiVede;
var
  LRig: TCommandRig;
  LPeasant: Integer;
  LWood: PWarStateWood;
begin
  LRig := TCommandRig.Create(1, True);
  try
    LRig.AddTree(30, 12, 50);
    LRig.AddTree(31, 12, 50);
    LPeasant := LRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
    // the tree of the click is unknown, its neighbour is seen
    LRig.Reveal(32, 12);
    Assert.IsTrue(LRig.Fog.IsTileVisible(31, 12) and LRig.Fog.IsTileUnknown(30, 12), 'la nebbia della prova');
    Assert.AreEqual(2, LRig.Forest.Trees.Count);
    Assert.AreEqual(Integer(LRig.Forest.Id), Integer(LRig.Map.EntityIdAt(30, 12)));
    LRig.Select([LPeasant]);
    LRig.Commands.Execute(WAR_COMMAND_HARVEST, LRig.TilePoint(30, 12));
    // the order waits for the next tic
    Assert.IsTrue(LRig.Machine.HasPending(LPeasant, WAR_STATE_WOOD), 'raccoglie dall''albero che si vede');
    LWood := PWarStateWood(LRig.Context.Storage.Deref(LRig.Entity(LPeasant)^.StateMachine.Pending.StateRef));
    Assert.AreEqual<Single>(LRig.TilePoint(31, 12).X, LWood^.Position.X);
  finally
    LRig.Free;
  end;
end;

procedure TTestWarCommands.DovrebbeMuovereSeNessunAlberoERaggiungibile;
var
  LRig: TCommandRig;
  LPeasant: Integer;
begin
  LRig := TCommandRig.Create(1, True);
  try
    LRig.AddTree(30, 12, 50);
    LPeasant := LRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
    LRig.Select([LPeasant]);
    LRig.Commands.Execute(WAR_COMMAND_HARVEST, LRig.TilePoint(30, 12));
    LRig.Tick;
    Assert.AreEqual<Integer>(WAR_STATE_MOVE, LRig.ActiveType(LPeasant));
    Assert.IsFalse(LRig.Machine.Contains(LPeasant, WAR_STATE_WOOD));
    // the right click wants the tile visible and the command only not unknown, but a tree in the fog is one that can be
    // reached: both harvest it
    LRig.Reveal(30, 12, wtsFog);
    LRig.Commands.Execute(WAR_COMMAND_STOP);
    LRig.Tick;
    LRig.Commands.RightClick(LRig.TilePoint(30, 12));
    Assert.IsTrue(LRig.Machine.HasPending(LPeasant, WAR_STATE_WOOD), 'clic destro: l''albero in nebbia si raggiunge');
    LRig.Commands.Execute(WAR_COMMAND_STOP);
    LRig.Tick;
    LRig.Commands.Execute(WAR_COMMAND_HARVEST, LRig.TilePoint(30, 12));
    Assert.IsTrue(LRig.Machine.HasPending(LPeasant, WAR_STATE_WOOD), 'comando: la nebbia basta');
  finally
    LRig.Free;
  end;
end;

procedure TTestWarCommands.DovrebbeNonFareNullaSeSottoIlPuntoNonCENulla;
var
  LPeasant: Integer;
  LFarm: Integer;
begin
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  FRig.Select([LPeasant]);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_HARVEST, FRig.TilePoint(40, 40)));
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_HARVEST, FRig.Center(LFarm)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LPeasant));
end;

procedure TTestWarCommands.DovrebbeConsegnareConIlComando;
var
  LPeasant: Integer;
begin
  FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, 6, 6);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 20, 10);
  FRig.UnitOf(LPeasant)^.ResourceKind := wrkGold;
  FRig.UnitOf(LPeasant)^.Amount := WAR_MODEL_MAX_CARRY;
  FRig.Select([LPeasant]);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_DELIVER));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_DELIVER));
end;

procedure TTestWarCommands.DovrebbeRiparareLEdificioSottoIlPunto;
var
  LPeasant: Integer;
  LFarm: Integer;
  LFootman: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 14);
  FRig.Select([LPeasant]);
  FRig.Commands.Execute(WAR_COMMAND_REPAIR, FRig.Center(LFarm));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_REPAIR));
  // a unit is not a building: nothing to repair
  FRig.Commands.Execute(WAR_COMMAND_STOP);
  FRig.Tick;
  FRig.Commands.Execute(WAR_COMMAND_REPAIR, FRig.Center(LFootman));
  FRig.Tick;
  Assert.IsFalse(FRig.Machine.Contains(LPeasant, WAR_STATE_REPAIR));
end;

procedure TTestWarCommands.DovrebbeNonRiparareCioCheNonSiVede;
var
  LRig: TCommandRig;
  LPeasant: Integer;
  LFarm: Integer;
begin
  LRig := TCommandRig.Create(1, True);
  try
    LFarm := LRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
    LPeasant := LRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
    LRig.Select([LPeasant]);
    LRig.Commands.Execute(WAR_COMMAND_REPAIR, LRig.TilePoint(20, 10));
    LRig.Tick;
    Assert.IsFalse(LRig.Machine.Contains(LPeasant, WAR_STATE_REPAIR));
    LRig.Reveal(20, 10, wtsFog);
    LRig.Commands.Execute(WAR_COMMAND_REPAIR, LRig.TilePoint(20, 10));
    LRig.Tick;
    Assert.IsTrue(LRig.Machine.Contains(LPeasant, WAR_STATE_REPAIR), 'in nebbia si puo''');
    Assert.AreNotEqual(0, LFarm);
  finally
    LRig.Free;
  end;
end;

procedure TTestWarCommands.DovrebbeAttaccareLUnitaSottoIlPunto;
var
  LFootman: Integer;
  LEnemy: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LEnemy := FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 30, 30, 1);
  FRig.Select([LFootman]);
  FRig.Commands.Execute(WAR_COMMAND_ATTACK, FRig.Center(LEnemy));
  FRig.Tick;
  Assert.AreEqual(Integer(FRig.IdOf(LEnemy)),
    Integer(PWarStateAttack(FRig.Machine.FindState(LFootman, WAR_STATE_ATTACK))^.TargetEntityId));
  // nothing under the point: the attack of the point
  FRig.Commands.Execute(WAR_COMMAND_ATTACK, FRig.TilePoint(50, 10));
  FRig.Tick;
  Assert.AreEqual(0, Integer(PWarStateAttack(FRig.Machine.FindState(LFootman, WAR_STATE_ATTACK))^.TargetEntityId));
end;

procedure TTestWarCommands.DovrebbeAttaccareIlPuntoSeLUnitaNonSiVede;
var
  LRig: TCommandRig;
  LFootman: Integer;
  LEnemy: Integer;
begin
  LRig := TCommandRig.Create(1, True);
  try
    LFootman := LRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
    LEnemy := LRig.AddBuilding(WAR_UNIT_FARM_ORCS, 30, 30, 1);
    LRig.Select([LFootman]);
    LRig.Commands.Execute(WAR_COMMAND_ATTACK, LRig.Center(LEnemy));
    LRig.Tick;
    Assert.AreEqual(0, Integer(PWarStateAttack(LRig.Machine.FindState(LFootman, WAR_STATE_ATTACK))^.TargetEntityId));
  finally
    LRig.Free;
  end;
end;

procedure TTestWarCommands.DovrebbeAttaccareIlMuroSottoIlPunto;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.AddWallPiece(20, 10);
  FRig.Select([LFootman]);
  FRig.Commands.Execute(WAR_COMMAND_ATTACK, FRig.TilePoint(20, 10));
  FRig.Tick;
  Assert.AreEqual(Integer(FRig.IdOf(FRig.WallSlot)),
    Integer(PWarStateAttack(FRig.Machine.FindState(LFootman, WAR_STATE_ATTACK))^.TargetEntityId));
end;

procedure TTestWarCommands.DovrebbeAttaccareIlPuntoSeIlMuroNonSiVede;
var
  LRig: TCommandRig;
  LFootman: Integer;
begin
  LRig := TCommandRig.Create(1, True);
  try
    LFootman := LRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
    LRig.AddWallPiece(20, 10);
    LRig.Reveal(20, 10, wtsFog);
    LRig.Select([LFootman]);
    LRig.Commands.Execute(WAR_COMMAND_ATTACK, LRig.TilePoint(20, 10));
    LRig.Tick;
    Assert.AreEqual(0, Integer(PWarStateAttack(LRig.Machine.FindState(LFootman, WAR_STATE_ATTACK))^.TargetEntityId));
  finally
    LRig.Free;
  end;
end;

procedure TTestWarCommands.DovrebbeAddestrareDallEdificioSelezionato;
var
  LBarracks: Integer;
begin
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 14, 10);
  FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  FRig.Select([LBarracks]);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_TRAIN_FIRST));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_TRAIN, FRig.ActiveType(LBarracks));
  Assert.AreEqual<Integer>(WAR_UNIT_FOOTMAN, PWarStateTrain(FRig.Machine.FindState(LBarracks, WAR_STATE_TRAIN))^.UnitToBuild);
end;

procedure TTestWarCommands.DovrebbeSollevareSeLEdificioNonAddestraQuellUnita;
var
  LFarm: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  FRig.Select([LFarm]);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(WAR_COMMAND_TRAIN_FIRST);
    end, EWarException);
end;

procedure TTestWarCommands.DovrebbeSollevareSenzaUnSoloEdificioSelezionato;
var
  LFootman: Integer;
  LFarm: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(WAR_COMMAND_TRAIN_FIRST);
    end, EWarException, 'nessuno');
  FRig.Select([LFootman]);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(WAR_COMMAND_UPGRADE_FIRST);
    end, EWarException, 'non un edificio');
  FRig.Select([LFarm, LFootman]);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(WAR_COMMAND_TRAIN_FIRST);
    end, EWarException, 'due');
end;

procedure TTestWarCommands.DovrebbeMigliorareDallEdificioSelezionato;
var
  LSmith: Integer;
begin
  LSmith := FRig.AddBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 14, 10);
  FRig.Select([LSmith]);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_UPGRADE_FIRST));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_UPGRADE, FRig.ActiveType(LSmith));
  Assert.AreEqual<Integer>(WAR_UPGRADE_SWORDS,
    PWarStateUpgrade(FRig.Machine.FindState(LSmith, WAR_STATE_UPGRADE))^.UpgradeToBuild);
end;

procedure TTestWarCommands.DovrebbeCostruireConIlPrimoSelezionato;
var
  LPeasant: Integer;
begin
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  FRig.Select([LPeasant]);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted,
    FRig.Commands.Execute(WAR_COMMAND_BUILD_FIRST, FRig.TilePoint(11, 10)));
  Assert.AreEqual(1, FRig.CountOfType(WAR_UNIT_FARM_HUMANS));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_REPAIR), 'il contadino va al cantiere');
end;

procedure TTestWarCommands.DovrebbeSuonareLAnnullaSeNonSiPuoCostruireLi;
var
  LPeasant: Integer;
  LFarm: Integer;
begin
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  FRig.Select([LPeasant]);
  FRig.Commands.Execute(WAR_COMMAND_BUILD_FIRST, FRig.Center(LFarm));
  Assert.AreEqual(1, FRig.CountOfType(WAR_UNIT_FARM_HUMANS));
  Assert.AreEqual(WAR_SOUND_UI_CANCEL, FRig.Observer.LastSound);
end;

procedure TTestWarCommands.DovrebbeSollevareSeNessunoESelezionatoPerCostruire;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(WAR_COMMAND_BUILD_FIRST, FRig.TilePoint(11, 10));
    end, EWarException);
end;

procedure TTestWarCommands.DovrebbeCostruireMuraEStradeDalMunicipio;
var
  LTownHall: Integer;
  LGold: Integer;
begin
  LTownHall := FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, 6, 6);
  FRig.Select([LTownHall]);
  LGold := FRig.Context.Players[0]^.Gold;
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_BUILD_WALL, FRig.TilePoint(20, 20)));
  Assert.AreEqual(1, FRig.Context.Walls.Count);
  Assert.AreEqual(LGold - WAR_WALL_GOLD_COST, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_BUILD_ROAD, FRig.TilePoint(22, 20)));
  FRig.Commands.Execute(WAR_COMMAND_BUILD_ROAD, FRig.TilePoint(23, 20));
  Assert.AreEqual(2, FRig.Context.Roads.Count);
  Assert.AreEqual(LGold - WAR_WALL_GOLD_COST - 2 * WAR_ROAD_GOLD_COST, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual(22, FRig.Context.Roads.Pieces[0].TileX);
  Assert.AreEqual(0, Integer(FRig.Context.Roads.Pieces[0].Player), 'il pezzo e'' del giocatore 0');
  Assert.AreNotEqual(Integer(FRig.Context.Roads.Pieces[0].PieceType), Integer(FRig.Context.Roads.Pieces[1].PieceType),
    'il tipo dipende dai vicini');
  Assert.AreEqual(WAR_SOUND_BUILD_ROAD, FRig.Observer.LastSound);
end;

procedure TTestWarCommands.DovrebbeSollevareSeIlSelezionatoNonEIlMunicipio;
var
  LFarm: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  FRig.Select([LFarm]);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(WAR_COMMAND_BUILD_WALL, FRig.TilePoint(30, 30));
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.Execute(WAR_COMMAND_BUILD_ROAD, FRig.TilePoint(30, 30));
    end, EWarException);
end;

procedure TTestWarCommands.DovrebbeNonCostruireLaStradaSuUnaCasellaOccupataOSenzaOro;
var
  LFarm: Integer;
  LFlashes: Cardinal;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  LFlashes := FRig.Observer.FlashCount;
  Assert.IsFalse(FRig.Commands.Construction.PlaceRoad(0, 20, 10));
  Assert.AreEqual(LFlashes + 1, FRig.Observer.FlashCount);
  Assert.AreEqual(wsmCantBuildThere, FRig.Observer.LastMessage);
  Assert.AreEqual(WAR_SOUND_UI_CANCEL, FRig.Observer.LastSound);
  FRig.Context.Players[0]^.Gold := 10;
  Assert.IsFalse(FRig.Commands.Construction.PlaceRoad(0, 40, 40));
  Assert.AreEqual(0, FRig.Context.Roads.Count);
  Assert.AreNotEqual(0, LFarm);
end;

procedure TTestWarCommands.DovrebbeEvocareELanciareOgniIncantesimoConIComandi;
var
  LConjurer: Integer;
  LCleric: Integer;
  LFootman: Integer;
  LCommand: Integer;

  function SpellOf(ASlot: Integer): Integer;
  var
    LCast: PWarStateCast;
  begin
    FRig.Tick;
    LCast := PWarStateCast(FRig.Machine.FindState(ASlot, WAR_STATE_CAST));
    if Assigned(LCast) then
      Result := LCast^.SpellType
    else
      Result := -1;
  end;

begin
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 10, 10);
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 14);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 14, 14);
  FRig.Context.InterruptibleCasts := True;
  FRig.Select([LConjurer, LCleric]);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_SUMMON_SCORPION));
  Assert.AreEqual(1, FRig.CountOfType(WAR_UNIT_SCORPION));
  FRig.UnitOf(LConjurer)^.Mana := 255;
  FRig.Commands.Execute(WAR_COMMAND_SUMMON_WATER_ELEMENTAL);
  Assert.AreEqual(1, FRig.CountOfType(WAR_UNIT_WATER_ELEMENTAL));
  FRig.Commands.Execute(WAR_COMMAND_SPELL_RAIN_OF_FIRE, FRig.TilePoint(30, 30));
  Assert.AreEqual<Integer>(WAR_SPELL_RAIN_OF_FIRE, SpellOf(LConjurer));
  FRig.Commands.Execute(WAR_COMMAND_SPELL_POISON_CLOUD, FRig.TilePoint(30, 30));
  Assert.AreEqual<Integer>(WAR_SPELL_POISON_CLOUD, SpellOf(LConjurer));
  for LCommand := WAR_COMMAND_SPELL_HEALING to WAR_COMMAND_SPELL_UNHOLY_ARMOR do
    if (LCommand <> WAR_COMMAND_SPELL_RAIN_OF_FIRE) and (LCommand <> WAR_COMMAND_SPELL_POISON_CLOUD) and
      (LCommand <> WAR_COMMAND_SPELL_DARK_VISION) then
    begin
      Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(LCommand, FRig.Center(LFootman)));
      Assert.AreEqual(LCommand - WAR_COMMAND_SPELL_HEALING, SpellOf(LCleric), Format('comando %d', [LCommand]));
    end;
  // the command of the dark vision is the sight of the race of the caster too
  FRig.Commands.Execute(WAR_COMMAND_SPELL_DARK_VISION, FRig.TilePoint(30, 30));
  Assert.AreEqual<Integer>(WAR_SPELL_FAR_SIGHT, SpellOf(LCleric));
end;

procedure TTestWarCommands.DovrebbeAnnullareCioCheFannoGliEdificiSelezionati;
var
  LBarracks: Integer;
  LFootman: Integer;
  LGold: Integer;
begin
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_HUMANS, 14, 10);
  FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 20);
  LGold := FRig.Context.Players[0]^.Gold;
  FRig.Select([LBarracks]);
  FRig.Commands.Execute(WAR_COMMAND_TRAIN_FIRST);
  FRig.Tick;
  Assert.IsTrue(FRig.Context.Players[0]^.Gold < LGold);
  FRig.Select([LFootman, LBarracks]);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.Commands.Execute(WAR_COMMAND_CANCEL));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LBarracks));
  Assert.AreEqual(LGold, FRig.Context.Players[0]^.Gold, 'l''oro torna');
  Assert.IsFalse(FRig.Commands.Cancel, 'nulla da annullare');
end;

procedure TTestWarCommands.DovrebbeNonFareNullaConIlClicDestroSenzaSelezione;
begin
  Assert.IsFalse(FRig.Commands.RightClick(FRig.TilePoint(30, 30)));
end;

procedure TTestWarCommands.DovrebbeMuovereConIlClicDestroSulVuoto;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Select([LFootman]);
  Assert.IsTrue(FRig.Commands.RightClick(FRig.TilePoint(30, 30)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(LFootman));
  Assert.IsTrue(FRig.Commands.RightClick(FRig.TilePoint(30, 40), True));
  Assert.AreEqual(3, PWarStateMove(FRig.Machine.FindState(LFootman, WAR_STATE_MOVE))^.WaypointsCount);
end;

procedure TTestWarCommands.DovrebbeRaccogliereConIlClicDestroSuMinieraEAlbero;
var
  LPeasant: Integer;
  LMine: Integer;
begin
  LMine := FRig.AddMine(30, 10, 500);
  FRig.AddTree(30, 20, 50);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  FRig.Select([LPeasant]);
  FRig.Commands.RightClick(FRig.Center(LMine));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_GOLD));
  FRig.Commands.RightClick(FRig.TilePoint(30, 20));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_WOOD));
end;

procedure TTestWarCommands.DovrebbeConsegnareConIlClicDestroSulProprioMunicipio;
var
  LPeasant: Integer;
  LTownHall: Integer;
begin
  LTownHall := FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, 6, 6);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 20, 10);
  FRig.UnitOf(LPeasant)^.ResourceKind := wrkWood;
  FRig.UnitOf(LPeasant)^.Amount := WAR_MODEL_MAX_CARRY;
  FRig.Select([LPeasant]);
  FRig.Commands.RightClick(FRig.Center(LTownHall));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LPeasant, WAR_STATE_DELIVER));
end;

procedure TTestWarCommands.DovrebbeAttaccareConIlClicDestroSulMunicipioNemico;
var
  LFootman: Integer;
  LTownHall: Integer;
begin
  LTownHall := FRig.AddBuilding(WAR_UNIT_TOWNHALL_ORCS, 40, 40, 1);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 20, 10);
  FRig.Select([LFootman]);
  FRig.Commands.RightClick(FRig.Center(LTownHall));
  FRig.Tick;
  Assert.AreEqual(Integer(FRig.IdOf(LTownHall)),
    Integer(PWarStateAttack(FRig.Machine.FindState(LFootman, WAR_STATE_ATTACK))^.TargetEntityId));
end;

procedure TTestWarCommands.DovrebbeMuovereConIlClicDestroSuUnMunicipioSconosciuto;
var
  LRig: TCommandRig;
  LFootman: Integer;
  LTownHall: Integer;
begin
  LRig := TCommandRig.Create(1, True);
  try
    LTownHall := LRig.AddBuilding(WAR_UNIT_TOWNHALL_ORCS, 40, 40, 1);
    LFootman := LRig.AddDude(WAR_UNIT_FOOTMAN, 20, 10);
    LRig.Select([LFootman]);
    LRig.Commands.RightClick(LRig.Center(LTownHall));
    LRig.Tick;
    Assert.AreEqual<Integer>(WAR_STATE_MOVE, LRig.ActiveType(LFootman));
    Assert.IsFalse(LRig.Machine.IsAttacking(LFootman));
  finally
    LRig.Free;
  end;
end;

procedure TTestWarCommands.DovrebbeMuovereConIlClicDestroSulMuro;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.AddWallPiece(20, 10);
  FRig.Select([LFootman]);
  FRig.Commands.RightClick(FRig.TilePoint(20, 10));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(LFootman));
  Assert.IsFalse(FRig.Machine.IsAttacking(LFootman));
end;

procedure TTestWarCommands.DovrebbeAttaccareIlNemicoESeguireLAmicoConIlClicDestro;
var
  LFootman: Integer;
  LFriend: Integer;
  LEnemy: Integer;
  LCritter: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LFriend := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 10);
  LEnemy := FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 40, 40, 1);
  LCritter := FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 40, 10, 4);
  FRig.Select([LFootman]);
  FRig.Commands.RightClick(FRig.Center(LEnemy));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.IsAttacking(LFootman));
  FRig.Commands.RightClick(FRig.Center(LFriend));
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.Contains(LFootman, WAR_STATE_FOLLOW));
  Assert.IsFalse(FRig.Machine.IsAttacking(LFootman));
  // what belongs to the neutral player is not an enemy: it is followed
  FRig.Commands.RightClick(FRig.Center(LCritter));
  FRig.Tick;
  Assert.AreEqual(Integer(FRig.IdOf(LCritter)),
    Integer(PWarStateFollow(FRig.Machine.FindState(LFootman, WAR_STATE_FOLLOW))^.TargetEntityId));
end;

procedure TTestWarCommands.DovrebbeNonTrovareNessunoSenzaLaMappa;
var
  LCommands: TWarCommands;
  LFootman: Integer;
  LEnemy: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LEnemy := FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 40, 40, 1);
  FRig.AddTree(30, 12, 50);
  LCommands := TWarModelFactory.CreateCommands(FRig.World);
  try
    FRig.Select([LFootman]);
    LCommands.Execute(WAR_COMMAND_ATTACK, FRig.Center(LEnemy));
    FRig.Tick;
    Assert.AreEqual(0, Integer(PWarStateAttack(FRig.Machine.FindState(LFootman, WAR_STATE_ATTACK))^.TargetEntityId));
    Assert.IsTrue(LCommands.RightClick(FRig.Center(LEnemy)));
    FRig.Tick;
    Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(LFootman));
    Assert.IsTrue(LCommands.Selecting.IsSelectable(LFootman));
  finally
    LCommands.Free;
  end;
end;

procedure TTestWarCommands.DovrebbeRisponderePerLaNebbiaDallaMappaDeiComandi;
var
  LRig: TCommandRig;
  LOpen: IWarCommandMap;
begin
  LRig := TCommandRig.Create(1, True);
  try
    Assert.IsTrue(LRig.Map.IsTileUnknown(5, 5));
    Assert.IsFalse(LRig.Map.IsTileVisible(5, 5));
    Assert.IsFalse(LRig.Map.IsTileFog(5, 5));
    Assert.IsTrue(LRig.Map.IsAreaUnknown(5, 5, 2, 2));
    Assert.IsFalse(LRig.Map.IsAreaPartiallyVisible(5, 5, 2, 2));
    LRig.Reveal(6, 6);
    LRig.Reveal(5, 5, wtsFog);
    Assert.IsTrue(LRig.Map.IsTileFog(5, 5));
    Assert.IsFalse(LRig.Map.IsAreaUnknown(5, 5, 2, 2));
    Assert.IsTrue(LRig.Map.IsAreaPartiallyVisible(5, 5, 2, 2));
    Assert.AreEqual(0, Integer(LRig.Map.EntityIdAt(-1, 5)));
    Assert.AreEqual(0, Integer(LRig.Map.EntityIdAt(5, 64)));
    // without a fog everything is seen
    LOpen := TWarGridCommandMap.Create(LRig.Grid);
    Assert.IsTrue(LOpen.IsTileVisible(5, 5));
    Assert.IsFalse(LOpen.IsTileFog(5, 5));
    Assert.IsFalse(LOpen.IsTileUnknown(5, 5));
    Assert.IsFalse(LOpen.IsAreaUnknown(5, 5, 2, 2));
    Assert.IsTrue(LOpen.IsAreaPartiallyVisible(5, 5, 2, 2));
  finally
    LRig.Free;
  end;
end;

{ TTestWarWallAttack }

procedure TTestWarWallAttack.Setup;
begin
  FRig := TCommandRig.Create;
end;

procedure TTestWarWallAttack.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarWallAttack.DovrebbeAbbattereUnPezzoDiMuroACorpoACorpo;
var
  LFootman: Integer;
  LPiece: Integer;
begin
  LPiece := FRig.AddWallPiece(12, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 11, 10);
  FRig.Select([LFootman]);
  Assert.IsTrue(FRig.Commands.Attack.Attack(FRig.WallSlot, FRig.TilePoint(12, 10)));
  Assert.IsTrue(FRig.RunUntil(
    function: Boolean
    begin
      Result := FRig.Context.Walls[LPiece]^.Hp = 0;
    end, 120));
  // the piece is down: the attack ends and the tile is free again
  Assert.IsTrue(FRig.RunUntil(
    function: Boolean
    begin
      Result := FRig.ActiveType(LFootman) = WAR_STATE_IDLE;
    end, 10));
  Assert.IsTrue(FRig.Grid.IsEmpty(12, 10));
  Assert.IsTrue(FRig.Observer.AttackSounds > 0);
end;

procedure TTestWarWallAttack.DovrebbeAvvicinarsiAlMuroFuoriPortata;
var
  LFootman: Integer;
  LFollow: PWarStateFollow;
begin
  FRig.AddWallPiece(30, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Select([LFootman]);
  FRig.Commands.Attack.Attack(FRig.WallSlot, FRig.TilePoint(30, 10));
  FRig.Tick(2);
  LFollow := PWarStateFollow(FRig.Machine.FindState(LFootman, WAR_STATE_FOLLOW));
  Assert.IsNotNull(LFollow);
  Assert.AreEqual(0, Integer(LFollow^.TargetEntityId), 'segue il punto, non l''entita'' del muro');
  Assert.AreEqual<Single>(FRig.TilePoint(30, 10).X, LFollow^.TargetPosition.X);
end;

procedure TTestWarWallAttack.DovrebbeColpireIlMuroConUnaFreccia;
var
  LArcher: Integer;
  LPiece: Integer;
  LSeen: Boolean;
begin
  LPiece := FRig.AddWallPiece(14, 10);
  LArcher := FRig.AddDude(WAR_UNIT_ARCHER, 11, 10);
  FRig.Select([LArcher]);
  FRig.Commands.Attack.Attack(FRig.WallSlot, FRig.TilePoint(14, 10));
  LSeen := FRig.RunUntil(
    function: Boolean
    begin
      Result := FRig.Context.Pool.OfType[WAR_ENTITY_PROJECTILE].Count > 0;
    end, 20);
  Assert.IsTrue(LSeen, 'una freccia verso il muro');
  Assert.AreEqual(Integer(FRig.IdOf(FRig.WallSlot)),
    Integer(FRig.Entity(FRig.Context.Pool.OfType[WAR_ENTITY_PROJECTILE][0])^.Projectile.TargetEntityId));
  Assert.AreEqual<Single>(FRig.TilePoint(14, 10).X,
    FRig.Entity(FRig.Context.Pool.OfType[WAR_ENTITY_PROJECTILE][0])^.Projectile.Target.X);
  Assert.IsTrue(FRig.RunUntil(
    function: Boolean
    begin
      Result := FRig.Context.Walls[LPiece]^.Hp < WAR_WALL_MAX_HP;
    end, 60));
end;

procedure TTestWarWallAttack.DovrebbeFermareIlMagoSenzaManaDavantiAlMuro;
var
  LConjurer: Integer;
  LPiece: Integer;
begin
  LPiece := FRig.AddWallPiece(13, 10);
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 11, 10);
  FRig.UnitOf(LConjurer)^.Mana := 3;
  FRig.UnitOf(LConjurer)^.ManaTime := 1000;
  FRig.Select([LConjurer]);
  FRig.Commands.Attack.Attack(FRig.WallSlot, FRig.TilePoint(13, 10));
  // one shot of 2 mana, then no mana: idle
  Assert.IsTrue(FRig.RunUntil(
    function: Boolean
    begin
      Result := (FRig.UnitOf(LConjurer)^.Mana = 1) and (FRig.ActiveType(LConjurer) = WAR_STATE_IDLE);
    end, 30));
  Assert.IsTrue(FRig.Context.Walls[LPiece]^.Hp <= WAR_WALL_MAX_HP);
end;

procedure TTestWarWallAttack.DovrebbeFerireIPezziViciniConLaCatapulta;
var
  LCatapult: Integer;
  LNear: Integer;
  LFar: Integer;
begin
  LNear := FRig.AddWallPiece(20, 10);
  LFar := FRig.AddWallPiece(30, 10);
  LCatapult := FRig.AddDude(WAR_UNIT_CATAPULT_HUMANS, 5, 5);
  // a stone that lands next to the first piece: the splash of 2 tiles hurts it, not the far one
  FRig.Context.Combat.CreateProjectile(WAR_PROJECTILE_CATAPULT, FRig.IdOf(LCatapult), 0, FRig.TilePoint(19, 10),
    FRig.TilePoint(21, 10));
  FRig.Run(2);
  Assert.IsTrue(FRig.Context.Walls[LNear]^.Hp < WAR_WALL_MAX_HP, 'la catapulta non manca mai');
  Assert.AreEqual(WAR_WALL_MAX_HP, FRig.Context.Walls[LFar]^.Hp);
  Assert.AreEqual(1, FRig.CountEntities(WAR_ENTITY_ANIMATION));
end;

procedure TTestWarWallAttack.DovrebbeFerireIPezziDiMuroConLaPioggiaDiFuoco;
var
  LNear: Integer;
  LFar: Integer;
begin
  LNear := FRig.AddWallPiece(20, 10);
  LFar := FRig.AddWallPiece(23, 10);
  FRig.Context.Combat.CreateProjectile(WAR_PROJECTILE_RAIN_OF_FIRE, 0, 0, FRig.TilePoint(20, 8), FRig.TilePoint(20, 10));
  FRig.Run(2);
  Assert.AreEqual(WAR_WALL_MAX_HP - WAR_MODEL_RAIN_OF_FIRE_DAMAGE, FRig.Context.Walls[LNear]^.Hp);
  Assert.AreEqual(WAR_WALL_MAX_HP, FRig.Context.Walls[LFar]^.Hp, 'la pioggia arriva a una casella');
end;

procedure TTestWarWallAttack.DovrebbeColpireSenzaFineDoveNonCEUnPezzo;
var
  LFootman: Integer;
  LPiece: Integer;
begin
  LPiece := FRig.AddWallPiece(20, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 11, 10);
  FRig.Select([LFootman]);
  // the target is the wall, the tile has no piece: the unit swings for ever (as in the original)
  FRig.Commands.Attack.Attack(FRig.WallSlot, FRig.TilePoint(12, 10));
  FRig.Run(10);
  Assert.AreEqual<Integer>(WAR_STATE_ATTACK, FRig.ActiveType(LFootman));
  Assert.AreEqual(WAR_WALL_MAX_HP, FRig.Context.Walls[LPiece]^.Hp);
end;

procedure TTestWarWallAttack.DovrebbeNonFerireLeMuraSenzaLEntitaDelMuro;
var
  LPiece: Integer;
begin
  // pieces in the walls of the context, but no entity of the wall in the map: the splashes look for the entity
  LPiece := FRig.Context.Walls.Add(20, 10, 0);
  FRig.Context.Walls[LPiece]^.Hp := WAR_WALL_MAX_HP;
  FRig.Context.Combat.CreateProjectile(WAR_PROJECTILE_RAIN_OF_FIRE, 0, 0, FRig.TilePoint(20, 8), FRig.TilePoint(20, 10));
  FRig.Run(2);
  Assert.AreEqual(WAR_WALL_MAX_HP, FRig.Context.Walls[LPiece]^.Hp);
end;

procedure TTestWarWallAttack.DovrebbeMostrareLImmagineDelCantiereMentreSiCostruisce;
var
  LPeasant: Integer;
  LFarm: Integer;
begin
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  FRig.Select([LPeasant]);
  FRig.Commands.Execute(WAR_COMMAND_BUILD_FIRST, FRig.TilePoint(11, 10));
  FRig.Tick(2);
  LFarm := FRig.Context.Pool.UnitsOfType[WAR_UNIT_FARM_HUMANS][0];
  Assert.AreEqual(WAR_BUILDING_CONSTRUCTION_RESOURCES[WAR_UNIT_FARM_HUMANS - WAR_BUILDING_FIRST_TYPE],
    FRig.Entity(LFarm)^.SpriteResource);
  FRig.Context.HurryUp := True;
  Assert.IsTrue(FRig.RunUntil(
    function: Boolean
    begin
      Result := FRig.ActiveType(LFarm) = WAR_STATE_IDLE;
    end, 60));
  Assert.AreEqual(TWarUnitSprites.DefaultResource(WAR_UNIT_FARM_HUMANS), FRig.Entity(LFarm)^.SpriteResource);
end;

procedure TTestWarWallAttack.DovrebbeFareUnTicInteroConTick;
var
  LCleric: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  FRig.UnitOf(LCleric)^.Mana := 10;
  FRig.UnitOf(LCleric)^.ManaTime := 0;
  FRig.World.Tick(0.5);
  Assert.AreEqual(11, FRig.UnitOf(LCleric)^.Mana, 'Tick comprende il mana');
  FRig.UnitOf(LCleric)^.ManaTime := 0;
  // UpdateAfterStates is the tic without the animations, the mana and the spells
  FRig.World.AdvanceClock(0.5);
  FRig.World.Update;
  FRig.World.UpdateAfterStates;
  Assert.AreEqual(11, FRig.UnitOf(LCleric)^.Mana);
end;

procedure TTestWarWallAttack.DovrebbeAddestrarePerOrdineDelComputer;
var
  LBarracks: Integer;
begin
  LBarracks := FRig.AddBuilding(WAR_UNIT_BARRACKS_ORCS, 40, 40, 1);
  FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 46, 40, 1);
  FRig.AiSelection.Assign([FRig.IdOf(LBarracks)]);
  Assert.AreEqual<TWarCommandOutcome>(wcoExecuted, FRig.AiCommands.Execute(WAR_COMMAND_TRAIN_FIRST + 1));
  Assert.AreEqual<Integer>(WAR_CAUSE_AI_ORDER, FRig.Entity(LBarracks)^.StateMachine.Pending.Cause);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_TRAIN, FRig.ActiveType(LBarracks));
  Assert.AreEqual<Integer>(WAR_UNIT_GRUNT, PWarStateTrain(FRig.Machine.FindState(LBarracks, WAR_STATE_TRAIN))^.UnitToBuild);
end;

procedure TTestWarWallAttack.DovrebbeCreareLEntitaDellaStrada;
var
  LSlot: Integer;
begin
  LSlot := TWarTerrainEntities.CreateRoad(FRig.Context);
  Assert.AreNotEqual(0, LSlot);
  Assert.AreEqual<Integer>(WAR_ENTITY_ROAD, FRig.Entity(LSlot)^.EntityType);
end;

end.
