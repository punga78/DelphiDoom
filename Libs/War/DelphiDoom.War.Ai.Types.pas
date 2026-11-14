{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the computer player (the AI)              }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.h and the WarAICommand enums of          }
{  war_enums.h, (c) 2019 Alejandro Coto Gutierrez, zlib License (see            }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.Types;

interface

const
  /// <summary>WAR_AI_COMMAND_REQUEST: train (or, for a building, "build") count units of a type</summary>
  WAR_AI_COMMAND_REQUEST = 0;
  /// <summary>WAR_AI_COMMAND_WAIT: blocks the script until the player has count units of a type</summary>
  WAR_AI_COMMAND_WAIT = 1;
  /// <summary>WAR_AI_COMMAND_ATTACK: declared by the original, never handled (a warning and "done")</summary>
  WAR_AI_COMMAND_ATTACK = 2;
  /// <summary>WAR_AI_COMMAND_DEFEND: declared by the original, never handled (a warning and "done")</summary>
  WAR_AI_COMMAND_DEFEND = 3;
  /// <summary>WAR_AI_COMMAND_SLEEP: blocks the script until the real time reaches a moment</summary>
  WAR_AI_COMMAND_SLEEP = 4;
  WAR_AI_COMMAND_COUNT = 5;

  WAR_AI_STATUS_CREATED = 0;
  WAR_AI_STATUS_STARTED = 1;
  WAR_AI_STATUS_COMPLETED = 2;

  /// <summary>The seconds of the sleep that follows the end of the script (wai_getNextAICommand)</summary>
  WAR_AI_IDLE_SLEEP_SECONDS = 10.0;

type
  /// <summary>One line of the script of a race: a command of the kind REQUEST or WAIT</summary>
  TWarAiScriptEntry = record
    Kind: Integer;
    UnitType: Integer;
    Count: Integer;
  end;

implementation

end.
