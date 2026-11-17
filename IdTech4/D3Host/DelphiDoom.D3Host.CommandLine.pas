{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - the command line of the program           }
{                                                                              }
{  Port of Doom 3 (id Software): framework\Common.cpp (ParseCommandLine,       }
{  ClearCommandLine, SafeMode, CheckToolMode, StartupVariable,                 }
{  AddStartupCommands).                                                        }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.CommandLine;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.D3Host.Types,
  DelphiDoom.D3Host.Intf, DelphiDoom.D3Host.Lifecycle.Intf;

type
  /// <summary>
  ///   The command line as Doom 3 reads it: a + separates the console command lines, so that
  ///   "doom +set test blah +map test", "doom set test blah+map test" and "doom set test blah + map test" are
  ///   all the same. At most 32 lines (the C++ writes past its array; here it is an ED3HostException).
  /// </summary>
  TD3CommandLine = class(TInterfacedObject, ID3StartupVariables, ID3CommandLineControl)
  strict private
    FCVars: ID3CommonCVars;
    FBuffer: ICmdBuffer;
    FState: TD3CommonState;
    FLines: array[0..D3_MAX_CONSOLE_LINES - 1] of TIdCmdArgs;
    FLineCount: Integer;
    class function SameIgnoringCase(const ALeft, ARight: AnsiString): Boolean; static;
    procedure SetStartupVariable(const AHasMatch: Boolean; const AMatch: AnsiString; const AOnce: Boolean);
  public
    constructor Create(const ACVars: ID3CommonCVars; const ABuffer: ICmdBuffer; const AState: TD3CommonState);
    destructor Destroy; override;
    /// <summary>idCommonLocal::ParseCommandLine: the arguments without the path of the program</summary>
    procedure ParseCommandLine(const AArguments: TArray<AnsiString>);
    /// <summary>idCommonLocal::ClearCommandLine</summary>
    procedure ClearCommandLine;
    /// <summary>
    ///   idCommonLocal::SafeMode: "safe" or "cvar_restart" on the command line (skips the config file); the
    ///   line is cleared
    /// </summary>
    function SafeMode: Boolean;
    /// <summary>
    ///   idCommonLocal::CheckToolMode: "guieditor", "debugger", "editor", "materialEditor" set the editor
    ///   flags; those, "renderbump" and "dmap" turn r_fullscreen off
    /// </summary>
    procedure CheckToolMode;
    /// <summary>idCommonLocal::StartupVariable( match, once ): the "set" lines for the cvar named AMatch</summary>
    procedure StartupVariable(const AMatch: AnsiString; const AOnce: Boolean);
    /// <summary>idCommonLocal::StartupVariable( NULL, once ): all the "set" lines</summary>
    procedure StartupAllVariables(const AOnce: Boolean);
    /// <summary>
    ///   idCommonLocal::AddStartupCommands: the lines to the command buffer (appended, tokenized); true if any
    ///   line other than a "set..." was added, which keeps the demo loop from starting
    /// </summary>
    function AddStartupCommands: Boolean;
    function LineCount: Integer;
    /// <summary>The line at the index (com_consoleLines): never nil, owned by this object</summary>
    function Line(const AIndex: Integer): TIdCmdArgs;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Str;

const
  STooManyLines = 'The command line has more than %d lines separated by +';
  SSafe = 'safe';
  SCvarRestart = 'cvar_restart';
  SSet = 'set';
  SFullscreen = 'r_fullscreen';

class function TD3CommandLine.SameIgnoringCase(const ALeft, ARight: AnsiString): Boolean;
var
  LLeft: TIdStr;
begin
  // idStr::Icmp compares the ASCII letters without regard to case
  LLeft := TIdStr.Create(ALeft);
  Result := LLeft.Icmp(ARight) = 0;
end;

constructor TD3CommandLine.Create(const ACVars: ID3CommonCVars; const ABuffer: ICmdBuffer;
  const AState: TD3CommonState);
var
  LIndex: Integer;
begin
  inherited Create;
  FCVars := ACVars;
  FBuffer := ABuffer;
  FState := AState;
  for LIndex := 0 to D3_MAX_CONSOLE_LINES - 1 do
    FLines[LIndex] := TIdCmdArgs.Create;
end;

destructor TD3CommandLine.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to D3_MAX_CONSOLE_LINES - 1 do
    FLines[LIndex].Free;
  inherited Destroy;
end;

procedure TD3CommandLine.ParseCommandLine(const AArguments: TArray<AnsiString>);
var
  LIndex: Integer;
  LArgument: AnsiString;
begin
  FLineCount := 0;
  // API says no program path
  for LIndex := 0 to High(AArguments) do
  begin
    LArgument := AArguments[LIndex];
    if (LArgument <> '') and (LArgument[1] = '+') then
    begin
      if FLineCount >= D3_MAX_CONSOLE_LINES then
        raise ED3HostException.CreateFmt(STooManyLines, [D3_MAX_CONSOLE_LINES]);
      Inc(FLineCount);
      // like the C++, the slots are not cleared: a second parse appends to what the first one left
      FLines[FLineCount - 1].AppendArg(Copy(LArgument, 2, MaxInt));
    end
    else
    begin
      if FLineCount = 0 then
        Inc(FLineCount);
      FLines[FLineCount - 1].AppendArg(LArgument);
    end;
  end;
end;

procedure TD3CommandLine.ClearCommandLine;
begin
  FLineCount := 0;
end;

function TD3CommandLine.SafeMode: Boolean;
var
  LIndex: Integer;
  LName: AnsiString;
begin
  for LIndex := 0 to FLineCount - 1 do
  begin
    LName := FLines[LIndex].Argv(0);
    if SameIgnoringCase(LName, SSafe) or SameIgnoringCase(LName, SCvarRestart) then
    begin
      FLines[LIndex].Clear;
      Exit(True);
    end;
  end;
  Result := False;
end;

procedure TD3CommandLine.CheckToolMode;
var
  LIndex: Integer;
  LName: AnsiString;
begin
  for LIndex := 0 to FLineCount - 1 do
  begin
    LName := FLines[LIndex].Argv(0);
    if SameIgnoringCase(LName, 'guieditor') then
      FState.Editors := FState.Editors or EDITOR_GUI
    else if SameIgnoringCase(LName, 'debugger') then
      FState.Editors := FState.Editors or EDITOR_DEBUGGER
    else if SameIgnoringCase(LName, 'editor') then
      FState.Editors := FState.Editors or EDITOR_RADIANT
    else if SameIgnoringCase(LName, 'materialEditor') then
      FState.Editors := FState.Editors or EDITOR_MATERIAL;

    if SameIgnoringCase(LName, 'renderbump') or SameIgnoringCase(LName, 'editor')
      or SameIgnoringCase(LName, 'guieditor') or SameIgnoringCase(LName, 'debugger')
      or SameIgnoringCase(LName, 'dmap') or SameIgnoringCase(LName, 'materialEditor') then
    begin
      FCVars.SetCVarBool(SFullscreen, False);
      Exit;
    end;
  end;
end;

procedure TD3CommandLine.SetStartupVariable(const AHasMatch: Boolean; const AMatch: AnsiString;
  const AOnce: Boolean);
var
  LIndex: Integer;
  LJ: Integer;
  LName: AnsiString;
begin
  LIndex := 0;
  while LIndex < FLineCount do
  begin
    // strcmp: the word "set" is compared with case
    if FLines[LIndex].Argv(0) <> SSet then
    begin
      Inc(LIndex);
      Continue;
    end;
    LName := FLines[LIndex].Argv(1);
    if (not AHasMatch) or SameIgnoringCase(LName, AMatch) then
    begin
      FCVars.SetCVarString(LName, FLines[LIndex].Argv(2));
      if AOnce then
      begin
        // kill the line
        LJ := LIndex + 1;
        while LJ < FLineCount do
        begin
          FLines[LJ - 1].Assign(FLines[LJ]);
          Inc(LJ);
        end;
        Dec(FLineCount);
        Continue;
      end;
    end;
    Inc(LIndex);
  end;
end;

procedure TD3CommandLine.StartupVariable(const AMatch: AnsiString; const AOnce: Boolean);
begin
  SetStartupVariable(True, AMatch, AOnce);
end;

procedure TD3CommandLine.StartupAllVariables(const AOnce: Boolean);
begin
  SetStartupVariable(False, '', AOnce);
end;

function TD3CommandLine.AddStartupCommands: Boolean;
var
  LIndex: Integer;
  LText: TIdStr;
begin
  Result := False;
  // quote every token, so args with semicolons can work
  for LIndex := 0 to FLineCount - 1 do
  begin
    if FLines[LIndex].Argc = 0 then
      Continue;
    // set commands won't override menu startup
    LText := TIdStr.Create(FLines[LIndex].Argv(0));
    if LText.Icmpn(SSet, 3) <> 0 then
      Result := True;
    // directly as tokenized so nothing gets screwed
    FBuffer.BufferCommandArgs(ceAppend, FLines[LIndex]);
  end;
end;

function TD3CommandLine.LineCount: Integer;
begin
  Result := FLineCount;
end;

function TD3CommandLine.Line(const AIndex: Integer): TIdCmdArgs;
begin
  Result := FLines[AIndex];
end;

end.
