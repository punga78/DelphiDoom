{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the conversion of a MIDI track to MUS                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.M2m.Converter;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('m2m')]
  TTestMidiToMusConverter = class(TObject)
  private
    function Convert(const ADivision: Integer; const AEvents: TBytes): TBytes;
    function Mus(const AScoreLength, APrimaryChannels: Integer; const APatches: array of Integer;
      const AScore: array of Byte): TBytes;
    procedure AssertBytes(const AExpected, AActual: TBytes);
    function ConversionFails(const AMode, ADivision: Integer; const AEvents: TBytes): Boolean;
  public
    [Test]
    procedure TestUnaNotaConUnProgramma;
    [Test]
    procedure TestLaVelocitaUgualeNonSiRiscrive;
    [Test]
    procedure TestLePercussioniVannoSulCanale15ConUnProgrammaPerOgniTasto;
    [Test]
    procedure TestUnNoteOnConVelocitaZeroEUnNoteOff;
    [Test]
    procedure TestICanaliSiNumeranoDiNuovoNelLoroOrdine;
    [Test]
    procedure TestUnEventoScartatoRestituisceIlCanale;
    [Test]
    procedure TestIControllerCheMusHa;
    [Test]
    procedure TestPitchBend;
    [Test]
    procedure TestIlTempoCambiaLaDurataDelleNote;
    [Test]
    procedure TestIlTempoDiUnFileSmpte;
    [Test]
    procedure TestIlTempoNonContaInUnFileSmpte;
    [Test]
    procedure TestUnRitardoDiDueCifre;
    [Test]
    procedure TestLaListaDeiProgrammiESenzaDoppioniEOrdinata;
    [Test]
    procedure TestDueRitardiConUnEventoScartatoInMezzoSiUniscono;
    [Test]
    procedure TestRifiutaUnFileDiPiuTracce;
    [Test]
    procedure TestRifiutaUnaTracciaSenzaFine;
    [Test]
    procedure TestRifiutaUnPrimoEventoConUnRitardo;
    [Test]
    procedure TestRifiutaUnaDivisioneNulla;
  end;

implementation

uses
  DelphiDoom.M2m.Converter,
  DelphiDoom.M2m.Intf,
  DelphiDoom.M2m.MidiFile,
  DelphiDoom.M2m.MidiReader,
  DelphiDoom.M2m.Types,
  DelphiDoom.Tests.M2m.MidiBuilder;

type
  B = TTestMidiBuilder;

const
  // 70 clocks per quarter note at the tempo of 120 beats per minute: one MUS clock per MIDI clock
  DIVISION_ONE_TO_ONE = 70;
  // 25 frames per second, 40 clocks per frame
  DIVISION_SMPTE = $E728;

{ TTestMidiToMusConverter }

function TTestMidiToMusConverter.Convert(const ADivision: Integer; const AEvents: TBytes): TBytes;
var
  LData: TBytes;
  LMidi: TMidiFile;
begin
  LData := B.Join([B.Header(0, 1, ADivision), B.Track(AEvents)]);
  LMidi := TMidiReader.Parse(@LData[0], Length(LData));
  try
    Result := TMidiToMusConverter.Convert(LMidi);
  finally
    LMidi.Free;
  end;
end;

function TTestMidiToMusConverter.ConversionFails(const AMode, ADivision: Integer; const AEvents: TBytes): Boolean;
var
  LData: TBytes;
  LMidi: TMidiFile;
begin
  LData := B.Join([B.Header(AMode, 1, ADivision), B.Track(AEvents)]);
  LMidi := TMidiReader.Parse(@LData[0], Length(LData));
  try
    try
      TMidiToMusConverter.Convert(LMidi);
      Result := False;
    except
      on E: EM2mException do
        Result := E.Code = M2M_ERROR_CONVERT;
    end;
  finally
    LMidi.Free;
  end;
end;

// The header of a MUS file followed by the score
function TTestMidiToMusConverter.Mus(const AScoreLength, APrimaryChannels: Integer;
  const APatches: array of Integer; const AScore: array of Byte): TBytes;
var
  LPatch: Integer;
  LWords: TBytes;
begin
  LWords := B.Bytes([Byte(AScoreLength and $FF), Byte(AScoreLength shr 8),
    Byte((Length(APatches) * 2 + 16) and $FF), 0, Byte(APrimaryChannels), 0, 0, 0,
    Byte(Length(APatches)), 0, 0, 0]);
  for LPatch in APatches do
    LWords := B.Join([LWords, B.Bytes([Byte(LPatch and $FF), Byte(LPatch shr 8)])]);
  Result := B.Join([B.Bytes([Ord('M'), Ord('U'), Ord('S'), $1A]), LWords, B.Bytes(AScore)]);
end;

procedure TTestMidiToMusConverter.AssertBytes(const AExpected, AActual: TBytes);
var
  LIndex: Integer;
begin
  Assert.AreEqual(Length(AExpected), Length(AActual), 'length');
  for LIndex := 0 to High(AExpected) do
    Assert.AreEqual(Integer(AExpected[LIndex]), Integer(AActual[LIndex]), Format('byte %d', [LIndex]));
end;

procedure TTestMidiToMusConverter.TestUnaNotaConUnProgramma;
begin
  AssertBytes(
    B.Bytes([$4D, $55, $53, $1A, $0A, $00, $12, $00, $01, $00, $00, $00, $01, $00, $00, $00, $05, $00,
      $40, $00, $05, $90, $BC, $64, $0A, $00, $3C, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.ProgramChange(0, 0, 5), B.NoteOn(0, 0, 60, 100),
      B.NoteOff(10, 0, 60, 0), B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestLaVelocitaUgualeNonSiRiscrive;
begin
  // The second note has the velocity of the first one: its key has no flag and the velocity is left out
  AssertBytes(Mus(6, 1, [], [$10, $BC, $64, $10, $3E, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.NoteOn(0, 0, 60, 100), B.NoteOn(0, 0, 62, 100),
      B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestLePercussioniVannoSulCanale15ConUnProgrammaPerOgniTasto;
begin
  // The key 38 of the percussion is the patch 138; the channel 15 is not a primary one
  AssertBytes(Mus(4, 0, [138], [$1F, $A6, $50, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.NoteOn(0, 9, 38, 80), B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestUnNoteOnConVelocitaZeroEUnNoteOff;
begin
  // The velocity of the note off (40) is lost
  AssertBytes(Mus(8, 1, [], [$10, $BC, $64, $00, $3C, $00, $3E, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.NoteOn(0, 0, 60, 100), B.NoteOn(0, 0, 60, 0),
      B.NoteOff(0, 0, 62, 40), B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestICanaliSiNumeranoDiNuovoNelLoroOrdine;
begin
  // The MIDI channels 3 and 5 become the MUS channels 0 and 1
  AssertBytes(Mus(7, 2, [], [$10, $BC, $64, $11, $BD, $64, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.NoteOn(0, 3, 60, 100), B.NoteOn(0, 5, 61, 100),
      B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestUnEventoScartatoRestituisceIlCanale;
begin
  // The aftertouch of the channel 4 is lost, and the channel 4 does not take a number
  AssertBytes(Mus(4, 1, [], [$10, $BC, $64, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.NoteAftertouch(0, 4, 60, 9), B.NoteOn(0, 6, 60, 100),
      B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestIControllerCheMusHa;
begin
  // The volume (7) and all notes off (123) are written; the controller 99 is lost
  AssertBytes(Mus(6, 0, [], [$40, $03, $64, $30, $0B, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.Controller(0, 0, 7, 100), B.Controller(0, 0, 123, 0),
      B.Controller(0, 0, 99, 5), B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestPitchBend;
begin
  // 14 bits of 8192 (the middle) become 8 bits: 128
  AssertBytes(Mus(3, 0, [], [$20, $80, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.PitchBend(0, 0, 0, $40), B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestIlTempoCambiaLaDurataDelleNote;
begin
  // At 250000 microseconds per quarter note the clocks are twice as long: 20 MIDI clocks are 10 MUS clocks
  AssertBytes(Mus(7, 1, [], [$90, $BC, $64, $0A, $00, $3C, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.Tempo(0, 250000), B.NoteOn(0, 0, 60, 100),
      B.NoteOff(20, 0, 60, 0), B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestIlTempoDiUnFileSmpte;
begin
  // 140 / 25 / 40 = 0.14 MUS clocks per MIDI clock: 110 clocks are 15.4, 15 of them
  AssertBytes(Mus(7, 1, [], [$90, $BC, $64, $0F, $00, $3C, $60]),
    Convert(DIVISION_SMPTE, B.Join([B.NoteOn(0, 0, 60, 100), B.NoteOff(110, 0, 60, 0), B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestIlTempoNonContaInUnFileSmpte;
begin
  AssertBytes(Mus(7, 1, [], [$90, $BC, $64, $0F, $00, $3C, $60]),
    Convert(DIVISION_SMPTE, B.Join([B.Tempo(0, 250000), B.NoteOn(0, 0, 60, 100), B.NoteOff(110, 0, 60, 0),
      B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestUnRitardoDiDueCifre;
begin
  AssertBytes(Mus(8, 1, [], [$90, $BC, $64, $81, $48, $00, $3C, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.NoteOn(0, 0, 60, 100), B.NoteOff(200, 0, 60, 0),
      B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestLaListaDeiProgrammiESenzaDoppioniEOrdinata;
begin
  AssertBytes(Mus(10, 0, [3, 10], [$40, $00, $0A, $40, $00, $03, $40, $00, $0A, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.ProgramChange(0, 0, 10), B.ProgramChange(0, 0, 3),
      B.ProgramChange(0, 0, 10), B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestDueRitardiConUnEventoScartatoInMezzoSiUniscono;
begin
  // As in the C code, the delay of 20 replaces the one of 10 instead of adding to it
  AssertBytes(Mus(7, 1, [], [$90, $BC, $64, $14, $00, $3C, $60]),
    Convert(DIVISION_ONE_TO_ONE, B.Join([B.NoteOn(0, 0, 60, 100), B.NoteAftertouch(10, 0, 60, 5),
      B.NoteOff(20, 0, 60, 0), B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestRifiutaUnFileDiPiuTracce;
begin
  Assert.IsTrue(ConversionFails(2, DIVISION_ONE_TO_ONE, B.EndOfTrack(0)));
  Assert.IsTrue(ConversionFails(1, DIVISION_ONE_TO_ONE, B.EndOfTrack(0)));
end;

procedure TTestMidiToMusConverter.TestRifiutaUnaTracciaSenzaFine;
var
  LMidi: TMidiFile;
begin
  // The reader gives every track an end of track event, so this file is built by hand
  LMidi := TMidiFile.Create;
  try
    LMidi.Timing := DIVISION_ONE_TO_ONE;
    SetLength(LMidi.Tracks, 1);
    SetLength(LMidi.Tracks[0].Events, 1);
    LMidi.Tracks[0].Events[0].EventType := metNoteOn;
    LMidi.Tracks[0].Events[0].Param1 := 60;
    LMidi.Tracks[0].Events[0].Param2 := 100;

    Assert.WillRaise(
      procedure
      begin
        TMidiToMusConverter.Convert(LMidi);
      end, EM2mException);
  finally
    LMidi.Free;
  end;
end;

procedure TTestMidiToMusConverter.TestRifiutaUnPrimoEventoConUnRitardo;
begin
  // The score has to begin with an event: a delay before it cannot be written
  Assert.IsTrue(ConversionFails(0, DIVISION_ONE_TO_ONE, B.Join([B.NoteOn(5, 0, 60, 100), B.EndOfTrack(0)])));
end;

procedure TTestMidiToMusConverter.TestRifiutaUnaDivisioneNulla;
begin
  Assert.IsTrue(ConversionFails(0, 0, B.EndOfTrack(0)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMidiToMusConverter);

end.
