{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the XM loader of the tracker                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.Loader.Xm;

interface

uses
  System.Math,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tracker.Loader.Xm,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerXmLoader = class(TObject)
  private
    FModule: TTrackerModule;
    FBytes: TBytes;
    // A module of 2 channels, 4 rows, one pattern and one instrument with an
    // 8 bit sample of 4 bytes
    function BuildXm: TBytes;
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
    procedure TestOrdini;
    [Test]
    procedure TestCellaImpacchettata;
    [Test]
    procedure TestCellaNonImpacchettataConKeyOff;
    [Test]
    procedure TestCelleVuote;
    [Test]
    procedure TestStrumento;
    [Test]
    procedure TestInviluppoDelVolume;
    [Test]
    procedure TestCampioneDecodificatoDaDelta;
    [Test]
    procedure TestFrequenzaConNotaRelativaEFinetune;
    [Test]
    procedure TestRipetizionePannelloEVolume;
    [Test]
    procedure TestIlModuloPossiedeICampioni;
  end;

implementation

const
  PATTERN_OFFSET = 60 + 276;
  PACKED_SIZE = 17;
  INSTRUMENT_OFFSET = PATTERN_OFFSET + 9 + PACKED_SIZE;
  INSTRUMENT_HEADER = 263;
  SAMPLE_HEADER_OFFSET = INSTRUMENT_OFFSET + INSTRUMENT_HEADER;
  SAMPLE_DATA_OFFSET = SAMPLE_HEADER_OFFSET + 40;

{ TTestTrackerXmLoader }

procedure TTestTrackerXmLoader.TearDown;
begin
  FreeAndNil(FModule);
end;

procedure TTestTrackerXmLoader.PutWord(var ABytes: TBytes; const AOffset, AValue: Integer);
begin
  ABytes[AOffset] := Byte(AValue);
  ABytes[AOffset + 1] := Byte(AValue shr 8);
end;

procedure TTestTrackerXmLoader.PutCardinal(var ABytes: TBytes; const AOffset: Integer;
  const AValue: Cardinal);
begin
  PutWord(ABytes, AOffset, Integer(AValue and $FFFF));
  PutWord(ABytes, AOffset + 2, Integer(AValue shr 16));
end;

procedure TTestTrackerXmLoader.PutText(var ABytes: TBytes; const AOffset: Integer;
  const AText: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    ABytes[AOffset + LIndex - 1] := Ord(AText[LIndex]);
end;

function TTestTrackerXmLoader.BuildXm: TBytes;
var
  LBase, LCell: Integer;
begin
  SetLength(Result, SAMPLE_DATA_OFFSET + 4);
  PutText(Result, 0, 'Extended Module: ');
  PutText(Result, 17, 'XM TEST');
  Result[37] := $1A;
  PutText(Result, 38, 'TestTracker');
  PutWord(Result, 58, $0104);
  PutCardinal(Result, 60, 276);
  PutWord(Result, 64, 2);       // song length
  PutWord(Result, 66, 1);       // restart
  PutWord(Result, 68, 2);       // channels
  PutWord(Result, 70, 1);       // patterns
  PutWord(Result, 72, 1);       // instruments
  PutWord(Result, 74, 1);       // flags: linear
  PutWord(Result, 76, 4);       // speed
  PutWord(Result, 78, 130);     // tempo
  Result[80] := 0;
  Result[81] := 0;

  // The pattern
  PutCardinal(Result, PATTERN_OFFSET, 9);
  Result[PATTERN_OFFSET + 4] := 0;
  PutWord(Result, PATTERN_OFFSET + 5, 4);
  PutWord(Result, PATTERN_OFFSET + 7, PACKED_SIZE);
  LCell := PATTERN_OFFSET + 9;
  // Row 0, channel 0: packed, with the five fields
  Result[LCell] := $9F;
  Result[LCell + 1] := 49;
  Result[LCell + 2] := 1;
  Result[LCell + 3] := $50;
  Result[LCell + 4] := $0F;
  Result[LCell + 5] := 3;
  // Row 0, channel 1: not packed, key off
  Result[LCell + 6] := 97;
  // (instrument, volume, effect and parameter are zero)
  // The other cells are packed and empty
  for LBase := LCell + 11 to LCell + PACKED_SIZE - 1 do
    Result[LBase] := $80;

  // The instrument
  PutCardinal(Result, INSTRUMENT_OFFSET, INSTRUMENT_HEADER);
  PutText(Result, INSTRUMENT_OFFSET + 4, 'INST1');
  PutWord(Result, INSTRUMENT_OFFSET + 27, 1);
  PutCardinal(Result, INSTRUMENT_OFFSET + 29, 40);
  // The volume envelope: (0, 64) and (10, 32)
  PutWord(Result, INSTRUMENT_OFFSET + 129, 0);
  PutWord(Result, INSTRUMENT_OFFSET + 131, 64);
  PutWord(Result, INSTRUMENT_OFFSET + 133, 10);
  PutWord(Result, INSTRUMENT_OFFSET + 135, 32);
  Result[INSTRUMENT_OFFSET + 225] := 2;   // volume points
  Result[INSTRUMENT_OFFSET + 226] := 0;   // panning points
  Result[INSTRUMENT_OFFSET + 227] := 1;   // volume sustain
  Result[INSTRUMENT_OFFSET + 228] := 0;   // volume loop start
  Result[INSTRUMENT_OFFSET + 229] := 1;   // volume loop end
  Result[INSTRUMENT_OFFSET + 233] := 3;   // volume envelope: on and sustain
  PutWord(Result, INSTRUMENT_OFFSET + 239, 512);

  // The sample header
  PutCardinal(Result, SAMPLE_HEADER_OFFSET, 4);          // length
  PutCardinal(Result, SAMPLE_HEADER_OFFSET + 4, 1);      // loop start
  PutCardinal(Result, SAMPLE_HEADER_OFFSET + 8, 2);      // loop length
  Result[SAMPLE_HEADER_OFFSET + 12] := 50;               // volume
  Result[SAMPLE_HEADER_OFFSET + 13] := $F0;              // finetune -16
  Result[SAMPLE_HEADER_OFFSET + 14] := 1;                // forward loop, 8 bit
  Result[SAMPLE_HEADER_OFFSET + 15] := 100;              // panning
  Result[SAMPLE_HEADER_OFFSET + 16] := 12;               // relative note
  PutText(Result, SAMPLE_HEADER_OFFSET + 18, 'SAMP');

  // The sample data, delta coded: 10, 20, 10, -10
  Result[SAMPLE_DATA_OFFSET] := 10;
  Result[SAMPLE_DATA_OFFSET + 1] := 10;
  Result[SAMPLE_DATA_OFFSET + 2] := 246;
  Result[SAMPLE_DATA_OFFSET + 3] := 236;
end;

procedure TTestTrackerXmLoader.TestRiconoscePerLaFirma;
begin
  Assert.IsTrue(TTrackerXmLoader.Detect(BuildXm));
  Assert.IsFalse(TTrackerXmLoader.Detect(nil));
  Assert.IsFalse(TTrackerXmLoader.Detect(TBytes.Create(1, 2, 3)));
end;

procedure TTestTrackerXmLoader.TestVersioneVecchiaSollevaEccezione;
begin
  FBytes := BuildXm;
  PutWord(FBytes, 58, $0103);

  Assert.WillRaise(
    procedure
    begin
      TTrackerXmLoader.Load(FBytes);
    end, ETrackerException);
end;

procedure TTestTrackerXmLoader.TestFileTroncatoSollevaEccezione;
begin
  FBytes := BuildXm;
  SetLength(FBytes, 200);

  Assert.WillRaise(
    procedure
    begin
      TTrackerXmLoader.Load(FBytes);
    end, ETrackerException);
end;

procedure TTestTrackerXmLoader.TestIntestazione;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  Assert.AreEqual('XM TEST', FModule.Title);
  Assert.IsTrue(FModule.Format = tfXm);
  Assert.AreEqual(2, FModule.Channels);
  Assert.AreEqual(4, FModule.InitialSpeed);
  Assert.AreEqual(130, FModule.InitialTempo);
  Assert.IsTrue(FModule.LinearSlides);
  Assert.AreEqual(1, FModule.Patterns.Count);
  Assert.AreEqual(4, FModule.Patterns[0].Rows);
  Assert.AreEqual(1, FModule.Instruments.Count);
end;

procedure TTestTrackerXmLoader.TestOrdini;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  Assert.AreEqual(2, Length(FModule.Orders));
  Assert.AreEqual(1, FModule.RestartPosition);
end;

procedure TTestTrackerXmLoader.TestCellaImpacchettata;
var
  LCell: TTrackerCell;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  LCell := FModule.Patterns[0].Cells[0, 0];
  Assert.AreEqual(49, Integer(LCell.Note));
  Assert.AreEqual(1, Integer(LCell.Instrument));
  Assert.AreEqual($50, Integer(LCell.Volume));
  Assert.AreEqual($0F, Integer(LCell.Effect));
  Assert.AreEqual(3, Integer(LCell.Param));
end;

procedure TTestTrackerXmLoader.TestCellaNonImpacchettataConKeyOff;
var
  LCell: TTrackerCell;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  LCell := FModule.Patterns[0].Cells[0, 1];
  Assert.AreEqual(Integer(TRACKER_NOTE_OFF), Integer(LCell.Note));
  Assert.AreEqual(-1, Integer(LCell.Volume));
  Assert.AreEqual(0, Integer(LCell.Effect));
end;

procedure TTestTrackerXmLoader.TestCelleVuote;
var
  LCell: TTrackerCell;
  LRow: Integer;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  for LRow := 1 to 3 do
  begin
    LCell := FModule.Patterns[0].Cells[LRow, 0];
    Assert.AreEqual(0, Integer(LCell.Note));
    Assert.AreEqual(-1, Integer(LCell.Volume));
    LCell := FModule.Patterns[0].Cells[LRow, 1];
    Assert.AreEqual(0, Integer(LCell.Note));
  end;
end;

procedure TTestTrackerXmLoader.TestStrumento;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  Assert.AreEqual('INST1', FModule.Instruments[0].Name);
  Assert.AreEqual(1, FModule.Instruments[0].Samples.Count);
  Assert.AreEqual(512, Integer(FModule.Instruments[0].FadeOut));
  Assert.AreEqual(0, Integer(FModule.Instruments[0].SampleMap[60]));
  Assert.AreEqual(0, Integer(FModule.Instruments[0].SampleMap[119]));
end;

procedure TTestTrackerXmLoader.TestInviluppoDelVolume;
var
  LEnvelope: TTrackerEnvelope;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  LEnvelope := FModule.Instruments[0].VolumeEnvelope;
  Assert.IsTrue(LEnvelope.Enabled);
  Assert.IsTrue(LEnvelope.Sustain);
  Assert.IsFalse(LEnvelope.Loop);
  Assert.AreEqual(2, Length(LEnvelope.Points));
  Assert.AreEqual(0, Integer(LEnvelope.Points[0].Tick));
  Assert.AreEqual(64, Integer(LEnvelope.Points[0].Value));
  Assert.AreEqual(10, Integer(LEnvelope.Points[1].Tick));
  Assert.AreEqual(32, Integer(LEnvelope.Points[1].Value));
  Assert.AreEqual(1, Integer(LEnvelope.SustainStart));
  Assert.IsFalse(FModule.Instruments[0].PanningEnvelope.Enabled);
end;

procedure TTestTrackerXmLoader.TestCampioneDecodificatoDaDelta;
var
  LSample: TTrackerSample;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  LSample := FModule.Instruments[0].Samples[0];
  Assert.AreEqual('SAMP', LSample.Name);
  Assert.AreEqual(4, LSample.Length);
  Assert.AreEqual(10 * 256, Integer(LSample.Data[0]));
  Assert.AreEqual(20 * 256, Integer(LSample.Data[1]));
  Assert.AreEqual(10 * 256, Integer(LSample.Data[2]));
  Assert.AreEqual(-10 * 256, Integer(LSample.Data[3]));
end;

procedure TTestTrackerXmLoader.TestFrequenzaConNotaRelativaEFinetune;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  // An octave up, less 16 of the 128 steps of a semitone
  Assert.AreEqual(Integer(Round(8363 * Power(2, (12 - 16 / 128) / 12))),
    FModule.Instruments[0].Samples[0].CenterFrequency);
end;

procedure TTestTrackerXmLoader.TestRipetizionePannelloEVolume;
var
  LSample: TTrackerSample;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  LSample := FModule.Instruments[0].Samples[0];
  Assert.IsTrue(LSample.LoopType = tlForward);
  Assert.AreEqual(1, LSample.LoopStart);
  Assert.AreEqual(3, LSample.LoopEnd);
  Assert.AreEqual(100, Integer(LSample.Panning));
  Assert.AreEqual(50, Integer(LSample.Volume));
end;

procedure TTestTrackerXmLoader.TestIlModuloPossiedeICampioni;
begin
  FModule := TTrackerXmLoader.Load(BuildXm);

  Assert.AreEqual(1, FModule.Samples.Count);
  Assert.AreSame(FModule.Samples[0], FModule.Instruments[0].Samples[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerXmLoader);

end.

