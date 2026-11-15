{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegFloatInverseDct and of the Doom 3 settings of     }
{  the JPEG decoder (DUnitX)                                                   }
{                                                                              }
{  The pixels against the real jpeg-6 of Doom 3 are in                         }
{  DelphiDoom.Tests.Jpeg.Doom3Parity; these tests cover the pieces.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.FloatInverseDct;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Intf, DelphiDoom.Jpeg.Types,
  DelphiDoom.Jpeg.InverseDct, DelphiDoom.Jpeg.SlowInverseDct, DelphiDoom.Jpeg.FloatInverseDct,
  DelphiDoom.Jpeg.Decoder;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegFloatInverseDct = class(TObject)
  strict private
    FQuantization: array[0..JPEG_DCT_SIZE2 - 1] of Integer;
    procedure Fill;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareGrigioMedioConUnBloccoVuoto;
    [Test]
    procedure DovrebbeDareUnBloccoPiattoConSoloLaComponenteContinua;
    [Test]
    procedure DovrebbeStareVicinoAllaDctIntera;
    [Test]
    procedure DovrebbeLimitareISaturati;
    [Test]
    procedure DovrebbeUsareLeOpzioniDiDoom3;
  end;

  [TestFixture]
  [Category('jpeg')]
  TTestJpegDecodeOptions = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlDefaultDiLibjpeg;
    [Test]
    procedure DovrebbeDareLeImpostazioniDiDoom3;
    [Test]
    procedure DovrebbeScambiareRossoEBluConLOrdineRgb;
    [Test]
    procedure DovrebbeGonfiareLaCromaSenzaFiltroSeNonFancy;
  end;

implementation

procedure TTestJpegFloatInverseDct.Fill;
var
  LIndex: Integer;
begin
  for LIndex := 0 to JPEG_DCT_SIZE2 - 1 do
    FQuantization[LIndex] := 1 + LIndex mod 9;
end;

procedure TTestJpegFloatInverseDct.Setup;
begin
  Fill;
end;

procedure TTestJpegFloatInverseDct.DovrebbeDareGrigioMedioConUnBloccoVuoto;
var
  LBlock: TJpegBlock;
  LOutput: array[0..63] of Byte;
  LIndex: Integer;
begin
  FillChar(LBlock, SizeOf(LBlock), 0);
  (TJpegFloatInverseDct.Create as IJpegInverseDct).Transform(LBlock, FQuantization, @LOutput[0], 8);
  for LIndex := 0 to 63 do
    Assert.AreEqual(128, Integer(LOutput[LIndex]));
end;

procedure TTestJpegFloatInverseDct.DovrebbeDareUnBloccoPiattoConSoloLaComponenteContinua;
var
  LBlock: TJpegBlock;
  LOutput: array[0..63] of Byte;
  LIndex: Integer;
begin
  FillChar(LBlock, SizeOf(LBlock), 0);
  LBlock[0] := 16;
  FQuantization[0] := 4;
  // 16 * 4 / 8 = 8 above the middle
  (TJpegFloatInverseDct.Create as IJpegInverseDct).Transform(LBlock, FQuantization, @LOutput[0], 8);
  for LIndex := 0 to 63 do
    Assert.AreEqual(136, Integer(LOutput[LIndex]));
end;

procedure TTestJpegFloatInverseDct.DovrebbeStareVicinoAllaDctIntera;
var
  LBlock: TJpegBlock;
  LFloat: array[0..63] of Byte;
  LSlow: array[0..63] of Byte;
  LRound: Integer;
  LIndex: Integer;
  LSeed: Cardinal;
begin
  LSeed := 12345;
  for LRound := 1 to 200 do
  begin
    for LIndex := 0 to 63 do
    begin
      LSeed := LSeed * 1103515245 + 12345;
      if (LIndex = 0) or (LSeed shr 29 = 0) then
        LBlock[LIndex] := Integer((LSeed shr 16) and 127) - 63
      else
        LBlock[LIndex] := 0;
    end;
    (TJpegFloatInverseDct.Create as IJpegInverseDct).Transform(LBlock, FQuantization, @LFloat[0], 8);
    (TJpegSlowInverseDct.Create as IJpegInverseDct).Transform(LBlock, FQuantization, @LSlow[0], 8);
    for LIndex := 0 to 63 do
      Assert.IsTrue(Abs(Integer(LFloat[LIndex]) - Integer(LSlow[LIndex])) <= 2,
        Format('round %d sample %d: %d against %d', [LRound, LIndex, LFloat[LIndex], LSlow[LIndex]]));
  end;
end;

procedure TTestJpegFloatInverseDct.DovrebbeLimitareISaturati;
var
  LBlock: TJpegBlock;
  LOutput: array[0..63] of Byte;
begin
  FillChar(LBlock, SizeOf(LBlock), 0);
  LBlock[0] := 1000;
  LBlock[1] := -900;
  (TJpegFloatInverseDct.Create as IJpegInverseDct).Transform(LBlock, FQuantization, @LOutput[0], 8);
  Assert.IsTrue((LOutput[0] = 255) or (LOutput[7] = 255) or (LOutput[0] = 0) or (LOutput[7] = 0));
end;

procedure TTestJpegFloatInverseDct.DovrebbeUsareLeOpzioniDiDoom3;
var
  LData: TBytes;
  LInfo: TJpegInfo;
  LDefault: TBytes;
  LFast: TBytes;
  LCount: Integer;
begin
  LData := TFile.ReadAllBytes(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Jpeg\encoder-48x48-c3-q100.jpg')));
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.ReadInfo(@LData[0], Length(LData), LInfo));
  SetLength(LDefault, LInfo.Width * LInfo.Height * LInfo.Components);
  SetLength(LFast, Length(LDefault));
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(@LData[0], Length(LData), @LDefault[0], Length(LDefault), LInfo));
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(@LData[0], Length(LData), @LFast[0], Length(LFast), LInfo,
    TJpegDecodeOptions.Default));
  Assert.IsTrue(CompareMem(@LDefault[0], @LFast[0], Length(LDefault)), 'the default options are the old decoder');
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(@LData[0], Length(LData), @LFast[0], Length(LFast), LInfo,
    TJpegDecodeOptions.Doom3));
  LCount := Length(LFast);
  Assert.IsTrue(LCount > 0);
end;

{ TTestJpegDecodeOptions }

procedure TTestJpegDecodeOptions.DovrebbeDareIlDefaultDiLibjpeg;
begin
  Assert.IsFalse(TJpegDecodeOptions.Default.FastInverseDct);
  Assert.IsTrue(TJpegDecodeOptions.Default.FancyUpsampling);
  Assert.IsFalse(TJpegDecodeOptions.Default.RgbOrder);
end;

procedure TTestJpegDecodeOptions.DovrebbeDareLeImpostazioniDiDoom3;
begin
  Assert.IsTrue(TJpegDecodeOptions.Doom3.FastInverseDct);
  Assert.IsFalse(TJpegDecodeOptions.Doom3.FancyUpsampling);
  Assert.IsTrue(TJpegDecodeOptions.Doom3.RgbOrder);
end;

procedure TTestJpegDecodeOptions.DovrebbeScambiareRossoEBluConLOrdineRgb;
var
  LData: TBytes;
  LInfo: TJpegInfo;
  LBgr: TBytes;
  LRgb: TBytes;
  LOptions: TJpegDecodeOptions;
  LIndex: Integer;
begin
  LData := TFile.ReadAllBytes(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Jpeg\encoder-17x13-c3-q80.jpg')));
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.ReadInfo(@LData[0], Length(LData), LInfo));
  SetLength(LBgr, LInfo.Width * LInfo.Height * 3);
  SetLength(LRgb, Length(LBgr));
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(@LData[0], Length(LData), @LBgr[0], Length(LBgr), LInfo));
  LOptions := TJpegDecodeOptions.Default;
  LOptions.RgbOrder := True;
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(@LData[0], Length(LData), @LRgb[0], Length(LRgb), LInfo, LOptions));
  for LIndex := 0 to LInfo.Width * LInfo.Height - 1 do
  begin
    Assert.AreEqual(Integer(LBgr[LIndex * 3]), Integer(LRgb[LIndex * 3 + 2]));
    Assert.AreEqual(Integer(LBgr[LIndex * 3 + 1]), Integer(LRgb[LIndex * 3 + 1]));
    Assert.AreEqual(Integer(LBgr[LIndex * 3 + 2]), Integer(LRgb[LIndex * 3]));
  end;
end;

procedure TTestJpegDecodeOptions.DovrebbeGonfiareLaCromaSenzaFiltroSeNonFancy;
var
  LPack: TFileStream;
  LLength: Cardinal;
  LName: TBytes;
  LData: TBytes;
  LInfo: TJpegInfo;
  LFancy: TBytes;
  LPlain: TBytes;
  LOptions: TJpegDecodeOptions;
  LDifferent: Boolean;
  LIndex: Integer;
begin
  // a 4:2:0 image of the pack of the parity tests: replicated chroma is not the triangle filter
  LPack := TFileStream.Create(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Jpeg\doom3\cases.pack')), fmOpenRead or fmShareDenyWrite);
  try
    repeat
      LPack.ReadBuffer(LLength, 4);
      SetLength(LName, LLength);
      LPack.ReadBuffer(LName[0], LLength);
      LPack.ReadBuffer(LLength, 4);
      SetLength(LData, LLength);
      LPack.ReadBuffer(LData[0], LLength);
    until TEncoding.ASCII.GetString(LName) = 'sampling-h2v2-50x37';
  finally
    LPack.Free;
  end;
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.ReadInfo(@LData[0], Length(LData), LInfo));
  SetLength(LFancy, LInfo.Width * LInfo.Height * 3);
  SetLength(LPlain, Length(LFancy));
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(@LData[0], Length(LData), @LFancy[0], Length(LFancy), LInfo));
  LOptions := TJpegDecodeOptions.Default;
  LOptions.FancyUpsampling := False;
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(@LData[0], Length(LData), @LPlain[0], Length(LPlain), LInfo, LOptions));
  LDifferent := False;
  for LIndex := 0 to High(LFancy) do
    if LFancy[LIndex] <> LPlain[LIndex] then
      LDifferent := True;
  Assert.IsTrue(LDifferent);
end;
initialization
  TDUnitX.RegisterTestFixture(TTestJpegFloatInverseDct);
  TDUnitX.RegisterTestFixture(TTestJpegDecodeOptions);

end.
