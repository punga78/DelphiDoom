{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the factory: the composition root of the    }
{  audio of the game                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.Factory;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Music.Intf,
  DelphiDoom.XcomAudio.Intf;

type
  /// <summary>The only place that knows the classes of the audio: the mixer, the Adlib and the music player</summary>
  TXcomAudioFactory = class
  public
    /// <summary>
    ///   The mixer on the output (Game::run: Mix_OpenAudio, then setVolume of the options) and the player of the
    ///   music that plays on it. ADevice is also IXcomMixerMeter. When there is no output the device says it is not
    ///   available and nothing plays
    /// </summary>
    /// <param name="AOptions">The options of the game; they are read, not owned</param>
    class procedure CreateAudio(AOptions: TXcomOptions; const AOutput: IXcomPcmOutput; ARate: Integer;
      out ADevice: IXcomAudioDevice; out AMusic: IXcomMusicPlayer); static;
  end;

implementation

uses
  DelphiDoom.XcomAdlib.Intf, DelphiDoom.XcomAdlib.Factory, DelphiDoom.XcomEngine.Resources.Intf,
  DelphiDoom.XcomAudio.Mixer, DelphiDoom.XcomAudio.MusicPlayer, DelphiDoom.XcomAudio.CatSongs,
  DelphiDoom.XcomAudio.OptionsSettings;

class procedure TXcomAudioFactory.CreateAudio(AOptions: TXcomOptions; const AOutput: IXcomPcmOutput; ARate: Integer;
  out ADevice: IXcomAudioDevice; out AMusic: IXcomMusicPlayer);
var
  LSink: IXcomMusicSink;
  LMeter: IXcomMixerMeter;
begin
  ADevice := TXcomMixer.Create(AOutput, ARate);
  LSink := ADevice as IXcomMusicSink;
  LMeter := ADevice as IXcomMixerMeter;
  Randomize;
  AMusic := TXcomMusicPlayer.Create(LSink, TXcomOptionsMusicSettings.Create(AOptions), ARate,
    function: IXcomAdlibPlayer
    begin
      Result := TXcomAdlibFactory.CreatePlayer(ARate);
    end,
    function(const AResources: IXcomResources): IXcomAdlibSongs
    begin
      Result := TXcomCatSongs.FromResources(AResources);
    end);
  if LMeter.Open then
    ADevice.SetVolume(AOptions.SoundVolume, AOptions.MusicVolume, AOptions.UiVolume);
end;

end.
