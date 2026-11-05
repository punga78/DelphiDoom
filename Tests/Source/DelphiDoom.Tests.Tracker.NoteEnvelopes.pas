{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the envelopes and of the fade out of a note            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.NoteEnvelopes;

interface

uses
  System.Math,
  DUnitX.TestFramework,
  DelphiDoom.Tracker.NoteEnvelopes,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerNoteEnvelopes = class(TObject)
  private
    FInstrument: TTrackerInstrument;
    FEnvelopes: TTrackerNoteEnvelopes;
    function MakeEnvelope(const ATicks, AValues: array of Integer): TTrackerEnvelope;
    procedure CreateEnvelopes(const AFormat: TTrackerFormat);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSenzaInviluppiIlVolumeEPieno;
    [Test]
    procedure TestIlVolumeSegueLInviluppo;
    [Test]
    procedure TestDopoIlKeyOffSfuma;
    [Test]
    procedure TestIlKeyOffDiXmSenzaInviluppoTaglia;
    [Test]
    procedure TestIlKeyOffDiItSenzaInviluppoNonTaglia;
    [Test]
    procedure TestSfumaturaSenzaKeyOff;
    [Test]
    procedure TestFinisceQuandoLaSfumaturaArrivaAZero;
    [Test]
    procedure TestFinisceQuandoLInviluppoRilasciatoArrivaAZero;
    [Test]
    procedure TestSenzaInviluppoDelPitchIlFattoreEUno;
    [Test]
    procedure TestInviluppoDelPitchSaleDiSedicesemitoni;
    [Test]
    procedure TestPanningSenzaInviluppoRestaFermo;
    [Test]
    procedure TestPanningAlCentroConInviluppoAlMassimoVaADestra;
    [Test]
    procedure TestStartRiparteDaCapo;
  end;

implementation

{ TTestTrackerNoteEnvelopes }

procedure TTestTrackerNoteEnvelopes.Setup;
begin
  FInstrument := TTrackerInstrument.Create;
  FEnvelopes := nil;
end;

procedure TTestTrackerNoteEnvelopes.TearDown;
begin
  FEnvelopes.Free;
  FInstrument.Free;
end;

function TTestTrackerNoteEnvelopes.MakeEnvelope(const ATicks, AValues: array of Integer): TTrackerEnvelope;
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

procedure TTestTrackerNoteEnvelopes.CreateEnvelopes(const AFormat: TTrackerFormat);
begin
  FEnvelopes.Free;
  FEnvelopes := TTrackerNoteEnvelopes.Create(AFormat);
  FEnvelopes.Start(FInstrument);
end;

procedure TTestTrackerNoteEnvelopes.TestSenzaInviluppiIlVolumeEPieno;
begin
  CreateEnvelopes(tfXm);

  FEnvelopes.Advance;

  Assert.AreEqual(1.0, FEnvelopes.VolumeFactor, 0.0001);
  Assert.IsFalse(FEnvelopes.IsFinished);
end;

procedure TTestTrackerNoteEnvelopes.TestIlVolumeSegueLInviluppo;
begin
  FInstrument.VolumeEnvelope := MakeEnvelope([0, 10], [64, 0]);
  CreateEnvelopes(tfXm);

  FEnvelopes.Advance;
  FEnvelopes.Advance;

  Assert.AreEqual(0.8, FEnvelopes.VolumeFactor, 0.0001);
end;

procedure TTestTrackerNoteEnvelopes.TestDopoIlKeyOffSfuma;
begin
  FInstrument.VolumeEnvelope := MakeEnvelope([0, 100], [64, 64]);
  // 1024 * 2 of 65536 in each tick
  FInstrument.FadeOut := 1024;
  CreateEnvelopes(tfXm);

  FEnvelopes.Advance;
  Assert.AreEqual(1.0, FEnvelopes.VolumeFactor, 0.0001);
  FEnvelopes.KeyOff;
  FEnvelopes.Advance;
  FEnvelopes.Advance;

  Assert.IsTrue(FEnvelopes.KeyedOff);
  Assert.AreEqual((65536 - 2 * 2048) / 65536, FEnvelopes.VolumeFactor, 0.0001);
end;

procedure TTestTrackerNoteEnvelopes.TestIlKeyOffDiXmSenzaInviluppoTaglia;
begin
  CreateEnvelopes(tfXm);

  FEnvelopes.KeyOff;

  Assert.AreEqual(0.0, FEnvelopes.VolumeFactor, 0.0001);
  Assert.IsTrue(FEnvelopes.IsFinished);
end;

procedure TTestTrackerNoteEnvelopes.TestIlKeyOffDiItSenzaInviluppoNonTaglia;
begin
  CreateEnvelopes(tfIt);

  FEnvelopes.KeyOff;
  FEnvelopes.Advance;

  Assert.AreEqual(1.0, FEnvelopes.VolumeFactor, 0.0001);
  Assert.IsFalse(FEnvelopes.IsFinished);
end;

procedure TTestTrackerNoteEnvelopes.TestSfumaturaSenzaKeyOff;
begin
  // 16 * 64 of 65536 in each tick
  FInstrument.FadeOut := 16;
  CreateEnvelopes(tfIt);

  FEnvelopes.Advance;
  Assert.AreEqual(1.0, FEnvelopes.VolumeFactor, 0.0001);
  FEnvelopes.StartFade;
  FEnvelopes.Advance;
  FEnvelopes.Advance;

  Assert.IsFalse(FEnvelopes.KeyedOff);
  Assert.AreEqual((65536 - 2 * 1024) / 65536, FEnvelopes.VolumeFactor, 0.0001);
end;

procedure TTestTrackerNoteEnvelopes.TestFinisceQuandoLaSfumaturaArrivaAZero;
var
  LIndex: Integer;
begin
  // 128 * 64 = 8192 of 65536: eight ticks
  FInstrument.FadeOut := 128;
  CreateEnvelopes(tfIt);
  FEnvelopes.StartFade;

  for LIndex := 1 to 7 do
    FEnvelopes.Advance;
  Assert.IsFalse(FEnvelopes.IsFinished);
  FEnvelopes.Advance;

  Assert.IsTrue(FEnvelopes.IsFinished);
end;

procedure TTestTrackerNoteEnvelopes.TestFinisceQuandoLInviluppoRilasciatoArrivaAZero;
var
  LIndex: Integer;
begin
  FInstrument.VolumeEnvelope := MakeEnvelope([0, 4, 8], [64, 64, 0]);
  CreateEnvelopes(tfIt);
  FEnvelopes.KeyOff;

  for LIndex := 1 to 7 do
    FEnvelopes.Advance;
  Assert.IsFalse(FEnvelopes.IsFinished);
  FEnvelopes.Advance;

  Assert.IsTrue(FEnvelopes.IsFinished);
end;

procedure TTestTrackerNoteEnvelopes.TestSenzaInviluppoDelPitchIlFattoreEUno;
begin
  CreateEnvelopes(tfIt);

  Assert.AreEqual(1.0, FEnvelopes.PitchFactor, 0.0001);
end;

procedure TTestTrackerNoteEnvelopes.TestInviluppoDelPitchSaleDiSedicesemitoni;
begin
  // 64 is the top, 32 the middle: plus or minus 16 semitones
  FInstrument.PitchEnvelope := MakeEnvelope([0, 100], [64, 64]);
  CreateEnvelopes(tfIt);

  Assert.AreEqual(Power(2, 16 / 12), FEnvelopes.PitchFactor, 0.0001);
end;

procedure TTestTrackerNoteEnvelopes.TestPanningSenzaInviluppoRestaFermo;
begin
  CreateEnvelopes(tfXm);

  Assert.AreEqual(100.0, FEnvelopes.AdjustPanning(100), 0.0001);
end;

procedure TTestTrackerNoteEnvelopes.TestPanningAlCentroConInviluppoAlMassimoVaADestra;
begin
  FInstrument.PanningEnvelope := MakeEnvelope([0, 100], [64, 64]);
  CreateEnvelopes(tfXm);

  Assert.AreEqual(255.0, FEnvelopes.AdjustPanning(127.5), 0.01);
end;

procedure TTestTrackerNoteEnvelopes.TestStartRiparteDaCapo;
begin
  FInstrument.VolumeEnvelope := MakeEnvelope([0, 100], [64, 64]);
  FInstrument.FadeOut := 1024;
  CreateEnvelopes(tfXm);
  FEnvelopes.KeyOff;
  FEnvelopes.Advance;

  FEnvelopes.Start(FInstrument);

  Assert.IsFalse(FEnvelopes.KeyedOff);
  Assert.AreEqual(1.0, FEnvelopes.VolumeFactor, 0.0001);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerNoteEnvelopes);

end.
