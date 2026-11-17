{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 host library - the scenario interpreter     }
{  (the commands of Tools\Verifica\255\harness.cpp, run on the Delphi classes) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Host.Scenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Common, DelphiDoom.Tests.D3Host.World;

type
  /// <summary>
  ///   Runs a scenario of Tests\Data\D3Host\scenarios on the classes of the library and writes what the C++
  ///   harness writes: the golden file is the answer of the real code. The format of the commands is described in
  ///   the header of Tools\Verifica\255\harness.cpp.
  /// </summary>
  TD3ScenarioRunner = class
  strict private
    FWorld: TD3FakeWorld;
    FHost: TD3CommonHost;
    function Words(const ARest: string): TArray<string>;
    function Tail(const ARest: string; const ACount: Integer): string;
    function MakeEvent(const AWords: TArray<string>; const ARest: string): TD3SysEvent;
    procedure Execute(const ACommand, ARest: string);
  public
    constructor Create(const AWorld: TD3FakeWorld; const AHost: TD3CommonHost);
    /// <summary>Runs every line; the trace of the world gets the result</summary>
    procedure Run(const AScenario: TStrings);
  end;

implementation

uses
  DelphiDoom.D3Host.Printer;

constructor TD3ScenarioRunner.Create(const AWorld: TD3FakeWorld; const AHost: TD3CommonHost);
begin
  inherited Create;
  FWorld := AWorld;
  FHost := AHost;
end;

function TD3ScenarioRunner.Words(const ARest: string): TArray<string>;
var
  LIndex: Integer;
  LStart: Integer;
begin
  Result := nil;
  LIndex := 1;
  while LIndex <= Length(ARest) do
  begin
    while (LIndex <= Length(ARest)) and (ARest[LIndex] = ' ') do
      Inc(LIndex);
    LStart := LIndex;
    while (LIndex <= Length(ARest)) and (ARest[LIndex] <> ' ') do
      Inc(LIndex);
    if LIndex > LStart then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Copy(ARest, LStart, LIndex - LStart);
    end;
  end;
end;

function TD3ScenarioRunner.Tail(const ARest: string; const ACount: Integer): string;
var
  LIndex: Integer;
  LStep: Integer;
begin
  LIndex := 1;
  for LStep := 1 to ACount do
  begin
    while (LIndex <= Length(ARest)) and (ARest[LIndex] = ' ') do
      Inc(LIndex);
    while (LIndex <= Length(ARest)) and (ARest[LIndex] <> ' ') do
      Inc(LIndex);
  end;
  if LIndex <= Length(ARest) then
    Inc(LIndex);
  if LIndex <= Length(ARest) then
    Result := Copy(ARest, LIndex, MaxInt)
  else
    Result := '';
end;

function TD3ScenarioRunner.MakeEvent(const AWords: TArray<string>; const ARest: string): TD3SysEvent;
var
  LText: AnsiString;
begin
  Result := TD3SysEvent.Make(StrToInt(AWords[0]), StrToInt(AWords[1]), StrToInt(AWords[2]));
  if ARest <> '' then
  begin
    LText := TD3Escape.Unescape(ARest);
    SetLength(Result.EvData, Length(LText) + 1);
    Move(LText[1], Result.EvData[0], Length(LText));
    Result.EvData[Length(LText)] := 0;
  end;
end;

procedure TD3ScenarioRunner.Execute(const ACommand, ARest: string);
var
  LWords: TArray<string>;
  LText: AnsiString;
  LAll: string;
  LIndex: Integer;
  LCount: Integer;
  LEvent: TD3SysEvent;
  LLine: string;
  LArguments: TArray<AnsiString>;
  LResult: Integer;
begin
  LWords := Words(ARest);
  LText := TD3Escape.Unescape(ARest);
  if ACommand = 'rep' then
  begin
    LCount := StrToInt(LWords[0]);
    LAll := '';
    for LIndex := 1 to LCount do
      LAll := LAll + Tail(ARest, 2);
    Execute(LWords[1], LAll);
  end
  else if ACommand = 'warnmany' then
  begin
    for LIndex := 0 to StrToInt(LWords[0]) - 1 do
      FHost.Diagnostics.Warning(AnsiString('warning number ' + IntToStr(LIndex)));
  end
  else if ACommand = 'pushmany' then
  begin
    for LIndex := 0 to StrToInt(LWords[0]) - 1 do
      FHost.EventLoop.PushEvent(TD3SysEvent.Make(SE_KEY, LIndex, 1));
  end
  else if ACommand = 'cvars' then
    FWorld.CVarsInitialized := StrToInt(LWords[0]) <> 0
  else if ACommand = 'files' then
    FWorld.FilesInitialized := StrToInt(LWords[0]) <> 0
  else if ACommand = 'opengl' then
    FWorld.OpenGLRunning := StrToInt(LWords[0]) <> 0
  else if ACommand = 'cvar' then
  begin
    if Length(LWords) > 1 then
      FWorld.SetCVarString(AnsiString(LWords[0]), AnsiString(LWords[1]))
    else
      FWorld.SetCVarString(AnsiString(LWords[0]), '');
  end
  else if ACommand = 'openfail' then
    FWorld.OpenFails := StrToInt(LWords[0]) <> 0
  else if ACommand = 'time' then
    FWorld.Time := StrToInt(LWords[0])
  else if ACommand = 'editors' then
    FHost.State.Editors := StrToInt(LWords[0])
  else if ACommand = 'printf' then
    FHost.Printer.Printf(LText)
  else if ACommand = 'dprintf' then
    FHost.Printer.DPrintf(LText)
  else if ACommand = 'warning' then
    FHost.Diagnostics.Warning(LText)
  else if ACommand = 'dwarning' then
    FHost.Diagnostics.DWarning(LText)
  else if ACommand = 'printwarnings' then
    FHost.Diagnostics.PrintWarnings
  else if ACommand = 'clearwarnings' then
    FHost.Diagnostics.ClearWarnings(LText)
  else if ACommand = 'dumpwarnings' then
    FHost.Diagnostics.DumpWarnings
  else if ACommand = 'error' then
    FHost.Errors.Error(LText)
  else if ACommand = 'fatal' then
    FHost.Errors.FatalError(LText)
  else if ACommand = 'redirect' then
    FHost.Printer.BeginRedirect(StrToInt(LWords[0]),
      procedure(const AText: AnsiString)
      begin
        FWorld.LineText('REDIRECT', AText);
      end)
  else if ACommand = 'endredirect' then
    FHost.Printer.EndRedirect
  else if ACommand = 'refresh' then
    FHost.Printer.SetRefreshOnPrint(StrToInt(LWords[0]) <> 0)
  else if ACommand = 'closelog' then
    FHost.Printer.CloseLogFile
  else if ACommand = 'cmdline' then
  begin
    SetLength(LArguments, Length(LWords));
    for LIndex := 0 to High(LWords) do
      LArguments[LIndex] := AnsiString(LWords[LIndex]);
    FHost.CommandLine.ParseCommandLine(LArguments);
  end
  else if ACommand = 'safemode' then
    FWorld.Line('RET ' + IntToStr(Ord(FHost.CommandLine.SafeMode)))
  else if ACommand = 'toolmode' then
    FHost.CommandLine.CheckToolMode
  else if ACommand = 'startup' then
  begin
    if LWords[0] = '*' then
      FHost.CommandLine.StartupAllVariables(StrToInt(LWords[1]) <> 0)
    else
      FHost.CommandLine.StartupVariable(AnsiString(LWords[0]), StrToInt(LWords[1]) <> 0);
  end
  else if ACommand = 'addstartup' then
    FWorld.Line('RET ' + IntToStr(Ord(FHost.CommandLine.AddStartupCommands)))
  else if ACommand = 'lines' then
  begin
    for LIndex := 0 to FHost.CommandLine.LineCount - 1 do
    begin
      LLine := '';
      for LCount := 0 to FHost.CommandLine.Line(LIndex).Argc - 1 do
      begin
        if LCount > 0 then
          LLine := LLine + '|';
        LLine := LLine + string(FHost.CommandLine.Line(LIndex).Argv(LCount));
      end;
      FWorld.LineText(Format('LINE %d', [LIndex]), AnsiString(LLine));
    end;
    FWorld.Line(Format('LINES %d', [FHost.CommandLine.LineCount]));
  end
  else if ACommand = 'evinit' then
    FHost.EventLoop.Init
  else if ACommand = 'evshutdown' then
    FHost.EventLoop.Shutdown
  else if ACommand = 'evsys' then
    FWorld.SystemQueue.Add(MakeEvent(LWords, Tail(ARest, 3)))
  else if ACommand = 'evpush' then
    FHost.EventLoop.PushEvent(MakeEvent(LWords, Tail(ARest, 3)))
  else if ACommand = 'evget' then
  begin
    LEvent := FHost.EventLoop.GetEvent;
    LText := '';
    if (LEvent.EvType = SE_CONSOLE) and (Length(LEvent.EvData) > 0) then
    begin
      LIndex := 0;
      while (LIndex < Length(LEvent.EvData)) and (LEvent.EvData[LIndex] <> 0) do
        Inc(LIndex);
      SetString(LText, PAnsiChar(@LEvent.EvData[0]), LIndex);
    end;
    FWorld.Line(Format('EV %d %d %d %d %s', [LEvent.EvType, LEvent.EvValue, LEvent.EvValue2, Length(LEvent.EvData),
      TD3Escape.Escape(LText)]));
  end
  else if ACommand = 'evrun' then
  begin
    LResult := FHost.EventLoop.RunEventLoop(StrToInt(LWords[0]) <> 0);
    FWorld.Line('RET ' + IntToStr(LResult));
  end
  else if ACommand = 'evms' then
    FWorld.Line('RET ' + IntToStr(FHost.EventLoop.Milliseconds))
  else if ACommand = 'evlevel' then
    FWorld.Line('RET ' + IntToStr(FHost.EventLoop.JournalLevel))
  else if ACommand = 'evqueue' then
    FWorld.Line(Format('EVQ %d %d', [FHost.EventLoop.PushedHead, FHost.EventLoop.PushedTail]))
  else if ACommand = 'state' then
    FWorld.Line(Format('STATE err=%d refresh=%d editors=%d', [FHost.State.ErrorEntered,
      Ord(FHost.State.RefreshOnPrint), FHost.State.Editors]))
  else if ACommand = 'warnlist' then
  begin
    FWorld.Line(Format('WARNLIST %d %d', [FHost.Diagnostics.WarningCount, FHost.Diagnostics.ErrorCount]));
    for LIndex := 0 to FHost.Diagnostics.WarningCount - 1 do
      FWorld.LineText('W', FHost.Diagnostics.WarningAt(LIndex));
    for LIndex := 0 to FHost.Diagnostics.ErrorCount - 1 do
      FWorld.LineText('E', FHost.Diagnostics.ErrorAt(LIndex));
    FWorld.LineText('CAPTION', FHost.Diagnostics.Caption);
  end
  else
    FWorld.Line('UNKNOWN ' + ACommand);
end;

procedure TD3ScenarioRunner.Run(const AScenario: TStrings);
var
  LLine: string;
  LSpace: Integer;
  LCommand: string;
  LRest: string;
begin
  for LLine in AScenario do
  begin
    if (LLine = '') or (LLine[1] = '#') then
      Continue;
    FWorld.LineText('CMD', AnsiString(LLine));
    LSpace := Pos(' ', LLine);
    if LSpace = 0 then
    begin
      LCommand := LLine;
      LRest := '';
    end
    else
    begin
      LCommand := Copy(LLine, 1, LSpace - 1);
      LRest := Copy(LLine, LSpace + 1, MaxInt);
    end;
    try
      Execute(LCommand, LRest);
    except
      on LError: ED3HostException do
        FWorld.LineText('THROW', AnsiString(LError.Message));
      on LExit: ETestExit do
        FWorld.Line('EXIT ' + LExit.Why);
    end;
  end;
end;

end.
