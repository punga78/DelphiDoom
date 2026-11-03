{******************************************************************************}
{                                                                              }
{  DelphiDoom: MP3 streams built in memory for the tests of the mp3 library    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mp3.Samples;

interface

uses
  System.SysUtils;

const
  // MPEG-1 layer III, 128 kbit/s, 44100 Hz, no padding: 144 * 128000 div 44100
  SAMPLE_FRAME_SIZE = 417;

  // 1152 samples per channel, 16 bit
  SAMPLE_MONO_PCM_BYTES = 1152 * 2;
  SAMPLE_STEREO_PCM_BYTES = 1152 * 2 * 2;

  SAMPLE_FREQUENCY = 44100;

type
  /// <summary>
  ///   Valid but silent MP3 data. A layer III frame whose side info and main
  ///   data are all zero is legal and decodes to 1152 zero samples per
  ///   channel, so these streams exercise framing, buffering and output sizes
  ///   without needing a real recording. They say nothing about the quality
  ///   of the decoded audio
  /// </summary>
  TMp3Samples = class
  public
    /// <summary>
    ///   One silent frame; AMono selects the channel mode of the header
    /// </summary>
    class function SilentFrame(AMono: Boolean): TBytes; static;

    /// <summary>
    ///   AFrameCount silent frames one after the other
    /// </summary>
    class function SilentStream(AFrameCount: Integer;
      AMono: Boolean = True): TBytes; static;

    /// <summary>
    ///   An ID3v2 tag with APayloadSize bytes of payload. The payload starts
    ///   with the bytes of a frame header, which a decoder that does not skip
    ///   tags would take for the beginning of a frame
    /// </summary>
    class function Id3Tag(APayloadSize: Integer): TBytes; static;

    /// <summary>
    ///   One MPEG-1 layer II frame (160 kbit/s, 44100 Hz, no padding)
    /// </summary>
    class function Layer2Frame: TBytes; static;

    /// <summary>
    ///   Concatenation of two byte arrays
    /// </summary>
    class function Join(const AFirst, ASecond: TBytes): TBytes; static;

    /// <summary>
    ///   True when every byte is zero
    /// </summary>
    class function IsSilent(const AData: TBytes): Boolean; static;
  end;

implementation

{ TMp3Samples }

class function TMp3Samples.SilentFrame(AMono: Boolean): TBytes;
begin
  SetLength(Result, SAMPLE_FRAME_SIZE);
  FillChar(Result[0], Length(Result), 0);
  // FF FB: sync, MPEG-1, layer III, no CRC. 90: 128 kbit/s, 44100 Hz
  Result[0] := $FF;
  Result[1] := $FB;
  Result[2] := $90;
  if AMono then
    Result[3] := $C0
  else
    Result[3] := $00;
end;

class function TMp3Samples.SilentStream(AFrameCount: Integer;
  AMono: Boolean): TBytes;
var
  LFrame: TBytes;
  LIndex: Integer;
begin
  LFrame := SilentFrame(AMono);
  SetLength(Result, AFrameCount * Length(LFrame));
  for LIndex := 0 to AFrameCount - 1 do
    Move(LFrame[0], Result[LIndex * Length(LFrame)], Length(LFrame));
end;

class function TMp3Samples.Id3Tag(APayloadSize: Integer): TBytes;
begin
  SetLength(Result, 10 + APayloadSize);
  FillChar(Result[0], Length(Result), 0);
  Result[0] := Ord('I');
  Result[1] := Ord('D');
  Result[2] := Ord('3');
  Result[3] := 3;
  // Size as four 7 bit groups (payload sizes in the tests are below 128)
  Result[9] := Byte(APayloadSize and $7F);
  Result[10] := $FF;
  Result[11] := $FB;
  Result[12] := $90;
  Result[13] := $C0;
end;

class function TMp3Samples.Layer2Frame: TBytes;
begin
  // 144 * 160000 div 44100
  SetLength(Result, 522);
  FillChar(Result[0], Length(Result), 0);
  // FD in the second byte: layer II
  Result[0] := $FF;
  Result[1] := $FD;
  Result[2] := $90;
  Result[3] := $C0;
end;

class function TMp3Samples.Join(const AFirst, ASecond: TBytes): TBytes;
begin
  SetLength(Result, Length(AFirst) + Length(ASecond));
  if Length(AFirst) > 0 then
    Move(AFirst[0], Result[0], Length(AFirst));
  if Length(ASecond) > 0 then
    Move(ASecond[0], Result[Length(AFirst)], Length(ASecond));
end;

class function TMp3Samples.IsSilent(const AData: TBytes): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to High(AData) do
    if AData[LIndex] <> 0 then
      Exit(False);
end;

end.
