{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - what the bot library asks of the game  }
{  (botimport: Print, AAS time, BotClientCommand)                              }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_bot.c        }
{  (BotImport_Print, BotClientCommand). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.Import;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Q3Host.Intf,
  DelphiDoom.Q3Host.Bot.Intf;

type
  /// <summary>
  ///   IBotImport on the console of the engine and the bot side of the server: BotImport_Print with its colour
  ///   prefixes (a fatal print stops with the module error the C raises as Com_Error( ERR_DROP )),
  ///   BotClientCommand, and AAS_Time from the clock the library gives. The log file of the library (Log_Write)
  ///   is not written
  /// </summary>
  TQ3BotImport = class(TInterfacedObject, IBotImport)
  strict private
    FConsole: IQ3HostConsole;
    FServer: IQ3HostBotServer;
    FTime: TFunc<Single>;
    FMachine: TFunc<IQvmMachine>;
  public
    /// <summary>AMachine gives the game that is calling (the library attaches it to every call)</summary>
    constructor Create(const AConsole: IQ3HostConsole; const AServer: IQ3HostBotServer; const ATime: TFunc<Single>;
      const AMachine: TFunc<IQvmMachine>);
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    procedure LogWrite(const AMessage: AnsiString);
    function Time: Single;
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Q3Host.Types;

resourcestring
  SUnknownPrintType = 'unknown print type'#10;

constructor TQ3BotImport.Create(const AConsole: IQ3HostConsole; const AServer: IQ3HostBotServer;
  const ATime: TFunc<Single>; const AMachine: TFunc<IQvmMachine>);
begin
  inherited Create;
  FConsole := AConsole;
  FServer := AServer;
  FTime := ATime;
  FMachine := AMachine;
end;

procedure TQ3BotImport.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
  case ALevel of
    PRT_MESSAGE:
      FConsole.Print(AMessage);
    PRT_WARNING:
      FConsole.Print('^3Warning: ' + AMessage);
    PRT_ERROR:
      FConsole.Print('^1Error: ' + AMessage);
    PRT_FATAL:
      FConsole.Print('^1Fatal: ' + AMessage);
    PRT_EXIT:
      raise EQ3ModuleErrorException.Create(string('^1Exit: ' + AMessage));
  else
    FConsole.Print(AnsiString(SUnknownPrintType));
  end;
end;

procedure TQ3BotImport.LogWrite(const AMessage: AnsiString);
begin
  // botlib.log is opened only for the library variable "log"; the engine does not keep it
end;

function TQ3BotImport.Time: Single;
begin
  if Assigned(FTime) then
    Result := FTime()
  else
    Result := 0;
end;

procedure TQ3BotImport.Command(const AClient: Integer; const ACommand: AnsiString);
begin
  if Assigned(FServer) and Assigned(FMachine) then
    FServer.ClientCommand(FMachine(), AClient, ACommand);
end;

end.
