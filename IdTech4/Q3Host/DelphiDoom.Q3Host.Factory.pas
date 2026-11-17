{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - factory                                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,       }
{  cl_cgame.c, cl_ui.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Factory;

interface

uses
  DelphiDoom.Console.Q3.Intf, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf,
  DelphiDoom.Q3Host.Bot.Intf, DelphiDoom.Q3Host.Client.Services, DelphiDoom.Q3Host.GameWorld,
  DelphiDoom.Q3Host.EntityTokens;

type
  /// <summary>
  ///   What the engine gives to the host of a module. Every service is optional: a group of system calls is
  ///   registered only when the services it needs are there (a call that nobody answers raises with its name)
  /// </summary>
  TQ3HostServices = record
    /// <summary>cvars, commands and the command buffer: the cvar and command calls of all the modules</summary>
    CVars: IQ3CVarSystem;
    Arguments: IQ3CommandArguments;
    Buffer: IQ3CommandBuffer;
    Commands: IQ3CommandRegistry;
    /// <summary>The file calls</summary>
    Files: IQ3HostFileSystem;
    /// <summary>The shared clipmap: the collision calls of cgame and the world of qagame</summary>
    ClipMap: IQ3HostClipMap;
    /// <summary>Configstrings, user infos, user commands, bots, and what the server sends: the server calls of qagame</summary>
    State: IQ3HostServerState;
    ServerCommands: IQ3HostServerCommands;
    /// <summary>The real time calls</summary>
    Calendar: IQ3HostCalendar;
    /// <summary>The BOTLIB calls of qagame (phase 2d): registered when Bot.Files is given</summary>
    Bot: TQ3HostBotServices;
    /// <summary>The client services of cgame and ui (phase 2c): state, keys, sound, renderer, parser, server lists</summary>
    Client: TQ3HostClientServices;
    /// <summary>
    ///   The world of the server game (sv_world.c), when the server wants to read the entities the game located
    ///   (the snapshots): the host of qagame uses it and does not own it. nil: the host makes its own
    /// </summary>
    World: TQ3GameWorld;
    /// <summary>
    ///   The entity string reader of the server game (CM_EntityString parse point), when the server has to rewind it
    ///   for a map_restart; the host uses it and does not own it. nil: the host makes its own
    /// </summary>
    Tokens: TQ3EntityTokens;
  end;

  /// <summary>The only place that knows the classes of the host</summary>
  TQ3HostFactory = class
  public
    /// <summary>
    ///   The host of a module with the common system calls already registered (see TQ3CommonSyscalls); the
    ///   engine adds the others (cvars, file system, entities, renderer ...) through Registry
    /// </summary>
    class function CreateHost(AModule: TQ3Module; const AConsole: IQ3HostConsole;
      const ATime: IQ3HostTime): IQ3SyscallHost; static;
    /// <summary>
    ///   CreateHost with the groups of system calls that have a service (phase 2b): cvars and commands, files,
    ///   real time and snap vector, the collision calls of cgame and the world of qagame (with its entity tokens).
    ///   The world and the tokens belong to the host
    /// </summary>
    class function CreateHostWithServices(AModule: TQ3Module; const AConsole: IQ3HostConsole;
      const ATime: IQ3HostTime; const AServices: TQ3HostServices): IQ3SyscallHost; static;
  end;

implementation

uses
  DelphiDoom.Q3Host.SyscallHost, DelphiDoom.Q3Host.CommonSyscalls, DelphiDoom.Q3Host.CvarSyscalls,
  DelphiDoom.Q3Host.FileSyscalls, DelphiDoom.Q3Host.MiscSyscalls, DelphiDoom.Q3Host.CollisionSyscalls,
  DelphiDoom.Q3Host.GameSyscalls,
  DelphiDoom.Q3Host.Bot.Factory;

class function TQ3HostFactory.CreateHost(AModule: TQ3Module; const AConsole: IQ3HostConsole;
  const ATime: IQ3HostTime): IQ3SyscallHost;
var
  LHost: TQ3SyscallHost;
begin
  LHost := TQ3SyscallHost.Create(AModule);
  Result := LHost;
  TQ3CommonSyscalls.Register(AModule, Result.Registry, AConsole, ATime);
end;

class function TQ3HostFactory.CreateHostWithServices(AModule: TQ3Module; const AConsole: IQ3HostConsole;
  const ATime: IQ3HostTime; const AServices: TQ3HostServices): IQ3SyscallHost;
var
  LHost: TQ3SyscallHost;
  LWorld: TQ3GameWorld;
  LTokens: TQ3EntityTokens;
begin
  LHost := TQ3SyscallHost.Create(AModule);
  Result := LHost;
  TQ3CommonSyscalls.Register(AModule, Result.Registry, AConsole, ATime);

  if Assigned(AServices.CVars) and Assigned(AServices.Arguments) and Assigned(AServices.Buffer)
    and Assigned(AServices.Commands) then
    TQ3CvarSyscalls.Register(AModule, Result.Registry, AServices.CVars, AServices.Arguments, AServices.Buffer,
      AServices.Commands);
  if Assigned(AServices.Files) then
    TQ3FileSyscalls.Register(AModule, Result.Registry, AServices.Files);
  if Assigned(AServices.Calendar) then
    TQ3MiscSyscalls.Register(AModule, Result.Registry, AServices.Calendar);
  TQ3ClientGroups.Register(AModule, Result.Registry, AServices.Client, AServices.CVars);

  if not Assigned(AServices.ClipMap) then
    Exit;
  case AModule of
    TQ3Module.CGame:
      begin
        LTokens := TQ3EntityTokens.Create(AServices.ClipMap);
        LHost.Own(LTokens);
        TQ3CollisionSyscalls.RegisterCGame(Result.Registry, AServices.ClipMap, LTokens);
      end;
    TQ3Module.Game:
      if Assigned(AServices.State) and Assigned(AServices.ServerCommands) and Assigned(AServices.CVars) then
      begin
        if Assigned(AServices.World) then
          LWorld := AServices.World
        else
        begin
          LWorld := TQ3GameWorld.Create(AServices.ClipMap, AConsole);
          LHost.Own(LWorld);
        end;
        if Assigned(AServices.Tokens) then
          LTokens := AServices.Tokens
        else
        begin
          LTokens := TQ3EntityTokens.Create(AServices.ClipMap);
          LHost.Own(LTokens);
        end;
        TQ3GameSyscalls.Register(Result.Registry, LWorld, AServices.State, AServices.ServerCommands,
          AServices.ClipMap, LTokens, AServices.CVars);
        TQ3BotFactory.Register(LHost, LWorld, AServices.ClipMap, AConsole, AServices.CVars, AServices.Bot,
          AServices.Client.Sources);
      end;
  end;
end;

end.
