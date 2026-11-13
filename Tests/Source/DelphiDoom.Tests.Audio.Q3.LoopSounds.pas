{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the looping sounds of the Quake III sound              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.LoopSounds;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Audio.Q3.Rig;

type
  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3LoopSounds = class
  strict private
    FRig: TQ3TestRig;
    FSfx: Integer;
    FOther: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAttivareUnSuonoInCicloEFermarlo;
    [Test]
    procedure DovrebbeLasciareIlCicloRealeFinoAllaFermata;
    [Test]
    procedure DovrebbeToglierePerPrimiIGiriAggiuntiDaIlFrame;
    [Test]
    procedure DovrebbeToglierliTuttiSeSiChiedeDiUccidere;
    [Test]
    procedure DovrebbeFermareUnCicloConIlSuonoDiLunghezzaZero;
    [Test]
    procedure DovrebbeRifiutareUnSuonoDiLunghezzaZero;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiEntitaFuoriIntervallo;
    [Test]
    procedure DovrebbeMemorizzareLaPosizioneDellEntita;
    [Test]
    procedure DovrebbeSpazializzareIlCicloTridimensionaleA127EQuelloRealeA90;
    [Test]
    procedure DovrebbeSommareICicliDelloStessoSuonoFinoA255;
    [Test]
    procedure DovrebbeSommareICicliADestraFinoA255;
    [Test]
    procedure DovrebbeTenereCanaliDiversiPerSuoniDiversi;
    [Test]
    procedure DovrebbeSaltareUnCicloNonUdibile;
    [Test]
    procedure DovrebbeCalcolareLaScalaDelDoppler;
    [Test]
    procedure DovrebbeNonUsareIlDopplerSeLaScalaNonSuperaUno;
    [Test]
    procedure DovrebbeConservareLaScalaInfinitaDiUnSuonoNelListener;
    [Test]
    procedure DovrebbeTenereAUnoLaVecchiaScalaDelDoppler;
    [Test]
    procedure DovrebbeNonUnireUnSuonoDopplerAgliAltri;
    [Test]
    procedure DovrebbeAzzerareTuttoNelReset;
  end;

implementation

uses
  System.Math, DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Sfx;

{ TTestQ3LoopSounds }

procedure TTestQ3LoopSounds.Setup;
begin
  FRig := TQ3TestRig.Create;
  FSfx := FRig.AddConstant('loop1', 1000, 3000);
  FOther := FRig.AddConstant('loop2', -1000, 3000);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
end;

procedure TTestQ3LoopSounds.TearDown;
begin
  FRig.Free;
end;

procedure TTestQ3LoopSounds.DovrebbeAttivareUnSuonoInCicloEFermarlo;
begin
  FRig.Sound.AddLoopingSound(5, Vec3(0, 100, 0), Vec3(0, 0, 0), FSfx);
  Assert.IsTrue(FRig.Sound.Loops.LoopOf(5).Active);
  Assert.IsTrue(FRig.Sound.Loops.LoopOf(5).Kill);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Doppler);
  FRig.Sound.StopLoopingSound(5);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Active);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Kill);
end;

procedure TTestQ3LoopSounds.DovrebbeLasciareIlCicloRealeFinoAllaFermata;
begin
  FRig.Sound.AddRealLoopingSound(5, Vec3(0, 100, 0), Vec3(0, 0, 0), FSfx);
  Assert.IsTrue(FRig.Sound.Loops.LoopOf(5).Active);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Kill);
  FRig.Sound.ClearLoopingSounds(False);
  Assert.IsTrue(FRig.Sound.Loops.LoopOf(5).Active);
  FRig.Sound.StopLoopingSound(5);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Active);
end;

procedure TTestQ3LoopSounds.DovrebbeToglierePerPrimiIGiriAggiuntiDaIlFrame;
begin
  FRig.Sound.AddLoopingSound(5, Vec3(0, 100, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.AddRealLoopingSound(6, Vec3(0, 100, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.ClearLoopingSounds(False);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Active);
  Assert.IsTrue(FRig.Sound.Loops.LoopOf(6).Active);
  Assert.AreEqual(0, FRig.Sound.State.NumLoopChannels);
end;

procedure TTestQ3LoopSounds.DovrebbeToglierliTuttiSeSiChiedeDiUccidere;
begin
  FRig.Sound.AddRealLoopingSound(6, Vec3(0, 100, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.ClearLoopingSounds(True);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(6).Active);
end;

procedure TTestQ3LoopSounds.DovrebbeFermareUnCicloConIlSuonoDiLunghezzaZero;
var
  LEmpty: Integer;
begin
  FRig.Sound.AddRealLoopingSound(6, Vec3(0, 100, 0), Vec3(0, 0, 0), FSfx);
  LEmpty := FRig.AddSound('empty', []);
  // the sound lost its samples (the registry reloaded it): the loop is stopped
  FRig.Sound.Registry.SfxOf(FSfx).SetSamples(nil, 0);
  FRig.Sound.ClearLoopingSounds(False);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(6).Active);
  Assert.AreEqual(2, LEmpty);
end;

procedure TTestQ3LoopSounds.DovrebbeRifiutareUnSuonoDiLunghezzaZero;
var
  LEmpty: Integer;
begin
  LEmpty := FRig.AddSound('empty', []);
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.AddLoopingSound(1, Vec3(0, 0, 0), Vec3(0, 0, 0), LEmpty);
    end, EQ3SoundException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.AddRealLoopingSound(1, Vec3(0, 0, 0), Vec3(0, 0, 0), LEmpty);
    end, EQ3SoundException);
end;

procedure TTestQ3LoopSounds.DovrebbeRifiutareUnNumeroDiEntitaFuoriIntervallo;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.AddLoopingSound(1024, Vec3(0, 0, 0), Vec3(0, 0, 0), FSfx);
    end, EQ3SoundException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.AddRealLoopingSound(-1, Vec3(0, 0, 0), Vec3(0, 0, 0), FSfx);
    end, EQ3SoundException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.StopLoopingSound(1024);
    end, EQ3SoundException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.UpdateEntityPosition(1024, Vec3(0, 0, 0));
    end, EQ3SoundException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.Loops.OriginOf(-1);
    end, EQ3SoundException);
  Assert.WillRaise(
    procedure
    begin
      FRig.Sound.Loops.LoopOf(2000);
    end, EQ3SoundException);
end;

procedure TTestQ3LoopSounds.DovrebbeMemorizzareLaPosizioneDellEntita;
begin
  FRig.Sound.UpdateEntityPosition(9, Vec3(1, 2, 3));
  Assert.AreEqual<Single>(2, FRig.Sound.Loops.OriginOf(9)[1]);
end;

procedure TTestQ3LoopSounds.DovrebbeSpazializzareIlCicloTridimensionaleA127EQuelloRealeA90;
begin
  FRig.Sound.AddLoopingSound(5, Vec3(0, 50, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.AddRealLoopingSound(6, Vec3(0, 50, 0), Vec3(0, 0, 0), FOther);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(2, FRig.Sound.State.NumLoopChannels);
  Assert.AreEqual(127, FRig.Sound.State.LoopChannels[0].LeftVolume);
  Assert.AreEqual(0, FRig.Sound.State.LoopChannels[0].RightVolume);
  Assert.AreEqual(127, FRig.Sound.State.LoopChannels[0].MasterVolume);
  Assert.AreEqual(90, FRig.Sound.State.LoopChannels[1].LeftVolume);
  Assert.AreEqual(0, FRig.Sound.State.LoopChannels[1].RightVolume);
  Assert.AreSame(FRig.Sound.Registry.SfxOf(FSfx), FRig.Sound.State.LoopChannels[0].Sfx);
end;

procedure TTestQ3LoopSounds.DovrebbeSommareICicliDelloStessoSuonoFinoA255;
begin
  FRig.Sound.AddLoopingSound(5, Vec3(0, 50, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.AddLoopingSound(6, Vec3(0, 50, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(1, FRig.Sound.State.NumLoopChannels);
  Assert.AreEqual(254, FRig.Sound.State.LoopChannels[0].LeftVolume);
  FRig.Sound.AddLoopingSound(7, Vec3(0, 50, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(1, FRig.Sound.State.NumLoopChannels);
  Assert.AreEqual(255, FRig.Sound.State.LoopChannels[0].LeftVolume);
  Assert.AreEqual(0, FRig.Sound.State.LoopChannels[0].RightVolume);
end;

procedure TTestQ3LoopSounds.DovrebbeSommareICicliADestraFinoA255;
begin
  FRig.Sound.AddLoopingSound(5, Vec3(0, -50, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.AddLoopingSound(6, Vec3(0, -50, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.AddLoopingSound(7, Vec3(0, -50, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(1, FRig.Sound.State.NumLoopChannels);
  Assert.AreEqual(0, FRig.Sound.State.LoopChannels[0].LeftVolume);
  Assert.AreEqual(255, FRig.Sound.State.LoopChannels[0].RightVolume);
end;

procedure TTestQ3LoopSounds.DovrebbeTenereCanaliDiversiPerSuoniDiversi;
begin
  FRig.Sound.AddLoopingSound(5, Vec3(0, 50, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.AddLoopingSound(6, Vec3(0, 50, 0), Vec3(0, 0, 0), FOther);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(2, FRig.Sound.State.NumLoopChannels);
end;

procedure TTestQ3LoopSounds.DovrebbeSaltareUnCicloNonUdibile;
begin
  FRig.Sound.AddLoopingSound(5, Vec3(0, 5000, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(0, FRig.Sound.State.NumLoopChannels);
end;

procedure TTestQ3LoopSounds.DovrebbeCalcolareLaScalaDelDoppler;
begin
  FRig.Sound.UpdateEntityPosition(0, Vec3(0, 0, 0));
  FRig.Clock.FrameCount := 40;
  // 100 units away and moving at 1000: (1100^2) / (100^2 * 100) = 1.21
  FRig.Sound.AddLoopingSound(5, Vec3(100, 0, 0), Vec3(1000, 0, 0), FSfx);
  Assert.IsTrue(FRig.Sound.Loops.LoopOf(5).Doppler);
  Assert.AreEqual(1.21, Double(FRig.Sound.Loops.LoopOf(5).DopplerScale), 0.0001);
  Assert.AreEqual(40, FRig.Sound.Loops.LoopOf(5).FrameNumber);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(1, FRig.Sound.State.NumLoopChannels);
  Assert.IsTrue(FRig.Sound.State.LoopChannels[0].Doppler);
  Assert.AreEqual(1.21, Double(FRig.Sound.State.LoopChannels[0].DopplerScale), 0.0001);
end;

procedure TTestQ3LoopSounds.DovrebbeNonUsareIlDopplerSeLaScalaNonSuperaUno;
begin
  FRig.Sound.UpdateEntityPosition(0, Vec3(0, 0, 0));
  FRig.Sound.AddLoopingSound(5, Vec3(100, 0, 0), Vec3(10, 0, 0), FSfx);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Doppler);
  // the scale that was computed stays (0.0121)
  Assert.AreEqual(0.0121, Double(FRig.Sound.Loops.LoopOf(5).DopplerScale), 0.00001);
  FRig.Sound.State.Doppler := 0;
  FRig.Sound.AddLoopingSound(6, Vec3(100, 0, 0), Vec3(1000, 0, 0), FSfx);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(6).Doppler);
  Assert.AreEqual<Single>(1, FRig.Sound.Loops.LoopOf(6).DopplerScale);
end;

procedure TTestQ3LoopSounds.DovrebbeConservareLaScalaInfinitaDiUnSuonoNelListener;
begin
  // the C divides by zero: infinity, which is not <= 1, so the sound stays a doppler one
  FRig.Sound.UpdateEntityPosition(0, Vec3(0, 0, 0));
  FRig.Sound.AddLoopingSound(5, Vec3(0, 0, 0), Vec3(0, 0, 0), FSfx);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Doppler);
  FRig.Sound.AddLoopingSound(5, Vec3(0, 0, 0), Vec3(100, 0, 0), FSfx);
  Assert.IsTrue(FRig.Sound.Loops.LoopOf(5).Doppler);
  Assert.IsTrue(IsInfinite(FRig.Sound.Loops.LoopOf(5).DopplerScale));
  // a sound without velocity does not enter the branch: the flag is reset
  FRig.Sound.AddLoopingSound(5, Vec3(0, 0, 0), Vec3(0, 0, 0), FSfx);
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Doppler);
end;

procedure TTestQ3LoopSounds.DovrebbeTenereAUnoLaVecchiaScalaDelDoppler;
begin
  FRig.Sound.UpdateEntityPosition(0, Vec3(0, 0, 0));
  FRig.Clock.FrameCount := 10;
  FRig.Sound.AddLoopingSound(5, Vec3(100, 0, 0), Vec3(1000, 0, 0), FSfx);
  FRig.Clock.FrameCount := 11;
  FRig.Sound.AddLoopingSound(5, Vec3(100, 0, 0), Vec3(1000, 0, 0), FSfx);
  // the C resets dopplerScale to 1 just before it reads it as the old one
  Assert.AreEqual<Single>(1, FRig.Sound.Loops.LoopOf(5).OldDopplerScale);
end;

procedure TTestQ3LoopSounds.DovrebbeNonUnireUnSuonoDopplerAgliAltri;
begin
  FRig.Sound.UpdateEntityPosition(0, Vec3(0, 0, 0));
  FRig.Sound.AddLoopingSound(5, Vec3(0, 50, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.AddLoopingSound(6, Vec3(0, 100, 0), Vec3(0, 5000, 0), FSfx);
  Assert.IsTrue(FRig.Sound.Loops.LoopOf(6).Doppler);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  Assert.AreEqual(2, FRig.Sound.State.NumLoopChannels);
  Assert.IsFalse(FRig.Sound.State.LoopChannels[0].Doppler);
  Assert.IsTrue(FRig.Sound.State.LoopChannels[1].Doppler);
end;

procedure TTestQ3LoopSounds.DovrebbeAzzerareTuttoNelReset;
begin
  FRig.Sound.AddLoopingSound(5, Vec3(0, 50, 0), Vec3(0, 0, 0), FSfx);
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
  FRig.Sound.ClearSoundBuffer;
  Assert.IsFalse(FRig.Sound.Loops.LoopOf(5).Active);
  Assert.AreEqual(0, FRig.Sound.State.NumLoopChannels);
end;

end.
