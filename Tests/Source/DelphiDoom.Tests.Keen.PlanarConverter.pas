{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - from EGA planes to pixels            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.PlanarConverter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenPlanarConverter = class(TObject)
  public
    [Test]
    procedure DovrebbeMettereIlPixelASinistraNelBitPiuAlto;
    [Test]
    procedure DovrebbeFareDelPrimoPianoIlBitMenoSignificativoDelColore;
    [Test]
    procedure DovrebbeUnireIQuattroPianiInUnColore;
    [Test]
    procedure DovrebbeLeggerePiuRigheEPiuByteDiLarghezza;
    [Test]
    procedure DovrebbePartireDaUnOffset;
    [Test]
    procedure DovrebbeLeggereLaMaschera;
    [Test]
    procedure DovrebbeSegnareITrasparenti;
    [Test]
    procedure DovrebbeComporreUnaMascheraSulloSfondo;
    [Test]
    procedure DovrebbeRifiutareDatiTroppoCorti;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNulla;
    [Test]
    procedure DovrebbeConvertireUnTileDa16;
  end;

implementation

uses
  DelphiDoom.Keen.PlanarConverter;

function Pixels(const AImage: TKeenChunkyImage): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(AImage.Pixels) do
    Result := Result + IntToHex(AImage.Pixels[LIndex], 1);
end;

{ TTestKeenPlanarConverter }

procedure TTestKeenPlanarConverter.DovrebbeMettereIlPixelASinistraNelBitPiuAlto;
var
  LImage: TKeenChunkyImage;
begin
  // only the plane 0 (blue) has the bit $80: the pixel on the left is color 1
  LImage := TKeenPlanarConverter.ToChunky(TBytes.Create($80, 0, 0, 0), 0, 1, 1);
  Assert.AreEqual(8, LImage.Width);
  Assert.AreEqual(1, LImage.Height);
  Assert.AreEqual('10000000', Pixels(LImage));
end;

procedure TTestKeenPlanarConverter.DovrebbeFareDelPrimoPianoIlBitMenoSignificativoDelColore;
begin
  Assert.AreEqual('00000001', Pixels(TKeenPlanarConverter.ToChunky(TBytes.Create($01, 0, 0, 0), 0, 1, 1)), 'blu');
  Assert.AreEqual('00000002', Pixels(TKeenPlanarConverter.ToChunky(TBytes.Create(0, $01, 0, 0), 0, 1, 1)), 'verde');
  Assert.AreEqual('00000004', Pixels(TKeenPlanarConverter.ToChunky(TBytes.Create(0, 0, $01, 0), 0, 1, 1)), 'rosso');
  Assert.AreEqual('00000008', Pixels(TKeenPlanarConverter.ToChunky(TBytes.Create(0, 0, 0, $01), 0, 1, 1)), 'intensita''');
end;

procedure TTestKeenPlanarConverter.DovrebbeUnireIQuattroPianiInUnColore;
begin
  // the plane 0: 10101010, plane 1: 11001100, plane 2: 11110000, plane 3: 00001111
  Assert.AreEqual('7654BA98',
    Pixels(TKeenPlanarConverter.ToChunky(TBytes.Create($AA, $CC, $F0, $0F), 0, 1, 1)));
end;

procedure TTestKeenPlanarConverter.DovrebbeLeggerePiuRigheEPiuByteDiLarghezza;
var
  LImage: TKeenChunkyImage;
begin
  // 2 bytes wide, 2 rows: each plane has 4 bytes (row 0: byte 0, 1; row 1: byte 2, 3); only the plane 2 (red)
  LImage := TKeenPlanarConverter.ToChunky(
    TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, $80, $01, $00, $FF, 0, 0, 0, 0), 0, 2, 2);
  Assert.AreEqual(16, LImage.Width);
  Assert.AreEqual(2, LImage.Height);
  Assert.AreEqual('4000000000000004' + '0000000044444444', Pixels(LImage));
end;

procedure TTestKeenPlanarConverter.DovrebbePartireDaUnOffset;
begin
  Assert.AreEqual('10000000',
    Pixels(TKeenPlanarConverter.ToChunky(TBytes.Create($99, $99, $80, 0, 0, 0), 2, 1, 1)));
end;

procedure TTestKeenPlanarConverter.DovrebbeLeggereLaMaschera;
var
  LImage: TKeenChunkyImage;
  LMask: TBytes;
begin
  // the mask first ($C0: the first two pixels), then the 4 planes: green $40
  LImage := TKeenPlanarConverter.ToChunkyMasked(TBytes.Create($C0, 0, $40, 0, 0), 0, 1, 1, LMask);
  Assert.AreEqual('02000000', Pixels(LImage));
  Assert.AreEqual<Integer>(8, Length(LMask));
  Assert.AreEqual(15, Integer(LMask[0]));
  Assert.AreEqual(15, Integer(LMask[1]));
  Assert.AreEqual(0, Integer(LMask[2]));
  Assert.AreEqual(0, Integer(LMask[7]));
end;

procedure TTestKeenPlanarConverter.DovrebbeSegnareITrasparenti;
var
  LImage: TKeenChunkyImage;
begin
  LImage := TKeenPlanarConverter.ToChunkyTransparent(TBytes.Create($C0, 0, 0, $20, 0), 0, 1, 1);
  Assert.AreEqual(KEEN_PIXEL_TRANSPARENT, Integer(LImage.Pixels[0]));
  Assert.AreEqual(KEEN_PIXEL_TRANSPARENT, Integer(LImage.Pixels[1]));
  Assert.AreEqual(4, Integer(LImage.Pixels[2]), 'rosso');
  Assert.AreEqual(0, Integer(LImage.Pixels[3]));
end;

procedure TTestKeenPlanarConverter.DovrebbeComporreUnaMascheraSulloSfondo;
var
  LImage: TKeenChunkyImage;
  LMask: TBytes;
  LBackground: Byte;
begin
  // the screen becomes (screen and mask) or color: where the mask is 1 the screen stays
  // the mask keeps the first pixel; the second is drawn: blue (plane 0)
  LImage := TKeenPlanarConverter.ToChunkyMasked(TBytes.Create($80, $40, 0, 0, 0), 0, 1, 1, LMask);
  LBackground := 9;
  Assert.AreEqual(9, Integer((LBackground and LMask[0]) or LImage.Pixels[0]));
  Assert.AreEqual(1, Integer((LBackground and LMask[1]) or LImage.Pixels[1]));
  Assert.AreEqual(0, Integer((LBackground and LMask[2]) or LImage.Pixels[2]));
end;

procedure TTestKeenPlanarConverter.DovrebbeRifiutareDatiTroppoCorti;
var
  LMask: TBytes;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenPlanarConverter.ToChunky(TBytes.Create(1, 2, 3), 0, 1, 1);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      TKeenPlanarConverter.ToChunky(TBytes.Create(1, 2, 3, 4), 1, 1, 1);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      TKeenPlanarConverter.ToChunkyMasked(TBytes.Create(1, 2, 3, 4), 0, 1, 1, LMask);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      TKeenPlanarConverter.ToChunky(TBytes.Create(1, 2, 3, 4), -1, 1, 1);
    end, EKeenDataException);
end;

procedure TTestKeenPlanarConverter.DovrebbeRifiutareUnaDimensioneNulla;
var
  LMask: TBytes;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenPlanarConverter.ToChunky(nil, 0, 0, 1);
    end, EKeenException);
  Assert.WillRaise(
    procedure
    begin
      TKeenPlanarConverter.ToChunkyMasked(nil, 0, 1, 0, LMask);
    end, EKeenException);
end;

procedure TTestKeenPlanarConverter.DovrebbeConvertireUnTileDa16;
var
  LPlanar: TBytes;
  LImage: TKeenChunkyImage;
begin
  // 4 planes of 16 rows of 2 bytes; the plane 3 has $FF in the last byte of the last row
  SetLength(LPlanar, KEEN_TILE16_BYTES);
  FillChar(LPlanar[0], Length(LPlanar), 0);
  LPlanar[3 * 32 + 31] := $FF;
  LImage := TKeenPlanarConverter.ToChunky(LPlanar, 0, 2, 16);
  Assert.AreEqual(16, LImage.Width);
  Assert.AreEqual(16, LImage.Height);
  Assert.AreEqual(8, Integer(LImage.Pixels[15 * 16 + 15]));
  Assert.AreEqual(8, Integer(LImage.Pixels[15 * 16 + 8]));
  Assert.AreEqual(0, Integer(LImage.Pixels[15 * 16 + 7]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenPlanarConverter);

end.
