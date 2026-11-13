{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the configuration file, the     }
{  table of the scores and the saved games of the control panel                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.UserFiles;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf,
  DelphiDoom.Tests.Keen.UiWorld;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenConfigStore = class(TObject)
  strict private
    function Keys: TKeenKeyboardDef;
  public
    [Test]
    procedure IRecordDeiFileDovrebberoAvereLeDimensioniDelProgrammaA16Bit;
    [Test]
    procedure SenzaFileDovrebbeDareIValoriPredefiniti;
    [Test]
    procedure DovrebbeRileggereCioCheScrive;
    [Test]
    procedure IlFileDovrebbeAvereIlFormatoDellOriginale;
    [Test]
    procedure UnFileTroppoCortoDovrebbeContareComeAssente;
    [Test]
    procedure DovrebbeTagliareUnNomeTroppoLungo;
    [Test]
    procedure UnDiscoCheNonScriveDovrebbeDareFalso;
    [Test]
    procedure LaModalitaDelSuonoDovrebbeEssereQuellaDelFile;
    [Test]
    procedure DovrebbeLeggereIlFileDelloShareware;
    [Test]
    procedure ICartelleSulDiscoDovrebberoScrivereERileggere;
  end;

  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenHighScores = class(TObject)
  strict private
    FWorld: TKeenUiWorld;
    function Make(const AScript: string): IKeenHighScores;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure LaTabellaNuovaDovrebbeAvereDieciPunteggiDaDiecimila;
    [Test]
    procedure UnPunteggioPiuAltoDovrebbeEntrareEFarScendereGliAltri;
    [Test]
    procedure APariPuntiDovrebbeVincereChiHaFattoPiuLivelli;
    [Test]
    procedure UnPunteggioBassoNonDovrebbeEntrare;
    [Test]
    procedure LoSchermoDovrebbeMostrareLaTabella;
    [Test]
    procedure IlControlloDovrebbeChiedereIlNomeDelNuovoPunteggio;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriTabella;
  end;

  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenSaveSlots = class(TObject)
  public
    [Test]
    procedure IlNomeDelFileDovrebbeAvereIlNumeroDelloSlot;
    [Test]
    procedure LaTestataDovrebbeAvereFirmaENome;
    [Test]
    procedure UnaTestataConUnAltraFirmaDovrebbeEssereRifiutata;
    [Test]
    procedure IlControlloDovrebbeTrovareIFilePresenti;
    [Test]
    procedure SalvareDovrebbeScrivereLaTestataECioCheScriveIlGioco;
    [Test]
    procedure SalvareDovrebbeTogliereIlFileSeIlGiocoRifiuta;
    [Test]
    procedure SalvareDovrebbeDareFalsoSeIlDiscoNonScrive;
    [Test]
    procedure CaricareDovrebbeDareAlGiocoIDatiDopoLaTestata;
    [Test]
    procedure CaricareDovrebbeDireCheIlFileManca;
    [Test]
    procedure CaricareDovrebbeDireCheIlFileNonEBuono;
    [Test]
    procedure DovrebbeRifiutareUnoSlotCheNonEsiste;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Keen.ConfigStore, DelphiDoom.Keen.HighScores, DelphiDoom.Keen.SaveSlots,
  DelphiDoom.Keen.UserFiles, DelphiDoom.Platform.Factory, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Skip;

type
  /// <summary>A game that writes and reads a few bytes; it can refuse</summary>
  TFakeHooks = class(TInterfacedObject, IKeenGameHooks)
  public
    Accept: Boolean;
    Loaded: TBytes;
    Resets: Integer;
    constructor Create;
    function LoadGame(AStream: TStream): Boolean;
    function SaveGame(AStream: TStream): Boolean;
    procedure ResetGame;
  end;

{ TFakeHooks }

constructor TFakeHooks.Create;
begin
  inherited Create;
  Accept := True;
end;

function TFakeHooks.LoadGame(AStream: TStream): Boolean;
begin
  SetLength(Loaded, AStream.Size - AStream.Position);
  if Length(Loaded) > 0 then
    AStream.ReadBuffer(Loaded[0], Length(Loaded));
  Result := Accept;
end;

function TFakeHooks.SaveGame(AStream: TStream): Boolean;
const
  PAYLOAD: array[0..3] of Byte = (9, 8, 7, 6);
begin
  AStream.WriteBuffer(PAYLOAD[0], SizeOf(PAYLOAD));
  Result := Accept;
end;

procedure TFakeHooks.ResetGame;
begin
  Inc(Resets);
end;

{ TTestKeenConfigStore }

function TTestKeenConfigStore.Keys: TKeenKeyboardDef;
begin
  Result.Button0 := $1D;
  Result.Button1 := $38;
  Result.UpLeft := $47;
  Result.Up := $48;
  Result.UpRight := $49;
  Result.Left := $4B;
  Result.Right := $4D;
  Result.DownLeft := $4F;
  Result.Down := $50;
  Result.DownRight := $51;
end;

procedure TTestKeenConfigStore.IRecordDeiFileDovrebberoAvereLeDimensioniDelProgrammaA16Bit;
begin
  Assert.AreEqual(64, SizeOf(TKeenHighScoreRecord), 'HighScore');
  Assert.AreEqual(10, SizeOf(TKeenKeyboardRecord), 'KeyboardDef');
  Assert.AreEqual(656, SizeOf(TKeenConfigRecord), 'KDREAMS.CFG');
  Assert.AreEqual(39, SizeOf(TKeenSaveHeader), 'SaveGame');
  Assert.AreEqual(60, SizeOf(TKeenSaveGameState), 'gametype');
  Assert.AreEqual(76, SizeOf(TKeenSaveObject), 'objtype');
end;

procedure TTestKeenConfigStore.SenzaFileDovrebbeDareIValoriPredefiniti;
var
  LStore: TKeenConfigStore;
  LConfig: TKeenConfig;
  LIndex: Integer;
begin
  LStore := TKeenConfigStore.Create(TUiFakeFiles.Create);
  try
    LConfig := LStore.Read(Keys);
    Assert.IsFalse(LConfig.Found);
    for LIndex := 0 to KEEN_MAX_SCORES - 1 do
    begin
      Assert.AreEqual(KEEN_DEFAULT_HIGH_SCORE, LConfig.Scores[LIndex].Score);
      Assert.AreEqual(AnsiString(''), LConfig.Scores[LIndex].Name);
    end;
    Assert.AreEqual(KEEN_SDM_OFF, Integer(LConfig.SoundMode));
    Assert.AreEqual(Ord(kctKeyboard1), Ord(LConfig.Control));
    Assert.AreEqual($1D, Integer(LConfig.Keyboard.Button0));
  finally
    LStore.Free;
  end;
end;

procedure TTestKeenConfigStore.DovrebbeRileggereCioCheScrive;
var
  LFiles: TUiFakeFiles;
  LFilesIntf: IKeenUserFiles;
  LStore: TKeenConfigStore;
  LConfig: TKeenConfig;
  LBack: TKeenConfig;
begin
  LFiles := TUiFakeFiles.Create;
  LFilesIntf := LFiles;
  LStore := TKeenConfigStore.Create(LFilesIntf);
  try
    LConfig := TKeenConfigStore.Defaults(Keys);
    LConfig.Scores[0].Name := 'Billy Blaze';
    LConfig.Scores[0].Score := 123456;
    LConfig.Scores[0].Completed := 12;
    LConfig.Scores[9].Name := 'last';
    LConfig.SoundMode := KEEN_SDM_ADLIB;
    LConfig.MusicMode := 1;
    LConfig.Control := kctJoystick2;
    LConfig.Keyboard.Button0 := $39;
    Assert.IsTrue(LStore.Write(LConfig));
    Assert.IsTrue(LFiles.Has('KDREAMS.CFG'));
    LBack := LStore.Read(Keys);
    Assert.IsTrue(LBack.Found);
    Assert.AreEqual(AnsiString('Billy Blaze'), LBack.Scores[0].Name);
    Assert.AreEqual(123456, LBack.Scores[0].Score);
    Assert.AreEqual(12, Integer(LBack.Scores[0].Completed));
    Assert.AreEqual(AnsiString('last'), LBack.Scores[9].Name);
    Assert.AreEqual(KEEN_SDM_ADLIB, Integer(LBack.SoundMode));
    Assert.AreEqual(1, Integer(LBack.MusicMode));
    Assert.AreEqual(Ord(kctJoystick2), Ord(LBack.Control));
    Assert.AreEqual($39, Integer(LBack.Keyboard.Button0));
    Assert.AreEqual($51, Integer(LBack.Keyboard.DownRight));
  finally
    LStore.Free;
  end;
end;

procedure TTestKeenConfigStore.IlFileDovrebbeAvereIlFormatoDellOriginale;
var
  LConfig: TKeenConfig;
  LBytes: TBytes;
begin
  LConfig := TKeenConfigStore.Defaults(Keys);
  LConfig.Scores[1].Name := 'AB';
  LConfig.Scores[1].Score := $01020304;
  LConfig.Scores[1].Completed := $0506;
  LConfig.SoundMode := 2;
  LConfig.MusicMode := 1;
  LConfig.Control := kctJoystick1;
  LBytes := TKeenConfigStore.Encode(LConfig);
  Assert.AreEqual<Integer>(656, Length(LBytes));
  // the second score starts at 64: the name, a 0, then at 58 the score and at 62 the levels (little endian)
  Assert.AreEqual(Ord('A'), Integer(LBytes[64]));
  Assert.AreEqual(Ord('B'), Integer(LBytes[65]));
  Assert.AreEqual(0, Integer(LBytes[66]));
  Assert.AreEqual(4, Integer(LBytes[64 + 58]));
  Assert.AreEqual(1, Integer(LBytes[64 + 61]));
  Assert.AreEqual(6, Integer(LBytes[64 + 62]));
  Assert.AreEqual(5, Integer(LBytes[64 + 63]));
  // the first score: 10000
  Assert.AreEqual($10, Integer(LBytes[58]));
  Assert.AreEqual($27, Integer(LBytes[59]));
  // after the ten scores: sound mode, music mode, control (2 is the first joystick), the ten keys
  Assert.AreEqual(2, Integer(LBytes[640]));
  Assert.AreEqual(0, Integer(LBytes[641]));
  Assert.AreEqual(1, Integer(LBytes[642]));
  Assert.AreEqual(2, Integer(LBytes[644]));
  Assert.AreEqual($1D, Integer(LBytes[646]));
  Assert.AreEqual($51, Integer(LBytes[655]));
end;

procedure TTestKeenConfigStore.UnFileTroppoCortoDovrebbeContareComeAssente;
var
  LFiles: TUiFakeFiles;
  LFilesIntf: IKeenUserFiles;
  LStore: TKeenConfigStore;
begin
  LFiles := TUiFakeFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Put('KDREAMS.CFG', TBytes.Create(1, 2, 3));
  LStore := TKeenConfigStore.Create(LFilesIntf);
  try
    Assert.IsFalse(LStore.Read(Keys).Found);
    Assert.WillRaise(procedure begin TKeenConfigStore.Decode(TBytes.Create(1, 2, 3)); end, EKeenDataException);
  finally
    LStore.Free;
  end;
end;

procedure TTestKeenConfigStore.DovrebbeTagliareUnNomeTroppoLungo;
var
  LConfig: TKeenConfig;
  LBack: TKeenConfig;
begin
  LConfig := TKeenConfigStore.Defaults(Keys);
  LConfig.Scores[3].Name := StringOfChar(AnsiChar('x'), 100);
  LBack := TKeenConfigStore.Decode(TKeenConfigStore.Encode(LConfig));
  Assert.AreEqual(KEEN_MAX_HIGH_NAME, Length(LBack.Scores[3].Name));
  Assert.AreEqual(KEEN_DEFAULT_HIGH_SCORE, LBack.Scores[3].Score, 'the name does not run into the score');
end;

procedure TTestKeenConfigStore.UnDiscoCheNonScriveDovrebbeDareFalso;
var
  LFiles: TUiFakeFiles;
  LFilesIntf: IKeenUserFiles;
  LStore: TKeenConfigStore;
begin
  LFiles := TUiFakeFiles.Create;
  LFilesIntf := LFiles;
  LFiles.ReadOnly := True;
  LStore := TKeenConfigStore.Create(LFilesIntf);
  try
    Assert.IsFalse(LStore.Write(TKeenConfigStore.Defaults(Keys)));
  finally
    LStore.Free;
  end;
  Assert.WillRaise(procedure begin TKeenConfigStore.Create(nil).Free; end, EArgumentNilException);
end;

procedure TTestKeenConfigStore.LaModalitaDelSuonoDovrebbeEssereQuellaDelFile;
var
  LMode: TKeenSoundMode;
begin
  Assert.IsTrue(TKeenConfigStore.TrySoundMode(KEEN_SDM_OFF, LMode));
  Assert.AreEqual(Ord(ksmOff), Ord(LMode));
  Assert.IsTrue(TKeenConfigStore.TrySoundMode(KEEN_SDM_PC, LMode));
  Assert.AreEqual(Ord(ksmPC), Ord(LMode));
  Assert.IsTrue(TKeenConfigStore.TrySoundMode(KEEN_SDM_ADLIB, LMode));
  Assert.AreEqual(Ord(ksmAdLib), Ord(LMode));
  // the Sound Blaster and the Sound Source are not in this port
  Assert.IsFalse(TKeenConfigStore.TrySoundMode(KEEN_SDM_SOUNDBLASTER, LMode));
  Assert.IsFalse(TKeenConfigStore.TrySoundMode(KEEN_SDM_SOUNDSOURCE, LMode));
end;

procedure TTestKeenConfigStore.DovrebbeLeggereIlFileDelloShareware;
var
  LPath: string;
  LBytes: TBytes;
  LConfig: TKeenConfig;
  LIndex: Integer;
begin
  LPath := TTestFiles.FindFileUp('Reference\_dati\keen\KDREAMS.CFG');
  if LPath = '' then
    TTestSkip.Ignore('il KDREAMS.CFG dello shareware di Keen Dreams non e'' su questa macchina');
  LBytes := TFile.ReadAllBytes(LPath);
  Assert.AreEqual<Integer>(656, Length(LBytes), 'the file of the original has the size of the record');
  LConfig := TKeenConfigStore.Decode(LBytes);
  for LIndex := 0 to KEEN_MAX_SCORES - 2 do
    Assert.IsTrue(LConfig.Scores[LIndex].Score >= LConfig.Scores[LIndex + 1].Score, 'the scores go down');
  Assert.IsTrue(LConfig.SoundMode <= KEEN_SDM_SOUNDSOURCE);
  Assert.IsTrue(Ord(LConfig.Control) <= Ord(kctMouse));
  Assert.IsTrue(LConfig.Keyboard.Up <> 0);
  // written again, it reads the same
  LConfig := TKeenConfigStore.Decode(TKeenConfigStore.Encode(LConfig));
  Assert.IsTrue(LConfig.Keyboard.Up <> 0);
end;

procedure TTestKeenConfigStore.ICartelleSulDiscoDovrebberoScrivereERileggere;
var
  LFolder: string;
  LFiles: IKeenUserFiles;
  LBytes: TBytes;
begin
  LFolder := TPath.Combine(TPath.GetTempPath, 'keen-tests-' + TGUID.NewGuid.ToString);
  LFiles := TKeenFolderUserFiles.Create(TPlatformFactory.CreateFileStore, LFolder);
  try
    Assert.IsFalse(LFiles.TryRead('A.BIN', LBytes));
    Assert.IsTrue(LFiles.TryWrite('A.BIN', TBytes.Create(1, 2, 3)));
    Assert.IsTrue(LFiles.TryRead('A.BIN', LBytes));
    Assert.AreEqual<Integer>(3, Length(LBytes));
    Assert.AreEqual(3, Integer(LBytes[2]));
    LFiles.Delete('A.BIN');
    Assert.IsFalse(LFiles.TryRead('A.BIN', LBytes));
    LFiles.Delete('A.BIN'); // not there: nothing happens
  finally
    if TDirectory.Exists(LFolder) then
      TDirectory.Delete(LFolder, True);
  end;
  Assert.WillRaise(procedure begin TKeenFolderUserFiles.Create(nil, LFolder); end, EArgumentNilException);
end;

{ TTestKeenHighScores }

function TTestKeenHighScores.Make(const AScript: string): IKeenHighScores;
begin
  FWorld := TKeenUiWorld.Create(nil, AScript);
  Result := TKeenHighScores.Create(FWorld.Windows, FWorld.Input);
end;

procedure TTestKeenHighScores.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestKeenHighScores.LaTabellaNuovaDovrebbeAvereDieciPunteggiDaDiecimila;
var
  LScores: IKeenHighScores;
  LIndex: Integer;
begin
  LScores := Make('');
  for LIndex := 0 to KEEN_MAX_SCORES - 1 do
    Assert.AreEqual(10000, LScores.Scores[LIndex].Score);
  Assert.IsFalse(LScores.Dirty);
end;

procedure TTestKeenHighScores.UnPunteggioPiuAltoDovrebbeEntrareEFarScendereGliAltri;
var
  LScores: IKeenHighScores;
  LScore: TKeenHighScore;
begin
  LScores := Make('');
  LScore.Name := 'first';
  LScore.Score := 50000;
  LScore.Completed := 3;
  LScores.Scores[0] := LScore;
  LScore.Name := 'second';
  LScore.Score := 30000;
  LScores.Scores[1] := LScore;
  Assert.AreEqual(1, LScores.Insert(40000, 2));
  Assert.IsTrue(LScores.Dirty);
  Assert.AreEqual(AnsiString('first'), LScores.Scores[0].Name);
  Assert.AreEqual(AnsiString(''), LScores.Scores[1].Name, 'the new line has no name yet');
  Assert.AreEqual(40000, LScores.Scores[1].Score);
  Assert.AreEqual(2, Integer(LScores.Scores[1].Completed));
  Assert.AreEqual(AnsiString('second'), LScores.Scores[2].Name);
  Assert.AreEqual(10000, LScores.Scores[9].Score);
end;

procedure TTestKeenHighScores.APariPuntiDovrebbeVincereChiHaFattoPiuLivelli;
var
  LScores: IKeenHighScores;
begin
  LScores := Make('');
  // 10000 with a level done goes above the ten 10000 with none
  Assert.AreEqual(0, LScores.Insert(10000, 1));
  // the same again stays under the first (not more levels) and above the others
  Assert.AreEqual(1, LScores.Insert(10000, 1));
end;

procedure TTestKeenHighScores.UnPunteggioBassoNonDovrebbeEntrare;
var
  LScores: IKeenHighScores;
begin
  LScores := Make('');
  Assert.AreEqual(-1, LScores.Insert(500, 0));
  Assert.AreEqual(-1, LScores.Insert(10000, 0), 'equal in points and levels: it does not enter');
  Assert.IsFalse(LScores.Dirty);
end;

procedure TTestKeenHighScores.LoSchermoDovrebbeMostrareLaTabella;
var
  LScores: IKeenHighScores;
  LBlank: Cardinal;
  LWindow: TKeenWindowRec;
begin
  LScores := Make('');
  LBlank := FWorld.ScreenHash;
  LScores.Display(-1);
  Assert.AreNotEqual(LBlank, FWorld.ScreenHash);
  LWindow := FWorld.Windows.Window;
  Assert.AreEqual(240, LWindow.W, '30 characters');
  Assert.AreEqual(120, LWindow.H, '15 characters');
  Assert.AreEqual(KEEN_F_BLACK, FWorld.Buffered.FontColor);
end;

procedure TTestKeenHighScores.IlControlloDovrebbeChiedereIlNomeDelNuovoPunteggio;
var
  LScores: IKeenHighScores;
begin
  LScores := Make('wait 10'#10'type keen'#10'press enter'#10'wait 20'#10'press space');
  LScores.Check(77000, 5);
  Assert.AreEqual(AnsiString('keen'), LScores.Scores[0].Name);
  Assert.AreEqual(77000, LScores.Scores[0].Score);
  Assert.AreEqual(5, Integer(LScores.Scores[0].Completed));
  Assert.AreEqual(10000, LScores.Scores[1].Score);
end;

procedure TTestKeenHighScores.DovrebbeRifiutareUnIndiceFuoriTabella;
var
  LScores: IKeenHighScores;
  LScore: TKeenHighScore;
begin
  LScores := Make('');
  Assert.WillRaise(procedure begin LScore := LScores.Scores[10]; end, EArgumentOutOfRangeException);
  Assert.WillRaise(procedure begin LScore := LScores.Scores[-1]; end, EArgumentOutOfRangeException);
  Assert.WillRaise(procedure begin TKeenHighScores.Create(nil, FWorld.Input); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenHighScores.Create(FWorld.Windows, nil); end, EArgumentNilException);
end;

{ TTestKeenSaveSlots }

procedure TTestKeenSaveSlots.IlNomeDelFileDovrebbeAvereIlNumeroDelloSlot;
begin
  Assert.AreEqual('SAVEGM0.KDR', TKeenSaveSlots.FileName(0));
  Assert.AreEqual('SAVEGM6.KDR', TKeenSaveSlots.FileName(6));
end;

procedure TTestKeenSaveSlots.LaTestataDovrebbeAvereFirmaENome;
var
  LSlot: TKeenSaveSlot;
  LBack: TKeenSaveSlot;
  LBytes: TBytes;
begin
  LSlot.Present := True;
  LSlot.Name := 'Tuberia';
  LBytes := TKeenSaveSlots.EncodeHeader(LSlot);
  Assert.AreEqual<Integer>(39, Length(LBytes));
  Assert.AreEqual(Ord('K'), Integer(LBytes[0]));
  Assert.AreEqual(Ord('R'), Integer(LBytes[2]));
  Assert.AreEqual(0, Integer(LBytes[3]));
  Assert.AreEqual(1, Integer(LBytes[4]), 'present, a 16 bit boolean');
  Assert.AreEqual(Ord('T'), Integer(LBytes[6]));
  Assert.IsTrue(TKeenSaveSlots.TryDecodeHeader(LBytes, LBack));
  Assert.AreEqual(AnsiString('Tuberia'), LBack.Name);
  Assert.IsTrue(LBack.Present);
  // a name of the longest size
  LSlot.Name := StringOfChar(AnsiChar('n'), 60);
  Assert.IsTrue(TKeenSaveSlots.TryDecodeHeader(TKeenSaveSlots.EncodeHeader(LSlot), LBack));
  Assert.AreEqual(KEEN_MAX_GAME_NAME, Length(LBack.Name));
end;

procedure TTestKeenSaveSlots.UnaTestataConUnAltraFirmaDovrebbeEssereRifiutata;
var
  LSlot: TKeenSaveSlot;
  LBytes: TBytes;
begin
  LSlot.Present := True;
  LSlot.Name := 'x';
  LBytes := TKeenSaveSlots.EncodeHeader(LSlot);
  LBytes[1] := Ord('X');
  Assert.IsFalse(TKeenSaveSlots.TryDecodeHeader(LBytes, LSlot));
  Assert.IsFalse(TKeenSaveSlots.TryDecodeHeader(TBytes.Create(Ord('K'), Ord('D'), Ord('R'), 0), LSlot), 'too short');
end;

procedure TTestKeenSaveSlots.IlControlloDovrebbeTrovareIFilePresenti;
var
  LFiles: TUiFakeFiles;
  LFilesIntf: IKeenUserFiles;
  LSlots: IKeenSaveSlots;
  LSlot: TKeenSaveSlot;
begin
  LFiles := TUiFakeFiles.Create;
  LFilesIntf := LFiles;
  LSlot.Present := False;
  LSlot.Name := 'Level 3';
  LFiles.Put('SAVEGM2.KDR', TKeenSaveSlots.EncodeHeader(LSlot));
  LFiles.Put('SAVEGM4.KDR', TBytes.Create(1, 2, 3));
  LSlots := TKeenSaveSlots.Create(LFilesIntf);
  LSlots.Check;
  Assert.IsFalse(LSlots.Slots[0].Present);
  Assert.AreEqual(AnsiString('Empty'), LSlots.Slots[0].Name);
  Assert.IsTrue(LSlots.Slots[2].Present, 'a file with a good header is present whatever its flag says');
  Assert.AreEqual(AnsiString('Level 3'), LSlots.Slots[2].Name);
  Assert.IsFalse(LSlots.Slots[4].Present, 'a file that is not a saved game');
end;

procedure TTestKeenSaveSlots.SalvareDovrebbeScrivereLaTestataECioCheScriveIlGioco;
var
  LFiles: TUiFakeFiles;
  LFilesIntf: IKeenUserFiles;
  LSlots: IKeenSaveSlots;
  LSlot: TKeenSaveSlot;
  LBytes: TBytes;
begin
  LFiles := TUiFakeFiles.Create;
  LFilesIntf := LFiles;
  LSlots := TKeenSaveSlots.Create(LFilesIntf);
  LSlot.Present := False;
  LSlot.Name := 'mine';
  LSlots.Slots[3] := LSlot;
  Assert.IsTrue(LSlots.Save(3, TFakeHooks.Create));
  Assert.IsTrue(LFilesIntf.TryRead('SAVEGM3.KDR', LBytes));
  Assert.AreEqual<Integer>(39 + 4, Length(LBytes));
  Assert.AreEqual(Ord('m'), Integer(LBytes[6]));
  Assert.AreEqual(9, Integer(LBytes[39]));
  Assert.AreEqual(6, Integer(LBytes[42]));
  // without a game the file is the header alone
  Assert.IsTrue(LSlots.Save(1, nil));
  Assert.IsTrue(LFilesIntf.TryRead('SAVEGM1.KDR', LBytes));
  Assert.AreEqual<Integer>(39, Length(LBytes));
end;

procedure TTestKeenSaveSlots.SalvareDovrebbeTogliereIlFileSeIlGiocoRifiuta;
var
  LFiles: TUiFakeFiles;
  LFilesIntf: IKeenUserFiles;
  LSlots: IKeenSaveSlots;
  LHooks: TFakeHooks;
  LHooksIntf: IKeenGameHooks;
begin
  LFiles := TUiFakeFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Put('SAVEGM0.KDR', TBytes.Create(1));
  LSlots := TKeenSaveSlots.Create(LFilesIntf);
  LHooks := TFakeHooks.Create;
  LHooksIntf := LHooks;
  LHooks.Accept := False;
  Assert.IsFalse(LSlots.Save(0, LHooksIntf));
  Assert.IsFalse(LFiles.Has('SAVEGM0.KDR'), 'the C removes the file');
end;

procedure TTestKeenSaveSlots.SalvareDovrebbeDareFalsoSeIlDiscoNonScrive;
var
  LFiles: TUiFakeFiles;
  LFilesIntf: IKeenUserFiles;
  LSlots: IKeenSaveSlots;
begin
  LFiles := TUiFakeFiles.Create;
  LFilesIntf := LFiles;
  LFiles.ReadOnly := True;
  LSlots := TKeenSaveSlots.Create(LFilesIntf);
  Assert.IsFalse(LSlots.Save(0, TFakeHooks.Create));
end;

procedure TTestKeenSaveSlots.CaricareDovrebbeDareAlGiocoIDatiDopoLaTestata;
var
  LFiles: TUiFakeFiles;
  LFilesIntf: IKeenUserFiles;
  LSlots: IKeenSaveSlots;
  LHooks: TFakeHooks;
  LHooksIntf: IKeenGameHooks;
  LSlot: TKeenSaveSlot;
  LError: AnsiString;
begin
  LFiles := TUiFakeFiles.Create;
  LFilesIntf := LFiles;
  LSlots := TKeenSaveSlots.Create(LFilesIntf);
  LSlot.Present := True;
  LSlot.Name := 'on disk';
  LFiles.Put('SAVEGM5.KDR', TKeenSaveSlots.EncodeHeader(LSlot) + TBytes.Create(11, 22, 33));
  LHooks := TFakeHooks.Create;
  LHooksIntf := LHooks;
  Assert.IsTrue(LSlots.Load(5, LHooksIntf, LError));
  Assert.AreEqual(AnsiString(''), LError);
  Assert.AreEqual<Integer>(3, Length(LHooks.Loaded));
  Assert.AreEqual(22, Integer(LHooks.Loaded[1]));
  Assert.AreEqual(AnsiString('on disk'), LSlots.Slots[5].Name, 'the name of the file');
  // a game that does not take the data
  LHooks.Accept := False;
  Assert.IsFalse(LSlots.Load(5, LHooksIntf, LError));
  Assert.AreNotEqual(AnsiString(''), LError);
end;

procedure TTestKeenSaveSlots.CaricareDovrebbeDireCheIlFileManca;
var
  LSlots: IKeenSaveSlots;
  LError: AnsiString;
begin
  LSlots := TKeenSaveSlots.Create(TUiFakeFiles.Create);
  Assert.IsFalse(LSlots.Load(0, TFakeHooks.Create, LError));
  Assert.AreEqual(AnsiString('No such file or directory'), LError);
end;

procedure TTestKeenSaveSlots.CaricareDovrebbeDireCheIlFileNonEBuono;
var
  LFiles: TUiFakeFiles;
  LFilesIntf: IKeenUserFiles;
  LSlots: IKeenSaveSlots;
  LError: AnsiString;
begin
  LFiles := TUiFakeFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Put('SAVEGM0.KDR', TBytes.Create(1, 2, 3));
  LSlots := TKeenSaveSlots.Create(LFilesIntf);
  Assert.IsFalse(LSlots.Load(0, TFakeHooks.Create, LError));
  Assert.AreEqual(AnsiString('File is Incomplete'), LError);
end;

procedure TTestKeenSaveSlots.DovrebbeRifiutareUnoSlotCheNonEsiste;
var
  LSlots: IKeenSaveSlots;
  LSlot: TKeenSaveSlot;
  LError: AnsiString;
begin
  LSlots := TKeenSaveSlots.Create(TUiFakeFiles.Create);
  Assert.WillRaise(procedure begin LSlot := LSlots.Slots[7]; end, EKeenException);
  Assert.WillRaise(procedure begin LSlots.Save(-1, nil); end, EKeenException);
  Assert.WillRaise(procedure begin LSlots.Load(9, nil, LError); end, EKeenException);
  Assert.WillRaise(procedure begin TKeenSaveSlots.Create(nil); end, EArgumentNilException);
end;

end.
