{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS library - the shared types of the virtual machine           }
{  Port of the interpreter of Hexen (p_acs.c, Raven Software)                  }
{  Copyright (C) 1995 Raven Software, Corp.                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Machine.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The first long of an object code: "ACS" and a zero</summary>
  ACS_MAGIC = $534341;
  ACS_STACK_DEPTH = 32;
  ACS_SCRIPT_VARIABLE_COUNT = 10;
  ACS_MAP_VARIABLE_COUNT = 32;
  ACS_WORLD_VARIABLE_COUNT = 64;
  /// <summary>
  ///   How many scripts can wait for another map. The store has one entry more: the one that
  ///   ends the list
  /// </summary>
  ACS_STORE_SIZE = 20;
  /// <summary>The arguments of a script that starts: the bytes of one long</summary>
  ACS_ARGUMENT_COUNT = 4;
  /// <summary>The arguments of a line special: five, and room for the engine</summary>
  ACS_SPECIAL_ARGUMENT_COUNT = 8;
  /// <summary>The most arguments that a script of the object code can declare</summary>
  ACS_MAX_SCRIPT_ARGUMENTS = ACS_SCRIPT_VARIABLE_COUNT;

  /// <summary>Where SetLineTexture puts the texture</summary>
  ACS_TEXTURE_TOP = 0;
  ACS_TEXTURE_MIDDLE = 1;
  ACS_TEXTURE_BOTTOM = 2;

type
  /// <summary>What a script of the object code is doing. The numbers are saved in the games</summary>
  TAcsScriptState = (
    assInactive,
    assRunning,
    assSuspended,
    assWaitingForTag,
    assWaitingForPolyobj,
    assWaitingForScript,
    assTerminating
  );

  /// <summary>The answer of GameType: the values are the ones that the scripts know</summary>
  TAcsGameType = (
    agtSinglePlayer,
    agtNetCooperative,
    agtNetDeathmatch
  );

  /// <summary>A script of the table of the object code and what it is doing</summary>
  TAcsScriptInfo = record
    Number: Integer;
    /// <summary>The first command of the script, in the object code</summary>
    Address: PInteger;
    ArgCount: Integer;
    State: TAcsScriptState;
    WaitValue: Integer;
  end;

  PAcsScript = ^TAcsScript;

  /// <summary>
  ///   A script that runs: its stack, its variables and where it is. The engine keeps it in the
  ///   memory of a thinker, after the thinker itself, and saves it as it is: the layout is the one
  ///   of the old acs_t without its thinker, and cannot change. The activator and the line are
  ///   things of the engine that the machine only gives back to the host
  /// </summary>
  TAcsScript = record
    Activator: Pointer;
    Line: Pointer;
    Side: Integer;
    Number: Integer;
    InfoIndex: Integer;
    DelayCount: Integer;
    Stack: array[0..ACS_STACK_DEPTH - 1] of Integer;
    StackPtr: Integer;
    Vars: array[0..ACS_SCRIPT_VARIABLE_COUNT - 1] of Integer;
    Ip: PInteger;
  end;

  /// <summary>A script that waits for the map where it has to start. Saved as it is</summary>
  TAcsStoreEntry = packed record
    /// <summary>The target map; 0 ends the list, -1 is a free entry</summary>
    Map: Integer;
    Script: Integer;
    Args: array[0..ACS_ARGUMENT_COUNT - 1] of Byte;
  end;

  PAcsStoreEntry = ^TAcsStoreEntry;

  TAcsStore = array[0..ACS_STORE_SIZE] of TAcsStoreEntry;
  TAcsMapVariables = array[0..ACS_MAP_VARIABLE_COUNT - 1] of Integer;
  TAcsWorldVariables = array[0..ACS_WORLD_VARIABLE_COUNT - 1] of Integer;
  TAcsArguments = array[0..ACS_ARGUMENT_COUNT - 1] of Byte;
  TAcsSpecialArguments = array[0..ACS_SPECIAL_ARGUMENT_COUNT - 1] of Byte;
  TAcsLineSpecialArguments = array[0..4] of Integer;

  /// <summary>
  ///   The machine cannot go on: the store of the scripts for other maps is full. A script that
  ///   does something wrong is not this: it is stopped and the machine warns the log
  /// </summary>
  EAcsMachineException = class(Exception);

resourcestring
  SAcsStoreFull = 'ACS store is full: at most %d scripts can wait for another map';

implementation

end.
