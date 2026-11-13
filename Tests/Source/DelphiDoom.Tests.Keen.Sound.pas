{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the PC speaker and the sound    }
{  manager                                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Sound;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.Intf, DelphiDoom.Keen.PcSpeaker;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-sound')]
  TTestKeenSound = class(TObject)
  strict private
    FLog: TStringList;
    FSpeaker: IKeenSpeaker;
    function Chunk(ALength: Cardinal; APriority: Word; const AData: array of Byte): TBytes;
    function Manager(const ASounds: array of TBytes): IKeenSoundManager;
    function Events: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLungezzaPrioritaEDatiDiUnSuono;
    [Test]
    procedure DovrebbeRifiutareUnChunkTroppoCorto;
    [Test]
    procedure DovrebbeDareIlSilenzioPerIByteCheMancano;
    [Test]
    procedure DovrebbeDareLaFrequenzaDiUnByte;
    [Test]
    procedure DovrebbeProgrammareLoAltoparlanteSoloQuandoIlByteCambia;
    [Test]
    procedure DovrebbeSpegnereLoAltoparlanteConUnZero;
    [Test]
    procedure DovrebbeSuonareUnPrimoByteDiDuecentocinquantacinque;
    [Test]
    procedure DovrebbeFermareLoAltoparlanteAllaFineDelSuono;
    [Test]
    procedure DovrebbeFinireSubitoUnSuonoDiLunghezzaZero;
    [Test]
    procedure DovrebbeFermareASecondaRichiestaSenzaAvvisare;
    [Test]
    procedure DovrebbeNonFareNullaSeNonSuona;
    [Test]
    procedure DovrebbeIgnorareUnSuonoDiPrioritaPiuBassa;
    [Test]
    procedure DovrebbeSostituireConUnSuonoDiPrioritaUguale;
    [Test]
    procedure DovrebbeTornareAllaPrioritaZeroQuandoIlSuonoFinisce;
    [Test]
    procedure DovrebbeDareIlNumeroDelSuonoCheSuona;
    [Test]
    procedure DovrebbeLeggereIlSuonoZeroComeNessuno;
    [Test]
    procedure DovrebbeFermareIlSuono;
    [Test]
    procedure DovrebbeAspettareLaFineDelSuono;
    [Test]
    procedure DovrebbeDareEccezioneAUnSuonoNonInMemoria;
    [Test]
    procedure DovrebbeTacereConLaModalitaSpenta;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
    [Test]
    procedure DovrebbeSuonareOgniSuonoDelloShareware;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Keen.SoundManager, DelphiDoom.Keen.Factory, DelphiDoom.Tests.Keen.RealData;

type
  TLogSpeaker = class(TInterfacedObject, IKeenSpeaker)
  strict private
    FLog: TStringList;
  public
    constructor Create(ALog: TStringList);
    procedure Tone(ADivisor: Word);
    procedure Silence;
    procedure Stop;
  end;

  /// <summary>An audio file of a test: the chunks are what the test gives, the others have no data</summary>
  TFakeAudio = class(TInterfacedObject, IKeenChunkSource)
  strict private
    FChunks: TDictionary<Integer, TBytes>;
  public
    constructor Create(const ASounds: array of TBytes);
    destructor Destroy; override;
    function GetChunkCount: Integer;
    function HasChunk(AIndex: Integer): Boolean;
    function ReadCompressed(AIndex: Integer): TBytes;
    function Read(AIndex: Integer): TBytes;
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

constructor TFakeAudio.Create(const ASounds: array of TBytes);
var
  LIndex: Integer;
begin
  inherited Create;
  FChunks := TDictionary<Integer, TBytes>.Create;
  for LIndex := 0 to High(ASounds) do
    if Length(ASounds[LIndex]) > 0 then
      FChunks.Add(LIndex, ASounds[LIndex]);
end;

destructor TFakeAudio.Destroy;
begin
  FChunks.Free;
  inherited Destroy;
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

{ TTestKeenSound }

function TTestKeenSound.Events: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FLog.Count - 1 do
    if LIndex = 0 then
      Result := FLog[LIndex]
    else
      Result := Result + ',' + FLog[LIndex];
end;

procedure TTestKeenSound.Setup;
begin
  FLog := TStringList.Create;
  FSpeaker := TLogSpeaker.Create(FLog);
end;

procedure TTestKeenSound.TearDown;
begin
  FSpeaker := nil;
  FLog.Free;
end;

function TTestKeenSound.Chunk(ALength: Cardinal; APriority: Word; const AData: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 6 + Length(AData));
  Result[0] := Byte(ALength);
  Result[1] := Byte(ALength shr 8);
  Result[2] := Byte(ALength shr 16);
  Result[3] := Byte(ALength shr 24);
  Result[4] := Byte(APriority);
  Result[5] := Byte(APriority shr 8);
  for LIndex := 0 to High(AData) do
    Result[6 + LIndex] := AData[LIndex];
end;

function TTestKeenSound.Manager(const ASounds: array of TBytes): IKeenSoundManager;
begin
  Result := TKeenSoundManager.Create(TFakeAudio.Create(ASounds), FSpeaker);
end;

procedure TTestKeenSound.DovrebbeLeggereLungezzaPrioritaEDatiDiUnSuono;
var
  LSound: TKeenPcSound;
begin
  LSound := TKeenPcSoundReader.Parse(Chunk(70000, 513, [1, 2, 3]));
  Assert.AreEqual(Cardinal(70000), LSound.Length);
  Assert.AreEqual(513, Integer(LSound.Priority));
  Assert.AreEqual<Integer>(3, Length(LSound.Data));
  Assert.AreEqual(3, Integer(LSound.Data[2]));
end;

procedure TTestKeenSound.DovrebbeRifiutareUnChunkTroppoCorto;
begin
  Assert.WillRaise(procedure begin TKeenPcSoundReader.Parse(TBytes.Create(1, 2, 3)); end, EKeenDataException);
end;

procedure TTestKeenSound.DovrebbeDareIlSilenzioPerIByteCheMancano;
var
  LSpeaker: TKeenPcSpeaker;
begin
  LSpeaker := TKeenPcSpeaker.Create(FSpeaker);
  try
    // the length says 3 and the data have 1 byte: the other two ticks are silence
    LSpeaker.Play(TKeenPcSoundReader.Parse(Chunk(3, 1, [5])));
    LSpeaker.Service;
    LSpeaker.Service;
    LSpeaker.Service;
    Assert.AreEqual('tone 300,silence,stop', Events);
  finally
    LSpeaker.Free;
  end;
end;

procedure TTestKeenSound.DovrebbeDareLaFrequenzaDiUnByte;
begin
  Assert.AreEqual(0.0, TKeenPcSoundReader.Frequency(0), 0.0001);
  Assert.AreEqual(1193181 / 600, TKeenPcSoundReader.Frequency(10), 0.0001);
end;

procedure TTestKeenSound.DovrebbeProgrammareLoAltoparlanteSoloQuandoIlByteCambia;
var
  LSpeaker: TKeenPcSpeaker;
  LIndex: Integer;
begin
  LSpeaker := TKeenPcSpeaker.Create(FSpeaker);
  try
    LSpeaker.Play(TKeenPcSoundReader.Parse(Chunk(4, 1, [10, 10, 20, 20])));
    for LIndex := 1 to 4 do
      LSpeaker.Service;
    Assert.AreEqual('tone 600,tone 1200,stop', Events);
  finally
    LSpeaker.Free;
  end;
end;

procedure TTestKeenSound.DovrebbeSpegnereLoAltoparlanteConUnZero;
var
  LSpeaker: TKeenPcSpeaker;
  LIndex: Integer;
begin
  LSpeaker := TKeenPcSpeaker.Create(FSpeaker);
  try
    LSpeaker.Play(TKeenPcSoundReader.Parse(Chunk(4, 1, [10, 0, 0, 10])));
    for LIndex := 1 to 4 do
      LSpeaker.Service;
    Assert.AreEqual('tone 600,silence,tone 600,stop', Events);
  finally
    LSpeaker.Free;
  end;
end;

procedure TTestKeenSound.DovrebbeSuonareUnPrimoByteDiDuecentocinquantacinque;
var
  LSpeaker: TKeenPcSpeaker;
begin
  // the last byte starts at 255 (byte -1): a sound that begins with 255 does not program the timer (defect of the C kept)
  LSpeaker := TKeenPcSpeaker.Create(FSpeaker);
  try
    LSpeaker.Play(TKeenPcSoundReader.Parse(Chunk(1, 1, [255])));
    LSpeaker.Service;
    Assert.AreEqual('stop', Events);
  finally
    LSpeaker.Free;
  end;
end;

procedure TTestKeenSound.DovrebbeFermareLoAltoparlanteAllaFineDelSuono;
var
  LSpeaker: TKeenPcSpeaker;
  LFinished: Integer;
begin
  LFinished := 0;
  LSpeaker := TKeenPcSpeaker.Create(FSpeaker);
  try
    LSpeaker.OnFinished := procedure begin Inc(LFinished); end;
    LSpeaker.Play(TKeenPcSoundReader.Parse(Chunk(2, 1, [7, 8])));
    Assert.IsTrue(LSpeaker.Playing);
    LSpeaker.Service;
    Assert.IsTrue(LSpeaker.Playing);
    LSpeaker.Service;
    Assert.IsFalse(LSpeaker.Playing);
    Assert.AreEqual(1, LFinished);
    LSpeaker.Service; // nothing more
    Assert.AreEqual('tone 420,tone 480,stop', Events);
  finally
    LSpeaker.Free;
  end;
end;

procedure TTestKeenSound.DovrebbeFinireSubitoUnSuonoDiLunghezzaZero;
var
  LSpeaker: TKeenPcSpeaker;
begin
  // the C counts down from 4 billion and plays what is after the data: here the sound ends at the first service
  LSpeaker := TKeenPcSpeaker.Create(FSpeaker);
  try
    LSpeaker.Play(TKeenPcSoundReader.Parse(Chunk(0, 1, [9, 9, 9])));
    LSpeaker.Service;
    Assert.IsFalse(LSpeaker.Playing);
  finally
    LSpeaker.Free;
  end;
end;

procedure TTestKeenSound.DovrebbeFermareASecondaRichiestaSenzaAvvisare;
var
  LSpeaker: TKeenPcSpeaker;
  LFinished: Boolean;
begin
  LFinished := False;
  LSpeaker := TKeenPcSpeaker.Create(FSpeaker);
  try
    LSpeaker.OnFinished := procedure begin LFinished := True; end;
    LSpeaker.Play(TKeenPcSoundReader.Parse(Chunk(5, 1, [7, 7, 7, 7, 7])));
    LSpeaker.Service;
    LSpeaker.Stop;
    Assert.IsFalse(LSpeaker.Playing);
    Assert.IsFalse(LFinished);
  finally
    LSpeaker.Free;
  end;
end;

procedure TTestKeenSound.DovrebbeNonFareNullaSeNonSuona;
var
  LSpeaker: TKeenPcSpeaker;
begin
  LSpeaker := TKeenPcSpeaker.Create(FSpeaker);
  try
    LSpeaker.Service;
    Assert.AreEqual(0, FLog.Count);
  finally
    LSpeaker.Free;
  end;
end;

procedure TTestKeenSound.DovrebbeIgnorareUnSuonoDiPrioritaPiuBassa;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(4, 5, [10, 10, 10, 10]), Chunk(4, 3, [20, 20, 20, 20])]);
  LManager.PlaySound(0);
  LManager.PlaySound(1);
  LManager.Service;
  Assert.AreEqual('tone 600', Events);
end;

procedure TTestKeenSound.DovrebbeSostituireConUnSuonoDiPrioritaUguale;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(4, 5, [10, 10, 10, 10]), Chunk(4, 5, [20, 20, 20, 20])]);
  LManager.PlaySound(0);
  LManager.Service;
  LManager.PlaySound(1);
  LManager.Service;
  Assert.AreEqual('tone 600,tone 1200', Events);
  Assert.AreEqual(1, LManager.SoundPlaying);
end;

procedure TTestKeenSound.DovrebbeTornareAllaPrioritaZeroQuandoIlSuonoFinisce;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(1, 9, [10]), Chunk(2, 1, [20, 20])]);
  LManager.PlaySound(0);
  LManager.Service;
  Assert.AreEqual(0, LManager.SoundPlaying);
  // the high priority sound is over: a low one plays
  LManager.PlaySound(1);
  Assert.AreEqual(1, LManager.SoundPlaying);
end;

procedure TTestKeenSound.DovrebbeDareIlNumeroDelSuonoCheSuona;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(2, 1, [1, 1]), Chunk(2, 1, [2, 2]), Chunk(2, 1, [3, 3])]);
  LManager.PlaySound(2);
  Assert.AreEqual(2, LManager.SoundPlaying);
  LManager.Service;
  LManager.Service;
  Assert.AreEqual(0, LManager.SoundPlaying);
end;

procedure TTestKeenSound.DovrebbeLeggereIlSuonoZeroComeNessuno;
var
  LManager: IKeenSoundManager;
begin
  // defect of the C kept: SD_SoundPlaying gives the number of the sound, so the sound 0 looks like silence
  LManager := Manager([Chunk(3, 1, [1, 1, 1])]);
  LManager.PlaySound(0);
  Assert.AreEqual(0, LManager.SoundPlaying);
  LManager.WaitSoundDone;
  Assert.AreEqual('', Events, 'WaitSoundDone does not wait for the sound 0');
end;

procedure TTestKeenSound.DovrebbeFermareIlSuono;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(9, 1, [1, 1, 1]), Chunk(9, 1, [4, 4, 4])]);
  LManager.PlaySound(1);
  LManager.Service;
  LManager.StopSound;
  Assert.AreEqual(0, LManager.SoundPlaying);
  Assert.AreEqual('tone 240,stop', Events);
  // the priority is free again
  LManager.PlaySound(0);
  Assert.AreEqual(0, LManager.SoundPlaying, 'the sound 0 reads as none');
end;

procedure TTestKeenSound.DovrebbeAspettareLaFineDelSuono;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(1, 1, [1]), Chunk(3, 1, [2, 3, 4])]);
  LManager.PlaySound(1);
  LManager.WaitSoundDone;
  Assert.AreEqual(0, LManager.SoundPlaying);
  Assert.AreEqual('tone 120,tone 180,tone 240,stop', Events);
end;

procedure TTestKeenSound.DovrebbeDareEccezioneAUnSuonoNonInMemoria;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(1, 1, [1])]);
  Assert.WillRaise(procedure begin LManager.PlaySound(5); end, EKeenException);
  Assert.WillRaise(procedure begin LManager.PlaySound(-1); end, EKeenException);
  Assert.WillRaise(procedure begin LManager.PlaySound(KEEN_NUMSOUNDS); end, EKeenException);
end;

procedure TTestKeenSound.DovrebbeTacereConLaModalitaSpenta;
var
  LManager: IKeenSoundManager;
begin
  LManager := Manager([Chunk(2, 1, [1, 1]), Chunk(2, 1, [2, 2])]);
  LManager.PlaySound(1);
  LManager.Mode := ksmOff;
  Assert.AreEqual(Ord(ksmOff), Ord(LManager.Mode));
  Assert.AreEqual(0, LManager.SoundPlaying);
  // with the mode off a sound that is not cached is not an error either (the C returns first)
  LManager.PlaySound(20);
  LManager.Service;
  LManager.Mode := ksmPC;
  LManager.PlaySound(1);
  Assert.AreEqual(1, LManager.SoundPlaying);
end;

procedure TTestKeenSound.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(procedure begin TKeenPcSpeaker.Create(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenSoundManager.Create(nil, FSpeaker); end, EArgumentNilException);
end;

procedure TTestKeenSound.DovrebbeSuonareOgniSuonoDelloShareware;
var
  LFiles: IKeenDataFiles;
  LData: IKeenGameData;
  LManager: IKeenSoundManager;
  LSound: Integer;
  LCached: Integer;
  LChunk: TBytes;
  LTicks: Integer;
begin
  LFiles := TKeenRealData.OpenFiles;
  if not Assigned(LFiles) then
  begin
    Assert.Pass('The files of the shareware are not here');
    Exit;
  end;
  LData := TKeenFactory.OpenGameData(LFiles);
  LManager := TKeenSoundManager.Create(LData.Audio, FSpeaker);
  LCached := 0;
  for LSound := 0 to KEEN_NUMSOUNDS - 1 do
  begin
    LChunk := LData.Audio.Read(LSound);
    if Length(LChunk) < 6 then
      Continue;
    Inc(LCached);
    FLog.Clear;
    LManager.StopSound;
    LManager.PlaySound(LSound);
    LTicks := 0;
    while LManager.SoundPlaying <> 0 do
    begin
      LManager.Service;
      Inc(LTicks);
      Assert.IsTrue(LTicks <= 100000, 'the sound ' + IntToStr(LSound) + ' does not end');
    end;
    if LSound <> 0 then
      Assert.IsTrue(FLog.Count > 0);
  end;
  Assert.IsTrue(LCached > 0);
end;

end.
