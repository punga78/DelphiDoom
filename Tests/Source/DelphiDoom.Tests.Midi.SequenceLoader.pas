{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library tests - TMidiSequenceLoader                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Midi.SequenceLoader;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Midi.Types,
  DelphiDoom.Midi.SequenceLoader,
  DelphiDoom.Tests.M2m.MidiBuilder,
  DelphiDoom.Tests.Midi.FakeLog;

type
  [TestFixture]
  [Category('midi')]
  TTestMidiSequenceLoader = class
  strict private
    FLogObject: TFakeMidiLog;
    FLog: ILog;
    FEvents: TArray<TMidiSequenceEvent>;
    FDivision: Word;
    function Load(const ABytes: TBytes): Boolean;
    function OneTrack(const AEvents: array of TBytes; AFormat: Integer = 0): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereUnaTracciaSingola;
    [Test]
    procedure DovrebbeScartareLaFineTraccia;
    [Test]
    procedure DovrebbeTenereLoStatoCorrenteDopoUnMeta;
    [Test]
    procedure DovrebbeUnireLeTraccieNellOrdineDelTempo;
    [Test]
    procedure DovrebbeTenereIlTempoAssolutoDopoLaFineDiUnaTraccia;
    [Test]
    procedure DovrebbeDareLaPrecedenzaAllaPrimaTracciaNelPareggio;
    [Test]
    procedure DovrebbeAccettareUnaTracciaVuota;
    [Test]
    procedure DovrebbeDareLaDivisioneComeScrittaNelFile;
    [Test]
    procedure DovrebbeDareFalsoConUnIntestazioneErrata;
    [Test]
    procedure DovrebbeDareFalsoSenzaDati;
    [Test]
    procedure DovrebbeLeggereUnTempoNonValidoComeMetaInutile;
    [Test]
    procedure DovrebbeSaltareCioCheSegueLaFineTraccia;
    [Test]
    procedure DovrebbeSegnareIlSysexComeNonSuonato;
    [Test]
    procedure DovrebbeUnireLeTraccieDiUnFileDiTipoDue;
  end;

implementation

type
  TB = TTestMidiBuilder;

procedure TTestMidiSequenceLoader.Setup;
begin
  FLogObject := TFakeMidiLog.Create;
  FLog := FLogObject;
  FEvents := nil;
  FDivision := 0;
end;

procedure TTestMidiSequenceLoader.TearDown;
begin
  FLog := nil;
  FLogObject := nil;
end;

function TTestMidiSequenceLoader.Load(const ABytes: TBytes): Boolean;
begin
  if Length(ABytes) = 0 then
    Result := TMidiSequenceLoader.TryLoad(nil, 0, FLog, FEvents, FDivision)
  else
    Result := TMidiSequenceLoader.TryLoad(@ABytes[0], Length(ABytes), FLog, FEvents, FDivision);
end;

function TTestMidiSequenceLoader.OneTrack(const AEvents: array of TBytes; AFormat: Integer): TBytes;
var
  LJoined: TBytes;
begin
  LJoined := TB.Join(AEvents);
  Result := TB.Join([TB.Header(AFormat, 1, 96), TB.Track(LJoined)]);
end;

procedure TTestMidiSequenceLoader.DovrebbeLeggereUnaTracciaSingola;
begin
  Assert.IsTrue(Load(OneTrack([TB.Tempo(0, 500000), TB.NoteOn(0, 0, 60, 100),
    TB.NoteOff(48, 0, 60, 0), TB.EndOfTrack(0)])));
  Assert.AreEqual(3, Integer(Length(FEvents)));
  Assert.AreEqual(Integer(Ord(mskTempo)), Integer(Ord(FEvents[0].Kind)));
  Assert.AreEqual(Integer(500000), Integer(FEvents[0].Tempo));
  Assert.AreEqual(Integer($90), Integer(FEvents[1].Status));
  Assert.AreEqual(Integer(60), Integer(FEvents[1].Data1));
  Assert.AreEqual(Integer(100), Integer(FEvents[1].Data2));
  Assert.AreEqual(Integer($80), Integer(FEvents[2].Status));
  Assert.AreEqual(Integer(48), Integer(FEvents[2].Time));
  Assert.AreEqual(Integer(96), Integer(FDivision));
end;

procedure TTestMidiSequenceLoader.DovrebbeScartareLaFineTraccia;
begin
  Assert.IsTrue(Load(OneTrack([TB.NoteOn(0, 0, 60, 100), TB.EndOfTrack(500)])));
  Assert.AreEqual(1, Integer(Length(FEvents)));
end;

procedure TTestMidiSequenceLoader.DovrebbeTenereLoStatoCorrenteDopoUnMeta;
begin
  Assert.IsTrue(Load(OneTrack([TB.NoteOn(0, 0, 60, 90), TB.Meta(10, $01, [Ord('t')]),
    TB.Running(10, [62, 90]), TB.EndOfTrack(0)])));
  Assert.AreEqual(3, Integer(Length(FEvents)));
  Assert.AreEqual(Integer(Ord(mskOtherMeta)), Integer(Ord(FEvents[1].Kind)));
  Assert.AreEqual(Integer(Ord(mskChannel)), Integer(Ord(FEvents[2].Kind)));
  Assert.AreEqual(Integer($90), Integer(FEvents[2].Status));
  Assert.AreEqual(Integer(62), Integer(FEvents[2].Data1));
  Assert.AreEqual(Integer(20), Integer(FEvents[2].Time));
end;

procedure TTestMidiSequenceLoader.DovrebbeUnireLeTraccieNellOrdineDelTempo;
begin
  Assert.IsTrue(Load(TB.Join([TB.Header(1, 2, 96),
    TB.Track(TB.Join([TB.NoteOn(0, 0, 60, 90), TB.EndOfTrack(10)])),
    TB.Track(TB.Join([TB.NoteOn(5, 1, 50, 80), TB.EndOfTrack(0)]))])));
  Assert.AreEqual(2, Integer(Length(FEvents)));
  Assert.AreEqual(Integer($90), Integer(FEvents[0].Status));
  Assert.AreEqual(Integer(0), Integer(FEvents[0].Time));
  Assert.AreEqual(Integer($91), Integer(FEvents[1].Status));
  Assert.AreEqual(Integer(5), Integer(FEvents[1].Time));
end;

procedure TTestMidiSequenceLoader.DovrebbeTenereIlTempoAssolutoDopoLaFineDiUnaTraccia;
begin
  // regression: the end of track at 1 of the first track was dropped by the merger and its
  // time lost, so the last note came at 118 and not at 119
  Assert.IsTrue(Load(TB.Join([TB.Header(1, 2, 96),
    TB.Track(TB.Join([TB.NoteOn(0, 0, 60, 90), TB.EndOfTrack(1)])),
    TB.Track(TB.Join([TB.NoteOn(0, 1, 50, 80), TB.NoteOn(119, 1, 52, 80), TB.EndOfTrack(0)]))])));
  Assert.AreEqual(3, Integer(Length(FEvents)));
  Assert.AreEqual(Integer(52), Integer(FEvents[2].Data1));
  Assert.AreEqual(Integer(119), Integer(FEvents[2].Time));
end;

procedure TTestMidiSequenceLoader.DovrebbeDareLaPrecedenzaAllaPrimaTracciaNelPareggio;
begin
  Assert.IsTrue(Load(TB.Join([TB.Header(1, 2, 96),
    TB.Track(TB.Join([TB.NoteOn(10, 0, 60, 90), TB.EndOfTrack(0)])),
    TB.Track(TB.Join([TB.NoteOn(10, 1, 50, 80), TB.EndOfTrack(0)]))])));
  Assert.AreEqual(2, Integer(Length(FEvents)));
  Assert.AreEqual(Integer($90), Integer(FEvents[0].Status));
  Assert.AreEqual(Integer($91), Integer(FEvents[1].Status));
  Assert.AreEqual(Integer(10), Integer(FEvents[1].Time));
end;

procedure TTestMidiSequenceLoader.DovrebbeAccettareUnaTracciaVuota;
begin
  Assert.IsTrue(Load(TB.Join([TB.Header(1, 2, 96), TB.Track(TB.Bytes([])),
    TB.Track(TB.Join([TB.NoteOn(0, 0, 60, 90), TB.EndOfTrack(0)]))])));
  Assert.AreEqual(1, Integer(Length(FEvents)));
end;

procedure TTestMidiSequenceLoader.DovrebbeDareLaDivisioneComeScrittaNelFile;
begin
  Assert.IsTrue(Load(TB.Join([TB.Header(0, 1, $E728),
    TB.Track(TB.Join([TB.NoteOn(0, 0, 60, 90), TB.EndOfTrack(0)]))])));
  Assert.AreEqual(Integer($E728), Integer(FDivision));
end;

procedure TTestMidiSequenceLoader.DovrebbeDareFalsoConUnIntestazioneErrata;
begin
  Assert.IsFalse(Load(TB.Join([TB.Bytes([Ord('M'), Ord('T'), Ord('h'), Ord('x'), 0, 0, 0, 6, 0, 0, 0, 1, 0, 96]),
    TB.Track(TB.EndOfTrack(0))])));
  Assert.AreEqual(1, FLogObject.Warnings);
  Assert.AreEqual(0, Integer(Length(FEvents)));
end;

procedure TTestMidiSequenceLoader.DovrebbeDareFalsoSenzaDati;
begin
  Assert.IsFalse(Load(nil));
  Assert.AreEqual(1, FLogObject.Warnings);
end;

procedure TTestMidiSequenceLoader.DovrebbeLeggereUnTempoNonValidoComeMetaInutile;
begin
  Assert.IsTrue(Load(OneTrack([TB.Meta(0, $51, [1, 2]), TB.Meta(0, $51, [0, 0, 0]),
    TB.EndOfTrack(0)])));
  Assert.AreEqual(2, Integer(Length(FEvents)));
  Assert.AreEqual(Integer(Ord(mskOtherMeta)), Integer(Ord(FEvents[0].Kind)));
  Assert.AreEqual(Integer(Ord(mskOtherMeta)), Integer(Ord(FEvents[1].Kind)));
  Assert.AreEqual(2, FLogObject.DevWarnings);
end;

procedure TTestMidiSequenceLoader.DovrebbeSaltareCioCheSegueLaFineTraccia;
var
  LFirst: TBytes;
begin
  LFirst := TB.Join([TB.NoteOn(0, 0, 60, 90), TB.NoteOff(10, 0, 60, 0), TB.EndOfTrack(0)]);
  Assert.IsTrue(Load(TB.Join([TB.Header(1, 2, 96), TB.Track(LFirst, Length(LFirst) + 4),
    TB.Bytes([1, 2, 3, 4]), TB.Track(TB.Join([TB.NoteOn(0, 1, 50, 80), TB.EndOfTrack(0)]))])));
  Assert.AreEqual(3, Integer(Length(FEvents)));
end;

procedure TTestMidiSequenceLoader.DovrebbeSegnareIlSysexComeNonSuonato;
begin
  Assert.IsTrue(Load(OneTrack([TB.SysEx(0, [1, 2, $F7]), TB.EndOfTrack(0)])));
  Assert.AreEqual(1, Integer(Length(FEvents)));
  Assert.AreEqual(Integer(Ord(mskSystemExclusive)), Integer(Ord(FEvents[0].Kind)));
end;

procedure TTestMidiSequenceLoader.DovrebbeUnireLeTraccieDiUnFileDiTipoDue;
begin
  Assert.IsTrue(Load(TB.Join([TB.Header(2, 2, 96),
    TB.Track(TB.Join([TB.NoteOn(10, 0, 60, 90), TB.EndOfTrack(0)])),
    TB.Track(TB.Join([TB.NoteOn(5, 1, 50, 80), TB.EndOfTrack(0)]))])));
  Assert.AreEqual(2, Integer(Length(FEvents)));
  Assert.AreEqual(Integer($91), Integer(FEvents[0].Status));
  Assert.AreEqual(Integer($90), Integer(FEvents[1].Status));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMidiSequenceLoader);

end.
