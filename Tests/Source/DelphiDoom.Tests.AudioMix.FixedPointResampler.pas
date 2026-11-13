{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - the resampler with a       }
{  16.16 position, against a copy of the one of the war library as it was       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.FixedPointResampler;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.AudioMix.Types, DelphiDoom.AudioMix.Intf,
  DelphiDoom.AudioMix.FixedPointResampler, DelphiDoom.Tests.AudioMix.LegacyFixedPointResampler;

type
  [TestFixture]
  [Category('audiomix')]
  TTestAudioMixFixedPointResampler = class
  strict private
    function Buffer(ASeed: Cardinal; AChannels, ABits, ARate, ASamples: Integer): TPcmBuffer;
    procedure SameBuffer(const AExpected, AActual: TPcmBuffer; const AText: string);
  public
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioSuTuttiIFormati;
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioNeiCasiVeloci;
    [Test]
    procedure DovrebbeCopiareAlloStessoRate;
    [Test]
    procedure DovrebbeRifiutareUnBufferVuotoEUnRateZero;
    [Test]
    procedure DovrebbeRifiutareUnFormatoNonInterpolabile;
    [Test]
    procedure DovrebbeEssereUnIPcmResampler;
  end;

implementation

uses
  DelphiDoom.Tests.AudioMix.Support;

function TTestAudioMixFixedPointResampler.Buffer(ASeed: Cardinal; AChannels, ABits, ARate, ASamples: Integer): TPcmBuffer;
var
  LRandom: TAudioMixLcg;
  LIndex: Integer;
begin
  LRandom := TAudioMixLcg.Create(ASeed);
  try
    Result.Channels := AChannels;
    Result.BitsPerSample := ABits;
    Result.SampleRate := ARate;
    SetLength(Result.Data, ASamples * AChannels * (ABits div 8));
    for LIndex := 0 to High(Result.Data) do
      Result.Data[LIndex] := Byte(LRandom.Next(256));
  finally
    LRandom.Free;
  end;
end;

procedure TTestAudioMixFixedPointResampler.SameBuffer(const AExpected, AActual: TPcmBuffer; const AText: string);
begin
  Assert.AreEqual<Cardinal>(AExpected.Channels, AActual.Channels, AText);
  Assert.AreEqual<Cardinal>(AExpected.BitsPerSample, AActual.BitsPerSample, AText);
  Assert.AreEqual<Cardinal>(AExpected.SampleRate, AActual.SampleRate, AText);
  Assert.AreEqual<Integer>(Length(AExpected.Data), Length(AActual.Data), AText);
  if Length(AExpected.Data) > 0 then
    Assert.IsTrue(CompareMem(@AExpected.Data[0], @AActual.Data[0], Length(AExpected.Data)), AText);
end;

procedure TTestAudioMixFixedPointResampler.DovrebbeDareGliStessiByteDelVecchioSuTuttiIFormati;
const
  RATES: array[0..8] of Integer = (8000, 11025, 11111, 22050, 32000, 44100, 48000, 96000, 5512);
  SIZES: array[0..5] of Integer = (1, 2, 3, 17, 255, 1000);
var
  LChannels, LBits, LSource, LTarget, LSize: Integer;
  LInput: TPcmBuffer;
  LSeed: Cardinal;
begin
  LSeed := 1;
  for LChannels := 1 to 2 do
    for LBits := 1 to 2 do
      for LSource := 0 to High(RATES) do
        for LTarget := 0 to High(RATES) do
          for LSize := 0 to High(SIZES) do
          begin
            Inc(LSeed);
            LInput := Buffer(LSeed, LChannels, LBits * 8, RATES[LSource], SIZES[LSize]);
            SameBuffer(TLegacyFixedPointResampler.Resample(LInput, RATES[LTarget]),
              TPcmFixedPointResampler.Convert(LInput, RATES[LTarget]),
              Format('%d canali %d bit %d -> %d, %d campioni', [LChannels, LBits * 8, RATES[LSource],
              RATES[LTarget], SIZES[LSize]]));
          end;
end;

procedure TTestAudioMixFixedPointResampler.DovrebbeDareGliStessiByteDelVecchioNeiCasiVeloci;
const
  SIZES: array[0..6] of Integer = (2, 3, 4, 5, 8, 101, 1000);
var
  LInput: TPcmBuffer;
  LSamples, LSize: Integer;
begin
  // 8 bit mono and a ratio of 2 or 4, both ways: the paths that do not interpolate
  for LSize := 0 to High(SIZES) do
  begin
    LSamples := SIZES[LSize];
    LInput := Buffer(LSamples, 1, 8, 11025, LSamples);
    SameBuffer(TLegacyFixedPointResampler.Resample(LInput, 22050), TPcmFixedPointResampler.Convert(LInput, 22050), 'x2');
    SameBuffer(TLegacyFixedPointResampler.Resample(LInput, 44100), TPcmFixedPointResampler.Convert(LInput, 44100), 'x4');
    LInput := Buffer(LSamples, 1, 8, 44100, LSamples);
    SameBuffer(TLegacyFixedPointResampler.Resample(LInput, 22050), TPcmFixedPointResampler.Convert(LInput, 22050), '/2');
    SameBuffer(TLegacyFixedPointResampler.Resample(LInput, 11025), TPcmFixedPointResampler.Convert(LInput, 11025), '/4');
  end;
end;

procedure TTestAudioMixFixedPointResampler.DovrebbeCopiareAlloStessoRate;
var
  LInput, LOutput: TPcmBuffer;
begin
  LInput := Buffer(7, 2, 16, 22050, 40);
  LOutput := TPcmFixedPointResampler.Convert(LInput, 22050);
  SameBuffer(LInput, LOutput, 'stesso rate');
  LOutput.Data[0] := LOutput.Data[0] xor $FF;
  Assert.AreNotEqual<Integer>(LInput.Data[0], LOutput.Data[0], 'e una copia');
end;

procedure TTestAudioMixFixedPointResampler.DovrebbeRifiutareUnBufferVuotoEUnRateZero;
var
  LEmpty: TPcmBuffer;
  LInput: TPcmBuffer;
begin
  LEmpty := Buffer(1, 1, 8, 11025, 0);
  Assert.WillRaise(
    procedure
    begin
      TPcmFixedPointResampler.Convert(LEmpty, 44100);
    end, EAudioMixException);
  LInput := Buffer(1, 1, 8, 11025, 10);
  Assert.WillRaise(
    procedure
    begin
      TPcmFixedPointResampler.Convert(LInput, 0);
    end, EAudioMixException);
end;

procedure TTestAudioMixFixedPointResampler.DovrebbeRifiutareUnFormatoNonInterpolabile;
var
  LTwelveBits: TPcmBuffer;
  LNoChannels: TPcmBuffer;
begin
  LTwelveBits := Buffer(1, 1, 12, 11025, 10);
  LNoChannels := Buffer(1, 1, 8, 11025, 10);
  LNoChannels.Channels := 0;
  Assert.WillRaise(
    procedure
    begin
      TPcmFixedPointResampler.Convert(LTwelveBits, 44100);
    end, EAudioMixException);
  Assert.WillRaise(
    procedure
    begin
      TPcmFixedPointResampler.Convert(LNoChannels, 44100);
    end, EAudioMixException);
end;

procedure TTestAudioMixFixedPointResampler.DovrebbeEssereUnIPcmResampler;
var
  LResampler: IPcmResampler;
  LInput: TPcmBuffer;
begin
  LResampler := TPcmFixedPointResampler.Create;
  LInput := Buffer(3, 2, 16, 11025, 100);
  SameBuffer(TPcmFixedPointResampler.Convert(LInput, 44100), LResampler.Resample(LInput, 44100), 'interfaccia');
end;

end.
