{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the demo buffer                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.DemoTape;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenDemoTape = class(TObject)
  public
    [Test]
    procedure DovrebbeRendereLaDimensionePari;
    [Test]
    procedure DovrebbeScrivereLaPrimaLetturaComeCoppia;
    [Test]
    procedure DovrebbeRipetereLaCoppiaFinoAlleStesseLetture;
    [Test]
    procedure DovrebbeFermareIlConteggioA254;
    [Test]
    procedure DovrebbeAvanzareDopoLaPrimaCoppia;
    [Test]
    procedure DovrebbeRifiutareUnBufferPieno;
    [Test]
    procedure DovrebbeDareLaLetturaUnaVoltaPiuDelConteggio;
    [Test]
    procedure DovrebbeFinireDopoLUltimaCoppia;
    [Test]
    procedure DovrebbeRifiutareUnaLetturaDopoLaFine;
    [Test]
    procedure DovrebbeLasciareIntattiIByteDelChiamante;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNulla;
    [Test]
    procedure DovrebbeRifiutareUnDemoPiuCortoDellaDimensione;
    [Test]
    procedure DovrebbeSuonareQuelloCheHaRegistratoUnaVoltaDiPiuPerCoppia;
  end;

implementation

uses
  DelphiDoom.Keen.DemoTape;

{ TTestKeenDemoTape }

procedure TTestKeenDemoTape.DovrebbeRendereLaDimensionePari;
var
  LTape: TKeenDemoTape;
begin
  LTape := TKeenDemoTape.CreateForRecording(7);
  try
    Assert.AreEqual(6, LTape.Size);
  finally
    LTape.Free;
  end;
end;

procedure TTestKeenDemoTape.DovrebbeScrivereLaPrimaLetturaComeCoppia;
var
  LTape: TKeenDemoTape;
begin
  LTape := TKeenDemoTape.CreateForRecording(8);
  try
    Assert.AreEqual(0, Length(LTape.RecordedBytes));
    LTape.RecordReading($15);
    Assert.AreEqual(TBytes(TBytes.Create(1, $15)), TBytes(LTape.RecordedBytes));
  finally
    LTape.Free;
  end;
end;

procedure TTestKeenDemoTape.DovrebbeRipetereLaCoppiaFinoAlleStesseLetture;
var
  LTape: TKeenDemoTape;
begin
  LTape := TKeenDemoTape.CreateForRecording(8);
  try
    // the C stayed at the offset 0 and wrote the first pair again for every reading
    LTape.RecordReading($15);
    LTape.RecordReading($15);
    LTape.RecordReading($15);
    Assert.AreEqual(TBytes(TBytes.Create(3, $15)), TBytes(LTape.RecordedBytes));
  finally
    LTape.Free;
  end;
end;

procedure TTestKeenDemoTape.DovrebbeFermareIlConteggioA254;
var
  LTape: TKeenDemoTape;
  LIndex: Integer;
begin
  LTape := TKeenDemoTape.CreateForRecording(8);
  try
    for LIndex := 1 to 256 do
      LTape.RecordReading($21);
    Assert.AreEqual(TBytes(TBytes.Create(254, $21, 2, $21)), TBytes(LTape.RecordedBytes));
  finally
    LTape.Free;
  end;
end;

procedure TTestKeenDemoTape.DovrebbeAvanzareDopoLaPrimaCoppia;
var
  LTape: TKeenDemoTape;
begin
  LTape := TKeenDemoTape.CreateForRecording(16);
  try
    LTape.RecordReading($15);
    LTape.RecordReading($16);
    LTape.RecordReading($16);
    LTape.RecordReading($15);
    Assert.AreEqual(TBytes(TBytes.Create(1, $15, 2, $16, 1, $15)), TBytes(LTape.RecordedBytes));
  finally
    LTape.Free;
  end;
end;

procedure TTestKeenDemoTape.DovrebbeRifiutareUnBufferPieno;
var
  LTape: TKeenDemoTape;
begin
  LTape := TKeenDemoTape.CreateForRecording(4);
  try
    LTape.RecordReading(1);
    LTape.RecordReading(2);
    Assert.WillRaise(
      procedure
      begin
        LTape.RecordReading(3);
      end, EKeenException);
  finally
    LTape.Free;
  end;
end;

procedure TTestKeenDemoTape.DovrebbeDareLaLetturaUnaVoltaPiuDelConteggio;
var
  LTape: TKeenDemoTape;
  LIndex: Integer;
begin
  // a pair (count 2, byte $15): the C gives the byte for the count and one more, 3 times
  LTape := TKeenDemoTape.CreateForPlayback(TBytes.Create(2, $15, 0, $2A), 4);
  try
    for LIndex := 1 to 3 do
    begin
      Assert.AreEqual($15, Integer(LTape.PlayReading));
      Assert.IsFalse(LTape.Finished);
    end;
    Assert.AreEqual($2A, Integer(LTape.PlayReading));
    Assert.IsTrue(LTape.Finished);
  finally
    LTape.Free;
  end;
end;

procedure TTestKeenDemoTape.DovrebbeFinireDopoLUltimaCoppia;
var
  LTape: TKeenDemoTape;
begin
  LTape := TKeenDemoTape.CreateForPlayback(TBytes.Create(0, $11), 2);
  try
    Assert.AreEqual($11, Integer(LTape.PlayReading));
    Assert.IsTrue(LTape.Finished);
    Assert.AreEqual(2, LTape.Offset);
  finally
    LTape.Free;
  end;
end;

procedure TTestKeenDemoTape.DovrebbeRifiutareUnaLetturaDopoLaFine;
var
  LTape: TKeenDemoTape;
begin
  LTape := TKeenDemoTape.CreateForPlayback(TBytes.Create(0, $11), 2);
  try
    LTape.PlayReading;
    Assert.WillRaise(
      procedure
      begin
        LTape.PlayReading;
      end, EKeenException);
  finally
    LTape.Free;
  end;
end;

procedure TTestKeenDemoTape.DovrebbeLasciareIntattiIByteDelChiamante;
var
  LBytes: TBytes;
  LTape: TKeenDemoTape;
begin
  LBytes := TBytes.Create(2, $15);
  LTape := TKeenDemoTape.CreateForPlayback(LBytes, 2);
  try
    LTape.PlayReading;
    LTape.PlayReading;
    // the C counted the pair down in the buffer of the caller
    Assert.AreEqual(2, Integer(LBytes[0]));
  finally
    LTape.Free;
  end;
end;

procedure TTestKeenDemoTape.DovrebbeRifiutareUnaDimensioneNulla;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenDemoTape.CreateForRecording(0);
    end, EKeenException);
end;

procedure TTestKeenDemoTape.DovrebbeRifiutareUnDemoPiuCortoDellaDimensione;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenDemoTape.CreateForPlayback(TBytes.Create(1, 2), 8);
    end, EKeenException);
  Assert.WillRaise(
    procedure
    begin
      TKeenDemoTape.CreateForPlayback(TBytes.Create(1), 1);
    end, EKeenException);
end;

procedure TTestKeenDemoTape.DovrebbeSuonareQuelloCheHaRegistratoUnaVoltaDiPiuPerCoppia;
var
  LRecorder: TKeenDemoTape;
  LPlayer: TKeenDemoTape;
  LPlayed: Integer;
begin
  // the defect that the C has and the port keeps: the pair says how many readings were recorded and the playback
  // gives one more for each
  LRecorder := TKeenDemoTape.CreateForRecording(8);
  try
    LRecorder.RecordReading($15);
    LRecorder.RecordReading($15);
    LPlayer := TKeenDemoTape.CreateForPlayback(LRecorder.RecordedBytes, 2);
    try
      LPlayed := 0;
      while not LPlayer.Finished do
      begin
        LPlayer.PlayReading;
        Inc(LPlayed);
      end;
      Assert.AreEqual(3, LPlayed);
    finally
      LPlayer.Free;
    end;
  finally
    LRecorder.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenDemoTape);

end.
