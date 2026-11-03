{******************************************************************************}
{                                                                              }
{  DelphiDoom: MikMod - contract shared by the DLL and its clients             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mikmod.Intf;

interface

uses
  System.SysUtils;

const
  // Result codes (zero is success, every error is negative)
  MIKMOD_OK = 0;
  MIKMOD_ERR_NOT_INITIALIZED = -1;
  MIKMOD_ERR_ALREADY_INITIALIZED = -2;
  MIKMOD_ERR_LOAD_LIBRARY = -3;
  MIKMOD_ERR_INIT = -4;
  MIKMOD_ERR_LOAD_MODULE = -5;
  MIKMOD_ERR_INVALID_ARGUMENT = -6;
  MIKMOD_ERR_BUSY = -7;
  MIKMOD_ERR_NO_MODULE = -8;
  MIKMOD_ERR_IO = -9;
  MIKMOD_ERR_INTERNAL = -10;

  // Limits checked by the engine before touching the sound library
  MIKMOD_MIN_MIX_FREQUENCY = 4000;
  MIKMOD_MAX_MIX_FREQUENCY = 65535;
  MIKMOD_MAX_VOLUME = 128;
  MIKMOD_MAX_MODULE_SIZE = 64 * 1024 * 1024;

  // Name of the DLL and of its only export
  DDMIKMOD_LIBRARY_NAME = 'DDMikmod.dll';
  DDMIKMOD_CREATE_EXPORT = 'DDMikmodCreate';

type
  /// <summary>
  ///   One module (MOD, S3M, XM, IT...) that can be loaded and played. Only
  ///   one player at a time can exist for an IMikMod, because the sound
  ///   library has a single current module. Releasing the interface stops
  ///   the music and frees the player slot
  /// </summary>
  /// <remarks>
  ///   Every method returns MIKMOD_OK or a MIKMOD_ERR_* code, except the
  ///   queries that return a boolean. The textual detail of a failure is
  ///   available through IMikMod.GetLastError
  /// </remarks>
  IMikModPlayer = interface
    ['{A3E55B0B-5C7E-4C6D-9F3B-3F4C0B6E8A21}']

    /// <summary>
    ///   Loads a module from a file (the path is ANSI, as the C library wants)
    /// </summary>
    /// <returns>
    ///   MIKMOD_OK, MIKMOD_ERR_INVALID_ARGUMENT for a missing path,
    ///   MIKMOD_ERR_LOAD_MODULE if the file is missing or is not a module
    /// </returns>
    function LoadFromFile(AFileName: PAnsiChar): Integer; stdcall;

    /// <summary>
    ///   Loads a module from a buffer owned by the caller: the buffer is
    ///   not needed any more when the call returns
    /// </summary>
    /// <returns>
    ///   MIKMOD_OK, MIKMOD_ERR_INVALID_ARGUMENT for a nil or empty buffer,
    ///   MIKMOD_ERR_IO if the buffer cannot be handed to the C library,
    ///   MIKMOD_ERR_LOAD_MODULE if it is not a module
    /// </returns>
    function LoadFromMemory(AData: Pointer; ASize: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Starts the loaded module from its beginning
    /// </summary>
    /// <returns>
    ///   MIKMOD_OK or MIKMOD_ERR_NO_MODULE if nothing has been loaded
    /// </returns>
    function Play(ALoop: LongBool): Integer; stdcall;

    /// <summary>
    ///   Stops the music and rewinds the module
    /// </summary>
    function Stop: Integer; stdcall;

    /// <summary>
    ///   Pauses or resumes the music (idempotent, unlike the toggle of the
    ///   C library)
    /// </summary>
    function SetPaused(APaused: LongBool): Integer; stdcall;

    /// <summary>
    ///   AVolume goes from 0 to MIKMOD_MAX_VOLUME
    /// </summary>
    function SetVolume(AVolume: Integer): Integer; stdcall;

    function IsPlaying: LongBool; stdcall;
    function IsPaused: LongBool; stdcall;

    /// <summary>
    ///   Mixes the next block of audio: to be called often by the owner
    /// </summary>
    function Update: Integer; stdcall;
  end;

  /// <summary>
  ///   Contract of the MikMod DLL
  /// </summary>
  /// <remarks>
  ///   Only raw buffers, ANSI strings and integers cross the DLL boundary:
  ///   the caller owns every buffer, the DLL never allocates memory the
  ///   caller has to free. Methods are stdcall so that the binary layout
  ///   does not depend on the compiler settings of the client.
  ///   The sound library keeps global state: use one initialised IMikMod
  ///   at a time and call it from a single thread
  /// </remarks>
  IMikMod = interface
    ['{5B1D9F52-2B7A-4E39-8A57-0C4E6D1F7B93}']

    /// <summary>
    ///   Version of libmikmod inside the DLL, packed as
    ///   (major shl 16) or (minor shl 8) or revision
    /// </summary>
    function GetVersion: Cardinal; stdcall;

    /// <summary>
    ///   Loads the sound library and opens the audio device (this is the
    ///   call that makes noise possible)
    /// </summary>
    /// <param name="AMixFrequency">
    ///   Sampling rate, MIKMOD_MIN_MIX_FREQUENCY..MIKMOD_MAX_MIX_FREQUENCY
    /// </param>
    /// <param name="AWindow">
    ///   Window handle DirectSound needs for its cooperative level
    /// </param>
    /// <param name="ABufferSize">
    ///   Size of the DirectSound buffer, zero for the default
    /// </param>
    /// <returns>
    ///   MIKMOD_OK, MIKMOD_ERR_INVALID_ARGUMENT, MIKMOD_ERR_ALREADY_INITIALIZED,
    ///   MIKMOD_ERR_BUSY (another engine of the process is initialised),
    ///   MIKMOD_ERR_LOAD_LIBRARY or MIKMOD_ERR_INIT (no audio device)
    /// </returns>
    function Initialize(AMixFrequency: Cardinal; AStereo, A16Bits,
      AInterpolation: LongBool; AWindow: NativeUInt;
      ABufferSize: Integer): Integer; stdcall;

    /// <summary>
    ///   Stops everything and closes the audio device (does nothing if not
    ///   initialised). Players obtained before become unusable
    /// </summary>
    procedure Shutdown; stdcall;

    function IsInitialized: LongBool; stdcall;

    /// <summary>
    ///   Creates the player of the initialised engine
    /// </summary>
    /// <returns>
    ///   MIKMOD_OK, MIKMOD_ERR_NOT_INITIALIZED or MIKMOD_ERR_BUSY if a
    ///   player already exists
    /// </returns>
    function CreatePlayer(out APlayer: IMikModPlayer): Integer; stdcall;

    /// <summary>
    ///   Copies into ABuffer the text of the last error reported by the
    ///   sound library (zero terminated, ANSI, truncated to ABufferSize - 1
    ///   characters)
    /// </summary>
    /// <returns>
    ///   Length of the whole text, without the terminator: when it is not
    ///   less than ABufferSize the text was truncated. ABuffer may be nil to
    ///   ask for the length only
    /// </returns>
    function GetLastError(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
  end;

  /// <summary>
  ///   Signature of the export DDMIKMOD_CREATE_EXPORT of the DLL. Returns
  ///   MIKMOD_OK and an IMikMod on success; no audio device is opened until
  ///   IMikMod.Initialize is called
  /// </summary>
  TDDMikmodCreate = function(out AMikMod: IMikMod): Integer; stdcall;

  /// <summary>
  ///   Raised by the classes that wrap the DLL
  /// </summary>
  EMikModException = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer); overload;
    constructor CreateCode(ACode: Integer; const ADetail: string); overload;
    class function TextOf(ACode: Integer): string; static;
    property Code: Integer read FCode;
  end;

implementation

{ EMikModException }

constructor EMikModException.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited CreateFmt('MikMod error %d: %s', [ACode, TextOf(ACode)]);
end;

constructor EMikModException.CreateCode(ACode: Integer; const ADetail: string);
begin
  FCode := ACode;
  if ADetail = '' then
    inherited CreateFmt('MikMod error %d: %s', [ACode, TextOf(ACode)])
  else
    inherited CreateFmt('MikMod error %d: %s (%s)',
      [ACode, TextOf(ACode), ADetail]);
end;

class function EMikModException.TextOf(ACode: Integer): string;
begin
  case ACode of
    MIKMOD_OK:                     Result := 'OK';
    MIKMOD_ERR_NOT_INITIALIZED:    Result := 'Not initialized';
    MIKMOD_ERR_ALREADY_INITIALIZED: Result := 'Already initialized';
    MIKMOD_ERR_LOAD_LIBRARY:       Result := 'Cannot load the sound library';
    MIKMOD_ERR_INIT:               Result := 'Cannot initialize the audio device';
    MIKMOD_ERR_LOAD_MODULE:        Result := 'Cannot load the module';
    MIKMOD_ERR_INVALID_ARGUMENT:   Result := 'Invalid argument';
    MIKMOD_ERR_BUSY:               Result := 'Resource busy';
    MIKMOD_ERR_NO_MODULE:          Result := 'No module loaded';
    MIKMOD_ERR_IO:                 Result := 'File error';
    MIKMOD_ERR_INTERNAL:           Result := 'Internal error';
  else
    Result := 'Unknown error';
  end;
end;

end.
