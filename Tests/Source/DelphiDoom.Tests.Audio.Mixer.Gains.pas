{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - the gains of the software mixer     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Mixer.Gains;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Audio.Types, DelphiDoom.Audio.Mixer.Gains;

type
  [TestFixture]
  [Category('audio')]
  TTestAudioMixerGains = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlGuadagnoPienoAZeroDecibel;
    [Test]
    procedure DovrebbeDareSilenzioAlMinimoDelVolume;
    [Test]
    procedure DovrebbeDareSilenzioOltreIlMinimo;
    [TestCase('seiDecibel', '-600,16423')]
    [TestCase('venti', '-2000,3277')]
    [TestCase('dodici', '-1200,8231')]
    procedure DovrebbeSeguireLaFormulaDeiDecibel(AAttenuation, AExpected: Integer);
    [Test]
    procedure DovrebbeTenerePienoIlCanaleDelLatoDelPan;
    [Test]
    procedure DovrebbeAttenuareIlCanaleLontanoDalPan;
    [Test]
    procedure DovrebbeSilenziareIlCanaleLontanoAPanPieno;
    [Test]
    procedure DovrebbeSommareVolumeEPan;
    [Test]
    procedure DovrebbeLimitareUnVolumeFuoriScala;
  end;

implementation

{ TTestAudioMixerGains }

procedure TTestAudioMixerGains.DovrebbeDareIlGuadagnoPienoAZeroDecibel;
begin
  Assert.AreEqual<Integer>(SFX_GAIN_ONE, TSfxMixerGains.AttenuationToGain(0));
end;

procedure TTestAudioMixerGains.DovrebbeDareSilenzioAlMinimoDelVolume;
begin
  Assert.AreEqual<Integer>(0, TSfxMixerGains.AttenuationToGain(AUDIO_VOLUME_MIN));
end;

procedure TTestAudioMixerGains.DovrebbeDareSilenzioOltreIlMinimo;
begin
  Assert.AreEqual<Integer>(0, TSfxMixerGains.AttenuationToGain(-25000));
end;

procedure TTestAudioMixerGains.DovrebbeSeguireLaFormulaDeiDecibel(AAttenuation, AExpected: Integer);
begin
  Assert.IsTrue(Abs(TSfxMixerGains.AttenuationToGain(AAttenuation) - AExpected) <= 1);
end;

procedure TTestAudioMixerGains.DovrebbeTenerePienoIlCanaleDelLatoDelPan;
var
  LLeft: Integer;
  LRight: Integer;
begin
  TSfxMixerGains.ChannelGains(0, -600, LLeft, LRight);
  Assert.AreEqual<Integer>(SFX_GAIN_ONE, LLeft);
  TSfxMixerGains.ChannelGains(0, 600, LLeft, LRight);
  Assert.AreEqual<Integer>(SFX_GAIN_ONE, LRight);
end;

procedure TTestAudioMixerGains.DovrebbeAttenuareIlCanaleLontanoDalPan;
var
  LLeft: Integer;
  LRight: Integer;
begin
  TSfxMixerGains.ChannelGains(0, -600, LLeft, LRight);
  Assert.IsTrue(Abs(LRight - 16423) <= 1);
end;

procedure TTestAudioMixerGains.DovrebbeSilenziareIlCanaleLontanoAPanPieno;
var
  LLeft: Integer;
  LRight: Integer;
begin
  TSfxMixerGains.ChannelGains(0, AUDIO_PAN_RIGHT, LLeft, LRight);
  Assert.AreEqual<Integer>(0, LLeft);
  Assert.AreEqual<Integer>(SFX_GAIN_ONE, LRight);
end;

procedure TTestAudioMixerGains.DovrebbeSommareVolumeEPan;
var
  LLeft: Integer;
  LRight: Integer;
begin
  TSfxMixerGains.ChannelGains(-600, 600, LLeft, LRight);
  Assert.IsTrue(Abs(LLeft - 8231) <= 1);
  Assert.IsTrue(Abs(LRight - 16423) <= 1);
end;

procedure TTestAudioMixerGains.DovrebbeLimitareUnVolumeFuoriScala;
var
  LLeft: Integer;
  LRight: Integer;
begin
  TSfxMixerGains.ChannelGains(500, 0, LLeft, LRight);
  Assert.AreEqual<Integer>(SFX_GAIN_ONE, LLeft);
  TSfxMixerGains.ChannelGains(-30000, 0, LLeft, LRight);
  Assert.AreEqual<Integer>(0, LLeft);
end;

end.
