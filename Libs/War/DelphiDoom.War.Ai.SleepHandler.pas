{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sleep of the AI                                }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.c (wai_executeSleepAICommand), (c) 2019 }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).      }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.SleepHandler;

interface

uses
  DelphiDoom.War.Ai.Command, DelphiDoom.War.Ai.Environment, DelphiDoom.War.Ai.Handler;

type
  /// <summary>
  ///   WAR_AI_COMMAND_SLEEP: done when the REAL time (context->realTime, not the time of the game: the hurry up cheat does
  ///   not shorten it) reaches the end of the sleep
  /// </summary>
  TWarAiSleepHandler = class(TWarAiCommandHandler)
  public
    function Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean; override;
  end;

implementation

uses
  DelphiDoom.War.Ai.Types;

{ TWarAiSleepHandler }

function TWarAiSleepHandler.Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean;
begin
  ACommand.Status := WAR_AI_STATUS_STARTED;
  Result := AEnvironment.World.Context.RealTime >= ACommand.EndRealTime;
  if Result then
    ACommand.Status := WAR_AI_STATUS_COMPLETED;
end;

end.
