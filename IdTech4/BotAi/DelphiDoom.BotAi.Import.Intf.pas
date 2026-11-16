{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - what the bot library asks of the game                  }
{                                                                              }
{  Replaces botimport (code\game\botlib.h), the library variables of           }
{  l_libvar.c and random() of q_shared.h of Quake III Arena (id Software,      }
{  GPL v2 or later). Based on the Quake III Arena GPL Source Code (id Software).}
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Import.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The game side of the bot library: botimport.Print, the log file, AAS_Time and EA_Command.
  /// </summary>
  IBotImport = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F71}']
    /// <summary>botimport.Print: the text ends with a line feed as in the original</summary>
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    /// <summary>Log_Write</summary>
    procedure LogWrite(const AMessage: AnsiString);
    /// <summary>AAS_Time: the time of the world in seconds</summary>
    function Time: Single;
    /// <summary>EA_Command: a command line the bot sends to the game as the client</summary>
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
  end;

  /// <summary>The files of the bots (botimport.FS_FOpenFile and FS_Read)</summary>
  IBotFileSource = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F72}']
    /// <summary>Reads a whole file by its path with forward slashes (botfiles/syn.c); false if it does not exist</summary>
    function TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

  /// <summary>random() of q_shared.h: a number in [0, 1] as a float, injected so the tests are repeatable</summary>
  IBotRandom = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F73}']
    function NextFloat: Single;
  end;

  /// <summary>The library variables the chat reads (l_libvar.c)</summary>
  IBotLibVars = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F74}']
    /// <summary>LibVarGetValue: the value of the variable, 0 if it does not exist</summary>
    function GetValue(const AName: AnsiString): Single;
    /// <summary>LibVarValue: creates the variable with the default if missing and returns its value</summary>
    function GetValueOrCreate(const AName, ADefault: AnsiString): Single;
    /// <summary>LibVarString: creates the variable with the default if missing and returns its text</summary>
    function GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
  end;

implementation

end.
