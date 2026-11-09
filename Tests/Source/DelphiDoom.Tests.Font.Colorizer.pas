{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFontColorizer (issue #167)                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.Colorizer;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Colorizer;

type
  /// <summary>
  ///   The gray level is computed as the old Grayscale did (golden file: the fingerprint of the level of every
  ///   one of the 16 million colors); the rest of the steps are checked on pictures made here
  /// </summary>
  [TestFixture]
  [Category('font')]
  TTestFontColorizer = class(TObject)
  strict private
    FMatcher: IColorMatcher;
    function GrayPalette: TFontPaletteSelection;
    function Indexes(const AGray: TBytes; AFront, ABack: Integer; APerlin: Boolean): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLoStessoLivelloDiGrigioDelVecchioPerOgniColore;
    {$IFDEF CPUX86}
    [Test]
    procedure DovrebbeDare62PerIlGrigio63ComeIlVecchioInTrentaDueBit;
    {$ENDIF}
    [Test]
    procedure DovrebbeDareIlLivelloDiUnPixelBiancoENero;
    [Test]
    procedure DovrebbeLeggereIlRossoNelTerzoByteDelPixel;
    [Test]
    procedure DovrebbeFareIlGrigioDiOgniPixelDellImmagine;
    [Test]
    procedure DovrebbeRifiutareUnImmagineNonValida;
    [Test]
    procedure DovrebbeNonToccareLaImmagineSeIlMassimoEDi255;
    [Test]
    procedure DovrebbeNonToccareLaImmagineTuttaNera;
    [Test]
    procedure DovrebbeRenderePieno255OgniPixelNonNeroSeIlMassimoEMinore;
    [Test]
    procedure DovrebbeLasciareTrasparenteUnPixelFinoAllaSoglia;
    [Test]
    procedure DovrebbeColorareUnPixelOltreLaSogliaConIlColoreDelleImpostazioni;
    [Test]
    procedure DovrebbeMescolareSfondoEPrimoPianoInBaseAlGrigio;
    [Test]
    procedure DovrebbeAggiungereIlRumoreSoloSeLoSiChiede;
    [Test]
    procedure DovrebbeUsareSoloIColoriDelIntervalloDellaPalette;
    [Test]
    procedure DovrebbeChiedereAllaRicercaIlColoreComeRRGGBB;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteNonValidaOUnaRicercaNil;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineGrigiaPiuCortaDelleDimensioni;
  end;

implementation

uses
  DelphiDoom.Palette.ColorMatcher,
  DelphiDoom.Palette.GamePalettes,
  DelphiDoom.Tests.Sound.Digest,
  DelphiDoom.Tests.Font.Golden;

const
  GOLDEN_FILE = 'Font\font.golden.txt';

type
  /// <summary>A search that remembers what it was asked and answers with the first index of the range</summary>
  TRecordingMatcher = class(TInterfacedObject, IColorMatcher)
  public
    Colors: TArray<Cardinal>;
    LastColor: Cardinal;
    LastLow: Integer;
    LastHigh: Integer;
    Calls: Integer;
    function BestColor(ARed, AGreen, ABlue: Byte; const APalette: TBytes; ALow, AHigh: Integer): Byte;
    function FindApproximateIndex(const AColors: TArray<Cardinal>; AColor: Cardinal; ALow, AHigh: Integer): Integer;
  end;

function TRecordingMatcher.BestColor(ARed, AGreen, ABlue: Byte; const APalette: TBytes; ALow, AHigh: Integer): Byte;
begin
  Result := 0;
end;

function TRecordingMatcher.FindApproximateIndex(const AColors: TArray<Cardinal>; AColor: Cardinal; ALow,
  AHigh: Integer): Integer;
begin
  Inc(Calls);
  LastColor := AColor;
  LastLow := ALow;
  LastHigh := AHigh;
  Result := ALow;
end;

function Bytes(const AValues: array of Byte): TBytes;
begin
  SetLength(Result, Length(AValues));
  if Length(AValues) > 0 then
    Move(AValues[0], Result[0], Length(AValues));
end;

{ TTestFontColorizer }

procedure TTestFontColorizer.Setup;
begin
  FMatcher := TColorMatcher.Create;
end;

procedure TTestFontColorizer.TearDown;
begin
  FMatcher := nil;
end;

function TTestFontColorizer.GrayPalette: TFontPaletteSelection;
begin
  Result := TFontPaletteSelection.Create(TGamePalettes.ToColors(TGamePalettes.GrayscaleColors), 1, 255);
end;

function TTestFontColorizer.Indexes(const AGray: TBytes; AFront, ABack: Integer; APerlin: Boolean): TBytes;
begin
  Result := TFontColorizer.ToPaletteIndexes(AGray, Length(AGray), 1, AFront, ABack, APerlin, GrayPalette, FMatcher);
end;

procedure TTestFontColorizer.DovrebbeDareLoStessoLivelloDiGrigioDelVecchioPerOgniColore;
var
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LDigest: TSoundDigest;
  LLevel: Byte;
  LExpected: string;
begin
  LDigest := TSoundDigest.Start;
  for LRed := 0 to 255 do
    for LGreen := 0 to 255 do
      for LBlue := 0 to 255 do
      begin
        LLevel := TFontColorizer.GrayLevel(Byte(LRed), Byte(LGreen), Byte(LBlue));
        LDigest.AddBuffer(@LLevel, 1);
      end;
  LExpected := TFontGolden.Lines(GOLDEN_FILE, 'GRAY')[0];
  Assert.AreEqual(LExpected, IntToHex(LDigest.Value, 16));
end;

{$IFDEF CPUX86}
procedure TTestFontColorizer.DovrebbeDare62PerIlGrigio63ComeIlVecchioInTrentaDueBit;
begin
  // 63 * 0.299 + 63 * 0.587 + 63 * 0.114 is 62.99999... in Extended: the old tool cut it to 62
  Assert.AreEqual(62, Integer(TFontColorizer.GrayLevel(63, 63, 63)));
  Assert.AreEqual(125, Integer(TFontColorizer.GrayLevel(126, 126, 126)));
end;
{$ENDIF}

procedure TTestFontColorizer.DovrebbeDareIlLivelloDiUnPixelBiancoENero;
begin
  Assert.AreEqual(255, Integer(TFontColorizer.GrayLevel(255, 255, 255)));
  Assert.AreEqual(0, Integer(TFontColorizer.GrayLevel(0, 0, 0)));
end;

procedure TTestFontColorizer.DovrebbeLeggereIlRossoNelTerzoByteDelPixel;
var
  LImage: TFontImage;
  LGray: TBytes;
begin
  LImage := TFontImage.Create(3, 1);
  LImage.Pixels[0] := $FF0000;
  LImage.Pixels[1] := $00FF00;
  LImage.Pixels[2] := $0000FF;
  LGray := TFontColorizer.Grayscale(LImage);
  // 0.299 of 255 is 76, 0.587 is 149, 0.114 is 29 (cut)
  Assert.AreEqual(76, Integer(LGray[0]), 'rosso');
  Assert.AreEqual(149, Integer(LGray[1]), 'verde');
  Assert.AreEqual(29, Integer(LGray[2]), 'blu');
end;

procedure TTestFontColorizer.DovrebbeFareIlGrigioDiOgniPixelDellImmagine;
var
  LImage: TFontImage;
  LGray: TBytes;
begin
  LImage := TFontImage.Create(2, 2);
  LImage.Pixels[0] := $000000;
  LImage.Pixels[1] := $FFFFFF;
  LImage.Pixels[2] := $808080;
  LImage.Pixels[3] := $010101;
  LGray := TFontColorizer.Grayscale(LImage);
  Assert.AreEqual(4, Length(LGray));
  Assert.AreEqual(0, Integer(LGray[0]));
  Assert.AreEqual(255, Integer(LGray[1]));
  Assert.AreEqual(Integer(TFontColorizer.GrayLevel($80, $80, $80)), Integer(LGray[2]));
  Assert.AreEqual(Integer(TFontColorizer.GrayLevel(1, 1, 1)), Integer(LGray[3]));
end;

procedure TTestFontColorizer.DovrebbeRifiutareUnImmagineNonValida;
var
  LImage: TFontImage;
begin
  LImage.Width := 4;
  LImage.Height := 4;
  SetLength(LImage.Pixels, 3);
  Assert.WillRaise(
    procedure
    begin
      TFontColorizer.Grayscale(LImage);
    end, EFontException);
end;

procedure TTestFontColorizer.DovrebbeNonToccareLaImmagineSeIlMassimoEDi255;
var
  LGray: TBytes;
begin
  LGray := Bytes([0, 10, 255, 100]);
  TFontColorizer.StretchToMaximum(LGray);
  Assert.AreEqual(10, Integer(LGray[1]));
  Assert.AreEqual(100, Integer(LGray[3]));
end;

procedure TTestFontColorizer.DovrebbeNonToccareLaImmagineTuttaNera;
var
  LGray: TBytes;
begin
  LGray := Bytes([0, 0, 0]);
  TFontColorizer.StretchToMaximum(LGray);
  Assert.AreEqual(0, Integer(LGray[0]) + Integer(LGray[1]) + Integer(LGray[2]));
end;

procedure TTestFontColorizer.DovrebbeRenderePieno255OgniPixelNonNeroSeIlMassimoEMinore;
var
  LGray: TBytes;
begin
  // the defect of the original that is kept: the stretch multiplies the 24 bit pixel and not the level
  LGray := Bytes([0, 1, 60, 200, 254]);
  TFontColorizer.StretchToMaximum(LGray);
  Assert.AreEqual(0, Integer(LGray[0]));
  Assert.AreEqual(255, Integer(LGray[1]));
  Assert.AreEqual(255, Integer(LGray[2]));
  Assert.AreEqual(255, Integer(LGray[3]));
  Assert.AreEqual(255, Integer(LGray[4]));
end;

procedure TTestFontColorizer.DovrebbeLasciareTrasparenteUnPixelFinoAllaSoglia;
var
  LResult: TBytes;
begin
  LResult := Indexes(Bytes([0, 1, 16, 17, 255]), $FFFFFF, 0, False);
  Assert.AreEqual(0, Integer(LResult[0]));
  Assert.AreEqual(0, Integer(LResult[1]));
  Assert.AreEqual(0, Integer(LResult[2]), 'la soglia e esclusa');
  Assert.AreNotEqual(0, Integer(LResult[3]), 'sopra la soglia');
  Assert.AreNotEqual(0, Integer(LResult[4]));
end;

procedure TTestFontColorizer.DovrebbeColorareUnPixelOltreLaSogliaConIlColoreDelleImpostazioni;
var
  LResult: TBytes;
begin
  // red on black with the full gray: the nearest gray of the ramp to (255, 0, 0)... the palette is gray, so the
  // choice is the gray that is nearest to red
  LResult := Indexes(Bytes([255]), $0000FF, 0, False);
  Assert.AreEqual(FMatcher.FindApproximateIndex(GrayPalette.Colors, $FF0000, 1, 255), Integer(LResult[0]));
end;

procedure TTestFontColorizer.DovrebbeMescolareSfondoEPrimoPianoInBaseAlGrigio;
var
  LResult: TBytes;
begin
  // white on black: the color of a pixel is its gray level, and the gray palette has the same index
  LResult := Indexes(Bytes([100, 128, 200]), $FFFFFF, 0, False);
  Assert.AreEqual(100, Integer(LResult[0]));
  Assert.AreEqual(128, Integer(LResult[1]));
  Assert.AreEqual(200, Integer(LResult[2]));
  // black on white goes the other way
  LResult := Indexes(Bytes([100, 200]), 0, $FFFFFF, False);
  Assert.AreEqual(155, Integer(LResult[0]));
  Assert.AreEqual(55, Integer(LResult[1]));
end;

procedure TTestFontColorizer.DovrebbeAggiungereIlRumoreSoloSeLoSiChiede;
var
  LGray: TBytes;
  LPlain: TBytes;
  LNoisy: TBytes;
  LIndex: Integer;
  LDifferent: Integer;
begin
  SetLength(LGray, 200);
  for LIndex := 0 to 199 do
    LGray[LIndex] := 128;
  LPlain := Indexes(LGray, $FFFFFF, 0, False);
  LNoisy := Indexes(LGray, $FFFFFF, 0, True);
  LDifferent := 0;
  for LIndex := 0 to 199 do
  begin
    Assert.AreEqual(128, Integer(LPlain[LIndex]));
    if LNoisy[LIndex] <> LPlain[LIndex] then
      Inc(LDifferent);
  end;
  Assert.IsTrue(LDifferent > 100, 'il rumore cambia quasi ogni pixel');
end;

procedure TTestFontColorizer.DovrebbeUsareSoloIColoriDelIntervalloDellaPalette;
var
  LResult: TBytes;
  LIndex: Integer;
  LPalette: TFontPaletteSelection;
  LGray: TBytes;
begin
  LPalette := TFontPaletteSelection.Create(TGamePalettes.ToColors(TGamePalettes.GrayscaleColors), 16, 239);
  SetLength(LGray, 256);
  for LIndex := 0 to 255 do
    LGray[LIndex] := Byte(LIndex);
  LResult := TFontColorizer.ToPaletteIndexes(LGray, 256, 1, $FFFFFF, 0, False, LPalette, FMatcher);
  for LIndex := 0 to 255 do
    if LGray[LIndex] > FONT_COLOR_THRESHOLD then
      Assert.IsTrue((LResult[LIndex] >= 16) and (LResult[LIndex] <= 239), 'indice ' + IntToStr(LResult[LIndex]));
end;

procedure TTestFontColorizer.DovrebbeChiedereAllaRicercaIlColoreComeRRGGBB;
var
  LMatcher: TRecordingMatcher;
  LIntf: IColorMatcher;
begin
  LMatcher := TRecordingMatcher.Create;
  LIntf := LMatcher;
  // a pure red, $0000FF in a color of Windows, at full gray on black: the search gets $FF0000
  TFontColorizer.ToPaletteIndexes(Bytes([255]), 1, 1, $0000FF, 0, False, GrayPalette, LIntf);
  Assert.AreEqual(1, LMatcher.Calls);
  Assert.AreEqual(Cardinal($FF0000), LMatcher.LastColor);
  Assert.AreEqual(1, LMatcher.LastLow);
  Assert.AreEqual(255, LMatcher.LastHigh);
end;

procedure TTestFontColorizer.DovrebbeRifiutareUnaPaletteNonValidaOUnaRicercaNil;
var
  LShort: TFontPaletteSelection;
begin
  LShort := TFontPaletteSelection.Create(nil, 0, 0);
  Assert.WillRaise(
    procedure
    begin
      TFontColorizer.ToPaletteIndexes(Bytes([1]), 1, 1, 0, 0, False, LShort, FMatcher);
    end, EFontException);
  Assert.WillRaise(
    procedure
    begin
      TFontColorizer.ToPaletteIndexes(Bytes([1]), 1, 1, 0, 0, False, GrayPalette, nil);
    end, EFontException);
end;

procedure TTestFontColorizer.DovrebbeRifiutareUnaImmagineGrigiaPiuCortaDelleDimensioni;
begin
  Assert.WillRaise(
    procedure
    begin
      TFontColorizer.ToPaletteIndexes(Bytes([1, 2, 3]), 2, 2, 0, 0, False, GrayPalette, FMatcher);
    end, EFontException);
end;

end.
