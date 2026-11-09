{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedIs2Decoder                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.Is2Decoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Speed.Intf;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedIs2Decoder = class(TObject)
  strict private
    FDecoder: ISpeedBitmapDecoder;
    function Picture(AWidth, AHeight: Integer; AFlags: Cardinal; const AData: TBytes;
      ALength: Integer = -1): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereUnaImmagineAColonne;
    [Test]
    procedure DovrebbeLeggereUnaImmagineARighe;
    [Test]
    procedure DovrebbeLasciareAduecentocinquantacinqueIPixelNonCoperti;
    [Test]
    procedure DovrebbeIgnorareIPixelOltreLaLarghezza;
    [Test]
    procedure DovrebbeRifiutareLaFirmaSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnFileCortoDellIntestazione;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineTroppoGrande;
    [Test]
    procedure DovrebbeLeggereZeroOltreLaFineDeiDati;
    [Test]
    procedure DovrebbeFinireConDatiTroncatiSenzaCicliInfiniti;
    [Test]
    procedure DovrebbeDareUnaImmagineVuotaSeLaLarghezzaEZero;
    [Test]
    procedure DovrebbeDecodificareLeImmaginiSinteticheSenzaErrori;
  end;

implementation

uses
  DelphiDoom.Speed.Types, DelphiDoom.Speed.Factory, DelphiDoom.Tests.Speed.JclBuilder;

{ TTestSpeedIs2Decoder }

procedure TTestSpeedIs2Decoder.Setup;
begin
  FDecoder := TSpeedFactory.CreateBitmapDecoder;
end;

procedure TTestSpeedIs2Decoder.TearDown;
begin
  FDecoder := nil;
end;

function TTestSpeedIs2Decoder.Picture(AWidth, AHeight: Integer; AFlags: Cardinal; const AData: TBytes;
  ALength: Integer): TBytes;
var
  LHeader: TSpeedIs2Header;
begin
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Sign := SPEED_IS2_MAGIC;
  LHeader.Width := AWidth;
  LHeader.Height := AHeight;
  LHeader.Flags := AFlags;
  if ALength < 0 then
    LHeader.Length := Length(AData)
  else
    LHeader.Length := ALength;
  SetLength(Result, SizeOf(LHeader) + Length(AData));
  Move(LHeader, Result[0], SizeOf(LHeader));
  if Length(AData) > 0 then
    Move(AData[0], Result[SizeOf(LHeader)], Length(AData));
end;

procedure TTestSpeedIs2Decoder.DovrebbeLeggereUnaImmagineAColonne;
var
  LBitmap: TSpeedBitmap;
begin
  // columns: (0: 2 pixels from the row 0), (1: 1 pixel from the row 1), (2: a pixel, a gap of 1, a pixel)
  Assert.IsTrue(FDecoder.DecodeIs2(Picture(3, 3, 0,
    TBytes.Create(0, 2, 10, 20, 0, 1, 1, 30, 0, 0, 1, 40, 1, 1, 50, 0)), LBitmap));
  Assert.AreEqual(3, LBitmap.Width);
  Assert.AreEqual(3, LBitmap.Height);
  Assert.AreEqual<TBytes>(TBytes.Create(10, 20, 255, 255, 30, 255, 40, 255, 50), LBitmap.Pixels);
end;

procedure TTestSpeedIs2Decoder.DovrebbeLeggereUnaImmagineARighe;
var
  LBitmap: TSpeedBitmap;
begin
  // rows: (0: from the column 1, one pixel), (1: from the column 0, two pixels); stored by columns
  Assert.IsTrue(FDecoder.DecodeIs2(Picture(2, 2, SPEED_IS2_HORIZONTAL,
    TBytes.Create(1, 1, 9, 0, 0, 2, 7, 8, 0)), LBitmap));
  Assert.AreEqual<TBytes>(TBytes.Create(255, 7, 9, 8), LBitmap.Pixels);
end;

procedure TTestSpeedIs2Decoder.DovrebbeLasciareAduecentocinquantacinqueIPixelNonCoperti;
var
  LBitmap: TSpeedBitmap;
  LIndex: Integer;
begin
  Assert.IsTrue(FDecoder.DecodeIs2(Picture(2, 4, 0, TBytes.Create(3, 1, 5, 0, 0, 1, 6, 0)), LBitmap));
  Assert.AreEqual(8, Length(LBitmap.Pixels));
  Assert.AreEqual<Byte>(5, LBitmap.Pixels[3]);
  Assert.AreEqual<Byte>(6, LBitmap.Pixels[4]);
  for LIndex in [0, 1, 2, 5, 6, 7] do
    Assert.AreEqual<Byte>(255, LBitmap.Pixels[LIndex], 'hole at ' + IntToStr(LIndex));
end;

procedure TTestSpeedIs2Decoder.DovrebbeIgnorareIPixelOltreLaLarghezza;
var
  LBitmap: TSpeedBitmap;
begin
  // a run of 4 pixels in a column of 2: the last two are out
  Assert.IsTrue(FDecoder.DecodeIs2(Picture(1, 2, 0, TBytes.Create(0, 4, 1, 2, 3, 4, 0)), LBitmap));
  Assert.AreEqual<TBytes>(TBytes.Create(1, 2), LBitmap.Pixels);
end;

procedure TTestSpeedIs2Decoder.DovrebbeRifiutareLaFirmaSbagliata;
var
  LBytes: TBytes;
  LBitmap: TSpeedBitmap;
begin
  LBytes := Picture(1, 1, 0, TBytes.Create(0, 1, 5, 0));
  LBytes[0] := Ord('X');
  Assert.IsFalse(FDecoder.DecodeIs2(LBytes, LBitmap));
  Assert.AreEqual(0, LBitmap.Width);
  Assert.AreEqual(0, Length(LBitmap.Pixels));
end;

procedure TTestSpeedIs2Decoder.DovrebbeRifiutareUnFileCortoDellIntestazione;
var
  LBitmap: TSpeedBitmap;
begin
  Assert.IsFalse(FDecoder.DecodeIs2(TBytes.Create(1, 2, 3), LBitmap));
  Assert.IsFalse(FDecoder.DecodeIs2(nil, LBitmap));
end;

procedure TTestSpeedIs2Decoder.DovrebbeRifiutareUnaImmagineTroppoGrande;
var
  LBitmap: TSpeedBitmap;
begin
  Assert.IsFalse(FDecoder.DecodeIs2(Picture(9000, 10, 0, TBytes.Create(0)), LBitmap));
end;

procedure TTestSpeedIs2Decoder.DovrebbeLeggereZeroOltreLaFineDeiDati;
var
  LBitmap: TSpeedBitmap;
begin
  // the header says 40 bytes of data and there are 4: what is not there is 0
  Assert.IsTrue(FDecoder.DecodeIs2(Picture(1, 3, 0, TBytes.Create(0, 1, 5, 0), 40), LBitmap));
  Assert.AreEqual<Byte>(5, LBitmap.Pixels[0]);
end;

procedure TTestSpeedIs2Decoder.DovrebbeFinireConDatiTroncatiSenzaCicliInfiniti;
var
  LBitmap: TSpeedBitmap;
  LIndex: Integer;
begin
  // every prefix of a good picture ends, and a picture that says more data than it has too
  for LIndex := 0 to 15 do
    Assert.IsTrue(FDecoder.DecodeIs2(Picture(3, 3, 0,
      Copy(TBytes.Create(0, 2, 10, 20, 0, 1, 1, 30, 0, 0, 1, 40, 1, 1, 50, 0), 0, LIndex), 16), LBitmap));
end;

procedure TTestSpeedIs2Decoder.DovrebbeDareUnaImmagineVuotaSeLaLarghezzaEZero;
var
  LBitmap: TSpeedBitmap;
begin
  Assert.IsTrue(FDecoder.DecodeIs2(Picture(0, 5, 0, nil), LBitmap));
  Assert.AreEqual(0, Length(LBitmap.Pixels));
end;

procedure TTestSpeedIs2Decoder.DovrebbeDecodificareLeImmaginiSinteticheSenzaErrori;
var
  LBitmap: TSpeedBitmap;
begin
  Assert.IsTrue(FDecoder.DecodeIs2(TJclBuilder.Is2(5, 20, 30, False), LBitmap));
  Assert.AreEqual(600, Length(LBitmap.Pixels));
  Assert.IsTrue(FDecoder.DecodeIs2(TJclBuilder.Is2(6, 20, 30, True), LBitmap));
  Assert.AreEqual(600, Length(LBitmap.Pixels));
end;

end.
