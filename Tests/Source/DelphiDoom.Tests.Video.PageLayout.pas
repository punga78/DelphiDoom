{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the choices of V_PageDrawer        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.PageLayout;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Video.PageLayout;

type
  [TestFixture]
  [Category('video')]
  TTestVideoPageLayout = class(TObject)
  public
    [Test]
    procedure DovrebbeRiconoscereUnaPatchPiuGrandeDi320x200;
    [Test]
    procedure DovrebbeNonRidurreUnaPatchChePassaNelloSchermo;
    [Test]
    procedure DovrebbeRidurreUnaPatchPiuGrandeDelloSchermo;
    [Test]
    procedure DovrebbeNonStirareLeParine426x200;
    [Test]
    procedure DovrebbeRiprodurreLeCondizioniDelVecchioCodice;
  end;

implementation

procedure TTestVideoPageLayout.DovrebbeRiconoscereUnaPatchPiuGrandeDi320x200;
begin
  Assert.IsFalse(TVideoPageLayout.IsOversized(320, 200));
  Assert.IsTrue(TVideoPageLayout.IsOversized(321, 200));
  Assert.IsTrue(TVideoPageLayout.IsOversized(320, 201));
end;

procedure TTestVideoPageLayout.DovrebbeNonRidurreUnaPatchChePassaNelloSchermo;
begin
  Assert.IsFalse(TVideoPageLayout.NeedsDownscale(640, 400, 640, 400));
end;

procedure TTestVideoPageLayout.DovrebbeRidurreUnaPatchPiuGrandeDelloSchermo;
begin
  Assert.IsTrue(TVideoPageLayout.NeedsDownscale(641, 400, 640, 400));
  Assert.IsTrue(TVideoPageLayout.NeedsDownscale(640, 401, 640, 400));
end;

procedure TTestVideoPageLayout.DovrebbeNonStirareLeParine426x200;
begin
  Assert.IsFalse(TVideoPageLayout.NeedsStretch(426, 200));
  Assert.IsTrue(TVideoPageLayout.NeedsStretch(320, 200));
  Assert.IsTrue(TVideoPageLayout.NeedsStretch(426, 201));
end;

procedure TTestVideoPageLayout.DovrebbeRiprodurreLeCondizioniDelVecchioCodice;
const
  CValues: array[0..6] of Integer = (1, 199, 200, 201, 320, 426, 1000);
var
  LW, LH, LSW, LSH: Integer;
begin
  for LW in CValues do
    for LH in CValues do
    begin
      // the conditions of the old text of V_PageDrawer: bigpatch, the scale and the stretch
      Assert.AreEqual((LW > 320) or (LH > 200), TVideoPageLayout.IsOversized(LW, LH));
      Assert.AreEqual((LW <> 426) or (LH <> 200), TVideoPageLayout.NeedsStretch(LW, LH));
      for LSW in CValues do
        for LSH in CValues do
          Assert.AreEqual((LW > LSW) or (LH > LSH), TVideoPageLayout.NeedsDownscale(LW, LH, LSW, LSH));
    end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoPageLayout);

end.
