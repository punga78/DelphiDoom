{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - shared types                            }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,       }
{  cl_cgame.c, cl_ui.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>The three virtual machines of a game: the server game, the client game and the user interface</summary>
  TQ3Module = (Game, CGame, Ui);

  /// <summary>One member of the enums gameImport_t, cgameImport_t, uiImport_t (and the exports)</summary>
  TQ3OpcodeEntry = record
    Name: string;
    Value: Integer;
  end;

  /// <summary>Base of what the host raises</summary>
  EQ3HostException = class(Exception);

  /// <summary>
  ///   The Com_Error( ERR_DROP, ... ) of a module (G_ERROR, CG_ERROR, UI_ERROR): the text is the one the module
  ///   passed
  /// </summary>
  EQ3ModuleErrorException = class(EQ3HostException);

  /// <summary>
  ///   A system call number that is not in the tables of the module ("Bad game system trap" of sv_game.c)
  /// </summary>
  EQ3UnknownSyscallException = class(EQ3HostException);

  /// <summary>
  ///   A system call that exists but that nobody answers yet (the engine does not provide it): the message has
  ///   its name
  /// </summary>
  EQ3UnhandledSyscallException = class(EQ3HostException);

resourcestring
  SQ3BadSystemTrap = 'Bad %s system trap: %d';
  SQ3UnhandledSystemTrap = 'System trap %s (%d) of %s has no handler';
  SQ3NullStringArgument = 'The module passed a null string to %s';

implementation

end.
