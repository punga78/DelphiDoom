{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - contract shared by the DLL and its clients               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Intf;

interface

uses
  System.SysUtils;

const
  // Result codes
  DDJPEG_OK = 0;
  DDJPEG_ERR_INVALID_ARGUMENT = -1;
  DDJPEG_ERR_DATA = -2;
  DDJPEG_ERR_TRUNCATED = -3;
  DDJPEG_ERR_UNSUPPORTED = -4;
  DDJPEG_ERR_BUFFER_TOO_SMALL = -5;
  DDJPEG_ERR_MEMORY = -6;
  DDJPEG_ERR_INTERNAL = -7;

  // Quality of the encoder: values outside the range are clamped to it
  DDJPEG_MIN_QUALITY = 1;
  DDJPEG_MAX_QUALITY = 100;
  DDJPEG_DEFAULT_QUALITY = 85;

  // Largest width and height accepted by the encoder
  DDJPEG_MAX_DIMENSION = 65500;

  // Name of the DLL and of its only export
  DDJPEG_LIBRARY_NAME = 'DDJpeg.dll';
  DDJPEG_CREATE_EXPORT = 'DDJpegCreate';

type
  /// <summary>
  ///   Size and format of a decoded image
  /// </summary>
  /// <remarks>
  ///   Components is 1 for a grayscale image (one byte per pixel) and 3 for
  ///   a color image (three bytes per pixel in B, G, R order, as in a Windows
  ///   bitmap). Rows are stored from top to bottom without padding: a row is
  ///   Width * Components bytes long
  /// </remarks>
  TJpegInfo = record
    Width: Integer;
    Height: Integer;
    Components: Integer;
  end;

  /// <summary>
  ///   Contract of the JPEG DLL
  /// </summary>
  /// <remarks>
  ///   Only raw buffers and integers cross the DLL boundary: the caller owns
  ///   every buffer, the DLL never allocates memory the caller has to free and
  ///   never lets an exception escape. Methods are stdcall so that the binary
  ///   layout does not depend on the compiler settings of the client
  /// </remarks>
  IJpeg = interface
    ['{6CED635D-5654-4EBD-9299-75A4F011F523}']

    /// <summary>
    ///   Version of the JPEG code inside the DLL (zero terminated, ANSI)
    /// </summary>
    function GetVersion: PAnsiChar; stdcall;

    /// <summary>
    ///   Reads the header of a JPEG stream without decoding the pixels
    /// </summary>
    /// <returns>
    ///   DDJPEG_OK, DDJPEG_ERR_DATA if ASource is not a JPEG stream or
    ///   DDJPEG_ERR_UNSUPPORTED if it uses a feature that is not supported
    /// </returns>
    function GetInfo(ASource: Pointer; ASourceSize: Cardinal;
      out AInfo: TJpegInfo): Integer; stdcall;

    /// <summary>
    ///   Decodes a JPEG stream into ADest, which holds ADestSize bytes
    /// </summary>
    /// <remarks>
    ///   AInfo is filled as soon as the header is read, so it is valid also
    ///   when the result is DDJPEG_ERR_BUFFER_TOO_SMALL: the caller can then
    ///   allocate Width * Height * Components bytes and call again
    /// </remarks>
    /// <returns>
    ///   DDJPEG_OK, DDJPEG_ERR_BUFFER_TOO_SMALL, DDJPEG_ERR_DATA (not a JPEG
    ///   stream or corrupted), DDJPEG_ERR_TRUNCATED (the stream ends before
    ///   the image is complete) or another error code
    /// </returns>
    function Decode(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      ADestSize: Cardinal; out AInfo: TJpegInfo): Integer; stdcall;

    /// <summary>
    ///   Upper bound of the size of the JPEG stream Encode produces for an
    ///   image of that size; 0 if the arguments are not valid
    /// </summary>
    function EncodeBound(AWidth, AHeight, AComponents: Integer): Cardinal; stdcall;

    /// <summary>
    ///   Encodes APixels (layout as described in TJpegInfo) into a baseline
    ///   JPEG stream. ADestSize is the size of ADest on input and the size of
    ///   the stream on output
    /// </summary>
    /// <returns>
    ///   DDJPEG_OK, DDJPEG_ERR_INVALID_ARGUMENT or DDJPEG_ERR_BUFFER_TOO_SMALL
    ///   (use EncodeBound to size ADest)
    /// </returns>
    function Encode(APixels: Pointer; AWidth, AHeight, AComponents,
      AQuality: Integer; ADest: Pointer; var ADestSize: Cardinal): Integer; stdcall;
  end;

  /// <summary>
  ///   Signature of the export DDJPEG_CREATE_EXPORT of the DLL. Returns
  ///   DDJPEG_OK and an IJpeg on success
  /// </summary>
  TDDJpegCreate = function(out AJpeg: IJpeg): Integer; stdcall;

  /// <summary>
  ///   Raised by the classes that wrap the DLL
  /// </summary>
  EJpegException = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer);
    class function TextOf(ACode: Integer): string; static;
    property Code: Integer read FCode;
  end;

implementation

{ EJpegException }

constructor EJpegException.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited CreateFmt('JPEG error %d: %s', [ACode, TextOf(ACode)]);
end;

class function EJpegException.TextOf(ACode: Integer): string;
begin
  case ACode of
    DDJPEG_OK:                  Result := 'OK';
    DDJPEG_ERR_INVALID_ARGUMENT: Result := 'Invalid argument';
    DDJPEG_ERR_DATA:            Result := 'Not a valid JPEG stream';
    DDJPEG_ERR_TRUNCATED:       Result := 'Truncated JPEG stream';
    DDJPEG_ERR_UNSUPPORTED:     Result := 'Unsupported JPEG feature';
    DDJPEG_ERR_BUFFER_TOO_SMALL: Result := 'Buffer too small';
    DDJPEG_ERR_MEMORY:          Result := 'Insufficient memory';
    DDJPEG_ERR_INTERNAL:        Result := 'Internal error';
  else
    Result := 'Unknown error';
  end;
end;

end.
