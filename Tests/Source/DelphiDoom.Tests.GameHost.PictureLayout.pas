{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TGameHostPictureLayout                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameHost.PictureLayout;

interface

uses
  System.Types, DUnitX.TestFramework, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.PictureLayout;

type
  [TestFixture]
  [Category('GameHost')]
  TTestGameHostPictureLayout = class
  strict private
    function State(AWidth, AHeight, AClientWidth, AClientHeight: Integer; AFullscreen: Boolean): TGameHostWindowState;
  public
    [Test]
    procedure InFinestraNonDovrebbeEsserciUnRettangoloDellImmagine;
    [Test]
    procedure InFinestraLUscitaDovrebbeEssereIlModoDallAngolo;
    [Test]
    procedure ASchermoInteroDovrebbeMettereLeBandeAiLati;
    [Test]
    procedure ASchermoInteroDovrebbeMettereLeBandeSopraESotto;
    [Test]
    procedure ASchermoInteroSenzaAreaClientNonDovrebbeDareIlRettangolo;
    [Test]
    [TestCase('centro', '960,540,320,200')]
    [TestCase('angolo dell''immagine', '96,0,0,0')]
    [TestCase('nella banda di sinistra', '0,0,-36,0')]
    [TestCase('angolo opposto', '1824,1080,640,400')]
    procedure ASchermoInteroIlPuntoDovrebbeTornareNellImmagine(AX, AY, AExpectedX, AExpectedY: Integer);
    [Test]
    procedure InFinestraIlPuntoDovrebbeRestareComE;
  end;

implementation

function TTestGameHostPictureLayout.State(AWidth, AHeight, AClientWidth, AClientHeight: Integer;
  AFullscreen: Boolean): TGameHostWindowState;
begin
  Result := Default(TGameHostWindowState);
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.ClientWidth := AClientWidth;
  Result.ClientHeight := AClientHeight;
  Result.Fullscreen := AFullscreen;
end;

procedure TTestGameHostPictureLayout.InFinestraNonDovrebbeEsserciUnRettangoloDellImmagine;
var
  LRect: TRect;
begin
  Assert.IsFalse(TGameHostPictureLayout.PictureRect(State(640, 400, 640, 400, False), LRect));
end;

procedure TTestGameHostPictureLayout.InFinestraLUscitaDovrebbeEssereIlModoDallAngolo;
var
  LRect: TRect;
begin
  // the client area can be larger for a moment (the player drags the border): the picture is the mode
  LRect := TGameHostPictureLayout.OutputRect(State(640, 400, 700, 500, False));
  Assert.AreEqual(0, LRect.Left);
  Assert.AreEqual(0, LRect.Top);
  Assert.AreEqual(640, LRect.Right);
  Assert.AreEqual(400, LRect.Bottom);
end;

procedure TTestGameHostPictureLayout.ASchermoInteroDovrebbeMettereLeBandeAiLati;
var
  LRect: TRect;
begin
  // 16:10 on a monitor of 16:9
  Assert.IsTrue(TGameHostPictureLayout.PictureRect(State(640, 400, 1920, 1080, True), LRect));
  Assert.AreEqual(96, LRect.Left);
  Assert.AreEqual(0, LRect.Top);
  Assert.AreEqual(1824, LRect.Right);
  Assert.AreEqual(1080, LRect.Bottom);
  Assert.IsTrue(TGameHostPictureLayout.OutputRect(State(640, 400, 1920, 1080, True)) = LRect);
end;

procedure TTestGameHostPictureLayout.ASchermoInteroDovrebbeMettereLeBandeSopraESotto;
var
  LRect: TRect;
begin
  // 16:9 on a monitor of 4:3
  Assert.IsTrue(TGameHostPictureLayout.PictureRect(State(1280, 720, 1024, 768, True), LRect));
  Assert.AreEqual(0, LRect.Left);
  Assert.AreEqual(96, LRect.Top);
  Assert.AreEqual(1024, LRect.Right);
  Assert.AreEqual(672, LRect.Bottom);
end;

procedure TTestGameHostPictureLayout.ASchermoInteroSenzaAreaClientNonDovrebbeDareIlRettangolo;
var
  LRect: TRect;
begin
  Assert.IsFalse(TGameHostPictureLayout.PictureRect(State(640, 400, 0, 0, True), LRect));
  Assert.IsFalse(TGameHostPictureLayout.PictureRect(State(0, 0, 1920, 1080, True), LRect));
end;

procedure TTestGameHostPictureLayout.ASchermoInteroIlPuntoDovrebbeTornareNellImmagine(AX, AY, AExpectedX,
  AExpectedY: Integer);
var
  LPoint: TPoint;
begin
  LPoint := TGameHostPictureLayout.ToPicture(State(640, 400, 1920, 1080, True), AX, AY);
  Assert.AreEqual(AExpectedX, LPoint.X);
  Assert.AreEqual(AExpectedY, LPoint.Y);
end;

procedure TTestGameHostPictureLayout.InFinestraIlPuntoDovrebbeRestareComE;
var
  LPoint: TPoint;
begin
  LPoint := TGameHostPictureLayout.ToPicture(State(640, 400, 640, 400, False), 123, -4);
  Assert.AreEqual(123, LPoint.X);
  Assert.AreEqual(-4, LPoint.Y);
end;

end.
