{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - contracts                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Intf;

interface

uses
  DelphiDoom.Console.Types;

type
  /// <summary>Where the text of the console goes: the engine writes it on the screen (printf)</summary>
  IConsoleOutput = interface
    ['{5E2B71C4-8D03-4A96-B1F7-3C94A06D2E58}']
    /// <summary>AText is written as it is: the line breaks (CR LF) are the caller's</summary>
    procedure Write(const AText: string);
  end;

  /// <summary>
  ///   One variable of the game (an entry of the table "defaults" of the engine). The engine
  ///   implements it on the pointer to the global
  /// </summary>
  IConsoleVariable = interface
    ['{A91D3E60-47B5-4C28-9F0E-D1827B5C6A34}']
    /// <summary>The name in lower case</summary>
    function Name: string;
    function Kind: TConsoleVariableKind;
    function Access: TConsoleAccess;
    function GetInteger: Integer;
    procedure SetInteger(AValue: Integer);
    function GetBoolean: Boolean;
    procedure SetBoolean(AValue: Boolean);
    function GetString: string;
    procedure SetString(const AValue: string);
  end;

  /// <summary>The variables that the console can read and write (without the groups of the table)</summary>
  IConsoleVariableSource = interface
    ['{0C6F8A52-1E37-4D9B-A850-92B4E7D13F06}']
    function Count: Integer;
    function Item(AIndex: Integer): IConsoleVariable;
    /// <summary>AName is in lower case. Nil if there is no such variable</summary>
    function Find(const AName: string): IConsoleVariable;
  end;

  /// <summary>The commands of the console, by name (aliases included)</summary>
  ICommandRegistry = interface
    ['{7D40B2E9-6A18-4F53-8C3D-E5016F9A2B74}']
    /// <summary>
    ///   Registers a command. AName may be a list of names separated by commas ("dir, ls"): the
    ///   handler is registered for each of them. Names are not case sensitive. An empty name is
    ///   ignored; a name already registered gets the new handler
    /// </summary>
    procedure Add(const AName: string; const AHandler: TConsoleCommandHandler);
    function Find(const AName: string; out AHandler: TConsoleCommandHandler): Boolean;
    function Contains(const AName: string): Boolean;
    /// <summary>The names in upper case, sorted</summary>
    function Names: TArray<string>;
  end;

  /// <summary>Runs the lines that the user types</summary>
  IConsoleInterpreter = interface
    ['{E3B59D17-0A82-4C6F-95D4-7F1280CB3E69}']
    /// <summary>
    ///   A whole line: the first word is the name, then up to two parameters. Gives false if
    ///   there is nothing to run (the engine prints "Unknown command")
    /// </summary>
    function Execute(const ALine: string): Boolean; overload;
    function Execute(const AName, AParameters: string): Boolean; overload;
    function Execute(const AName, AParam1, AParam2: string): Boolean; overload;
  end;

  /// <summary>Runs the commands of a file or of a text (exec, autoexec, the lumps AUTOEXEC)</summary>
  IConsoleScriptRunner = interface
    ['{91A7C0E4-3D58-4B16-A2F9-6E0D5B84C173}']
    procedure RunFile(const AFileName: string);
    procedure RunText(const AText: string);
  end;

  /// <summary>The files, as the engine sees them</summary>
  IConsoleFileSystem = interface
    ['{4F83D26B-90E1-47A5-B6C8-1A25E7093D4F}']
    function ExpandFileName(const AFileName: string): string;
    function FileExists(const AFileName: string): Boolean;
    /// <summary>The lines of a text file. Gives an empty array if it can not be read</summary>
    function ReadLines(const AFileName: string): TArray<string>;
  end;

  /// <summary>What the start of the console needs from the engine</summary>
  IConsoleStartupSource = interface
    ['{B2E64F19-7C03-48DA-91B5-D80A3F5E6C27}']
    /// <summary>The file given with "autoexecfile" (it can be empty)</summary>
    function AutoExecFileName: string;
    /// <summary>Whether the default file (Doom32.con ...) is already where the engine keeps its files</summary>
    function DefaultAutoExecExists: Boolean;
    /// <summary>Writes the default file where the engine keeps its files</summary>
    procedure CreateDefaultAutoExec(const ALines: TArray<string>);
    /// <summary>The texts of the lumps called AUTOEXEC, in the order of the directory</summary>
    function AutoExecLumpTexts: TArray<string>;
    /// <summary>The file after "-con" in the command line, empty if there is not</summary>
    function CommandLineFileName: string;
  end;

implementation

end.
