{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - the WAVE header of the sound       }
{  cache of Doom 3                                                             }
{                                                                              }
{  The unit tests of TWaveHeaderReader and the parity with the real            }
{  snd_wavefile.cpp of Doom 3: Tests\Data\Audio\wave.input.txt is run with the }
{  class and the output is compared with wave.golden.txt (see                  }
{  Tests\Data\Audio\README.md).                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.WaveHeader;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Audio.WaveHeader;

type
  [TestFixture]
  [Category('Audio')]
  TTestWaveHeaderReader = class
  strict private
    /// <summary>RIFF, WAVE and a PCM fmt chunk (mono, 22050 Hz, 16 bits) followed by AExtra</summary>
    class function Wave(const AExtra: TBytes): TBytes; static;
    class function Text(const AText: AnsiString): TBytes; static;
    class function Long(const AValue: Cardinal): TBytes; static;
    class function Short(const AValue: Word): TBytes; static;
    class function Join(const AParts: array of TBytes): TBytes; static;
    class function FormatChunk(const ATag: Word; const ASize: Cardinal = 16): TBytes; static;
    class function DataChunk(const ASize: Cardinal; const AData: TBytes): TBytes; static;
  public
    [Test]
    procedure DovrebbeLeggereIlFormatoPcmEDoveSonoICampioni;
    [Test]
    procedure DovrebbeDareLaDimensioneInCampioniDa16Bit;
    [Test]
    procedure DovrebbeSaltareIByteInPiuDelChunkFmt;
    [Test]
    procedure DovrebbeRifiutareUnFormatoNonPcm;
    [Test]
    procedure DovrebbeRifiutareUnChunkFmtPiuCortoDi16Byte;
    [Test]
    procedure DovrebbeRifiutareUnFormatoTroncato;
    [Test]
    procedure DovrebbeRifiutareUnFileChePartaSenzaRiffWave;
    [Test]
    procedure DovrebbeRifiutareUnFileDiMenoDiDodiciByte;
    [Test]
    procedure DovrebbeRifiutareSeNonTrovaIlChunkFmt;
    [Test]
    procedure DovrebbeRifiutareSeNonTrovaIlChunkData;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneDeiDatiDiFfffffff;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneTagliataDallaFineDelFile;
    [Test]
    procedure DovrebbeNonControllareLaDimensioneDeiDatiControIlFile;
    [Test]
    procedure DovrebbeNonSaltareUnChunkPrimaDiFmtSeHaDei;
    [Test]
    procedure DovrebbeAccettareUnChunkVuotoPrimaDiFmt;
    [Test]
    procedure DovrebbeCercareDataByteAByteDalByte16;
  end;

  [TestFixture]
  [Category('Audio')]
  TTestWaveHeaderGolden = class
  strict private
    FLines: TStringList;
    FFiles: TDictionary<string, TBytes>;
    function DataFolder: string;
    procedure Emit(const ALine: string);
    class function Number(const AText: string): Int64; static;
    class procedure Append(var ABytes: TBytes; const AValue: Int64; const ACount: Integer); static;
    class procedure AddTokens(var ABytes: TBytes; const ALine: string); static;
    procedure Execute(const AOperation: string);
    function Run(const AInput: TStrings): TStringList;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroIdWaveFile;
  end;

implementation

{ TTestWaveHeaderReader }

class function TTestWaveHeaderReader.Text(const AText: AnsiString): TBytes;
begin
  SetLength(Result, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], Result[0], Length(AText));
end;

class function TTestWaveHeaderReader.Long(const AValue: Cardinal): TBytes;
begin
  Result := TBytes.Create(AValue and $FF, (AValue shr 8) and $FF, (AValue shr 16) and $FF, AValue shr 24);
end;

class function TTestWaveHeaderReader.Short(const AValue: Word): TBytes;
begin
  Result := TBytes.Create(AValue and $FF, AValue shr 8);
end;

class function TTestWaveHeaderReader.Join(const AParts: array of TBytes): TBytes;
var
  LPart: TBytes;
begin
  Result := nil;
  for LPart in AParts do
    Result := Result + LPart;
end;

class function TTestWaveHeaderReader.FormatChunk(const ATag: Word; const ASize: Cardinal): TBytes;
begin
  Result := Join([Text('fmt '), Long(ASize), Short(ATag), Short(1), Long(22050), Long(44100), Short(2), Short(16)]);
end;

class function TTestWaveHeaderReader.DataChunk(const ASize: Cardinal; const AData: TBytes): TBytes;
begin
  Result := Join([Text('data'), Long(ASize), AData]);
end;

class function TTestWaveHeaderReader.Wave(const AExtra: TBytes): TBytes;
begin
  Result := Join([Text('RIFF'), Long(100), Text('WAVE'), FormatChunk(1), AExtra]);
end;

procedure TTestWaveHeaderReader.DovrebbeLeggereIlFormatoPcmEDoveSonoICampioni;
var
  LHeader: TWaveHeader;
begin
  Assert.IsTrue(TWaveHeaderReader.TryRead(Wave(DataChunk(8, TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8))), LHeader));
  Assert.AreEqual<Word>(1, LHeader.FormatTag);
  Assert.AreEqual<Word>(1, LHeader.Channels);
  Assert.AreEqual<Cardinal>(22050, LHeader.SamplesPerSecond);
  Assert.AreEqual<Cardinal>(44100, LHeader.AverageBytesPerSecond);
  Assert.AreEqual<Word>(2, LHeader.BlockAlign);
  Assert.AreEqual<Word>(16, LHeader.BitsPerSample);
  Assert.AreEqual<Cardinal>(8, LHeader.DataSize);
  // 12 of the RIFF header, 24 of the fmt chunk, 8 of the data chunk header
  Assert.AreEqual<Cardinal>(44, LHeader.DataOffset);
end;

procedure TTestWaveHeaderReader.DovrebbeDareLaDimensioneInCampioniDa16Bit;
var
  LHeader: TWaveHeader;
begin
  Assert.IsTrue(TWaveHeaderReader.TryRead(Wave(DataChunk(7, TBytes.Create(1, 2, 3, 4, 5, 6, 7))), LHeader));
  Assert.AreEqual<Cardinal>(7, LHeader.DataSize);
  Assert.AreEqual<Cardinal>(3, LHeader.SizeInSamples);
end;

procedure TTestWaveHeaderReader.DovrebbeSaltareIByteInPiuDelChunkFmt;
var
  LHeader: TWaveHeader;
  LBytes: TBytes;
begin
  // a fmt chunk of 18 bytes (cbSize): the extra bytes are not read but the data chunk is found all the same
  LBytes := Join([Text('RIFF'), Long(100), Text('WAVE'), FormatChunk(1, 18), Short(0),
    DataChunk(4, TBytes.Create(1, 2, 3, 4))]);
  Assert.IsTrue(TWaveHeaderReader.TryRead(LBytes, LHeader));
  Assert.AreEqual<Cardinal>(4, LHeader.DataSize);
  Assert.AreEqual<Cardinal>(46, LHeader.DataOffset);
end;

procedure TTestWaveHeaderReader.DovrebbeRifiutareUnFormatoNonPcm;
var
  LHeader: TWaveHeader;
  LTag: Word;
begin
  for LTag in [0, 2, 3, $FFFE] do
    Assert.IsFalse(TWaveHeaderReader.TryRead(Join([Text('RIFF'), Long(100), Text('WAVE'), FormatChunk(LTag),
      DataChunk(4, TBytes.Create(1, 2, 3, 4))]), LHeader));
end;

procedure TTestWaveHeaderReader.DovrebbeRifiutareUnChunkFmtPiuCortoDi16Byte;
var
  LHeader: TWaveHeader;
begin
  Assert.IsFalse(TWaveHeaderReader.TryRead(Join([Text('RIFF'), Long(100), Text('WAVE'), FormatChunk(1, 15),
    DataChunk(4, TBytes.Create(1, 2, 3, 4))]), LHeader));
end;

procedure TTestWaveHeaderReader.DovrebbeRifiutareUnFormatoTroncato;
var
  LHeader: TWaveHeader;
  LBytes: TBytes;
begin
  LBytes := Join([Text('RIFF'), Long(100), Text('WAVE'), FormatChunk(1)]);
  // only 12 of the 16 bytes of the format
  Assert.IsFalse(TWaveHeaderReader.TryRead(Copy(LBytes, 0, Length(LBytes) - 4), LHeader));
  // and no format at all after the chunk header
  Assert.IsFalse(TWaveHeaderReader.TryRead(Copy(LBytes, 0, 20), LHeader));
end;

procedure TTestWaveHeaderReader.DovrebbeRifiutareUnFileChePartaSenzaRiffWave;
var
  LHeader: TWaveHeader;
  LData: TBytes;
begin
  LData := Join([FormatChunk(1), DataChunk(4, TBytes.Create(1, 2, 3, 4))]);
  Assert.IsFalse(TWaveHeaderReader.TryRead(Join([Text('RIFX'), Long(100), Text('WAVE'), LData]), LHeader));
  Assert.IsFalse(TWaveHeaderReader.TryRead(Join([Text('RIFF'), Long(100), Text('AVI '), LData]), LHeader));
  Assert.IsFalse(TWaveHeaderReader.TryRead(Text('This is not a wave file at all'), LHeader));
end;

procedure TTestWaveHeaderReader.DovrebbeRifiutareUnFileDiMenoDiDodiciByte;
var
  LHeader: TWaveHeader;
begin
  Assert.IsFalse(TWaveHeaderReader.TryRead(nil, LHeader));
  Assert.IsFalse(TWaveHeaderReader.TryRead(Text('RIFF'), LHeader));
  Assert.IsFalse(TWaveHeaderReader.TryRead(Text('RIFF1234WAV'), LHeader));
  // 12 bytes are the RIFF header: no chunk follows
  Assert.IsFalse(TWaveHeaderReader.TryRead(Join([Text('RIFF'), Long(100), Text('WAVE')]), LHeader));
end;

procedure TTestWaveHeaderReader.DovrebbeRifiutareSeNonTrovaIlChunkFmt;
var
  LHeader: TWaveHeader;
begin
  Assert.IsFalse(TWaveHeaderReader.TryRead(Join([Text('RIFF'), Long(100), Text('WAVE'),
    DataChunk(4, TBytes.Create(1, 2, 3, 4)), DataChunk(4, TBytes.Create(1, 2, 3, 4))]), LHeader));
end;

procedure TTestWaveHeaderReader.DovrebbeRifiutareSeNonTrovaIlChunkData;
var
  LHeader: TWaveHeader;
begin
  Assert.IsFalse(TWaveHeaderReader.TryRead(Wave(Join([Text('LIST'), Long(4), Text('INFO')])), LHeader));
  Assert.IsFalse(TWaveHeaderReader.TryRead(Wave(nil), LHeader));
end;

procedure TTestWaveHeaderReader.DovrebbeRifiutareUnaDimensioneDeiDatiDiFfffffff;
var
  LHeader: TWaveHeader;
begin
  Assert.IsFalse(TWaveHeaderReader.TryRead(Wave(DataChunk($FFFFFFFF, TBytes.Create(0, 0, 0, 0))), LHeader));
  Assert.IsTrue(TWaveHeaderReader.TryRead(Wave(DataChunk($FFFFFFFE, TBytes.Create(0, 0, 0, 0))), LHeader));
  Assert.AreEqual<Cardinal>($7FFFFFFF, LHeader.SizeInSamples);
end;

procedure TTestWaveHeaderReader.DovrebbeRifiutareUnaDimensioneTagliataDallaFineDelFile;
var
  LHeader: TWaveHeader;
begin
  // the original reads what was left in memory; here it is a refusal
  Assert.IsFalse(TWaveHeaderReader.TryRead(Wave(Join([Text('data'), TBytes.Create(1, 2)])), LHeader));
  Assert.IsFalse(TWaveHeaderReader.TryRead(Wave(Text('data')), LHeader));
end;

procedure TTestWaveHeaderReader.DovrebbeNonControllareLaDimensioneDeiDatiControIlFile;
var
  LHeader: TWaveHeader;
begin
  Assert.IsTrue(TWaveHeaderReader.TryRead(Wave(DataChunk(1000, TBytes.Create(1))), LHeader));
  Assert.AreEqual<Cardinal>(1000, LHeader.DataSize);
  Assert.IsTrue(TWaveHeaderReader.TryRead(Wave(DataChunk(0, nil)), LHeader));
  Assert.AreEqual<Cardinal>(0, LHeader.DataSize);
  Assert.AreEqual<Cardinal>(44, LHeader.DataOffset);
end;

procedure TTestWaveHeaderReader.DovrebbeNonSaltareUnChunkPrimaDiFmtSeHaDei;
var
  LHeader: TWaveHeader;
begin
  // the chunks are read 8 bytes at a time and their size is not used to skip them: a LIST of 4 bytes puts the
  // next read in the middle of the fmt chunk, and the file is refused
  Assert.IsFalse(TWaveHeaderReader.TryRead(Join([Text('RIFF'), Long(100), Text('WAVE'), Text('LIST'), Long(4),
    Text('INFO'), FormatChunk(1), DataChunk(2, TBytes.Create(1, 2))]), LHeader));
  // with 8 bytes of data it lands on it
  Assert.IsTrue(TWaveHeaderReader.TryRead(Join([Text('RIFF'), Long(100), Text('WAVE'), Text('LIST'), Long(8),
    Text('INFOabcd'), FormatChunk(1), DataChunk(2, TBytes.Create(1, 2))]), LHeader));
  Assert.AreEqual<Cardinal>(60, LHeader.DataOffset);
end;

procedure TTestWaveHeaderReader.DovrebbeAccettareUnChunkVuotoPrimaDiFmt;
var
  LHeader: TWaveHeader;
begin
  Assert.IsTrue(TWaveHeaderReader.TryRead(Join([Text('RIFF'), Long(100), Text('WAVE'), Text('JUNK'), Long(0),
    FormatChunk(1), DataChunk(2, TBytes.Create(1, 2))]), LHeader));
  Assert.AreEqual<Cardinal>(52, LHeader.DataOffset);
end;

procedure TTestWaveHeaderReader.DovrebbeCercareDataByteAByteDalByte16;
var
  LHeader: TWaveHeader;
begin
  // a "data" inside the fmt chunk (in its extra bytes) is taken for the data chunk, and the size is what follows it
  Assert.IsTrue(TWaveHeaderReader.TryRead(Join([Text('RIFF'), Long(100), Text('WAVE'), FormatChunk(1, 22),
    Text('data'), TBytes.Create(1, 2), DataChunk(4, TBytes.Create(1, 2, 3, 4))]), LHeader));
  Assert.AreEqual<Cardinal>(44, LHeader.DataOffset);
  Assert.AreEqual<Cardinal>($61640201, LHeader.DataSize);
  // and "data" can start anywhere after the byte 16
  Assert.IsTrue(TWaveHeaderReader.TryRead(Wave(Join([Text('dat'), DataChunk(2, TBytes.Create(1, 2))])), LHeader));
  Assert.AreEqual<Cardinal>(2, LHeader.DataSize);
end;

{ TTestWaveHeaderGolden }

function TTestWaveHeaderGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Audio\');
end;

procedure TTestWaveHeaderGolden.Emit(const ALine: string);
begin
  FLines.Add(ALine);
end;

class function TTestWaveHeaderGolden.Number(const AText: string): Int64;
begin
  if AText.StartsWith('0x') then
    Result := StrToInt64('$' + Copy(AText, 3, MaxInt))
  else
    Result := StrToInt64(AText);
end;

class procedure TTestWaveHeaderGolden.Append(var ABytes: TBytes; const AValue: Int64; const ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    SetLength(ABytes, Length(ABytes) + 1);
    ABytes[High(ABytes)] := (AValue shr (8 * LIndex)) and $FF;
  end;
end;

// the tokens of a line of bytes: T:abcd (the characters, "_" is a space), B:n, W:n (16 bits), D:n (32 bits),
// Z:n (n zero bytes), X:hex
class procedure TTestWaveHeaderGolden.AddTokens(var ABytes: TBytes; const ALine: string);
var
  LToken: string;
  LValue: string;
  LIndex: Integer;
begin
  for LToken in ALine.Split([' '], TStringSplitOptions.ExcludeEmpty) do
  begin
    LValue := Copy(LToken, 3, MaxInt);
    case LToken[1] of
      'T':
        for LIndex := 1 to Length(LValue) do
          if LValue[LIndex] = '_' then
            Append(ABytes, Ord(' '), 1)
          else
            Append(ABytes, Ord(LValue[LIndex]), 1);
      'B': Append(ABytes, Number(LValue), 1);
      'W': Append(ABytes, Number(LValue), 2);
      'D': Append(ABytes, Number(LValue), 4);
      'Z':
        for LIndex := 1 to Number(LValue) do
          Append(ABytes, 0, 1);
      'X':
        begin
          LIndex := 1;
          while LIndex < Length(LValue) do
          begin
            Append(ABytes, StrToInt('$' + Copy(LValue, LIndex, 2)), 1);
            Inc(LIndex, 2);
          end;
        end;
    end;
  end;
end;

procedure TTestWaveHeaderGolden.Execute(const AOperation: string);
var
  LWords: TArray<string>;
  LBytes: TBytes;
  LHeader: TWaveHeader;
begin
  LWords := AOperation.Split([' '], TStringSplitOptions.ExcludeEmpty);
  Emit('> ' + string.Join(' ', LWords));
  if LWords[0] = 'size' then
    Emit('sizes pcm=16 ex=18')
  else if LWords[0] = 'wave' then
  begin
    if not FFiles.TryGetValue(LWords[1], LBytes) then
    begin
      Emit('ret=-1');
      Exit;
    end;
    if TWaveHeaderReader.TryRead(LBytes, LHeader) then
    begin
      Emit('ret=0');
      Emit(Format(' fmt tag=%d ch=%d rate=%u avg=%u align=%d bits=%d cb=0', [LHeader.FormatTag, LHeader.Channels,
        LHeader.SamplesPerSecond, LHeader.AverageBytesPerSecond, LHeader.BlockAlign, LHeader.BitsPerSample]));
      Emit(Format(' size=%d mem=%d base=%u cksize=%u', [Integer(LHeader.SizeInSamples), Integer(LHeader.DataSize),
        LHeader.DataOffset, LHeader.DataSize]));
    end
    else
      Emit('ret=-1');
  end;
end;

function TTestWaveHeaderGolden.Run(const AInput: TStrings): TStringList;
var
  LLine: string;
  LFile: string;
  LInFile: Boolean;
  LBytes: TBytes;
begin
  Result := TStringList.Create;
  FLines := Result;
  FFiles := TDictionary<string, TBytes>.Create;
  LInFile := False;
  try
    for LLine in AInput do
    begin
      if LLine.StartsWith('@case ') then
      begin
        FFiles.Clear;
        LInFile := False;
        Emit('## ' + Copy(LLine, 7, MaxInt));
      end
      else if LLine = '@end' then
        LInFile := False
      else if LLine.StartsWith('@file ') then
      begin
        LFile := Copy(LLine, 7, MaxInt);
        FFiles.AddOrSetValue(LFile, nil);
        LInFile := True;
      end
      else if LLine.StartsWith('@op ') then
      begin
        LInFile := False;
        Execute(Copy(LLine, 5, MaxInt));
      end
      else if LInFile then
      begin
        FFiles.TryGetValue(LFile, LBytes);
        AddTokens(LBytes, LLine);
        FFiles.AddOrSetValue(LFile, LBytes);
      end;
    end;
  finally
    FreeAndNil(FFiles);
    FLines := nil;
  end;
end;

procedure TTestWaveHeaderGolden.DovrebbeDareLeStesseRisposteDelVeroIdWaveFile;
var
  LInput, LGolden, LActual: TStringList;
  LIndex: Integer;
begin
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LActual := nil;
  try
    LInput.LoadFromFile(DataFolder + 'wave.input.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'wave.golden.txt', TEncoding.ANSI);
    LActual := Run(LInput);
    for LIndex := 0 to LGolden.Count - 1 do
      if (LIndex >= LActual.Count) or (LGolden[LIndex] <> LActual[LIndex]) then
      begin
        LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.wave.actual.txt'));
        if LIndex < LActual.Count then
          Assert.Fail(Format('line %d: expected [%s] but got [%s]', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]))
        else
          Assert.Fail(Format('line %d: expected [%s] but the output ended', [LIndex + 1, LGolden[LIndex]]));
      end;
    Assert.AreEqual(LGolden.Count, LActual.Count);
  finally
    LActual.Free;
    LGolden.Free;
    LInput.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWaveHeaderReader);
  TDUnitX.RegisterTestFixture(TTestWaveHeaderGolden);

end.
