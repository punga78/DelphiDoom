{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the device context against the C++   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.DrawParity;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   Runs Tests\Data\Gui\draw\*.input.txt with the classes of Libs\Gui and compares what they send to the renderer,
  ///   the results of the text calls and the warnings with the golden: the answer of the real ui\DeviceContext.cpp,
  ///   Window.cpp, SimpleWindow.cpp and UserInterface.cpp of Doom 3 (and of RegisterFont of renderer\tr_font.cpp),
  ///   made by Tools\Verifica\111
  /// </summary>
  [TestFixture]
  [Category('GuiDraw')]
  [Category('Parity')]
  TTestGuiDrawParity = class
  public
    [Test]
    procedure IScenariDelDeviceContextCoincidonoConIlCpp;
    [Test]
    procedure IlGoldenDelDeviceContextHaTuttiICasi;
    [Test]
    procedure IScenariDelDisegnoDelleFinestreCoincidonoConIlCpp;
    [Test]
    procedure IlGoldenDelDisegnoDelleFinestreHaTuttiICasi;
    [Test]
    procedure GliEventiDelleFinestreCoincidonoConIlCpp;
    [Test]
    procedure IlGoldenDegliEventiHaTuttiICasi;
    [Test]
    procedure IScenariDelDisegnoDelleFinestreAncoraCoincidonoConIlCpp;
  end;

implementation

uses
  DelphiDoom.Tests.Gui.Harness;

procedure TTestGuiDrawParity.IScenariDelDeviceContextCoincidonoConIlCpp;
begin
  TGuiHarnessCompare.Check('draw\draw.input.txt', 'draw\draw.golden.txt');
end;

procedure TTestGuiDrawParity.IlGoldenDelDeviceContextHaTuttiICasi;
begin
  Assert.AreEqual(11, TGuiHarnessCompare.CountCases('draw\draw.golden.txt'));
end;

procedure TTestGuiDrawParity.IScenariDelDisegnoDelleFinestreCoincidonoConIlCpp;
begin
  // the rotation of a window uses sinf and cosf: the C library of the compiler of the reference is one ULP off in places
  TGuiHarnessCompare.Check('draw\redraw.input.txt', 'draw\redraw.golden.txt', 'redraw_transform', 4);
end;

procedure TTestGuiDrawParity.IlGoldenDelDisegnoDelleFinestreHaTuttiICasi;
begin
  Assert.AreEqual(5, TGuiHarnessCompare.CountCases('draw\redraw.golden.txt'));
end;

procedure TTestGuiDrawParity.GliEventiDelleFinestreCoincidonoConIlCpp;
begin
  TGuiHarnessCompare.Check('draw\events.input.txt', 'draw\events.golden.txt');
end;

procedure TTestGuiDrawParity.IlGoldenDegliEventiHaTuttiICasi;
begin
  Assert.AreEqual(6, TGuiHarnessCompare.CountCases('draw\events.golden.txt'));
end;

procedure TTestGuiDrawParity.IScenariDelDisegnoDelleFinestreAncoraCoincidonoConIlCpp;
begin
  TGuiHarnessCompare.Check('draw\redraw2.input.txt', 'draw\redraw2.golden.txt', 'redraw_flags', 4);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiDrawParity);

end.
