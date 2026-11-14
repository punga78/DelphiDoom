{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the storage of the states                         }
{                                                                              }
{  Port of war1 (acoto87/war1), WarStateStorage and wst_allocState,            }
{  wst_releaseStateRef, wst_deref, wst_refOf, wst_initStorage of               }
{  war_state_machine.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see   }
{  Libs\War\LICENSE-war1.txt). This is an altered version.                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.StateStorage;

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types;

type
  /// <summary>Operations on the references to states</summary>
  TWarStateRefs = class
  public
    /// <summary>WAR_STATE_REF_INVALID</summary>
    class function Invalid: TWarStateRef; static;
    /// <summary>WAR_STATE_REF_IS_VALID: a known type, a slot and a generation that is not 0</summary>
    class function IsValid(const ARef: TWarStateRef): Boolean; static; inline;
    class function Equal(const A, B: TWarStateRef): Boolean; static; inline;
  end;

  /// <summary>
  ///   One array of 512 states for each type of state, each slot with a generation that grows when it is freed (so an
  ///   old reference to it stops being valid) and a LIFO list of the free slots: the first state of a type gets slot 0,
  ///   the one freed last is the first to be reused. The updates of the states go through the slots in order, so
  ///   this order is part of what the game does
  /// </summary>
  TWarStateStorage = class
  strict private
    FIdle: TArray<TWarStateIdle>;
    FMove: TArray<TWarStateMove>;
    FPatrol: TArray<TWarStatePatrol>;
    FFollow: TArray<TWarStateFollow>;
    FAttack: TArray<TWarStateAttack>;
    FGold: TArray<TWarStateGold>;
    FMining: TArray<TWarStateMining>;
    FWood: TArray<TWarStateWood>;
    FChopping: TArray<TWarStateChopping>;
    FDeliver: TArray<TWarStateDeliver>;
    FDeath: TArray<TWarStateDeath>;
    FCollapse: TArray<TWarStateCollapse>;
    FTrain: TArray<TWarStateTrain>;
    FUpgrade: TArray<TWarStateUpgrade>;
    FBuild: TArray<TWarStateBuild>;
    FRepair: TArray<TWarStateRepair>;
    FRepairing: TArray<TWarStateRepairing>;
    FCast: TArray<TWarStateCast>;
    FWait: TArray<TWarStateWait>;
    FBases: array[0..WAR_STATE_COUNT - 1] of PByte;
    FSizes: array[0..WAR_STATE_COUNT - 1] of Integer;
    FGenerations: array[0..WAR_STATE_COUNT - 1, 0..WAR_MODEL_MAX_STATES_PER_TYPE - 1] of Cardinal;
    FOccupied: array[0..WAR_STATE_COUNT - 1, 0..WAR_MODEL_MAX_STATES_PER_TYPE - 1] of Boolean;
    FFreeLists: array[0..WAR_STATE_COUNT - 1, 0..WAR_MODEL_MAX_STATES_PER_TYPE - 1] of Integer;
    FFreeCounts: array[0..WAR_STATE_COUNT - 1] of Integer;
    FActiveCounts: array[0..WAR_STATE_COUNT - 1] of Integer;
    procedure Register(AType: Integer; ABase: Pointer; ASize: Integer);
    function GetOccupied(AType, AIndex: Integer): Boolean; inline;
    function GetActiveCount(AType: Integer): Integer;
    function GetFreeCount(AType: Integer): Integer;
  public
    constructor Create;
    /// <summary>wst_allocState: a zeroed state of the type for the entity; an invalid reference if the type is full</summary>
    function Alloc(AType: Integer; AEntityId: Word): TWarStateRef;
    /// <summary>wst_releaseStateRef: the slot is free and its generation grows (0 is skipped)</summary>
    procedure Release(const ARef: TWarStateRef);
    /// <summary>The reference is of a state that is allocated now (its generation is the one of the slot)</summary>
    function IsAllocated(const ARef: TWarStateRef): Boolean;
    /// <summary>wst_deref: nil if the reference is not valid any more</summary>
    function Deref(const ARef: TWarStateRef): PWarStateBase;
    /// <summary>wst_refOf</summary>
    function RefOf(AState: PWarStateBase): TWarStateRef;
    /// <summary>The state in a slot, without looking at the generation (the loops of the updates use it with Occupied)</summary>
    function StateAt(AType, AIndex: Integer): PWarStateBase; inline;
    property Occupied[AType, AIndex: Integer]: Boolean read GetOccupied;
    property ActiveCount[AType: Integer]: Integer read GetActiveCount;
    property FreeCount[AType: Integer]: Integer read GetFreeCount;
  end;

implementation

{ TWarStateRefs }

class function TWarStateRefs.Invalid: TWarStateRef;
begin
  Result.StateType := WAR_STATE_NONE;
  Result.Index := -1;
  Result.Generation := 0;
end;

class function TWarStateRefs.IsValid(const ARef: TWarStateRef): Boolean;
begin
  Result := (ARef.StateType >= WAR_STATE_IDLE) and (ARef.StateType < WAR_STATE_COUNT) and (ARef.Index >= 0) and
    (ARef.Generation <> 0);
end;

class function TWarStateRefs.Equal(const A, B: TWarStateRef): Boolean;
begin
  Result := (A.StateType = B.StateType) and (A.Index = B.Index) and (A.Generation = B.Generation);
end;

{ TWarStateStorage }

constructor TWarStateStorage.Create;
var
  LType: Integer;
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FIdle, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FMove, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FPatrol, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FFollow, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FAttack, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FGold, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FMining, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FWood, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FChopping, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FDeliver, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FDeath, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FCollapse, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FTrain, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FUpgrade, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FBuild, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FRepair, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FRepairing, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FCast, WAR_MODEL_MAX_STATES_PER_TYPE);
  SetLength(FWait, WAR_MODEL_MAX_STATES_PER_TYPE);
  Register(WAR_STATE_IDLE, @FIdle[0], SizeOf(TWarStateIdle));
  Register(WAR_STATE_MOVE, @FMove[0], SizeOf(TWarStateMove));
  Register(WAR_STATE_PATROL, @FPatrol[0], SizeOf(TWarStatePatrol));
  Register(WAR_STATE_FOLLOW, @FFollow[0], SizeOf(TWarStateFollow));
  Register(WAR_STATE_ATTACK, @FAttack[0], SizeOf(TWarStateAttack));
  Register(WAR_STATE_GOLD, @FGold[0], SizeOf(TWarStateGold));
  Register(WAR_STATE_MINING, @FMining[0], SizeOf(TWarStateMining));
  Register(WAR_STATE_WOOD, @FWood[0], SizeOf(TWarStateWood));
  Register(WAR_STATE_CHOPPING, @FChopping[0], SizeOf(TWarStateChopping));
  Register(WAR_STATE_DELIVER, @FDeliver[0], SizeOf(TWarStateDeliver));
  Register(WAR_STATE_DEATH, @FDeath[0], SizeOf(TWarStateDeath));
  Register(WAR_STATE_COLLAPSE, @FCollapse[0], SizeOf(TWarStateCollapse));
  Register(WAR_STATE_TRAIN, @FTrain[0], SizeOf(TWarStateTrain));
  Register(WAR_STATE_UPGRADE, @FUpgrade[0], SizeOf(TWarStateUpgrade));
  Register(WAR_STATE_BUILD, @FBuild[0], SizeOf(TWarStateBuild));
  Register(WAR_STATE_REPAIR, @FRepair[0], SizeOf(TWarStateRepair));
  Register(WAR_STATE_REPAIRING, @FRepairing[0], SizeOf(TWarStateRepairing));
  Register(WAR_STATE_CAST, @FCast[0], SizeOf(TWarStateCast));
  Register(WAR_STATE_WAIT, @FWait[0], SizeOf(TWarStateWait));
  // wst_initStorage
  for LType := 0 to WAR_STATE_COUNT - 1 do
  begin
    FFreeCounts[LType] := WAR_MODEL_MAX_STATES_PER_TYPE;
    for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
    begin
      FGenerations[LType, LIndex] := 1;
      FFreeLists[LType, LIndex] := WAR_MODEL_MAX_STATES_PER_TYPE - 1 - LIndex;
    end;
  end;
end;

procedure TWarStateStorage.Register(AType: Integer; ABase: Pointer; ASize: Integer);
begin
  FBases[AType] := ABase;
  FSizes[AType] := ASize;
end;

function TWarStateStorage.GetOccupied(AType, AIndex: Integer): Boolean;
begin
  Result := FOccupied[AType, AIndex];
end;

function TWarStateStorage.GetActiveCount(AType: Integer): Integer;
begin
  Result := FActiveCounts[AType];
end;

function TWarStateStorage.GetFreeCount(AType: Integer): Integer;
begin
  Result := FFreeCounts[AType];
end;

function TWarStateStorage.StateAt(AType, AIndex: Integer): PWarStateBase;
begin
  Result := PWarStateBase(FBases[AType] + AIndex * FSizes[AType]);
end;

function TWarStateStorage.Alloc(AType: Integer; AEntityId: Word): TWarStateRef;
var
  LFreeListIndex: Integer;
  LIndex: Integer;
  LState: PWarStateBase;
begin
  Result := TWarStateRefs.Invalid;
  if (AType < WAR_STATE_IDLE) or (AType >= WAR_STATE_COUNT) then
    Exit;
  if (FFreeCounts[AType] <= 0) or (FFreeCounts[AType] > WAR_MODEL_MAX_STATES_PER_TYPE) then
    Exit;
  LFreeListIndex := FFreeCounts[AType] - 1;
  LIndex := FFreeLists[AType, LFreeListIndex];
  if (LIndex < 0) or (LIndex >= WAR_MODEL_MAX_STATES_PER_TYPE) or FOccupied[AType, LIndex] then
    Exit;
  FFreeCounts[AType] := LFreeListIndex;
  FOccupied[AType, LIndex] := True;
  Inc(FActiveCounts[AType]);
  LState := StateAt(AType, LIndex);
  FillChar(LState^, FSizes[AType], 0);
  LState^.StateType := AType;
  LState^.EntityId := AEntityId;
  Result.StateType := AType;
  Result.Index := LIndex;
  Result.Generation := FGenerations[AType, LIndex];
end;

function TWarStateStorage.IsAllocated(const ARef: TWarStateRef): Boolean;
begin
  if (ARef.StateType < WAR_STATE_IDLE) or (ARef.StateType >= WAR_STATE_COUNT) then
    Exit(False);
  if (ARef.Index < 0) or (ARef.Index >= WAR_MODEL_MAX_STATES_PER_TYPE) or (ARef.Generation = 0) then
    Exit(False);
  Result := FOccupied[ARef.StateType, ARef.Index] and (FGenerations[ARef.StateType, ARef.Index] = ARef.Generation);
end;

procedure TWarStateStorage.Release(const ARef: TWarStateRef);
begin
  if not IsAllocated(ARef) then
    Exit;
  if (FFreeCounts[ARef.StateType] >= WAR_MODEL_MAX_STATES_PER_TYPE) or (FActiveCounts[ARef.StateType] <= 0) then
    Exit;
  FOccupied[ARef.StateType, ARef.Index] := False;
  Inc(FGenerations[ARef.StateType, ARef.Index]);
  if FGenerations[ARef.StateType, ARef.Index] = 0 then
    FGenerations[ARef.StateType, ARef.Index] := 1;
  FFreeLists[ARef.StateType, FFreeCounts[ARef.StateType]] := ARef.Index;
  Inc(FFreeCounts[ARef.StateType]);
  Dec(FActiveCounts[ARef.StateType]);
end;

function TWarStateStorage.Deref(const ARef: TWarStateRef): PWarStateBase;
begin
  if IsAllocated(ARef) then
    Result := StateAt(ARef.StateType, ARef.Index)
  else
    Result := nil;
end;

function TWarStateStorage.RefOf(AState: PWarStateBase): TWarStateRef;
var
  LOffset: NativeInt;
  LIndex: Integer;
  LType: Integer;
begin
  Result := TWarStateRefs.Invalid;
  if not Assigned(AState) then
    Exit;
  LType := AState^.StateType;
  if (LType < WAR_STATE_IDLE) or (LType >= WAR_STATE_COUNT) then
    Exit;
  LOffset := PByte(AState) - FBases[LType];
  if (LOffset < 0) or (LOffset >= NativeInt(FSizes[LType]) * WAR_MODEL_MAX_STATES_PER_TYPE) then
    Exit;
  if LOffset mod FSizes[LType] <> 0 then
    Exit;
  LIndex := LOffset div FSizes[LType];
  Result.StateType := LType;
  Result.Index := LIndex;
  Result.Generation := FGenerations[LType, LIndex];
  if not IsAllocated(Result) then
    Result := TWarStateRefs.Invalid;
end;

end.
