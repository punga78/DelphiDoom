{******************************************************************************}
{                                                                              }
{  DelphiDoom: MikMod - IMikMod on top of the Pascal tracker                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mikmod.TrackerEngine;

interface

uses
  DelphiDoom.Mikmod.Intf,
  DelphiDoom.Tracker.Output.Intf;

const
  // The version of the library that the tracker replaces (3.1.x)
  TRACKER_VERSION = $030107;

type
  /// <summary>
  ///   The IMikMod contract, with the modules played by the
  ///   tracker written in Pascal: there is no embedded MikWin library
  /// </summary>
  TTrackerMikModEngine = class(TInterfacedObject, IMikMod)
  private
    FOutputs: ITrackerOutputFactory;
    FInitialized: Boolean;
    FSampleRate: Integer;
    FPlayerExists: Boolean;
    procedure PlayerReleased;
  public
    /// <param name="AOutputs">The audio device and the worker of the players</param>
    constructor Create(const AOutputs: ITrackerOutputFactory);

    // IMikMod
    function GetVersion: Cardinal; stdcall;
    function Initialize(AMixFrequency: Cardinal; AStereo, A16Bits,
      AInterpolation: LongBool; AWindow: NativeUInt;
      ABufferSize: Integer): Integer; stdcall;
    procedure Shutdown; stdcall;
    function IsInitialized: LongBool; stdcall;
    function CreatePlayer(out APlayer: IMikModPlayer): Integer; stdcall;
    function GetLastError(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Mikmod.TrackerPlayer;

{ TTrackerMikModEngine }

constructor TTrackerMikModEngine.Create(const AOutputs: ITrackerOutputFactory);
begin
  inherited Create;
  if not Assigned(AOutputs) then
    raise EArgumentNilException.Create('AOutputs');
  FOutputs := AOutputs;
end;

function TTrackerMikModEngine.GetVersion: Cardinal;
begin
  Result := TRACKER_VERSION;
end;

function TTrackerMikModEngine.Initialize(AMixFrequency: Cardinal; AStereo, A16Bits,
  AInterpolation: LongBool; AWindow: NativeUInt; ABufferSize: Integer): Integer;
begin
  // The output is always 16 bit stereo, with interpolation; the window and the
  // size of the buffer do not matter to the waveform audio device
  if FInitialized then
    Exit(MIKMOD_ERR_ALREADY_INITIALIZED);
  if (AMixFrequency < MIKMOD_MIN_MIX_FREQUENCY) or (AMixFrequency > MIKMOD_MAX_MIX_FREQUENCY) or
    (ABufferSize < 0) then
    Exit(MIKMOD_ERR_INVALID_ARGUMENT);

  FSampleRate := Integer(AMixFrequency);
  FInitialized := True;
  Result := MIKMOD_OK;
end;

procedure TTrackerMikModEngine.Shutdown;
begin
  FInitialized := False;
end;

function TTrackerMikModEngine.IsInitialized: LongBool;
begin
  Result := FInitialized;
end;

procedure TTrackerMikModEngine.PlayerReleased;
begin
  FPlayerExists := False;
end;

function TTrackerMikModEngine.CreatePlayer(out APlayer: IMikModPlayer): Integer;
var
  LKeepAlive: IMikMod;
begin
  APlayer := nil;
  try
    if not FInitialized then
      Exit(MIKMOD_ERR_NOT_INITIALIZED);
    if FPlayerExists then
      Exit(MIKMOD_ERR_BUSY);

    // The closure holds the engine, so that it lives as long as the player
    LKeepAlive := Self;
    APlayer := TTrackerModPlayer.Create(FSampleRate,
      procedure
      begin
        if Assigned(LKeepAlive) then
          PlayerReleased;
      end, FOutputs);
    FPlayerExists := True;
    Result := MIKMOD_OK;
  except
    APlayer := nil;
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

// The tracker never fails in a way that a text would explain: the last error is
// always empty, and only the terminator is written
function TTrackerMikModEngine.GetLastError(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal;
begin
  Result := 0;
  if Assigned(ABuffer) and (ABufferSize > 0) then
    ABuffer^ := #0;
end;

end.
