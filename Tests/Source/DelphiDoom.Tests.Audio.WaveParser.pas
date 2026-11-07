{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - the headers of the sounds          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.WaveParser;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder,
  DelphiDoom.Logging.Factory,
  DelphiDoom.Audio.Types, DelphiDoom.Audio.SoundParameters, DelphiDoom.Audio.WaveParser;

type
  /// <summary>
  ///   Tests\Data\Audio\audio.golden.txt was written by the old I_CacheSFX of i_sound (the file
  ///   and the lump parts, copied as they were in a harness out of the repository) on the inputs
  ///   of TAudioScenarios: the parser and TSfxSoundParameters must give the same parameters and
  ///   the same warnings
  /// </summary>
  [TestFixture]
  [Category('audio')]
  TTestAudioWaveParser = class(TObject)
  private
    FGolden: TDictionary<string, string>;
    FRecorder: TLogRecorder;
    FRecorderIntf: ILogSink;
    FLog: ILog;
    function ParametersText(const AParameters: TSfxSoundParameters): string;
    function WarningsText: string;
    procedure Check(const AKey, AActual: string);
    function Wave(AFormatLength, ADataLength: Integer; AShifted: Boolean): TBytes;
    function EmptyChunks: TSfxWaveChunks;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereILumpComeIlVecchioCodice;
    [Test]
    procedure DovrebbeLeggereIFileComeIlVecchioCodice;
    [Test]
    procedure DovrebbeLeggereUnWavValidoInUnLump;
    [Test]
    procedure DovrebbeTrovareUnChunkSpostatoDiDueByte;
    [Test]
    procedure DovrebbeLeggereUnSuonoDmx;
    [Test]
    procedure DovrebbeRiconoscereIlRiff;
    [Test]
    procedure DovrebbeRifiutareUnFileConDatiDiLunghezzaNegativa;
    [Test]
    procedure DovrebbeRifiutareUnLumpConDatiDiLunghezzaNegativa;
    [Test]
    procedure DovrebbeAccettareUnFileSenzaLog;
    [Test]
    procedure DovrebbeNonRileggereIDatiGiaTrovati;
    [Test]
    procedure DovrebbeDareIlCampioneDeiParametri;
  end;

implementation

uses
  DelphiDoom.Tests.Audio.Scenarios;

const
  RIFF_ID = $46464952;
  WAVE_ID = $45564157;
  FMT_ID = $20746D66;
  DATA_ID = $61746164;

procedure PutLong(var ABytes: TBytes; APosition: Integer; AValue: Cardinal);
begin
  ABytes[APosition] := AValue and $FF;
  ABytes[APosition + 1] := (AValue shr 8) and $FF;
  ABytes[APosition + 2] := (AValue shr 16) and $FF;
  ABytes[APosition + 3] := AValue shr 24;
end;

{ TTestAudioWaveParser }

procedure TTestAudioWaveParser.Setup;
var
  LLines: TStringList;
  LIndex: Integer;
  LSeparator: Integer;
begin
  FRecorder := TLogRecorder.Create;
  FRecorderIntf := FRecorder;
  FLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(FRecorderIntf), nil);
  FGolden := TDictionary<string, string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\Tests\Data\Audio\audio.golden.txt')));
    for LIndex := 0 to LLines.Count - 1 do
    begin
      LSeparator := Pos('=', LLines[LIndex]);
      if LSeparator > 1 then
        FGolden.Add(Copy(LLines[LIndex], 1, LSeparator - 1), Copy(LLines[LIndex], LSeparator + 1, MaxInt));
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestAudioWaveParser.TearDown;
begin
  FGolden.Free;
  FLog := nil;
  FRecorderIntf := nil;
end;

function TTestAudioWaveParser.EmptyChunks: TSfxWaveChunks;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function TTestAudioWaveParser.ParametersText(const AParameters: TSfxSoundParameters): string;
begin
  Result := Format('%d,%d,%d,%d,%d,%d,%d,%d', [AParameters.Length, AParameters.Offset,
    AParameters.Format.Tag, AParameters.Format.SamplesPerSecond,
    AParameters.Format.AverageBytesPerSecond, AParameters.Format.BitsPerSample,
    AParameters.Format.Channels, Ord(AParameters.Status)]);
end;

function TTestAudioWaveParser.WarningsText: string;
const
  PREFIX = 'I_Warning: ';
var
  LIndex: Integer;
  LText: string;
begin
  // every warning goes to two channels: the file of the errors is enough
  Result := '';
  for LIndex := 0 to FRecorder.Count - 1 do
    if FRecorder[LIndex].Channel = TLogChannel.ErrorFile then
    begin
      LText := FRecorder[LIndex].Text;
      if LText.StartsWith(PREFIX) then
        LText := Copy(LText, Length(PREFIX) + 1, MaxInt);
      Result := Result + '|' + StringReplace(LText, #13#10, '\n', [rfReplaceAll]);
    end;
  FRecorder.Clear;
end;

procedure TTestAudioWaveParser.Check(const AKey, AActual: string);
var
  LExpected: string;
begin
  Assert.IsTrue(FGolden.TryGetValue(AKey, LExpected), 'missing golden key ' + AKey);
  Assert.AreEqual(LExpected, AActual, AKey);
end;

function TTestAudioWaveParser.Wave(AFormatLength, ADataLength: Integer; AShifted: Boolean): TBytes;
var
  LData: Integer;
begin
  // RIFF, WAVE, fmt, [an odd chunk], data
  SetLength(Result, 12 + 8 + AFormatLength + Ord(AShifted) * 10 + 8 + ADataLength);
  FillChar(Result[0], Length(Result), 0);
  PutLong(Result, 0, RIFF_ID);
  PutLong(Result, 4, Length(Result) - 8);
  PutLong(Result, 8, WAVE_ID);
  PutLong(Result, 12, FMT_ID);
  PutLong(Result, 16, AFormatLength);
  Result[20] := 1;
  Result[22] := 2;
  PutLong(Result, 24, 22050);
  PutLong(Result, 28, 88200);
  Result[34] := 16;
  LData := 12 + 8 + AFormatLength;
  if AShifted then
  begin
    PutLong(Result, LData, $6B6E756A);
    PutLong(Result, LData + 4, 2);
    LData := LData + 10;
  end;
  PutLong(Result, LData, DATA_ID);
  PutLong(Result, LData + 4, ADataLength);
end;

procedure TTestAudioWaveParser.DovrebbeLeggereILumpComeIlVecchioCodice;
var
  LCases: TArray<TBytes>;
  LIndex: Integer;
  LFlags: Integer;
  LChunks: TSfxWaveChunks;
  LParameters: TSfxSoundParameters;
  LComplete: Boolean;
begin
  LCases := TAudioScenarios.WaveLumps;
  for LIndex := 0 to High(LCases) do
    for LFlags := 0 to 2 do
    begin
      FillChar(LParameters, SizeOf(LParameters), 0);
      LChunks := EmptyChunks;
      LChunks.FormatDone := LFlags = 1;
      LChunks.DataDone := LFlags = 2;
      LComplete := TSfxWaveParser.ParseLump(PByte(LCases[LIndex]), Length(LCases[LIndex]),
        'L' + IntToStr(LIndex), FLog, LChunks);
      LParameters.ApplyLump(LChunks, LComplete);
      Check(Format('lump.%d.%d', [LIndex, LFlags]), Format('%s,%d,%d%s', [ParametersText(LParameters),
        Ord(LChunks.FormatDone), Ord(LChunks.DataDone), WarningsText]));
    end;
end;

procedure TTestAudioWaveParser.DovrebbeLeggereIFileComeIlVecchioCodice;
var
  LCases: TArray<TBytes>;
  LIndex: Integer;
  LChunks: TSfxWaveChunks;
  LParameters: TSfxSoundParameters;
  LAccepted: Boolean;
  LHash: string;
begin
  LCases := TAudioScenarios.WaveFiles;
  for LIndex := 0 to High(LCases) do
  begin
    FillChar(LParameters, SizeOf(LParameters), 0);
    LChunks := EmptyChunks;
    LAccepted := TSfxWaveParser.ParseFile(LCases[LIndex], 'F' + IntToStr(LIndex), FLog, LChunks);
    LParameters.ApplyFile(LChunks, LAccepted);
    if LChunks.DataFound then
      LHash := TAudioScenarios.Fingerprint(@LCases[LIndex][LChunks.DataOffset], LChunks.DataLength)
    else
      LHash := '-';
    Check(Format('file.%d', [LIndex]), Format('%s,%d,%d,%d,%s%s', [ParametersText(LParameters),
      Ord(LChunks.FormatDone), Ord(LChunks.DataDone), Ord(LAccepted), LHash, WarningsText]));
  end;
end;

procedure TTestAudioWaveParser.DovrebbeLeggereUnWavValidoInUnLump;
var
  LBytes: TBytes;
  LChunks: TSfxWaveChunks;
begin
  LBytes := Wave(16, 40, False);
  LChunks := EmptyChunks;
  Assert.IsTrue(TSfxWaveParser.ParseLump(PByte(LBytes), Length(LBytes), 'pistol', FLog, LChunks));
  Assert.IsTrue(LChunks.FormatFound);
  Assert.AreEqual<Integer>(1, LChunks.Format.Tag);
  Assert.AreEqual<Integer>(2, LChunks.Format.Channels);
  Assert.AreEqual<Cardinal>(22050, LChunks.Format.SamplesPerSecond);
  Assert.AreEqual<Cardinal>(88200, LChunks.Format.AverageBytesPerSecond);
  Assert.AreEqual<Integer>(16, LChunks.Format.BitsPerSample);
  Assert.IsTrue(LChunks.DataFound);
  Assert.AreEqual(44, LChunks.DataOffset);
  Assert.AreEqual(40, LChunks.DataLength);
  Assert.AreEqual('', WarningsText);
end;

procedure TTestAudioWaveParser.DovrebbeTrovareUnChunkSpostatoDiDueByte;
var
  LBytes: TBytes;
  LChunks: TSfxWaveChunks;
begin
  // an odd chunk of 2 bytes puts data at 46: two bytes after a long word
  LBytes := Wave(16, 24, True);
  LChunks := EmptyChunks;
  Assert.IsTrue(TSfxWaveParser.ParseLump(PByte(LBytes), Length(LBytes), 'odd', FLog, LChunks));
  Assert.AreEqual(54, LChunks.DataOffset);
  Assert.AreEqual(24, LChunks.DataLength);
end;

procedure TTestAudioWaveParser.DovrebbeLeggereUnSuonoDmx;
var
  LBytes: TBytes;
  LChunks: TSfxWaveChunks;
begin
  LBytes := TBytes.Create(3, 0, $11, $2B, 4, 0, 0, 0, $80, $81, $82, $83);
  LChunks := EmptyChunks;
  Assert.IsFalse(TSfxWaveParser.ParseLump(PByte(LBytes), Length(LBytes), 'dmx', FLog, LChunks));
  Assert.IsTrue(LChunks.FormatFound and LChunks.DataFound);
  Assert.AreEqual<Cardinal>($2B11, LChunks.Format.SamplesPerSecond);
  Assert.AreEqual<Cardinal>($2B11, LChunks.Format.AverageBytesPerSecond);
  Assert.AreEqual<Integer>(8, LChunks.Format.BitsPerSample);
  Assert.AreEqual<Integer>(1, LChunks.Format.Channels);
  Assert.AreEqual(8, LChunks.DataOffset);
  Assert.AreEqual(12, LChunks.DataLength);
end;

procedure TTestAudioWaveParser.DovrebbeRiconoscereIlRiff;
var
  LBytes: TBytes;
begin
  LBytes := Wave(16, 0, False);
  Assert.IsTrue(TSfxWaveParser.IsRiff(PByte(LBytes), Length(LBytes)));
  Assert.IsFalse(TSfxWaveParser.IsRiff(PByte(LBytes), 3));
  Assert.IsFalse(TSfxWaveParser.IsRiff(nil, 100));
  LBytes[0] := 0;
  Assert.IsFalse(TSfxWaveParser.IsRiff(PByte(LBytes), Length(LBytes)));
end;

procedure TTestAudioWaveParser.DovrebbeRifiutareUnFileConDatiDiLunghezzaNegativa;
var
  LBytes: TBytes;
  LChunks: TSfxWaveChunks;
begin
  // the old code gave Z_Malloc a negative length
  LBytes := Wave(16, 8, False);
  PutLong(LBytes, 40, $FFFFFFF0);
  LChunks := EmptyChunks;
  Assert.IsFalse(TSfxWaveParser.ParseFile(LBytes, 'neg', FLog, LChunks));
  Assert.IsFalse(LChunks.DataDone);
  Assert.AreEqual('|CacheSFX(): Sound neg.wav has invalid data CHUNK\n', WarningsText);
end;

procedure TTestAudioWaveParser.DovrebbeRifiutareUnLumpConDatiDiLunghezzaNegativa;
var
  LBytes: TBytes;
  LChunks: TSfxWaveChunks;
begin
  LBytes := Wave(16, 8, False);
  PutLong(LBytes, 40, $FFFFFFF0);
  LChunks := EmptyChunks;
  Assert.IsFalse(TSfxWaveParser.ParseLump(PByte(LBytes), Length(LBytes), 'neg', FLog, LChunks));
  Assert.IsFalse(LChunks.DataFound);
  Assert.AreEqual('|CacheSFX(): Sound neg has invalid data CHUNK\n', WarningsText);
end;

procedure TTestAudioWaveParser.DovrebbeAccettareUnFileSenzaLog;
var
  LBytes: TBytes;
  LChunks: TSfxWaveChunks;
begin
  LBytes := Wave(12, 8, False);
  LChunks := EmptyChunks;
  Assert.IsFalse(TSfxWaveParser.ParseFile(LBytes, 'short', nil, LChunks));
  LBytes := Wave(16, 8, False);
  LChunks := EmptyChunks;
  Assert.IsTrue(TSfxWaveParser.ParseFile(LBytes, 'good', nil, LChunks));
  Assert.AreEqual(44, LChunks.DataOffset);
end;

procedure TTestAudioWaveParser.DovrebbeNonRileggereIDatiGiaTrovati;
var
  LBytes: TBytes;
  LChunks: TSfxWaveChunks;
begin
  // the file out of the WAD gave the samples: the lump gives only the format
  LBytes := Wave(16, 8, False);
  LChunks := EmptyChunks;
  LChunks.DataDone := True;
  Assert.IsTrue(TSfxWaveParser.ParseLump(PByte(LBytes), Length(LBytes), 'mix', FLog, LChunks));
  Assert.IsTrue(LChunks.FormatFound);
  Assert.IsFalse(LChunks.DataFound);
end;

procedure TTestAudioWaveParser.DovrebbeDareIlCampioneDeiParametri;
var
  LParameters: TSfxSoundParameters;
  LChunks: TSfxWaveChunks;
  LSample: TSfxSample;
  LByte: Byte;
begin
  FillChar(LParameters, SizeOf(LParameters), 0);
  LChunks := EmptyChunks;
  LChunks.FormatFound := True;
  LChunks.Format.Tag := 1;
  LChunks.Format.Channels := 258;
  LChunks.Format.BitsPerSample := 264;
  LChunks.Format.SamplesPerSecond := 11025;
  LChunks.DataFound := True;
  LChunks.DataOffset := 40;
  LChunks.DataLength := 100;
  LChunks.FormatDone := True;
  LChunks.DataDone := True;
  LParameters.ApplyFile(LChunks, True);
  LSample := LParameters.ToSample(@LByte);
  // the samples of a file have a block of their own; channels and bits are bytes
  Assert.AreEqual(0, LSample.Offset);
  Assert.AreEqual(100, LSample.Length);
  Assert.AreEqual<Integer>(2, LSample.Format.Channels);
  Assert.AreEqual<Integer>(8, LSample.Format.BitsPerSample);
  Assert.IsTrue(LSample.IsExternal);
  Assert.IsTrue(LSample.Data = @LByte);
  LParameters.ApplyLump(LChunks, False);
  Assert.AreEqual(40, LParameters.Offset);
  Assert.IsTrue(LParameters.Status = TSfxWaveStatus.ExternalWave);
  LParameters.ApplyLump(LChunks, True);
  Assert.IsFalse(LParameters.ToSample(nil).IsExternal);
end;

end.
