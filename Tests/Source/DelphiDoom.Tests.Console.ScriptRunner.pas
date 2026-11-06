{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command files and texts of the console             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.ScriptRunner;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.Console.Intf,
  DelphiDoom.Tests.Console.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleScriptRunner = class(TObject)
  private
    FOutput: TFakeOutput;
    FOutputIntf: IConsoleOutput;
    FLog: ILog;
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FFileSystem: TFakeFileSystem;
    FFileSystemIntf: IConsoleFileSystem;
    FRunner: IConsoleScriptRunner;
    FRan: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestEachLineIsAnInputOfTheInterpreter;
    [Test]
    procedure TestEmptyLinesAndCommentsAreSkipped;
    [Test]
    procedure TestLinesAreTrimmed;
    [Test]
    procedure TestFileWithoutNameShowsTheUsage;
    [Test]
    procedure TestFileThatDoesNotExistIsReported;
    [Test]
    procedure TestExtensionConIsTriedWhenTheNameIsNotAFile;
    [Test]
    procedure TestFileNameIsShownInUpperCase;
    [Test]
    procedure TestFileThatRunsItselfIsRefused;
    [Test]
    procedure TestFileThatRunsAnotherIsAllowed;
    [Test]
    procedure TestSameFileCanRunTwoTimesOneAfterTheOther;
    [Test]
    procedure TestTextIsRunLineByLine;
    [Test]
    procedure TestTextAcceptsAnyLineBreak;
  end;

implementation

uses
  DelphiDoom.Console.Factory;

const
  EOL = #13#10;

{ TTestConsoleScriptRunner }

procedure TTestConsoleScriptRunner.Setup;
begin
  FOutput := TFakeOutput.Create;
  FOutputIntf := FOutput;
  FLog := TFakeLog.Create(FOutput);
  FRegistry := TConsoleFactory.CreateRegistry;
  FInterpreter := TConsoleFactory.CreateInterpreter(FRegistry);
  FRan := '';
  FRegistry.Add('run',
    procedure(const AParam1, AParam2: string)
    begin
      FRan := FRan + '[' + AParam1 + ' ' + AParam2 + ']';
    end);
  FRegistry.Add('exec',
    procedure(const AParam1, AParam2: string)
    begin
      FRunner.RunFile(AParam1);
    end);
  FFileSystem := TFakeFileSystem.Create('');
  FFileSystemIntf := FFileSystem;
  FRunner := TConsoleFactory.CreateScriptRunner(FInterpreter, FFileSystemIntf, FOutputIntf, FLog);
end;

procedure TTestConsoleScriptRunner.TearDown;
begin
  FRegistry := nil;
  FRunner := nil;
  FFileSystemIntf := nil;
  FInterpreter := nil;
  FLog := nil;
  FOutputIntf := nil;
end;

procedure TTestConsoleScriptRunner.TestEachLineIsAnInputOfTheInterpreter;
begin
  FFileSystem.AddFile('a.con', TArray<string>.Create('run one', 'run two three'));
  FRunner.RunFile('a.con');
  Assert.AreEqual('[one ][two three]', FRan, 'dovrebbe eseguire le righe in ordine');
end;

procedure TTestConsoleScriptRunner.TestEmptyLinesAndCommentsAreSkipped;
begin
  FFileSystem.AddFile('a.con', TArray<string>.Create('// comment', '', '   ', '  // indented', 'run x'));
  FRunner.RunFile('a.con');
  Assert.AreEqual('[x ]', FRan, 'dovrebbe saltare righe vuote e commenti');
end;

procedure TTestConsoleScriptRunner.TestLinesAreTrimmed;
begin
  FFileSystem.AddFile('a.con', TArray<string>.Create('   run   x   '#9));
  FRunner.RunFile('a.con');
  Assert.AreEqual('[x ]', FRan, 'dovrebbe togliere gli spazi ai lati della riga');
end;

procedure TTestConsoleScriptRunner.TestFileWithoutNameShowsTheUsage;
begin
  FRunner.RunFile('');
  Assert.AreEqual('Usage:' + EOL + ' exec [command file(*.con)]' + EOL, FOutput.Text,
    'dovrebbe scrivere l''uso');
end;

procedure TTestConsoleScriptRunner.TestFileThatDoesNotExistIsReported;
begin
  FRunner.RunFile('missing');
  Assert.AreEqual(' Command file not found: missing' + EOL, FOutput.Text,
    'dovrebbe dire che il file non c''e''');
end;

procedure TTestConsoleScriptRunner.TestExtensionConIsTriedWhenTheNameIsNotAFile;
begin
  FFileSystem.AddFile('autoexec.CON', TArray<string>.Create('run y'));
  FRunner.RunFile('autoexec');
  Assert.AreEqual('[y ]', FRan, 'dovrebbe provare con .CON');
end;

procedure TTestConsoleScriptRunner.TestFileNameIsShownInUpperCase;
begin
  FFileSystem.AddFile('Mixed.con', nil);
  FRunner.RunFile('Mixed.con');
  Assert.AreEqual(' Running command file: MIXED.CON' + EOL, FOutput.Text,
    'dovrebbe scrivere il nome in maiuscolo');
end;

procedure TTestConsoleScriptRunner.TestFileThatRunsItselfIsRefused;
begin
  FFileSystem.AddFile('loop.con', TArray<string>.Create('run a', 'exec loop.con', 'run b'));
  FRunner.RunFile('loop.con');
  Assert.AreEqual('[a ][b ]', FRan, 'dovrebbe rifiutare la chiamata ricorsiva e andare avanti');
  Assert.AreEqual(' Running command file: LOOP.CON' + EOL +
    '[warn]  Recursive calls of con files are not allowed(loop.con)' + EOL, FOutput.Text,
    'dovrebbe avvisare');
end;

procedure TTestConsoleScriptRunner.TestFileThatRunsAnotherIsAllowed;
begin
  FFileSystem.AddFile('a.con', TArray<string>.Create('run a1', 'exec b.con', 'run a2'));
  FFileSystem.AddFile('b.con', TArray<string>.Create('run b1'));
  FRunner.RunFile('a.con');
  Assert.AreEqual('[a1 ][b1 ][a2 ]', FRan, 'dovrebbe eseguire il file annidato');
end;

procedure TTestConsoleScriptRunner.TestSameFileCanRunTwoTimesOneAfterTheOther;
begin
  FFileSystem.AddFile('a.con', TArray<string>.Create('run a'));
  FRunner.RunFile('a.con');
  FRunner.RunFile('a.con');
  Assert.AreEqual('[a ][a ]', FRan, 'dovrebbe poter rieseguire un file finito');
end;

procedure TTestConsoleScriptRunner.TestTextIsRunLineByLine;
begin
  FRunner.RunText('run a' + EOL + '// hidden' + EOL + '  run b  ' + EOL);
  Assert.AreEqual('[a ][b ]', FRan, 'dovrebbe eseguire le righe del testo');
end;

procedure TTestConsoleScriptRunner.TestTextAcceptsAnyLineBreak;
begin
  FRunner.RunText('run a'#13'run b'#10'run c');
  Assert.AreEqual('[a ][b ][c ]', FRan, 'dovrebbe spezzare anche su CR e su LF soli');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleScriptRunner);

end.
