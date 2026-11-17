{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - where the BOTLIB system calls are      }
{  registered                                                                  }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c.      }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.Registrar;

interface

uses
  DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Bot.Intf;

type
  /// <summary>
  ///   What the groups of BOTLIB system calls share: the bot library and the server side of a bot. Every handler is
  ///   registered with Add, which tells the library which module is calling (its memory holds the entities of the
  ///   world the library traces through) before the handler runs
  /// </summary>
  TQ3BotRegistrar = class
  strict private
    // the registry is the host, which owns this object
    [weak] FRegistry: IQ3SyscallRegistry;
    FLibrary: IQ3BotLibrary;
    FServer: IQ3HostBotServer;
  public
    constructor Create(const ARegistry: IQ3SyscallRegistry; const ALibrary: IQ3BotLibrary;
      const AServer: IQ3HostBotServer);
    procedure Add(ANumber: Integer; const AHandler: TQ3SyscallHandler);
    property Lib: IQ3BotLibrary read FLibrary;
    property Server: IQ3HostBotServer read FServer;
  end;

implementation

uses
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf;

constructor TQ3BotRegistrar.Create(const ARegistry: IQ3SyscallRegistry; const ALibrary: IQ3BotLibrary;
  const AServer: IQ3HostBotServer);
begin
  inherited Create;
  FRegistry := ARegistry;
  FLibrary := ALibrary;
  FServer := AServer;
end;

procedure TQ3BotRegistrar.Add(ANumber: Integer; const AHandler: TQ3SyscallHandler);
begin
  FRegistry.Register(ANumber,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      FLibrary.Attach(AMachine);
      Result := AHandler(AMachine, AArguments);
    end);
end;

end.
