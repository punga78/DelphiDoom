{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the registry of the console commands                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CommandRegistry;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Intf;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleCommandRegistry = class(TObject)
  private
    FRegistry: ICommandRegistry;
    FCalls: string;
    procedure AddCounting(const AName, ATag: string);
    function Run(const AName: string): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRegisteredCommandIsFound;
    [Test]
    procedure TestNamesAreNotCaseSensitive;
    [Test]
    procedure TestAliasesWithCommasAreAllRegistered;
    [Test]
    procedure TestAliasesWithMoreThanTwoNames;
    [Test]
    procedure TestEmptyNamesAreIgnored;
    [Test]
    procedure TestHandlerThatIsNilIsAnError;
    [Test]
    procedure TestSameNameTwiceKeepsTheLastHandler;
    [Test]
    procedure TestNamesAreUpperCaseAndSorted;
    [Test]
    procedure TestUnknownCommandIsNotFound;
  end;

implementation

uses
  DelphiDoom.Console.Types, DelphiDoom.Console.Factory;

{ TTestConsoleCommandRegistry }

procedure TTestConsoleCommandRegistry.Setup;
begin
  FRegistry := TConsoleFactory.CreateRegistry;
  FCalls := '';
end;

procedure TTestConsoleCommandRegistry.TearDown;
begin
  FRegistry := nil;
end;

procedure TTestConsoleCommandRegistry.AddCounting(const AName, ATag: string);
begin
  FRegistry.Add(AName,
    procedure(const AParam1, AParam2: string)
    begin
      FCalls := FCalls + ATag;
    end);
end;

function TTestConsoleCommandRegistry.Run(const AName: string): Boolean;
var
  LHandler: TConsoleCommandHandler;
begin
  Result := FRegistry.Find(AName, LHandler);
  if Result then
    LHandler('', '');
end;

procedure TTestConsoleCommandRegistry.TestRegisteredCommandIsFound;
begin
  AddCounting('dir', 'D');
  Assert.IsTrue(Run('dir'), 'dovrebbe trovare il comando');
  Assert.AreEqual('D', FCalls, 'dovrebbe eseguire il suo gestore');
  Assert.IsTrue(FRegistry.Contains('dir'), 'dovrebbe dire che c''e''');
end;

procedure TTestConsoleCommandRegistry.TestNamesAreNotCaseSensitive;
begin
  AddCounting('Dir', 'D');
  Assert.IsTrue(Run('DIR'), 'dovrebbe ignorare le maiuscole');
  Assert.IsTrue(Run('dIr'), 'dovrebbe ignorare le maiuscole');
end;

procedure TTestConsoleCommandRegistry.TestAliasesWithCommasAreAllRegistered;
begin
  AddCounting('dir, ls', 'D');
  Assert.IsTrue(Run('dir'), 'dovrebbe registrare il primo nome');
  Assert.IsTrue(Run('ls'), 'dovrebbe registrare il secondo nome, senza lo spazio');
  Assert.AreEqual('DD', FCalls);
end;

procedure TTestConsoleCommandRegistry.TestAliasesWithMoreThanTwoNames;
begin
  AddCounting('multi1 , multi2,multi3', 'M');
  Assert.IsTrue(Run('multi1') and Run('multi2') and Run('multi3'), 'dovrebbe registrare tutti i nomi');
  Assert.AreEqual(3, Length(FRegistry.Names), 'dovrebbe avere tre nomi');
end;

procedure TTestConsoleCommandRegistry.TestEmptyNamesAreIgnored;
begin
  AddCounting('', 'X');
  AddCounting('a,,b', 'A');
  AddCounting(',c', 'C');
  AddCounting('d,', 'D');
  Assert.AreEqual('A,B,C,D', string.Join(',', FRegistry.Names), 'dovrebbe saltare i nomi vuoti');
end;

procedure TTestConsoleCommandRegistry.TestHandlerThatIsNilIsAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      FRegistry.Add('dir', nil);
    end,
    EConsoleException, 'dovrebbe rifiutare un comando senza gestore');
end;

procedure TTestConsoleCommandRegistry.TestSameNameTwiceKeepsTheLastHandler;
begin
  AddCounting('dir', 'A');
  AddCounting('DIR', 'B');
  Run('dir');
  Assert.AreEqual('B', FCalls, 'dovrebbe tenere l''ultimo gestore');
  Assert.AreEqual(1, Length(FRegistry.Names), 'dovrebbe avere un solo nome');
end;

procedure TTestConsoleCommandRegistry.TestNamesAreUpperCaseAndSorted;
begin
  AddCounting('zeta', 'Z');
  AddCounting('Alfa', 'A');
  AddCounting('beta', 'B');
  Assert.AreEqual('ALFA,BETA,ZETA', string.Join(',', FRegistry.Names), 'dovrebbe dare i nomi in ordine');
end;

procedure TTestConsoleCommandRegistry.TestUnknownCommandIsNotFound;
begin
  Assert.IsFalse(Run('nothing'), 'dovrebbe dire che non c''e''');
  Assert.IsFalse(FRegistry.Contains('nothing'), 'dovrebbe dire che non c''e''');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleCommandRegistry);

end.
