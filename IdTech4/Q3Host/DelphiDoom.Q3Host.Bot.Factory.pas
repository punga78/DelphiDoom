{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the factory of the bot library bridge  }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,      }
{  sv_bot.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is derived    }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.Factory;

interface

uses
  DelphiDoom.Console.Q3.Intf, DelphiDoom.Scanner.Q3.SourceHandles, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.SyscallHost, DelphiDoom.Q3Host.Services.Intf,
  DelphiDoom.Q3Host.GameWorld, DelphiDoom.Q3Host.Bot.Intf;

type
  /// <summary>
  ///   The one place that knows the classes of the bridge: the BSP of the bots over the world of the server game,
  ///   the bot library, and the groups of BOTLIB system calls registered in the host of qagame. Everything it
  ///   makes belongs to the host
  /// </summary>
  TQ3BotFactory = class
  public
    /// <summary>
    ///   SV_InitGameProgs asks the cvar bot_enable once (latched, default 1) and SV_BotLibSetup does nothing when it
    ///   was 0: so does the BOTLIB_SETUP registered here. Without AServices.Files nothing is registered
    /// </summary>
    class procedure Register(const AHost: TQ3SyscallHost; const AWorld: TQ3GameWorld;
      const AClipMap: IQ3HostClipMap; const AConsole: IQ3HostConsole; const ACVars: IQ3CVarSystem;
      const AServices: TQ3HostBotServices; const ASources: TQ3SourceHandles = nil); static;
  end;

implementation

uses
  DelphiDoom.Console.Q3.CVar, DelphiDoom.Console.Q3.Types, DelphiDoom.Q3Host.Bot.Bsp, DelphiDoom.Q3Host.Bot.Botlib,
  DelphiDoom.Q3Host.Bot.Registrar, DelphiDoom.Q3Host.Bot.CoreSyscalls, DelphiDoom.Q3Host.Bot.AasSyscalls,
  DelphiDoom.Q3Host.Bot.EaSyscalls, DelphiDoom.Q3Host.Bot.ChatSyscalls, DelphiDoom.Q3Host.Bot.GoalSyscalls,
  DelphiDoom.Q3Host.Bot.MoveSyscalls, DelphiDoom.Q3Host.ClientPrecompilerSyscalls, DelphiDoom.Q3Host.Types;

class procedure TQ3BotFactory.Register(const AHost: TQ3SyscallHost; const AWorld: TQ3GameWorld;
  const AClipMap: IQ3HostClipMap; const AConsole: IQ3HostConsole; const ACVars: IQ3CVarSystem;
  const AServices: TQ3HostBotServices; const ASources: TQ3SourceHandles);
var
  LCVar: TQ3CVar;
  LEnabled: Boolean;
  LBsp: TQ3BotBsp;
  LLibrary: IQ3BotLibrary;
  LRegistrar: TQ3BotRegistrar;
begin
  if not Assigned(AServices.Files) then
    Exit;
  LCVar := ACVars.Get('bot_enable', '1', Q3_CVAR_LATCH);
  LEnabled := Assigned(LCVar) and (LCVar.IntegerValue <> 0);
  LBsp := TQ3BotBsp.Create(AWorld, AClipMap);
  LLibrary := TQ3BotLibrary.Create(AConsole, AServices.Server, AServices.Files, AServices.Random, LBsp);
  LRegistrar := TQ3BotRegistrar.Create(AHost.GetRegistry, LLibrary, AServices.Server);
  AHost.Own(LRegistrar);
  TQ3BotCoreSyscalls.Register(LRegistrar, LEnabled);
  TQ3BotAasSyscalls.Register(LRegistrar);
  TQ3BotEaSyscalls.Register(LRegistrar);
  TQ3BotChatSyscalls.Register(LRegistrar);
  TQ3BotGoalSyscalls.Register(LRegistrar);
  TQ3BotMoveSyscalls.Register(LRegistrar);
  // the sources of botlib are the ones of the client (one table, as botlib_export has)
  if Assigned(ASources) then
    TQ3PrecompilerSyscalls.Register(TQ3Module.Game, AHost.GetRegistry, ASources);
end;

end.
