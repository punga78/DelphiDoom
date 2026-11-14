{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the wait for units of the AI                       }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.c (wai_executeWaitAICommand), (c) 2019  }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).      }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.WaitHandler;

interface

uses
  DelphiDoom.War.Ai.Command, DelphiDoom.War.Ai.Environment, DelphiDoom.War.Ai.Handler;

type
  /// <summary>
  ///   WAR_AI_COMMAND_WAIT: done when the player has at least Count units of the type (buildings under construction
  ///   count: they are entities of the player); until then the script does not go on
  /// </summary>
  TWarAiWaitHandler = class(TWarAiCommandHandler)
  public
    function Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean; override;
  end;

implementation

uses
  DelphiDoom.War.Ai.Types;

{ TWarAiWaitHandler }

function TWarAiWaitHandler.Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean;
begin
  ACommand.Status := WAR_AI_STATUS_STARTED;
  Result := AEnvironment.World.Queries.CountUnitsOfType(AEnvironment.PlayerIndex, ACommand.UnitType) >= ACommand.Count;
  if Result then
    ACommand.Status := WAR_AI_STATUS_COMPLETED;
end;

end.
