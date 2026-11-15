{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - the MIDI synthesizer       }
{  (the tests that were written for TXcomMidiSynth before it moved here, and    }
{  the fingerprint of the old synthesizer on a fixed scenario)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.MidiSynth;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.AudioMix.Types, DelphiDoom.AudioMix.Intf,
  DelphiDoom.AudioMix.MidiSynth;

type
  [TestFixture]
  [Category('audiomix')]
  TTestPcmMidiSynth = class
  strict private
    FSynth: TPcmMidiSynth;
    FRef: IPcmMidiSynth;
    function Render(AFrames: Integer): TArray<SmallInt>;
    class function Rms(const ASamples: TArray<SmallInt>): Double; static;
    class function Crossings(const ASamples: TArray<SmallInt>): Integer; static;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure SenzaNoteSuonaSilenzio;
    [Test]
    procedure UnaNotaSuonaEPoiSiSpegneAlRilascio;
    [Test]
    procedure UnaNotaConVelocitaZeroEUnNoteOff;
    [Test]
    procedure UnaNotaPiuAltaOscillaPiuVelocemente;
    [Test]
    procedure IlVolumeDelCanaleScalaIlSuono;
    [Test]
    procedure IlPanoramaSpostaIlSuonoAlLatoGiusto;
    [Test]
    procedure IlPitchBendCambiaLaFrequenza;
    [Test]
    procedure TutteLeNoteSpenteTaceSubito;
    [Test]
    procedure TutteLeNoteRilasciateSiSpengonoDaSole;
    [Test]
    procedure LaBatteriaSuonaSulCanaleDieciESiSpegneDaSola;
    [Test]
    procedure OltreLeVociDisponibiliSiRubaLaPiuVecchia;
    [Test]
    procedure IlResetFaTacere;
    [Test]
    procedure IlRenderSommaAlBufferEdECompreso;
    [Test]
    procedure UnaRichiestaNonMultiplaDiQuattroDaEccezione;
    [Test]
    procedure UnRateNonValidoDaEccezione;
    [Test]
    procedure OgniFamigliaDiPatchProduceSuono;
    /// <summary>
    ///   The number is the one that TXcomMidiSynth gave (Win32 and Win64 differ in the last bit of the floating point
    ///   functions) on the same 600 steps before the synthesizer moved to this library
    /// </summary>
    [Test]
    procedure LaStessaPartituraDaLaStessaImprontaDelVecchioSintetizzatore;
  end;

implementation

uses
  DelphiDoom.Tests.AudioMix.MidiScenario;

const
  RATE = 22050;
  // produced with TXcomMidiSynth (Libs\XcomAudio) before the move, rate 22050
  GOLDEN_FINGERPRINT_WIN32 = UInt64($B524566670237905);
  GOLDEN_FINGERPRINT_WIN64 = UInt64($5A5874F856C00DFA);

procedure TTestPcmMidiSynth.Setup;
begin
  FSynth := TPcmMidiSynth.Create(RATE);
  FRef := FSynth;
end;

function TTestPcmMidiSynth.Render(AFrames: Integer): TArray<SmallInt>;
begin
  SetLength(Result, AFrames * 2);
  // the synthesizer adds to the buffer: it starts from silence
  FillChar(Result[0], AFrames * 4, 0);
  FRef.Render(@Result[0], AFrames * 4);
end;

class function TTestPcmMidiSynth.Rms(const ASamples: TArray<SmallInt>): Double;
var
  LIndex: Integer;
  LSum: Double;
begin
  LSum := 0;
  for LIndex := 0 to High(ASamples) do
    LSum := LSum + Double(ASamples[LIndex]) * ASamples[LIndex];
  if Length(ASamples) = 0 then
    Result := 0
  else
    Result := Sqrt(LSum / Length(ASamples));
end;

class function TTestPcmMidiSynth.Crossings(const ASamples: TArray<SmallInt>): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 1 to Length(ASamples) div 2 - 1 do
    if (ASamples[(LIndex - 1) * 2] < 0) <> (ASamples[LIndex * 2] < 0) then
      Inc(Result);
end;

procedure TTestPcmMidiSynth.SenzaNoteSuonaSilenzio;
begin
  Assert.AreEqual(0.0, Rms(Render(1000)), 1e-9);
  Assert.AreEqual(0, FSynth.ActiveVoices);
end;

procedure TTestPcmMidiSynth.UnaNotaSuonaEPoiSiSpegneAlRilascio;
begin
  FRef.Send($90, 60, 100);
  Assert.AreEqual(1, FSynth.ActiveVoices);
  Assert.IsTrue(Rms(Render(2000)) > 50);
  FRef.Send($80, 60, 0);
  // the release lasts 0.05 s or more: after half a second the voice is gone
  Render(RATE div 2);
  Assert.AreEqual(0, FSynth.ActiveVoices);
  Assert.AreEqual(0.0, Rms(Render(1000)), 1e-9);
end;

procedure TTestPcmMidiSynth.UnaNotaConVelocitaZeroEUnNoteOff;
begin
  FRef.Send($90, 60, 100);
  FRef.Send($90, 60, 0);
  Render(RATE div 2);
  Assert.AreEqual(0, FSynth.ActiveVoices);
end;

procedure TTestPcmMidiSynth.UnaNotaPiuAltaOscillaPiuVelocemente;
var
  LLow: TArray<SmallInt>;
  LHigh: TArray<SmallInt>;
begin
  // a triangle wave of the piano family: the crossings of zero follow the frequency (110 and 440 Hz)
  FRef.Send($90, 45, 100);
  LLow := Render(RATE);
  FRef.Send($B0, 120, 0);
  FRef.Send($90, 69, 100);
  LHigh := Render(RATE);
  Assert.IsTrue(Crossings(LHigh) > Crossings(LLow) * 3, Format('%d %d', [Crossings(LLow), Crossings(LHigh)]));
end;

procedure TTestPcmMidiSynth.IlVolumeDelCanaleScalaIlSuono;
var
  LFull: Double;
  LHalf: Double;
begin
  FRef.Send($90, 60, 100);
  LFull := Rms(Render(2000));
  FRef.Send($B0, 120, 0);
  FRef.Send($B0, 7, 50);
  FRef.Send($90, 60, 100);
  LHalf := Rms(Render(2000));
  Assert.IsTrue(LHalf < LFull * 0.7, Format('%f %f', [LFull, LHalf]));
  Assert.IsTrue(LHalf > 0);
  // the expression of the channel counts as well
  FRef.Send($B0, 120, 0);
  FRef.Send($B0, 7, 100);
  FRef.Send($B0, 11, 0);
  FRef.Send($90, 60, 100);
  Assert.AreEqual(0.0, Rms(Render(2000)), 1e-9);
end;

procedure TTestPcmMidiSynth.IlPanoramaSpostaIlSuonoAlLatoGiusto;
var
  LSamples: TArray<SmallInt>;
  LLeft: Double;
  LRight: Double;
  LIndex: Integer;
begin
  FRef.Send($B0, 10, 0);
  FRef.Send($90, 60, 100);
  LSamples := Render(2000);
  LLeft := 0;
  LRight := 0;
  for LIndex := 0 to 1999 do
  begin
    LLeft := LLeft + Abs(LSamples[LIndex * 2]);
    LRight := LRight + Abs(LSamples[LIndex * 2 + 1]);
  end;
  Assert.IsTrue(LLeft > 10 * LRight + 1, Format('pan 0: %f %f', [LLeft, LRight]));
  FRef.Send($B0, 120, 0);
  FRef.Send($B0, 10, 127);
  FRef.Send($90, 60, 100);
  LSamples := Render(2000);
  LLeft := 0;
  LRight := 0;
  for LIndex := 0 to 1999 do
  begin
    LLeft := LLeft + Abs(LSamples[LIndex * 2]);
    LRight := LRight + Abs(LSamples[LIndex * 2 + 1]);
  end;
  Assert.IsTrue(LRight > 10 * LLeft + 1, Format('pan 127: %f %f', [LLeft, LRight]));
end;

procedure TTestPcmMidiSynth.IlPitchBendCambiaLaFrequenza;
var
  LPlain: TArray<SmallInt>;
  LBent: TArray<SmallInt>;
begin
  FRef.Send($90, 60, 100);
  LPlain := Render(RATE);
  FRef.Send($B0, 120, 0);
  // the highest bend: two semitones up
  FRef.Send($E0, $7F, $7F);
  FRef.Send($90, 60, 100);
  LBent := Render(RATE);
  Assert.IsTrue(Crossings(LBent) > Crossings(LPlain));
end;

procedure TTestPcmMidiSynth.TutteLeNoteSpenteTaceSubito;
begin
  FRef.Send($90, 60, 100);
  FRef.Send($90, 64, 100);
  FRef.Send($B0, 120, 0);
  Assert.AreEqual(0, FSynth.ActiveVoices);
  Assert.AreEqual(0.0, Rms(Render(500)), 1e-9);
end;

procedure TTestPcmMidiSynth.TutteLeNoteRilasciateSiSpengonoDaSole;
begin
  FRef.Send($90, 60, 100);
  FRef.Send($90, 64, 100);
  FRef.Send($B0, 123, 0);
  Assert.AreEqual(2, FSynth.ActiveVoices);
  Render(RATE);
  Assert.AreEqual(0, FSynth.ActiveVoices);
end;

procedure TTestPcmMidiSynth.LaBatteriaSuonaSulCanaleDieciESiSpegneDaSola;
var
  LSamples: TArray<SmallInt>;
begin
  // a kick (a falling sine), a snare and a hat: noise that dies by itself, a note off does not matter
  FRef.Send($99, 36, 110);
  FRef.Send($99, 38, 110);
  FRef.Send($99, 42, 110);
  LSamples := Render(500);
  Assert.IsTrue(Rms(LSamples) > 100);
  FRef.Send($89, 36, 0);
  Render(RATE);
  Assert.AreEqual(0, FSynth.ActiveVoices);
end;

procedure TTestPcmMidiSynth.OltreLeVociDisponibiliSiRubaLaPiuVecchia;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 39 do
    FRef.Send($90, 40 + LIndex, 100);
  Assert.AreEqual(32, FSynth.ActiveVoices);
  // with released voices the steal takes one of them: the voices that sound stay 32
  FRef.Send($80, 40 + 39, 0);
  FRef.Send($90, 100, 100);
  Assert.AreEqual(32, FSynth.ActiveVoices);
  Assert.IsTrue(Rms(Render(500)) > 10);
end;

procedure TTestPcmMidiSynth.IlResetFaTacere;
begin
  FRef.Send($90, 60, 100);
  FRef.Send($B0, 7, 10);
  FRef.Reset;
  Assert.AreEqual(0, FSynth.ActiveVoices);
  // the controllers are back to the start: a new note has the full volume
  FRef.Send($90, 60, 100);
  Assert.IsTrue(Rms(Render(2000)) > 50);
end;

procedure TTestPcmMidiSynth.IlRenderSommaAlBufferEdECompreso;
var
  LBuffer: TArray<SmallInt>;
  LIndex: Integer;
begin
  SetLength(LBuffer, 400);
  for LIndex := 0 to 399 do
    LBuffer[LIndex] := 32000;
  FRef.Send($90, 60, 127);
  FRef.Send($90, 64, 127);
  FRef.Send($90, 67, 127);
  FRef.Render(@LBuffer[0], 1600);
  // it adds to what is there: a wrap-around past 16 bits would lower the RMS
  Assert.IsTrue(Rms(LBuffer) > 25000);
end;

procedure TTestPcmMidiSynth.UnaRichiestaNonMultiplaDiQuattroDaEccezione;
var
  LBuffer: TArray<SmallInt>;
begin
  SetLength(LBuffer, 8);
  Assert.WillRaise(
    procedure
    begin
      FRef.Render(@LBuffer[0], 6);
    end, EAudioMixException);
end;

procedure TTestPcmMidiSynth.UnRateNonValidoDaEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TPcmMidiSynth.Create(0);
    end, EArgumentOutOfRangeException);
end;

procedure TTestPcmMidiSynth.OgniFamigliaDiPatchProduceSuono;
var
  LFamily: Integer;
begin
  for LFamily := 0 to 15 do
  begin
    FRef.Send($B0, 120, 0);
    FRef.Send($C0, LFamily * 8, 0);
    FRef.Send($90, 60, 100);
    Assert.IsTrue(Rms(Render(1000)) > 20, 'family ' + IntToStr(LFamily));
  end;
end;

procedure TTestPcmMidiSynth.LaStessaPartituraDaLaStessaImprontaDelVecchioSintetizzatore;
var
  LExpected: UInt64;
  LActual: UInt64;
begin
{$IFDEF CPUX64}
  LExpected := GOLDEN_FINGERPRINT_WIN64;
{$ELSE}
  LExpected := GOLDEN_FINGERPRINT_WIN32;
{$ENDIF}
  LActual := TMidiScenario.Fingerprint(
    procedure(AStatus, AData1, AData2: Byte)
    begin
      FRef.Send(AStatus, AData1, AData2);
    end,
    procedure(ABuffer: PSmallInt; AFrames: Integer)
    begin
      FRef.Render(ABuffer, AFrames * 4);
    end);
  Assert.AreEqual(IntToHex(LExpected, 16), IntToHex(LActual, 16));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPcmMidiSynth);

end.
