{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the reader of Standard MIDI files                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.M2m.MidiReader;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.M2m.MidiFile;

type
  [TestFixture]
  [Category('m2m')]
  TTestMidiReader = class(TObject)
  private
    FMidi: TMidiFile;
    procedure Parse(const AData: TBytes);
    function ParseFails(const AData: TBytes): Boolean;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLeggeUnaTracciaSola;
    [Test]
    procedure TestLeggeIlTempoSmpte;
    [Test]
    procedure TestLeggeLeTracceDiUnFileDiTipo1;
    [Test]
    procedure TestLeggeIParametriDegliEventi;
    [Test]
    procedure TestStatoCorrenteRipeteLUltimoEvento;
    [Test]
    procedure TestLeggeLeDimensioniVariabili;
    [Test]
    procedure TestLeggeIDatiDegliEventiMetaESysex;
    [Test]
    procedure TestSenzaIntestazione;
    [Test]
    procedure TestIntestazioneDiLunghezzaSbagliata;
    [Test]
    procedure TestTipoSconosciuto;
    [Test]
    procedure TestSenzaTracce;
    [Test]
    procedure TestTracciaSenzaIntestazione;
    [Test]
    procedure TestTracciaTroncata;
    [Test]
    procedure TestTracciaSenzaFineTraccia;
    [Test]
    procedure TestEventoSconosciuto;
    [Test]
    procedure TestStatoCorrenteSenzaEventoPrecedente;
    [Test]
    procedure TestLunghezzaVariabileTroppoLunga;
    [Test]
    procedure TestDatiMetaPiuLunghiDelFile;
    [Test]
    procedure TestFineTracciaConDatiInPiuFaCercareLaProssimaTracciaSubito;
  end;

implementation

uses
  DelphiDoom.M2m.Intf,
  DelphiDoom.M2m.MidiReader,
  DelphiDoom.M2m.Types,
  DelphiDoom.Tests.M2m.MidiBuilder;

type
  B = TTestMidiBuilder;

{ TTestMidiReader }

procedure TTestMidiReader.TearDown;
begin
  FreeAndNil(FMidi);
end;

procedure TTestMidiReader.Parse(const AData: TBytes);
begin
  FreeAndNil(FMidi);
  FMidi := TMidiReader.Parse(@AData[0], Length(AData));
end;

function TTestMidiReader.ParseFails(const AData: TBytes): Boolean;
begin
  FreeAndNil(FMidi);
  try
    FMidi := TMidiReader.Parse(@AData[0], Length(AData));
    Result := False;
  except
    on E: EM2mException do
      Result := E.Code = M2M_ERROR_MIDI;
  end;
end;

procedure TTestMidiReader.TestLeggeUnaTracciaSola;
begin
  Parse(B.Join([B.Header(0, 1, 96), B.Track(B.Join([B.NoteOn(0, 2, 60, 100), B.EndOfTrack(48)]))]));

  Assert.AreEqual(0, FMidi.Mode);
  Assert.AreEqual(0, FMidi.SmpteFps);
  Assert.AreEqual(96, FMidi.Timing);
  Assert.AreEqual(1, Length(FMidi.Tracks));
  Assert.AreEqual(2, Length(FMidi.Tracks[0].Events));
  Assert.IsTrue(FMidi.Tracks[0].Events[0].EventType = metNoteOn);
  Assert.AreEqual(2, FMidi.Tracks[0].Events[0].Channel);
  Assert.AreEqual(60, FMidi.Tracks[0].Events[0].Param1);
  Assert.AreEqual(100, FMidi.Tracks[0].Events[0].Param2);
  Assert.AreEqual(48, Integer(FMidi.Tracks[0].Events[1].Delta));
end;

procedure TTestMidiReader.TestLeggeIlTempoSmpte;
begin
  // -25 frames per second (E7) and 40 clocks per frame
  Parse(B.Join([B.Header(0, 1, $E728), B.Track(B.EndOfTrack(0))]));

  Assert.AreEqual(25, FMidi.SmpteFps);
  Assert.AreEqual(40, FMidi.Timing);
end;

procedure TTestMidiReader.TestLeggeLeTracceDiUnFileDiTipo1;
begin
  Parse(B.Join([B.Header(1, 2, 120), B.Track(B.EndOfTrack(0)), B.Track(B.Join([B.NoteOn(5, 0, 1, 2),
    B.EndOfTrack(0)]))]));

  Assert.AreEqual(1, FMidi.Mode);
  Assert.AreEqual(2, Length(FMidi.Tracks));
  Assert.AreEqual(1, Length(FMidi.Tracks[0].Events));
  Assert.AreEqual(2, Length(FMidi.Tracks[1].Events));
end;

procedure TTestMidiReader.TestLeggeIParametriDegliEventi;
var
  LEvents: TArray<TMidiEvent>;
begin
  Parse(B.Join([B.Header(0, 1, 96), B.Track(B.Join([
    B.NoteOff(0, 1, 60, 64),
    B.NoteAftertouch(0, 1, 61, 62),
    B.Controller(0, 3, 7, 99),
    B.ProgramChange(0, 4, 12),
    B.ChannelAftertouch(0, 5, 33),
    B.PitchBend(0, 6, 1, 2),
    B.EndOfTrack(0)]))]));

  LEvents := FMidi.Tracks[0].Events;
  Assert.IsTrue(LEvents[0].EventType = metNoteOff);
  Assert.AreEqual(64, LEvents[0].Param2);
  Assert.IsTrue(LEvents[1].EventType = metNoteAftertouch);
  Assert.AreEqual(62, LEvents[1].Param2);
  Assert.IsTrue(LEvents[2].EventType = metController);
  Assert.AreEqual(3, LEvents[2].Channel);
  Assert.AreEqual(7, LEvents[2].Param1);
  Assert.AreEqual(99, LEvents[2].Param2);
  Assert.IsTrue(LEvents[3].EventType = metProgramChange);
  Assert.AreEqual(12, LEvents[3].Param1);
  Assert.IsTrue(LEvents[4].EventType = metChannelAftertouch);
  Assert.AreEqual(33, LEvents[4].Param1);
  Assert.IsTrue(LEvents[5].EventType = metPitchBend);
  Assert.AreEqual(1, LEvents[5].Param1);
  Assert.AreEqual(2, LEvents[5].Param2);
end;

procedure TTestMidiReader.TestStatoCorrenteRipeteLUltimoEvento;
var
  LEvents: TArray<TMidiEvent>;
begin
  // The second and third notes have no status byte
  Parse(B.Join([B.Header(0, 1, 96), B.Track(B.Join([B.NoteOn(0, 7, 60, 100), B.Running(3, [62, 90]),
    B.Running(4, [64, 80]), B.EndOfTrack(0)]))]));

  LEvents := FMidi.Tracks[0].Events;
  Assert.AreEqual(4, Length(LEvents));
  Assert.IsTrue(LEvents[2].EventType = metNoteOn);
  Assert.AreEqual(7, LEvents[2].Channel);
  Assert.AreEqual(64, LEvents[2].Param1);
  Assert.AreEqual(4, Integer(LEvents[2].Delta));
end;

procedure TTestMidiReader.TestLeggeLeDimensioniVariabili;
begin
  Parse(B.Join([B.Header(0, 1, 96), B.Track(B.Join([B.NoteOn(300, 0, 60, 1), B.NoteOn(20000, 0, 61, 1),
    B.EndOfTrack(0)]))]));

  Assert.AreEqual(300, Integer(FMidi.Tracks[0].Events[0].Delta));
  Assert.AreEqual(20000, Integer(FMidi.Tracks[0].Events[1].Delta));
end;

procedure TTestMidiReader.TestLeggeIDatiDegliEventiMetaESysex;
var
  LEvents: TArray<TMidiEvent>;
begin
  Parse(B.Join([B.Header(0, 1, 96), B.Track(B.Join([B.Tempo(0, 500000), B.SysEx(0, [1, 2, 3]),
    B.Meta(0, $06, []), B.EndOfTrack(0)]))]));

  LEvents := FMidi.Tracks[0].Events;
  Assert.IsTrue(LEvents[0].EventType = metMeta);
  Assert.AreEqual($51, LEvents[0].Param1);
  Assert.AreEqual(3, Length(LEvents[0].Data));
  Assert.AreEqual(Integer($07), Integer(LEvents[0].Data[0]));
  Assert.IsTrue(LEvents[1].EventType = metSysEx);
  Assert.AreEqual(3, Length(LEvents[1].Data));
  Assert.AreEqual(0, Length(LEvents[2].Data));
end;

procedure TTestMidiReader.TestSenzaIntestazione;
begin
  Assert.IsTrue(ParseFails(B.Bytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14])));
  Assert.IsTrue(ParseFails(B.Bytes([Ord('M'), Ord('T')])));
end;

procedure TTestMidiReader.TestIntestazioneDiLunghezzaSbagliata;
var
  LData: TBytes;
begin
  LData := B.Join([B.Header(0, 1, 96), B.Track(B.EndOfTrack(0))]);
  LData[7] := 7;

  Assert.IsTrue(ParseFails(LData));
end;

procedure TTestMidiReader.TestTipoSconosciuto;
begin
  Assert.IsTrue(ParseFails(B.Join([B.Header(3, 1, 96), B.Track(B.EndOfTrack(0))])));
end;

procedure TTestMidiReader.TestSenzaTracce;
begin
  Assert.IsTrue(ParseFails(B.Header(0, 0, 96)));
end;

procedure TTestMidiReader.TestTracciaSenzaIntestazione;
var
  LData: TBytes;
begin
  LData := B.Join([B.Header(0, 1, 96), B.Track(B.EndOfTrack(0))]);
  LData[14] := Ord('X');

  Assert.IsTrue(ParseFails(LData));
end;

procedure TTestMidiReader.TestTracciaTroncata;
begin
  // The track says 20 bytes and the file ends after the first event
  Assert.IsTrue(ParseFails(B.Join([B.Header(0, 1, 96), B.Track(B.NoteOn(0, 0, 60, 100), 20)])));
end;

procedure TTestMidiReader.TestTracciaSenzaFineTraccia;
begin
  // The track has all the bytes that it says, but not the end of track event
  Assert.IsTrue(ParseFails(B.Join([B.Header(0, 1, 96), B.Track(B.NoteOn(0, 0, 60, 100))])));
end;

procedure TTestMidiReader.TestEventoSconosciuto;
begin
  Assert.IsTrue(ParseFails(B.Join([B.Header(0, 1, 96), B.Track(B.Bytes([0, $F1, 0, 0]))])));
end;

procedure TTestMidiReader.TestStatoCorrenteSenzaEventoPrecedente;
begin
  // The first event has no status byte
  Assert.IsTrue(ParseFails(B.Join([B.Header(0, 1, 96), B.Track(B.Join([B.Running(0, [60, 100]),
    B.EndOfTrack(0)]))])));
end;

procedure TTestMidiReader.TestLunghezzaVariabileTroppoLunga;
begin
  Assert.IsTrue(ParseFails(B.Join([B.Header(0, 1, 96), B.Track(B.Bytes([$81, $81, $81, $81, $01, $90, 1, 1]))])));
end;

procedure TTestMidiReader.TestDatiMetaPiuLunghiDelFile;
begin
  Assert.IsTrue(ParseFails(B.Join([B.Header(0, 1, 96), B.Track(B.Bytes([0, $FF, $01, $7F, 65, 66]))])));
end;

procedure TTestMidiReader.TestFineTracciaConDatiInPiuFaCercareLaProssimaTracciaSubito;
begin
  // The first track says 12 bytes but ends after 4: the second one is looked for right
  // after the end of track event, where there is no header. The C reader did the same
  Assert.IsTrue(ParseFails(B.Join([B.Header(1, 2, 96),
    B.Track(B.Join([B.EndOfTrack(0), B.Bytes([0, 0, 0, 0, 0, 0, 0, 0])])), B.Track(B.EndOfTrack(0))])));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMidiReader);

end.
