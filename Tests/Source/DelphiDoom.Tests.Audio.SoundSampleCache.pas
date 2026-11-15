{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound cache of Doom 3, TSoundSampleCache (DUnitX)  }
{                                                                              }
{  The rules are those of idSoundCache::FindSound and idSoundSample::Load,     }
{  written from snd_cache.cpp line by line (the cache needs OpenAL and the     }
{  whole sound system in the original, so it cannot be compiled alone).        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.SoundSampleCache;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Logging.Intf,
  DelphiDoom.Audio.WaveFile.Types, DelphiDoom.Audio.WaveFile.Intf, DelphiDoom.Audio.SoundSample.Types,
  DelphiDoom.Audio.SoundSample.Cache, DelphiDoom.Tests.Audio.WaveFile;

type
  TWarningLog = class(TInterfacedObject, ILog)
  strict private
    FWarnings: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Warnings: TList<string> read FWarnings;
  end;

  [TestFixture]
  [Category('audio')]
  TTestSoundSampleCache = class(TObject)
  strict private
    FFiles: TFakeWaveFileSystem;
    FFilesIntf: IWaveFileSystem;
    FLog: TWarningLog;
    FLogIntf: ILog;
    FCache: TSoundSampleCache;
    class function Wave(AChannels, ABits, ARate, ABytes: Integer): TBytes; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCaricareUnSuonoValidoConIlSuoFormato;
    [Test]
    procedure DovrebbeDareLoStessoOggettoPerLoStessoNome;
    [Test]
    procedure DovrebbeCanonizzareIlNome;
    [Test]
    procedure DovrebbeUsareIlSuonoDiDefaultSeIlFileNonCe;
    [Test]
    procedure DovrebbeFareLOndaSinusoidaleDelSuonoDiDefault;
    [Test]
    procedure DovrebbeRifiutareCanaliBitERateNonAmmessi;
    [Test]
    procedure DovrebbeDareLaLunghezzaA44kHz;
    [Test]
    procedure DovrebbeTrovareUnFileOggConLoStessoNome;
    [Test]
    procedure DovrebbeDirIlFormatoOggConLaDecodificaInTempoReale;
    [Test]
    procedure DovrebbeSvuotareLaCache;
  end;

implementation

{ TWarningLog }

constructor TWarningLog.Create;
begin
  inherited Create;
  FWarnings := TList<string>.Create;
end;

destructor TWarningLog.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

procedure TWarningLog.Info(const AText: string);
begin
end;

procedure TWarningLog.Warning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TWarningLog.DevWarning(const AText: string);
begin
end;

procedure TWarningLog.Error(const AText: string);
begin
end;

{ TTestSoundSampleCache }

class function TTestSoundSampleCache.Wave(AChannels, ABits, ARate, ABytes: Integer): TBytes;
var
  LIndex: Integer;
  procedure PutLe(AValue: Cardinal; ACount: Integer);
  var
    LByte: Integer;
  begin
    for LByte := 0 to ACount - 1 do
    begin
      Result[LIndex] := Byte(AValue shr (8 * LByte));
      Inc(LIndex);
    end;
  end;
  procedure Put(const AText: AnsiString);
  var
    LChar: Integer;
  begin
    for LChar := 1 to Length(AText) do
    begin
      Result[LIndex] := Ord(AText[LChar]);
      Inc(LIndex);
    end;
  end;
begin
  SetLength(Result, 44 + ABytes);
  LIndex := 0;
  Put('RIFF');
  PutLe(Cardinal(36 + ABytes), 4);
  Put('WAVEfmt ');
  PutLe(16, 4);
  PutLe(1, 2);
  PutLe(Cardinal(AChannels), 2);
  PutLe(Cardinal(ARate), 4);
  PutLe(Cardinal(ARate * AChannels * ABits div 8), 4);
  PutLe(Cardinal(AChannels * ABits div 8), 2);
  PutLe(Cardinal(ABits), 2);
  Put('data');
  PutLe(Cardinal(ABytes), 4);
  while LIndex < Length(Result) do
  begin
    Result[LIndex] := Byte(LIndex);
    Inc(LIndex);
  end;
end;

procedure TTestSoundSampleCache.Setup;
begin
  FFiles := TFakeWaveFileSystem.Create;
  FFilesIntf := FFiles;
  FLog := TWarningLog.Create;
  FLogIntf := FLog;
  FCache := TSoundSampleCache.Create(FFilesIntf, TFakeOggDecoder.Create(2, 22050, TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8)),
    FLogIntf);
end;

procedure TTestSoundSampleCache.TearDown;
begin
  FCache.Free;
end;

procedure TTestSoundSampleCache.DovrebbeCaricareUnSuonoValidoConIlSuoFormato;
var
  LSample: TSoundSample;
begin
  FFiles.Add('sound/x.wav', Wave(2, 16, 44100, 400));
  LSample := FCache.FindSound('sound/x.wav');
  Assert.IsFalse(LSample.IsDefault);
  Assert.AreEqual(2, Integer(LSample.Format.Channels));
  Assert.AreEqual(200, LSample.SizeInSamples);
  Assert.AreEqual(400, LSample.MemorySize);
  Assert.AreEqual<Integer>(400, Length(LSample.Data));
  Assert.AreEqual(44, Integer(LSample.Data[0]));
  Assert.IsFalse(LSample.IsOgg);
  Assert.AreEqual(0, FLog.Warnings.Count);
end;

procedure TTestSoundSampleCache.DovrebbeDareLoStessoOggettoPerLoStessoNome;
begin
  FFiles.Add('sound/x.wav', Wave(1, 16, 44100, 100));
  Assert.IsTrue(FCache.FindSound('sound/x.wav') = FCache.FindSound('SOUND\X.WAV'));
  Assert.AreEqual(1, FCache.Count);
end;

procedure TTestSoundSampleCache.DovrebbeCanonizzareIlNome;
begin
  FFiles.Add('sound/x.wav', Wave(1, 16, 44100, 100));
  Assert.AreEqual('sound/x.wav', FCache.FindSound('Sound\X.WAV').Name);
end;

procedure TTestSoundSampleCache.DovrebbeUsareIlSuonoDiDefaultSeIlFileNonCe;
var
  LSample: TSoundSample;
begin
  LSample := FCache.FindSound('sound/missing.wav');
  Assert.IsTrue(LSample.IsDefault);
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.AreEqual('Couldn''t load sound ''sound/missing.wav'' using default', FLog.Warnings[0]);
  Assert.AreEqual(8192, LSample.SizeInSamples);
  Assert.AreEqual(16384, LSample.MemorySize);
  Assert.AreEqual(44100, Integer(LSample.Format.SamplesPerSecond));
  Assert.AreEqual(1, Integer(LSample.Format.Channels));
end;

procedure TTestSoundSampleCache.DovrebbeFareLOndaSinusoidaleDelSuonoDiDefault;
var
  LSample: TSoundSample;
  function At(AIndex: Integer): Integer;
  begin
    Result := PSmallInt(@LSample.Data[AIndex * 4])^;
  end;
begin
  LSample := FCache.FindSound('nothing');
  // a period of 64 samples with the amplitude 0x4000, the same in both halves of a frame
  Assert.AreEqual(0, At(0));
  Assert.AreEqual($4000, At(16));
  Assert.AreEqual(0, At(32));
  Assert.AreEqual(-$4000, At(48));
  Assert.AreEqual(At(5), Integer(PSmallInt(@LSample.Data[5 * 4 + 2])^));
  Assert.AreEqual(At(5), At(5 + 64));
end;

procedure TTestSoundSampleCache.DovrebbeRifiutareCanaliBitERateNonAmmessi;
begin
  FFiles.Add('three.wav', Wave(3, 16, 44100, 100));
  FFiles.Add('eight.wav', Wave(1, 8, 44100, 100));
  FFiles.Add('rate.wav', Wave(1, 16, 48000, 100));
  Assert.IsTrue(FCache.FindSound('three.wav').IsDefault);
  Assert.IsTrue(FCache.FindSound('eight.wav').IsDefault);
  Assert.IsTrue(FCache.FindSound('rate.wav').IsDefault);
  Assert.AreEqual(3, FLog.Warnings.Count);
  Assert.AreEqual('idSoundSample: three.wav has 3 channels, using default', FLog.Warnings[0]);
  Assert.AreEqual('idSoundSample: eight.wav is 8bits, expected 16bits using default', FLog.Warnings[1]);
  Assert.AreEqual('idSoundCache: rate.wav is 48000Hz, expected 11025, 22050 or 44100 Hz. Using default', FLog.Warnings[2]);
end;

procedure TTestSoundSampleCache.DovrebbeDareLaLunghezzaA44kHz;
begin
  FFiles.Add('a.wav', Wave(1, 16, 11025, 100));
  FFiles.Add('b.wav', Wave(1, 16, 22050, 100));
  FFiles.Add('c.wav', Wave(1, 16, 44100, 100));
  Assert.AreEqual(50 * 4, FCache.FindSound('a.wav').Length44kHzSamples);
  Assert.AreEqual(50 * 2, FCache.FindSound('b.wav').Length44kHzSamples);
  Assert.AreEqual(50, FCache.FindSound('c.wav').Length44kHzSamples);
end;

procedure TTestSoundSampleCache.DovrebbeTrovareUnFileOggConLoStessoNome;
var
  LSample: TSoundSample;
begin
  FFiles.Add('music.ogg', TBytes.Create(Ord('O'), Ord('g'), Ord('g'), Ord('S')));
  LSample := FCache.FindSound('music.wav');
  Assert.IsFalse(LSample.IsDefault);
  Assert.AreEqual(2, Integer(LSample.Format.Channels));
  Assert.AreEqual(4, LSample.SizeInSamples);
  Assert.AreEqual<Integer>(8, Length(LSample.Data));
  Assert.AreEqual(0, FLog.Warnings.Count);
end;

procedure TTestSoundSampleCache.DovrebbeDirIlFormatoOggConLaDecodificaInTempoReale;
var
  LSample: TSoundSample;
begin
  FFiles.Add('music.ogg', TBytes.Create(Ord('O'), Ord('g'), Ord('g'), Ord('S'), 1, 2));
  FCache.RealTimeDecoding := True;
  LSample := FCache.FindSound('music.wav');
  Assert.IsTrue(LSample.IsOgg);
  Assert.AreEqual(6, LSample.MemorySize);
end;

procedure TTestSoundSampleCache.DovrebbeSvuotareLaCache;
begin
  FCache.FindSound('a');
  FCache.FindSound('b');
  Assert.AreEqual(2, FCache.Count);
  FCache.Clear;
  Assert.AreEqual(0, FCache.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSoundSampleCache);

end.
