{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the frame counter       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.FpsCounter;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.FpsCounter;

type
  [TestFixture]
  [Category('hud')]
  TTestHudFpsCounter = class(TObject)
  private
    FCounter: THudFpsCounter;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareParametriNonValidi;
    [Test]
    procedure DovrebbeDareIlTicRateSeNonCeAbbastanzaStoria;
    [Test]
    procedure DovrebbeDareIlTicRatePrimaDelPrimoFotogramma;
    [Test]
    procedure DovrebbeCalcolareIFotogrammiAlSecondo;
    [Test]
    procedure DovrebbeUsareLaStoriaLungaSeSuperaIlLimiteDiTrentamilaCento;
    [Test]
    procedure DovrebbeScrivereIlTestoOgniMezzoSecondo;
    [Test]
    procedure DovrebbeSvuotareLaStoriaSenzaPerdereLaPosizione;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.Types;

{ TTestHudFpsCounter }

procedure TTestHudFpsCounter.Setup;
begin
  FCounter := THudFpsCounter.Create(35, 512);
end;

procedure TTestHudFpsCounter.TearDown;
begin
  FCounter.Free;
end;

procedure TTestHudFpsCounter.DovrebbeRifiutareParametriNonValidi;
begin
  Assert.WillRaise(
    procedure
    begin
      THudFpsCounter.Create(0, 512);
    end,
    EHudException);
  Assert.WillRaise(
    procedure
    begin
      THudFpsCounter.Create(35, 64);
    end,
    EHudException);
end;

procedure TTestHudFpsCounter.DovrebbeDareIlTicRateSeNonCeAbbastanzaStoria;
var
  LIndex: Integer;
begin
  // a clock that goes back: the difference is not positive, the counter says the tic rate
  for LIndex := 0 to 127 do
    FCounter.AddFrame(1000 - LIndex);
  Assert.AreEqual(35, FCounter.FramesPerSecond);
end;

procedure TTestHudFpsCounter.DovrebbeDareIlTicRatePrimaDelPrimoFotogramma;
begin
  // regression: the old code read before the start of its array and showed a number made of
  // whatever came before it in memory
  Assert.AreEqual(35, FCounter.FramesPerSecond);
  FCounter.Tick;
  Assert.AreEqual('35 fps', FCounter.Text);
  FCounter.AddFrame(0);
  Assert.AreEqual(35 * 512 * HUD_FRACUNIT, FCounter.FramesPerSecond);
end;

procedure TTestHudFpsCounter.DovrebbeCalcolareIFotogrammiAlSecondo;
var
  LIndex: Integer;
begin
  // a frame every 2 tics: 127 steps of 2 * 65536 between the newest and the oldest of 128 times
  for LIndex := 0 to 127 do
    FCounter.AddFrame(LIndex * 2 * HUD_FRACUNIT);
  Assert.AreEqual(35 * 128 * HUD_FRACUNIT div (127 * 2 * HUD_FRACUNIT + 1), FCounter.FramesPerSecond);
end;

procedure TTestHudFpsCounter.DovrebbeUsareLaStoriaLungaSeSuperaIlLimiteDiTrentamilaCento;
var
  LIndex: Integer;
  LExpected: Integer;
begin
  // very fast frames: 100 per tic; the short history says more than 128, the long one is used
  for LIndex := 0 to 599 do
    FCounter.AddFrame(LIndex * (HUD_FRACUNIT div 100));
  LExpected := 35 * 512 * HUD_FRACUNIT div (511 * (HUD_FRACUNIT div 100) + 1);
  Assert.AreEqual(LExpected, FCounter.FramesPerSecond);
end;

procedure TTestHudFpsCounter.DovrebbeScrivereIlTestoOgniMezzoSecondo;
var
  LIndex: Integer;
begin
  Assert.AreEqual('', FCounter.Text);
  for LIndex := 0 to 199 do
    FCounter.AddFrame(LIndex * 3 * HUD_FRACUNIT);
  FCounter.Tick;
  Assert.AreEqual(IntToStr(FCounter.FramesPerSecond) + ' fps', FCounter.Text);
  // the text does not change until half a second (17 tics) passed
  for LIndex := 0 to 199 do
    FCounter.AddFrame(LIndex * 7 * HUD_FRACUNIT);
  for LIndex := 1 to 16 do
    FCounter.Tick;
  Assert.AreNotEqual(IntToStr(FCounter.FramesPerSecond) + ' fps', FCounter.Text);
  FCounter.Tick;
  Assert.AreEqual(IntToStr(FCounter.FramesPerSecond) + ' fps', FCounter.Text);
end;

procedure TTestHudFpsCounter.DovrebbeSvuotareLaStoriaSenzaPerdereLaPosizione;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 200 do
    FCounter.AddFrame(LIndex * 3 * HUD_FRACUNIT);
  FCounter.Clear;
  // everything is zero: 35 * 128 * 65536 div 1, then the long history says the same
  Assert.AreEqual(35 * 512 * HUD_FRACUNIT, FCounter.FramesPerSecond);
end;

end.
