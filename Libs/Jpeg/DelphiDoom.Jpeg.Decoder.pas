{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the decoder as the engine calls it                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Decoder;

interface

uses
  DelphiDoom.Jpeg.Intf;

type
  /// <summary>
  ///   Decodes the JPEG stream that is in a buffer into a buffer of pixels,
  ///   and answers with result codes (DDJPEG_*) instead of exceptions
  /// </summary>
  /// <remarks>
  ///   One decompressor is made for every call, so nothing is shared between
  ///   two calls
  /// </remarks>
  TJpegDecoder = class
  private
    class function Run(ASource: Pointer; ASourceSize: Cardinal; out AInfo: TJpegInfo;
      ADest: Pointer; ADestSize: Cardinal; ADecodePixels: Boolean): Integer; static;
  public
    /// <summary>
    ///   Version of the library whose decoder this is
    /// </summary>
    class function Version: PAnsiChar; static;

    /// <summary>
    ///   Reads the header of the stream in ASource
    /// </summary>
    /// <returns>DDJPEG_OK or the code of the error found</returns>
    class function ReadInfo(ASource: Pointer; ASourceSize: Cardinal;
      out AInfo: TJpegInfo): Integer; static;

    /// <summary>
    ///   Decodes the stream in ASource into ADest (ADestSize bytes). AInfo is
    ///   filled as soon as the header is read. Pixels are written as TJpegInfo
    ///   describes
    /// </summary>
    /// <returns>DDJPEG_OK or the code of the error found</returns>
    class function Decode(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      ADestSize: Cardinal; out AInfo: TJpegInfo): Integer; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Jpeg.Decompressor, DelphiDoom.Jpeg.Types;

const
  LIBRARY_VERSION: PAnsiChar = '6b';

{ TJpegDecoder }

class function TJpegDecoder.Version: PAnsiChar;
begin
  Result := LIBRARY_VERSION;
end;

class function TJpegDecoder.Run(ASource: Pointer; ASourceSize: Cardinal;
  out AInfo: TJpegInfo; ADest: Pointer; ADestSize: Cardinal;
  ADecodePixels: Boolean): Integer;
var
  LDecompressor: TJpegDecompressor;
  LRowStride: Integer;
begin
  AInfo := Default(TJpegInfo);
  if (ASource = nil) or (ASourceSize = 0) or (ASourceSize > Cardinal(High(Integer))) then
    Exit(DDJPEG_ERR_INVALID_ARGUMENT);

  Result := DDJPEG_OK;
  LDecompressor := TJpegDecompressor.Create(ASource, Integer(ASourceSize));
  try
    try
      LDecompressor.ReadHeader;
      AInfo.Width := LDecompressor.Width;
      AInfo.Height := LDecompressor.Height;
      AInfo.Components := LDecompressor.OutputComponents;
      if not ADecodePixels then
        Exit;

      LRowStride := AInfo.Width * AInfo.Components;
      if (ADest = nil) or
         (Int64(ADestSize) < Int64(LRowStride) * Int64(AInfo.Height)) then
        Exit(DDJPEG_ERR_BUFFER_TOO_SMALL);

      LDecompressor.Decompress(ADest, LRowStride);
    except
      on E: EJpegDecodeException do
        Result := EJpegDecodeException.ResultCodeOf(E.Error);
    end;
  finally
    LDecompressor.Free;
  end;
end;

class function TJpegDecoder.ReadInfo(ASource: Pointer; ASourceSize: Cardinal;
  out AInfo: TJpegInfo): Integer;
begin
  Result := Run(ASource, ASourceSize, AInfo, nil, 0, False);
end;

class function TJpegDecoder.Decode(ASource: Pointer; ASourceSize: Cardinal;
  ADest: Pointer; ADestSize: Cardinal; out AInfo: TJpegInfo): Integer;
begin
  Result := Run(ASource, ASourceSize, AInfo, ADest, ADestSize, True);
end;

end.
