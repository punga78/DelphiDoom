{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TWaveFile, the idWaveFile of Doom 3 (DUnitX)           }
{                                                                              }
{  The header (Open) has its parity with the real C++ in                       }
{  DelphiDoom.Tests.Audio.WaveHeader; Read, Seek, OpenFromMemory and the OGG   }
{  path are checked against the text of snd_wavefile.cpp and snd_decoder.cpp,  }
{  line by line, with a file system and a decoder written for the test.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.WaveFile;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Audio.WaveFile.Types,
  DelphiDoom.Audio.WaveFile.Intf, DelphiDoom.Audio.WaveFile;

type
  /// <summary>Files in memory by name (compared without case)</summary>
  TFakeWaveFileSystem = class(TInterfacedObject, IWaveFileSystem)
  strict private
    FFiles: TDictionary<string, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName: string; const AData: TBytes);
    function FileLength(const AName: string): Integer;
    function TryReadFile(const AName: string; out AData: TBytes): Boolean;
    function Timestamp(const AName: string): Int64;
  end;

  /// <summary>An OGG decoder that gives what the test says for any data that starts with OggS</summary>
  TFakeOggDecoder = class(TInterfacedObject, IWaveOggDecoder)
  strict private
    FChannels: Integer;
    FRate: Cardinal;
    FPcm: TBytes;
  public
    constructor Create(AChannels: Integer; ARate: Cardinal; const APcm: TBytes);
    function TryDecode(const AData: TBytes; out AChannels: Integer; out ASamplesPerSecond: Cardinal;
      out APcm: TBytes): Boolean;
  end;

  [TestFixture]
  [Category('audio')]
  TTestWaveFile = class(TObject)
  strict private
    FFiles: TFakeWaveFileSystem;
    FFilesIntf: IWaveFileSystem;
    function Wave(ASamples: Integer; ATrailing: Integer = 0): TBytes;
    function Pcm(ACount: Integer): TBytes;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeAprireUnWavEDareFormatoEDimensioni;
    [Test]
    procedure DovrebbeLeggereIDatiDalPrimoCampione;
    [Test]
    procedure DovrebbeLeggereOltreIlChunkDeiDatiFinoAllaFineDelFile;
    [Test]
    procedure DovrebbeSpostarsiDallInizioDeiDati;
    [Test]
    procedure DovrebbeTornareAllInizioConResetFile;
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonCeVuotoONonWave;
    [Test]
    procedure DovrebbeDireMenoUnoSenzaNomeOSenzaFileAperto;
    [Test]
    procedure DovrebbePreferireUnFileOggConLoStessoNome;
    [Test]
    procedure DovrebbeLeggereLOggDecodificatoABlocchiDa4096;
    [Test]
    procedure DovrebbeFermarsiAllaFineDeiCampioniOgg;
    [Test]
    procedure DovrebbeDareErroreFatalePerSeekSuUnOgg;
    [Test]
    procedure DovrebbeRifiutareUnOggNonValidoOSenzaDecoder;
    [Test]
    procedure DovrebbeLasciareLOggCodificatoConLaDecodificaInTempoReale;
    [Test]
    procedure DovrebbeAprireDallaMemoriaELeggereConTaglio;
    [Test]
    procedure DovrebbeSpostareInMemoriaERispondereMenoUno;
    [Test]
    procedure DovrebbeChiudereSempreConZero;
  end;

implementation

{ TFakeWaveFileSystem }

constructor TFakeWaveFileSystem.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TFakeWaveFileSystem.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeWaveFileSystem.Add(const AName: string; const AData: TBytes);
begin
  FFiles.AddOrSetValue(LowerCase(AName), AData);
end;

function TFakeWaveFileSystem.FileLength(const AName: string): Integer;
var
  LData: TBytes;
begin
  if FFiles.TryGetValue(LowerCase(AName), LData) then
    Result := Length(LData)
  else
    Result := -1;
end;

function TFakeWaveFileSystem.TryReadFile(const AName: string; out AData: TBytes): Boolean;
begin
  Result := FFiles.TryGetValue(LowerCase(AName), AData);
end;

function TFakeWaveFileSystem.Timestamp(const AName: string): Int64;
begin
  if FFiles.ContainsKey(LowerCase(AName)) then
    Result := 1234567
  else
    Result := 0;
end;

{ TFakeOggDecoder }

constructor TFakeOggDecoder.Create(AChannels: Integer; ARate: Cardinal; const APcm: TBytes);
begin
  inherited Create;
  FChannels := AChannels;
  FRate := ARate;
  FPcm := APcm;
end;

function TFakeOggDecoder.TryDecode(const AData: TBytes; out AChannels: Integer; out ASamplesPerSecond: Cardinal;
  out APcm: TBytes): Boolean;
begin
  Result := (Length(AData) >= 4) and (AData[0] = Ord('O')) and (AData[1] = Ord('g'));
  if Result then
  begin
    AChannels := FChannels;
    ASamplesPerSecond := FRate;
    APcm := FPcm;
  end;
end;

{ TTestWaveFile }

procedure TTestWaveFile.Setup;
begin
  FFiles := TFakeWaveFileSystem.Create;
  FFilesIntf := FFiles;
end;

function TTestWaveFile.Pcm(ACount: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := Byte(LIndex * 7 + 3);
end;

function TTestWaveFile.Wave(ASamples: Integer; ATrailing: Integer): TBytes;
var
  LData: TBytes;
  LSize: Cardinal;
  LIndex: Integer;
  procedure Put(const AText: AnsiString);
  var
    LCharIndex: Integer;
  begin
    for LCharIndex := 1 to Length(AText) do
    begin
      Result[LIndex] := Ord(AText[LCharIndex]);
      Inc(LIndex);
    end;
  end;
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
begin
  LData := Pcm(ASamples * 2);
  LSize := Cardinal(Length(LData));
  SetLength(Result, 44 + Integer(LSize) + ATrailing);
  LIndex := 0;
  Put('RIFF');
  PutLe(36 + LSize, 4);
  Put('WAVEfmt ');
  PutLe(16, 4);
  PutLe(1, 2);
  PutLe(2, 2);
  PutLe(22050, 4);
  PutLe(88200, 4);
  PutLe(4, 2);
  PutLe(16, 2);
  Put('data');
  PutLe(LSize, 4);
  Move(LData[0], Result[LIndex], Length(LData));
  Inc(LIndex, Length(LData));
  while LIndex < Length(Result) do
  begin
    Result[LIndex] := $EE;
    Inc(LIndex);
  end;
end;

procedure TTestWaveFile.DovrebbeAprireUnWavEDareFormatoEDimensioni;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
begin
  FFiles.Add('sound/a.wav', Wave(10));
  LFile := TWaveFile.Create(FFilesIntf);
  try
    Assert.AreEqual(0, LFile.Open('sound/a.wav', LFormat));
    Assert.AreEqual(1, Integer(LFormat.Tag));
    Assert.AreEqual(2, Integer(LFormat.Channels));
    Assert.AreEqual<Cardinal>(22050, LFormat.SamplesPerSecond);
    Assert.AreEqual(16, Integer(LFormat.BitsPerSample));
    Assert.AreEqual(10, LFile.OutputSize);
    Assert.AreEqual(20, LFile.MemorySize);
    Assert.AreEqual(44, LFile.SeekBase);
    Assert.AreEqual<Int64>(1234567, LFile.FileTime);
    Assert.IsFalse(LFile.IsOgg);
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeLeggereIDatiDalPrimoCampione;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LBuffer: TBytes;
  LRead: Integer;
begin
  FFiles.Add('a.wav', Wave(10));
  LFile := TWaveFile.Create(FFilesIntf);
  try
    LFile.Open('a.wav', LFormat);
    SetLength(LBuffer, 8);
    Assert.AreEqual(8, LFile.Read(@LBuffer[0], 8, LRead));
    Assert.AreEqual(8, LRead);
    Assert.AreEqual(3, Integer(LBuffer[0]));
    Assert.AreEqual(10, Integer(LBuffer[1]));
    // the next call goes on from where the last one stopped
    Assert.AreEqual(4, LFile.Read(@LBuffer[0], 4, LRead));
    Assert.AreEqual(Integer(Byte(8 * 7 + 3)), Integer(LBuffer[0]));
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeLeggereOltreIlChunkDeiDatiFinoAllaFineDelFile;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LBuffer: TBytes;
  LRead: Integer;
begin
  // 20 bytes of samples and 6 more after them: idFile::Read does not stop at cksize
  FFiles.Add('a.wav', Wave(10, 6));
  LFile := TWaveFile.Create(FFilesIntf);
  try
    LFile.Open('a.wav', LFormat);
    SetLength(LBuffer, 100);
    Assert.AreEqual(26, LFile.Read(@LBuffer[0], 100, LRead));
    Assert.AreEqual(Integer($EE), Integer(LBuffer[25]));
    Assert.AreEqual(0, LFile.Read(@LBuffer[0], 100, LRead));
    Assert.AreEqual(0, LRead);
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeSpostarsiDallInizioDeiDati;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LBuffer: TBytes;
  LRead: Integer;
begin
  FFiles.Add('a.wav', Wave(10));
  LFile := TWaveFile.Create(FFilesIntf);
  try
    LFile.Open('a.wav', LFormat);
    Assert.AreEqual(0, LFile.Seek(6));
    SetLength(LBuffer, 2);
    LFile.Read(@LBuffer[0], 2, LRead);
    Assert.AreEqual(Integer(Byte(6 * 7 + 3)), Integer(LBuffer[0]));
    // past the end there is nothing to read
    Assert.AreEqual(0, LFile.Seek(1000));
    Assert.AreEqual(0, LFile.Read(@LBuffer[0], 2, LRead));
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeTornareAllInizioConResetFile;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LBuffer: TBytes;
  LRead: Integer;
begin
  FFiles.Add('a.wav', Wave(10));
  LFile := TWaveFile.Create(FFilesIntf);
  try
    LFile.Open('a.wav', LFormat);
    SetLength(LBuffer, 4);
    LFile.Read(@LBuffer[0], 4, LRead);
    Assert.AreEqual(0, LFile.ResetFile);
    LFile.Read(@LBuffer[0], 1, LRead);
    Assert.AreEqual(3, Integer(LBuffer[0]));
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeRifiutareUnFileCheNonCeVuotoONonWave;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
begin
  FFiles.Add('empty.wav', nil);
  FFiles.Add('text.wav', TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20));
  LFile := TWaveFile.Create(FFilesIntf);
  try
    Assert.AreEqual(-1, LFile.Open('missing.wav', LFormat));
    Assert.AreEqual(0, LFile.OutputSize);
    Assert.AreEqual(-1, LFile.Open('empty.wav', LFormat));
    Assert.AreEqual(-1, LFile.Open('text.wav', LFormat));
    // a file that is refused is closed
    Assert.AreEqual(-1, LFile.Seek(0));
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeDireMenoUnoSenzaNomeOSenzaFileAperto;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LBuffer: TBytes;
  LRead: Integer;
begin
  LFile := TWaveFile.Create(FFilesIntf);
  try
    SetLength(LBuffer, 4);
    Assert.AreEqual(-1, LFile.Open('', LFormat));
    Assert.AreEqual(-1, LFile.Read(@LBuffer[0], 4, LRead));
    Assert.AreEqual(-1, LFile.Seek(0));
    Assert.AreEqual(-1, LFile.ResetFile);
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbePreferireUnFileOggConLoStessoNome;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
begin
  FFiles.Add('sound/a.wav', Wave(10));
  FFiles.Add('sound/a.ogg', TBytes.Create(Ord('O'), Ord('g'), Ord('g'), Ord('S')));
  LFile := TWaveFile.Create(FFilesIntf, TFakeOggDecoder.Create(2, 44100, Pcm(40)));
  try
    Assert.AreEqual(0, LFile.Open('sound/a.wav', LFormat));
    Assert.IsTrue(LFile.IsOgg);
    Assert.AreEqual(WAVE_FORMAT_TAG_PCM, Integer(LFormat.Tag));
    Assert.AreEqual(2, Integer(LFormat.Channels));
    Assert.AreEqual<Cardinal>(44100, LFormat.SamplesPerSecond);
    Assert.AreEqual(16, Integer(LFormat.BitsPerSample));
    // 40 bytes of pcm: 20 samples, all channels counted
    Assert.AreEqual(20, LFile.OutputSize);
    Assert.AreEqual(40, LFile.MemorySize);
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeLeggereLOggDecodificatoABlocchiDa4096;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LBuffer: TBytes;
  LRead: Integer;
  LPcm: TBytes;
begin
  LPcm := Pcm(10000);
  FFiles.Add('a.ogg', TBytes.Create(Ord('O'), Ord('g'), Ord('g'), Ord('S')));
  LFile := TWaveFile.Create(FFilesIntf, TFakeOggDecoder.Create(1, 22050, LPcm));
  try
    LFile.Open('a.wav', LFormat);
    SetLength(LBuffer, 9000);
    Assert.AreEqual(9000, LFile.Read(@LBuffer[0], 9000, LRead));
    Assert.IsTrue(CompareMem(@LPcm[0], @LBuffer[0], 9000));
    Assert.AreEqual(1000, LFile.Read(@LBuffer[0], 5000, LRead));
    Assert.IsTrue(CompareMem(@LPcm[9000], @LBuffer[0], 1000));
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeFermarsiAllaFineDeiCampioniOgg;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LBuffer: TBytes;
  LRead: Integer;
begin
  FFiles.Add('a.ogg', TBytes.Create(Ord('O'), Ord('g'), Ord('g'), Ord('S')));
  LFile := TWaveFile.Create(FFilesIntf, TFakeOggDecoder.Create(1, 22050, Pcm(10)));
  try
    LFile.Open('a.wav', LFormat);
    SetLength(LBuffer, 100);
    Assert.AreEqual(10, LFile.Read(@LBuffer[0], 100, LRead));
    Assert.AreEqual(0, LFile.Read(@LBuffer[0], 100, LRead));
    Assert.AreEqual(0, LRead);
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeDareErroreFatalePerSeekSuUnOgg;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
begin
  FFiles.Add('a.ogg', TBytes.Create(Ord('O'), Ord('g'), Ord('g'), Ord('S')));
  LFile := TWaveFile.Create(FFilesIntf, TFakeOggDecoder.Create(1, 22050, Pcm(10)));
  try
    LFile.Open('a.wav', LFormat);
    Assert.WillRaise(
      procedure
      begin
        LFile.Seek(0);
      end, EWaveFileException);
    Assert.AreEqual(0, LFile.Close);
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeRifiutareUnOggNonValidoOSenzaDecoder;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
begin
  FFiles.Add('bad.ogg', TBytes.Create(1, 2, 3, 4, 5, 6));
  FFiles.Add('good.ogg', TBytes.Create(Ord('O'), Ord('g'), Ord('g'), Ord('S')));
  LFile := TWaveFile.Create(FFilesIntf, TFakeOggDecoder.Create(1, 22050, Pcm(10)));
  try
    Assert.AreEqual(-1, LFile.Open('bad.wav', LFormat));
    Assert.AreEqual(0, Integer(LFormat.Tag));
  finally
    LFile.Free;
  end;
  LFile := TWaveFile.Create(FFilesIntf);
  try
    Assert.AreEqual(-1, LFile.Open('good.wav', LFormat));
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeLasciareLOggCodificatoConLaDecodificaInTempoReale;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LBuffer: TBytes;
  LRead: Integer;
begin
  FFiles.Add('a.ogg', TBytes.Create(Ord('O'), Ord('g'), Ord('g'), Ord('S'), 9, 8, 7));
  LFile := TWaveFile.Create(FFilesIntf, TFakeOggDecoder.Create(1, 22050, Pcm(10)));
  try
    LFile.RealTimeDecoding := True;
    Assert.AreEqual(0, LFile.Open('a.wav', LFormat));
    Assert.AreEqual(WAVE_FORMAT_TAG_OGG, Integer(LFormat.Tag));
    // the memory size is the size of the encoded file, the output size the decoded samples
    Assert.AreEqual(7, LFile.MemorySize);
    Assert.AreEqual(5, LFile.OutputSize);
    SetLength(LBuffer, 20);
    Assert.AreEqual(7, LFile.Read(@LBuffer[0], 20, LRead));
    Assert.AreEqual(Integer(Ord('O')), Integer(LBuffer[0]));
    Assert.AreEqual(7, Integer(LBuffer[6]));
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeAprireDallaMemoriaELeggereConTaglio;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LSamples: TBytes;
  LBuffer: TBytes;
  LRead: Integer;
begin
  LSamples := Pcm(10);
  LFormat := Default(TWaveFormat);
  LFormat.Tag := 1;
  LFormat.Channels := 1;
  LFile := TWaveFile.Create(FFilesIntf);
  try
    Assert.AreEqual(0, LFile.OpenFromMemory(@LSamples[0], 10, LFormat));
    Assert.AreEqual(5, LFile.OutputSize);
    Assert.AreEqual(10, LFile.MemorySize);
    SetLength(LBuffer, 100);
    // cut at the end of the data
    Assert.AreEqual(10, LFile.Read(@LBuffer[0], 100, LRead));
    Assert.AreEqual(10, LRead);
    Assert.IsTrue(CompareMem(@LSamples[0], @LBuffer[0], 10));
    Assert.AreEqual(0, LFile.Read(@LBuffer[0], 100, LRead));
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeSpostareInMemoriaERispondereMenoUno;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LSamples: TBytes;
  LBuffer: TBytes;
  LRead: Integer;
begin
  LSamples := Pcm(10);
  LFile := TWaveFile.Create(FFilesIntf);
  try
    LFile.OpenFromMemory(@LSamples[0], 10, LFormat);
    // idWaveFile::Seek sets the pointer and falls out of the if with -1
    Assert.AreEqual(-1, LFile.Seek(4));
    SetLength(LBuffer, 2);
    LFile.Read(@LBuffer[0], 2, LRead);
    Assert.AreEqual(Integer(Byte(4 * 7 + 3)), Integer(LBuffer[0]));
    Assert.AreEqual(0, LFile.ResetFile);
    LFile.Read(@LBuffer[0], 1, LRead);
    Assert.AreEqual(3, Integer(LBuffer[0]));
  finally
    LFile.Free;
  end;
end;

procedure TTestWaveFile.DovrebbeChiudereSempreConZero;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
begin
  FFiles.Add('a.wav', Wave(4));
  LFile := TWaveFile.Create(FFilesIntf);
  try
    Assert.AreEqual(0, LFile.Close);
    LFile.Open('a.wav', LFormat);
    Assert.AreEqual(0, LFile.Close);
    Assert.AreEqual(0, LFile.Close);
    Assert.AreEqual(-1, LFile.Seek(0));
  finally
    LFile.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWaveFile);

end.
