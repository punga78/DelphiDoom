{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - compiling a script                                }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.CompileCommand;

interface

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf;

type
  /// <summary>What compiling a script gave</summary>
  TIdeCompileResult = record
    Success: Boolean;
    /// <summary>The compiled code, one character for each byte</summary>
    PCode: string;
    /// <summary>True if the messages tell where the first error is</summary>
    HasErrorLocation: Boolean;
    ErrorLocation: TIdeSourceLocation;
  end;

  /// <summary>
  ///   The "compile" button: gives the text of a script to the compiler of the game and writes
  ///   what comes back in the message list (the warnings if it worked, the errors if not)
  /// </summary>
  TIdeCompileCommand = class
  strict private
    FCompiler: IIdeScriptCompiler;
    FLog: IIdeLog;
  public
    constructor Create(const ACompiler: IIdeScriptCompiler; const ALog: IIdeLog);
    /// <summary>
    ///   The text goes to the compiler through an AnsiString, as it always did: a character the
    ///   ANSI code page does not have becomes a question mark
    /// </summary>
    function Execute(const AGame, ARelativePath, ASourceText: string): TIdeCompileResult;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Ide.Messages,
  DelphiDoom.Ide.CompilerMessages;

{ TIdeCompileCommand }

constructor TIdeCompileCommand.Create(const ACompiler: IIdeScriptCompiler; const ALog: IIdeLog);
begin
  inherited Create;
  if not Assigned(ACompiler) then
    raise EArgumentNilException.Create('ACompiler');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FCompiler := ACompiler;
  FLog := ALog;
end;

function TIdeCompileCommand.Execute(const AGame, ARelativePath,
  ASourceText: string): TIdeCompileResult;
var
  LSource, LMessages, LLine: string;
begin
  FLog.WriteFormat(mkNormal, SCompiling, [AGame, ARelativePath]);
  LSource := string(AnsiString(ASourceText));
  LMessages := '';
  Result.PCode := '';
  Result.Success := FCompiler.Compile(AGame, LSource, Result.PCode, LMessages);
  if Result.Success then
  begin
    for LLine in TIdeCompilerMessages.SplitLines(LMessages) do
      FLog.Write(mkWarning, LLine);
    FLog.Write(mkNormal, SCompileSuccessful);
  end
  else
    for LLine in TIdeCompilerMessages.SplitLines(LMessages) do
      FLog.Write(mkError, LLine);
  Result.HasErrorLocation := TIdeCompilerMessages.TryFindErrorLocation(LMessages,
    Result.ErrorLocation);
end;

end.
