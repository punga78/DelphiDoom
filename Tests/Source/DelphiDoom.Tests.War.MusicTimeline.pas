{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the timeline of the music of Libs\War                  }
{                                                                              }
{  It runs on the real sequencer of Libs\Midi and on small files built in      }
{  memory. With a division of 100 and the tempo of 500000 a tick is 5 ms.      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MusicTimeline;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Music.Types, DelphiDoom.War.Music.Intf;

type
  [TestFixture]
  [Category('war')]
  TTestWarMusicTimeline = class
  strict private
    FTimeline: IWarMusicTimeline;
    function Song(const ATrack: TBytes; ADivision: Integer = 100): TBytes;
    function Load(const AMidi: TBytes): Boolean;
    function Next: TWarMusicEvent;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeRifiutareUnSequencerNullo;
    [Test]
    procedure DovrebbeDareITempiInMillisecondiTroncatiAlTempoDiDefault;
    [Test]
    procedure DovrebbeTroncareIMillisecondiDiOgniEvento;
    [Test]
    procedure DovrebbeCambiareIlPassoDopoUnCambioDiTempo;
    [Test]
    procedure DovrebbeDareIlTempoDelCambioConIlPassoDiPrima;
    [Test]
    procedure DovrebbeDareGliEventiDiTuttiITipiCheLOriginaleSuona;
    [Test]
    procedure DovrebbeDareCometipoIgnoratoGliEventiDiPressioneEDiTempo;
    [Test]
    procedure DovrebbeDareITastiEVelocitaMassimi;
    [Test]
    procedure DovrebbeFondereLeTracceInOrdineDiTempo;
    [Test]
    procedure DovrebbeFondereLeTracceAncheSeIlPrimoEventoEDellaSeconda;
    [Test]
    procedure DovrebbeFinireAllaFineDellaCanzone;
    [Test]
    procedure DovrebbeRicominciareDaZeroConRewind;
    [Test]
    procedure DovrebbeDareFalsoPerUnFileChePerdeLaTestata;
    [Test]
    procedure DovrebbeDareFalsoPerUnFileVuoto;
    [Test]
    procedure DovrebbeDareFalsoPerUnTempoSmpte;
    [Test]
    procedure DovrebbeNonDareEventiSenzaCanzone;
    [Test]
    procedure DovrebbeLeggereUnaCanzoneLungaOltreUnBloccoDelSequencer;
    [Test]
    procedure DovrebbeSostituireLaCanzoneConUnaNuova;
  end;

implementation

uses
  DelphiDoom.Midi.Intf, DelphiDoom.Midi.Factory, DelphiDoom.War.Types, DelphiDoom.War.Music.Factory, DelphiDoom.Tests.M2m.MidiBuilder;

{ TTestWarMusicTimeline }

procedure TTestWarMusicTimeline.Setup;
begin
  FTimeline := TWarMusicFactory.CreateTimeline(TMidiFactory.CreateSequencer(nil));
end;

function TTestWarMusicTimeline.Song(const ATrack: TBytes; ADivision: Integer): TBytes;
begin
  Result := TTestMidiBuilder.Join([TTestMidiBuilder.Header(0, 1, ADivision),
    TTestMidiBuilder.Track(TTestMidiBuilder.Join([ATrack, TTestMidiBuilder.EndOfTrack(0)]))]);
end;

function TTestWarMusicTimeline.Load(const AMidi: TBytes): Boolean;
begin
  Result := FTimeline.Load(AMidi);
end;

function TTestWarMusicTimeline.Next: TWarMusicEvent;
begin
  Assert.IsTrue(FTimeline.TryNext(Result), 'An event was expected');
end;

procedure TTestWarMusicTimeline.DovrebbeRifiutareUnSequencerNullo;
var
  LSequencer: IMidiStreamSequencer;
begin
  LSequencer := nil;
  Assert.WillRaise(
    procedure
    begin
      TWarMusicFactory.CreateTimeline(LSequencer);
    end, EWarException);
end;

procedure TTestWarMusicTimeline.DovrebbeDareITempiInMillisecondiTroncatiAlTempoDiDefault;
var
  LEvent: TWarMusicEvent;
begin
  Assert.IsTrue(Load(Song(TTestMidiBuilder.Join([TTestMidiBuilder.NoteOn(100, 1, 60, 100),
    TTestMidiBuilder.NoteOff(100, 1, 60, 0)]))));
  LEvent := Next;
  Assert.AreEqual<Cardinal>(500, LEvent.TimeMs);
  Assert.AreEqual<Integer>(Ord(wmkNoteOn), Ord(LEvent.Kind));
  Assert.AreEqual<Integer>(1, LEvent.Channel);
  Assert.AreEqual<Integer>(60, LEvent.Key);
  Assert.AreEqual<Integer>(100, LEvent.Value);
  LEvent := Next;
  Assert.AreEqual<Cardinal>(1000, LEvent.TimeMs);
  Assert.AreEqual<Integer>(Ord(wmkNoteOff), Ord(LEvent.Kind));
end;

procedure TTestWarMusicTimeline.DovrebbeTroncareIMillisecondiDiOgniEvento;
begin
  // 1 tick = 5.2083 ms: ticks 1, 3 and 7 are at 5, 15 and 36 ms (the original truncates, it does not round)
  Assert.IsTrue(Load(Song(TTestMidiBuilder.Join([TTestMidiBuilder.NoteOn(1, 0, 60, 1),
    TTestMidiBuilder.NoteOn(2, 0, 61, 1), TTestMidiBuilder.NoteOn(4, 0, 62, 1)]), 96)));
  Assert.AreEqual<Cardinal>(5, Next.TimeMs);
  Assert.AreEqual<Cardinal>(15, Next.TimeMs);
  Assert.AreEqual<Cardinal>(36, Next.TimeMs);
end;

procedure TTestWarMusicTimeline.DovrebbeCambiareIlPassoDopoUnCambioDiTempo;
begin
  // at tick 100 (500 ms) the tempo doubles in length: 100 ticks more are 1000 ms
  Assert.IsTrue(Load(Song(TTestMidiBuilder.Join([TTestMidiBuilder.NoteOn(100, 0, 60, 1),
    TTestMidiBuilder.Tempo(0, 1000000), TTestMidiBuilder.NoteOn(100, 0, 61, 1)]))));
  Assert.AreEqual<Cardinal>(500, Next.TimeMs);
  Assert.AreEqual<Integer>(Ord(wmkIgnored), Ord(Next.Kind));
  Assert.AreEqual<Cardinal>(1500, Next.TimeMs);
end;

procedure TTestWarMusicTimeline.DovrebbeDareIlTempoDelCambioConIlPassoDiPrima;
var
  LEvent: TWarMusicEvent;
begin
  Assert.IsTrue(Load(Song(TTestMidiBuilder.Join([TTestMidiBuilder.Tempo(100, 1000000),
    TTestMidiBuilder.NoteOn(0, 0, 60, 1)]))));
  LEvent := Next;
  Assert.AreEqual<Integer>(Ord(wmkIgnored), Ord(LEvent.Kind));
  Assert.AreEqual<Cardinal>(500, LEvent.TimeMs);
  Assert.AreEqual<Cardinal>(500, Next.TimeMs);
end;

procedure TTestWarMusicTimeline.DovrebbeDareGliEventiDiTuttiITipiCheLOriginaleSuona;
var
  LEvent: TWarMusicEvent;
begin
  Assert.IsTrue(Load(Song(TTestMidiBuilder.Join([TTestMidiBuilder.ProgramChange(0, 9, 12),
    TTestMidiBuilder.Controller(0, 2, 7, 90), TTestMidiBuilder.PitchBend(0, 3, $05, $40),
    TTestMidiBuilder.NoteOn(0, 4, 70, 80), TTestMidiBuilder.NoteOff(0, 4, 70, 0)]))));
  LEvent := Next;
  Assert.AreEqual<Integer>(Ord(wmkProgramChange), Ord(LEvent.Kind));
  Assert.AreEqual<Integer>(9, LEvent.Channel);
  Assert.AreEqual<Integer>(12, LEvent.Key);
  LEvent := Next;
  Assert.AreEqual<Integer>(Ord(wmkControlChange), Ord(LEvent.Kind));
  Assert.AreEqual<Integer>(7, LEvent.Key);
  Assert.AreEqual<Integer>(90, LEvent.Value);
  LEvent := Next;
  Assert.AreEqual<Integer>(Ord(wmkPitchBend), Ord(LEvent.Kind));
  Assert.AreEqual<Integer>(3, LEvent.Channel);
  // ((high & 0x7f) << 7) | low
  Assert.AreEqual<Integer>((($40) shl 7) or $05, LEvent.Value);
  Assert.AreEqual<Integer>(Ord(wmkNoteOn), Ord(Next.Kind));
  Assert.AreEqual<Integer>(Ord(wmkNoteOff), Ord(Next.Kind));
end;

procedure TTestWarMusicTimeline.DovrebbeDareCometipoIgnoratoGliEventiDiPressioneEDiTempo;
begin
  Assert.IsTrue(Load(Song(TTestMidiBuilder.Join([TTestMidiBuilder.NoteAftertouch(10, 0, 60, 5),
    TTestMidiBuilder.ChannelAftertouch(10, 0, 5), TTestMidiBuilder.NoteOn(10, 0, 60, 5)]))));
  Assert.AreEqual<Integer>(Ord(wmkIgnored), Ord(Next.Kind));
  Assert.AreEqual<Integer>(Ord(wmkIgnored), Ord(Next.Kind));
  Assert.AreEqual<Integer>(Ord(wmkNoteOn), Ord(Next.Kind));
end;

procedure TTestWarMusicTimeline.DovrebbeDareITastiEVelocitaMassimi;
var
  LEvent: TWarMusicEvent;
begin
  Assert.IsTrue(Load(Song(TTestMidiBuilder.Bytes([0, $90, $7F, $7F]))));
  LEvent := Next;
  Assert.AreEqual<Integer>(127, LEvent.Key);
  Assert.AreEqual<Integer>(127, LEvent.Value);
end;

procedure TTestWarMusicTimeline.DovrebbeFondereLeTracceInOrdineDiTempo;
var
  LSong: TBytes;
begin
  LSong := TTestMidiBuilder.Join([TTestMidiBuilder.Header(1, 2, 96),
    TTestMidiBuilder.Track(TTestMidiBuilder.Join([TTestMidiBuilder.NoteOn(10, 0, 60, 1), TTestMidiBuilder.NoteOn(40, 0, 62, 1),
      TTestMidiBuilder.EndOfTrack(0)])),
    TTestMidiBuilder.Track(TTestMidiBuilder.Join([TTestMidiBuilder.NoteOn(20, 1, 61, 1), TTestMidiBuilder.NoteOn(5, 1, 63, 1),
      TTestMidiBuilder.EndOfTrack(0)]))]);
  Assert.IsTrue(Load(LSong));
  Assert.AreEqual<Integer>(60, Next.Key);
  Assert.AreEqual<Integer>(61, Next.Key);
  Assert.AreEqual<Integer>(63, Next.Key);
  Assert.AreEqual<Integer>(62, Next.Key);
end;

procedure TTestWarMusicTimeline.DovrebbeFondereLeTracceAncheSeIlPrimoEventoEDellaSeconda;
var
  LSong: TBytes;
begin
  // tml_load swaps its first message with the first one of the track 0 and loses events when the first
  // event of the song is not of the track 0 (a defect of tml, not kept): here all four come out, in time order
  LSong := TTestMidiBuilder.Join([TTestMidiBuilder.Header(1, 2, 100),
    TTestMidiBuilder.Track(TTestMidiBuilder.Join([TTestMidiBuilder.NoteOn(30, 0, 60, 1),
      TTestMidiBuilder.NoteOn(30, 0, 62, 1), TTestMidiBuilder.EndOfTrack(0)])),
    TTestMidiBuilder.Track(TTestMidiBuilder.Join([TTestMidiBuilder.NoteOn(10, 1, 61, 1),
      TTestMidiBuilder.NoteOn(40, 1, 63, 1), TTestMidiBuilder.EndOfTrack(0)]))]);
  Assert.IsTrue(Load(LSong));
  Assert.AreEqual<Integer>(61, Next.Key);
  Assert.AreEqual<Integer>(60, Next.Key);
  Assert.AreEqual<Integer>(63, Next.Key);
  Assert.AreEqual<Integer>(62, Next.Key);
end;

procedure TTestWarMusicTimeline.DovrebbeFinireAllaFineDellaCanzone;
var
  LEvent: TWarMusicEvent;
begin
  Assert.IsTrue(Load(Song(TTestMidiBuilder.NoteOn(1, 0, 60, 1))));
  Next;
  Assert.IsFalse(FTimeline.TryNext(LEvent));
  Assert.IsFalse(FTimeline.TryNext(LEvent));
end;

procedure TTestWarMusicTimeline.DovrebbeRicominciareDaZeroConRewind;
begin
  Assert.IsTrue(Load(Song(TTestMidiBuilder.Join([TTestMidiBuilder.Tempo(0, 1000000),
    TTestMidiBuilder.NoteOn(100, 0, 60, 1)]))));
  Next;
  Assert.AreEqual<Cardinal>(1000, Next.TimeMs);
  FTimeline.Rewind;
  Next;
  // the tempo of the song is read again: the same times
  Assert.AreEqual<Cardinal>(1000, Next.TimeMs);
end;

procedure TTestWarMusicTimeline.DovrebbeDareFalsoPerUnFileChePerdeLaTestata;
begin
  Assert.IsFalse(Load(TTestMidiBuilder.Bytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])));
  Assert.IsFalse(Load(TTestMidiBuilder.Bytes([Ord('M'), Ord('T')])));
end;

procedure TTestWarMusicTimeline.DovrebbeDareFalsoPerUnFileVuoto;
begin
  Assert.IsFalse(Load(nil));
end;

procedure TTestWarMusicTimeline.DovrebbeDareFalsoPerUnTempoSmpte;
begin
  // the division has its top bit set: frames per second, not ticks per beat
  Assert.IsFalse(Load(Song(TTestMidiBuilder.NoteOn(1, 0, 60, 1), $E728)));
end;

procedure TTestWarMusicTimeline.DovrebbeNonDareEventiSenzaCanzone;
var
  LEvent: TWarMusicEvent;
begin
  Assert.IsFalse(FTimeline.TryNext(LEvent));
  FTimeline.Rewind;
  Assert.IsFalse(FTimeline.TryNext(LEvent));
end;

procedure TTestWarMusicTimeline.DovrebbeLeggereUnaCanzoneLungaOltreUnBloccoDelSequencer;
var
  LTrack: TBytes;
  LIndex, LCount: Integer;
  LEvent: TWarMusicEvent;
  LPrevious: Cardinal;
begin
  // 600 notes: more than the 256 events that the timeline asks for at a time
  LTrack := nil;
  for LIndex := 1 to 600 do
    LTrack := TTestMidiBuilder.Join([LTrack, TTestMidiBuilder.NoteOn(3, 0, LIndex mod 100, 50)]);
  Assert.IsTrue(Load(Song(LTrack)));
  LCount := 0;
  LPrevious := 0;
  while FTimeline.TryNext(LEvent) do
  begin
    Inc(LCount);
    Assert.IsTrue(LEvent.TimeMs >= LPrevious);
    LPrevious := LEvent.TimeMs;
  end;
  Assert.AreEqual<Integer>(600, LCount);
  // 1800 ticks of 5 ms
  Assert.AreEqual<Cardinal>(9000, LPrevious);
end;

procedure TTestWarMusicTimeline.DovrebbeSostituireLaCanzoneConUnaNuova;
begin
  Assert.IsTrue(Load(Song(TTestMidiBuilder.NoteOn(1, 0, 60, 1))));
  Next;
  Assert.IsTrue(Load(Song(TTestMidiBuilder.NoteOn(100, 0, 61, 1))));
  Assert.AreEqual<Integer>(61, Next.Key);
end;

end.
