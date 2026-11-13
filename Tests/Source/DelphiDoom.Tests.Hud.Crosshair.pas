{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the crosshair         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.Crosshair;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('hud')]
  TTestHudCrosshair = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlMirinoFermoSenzaBersaglioOConUnAmico;
    [Test]
    procedure DovrebbeFarGirareIlMirinoSuUnNemico;
    [Test]
    procedure DovrebbeSpostareIlMirinoConLoSguardo;
    [Test]
    procedure DovrebbeNonSpostareIlMirinoSeGuardaDritto;
  end;

implementation

uses
  DelphiDoom.Hud.Types, DelphiDoom.Hud.Crosshair;

{ TTestHudCrosshair }

procedure TTestHudCrosshair.DovrebbeDareIlMirinoFermoSenzaBersaglioOConUnAmico;
begin
  Assert.AreEqual(0, THudCrosshair.PatchIndex(THudCrosshairTarget.None, 1000, 10));
  Assert.AreEqual(0, THudCrosshair.PatchIndex(THudCrosshairTarget.Friend, 1000, 10));
end;

procedure TTestHudCrosshair.DovrebbeFarGirareIlMirinoSuUnNemico;
begin
  Assert.AreEqual(1, THudCrosshair.PatchIndex(THudCrosshairTarget.Enemy, 100, 100));
  Assert.AreEqual(1, THudCrosshair.PatchIndex(THudCrosshairTarget.Enemy, 107, 100));
  Assert.AreEqual(2, THudCrosshair.PatchIndex(THudCrosshairTarget.Enemy, 108, 100));
  Assert.AreEqual(4, THudCrosshair.PatchIndex(THudCrosshairTarget.Enemy, 124, 100));
  Assert.AreEqual(1, THudCrosshair.PatchIndex(THudCrosshairTarget.Enemy, 132, 100));
end;

procedure TTestHudCrosshair.DovrebbeSpostareIlMirinoConLoSguardo;
begin
  // looking up (below 128) the crosshair moves one way, looking down the other
  Assert.AreEqual(32, THudCrosshair.OffsetX(10, 128));
  Assert.AreEqual(40, THudCrosshair.OffsetX(10, 160));
  Assert.AreEqual(-40, THudCrosshair.OffsetX(245, 160));
  Assert.AreEqual(0, THudCrosshair.OffsetX(255, 160));
end;

procedure TTestHudCrosshair.DovrebbeNonSpostareIlMirinoSeGuardaDritto;
begin
  Assert.AreEqual(0, THudCrosshair.OffsetX(0, 320));
end;


end.