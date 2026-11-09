{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsAudioState of OpenXcom (volumes and   }
{  preferred formats of music, sounds and videos)                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.OptionsAudioState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.Slider, DelphiDoom.XcomUi.ComboBox, DelphiDoom.XcomUi.ToggleTextButton,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf, DelphiDoom.XcomMenu.OptionsBaseState;

type
  /// <summary>
  ///   The audio options: three volume sliders, the preferred formats of music, sounds and videos, and the mute in
  ///   the background. The sounds that play when a slider is released (the test sound) are not played: the audio is
  ///   not connected to the menus yet
  /// </summary>
  TXcomOptionsAudioState = class(TXcomOptionsBaseState)
  strict private
    const
      MIX_MAX_VOLUME = 128;
      SOUND_FORMATS: array[0..2] of string = ('?', '1.4', '1.0');
    var
      FTxtMusicVolume: TXcomText;
      FSlrMusicVolume: TXcomSlider;
      FTxtSoundVolume: TXcomText;
      FSlrSoundVolume: TXcomSlider;
      FTxtUiVolume: TXcomText;
      FSlrUiVolume: TXcomSlider;
      FTxtMusicFormat: TXcomText;
      FCbxMusicFormat: TXcomComboBox;
      FTxtCurrentMusic: TXcomText;
      FTxtSoundFormat: TXcomText;
      FCbxSoundFormat: TXcomComboBox;
      FTxtCurrentSound: TXcomText;
      FTxtVideoFormat: TXcomText;
      FCbxVideoFormat: TXcomComboBox;
      FTxtOptions: TXcomText;
      FBtnBackgroundMute: TXcomToggleTextButton;
    procedure Tip(ASurface: TXcomInteractiveSurface; const ATooltip: string);
    procedure MusicVolumeChange(AAction: TXcomAction);
    procedure SoundVolumeChange(AAction: TXcomAction);
    procedure UiVolumeChange(AAction: TXcomAction);
    procedure MusicFormatChange(AAction: TXcomAction);
    procedure SoundFormatChange(AAction: TXcomAction);
    procedure VideoFormatChange(AAction: TXcomAction);
    procedure BackgroundMuteClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
  end;

implementation

procedure TXcomOptionsAudioState.Tip(ASurface: TXcomInteractiveSurface; const ATooltip: string);
begin
  ASurface.Tooltip := ATooltip;
  ASurface.OnMouseIn(TooltipIn);
  ASurface.OnMouseOut(TooltipOut);
end;

constructor TXcomOptionsAudioState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
var
  LOptions: TXcomOptions;
  LSoundDefined: Boolean;
begin
  inherited Create(AHost, AOrigin, ANavigator);
  LOptions := Host.Options;
  SetCategory(FBtnAudio);
  FTxtMusicVolume := TXcomText.Create(114, 9, 94, 8);
  FSlrMusicVolume := TXcomSlider.Create(104, 16, 94, 18);
  FTxtSoundVolume := TXcomText.Create(114, 9, 94, 40);
  FSlrSoundVolume := TXcomSlider.Create(104, 16, 94, 50);
  FTxtUiVolume := TXcomText.Create(114, 9, 94, 72);
  FSlrUiVolume := TXcomSlider.Create(104, 16, 94, 82);
  FTxtMusicFormat := TXcomText.Create(114, 9, 206, 40);
  FCbxMusicFormat := TXcomComboBox.Create(Self, 104, 16, 206, 50);
  FTxtCurrentMusic := TXcomText.Create(114, 9, 206, 68);
  FTxtSoundFormat := TXcomText.Create(114, 9, 206, 82);
  FCbxSoundFormat := TXcomComboBox.Create(Self, 104, 16, 206, 92);
  FTxtCurrentSound := TXcomText.Create(114, 9, 206, 110);
  FTxtVideoFormat := TXcomText.Create(114, 9, 206, 8);
  FCbxVideoFormat := TXcomComboBox.Create(Self, 104, 16, 206, 18);
  FTxtOptions := TXcomText.Create(114, 9, 94, 104);
  FBtnBackgroundMute := TXcomToggleTextButton.Create(104, 16, 94, 114);
  Add(FTxtMusicVolume, 'text', 'audioMenu');
  Add(FSlrMusicVolume, 'button', 'audioMenu');
  Add(FTxtSoundVolume, 'text', 'audioMenu');
  Add(FSlrSoundVolume, 'button', 'audioMenu');
  Add(FTxtUiVolume, 'text', 'audioMenu');
  Add(FSlrUiVolume, 'button', 'audioMenu');
  Add(FTxtVideoFormat, 'text', 'audioMenu');
  Add(FTxtMusicFormat, 'text', 'audioMenu');
  Add(FTxtCurrentMusic, 'text', 'audioMenu');
  Add(FTxtSoundFormat, 'text', 'audioMenu');
  Add(FTxtCurrentSound, 'text', 'audioMenu');
  Add(FCbxSoundFormat, 'button', 'audioMenu');
  Add(FCbxMusicFormat, 'button', 'audioMenu');
  Add(FCbxVideoFormat, 'button', 'audioMenu');
  Add(FTxtOptions, 'text', 'audioMenu');
  Add(FBtnBackgroundMute, 'button', 'audioMenu');
  CenterAllSurfaces;
  FTxtMusicVolume.SetText(Tr('STR_MUSIC_VOLUME'));
  FSlrMusicVolume.SetRange(0, MIX_MAX_VOLUME);
  FSlrMusicVolume.SetValue(LOptions.MusicVolume);
  FSlrMusicVolume.OnChange(MusicVolumeChange);
  Tip(FSlrMusicVolume, 'STR_MUSIC_VOLUME_DESC');
  FTxtSoundVolume.SetText(Tr('STR_SFX_VOLUME'));
  FSlrSoundVolume.SetRange(0, MIX_MAX_VOLUME);
  FSlrSoundVolume.SetValue(LOptions.SoundVolume);
  FSlrSoundVolume.OnChange(SoundVolumeChange);
  Tip(FSlrSoundVolume, 'STR_SFX_VOLUME_DESC');
  FTxtUiVolume.SetText(Tr('STR_UI_VOLUME'));
  FSlrUiVolume.SetRange(0, MIX_MAX_VOLUME);
  FSlrUiVolume.SetValue(LOptions.UiVolume);
  FSlrUiVolume.OnChange(UiVolumeChange);
  Tip(FSlrUiVolume, 'STR_UI_VOLUME_DESC');
  FTxtMusicFormat.SetText(Tr('STR_PREFERRED_MUSIC_FORMAT'));
  FCbxMusicFormat.SetOptions([Tr('STR_PREFERRED_FORMAT_AUTO').Text, 'FLAC', 'OGG', 'MP3', 'MOD', 'WAV', 'Adlib', 'GM',
    'MIDI']);
  FCbxMusicFormat.SetSelected(LOptions.PreferredMusic);
  Tip(FCbxMusicFormat, 'STR_PREFERRED_MUSIC_FORMAT_DESC');
  FCbxMusicFormat.OnChange(MusicFormatChange);
  FTxtCurrentMusic.SetText(Tr('STR_CURRENT_FORMAT').Arg(Host.CurrentMusicFormat));
  FTxtSoundFormat.SetText(Tr('STR_PREFERRED_SFX_FORMAT'));
  FCbxSoundFormat.SetOptions([Tr('STR_PREFERRED_FORMAT_AUTO').Text, '1.4', '1.0']);
  FCbxSoundFormat.SetSelected(LOptions.PreferredSound);
  Tip(FCbxSoundFormat, 'STR_PREFERRED_SFX_FORMAT_DESC');
  FCbxSoundFormat.OnChange(SoundFormatChange);
  FTxtCurrentSound.SetText(Tr('STR_CURRENT_FORMAT').Arg(SOUND_FORMATS[LOptions.CurrentSound mod 3]));
  FTxtVideoFormat.SetText(Tr('STR_PREFERRED_VIDEO_FORMAT'));
  FCbxVideoFormat.SetOptions([Tr('STR_PREFERRED_VIDEO_ANIMATION').Text, Tr('STR_PREFERRED_VIDEO_SLIDESHOW').Text]);
  FCbxVideoFormat.SetSelected(LOptions.PreferredVideo);
  Tip(FCbxVideoFormat, 'STR_PREFERRED_VIDEO_FORMAT_DESC');
  FCbxVideoFormat.OnChange(VideoFormatChange);
  // these options need a restart, so they are not shown inside a game
  FTxtMusicFormat.Visible := FOrigin = ooMenu;
  FCbxMusicFormat.Visible := FOrigin = ooMenu;
  FTxtCurrentMusic.Visible := FOrigin = ooMenu;
  // the sound formats only apply to UFO: the mods that define the sounds do not have them
  LSoundDefined := (Host.Resources <> nil) and Host.Resources.HasSoundDefinitions;
  FTxtSoundFormat.Visible := (FOrigin = ooMenu) and not LSoundDefined;
  FCbxSoundFormat.Visible := (FOrigin = ooMenu) and not LSoundDefined;
  FTxtCurrentSound.Visible := (FOrigin = ooMenu) and not LSoundDefined;
  FTxtOptions.SetText(Tr('STR_SOUND_OPTIONS'));
  FBtnBackgroundMute.SetText(Tr('STR_BACKGROUND_MUTE'));
  FBtnBackgroundMute.SetPressed(LOptions.BackgroundMute);
  FBtnBackgroundMute.OnMouseClick(BackgroundMuteClick);
  Tip(FBtnBackgroundMute, 'STR_BACKGROUND_MUTE_DESC');
end;

procedure TXcomOptionsAudioState.MusicVolumeChange(AAction: TXcomAction);
begin
  Host.Options.MusicVolume := FSlrMusicVolume.GetValue;
  Host.SetVolume(Host.Options.SoundVolume, Host.Options.MusicVolume, Host.Options.UiVolume);
end;

procedure TXcomOptionsAudioState.SoundVolumeChange(AAction: TXcomAction);
begin
  Host.Options.SoundVolume := FSlrSoundVolume.GetValue;
  Host.SetVolume(Host.Options.SoundVolume, Host.Options.MusicVolume, Host.Options.UiVolume);
end;

procedure TXcomOptionsAudioState.UiVolumeChange(AAction: TXcomAction);
begin
  Host.Options.UiVolume := FSlrUiVolume.GetValue;
  Host.SetVolume(Host.Options.SoundVolume, Host.Options.MusicVolume, Host.Options.UiVolume);
end;

procedure TXcomOptionsAudioState.MusicFormatChange(AAction: TXcomAction);
begin
  Host.Options.PreferredMusic := FCbxMusicFormat.GetSelected;
  Host.Options.Reload := True;
end;

procedure TXcomOptionsAudioState.SoundFormatChange(AAction: TXcomAction);
begin
  Host.Options.PreferredSound := FCbxSoundFormat.GetSelected;
  Host.Options.Reload := True;
end;

procedure TXcomOptionsAudioState.VideoFormatChange(AAction: TXcomAction);
begin
  Host.Options.PreferredVideo := FCbxVideoFormat.GetSelected;
end;

procedure TXcomOptionsAudioState.BackgroundMuteClick(AAction: TXcomAction);
begin
  Host.Options.BackgroundMute := FBtnBackgroundMute.GetPressed;
end;

end.
