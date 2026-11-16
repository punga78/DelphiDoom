{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the request of units of the AI                     }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.c (wai_executeRequestAICommand,          }
{  wai_tryCreateUnit, wai_hasUnresolvedTrainRequest), (c) 2019 Alejandro Coto   }
{  Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.RequestHandler;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Ai.Command, DelphiDoom.War.Ai.Environment, DelphiDoom.War.Ai.Handler;

type
  /// <summary>
  ///   WAR_AI_COMMAND_REQUEST. A unit that is a dude is trained by the first building of its producer type that belongs to the
  ///   player and is not busy (the order is the one of the list of the units of the type), with the cause WAR_CAUSE_AI_ORDER
  ///   and the command in the training state; everything else is checked in the order of the original (resources, then
  ///   food, without the message of the player). It does NOT go through TWarCommands: the original calls
  ///   wst_createTrainState and wst_resetState itself, and the player's order flashes a message. A building is "done" at
  ///   once without anything being built (the original has only the comments of what it would do): the request counts one
  ///   and completes. The request itself always lets the script go on (it returns True)
  /// </summary>
  TWarAiRequestHandler = class(TWarAiCommandHandler)
  strict private
    class function HasUnresolvedTrainRequest(const AEnvironment: TWarAiEnvironment; AHandle: Cardinal): Boolean; static;
    class function TryCreateUnit(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean; static;
  public
    function Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean; override;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Ai.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.State.Train, DelphiDoom.War.Model.Stats.Types, DelphiDoom.War.Model.UnitClassifier,
  DelphiDoom.War.Model.UnitProducers, DelphiDoom.War.Model.World;

{ TWarAiRequestHandler }

class function TWarAiRequestHandler.HasUnresolvedTrainRequest(const AEnvironment: TWarAiEnvironment;
  AHandle: Cardinal): Boolean;
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LLeft: Integer;
begin
  LContext := AEnvironment.World.Context;
  // the original scans the 512 places of the storage; the count of the allocated ones says when to stop (the same answer)
  LLeft := LContext.Storage.ActiveCount[WAR_STATE_TRAIN];
  LIndex := 0;
  while (LLeft > 0) and (LIndex < WAR_MODEL_MAX_STATES_PER_TYPE) do
  begin
    if LContext.Storage.Occupied[WAR_STATE_TRAIN, LIndex] then
    begin
      if PWarStateTrain(LContext.Storage.StateAt(WAR_STATE_TRAIN, LIndex))^.AiCommand = AHandle then
        Exit(True);
      Dec(LLeft);
    end;
    Inc(LIndex);
  end;
  Result := False;
end;

class function TWarAiRequestHandler.TryCreateUnit(const AEnvironment: TWarAiEnvironment;
  const ACommand: TWarAiCommand): Boolean;
var
  LWorld: TWarModelWorld;
  LContext: TWarModelContext;
  LUnitType: Integer;
  LHandle: Cardinal;
  LStats: TWarUnitStatsFull;
  LProducer: Integer;
  LUnits: TList<Integer>;
  LIndex: Integer;
  LSlot: Integer;
  LTrain: PWarStateTrain;
begin
  Result := False;
  LWorld := AEnvironment.World;
  LContext := LWorld.Context;
  LUnitType := ACommand.UnitType;
  if TWarUnitClassifier.IsDude(LUnitType) then
  begin
    LHandle := TWarAiCommand.MakeHandle(AEnvironment.PlayerIndex, ACommand.Id);
    if HasUnresolvedTrainRequest(AEnvironment, LHandle) then
      Exit;
    LStats := LContext.Database.GetUnitStats(LUnitType);
    // not enough gold or lumber: the request lives and tries again at the next tic
    if not LWorld.Economy.EnoughResources(AEnvironment.Player, LStats.GoldCost, LStats.WoodCost) then
      Exit;
    // no room in the farms
    if not LWorld.Economy.EnoughFarmFood(AEnvironment.Player) then
      Exit;
    LProducer := TWarUnitProducers.ProducerOf(LUnitType);
    if TWarUnitProducers.IsValidType(LProducer) then
    begin
      LUnits := LContext.Pool.UnitsOfType[LProducer];
      for LIndex := 0 to LUnits.Count - 1 do
      begin
        LSlot := LUnits[LIndex];
        if (LSlot <> 0) and (LContext.Pool.Slots[LSlot]^.UnitData.Player = AEnvironment.PlayerIndex) and
          not LWorld.Machine.Contains(LSlot, WAR_STATE_TRAIN) and not LWorld.Machine.HasPending(LSlot, WAR_STATE_TRAIN) and
          not LWorld.Machine.Contains(LSlot, WAR_STATE_UPGRADE) and
          not LWorld.Machine.HasPending(LSlot, WAR_STATE_UPGRADE) and
          LWorld.Machine.CanSubmitTransition(LSlot, WAR_INTERRUPT_AI_ORDER) then
        begin
          // the first building that is free decides, whether the order is then accepted or not (as in the original)
          LTrain := TWarTrainState.CreateState(LWorld.Machine, LSlot, LUnitType, LStats.BuildTime, LStats.GoldCost,
            LStats.WoodCost, LHandle);
          if not Assigned(LTrain) then
            Exit(False);
          Exit(LWorld.Machine.ResetState(LSlot, PWarStateBase(LTrain), WAR_CAUSE_AI_ORDER));
        end;
      end;
    end;
    // no building to train the unit, or all busy: the request lives and tries again
    Exit(False);
  end;
  if TWarUnitClassifier.IsBuilding(LUnitType) then
    // the original only has the plan of what it would do (find a worker, a place, send it): it says "done"
    Exit(True);
  AEnvironment.Warn('Unknown unit type ' + IntToStr(LUnitType) + ' to be built by player ' +
    IntToStr(AEnvironment.PlayerIndex));
end;

function TWarAiRequestHandler.Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean;
begin
  ACommand.Status := WAR_AI_STATUS_STARTED;
  if TryCreateUnit(AEnvironment, ACommand) and not TWarUnitClassifier.IsDude(ACommand.UnitType) then
    ACommand.ApplyUnitRequestProgress;
  Result := True;
end;

end.
