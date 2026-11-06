{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - the sizes of flats   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.FlatSizes;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('texturedefs')]
  TTestTextureDefsFlatSizes = class(TObject)
  public
    [Test]
    [TestCase('64', '64,0')]
    [TestCase('128', '128,1')]
    [TestCase('256', '256,2')]
    [TestCase('512', '512,3')]
    [TestCase('1024', '1024,4')]
    [TestCase('2048', '2048,5')]
    [TestCase('4096', '4096,6')]
    procedure TestCodeFromSize(ASize, ACode: Integer);
    [Test]
    [TestCase('zero', '0')]
    [TestCase('negativo', '-128')]
    [TestCase('non una potenza', '100')]
    [TestCase('troppo grande', '8192')]
    procedure TestOtherSizesAreSixtyFour(ASize: Integer);
    [Test]
    [TestCase('64', '0,64')]
    [TestCase('128', '1,128')]
    [TestCase('4096', '6,4096')]
    [TestCase('inesistente', '9,64')]
    procedure TestSizeFromCode(ACode, ASize: Integer);
  end;

implementation

uses
  DelphiDoom.TextureDefs.FlatSizes;

{ TTestTextureDefsFlatSizes }

procedure TTestTextureDefsFlatSizes.TestCodeFromSize(ASize, ACode: Integer);
begin
  Assert.AreEqual(ACode, TTextureDefsFlatSizes.CodeFromSize(ASize), 'dovrebbe dare il codice');
end;

procedure TTestTextureDefsFlatSizes.TestOtherSizesAreSixtyFour(ASize: Integer);
begin
  Assert.AreEqual(0, TTextureDefsFlatSizes.CodeFromSize(ASize), 'dovrebbe dare 64x64');
end;

procedure TTestTextureDefsFlatSizes.TestSizeFromCode(ACode, ASize: Integer);
begin
  Assert.AreEqual(ASize, TTextureDefsFlatSizes.SizeFromCode(ACode), 'dovrebbe dare il lato');
end;

end.
