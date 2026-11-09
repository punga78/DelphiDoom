{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL texture buffers (Libs\GlTexture)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.TextureBuffers;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.GlTexture.Types;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlTextureBuffers = class(TObject)
  strict private
    FPalette: TBytes;
    FRipple: TBytes;
    procedure MakePalette(const ADistinctColors: Integer);
    procedure MakeRipple;
    function MakePatch(const AWidth: Integer): TBytes;
    function RandomBuffer(const ASize: Integer): TBytes;
    function PaletteData: TGlTexturePaletteData;
    function RandomTranslation: TBytes;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeTrovareLaMappaDeiColoriComeIlVecchioCodice;
    [Test]
    procedure DovrebbeDareMenoUnoSeITuttiIColoriSonoDiversi;
    [Test]
    procedure DovrebbeCostruireLaPaletteDelDriverComeIlVecchioCodice;
    [Test]
    procedure DovrebbeNonScrivereFuoriDallaPaletteSenzaColoreTrasparente;
    [Test]
    procedure DovrebbeDipingereLePatchCosiCome;
    [Test]
    procedure DovrebbeDipingereLePatchConUnaTabellaDiTraduzione;
    [Test]
    procedure DovrebbeNonFareNullaSeLaPatchEFuoriDallaTexture;
    [Test]
    procedure DovrebbeDipingereIFlatCosiCome;
    [Test]
    procedure DovrebbeFareOndeggiareUnBufferComeIlVecchioCodice;
    [Test]
    procedure DovrebbeNonFareNullaSenzaLaRigaDelleOnde;
    [Test]
    procedure DovrebbeMarcareLePatchPerLaTrasparenzaComeIlVecchioCodice;
    [Test]
    procedure DovrebbeTrovareIBuchiComeIlVecchioCodice;
    [Test]
    procedure DovrebbeNonLeggereOltreLaFineDellaMaschera;
  end;

implementation

uses
  DelphiDoom.GlTexture.Palette,
  DelphiDoom.GlTexture.PatchPainter,
  DelphiDoom.GlTexture.FlatPainter,
  DelphiDoom.GlTexture.Ripple,
  DelphiDoom.GlTexture.Transparency,
  DelphiDoom.Tests.OpenGl.OldTextureBuffers;

procedure TTestOpenGlTextureBuffers.Setup;
begin
  RandSeed := 177;
end;

procedure TTestOpenGlTextureBuffers.MakePalette(const ADistinctColors: Integer);
var
  LColors: array of array[0..2] of Byte;
  LIndex, LPick: Integer;
begin
  SetLength(LColors, ADistinctColors);
  for LIndex := 0 to ADistinctColors - 1 do
  begin
    LColors[LIndex][0] := Random(256);
    LColors[LIndex][1] := Random(256);
    LColors[LIndex][2] := Random(256);
  end;
  // the old code read 4 bytes at the last color: one byte of guard
  SetLength(FPalette, 768 + 8);
  FillChar(FPalette[0], Length(FPalette), 0);
  for LIndex := 0 to 255 do
  begin
    if ADistinctColors >= 256 then
      LPick := LIndex
    else
      LPick := Random(ADistinctColors);
    FPalette[LIndex * 3] := LColors[LPick][0];
    FPalette[LIndex * 3 + 1] := LColors[LPick][1];
    FPalette[LIndex * 3 + 2] := LColors[LPick][2];
  end;
  old_playpal := POldByteArray(@FPalette[0]);
end;

procedure TTestOpenGlTextureBuffers.MakeRipple;
var
  LIndex: Integer;
  LValues: array[0..127] of Integer;
begin
  for LIndex := 0 to 127 do
    LValues[LIndex] := Random($40000) - $20000;
  SetLength(FRipple, SizeOf(LValues));
  Move(LValues[0], FRipple[0], SizeOf(LValues));
  old_ripple := POldIntegerArray(@FRipple[0]);
end;

function TTestOpenGlTextureBuffers.PaletteData: TGlTexturePaletteData;
begin
  Result.Colors := @FPalette[0];
  Result.ColorMap := @old_palmap[0];
end;

function TTestOpenGlTextureBuffers.RandomBuffer(const ASize: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ASize);
  for LIndex := 0 to ASize - 1 do
    Result[LIndex] := Random(256);
end;

function TTestOpenGlTextureBuffers.RandomTranslation: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := Random(256);
end;

// A patch of the game: the header, the offsets of the columns and the columns made of posts
// (top delta, length, a byte of padding, the pixels, a byte of padding), ended by 255. The
// top deltas go up most of the time and sometimes do not (the "tall patch" of the engine).
function TTestOpenGlTextureBuffers.MakePatch(const AWidth: Integer): TBytes;
var
  LColumns: TBytes;
  LOffsets: array of Integer;
  LX, LPosts, LPost, LLength, LIndex, LTop, LPrevious, LPixel: Integer;
  LHeader: Integer;
  LSmall: SmallInt;
begin
  SetLength(LOffsets, AWidth);
  SetLength(LColumns, 0);
  LHeader := GLTEXTURE_PATCH_HEADER_SIZE + 4 * AWidth;
  for LX := 0 to AWidth - 1 do
  begin
    LOffsets[LX] := LHeader + Length(LColumns);
    LPosts := Random(4);
    LPrevious := 0;
    for LPost := 0 to LPosts - 1 do
    begin
      if Random(5) = 0 then
        LTop := Random(60)
      else
        LTop := LPrevious + Random(25);
      if LTop > 254 then
        LTop := 254;
      LPrevious := LTop;
      LLength := 1 + Random(40);
      SetLength(LColumns, Length(LColumns) + 4 + LLength);
      LIndex := Length(LColumns) - 4 - LLength;
      LColumns[LIndex] := LTop;
      LColumns[LIndex + 1] := LLength;
      LColumns[LIndex + 2] := 0;
      for LPixel := 0 to LLength - 1 do
        LColumns[LIndex + 3 + LPixel] := Random(256);
      LColumns[LIndex + 3 + LLength] := 0;
    end;
    SetLength(LColumns, Length(LColumns) + 1);
    LColumns[High(LColumns)] := 255;
  end;
  SetLength(Result, LHeader + Length(LColumns) + 8);
  FillChar(Result[0], Length(Result), 0);
  LSmall := AWidth;
  Move(LSmall, Result[0], 2);
  LSmall := 1 + Random(64);
  Move(LSmall, Result[2], 2);
  for LX := 0 to AWidth - 1 do
    Move(LOffsets[LX], Result[GLTEXTURE_PATCH_HEADER_SIZE + 4 * LX], 4);
  Move(LColumns[0], Result[LHeader], Length(LColumns));
end;

procedure TTestOpenGlTextureBuffers.DovrebbeTrovareLaMappaDeiColoriComeIlVecchioCodice;
var
  LRound, LColors, LIndex: Integer;
  LMap: array[0..255] of Byte;
begin
  for LRound := 1 to 200 do
  begin
    LColors := 1 + Random(255);
    MakePalette(LColors);
    Old_InitPalettedTextures;
    Assert.AreEqual(old_transparent_pal_index, TGlTexturePalette.BuildColorMap(@FPalette[0], LMap),
      'indice, giro ' + IntToStr(LRound));
    for LIndex := 0 to 255 do
      Assert.AreEqual(Integer(old_palmap[LIndex]), Integer(LMap[LIndex]), 'colore ' + IntToStr(LIndex));
  end;
end;

procedure TTestOpenGlTextureBuffers.DovrebbeDareMenoUnoSeITuttiIColoriSonoDiversi;
var
  LMap: array[0..255] of Byte;
  LIndex: Integer;
begin
  SetLength(FPalette, 768);
  FillChar(FPalette[0], 768, 0);
  for LIndex := 0 to 255 do
    FPalette[LIndex * 3] := LIndex;
  Assert.AreEqual(-1, TGlTexturePalette.BuildColorMap(@FPalette[0], LMap));
  for LIndex := 0 to 255 do
    Assert.AreEqual(LIndex, Integer(LMap[LIndex]));
end;

procedure TTestOpenGlTextureBuffers.DovrebbeCostruireLaPaletteDelDriverComeIlVecchioCodice;
var
  LRound: Integer;
  LOld: array[0..1023] of Byte;
  LNew: TGlTextureRgbaPalette;
begin
  for LRound := 1 to 100 do
  begin
    MakePalette(2 + Random(254));
    Old_InitPalettedTextures;
    if old_transparent_pal_index < 0 then
      Continue;
    Old_SetTexturePalette(LOld);
    TGlTexturePalette.BuildRgba(@FPalette[0], old_transparent_pal_index, LNew);
    Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], 1024), 'giro ' + IntToStr(LRound));
  end;
end;

procedure TTestOpenGlTextureBuffers.DovrebbeNonScrivereFuoriDallaPaletteSenzaColoreTrasparente;
var
  LPalette: TGlTextureRgbaPalette;
begin
  MakePalette(256);
  TGlTexturePalette.BuildRgba(@FPalette[0], -1, LPalette);
  Assert.AreEqual(Cardinal(FPalette[0]) or (Cardinal(FPalette[1]) shl 8) or (Cardinal(FPalette[2]) shl 16) or $FF000000,
    LPalette[0]);
  Assert.AreEqual(Cardinal($FF000000), LPalette[255] and $FF000000);
end;

procedure TTestOpenGlTextureBuffers.DovrebbeDipingereLePatchCosiCome;
var
  LRound, LRealWidth, LRealHeight, LBufferWidth, LBufferHeight, LOriginX, LOriginY, LBpp: Integer;
  LPaletted: Boolean;
  LPatch, LOld, LNew: TBytes;
  LTexture: OldGLTexture;
  LTarget: TGlTextureTarget;
begin
  for LRound := 1 to 600 do
  begin
    MakePalette(2 + Random(254));
    Old_InitPalettedTextures;
    LRealWidth := 4 + Random(60);
    LRealHeight := 4 + Random(60);
    LBufferWidth := LRealWidth + Random(9);
    LBufferHeight := LRealHeight + Random(5);
    LOriginX := Random(90) - 30;
    LOriginY := Random(90) - 30;
    LPaletted := Random(2) = 0;
    if LPaletted then
      LBpp := 1
    else
      LBpp := 4;
    LPatch := MakePatch(1 + Random(40));
    LOld := RandomBuffer(LBufferWidth * LBufferHeight * LBpp);
    LNew := Copy(LOld);
    LTexture.realtexwidth := LRealWidth;
    LTexture.realtexheight := LRealHeight;
    LTexture.buffer_width := LBufferWidth;
    LTexture.buffer_height := LBufferHeight;
    LTarget.Pixels := @LNew[0];
    LTarget.BufferWidth := LBufferWidth;
    LTarget.RealWidth := LRealWidth;
    LTarget.RealHeight := LRealHeight;
    Old_AddPatchToTexture_UnTranslated(@LTexture, POldByteArray(@LOld[0]), @LPatch[0], LOriginX, LOriginY, LPaletted);
    TGlTexturePatchPainter.Paint(LTarget, @LPatch[0], LOriginX, LOriginY, PaletteData, nil, LPaletted);
    Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], Length(LOld)), 'giro ' + IntToStr(LRound));
  end;
end;

procedure TTestOpenGlTextureBuffers.DovrebbeDipingereLePatchConUnaTabellaDiTraduzione;
var
  LRound, LRealWidth, LRealHeight, LOriginX, LOriginY, LBpp: Integer;
  LPaletted: Boolean;
  LPatch, LOld, LNew, LTranslation: TBytes;
  LTexture: OldGLTexture;
  LTarget: TGlTextureTarget;
begin
  for LRound := 1 to 600 do
  begin
    MakePalette(2 + Random(254));
    Old_InitPalettedTextures;
    LRealWidth := 4 + Random(60);
    LRealHeight := 4 + Random(60);
    LOriginX := Random(90) - 30;
    LOriginY := Random(90) - 30;
    LPaletted := Random(2) = 0;
    if LPaletted then
      LBpp := 1
    else
      LBpp := 4;
    LPatch := MakePatch(1 + Random(40));
    LTranslation := RandomTranslation;
    LOld := RandomBuffer(LRealWidth * LRealHeight * LBpp);
    LNew := Copy(LOld);
    LTexture.realtexwidth := LRealWidth;
    LTexture.realtexheight := LRealHeight;
    LTexture.buffer_width := LRealWidth;
    LTexture.buffer_height := LRealHeight;
    LTarget.Pixels := @LNew[0];
    LTarget.BufferWidth := LRealWidth;
    LTarget.RealWidth := LRealWidth;
    LTarget.RealHeight := LRealHeight;
    Old_AddPatchToTexture(@LTexture, POldByteArray(@LOld[0]), @LPatch[0], LOriginX, LOriginY,
      POldByteArray(@LTranslation[0]), LPaletted);
    TGlTexturePatchPainter.Paint(LTarget, @LPatch[0], LOriginX, LOriginY, PaletteData, @LTranslation[0], LPaletted);
    Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], Length(LOld)), 'giro ' + IntToStr(LRound));
  end;
end;

procedure TTestOpenGlTextureBuffers.DovrebbeNonFareNullaSeLaPatchEFuoriDallaTexture;
var
  LPatch, LBuffer, LCopy: TBytes;
  LTarget: TGlTextureTarget;
begin
  MakePalette(200);
  Old_InitPalettedTextures;
  LPatch := MakePatch(10);
  LBuffer := RandomBuffer(16 * 16 * 4);
  LTarget.Pixels := @LBuffer[0];
  LTarget.BufferWidth := 16;
  LTarget.RealWidth := 16;
  LTarget.RealHeight := 16;
  LCopy := Copy(LBuffer);
  // right of the texture, left of it (the patch is 10 wide), below it and no patch at all
  TGlTexturePatchPainter.Paint(LTarget, @LPatch[0], 16, 0, PaletteData, nil, False);
  TGlTexturePatchPainter.Paint(LTarget, @LPatch[0], -10, 0, PaletteData, nil, False);
  TGlTexturePatchPainter.Paint(LTarget, @LPatch[0], 0, 100, PaletteData, nil, False);
  TGlTexturePatchPainter.Paint(LTarget, nil, 0, 0, PaletteData, nil, False);
  Assert.IsTrue(CompareMem(@LBuffer[0], @LCopy[0], Length(LBuffer)));
end;

procedure TTestOpenGlTextureBuffers.DovrebbeDipingereIFlatCosiCome;
var
  LRound, LRealWidth, LRealHeight, LBufferWidth, LBufferHeight, LBpp: Integer;
  LPaletted, LRipple: Boolean;
  LFlat, LOld, LNew: TBytes;
  LTexture: OldGLTexture;
  LTarget: TGlTextureTarget;
begin
  for LRound := 1 to 200 do
  begin
    MakePalette(2 + Random(254));
    MakeRipple;
    Old_InitPalettedTextures;
    LRealWidth := 8 + Random(57);
    LRealHeight := 8 + Random(57);
    LBufferWidth := LRealWidth + Random(9);
    LBufferHeight := LRealHeight + Random(5);
    LPaletted := Random(2) = 0;
    LRipple := Random(2) = 0;
    if LPaletted then
      LBpp := 1
    else
      LBpp := 4;
    LFlat := RandomBuffer(LRealWidth * LRealHeight);
    LOld := RandomBuffer(LBufferWidth * LBufferHeight * LBpp);
    LNew := Copy(LOld);
    LTexture.realtexwidth := LRealWidth;
    LTexture.realtexheight := LRealHeight;
    LTexture.buffer_width := LBufferWidth;
    LTexture.buffer_height := LBufferHeight;
    LTarget.Pixels := @LNew[0];
    LTarget.BufferWidth := LBufferWidth;
    LTarget.RealWidth := LRealWidth;
    LTarget.RealHeight := LRealHeight;
    Old_AddFlatToTexture(@LTexture, POldByteArray(@LOld[0]), POldByteArray(@LFlat[0]), LPaletted, LRipple);
    TGlTextureFlatPainter.Paint(LTarget, @LFlat[0], PaletteData, LPaletted);
    if LRipple then
      TGlTextureRipple.Transform(@LNew[0], LBufferWidth, LBufferHeight, LBpp, PGlRippleRow(@FRipple[0]));
    Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], Length(LOld)), 'giro ' + IntToStr(LRound));
  end;
end;

procedure TTestOpenGlTextureBuffers.DovrebbeFareOndeggiareUnBufferComeIlVecchioCodice;
var
  LRound, LWidth, LHeight, LBpp: Integer;
  LOld, LNew: TBytes;
begin
  for LRound := 1 to 300 do
  begin
    MakeRipple;
    LWidth := 1 + Random(70);
    LHeight := 1 + Random(70);
    case Random(3) of
      0: LBpp := 1;
      1: LBpp := 3;
    else
      LBpp := 4;
    end;
    LOld := RandomBuffer(LWidth * LHeight * LBpp);
    LNew := Copy(LOld);
    Old_RippleTransform(@LOld[0], LWidth, LHeight, LBpp);
    TGlTextureRipple.Transform(@LNew[0], LWidth, LHeight, LBpp, PGlRippleRow(@FRipple[0]));
    Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], Length(LOld)), 'giro ' + IntToStr(LRound));
  end;
end;

procedure TTestOpenGlTextureBuffers.DovrebbeNonFareNullaSenzaLaRigaDelleOnde;
var
  LBuffer, LCopy: TBytes;
begin
  LBuffer := RandomBuffer(64);
  LCopy := Copy(LBuffer);
  TGlTextureRipple.Transform(@LBuffer[0], 8, 8, 1, nil);
  Assert.IsTrue(CompareMem(@LBuffer[0], @LCopy[0], 64));
end;

procedure TTestOpenGlTextureBuffers.DovrebbeMarcareLePatchPerLaTrasparenzaComeIlVecchioCodice;
var
  LRound, LRealWidth, LRealHeight, LOriginX, LOriginY: Integer;
  LPatch, LOld, LNew: TBytes;
  LTexture: OldGLTexture;
begin
  for LRound := 1 to 500 do
  begin
    LRealWidth := 4 + Random(60);
    LRealHeight := 4 + Random(60);
    LOriginX := Random(90) - 30;
    LOriginY := Random(90) - 30;
    LPatch := MakePatch(1 + Random(40));
    SetLength(LOld, LRealWidth * LRealHeight);
    FillChar(LOld[0], Length(LOld), 0);
    LNew := Copy(LOld);
    LTexture.realtexwidth := LRealWidth;
    LTexture.realtexheight := LRealHeight;
    LTexture.buffer_width := LRealWidth;
    LTexture.buffer_height := LRealHeight;
    Old_AddPatchForTransparencyCheck(@LTexture, POldByteArray(@LOld[0]), @LPatch[0], LOriginX, LOriginY);
    TGlTextureTransparency.MarkPatch(@LNew[0], LRealWidth, LRealHeight, @LPatch[0], LOriginX, LOriginY);
    Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], Length(LOld)), 'giro ' + IntToStr(LRound));
  end;
end;

procedure TTestOpenGlTextureBuffers.DovrebbeTrovareIBuchiComeIlVecchioCodice;
var
  LRound, LSize, LIndex, LHoles: Integer;
  LMask: TBytes;
begin
  for LRound := 1 to 2000 do
  begin
    LSize := 1 + Random(70);
    // the old scan read one byte after a mask of 4n + 3 bytes: the guard is 255 here
    SetLength(LMask, LSize + 8);
    FillChar(LMask[0], Length(LMask), 255);
    LHoles := Random(4);
    for LIndex := 1 to LHoles do
      LMask[Random(LSize)] := Random(255);
    // the old scan does not look at the first four bytes of a mask of 7 bytes or more: both agree
    Assert.AreEqual(Old_ScanTransparency(POldByteArray(@LMask[0]), LSize),
      TGlTextureTransparency.HasHoles(@LMask[0], LSize), 'giro ' + IntToStr(LRound));
  end;
end;

procedure TTestOpenGlTextureBuffers.DovrebbeNonLeggereOltreLaFineDellaMaschera;
var
  LMask: TBytes;
begin
  // 7 bytes all 255, the byte after the mask is 0: the old scan saw it through a word
  SetLength(LMask, 8);
  FillChar(LMask[0], 7, 255);
  LMask[7] := 0;
  Assert.IsFalse(TGlTextureTransparency.HasHoles(@LMask[0], 7));
  Assert.IsTrue(Old_ScanTransparency(POldByteArray(@LMask[0]), 7));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOpenGlTextureBuffers);

end.
