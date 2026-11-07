{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the UDMF library - the namespaces of a text map        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Udmf.Namespaces;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Udmf.Namespaces;

type
  [TestFixture]
  [Category('udmf')]
  TTestUdmfNamespaces = class(TObject)
  public
    [Test]
    [TestCase('Doom', 'DOOM,Doom')]
    [TestCase('Heretic', 'HERETIC,Heretic')]
    [TestCase('Hexen', 'HEXEN,Hexen')]
    [TestCase('Strife', 'STRIFE,Strife')]
    procedure TestIlNamespaceDelGiocoNonDovrebbeTradurreLeLinee(const ANamespace, AGame: string);
    [Test]
    [TestCase('Doom', 'Doom')]
    [TestCase('Hexen', 'Hexen')]
    procedure TestZdoomTranslatedNonDovrebbeTradurreLeLinee(const AGame: string);
    [Test]
    [TestCase('ZdoomInDoom', 'ZDOOM,Doom')]
    [TestCase('HexenInDoom', 'HEXEN,Doom')]
    [TestCase('DoomInStrife', 'DOOM,Strife')]
    [TestCase('Vuoto', ',Heretic')]
    procedure TestUnAltroNamespaceDovrebbeTradurreLeLinee(const ANamespace, AGame: string);
    [Test]
    procedure TestUnNamespaceInMinuscoloNonDovrebbeEssereQuelloDelGioco;
  end;

implementation

{ TTestUdmfNamespaces }

procedure TTestUdmfNamespaces.TestIlNamespaceDelGiocoNonDovrebbeTradurreLeLinee(const ANamespace,
  AGame: string);
begin
  Assert.IsFalse(TUdmfNamespaces.TranslatesLines(ANamespace, AGame));
end;

procedure TTestUdmfNamespaces.TestZdoomTranslatedNonDovrebbeTradurreLeLinee(const AGame: string);
begin
  Assert.IsFalse(TUdmfNamespaces.TranslatesLines('ZDOOMTRANSLATED', AGame));
end;

procedure TTestUdmfNamespaces.TestUnAltroNamespaceDovrebbeTradurreLeLinee(const ANamespace, AGame: string);
begin
  Assert.IsTrue(TUdmfNamespaces.TranslatesLines(ANamespace, AGame));
end;

procedure TTestUdmfNamespaces.TestUnNamespaceInMinuscoloNonDovrebbeEssereQuelloDelGioco;
begin
  // il convertitore e il lump NSPACE danno il namespace in maiuscolo: il confronto non lo cambia
  Assert.IsTrue(TUdmfNamespaces.TranslatesLines('doom', 'Doom'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUdmfNamespaces);

end.
