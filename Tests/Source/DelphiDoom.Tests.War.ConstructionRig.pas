{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - a model with the orders of building   }
{  ready to use in a test                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ConstructionRig;

interface

uses
  System.SysUtils, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.World,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.Commands.Construction, DelphiDoom.Tests.War.ConstructionObserver;

type
  /// <summary>
  ///   A world of the model with the grid of occupation, the host and the observer of the tests and the orders of building
  ///   and training. The player 0 is human, 1 to 3 orcs and 4 neutral; the player 0 has 5000 gold and lumber and the
  ///   upgrades are allowed up to the level 2. A tic is by default 1/60 s
  /// </summary>
  TConstructionRig = class
  strict private
    FWorld: TWarModelWorld;
    FGrid: TWarPathGrid;
    FObserver: TConstructionObserver;
    FCommands: TWarConstructionCommands;
    function GetContext: TWarModelContext;
    function GetMachine: TWarStateMachine;
  public
    constructor Create(ASeed: Cardinal = 1);
    destructor Destroy; override;
    /// <summary>A unit that moves with its idle state entered (one tic goes by); the slot</summary>
    function AddDude(AUnitType, AX, AY: Integer; APlayer: Byte = 0): Integer;
    /// <summary>A building, finished, with its idle state entered (one tic goes by); the slot</summary>
    function AddBuilding(AUnitType, AX, AY: Integer; APlayer: Byte = 0): Integer;
    /// <summary>Tics of the given length: the clock goes on, the states change and update, then the actions</summary>
    procedure Tick(ACount: Integer = 1; ADelta: Single = 0.016666668);
    /// <summary>Tics until the game time has gone forward by the seconds</summary>
    procedure Run(ASeconds: Single; ADelta: Single = 0.016666668);
    function Entity(ASlot: Integer): PWarEntity;
    function ActiveType(ASlot: Integer): Integer;
    function BuildState(ASlot: Integer): PWarStateBuild;
    /// <summary>The slot of the first unit of the type in the map, 0 if there is none</summary>
    function FirstOfType(AUnitType: Integer): Integer;
    property World: TWarModelWorld read FWorld;
    property Context: TWarModelContext read GetContext;
    property Machine: TWarStateMachine read GetMachine;
    property Grid: TWarPathGrid read FGrid;
    property Observer: TConstructionObserver read FObserver;
    property Commands: TWarConstructionCommands read FCommands;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.GridOccupancy;

{ TConstructionRig }

function TConstructionRig.GetContext: TWarModelContext;
begin
  Result := FWorld.Context;
end;

function TConstructionRig.GetMachine: TWarStateMachine;
begin
  Result := FWorld.Machine;
end;

constructor TConstructionRig.Create(ASeed: Cardinal);
var
  LPlayer: Integer;
  LUpgrade: Integer;
  LZeros: TArray<Word>;
begin
  inherited Create;
  FObserver := TConstructionObserver.Create(ASeed);
  SetLength(LZeros, 4096);
  FGrid := TWarPathGrid.Create(LZeros);
  FWorld := TWarModelFactory.CreateWorld(FObserver, TWarGridOccupancy.Create(FGrid), FObserver);
  FWorld.Context.ConstructionHost := FObserver;
  FCommands := TWarConstructionCommands.Create(FWorld.Context, FWorld.Machine, FWorld.Economy);
  for LPlayer := 0 to WAR_MAX_PLAYERS_COUNT - 1 do
  begin
    if LPlayer = 0 then
      FWorld.Context.Players[LPlayer]^.Race := wraHumans
    else if LPlayer = 4 then
      FWorld.Context.Players[LPlayer]^.Race := wraNeutral
    else
      FWorld.Context.Players[LPlayer]^.Race := wraOrcs;
    FWorld.Context.Players[LPlayer]^.Gold := 5000;
    FWorld.Context.Players[LPlayer]^.Wood := 5000;
    for LUpgrade := 0 to WAR_MAX_UPGRADES_COUNT - 1 do
      FWorld.Context.Players[LPlayer]^.Upgrades[LUpgrade].Allowed := 2;
  end;
end;

destructor TConstructionRig.Destroy;
begin
  FCommands.Free;
  FWorld.Free;
  FGrid.Free;
  inherited;
end;

function TConstructionRig.AddDude(AUnitType, AX, AY: Integer; APlayer: Byte): Integer;
begin
  Result := FWorld.Entities.CreateDude(AUnitType, AX, AY, APlayer, False);
  FWorld.Entities.SetInitialIdle(Result);
  Tick;
end;

function TConstructionRig.AddBuilding(AUnitType, AX, AY: Integer; APlayer: Byte): Integer;
begin
  Result := FWorld.Entities.CreateBuilding(AUnitType, AX, AY, APlayer, False);
  Tick;
end;

procedure TConstructionRig.Tick(ACount: Integer; ADelta: Single);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
  begin
    FWorld.AdvanceClock(ADelta);
    FWorld.Update;
    FWorld.UpdateActions;
  end;
end;

procedure TConstructionRig.Run(ASeconds: Single; ADelta: Single);
var
  LEnd: Double;
begin
  LEnd := FWorld.Context.Clock^.GameTime + ASeconds;
  while FWorld.Context.Clock^.GameTime < LEnd do
    Tick(1, ADelta);
end;

function TConstructionRig.Entity(ASlot: Integer): PWarEntity;
begin
  Result := FWorld.Context.Pool.Slots[ASlot];
end;

function TConstructionRig.ActiveType(ASlot: Integer): Integer;
var
  LState: PWarStateBase;
begin
  LState := FWorld.Machine.ActiveState(ASlot);
  if Assigned(LState) then
    Result := LState^.StateType
  else
    Result := WAR_STATE_NONE;
end;

function TConstructionRig.BuildState(ASlot: Integer): PWarStateBuild;
begin
  Result := PWarStateBuild(FWorld.Machine.FindState(ASlot, WAR_STATE_BUILD));
end;

function TConstructionRig.FirstOfType(AUnitType: Integer): Integer;
var
  LList: TList<Integer>;
begin
  LList := FWorld.Context.Pool.UnitsOfType[AUnitType];
  if LList.Count > 0 then
    Result := LList[0]
  else
    Result := 0;
end;

end.
