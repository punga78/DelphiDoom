{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - contract shared by the DLL and its clients                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mp3.Intf;

interface

uses
  System.SysUtils;

const
  // Result codes. Negative values are errors
  MP3_OK = 0;
  MP3_NEED_DATA = 1;
  MP3_ERROR_INVALID_ARGUMENT = -1;
  MP3_ERROR_UNSUPPORTED = -2;
  MP3_ERROR_DATA = -3;
  MP3_ERROR_MEMORY = -4;
  MP3_ERROR_LIMIT = -5;
  MP3_ERROR_INTERNAL = -6;

  // Which channels of the stream are decoded
  MP3_CHANNELS_BOTH = 0;
  MP3_CHANNELS_LEFT = 1;
  MP3_CHANNELS_RIGHT = 2;
  MP3_CHANNELS_DOWNMIX = 3;

  // Output volume, in percent of the full scale (louder samples are clipped)
  MP3_VOLUME_MIN = 0;
  MP3_VOLUME_MAX = 100;
  MP3_DEFAULT_VOLUME = 100;

  // Largest amount of input a decoder keeps buffered (Feed fails beyond it)
  MP3_MAX_BUFFERED_BYTES = 64 * 1024 * 1024;

  // Samples per channel of one MPEG-1 layer III frame
  MP3_SAMPLES_PER_FRAME = 1152;

  // Name of the DLL and of its only export
  DDMP3_LIBRARY_NAME = 'DDMp3.dll';
  DDMP3_CREATE_EXPORT = 'DDMp3Create';

  DDMP3_VERSION_TEXT: PAnsiChar = 'DDMp3 1.0 (MPEG-1/2 layer III)';

type
  /// <summary>
  ///   Incremental MP3 decoder: the caller feeds MP3 bytes in blocks of any
  ///   size and collects 16 bit PCM in buffers it owns. Releasing the
  ///   interface destroys the decoder
  /// </summary>
  /// <remarks>
  ///   PCM is interleaved, signed 16 bit, little endian. Not thread safe: use
  ///   a decoder from one thread at a time. The MPEG code behind it shares
  ///   some global tables, so different decoders must not run concurrently
  ///   either. Only layer III is decoded; the other layers are reported as
  ///   MP3_ERROR_UNSUPPORTED
  /// </remarks>
  IMp3Decoder = interface
    ['{8A3D5E21-47C0-4B6F-9E12-5C7A0D3B8F64}']

    /// <summary>
    ///   Appends ASize bytes of MP3 data to the input of the decoder; the
    ///   data is copied. ID3v2 tags and bytes that do not belong to a frame
    ///   are skipped by the decoder
    /// </summary>
    /// <returns>
    ///   MP3_OK, MP3_ERROR_INVALID_ARGUMENT (AData nil with ASize > 0) or
    ///   MP3_ERROR_LIMIT (more than MP3_MAX_BUFFERED_BYTES pending)
    /// </returns>
    function Feed(AData: Pointer; ASize: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Decodes the frames available in the input into APcm, which holds
    ///   APcmSize bytes (at least 2; only whole 16 bit samples are written,
    ///   a multiple of 4 keeps stereo samples together). AWritten receives the
    ///   number of bytes written and is valid also when an error is returned
    /// </summary>
    /// <returns>
    ///   MP3_OK when APcm is full and more PCM may be available (call again),
    ///   MP3_NEED_DATA when the input is exhausted (feed more data),
    ///   MP3_ERROR_INVALID_ARGUMENT, MP3_ERROR_UNSUPPORTED (layer I or II
    ///   frame, already skipped), MP3_ERROR_DATA or another error code
    /// </returns>
    function Decode(APcm: Pointer; APcmSize: Cardinal;
      out AWritten: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Sampling rate of the stream in Hz, 0 until the first frame header
    ///   has been found
    /// </summary>
    function GetFrequency: Cardinal; stdcall;

    /// <summary>
    ///   Channels of the PCM produced (1 or 2), 0 until the first frame header
    ///   has been found
    /// </summary>
    function GetChannels: Cardinal; stdcall;

    /// <summary>
    ///   Bytes of input fed but not consumed yet
    /// </summary>
    function GetPendingSize: Cardinal; stdcall;

    /// <summary>
    ///   Drops the buffered input and the state of the decoder, ready for a
    ///   new stream (for example to loop a track)
    /// </summary>
    function Reset: Integer; stdcall;
  end;

  /// <summary>
  ///   Contract of the mp3 DLL
  /// </summary>
  /// <remarks>
  ///   Only raw buffers and integers cross the DLL boundary: the caller owns
  ///   every buffer, the DLL never allocates memory the caller has to free.
  ///   Methods are stdcall so that the binary layout does not depend on the
  ///   compiler settings of the client. Every decoder must be released before
  ///   the DLL is unloaded, because its code lives inside the DLL
  /// </remarks>
  IMp3 = interface
    ['{C41F7B92-0E63-4D58-A7B1-2F9E6D40C385}']

    /// <summary>
    ///   Version of the library (zero terminated, ANSI)
    /// </summary>
    function GetVersion: PAnsiChar; stdcall;

    /// <summary>
    ///   Creates a decoder. AChannels is one of the MP3_CHANNELS_* values and
    ///   AVolume a percentage between MP3_VOLUME_MIN and MP3_VOLUME_MAX
    /// </summary>
    /// <returns>
    ///   MP3_OK, MP3_ERROR_INVALID_ARGUMENT or MP3_ERROR_MEMORY
    /// </returns>
    function CreateDecoder(AChannels, AVolume: Integer;
      out ADecoder: IMp3Decoder): Integer; stdcall;
  end;

  /// <summary>
  ///   Signature of the export DDMP3_CREATE_EXPORT of the DLL. Returns MP3_OK
  ///   and an IMp3 on success
  /// </summary>
  TDDMp3Create = function(out AMp3: IMp3): Integer; stdcall;

  /// <summary>
  ///   Raised by the classes that wrap the DLL
  /// </summary>
  EMp3Exception = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer);
    class function TextOf(ACode: Integer): string; static;

    /// <summary>
    ///   Result code that stands for AException when it must cross the DLL
    ///   boundary as an integer
    /// </summary>
    class function CodeOf(const AException: Exception): Integer; static;
    property Code: Integer read FCode;
  end;

implementation

{ EMp3Exception }

constructor EMp3Exception.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited CreateFmt('mp3 error %d: %s', [ACode, TextOf(ACode)]);
end;

class function EMp3Exception.TextOf(ACode: Integer): string;
begin
  case ACode of
    MP3_OK:                     Result := 'OK';
    MP3_NEED_DATA:              Result := 'More data needed';
    MP3_ERROR_INVALID_ARGUMENT: Result := 'Invalid argument';
    MP3_ERROR_UNSUPPORTED:      Result := 'Unsupported MPEG layer';
    MP3_ERROR_DATA:             Result := 'Invalid MP3 data';
    MP3_ERROR_MEMORY:           Result := 'Insufficient memory';
    MP3_ERROR_LIMIT:            Result := 'Too much data buffered';
    MP3_ERROR_INTERNAL:         Result := 'Internal error';
  else
    Result := 'Unknown error';
  end;
end;

class function EMp3Exception.CodeOf(const AException: Exception): Integer;
begin
  if AException is EMp3Exception then
    Result := EMp3Exception(AException).Code
  else if AException is EOutOfMemory then
    Result := MP3_ERROR_MEMORY
  else
    Result := MP3_ERROR_INTERNAL;
end;

end.
