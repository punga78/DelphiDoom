{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL scene - the tint of a palette number        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.PaletteTint;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.GlScene.PaletteTint;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlPaletteTint = class(TObject)
  strict private
    // the text of the branch of gld_SetPalette of gl_render.pas (no shared palette) before IdTech1\GlScene
    procedure OldTint(palette: Integer; const AHexen: Boolean; out ARed, AGreen, ABlue, AAlpha: Single);
  public
    [Test]
    procedure DovrebbeDareLoStessoColoreDelVecchioPerOgniPaletta;
    [Test]
    procedure DovrebbeDareLoStessoColoreDelVecchioPerOgniPalettaDiHexen;
    [Test]
    procedure DovrebbeNonColorareLaPalettaNormale;
    [Test]
    procedure DovrebbeNonColorareUnaPalettaCheIlGiocoNonUsa;
    [Test]
    procedure DovrebbeColorareDiRossoLeOttoPrimePalette;
    [Test]
    procedure DovrebbeUsareLeDuePalettePropriePerHexenSoloPerHexen;
    [Test]
    procedure DovrebbeTenereOgniComponenteAlMassimoUno;
  end;

implementation

{ TTestOpenGlPaletteTint }

procedure TTestOpenGlPaletteTint.OldTint(palette: Integer; const AHexen: Boolean; out ARed, AGreen, ABlue,
  AAlpha: Single);
begin
  ARed := 0.0;
  AGreen := 0.0;
  ABlue := 0.0;
  AAlpha := 0.0;
  if palette > 0 then
  begin
    if palette <= 8 then
    begin
      ARed := palette / 2.0;
      AGreen := 0.0;
      ABlue := 0.0;
      AAlpha := palette / 10.0;
    end
    else if palette <= 12 then
    begin
      palette := palette - 8;
      ARed := palette * 1.0;
      AGreen := palette * 0.8;
      ABlue := palette * 0.1;
      AAlpha := palette / 11.0;
    end
    else if palette = 13 then
    begin
      ARed := 0.4;
      AGreen := 1.0;
      ABlue := 0.0;
      AAlpha := 0.2;
    end
    else if AHexen and (palette < 21) then
    begin
      palette := palette - 13;
      ARed := 0.0;
      AGreen := palette / 2.0;
      ABlue := 0.0;
      AAlpha := palette / 10.0;
    end
    else if AHexen and (palette = 21) then
    begin
      ARed := 0.0;
      AGreen := 0.0;
      ABlue := 1.0;
      AAlpha := 0.8;
    end;
  end;
  if ARed > 1.0 then
    ARed := 1.0;
  if AGreen > 1.0 then
    AGreen := 1.0;
  if ABlue > 1.0 then
    ABlue := 1.0;
  if AAlpha > 1.0 then
    AAlpha := 1.0;
end;

procedure TTestOpenGlPaletteTint.DovrebbeDareLoStessoColoreDelVecchioPerOgniPaletta;
var
  LPalette: Integer;
  LRed, LGreen, LBlue, LAlpha: Single;
  LTint: TGlScenePaletteTint;
begin
  for LPalette := -3 to 40 do
  begin
    OldTint(LPalette, False, LRed, LGreen, LBlue, LAlpha);
    LTint := TGlScenePaletteTints.Compute(LPalette, False);
    Assert.AreEqual(LRed, LTint.Red, Format('rosso %d', [LPalette]));
    Assert.AreEqual(LGreen, LTint.Green, Format('verde %d', [LPalette]));
    Assert.AreEqual(LBlue, LTint.Blue, Format('blu %d', [LPalette]));
    Assert.AreEqual(LAlpha, LTint.Alpha, Format('opacita %d', [LPalette]));
  end;
end;

procedure TTestOpenGlPaletteTint.DovrebbeDareLoStessoColoreDelVecchioPerOgniPalettaDiHexen;
var
  LPalette: Integer;
  LRed, LGreen, LBlue, LAlpha: Single;
  LTint: TGlScenePaletteTint;
begin
  for LPalette := -3 to 40 do
  begin
    OldTint(LPalette, True, LRed, LGreen, LBlue, LAlpha);
    LTint := TGlScenePaletteTints.Compute(LPalette, True);
    Assert.AreEqual(LRed, LTint.Red, Format('rosso %d', [LPalette]));
    Assert.AreEqual(LGreen, LTint.Green, Format('verde %d', [LPalette]));
    Assert.AreEqual(LBlue, LTint.Blue, Format('blu %d', [LPalette]));
    Assert.AreEqual(LAlpha, LTint.Alpha, Format('opacita %d', [LPalette]));
  end;
end;

procedure TTestOpenGlPaletteTint.DovrebbeNonColorareLaPalettaNormale;
var
  LTint: TGlScenePaletteTint;
begin
  LTint := TGlScenePaletteTints.Compute(0, False);
  Assert.AreEqual<Single>(0.0, LTint.Alpha);
  Assert.AreEqual<Single>(0.0, LTint.Red + LTint.Green + LTint.Blue);
end;

procedure TTestOpenGlPaletteTint.DovrebbeNonColorareUnaPalettaCheIlGiocoNonUsa;
var
  LTint: TGlScenePaletteTint;
begin
  LTint := TGlScenePaletteTints.Compute(14, False);
  Assert.AreEqual<Single>(0.0, LTint.Alpha);
  LTint := TGlScenePaletteTints.Compute(-1, True);
  Assert.AreEqual<Single>(0.0, LTint.Alpha);
end;

procedure TTestOpenGlPaletteTint.DovrebbeColorareDiRossoLeOttoPrimePalette;
var
  LTint: TGlScenePaletteTint;
begin
  LTint := TGlScenePaletteTints.Compute(1, False);
  Assert.AreEqual<Single>(0.5, LTint.Red);
  Assert.AreEqual<Single>(0.0, LTint.Green);
  Assert.AreEqual<Single>(0.0, LTint.Blue);
  Assert.AreEqual<Single>(Single(1 / 10.0), LTint.Alpha);
  // 4 / 2 is 2: the component stops at 1
  LTint := TGlScenePaletteTints.Compute(4, False);
  Assert.AreEqual<Single>(1.0, LTint.Red);
end;

procedure TTestOpenGlPaletteTint.DovrebbeUsareLeDuePalettePropriePerHexenSoloPerHexen;
var
  LTint: TGlScenePaletteTint;
begin
  LTint := TGlScenePaletteTints.Compute(21, True);
  Assert.AreEqual<Single>(1.0, LTint.Blue);
  Assert.AreEqual<Single>(Single(0.8), LTint.Alpha);
  LTint := TGlScenePaletteTints.Compute(21, False);
  Assert.AreEqual<Single>(0.0, LTint.Alpha);
  LTint := TGlScenePaletteTints.Compute(14, True);
  Assert.AreEqual<Single>(0.5, LTint.Green);
end;
procedure TTestOpenGlPaletteTint.DovrebbeTenereOgniComponenteAlMassimoUno;
var
  LPalette: Integer;
  LTint: TGlScenePaletteTint;
begin
  for LPalette := -3 to 40 do
  begin
    LTint := TGlScenePaletteTints.Compute(LPalette, True);
    Assert.IsTrue((LTint.Red <= 1.0) and (LTint.Green <= 1.0) and (LTint.Blue <= 1.0) and (LTint.Alpha <= 1.0),
      Format('palette %d', [LPalette]));
  end;
end;

end.
