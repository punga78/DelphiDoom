{******************************************************************************}
{                                                                              }
{  DelphiDoom: plays an MP3 song through the waveform audio device             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Mp3Player;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Mp3.Intf;

type
  /// <summary>
  ///   Decodes an MP3 song with a decoder created from IMp3 and plays it in
  ///   a background thread, a few buffers at a time
  /// </summary>
  /// <remarks>
  ///   The song is kept in memory, so the caller can release its own copy
  ///   after Play. A failure of the audio device or of the decoder ends the
  ///   playback silently: music is never worth stopping the game
  /// </remarks>
  TMp3Player = class
  private
    FMp3: IMp3;
    FData: TBytes;
    FLooping: Boolean;
    FStopRequested: Boolean;
    FPaused: Boolean;
    FThread: TThread;
    procedure Run;
  public
    constructor Create(const AMp3: IMp3);
    destructor Destroy; override;

    /// <summary>
    ///   Starts the song from the beginning, stopping the one that is playing
    /// </summary>
    procedure Play(AData: Pointer; ASize: Cardinal; ALooping: Boolean);

    /// <summary>
    ///   Stops the playback and waits for the thread to end
    /// </summary>
    procedure Stop;

    procedure Pause;
    procedure Resume;

    function IsPlaying: Boolean;
  end;

implementation

uses
  Winapi.Windows, Winapi.MMSystem, DelphiDoom.Mp3.Client;

const
  BUFFER_COUNT = 4;
  // About 0.37 seconds of CD quality stereo
  BUFFER_BYTES = 64 * 1024;
  WAIT_MS = 10;
  BITS_PER_SAMPLE = 16;

{ TMp3Player }

constructor TMp3Player.Create(const AMp3: IMp3);
begin
  inherited Create;
  if not Assigned(AMp3) then
    raise EArgumentNilException.Create('AMp3');
  FMp3 := AMp3;
end;

destructor TMp3Player.Destroy;
begin
  Stop;
  inherited;
end;

procedure TMp3Player.Play(AData: Pointer; ASize: Cardinal; ALooping: Boolean);
begin
  Stop;
  if (AData = nil) or (ASize = 0) then
    Exit;

  SetLength(FData, ASize);
  Move(AData^, FData[0], ASize);
  FLooping := ALooping;
  FStopRequested := False;
  FPaused := False;

  FThread := TThread.CreateAnonymousThread(Run);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

procedure TMp3Player.Stop;
begin
  if not Assigned(FThread) then
    Exit;
  FStopRequested := True;
  FThread.WaitFor;
  FreeAndNil(FThread);
end;

procedure TMp3Player.Pause;
begin
  FPaused := True;
end;

procedure TMp3Player.Resume;
begin
  FPaused := False;
end;

function TMp3Player.IsPlaying: Boolean;
begin
  Result := Assigned(FThread) and not FThread.Finished;
end;

procedure TMp3Player.Run;
var
  LClient: TMp3Client;
  LHeaders: array[0..BUFFER_COUNT - 1] of TWaveHdr;
  LBuffers: array[0..BUFFER_COUNT - 1] of TBytes;
  LFormat: TWaveFormatEx;
  LDevice: HWAVEOUT;
  LDeviceOpen: Boolean;
  LExhausted: Boolean;
  LJustRewound: Boolean;
  LWasPaused: Boolean;
  LNext: Integer;
  LIndex: Integer;
  LWritten: Cardinal;

  function IsQueued(AIndex: Integer): Boolean;
  begin
    Result := (LHeaders[AIndex].dwFlags and WHDR_PREPARED <> 0) and
      (LHeaders[AIndex].dwFlags and WHDR_DONE = 0);
  end;

  function AnyQueued: Boolean;
  var
    LCheck: Integer;
  begin
    Result := False;
    for LCheck := 0 to BUFFER_COUNT - 1 do
      if IsQueued(LCheck) then
        Exit(True);
  end;

  procedure ReleaseHeader(AIndex: Integer);
  begin
    if LHeaders[AIndex].dwFlags and WHDR_PREPARED <> 0 then
      waveOutUnprepareHeader(LDevice, @LHeaders[AIndex], SizeOf(TWaveHdr));
  end;

  function OpenDevice: Boolean;
  begin
    FillChar(LFormat, SizeOf(LFormat), 0);
    LFormat.wFormatTag := WAVE_FORMAT_PCM;
    LFormat.nChannels := LClient.Channels;
    LFormat.nSamplesPerSec := LClient.Frequency;
    LFormat.wBitsPerSample := BITS_PER_SAMPLE;
    LFormat.nBlockAlign := LFormat.nChannels * (BITS_PER_SAMPLE div 8);
    LFormat.nAvgBytesPerSec := LFormat.nSamplesPerSec * LFormat.nBlockAlign;
    Result := waveOutOpen(@LDevice, WAVE_MAPPER, @LFormat, 0, 0,
      CALLBACK_NULL) = MMSYSERR_NOERROR;
  end;

begin
  LDeviceOpen := False;
  LDevice := 0;
  FillChar(LHeaders, SizeOf(LHeaders), 0);
  for LIndex := 0 to BUFFER_COUNT - 1 do
    SetLength(LBuffers[LIndex], BUFFER_BYTES);

  LClient := TMp3Client.Create(FMp3);
  try
    try
      LClient.Feed(FData);
      LExhausted := False;
      LJustRewound := False;
      LWasPaused := False;
      LNext := 0;

      while not FStopRequested do
      begin
        if FPaused <> LWasPaused then
        begin
          LWasPaused := FPaused;
          if LDeviceOpen then
          begin
            if LWasPaused then
              waveOutPause(LDevice)
            else
              waveOutRestart(LDevice);
          end;
        end;

        // The buffer to fill next is still being played
        if IsQueued(LNext) then
        begin
          Sleep(WAIT_MS);
          Continue;
        end;

        if LExhausted then
        begin
          if not AnyQueued then
            Break;
          Sleep(WAIT_MS);
          Continue;
        end;

        ReleaseHeader(LNext);

        LClient.Decode(@LBuffers[LNext][0], BUFFER_BYTES, LWritten);
        if LWritten = 0 then
        begin
          // End of the song: start again, once, or the file has no frames
          if FLooping and not LJustRewound then
          begin
            LClient.Reset;
            LClient.Feed(FData);
            LJustRewound := True;
          end
          else
            LExhausted := True;
          Continue;
        end;
        LJustRewound := False;

        if not LDeviceOpen then
        begin
          if not OpenDevice then
            Break;
          LDeviceOpen := True;
        end;

        FillChar(LHeaders[LNext], SizeOf(TWaveHdr), 0);
        LHeaders[LNext].lpData := PAnsiChar(@LBuffers[LNext][0]);
        LHeaders[LNext].dwBufferLength := LWritten;
        waveOutPrepareHeader(LDevice, @LHeaders[LNext], SizeOf(TWaveHdr));
        waveOutWrite(LDevice, @LHeaders[LNext], SizeOf(TWaveHdr));
        LNext := (LNext + 1) mod BUFFER_COUNT;
      end;
    except
      on Exception do
        ; // Music is not worth stopping the game: the thread just ends
    end;
  finally
    if LDeviceOpen then
    begin
      waveOutReset(LDevice);
      for LIndex := 0 to BUFFER_COUNT - 1 do
        ReleaseHeader(LIndex);
      waveOutClose(LDevice);
    end;
    LClient.Free;
  end;
end;

end.
