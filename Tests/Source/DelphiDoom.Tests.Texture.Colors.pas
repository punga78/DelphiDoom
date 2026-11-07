{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureColors                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Colors;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Colors;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureColors = class(TObject)
  public
    [Test]
    procedure DovrebbeSpostareOgniCampoDiUnPixelA15BitDiTreBit;
    [Test]
    procedure DovrebbeIgnorareIlBitAltoDiUnPixelA15Bit;
    [Test]
    procedure DovrebbeConvertireTuttiIPixelA15BitDiversiDaZero;
    [Test]
    procedure DovrebbeScambiareRossoEBluLasciandoGliAltriByte;
    [Test]
    procedure DovrebbeFareLaMediaDeiTreCanaliPerIlGrigio;
    [Test]
    procedure DovrebbeLeggereUnaVoceDiPaletteInBgr8;
    [Test]
    procedure DovrebbePrendereIlBluDeiPaletteInBgr5DaiBitAltiDellaDoppiaParola;
  end;

implementation

procedure TTestTextureColors.DovrebbeSpostareOgniCampoDiUnPixelA15BitDiTreBit;
begin
  // 0rrrrrgggggbbbbb: the fields are 5 bits, the result has them in the top of each byte
  Assert.AreEqual(Cardinal($F8F8F8), TTextureColors.Pixel15To24($7FFF), 'dovrebbe dare il bianco');
  Assert.AreEqual(Cardinal($080808), TTextureColors.Pixel15To24($0421), 'dovrebbe dare 1 per campo');
  Assert.AreEqual(Cardinal($F80000), TTextureColors.Pixel15To24(31 shl 10), 'dovrebbe dare il campo alto nel terzo byte');
  Assert.AreEqual(Cardinal($00F800), TTextureColors.Pixel15To24(31 shl 5), 'dovrebbe dare il campo medio nel secondo byte');
  Assert.AreEqual(Cardinal($0000F8), TTextureColors.Pixel15To24(31), 'dovrebbe dare il campo basso nel primo byte');
end;

procedure TTestTextureColors.DovrebbeIgnorareIlBitAltoDiUnPixelA15Bit;
begin
  Assert.AreEqual(Cardinal(0), TTextureColors.Pixel15To24($8000), 'dovrebbe ignorare il bit 15');
  Assert.AreEqual(Cardinal($F8F8F8), TTextureColors.Pixel15To24($FFFF), 'dovrebbe dare lo stesso colore con o senza il bit 15');
end;

procedure TTestTextureColors.DovrebbeConvertireTuttiIPixelA15BitDiversiDaZero;
var
  LWord: Integer;
begin
  // regression: the old assembler (xor eax, eax before reading its parameter) gave 0 for each one
  for LWord := 1 to $7FFF do
    if TTextureColors.Pixel15To24(Word(LWord)) = 0 then
      Assert.Fail('dovrebbe dare un colore per la parola ' + IntToHex(LWord, 4));
  Assert.Pass;
end;

procedure TTestTextureColors.DovrebbeScambiareRossoEBluLasciandoGliAltriByte;
begin
  Assert.AreEqual(Cardinal($FF332211), TTextureColors.SwapRedBlue($FF112233), 'dovrebbe scambiare il primo e il terzo byte');
  Assert.AreEqual(Cardinal($0000FF), TTextureColors.SwapRedBlue($FF0000), 'dovrebbe portare il rosso nel blu');
end;

procedure TTestTextureColors.DovrebbeFareLaMediaDeiTreCanaliPerIlGrigio;
begin
  Assert.AreEqual(Cardinal(0), TTextureColors.Gray($000000), 'dovrebbe dare 0 per il nero');
  Assert.AreEqual(Cardinal(255), TTextureColors.Gray($FFFFFF), 'dovrebbe dare 255 per il bianco');
  Assert.AreEqual(Cardinal(20), TTextureColors.Gray($0A141E), 'dovrebbe fare la media di 10, 20 e 30');
end;

procedure TTestTextureColors.DovrebbeLeggereUnaVoceDiPaletteInBgr8;
begin
  // the bytes of the file are B, G, R and one of the next entry: the entry is $00RRGGBB
  Assert.AreEqual(Cardinal($CCBBAA), TTextureColors.PaletteEntry($FFCCBBAA, TTexturePaletteLayout.Bgr8),
    'dovrebbe ignorare il quarto byte');
end;

procedure TTestTextureColors.DovrebbePrendereIlBluDeiPaletteInBgr5DaiBitAltiDellaDoppiaParola;
begin
  // red from the bits 10..14, green from 5..9; the blue is taken from the bits 29..31 and
  // masked with $F8, so it is always 0 (the old code did the same: kept)
  Assert.AreEqual(Cardinal($F8F800), TTextureColors.PaletteEntry($00007FE0, TTexturePaletteLayout.Bgr5) and $FFFF00);
  Assert.AreEqual(Cardinal(0), TTextureColors.PaletteEntry($E0000000, TTexturePaletteLayout.Bgr5) and $0000FF,
    'dovrebbe dare sempre 0 per il blu');
  Assert.AreEqual(Cardinal(0), TTextureColors.PaletteEntry($FFFFFFFF, TTexturePaletteLayout.Bgr5) and $0000FF,
    'dovrebbe dare 0 per il blu anche con tutti i bit');
end;

end.
