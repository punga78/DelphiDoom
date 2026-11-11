{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the X-COM Adlib player                                  }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\Opl\README.md                                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Opl.Player;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.CatArchive, DelphiDoom.Opl.Intf,
  DelphiDoom.Opl.Factory, DelphiDoom.XcomAdlib.Types, DelphiDoom.XcomAdlib.Intf, DelphiDoom.XcomAdlib.RegisterWriter,
  DelphiDoom.XcomAdlib.Factory, DelphiDoom.Tests.Opl.Recorder;

type
  [TestFixture]
  [Category('opl')]
  [Category('xcom-adlib')]
  TTestXcomAdlibPlayer = class(TObject)
  private
    /// <summary>A song with a name of 0 characters, one sample, no subtrack and one track with the given events</summary>
    function BuildSong(const AEvents: array of Byte; ASubtracks: Integer = 0): TBytes;
    function Play(const ASong: TBytes): IXcomAdlibPlayer;
    function Render(const APlayer: IXcomAdlibPlayer; ABytes: Integer): TArray<SmallInt>;
    function Silent(const ABuffer: TArray<SmallInt>): Boolean;
  public
    [Test]
    procedure DovrebbeSuonareUnBranoSemplice;
    [Test]
    procedure DovrebbeFinireQuandoIlBranoArrivaAllaFine;
    [Test]
    procedure DovrebbeFermareIlBranoConStop;
    [Test]
    procedure DovrebbeDareSilenzioDopoLoStop;
    [Test]
    procedure DovrebbeRifiutareUnaFrequenzaDiCampionamentoSenzaDurataDelTick;
    [Test]
    procedure DovrebbeRifiutareUnPlayDiUnBranoNonCaricato;
    [Test]
    procedure DovrebbeRifiutareUnBranoVuoto;
    [Test]
    procedure DovrebbeRifiutareUnRenderCheNonSiaUnNumeroIntero_DiCampioniStereo;
    [Test]
    procedure DovrebbeRifiutareUnRenderPiuGrandeDelBuffer;
    [Test]
    procedure DovrebbeFermareIlBranoEdareErroreSeIDatiFinisconoACaso;
    [Test]
    procedure DovrebbeDareErroreSeUnaNotaEFuoriDallaTabella;
    [Test]
    procedure DovrebbeDareErroreSeUnSubtrackNonEsiste;
    [Test]
    procedure DovrebbeDareErroreSeIBrani_SuperanoLaTabellaDelleSubtrack;
    [Test]
    procedure DovrebbeRifiutareUnoStatoDelBranoCheNonEsiste;
    [Test]
    procedure DovrebbeScrivereAlSecondoChipLaCopiaTrasposta;
    [Test]
    procedure DovrebbeTogliereTremoloEVibratoAlSecondoChip;
    [Test]
    procedure DovrebbeLasciareSoloLeOndeSinusoidaliAgliOperatoriPortanti;
    [Test]
    procedure DovrebbeRifiutareUnRegistroCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnPlayerSenzaChip;
    [Test]
    procedure DovrebbeLeggereIBraniDiUnContenitoreCat;
  end;

implementation

const
  /// <summary>The sample of the test: sine waves, a fast attack, a long sustain</summary>
  TEST_SAMPLE: array[0..23] of Byte = ($01, $01, $10, $00, $F0, $F0, $77, $77, $00, $00, $00, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0);

{ TTestXcomAdlibPlayer }

function TTestXcomAdlibPlayer.BuildSong(const AEvents: array of Byte; ASubtracks: Integer): TBytes;
var
  LIndex: Integer;
  LLength: Integer;

  procedure Add(AValue: Byte);
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := AValue;
  end;

begin
  SetLength(Result, 0);
  Add(0); // no name: format 1
  Add(100); // tempo
  Add(1); // samples
  for LIndex := 0 to 23 do
    Add(TEST_SAMPLE[LIndex]);
  Add(ASubtracks);
  Add(1); // tracks
  LLength := 5 + Length(AEvents);
  Add(LLength and $FF);
  Add(LLength shr 8);
  Add(0);
  Add(0);
  Add(0); // instrument 0
  for LIndex := 0 to High(AEvents) do
    Add(AEvents[LIndex]);
end;

function TTestXcomAdlibPlayer.Play(const ASong: TBytes): IXcomAdlibPlayer;
begin
  Result := TXcomAdlibFactory.CreatePlayer(22050);
  Result.Load(ASong);
  Result.Play(1.0);
end;

function TTestXcomAdlibPlayer.Render(const APlayer: IXcomAdlibPlayer; ABytes: Integer): TArray<SmallInt>;
begin
  SetLength(Result, ABytes div 2);
  APlayer.Render(Result, ABytes, 1.0);
end;

function TTestXcomAdlibPlayer.Silent(const ABuffer: TArray<SmallInt>): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ABuffer) do
    if ABuffer[LIndex] <> 0 then
      Exit(False);
  Result := True;
end;

procedure TTestXcomAdlibPlayer.DovrebbeSuonareUnBranoSemplice;
var
  LPlayer: IXcomAdlibPlayer;
begin
  // initial delay 0, the volume of the track, a note, a delay, the end of the track
  LPlayer := Play(BuildSong([$00, $B0, $07, $7F, $00, $90, $40, $7F, $FF, $01, $FF]));
  Assert.IsTrue(LPlayer.IsPlaying);
  Assert.IsFalse(Silent(Render(LPlayer, 4000)));
  Assert.AreEqual(1, LPlayer.Polyphony);
end;

procedure TTestXcomAdlibPlayer.DovrebbeFinireQuandoIlBranoArrivaAllaFine;
var
  LPlayer: IXcomAdlibPlayer;
begin
  LPlayer := Play(BuildSong([$00, $B0, $07, $7F, $00, $90, $40, $7F, $01, $80, $40, $00, $01, $FF]));
  Render(LPlayer, 40000);
  Assert.IsFalse(LPlayer.IsPlaying);
  Assert.AreEqual(0, LPlayer.Polyphony);
end;

procedure TTestXcomAdlibPlayer.DovrebbeFermareIlBranoConStop;
var
  LPlayer: IXcomAdlibPlayer;
begin
  LPlayer := Play(BuildSong([$00, $B0, $07, $7F, $00, $90, $40, $7F, $FF, $01, $FF]));
  Render(LPlayer, 4000);
  LPlayer.Stop;
  Assert.IsFalse(LPlayer.IsPlaying);
  Assert.AreEqual(0, LPlayer.Polyphony);
end;

procedure TTestXcomAdlibPlayer.DovrebbeDareSilenzioDopoLoStop;
var
  LPlayer: IXcomAdlibPlayer;
begin
  LPlayer := Play(BuildSong([$00, $B0, $07, $7F, $00, $90, $40, $7F, $FF, $01, $FF]));
  Render(LPlayer, 4000);
  LPlayer.Stop;
  // the release of the notes dies out: after a while there is nothing left
  Render(LPlayer, 400000);
  Assert.IsTrue(Silent(Render(LPlayer, 4000)));
end;

procedure TTestXcomAdlibPlayer.DovrebbeRifiutareUnaFrequenzaDiCampionamentoSenzaDurataDelTick;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomAdlibFactory.CreatePlayer(12345);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeRifiutareUnPlayDiUnBranoNonCaricato;
var
  LPlayer: IXcomAdlibPlayer;
begin
  LPlayer := TXcomAdlibFactory.CreatePlayer(22050);
  Assert.WillRaise(
    procedure
    begin
      LPlayer.Play(1.0);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeRifiutareUnBranoVuoto;
var
  LPlayer: IXcomAdlibPlayer;
begin
  LPlayer := TXcomAdlibFactory.CreatePlayer(22050);
  Assert.WillRaise(
    procedure
    begin
      LPlayer.Load(nil);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeRifiutareUnRenderCheNonSiaUnNumeroIntero_DiCampioniStereo;
var
  LPlayer: IXcomAdlibPlayer;
  LBuffer: TArray<SmallInt>;
begin
  LPlayer := Play(BuildSong([$00, $FF]));
  SetLength(LBuffer, 100);
  Assert.WillRaise(
    procedure
    begin
      LPlayer.Render(LBuffer, 102, 1.0);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeRifiutareUnRenderPiuGrandeDelBuffer;
var
  LPlayer: IXcomAdlibPlayer;
  LBuffer: TArray<SmallInt>;
begin
  LPlayer := Play(BuildSong([$00, $FF]));
  SetLength(LBuffer, 100);
  Assert.WillRaise(
    procedure
    begin
      LPlayer.Render(LBuffer, 204, 1.0);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeFermareIlBranoEdareErroreSeIDatiFinisconoACaso;
var
  LPlayer: IXcomAdlibPlayer;
begin
  // no end of track: the C reads past the song
  LPlayer := Play(BuildSong([$00, $B0, $07, $7F, $00, $90, $40, $7F, $01]));
  Assert.WillRaise(
    procedure
    begin
      Render(LPlayer, 100000);
    end, EXcomAdlibException);
  Assert.IsFalse(LPlayer.IsPlaying);
end;

procedure TTestXcomAdlibPlayer.DovrebbeDareErroreSeUnaNotaEFuoriDallaTabella;
var
  LPlayer: IXcomAdlibPlayer;
begin
  // note 0 becomes -1: the C reads the frequency table before its start
  LPlayer := Play(BuildSong([$00, $B0, $07, $7F, $00, $90, $00, $7F, $01, $FF]));
  Assert.WillRaise(
    procedure
    begin
      Render(LPlayer, 100000);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeDareErroreSeUnSubtrackNonEsiste;
var
  LPlayer: IXcomAdlibPlayer;
begin
  LPlayer := Play(BuildSong([$00, $FE, $05, $01, $FF]));
  Assert.WillRaise(
    procedure
    begin
      Render(LPlayer, 100000);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeDareErroreSeIBrani_SuperanoLaTabellaDelleSubtrack;
var
  LSong: TBytes;
  LPlayer: IXcomAdlibPlayer;
begin
  // the song says it has 200 subtracks: the C writes past its table of 128
  LSong := BuildSong([$00, $FF], 200);
  LPlayer := TXcomAdlibFactory.CreatePlayer(22050);
  LPlayer.Load(LSong);
  Assert.WillRaise(
    procedure
    begin
      LPlayer.Play(1.0);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeRifiutareUnoStatoDelBranoCheNonEsiste;
var
  LPlayer: IXcomAdlibPlayer;
begin
  LPlayer := Play(BuildSong([$00, $FF]));
  Assert.WillRaise(
    procedure
    begin
      LPlayer.SaveState(2);
    end, EXcomAdlibException);
  Assert.WillRaise(
    procedure
    begin
      LPlayer.LoadState(-1);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeScrivereAlSecondoChipLaCopiaTrasposta;
var
  LLeft: TOplRecorderChip;
  LRight: TOplRecorderChip;
  LLeftChip: IOplChip;
  LRightChip: IOplChip;
  LWriter: IXcomAdlibRegisterWriter;
begin
  LLeft := TOplRecorderChip.Create(TOplFactory.CreateChip(3579545, 22050), 0, nil);
  LRight := TOplRecorderChip.Create(TOplFactory.CreateChip(3579545, 22050), 1, nil);
  LLeftChip := LLeft;
  LRightChip := LRight;
  LWriter := TXcomAdlibRegisterWriter.Create(LLeftChip, LRightChip);
  LWriter.WriteRegister($A0, $41);
  LWriter.WriteRegister($B0, $2A);
  // block 2 and fnum 577 become fnum 581 (a 128th higher): the low bits are written again after the block
  Assert.AreEqual(4, LLeft.Writes.Count);
  Assert.AreEqual(6, LRight.Writes.Count);
  Assert.AreEqual(Integer($A0), LRight.Writes[0].Value);
  Assert.AreEqual(Integer($41), LRight.Writes[1].Value);
  Assert.AreEqual(Integer($B0), LRight.Writes[2].Value);
  Assert.AreEqual(Integer($2A), LRight.Writes[3].Value);
  Assert.AreEqual(Integer($A0), LRight.Writes[4].Value);
  Assert.AreEqual(Integer($45), LRight.Writes[5].Value);
end;

procedure TTestXcomAdlibPlayer.DovrebbeTogliereTremoloEVibratoAlSecondoChip;
var
  LLeft: TOplRecorderChip;
  LRight: TOplRecorderChip;
  LLeftChip: IOplChip;
  LRightChip: IOplChip;
  LWriter: IXcomAdlibRegisterWriter;
begin
  LLeft := TOplRecorderChip.Create(TOplFactory.CreateChip(3579545, 22050), 0, nil);
  LRight := TOplRecorderChip.Create(TOplFactory.CreateChip(3579545, 22050), 1, nil);
  LLeftChip := LLeft;
  LRightChip := LRight;
  LWriter := TXcomAdlibRegisterWriter.Create(LLeftChip, LRightChip);
  LWriter.WriteRegister($20, $FF);
  Assert.AreEqual(Integer($FF), LLeft.Writes[1].Value);
  Assert.AreEqual(Integer($3F), LRight.Writes[1].Value);
end;

procedure TTestXcomAdlibPlayer.DovrebbeLasciareSoloLeOndeSinusoidaliAgliOperatoriPortanti;
var
  LLeft: TOplRecorderChip;
  LRight: TOplRecorderChip;
  LLeftChip: IOplChip;
  LRightChip: IOplChip;
  LWriter: IXcomAdlibRegisterWriter;
begin
  LLeft := TOplRecorderChip.Create(TOplFactory.CreateChip(3579545, 22050), 0, nil);
  LRight := TOplRecorderChip.Create(TOplFactory.CreateChip(3579545, 22050), 1, nil);
  LLeftChip := LLeft;
  LRightChip := LRight;
  LWriter := TXcomAdlibRegisterWriter.Create(LLeftChip, LRightChip);
  LWriter.WriteRegister($E0, $FF); // the slot 0 is even: the wave form is kept
  LWriter.WriteRegister($E3, $FF); // the slot 1 is odd: only the bit 1 is kept
  LWriter.WriteRegister($E6, $FF); // no slot: the C takes -1 and the odd rule applies too
  Assert.AreEqual(Integer($FF), LRight.Writes[1].Value);
  Assert.AreEqual(Integer($02), LRight.Writes[3].Value);
  Assert.AreEqual(Integer($02), LRight.Writes[5].Value);
end;

procedure TTestXcomAdlibPlayer.DovrebbeRifiutareUnRegistroCheNonEsiste;
var
  LWriter: IXcomAdlibRegisterWriter;
begin
  LWriter := TXcomAdlibRegisterWriter.Create(TOplFactory.CreateChip(3579545, 22050),
    TOplFactory.CreateChip(3579545, 22050));
  Assert.WillRaise(
    procedure
    begin
      LWriter.WriteRegister(256, 0);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeRifiutareUnPlayerSenzaChip;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomAdlibFactory.CreatePlayer(nil, nil, 22050);
    end, EXcomAdlibException);
end;

procedure TTestXcomAdlibPlayer.DovrebbeLeggereIBraniDiUnContenitoreCat;
var
  LSong: TBytes;
  LCat: TBytes;
  LSource: IXcomAdlibMusicSource;
  LTrack: TBytes;
  LIndex: Integer;
begin
  LSong := BuildSong([$00, $FF]);
  // one entry at offset 8: the index, then a name of 3 characters and the song
  SetLength(LCat, 8 + 4 + Length(LSong));
  LCat[0] := 8;
  LCat[4] := Byte(Length(LSong));
  LCat[8] := 3;
  LCat[9] := Ord('A');
  LCat[10] := Ord('B');
  LCat[11] := Ord('C');
  for LIndex := 0 to High(LSong) do
    LCat[12 + LIndex] := LSong[LIndex];
  LSource := TXcomAdlibFactory.CreateCatSource(TXcomCatArchive.Create(LCat));
  Assert.AreEqual(1, LSource.TrackCount);
  LTrack := LSource.LoadTrack(0);
  Assert.AreEqual(Length(LSong), Length(LTrack));
  for LIndex := 0 to High(LSong) do
    Assert.AreEqual(Integer(LSong[LIndex]), Integer(LTrack[LIndex]));
  // as AdlibMusic is given it: with the name (a length of 3 and "ABC") in front
  LTrack := LSource.LoadTrackWithName(0);
  Assert.AreEqual(Length(LSong) + 4, Length(LTrack));
  Assert.AreEqual(3, Integer(LTrack[0]));
  Assert.AreEqual(Integer(Ord('C')), Integer(LTrack[3]));
  Assert.AreEqual(Integer(LSong[0]), Integer(LTrack[4]));
end;

end.
