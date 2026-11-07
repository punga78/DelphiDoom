{******************************************************************************}
{                                                                              }
{  DDJpeg.dll: JPEG for DelphiDoom                                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDJpeg;

uses
  DelphiDoom.Jpeg.Intf in 'DelphiDoom.Jpeg.Intf.pas',
  DelphiDoom.Jpeg.Types in 'DelphiDoom.Jpeg.Types.pas',
  DelphiDoom.Jpeg.ByteSource in 'DelphiDoom.Jpeg.ByteSource.pas',
  DelphiDoom.Jpeg.Frame in 'DelphiDoom.Jpeg.Frame.pas',
  DelphiDoom.Jpeg.MarkerReader in 'DelphiDoom.Jpeg.MarkerReader.pas',
  DelphiDoom.Jpeg.HuffmanTable in 'DelphiDoom.Jpeg.HuffmanTable.pas',
  DelphiDoom.Jpeg.BitReader in 'DelphiDoom.Jpeg.BitReader.pas',
  DelphiDoom.Jpeg.EntropyDecoder in 'DelphiDoom.Jpeg.EntropyDecoder.pas',
  DelphiDoom.Jpeg.EntropyDecoderBase in 'DelphiDoom.Jpeg.EntropyDecoderBase.pas',
  DelphiDoom.Jpeg.SequentialDecoder in 'DelphiDoom.Jpeg.SequentialDecoder.pas',
  DelphiDoom.Jpeg.ProgressiveDecoder in 'DelphiDoom.Jpeg.ProgressiveDecoder.pas',
  DelphiDoom.Jpeg.InverseDct in 'DelphiDoom.Jpeg.InverseDct.pas',
  DelphiDoom.Jpeg.SlowInverseDct in 'DelphiDoom.Jpeg.SlowInverseDct.pas',
  DelphiDoom.Jpeg.ComponentBuffers in 'DelphiDoom.Jpeg.ComponentBuffers.pas',
  DelphiDoom.Jpeg.RowUpsampler in 'DelphiDoom.Jpeg.RowUpsampler.pas',
  DelphiDoom.Jpeg.ReplicatingUpsampler in 'DelphiDoom.Jpeg.ReplicatingUpsampler.pas',
  DelphiDoom.Jpeg.FancyUpsamplerH2V1 in 'DelphiDoom.Jpeg.FancyUpsamplerH2V1.pas',
  DelphiDoom.Jpeg.FancyUpsamplerH2V2 in 'DelphiDoom.Jpeg.FancyUpsamplerH2V2.pas',
  DelphiDoom.Jpeg.ColorConverter in 'DelphiDoom.Jpeg.ColorConverter.pas',
  DelphiDoom.Jpeg.GrayConverter in 'DelphiDoom.Jpeg.GrayConverter.pas',
  DelphiDoom.Jpeg.RgbConverter in 'DelphiDoom.Jpeg.RgbConverter.pas',
  DelphiDoom.Jpeg.YccConverter in 'DelphiDoom.Jpeg.YccConverter.pas',
  DelphiDoom.Jpeg.ColorConverterFactory in 'DelphiDoom.Jpeg.ColorConverterFactory.pas',
  DelphiDoom.Jpeg.RowRenderer in 'DelphiDoom.Jpeg.RowRenderer.pas',
  DelphiDoom.Jpeg.BlockSmoother in 'DelphiDoom.Jpeg.BlockSmoother.pas',
  DelphiDoom.Jpeg.McuTarget in 'DelphiDoom.Jpeg.McuTarget.pas',
  DelphiDoom.Jpeg.CoefficientTarget in 'DelphiDoom.Jpeg.CoefficientTarget.pas',
  DelphiDoom.Jpeg.SampleTarget in 'DelphiDoom.Jpeg.SampleTarget.pas',
  DelphiDoom.Jpeg.Decompressor in 'DelphiDoom.Jpeg.Decompressor.pas',
  DelphiDoom.Jpeg.Decoder in 'DelphiDoom.Jpeg.Decoder.pas',
  DelphiDoom.Jpeg.Encoder in 'DelphiDoom.Jpeg.Encoder.pas',
  DelphiDoom.Jpeg.Engine in 'DelphiDoom.Jpeg.Engine.pas';

function DDJpegCreate(out AJpeg: IJpeg): Integer; stdcall;
begin
  AJpeg := nil;
  try
    AJpeg := TJpegEngine.Create;
    Result := DDJPEG_OK;
  except
    Result := DDJPEG_ERR_MEMORY;
  end;
end;

exports
  DDJpegCreate;

begin
end.
