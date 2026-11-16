{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - 3D sound of Doom 3, mixing into the speakers    }
{                                                                              }
{  Port of idSIMD_Generic::MixSoundTwoSpeakerMono, MixSoundTwoSpeakerStereo,   }
{  MixSoundSixSpeakerMono, MixSoundSixSpeakerStereo and MixedSoundToSamples    }
{  (idlib\math\Simd_Generic.cpp), in Pascal: no SIMD, no assembler.            }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Framework\IdLib\README.md); the repository }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.D3.SpeakerMixer;

interface

uses
  System.SysUtils, DelphiDoom.Audio.D3.Types, DelphiDoom.Audio.D3.ChannelGain;

type
  /// <summary>
  ///   Adds a block of 4096 samples of a channel (mono or stereo, as float samples) into the mix buffer of 2 or 6
  ///   speakers, the volume of each speaker going in a straight line from the last block's volume to this block's
  ///   (so a sound that moves or fades does not click), and turns the mix buffer into 16-bit samples
  /// </summary>
  TD3SpeakerMixer = class sealed
  public
    /// <summary>The mix buffer holds 4096 frames of ANumSpeakers (2 or 6) values</summary>
    class procedure Mix(ANumSpeakers: Integer; AStereoSample: Boolean; AMixBuffer: PSingle; ASamples: PSingle;
      const ALastVolumes, ACurrentVolumes: TD3Ears); static;
    /// <summary>MixedSoundToSamples: truncated, limited to -32768..32767 (the limits themselves map to themselves)</summary>
    class procedure ToSamples(ASamples: PSmallInt; AMixBuffer: PSingle; ACount: Integer); static;
  end;

implementation

{$POINTERMATH ON}

{ TD3SpeakerMixer }

class procedure TD3SpeakerMixer.Mix(ANumSpeakers: Integer; AStereoSample: Boolean; AMixBuffer, ASamples: PSingle;
  const ALastVolumes, ACurrentVolumes: TD3Ears);
var
  LCurrent: array[0..5] of Single;
  LStep: array[0..5] of Single;
  LIndex: Integer;
  LSpeaker: Integer;
  LLeft, LRight: Single;
  LTemporary: Single;
begin
  for LSpeaker := 0 to 5 do
  begin
    LCurrent[LSpeaker] := ALastVolumes[LSpeaker];
    LTemporary := ACurrentVolumes[LSpeaker] - ALastVolumes[LSpeaker];
    LStep[LSpeaker] := LTemporary / D3_MIXBUFFER_SAMPLES;
  end;
  if ANumSpeakers = 6 then
  begin
    for LIndex := 0 to D3_MIXBUFFER_SAMPLES - 1 do
    begin
      if AStereoSample then
      begin
        LLeft := ASamples[LIndex * 2];
        LRight := ASamples[LIndex * 2 + 1];
        AMixBuffer[LIndex * 6 + 0] := AMixBuffer[LIndex * 6 + 0] + LLeft * LCurrent[0];
        AMixBuffer[LIndex * 6 + 1] := AMixBuffer[LIndex * 6 + 1] + LRight * LCurrent[1];
        AMixBuffer[LIndex * 6 + 2] := AMixBuffer[LIndex * 6 + 2] + LLeft * LCurrent[2];
        AMixBuffer[LIndex * 6 + 3] := AMixBuffer[LIndex * 6 + 3] + LLeft * LCurrent[3];
        AMixBuffer[LIndex * 6 + 4] := AMixBuffer[LIndex * 6 + 4] + LLeft * LCurrent[4];
        AMixBuffer[LIndex * 6 + 5] := AMixBuffer[LIndex * 6 + 5] + LRight * LCurrent[5];
      end
      else
        for LSpeaker := 0 to 5 do
          AMixBuffer[LIndex * 6 + LSpeaker] := AMixBuffer[LIndex * 6 + LSpeaker] + ASamples[LIndex] * LCurrent[LSpeaker];
      for LSpeaker := 0 to 5 do
        LCurrent[LSpeaker] := LCurrent[LSpeaker] + LStep[LSpeaker];
    end;
  end
  else
  begin
    for LIndex := 0 to D3_MIXBUFFER_SAMPLES - 1 do
    begin
      if AStereoSample then
      begin
        AMixBuffer[LIndex * 2 + 0] := AMixBuffer[LIndex * 2 + 0] + ASamples[LIndex * 2 + 0] * LCurrent[0];
        AMixBuffer[LIndex * 2 + 1] := AMixBuffer[LIndex * 2 + 1] + ASamples[LIndex * 2 + 1] * LCurrent[1];
      end
      else
      begin
        AMixBuffer[LIndex * 2 + 0] := AMixBuffer[LIndex * 2 + 0] + ASamples[LIndex] * LCurrent[0];
        AMixBuffer[LIndex * 2 + 1] := AMixBuffer[LIndex * 2 + 1] + ASamples[LIndex] * LCurrent[1];
      end;
      LCurrent[0] := LCurrent[0] + LStep[0];
      LCurrent[1] := LCurrent[1] + LStep[1];
    end;
  end;
end;

class procedure TD3SpeakerMixer.ToSamples(ASamples: PSmallInt; AMixBuffer: PSingle; ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
    if AMixBuffer[LIndex] <= -32768.0 then
      ASamples[LIndex] := -32768
    else if AMixBuffer[LIndex] >= 32767.0 then
      ASamples[LIndex] := 32767
    else
      ASamples[LIndex] := Trunc(AMixBuffer[LIndex]);
end;

end.
