{******************************************************************************}
{                                                                              }
{  DelphiDoom: MikMod - implementation of IMikModPlayer                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mikmod.Player;

interface

uses
  System.SysUtils, DelphiDoom.Mikmod.Intf;

type
  /// <summary>
  ///   What a player needs from the engine that created it (Dependency
  ///   Inversion: the player does not know TMikModEngine)
  /// </summary>
  IMikModPlayerHost = interface
    ['{0F3C7A2E-6D41-4B8A-A1C5-7E92D4B6F308}']

    /// <summary>
    ///   Identifies the current initialisation of the sound library: zero
    ///   when it is not initialised, different after each new Initialize
    /// </summary>
    function GetSession: Cardinal;

    /// <summary>
    ///   Records why an operation failed: AMessage if not empty, otherwise
    ///   the text the sound library reports
    /// </summary>
    procedure PlayerFailed(const AMessage: AnsiString);

    /// <summary>
    ///   Called once when the player is destroyed
    /// </summary>
    procedure PlayerReleased;
  end;

  /// <summary>
  ///   Drives the single module of the sound library. Created by the engine
  /// </summary>
  /// <remarks>
  ///   The calls go to the MikWin_* functions of Base\mikmod.pas, valid only
  ///   while the engine that created the player stays initialised: after a
  ///   Shutdown every call answers MIKMOD_ERR_NOT_INITIALIZED
  /// </remarks>
  TMikModPlayer = class(TInterfacedObject, IMikModPlayer)
  private
    FHost: IMikModPlayerHost;
    FSession: Cardinal;
    FLoaded: Boolean;
    // -1 until the owner asks for a volume
    FVolume: Integer;
    function CheckReady(ARequireModule: Boolean): Integer;
    function LoadFile(const AFileName: AnsiString): Integer;
    class function ToAnsiPath(const APath: string;
      out AResult: AnsiString): Boolean; static;
    class procedure WriteTempFile(const AFileName: string; AData: Pointer;
      ASize: Cardinal); static;
  public
    constructor Create(const AHost: IMikModPlayerHost);
    destructor Destroy; override;

    function LoadFromFile(AFileName: PAnsiChar): Integer; stdcall;
    function LoadFromMemory(AData: Pointer; ASize: Cardinal): Integer; stdcall;
    function Play(ALoop: LongBool): Integer; stdcall;
    function Stop: Integer; stdcall;
    function SetPaused(APaused: LongBool): Integer; stdcall;
    function SetVolume(AVolume: Integer): Integer; stdcall;
    function IsPlaying: LongBool; stdcall;
    function IsPaused: LongBool; stdcall;
    function Update: Integer; stdcall;
  end;

implementation

uses
  Winapi.Windows, System.Classes, System.IOUtils, mikmod;

{ TMikModPlayer }

constructor TMikModPlayer.Create(const AHost: IMikModPlayerHost);
begin
  inherited Create;
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FHost := AHost;
  FSession := FHost.GetSession;
  FVolume := -1;
end;

destructor TMikModPlayer.Destroy;
begin
  // FHost is nil if the constructor failed
  if Assigned(FHost) then
  begin
    try
      // The library may already be gone (Shutdown): then nothing is playing
      if FLoaded and (FHost.GetSession = FSession) then
        MikWin_Stop;
    except
      // A destructor must not raise: the slot is released in any case below
    end;
    FHost.PlayerReleased;
    FHost := nil;
  end;
  inherited;
end;

function TMikModPlayer.CheckReady(ARequireModule: Boolean): Integer;
begin
  if (FSession = 0) or (FHost.GetSession <> FSession) then
    Result := MIKMOD_ERR_NOT_INITIALIZED
  else if ARequireModule and not FLoaded then
    Result := MIKMOD_ERR_NO_MODULE
  else
    Result := MIKMOD_OK;
end;

class function TMikModPlayer.ToAnsiPath(const APath: string;
  out AResult: AnsiString): Boolean;
var
  LShortPath: string;
  LLength: DWORD;
begin
  AResult := AnsiString(APath);
  if string(AResult) = APath then
    Exit(True);

  // Characters outside the ANSI code page (e.g. a user profile folder): the
  // C library only understands ANSI paths, so try the 8.3 form
  SetLength(LShortPath, MAX_PATH);
  LLength := GetShortPathName(PChar(APath), PChar(LShortPath), MAX_PATH);
  if (LLength = 0) or (LLength >= MAX_PATH) then
    Exit(False);
  SetLength(LShortPath, LLength);

  AResult := AnsiString(LShortPath);
  Result := string(AResult) = LShortPath;
end;

class procedure TMikModPlayer.WriteTempFile(const AFileName: string;
  AData: Pointer; ASize: Cardinal);
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(AFileName, fmCreate);
  try
    LStream.WriteBuffer(PByte(AData)^, ASize);
  finally
    LStream.Free;
  end;
end;

function TMikModPlayer.LoadFile(const AFileName: AnsiString): Integer;
var
  LAttributes: DWORD;
begin
  FLoaded := False;

  // MikWin_LoadPos frees the previous module before opening the file and, if
  // the file cannot be opened, keeps the dangling pointer (a later load would
  // free it twice). So never let it try with a path that cannot be opened
  LAttributes := GetFileAttributesA(PAnsiChar(AFileName));
  if (LAttributes = INVALID_FILE_ATTRIBUTES) or
     ((LAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0) then
  begin
    FHost.PlayerFailed('File not found: ' + AFileName);
    Exit(MIKMOD_ERR_LOAD_MODULE);
  end;

  if MikWin_Load(PAnsiChar(AFileName)) then
  begin
    FLoaded := True;
    Result := MIKMOD_OK;
  end
  else
  begin
    FHost.PlayerFailed('');
    Result := MIKMOD_ERR_LOAD_MODULE;
  end;
end;

function TMikModPlayer.LoadFromFile(AFileName: PAnsiChar): Integer;
begin
  try
    Result := CheckReady(False);
    if Result <> MIKMOD_OK then
      Exit;
    if not Assigned(AFileName) or (AFileName^ = #0) then
      Exit(MIKMOD_ERR_INVALID_ARGUMENT);
    Result := LoadFile(AnsiString(AFileName));
  except
    // An exception must never cross the DLL boundary
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TMikModPlayer.LoadFromMemory(AData: Pointer; ASize: Cardinal): Integer;
var
  LTempName: string;
  LAnsiName: AnsiString;
begin
  try
    Result := CheckReady(False);
    if Result <> MIKMOD_OK then
      Exit;
    if not Assigned(AData) or (ASize = 0) or (ASize > MIKMOD_MAX_MODULE_SIZE) then
      Exit(MIKMOD_ERR_INVALID_ARGUMENT);

    // The C library reads modules only from a FILE*: hand it a temporary file
    // that lives just as long as the load
    LTempName := '';
    try
      try
        LTempName := TPath.GetTempFileName;
        WriteTempFile(LTempName, AData, ASize);
      except
        on E: Exception do
        begin
          FHost.PlayerFailed(AnsiString(E.Message));
          Exit(MIKMOD_ERR_IO);
        end;
      end;

      if not ToAnsiPath(LTempName, LAnsiName) then
      begin
        FHost.PlayerFailed('The temporary path cannot be written in ANSI');
        Exit(MIKMOD_ERR_IO);
      end;

      Result := LoadFile(LAnsiName);
    finally
      if LTempName <> '' then
        System.SysUtils.DeleteFile(LTempName);
    end;
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TMikModPlayer.Play(ALoop: LongBool): Integer;
begin
  try
    Result := CheckReady(True);
    if Result <> MIKMOD_OK then
      Exit;
    MikWin_Play(ALoop);
    // Starting a module resets its volume
    if FVolume >= 0 then
      Player_SetVolume(SWORD(FVolume));
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TMikModPlayer.Stop: Integer;
begin
  try
    Result := CheckReady(False);
    if (Result = MIKMOD_OK) and FLoaded then
      MikWin_Stop;
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TMikModPlayer.SetPaused(APaused: LongBool): Integer;
var
  LCurrentlyPaused: Boolean;
  LWanted: Boolean;
begin
  try
    Result := CheckReady(True);
    if Result <> MIKMOD_OK then
      Exit;
    LCurrentlyPaused := MikWin_Paused;
    LWanted := APaused;
    // MikWin_Pause only toggles
    if LCurrentlyPaused <> LWanted then
      MikWin_Pause;
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TMikModPlayer.SetVolume(AVolume: Integer): Integer;
begin
  try
    Result := CheckReady(False);
    if Result <> MIKMOD_OK then
      Exit;
    if (AVolume < 0) or (AVolume > MIKMOD_MAX_VOLUME) then
      Exit(MIKMOD_ERR_INVALID_ARGUMENT);

    FVolume := AVolume;
    if FLoaded then
      Player_SetVolume(SWORD(AVolume));
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TMikModPlayer.IsPlaying: LongBool;
begin
  Result := False;
  try
    if CheckReady(True) = MIKMOD_OK then
      Result := MikWin_Playing;
  except
    Result := False;
  end;
end;

function TMikModPlayer.IsPaused: LongBool;
begin
  Result := False;
  try
    if CheckReady(True) = MIKMOD_OK then
      Result := MikWin_Paused;
  except
    Result := False;
  end;
end;

function TMikModPlayer.Update: Integer;
begin
  try
    Result := CheckReady(False);
    if (Result = MIKMOD_OK) and FLoaded then
      MikWin_Update;
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

end.
