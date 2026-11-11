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
    ///   SoundSet::loadCatbyIndex (the sounds of a soundDefs set, as in TFTD): signed 8 bit samples at 11025 Hz; the
    ///   five bytes at the start and the last one go away, the samples become unsigned (plus 128), no resampling
    /// </summary>
    class function IndexedToWave(const ARaw: TBytes): TBytes; static;
    /// <summary>
    ///   SoundSet::loadCat for a sound that is a WAV file (SAMPLE.CAT of the Windows version): a file that says
    ///   8000 Hz becomes an 11025 Hz one (the rate of the header and the samples after the 44 byte header, repeated
    ///   as convertSampleRate does); any other file is returned as it is
    /// </summary>
    class function WaveToWave(const AWave: TBytes): TBytes; static;
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

class function TXcomSoundConverter.IndexedToWave(const ARaw: TBytes): TBytes;
const
  HEADER: array[0..43] of Byte = (Ord('R'), Ord('I'), Ord('F'), Ord('F'), 0, 0, 0, 0, Ord('W'), Ord('A'), Ord('V'),
    Ord('E'), Ord('f'), Ord('m'), Ord('t'), Ord(' '), $10, 0, 0, 0, 1, 0, 1, 0, $11, $2B, 0, 0, $11, $2B, 0, 0, 1, 0, 8,
    0, Ord('d'), Ord('a'), Ord('t'), Ord('a'), 0, 0, 0, 0);
var
  LSize: Integer;
  LIndex: Integer;
begin
  LSize := Length(ARaw);
  if LSize = 0 then
    Exit(nil);
  if LSize > 5 then
    Dec(LSize, 5);
  if LSize > 0 then
    Dec(LSize);
  // the C++ reads from byte 5 whatever the size: a sound of five bytes or fewer has nothing to read
  if Length(ARaw) < 5 + LSize then
    LSize := 0;
  SetLength(Result, HEADER_SIZE + LSize);
  Move(HEADER[0], Result[0], HEADER_SIZE);
  for LIndex := 0 to LSize - 1 do
    Result[HEADER_SIZE + LIndex] := Byte(ARaw[5 + LIndex] + 128);
  PCardinal(@Result[4])^ := Cardinal(LSize + 36);
  PCardinal(@Result[40])^ := Cardinal(LSize);
end;

class function TXcomSoundConverter.WaveToWave(const AWave: TBytes): TBytes;
var
  LSize: Integer;
  LStep: Cardinal;
  LOffset: Cardinal;
  LCount: Integer;
begin
  Result := Copy(AWave);
  // the rate of the header as four bytes: 8000 is 40 1F 00 00
  if (Length(AWave) <= HEADER_SIZE) or (PCardinal(@AWave[$18])^ <> 8000) then
    Exit;
  LSize := Length(AWave) - HEADER_SIZE;
  SetLength(Result, HEADER_SIZE + LSize * 2);
  // the rate and the low bytes of the bytes per second, as the C++ writes them
  Result[$18] := $11;
  Result[$19] := $2B;
  Result[$1C] := $11;
  Result[$1D] := $2B;
  LStep := Cardinal((Int64(8000) shl 16) div SAMPLE_RATE);
  LOffset := 0;
  LCount := 0;
  while (LOffset shr 16) < Cardinal(LSize) do
  begin
    Result[HEADER_SIZE + LCount] := AWave[HEADER_SIZE + Integer(LOffset shr 16)];
    Inc(LCount);
    Inc(LOffset, LStep);
  end;
  SetLength(Result, HEADER_SIZE + LCount);
  // only the size of the data is rewritten: the size of the RIFF stays the one of the file
  PCardinal(@Result[$28])^ := Cardinal(LCount);
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