{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - the voice of 8 bit         }
{  unsigned mono samples, against a copy of the one of the war library as it    }
{  was                                                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.UnsignedMonoVoice;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.AudioMix.UnsignedMonoVoice,
  DelphiDoom.Tests.AudioMix.LegacyWaveVoice;

type
  [TestFixture]
  [Category('audiomix')]
  TTestAudioMixUnsignedMonoVoice = class
  public
    [Test]
    procedure DovrebbeDareGliStessiCampioniDelVecchioSuScenariACasoConSeme;
    [Test]
    procedure DovrebbeFinireUnSuonoSenzaCiclo;
    [Test]
    procedure DovrebbeRipartireDaCapoSeChiamatoDopoLaFine;
    [Test]
    procedure DovrebbeFinireSubitoUnSuonoVuoto;
    [Test]
    procedure DovrebbeSaturareASedicibit;
    [Test]
    procedure DovrebbeScalareConIlVolume;
  end;

implementation

uses
  DelphiDoom.Tests.AudioMix.Support;

const
  VOLUMES: array[0..7] of Single = (0, 0.37, 0.5, 1, 1.9, 4, -0.5, 0.001);

procedure TTestAudioMixUnsignedMonoVoice.DovrebbeDareGliStessiCampioniDelVecchioSuScenariACasoConSeme;
var
  LSeed, LBlock, LIndex, LLength, LCount: Integer;
  LRandom: TAudioMixLcg;
  LData: TBytes;
  LOld: TLegacyWaveVoice;
  LNew: TPcmUnsignedMonoVoice;
  LLoop: Boolean;
  LVolume, LOldTime, LNewTime: Single;
  LOldBuffer, LNewBuffer: array[0..511] of SmallInt;
  LOldEnded, LNewEnded: Boolean;
begin
  for LSeed := 1 to 300 do
  begin
    LRandom := TAudioMixLcg.Create(LSeed);
    try
      LLength := LRandom.Next(600);
      SetLength(LData, LLength);
      for LIndex := 0 to LLength - 1 do
        LData[LIndex] := Byte(LRandom.Next(256));
      LLoop := LRandom.Chance(40);
      LOld := TLegacyWaveVoice.Create(LData, LLoop);
      LNew := TPcmUnsignedMonoVoice.Create(LData, LLoop);
      try
        for LBlock := 1 to 30 do
        begin
          LCount := LRandom.Between(1, 512);
          LVolume := VOLUMES[LRandom.Next(Length(VOLUMES))];
          // the output already holds samples, some near the limits, so that the sum saturates
          for LIndex := 0 to LCount - 1 do
          begin
            if LRandom.Chance(20) then
              LOldBuffer[LIndex] := SmallInt(LRandom.Between(25000, 32767) * (LRandom.Next(2) * 2 - 1))
            else
              LOldBuffer[LIndex] := SmallInt(LRandom.Between(-3000, 3000));
            LNewBuffer[LIndex] := LOldBuffer[LIndex];
          end;
          LOldEnded := LOld.Mix(@LOldBuffer[0], LCount, LVolume);
          LNewEnded := LNew.Mix(@LNewBuffer[0], LCount, LVolume);
          Assert.AreEqual(LOldEnded, LNewEnded, Format('fine, seme %d blocco %d', [LSeed, LBlock]));
          Assert.IsTrue(CompareMem(@LOldBuffer[0], @LNewBuffer[0], LCount * SizeOf(SmallInt)),
            Format('campioni, seme %d blocco %d', [LSeed, LBlock]));
          Assert.AreEqual<Integer>(LOld.SampleIndex, LNew.SampleIndex, 'posizione');
          LOldTime := LOld.PlaybackTime;
          LNewTime := LNew.PlaybackTime;
          Assert.AreEqual<Integer>(PInteger(@LOldTime)^, PInteger(@LNewTime)^, 'tempo, bit per bit');
        end;
      finally
        LNew.Free;
        LOld.Free;
      end;
    finally
      LRandom.Free;
    end;
  end;
end;

procedure TTestAudioMixUnsignedMonoVoice.DovrebbeFinireUnSuonoSenzaCiclo;
var
  LVoice: TPcmUnsignedMonoVoice;
  LOutput: array[0..3] of SmallInt;
begin
  LVoice := TPcmUnsignedMonoVoice.Create(TBytes.Create(128, 129, 130), False);
  try
    FillChar(LOutput, SizeOf(LOutput), 0);
    Assert.IsFalse(LVoice.Mix(@LOutput[0], 2, 1));
    Assert.IsTrue(LVoice.Mix(@LOutput[2], 2, 1), 'il terzo campione e l ultimo');
    Assert.AreEqual<Integer>(0, LOutput[0]);
    Assert.AreEqual<Integer>(256, LOutput[1]);
    Assert.AreEqual<Integer>(512, LOutput[2]);
    Assert.AreEqual<Integer>(3, LVoice.SampleIndex);
  finally
    LVoice.Free;
  end;
end;

procedure TTestAudioMixUnsignedMonoVoice.DovrebbeRipartireDaCapoSeChiamatoDopoLaFine;
var
  LVoice: TPcmUnsignedMonoVoice;
  LOutput: array[0..2] of SmallInt;
begin
  LVoice := TPcmUnsignedMonoVoice.Create(TBytes.Create(129), False);
  try
    FillChar(LOutput, SizeOf(LOutput), 0);
    Assert.IsTrue(LVoice.Mix(@LOutput[0], 1, 1));
    Assert.IsTrue(LVoice.Mix(@LOutput[1], 1, 1), 'come nell originale');
    Assert.AreEqual<Integer>(256, LOutput[0]);
    Assert.AreEqual<Integer>(256, LOutput[1]);
  finally
    LVoice.Free;
  end;
end;

procedure TTestAudioMixUnsignedMonoVoice.DovrebbeFinireSubitoUnSuonoVuoto;
var
  LVoice: TPcmUnsignedMonoVoice;
  LOutput: SmallInt;
begin
  LVoice := TPcmUnsignedMonoVoice.Create(nil, True);
  try
    LOutput := 7;
    Assert.IsTrue(LVoice.Mix(@LOutput, 1, 1));
    Assert.AreEqual<Integer>(7, LOutput);
  finally
    LVoice.Free;
  end;
end;

procedure TTestAudioMixUnsignedMonoVoice.DovrebbeSaturareASedicibit;
var
  LVoice: TPcmUnsignedMonoVoice;
  LOutput: array[0..1] of SmallInt;
begin
  LVoice := TPcmUnsignedMonoVoice.Create(TBytes.Create(255, 0), False);
  try
    LOutput[0] := 32000;
    LOutput[1] := -32000;
    LVoice.Mix(@LOutput[0], 2, 1);
    Assert.AreEqual<Integer>(32767, LOutput[0]);
    Assert.AreEqual<Integer>(-32768, LOutput[1]);
  finally
    LVoice.Free;
  end;
end;

procedure TTestAudioMixUnsignedMonoVoice.DovrebbeScalareConIlVolume;
var
  LVoice: TPcmUnsignedMonoVoice;
  LOutput: array[0..1] of SmallInt;
begin
  LVoice := TPcmUnsignedMonoVoice.Create(TBytes.Create(192, 64), True);
  try
    FillChar(LOutput, SizeOf(LOutput), 0);
    LVoice.Mix(@LOutput[0], 2, 0.5);
    Assert.AreEqual<Integer>(8192, LOutput[0]);
    Assert.AreEqual<Integer>(-8192, LOutput[1]);
  finally
    LVoice.Free;
  end;
end;

end.
