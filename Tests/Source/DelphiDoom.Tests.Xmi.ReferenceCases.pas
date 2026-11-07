{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the XMI library - the songs of the reference golden    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.ReferenceCases;

// The same unit builds the songs for the program that wrote
// Tests\Data\Xmi\reference.golden.txt with the old converter (xmi_core, before
// it was deleted) and for the test that compares the library with it: the
// bytes are written here once, and nothing else may change them

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>A song of the golden and the track to convert</summary>
  TXmiReferenceCase = record
    Name: string;
    Track: Integer;
    Data: TBytes;
  end;

  /// <summary>
  ///   XMI and CMF songs that go through the parts of the readers and of the
  ///   converters that the simple samples do not reach: every kind of event,
  ///   damaged data, the layouts of the containers, the drums of CMF
  /// </summary>
  TXmiReferenceCases = class
  strict private
    class function Concat(const AParts: array of TBytes): TBytes; static;
    class function BigEndian32(AValue: Cardinal): TBytes; static;
    class function LittleEndian16(AValue: Word): TBytes; static;
    class function Tag(const AName: AnsiString): TBytes; static;
    class function Chunk(const AName: AnsiString; const AData: TBytes): TBytes; static;
    class function Group(const AKind, ASub: AnsiString; const AContent: TBytes): TBytes; static;
    class function XmiSong(const AEvents: TBytes): TBytes; static;
    class function XmiFile(const ASongs: array of TBytes; AInfoCount: Integer): TBytes; static;
    class function CmfFile(const AEvents, ATrailer: TBytes; AVersion: Word;
      ATitle, AComposer, ARemarks, AInstruments: Word): TBytes; static;
    class function Repeated(AValue: Byte; ACount: Integer): TBytes; static;
    class procedure Add(var ACases: TArray<TXmiReferenceCase>; const AName: string;
      ATrack: Integer; const AData: TBytes); static;
  public
    /// <summary>Every song of the golden, always in the same order</summary>
    class function All: TArray<TXmiReferenceCase>; static;
    /// <summary>The bytes as two hexadecimal digits each, upper case</summary>
    class function ToHex(const AData: TBytes): string; static;
  end;

implementation

const
  // Where the music starts in the CMF files of these songs: the header, the
  // 16 bytes of the channels in use and the number of instruments
  CMF_MUSIC_OFFSET = 37;

{ TXmiReferenceCases }

class function TXmiReferenceCases.Concat(const AParts: array of TBytes): TBytes;
var
  LIndex, LSize, LOffset: Integer;
begin
  LSize := 0;
  for LIndex := 0 to High(AParts) do
    Inc(LSize, Length(AParts[LIndex]));
  SetLength(Result, LSize);
  LOffset := 0;
  for LIndex := 0 to High(AParts) do
  begin
    if Length(AParts[LIndex]) > 0 then
      Move(AParts[LIndex][0], Result[LOffset], Length(AParts[LIndex]));
    Inc(LOffset, Length(AParts[LIndex]));
  end;
end;

class function TXmiReferenceCases.BigEndian32(AValue: Cardinal): TBytes;
begin
  Result := TBytes.Create(Byte(AValue shr 24), Byte(AValue shr 16), Byte(AValue shr 8),
    Byte(AValue));
end;

class function TXmiReferenceCases.LittleEndian16(AValue: Word): TBytes;
begin
  Result := TBytes.Create(Byte(AValue), Byte(AValue shr 8));
end;

class function TXmiReferenceCases.Tag(const AName: AnsiString): TBytes;
begin
  SetLength(Result, 4);
  Move(PAnsiChar(AName)^, Result[0], 4);
end;

// A chunk of IFF: name, size (big endian) and data, with a byte of padding if odd
class function TXmiReferenceCases.Chunk(const AName: AnsiString; const AData: TBytes): TBytes;
begin
  Result := Concat([Tag(AName), BigEndian32(Length(AData)), AData]);
  if Odd(Length(AData)) then
    Result := Concat([Result, TBytes.Create(0)]);
end;

// A FORM or CAT of IFF: its size counts the sub type and the content
class function TXmiReferenceCases.Group(const AKind, ASub: AnsiString;
  const AContent: TBytes): TBytes;
begin
  Result := Concat([Tag(AKind), BigEndian32(4 + Length(AContent)), Tag(ASub), AContent]);
end;

class function TXmiReferenceCases.XmiSong(const AEvents: TBytes): TBytes;
begin
  Result := Group('FORM', 'XMID', Chunk('EVNT', AEvents));
end;

// FORM XDIR with INFO (unless AInfoCount is negative), then CAT XMID with the songs
class function TXmiReferenceCases.XmiFile(const ASongs: array of TBytes;
  AInfoCount: Integer): TBytes;
var
  LDirectory: TBytes;
begin
  if AInfoCount >= 0 then
    LDirectory := Chunk('INFO', LittleEndian16(AInfoCount))
  else
    LDirectory := Chunk('NONE', LittleEndian16(0));
  Result := Concat([Group('FORM', 'XDIR', LDirectory), Group('CAT ', 'XMID', Concat(ASongs))]);
end;

class function TXmiReferenceCases.CmfFile(const AEvents, ATrailer: TBytes; AVersion: Word;
  ATitle, AComposer, ARemarks, AInstruments: Word): TBytes;
begin
  Result := Concat([Tag('CTMF'), LittleEndian16(AVersion), LittleEndian16(AInstruments),
    LittleEndian16(CMF_MUSIC_OFFSET), LittleEndian16(48), LittleEndian16(96),
    LittleEndian16(ATitle), LittleEndian16(AComposer), LittleEndian16(ARemarks),
    Repeated(0, 16), TBytes.Create(0), AEvents, ATrailer]);
end;

class function TXmiReferenceCases.Repeated(AValue: Byte; ACount: Integer): TBytes;
begin
  SetLength(Result, ACount);
  if ACount > 0 then
    FillChar(Result[0], ACount, AValue);
end;

class procedure TXmiReferenceCases.Add(var ACases: TArray<TXmiReferenceCase>;
  const AName: string; ATrack: Integer; const AData: TBytes);
begin
  SetLength(ACases, Length(ACases) + 1);
  ACases[High(ACases)].Name := AName;
  ACases[High(ACases)].Track := ATrack;
  ACases[High(ACases)].Data := AData;
end;

class function TXmiReferenceCases.All: TArray<TXmiReferenceCase>;
var
  LEvents, LDrums, LShortSong, LTitle: TBytes;
  LTitleOffset: Word;
begin
  Result := nil;

  // XMIDI: every kind of event, notes that end in every order, the end of the
  // track with notes still on, delays of more than one byte
  LEvents := Concat([
    // program, controller, aftertouch, channel pressure, pitch bend
    TBytes.Create($C0, $05, $B0, $07, $64, $A0, $3C, $20, $D0, $40, $E0, $00, $40),
    // sequence number, channel prefix 3, channel prefix 20 (not a channel), port prefix 2
    TBytes.Create($FF, $00, $02, $00, $07, $FF, $20, $01, $03, $FF, $20, $01, $14,
      $FF, $21, $01, $02),
    // SMPTE offset of 5 and of 2 bytes, time signature of 4 and of 6, key signature
    TBytes.Create($FF, $54, $05, $01, $02, $03, $04, $05, $FF, $54, $02, $01, $02,
      $FF, $58, $04, $04, $02, $18, $08, $FF, $58, $06, $03, $02, $18, $08, $09, $0A,
      $FF, $59, $02, $01, $00),
    // a text with a zero inside, sequencer specific data
    TBytes.Create($FF, $01, $05, $41, $62, $00, $63, $64, $FF, $7F, $03, $01, $02, $03),
    // song position, song select, time code, tune request, end of exclusive
    TBytes.Create($F2, $10, $20, $F3, $05, $F1, $33, $F6, $F7),
    // tempo, a note of 10 ticks, a note of 50 ticks, a parameter over 127
    TBytes.Create($FF, $51, $03, $0F, $42, $40, $90, $3C, $64, $0A, $91, $40, $50, $32,
      $92, $FF, $64, $01),
    // delay 5, a Note Off that XMIDI does not have
    TBytes.Create($05, $80, $3C, $00),
    // delay 20, then two notes of the same channel and length
    TBytes.Create($14, $93, $43, $60, $0A, $93, $44, $60, $0A),
    // delay 270, a program change, a note of 128 ticks, the end of the track
    TBytes.Create($7F, $7F, $10, $C1, $06, $94, $30, $40, $81, $00, $FF, $2F, $00)]);
  Add(Result, 'xmi_every_event', 0, XmiFile([XmiSong(LEvents)], 1));

  LShortSong := TBytes.Create($00, $C0, $05, $00, $FF, $2F, $00);

  // Damaged events: each one ends the track where it is
  Add(Result, 'xmi_duration_overflow', 0, XmiFile([XmiSong(Concat([
    TBytes.Create($90, $3C, $64), Repeated($FF, 10), TBytes.Create($01, $FF, $2F, $00)]))], 1));
  Add(Result, 'xmi_duration_truncated', 0, XmiFile([XmiSong(
    TBytes.Create($C0, $05, $90, $3C, $64, $81))], 1));
  Add(Result, 'xmi_delay_truncated', 0, XmiFile([XmiSong(
    TBytes.Create($C0, $05, $7F, $7F))], 1));
  Add(Result, 'xmi_parameter_truncated', 0, XmiFile([XmiSong(
    TBytes.Create($C0, $05, $B0, $07))], 1));
  Add(Result, 'xmi_length_overflow', 0, XmiFile([XmiSong(Concat([
    TBytes.Create($C0, $05, $F0), Repeated($FF, 10), TBytes.Create($02, $FF, $01),
    Repeated($FF, 10), TBytes.Create($02, $FF, $2F, $00)]))], 1));
  Add(Result, 'xmi_exclusive_length_truncated', 0, XmiFile([XmiSong(
    TBytes.Create($C0, $05, $F0, $81))], 1));
  Add(Result, 'xmi_meta_length_truncated', 0, XmiFile([XmiSong(
    TBytes.Create($C0, $05, $FF, $51, $81))], 1));
  Add(Result, 'xmi_meta_value_truncated', 0, XmiFile([XmiSong(
    TBytes.Create($C0, $05, $FF, $51, $03, $07))], 1));
  Add(Result, 'xmi_fixed_meta_truncated', 0, XmiFile([XmiSong(
    TBytes.Create($C0, $05, $FF, $58, $04, $04))], 1));

  // The layouts of the container
  Add(Result, 'xmi_form_without_cat', 0, XmiSong(LShortSong));
  Add(Result, 'xmi_two_forms_without_cat', 1, Concat([XmiSong(LShortSong),
    XmiSong(TBytes.Create($00, $C1, $07, $00, $FF, $2F, $00))]));
  Add(Result, 'xmi_song_without_events', 0, XmiFile([Group('FORM', 'XMID',
    Chunk('TIMB', TBytes.Create(1, 2)))], 1));
  Add(Result, 'xmi_info_beyond_the_songs', 0, XmiFile([XmiSong(LShortSong)], 3));
  Add(Result, 'xmi_info_zero', 1, XmiFile([XmiSong(LShortSong), XmiSong(LShortSong)], 0));
  Add(Result, 'xmi_without_info', 0, XmiFile([XmiSong(LShortSong)], -1));
  Add(Result, 'xmi_events_beyond_the_file', 0, Copy(XmiFile([XmiSong(Concat([LShortSong,
    Repeated($00, 20)]))], 1), 0, 60));

  // CMF: the drums of the rhythm mode, a data byte with no status, the
  // controllers of CMF, events of standard MIDI
  LDrums := Concat([
    // a data byte before any status: skipped, and the next byte is a status
    TBytes.Create($00, $3C, $C0, $05),
    // the rhythm mode, a note of the channel 10 (no drum)
    TBytes.Create($00, $B0, $67, $01, $00, $9A, $30, $64),
    // bass drum, snare drum
    TBytes.Create($00, $9B, $24, $64, $00, $9B, $25, $64, $00, $9C, $28, $64, $00, $9C, $29, $64),
    // tom
    TBytes.Create($00, $9D, $26, $64, $00, $9D, $27, $64, $00, $9D, $28, $64, $00, $9D, $29, $64,
      $00, $9D, $2A, $64, $00, $9D, $2B, $64),
    // cymbal, hi-hat
    TBytes.Create($00, $9E, $32, $64, $00, $9E, $33, $64, $00, $9E, $42, $64, $00, $9F, $2C, $64,
      $00, $9F, $2D, $64),
    // note off of a drum, program of a drum channel, transpose down, marker
    TBytes.Create($10, $8B, $24, $40, $00, $CB, $03, $00, $B0, $69, $02, $00, $B0, $66, $07),
    // pitch bend, the rhythm mode off, a note of the channel 12
    TBytes.Create($00, $E0, $00, $40, $00, $B0, $67, $00, $00, $9C, $30, $64),
    // system exclusive and its end with data, song position, tempo, the end
    TBytes.Create($00, $F0, $03, $7E, $7F, $01, $00, $F7, $02, $01, $02, $00, $F2, $10, $20,
      $00, $FF, $51, $03, $07, $A1, $20, $00, $FF, $2F, $00)]);
  Add(Result, 'cmf_drums', 0, CmfFile(LDrums, nil, $0101, 0, 0, 0, 0));

  // Where the music ends: the title, the composer, the remarks or the instruments after it
  LTitle := Concat([TBytes.Create($54, $69, $74, $6F, $6C, $6F, $00), Repeated($00, 4)]);
  LTitleOffset := CMF_MUSIC_OFFSET + Length(LShortSong);
  Add(Result, 'cmf_title_after_music', 0, CmfFile(LShortSong, LTitle, $0100,
    LTitleOffset, 0, 0, 0));
  Add(Result, 'cmf_composer_after_music', 0, CmfFile(LShortSong, LTitle, $0100,
    0, LTitleOffset, 0, 0));
  Add(Result, 'cmf_remarks_after_music', 0, CmfFile(LShortSong, LTitle, $0100,
    0, 0, LTitleOffset, 0));
  Add(Result, 'cmf_instruments_after_music', 0, CmfFile(LShortSong, LTitle, $0100,
    0, 0, 0, LTitleOffset));
  Add(Result, 'cmf_offsets_beyond_the_file', 0, CmfFile(LShortSong, nil, $0100,
    $7000, $7001, $7002, 0));
  Add(Result, 'cmf_bad_version', 0, CmfFile(LShortSong, nil, $0200, 0, 0, 0, 0));

  // Damaged CMF events
  Add(Result, 'cmf_delay_truncated', 0, CmfFile(TBytes.Create($00, $C0, $05, $81), nil,
    $0100, 0, 0, 0, 0));
  Add(Result, 'cmf_parameter_truncated', 0, CmfFile(TBytes.Create($00, $C0, $05, $00, $B0, $07),
    nil, $0100, 0, 0, 0, 0));
  Add(Result, 'cmf_meta_truncated', 0, CmfFile(TBytes.Create($00, $C0, $05, $00, $FF, $51, $83),
    nil, $0100, 0, 0, 0, 0));
end;

class function TXmiReferenceCases.ToHex(const AData: TBytes): string;
var
  LIndex: Integer;
  LBuilder: TStringBuilder;
begin
  LBuilder := TStringBuilder.Create(2 * Length(AData));
  try
    for LIndex := 0 to High(AData) do
      LBuilder.Append(IntToHex(AData[LIndex], 2));
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

end.
