{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library tests - the options of the reader of m2m             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Midi.ReaderOptions;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.M2m.Intf,
  DelphiDoom.M2m.Types,
  DelphiDoom.M2m.MidiFile,
  DelphiDoom.M2m.MidiReader,
  DelphiDoom.Tests.M2m.MidiBuilder;

type
  [TestFixture]
  [Category('midi')]
  TTestMidiReaderOptions = class
  strict private
    FFile: TMidiFile;
    function Parse(const ABytes: TBytes; const AOptions: TMidiReaderOptions): TMidiFile;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareIlRunningStatusDopoUnMetaSenzaOpzioni;
    [Test]
    procedure DovrebbeTenereIlRunningStatusDopoUnMetaConLOpzione;
    [Test]
    procedure DovrebbeRifiutareUnaTracciaVuotaSenzaOpzioni;
    [Test]
    procedure DovrebbeLeggereUnaTracciaVuotaConLeLunghezze;
    [Test]
    procedure DovrebbeSaltareLaCodaDellaTracciaConLeLunghezze;
    [Test]
    procedure DovrebbeRifiutareUnTipoSconosciutoSenzaOpzioni;
    [Test]
    procedure DovrebbeAccettareUnTipoSconosciutoESenzaTracceConLOpzione;
    [Test]
    procedure DovrebbeDareLaDivisioneGrezza;
  end;

implementation

type
  TB = TTestMidiBuilder;

procedure TTestMidiReaderOptions.Setup;
begin
  FFile := nil;
end;

procedure TTestMidiReaderOptions.TearDown;
begin
  FreeAndNil(FFile);
end;

function TTestMidiReaderOptions.Parse(const ABytes: TBytes; const AOptions: TMidiReaderOptions): TMidiFile;
begin
  FreeAndNil(FFile);
  FFile := TMidiReader.Parse(@ABytes[0], Length(ABytes), AOptions);
  Result := FFile;
end;

procedure TTestMidiReaderOptions.DovrebbeRifiutareIlRunningStatusDopoUnMetaSenzaOpzioni;
var
  LBytes: TBytes;
begin
  LBytes := TB.Join([TB.Header(0, 1, 96), TB.Track(TB.Join([TB.NoteOn(0, 0, 60, 90),
    TB.Meta(10, $01, [Ord('t')]), TB.Running(10, [62, 90]), TB.EndOfTrack(0)]))]);
  Assert.WillRaise(
    procedure
    begin
      Parse(LBytes, []);
    end, EM2mException);
end;

procedure TTestMidiReaderOptions.DovrebbeTenereIlRunningStatusDopoUnMetaConLOpzione;
var
  LMidi: TMidiFile;
begin
  LMidi := Parse(TB.Join([TB.Header(0, 1, 96), TB.Track(TB.Join([TB.NoteOn(0, 0, 60, 90),
    TB.Meta(10, $01, [Ord('t')]), TB.Running(10, [62, 90]), TB.EndOfTrack(0)]))]),
    [mroRunningStatusAcrossMeta]);
  Assert.AreEqual(4, Integer(Length(LMidi.Tracks[0].Events)));
  Assert.AreEqual(Integer(Ord(metNoteOn)), Integer(Ord(LMidi.Tracks[0].Events[2].EventType)));
  Assert.AreEqual(62, LMidi.Tracks[0].Events[2].Param1);
end;

procedure TTestMidiReaderOptions.DovrebbeRifiutareUnaTracciaVuotaSenzaOpzioni;
var
  LBytes: TBytes;
begin
  LBytes := TB.Join([TB.Header(1, 1, 96), TB.Track(TB.Bytes([]))]);
  Assert.WillRaise(
    procedure
    begin
      Parse(LBytes, []);
    end, EM2mException);
end;

procedure TTestMidiReaderOptions.DovrebbeLeggereUnaTracciaVuotaConLeLunghezze;
var
  LMidi: TMidiFile;
begin
  LMidi := Parse(TB.Join([TB.Header(1, 2, 96), TB.Track(TB.Bytes([])),
    TB.Track(TB.Join([TB.NoteOn(0, 0, 60, 90), TB.EndOfTrack(0)]))]), [mroTrackLengths]);
  Assert.AreEqual(0, Integer(Length(LMidi.Tracks[0].Events)));
  Assert.AreEqual(2, Integer(Length(LMidi.Tracks[1].Events)));
end;

procedure TTestMidiReaderOptions.DovrebbeSaltareLaCodaDellaTracciaConLeLunghezze;
var
  LFirst: TBytes;
  LBytes: TBytes;
  LMidi: TMidiFile;
begin
  LFirst := TB.Join([TB.NoteOn(0, 0, 60, 90), TB.EndOfTrack(0)]);
  LBytes := TB.Join([TB.Header(1, 2, 96), TB.Track(LFirst, Length(LFirst) + 3),
    TB.Bytes([9, 9, 9]), TB.Track(TB.Join([TB.NoteOn(0, 1, 50, 80), TB.EndOfTrack(0)]))]);
  LMidi := Parse(LBytes, [mroTrackLengths]);
  Assert.AreEqual(2, Integer(Length(LMidi.Tracks[1].Events)));
  Assert.WillRaise(
    procedure
    begin
      Parse(LBytes, []);
    end, EM2mException);
end;

procedure TTestMidiReaderOptions.DovrebbeRifiutareUnTipoSconosciutoSenzaOpzioni;
var
  LBytes: TBytes;
begin
  LBytes := TB.Join([TB.Header(3, 1, 96), TB.Track(TB.EndOfTrack(0))]);
  Assert.WillRaise(
    procedure
    begin
      Parse(LBytes, []);
    end, EM2mException);
end;

procedure TTestMidiReaderOptions.DovrebbeAccettareUnTipoSconosciutoESenzaTracceConLOpzione;
var
  LMidi: TMidiFile;
begin
  LMidi := Parse(TB.Join([TB.Header(3, 1, 96), TB.Track(TB.EndOfTrack(0))]), [mroAnyHeader]);
  Assert.AreEqual(3, LMidi.Mode);
  LMidi := Parse(TB.Header(0, 0, 96), [mroAnyHeader]);
  Assert.AreEqual(0, Integer(Length(LMidi.Tracks)));
end;

procedure TTestMidiReaderOptions.DovrebbeDareLaDivisioneGrezza;
var
  LMidi: TMidiFile;
begin
  LMidi := Parse(TB.Join([TB.Header(0, 1, $E728), TB.Track(TB.EndOfTrack(0))]), []);
  Assert.AreEqual(Integer($E728), LMidi.RawDivision);
  Assert.AreEqual(25, LMidi.SmpteFps);
  Assert.AreEqual($28, LMidi.Timing);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMidiReaderOptions);

end.
