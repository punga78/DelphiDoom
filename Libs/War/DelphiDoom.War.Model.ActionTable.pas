{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the actions that each unit type has               }
{                                                                              }
{  Port of war1 (acoto87/war1), wact_getActionDuration and wact_setAction of   }
{  war_actions.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see         }
{  Libs\War\LICENSE-war1.txt). This is an altered version.                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.ActionTable;

interface

uses
  DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   What the animations of a unit type are, as far as the model needs: which actions it has and how many frames
  ///   they last (the sum of the wait steps). The steps themselves (which frame, which sound) are the business of the
  ///   actions, not done yet. Static functions: the move state asks at every tic
  /// </summary>
  TWarActionTable = class
  public
    /// <summary>The unit type has an action of that type (gUnitActionDefs[type][action].type is not NONE)</summary>
    class function Has(AUnitType, AAction: Integer): Boolean; static;
    /// <summary>wact_getActionDuration: frames; 0 for an action that the type does not have, or for NONE</summary>
    class function Duration(AUnitType, AAction: Integer): Integer; static;
    /// <summary>
    ///   wact_setAction on the component of a unit: the action becomes the current one (with its scale if it is not
    ///   negative, and from the start if AReset); a type without that action leaves everything as it is
    /// </summary>
    class procedure SetAction(var AUnit: TWarUnitComponent; AAction: Integer; AReset: Boolean; AScale: Single); static;
    /// <summary>wact_addUnitActions: every action not started, scale 1, no step</summary>
    class procedure InitActions(var AUnit: TWarUnitComponent); static;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.ActionData;

{ TWarActionTable }

class function TWarActionTable.Has(AUnitType, AAction: Integer): Boolean;
begin
  Result := (AUnitType >= 0) and (AUnitType < WAR_UNIT_COUNT) and (AAction >= 0) and (AAction < WAR_ACTION_TYPE_COUNT) and
    (WAR_ACTION_DURATIONS[AUnitType, AAction] >= 0);
end;

class function TWarActionTable.Duration(AUnitType, AAction: Integer): Integer;
begin
  if Has(AUnitType, AAction) then
    Result := WAR_ACTION_DURATIONS[AUnitType, AAction]
  else
    Result := 0;
end;

class procedure TWarActionTable.SetAction(var AUnit: TWarUnitComponent; AAction: Integer; AReset: Boolean;
  AScale: Single);
begin
  if AAction <> WAR_ACTION_NONE then
  begin
    if not Has(AUnit.UnitType, AAction) then
      Exit;
    AUnit.ActionType := AAction;
    if AScale >= 0 then
      AUnit.Actions[AAction].Scale := AScale;
    if AReset then
    begin
      AUnit.Actions[AAction].StepIndex := 0;
      AUnit.Actions[AAction].Status := WAR_ACTION_NOT_STARTED;
      AUnit.Actions[AAction].WaitEndGameTime := 0;
    end;
  end
  else
    AUnit.ActionType := AAction;
end;

class procedure TWarActionTable.InitActions(var AUnit: TWarUnitComponent);
var
  LIndex: Integer;
begin
  for LIndex := 0 to WAR_ACTION_TYPE_COUNT - 1 do
  begin
    AUnit.Actions[LIndex].Status := WAR_ACTION_NOT_STARTED;
    AUnit.Actions[LIndex].Scale := 1.0;
    AUnit.Actions[LIndex].WaitEndGameTime := 0;
    AUnit.Actions[LIndex].StepIndex := -1;
    AUnit.Actions[LIndex].LastActionStep := 0;
    AUnit.Actions[LIndex].LastSoundStep := 0;
  end;
end;

end.
