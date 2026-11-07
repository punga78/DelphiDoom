{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - from map to frame buffer         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.Transform;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Automap.Types;

type
  [TestFixture]
  [Category('automap')]
  TTestAutomapTransform = class(TObject)
  private
    FWindow: TAutomapWindow;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeConvertireUnaDistanzaDallaMappaAlFrameBuffer;
    [Test]
    procedure DovrebbeTroncareVersoZeroLeDistanzeNegative;
    [Test]
    procedure DovrebbeDimezzareConScalaMezza;
    [Test]
    procedure DovrebbeConvertireUnaDistanzaDalFrameBufferAllaMappa;
    [Test]
    procedure DovrebbeTenereContoDellOrigineInX;
    [Test]
    procedure DovrebbeRovesciareLaYEPartireDallAltezzaDelFrame;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Automap.Transform;

{ TTestAutomapTransform }

procedure TTestAutomapTransform.Setup;
begin
  FillChar(FWindow, SizeOf(FWindow), 0);
  FWindow.FrameX := 10;
  FWindow.FrameY := 20;
  FWindow.FrameWidth := 320;
  FWindow.FrameHeight := 168;
  FWindow.MapX := 100 * FIXED_ONE;
  FWindow.MapY := 200 * FIXED_ONE;
  FWindow.ScaleMapToFrame := FIXED_ONE;
  FWindow.ScaleFrameToMap := FIXED_ONE;
end;

procedure TTestAutomapTransform.DovrebbeConvertireUnaDistanzaDallaMappaAlFrameBuffer;
begin
  Assert.AreEqual(50, TAutomapTransform.MapToFrame(FWindow, 50 * FIXED_ONE));
  Assert.AreEqual(0, TAutomapTransform.MapToFrame(FWindow, 0));
end;

procedure TTestAutomapTransform.DovrebbeTroncareVersoZeroLeDistanzeNegative;
begin
  Assert.AreEqual(5, TAutomapTransform.MapToFrame(FWindow, 5 * FIXED_ONE + 32768));
  Assert.AreEqual(-5, TAutomapTransform.MapToFrame(FWindow, -5 * FIXED_ONE - 32768));
end;

procedure TTestAutomapTransform.DovrebbeDimezzareConScalaMezza;
begin
  FWindow.ScaleMapToFrame := FIXED_ONE div 2;
  Assert.AreEqual(25, TAutomapTransform.MapToFrame(FWindow, 50 * FIXED_ONE));
end;

procedure TTestAutomapTransform.DovrebbeConvertireUnaDistanzaDalFrameBufferAllaMappa;
begin
  FWindow.ScaleFrameToMap := 2 * FIXED_ONE;
  Assert.AreEqual(20 * FIXED_ONE, TAutomapTransform.FrameToMap(FWindow, 10));
  Assert.AreEqual(-20 * FIXED_ONE, TAutomapTransform.FrameToMap(FWindow, -10));
end;

procedure TTestAutomapTransform.DovrebbeTenereContoDellOrigineInX;
begin
  // FrameX + x - MapX, in pixels
  Assert.AreEqual(10 + 50, TAutomapTransform.MapToFrameX(FWindow, 150 * FIXED_ONE));
  Assert.AreEqual(10, TAutomapTransform.MapToFrameX(FWindow, 100 * FIXED_ONE));
end;

procedure TTestAutomapTransform.DovrebbeRovesciareLaYEPartireDallAltezzaDelFrame;
begin
  // FrameY + (FrameHeight - y + MapY), in pixels: the map goes up, the frame goes down
  Assert.AreEqual(20 + 168, TAutomapTransform.MapToFrameY(FWindow, 200 * FIXED_ONE));
  Assert.AreEqual(20 + 168 - 30, TAutomapTransform.MapToFrameY(FWindow, 230 * FIXED_ONE));
end;

end.
