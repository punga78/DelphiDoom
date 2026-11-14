{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the creation of the states of the gatherers       }
{                                                                              }
{  Port of war1 (acoto87/war1), wst_createGatherGoldState,                     }
{  wst_createMiningState, wst_createGatherWoodState,                           }
{  wst_createChoppingState and wst_createDeliverState, (c) 2019 Alejandro Coto }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.GatherFactory;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   The five states of the gatherers make each other (gold to mining to delivery to gold again, wood to chopping to
  ///   delivery): the creation is here, in one place, so that the states do not use each other. Every function returns
  ///   nil if the storage of the type is full (the original then hands a null state to the machine, which refuses it)
  /// </summary>
  TWarGatherStateFactory = class
  public
    class function NewGold(AMachine: TWarStateMachine; ASlot: Integer; AGoldmineId: Word): PWarStateGold; static;
    class function NewMining(AMachine: TWarStateMachine; ASlot: Integer; AGoldmineId: Word): PWarStateMining; static;
    class function NewWood(AMachine: TWarStateMachine; ASlot: Integer; AForestId: Word;
      const APosition: TWarVec2): PWarStateWood; static;
    class function NewChopping(AMachine: TWarStateMachine; ASlot: Integer; AForestId: Word;
      const APosition: TWarVec2): PWarStateChopping; static;
    class function NewDeliver(AMachine: TWarStateMachine; ASlot: Integer; ATownHallId: Word): PWarStateDeliver; static;
    /// <summary>The three lines that the gatherers repeat: an idle state that looks around replaces the active one (completion)</summary>
    class procedure ReplaceWithIdle(AMachine: TWarStateMachine; ASlot: Integer); static;
  end;

implementation

uses
  DelphiDoom.War.Level.Types;

{ TWarGatherStateFactory }

class function TWarGatherStateFactory.NewGold(AMachine: TWarStateMachine; ASlot: Integer;
  AGoldmineId: Word): PWarStateGold;
begin
  Result := PWarStateGold(AMachine.AllocState(ASlot, WAR_STATE_GOLD));
  if Assigned(Result) then
    Result^.GoldmineId := AGoldmineId;
end;

class function TWarGatherStateFactory.NewMining(AMachine: TWarStateMachine; ASlot: Integer;
  AGoldmineId: Word): PWarStateMining;
begin
  Result := PWarStateMining(AMachine.AllocState(ASlot, WAR_STATE_MINING));
  if Assigned(Result) then
  begin
    Result^.GoldmineId := AGoldmineId;
    Result^.MiningTime := 0;
  end;
end;

class function TWarGatherStateFactory.NewWood(AMachine: TWarStateMachine; ASlot: Integer; AForestId: Word;
  const APosition: TWarVec2): PWarStateWood;
begin
  Result := PWarStateWood(AMachine.AllocState(ASlot, WAR_STATE_WOOD));
  if Assigned(Result) then
  begin
    Result^.ForestId := AForestId;
    Result^.Position := APosition;
  end;
end;

class function TWarGatherStateFactory.NewChopping(AMachine: TWarStateMachine; ASlot: Integer; AForestId: Word;
  const APosition: TWarVec2): PWarStateChopping;
begin
  Result := PWarStateChopping(AMachine.AllocState(ASlot, WAR_STATE_CHOPPING));
  if Assigned(Result) then
  begin
    Result^.ForestId := AForestId;
    Result^.Position := APosition;
  end;
end;

class function TWarGatherStateFactory.NewDeliver(AMachine: TWarStateMachine; ASlot: Integer;
  ATownHallId: Word): PWarStateDeliver;
begin
  Result := PWarStateDeliver(AMachine.AllocState(ASlot, WAR_STATE_DELIVER));
  if Assigned(Result) then
  begin
    Result^.TownHallId := ATownHallId;
    Result^.InsideBuilding := False;
    Result^.Cycle := False;
    Result^.SourceKind := wrkNone;
    Result^.SourceId := 0;
    Result^.SourcePosition.X := 0;
    Result^.SourcePosition.Y := 0;
  end;
end;

class procedure TWarGatherStateFactory.ReplaceWithIdle(AMachine: TWarStateMachine; ASlot: Integer);
begin
  AMachine.ReplaceState(ASlot, PWarStateBase(AMachine.CreateIdle(ASlot, True)), WAR_CAUSE_COMPLETION);
end;

end.
