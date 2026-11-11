{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the sounds of a CAT file as WAV files      }
{  (SoundSet::loadCat and convertSampleRate)                                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.SoundConverter;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Makes a WAV file from a sound of SAMPLE.CAT of the DOS games (raw 6 bit samples at 8 kHz): the five bytes of
  ///   garbage at the start and the null at the end go away, the samples are scaled to 8 bits (times 4, wrapping),
  ///   the rate goes from 8 kHz to 11.025 kHz by repeating samples, and the 44 byte header of the file is added
  /// </summary>
  TXcomSoundConverter = class
  public
    const
      HEADER_SIZE = 44;
      SAMPLE_RATE = 11025;
    /// <summary>The WAV file (11025 Hz, mono, 8 bit); empty when the sound is too short</summary>
    class function RawToWave(const ARaw: TBytes): TBytes; static;
    /// <summary>
    ///   A WAV file with the volume applied (0..128 of 128): the 8 bit samples are unsigned, so they scale around
    ///   128; a file that is not a mono or stereo 8 bit PCM one is returned as it is
    /// </summary>
    class function WithVolume(const AWave: TBytes; AVolume: Integer): TBytes; static;
  end;

implementation

class function TXcomSoundConverter.RawToWave(const ARaw: TBytes): TBytes;
const
  HEADER: array[0..43] of Byte = (Ord('R'), Ord('I'), Ord('F'), Ord('F'), 0, 0, 0, 0, Ord('W'), Ord('A'), Ord('V'),
    Ord('E'), Ord('f'), Ord('m'), Ord('t'), Ord(' '), $10, 0, 0, 0, 1, 0, 1, 0, $11, $2B, 0, 0, $11, $2B, 0, 0, 1, 0, 8,
    0, Ord('d'), Ord('a'), Ord('t'), Ord('a'), 0, 0, 0, 0);
var
  LSize: Integer;
  LStep: Cardinal;
  LOffset: Cardinal;
  LCount: Integer;
  LData: TBytes;
  LIndex: Integer;
begin
  LSize := Length(ARaw);
  if LSize > 5 then
    Dec(LSize, 5);
  if LSize > 0 then
    Dec(LSize);
  if (Length(ARaw) <= 5) or (LSize <= 0) then
    Exit(nil);
  SetLength(LData, LSize * 2);
  LStep := Cardinal((Int64(8000) shl 16) div SAMPLE_RATE);
  LOffset := 0;
  LCount := 0;
  while (LOffset shr 16) < Cardinal(LSize) do
  begin
    // the scaling to 8 bits keeps the low byte of the product
    LData[LCount] := Byte(ARaw[5 + Integer(LOffset shr 16)] * 4);
    Inc(LCount);
    Inc(LOffset, LStep);
  end;
  SetLength(Result, HEADER_SIZE + LCount);
  Move(HEADER[0], Result[0], HEADER_SIZE);
  for LIndex := 0 to LCount - 1 do
    Result[HEADER_SIZE + LIndex] := LData[LIndex];
  PCardinal(@Result[4])^ := Cardinal(LCount + 36);
  PCardinal(@Result[40])^ := Cardinal(LCount);
end;

class function TXcomSoundConverter.WithVolume(const AWave: TBytes; AVolume: Integer): TBytes;
var
  LIndex: Integer;
  LValue: Integer;
begin
  Result := Copy(AWave);
  if (Length(Result) <= HEADER_SIZE) or (PWord(@Result[34])^ <> 8) then
    Exit;
  if AVolume < 0 then
    AVolume := 0;
  if AVolume > 128 then
    AVolume := 128;
  for LIndex := HEADER_SIZE to High(Result) do
  begin
    LValue := 128 + ((Result[LIndex] - 128) * AVolume) div 128;
    Result[LIndex] := Byte(LValue);
  end;
end;

end.