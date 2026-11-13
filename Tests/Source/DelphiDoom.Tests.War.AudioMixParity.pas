{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the war library - the mixer of the effects on      }
{  Libs\AudioMix against a copy of the mixer as it was before (issue #228):     }
{  the same calls, the same samples, byte by byte                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AudioMixParity;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Audio.Types, DelphiDoom.War.Audio.Intf;

type
  /// <summary>Sounds made from the index: the same bytes every time, loops short and long</summary>
  TParityAudioLibrary = class(TInterfacedObject, IWarAudioLibrary)
  public
    function KindOf(AIndex: Integer): TWarAudioKind;
    function GetSound(AIndex: Integer): TWarPcmBuffer;
    function GetMusic(AIndex: Integer): TBytes;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarAudioMixParity = class
  public
    [Test]
    procedure DovrebbeDareGliStessiCampioniDelVecchioMixerSuScenariACasoConSeme;
    [Test]
    procedure DovrebbeDareGliStessiHandleEGliStessiConteggi;
  end;

implementation

uses
  DelphiDoom.War.Audio.Mixer, DelphiDoom.Tests.War.LegacyMixer, DelphiDoom.Tests.AudioMix.Support;

{ TParityAudioLibrary }

function TParityAudioLibrary.KindOf(AIndex: Integer): TWarAudioKind;
begin
  Result := wakWave;
end;

function TParityAudioLibrary.GetSound(AIndex: Integer): TWarPcmBuffer;
var
  LRandom: TAudioMixLcg;
  LIndex: Integer;
begin
  LRandom := TAudioMixLcg.Create(AIndex + 1000);
  try
    Result.Channels := 1;
    Result.BitsPerSample := 8;
    Result.SampleRate := WAR_PLAYBACK_RATE;
    case AIndex mod 4 of
      0: SetLength(Result.Data, LRandom.Between(1, 40));
      1: SetLength(Result.Data, LRandom.Between(100, 700));
      2: SetLength(Result.Data, LRandom.Between(2000, 9000));
    else
      SetLength(Result.Data, 0);
    end;
    for LIndex := 0 to High(Result.Data) do
      // loud: the sums saturate
      if LRandom.Chance(50) then
        Result.Data[LIndex] := Byte(LRandom.Between(200, 255))
      else
        Result.Data[LIndex] := Byte(LRandom.Between(0, 60));
  finally
    LRandom.Free;
  end;
end;

function TParityAudioLibrary.GetMusic(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

{ TTestWarAudioMixParity }

procedure TTestWarAudioMixParity.DovrebbeDareGliStessiCampioniDelVecchioMixerSuScenariACasoConSeme;
const
  BLOCK = 600;
var
  LSeed, LStep, LIndex, LCount, LHandleOld, LHandleNew: Integer;
  LRandom: TAudioMixLcg;
  LLibrary: IWarAudioLibrary;
  LOld: IWarSoundMixer;
  LNew: IWarSoundMixer;
  LOldBuffer, LNewBuffer: array[0..BLOCK - 1] of SmallInt;
  LSound, LX, LY, LVolume: Integer;
  LLoop: Boolean;
  LHandles: array[0..63] of Integer;
  LHandleCount: Integer;
begin
  LLibrary := TParityAudioLibrary.Create;
  for LSeed := 1 to 60 do
  begin
    LRandom := TAudioMixLcg.Create(LSeed);
    try
      LOld := TLegacyWarSoundMixer.Create(LLibrary);
      LNew := TWarSoundMixer.Create(LLibrary);
      LHandleCount := 0;
      for LStep := 1 to 80 do
      begin
        case LRandom.Next(10) of
          0, 1, 2:
            begin
              LSound := LRandom.Next(12);
              LLoop := LRandom.Chance(35);
              LHandleOld := LOld.Play(LSound, LLoop);
              LHandleNew := LNew.Play(LSound, LLoop);
              Assert.AreEqual(LHandleOld, LHandleNew);
              if LHandleCount < Length(LHandles) then
              begin
                LHandles[LHandleCount] := LHandleOld;
                Inc(LHandleCount);
              end;
            end;
          3, 4:
            begin
              LSound := LRandom.Next(12);
              LLoop := LRandom.Chance(35);
              LX := LRandom.Between(-200, 1200);
              LY := LRandom.Between(-200, 900);
              LHandleOld := LOld.PlayAt(LSound, LX, LY, LLoop);
              LHandleNew := LNew.PlayAt(LSound, LX, LY, LLoop);
              Assert.AreEqual(LHandleOld, LHandleNew);
              if LHandleCount < Length(LHandles) then
              begin
                LHandles[LHandleCount] := LHandleOld;
                Inc(LHandleCount);
              end;
            end;
          5:
            if LHandleCount > 0 then
            begin
              LIndex := LRandom.Next(LHandleCount);
              LOld.Stop(LHandles[LIndex]);
              LNew.Stop(LHandles[LIndex]);
            end;
          6:
            begin
              LX := LRandom.Between(0, 800);
              LY := LRandom.Between(0, 600);
              LOld.SetViewport(LX, LY, 400, 300);
              LNew.SetViewport(LX, LY, 400, 300);
            end;
          7:
            begin
              LVolume := LRandom.Between(-20, 120);
              LLoop := LRandom.Chance(80);
              LOld.SetVolume(LVolume / 100, LLoop);
              LNew.SetVolume(LVolume / 100, LLoop);
            end;
          8:
            begin
              LLoop := LRandom.Chance(30);
              LOld.SetSilenced(LLoop);
              LNew.SetSilenced(LLoop);
              if LRandom.Chance(10) then
              begin
                LOld.StopAll;
                LNew.StopAll;
              end;
            end;
        end;
        // the output starts with samples in it: the mixers add
        LCount := LRandom.Between(0, BLOCK);
        for LIndex := 0 to BLOCK - 1 do
        begin
          if LRandom.Chance(15) then
            LOldBuffer[LIndex] := SmallInt(LRandom.Between(-32768, 32767))
          else
            LOldBuffer[LIndex] := SmallInt(LRandom.Between(-500, 500));
          LNewBuffer[LIndex] := LOldBuffer[LIndex];
        end;
        LOld.Mix(@LOldBuffer[0], LCount);
        LNew.Mix(@LNewBuffer[0], LCount);
        Assert.IsTrue(CompareMem(@LOldBuffer[0], @LNewBuffer[0], SizeOf(LOldBuffer)),
          Format('campioni, seme %d passo %d', [LSeed, LStep]));
        Assert.AreEqual(LOld.ActiveVoices, LNew.ActiveVoices, Format('voci, seme %d passo %d', [LSeed, LStep]));
      end;
    finally
      LRandom.Free;
    end;
  end;
end;

procedure TTestWarAudioMixParity.DovrebbeDareGliStessiHandleEGliStessiConteggi;
var
  LLibrary: IWarAudioLibrary;
  LOld: IWarSoundMixer;
  LNew: IWarSoundMixer;
  LBuffer: array[0..99] of SmallInt;
  LIndex: Integer;
begin
  LLibrary := TParityAudioLibrary.Create;
  LOld := TLegacyWarSoundMixer.Create(LLibrary);
  LNew := TWarSoundMixer.Create(LLibrary);
  for LIndex := 1 to 5 do
    Assert.AreEqual(LOld.Play(0, False), LNew.Play(0, False));
  Assert.AreEqual(LOld.ActiveVoices, LNew.ActiveVoices);
  // sound 0 has up to 39 samples: one block of 100 ends every voice
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LOld.Mix(@LBuffer[0], 100);
  LNew.Mix(@LBuffer[0], 100);
  Assert.AreEqual(0, LOld.ActiveVoices);
  Assert.AreEqual(0, LNew.ActiveVoices);
  Assert.AreEqual(LOld.Play(1, True), LNew.Play(1, True), 'the handles go on');
end;

end.
