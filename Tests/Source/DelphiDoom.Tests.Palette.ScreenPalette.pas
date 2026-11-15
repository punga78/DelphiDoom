{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the palette library - TScreenPalette                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Palette.ScreenPalette;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Palette.Fixtures,
  DelphiDoom.Palette.Intf, DelphiDoom.Palette.GammaTables, DelphiDoom.Palette.Converter,
  DelphiDoom.Palette.ScreenPalette;

type
  [TestFixture]
  [Category('palette')]
  TTestPaletteScreenPalette = class(TObject)
  strict private
    FGamma: IGammaTables;
    FPalette: TBytes;
    FColormap: TBytes;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareIlColoreOpacoConLaGamma;
    [Test]
    procedure DovrebbeEssereUgualeAV_SetPaletteSuTuttiILivelliDiGamma;
    [Test]
    procedure DovrebbeEssereUgualeAV_CalcColorMapPaletteSuTuttiILivelliDiGamma;
    [Test]
    procedure DovrebbeEssereUgualeAV_InitDefaultPalette;
    [Test]
    procedure IlConvertitoreDellaLibreriaDovrebbeDareColoriSenzaAlfa;
    [Test]
    procedure DovrebbeLasciareInvariatoCioCheStaOltreLe256Voci;
  end;

implementation

// The loops of V_SetPalette, V_CalcColorMapPalette and V_InitDefaultPalette of v_video.pas before issue #241, as they were

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..32767] of Byte;
  PLongWord = ^LongWord;

procedure OldSetPalette(const palette: PByteArray; const curgamma: PByteArray; dest: PLongWord);
var
  src: PByteArray;
begin
  src := palette;
  while NativeUInt(src) < NativeUInt(@palette[256 * 3]) do
  begin
    dest^ := (LongWord(curgamma[src[0]]) shl 16) or
             (LongWord(curgamma[src[1]]) shl 8) or
             (LongWord(curgamma[src[2]])) or $FF000000;
    inc(dest);
    src := PByteArray(NativeInt(src) + 3);
  end;
end;

procedure OldCalcColorMapPalette(const palette: PByteArray; const colormap: PByteArray;
  const curgamma: PByteArray; dest: PLongWord);
var
  src: PByteArray;
  i: integer;
begin
  i := 0;
  while i < 256 do
  begin
    src := @palette[3 * colormap[i]];
    dest^ := (LongWord(curgamma[src[0]]) shl 16) or
             (LongWord(curgamma[src[1]]) shl 8) or
             (LongWord(curgamma[src[2]])) or $FF000000;
    inc(dest);
    inc(i);
  end;
end;

procedure OldInitDefaultPalette(const playpal: PByteArray; default_palette: PLongWord);
var
  i: integer;
begin
  for i := 0 to 255 do
    PLongWord(NativeInt(default_palette) + i * 4)^ :=
      (LongWord(playpal[i * 3]) shl 16) or (LongWord(playpal[i * 3 + 1]) shl 8) or playpal[i * 3 + 2];
end;

{ TTestPaletteScreenPalette }

procedure TTestPaletteScreenPalette.Setup;
begin
  FGamma := TGammaTables.Create;
  FPalette := TPaletteFixtures.Palette8(31);
  FColormap := TPaletteFixtures.Colormap(5, 1);
end;

procedure TTestPaletteScreenPalette.DovrebbeDareIlColoreOpacoConLaGamma;
var
  LGamma: TBytes;
  LColors: array[0..255] of Cardinal;
begin
  LGamma := FGamma.Table(2);
  TScreenPalette.Convert(@FPalette[0], @LGamma[0], @LColors[0], SCREEN_PALETTE_OPAQUE);
  Assert.AreEqual(Cardinal($FF000000) or (Cardinal(LGamma[FPalette[3]]) shl 16) or
    (Cardinal(LGamma[FPalette[4]]) shl 8) or Cardinal(LGamma[FPalette[5]]), LColors[1]);
end;

procedure TTestPaletteScreenPalette.DovrebbeEssereUgualeAV_SetPaletteSuTuttiILivelliDiGamma;
var
  LLevel: Integer;
  LGamma: TBytes;
  LOld: array[0..255] of LongWord;
  LNew: array[0..255] of Cardinal;
  LIndex: Integer;
begin
  for LLevel := 0 to FGamma.LevelCount - 1 do
  begin
    LGamma := FGamma.Table(LLevel);
    OldSetPalette(PByteArray(@FPalette[0]), PByteArray(@LGamma[0]), @LOld[0]);
    TScreenPalette.Convert(@FPalette[0], @LGamma[0], @LNew[0], SCREEN_PALETTE_OPAQUE);
    for LIndex := 0 to 255 do
      Assert.AreEqual(LOld[LIndex], LNew[LIndex]);
  end;
end;

procedure TTestPaletteScreenPalette.DovrebbeEssereUgualeAV_CalcColorMapPaletteSuTuttiILivelliDiGamma;
var
  LLevel: Integer;
  LGamma: TBytes;
  LOld: array[0..255] of LongWord;
  LNew: array[0..255] of Cardinal;
  LIndex: Integer;
begin
  for LLevel := 0 to FGamma.LevelCount - 1 do
  begin
    LGamma := FGamma.Table(LLevel);
    OldCalcColorMapPalette(PByteArray(@FPalette[0]), PByteArray(@FColormap[0]), PByteArray(@LGamma[0]), @LOld[0]);
    TScreenPalette.ConvertThroughColormap(@FPalette[0], @FColormap[0], @LGamma[0], @LNew[0],
      SCREEN_PALETTE_OPAQUE);
    for LIndex := 0 to 255 do
      Assert.AreEqual(LOld[LIndex], LNew[LIndex]);
  end;
end;

procedure TTestPaletteScreenPalette.DovrebbeEssereUgualeAV_InitDefaultPalette;
var
  LOld: array[0..255] of LongWord;
  LNew: array[0..255] of Cardinal;
  LIndex: Integer;
begin
  OldInitDefaultPalette(PByteArray(@FPalette[0]), @LOld[0]);
  TScreenPalette.Unpack(@FPalette[0], @LNew[0]);
  for LIndex := 0 to 255 do
    Assert.AreEqual(LOld[LIndex], LNew[LIndex]);
end;

procedure TTestPaletteScreenPalette.IlConvertitoreDellaLibreriaDovrebbeDareColoriSenzaAlfa;
var
  LGamma: TBytes;
  LConverter: IPaletteConverter;
  LColors: array[0..255] of Cardinal;
  LIndex: Integer;
begin
  LGamma := FGamma.Table(3);
  LConverter := TPaletteConverter.Create;
  LConverter.Convert(@FPalette[0], @LGamma[0], @LColors[0]);
  for LIndex := 0 to 255 do
    Assert.AreEqual(Cardinal(0), LColors[LIndex] and $FF000000);
  Assert.AreEqual(Cardinal(LGamma[FPalette[0]]) shl 16, LColors[0] and $FF0000);
end;

procedure TTestPaletteScreenPalette.DovrebbeLasciareInvariatoCioCheStaOltreLe256Voci;
var
  LGamma: TBytes;
  LColors: array[0..256] of Cardinal;
begin
  LGamma := FGamma.Table(0);
  LColors[256] := $DEADBEEF;
  TScreenPalette.Convert(@FPalette[0], @LGamma[0], @LColors[0], SCREEN_PALETTE_OPAQUE);
  Assert.AreEqual(Cardinal($DEADBEEF), LColors[256]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPaletteScreenPalette);

end.
