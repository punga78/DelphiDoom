{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the commands run at the start of the console           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.AutoExec;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Intf, DelphiDoom.Console.AutoExec,
  DelphiDoom.Tests.Console.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleAutoExec = class(TObject)
  private
    FOutput: TFakeOutput;
    FOutputIntf: IConsoleOutput;
    FStartup: TFakeStartupSource;
    FStartupIntf: IConsoleStartupSource;
    FRunner: TRecordingRunner;
    FRunnerIntf: IConsoleScriptRunner;
    FAutoExec: TConsoleAutoExec;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRunsTheAutoExecFileThenTheLumpsThenTheCommandLineFile;
    [Test]
    procedure TestWithoutCommandLineFileNothingMoreRuns;
    [Test]
    procedure TestDefaultFileIsCreatedWhenItDoesNotExist;
    [Test]
    procedure TestDefaultFileIsNotCreatedWhenItExists;
    [Test]
    procedure TestSaysThatItStarts;
    [Test]
    procedure TestEmptyAutoExecNameShowsTheUsageOfExecAsBefore;
  end;

implementation

uses
  DelphiDoom.Console.Factory;

{ TTestConsoleAutoExec }

procedure TTestConsoleAutoExec.Setup;
begin
  FOutput := TFakeOutput.Create;
  FOutputIntf := FOutput;
  FStartup := TFakeStartupSource.Create;
  FStartupIntf := FStartup;
  FStartup.AutoExec := 'my.con';
  FStartup.DefaultExists := True;
  FRunner := TRecordingRunner.Create;
  FRunnerIntf := FRunner;
  FAutoExec := TConsoleFactory.CreateAutoExec(FStartupIntf, FRunnerIntf, FOutputIntf, 'DelphiDoom 2.07');
end;

procedure TTestConsoleAutoExec.TearDown;
begin
  FAutoExec.Free;
  FRunnerIntf := nil;
  FStartupIntf := nil;
  FOutputIntf := nil;
end;

procedure TTestConsoleAutoExec.TestRunsTheAutoExecFileThenTheLumpsThenTheCommandLineFile;
begin
  FStartup.LumpTexts := TArray<string>.Create('one', 'two');
  FStartup.CommandLineFile := 'cmd.con';
  FAutoExec.Run;
  Assert.AreEqual('file(my.con) text(one) text(two) file(cmd.con) ', FRunner.Calls,
    'dovrebbe rispettare l''ordine');
end;

procedure TTestConsoleAutoExec.TestWithoutCommandLineFileNothingMoreRuns;
begin
  FAutoExec.Run;
  Assert.AreEqual('file(my.con) ', FRunner.Calls, 'dovrebbe eseguire solo il file autoexec');
end;

procedure TTestConsoleAutoExec.TestDefaultFileIsCreatedWhenItDoesNotExist;
begin
  FStartup.DefaultExists := False;
  FAutoExec.Run;
  Assert.AreEqual<Integer>(2, Length(FStartup.CreatedLines), 'dovrebbe creare il file con due righe');
  Assert.AreEqual('// Add autoexec console commands in this file.', FStartup.CreatedLines[0]);
  Assert.AreEqual('// These console commands will be executed everytime you start DelphiDoom 2.07',
    FStartup.CreatedLines[1], 'dovrebbe nominare l''applicazione');
end;

procedure TTestConsoleAutoExec.TestDefaultFileIsNotCreatedWhenItExists;
begin
  FAutoExec.Run;
  Assert.AreEqual<Integer>(0, Length(FStartup.CreatedLines), 'non dovrebbe creare niente');
end;

procedure TTestConsoleAutoExec.TestSaysThatItStarts;
begin
  FAutoExec.Run;
  Assert.AreEqual('C_RunAutoExec()' + #13#10, FOutput.Text, 'dovrebbe scriverlo come prima');
end;

procedure TTestConsoleAutoExec.TestEmptyAutoExecNameShowsTheUsageOfExecAsBefore;
begin
  FStartup.AutoExec := '';
  FAutoExec.Run;
  Assert.AreEqual('file() ', FRunner.Calls, 'dovrebbe dare al runner anche il nome vuoto, come faceva il vecchio codice');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleAutoExec);

end.
