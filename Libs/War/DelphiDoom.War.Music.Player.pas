{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the player of the music                           }
{                                                                              }
{  Port of wa_playMidi and of the music part of audioDataCallback of            }
{  war_audio.c, war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib    }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not     }
{  the original.                                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Music.Player;

interface

uses
  System.SysUtils, System.SyncObjs, DelphiDoom.War.Music.Types, DelphiDoom.War.Music.Intf,
  DelphiDoom.War.Music.Fade;

type
  /// <summary>
  ///   Plays a song through a synth. It keeps the way of the original: the time of the song advances 64 samples at
  ///   a time (playbackTime in milliseconds as a Single), the events that are due fire before the block is
  ///   rendered, the volume of the music scales the velocity of the notes that start (a note that already sounds
  ///   keeps its own), a song at volume 0 does not advance, a loop starts again as soon as the last event has
  ///   fired and keeps the time that went past it. What is new is the fade of the volume (TWarMusicFade).
  ///   Every method takes one lock: the game starts and stops the songs, the audio thread mixes
  /// </summary>
  TWarMusicPlayer = class(TInterfacedObject, IWarMusicPlayer)
  strict private
    FLock: TCriticalSection;
    FSynth: IWarMusicSynth;
    FTimeline: IWarMusicTimeline;
    FFade: TWarMusicFade;
    FState: TWarMusicState;
    FLoop: Boolean;
    FEnding: Boolean;
    FPlaybackMs: Single;
    FStepMs: Single;
    FHasNext: Boolean;
    FNext: TWarMusicEvent;
    FLastEventMs: Cardinal;
    FVolume: Single;
    FEnabled: Boolean;
    FSilenced: Boolean;
    FNotesSilenced: Boolean;
    FScratch: array[0..WAR_MUSIC_SCRATCH_SAMPLES - 1] of SmallInt;
    procedure PlayEvent(const AEvent: TWarMusicEvent; AVolume: Single);
    procedure FireDueEvents(AVolume: Single);
    procedure RenderBlock(AOffset, ACount: Integer; AVolume: Single);
    procedure StopNow;
    function GetState: TWarMusicState;
  public
    constructor Create(const ASynth: IWarMusicSynth; const ATimeline: IWarMusicTimeline; ASampleRate: Integer);
    destructor Destroy; override;
    function Play(const AMidi: TBytes; ALoop: Boolean; AFadeInMs: Integer): Boolean;
    procedure Stop(AFadeOutMs: Integer);
    procedure SetVolume(AVolume: Single; AEnabled: Boolean);
    procedure SetSilenced(ASilenced: Boolean);
    procedure Mix(ABuffer: PSmallInt; ASampleCount: Integer);
  end;

implementation

uses
  DelphiDoom.AudioMix.Saturation, DelphiDoom.War.Types;

const
  // a song that loops over and over inside one block has no length: it is stopped instead of hanging the audio
  MAX_RESTARTS_PER_BLOCK = 64;

{ TWarMusicPlayer }

constructor TWarMusicPlayer.Create(const ASynth: IWarMusicSynth; const ATimeline: IWarMusicTimeline;
  ASampleRate: Integer);
begin
  inherited Create;
  if not Assigned(ASynth) or not Assigned(ATimeline) then
    raise EWarException.Create('The synth and the timeline of the music player cannot be nil');
  if ASampleRate <= 0 then
    raise EWarException.Create('The sample rate of the music player must be positive');
  FLock := TCriticalSection.Create;
  FSynth := ASynth;
  FTimeline := ATimeline;
  FFade := TWarMusicFade.Create(ASampleRate);
  FStepMs := 1000.0 / ASampleRate;
  FVolume := 1;
  FEnabled := True;
  FState := wmsStopped;
end;

destructor TWarMusicPlayer.Destroy;
begin
  FFade.Free;
  FLock.Free;
  inherited;
end;

function TWarMusicPlayer.GetState: TWarMusicState;
begin
  FLock.Enter;
  try
    Result := FState;
  finally
    FLock.Leave;
  end;
end;

procedure TWarMusicPlayer.StopNow;
begin
  if FState <> wmsStopped then
    FSynth.AllNotesOff;
  FState := wmsStopped;
  FHasNext := False;
  FEnding := False;
end;

function TWarMusicPlayer.Play(const AMidi: TBytes; ALoop: Boolean; AFadeInMs: Integer): Boolean;
begin
  FLock.Enter;
  try
    StopNow;
    Result := FTimeline.Load(AMidi);
    if not Result then
      Exit;
    FLoop := ALoop;
    FEnding := False;
    FPlaybackMs := 0;
    FLastEventMs := 0;
    FHasNext := FTimeline.TryNext(FNext);
    if AFadeInMs > 0 then
      FFade.FadeIn(AFadeInMs)
    else
      FFade.Reset;
    FNotesSilenced := False;
    FState := wmsPlaying;
  finally
    FLock.Leave;
  end;
end;

procedure TWarMusicPlayer.Stop(AFadeOutMs: Integer);
begin
  FLock.Enter;
  try
    if not (FState in [wmsPlaying, wmsFadingOut]) then
      Exit;
    if AFadeOutMs <= 0 then
    begin
      StopNow;
      Exit;
    end;
    FFade.FadeOut(AFadeOutMs);
    FState := wmsFadingOut;
  finally
    FLock.Leave;
  end;
end;

procedure TWarMusicPlayer.SetVolume(AVolume: Single; AEnabled: Boolean);
begin
  FLock.Enter;
  try
    // CLAMP(volume, 0, 1) of wg_setMusicVolume
    if AVolume < 0 then
      AVolume := 0
    else if AVolume > 1 then
      AVolume := 1;
    FVolume := AVolume;
    FEnabled := AEnabled;
  finally
    FLock.Leave;
  end;
end;

procedure TWarMusicPlayer.SetSilenced(ASilenced: Boolean);
begin
  FLock.Enter;
  try
    FSilenced := ASilenced;
  finally
    FLock.Leave;
  end;
end;

procedure TWarMusicPlayer.PlayEvent(const AEvent: TWarMusicEvent; AVolume: Single);
var
  LVelocity: Single;
begin
  case AEvent.Kind of
    wmkProgramChange:
      FSynth.ProgramChange(AEvent.Channel, AEvent.Key, AEvent.Channel = WAR_MUSIC_DRUM_CHANNEL);
    wmkNoteOn:
      begin
        // f32 velocity = velocity / 127.0f; tsf_channel_note_on(..., velocity * volume)
        LVelocity := AEvent.Value / 127.0;
        LVelocity := LVelocity * AVolume;
        FSynth.NoteOn(AEvent.Channel, AEvent.Key, LVelocity);
      end;
    wmkNoteOff:
      FSynth.NoteOff(AEvent.Channel, AEvent.Key);
    wmkPitchBend:
      FSynth.PitchBend(AEvent.Channel, AEvent.Value);
    wmkControlChange:
      FSynth.ControlChange(AEvent.Channel, AEvent.Key, AEvent.Value);
  end;
end;

procedure TWarMusicPlayer.FireDueEvents(AVolume: Single);
var
  LRestarts: Integer;
  LLast: Single;
  LDue: Single;
begin
  LRestarts := 0;
  while True do
  begin
    if not FHasNext then
    begin
      // the end of the song
      if not FLoop then
      begin
        FEnding := True;
        Exit;
      end;
      Inc(LRestarts);
      if LRestarts > MAX_RESTARTS_PER_BLOCK then
      begin
        FLoop := False;
        FEnding := True;
        Exit;
      end;
      FTimeline.Rewind;
      LLast := FLastEventMs;
      FPlaybackMs := FPlaybackMs - LLast;
      FLastEventMs := 0;
      FHasNext := FTimeline.TryNext(FNext);
      if not FHasNext then
      begin
        FLoop := False;
        FEnding := True;
        Exit;
      end;
    end;
    LDue := FNext.TimeMs;
    if LDue > FPlaybackMs then
      Exit;
    PlayEvent(FNext, AVolume);
    FLastEventMs := FNext.TimeMs;
    FHasNext := FTimeline.TryNext(FNext);
  end;
end;

procedure TWarMusicPlayer.RenderBlock(AOffset, ACount: Integer; AVolume: Single);
var
  LStep: Single;
begin
  // playbackTime += sampleBlock * (1000.0f / PLAYBACK_FREQ)
  LStep := ACount * FStepMs;
  FPlaybackMs := FPlaybackMs + LStep;
  FireDueEvents(AVolume);
  FSynth.Render(@FScratch[AOffset], ACount);
end;

procedure TWarMusicPlayer.Mix(ABuffer: PSmallInt; ASampleCount: Integer);
var
  LVolume: Single;
  LChunk: Integer;
  LOffset: Integer;
  LBlock: Integer;
  LDone: Integer;
  LOutput: PSmallInt;
begin
  FLock.Enter;
  try
    if (FState in [wmsStopped, wmsEnded]) or (ASampleCount <= 0) then
      Exit;
    if FSilenced then
    begin
      // the original puts every note off while the scene changes, and does not advance
      if not FNotesSilenced then
        FSynth.AllNotesOff;
      FNotesSilenced := True;
      Exit;
    end;
    FNotesSilenced := False;
    if FEnabled then
      LVolume := FVolume
    else
      LVolume := 0;
    if LVolume <= 0 then
      Exit;
    LDone := 0;
    while (LDone < ASampleCount) and (FState in [wmsPlaying, wmsFadingOut]) do
    begin
      LChunk := ASampleCount - LDone;
      if LChunk > WAR_MUSIC_SCRATCH_SAMPLES then
        LChunk := WAR_MUSIC_SCRATCH_SAMPLES;
      FillChar(FScratch[0], LChunk * SizeOf(SmallInt), 0);
      LOffset := 0;
      while LOffset < LChunk do
      begin
        LBlock := LChunk - LOffset;
        if LBlock > WAR_MUSIC_RENDER_BLOCK then
          LBlock := WAR_MUSIC_RENDER_BLOCK;
        RenderBlock(LOffset, LBlock, LVolume);
        Inc(LOffset, LBlock);
      end;
      FFade.Apply(@FScratch[0], LChunk);
      LOutput := ABuffer;
      Inc(LOutput, LDone);
      TPcmSaturation.AddSaturated(LOutput, @FScratch[0], LChunk);
      Inc(LDone, LChunk);
      if (FState = wmsFadingOut) and FFade.IsSilent then
        StopNow;
    end;
    // wa_playMidi says it is finished at the end of the call in which the last event fired; the notes that
    // still sounded stop (the original left them in the synth)
    if FEnding and not FLoop and (FState in [wmsPlaying, wmsFadingOut]) then
    begin
      FSynth.AllNotesOff;
      FState := wmsEnded;
      FEnding := False;
    end;
  finally
    FLock.Leave;
  end;
end;

end.
