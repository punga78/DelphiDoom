{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the completion of the console                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Completer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Intf, DelphiDoom.Console.Completer,
  DelphiDoom.Tests.Console.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleCompleter = class(TObject)
  private
    FRegistry: ICommandRegistry;
    FSource: TFakeVariableSource;
    FSourceIntf: IConsoleVariableSource;
    FCompleter: TConsoleCompleter;
    function Joined(const APrefix: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestFindsCommandsAndVariablesThatStartWithThePrefix;
    [Test]
    procedure TestNamesAreInLowerCaseAndSorted;
    [Test]
    procedure TestPrefixIsNotCaseSensitive;
    [Test]
    procedure TestEmptyPrefixGivesAllTheNames;
    [Test]
    procedure TestNothingFitsGivesAnEmptyList;
    [Test]
    procedure TestSameNameOfCommandAndVariableIsGivenOnce;
    [Test]
    procedure TestWithoutVariablesOnlyCommandsAreGiven;
    [Test]
    procedure TestCommonPrefix;
    [Test]
    procedure TestCommonPrefixOfNothingIsEmpty;
  end;

implementation

uses
  DelphiDoom.Console.Types, DelphiDoom.Console.Factory;

{ TTestConsoleCompleter }

procedure TTestConsoleCompleter.Setup;
var
  LHandler: TConsoleCommandHandler;
begin
  LHandler :=
    procedure(const AParam1, AParam2: string)
    begin
    end;
  FRegistry := TConsoleFactory.CreateRegistry;
  FRegistry.Add('echo', LHandler);
  FRegistry.Add('exec, execcommandfile', LHandler);
  FRegistry.Add('fraglimit', LHandler);
  FSource := TFakeVariableSource.Create;
  FSourceIntf := FSource;
  FSource.AddInteger('fraglimit', [camSinglePlayer], 0);
  FSource.AddInteger('frames', [camSinglePlayer], 0);
  FSource.AddBoolean('showfps', [camSinglePlayer], False);
  FCompleter := TConsoleFactory.CreateCompleter(FRegistry, FSourceIntf);
end;

procedure TTestConsoleCompleter.TearDown;
begin
  FCompleter.Free;
  FSourceIntf := nil;
  FRegistry := nil;
end;

function TTestConsoleCompleter.Joined(const APrefix: string): string;
begin
  Result := string.Join(',', FCompleter.Candidates(APrefix));
end;

procedure TTestConsoleCompleter.TestFindsCommandsAndVariablesThatStartWithThePrefix;
begin
  Assert.AreEqual('fraglimit,frames', Joined('fr'), 'dovrebbe trovare comandi e variabili');
  Assert.AreEqual('showfps', Joined('sh'), 'dovrebbe trovare le variabili');
  Assert.AreEqual('exec,execcommandfile', Joined('ex'), 'dovrebbe trovare i comandi');
end;

procedure TTestConsoleCompleter.TestNamesAreInLowerCaseAndSorted;
begin
  Assert.AreEqual('echo,exec,execcommandfile,fraglimit,frames,showfps', Joined(''),
    'dovrebbe dare i nomi in minuscolo e in ordine');
end;

procedure TTestConsoleCompleter.TestPrefixIsNotCaseSensitive;
begin
  Assert.AreEqual('exec,execcommandfile', Joined('EXE'), 'dovrebbe ignorare le maiuscole');
end;

procedure TTestConsoleCompleter.TestEmptyPrefixGivesAllTheNames;
begin
  Assert.AreEqual(6, Length(FCompleter.Candidates('')), 'dovrebbe dare tutti i nomi');
end;

procedure TTestConsoleCompleter.TestNothingFitsGivesAnEmptyList;
begin
  Assert.AreEqual(0, Length(FCompleter.Candidates('zz')), 'dovrebbe dare una lista vuota');
end;

procedure TTestConsoleCompleter.TestSameNameOfCommandAndVariableIsGivenOnce;
begin
  Assert.AreEqual('fraglimit', Joined('fragl'), 'dovrebbe dare il nome una volta sola');
end;

procedure TTestConsoleCompleter.TestWithoutVariablesOnlyCommandsAreGiven;
var
  LCompleter: TConsoleCompleter;
begin
  LCompleter := TConsoleFactory.CreateCompleter(FRegistry, nil);
  try
    Assert.AreEqual('fraglimit', string.Join(',', LCompleter.Candidates('fr')),
      'dovrebbe dare i soli comandi');
  finally
    LCompleter.Free;
  end;
end;

procedure TTestConsoleCompleter.TestCommonPrefix;
begin
  Assert.AreEqual('exec', TConsoleCompleter.CommonPrefix(TArray<string>.Create('exec', 'execcommandfile')),
    'dovrebbe dare l''inizio in comune');
  Assert.AreEqual('f', TConsoleCompleter.CommonPrefix(TArray<string>.Create('fraglimit', 'fps')));
  Assert.AreEqual('', TConsoleCompleter.CommonPrefix(TArray<string>.Create('a', 'b')));
  Assert.AreEqual('only', TConsoleCompleter.CommonPrefix(TArray<string>.Create('only')));
end;

procedure TTestConsoleCompleter.TestCommonPrefixOfNothingIsEmpty;
begin
  Assert.AreEqual('', TConsoleCompleter.CommonPrefix(nil), 'dovrebbe dare una stringa vuota');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleCompleter);

end.
