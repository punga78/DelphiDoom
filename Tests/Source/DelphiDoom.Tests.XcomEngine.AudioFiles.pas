{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio of the xcom game - makers of the music files  }
{  (a MOD, a Standard MIDI file, an entry of GM.CAT, a CAT container) and the   }
{  measure of a buffer                                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.AudioFiles;

interface

uses
  System.SysUtils;

type
  /// <summary>Makes the small music files of the tests. It is not a fixture</summary>
  TAudioFiles = class
  public
    /// <summary>
    ///   A MOD of one pattern (64 rows, speed 6, tempo 125: about 7.7 seconds) in which the first channel plays C-2 of a
    ///   square wave sample once, at the first row
    /// </summary>
    class function Mod_: TBytes; static;
    /// <summary>
    ///   A MIDI file of type 0, 96 ticks per quarter note, 120 beats per minute: patch AProgram on channel 0 plays
    ///   C4 for a beat and E4 for a beat (one second), then the track ends
    /// </summary>
    class function Midi(AProgram: Integer = 0): TBytes; static;
    /// <summary>The same song as an entry of GM.CAT (tempo 120, one track on channel 0 with the patch AProgram)</summary>
    class function GmEntry(AProgram: Integer = 0): TBytes; static;
    /// <summary>A CAT container: an index of offset and size, then entries with a name (length byte and text)</summary>
    class function Cat(const AEntries: TArray<TBytes>): TBytes; static;
    /// <summary>The root mean square of 16 bit samples</summary>
    class function Rms(const ASamples: TArray<SmallInt>; AFirst: Integer = 0; ACount: Integer = -1): Double; static;
  end;

implementation

class function TAudioFiles.Mod_: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 1084 + 1024 + 32);
  FillChar(Result[0], Length(Result), 0);
  // the first sample: 16 words long, volume 64, looped over all of it
  Result[20 + 22] := 0;
  Result[20 + 23] := 16;
  Result[20 + 25] := 64;
  Result[20 + 26] := 0;
  Result[20 + 27] := 0;
  Result[20 + 28] := 0;
  Result[20 + 29] := 16;
  // one position in the order, the restart byte
  Result[950] := 1;
  Result[951] := 127;
  Result[1080] := Ord('M');
  Result[1081] := Ord('.');
  Result[1082] := Ord('K');
  Result[1083] := Ord('.');
  // the first row: period 428, sample 1
  Result[1084] := $01;
  Result[1085] := $AC;
  Result[1086] := $10;
  Result[1087] := $00;
  for LIndex := 0 to 31 do
    if LIndex < 16 then
      Result[1084 + 1024 + LIndex] := 64
    else
      Result[1084 + 1024 + LIndex] := $C0;
end;

class function TAudioFiles.Midi(AProgram: Integer): TBytes;
var
  LTrack: TBytes;
begin
  LTrack := TBytes.Create(
    $00, $C0, AProgram,
    $00, $90, 60, 100,
    $60, $80, 60, 0,
    $00, $90, 64, 100,
    $60, $80, 64, 0,
    $00, $FF, $2F, $00);
  Result := TBytes.Create($4D, $54, $68, $64, 0, 0, 0, 6, 0, 0, 0, 1, 0, 96,
    $4D, $54, $72, $6B, 0, 0, 0, Length(LTrack));
  Result := Result + LTrack;
end;

class function TAudioFiles.GmEntry(AProgram: Integer): TBytes;
var
  LSequence: TBytes;
  LSize: Cardinal;
begin
  LSequence := TBytes.Create(
    $00, $C0, AProgram,
    $00, $90, 60, 100,
    $60, $80, 60, 0,
    $00, $90, 64, 100,
    $60, $80, 64, 0,
    $00, $FF);
  LSize := Length(LSequence) + 4;
  // the tempo, no subsequence, one track: the channel, the size (with the size field itself) and the events
  Result := TBytes.Create(120, 0, 1, 0, Byte(LSize), Byte(LSize shr 8), 0, 0) + LSequence;
end;

class function TAudioFiles.Cat(const AEntries: TArray<TBytes>): TBytes;
var
  LIndex: Integer;
  LOffset: Cardinal;
  LEntry: TBytes;
begin
  SetLength(Result, Length(AEntries) * 8);
  LOffset := Length(AEntries) * 8;
  for LIndex := 0 to High(AEntries) do
  begin
    Move(LOffset, Result[LIndex * 8], 4);
    PCardinal(@Result[LIndex * 8 + 4])^ := Length(AEntries[LIndex]);
    // a name of one character
    LEntry := TBytes.Create(1, Ord('X')) + AEntries[LIndex];
    Result := Result + LEntry;
    Inc(LOffset, Length(LEntry));
  end;
end;

class function TAudioFiles.Rms(const ASamples: TArray<SmallInt>; AFirst, ACount: Integer): Double;
var
  LIndex: Integer;
  LSum: Double;
begin
  if ACount < 0 then
    ACount := Length(ASamples) - AFirst;
  if ACount <= 0 then
    Exit(0);
  LSum := 0;
  for LIndex := AFirst to AFirst + ACount - 1 do
    LSum := LSum + Double(ASamples[LIndex]) * ASamples[LIndex];
  Result := Sqrt(LSum / ACount);
end;

end.
