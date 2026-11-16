{******************************************************************************}
{                                                                              }
{  DelphiDoom: zlib - contract shared by the DLL and its clients               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zlib.Intf;

interface

uses
  System.SysUtils;

{$SCOPEDENUMS ON}

const
  // Result codes (same values as zlib)
  ZLIB_OK = 0;
  ZLIB_STREAM_END = 1;
  ZLIB_NEED_DICT = 2;
  ZLIB_ERRNO = -1;
  ZLIB_STREAM_ERROR = -2;
  ZLIB_DATA_ERROR = -3;
  ZLIB_MEM_ERROR = -4;
  ZLIB_BUF_ERROR = -5;
  ZLIB_VERSION_ERROR = -6;

  // Flush modes of the streaming interfaces
  ZLIB_NO_FLUSH = 0;
  ZLIB_SYNC_FLUSH = 2;
  ZLIB_FINISH = 4;

  // Compression levels
  ZLIB_DEFAULT_LEVEL = -1;
  ZLIB_BEST_SPEED = 1;
  ZLIB_BEST_COMPRESSION = 9;

  // The version of the zlib API that the engine asks for when it starts a stream: zlib only
  // checks the first digit
  ZLIB_API_VERSION: PAnsiChar = '1.2.8';

  // Name of the DLL and of its only export
  // the 64-bit library has the suffix 64 (DDZlib64.dll): the two never share a name
{$IFDEF CPUX64}
  DDZLIB_LIBRARY_NAME = 'DDZlib64.dll';
{$ELSE}
  DDZLIB_LIBRARY_NAME = 'DDZlib.dll';
{$ENDIF}
  DDZLIB_CREATE_EXPORT = 'DDZlibCreate';

type
  /// <summary>
  ///   Container format of the compressed data
  /// </summary>
  TZlibFormat = (Zlib, Raw, Gzip, Auto);

  /// <summary>
  ///   Input and output buffers of a stream: the caller fills NextIn/AvailIn
  ///   and NextOut/AvailOut before each call and the stream updates all of
  ///   them (and the totals) when it returns
  /// </summary>
  TZlibStreamBuffers = record
    NextIn: PByte;
    AvailIn: Cardinal;
    TotalIn: Cardinal;
    NextOut: PByte;
    AvailOut: Cardinal;
    TotalOut: Cardinal;
  end;

  /// <summary>
  ///   Incremental decompression. Releasing the interface ends the stream
  /// </summary>
  IZlibInflater = interface
    ['{6C8449CE-16F7-456E-A536-C442664D05C0}']

    /// <returns>
    ///   ZLIB_OK (progress made), ZLIB_STREAM_END (all data decoded),
    ///   ZLIB_BUF_ERROR (no progress possible) or an error code
    /// </returns>
    function Inflate(var ABuffers: TZlibStreamBuffers; AFlush: Integer): Integer; stdcall;
  end;

  /// <summary>
  ///   Incremental compression (zlib format). Releasing the interface ends
  ///   the stream
  /// </summary>
  IZlibDeflater = interface
    ['{FCFE6757-74EB-4402-8488-1B1CCDF14B96}']

    /// <returns>
    ///   ZLIB_OK (progress made), ZLIB_STREAM_END (everything flushed with
    ///   ZLIB_FINISH), ZLIB_BUF_ERROR (no progress possible) or an error code
    /// </returns>
    function Deflate(var ABuffers: TZlibStreamBuffers; AFlush: Integer): Integer; stdcall;
  end;

  /// <summary>
  ///   Contract of the zlib DLL
  /// </summary>
  /// <remarks>
  ///   Only raw buffers and integers cross the DLL boundary: the caller owns
  ///   every buffer, the DLL never allocates memory the caller has to free.
  ///   Methods are stdcall so that the binary layout does not depend on the
  ///   compiler settings of the client
  /// </remarks>
  IZlib = interface
    ['{69C08C8C-EBE9-46FD-9EF1-A0103A08893D}']

    /// <summary>
    ///   Name of the zlib code behind the interface (zero terminated, ANSI)
    /// </summary>
    function GetVersion: PAnsiChar; stdcall;

    /// <summary>
    ///   Upper bound of the size of the compressed form of ASourceSize bytes
    /// </summary>
    function CompressBound(ASourceSize: Cardinal): Cardinal; stdcall;

    /// <summary>
    ///   Compresses ASource into ADest (zlib format). ADestSize is the size of
    ///   ADest on input and the compressed size on output
    /// </summary>
    /// <returns>
    ///   ZLIB_OK, ZLIB_BUF_ERROR if ADest is too small, or another error code
    /// </returns>
    function Compress(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      var ADestSize: Cardinal; ALevel: Integer): Integer; stdcall;

    /// <summary>
    ///   Decompresses ASource into ADest. ADestSize is the size of ADest on
    ///   input and the decompressed size on output
    /// </summary>
    /// <returns>
    ///   ZLIB_OK, ZLIB_BUF_ERROR if ADest is too small or the input is
    ///   truncated, ZLIB_DATA_ERROR if the input is corrupted
    /// </returns>
    function Uncompress(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      var ADestSize: Cardinal; AFormat: TZlibFormat): Integer; stdcall;

    /// <summary>
    ///   Starts an incremental decompression
    /// </summary>
    function CreateInflater(AFormat: TZlibFormat;
      out AInflater: IZlibInflater): Integer; stdcall;

    /// <summary>
    ///   Starts an incremental compression (zlib format)
    /// </summary>
    function CreateDeflater(ALevel: Integer;
      out ADeflater: IZlibDeflater): Integer; stdcall;
  end;

  /// <summary>
  ///   Signature of the export DDZLIB_CREATE_EXPORT of the DLL. Returns
  ///   ZLIB_OK and an IZlib on success
  /// </summary>
  TDDZlibCreate = function(out AZlib: IZlib): Integer; stdcall;

  /// <summary>
  ///   Raised by the classes that wrap the DLL
  /// </summary>
  EZlibException = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer);
    class function TextOf(ACode: Integer): string; static;
    property Code: Integer read FCode;
  end;

implementation

{ EZlibException }

constructor EZlibException.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited CreateFmt('zlib error %d: %s', [ACode, TextOf(ACode)]);
end;

class function EZlibException.TextOf(ACode: Integer): string;
begin
  case ACode of
    ZLIB_OK:            Result := 'OK';
    ZLIB_STREAM_END:    Result := 'Stream end';
    ZLIB_NEED_DICT:     Result := 'Need dictionary';
    ZLIB_ERRNO:         Result := 'File error';
    ZLIB_STREAM_ERROR:  Result := 'Stream error';
    ZLIB_DATA_ERROR:    Result := 'Data error';
    ZLIB_MEM_ERROR:     Result := 'Insufficient memory';
    ZLIB_BUF_ERROR:     Result := 'Buffer error';
    ZLIB_VERSION_ERROR: Result := 'Incompatible version';
  else
    Result := 'Unknown error';
  end;
end;

end.
