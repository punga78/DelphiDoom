{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio mix library - channel of 16 bit stereo samples            }
{                                                                              }
{  Moved from DelphiDoom.XcomAudio.Mixer (the channels of SDL_mixer).          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see       }
{  Libs\XcomFormats\README.md for the license of this unit                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.AudioMix.StereoChannelVoice;

{$Q-}
{$R-}
// the sums are cut back to 16 bits: nothing here depends on the overflow checks

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   One channel of the mixer of OpenXcom: a sound of interleaved 16 bit stereo samples that plays a number of times
  ///   (or forever) into a 16 bit stereo output, with a gain for each side (the pan and the distance) and the volume
  ///   of the channel that the caller gives at each block. A sound that comes with its volume applied ("baked") is
  ///   added as it is and is not heard at all while the caller says it is silenced
  /// </summary>
  TPcmStereoChannelVoice = class
  strict private
    FSamples: TArray<SmallInt>;
    FPosition: Integer;
    FActive: Boolean;
    // plays left: -1 forever
    FPlays: Integer;
    FBaked: Boolean;
    FGainLeft: Single;
    FGainRight: Single;
    procedure MixBlock(ADestination: PSmallInt; ACount: Integer; AVolume: Single; ASilenced: Boolean);
  public
    constructor Create;
    /// <summary>Starts ASamples: ALoops less than 0 is forever, otherwise ALoops + 1 plays; gains back to 1</summary>
    procedure Start(const ASamples: TArray<SmallInt>; ALoops: Integer; ABaked: Boolean);
    procedure SetGains(ALeft, ARight: Single);
    /// <summary>Stops the sound and lets go of its samples</summary>
    procedure Halt;
    /// <summary>
    ///   Adds ACount 16 bit samples (ACount / 2 frames, left then right) to ADestination, going on to the next play
    ///   when one ends; the channel is inactive after the last play (and at once for an empty sound)
    /// </summary>
    procedure Render(ADestination: PSmallInt; ACount: Integer; AVolume: Single; ASilenced: Boolean);
    property Active: Boolean read FActive;
  end;

implementation

uses
  System.Math, DelphiDoom.AudioMix.Saturation;

{ TPcmStereoChannelVoice }

constructor TPcmStereoChannelVoice.Create;
begin
  inherited Create;
end;

procedure TPcmStereoChannelVoice.Start(const ASamples: TArray<SmallInt>; ALoops: Integer; ABaked: Boolean);
begin
  FSamples := ASamples;
  FPosition := 0;
  FActive := True;
  if ALoops < 0 then
    FPlays := -1
  else
    FPlays := ALoops + 1;
  FBaked := ABaked;
  FGainLeft := 1;
  FGainRight := 1;
end;

procedure TPcmStereoChannelVoice.SetGains(ALeft, ARight: Single);
begin
  FGainLeft := ALeft;
  FGainRight := ARight;
end;

procedure TPcmStereoChannelVoice.Halt;
begin
  FActive := False;
  FSamples := nil;
end;

procedure TPcmStereoChannelVoice.MixBlock(ADestination: PSmallInt; ACount: Integer; AVolume: Single;
  ASilenced: Boolean);
var
  LIndex: Integer;
  LSum: Integer;
  LSource: PSmallInt;
  LLeft: Single;
  LRight: Single;
  LGain: Single;
begin
  LSource := @FSamples[FPosition];
  if FBaked then
  begin
    // the volume is in the samples: with the sounds silenced (backgroundMute) nothing is added
    if not ASilenced then
      TPcmSaturation.AddSaturated(ADestination, LSource, ACount);
    Exit;
  end;
  LLeft := FGainLeft * AVolume;
  LRight := FGainRight * AVolume;
  for LIndex := 0 to ACount - 1 do
  begin
    if (LIndex and 1) = 0 then
      LGain := LLeft
    else
      LGain := LRight;
    LSum := Integer(ADestination^) + Trunc(LSource^ * LGain);
    ADestination^ := SmallInt(EnsureRange(LSum, -32768, 32767));
    Inc(ADestination);
    Inc(LSource);
  end;
end;

procedure TPcmStereoChannelVoice.Render(ADestination: PSmallInt; ACount: Integer; AVolume: Single;
  ASilenced: Boolean);
var
  LTake: Integer;
begin
  while FActive and (ACount > 0) do
  begin
    LTake := Length(FSamples) - FPosition;
    if LTake <= 0 then
    begin
      // nothing to play (an empty sound) or the end of a pass
      if (Length(FSamples) = 0) or (FPlays = 1) then
      begin
        FActive := False;
        FSamples := nil;
        Exit;
      end;
      if FPlays > 1 then
        Dec(FPlays);
      FPosition := 0;
      Continue;
    end;
    if LTake > ACount then
      LTake := ACount;
    MixBlock(ADestination, LTake, AVolume, ASilenced);
    Inc(ADestination, LTake);
    Inc(FPosition, LTake);
    Dec(ACount, LTake);
  end;
  if FActive and (FPlays = 1) and (FPosition >= Length(FSamples)) then
  begin
    FActive := False;
    FSamples := nil;
  end;
end;

end.
