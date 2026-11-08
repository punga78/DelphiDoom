{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the merger of the tracks of a type 1 MIDI file         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.M2m.TrackMerger;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.M2m.MidiFile;

type
  [TestFixture]
  [Category('m2m')]
  TTestMidiTrackMerger = class(TObject)
  private
    FSource: TMidiFile;
    FMerged: TMidiFile;
    procedure Merge(const AData: TBytes);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestPortaTuttoInUnaTraccia;
    [Test]
    procedure TestMetteGliEventiInOrdineDiTempo;
    [Test]
    procedure TestLaFineDelleTraccePiuCorteSiScarta;
    [Test]
    procedure TestDueEventiNelloStessoTempoRestanoNellOrdineDelleTracce;
    [Test]
    procedure TestRifiutaUnFileDiTipo0;
    [Test]
    procedure TestRifiutaUnFileDiTipo2;
    [Test]
    procedure TestConLaOpzioneRiportaIlTempoDellaFineScartata;
    [Test]
    procedure TestSenzaOpzioneIlTempoDellaFineScartataSiPerde;
    [Test]
    procedure TestNonCambiaIlFileDiPartenza;
  end;

implementation

uses
  DelphiDoom.M2m.Intf,
  DelphiDoom.M2m.MidiReader,
  DelphiDoom.M2m.TrackMerger,
  DelphiDoom.M2m.Types,
  DelphiDoom.Tests.M2m.MidiBuilder;

type
  B = TTestMidiBuilder;

{ TTestMidiTrackMerger }

procedure TTestMidiTrackMerger.TearDown;
begin
  FreeAndNil(FMerged);
  FreeAndNil(FSource);
end;

procedure TTestMidiTrackMerger.Merge(const AData: TBytes);
begin
  FreeAndNil(FMerged);
  FreeAndNil(FSource);
  FSource := TMidiReader.Parse(@AData[0], Length(AData));
  FMerged := TMidiTrackMerger.Merge(FSource);
end;

procedure TTestMidiTrackMerger.TestPortaTuttoInUnaTraccia;
begin
  Merge(B.Join([B.Header(1, 2, $E728), B.Track(B.EndOfTrack(0)), B.Track(B.EndOfTrack(0))]));

  Assert.AreEqual(0, FMerged.Mode);
  Assert.AreEqual(25, FMerged.SmpteFps);
  Assert.AreEqual(40, FMerged.Timing);
  Assert.AreEqual(1, Length(FMerged.Tracks));
end;

procedure TTestMidiTrackMerger.TestMetteGliEventiInOrdineDiTempo;
var
  LEvents: TArray<TMidiEvent>;
begin
  // The first track has notes at 0 and 10, the second one at 5 and 12
  Merge(B.Join([B.Header(1, 2, 96),
    B.Track(B.Join([B.NoteOn(0, 0, 60, 1), B.NoteOn(10, 0, 62, 1), B.EndOfTrack(0)])),
    B.Track(B.Join([B.NoteOn(5, 1, 70, 1), B.NoteOn(7, 1, 72, 1), B.EndOfTrack(0)]))]));

  LEvents := FMerged.Tracks[0].Events;
  Assert.AreEqual(5, Length(LEvents));
  Assert.AreEqual(60, LEvents[0].Param1);
  Assert.AreEqual(0, Integer(LEvents[0].Delta));
  Assert.AreEqual(70, LEvents[1].Param1);
  Assert.AreEqual(5, Integer(LEvents[1].Delta));
  Assert.AreEqual(62, LEvents[2].Param1);
  Assert.AreEqual(5, Integer(LEvents[2].Delta));
  Assert.AreEqual(72, LEvents[3].Param1);
  Assert.AreEqual(2, Integer(LEvents[3].Delta));
end;

procedure TTestMidiTrackMerger.TestLaFineDelleTraccePiuCorteSiScarta;
var
  LEvents: TArray<TMidiEvent>;
  LEnds: Integer;
  LEvent: TMidiEvent;
begin
  // The first track ends at 20, the second one at 25
  Merge(B.Join([B.Header(1, 2, 96),
    B.Track(B.Join([B.NoteOn(0, 0, 60, 1), B.NoteOn(10, 0, 62, 1), B.EndOfTrack(10)])),
    B.Track(B.Join([B.NoteOn(5, 1, 70, 1), B.EndOfTrack(20)]))]));

  LEvents := FMerged.Tracks[0].Events;
  LEnds := 0;
  for LEvent in LEvents do
  begin
    if (LEvent.EventType = metMeta) and (LEvent.Param1 = META_ENDTRACK) then
      Inc(LEnds);
  end;
  Assert.AreEqual(1, LEnds);
  Assert.IsTrue(LEvents[High(LEvents)].EventType = metMeta);
  // The time of the end of track events that are dropped is lost, as it was in the C code:
  // the last one comes 5 clocks after the note at 10
  Assert.AreEqual(5, Integer(LEvents[High(LEvents)].Delta));
end;

procedure TTestMidiTrackMerger.TestDueEventiNelloStessoTempoRestanoNellOrdineDelleTracce;
var
  LEvents: TArray<TMidiEvent>;
begin
  Merge(B.Join([B.Header(1, 2, 96),
    B.Track(B.Join([B.NoteOn(4, 0, 60, 1), B.EndOfTrack(0)])),
    B.Track(B.Join([B.NoteOn(4, 1, 70, 1), B.EndOfTrack(0)]))]));

  LEvents := FMerged.Tracks[0].Events;
  Assert.AreEqual(60, LEvents[0].Param1);
  Assert.AreEqual(4, Integer(LEvents[0].Delta));
  Assert.AreEqual(70, LEvents[1].Param1);
  Assert.AreEqual(0, Integer(LEvents[1].Delta));
end;

procedure TTestMidiTrackMerger.TestRifiutaUnFileDiTipo0;
var
  LData: TBytes;
begin
  LData := B.Join([B.Header(0, 1, 96), B.Track(B.EndOfTrack(0))]);
  FSource := TMidiReader.Parse(@LData[0], Length(LData));

  Assert.WillRaise(
    procedure
    begin
      TMidiTrackMerger.Merge(FSource);
    end, EM2mException);
end;

procedure TTestMidiTrackMerger.TestRifiutaUnFileDiTipo2;
var
  LData: TBytes;
begin
  LData := B.Join([B.Header(2, 1, 96), B.Track(B.EndOfTrack(0))]);
  FSource := TMidiReader.Parse(@LData[0], Length(LData));

  Assert.WillRaise(
    procedure
    begin
      TMidiTrackMerger.Merge(FSource);
    end, EM2mException);
end;

procedure TTestMidiTrackMerger.TestConLaOpzioneRiportaIlTempoDellaFineScartata;
var
  LEvents: TArray<TMidiEvent>;
  LData: TBytes;
begin
  // The first track ends at 1, the second one has notes at 0 and at 119 (regression: the
  // time of the dropped end of track was lost and the second note came at 118)
  LData := B.Join([B.Header(1, 2, 96),
    B.Track(B.Join([B.NoteOn(0, 0, 60, 1), B.EndOfTrack(1)])),
    B.Track(B.Join([B.NoteOn(0, 1, 70, 1), B.NoteOn(119, 1, 72, 1), B.EndOfTrack(0)]))]);
  FSource := TMidiReader.Parse(@LData[0], Length(LData));
  FMerged := TMidiTrackMerger.Merge(FSource, True);

  LEvents := FMerged.Tracks[0].Events;
  Assert.AreEqual(72, LEvents[2].Param1);
  Assert.AreEqual(119, Integer(LEvents[2].Delta));
end;

procedure TTestMidiTrackMerger.TestSenzaOpzioneIlTempoDellaFineScartataSiPerde;
var
  LEvents: TArray<TMidiEvent>;
  LData: TBytes;
begin
  LData := B.Join([B.Header(1, 2, 96),
    B.Track(B.Join([B.NoteOn(0, 0, 60, 1), B.EndOfTrack(1)])),
    B.Track(B.Join([B.NoteOn(0, 1, 70, 1), B.NoteOn(119, 1, 72, 1), B.EndOfTrack(0)]))]);
  FSource := TMidiReader.Parse(@LData[0], Length(LData));
  FMerged := TMidiTrackMerger.Merge(FSource);

  LEvents := FMerged.Tracks[0].Events;
  Assert.AreEqual(72, LEvents[2].Param1);
  Assert.AreEqual(118, Integer(LEvents[2].Delta));
end;

procedure TTestMidiTrackMerger.TestNonCambiaIlFileDiPartenza;
begin
  Merge(B.Join([B.Header(1, 2, 96), B.Track(B.Join([B.NoteOn(0, 0, 60, 1), B.EndOfTrack(0)])),
    B.Track(B.EndOfTrack(0))]));

  Assert.AreEqual(1, FSource.Mode);
  Assert.AreEqual(2, Length(FSource.Tracks));
  Assert.AreEqual(2, Length(FSource.Tracks[0].Events));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMidiTrackMerger);

end.
