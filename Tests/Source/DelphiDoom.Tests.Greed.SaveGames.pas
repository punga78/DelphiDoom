{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedSaveGames and of the records of the saved games   }
{                                                                              }
{  The golden file has the layout of player_t and pevent_t of the ORIGINAL      }
{  xGreed (Tools\Verifica\175\SaveGolden.dpr compiled with protos_h.pas)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SaveGames;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Save.Intf;

type
  /// <summary>Files in memory</summary>
  TFakeSaveFiles = class(TInterfacedObject, IGreedSaveFiles)
  public
    Files: TDictionary<string, TBytes>;
    constructor Create;
    destructor Destroy; override;
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
    procedure WriteAll(const AName: string; const ABytes: TBytes);
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedSaveGames = class(TObject)
  private
    FFiles: TFakeSaveFiles;
    FFilesIntf: IGreedSaveFiles;
    FSut: IGreedSaveGames;
    procedure Make(AVariant: TGreedGameVariant);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereLaDimensioneEIlLayoutDiPlayerT;
    [Test]
    procedure DovrebbeAvereLaDimensioneDiPeventT;
    [Test]
    procedure DovrebbeAvereLaDirectoryDi230Byte;
    [Test]
    procedure DovrebbeScrivereERileggereLaPartita;
    [Test]
    procedure DovrebbeScrivereIlRecordCosiCom;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileNonCe;
    [Test]
    procedure DovrebbeSollevareSeIlFileEPiuCortoDelRecord;
    [Test]
    procedure DovrebbeIgnorareIByteDopoIlRecord;
    [TestCase('normale', '0,SAVEGAME.3,SAVEGAME.DIR')]
    [TestCase('gioco 1', '1,SAVE1.3,SAVE1.DIR')]
    [TestCase('gioco 2', '2,SAVE2.3,SAVE2.DIR')]
    [TestCase('gioco 3', '3,SAVE3.3,SAVE3.DIR')]
    procedure DovrebbeDareINomiDeiFileDelGioco(AVariant: Integer; const AGame, ADirectory: string);
    [Test]
    procedure DovrebbeCreareLaDirectoryVuotaSeNonCe;
    [Test]
    procedure DovrebbeRileggereLaDirectoryScritta;
    [Test]
    procedure DovrebbeSollevareSeLaDirectoryEPiuCorta;
    [Test]
    procedure DovrebbeAggiustareLoScrollInBassaRisoluzione;
    [Test]
    procedure DovrebbeAggiustareLoScrollInAltaRisoluzione;
    [Test]
    procedure DovrebbeSollevareSenzaFile;
  end;

implementation

uses
  System.Classes, DelphiDoom.Tests.Greed.RealData, DelphiDoom.Greed.SaveGames;

function Fnv(const AData: Pointer; ASize: Integer): string;
var
  LHash: Cardinal;
  LIndex: Integer;
begin
  LHash := $811C9DC5;
  for LIndex := 0 to ASize - 1 do
    LHash := (LHash xor PByte(PByte(AData) + LIndex)^) * 16777619;
  Result := LowerCase(IntToHex(LHash, 8));
end;

// the same values as SaveGolden.dpr
procedure FillPattern(var P: TGreedPlayerRecord);
var
  I: Integer;
begin
  FillChar(P, SizeOf(P), 0);
  P.X := 1; P.Y := 2; P.Z := 3; P.MapSpot := 4; P.Angle := 5; P.Height := 6; P.CurrentWeapon := 7;
  P.Shield := 8; P.Angst := 9; P.MaxShield := 10; P.MaxAngst := 11; P.Map := 12; P.Mission := 13;
  P.CharType := 14; P.LevelScore := 15; P.Difficulty := 16;
  for I := 0 to 4 do
    P.Weapons[I] := 100 + I;
  for I := 0 to 2 do
    P.Ammo[I] := 200 + I;
  P.BodyCount := 17; P.TimeCount := 18; P.Score := 19;
  for I := 0 to 4095 do
  begin
    P.NorthMap[I] := I and 255;
    P.WestMap[I] := (I + 1) and 255;
    P.NorthWall[I] := (I + 2) and 255;
    P.WestWall[I] := (I + 3) and 255;
    P.SaveSprites[I] := (I + 4) and 255;
  end;
  P.ScrollMin := 20; P.ScrollMax := 21;
  for I := 0 to 1 do
    P.Primaries[I] := 300 + I;
  for I := 0 to 6 do
    P.Secondaries[I] := 400 + I;
  for I := 0 to GREED_MAX_PLAYERS - 1 do
    P.Frags[I] := 500 + I;
  P.RunMod := 22; P.WalkMod := 23;
  for I := 0 to GREED_MAX_INVENTORY - 1 do
    P.Inventory[I] := 600 + I;
  P.Status := 24; P.HoloPic := 25; P.HoloScale := 26; P.JumpMod := 27;
  for I := 0 to 255 do
    P.Events[I] := (I * 7) and 255;
end;

{ TFakeSaveFiles }

constructor TFakeSaveFiles.Create;
begin
  inherited Create;
  Files := TDictionary<string, TBytes>.Create;
end;

destructor TFakeSaveFiles.Destroy;
begin
  Files.Free;
  inherited;
end;

function TFakeSaveFiles.Exists(const AName: string): Boolean;
begin
  Result := Files.ContainsKey(AName);
end;

function TFakeSaveFiles.ReadAll(const AName: string): TBytes;
begin
  Result := Files[AName];
end;

procedure TFakeSaveFiles.WriteAll(const AName: string; const ABytes: TBytes);
begin
  Files.AddOrSetValue(AName, ABytes);
end;

{ TTestGreedSaveGames }

procedure TTestGreedSaveGames.Make(AVariant: TGreedGameVariant);
begin
  FSut := TGreedSaveGames.Create(FFilesIntf, AVariant);
end;

procedure TTestGreedSaveGames.Setup;
begin
  FFiles := TFakeSaveFiles.Create;
  FFilesIntf := FFiles;
  Make(ggvDefault);
end;

procedure TTestGreedSaveGames.TearDown;
begin
  FSut := nil;
  FFilesIntf := nil;
end;

procedure TTestGreedSaveGames.DovrebbeAvereLaDimensioneEIlLayoutDiPlayerT;
var
  LGolden: TStringList;
  LPlayer: TGreedPlayerRecord;
  LBase: PByte;
  LLine: string;
  LParts: TArray<string>;
  LOffsets: TDictionary<string, Integer>;
begin
  FillPattern(LPlayer);
  LBase := @LPlayer;
  LOffsets := TDictionary<string, Integer>.Create;
  LGolden := TStringList.Create;
  try
    LOffsets.Add('x', PByte(@LPlayer.X) - LBase);
    LOffsets.Add('mapspot', PByte(@LPlayer.MapSpot) - LBase);
    LOffsets.Add('weapons', PByte(@LPlayer.Weapons) - LBase);
    LOffsets.Add('ammo', PByte(@LPlayer.Ammo) - LBase);
    LOffsets.Add('bodycount', PByte(@LPlayer.BodyCount) - LBase);
    LOffsets.Add('northmap', PByte(@LPlayer.NorthMap) - LBase);
    LOffsets.Add('westmap', PByte(@LPlayer.WestMap) - LBase);
    LOffsets.Add('northwall', PByte(@LPlayer.NorthWall) - LBase);
    LOffsets.Add('westwall', PByte(@LPlayer.WestWall) - LBase);
    LOffsets.Add('savesprites', PByte(@LPlayer.SaveSprites) - LBase);
    LOffsets.Add('scrollmin', PByte(@LPlayer.ScrollMin) - LBase);
    LOffsets.Add('primaries', PByte(@LPlayer.Primaries) - LBase);
    LOffsets.Add('secondaries', PByte(@LPlayer.Secondaries) - LBase);
    LOffsets.Add('frags', PByte(@LPlayer.Frags) - LBase);
    LOffsets.Add('runmod', PByte(@LPlayer.RunMod) - LBase);
    LOffsets.Add('inventory', PByte(@LPlayer.Inventory) - LBase);
    LOffsets.Add('status', PByte(@LPlayer.Status) - LBase);
    LOffsets.Add('jumpmod', PByte(@LPlayer.JumpMod) - LBase);
    LOffsets.Add('events', PByte(@LPlayer.Events) - LBase);
    LGolden.LoadFromFile(TGreedRealData.GoldenPath('save.golden.txt'));
    for LLine in LGolden do
    begin
      LParts := LLine.Split([' ']);
      if LParts[0] = 'O' then
        Assert.AreEqual(StrToInt(LParts[2]), LOffsets[LParts[1]], 'offset of ' + LParts[1])
      else if (LParts[0] = 'S') and (LParts[1] = 'player_t') then
      begin
        Assert.AreEqual(StrToInt(LParts[2]), Integer(SizeOf(LPlayer)));
        Assert.AreEqual(LParts[3], Fnv(@LPlayer, SizeOf(LPlayer)));
      end;
    end;
    Assert.AreEqual(19, LOffsets.Count);
  finally
    LGolden.Free;
    LOffsets.Free;
  end;
end;

procedure TTestGreedSaveGames.DovrebbeAvereLaDimensioneDiPeventT;
var
  LGolden: TStringList;
  LEvent: TGreedPlayerEvent;
  LParts: TArray<string>;
  LLine: string;
begin
  FillChar(LEvent, SizeOf(LEvent), 0);
  LEvent.Id := 1; LEvent.PlayerId := 2; LEvent.X := 3; LEvent.Y := 4; LEvent.Z := 5; LEvent.Angle := 6;
  LEvent.Angst := 7; LEvent.CharType := 8; LEvent.Status := 9; LEvent.HoloPic := 10; LEvent.HoloScale := 11;
  LEvent.Height := 12; LEvent.SpecialEffect := 13;
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath('save.golden.txt'));
    for LLine in LGolden do
    begin
      LParts := LLine.Split([' ']);
      if (LParts[0] = 'S') and (LParts[1] = 'pevent_t') then
      begin
        Assert.AreEqual(StrToInt(LParts[2]), Integer(SizeOf(LEvent)));
        Assert.AreEqual(LParts[3], Fnv(@LEvent, SizeOf(LEvent)));
      end;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedSaveGames.DovrebbeAvereLaDirectoryDi230Byte;
begin
  // 10 short strings of 22 characters: 23 bytes each
  Assert.AreEqual(230, Integer(SizeOf(TGreedSaveDirectory)));
end;

procedure TTestGreedSaveGames.DovrebbeScrivereERileggereLaPartita;
var
  LWritten, LRead: TGreedPlayerRecord;
begin
  FillPattern(LWritten);
  FSut.SaveGame(4, LWritten);
  Assert.IsTrue(FSut.LoadGame(4, LRead));
  Assert.AreEqual(Fnv(@LWritten, SizeOf(LWritten)), Fnv(@LRead, SizeOf(LRead)));
end;

procedure TTestGreedSaveGames.DovrebbeScrivereIlRecordCosiCom;
var
  LPlayer: TGreedPlayerRecord;
begin
  FillPattern(LPlayer);
  FSut.SaveGame(0, LPlayer);
  Assert.AreEqual(20996, Length(FFiles.Files['SAVEGAME.0']));
  Assert.AreEqual(Fnv(@LPlayer, SizeOf(LPlayer)), Fnv(@FFiles.Files['SAVEGAME.0'][0], 20996));
end;

procedure TTestGreedSaveGames.DovrebbeDareFalsoSeIlFileNonCe;
var
  LPlayer: TGreedPlayerRecord;
begin
  FillPattern(LPlayer);
  Assert.IsFalse(FSut.LoadGame(7, LPlayer));
  // the record is not touched
  Assert.AreEqual(1, LPlayer.X);
end;

procedure TTestGreedSaveGames.DovrebbeSollevareSeIlFileEPiuCortoDelRecord;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 20995);
  FFiles.Files.Add('SAVEGAME.1', LBytes);
  Assert.WillRaise(
    procedure
    var
      LOther: TGreedPlayerRecord;
    begin
      FSut.LoadGame(1, LOther);
    end, EGreedDataException);
end;

procedure TTestGreedSaveGames.DovrebbeIgnorareIByteDopoIlRecord;
var
  LPlayer, LRead: TGreedPlayerRecord;
  LBytes: TBytes;
begin
  FillPattern(LPlayer);
  SetLength(LBytes, SizeOf(LPlayer) + 10);
  Move(LPlayer, LBytes[0], SizeOf(LPlayer));
  FFiles.Files.Add('SAVEGAME.2', LBytes);
  Assert.IsTrue(FSut.LoadGame(2, LRead));
  Assert.AreEqual(Fnv(@LPlayer, SizeOf(LPlayer)), Fnv(@LRead, SizeOf(LRead)));
end;

procedure TTestGreedSaveGames.DovrebbeDareINomiDeiFileDelGioco(AVariant: Integer; const AGame, ADirectory: string);
begin
  Make(TGreedGameVariant(AVariant));
  Assert.AreEqual(AGame, FSut.GameFileName(3));
  Assert.AreEqual(ADirectory, FSut.DirectoryFileName);
end;

procedure TTestGreedSaveGames.DovrebbeCreareLaDirectoryVuotaSeNonCe;
var
  LDirectory: TGreedSaveDirectory;
  LIndex: Integer;
begin
  LDirectory := FSut.ReadDirectory;
  for LIndex := 0 to GREED_MAX_SAVE_GAMES - 1 do
    Assert.AreEqual('', string(LDirectory[LIndex]));
  Assert.AreEqual(230, Length(FFiles.Files['SAVEGAME.DIR']));
end;

procedure TTestGreedSaveGames.DovrebbeRileggereLaDirectoryScritta;
var
  LDirectory, LRead: TGreedSaveDirectory;
  LIndex: Integer;
begin
  for LIndex := 0 to GREED_MAX_SAVE_GAMES - 1 do
    LDirectory[LIndex] := '';
  LDirectory[0] := 'FIRST LEVEL';
  LDirectory[9] := 'A NAME OF 22 LETTERS!';
  FSut.WriteDirectory(LDirectory);
  LRead := FSut.ReadDirectory;
  Assert.AreEqual('FIRST LEVEL', string(LRead[0]));
  Assert.AreEqual('A NAME OF 22 LETTERS!', string(LRead[9]));
  // a short string has its length in the first byte
  Assert.AreEqual<Integer>(11, FFiles.Files['SAVEGAME.DIR'][0]);
end;

procedure TTestGreedSaveGames.DovrebbeSollevareSeLaDirectoryEPiuCorta;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 229);
  FFiles.Files.Add('SAVEGAME.DIR', LBytes);
  Assert.WillRaise(
    procedure
    begin
      FSut.ReadDirectory;
    end, EGreedDataException);
end;

procedure TTestGreedSaveGames.DovrebbeAggiustareLoScrollInBassaRisoluzione;
var
  LPlayer: TGreedPlayerRecord;
begin
  LPlayer.ScrollMin := 100;
  LPlayer.ScrollMax := 500;
  TGreedSaveGames.AdjustScroll(LPlayer, True);
  Assert.AreEqual(50, LPlayer.ScrollMin);
  Assert.AreEqual(250, LPlayer.ScrollMax);
  // already 200 lines: kept
  TGreedSaveGames.AdjustScroll(LPlayer, True);
  Assert.AreEqual(50, LPlayer.ScrollMin);
  Assert.AreEqual(250, LPlayer.ScrollMax);
end;

procedure TTestGreedSaveGames.DovrebbeAggiustareLoScrollInAltaRisoluzione;
var
  LPlayer: TGreedPlayerRecord;
begin
  LPlayer.ScrollMin := 50;
  LPlayer.ScrollMax := 250;
  TGreedSaveGames.AdjustScroll(LPlayer, False);
  Assert.AreEqual(100, LPlayer.ScrollMin);
  Assert.AreEqual(500, LPlayer.ScrollMax);
  TGreedSaveGames.AdjustScroll(LPlayer, False);
  Assert.AreEqual(100, LPlayer.ScrollMin);
  Assert.AreEqual(500, LPlayer.ScrollMax);
end;

procedure TTestGreedSaveGames.DovrebbeSollevareSenzaFile;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedSaveGames.Create(nil, ggvDefault);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedSaveGames);

end.
