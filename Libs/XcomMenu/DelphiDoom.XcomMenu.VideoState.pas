{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - VideoState of OpenXcom (plays the FLI/FLC    }
{  animations of a cutscene) with the player loop of FlcPlayer                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.VideoState;

interface

uses
  DelphiDoom.XcomEngine.Ticks,
  System.SysUtils, DelphiDoom.Xcom.FlcDecoder, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomMenu.CutsceneCatalog.Intf;

type
  /// <summary>Where the player of the videos is</summary>
  TXcomVideoPhase = (
    /// <summary>The next video of the list is to be opened</summary>
    vpOpen,
    /// <summary>FlcPlayer::play: a frame at a time, each after its delay</summary>
    vpPlay,
    /// <summary>FlcPlayer::delay(10000) after the introduction of UFO</summary>
    vpTail,
    /// <summary>The palette goes to black in 20 steps of 45 ms</summary>
    vpFade,
    vpDone);

  /// <summary>
  ///   Plays the videos of a cutscene one after the other. The C++ does everything inside init() with its own
  ///   loop (events, clock, flip); here the state is a state like the others: Think decodes a frame when its
  ///   time has come (FlcPlayer::waitForNextFrame), the picture is a surface of the state as large as the
  ///   screen that the decoder draws into, the palette of the animation goes to the screen as it changes. A
  ///   key or a mouse button skips everything. With the audio sequence of UFO (the tables of
  ///   IntroSoundTrack) the musics, the sounds and the changes of speed start at their frames. The audio
  ///   chunks of the videos of TFTD are read (they give the delay between frames) but not played
  /// </summary>
  TXcomVideoState = class(TXcomState)
  strict private
    FCatalog: IXcomCutsceneCatalog;
    FVideos: TArray<string>;
    FTracks: TArray<string>;
    FUseUfoAudioSequence: Boolean;
    FStarted: Boolean;
    FPhase: TXcomVideoPhase;
    FPicture: TXcomWidget;
    FDecoder: TXcomFlcDecoder;
    FVideoIndex: Integer;
    FUseInternalAudio: Boolean;
    FWasLetterboxed: Boolean;
    FPreviousMusicVolume: Integer;
    FPreviousSoundVolume: Integer;
    FSkipped: Boolean;
    FFade: Boolean;
    FFrameReady: Boolean;
    FHasOldTick: Boolean;
    FOldTick: Cardinal;
    FDueTick: Cardinal;
    FTailEnd: Cardinal;
    FTrackPosition: Integer;
    FFadeStep: Integer;
    FFadeTick: Cardinal;
    FFadeKey: Boolean;
    FFadePalette: TXcomColors;
    FFramesShown: Integer;
    procedure Start;
    procedure OpenNextVideo;
    procedure PlayStep;
    procedure AudioSequenceStep;
    procedure EndVideo;
    procedure CloseVideo;
    procedure BeginEnding;
    procedure FadeStep;
    procedure Finish;
    procedure PaletteChanged(AFirst, ACount: Integer);
  public
    constructor Create(AHost: TXcomStateHost; const ACatalog: IXcomCutsceneCatalog;
      const AVideos, ATracks: TArray<string>; AUseUfoAudioSequence: Boolean);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    procedure Handle(AAction: TXcomAction); override;
    property Phase: TXcomVideoPhase read FPhase;
    /// <summary>The frames drawn so far, of all the videos</summary>
    property FramesShown: Integer read FFramesShown;
    /// <summary>The surface the animation is drawn into</summary>
    property Picture: TXcomWidget read FPicture;
  end;

implementation

uses
  System.Math, DelphiDoom.Xcom.Types, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomMenu.CutsceneState,
  DelphiDoom.XcomMenu.IntroSoundTrack;

const
  FADE_DELAY = 45;
  FADE_STEPS = 20;
  TAIL_MILLISECONDS = 10000;
  MIX_MAX_VOLUME = 128;
  SOUND_FOLDER = 'SOUND/';
  INTRO_CAT = 'INTRO.CAT';
  SAMPLE3_CAT = 'SAMPLE3.CAT';
  INTRO_MUSIC: array[0..2] of string = ('GMINTRO1', 'GMINTRO2', 'GMINTRO3');

constructor TXcomVideoState.Create(AHost: TXcomStateHost; const ACatalog: IXcomCutsceneCatalog;
  const AVideos, ATracks: TArray<string>; AUseUfoAudioSequence: Boolean);
begin
  inherited Create(AHost);
  FCatalog := ACatalog;
  FVideos := AVideos;
  FTracks := ATracks;
  FUseUfoAudioSequence := AUseUfoAudioSequence;
  FPhase := vpOpen;
  FPicture := TXcomWidget.Create(XCOM_ORIGINAL_WIDTH, XCOM_ORIGINAL_HEIGHT, 0, 0);
  Add(FPicture);
end;

destructor TXcomVideoState.Destroy;
begin
  FDecoder.Free;
  inherited Destroy;
end;

procedure TXcomVideoState.Init;
begin
  inherited Init;
  if not FStarted then
  begin
    FStarted := True;
    Start;
  end;
end;

procedure TXcomVideoState.Start;
var
  LDos: Boolean;
  LWindows: Boolean;
begin
  FWasLetterboxed := TXcomCutsceneState.InitDisplay(Host);
  FPreviousMusicVolume := Host.Options.MusicVolume;
  FPreviousSoundVolume := Host.Options.SoundVolume;
  if FUseUfoAudioSequence then
  begin
    LDos := FCatalog.FileExists(SOUND_FOLDER + INTRO_CAT);
    LWindows := FCatalog.FileExists(SOUND_FOLDER + SAMPLE3_CAT);
    if (not LDos) and (not LWindows) then
      FUseUfoAudioSequence := False
    else
    begin
      // ensure user can hear both music and sound effects for the vanilla intro sequence
      Host.Options.MusicVolume := Max(FPreviousMusicVolume, FPreviousSoundVolume);
      Host.Options.SoundVolume := Host.Options.MusicVolume;
      Host.SetVolume(Host.Options.SoundVolume, Host.Options.MusicVolume, Host.Options.UiVolume);
    end;
  end;
  Host.Cursor.Visible := False;
  FFade := True;
  FVideoIndex := 0;
  FPhase := vpOpen;
end;

procedure TXcomVideoState.OpenNextVideo;
var
  LPath: string;
  LIndex: Integer;
  LScreenWidth: Integer;
begin
  while FVideoIndex < Length(FVideos) do
  begin
    LIndex := FVideoIndex;
    Inc(FVideoIndex);
    FUseInternalAudio := True;
    if LIndex < Length(FTracks) then
    begin
      Host.PlayMusic(FTracks[LIndex]);
      FUseInternalAudio := False;
    end;
    LPath := FVideos[LIndex];
    if not FCatalog.FileExists(LPath) then
      Continue;
    // FlcPlayer::init
    FDecoder := TXcomFlcDecoder.Create(FCatalog.LoadBytes(LPath));
    FDecoder.OnPalette := PaletteChanged;
    LScreenWidth := Host.Screen.GetSurface.Width;
    if (FDecoder.Width > LScreenWidth) and (Host.Options.DisplayWidth >= FDecoder.Width) then
    begin
      // the video is larger than the picture of the game and the display allows it: the picture grows
      Host.Options.BaseXResolution := FDecoder.Width;
      Host.Options.BaseYResolution := FDecoder.Height;
      Host.Screen.ResetDisplay;
    end;
    FPicture.SetWidth(Host.Screen.GetSurface.Width);
    FPicture.SetHeight(Host.Screen.GetSurface.Height);
    FPicture.Clear;
    // Surface::draw clears the surface: the picture is drawn by the decoder, never redrawn
    FPicture.Redraw := False;
    FTrackPosition := 0;
    FFrameReady := False;
    FPhase := vpPlay;
    Exit;
  end;
  BeginEnding;
end;

procedure TXcomVideoState.PaletteChanged(AFirst, ACount: Integer);
var
  LIndex: Integer;
  LPalette: PXcomColors;
begin
  LPalette := Palette;
  for LIndex := AFirst to AFirst + ACount - 1 do
    LPalette^[LIndex] := FDecoder.Color(LIndex);
  Host.Screen.SetPalette(@LPalette^[AFirst], AFirst, ACount);
  // the picture and the screen must have the same colors, or the blit would map one palette onto the other
  FPicture.SetPalette(@LPalette^[AFirst], AFirst, ACount);
end;

procedure TXcomVideoState.AudioSequenceStep;
var
  LCommand: Integer;
  LSet: Integer;
  LSound: TXcomIntroSound;
  LRatio: Double;
begin
  while (FTrackPosition < XCOM_INTRO_TRACK_COUNT) and
    (FDecoder.FrameCount >= XCOM_INTRO_SOUND_TRACK[FTrackPosition].Frame) do
  begin
    LCommand := XCOM_INTRO_SOUND_TRACK[FTrackPosition].Command;
    if (LCommand and XCOM_INTRO_COMMAND_MUSIC) <> 0 then
    begin
      if (LCommand >= XCOM_INTRO_COMMAND_MUSIC) and (LCommand - XCOM_INTRO_COMMAND_MUSIC <= High(INTRO_MUSIC)) then
        Host.PlayMusic(INTRO_MUSIC[LCommand - XCOM_INTRO_COMMAND_MUSIC]);
    end
    else if (LCommand and XCOM_INTRO_COMMAND_SPEED) <> 0 then
      FDecoder.SetHeaderSpeed(LCommand and $FF)
    else if LCommand <= XCOM_INTRO_LAST_SOUND then
    begin
      // try hybrid sound set, then intro.cat or sample3.cat alone
      LRatio := Host.Options.SoundVolume / MIX_MAX_VOLUME;
      for LSet := 0 to XCOM_INTRO_SOUND_SETS - 1 do
      begin
        LSound := XCOM_INTRO_SOUNDS[LSet][LCommand];
        if Host.PlaySoundAt(LSound.CatFile, LSound.Sound, Trunc(LSound.Volume * LRatio)) then
          Break;
      end;
    end;
    Inc(FTrackPosition);
  end;
end;

procedure TXcomVideoState.PlayStep;
var
  LNow: Cardinal;
  LSamples: TBytes;
  LSurface: TXcomWidget;
  LPitch: Integer;
  LOffset: Integer;
  LDX: Integer;
  LDY: Integer;
begin
  if FSkipped then
  begin
    EndVideo;
    Exit;
  end;
  LNow := TXcomTicks.Now(Host.Clock);
  if not FFrameReady then
  begin
    // the start of the loop of FlcPlayer::play: the callback of the audio sequence, or two audio chunks
    if FUseUfoAudioSequence then
      AudioSequenceStep
    else if FDecoder.NextAudioChunk(LSamples) then
      FDecoder.NextAudioChunk(LSamples);
    if FDecoder.Finished or (not FDecoder.FindFrame) then
    begin
      EndVideo;
      Exit;
    end;
    FFrameReady := True;
    // FlcPlayer::waitForNextFrame: the very first frame does not wait
    if FHasOldTick then
      // a FLC without audio chunks has no delay of its own (the C++ would read a field never set)
      FDueTick := FOldTick +
        FDecoder.FrameDelay(FUseInternalAudio and (not FUseUfoAudioSequence) and FDecoder.HasAudio)
    else
      FDueTick := LNow;
    FHasOldTick := True;
  end;
  if Integer(LNow - FDueTick) < 0 then
    Exit;
  FOldTick := LNow;
  FFrameReady := False;
  LSurface := FPicture;
  LPitch := LSurface.Width;
  LDX := (Host.Options.BaseXResolution - XCOM_ORIGINAL_WIDTH) div 2;
  // FlcPlayer::play: vertically center the video
  LDY := (LSurface.Height - FDecoder.Height) div 2;
  LOffset := LDY * LPitch + LDX;
  FDecoder.DecodeFrame(LSurface.Pixels, LPitch, LOffset, FUseUfoAudioSequence);
  if FFramesShown < FDecoder.FrameCount then
    FFramesShown := FDecoder.FrameCount;
  if FDecoder.Finished then
    EndVideo;
end;

procedure TXcomVideoState.EndVideo;
begin
  if FUseUfoAudioSequence and (not FSkipped) then
  begin
    FTailEnd := TXcomTicks.Now(Host.Clock) + TAIL_MILLISECONDS;
    FPhase := vpTail;
  end
  else
    CloseVideo;
end;

procedure TXcomVideoState.CloseVideo;
begin
  FreeAndNil(FDecoder);
  if FSkipped then
  begin
    FFade := False;
    BeginEnding;
  end
  else
    FPhase := vpOpen;
end;

procedure TXcomVideoState.BeginEnding;
begin
  if FFade then
  begin
    FFadePalette := Host.Screen.Palette^;
    FFadeStep := FADE_STEPS;
    FFadeTick := TXcomTicks.Now(Host.Clock);
    FFadeKey := False;
    FPhase := vpFade;
  end
  else
    Finish;
end;

procedure TXcomVideoState.FadeStep;
var
  LColors: TXcomColors;
  LIndex: Integer;
begin
  // a key ends the fade at once
  if FFadeKey then
  begin
    Finish;
    Exit;
  end;
  if Integer(TXcomTicks.Now(Host.Clock) - FFadeTick) < 0 then
    Exit;
  if FFadeStep <= 0 then
  begin
    Finish;
    Exit;
  end;
  for LIndex := 0 to 255 do
  begin
    LColors[LIndex].Red := (Integer(FFadePalette[LIndex].Red) * FFadeStep) div FADE_STEPS;
    LColors[LIndex].Green := (Integer(FFadePalette[LIndex].Green) * FFadeStep) div FADE_STEPS;
    LColors[LIndex].Blue := (Integer(FFadePalette[LIndex].Blue) * FFadeStep) div FADE_STEPS;
    LColors[LIndex].Alpha := FFadePalette[LIndex].Alpha;
  end;
  Host.Screen.SetPalette(@LColors[0], 0, 256);
  Dec(FFadeStep);
  FFadeTick := TXcomTicks.Now(Host.Clock) + FADE_DELAY;
end;

procedure TXcomVideoState.Finish;
begin
  FPhase := vpDone;
  FPicture.Clear;
  if FUseUfoAudioSequence then
  begin
    Host.Options.MusicVolume := FPreviousMusicVolume;
    Host.Options.SoundVolume := FPreviousSoundVolume;
    Host.SetVolume(Host.Options.SoundVolume, Host.Options.MusicVolume, Host.Options.UiVolume);
  end;
  Host.StopMusic;
  Host.Cursor.Visible := True;
  TXcomCutsceneState.ResetDisplay(Host, FWasLetterboxed);
  Host.PopState;
end;

procedure TXcomVideoState.Think;
begin
  inherited Think;
  if not FStarted then
    Exit;
  case FPhase of
    vpOpen:
      OpenNextVideo;
    vpPlay:
      PlayStep;
    vpTail:
      if FSkipped or (Integer(TXcomTicks.Now(Host.Clock) - FTailEnd) >= 0) then
        CloseVideo;
    vpFade:
      FadeStep;
  end;
end;

procedure TXcomVideoState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  // FlcPlayer::SDLPolling: a key or a mouse button skips the videos; during the fade only a key ends it
  case AAction.Details^.Kind of
    ekKeyDown:
      if FPhase = vpFade then
        FFadeKey := True
      else
        FSkipped := True;
    ekMouseDown:
      if FPhase <> vpFade then
        FSkipped := True;
  end;
end;

end.
