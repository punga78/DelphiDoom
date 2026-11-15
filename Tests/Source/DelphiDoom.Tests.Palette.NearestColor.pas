{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the palette library - TNearestColor                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Palette.NearestColor;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Palette.Fixtures,
  DelphiDoom.Palette.NearestColor;

type
  PLongWordArray = ^TLongWordArray;
  TLongWordArray = array[0..255] of LongWord;

  [TestFixture]
  [Category('palette')]
  TTestPaletteNearestColor = class(TObject)
  strict private
    FPalette: TArray<Cardinal>;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeTrovareIlColoreEsatto;
    [Test]
    procedure DovrebbeDareIlPrimoDegliUguali;
    [Test]
    procedure DovrebbeDareIlPrimoIndiceConUnIntervalloVuoto;
    [Test]
    procedure DovrebbeSaltareLIndiceEscluso;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioTestoSuColoriCasuali;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioTestoConEsclusione;
  end;

implementation

// The text of V_FindAproxColorIndex and V_FindAproxColorIndexExcluding of v_video.pas before issue #241, as it was

function OldFindAproxColorIndex(const pal: PLongWordArray; const c: LongWord;
  const start: integer = 0; const finish: integer = 255): integer;
var
  r, g, b: integer;
  rc, gc, bc: integer;
  dr, dg, db: integer;
  i: integer;
  cc: LongWord;
  dist: LongWord;
  mindist: LongWord;
begin
  r := c and $FF;
  g := (c shr 8) and $FF;
  b := (c shr 16) and $FF;
  result := start;
  mindist := LongWord($ffffffff);
  for i := start to finish do
  begin
    cc := pal[i];
    rc := cc and $FF;
    gc := (cc shr 8) and $FF;
    bc := (cc shr 16) and $FF;
    dr := r - rc;
    dg := g - gc;
    db := b - bc;
    dist := dr * dr + dg * dg + db * db;
    if dist < mindist then
    begin
      result := i;
      if dist = 0 then
        exit
      else
        mindist := dist;
    end;
  end;
end;

function OldFindAproxColorIndexExcluding(const pal: PLongWordArray; const c: LongWord;
  const start: integer = 0; const finish: integer = 255; const exclude: integer = -1): integer;
var
  r, g, b: integer;
  rc, gc, bc: integer;
  dr, dg, db: integer;
  i: integer;
  cc: LongWord;
  dist: LongWord;
  mindist: LongWord;
begin
  r := c and $FF;
  g := (c shr 8) and $FF;
  b := (c shr 16) and $FF;
  result := start;
  mindist := LongWord($ffffffff);
  for i := start to finish do
  begin
    if i = exclude then
      continue;
    cc := pal[i];
    rc := cc and $FF;
    gc := (cc shr 8) and $FF;
    bc := (cc shr 16) and $FF;
    dr := r - rc;
    dg := g - gc;
    db := b - bc;
    dist := dr * dr + dg * dg + db * db;
    if dist < mindist then
    begin
      result := i;
      if dist = 0 then
        exit
      else
        mindist := dist;
    end;
  end;
end;

{ TTestPaletteNearestColor }

procedure TTestPaletteNearestColor.Setup;
begin
  FPalette := TPaletteFixtures.PackedColors(TPaletteFixtures.Palette8(11));
end;

procedure TTestPaletteNearestColor.DovrebbeTrovareIlColoreEsatto;
begin
  Assert.AreEqual(77, TNearestColor.Find(@FPalette[0], FPalette[77], 0, 255));
end;

procedure TTestPaletteNearestColor.DovrebbeDareIlPrimoDegliUguali;
begin
  FPalette[10] := $00123456;
  FPalette[20] := $00123456;
  Assert.AreEqual(10, TNearestColor.Find(@FPalette[0], $00123456, 0, 255));
end;

procedure TTestPaletteNearestColor.DovrebbeDareIlPrimoIndiceConUnIntervalloVuoto;
begin
  Assert.AreEqual(5, TNearestColor.Find(@FPalette[0], $123456, 5, 4));
end;

procedure TTestPaletteNearestColor.DovrebbeSaltareLIndiceEscluso;
begin
  Assert.AreNotEqual(77, TNearestColor.Find(@FPalette[0], FPalette[77], 0, 255, 77));
end;

procedure TTestPaletteNearestColor.DovrebbeEssereUgualeAlVecchioTestoSuColoriCasuali;
var
  LSeed: Cardinal;
  LColor: Cardinal;
  LIndex: Integer;
  LLow: Integer;
begin
  LSeed := 12345;
  for LIndex := 0 to 1999 do
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    LColor := LSeed and $FFFFFF;
    LLow := LIndex mod 3;
    Assert.AreEqual(
      OldFindAproxColorIndex(PLongWordArray(@FPalette[0]), LColor, LLow, 255 - (LIndex mod 5)),
      TNearestColor.Find(@FPalette[0], LColor, LLow, 255 - (LIndex mod 5)));
  end;
end;

procedure TTestPaletteNearestColor.DovrebbeEssereUgualeAlVecchioTestoConEsclusione;
var
  LSeed: Cardinal;
  LColor: Cardinal;
  LIndex: Integer;
begin
  LSeed := 777;
  for LIndex := 0 to 1999 do
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    LColor := LSeed and $FFFFFF;
    Assert.AreEqual(
      OldFindAproxColorIndexExcluding(PLongWordArray(@FPalette[0]), LColor, 0, 255, LIndex mod 256),
      TNearestColor.Find(@FPalette[0], LColor, 0, 255, LIndex mod 256));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPaletteNearestColor);

end.
