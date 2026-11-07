{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the palette library - TTranslationBlood                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Palette.TranslationBlood;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('palette')]
  TTestPaletteTranslationBlood = class(TObject)
  public
    [Test]
    [TestCase('Numero', '3,3')]
    [TestCase('Nome', 'green,2')]
    [TestCase('ConCR_', 'CR_GREEN,2')]
    [TestCase('ConCR', 'CRGREEN,2')]
    [TestCase('Porpora', 'purple,6')]
    [TestCase('PorporaBreve', 'Purpl,6')]
    [TestCase('Maiuscole', 'Orange,8')]
    [TestCase('Rosso', 'red,0')]
    procedure DovrebbeRiconoscereNumeriENomi(const AName: string; AExpected: Integer);
    [Test]
    [TestCase('Sconosciuto', 'mauve')]
    [TestCase('FuoriTabella', '9')]
    [TestCase('Enorme', '99999999999')]
    [TestCase('Negativo', '-1')]
    [TestCase('Vuoto', '')]
    procedure DovrebbeDareZeroPerUnNomeCheNonEsiste(const AName: string);
    [Test]
    procedure DovrebbeDareIlNomeTranneCheAlRosso;
    [Test]
    procedure DovrebbeDareLaRegioneTranneCheAlRosso;
  end;

implementation

uses
  DelphiDoom.Palette.Types,
  DelphiDoom.Palette.TranslationBlood;

{ TTestPaletteTranslationBlood }

procedure TTestPaletteTranslationBlood.DovrebbeRiconoscereNumeriENomi(const AName: string;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TTranslationBlood.IdForName(AName));
end;

procedure TTestPaletteTranslationBlood.DovrebbeDareZeroPerUnNomeCheNonEsiste(const AName: string);
begin
  Assert.AreEqual(0, TTranslationBlood.IdForName(AName));
end;

procedure TTestPaletteTranslationBlood.DovrebbeDareIlNomeTranneCheAlRosso;
begin
  Assert.AreEqual('', TTranslationBlood.NameOf(0));
  Assert.AreEqual('GRAY', TTranslationBlood.NameOf(1));
  Assert.AreEqual('PURPL', TTranslationBlood.NameOf(6));
  Assert.AreEqual('ORANGE', TTranslationBlood.NameOf(8));
  Assert.AreEqual('', TTranslationBlood.NameOf(9));
  Assert.AreEqual('', TTranslationBlood.NameOf(-1));
end;

procedure TTestPaletteTranslationBlood.DovrebbeDareLaRegioneTranneCheAlRosso;
begin
  Assert.AreEqual(-1, TTranslationBlood.Region(0));
  Assert.AreEqual(REGION_GRAY, TTranslationBlood.Region(1));
  Assert.AreEqual(REGION_GREEN, TTranslationBlood.Region(2));
  Assert.AreEqual(REGION_BLUE2, TTranslationBlood.Region(3));
  Assert.AreEqual(REGION_YELLOW, TTranslationBlood.Region(4));
  Assert.AreEqual(REGION_BLACK, TTranslationBlood.Region(5));
  Assert.AreEqual(REGION_PURPL, TTranslationBlood.Region(6));
  Assert.AreEqual(REGION_WHITE, TTranslationBlood.Region(7));
  Assert.AreEqual(REGION_ORANGE, TTranslationBlood.Region(8));
  Assert.AreEqual(-1, TTranslationBlood.Region(9));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPaletteTranslationBlood);

end.
