{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGlbspProcess                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Runner;

{
  The runner is tested with programs of the system (cmd.exe, ping.exe on the
  loopback address), never with glbsp on a map: output capture, exit code,
  timeout and clean up are properties of the runner, not of glbsp. The only
  test that waits is the timeout one, and it waits for the timeout it asks.
}

interface

uses
  System.SysUtils, System.Diagnostics, DUnitX.TestFramework,
  DelphiDoom.Glbsp.Runner;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspProcess = class(TObject)
  private
    FNotAnExecutable: TBytes;
    FProcess: TGlbspProcess;
    function CommandProcessor: string;
    function SystemProgram(const AName: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutExecutableRaises;
    [Test]
    procedure TestCreateWithEmptyExecutableRaises;
    [Test]
    procedure TestRunCommandLineCapturesTheOutput;
    [Test]
    procedure TestRunCommandLineReportsTheExitCode;
    [Test]
    procedure TestRunCommandLineWithMissingProgramFailsToLaunch;
    [Test]
    procedure TestRunCommandLineDoesNotWriteIntoTheCallerString;
    [Test]
    procedure TestRunCommandLineKillsTheProcessOnTimeout;
    [Test]
    procedure TestRunWithInvalidExecutableFailsToLaunchAndDeletesTheFile;
    [Test]
    procedure TestRunStartsFromACleanState;
  end;

implementation

{ TTestGlbspProcess }

procedure TTestGlbspProcess.Setup;
begin
  FNotAnExecutable := TEncoding.ASCII.GetBytes('this is not a Win32 program');
  FProcess := TGlbspProcess.Create(Pointer(FNotAnExecutable),
    Length(FNotAnExecutable));
end;

procedure TTestGlbspProcess.TearDown;
begin
  FreeAndNil(FProcess);
  FNotAnExecutable := nil;
end;

function TTestGlbspProcess.CommandProcessor: string;
begin
  Result := GetEnvironmentVariable('ComSpec');
end;

function TTestGlbspProcess.SystemProgram(const AName: string): string;
begin
  Result := GetEnvironmentVariable('SystemRoot') + '\System32\' + AName;
end;

procedure TTestGlbspProcess.TestCreateWithoutExecutableRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlbspProcess.Create(nil, 10).Free;
    end, EArgumentNilException);
end;

procedure TTestGlbspProcess.TestCreateWithEmptyExecutableRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlbspProcess.Create(Pointer(FNotAnExecutable), 0).Free;
    end, EArgumentException);
end;

procedure TTestGlbspProcess.TestRunCommandLineCapturesTheOutput;
var
  LStatus: TGlbspRunStatus;
begin
  LStatus := FProcess.RunCommandLine('"' + CommandProcessor + '" /c echo ciao glbsp',
    30000);

  Assert.AreEqual(Ord(grsCompleted), Ord(LStatus));
  Assert.AreEqual(0, Integer(FProcess.ExitCode));
  Assert.IsTrue(Pos('ciao glbsp', string(FProcess.Output)) > 0);
  Assert.AreEqual('', FProcess.ErrorText);
end;

procedure TTestGlbspProcess.TestRunCommandLineReportsTheExitCode;
var
  LStatus: TGlbspRunStatus;
begin
  LStatus := FProcess.RunCommandLine('"' + CommandProcessor + '" /c exit 3', 30000);

  Assert.AreEqual(Ord(grsCompleted), Ord(LStatus));
  Assert.AreEqual(3, Integer(FProcess.ExitCode));
end;

procedure TTestGlbspProcess.TestRunCommandLineWithMissingProgramFailsToLaunch;
var
  LStatus: TGlbspRunStatus;
begin
  LStatus := FProcess.RunCommandLine('"' + SystemProgram('ddglbsp.missing.exe') + '"',
    30000);

  Assert.AreEqual(Ord(grsLaunchFailed), Ord(LStatus));
  Assert.IsTrue(FProcess.ErrorText <> '');
end;

procedure TTestGlbspProcess.TestRunCommandLineDoesNotWriteIntoTheCallerString;
var
  LCommandLine: string;
  LCopy: string;
begin
  // CreateProcess may modify the command line buffer: the runner must hand
  // it a private copy (UniqueString) and leave the caller's string intact
  LCommandLine := '"' + CommandProcessor + '" /c echo abc';
  LCopy := LCommandLine;

  FProcess.RunCommandLine(LCommandLine, 30000);

  Assert.AreEqual(LCopy, LCommandLine);
end;

procedure TTestGlbspProcess.TestRunCommandLineKillsTheProcessOnTimeout;
var
  LPing: string;
  LWatch: TStopwatch;
  LStatus: TGlbspRunStatus;
begin
  LPing := SystemProgram('ping.exe');
  if not FileExists(LPing) then
  begin
    Assert.Pass('ping.exe not found: ' + LPing);
    Exit;
  end;

  // 30 echo requests to the loopback address take about 29 seconds
  LWatch := TStopwatch.StartNew;
  LStatus := FProcess.RunCommandLine('"' + LPing + '" -n 30 127.0.0.1', 300);
  LWatch.Stop;

  Assert.AreEqual(Ord(grsTimedOut), Ord(LStatus));
  Assert.IsTrue(LWatch.ElapsedMilliseconds < 15000,
    'The process was not terminated at the timeout');
  Assert.IsTrue(FProcess.ErrorText <> '');
end;

procedure TTestGlbspProcess.TestRunWithInvalidExecutableFailsToLaunchAndDeletesTheFile;
var
  LStatus: TGlbspRunStatus;
begin
  // The bytes are written to a real file, but Windows refuses to run them
  LStatus := FProcess.Run('-q', 30000);

  Assert.AreEqual(Ord(grsLaunchFailed), Ord(LStatus));
  Assert.IsTrue(FProcess.ExecutablePath <> '');
  Assert.IsTrue(ExtractFileName(FProcess.ExecutablePath).StartsWith('ddglbsp_'));
  Assert.IsFalse(FileExists(FProcess.ExecutablePath),
    'The temporary executable was not deleted');
end;

procedure TTestGlbspProcess.TestRunStartsFromACleanState;
begin
  FProcess.RunCommandLine('"' + CommandProcessor + '" /c echo first', 30000);
  Assert.IsTrue(Pos('first', string(FProcess.Output)) > 0);

  // A failed run must not keep the output and the exit code of the previous
  FProcess.RunCommandLine('"' + SystemProgram('ddglbsp.missing.exe') + '"', 30000);

  Assert.AreEqual('', string(FProcess.Output));
  Assert.AreEqual(0, Integer(FProcess.ExitCode));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspProcess);

end.
