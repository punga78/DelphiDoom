{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the clipping of the lines        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.LineClipper;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Automap.Types;

type
  [TestFixture]
  [Category('automap')]
  TTestAutomapLineClipper = class(TObject)
  private
    FWindow: TAutomapWindow;
    function MapLine(const AX1, AY1, AX2, AY2: Integer): TAutomapLine;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeLasciareUnaLineaInternaCosiCom;
    [Test]
    procedure DovrebbeScartareUnaLineaSopraLaFinestra;
    [Test]
    procedure DovrebbeScartareUnaLineaAllaDestraDellaFinestra;
    [Test]
    procedure DovrebbeTagliareUnaLineaCheEsceASinistra;
    [Test]
    procedure DovrebbeTagliareUnaLineaCheAttraversaTuttaLaFinestra;
    [Test]
    procedure DovrebbeScartareUnaLineaCheSfiorailAngoloDallEsterno;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Automap.LineClipper;

{ TTestAutomapLineClipper }

function TTestAutomapLineClipper.MapLine(const AX1, AY1, AX2, AY2: Integer): TAutomapLine;
begin
  Result.A.X := AX1 * FIXED_ONE;
  Result.A.Y := AY1 * FIXED_ONE;
  Result.B.X := AX2 * FIXED_ONE;
  Result.B.Y := AY2 * FIXED_ONE;
end;

procedure TTestAutomapLineClipper.Setup;
begin
  // a window of 100 x 100 pixels on a map of 100 x 100 units, one pixel for each unit
  FillChar(FWindow, SizeOf(FWindow), 0);
  FWindow.FrameWidth := 100;
  FWindow.FrameHeight := 100;
  FWindow.MapX2 := 100 * FIXED_ONE;
  FWindow.MapY2 := 100 * FIXED_ONE;
  FWindow.MapWidth := 100 * FIXED_ONE;
  FWindow.MapHeight := 100 * FIXED_ONE;
  FWindow.ScaleMapToFrame := FIXED_ONE;
  FWindow.ScaleFrameToMap := FIXED_ONE;
end;

procedure TTestAutomapLineClipper.DovrebbeLasciareUnaLineaInternaCosiCom;
var
  LFrame: TAutomapFrameLine;
begin
  Assert.IsTrue(TAutomapLineClipper.Clip(FWindow, MapLine(10, 10, 60, 40), LFrame));
  Assert.AreEqual(10, LFrame.A.X);
  Assert.AreEqual(90, LFrame.A.Y);
  Assert.AreEqual(60, LFrame.B.X);
  Assert.AreEqual(60, LFrame.B.Y);
end;

procedure TTestAutomapLineClipper.DovrebbeScartareUnaLineaSopraLaFinestra;
var
  LFrame: TAutomapFrameLine;
begin
  Assert.IsFalse(TAutomapLineClipper.Clip(FWindow, MapLine(10, 150, 60, 200), LFrame));
end;

procedure TTestAutomapLineClipper.DovrebbeScartareUnaLineaAllaDestraDellaFinestra;
var
  LFrame: TAutomapFrameLine;
begin
  Assert.IsFalse(TAutomapLineClipper.Clip(FWindow, MapLine(150, 10, 200, 60), LFrame));
end;

procedure TTestAutomapLineClipper.DovrebbeTagliareUnaLineaCheEsceASinistra;
var
  LFrame: TAutomapFrameLine;
begin
  Assert.IsTrue(TAutomapLineClipper.Clip(FWindow, MapLine(-50, 50, 50, 50), LFrame));
  Assert.AreEqual(0, LFrame.A.X);
  Assert.AreEqual(50, LFrame.A.Y);
  Assert.AreEqual(50, LFrame.B.X);
  Assert.AreEqual(50, LFrame.B.Y);
end;

procedure TTestAutomapLineClipper.DovrebbeTagliareUnaLineaCheAttraversaTuttaLaFinestra;
var
  LFrame: TAutomapFrameLine;
begin
  // from the left of the window to the right of it, along its middle
  Assert.IsTrue(TAutomapLineClipper.Clip(FWindow, MapLine(-50, 50, 150, 50), LFrame));
  Assert.AreEqual(0, LFrame.A.X);
  Assert.AreEqual(99, LFrame.B.X);
  Assert.AreEqual(50, LFrame.A.Y);
  Assert.AreEqual(50, LFrame.B.Y);
end;

procedure TTestAutomapLineClipper.DovrebbeScartareUnaLineaCheSfiorailAngoloDallEsterno;
var
  LFrame: TAutomapFrameLine;
begin
  // a diagonal that passes outside the top left corner of the window
  Assert.IsFalse(TAutomapLineClipper.Clip(FWindow, MapLine(-30, 90, 10, 130), LFrame));
end;

end.
