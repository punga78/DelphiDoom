{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the registry of the kinds of AI command            }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.c (wai_executeAICommand: the switch on   }
{  the type of command, here a table), (c) 2019 Alejandro Coto Gutierrez, zlib  }
{  License (see Games\War\LICENSE-war1.txt). This is an altered version.       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.Registry;

interface

uses
  DelphiDoom.War.Ai.Command, DelphiDoom.War.Ai.Environment, DelphiDoom.War.Ai.Handler, DelphiDoom.War.Ai.Types;

type
  /// <summary>
  ///   Kind of command -> handler. REQUEST, WAIT and SLEEP are registered by CreateDefault; ATTACK and DEFEND are not (the
  ///   original does not handle them): a command of a kind with no handler gives a warning and is "done" at once, as the
  ///   default of the switch does. Whoever adds attack or defense registers a handler, no case to change. The registry
  ///   owns its handlers
  /// </summary>
  TWarAiCommandRegistry = class
  strict private
    FHandlers: array[0..WAR_AI_COMMAND_COUNT - 1] of TWarAiCommandHandler;
  public
    destructor Destroy; override;
    /// <summary>The registry of the original: REQUEST, WAIT and SLEEP</summary>
    class function CreateDefault: TWarAiCommandRegistry; static;
    /// <summary>Registers (or replaces, freeing the old one) the handler of a kind; the registry owns it</summary>
    procedure RegisterHandler(ACommandType: Integer; const AHandler: TWarAiCommandHandler);
    function HasHandler(ACommandType: Integer): Boolean;
    /// <summary>wai_executeAICommand: a completed command is "done"; without a handler a warning and "done"</summary>
    function Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Ai.RequestHandler, DelphiDoom.War.Ai.WaitHandler,
  DelphiDoom.War.Ai.SleepHandler;

{ TWarAiCommandRegistry }

destructor TWarAiCommandRegistry.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FHandlers) do
    FHandlers[LIndex].Free;
  inherited;
end;

class function TWarAiCommandRegistry.CreateDefault: TWarAiCommandRegistry;
begin
  Result := TWarAiCommandRegistry.Create;
  try
    Result.RegisterHandler(WAR_AI_COMMAND_REQUEST, TWarAiRequestHandler.Create);
    Result.RegisterHandler(WAR_AI_COMMAND_WAIT, TWarAiWaitHandler.Create);
    Result.RegisterHandler(WAR_AI_COMMAND_SLEEP, TWarAiSleepHandler.Create);
  except
    Result.Free;
    raise;
  end;
end;

procedure TWarAiCommandRegistry.RegisterHandler(ACommandType: Integer; const AHandler: TWarAiCommandHandler);
begin
  if (ACommandType < 0) or (ACommandType >= WAR_AI_COMMAND_COUNT) then
  begin
    AHandler.Free;
    raise EWarException.CreateFmt('AI command type %d is not valid', [ACommandType]);
  end;
  if FHandlers[ACommandType] <> AHandler then
    FHandlers[ACommandType].Free;
  FHandlers[ACommandType] := AHandler;
end;

function TWarAiCommandRegistry.HasHandler(ACommandType: Integer): Boolean;
begin
  Result := (ACommandType >= 0) and (ACommandType < WAR_AI_COMMAND_COUNT) and Assigned(FHandlers[ACommandType]);
end;

function TWarAiCommandRegistry.Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean;
begin
  if ACommand.Status = WAR_AI_STATUS_COMPLETED then
    Exit(True);
  if HasHandler(ACommand.CommandType) then
    Exit(FHandlers[ACommand.CommandType].Execute(AEnvironment, ACommand));
  AEnvironment.Warn('AI commands of type ' + IntToStr(ACommand.CommandType) + ' are NOT handled yet');
  Result := True;
end;

end.
