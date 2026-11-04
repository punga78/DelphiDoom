{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IT loader of the tracker                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.Loader.It;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tracker.Loader.It,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerItLoader = class(TObject)
  private
    FModule: TTrackerModule;
    FBytes: TBytes;
    // A module of 2 channels with one instrument, one 16 bit sample of 4
    // samples and one pattern of 3 rows
    function BuildIt: TBytes;
    procedure PutWord(var ABytes: TBytes; const AOffset, AValue: Integer);
    procedure PutCardinal(var ABytes: TBytes; const AOffset: Integer; const AValue: Cardinal);
    procedure PutText(var ABytes: TBytes; const AOffset: Integer; const AText: string);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRiconoscePerLaFirma;
    [Test]
    procedure TestVersioneVecchiaSollevaEccezione;
    [Test]
    procedure TestFileTroncatoSollevaEccezione;
    [Test]
    procedure TestIntestazione;
    [Test]
    procedure TestPannelloDeiCanali;
    [Test]
    procedure TestCampioneSedicibitConSegno;
    [Test]
    procedure TestRipetizioneEPannelloDelCampione;
    [Test]
    procedure TestCampioneOttoBitSenzaSegno;
    [Test]
    procedure TestCampioneOttoBitConDelta;
    [Test]
    procedure TestStrumento;
    [Test]
    procedure TestMappeDelleNote;
    [Test]
    procedure TestInviluppi;
    [Test]
    procedure TestCellaConTuttiICampi;
    [Test]
    procedure TestNotaOffEMaschera;
    [Test]
    procedure TestRipeteIValoriPrecedenti;
    [Test]
    procedure TestRigaVuota;
    [Test]
    procedure TestSenzaStrumentiIDatiSonoICampioni;
  end;

implementation

const
  INSTRUMENT_OFFSET = $100;
  SAMPLE_OFFSET = $340;
  PATTERN_OFFSET = $3A0;
  DATA_OFFSET = $400;

{ TTestTrackerItLoader }

procedure TTestTrackerItLoader.TearDown;
begin
  FreeAndNil(FModule);
end;

procedure TTestTrackerItLoader.PutWord(var ABytes: TBytes; const AOffset, AValue: Integer);
begin
  ABytes[AOffset] := Byte(AValue);
  ABytes[AOffset + 1] := Byte(AValue shr 8);
end;

procedure TTestTrackerItLoader.PutCardinal(var ABytes: TBytes; const AOffset: Integer;
  const AValue: Cardinal);
begin
  PutWord(ABytes, AOffset, Integer(AValue and $FFFF));
  PutWord(ABytes, AOffset + 2, Integer(AValue shr 16));
end;

procedure TTestTrackerItLoader.PutText(var ABytes: TBytes; const AOffset: Integer;
  const AText: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    ABytes[AOffset + LIndex - 1] := Ord(AText[LIndex]);
end;

function TTestTrackerItLoader.BuildIt: TBytes;
var
  LNote, LBase: Integer;
begin
  SetLength(Result, DATA_OFFSET + 8);
  PutText(Result, 0, 'IMPM');
  PutText(Result, 4, 'IT TEST');
  PutWord(Result, 32, 2);            // orders
  PutWord(Result, 34, 1);            // instruments
  PutWord(Result, 36, 1);            // samples
  PutWord(Result, 38, 1);            // patterns
  PutWord(Result, 40, $0214);        // created with
  PutWord(Result, 42, $0214);        // compatible with
  PutWord(Result, 44, 1 or 4 or 8);  // stereo, instruments, linear slides
  Result[48] := 128;                 // global volume
  Result[50] := 5;                   // speed
  Result[51] := 150;                 // tempo
  Result[64] := 16;                  // channel 0: to the left
  Result[65] := 100;                 // channel 1: surround
  for LNote := 2 to 63 do
    Result[64 + LNote] := 160;
  Result[192] := 0;
  Result[193] := 255;
  PutCardinal(Result, 194, INSTRUMENT_OFFSET);
  PutCardinal(Result, 198, SAMPLE_OFFSET);
  PutCardinal(Result, 202, PATTERN_OFFSET);

  // The instrument
  PutText(Result, INSTRUMENT_OFFSET, 'IMPI');
  Result[INSTRUMENT_OFFSET + 17] := 2;               // new note action: off
  Result[INSTRUMENT_OFFSET + 18] := 1;               // duplicate check: note
  Result[INSTRUMENT_OFFSET + 19] := 2;               // duplicate action: fade
  PutWord(Result, INSTRUMENT_OFFSET + 20, 256);      // fade out
  Result[INSTRUMENT_OFFSET + 22] := $F8;             // pitch pan separation -8
  Result[INSTRUMENT_OFFSET + 23] := 60;              // pitch pan center
  Result[INSTRUMENT_OFFSET + 24] := 100;             // global volume
  Result[INSTRUMENT_OFFSET + 25] := 32;              // default panning
  PutText(Result, INSTRUMENT_OFFSET + 32, 'INSTRUMENT 1');
  for LNote := 0 to 119 do
    Result[INSTRUMENT_OFFSET + 64 + 2 * LNote] := LNote;
  // The notes 0 and 1 play the sample 1, as the notes 12 and 13
  Result[INSTRUMENT_OFFSET + 64] := 12;
  Result[INSTRUMENT_OFFSET + 65] := 1;
  Result[INSTRUMENT_OFFSET + 66] := 13;
  Result[INSTRUMENT_OFFSET + 67] := 1;
  // The volume envelope: on and loop, two nodes
  LBase := INSTRUMENT_OFFSET + 304;
  Result[LBase] := 3;
  Result[LBase + 1] := 2;
  Result[LBase + 2] := 0;
  Result[LBase + 3] := 1;
  Result[LBase + 6] := 64;
  PutWord(Result, LBase + 7, 0);
  Result[LBase + 9] := 32;
  PutWord(Result, LBase + 10, 20);
  // The panning envelope: on, two signed nodes (-32 and 32)
  LBase := INSTRUMENT_OFFSET + 386;
  Result[LBase] := 1;
  Result[LBase + 1] := 2;
  Result[LBase + 6] := $E0;
  PutWord(Result, LBase + 7, 0);
  Result[LBase + 9] := $20;
  PutWord(Result, LBase + 10, 10);

  // The sample: 16 bit, signed, with a loop and a default panning
  PutText(Result, SAMPLE_OFFSET, 'IMPS');
  Result[SAMPLE_OFFSET + 17] := 64;
  Result[SAMPLE_OFFSET + 18] := 1 or 2 or 16;
  Result[SAMPLE_OFFSET + 19] := 40;
  PutText(Result, SAMPLE_OFFSET + 20, 'SMP 1');
  Result[SAMPLE_OFFSET + 46] := 1;
  Result[SAMPLE_OFFSET + 47] := $80 or 16;
  PutCardinal(Result, SAMPLE_OFFSET + 48, 4);
  PutCardinal(Result, SAMPLE_OFFSET + 52, 1);
  PutCardinal(Result, SAMPLE_OFFSET + 56, 3);
  PutCardinal(Result, SAMPLE_OFFSET + 60, 16726);
  PutCardinal(Result, SAMPLE_OFFSET + 72, DATA_OFFSET);

  // The sample data: 256, -256, 32767, -32768
  PutWord(Result, DATA_OFFSET, $0100);
  PutWord(Result, DATA_OFFSET + 2, $FF00);
  PutWord(Result, DATA_OFFSET + 4, $7FFF);
  PutWord(Result, DATA_OFFSET + 6, $8000);

  // The pattern of three rows (15 bytes)
  PutWord(Result, PATTERN_OFFSET, 15);
  PutWord(Result, PATTERN_OFFSET + 2, 3);
  LBase := PATTERN_OFFSET + 8;
  // Row 0, channel 0: new mask 0F (note, instrument, volume, command)
  Result[LBase] := $81;
  Result[LBase + 1] := $0F;
  Result[LBase + 2] := 60;
  Result[LBase + 3] := 1;
  Result[LBase + 4] := 64;
  Result[LBase + 5] := 1;
  Result[LBase + 6] := 6;
  // Row 0, channel 1: note off (255)
  Result[LBase + 7] := $82;
  Result[LBase + 8] := $01;
  Result[LBase + 9] := 255;
  Result[LBase + 10] := 0;
  // Row 1, channel 0: mask F0, all the values of the last time
  Result[LBase + 11] := $81;
  Result[LBase + 12] := $F0;
  Result[LBase + 13] := 0;
  // Row 2: empty
  Result[LBase + 14] := 0;
end;

procedure TTestTrackerItLoader.TestRiconoscePerLaFirma;
begin
  Assert.IsTrue(TTrackerItLoader.Detect(BuildIt));
  Assert.IsFalse(TTrackerItLoader.Detect(nil));
  Assert.IsFalse(TTrackerItLoader.Detect(TBytes.Create(1, 2, 3)));
end;

procedure TTestTrackerItLoader.TestVersioneVecchiaSollevaEccezione;
begin
  FBytes := BuildIt;
  PutWord(FBytes, 42, $0100);

  Assert.WillRaise(
    procedure
    begin
      TTrackerItLoader.Load(FBytes);
    end, ETrackerException);
end;

procedure TTestTrackerItLoader.TestFileTroncatoSollevaEccezione;
begin
  FBytes := BuildIt;
  SetLength(FBytes, 200);

  Assert.WillRaise(
    procedure
    begin
      TTrackerItLoader.Load(FBytes);
    end, ETrackerException);
end;

procedure TTestTrackerItLoader.TestIntestazione;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  Assert.AreEqual('IT TEST', FModule.Title);
  Assert.IsTrue(FModule.Format = tfIt);
  Assert.AreEqual(2, FModule.Channels);
  Assert.AreEqual(5, FModule.InitialSpeed);
  Assert.AreEqual(150, FModule.InitialTempo);
  Assert.AreEqual(128, FModule.GlobalVolume);
  Assert.IsTrue(FModule.LinearSlides);
  Assert.AreEqual(2, Length(FModule.Orders));
  Assert.AreEqual(255, Integer(FModule.Orders[1]));
  Assert.AreEqual(1, FModule.Patterns.Count);
  Assert.AreEqual(3, FModule.Patterns[0].Rows);
end;

procedure TTestTrackerItLoader.TestPannelloDeiCanali;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  Assert.AreEqual(64, Integer(FModule.ChannelPanning[0]));
  Assert.AreEqual(128, Integer(FModule.ChannelPanning[1]));
end;

procedure TTestTrackerItLoader.TestCampioneSedicibitConSegno;
var
  LSample: TTrackerSample;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  LSample := FModule.Samples[0];
  Assert.AreEqual('SMP 1', LSample.Name);
  Assert.AreEqual(4, LSample.Length);
  Assert.AreEqual(256, Integer(LSample.Data[0]));
  Assert.AreEqual(-256, Integer(LSample.Data[1]));
  Assert.AreEqual(32767, Integer(LSample.Data[2]));
  Assert.AreEqual(-32768, Integer(LSample.Data[3]));
  Assert.AreEqual(40, Integer(LSample.Volume));
  // The C5 speed is for C-5: the center frequency at C-4 is half
  Assert.AreEqual(8363, LSample.CenterFrequency);
end;

procedure TTestTrackerItLoader.TestRipetizioneEPannelloDelCampione;
var
  LSample: TTrackerSample;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  LSample := FModule.Samples[0];
  Assert.IsTrue(LSample.LoopType = tlForward);
  Assert.AreEqual(1, LSample.LoopStart);
  Assert.AreEqual(3, LSample.LoopEnd);
  Assert.AreEqual(64, Integer(LSample.Panning));
end;

procedure TTestTrackerItLoader.TestCampioneOttoBitSenzaSegno;
begin
  FBytes := BuildIt;
  // 8 bit, with loop, unsigned
  FBytes[SAMPLE_OFFSET + 18] := 1 or 16;
  FBytes[SAMPLE_OFFSET + 46] := 0;
  FBytes[DATA_OFFSET] := 0;
  FBytes[DATA_OFFSET + 1] := 128;
  FBytes[DATA_OFFSET + 2] := 255;
  FBytes[DATA_OFFSET + 3] := 64;

  FModule := TTrackerItLoader.Load(FBytes);

  Assert.AreEqual(-128 * 256, Integer(FModule.Samples[0].Data[0]));
  Assert.AreEqual(0, Integer(FModule.Samples[0].Data[1]));
  Assert.AreEqual(127 * 256, Integer(FModule.Samples[0].Data[2]));
  Assert.AreEqual(-64 * 256, Integer(FModule.Samples[0].Data[3]));
end;

procedure TTestTrackerItLoader.TestCampioneOttoBitConDelta;
begin
  FBytes := BuildIt;
  // 8 bit, signed and delta coded
  FBytes[SAMPLE_OFFSET + 18] := 1 or 16;
  FBytes[SAMPLE_OFFSET + 46] := 1 or 4;
  FBytes[DATA_OFFSET] := 10;
  FBytes[DATA_OFFSET + 1] := 10;
  FBytes[DATA_OFFSET + 2] := 246;
  FBytes[DATA_OFFSET + 3] := 236;

  FModule := TTrackerItLoader.Load(FBytes);

  Assert.AreEqual(10 * 256, Integer(FModule.Samples[0].Data[0]));
  Assert.AreEqual(20 * 256, Integer(FModule.Samples[0].Data[1]));
  Assert.AreEqual(10 * 256, Integer(FModule.Samples[0].Data[2]));
  Assert.AreEqual(-10 * 256, Integer(FModule.Samples[0].Data[3]));
end;

procedure TTestTrackerItLoader.TestStrumento;
var
  LInstrument: TTrackerInstrument;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  LInstrument := FModule.Instruments[0];
  Assert.AreEqual('INSTRUMENT 1', LInstrument.Name);
  Assert.IsTrue(LInstrument.NewNoteAction = nnaOff);
  Assert.AreEqual(1, Integer(LInstrument.DuplicateCheckType));
  Assert.AreEqual(2, Integer(LInstrument.DuplicateCheckAction));
  Assert.AreEqual(256, Integer(LInstrument.FadeOut));
  Assert.AreEqual(-8, Integer(LInstrument.PitchPanSeparation));
  Assert.AreEqual(60, Integer(LInstrument.PitchPanCenter));
  Assert.AreEqual(100, Integer(LInstrument.GlobalVolume));
  Assert.AreEqual(128, Integer(LInstrument.DefaultPanning));
end;

procedure TTestTrackerItLoader.TestMappeDelleNote;
var
  LInstrument: TTrackerInstrument;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  LInstrument := FModule.Instruments[0];
  // Only the sample 1 is used, and it is the sample of the module
  Assert.AreEqual(1, LInstrument.Samples.Count);
  Assert.AreSame(FModule.Samples[0], LInstrument.Samples[0]);
  Assert.AreEqual(0, Integer(LInstrument.SampleMap[0]));
  // The notes 0 and 1 are played as 12 and 13 (the model numbers from 1)
  Assert.AreEqual(13, Integer(LInstrument.NoteMap[0]));
  Assert.AreEqual(14, Integer(LInstrument.NoteMap[1]));
  Assert.AreEqual(3, Integer(LInstrument.NoteMap[2]));
end;

procedure TTestTrackerItLoader.TestInviluppi;
var
  LVolume, LPanning: TTrackerEnvelope;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  LVolume := FModule.Instruments[0].VolumeEnvelope;
  Assert.IsTrue(LVolume.Enabled);
  Assert.IsTrue(LVolume.Loop);
  Assert.IsFalse(LVolume.Sustain);
  Assert.AreEqual(2, Length(LVolume.Points));
  Assert.AreEqual(64, Integer(LVolume.Points[0].Value));
  Assert.AreEqual(0, Integer(LVolume.Points[0].Tick));
  Assert.AreEqual(32, Integer(LVolume.Points[1].Value));
  Assert.AreEqual(20, Integer(LVolume.Points[1].Tick));
  Assert.AreEqual(1, Integer(LVolume.LoopEnd));

  // The signed values -32 and +32 become 0 and 64
  LPanning := FModule.Instruments[0].PanningEnvelope;
  Assert.IsTrue(LPanning.Enabled);
  Assert.AreEqual(0, Integer(LPanning.Points[0].Value));
  Assert.AreEqual(64, Integer(LPanning.Points[1].Value));
  Assert.AreEqual(10, Integer(LPanning.Points[1].Tick));
  Assert.IsFalse(FModule.Instruments[0].PitchEnvelope.Enabled);
end;

procedure TTestTrackerItLoader.TestCellaConTuttiICampi;
var
  LCell: TTrackerCell;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  LCell := FModule.Patterns[0].Cells[0, 0];
  Assert.AreEqual(61, Integer(LCell.Note));
  Assert.AreEqual(1, Integer(LCell.Instrument));
  Assert.AreEqual(64, Integer(LCell.Volume));
  Assert.AreEqual(1, Integer(LCell.Effect));
  Assert.AreEqual(6, Integer(LCell.Param));
end;

procedure TTestTrackerItLoader.TestNotaOffEMaschera;
var
  LCell: TTrackerCell;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  LCell := FModule.Patterns[0].Cells[0, 1];
  Assert.AreEqual(Integer(TRACKER_NOTE_OFF), Integer(LCell.Note));
  Assert.AreEqual(0, Integer(LCell.Instrument));
  Assert.AreEqual(-1, Integer(LCell.Volume));
  Assert.AreEqual(0, Integer(LCell.Effect));
end;

procedure TTestTrackerItLoader.TestRipeteIValoriPrecedenti;
var
  LCell: TTrackerCell;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  LCell := FModule.Patterns[0].Cells[1, 0];
  Assert.AreEqual(61, Integer(LCell.Note));
  Assert.AreEqual(1, Integer(LCell.Instrument));
  Assert.AreEqual(64, Integer(LCell.Volume));
  Assert.AreEqual(1, Integer(LCell.Effect));
  Assert.AreEqual(6, Integer(LCell.Param));
end;

procedure TTestTrackerItLoader.TestRigaVuota;
var
  LCell: TTrackerCell;
begin
  FModule := TTrackerItLoader.Load(BuildIt);

  LCell := FModule.Patterns[0].Cells[2, 0];
  Assert.AreEqual(0, Integer(LCell.Note));
  Assert.AreEqual(-1, Integer(LCell.Volume));
end;

procedure TTestTrackerItLoader.TestSenzaStrumentiIDatiSonoICampioni;
begin
  FBytes := BuildIt;
  // Without the instruments flag the notes use the samples
  PutWord(FBytes, 44, 1 or 8);

  FModule := TTrackerItLoader.Load(FBytes);

  Assert.AreEqual(1, FModule.Instruments.Count);
  Assert.AreEqual('SMP 1', FModule.Instruments[0].Name);
  Assert.AreSame(FModule.Samples[0], FModule.Instruments[0].Samples[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerItLoader);

end.

