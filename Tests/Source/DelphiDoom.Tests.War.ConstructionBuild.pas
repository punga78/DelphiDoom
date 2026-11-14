{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - building, repairing and collapsing    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ConstructionBuild;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.ConstructionRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarConstructionBuild = class(TObject)
  private
    FRig: TConstructionRig;
    function StartFarm(out AWorker, ABuilding: Integer): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAddebitareIlCostoECrearePerQuandoSiPiazzaUnEdificio;
    [Test]
    procedure DovrebbeMostrareLImmagineDellaCostruzioneEFarAvanzareIFotogrammi;
    [Test]
    procedure DovrebbeFinireLaCostruzioneERestituireLOperaioSuUnaCasellaVuota;
    [Test]
    procedure DovrebbeFarCorrereIlTempoCentoVolteSuPiuVelocePerIlTrucco;
    [Test]
    procedure DovrebbeFermareIlTempoSeNessunOperaioLavora;
    [Test]
    procedure DovrebbeAnnullareLaCostruzioneRestituireIlCostoEFarCrollare;
    [Test]
    procedure DovrebbeRestituireIlCostoUnaVoltaSola;
    [Test]
    procedure DovrebbeRifiutareUnEdificioSuUnaCasellaOccupata;
    [Test]
    procedure DovrebbeRifiutareUnEdificioSuUnaCasellaNeraNellaNebbia;
    [Test]
    procedure DovrebbeIgnorareLeCaselleFuoriDallaMappaNelControllo;
    [Test]
    procedure DovrebbeRifiutareUnEdificioSeMancaLOro;
    [Test]
    procedure DovrebbeRifiutareUnEdificioSeLOperaioNonAccettaOrdini;
    [Test]
    procedure DovrebbeRestituireIlCostoSeLaPiscinaDelleEntitaEPiena;
    [Test]
    procedure DovrebbeRestituireIlCostoSeNonSiPuoCreareLoStatoDelContadino;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnTipoNonHaLaMisura;
    [Test]
    procedure DovrebbeRiparareUnEdificioPagandoUnOroEUnaLegnaPerColpo;
    [Test]
    procedure DovrebbeFermarsiQuandoLEdificioELIntero;
    [Test]
    procedure DovrebbeLasciareLaRiparazioneSeFinisconoIlDenaro;
    [Test]
    procedure DovrebbeLasciareLaRiparazioneSeLEdificioSparisce;
    [Test]
    procedure DovrebbeLasciareLaRiparazioneSeLEdificioCrolla;
    [Test]
    procedure DovrebbeInseguireLEdificioSeEFuoriPortata;
    [Test]
    procedure DovrebbeNonRiparareConUnOperaioGiaDentroUnEdificioInCostruzione;
    [Test]
    procedure DovrebbeFarUscireLOperaioSeLEdificioCrollaMentreCostruisce;
    [Test]
    procedure DovrebbeFarUscireLOperaioQuandoLEdificioEFinito;
    [Test]
    procedure DovrebbeLiberareLaCostruzioneSeLOperaioVieneRimosso;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLEdificioDaCostruireNonHaLoStato;
    [Test]
    procedure DovrebbeDareIlOrdineDiRiparazioneSoloAgliOperaiAmiciDelProprietario;
    [Test]
    procedure DovrebbeFarCrollareUnEdificioLasciandoRovineECaselleLibere;
    [Test]
    procedure DovrebbeRimuovereLEdificioQuandoFinisceLAnimazioneDelCrollo;
    [Test]
    procedure DovrebbeIgnorareLAnnullamentoDiUnaCosaCheNonEUnEdificio;
    [Test]
    procedure DovrebbeDireLavoroFinitoConLaVoceDegliOrchiSeIlGiocatoreEOrco;
    [Test]
    procedure DovrebbeUscireDalloStatoSeLaCostruzioneEGiaCompletata;
    [Test]
    procedure DovrebbeFarCrollareUnEdificioAnnullatoSenzaAltriStati;
    [Test]
    procedure DovrebbeTornareAlloStatoPrecedenteSeUnaCostruzioneSottoUnAltroStatoVieneAnnullata;
    [Test]
    procedure DovrebbeDimenticareUnOperaioCheNonEsistePiu;
    [Test]
    procedure DovrebbeCrearePerLoStatoDiCostruzioneDelCostoGiaPagato;
    [Test]
    procedure DovrebbeCostruireSenzaDividerePerZeroSeLImmagineNonHaFotogrammi;
    [Test]
    procedure DovrebbeConservareIlDifettoDelCDeiNoveVitaPerUnOroEUnaLegnaAncheSeNeMancaUno;
    [Test]
    procedure DovrebbeConservareIlDifettoDelCDelMuroDelGiocatoreZeroAnchePerGliAltri;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Model.State.Repairing,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.State.Build;

{ TTestWarConstructionBuild }

procedure TTestWarConstructionBuild.Setup;
begin
  FRig := TConstructionRig.Create;
end;

procedure TTestWarConstructionBuild.TearDown;
begin
  FRig.Free;
end;

function TTestWarConstructionBuild.StartFarm(out AWorker, ABuilding: Integer): Boolean;
begin
  AWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  Result := FRig.Commands.PlaceBuilding(AWorker, WAR_UNIT_FARM_HUMANS, 10, 10);
  ABuilding := FRig.FirstOfType(WAR_UNIT_FARM_HUMANS);
end;

procedure TTestWarConstructionBuild.DovrebbeAddebitareIlCostoECrearePerQuandoSiPiazzaUnEdificio;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  Assert.IsTrue(StartFarm(LWorker, LBuilding));
  Assert.AreEqual<Integer>(4500, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(4700, FRig.Context.Players[0]^.Wood);
  Assert.IsTrue(LBuilding <> 0);
  Assert.IsTrue(FRig.Machine.IsGoingToBuild(LBuilding));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_BUILD, FRig.ActiveType(LBuilding));
  Assert.IsTrue(FRig.Entity(LBuilding)^.UnitData.Building);
  // the worker is in reach: one tic as repairer, the next as the one that works inside the building
  Assert.AreEqual<Integer>(WAR_STATE_REPAIR, FRig.ActiveType(LWorker));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_REPAIRING, FRig.ActiveType(LWorker));
end;

procedure TTestWarConstructionBuild.DovrebbeMostrareLImmagineDellaCostruzioneEFarAvanzareIFotogrammi;
var
  LWorker: Integer;
  LBuilding: Integer;
  LBefore: Integer;
  LFrames: Integer;
begin
  StartFarm(LWorker, LBuilding);
  // the image of the construction of the farm (resource 331) has 1 + 331 mod 4 frames in the tests
  FRig.Tick(3, 10);
  LFrames := FRig.Entity(LBuilding)^.SpriteFrames;
  Assert.AreEqual<Integer>(4, LFrames);
  Assert.IsTrue(FRig.Entity(LBuilding)^.HasSprite);
  Assert.AreEqual<Integer>(0, FRig.Observer.AudioCount);
  Assert.IsTrue(FRig.BuildState(LBuilding)^.WorkerId <> 0);
  Assert.IsTrue(FRig.BuildState(LBuilding)^.BuildTime > 0);
  Assert.AreEqual(Double(FRig.BuildState(LBuilding)^.BuildTime / FRig.BuildState(LBuilding)^.TotalBuildTime),
    Double(FRig.Entity(LBuilding)^.UnitData.BuildPercent), 0.0001);
  LBefore := FRig.Entity(LBuilding)^.SpriteFrame;
  FRig.Tick(2, 10);
  // one frame at most for each update, never past the last
  Assert.IsTrue(FRig.Entity(LBuilding)^.SpriteFrame >= LBefore);
  Assert.IsTrue(FRig.Entity(LBuilding)^.SpriteFrame <= LFrames - 1);
  Assert.IsTrue(FRig.Entity(LBuilding)^.SpriteFrame > 0);
end;

procedure TTestWarConstructionBuild.DovrebbeFinireLaCostruzioneERestituireLOperaioSuUnaCasellaVuota;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(40, 10);
  Assert.IsFalse(FRig.Entity(LBuilding)^.UnitData.Building);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LBuilding));
  Assert.AreEqual(1.0, Double(FRig.Entity(LBuilding)^.UnitData.BuildPercent), 0.0001);
  Assert.AreEqual<Integer>(WAR_SOUND_HUMAN_WORK_COMPLETE, FRig.Observer.LastSound);
  // the building has its own image again, with no frames in the tests
  Assert.AreEqual<Integer>(0, FRig.Entity(LBuilding)^.SpriteFrames);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWorker));
  Assert.IsTrue(FRig.Entity(LWorker)^.SpriteEnabled);
end;

procedure TTestWarConstructionBuild.DovrebbeFarCorrereIlTempoCentoVolteSuPiuVelocePerIlTrucco;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  FRig.Context.HurryUp := True;
  StartFarm(LWorker, LBuilding);
  // the farm takes 80 seconds: with 100 times the speed, a second is enough
  FRig.Run(1.5);
  Assert.IsFalse(FRig.Entity(LBuilding)^.UnitData.Building);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LBuilding));
end;

procedure TTestWarConstructionBuild.DovrebbeFermareIlTempoSeNessunOperaioLavora;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(3, 10);
  FRig.World.Entities.RemoveEntity(LWorker);
  Assert.AreEqual<Integer>(0, FRig.BuildState(LBuilding)^.WorkerId);
  FRig.Tick(5, 10);
  Assert.IsTrue(FRig.BuildState(LBuilding)^.BuildTime < FRig.BuildState(LBuilding)^.TotalBuildTime);
  Assert.AreEqual<Integer>(WAR_STATE_BUILD, FRig.ActiveType(LBuilding));
end;

procedure TTestWarConstructionBuild.DovrebbeAnnullareLaCostruzioneRestituireIlCostoEFarCrollare;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(3, 1);
  Assert.IsTrue(FRig.Commands.Cancel(LBuilding));
  FRig.Tick;
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Wood);
  Assert.AreEqual<Integer>(WAR_SOUND_BUILDING_COLLAPSE_1 * 1000 + WAR_SOUND_BUILDING_COLLAPSE_3, FRig.Observer.LastSound);
  Assert.IsTrue(FRig.Machine.IsCollapsing(LBuilding));
  Assert.IsTrue(FRig.Context.Ruins.Count > 0);
  // the worker sees it the tic after and comes out
  FRig.Tick(2);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWorker));
  Assert.IsTrue(FRig.Entity(LWorker)^.SpriteEnabled);
end;

procedure TTestWarConstructionBuild.DovrebbeRestituireIlCostoUnaVoltaSola;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(3, 1);
  FRig.Commands.Cancel(LBuilding);
  FRig.Tick(3, 1);
  // a second cancel, or the collapse, does not give the money back again
  FRig.Commands.Cancel(LBuilding);
  FRig.Tick(3, 1);
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionBuild.DovrebbeRifiutareUnEdificioSuUnaCasellaOccupata;
var
  LWorker: Integer;
begin
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  FRig.AddDude(WAR_UNIT_FOOTMAN, 11, 11);
  Assert.IsFalse(FRig.Commands.PlaceBuilding(LWorker, WAR_UNIT_FARM_HUMANS, 10, 10));
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(Ord(wsmCantBuildThere), Ord(FRig.Observer.LastMessage));
  Assert.AreEqual<Integer>(WAR_SOUND_UI_CANCEL, FRig.Observer.LastSound);
  Assert.AreEqual<Integer>(0, FRig.FirstOfType(WAR_UNIT_FARM_HUMANS));
end;

procedure TTestWarConstructionBuild.DovrebbeRifiutareUnEdificioSuUnaCasellaNeraNellaNebbia;
var
  LWorker: Integer;
begin
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  FRig.Observer.HideTile(11, 11);
  Assert.IsFalse(FRig.Commands.PlaceBuilding(LWorker, WAR_UNIT_FARM_HUMANS, 10, 10));
  Assert.AreEqual<Integer>(Ord(wsmCantBuildThere), Ord(FRig.Observer.LastMessage));
end;

procedure TTestWarConstructionBuild.DovrebbeIgnorareLeCaselleFuoriDallaMappaNelControllo;
begin
  // the original skips the tiles outside the map: a rectangle that is half out is checked only where it is in
  Assert.IsTrue(FRig.Commands.CheckRectToBuild(62, 62, 4, 4));
  Assert.IsTrue(FRig.Commands.CheckRectToBuild(-3, -3, 2, 2));
end;

procedure TTestWarConstructionBuild.DovrebbeRifiutareUnEdificioSeMancaLOro;
var
  LWorker: Integer;
begin
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  FRig.Context.Players[0]^.Gold := 100;
  Assert.IsFalse(FRig.Commands.PlaceBuilding(LWorker, WAR_UNIT_FARM_HUMANS, 10, 10));
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughGold), Ord(FRig.Observer.LastMessage));
  Assert.AreEqual<Integer>(100, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(0, FRig.FirstOfType(WAR_UNIT_FARM_HUMANS));
end;

procedure TTestWarConstructionBuild.DovrebbeRifiutareUnEdificioSeLOperaioNonAccettaOrdini;
var
  LWorker: Integer;
begin
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  FRig.Machine.ResetState(LWorker, PWarStateBase(FRig.Machine.CreateDeath(LWorker)), WAR_CAUSE_LIFECYCLE);
  FRig.Tick;
  Assert.IsFalse(FRig.Commands.PlaceBuilding(LWorker, WAR_UNIT_FARM_HUMANS, 10, 10));
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionBuild.DovrebbeRestituireIlCostoSeLaPiscinaDelleEntitaEPiena;
var
  LWorker: Integer;
  LCount: Integer;
begin
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  // the pool has 1023 usable slots: fill them with units that do nothing
  for LCount := 1 to WAR_MODEL_MAX_ENTITIES do
    if FRig.World.Entities.CreateDude(WAR_UNIT_FOOTMAN, 30, 30, 1, False) = 0 then
      Break;
  Assert.IsFalse(FRig.Commands.PlaceBuilding(LWorker, WAR_UNIT_FARM_HUMANS, 10, 10));
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Wood);
end;

procedure TTestWarConstructionBuild.DovrebbeRestituireIlCostoSeNonSiPuoCreareLoStatoDelContadino;
var
  LWorker: Integer;
  LCount: Integer;
begin
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  // the storage of the repair states has 512 of them: take them all
  for LCount := 1 to 600 do
    if FRig.Machine.AllocState(LWorker, WAR_STATE_REPAIR) = nil then
      Break;
  Assert.IsFalse(FRig.Commands.PlaceBuilding(LWorker, WAR_UNIT_FARM_HUMANS, 10, 10));
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(0, FRig.FirstOfType(WAR_UNIT_FARM_HUMANS));
end;

procedure TTestWarConstructionBuild.DovrebbeSollevareEccezioneSeUnTipoNonHaLaMisura;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Commands.CheckTileToBuild(WAR_UNIT_COUNT + 5, 10, 10);
    end, EWarException);
end;

procedure TTestWarConstructionBuild.DovrebbeRiparareUnEdificioPagandoUnOroEUnaLegnaPerColpo;
var
  LFarm: Integer;
  LWorker: Integer;
  LGold: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  FRig.World.Combat.TakeDamage(LFarm, 100, 0);
  Assert.AreEqual<Integer>(300, FRig.Entity(LFarm)^.UnitData.Hp);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  LGold := FRig.Context.Players[0]^.Gold;
  Assert.IsTrue(FRig.Commands.OrderRepair([LWorker], LFarm));
  Assert.AreEqual<Integer>(1, FRig.Observer.Acknowledged);
  FRig.Run(2);
  Assert.AreEqual<Integer>(WAR_STATE_REPAIRING, FRig.ActiveType(LWorker));
  // each blow of the hammer: 9 hit points for a gold and a lumber
  Assert.IsTrue(FRig.Entity(LFarm)^.UnitData.Hp > 300);
  Assert.AreEqual<Integer>((FRig.Entity(LFarm)^.UnitData.Hp - 300) div 9, LGold - FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(5000 - (LGold - FRig.Context.Players[0]^.Gold), FRig.Context.Players[0]^.Wood);
end;

procedure TTestWarConstructionBuild.DovrebbeFermarsiQuandoLEdificioELIntero;
var
  LFarm: Integer;
  LWorker: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  FRig.World.Combat.TakeDamage(LFarm, 20, 0);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  FRig.Commands.OrderRepair([LWorker], LFarm);
  FRig.Run(4);
  Assert.AreEqual<Integer>(400, FRig.Entity(LFarm)^.UnitData.Hp);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWorker));
  // 20 points of damage: 3 blows of 9 hit points, the last one more than was needed
  Assert.AreEqual<Integer>(5000 - 3, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionBuild.DovrebbeLasciareLaRiparazioneSeFinisconoIlDenaro;
var
  LFarm: Integer;
  LWorker: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  FRig.World.Combat.TakeDamage(LFarm, 200, 0);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  FRig.Context.Players[0]^.Gold := 0;
  FRig.Commands.OrderRepair([LWorker], LFarm);
  FRig.Run(2);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWorker));
  Assert.AreEqual<Integer>(200, FRig.Entity(LFarm)^.UnitData.Hp);
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughGold), Ord(FRig.Observer.LastMessage));
end;

procedure TTestWarConstructionBuild.DovrebbeLasciareLaRiparazioneSeLEdificioSparisce;
var
  LFarm: Integer;
  LWorker: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  FRig.Commands.OrderRepair([LWorker], LFarm);
  FRig.Tick;
  FRig.World.Entities.RemoveEntity(LFarm);
  FRig.Tick(3);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWorker));
end;

procedure TTestWarConstructionBuild.DovrebbeLasciareLaRiparazioneSeLEdificioCrolla;
var
  LFarm: Integer;
  LWorker: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  FRig.Commands.OrderRepair([LWorker], LFarm);
  FRig.Tick(2);
  FRig.World.Combat.TakeDamage(LFarm, 500, 0);
  FRig.Tick(3);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWorker));
end;

procedure TTestWarConstructionBuild.DovrebbeInseguireLEdificioSeEFuoriPortata;
var
  LFarm: Integer;
  LWorker: Integer;
  LFollow: PWarStateFollow;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 20, 20);
  FRig.Commands.OrderRepair([LWorker], LFarm);
  FRig.Tick(3);
  // the follow state is not ported yet: the worker is in it and nobody updates it
  Assert.AreEqual<Integer>(WAR_STATE_FOLLOW, FRig.ActiveType(LWorker));
  LFollow := PWarStateFollow(FRig.Machine.ActiveState(LWorker));
  Assert.AreEqual<Integer>(FRig.Entity(LFarm)^.Id, LFollow^.TargetEntityId);
  Assert.AreEqual<Integer>(1 * WAR_MEGA_TILE_SIZE, LFollow^.TargetDistance);
  // the nearest point of the farm (pixels): the corner of the farm that is nearer to the worker
  Assert.AreEqual(Double(11 * WAR_MEGA_TILE_SIZE + WAR_MEGA_TILE_SIZE - 1 + 0), Double(LFollow^.TargetPosition.X), 100);
end;

procedure TTestWarConstructionBuild.DovrebbeNonRiparareConUnOperaioGiaDentroUnEdificioInCostruzione;
var
  LWorker: Integer;
  LBuilding: Integer;
  LSecond: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(4, 1);
  LSecond := FRig.AddDude(WAR_UNIT_PEON, 9, 11);
  FRig.Commands.OrderRepair([LSecond], LBuilding);
  FRig.Tick(4, 1);
  // there is someone building it already
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LSecond));
  Assert.AreEqual<Integer>(FRig.Entity(LWorker)^.Id, FRig.BuildState(LBuilding)^.WorkerId);
end;

procedure TTestWarConstructionBuild.DovrebbeFarUscireLOperaioSeLEdificioCrollaMentreCostruisce;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(4, 1);
  Assert.IsFalse(FRig.Entity(LWorker)^.SpriteEnabled);
  FRig.World.Combat.TakeDamage(LBuilding, 500, 0);
  FRig.Tick(4, 1);
  Assert.IsTrue(FRig.Entity(LWorker)^.SpriteEnabled);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWorker));
end;

procedure TTestWarConstructionBuild.DovrebbeFarUscireLOperaioQuandoLEdificioEFinito;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(4, 1);
  // the building is done but the worker has not seen it yet: the build state is gone by the time it looks
  FRig.Machine.PopState(LBuilding, WAR_CAUSE_PLAYER_ORDER, WAR_RESULT_SUCCESS);
  FRig.Tick(4, 1);
  Assert.IsTrue(FRig.Entity(LWorker)^.SpriteEnabled);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LWorker));
end;

procedure TTestWarConstructionBuild.DovrebbeLiberareLaCostruzioneSeLOperaioVieneRimosso;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(4, 1);
  Assert.IsTrue(FRig.BuildState(LBuilding)^.WorkerId <> 0);
  FRig.World.Entities.RemoveEntity(LWorker);
  Assert.AreEqual<Integer>(0, FRig.BuildState(LBuilding)^.WorkerId);
end;

procedure TTestWarConstructionBuild.DovrebbeSollevareEccezioneSeLEdificioDaCostruireNonHaLoStato;
var
  LWorker: Integer;
  LBuilding: Integer;
  LRepairing: PWarStateRepairing;
begin
  // the worker is before the building in the pool, so its change of state comes first: the building is going to be
  // built but its build state is not on the stack yet
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  LBuilding := FRig.World.Entities.CreateBuilding(WAR_UNIT_FARM_HUMANS, 10, 10, 0, True);
  Assert.IsTrue(FRig.Machine.IsGoingToBuild(LBuilding));
  LRepairing := TWarRepairingState.CreateState(FRig.Machine, LWorker, FRig.Entity(LBuilding)^.Id);
  FRig.Machine.ResetState(LWorker, PWarStateBase(LRepairing), WAR_CAUSE_PLAYER_ORDER);
  Assert.WillRaise(
    procedure
    begin
      FRig.Tick;
    end, EWarException);
end;

procedure TTestWarConstructionBuild.DovrebbeDareIlOrdineDiRiparazioneSoloAgliOperaiAmiciDelProprietario;
var
  LFarm: Integer;
  LEnemyFarm: Integer;
  LWorker: Integer;
  LEnemyWorker: Integer;
  LFootman: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LEnemyFarm := FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 20, 10, 1);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  LEnemyWorker := FRig.AddDude(WAR_UNIT_PEON, 19, 10, 1);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 9, 11);
  // the footman can not repair; the worker of the other player is not friendly; nobody repairs a building of another owner
  Assert.IsFalse(FRig.Commands.OrderRepair([LFootman], LFarm));
  Assert.IsFalse(FRig.Commands.OrderRepair([LEnemyWorker], LEnemyFarm));
  Assert.IsFalse(FRig.Commands.OrderRepair([LWorker], LEnemyFarm));
  Assert.AreEqual<Integer>(0, FRig.Observer.Acknowledged);
  // a worker that does not accept orders is skipped: dead, it is not given the order
  FRig.Machine.ResetState(LWorker, PWarStateBase(FRig.Machine.CreateDeath(LWorker)), WAR_CAUSE_LIFECYCLE);
  FRig.Tick;
  Assert.IsFalse(FRig.Commands.OrderRepair([LWorker], LFarm));
  // a worker can not repair itself (a worker is not a building, but the order is by slot)
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 12);
  Assert.IsFalse(FRig.Commands.OrderRepair([LWorker], LWorker));
  Assert.IsTrue(FRig.Commands.OrderRepair([LWorker], LFarm));
  Assert.AreEqual<Integer>(1, FRig.Observer.Acknowledged);
end;

procedure TTestWarConstructionBuild.DovrebbeFarCrollareUnEdificioLasciandoRovineECaselleLibere;
var
  LTownHall: Integer;
begin
  LTownHall := FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, 10, 10);
  Assert.IsFalse(FRig.Grid.IsEmpty(11, 11));
  FRig.World.Combat.TakeDamage(LTownHall, 3000, 0);
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.IsCollapsing(LTownHall));
  Assert.IsFalse(FRig.Entity(LTownHall)^.SpriteEnabled);
  Assert.IsTrue(FRig.Context.Ruins.Count > 0);
  Assert.IsTrue(FRig.Context.Ruins.HasPieceAt(10, 10));
  Assert.IsTrue(FRig.Grid.IsEmpty(11, 11));
  Assert.AreEqual<Integer>(1, FRig.Observer.LeftSelection);
end;

procedure TTestWarConstructionBuild.DovrebbeRimuovereLEdificioQuandoFinisceLAnimazioneDelCrollo;
var
  LFarm: Integer;
  LId: Word;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LId := FRig.Entity(LFarm)^.Id;
  FRig.World.Combat.TakeDamage(LFarm, 500, 0);
  FRig.Tick;
  // 17 frames of a tenth of a second
  FRig.Run(1.5);
  Assert.AreEqual<Integer>(LFarm, FRig.Context.Pool.FindSlot(LId));
  FRig.Run(0.5);
  Assert.AreEqual<Integer>(0, FRig.Context.Pool.FindSlot(LId));
end;

procedure TTestWarConstructionBuild.DovrebbeIgnorareLAnnullamentoDiUnaCosaCheNonEUnEdificio;
var
  LWorker: Integer;
  LFarm: Integer;
begin
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  // a unit has nothing to cancel, and a building that does nothing neither
  Assert.IsFalse(FRig.Commands.Cancel(LWorker));
  Assert.IsFalse(FRig.Commands.Cancel(LFarm));
  // a building that does not accept orders (it collapses) is left alone
  FRig.World.Combat.TakeDamage(LFarm, 500, 0);
  FRig.Tick;
  Assert.IsFalse(FRig.Commands.Cancel(LFarm));
end;

procedure TTestWarConstructionBuild.DovrebbeDireLavoroFinitoConLaVoceDegliOrchiSeIlGiocatoreEOrco;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  FRig.Context.Players[0]^.Race := wraOrcs;
  StartFarm(LWorker, LBuilding);
  FRig.Tick(40, 10);
  Assert.AreEqual<Integer>(WAR_SOUND_ORC_WORK_COMPLETE, FRig.Observer.LastSound);
end;

procedure TTestWarConstructionBuild.DovrebbeUscireDalloStatoSeLaCostruzioneEGiaCompletata;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(3, 1);
  FRig.BuildState(LBuilding)^.OutputCommitted := True;
  FRig.Tick(3, 1);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LBuilding));
end;

procedure TTestWarConstructionBuild.DovrebbeFarCrollareUnEdificioAnnullatoSenzaAltriStati;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(3, 1);
  // a build state that is cancelled and is the only one of the building: the building collapses, and leaving the state
  // gives the money back
  FRig.BuildState(LBuilding)^.Cancelled := True;
  FRig.Tick(3, 1);
  Assert.IsTrue(FRig.Machine.IsCollapsing(LBuilding));
  Assert.AreEqual<Integer>(5000, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarConstructionBuild.DovrebbeTornareAlloStatoPrecedenteSeUnaCostruzioneSottoUnAltroStatoVieneAnnullata;
var
  LFarm: Integer;
  LBuild: PWarStateBase;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LBuild := FRig.Machine.CreateBuild(LFarm, 5, 100, 50);
  Assert.IsTrue(FRig.Machine.PushState(LFarm, LBuild, WAR_CAUSE_PLAYER_ORDER));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_BUILD, FRig.ActiveType(LFarm));
  PWarStateBuild(LBuild)^.Cancelled := True;
  FRig.Tick(2);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFarm));
  Assert.AreEqual<Integer>(5000 + 100, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(5000 + 50, FRig.Context.Players[0]^.Wood);
end;

procedure TTestWarConstructionBuild.DovrebbeDimenticareUnOperaioCheNonEsistePiu;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  StartFarm(LWorker, LBuilding);
  FRig.Tick(3, 1);
  FRig.BuildState(LBuilding)^.WorkerId := 999;
  FRig.Tick(1, 1);
  Assert.AreEqual<Integer>(0, FRig.BuildState(LBuilding)^.WorkerId);
end;

procedure TTestWarConstructionBuild.DovrebbeCostruireSenzaDividerePerZeroSeLImmagineNonHaFotogrammi;
var
  LWorker: Integer;
  LBuilding: Integer;
begin
  // the default host has no frames for the image of the construction (the original divides 1 by 0 and gets infinity, which
  // no percent reaches): the time goes on and the frame stays
  FRig.Context.ConstructionHost := nil;
  StartFarm(LWorker, LBuilding);
  FRig.Tick(5, 10);
  Assert.AreEqual<Integer>(0, FRig.Entity(LBuilding)^.SpriteFrames);
  Assert.AreEqual<Integer>(0, FRig.Entity(LBuilding)^.SpriteFrame);
  Assert.IsTrue(FRig.Entity(LBuilding)^.UnitData.BuildPercent > 0);
end;

procedure TTestWarConstructionBuild.DovrebbeConservareIlDifettoDelCDeiNoveVitaPerUnOroEUnaLegnaAncheSeNeMancaUno;
var
  LFarm: Integer;
  LWorker: Integer;
begin
  // a defect of the original that is kept: a blow of the hammer pays a gold and a lumber and heals 9 hit points, even
  // for the one hit point that is missing
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  FRig.World.Combat.TakeDamage(LFarm, 1, 0);
  Assert.AreEqual<Integer>(399, FRig.Entity(LFarm)^.UnitData.Hp);
  LWorker := FRig.AddDude(WAR_UNIT_PEASANT, 9, 10);
  FRig.Commands.OrderRepair([LWorker], LFarm);
  FRig.Run(2);
  Assert.AreEqual<Integer>(400, FRig.Entity(LFarm)^.UnitData.Hp);
  Assert.AreEqual<Integer>(4999, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual<Integer>(4999, FRig.Context.Players[0]^.Wood);
end;

procedure TTestWarConstructionBuild.DovrebbeConservareIlDifettoDelCDelMuroDelGiocatoreZeroAnchePerGliAltri;
begin
  // a defect of the original that is kept: the piece belongs to the player 0 whoever pays for it
  Assert.IsTrue(FRig.Commands.PlaceWall(2, 20, 20));
  Assert.AreEqual<Integer>(0, FRig.Context.Walls[0]^.Player);
  Assert.AreEqual<Integer>(5000 - WAR_WALL_GOLD_COST, FRig.Context.Players[2]^.Gold);
end;

procedure TTestWarConstructionBuild.DovrebbeCrearePerLoStatoDiCostruzioneDelCostoGiaPagato;
var
  LFarm: Integer;
  LBuild: PWarStateBuild;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LBuild := TWarBuildState.CreateState(FRig.Machine, LFarm, 80, 500, 300);
  Assert.IsTrue(Assigned(LBuild));
  Assert.AreEqual(80.0, Double(LBuild^.TotalBuildTime), 0);
  Assert.IsTrue(LBuild^.TransactionApplied);
  Assert.AreEqual<Integer>(0, LBuild^.WorkerId);
  Assert.AreEqual<Integer>(500, LBuild^.GoldCost);
end;

end.
