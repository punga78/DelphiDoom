{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRoqJpegDecoder                                        }
{                                                                              }
{  The JPEG files are the ones of the tests of Libs\Jpeg (Tests\Data\Jpeg).     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.JpegDecoder;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqJpegDecoder = class(TObject)
  public
    [Test]
    procedure DovrebbeDareITreByteRgbDellaLibreriaJpeg;
    [Test]
    procedure DovrebbeRipetereIlGrigioNeiTreCanali;
    [Test]
    procedure DovrebbeSollevareSeIDatiSonoVuoti;
    [Test]
    procedure DovrebbeSollevareSeNonESJpeg;
    [Test]
    procedure DovrebbeSollevareSeIlJpegEMozzato;
    [Test]
    procedure DovrebbeEssereDatoDallaFabbrica;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Jpeg.Intf,
  DelphiDoom.Cinematic.Jpeg.Factory,
  DelphiDoom.Jpeg.Intf,
  DelphiDoom.Jpeg.Decoder,
  DelphiDoom.Tests.Cinematic.Support;

{ TTestRoqJpegDecoder }

procedure TTestRoqJpegDecoder.DovrebbeDareITreByteRgbDellaLibreriaJpeg;
var
  LData, LExpected, LActual: TBytes;
  LInfo: TJpegInfo;
  LWidth, LHeight: Integer;
begin
  LData := TRoqTestData.ReadJpeg('encoder-48x48-c3-q100.jpg');
  SetLength(LExpected, 48 * 48 * 3);
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(@LData[0], Length(LData), @LExpected[0],
    Length(LExpected), LInfo));
  LActual := TRoqJpegFactory.CreateDecoder.Decode(LData, LWidth, LHeight);
  Assert.AreEqual(48, LWidth);
  Assert.AreEqual(48, LHeight);
  Assert.AreEqual<Integer>(Length(LExpected), Length(LActual));
  Assert.IsTrue(CompareMem(@LExpected[0], @LActual[0], Length(LExpected)));
end;

procedure TTestRoqJpegDecoder.DovrebbeRipetereIlGrigioNeiTreCanali;
var
  LData, LRaw, LActual: TBytes;
  LInfo: TJpegInfo;
  LWidth, LHeight, LIndex: Integer;
begin
  LData := TRoqTestData.ReadJpeg('encoder-33x17-c1-q50.jpg');
  SetLength(LRaw, 33 * 17);
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(@LData[0], Length(LData), @LRaw[0], Length(LRaw), LInfo));
  Assert.AreEqual(1, LInfo.Components);
  LActual := TRoqJpegFactory.CreateDecoder.Decode(LData, LWidth, LHeight);
  Assert.AreEqual(33, LWidth);
  Assert.AreEqual(17, LHeight);
  Assert.AreEqual<Integer>(33 * 17 * 3, Length(LActual));
  for LIndex := 0 to High(LRaw) do
  begin
    Assert.AreEqual(Integer(LRaw[LIndex]), Integer(LActual[LIndex * 3]));
    Assert.AreEqual(Integer(LRaw[LIndex]), Integer(LActual[LIndex * 3 + 1]));
    Assert.AreEqual(Integer(LRaw[LIndex]), Integer(LActual[LIndex * 3 + 2]));
  end;
end;

procedure TTestRoqJpegDecoder.DovrebbeSollevareSeIDatiSonoVuoti;
begin
  Assert.WillRaise(
    procedure
    var
      LWidth, LHeight: Integer;
    begin
      TRoqJpegFactory.CreateDecoder.Decode(nil, LWidth, LHeight);
    end, ERoqInvalidDataException);
end;

procedure TTestRoqJpegDecoder.DovrebbeSollevareSeNonESJpeg;
begin
  Assert.WillRaise(
    procedure
    var
      LWidth, LHeight: Integer;
    begin
      TRoqJpegFactory.CreateDecoder.Decode(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8), LWidth, LHeight);
    end, ERoqInvalidDataException);
end;

procedure TTestRoqJpegDecoder.DovrebbeSollevareSeIlJpegEMozzato;
var
  LData: TBytes;
begin
  LData := TRoqTestData.ReadJpeg('encoder-48x48-c3-q100.jpg');
  // the header is valid, the data of the pixels are cut: the decoder of Libs\Jpeg gives pixels from
  // the end-of-image marker that it invents, so it is the size check that is not asked here; only a cut
  // inside the header is an error
  SetLength(LData, 12);
  Assert.WillRaise(
    procedure
    var
      LWidth, LHeight: Integer;
    begin
      TRoqJpegFactory.CreateDecoder.Decode(LData, LWidth, LHeight);
    end, ERoqInvalidDataException);
end;

procedure TTestRoqJpegDecoder.DovrebbeEssereDatoDallaFabbrica;
begin
  Assert.IsNotNull(TRoqJpegFactory.CreateDecoder);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqJpegDecoder);

end.
