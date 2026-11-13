{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the song under the effects in the PCM source of        }
{  Libs\War                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.PcmSourceMusic;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameHost.Audio.Intf, DelphiDoom.War.Audio.Intf,
  DelphiDoom.War.Music.Intf, DelphiDoom.Tests.War.MusicFakes;

type
  [TestFixture]
  [Category('war')]
  TTestWarPcmSourceMusic = class
  strict private
    FMixerObject: TFakeSoundMixer;
    FMixer: IWarSoundMixer;
    FMusic: IWarMusicPlayer;
    function Source(AWithMusic: Boolean; AMusicLevel, AMixerLevel: SmallInt): IGameHostPcmSource;
    function Render(const ASource: IGameHostPcmSource; AFrames: Integer): TArray<SmallInt>;
  public
    [Test]
    procedure DovrebbeSommareMusicaEdEffettiSuiDueCanali;
    [Test]
    procedure DovrebbeDareSoloGliEffettiSenzaMusica;
    [Test]
    procedure DovrebbeDareSoloLaMusicaSenzaEffetti;
    [Test]
    procedure DovrebbeDareSilenzioSeLaMusicaEFermaENonCeNulla;
    [Test]
    procedure DovrebbeServireUnaRichiestaPiuLungaDelBufferInterno;
    [Test]
    procedure DovrebbeCrearelaSorgenteConLaFabbricaConEMenoMusica;
  end;

implementation

uses
  DelphiDoom.War.Audio.Factory, DelphiDoom.War.Music.Types, DelphiDoom.War.Music.Player;

{ TTestWarPcmSourceMusic }

function TTestWarPcmSourceMusic.Source(AWithMusic: Boolean; AMusicLevel, AMixerLevel: SmallInt): IGameHostPcmSource;
var
  LEvents: TArray<TWarMusicEvent>;
begin
  FMixerObject := TFakeSoundMixer.Create;
  FMixerObject.Level := AMixerLevel;
  FMixer := FMixerObject;
  if AWithMusic then
  begin
    // one event far away: the song plays and the synth adds its level
    SetLength(LEvents, 1);
    LEvents[0] := Default(TWarMusicEvent);
    LEvents[0].TimeMs := 1000000;
    LEvents[0].Kind := wmkNoteOff;
    FMusic := TWarMusicPlayer.Create(TFakeMusicSynth.Create(AMusicLevel), TFakeMusicTimeline.Create(LEvents), 44100);
    FMusic.Play([1], False, 0);
    Result := TWarAudioFactory.CreatePcmSource(FMixer, FMusic);
  end
  else
    Result := TWarAudioFactory.CreatePcmSource(FMixer);
end;

function TTestWarPcmSourceMusic.Render(const ASource: IGameHostPcmSource; AFrames: Integer): TArray<SmallInt>;
begin
  SetLength(Result, AFrames * 2);
  // the output asks for 16 bit stereo: 4 bytes a frame
  FillChar(Result[0], Length(Result) * SizeOf(SmallInt), $55);
  ASource.Render(PByte(@Result[0]), AFrames * 4);
end;

procedure TTestWarPcmSourceMusic.DovrebbeSommareMusicaEdEffettiSuiDueCanali;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := Render(Source(True, 100, 5), 50);
  Assert.AreEqual<Integer>(105, LSamples[0]);
  Assert.AreEqual<Integer>(105, LSamples[1]);
  Assert.AreEqual<Integer>(105, LSamples[98]);
  Assert.AreEqual<Integer>(105, LSamples[99]);
end;

procedure TTestWarPcmSourceMusic.DovrebbeDareSoloGliEffettiSenzaMusica;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := Render(Source(False, 0, 7), 20);
  Assert.AreEqual<Integer>(7, LSamples[0]);
  Assert.AreEqual<Integer>(7, LSamples[39]);
end;

procedure TTestWarPcmSourceMusic.DovrebbeDareSoloLaMusicaSenzaEffetti;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := Render(Source(True, 100, 0), 20);
  Assert.AreEqual<Integer>(100, LSamples[0]);
  Assert.AreEqual<Integer>(100, LSamples[39]);
end;

procedure TTestWarPcmSourceMusic.DovrebbeDareSilenzioSeLaMusicaEFermaENonCeNulla;
var
  LSamples: TArray<SmallInt>;
  LSource: IGameHostPcmSource;
begin
  LSource := Source(True, 100, 0);
  FMusic.Stop(0);
  LSamples := Render(LSource, 20);
  Assert.AreEqual<Integer>(0, LSamples[0]);
  Assert.AreEqual<Integer>(0, LSamples[39]);
end;

procedure TTestWarPcmSourceMusic.DovrebbeServireUnaRichiestaPiuLungaDelBufferInterno;
var
  LSamples: TArray<SmallInt>;
begin
  // 20000 frames: more than the 8192 samples the source mixes at a time
  LSamples := Render(Source(True, 100, 5), 20000);
  Assert.AreEqual<Integer>(105, LSamples[0]);
  Assert.AreEqual<Integer>(105, LSamples[8192 * 2]);
  Assert.AreEqual<Integer>(105, LSamples[39999]);
end;

procedure TTestWarPcmSourceMusic.DovrebbeCrearelaSorgenteConLaFabbricaConEMenoMusica;
var
  LSource: IGameHostPcmSource;
begin
  LSource := TWarAudioFactory.CreatePcmSource(TFakeSoundMixer.Create, nil);
  Assert.IsNotNull(LSource);
  Assert.IsNotNull(TWarAudioFactory.CreatePcmSource(TFakeSoundMixer.Create));
end;

end.
