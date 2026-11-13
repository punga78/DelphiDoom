{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - voices, mixer, volume of a sound on  }
{  the map, spacing of the answers and the PCM source                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AudioMixer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Audio.Types,
  DelphiDoom.War.Audio.Intf;

type
  /// <summary>A library that has the sounds the test gives it</summary>
  TWarFakeAudioLibrary = class(TInterfacedObject, IWarAudioLibrary)
  strict private
    FSounds: array[0..9] of TBytes;
  public
    procedure Put(AIndex: Integer; const AData: TBytes);
    function KindOf(AIndex: Integer): TWarAudioKind;
    function GetSound(AIndex: Integer): TWarPcmBuffer;
    function GetMusic(AIndex: Integer): TBytes;
  end;

  /// <summary>
  ///   audio.mixer.golden.txt: wa_playWave of war_audio.c ORIGINAL (extracted and compiled with gcc) on a sound of
  ///   3000 bytes, 9 scenarios of volume, loop and block sizes; each call gives the return value, sampleIndex, the
  ///   bits of playbackTime (a float) and the CRC-32 of the output. audio.position.golden.txt: the volume of a
  ///   sound outside the viewport, as audioDataCallback computes it, bit by bit
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarAudioMixer = class(TObject)
  private
    function Mono(const ASamples: array of Byte): TBytes;
    function NewMixer(const ASound: TBytes): IWarSoundMixer;
    function Mixed(const AMixer: IWarSoundMixer; ACount: Integer; AFill: SmallInt): TArray<SmallInt>;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCodiceOriginaleNegliScenariDelMixer;
    [Test]
    procedure DovrebbeDareLoStessoVolumeFuoriDallaVistaDelCodiceOriginale;
    [Test]
    procedure DovrebbeRicominciareUnaVoceFinitaSeLaSiChiamaAncora;
    [Test]
    procedure DovrebbeFinireAlloStessoVolumeUnSuonoVuoto;
    [Test]
    procedure DovrebbeSommareAQuelloCheCEGiaNelBufferESaturare;
    [Test]
    procedure DovrebbeTogliereUnaVoceFinita;
    [Test]
    procedure DovrebbeTenereUnaVoceInCiclo;
    [Test]
    procedure DovrebbeDareManiglieCheCrescono;
    [Test]
    procedure DovrebbeFermareUnaVoceEToglierleTutte;
    [Test]
    procedure DovrebbeTacereEFermareLeVociMentreESilenziato;
    [Test]
    procedure DovrebbeUsareIlVolumeDeiSuoniELimitarloATraZeroEUno;
    [Test]
    procedure DovrebbeTacereSeISuoniSonoDisattivati;
    [Test]
    procedure DovrebbeSentireUnSuonoDentroLaVistaAlVolumePieno;
    [Test]
    procedure DovrebbeAbbassareUnSuonoFuoriDallaVistaEScalarloPerIlVolumeDeiSuoni;
    [Test]
    procedure DovrebbeSommareLeVociNellOrdineInCuiSonoPartite;
    [Test]
    procedure DovrebbeRifiutareUnaLibreriaNil;
    [Test]
    procedure DovrebbeLasciareIlBufferSeNonCeNulla;
    [Test]
    procedure DovrebbeDareIlSuonoDellaLibreria;
    [Test]
    procedure DovrebbeConsentireUnaRispostaOgni150Millisecondi;
    [Test]
    procedure DovrebbeDimenticareLUltimaRispostaConReset;
    [Test]
    procedure DovrebbeDuplicareIlMonoSuiDueCanali;
    [Test]
    procedure DovrebbeServireUnaRichiestaPiuLungaDelBufferDelMixerABlocchi;
    [Test]
    procedure DovrebbeRifiutareUnMixerNilNellaFonte;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.War.RealData, DelphiDoom.Tests.War.AudioSupport, DelphiDoom.War.Audio.WaveVoice,
  DelphiDoom.War.Audio.Attenuation, DelphiDoom.War.Audio.AckThrottle, DelphiDoom.War.Audio.Mixer,
  DelphiDoom.War.Audio.PcmSource, DelphiDoom.GameHost.Audio.Intf;

type
  TMixCase = record
    Volume: Single;
    Loop: Boolean;
    Calls: Integer;
    Counts: array[0..5] of Integer;
  end;

const
  MIX_CASES: array[0..8] of TMixCase = (
    (Volume: 1.0; Loop: False; Calls: 4; Counts: (1000, 1000, 1000, 1000, 0, 0)),
    (Volume: 0.5; Loop: True; Calls: 3; Counts: (4096, 8192, 77, 0, 0, 0)),
    (Volume: 0.75; Loop: False; Calls: 3; Counts: (2999, 1, 1, 0, 0, 0)),
    (Volume: 0.3333333; Loop: True; Calls: 1; Counts: (5000, 0, 0, 0, 0, 0)),
    (Volume: 1.5; Loop: False; Calls: 1; Counts: (100, 0, 0, 0, 0, 0)),
    (Volume: 0.0; Loop: False; Calls: 1; Counts: (50, 0, 0, 0, 0, 0)),
    (Volume: 0.1; Loop: False; Calls: 2; Counts: (3000, 1, 0, 0, 0, 0)),
    (Volume: 1.0; Loop: True; Calls: 2; Counts: (2999, 3, 0, 0, 0, 0)),
    (Volume: 0.9; Loop: False; Calls: 5; Counts: (600, 600, 600, 600, 600, 0)));

  VIEWPORT_X = 100.0;
  VIEWPORT_Y = 50.0;
  VIEWPORT_WIDTH = 240.0;
  VIEWPORT_HEIGHT = 160.0;

  POSITIONS: array[0..19, 0..1] of Single = (
    (220, 130), (100, 50), (340, 210), (99, 130), (341, 130), (220, 49), (220, 211),
    (60, 130), (20, 130), (0, 0), (500, 400), (340, 340), (400, 130), (420, 130), (438.5, 131),
    (300, 300), (150, 250), (1024, 1024), (241, 130), (339.9, 130.25));
  VOLUMES: array[0..2] of Single = (1.0, 0.6, 0.0);

function FloatBits(AValue: Single): string;
begin
  Result := LowerCase(IntToHex(PCardinal(@AValue)^, 8));
end;

{ TWarFakeAudioLibrary }

procedure TWarFakeAudioLibrary.Put(AIndex: Integer; const AData: TBytes);
begin
  FSounds[AIndex] := AData;
end;

function TWarFakeAudioLibrary.KindOf(AIndex: Integer): TWarAudioKind;
begin
  Result := wakWave;
end;

function TWarFakeAudioLibrary.GetSound(AIndex: Integer): TWarPcmBuffer;
begin
  if (AIndex < 0) or (AIndex > High(FSounds)) then
    raise EWarException.CreateFmt(SWarAudioNotSound, [AIndex]);
  Result := Default(TWarPcmBuffer);
  Result.Channels := 1;
  Result.BitsPerSample := 8;
  Result.SampleRate := WAR_PLAYBACK_RATE;
  Result.Data := FSounds[AIndex];
end;

function TWarFakeAudioLibrary.GetMusic(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

{ TTestWarAudioMixer }

function TTestWarAudioMixer.Mono(const ASamples: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ASamples));
  for LIndex := 0 to High(ASamples) do
    Result[LIndex] := ASamples[LIndex];
end;

function TTestWarAudioMixer.NewMixer(const ASound: TBytes): IWarSoundMixer;
var
  LLibrary: TWarFakeAudioLibrary;
begin
  LLibrary := TWarFakeAudioLibrary.Create;
  LLibrary.Put(1, ASound);
  Result := TWarSoundMixer.Create(LLibrary);
end;

function TTestWarAudioMixer.Mixed(const AMixer: IWarSoundMixer; ACount: Integer; AFill: SmallInt): TArray<SmallInt>;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := AFill;
  AMixer.Mix(@Result[0], ACount);
end;

procedure TTestWarAudioMixer.DovrebbeDareLeStesseRisposteDelCodiceOriginaleNegliScenariDelMixer;
var
  LGolden: TStringList;
  LWave: TBytes;
  LIndex, LCase, LCall, LLineNumber, LCount: Integer;
  LVoice: TWarWaveVoice;
  LOutput: TArray<SmallInt>;
  LFinished: Boolean;
  LExpected: string;
begin
  SetLength(LWave, 3000);
  for LIndex := 0 to 2999 do
    LWave[LIndex] := Byte((LIndex * 37) xor (LIndex shr 3));
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('audio.mixer.golden.txt'));
    LLineNumber := 0;
    for LCase := 0 to High(MIX_CASES) do
    begin
      LVoice := TWarWaveVoice.Create(LWave, MIX_CASES[LCase].Loop);
      try
        for LCall := 0 to MIX_CASES[LCase].Calls - 1 do
        begin
          LCount := MIX_CASES[LCase].Counts[LCall];
          SetLength(LOutput, LCount);
          for LIndex := 0 to LCount - 1 do
            LOutput[LIndex] := SmallInt(Word((Cardinal(LIndex) + Cardinal(LCall) * 11) * 7919));
          LFinished := LVoice.Mix(@LOutput[0], LCount, MIX_CASES[LCase].Volume);
          LExpected := Format('A %d %d %d %d %s %s', [LCase, LCall, Ord(LFinished), LVoice.SampleIndex,
            FloatBits(LVoice.PlaybackTime), TWarAudioHash.OfBuffer(LOutput[0], LCount * 2)]);
          Assert.AreEqual(LGolden[LLineNumber], LExpected, 'riga ' + IntToStr(LLineNumber));
          Inc(LLineNumber);
        end;
      finally
        LVoice.Free;
      end;
    end;
    Assert.AreEqual(LGolden.Count, LLineNumber);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarAudioMixer.DovrebbeDareLoStessoVolumeFuoriDallaVistaDelCodiceOriginale;
var
  LGolden: TStringList;
  LVolume, LPoint, LLine: Integer;
  LValue: Single;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('audio.position.golden.txt'));
    LLine := 0;
    for LVolume := 0 to High(VOLUMES) do
      for LPoint := 0 to High(POSITIONS) do
      begin
        LValue := TWarSoundAttenuation.Volume(VIEWPORT_X, VIEWPORT_Y, VIEWPORT_WIDTH, VIEWPORT_HEIGHT,
          POSITIONS[LPoint, 0], POSITIONS[LPoint, 1], VOLUMES[LVolume]);
        Assert.AreEqual(LGolden[LLine], Format('P %d %d %s', [LVolume, LPoint, FloatBits(LValue)]),
          'riga ' + IntToStr(LLine));
        Inc(LLine);
      end;
    Assert.AreEqual(LGolden.Count, LLine);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarAudioMixer.DovrebbeRicominciareUnaVoceFinitaSeLaSiChiamaAncora;
var
  LVoice: TWarWaveVoice;
  LOutput: array[0..4] of SmallInt;
begin
  LVoice := TWarWaveVoice.Create(Mono([192, 192, 192]), False);
  try
    FillChar(LOutput, SizeOf(LOutput), 0);
    Assert.IsTrue(LVoice.Mix(@LOutput[0], 3, 1));
    Assert.AreEqual(3, LVoice.SampleIndex);
    // as the original: called again it starts again from the first sample
    FillChar(LOutput, SizeOf(LOutput), 0);
    Assert.IsFalse(LVoice.Mix(@LOutput[0], 2, 1));
    Assert.AreEqual(2, LVoice.SampleIndex);
    Assert.AreEqual<Integer>(16384, LOutput[0]);
  finally
    LVoice.Free;
  end;
end;

procedure TTestWarAudioMixer.DovrebbeFinireAlloStessoVolumeUnSuonoVuoto;
var
  LVoice: TWarWaveVoice;
  LOutput: SmallInt;
begin
  // the original never leaves the loop of a looping sound without samples
  LVoice := TWarWaveVoice.Create(nil, True);
  try
    LOutput := 5;
    Assert.IsTrue(LVoice.Mix(@LOutput, 1, 1));
    Assert.AreEqual<Integer>(5, LOutput);
  finally
    LVoice.Free;
  end;
end;

procedure TTestWarAudioMixer.DovrebbeSommareAQuelloCheCEGiaNelBufferESaturare;
var
  LVoice: TWarWaveVoice;
  LOutput: array[0..2] of SmallInt;
begin
  LVoice := TWarWaveVoice.Create(Mono([255, 0, 128]), False);
  try
    LOutput[0] := 30000;
    LOutput[1] := -30000;
    LOutput[2] := 123;
    LVoice.Mix(@LOutput[0], 3, 1);
    Assert.AreEqual<Integer>(32767, LOutput[0], 'satura in alto');
    Assert.AreEqual<Integer>(-32768, LOutput[1], 'satura in basso');
    Assert.AreEqual<Integer>(123, LOutput[2], 'il centro non aggiunge nulla');
  finally
    LVoice.Free;
  end;
end;

procedure TTestWarAudioMixer.DovrebbeTogliereUnaVoceFinita;
var
  LMixer: IWarSoundMixer;
begin
  LMixer := NewMixer(Mono([192, 192]));
  LMixer.Play(1, False);
  Assert.AreEqual(1, LMixer.ActiveVoices);
  Mixed(LMixer, 1, 0);
  Assert.AreEqual(1, LMixer.ActiveVoices);
  Mixed(LMixer, 1, 0);
  Assert.AreEqual(0, LMixer.ActiveVoices);
end;

procedure TTestWarAudioMixer.DovrebbeTenereUnaVoceInCiclo;
var
  LMixer: IWarSoundMixer;
  LOutput: TArray<SmallInt>;
begin
  LMixer := NewMixer(Mono([192, 192]));
  LMixer.Play(1, True);
  LOutput := Mixed(LMixer, 5, 0);
  Assert.AreEqual(1, LMixer.ActiveVoices);
  Assert.AreEqual<Integer>(16384, LOutput[4]);
end;

procedure TTestWarAudioMixer.DovrebbeDareManiglieCheCrescono;
var
  LMixer: IWarSoundMixer;
  LFirst, LSecond: Integer;
begin
  LMixer := NewMixer(Mono([192]));
  LFirst := LMixer.Play(1, True);
  LSecond := LMixer.PlayAt(1, 0, 0, True);
  Assert.IsTrue(LSecond > LFirst);
  Assert.AreEqual(2, LMixer.ActiveVoices);
end;

procedure TTestWarAudioMixer.DovrebbeFermareUnaVoceEToglierleTutte;
var
  LMixer: IWarSoundMixer;
  LFirst: Integer;
begin
  LMixer := NewMixer(Mono([192]));
  LFirst := LMixer.Play(1, True);
  LMixer.Play(1, True);
  LMixer.Stop(LFirst);
  Assert.AreEqual(1, LMixer.ActiveVoices);
  LMixer.Stop(9999);
  Assert.AreEqual(1, LMixer.ActiveVoices);
  LMixer.StopAll;
  Assert.AreEqual(0, LMixer.ActiveVoices);
end;

procedure TTestWarAudioMixer.DovrebbeTacereEFermareLeVociMentreESilenziato;
var
  LMixer: IWarSoundMixer;
  LOutput: TArray<SmallInt>;
begin
  LMixer := NewMixer(Mono([192, 192]));
  LMixer.Play(1, False);
  LMixer.SetSilenced(True);
  LOutput := Mixed(LMixer, 2, 7);
  Assert.AreEqual<Integer>(7, LOutput[0]);
  Assert.AreEqual(1, LMixer.ActiveVoices, 'la voce non e'' avanzata');
  LMixer.SetSilenced(False);
  LOutput := Mixed(LMixer, 2, 0);
  Assert.AreEqual<Integer>(16384, LOutput[1]);
end;

procedure TTestWarAudioMixer.DovrebbeUsareIlVolumeDeiSuoniELimitarloATraZeroEUno;
var
  LMixer: IWarSoundMixer;
  LOutput: TArray<SmallInt>;
begin
  LMixer := NewMixer(Mono([192]));
  LMixer.SetVolume(0.5, True);
  LMixer.Play(1, True);
  LOutput := Mixed(LMixer, 1, 0);
  Assert.AreEqual<Integer>(8192, LOutput[0]);
  LMixer.SetVolume(7, True);
  LOutput := Mixed(LMixer, 1, 0);
  Assert.AreEqual<Integer>(16384, LOutput[0], 'oltre uno vale uno');
  LMixer.SetVolume(-3, True);
  LOutput := Mixed(LMixer, 1, 0);
  Assert.AreEqual<Integer>(0, LOutput[0], 'sotto zero vale zero');
end;

procedure TTestWarAudioMixer.DovrebbeTacereSeISuoniSonoDisattivati;
var
  LMixer: IWarSoundMixer;
  LOutput: TArray<SmallInt>;
begin
  LMixer := NewMixer(Mono([192]));
  LMixer.SetVolume(1, False);
  LMixer.Play(1, True);
  LOutput := Mixed(LMixer, 1, 0);
  Assert.AreEqual<Integer>(0, LOutput[0]);
end;

procedure TTestWarAudioMixer.DovrebbeSentireUnSuonoDentroLaVistaAlVolumePieno;
var
  LMixer: IWarSoundMixer;
  LOutput: TArray<SmallInt>;
begin
  LMixer := NewMixer(Mono([192]));
  LMixer.SetViewport(0, 0, 100, 100);
  LMixer.PlayAt(1, 50, 50, True);
  LOutput := Mixed(LMixer, 1, 0);
  Assert.AreEqual<Integer>(16384, LOutput[0]);
end;

procedure TTestWarAudioMixer.DovrebbeAbbassareUnSuonoFuoriDallaVistaEScalarloPerIlVolumeDeiSuoni;
var
  LMixer: IWarSoundMixer;
  LOutput: TArray<SmallInt>;
begin
  // the center is (50, 50): at (220, 50) the distance is 170, so 0.75 * (1 - 50 / 80) = 0.28125
  LMixer := NewMixer(Mono([192]));
  LMixer.SetViewport(0, 0, 100, 100);
  LMixer.PlayAt(1, 220, 50, True);
  LOutput := Mixed(LMixer, 1, 0);
  Assert.AreEqual<Integer>(4608, LOutput[0]);
  // differenza voluta: the original does not scale it by the sound volume (a muted sound would be heard from afar)
  LMixer.SetVolume(0.5, True);
  LOutput := Mixed(LMixer, 1, 0);
  Assert.AreEqual<Integer>(2304, LOutput[0]);
  LMixer.SetVolume(1, False);
  LOutput := Mixed(LMixer, 1, 0);
  Assert.AreEqual<Integer>(0, LOutput[0]);
  // 200 or more pixels from the center: silence
  LMixer.StopAll;
  LMixer.SetVolume(1, True);
  LMixer.PlayAt(1, 250, 50, True);
  LOutput := Mixed(LMixer, 1, 0);
  Assert.AreEqual<Integer>(0, LOutput[0]);
end;

procedure TTestWarAudioMixer.DovrebbeSommareLeVociNellOrdineInCuiSonoPartite;
var
  LLibrary: TWarFakeAudioLibrary;
  LMixer: IWarSoundMixer;
  LOutput: TArray<SmallInt>;
begin
  // the sum saturates at each voice: 30000 + 16384 -> 32767, then - 16384 (a second voice of 64) is 16383
  LLibrary := TWarFakeAudioLibrary.Create;
  LLibrary.Put(1, Mono([192]));
  LLibrary.Put(2, Mono([64]));
  LMixer := TWarSoundMixer.Create(LLibrary);
  LMixer.Play(1, True);
  LMixer.Play(2, True);
  LOutput := Mixed(LMixer, 1, 30000);
  Assert.AreEqual<Integer>(16383, LOutput[0]);
end;

procedure TTestWarAudioMixer.DovrebbeRifiutareUnaLibreriaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarSoundMixer.Create(nil);
    end, EWarException);
end;

procedure TTestWarAudioMixer.DovrebbeLasciareIlBufferSeNonCeNulla;
var
  LMixer: IWarSoundMixer;
  LOutput: TArray<SmallInt>;
begin
  LMixer := NewMixer(Mono([192]));
  LOutput := Mixed(LMixer, 3, 9);
  Assert.AreEqual<Integer>(9, LOutput[2]);
  LMixer.Mix(nil, 0);
  LMixer.Play(1, True);
  LMixer.Mix(nil, -4);
  Assert.AreEqual(1, LMixer.ActiveVoices);
end;

procedure TTestWarAudioMixer.DovrebbeDareIlSuonoDellaLibreria;
var
  LMixer: IWarSoundMixer;
begin
  LMixer := NewMixer(Mono([192]));
  Assert.WillRaise(
    procedure
    begin
      LMixer.Play(15, False);
    end, EWarException);
  Assert.AreEqual(0, LMixer.ActiveVoices);
end;

procedure TTestWarAudioMixer.DovrebbeConsentireUnaRispostaOgni150Millisecondi;
var
  LThrottle: TWarAcknowledgementThrottle;
begin
  LThrottle := TWarAcknowledgementThrottle.Create;
  try
    Assert.IsFalse(LThrottle.TryAcquire(0.1), 'il tempo parte da 0');
    Assert.IsTrue(LThrottle.TryAcquire(0.15));
    Assert.IsFalse(LThrottle.TryAcquire(0.2));
    Assert.IsFalse(LThrottle.TryAcquire(0.29));
    Assert.IsTrue(LThrottle.TryAcquire(0.31));
  finally
    LThrottle.Free;
  end;
end;

procedure TTestWarAudioMixer.DovrebbeDimenticareLUltimaRispostaConReset;
var
  LThrottle: TWarAcknowledgementThrottle;
begin
  LThrottle := TWarAcknowledgementThrottle.Create;
  try
    Assert.IsTrue(LThrottle.TryAcquire(10));
    Assert.IsFalse(LThrottle.TryAcquire(10.1));
    LThrottle.Reset;
    Assert.IsFalse(LThrottle.TryAcquire(0.1));
    Assert.IsTrue(LThrottle.TryAcquire(0.2));
  finally
    LThrottle.Free;
  end;
end;

procedure TTestWarAudioMixer.DovrebbeDuplicareIlMonoSuiDueCanali;
var
  LMixer: IWarSoundMixer;
  LSource: IGameHostPcmSource;
  LBuffer: array[0..7] of SmallInt;
begin
  LMixer := NewMixer(Mono([192, 64]));
  LMixer.Play(1, False);
  LSource := TWarPcmSource.Create(LMixer);
  FillChar(LBuffer, SizeOf(LBuffer), 1);
  LSource.Render(@LBuffer[0], SizeOf(LBuffer));
  Assert.AreEqual<Integer>(16384, LBuffer[0]);
  Assert.AreEqual<Integer>(16384, LBuffer[1]);
  Assert.AreEqual<Integer>(-16384, LBuffer[2]);
  Assert.AreEqual<Integer>(-16384, LBuffer[3]);
  Assert.AreEqual<Integer>(0, LBuffer[4], 'poi silenzio: il buffer e'' azzerato');
  Assert.AreEqual<Integer>(0, LBuffer[7]);
end;

procedure TTestWarAudioMixer.DovrebbeServireUnaRichiestaPiuLungaDelBufferDelMixerABlocchi;
var
  LMixer: IWarSoundMixer;
  LSource: IGameHostPcmSource;
  LSound: TBytes;
  LBuffer: TArray<SmallInt>;
  LIndex: Integer;
begin
  SetLength(LSound, 10000);
  for LIndex := 0 to 9999 do
    LSound[LIndex] := 192;
  LMixer := NewMixer(LSound);
  LMixer.Play(1, False);
  LSource := TWarPcmSource.Create(LMixer);
  SetLength(LBuffer, 20002);
  LSource.Render(@LBuffer[0], 40008);
  Assert.AreEqual<Integer>(16384, LBuffer[2 * 9999]);
  Assert.AreEqual<Integer>(0, LBuffer[2 * 10000]);
  Assert.AreEqual<Integer>(16384, LBuffer[2 * 8192 + 1]);
  Assert.AreEqual(0, LMixer.ActiveVoices);
end;

procedure TTestWarAudioMixer.DovrebbeRifiutareUnMixerNilNellaFonte;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarPcmSource.Create(nil);
    end, EWarException);
end;

end.
