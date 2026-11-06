{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the interpreter of the console                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Interpreter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Intf;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleInterpreter = class(TObject)
  private
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FCalls: string;
    procedure AddRecording(const AName: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNameAndParametersAreCut;
    [Test]
    procedure TestSecondParameterIsTheRestOfTheLine;
    [Test]
    procedure TestNameIsNotCaseSensitive;
    [Test]
    procedure TestMissingParametersAreEmpty;
    [Test]
    procedure TestUnknownCommandGivesFalse;
    [Test]
    procedure TestVariableNameAloneBecomesGet;
    [Test]
    procedure TestVariableNameWithValueBecomesSet;
    [Test]
    procedure TestVariableNameWithTwoParametersGivesFalse;
    [Test]
    procedure TestGetAndSetReceiveTheNameInUpperCase;
    [Test]
    procedure TestWithoutGetAndSetNothingHappens;
    [Test]
    procedure TestLineWithLeadingSpaceHasAnEmptyName;
    [Test]
    procedure TestNilRegistryIsAnError;
  end;

implementation

uses
  DelphiDoom.Console.Types, DelphiDoom.Console.Factory;

{ TTestConsoleInterpreter }

procedure TTestConsoleInterpreter.Setup;
begin
  FRegistry := TConsoleFactory.CreateRegistry;
  FInterpreter := TConsoleFactory.CreateInterpreter(FRegistry);
  FCalls := '';
end;

procedure TTestConsoleInterpreter.TearDown;
begin
  FInterpreter := nil;
  FRegistry := nil;
end;

procedure TTestConsoleInterpreter.AddRecording(const AName: string);
begin
  FRegistry.Add(AName,
    procedure(const AParam1, AParam2: string)
    begin
      FCalls := FCalls + AName + '<' + AParam1 + '|' + AParam2 + '>';
    end);
end;

procedure TTestConsoleInterpreter.TestNameAndParametersAreCut;
begin
  AddRecording('echo');
  Assert.IsTrue(FInterpreter.Execute('echo one two'), 'dovrebbe eseguire il comando');
  Assert.AreEqual('echo<one|two>', FCalls, 'dovrebbe passare due parametri');
end;

procedure TTestConsoleInterpreter.TestSecondParameterIsTheRestOfTheLine;
begin
  AddRecording('echo');
  FInterpreter.Execute('echo one two   three  four  ');
  Assert.AreEqual('echo<one|two   three  four>', FCalls,
    'dovrebbe dare il resto della riga senza gli spazi ai lati');
end;

procedure TTestConsoleInterpreter.TestNameIsNotCaseSensitive;
begin
  AddRecording('echo');
  Assert.IsTrue(FInterpreter.Execute('ECHO x'), 'dovrebbe ignorare le maiuscole');
end;

procedure TTestConsoleInterpreter.TestMissingParametersAreEmpty;
begin
  AddRecording('echo');
  FInterpreter.Execute('echo');
  FInterpreter.Execute('echo a');
  Assert.AreEqual('echo<|>echo<a|>', FCalls, 'dovrebbe dare parametri vuoti');
end;

procedure TTestConsoleInterpreter.TestUnknownCommandGivesFalse;
begin
  Assert.IsFalse(FInterpreter.Execute('unknown a b'), 'dovrebbe dare false');
  Assert.IsFalse(FInterpreter.Execute('unknown a b c'), 'dovrebbe dare false');
end;

procedure TTestConsoleInterpreter.TestVariableNameAloneBecomesGet;
begin
  AddRecording('get');
  Assert.IsTrue(FInterpreter.Execute('fraglimit'), 'dovrebbe passare a get');
  Assert.AreEqual('get<FRAGLIMIT|>', FCalls);
end;

procedure TTestConsoleInterpreter.TestVariableNameWithValueBecomesSet;
begin
  AddRecording('set');
  Assert.IsTrue(FInterpreter.Execute('fraglimit 7'), 'dovrebbe passare a set');
  Assert.AreEqual('set<FRAGLIMIT|7>', FCalls);
end;

procedure TTestConsoleInterpreter.TestVariableNameWithTwoParametersGivesFalse;
begin
  AddRecording('set');
  Assert.IsFalse(FInterpreter.Execute('fraglimit 7 8'), 'dovrebbe dare false');
  Assert.AreEqual('', FCalls, 'non dovrebbe eseguire niente');
end;

procedure TTestConsoleInterpreter.TestGetAndSetReceiveTheNameInUpperCase;
begin
  AddRecording('get');
  FInterpreter.Execute('showFps');
  Assert.AreEqual('get<SHOWFPS|>', FCalls, 'dovrebbe conservare il comportamento: il nome va in maiuscolo');
end;

procedure TTestConsoleInterpreter.TestWithoutGetAndSetNothingHappens;
begin
  Assert.IsFalse(FInterpreter.Execute('fraglimit'), 'dovrebbe dare false senza il comando get');
  Assert.IsFalse(FInterpreter.Execute('fraglimit 7'), 'dovrebbe dare false senza il comando set');
  Assert.IsFalse(FInterpreter.Execute('get'), 'get stesso non deve richiamarsi');
  Assert.IsFalse(FInterpreter.Execute('set'), 'set stesso non deve richiamarsi');
end;

procedure TTestConsoleInterpreter.TestLineWithLeadingSpaceHasAnEmptyName;
begin
  AddRecording('echo');
  Assert.IsFalse(FInterpreter.Execute('  echo   a   '),
    'dovrebbe conservare il comportamento: con uno spazio davanti il nome e'' vuoto');
  Assert.AreEqual('', FCalls);
end;

procedure TTestConsoleInterpreter.TestNilRegistryIsAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      TConsoleFactory.CreateInterpreter(nil);
    end,
    EArgumentNilException, 'dovrebbe rifiutare un registro nil');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleInterpreter);

end.
