{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sound of the scenes on the mixer and the song  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.SceneAudio;

interface

uses
  System.SysUtils, DelphiDoom.War.Audio.Intf, DelphiDoom.War.Music.Intf, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   IWarSceneAudio of the program: the audio id that the scenes give is the index of a record of DATA.WAR, so a
  ///   wave goes to the mixer of the effects and a song to the music player. A sound that cannot be played (not a
  ///   sound, not decodable) is counted and skipped: a missing sound must not stop the game
  /// </summary>
  TWarSceneAudio = class(TInterfacedObject, IWarSceneAudio, IWarPositionalAudio)
  strict private
    FLibrary: IWarAudioLibrary;
    FMixer: IWarSoundMixer;
    FMusic: IWarMusicPlayer;
    FSoundsStarted: Integer;
    FSongsStarted: Integer;
    FSongsStopped: Integer;
    FFailures: Integer;
    FMuted: Boolean;
    // what the song asked for while Muted was True: the last request only, started when the sound comes back
    FDeferredSong: Integer;
    FDeferredLoop: Boolean;
    FDeferredStop: Boolean;
    procedure SetMuted(AValue: Boolean);
    procedure StartSong(AAudioId: Integer; ALoop: Boolean);
  public
    /// <summary>The music player may be nil (no song is played)</summary>
    constructor Create(const ALibrary: IWarAudioLibrary; const AMixer: IWarSoundMixer; const AMusic: IWarMusicPlayer);
    procedure Play(AAudioId: Integer; ALoop: Boolean);
    procedure StopMusic;
    /// <summary>
    ///   A sound with a place on the map: the mixer plays it at the volume that the place has for the viewport (a song has
    ///   no place and is not played here)
    /// </summary>
    procedure PlayAt(AAudioId: Integer; AX, AY: Single);
    /// <summary>The rectangle of the map on screen (map->camera.viewport), which the mixer reads at every block it mixes</summary>
    procedure SetViewport(AX, AY, AWidth, AHeight: Single);
    /// <summary>
    ///   Gives the volumes and the switches of the settings to the mixer and the player, and silences both while the
    ///   game is changing scene (AudioEnabled false), as the callback of the original does
    /// </summary>
    procedure Synchronize(const ASettings: IWarGameSettings);
    /// <summary>The sounds the mixer was asked to start</summary>
    property SoundsStarted: Integer read FSoundsStarted;
    property SongsStarted: Integer read FSongsStarted;
    property SongsStopped: Integer read FSongsStopped;
    /// <summary>The audio ids that could not be played</summary>
    property Failures: Integer read FFailures;
    /// <summary>
    ///   While True no sound is played (a saved game that is loaded plays its old frames again and they must not be
    ///   heard); the effects asked in the meantime are dropped. The song is not: a song starts once at the entrance
    ///   of a scene, so the last request about it (play or stop) is remembered and done when Muted goes back to False,
    ///   otherwise a loaded game would have no music
    /// </summary>
    property Muted: Boolean read FMuted write SetMuted;
  end;

implementation

uses
  DelphiDoom.War.Audio.Types, DelphiDoom.War.Types;

{ TWarSceneAudio }

constructor TWarSceneAudio.Create(const ALibrary: IWarAudioLibrary; const AMixer: IWarSoundMixer;
  const AMusic: IWarMusicPlayer);
begin
  inherited Create;
  if not Assigned(ALibrary) then
    raise EArgumentNilException.Create('ALibrary');
  if not Assigned(AMixer) then
    raise EArgumentNilException.Create('AMixer');
  FLibrary := ALibrary;
  FMixer := AMixer;
  FMusic := AMusic;
  FDeferredSong := -1;
end;

procedure TWarSceneAudio.SetMuted(AValue: Boolean);
var
  LSong: Integer;
begin
  if AValue = FMuted then
    Exit;
  FMuted := AValue;
  if AValue then
  begin
    FDeferredSong := -1;
    FDeferredStop := False;
    Exit;
  end;
  LSong := FDeferredSong;
  FDeferredSong := -1;
  if LSong >= 0 then
    StartSong(LSong, FDeferredLoop)
  else if FDeferredStop then
    StopMusic;
  FDeferredStop := False;
end;

procedure TWarSceneAudio.StartSong(AAudioId: Integer; ALoop: Boolean);
begin
  if not Assigned(FMusic) then
    Exit;
  try
    if FMusic.Play(FLibrary.GetMusic(AAudioId), ALoop, 0) then
      Inc(FSongsStarted)
    else
      Inc(FFailures);
  except
    on EWarException do
      Inc(FFailures);
  end;
end;

procedure TWarSceneAudio.Play(AAudioId: Integer; ALoop: Boolean);
var
  LKind: TWarAudioKind;
begin
  try
    LKind := FLibrary.KindOf(AAudioId);
    if LKind = wakWave then
    begin
      if FMuted then
        Exit;
      FMixer.Play(AAudioId, ALoop);
      Inc(FSoundsStarted);
    end
    else if FMuted then
    begin
      FDeferredSong := AAudioId;
      FDeferredLoop := ALoop;
      FDeferredStop := False;
    end
    else
      StartSong(AAudioId, ALoop);
  except
    on EWarException do
      Inc(FFailures);
  end;
end;

procedure TWarSceneAudio.PlayAt(AAudioId: Integer; AX, AY: Single);
begin
  if FMuted then
    Exit;
  try
    if FLibrary.KindOf(AAudioId) = wakWave then
    begin
      FMixer.PlayAt(AAudioId, AX, AY, False);
      Inc(FSoundsStarted);
    end;
  except
    on EWarException do
      Inc(FFailures);
  end;
end;

procedure TWarSceneAudio.SetViewport(AX, AY, AWidth, AHeight: Single);
begin
  FMixer.SetViewport(AX, AY, AWidth, AHeight);
end;

procedure TWarSceneAudio.StopMusic;
begin
  if FMuted then
  begin
    FDeferredSong := -1;
    FDeferredStop := True;
    Exit;
  end;
  if Assigned(FMusic) then
  begin
    FMusic.Stop(0);
    Inc(FSongsStopped);
  end;
end;

procedure TWarSceneAudio.Synchronize(const ASettings: IWarGameSettings);
begin
  FMixer.SetVolume(ASettings.SoundVolume, ASettings.SoundEnabled);
  FMixer.SetSilenced(not ASettings.AudioEnabled);
  if Assigned(FMusic) then
  begin
    FMusic.SetVolume(ASettings.MusicVolume, ASettings.MusicEnabled);
    FMusic.SetSilenced(not ASettings.AudioEnabled);
  end;
end;

end.
