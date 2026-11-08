{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library tests - TMidiStreamSequencer                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Midi.StreamSequencer;

{$I DelphiDoom.Midi.inc}

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Midi.Types,
  DelphiDoom.Midi.Intf,
  DelphiDoom.Midi.Factory,
  DelphiDoom.Tests.M2m.MidiBuilder,
  DelphiDoom.Tests.Midi.FakeLog;

type
  [TestFixture]
  [Category('midi')]
  TTestMidiStreamSequencer = class
  strict private
    FLogObject: TFakeMidiLog;
    FLog: ILog;
    FSequencer: IMidiStreamSequencer;
    function Song(const ATrack: TBytes; ADivision: Integer = 96): TBytes;
    function Prepare(const ABytes: TBytes): Boolean;
    function Block(AReset: Boolean; out ACode: TMidiConvertResult): TBytes;
    function EventAt(const ABlock: TBytes; AIndex: Integer): TMidiStreamEvent;
    function KeyedNotes(ACount: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereGliEventiDiUnaCanzoneBreve;
    [Test]
    procedure DovrebbeDareFinitoDopoLaFineSenzaRipetizione;
    [Test]
    procedure DovrebbeContareNelDeltaIlTempoDelSysexNonScritto;
    [Test]
    procedure DovrebbeChiudereIlBloccoQuandoNonCapisceAltriEventi;
    [Test]
    procedure DovrebbeRimandareAlBloccoDopoLEventoCheNonCapiva;
    [Test]
    procedure DovrebbeChiudereIlBloccoDopoSessantaMillisecondi;
    [Test]
    procedure DovrebbeFarePrecedereIlProssimoEventoDalTempoRichiesto;
    [Test]
    procedure DovrebbeScalareIlTempoConLaPercentuale;
    [Test]
    procedure DovrebbeChiedereLaChiamataPerLaVolumeDelCanale;
    [Test]
    procedure DovrebbeRicominciareSeLaCanzoneSiRipete;
{$IFDEF MIDI_LEGACY_LOOP}
    [Test]
    procedure DovrebbeConservareIlDeltaCheAvvolgeDopoIlGiro;
{$ELSE}
    [Test]
    procedure DovrebbeAzzerareIlTempoAlGiro;
    [Test]
    procedure DovrebbeDareIlTempoDelPrimoEventoDopoIlGiro;
    [Test]
    procedure DovrebbeAzzerareIlTempoConIlRewind;
{$ENDIF}
    [Test]
    procedure DovrebbeDimenticareLEventoInSospesoConIlReset;
    [Test]
    procedure DovrebbeTenereLEventoInSospesoSenzaReset;
    [Test]
    procedure DovrebbeRicominciareDalPrimoEventoConRewind;
    [Test]
    procedure DovrebbeDareFalsoEBlocchiVuotiSeIlFileNonSiLegge;
    [Test]
    procedure DovrebbeDareLaDivisioneEIValoriIniziali;
    [Test]
    procedure DovrebbeLeggereUnaDivisioneZeroComeUno;
    [Test]
    procedure DovrebbeFarCreareUnSequencerPerCanzoneDallaFabbrica;
  end;

implementation

type
  TB = TTestMidiBuilder;

procedure TTestMidiStreamSequencer.Setup;
begin
  FLogObject := TFakeMidiLog.Create;
  FLog := FLogObject;
  FSequencer := TMidiFactory.CreateSequencer(FLog);
end;

procedure TTestMidiStreamSequencer.TearDown;
begin
  FSequencer := nil;
  FLog := nil;
  FLogObject := nil;
end;

function TTestMidiStreamSequencer.Song(const ATrack: TBytes; ADivision: Integer): TBytes;
begin
  Result := TB.Join([TB.Header(0, 1, ADivision), TB.Track(ATrack)]);
end;

function TTestMidiStreamSequencer.Prepare(const ABytes: TBytes): Boolean;
begin
  Result := FSequencer.Load(@ABytes[0], Length(ABytes));
end;

function TTestMidiStreamSequencer.Block(AReset: Boolean; out ACode: TMidiConvertResult): TBytes;
begin
  ACode := FSequencer.ConvertBlock(AReset, 1024, Result);
end;

function TTestMidiStreamSequencer.EventAt(const ABlock: TBytes; AIndex: Integer): TMidiStreamEvent;
begin
  Move(ABlock[AIndex * MIDI_STREAM_EVENT_SIZE], Result, MIDI_STREAM_EVENT_SIZE);
end;

// events with delta zero, each with its own key: the key says which event it is
function TTestMidiStreamSequencer.KeyedNotes(ACount: Integer): TBytes;
var
  LParts: array of TBytes;
  LIndex: Integer;
begin
  SetLength(LParts, ACount + 1);
  for LIndex := 0 to ACount - 1 do
    LParts[LIndex] := TB.NoteOn(0, 0, LIndex, 90);
  LParts[ACount] := TB.EndOfTrack(0);
  Result := TB.Join(LParts);
end;

procedure TTestMidiStreamSequencer.DovrebbeScrivereGliEventiDiUnaCanzoneBreve;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(TB.Join([TB.Tempo(0, 500000), TB.NoteOn(0, 0, 60, 100),
    TB.NoteOff(48, 0, 60, 0), TB.EndOfTrack(0)]))));
  LBlock := Block(True, LCode);
  Assert.AreEqual(Integer(Ord(mcrNoError)), Integer(Ord(LCode)));
  Assert.AreEqual(36, Integer(Length(LBlock)));
  Assert.AreEqual(Integer(0), Integer(EventAt(LBlock, 0).Time));
  Assert.AreEqual(Integer($0107A120), Integer(EventAt(LBlock, 0).Event));
  Assert.AreEqual(Integer(0), Integer(EventAt(LBlock, 1).StreamId));
  Assert.AreEqual(Integer($00643C90), Integer(EventAt(LBlock, 1).Event));
  Assert.AreEqual(Integer(48), Integer(EventAt(LBlock, 2).Time));
  Assert.AreEqual(Integer($00003C80), Integer(EventAt(LBlock, 2).Event));
end;

procedure TTestMidiStreamSequencer.DovrebbeDareFinitoDopoLaFineSenzaRipetizione;
var
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(TB.Join([TB.NoteOn(0, 0, 60, 100), TB.EndOfTrack(0)]))));
  Block(True, LCode);
  Block(False, LCode);
  Assert.AreEqual(Integer(Ord(mcrDone)), Integer(Ord(LCode)));
  Assert.AreEqual(0, Integer(Length(Block(False, LCode))));
  Assert.AreEqual(Integer(Ord(mcrDone)), Integer(Ord(LCode)));
end;

procedure TTestMidiStreamSequencer.DovrebbeContareNelDeltaIlTempoDelSysexNonScritto;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(TB.Join([TB.NoteOn(0, 0, 60, 90), TB.SysEx(100, [1, 2, $F7]),
    TB.NoteOff(100, 0, 60, 0), TB.EndOfTrack(0)]))));
  LBlock := Block(True, LCode);
  Assert.AreEqual(24, Integer(Length(LBlock)));
  // as in the old player: the second event is 100 ticks after the sysex, not 200 after the first
  Assert.AreEqual(Integer(100), Integer(EventAt(LBlock, 1).Time));
end;

procedure TTestMidiStreamSequencer.DovrebbeChiudereIlBloccoQuandoNonCapisceAltriEventi;
var
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(KeyedNotes(200))));
  // 1024 bytes hold 85 events of 12 bytes
  Assert.AreEqual(1020, Integer(Length(Block(True, LCode))));
  Assert.AreEqual(Integer(Ord(mcrNoError)), Integer(Ord(LCode)));
  Assert.AreEqual(1020, Integer(Length(Block(False, LCode))));
  Assert.AreEqual(360, Integer(Length(Block(False, LCode))));
  Assert.AreEqual(Integer(Ord(mcrNoError)), Integer(Ord(LCode)));
  Block(False, LCode);
  Assert.AreEqual(Integer(Ord(mcrDone)), Integer(Ord(LCode)));
end;

procedure TTestMidiStreamSequencer.DovrebbeRimandareAlBloccoDopoLEventoCheNonCapiva;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(KeyedNotes(128))));
  Block(True, LCode);
  LBlock := Block(False, LCode);
  // the keys of the first block are 0..84: the event 85 did not fit and opens the second
  Assert.AreEqual(Integer(85), Integer(EventAt(LBlock, 0).Data[1]));
  Assert.AreEqual(Integer(0), Integer(EventAt(LBlock, 0).Time));
end;

procedure TTestMidiStreamSequencer.DovrebbeChiudereIlBloccoDopoSessantaMillisecondi;
var
  LParts: array of TBytes;
  LIndex: Integer;
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  // 96 ticks per quarter note at 500000 microseconds: a block covers 11 ticks
  SetLength(LParts, 12);
  LParts[0] := TB.Tempo(0, 500000);
  for LIndex := 0 to 9 do
    LParts[LIndex + 1] := TB.NoteOn(5, 0, 60 + LIndex, 90);
  LParts[11] := TB.EndOfTrack(0);
  Assert.IsTrue(Prepare(Song(TB.Join(LParts))));
  LBlock := Block(True, LCode);
  // the tempo and four notes (at 5, 10, 15 and 20 ticks)
  Assert.AreEqual(60, Integer(Length(LBlock)));
  LBlock := Block(False, LCode);
  Assert.AreEqual(Integer(64), Integer(EventAt(LBlock, 0).Data[1]));
  Assert.AreEqual(Integer(5), Integer(EventAt(LBlock, 0).Time));
end;

procedure TTestMidiStreamSequencer.DovrebbeFarePrecedereIlProssimoEventoDalTempoRichiesto;
var
  LBlock: TBytes;
  LParts: array of TBytes;
  LCode: TMidiConvertResult;
begin
  SetLength(LParts, 2);
  LParts[0] := TB.Tempo(0, 500000);
  LParts[1] := KeyedNotes(200);
  Assert.IsTrue(Prepare(Song(TB.Join(LParts))));
  Block(True, LCode);
  FSequencer.RequestTempoEvent;
  LBlock := Block(False, LCode);
  Assert.AreEqual(Integer($0107A120), Integer(EventAt(LBlock, 0).Event));
  Assert.AreEqual(Integer(0), Integer(EventAt(LBlock, 0).Time));
  Assert.AreEqual(Integer($90), Integer(EventAt(LBlock, 1).Data[0]));
  // the next event follows at once, 12 bytes after the tempo event
  Assert.AreEqual(1020, Integer(Length(LBlock)));
end;

procedure TTestMidiStreamSequencer.DovrebbeScalareIlTempoConLaPercentuale;
var
  LBlock: TBytes;
  LParts: array of TBytes;
  LCode: TMidiConvertResult;
begin
  SetLength(LParts, 2);
  LParts[0] := TB.Tempo(0, 500000);
  LParts[1] := KeyedNotes(200);
  Assert.IsTrue(Prepare(Song(TB.Join(LParts))));
  Block(True, LCode);
  FSequencer.TempoPercent := 200;
  LBlock := Block(False, LCode);
  // half the microseconds: twice as fast
  Assert.AreEqual(Integer($0103D090), Integer(EventAt(LBlock, 0).Event));
end;

procedure TTestMidiStreamSequencer.DovrebbeChiedereLaChiamataPerLaVolumeDelCanale;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(TB.Join([TB.Controller(0, 2, 7, 100), TB.Controller(0, 2, 10, 64),
    TB.EndOfTrack(0)]))));
  LBlock := Block(True, LCode);
  Assert.AreEqual(Integer($4064 * $10000 + $0700 + $B2), Integer(EventAt(LBlock, 0).Event));
  Assert.AreEqual(Integer($40 * $10000 + $0A00 + $B2), Integer(EventAt(LBlock, 1).Event));
end;

procedure TTestMidiStreamSequencer.DovrebbeRicominciareSeLaCanzoneSiRipete;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(TB.Join([TB.NoteOn(0, 0, 60, 100), TB.NoteOff(24, 0, 60, 0),
    TB.EndOfTrack(0)]))));
  Block(True, LCode);
  FSequencer.Looped := True;
  LBlock := Block(False, LCode);
  Assert.AreEqual(Integer(Ord(mcrNoError)), Integer(Ord(LCode)));
  Assert.AreEqual(24, Integer(Length(LBlock)));
  Assert.AreEqual(Integer(60), Integer(EventAt(LBlock, 0).Data[1]));
end;

{$IFDEF MIDI_LEGACY_LOOP}
procedure TTestMidiStreamSequencer.DovrebbeConservareIlDeltaCheAvvolgeDopoIlGiro;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(TB.Join([TB.NoteOn(0, 0, 60, 100), TB.NoteOff(24, 0, 60, 0),
    TB.EndOfTrack(0)]))));
  Block(True, LCode);
  FSequencer.Looped := True;
  LBlock := Block(False, LCode);
  // the old player did not bring the time back to zero: 0 - 24 wraps around
  Assert.AreEqual(Int64($FFFFFFE8), Int64(EventAt(LBlock, 0).Time));
end;
{$ELSE}
procedure TTestMidiStreamSequencer.DovrebbeAzzerareIlTempoAlGiro;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(TB.Join([TB.NoteOn(0, 0, 60, 100), TB.NoteOff(24, 0, 60, 0),
    TB.EndOfTrack(0)]))));
  Block(True, LCode);
  FSequencer.Looped := True;
  LBlock := Block(False, LCode);
  // the first event is at time zero: its delta is zero, not 0 - 24
  Assert.AreEqual(Integer(0), Integer(EventAt(LBlock, 0).Time));
  Assert.AreEqual(Integer(24), Integer(EventAt(LBlock, 1).Time));
end;

procedure TTestMidiStreamSequencer.DovrebbeDareIlTempoDelPrimoEventoDopoIlGiro;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(TB.Join([TB.NoteOn(10, 0, 60, 100), TB.NoteOff(24, 0, 60, 0),
    TB.EndOfTrack(0)]))));
  Block(True, LCode);
  FSequencer.Looped := True;
  LBlock := Block(False, LCode);
  // the song waits 10 ticks before its first event, every round
  Assert.AreEqual(Integer(10), Integer(EventAt(LBlock, 0).Time));
  Assert.AreEqual(Integer(24), Integer(EventAt(LBlock, 1).Time));
end;

procedure TTestMidiStreamSequencer.DovrebbeAzzerareIlTempoConIlRewind;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(TB.Join([TB.NoteOn(10, 0, 60, 100), TB.NoteOff(24, 0, 60, 0),
    TB.EndOfTrack(0)]))));
  Block(True, LCode);
  FSequencer.Rewind;
  LBlock := Block(False, LCode);
  Assert.AreEqual(Integer(10), Integer(EventAt(LBlock, 0).Time));
end;
{$ENDIF}

procedure TTestMidiStreamSequencer.DovrebbeDimenticareLEventoInSospesoConIlReset;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(KeyedNotes(128))));
  Block(True, LCode);
  LBlock := Block(True, LCode);
  Assert.AreEqual(Integer(86), Integer(EventAt(LBlock, 0).Data[1]));
end;

procedure TTestMidiStreamSequencer.DovrebbeTenereLEventoInSospesoSenzaReset;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(KeyedNotes(128))));
  Block(True, LCode);
  LBlock := Block(False, LCode);
  Assert.AreEqual(Integer(85), Integer(EventAt(LBlock, 0).Data[1]));
end;

procedure TTestMidiStreamSequencer.DovrebbeRicominciareDalPrimoEventoConRewind;
var
  LBlock: TBytes;
  LCode: TMidiConvertResult;
begin
  Assert.IsTrue(Prepare(Song(KeyedNotes(128))));
  Block(True, LCode);
  FSequencer.Rewind;
  LBlock := Block(False, LCode);
  Assert.AreEqual(Integer(0), Integer(EventAt(LBlock, 0).Data[1]));
end;

procedure TTestMidiStreamSequencer.DovrebbeDareFalsoEBlocchiVuotiSeIlFileNonSiLegge;
var
  LBytes: TBytes;
  LCode: TMidiConvertResult;
begin
  LBytes := TB.Bytes([1, 2, 3, 4, 5, 6, 7, 8]);
  Assert.IsFalse(FSequencer.Load(@LBytes[0], Length(LBytes)));
  Assert.AreEqual(1, FLogObject.Warnings);
  Assert.AreEqual(0, Integer(Length(Block(True, LCode))));
end;

procedure TTestMidiStreamSequencer.DovrebbeDareLaDivisioneEIValoriIniziali;
begin
  Assert.IsTrue(Prepare(Song(TB.EndOfTrack(0), $E728)));
  Assert.AreEqual(Integer($E728), Integer(FSequencer.TimeDivision));
  Assert.IsFalse(FSequencer.Looped);
  Assert.AreEqual(Integer(100), Integer(FSequencer.TempoPercent));
end;

procedure TTestMidiStreamSequencer.DovrebbeLeggereUnaDivisioneZeroComeUno;
begin
  FSequencer.TempoPercent := 0;
  Assert.AreEqual(Integer(1), Integer(FSequencer.TempoPercent));
end;

procedure TTestMidiStreamSequencer.DovrebbeFarCreareUnSequencerPerCanzoneDallaFabbrica;
var
  LFactory: IMidiStreamSequencerFactory;
begin
  LFactory := TMidiFactory.CreateSequencerFactory(FLog);
  Assert.IsTrue(LFactory.CreateSequencer <> LFactory.CreateSequencer);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMidiStreamSequencer);

end.
