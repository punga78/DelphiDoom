{******************************************************************************}
{                                                                              }
{  DelphiDoom: MikMod - implementation of IMikMod on top of Base\mikmod.pas    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mikmod.Engine;

interface

uses
  DelphiDoom.Mikmod.Intf, DelphiDoom.Mikmod.Player;

type
  /// <summary>
  ///   Implements IMikMod using the binding of the third-party MikWin.dll
  ///   (Base\mikmod.pas), which embeds the DLL and loads it from memory
  /// </summary>
  /// <remarks>
  ///   Creating the engine is free: the embedded DLL is loaded and the audio
  ///   device opened only by Initialize. The sound library is a process-wide
  ///   singleton, so a second engine cannot be initialised while another one
  ///   is (MIKMOD_ERR_BUSY). Not thread safe: use it from one thread
  /// </remarks>
  TMikModEngine = class(TInterfacedObject, IMikMod, IMikModPlayerHost)
  private
    FInitialized: Boolean;
    FSession: Cardinal;
    FPlayerExists: Boolean;
    FLastError: AnsiString;
    class function BindingComplete: Boolean; static;
    procedure CaptureLibraryError;
    procedure CloseLibrary;
  public
    destructor Destroy; override;

    // IMikMod
    function GetVersion: Cardinal; stdcall;
    function Initialize(AMixFrequency: Cardinal; AStereo, A16Bits,
      AInterpolation: LongBool; AWindow: NativeUInt;
      ABufferSize: Integer): Integer; stdcall;
    procedure Shutdown; stdcall;
    function IsInitialized: LongBool; stdcall;
    function CreatePlayer(out APlayer: IMikModPlayer): Integer; stdcall;
    function GetLastError(ABuffer: PAnsiChar;
      ABufferSize: Cardinal): Cardinal; stdcall;

    // IMikModPlayerHost
    function GetSession: Cardinal;
    procedure PlayerFailed(const AMessage: AnsiString);
    procedure PlayerReleased;
  end;

implementation

uses
  mikmod;

var
  // The engine that owns the sound library right now
  GActiveEngine: TMikModEngine = nil;
  GLastSession: Cardinal = 0;

{ TMikModEngine }

destructor TMikModEngine.Destroy;
begin
  if FInitialized then
  begin
    try
      CloseLibrary;
    except
      // A destructor must not raise
    end;
  end;
  inherited;
end;

class function TMikModEngine.BindingComplete: Boolean;
begin
  // The exports of MikWin.dll used by the engine and by the players
  Result := Assigned(MikWin_Init) and Assigned(MikWin_Free) and
    Assigned(MikWin_Load) and Assigned(MikWin_Play) and
    Assigned(MikWin_Stop) and Assigned(MikWin_Pause) and
    Assigned(MikWin_Paused) and Assigned(MikWin_Update) and
    Assigned(MikWin_Playing) and Assigned(MikWin_GetErrorText) and
    Assigned(Player_SetVolume);
end;

procedure TMikModEngine.CaptureLibraryError;
var
  LText: PAnsiChar;
begin
  FLastError := '';
  if Assigned(MikWin_GetErrorText) then
  begin
    LText := MikWin_GetErrorText;
    if Assigned(LText) then
      FLastError := AnsiString(LText);
  end;
end;

procedure TMikModEngine.CloseLibrary;
begin
  // First of all: the players must stop calling into the library
  FInitialized := False;
  if GActiveEngine = Self then
    GActiveEngine := nil;
  try
    MikWin_Free;
  finally
    MikWin_FreeLibrary;
  end;
end;

function TMikModEngine.GetVersion: Cardinal;
begin
  Result := Cardinal(LIBMIKMOD_VERSION);
end;

function TMikModEngine.Initialize(AMixFrequency: Cardinal; AStereo, A16Bits,
  AInterpolation: LongBool; AWindow: NativeUInt; ABufferSize: Integer): Integer;
begin
  try
    if FInitialized then
      Exit(MIKMOD_ERR_ALREADY_INITIALIZED);
    if Assigned(GActiveEngine) then
      Exit(MIKMOD_ERR_BUSY);
    if (AMixFrequency < MIKMOD_MIN_MIX_FREQUENCY) or
       (AMixFrequency > MIKMOD_MAX_MIX_FREQUENCY) or (ABufferSize < 0) then
      Exit(MIKMOD_ERR_INVALID_ARGUMENT);

    if not MikWin_LoadLibrary then
    begin
      FLastError := 'Cannot load the embedded MikWin library';
      Exit(MIKMOD_ERR_LOAD_LIBRARY);
    end;

    if not BindingComplete then
    begin
      FLastError := 'The embedded MikWin library lacks an expected export';
      MikWin_FreeLibrary;
      Exit(MIKMOD_ERR_LOAD_LIBRARY);
    end;

    if not MikWin_Init(UWORD(AMixFrequency), AStereo, A16Bits, AInterpolation,
      AWindow, ABufferSize) then
    begin
      CaptureLibraryError;
      try
        MikWin_Free;
      finally
        MikWin_FreeLibrary;
      end;
      Exit(MIKMOD_ERR_INIT);
    end;

    Inc(GLastSession);
    FSession := GLastSession;
    FInitialized := True;
    GActiveEngine := Self;
    FLastError := '';
    Result := MIKMOD_OK;
  except
    // An exception must never cross the DLL boundary
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

procedure TMikModEngine.Shutdown;
begin
  try
    if FInitialized then
      CloseLibrary;
  except
    // An exception must never cross the DLL boundary; CloseLibrary has
    // already marked the engine as not initialised
  end;
end;

function TMikModEngine.IsInitialized: LongBool;
begin
  Result := FInitialized;
end;

function TMikModEngine.CreatePlayer(out APlayer: IMikModPlayer): Integer;
begin
  APlayer := nil;
  try
    if not FInitialized then
      Exit(MIKMOD_ERR_NOT_INITIALIZED);
    // The sound library has a single current module
    if FPlayerExists then
      Exit(MIKMOD_ERR_BUSY);

    APlayer := TMikModPlayer.Create(Self);
    FPlayerExists := True;
    Result := MIKMOD_OK;
  except
    APlayer := nil;
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TMikModEngine.GetLastError(ABuffer: PAnsiChar;
  ABufferSize: Cardinal): Cardinal;
var
  LCount: Cardinal;
begin
  Result := Length(FLastError);
  if not Assigned(ABuffer) or (ABufferSize = 0) then
    Exit;

  LCount := Result;
  if LCount > ABufferSize - 1 then
    LCount := ABufferSize - 1;
  if LCount > 0 then
    Move(PAnsiChar(FLastError)^, ABuffer^, LCount);
  ABuffer[LCount] := #0;
end;

function TMikModEngine.GetSession: Cardinal;
begin
  if FInitialized then
    Result := FSession
  else
    Result := 0;
end;

procedure TMikModEngine.PlayerFailed(const AMessage: AnsiString);
begin
  if AMessage <> '' then
    FLastError := AMessage
  else
    CaptureLibraryError;
end;

procedure TMikModEngine.PlayerReleased;
begin
  FPlayerExists := False;
end;

end.
