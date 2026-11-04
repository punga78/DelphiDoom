{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiConverter, against the converter of xmi_core       }
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
    function ConvertWithTheOldCode(const ASource: TBytes; ATrack: Integer): TBytes;
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
    procedure TestSimpleXmiMatchesTheOldConverter;
    [Test]
    procedure TestRichXmiMatchesTheOldConverter;
    [Test]
    procedure TestNoteWithoutDurationIsTurnedOffRightAway;
    [Test]
    procedure TestTwoSongsCanBeConvertedOneAtATime;
  end;

implementation

uses
  System.Classes, DelphiDoom.Xmi.Intf, DelphiDoom.Xmi.Midi.Types,
  DelphiDoom.Xmi.Native, DelphiDoom.Xmi.Converter,
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
  LPadding: Integer;
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

function TTestXmiConverter.ConvertWithTheOldCode(const ASource: TBytes;
  ATrack: Integer): TBytes;
var
  LStatus: TXmiNativeStatus;
begin
  XmiNativeAcquire;
  try
    LStatus := XmiNativeConvertToMidi(Pointer(ASource), Length(ASource), ATrack,
      Result);
    Assert.AreEqual(Ord(TXmiNativeStatus.Ok), Ord(LStatus),
      'the old converter accepts the song');
  finally
    XmiNativeRelease;
  end;
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
  Assert.AreEqual(1, (LMidi[10] shl 8) or LMidi[11]);
  Assert.AreEqual(XMI_DIVISION, (LMidi[12] shl 8) or LMidi[13]);
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

procedure TTestXmiConverter.TestSimpleXmiMatchesTheOldConverter;
var
  LXmi, LNew: TBytes;
begin
  LXmi := TXmiSamples.BuildXmi;
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LXmi), Length(LXmi), 0, LNew)));
  Assert.AreEqual(Length(ConvertWithTheOldCode(LXmi, 0)), Length(LNew));
  Assert.AreEqualMemory(Pointer(ConvertWithTheOldCode(LXmi, 0)), Pointer(LNew),
    Length(LNew));
end;

procedure TTestXmiConverter.TestRichXmiMatchesTheOldConverter;
var
  LXmi, LNew, LOld: TBytes;
begin
  LXmi := BuildRichXmi(RichEvents);
  LOld := ConvertWithTheOldCode(LXmi, 0);
  Assert.AreEqual(Ord(TXmiConversionStatus.Ok),
    Ord(TXmiConverter.ConvertToMidi(Pointer(LXmi), Length(LXmi), 0, LNew)));
  Assert.AreEqual(Length(LOld), Length(LNew), 'same size');
  Assert.AreEqualMemory(Pointer(LOld), Pointer(LNew), Length(LOld));
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
