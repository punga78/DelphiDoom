{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - the variables of the bots                   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): SV_BotInitCvars }
{  (sv_bot.c). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived  }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.BotCvars;

interface

uses
  DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   SV_BotInitCvars: the variables that the game and the botlib read, with the values the server gives them
  ///   (a variable that the command line already set keeps its value)
  /// </summary>
  TQ3BotCvars = class sealed
  public
    class procedure Register(const ACVars: IQ3CVarSystem); static;
  end;

implementation

const
  NAMES: array[0..30] of AnsiString = ('bot_enable', 'bot_developer', 'bot_debug', 'bot_maxdebugpolys',
    'bot_groundonly', 'bot_reachability', 'bot_visualizejumppads', 'bot_forceclustering', 'bot_forcereachability',
    'bot_forcewrite', 'bot_aasoptimize', 'bot_saveroutingcache', 'bot_thinktime', 'bot_reloadcharacters',
    'bot_testichat', 'bot_testrchat', 'bot_testsolid', 'bot_testclusters', 'bot_fastchat', 'bot_nochat', 'bot_pause',
    'bot_report', 'bot_grapple', 'bot_rocketjump', 'bot_challenge', 'bot_minplayers', 'bot_interbreedchar',
    'bot_interbreedbots', 'bot_interbreedcycle', 'bot_interbreedwrite', 'bot_memorydump');
  VALUES: array[0..30] of AnsiString = ('1', '0', '0', '2', '1', '0', '0', '0', '0', '0', '0', '0', '100', '0', '0',
    '0', '0', '0', '0', '0', '0', '0', '0', '1', '0', '0', '', '10', '20', '', '0');

{ TQ3BotCvars }

class procedure TQ3BotCvars.Register(const ACVars: IQ3CVarSystem);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(NAMES) do
    ACVars.Get(NAMES[LIndex], VALUES[LIndex], 0);
end;

end.
