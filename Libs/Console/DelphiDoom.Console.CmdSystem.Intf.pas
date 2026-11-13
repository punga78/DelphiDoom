{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 command system, contracts            }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CmdSystem.h.                }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CmdSystem.Intf;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CmdSystem.Types;

type
  /// <summary>
  ///   What the engine knows of the game session (the global <c>session</c> of Doom 3 and
  ///   <c>idAsyncNetwork::client</c>). A class that gets a nil session behaves as a single player game.
  /// </summary>
  IConsoleSession = interface
    ['{6B1E40A7-93C2-4D58-8F06-A7D4C2E91B35}']
    function IsMultiplayer: Boolean;
    /// <summary>idAsyncNetwork::client.IsActive</summary>
    function IsNetworkClientActive: Boolean;
  end;

  /// <summary>The cvar system as the command system sees it: a line that is not a command</summary>
  ICVarCommand = interface
    ['{C20D5E3B-1A74-46F9-B8E1-5F90A3D7C612}']
    /// <summary>
    ///   idCVarSystem::Command: true if argv(0) is a variable; prints it (one argument) or changes
    ///   it (more arguments)
    /// </summary>
    function Command(const AArgs: TIdCmdArgs): Boolean;
  end;

  /// <summary>
  ///   The commands: registration, removal and the completion of names and arguments
  /// </summary>
  ICmdCommands = interface
    ['{4D8A1F62-0B93-4C75-A6E4-9E2B7D5013C8}']
    /// <summary>
    ///   Registers a command. A name that exists (compared with case) is not replaced: if the
    ///   function is another one the log gets "already defined". The new command is the first of
    ///   the list
    /// </summary>
    procedure AddCommand(const ACommandName: AnsiString; const AFunction: TCmdFunction; const AFlags: Integer;
      const ADescription: AnsiString); overload;
    procedure AddCommand(const ACommandName: AnsiString; const AFunction: TCmdFunction; const AFlags: Integer;
      const ADescription: AnsiString; const AArgCompletion: TCmdArgCompletion); overload;
    procedure RemoveCommand(const ACommandName: AnsiString);
    /// <summary>Removes all commands with one of the flags set</summary>
    procedure RemoveFlaggedCommands(const AFlags: Integer);
    /// <summary>The name of each command to the callback, in the order of the list</summary>
    procedure CommandCompletion(const ACallback: TCmdCompletionCallback);
    /// <summary>The completion of the first command that has one and is named by the first word</summary>
    procedure ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
    /// <summary>The commands in the order of the list (the first is the last added or last used)</summary>
    function Commands: TArray<TCmdInfo>;
  end;

  /// <summary>The command text buffer</summary>
  ICmdBuffer = interface
    ['{93F2C7A1-58B0-4E26-A1D9-3C6E80B4F527}']
    /// <summary>Adds command text to the command buffer, does not add a final line feed</summary>
    procedure BufferCommandText(const AExecution: TCmdExecution; const AText: AnsiString);
    /// <summary>Adds to the command buffer in tokenized form (ceNow or ceAppend only)</summary>
    procedure BufferCommandArgs(const AExecution: TCmdExecution; const AArgs: TIdCmdArgs);
    /// <summary>
    ///   Pulls off line feed, carriage return or semicolon terminated lines of text from the
    ///   buffer and executes the commands, until the buffer is empty or a wait is pending
    /// </summary>
    procedure ExecuteCommandBuffer;
    /// <summary>idCmdSystemLocal::SetWait: the number of frames the buffer waits</summary>
    procedure SetWait(const AFrames: Integer);
    /// <summary>Sets up a reloadEngine to happen on next command run, and gives a command to execute after it</summary>
    procedure SetupReloadEngine(const AArgs: TIdCmdArgs);
    /// <summary>Appends the command given to SetupReloadEngine; false if there is none</summary>
    function PostReloadEngine: Boolean;
  end;

  /// <summary>The cvar system as the commands that read variables see it</summary>
  ICVarReader = interface(IIdLibCVars)
    ['{E7A3B590-2D14-4F86-9C0B-81D6F5A2E473}']
    function GetCVarBool(const AName: AnsiString): Boolean;
    function GetCVarInteger(const AName: AnsiString): Integer;
    function GetCVarFloat(const AName: AnsiString): Single;
  end;

  /// <summary>The files that the completion of file names lists (idFileSystem::ListFiles)</summary>
  ICmdFileLister = interface
    ['{1F9B6C48-D0A5-47E3-B2C7-6A8E3D5F0914}']
    /// <summary>
    ///   The names of the files (or of the folders, with "/" as the extension) in ADirectory that
    ///   end with AExtension; AFullRelativePath keeps the directory in the name, ASort sorts them
    /// </summary>
    function ListFiles(const ADirectory, AExtension: AnsiString; const ASort, AFullRelativePath: Boolean): TArray<AnsiString>;
  end;

implementation

end.
