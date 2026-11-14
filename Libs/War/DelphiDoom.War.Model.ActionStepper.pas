{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the steps of the actions of the units              }
{                                                                              }
{  Port of war1 (acoto87/war1), wact_updateAction of war_actions.c and the     }
{  updateActions of war_map.c, (c) 2019 Alejandro Coto Gutierrez, zlib         }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not    }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.ActionStepper;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context;

const
  // WarUnitActionStepType of war_enums.h
  WAR_ACTION_STEP_NONE = 0;
  WAR_ACTION_STEP_FRAME = 1;
  WAR_ACTION_STEP_WAIT = 2;
  WAR_ACTION_STEP_ATTACK = 3;
  WAR_ACTION_STEP_SOUND_SWORD = 4;
  WAR_ACTION_STEP_SOUND_LIGHTNING = 10;

type
  /// <summary>
  ///   The animations of the units as a list of steps (show a frame, wait some frames of time, strike, make a sound),
  ///   which the original runs once per tic for every unit. The step of an action tells the states what happened: the
  ///   hammer of a worker that repairs a building falls when its action reaches the step ATTACK. Static functions: it runs
  ///   for every unit at every tic
  /// </summary>
  TWarActionStepper = class
  public
    /// <summary>
    ///   wact_updateAction on the unit of a slot: a wait that has not ended leaves everything as it is; otherwise the
    ///   steps up to the next wait run (the frame goes to the sprite, ATTACK and the sounds are noted in the action) and the
    ///   wait that follows starts
    /// </summary>
    class procedure Update(AContext: TWarModelContext; AEntity: PWarEntity); static;
    /// <summary>updateActions of war_map.c: every unit, in the order of the list of the units</summary>
    class procedure UpdateAll(AContext: TWarModelContext); static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.ActionStepData;

{ TWarActionStepper }

class procedure TWarActionStepper.Update(AContext: TWarModelContext; AEntity: PWarEntity);
var
  LUnit: PWarUnitComponent;
  LAction: ^TWarUnitAction;
  LDefIndex: Integer;
  LDef: ^TWarActionDef;
  LStep: TWarActionStep;
  LFrame: Integer;
  LSeconds: Single;
begin
  if not AEntity^.HasUnit then
    Exit;
  LUnit := @AEntity^.UnitData;
  if LUnit^.ActionType = WAR_ACTION_NONE then
    Exit;
  LAction := @LUnit^.Actions[LUnit^.ActionType];
  if LAction^.Status = WAR_ACTION_FINISHED then
    Exit;
  if LAction^.StepIndex < 0 then
  begin
    LAction^.StepIndex := 0;
    LAction^.Status := WAR_ACTION_NOT_STARTED;
    LAction^.WaitEndGameTime := 0;
  end;
  LAction^.Status := WAR_ACTION_RUNNING;
  LDefIndex := -1;
  if (LUnit^.UnitType >= 0) and (LUnit^.UnitType <= High(WAR_ACTION_DEF_INDEX)) then
    LDefIndex := WAR_ACTION_DEF_INDEX[LUnit^.UnitType, LUnit^.ActionType];
  if LDefIndex < 0 then
  begin
    // the unit type has no such action: the original warns and stops it
    LAction^.Status := WAR_ACTION_FINISHED;
    LUnit^.ActionType := WAR_ACTION_NONE;
    Exit;
  end;
  LDef := @WAR_ACTION_DEFS[LDefIndex];
  LStep := WAR_ACTION_STEPS[LDef^.First + LAction^.StepIndex];
  if LStep.StepType = WAR_ACTION_STEP_WAIT then
  begin
    if AContext.Clock^.GameTime < LAction^.WaitEndGameTime then
      Exit;
    LAction^.WaitEndGameTime := 0;
    Inc(LAction^.StepIndex);
    if LAction^.StepIndex >= LDef^.Count then
    begin
      if not LDef^.Loop then
      begin
        LAction^.Status := WAR_ACTION_FINISHED;
        Exit;
      end;
      LAction^.StepIndex := 0;
    end;
    LStep := WAR_ACTION_STEPS[LDef^.First + LAction^.StepIndex];
  end;
  LAction^.LastActionStep := WAR_ACTION_STEP_NONE;
  LAction^.LastSoundStep := WAR_ACTION_STEP_NONE;
  while LStep.StepType <> WAR_ACTION_STEP_WAIT do
  begin
    case LStep.StepType of
      WAR_ACTION_STEP_FRAME:
        begin
          LFrame := LStep.Param;
          if LDef^.Directional then
          begin
            // N 0, NE 1, E 2, SE 3, S 4, SW 3, W 2, NW 1: 4 - |4 - direction|
            LFrame := LFrame + (4 - Abs(4 - LUnit^.Direction));
            if (LUnit^.Direction >= WAR_DIRECTION_SOUTH_WEST) and (LUnit^.Direction < WAR_DIRECTION_COUNT) then
              AEntity^.ScaleX := -1.0
            else
              AEntity^.ScaleX := 1.0;
          end;
          if AEntity^.HasSprite then
            AEntity^.SpriteFrame := LFrame;
        end;
      WAR_ACTION_STEP_ATTACK:
        LAction^.LastActionStep := WAR_ACTION_STEP_ATTACK;
      WAR_ACTION_STEP_SOUND_SWORD..WAR_ACTION_STEP_SOUND_LIGHTNING:
        LAction^.LastSoundStep := LStep.StepType;
    end;
    Inc(LAction^.StepIndex);
    if LAction^.StepIndex >= LDef^.Count then
    begin
      if not LDef^.Loop then
      begin
        LAction^.Status := WAR_ACTION_FINISHED;
        Exit;
      end;
      LAction^.StepIndex := 0;
    end;
    LStep := WAR_ACTION_STEPS[LDef^.First + LAction^.StepIndex];
  end;
  // a Single product: the original multiplies two floats
  LSeconds := TWarModelMath.FramesToSeconds(LStep.Param) * LAction^.Scale;
  LAction^.WaitEndGameTime := AContext.Clock^.GameTime + LSeconds;
end;

class procedure TWarActionStepper.UpdateAll(AContext: TWarModelContext);
var
  LUnits: TList<Integer>;
  LIndex: Integer;
begin
  LUnits := AContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
    Update(AContext, AContext.Pool.Slots[LUnits[LIndex]]);
end;

end.
