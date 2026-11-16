{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the way a kind of AI command is executed           }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.c (wai_executeAICommand and its          }
{  cases), (c) 2019 Alejandro Coto Gutierrez, zlib License (see                 }
{  Games\War\LICENSE-war1.txt). This is an altered version, not the original.  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.Handler;

interface

uses
  DelphiDoom.War.Ai.Command, DelphiDoom.War.Ai.Environment;

type
  /// <summary>
  ///   The strategy of one kind of command (the registry has one per kind: the original has a switch). Execute returns the
  ///   same Boolean as the wai_execute*AICommand functions: True if the script may go on to its next command. A command
  ///   runs once per tic per player (a handler is called for a command, never for a unit)
  /// </summary>
  TWarAiCommandHandler = class abstract
  public
    function Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean; virtual; abstract;
  end;

implementation

end.
