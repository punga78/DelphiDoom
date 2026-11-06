{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the input line of the console                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.InputLine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Intf, DelphiDoom.Console.InputLine,
  DelphiDoom.Tests.Console.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleInputLine = class(TObject)
  private
    FOutput: TFakeOutput;
    FOutputIntf: IConsoleOutput;
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FLine: TConsoleInputLine;
    FRan: string;
    procedure Type_(const AText: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestStartsWithThePromptAlone;
    [Test]
    procedure TestTypedCharactersAreAppendedAfterThePrompt;
    [Test]
    procedure TestBackspaceNeverRemovesThePrompt;
    [Test]
    procedure TestResetGoesBackToThePrompt;
    [Test]
    procedure TestAnyChangeAsksToDrawAgain;
    [Test]
    procedure TestSubmitEchoesRunsAndClears;
    [Test]
    procedure TestSubmitOfAnUnknownCommandSaysSo;
    [Test]
    procedure TestSubmitOfAnEmptyLineDoesNothing;
    [Test]
    procedure TestHistoryGivesBackTheLinesWithThePrompt;
    [Test]
    procedure TestHistoryWithNothingKeepsTheBuffer;
    [Test]
    procedure TestCompleteWithOneNameWritesItAndASpace;
    [Test]
    procedure TestCompleteWithManyNamesWritesTheCommonStartAndTheList;
    [Test]
    procedure TestCompleteDoesNothingAfterTheFirstWord;
    [Test]
    procedure TestCompleteWithoutCompleterDoesNothing;
  end;

implementation

uses
  DelphiDoom.Console.Factory, DelphiDoom.Console.Types, DelphiDoom.Console.History,
  DelphiDoom.Console.Completer;

const
  EOL = #13#10;
  PROMPT = ']';

{ TTestConsoleInputLine }

procedure TTestConsoleInputLine.Setup;
var
  LHandler: TConsoleCommandHandler;
begin
  FOutput := TFakeOutput.Create;
  FOutputIntf := FOutput;
  FRan := '';
  FRegistry := TConsoleFactory.CreateRegistry;
  LHandler :=
    procedure(const AParam1, AParam2: string)
    begin
      FRan := FRan + '[' + AParam1 + ']';
    end;
  FRegistry.Add('echo', LHandler);
  FRegistry.Add('exec', LHandler);
  FRegistry.Add('execcommandfile', LHandler);
  FRegistry.Add('quit', LHandler);
  FInterpreter := TConsoleFactory.CreateInterpreter(FRegistry);
  FLine := TConsoleFactory.CreateInputLine(PROMPT, FInterpreter, FOutputIntf,
    TConsoleFactory.CreateHistory, TConsoleFactory.CreateCompleter(FRegistry, nil));
end;

procedure TTestConsoleInputLine.TearDown;
begin
  FLine.Free;
  FInterpreter := nil;
  FRegistry := nil;
  FOutputIntf := nil;
end;

procedure TTestConsoleInputLine.Type_(const AText: string);
var
  LChar: Char;
begin
  for LChar in AText do
    FLine.AppendChar(LChar);
end;

procedure TTestConsoleInputLine.TestStartsWithThePromptAlone;
begin
  Assert.AreEqual(PROMPT, FLine.Buffer, 'dovrebbe contenere solo il prompt');
  Assert.IsTrue(FLine.IsEmpty, 'dovrebbe essere vuota');
  Assert.AreEqual('', FLine.CommandText);
end;

procedure TTestConsoleInputLine.TestTypedCharactersAreAppendedAfterThePrompt;
begin
  Type_('echo');
  Assert.AreEqual(PROMPT + 'echo', FLine.Buffer, 'dovrebbe aggiungere i caratteri dopo il prompt');
  Assert.AreEqual('echo', FLine.CommandText, 'dovrebbe dare il testo senza il prompt');
  Assert.IsFalse(FLine.IsEmpty);
end;

procedure TTestConsoleInputLine.TestBackspaceNeverRemovesThePrompt;
begin
  Type_('ab');
  FLine.Backspace;
  Assert.AreEqual(PROMPT + 'a', FLine.Buffer, 'dovrebbe togliere un carattere');
  FLine.Backspace;
  FLine.Backspace;
  Assert.AreEqual(PROMPT, FLine.Buffer, 'dovrebbe lasciare il prompt');
end;

procedure TTestConsoleInputLine.TestResetGoesBackToThePrompt;
begin
  Type_('abc');
  FLine.Reset;
  Assert.IsTrue(FLine.IsEmpty, 'dovrebbe tornare al prompt');
end;

procedure TTestConsoleInputLine.TestAnyChangeAsksToDrawAgain;
begin
  FLine.NeedsUpdate := False;
  FLine.AppendChar('a');
  Assert.IsTrue(FLine.NeedsUpdate, 'dovrebbe chiedere di ridisegnare');
  FLine.NeedsUpdate := False;
  FLine.Backspace;
  Assert.IsTrue(FLine.NeedsUpdate, 'dovrebbe chiedere di ridisegnare');
  FLine.NeedsUpdate := False;
  FLine.Backspace;
  Assert.IsFalse(FLine.NeedsUpdate, 'non dovrebbe chiedere niente se non cambia');
end;

procedure TTestConsoleInputLine.TestSubmitEchoesRunsAndClears;
begin
  Type_('echo hi');
  Assert.IsTrue(FLine.Submit, 'dovrebbe dire che ha eseguito la riga');
  Assert.AreEqual(PROMPT + 'echo hi' + EOL, FOutput.Text, 'dovrebbe scrivere la riga con il prompt');
  Assert.AreEqual('[hi]', FRan, 'dovrebbe eseguire il comando');
  Assert.IsTrue(FLine.IsEmpty, 'dovrebbe tornare al prompt');
end;

procedure TTestConsoleInputLine.TestSubmitOfAnUnknownCommandSaysSo;
begin
  Type_('nothing a b c');
  FLine.Submit;
  Assert.AreEqual(PROMPT + 'nothing a b c' + EOL + 'Unknown command' + EOL, FOutput.Text,
    'dovrebbe dire che il comando non c''e''');
end;

procedure TTestConsoleInputLine.TestSubmitOfAnEmptyLineDoesNothing;
begin
  Assert.IsFalse(FLine.Submit, 'dovrebbe dire che non c''era niente');
  Assert.AreEqual('', FOutput.Text, 'non dovrebbe scrivere niente');
end;

procedure TTestConsoleInputLine.TestHistoryGivesBackTheLinesWithThePrompt;
begin
  Type_('echo one');
  FLine.Submit;
  Type_('echo two');
  FLine.Submit;
  Assert.IsTrue(FLine.HistoryPrevious);
  Assert.AreEqual(PROMPT + 'echo two', FLine.Buffer, 'dovrebbe dare l''ultima riga');
  Assert.IsTrue(FLine.HistoryPrevious);
  Assert.AreEqual(PROMPT + 'echo one', FLine.Buffer);
  Assert.IsTrue(FLine.HistoryNext);
  Assert.AreEqual(PROMPT + 'echo two', FLine.Buffer, 'dovrebbe tornare avanti');
end;

procedure TTestConsoleInputLine.TestHistoryWithNothingKeepsTheBuffer;
begin
  Type_('abc');
  Assert.IsFalse(FLine.HistoryPrevious, 'dovrebbe dire che non c''e'' niente');
  Assert.AreEqual(PROMPT + 'abc', FLine.Buffer, 'dovrebbe lasciare il testo');
end;

procedure TTestConsoleInputLine.TestCompleteWithOneNameWritesItAndASpace;
begin
  Type_('qu');
  Assert.AreEqual(1, FLine.Complete, 'dovrebbe dire che c''e'' un solo nome');
  Assert.AreEqual(PROMPT + 'quit ', FLine.Buffer, 'dovrebbe completare il nome e aggiungere uno spazio');
end;

procedure TTestConsoleInputLine.TestCompleteWithManyNamesWritesTheCommonStartAndTheList;
begin
  Type_('e');
  Assert.AreEqual(3, FLine.Complete, 'dovrebbe dire quanti nomi corrispondono');
  Assert.AreEqual(PROMPT + 'e', FLine.Buffer, 'non c''e'' un inizio piu'' lungo in comune: resta cosi''');
  Assert.AreEqual('echo exec execcommandfile' + EOL, FOutput.Text, 'dovrebbe elencare i nomi');
  FLine.Reset;
  FOutput.Clear;
  Type_('exe');
  Assert.AreEqual(2, FLine.Complete);
  Assert.AreEqual(PROMPT + 'exec', FLine.Buffer, 'dovrebbe scrivere l''inizio in comune');
end;

procedure TTestConsoleInputLine.TestCompleteDoesNothingAfterTheFirstWord;
begin
  Type_('echo qu');
  Assert.AreEqual(0, FLine.Complete, 'dovrebbe completare solo il primo nome');
  Assert.AreEqual(PROMPT + 'echo qu', FLine.Buffer);
end;

procedure TTestConsoleInputLine.TestCompleteWithoutCompleterDoesNothing;
var
  LLine: TConsoleInputLine;
begin
  LLine := TConsoleFactory.CreateInputLine(PROMPT, FInterpreter, FOutputIntf,
    TConsoleFactory.CreateHistory, nil);
  try
    LLine.AppendChar('q');
    Assert.AreEqual(0, LLine.Complete, 'dovrebbe dare 0');
    Assert.AreEqual(PROMPT + 'q', LLine.Buffer);
  finally
    LLine.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleInputLine);

end.
