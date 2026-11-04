{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiConverter                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Converter;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiConverter = class(TObject)
  private
    function BuildRichXmi(const AEvents: array of Byte): TBytes;
    function RichEvents: TBytes;
    function BuildRichCmf(const AEvents: array of Byte): TBytes;
    function RichCmfEvents: TBytes;
  public
    [Test]
    procedure TestDetectsEveryFormat;
    [Test]
    procedure TestDetectsNothingInGarbage;
    [Test]
    procedure TestCountsTheTracksOfAnXmi;
    [Test]
    procedure TestCountOfAnUnknownFormatIsRefused;
    [Test]
    procedure TestConvertedFileIsAStandardMidiFile;
    [Test]
    procedure TestTrackOutOfRange;
    [Test]
    procedure TestGarbageIsNotConverted;
    [Test]
    procedure TestRichXmiGivesTheExpectedFile;
    [Test]
    procedure TestRichCmfGivesTheExpectedFile;
    [Test]
    procedure TestCmfIsConverted;
    [Test]
    procedure TestCmfDropsTheControllersMidiDoesNotKnow;
    [Test]
    procedure TestNoteWithoutDurationIsTurnedOffRightAway;
    [Test]
    procedure TestTwoSongsCanBeConvertedOneAtATime;
  end;

implementation

uses
  System.Classes, DelphiDoom.Xmi.Intf, DelphiDoom.Xmi.Midi.Types,
  DelphiDoom.Xmi.Converter,
  DelphiDoom.Tests.Xmi.Samples;

const
  MIDI_HEADER_SIZE = 14;
  // Division of a converted XMIDI file: 120 ticks a second
  XMI_DIVISION = 60;

{ TTestXmiConverter }

// FORM XDIR / INFO with the number of songs, then CAT XMID with one FORM
// XMID per song
function TTestXmiConverter.BuildRichXmi(const AEvents: array of Byte): TBytes;
var
  LStream: TBytesStream;
  LEventsSize: Cardinal;
  LPadding: Cardinal;
  LZero: Byte;

  procedure WriteTag(const ATag: AnsiString);
  begin
    LStream.WriteBuffer(PAnsiChar(ATag)^, 4);
  end;

  procedure WriteBigEndian32(AValue: Cardinal);
  var
    LBytes: array[0..3] of Byte;
  begin
    LBytes[0] := Byte(AValue shr 24);
    LBytes[1] := Byte(AValue shr 16);
    LBytes[2] := Byte(AValue shr 8);
    LBytes[3] := Byte(AValue);
    LStream.WriteBuffer(LBytes, 4);
  end;

  procedure WriteWord(AValue: Word);
  begin
    LStream.WriteBuffer(AValue, 2);
  end;

begin
  LEventsSize := Length(AEvents);
  LPadding := LEventsSize and 1;
  LStream := TBytesStream.Create;
  try
    WriteTag('FORM');
    WriteBigEndian32(14);
    WriteTag('XDIR');
    WriteTag('INFO');
    WriteBigEndian32(2);
    WriteWord(1);

    WriteTag('CAT ');
    WriteBigEndian32(4 + 8 + 4 + 8 + LEventsSize + LPadding);
    WriteTag('XMID');
    WriteTag('FORM');
    WriteBigEndian32(4 + 8 + LEventsSize + LPadding);
    WriteTag('XMID');
    WriteTag('EVNT');
    WriteBigEndian32(LEventsSize);
    if LEventsSize > 0 then
      LStream.WriteBuffer(AEvents[0], LEventsSize);
    if LPadding = 1 then
    begin
      LZero := 0;
      LStream.WriteBuffer(LZero, 1);
    end;

    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

// Program change, volume, tempo, three notes of different length, a pitch
// bend, a delay of more than 127 ticks, a system exclusive, a track name and
// the end of the track
function TTestXmiConverter.RichEvents: TBytes;
begin
  Result := TBytes.Create(
    $00, $C0, $05,
    $00, $B0, $07, $64,
    $00, $FF, $51, $03, $07, $A1, $20,
    $00, $90, $3C, $64, $60,
    $0A, $90, $40, $64, $30,
    $14, $E0, $00, $40,
    $7F, $05, $90, $43, $64, $00,
    $00, $F0, $04, $7E, $7F, $09, $01,
    $00, $FF, $03, $04, $54, $65, $73, $74,
    $64, $FF, $2F, $00);
end;

// The header of the sample CMF, then the events of a standard MIDI track
function TTestXmiConverter.BuildRichCmf(const AEvents: array of Byte): TBytes;
const
  MUSIC_OFFSET = 37;
var
  LStream: TBytesStream;
  LIndex: Integer;
  LZero: Byte;

  procedure WriteWord(AValue: Word);
  begin
    LStream.WriteBuffer(AValue, 2);
  end;

begin
  LStream := TBytesStream.Create;
  try
    LStream.WriteBuffer(PAnsiChar('CTMF')^, 4);
    WriteWord($0100);
    WriteWord(0);
    WriteWord(MUSIC_OFFSET);
    WriteWord(48);
    WriteWord(96);
    WriteWord(0);
    WriteWord(0);
    WriteWord(0);
    LZero := 0;
    for LIndex := 0 to 15 do
      LStream.WriteBuffer(LZero, 1);
    LStream.WriteBuffer(LZero, 1);
    if Length(AEvents) > 0 then
      LStream.WriteBuffer(AEvents[0], Length(AEvents));

    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

// Program change, the CMF controllers (marker, rhythm mode, AM and vibrato,
// transpose), drum notes on the channel 11 and a program change on it, a
// tempo, a note, running status, the end of the track
function TTestXmiConverter.RichCmfEvents: TBytes;
begin
  Result := TBytes.Create(
    $00, $C0, $05,
    $00, $B0, $66, $05,
    $00, $B0, $67, $01,
    $00, $9B, $28, $64,
    $10, $8B, $28, $40,
    $00, $B0, $63, $01,
    $00, $B0, $68, $05,
    $08, $C0, $07,
    $00, $CB, $03,
    $00, $FF, $51, $03, $07, $A1, $20,
    $20, $90, $3C, $64,
    $10, $3E, $64,
    $10, $80, $3C, $40,
    $00, $FF, $2F, $00);
end;

procedure TTestXmiConverter.TestDetectsEveryFormat;
var
  LXmi, LCmf, LSop, LMidi: TBytes;
begin
  LXmi := TXmiSamples.BuildXmi;
  LCmf := TXmiSamples.BuildCmf;
  LSop := TXmiSamples.BuildSopHeader;
  LMidi := TXmiSamples.BuildMidi;
  Assert.AreEqual(Ord(TXmiFormat.Xmi),
    Ord(TXmiConverter.DetectFormat(Pointer(LXmi), Length(LXmi))));
  Assert.AreEqual(Ord(TXmiFormat.Cmf),
    Ord(TXmiConverter.DetectFormat(Pointer(LCmf), Length(LCmf))));
  Assert.AreEqual(Ord(TXmiFormat.Sop),
    Ord(TXmiConverter.DetectFormat(Pointer(LSop), Length(LSop))));
  Assert.AreEqual(Ord(TXmiFormat.Midi),
    Ord(TXmiConverter.DetectFormat(Pointer(LMidi), Length(LMidi))));
end;

procedure TTestXmiConverter.TestDetectsNothingInGarbage;
var
  LGarbage: TBytes;
begin
  LGarbage := TXmiSamples.BuildGarbage(64);
  Assert.AreEqual(Ord(TXmiFormat.Unknown),
    Ord(TXmiConverter.DetectFormat(Pointer(LGarbage), Length(LGarbage))));
  Assert.AreEqual(Ord(TXmiFormat.Unknown),
    Ord(TXmiConverter.DetectFormat(nil, 0)));
end;

procedure TTestXmiConverter.TestCountsTheTracksOfAnXmi;
var
  LXmi: TBytes;
  LCount: Integer;
begin
  LXmi := TXmiSamples.BuildXmi;
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.CountTracks(Pointer(LXmi), Length(LXmi), LCount)));
  Assert.AreEqual(1, LCount);
end;

procedure TTestXmiConverter.TestCountOfAnUnknownFormatIsRefused;
var
  LGarbage: TBytes;
  LCount: Integer;
begin
  LGarbage := TXmiSamples.BuildGarbage(64);
  Assert.AreEqual(Ord(TXmiConversionStatus.UnknownFormat),
    Ord(TXmiConverter.CountTracks(Pointer(LGarbage), Length(LGarbage), LCount)));
  Assert.AreEqual(0, LCount);
end;

procedure TTestXmiConverter.TestConvertedFileIsAStandardMidiFile;
var
  LXmi, LMidi: TBytes;
begin
  LXmi := TXmiSamples.BuildXmi;
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LXmi), Length(LXmi), 0, LMidi)));
  Assert.IsTrue(Length(LMidi) > MIDI_HEADER_SIZE);
  Assert.AreEqual('MThd', TXmiSamples.TagAt(LMidi, 0));
  Assert.AreEqual('MTrk', TXmiSamples.TagAt(LMidi, MIDI_HEADER_SIZE));
  // One track, and the division of XMIDI
  Assert.AreEqual(1, Integer((LMidi[10] shl 8) or LMidi[11]));
  Assert.AreEqual(Integer(XMI_DIVISION), Integer((LMidi[12] shl 8) or LMidi[13]));
end;

procedure TTestXmiConverter.TestTrackOutOfRange;
var
  LXmi, LMidi: TBytes;
begin
  LXmi := TXmiSamples.BuildXmi;
  Assert.AreEqual(Ord(TXmiConversionStatus.TrackOutOfRange),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LXmi), Length(LXmi), 1, LMidi)));
  Assert.AreEqual(Ord(TXmiConversionStatus.TrackOutOfRange),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LXmi), Length(LXmi), -1, LMidi)));
end;

procedure TTestXmiConverter.TestGarbageIsNotConverted;
var
  LGarbage, LMidi: TBytes;
begin
  LGarbage := TXmiSamples.BuildGarbage(64);
  Assert.AreEqual(Ord(TXmiConversionStatus.UnknownFormat),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LGarbage), Length(LGarbage), 0, LMidi)));
  Assert.AreEqual(0, Length(LMidi));
end;

procedure TTestXmiConverter.TestRichXmiGivesTheExpectedFile;
var
  LXmi, LMidi, LExpected: TBytes;
begin
  LXmi := BuildRichXmi(RichEvents);
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LXmi), Length(LXmi), 0, LMidi)));

  LExpected := TBytes.Create(
    $4D, $54, $68, $64, $00, $00, $00, $06, $00, $02, $00, $01, $00, $3C,
    $4D, $54, $72, $6B, $00, $00, $00, $3C,
    $00, $C0, $05,
    $00, $B0, $07, $64,
    $00, $FF, $51, $03, $07, $A1, $20,
    $00, $90, $3C, $64,
    $0A, $90, $40, $64,
    $14, $E0, $00, $40,
    $1C, $80, $40, $00,
    $26, $3C, $00,
    $42, $90, $43, $64,
    $00, $80, $43, $00,
    $00, $F0, $04, $7E, $7F, $09, $01,
    $00, $FF, $03, $04, $54, $65, $73, $74,
    $64, $FF, $2F, $00);
  Assert.AreEqual(Length(LExpected), Length(LMidi), 'size');
  Assert.AreEqualMemory(Pointer(LExpected), Pointer(LMidi), Length(LExpected));
end;

// The CMF controllers and the drums are changed or dropped, the tempo events
// count double and a tempo of one second per quarter note opens the song
procedure TTestXmiConverter.TestRichCmfGivesTheExpectedFile;
var
  LCmf, LMidi, LExpected: TBytes;
begin
  LCmf := BuildRichCmf(RichCmfEvents);
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LCmf), Length(LCmf), 0, LMidi)));

  LExpected := TBytes.Create(
    $4D, $54, $68, $64, $00, $00, $00, $06, $00, $00, $00, $01, $00, $60,
    $4D, $54, $72, $6B, $00, $00, $00, $30,
    $00, $FF, $51, $03, $0F, $42, $40,
    $00, $C0, $05,
    $00, $FF, $06, $01, $35,
    $00, $99, $24, $64,
    $10, $89, $24, $40,
    $08, $C0, $07,
    $00, $FF, $51, $03, $0F, $42, $40,
    $20, $90, $3C, $64,
    $10, $3E, $64,
    $10, $80, $3C, $40,
    $00, $FF, $2F, $00);
  Assert.AreEqual(Length(LExpected), Length(LMidi), 'size');
  Assert.AreEqualMemory(Pointer(LExpected), Pointer(LMidi), Length(LExpected));
end;

procedure TTestXmiConverter.TestCmfIsConverted;
var
  LCmf, LMidi: TBytes;
  LCount: Integer;
begin
  LCmf := BuildRichCmf(RichCmfEvents);
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.CountTracks(Pointer(LCmf), Length(LCmf), LCount)));
  Assert.AreEqual(1, LCount);
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LCmf), Length(LCmf), 0, LMidi)));
  Assert.AreEqual('MThd', TXmiSamples.TagAt(LMidi, 0));
  // Type 0, one track, 96 ticks per second
  Assert.AreEqual(0, Integer((LMidi[8] shl 8) or LMidi[9]));
  Assert.AreEqual(1, Integer((LMidi[10] shl 8) or LMidi[11]));
  Assert.AreEqual(96, Integer((LMidi[12] shl 8) or LMidi[13]));
end;

procedure TTestXmiConverter.TestCmfDropsTheControllersMidiDoesNotKnow;
var
  LCmf, LMidi: TBytes;
  LIndex: Integer;
  LControllers: Integer;
begin
  LCmf := BuildRichCmf(RichCmfEvents);
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LCmf), Length(LCmf), 0, LMidi)));

  // No Control Change of the CMF controllers is left in the file
  LControllers := 0;
  for LIndex := 22 to Length(LMidi) - 3 do
    if (LMidi[LIndex] = $B0) and (LMidi[LIndex + 1] in [$63, $67, $68, $69]) then
      Inc(LControllers);
  Assert.AreEqual(0, LControllers);
end;

procedure TTestXmiConverter.TestNoteWithoutDurationIsTurnedOffRightAway;
var
  LXmi, LMidi: TBytes;
  LIndex: Integer;
  LNoteOnAt: Integer;
begin
  // Delay 0, note on channel 0 with duration 0, then the end of the track
  LXmi := BuildRichXmi(TBytes.Create($00, $90, $3C, $64, $00, $00, $FF, $2F, $00));
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LXmi), Length(LXmi), 0, LMidi)));

  // After the track header: delay 0, 90 3C 64, delay 0, 80 3C 00
  LNoteOnAt := -1;
  for LIndex := 22 to Length(LMidi) - 4 do
    if (LMidi[LIndex] = $90) and (LMidi[LIndex + 1] = $3C) then
    begin
      LNoteOnAt := LIndex;
      Break;
    end;
  Assert.IsTrue(LNoteOnAt > 0, 'the note on is there');
  Assert.AreEqual($00, Integer(LMidi[LNoteOnAt + 3]));
  Assert.AreEqual($80, Integer(LMidi[LNoteOnAt + 4]));
  Assert.AreEqual($3C, Integer(LMidi[LNoteOnAt + 5]));
end;

procedure TTestXmiConverter.TestTwoSongsCanBeConvertedOneAtATime;
var
  LXmi, LFirst, LSecond: TBytes;
begin
  // Converting does not keep anything of the song before
  LXmi := BuildRichXmi(RichEvents);
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LXmi), Length(LXmi), 0, LFirst)));
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LXmi), Length(LXmi), 0, LSecond)));
  Assert.AreEqual(Length(LFirst), Length(LSecond));
  Assert.AreEqualMemory(Pointer(LFirst), Pointer(LSecond), Length(LFirst));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiConverter);

end.

