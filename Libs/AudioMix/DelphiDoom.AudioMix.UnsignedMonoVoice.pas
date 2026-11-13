{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio mix library - voice of 8 bit unsigned mono samples        }
{                                                                              }
{  Moved from DelphiDoom.War.Audio.WaveVoice: port of wa_playWave of           }
{  war_audio.c, war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib   }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not    }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.AudioMix.UnsignedMonoVoice;

{$Q-}
{$R-}
// the sums are cut back to 16 bits and the scaling is done in Single as the C does

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The state of a voice (sampleIndex, playbackTime, loop of WarAudioComponent) and wa_playWave: the bytes are
  ///   8 bit unsigned samples, centered on 128, added to what is in the 16 bit mono output scaled by a volume that
  ///   comes from the caller at each block (a Single, as in the C)
  /// </summary>
  TPcmUnsignedMonoVoice = class
  strict private
    FData: TBytes;
    FLoop: Boolean;
    FSampleIndex: Integer;
    FPlaybackTime: Single;
  public
    constructor Create(const AData: TBytes; ALoop: Boolean);
    /// <summary>
    ///   Adds ASampleCount samples to AOutput. True when the sound has finished and does not loop. A voice that
    ///   is called again after it finished starts again from the first sample, as in the original. An empty
    ///   sound is finished at once (the original loops forever on it)
    /// </summary>
    function Mix(AOutput: PSmallInt; ASampleCount: Integer; AVolume: Single): Boolean;
    property SampleIndex: Integer read FSampleIndex;
    /// <summary>Milliseconds played in the current round</summary>
    property PlaybackTime: Single read FPlaybackTime;
    property Loop: Boolean read FLoop;
  end;

implementation

{ TPcmUnsignedMonoVoice }

constructor TPcmUnsignedMonoVoice.Create(const AData: TBytes; ALoop: Boolean);
begin
  inherited Create;
  FData := AData;
  FLoop := ALoop;
end;

function TPcmUnsignedMonoVoice.Mix(AOutput: PSmallInt; ASampleCount: Integer; AVolume: Single): Boolean;
var
  LLength: Integer;
  LBlock: Integer;
  LIndex: Integer;
  LValue: Integer;
  LScaled: Single;
  LStep: Single;
  LMillisecondsPerSample: Single;
  LRemaining: Cardinal;
begin
  LLength := Length(FData);
  if LLength = 0 then
    Exit(True);
  // 1000.0f / PLAYBACK_FREQ: float / int, done in float; every operation below is stored in a Single so that it
  // is rounded like the C does (the x87 would keep more bits)
  LMillisecondsPerSample := 1000.0;
  LMillisecondsPerSample := LMillisecondsPerSample / 44100;
  LRemaining := Cardinal(ASampleCount);
  repeat
    if FSampleIndex >= LLength then
    begin
      FSampleIndex := 0;
      FPlaybackTime := 0;
    end;
    LBlock := LLength - FSampleIndex;
    if LRemaining < Cardinal(LBlock) then
      LBlock := Integer(LRemaining);
    for LIndex := 0 to LBlock - 1 do
    begin
      LValue := (Integer(FData[FSampleIndex + LIndex]) - 128) shl 8;
      LScaled := LValue * AVolume;
      LValue := Trunc(LScaled);
      Inc(LValue, AOutput^);
      if LValue > 32767 then
        LValue := 32767
      else if LValue < -32768 then
        LValue := -32768;
      AOutput^ := SmallInt(LValue);
      Inc(AOutput);
    end;
    LStep := LBlock * LMillisecondsPerSample;
    FPlaybackTime := FPlaybackTime + LStep;
    Inc(FSampleIndex, LBlock);
    Dec(LRemaining, Cardinal(LBlock));
  until (LRemaining = 0) or not FLoop;
  Result := (FSampleIndex >= LLength) and not FLoop;
end;

end.
