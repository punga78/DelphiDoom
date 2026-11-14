{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the steps of the actions of the units             }
{                                                                              }
{  Port of war1 (acoto87/war1), wact_updateAction of war_actions.c, (c) 2019   }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.ActionRunner;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context;

type
  /// <summary>
  ///   The current action of a unit advances by its steps: it waits for the end of a wait step, then goes through the
  ///   steps up to the next wait, noting the blow (WAR_ACTION_STEP_ATTACK) and the sound that the steps ask for, which the
  ///   states read (the attack state hits when the blow is noted, the repairing one when the hammer falls, the gatherers
  ///   when the axe or the pick hits), and showing the frame that a frame step asks for (the sprite of the entity, mirrored
  ///   for the west). It is the one runner of the actions of all the areas (attack, gathering, repairing, building...): the
  ///   table of the steps is one, generated from the C (DelphiDoom.War.Model.ActionSteps.Data). Static: called once per
  ///   unit and tic
  /// </summary>
  TWarActionRunner = class
  public
    /// <summary>wact_resetAction: from the first step, not started (an action index outside the seven is left alone)</summary>
    class procedure Reset(var AUnit: TWarUnitComponent; AAction: Integer); static;
    /// <summary>wact_updateAction</summary>
    class procedure Update(AEntity: PWarEntity; AGameTime: Double); static;
    /// <summary>updateActions of wmap_updateMap: every unit, in the order of the list of the units</summary>
    class procedure UpdateAll(AContext: TWarModelContext); static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.ActionSteps.Data,
  DelphiDoom.War.Model.Math;

{ TWarActionRunner }

class procedure TWarActionRunner.Reset(var AUnit: TWarUnitComponent; AAction: Integer);
begin
  // the original indexes the array with the action that the unit has (it never has none here)
  if (AAction < 0) or (AAction >= WAR_ACTION_TYPE_COUNT) then
    Exit;
  AUnit.Actions[AAction].StepIndex := 0;
  AUnit.Actions[AAction].Status := WAR_ACTION_NOT_STARTED;
  AUnit.Actions[AAction].WaitEndGameTime := 0;
end;

class procedure TWarActionRunner.Update(AEntity: PWarEntity; AGameTime: Double);
var
  LUnit: PWarUnitComponent;
  LAction: ^TWarUnitAction;
  LDef: ^TWarActionDefData;
  LStep: TWarActionStepData;
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
    Reset(LUnit^, LUnit^.ActionType);
  LAction^.Status := WAR_ACTION_RUNNING;
  LDef := @WAR_ACTION_DEF_DATA[LUnit^.UnitType, LUnit^.ActionType];
  if not LDef^.Present then
  begin
    // the unit type has no such action: the original warns and stops it
    LAction^.Status := WAR_ACTION_FINISHED;
    LUnit^.ActionType := WAR_ACTION_NONE;
    Exit;
  end;
  LStep := WAR_ACTION_STEP_DATA[LDef^.Start + LAction^.StepIndex];
  if LStep.Kind = WAR_ACTION_STEP_WAIT then
  begin
    if AGameTime < LAction^.WaitEndGameTime then
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
    LStep := WAR_ACTION_STEP_DATA[LDef^.Start + LAction^.StepIndex];
  end;
  LAction^.LastActionStep := WAR_ACTION_STEP_NONE;
  LAction^.LastSoundStep := WAR_ACTION_STEP_NONE;
  while LStep.Kind <> WAR_ACTION_STEP_WAIT do
  begin
    if LStep.Kind = WAR_ACTION_STEP_FRAME then
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
    end
    else if LStep.Kind = WAR_ACTION_STEP_ATTACK then
      LAction^.LastActionStep := WAR_ACTION_STEP_ATTACK
    else if (LStep.Kind >= WAR_ACTION_STEP_SOUND_SWORD) and (LStep.Kind <= WAR_ACTION_STEP_SOUND_LIGHTNING) then
      LAction^.LastSoundStep := LStep.Kind;
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
    LStep := WAR_ACTION_STEP_DATA[LDef^.Start + LAction^.StepIndex];
  end;
  // (f32)frames / 60 * scale, in 32 bit, added to the double time
  LSeconds := TWarModelMath.FramesToSeconds(LStep.Param);
  LSeconds := LSeconds * LAction^.Scale;
  LAction^.WaitEndGameTime := AGameTime + LSeconds;
end;

class procedure TWarActionRunner.UpdateAll(AContext: TWarModelContext);
var
  LUnits: TList<Integer>;
  LIndex: Integer;
begin
  LUnits := AContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
    Update(AContext.Pool.Slots[LUnits[LIndex]], AContext.Clock^.GameTime);
end;

end.
