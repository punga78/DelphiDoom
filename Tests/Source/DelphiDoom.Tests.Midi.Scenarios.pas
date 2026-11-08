{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library tests - the songs and the way they are played,       }
{  shared by the tests and by the program that records the old player            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Midi.Scenarios;

{$Q-}
{$R-}
// The digest wraps around

interface

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Tests.M2m.MidiBuilder;

const
  /// <summary>The bytes of a buffer of the stream, as in the old player</summary>
  SCENARIO_BUFFER_LENGTH = 1024;
  /// <summary>The blocks asked for after the two of the setup</summary>
  SCENARIO_ROUNDS = 24;
  /// <summary>The tempo given to the events of a MUS song, and the events of a piece of it</summary>
  SCENARIO_MUS_TEMPO = 140;
  SCENARIO_MUS_PIECE = 512;
  /// <summary>The volumes of the menu that the MUS scenario sets, one after the other</summary>
  SCENARIO_MUS_VOLUMES: array[0..3] of Integer = (15, 8, 0, 3);
  /// <summary>The pieces taken after each volume</summary>
  SCENARIO_MUS_PIECES_PER_VOLUME = 6;

type
  /// <summary>
  ///   How the song is played: the sequence of calls that the old TMidi made. The two blocks of
  ///   the setup come first (the first with the reset), then Play, then the blocks that the
  ///   stream asks for when a buffer comes back, until the song is over or SCENARIO_ROUNDS
  /// </summary>
  TMidiProtocol = (
    /// <summary>Play(True) with no tempo event requested</summary>
    mpLooped,
    /// <summary>Play(True) as the engine does it: the next event is preceded by the tempo</summary>
    mpLoopedWithTempo,
    /// <summary>Play(False) with no tempo event requested: the song ends</summary>
    mpOnce
  );

  TMidiScenarioFile = record
    Name: string;
    Bytes: TBytes;
  end;

  /// <summary>What a protocol gave: the codes and the bytes of every block</summary>
  TMidiRunRecord = record
    Failed: Boolean;
    Codes: TArray<Integer>;
    Blocks: TArray<TBytes>;
    procedure AddBlock(ACode: Integer; const ABytes: TBytes);
    /// <summary>One line: counts, codes and the digest of the blocks (or ERROR)</summary>
    function ToLine(const AName: string; AProtocol: TMidiProtocol): string;
    /// <summary>The same line with a label of the caller instead of name/protocol</summary>
    function ToText(const ALabel: string): string;
  end;

  TMidiScenarios = class
  public
    class function Fnv1a(const ABytes: TBytes; const ASeed: UInt64 = 0): UInt64; static;
    class function ProtocolName(AProtocol: TMidiProtocol): string; static;
    /// <summary>The songs built in memory</summary>
    class function All: TArray<TMidiScenarioFile>; static;
    /// <summary>
    ///   The lumps of a WAD that start with MThd (AMus false) or with MUS and $1A (AMus true),
    ///   named wad:file:lump. Nothing if the file does not exist or is not a WAD
    /// </summary>
    class function WadSongs(const APath: string; AMus: Boolean): TArray<TMidiScenarioFile>; static;
  end;

implementation

const
  FNV_OFFSET = UInt64($CBF29CE484222325);
  FNV_PRIME = UInt64($100000001B3);

type
  TB = TTestMidiBuilder;

procedure TMidiRunRecord.AddBlock(ACode: Integer; const ABytes: TBytes);
begin
  SetLength(Codes, Length(Codes) + 1);
  Codes[High(Codes)] := ACode;
  SetLength(Blocks, Length(Blocks) + 1);
  Blocks[High(Blocks)] := ABytes;
end;

function TMidiRunRecord.ToLine(const AName: string; AProtocol: TMidiProtocol): string;
begin
  Result := ToText(AName + '/' + TMidiScenarios.ProtocolName(AProtocol));
end;

function TMidiRunRecord.ToText(const ALabel: string): string;
var
  LIndex: Integer;
  LTotal: Integer;
  LDigest: UInt64;
  LCodes: string;
  LFirst: UInt64;
begin
  if Failed then
  begin
    Result := ALabel + ' ERROR';
    Exit;
  end;
  LTotal := 0;
  LDigest := FNV_OFFSET;
  LCodes := '';
  LFirst := FNV_OFFSET;
  for LIndex := 0 to High(Blocks) do
  begin
    Inc(LTotal, Length(Blocks[LIndex]));
    LDigest := TMidiScenarios.Fnv1a(Blocks[LIndex], LDigest);
    if LIndex = 0 then
      LFirst := TMidiScenarios.Fnv1a(Blocks[0], FNV_OFFSET);
    if LIndex > 0 then
      LCodes := LCodes + ',';
    LCodes := LCodes + IntToStr(Codes[LIndex]);
  end;
  Result := Format('%s blocks=%d bytes=%d codes=%s fnv=%s first=%s',
    [ALabel, Length(Blocks), LTotal, LCodes, IntToHex(Int64(LDigest), 16),
    IntToHex(Int64(LFirst), 16)]);
end;

class function TMidiScenarios.Fnv1a(const ABytes: TBytes; const ASeed: UInt64): UInt64;
var
  LIndex: Integer;
begin
  if ASeed = 0 then
    Result := FNV_OFFSET
  else
    Result := ASeed;
  for LIndex := 0 to High(ABytes) do
    Result := (Result xor ABytes[LIndex]) * FNV_PRIME;
end;

class function TMidiScenarios.ProtocolName(AProtocol: TMidiProtocol): string;
begin
  case AProtocol of
    mpLooped: Result := 'looped';
    mpLoopedWithTempo: Result := 'tempo';
  else
    Result := 'once';
  end;
end;

function Scenario(const AName: string; const ABytes: TBytes): TMidiScenarioFile;
begin
  Result.Name := AName;
  Result.Bytes := ABytes;
end;

function Song(const AFormat, ADivision: Integer; const ATracks: array of TBytes): TBytes;
var
  LParts: array of TBytes;
  LIndex: Integer;
begin
  SetLength(LParts, Length(ATracks) + 1);
  LParts[0] := TB.Header(AFormat, Length(ATracks), ADivision);
  for LIndex := 0 to High(ATracks) do
    LParts[LIndex + 1] := ATracks[LIndex];
  Result := TB.Join(LParts);
end;

function Notes(const ACount: Integer; const ADelta: Cardinal; const AChannel: Integer): TBytes;
var
  LParts: array of TBytes;
  LIndex: Integer;
begin
  SetLength(LParts, ACount * 2);
  for LIndex := 0 to ACount - 1 do
  begin
    LParts[LIndex * 2] := TB.NoteOn(ADelta, AChannel, 40 + (LIndex mod 40), 90);
    LParts[LIndex * 2 + 1] := TB.NoteOff(ADelta, AChannel, 40 + (LIndex mod 40), 0);
  end;
  Result := TB.Join(LParts);
end;

class function TMidiScenarios.All: TArray<TMidiScenarioFile>;
var
  LList: TArray<TMidiScenarioFile>;

  procedure Add(const AName: string; const ABytes: TBytes);
  begin
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := Scenario(AName, ABytes);
  end;

var
  LTrack: TBytes;
  LCut: TBytes;
begin
  LList := nil;

  Add('simple', Song(0, 96, [TB.Track(TB.Join([TB.Tempo(0, 500000), TB.ProgramChange(0, 0, 5),
    TB.NoteOn(0, 0, 60, 100), TB.NoteOff(48, 0, 60, 0), TB.NoteOn(0, 0, 64, 100),
    TB.NoteOff(96, 0, 64, 0), TB.EndOfTrack(0)]))]));

  Add('long', Song(0, 96, [TB.Track(TB.Join([TB.Tempo(0, 500000), Notes(600, 10, 0),
    TB.EndOfTrack(10)]))]));

  Add('tempo_changes', Song(0, 120, [TB.Track(TB.Join([TB.Tempo(0, 500000), Notes(120, 12, 0),
    TB.Tempo(0, 250000), Notes(120, 12, 1), TB.Tempo(7, 1000000), Notes(120, 12, 2),
    TB.EndOfTrack(0)]))]));

  Add('no_tempo', Song(0, 96, [TB.Track(TB.Join([Notes(200, 6, 3), TB.EndOfTrack(0)]))]));

  Add('sysex', Song(0, 96, [TB.Track(TB.Join([TB.Tempo(0, 500000), TB.NoteOn(0, 0, 60, 90),
    TB.SysEx(100, [$7E, $7F, $09, $01, $F7]), TB.NoteOff(100, 0, 60, 0),
    TB.SysEx(50, [$41, $10, $42]), TB.NoteOn(10, 0, 62, 90), TB.NoteOff(30, 0, 62, 0),
    Notes(80, 9, 0), TB.EndOfTrack(0)]))]));

  Add('meta_events', Song(0, 96, [TB.Track(TB.Join([TB.Meta(0, $03, [Ord('a'), Ord('b')]),
    TB.Tempo(0, 600000), TB.Meta(20, $58, [4, 2, 24, 8]), TB.Meta(20, $59, [0, 0]),
    TB.NoteOn(20, 0, 60, 90), TB.Meta(40, $01, [Ord('x')]), TB.NoteOff(40, 0, 60, 0),
    Notes(70, 8, 0), TB.EndOfTrack(0)]))]));

  Add('running_status', Song(0, 96, [TB.Track(TB.Join([TB.Tempo(0, 500000),
    TB.NoteOn(0, 0, 60, 90), TB.Running(10, [62, 90]), TB.Running(10, [64, 90]),
    TB.Running(10, [60, 0]), TB.Running(10, [62, 0]), TB.Running(10, [64, 0]),
    TB.ProgramChange(5, 2, 7), TB.Running(5, [9]), TB.EndOfTrack(0)]))]));

  // the running status goes on after a meta event, as in the old player
  Add('running_across_meta', Song(0, 96, [TB.Track(TB.Join([TB.Tempo(0, 500000),
    TB.NoteOn(0, 0, 60, 90), TB.Meta(10, $01, [Ord('t')]), TB.Running(10, [62, 90]),
    TB.SysEx(10, [1, 2, 3, $F7]), TB.Running(10, [64, 90]), TB.Running(10, [64, 0]),
    TB.EndOfTrack(0)]))]));

  Add('two_tracks', Song(1, 96, [
    TB.Track(TB.Join([TB.Tempo(0, 500000), Notes(60, 10, 0), TB.EndOfTrack(0)])),
    TB.Track(TB.Join([TB.NoteOn(0, 1, 50, 80), Notes(80, 7, 1), TB.EndOfTrack(30)]))]));

  Add('ties_between_tracks', Song(1, 96, [
    TB.Track(TB.Join([TB.Tempo(0, 500000), TB.NoteOn(0, 0, 60, 90), TB.NoteOn(0, 0, 61, 90),
      TB.NoteOff(48, 0, 60, 0), TB.NoteOff(0, 0, 61, 0), TB.EndOfTrack(0)])),
    TB.Track(TB.Join([TB.NoteOn(0, 1, 40, 90), TB.NoteOn(0, 1, 41, 90),
      TB.NoteOff(48, 1, 40, 0), TB.NoteOff(0, 1, 41, 0), TB.EndOfTrack(0)])),
    TB.Track(TB.Join([TB.NoteOn(48, 2, 30, 90), TB.EndOfTrack(48)]))]));

  Add('type2_tracks', Song(2, 96, [
    TB.Track(TB.Join([TB.Tempo(0, 500000), Notes(30, 10, 0), TB.EndOfTrack(0)])),
    TB.Track(TB.Join([Notes(30, 10, 1), TB.EndOfTrack(0)]))]));

  Add('empty_track', Song(1, 96, [TB.Track(TB.Bytes([])),
    TB.Track(TB.Join([TB.Tempo(0, 500000), Notes(50, 10, 0), TB.EndOfTrack(0)]))]));

  Add('volume_controller', Song(0, 96, [TB.Track(TB.Join([TB.Tempo(0, 500000),
    TB.Controller(0, 0, 7, 100), TB.Controller(0, 5, 7, 64), TB.Controller(0, 5, 10, 64),
    Notes(40, 10, 0), TB.Controller(10, 0, 7, 20), TB.Controller(10, 15, 7, 127),
    TB.EndOfTrack(0)]))]));

  Add('all_channel_events', Song(0, 96, [TB.Track(TB.Join([TB.Tempo(0, 500000),
    TB.NoteOff(0, 1, 60, 10), TB.NoteOn(0, 2, 61, 11), TB.NoteAftertouch(0, 3, 62, 12),
    TB.Controller(0, 4, 1, 13), TB.ProgramChange(0, 5, 14), TB.ChannelAftertouch(0, 6, 15),
    TB.PitchBend(0, 7, 16, 17), TB.EndOfTrack(100)]))]));

  Add('smpte_division', Song(0, $E728, [TB.Track(TB.Join([TB.Tempo(0, 500000), Notes(150, 4, 0),
    TB.EndOfTrack(0)]))]));

  Add('short_loop', Song(0, 96, [TB.Track(TB.Join([TB.Tempo(0, 500000), TB.NoteOn(0, 0, 60, 90),
    TB.NoteOff(24, 0, 60, 0), TB.EndOfTrack(24)]))]));

  Add('large_deltas', Song(0, 480, [TB.Track(TB.Join([TB.Tempo(0, 500000),
    TB.NoteOn(0, 0, 60, 90), TB.NoteOff(100000, 0, 60, 0), TB.NoteOn(300, 0, 62, 90),
    TB.NoteOff(70000, 0, 62, 0), TB.EndOfTrack(0)]))]));

  // the length of the track says more than the events: what follows the end of track is skipped
  LTrack := TB.Join([TB.Tempo(0, 500000), Notes(20, 10, 0), TB.EndOfTrack(0)]);
  Add('length_beyond_events', TB.Join([TB.Header(1, 2, 96), TB.Track(LTrack, Length(LTrack) + 4),
    TB.Bytes([1, 2, 3, 4]), TB.Track(TB.Join([Notes(20, 7, 1), TB.EndOfTrack(0)]))]));

  // files that are not readable: the old player stopped the game
  Add('bad_header', TB.Join([TB.Bytes([Ord('M'), Ord('T'), Ord('h'), Ord('x'), 0, 0, 0, 6, 0, 0, 0, 1, 0, 96]),
    TB.Track(TB.EndOfTrack(0))]));
  LCut := TB.Join([TB.Tempo(0, 500000), TB.NoteOn(0, 0, 60, 90), TB.NoteOff(10, 0, 60, 0)]);
  Add('no_end_of_track', Song(0, 96, [TB.Track(LCut)]));

  Result := LList;
end;

class function TMidiScenarios.WadSongs(const APath: string; AMus: Boolean): TArray<TMidiScenarioFile>;
var
  LFile: TBytes;
  LCount, LTable, LIndex, LPosition, LSize: Integer;
  LName: AnsiString;
  LCharIndex: Integer;
  LStream: TFileStream;
  LIsSong: Boolean;
  LBytes: TBytes;
begin
  Result := nil;
  if not FileExists(APath) then
    Exit;
  LStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    SetLength(LFile, LStream.Size);
    if Length(LFile) > 0 then
      LStream.ReadBuffer(LFile[0], Length(LFile));
  finally
    LStream.Free;
  end;
  if (Length(LFile) < 12) or not (((LFile[0] = Ord('I')) or (LFile[0] = Ord('P'))) and
    (LFile[1] = Ord('W')) and (LFile[2] = Ord('A')) and (LFile[3] = Ord('D'))) then
    Exit;
  Move(LFile[4], LCount, 4);
  Move(LFile[8], LTable, 4);
  for LIndex := 0 to LCount - 1 do
  begin
    if (LTable < 0) or (LTable + (LIndex + 1) * 16 > Length(LFile)) then
      Break;
    Move(LFile[LTable + LIndex * 16], LPosition, 4);
    Move(LFile[LTable + LIndex * 16 + 4], LSize, 4);
    if (LPosition < 0) or (LSize < 4) or (LPosition + LSize > Length(LFile)) then
      Continue;
    if AMus then
      LIsSong := (LFile[LPosition] = Ord('M')) and (LFile[LPosition + 1] = Ord('U')) and
        (LFile[LPosition + 2] = Ord('S')) and (LFile[LPosition + 3] = $1A)
    else
      LIsSong := (LFile[LPosition] = Ord('M')) and (LFile[LPosition + 1] = Ord('T')) and
        (LFile[LPosition + 2] = Ord('h')) and (LFile[LPosition + 3] = Ord('d'));
    if not LIsSong then
      Continue;
    LName := '';
    for LCharIndex := 0 to 7 do
      if LFile[LTable + LIndex * 16 + 8 + LCharIndex] <> 0 then
        LName := LName + AnsiChar(LFile[LTable + LIndex * 16 + 8 + LCharIndex]);
    SetLength(LBytes, LSize);
    Move(LFile[LPosition], LBytes[0], LSize);
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Scenario('wad:' + ChangeFileExt(ExtractFileName(APath), '') + ':' +
      string(LName) + '#' + IntToStr(LIndex), LBytes);
  end;
end;

end.
