{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TScreenshotFormats                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.Formats;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Screenshot.Types,
  DelphiDoom.Screenshot.Formats;

type
  [TestFixture]
  [Category('screenshot')]
  TTestScreenshotFormats = class(TObject)
  public
    [Test]
    procedure DovrebbeRiconoscereITreNomi;
    [Test]
    procedure DovrebbeRifiutareUnNomeSconosciuto;
    [Test]
    procedure DovrebbeNonDistinguereLeMinuscoleNelNome;
    [Test]
    procedure DovrebbeDareEstensioneECartellaDiOgniFormato;
  end;

implementation

procedure TTestScreenshotFormats.DovrebbeRiconoscereITreNomi;
var
  LFormat: TScreenshotFormat;
begin
  Assert.IsTrue(TScreenshotFormats.TryParse('TGA', LFormat));
  Assert.AreEqual(Ord(TScreenshotFormat.Tga), Ord(LFormat));
  Assert.IsTrue(TScreenshotFormats.TryParse('PNG', LFormat));
  Assert.AreEqual(Ord(TScreenshotFormat.Png), Ord(LFormat));
  Assert.IsTrue(TScreenshotFormats.TryParse('JPG', LFormat));
  Assert.AreEqual(Ord(TScreenshotFormat.Jpg), Ord(LFormat));
end;

procedure TTestScreenshotFormats.DovrebbeRifiutareUnNomeSconosciuto;
var
  LFormat: TScreenshotFormat;
begin
  Assert.IsFalse(TScreenshotFormats.TryParse('BMP', LFormat));
  Assert.IsFalse(TScreenshotFormats.TryParse('', LFormat));
  Assert.AreEqual(Ord(TScreenshotFormat.Png), Ord(LFormat));
end;

procedure TTestScreenshotFormats.DovrebbeNonDistinguereLeMinuscoleNelNome;
var
  LFormat: TScreenshotFormat;
begin
  // the engine puts the name in upper case (M_FixScreenshotFormat) before it asks
  Assert.IsFalse(TScreenshotFormats.TryParse('png', LFormat));
end;

procedure TTestScreenshotFormats.DovrebbeDareEstensioneECartellaDiOgniFormato;
begin
  Assert.AreEqual('.tga', TScreenshotFormats.ExtensionOf(TScreenshotFormat.Tga));
  Assert.AreEqual('.png', TScreenshotFormats.ExtensionOf(TScreenshotFormat.Png));
  Assert.AreEqual('.jpg', TScreenshotFormats.ExtensionOf(TScreenshotFormat.Jpg));
  Assert.AreEqual('DATA\SCREENSHOTS\TGA', TScreenshotFormats.FolderOf(TScreenshotFormat.Tga));
  Assert.AreEqual('DATA\SCREENSHOTS\JPG', TScreenshotFormats.FolderOf(TScreenshotFormat.Jpg));
  Assert.AreEqual('DATA\SCREENSHOTS', TScreenshotFormats.RootFolder);
  Assert.AreEqual('PNG', TScreenshotFormats.NameOf(TScreenshotFormat.Png));
end;

end.
