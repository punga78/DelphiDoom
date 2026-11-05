{******************************************************************************}
{                                                                              }
{  DelphiDoom: libsndfile - contract shared by the DLL and its clients         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sndfile.Intf;

interface

uses
  System.SysUtils;

const
  // Result codes. 1..4 are the public error values of libsndfile (SF_ERR_*);
  // the negative ones are raised by the DLL itself. Any other positive value
  // is an internal error number of libsndfile (see ISoundFile.GetErrorText)
  SNDFILE_OK = 0;
  SNDFILE_ERR_UNRECOGNISED_FORMAT = 1;
  SNDFILE_ERR_SYSTEM = 2;
  SNDFILE_ERR_MALFORMED_FILE = 3;
  SNDFILE_ERR_UNSUPPORTED_ENCODING = 4;
  SNDFILE_ERR_INVALID_ARGUMENT = -1;
  SNDFILE_ERR_OUT_OF_MEMORY = -2;
  SNDFILE_ERR_UNEXPECTED = -3;

  // Masks of TSoundFileInfo.Format: container (major) and encoding (subtype)
  SNDFILE_FORMAT_TYPEMASK = $0FFF0000;
  SNDFILE_FORMAT_SUBMASK = $0000FFFF;

  // Containers (same values as SF_FORMAT_* of libsndfile)
  SNDFILE_FORMAT_WAV = $010000;
  SNDFILE_FORMAT_AIFF = $020000;
  SNDFILE_FORMAT_AU = $030000;
  SNDFILE_FORMAT_RAW = $040000;
  SNDFILE_FORMAT_VOC = $080000;
  SNDFILE_FORMAT_WAVEX = $130000;
  SNDFILE_FORMAT_FLAC = $170000;
  SNDFILE_FORMAT_OGG = $200000;

  // Flag or'ed to Format when the samples are stored big endian
  SNDFILE_FORMAT_ENDIAN_LITTLE = $10000000;
  SNDFILE_FORMAT_ENDIAN_BIG = $20000000;

  // Encodings (same values as SF_FORMAT_* of libsndfile)
  SNDFILE_FORMAT_PCM_S8 = $0001;
  SNDFILE_FORMAT_PCM_16 = $0002;
  SNDFILE_FORMAT_PCM_24 = $0003;
  SNDFILE_FORMAT_PCM_32 = $0004;
  SNDFILE_FORMAT_PCM_U8 = $0005;
  SNDFILE_FORMAT_FLOAT = $0006;
  SNDFILE_FORMAT_DOUBLE = $0007;
  SNDFILE_FORMAT_ULAW = $0010;
  SNDFILE_FORMAT_ALAW = $0011;
  SNDFILE_FORMAT_VORBIS = $0060;

  // Origins of ISoundFile.Seek
  SNDFILE_SEEK_SET = 0;
  SNDFILE_SEEK_CUR = 1;
  SNDFILE_SEEK_END = 2;

  // Name of the DLL and of its only export
  DDSNDFILE_LIBRARY_NAME = 'DDSndfile.dll';
  DDSNDFILE_CREATE_EXPORT = 'DDSndfileCreate';

type
  /// <summary>
  ///   Description of an opened sound. Plain data, identical on both sides of
  ///   the DLL boundary
  /// </summary>
  TSoundFileInfo = packed record
    /// <summary>Length of the sound, in frames (one sample per channel)</summary>
    Frames: Int64;
    /// <summary>Frames per second</summary>
    SampleRate: Integer;
    /// <summary>Samples per frame</summary>
    Channels: Integer;
    /// <summary>SNDFILE_FORMAT_* container or'ed with SNDFILE_FORMAT_* encoding</summary>
    Format: Integer;
    Sections: Integer;
    /// <summary>Non zero if ISoundFile.Seek can be used</summary>
    Seekable: Integer;
  end;

  /// <summary>
  ///   A sound opened from a buffer in memory, read only. Releasing the
  ///   interface closes the sound
  /// </summary>
  /// <remarks>
  ///   Samples are interleaved: a buffer for AFrames frames holds
  ///   AFrames * Channels items. The Read methods return SNDFILE_OK also when
  ///   AFramesRead is less than AFrames (end of the sound reached); an error
  ///   code means that the data is damaged. Not thread safe: use one instance
  ///   per thread
  /// </remarks>
  ISoundFile = interface
    ['{085C2F9E-A919-45D4-A508-51EDB576BBB2}']

    function GetInfo(out AInfo: TSoundFileInfo): Integer; stdcall;

    /// <summary>
    ///   Reads up to AFrames frames as 16 bit signed integers into ABuffer
    /// </summary>
    function ReadShort(ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer; stdcall;

    /// <summary>
    ///   Reads up to AFrames frames as 32 bit signed integers into ABuffer
    /// </summary>
    function ReadInt(ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer; stdcall;

    /// <summary>
    ///   Reads up to AFrames frames as doubles in the range -1..1 into ABuffer
    /// </summary>
    function ReadDouble(ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer; stdcall;

    /// <summary>
    ///   Moves the read position to AFrame frames from AWhence
    ///   (SNDFILE_SEEK_*). APosition is the new position, in frames from the
    ///   start of the sound
    /// </summary>
    function Seek(AFrame: Int64; AWhence: Integer;
      out APosition: Int64): Integer; stdcall;

    /// <summary>
    ///   Text of the last error of this sound (zero terminated, ANSI), valid
    ///   until the sound is released
    /// </summary>
    function GetErrorText: PAnsiChar; stdcall;
  end;

  /// <summary>
  ///   Contract of the libsndfile DLL
  /// </summary>
  /// <remarks>
  ///   Only raw buffers and integers cross the DLL boundary: the caller owns
  ///   every buffer, the DLL never allocates memory the caller has to free.
  ///   Methods are stdcall so that the binary layout does not depend on the
  ///   compiler settings of the client
  /// </remarks>
  ISndfile = interface
    ['{D9BEFD41-C116-4303-AC56-4C68A2AF9FE0}']

    /// <summary>
    ///   Version of the libsndfile code inside the DLL (zero terminated, ANSI)
    /// </summary>
    function GetVersion: PAnsiChar; stdcall;

    /// <summary>
    ///   Opens the sound stored in ASource, detecting its format. The DLL
    ///   copies the data, so ASource may be released as soon as the call
    ///   returns
    /// </summary>
    /// <returns>
    ///   SNDFILE_OK, SNDFILE_ERR_UNRECOGNISED_FORMAT if the data is not a
    ///   supported sound, or another error code
    /// </returns>
    function OpenMemory(ASource: Pointer; ASourceSize: Cardinal;
      out ASoundFile: ISoundFile): Integer; stdcall;
  end;

  /// <summary>
  ///   Signature of the export DDSNDFILE_CREATE_EXPORT of the DLL. Returns
  ///   SNDFILE_OK and an ISndfile on success
  /// </summary>
  TDDSndfileCreate = function(out ASndfile: ISndfile): Integer; stdcall;

  /// <summary>
  ///   Raised by the classes that wrap the DLL
  /// </summary>
  ESndfileException = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer);
    constructor CreateCodeDetail(ACode: Integer; const ADetail: string);
    class function TextOf(ACode: Integer): string; static;
    property Code: Integer read FCode;
  end;

implementation

{ ESndfileException }

constructor ESndfileException.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited CreateFmt('libsndfile error %d: %s', [ACode, TextOf(ACode)]);
end;

constructor ESndfileException.CreateCodeDetail(ACode: Integer;
  const ADetail: string);
begin
  FCode := ACode;
  inherited CreateFmt('libsndfile error %d: %s (%s)',
    [ACode, TextOf(ACode), ADetail]);
end;

class function ESndfileException.TextOf(ACode: Integer): string;
begin
  case ACode of
    SNDFILE_OK:                       Result := 'OK';
    SNDFILE_ERR_UNRECOGNISED_FORMAT:  Result := 'Unrecognised format';
    SNDFILE_ERR_SYSTEM:               Result := 'System error';
    SNDFILE_ERR_MALFORMED_FILE:       Result := 'Malformed file';
    SNDFILE_ERR_UNSUPPORTED_ENCODING: Result := 'Unsupported encoding';
    SNDFILE_ERR_INVALID_ARGUMENT:     Result := 'Invalid argument';
    SNDFILE_ERR_OUT_OF_MEMORY:        Result := 'Insufficient memory';
    SNDFILE_ERR_UNEXPECTED:           Result := 'Unexpected error';
  else
    if ACode > SNDFILE_ERR_UNSUPPORTED_ENCODING then
      Result := 'Internal libsndfile error'
    else
      Result := 'Unknown error';
  end;
end;

end.
