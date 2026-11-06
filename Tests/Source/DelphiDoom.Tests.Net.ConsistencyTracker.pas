{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the net library - the consistency check                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.ConsistencyTracker;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Net.Types, DelphiDoom.Net.Intf,
  DelphiDoom.Net.ConsistencyTracker;

type
  [TestFixture]
  [Category('net')]
  TTestNetConsistencyTracker = class(TObject)
  public
    [Test]
    procedure TestNothingIsCheckedInTheFirstTics;
    [Test]
    procedure TestSameValueIsFine;
    [Test]
    procedure TestDifferentValueIsAFailure;
    [Test]
    procedure TestFailureMessageIsTheOldOne;
    [Test]
    procedure TestExpectedIsTheValueStoredForTheTic;
    [Test]
    procedure TestOnlyTheLowSixteenBitsAreKept;
    [Test]
    procedure TestSlotFollowsTheTicDup;
    [Test]
    procedure TestPlayersAreIndependent;
    [Test]
    procedure TestPlayerOutOfRangeRaises;
    [Test]
    procedure TestBadParametersRaise;
  end;

implementation

{ TTestNetConsistencyTracker }

procedure TTestNetConsistencyTracker.TestNothingIsCheckedInTheFirstTics;
var
  LTracker: INetConsistency;
begin
  LTracker := TNetConsistencyTracker.Create(4, 1);
  // gametic is not above BACKUPTICS yet: a wrong value is not a failure
  LTracker.Verify(0, 12, 1234, 77);
  LTracker.Verify(0, 12, -5, 78);
  Assert.AreEqual(SmallInt(78), LTracker.Expected(0, 12));
end;

procedure TTestNetConsistencyTracker.TestSameValueIsFine;
var
  LTracker: INetConsistency;
begin
  LTracker := TNetConsistencyTracker.Create(4, 1);
  LTracker.Verify(1, 20, 0, 4321);
  // twelve tics later the same slot comes back
  LTracker.Verify(1, 32, 4321, 999);
  Assert.AreEqual(SmallInt(999), LTracker.Expected(1, 32));
end;

procedure TTestNetConsistencyTracker.TestDifferentValueIsAFailure;
var
  LTracker: INetConsistency;
begin
  LTracker := TNetConsistencyTracker.Create(4, 1);
  LTracker.Verify(1, 20, 0, 4321);
  Assert.WillRaise(
    procedure
    begin
      LTracker.Verify(1, 32, 4322, 0);
    end, ENetConsistencyException);
end;

procedure TTestNetConsistencyTracker.TestFailureMessageIsTheOldOne;
var
  LTracker: INetConsistency;
  LMessage: string;
begin
  LTracker := TNetConsistencyTracker.Create(4, 1);
  LTracker.Verify(0, 20, 0, 100);
  try
    LTracker.Verify(0, 32, 7, 0);
    Assert.Fail('doveva fallire');
  except
    on E: ENetConsistencyException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('G_Ticker(): consistency failure (7 should be 100)', LMessage);
end;

procedure TTestNetConsistencyTracker.TestExpectedIsTheValueStoredForTheTic;
var
  LTracker: INetConsistency;
begin
  LTracker := TNetConsistencyTracker.Create(4, 1);
  LTracker.Verify(2, 5, 0, 50);
  LTracker.Verify(2, 6, 0, 60);
  Assert.AreEqual(SmallInt(50), LTracker.Expected(2, 5));
  Assert.AreEqual(SmallInt(60), LTracker.Expected(2, 6));
  Assert.AreEqual(SmallInt(50), LTracker.Expected(2, 17), 'maketic mod BACKUPTICS');
  Assert.AreEqual(SmallInt(0), LTracker.Expected(2, 7));
end;

procedure TTestNetConsistencyTracker.TestOnlyTheLowSixteenBitsAreKept;
var
  LTracker: INetConsistency;
begin
  LTracker := TNetConsistencyTracker.Create(4, 1);
  // the x of a mobj is 32 bit fixed point; the slot is a smallint
  LTracker.Verify(0, 1, 0, $12348765);
  Assert.AreEqual(SmallInt($8765 - $10000), LTracker.Expected(0, 1));
  LTracker.Verify(0, 13, SmallInt($8765 - $10000), -1);
  Assert.AreEqual(SmallInt(-1), LTracker.Expected(0, 1));
end;

procedure TTestNetConsistencyTracker.TestSlotFollowsTheTicDup;
var
  LTracker: INetConsistency;
begin
  LTracker := TNetConsistencyTracker.Create(4, 2);
  LTracker.Verify(0, 14, 0, 70);
  // game tic 14 with ticdup 2 is the tic 7 of the net
  Assert.AreEqual(SmallInt(70), LTracker.Expected(0, 7));
end;

procedure TTestNetConsistencyTracker.TestPlayersAreIndependent;
var
  LTracker: INetConsistency;
begin
  LTracker := TNetConsistencyTracker.Create(4, 1);
  LTracker.Verify(0, 3, 0, 30);
  Assert.AreEqual(SmallInt(0), LTracker.Expected(1, 3));
end;

procedure TTestNetConsistencyTracker.TestPlayerOutOfRangeRaises;
var
  LTracker: INetConsistency;
begin
  LTracker := TNetConsistencyTracker.Create(4, 1);
  Assert.WillRaise(
    procedure
    begin
      LTracker.Expected(4, 0);
    end, ENetException);
  Assert.WillRaise(
    procedure
    begin
      LTracker.Verify(-1, 0, 0, 0);
    end, ENetException);
end;

procedure TTestNetConsistencyTracker.TestBadParametersRaise;
begin
  Assert.WillRaise(
    procedure
    begin
      TNetConsistencyTracker.Create(0, 1);
    end, ENetException);
  Assert.WillRaise(
    procedure
    begin
      TNetConsistencyTracker.Create(4, 0);
    end, ENetException);
end;

end.
