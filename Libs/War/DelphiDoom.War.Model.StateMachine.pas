{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the state machine of the units                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine.c (the stack of states, the  }
{  deferred transitions, the queries and the table of descriptors),            }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Libs\War\LICENSE-war1.txt). This is an altered version.                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.StateMachine;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.Context;

type
  TWarStateMachine = class;

  /// <summary>onEnter of a descriptor: the entity is the slot in the pool</summary>
  TWarStateEnterHook = procedure(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
  /// <summary>onExit of a descriptor</summary>
  TWarStateExitHook = procedure(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer);
  /// <summary>The loop of the update of all the states of one type (wst_updateIdleStates, ...)</summary>
  TWarStateUpdateAll = procedure(AMachine: TWarStateMachine);

  /// <summary>
  ///   WarStateDescriptor: what a type of state does. The table is the registry of the states in place of a big case:
  ///   the machine calls a procedure by the type of the state, once per transition (enter and exit) or once per
  ///   tic and type (the update: the loop over the states of that type is inside the procedure, so there is no call
  ///   through the table for each unit). A type without a procedure does nothing: its states are created and stay as
  ///   they are (the states of the original that are not ported yet are registered with the mask only)
  /// </summary>
  TWarStateDescriptor = record
    OnEnter: TWarStateEnterHook;
    OnExit: TWarStateExitHook;
    UpdateAll: TWarStateUpdateAll;
    /// <summary>The kinds of interruption (WAR_INTERRUPT_*) that the state accepts</summary>
    DefaultInterruptMask: Cardinal;
  end;

  /// <summary>
  ///   The stack of states of every entity (at most 4: the last is the active one) and the requests of change that
  ///   wait for the next tic (one for entity, the one with the higher cause wins). Everything that the original does in
  ///   war_state_machine.c except the states themselves
  /// </summary>
  TWarStateMachine = class
  strict private
    FContext: TWarModelContext;
    FDescriptors: array[0..WAR_STATE_COUNT - 1] of TWarStateDescriptor;
    function Machine(ASlot: Integer): PWarStateMachineComponent; inline;
    function StateRefsEqual(const A, B: TWarStateRef): Boolean; inline;
    function OperationHasState(AOperation: Integer): Boolean; inline;
    function IsTransactionalType(AType: Integer): Boolean; inline;
    function IsCauseValid(ACause: Integer): Boolean;
    function IsRefOnMachineStack(AMachine: PWarStateMachineComponent; const ARef: TWarStateRef): Boolean;
    function IsRefOnStack(const ARef: TWarStateRef): Boolean;
    function IsRefPendingElsewhere(AOwner: PWarStateMachineComponent; const ARef: TWarStateRef): Boolean;
    function IsRefOwned(const ARef: TWarStateRef): Boolean;
    procedure FreeUnownedRef(const ARef: TWarStateRef);
    procedure FreeUnownedTransitionRefs(const ARequest: TWarTransitionRequest);
    function ShouldReplacePending(const APending, ARequest: TWarTransitionRequest): Boolean;
    function IsCancellationTargetValid(ASlot: Integer; AMachine: PWarStateMachineComponent;
      const ARequest: TWarTransitionRequest): Boolean;
    function IsRequestValid(ASlot: Integer; AMachine: PWarStateMachineComponent;
      const ARequest: TWarTransitionRequest): Boolean;
    function FindCancellationTarget(AMachine: PWarStateMachineComponent): TWarStateRef;
    function SetDefaultIdle(ASlot: Integer; AMachine: PWarStateMachineComponent): TWarStateRef;
    function CommitCancellation(ASlot: Integer; AMachine: PWarStateMachineComponent;
      const ARequest: TWarTransitionRequest): Boolean;
    procedure ResolveCommittedBuildCancellation(AMachine: PWarStateMachineComponent;
      var ARequest: TWarTransitionRequest);
    function ExitReasonOf(AResult: Integer): Integer;
    function GetDescriptor(AType: Integer): TWarStateDescriptor;
  public
    constructor Create(const AContext: TWarModelContext);
    /// <summary>Sets what a type of state does (the table of stateDescriptors); the mask of interruptions stays the one of the original</summary>
    procedure RegisterHooks(AType: Integer; AOnEnter: TWarStateEnterHook; AOnExit: TWarStateExitHook;
      AUpdateAll: TWarStateUpdateAll);
    property Context: TWarModelContext read FContext;
    property Descriptors[AType: Integer]: TWarStateDescriptor read GetDescriptor;

    /// <summary>wst_allocState + wst_deref: a new zeroed state for the entity, nil if the storage of that type is full</summary>
    function AllocState(ASlot: Integer; AType: Integer): PWarStateBase;
    /// <summary>wst_createIdleState</summary>
    function CreateIdle(ASlot: Integer; ALookAround: Boolean): PWarStateIdle;
    /// <summary>wst_createMoveState: at most 64 waypoints (the first is where the unit is now)</summary>
    function CreateMove(ASlot: Integer; const APositions: array of TWarVec2; ACheckForAttacks: Boolean): PWarStateMove;
    /// <summary>wst_createDeathState</summary>
    function CreateDeath(ASlot: Integer): PWarStateDeath;
    /// <summary>wst_createWaitState: waits until the game time is now plus ATime</summary>
    function CreateWait(ASlot: Integer; ATime: Single): PWarStateWait;
    /// <summary>wst_createAttackState</summary>
    function CreateAttack(ASlot: Integer; ATargetId: Word; const ATargetPosition: TWarVec2): PWarStateAttack;
    /// <summary>wst_createCollapseState</summary>
    function CreateCollapse(ASlot: Integer): PWarStateBase;
    /// <summary>wst_createBuildState: paid already (the cost is the one stored)</summary>
    function CreateBuild(ASlot: Integer; ABuildTime: Single; AGoldCost, AWoodCost: Integer): PWarStateBase;
    /// <summary>wst_freeStateRef: frees a state that no stack and no request holds</summary>
    procedure FreeStateRef(const ARef: TWarStateRef);

    /// <summary>wst_canSubmitTransition: the active state accepts that kind of interruption</summary>
    function CanSubmitTransition(ASlot: Integer; AInterrupt: Integer): Boolean;
    /// <summary>wst_submitTransition: False if the request is not valid or a request with a higher cause waits already</summary>
    function SubmitTransition(ASlot: Integer; ARequest: TWarTransitionRequest): Boolean;
    function PushState(ASlot: Integer; AState: PWarStateBase; ACause: Integer): Boolean;
    function PopState(ASlot: Integer; ACause, AResult: Integer): Boolean;
    function ReplaceState(ASlot: Integer; AState: PWarStateBase; ACause: Integer): Boolean;
    function ResetState(ASlot: Integer; AState: PWarStateBase; ACause: Integer): Boolean;
    function ResetStateForCancellation(ASlot: Integer; AState: PWarStateBase; ACause: Integer): Boolean;
    /// <summary>wst_processPendingTransitions: the requests of all the entities, in the order of the slots</summary>
    procedure ProcessPendingTransitions;
    /// <summary>
    ///   The updates of the states: the update of every type that has one, in the order of the types (the order
    ///   of the calls in wmap_updateMap)
    /// </summary>
    procedure UpdateStates;

    /// <summary>wst_enterState, wst_exitState: the hook of the descriptor; exit also frees the state</summary>
    procedure EnterState(ASlot: Integer; AState: PWarStateBase);
    procedure ExitState(ASlot: Integer; AState: PWarStateBase; AReason: Integer);
    /// <summary>The part of we_removeStateMachineComponent that leaves the states: top to bottom, and the pending ones freed</summary>
    procedure TearDown(ASlot: Integer);

    /// <summary>wst_getActiveState: the top of the stack</summary>
    function ActiveState(ASlot: Integer): PWarStateBase;
    function ActiveStateOfType(ASlot, AType: Integer): PWarStateBase;
    /// <summary>wst_findStateInStack: the first state of the type from the top</summary>
    function FindState(ASlot, AType: Integer): PWarStateBase;
    function IsActive(ASlot, AType: Integer): Boolean; inline;
    function Contains(ASlot, AType: Integer): Boolean; inline;
    /// <summary>wst_hasPendingState: the request that waits is for a state of that type</summary>
    function HasPending(ASlot, AType: Integer): Boolean;
    /// <summary>wst_isNextUpdateTime: it is time to update the state (the delay becomes a time)</summary>
    function IsNextUpdateTime(AState: PWarStateBase): Boolean; inline;
    function IsDead(ASlot: Integer): Boolean; inline;
    function IsGoingToDie(ASlot: Integer): Boolean; inline;
    function IsCollapsing(ASlot: Integer): Boolean; inline;
    function IsGoingToCollapse(ASlot: Integer): Boolean; inline;
    function IsBuilding(ASlot: Integer): Boolean; inline;
    function IsGoingToBuild(ASlot: Integer): Boolean; inline;
    function IsGoingToAttack(ASlot: Integer): Boolean; inline;
    function IsAttacking(ASlot: Integer): Boolean; inline;
  end;

implementation

{ TWarStateMachine }

constructor TWarStateMachine.Create(const AContext: TWarModelContext);
var
  LType: Integer;
begin
  inherited Create;
  FContext := AContext;
  // the masks of stateDescriptors; the hooks are given by RegisterState
  for LType := 0 to WAR_STATE_COUNT - 1 do
    FDescriptors[LType].DefaultInterruptMask := WAR_INTERRUPT_ALL;
  FDescriptors[WAR_STATE_ATTACK].DefaultInterruptMask := WAR_INTERRUPT_PLAYER_ORDER or WAR_INTERRUPT_AI_ORDER or
    WAR_INTERRUPT_STATUS or WAR_INTERRUPT_SCRIPT or WAR_INTERRUPT_LIFECYCLE;
  FDescriptors[WAR_STATE_DEATH].DefaultInterruptMask := WAR_INTERRUPT_LIFECYCLE;
  FDescriptors[WAR_STATE_COLLAPSE].DefaultInterruptMask := WAR_INTERRUPT_LIFECYCLE;
  FDescriptors[WAR_STATE_TRAIN].DefaultInterruptMask := WAR_INTERRUPT_PLAYER_ORDER or WAR_INTERRUPT_AI_ORDER or
    WAR_INTERRUPT_LIFECYCLE;
  FDescriptors[WAR_STATE_UPGRADE].DefaultInterruptMask := WAR_INTERRUPT_PLAYER_ORDER or WAR_INTERRUPT_AI_ORDER or
    WAR_INTERRUPT_LIFECYCLE;
  FDescriptors[WAR_STATE_BUILD].DefaultInterruptMask := WAR_INTERRUPT_PLAYER_ORDER or WAR_INTERRUPT_AI_ORDER or
    WAR_INTERRUPT_STATUS or WAR_INTERRUPT_SCRIPT or WAR_INTERRUPT_LIFECYCLE;
  FDescriptors[WAR_STATE_CAST].DefaultInterruptMask := 0;
end;

procedure TWarStateMachine.RegisterHooks(AType: Integer; AOnEnter: TWarStateEnterHook; AOnExit: TWarStateExitHook;
  AUpdateAll: TWarStateUpdateAll);
begin
  if (AType < 0) or (AType >= WAR_STATE_COUNT) then
    raise EWarException.CreateFmt(SWarModelBadState, [AType]);
  FDescriptors[AType].OnEnter := AOnEnter;
  FDescriptors[AType].OnExit := AOnExit;
  FDescriptors[AType].UpdateAll := AUpdateAll;
end;

function TWarStateMachine.GetDescriptor(AType: Integer): TWarStateDescriptor;
begin
  if (AType < 0) or (AType >= WAR_STATE_COUNT) then
    raise EWarException.CreateFmt(SWarModelBadState, [AType]);
  Result := FDescriptors[AType];
end;

function TWarStateMachine.Machine(ASlot: Integer): PWarStateMachineComponent;
begin
  Result := @FContext.Pool.Slots[ASlot].StateMachine;
end;

function TWarStateMachine.StateRefsEqual(const A, B: TWarStateRef): Boolean;
begin
  Result := TWarStateRefs.Equal(A, B);
end;

function TWarStateMachine.OperationHasState(AOperation: Integer): Boolean;
begin
  Result := (AOperation = WAR_OP_PUSH) or (AOperation = WAR_OP_REPLACE) or (AOperation = WAR_OP_RESET);
end;

function TWarStateMachine.IsTransactionalType(AType: Integer): Boolean;
begin
  Result := (AType = WAR_STATE_TRAIN) or (AType = WAR_STATE_UPGRADE) or (AType = WAR_STATE_BUILD);
end;

function TWarStateMachine.IsCauseValid(ACause: Integer): Boolean;
begin
  Result := ACause in [WAR_CAUSE_INITIALIZATION, WAR_CAUSE_COMPLETION, WAR_CAUSE_AUTONOMOUS, WAR_CAUSE_AI_ORDER,
    WAR_CAUSE_PLAYER_ORDER, WAR_CAUSE_STATUS, WAR_CAUSE_SCRIPT, WAR_CAUSE_LIFECYCLE];
end;

function TWarStateMachine.IsRefOnMachineStack(AMachine: PWarStateMachineComponent; const ARef: TWarStateRef): Boolean;
var
  LDepth: Integer;
  LIndex: Integer;
begin
  LDepth := AMachine^.Depth;
  if LDepth > WAR_MODEL_STATE_STACK_DEPTH then
    LDepth := WAR_MODEL_STATE_STACK_DEPTH;
  for LIndex := 0 to LDepth - 1 do
    if StateRefsEqual(AMachine^.Stack[LIndex], ARef) then
      Exit(True);
  Result := False;
end;

function TWarStateMachine.IsRefOnStack(const ARef: TWarStateRef): Boolean;
var
  LSlot: Integer;
  LEntity: PWarEntity;
begin
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
  begin
    LEntity := FContext.Pool.Slots[LSlot];
    if LEntity^.HasStateMachine and IsRefOnMachineStack(@LEntity^.StateMachine, ARef) then
      Exit(True);
  end;
  Result := False;
end;

function TWarStateMachine.IsRefPendingElsewhere(AOwner: PWarStateMachineComponent; const ARef: TWarStateRef): Boolean;
var
  LSlot: Integer;
  LEntity: PWarEntity;
begin
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
  begin
    LEntity := FContext.Pool.Slots[LSlot];
    if LEntity^.HasStateMachine and (@LEntity^.StateMachine <> AOwner) and
      (LEntity^.StateMachine.Pending.Operation <> WAR_OP_NONE) and
      (StateRefsEqual(LEntity^.StateMachine.Pending.StateRef, ARef) or
       StateRefsEqual(LEntity^.StateMachine.Pending.CancellationTargetRef, ARef)) then
      Exit(True);
  end;
  Result := False;
end;

function TWarStateMachine.IsRefOwned(const ARef: TWarStateRef): Boolean;
var
  LSlot: Integer;
  LEntity: PWarEntity;
begin
  if IsRefOnStack(ARef) then
    Exit(True);
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
  begin
    LEntity := FContext.Pool.Slots[LSlot];
    if LEntity^.HasStateMachine and (LEntity^.StateMachine.Pending.Operation <> WAR_OP_NONE) and
      (StateRefsEqual(LEntity^.StateMachine.Pending.StateRef, ARef) or
       StateRefsEqual(LEntity^.StateMachine.Pending.CancellationTargetRef, ARef)) then
      Exit(True);
  end;
  Result := False;
end;

procedure TWarStateMachine.FreeStateRef(const ARef: TWarStateRef);
begin
  if not IsRefOwned(ARef) then
    FContext.Storage.Release(ARef);
end;

procedure TWarStateMachine.FreeUnownedRef(const ARef: TWarStateRef);
begin
  if not Assigned(FContext.Storage.Deref(ARef)) or IsRefOwned(ARef) then
    Exit;
  FContext.Storage.Release(ARef);
end;

procedure TWarStateMachine.FreeUnownedTransitionRefs(const ARequest: TWarTransitionRequest);
begin
  FreeUnownedRef(ARequest.StateRef);
  if not StateRefsEqual(ARequest.CancellationTargetRef, ARequest.StateRef) then
    FreeUnownedRef(ARequest.CancellationTargetRef);
end;

function TWarStateMachine.ShouldReplacePending(const APending, ARequest: TWarTransitionRequest): Boolean;
var
  LPendingHasState: Boolean;
  LPendingIsTransactional: Boolean;
begin
  if APending.Operation = WAR_OP_NONE then
    Exit(True);
  if ARequest.Cause <> APending.Cause then
    Exit(ARequest.Cause > APending.Cause);
  LPendingHasState := OperationHasState(APending.Operation);
  LPendingIsTransactional := IsTransactionalType(APending.StateRef.StateType);
  // a player can cancel the exact transaction that its earlier order would commit
  Result := (ARequest.Cause = WAR_CAUSE_PLAYER_ORDER) and ARequest.Cancellation and LPendingHasState and
    LPendingIsTransactional and StateRefsEqual(ARequest.CancellationTargetRef, APending.StateRef);
end;

function TWarStateMachine.IsCancellationTargetValid(ASlot: Integer; AMachine: PWarStateMachineComponent;
  const ARequest: TWarTransitionRequest): Boolean;
var
  LTarget: PWarStateBase;
begin
  if not ARequest.Cancellation then
    Exit(not TWarStateRefs.IsValid(ARequest.CancellationTargetRef));
  if (ARequest.Operation <> WAR_OP_RESET) or not TWarStateRefs.IsValid(ARequest.CancellationTargetRef) or
    not IsTransactionalType(ARequest.CancellationTargetRef.StateType) or
    StateRefsEqual(ARequest.StateRef, ARequest.CancellationTargetRef) then
    Exit(False);
  LTarget := FContext.Storage.Deref(ARequest.CancellationTargetRef);
  if not Assigned(LTarget) or (LTarget^.EntityId <> FContext.Pool.Slots[ASlot]^.Id) then
    Exit(False);
  Result := IsRefOnMachineStack(AMachine, ARequest.CancellationTargetRef) or
    StateRefsEqual(AMachine^.Pending.StateRef, ARequest.CancellationTargetRef) or
    StateRefsEqual(AMachine^.Pending.CancellationTargetRef, ARequest.CancellationTargetRef);
end;

function TWarStateMachine.IsRequestValid(ASlot: Integer; AMachine: PWarStateMachineComponent;
  const ARequest: TWarTransitionRequest): Boolean;
var
  LState: PWarStateBase;
begin
  if not IsCauseValid(ARequest.Cause) then
    Exit(False);
  if not IsCancellationTargetValid(ASlot, AMachine, ARequest) then
    Exit(False);
  if ARequest.Operation = WAR_OP_POP then
    Exit(StateRefsEqual(ARequest.StateRef, TWarStateRefs.Invalid));
  if not OperationHasState(ARequest.Operation) then
    Exit(False);
  LState := FContext.Storage.Deref(ARequest.StateRef);
  if not Assigned(LState) or (LState^.EntityId <> FContext.Pool.Slots[ASlot]^.Id) then
    Exit(False);
  if IsRefOnStack(ARequest.StateRef) then
    Exit(False);
  Result := not IsRefPendingElsewhere(AMachine, ARequest.StateRef);
end;

function TWarStateMachine.CanSubmitTransition(ASlot: Integer; AInterrupt: Integer): Boolean;
var
  LMachine: PWarStateMachineComponent;
  LActiveRef: TWarStateRef;
begin
  if (ASlot <= 0) or not FContext.Pool.Slots[ASlot]^.HasStateMachine then
    Exit(False);
  LMachine := Machine(ASlot);
  if LMachine^.Depth > WAR_MODEL_STATE_STACK_DEPTH then
    Exit(False);
  if LMachine^.Depth = 0 then
    Exit(True);
  LActiveRef := LMachine^.Stack[LMachine^.Depth - 1];
  if not Assigned(FContext.Storage.Deref(LActiveRef)) then
    Exit(False);
  Result := (FDescriptors[LActiveRef.StateType].DefaultInterruptMask and Cardinal(AInterrupt)) <> 0;
end;

function TWarStateMachine.SubmitTransition(ASlot: Integer; ARequest: TWarTransitionRequest): Boolean;
var
  LMachine: PWarStateMachineComponent;
  LReplaced: TWarTransitionRequest;
begin
  if (ASlot <= 0) or not FContext.Pool.Slots[ASlot]^.HasStateMachine then
  begin
    FreeUnownedTransitionRefs(ARequest);
    Exit(False);
  end;
  LMachine := Machine(ASlot);
  if not IsRequestValid(ASlot, LMachine, ARequest) then
  begin
    FreeUnownedTransitionRefs(ARequest);
    Exit(False);
  end;
  ARequest.Sequence := LMachine^.NextTransitionSequence;
  Inc(LMachine^.NextTransitionSequence);
  if ShouldReplacePending(LMachine^.Pending, ARequest) then
  begin
    LReplaced := LMachine^.Pending;
    LMachine^.Pending := ARequest;
    FreeUnownedTransitionRefs(LReplaced);
    Exit(True);
  end;
  FreeUnownedTransitionRefs(ARequest);
  Result := False;
end;

function TWarStateMachine.PushState(ASlot: Integer; AState: PWarStateBase; ACause: Integer): Boolean;
var
  LRequest: TWarTransitionRequest;
begin
  if not Assigned(AState) then
    Exit(False);
  LRequest := Default(TWarTransitionRequest);
  LRequest.StateRef := FContext.Storage.RefOf(AState);
  LRequest.CancellationTargetRef := TWarStateRefs.Invalid;
  LRequest.Operation := WAR_OP_PUSH;
  LRequest.Cause := ACause;
  Result := SubmitTransition(ASlot, LRequest);
end;

function TWarStateMachine.PopState(ASlot: Integer; ACause, AResult: Integer): Boolean;
var
  LRequest: TWarTransitionRequest;
begin
  LRequest := Default(TWarTransitionRequest);
  LRequest.StateRef := TWarStateRefs.Invalid;
  LRequest.CancellationTargetRef := TWarStateRefs.Invalid;
  LRequest.Operation := WAR_OP_POP;
  LRequest.Cause := ACause;
  LRequest.Result := AResult;
  Result := SubmitTransition(ASlot, LRequest);
end;

function TWarStateMachine.ReplaceState(ASlot: Integer; AState: PWarStateBase; ACause: Integer): Boolean;
var
  LRequest: TWarTransitionRequest;
begin
  if not Assigned(AState) then
    Exit(False);
  LRequest := Default(TWarTransitionRequest);
  LRequest.StateRef := FContext.Storage.RefOf(AState);
  LRequest.CancellationTargetRef := TWarStateRefs.Invalid;
  LRequest.Operation := WAR_OP_REPLACE;
  LRequest.Cause := ACause;
  Result := SubmitTransition(ASlot, LRequest);
end;

function TWarStateMachine.ResetState(ASlot: Integer; AState: PWarStateBase; ACause: Integer): Boolean;
var
  LRequest: TWarTransitionRequest;
begin
  if not Assigned(AState) then
    Exit(False);
  LRequest := Default(TWarTransitionRequest);
  LRequest.StateRef := FContext.Storage.RefOf(AState);
  LRequest.CancellationTargetRef := TWarStateRefs.Invalid;
  LRequest.Operation := WAR_OP_RESET;
  LRequest.Cause := ACause;
  Result := SubmitTransition(ASlot, LRequest);
end;

function TWarStateMachine.FindCancellationTarget(AMachine: PWarStateMachineComponent): TWarStateRef;
var
  LDepth: Integer;
  LIndex: Integer;
  LRef: TWarStateRef;
begin
  LDepth := AMachine^.Depth;
  if LDepth > WAR_MODEL_STATE_STACK_DEPTH then
    LDepth := WAR_MODEL_STATE_STACK_DEPTH;
  for LIndex := LDepth - 1 downto 0 do
  begin
    LRef := AMachine^.Stack[LIndex];
    if IsTransactionalType(LRef.StateType) and Assigned(FContext.Storage.Deref(LRef)) then
      Exit(LRef);
  end;
  if OperationHasState(AMachine^.Pending.Operation) and IsTransactionalType(AMachine^.Pending.StateRef.StateType) and
    Assigned(FContext.Storage.Deref(AMachine^.Pending.StateRef)) then
    Exit(AMachine^.Pending.StateRef);
  if AMachine^.Pending.Cancellation and IsTransactionalType(AMachine^.Pending.CancellationTargetRef.StateType) and
    Assigned(FContext.Storage.Deref(AMachine^.Pending.CancellationTargetRef)) then
    Exit(AMachine^.Pending.CancellationTargetRef);
  Result := TWarStateRefs.Invalid;
end;

function TWarStateMachine.ResetStateForCancellation(ASlot: Integer; AState: PWarStateBase; ACause: Integer): Boolean;
var
  LRequest: TWarTransitionRequest;
begin
  if not Assigned(AState) then
    Exit(False);
  if (ASlot <= 0) or not FContext.Pool.Slots[ASlot]^.HasStateMachine then
  begin
    FreeStateRef(FContext.Storage.RefOf(AState));
    Exit(False);
  end;
  LRequest := Default(TWarTransitionRequest);
  LRequest.StateRef := FContext.Storage.RefOf(AState);
  LRequest.CancellationTargetRef := FindCancellationTarget(Machine(ASlot));
  LRequest.Operation := WAR_OP_RESET;
  LRequest.Cause := ACause;
  LRequest.Cancellation := True;
  Result := SubmitTransition(ASlot, LRequest);
end;

function TWarStateMachine.ActiveState(ASlot: Integer): PWarStateBase;
var
  LMachine: PWarStateMachineComponent;
begin
  Result := nil;
  if (ASlot <= 0) or not FContext.Pool.Slots[ASlot]^.HasStateMachine then
    Exit;
  LMachine := Machine(ASlot);
  if LMachine^.Depth = 0 then
    Exit;
  Result := FContext.Storage.Deref(LMachine^.Stack[LMachine^.Depth - 1]);
end;

function TWarStateMachine.ActiveStateOfType(ASlot, AType: Integer): PWarStateBase;
var
  LMachine: PWarStateMachineComponent;
begin
  Result := nil;
  LMachine := Machine(ASlot);
  if (LMachine^.Depth > 0) and (LMachine^.Stack[LMachine^.Depth - 1].StateType = AType) then
    Result := FContext.Storage.Deref(LMachine^.Stack[LMachine^.Depth - 1]);
end;

function TWarStateMachine.FindState(ASlot, AType: Integer): PWarStateBase;
var
  LMachine: PWarStateMachineComponent;
  LIndex: Integer;
begin
  LMachine := Machine(ASlot);
  for LIndex := LMachine^.Depth - 1 downto 0 do
    if LMachine^.Stack[LIndex].StateType = AType then
      Exit(FContext.Storage.Deref(LMachine^.Stack[LIndex]));
  Result := nil;
end;

function TWarStateMachine.IsActive(ASlot, AType: Integer): Boolean;
begin
  Result := Assigned(ActiveStateOfType(ASlot, AType));
end;

function TWarStateMachine.Contains(ASlot, AType: Integer): Boolean;
begin
  Result := Assigned(FindState(ASlot, AType));
end;

function TWarStateMachine.HasPending(ASlot, AType: Integer): Boolean;
var
  LPending: PWarTransitionRequest;
begin
  LPending := @Machine(ASlot)^.Pending;
  Result := OperationHasState(LPending^.Operation) and (LPending^.StateRef.StateType = AType) and
    Assigned(FContext.Storage.Deref(LPending^.StateRef));
end;

function TWarStateMachine.IsNextUpdateTime(AState: PWarStateBase): Boolean;
begin
  if AState^.Delay > 0 then
  begin
    AState^.NextUpdateGameTime := FContext.Clock^.GameTime + AState^.Delay;
    AState^.Delay := 0;
  end;
  Result := FContext.Clock^.GameTime >= AState^.NextUpdateGameTime;
end;

function TWarStateMachine.IsDead(ASlot: Integer): Boolean;
begin
  Result := Contains(ASlot, WAR_STATE_DEATH);
end;

function TWarStateMachine.IsGoingToDie(ASlot: Integer): Boolean;
begin
  Result := HasPending(ASlot, WAR_STATE_DEATH);
end;

function TWarStateMachine.IsCollapsing(ASlot: Integer): Boolean;
begin
  Result := Contains(ASlot, WAR_STATE_COLLAPSE);
end;

function TWarStateMachine.IsGoingToCollapse(ASlot: Integer): Boolean;
begin
  Result := HasPending(ASlot, WAR_STATE_COLLAPSE);
end;

function TWarStateMachine.IsBuilding(ASlot: Integer): Boolean;
begin
  Result := Contains(ASlot, WAR_STATE_BUILD);
end;

function TWarStateMachine.IsGoingToBuild(ASlot: Integer): Boolean;
begin
  Result := HasPending(ASlot, WAR_STATE_BUILD);
end;

function TWarStateMachine.IsGoingToAttack(ASlot: Integer): Boolean;
begin
  Result := HasPending(ASlot, WAR_STATE_ATTACK);
end;

function TWarStateMachine.IsAttacking(ASlot: Integer): Boolean;
begin
  Result := Contains(ASlot, WAR_STATE_ATTACK);
end;

function TWarStateMachine.AllocState(ASlot: Integer; AType: Integer): PWarStateBase;
var
  LRef: TWarStateRef;
begin
  LRef := FContext.Storage.Alloc(AType, FContext.Pool.Slots[ASlot]^.Id);
  if not TWarStateRefs.IsValid(LRef) then
    Exit(nil);
  Result := FContext.Storage.Deref(LRef);
end;

function TWarStateMachine.CreateIdle(ASlot: Integer; ALookAround: Boolean): PWarStateIdle;
begin
  Result := PWarStateIdle(AllocState(ASlot, WAR_STATE_IDLE));
  if Assigned(Result) then
    Result^.LookAround := ALookAround;
end;

function TWarStateMachine.CreateMove(ASlot: Integer; const APositions: array of TWarVec2;
  ACheckForAttacks: Boolean): PWarStateMove;
var
  LCount: Integer;
  LIndex: Integer;
begin
  Result := PWarStateMove(AllocState(ASlot, WAR_STATE_MOVE));
  if not Assigned(Result) then
    Exit;
  LCount := System.Length(APositions);
  if LCount > WAR_MODEL_MAX_WAYPOINTS then
    LCount := WAR_MODEL_MAX_WAYPOINTS;
  for LIndex := 0 to LCount - 1 do
    Result^.Waypoints[LIndex] := APositions[LIndex];
  Result^.WaypointsIndex := 0;
  Result^.WaypointsCount := LCount;
  Result^.CheckForAttacks := ACheckForAttacks;
end;

function TWarStateMachine.CreateDeath(ASlot: Integer): PWarStateDeath;
begin
  Result := PWarStateDeath(AllocState(ASlot, WAR_STATE_DEATH));
end;

function TWarStateMachine.CreateWait(ASlot: Integer; ATime: Single): PWarStateWait;
begin
  Result := PWarStateWait(AllocState(ASlot, WAR_STATE_WAIT));
  if Assigned(Result) then
    Result^.WaitEndGameTime := FContext.Clock^.GameTime + ATime;
end;

function TWarStateMachine.CreateAttack(ASlot: Integer; ATargetId: Word; const ATargetPosition: TWarVec2): PWarStateAttack;
begin
  Result := PWarStateAttack(AllocState(ASlot, WAR_STATE_ATTACK));
  if Assigned(Result) then
  begin
    Result^.TargetEntityId := ATargetId;
    Result^.TargetPosition := ATargetPosition;
  end;
end;

function TWarStateMachine.CreateCollapse(ASlot: Integer): PWarStateBase;
begin
  Result := AllocState(ASlot, WAR_STATE_COLLAPSE);
end;

function TWarStateMachine.CreateBuild(ASlot: Integer; ABuildTime: Single; AGoldCost, AWoodCost: Integer): PWarStateBase;
var
  LBuild: PWarStateBuild;
begin
  Result := AllocState(ASlot, WAR_STATE_BUILD);
  if not Assigned(Result) then
    Exit;
  LBuild := PWarStateBuild(Result);
  LBuild^.WorkerId := 0;
  LBuild^.BuildTime := 0;
  LBuild^.TotalBuildTime := ABuildTime;
  LBuild^.GoldCost := AGoldCost;
  LBuild^.WoodCost := AWoodCost;
  LBuild^.TransactionApplied := True;
end;

procedure TWarStateMachine.EnterState(ASlot: Integer; AState: PWarStateBase);
begin
  if not Assigned(AState) then
    Exit;
  if (AState^.StateType < WAR_STATE_IDLE) or (AState^.StateType >= WAR_STATE_COUNT) then
    Exit;
  if not TWarStateRefs.IsValid(FContext.Storage.RefOf(AState)) then
    Exit;
  if Assigned(FDescriptors[AState^.StateType].OnEnter) then
    FDescriptors[AState^.StateType].OnEnter(Self, ASlot, AState);
end;

procedure TWarStateMachine.ExitState(ASlot: Integer; AState: PWarStateBase; AReason: Integer);
var
  LRef: TWarStateRef;
begin
  if not Assigned(AState) then
    Exit;
  if (AState^.StateType < WAR_STATE_IDLE) or (AState^.StateType >= WAR_STATE_COUNT) then
    Exit;
  LRef := FContext.Storage.RefOf(AState);
  if not TWarStateRefs.IsValid(LRef) then
    Exit;
  if Assigned(FDescriptors[AState^.StateType].OnExit) then
    FDescriptors[AState^.StateType].OnExit(Self, ASlot, AState, AReason);
  FContext.Storage.Release(LRef);
end;

function TWarStateMachine.SetDefaultIdle(ASlot: Integer; AMachine: PWarStateMachineComponent): TWarStateRef;
var
  LIdle: PWarStateIdle;
begin
  LIdle := CreateIdle(ASlot, True);
  if not Assigned(LIdle) then
    Exit(TWarStateRefs.Invalid);
  Result := FContext.Storage.RefOf(PWarStateBase(LIdle));
  if not TWarStateRefs.IsValid(Result) then
    Exit(TWarStateRefs.Invalid);
  AMachine^.Stack[0] := Result;
  AMachine^.Depth := 1;
end;

function TWarStateMachine.CommitCancellation(ASlot: Integer; AMachine: PWarStateMachineComponent;
  const ARequest: TWarTransitionRequest): Boolean;
var
  LTarget: PWarStateBase;
begin
  if not ARequest.Cancellation then
    Exit(True);
  LTarget := FContext.Storage.Deref(ARequest.CancellationTargetRef);
  if not Assigned(LTarget) or (LTarget^.EntityId <> FContext.Pool.Slots[ASlot]^.Id) or
    not IsTransactionalType(LTarget^.StateType) then
    Exit(False);
  case LTarget^.StateType of
    WAR_STATE_TRAIN: PWarStateTrain(LTarget)^.Cancelled := True;
    WAR_STATE_UPGRADE: PWarStateUpgrade(LTarget)^.Cancelled := True;
    WAR_STATE_BUILD: PWarStateBuild(LTarget)^.Cancelled := True;
  else
    Exit(False);
  end;
  if not IsRefOnMachineStack(AMachine, ARequest.CancellationTargetRef) then
    ExitState(ASlot, LTarget, WAR_EXIT_CANCELLED);
  Result := True;
end;

procedure TWarStateMachine.ResolveCommittedBuildCancellation(AMachine: PWarStateMachineComponent;
  var ARequest: TWarTransitionRequest);
var
  LBuild: PWarStateBuild;
  LOutcomeRef: TWarStateRef;
begin
  if not ARequest.Cancellation or (ARequest.CancellationTargetRef.StateType <> WAR_STATE_BUILD) or
    not IsRefOnMachineStack(AMachine, ARequest.CancellationTargetRef) then
    Exit;
  LBuild := PWarStateBuild(FContext.Storage.Deref(ARequest.CancellationTargetRef));
  if not Assigned(LBuild) or not LBuild^.OutputCommitted then
    Exit;
  LOutcomeRef := ARequest.StateRef;
  ARequest.StateRef := TWarStateRefs.Invalid;
  ARequest.CancellationTargetRef := TWarStateRefs.Invalid;
  ARequest.Operation := WAR_OP_POP;
  ARequest.Cause := WAR_CAUSE_COMPLETION;
  ARequest.Cancellation := False;
  FreeUnownedRef(LOutcomeRef);
end;

function TWarStateMachine.ExitReasonOf(AResult: Integer): Integer;
begin
  case AResult of
    WAR_RESULT_SUCCESS: Result := WAR_EXIT_COMPLETED;
    WAR_RESULT_CANCELLED: Result := WAR_EXIT_CANCELLED;
    WAR_RESULT_TARGET_INVALID, WAR_RESULT_TARGET_HIDDEN: Result := WAR_EXIT_TARGET_INVALID;
    WAR_RESULT_CONTAINER_DESTROYED: Result := WAR_EXIT_CONTAINER_DESTROYED;
  else
    Result := WAR_EXIT_FAILED;
  end;
end;

procedure TWarStateMachine.ProcessPendingTransitions;
var
  LSlot: Integer;
  LEntity: PWarEntity;
  LMachine: PWarStateMachineComponent;
  LRequest: TWarTransitionRequest;
  LCandidate: PWarStateBase;
  LTop: PWarStateBase;
  LNewTop: PWarStateBase;
  LDepth: Integer;
  LIdleRef: TWarStateRef;
  LState: PWarStateBase;
  LExitReason: Integer;
begin
  for LSlot := 0 to WAR_MODEL_MAX_ENTITIES - 1 do
  begin
    LEntity := FContext.Pool.Slots[LSlot];
    if (LEntity^.Id = 0) or not LEntity^.HasStateMachine then
      Continue;
    LMachine := @LEntity^.StateMachine;
    if LMachine^.Pending.Operation = WAR_OP_NONE then
      Continue;
    LRequest := LMachine^.Pending;
    LMachine^.Pending := Default(TWarTransitionRequest);
    LMachine^.Pending.StateRef := TWarStateRefs.Invalid;
    LMachine^.Pending.CancellationTargetRef := TWarStateRefs.Invalid;
    if LMachine^.Depth > WAR_MODEL_STATE_STACK_DEPTH then
      LMachine^.Depth := WAR_MODEL_STATE_STACK_DEPTH;
    LCandidate := FContext.Storage.Deref(LRequest.StateRef);
    if (not Assigned(LCandidate)) or (LCandidate^.EntityId <> LEntity^.Id) then
      if OperationHasState(LRequest.Operation) then
      begin
        FreeUnownedTransitionRefs(LRequest);
        Continue;
      end;
    ResolveCommittedBuildCancellation(LMachine, LRequest);
    if not CommitCancellation(LSlot, LMachine, LRequest) then
    begin
      FreeUnownedTransitionRefs(LRequest);
      Continue;
    end;
    case LRequest.Operation of
      WAR_OP_PUSH:
        begin
          // the descriptors have no validate and no pause hook: the push is always valid
          if LMachine^.Depth < WAR_MODEL_STATE_STACK_DEPTH then
          begin
            LMachine^.Stack[LMachine^.Depth] := LRequest.StateRef;
            Inc(LMachine^.Depth);
          end
          else
          begin
            // a push on a full stack replaces only the active state
            LNewTop := FContext.Storage.Deref(LMachine^.Stack[LMachine^.Depth - 1]);
            if Assigned(LNewTop) then
              ExitState(LSlot, LNewTop, WAR_EXIT_REPLACED);
            LMachine^.Stack[LMachine^.Depth - 1] := LRequest.StateRef;
          end;
          EnterState(LSlot, LCandidate);
        end;
      WAR_OP_POP:
        begin
          if LMachine^.Depth > 0 then
          begin
            LTop := FContext.Storage.Deref(LMachine^.Stack[LMachine^.Depth - 1]);
            if Assigned(LTop) then
              ExitState(LSlot, LTop, ExitReasonOf(LRequest.Result));
            Dec(LMachine^.Depth);
            LMachine^.Stack[LMachine^.Depth] := TWarStateRefs.Invalid;
          end;
          // no state has a resume hook either: only an empty stack needs something to do
          if LMachine^.Depth = 0 then
          begin
            LIdleRef := SetDefaultIdle(LSlot, LMachine);
            if TWarStateRefs.IsValid(LIdleRef) then
            begin
              LState := FContext.Storage.Deref(LIdleRef);
              if Assigned(LState) then
                EnterState(LSlot, LState);
            end;
          end;
        end;
      WAR_OP_REPLACE:
        begin
          if LMachine^.Depth > 0 then
          begin
            LTop := FContext.Storage.Deref(LMachine^.Stack[LMachine^.Depth - 1]);
            if Assigned(LTop) then
              ExitState(LSlot, LTop, WAR_EXIT_REPLACED);
            LMachine^.Stack[LMachine^.Depth - 1] := LRequest.StateRef;
          end
          else
          begin
            LMachine^.Stack[0] := LRequest.StateRef;
            LMachine^.Depth := 1;
          end;
          LNewTop := FContext.Storage.Deref(LMachine^.Stack[LMachine^.Depth - 1]);
          if Assigned(LNewTop) then
            EnterState(LSlot, LNewTop);
        end;
      WAR_OP_RESET:
        begin
          LDepth := LMachine^.Depth;
          while LDepth > 0 do
          begin
            Dec(LDepth);
            LState := FContext.Storage.Deref(LMachine^.Stack[LDepth]);
            if Assigned(LState) then
            begin
              if LState^.StateType = WAR_STATE_DEATH then
                LExitReason := WAR_EXIT_ENTITY_DIED
              else
                LExitReason := WAR_EXIT_RESET_BY_COMMAND;
              ExitState(LSlot, LState, LExitReason);
            end;
            LMachine^.Stack[LDepth] := TWarStateRefs.Invalid;
          end;
          LMachine^.Stack[0] := LRequest.StateRef;
          LMachine^.Depth := 1;
          LNewTop := FContext.Storage.Deref(LMachine^.Stack[0]);
          if Assigned(LNewTop) then
            EnterState(LSlot, LNewTop);
        end;
    else
      FreeUnownedTransitionRefs(LRequest);
    end;
    FreeUnownedRef(LRequest.CancellationTargetRef);
  end;
end;

procedure TWarStateMachine.UpdateStates;
var
  LType: Integer;
begin
  for LType := 0 to WAR_STATE_COUNT - 1 do
    if Assigned(FDescriptors[LType].UpdateAll) then
      FDescriptors[LType].UpdateAll(Self);
end;

procedure TWarStateMachine.TearDown(ASlot: Integer);
var
  LMachine: PWarStateMachineComponent;
  LDepth: Integer;
  LPendingRef: TWarStateRef;
  LCancellationRef: TWarStateRef;
begin
  LMachine := Machine(ASlot);
  for LDepth := LMachine^.Depth - 1 downto 0 do
    if TWarStateRefs.IsValid(LMachine^.Stack[LDepth]) then
      ExitState(ASlot, FContext.Storage.Deref(LMachine^.Stack[LDepth]), WAR_EXIT_REMOVED);
  for LDepth := 0 to WAR_MODEL_STATE_STACK_DEPTH - 1 do
    LMachine^.Stack[LDepth] := TWarStateRefs.Invalid;
  LMachine^.Depth := 0;
  LPendingRef := LMachine^.Pending.StateRef;
  LCancellationRef := LMachine^.Pending.CancellationTargetRef;
  LMachine^.Pending := Default(TWarTransitionRequest);
  LMachine^.Pending.StateRef := TWarStateRefs.Invalid;
  LMachine^.Pending.CancellationTargetRef := TWarStateRefs.Invalid;
  if TWarStateRefs.IsValid(LPendingRef) then
    FreeStateRef(LPendingRef);
  if TWarStateRefs.IsValid(LCancellationRef) then
    FreeStateRef(LCancellationRef);
end;

end.
