{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - index of the hi resolution      }
{  light levels                                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.LightIndex;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   TRendererLightIndex: the column of zlightlevels of a span (issue #40)
  /// </summary>
  [TestFixture]
  [Category('renderer')]
  TTestRendererLightIndex = class(TObject)
  public
    [Test]
    procedure DovrebbeLasciareUnaColonnaValida;
    [Test]
    procedure DovrebbeLimitareUnaColonnaOltreLaFine;
    [Test]
    procedure DovrebbeDareLUltimaColonnaPerUnaDistanzaNegativa;
  end;

implementation

uses
  DelphiDoom.Renderer.LightIndex;

const
  COLUMNS = 8192;

//==============================================================================
//
// TTestRendererLightIndex.DovrebbeLasciareUnaColonnaValida
//
//==============================================================================
procedure TTestRendererLightIndex.DovrebbeLasciareUnaColonnaValida;
begin
  Assert.AreEqual<Integer>(0, TRendererLightIndex.Clamp(0, COLUMNS));
  Assert.AreEqual<Integer>(1234, TRendererLightIndex.Clamp(1234, COLUMNS));
  Assert.AreEqual<Integer>(COLUMNS - 1, TRendererLightIndex.Clamp(COLUMNS - 1, COLUMNS));
end;

//==============================================================================
//
// TTestRendererLightIndex.DovrebbeLimitareUnaColonnaOltreLaFine
//
//==============================================================================
procedure TTestRendererLightIndex.DovrebbeLimitareUnaColonnaOltreLaFine;
begin
  Assert.AreEqual<Integer>(COLUMNS - 1, TRendererLightIndex.Clamp(COLUMNS, COLUMNS));
  Assert.AreEqual<Integer>(COLUMNS - 1, TRendererLightIndex.Clamp(MaxInt, COLUMNS));
end;

//==============================================================================
//
// TTestRendererLightIndex.DovrebbeDareLUltimaColonnaPerUnaDistanzaNegativa
//
//==============================================================================
procedure TTestRendererLightIndex.DovrebbeDareLUltimaColonnaPerUnaDistanzaNegativa;
begin
  // the distance of the span of the tic 368 of the scenario "base" of Fp40: -1870538752 shr 14
  Assert.AreEqual<Integer>(COLUMNS - 1, TRendererLightIndex.Clamp(-114167, COLUMNS));
  Assert.AreEqual<Integer>(COLUMNS - 1, TRendererLightIndex.Clamp(-1, COLUMNS));
end;

end.
