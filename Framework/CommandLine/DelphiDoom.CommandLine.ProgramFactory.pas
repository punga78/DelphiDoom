{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - the factory of the command line of a      }
{  program that is not the engine of Doom                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.ProgramFactory;

interface

uses
  System.SysUtils, DelphiDoom.CommandLine.Intf;

type
  /// <summary>
  ///   The only place that knows the classes of the command line that keeps the case of its arguments and of its
  ///   cursor. It is apart from TCommandLineFactory so that a small program does not link the default file, the
  ///   response files and the log of the engine, and the engine does not link what it does not use
  /// </summary>
  TProgramCommandLineFactory = class
  public
    /// <summary>A command line made of the given arguments as they are, the program name first</summary>
    class function CreateCommandLine(const AArguments: TArray<string>): ICommandLine; static;
    /// <summary>The command line this process was started with (ParamStr), as it was written</summary>
    class function CreateProcessCommandLine: ICommandLine; static;
    /// <summary>A cursor at the first argument after the name of the program</summary>
    class function CreateCursor(const ACommandLine: ICommandLine): ICommandLineCursor; static;
  end;

implementation

uses
  DelphiDoom.CommandLine.Verbatim, DelphiDoom.CommandLine.Cursor;

class function TProgramCommandLineFactory.CreateCommandLine(const AArguments: TArray<string>): ICommandLine;
begin
  Result := TVerbatimCommandLine.Create(AArguments);
end;

class function TProgramCommandLineFactory.CreateProcessCommandLine: ICommandLine;
var
  LArguments: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LArguments, ParamCount + 1);
  for LIndex := 0 to ParamCount do
    LArguments[LIndex] := ParamStr(LIndex);
  Result := TVerbatimCommandLine.Create(LArguments);
end;

class function TProgramCommandLineFactory.CreateCursor(const ACommandLine: ICommandLine): ICommandLineCursor;
begin
  Result := TCommandLineCursor.Create(ACommandLine);
end;

end.
