{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - chooses the conversion of the colors                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.ColorConverterFactory;

interface

uses
  DelphiDoom.Jpeg.ColorConverter, DelphiDoom.Jpeg.Frame;

type
  /// <summary>
  ///   Gives the conversion from the color space of the stream to the one of
  ///   the output: gray stays gray, anything else is RGB
  /// </summary>
  /// <remarks>
  ///   Port of the choice of jinit_color_deconverter of libjpeg 6b for the
  ///   output spaces that the decoder asks for. Only YCbCr and RGB streams
  ///   can be turned into RGB: for the others (CMYK, YCCK, two components or
  ///   more than four) there is no conversion
  /// </remarks>
  TJpegColorConverterFactory = class
  public
    /// <summary>
    ///   The number of bytes of a pixel of the output for the stream: 1 for
    ///   gray, 3 otherwise
    /// </summary>
    class function OutputComponentsOf(AFrame: TJpegFrame): Integer; static;

    /// <exception cref="EJpegDecodeException">There is no conversion</exception>
    class function Select(AFrame: TJpegFrame): IJpegColorConverter; static;
  end;

implementation

uses
  DelphiDoom.Jpeg.GrayConverter, DelphiDoom.Jpeg.RgbConverter,
  DelphiDoom.Jpeg.Types, DelphiDoom.Jpeg.YccConverter;

{ TJpegColorConverterFactory }

class function TJpegColorConverterFactory.OutputComponentsOf(AFrame: TJpegFrame): Integer;
begin
  if AFrame.ColorSpace = jcsGrayscale then
    Result := 1
  else
    Result := 3;
end;

class function TJpegColorConverterFactory.Select(AFrame: TJpegFrame): IJpegColorConverter;
begin
  case AFrame.ColorSpace of
    jcsGrayscale:
      Result := TJpegGrayConverter.Create;
    jcsYCbCr:
      Result := TJpegYccConverter.Create;
    jcsRgb:
      Result := TJpegRgbConverter.Create;
  else
    EJpegDecodeException.Fail(jdeColorConversion);
    Result := nil;
  end;
end;

end.
