{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - parity with the C++ of Doom 3        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.WindowParity;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   Runs the scenarios of Tests\Data\Gui\window\window.input.txt with the classes of Libs\Gui and
  ///   compares the text with the answer of the real windows of Doom 3 (window.golden.txt, made by
  ///   the harness of Tools\Verifica\111 with the C++ of ui\Window.cpp, Winvar.h, RegExp.cpp, GuiScript.cpp...)
  /// </summary>
  [TestFixture]
  [Category('GuiWindow')]
  [Category('Parity')]
  TTestGuiWindowParity = class
  public
    [Test]
    procedure IScenariCoincidonoConIlCpp;
    [Test]
    procedure IlGoldenHaTuttiICasi;
  end;

implementation

uses
  DelphiDoom.Tests.Gui.Harness;

procedure TTestGuiWindowParity.IScenariCoincidonoConIlCpp;
begin
  TGuiHarnessCompare.Check('window\window.input.txt', 'window\window.golden.txt');
end;

procedure TTestGuiWindowParity.IlGoldenHaTuttiICasi;
begin
  Assert.AreEqual(13, TGuiHarnessCompare.CountCases('window\window.golden.txt'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiWindowParity);

end.
