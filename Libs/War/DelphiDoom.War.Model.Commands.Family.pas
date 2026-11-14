{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what every family of commands shares              }
{                                                                              }
{  Port of war1 (acoto87/war1), war_commands.c, (c) 2019 Alejandro Coto        }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.Family;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Selection;

type
  /// <summary>
  ///   Who gives the orders: its selection (not owned), its player and why its orders change the state of a unit. The
  ///   player of the original is the player 0 with WAR_CAUSE_PLAYER_ORDER and the selection of the map; the computer
  ///   (issue #196) gives the same orders with its own selection, its player and WAR_CAUSE_AI_ORDER
  /// </summary>
  TWarCommander = record
    Selection: TWarSelection;
    Player: Integer;
    Cause: Integer;
    /// <summary>The player of the original: the selection of the context, the player 0, WAR_CAUSE_PLAYER_ORDER</summary>
    class function Human(AContext: TWarModelContext): TWarCommander; static;
    /// <summary>A computer player: WAR_CAUSE_AI_ORDER</summary>
    class function Computer(ASelection: TWarSelection; APlayer: Integer): TWarCommander; static;
    /// <summary>WAR_INTERRUPT_AI_ORDER for the computer, WAR_INTERRUPT_PLAYER_ORDER for anything else</summary>
    function Interrupt: Integer;
  end;

  /// <summary>
  ///   The base of a family of commands (movement, attack, gathering, spells): the walk on the selection that every
  ///   wcmd_execute*Command of the original does. A selected entity that does not exist any more is EWarException (the
  ///   original stops on an assert)
  /// </summary>
  TWarCommandFamily = class
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FCommander: TWarCommander;
  strict protected
    /// <summary>The slot of the selected entity at the position</summary>
    function SelectedSlot(AIndex: Integer): Integer;
    /// <summary>wu_isFriendlyUnit: a unit of the player that gives the orders</summary>
    function IsOwn(ASlot: Integer): Boolean;
    /// <summary>wst_canSubmitTransition for the cause of the commander</summary>
    function CanOrder(ASlot: Integer): Boolean;
    /// <summary>wst_resetState with the cause of the commander</summary>
    procedure Order(ASlot: Integer; AState: Pointer);
    /// <summary>wa_playAcknowledgementSound of the owner of the unit</summary>
    procedure Acknowledge(ASlot: Integer);
    property Context: TWarModelContext read FContext;
    property Machine: TWarStateMachine read FMachine;
    property Commander: TWarCommander read FCommander;
  public
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
      const ACommander: TWarCommander);
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Model.State.Types;

{ TWarCommander }

class function TWarCommander.Human(AContext: TWarModelContext): TWarCommander;
begin
  Result.Selection := AContext.Selection;
  Result.Player := 0;
  Result.Cause := WAR_CAUSE_PLAYER_ORDER;
end;

class function TWarCommander.Computer(ASelection: TWarSelection; APlayer: Integer): TWarCommander;
begin
  Result.Selection := ASelection;
  Result.Player := APlayer;
  Result.Cause := WAR_CAUSE_AI_ORDER;
end;

function TWarCommander.Interrupt: Integer;
begin
  if Cause = WAR_CAUSE_AI_ORDER then
    Result := WAR_INTERRUPT_AI_ORDER
  else
    Result := WAR_INTERRUPT_PLAYER_ORDER;
end;

{ TWarCommandFamily }

constructor TWarCommandFamily.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  const ACommander: TWarCommander);
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
  FCommander := ACommander;
end;

function TWarCommandFamily.SelectedSlot(AIndex: Integer): Integer;
begin
  Result := FContext.Pool.FindSlot(FCommander.Selection[AIndex]);
  if Result = 0 then
    raise EWarException.CreateFmt(SWarModelSelectionGone, [FCommander.Selection[AIndex]]);
end;

function TWarCommandFamily.IsOwn(ASlot: Integer): Boolean;
var
  LEntity: PWarEntity;
begin
  LEntity := FContext.Pool.Slots[ASlot];
  Result := LEntity^.HasUnit and (LEntity^.UnitData.Player = FCommander.Player);
end;

function TWarCommandFamily.CanOrder(ASlot: Integer): Boolean;
begin
  Result := FMachine.CanSubmitTransition(ASlot, FCommander.Interrupt);
end;

procedure TWarCommandFamily.Order(ASlot: Integer; AState: Pointer);
begin
  // the storage of the states is full: no order (the original passes the null state on, and the request is refused)
  if Assigned(AState) then
    FMachine.ResetState(ASlot, PWarStateBase(AState), FCommander.Cause);
end;

procedure TWarCommandFamily.Acknowledge(ASlot: Integer);
begin
  FContext.ConstructionHost.Acknowledge(FContext.Pool.Slots[ASlot]^.UnitData.Player);
end;

end.
