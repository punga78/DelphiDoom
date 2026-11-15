{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio mix library - the level of the samples that a mixer gave   }
{  to the output (peak, RMS, frames with sound)                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.AudioMix.LevelMeter;

{$Q-}
{$R-}
// the sum of the squares is a Double and the counters are Int64: nothing here depends on the overflow checks

interface

type
  /// <summary>
  ///   What the mixers of the games count on the buffers that go to the output: the highest sample, the RMS and the
  ///   frames in which something plays. It has no lock: the mixer that owns it measures and reads under its own
  /// </summary>
  TPcmLevelMeter = class
  strict private
    FPeak: Integer;
    FSumSquares: Double;
    FSampleCount: Int64;
    FFrameCount: Int64;
    FFramesWithSound: Int64;
  public
    /// <summary>Adds AFrames frames of 16 bit stereo samples (left and right, interleaved) to the figures</summary>
    procedure Measure(ASamples: PSmallInt; AFrames: Integer);
    /// <summary>The highest absolute value seen: -32768 counts as 32768, a mixer that wants 32767 cuts it</summary>
    property Peak: Integer read FPeak;
    /// <summary>Square root of the mean of the squares of every sample measured; 0 before the first sample</summary>
    function Rms: Double;
    /// <summary>Frames measured</summary>
    property FrameCount: Int64 read FFrameCount;
    /// <summary>Frames in which the left or the right sample was not zero</summary>
    property FramesWithSound: Int64 read FFramesWithSound;
  end;

implementation

uses
  System.Math;

procedure TPcmLevelMeter.Measure(ASamples: PSmallInt; AFrames: Integer);
var
  LFrame: Integer;
  LLeft: Integer;
  LRight: Integer;
begin
  for LFrame := 0 to AFrames - 1 do
  begin
    LLeft := ASamples^;
    Inc(ASamples);
    LRight := ASamples^;
    Inc(ASamples);
    FSumSquares := FSumSquares + Double(LLeft) * LLeft;
    FSumSquares := FSumSquares + Double(LRight) * LRight;
    if Abs(LLeft) > FPeak then
      FPeak := Abs(LLeft);
    if Abs(LRight) > FPeak then
      FPeak := Abs(LRight);
    if (LLeft <> 0) or (LRight <> 0) then
      Inc(FFramesWithSound);
  end;
  if AFrames > 0 then
  begin
    Inc(FSampleCount, Int64(AFrames) * 2);
    Inc(FFrameCount, AFrames);
  end;
end;

function TPcmLevelMeter.Rms: Double;
begin
  if FSampleCount > 0 then
    Result := Sqrt(FSumSquares / FSampleCount)
  else
    Result := 0;
end;

end.
