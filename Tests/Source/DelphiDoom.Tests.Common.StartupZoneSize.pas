{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the minimum size of the zone memory              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Common.StartupZoneSize;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Engine.Startup.ZoneSize;

type
  [TestFixture]
  [Category('startup')]
  TTestStartupZoneSize = class(TObject)
  public
    [Test]
    procedure DovrebbeSommareLaBaseEiMegabyteDeiBuffer;
    [Test]
    procedure DovrebbeTroncareIMegabyteParziali;
    [Test]
    procedure DovrebbeUsareLaBaseDiHexenPiuAlta;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceSuiBufferDiOgniRisoluzione;
  end;

implementation

procedure TTestStartupZoneSize.DovrebbeSommareLaBaseEiMegabyteDeiBuffer;
begin
  Assert.AreEqual(6 + 5, TStartupZoneSize.MinimumMegabytes(TStartupZoneSize.DefaultBaseMegabytes, 5 * 1024 * 1024));
end;

procedure TTestStartupZoneSize.DovrebbeTroncareIMegabyteParziali;
begin
  Assert.AreEqual(6, TStartupZoneSize.MinimumMegabytes(TStartupZoneSize.DefaultBaseMegabytes, 1024 * 1024 - 1));
  Assert.AreEqual(7, TStartupZoneSize.MinimumMegabytes(TStartupZoneSize.DefaultBaseMegabytes, 1024 * 1024));
end;

procedure TTestStartupZoneSize.DovrebbeUsareLaBaseDiHexenPiuAlta;
begin
  Assert.AreEqual(8, TStartupZoneSize.HexenBaseMegabytes);
  Assert.AreEqual(8 + 2, TStartupZoneSize.MinimumMegabytes(TStartupZoneSize.HexenBaseMegabytes, 2 * 1024 * 1024));
end;

procedure TTestStartupZoneSize.DovrebbeEssereUgualeAlVecchioCodiceSuiBufferDiOgniRisoluzione;
var
  LBytes: Integer;
begin
  // old text: mb_min := 6 + V_ScreensSize(SCN_FG) div (1024 * 1024) (8 for Hexen)
  LBytes := 0;
  while LBytes < 200 * 1024 * 1024 do
  begin
    Assert.AreEqual(6 + LBytes div (1024 * 1024), TStartupZoneSize.MinimumMegabytes(6, LBytes));
    Assert.AreEqual(8 + LBytes div (1024 * 1024), TStartupZoneSize.MinimumMegabytes(8, LBytes));
    Inc(LBytes, 777777);
  end;
end;

end.