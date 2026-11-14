{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the attack command                                }
{                                                                              }
{  Port of war1 (acoto87/war1), wcmd_executeAttackCommand of war_commands.c,   }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.Attack;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Commands.Family;

type
  /// <summary>
  ///   The attack of a unit, of the wall (the piece of the tile of the point) or of a point (the units go there and fight
  ///   who they meet). A worker told to attack a unit follows it instead. Defects of the original kept: buildings and
  ///   workers get the attack of a point too (their attack state ends when they are there, or never for a building);
  ///   there is no acknowledgement when only workers follow
  /// </summary>
  TWarAttackCommands = class(TWarCommandFamily)
  public
    /// <summary>
    ///   wcmd_executeAttackCommand: ATargetSlot is the slot of the unit or of the wall, 0 for the attack of the point
    ///   ATarget (pixels of the map). True if someone attacks
    /// </summary>
    function Attack(ATargetSlot: Integer; const ATarget: TWarVec2): Boolean;
  end;

implementation

uses
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.UnitClassifier;

{ TWarAttackCommands }

function TWarAttackCommands.Attack(ATargetSlot: Integer; const ATarget: TWarVec2): Boolean;
var
  LIndex: Integer;
  LSlot: Integer;
  LAcknowledge: Integer;
  LTargetId: Word;
begin
  Result := False;
  LAcknowledge := 0;
  LTargetId := 0;
  if ATargetSlot <> 0 then
    LTargetId := Context.Pool.Slots[ATargetSlot]^.Id;
  for LIndex := 0 to Commander.Selection.Count - 1 do
  begin
    LSlot := SelectedSlot(LIndex);
    if not (IsOwn(LSlot) and CanOrder(LSlot)) then
      Continue;
    if ATargetSlot <> 0 then
    begin
      // a unit can not attack itself
      if LSlot = ATargetSlot then
        Continue;
      if not Context.Queries.CanAttack(LSlot, ATargetSlot) then
      begin
        if TWarUnitClassifier.IsWorker(Context.Pool.Slots[LSlot]^.UnitData.UnitType) then
          Order(LSlot, Machine.CreateFollow(LSlot, LTargetId, Default(TWarVec2), WAR_MODEL_MEGA_TILE));
        Continue;
      end;
    end;
    Order(LSlot, Machine.CreateAttack(LSlot, LTargetId, ATarget));
    if LAcknowledge = 0 then
      LAcknowledge := LSlot;
    Result := True;
  end;
  if Result then
    Acknowledge(LAcknowledge);
end;

end.
