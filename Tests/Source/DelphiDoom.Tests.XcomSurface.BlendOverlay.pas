{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the overlay of blended pixels (issue 183)          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.BlendOverlay;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.BlendOverlay;

type
  [TestFixture]
  [Category('XcomSurface')]
  TTestXcomBlendOverlay = class
  strict private
    FOverlay: TXcomBlendOverlay;
    FSurface: TXcomSurface;
    FSprite: TXcomSurface;
    FPalette: array[0..255] of TXcomColor;
    function Valid(AX, AY: Integer): Boolean;
    function ColorAt(AX, AY: Integer): Cardinal;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SenzaVelinoNonCiDovrebbeEssereNessunaSfumatura;
    [Test]
    procedure UnVelinoDovrebbeMescolareILColoriSottoEIlColoreDelloSprite;
    [Test]
    procedure UnVelinoOpacoDovrebbeEssereUnPienoDellaPaletta;
    [Test]
    procedure UnVelinoDovrebbeSaltareIPixelTrasparentiDelloSprite;
    [Test]
    procedure UnVelinoSuUnVelinoDovrebbeMescolareConLaSfumatura;
    [Test]
    procedure UnoSpriteSolidoDopoDovrebbeToglierelaSfumatura;
    [Test]
    procedure UnPixelScrittoDopoDovrebbeToglierelaSfumatura;
    [Test]
    procedure LaMezzaMetaDovrebbeCoprireSoloLaDestra;
    [Test]
    procedure UnaOmbraDovrebbeScurireLEllisse;
    [Test]
    procedure ClearDovrebbeDimenticareTutto;
    [Test]
    procedure UnaMisuraSbagliataDovrebbeSollevare;
  end;

implementation

procedure TTestXcomBlendOverlay.Setup;
var
  LIndex: Integer;
begin
  FOverlay := TXcomBlendOverlay.Create(32, 24);
  FSurface := TXcomSurface.Create(32, 24);
  FSprite := TXcomSurface.Create(4, 4);
  for LIndex := 0 to 255 do
  begin
    FPalette[LIndex].Red := Byte(LIndex);
    FPalette[LIndex].Green := Byte(255 - LIndex);
    FPalette[LIndex].Blue := 100;
    FPalette[LIndex].Alpha := 255;
  end;
  FOverlay.SetPalette(FPalette);
end;

procedure TTestXcomBlendOverlay.TearDown;
begin
  FSprite.Free;
  FSurface.Free;
  FOverlay.Free;
end;

function TTestXcomBlendOverlay.Valid(AX, AY: Integer): Boolean;
begin
  Result := FOverlay.Valid[AY * FOverlay.Width + AX] <> 0;
end;

function TTestXcomBlendOverlay.ColorAt(AX, AY: Integer): Cardinal;
begin
  Result := FOverlay.Colors[AY * FOverlay.Width + AX];
end;

procedure TTestXcomBlendOverlay.SenzaVelinoNonCiDovrebbeEssereNessunaSfumatura;
begin
  Assert.IsFalse(FOverlay.HasBlends);
  FOverlay.Cover(FSprite, 1, 1);
  FOverlay.CoverPixel(2, 2);
  Assert.IsFalse(FOverlay.HasBlends);
end;

procedure TTestXcomBlendOverlay.UnVelinoDovrebbeMescolareILColoriSottoEIlColoreDelloSprite;
begin
  FSurface.DrawRect(0, 0, 32, 24, 100);
  FSprite.DrawRect(0, 0, 4, 4, 200);
  FOverlay.BeginVeil(FSurface, 5, 6, 4, 4);
  // the picture of the game gets the sprite as a solid
  FSurface.DrawRect(5, 6, 4, 4, 200);
  FOverlay.EndVeil(FSurface, FSprite, 5, 6, 128, FOverlay.Everything);
  Assert.IsTrue(FOverlay.HasBlends);
  Assert.IsTrue(Valid(5, 6));
  Assert.IsTrue(Valid(8, 9));
  Assert.IsFalse(Valid(9, 6));
  Assert.IsFalse(Valid(4, 6));
  // half of the color 100 and half of the color 200 (red 100 and 200, green 155 and 55, blue 100)
  Assert.AreEqual(Cardinal($FF000000 or (150 shl 16) or (105 shl 8) or 100), ColorAt(5, 6));
end;

procedure TTestXcomBlendOverlay.UnVelinoOpacoDovrebbeEssereUnPienoDellaPaletta;
begin
  FSurface.DrawRect(0, 0, 32, 24, 100);
  FSprite.DrawRect(0, 0, 4, 4, 200);
  FOverlay.BeginVeil(FSurface, 5, 6, 4, 4);
  FSurface.DrawRect(5, 6, 4, 4, 200);
  FOverlay.EndVeil(FSurface, FSprite, 5, 6, TXcomBlendOverlay.OPAQUE, FOverlay.Everything);
  Assert.IsFalse(FOverlay.HasBlends);
end;

procedure TTestXcomBlendOverlay.UnVelinoDovrebbeSaltareIPixelTrasparentiDelloSprite;
begin
  FSurface.DrawRect(0, 0, 32, 24, 100);
  FSprite.DrawRect(0, 0, 4, 4, 200);
  FSprite.SetPixel(1, 1, 0);
  FOverlay.BeginVeil(FSurface, 5, 6, 4, 4);
  FOverlay.EndVeil(FSurface, FSprite, 5, 6, 128, FOverlay.Everything);
  Assert.IsTrue(Valid(5, 6));
  Assert.IsFalse(Valid(6, 7));
end;

procedure TTestXcomBlendOverlay.UnVelinoSuUnVelinoDovrebbeMescolareConLaSfumatura;
var
  LFirst: Cardinal;
begin
  FSurface.DrawRect(0, 0, 32, 24, 100);
  FSprite.DrawRect(0, 0, 4, 4, 200);
  FOverlay.BeginVeil(FSurface, 5, 6, 4, 4);
  FSurface.DrawRect(5, 6, 4, 4, 200);
  FOverlay.EndVeil(FSurface, FSprite, 5, 6, 128, FOverlay.Everything);
  LFirst := ColorAt(5, 6);
  FOverlay.BeginVeil(FSurface, 5, 6, 4, 4);
  FOverlay.EndVeil(FSurface, FSprite, 5, 6, 128, FOverlay.Everything);
  // the second veil is laid on the blend, not on the color of the palette under the first one
  Assert.AreEqual(Cardinal($FF000000 or (175 shl 16) or (80 shl 8) or 100), ColorAt(5, 6));
  Assert.AreNotEqual(LFirst, ColorAt(5, 6));
end;

procedure TTestXcomBlendOverlay.UnoSpriteSolidoDopoDovrebbeToglierelaSfumatura;
var
  LSolid: TXcomSurface;
begin
  FSurface.DrawRect(0, 0, 32, 24, 100);
  FSprite.DrawRect(0, 0, 4, 4, 200);
  FOverlay.BeginVeil(FSurface, 5, 6, 4, 4);
  FOverlay.EndVeil(FSurface, FSprite, 5, 6, 128, FOverlay.Everything);
  LSolid := TXcomSurface.Create(2, 2);
  try
    LSolid.DrawRect(0, 0, 2, 2, 50);
    FOverlay.Cover(LSolid, 6, 7);
    Assert.IsFalse(Valid(6, 7));
    Assert.IsFalse(Valid(7, 8));
    Assert.IsTrue(Valid(5, 6));
    Assert.IsTrue(Valid(8, 9));
  finally
    LSolid.Free;
  end;
end;

procedure TTestXcomBlendOverlay.UnPixelScrittoDopoDovrebbeToglierelaSfumatura;
begin
  FSurface.DrawRect(0, 0, 32, 24, 100);
  FSprite.DrawRect(0, 0, 4, 4, 200);
  FOverlay.BeginVeil(FSurface, 5, 6, 4, 4);
  FOverlay.EndVeil(FSurface, FSprite, 5, 6, 128, FOverlay.Everything);
  FOverlay.CoverPixel(5, 6);
  FOverlay.CoverPixel(-1, 3);
  FOverlay.CoverPixel(500, 3);
  Assert.IsFalse(Valid(5, 6));
  Assert.IsTrue(Valid(6, 6));
end;

procedure TTestXcomBlendOverlay.LaMezzaMetaDovrebbeCoprireSoloLaDestra;
var
  LSolid: TXcomSurface;
begin
  FSurface.DrawRect(0, 0, 32, 24, 100);
  FSprite.DrawRect(0, 0, 4, 4, 200);
  FOverlay.BeginVeil(FSurface, 5, 6, 4, 4);
  FOverlay.EndVeil(FSurface, FSprite, 5, 6, 128, FOverlay.Everything);
  LSolid := TXcomSurface.Create(4, 4);
  try
    LSolid.DrawRect(0, 0, 4, 4, 50);
    FOverlay.Cover(LSolid, 5, 6, True);
    Assert.IsTrue(Valid(5, 6));
    Assert.IsTrue(Valid(6, 6));
    Assert.IsFalse(Valid(7, 6));
    Assert.IsFalse(Valid(8, 6));
  finally
    LSolid.Free;
  end;
end;

procedure TTestXcomBlendOverlay.UnaOmbraDovrebbeScurireLEllisse;
begin
  FSurface.DrawRect(0, 0, 32, 24, 200);
  FOverlay.Darken(FSurface, 16, 12, 6, 3, 128);
  Assert.IsTrue(Valid(16, 12));
  Assert.IsTrue(Valid(22, 12));
  Assert.IsTrue(Valid(16, 15));
  Assert.IsFalse(Valid(23, 12));
  Assert.IsFalse(Valid(22, 15), 'fuori dall''ellisse');
  // half black over red 200, green 55, blue 100
  Assert.AreEqual(Cardinal($FF000000 or (100 shl 16) or (27 shl 8) or 50), ColorAt(16, 12));
end;

procedure TTestXcomBlendOverlay.ClearDovrebbeDimenticareTutto;
begin
  FSurface.DrawRect(0, 0, 32, 24, 200);
  FOverlay.Darken(FSurface, 16, 12, 6, 3, 128);
  Assert.IsTrue(FOverlay.HasBlends);
  FOverlay.Clear;
  Assert.IsFalse(FOverlay.HasBlends);
  Assert.IsFalse(Valid(16, 12));
end;

procedure TTestXcomBlendOverlay.UnaMisuraSbagliataDovrebbeSollevare;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomBlendOverlay.Create(0, 4);
    end, EArgumentException);
end;

end.
