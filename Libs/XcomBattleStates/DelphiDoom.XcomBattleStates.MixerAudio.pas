{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the sounds of the battle on    }
{  the channels of the mixer (Sound::play with an angle, Sound::loop)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.MixerAudio;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomAudio.Intf, DelphiDoom.XcomBattleStates.Screens.Intf;

type
  /// <summary>
  ///   IXcomBattleAudio on an IXcomChannelMixer: the waves come from the resources of the host (BATTLE.CAT on land,
  ///   BATTLE2.CAT under water, as Mod::getSoundByDepth), a sound takes the first free channel and is panned with
  ///   Options::StereoSound, the ambience loops on the reserved channel 3. The host is not owned
  /// </summary>
  TXcomBattleMixerAudio = class(TInterfacedObject, IXcomBattleAudio)
  strict private
    FHost: TXcomStateHost;
    FMixer: IXcomChannelMixer;
    function Wave(ADepth, ASound: Integer): TBytes;
  public
    constructor Create(AHost: TXcomStateHost; const AMixer: IXcomChannelMixer);
    procedure PlaySound(ADepth, ASound, AAngle: Integer);
    procedure LoopAmbience(ADepth, ASound: Integer);
    procedure StopAmbience;
  end;

implementation

const
  AMBIENT_CHANNEL = 3;

constructor TXcomBattleMixerAudio.Create(AHost: TXcomStateHost; const AMixer: IXcomChannelMixer);
begin
  inherited Create;
  FHost := AHost;
  FMixer := AMixer;
end;

function TXcomBattleMixerAudio.Wave(ADepth, ASound: Integer): TBytes;
begin
  Result := nil;
  if (ASound < 0) or FHost.Options.GetBool('mute') or (FHost.Resources = nil) then
    Exit;
  if ADepth = 0 then
    Result := FHost.Resources.SoundWave('BATTLE.CAT', ASound)
  else
    Result := FHost.Resources.SoundWave('BATTLE2.CAT', ASound);
end;

procedure TXcomBattleMixerAudio.PlaySound(ADepth, ASound, AAngle: Integer);
var
  LWave: TBytes;
  LChannel: Integer;
begin
  LWave := Wave(ADepth, ASound);
  if Length(LWave) = 0 then
    Exit;
  LChannel := FMixer.PlayChannel(LWave, -1, 0);
  if (LChannel >= 0) and FHost.Options.GetBool('StereoSound') then
    FMixer.SetPosition(LChannel, AAngle, 0);
end;

procedure TXcomBattleMixerAudio.LoopAmbience(ADepth, ASound: Integer);
var
  LWave: TBytes;
begin
  if FMixer.IsChannelPlaying(AMBIENT_CHANNEL) then
    Exit;
  LWave := Wave(ADepth, ASound);
  if Length(LWave) > 0 then
    FMixer.PlayChannel(LWave, AMBIENT_CHANNEL, -1);
end;

procedure TXcomBattleMixerAudio.StopAmbience;
begin
  FMixer.HaltChannel(AMBIENT_CHANNEL);
end;

end.
