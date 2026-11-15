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
  TWarSceneAudio = class(TInterfacedObject, IWarSceneAudio)
  strict private
    FLibrary: IWarAudioLibrary;
    FMixer: IWarSoundMixer;
    FMusic: IWarMusicPlayer;
    FSoundsStarted: Integer;
    FSongsStarted: Integer;
    FSongsStopped: Integer;
    FFailures: Integer;
    FMuted: Boolean;
  public
    /// <summary>The music player may be nil (no song is played)</summary>
    constructor Create(const ALibrary: IWarAudioLibrary; const AMixer: IWarSoundMixer; const AMusic: IWarMusicPlayer);
    procedure Play(AAudioId: Integer; ALoop: Boolean);
    procedure StopMusic;
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
    ///   While True nothing is played (a saved game that is loaded plays its old frames again and they must not be heard);
    ///   what is asked in the meantime is dropped
    /// </summary>
    property Muted: Boolean read FMuted write FMuted;
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
end;

procedure TWarSceneAudio.Play(AAudioId: Integer; ALoop: Boolean);
var
  LKind: TWarAudioKind;
begin
  if FMuted then
    Exit;
  try
    LKind := FLibrary.KindOf(AAudioId);
    if LKind = wakWave then
    begin
      FMixer.Play(AAudioId, ALoop);
      Inc(FSoundsStarted);
    end
    else if Assigned(FMusic) then
    begin
      if FMusic.Play(FLibrary.GetMusic(AAudioId), ALoop, 0) then
        Inc(FSongsStarted)
      else
        Inc(FFailures);
    end;
  except
    on EWarException do
      Inc(FFailures);
  end;
end;

procedure TWarSceneAudio.StopMusic;
begin
  if Assigned(FMusic) and not FMuted then
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
