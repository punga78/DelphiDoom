{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - file system of id Tech 4, pure      }
{  server (the exclusion table, GetPackStatus, the pure lock)                  }
{                                                                              }
{  The parity tests compare with Tests\Data\Wad\GameFs\pureparity.expected.txt }
{  that the real code of Doom 3 printed (pureparity.cpp: the exclusion table,  }
{  the loop of GetPackStatus, the two sscanf of ParseAddonDef and the loop of  }
{  SetPureServerChecksums, compiled with bcc32c).                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.PureServer;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Wad.Fs.PureServer.Intf, DelphiDoom.Tests.Wad.MemoryWriteDisk;

type
  [TestFixture]
  [Category('wad')]
  TTestGamePackStatus = class(TObject)
  strict private
    function MakePack(const AFileName: string; const ANames: TArray<string>): IGamePack;
  public
    [Test]
    procedure DovrebbeEscludereLeCartelleEIFileDiLingua;
    [Test]
    procedure DovrebbeEscludereLaVoceFuoriDallaTabella;
    [Test]
    procedure DovrebbeContareLaLunghezzaDelNome;
    [Test]
    procedure DovrebbeDareMaiPerUnPakSoloDiFileEsclusi;
    [Test]
    procedure DovrebbeDareMaiPerUnPakVuoto;
    [Test]
    procedure DovrebbeDareSempreSeIlNomeComincia;
    [Test]
    procedure DovrebbeDareNeutroSeIlNomeNonComincia;
    [Test]
    procedure DovrebbeUsareSoloIlNomeDelFile;
  end;

  [TestFixture]
  [Category('wad')]
  TTestGamePureServer = class(TObject)
  strict private
    FServer: IGamePureServer;
    function Pack(const AFileName: string; AChecksum: Cardinal; AIsAddon: Boolean = False;
      AReferenced: Boolean = False; const ANames: TArray<string> = nil): IGamePack;
    procedure Start(const APacks, AAddons: TArray<IGamePack>);
  public
    [Test]
    procedure DovrebbeRifiutareUnFileSystemNil;
    [Test]
    procedure DovrebbeBloccareAiPakSempreESeNeutriSoloSeReferenziati;
    [Test]
    procedure DovrebbeDareICheckSumNellOrdineDellaLista;
    [Test]
    procedure DovrebbeSvuotareIlBlocco;
    [Test]
    procedure DovrebbeCalcolareLoStatoUnaVoltaSola;
    [Test]
    procedure DovrebbeTrovareUnPakPerCheckSum;
    [Test]
    procedure DovrebbeCercareNegliAddonSoloSeRichiesto;
    [Test]
    procedure DovrebbeFermarsiAlPrimoCheckSumZero;
    [Test]
    procedure DovrebbeRispondereOkConUnaListaVuota;
    [Test]
    procedure DovrebbeFallireAl128PakDelBlocco;
    [Test]
    procedure DovrebbeRispondereRestartSeUnFileVieneDaUnaCartella;
    [Test]
    procedure DovrebbeRispondereRestartPerUnAddonFuoriDallaLista;
  end;

  [TestFixture]
  [Category('wad')]
  TTestGamePureParity = class(TObject)
  strict private
    FGolden: TStringList;
    function GoldenLines(const APrefix: string): TArray<string>;
    function Pack(const AFileName: string; AChecksum: Cardinal; AIsAddon, AReferenced: Boolean): IGamePack;
    function FormatList(const AChecksums: TArray<Cardinal>): string;
    function Scenario(const AName: string; const AList: TArray<Cardinal>; AFromDirectory: Boolean;
      const AServer: IGamePureServer): string;
    function NewServer: IGamePureServer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLeStesseEsclusioniDelCodiceOriginale;
    [Test]
    procedure DovrebbeDareGliStessiStatiDelCodiceOriginale;
    [Test]
    procedure DovrebbeLeggereIChecksumComeLoSscanfDelCodiceOriginale;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCodiceOriginale;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Wad.Fs.PackStatus, DelphiDoom.Wad.Fs.PureServer, DelphiDoom.Wad.Fs.AddonParser,
  DelphiDoom.Wad.Fs.Factory;

function GoldenPath: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Wad\GameFs\pureparity.expected.txt');
end;

{ TTestGamePackStatus }

function TTestGamePackStatus.MakePack(const AFileName: string; const ANames: TArray<string>): IGamePack;
begin
  Result := TFakeGamePack.Create(AFileName, 1, ANames);
end;

procedure TTestGamePackStatus.DovrebbeEscludereLeCartelleEIFileDiLingua;
begin
  Assert.IsTrue(TGamePackStatus.IsExcluded('sound/'), 'folder');
  Assert.IsTrue(TGamePackStatus.IsExcluded('x\'), 'folder with backslash');
  Assert.IsTrue(TGamePackStatus.IsExcluded('guis/main.gui'), 'gui');
  Assert.IsTrue(TGamePackStatus.IsExcluded('a.pda'), 'pda');
  Assert.IsTrue(TGamePackStatus.IsExcluded('a.pd'), 'pd');
  Assert.IsTrue(TGamePackStatus.IsExcluded('strings/english.LANG'), 'lang');
  Assert.IsTrue(TGamePackStatus.IsExcluded('sound/VO/line.ogg'), 'voice over');
  Assert.IsTrue(TGamePackStatus.IsExcluded('SOUND\vo\line.WAV'), 'voice over, other case and separator');
  Assert.IsTrue(TGamePackStatus.IsExcluded('fonts/a.tga'), 'font');
  Assert.IsTrue(TGamePackStatus.IsExcluded('dds/fonts/a.dds'), 'dds font');
  Assert.IsTrue(TGamePackStatus.IsExcluded('Default.CFG'), 'full name');
  Assert.IsTrue(TGamePackStatus.IsExcluded('guis/temp.guied'), 'russian pak');
end;

procedure TTestGamePackStatus.DovrebbeEscludereLaVoceFuoriDallaTabella;
begin
  Assert.IsFalse(TGamePackStatus.IsExcluded('readme.txt'));
  Assert.IsFalse(TGamePackStatus.IsExcluded('sound'));
  Assert.IsFalse(TGamePackStatus.IsExcluded('default.cfg2'));
  Assert.IsFalse(TGamePackStatus.IsExcluded('.pd'), 'extension needs a name before it');
  Assert.IsFalse(TGamePackStatus.IsExcluded(''));
  Assert.IsFalse(TGamePackStatus.IsExcluded('dds/fonts'));
end;

procedure TTestGamePackStatus.DovrebbeContareLaLunghezzaDelNome;
begin
  // the prefix "sound/VO" also matches "sound/vox": the original compares the first characters only
  Assert.IsTrue(TGamePackStatus.IsExcluded('sound/vox/line.ogg'));
  Assert.IsTrue(TGamePackStatus.IsExcluded('sound/feedbacks/x.ogg'));
  // the full name must be the whole name
  Assert.IsFalse(TGamePackStatus.IsExcluded('sound/ed/marscity/vo_intro_cutscene.ogg2'));
end;

procedure TTestGamePackStatus.DovrebbeDareMaiPerUnPakSoloDiFileEsclusi;
begin
  Assert.AreEqual(Ord(TGamePureStatus.Never),
    Ord(TGamePackStatus.Classify(MakePack('c:\d3\base\pak000.pk4', ['a.gui', 'b/', 'strings/x.lang']))));
end;

procedure TTestGamePackStatus.DovrebbeDareMaiPerUnPakVuoto;
begin
  Assert.AreEqual(Ord(TGamePureStatus.Never), Ord(TGamePackStatus.Classify(MakePack('pak.pk4', nil))));
end;

procedure TTestGamePackStatus.DovrebbeDareSempreSeIlNomeComincia;
begin
  Assert.AreEqual(Ord(TGamePureStatus.Always),
    Ord(TGamePackStatus.Classify(MakePack('c:\d3\base\PAK000.pk4', ['a.gui', 'c.txt']))));
end;

procedure TTestGamePackStatus.DovrebbeDareNeutroSeIlNomeNonComincia;
begin
  Assert.AreEqual(Ord(TGamePureStatus.Neutral),
    Ord(TGamePackStatus.Classify(MakePack('c:\d3\base\zpak001.pk4', ['c.txt']))));
end;

procedure TTestGamePackStatus.DovrebbeUsareSoloIlNomeDelFile;
begin
  // "pak" in the folder does not count; '/' and '\' both separate
  Assert.AreEqual(Ord(TGamePureStatus.Neutral), Ord(TGamePackStatus.Classify(MakePack('c:/pakfolder/x.pk4', ['c.txt']))));
  Assert.AreEqual(Ord(TGamePureStatus.Always), Ord(TGamePackStatus.Classify(MakePack('c:/d3/base/Pak001.pk4', ['c.txt']))));
end;

{ TTestGamePureServer }

function TTestGamePureServer.Pack(const AFileName: string; AChecksum: Cardinal; AIsAddon, AReferenced: Boolean;
  const ANames: TArray<string>): IGamePack;
begin
  if ANames = nil then
    Result := TFakeGamePack.Create(AFileName, AChecksum, ['a.txt'], AIsAddon, AReferenced)
  else
    Result := TFakeGamePack.Create(AFileName, AChecksum, ANames, AIsAddon, AReferenced);
end;

procedure TTestGamePureServer.Start(const APacks, AAddons: TArray<IGamePack>);
begin
  FServer := TGamePureServer.Create(TFakeFileSystemState.Create(APacks, AAddons));
end;

procedure TTestGamePureServer.DovrebbeRifiutareUnFileSystemNil;
begin
  Assert.WillRaise(procedure begin TGamePureServer.Create(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TGameFileSystemFactory.CreatePureServer(nil); end, EGameFsException);
end;

procedure TTestGamePureServer.DovrebbeBloccareAiPakSempreESeNeutriSoloSeReferenziati;
begin
  Start([Pack('pak001.pk4', $11), Pack('x2.pk4', $22, False, True), Pack('x3.pk4', $33),
    Pack('x4.pk4', $44, False, False, ['a.gui'])], nil);
  FServer.UpdatePureServerChecksums;
  Assert.AreEqual<Integer>(2, Length(FServer.ServerPacks));
  Assert.AreEqual<Cardinal>($11, FServer.ServerPacks[0].Checksum);
  Assert.AreEqual<Cardinal>($22, FServer.ServerPacks[1].Checksum);
end;

procedure TTestGamePureServer.DovrebbeDareICheckSumNellOrdineDellaLista;
var
  LChecksums: TArray<Cardinal>;
begin
  Start([Pack('pak001.pk4', $11), Pack('pak000.pk4', $22)], nil);
  FServer.UpdatePureServerChecksums;
  LChecksums := FServer.GetPureServerChecksums;
  Assert.AreEqual<Integer>(2, Length(LChecksums));
  Assert.AreEqual<Cardinal>($11, LChecksums[0]);
  Assert.AreEqual<Cardinal>($22, LChecksums[1]);
end;

procedure TTestGamePureServer.DovrebbeSvuotareIlBlocco;
begin
  Start([Pack('pak001.pk4', $11)], nil);
  FServer.UpdatePureServerChecksums;
  FServer.ClearPureChecksums;
  Assert.AreEqual<Integer>(0, Length(FServer.ServerPacks));
  Assert.AreEqual<Integer>(0, Length(FServer.GetPureServerChecksums));
end;

procedure TTestGamePureServer.DovrebbeCalcolareLoStatoUnaVoltaSola;
var
  LPack: IGamePack;
begin
  LPack := Pack('x.pk4', $11, False, False, ['a.gui']);
  Start([LPack], nil);
  Assert.AreEqual(Ord(TGamePureStatus.Never), Ord(FServer.GetPackStatus(LPack)));
  Assert.AreEqual(Ord(TGamePureStatus.Never), Ord(FServer.GetPackStatus(LPack)));
end;

procedure TTestGamePureServer.DovrebbeTrovareUnPakPerCheckSum;
begin
  Start([Pack('pak001.pk4', $11)], nil);
  Assert.IsNotNull(FServer.GetPackForChecksum($11));
  Assert.IsNull(FServer.GetPackForChecksum($99));
end;

procedure TTestGamePureServer.DovrebbeCercareNegliAddonSoloSeRichiesto;
begin
  Start([Pack('pak001.pk4', $11)], [Pack('addon.pk4', $66, True)]);
  Assert.IsNull(FServer.GetPackForChecksum($66));
  Assert.IsNull(FServer.GetPackForChecksum($66, False));
  Assert.IsNotNull(FServer.GetPackForChecksum($66, True));
end;

procedure TTestGamePureServer.DovrebbeFermarsiAlPrimoCheckSumZero;
var
  LMissing: TArray<Cardinal>;
begin
  Start([Pack('pak001.pk4', $11)], nil);
  // what comes after the zero is not read
  Assert.AreEqual(Ord(TGamePureReply.Ok), Ord(FServer.SetPureServerChecksums([$11, 0, $99], LMissing)));
  Assert.AreEqual<Integer>(0, Length(LMissing));
end;

procedure TTestGamePureServer.DovrebbeRispondereOkConUnaListaVuota;
var
  LMissing: TArray<Cardinal>;
begin
  Start([Pack('pak001.pk4', $11)], nil);
  FServer.UpdatePureServerChecksums;
  Assert.AreEqual(Ord(TGamePureReply.Ok), Ord(FServer.SetPureServerChecksums(nil, LMissing)));
  Assert.AreEqual<Integer>(0, Length(FServer.ServerPacks));
  FServer.UpdatePureServerChecksums;
  Assert.AreEqual(Ord(TGamePureReply.Ok), Ord(FServer.SetPureServerChecksums([0], LMissing)));
  Assert.AreEqual<Integer>(0, Length(FServer.ServerPacks));
end;

procedure TTestGamePureServer.DovrebbeFallireAl128PakDelBlocco;
var
  LPacks: TArray<IGamePack>;
  LIndex: Integer;
begin
  SetLength(LPacks, 128);
  for LIndex := 0 to 127 do
    LPacks[LIndex] := Pack(Format('pak%.3d.pk4', [LIndex]), Cardinal(LIndex + 1));
  Start(LPacks, nil);
  Assert.WillRaise(procedure begin FServer.UpdatePureServerChecksums; end, EGameFsException);
  // 127 are fine
  SetLength(LPacks, 127);
  Start(LPacks, nil);
  FServer.UpdatePureServerChecksums;
  Assert.AreEqual<Integer>(127, Length(FServer.ServerPacks));
end;

procedure TTestGamePureServer.DovrebbeRispondereRestartSeUnFileVieneDaUnaCartella;
var
  LMissing: TArray<Cardinal>;
begin
  Start([Pack('pak001.pk4', $11)], nil);
  Assert.AreEqual(Ord(TGamePureReply.Ok), Ord(FServer.SetPureServerChecksums([$11], LMissing, False)));
  Assert.AreEqual(Ord(TGamePureReply.Restart), Ord(FServer.SetPureServerChecksums([$11], LMissing, True)));
end;

procedure TTestGamePureServer.DovrebbeRispondereRestartPerUnAddonFuoriDallaLista;
var
  LMissing: TArray<Cardinal>;
begin
  Start([Pack('pak001.pk4', $11)], [Pack('addon.pk4', $66, True)]);
  Assert.AreEqual(Ord(TGamePureReply.Restart), Ord(FServer.SetPureServerChecksums([$66, $11], LMissing)));
  // the addon was put in the list anyway, in front
  Assert.AreEqual<Cardinal>($66, FServer.ServerPacks[0].Checksum);
end;

{ TTestGamePureParity }

procedure TTestGamePureParity.Setup;
begin
  FGolden := TStringList.Create;
  FGolden.LoadFromFile(GoldenPath, TEncoding.ANSI);
end;

procedure TTestGamePureParity.TearDown;
begin
  FGolden.Free;
end;

function TTestGamePureParity.GoldenLines(const APrefix: string): TArray<string>;
var
  LLine: string;
begin
  Result := nil;
  for LLine in FGolden do
    if LLine.StartsWith(APrefix) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LLine;
    end;
end;

function TTestGamePureParity.Pack(const AFileName: string; AChecksum: Cardinal; AIsAddon,
  AReferenced: Boolean): IGamePack;
begin
  Result := TFakeGamePack.Create(AFileName, AChecksum, ['a.txt'], AIsAddon, AReferenced);
end;

function TTestGamePureParity.FormatList(const AChecksums: TArray<Cardinal>): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(AChecksums) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + LowerCase(IntToHex(AChecksums[LIndex], 1));
  end;
end;

function TTestGamePureParity.NewServer: IGamePureServer;
var
  LPacks, LAddons: TArray<IGamePack>;
begin
  // 1 always, 2 neutral and referenced, 3 neutral, 4 never, 5 addon on the search list, 6 addon left out
  LPacks := [Pack('pak001.pk4', $11, False, False), Pack('x2.pk4', $22, False, True), Pack('x3.pk4', $33, False, False),
    TFakeGamePack.Create('x4.pk4', $44, ['a.gui']), Pack('pak005.pk4', $55, True, False)];
  LAddons := [Pack('x6.pk4', $66, True, False)];
  Result := TGamePureServer.Create(TFakeFileSystemState.Create(LPacks, LAddons));
end;

function TTestGamePureParity.Scenario(const AName: string; const AList: TArray<Cardinal>; AFromDirectory: Boolean;
  const AServer: IGamePureServer): string;
var
  LMissing: TArray<Cardinal>;
  LReply: TGamePureReply;
begin
  LReply := AServer.SetPureServerChecksums(AList, LMissing, AFromDirectory);
  Result := Format('pure %s reply=%d missing=%s server=%s',
    [AName, Ord(LReply), FormatList(LMissing), FormatList(AServer.GetPureServerChecksums)]);
end;

procedure TTestGamePureParity.DovrebbeDareLeStesseEsclusioniDelCodiceOriginale;
var
  LLine, LName, LRest: string;
  LLast: Integer;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in GoldenLines('excl ') do
  begin
    LRest := Copy(LLine, 6, MaxInt);
    LLast := LRest.LastIndexOf(' ') + 1;
    LName := Copy(LRest, 1, LLast - 1);
    Assert.AreEqual<Boolean>(LRest[LLast + 1] = '1', TGamePackStatus.IsExcluded(LName), LLine);
    Inc(LCount);
  end;
  Assert.IsTrue(LCount >= 25, 'the golden has the names');
end;

procedure TTestGamePureParity.DovrebbeDareGliStessiStatiDelCodiceOriginale;
var
  LLines: TArray<string>;

  procedure Check(AIndex: Integer; const AFileName: string; const ANames: TArray<string>);
  var
    LStatus: Integer;
  begin
    LStatus := Ord(TGamePackStatus.Classify(TFakeGamePack.Create(AFileName, 1, ANames)));
    Assert.AreEqual(IntToStr(LStatus), LLines[AIndex].Substring(LLines[AIndex].LastIndexOf(' ') + 1), LLines[AIndex]);
  end;

begin
  LLines := GoldenLines('status ');
  Assert.AreEqual<Integer>(6, Length(LLines));
  Check(0, 'c:\d3\base\pak000.pk4', ['a.gui', 'b/']);
  Check(1, 'c:\d3\base\PAK000.pk4', ['a.gui', 'b/', 'c.txt']);
  Check(2, 'c:/d3/base/Pak001.pk4', ['a.gui', 'b/', 'c.txt']);
  Check(3, 'c:\d3\base\zpak001.pk4', ['a.gui', 'b/', 'c.txt']);
  Check(4, 'pakx.pk4', ['a.gui', 'b/', 'c.txt']);
  Check(5, 'pak.pk4', nil);
end;

procedure TTestGamePureParity.DovrebbeLeggereIChecksumComeLoSscanfDelCodiceOriginale;
var
  LLine, LText, LRest: string;
  LValue: Cardinal;
  LOk: Boolean;
  LOpen, LClose: Integer;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in GoldenLines('chk [') do
  begin
    LOpen := Pos('[', LLine);
    LClose := LLine.LastIndexOf(']') + 1;
    LText := Copy(LLine, LOpen + 1, LClose - LOpen - 1);
    LRest := Copy(LLine, LClose + 2, MaxInt);
    LOk := TGameAddonParser.ParseChecksum(AnsiString(LText), LValue);
    if LOk then
      Assert.AreEqual('1 ' + LowerCase(IntToHex(LValue, 1)), LRest, LLine)
    else
      Assert.AreEqual('0 0', LRest, LLine);
    Inc(LCount);
  end;
  Assert.IsTrue(LCount >= 13, 'the golden has the texts');
end;

procedure TTestGamePureParity.DovrebbeDareLeStesseRisposteDelCodiceOriginale;
var
  LLines: TArray<string>;
  LIndex: Integer;
  LServer: IGamePureServer;
  LLock: IGamePureServer;

  procedure Expect(const AActual: string);
  begin
    Assert.AreEqual(LLines[LIndex], AActual);
    Inc(LIndex);
  end;

begin
  LLines := GoldenLines('update');
  LServer := NewServer;
  LServer.UpdatePureServerChecksums;
  Assert.AreEqual(LLines[0], 'update server=' + FormatList(LServer.GetPureServerChecksums));
  LLines := GoldenLines('pure ');
  LIndex := 0;
  Expect(Scenario('empty-clears', [0], False, NewServer));
  Expect(Scenario('same', [$11, $22, $55, 0], False, NewServer));
  Expect(Scenario('same-fromdir', [$11, $22, $55, 0], True, NewServer));
  Expect(Scenario('prepend', [$33, $11, $22, $55, 0], False, NewServer));
  Expect(Scenario('wrong-order', [$11, $33, $22, $55, 0], False, NewServer));
  Expect(Scenario('extra-local', [$11, $22, 0], False, NewServer));
  Expect(Scenario('missing-first', [$99, $11, $22, $55, 0], False, NewServer));
  Expect(Scenario('missing-two', [$11, $99, $22, $88, $55, 0], False, NewServer));
  Expect(Scenario('addon-left-out', [$66, $11, $22, $55, 0], False, NewServer));
  Expect(Scenario('addon-after', [$11, $22, $55, $66, 0], False, NewServer));
  Expect(Scenario('never-pak-asked', [$44, $11, $22, $55, 0], False, NewServer));
  Expect(Scenario('swapped', [$22, $11, 0], False, NewServer));
  // a lock that already exists is kept and extended
  LLock := NewServer;
  Expect(Scenario('lock-one', [$22, 0], False, LLock));
  Expect(Scenario('lock-extend', [$33, $22, 0], False, LLock));
  Assert.AreEqual<Integer>(Length(LLines), LIndex, 'every scenario of the golden was run');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGamePackStatus);
  TDUnitX.RegisterTestFixture(TTestGamePureServer);
  TDUnitX.RegisterTestFixture(TTestGamePureParity);

end.
