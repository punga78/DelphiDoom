{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - shared types                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   What a console command does. AParam1 and AParam2 are what the user typed after the name:
  ///   the first word and the rest of the line (both trimmed, empty when missing)
  /// </summary>
  TConsoleCommandHandler = reference to procedure(const AParam1, AParam2: string);

  /// <summary>The type of a console variable</summary>
  TConsoleVariableKind = (
    cvkInteger,
    cvkBoolean,
    cvkString
  );

  /// <summary>When a variable can be changed from the console</summary>
  TConsoleAccessMode = (
    /// <summary>In a single player game</summary>
    camSinglePlayer,
    /// <summary>In a network game</summary>
    camNetwork
  );

  /// <summary>An empty set is a read only variable</summary>
  TConsoleAccess = set of TConsoleAccessMode;

  /// <summary>The state of a cheat that receives the keys, one after the other</summary>
  TCheatStatus = (
    /// <summary>The key is not part of the sequence</summary>
    csUnknown,
    /// <summary>The key is the right one, the sequence is not complete</summary>
    csPending,
    /// <summary>The sequence is complete (and the parameter, if there is one, is read)</summary>
    csAcquired
  );

  /// <summary>A wrong use of the console library (not a mistake of the user typing a command)</summary>
  EConsoleException = class(Exception);

implementation

end.
