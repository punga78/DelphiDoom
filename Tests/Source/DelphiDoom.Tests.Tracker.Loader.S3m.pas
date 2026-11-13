{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the S3M loader of the tracker                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.Loader.S3m;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tracker.Loader.S3m,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerS3mLoader = class(TObject)
  private
    FModule: TTrackerModule;
    FBytes: TBytes;
    // A module with 2 channels (one left, one right), one instrument of
    // 4 unsigned bytes and one pattern
    function BuildS3m: TBytes;
    procedure PutWord(var ABytes: TBytes; const AOffset, AValue: Integer);
    procedure PutCardinal(var ABytes: TBytes; const AOffset: Integer; const AValue: Cardinal);
    procedure PutText(var ABytes: TBytes; const AOffset: Integer; const AText: string);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRiconoscePerLaFirma;
    [Test]
    procedure TestFirmaMancanteSollevaEccezione;
    [Test]
    procedure TestIntestazione;
    [Test]
    procedure TestOrdini;
    [Test]
    procedure TestStrumentoECampione;
    [Test]
    procedure TestCampioniSenzaSegno;
    [Test]
    procedure TestRipetizione;
    [Test]
    procedure TestCellaConTuttiICampi;
    [Test]
    procedure TestCelleVuote;
    [Test]
    procedure TestPannelloDeiCanali;
    [Test]
    procedure TestModuloMonoHaTuttiICanaliAlCentro;
    [Test]
    procedure TestFileTroncatoSollevaEccezione;
    [Test]
    procedure DovrebbeRifiutareUnModuloSenzaCanali;
    [Test]
    procedure DovrebbeLeggereLaTabellaDeiPannelli;
    [Test]
    procedure DovrebbeUsareLaFrequenzaPredefinitaSeManca;
    [Test]
    procedure DovrebbeLeggereLaNotaTagliata;
    [Test]
    procedure DovrebbeLeggereICampioniConSegno;
    [Test]
    procedure DovrebbeLeggereICampioniA16BitSenzaSegno;
    [Test]
    procedure DovrebbeLeggereICampioniA16BitConSegno;
    [Test]
    procedure DovrebbeLeggereIDueCanaliDiUnCampioneStereo;
    [Test]
    procedure DovrebbeFermareLaRipetizioneAllaFineDelCampione;
  end;

implementation

const
  INSTRUMENT_OFFSET = $80;
  PATTERN_OFFSET = $E0;
  SAMPLE_OFFSET = $140;

{ TTestTrackerS3mLoader }

procedure TTestTrackerS3mLoader.TearDown;
begin
  FreeAndNil(FModule);
end;

procedure TTestTrackerS3mLoader.PutWord(var ABytes: TBytes; const AOffset, AValue: Integer);
begin
  ABytes[AOffset] := Byte(AValue);
  ABytes[AOffset + 1] := Byte(AValue shr 8);
end;

procedure TTestTrackerS3mLoader.PutCardinal(var ABytes: TBytes; const AOffset: Integer;
  const AValue: Cardinal);
begin
  PutWord(ABytes, AOffset, Integer(AValue and $FFFF));
  PutWord(ABytes, AOffset + 2, Integer(AValue shr 16));
end;

procedure TTestTrackerS3mLoader.PutText(var ABytes: TBytes; const AOffset: Integer;
  const AText: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    ABytes[AOffset + LIndex - 1] := Ord(AText[LIndex]);
end;

function TTestTrackerS3mLoader.BuildS3m: TBytes;
var
  LIndex, LPatternBytes: Integer;
begin
  SetLength(Result, SAMPLE_OFFSET + 4);
  PutText(Result, 0, 'S3M TEST');
  Result[$1C] := $1A;
  Result[$1D] := 16;
  PutWord(Result, $20, 2);          // orders
  PutWord(Result, $22, 1);          // instruments
  PutWord(Result, $24, 1);          // patterns
  PutWord(Result, $26, 0);          // flags
  PutWord(Result, $28, $1320);      // tracker version
  PutWord(Result, $2A, 2);          // unsigned samples
  PutText(Result, $2C, 'SCRM');
  Result[$30] := 64;                // global volume
  Result[$31] := 3;                 // initial speed
  Result[$32] := 140;               // initial tempo
  Result[$33] := $B0;               // master volume, stereo
  Result[$35] := 0;                 // no panning table
  // Channel settings: 0 is left, 1 is right, the others are not used
  for LIndex := 0 to 31 do
    Result[$40 + LIndex] := 255;
  Result[$40] := 0;
  Result[$41] := 8;
  // Orders, instrument and pattern pointers (in paragraphs)
  Result[$60] := 0;
  Result[$61] := 255;
  PutWord(Result, $62, INSTRUMENT_OFFSET div 16);
  PutWord(Result, $64, PATTERN_OFFSET div 16);

  // The instrument
  Result[INSTRUMENT_OFFSET] := 1;
  PutText(Result, INSTRUMENT_OFFSET + 1, 'smp1.raw');
  Result[INSTRUMENT_OFFSET + $0D] := 0;
  PutWord(Result, INSTRUMENT_OFFSET + $0E, SAMPLE_OFFSET div 16);
  PutCardinal(Result, INSTRUMENT_OFFSET + $10, 4);   // length
  PutCardinal(Result, INSTRUMENT_OFFSET + $14, 1);   // loop start
  PutCardinal(Result, INSTRUMENT_OFFSET + $18, 3);   // loop end
  Result[INSTRUMENT_OFFSET + $1C] := 48;             // volume
  Result[INSTRUMENT_OFFSET + $1F] := 1;              // flags: loop
  PutCardinal(Result, INSTRUMENT_OFFSET + $20, 16726);
  PutText(Result, INSTRUMENT_OFFSET + $30, 'INS1');
  PutText(Result, INSTRUMENT_OFFSET + $4C, 'SCRS');

  // The pattern: a cell with everything on the channel 0 of the first row,
  // then the end of each row
  // 7 bytes for the row 0 and one for each of the other 63 rows
  LPatternBytes := 7 + 63;
  PutWord(Result, PATTERN_OFFSET, LPatternBytes + 2);
  Result[PATTERN_OFFSET + 2] := 32 or 64 or 128 or 0;   // channel 0: note+instr, volume, effect
  Result[PATTERN_OFFSET + 3] := $41;                    // octave 4, semitone 1
  Result[PATTERN_OFFSET + 4] := 1;                      // instrument
  Result[PATTERN_OFFSET + 5] := 30;                     // volume
  Result[PATTERN_OFFSET + 6] := 1;                      // effect A
  Result[PATTERN_OFFSET + 7] := 5;                      // parameter
  Result[PATTERN_OFFSET + 8] := 0;                      // end of the row 0
  // The rows 1..63 are empty (zero bytes already)

  // The sample data (unsigned)
  Result[SAMPLE_OFFSET] := 0;
  Result[SAMPLE_OFFSET + 1] := 128;
  Result[SAMPLE_OFFSET + 2] := 255;
  Result[SAMPLE_OFFSET + 3] := 64;
end;

procedure TTestTrackerS3mLoader.TestRiconoscePerLaFirma;
begin
  Assert.IsTrue(TTrackerS3mLoader.Detect(BuildS3m));
  Assert.IsFalse(TTrackerS3mLoader.Detect(nil));
  Assert.IsFalse(TTrackerS3mLoader.Detect(TBytes.Create(1, 2, 3)));
end;

procedure TTestTrackerS3mLoader.TestFirmaMancanteSollevaEccezione;
begin
  FBytes := BuildS3m;
  FBytes[$2C] := Ord('X');

  Assert.WillRaise(
    procedure
    begin
      TTrackerS3mLoader.Load(FBytes);
    end, ETrackerException);
end;

procedure TTestTrackerS3mLoader.TestIntestazione;
begin
  FModule := TTrackerS3mLoader.Load(BuildS3m);

  Assert.AreEqual('S3M TEST', FModule.Title);
  Assert.IsTrue(FModule.Format = tfS3m);
  Assert.AreEqual(2, FModule.Channels);
  Assert.AreEqual(3, FModule.InitialSpeed);
  Assert.AreEqual(140, FModule.InitialTempo);
  Assert.AreEqual(128, FModule.GlobalVolume);
  Assert.AreEqual(1, FModule.Instruments.Count);
  Assert.AreEqual(1, FModule.Patterns.Count);
  Assert.AreEqual(64, FModule.Patterns[0].Rows);
end;

procedure TTestTrackerS3mLoader.TestOrdini;
begin
  FModule := TTrackerS3mLoader.Load(BuildS3m);

  Assert.AreEqual<Integer>(2, Length(FModule.Orders));
  Assert.AreEqual(0, Integer(FModule.Orders[0]));
  Assert.AreEqual(255, Integer(FModule.Orders[1]));
end;

procedure TTestTrackerS3mLoader.TestStrumentoECampione;
var
  LSample: TTrackerSample;
begin
  FModule := TTrackerS3mLoader.Load(BuildS3m);

  Assert.AreEqual('INS1', FModule.Instruments[0].Name);
  LSample := FModule.Instruments[0].Samples[0];
  Assert.AreEqual(4, LSample.Length);
  Assert.AreEqual(48, Integer(LSample.Volume));
  // The C5 speed is for C-5: the center frequency at C-4 is half
  Assert.AreEqual(8363, LSample.CenterFrequency);
end;

procedure TTestTrackerS3mLoader.TestCampioniSenzaSegno;
var
  LSample: TTrackerSample;
begin
  FModule := TTrackerS3mLoader.Load(BuildS3m);

  LSample := FModule.Instruments[0].Samples[0];
  Assert.AreEqual(-128 * 256, Integer(LSample.Data[0]));
  Assert.AreEqual(0, Integer(LSample.Data[1]));
  Assert.AreEqual(127 * 256, Integer(LSample.Data[2]));
  Assert.AreEqual(-64 * 256, Integer(LSample.Data[3]));
end;

procedure TTestTrackerS3mLoader.TestRipetizione;
var
  LSample: TTrackerSample;
begin
  FModule := TTrackerS3mLoader.Load(BuildS3m);

  LSample := FModule.Instruments[0].Samples[0];
  Assert.IsTrue(LSample.LoopType = tlForward);
  Assert.AreEqual(1, LSample.LoopStart);
  Assert.AreEqual(3, LSample.LoopEnd);
end;

procedure TTestTrackerS3mLoader.TestCellaConTuttiICampi;
var
  LCell: TTrackerCell;
begin
  FModule := TTrackerS3mLoader.Load(BuildS3m);

  LCell := FModule.Patterns[0].Cells[0, 0];
  // Octave 4, semitone 1: 4 * 12 + 1 + 1
  Assert.AreEqual(50, Integer(LCell.Note));
  Assert.AreEqual(1, Integer(LCell.Instrument));
  Assert.AreEqual(30, Integer(LCell.Volume));
  Assert.AreEqual(1, Integer(LCell.Effect));
  Assert.AreEqual(5, Integer(LCell.Param));
end;

procedure TTestTrackerS3mLoader.TestCelleVuote;
var
  LCell: TTrackerCell;
begin
  FModule := TTrackerS3mLoader.Load(BuildS3m);

  LCell := FModule.Patterns[0].Cells[1, 0];
  Assert.AreEqual(0, Integer(LCell.Note));
  Assert.AreEqual(-1, Integer(LCell.Volume));
  LCell := FModule.Patterns[0].Cells[0, 1];
  Assert.AreEqual(0, Integer(LCell.Note));
  Assert.AreEqual(-1, Integer(LCell.Volume));
end;

procedure TTestTrackerS3mLoader.TestPannelloDeiCanali;
begin
  FModule := TTrackerS3mLoader.Load(BuildS3m);

  // Left (channels 0..7) and right (8..15) by default
  Assert.AreEqual(51, Integer(FModule.ChannelPanning[0]));
  Assert.AreEqual(204, Integer(FModule.ChannelPanning[1]));
end;

procedure TTestTrackerS3mLoader.TestModuloMonoHaTuttiICanaliAlCentro;
var
  LBytes: TBytes;
begin
  LBytes := BuildS3m;
  LBytes[$33] := $30;

  FModule := TTrackerS3mLoader.Load(LBytes);

  Assert.AreEqual(128, Integer(FModule.ChannelPanning[0]));
  Assert.AreEqual(128, Integer(FModule.ChannelPanning[1]));
end;

procedure TTestTrackerS3mLoader.TestFileTroncatoSollevaEccezione;
begin
  FBytes := BuildS3m;
  SetLength(FBytes, $50);

  Assert.WillRaise(
    procedure
    begin
      TTrackerS3mLoader.Load(FBytes);
    end, ETrackerException);
end;

procedure TTestTrackerS3mLoader.DovrebbeRifiutareUnModuloSenzaCanali;
begin
  FBytes := BuildS3m;
  FBytes[$40] := 255;
  FBytes[$41] := 255;

  Assert.WillRaise(
    procedure
    begin
      TTrackerS3mLoader.Load(FBytes).Free;
    end, ETrackerException);
end;

procedure TTestTrackerS3mLoader.DovrebbeLeggereLaTabellaDeiPannelli;
var
  LBytes: TBytes;
begin
  // The table follows the pointers: bit 5 says the low nibble is the panning (0..15)
  LBytes := BuildS3m;
  LBytes[$35] := 252;
  LBytes[$66] := $2F;
  LBytes[$67] := $20;

  FModule := TTrackerS3mLoader.Load(LBytes);

  Assert.AreEqual(255, Integer(FModule.ChannelPanning[0]));
  Assert.AreEqual(0, Integer(FModule.ChannelPanning[1]));
end;

procedure TTestTrackerS3mLoader.DovrebbeUsareLaFrequenzaPredefinitaSeManca;
var
  LBytes: TBytes;
begin
  LBytes := BuildS3m;
  PutCardinal(LBytes, INSTRUMENT_OFFSET + $20, 0);

  FModule := TTrackerS3mLoader.Load(LBytes);

  Assert.AreEqual(8363, FModule.Samples[0].CenterFrequency);
end;

procedure TTestTrackerS3mLoader.DovrebbeLeggereLaNotaTagliata;
var
  LBytes: TBytes;
begin
  LBytes := BuildS3m;
  LBytes[PATTERN_OFFSET + 3] := 254;

  FModule := TTrackerS3mLoader.Load(LBytes);

  Assert.AreEqual(Integer(TRACKER_NOTE_CUT), Integer(FModule.Patterns[0].Cells[0, 0].Note));
end;

procedure TTestTrackerS3mLoader.DovrebbeLeggereICampioniConSegno;
var
  LBytes: TBytes;
begin
  LBytes := BuildS3m;
  PutWord(LBytes, $2A, 1);

  FModule := TTrackerS3mLoader.Load(LBytes);

  // 0, 128, 255, 64 as signed bytes, scaled to 16 bit
  Assert.AreEqual(0, Integer(FModule.Samples[0].Data[0]));
  Assert.AreEqual(-128 * 256, Integer(FModule.Samples[0].Data[1]));
  Assert.AreEqual(-1 * 256, Integer(FModule.Samples[0].Data[2]));
  Assert.AreEqual(64 * 256, Integer(FModule.Samples[0].Data[3]));
end;

procedure TTestTrackerS3mLoader.DovrebbeLeggereICampioniA16BitSenzaSegno;
var
  LBytes: TBytes;
begin
  // Two samples of 16 bit (little endian): $8000 and $40FF, unsigned
  LBytes := BuildS3m;
  PutCardinal(LBytes, INSTRUMENT_OFFSET + $10, 2);
  LBytes[INSTRUMENT_OFFSET + $1F] := 4;

  FModule := TTrackerS3mLoader.Load(LBytes);

  Assert.AreEqual<Integer>(2, Length(FModule.Samples[0].Data));
  Assert.AreEqual(0, Integer(FModule.Samples[0].Data[0]));
  Assert.AreEqual($40FF - 32768, Integer(FModule.Samples[0].Data[1]));
end;

procedure TTestTrackerS3mLoader.DovrebbeLeggereICampioniA16BitConSegno;
var
  LBytes: TBytes;
begin
  LBytes := BuildS3m;
  PutWord(LBytes, $2A, 1);
  PutCardinal(LBytes, INSTRUMENT_OFFSET + $10, 2);
  LBytes[INSTRUMENT_OFFSET + $1F] := 4;

  FModule := TTrackerS3mLoader.Load(LBytes);

  Assert.AreEqual(-32768, Integer(FModule.Samples[0].Data[0]));
  Assert.AreEqual($40FF, Integer(FModule.Samples[0].Data[1]));
end;

procedure TTestTrackerS3mLoader.DovrebbeLeggereIDueCanaliDiUnCampioneStereo;
var
  LBytes: TBytes;
begin
  // A stereo sample of 2 frames has 4 bytes
  LBytes := BuildS3m;
  PutCardinal(LBytes, INSTRUMENT_OFFSET + $10, 2);
  LBytes[INSTRUMENT_OFFSET + $1F] := 2;

  FModule := TTrackerS3mLoader.Load(LBytes);

  Assert.AreEqual<Integer>(4, Length(FModule.Samples[0].Data));
end;

procedure TTestTrackerS3mLoader.DovrebbeFermareLaRipetizioneAllaFineDelCampione;
var
  LBytes: TBytes;
begin
  LBytes := BuildS3m;
  PutCardinal(LBytes, INSTRUMENT_OFFSET + $18, 10);

  FModule := TTrackerS3mLoader.Load(LBytes);

  Assert.AreEqual(1, FModule.Samples[0].LoopStart);
  Assert.AreEqual(4, FModule.Samples[0].LoopEnd);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerS3mLoader);

end.


