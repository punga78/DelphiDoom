{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the palette of I3D models      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.I3dPalette;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>The fixed palette of 256 colors: its three ways to give a color</summary>
  [TestFixture]
  [Category('models')]
  TTestModelsI3dPalette = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlColoreInFrazioniDalCentroDelPasso;
    [Test]
    procedure DovrebbeDareIlColoreCome00BBGGRR;
    [Test]
    procedure DovrebbeTrovareLIndiceDiUnColoreEsatto;
    [Test]
    procedure DovrebbeDareIlPrimoIndiceSeNessunoCoincide;
  end;

implementation

uses
  DelphiDoom.Models.I3d.Types, DelphiDoom.Models.I3d.Palette;

{ TTestModelsI3dPalette }

procedure TTestModelsI3dPalette.DovrebbeDareIlColoreInFrazioniDalCentroDelPasso;
var
  LColor: TI3dColor3f;
begin
  // the index 1 is (0, 63, 0) in 6 bits
  LColor := TI3dPalette.Color3f(1);
  Assert.AreEqual(Single(0.5 / 64), LColor.R);
  Assert.AreEqual(Single(63.5 / 64), LColor.G);
  Assert.AreEqual(Single(0.5 / 64), LColor.B);
  // the last index is (63, 16, 63)
  LColor := TI3dPalette.Color3f(255);
  Assert.AreEqual(Single(63.5 / 64), LColor.R);
  Assert.AreEqual(Single(16.5 / 64), LColor.G);
  Assert.AreEqual(Single(63.5 / 64), LColor.B);
end;

procedure TTestModelsI3dPalette.DovrebbeDareIlColoreCome00BBGGRR;
begin
  Assert.AreEqual(Cardinal($00020202), TI3dPalette.ColorLong(0));
  Assert.AreEqual(Cardinal($0002FE02), TI3dPalette.ColorLong(1));
  Assert.AreEqual(Cardinal($00FE42FE), TI3dPalette.ColorLong(255));
end;

procedure TTestModelsI3dPalette.DovrebbeTrovareLIndiceDiUnColoreEsatto;
begin
  // the channels are compared with the 6 bit values of the palette as they are (a defect that is kept)
  Assert.AreEqual(255, TI3dPalette.IndexOf($003F103F));
  Assert.AreEqual(0, TI3dPalette.IndexOf($00000000));
end;

procedure TTestModelsI3dPalette.DovrebbeDareIlPrimoIndiceSeNessunoCoincide;
begin
  Assert.AreEqual(0, TI3dPalette.IndexOf($00000001));
end;

end.
