{******************************************************************************}
{                                                                              }
{  DelphiDoom: MikMod - the class the engine uses in place of the library      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mikmod.Client;

interface

uses
  System.SysUtils, DelphiDoom.Mikmod.Intf;

type
  /// <summary>
  ///   Stands for the MikMod library in the rest of the engine: works with
  ///   string and TBytes and raises EMikModException instead of returning
  ///   error codes
  /// </summary>
  /// <remarks>
  ///   Depends only on IMikMod, so it works the same with the DLL (see
  ///   TMikModLoader) and with an engine linked in the executable, or with a
  ///   fake in the tests. The client creates the player in Initialize and
  ///   releases it in Shutdown; the IMikMod passed to the constructor is not
  ///   owned
  /// </remarks>
  TMikModClient = class
  private
    FMikMod: IMikMod;
    FPlayer: IMikModPlayer;
    FStartedHere: Boolean;
    procedure Check(ACode: Integer);
    function RequirePlayer: IMikModPlayer;
  public
    constructor Create(const AMikMod: IMikMod);
    destructor Destroy; override;

    /// <summary>
    ///   Version of libmikmod inside the library, as major.minor.revision
    /// </summary>
    function LibraryVersion: string;

    /// <summary>
    ///   Text of the last error reported by the sound library, or empty
    /// </summary>
    function LastErrorText: string;

    function IsInitialized: Boolean;

    /// <summary>
    ///   Opens the audio device and creates the player. Raises
    ///   EMikModException (with the text of the library) if there is no
    ///   usable audio device
    /// </summary>
    procedure Initialize(AMixFrequency: Cardinal; AStereo, A16Bits,
      AInterpolation: Boolean; AWindow: NativeUInt; ABufferSize: Integer = 0);

    /// <summary>
    ///   Stops the music and closes the audio device (does nothing if this
    ///   client did not initialise it)
    /// </summary>
    procedure Shutdown;

    /// <summary>
    ///   AFileName must be representable in the ANSI code page
    /// </summary>
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromMemory(const AData: TBytes); overload;
    procedure LoadFromMemory(AData: Pointer; ASize: Cardinal); overload;

    procedure Play(ALoop: Boolean = True);
    procedure Stop;
    procedure Pause;
    procedure Resume;
    function IsPlaying: Boolean;
    function IsPaused: Boolean;

    /// <summary>
    ///   AVolume goes from 0 to MIKMOD_MAX_VOLUME
    /// </summary>
    procedure SetVolume(AVolume: Integer);

    /// <summary>
    ///   Mixes the next block of audio: to be called often
    /// </summary>
    procedure Update;
  end;

implementation

{ TMikModClient }

constructor TMikModClient.Create(const AMikMod: IMikMod);
begin
  inherited Create;
  if not Assigned(AMikMod) then
    raise EArgumentNilException.Create('AMikMod');
  FMikMod := AMikMod;
end;

destructor TMikModClient.Destroy;
begin
  // FMikMod is nil if the constructor failed
  if Assigned(FMikMod) then
    Shutdown;
  inherited;
end;

procedure TMikModClient.Check(ACode: Integer);
var
  LDetail: string;
begin
  if ACode = MIKMOD_OK then
    Exit;

  // Only these failures come with a text from the sound library
  case ACode of
    MIKMOD_ERR_LOAD_LIBRARY, MIKMOD_ERR_INIT, MIKMOD_ERR_LOAD_MODULE,
    MIKMOD_ERR_IO:
      LDetail := LastErrorText;
  else
    LDetail := '';
  end;
  raise EMikModException.CreateCode(ACode, LDetail);
end;

function TMikModClient.RequirePlayer: IMikModPlayer;
begin
  if not Assigned(FPlayer) then
    raise EMikModException.CreateCode(MIKMOD_ERR_NOT_INITIALIZED);
  Result := FPlayer;
end;

function TMikModClient.LibraryVersion: string;
var
  LVersion: Cardinal;
begin
  LVersion := FMikMod.GetVersion;
  Result := Format('%d.%d.%d',
    [LVersion shr 16, (LVersion shr 8) and $FF, LVersion and $FF]);
end;

function TMikModClient.LastErrorText: string;
var
  LText: AnsiString;
  LLength: Cardinal;
begin
  LLength := FMikMod.GetLastError(nil, 0);
  if LLength = 0 then
    Exit('');

  SetLength(LText, LLength);
  // The buffer includes room for the terminator
  FMikMod.GetLastError(PAnsiChar(LText), LLength + 1);
  Result := string(LText);
end;

function TMikModClient.IsInitialized: Boolean;
begin
  Result := FMikMod.IsInitialized;
end;

procedure TMikModClient.Initialize(AMixFrequency: Cardinal; AStereo, A16Bits,
  AInterpolation: Boolean; AWindow: NativeUInt; ABufferSize: Integer);
begin
  Check(FMikMod.Initialize(AMixFrequency, AStereo, A16Bits, AInterpolation,
    AWindow, ABufferSize));
  FStartedHere := True;
  try
    Check(FMikMod.CreatePlayer(FPlayer));
  except
    Shutdown;
    raise;
  end;
end;

procedure TMikModClient.Shutdown;
begin
  FPlayer := nil;
  if FStartedHere then
  begin
    FStartedHere := False;
    FMikMod.Shutdown;
  end;
end;

procedure TMikModClient.LoadFromFile(const AFileName: string);
var
  LAnsiName: AnsiString;
begin
  LAnsiName := AnsiString(AFileName);
  if string(LAnsiName) <> AFileName then
    raise EMikModException.CreateCode(MIKMOD_ERR_INVALID_ARGUMENT,
      'The file name cannot be written in the ANSI code page');
  Check(RequirePlayer.LoadFromFile(PAnsiChar(LAnsiName)));
end;

procedure TMikModClient.LoadFromMemory(const AData: TBytes);
begin
  LoadFromMemory(Pointer(AData), Length(AData));
end;

procedure TMikModClient.LoadFromMemory(AData: Pointer; ASize: Cardinal);
begin
  Check(RequirePlayer.LoadFromMemory(AData, ASize));
end;

procedure TMikModClient.Play(ALoop: Boolean);
begin
  Check(RequirePlayer.Play(ALoop));
end;

procedure TMikModClient.Stop;
begin
  Check(RequirePlayer.Stop);
end;

procedure TMikModClient.Pause;
begin
  Check(RequirePlayer.SetPaused(True));
end;

procedure TMikModClient.Resume;
begin
  Check(RequirePlayer.SetPaused(False));
end;

function TMikModClient.IsPlaying: Boolean;
begin
  Result := False;
  if Assigned(FPlayer) then
    Result := FPlayer.IsPlaying;
end;

function TMikModClient.IsPaused: Boolean;
begin
  Result := False;
  if Assigned(FPlayer) then
    Result := FPlayer.IsPaused;
end;

procedure TMikModClient.SetVolume(AVolume: Integer);
begin
  Check(RequirePlayer.SetVolume(AVolume));
end;

procedure TMikModClient.Update;
begin
  Check(RequirePlayer.Update);
end;

end.
