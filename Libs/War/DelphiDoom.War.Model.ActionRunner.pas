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
  DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   The current action of a unit advances by its steps: it waits for the end of a wait step, then goes through the
  ///   steps up to the next wait, noting the blow (WAR_ACTION_STEP_ATTACK) and the sound that the steps ask for, which the
  ///   states read (the attack state hits when the blow is noted). The frame steps would choose the sprite: that is
  ///   drawing and is not done here (the step index tells it). Static: called once per unit and tic
  /// </summary>
  TWarActionRunner = class
  public
    /// <summary>wact_updateAction</summary>
    class procedure Update(AEntity: PWarEntity; AGameTime: Double); static;
  end;

implementation

uses
  DelphiDoom.War.Model.ActionSteps.Data, DelphiDoom.War.Model.Math;

{ TWarActionRunner }

class procedure TWarActionRunner.Update(AEntity: PWarEntity; AGameTime: Double);
var
  LUnit: PWarUnitComponent;
  LAction: ^TWarUnitAction;
  LDef: ^TWarActionDefData;
  LStep: TWarActionStepData;
  LSeconds: Single;
begin
  LUnit := @AEntity^.UnitData;
  if LUnit^.ActionType = WAR_ACTION_NONE then
    Exit;
  LAction := @LUnit^.Actions[LUnit^.ActionType];
  if LAction^.Status = WAR_ACTION_FINISHED then
    Exit;
  if LAction^.StepIndex < 0 then
  begin
    // resetAction
    LAction^.StepIndex := 0;
    LAction^.Status := WAR_ACTION_NOT_STARTED;
    LAction^.WaitEndGameTime := 0;
  end;
  LAction^.Status := WAR_ACTION_RUNNING;
  LDef := @WAR_ACTION_DEF_DATA[LUnit^.UnitType, LUnit^.ActionType];
  if not LDef^.Present then
  begin
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
    if LStep.Kind = WAR_ACTION_STEP_ATTACK then
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

end.
