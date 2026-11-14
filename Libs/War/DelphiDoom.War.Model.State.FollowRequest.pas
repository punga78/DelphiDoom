{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - asking a unit to follow                           }
{                                                                              }
{  Port of war1 (acoto87/war1), wst_createFollowState of                       }
{  war_state_machine_follow.c, (c) 2019 Alejandro Coto Gutierrez, zlib License }
{  (see Libs\War\LICENSE-war1.txt). This is an altered version, not the        }
{  original.                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.FollowRequest;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   Only the creation of the follow state (the gatherers push one to walk to a mine or a town hall). The update
  ///   of the state, which walks to the target and ends when the unit is near it, belongs to the follow and patrol
  ///   slice and is not ported: until then a follow state that is pushed stays as it is
  /// </summary>
  TWarFollowRequest = class
  public
    /// <summary>wst_createFollowState; nil if the storage is full</summary>
    class function New(AMachine: TWarStateMachine; ASlot: Integer; ATargetId: Word; const ATargetPosition: TWarVec2;
      ATargetDistance: Integer): PWarStateFollow; static;
  end;

implementation

{ TWarFollowRequest }

class function TWarFollowRequest.New(AMachine: TWarStateMachine; ASlot: Integer; ATargetId: Word;
  const ATargetPosition: TWarVec2; ATargetDistance: Integer): PWarStateFollow;
begin
  Result := PWarStateFollow(AMachine.AllocState(ASlot, WAR_STATE_FOLLOW));
  if Assigned(Result) then
  begin
    Result^.TargetEntityId := ATargetId;
    Result^.TargetPosition := ATargetPosition;
    Result^.TargetDistance := ATargetDistance;
  end;
end;

end.
