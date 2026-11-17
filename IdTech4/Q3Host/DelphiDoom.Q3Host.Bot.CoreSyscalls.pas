{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the BOTLIB system calls of the library  }
{  itself (setup, variables, frame, map, entities, the server side of a bot)   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,      }
{  sv_bot.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is derived    }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.Bot.CoreSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Bot.Registrar;

type
  /// <summary>
  ///   BOTLIB_SETUP (SV_BotLibSetup: nothing when bot_enable was 0 when the game programs started),
  ///   BOTLIB_SHUTDOWN, BOTLIB_LIBVAR_SET and _GET, BOTLIB_START_FRAME, BOTLIB_LOAD_MAP, BOTLIB_UPDATENTITY,
  ///   BOTLIB_TEST (the debug drawing of the library: nothing), BOTLIB_GET_SNAPSHOT_ENTITY,
  ///   BOTLIB_GET_CONSOLE_MESSAGE and BOTLIB_USER_COMMAND (SV_ClientThink: the command is stored and the game
  ///   thinks, a nested call of the machine that is calling)
  /// </summary>
  TQ3BotCoreSyscalls = class
  public
    class procedure Register(const ARegistrar: TQ3BotRegistrar; ABotEnabled: Boolean); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Aas.Entity.Types, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.Arguments, DelphiDoom.Q3Host.Bot.Intf, DelphiDoom.Q3Host.Bot.Memory;

const
  USERCMD_SIZE = 24;

class procedure TQ3BotCoreSyscalls.Register(const ARegistrar: TQ3BotRegistrar; ABotEnabled: Boolean);
begin
  ARegistrar.Add(BOTLIB_SETUP,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      // SV_BotLibSetup
      if not ABotEnabled then
        Exit(0);
      Result := ARegistrar.Lib.Setup;
    end);

  ARegistrar.Add(BOTLIB_SHUTDOWN,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ARegistrar.Lib.Shutdown;
    end);

  ARegistrar.Add(BOTLIB_LIBVAR_SET,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ARegistrar.Lib.LibVarSet(TQ3SyscallArguments.Text(AMachine, AArgs[1], 'BOTLIB_LIBVAR_SET'),
        TQ3BotMemory.OptionalText(AMachine.Memory, AArgs[2]));
    end);

  ARegistrar.Add(BOTLIB_LIBVAR_GET,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LValue: AnsiString;
    begin
      LValue := ARegistrar.Lib.LibVarGet(TQ3SyscallArguments.Text(AMachine, AArgs[1], 'BOTLIB_LIBVAR_GET'),
        AArgs[3]);
      // strncpy( value, varvalue, size - 1 ); value[size - 1] = 0
      if AArgs[3] > 0 then
        AMachine.Memory.WriteString(AArgs[2], LValue, AArgs[3]);
      Result := 0;
    end);

  ARegistrar.Add(BOTLIB_START_FRAME,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ARegistrar.Lib.StartFrame(TQ3SyscallArguments.ToSingle(AArgs[1]));
    end);

  ARegistrar.Add(BOTLIB_LOAD_MAP,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ARegistrar.Lib.LoadMap(TQ3SyscallArguments.Text(AMachine, AArgs[1], 'BOTLIB_LOAD_MAP'));
    end);

  ARegistrar.Add(BOTLIB_UPDATENTITY,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LState: TBotEntityState;
    begin
      // a NULL state unlinks the entity
      if AArgs[2] = 0 then
        Exit(ARegistrar.Lib.UpdateEntity(AArgs[1], nil));
      LState := TQ3BotMemory.ReadEntityState(AMachine.Memory, AArgs[2]);
      Result := ARegistrar.Lib.UpdateEntity(AArgs[1], @LState);
    end);

  ARegistrar.Add(BOTLIB_PC_ADD_GLOBAL_DEFINE,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      // the missionpack game defines MISSIONPACK for the scripts of the bots. The define is accepted (qtrue) and not
      // kept: the parsers of IdTech4\BotAi (TIdParser) have no global defines, and the files of the bots that
      // OpenArena ships do not test it
      TQ3SyscallArguments.Text(AMachine, AArgs[1], 'BOTLIB_PC_ADD_GLOBAL_DEFINE');
      Result := 1;
    end);

  ARegistrar.Add(BOTLIB_TEST,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      // BotExportTest only draws the debug lines of the library
      Result := 0;
    end);

  ARegistrar.Add(BOTLIB_GET_SNAPSHOT_ENTITY,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      if Assigned(ARegistrar.Server) then
        Result := ARegistrar.Server.SnapshotEntity(AArgs[1], AArgs[2])
      else
        Result := -1;
    end);

  ARegistrar.Add(BOTLIB_GET_CONSOLE_MESSAGE,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LText: AnsiString;
    begin
      Result := 0;
      if not Assigned(ARegistrar.Server) or not ARegistrar.Server.ConsoleMessage(AArgs[1], LText) then
        Exit;
      // Q_strncpyz( buf, command, size )
      AMachine.Memory.WriteString(AArgs[2], LText, AArgs[3]);
      Result := 1;
    end);

  ARegistrar.Add(BOTLIB_USER_COMMAND,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      // SV_ClientThink( &svs.clients[client], cmd )
      if Assigned(ARegistrar.Server) and
        ARegistrar.Server.UserCommand(AArgs[1], AMachine.Memory.ReadBytes(AArgs[2], USERCMD_SIZE)) then
        AMachine.Call(GAME_CLIENT_THINK, [AArgs[1]]);
      Result := 0;
    end);
end;

end.
