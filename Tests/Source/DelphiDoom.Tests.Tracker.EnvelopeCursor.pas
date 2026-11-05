{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the cursor along the envelope of an instrument         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.EnvelopeCursor;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Tracker.EnvelopeCursor,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerEnvelopeCursor = class(TObject)
  private
    FCursor: TTrackerEnvelopeCursor;
    function MakeEnvelope(const ATicks, AValues: array of Integer): TTrackerEnvelope;
    procedure AdvanceBy(const ATicks: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSenzaInviluppoVale64;
    [Test]
    procedure TestInviluppoDisabilitatoVale64;
    [Test]
    procedure TestInizioDaiPrimiPunti;
    [Test]
    procedure TestInterpolaTraDuePunti;
    [Test]
    procedure TestDopoUltimoPuntoRestaFermo;
    [Test]
    procedure TestSostegnoXmRestaSulPunto;
    [Test]
    procedure TestSostegnoXmSiLasciaConRilascio;
    [Test]
    procedure TestSostegnoItRipeteIlTratto;
    [Test]
    procedure TestCicloRipeteIlTratto;
    [Test]
    procedure TestIlCicloContinuaDopoIlRilascio;
    [Test]
    procedure TestRipartenzaConStart;
  end;

implementation

{ TTestTrackerEnvelopeCursor }

procedure TTestTrackerEnvelopeCursor.Setup;
begin
  FCursor := TTrackerEnvelopeCursor.Create;
end;

procedure TTestTrackerEnvelopeCursor.TearDown;
begin
  FCursor.Free;
end;

function TTestTrackerEnvelopeCursor.MakeEnvelope(const ATicks, AValues: array of Integer): TTrackerEnvelope;
var
  LIndex: Integer;
begin
  Result := Default(TTrackerEnvelope);
  Result.Enabled := True;
  SetLength(Result.Points, Length(ATicks));
  for LIndex := 0 to High(ATicks) do
  begin
    Result.Points[LIndex].Tick := ATicks[LIndex];
    Result.Points[LIndex].Value := AValues[LIndex];
  end;
end;

procedure TTestTrackerEnvelopeCursor.AdvanceBy(const ATicks: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ATicks do
    FCursor.Advance;
end;

procedure TTestTrackerEnvelopeCursor.TestSenzaInviluppoVale64;
begin
  Assert.IsFalse(FCursor.Active);
  Assert.AreEqual(64.0, FCursor.Value, 0.0001);
  FCursor.Advance;
  Assert.AreEqual(64.0, FCursor.Value, 0.0001);
end;

procedure TTestTrackerEnvelopeCursor.TestInviluppoDisabilitatoVale64;
var
  LEnvelope: TTrackerEnvelope;
begin
  LEnvelope := MakeEnvelope([0, 10], [0, 0]);
  LEnvelope.Enabled := False;

  FCursor.Start(LEnvelope);

  Assert.IsFalse(FCursor.Active);
  Assert.AreEqual(64.0, FCursor.Value, 0.0001);
end;

procedure TTestTrackerEnvelopeCursor.TestInizioDaiPrimiPunti;
begin
  FCursor.Start(MakeEnvelope([0, 10], [20, 40]));

  Assert.IsTrue(FCursor.Active);
  Assert.AreEqual(20.0, FCursor.Value, 0.0001);
end;

procedure TTestTrackerEnvelopeCursor.TestInterpolaTraDuePunti;
begin
  FCursor.Start(MakeEnvelope([0, 10, 30], [0, 40, 40]));

  AdvanceBy(5);
  Assert.AreEqual(20.0, FCursor.Value, 0.0001);
  AdvanceBy(5);
  Assert.AreEqual(40.0, FCursor.Value, 0.0001);
end;

procedure TTestTrackerEnvelopeCursor.TestDopoUltimoPuntoRestaFermo;
begin
  FCursor.Start(MakeEnvelope([0, 10], [64, 8]));

  AdvanceBy(500);

  Assert.AreEqual(8.0, FCursor.Value, 0.0001);
  Assert.AreEqual(10, FCursor.Position);
end;

procedure TTestTrackerEnvelopeCursor.TestSostegnoXmRestaSulPunto;
var
  LEnvelope: TTrackerEnvelope;
begin
  LEnvelope := MakeEnvelope([0, 10, 20], [64, 32, 0]);
  LEnvelope.Sustain := True;
  LEnvelope.SustainStart := 1;
  LEnvelope.SustainEnd := 1;
  FCursor.Start(LEnvelope);

  AdvanceBy(100);

  Assert.AreEqual(10, FCursor.Position);
  Assert.AreEqual(32.0, FCursor.Value, 0.0001);
end;

procedure TTestTrackerEnvelopeCursor.TestSostegnoXmSiLasciaConRilascio;
var
  LEnvelope: TTrackerEnvelope;
begin
  LEnvelope := MakeEnvelope([0, 10, 20], [64, 32, 0]);
  LEnvelope.Sustain := True;
  LEnvelope.SustainStart := 1;
  LEnvelope.SustainEnd := 1;
  FCursor.Start(LEnvelope);
  AdvanceBy(100);

  FCursor.Release;
  AdvanceBy(5);

  Assert.IsTrue(FCursor.Released);
  Assert.AreEqual(15, FCursor.Position);
  Assert.AreEqual(16.0, FCursor.Value, 0.0001);
end;

procedure TTestTrackerEnvelopeCursor.TestSostegnoItRipeteIlTratto;
var
  LEnvelope: TTrackerEnvelope;
begin
  LEnvelope := MakeEnvelope([0, 10, 20, 30], [0, 64, 0, 0]);
  LEnvelope.Sustain := True;
  LEnvelope.SustainStart := 1;
  LEnvelope.SustainEnd := 2;
  FCursor.Start(LEnvelope);

  // 10 ticks to the first point, then 10 up the second: back to the first
  AdvanceBy(20);
  Assert.AreEqual(10, FCursor.Position);
  AdvanceBy(7);
  Assert.AreEqual(17, FCursor.Position);
end;

procedure TTestTrackerEnvelopeCursor.TestCicloRipeteIlTratto;
var
  LEnvelope: TTrackerEnvelope;
begin
  LEnvelope := MakeEnvelope([0, 4, 8], [0, 64, 0]);
  LEnvelope.Loop := True;
  LEnvelope.LoopStart := 0;
  LEnvelope.LoopEnd := 2;
  FCursor.Start(LEnvelope);

  AdvanceBy(8);

  Assert.AreEqual(0, FCursor.Position);
  AdvanceBy(2);
  Assert.AreEqual(2, FCursor.Position);
end;

procedure TTestTrackerEnvelopeCursor.TestIlCicloContinuaDopoIlRilascio;
var
  LEnvelope: TTrackerEnvelope;
begin
  LEnvelope := MakeEnvelope([0, 4, 8], [0, 64, 0]);
  LEnvelope.Loop := True;
  LEnvelope.LoopStart := 1;
  LEnvelope.LoopEnd := 2;
  FCursor.Start(LEnvelope);
  FCursor.Release;

  AdvanceBy(8);

  Assert.AreEqual(4, FCursor.Position);
end;

procedure TTestTrackerEnvelopeCursor.TestRipartenzaConStart;
var
  LEnvelope: TTrackerEnvelope;
begin
  LEnvelope := MakeEnvelope([0, 10], [0, 64]);
  FCursor.Start(LEnvelope);
  AdvanceBy(10);
  FCursor.Release;

  FCursor.Start(LEnvelope);

  Assert.AreEqual(0, FCursor.Position);
  Assert.IsFalse(FCursor.Released);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerEnvelopeCursor);

end.
