{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the sound as samples: the PC    }
{  speaker, the AdLib card on the OPL emulator, the mixer and its lock          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Audio;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-sound')]
  TTestKeenAudio = class(TObject)
  strict private
    function RealManager(out ASpeaker: IKeenSampleSource; out ACard: IKeenSampleSource;
      out ALock: IKeenAudioLock; out AAudio: IKeenChunkSource): IKeenSoundManager;
  public
    [Test]
    procedure LoAltoparlanteDovrebbeTacereFinoAUnTono;
    [Test]
    procedure LoAltoparlanteDovrebbeDareUnOndaQuadraDelPeriodoDelDivisore;
    [Test]
    procedure LoAltoparlanteDovrebbeTacereDopoSilenzioEStop;
    [Test]
    procedure LoAltoparlanteDovrebbeSommareAlBuffer;
    [Test]
    procedure LoAltoparlanteDovrebbeRifiutareUnaFrequenzaNonValida;
    [Test]
    procedure LaSchedaDovrebbeContareLeScrittureETacereSenzaNote;
    [Test]
    procedure LaSchedaDovrebbeSuonareUnaNota;
    [Test]
    procedure IlMixerDovrebbeChiamareIlServizioCentoquarantaVolteAlSecondo;
    [Test]
    procedure IlMixerDovrebbeDareGliStessiCampioniComunqueSiaTagliatoIlBuffer;
    [Test]
    procedure IlMixerDovrebbeScrivereSinistraEDestraUguali;
    [Test]
    procedure IlMixerDovrebbeTagliareIPicchi;
    [Test]
    procedure IlMixerDovrebbeContareIFotogrammiUdibili;
    [Test]
    procedure IlMixerDovrebbeRifiutareIParametriNonValidi;
    [Test]
    procedure IlGestoreProtettoDovrebbeAspettareLaFineDelSuonoSenzaServire;
    [Test]
    procedure IlGestoreProtettoDovrebbePassareOgniChiamata;
    [Test]
    procedure IlLucchettoDovrebbeLasciarRientrareLoStessoThread;
    [Test]
    procedure OgniSuonoDelloSharewareDovrebbeDareCampioniConLoAltoparlante;
    [Test]
    procedure OgniSuonoDelloSharewareDovrebbeDareCampioniConLaScheda;
  end;

implementation

uses
  DelphiDoom.Keen.SpeakerSynth, DelphiDoom.Keen.OplAdLib, DelphiDoom.Keen.AudioMixer, DelphiDoom.Keen.AudioLock,
  DelphiDoom.Keen.LockedSoundManager, DelphiDoom.Keen.SoundManager, DelphiDoom.Keen.PcSpeaker,
  DelphiDoom.Keen.Factory, DelphiDoom.Opl.Intf, DelphiDoom.Opl.Factory, DelphiDoom.Tests.Keen.RealData,
  DelphiDoom.Tests.Shared.Skip;

const
  RATE = 44100;

type
  /// <summary>A sound manager that counts its calls; a sound "plays" for a number of services</summary>
  TCountingManager = class(TInterfacedObject, IKeenSoundManager)
  public
    Services: Integer;
    Left: Integer;
    Calls: string;
    function GetMode: TKeenSoundMode;
    procedure SetMode(AMode: TKeenSoundMode);
    procedure PlaySound(ASound: Integer);
    procedure StopSound;
    function SoundPlaying: Integer;
    procedure Service;
    procedure WaitSoundDone;
    function AdLibPresent: Boolean;
    function TrySetMode(AMode: TKeenSoundMode): Boolean;
    procedure SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
  end;

  /// <summary>A source that gives the same value for every sample</summary>
  TConstantSource = class(TInterfacedObject, IKeenSampleSource)
  strict private
    FValue: Integer;
  public
    constructor Create(AValue: Integer);
    procedure AddSamples(const ABuffer: TArray<Integer>; ACount: Integer);
  end;

  /// <summary>A source that counts the samples: the sample n is n</summary>
  TRampSource = class(TInterfacedObject, IKeenSampleSource)
  strict private
    FNext: Integer;
  public
    procedure AddSamples(const ABuffer: TArray<Integer>; ACount: Integer);
  end;

{ TCountingManager }

function TCountingManager.GetMode: TKeenSoundMode;
begin
  Calls := Calls + 'G';
  Result := ksmPC;
end;

procedure TCountingManager.SetMode(AMode: TKeenSoundMode);
begin
  Calls := Calls + 'M';
end;

procedure TCountingManager.PlaySound(ASound: Integer);
begin
  Calls := Calls + 'P';
  Left := ASound;
end;

procedure TCountingManager.StopSound;
begin
  Calls := Calls + 'X';
  Left := 0;
end;

function TCountingManager.SoundPlaying: Integer;
begin
  Result := Left;
end;

procedure TCountingManager.Service;
begin
  Inc(Services);
  if Left > 0 then
    Dec(Left);
end;

procedure TCountingManager.WaitSoundDone;
begin
  Calls := Calls + 'W';
end;

function TCountingManager.AdLibPresent: Boolean;
begin
  Result := True;
end;

function TCountingManager.TrySetMode(AMode: TKeenSoundMode): Boolean;
begin
  Calls := Calls + 'T';
  Result := True;
end;

procedure TCountingManager.SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
begin
  Calls := Calls + 'D';
end;

{ TConstantSource }

constructor TConstantSource.Create(AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
end;

procedure TConstantSource.AddSamples(const ABuffer: TArray<Integer>; ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
    Inc(ABuffer[LIndex], FValue);
end;

{ TRampSource }

procedure TRampSource.AddSamples(const ABuffer: TArray<Integer>; ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    Inc(ABuffer[LIndex], FNext and $3FFF);
    Inc(FNext);
  end;
end;

{ TTestKeenAudio }

procedure TTestKeenAudio.LoAltoparlanteDovrebbeTacereFinoAUnTono;
var
  LSynth: IKeenSampleSource;
  LBuffer: TArray<Integer>;
  LIndex: Integer;
begin
  LSynth := TKeenSpeakerSynth.Create(RATE);
  SetLength(LBuffer, 100);
  LSynth.AddSamples(LBuffer, 100);
  for LIndex := 0 to 99 do
    Assert.AreEqual(0, LBuffer[LIndex]);
end;

procedure TTestKeenAudio.LoAltoparlanteDovrebbeDareUnOndaQuadraDelPeriodoDelDivisore;
var
  LObject: TKeenSpeakerSynth;
  LSynth: IKeenSampleSource;
  LBuffer: TArray<Integer>;
  LIndex: Integer;
  LEdges: Integer;
begin
  LObject := TKeenSpeakerSynth.Create(RATE);
  LSynth := LObject;
  // the divisor 2712: 1193181 / 2712 = 440 Hz, in one second 440 periods
  LObject.Tone(2712);
  SetLength(LBuffer, RATE);
  LSynth.AddSamples(LBuffer, RATE);
  LEdges := 0;
  for LIndex := 0 to RATE - 1 do
  begin
    Assert.AreEqual(KEEN_SPEAKER_AMPLITUDE, Abs(LBuffer[LIndex]));
    if (LIndex > 0) and (LBuffer[LIndex] > 0) and (LBuffer[LIndex - 1] < 0) then
      Inc(LEdges);
  end;
  Assert.IsTrue(Abs(LEdges - 440) <= 1, 'rising edges: ' + IntToStr(LEdges));
  Assert.AreEqual(KEEN_SPEAKER_AMPLITUDE, LBuffer[0], 'the wave starts high');
end;

procedure TTestKeenAudio.LoAltoparlanteDovrebbeTacereDopoSilenzioEStop;
var
  LObject: TKeenSpeakerSynth;
  LSynth: IKeenSampleSource;
  LBuffer: TArray<Integer>;
begin
  LObject := TKeenSpeakerSynth.Create(RATE);
  LSynth := LObject;
  SetLength(LBuffer, 4);
  LObject.Tone(600);
  LObject.Silence;
  LSynth.AddSamples(LBuffer, 4);
  Assert.AreEqual(0, LBuffer[0]);
  LObject.Tone(600);
  LObject.Stop;
  LSynth.AddSamples(LBuffer, 4);
  Assert.AreEqual(0, LBuffer[3]);
  // the divisor 0 is 65536 for the timer: a tone, not a division by zero
  LObject.Tone(0);
  LSynth.AddSamples(LBuffer, 4);
  Assert.AreEqual(KEEN_SPEAKER_AMPLITUDE, Abs(LBuffer[0]));
end;

procedure TTestKeenAudio.LoAltoparlanteDovrebbeSommareAlBuffer;
var
  LObject: TKeenSpeakerSynth;
  LSynth: IKeenSampleSource;
  LBuffer: TArray<Integer>;
begin
  LObject := TKeenSpeakerSynth.Create(RATE);
  LSynth := LObject;
  LObject.Tone(600);
  LBuffer := TArray<Integer>.Create(100, 100);
  LSynth.AddSamples(LBuffer, 1);
  Assert.AreEqual(100 + KEEN_SPEAKER_AMPLITUDE, LBuffer[0]);
  Assert.AreEqual(100, LBuffer[1], 'only the samples that were asked');
end;

procedure TTestKeenAudio.LoAltoparlanteDovrebbeRifiutareUnaFrequenzaNonValida;
begin
  Assert.WillRaise(procedure begin TKeenSpeakerSynth.Create(0); end, EArgumentOutOfRangeException);
end;

procedure TTestKeenAudio.LaSchedaDovrebbeContareLeScrittureETacereSenzaNote;
var
  LCard: TKeenOplAdLib;
  LSource: IKeenSampleSource;
  LBuffer: TArray<Integer>;
  LIndex: Integer;
begin
  LCard := TKeenOplAdLib.Create(TOplFactory.CreateChip(KEEN_ADLIB_CLOCK, RATE));
  LSource := LCard;
  LCard.Write($BD, 0);
  LCard.Write($B0, 0);
  Assert.AreEqual(Int64(2), LCard.Writes);
  SetLength(LBuffer, 500);
  LSource.AddSamples(LBuffer, 500);
  LSource.AddSamples(LBuffer, 0);
  for LIndex := 0 to 499 do
    Assert.AreEqual(0, LBuffer[LIndex]);
  Assert.WillRaise(procedure begin TKeenOplAdLib.Create(nil); end, EArgumentNilException);
end;

procedure TTestKeenAudio.LaSchedaDovrebbeSuonareUnaNota;
var
  LCard: TKeenOplAdLib;
  LSource: IKeenSampleSource;
  LBuffer: TArray<Integer>;
  LIndex: Integer;
  LPeak: Integer;
begin
  LCard := TKeenOplAdLib.Create(TOplFactory.CreateChip(KEEN_ADLIB_CLOCK, RATE));
  LSource := LCard;
  // a plain instrument on the channel 0: fast attack, full sustain, the carrier at full volume
  LCard.Write($20, $01);
  LCard.Write($40, $10);
  LCard.Write($60, $F0);
  LCard.Write($80, $77);
  LCard.Write($23, $01);
  LCard.Write($43, $00);
  LCard.Write($63, $F0);
  LCard.Write($83, $77);
  LCard.Write($A0, $98);
  LCard.Write($B0, $31);
  SetLength(LBuffer, 4000);
  LSource.AddSamples(LBuffer, 4000);
  LPeak := 0;
  for LIndex := 0 to 3999 do
    if Abs(LBuffer[LIndex]) > LPeak then
      LPeak := Abs(LBuffer[LIndex]);
  Assert.IsTrue(LPeak > 1000, 'peak ' + IntToStr(LPeak));
end;

procedure TTestKeenAudio.IlMixerDovrebbeChiamareIlServizioCentoquarantaVolteAlSecondo;
var
  LManager: TCountingManager;
  LIntf: IKeenSoundManager;
  LMixer: IKeenAudioMixer;
  LBytes: TBytes;
begin
  LManager := TCountingManager.Create;
  LIntf := LManager;
  LMixer := TKeenAudioMixer.Create(LIntf, [], TKeenAudioLock.Create, RATE);
  Assert.AreEqual(RATE, LMixer.Rate);
  SetLength(LBytes, RATE * 4);
  LMixer.Render(@LBytes[0], Length(LBytes));
  Assert.AreEqual(KEEN_PC_SERVICE_RATE, LManager.Services);
  Assert.AreEqual(Int64(KEEN_PC_SERVICE_RATE), LMixer.Statistics.Services);
  Assert.AreEqual(Int64(RATE), LMixer.Statistics.Frames);
  // a rate that 140 does not divide: the remainder is carried, the count stays exact over the seconds
  LManager := TCountingManager.Create;
  LIntf := LManager;
  LMixer := TKeenAudioMixer.Create(LIntf, [], TKeenAudioLock.Create, 22050);
  SetLength(LBytes, 22050 * 4);
  LMixer.Render(@LBytes[0], Length(LBytes));
  LMixer.Render(@LBytes[0], Length(LBytes));
  LMixer.Render(@LBytes[0], Length(LBytes));
  Assert.AreEqual(3 * KEEN_PC_SERVICE_RATE, LManager.Services);
end;

procedure TTestKeenAudio.IlMixerDovrebbeDareGliStessiCampioniComunqueSiaTagliatoIlBuffer;
var
  LWhole: TBytes;
  LParts: TBytes;
  LMixer: IKeenAudioMixer;
  LPosition: Integer;
  LSize: Integer;
begin
  LMixer := TKeenAudioMixer.Create(TCountingManager.Create, [TRampSource.Create], TKeenAudioLock.Create, RATE);
  SetLength(LWhole, 20000);
  LMixer.Render(@LWhole[0], Length(LWhole));
  LMixer := TKeenAudioMixer.Create(TCountingManager.Create, [TRampSource.Create], TKeenAudioLock.Create, RATE);
  SetLength(LParts, 20000);
  LPosition := 0;
  LSize := 4;
  while LPosition < Length(LParts) do
  begin
    if LPosition + LSize > Length(LParts) then
      LSize := Length(LParts) - LPosition;
    LMixer.Render(@LParts[LPosition], LSize);
    Inc(LPosition, LSize);
    LSize := (LSize * 3 + 4) and not 3;
    if LSize > 3000 then
      LSize := 4;
  end;
  Assert.AreEqual(LWhole, LParts);
end;

procedure TTestKeenAudio.IlMixerDovrebbeScrivereSinistraEDestraUguali;
var
  LMixer: IKeenAudioMixer;
  LSamples: array[0..7] of SmallInt;
begin
  LMixer := TKeenAudioMixer.Create(TCountingManager.Create, [TConstantSource.Create(1000), TConstantSource.Create(-300)],
    TKeenAudioLock.Create, RATE);
  LMixer.Render(@LSamples[0], SizeOf(LSamples));
  Assert.AreEqual(700, Integer(LSamples[0]));
  Assert.AreEqual(700, Integer(LSamples[1]));
  Assert.AreEqual(700, Integer(LSamples[7]));
end;

procedure TTestKeenAudio.IlMixerDovrebbeTagliareIPicchi;
var
  LMixer: IKeenAudioMixer;
  LSamples: array[0..1] of SmallInt;
begin
  LMixer := TKeenAudioMixer.Create(TCountingManager.Create, [TConstantSource.Create(30000), TConstantSource.Create(30000)],
    TKeenAudioLock.Create, RATE);
  LMixer.Render(@LSamples[0], SizeOf(LSamples));
  Assert.AreEqual(32767, Integer(LSamples[0]));
  Assert.AreEqual(32767, LMixer.Statistics.Peak);
  LMixer := TKeenAudioMixer.Create(TCountingManager.Create, [TConstantSource.Create(-70000)], TKeenAudioLock.Create, RATE);
  LMixer.Render(@LSamples[0], SizeOf(LSamples));
  Assert.AreEqual(-32768, Integer(LSamples[1]));
end;

procedure TTestKeenAudio.IlMixerDovrebbeContareIFotogrammiUdibili;
var
  LMixer: IKeenAudioMixer;
  LBytes: TBytes;
begin
  SetLength(LBytes, 400);
  LMixer := TKeenAudioMixer.Create(TCountingManager.Create, [], TKeenAudioLock.Create, RATE);
  LMixer.Render(@LBytes[0], 400);
  Assert.AreEqual(Int64(0), LMixer.Statistics.AudibleFrames);
  Assert.AreEqual(0, LMixer.Statistics.Peak);
  LMixer := TKeenAudioMixer.Create(TCountingManager.Create, [TConstantSource.Create(5)], TKeenAudioLock.Create, RATE);
  LMixer.Render(@LBytes[0], 400);
  Assert.AreEqual(Int64(100), LMixer.Statistics.AudibleFrames);
  Assert.AreEqual(5, LMixer.Statistics.Peak);
end;

procedure TTestKeenAudio.IlMixerDovrebbeRifiutareIParametriNonValidi;
begin
  Assert.WillRaise(
    procedure begin TKeenAudioMixer.Create(nil, [], TKeenAudioLock.Create, RATE); end, EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenAudioMixer.Create(TCountingManager.Create, [], nil, RATE); end, EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenAudioMixer.Create(TCountingManager.Create, [nil], TKeenAudioLock.Create, RATE); end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenAudioMixer.Create(TCountingManager.Create, [], TKeenAudioLock.Create, 100); end,
    EArgumentOutOfRangeException);
end;

procedure TTestKeenAudio.IlGestoreProtettoDovrebbeAspettareLaFineDelSuonoSenzaServire;
var
  LInner: TCountingManager;
  LInnerIntf: IKeenSoundManager;
  LLocked: IKeenSoundManager;
  LIdles: Integer;
begin
  LInner := TCountingManager.Create;
  LInnerIntf := LInner;
  LIdles := 0;
  // the "output" is the idle: each wait is a service of the timer
  LLocked := TKeenLockedSoundManager.Create(LInnerIntf, TKeenAudioLock.Create,
    procedure
    begin
      Inc(LIdles);
      LInner.Service;
    end);
  LLocked.PlaySound(5);
  LLocked.WaitSoundDone;
  Assert.AreEqual(5, LIdles);
  Assert.AreEqual(0, LLocked.SoundPlaying);
  Assert.AreEqual('P', LInner.Calls, 'the wait of the inner manager is not used');
end;

procedure TTestKeenAudio.IlGestoreProtettoDovrebbePassareOgniChiamata;
var
  LInner: TCountingManager;
  LInnerIntf: IKeenSoundManager;
  LLocked: IKeenSoundManager;
begin
  LInner := TCountingManager.Create;
  LInnerIntf := LInner;
  LLocked := TKeenLockedSoundManager.Create(LInnerIntf, TKeenAudioLock.Create, procedure begin end);
  Assert.AreEqual(Ord(ksmPC), Ord(LLocked.Mode));
  LLocked.Mode := ksmOff;
  LLocked.PlaySound(1);
  LLocked.StopSound;
  Assert.IsTrue(LLocked.TrySetMode(ksmAdLib));
  LLocked.SetDefault(False, ksmOff);
  LLocked.Service;
  Assert.IsTrue(LLocked.AdLibPresent);
  Assert.AreEqual('GMPXTD', LInner.Calls);
  Assert.AreEqual(1, LInner.Services);
  Assert.WillRaise(
    procedure begin TKeenLockedSoundManager.Create(nil, TKeenAudioLock.Create, procedure begin end); end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenLockedSoundManager.Create(LInnerIntf, nil, procedure begin end); end, EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenLockedSoundManager.Create(LInnerIntf, TKeenAudioLock.Create, nil); end, EArgumentNilException);
end;

procedure TTestKeenAudio.IlLucchettoDovrebbeLasciarRientrareLoStessoThread;
var
  LLock: IKeenAudioLock;
begin
  LLock := TKeenAudioLock.Create;
  LLock.Enter;
  LLock.Enter;
  LLock.Leave;
  LLock.Leave;
  Assert.Pass;
end;

function TTestKeenAudio.RealManager(out ASpeaker: IKeenSampleSource; out ACard: IKeenSampleSource;
  out ALock: IKeenAudioLock; out AAudio: IKeenChunkSource): IKeenSoundManager;
var
  LFiles: IKeenDataFiles;
  LData: IKeenGameData;
  LSynth: TKeenSpeakerSynth;
  LOpl: TKeenOplAdLib;
begin
  LFiles := TKeenRealData.OpenFiles;
  if not Assigned(LFiles) then
    TTestSkip.Ignore('i file dello shareware di Keen Dreams non sono su questa macchina');
  LData := TKeenFactory.OpenGameData(LFiles);
  AAudio := LData.Audio;
  LSynth := TKeenSpeakerSynth.Create(RATE);
  ASpeaker := LSynth;
  LOpl := TKeenOplAdLib.Create(TOplFactory.CreateChip(KEEN_ADLIB_CLOCK, RATE));
  ACard := LOpl;
  ALock := TKeenAudioLock.Create;
  Result := TKeenSoundManager.Create(LData.Audio, LSynth, LOpl);
end;

procedure TTestKeenAudio.OgniSuonoDelloSharewareDovrebbeDareCampioniConLoAltoparlante;
var
  LSpeaker: IKeenSampleSource;
  LCard: IKeenSampleSource;
  LLock: IKeenAudioLock;
  LManager: IKeenSoundManager;
  LMixer: IKeenAudioMixer;
  LSound: Integer;
  LBefore: TKeenAudioStatistics;
  LAfter: TKeenAudioStatistics;
  LBytes: TBytes;
  LBlocks: Integer;
  LAudio: IKeenChunkSource;
  LPcSound: TKeenPcSound;
  LIndex: Integer;
  LLast: Byte;
  LTone: Boolean;
begin
  LManager := RealManager(LSpeaker, LCard, LLock, LAudio);
  LManager.TrySetMode(ksmPC);
  LMixer := TKeenAudioMixer.Create(LManager, [LSpeaker, LCard], LLock, RATE);
  SetLength(LBytes, 315 * 4);
  // the sound 0 reads as none (defect of the C kept): it starts at 1
  for LSound := 1 to KEEN_NUMSOUNDS - 1 do
  begin
    LManager.StopSound;
    LBefore := LMixer.Statistics;
    LManager.PlaySound(LSound);
    LBlocks := 0;
    while LManager.SoundPlaying <> 0 do
    begin
      LMixer.Render(@LBytes[0], Length(LBytes));
      Inc(LBlocks);
      Assert.IsTrue(LBlocks < 10000, 'the sound ' + IntToStr(LSound) + ' does not end');
    end;
    LAfter := LMixer.Statistics;
    // a sound makes a tone when a byte that is not 0 differs from the one before it (the first is compared to 255)
    LPcSound := TKeenPcSoundReader.Parse(LAudio.Read(KEEN_STARTPCSOUNDS + LSound));
    LTone := False;
    LLast := 255;
    for LIndex := 0 to Integer(LPcSound.Length) - 1 do
      if LIndex < Length(LPcSound.Data) then
      begin
        if (LPcSound.Data[LIndex] <> LLast) and (LPcSound.Data[LIndex] <> 0) then
          LTone := True;
        LLast := LPcSound.Data[LIndex];
      end;
    Assert.AreEqual(LTone, LAfter.AudibleFrames > LBefore.AudibleFrames, 'the sound ' + IntToStr(LSound));
  end;
  Assert.AreEqual(KEEN_SPEAKER_AMPLITUDE, LMixer.Statistics.Peak);
end;

procedure TTestKeenAudio.OgniSuonoDelloSharewareDovrebbeDareCampioniConLaScheda;
var
  LSpeaker: IKeenSampleSource;
  LCard: IKeenSampleSource;
  LLock: IKeenAudioLock;
  LManager: IKeenSoundManager;
  LMixer: IKeenAudioMixer;
  LSound: Integer;
  LBefore: TKeenAudioStatistics;
  LAfter: TKeenAudioStatistics;
  LBytes: TBytes;
  LBlocks: Integer;
  LSilent: string;
  LAudio: IKeenChunkSource;
begin
  LManager := RealManager(LSpeaker, LCard, LLock, LAudio);
  Assert.IsTrue(LManager.TrySetMode(ksmAdLib));
  LMixer := TKeenAudioMixer.Create(LManager, [LSpeaker, LCard], LLock, RATE);
  SetLength(LBytes, 315 * 4);
  LSilent := '';
  for LSound := 1 to KEEN_NUMSOUNDS - 1 do
  begin
    LManager.StopSound;
    // the release of the note before
    LMixer.Render(@LBytes[0], Length(LBytes));
    LBefore := LMixer.Statistics;
    LManager.PlaySound(LSound);
    LBlocks := 0;
    while LManager.SoundPlaying <> 0 do
    begin
      LMixer.Render(@LBytes[0], Length(LBytes));
      Inc(LBlocks);
      Assert.IsTrue(LBlocks < 10000, 'the sound ' + IntToStr(LSound) + ' does not end');
    end;
    LAfter := LMixer.Statistics;
    if LAfter.AudibleFrames = LBefore.AudibleFrames then
      LSilent := LSilent + ' ' + IntToStr(LSound);
  end;
  Assert.AreEqual('', LSilent, 'silent sounds');
  Assert.IsTrue(LMixer.Statistics.Peak > 1000, 'peak ' + IntToStr(LMixer.Statistics.Peak));
end;

end.
