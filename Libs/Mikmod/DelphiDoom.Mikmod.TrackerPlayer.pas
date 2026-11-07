{******************************************************************************}
{                                                                              }
{  DelphiDoom: MikMod - IMikModPlayer on top of the Pascal tracker             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mikmod.TrackerPlayer;

interface

uses
  System.SysUtils,
  DelphiDoom.Mikmod.Intf,
  DelphiDoom.Tracker.Output.Intf,
  DelphiDoom.Tracker.Playback,
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   Loads MOD, S3M, XM and IT modules and plays them with the tracker of
  ///   DelphiDoom, on the audio output it is given
  /// </summary>
  TTrackerModPlayer = class(TInterfacedObject, IMikModPlayer)
  private
    FSampleRate: Integer;
    FOnReleased: TProc;
    FOutputs: ITrackerOutputFactory;
    FModule: TTrackerModule;
    FPlayback: TTrackerPlayback;
    FVolume: Integer;
    procedure UnloadModule;
    function LoadBytes(const AData: TBytes): Integer;
  public
    /// <param name="ASampleRate">Frames per second of the output</param>
    /// <param name="AOnReleased">Called when the player is destroyed; may be nil</param>
    /// <param name="AOutputs">The audio device and the worker of the playback</param>
    constructor Create(const ASampleRate: Integer; const AOnReleased: TProc;
      const AOutputs: ITrackerOutputFactory);
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
  System.IOUtils,
  DelphiDoom.Tracker.Loader.It,
  DelphiDoom.Tracker.Loader.ProTracker,
  DelphiDoom.Tracker.Loader.S3m,
  DelphiDoom.Tracker.Loader.Xm;

{ TTrackerModPlayer }

constructor TTrackerModPlayer.Create(const ASampleRate: Integer; const AOnReleased: TProc;
  const AOutputs: ITrackerOutputFactory);
begin
  inherited Create;
  if not Assigned(AOutputs) then
    raise EArgumentNilException.Create('AOutputs');
  FOutputs := AOutputs;
  FSampleRate := ASampleRate;
  FOnReleased := AOnReleased;
  FVolume := MIKMOD_MAX_VOLUME;
end;

destructor TTrackerModPlayer.Destroy;
begin
  try
    UnloadModule;
  except
    // A destructor must not raise
  end;
  if Assigned(FOnReleased) then
    FOnReleased();
  inherited Destroy;
end;

procedure TTrackerModPlayer.UnloadModule;
begin
  // The thread uses the module: it ends first
  FreeAndNil(FPlayback);
  FreeAndNil(FModule);
end;

function TTrackerModPlayer.LoadBytes(const AData: TBytes): Integer;
var
  LModule: TTrackerModule;
begin
  UnloadModule;
  try
    if TTrackerXmLoader.Detect(AData) then
      LModule := TTrackerXmLoader.Load(AData)
    else if TTrackerItLoader.Detect(AData) then
      LModule := TTrackerItLoader.Load(AData)
    else if TTrackerS3mLoader.Detect(AData) then
      LModule := TTrackerS3mLoader.Load(AData)
    else if TTrackerModLoader.Detect(AData) then
      LModule := TTrackerModLoader.Load(AData)
    else
      Exit(MIKMOD_ERR_LOAD_MODULE);
  except
    on ETrackerException do
      Exit(MIKMOD_ERR_LOAD_MODULE);
  end;

  FModule := LModule;
  FPlayback := TTrackerPlayback.Create(FModule, FSampleRate, FOutputs);
  FPlayback.Volume := FVolume;
  Result := MIKMOD_OK;
end;

function TTrackerModPlayer.LoadFromFile(AFileName: PAnsiChar): Integer;
var
  LPath: string;
  LData: TBytes;
begin
  try
    if not Assigned(AFileName) or (AFileName^ = #0) then
      Exit(MIKMOD_ERR_INVALID_ARGUMENT);
    LPath := string(AnsiString(AFileName));
    if not TFile.Exists(LPath) then
      Exit(MIKMOD_ERR_LOAD_MODULE);
    try
      LData := TFile.ReadAllBytes(LPath);
    except
      on EInOutError do
        Exit(MIKMOD_ERR_IO);
    end;
    if Length(LData) > MIKMOD_MAX_MODULE_SIZE then
      Exit(MIKMOD_ERR_INVALID_ARGUMENT);
    Result := LoadBytes(LData);
  except
    // An exception must never cross the DLL boundary
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TTrackerModPlayer.LoadFromMemory(AData: Pointer; ASize: Cardinal): Integer;
var
  LData: TBytes;
begin
  try
    if not Assigned(AData) or (ASize = 0) or (ASize > MIKMOD_MAX_MODULE_SIZE) then
      Exit(MIKMOD_ERR_INVALID_ARGUMENT);
    SetLength(LData, ASize);
    Move(AData^, LData[0], ASize);
    Result := LoadBytes(LData);
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TTrackerModPlayer.Play(ALoop: LongBool): Integer;
begin
  try
    if not Assigned(FPlayback) then
      Exit(MIKMOD_ERR_NO_MODULE);
    FPlayback.Volume := FVolume;
    FPlayback.Play(ALoop);
    Result := MIKMOD_OK;
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TTrackerModPlayer.Stop: Integer;
begin
  try
    if Assigned(FPlayback) then
      FPlayback.Stop;
    Result := MIKMOD_OK;
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TTrackerModPlayer.SetPaused(APaused: LongBool): Integer;
begin
  try
    if not Assigned(FPlayback) then
      Exit(MIKMOD_ERR_NO_MODULE);
    if APaused then
      FPlayback.Pause
    else
      FPlayback.Resume;
    Result := MIKMOD_OK;
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

function TTrackerModPlayer.SetVolume(AVolume: Integer): Integer;
begin
  if (AVolume < 0) or (AVolume > MIKMOD_MAX_VOLUME) then
    Exit(MIKMOD_ERR_INVALID_ARGUMENT);
  FVolume := AVolume;
  if Assigned(FPlayback) then
    FPlayback.Volume := AVolume;
  Result := MIKMOD_OK;
end;

function TTrackerModPlayer.IsPlaying: LongBool;
begin
  Result := Assigned(FPlayback) and FPlayback.IsPlaying;
end;

function TTrackerModPlayer.IsPaused: LongBool;
begin
  Result := Assigned(FPlayback) and FPlayback.Paused;
end;

function TTrackerModPlayer.Update: Integer;
begin
  // The worker of the playback does the work
  Result := MIKMOD_OK;
end;

end.
