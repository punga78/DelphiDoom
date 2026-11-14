{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - a model ready to use in a test       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelRig;

interface

uses
  System.SysUtils, DelphiDoom.War.Sound.Intf, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.World, DelphiDoom.Tests.War.ModelObserver;

type
  /// <summary>A generator that gives the numbers of a list (and 0 when they are over), to decide what the model draws</summary>
  TScriptedRandom = class(TInterfacedObject, IWarRandom)
  strict private
    FValues: TArray<Integer>;
    FNext: Integer;
  public
    constructor Create(const AValues: array of Integer);
    function Below(ALimit: Integer): Integer;
    /// <summary>How many numbers were asked</summary>
    property Draws: Integer read FNext;
  end;

  /// <summary>
  ///   A world of the model with a generator that can be repeated, a grid of occupation and an observer of the events,
  ///   with the players of the original tests (the player 0 human, 1 to 3 orcs, 4 neutral) and some shortcuts
  /// </summary>
  TModelRig = class
  strict private
    FWorld: TWarModelWorld;
    FGrid: TWarPathGrid;
    FObserver: TModelObserver;
  public
    constructor Create(ASeed: Cardinal = 1); overload;
    /// <summary>A rig whose model draws the numbers of the random given (the observer then counts nothing)</summary>
    constructor Create(const ARandom: IWarRandom); overload;
    destructor Destroy; override;
    /// <summary>A unit that moves with its idle state already entered (one tic); the slot of the pool</summary>
    function AddDude(AUnitType, AX, AY: Integer; APlayer: Byte = 0): Integer;
    /// <summary>A building with its idle state already entered</summary>
    function AddBuilding(AUnitType, AX, AY: Integer; APlayer: Byte = 0): Integer;
    /// <summary>Tics of 1/60 s: the clock goes forward, the states change and update</summary>
    procedure Tick(ACount: Integer = 1);
    /// <summary>Tics until the game time has gone forward by the seconds</summary>
    procedure Run(ASeconds: Single);
    /// <summary>The type of the active state of the entity (WAR_STATE_NONE if it has none)</summary>
    function ActiveType(ASlot: Integer): Integer;
    function Entity(ASlot: Integer): PWarEntity;
    function Move(ASlot: Integer; const APositions: array of TWarVec2; ACheckForAttacks: Boolean = False): Boolean;
    property World: TWarModelWorld read FWorld;
    property Grid: TWarPathGrid read FGrid;
    property Observer: TModelObserver read FObserver;
  end;

const
  TIC_LENGTH: Single = 0.016666668;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Sound.SeededRandom, DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.GridOccupancy,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine;

{ TScriptedRandom }

constructor TScriptedRandom.Create(const AValues: array of Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FValues, Length(AValues));
  for LIndex := 0 to High(AValues) do
    FValues[LIndex] := AValues[LIndex];
end;

function TScriptedRandom.Below(ALimit: Integer): Integer;
begin
  Result := 0;
  if FNext < Length(FValues) then
    Result := FValues[FNext];
  Inc(FNext);
end;

{ TModelRig }

constructor TModelRig.Create(ASeed: Cardinal);
begin
  Create(IWarRandom(TWarSeededRandom.Create(ASeed)));
end;

constructor TModelRig.Create(const ARandom: IWarRandom);
var
  LPlayer: Integer;
  LZeros: TArray<Word>;
begin
  inherited Create;
  FObserver := TModelObserver.Create(1);
  SetLength(LZeros, 4096);
  FGrid := TWarPathGrid.Create(LZeros);
  FWorld := TWarModelFactory.CreateWorld(ARandom, TWarGridOccupancy.Create(FGrid), FObserver);
  for LPlayer := 0 to WAR_MAX_PLAYERS_COUNT - 1 do
  begin
    if LPlayer = 0 then
      FWorld.Context.Players[LPlayer]^.Race := wraHumans
    else if LPlayer = 4 then
      FWorld.Context.Players[LPlayer]^.Race := wraNeutral
    else
      FWorld.Context.Players[LPlayer]^.Race := wraOrcs;
    FWorld.Context.Players[LPlayer]^.Gold := 1000;
    FWorld.Context.Players[LPlayer]^.Wood := 1000;
    FWorld.Context.Players[LPlayer]^.Upgrades[0].Allowed := 2;
    FWorld.Context.Players[LPlayer]^.Upgrades[1].Allowed := 2;
    FWorld.Context.Players[LPlayer]^.Upgrades[2].Allowed := 2;
    FWorld.Context.Players[LPlayer]^.Upgrades[9].Allowed := 2;
  end;
end;

destructor TModelRig.Destroy;
begin
  FWorld.Free;
  FGrid.Free;
  inherited;
end;

function TModelRig.AddDude(AUnitType, AX, AY: Integer; APlayer: Byte): Integer;
begin
  Result := FWorld.Entities.CreateDude(AUnitType, AX, AY, APlayer, False);
  FWorld.Entities.SetInitialIdle(Result);
  Tick;
end;

function TModelRig.AddBuilding(AUnitType, AX, AY: Integer; APlayer: Byte): Integer;
begin
  Result := FWorld.Entities.CreateBuilding(AUnitType, AX, AY, APlayer, False);
  Tick;
end;

procedure TModelRig.Tick(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
  begin
    FWorld.AdvanceClock(TIC_LENGTH);
    FWorld.Update;
  end;
end;

procedure TModelRig.Run(ASeconds: Single);
var
  LEnd: Double;
begin
  LEnd := FWorld.Context.Clock^.GameTime + ASeconds;
  while FWorld.Context.Clock^.GameTime < LEnd do
    Tick;
end;

function TModelRig.ActiveType(ASlot: Integer): Integer;
var
  LState: PWarStateBase;
begin
  LState := FWorld.Machine.ActiveState(ASlot);
  if Assigned(LState) then
    Result := LState^.StateType
  else
    Result := WAR_STATE_NONE;
end;

function TModelRig.Entity(ASlot: Integer): PWarEntity;
begin
  Result := FWorld.Context.Pool.Slots[ASlot];
end;

function TModelRig.Move(ASlot: Integer; const APositions: array of TWarVec2; ACheckForAttacks: Boolean): Boolean;
var
  LState: PWarStateMove;
begin
  LState := FWorld.Machine.CreateMove(ASlot, APositions, ACheckForAttacks);
  Result := FWorld.Machine.ResetState(ASlot, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

end.
