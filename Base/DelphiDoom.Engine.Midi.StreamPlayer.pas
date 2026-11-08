{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - plays a MIDI file with the midi stream of Windows       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from the CMIDI sample of Microsoft                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Midi.StreamPlayer;

{$WARN SYMBOL_DEPRECATED OFF}

interface

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.MMSystem,
  DelphiDoom.Midi.Intf;

type
  /// <summary>
  ///   The device side of the old TMidi (i_midi_new): the midi stream of Windows, its two
  ///   buffers, the callback that refills them and the volume of the channels. The events come
  ///   from an IMidiStreamSequencer, which knows nothing of the system. It plays one song, and
  ///   the player of the engine makes a new one for the next
  /// </summary>
  TEngineMidiStreamPlayer = class
  strict private
    const
      NUM_CHANNELS = 16;
      NUM_STREAM_BUFFERS = 2;
      // the bytes of a buffer of the stream
      OUT_BUFFER_SIZE = 1024;
      DEBUG_CALLBACK_TIMEOUT = 2000;
      // the states of the callback
      STATUS_KILLCALLBACK = 100;
      STATUS_CALLBACKDEAD = 200;
      STATUS_WAITINGFOREND = 300;
    var
      FSequencer: IMidiStreamSequencer;
      FPlaying: Boolean;
      FPaused: Boolean;
      FStream: HMIDISTRM;
      FDeviceID: UINT;
      FBuffers: array[0..NUM_STREAM_BUFFERS - 1] of TMidiHdr;
      FBuffersPrepared: Boolean;
      FCurrentBuffer: Integer;
      FEmptyBuffers: Integer;
      FCallbackStatus: UINT;
      FBufferReturnEvent: THandle;
      FVolumes: array[0..NUM_CHANNELS - 1] of Cardinal;
      FVolume: Integer;
    procedure MidiError(AResult: MMRESULT);
    procedure FreeBuffers;
    function StreamBufferSetup: Boolean;
    procedure FillBuffer(AIndex: Integer; const ABytes: TBytes);
    procedure SetChannelVolume(AChannel, APercent: Cardinal);
    procedure SetVolumeOfAllChannels(APercent: Cardinal);
  public
    /// <summary>
    ///   ASequencer has the song loaded; ADeviceID is the midi device that plays it.
    ///   EArgumentNilException if the sequencer is nil
    /// </summary>
    constructor Create(const ASequencer: IMidiStreamSequencer; ADeviceID: UINT);
    destructor Destroy; override;

    /// <summary>
    ///   Opens the stream and writes the first buffers. False if the device does not open
    /// </summary>
    function Load: Boolean;
    /// <summary>Starts the song; ALoop makes it start again at its end</summary>
    function Play(ALoop: Boolean): Boolean;
    /// <summary>Stops the song; AReopen opens the stream again, ready for another Play</summary>
    function Stop(AReopen: Boolean = True): Boolean;
    function Pause: Boolean;
    function Resume: Boolean;
    function IsPlaying: Boolean;
    function IsPaused: Boolean;
    /// <summary>The volume of the whole song, in percent (0..100)</summary>
    procedure SetMasterVolume(APercent: Integer);

    // The calls that the callback of the stream makes; they are not for anyone else
    procedure OnMidiOutDone;
    procedure OnMidiOutPositionCB(const AEvent: TMidiEvent);
  end;

implementation

uses
  System.SysUtils,
  i_system,
  DelphiDoom.Midi.Types,
  DelphiDoom.Midi.Volume;

const
  VOLUME_INIT = 100;
  SSequencerIsNil = 'TEngineMidiStreamPlayer.Create(): ASequencer is nil';
  SCannotCreateEvent = 'TEngineMidiStreamPlayer.Create(): Can not create event';
  SCallbackWithoutPlayer = 'MidiProc(): Midi object is null';
  SCallbackWithoutHeader = 'MidiProc(): Midi header is null';

//==============================================================================
//
// MidiProc
// The callback of the stream: it is called by a thread of Windows
//
//==============================================================================
procedure MidiProc(AMidi: HMIDIOUT; AMessage: UINT; AInstance, AParam1, AParam2: DWORD_PTR); stdcall;
var
  LPlayer: TEngineMidiStreamPlayer;
  LHeader: PMidiHdr;
begin
  LPlayer := TEngineMidiStreamPlayer(Pointer(AInstance));
  if LPlayer = nil then
    I_Error(SCallbackWithoutPlayer);
  LHeader := PMidiHdr(AParam1);

  case AMessage of
    MOM_DONE:
      begin
        if LHeader = nil then
          I_Error(SCallbackWithoutHeader);
        LPlayer.OnMidiOutDone;
      end;
    MOM_POSITIONCB:
      begin
        if LHeader = nil then
          I_Error(SCallbackWithoutHeader);
        LPlayer.OnMidiOutPositionCB(PMidiEvent(LHeader^.lpData + LHeader^.dwOffset)^);
      end;
  end;
end;

{ TEngineMidiStreamPlayer }

constructor TEngineMidiStreamPlayer.Create(const ASequencer: IMidiStreamSequencer;
  ADeviceID: UINT);
var
  LChannel: Integer;
begin
  inherited Create;
  if not Assigned(ASequencer) then
    raise EArgumentNilException.Create(SSequencerIsNil);
  FSequencer := ASequencer;
  FDeviceID := ADeviceID;
  FVolume := VOLUME_INIT;
  for LChannel := 0 to NUM_CHANNELS - 1 do
    FVolumes[LChannel] := VOLUME_INIT;
  FBufferReturnEvent := CreateEvent(nil, False, False, nil);
  if FBufferReturnEvent = 0 then
    I_Error(SCannotCreateEvent);
end;

destructor TEngineMidiStreamPlayer.Destroy;
begin
  Stop(False);
  if FBufferReturnEvent <> 0 then
    CloseHandle(FBufferReturnEvent);
  inherited Destroy;
end;

procedure TEngineMidiStreamPlayer.MidiError(AResult: MMRESULT);
var
  LText: array[0..511] of Char;
begin
  midiOutGetErrorText(AResult, LText, Length(LText));
  I_DevWarning('Midi error: %s'#13#10, [string(LText)]);
end;

function TEngineMidiStreamPlayer.IsPlaying: Boolean;
begin
  Result := FPlaying;
end;

function TEngineMidiStreamPlayer.IsPaused: Boolean;
begin
  Result := FPaused;
end;

// This function unprepares and frees all our buffers: a device does not play back properly
// unless it is closed and reopened after each stop
procedure TEngineMidiStreamPlayer.FreeBuffers;
var
  LIndex: Integer;
  LResult: MMRESULT;
begin
  if FBuffersPrepared then
  begin
    for LIndex := 0 to NUM_STREAM_BUFFERS - 1 do
    begin
      LResult := midiOutUnprepareHeader(HMIDIOUT(FStream), @FBuffers[LIndex], SizeOf(TMidiHdr));
      if LResult <> MMSYSERR_NOERROR then
        MidiError(LResult);
    end;
    FBuffersPrepared := False;
  end;

  for LIndex := 0 to NUM_STREAM_BUFFERS - 1 do
    if FBuffers[LIndex].lpData <> nil then
    begin
      FreeMem(FBuffers[LIndex].lpData);
      FBuffers[LIndex].lpData := nil;
    end;
end;

procedure TEngineMidiStreamPlayer.FillBuffer(AIndex: Integer; const ABytes: TBytes);
begin
  if Length(ABytes) > 0 then
    Move(ABytes[0], FBuffers[AIndex].lpData^, Length(ABytes));
  FBuffers[AIndex].dwBytesRecorded := Length(ABytes);
end;

// Opens the stream, then converts the first buffers of the song and gives them to the stream
function TEngineMidiStreamPlayer.StreamBufferSetup: Boolean;
var
  LResult: MMRESULT;
  LConversion: TMidiConvertResult;
  LTimeDivision: MIDIPROPTIMEDIV;
  LBytes: TBytes;
  LReset: Boolean;
  LFoundEnd: Boolean;
begin
  LFoundEnd := False;

  if FStream = 0 then
  begin
    LResult := midiStreamOpen(@FStream, @FDeviceID, 1, DWORD_PTR(@MidiProc), DWORD_PTR(Self),
      CALLBACK_FUNCTION);
    if LResult <> MMSYSERR_NOERROR then
    begin
      MidiError(LResult);
      Result := False;
      Exit;
    end;
  end;

  LTimeDivision.cbStruct := SizeOf(LTimeDivision);
  LTimeDivision.dwTimeDiv := FSequencer.TimeDivision;
  LResult := midiStreamProperty(FStream, @LTimeDivision, MIDIPROP_SET or MIDIPROP_TIMEDIV);
  if LResult <> MMSYSERR_NOERROR then
  begin
    MidiError(LResult);
    Result := False;
    Exit;
  end;

  FEmptyBuffers := 0;
  // the first block forgets what the one before left half done
  LReset := True;

  FCurrentBuffer := 0;
  while FCurrentBuffer < NUM_STREAM_BUFFERS do
  begin
    FBuffers[FCurrentBuffer].dwBufferLength := OUT_BUFFER_SIZE;
    GetMem(FBuffers[FCurrentBuffer].lpData, OUT_BUFFER_SIZE);

    LConversion := FSequencer.ConvertBlock(LReset, OUT_BUFFER_SIZE, LBytes);
    if LConversion = mcrDone then
      LFoundEnd := True;
    FillBuffer(FCurrentBuffer, LBytes);

    if not FBuffersPrepared then
    begin
      LResult := midiOutPrepareHeader(HMIDIOUT(FStream), @FBuffers[FCurrentBuffer],
        SizeOf(TMidiHdr));
      if LResult <> MMSYSERR_NOERROR then
      begin
        MidiError(LResult);
        Result := False;
        Exit;
      end;
    end;

    LResult := midiStreamOut(FStream, @FBuffers[FCurrentBuffer], SizeOf(TMidiHdr));
    if LResult <> MMSYSERR_NOERROR then
    begin
      MidiError(LResult);
      Break;
    end;
    LReset := False;

    if LFoundEnd then
      Break;
    Inc(FCurrentBuffer);
  end;

  FBuffersPrepared := True;
  FCurrentBuffer := 0;
  Result := True;
end;

function TEngineMidiStreamPlayer.Load: Boolean;
begin
  Result := StreamBufferSetup;
end;

// Called by the stream when a buffer has been played: it is filled again with the next events
procedure TEngineMidiStreamPlayer.OnMidiOutDone;
var
  LResult: MMRESULT;
  LConversion: TMidiConvertResult;
  LBytes: TBytes;
begin
  if FCallbackStatus = STATUS_CALLBACKDEAD then
    Exit;

  Inc(FEmptyBuffers);

  if FCallbackStatus = STATUS_WAITINGFOREND then
  begin
    if FEmptyBuffers < NUM_STREAM_BUFFERS then
      Exit;
    FCallbackStatus := STATUS_CALLBACKDEAD;
    Stop;
    SetEvent(FBufferReturnEvent);
    Exit;
  end;

  // This status is set whenever the callback is waiting for all buffers to come back
  if FCallbackStatus = STATUS_KILLCALLBACK then
  begin
    if FEmptyBuffers < NUM_STREAM_BUFFERS then
      Exit;
    FCallbackStatus := STATUS_CALLBACKDEAD;
    SetEvent(FBufferReturnEvent);
    Exit;
  end;

  if FPlaying and (FEmptyBuffers <> 0) then
  begin
    LConversion := FSequencer.ConvertBlock(False, OUT_BUFFER_SIZE, LBytes);
    if LConversion = mcrDone then
    begin
      FCallbackStatus := STATUS_WAITINGFOREND;
      Exit;
    end;
    FillBuffer(FCurrentBuffer, LBytes);

    LResult := midiStreamOut(FStream, @FBuffers[FCurrentBuffer], SizeOf(TMidiHdr));
    if LResult <> MMSYSERR_NOERROR then
    begin
      MidiError(LResult);
      Exit;
    end;
    FCurrentBuffer := (FCurrentBuffer + 1) mod NUM_STREAM_BUFFERS;
    Dec(FEmptyBuffers);
  end;
end;

// Called by the stream at a change of volume: the volume of the channel is kept
procedure TEngineMidiStreamPlayer.OnMidiOutPositionCB(const AEvent: TMidiEvent);
begin
  if (AEvent.dwEvent and $000000F0) = MIDI_CONTROL_CHANGE then
    if ((AEvent.dwEvent and $0000FF00) shr 8) = MIDI_CONTROLLER_VOLUME then
      // the channel is in the low bits of the event, the volume in the third byte
      FVolumes[AEvent.dwEvent and $0000000F] := Cardinal(
        ((AEvent.dwEvent and $007F0000) shr 16) * 100 div MIDI_CONTROLLER_MAXIMUM);
end;

function TEngineMidiStreamPlayer.Pause: Boolean;
begin
  if not FPaused and FPlaying and (FStream <> 0) then
  begin
    midiStreamPause(FStream);
    FPaused := True;
  end;
  // the old TMidi answered false
  Result := False;
end;

function TEngineMidiStreamPlayer.Resume: Boolean;
begin
  if FPaused and FPlaying and (FStream <> 0) then
  begin
    midiStreamRestart(FStream);
    FPaused := False;
  end;
  Result := False;
end;

function TEngineMidiStreamPlayer.Play(ALoop: Boolean): Boolean;
var
  LResult: MMRESULT;
begin
  if IsPaused then
  begin
    Resume;
    Result := True;
    Exit;
  end;

  // calling Play while it is already playing restarts from scratch
  if IsPlaying then
    Stop;

  // the callback handles the buffers that come back once more
  FCallbackStatus := 0;

  if not FSequencer.Looped then
    FSequencer.RequestTempoEvent;
  LResult := midiStreamRestart(FStream);
  if LResult <> MMSYSERR_NOERROR then
  begin
    MidiError(LResult);
    Result := False;
    Exit;
  end;

  FPlaying := True;
  FSequencer.Looped := ALoop;

  Result := FPlaying;
end;

function TEngineMidiStreamPlayer.Stop(AReopen: Boolean): Boolean;
var
  LResult: MMRESULT;
begin
  if IsPlaying or (FCallbackStatus <> STATUS_CALLBACKDEAD) then
  begin
    FPaused := False;
    FPlaying := FPaused;
    if (FCallbackStatus <> STATUS_CALLBACKDEAD) and (FCallbackStatus <> STATUS_WAITINGFOREND) then
      FCallbackStatus := STATUS_KILLCALLBACK;

    LResult := midiStreamStop(FStream);
    if LResult <> MMSYSERR_NOERROR then
    begin
      MidiError(LResult);
      Result := False;
      Exit;
    end;

    LResult := midiOutReset(HMIDIOUT(FStream));
    if LResult <> MMSYSERR_NOERROR then
    begin
      MidiError(LResult);
      Result := False;
      Exit;
    end;

    // Wait for the callback to release this thread, which it does by setting the event once
    // all the buffers are returned to it
    if WaitForSingleObject(FBufferReturnEvent, DEBUG_CALLBACK_TIMEOUT) = WAIT_TIMEOUT then
    begin
      // A risky move because the callback may be genuinely busy, but safer than freezing the
      // application and leaving the device locked up
      I_DevWarning('TEngineMidiStreamPlayer.Stop(): Timed out waiting for MIDI callback'#13#10);
      FCallbackStatus := STATUS_CALLBACKDEAD;
    end;
  end;

  if FCallbackStatus = STATUS_CALLBACKDEAD then
  begin
    FCallbackStatus := 0;
    FreeBuffers;
    if FStream <> 0 then
    begin
      LResult := midiStreamClose(FStream);
      if LResult <> MMSYSERR_NOERROR then
        MidiError(LResult);
      FStream := 0;
    end;

    if AReopen then
    begin
      if not StreamBufferSetup then
      begin
        Result := False;
        Exit;
      end;
      if not FSequencer.Looped then
        FSequencer.Rewind;
    end;
  end;
  Result := True;
end;

procedure TEngineMidiStreamPlayer.SetChannelVolume(AChannel, APercent: Cardinal);
var
  LResult: MMRESULT;
begin
  if AChannel >= NUM_CHANNELS then
    I_Error('TEngineMidiStreamPlayer.SetChannelVolume(): Invalid channel %d', [AChannel]);

  if not FPlaying then
    Exit;

  if APercent > VOLUME_INIT then
    FVolumes[AChannel] := Cardinal(FVolume)
  else
    FVolumes[AChannel] := Cardinal(Round(APercent * FVolume / VOLUME_INIT));

  LResult := midiOutShortMsg(HMIDIOUT(FStream),
    TMidiVolume.ControlChangeMessage(AChannel,
      Cardinal(TMidiVolume.ControllerValueOfPercent(Integer(FVolumes[AChannel])))));
  if LResult <> MMSYSERR_NOERROR then
    MidiError(LResult);
end;

procedure TEngineMidiStreamPlayer.SetVolumeOfAllChannels(APercent: Cardinal);
var
  LChannel: Cardinal;
begin
  for LChannel := 0 to NUM_CHANNELS - 1 do
    SetChannelVolume(LChannel, APercent);
end;

procedure TEngineMidiStreamPlayer.SetMasterVolume(APercent: Integer);
begin
  if APercent < 0 then
    APercent := 0
  else if APercent > VOLUME_INIT then
    APercent := VOLUME_INIT;
  FVolume := APercent;
  SetVolumeOfAllChannels(VOLUME_INIT);
end;

end.
