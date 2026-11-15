{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the link between the sound shaders and the sound cache }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.SoundCacheCatalog;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Audio.WaveFile.Intf, DelphiDoom.Audio.SoundSample.Cache,
  DelphiDoom.Decl.Sound.Types, DelphiDoom.Decl.Sound.Intf, DelphiDoom.Decl.Sound.CacheCatalog,
  DelphiDoom.Tests.Audio.WaveFile;

type
  [TestFixture]
  [Category('audio')]
  TTestSoundCacheCatalog = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLoScattoDelCampioneAlloShader;
    [Test]
    procedure DovrebbeSegnareIlSuonoDiDefaultEOgg;
    [Test]
    procedure DovrebbeDareLaDimensioneDelFileOMenoUno;
  end;

implementation

procedure TTestSoundCacheCatalog.DovrebbeDareLoScattoDelCampioneAlloShader;
var
  LFiles: TFakeWaveFileSystem;
  LFilesIntf: IWaveFileSystem;
  LCache: TSoundSampleCache;
  LCatalog: ISoundSampleCatalog;
  LWave: TBytes;
  LInfo: TSoundSampleInfo;
begin
  LFiles := TFakeWaveFileSystem.Create;
  LFilesIntf := LFiles;
  // a mono 11025 Hz sound of 50 samples (the header of TTestWaveFile.Wave is for 22050 Hz stereo: build another)
  SetLength(LWave, 44 + 100);
  Move(PAnsiChar('RIFF'#100#0#0#0'WAVEfmt '#16#0#0#0#1#0#1#0#$11#$2B#0#0#$22#$56#0#0#2#0#16#0'data'#100#0#0#0)^, LWave[0], 44);
  LFiles.Add('sound/s.wav', LWave);
  LCache := TSoundSampleCache.Create(LFilesIntf);
  try
    LCatalog := TSoundCacheCatalog.Create(LCache);
    LInfo := LCatalog.FindSample('Sound\S.wav');
    Assert.AreEqual('sound/s.wav', string(LInfo.Name));
    Assert.IsFalse(LInfo.IsDefault);
    Assert.IsFalse(LInfo.IsOgg);
    Assert.AreEqual(50 * 4, LInfo.Length44kHzSamples);
    Assert.AreEqual(100, LInfo.MemorySize);
  finally
    LCatalog := nil;
    LCache.Free;
  end;
end;

procedure TTestSoundCacheCatalog.DovrebbeSegnareIlSuonoDiDefaultEOgg;
var
  LFiles: TFakeWaveFileSystem;
  LFilesIntf: IWaveFileSystem;
  LCache: TSoundSampleCache;
  LCatalog: ISoundSampleCatalog;
begin
  LFiles := TFakeWaveFileSystem.Create;
  LFilesIntf := LFiles;
  LFiles.Add('m.ogg', TBytes.Create(Ord('O'), Ord('g'), Ord('g'), Ord('S')));
  LCache := TSoundSampleCache.Create(LFilesIntf, TFakeOggDecoder.Create(1, 22050, TBytes.Create(1, 2)));
  try
    LCache.RealTimeDecoding := True;
    LCatalog := TSoundCacheCatalog.Create(LCache);
    Assert.IsTrue(LCatalog.FindSample('m.wav').IsOgg);
    Assert.IsTrue(LCatalog.FindSample('none.wav').IsDefault);
  finally
    LCatalog := nil;
    LCache.Free;
  end;
end;

procedure TTestSoundCacheCatalog.DovrebbeDareLaDimensioneDelFileOMenoUno;
var
  LFiles: TFakeWaveFileSystem;
  LProbe: ISoundFileProbe;
begin
  LFiles := TFakeWaveFileSystem.Create;
  LFiles.Add('a.wav', TBytes.Create(1, 2, 3));
  LProbe := TSoundFileSystemProbe.Create(LFiles);
  Assert.AreEqual(3, LProbe.FileSize('A.wav'));
  Assert.AreEqual(-1, LProbe.FileSize('b.wav'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSoundCacheCatalog);

end.
