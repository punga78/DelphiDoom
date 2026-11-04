{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the MOD loader of the tracker                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.Loader.ProTracker;

interface

uses
  System.Math,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tracker.Loader.ProTracker,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerModLoader = class(TObject)
  private
    FModule: TTrackerModule;
    FBytes: TBytes;
    // A module of AChannels channels with AOrderCount orders and APatterns
    // patterns; the sample 1 has 8 bytes (0, 16, 32, ..., 112 as signed)
    function BuildMod(const ASignature: string; const AChannels, APatterns: Integer;
      const ASampleBytes: Integer = 8): TBytes;
    procedure SetByte(var ABytes: TBytes; const AOffset: Integer; const AValue: Integer);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('M.K.', 'M.K.,4')]
    [TestCase('M!K!', 'M!K!,4')]
    [TestCase('FLT4', 'FLT4,4')]
    [TestCase('6CHN', '6CHN,6')]
    [TestCase('8CHN', '8CHN,8')]
    [TestCase('OCTA', 'OCTA,8')]
    [TestCase('CD81', 'CD81,8')]
    [TestCase('1CHN', '1CHN,1')]
    [TestCase('16CH', '16CH,16')]
    [TestCase('32CH', '32CH,32')]
    [TestCase('Sconosciuta', 'ABCD,0')]
    [TestCase('Zero canali', '00CH,0')]
    procedure TestCanaliDellaFirma(const ASignature: string; AExpected: Integer);

    [Test]
    [TestCase('C-1', '856,37')]
    [TestCase('C-2', '428,49')]
    [TestCase('C-3', '214,61')]
    [TestCase('B-3', '113,72')]
    [TestCase('Nessuna', '0,0')]
    procedure TestNotaDelPeriodo(APeriod, AExpected: Integer);

    [Test]
    procedure TestRiconoscePerLaFirma;
    [Test]
    procedure TestFileTroppoCortoSollevaEccezione;
    [Test]
    procedure TestFirmaSconosciutaSollevaEccezione;
    [Test]
    procedure TestIntestazione;
    [Test]
    procedure TestOrdiniERipartenza;
    [Test]
    procedure TestPatternCelle;
    [Test]
    procedure TestCampione;
    [Test]
    procedure TestRipetizioneDelCampione;
    [Test]
    procedure TestPannelloAmiga;
    [Test]
    procedure TestPatternTroncatiSollevanoEccezione;
    [Test]
    procedure TestCampioniTroncatiRestanoInSilenzio;
  end;

implementation

const
  HEADER_SIZE = 1084;
  PATTERN_SIZE_4 = 64 * 4 * 4;

{ TTestTrackerModLoader }

procedure TTestTrackerModLoader.TearDown;
begin
  FreeAndNil(FModule);
end;

procedure TTestTrackerModLoader.SetByte(var ABytes: TBytes; const AOffset, AValue: Integer);
begin
  ABytes[AOffset] := Byte(AValue);
end;

function TTestTrackerModLoader.BuildMod(const ASignature: string; const AChannels,
  APatterns, ASampleBytes: Integer): TBytes;
var
  LIndex, LOffset: Integer;
begin
  SetLength(Result, HEADER_SIZE + APatterns * 64 * AChannels * 4 + ASampleBytes);
  // Title
  for LIndex := 1 to Length('TEST SONG') do
    Result[LIndex - 1] := Ord('TEST SONG'[LIndex]);
  // Sample 1: name, length (words), finetune, volume, loop start, loop length
  for LIndex := 1 to Length('SMP1') do
    Result[20 + LIndex - 1] := Ord('SMP1'[LIndex]);
  LOffset := 20 + 22;
  Result[LOffset] := 0;
  Result[LOffset + 1] := ASampleBytes div 2;
  Result[LOffset + 2] := 8;  // finetune -8
  Result[LOffset + 3] := 40; // volume
  Result[LOffset + 4] := 0;
  Result[LOffset + 5] := 1;  // loop start: 1 word
  Result[LOffset + 6] := 0;
  Result[LOffset + 7] := 2;  // loop length: 2 words
  // Song length, restart and orders
  Result[950] := 2;
  Result[951] := 0;
  Result[952] := 0;
  Result[953] := Byte(APatterns - 1);
  // Signature
  for LIndex := 1 to 4 do
    Result[1080 + LIndex - 1] := Ord(ASignature[LIndex]);
  // Sample data
  for LIndex := 0 to ASampleBytes - 1 do
    Result[HEADER_SIZE + APatterns * 64 * AChannels * 4 + LIndex] := Byte(LIndex * 16);
end;

procedure TTestTrackerModLoader.TestCanaliDellaFirma(const ASignature: string;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TTrackerModLoader.ChannelsOfSignature(ASignature));
end;

procedure TTestTrackerModLoader.TestNotaDelPeriodo(APeriod, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, Integer(TTrackerModLoader.NoteOfPeriod(APeriod)));
end;

procedure TTestTrackerModLoader.TestRiconoscePerLaFirma;
begin
  Assert.IsTrue(TTrackerModLoader.Detect(BuildMod('M.K.', 4, 2)));
  Assert.IsFalse(TTrackerModLoader.Detect(BuildMod('XXXX', 4, 2)));
  Assert.IsFalse(TTrackerModLoader.Detect(nil));
end;

procedure TTestTrackerModLoader.TestFileTroppoCortoSollevaEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TTrackerModLoader.Load(TBytes.Create(1, 2, 3));
    end, ETrackerException);
end;

procedure TTestTrackerModLoader.TestFirmaSconosciutaSollevaEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TTrackerModLoader.Load(BuildMod('XXXX', 4, 2));
    end, ETrackerException);
end;

procedure TTestTrackerModLoader.TestIntestazione;
begin
  FModule := TTrackerModLoader.Load(BuildMod('M.K.', 4, 2));

  Assert.AreEqual('TEST SONG', FModule.Title);
  Assert.IsTrue(FModule.Format = tfMod);
  Assert.AreEqual(4, FModule.Channels);
  Assert.AreEqual(6, FModule.InitialSpeed);
  Assert.AreEqual(125, FModule.InitialTempo);
  Assert.AreEqual(31, FModule.Instruments.Count);
  Assert.AreEqual(2, FModule.Patterns.Count);
  Assert.AreEqual(64, FModule.Patterns[0].Rows);
end;

procedure TTestTrackerModLoader.TestOrdiniERipartenza;
var
  LBytes: TBytes;
begin
  LBytes := BuildMod('M.K.', 4, 2);
  SetByte(LBytes, 951, 5);

  FModule := TTrackerModLoader.Load(LBytes);

  // Two orders; a restart past the end goes back to the start
  Assert.AreEqual(2, Length(FModule.Orders));
  Assert.AreEqual(0, Integer(FModule.Orders[0]));
  Assert.AreEqual(1, Integer(FModule.Orders[1]));
  Assert.AreEqual(0, FModule.RestartPosition);
end;

procedure TTestTrackerModLoader.TestPatternCelle;
var
  LBytes: TBytes;
  LCell: TTrackerCell;
  LOffset: Integer;
begin
  LBytes := BuildMod('M.K.', 4, 2);
  // Pattern 0, row 1, channel 2: period 428 (0x1AC), sample 0x12, effect C, param 0x20
  LOffset := HEADER_SIZE + (1 * 4 + 2) * 4;
  SetByte(LBytes, LOffset, $11);
  SetByte(LBytes, LOffset + 1, $AC);
  SetByte(LBytes, LOffset + 2, $2C);
  SetByte(LBytes, LOffset + 3, $20);

  FModule := TTrackerModLoader.Load(LBytes);

  LCell := FModule.Patterns[0].Cells[1, 2];
  Assert.AreEqual(49, Integer(LCell.Note));
  Assert.AreEqual($12, Integer(LCell.Instrument));
  Assert.AreEqual($C, Integer(LCell.Effect));
  Assert.AreEqual($20, Integer(LCell.Param));
  Assert.AreEqual(-1, Integer(LCell.Volume));
  // The cell next to it is empty
  LCell := FModule.Patterns[0].Cells[1, 3];
  Assert.AreEqual(0, Integer(LCell.Note));
  Assert.AreEqual(0, Integer(LCell.Instrument));
end;

procedure TTestTrackerModLoader.TestCampione;
var
  LSample: TTrackerSample;
begin
  FModule := TTrackerModLoader.Load(BuildMod('M.K.', 4, 2));

  LSample := FModule.Instruments[0].Samples[0];
  Assert.AreEqual('SMP1', FModule.Instruments[0].Name);
  Assert.AreEqual(8, LSample.Length);
  Assert.AreEqual(40, Integer(LSample.Volume));
  // The 8 bit values become 16 bit: 0, 16, ..., 112
  Assert.AreEqual(0, Integer(LSample.Data[0]));
  Assert.AreEqual(16 * 256, Integer(LSample.Data[1]));
  Assert.AreEqual(112 * 256, Integer(LSample.Data[7]));
  // The finetune is -8 eighths of a semitone: half a semitone lower
  Assert.AreEqual(Integer(Round(8363 * Power(2, -8 / 96))), LSample.CenterFrequency);
  Assert.AreEqual(8363, FModule.Instruments[1].Samples[0].CenterFrequency);
end;

procedure TTestTrackerModLoader.TestRipetizioneDelCampione;
var
  LSample: TTrackerSample;
begin
  FModule := TTrackerModLoader.Load(BuildMod('M.K.', 4, 2));

  LSample := FModule.Instruments[0].Samples[0];
  Assert.IsTrue(LSample.LoopType = tlForward);
  Assert.AreEqual(2, LSample.LoopStart);
  Assert.AreEqual(6, LSample.LoopEnd);
  // The sample 2 is empty and has no loop
  Assert.IsTrue(FModule.Instruments[1].Samples[0].LoopType = tlNone);
end;

procedure TTestTrackerModLoader.TestPannelloAmiga;
begin
  FModule := TTrackerModLoader.Load(BuildMod('8CHN', 8, 2));

  // Left, right, right, left, and again
  Assert.AreEqual(0, Integer(FModule.ChannelPanning[0]));
  Assert.AreEqual(255, Integer(FModule.ChannelPanning[1]));
  Assert.AreEqual(255, Integer(FModule.ChannelPanning[2]));
  Assert.AreEqual(0, Integer(FModule.ChannelPanning[3]));
  Assert.AreEqual(0, Integer(FModule.ChannelPanning[4]));
  Assert.AreEqual(255, Integer(FModule.ChannelPanning[5]));
end;

procedure TTestTrackerModLoader.TestPatternTroncatiSollevanoEccezione;
begin
  FBytes := BuildMod('M.K.', 4, 2);
  SetLength(FBytes, HEADER_SIZE + PATTERN_SIZE_4 + 100);

  Assert.WillRaise(
    procedure
    begin
      TTrackerModLoader.Load(FBytes);
    end, ETrackerException);
end;

procedure TTestTrackerModLoader.TestCampioniTroncatiRestanoInSilenzio;
var
  LBytes: TBytes;
  LSample: TTrackerSample;
begin
  LBytes := BuildMod('M.K.', 4, 2);
  // Only 4 of the 8 bytes of the sample are in the file
  SetLength(LBytes, Length(LBytes) - 4);

  FModule := TTrackerModLoader.Load(LBytes);

  LSample := FModule.Instruments[0].Samples[0];
  Assert.AreEqual(8, LSample.Length);
  Assert.AreEqual(48 * 256, Integer(LSample.Data[3]));
  Assert.AreEqual(0, Integer(LSample.Data[4]));
  Assert.AreEqual(0, Integer(LSample.Data[7]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerModLoader);

end.

