{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the mixer of the Quake III sound                       }
{                                                                              }
{  Small buffers worked out by hand from snd_mix.c (volume = leftvol * snd_vol }
{  shifted by 8, the sum shifted by 8 and clamped). The parity with the C on   }
{  long random sequences is in DelphiDoom.Tests.Audio.Q3.Parity.               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.Mixer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Audio.Q3.Rig;

type
  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3Mixer = class
  strict private
    FRig: TQ3TestRig;
    procedure UseRig(AChannels, ASamples, ABits: Integer);
    function Expected(AValue, AVolume, ASoundVolume: Integer): Integer;
    function StartedChannel(AHandle: Integer; ALeft, ARight: Integer): Integer;
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMescolareUnSuonoConIlVolumeDelCanale;
    [Test]
    procedure DovrebbeFermarsiAllaFineDelSuono;
    [Test]
    procedure DovrebbeUsareIlVolumeGeneraleDiTrecentoCinquantacinque;
    [Test]
    procedure DovrebbeTagliareLaSommaAlMassimoEAlMinimo;
    [Test]
    procedure DovrebbeScrivereSoloIlCanaleSinistroNelMono;
    [Test]
    procedure DovrebbeScrivereGliOttoBitConIlCentroA128;
    [Test]
    procedure DovrebbeScrivereGliOttoBitInStereo;
    [Test]
    procedure DovrebbeSaltareUnCanaleSenzaVolume;
    [Test]
    procedure DovrebbeSaltareUnCanaleNonAncoraIniziato;
    [Test]
    procedure DovrebbeLeggereAttraversoUnConfineDiBlocco;
    [Test]
    procedure DovrebbeRipeterePiuVolteUnSuonoInCiclo;
    [Test]
    procedure DovrebbeUsareSoloIlLatoDelCicloAudibile;
    [Test]
    procedure DovrebbeMescolareInPassiDaQuattroMilaNovantasei;
    [Test]
    procedure DovrebbeGirareNelBufferDelDispositivo;
    [Test]
    procedure DovrebbeScrivereLOndaDiProva;
    [Test]
    procedure DovrebbeLeggereConLaScalaDelDoppler;
    [Test]
    procedure DovrebbeLasciareIlCampioneConUnaScalaNonNumerica;
    [Test]
    procedure DovrebbeLeggereUnCicloDopplerOltreLaFineSenzaUscire;
    [Test]
    procedure DovrebbeSaltareLaTrasferimentoSenzaBufferDelDispositivo;
    [Test]
    procedure DovrebbeTroncareIlVolumeGenerale;
    [Test]
    procedure DovrebbeTagliareLaSommaNelCasoGenerale;
    [Test]
    procedure DovrebbeUsareSoloLaParteDelFlussoCheServe;
    [Test]
    procedure DovrebbeGirareAllaFineDellaCatenaDiBlocchi;
    [Test]
    procedure DovrebbeSaltareBlocchiOltreLaFineConLaVecchiaScala;
  end;

implementation

uses
  System.Math, DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Sfx, DelphiDoom.Audio.Q3.Intf;

{ TTestQ3Mixer }

procedure TTestQ3Mixer.UseRig(AChannels, ASamples, ABits: Integer);
begin
  FRig.Free;
  FRig := TQ3TestRig.Create(AChannels, ASamples, ABits);
  FRig.Sound.State.Volume := 1.0;
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
end;

procedure TTestQ3Mixer.TearDown;
begin
  FreeAndNil(FRig);
end;

// what the C does to a sample: volume * snd_vol shifted, then the transfer shifts again
function TTestQ3Mixer.Expected(AValue, AVolume, ASoundVolume: Integer): Integer;
begin
  Result := TQ3Math.Sar(TQ3Math.Sar(AValue * AVolume * ASoundVolume, 8), 8);
end;

// starts a sound on a free channel and sets its volumes; the channel index
function TTestQ3Mixer.StartedChannel(AHandle: Integer; ALeft, ARight: Integer): Integer;
begin
  // apart in time, so that the double start of the same sound is not refused
  FRig.Clock.Milliseconds := FRig.Clock.Milliseconds + 100;
  Result := FRig.Sound.Pool.StartSound(nil, 3, Q3_CHAN_AUTO,
    FRig.Sound.Registry.SfxOf(AHandle));
  FRig.Sound.State.Channels[Result].LeftVolume := ALeft;
  FRig.Sound.State.Channels[Result].RightVolume := ARight;
  FRig.Sound.Pool.ScanChannelStarts;
end;

procedure TTestQ3Mixer.DovrebbeMescolareUnSuonoConIlVolumeDelCanale;
var
  LHandle: Integer;
begin
  UseRig(2, 8192, 16);
  LHandle := FRig.AddConstant('a', 1000, 3000);
  StartedChannel(LHandle, 127, 64);
  FRig.Sound.Mixer.PaintChannels(100);
  Assert.AreEqual(100, FRig.Sound.State.PaintedTime);
  Assert.AreEqual(Expected(1000, 127, 255), Integer(FRig.DeviceSample(0)));
  Assert.AreEqual(Expected(1000, 64, 255), Integer(FRig.DeviceSample(1)));
  Assert.AreEqual(Expected(1000, 127, 255), Integer(FRig.DeviceSample(198)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(200)));
  Assert.AreEqual(494, Integer(FRig.DeviceSample(0)));
end;

procedure TTestQ3Mixer.DovrebbeFermarsiAllaFineDelSuono;
var
  LHandle: Integer;
begin
  UseRig(2, 8192, 16);
  LHandle := FRig.AddConstant('a', 1000, 50);
  StartedChannel(LHandle, 127, 127);
  FRig.Sound.Mixer.PaintChannels(100);
  Assert.AreEqual(494, Integer(FRig.DeviceSample(98)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(100)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(199)));
end;

procedure TTestQ3Mixer.DovrebbeUsareIlVolumeGeneraleDiTrecentoCinquantacinque;
var
  LHandle: Integer;
begin
  UseRig(2, 8192, 16);
  FRig.Sound.State.Volume := 0.5;
  LHandle := FRig.AddConstant('a', 20000, 3000);
  StartedChannel(LHandle, 127, 127);
  FRig.Sound.Mixer.PaintChannels(10);
  // 0.5 * 255 = 127
  Assert.AreEqual(127, FRig.Sound.Mixer.SoundVolume);
  Assert.AreEqual(Expected(20000, 127, 127), Integer(FRig.DeviceSample(0)));
end;

procedure TTestQ3Mixer.DovrebbeTagliareLaSommaAlMassimoEAlMinimo;
var
  LPositive, LNegative: Integer;
begin
  UseRig(2, 8192, 16);
  LPositive := FRig.AddConstant('p', 32767, 3000);
  LNegative := FRig.AddConstant('n', -32768, 3000);
  StartedChannel(LPositive, 255, 255);
  StartedChannel(LPositive, 255, 255);
  FRig.Sound.Mixer.PaintChannels(10);
  Assert.AreEqual(32767, Integer(FRig.DeviceSample(0)));
  Assert.AreEqual(32767, Integer(FRig.DeviceSample(1)));
  // two of the negative one
  FRig.Sound.Pool.Reset;
  FRig.Sound.State.PaintedTime := 0;
  StartedChannel(LNegative, 255, 255);
  StartedChannel(LNegative, 255, 255);
  FRig.Sound.Mixer.PaintChannels(10);
  Assert.AreEqual(-32768, Integer(FRig.DeviceSample(0)));
end;

procedure TTestQ3Mixer.DovrebbeScrivereSoloIlCanaleSinistroNelMono;
var
  LHandle, LIndex: Integer;
begin
  UseRig(1, 4096, 16);
  LHandle := FRig.AddConstant('a', 1000, 3000);
  StartedChannel(LHandle, 127, 0);
  FRig.Sound.Mixer.PaintChannels(20);
  for LIndex := 0 to 19 do
    Assert.AreEqual(494, Integer(FRig.DeviceSample(LIndex)), LIndex.ToString);
  Assert.AreEqual(0, Integer(FRig.DeviceSample(20)));
end;

procedure TTestQ3Mixer.DovrebbeScrivereGliOttoBitConIlCentroA128;
var
  LHandle: Integer;
begin
  UseRig(1, 4096, 8);
  LHandle := FRig.AddConstant('a', 1000, 3000);
  StartedChannel(LHandle, 127, 0);
  FRig.Sound.Mixer.PaintChannels(20);
  // 494 shifted by 8 is 1: 129
  Assert.AreEqual(129, Integer(FRig.Device.Buffer[0]));
  Assert.AreEqual(129, Integer(FRig.Device.Buffer[19]));
  // the rest is the silence of 8 bits that the initialisation wrote
  Assert.AreEqual(128, Integer(FRig.Device.Buffer[20]));
end;

procedure TTestQ3Mixer.DovrebbeScrivereGliOttoBitInStereo;
var
  LHandle: Integer;
begin
  UseRig(2, 4096, 8);
  LHandle := FRig.AddConstant('a', -20000, 3000);
  StartedChannel(LHandle, 127, 0);
  FRig.Sound.Mixer.PaintChannels(10);
  // left: -20000 gives -9884 after the shifts of the 16 bit case, -39 after one more: 89
  Assert.AreEqual(-9884, Expected(-20000, 127, 255));
  Assert.AreEqual(89, Integer(FRig.Device.Buffer[0]));
  Assert.AreEqual(128, Integer(FRig.Device.Buffer[1]));
end;

procedure TTestQ3Mixer.DovrebbeSaltareUnCanaleSenzaVolume;
var
  LHandle: Integer;
begin
  UseRig(2, 8192, 16);
  LHandle := FRig.AddConstant('a', 1000, 3000);
  StartedChannel(LHandle, 0, 0);
  FRig.Sound.Mixer.PaintChannels(10);
  Assert.AreEqual(0, Integer(FRig.DeviceSample(0)));
end;

procedure TTestQ3Mixer.DovrebbeSaltareUnCanaleNonAncoraIniziato;
var
  LHandle, LChannel: Integer;
begin
  UseRig(2, 8192, 16);
  LHandle := FRig.AddConstant('a', 1000, 3000);
  LChannel := FRig.Sound.Pool.StartSound(nil, 3, Q3_CHAN_AUTO, FRig.Sound.Registry.SfxOf(LHandle));
  // not scanned: StartSample is START_SAMPLE_IMMEDIATE (the C would read before the sound)
  Assert.AreEqual(Q3_START_SAMPLE_IMMEDIATE, FRig.Sound.State.Channels[LChannel].StartSample);
  FRig.Sound.Mixer.PaintChannels(10);
  Assert.AreEqual(0, Integer(FRig.DeviceSample(0)));
end;

procedure TTestQ3Mixer.DovrebbeLeggereAttraversoUnConfineDiBlocco;
const
  CHECKED: array[0..7] of Integer = (0, 1, 1023, 1024, 1025, 2047, 2048, 2099);
var
  LSamples: TArray<SmallInt>;
  LIndex, LHandle, LCheck: Integer;
begin
  UseRig(2, 8192, 16);
  SetLength(LSamples, 2500);
  for LIndex := 0 to 2499 do
    LSamples[LIndex] := LIndex * 10 - 12000;
  LHandle := FRig.Sound.Registry.AddSound('ramp', LSamples, 2500);
  StartedChannel(LHandle, 127, 127);
  FRig.Sound.Mixer.PaintChannels(2100);
  for LCheck := 0 to High(CHECKED) do
  begin
    LIndex := CHECKED[LCheck];
    Assert.AreEqual(Expected(LSamples[LIndex], 127, 255), Integer(FRig.DeviceSample(LIndex * 2)),
      'sample ' + LIndex.ToString);
  end;
end;

procedure TTestQ3Mixer.DovrebbeRipeterePiuVolteUnSuonoInCiclo;
var
  LHandle, LIndex: Integer;
  LSamples: TArray<SmallInt>;
begin
  UseRig(2, 8192, 16);
  SetLength(LSamples, 10);
  for LIndex := 0 to 9 do
    LSamples[LIndex] := (LIndex + 1) * 1000;
  LHandle := FRig.Sound.Registry.AddSound('loop', LSamples, 10);
  FRig.Sound.AddRealLoopingSound(5, Vec3(0, 30, 0), Vec3(0, 0, 0), LHandle);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(1, FRig.Sound.State.NumLoopChannels);
  FRig.Sound.Mixer.PaintChannels(25);
  for LIndex := 0 to 24 do
    Assert.AreEqual(Expected(LSamples[LIndex mod 10], 90, 255), Integer(FRig.DeviceSample(LIndex * 2)),
      LIndex.ToString);
end;

procedure TTestQ3Mixer.DovrebbeUsareSoloIlLatoDelCicloAudibile;
var
  LHandle: Integer;
begin
  UseRig(2, 8192, 16);
  LHandle := FRig.AddConstant('loop', 1000, 40);
  FRig.Sound.AddRealLoopingSound(5, Vec3(0, -30, 0), Vec3(0, 0, 0), LHandle);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  FRig.Sound.Mixer.PaintChannels(10);
  Assert.AreEqual(0, Integer(FRig.DeviceSample(0)));
  Assert.AreEqual(Expected(1000, 90, 255), Integer(FRig.DeviceSample(1)));
end;

procedure TTestQ3Mixer.DovrebbeMescolareInPassiDaQuattroMilaNovantasei;
var
  LHandle: Integer;
begin
  UseRig(2, 16384, 16);
  LHandle := FRig.AddConstant('a', 1000, 6000);
  StartedChannel(LHandle, 127, 127);
  FRig.Sound.Mixer.PaintChannels(5000);
  Assert.AreEqual(5000, FRig.Sound.State.PaintedTime);
  Assert.AreEqual(494, Integer(FRig.DeviceSample(2 * 4095)));
  Assert.AreEqual(494, Integer(FRig.DeviceSample(2 * 4096)));
  Assert.AreEqual(494, Integer(FRig.DeviceSample(2 * 4999 + 1)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(2 * 5000)));
  // the paint buffer holds the last block, which began at pair 4096
  Assert.AreEqual(126503, FRig.Sound.Mixer.PaintBufferAt(0).Left);
  Assert.AreEqual(126503, FRig.Sound.Mixer.PaintBufferAt(903).Right);
end;

procedure TTestQ3Mixer.DovrebbeGirareNelBufferDelDispositivo;
var
  LHandle: Integer;
begin
  // 8192 samples = 4096 pairs
  UseRig(2, 8192, 16);
  LHandle := FRig.AddConstant('a', 1000, 3000);
  FRig.Sound.State.PaintedTime := 4090;
  StartedChannel(LHandle, 127, 127);
  FRig.Sound.Mixer.PaintChannels(4110);
  Assert.AreEqual(494, Integer(FRig.DeviceSample(2 * 4095)));
  Assert.AreEqual(494, Integer(FRig.DeviceSample(0)));
  Assert.AreEqual(494, Integer(FRig.DeviceSample(2 * 13 + 1)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(2 * 14)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(2 * 4089)));
end;

procedure TTestQ3Mixer.DovrebbeScrivereLOndaDiProva;
var
  LIndex: Integer;
begin
  UseRig(2, 8192, 16);
  FRig.Sound.State.TestSound := 1;
  FRig.Sound.Mixer.PaintChannels(5);
  for LIndex := 0 to 4 do
    Assert.AreEqual(TQ3Math.Sar(Trunc(Sin(LIndex * 0.1) * 20000 * 256), 8),
      Integer(FRig.DeviceSample(LIndex * 2)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(0)));
end;

procedure TTestQ3Mixer.DovrebbeLeggereConLaScalaDelDoppler;
var
  LHandle: Integer;
begin
  UseRig(2, 8192, 16);
  LHandle := FRig.AddConstant('a', 1000, 3000);
  FRig.Sound.State.LoopChannels[0].Sfx := FRig.Sound.Registry.SfxOf(LHandle);
  FRig.Sound.State.LoopChannels[0].LeftVolume := 100;
  FRig.Sound.State.LoopChannels[0].RightVolume := 0;
  FRig.Sound.State.LoopChannels[0].Doppler := True;
  FRig.Sound.State.LoopChannels[0].DopplerScale := 2.0;
  FRig.Sound.State.LoopChannels[0].OldDopplerScale := 1.0;
  FRig.Sound.State.NumLoopChannels := 1;
  FRig.Sound.Mixer.PaintChannels(10);
  // two samples of 1000 per output sample: 2000 * (100 * 255) / 512 = 99609 -> 389
  Assert.AreEqual(389, Integer(FRig.DeviceSample(0)));
  Assert.AreEqual(389, Integer(FRig.DeviceSample(18)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(1)));
end;

procedure TTestQ3Mixer.DovrebbeLasciareIlCampioneConUnaScalaNonNumerica;
var
  LHandle: Integer;
begin
  UseRig(2, 8192, 16);
  LHandle := FRig.AddConstant('a', 1000, 3000);
  FRig.Sound.State.LoopChannels[0].Sfx := FRig.Sound.Registry.SfxOf(LHandle);
  FRig.Sound.State.LoopChannels[0].LeftVolume := 100;
  FRig.Sound.State.LoopChannels[0].Doppler := True;
  FRig.Sound.State.LoopChannels[0].DopplerScale := Single(Infinity);
  FRig.Sound.State.LoopChannels[0].OldDopplerScale := 1.0;
  FRig.Sound.State.NumLoopChannels := 1;
  FRig.Sound.Mixer.PaintChannels(4);
  // 256 * ($80000000 - 0) wraps to 0 in the C: a division by zero, a NaN that is converted
  // to $80000000 and then clamped to -32768 (both channels)
  Assert.AreEqual(-32768, Integer(FRig.DeviceSample(0)));
  Assert.AreEqual(-32768, Integer(FRig.DeviceSample(1)));
  Assert.AreEqual(-32768, Integer(FRig.DeviceSample(2)));
  Assert.AreEqual(-32768, Integer(FRig.DeviceSample(7)));
end;

procedure TTestQ3Mixer.DovrebbeLeggereUnCicloDopplerOltreLaFineSenzaUscire;
var
  LHandle: Integer;
begin
  UseRig(2, 8192, 16);
  LHandle := FRig.AddConstant('a', 1000, 1100);
  FRig.Sound.State.LoopChannels[0].Sfx := FRig.Sound.Registry.SfxOf(LHandle);
  FRig.Sound.State.LoopChannels[0].LeftVolume := 100;
  FRig.Sound.State.LoopChannels[0].Doppler := True;
  FRig.Sound.State.LoopChannels[0].DopplerScale := 3.0;
  FRig.Sound.State.LoopChannels[0].OldDopplerScale := 1.0;
  FRig.Sound.State.NumLoopChannels := 1;
  // 1100 samples at 3 per output: the read goes through the padding of the last chunk
  // (zeros) and wraps, as the C does when it meets the end of the chain
  FRig.Sound.Mixer.PaintChannels(1100);
  Assert.AreEqual(1100, FRig.Sound.State.PaintedTime);
  Assert.AreNotEqual(0, Integer(FRig.DeviceSample(0)));
end;

procedure TTestQ3Mixer.DovrebbeSaltareLaTrasferimentoSenzaBufferDelDispositivo;
var
  LHandle: Integer;
begin
  UseRig(2, 8192, 16);
  LHandle := FRig.AddConstant('a', 1000, 3000);
  StartedChannel(LHandle, 127, 127);
  SetLength(FRig.Device.Buffer, 0);
  FRig.Sound.Mixer.PaintChannels(100);
  Assert.AreEqual(100, FRig.Sound.State.PaintedTime);
  Assert.AreEqual(126503, FRig.Sound.Mixer.PaintBufferAt(0).Left);
end;

// a loop channel of the state with a constant sound, for the cases that need a given doppler
function SetUpDopplerLoop(ARig: TQ3TestRig; ALength: Integer; AScale, AOldScale: Single): Integer;
begin
  Result := ARig.AddConstant('d', 1000, ALength);
  ARig.Sound.State.LoopChannels[0].Sfx := ARig.Sound.Registry.SfxOf(Result);
  ARig.Sound.State.LoopChannels[0].LeftVolume := 100;
  ARig.Sound.State.LoopChannels[0].Doppler := True;
  ARig.Sound.State.LoopChannels[0].DopplerScale := AScale;
  ARig.Sound.State.LoopChannels[0].OldDopplerScale := AOldScale;
  ARig.Sound.State.NumLoopChannels := 1;
end;

procedure TTestQ3Mixer.DovrebbeTagliareLaSommaNelCasoGenerale;
var
  LPositive, LNegative: Integer;
begin
  UseRig(1, 4096, 16);
  LPositive := FRig.AddConstant('p', 32767, 3000);
  LNegative := FRig.AddConstant('n', -32768, 3000);
  StartedChannel(LPositive, 255, 0);
  StartedChannel(LPositive, 255, 0);
  FRig.Sound.Mixer.PaintChannels(10);
  Assert.AreEqual(32767, Integer(FRig.DeviceSample(0)));
  FRig.Sound.Pool.Reset;
  FRig.Sound.State.PaintedTime := 0;
  StartedChannel(LNegative, 255, 0);
  StartedChannel(LNegative, 255, 0);
  FRig.Sound.Mixer.PaintChannels(10);
  Assert.AreEqual(-32768, Integer(FRig.DeviceSample(0)));
end;

procedure TTestQ3Mixer.DovrebbeUsareSoloLaParteDelFlussoCheServe;
begin
  UseRig(2, 8192, 16);
  FRig.Sound.Raw.RawSamples(TArray<SmallInt>.Create(1000, 2000, 3000, 4000, 5000, 6000, 7000,
    8000), 22050, 2, 1.0);
  // four pairs of the stream, only two are mixed
  FRig.Sound.Mixer.PaintChannels(2);
  Assert.AreEqual(1000, Integer(FRig.DeviceSample(0)));
  Assert.AreEqual(4000, Integer(FRig.DeviceSample(3)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(4)));
end;

procedure TTestQ3Mixer.DovrebbeGirareAllaFineDellaCatenaDiBlocchi;
begin
  UseRig(2, 8192, 16);
  SetUpDopplerLoop(FRig, 3000, 1.0, 1.5);
  // the offset 2040 becomes 3060 with the old scale: 12 samples before the end of the
  // last chunk (3072), then the chain wraps to the first sample
  FRig.Sound.State.PaintedTime := 2040;
  FRig.Sound.Mixer.PaintChannels(2140);
  Assert.AreEqual(2140, FRig.Sound.State.PaintedTime);
  Assert.AreEqual(Expected(1000, 100, 255), Integer(FRig.DeviceSample(2 * 2139)));
end;

procedure TTestQ3Mixer.DovrebbeSaltareBlocchiOltreLaFineConLaVecchiaScala;
begin
  UseRig(2, 8192, 16);
  SetUpDopplerLoop(FRig, 3000, 1.0, 1.5);
  // 2100 * 1.5 = 3150 is beyond the three chunks: the walk goes back to the first one
  FRig.Sound.State.PaintedTime := 2100;
  FRig.Sound.Mixer.PaintChannels(2110);
  Assert.AreEqual(Expected(1000, 100, 255), Integer(FRig.DeviceSample(2 * 2100)));
end;

procedure TTestQ3Mixer.DovrebbeTroncareIlVolumeGenerale;
begin
  UseRig(2, 8192, 16);
  FRig.Sound.State.Volume := 0.8;
  FRig.Sound.Mixer.PaintChannels(1);
  Assert.AreEqual(204, FRig.Sound.Mixer.SoundVolume);
  FRig.Sound.State.Volume := 0.3;
  FRig.Sound.Mixer.PaintChannels(2);
  Assert.AreEqual(76, FRig.Sound.Mixer.SoundVolume);
end;

end.
