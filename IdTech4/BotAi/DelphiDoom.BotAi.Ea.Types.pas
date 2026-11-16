{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - the bot input and the action flags                     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): code\game\      }
{  botlib.h (bot_input_t, ACTION_*). Copyright (C) 1999-2005 Id Software, Inc. }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your        }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Ea.Types;

interface

uses
  DelphiDoom.MathCore.Types;

const
  /// <summary>The action flags of botlib.h (ACTION_*)</summary>
  ACTION_ATTACK = $0000001;
  ACTION_USE = $0000002;
  ACTION_RESPAWN = $0000008;
  ACTION_JUMP = $0000010;
  ACTION_MOVEUP = $0000020;
  ACTION_CROUCH = $0000080;
  ACTION_MOVEDOWN = $0000100;
  ACTION_MOVEFORWARD = $0000200;
  ACTION_MOVEBACK = $0000800;
  ACTION_MOVELEFT = $0001000;
  ACTION_MOVERIGHT = $0002000;
  ACTION_DELAYEDJUMP = $0008000;
  ACTION_TALK = $0010000;
  ACTION_GESTURE = $0020000;
  ACTION_WALK = $0080000;
  ACTION_AFFIRMATIVE = $0100000;
  ACTION_NEGATIVE = $0200000;
  ACTION_GETFLAG = $0800000;
  ACTION_GUARDBASE = $1000000;
  ACTION_PATROL = $2000000;
  ACTION_FOLLOWME = $8000000;
  /// <summary>ACTION_JUMPEDLASTFRAME of be_ea.c: the bot jumped in the last frame</summary>
  ACTION_JUMPEDLASTFRAME = 128;
  /// <summary>MAX_USERMOVE of be_ea.c: the limit of the speed of a move</summary>
  MAX_USERMOVE = 400;

type
  /// <summary>bot_input_t: what the bot wants to do in this frame (the game converts it to a usercmd_t)</summary>
  TBotInput = record
    /// <summary>Time since the last output, in seconds</summary>
    ThinkTime: Single;
    /// <summary>Movement direction</summary>
    Dir: TVec3;
    /// <summary>Speed in the range [0, 400]</summary>
    Speed: Single;
    ViewAngles: TVec3;
    /// <summary>One of the ACTION_ flags</summary>
    ActionFlags: Integer;
    /// <summary>The weapon to use</summary>
    Weapon: Integer;
  end;

implementation

end.
