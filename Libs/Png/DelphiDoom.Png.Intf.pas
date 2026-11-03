{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - contract shared by the DLL and its clients                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Zlib.Intf;

const
  // Result codes
  DDPNG_OK = 0;
  DDPNG_ERR_INVALID_ARGUMENT = -1;
  DDPNG_ERR_DATA = -2;
  DDPNG_ERR_TRUNCATED = -3;
  DDPNG_ERR_UNSUPPORTED = -4;
  DDPNG_ERR_BUFFER_TOO_SMALL = -5;
  DDPNG_ERR_MEMORY = -6;
  DDPNG_ERR_INTERNAL = -7;
  DDPNG_ERR_CRC = -8;
  DDPNG_ERR_TOO_LARGE = -9;

  // Color types of a PNG image (the values of the PNG specification)
  DDPNG_COLOR_GRAY = 0;
  DDPNG_COLOR_RGB = 2;
  DDPNG_COLOR_PALETTE = 3;
  DDPNG_COLOR_GRAY_ALPHA = 4;
  DDPNG_COLOR_RGBA = 6;

  // Layout of the pixels given to Encode
  DDPNG_FORMAT_BGRA = 0;   // 4 bytes: B, G, R, A. Written as RGBA, 8 bit
  DDPNG_FORMAT_BGRX = 1;   // 4 bytes: B, G, R, ignored. Written as RGB, 8 bit
  DDPNG_FORMAT_BGR = 2;    // 3 bytes: B, G, R. Written as RGB, 8 bit
  DDPNG_FORMAT_GRAY = 3;   // 1 byte. Written as grayscale, 8 bit

  // Compression level of Encode (as in zlib): values outside the range are
  // clamped to it
  DDPNG_DEFAULT_LEVEL = -1;
  DDPNG_MIN_LEVEL = 0;
  DDPNG_MAX_LEVEL = 9;

  // Largest image the decoder and the encoder accept: a PNG that declares a
  // larger size is refused before any memory is allocated for its pixels
  DDPNG_MAX_DIMENSION = 16384;
  DDPNG_MAX_PIXELS = 32 * 1024 * 1024;

  // Size in bytes of the palette DecodeIndexed returns: 256 entries of
  // 4 bytes (B, G, R, A)
  DDPNG_PALETTE_BYTES = 256 * 4;

  // Name of the DLL and of its only export
  DDPNG_LIBRARY_NAME = 'DDPng.dll';
  DDPNG_CREATE_EXPORT = 'DDPngCreate';

type
  /// <summary>
  ///   What the header and the ancillary chunks of a PNG file say about it
  /// </summary>
  /// <remarks>
  ///   Decoded pixels are always 8 bit per channel, whatever BitDepth is.
  ///   TransparentColor is a pixel in the layout of a decoded one (B, G, R
  ///   bytes and a zero fourth byte, so it reads as $00RRGGBB): for grayscale
  ///   and RGB images it is the color the tRNS chunk makes transparent, for
  ///   palette images it is the first palette entry with zero alpha
  /// </remarks>
  TPngInfo = record
    Width: Integer;
    Height: Integer;
    BitDepth: Integer;
    ColorType: Integer;
    /// <summary>1 if the image is interlaced (Adam7), 0 otherwise</summary>
    Interlaced: Integer;
    /// <summary>1 if some pixels may be not opaque</summary>
    HasAlpha: Integer;
    /// <summary>1 if TransparentColor is valid</summary>
    HasTransparentColor: Integer;
    TransparentColor: Cardinal;
    /// <summary>Number of entries of the PLTE chunk, 0 if there is none</summary>
    PaletteCount: Integer;
    /// <summary>Offsets of the grAb chunk (ZDoom patch offsets), 0 if absent</summary>
    OffsetX: Integer;
    OffsetY: Integer;
  end;

  /// <summary>
  ///   Contract of the PNG DLL
  /// </summary>
  /// <remarks>
  ///   Only raw buffers and integers cross the DLL boundary: the caller owns
  ///   every buffer, the DLL never allocates memory the caller has to free and
  ///   never lets an exception escape. Methods are stdcall so that the binary
  ///   layout does not depend on the compiler settings of the client.
  ///   The compression is done by the IZlib the library was created with
  /// </remarks>
  IPng = interface
    ['{B3E1F4A2-7C5D-4E8B-9A16-2D0F8C47E5B1}']

    /// <summary>
    ///   Version of the PNG code inside the DLL (zero terminated, ANSI)
    /// </summary>
    function GetVersion: PAnsiChar; stdcall;

    /// <summary>
    ///   Reads the header and the ancillary chunks of a PNG file without
    ///   decoding the pixels
    /// </summary>
    /// <remarks>
    ///   Only the signature and the header are required to be valid: damage
    ///   found after the header (a bad CRC of another chunk, a truncated
    ///   file) is reported by Decode, not here
    /// </remarks>
    /// <returns>
    ///   DDPNG_OK, DDPNG_ERR_DATA (not a PNG file or an invalid header),
    ///   DDPNG_ERR_CRC (bad CRC of the header), DDPNG_ERR_TRUNCATED,
    ///   DDPNG_ERR_TOO_LARGE or DDPNG_ERR_INVALID_ARGUMENT
    /// </returns>
    function GetInfo(ASource: Pointer; ASourceSize: Cardinal;
      out AInfo: TPngInfo): Integer; stdcall;

    /// <summary>
    ///   Decodes a PNG file into ADest, which holds ADestSize bytes: Width *
    ///   Height pixels of 4 bytes (B, G, R, A), rows from top to bottom
    ///   without padding. Every color type and bit depth is converted; the
    ///   alpha is the alpha channel, the tRNS chunk or 255
    /// </summary>
    /// <remarks>
    ///   AInfo is filled as soon as the header is read, so it is valid also
    ///   when the result is DDPNG_ERR_BUFFER_TOO_SMALL: the caller can then
    ///   allocate Width * Height * 4 bytes and call again. The content of
    ///   ADest is not defined when the result is an error
    /// </remarks>
    /// <returns>
    ///   DDPNG_OK or an error code: DDPNG_ERR_BUFFER_TOO_SMALL,
    ///   DDPNG_ERR_DATA, DDPNG_ERR_CRC, DDPNG_ERR_TRUNCATED,
    ///   DDPNG_ERR_UNSUPPORTED (unknown critical chunk), DDPNG_ERR_TOO_LARGE
    /// </returns>
    function Decode(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      ADestSize: Cardinal; out AInfo: TPngInfo): Integer; stdcall;

    /// <summary>
    ///   Decodes a palette image (color type 3, any bit depth) without
    ///   expanding it: APixels receives Width * Height palette indices, one
    ///   byte each, and APalette (DDPNG_PALETTE_BYTES bytes) the 256 entries
    ///   as B, G, R, A, with the alpha of the tRNS chunk. Entries beyond the
    ///   PLTE chunk are opaque black
    /// </summary>
    /// <returns>
    ///   The codes of Decode, or DDPNG_ERR_UNSUPPORTED if the image is not a
    ///   palette image (AInfo tells which it is)
    /// </returns>
    function DecodeIndexed(ASource: Pointer; ASourceSize: Cardinal;
      APixels: Pointer; APixelsSize: Cardinal; APalette: Pointer;
      out AInfo: TPngInfo): Integer; stdcall;

    /// <summary>
    ///   Upper bound of the size of the PNG file Encode produces for an image
    ///   of that size; 0 if the arguments are not valid
    /// </summary>
    function EncodeBound(AWidth, AHeight, AFormat: Integer): Cardinal; stdcall;

    /// <summary>
    ///   Encodes AWidth * AHeight pixels (AFormat gives their layout) into a
    ///   PNG file. ADestSize is the size of ADest on input and the size of the
    ///   file on output
    /// </summary>
    /// <remarks>
    ///   AStride is the distance in bytes between two rows of APixels, 0 for
    ///   rows without padding. It can be negative to read a bottom-up image
    ///   (as OpenGL gives it): APixels then points to the first row to write,
    ///   which is the last one in memory. The compression level is 0..9 or
    ///   DDPNG_DEFAULT_LEVEL; 0 stores the data without compressing it
    /// </remarks>
    /// <returns>
    ///   DDPNG_OK, DDPNG_ERR_INVALID_ARGUMENT or DDPNG_ERR_BUFFER_TOO_SMALL
    ///   (use EncodeBound to size ADest; ADestSize is not changed)
    /// </returns>
    function Encode(APixels: Pointer; AWidth, AHeight, AFormat, AStride,
      ALevel: Integer; ADest: Pointer; var ADestSize: Cardinal): Integer; stdcall;
  end;

  /// <summary>
  ///   Signature of the export DDPNG_CREATE_EXPORT of the DLL: it receives the
  ///   zlib the library compresses with (from DDZlib.dll or from an engine
  ///   linked in the caller) and returns DDPNG_OK and an IPng on success. The
  ///   IPng keeps a reference to the IZlib: release the IPng before the code
  ///   behind the IZlib is unloaded
  /// </summary>
  TDDPngCreate = function(AZlib: IZlib; out APng: IPng): Integer; stdcall;

  /// <summary>
  ///   Raised by the classes that wrap the DLL (and, inside the DLL, by the
  ///   decoder and the encoder, which the engine turns into result codes)
  /// </summary>
  EPngException = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer);
    class function TextOf(ACode: Integer): string; static;
    property Code: Integer read FCode;
  end;

implementation

{ EPngException }

constructor EPngException.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited CreateFmt('PNG error %d: %s', [ACode, TextOf(ACode)]);
end;

class function EPngException.TextOf(ACode: Integer): string;
begin
  case ACode of
    DDPNG_OK:                    Result := 'OK';
    DDPNG_ERR_INVALID_ARGUMENT:  Result := 'Invalid argument';
    DDPNG_ERR_DATA:              Result := 'Not a valid PNG file';
    DDPNG_ERR_TRUNCATED:         Result := 'Truncated PNG file';
    DDPNG_ERR_UNSUPPORTED:       Result := 'Unsupported PNG feature';
    DDPNG_ERR_BUFFER_TOO_SMALL:  Result := 'Buffer too small';
    DDPNG_ERR_MEMORY:            Result := 'Insufficient memory';
    DDPNG_ERR_INTERNAL:          Result := 'Internal error';
    DDPNG_ERR_CRC:               Result := 'Bad CRC';
    DDPNG_ERR_TOO_LARGE:         Result := 'Image too large';
  else
    Result := 'Unknown error';
  end;
end;

end.
