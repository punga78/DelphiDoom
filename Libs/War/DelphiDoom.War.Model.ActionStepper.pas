{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the steps of the actions                          }
{                                                                              }
{  Port of war1 (acoto87/war1), wact_updateAction and wact_resetAction of      }
{  war_actions.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see         }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.ActionStepper;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.GatherData;

const
  // WarUnitActionStepType of war_enums.h
  WAR_ACTION_STEP_NONE = 0;
  WAR_ACTION_STEP_FRAME = 1;
  WAR_ACTION_STEP_WAIT = 2;
  WAR_ACTION_STEP_ATTACK = 3;
  WAR_ACTION_STEP_SOUND_SWORD = 4;
  WAR_ACTION_STEP_SOUND_FIST = 5;
  WAR_ACTION_STEP_SOUND_FIREBALL = 6;
  WAR_ACTION_STEP_SOUND_CHOPPING = 7;
  WAR_ACTION_STEP_SOUND_CATAPULT = 8;
  WAR_ACTION_STEP_SOUND_ARROW = 9;
  WAR_ACTION_STEP_SOUND_LIGHTNING = 10;

type
  /// <summary>
  ///   Plays the steps of the animation that a unit is doing: which frame it shows, when it hits (the step that the
  ///   states wait for) and which sound it makes, and when the next step is due. The steps are data
  ///   (DelphiDoom.War.Model.GatherData, generated from the C): so far only those of the harvest action are there; an
  ///   action without data is left as it is, not run (the other actions come with their own slices)
  /// </summary>
  TWarActionStepper = class
  strict private
    class function FindDefinition(AUnitType, AAction: Integer): Integer; static;
  public
    /// <summary>True if the steps of the action are in the data</summary>
    class function HasSteps(AUnitType, AAction: Integer): Boolean; static;
    /// <summary>wact_resetAction: from the first step, not started</summary>
    class procedure Reset(var AUnit: TWarUnitComponent; AAction: Integer); static;
    /// <summary>wact_updateAction on the unit of the entity</summary>
    class procedure UpdateAction(AClock: PWarGameClock; AEntity: PWarEntity); static;
    /// <summary>The updateActions of wmap_updateMap: every unit, in the order of the list of the units</summary>
    class procedure UpdateAll(AContext: TWarModelContext); static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Model.Math;

{ TWarActionStepper }

class function TWarActionStepper.FindDefinition(AUnitType, AAction: Integer): Integer;
var
  LIndex: Integer;
begin
  if AAction = WAR_ACTION_HARVEST then
    for LIndex := Low(WAR_HARVEST_ACTIONS) to High(WAR_HARVEST_ACTIONS) do
      if WAR_HARVEST_ACTIONS[LIndex].UnitType = AUnitType then
        Exit(LIndex);
  Result := -1;
end;

class function TWarActionStepper.HasSteps(AUnitType, AAction: Integer): Boolean;
begin
  Result := FindDefinition(AUnitType, AAction) >= 0;
end;

class procedure TWarActionStepper.Reset(var AUnit: TWarUnitComponent; AAction: Integer);
begin
  // the original indexes the array with the action that the unit has (it never has none here)
  if (AAction < 0) or (AAction >= WAR_ACTION_TYPE_COUNT) then
    Exit;
  AUnit.Actions[AAction].StepIndex := 0;
  AUnit.Actions[AAction].Status := WAR_ACTION_NOT_STARTED;
  AUnit.Actions[AAction].WaitEndGameTime := 0;
end;

class procedure TWarActionStepper.UpdateAction(AClock: PWarGameClock; AEntity: PWarEntity);
var
  LUnit: PWarUnitComponent;
  LAction: ^TWarUnitAction;
  LDefinition: Integer;
  LStep: TWarActionStepData;
  LFrame: Integer;
  LSeconds: Single;
begin
  LUnit := @AEntity^.UnitData;
  if (LUnit^.ActionType < 0) or (LUnit^.ActionType >= WAR_ACTION_TYPE_COUNT) then
    Exit;
  LDefinition := FindDefinition(LUnit^.UnitType, LUnit^.ActionType);
  if LDefinition < 0 then
    Exit;
  LAction := @LUnit^.Actions[LUnit^.ActionType];
  if LAction^.Status = WAR_ACTION_FINISHED then
    Exit;
  if LAction^.StepIndex < 0 then
    Reset(LUnit^, LUnit^.ActionType);
  LAction^.Status := WAR_ACTION_RUNNING;
  LStep := WAR_HARVEST_ACTIONS[LDefinition].Steps[LAction^.StepIndex];
  if LStep.StepType = WAR_ACTION_STEP_WAIT then
  begin
    if AClock^.GameTime < LAction^.WaitEndGameTime then
      Exit;
    LAction^.WaitEndGameTime := 0;
    Inc(LAction^.StepIndex);
    if LAction^.StepIndex >= WAR_HARVEST_ACTIONS[LDefinition].Count then
    begin
      if not WAR_HARVEST_ACTIONS[LDefinition].Loop then
      begin
        LAction^.Status := WAR_ACTION_FINISHED;
        Exit;
      end;
      LAction^.StepIndex := 0;
    end;
    LStep := WAR_HARVEST_ACTIONS[LDefinition].Steps[LAction^.StepIndex];
  end;
  LAction^.LastActionStep := WAR_ACTION_STEP_NONE;
  LAction^.LastSoundStep := WAR_ACTION_STEP_NONE;
  while LStep.StepType <> WAR_ACTION_STEP_WAIT do
  begin
    case LStep.StepType of
      WAR_ACTION_STEP_FRAME:
        begin
          LFrame := LStep.Param;
          if WAR_HARVEST_ACTIONS[LDefinition].Directional then
          begin
            // 4 - ABS(4 - direction): north 0, east 2, south 4, west 2, north west 1
            LFrame := LFrame + (4 - Abs(4 - LUnit^.Direction));
            LUnit^.Mirrored := (LUnit^.Direction >= WAR_DIRECTION_SOUTH_WEST) and (LUnit^.Direction < WAR_DIRECTION_COUNT);
          end;
          if LUnit^.SpriteResource <> 0 then
            LUnit^.SpriteFrame := LFrame;
        end;
      WAR_ACTION_STEP_ATTACK:
        LAction^.LastActionStep := WAR_ACTION_STEP_ATTACK;
      WAR_ACTION_STEP_SOUND_SWORD..WAR_ACTION_STEP_SOUND_LIGHTNING:
        LAction^.LastSoundStep := LStep.StepType;
    end;
    Inc(LAction^.StepIndex);
    if LAction^.StepIndex >= WAR_HARVEST_ACTIONS[LDefinition].Count then
    begin
      if not WAR_HARVEST_ACTIONS[LDefinition].Loop then
      begin
        LAction^.Status := WAR_ACTION_FINISHED;
        Exit;
      end;
      LAction^.StepIndex := 0;
    end;
    LStep := WAR_HARVEST_ACTIONS[LDefinition].Steps[LAction^.StepIndex];
  end;
  LSeconds := TWarModelMath.FramesToSeconds(LStep.Param);
  LSeconds := LSeconds * LAction^.Scale;
  LAction^.WaitEndGameTime := AClock^.GameTime + LSeconds;
end;

class procedure TWarActionStepper.UpdateAll(AContext: TWarModelContext);
var
  LUnits: TList<Integer>;
  LIndex: Integer;
  LEntity: PWarEntity;
begin
  LUnits := AContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LEntity := AContext.Pool.Slots[LUnits[LIndex]];
    if LEntity^.HasUnit and (LEntity^.UnitData.ActionType = WAR_ACTION_HARVEST) then
      UpdateAction(AContext.Clock, LEntity);
  end;
end;

end.
