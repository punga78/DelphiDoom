{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the bot side of a server that has no   }
{  network (the reliable commands, the snapshots and the commands of a bot)    }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_bot.c        }
{  (SV_BotGetConsoleMessage, SV_BotGetSnapshotEntity), sv_main.c               }
{  (SV_AddServerCommand), sv_client.c (SV_ClientThink). Copyright (C)          }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.Server;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.ServerState,
  DelphiDoom.Q3Host.Bot.Intf;

type
  /// <summary>Runs a command that a bot sent as its client (SV_ExecuteClientCommand), in the game that is calling</summary>
  TQ3BotClientCommand = reference to procedure(const AMachine: IQvmMachine; AClient: Integer;
    const ACommand: AnsiString);

  /// <summary>
  ///   IQ3HostBotServer and IQ3HostServerCommands of a server with no connections: the reliable commands the game
  ///   sends are queued for each client in the ring of 64 the C keeps (reliableCommands, reliableSequence and
  ///   reliableAcknowledge), and a bot reads them with ConsoleMessage; the snapshot of a client is the list of the
  ///   entity numbers that the server gives it with SetSnapshot (empty: the bot sees no entity); the user command
  ///   goes to the state of the server. Give the same object as ServerCommands and as the bot server
  /// </summary>
  TQ3HostBotServer = class(TInterfacedObject, IQ3HostBotServer, IQ3HostServerCommands)
  strict private
    const
      MAX_RELIABLE_COMMANDS = 64;
      MAX_CLIENTS = 64;
    type
      TClientQueue = record
        Commands: array[0..MAX_RELIABLE_COMMANDS - 1] of AnsiString;
        Sequence: Integer;
        Acknowledge: Integer;
      end;
    var
      FState: TQ3HostServerState;
      FOnCommand: TQ3BotClientCommand;
      FQueues: array[0..MAX_CLIENTS - 1] of TClientQueue;
      FSnapshots: array[0..MAX_CLIENTS - 1] of TArray<Integer>;
    procedure AddCommand(AClient: Integer; const AText: AnsiString);
  public
    /// <summary>The state is not owned; AOnCommand may be nil (the commands of the bots are ignored)</summary>
    constructor Create(const AState: TQ3HostServerState; const AOnCommand: TQ3BotClientCommand);
    procedure ClientCommand(const AMachine: IQvmMachine; AClient: Integer; const ACommand: AnsiString);
    function ConsoleMessage(AClient: Integer; out AText: AnsiString): Boolean;
    function SnapshotEntity(AClient, ASequence: Integer): Integer;
    function UserCommand(AClient: Integer; const ACommand: TBytes): Boolean;
    /// <summary>SV_SendServerCommand: -1 is every client that is in use</summary>
    procedure Send(AClient: Integer; const AText: AnsiString);
    /// <summary>The server without connections does not drop anyone</summary>
    procedure Drop(AClient: Integer; const AReason: AnsiString);
    /// <summary>The entities of the last snapshot of the client, in the order of the snapshot</summary>
    procedure SetSnapshot(AClient: Integer; const AEntities: TArray<Integer>);
  end;

implementation

procedure TQ3HostBotServer.AddCommand(AClient: Integer; const AText: AnsiString);
var
  LQueue: ^TClientQueue;
begin
  LQueue := @FQueues[AClient];
  Inc(LQueue.Sequence);
  // the C drops the client when the ring would overflow; this server forgets the oldest command
  if LQueue.Sequence - LQueue.Acknowledge = MAX_RELIABLE_COMMANDS + 1 then
    Inc(LQueue.Acknowledge);
  LQueue.Commands[LQueue.Sequence and (MAX_RELIABLE_COMMANDS - 1)] := AText;
end;

constructor TQ3HostBotServer.Create(const AState: TQ3HostServerState; const AOnCommand: TQ3BotClientCommand);
begin
  inherited Create;
  FState := AState;
  FOnCommand := AOnCommand;
end;

procedure TQ3HostBotServer.ClientCommand(const AMachine: IQvmMachine; AClient: Integer; const ACommand: AnsiString);
begin
  if Assigned(FOnCommand) then
    FOnCommand(AMachine, AClient, ACommand);
end;

function TQ3HostBotServer.ConsoleMessage(AClient: Integer; out AText: AnsiString): Boolean;
var
  LQueue: ^TClientQueue;
  LIndex: Integer;
begin
  AText := '';
  LQueue := @FQueues[AClient];
  if LQueue.Acknowledge = LQueue.Sequence then
    Exit(False);
  Inc(LQueue.Acknowledge);
  LIndex := LQueue.Acknowledge and (MAX_RELIABLE_COMMANDS - 1);
  if LQueue.Commands[LIndex] = '' then
    Exit(False);
  AText := LQueue.Commands[LIndex];
  Result := True;
end;

function TQ3HostBotServer.SnapshotEntity(AClient, ASequence: Integer): Integer;
begin
  if (ASequence < 0) or (ASequence >= Length(FSnapshots[AClient])) then
    Exit(-1);
  Result := FSnapshots[AClient][ASequence];
end;

function TQ3HostBotServer.UserCommand(AClient: Integer; const ACommand: TBytes): Boolean;
begin
  FState.SetUsercmd(AClient, ACommand);
  Result := FState.IsClientActive(AClient);
end;

procedure TQ3HostBotServer.Send(AClient: Integer; const AText: AnsiString);
var
  LIndex: Integer;
begin
  if AClient >= 0 then
    AddCommand(AClient, AText)
  else
    for LIndex := 0 to FState.MaxClients - 1 do
      if FState.IsClientActive(LIndex) then
        AddCommand(LIndex, AText);
end;

procedure TQ3HostBotServer.Drop(AClient: Integer; const AReason: AnsiString);
begin
  // a client of this server is a slot of the state: nothing to disconnect
end;

procedure TQ3HostBotServer.SetSnapshot(AClient: Integer; const AEntities: TArray<Integer>);
begin
  FSnapshots[AClient] := Copy(AEntities);
end;

end.
