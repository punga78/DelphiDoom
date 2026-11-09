{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedMusic and TGreedSoundVolumes                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Music;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Sound.Intf,
  DelphiDoom.Greed.Music, DelphiDoom.Tests.Greed.SoundFakes;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedMusic = class(TObject)
  private
    FDevice: TFakeSoundDevice;
    FDeviceIntf: IGreedSoundDevice;
    FFiles: IGreedExternalFiles;
    FVolumes: IGreedSoundVolumes;
    FTics: TFakeTics;
    FTicsIntf: IGreedTics;
    FMusic: TGreedMusic;
    FMusicIntf: IGreedMusic;
    procedure CreateMusic(ANetGame: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSuonareIlModuloTrovatoPerNome;
    [Test]
    procedure DovrebbeIgnorareUnPercorsoEUsareIlNomeDelFile;
    [Test]
    procedure DovrebbeRestareMutoSeIlFileNonCe;
    [Test]
    procedure DovrebbeFermareIlBranoPrimaDiUnoNuovo;
    [Test]
    procedure DovrebbeFareLaDissolvenzaDiTreInTreAUnTicAlPasso;
    [Test]
    procedure DovrebbeRipristinareIlVolumeDopoLaDissolvenza;
    [Test]
    procedure DovrebbeFermareSenzaDissolvenzaInRete;
    [Test]
    procedure DovrebbeNonFareNienteSenzaBrano;
    [Test]
    procedure DovrebbePortareIlVolumeImpostatoAlBrano;
    [Test]
    procedure DovrebbeLimitareIVolumiA255;
    [Test]
    procedure DovrebbePartireConIVolumiDiDefault;
  end;

implementation

uses
  DelphiDoom.Greed.SoundVolumes;

{ TTestGreedMusic }

procedure TTestGreedMusic.Setup;
var
  LFiles: TFakeFiles;
begin
  FDevice := TFakeSoundDevice.Create;
  FDeviceIntf := FDevice;
  LFiles := TFakeFiles.Create;
  FFiles := LFiles;
  LFiles.Files.Add('SONG0.S3M', [1, 2, 3]);
  FVolumes := TGreedSoundVolumes.Create;
  FTics := TFakeTics.Create;
  FTicsIntf := FTics;
  CreateMusic(False);
end;

procedure TTestGreedMusic.TearDown;
begin
  FMusicIntf := nil;
  FMusic := nil;
  FTicsIntf := nil;
  FVolumes := nil;
  FFiles := nil;
  FDeviceIntf := nil;
end;

procedure TTestGreedMusic.CreateMusic(ANetGame: Boolean);
begin
  FMusicIntf := nil;
  FMusic := TGreedMusic.Create(FDeviceIntf, FFiles, FVolumes, FTicsIntf, ANetGame);
  FMusicIntf := FMusic;
end;

procedure TTestGreedMusic.DovrebbeSuonareIlModuloTrovatoPerNome;
begin
  FMusicIntf.Play('SONG0.S3M', 20);
  Assert.AreEqual(1, FDevice.MusicModules.Count);
  Assert.AreEqual<Integer>(3, Length(FDevice.MusicModules[0]));
  Assert.AreEqual(Single(100 / 255), FDevice.Music.Volumes[0]);
end;

procedure TTestGreedMusic.DovrebbeIgnorareUnPercorsoEUsareIlNomeDelFile;
begin
  FMusicIntf.Play('C:\GREED\MUSIC\SONG0.S3M', 0);
  Assert.AreEqual(1, FDevice.MusicModules.Count);
end;

procedure TTestGreedMusic.DovrebbeRestareMutoSeIlFileNonCe;
begin
  FMusicIntf.Play('SONG9.MOD', 0);
  Assert.AreEqual(0, FDevice.MusicModules.Count);
end;

procedure TTestGreedMusic.DovrebbeFermareIlBranoPrimaDiUnoNuovo;
var
  LFirst: TFakeMusicChannel;
begin
  FMusicIntf.Play('SONG0.S3M', 0);
  LFirst := FDevice.Music;
  FMusicIntf.Play('SONG0.S3M', 0);
  Assert.IsTrue(LFirst.Stopped);
  Assert.AreEqual(2, FDevice.MusicModules.Count);
end;

procedure TTestGreedMusic.DovrebbeFareLaDissolvenzaDiTreInTreAUnTicAlPasso;
begin
  FMusicIntf.Play('SONG0.S3M', 0);
  FMusicIntf.Stop;
  // 100, 97, ..., 1: 34 steps, a tic each
  Assert.AreEqual(34, FTics.Waited);
  Assert.AreEqual(Single(100 / 255), FDevice.Music.Volumes[1]);
  Assert.AreEqual(Single(97 / 255), FDevice.Music.Volumes[2]);
  Assert.IsTrue(FDevice.Music.Stopped);
end;

procedure TTestGreedMusic.DovrebbeRipristinareIlVolumeDopoLaDissolvenza;
begin
  FMusicIntf.Play('SONG0.S3M', 0);
  FMusicIntf.Stop;
  Assert.AreEqual(100, FVolumes.MusicVolume);
end;

procedure TTestGreedMusic.DovrebbeFermareSenzaDissolvenzaInRete;
begin
  CreateMusic(True);
  FMusicIntf.Play('SONG0.S3M', 0);
  FMusicIntf.Stop;
  Assert.AreEqual(0, FTics.Waited);
  Assert.IsTrue(FDevice.Music.Stopped);
end;

procedure TTestGreedMusic.DovrebbeNonFareNienteSenzaBrano;
begin
  FMusicIntf.Stop;
  Assert.AreEqual(0, FTics.Waited);
end;

procedure TTestGreedMusic.DovrebbePortareIlVolumeImpostatoAlBrano;
begin
  FMusicIntf.Play('SONG0.S3M', 0);
  FVolumes.SetVolumes(51, 128);
  FMusic.ApplyVolumes;
  Assert.AreEqual(Single(51 / 255), FDevice.Music.Volumes[FDevice.Music.Volumes.Count - 1]);
end;

procedure TTestGreedMusic.DovrebbeLimitareIVolumiA255;
begin
  FVolumes.SetVolumes(300, 1000);
  Assert.AreEqual(255, FVolumes.MusicVolume);
  Assert.AreEqual(255, FVolumes.SfxVolume);
  FVolumes.SetVolumes(-5, 7);
  Assert.AreEqual(-5, FVolumes.MusicVolume);
end;

procedure TTestGreedMusic.DovrebbePartireConIVolumiDiDefault;
begin
  Assert.AreEqual(100, FVolumes.MusicVolume);
  Assert.AreEqual(128, FVolumes.SfxVolume);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedMusic);

end.
