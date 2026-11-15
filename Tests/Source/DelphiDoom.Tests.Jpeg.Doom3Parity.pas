{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the JPEG decoder with the jpeg-6 of Doom 3 (DUnitX)   }
{                                                                              }
{  Tests\Data\Jpeg\doom3\doom3.golden.txt is the output of the REAL jpeg-6 of  }
{  Doom 3 (Tools\Verifica\236b\jpeg, compiled with bcc32c) on the streams of   }
{  cases.pack, with the settings of JPEGBlit (JDCT_FASTEST, which in that      }
{  jconfig.h is the floating point IDCT, and no fancy upsampling). The decoder }
{  with TJpegDecodeOptions.Doom3 must give the same pixels.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Doom3Parity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Intf,
  DelphiDoom.Jpeg.Types, DelphiDoom.Jpeg.Decoder;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegDoom3Parity = class(TObject)
  strict private
    FFolder: string;
    class function Hash(const AData: TBytes): Cardinal; static;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareGliStessiPixelDelJpeg6DiDoom3;
    [Test]
    procedure DovrebbeDecodificareDiPiuDiDoom3ISoliFlussiProgressivi;
  end;

implementation

class function TTestJpegDoom3Parity.Hash(const AData: TBytes): Cardinal;
var
  LByte: Byte;
begin
  // FNV-1a, as jpegfast.c
  Result := 2166136261;
  for LByte in AData do
    Result := (Result xor LByte) * 16777619;
end;

procedure TTestJpegDoom3Parity.Setup;
begin
  FFolder := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..\Tests\Data\Jpeg\doom3'));
end;

procedure TTestJpegDoom3Parity.DovrebbeDareGliStessiPixelDelJpeg6DiDoom3;
var
  LPack: TFileStream;
  LGolden: TStringList;
  LLine: Integer;
  LLength: Cardinal;
  LNameBytes: TBytes;
  LName: string;
  LData: TBytes;
  LParts: TArray<string>;
  LInfo: TJpegInfo;
  LPixels: TBytes;
  LCode: Integer;
  LCompared: Integer;
  LMismatches: string;
begin
  LMismatches := '';
  LGolden := TStringList.Create;
  LPack := TFileStream.Create(TPath.Combine(FFolder, 'cases.pack'), fmOpenRead or fmShareDenyWrite);
  try
    LGolden.LoadFromFile(TPath.Combine(FFolder, 'doom3.golden.txt'), TEncoding.ANSI);
    LCompared := 0;
    for LLine := 0 to LGolden.Count - 1 do
    begin
      LPack.ReadBuffer(LLength, 4);
      SetLength(LNameBytes, LLength);
      LPack.ReadBuffer(LNameBytes[0], LLength);
      LName := TEncoding.ASCII.GetString(LNameBytes);
      LPack.ReadBuffer(LLength, 4);
      SetLength(LData, LLength);
      LPack.ReadBuffer(LData[0], LLength);
      LParts := LGolden[LLine].Split(['|']);
      Assert.AreEqual(LName, LParts[0], 'the order of the pack and of the golden');
      // Doom 3 does not decode what is in more than one scan (D_MULTISCAN_FILES_SUPPORTED is undefined in
      // its jmorecfg.h) and refuses a few other streams: there is nothing to compare for those
      if LParts[4] <> '0' then
        Continue;
      // four components (CMYK, YCCK) come out as four: this library gives gray or RGB only
      if (LParts[3] <> '1') and (LParts[3] <> '3') then
        Continue;
      LCode := TJpegDecoder.ReadInfo(@LData[0], Length(LData), LInfo);
      Assert.AreEqual(DDJPEG_OK, LCode, LName);
      SetLength(LPixels, LInfo.Width * LInfo.Height * LInfo.Components);
      LCode := TJpegDecoder.Decode(@LData[0], Length(LData), @LPixels[0], Length(LPixels), LInfo,
        TJpegDecodeOptions.Doom3);
      Assert.AreEqual(DDJPEG_OK, LCode, LName);
      Assert.AreEqual(StrToInt(LParts[1]), LInfo.Width, LName + ': width');
      Assert.AreEqual(StrToInt(LParts[2]), LInfo.Height, LName + ': height');
      Assert.AreEqual(StrToInt(LParts[3]), LInfo.Components, LName + ': components');
      // The jpeg-6 of Doom 3 is IJG 6, not 6b: when the data end before the image does (the header of this stream
      // says 65500 rows for 24 of data) it goes on decoding zero bits as symbols, 6b leaves the blocks at zero
      // (insufficient_data). The decoder here is 6b, so the pixels below the data differ by design
      if LName = 'patch-sof-height-65500' then
        Continue;
      if LParts[5] <> IntToHex(Hash(LPixels), 8) then
        LMismatches := LMismatches + ' ' + LName;
      Inc(LCompared);
    end;
    Assert.AreEqual('', LMismatches, 'streams with other pixels');
    Assert.IsTrue(LCompared >= 100, 'streams compared: ' + IntToStr(LCompared));
  finally
    LPack.Free;
    LGolden.Free;
  end;
end;

procedure TTestJpegDoom3Parity.DovrebbeDecodificareDiPiuDiDoom3ISoliFlussiProgressivi;
var
  LPack: TFileStream;
  LGolden: TStringList;
  LLine: Integer;
  LLength: Cardinal;
  LData: TBytes;
  LInfo: TJpegInfo;
  LPixels: TBytes;
  LMultiScan: Integer;
begin
  // the streams that Doom 3 cannot decode and this decoder can are only the ones in several scans
  LGolden := TStringList.Create;
  LPack := TFileStream.Create(TPath.Combine(FFolder, 'cases.pack'), fmOpenRead or fmShareDenyWrite);
  try
    LGolden.LoadFromFile(TPath.Combine(FFolder, 'doom3.golden.txt'), TEncoding.ANSI);
    LMultiScan := 0;
    for LLine := 0 to LGolden.Count - 1 do
    begin
      LPack.ReadBuffer(LLength, 4);
      LPack.Seek(LLength, soCurrent);
      LPack.ReadBuffer(LLength, 4);
      SetLength(LData, LLength);
      LPack.ReadBuffer(LData[0], LLength);
      if LGolden[LLine].Split(['|'])[4] = '0' then
        Continue;
      if (TJpegDecoder.ReadInfo(@LData[0], Length(LData), LInfo) = DDJPEG_OK) then
      begin
        SetLength(LPixels, LInfo.Width * LInfo.Height * LInfo.Components);
        if TJpegDecoder.Decode(@LData[0], Length(LData), @LPixels[0], Length(LPixels), LInfo,
          TJpegDecodeOptions.Doom3) = DDJPEG_OK then
          Inc(LMultiScan);
      end;
    end;
    Assert.IsTrue(LMultiScan > 0, 'this decoder reads streams that Doom 3 refuses');
  finally
    LPack.Free;
    LGolden.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJpegDoom3Parity);

end.
