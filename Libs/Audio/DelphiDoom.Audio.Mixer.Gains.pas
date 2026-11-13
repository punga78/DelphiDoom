{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - volume and pan of a voice (hundredths of a       }
{  decibel, as DirectSound had them) to the gains of the left and right channel }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Mixer.Gains;

interface

const
  /// <summary>The gain of full volume: gains are fixed point numbers of 15 bits</summary>
  SFX_GAIN_ONE = 32768;

type
  TSfxMixerGains = class
  public
    /// <summary>
    ///   Attenuation in hundredths of a decibel (0 down to -10000, silence) to a gain: 10 to the power of
    ///   (attenuation / 2000), the amplitude ratio of that many decibels
    /// </summary>
    class function AttenuationToGain(AAttenuation: Integer): Integer; static;
    /// <summary>
    ///   The gains of the two channels. Like in DirectSound the pan attenuates the channel that is away from the
    ///   side of the pan, and adds to the attenuation of the volume
    /// </summary>
    class procedure ChannelGains(AVolume, APan: Integer; out ALeft, ARight: Integer); static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Audio.Types;

{ TSfxMixerGains }

class function TSfxMixerGains.AttenuationToGain(AAttenuation: Integer): Integer;
begin
  if AAttenuation <= AUDIO_VOLUME_MIN then
    Exit(0);
  if AAttenuation >= AUDIO_VOLUME_MAX then
    Exit(SFX_GAIN_ONE);
  Result := Round(Power(10.0, AAttenuation / 2000.0) * SFX_GAIN_ONE);
end;

class procedure TSfxMixerGains.ChannelGains(AVolume, APan: Integer; out ALeft, ARight: Integer);
var
  LVolume: Integer;
begin
  LVolume := EnsureRange(AVolume, AUDIO_VOLUME_MIN, AUDIO_VOLUME_MAX);
  ALeft := AttenuationToGain(LVolume - Max(0, APan));
  ARight := AttenuationToGain(LVolume - Max(0, -APan));
end;

end.
