{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - plays a module on an audio device, in a worker        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Playback;

interface

uses
  DelphiDoom.Tracker.Output.Intf,
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   Plays a module in a worker (a background thread), a few buffers at a time
  /// </summary>
  /// <remarks>
  ///   The module must stay alive and unchanged while it plays. A failure of
  ///   the audio device ends the playback silently: music is never worth
  ///   stopping the game
  /// </remarks>
  TTrackerPlayback = class
  strict private
    FModule: TTrackerModule;
    FSampleRate: Integer;
    FOutputs: ITrackerOutputFactory;
    FWorker: ITrackerWorker;
    FLooping: Boolean;
    FStopRequested: Boolean;
    FPaused: Boolean;
    FVolume: Integer;
    procedure Run;
    procedure ApplyVolume(const ABuffer: TArray<SmallInt>);
  public
    /// <param name="AModule">The module to play</param>
    /// <param name="ASampleRate">Frames per second of the output</param>
    /// <param name="AOutputs">Gives the worker now and a device for each Play</param>
    constructor Create(const AModule: TTrackerModule; const ASampleRate: Integer;
      const AOutputs: ITrackerOutputFactory);
    destructor Destroy; override;

    /// <summary>Starts the song from the beginning, stopping the one that is playing</summary>
    procedure Play(const ALooping: Boolean);

    /// <summary>Stops the playback and waits for the worker to end</summary>
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
  System.SysUtils,
  DelphiDoom.Tracker.Player;

const
  BUFFER_COUNT = 4;
  // A buffer lasts a tenth of a second
  BUFFER_FRACTION = 10;
  CHANNELS = 2;
  MAX_VOLUME = 128;

{ TTrackerPlayback }

constructor TTrackerPlayback.Create(const AModule: TTrackerModule; const ASampleRate: Integer;
  const AOutputs: ITrackerOutputFactory);
begin
  inherited Create;
  if not Assigned(AOutputs) then
    raise EArgumentNilException.Create('AOutputs');
  FModule := AModule;
  FSampleRate := ASampleRate;
  FOutputs := AOutputs;
  FWorker := FOutputs.CreateWorker;
  FVolume := MAX_VOLUME;
end;

destructor TTrackerPlayback.Destroy;
begin
  if Assigned(FWorker) then
    Stop;
  inherited Destroy;
end;

procedure TTrackerPlayback.Play(const ALooping: Boolean);
begin
  Stop;
  FLooping := ALooping;
  FStopRequested := False;
  FPaused := False;
  FWorker.Start(Run);
end;

procedure TTrackerPlayback.Stop;
begin
  FStopRequested := True;
  FWorker.WaitFor;
end;

procedure TTrackerPlayback.Pause;
begin
  FPaused := True;
end;

procedure TTrackerPlayback.Resume;
begin
  FPaused := False;
end;

function TTrackerPlayback.IsPlaying: Boolean;
begin
  Result := FWorker.IsRunning;
end;

procedure TTrackerPlayback.ApplyVolume(const ABuffer: TArray<SmallInt>);
var
  LIndex, LVolume: Integer;
begin
  LVolume := FVolume;
  if LVolume >= MAX_VOLUME then
    Exit;
  for LIndex := 0 to High(ABuffer) do
    ABuffer[LIndex] := ABuffer[LIndex] * LVolume div MAX_VOLUME;
end;

procedure TTrackerPlayback.Run;
var
  LPlayer: TTrackerPlayer;
  LDevice: ITrackerAudioDevice;
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
    LDevice.Write(AIndex, LBuffers[AIndex]);
    // Once the song has finished, what is rendered is only silence
    if LPlayer.Finished then
      LEnding := True;
  end;

begin
  LDevice := FOutputs.CreateDevice;
  LPlayer := TTrackerPlayer.Create(FModule, FSampleRate, FLooping);
  try
    LFrames := FSampleRate div BUFFER_FRACTION;
    FillChar(LDrained, SizeOf(LDrained), 0);
    for LIndex := 0 to BUFFER_COUNT - 1 do
      SetLength(LBuffers[LIndex], LFrames * CHANNELS);
    if not LDevice.Open(FSampleRate, BUFFER_COUNT) then
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
            LDevice.Pause
          else
            LDevice.Restart;
        end;

        if not LDevice.IsDone(LNext) then
        begin
          LDevice.Wait;
          Continue;
        end;

        if not LEnding then
          Fill(LNext)
        else
        begin
          // Nothing more to write: this buffer has been played. The end of
          // the song: leave when every buffer has been played
          LDrained[LNext] := True;
          LAllDone := True;
          for LIndex := 0 to BUFFER_COUNT - 1 do
          begin
            if not LDrained[LIndex] then
              LAllDone := False;
          end;
          if LAllDone then
            Break;
        end;
        LNext := (LNext + 1) mod BUFFER_COUNT;
      end;
    finally
      LDevice.Close;
    end;
  finally
    LPlayer.Free;
  end;
end;

end.
