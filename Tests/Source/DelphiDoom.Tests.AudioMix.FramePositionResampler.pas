{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - the resampler by frame     }
{  position, against a copy of the one of the xcom audio library as it was      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.FramePositionResampler;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.AudioMix.Types, DelphiDoom.AudioMix.Intf,
  DelphiDoom.AudioMix.FramePositionResampler, DelphiDoom.Tests.AudioMix.LegacyFramePositionResampler;

type
  [TestFixture]
  [Category('audiomix')]
  TTestAudioMixFramePositionResampler = class
  strict private
    function Samples(ASeed: Cardinal; ACount: Integer): TArray<SmallInt>;
  public
    [Test]
    procedure DovrebbeDareGliStessiCampioniDelVecchio;
    [Test]
    procedure DovrebbeDareLeStesseRispostePerLePotenzeDiDue;
    [Test]
    procedure DovrebbeRipetereICampioniQuandoIlRapportoEUnaPotenzaDiDue;
    [Test]
    procedure DovrebbeDareLoStessoArrayAlloStessoRate;
    [Test]
    procedure DovrebbeConvertireUnBufferComeUnArray;
    [Test]
    procedure DovrebbeRifiutareUnBufferCheNonESteroA16Bit;
  end;

implementation

uses
  DelphiDoom.Tests.AudioMix.Support;

function TTestAudioMixFramePositionResampler.Samples(ASeed: Cardinal; ACount: Integer): TArray<SmallInt>;
var
  LRandom: TAudioMixLcg;
  LIndex: Integer;
begin
  LRandom := TAudioMixLcg.Create(ASeed);
  try
    SetLength(Result, ACount);
    for LIndex := 0 to ACount - 1 do
      Result[LIndex] := SmallInt(LRandom.Between(-32768, 32767));
  finally
    LRandom.Free;
  end;
end;

procedure TTestAudioMixFramePositionResampler.DovrebbeDareGliStessiCampioniDelVecchio;
const
  RATES: array[0..8] of Integer = (8000, 11025, 22050, 32000, 44100, 48000, 96000, 5512, 22051);
  FRAMES: array[0..6] of Integer = (0, 1, 2, 3, 100, 777, 3000);
var
  LSource, LTarget, LFrame: Integer;
  LInput, LExpected, LActual: TArray<SmallInt>;
begin
  for LSource := 0 to High(RATES) do
    for LTarget := 0 to High(RATES) do
      for LFrame := 0 to High(FRAMES) do
      begin
        LInput := Samples(LSource * 100 + LTarget * 7 + LFrame, FRAMES[LFrame] * 2);
        LExpected := TLegacyFramePositionResampler.Convert(LInput, RATES[LSource], RATES[LTarget]);
        LActual := TPcmFramePositionResampler.ConvertStereo16(LInput, RATES[LSource], RATES[LTarget]);
        Assert.AreEqual<Integer>(Length(LExpected), Length(LActual),
          Format('%d -> %d, %d frame', [RATES[LSource], RATES[LTarget], FRAMES[LFrame]]));
        if Length(LExpected) > 0 then
          Assert.IsTrue(CompareMem(@LExpected[0], @LActual[0], Length(LExpected) * SizeOf(SmallInt)),
            Format('%d -> %d, %d frame', [RATES[LSource], RATES[LTarget], FRAMES[LFrame]]));
      end;
end;

procedure TTestAudioMixFramePositionResampler.DovrebbeDareLeStesseRispostePerLePotenzeDiDue;
const
  RATES: array[0..9] of Integer = (-5, 0, 1, 2, 3, 11025, 22050, 44100, 33075, 7350);
var
  LSource, LTarget: Integer;
begin
  for LSource := 0 to High(RATES) do
    for LTarget := 0 to High(RATES) do
      Assert.AreEqual(TLegacyFramePositionResampler.IsPowerOfTwoRatio(RATES[LSource], RATES[LTarget]),
        TPcmFramePositionResampler.IsPowerOfTwoRatio(RATES[LSource], RATES[LTarget]),
        Format('%d e %d', [RATES[LSource], RATES[LTarget]]));
end;

procedure TTestAudioMixFramePositionResampler.DovrebbeRipetereICampioniQuandoIlRapportoEUnaPotenzaDiDue;
var
  LOutput: TArray<SmallInt>;
begin
  // 11025 -> 22050: each frame twice, as SDL 1.2 does
  LOutput := TPcmFramePositionResampler.ConvertStereo16(TArray<SmallInt>.Create(1, -1, 5, -5), 11025, 22050);
  Assert.AreEqual<Integer>(8, Length(LOutput));
  Assert.AreEqual<Integer>(1, LOutput[0]);
  Assert.AreEqual<Integer>(-1, LOutput[1]);
  Assert.AreEqual<Integer>(1, LOutput[2]);
  Assert.AreEqual<Integer>(-1, LOutput[3]);
  Assert.AreEqual<Integer>(5, LOutput[4]);
  Assert.AreEqual<Integer>(-5, LOutput[5]);
  Assert.AreEqual<Integer>(5, LOutput[6]);
  Assert.AreEqual<Integer>(-5, LOutput[7]);
end;

procedure TTestAudioMixFramePositionResampler.DovrebbeDareLoStessoArrayAlloStessoRate;
var
  LInput, LOutput: TArray<SmallInt>;
begin
  LInput := Samples(5, 40);
  LOutput := TPcmFramePositionResampler.ConvertStereo16(LInput, 22050, 22050);
  Assert.IsTrue(Pointer(LInput) = Pointer(LOutput));
end;

procedure TTestAudioMixFramePositionResampler.DovrebbeConvertireUnBufferComeUnArray;
var
  LResampler: IPcmResampler;
  LInput, LOutput: TPcmBuffer;
  LArray, LExpected: TArray<SmallInt>;
begin
  LArray := Samples(9, 600);
  LInput.Channels := 2;
  LInput.BitsPerSample := 16;
  LInput.SampleRate := 11025;
  SetLength(LInput.Data, Length(LArray) * SizeOf(SmallInt));
  Move(LArray[0], LInput.Data[0], Length(LInput.Data));
  LResampler := TPcmFramePositionResampler.Create;
  LOutput := LResampler.Resample(LInput, 22050);
  LExpected := TPcmFramePositionResampler.ConvertStereo16(LArray, 11025, 22050);
  Assert.AreEqual<Cardinal>(22050, LOutput.SampleRate);
  Assert.AreEqual<Integer>(Length(LExpected) * SizeOf(SmallInt), Length(LOutput.Data));
  Assert.IsTrue(CompareMem(@LExpected[0], @LOutput.Data[0], Length(LOutput.Data)));
end;

procedure TTestAudioMixFramePositionResampler.DovrebbeRifiutareUnBufferCheNonESteroA16Bit;
var
  LResampler: IPcmResampler;
  LMono, LBytes: TPcmBuffer;
begin
  LResampler := TPcmFramePositionResampler.Create;
  LMono.Channels := 1;
  LMono.BitsPerSample := 16;
  LMono.SampleRate := 11025;
  LBytes := LMono;
  LBytes.Channels := 2;
  LBytes.BitsPerSample := 8;
  Assert.WillRaise(
    procedure
    begin
      LResampler.Resample(LMono, 22050);
    end, EAudioMixException);
  Assert.WillRaise(
    procedure
    begin
      LResampler.Resample(LBytes, 22050);
    end, EAudioMixException);
end;

end.
