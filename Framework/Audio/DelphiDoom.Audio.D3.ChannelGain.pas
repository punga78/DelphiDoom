{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - 3D sound of Doom 3, volume of a channel         }
{                                                                              }
{  Port of the volume and speaker part of                                      }
{  idSoundWorldLocal::AddChannelContribution and of CalcEars (snd_world.cpp),  }
{  and of idSoundSystemLocal::dB2Scale (snd_system.cpp).                       }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Framework\IdLib\README.md); the repository }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.D3.ChannelGain;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Audio.D3.Types;

type
  /// <summary>Per speaker volumes: left, right, center, sub, rear left, rear right (the first two for stereo)</summary>
  TD3Ears = array[0..5] of Single;

  /// <summary>What <c>AddChannelContribution</c> reads about one playing channel, its sample, its emitter and the listener</summary>
  TD3ChannelInput = record
    /// <summary>parms.soundShaderFlags</summary>
    SoundShaderFlags: Integer;
    /// <summary>parms.volume, in dB</summary>
    VolumeDb: Single;
    /// <summary>parms.minDistance, in meters</summary>
    MinDistance: Single;
    /// <summary>parms.maxDistance, in meters</summary>
    MaxDistance: Single;
    /// <summary>shader->speakerMask: 0 means every speaker</summary>
    SpeakerMask: Integer;
    /// <summary>shader->leadinVolume, in dB (0 = none)</summary>
    LeadinVolumeDb: Single;
    /// <summary>leadinSample->objectInfo.nChannels: 1 or 2</summary>
    SampleChannels: Integer;
    /// <summary>leadinSample->defaultSound</summary>
    SampleIsDefault: Boolean;
    /// <summary>leadinSample->LengthIn44kHzSamples()</summary>
    SampleLength44kHz: Integer;
    /// <summary>the time of the first sample of the block being mixed</summary>
    Current44kHz: Integer;
    /// <summary>chan->trigger44kHzTime</summary>
    Trigger44kHzTime: Integer;
    /// <summary>chan->channelFade.FadeDbAt44kHz(current44kHz)</summary>
    ChannelFadeDb: Single;
    /// <summary>soundClassFade[parms->soundClass].FadeDbAt44kHz(current44kHz)</summary>
    ClassFadeDb: Single;
    SlowmoActive: Boolean;
    SlowmoSpeed: Single;
    /// <summary>chan->disallowSlow</summary>
    DisallowSlow: Boolean;
    /// <summary>sound->origin, in Doom units</summary>
    EmitterOrigin: TIdVec3;
    /// <summary>sound->spatializedOrigin, in Doom units</summary>
    SpatializedOrigin: TIdVec3;
    RealDistance: Single;
    Distance: Single;
    /// <summary>sound->listenerId</summary>
    EmitterListenerId: Integer;
    /// <summary>listenerPrivateId</summary>
    ListenerPrivateId: Integer;
    /// <summary>listenerPos, in meters</summary>
    ListenerPosition: TIdVec3;
    ListenerAxis: TIdMat3;
    /// <summary>2 or 6</summary>
    NumSpeakers: Integer;
  end;

  /// <summary>What the mixing keeps from one block to the next on a channel: <c>lastVolume</c> and <c>lastV</c></summary>
  TD3ChannelState = record
    LastVolume: Single;
    LastV: TD3Ears;
  end;

  /// <summary>The result: whether the channel adds anything, and the volumes to ramp to</summary>
  TD3ChannelGain = record
    Audible: Boolean;
    Volume: Single;
    Ears: TD3Ears;
  end;

  /// <summary>
  ///   The 3D volume of a channel: decibels to scale (the table of <c>volumesDB</c>: steps of a tenth of a
  ///   decibel), distance falloff (linear, or quadratic with <c>s_quadraticFalloff</c>), the bias of the
  ///   spatialization inside the minimum distance, private and anti-private sounds, and the volume of each
  ///   speaker from the direction of the sound (<c>CalcEars</c>), with the speaker mask and the clipping.
  ///   Every operation is rounded to single precision, as the SSE code of the original
  /// </summary>
  TD3ChannelGainCalculator = class
  strict private
    FCvars: TD3SoundCvars;
    FVolumesDb: array[0..1199] of Single;
    procedure CalcEars(ANumSpeakers: Integer; const AOrigin, AListener: TIdVec3; const AAxis: TIdMat3;
      var AEars: TD3Ears; ASpatialize: Single);
  public
    constructor Create(const ACvars: TD3SoundCvars);
    /// <summary>idSoundSystemLocal::dB2Scale</summary>
    function DbToScale(AValue: Single): Single;
    /// <summary>
    ///   The volume and the ears of the channel for this block. AState is updated as the original does: the
    ///   last volume when the channel adds something, and <c>LastV</c> on the first block. The caller mixes
    ///   with <c>LastV</c> and <c>Ears</c> and then copies <c>Ears</c> into <c>LastV</c>
    /// </summary>
    function Calculate(const AInput: TD3ChannelInput; var AState: TD3ChannelState): TD3ChannelGain;
    property Cvars: TD3SoundCvars read FCvars;
  end;

implementation

uses
  System.Math;

const
  SPEAKER_VECTORS: array[0..5, 0..2] of Single = (
    (0.707, 0.707, 0.0),
    (0.707, -0.707, 0.0),
    (0.707, 0.0, 0.0),
    (0.0, 0.0, 0.0),
    (-0.707, 0.707, 0.0),
    (-0.707, -0.707, 0.0));

{ TD3ChannelGainCalculator }

constructor TD3ChannelGainCalculator.Create(const ACvars: TD3SoundCvars);
var
  LIndex: Integer;
  LPoint: Single;
  LExponent: Single;
begin
  inherited Create;
  FCvars := ACvars;
  // volumesDB[i + 600] = pow(2.0f, pt * (1.0f / 6.0f)) with pt = i * 0.1f
  for LIndex := -600 to 599 do
  begin
    LPoint := LIndex * 0.1;
    LExponent := LPoint * (1.0 / 6.0);
    FVolumesDb[LIndex + 600] := Power(2.0, LExponent);
  end;
end;

function TD3ChannelGainCalculator.DbToScale(AValue: Single): Single;
var
  LIndex: Integer;
  LStep: Single;
begin
  if AValue = 0 then
    Exit(1.0);
  if AValue <= -60 then
    Exit(0.0);
  if AValue >= 60 then
  begin
    LStep := AValue * (1.0 / 6.0);
    Exit(Power(2.0, LStep));
  end;
  LStep := AValue + 60.0;
  LStep := LStep * 10.0;
  LIndex := Trunc(LStep);
  Result := FVolumesDb[LIndex];
end;

procedure TD3ChannelGainCalculator.CalcEars(ANumSpeakers: Integer; const AOrigin, AListener: TIdVec3;
  const AAxis: TIdMat3; var AEars: TD3Ears; ASpatialize: Single);
var
  LDirection: TIdVec3;
  LLocal: TIdVec3;
  LIndex: Integer;
  LDot: Single;
  LDotBias: Single;
  LSpeaker: TIdVec3;
begin
  LDirection := AOrigin - AListener;
  LLocal.X := LDirection * AAxis.Rows[0];
  LLocal.Y := LDirection * AAxis.Rows[1];
  LLocal.Z := LDirection * AAxis.Rows[2];
  LLocal.Normalize;
  if ANumSpeakers = 6 then
  begin
    for LIndex := 0 to 5 do
    begin
      if LIndex = 3 then
      begin
        // the subwoofer
        AEars[LIndex] := FCvars.SubFraction;
        Continue;
      end;
      LSpeaker := TIdVec3.Create(SPEAKER_VECTORS[LIndex, 0], SPEAKER_VECTORS[LIndex, 1], SPEAKER_VECTORS[LIndex, 2]);
      LDot := LLocal * LSpeaker;
      AEars[LIndex] := (FCvars.DotBias6 + LDot) / (1.0 + FCvars.DotBias6);
      if AEars[LIndex] < FCvars.MinVolume6 then
        AEars[LIndex] := FCvars.MinVolume6;
    end;
  end
  else
  begin
    LDot := LLocal.Y;
    LDotBias := FCvars.DotBias2;
    // inside the minimum distance the spatialization fades
    LDotBias := LDotBias + (FCvars.SpatializationDecay - LDotBias) * (1.0 - ASpatialize);
    AEars[0] := (FCvars.DotBias2 + LDot) / (1.0 + LDotBias);
    AEars[1] := (FCvars.DotBias2 - LDot) / (1.0 + LDotBias);
    if AEars[0] < FCvars.MinVolume2 then
      AEars[0] := FCvars.MinVolume2;
    if AEars[1] < FCvars.MinVolume2 then
      AEars[1] := FCvars.MinVolume2;
    AEars[2] := 0;
    AEars[3] := 0;
    AEars[4] := 0;
    AEars[5] := 0;
  end;
end;

function TD3ChannelGainCalculator.Calculate(const AInput: TD3ChannelInput; var AState: TD3ChannelState): TD3ChannelGain;
var
  LMaxDistance, LMinDistance: Single;
  LMask: Integer;
  LOmni, LGlobal, LNoOcclusion: Boolean;
  LVolume: Single;
  LSpatialize: Single;
  LOriginInMeters: TIdVec3;
  LDistance: Single;
  LFraction: Single;
  LIndex: Integer;
begin
  Result := Default(TD3ChannelGain);
  // the beeps of missing sounds can be turned off
  if AInput.SampleIsDefault and not FCvars.PlayDefaultSound then
    Exit;
  LMaxDistance := AInput.MaxDistance;
  LMinDistance := AInput.MinDistance;
  LMask := AInput.SpeakerMask;
  LOmni := (AInput.SoundShaderFlags and D3_SSF_OMNIDIRECTIONAL) <> 0;
  LGlobal := (AInput.SoundShaderFlags and D3_SSF_GLOBAL) <> 0;
  LNoOcclusion := ((AInput.SoundShaderFlags and D3_SSF_NO_OCCLUSION) <> 0) or not FCvars.UseOcclusion;
  // slowmo sounds attenuate over a shorter distance
  if FCvars.SlowAttenuate and AInput.SlowmoActive and not AInput.DisallowSlow then
    LMaxDistance := LMaxDistance * AInput.SlowmoSpeed;
  // stereo samples are always omni
  if AInput.SampleChannels = 2 then
    LOmni := True;
  // a sound that plays from the current listener is not spatialized at all
  if AInput.EmitterListenerId = AInput.ListenerPrivateId then
    LGlobal := True;

  // decibels to scale: the leadin volume (shattering lights) while the leadin plays, the global volume, the fades
  if (AInput.LeadinVolumeDb <> 0) and (AInput.Current44kHz - AInput.Trigger44kHzTime < AInput.SampleLength44kHz) then
    LVolume := DbToScale(AInput.LeadinVolumeDb)
  else
    LVolume := DbToScale(AInput.VolumeDb);
  LVolume := LVolume * DbToScale(FCvars.VolumeDb);
  LVolume := LVolume * DbToScale(AInput.ChannelFadeDb);
  LVolume := LVolume * DbToScale(AInput.ClassFadeDb);

  // a global sound is not affected by distance or occlusion
  LSpatialize := 1;
  LOriginInMeters.Zero;
  if not LGlobal then
  begin
    if LNoOcclusion then
    begin
      LOriginInMeters := AInput.EmitterOrigin * D3_DOOM_TO_METERS;
      LDistance := AInput.RealDistance;
    end
    else
    begin
      LOriginInMeters := AInput.SpatializedOrigin * D3_DOOM_TO_METERS;
      LDistance := AInput.Distance;
    end;
    if LDistance >= LMaxDistance then
      LVolume := 0
    else if LDistance > LMinDistance then
    begin
      LFraction := 1.0 - ((LDistance - LMinDistance) / (LMaxDistance - LMinDistance));
      if LFraction < 0 then
        LFraction := 0
      else if LFraction > 1 then
        LFraction := 1;
      if FCvars.QuadraticFalloff then
        LFraction := LFraction * LFraction;
      LVolume := LVolume * LFraction;
    end
    else if LMinDistance > 0 then
      // inside the minimum distance the spatialization bias is tweaked
      LSpatialize := LDistance / LMinDistance;
  end;

  // a private sound is silent unless the listener matches
  if (AInput.SoundShaderFlags and D3_SSF_PRIVATE_SOUND) <> 0 then
    if AInput.EmitterListenerId <> AInput.ListenerPrivateId then
      LVolume := 0;
  if (AInput.SoundShaderFlags and D3_SSF_ANTI_PRIVATE_SOUND) <> 0 then
    if AInput.EmitterListenerId = AInput.ListenerPrivateId then
      LVolume := 0;

  // is there anything to add
  if (LVolume < D3_SND_EPSILON) and (AState.LastVolume < D3_SND_EPSILON) then
    Exit;
  AState.LastVolume := LVolume;
  Result.Audible := True;
  Result.Volume := LVolume;

  // the ear values
  if LGlobal or LOmni then
  begin
    for LIndex := 0 to 5 do
      Result.Ears[LIndex] := FCvars.GlobalFraction * LVolume;
    Result.Ears[3] := FCvars.SubFraction * LVolume;
  end
  else
  begin
    CalcEars(AInput.NumSpeakers, LOriginInMeters, AInput.ListenerPosition, AInput.ListenerAxis, Result.Ears, LSpatialize);
    for LIndex := 0 to 5 do
      Result.Ears[LIndex] := Result.Ears[LIndex] * LVolume;
  end;
  // a mask of 0 means every speaker; a cleared bit silences a speaker
  if LMask = 0 then
    LMask := 255;
  for LIndex := 0 to 5 do
    if (LMask and (1 shl LIndex)) = 0 then
      Result.Ears[LIndex] := 0;
  // volumes over 1 almost always clip, unless the sound says it is not normalized
  if FCvars.ClipVolumes and ((AInput.SoundShaderFlags and D3_SSF_UNCLAMPED) = 0) then
    for LIndex := 0 to 5 do
      if Result.Ears[LIndex] > 1.0 then
        Result.Ears[LIndex] := 1.0;
  // the very first block starts at the volume it will have
  if AInput.Current44kHz = AInput.Trigger44kHzTime then
    AState.LastV := Result.Ears;
end;

end.
