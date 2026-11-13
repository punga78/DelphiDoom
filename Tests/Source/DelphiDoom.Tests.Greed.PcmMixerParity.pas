{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the greed library - the mixer to PCM on            }
{  Libs\AudioMix against a copy of the mixer as it was before (issue #228):     }
{  the same calls, the same samples and statistics, byte by byte                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.PcmMixerParity;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.PcmMixer;

type
  /// <summary>A song that makes its samples from a seed: loud, so that the sums are cut</summary>
  TParitySongRenderer = class(TInterfacedObject, IGreedSongRenderer)
  strict private
    FState: Cardinal;
  public
    constructor Create(ASeed: Cardinal);
    procedure Render(const ASamples: TArray<SmallInt>; AFrames: Integer);
  end;

  TParitySongDecoder = class(TInterfacedObject, IGreedSongDecoder)
  public
    function Open(const AModule: TBytes; ARate: Integer): IGreedSongRenderer;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedPcmMixerParity = class
  strict private
    class function Wave(AChannels, ABits, ARate: Integer; ASeed: Cardinal; AFrames: Integer): TBytes; static;
  public
    [Test]
    procedure DovrebbeDareGliStessiCampioniEStatisticheDelVecchioMixerSuScenariACasoConSeme;
    [Test]
    procedure DovrebbeRifiutareGliStessiByte;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.PcmMixer, DelphiDoom.Tests.Greed.LegacyPcmMixer, DelphiDoom.Tests.AudioMix.Support;

{ TParitySongRenderer }

constructor TParitySongRenderer.Create(ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
end;

procedure TParitySongRenderer.Render(const ASamples: TArray<SmallInt>; AFrames: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AFrames * 2 - 1 do
  begin
    FState := FState * 1664525 + 1013904223;
    if (FState shr 30) = 0 then
      ASamples[LIndex] := 0
    else
      ASamples[LIndex] := SmallInt((FState shr 8) and $FFFF);
  end;
end;

{ TParitySongDecoder }

function TParitySongDecoder.Open(const AModule: TBytes; ARate: Integer): IGreedSongRenderer;
begin
  if (Length(AModule) = 0) or (AModule[0] = 0) then
    Exit(nil);
  Result := TParitySongRenderer.Create(AModule[0] * 7919);
end;

{ TTestGreedPcmMixerParity }

class function TTestGreedPcmMixerParity.Wave(AChannels, ABits, ARate: Integer; ASeed: Cardinal;
  AFrames: Integer): TBytes;
var
  LDataBytes, LIndex: Integer;
  LRandom: TAudioMixLcg;

  procedure Put32(AAt: Integer; AValue: Cardinal);
  begin
    Result[AAt] := Byte(AValue);
    Result[AAt + 1] := Byte(AValue shr 8);
    Result[AAt + 2] := Byte(AValue shr 16);
    Result[AAt + 3] := Byte(AValue shr 24);
  end;

  procedure Put16(AAt: Integer; AValue: Word);
  begin
    Result[AAt] := Byte(AValue);
    Result[AAt + 1] := Byte(AValue shr 8);
  end;

  procedure PutTag(AAt: Integer; const ATag: AnsiString);
  var
    LChar: Integer;
  begin
    for LChar := 1 to 4 do
      Result[AAt + LChar - 1] := Byte(ATag[LChar]);
  end;

begin
  LDataBytes := AFrames * AChannels * (ABits div 8);
  SetLength(Result, 44 + LDataBytes + 12);
  PutTag(44 + LDataBytes, 'pad ');
  Put32(48 + LDataBytes, 4);
  PutTag(0, 'RIFF');
  Put32(4, 48 + LDataBytes);
  PutTag(8, 'WAVE');
  PutTag(12, 'fmt ');
  Put32(16, 16);
  Put16(20, 1);
  Put16(22, AChannels);
  Put32(24, ARate);
  Put32(28, ARate * AChannels * (ABits div 8));
  Put16(32, AChannels * (ABits div 8));
  Put16(34, ABits);
  PutTag(36, 'data');
  Put32(40, LDataBytes);
  LRandom := TAudioMixLcg.Create(ASeed);
  try
    for LIndex := 0 to LDataBytes - 1 do
      Result[44 + LIndex] := Byte(LRandom.Next(256));
  finally
    LRandom.Free;
  end;
end;

procedure TTestGreedPcmMixerParity.DovrebbeDareGliStessiCampioniEStatisticheDelVecchioMixerSuScenariACasoConSeme;
const
  RATES: array[0..4] of Integer = (8000, 11025, 22050, 32000, 44100);
  MIXER_RATES: array[0..2] of Integer = (22050, 44100, 11025);
  MAX_FRAMES = 700;
var
  LSeed, LStep, LIndex, LFrames, LPick: Integer;
  LRandom: TAudioMixLcg;
  LOld: IGreedSoundDevice;
  LNew: IGreedSoundDevice;
  LOldRenderer: IGreedPcmRenderer;
  LNewRenderer: IGreedPcmRenderer;
  LWaves: array[0..9] of TBytes;
  LOldEffects, LNewEffects: array[0..39] of IGreedEffectChannel;
  LEffectCount: Integer;
  LOldMusic, LNewMusic: IGreedMusicChannel;
  LOldBuffer, LNewBuffer: array[0..MAX_FRAMES * 4 - 1] of Byte;
  LOldStats, LNewStats: TGreedMixerStatistics;
  LPan, LVolume: Single;
  LModule: TBytes;
  LMixerRate: Integer;
begin
  for LSeed := 1 to 40 do
  begin
    LRandom := TAudioMixLcg.Create(LSeed);
    try
      for LIndex := 0 to High(LWaves) do
        LWaves[LIndex] := Wave(LRandom.Between(1, 2), LRandom.Between(1, 2) * 8, RATES[LRandom.Next(Length(RATES))],
          LSeed * 100 + LIndex, LRandom.Between(1, 1500));
      // bytes that are not a WAV file
      LWaves[9] := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
      LMixerRate := MIXER_RATES[LSeed mod Length(MIXER_RATES)];
      LOld := TLegacyGreedPcmMixer.Create(LMixerRate, TParitySongDecoder.Create, TFakeMixerLog.Create);
      LNew := TGreedPcmMixer.Create(LMixerRate, TParitySongDecoder.Create, TFakeMixerLog.Create);
      Assert.IsTrue(LOld.Initialize);
      Assert.IsTrue(LNew.Initialize);
      LOldRenderer := LOld as IGreedPcmRenderer;
      LNewRenderer := LNew as IGreedPcmRenderer;
      LEffectCount := 0;
      LOldMusic := nil;
      LNewMusic := nil;
      for LStep := 1 to 60 do
      begin
        case LRandom.Next(9) of
          0, 1, 2:
            if LEffectCount < Length(LOldEffects) then
            begin
              LPick := LRandom.Next(Length(LWaves));
              LOldEffects[LEffectCount] := LOld.StartEffect(LWaves[LPick]);
              LNewEffects[LEffectCount] := LNew.StartEffect(LWaves[LPick]);
              Assert.AreEqual(Assigned(LOldEffects[LEffectCount]), Assigned(LNewEffects[LEffectCount]));
              Inc(LEffectCount);
            end;
          3, 4:
            if LEffectCount > 0 then
            begin
              LPick := LRandom.Next(LEffectCount);
              LPan := LRandom.Between(-150, 150) / 100;
              LVolume := LRandom.Between(-20, 130) / 100;
              if Assigned(LOldEffects[LPick]) then
              begin
                LOldEffects[LPick].SetPan(LPan);
                LNewEffects[LPick].SetPan(LPan);
                LOldEffects[LPick].SetVolume(LVolume);
                LNewEffects[LPick].SetVolume(LVolume);
                Assert.AreEqual(LOldEffects[LPick].IsActive, LNewEffects[LPick].IsActive);
              end;
            end;
          5:
            if (LEffectCount > 0) and LRandom.Chance(40) then
            begin
              LPick := LRandom.Next(LEffectCount);
              if Assigned(LOldEffects[LPick]) then
              begin
                LOldEffects[LPick].Stop;
                LNewEffects[LPick].Stop;
              end;
            end;
          6:
            begin
              LModule := TBytes.Create(Byte(LRandom.Next(4)), 1, 2);
              LVolume := LRandom.Between(0, 100) / 100;
              LOldMusic := LOld.StartMusic(LModule, LVolume);
              LNewMusic := LNew.StartMusic(LModule, LVolume);
              Assert.AreEqual(Assigned(LOldMusic), Assigned(LNewMusic));
            end;
          7:
            if Assigned(LOldMusic) then
            begin
              LVolume := LRandom.Between(-10, 120) / 100;
              LOldMusic.SetVolume(LVolume);
              LNewMusic.SetVolume(LVolume);
              if LRandom.Chance(25) then
              begin
                LOldMusic.Stop;
                LNewMusic.Stop;
              end;
            end;
        end;
        LFrames := LRandom.Between(1, MAX_FRAMES);
        FillChar(LOldBuffer, SizeOf(LOldBuffer), $55);
        FillChar(LNewBuffer, SizeOf(LNewBuffer), $55);
        LOldRenderer.Render(@LOldBuffer[0], LFrames * 4);
        LNewRenderer.Render(@LNewBuffer[0], LFrames * 4);
        Assert.IsTrue(CompareMem(@LOldBuffer[0], @LNewBuffer[0], SizeOf(LOldBuffer)),
          Format('campioni, seme %d passo %d', [LSeed, LStep]));
        LOldStats := LOldRenderer.Statistics;
        LNewStats := LNewRenderer.Statistics;
        Assert.AreEqual<Int64>(LOldStats.FramesRendered, LNewStats.FramesRendered);
        Assert.AreEqual<Int64>(LOldStats.FramesWithSound, LNewStats.FramesWithSound);
        Assert.AreEqual<Integer>(LOldStats.Peak, LNewStats.Peak);
        Assert.AreEqual<Int64>(LOldStats.ClippedSamples, LNewStats.ClippedSamples);
        Assert.AreEqual<Integer>(LOldStats.EffectsStarted, LNewStats.EffectsStarted);
        Assert.AreEqual<Integer>(LOldStats.EffectsRejected, LNewStats.EffectsRejected);
        Assert.AreEqual<Integer>(LOldStats.EffectsEnded, LNewStats.EffectsEnded,
          Format('effetti finiti, seme %d passo %d', [LSeed, LStep]));
        Assert.AreEqual<Integer>(LOldStats.ActiveEffects, LNewStats.ActiveEffects);
        Assert.AreEqual<Integer>(LOldStats.SongsStarted, LNewStats.SongsStarted);
        Assert.AreEqual<Integer>(LOldStats.SongsRejected, LNewStats.SongsRejected);
        Assert.AreEqual<Int64>(LOldStats.FramesWithMusic, LNewStats.FramesWithMusic);
        Assert.AreEqual(LOldStats.SongPlaying, LNewStats.SongPlaying);
      end;
      LOldRenderer := nil;
      LNewRenderer := nil;
      LOld.Shutdown;
      LNew.Shutdown;
    finally
      LRandom.Free;
    end;
  end;
end;

procedure TTestGreedPcmMixerParity.DovrebbeRifiutareGliStessiByte;
var
  LOld: IGreedSoundDevice;
  LNew: IGreedSoundDevice;
begin
  LOld := TLegacyGreedPcmMixer.Create(22050, nil, TFakeMixerLog.Create);
  LNew := TGreedPcmMixer.Create(22050, nil, TFakeMixerLog.Create);
  LOld.Initialize;
  LNew.Initialize;
  Assert.IsFalse(Assigned(LOld.StartEffect(TBytes.Create(1, 2, 3))));
  Assert.IsFalse(Assigned(LNew.StartEffect(TBytes.Create(1, 2, 3))));
  Assert.IsFalse(Assigned(LOld.StartEffect(nil)));
  Assert.IsFalse(Assigned(LNew.StartEffect(nil)));
  Assert.IsFalse(Assigned(LOld.StartMusic(TBytes.Create(1), 1)));
  Assert.IsFalse(Assigned(LNew.StartMusic(TBytes.Create(1), 1)));
end;

end.
