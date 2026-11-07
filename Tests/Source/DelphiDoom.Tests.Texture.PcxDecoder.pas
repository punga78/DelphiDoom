{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTexturePcxDecoder and of the reader of the older      }
{  PCX files                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.PcxDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Decoder.Pcx, DelphiDoom.Tests.Texture.Samples,
  DelphiDoom.Tests.Texture.Fakes;

type
  [TestFixture]
  [Category('texture')]
  TTestTexturePcxDecoder = class(TObject)
  private
    FLog: TFakeLog;
    FLogInterface: IInterface;
    FDecoder: ITextureDecoder;
    FImage: TTextureImage;
    function IdentityTrailer: TBytes;
    function Join(const AFirst, ASecond, AThird: TBytes): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDireLaPropriaEstensione;
    [Test]
    procedure DovrebbeLeggereUnaPcxA8BitConLaPaletteInFondo;
    [Test]
    procedure DovrebbeLeggereUnaPcxA24BitInTrePiani;
    [Test]
    procedure DovrebbeTrattareIlByteC0ComeUnPixelNelLettoreDiBase;
    [Test]
    procedure DovrebbeAllargareUnaPcxA1BitAUnMultiploDiOtto;
    [Test]
    procedure DovrebbeTagliareLeRipetizioniChePassanoLaRiga;
    [Test]
    procedure DovrebbeLeggereUnaPcxVecchiaConLaPaletteAA6Bit;
    [Test]
    procedure DovrebbeLeggereUnaPcxA16ColoriConLaPaletteDiDefaultDellaVersione3;
    [Test]
    procedure DovrebbeLeggereUnaPcxA24BitDiUnaVersioneVecchia;
    [Test]
    procedure DovrebbeRifiutareUnaPcxCheNessunLettorePrende;
    [Test]
    procedure DovrebbeDareUnAvvisoPerUnaPcxCheNonSiLegge;
    [Test]
    procedure DovrebbeRifiutareUnaPcxTroncata;
    [Test]
    procedure DovrebbeRiconoscereLIntestazioneDiUnaPcx;
    [Test]
    procedure DovrebbeRifiutareLeIntestazioniNonValide;
    [Test]
    procedure DovrebbeRifiutareUnDecoderSenzaLog;
  end;

implementation

function TTestTexturePcxDecoder.IdentityTrailer: TBytes;
var
  LIndex: Integer;
begin
  // the entry i is the color (i, i, i)
  SetLength(Result, 769);
  Result[0] := $0C;
  for LIndex := 0 to 255 do
  begin
    Result[1 + LIndex * 3] := Byte(LIndex);
    Result[2 + LIndex * 3] := Byte(LIndex);
    Result[3 + LIndex * 3] := Byte(LIndex);
  end;
end;

function TTestTexturePcxDecoder.Join(const AFirst, ASecond, AThird: TBytes): TBytes;
begin
  Result := Copy(AFirst);
  Result := Result + ASecond + AThird;
end;

procedure TTestTexturePcxDecoder.Setup;
begin
  FLog := TFakeLog.Create;
  FLogInterface := FLog;
  FDecoder := TTexturePcxDecoder.Create(FLog);
  FImage := TTextureImage.Create;
end;

procedure TTestTexturePcxDecoder.TearDown;
begin
  FImage.Free;
  FDecoder := nil;
  FLogInterface := nil;
end;

procedure TTestTexturePcxDecoder.DovrebbeDireLaPropriaEstensione;
begin
  Assert.AreEqual('.PCX', FDecoder.Extension, 'dovrebbe dire .PCX');
end;

procedure TTestTexturePcxDecoder.DovrebbeLeggereUnaPcxA8BitConLaPaletteInFondo;
var
  LTrailer: TBytes;
  LData: TBytes;
begin
  LTrailer := TTextureSamples.PcxTrailer(11);
  LData := TTextureSamples.PcxLine(TBytes.Create(0, 1)) + TTextureSamples.PcxLine(TBytes.Create(2, 3));
  Assert.IsTrue(FDecoder.Decode(Join(TTextureSamples.PcxHeaderBytes(5, 8, 2, 2, 1, 2), LData, LTrailer), FImage),
    'dovrebbe riuscire');
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe dare 32 bit');
  Assert.AreEqual(2, FImage.Width, 'dovrebbe avere la larghezza dell''intestazione');
  // the first line of a PCX is the top one, the colors are the entries of the palette as R, G, B
  Assert.AreEqual((Cardinal(LTrailer[1]) shl 16) or (Cardinal(LTrailer[2]) shl 8) or LTrailer[3],
    PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe dare il colore 0 in cima a sinistra');
  Assert.AreEqual((Cardinal(LTrailer[10]) shl 16) or (Cardinal(LTrailer[11]) shl 8) or LTrailer[12],
    PTextureColorArray(FImage.PixelsPointer)^[3], 'dovrebbe dare il colore 3 in fondo a destra');
  Assert.AreEqual(Cardinal(0), FImage.TransparentColor, 'dovrebbe non avere colori trasparenti');
end;

procedure TTestTexturePcxDecoder.DovrebbeLeggereUnaPcxA24BitInTrePiani;
var
  LData: TBytes;
begin
  // a line is the red plane, the green one and the blue one
  LData := TTextureSamples.PcxLine(TBytes.Create($10, $20)) + TTextureSamples.PcxLine(TBytes.Create($30, $40)) +
    TTextureSamples.PcxLine(TBytes.Create($50, $60));
  Assert.IsTrue(FDecoder.Decode(Join(TTextureSamples.PcxHeaderBytes(5, 8, 2, 1, 3, 2), LData, nil), FImage),
    'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($103050), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe comporre il primo pixel');
  Assert.AreEqual(Cardinal($204060), PTextureColorArray(FImage.PixelsPointer)^[1], 'dovrebbe comporre il secondo pixel');
end;

procedure TTestTexturePcxDecoder.DovrebbeTrattareIlByteC0ComeUnPixelNelLettoreDiBase;
begin
  // a byte up to $C0 is itself for the main reader (the others would take it for a run of 0)
  Assert.IsTrue(FDecoder.Decode(Join(TTextureSamples.PcxHeaderBytes(5, 8, 2, 1, 1, 2), TBytes.Create($C0, 5),
    IdentityTrailer), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($C0C0C0), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe dare $C0 come pixel');
  Assert.AreEqual(Cardinal($050505), PTextureColorArray(FImage.PixelsPointer)^[1], 'dovrebbe leggere il byte dopo come pixel');
end;

procedure TTestTexturePcxDecoder.DovrebbeAllargareUnaPcxA1BitAUnMultiploDiOtto;
begin
  // 10 pixels: 2 bytes per line; the image gets 16 pixels
  Assert.IsTrue(FDecoder.Decode(Join(TTextureSamples.PcxHeaderBytes(5, 1, 10, 1, 1, 2), TBytes.Create($80, $00),
    IdentityTrailer), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(16, FImage.Width, 'dovrebbe allargare a un multiplo di 8');
  Assert.AreEqual(Cardinal($010101), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe dare il colore 1 per il bit acceso');
  Assert.AreEqual(Cardinal(0), PTextureColorArray(FImage.PixelsPointer)^[1], 'dovrebbe dare il colore 0 per il bit spento');
end;

procedure TTestTexturePcxDecoder.DovrebbeTagliareLeRipetizioniChePassanoLaRiga;
begin
  // a run of 6 in a line of 4 pixels: the part that goes over the line is dropped
  Assert.IsTrue(FDecoder.Decode(Join(TTextureSamples.PcxHeaderBytes(5, 8, 4, 2, 1, 4), TBytes.Create($C6, 7, 1, 2, 3, 4),
    IdentityTrailer), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($070707), PTextureColorArray(FImage.PixelsPointer)^[3], 'dovrebbe riempire la prima riga');
  Assert.AreEqual(Cardinal($010101), PTextureColorArray(FImage.PixelsPointer)^[4], 'dovrebbe cominciare la seconda riga dai suoi byte');
end;

procedure TTestTexturePcxDecoder.DovrebbeLeggereUnaPcxVecchiaConLaPaletteAA6Bit;
var
  LTrailer: TBytes;
begin
  // a version 3 file goes to the second reader: the entries are cut to 6 bits and
  // given back as (value div 4) * 4 + 3, so the color (255, 0, 100) is (255, 3, 103)
  LTrailer := IdentityTrailer;
  LTrailer[1 + 5 * 3] := 255;
  LTrailer[2 + 5 * 3] := 0;
  LTrailer[3 + 5 * 3] := 100;
  Assert.IsTrue(FDecoder.Decode(Join(TTextureSamples.PcxHeaderBytes(3, 8, 2, 1, 1, 2), TBytes.Create(5, 0), LTrailer), FImage),
    'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($FF0367), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe dare il colore a 6 bit');
  Assert.AreEqual(Cardinal($030303), PTextureColorArray(FImage.PixelsPointer)^[1], 'dovrebbe dare il nero come 3, 3, 3');
end;

procedure TTestTexturePcxDecoder.DovrebbeLeggereUnaPcxA16ColoriConLaPaletteDiDefaultDellaVersione3;
begin
  // 4 planes of 1 bit: the plane 0 all on gives the index 1, which is (0, 0, 32) in the default palette
  // (the byte $FF of the first plane goes after a count, as the encoders do)
  Assert.IsTrue(FDecoder.Decode(Join(TTextureSamples.PcxHeaderBytes(3, 1, 8, 1, 4, 1), TBytes.Create($C1, $FF, 0, 0, 0), nil),
    FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($030383), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe dare il blu scuro');
  Assert.AreEqual(8, FImage.Width, 'dovrebbe avere 8 pixel');
end;

procedure TTestTexturePcxDecoder.DovrebbeLeggereUnaPcxA24BitDiUnaVersioneVecchia;
var
  LData: TBytes;
begin
  LData := TTextureSamples.PcxLine(TBytes.Create($10, $20)) + TTextureSamples.PcxLine(TBytes.Create($30, $40)) +
    TTextureSamples.PcxLine(TBytes.Create($50, $60));
  Assert.IsTrue(FDecoder.Decode(Join(TTextureSamples.PcxHeaderBytes(3, 8, 2, 1, 3, 2), LData, nil), FImage),
    'dovrebbe riuscire');
  Assert.AreEqual(Cardinal($103050), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe comporre il primo pixel senza cambiare i colori');
end;

procedure TTestTexturePcxDecoder.DovrebbeRifiutareUnaPcxCheNessunLettorePrende;
begin
  // 4 bits, one plane: the old code answered true with a blank image
  Assert.IsFalse(FDecoder.Decode(Join(TTextureSamples.PcxHeaderBytes(5, 4, 8, 2, 1, 4), TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8), nil),
    FImage), 'dovrebbe dare false');
end;

procedure TTestTexturePcxDecoder.DovrebbeDareUnAvvisoPerUnaPcxCheNonSiLegge;
var
  LBytes: TBytes;
begin
  LBytes := Join(TTextureSamples.PcxHeaderBytes(5, 8, 2, 1, 1, 2), TBytes.Create(1, 2), TTextureSamples.PcxTrailer(1));
  LBytes[0] := $0B;
  Assert.IsFalse(FDecoder.Decode(LBytes, FImage), 'dovrebbe dare false');
  Assert.AreEqual(1, FLog.Warnings.Count, 'dovrebbe dare un avviso');
  Assert.IsTrue(FLog.Warnings[0].Contains('TPCXTextureManager()'), 'dovrebbe dire chi lo da');
  Assert.IsTrue(FLog.Warnings[0].Contains('identification byte'), 'dovrebbe dire il motivo del lettore di base');
end;

procedure TTestTexturePcxDecoder.DovrebbeRifiutareUnaPcxTroncata;
begin
  Assert.IsFalse(FDecoder.Decode(TTextureSamples.PcxHeaderBytes(5, 8, 8, 4, 1, 8), FImage), 'dovrebbe rifiutare un file di sola intestazione');
  Assert.IsFalse(FDecoder.Decode(nil, FImage), 'dovrebbe rifiutare un file vuoto');
  Assert.IsFalse(FDecoder.Decode(Join(TTextureSamples.PcxHeaderBytes(5, 8, 4, 4, 3, 4), TBytes.Create(1, 2, 3), nil), FImage),
    'dovrebbe rifiutare dati che finiscono prima dell''immagine');
end;

procedure TTestTexturePcxDecoder.DovrebbeRiconoscereLIntestazioneDiUnaPcx;
begin
  Assert.IsTrue(TTexturePcxDecoder.IsValidHeader(TTextureSamples.PcxHeaderBytes(5, 8, 64, 64, 1, 64)), 'dovrebbe riconoscere 8 bit');
  Assert.IsTrue(TTexturePcxDecoder.IsValidHeader(TTextureSamples.PcxHeaderBytes(3, 1, 16, 8, 4, 2)), 'dovrebbe riconoscere 4 piani da 1 bit');
  Assert.IsTrue(TTexturePcxDecoder.IsValidHeader(TTextureSamples.PcxHeaderBytes(5, 8, 16, 8, 3, 16)), 'dovrebbe riconoscere 24 bit');
end;

procedure TTestTexturePcxDecoder.DovrebbeRifiutareLeIntestazioniNonValide;
var
  LHeader: TBytes;
begin
  LHeader := TTextureSamples.PcxHeaderBytes(5, 8, 64, 64, 1, 64);
  LHeader[0] := $0B;
  Assert.IsFalse(TTexturePcxDecoder.IsValidHeader(LHeader), 'dovrebbe rifiutare un identificatore sbagliato');
  Assert.IsFalse(TTexturePcxDecoder.IsValidHeader(TTextureSamples.PcxHeaderBytes(1, 8, 64, 64, 1, 64)), 'dovrebbe rifiutare la versione 1');
  Assert.IsFalse(TTexturePcxDecoder.IsValidHeader(TTextureSamples.PcxHeaderBytes(5, 8, 1, 64, 1, 2)), 'dovrebbe rifiutare la larghezza 1');
  Assert.IsFalse(TTexturePcxDecoder.IsValidHeader(TTextureSamples.PcxHeaderBytes(5, 8, 64, 1, 1, 64)), 'dovrebbe rifiutare l''altezza 1');
  Assert.IsFalse(TTexturePcxDecoder.IsValidHeader(TTextureSamples.PcxHeaderBytes(5, 8, 4096, 64, 1, 4096)), 'dovrebbe rifiutare una larghezza oltre 4095');
  Assert.IsFalse(TTexturePcxDecoder.IsValidHeader(TTextureSamples.PcxHeaderBytes(5, 8, 64, 8193, 1, 64)), 'dovrebbe rifiutare un''altezza oltre 8192');
  Assert.IsFalse(TTexturePcxDecoder.IsValidHeader(TTextureSamples.PcxHeaderBytes(5, 2, 64, 64, 3, 64)),
    'dovrebbe rifiutare 6 bit per pixel in tutto');
  Assert.IsFalse(TTexturePcxDecoder.IsValidHeader(TBytes.Create(10, 5)), 'dovrebbe rifiutare un blocco di meno di 128 byte');
end;

procedure TTestTexturePcxDecoder.DovrebbeRifiutareUnDecoderSenzaLog;
begin
  Assert.WillRaise(
    procedure
    begin
      TTexturePcxDecoder.Create(nil);
    end, EArgumentNilException, 'dovrebbe rifiutare un log nil');
end;

end.
