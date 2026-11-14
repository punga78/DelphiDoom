{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the state machine                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelMachine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.ModelRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarStateMachine = class(TObject)
  private
    FRig: TModelRig;
    FSlot: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeInstallareLoStatoIdleAlLoSpawnDiUnaUnita;
    [Test]
    procedure DovrebbeImpilareUnoStatoESpilarloTornandoAQuelloSotto;
    [Test]
    procedure DovrebbeRimettereUnIdleQuandoLoStackSiSvuota;
    [Test]
    procedure DovrebbeSostituireLoStatoInCima;
    [Test]
    procedure DovrebbeAzzerareLoStackConUnReset;
    [Test]
    procedure DovrebbeSostituireSoloLaCimaSeLoStackEPieno;
    [Test]
    procedure DovrebbeTenereLaRichiestaConLaCausaPiuAlta;
    [Test]
    procedure DovrebbeTenereLaPrimaRichiestaAParitaDiCausa;
    [Test]
    procedure DovrebbeRifiutareUnaRichiestaNonValida;
    [Test]
    procedure DovrebbeDareFalsoPerUnaEntitaSenzaMacchina;
    [Test]
    procedure DovrebbeDireSeLoStatoAttivoAccettaUnInterruzione;
    [Test]
    procedure DovrebbeDireVeroPerUnoStackVuoto;
    [Test]
    procedure DovrebbeDareLaRagioneDiUscitaSecondoIlRisultato;
    [Test]
    procedure DovrebbeDareLaRagioneDiUscitaPerSostituzioneResetERimozione;
    [Test]
    procedure DovrebbeDareLaMorteComeRagioneDelResetDiUnoStatoDiMorte;
    [Test]
    procedure DovrebbeLiberareGliStatiInAttesaQuandoUnaEntitaSiTogliendo;
    [Test]
    procedure DovrebbeSegnareComeAnnullatoUnAcquistoEUscire;
    [Test]
    procedure DovrebbeTrasformareLAnnullamentoInUnaFineSeLEsitoEGiaDato;
    [Test]
    procedure DovrebbeRifiutareUnAnnullamentoSenzaAcquisto;
    [Test]
    procedure DovrebbeTrasformareIlRitardoInUnTempo;
    [Test]
    procedure DovrebbeDireSePrimaDelloStatoCeUnaRichiesta;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiStatoFuoriTabella;
    [Test]
    procedure DovrebbeTrovareUnoStatoNellaPilaDallaCima;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.StateMachine;

var
  GReasons: array of Integer;
  GCancelledAtExit: Boolean;
  GEntered: Integer;

procedure RecordExit(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer);
begin
  SetLength(GReasons, Length(GReasons) + 1);
  GReasons[High(GReasons)] := AReason;
end;

procedure RecordBuildExit(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer);
begin
  GCancelledAtExit := PWarStateBuild(AState)^.Cancelled;
  RecordExit(AMachine, ASlot, AState, AReason);
end;

procedure CountEnter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
begin
  Inc(GEntered);
end;

{ TTestWarStateMachine }

procedure TTestWarStateMachine.Setup;
begin
  FRig := TModelRig.Create;
  FSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  SetLength(GReasons, 0);
  GCancelledAtExit := False;
  GEntered := 0;
  // the cast state is not ported: a scratch state with hooks that record
  FRig.World.Machine.RegisterHooks(WAR_STATE_CAST, CountEnter, RecordExit, nil);
end;

procedure TTestWarStateMachine.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarStateMachine.DovrebbeInstallareLoStatoIdleAlLoSpawnDiUnaUnita;
begin
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(1, FRig.Entity(FSlot)^.StateMachine.Depth);
  Assert.IsTrue(FRig.World.Machine.IsActive(FSlot, WAR_STATE_IDLE));
  Assert.IsFalse(FRig.World.Machine.IsActive(FSlot, WAR_STATE_MOVE));
end;

procedure TTestWarStateMachine.DovrebbeImpilareUnoStatoESpilarloTornandoAQuelloSotto;
var
  LState: PWarStateBase;
begin
  LState := FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST);
  Assert.IsTrue(FRig.World.Machine.PushState(FSlot, LState, WAR_CAUSE_PLAYER_ORDER));
  Assert.IsTrue(FRig.World.Machine.HasPending(FSlot, WAR_STATE_CAST));
  FRig.Tick;
  Assert.AreEqual<Integer>(2, FRig.Entity(FSlot)^.StateMachine.Depth);
  Assert.AreEqual<Integer>(WAR_STATE_CAST, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(1, GEntered);
  Assert.IsTrue(FRig.World.Machine.Contains(FSlot, WAR_STATE_IDLE));
  FRig.World.Machine.PopState(FSlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(1, FRig.Entity(FSlot)^.StateMachine.Depth);
end;

procedure TTestWarStateMachine.DovrebbeRimettereUnIdleQuandoLoStackSiSvuota;
begin
  FRig.World.Machine.PopState(FSlot, WAR_CAUSE_PLAYER_ORDER, WAR_RESULT_SUCCESS);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(1, FRig.World.Context.Storage.ActiveCount[WAR_STATE_IDLE]);
end;

procedure TTestWarStateMachine.DovrebbeSostituireLoStatoInCima;
var
  LState: PWarStateBase;
begin
  LState := FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST);
  Assert.IsTrue(FRig.World.Machine.ReplaceState(FSlot, LState, WAR_CAUSE_AI_ORDER));
  FRig.Tick;
  Assert.AreEqual<Integer>(1, FRig.Entity(FSlot)^.StateMachine.Depth);
  Assert.AreEqual<Integer>(WAR_STATE_CAST, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_IDLE]);
  Assert.IsFalse(FRig.World.Machine.ReplaceState(FSlot, nil, WAR_CAUSE_AI_ORDER));
end;

procedure TTestWarStateMachine.DovrebbeAzzerareLoStackConUnReset;
var
  LState: PWarStateBase;
begin
  FRig.World.Machine.PushState(FSlot, FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST), WAR_CAUSE_PLAYER_ORDER);
  FRig.Tick;
  LState := PWarStateBase(FRig.World.Machine.CreateWait(FSlot, 5));
  Assert.IsTrue(FRig.World.Machine.ResetState(FSlot, LState, WAR_CAUSE_PLAYER_ORDER));
  FRig.Tick;
  Assert.AreEqual<Integer>(1, FRig.Entity(FSlot)^.StateMachine.Depth);
  Assert.AreEqual<Integer>(WAR_STATE_WAIT, FRig.ActiveType(FSlot));
  Assert.IsFalse(FRig.World.Machine.ResetState(FSlot, nil, WAR_CAUSE_PLAYER_ORDER));
end;

procedure TTestWarStateMachine.DovrebbeSostituireSoloLaCimaSeLoStackEPieno;
var
  LIndex: Integer;
begin
  for LIndex := 1 to WAR_MODEL_STATE_STACK_DEPTH - 1 do
  begin
    FRig.World.Machine.PushState(FSlot, PWarStateBase(FRig.World.Machine.CreateWait(FSlot, 50)), WAR_CAUSE_AI_ORDER);
    FRig.Tick;
  end;
  Assert.AreEqual<Integer>(WAR_MODEL_STATE_STACK_DEPTH, FRig.Entity(FSlot)^.StateMachine.Depth);
  FRig.World.Machine.PushState(FSlot, FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST), WAR_CAUSE_AI_ORDER);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_MODEL_STATE_STACK_DEPTH, FRig.Entity(FSlot)^.StateMachine.Depth);
  Assert.AreEqual<Integer>(WAR_STATE_CAST, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(WAR_MODEL_STATE_STACK_DEPTH - 2, FRig.World.Context.Storage.ActiveCount[WAR_STATE_WAIT]);
end;

procedure TTestWarStateMachine.DovrebbeTenereLaRichiestaConLaCausaPiuAlta;
var
  LLow: PWarStateBase;
  LHigh: PWarStateBase;
begin
  LLow := FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST);
  LHigh := PWarStateBase(FRig.World.Machine.CreateWait(FSlot, 5));
  Assert.IsTrue(FRig.World.Machine.PushState(FSlot, LLow, WAR_CAUSE_AUTONOMOUS));
  Assert.IsTrue(FRig.World.Machine.PushState(FSlot, LHigh, WAR_CAUSE_PLAYER_ORDER));
  Assert.IsFalse(FRig.World.Machine.HasPending(FSlot, WAR_STATE_CAST));
  Assert.IsTrue(FRig.World.Machine.HasPending(FSlot, WAR_STATE_WAIT));
  // the state of the lost request was freed
  Assert.AreEqual<Integer>(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_CAST]);
end;

procedure TTestWarStateMachine.DovrebbeTenereLaPrimaRichiestaAParitaDiCausa;
var
  LFirst: PWarStateBase;
  LSecond: PWarStateBase;
begin
  LFirst := FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST);
  LSecond := PWarStateBase(FRig.World.Machine.CreateWait(FSlot, 5));
  Assert.IsTrue(FRig.World.Machine.PushState(FSlot, LFirst, WAR_CAUSE_AI_ORDER));
  Assert.IsFalse(FRig.World.Machine.PushState(FSlot, LSecond, WAR_CAUSE_AI_ORDER));
  Assert.IsTrue(FRig.World.Machine.HasPending(FSlot, WAR_STATE_CAST));
  Assert.AreEqual<Integer>(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_WAIT]);
end;

procedure TTestWarStateMachine.DovrebbeRifiutareUnaRichiestaNonValida;
var
  LOther: Integer;
  LForeign: PWarStateBase;
  LOwn: PWarStateBase;
  LRequest: TWarTransitionRequest;
  LWait: PWarStateBase;
begin
  LOther := FRig.AddDude(WAR_UNIT_GRUNT, 20, 20, 1);
  // a state of another entity: refused, and freed (nobody holds it)
  LForeign := PWarStateBase(FRig.World.Machine.CreateWait(LOther, 1));
  Assert.IsFalse(FRig.World.Machine.PushState(FSlot, LForeign, WAR_CAUSE_AI_ORDER));
  Assert.AreEqual<Integer>(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_WAIT]);
  // a state already on the stack
  LOwn := FRig.World.Machine.ActiveState(FSlot);
  Assert.IsFalse(FRig.World.Machine.PushState(FSlot, LOwn, WAR_CAUSE_AI_ORDER));
  Assert.IsTrue(Assigned(FRig.World.Machine.ActiveState(FSlot)));
  // a cause that does not exist
  Assert.IsFalse(FRig.World.Machine.PopState(FSlot, 5, WAR_RESULT_SUCCESS));
  // a pop that carries a state, and an operation that does not exist
  LWait := PWarStateBase(FRig.World.Machine.CreateWait(FSlot, 1));
  LRequest := Default(TWarTransitionRequest);
  LRequest.StateRef := FRig.World.Context.Storage.RefOf(LWait);
  LRequest.CancellationTargetRef := TWarStateRefs.Invalid;
  LRequest.Operation := WAR_OP_POP;
  LRequest.Cause := WAR_CAUSE_PLAYER_ORDER;
  Assert.IsFalse(FRig.World.Machine.SubmitTransition(FSlot, LRequest));
  LWait := PWarStateBase(FRig.World.Machine.CreateWait(FSlot, 1));
  LRequest.StateRef := FRig.World.Context.Storage.RefOf(LWait);
  LRequest.Operation := 77;
  Assert.IsFalse(FRig.World.Machine.SubmitTransition(FSlot, LRequest));
  // the same state asked by two entities: the second one is refused and the state stays with the first
  LForeign := PWarStateBase(FRig.World.Machine.CreateWait(LOther, 1));
  Assert.IsTrue(FRig.World.Machine.PushState(LOther, LForeign, WAR_CAUSE_AI_ORDER));
  Assert.IsFalse(FRig.World.Machine.PushState(FSlot, LForeign, WAR_CAUSE_AI_ORDER));
  Assert.IsTrue(FRig.World.Machine.HasPending(LOther, WAR_STATE_WAIT));
end;
procedure TTestWarStateMachine.DovrebbeDareFalsoPerUnaEntitaSenzaMacchina;
var
  LState: PWarStateBase;
begin
  LState := FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST);
  Assert.IsFalse(FRig.World.Machine.PushState(0, LState, WAR_CAUSE_AI_ORDER));
  Assert.IsFalse(FRig.World.Machine.PopState(0, WAR_CAUSE_AI_ORDER, WAR_RESULT_SUCCESS));
  Assert.IsFalse(FRig.World.Machine.CanSubmitTransition(0, WAR_INTERRUPT_ALL));
  Assert.IsFalse(Assigned(FRig.World.Machine.ActiveState(0)));
  Assert.IsFalse(FRig.World.Machine.ResetStateForCancellation(0, LState, WAR_CAUSE_PLAYER_ORDER));
  Assert.AreEqual<Integer>(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_CAST]);
end;

procedure TTestWarStateMachine.DovrebbeDireSeLoStatoAttivoAccettaUnInterruzione;
var
  LEnemy: Integer;
  LAttack: PWarStateAttack;
begin
  Assert.IsTrue(FRig.World.Machine.CanSubmitTransition(FSlot, WAR_INTERRUPT_AUTONOMOUS));
  LEnemy := FRig.AddDude(WAR_UNIT_GRUNT, 20, 20, 1);
  LAttack := FRig.World.Machine.CreateAttack(FSlot, FRig.Entity(LEnemy)^.Id, FRig.Entity(LEnemy)^.Position);
  FRig.World.Machine.ResetState(FSlot, PWarStateBase(LAttack), WAR_CAUSE_PLAYER_ORDER);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_ATTACK, FRig.ActiveType(FSlot));
  Assert.IsFalse(FRig.World.Machine.CanSubmitTransition(FSlot, WAR_INTERRUPT_AUTONOMOUS));
  Assert.IsTrue(FRig.World.Machine.CanSubmitTransition(FSlot, WAR_INTERRUPT_PLAYER_ORDER));
  Assert.IsTrue(FRig.World.Machine.IsAttacking(FSlot));
  Assert.AreEqual<Integer>(Integer(FRig.Entity(LEnemy)^.Id), Integer(PWarStateAttack(FRig.World.Machine.FindState(FSlot,
    WAR_STATE_ATTACK))^.TargetEntityId));
end;

procedure TTestWarStateMachine.DovrebbeDireVeroPerUnoStackVuoto;
var
  LSlot: Integer;
begin
  LSlot := FRig.World.Entities.CreateDude(WAR_UNIT_FOOTMAN, 5, 5, 0, False);
  Assert.IsTrue(FRig.World.Machine.CanSubmitTransition(LSlot, WAR_INTERRUPT_LIFECYCLE));
  Assert.IsFalse(Assigned(FRig.World.Machine.ActiveState(LSlot)));
end;

procedure TTestWarStateMachine.DovrebbeDareLaRagioneDiUscitaSecondoIlRisultato;
var
  LResults: array[0..6] of Integer;
  LExpected: array[0..6] of Integer;
  LIndex: Integer;
begin
  LResults[0] := WAR_RESULT_SUCCESS;
  LExpected[0] := WAR_EXIT_COMPLETED;
  LResults[1] := WAR_RESULT_CANCELLED;
  LExpected[1] := WAR_EXIT_CANCELLED;
  LResults[2] := WAR_RESULT_TARGET_INVALID;
  LExpected[2] := WAR_EXIT_TARGET_INVALID;
  LResults[3] := WAR_RESULT_TARGET_HIDDEN;
  LExpected[3] := WAR_EXIT_TARGET_INVALID;
  LResults[4] := WAR_RESULT_BLOCKED;
  LExpected[4] := WAR_EXIT_FAILED;
  LResults[5] := WAR_RESULT_CONTAINER_DESTROYED;
  LExpected[5] := WAR_EXIT_CONTAINER_DESTROYED;
  LResults[6] := WAR_RESULT_NONE;
  LExpected[6] := WAR_EXIT_FAILED;
  for LIndex := 0 to 6 do
  begin
    SetLength(GReasons, 0);
    FRig.World.Machine.PushState(FSlot, FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST), WAR_CAUSE_AI_ORDER);
    FRig.Tick;
    FRig.World.Machine.PopState(FSlot, WAR_CAUSE_COMPLETION, LResults[LIndex]);
    FRig.Tick;
    Assert.AreEqual<Integer>(1, Length(GReasons));
    Assert.AreEqual<Integer>(LExpected[LIndex], GReasons[0], Format('risultato %d', [LResults[LIndex]]));
  end;
end;

procedure TTestWarStateMachine.DovrebbeDareLaRagioneDiUscitaPerSostituzioneResetERimozione;
begin
  FRig.World.Machine.PushState(FSlot, FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST), WAR_CAUSE_AI_ORDER);
  FRig.Tick;
  FRig.World.Machine.ReplaceState(FSlot, FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST), WAR_CAUSE_AI_ORDER);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_EXIT_REPLACED, GReasons[0]);
  FRig.World.Machine.ResetState(FSlot, PWarStateBase(FRig.World.Machine.CreateWait(FSlot, 9)), WAR_CAUSE_PLAYER_ORDER);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_EXIT_RESET_BY_COMMAND, GReasons[1]);
  FRig.World.Machine.ResetState(FSlot, FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST), WAR_CAUSE_PLAYER_ORDER);
  FRig.Tick;
  FRig.World.Entities.RemoveEntity(FSlot);
  Assert.AreEqual<Integer>(WAR_EXIT_REMOVED, GReasons[High(GReasons)]);
end;

procedure TTestWarStateMachine.DovrebbeDareLaMorteComeRagioneDelResetDiUnoStatoDiMorte;
begin
  FRig.World.Machine.RegisterHooks(WAR_STATE_DEATH, nil, RecordExit, nil);
  FRig.World.Combat.TakeDamage(FSlot, 255, 255);
  FRig.Tick;
  Assert.IsTrue(FRig.World.Machine.IsDead(FSlot));
  FRig.World.Combat.TakeDamage(FSlot, 255, 255);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_EXIT_ENTITY_DIED, GReasons[0]);
end;

procedure TTestWarStateMachine.DovrebbeLiberareGliStatiInAttesaQuandoUnaEntitaSiTogliendo;
begin
  FRig.World.Machine.PushState(FSlot, FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST), WAR_CAUSE_AI_ORDER);
  Assert.AreEqual<Integer>(1, FRig.World.Context.Storage.ActiveCount[WAR_STATE_CAST]);
  FRig.World.Entities.RemoveEntity(FSlot);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_CAST]);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_IDLE]);
end;

procedure TTestWarStateMachine.DovrebbeSegnareComeAnnullatoUnAcquistoEUscire;
var
  LSlot: Integer;
  LIdle: PWarStateIdle;
begin
  FRig.World.Machine.RegisterHooks(WAR_STATE_BUILD, nil, RecordBuildExit, nil);
  LSlot := FRig.World.Entities.CreateBuilding(WAR_UNIT_FARM_HUMANS, 30, 30, 0, True);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_BUILD, FRig.ActiveType(LSlot));
  Assert.IsTrue(FRig.World.Machine.IsBuilding(LSlot));
  LIdle := FRig.World.Machine.CreateIdle(LSlot, False);
  Assert.IsTrue(FRig.World.Machine.ResetStateForCancellation(LSlot, PWarStateBase(LIdle), WAR_CAUSE_PLAYER_ORDER));
  Assert.IsTrue(FRig.World.Machine.HasPending(LSlot, WAR_STATE_IDLE));
  FRig.Tick;
  Assert.IsTrue(GCancelledAtExit);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LSlot));
  Assert.IsFalse(FRig.World.Machine.IsBuilding(LSlot));
end;

procedure TTestWarStateMachine.DovrebbeTrasformareLAnnullamentoInUnaFineSeLEsitoEGiaDato;
var
  LSlot: Integer;
  LIdle: PWarStateIdle;
begin
  LSlot := FRig.World.Entities.CreateBuilding(WAR_UNIT_FARM_HUMANS, 30, 30, 0, True);
  FRig.Tick;
  PWarStateBuild(FRig.World.Machine.ActiveState(LSlot))^.OutputCommitted := True;
  LIdle := FRig.World.Machine.CreateIdle(LSlot, False);
  Assert.IsTrue(FRig.World.Machine.ResetStateForCancellation(LSlot, PWarStateBase(LIdle), WAR_CAUSE_PLAYER_ORDER));
  FRig.Tick;
  // the build ended as completed and a new default idle took its place; the idle of the request was freed
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LSlot));
  Assert.AreEqual<Integer>(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_BUILD]);
end;

procedure TTestWarStateMachine.DovrebbeRifiutareUnAnnullamentoSenzaAcquisto;
var
  LIdle: PWarStateIdle;
begin
  LIdle := FRig.World.Machine.CreateIdle(FSlot, False);
  Assert.IsFalse(FRig.World.Machine.ResetStateForCancellation(FSlot, PWarStateBase(LIdle), WAR_CAUSE_PLAYER_ORDER));
  Assert.IsFalse(FRig.World.Machine.ResetStateForCancellation(FSlot, nil, WAR_CAUSE_PLAYER_ORDER));
end;

procedure TTestWarStateMachine.DovrebbeTrasformareIlRitardoInUnTempo;
var
  LState: PWarStateBase;
begin
  // the cast state is not updated by anybody: its time is only moved by the delay
  FRig.World.Machine.PushState(FSlot, FRig.World.Machine.AllocState(FSlot, WAR_STATE_CAST), WAR_CAUSE_AI_ORDER);
  FRig.Tick;
  LState := FRig.World.Machine.ActiveState(FSlot);
  LState^.NextUpdateGameTime := 0;
  LState^.Delay := 2;
  Assert.IsFalse(FRig.World.Machine.IsNextUpdateTime(LState));
  Assert.AreEqual<Single>(0, LState^.Delay);
  Assert.IsTrue(LState^.NextUpdateGameTime > FRig.World.Context.Clock^.GameTime);
  FRig.Run(2.5);
  Assert.IsTrue(FRig.World.Machine.IsNextUpdateTime(LState));
end;
procedure TTestWarStateMachine.DovrebbeDireSePrimaDelloStatoCeUnaRichiesta;
begin
  Assert.IsFalse(FRig.World.Machine.IsGoingToDie(FSlot));
  Assert.IsFalse(FRig.World.Machine.IsGoingToCollapse(FSlot));
  Assert.IsFalse(FRig.World.Machine.IsGoingToAttack(FSlot));
  Assert.IsFalse(FRig.World.Machine.IsCollapsing(FSlot));
  FRig.World.Combat.TakeDamage(FSlot, 255, 255);
  Assert.IsTrue(FRig.World.Machine.IsGoingToDie(FSlot));
  Assert.IsFalse(FRig.World.Machine.IsDead(FSlot));
end;

procedure TTestWarStateMachine.DovrebbeRifiutareUnTipoDiStatoFuoriTabella;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.World.Machine.RegisterHooks(WAR_STATE_COUNT, nil, nil, nil);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FRig.World.Machine.Descriptors[-1];
    end, EWarException);
  Assert.AreEqual<Cardinal>(WAR_INTERRUPT_LIFECYCLE, FRig.World.Machine.Descriptors[WAR_STATE_DEATH].DefaultInterruptMask);
  Assert.AreEqual<Cardinal>(0, FRig.World.Machine.Descriptors[WAR_STATE_CAST].DefaultInterruptMask);
end;

procedure TTestWarStateMachine.DovrebbeTrovareUnoStatoNellaPilaDallaCima;
begin
  FRig.World.Machine.PushState(FSlot, PWarStateBase(FRig.World.Machine.CreateWait(FSlot, 5)), WAR_CAUSE_AI_ORDER);
  FRig.Tick;
  Assert.IsTrue(Assigned(FRig.World.Machine.FindState(FSlot, WAR_STATE_IDLE)));
  Assert.IsFalse(Assigned(FRig.World.Machine.FindState(FSlot, WAR_STATE_MOVE)));
  Assert.IsFalse(Assigned(FRig.World.Machine.ActiveStateOfType(FSlot, WAR_STATE_IDLE)));
  Assert.IsTrue(Assigned(FRig.World.Machine.ActiveStateOfType(FSlot, WAR_STATE_WAIT)));
end;

end.
