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
  ///   Runs Tests\Data\Gui\draw\draw.input.txt with TGuiDrawContext and compares what it sends to the renderer, the
  ///   results of the text calls and the warnings with draw.golden.txt: the answer of the real
  ///   ui\DeviceContext.cpp of Doom 3 (and of RegisterFont of renderer\tr_font.cpp), made by Tools\Verifica\111
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

initialization
  TDUnitX.RegisterTestFixture(TTestGuiDrawParity);

end.
