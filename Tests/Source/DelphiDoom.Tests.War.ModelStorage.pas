{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the pool of the entities and the     }
{  storage of the states                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelStorage;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Model.EntityPool, DelphiDoom.War.Model.StateStorage;

type
  [TestFixture]
  [Category('war')]
  TTestWarEntityPool = class(TObject)
  private
    FPool: TWarEntityPool;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareIlPrimoSlotLiberoEIdCrescenti;
    [Test]
    procedure DovrebbeRiusareUnoSlotLiberatoMaDareUnIdNuovo;
    [Test]
    procedure DovrebbeTrovareUnaEntitaDalSuoId;
    [Test]
    procedure DovrebbeTenereLeListeNellOrdineDiInserimentoAnchePoiUnaRimozione;
    [Test]
    procedure DovrebbeTrovareUnaEntitaAnchePerNonEssereNellaScena;
    [Test]
    procedure DovrebbeDareSlotZeroSeIlPoolEPieno;
    [Test]
    procedure DovrebbeSaltareGliIdInUsoEZeroQuandoGliIdFinisconoIlGiro;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnoSlotNonEsiste;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarStateStorage = class(TObject)
  private
    FStorage: TWarStateStorage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareIlPrimoSlotELultimoLiberatoPerPrimo;
    [Test]
    procedure DovrebbeRendereInvalidaUnaReferenzaDopoLaLiberazione;
    [Test]
    procedure DovrebbeAzzerareUnoStatoNuovo;
    [Test]
    procedure DovrebbeTrovareLaReferenzaDiUnoStato;
    [Test]
    procedure DovrebbeDareUnaReferenzaInvalidaSeIlTipoEPieno;
    [Test]
    procedure DovrebbeIgnorareLaLiberazioneDiUnaReferenzaInvalida;
    [Test]
    procedure DovrebbeContareGliStatiAttiviELiberi;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiStatoCheNonEsiste;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types;

{ TTestWarEntityPool }

procedure TTestWarEntityPool.Setup;
begin
  FPool := TWarEntityPool.Create;
end;

procedure TTestWarEntityPool.TearDown;
begin
  FPool.Free;
end;

procedure TTestWarEntityPool.DovrebbeDareIlPrimoSlotLiberoEIdCrescenti;
begin
  Assert.AreEqual<Integer>(1, FPool.CreateEntity(WAR_ENTITY_UNIT, True));
  Assert.AreEqual<Integer>(2, FPool.CreateEntity(WAR_ENTITY_UNIT, True));
  Assert.AreEqual<Integer>(1, FPool.Slots[1]^.Id);
  Assert.AreEqual<Integer>(2, FPool.Slots[2]^.Id);
  Assert.AreEqual<Integer>(2, FPool.EntityCount);
  Assert.AreEqual<Integer>(2, FPool.LastId);
end;

procedure TTestWarEntityPool.DovrebbeRiusareUnoSlotLiberatoMaDareUnIdNuovo;
var
  LSlot: Integer;
begin
  LSlot := FPool.CreateEntity(WAR_ENTITY_UNIT, True);
  FPool.CreateEntity(WAR_ENTITY_UNIT, True);
  FPool.FreeSlot(LSlot, WAR_UNIT_FOOTMAN, False);
  Assert.AreEqual<Integer>(LSlot, FPool.CreateEntity(WAR_ENTITY_UNIT, True));
  Assert.AreEqual<Integer>(3, FPool.Slots[LSlot]^.Id);
end;

procedure TTestWarEntityPool.DovrebbeTrovareUnaEntitaDalSuoId;
var
  LSlot: Integer;
  LId: Word;
begin
  FPool.CreateEntity(WAR_ENTITY_UNIT, True);
  LSlot := FPool.CreateEntity(WAR_ENTITY_UNIT, True);
  LId := FPool.Slots[LSlot]^.Id;
  Assert.AreEqual<Integer>(LSlot, FPool.FindSlot(LId));
  Assert.AreEqual<Integer>(0, FPool.FindSlot(0));
  Assert.AreEqual<Integer>(0, FPool.FindSlot(999));
  FPool.FreeSlot(LSlot, WAR_UNIT_FOOTMAN, False);
  Assert.AreEqual<Integer>(0, FPool.FindSlot(LId));
end;

procedure TTestWarEntityPool.DovrebbeTenereLeListeNellOrdineDiInserimentoAnchePoiUnaRimozione;
var
  LFirst: Integer;
  LSecond: Integer;
  LThird: Integer;
begin
  LFirst := FPool.CreateEntity(WAR_ENTITY_UNIT, True);
  LSecond := FPool.CreateEntity(WAR_ENTITY_UNIT, True);
  LThird := FPool.CreateEntity(WAR_ENTITY_UNIT, True);
  FPool.AddToUnitList(LFirst, WAR_UNIT_FOOTMAN);
  FPool.AddToUnitList(LSecond, WAR_UNIT_FOOTMAN);
  FPool.AddToUnitList(LThird, WAR_UNIT_FOOTMAN);
  FPool.FreeSlot(LSecond, WAR_UNIT_FOOTMAN, True);
  Assert.AreEqual<Integer>(2, FPool.OfType[WAR_ENTITY_UNIT].Count);
  Assert.AreEqual<Integer>(LFirst, FPool.OfType[WAR_ENTITY_UNIT][0]);
  Assert.AreEqual<Integer>(LThird, FPool.OfType[WAR_ENTITY_UNIT][1]);
  Assert.AreEqual<Integer>(2, FPool.UnitsOfType[WAR_UNIT_FOOTMAN].Count);
end;

procedure TTestWarEntityPool.DovrebbeTrovareUnaEntitaAnchePerNonEssereNellaScena;
var
  LSlot: Integer;
begin
  LSlot := FPool.CreateEntity(WAR_ENTITY_UNIT, False);
  Assert.AreEqual<Integer>(0, FPool.OfType[WAR_ENTITY_UNIT].Count);
  Assert.AreEqual<Integer>(LSlot, FPool.FindSlot(FPool.Slots[LSlot]^.Id));
end;

procedure TTestWarEntityPool.DovrebbeDareSlotZeroSeIlPoolEPieno;
var
  LIndex: Integer;
begin
  for LIndex := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
    Assert.AreNotEqual<Integer>(0, FPool.CreateEntity(WAR_ENTITY_UNIT, False));
  Assert.AreEqual<Integer>(0, FPool.CreateEntity(WAR_ENTITY_UNIT, False));
end;

procedure TTestWarEntityPool.DovrebbeSaltareGliIdInUsoEZeroQuandoGliIdFinisconoIlGiro;
var
  LHolder: Integer;
  LIndex: Integer;
  LSlot: Integer;
begin
  // the first entity keeps the id 1 while 65535 more are made and freed: the ids come back to 1 (and 0 is never given)
  LHolder := FPool.CreateEntity(WAR_ENTITY_UNIT, False);
  for LIndex := 1 to 65536 do
  begin
    LSlot := FPool.CreateEntity(WAR_ENTITY_UNIT, False);
    Assert.AreNotEqual<Integer>(0, FPool.Slots[LSlot]^.Id);
    Assert.AreNotEqual<Integer>(FPool.Slots[LHolder]^.Id, FPool.Slots[LSlot]^.Id);
    FPool.FreeSlot(LSlot, WAR_UNIT_FOOTMAN, False);
  end;
  Assert.AreEqual<Integer>(1, FPool.EntityCount);
end;

procedure TTestWarEntityPool.DovrebbeSollevareEccezioneSeUnoSlotNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FPool.Slots[WAR_MODEL_MAX_ENTITIES];
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FPool.Slots[-1];
    end, EWarException);
end;

{ TTestWarStateStorage }

procedure TTestWarStateStorage.Setup;
begin
  FStorage := TWarStateStorage.Create;
end;

procedure TTestWarStateStorage.TearDown;
begin
  FStorage.Free;
end;

procedure TTestWarStateStorage.DovrebbeDareIlPrimoSlotELultimoLiberatoPerPrimo;
var
  LFirst: TWarStateRef;
  LSecond: TWarStateRef;
  LThird: TWarStateRef;
begin
  LFirst := FStorage.Alloc(WAR_STATE_IDLE, 1);
  LSecond := FStorage.Alloc(WAR_STATE_IDLE, 2);
  Assert.AreEqual<Integer>(0, LFirst.Index);
  Assert.AreEqual<Integer>(1, LSecond.Index);
  FStorage.Release(LFirst);
  LThird := FStorage.Alloc(WAR_STATE_IDLE, 3);
  Assert.AreEqual<Integer>(0, LThird.Index);
  Assert.AreEqual<Cardinal>(2, LThird.Generation);
end;

procedure TTestWarStateStorage.DovrebbeRendereInvalidaUnaReferenzaDopoLaLiberazione;
var
  LRef: TWarStateRef;
begin
  LRef := FStorage.Alloc(WAR_STATE_MOVE, 1);
  Assert.IsTrue(FStorage.IsAllocated(LRef));
  Assert.IsTrue(Assigned(FStorage.Deref(LRef)));
  FStorage.Release(LRef);
  Assert.IsFalse(FStorage.IsAllocated(LRef));
  Assert.IsFalse(Assigned(FStorage.Deref(LRef)));
end;

procedure TTestWarStateStorage.DovrebbeAzzerareUnoStatoNuovo;
var
  LRef: TWarStateRef;
  LMove: PWarStateMove;
begin
  LRef := FStorage.Alloc(WAR_STATE_MOVE, 7);
  LMove := PWarStateMove(FStorage.Deref(LRef));
  LMove^.WaypointsCount := 5;
  FStorage.Release(LRef);
  LRef := FStorage.Alloc(WAR_STATE_MOVE, 9);
  LMove := PWarStateMove(FStorage.Deref(LRef));
  Assert.AreEqual<Integer>(0, LMove^.WaypointsCount);
  Assert.AreEqual<Integer>(9, LMove^.Base.EntityId);
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, LMove^.Base.StateType);
end;

procedure TTestWarStateStorage.DovrebbeTrovareLaReferenzaDiUnoStato;
var
  LRef: TWarStateRef;
  LFound: TWarStateRef;
begin
  FStorage.Alloc(WAR_STATE_WAIT, 1);
  LRef := FStorage.Alloc(WAR_STATE_WAIT, 2);
  LFound := FStorage.RefOf(FStorage.Deref(LRef));
  Assert.IsTrue(TWarStateRefs.Equal(LRef, LFound));
  Assert.IsFalse(TWarStateRefs.IsValid(FStorage.RefOf(nil)));
  FStorage.Release(LRef);
  Assert.IsFalse(TWarStateRefs.IsValid(FStorage.RefOf(FStorage.StateAt(WAR_STATE_WAIT, 1))));
end;

procedure TTestWarStateStorage.DovrebbeDareUnaReferenzaInvalidaSeIlTipoEPieno;
var
  LIndex: Integer;
begin
  for LIndex := 1 to WAR_MODEL_MAX_STATES_PER_TYPE do
    Assert.IsTrue(TWarStateRefs.IsValid(FStorage.Alloc(WAR_STATE_DEATH, 1)));
  Assert.IsFalse(TWarStateRefs.IsValid(FStorage.Alloc(WAR_STATE_DEATH, 1)));
  Assert.AreEqual<Integer>(0, FStorage.FreeCount[WAR_STATE_DEATH]);
end;

procedure TTestWarStateStorage.DovrebbeIgnorareLaLiberazioneDiUnaReferenzaInvalida;
var
  LRef: TWarStateRef;
begin
  FStorage.Release(TWarStateRefs.Invalid);
  LRef := FStorage.Alloc(WAR_STATE_IDLE, 1);
  FStorage.Release(LRef);
  FStorage.Release(LRef);
  Assert.AreEqual<Integer>(0, FStorage.ActiveCount[WAR_STATE_IDLE]);
  Assert.AreEqual<Integer>(WAR_MODEL_MAX_STATES_PER_TYPE, FStorage.FreeCount[WAR_STATE_IDLE]);
end;

procedure TTestWarStateStorage.DovrebbeContareGliStatiAttiviELiberi;
begin
  FStorage.Alloc(WAR_STATE_CAST, 1);
  FStorage.Alloc(WAR_STATE_CAST, 2);
  Assert.AreEqual<Integer>(2, FStorage.ActiveCount[WAR_STATE_CAST]);
  Assert.AreEqual<Integer>(WAR_MODEL_MAX_STATES_PER_TYPE - 2, FStorage.FreeCount[WAR_STATE_CAST]);
  Assert.IsTrue(FStorage.Occupied[WAR_STATE_CAST, 0]);
  Assert.IsFalse(FStorage.Occupied[WAR_STATE_CAST, 2]);
end;

procedure TTestWarStateStorage.DovrebbeRifiutareUnTipoDiStatoCheNonEsiste;
begin
  Assert.IsFalse(TWarStateRefs.IsValid(FStorage.Alloc(WAR_STATE_COUNT, 1)));
  Assert.IsFalse(TWarStateRefs.IsValid(FStorage.Alloc(-1, 1)));
  Assert.IsFalse(FStorage.IsAllocated(TWarStateRefs.Invalid));
  Assert.IsFalse(TWarStateRefs.Equal(TWarStateRefs.Invalid, FStorage.Alloc(WAR_STATE_IDLE, 1)));
end;

end.
