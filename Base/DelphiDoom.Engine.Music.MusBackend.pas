{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - music backend of the midi stream (MUS)                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Music.MusBackend;

interface

uses
  Winapi.MMSystem,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Audio.Types,
  DelphiDoom.M2m.Intf,
  DelphiDoom.M2m.Client,
  DelphiDoom.Engine.Shutdown.Intf,
  DelphiDoom.Engine.Music.Intf,
  DelphiDoom.Engine.Music.BackendBase;

type
  /// <summary>
  ///   MUS songs and the MIDI files that are converted to MUS (snd_uselegacymidiplayer = 2),
  ///   played with the midi stream of Windows: the code of the old i_music (I_RegisterMus,
  ///   I_*Mus). The events of a song come from TMusConverter; the stream is opened at the start
  ///   and at every song, and the backends of the MIDI files close it through IEngineMidiStream
  /// </summary>
  TMusMusicBackend = class(TEngineMusicBackendBase, IEngineMidiStream)
  strict private
    const
      HEADER_COUNT = 2;
    type
      /// <summary>A song: its events, the events before the volume, and the two headers</summary>
      TMusSong = record
        Events: TArray<TMusMidiEvent>;
        OriginalEvents: TArray<TMusMidiEvent>;
        NextEvent: Integer;
        Headers: array[0..HEADER_COUNT - 1] of TMidiHdr;
      end;
      PMusSong = ^TMusSong;
    var
      FConverter: TM2mClient;
      FCommandLine: ICommandLine;
      FLog: ILog;
      FShutdown: IEngineShutdown;
      FStream: HMIDISTRM;
      FDevice: Cardinal;
      FCapabilities: TMidiOutCaps;
      FStarted: Boolean;
      FVolumeSet: Integer;
      FCurrent: PMusSong;
    procedure Open;
    procedure StopSong(ASong: PMusSong);
    function TryConvertMidiFile(AData: Pointer; ASize: Integer; ASong: PMusSong): Boolean;
    function TryConvert(AData: Pointer; ASize: Integer; ASong: PMusSong): Boolean;
  public
    /// <summary>
    ///   AM2m converts the MIDI files to MUS; ACommandLine is where -nomusic is looked for;
    ///   ALog receives the warnings of the midi device and AShutdown stops the game on its
    ///   errors (I_Error); EArgumentNilException if one of them is nil
    /// </summary>
    constructor Create(const AM2m: IM2m; const ACommandLine: ICommandLine; const ALog: ILog;
      const AShutdown: IEngineShutdown);
    destructor Destroy; override;
    procedure Initialize; override;
    procedure Shutdown; override;
    function Register(AData: Pointer; ASize: Integer;
      out AContext: NativeInt): TMusicRegisterResult; override;
    procedure Play(AContext: NativeInt; ALooping: Boolean); override;
    procedure Stop(AContext: NativeInt); override;
    procedure Pause(AContext: NativeInt); override;
    procedure Resume(AContext: NativeInt); override;
    procedure Unregister(AContext: NativeInt); override;
    procedure SetVolume(AVolume: Integer); override;
    procedure Process; override;
    /// <summary>IEngineMidiStream: the old I_StopMus</summary>
    procedure Close;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows,
  d_delphi,
  i_system,
  i_midi,
  s_sound,
  DelphiDoom.Audio.MusConverter,
  DelphiDoom.Midi.Types,
  DelphiDoom.Midi.Volume,
  DelphiDoom.Midi.EventFeeder;

const
  SM2mIsNil = 'TMusMusicBackend.Create(): AM2m is nil';
  SCommandLineIsNil = 'TMusMusicBackend.Create(): ACommandLine is nil';
  // the events given to the stream at a time
  MAX_MIDI_EVENTS = 512;

{ TMusMusicBackend }

constructor TMusMusicBackend.Create(const AM2m: IM2m; const ACommandLine: ICommandLine;
  const ALog: ILog; const AShutdown: IEngineShutdown);
begin
  inherited Create;
  if not Assigned(AM2m) then
    raise EArgumentNilException.Create(SM2mIsNil);
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.Create(SCommandLineIsNil);
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  if not Assigned(AShutdown) then
    raise EArgumentNilException.Create('AShutdown');
  FCommandLine := ACommandLine;
  FLog := ALog;
  FShutdown := AShutdown;
  FConverter := TM2mClient.Create(AM2m);
  FVolumeSet := -1;
end;

destructor TMusMusicBackend.Destroy;
begin
  FConverter.Free;
  inherited Destroy;
end;

procedure TMusMusicBackend.Initialize;
begin
  Open;
end;

procedure TMusMusicBackend.Shutdown;
begin
  Close;
end;

// The old I_InitMus
procedure TMusMusicBackend.Open;
var
  rc: MMRESULT;
  numdev: LongWord;
  i: integer;
begin
  if FCommandLine.IndexOf('-nomusic') <> 0 then
    exit;

  if FStream <> 0 then
    exit;

  ZeroMemory(@FCapabilities, SizeOf(FCapabilities));
  FDevice := I_SelectDefaultMidiDevice;

  // First try midi mapper
  rc := midiOutGetDevCaps(FDevice, @FCapabilities, SizeOf(FCapabilities));
  if rc <> MMSYSERR_NOERROR then
    FShutdown.Fail(Format('I_InitMusic(): midiOutGetDevCaps failed, return value = %d', [rc]));

  // midiStreamOut not supported (should not happen with MIDI MAPPER...)
  // Try to enumurate all midi devices
  if FCapabilities.dwSupport and MIDICAPS_STREAM = 0 then
  begin
    numdev := midiOutGetNumDevs;
    if numdev = 0 then // fatal
      exit;

    for i := -1 to numdev - 1 do
    begin
      rc := midiOutGetDevCaps(i, @FCapabilities, SizeOf(FCapabilities));
      if rc <> MMSYSERR_NOERROR then
        FShutdown.Fail(Format('I_InitMusic(): midiOutGetDevCaps failed, return value = %d', [rc]));

      if FCapabilities.dwSupport and MIDICAPS_STREAM <> 0 then
      begin
        FDevice := i;
        break;
      end;
    end;
  end;

  if FDevice = MIDI_MAPPER then
    printf(' Using midi mapper'#13#10)
  else
    printf(' Using midi device %d'#13#10, [FDevice]);

  rc := midiStreamOpen(@FStream, @FDevice, 1, 0, 0, CALLBACK_NULL);
  if rc <> MMSYSERR_NOERROR then
  begin
    FStream := 0;
    FLog.Warning(Format('I_InitMusic(): midiStreamOpen failed, result = %d'#13#10, [rc]));
  end;

  FStarted := false;
end;

// The old I_StopMus
procedure TMusMusicBackend.Close;
var
  rc: MMRESULT;
begin
  if FStream <> 0 then
  begin
    rc := midiStreamStop(FStream);
    if rc <> MMSYSERR_NOERROR then
      FLog.Warning(Format('I_ShutDownMusic(): midiStreamStop failed, result = %d'#13#10, [rc]));

    FStarted := false;
    rc := midiStreamClose(FStream);
    if rc <> MMSYSERR_NOERROR then
      FLog.Warning(Format('I_ShutDownMusic(): midiStreamClose failed, result = %d'#13#10, [rc]));

    FStream := 0;
  end;
end;

// The old I_StopMusicMus
procedure TMusMusicBackend.StopSong(ASong: PMusSong);
var
  i: integer;
  rc: MMRESULT;
begin
  if not ((ASong <> nil) and (FStream <> 0)) then
    exit;

  rc := midiOutReset(HMIDIOUT(FStream));
  if rc <> MMSYSERR_NOERROR then
    FLog.Warning(Format('I_StopMusic(): midiOutReset failed, result = %d'#13#10, [rc]));

  FStarted := false;

  for i := 0 to HEADER_COUNT - 1 do
  begin
    if ASong.Headers[i].lpData <> nil then
    begin
      rc := midiOutUnprepareHeader(HMIDIOUT(FStream), @ASong.Headers[i], SizeOf(TMidiHdr));
      if rc <> MMSYSERR_NOERROR then
        FLog.Warning(Format('I_StopMusic(): midiOutUnprepareHeader failed, result = %d'#13#10, [rc]));

      ASong.Headers[i].lpData := nil;
      ASong.Headers[i].dwFlags := MHDR_DONE or MHDR_ISSTRM;
    end;
  end;
  ASong.NextEvent := 0;
end;

// The old I_MidToMus: a MIDI file converted to MUS, and the MUS to events
function TMusMusicBackend.TryConvertMidiFile(AData: Pointer; ASize: Integer;
  ASong: PMusSong): Boolean;
var
  LMus: TBytes;
begin
  Result := False;
  if snd_uselegacymidiplayer <> 2 then
    Exit;
  if not TMusConverter.IsMidiFile(AData, ASize) then
    Exit;

  try
    LMus := FConverter.ConvertMidiToMus(AData, ASize);
  except
    on EM2mException do
      Exit;
  end;

  if not TMusConverter.IsMus(System.PByte(LMus), Length(LMus)) then
    Exit;
  Result := TryConvert(System.PByte(LMus), Length(LMus), ASong);
end;

// The old I_MusToMidi: an error of the song stops the game, as before
function TMusMusicBackend.TryConvert(AData: Pointer; ASize: Integer; ASong: PMusSong): Boolean;
begin
  try
    Result := TMusConverter.TryConvert(AData, ASize, miditempo, nil, ASong.Events);
  except
    on E: EMusConversionException do
    begin
      FShutdown.Fail(E.Message);
      Result := False;
    end;
  end;
  // the old code wrote the warning with I_Warning
  if not Result and not TMusConverter.IsMidiFile(AData, ASize) then
    FLog.Warning('I_MusToMidi(): Not a MUS file'#13#10);
end;

// The old I_RegisterMus
function TMusMusicBackend.Register(AData: Pointer; ASize: Integer;
  out AContext: NativeInt): TMusicRegisterResult;
var
  LSong: PMusSong;
  i: integer;
begin
  AContext := 0;
  New(LSong);
  LSong.NextEvent := 0;
  ZeroMemory(@LSong.Headers, SizeOf(LSong.Headers));

  if not (TryConvertMidiFile(AData, ASize, LSong) or TryConvert(AData, ASize, LSong)) then
  begin
    Dispose(LSong);
    Result := TMusicRegisterResult.NotRecognized;
    exit;
  end;

  FVolumeSet := -1; // Force music update
  LSong.OriginalEvents := Copy(LSong.Events);

  Open;

  if FStream = 0 then
  begin
    // with -nomusic the midi stream is never opened: it is not worth a warning for each song
    if FCommandLine.IndexOf('-nomusic') = 0 then
      FLog.Warning('I_RegisterSong(): Could not initialize midi stream'#13#10);
    Dispose(LSong);
    Result := TMusicRegisterResult.Failed;
    exit;
  end;

  for i := 0 to HEADER_COUNT - 1 do
  begin
    LSong.Headers[i].lpData := nil;
    LSong.Headers[i].dwFlags := MHDR_ISSTRM or MHDR_DONE;
  end;

  AContext := NativeInt(LSong);
  Result := TMusicRegisterResult.Registered;
end;

procedure TMusMusicBackend.Play(AContext: NativeInt; ALooping: Boolean);
begin
  if (AContext <> 0) and (FStream <> 0) then
    FCurrent := PMusSong(AContext);
end;

// Stops a song over 3 seconds.
procedure TMusMusicBackend.Stop(AContext: NativeInt);
begin
  if (AContext <> 0) and (FStream <> 0) then
  begin
    StopSong(PMusSong(AContext));

    if PMusSong(AContext) = FCurrent then
      FCurrent := nil;
  end;
end;

procedure TMusMusicBackend.Pause(AContext: NativeInt);
var
  rc: MMRESULT;
begin
  if FStream = 0 then
    exit;

  rc := midiStreamPause(FStream);
  if rc <> MMSYSERR_NOERROR then
    FShutdown.Fail(Format('I_PauseSong(): midiStreamRestart failed, return value = %d', [rc]));
end;

procedure TMusMusicBackend.Resume(AContext: NativeInt);
var
  rc: MMRESULT;
begin
  if FStream = 0 then
    exit;

  rc := midiStreamRestart(FStream);
  if rc <> MMSYSERR_NOERROR then
    FShutdown.Fail(Format('I_ResumeSong(): midiStreamRestart failed, return value = %d', [rc]));
end;

procedure TMusMusicBackend.Unregister(AContext: NativeInt);
var
  LSong: PMusSong;
begin
  if AContext = 0 then
    exit;

  LSong := PMusSong(AContext);
  if LSong = FCurrent then
    FCurrent := nil;
  Dispose(LSong);
end;

// The old I_SetMusicVolumeMus. It wrote AVolume in snd_MusicVolume too: S_SetMusicVolume, the
// only one that sets the volume, writes it at once after
procedure TMusMusicBackend.SetVolume(AVolume: Integer);
var
  rc: MMRESULT;
  vol100: integer;
  ch: DWORD;
begin
// Set volume on output device.
  if (FCurrent <> nil) and (AVolume = 0) and FStarted then
    StopSong(FCurrent);

  if win_vista_or_newer and (FCurrent <> nil) then
  begin
    vol100 := TMidiVolume.PercentOfLevel(AVolume);

    for ch := 0 to 15 do
      midiOutShortMsg(HMIDIOUT(FStream), TMidiVolume.ControlChangeMessage(ch, Cardinal(vol100)));

    // the events of the song are the original ones with the new volume
    if Length(FCurrent.Events) > 0 then
      TMidiVolume.ApplyToEvents(PMidiStreamEvent(@FCurrent.Events[0]),
        PMidiStreamEvent(@FCurrent.OriginalEvents[0]), Length(FCurrent.Events), Cardinal(vol100));
  end
  else
  begin
    if FCapabilities.dwSupport and MIDICAPS_VOLUME <> 0 then
    begin
      rc := midiOutSetVolume(HMIDIOUT(FStream),
        _SHLW($FFFF * AVolume div 16, 16) or _SHLW(($FFFF * AVolume div 16), 0));
      if rc <> MMSYSERR_NOERROR then
        FLog.Warning(Format('I_SetMusicVolume(): midiOutSetVolume failed, return value = %d'#13#10, [rc]));
    end
    else
      FLog.Warning('I_SetMusicVolume(): Midi device dos not support volume control'#13#10);
  end;
end;

// The old I_ProcessMusicMus: the headers that the stream has played get the next events
procedure TMusMusicBackend.Process;
var
  header: PMidiHdr;
  length: integer;
  first: integer;
  i: integer;
  rc: MMRESULT;
begin
  if (snd_MusicVolume = 0) or (FCurrent = nil) then
    exit;

  for i := 0 to HEADER_COUNT - 1 do
  begin
    header := @FCurrent.Headers[i];
    if header.dwFlags and MHDR_DONE <> 0 then
    begin
      if header.lpData <> nil then
      begin
        rc := midiOutUnprepareHeader(HMIDIOUT(FStream), header, SizeOf(TMidiHdr));
        if rc <> MMSYSERR_NOERROR then
          FLog.Warning(Format('I_ProcessMusic(): midiOutUnprepareHeader failed, result = %d'#13#10, [rc]));
      end;

      if FVolumeSet <> snd_MusicVolume then
      begin
        SetVolume(snd_MusicVolume);
        FVolumeSet := snd_MusicVolume;
      end;

      // the piece of the song that goes next: at most MAX_MIDI_EVENTS events, then from the start
      TMidiEventFeeder.NextPiece(System.Length(FCurrent.Events), MAX_MIDI_EVENTS,
        FCurrent.NextEvent, first, length);
      header.lpData := PAnsiChar(@FCurrent.Events[first]);
      length := length * SizeOf(TMusMidiEvent);
      header.dwBufferLength := length;
      header.dwBytesRecorded := length;
      header.dwFlags := MHDR_ISSTRM;
      rc := midiOutPrepareHeader(HMIDIOUT(FStream), header, SizeOf(TMidiHdr));
      if rc <> MMSYSERR_NOERROR then
        FShutdown.Fail(Format('I_ProcessMusic(): midiOutPrepareHeader failed, return value = %d', [rc]));
      if not FStarted then
      begin
        rc := midiStreamRestart(FStream);
        if rc <> MMSYSERR_NOERROR then
          FShutdown.Fail(Format('I_ProcessMusic(): midiStreamRestart failed, return value = %d', [rc]));
        FStarted := true;
      end;
      rc := midiStreamOut(FStream, header, SizeOf(TMidiHdr));
      if rc <> MMSYSERR_NOERROR then
        FShutdown.Fail(Format('I_ProcessMusic(): midiStreamOut failed, return value = %d', [rc]));
    end;
  end;
end;

end.
