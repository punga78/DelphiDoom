{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the sound effects of the AdLib   }
{  card and the modes of the sound manager                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.AdLib;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.Intf, DelphiDoom.Keen.AdLibSound, DelphiDoom.Keen.AdLibPlayer;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-sound')]
  TTestKeenAdLib = class(TObject)
  strict private
    FLog: TStringList;
    FPort: IKeenAdLibPort;
    FSpeaker: IKeenSpeaker;
    function Chunk(ALength: Cardinal; APriority: Word; ABlock: Byte; const AData: array of Byte): TBytes;
    function Manager(const AAdLibSounds: array of TBytes; AWithCard: Boolean = True): IKeenSoundManager;
    function Events: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure IRecordDovrebberoAvereLeDimensioniDelC;
    [Test]
    procedure DovrebbeLeggereStrumentoBloccoEDati;
    [Test]
    procedure DovrebbeDareZeriPerCioCheMancaDopoLaTestata;
    [Test]
    procedure DovrebbeRifiutareUnChunkSenzaLaTestataComune;
    [Test]
    procedure DovrebbeProgrammareLoStrumentoQuandoIlSuonoParte;
    [Test]
    procedure DovrebbeScrivereFrequenzaEBloccoPerOgniByte;
    [Test]
    procedure DovrebbeSpegnereLaNotaConUnByteZero;
    [Test]
    procedure DovrebbeSpegnereLaNotaEAvvisareAllaFine;
    [Test]
    procedure DovrebbeFinireSubitoUnSuonoDiLunghezzaZero;
    [Test]
    procedure DovrebbeDareIlSilenzioPerIByteCheMancano;
    [Test]
    procedure DovrebbeDareEccezioneAUnoStrumentoSospetto;
    [Test]
    procedure DovrebbeFermareSenzaAvvisare;
    [Test]
    procedure DovrebbeRifiutareLaSchedaNulla;
    [Test]
    procedure IlGestoreDovrebbeRifiutareLaModalitaAdLibSenzaScheda;
    [Test]
    procedure IlGestoreDovrebbeSpegnereEAccendereIDispositiviAlCambioDiModalita;
    [Test]
    procedure IlGestoreDovrebbeFermareIlSuonoAncheSeLaModalitaNonCambia;
    [Test]
    procedure IlGestoreDovrebbeSuonareConLaSchedaERispettareLaPriorita;
    [Test]
    procedure IlGestoreDovrebbeDareEccezioneAUnSuonoAdLibNonInMemoria;
    [Test]
    procedure LaModalitaPredefinitaDovrebbeEssereLaSchedaSeCE;
    [Test]
    procedure LaModalitaPredefinitaDovrebbeEssereLoAltoparlanteSenzaScheda;
    [Test]
    procedure LaModalitaSalvataDovrebbeValereSeIlDispositivoCE;
    [Test]
    procedure DovrebbeSuonareOgniSuonoAdLibDelloShareware;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Keen.SoundManager, DelphiDoom.Keen.Factory, DelphiDoom.Tests.Keen.RealData,
  DelphiDoom.Tests.Shared.Skip;

type
  TLogPort = class(TInterfacedObject, IKeenAdLibPort)
  strict private
    FLog: TStringList;
  public
    constructor Create(ALog: TStringList);
    procedure Write(ARegister, AValue: Byte);
  end;

  TLogSpeaker = class(TInterfacedObject, IKeenSpeaker)
  strict private
    FLog: TStringList;
  public
    constructor Create(ALog: TStringList);
    procedure Tone(ADivisor: Word);
    procedure Silence;
    procedure Stop;
  end;

  TFakeAudio = class(TInterfacedObject, IKeenChunkSource)
  strict private
    FChunks: TDictionary<Integer, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Put(AIndex: Integer; const ABytes: TBytes);
    function GetChunkCount: Integer;
    function HasChunk(AIndex: Integer): Boolean;
    function ReadCompressed(AIndex: Integer): TBytes;
    function Read(AIndex: Integer): TBytes;
  end;

{ TLogPort }

constructor TLogPort.Create(ALog: TStringList);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TLogPort.Write(ARegister, AValue: Byte);
begin
  FLog.Add(IntToHex(ARegister, 2) + '=' + IntToHex(AValue, 2));
end;

{ TLogSpeaker }

constructor TLogSpeaker.Create(ALog: TStringList);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TLogSpeaker.Tone(ADivisor: Word);
begin
  FLog.Add('tone ' + IntToStr(ADivisor));
end;

procedure TLogSpeaker.Silence;
begin
  FLog.Add('silence');
end;

procedure TLogSpeaker.Stop;
begin
  FLog.Add('stop');
end;

{ TFakeAudio }

constructor TFakeAudio.Create;
begin
  inherited Create;
  FChunks := TDictionary<Integer, TBytes>.Create;
end;

destructor TFakeAudio.Destroy;
begin
  FChunks.Free;
  inherited Destroy;
end;

procedure TFakeAudio.Put(AIndex: Integer; const ABytes: TBytes);
begin
  FChunks.AddOrSetValue(AIndex, ABytes);
end;

function TFakeAudio.GetChunkCount: Integer;
begin
  Result := KEEN_NUMSNDCHUNKS;
end;

function TFakeAudio.HasChunk(AIndex: Integer): Boolean;
begin
  Result := FChunks.ContainsKey(AIndex);
end;

function TFakeAudio.ReadCompressed(AIndex: Integer): TBytes;
begin
  Result := Read(AIndex);
end;

function TFakeAudio.Read(AIndex: Integer): TBytes;
begin
  if not FChunks.TryGetValue(AIndex, Result) then
    SetLength(Result, 0);
end;

{ TTestKeenAdLib }

procedure TTestKeenAdLib.Setup;
begin
  FLog := TStringList.Create;
  FPort := TLogPort.Create(FLog);
  FSpeaker := TLogSpeaker.Create(FLog);
end;

procedure TTestKeenAdLib.TearDown;
begin
  FPort := nil;
  FSpeaker := nil;
  FLog.Free;
end;

function TTestKeenAdLib.Events: string;
begin
  FLog.Delimiter := ',';
  FLog.StrictDelimiter := True;
  Result := FLog.DelimitedText;
end;

function TTestKeenAdLib.Chunk(ALength: Cardinal; APriority: Word; ABlock: Byte; const AData: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, KEEN_ADLIB_HEADER_BYTES + Length(AData));
  Result[0] := Byte(ALength);
  Result[1] := Byte(ALength shr 8);
  Result[2] := Byte(ALength shr 16);
  Result[3] := Byte(ALength shr 24);
  Result[4] := Byte(APriority);
  Result[5] := Byte(APriority shr 8);
  // the instrument: mChar, cChar, mScale, cScale, mAttack, cAttack, mSus, cSus, mWave, cWave, nConn
  for LIndex := 0 to 10 do
    Result[6 + LIndex] := $11 + LIndex;
  Result[22] := ABlock;
  for LIndex := 0 to High(AData) do
    Result[KEEN_ADLIB_HEADER_BYTES + LIndex] := AData[LIndex];
end;

function TTestKeenAdLib.Manager(const AAdLibSounds: array of TBytes; AWithCard: Boolean): IKeenSoundManager;
var
  LAudio: TFakeAudio;
  LIndex: Integer;
begin
  LAudio := TFakeAudio.Create;
  for LIndex := 0 to High(AAdLibSounds) do
  begin
    LAudio.Put(KEEN_STARTADLIBSOUNDS + LIndex, AAdLibSounds[LIndex]);
    // the PC sound of the same number: the common header and two tones
    LAudio.Put(KEEN_STARTPCSOUNDS + LIndex, TBytes.Create(2, 0, 0, 0, AAdLibSounds[LIndex][4], 0, 10, 20));
  end;
  if AWithCard then
    Result := TKeenSoundManager.Create(LAudio, FSpeaker, FPort)
  else
    Result := TKeenSoundManager.Create(LAudio, FSpeaker, nil);
end;

procedure TTestKeenAdLib.IRecordDovrebberoAvereLeDimensioniDelC;
begin
  Assert.AreEqual(16, SizeOf(TKeenAdLibInstrument));
  Assert.AreEqual(6, SizeOf(TKeenSoundCommon));
  Assert.AreEqual(23, KEEN_ADLIB_HEADER_BYTES);
end;

procedure TTestKeenAdLib.DovrebbeLeggereStrumentoBloccoEDati;
var
  LSound: TKeenAdLibSound;
begin
  LSound := TKeenAdLibSoundReader.Parse(Chunk(70000, 513, 5, [9, 8, 7]));
  Assert.AreEqual(Cardinal(70000), LSound.Length);
  Assert.AreEqual(513, Integer(LSound.Priority));
  Assert.AreEqual($11, Integer(LSound.Instrument.ModulatorChar));
  Assert.AreEqual($12, Integer(LSound.Instrument.CarrierChar));
  Assert.AreEqual($17, Integer(LSound.Instrument.ModulatorSustain));
  Assert.AreEqual($18, Integer(LSound.Instrument.CarrierSustain));
  Assert.AreEqual($1A, Integer(LSound.Instrument.CarrierWave));
  Assert.AreEqual($1B, Integer(LSound.Instrument.Connection));
  Assert.AreEqual(5, Integer(LSound.Block));
  Assert.AreEqual<Integer>(3, Length(LSound.Data));
  Assert.AreEqual(7, Integer(LSound.Data[2]));
end;

procedure TTestKeenAdLib.DovrebbeDareZeriPerCioCheMancaDopoLaTestata;
var
  LSound: TKeenAdLibSound;
begin
  // 6 bytes of SoundCommon and 3 of the instrument: the rest of the instrument and the block are 0
  LSound := TKeenAdLibSoundReader.Parse(TBytes.Create(4, 0, 0, 0, 2, 0, $A1, $A2, $A3));
  Assert.AreEqual(Cardinal(4), LSound.Length);
  Assert.AreEqual($A3, Integer(LSound.Instrument.ModulatorScale));
  Assert.AreEqual(0, Integer(LSound.Instrument.CarrierScale));
  Assert.AreEqual(0, Integer(LSound.Block));
  Assert.AreEqual<Integer>(0, Length(LSound.Data));
end;

procedure TTestKeenAdLib.DovrebbeRifiutareUnChunkSenzaLaTestataComune;
begin
  Assert.WillRaise(procedure begin TKeenAdLibSoundReader.Parse(TBytes.Create(1, 2, 3, 4, 5)); end, EKeenDataException);
end;

procedure TTestKeenAdLib.DovrebbeProgrammareLoStrumentoQuandoIlSuonoParte;
var
  LPlayer: TKeenAdLibPlayer;
begin
  LPlayer := TKeenAdLibPlayer.Create(FPort);
  try
    LPlayer.Play(TKeenAdLibSoundReader.Parse(Chunk(2, 1, 3, [5, 6])));
    // the note off of SDL_ALStopSound, then the modulator (cell 0) and the carrier (cell 3)
    Assert.AreEqual('B0=00,20=11,40=13,60=15,80=17,E0=19,23=12,43=14,63=16,83=18,E3=1A', Events);
    Assert.IsTrue(LPlayer.Playing);
  finally
    LPlayer.Free;
  end;
end;

procedure TTestKeenAdLib.DovrebbeScrivereFrequenzaEBloccoPerOgniByte;
var
  LPlayer: TKeenAdLibPlayer;
begin
  LPlayer := TKeenAdLibPlayer.Create(FPort);
  try
    // the block 13: only its 3 low bits count (5), shifted by 2 with the key on bit
    LPlayer.Play(TKeenAdLibSoundReader.Parse(Chunk(9, 1, 13, [$40, $41])));
    FLog.Clear;
    LPlayer.Service;
    LPlayer.Service;
    Assert.AreEqual('A0=40,B0=34,A0=41,B0=34', Events);
  finally
    LPlayer.Free;
  end;
end;

procedure TTestKeenAdLib.DovrebbeSpegnereLaNotaConUnByteZero;
var
  LPlayer: TKeenAdLibPlayer;
begin
  LPlayer := TKeenAdLibPlayer.Create(FPort);
  try
    LPlayer.Play(TKeenAdLibSoundReader.Parse(Chunk(9, 1, 1, [$40, 0, 0, $50])));
    FLog.Clear;
    LPlayer.Service;
    LPlayer.Service;
    LPlayer.Service;
    LPlayer.Service;
    // unlike the PC speaker, the same byte is written again at each service
    Assert.AreEqual('A0=40,B0=24,B0=00,B0=00,A0=50,B0=24', Events);
  finally
    LPlayer.Free;
  end;
end;

procedure TTestKeenAdLib.DovrebbeSpegnereLaNotaEAvvisareAllaFine;
var
  LPlayer: TKeenAdLibPlayer;
  LFinished: Integer;
begin
  LFinished := 0;
  LPlayer := TKeenAdLibPlayer.Create(FPort);
  try
    LPlayer.OnFinished := procedure begin Inc(LFinished); end;
    LPlayer.Play(TKeenAdLibSoundReader.Parse(Chunk(2, 1, 0, [7, 8])));
    FLog.Clear;
    LPlayer.Service;
    Assert.IsTrue(LPlayer.Playing);
    LPlayer.Service;
    Assert.IsFalse(LPlayer.Playing);
    Assert.AreEqual(1, LFinished);
    LPlayer.Service; // nothing more
    Assert.AreEqual('A0=07,B0=20,A0=08,B0=20,B0=00', Events);
  finally
    LPlayer.Free;
  end;
end;

procedure TTestKeenAdLib.DovrebbeFinireSubitoUnSuonoDiLunghezzaZero;
var
  LPlayer: TKeenAdLibPlayer;
begin
  // the C counts down from 4 billion and plays what is after the data: here the sound ends at the first service
  LPlayer := TKeenAdLibPlayer.Create(FPort);
  try
    LPlayer.Play(TKeenAdLibSoundReader.Parse(Chunk(0, 1, 0, [9, 9])));
    FLog.Clear;
    LPlayer.Service;
    Assert.IsFalse(LPlayer.Playing);
    Assert.AreEqual('B0=00', Events);
  finally
    LPlayer.Free;
  end;
end;

procedure TTestKeenAdLib.DovrebbeDareIlSilenzioPerIByteCheMancano;
var
  LPlayer: TKeenAdLibPlayer;
begin
  LPlayer := TKeenAdLibPlayer.Create(FPort);
  try
    LPlayer.Play(TKeenAdLibSoundReader.Parse(Chunk(3, 1, 0, [5])));
    FLog.Clear;
    LPlayer.Service;
    LPlayer.Service;
    LPlayer.Service;
    Assert.AreEqual('A0=05,B0=20,B0=00,B0=00,B0=00', Events);
  finally
    LPlayer.Free;
  end;
end;

procedure TTestKeenAdLib.DovrebbeDareEccezioneAUnoStrumentoSospetto;
var
  LPlayer: TKeenAdLibPlayer;
  LChunk: TBytes;
begin
  LChunk := Chunk(3, 1, 0, [5]);
  LChunk[6 + 6] := 0;
  LChunk[6 + 7] := 0;
  LPlayer := TKeenAdLibPlayer.Create(FPort);
  try
    Assert.WillRaise(procedure begin LPlayer.Play(TKeenAdLibSoundReader.Parse(LChunk)); end, EKeenException);
    Assert.IsFalse(LPlayer.Playing);
  finally
    LPlayer.Free;
  end;
end;

procedure TTestKeenAdLib.DovrebbeFermareSenzaAvvisare;
var
  LPlayer: TKeenAdLibPlayer;
  LFinished: Boolean;
begin
  LFinished := False;
  LPlayer := TKeenAdLibPlayer.Create(FPort);
  try
    LPlayer.OnFinished := procedure begin LFinished := True; end;
    LPlayer.Play(TKeenAdLibSoundReader.Parse(Chunk(5, 1, 0, [7, 7, 7, 7, 7])));
    LPlayer.Service;
    FLog.Clear;
    LPlayer.Stop;
    Assert.IsFalse(LPlayer.Playing);
    Assert.IsFalse(LFinished);
    Assert.AreEqual('B0=00', Events);
  finally
    LPlayer.Free;
  end;
end;

procedure TTestKeenAdLib.DovrebbeRifiutareLaSchedaNulla;
begin
  Assert.WillRaise(procedure begin TKeenAdLibPlayer.Create(nil); end, EArgumentNilException);
end;

procedure TTestKeenAdLib.IlGestoreDovrebbeRifiutareLaModalitaAdLibSenzaScheda;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(2, 1, 0, [1, 2])], False);
  Assert.IsFalse(LManager.AdLibPresent);
  Assert.IsFalse(LManager.TrySetMode(ksmAdLib));
  Assert.AreEqual(Ord(ksmPC), Ord(LManager.Mode));
end;

procedure TTestKeenAdLib.IlGestoreDovrebbeSpegnereEAccendereIDispositiviAlCambioDiModalita;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(2, 1, 0, [1, 2])]);
  Assert.IsTrue(LManager.AdLibPresent);
  // from the PC speaker to the card: SD_StopSound, SDL_ShutPC, SDL_StartAL
  Assert.IsTrue(LManager.TrySetMode(ksmAdLib));
  Assert.AreEqual('stop,silence,BD=00', Events);
  FLog.Clear;
  // and back: SD_StopSound (note off), SDL_ShutAL
  Assert.IsTrue(LManager.TrySetMode(ksmPC));
  Assert.AreEqual('B0=00,BD=00,B0=00', Events);
end;

procedure TTestKeenAdLib.IlGestoreDovrebbeFermareIlSuonoAncheSeLaModalitaNonCambia;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(2, 1, 0, [1, 2]), Chunk(9, 1, 0, [1, 2, 3])]);
  LManager.TrySetMode(ksmAdLib);
  LManager.PlaySound(1);
  FLog.Clear;
  Assert.IsTrue(LManager.TrySetMode(ksmAdLib));
  Assert.AreEqual('B0=00', Events);
  Assert.AreEqual(0, LManager.SoundPlaying);
end;

procedure TTestKeenAdLib.IlGestoreDovrebbeSuonareConLaSchedaERispettareLaPriorita;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(1, 1, 0, [1]), Chunk(3, 5, 0, [$21, $22, $23]), Chunk(3, 2, 0, [$31, $32, $33])]);
  LManager.TrySetMode(ksmAdLib);
  LManager.PlaySound(1);
  Assert.AreEqual(1, LManager.SoundPlaying);
  FLog.Clear;
  LManager.PlaySound(2); // lower priority: ignored
  LManager.Service;
  Assert.AreEqual('A0=21,B0=20', Events);
  LManager.Service;
  LManager.Service;
  Assert.AreEqual(0, LManager.SoundPlaying);
  LManager.PlaySound(2); // the priority is free again
  Assert.AreEqual(2, LManager.SoundPlaying);
  LManager.WaitSoundDone;
  Assert.AreEqual(0, LManager.SoundPlaying);
end;

procedure TTestKeenAdLib.IlGestoreDovrebbeDareEccezioneAUnSuonoAdLibNonInMemoria;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(1, 1, 0, [1])]);
  LManager.TrySetMode(ksmAdLib);
  Assert.WillRaise(procedure begin LManager.PlaySound(5); end, EKeenException);
  Assert.WillRaise(procedure begin LManager.PlaySound(KEEN_NUMSOUNDS); end, EKeenException);
end;

procedure TTestKeenAdLib.LaModalitaPredefinitaDovrebbeEssereLaSchedaSeCE;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(1, 1, 0, [1])]);
  LManager.SetDefault(False, ksmOff);
  Assert.AreEqual(Ord(ksmAdLib), Ord(LManager.Mode));
end;

procedure TTestKeenAdLib.LaModalitaPredefinitaDovrebbeEssereLoAltoparlanteSenzaScheda;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(1, 1, 0, [1])], False);
  LManager.SetDefault(False, ksmOff);
  Assert.AreEqual(Ord(ksmPC), Ord(LManager.Mode));
  // the saved mode asks for a card that is not there
  LManager.SetDefault(True, ksmAdLib);
  Assert.AreEqual(Ord(ksmPC), Ord(LManager.Mode));
end;

procedure TTestKeenAdLib.LaModalitaSalvataDovrebbeValereSeIlDispositivoCE;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(1, 1, 0, [1])]);
  LManager.SetDefault(True, ksmOff);
  Assert.AreEqual(Ord(ksmOff), Ord(LManager.Mode));
  LManager.SetDefault(True, ksmAdLib);
  Assert.AreEqual(Ord(ksmAdLib), Ord(LManager.Mode));
  LManager.SetDefault(True, ksmPC);
  Assert.AreEqual(Ord(ksmPC), Ord(LManager.Mode));
end;

procedure TTestKeenAdLib.DovrebbeSuonareOgniSuonoAdLibDelloShareware;
var
  LFiles: IKeenDataFiles;
  LData: IKeenGameData;
  LManager: IKeenSoundManager;
  LSound: Integer;
  LTicks: Integer;
  LPlayed: Integer;
begin
  LFiles := TKeenRealData.OpenFiles;
  if not Assigned(LFiles) then
    TTestSkip.Ignore('i file dello shareware di Keen Dreams non sono su questa macchina');
  LData := TKeenFactory.OpenGameData(LFiles);
  LManager := TKeenSoundManager.Create(LData.Audio, FSpeaker, FPort);
  Assert.IsTrue(LManager.TrySetMode(ksmAdLib));
  LPlayed := 0;
  for LSound := 0 to KEEN_NUMSOUNDS - 1 do
  begin
    FLog.Clear;
    LManager.StopSound;
    LManager.PlaySound(LSound);
    Inc(LPlayed);
    LTicks := 0;
    while LManager.SoundPlaying <> 0 do
    begin
      LManager.Service;
      Inc(LTicks);
      Assert.IsTrue(LTicks <= 100000, 'the sound ' + IntToStr(LSound) + ' does not end');
    end;
    // the instrument was programmed: the note off and ten registers
    Assert.IsTrue(FLog.Count >= 11, 'the sound ' + IntToStr(LSound));
  end;
  Assert.AreEqual(KEEN_NUMSOUNDS, LPlayed);
end;

end.
