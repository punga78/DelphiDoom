{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of libsndfile - builds minimal WAV files in memory        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sndfile.Wav;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Builds the bytes of a PCM WAV file (RIFF header, "fmt " and "data"
  ///   chunks) so that the tests need no files on disk
  /// </summary>
  TSndfileTestWav = class
  private
    class procedure PutNumber(var ABuffer: TBytes; var AOffset: Integer;
      AValue: Cardinal; AByteCount: Integer); static;
    class procedure PutText(var ABuffer: TBytes; var AOffset: Integer;
      const AText: AnsiString); static;
  public
    /// <summary>
    ///   16 bit PCM WAV; ASamples are interleaved (frame 0 channel 0, frame 0
    ///   channel 1, ...) and their count must be a multiple of AChannels
    /// </summary>
    class function MakePcm16(AChannels, ASampleRate: Integer;
      const ASamples: array of SmallInt): TBytes; static;

    /// <summary>
    ///   Mono 16 bit PCM WAV of AFrames frames made of a deterministic
    ///   sawtooth; SawtoothAt returns the value of a given frame
    /// </summary>
    class function MakeSawtooth(AFrames, ASampleRate: Integer): TBytes; static;
    class function SawtoothAt(AFrame: Integer): SmallInt; static;
  end;

implementation

{ TSndfileTestWav }

class procedure TSndfileTestWav.PutNumber(var ABuffer: TBytes;
  var AOffset: Integer; AValue: Cardinal; AByteCount: Integer);
var
  LIndex: Integer;
begin
  // Little endian
  for LIndex := 0 to AByteCount - 1 do
  begin
    ABuffer[AOffset] := Byte(AValue shr (8 * LIndex));
    Inc(AOffset);
  end;
end;

class procedure TSndfileTestWav.PutText(var ABuffer: TBytes;
  var AOffset: Integer; const AText: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
  begin
    ABuffer[AOffset] := Byte(AText[LIndex]);
    Inc(AOffset);
  end;
end;

class function TSndfileTestWav.MakePcm16(AChannels, ASampleRate: Integer;
  const ASamples: array of SmallInt): TBytes;
const
  HEADER_SIZE = 44;
var
  LDataSize: Integer;
  LOffset: Integer;
  LIndex: Integer;
begin
  LDataSize := Length(ASamples) * SizeOf(SmallInt);
  SetLength(Result, HEADER_SIZE + LDataSize);
  LOffset := 0;

  PutText(Result, LOffset, 'RIFF');
  PutNumber(Result, LOffset, Cardinal(HEADER_SIZE - 8 + LDataSize), 4);
  PutText(Result, LOffset, 'WAVE');

  PutText(Result, LOffset, 'fmt ');
  PutNumber(Result, LOffset, 16, 4);                                       // size of the chunk
  PutNumber(Result, LOffset, 1, 2);                                        // PCM
  PutNumber(Result, LOffset, Cardinal(AChannels), 2);
  PutNumber(Result, LOffset, Cardinal(ASampleRate), 4);
  PutNumber(Result, LOffset, Cardinal(ASampleRate * AChannels * 2), 4);    // bytes per second
  PutNumber(Result, LOffset, Cardinal(AChannels * 2), 2);                  // bytes per frame
  PutNumber(Result, LOffset, 16, 2);                                       // bits per sample

  PutText(Result, LOffset, 'data');
  PutNumber(Result, LOffset, Cardinal(LDataSize), 4);
  for LIndex := 0 to High(ASamples) do
    PutNumber(Result, LOffset, Word(ASamples[LIndex]), 2);
end;

class function TSndfileTestWav.SawtoothAt(AFrame: Integer): SmallInt;
begin
  Result := SmallInt((AFrame * 7) mod 20000 - 10000);
end;

class function TSndfileTestWav.MakeSawtooth(AFrames, ASampleRate: Integer): TBytes;
var
  LSamples: array of SmallInt;
  LIndex: Integer;
begin
  SetLength(LSamples, AFrames);
  for LIndex := 0 to AFrames - 1 do
    LSamples[LIndex] := SawtoothAt(LIndex);
  Result := MakePcm16(1, ASampleRate, LSamples);
end;

end.
