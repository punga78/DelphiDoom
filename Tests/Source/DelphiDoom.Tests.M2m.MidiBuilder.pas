{******************************************************************************}
{                                                                              }
{  DelphiDoom: builds Standard MIDI files, in memory, for the tests of m2m     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.M2m.MidiBuilder;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The bytes of the events and of the chunks of a MIDI file: the tests
  ///   join them with Join
  /// </summary>
  TTestMidiBuilder = class
  public
    class function Join(const AParts: array of TBytes): TBytes; static;
    class function Bytes(const AValues: array of Byte): TBytes; static;

    /// <summary>The header chunk; ADivision is the word as it is written in the file</summary>
    class function Header(const AMode, ATrackCount, ADivision: Integer): TBytes; static;
    /// <summary>A track chunk; ALength says how many bytes it declares (-1 for the real ones)</summary>
    class function Track(const AEvents: TBytes; const ALength: Integer = -1): TBytes; static;

    class function VariableLength(const AValue: Cardinal): TBytes; static;

    class function NoteOn(const ADelta: Cardinal; const AChannel, AKey, AVelocity: Integer): TBytes; static;
    class function NoteOff(const ADelta: Cardinal; const AChannel, AKey, AVelocity: Integer): TBytes; static;
    class function NoteAftertouch(const ADelta: Cardinal; const AChannel, AKey, AAmount: Integer): TBytes; static;
    class function Controller(const ADelta: Cardinal; const AChannel, AController, AValue: Integer): TBytes; static;
    class function ProgramChange(const ADelta: Cardinal; const AChannel, AProgram: Integer): TBytes; static;
    class function ChannelAftertouch(const ADelta: Cardinal; const AChannel, AAmount: Integer): TBytes; static;
    class function PitchBend(const ADelta: Cardinal; const AChannel, ALow, AHigh: Integer): TBytes; static;
    class function Meta(const ADelta: Cardinal; const AType: Integer; const AData: array of Byte): TBytes; static;
    class function Tempo(const ADelta: Cardinal; const AMicroseconds: Cardinal): TBytes; static;
    class function EndOfTrack(const ADelta: Cardinal): TBytes; static;
    class function SysEx(const ADelta: Cardinal; const AData: array of Byte): TBytes; static;
    /// <summary>An event with the status byte left out (running status)</summary>
    class function Running(const ADelta: Cardinal; const AParams: array of Byte): TBytes; static;
  end;

implementation

{ TTestMidiBuilder }

class function TTestMidiBuilder.Join(const AParts: array of TBytes): TBytes;
var
  LPart: TBytes;
  LTotal, LOffset: Integer;
begin
  LTotal := 0;
  for LPart in AParts do
    Inc(LTotal, Length(LPart));
  SetLength(Result, LTotal);
  LOffset := 0;
  for LPart in AParts do
  begin
    if Length(LPart) > 0 then
      Move(LPart[0], Result[LOffset], Length(LPart));
    Inc(LOffset, Length(LPart));
  end;
end;

class function TTestMidiBuilder.Bytes(const AValues: array of Byte): TBytes;
begin
  SetLength(Result, Length(AValues));
  if Length(AValues) > 0 then
    Move(AValues[0], Result[0], Length(AValues));
end;

class function TTestMidiBuilder.Header(const AMode, ATrackCount, ADivision: Integer): TBytes;
begin
  Result := Bytes([Ord('M'), Ord('T'), Ord('h'), Ord('d'), 0, 0, 0, 6, 0, Byte(AMode), Byte(ATrackCount shr 8),
    Byte(ATrackCount and $FF), Byte(ADivision shr 8), Byte(ADivision and $FF)]);
end;

class function TTestMidiBuilder.Track(const AEvents: TBytes; const ALength: Integer): TBytes;
var
  LLength: Integer;
begin
  if ALength >= 0 then
    LLength := ALength
  else
    LLength := Length(AEvents);
  Result := Join([Bytes([Ord('M'), Ord('T'), Ord('r'), Ord('k'), Byte(LLength shr 24), Byte((LLength shr 16) and $FF),
    Byte((LLength shr 8) and $FF), Byte(LLength and $FF)]), AEvents]);
end;

class function TTestMidiBuilder.VariableLength(const AValue: Cardinal): TBytes;
var
  LGroups: array[0..3] of Byte;
  LCount, LIndex: Integer;
  LValue: Cardinal;
begin
  LValue := AValue;
  LCount := 0;
  repeat
    LGroups[LCount] := Byte(LValue and $7F);
    LValue := LValue shr 7;
    Inc(LCount);
  until (LValue = 0) or (LCount = Length(LGroups));
  SetLength(Result, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    Result[LIndex] := LGroups[LCount - 1 - LIndex];
    if LIndex < LCount - 1 then
      Result[LIndex] := Result[LIndex] or $80;
  end;
end;

class function TTestMidiBuilder.NoteOn(const ADelta: Cardinal; const AChannel, AKey, AVelocity: Integer): TBytes;
begin
  Result := Join([VariableLength(ADelta), Bytes([Byte($90 or AChannel), Byte(AKey), Byte(AVelocity)])]);
end;

class function TTestMidiBuilder.NoteOff(const ADelta: Cardinal; const AChannel, AKey, AVelocity: Integer): TBytes;
begin
  Result := Join([VariableLength(ADelta), Bytes([Byte($80 or AChannel), Byte(AKey), Byte(AVelocity)])]);
end;

class function TTestMidiBuilder.NoteAftertouch(const ADelta: Cardinal; const AChannel, AKey, AAmount: Integer): TBytes;
begin
  Result := Join([VariableLength(ADelta), Bytes([Byte($A0 or AChannel), Byte(AKey), Byte(AAmount)])]);
end;

class function TTestMidiBuilder.Controller(const ADelta: Cardinal; const AChannel, AController,
  AValue: Integer): TBytes;
begin
  Result := Join([VariableLength(ADelta), Bytes([Byte($B0 or AChannel), Byte(AController), Byte(AValue)])]);
end;

class function TTestMidiBuilder.ProgramChange(const ADelta: Cardinal; const AChannel, AProgram: Integer): TBytes;
begin
  Result := Join([VariableLength(ADelta), Bytes([Byte($C0 or AChannel), Byte(AProgram)])]);
end;

class function TTestMidiBuilder.ChannelAftertouch(const ADelta: Cardinal; const AChannel, AAmount: Integer): TBytes;
begin
  Result := Join([VariableLength(ADelta), Bytes([Byte($D0 or AChannel), Byte(AAmount)])]);
end;

class function TTestMidiBuilder.PitchBend(const ADelta: Cardinal; const AChannel, ALow, AHigh: Integer): TBytes;
begin
  Result := Join([VariableLength(ADelta), Bytes([Byte($E0 or AChannel), Byte(ALow), Byte(AHigh)])]);
end;

class function TTestMidiBuilder.Meta(const ADelta: Cardinal; const AType: Integer; const AData: array of Byte): TBytes;
begin
  Result := Join([VariableLength(ADelta), Bytes([$FF, Byte(AType)]), VariableLength(Length(AData)), Bytes(AData)]);
end;

class function TTestMidiBuilder.Tempo(const ADelta: Cardinal; const AMicroseconds: Cardinal): TBytes;
begin
  Result := Meta(ADelta, $51, [Byte(AMicroseconds shr 16), Byte(AMicroseconds shr 8), Byte(AMicroseconds)]);
end;

class function TTestMidiBuilder.EndOfTrack(const ADelta: Cardinal): TBytes;
begin
  Result := Meta(ADelta, $2F, []);
end;

class function TTestMidiBuilder.SysEx(const ADelta: Cardinal; const AData: array of Byte): TBytes;
begin
  Result := Join([VariableLength(ADelta), Bytes([$F0]), VariableLength(Length(AData)), Bytes(AData)]);
end;

class function TTestMidiBuilder.Running(const ADelta: Cardinal; const AParams: array of Byte): TBytes;
begin
  Result := Join([VariableLength(ADelta), Bytes(AParams)]);
end;

end.
