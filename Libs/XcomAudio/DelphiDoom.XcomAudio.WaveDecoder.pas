{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - WAV files as samples of the mixer           }
{  (what Mix_QuickLoad_WAV and SDL_BuildAudioCVT do for a sound)                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.WaveDecoder;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Turns a PCM WAV file (mono or stereo, 8 or 16 bits, any rate) into 16 bit stereo samples at the rate of the
  ///   mixer. The rate changes by taking the nearest earlier sample (SDL converts by repeating or dropping samples:
  ///   a 11025 Hz sound at 22050 Hz has each sample twice)
  /// </summary>
  TXcomWaveDecoder = class
  public
    /// <summary>Interleaved left and right samples; EXcomAudioException when the file is not a PCM WAV file</summary>
    class function ToStereo16(const AWave: TBytes; ARate: Integer): TArray<SmallInt>; static;
  end;

implementation

uses
  DelphiDoom.XcomAudio.Types;

class function TXcomWaveDecoder.ToStereo16(const AWave: TBytes; ARate: Integer): TArray<SmallInt>;
var
  LPosition: Integer;
  LChunk: Cardinal;
  LSize: Cardinal;
  LFormat: Word;
  LChannels: Word;
  LSourceRate: Cardinal;
  LBits: Word;
  LDataStart: Integer;
  LDataSize: Integer;
  LHasFormat: Boolean;
  LFrameBytes: Integer;
  LFrames: Integer;
  LOutFrames: Integer;
  LIndex: Integer;
  LSource: Integer;
  LLeft: SmallInt;
  LRight: SmallInt;

  function ReadWord(AOffset: Integer): Word;
  begin
    Result := AWave[AOffset] or (AWave[AOffset + 1] shl 8);
  end;

  function ReadLong(AOffset: Integer): Cardinal;
  begin
    Result := Cardinal(ReadWord(AOffset)) or (Cardinal(ReadWord(AOffset + 2)) shl 16);
  end;

  function SampleAt(AOffset: Integer): SmallInt;
  begin
    if LBits = 8 then
      Result := (Integer(AWave[AOffset]) - 128) * 256
    else
      Result := SmallInt(ReadWord(AOffset));
  end;

begin
  if (Length(AWave) < 12) or (ReadLong(0) <> $46464952) or (ReadLong(8) <> $45564157) then
    raise EXcomAudioException.Create(SXcomWaveNotPcm);
  LHasFormat := False;
  LDataStart := -1;
  LDataSize := 0;
  LFormat := 0;
  LChannels := 0;
  LSourceRate := 0;
  LBits := 0;
  LPosition := 12;
  while LPosition + 8 <= Length(AWave) do
  begin
    LChunk := ReadLong(LPosition);
    LSize := ReadLong(LPosition + 4);
    if (LChunk = $20746D66) and (LPosition + 24 <= Length(AWave)) then
    begin
      LFormat := ReadWord(LPosition + 8);
      LChannels := ReadWord(LPosition + 10);
      LSourceRate := ReadLong(LPosition + 12);
      LBits := ReadWord(LPosition + 22);
      LHasFormat := True;
    end
    else if LChunk = $61746164 then
    begin
      LDataStart := LPosition + 8;
      LDataSize := Integer(LSize);
      if (LDataSize < 0) or (LDataStart + LDataSize > Length(AWave)) then
        LDataSize := Length(AWave) - LDataStart;
      Break;
    end;
    LPosition := LPosition + 8 + Integer(LSize) + Integer(LSize and 1);
  end;
  if (not LHasFormat) or (LDataStart < 0) or (LFormat <> 1) or (LSourceRate = 0) or
    not (LChannels in [1, 2]) or not (LBits in [8, 16]) or (ARate <= 0) then
    raise EXcomAudioException.Create(SXcomWaveNotPcm);
  LFrameBytes := LChannels * (LBits div 8);
  LFrames := LDataSize div LFrameBytes;
  LOutFrames := Integer((Int64(LFrames) * ARate) div LSourceRate);
  SetLength(Result, LOutFrames * 2);
  for LIndex := 0 to LOutFrames - 1 do
  begin
    LSource := Integer((Int64(LIndex) * LSourceRate) div Cardinal(ARate));
    if LSource >= LFrames then
      LSource := LFrames - 1;
    LLeft := SampleAt(LDataStart + LSource * LFrameBytes);
    if LChannels = 2 then
      LRight := SampleAt(LDataStart + LSource * LFrameBytes + (LBits div 8))
    else
      LRight := LLeft;
    Result[LIndex * 2] := LLeft;
    Result[LIndex * 2 + 1] := LRight;
  end;
end;

end.
