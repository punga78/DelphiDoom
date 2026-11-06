{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the queue of the console commands                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CommandQueue;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Intf, DelphiDoom.Console.CommandQueue;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleCommandQueue = class(TObject)
  private
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FQueue: TConsoleCommandQueue;
    FRan: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCommandsAreDroppedUntilTheQueueIsEnabled;
    [Test]
    procedure TestCommandsWaitUntilTheyAreExecuted;
    [Test]
    procedure TestCommandsRunInTheOrderTheyWereAsked;
    [Test]
    procedure TestExecutedCommandsAreRemoved;
    [Test]
    procedure TestACommandThatAsksForAnotherOneWaitsForTheNextCall;
  end;

implementation

uses
  DelphiDoom.Console.Factory;

{ TTestConsoleCommandQueue }

procedure TTestConsoleCommandQueue.Setup;
begin
  FRan := '';
  FRegistry := TConsoleFactory.CreateRegistry;
  FRegistry.Add('run',
    procedure(const AParam1, AParam2: string)
    begin
      FRan := FRan + AParam1;
    end);
  FRegistry.Add('chain',
    procedure(const AParam1, AParam2: string)
    begin
      FRan := FRan + 'c';
      FQueue.Enqueue('run later');
    end);
  FInterpreter := TConsoleFactory.CreateInterpreter(FRegistry);
  FQueue := TConsoleFactory.CreateCommandQueue(FInterpreter);
end;

procedure TTestConsoleCommandQueue.TearDown;
begin
  FQueue.Free;
  FInterpreter := nil;
  FRegistry := nil;
end;

procedure TTestConsoleCommandQueue.TestCommandsAreDroppedUntilTheQueueIsEnabled;
begin
  FQueue.Enqueue('run a');
  Assert.AreEqual(0, FQueue.Count, 'dovrebbe scartare i comandi finche'' la console non e'' attiva');
  FQueue.Enabled := True;
  FQueue.Enqueue('run a');
  Assert.AreEqual(1, FQueue.Count, 'dovrebbe tenere il comando');
end;

procedure TTestConsoleCommandQueue.TestCommandsWaitUntilTheyAreExecuted;
begin
  FQueue.Enabled := True;
  FQueue.Enqueue('run a');
  Assert.AreEqual('', FRan, 'non dovrebbe eseguire subito');
  FQueue.ExecutePending;
  Assert.AreEqual('a', FRan, 'dovrebbe eseguire alla chiamata');
end;

procedure TTestConsoleCommandQueue.TestCommandsRunInTheOrderTheyWereAsked;
begin
  FQueue.Enabled := True;
  FQueue.Enqueue('run a');
  FQueue.Enqueue('run b');
  FQueue.Enqueue('run c');
  FQueue.ExecutePending;
  Assert.AreEqual('abc', FRan, 'dovrebbe rispettare l''ordine');
end;

procedure TTestConsoleCommandQueue.TestExecutedCommandsAreRemoved;
begin
  FQueue.Enabled := True;
  FQueue.Enqueue('run a');
  FQueue.ExecutePending;
  FQueue.ExecutePending;
  Assert.AreEqual('a', FRan, 'non dovrebbe eseguire due volte');
  Assert.AreEqual(0, FQueue.Count, 'dovrebbe svuotare la coda');
end;

procedure TTestConsoleCommandQueue.TestACommandThatAsksForAnotherOneWaitsForTheNextCall;
begin
  FQueue.Enabled := True;
  FQueue.Enqueue('chain');
  FQueue.ExecutePending;
  Assert.AreEqual('c', FRan, 'il comando richiesto durante l''esecuzione non dovrebbe partire subito');
  Assert.AreEqual(1, FQueue.Count, 'dovrebbe restare in coda');
  FQueue.ExecutePending;
  Assert.AreEqual('clater', FRan, 'dovrebbe partire alla chiamata dopo');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleCommandQueue);

end.
