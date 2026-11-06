{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the standard commands (list, exec, printf)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.StandardCommands;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Intf, DelphiDoom.Console.StandardCommands,
  DelphiDoom.Tests.Console.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleStandardCommands = class(TObject)
  private
    FOutput: TFakeOutput;
    FOutputIntf: IConsoleOutput;
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FRunner: TRecordingRunner;
    FRunnerIntf: IConsoleScriptRunner;
    FCommands: TConsoleStandardCommands;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRegisterAddsAllTheNames;
    [Test]
    procedure TestPrintfWritesTheTextAndALineBreak;
    [Test]
    procedure TestPrintfJoinsTheTwoParametersWithASpace;
    [Test]
    procedure TestPrintfDoesNotFormatThePercentSign;
    [Test]
    procedure TestListWritesTheSortedNamesAndTheTotal;
    [Test]
    procedure TestListWithAMaskWritesOnlyTheNamesThatFit;
    [Test]
    procedure TestExecGivesTheFileToTheRunner;
  end;

implementation

uses
  DelphiDoom.Console.Factory;

const
  EOL = #13#10;

{ TTestConsoleStandardCommands }

procedure TTestConsoleStandardCommands.Setup;
begin
  FOutput := TFakeOutput.Create;
  FOutputIntf := FOutput;
  FRegistry := TConsoleFactory.CreateRegistry;
  FInterpreter := TConsoleFactory.CreateInterpreter(FRegistry);
  FRunner := TRecordingRunner.Create;
  FRunnerIntf := FRunner;
  FCommands := TConsoleFactory.CreateStandardCommands(FRegistry, FOutputIntf, FRunnerIntf);
  FCommands.Register;
end;

procedure TTestConsoleStandardCommands.TearDown;
begin
  FCommands.Free;
  FRunnerIntf := nil;
  FInterpreter := nil;
  FRegistry := nil;
  FOutputIntf := nil;
end;

procedure TTestConsoleStandardCommands.TestRegisterAddsAllTheNames;
var
  LName: string;
begin
  for LName in TArray<string>.Create('cmdlist', 'list', 'listcmds', 'exec', 'execcommandfile',
    'printf', 'write', 'writeln') do
    Assert.IsTrue(FRegistry.Contains(LName), 'dovrebbe registrare ' + LName);
end;

procedure TTestConsoleStandardCommands.TestPrintfWritesTheTextAndALineBreak;
begin
  FInterpreter.Execute('printf hello');
  Assert.AreEqual('hello' + EOL, FOutput.Text, 'dovrebbe scrivere il testo e un a capo');
end;

procedure TTestConsoleStandardCommands.TestPrintfJoinsTheTwoParametersWithASpace;
begin
  FInterpreter.Execute('write hello big   world');
  Assert.AreEqual('hello big   world' + EOL, FOutput.Text,
    'dovrebbe unire il primo parametro e il resto con uno spazio');
end;

procedure TTestConsoleStandardCommands.TestPrintfDoesNotFormatThePercentSign;
begin
  FInterpreter.Execute('printf 50% sure %d');
  Assert.AreEqual('50% sure %d' + EOL, FOutput.Text, 'non dovrebbe interpretare il segno di percentuale');
end;

procedure TTestConsoleStandardCommands.TestListWritesTheSortedNamesAndTheTotal;
begin
  FRegistry.Add('zeta', procedure(const AParam1, AParam2: string) begin end);
  FInterpreter.Execute('list');
  Assert.AreEqual('CMDLIST' + EOL + 'EXEC' + EOL + 'EXECCOMMANDFILE' + EOL + 'LIST' + EOL + 'LISTCMDS' + EOL +
    'PRINTF' + EOL + 'WRITE' + EOL + 'WRITELN' + EOL + 'ZETA' + EOL + '9 total commands.' + EOL,
    FOutput.Text, 'dovrebbe elencare i nomi in ordine e il totale');
end;

procedure TTestConsoleStandardCommands.TestListWithAMaskWritesOnlyTheNamesThatFit;
begin
  FInterpreter.Execute('list wri*');
  Assert.AreEqual('WRITE' + EOL + 'WRITELN' + EOL + '2 total commands.' + EOL, FOutput.Text,
    'dovrebbe elencare i nomi che corrispondono');
end;

procedure TTestConsoleStandardCommands.TestExecGivesTheFileToTheRunner;
begin
  FInterpreter.Execute('exec my file');
  Assert.AreEqual('[my]', FRunner.Files, 'dovrebbe dare al runner il primo parametro');
  FInterpreter.Execute('execcommandfile other');
  Assert.AreEqual('[my][other]', FRunner.Files, 'dovrebbe valere anche per l''altro nome');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleStandardCommands);

end.
