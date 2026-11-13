{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEndoomRenderer                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.Renderer;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Endoom.Intf;

type
  /// <summary>
  ///   Tests\Data\Endoom\endoom.golden.txt was written by the old E_Drawer of e_endoom.pas, copied as
  ///   it is in a throwaway program (see README.md in that folder), on the inputs of TEndoomFixtures
  ///   and on the ENDOOM, ENDTEXT and ENDSTRF of the WADs of bin\ (skipped when they are missing)
  /// </summary>
  [TestFixture]
  [Category('endoom')]
  TTestEndoomRenderer = class(TObject)
  strict private
    FRenderer: IEndoomRenderer;
    FGolden: TDictionary<string, string>;
    function Render(const AScreen, AFont: TBytes; const AColors: TArray<Byte>;
      ABlinkVisible: Boolean): TBytes;
    function Rgb(const AIndexed: TBytes; AStride: Integer): TArray<Cardinal>;
    procedure Check(const AKey, AActual: string);
    procedure CheckScenario(const AKey: string; const AScreen, AFont: TBytes; AColorKind: Integer;
      AWithRgb: Boolean);
    procedure CheckReal(const AGame, AFolder, AWad, ALump: string);
    function FontWithGlyph(ACode: Integer): TBytes;
    function ScreenWithCell(ACell, ACode, AFlags: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareGliStessiPixelDelVecchioCodiceSuiDatiSintetici;
    [Test]
    procedure DovrebbeTrattareUnLumpCortoUnFontCortoOVuotoComeZeri;
    [Test]
    procedure DovrebbeDareGliStessiPixelDelVecchioCodiceSuiWadVeri;
    [Test]
    procedure DovrebbeUsareIlPrimoCarattereDelFontPerIlCodiceUno;
    [Test]
    procedure DovrebbeLasciareLoSfondoPerIlCodiceZero;
    [Test]
    procedure DovrebbeMettereLeCelleNelPostoGiusto;
    [Test]
    procedure DovrebbeUsareIlBitAltoDegliAttributiPerIlLampeggio;
    [Test]
    procedure DovrebbeUsareSoloTreBitPerLoSfondo;
    [Test]
    procedure DovrebbeIgnorareIlLumpOltreLeDuemilaCelle;
    [Test]
    procedure DovrebbeRiempireUnBufferGiaPronto;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaDiColoriSbagliata;
    [Test]
    procedure DovrebbeConvertireInRgbConAlphaPieno;
    [Test]
    procedure DovrebbeLasciareIlBordoDiUnaRigaPiuLarga;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteOUnaRigaSbagliata;
    [Test]
    procedure DovrebbeAvereSediciColoriDelTestoEDimensioniDelloSchermo;
  end;

implementation

uses
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.Factory,
  DelphiDoom.Tests.Endoom.Digest, DelphiDoom.Tests.Endoom.Fixtures;

{ TTestEndoomRenderer }

procedure TTestEndoomRenderer.Setup;
var
  LLines: TStringList;
  LIndex: Integer;
  LSeparator: Integer;
begin
  FRenderer := TEndoomFactory.CreateRenderer;
  FGolden := TDictionary<string, string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\Tests\Data\Endoom\endoom.golden.txt')));
    for LIndex := 0 to LLines.Count - 1 do
    begin
      LSeparator := Pos('=', LLines[LIndex]);
      if LSeparator > 1 then
        FGolden.Add(Copy(LLines[LIndex], 1, LSeparator - 1), Copy(LLines[LIndex], LSeparator + 1, MaxInt));
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestEndoomRenderer.TearDown;
begin
  FGolden.Free;
  FRenderer := nil;
end;

function TTestEndoomRenderer.Render(const AScreen, AFont: TBytes; const AColors: TArray<Byte>;
  ABlinkVisible: Boolean): TBytes;
begin
  Result := nil;
  FRenderer.RenderIndexed(AScreen, AFont, AColors, ABlinkVisible, Result);
end;

function TTestEndoomRenderer.Rgb(const AIndexed: TBytes; AStride: Integer): TArray<Cardinal>;
begin
  Result := nil;
  FRenderer.ConvertToRgb32(AIndexed, TEndoomFixtures.Palette, AStride, Result);
end;

procedure TTestEndoomRenderer.Check(const AKey, AActual: string);
var
  LExpected: string;
begin
  Assert.IsTrue(FGolden.TryGetValue(AKey, LExpected), 'missing golden key ' + AKey);
  Assert.AreEqual(LExpected, AActual, AKey);
end;

procedure TTestEndoomRenderer.CheckScenario(const AKey: string; const AScreen, AFont: TBytes;
  AColorKind: Integer; AWithRgb: Boolean);
var
  LColors: TArray<Byte>;
  LOn: TBytes;
  LOff: TBytes;
begin
  LColors := TEndoomFixtures.ColorIndices(AColorKind);
  LOn := Render(AScreen, AFont, LColors, True);
  LOff := Render(AScreen, AFont, LColors, False);
  Check(AKey + '.on', TEndoomDigest.OfBytes(LOn));
  Check(AKey + '.off', TEndoomDigest.OfBytes(LOff));
  if AWithRgb then
  begin
    Check(AKey + '.rgb640', TEndoomDigest.OfCardinals(Rgb(LOn, 640)));
    Check(AKey + '.rgb1024', TEndoomDigest.OfCardinals(Rgb(LOff, 1024)));
  end;
end;

procedure TTestEndoomRenderer.CheckReal(const AGame, AFolder, AWad, ALump: string);
var
  LLump: TBytes;
  LFont: TBytes;
begin
  if not (TEndoomFixtures.ReadLump(TEndoomFixtures.WadPath(AFolder, AWad), ALump, LLump) and
    TEndoomFixtures.ReadLump(TEndoomFixtures.WadPath(AFolder, AFolder + '32.swd'), 'DOSFONT', LFont)) then
  begin
    Assert.Pass('WAD or DOSFONT missing: skipped');
    Exit;
  end;
  CheckScenario('real.' + AGame, LLump, LFont, 0, True);
end;

function TTestEndoomRenderer.FontWithGlyph(ACode: Integer): TBytes;
var
  LRow: Integer;
  LColumn: Integer;
begin
  // every pixel of the glyph of a code is on, the rest is off
  SetLength(Result, ENDOOM_FONT_SIZE);
  for LRow := 0 to 7 do
    for LColumn := 0 to 7 do
      Result[(((ACode - 1) div 16) * 8 + LRow) * ENDOOM_FONT_WIDTH + ((ACode - 1) mod 16) * 8 + LColumn] := 1;
end;

function TTestEndoomRenderer.ScreenWithCell(ACell, ACode, AFlags: Integer): TBytes;
begin
  SetLength(Result, ENDOOM_LUMP_SIZE);
  Result[ACell * 2] := Byte(ACode);
  Result[ACell * 2 + 1] := Byte(AFlags);
end;

procedure TTestEndoomRenderer.DovrebbeDareGliStessiPixelDelVecchioCodiceSuiDatiSintetici;
var
  LSyn: Integer;
  LColor: Integer;
begin
  for LSyn := 0 to 2 do
    for LColor := 0 to 1 do
      CheckScenario(Format('synth.s%d.c%d', [LSyn, LColor]), TEndoomFixtures.Screen(LSyn),
        TEndoomFixtures.Font, LColor, LColor = 0);
end;

procedure TTestEndoomRenderer.DovrebbeTrattareUnLumpCortoUnFontCortoOVuotoComeZeri;
begin
  CheckScenario('synth.emptyfont', TEndoomFixtures.Screen(0), nil, 0, False);
  CheckScenario('synth.shortlump', Copy(TEndoomFixtures.Screen(2), 0, 777), TEndoomFixtures.Font, 0, False);
  CheckScenario('synth.shortfont', TEndoomFixtures.Screen(1), Copy(TEndoomFixtures.Font, 0, 100), 1, False);
end;

procedure TTestEndoomRenderer.DovrebbeDareGliStessiPixelDelVecchioCodiceSuiWadVeri;
begin
  CheckReal('doom', 'Doom', 'DOOM1.WAD', 'ENDOOM');
  CheckReal('heretic', 'Heretic', 'HERETIC1.WAD', 'ENDTEXT');
  CheckReal('strife', 'Strife', 'STRIFE0.WAD', 'ENDSTRF');
end;

procedure TTestEndoomRenderer.DovrebbeUsareIlPrimoCarattereDelFontPerIlCodiceUno;
var
  LColors: TArray<Byte>;
  LPicture: TBytes;
begin
  LColors := TEndoomFixtures.ColorIndices(0);
  // cell 0, character 1, white on black: the glyph at the top left of the font
  LPicture := Render(ScreenWithCell(0, 1, $0F), FontWithGlyph(1), LColors, True);
  Assert.AreEqual(Integer(LColors[15]), Integer(LPicture[0]));
  Assert.AreEqual(Integer(LColors[15]), Integer(LPicture[7 + 7 * ENDOOM_WIDTH]));
  // character 2 has no pixels in this font, so cell 1 is all background
  LPicture := Render(ScreenWithCell(0, 2, $0F), FontWithGlyph(1), LColors, True);
  Assert.AreEqual(Integer(LColors[0]), Integer(LPicture[0]));
end;

procedure TTestEndoomRenderer.DovrebbeLasciareLoSfondoPerIlCodiceZero;
var
  LColors: TArray<Byte>;
  LPicture: TBytes;
  LFont: TBytes;
begin
  LColors := TEndoomFixtures.ColorIndices(0);
  LFont := FontWithGlyph(1);
  LPicture := Render(ScreenWithCell(0, 0, $4F), LFont, LColors, True);
  Assert.AreEqual(Integer(LColors[4]), Integer(LPicture[0]));
  Assert.AreEqual(Integer(LColors[4]), Integer(LPicture[7 * ENDOOM_WIDTH + 7]));
end;

procedure TTestEndoomRenderer.DovrebbeMettereLeCelleNelPostoGiusto;
var
  LColors: TArray<Byte>;
  LPicture: TBytes;
begin
  LColors := TEndoomFixtures.ColorIndices(0);
  // the cell of the column 3 and the row 2: first pixel at x = 24, y = 16
  LPicture := Render(ScreenWithCell(2 * ENDOOM_COLUMNS + 3, 1, $0E), FontWithGlyph(1), LColors, True);
  Assert.AreEqual(Integer(LColors[14]), Integer(LPicture[16 * ENDOOM_WIDTH + 24]));
  Assert.AreEqual(Integer(LColors[14]), Integer(LPicture[23 * ENDOOM_WIDTH + 31]));
  Assert.AreEqual(Integer(LColors[0]), Integer(LPicture[16 * ENDOOM_WIDTH + 23]));
  Assert.AreEqual(Integer(LColors[0]), Integer(LPicture[16 * ENDOOM_WIDTH + 32]));
  Assert.AreEqual(Integer(LColors[0]), Integer(LPicture[24 * ENDOOM_WIDTH + 24]));
end;

procedure TTestEndoomRenderer.DovrebbeUsareIlBitAltoDegliAttributiPerIlLampeggio;
var
  LColors: TArray<Byte>;
  LScreen: TBytes;
  LFont: TBytes;
begin
  LColors := TEndoomFixtures.ColorIndices(0);
  LFont := FontWithGlyph(1);
  // white on blue, blinking
  LScreen := ScreenWithCell(0, 1, $80 or $10 or $0F);
  Assert.AreEqual(Integer(LColors[15]), Integer(Render(LScreen, LFont, LColors, True)[0]));
  Assert.AreEqual(Integer(LColors[1]), Integer(Render(LScreen, LFont, LColors, False)[0]));
  // the same without the blinking: always visible
  LScreen := ScreenWithCell(0, 1, $10 or $0F);
  Assert.AreEqual(Integer(LColors[15]), Integer(Render(LScreen, LFont, LColors, False)[0]));
end;

procedure TTestEndoomRenderer.DovrebbeUsareSoloTreBitPerLoSfondo;
var
  LColors: TArray<Byte>;
  LPicture: TBytes;
begin
  LColors := TEndoomFixtures.ColorIndices(0);
  // background 5 (magenta), foreground 0; the blinking bit does not pick a light background
  LPicture := Render(ScreenWithCell(0, 0, $D0), FontWithGlyph(1), LColors, True);
  Assert.AreEqual(Integer(LColors[5]), Integer(LPicture[0]));
end;

procedure TTestEndoomRenderer.DovrebbeIgnorareIlLumpOltreLeDuemilaCelle;
var
  LColors: TArray<Byte>;
  LLong: TBytes;
  LNormal: TBytes;
begin
  LColors := TEndoomFixtures.ColorIndices(1);
  LNormal := TEndoomFixtures.Screen(0);
  LLong := TEndoomFixtures.RandomBytes(5, 6000, $FF);
  Move(LNormal[0], LLong[0], Length(LNormal));
  Assert.AreEqual(TEndoomDigest.OfBytes(Render(LNormal, TEndoomFixtures.Font, LColors, True)),
    TEndoomDigest.OfBytes(Render(LLong, TEndoomFixtures.Font, LColors, True)));
end;

procedure TTestEndoomRenderer.DovrebbeRiempireUnBufferGiaPronto;
var
  LColors: TArray<Byte>;
  LBuffer: TBytes;
  LExpected: TBytes;
begin
  LColors := TEndoomFixtures.ColorIndices(0);
  LExpected := Render(TEndoomFixtures.Screen(1), TEndoomFixtures.Font, LColors, True);
  SetLength(LBuffer, ENDOOM_WIDTH * ENDOOM_HEIGHT);
  FillChar(LBuffer[0], Length(LBuffer), $EE);
  FRenderer.RenderIndexed(TEndoomFixtures.Screen(1), TEndoomFixtures.Font, LColors, True, LBuffer);
  Assert.AreEqual(TEndoomDigest.OfBytes(LExpected), TEndoomDigest.OfBytes(LBuffer));
  // a buffer of another size is replaced
  SetLength(LBuffer, 10);
  FRenderer.RenderIndexed(TEndoomFixtures.Screen(1), TEndoomFixtures.Font, LColors, True, LBuffer);
  Assert.AreEqual<Integer>(ENDOOM_WIDTH * ENDOOM_HEIGHT, Length(LBuffer));
end;

procedure TTestEndoomRenderer.DovrebbeRifiutareUnaTabellaDiColoriSbagliata;
var
  LBuffer: TBytes;
  LShort: TArray<Byte>;
begin
  SetLength(LShort, 15);
  Assert.WillRaise(
    procedure
    begin
      FRenderer.RenderIndexed(TEndoomFixtures.Screen(0), TEndoomFixtures.Font, LShort, True, LBuffer);
    end, EEndoomException);
end;

procedure TTestEndoomRenderer.DovrebbeConvertireInRgbConAlphaPieno;
var
  LPalette: TArray<Cardinal>;
  LIndexed: TBytes;
  LPicture: TArray<Cardinal>;
begin
  LPalette := TEndoomFixtures.Palette;
  SetLength(LIndexed, ENDOOM_WIDTH * ENDOOM_HEIGHT);
  LIndexed[0] := 7;
  LIndexed[ENDOOM_WIDTH + 5] := 200;
  LPicture := Rgb(LIndexed, ENDOOM_WIDTH);
  Assert.AreEqual<Integer>(Integer(ENDOOM_WIDTH * ENDOOM_HEIGHT), Length(LPicture));
  Assert.AreEqual(LPalette[7] or $FF000000, LPicture[0]);
  Assert.AreEqual(LPalette[200] or $FF000000, LPicture[ENDOOM_WIDTH + 5]);
  Assert.AreEqual(LPalette[0] or $FF000000, LPicture[1]);
end;

procedure TTestEndoomRenderer.DovrebbeLasciareIlBordoDiUnaRigaPiuLarga;
var
  LIndexed: TBytes;
  LPicture: TArray<Cardinal>;
begin
  SetLength(LIndexed, ENDOOM_WIDTH * ENDOOM_HEIGHT);
  LPicture := Rgb(LIndexed, 1024);
  Assert.AreEqual<Integer>(1024 * ENDOOM_HEIGHT, Length(LPicture));
  Assert.AreEqual(Cardinal(0), LPicture[ENDOOM_WIDTH]);
  Assert.AreEqual(Cardinal(0), LPicture[1023]);
  Assert.AreNotEqual(Cardinal(0), LPicture[ENDOOM_WIDTH - 1]);
end;

procedure TTestEndoomRenderer.DovrebbeRifiutareUnaPaletteOUnaRigaSbagliata;
var
  LIndexed: TBytes;
  LOutput: TArray<Cardinal>;
  LShort: TArray<Cardinal>;
begin
  SetLength(LIndexed, ENDOOM_WIDTH * ENDOOM_HEIGHT);
  SetLength(LShort, 255);
  Assert.WillRaise(
    procedure
    begin
      FRenderer.ConvertToRgb32(LIndexed, LShort, ENDOOM_WIDTH, LOutput);
    end, EEndoomException);
  Assert.WillRaise(
    procedure
    begin
      FRenderer.ConvertToRgb32(LIndexed, TEndoomFixtures.Palette, ENDOOM_WIDTH - 1, LOutput);
    end, EEndoomException);
end;

procedure TTestEndoomRenderer.DovrebbeAvereSediciColoriDelTestoEDimensioniDelloSchermo;
begin
  Assert.AreEqual(16, Length(ENDOOM_COLORS));
  Assert.AreEqual(Cardinal($000000), ENDOOM_COLORS[0]);
  Assert.AreEqual(Cardinal($AA5500), ENDOOM_COLORS[6]);
  Assert.AreEqual(Cardinal($FFFFFF), ENDOOM_COLORS[15]);
  Assert.AreEqual(4000, ENDOOM_LUMP_SIZE);
  Assert.AreEqual(640, ENDOOM_WIDTH);
  Assert.AreEqual(200, ENDOOM_HEIGHT);
end;

end.
