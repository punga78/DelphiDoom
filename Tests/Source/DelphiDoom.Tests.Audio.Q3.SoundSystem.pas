{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III sound system (snd_dma.c entry points),   }
{  of the registry of sounds and of the scheduler of the mix                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.SoundSystem;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Audio.Q3.Rig;

type
  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3SoundSystem = class
  strict private
    FRig: TQ3TestRig;
    procedure UseRig(AChannels, ASamples, ABits, ASpeed, AChunk: Integer;
      AWithReader: Boolean = False);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeIgnorareISuoniDaMutoEAttivarsiConLaRegistrazione;
    [Test]
    procedure DovrebbeFermarsiConLaChiusura;
    [Test]
    procedure DovrebbeIgnorareUnaManigliaFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnaEntitaFuoriIntervalloSenzaOrigine;
    [Test]
    procedure DovrebbeSpazializzareUnSuonoConOrigineFissa;
    [Test]
    procedure DovrebbeDareIlVolumePienoAiSuoniDelListener;
    [Test]
    procedure DovrebbeSeguireLaPosizioneDellEntita;
    [Test]
    procedure DovrebbeFarSuonareUnSuonoLocaleSulListener;
    [Test]
    procedure DovrebbeSvuotareIlBufferDelDispositivo;
    [Test]
    procedure DovrebbeScrivereIlSilenzioDegliOttoBitA128;
    [Test]
    procedure DovrebbeFermareTuttoEMutare;
    [Test]
    procedure DovrebbeIgnorareLeManigliePerICicliFuoriIntervallo;
    [Test]
    procedure DovrebbeCaricareUnSuonoAllaPrimaPartenza;
    [Test]
    procedure DovrebbeCostruireUnSistemaSenzaLettoreDiFile;
    [Test]
    procedure DovrebbeCaricareUnSuonoAllaPrimaAggiuntaDiUnCiclo;
  end;

  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3Sfx = class
  public
    [Test]
    procedure DovrebbeCompletareICampioniAUnNumeroIntero;
    [Test]
    procedure DovrebbeLimitareLaLunghezzaAiCampioniDati;
    [Test]
    procedure DovrebbeTenereIlNomeEIlTempoDiUso;
  end;

  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3SfxRegistry = class
  strict private
    FRig: TQ3TestRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLaManigliaDellaPosizioneNellaTabella;
    [Test]
    procedure DovrebbeTrovareLoStessoSuonoSenzaDistinguereMaiuscole;
    [Test]
    procedure DovrebbeLeggereUnFileUnaSolaVolta;
    [Test]
    procedure DovrebbeRiprovareUnSuonoSenzaCampioni;
    [Test]
    procedure DovrebbeDareZeroPerUnSuonoMancante;
    [Test]
    procedure DovrebbeDareZeroPerUnSuonoDelGiocatore;
    [Test]
    procedure DovrebbeDareZeroPerUnNomeTroppoLungo;
    [Test]
    procedure DovrebbeRifiutareUnNomeVuoto;
    [Test]
    procedure DovrebbeRifiutareUnNomeTroppoLungoPerLaTabella;
    [Test]
    procedure DovrebbeRifiutareTroppiSuoni;
    [Test]
    procedure DovrebbeDareZeroSeIlSuonoNonEAttivo;
    [Test]
    procedure DovrebbeDareNilPerUnaManigliaFuoriIntervallo;
    [Test]
    procedure DovrebbeSegnareDefaultUnSuonoCheNonSiLegge;
  end;

  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3Scheduler = class
  strict private
    FRig: TQ3TestRig;
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMescolareAvantiNelLimiteDelBuffer;
    [Test]
    procedure DovrebbeNonMescolareSeIlTempoNonCambia;
    [Test]
    procedure DovrebbeContareIGiriDelBufferDelDispositivo;
    [Test]
    procedure DovrebbeTagliareIlTempoTroppoGrandeEFermareTutto;
    [Test]
    procedure DovrebbeAnticiparePerUnPassoPiccoloDiInvio;
    [Test]
    procedure DovrebbeNonMescolareSeMutoOSeFermato;
    [Test]
    procedure DovrebbeIniziareEFinireISuoniMescolando;
    [Test]
    procedure DovrebbeUsareLAnticipoPiuBreveTraPassoEOrologio;
  end;

implementation

uses
  DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Sfx, DelphiDoom.Audio.Q3.Factory,
  DelphiDoom.Tests.Audio.Q3.Fakes;

{ TTestQ3SoundSystem }

procedure TTestQ3SoundSystem.UseRig(AChannels, ASamples, ABits, ASpeed, AChunk: Integer;
  AWithReader: Boolean);
begin
  FRig.Free;
  FRig := TQ3TestRig.Create(AChannels, ASamples, ABits, ASpeed, AChunk, AWithReader);
end;

procedure TTestQ3SoundSystem.Setup;
begin
  FRig := TQ3TestRig.Create;
end;

procedure TTestQ3SoundSystem.TearDown;
begin
  FreeAndNil(FRig);
end;

procedure TTestQ3SoundSystem.DovrebbeIgnorareISuoniDaMutoEAttivarsiConLaRegistrazione;
var
  LHandle: Integer;
begin
  FRig.Free;
  FRig := TQ3TestRig.Create;
  LHandle := FRig.AddConstant('a', 1000, 500);
  FRig.Sound.DisableSounds;
  Assert.IsTrue(FRig.Sound.State.SoundMuted);
  FRig.Sound.StartSound(nil, 3, Q3_CHAN_AUTO, LHandle);
  Assert.IsNull(FRig.Sound.State.Channels[95].Sfx);
  FRig.Sound.BeginRegistration;
  FRig.Sound.StartSound(nil, 3, Q3_CHAN_AUTO, LHandle);
  Assert.IsNotNull(FRig.Sound.State.Channels[95].Sfx);
end;

procedure TTestQ3SoundSystem.DovrebbeFermarsiConLaChiusura;
begin
  Assert.IsTrue(FRig.Sound.State.SoundStarted);
  FRig.Sound.Shutdown;
  Assert.IsFalse(FRig.Sound.State.SoundStarted);
  Assert.AreEqual(0, FRig.Sound.RegisterSound('sound/x.wav'));
  // nothing happens on a system that is not started
  FRig.Sound.ClearSoundBuffer;
  FRig.Sound.StopAllSounds;
  FRig.Sound.Update;
end;

procedure TTestQ3SoundSystem.DovrebbeIgnorareUnaManigliaFuoriIntervallo;
begin
  FRig.AddConstant('a', 1000, 500);
  FRig.Sound.StartSound(nil, 3, Q3_CHAN_AUTO, 7);
  FRig.Sound.StartSound(nil, 3, Q3_CHAN_AUTO, -1);
  FRig.Sound.StartLocalSound(9, Q3_CHAN_LOCAL);
  Assert.IsNull(FRig.Sound.State.Channels[95].Sfx);
end;

procedure TTestQ3SoundSystem.DovrebbeRifiutareUnaEntitaFuoriIntervalloSenzaOrigine;
var
  LHandle: Integer;
  LOrigin: TQ3Vec3;
begin
  LHandle := FRig.AddConstant('a', 1000, 500);
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.StartSound(nil, 1024, Q3_CHAN_AUTO, LHandle);
    end, EQ3SoundException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.StartSound(nil, -1, Q3_CHAN_AUTO, LHandle);
    end, EQ3SoundException);
  // with an origin the entity is only a name
  LOrigin := Vec3(0, 0, 0);
  FRig.Sound.StartSound(@LOrigin, 5000, Q3_CHAN_AUTO, LHandle);
  Assert.AreEqual(5000, FRig.Sound.State.Channels[95].EntityNumber);
end;

procedure TTestQ3SoundSystem.DovrebbeSpazializzareUnSuonoConOrigineFissa;
var
  LHandle: Integer;
  LOrigin: TQ3Vec3;
begin
  LHandle := FRig.AddConstant('a', 1000, 500);
  LOrigin := Vec3(0, 100, 0);
  FRig.Sound.StartSound(@LOrigin, 4, Q3_CHAN_AUTO, LHandle);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(124, FRig.Sound.State.Channels[95].LeftVolume);
  Assert.AreEqual(0, FRig.Sound.State.Channels[95].RightVolume);
  FRig.Sound.Respatialize(0, Vec3(0, 200, 0), IdentityAxis, 0);
  // the listener moved 200 to the left: the sound is now 100 units to its right
  Assert.AreEqual(0, FRig.Sound.State.Channels[95].LeftVolume);
  Assert.AreEqual(124, FRig.Sound.State.Channels[95].RightVolume);
end;

procedure TTestQ3SoundSystem.DovrebbeDareIlVolumePienoAiSuoniDelListener;
var
  LHandle: Integer;
begin
  LHandle := FRig.AddConstant('a', 1000, 500);
  FRig.Sound.StartSound(nil, 0, Q3_CHAN_LOCAL, LHandle);
  FRig.Sound.State.Channels[95].LeftVolume := 3;
  FRig.Sound.Respatialize(0, Vec3(0, 900, 0), IdentityAxis, 0);
  Assert.AreEqual(127, FRig.Sound.State.Channels[95].LeftVolume);
  Assert.AreEqual(127, FRig.Sound.State.Channels[95].RightVolume);
  Assert.AreEqual(0, FRig.Sound.Listener.Number);
end;

procedure TTestQ3SoundSystem.DovrebbeSeguireLaPosizioneDellEntita;
var
  LHandle: Integer;
begin
  LHandle := FRig.AddConstant('a', 1000, 500);
  FRig.Sound.StartSound(nil, 4, Q3_CHAN_AUTO, LHandle);
  FRig.Sound.UpdateEntityPosition(4, Vec3(0, -100, 0));
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(0, FRig.Sound.State.Channels[95].LeftVolume);
  Assert.AreEqual(124, FRig.Sound.State.Channels[95].RightVolume);
  FRig.Sound.UpdateEntityPosition(4, Vec3(0, 100, 0));
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(124, FRig.Sound.State.Channels[95].LeftVolume);
end;

procedure TTestQ3SoundSystem.DovrebbeFarSuonareUnSuonoLocaleSulListener;
var
  LHandle: Integer;
begin
  LHandle := FRig.AddConstant('a', 1000, 500);
  FRig.Sound.Respatialize(6, Vec3(0, 0, 0), IdentityAxis, 0);
  FRig.Sound.StartLocalSound(LHandle, Q3_CHAN_LOCAL_SOUND);
  Assert.AreEqual(6, FRig.Sound.State.Channels[95].EntityNumber);
  Assert.AreEqual(Q3_CHAN_LOCAL_SOUND, FRig.Sound.State.Channels[95].EntityChannel);
end;

procedure TTestQ3SoundSystem.DovrebbeSvuotareIlBufferDelDispositivo;
var
  LHandle, LCount: Integer;
begin
  LHandle := FRig.AddConstant('a', 1000, 500);
  FRig.Sound.StartSound(nil, 4, Q3_CHAN_AUTO, LHandle);
  FRig.Sound.AddRealLoopingSound(5, Vec3(0, 10, 0), Vec3(0, 0, 0), LHandle);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  FRig.Sound.RawSamples(1, 22050, 2, 1, PByte(TBytes.Create(1, 0)), 1.0);
  FRig.Device.Buffer[10] := 77;
  LCount := FRig.Device.BeginCount;
  FRig.Sound.ClearSoundBuffer;
  Assert.AreEqual(0, Integer(FRig.Device.Buffer[10]));
  Assert.IsNull(FRig.Sound.State.Channels[95].Sfx);
  Assert.AreEqual(0, FRig.Sound.State.NumLoopChannels);
  Assert.AreEqual(0, FRig.Sound.State.RawEnd);
  Assert.AreEqual(LCount + 1, FRig.Device.BeginCount);
  Assert.AreEqual(FRig.Device.BeginCount, FRig.Device.SubmitCount);
end;

procedure TTestQ3SoundSystem.DovrebbeScrivereIlSilenzioDegliOttoBitA128;
begin
  UseRig(2, 4096, 8, 22050, 1024);
  FRig.Device.Buffer[5] := 9;
  FRig.Sound.ClearSoundBuffer;
  Assert.AreEqual(128, Integer(FRig.Device.Buffer[5]));
  Assert.AreEqual(128, Integer(FRig.Device.Buffer[4095]));
  // the buffer is 4096 samples of 8 bits
  Assert.AreEqual(0, Integer(FRig.Device.Buffer[4096]));
end;

procedure TTestQ3SoundSystem.DovrebbeFermareTuttoEMutare;
var
  LHandle: Integer;
begin
  LHandle := FRig.AddConstant('a', 1000, 500);
  FRig.Sound.StartSound(nil, 4, Q3_CHAN_AUTO, LHandle);
  FRig.Sound.DisableSounds;
  Assert.IsNull(FRig.Sound.State.Channels[95].Sfx);
  Assert.IsTrue(FRig.Sound.State.SoundMuted);
  // the loop calls do nothing while muted
  FRig.Sound.AddLoopingSound(5, Vec3(0, 0, 0), Vec3(0, 0, 0), LHandle);
  FRig.Sound.AddRealLoopingSound(5, Vec3(0, 0, 0), Vec3(0, 0, 0), LHandle);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Active);
  FRig.Sound.Respatialize(3, Vec3(1, 2, 3), IdentityAxis, 0);
  Assert.AreEqual(0, FRig.Sound.Listener.Number);
end;

procedure TTestQ3SoundSystem.DovrebbeIgnorareLeManigliePerICicliFuoriIntervallo;
begin
  FRig.AddConstant('a', 1000, 500);
  FRig.Sound.AddLoopingSound(5, Vec3(0, 0, 0), Vec3(0, 0, 0), 9);
  FRig.Sound.AddRealLoopingSound(5, Vec3(0, 0, 0), Vec3(0, 0, 0), -1);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Active);
end;

procedure TTestQ3SoundSystem.DovrebbeCaricareUnSuonoAllaPrimaPartenza;
var
  LHandle: Integer;
  LSfx: TQ3Sfx;
begin
  UseRig(2, 8192, 16, 22050, 1024, True);
  FRig.Files.Files.Add('sound/late.wav', TQ3TestWav.Mono16(22050, [100, 200, 300]));
  FRig.Sound.Registry.RegisterSound('sound/hit.wav');
  LHandle := FRig.Sound.Registry.RegisterSound('sound/late.wav');
  Assert.AreEqual(1, LHandle);
  LSfx := FRig.Sound.Registry.SfxOf(LHandle);
  LSfx.InMemory := False;
  LSfx.SetSamples(nil, 0);
  FRig.Sound.StartSound(nil, 4, Q3_CHAN_AUTO, LHandle);
  Assert.IsTrue(LSfx.InMemory);
  Assert.AreEqual(3, LSfx.SoundLength);
  Assert.IsNotNull(FRig.Sound.State.Channels[95].Sfx);
  FRig.Sound.AddLoopingSound(5, Vec3(0, 0, 0), Vec3(0, 0, 0), LHandle);
  Assert.IsTrue(FRig.Sound.Loops.LoopOf(5).Active);
end;

procedure TTestQ3SoundSystem.DovrebbeCostruireUnSistemaSenzaLettoreDiFile;
var
  LRig: TQ3TestRig;
begin
  LRig := TQ3TestRig.Create;
  try
    LRig.Files.Files.Add('sound/a.wav', TQ3TestWav.Mono16(22050, [1, 2, 3]));
    // no reader: the file is not read and the sound stays the default one
    Assert.AreEqual(0, LRig.Sound.RegisterSound('sound/a.wav'));
    Assert.IsTrue(LRig.Sound.Registry.SfxOf(0).DefaultSound);
  finally
    LRig.Free;
  end;
end;

{ TTestQ3SfxRegistry }

procedure TTestQ3SfxRegistry.Setup;
begin
  FRig := TQ3TestRig.Create(2, 8192, 16, 22050, 1024, True);
end;

procedure TTestQ3SfxRegistry.TearDown;
begin
  FRig.Free;
end;

procedure TTestQ3SfxRegistry.DovrebbeDareLaManigliaDellaPosizioneNellaTabella;
begin
  FRig.Files.Files.Add('sound/a.wav', TQ3TestWav.Mono16(22050, [1, 2, 3]));
  FRig.Files.Files.Add('sound/b.wav', TQ3TestWav.Mono16(11025, [1, 2]));
  // the first sound of the table has handle 0, the same value of "not loaded"
  Assert.AreEqual(0, FRig.Sound.RegisterSound('sound/a.wav'));
  Assert.AreEqual(1, FRig.Sound.RegisterSound('sound/b.wav'));
  Assert.AreEqual(2, FRig.Sound.Registry.Count);
  Assert.AreEqual(3, FRig.Sound.Registry.SfxOf(0).SoundLength);
  Assert.AreEqual(4, FRig.Sound.Registry.SfxOf(1).SoundLength);
  Assert.IsTrue(FRig.Sound.Registry.SfxOf(1).InMemory);
  Assert.IsFalse(FRig.Sound.Registry.SfxOf(1).DefaultSound);
end;

procedure TTestQ3SfxRegistry.DovrebbeTrovareLoStessoSuonoSenzaDistinguereMaiuscole;
begin
  FRig.Files.Files.Add('sound/a.wav', TQ3TestWav.Mono16(22050, [1, 2, 3]));
  FRig.Files.Files.Add('Sound/B.wav', TQ3TestWav.Mono16(22050, [1, 2, 3]));
  FRig.Sound.RegisterSound('sound/a.wav');
  Assert.AreEqual(1, FRig.Sound.RegisterSound('Sound/B.wav'));
  Assert.AreEqual(1, FRig.Sound.RegisterSound('SOUND/b.WAV'));
  Assert.AreEqual(2, FRig.Sound.Registry.Count);
end;

procedure TTestQ3SfxRegistry.DovrebbeLeggereUnFileUnaSolaVolta;
begin
  FRig.Files.Files.Add('sound/a.wav', TQ3TestWav.Mono16(22050, [1, 2, 3]));
  FRig.Files.Files.Add('sound/b.wav', TQ3TestWav.Mono16(22050, [1, 2, 3]));
  FRig.Sound.RegisterSound('sound/a.wav');
  FRig.Sound.RegisterSound('sound/b.wav');
  FRig.Sound.RegisterSound('sound/b.wav');
  Assert.AreEqual(2, FRig.Files.Reads);
end;

procedure TTestQ3SfxRegistry.DovrebbeRiprovareUnSuonoSenzaCampioni;
begin
  // a sound without samples has no data: the C loads it again
  FRig.Files.Files.Add('sound/a.wav', TQ3TestWav.Mono16(22050, []));
  FRig.Files.Files.Add('sound/b.wav', TQ3TestWav.Mono16(22050, [1]));
  FRig.Sound.RegisterSound('sound/b.wav');
  Assert.AreEqual(1, FRig.Sound.RegisterSound('sound/a.wav'));
  Assert.AreEqual(1, FRig.Sound.RegisterSound('sound/a.wav'));
  Assert.AreEqual(3, FRig.Files.Reads);
end;

procedure TTestQ3SfxRegistry.DovrebbeDareZeroPerUnSuonoMancante;
begin
  FRig.Files.Files.Add('sound/a.wav', TQ3TestWav.Mono16(22050, [1, 2, 3]));
  FRig.Sound.RegisterSound('sound/a.wav');
  Assert.AreEqual(0, FRig.Sound.RegisterSound('sound/missing.wav'));
  Assert.IsTrue(FRig.Sound.Registry.SfxOf(1).DefaultSound);
  Assert.AreEqual(0, FRig.Sound.RegisterSound('sound/missing.wav'));
  Assert.AreEqual(2, FRig.Sound.Registry.Count);
end;

procedure TTestQ3SfxRegistry.DovrebbeDareZeroPerUnSuonoDelGiocatore;
begin
  FRig.Files.Files.Add('sound/a.wav', TQ3TestWav.Mono16(22050, [1, 2, 3]));
  FRig.Sound.RegisterSound('sound/a.wav');
  Assert.AreEqual(0, FRig.Sound.RegisterSound('*pain25_1.wav'));
  // a name that begins with * is never read from a file
  Assert.AreEqual(1, FRig.Files.Reads);
end;

procedure TTestQ3SfxRegistry.DovrebbeDareZeroPerUnNomeTroppoLungo;
begin
  Assert.AreEqual(0, FRig.Sound.RegisterSound(StringOfChar('a', 64)));
  Assert.AreEqual(0, FRig.Sound.Registry.Count);
end;

procedure TTestQ3SfxRegistry.DovrebbeRifiutareUnNomeVuoto;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.RegisterSound('');
    end, EQ3SoundException);
end;

procedure TTestQ3SfxRegistry.DovrebbeRifiutareUnNomeTroppoLungoPerLaTabella;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.Registry.AddSound(StringOfChar('b', 70), nil, 0);
    end, EQ3SoundException);
end;

procedure TTestQ3SfxRegistry.DovrebbeRifiutareTroppiSuoni;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 4095 do
    FRig.Sound.Registry.AddSound('s' + LIndex.ToString, nil, 0);
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.Registry.AddSound('one more', nil, 0);
    end, EQ3SoundException);
end;

procedure TTestQ3SfxRegistry.DovrebbeDareZeroSeIlSuonoNonEAttivo;
begin
  FRig.Files.Files.Add('sound/a.wav', TQ3TestWav.Mono16(22050, [1, 2, 3]));
  FRig.Sound.Shutdown;
  Assert.AreEqual(0, FRig.Sound.RegisterSound('sound/a.wav'));
  Assert.AreEqual(0, FRig.Sound.Registry.Count);
end;

procedure TTestQ3SfxRegistry.DovrebbeDareNilPerUnaManigliaFuoriIntervallo;
begin
  Assert.IsNull(FRig.Sound.Registry.SfxOf(0));
  Assert.IsNull(FRig.Sound.Registry.SfxOf(-1));
end;

procedure TTestQ3SfxRegistry.DovrebbeSegnareDefaultUnSuonoCheNonSiLegge;
begin
  FRig.Files.Files.Add('sound/stereo.wav', TQ3TestWav.Build(2, 22050, 16,
    TBytes.Create(1, 0, 2, 0, 3, 0, 4, 0)));
  Assert.AreEqual(0, FRig.Sound.RegisterSound('sound/stereo.wav'));
  Assert.IsTrue(FRig.Sound.Registry.SfxOf(0).DefaultSound);
  Assert.AreEqual(0, FRig.Sound.Registry.SfxOf(0).SoundLength);
end;

procedure TTestQ3SoundSystem.DovrebbeCaricareUnSuonoAllaPrimaAggiuntaDiUnCiclo;
var
  LHandle: Integer;
begin
  UseRig(2, 8192, 16, 22050, 1024, True);
  FRig.Files.Files.Add('sound/loop.wav', TQ3TestWav.Mono16(22050, [100, 200, 300]));
  FRig.Sound.RegisterSound('sound/other.wav');
  LHandle := FRig.Sound.RegisterSound('sound/loop.wav');
  FRig.Sound.Registry.SfxOf(LHandle).InMemory := False;
  FRig.Sound.AddRealLoopingSound(5, Vec3(0, 0, 0), Vec3(0, 0, 0), LHandle);
  Assert.IsTrue(FRig.Sound.Registry.SfxOf(LHandle).InMemory);
  FRig.Sound.Registry.SfxOf(LHandle).InMemory := False;
  FRig.Sound.AddLoopingSound(6, Vec3(0, 0, 0), Vec3(0, 0, 0), LHandle);
  Assert.IsTrue(FRig.Sound.Registry.SfxOf(LHandle).InMemory);
end;

{ TTestQ3Sfx }

procedure TTestQ3Sfx.DovrebbeCompletareICampioniAUnNumeroIntero;
var
  LSfx: TQ3Sfx;
  LSamples: TArray<SmallInt>;
begin
  LSfx := TQ3Sfx.Create('sound/x.wav');
  try
    SetLength(LSamples, 1500);
    LSamples[1499] := 7;
    LSfx.SetSamples(LSamples, 1500);
    Assert.AreEqual(1500, LSfx.SoundLength);
    Assert.AreEqual<Integer>(2048, Length(LSfx.Samples));
    Assert.AreEqual(2, LSfx.ChunkCount);
    Assert.AreEqual(7, Integer(LSfx.Samples[1499]));
    Assert.AreEqual(0, Integer(LSfx.Samples[1500]));
    LSfx.SetSamples(LSamples, 1024);
    Assert.AreEqual<Integer>(1024, Length(LSfx.Samples));
    LSfx.SetSamples(nil, 0);
    Assert.AreEqual(0, LSfx.ChunkCount);
  finally
    LSfx.Free;
  end;
end;

procedure TTestQ3Sfx.DovrebbeLimitareLaLunghezzaAiCampioniDati;
var
  LSfx: TQ3Sfx;
begin
  LSfx := TQ3Sfx.Create('x');
  try
    LSfx.SetSamples(TArray<SmallInt>.Create(1, 2, 3), 10);
    Assert.AreEqual(3, LSfx.SoundLength);
    LSfx.SetSamples(TArray<SmallInt>.Create(1, 2, 3), -4);
    Assert.AreEqual(0, LSfx.SoundLength);
  finally
    LSfx.Free;
  end;
end;

procedure TTestQ3Sfx.DovrebbeTenereIlNomeEIlTempoDiUso;
var
  LSfx: TQ3Sfx;
begin
  LSfx := TQ3Sfx.Create('Sound/A.wav');
  try
    Assert.AreEqual('Sound/A.wav', LSfx.Name);
    Assert.IsFalse(LSfx.InMemory);
    Assert.IsFalse(LSfx.DefaultSound);
    LSfx.LastTimeUsed := 99;
    Assert.AreEqual(99, LSfx.LastTimeUsed);
  finally
    LSfx.Free;
  end;
end;

{ TTestQ3Scheduler }

procedure TTestQ3Scheduler.TearDown;
begin
  FreeAndNil(FRig);
end;

procedure TTestQ3Scheduler.DovrebbeMescolareAvantiNelLimiteDelBuffer;
var
  LBegin: Integer;
begin
  // 22050 Hz, 8192 samples of stereo = 4096 pairs, chunk 1024
  FRig := TQ3TestRig.Create;
  FRig.Clock.Milliseconds := 1000;
  LBegin := FRig.Device.BeginCount;
  FRig.Sound.Update;
  // sound time 0, painted 0 + 1024, mixes up to min(4410 -> 5120, 4096)
  Assert.AreEqual(0, FRig.Sound.State.SoundTime);
  Assert.AreEqual(4096, FRig.Sound.State.PaintedTime);
  Assert.AreEqual(LBegin + 1, FRig.Device.BeginCount);
  Assert.AreEqual(FRig.Device.BeginCount, FRig.Device.SubmitCount);
end;

procedure TTestQ3Scheduler.DovrebbeNonMescolareSeIlTempoNonCambia;
var
  LBegin: Integer;
begin
  FRig := TQ3TestRig.Create;
  FRig.Clock.Milliseconds := 1000;
  FRig.Sound.Update;
  LBegin := FRig.Device.BeginCount;
  FRig.Sound.Update;
  Assert.AreEqual(LBegin, FRig.Device.BeginCount);
  FRig.Device.Position := 200;
  FRig.Sound.Update;
  Assert.AreEqual(LBegin + 1, FRig.Device.BeginCount);
end;

procedure TTestQ3Scheduler.DovrebbeContareIGiriDelBufferDelDispositivo;
begin
  FRig := TQ3TestRig.Create;
  FRig.Device.Position := 5000;
  FRig.Sound.Scheduler.UpdateSoundTime;
  Assert.AreEqual(2500, FRig.Sound.State.SoundTime);
  // the position went back: the buffer wrapped once (4096 pairs)
  FRig.Device.Position := 100;
  FRig.Sound.Scheduler.UpdateSoundTime;
  Assert.AreEqual(4096 + 50, FRig.Sound.State.SoundTime);
  FRig.Device.Position := 8000;
  FRig.Sound.Scheduler.UpdateSoundTime;
  FRig.Device.Position := 10;
  FRig.Sound.Scheduler.UpdateSoundTime;
  Assert.AreEqual(2 * 4096 + 5, FRig.Sound.State.SoundTime);
end;

procedure TTestQ3Scheduler.DovrebbeTagliareIlTempoTroppoGrandeEFermareTutto;
var
  LHandle: Integer;
begin
  FRig := TQ3TestRig.Create;
  LHandle := FRig.AddConstant('a', 1000, 500);
  FRig.Sound.StartSound(nil, 4, Q3_CHAN_AUTO, LHandle);
  FRig.Device.Position := 5000;
  FRig.Sound.Scheduler.UpdateSoundTime;
  FRig.Sound.State.PaintedTime := $40000001;
  FRig.Device.Position := 100;
  FRig.Sound.Scheduler.UpdateSoundTime;
  // the buffers are counted from zero, the sounds stopped, the lead is added again
  Assert.IsNull(FRig.Sound.State.Channels[95].Sfx);
  Assert.AreEqual(50, FRig.Sound.State.SoundTime);
  Assert.AreEqual(50 + 1024, FRig.Sound.State.PaintedTime);
end;

procedure TTestQ3Scheduler.DovrebbeAnticiparePerUnPassoPiccoloDiInvio;
begin
  // a chunk under 256 samples: the lead is s_mixPreStep * speed = 1102 samples
  FRig := TQ3TestRig.Create(2, 8192, 16, 22050, 128);
  FRig.Device.Position := 2000;
  FRig.Sound.Scheduler.UpdateSoundTime;
  Assert.AreEqual(1000, FRig.Sound.State.SoundTime);
  Assert.AreEqual(1000 + 1102, FRig.Sound.State.PaintedTime);
end;

procedure TTestQ3Scheduler.DovrebbeNonMescolareSeMutoOSeFermato;
var
  LBegin: Integer;
begin
  FRig := TQ3TestRig.Create;
  FRig.Sound.DisableSounds;
  LBegin := FRig.Device.BeginCount;
  FRig.Sound.Scheduler.Update;
  Assert.AreEqual(LBegin, FRig.Device.BeginCount);
  FRig.Sound.BeginRegistration;
  FRig.Sound.Shutdown;
  FRig.Sound.Scheduler.Update;
  Assert.AreEqual(LBegin, FRig.Device.BeginCount);
end;

procedure TTestQ3Scheduler.DovrebbeIniziareEFinireISuoniMescolando;
var
  LHandle: Integer;
begin
  FRig := TQ3TestRig.Create;
  FRig.Sound.State.Volume := 1.0;
  LHandle := FRig.AddConstant('a', 1000, 300);
  FRig.Clock.Milliseconds := 1000;
  FRig.Sound.StartSound(nil, 4, Q3_CHAN_AUTO, LHandle);
  FRig.Sound.Update;
  // started at the first painted sample (1024) and played for its 300 samples
  Assert.AreEqual(1024, FRig.Sound.State.Channels[95].StartSample);
  Assert.AreEqual(494, Integer(FRig.DeviceSample(2 * 1024)));
  Assert.AreEqual(494, Integer(FRig.DeviceSample(2 * 1323)));
  Assert.AreEqual(0, Integer(FRig.DeviceSample(2 * 1324)));
  // the next step finds it finished
  FRig.Device.Position := 3000;
  FRig.Clock.Milliseconds := 1020;
  FRig.Sound.Update;
  Assert.IsNull(FRig.Sound.State.Channels[95].Sfx);
end;

procedure TTestQ3Scheduler.DovrebbeUsareLAnticipoPiuBreveTraPassoEOrologio;
begin
  // the second step is 1 ms after the first (sane is raised to 11 ms) and the position moved
  // 100 pairs: the lead 0.05 + 11 * 22050 * 0.01 is shorter than s_mixahead (4410)
  FRig := TQ3TestRig.Create(2, 32768, 16, 22050, 1024);
  FRig.Clock.Milliseconds := 1000;
  FRig.Sound.Update;
  FRig.Device.Position := 200;
  FRig.Clock.Milliseconds := 1001;
  FRig.Sound.Update;
  // sane = 11: 0.05 + 11 * 22050 * 0.01 = 2425.55 < 4410: mixes to 100 + 2425 -> 3072
  Assert.AreEqual(100, FRig.Sound.State.SoundTime);
  Assert.AreEqual(3072, FRig.Sound.State.PaintedTime);
end;

end.
