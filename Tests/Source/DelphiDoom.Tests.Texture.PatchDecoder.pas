{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTexturePatchDecoder                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.PatchDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Colors, DelphiDoom.Texture.Decoder.Patch,
  DelphiDoom.Tests.Texture.Samples, DelphiDoom.Tests.Texture.Fakes;

type
  [TestFixture]
  [Category('texture')]
  TTestTexturePatchDecoder = class(TObject)
  private
    FDecoder: ITextureDecoder;
    FImage: TTextureImage;
    function Expected(AIndex: Byte): Cardinal;
    function Patch(AWidth, AHeight: Integer; const AColumns: TArray<TBytes>): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDireLaPropriaEstensione;
    [Test]
    procedure DovrebbeColorareIPixelDeiPostEMettereZeroGliAltri;
    [Test]
    procedure DovrebbeTenereGliOffsetDellaPatch;
    [Test]
    procedure DovrebbeSommareIDeltaDiUnaColonnaAlta;
    [Test]
    procedure DovrebbeScartareIPixelFuoriDallAltezza;
    [Test]
    procedure DovrebbeRifiutareUnaColonnaFuoriDalLump;
    [Test]
    procedure DovrebbeRifiutareUnPostCheEsceDalLump;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaPiuLungaDelLump;
    [Test]
    procedure DovrebbeRifiutareLeDimensioniNonValide;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteNil;
    [Test]
    procedure DovrebbeRifiutareUnaPatchSenzaPaletteCompleta;
  end;

implementation

type
  TShortPalette = class(TInterfacedObject, ITexturePaletteSource)
  public
    function GetColors: TTexturePixels;
  end;

function TShortPalette.GetColors: TTexturePixels;
begin
  SetLength(Result, 3);
end;

function TTestTexturePatchDecoder.Expected(AIndex: Byte): Cardinal;
begin
  // the color of the palette with the alpha, red and blue exchanged
  Result := TTextureColors.SwapRedBlue(TTextureSamples.GamePalette[AIndex] or $FF000000);
end;

// AColumns: the bytes of each column, from the first post to the $FF that ends it
function TTestTexturePatchDecoder.Patch(AWidth, AHeight: Integer; const AColumns: TArray<TBytes>): TBytes;
var
  LColumn, LOffset: Integer;
begin
  Result := TBytes.Create(Byte(AWidth), Byte(AWidth shr 8), Byte(AHeight), Byte(AHeight shr 8), 3, 0, 2, 0);
  LOffset := 8 + AWidth * 4;
  for LColumn := 0 to AWidth - 1 do
  begin
    Result := Result + TBytes.Create(Byte(LOffset), Byte(LOffset shr 8), 0, 0);
    Inc(LOffset, Length(AColumns[LColumn]));
  end;
  for LColumn := 0 to AWidth - 1 do
    Result := Result + AColumns[LColumn];
end;

procedure TTestTexturePatchDecoder.Setup;
begin
  FDecoder := TTexturePatchDecoder.Create(TFakePaletteSource.Create);
  FImage := TTextureImage.Create;
end;

procedure TTestTexturePatchDecoder.TearDown;
begin
  FImage.Free;
end;

procedure TTestTexturePatchDecoder.DovrebbeDireLaPropriaEstensione;
begin
  Assert.AreEqual('.PATCH', FDecoder.Extension, 'dovrebbe dire .PATCH');
end;

procedure TTestTexturePatchDecoder.DovrebbeColorareIPixelDeiPostEMettereZeroGliAltri;
begin
  // 2x4: the column 0 has a post at the row 1 with 2 pixels; the column 1 has none
  Assert.IsTrue(FDecoder.Decode(Patch(2, 4, TArray<TBytes>.Create(TBytes.Create(1, 2, 0, 20, 21, 0, $FF), TBytes.Create($FF))),
    FImage), 'dovrebbe riuscire');
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe dare 32 bit');
  Assert.AreEqual(Cardinal(0), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe dare 0 sopra il post');
  Assert.AreEqual(Expected(20), PTextureColorArray(FImage.PixelsPointer)^[2], 'dovrebbe colorare il primo pixel del post');
  Assert.AreEqual(Expected(21), PTextureColorArray(FImage.PixelsPointer)^[4], 'dovrebbe colorare il secondo');
  Assert.AreEqual(Cardinal(0), PTextureColorArray(FImage.PixelsPointer)^[3], 'dovrebbe dare 0 nella colonna senza post');
  Assert.AreEqual(Cardinal(0), PTextureColorArray(FImage.PixelsPointer)^[6], 'dovrebbe dare 0 sotto il post');
end;

procedure TTestTexturePatchDecoder.DovrebbeTenereGliOffsetDellaPatch;
begin
  Assert.IsTrue(FDecoder.Decode(Patch(1, 1, TArray<TBytes>.Create(TBytes.Create($FF))), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(3, FImage.LeftOffset, 'dovrebbe tenere l''offset a sinistra');
  Assert.AreEqual(2, FImage.TopOffset, 'dovrebbe tenere l''offset in alto');
  Assert.IsTrue(FImage.HasOffsets, 'dovrebbe avere gli offset');
end;

procedure TTestTexturePatchDecoder.DovrebbeSommareIDeltaDiUnaColonnaAlta;
begin
  // three posts of a tall column: the deltas of the second and the third are added up (the first
  // is 10, the next one is lower so the rule of the tall patches starts: 10 + 2 = 12, then 12 + 3 = 15)
  Assert.IsTrue(FDecoder.Decode(Patch(1, 20, TArray<TBytes>.Create(TBytes.Create(10, 1, 0, 1, 0, 2, 1, 0, 2, 0, 3, 1, 0, 3, 0, $FF))),
    FImage), 'dovrebbe riuscire');
  Assert.AreEqual(Expected(1), PTextureColorArray(FImage.PixelsPointer)^[10], 'dovrebbe colorare la riga del primo post');
  Assert.AreEqual(Expected(2), PTextureColorArray(FImage.PixelsPointer)^[12], 'dovrebbe sommare il delta del secondo');
  Assert.AreEqual(Expected(3), PTextureColorArray(FImage.PixelsPointer)^[15], 'dovrebbe sommare il delta del terzo');
end;

procedure TTestTexturePatchDecoder.DovrebbeScartareIPixelFuoriDallAltezza;
begin
  // a post of 4 pixels that begins 2 rows from the bottom of an image of 4 rows
  Assert.IsTrue(FDecoder.Decode(Patch(1, 4, TArray<TBytes>.Create(TBytes.Create(2, 4, 0, 1, 2, 3, 4, 0, $FF))), FImage),
    'dovrebbe riuscire');
  Assert.AreEqual(Expected(2), PTextureColorArray(FImage.PixelsPointer)^[3], 'dovrebbe colorare i pixel dentro');
  Assert.AreEqual<Integer>(16, Length(FImage.Pixels), 'dovrebbe tenere la dimensione');
end;

procedure TTestTexturePatchDecoder.DovrebbeRifiutareUnaColonnaFuoriDalLump;
var
  LBytes: TBytes;
begin
  LBytes := Patch(1, 4, TArray<TBytes>.Create(TBytes.Create($FF)));
  LBytes[8] := $FF;
  LBytes[9] := $7F;
  Assert.IsFalse(FDecoder.Decode(LBytes, FImage), 'dovrebbe dare false (il vecchio codice leggeva la memoria dopo il lump)');
end;

procedure TTestTexturePatchDecoder.DovrebbeRifiutareUnPostCheEsceDalLump;
begin
  Assert.IsFalse(FDecoder.Decode(Patch(1, 4, TArray<TBytes>.Create(TBytes.Create(0, 200, 0, 1, 2))), FImage),
    'dovrebbe dare false per un post di 200 pixel in un lump che ne ha 2');
end;

procedure TTestTexturePatchDecoder.DovrebbeRifiutareUnaTabellaPiuLungaDelLump;
begin
  Assert.IsFalse(FDecoder.Decode(TBytes.Create(8, 0, 8, 0, 0, 0, 0, 0, 1, 0, 0, 0), FImage),
    'dovrebbe dare false: la tabella delle colonne esce dal lump');
end;

procedure TTestTexturePatchDecoder.DovrebbeRifiutareLeDimensioniNonValide;
begin
  Assert.IsFalse(FDecoder.Decode(TBytes.Create(0, 0, 8, 0, 0, 0, 0, 0), FImage), 'dovrebbe rifiutare la larghezza 0');
  Assert.IsFalse(FDecoder.Decode(TBytes.Create(8, 0, 0, 0, 0, 0, 0, 0), FImage), 'dovrebbe rifiutare l''altezza 0');
  Assert.IsFalse(FDecoder.Decode(TBytes.Create($01, $30, 8, 0, 0, 0, 0, 0), FImage), 'dovrebbe rifiutare una larghezza oltre 8192');
  Assert.IsFalse(FDecoder.Decode(TBytes.Create(8, 0, $01, $04, 0, 0, 0, 0), FImage), 'dovrebbe rifiutare un''altezza oltre 1024');
  Assert.IsFalse(FDecoder.Decode(TBytes.Create($FF, $FF, 8, 0, 0, 0, 0, 0), FImage), 'dovrebbe rifiutare una larghezza negativa');
  Assert.IsFalse(FDecoder.Decode(TBytes.Create(1, 2, 3), nil), 'dovrebbe rifiutare un lump di meno di 8 byte');
end;

procedure TTestTexturePatchDecoder.DovrebbeRifiutareUnaPaletteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TTexturePatchDecoder.Create(nil);
    end, EArgumentNilException, 'dovrebbe rifiutare una palette nil');
end;

procedure TTestTexturePatchDecoder.DovrebbeRifiutareUnaPatchSenzaPaletteCompleta;
var
  LDecoder: ITextureDecoder;
begin
  LDecoder := TTexturePatchDecoder.Create(TShortPalette.Create);
  Assert.IsFalse(LDecoder.Decode(Patch(1, 1, TArray<TBytes>.Create(TBytes.Create($FF))), FImage),
    'dovrebbe dare false con meno di 256 colori');
end;

end.
