{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio mix library - voice that takes the nearest sample         }
{                                                                              }
{  Moved from DelphiDoom.Greed.PcmMixer (a sound effect of the xGreed port:    }
{  what BASS did for modplay.pas)                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.AudioMix.NearestRateVoice;

{$Q-}
{$R-}
// the position is a 32.32 fixed point number that is only ever added to

interface

uses
  System.SysUtils, DelphiDoom.AudioMix.Intf;

type
  /// <summary>
  ///   A PCM wave (8 bit unsigned or 16 bit signed, one or two channels, any rate) that plays once into a wide 16 bit
  ///   stereo sum (two 32 bit integers for each frame, the caller cuts them to 16 bits at the end), at the rate of the
  ///   mixer, with a volume and a linear pan. The samples are taken at the nearest earlier position, without a
  ///   filter. The destination of Mix is a PInteger. The game can change the volume, the pan and stop the voice from
  ///   its thread while the output mixes: each is read once per block
  /// </summary>
  TPcmNearestRateVoice = class(TInterfacedObject, IPcmVoice)
  strict private
    FWave: TBytes;
    FDataOffset: Integer;
    FFrameCount: Integer;
    FChannels: Integer;
    FBytesPerSample: Integer;
    // the position in the frames of the wave, 32.32 fixed point
    FPosition: UInt64;
    FStep: UInt64;
    FPan: Single;
    FVolume: Single;
    FEnded: Boolean;
    function SampleAt(AFrame, AChannel: Integer): Integer; inline;
  public
    /// <param name="AWave">The bytes that hold the wave (the voice keeps the array alive)</param>
    /// <param name="ADataOffset">Where the samples start in AWave</param>
    /// <param name="AFrameCount">How many frames (a sample for each channel) there are</param>
    /// <param name="ABitsPerSample">8 or 16</param>
    constructor Create(const AWave: TBytes; ADataOffset, AFrameCount, AChannels, ABitsPerSample, AWaveRate,
      AMixerRate: Integer);
    /// <summary>-1 (left only) to 1 (right only), limited to that range</summary>
    procedure SetPan(APan: Single);
    /// <summary>0 to 1, limited to that range</summary>
    procedure SetVolume(AVolume: Single);
    function IsActive: Boolean;
    procedure Stop;
    /// <summary>Adds ACount frames to ADestination (PInteger, two integers per frame); True when it has ended</summary>
    function Mix(ADestination: Pointer; ACount: Integer): Boolean;
  end;

implementation

uses
  System.Math;

const
  POSITION_SHIFT = 32;

{ TPcmNearestRateVoice }

constructor TPcmNearestRateVoice.Create(const AWave: TBytes; ADataOffset, AFrameCount, AChannels, ABitsPerSample,
  AWaveRate, AMixerRate: Integer);
begin
  inherited Create;
  FWave := AWave;
  FDataOffset := ADataOffset;
  FFrameCount := AFrameCount;
  FChannels := AChannels;
  FBytesPerSample := ABitsPerSample div 8;
  FStep := (UInt64(AWaveRate) shl POSITION_SHIFT) div UInt64(AMixerRate);
  FVolume := 1;
end;

procedure TPcmNearestRateVoice.SetPan(APan: Single);
begin
  FPan := Min(Max(APan, -1), 1);
end;

procedure TPcmNearestRateVoice.SetVolume(AVolume: Single);
begin
  FVolume := Min(Max(AVolume, 0), 1);
end;

function TPcmNearestRateVoice.IsActive: Boolean;
begin
  Result := not FEnded;
end;

procedure TPcmNearestRateVoice.Stop;
begin
  FEnded := True;
end;

function TPcmNearestRateVoice.SampleAt(AFrame, AChannel: Integer): Integer;
var
  LOffset: Integer;
begin
  LOffset := FDataOffset + (AFrame * FChannels + AChannel) * FBytesPerSample;
  if FBytesPerSample = 1 then
    // 8 bit samples have no sign
    Result := (Integer(FWave[LOffset]) - 128) shl 8
  else
    Result := SmallInt(Word(FWave[LOffset]) or (Word(FWave[LOffset + 1]) shl 8));
end;

function TPcmNearestRateVoice.Mix(ADestination: Pointer; ACount: Integer): Boolean;
var
  LIndex, LFrame, LLeft, LRight: Integer;
  LLeftGain, LRightGain: Integer;
  LVolume, LPan: Single;
  LSums: PInteger;
begin
  // a voice that was stopped is not mixed
  if FEnded then
    Exit(True);
  // one reading of each: the game changes them from its thread
  LVolume := FVolume;
  LPan := FPan;
  LLeftGain := Round(LVolume * Min(1, 1 - LPan) * 256);
  LRightGain := Round(LVolume * Min(1, 1 + LPan) * 256);
  LSums := PInteger(ADestination);
  for LIndex := 0 to ACount - 1 do
  begin
    LFrame := Integer(FPosition shr POSITION_SHIFT);
    if LFrame >= FFrameCount then
    begin
      FEnded := True;
      Break;
    end;
    LLeft := SampleAt(LFrame, 0);
    if FChannels > 1 then
      LRight := SampleAt(LFrame, 1)
    else
      LRight := LLeft;
    Inc(LSums^, (LLeft * LLeftGain) div 256);
    Inc(LSums);
    Inc(LSums^, (LRight * LRightGain) div 256);
    Inc(LSums);
    Inc(FPosition, FStep);
  end;
  Result := FEnded;
end;

end.
