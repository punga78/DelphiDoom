{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the time of the level }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.LevelTime;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('hud')]
  TTestHudLevelTime = class(TObject)
  public
    [Test]
    procedure DovrebbeScrivereOreMinutiESecondi;
    [Test]
    procedure DovrebbeRiempireConGliZeri;
    [Test]
    procedure DovrebbeNonLimitareLeOre;
    [TestCase('zero', '0,35,Time: 00:00:00')]
    [TestCase('unSecondo', '35,35,Time: 00:00:01')]
    [TestCase('unMinuto', '2100,35,Time: 00:01:00')]
    [TestCase('unaOra', '126000,35,Time: 01:00:00')]
    [TestCase('mezzoSecondo', '34,35,Time: 00:00:00')]
    procedure DovrebbeSeguireIlTicRate(const ALevelTime, ATicRate: Integer; const AExpected: string);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.LevelTime;

{ TTestHudLevelTime }

procedure TTestHudLevelTime.DovrebbeScrivereOreMinutiESecondi;
begin
  Assert.AreEqual('Time: 01:02:03', THudLevelTime.Format((3600 + 120 + 3) * 35, 35));
end;

procedure TTestHudLevelTime.DovrebbeRiempireConGliZeri;
begin
  Assert.AreEqual('Time: 00:09:07', THudLevelTime.Format((9 * 60 + 7) * 35, 35));
end;

procedure TTestHudLevelTime.DovrebbeNonLimitareLeOre;
begin
  Assert.AreEqual('Time: 123:00:00', THudLevelTime.Format(123 * 3600 * 35, 35));
end;

procedure TTestHudLevelTime.DovrebbeSeguireIlTicRate(const ALevelTime, ATicRate: Integer;
  const AExpected: string);
begin
  Assert.AreEqual(AExpected, THudLevelTime.Format(ALevelTime, ATicRate));
end;


end.