{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the commands get, set and typeof                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.VariableCommands;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.GameState.Intf,
  DelphiDoom.Console.Intf, DelphiDoom.Console.VariableCommands, DelphiDoom.Tests.Console.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleVariableCommands = class(TObject)
  private
    FOutput: TFakeOutput;
    FOutputIntf: IConsoleOutput;
    FLog: ILog;
    FGame: TFakeGameContext;
    FGameIntf: IGameContext;
    FSource: TFakeVariableSource;
    FSourceIntf: IConsoleVariableSource;
    FRegistry: ICommandRegistry;
    FCommands: TConsoleVariableCommands;
    FFragLimit: TFakeVariable;
    FShowFps: TFakeVariable;
    FPlayerName: TFakeVariable;
    FVersion: TFakeVariable;
    FAutoRun: TFakeVariable;
    function Said: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGetShowsAnIntegerWithTheTypedName;
    [Test]
    procedure TestGetShowsABooleanAsOnOff;
    [Test]
    procedure TestGetShowsAString;
    [Test]
    procedure TestGetWithAMaskShowsTheVariablesThatFit;
    [Test]
    procedure TestGetWithoutNameListsTheVariables;
    [Test]
    procedure TestGetOfACommandRunsItWithoutParameters;
    [Test]
    procedure TestGetOfUnknownNameSaysUnknownCommand;
    [Test]
    procedure TestSetWritesAnInteger;
    [Test]
    procedure TestSetOfNotANumberWritesZero;
    [Test]
    procedure TestSetWritesABooleanAndKeepsTheOldOneIfNotUnderstood;
    [Test]
    procedure TestSetWritesAStringWithSpaces;
    [Test]
    procedure TestSetWithoutValueAsksForIt;
    [Test]
    procedure TestSetOfAReadOnlyVariableWarns;
    [Test]
    procedure TestSetOfASinglePlayerVariableInNetworkGameWarns;
    [Test]
    procedure TestSetOfANetworkVariableInSinglePlayerGameDoesNothing;
    [Test]
    procedure TestSetOfACommandRunsItWithTheValue;
    [Test]
    procedure TestSetWithAMaskListsOnlyTheVariablesThatCanBeSet;
    [Test]
    procedure TestTypeOfShowsTheType;
    [Test]
    procedure TestTypeOfUnknownVariable;
    [Test]
    procedure TestTypeOfWithoutNameShowsTheUsageAndThenUnknown;
    [Test]
    procedure TestRegisterAddsTheThreeCommands;
  end;

implementation

uses
  DelphiDoom.Console.Types, DelphiDoom.Console.Factory;

const
  EOL = #13#10;

{ TTestConsoleVariableCommands }

procedure TTestConsoleVariableCommands.Setup;
begin
  FOutput := TFakeOutput.Create;
  FOutputIntf := FOutput;
  FLog := TFakeLog.Create(FOutput);
  FGame := TFakeGameContext.Create;
  FGameIntf := FGame;
  FSource := TFakeVariableSource.Create;
  FSourceIntf := FSource;
  FFragLimit := FSource.AddInteger('fraglimit', [camSinglePlayer], 5);
  FShowFps := FSource.AddBoolean('showfps', [camSinglePlayer, camNetwork], False);
  FPlayerName := FSource.AddString('playername', [camSinglePlayer, camNetwork], 'player');
  FVersion := FSource.AddString('version', [], 'v1');
  FAutoRun := FSource.AddBoolean('autorun', [camNetwork], True);
  FRegistry := TConsoleFactory.CreateRegistry;
  FCommands := TConsoleFactory.CreateVariableCommands(FRegistry, FSourceIntf, FOutputIntf, FLog, FGameIntf);
end;

procedure TTestConsoleVariableCommands.TearDown;
begin
  FCommands.Free;
  FRegistry := nil;
  FSourceIntf := nil;
  FGameIntf := nil;
  FLog := nil;
  FOutputIntf := nil;
end;

function TTestConsoleVariableCommands.Said: string;
begin
  Result := FOutput.Text;
end;

procedure TTestConsoleVariableCommands.TestGetShowsAnIntegerWithTheTypedName;
begin
  FCommands.GetVariable('FragLimit');
  Assert.AreEqual('FragLimit=5' + EOL, Said, 'dovrebbe scrivere il nome come e'' stato digitato');
end;

procedure TTestConsoleVariableCommands.TestGetShowsABooleanAsOnOff;
begin
  FCommands.GetVariable('showfps');
  FShowFps.BooleanValue := True;
  FCommands.GetVariable('showfps');
  Assert.AreEqual('showfps=OFF' + EOL + 'showfps=ON' + EOL, Said, 'dovrebbe scrivere ON e OFF');
end;

procedure TTestConsoleVariableCommands.TestGetShowsAString;
begin
  FCommands.GetVariable('playername');
  Assert.AreEqual('playername=player' + EOL, Said, 'dovrebbe scrivere il testo');
end;

procedure TTestConsoleVariableCommands.TestGetWithAMaskShowsTheVariablesThatFit;
begin
  FCommands.GetVariable('*e');
  Assert.AreEqual('playername=player' + EOL + 'version=v1' + EOL, Said,
    'dovrebbe scrivere le variabili che finiscono per e, in ordine');
end;

procedure TTestConsoleVariableCommands.TestGetWithoutNameListsTheVariables;
begin
  FCommands.GetVariable('');
  Assert.AreEqual('Usage is:' + EOL + 'get [name]' + EOL + ' Display the current settings of:' + EOL +
    '  fraglimit' + EOL + '  showfps' + EOL + '  playername' + EOL + '  version' + EOL + '  autorun' + EOL,
    Said, 'dovrebbe scrivere l''uso e l''elenco');
end;

procedure TTestConsoleVariableCommands.TestGetOfACommandRunsItWithoutParameters;
var
  LCalled: string;
begin
  FRegistry.Add('dir',
    procedure(const AParam1, AParam2: string)
    begin
      LCalled := '<' + AParam1 + '|' + AParam2 + '>';
    end);
  FCommands.GetVariable('dir');
  Assert.AreEqual('<|>', LCalled, 'dovrebbe eseguire il comando senza parametri');
  Assert.AreEqual('', Said, 'non dovrebbe scrivere altro');
end;

procedure TTestConsoleVariableCommands.TestGetOfUnknownNameSaysUnknownCommand;
begin
  FCommands.GetVariable('nosuch');
  Assert.AreEqual('Unknown command' + EOL, Said, 'dovrebbe dire che il comando non c''e''');
end;

procedure TTestConsoleVariableCommands.TestSetWritesAnInteger;
begin
  FCommands.SetVariable('FRAGLIMIT', '0x10');
  Assert.AreEqual(16, FFragLimit.IntegerValue, 'dovrebbe scrivere il numero, anche esadecimale');
end;

procedure TTestConsoleVariableCommands.TestSetOfNotANumberWritesZero;
begin
  FCommands.SetVariable('fraglimit', 'abc');
  Assert.AreEqual(0, FFragLimit.IntegerValue, 'dovrebbe scrivere 0');
end;

procedure TTestConsoleVariableCommands.TestSetWritesABooleanAndKeepsTheOldOneIfNotUnderstood;
begin
  FCommands.SetVariable('showfps', 'yes');
  Assert.IsTrue(FShowFps.BooleanValue, 'dovrebbe capire yes');
  FCommands.SetVariable('showfps', 'maybe');
  Assert.IsTrue(FShowFps.BooleanValue, 'dovrebbe tenere il valore che c''era');
  FCommands.SetVariable('showfps', 'off');
  Assert.IsFalse(FShowFps.BooleanValue, 'dovrebbe capire off');
end;

procedure TTestConsoleVariableCommands.TestSetWritesAStringWithSpaces;
begin
  FCommands.SetVariable('playername', 'Bob Smith');
  Assert.AreEqual('Bob Smith', FPlayerName.StringValue, 'dovrebbe scrivere tutto il resto della riga');
end;

procedure TTestConsoleVariableCommands.TestSetWithoutValueAsksForIt;
begin
  FCommands.SetVariable('fraglimit', '');
  Assert.AreEqual('Please give the value to set fraglimit' + EOL, Said, 'dovrebbe chiedere il valore');
  Assert.AreEqual(5, FFragLimit.IntegerValue, 'non dovrebbe cambiare niente');
end;

procedure TTestConsoleVariableCommands.TestSetOfAReadOnlyVariableWarns;
begin
  FCommands.SetVariable('version', 'v2');
  Assert.AreEqual('[warn] Can not set readonly variable: version' + EOL, Said, 'dovrebbe avvisare');
  Assert.AreEqual('v1', FVersion.StringValue, 'non dovrebbe cambiare niente');
end;

procedure TTestConsoleVariableCommands.TestSetOfASinglePlayerVariableInNetworkGameWarns;
begin
  FGame.NetGame := True;
  FCommands.SetVariable('fraglimit', '9');
  Assert.AreEqual('[warn] Can not set variable: fraglimit during network game' + EOL, Said,
    'dovrebbe avvisare');
  Assert.AreEqual(5, FFragLimit.IntegerValue, 'non dovrebbe cambiare niente');
end;

procedure TTestConsoleVariableCommands.TestSetOfANetworkVariableInSinglePlayerGameDoesNothing;
begin
  FCommands.SetVariable('autorun', 'off');
  Assert.AreEqual('', Said, 'non dovrebbe dire niente');
  Assert.IsTrue(FAutoRun.BooleanValue, 'non dovrebbe cambiare niente');
  FGame.NetGame := True;
  FCommands.SetVariable('autorun', 'off');
  Assert.IsFalse(FAutoRun.BooleanValue, 'in rete dovrebbe cambiare');
end;

procedure TTestConsoleVariableCommands.TestSetOfACommandRunsItWithTheValue;
var
  LCalled: string;
begin
  FRegistry.Add('dir',
    procedure(const AParam1, AParam2: string)
    begin
      LCalled := '<' + AParam1 + '|' + AParam2 + '>';
    end);
  FCommands.SetVariable('dir', 'x y');
  Assert.AreEqual('<x y|>', LCalled, 'dovrebbe passare il valore come primo parametro');
end;

procedure TTestConsoleVariableCommands.TestSetWithAMaskListsOnlyTheVariablesThatCanBeSet;
begin
  FCommands.SetVariable('*', '');
  Assert.AreEqual('fraglimit' + EOL + 'showfps' + EOL + 'playername' + EOL, Said,
    'dovrebbe elencare le sole variabili modificabili ora');
  FOutput.Clear;
  FGame.NetGame := True;
  FCommands.SetVariable('*', '');
  Assert.AreEqual('showfps' + EOL + 'playername' + EOL + 'autorun' + EOL, Said,
    'in rete dovrebbe cambiare l''elenco');
end;

procedure TTestConsoleVariableCommands.TestTypeOfShowsTheType;
begin
  FCommands.TypeOfVariable('Fraglimit');
  FCommands.TypeOfVariable('showfps');
  FCommands.TypeOfVariable('playername');
  Assert.AreEqual('Fraglimit is integer' + EOL + 'showfps is boolean' + EOL + 'playername is string' + EOL,
    Said, 'dovrebbe dire il tipo');
end;

procedure TTestConsoleVariableCommands.TestTypeOfUnknownVariable;
begin
  FCommands.TypeOfVariable('nosuch');
  Assert.AreEqual('Unknown variable: nosuch' + EOL, Said, 'dovrebbe dire che la variabile non c''e''');
end;

procedure TTestConsoleVariableCommands.TestTypeOfWithoutNameShowsTheUsageAndThenUnknown;
begin
  FCommands.TypeOfVariable('');
  Assert.AreEqual('Usage is:' + EOL + 'typeof [name]' + EOL + ' Display the type of variable.' + EOL +
    'Unknown variable: ' + EOL, Said, 'dovrebbe conservare il comportamento del vecchio codice');
end;

procedure TTestConsoleVariableCommands.TestRegisterAddsTheThreeCommands;
begin
  FCommands.Register;
  Assert.IsTrue(FRegistry.Contains('get'), 'dovrebbe registrare get');
  Assert.IsTrue(FRegistry.Contains('set'), 'dovrebbe registrare set');
  Assert.IsTrue(FRegistry.Contains('typeof'), 'dovrebbe registrare typeof');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleVariableCommands);

end.
