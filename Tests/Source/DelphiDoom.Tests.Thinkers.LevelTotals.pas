{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the totals of a level                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LevelTotals;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Thinkers.LevelTotals;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLevelTotals = class
  strict private
    FTotals: TLevelTotals;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePartireDaZero;
    [Test]
    procedure DovrebbeContareOgniTotaleSeparatamente;
    [Test]
    procedure DovrebbeAzzerareTuttoConClear;
  end;

implementation

{ TTestThinkersLevelTotals }

procedure TTestThinkersLevelTotals.Setup;
begin
  FTotals := TLevelTotals.Create;
end;

procedure TTestThinkersLevelTotals.TearDown;
begin
  FTotals.Free;
end;

procedure TTestThinkersLevelTotals.DovrebbePartireDaZero;
begin
  Assert.AreEqual(0, FTotals.Kills);
  Assert.AreEqual(0, FTotals.Items);
  Assert.AreEqual(0, FTotals.Secrets);
end;

procedure TTestThinkersLevelTotals.DovrebbeContareOgniTotaleSeparatamente;
begin
  FTotals.CountKill;
  FTotals.CountKill;
  FTotals.CountItem;
  FTotals.CountSecret;
  FTotals.CountSecret;
  FTotals.CountSecret;
  Assert.AreEqual(2, FTotals.Kills);
  Assert.AreEqual(1, FTotals.Items);
  Assert.AreEqual(3, FTotals.Secrets);
end;

procedure TTestThinkersLevelTotals.DovrebbeAzzerareTuttoConClear;
begin
  FTotals.CountKill;
  FTotals.CountItem;
  FTotals.CountSecret;
  FTotals.Clear;
  Assert.AreEqual(0, FTotals.Kills);
  Assert.AreEqual(0, FTotals.Items);
  Assert.AreEqual(0, FTotals.Secrets);
end;

end.
