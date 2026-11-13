{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGamePalettes (issue #167)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Palette.GamePalettes;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Palette.GamePalettes;

type
  /// <summary>
  ///   The palettes are the bytes of ff_palettes.pas of DD_FONT: the golden file has the fingerprint of the
  ///   palettes, of their ranges and of what GetPaletteFromName of the old tool gave for files of every size
  /// </summary>
  [TestFixture]
  [Category('palette')]
  TTestGamePalettes = class(TObject)
  strict private
    function Digest(const ABytes: TBytes): string;
  public
    [Test]
    procedure DovrebbeDareLePalettesDeiGiochiUgualiAlVecchio;
    [Test]
    procedure DovrebbeDareGliIntervalliUtilizzabiliDelVecchio;
    [Test]
    procedure DovrebbeDareLaScalaDiGrigiPerUnaPaletteChePiuNonCe;
    [Test]
    procedure DovrebbeLeggereUnaPaletteEsternaCometoFacevaIlVecchio;
    [Test]
    procedure DovrebbeLeggereUnFileDa1024ByteComePixelRRGGBB;
    [Test]
    procedure DovrebbeLeggereUnFileMultiploDiEntrambeLeDimensioniComeRgb;
    [Test]
    procedure DovrebbeDareLaScalaDiGrigiPerUnFileDiUnaDimensioneNonValida;
    [Test]
    procedure DovrebbeDareLaScalaDiGrigiPerUnFileVuoto;
    [Test]
    procedure DovrebbeRiconoscereIlNomeDiOgniPaletta;
    [Test]
    procedure DovrebbeRifiutareUnNomeSconosciutoOInMinuscolo;
    [Test]
    procedure DovrebbeDare768ByteACopiaPerOgniPaletta;
    [Test]
    procedure DovrebbeImpacchettareI256ColoriComeRRGGBB;
    [Test]
    procedure DovrebbeRifiutareUnaPalettePiuCortaDi768Byte;
  end;

implementation

uses
  DelphiDoom.Tests.Sound.Digest,
  DelphiDoom.Tests.Font.Golden,
  DelphiDoom.Tests.Font.Scenarios;

const
  GOLDEN_FILE = 'Palette\gamepalettes.golden.txt';

{ TTestGamePalettes }

function TTestGamePalettes.Digest(const ABytes: TBytes): string;
var
  LDigest: TSoundDigest;
begin
  LDigest := TSoundDigest.Start;
  LDigest.AddBuffer(@ABytes[0], Length(ABytes));
  Result := IntToHex(LDigest.Value, 16) + ':' + IntToStr(Length(ABytes));
end;

procedure TTestGamePalettes.DovrebbeDareLePalettesDeiGiochiUgualiAlVecchio;
var
  LLine: string;
  LWords: TArray<string>;
  LPalette: TGamePalette;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'PALETTE') do
  begin
    LWords := TFontGolden.Words(LLine);
    if StrToInt(LWords[0]) > Ord(High(TGamePalette)) then
      Continue;
    LPalette := TGamePalette(StrToInt(LWords[0]));
    Assert.AreEqual(LWords[1], Digest(TGamePalettes.Colors(LPalette)), 'palette ' + TGamePalettes.Name(LPalette));
    Inc(LCount);
  end;
  Assert.AreEqual(6, LCount);
end;

procedure TTestGamePalettes.DovrebbeDareGliIntervalliUtilizzabiliDelVecchio;
var
  LLine: string;
  LWords: TArray<string>;
  LPalette: TGamePalette;
begin
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'PALETTE') do
  begin
    LWords := TFontGolden.Words(LLine);
    if StrToInt(LWords[0]) > Ord(High(TGamePalette)) then
    begin
      Assert.AreEqual(StrToInt(LWords[2]), TGamePalettes.FirstUsableIndexOfOther);
      Assert.AreEqual(StrToInt(LWords[3]), TGamePalettes.LastUsableIndexOfOther);
      Continue;
    end;
    LPalette := TGamePalette(StrToInt(LWords[0]));
    Assert.AreEqual(StrToInt(LWords[2]), TGamePalettes.FirstUsableIndex(LPalette), 'primo ' + TGamePalettes.Name(LPalette));
    Assert.AreEqual(StrToInt(LWords[3]), TGamePalettes.LastUsableIndex(LPalette), 'ultimo ' + TGamePalettes.Name(LPalette));
  end;
end;

procedure TTestGamePalettes.DovrebbeDareLaScalaDiGrigiPerUnaPaletteChePiuNonCe;
var
  LLine: string;
  LWords: TArray<string>;
begin
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'PALETTE') do
  begin
    LWords := TFontGolden.Words(LLine);
    if LWords[0] = '6' then
      Assert.AreEqual(LWords[1], Digest(TGamePalettes.GrayscaleColors));
  end;
end;

procedure TTestGamePalettes.DovrebbeLeggereUnaPaletteEsternaCometoFacevaIlVecchio;
var
  LLine: string;
  LWords: TArray<string>;
  LKind: Integer;
  LFile: TArray<Byte>;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'PALFILE') do
  begin
    LWords := TFontGolden.Words(LLine);
    LKind := StrToInt(LWords[0]);
    LFile := TFontScenarios.ExternalPaletteFile(LKind);
    Assert.AreEqual(LWords[1], Digest(TGamePalettes.ParseExternal(TBytes(LFile))), 'file ' + LWords[0]);
    Inc(LCount);
  end;
  Assert.AreEqual(TFontScenarios.ExternalPaletteKindCount, LCount);
end;

procedure TTestGamePalettes.DovrebbeLeggereUnFileDa1024ByteComePixelRRGGBB;
var
  LFile: TBytes;
  LColors: TBytes;
  LIndex: Integer;
begin
  SetLength(LFile, 1024);
  for LIndex := 0 to 255 do
  begin
    // little endian pixel $00RRGGBB: the bytes are B, G, R, 0
    LFile[4 * LIndex] := Byte(LIndex + 2);
    LFile[4 * LIndex + 1] := Byte(LIndex + 1);
    LFile[4 * LIndex + 2] := Byte(LIndex);
    LFile[4 * LIndex + 3] := 0;
  end;
  LColors := TGamePalettes.ParseExternal(LFile);
  Assert.AreEqual(Integer(Byte(5)), Integer(LColors[3 * 5]), 'rosso');
  Assert.AreEqual(Integer(Byte(6)), Integer(LColors[3 * 5 + 1]), 'verde');
  Assert.AreEqual(Integer(Byte(7)), Integer(LColors[3 * 5 + 2]), 'blu');
end;

procedure TTestGamePalettes.DovrebbeLeggereUnFileMultiploDiEntrambeLeDimensioniComeRgb;
var
  LFile: TBytes;
  LColors: TBytes;
  LIndex: Integer;
begin
  // 3072 bytes are three palettes of 768 and also three of 1024: the old tool tried 768 first
  SetLength(LFile, 3072);
  for LIndex := 0 to 3071 do
    LFile[LIndex] := Byte(LIndex * 3);
  LColors := TGamePalettes.ParseExternal(LFile);
  Assert.AreEqual(Integer(LFile[0]), Integer(LColors[0]));
  Assert.AreEqual(Integer(LFile[767]), Integer(LColors[767]));
end;

procedure TTestGamePalettes.DovrebbeDareLaScalaDiGrigiPerUnFileDiUnaDimensioneNonValida;
var
  LFile: TBytes;
begin
  SetLength(LFile, 800);
  Assert.AreEqual(Digest(TGamePalettes.GrayscaleColors), Digest(TGamePalettes.ParseExternal(LFile)));
  SetLength(LFile, 767);
  Assert.AreEqual(Digest(TGamePalettes.GrayscaleColors), Digest(TGamePalettes.ParseExternal(LFile)));
end;

procedure TTestGamePalettes.DovrebbeDareLaScalaDiGrigiPerUnFileVuoto;
begin
  Assert.AreEqual(Digest(TGamePalettes.GrayscaleColors), Digest(TGamePalettes.ParseExternal(nil)));
end;

procedure TTestGamePalettes.DovrebbeRiconoscereIlNomeDiOgniPaletta;
var
  LPalette: TGamePalette;
  LFound: TGamePalette;
begin
  for LPalette := Low(TGamePalette) to High(TGamePalette) do
  begin
    Assert.IsTrue(TGamePalettes.TryFromName(TGamePalettes.Name(LPalette), LFound));
    Assert.AreEqual(Ord(LPalette), Ord(LFound));
  end;
  Assert.AreEqual('DOOM', TGamePalettes.Name(gpDoom));
  Assert.AreEqual('GLSPEED', TGamePalettes.Name(gpGLSpeed));
end;

procedure TTestGamePalettes.DovrebbeRifiutareUnNomeSconosciutoOInMinuscolo;
var
  LFound: TGamePalette;
begin
  Assert.IsFalse(TGamePalettes.TryFromName('OTHER', LFound));
  Assert.IsFalse(TGamePalettes.TryFromName('doom', LFound));
  Assert.IsFalse(TGamePalettes.TryFromName('', LFound));
end;

procedure TTestGamePalettes.DovrebbeDare768ByteACopiaPerOgniPaletta;
var
  LPalette: TGamePalette;
  LFirst: TBytes;
  LSecond: TBytes;
begin
  for LPalette := Low(TGamePalette) to High(TGamePalette) do
  begin
    LFirst := TGamePalettes.Colors(LPalette);
    Assert.AreEqual<Integer>(768, Length(LFirst));
    LFirst[0] := LFirst[0] xor $FF;
    LSecond := TGamePalettes.Colors(LPalette);
    Assert.AreNotEqual(Integer(LFirst[0]), Integer(LSecond[0]), 'una copia: cambiarla non cambia la palette');
  end;
end;

procedure TTestGamePalettes.DovrebbeImpacchettareI256ColoriComeRRGGBB;
var
  LColors: TArray<Cardinal>;
  LRgb: TBytes;
begin
  LRgb := TGamePalettes.Colors(gpDoom);
  LColors := TGamePalettes.ToColors(LRgb);
  Assert.AreEqual<Integer>(256, Length(LColors));
  Assert.AreEqual(Cardinal((Cardinal(LRgb[3]) shl 16) or (Cardinal(LRgb[4]) shl 8) or LRgb[5]), LColors[1]);
  Assert.AreEqual(Cardinal((Cardinal(LRgb[765]) shl 16) or (Cardinal(LRgb[766]) shl 8) or LRgb[767]), LColors[255]);
end;

procedure TTestGamePalettes.DovrebbeRifiutareUnaPalettePiuCortaDi768Byte;
var
  LShort: TBytes;
begin
  SetLength(LShort, 767);
  Assert.WillRaise(
    procedure
    begin
      TGamePalettes.ToColors(LShort);
    end, EArgumentException);
end;

end.
