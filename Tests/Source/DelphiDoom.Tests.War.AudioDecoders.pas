{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - readers of VOC and WAV and the       }
{  resampler, with parity on the C of the remake                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AudioDecoders;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Audio.Types;

type
  /// <summary>
  ///   audio.synth.golden.txt is the output of war_audio_ref.exe: mv_read_memory, mw_read_memory and the resampler
  ///   ORIGINAL of shl/voc.h and shl/wav.h (MIT) compiled with gcc on inputs built by the harness. Each line says
  ///   how the input is built (kind, a, b, c, len) and what the original gave: format, length and CRC-32 of the
  ///   samples read, length and CRC-32 of the samples at 44100 Hz. The last number is how many bytes at the end
  ///   the original reads past its buffer (the CRC leaves them out)
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarAudioDecoders = class(TObject)
  private
    function Golden: TStringList;
    procedure CheckLine(const ALine: string);
    function Resampled(const ASource: TBytes; AIsVoc: Boolean; out AInfo: TWarPcmBuffer): TBytes;
    function Silence(ARate, ABits, AChannels, ALength: Cardinal): TWarPcmBuffer;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCodiceOriginaleSuiCasiSintetici;
    [Test]
    procedure DovrebbeAvereCasiPerOgniFamigliaDiBlocchi;
    [Test]
    procedure DovrebbeRifiutareUnVocSenzaDati;
    [Test]
    procedure DovrebbeRifiutareUnWavSenzaRiff;
    [Test]
    procedure DovrebbeLeggereUnWavConDatiVuotiMaNonRicampionarlo;
    [Test]
    procedure DovrebbeCopiareSeLaFrequenzaEGiaQuellaVoluta;
    [Test]
    procedure DovrebbeRifiutareUnFormatoCheIlCNonSaInterpolare;
    [Test]
    procedure DovrebbeRifiutareUnaFrequenzaDiDestinazioneZero;
    [Test]
    procedure DovrebbeInterpolareConLoShiftAritmeticoSuiNegativi;
    [Test]
    procedure DovrebbeUsareLUltimoCampioneDoveIlCLeggeOltreIlBuffer;
    [Test]
    procedure DovrebbeRaddoppiareEQuadruplicareAUnCanaleA8Bit;
    [Test]
    procedure DovrebbeDimezzareEDividerePerQuattroAUnCanaleA8Bit;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.War.RealData, DelphiDoom.Tests.War.AudioSupport, DelphiDoom.War.Audio.VocDecoder,
  DelphiDoom.War.Audio.WavDecoder, DelphiDoom.War.Audio.Resampler;

function Split(const ALine: string): TArray<string>;
begin
  Result := ALine.Split([' ']);
end;

{ TTestWarAudioDecoders }

function TTestWarAudioDecoders.Golden: TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TWarRealData.GoldenPath('audio.synth.golden.txt'));
end;

function TTestWarAudioDecoders.Silence(ARate, ABits, AChannels, ALength: Cardinal): TWarPcmBuffer;
begin
  Result.SampleRate := ARate;
  Result.BitsPerSample := ABits;
  Result.Channels := AChannels;
  SetLength(Result.Data, ALength);
end;

function TTestWarAudioDecoders.Resampled(const ASource: TBytes; AIsVoc: Boolean; out AInfo: TWarPcmBuffer): TBytes;
var
  LOk: Boolean;
begin
  if AIsVoc then
    LOk := TWarVocDecoder.TryDecode(ASource, AInfo)
  else
    LOk := TWarWavDecoder.TryDecode(ASource, AInfo);
  Assert.IsTrue(LOk);
  Result := TWarPcmResampler.Resample(AInfo, WAR_PLAYBACK_RATE).Data;
end;

procedure TTestWarAudioDecoders.CheckLine(const ALine: string);
var
  LFields: TArray<string>;
  LKind: Integer;
  LA, LB, LC, LLen: Cardinal;
  LInput: TBytes;
  LRead: TWarPcmBuffer;
  LOk: Boolean;
  LOut: TWarPcmBuffer;
  LTail: Integer;
begin
  LFields := Split(ALine);
  LKind := StrToInt(LFields[2]);
  LA := StrToUInt64(LFields[3]);
  LB := StrToUInt64(LFields[4]);
  LC := StrToUInt64(LFields[5]);
  LLen := StrToUInt64(LFields[6]);
  if LFields[0] = 'V' then
  begin
    LInput := TWarSyntheticAudio.Voc(LKind, LA, LB, LC, LLen);
    LOk := TWarVocDecoder.TryDecode(LInput, LRead);
  end
  else
  begin
    LInput := TWarSyntheticAudio.Wav(LKind, LA, LB, LC, LLen);
    LOk := TWarWavDecoder.TryDecode(LInput, LRead);
  end;
  if LFields[7] = 'FAIL' then
  begin
    Assert.IsFalse(LOk, LFields[1]);
    Exit;
  end;
  Assert.IsTrue(LOk, LFields[1]);
  if (LFields[7] = 'UNSAFE') or (LFields[7] = 'RESAMPLEFAIL') then
  begin
    // where the original crashes (division by zero) or refuses (nothing to resample) the library raises
    Assert.WillRaise(
      procedure
      begin
        TWarPcmResampler.Resample(LRead, WAR_PLAYBACK_RATE);
      end, EWarException, LFields[1]);
    Exit;
  end;
  Assert.AreEqual(StrToUInt64(LFields[7]), UInt64(LRead.Channels), LFields[1] + ' canali');
  Assert.AreEqual(StrToUInt64(LFields[8]), UInt64(LRead.SampleRate), LFields[1] + ' frequenza');
  Assert.AreEqual(StrToUInt64(LFields[9]), UInt64(LRead.BitsPerSample), LFields[1] + ' bit');
  Assert.AreEqual(StrToUInt64(LFields[10]), UInt64(Length(LRead.Data)), LFields[1] + ' byte letti');
  Assert.AreEqual(LFields[11], TWarAudioHash.Of_(LRead.Data, Length(LRead.Data)), LFields[1] + ' CRC letti');
  LOut := TWarPcmResampler.Resample(LRead, WAR_PLAYBACK_RATE);
  Assert.AreEqual(StrToUInt64(LFields[12]), UInt64(Length(LOut.Data)), LFields[1] + ' byte ricampionati');
  LTail := StrToInt(LFields[14]);
  Assert.AreEqual(LFields[13], TWarAudioHash.Of_(LOut.Data, Length(LOut.Data) - LTail), LFields[1] + ' CRC ricampionati');
end;

procedure TTestWarAudioDecoders.DovrebbeDareLeStesseRisposteDelCodiceOriginaleSuiCasiSintetici;
var
  LGolden: TStringList;
  LLine: string;
begin
  LGolden := Golden;
  try
    for LLine in LGolden do
      CheckLine(LLine);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarAudioDecoders.DovrebbeAvereCasiPerOgniFamigliaDiBlocchi;
var
  LGolden: TStringList;
  LLine: string;
  LVoc, LWav, LFail: Integer;
begin
  LGolden := Golden;
  try
    LVoc := 0;
    LWav := 0;
    LFail := 0;
    for LLine in LGolden do
    begin
      if LLine.StartsWith('V ') then Inc(LVoc);
      if LLine.StartsWith('W ') then Inc(LWav);
      if LLine.EndsWith(' FAIL') then Inc(LFail);
    end;
    Assert.AreEqual(39, LVoc);
    Assert.AreEqual(18, LWav);
    Assert.AreEqual(12, LFail);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarAudioDecoders.DovrebbeRifiutareUnVocSenzaDati;
var
  LBuffer: TWarPcmBuffer;
begin
  Assert.IsFalse(TWarVocDecoder.TryDecode(nil, LBuffer));
  Assert.IsFalse(TWarVocDecoder.TryDecode(TWarSyntheticAudio.Voc(14, 0, 0, 0, 0), LBuffer));
end;

procedure TTestWarAudioDecoders.DovrebbeRifiutareUnWavSenzaRiff;
var
  LBuffer: TWarPcmBuffer;
begin
  Assert.IsFalse(TWarWavDecoder.TryDecode(nil, LBuffer));
  Assert.IsFalse(TWarWavDecoder.TryDecode(TWarSyntheticAudio.Wav(4, 22050, 8, 1, 100), LBuffer));
end;

procedure TTestWarAudioDecoders.DovrebbeLeggereUnWavConDatiVuotiMaNonRicampionarlo;
var
  LBuffer: TWarPcmBuffer;
begin
  Assert.IsTrue(TWarWavDecoder.TryDecode(TWarSyntheticAudio.Wav(1, 22050, 8, 1, 0), LBuffer));
  Assert.AreEqual<Integer>(0, Length(LBuffer.Data));
  Assert.WillRaise(
    procedure
    begin
      TWarPcmResampler.Resample(LBuffer, WAR_PLAYBACK_RATE);
    end, EWarException);
end;

procedure TTestWarAudioDecoders.DovrebbeCopiareSeLaFrequenzaEGiaQuellaVoluta;
var
  LSource: TWarPcmBuffer;
  LResult: TWarPcmBuffer;
begin
  // also for a format the interpolation does not know: the original copies before it looks at the format
  LSource := Silence(44100, 24, 3, 9);
  LSource.Data[4] := 77;
  LResult := TWarPcmResampler.Resample(LSource, 44100);
  Assert.AreEqual<Integer>(9, Length(LResult.Data));
  Assert.AreEqual<Integer>(77, LResult.Data[4]);
  LResult.Data[4] := 1;
  Assert.AreEqual<Integer>(77, LSource.Data[4], 'e una copia');
end;

procedure TTestWarAudioDecoders.DovrebbeRifiutareUnFormatoCheIlCNonSaInterpolare;
var
  LSource: TWarPcmBuffer;
begin
  // the original divides by zero with no channels or fewer than 8 bits and leaves the output unwritten for 24 bits
  LSource := Silence(22050, 24, 1, 30);
  Assert.WillRaise(
    procedure
    begin
      TWarPcmResampler.Resample(LSource, 44100);
    end, EWarException);
  LSource := Silence(22050, 8, 0, 30);
  Assert.WillRaise(
    procedure
    begin
      TWarPcmResampler.Resample(LSource, 44100);
    end, EWarException);
end;

procedure TTestWarAudioDecoders.DovrebbeRifiutareUnaFrequenzaDiDestinazioneZero;
var
  LSource: TWarPcmBuffer;
begin
  LSource := Silence(22050, 8, 1, 30);
  Assert.WillRaise(
    procedure
    begin
      TWarPcmResampler.Resample(LSource, 0);
    end, EWarException);
end;

procedure TTestWarAudioDecoders.DovrebbeInterpolareConLoShiftAritmeticoSuiNegativi;
var
  LSource, LResult: TWarPcmBuffer;
begin
  // 200 then 100 doubled: the middle is 200 + ((100 - 200) >> 1) = 150; and with a step of 3/4 of a sample
  LSource := Silence(22050, 8, 1, 2);
  LSource.Data[0] := 200;
  LSource.Data[1] := 100;
  LResult := TWarPcmResampler.Resample(LSource, 44100);
  Assert.AreEqual<Integer>(200, LResult.Data[0]);
  Assert.AreEqual<Integer>(150, LResult.Data[1]);
  Assert.AreEqual<Integer>(100, LResult.Data[2]);
  Assert.AreEqual<Integer>(100, LResult.Data[3]);
  // four times: (-100 * 1) >> 2 is -25 (arithmetic), and (-100 * 3) >> 2 = -75
  LSource := Silence(11025, 8, 1, 2);
  LSource.Data[0] := 200;
  LSource.Data[1] := 100;
  LResult := TWarPcmResampler.Resample(LSource, 44100);
  Assert.AreEqual<Integer>(175, LResult.Data[1]);
  Assert.AreEqual<Integer>(150, LResult.Data[2]);
  Assert.AreEqual<Integer>(125, LResult.Data[3]);
  // -1 >> 2 is -1 and not a huge number: 101 then 100 with 4x gives 101 + ((-1 * 1) >> 2) = 100
  LSource.Data[0] := 101;
  LSource.Data[1] := 100;
  LResult := TWarPcmResampler.Resample(LSource, 44100);
  Assert.AreEqual<Integer>(100, LResult.Data[1]);
end;

procedure TTestWarAudioDecoders.DovrebbeUsareLUltimoCampioneDoveIlCLeggeOltreIlBuffer;
var
  LSource, LResult: TWarPcmBuffer;
  LIndex: Integer;
begin
  // 11111 Hz mono 8 bit, 24192 samples (the building sounds of the game): the step rounds up and the original
  // reads one byte past the end for the last output sample; here that sample is the last of the source
  LSource := Silence(11111, 8, 1, 24192);
  for LIndex := 0 to High(LSource.Data) do
    LSource.Data[LIndex] := Byte(LIndex * 13 + 7);
  LResult := TWarPcmResampler.Resample(LSource, 44100);
  Assert.AreEqual<Integer>(96019, Length(LResult.Data));
  Assert.AreEqual<Integer>(LSource.Data[High(LSource.Data)], LResult.Data[High(LResult.Data)]);
end;

procedure TTestWarAudioDecoders.DovrebbeRaddoppiareEQuadruplicareAUnCanaleA8Bit;
var
  LSource, LResult: TWarPcmBuffer;
begin
  LSource := Silence(22050, 8, 1, 3);
  LSource.Data[0] := 0; LSource.Data[1] := 10; LSource.Data[2] := 20;
  LResult := TWarPcmResampler.Resample(LSource, 44100);
  Assert.AreEqual<Integer>(6, Length(LResult.Data));
  Assert.AreEqual<Integer>(5, LResult.Data[1]);
  Assert.AreEqual<Integer>(20, LResult.Data[4]);
  Assert.AreEqual<Integer>(20, LResult.Data[5]);
  LSource.SampleRate := 11025;
  LResult := TWarPcmResampler.Resample(LSource, 44100);
  Assert.AreEqual<Integer>(12, Length(LResult.Data));
  Assert.AreEqual<Integer>(2, LResult.Data[1]);
  Assert.AreEqual<Integer>(5, LResult.Data[2]);
  Assert.AreEqual<Integer>(7, LResult.Data[3]);
end;

procedure TTestWarAudioDecoders.DovrebbeDimezzareEDividerePerQuattroAUnCanaleA8Bit;
var
  LSource, LResult: TWarPcmBuffer;
begin
  LSource := Silence(88200, 8, 1, 8);
  LSource.Data[0] := 10; LSource.Data[1] := 20; LSource.Data[2] := 30; LSource.Data[3] := 41;
  LResult := TWarPcmResampler.Resample(LSource, 44100);
  Assert.AreEqual<Integer>(4, Length(LResult.Data));
  Assert.AreEqual<Integer>(15, LResult.Data[0]);
  Assert.AreEqual<Integer>(35, LResult.Data[1]);
  LSource.SampleRate := 176400;
  LResult := TWarPcmResampler.Resample(LSource, 44100);
  Assert.AreEqual<Integer>(2, Length(LResult.Data));
  Assert.AreEqual<Integer>(25, LResult.Data[0]);
end;

end.
