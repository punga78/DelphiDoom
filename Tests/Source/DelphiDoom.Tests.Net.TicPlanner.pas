{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the net library - how many tics the game can run       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.TicPlanner;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Net.Types, DelphiDoom.Net.Intf,
  DelphiDoom.Tests.Net.Fakes, DelphiDoom.Tests.Net.TicSync;

type
  [TestFixture]
  [Category('net')]
  TTestNetTicPlanner = class(TObject)
  private
    FNet: TFakeNetwork;
    FSingle: TNodeRig;
    FA: TNodeRig;
    FB: TNodeRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    /// <summary>With five tics in the store, from the formulas of D_RunMultipleTicks</summary>
    [Test]
    [TestCase('Tanti tic reali', '5,0,5')]
    [TestCase('Pochi tic reali', '2,0,3')]
    [TestCase('Uno meno del disponibile', '4,0,4')]
    [TestCase('Zero tic reali', '0,0,1')]
    [TestCase('Piu del disponibile', '9,0,5')]
    [TestCase('Niente disponibile', '3,5,1')]
    [TestCase('Due disponibili, zero reali', '0,3,1')]
    [TestCase('Due disponibili, uno reale', '1,3,1')]
    [TestCase('Due disponibili, due reali', '2,3,2')]
    procedure TestHowManyTicsToRun(ARealTics, AGameTic, AExpected: Integer);

    [Test]
    procedure TestBeginRunGivesTheRealTicsFromTheLastPass;
    [Test]
    procedure TestEnterTimeIsTheTimeOfTheBeginningOfThePass;
    [Test]
    procedure TestTicDupDividesTheRealTics;
    [Test]
    procedure TestMustYieldAfterTenTics;
    [Test]
    procedure TestNeverYieldDuringADemo;
    [Test]
    procedure TestTicsAreReadyWhenEveryNodeHasThem;
    [Test]
    procedure TestNodeBehindTheGameIsAnError;
    [Test]
    procedure TestGameTicAheadOfTheSlowestNodeIsAnError;
    [Test]
    procedure TestLowTicIsTheLowestOfTheNodesInTheGame;
    [Test]
    procedure TestSlowComputerSkipsATicWhenItIsAlwaysAhead;
    [Test]
    procedure TestKeyPlayerDoesNotAdapt;
    [Test]
    procedure TestDemoPlaybackDoesNotAdapt;
  end;

implementation

{ TTestNetTicPlanner }

procedure TTestNetTicPlanner.Setup;
begin
  FNet := TFakeNetwork.Create;
  FSingle := TNodeRig.Create(nil, 0, [], 0, 1, 0);
  FSingle.Game.NetGame := False;
  FA := TNodeRig.Create(FNet, 0, [1], 0, 1, 0);
  FB := TNodeRig.Create(FNet, 1, [0], 1, 1, 0);
end;

procedure TTestNetTicPlanner.TearDown;
begin
  FB.Free;
  FA.Free;
  FSingle.Free;
  FNet.Free;
end;

procedure TTestNetTicPlanner.TestHowManyTicsToRun(ARealTics, AGameTic, AExpected: Integer);
begin
  FSingle.Clock.Tics := 5;
  FSingle.Sync.NetUpdate;
  Assert.AreEqual(5, FSingle.Planner.LowTic);
  FSingle.Game.CurrentGameTic := AGameTic;
  Assert.AreEqual(AExpected, FSingle.Planner.PlanTics(ARealTics));
end;

procedure TTestNetTicPlanner.TestBeginRunGivesTheRealTicsFromTheLastPass;
begin
  FSingle.Clock.Tics := 3;
  Assert.AreEqual(3, FSingle.Planner.BeginRun, 'dalla partenza');
  FSingle.Clock.Tics := 4;
  Assert.AreEqual(1, FSingle.Planner.BeginRun);
  Assert.AreEqual(0, FSingle.Planner.BeginRun, 'nessun tic dal giro precedente');
  FSingle.Clock.Tics := 10;
  Assert.AreEqual(6, FSingle.Planner.BeginRun);
end;

procedure TTestNetTicPlanner.TestEnterTimeIsTheTimeOfTheBeginningOfThePass;
begin
  FSingle.Clock.Tics := 7;
  FSingle.Planner.BeginRun;
  FSingle.Clock.Tics := 9;
  Assert.AreEqual(7, FSingle.Planner.EnterTime);
end;

procedure TTestNetTicPlanner.TestTicDupDividesTheRealTics;
var
  LRig: TNodeRig;
begin
  LRig := TNodeRig.Create(nil, 0, [], 0, 2, 0);
  try
    LRig.Clock.Tics := 9;
    Assert.AreEqual(4, LRig.Planner.BeginRun, '9 div 2');
  finally
    LRig.Free;
  end;
end;

procedure TTestNetTicPlanner.TestMustYieldAfterTenTics;
begin
  FSingle.Clock.Tics := 5;
  FSingle.Planner.BeginRun;
  FSingle.Clock.Tics := 14;
  Assert.IsFalse(FSingle.Planner.MustYield, 'nove tic');
  FSingle.Clock.Tics := 15;
  Assert.IsTrue(FSingle.Planner.MustYield, 'dieci tic');
end;

procedure TTestNetTicPlanner.TestNeverYieldDuringADemo;
begin
  FSingle.Planner.BeginRun;
  FSingle.Clock.Tics := 100;
  FSingle.Game.DemoPlayback := True;
  Assert.IsFalse(FSingle.Planner.MustYield);
  FSingle.Game.DemoPlayback := False;
  FSingle.Game.DemoRecording := True;
  Assert.IsFalse(FSingle.Planner.MustYield);
  FSingle.Game.DemoRecording := False;
  Assert.IsTrue(FSingle.Planner.MustYield);
end;

procedure TTestNetTicPlanner.TestTicsAreReadyWhenEveryNodeHasThem;
begin
  FA.Clock.Tics := 1;
  FB.Clock.Tics := 1;
  FA.Sync.NetUpdate;
  Assert.AreEqual(0, FA.Planner.LowTic, 'B non ha ancora risposto');
  Assert.IsFalse(FA.Planner.TicsReady(1));
  FB.Sync.NetUpdate;
  FA.Sync.NetUpdate;
  Assert.AreEqual(1, FA.Planner.LowTic);
  Assert.IsTrue(FA.Planner.TicsReady(1));
  Assert.IsFalse(FA.Planner.TicsReady(2));
end;

procedure TTestNetTicPlanner.TestNodeBehindTheGameIsAnError;
begin
  FA.Game.CurrentGameTic := 3;
  Assert.WillRaise(
    procedure
    begin
      FA.Planner.TicsReady(1);
    end, ENetException);
end;

procedure TTestNetTicPlanner.TestGameTicAheadOfTheSlowestNodeIsAnError;
begin
  FA.Game.CurrentGameTic := 1;
  Assert.WillRaise(
    procedure
    begin
      FA.Planner.VerifyCanRunTic;
    end, ENetException);
  FA.Game.CurrentGameTic := 0;
  FA.Planner.VerifyCanRunTic;
end;

procedure TTestNetTicPlanner.TestLowTicIsTheLowestOfTheNodesInTheGame;
begin
  FA.Clock.Tics := 3;
  FA.Sync.NetUpdate;
  Assert.AreEqual(3, FA.Sync.NetTic(0));
  Assert.AreEqual(0, FA.Sync.NetTic(1));
  Assert.AreEqual(0, FA.Planner.LowTic);
  // B leaves: only A counts
  FB.Sync.QuitNetGame;
  FA.Sync.NetUpdate;
  Assert.AreEqual(3, FA.Planner.LowTic);
end;

procedure TTestNetTicPlanner.TestSlowComputerSkipsATicWhenItIsAlwaysAhead;
var
  LIndex: Integer;
begin
  // B is not the key player. A speaks once, then B goes on alone and stays ahead of A
  FA.Clock.Tics := 1;
  FB.Clock.Tics := 1;
  FA.Sync.NetUpdate;
  FB.Sync.NetUpdate;
  FB.Clock.Tics := 4;
  FB.Sync.NetUpdate;
  Assert.AreEqual(4, FB.Sync.MakeTic);
  Assert.AreEqual(4, FB.Sync.NetTic(0));
  Assert.AreEqual(1, FB.Sync.NetTic(1));

  for LIndex := 1 to 5 do
    FB.Planner.PlanTics(0);

  // the fifth call decided to skip one tic: the next new tic is not made
  FB.Clock.Tics := 5;
  FB.Sync.NetUpdate;
  Assert.AreEqual(4, FB.Sync.MakeTic, 'un tic saltato');
  FB.Clock.Tics := 6;
  FB.Sync.NetUpdate;
  Assert.AreEqual(5, FB.Sync.MakeTic, 'poi si riprende');
end;

procedure TTestNetTicPlanner.TestKeyPlayerDoesNotAdapt;
var
  LIndex: Integer;
begin
  FA.Clock.Tics := 1;
  FB.Clock.Tics := 1;
  FA.Sync.NetUpdate;
  FB.Sync.NetUpdate;
  FA.Sync.NetUpdate;
  FA.Clock.Tics := 4;
  FA.Sync.NetUpdate;
  for LIndex := 1 to 8 do
    FA.Planner.PlanTics(0);
  FA.Clock.Tics := 5;
  FA.Sync.NetUpdate;
  Assert.AreEqual(5, FA.Sync.MakeTic, 'il giocatore chiave non salta tic');
end;

procedure TTestNetTicPlanner.TestDemoPlaybackDoesNotAdapt;
var
  LIndex: Integer;
begin
  FA.Clock.Tics := 1;
  FB.Clock.Tics := 1;
  FA.Sync.NetUpdate;
  FB.Sync.NetUpdate;
  FB.Clock.Tics := 4;
  FB.Sync.NetUpdate;
  FB.Game.DemoPlayback := True;
  for LIndex := 1 to 8 do
    FB.Planner.PlanTics(0);
  FB.Game.DemoPlayback := False;
  FB.Clock.Tics := 5;
  FB.Sync.NetUpdate;
  Assert.AreEqual(5, FB.Sync.MakeTic);
end;

end.
