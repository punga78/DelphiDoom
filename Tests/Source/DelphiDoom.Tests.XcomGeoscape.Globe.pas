{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom geoscape library - Globe                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.Globe;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomGeoscape.Globe;

type
  [TestFixture]
  [Category('XcomGeoscape')]
  TTestXcomGlobe = class
  public
    [Test]
    procedure DovrebbeDareLaSequenzaDiRandDelRuntimeDiWindows;
    [Test]
    procedure DovrebbeTenereIlRandNelleSuePrimeQuattroCifreInPartenza;
  end;

implementation

procedure TTestXcomGlobe.DovrebbeDareLaSequenzaDiRandDelRuntimeDiWindows;
var
  LRandom: TXcomCRandom;
begin
  // the first values of rand() of msvcrt after no srand
  LRandom := TXcomCRandom.Create(1);
  Assert.AreEqual(41, LRandom.Next);
  Assert.AreEqual(18467, LRandom.Next);
  Assert.AreEqual(6334, LRandom.Next);
  Assert.AreEqual(26500, LRandom.Next);
  Assert.AreEqual(19169, LRandom.Next);
end;

procedure TTestXcomGlobe.DovrebbeTenereIlRandNelleSuePrimeQuattroCifreInPartenza;
var
  LRandom: TXcomCRandom;
  LIndex: Integer;
begin
  LRandom := TXcomCRandom.Create(1);
  for LIndex := 1 to 1000 do
    Assert.IsTrue((LRandom.Next >= 0) and (LRandom.Next <= $7FFF));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomGlobe);

end.
