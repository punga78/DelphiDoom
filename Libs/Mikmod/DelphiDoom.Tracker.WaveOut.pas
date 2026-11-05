{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - plays a module through the waveform audio device      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.WaveOut;

interface

uses
  System.Classes,
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   Plays a module in a background thread, a few buffers at a time
  /// </summary>
  /// <remarks>
  ///   The module must stay alive and unchanged while it plays. A failure of
  ///   the audio device ends the playback silently: music is never worth
  ///   stopping the game
  /// </remarks>
  TTrackerWaveOut = class
  private
    FModule: TTrackerModule;
    FSampleRate: Integer;
    FLooping: Boolean;
    FStopRequested: Boolean;
    FPaused: Boolean;
    FVolume: Integer;
    FThread: TThread;
    procedure Run;
    procedure ApplyVolume(const ABuffer: TArray<SmallInt>);
  public
    /// <param name="AModule">The module to play</param>
    /// <param name="ASampleRate">Frames per second of the output</param>
    constructor Create(const AModule: TTrackerModule; const ASampleRate: Integer);
    destructor Destroy; override;

    /// <summary>Starts the song from the beginning, stopping the one that is playing</summary>
    procedure Play(const ALooping: Boolean);

    /// <summary>Stops the playback and waits for the thread to end</summary>
    procedure Stop;

    procedure Pause;
    procedure Resume;

    function IsPlaying: Boolean;

    property Paused: Boolean read FPaused;
    /// <summary>0..128</summary>
    property Volume: Integer read FVolume write FVolume;
  end;

implementation

uses
  Winapi.MMSystem,
  Winapi.Windows,
  System.SysUtils,
  DelphiDoom.Tracker.Player;

const
  BUFFER_COUNT = 4;
  // A buffer lasts a tenth of a second
  BUFFER_FRACTION = 10;
  WAIT_MS = 10;
  CHANNELS = 2;
  BITS_PER_SAMPLE = 16;
  MAX_VOLUME = 128;

{ TTrackerWaveOut }

constructor TTrackerWaveOut.Create(const AModule: TTrackerModule; const ASampleRate: Integer);
begin
  inherited Create;
  FModule := AModule;
  FSampleRate := ASampleRate;
  FVolume := MAX_VOLUME;
end;

destructor TTrackerWaveOut.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure TTrackerWaveOut.Play(const ALooping: Boolean);
begin
  Stop;
  FLooping := ALooping;
  FStopRequested := False;
  FPaused := False;
  FThread := TThread.CreateAnonymousThread(Run);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

procedure TTrackerWaveOut.Stop;
begin
  if not Assigned(FThread) then
    Exit;
  FStopRequested := True;
  FThread.WaitFor;
  FreeAndNil(FThread);
end;

procedure TTrackerWaveOut.Pause;
begin
  FPaused := True;
end;

procedure TTrackerWaveOut.Resume;
begin
  FPaused := False;
end;

function TTrackerWaveOut.IsPlaying: Boolean;
begin
  Result := Assigned(FThread) and not FThread.Finished;
end;

procedure TTrackerWaveOut.ApplyVolume(const ABuffer: TArray<SmallInt>);
var
  LIndex, LVolume: Integer;
begin
  LVolume := FVolume;
  if LVolume >= MAX_VOLUME then
    Exit;
  for LIndex := 0 to High(ABuffer) do
    ABuffer[LIndex] := ABuffer[LIndex] * LVolume div MAX_VOLUME;
end;

procedure TTrackerWaveOut.Run;
var
  LPlayer: TTrackerPlayer;
  LDevice: HWAVEOUT;
  LFormat: TWaveFormatEx;
  LHeaders: array[0..BUFFER_COUNT - 1] of TWaveHdr;
  LBuffers: array[0..BUFFER_COUNT - 1] of TArray<SmallInt>;
  // The buffers that were played after the end of the song
  LDrained: array[0..BUFFER_COUNT - 1] of Boolean;
  LFrames, LIndex, LNext: Integer;
  LEnding, LWasPaused, LAllDone: Boolean;

  procedure Fill(const AIndex: Integer);
  begin
    LPlayer.Render(LBuffers[AIndex], LFrames);
    LDrained[AIndex] := False;
    ApplyVolume(LBuffers[AIndex]);
    if (LHeaders[AIndex].dwFlags and WHDR_PREPARED) <> 0 then
      waveOutUnprepareHeader(LDevice, @LHeaders[AIndex], SizeOf(TWaveHdr));
    FillChar(LHeaders[AIndex], SizeOf(TWaveHdr), 0);
    LHeaders[AIndex].lpData := PAnsiChar(@LBuffers[AIndex][0]);
    LHeaders[AIndex].dwBufferLength := LFrames * CHANNELS * (BITS_PER_SAMPLE div 8);
    if waveOutPrepareHeader(LDevice, @LHeaders[AIndex], SizeOf(TWaveHdr)) = MMSYSERR_NOERROR then
      waveOutWrite(LDevice, @LHeaders[AIndex], SizeOf(TWaveHdr));
    // Once the song has finished, what is rendered is only silence
    if LPlayer.Finished then
      LEnding := True;
  end;

begin
  LPlayer := TTrackerPlayer.Create(FModule, FSampleRate, FLooping);
  try
    LFrames := FSampleRate div BUFFER_FRACTION;
    FillChar(LHeaders, SizeOf(LHeaders), 0);
    FillChar(LDrained, SizeOf(LDrained), 0);
    for LIndex := 0 to BUFFER_COUNT - 1 do
      SetLength(LBuffers[LIndex], LFrames * CHANNELS);

    FillChar(LFormat, SizeOf(LFormat), 0);
    LFormat.wFormatTag := WAVE_FORMAT_PCM;
    LFormat.nChannels := CHANNELS;
    LFormat.nSamplesPerSec := FSampleRate;
    LFormat.wBitsPerSample := BITS_PER_SAMPLE;
    LFormat.nBlockAlign := CHANNELS * (BITS_PER_SAMPLE div 8);
    LFormat.nAvgBytesPerSec := LFormat.nSamplesPerSec * LFormat.nBlockAlign;
    LDevice := 0;
    if waveOutOpen(@LDevice, WAVE_MAPPER, @LFormat, 0, 0, CALLBACK_NULL) <> MMSYSERR_NOERROR then
      Exit;

    try
      LEnding := False;
      LWasPaused := False;
      LNext := 0;
      for LIndex := 0 to BUFFER_COUNT - 1 do
        Fill(LIndex);

      while not FStopRequested do
      begin
        if FPaused <> LWasPaused then
        begin
          LWasPaused := FPaused;
          if LWasPaused then
            waveOutPause(LDevice)
          else
            waveOutRestart(LDevice);
        end;

        if (LHeaders[LNext].dwFlags and WHDR_DONE) <> 0 then
        begin
          if LEnding then
            // Nothing more to write: this buffer has been played
            LDrained[LNext] := True
          else
            Fill(LNext);
          LNext := (LNext + 1) mod BUFFER_COUNT;
        end
        else
        begin
          Sleep(WAIT_MS);
          if LEnding then
          begin
            // The end of the song: leave when every buffer has been played
            LAllDone := True;
            for LIndex := 0 to BUFFER_COUNT - 1 do
            begin
              if not LDrained[LIndex] then
                LAllDone := False;
            end;
            if LAllDone then
              Break;
          end;
        end;
      end;
    finally
      waveOutReset(LDevice);
      for LIndex := 0 to BUFFER_COUNT - 1 do
      begin
        if (LHeaders[LIndex].dwFlags and WHDR_PREPARED) <> 0 then
          waveOutUnprepareHeader(LDevice, @LHeaders[LIndex], SizeOf(TWaveHdr));
      end;
      waveOutClose(LDevice);
    end;
  finally
    LPlayer.Free;
  end;
end;

end.
