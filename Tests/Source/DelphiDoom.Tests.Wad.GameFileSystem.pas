{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - file system of id Tech 4             }
{  (search list, paks, relative paths, lists of files)                         }
{                                                                              }
{  The expected values come from reading framework\FileSystem.cpp of Doom 3   }
{  (and, for the hashes, from hand calculation); the disks and the paks are   }
{  built in memory.                                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.GameFileSystem;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Tests.Wad.MemoryDisk;

type
  [TestFixture]
  [Category('wad')]
  TTestGameFsPaths = class(TObject)
  public
    [Test]
    procedure DovrebbeCalcolareLHashDeiNomi;
    [Test]
    procedure DovrebbeIgnorareMaiuscoleESeparatoriNellHash;
    [Test]
    procedure DovrebbeFermareLHashAlPrimoPunto;
    [Test]
    procedure DovrebbeConfrontareIgnorandoMaiuscoleESeparatori;
    [Test]
    procedure DovrebbeRifiutareIPercorsiCheRisalgono;
    [Test]
    procedure DovrebbeToglierelaBarraIniziale;
    [Test]
    procedure DovrebbeCostruireIlPercorsoDelSistema;
    [Test]
    procedure DovrebbeDividereLeEstensioni;
    [Test]
    procedure DovrebbeOrdinareConLeCartellePrima;
    [Test]
    procedure DovrebbeTogliereLeBarreFinali;
  end;

  [TestFixture]
  [Category('wad')]
  TTestGamePack = class(TObject)
  public
    [Test]
    procedure DovrebbeTrovareUnaVoceSenzaMaiuscoleESeparatori;
    [Test]
    procedure DovrebbeFarVincereLUltimaVoceDoppia;
    [Test]
    procedure DovrebbeNonTrovareConDuePuntiDoveCeUnaBarra;
    [Test]
    procedure DovrebbeCalcolareIlChecksumSulleVociNonVuote;
    [Test]
    procedure DovrebbeRiconoscereUnAddon;
    [Test]
    procedure DovrebbeLeggereIByteDiUnaVoce;
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonEUnoZip;
    [Test]
    procedure DovrebbeDareNilSeIlFileManca;
    [Test]
    procedure DovrebbeTenereLeVociDelleCartelle;
  end;

  [TestFixture]
  [Category('wad')]
  TTestGameFileSystem = class(TObject)
  strict private
    FDisk: TMemoryGameDisk;
    FDiskIntf: IGameDisk;
    FSettings: TGameFsSettings;
    function MakeSystem: IGameFileSystem;
    function ReadText(const AFileSystem: IGameFileSystem; const APath: string): string;
    class function Join(const AValues: TArray<string>): string; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareLeChiamateSenzaStartup;
    [Test]
    procedure DovrebbeOrdinareLaListaDiRicercaConIlModSopraLaBase;
    [Test]
    procedure DovrebbeOrdinareICamminiCdBaseDevSave;
    [Test]
    procedure DovrebbeIgnorareGameUgualeAllaBase;
    [Test]
    procedure DovrebbeIgnorareGameUgualeAGameBase;
    [Test]
    procedure DovrebbeSaltareUnPakRotto;
    [Test]
    procedure DovrebbeFarVincereIFileDellaCartellaSuiPak;
    [Test]
    procedure DovrebbeFarVincereIlPakPiuAlto;
    [Test]
    procedure DovrebbeFarVincereIlModSopraLaBase;
    [Test]
    procedure DovrebbeTrovareConMaiuscoleEBarreInverse;
    [Test]
    procedure DovrebbeAccettareLaBarraIniziale;
    [Test]
    procedure DovrebbeRifiutarePercorsiNonValidi;
    [Test]
    procedure DovrebbeDareIlTimestampSoloAiFileDelleCartelle;
    [Test]
    procedure DovrebbeDareNomeEPercorsoCompletoDelFile;
    [Test]
    procedure DovrebbeLeggereIFileInMemoria;
    [Test]
    procedure DovrebbeDareLaLunghezzaOMenoUno;
    [Test]
    procedure DovrebbeRifiutareUnNomeVuotoInReadFile;
    [Test]
    procedure DovrebbeCercareSoloNeiPakOSoloNelleCartelle;
    [Test]
    procedure DovrebbeMarcareIPakLettiComeReferenziati;
    [Test]
    procedure DovrebbeNonMarcareConNoReference;
    [Test]
    procedure DovrebbeLimitareLeCartelleAlGameDirMaNonIPak;
    [Test]
    procedure DovrebbeDireSeUnFileEInUnPak;
    [Test]
    procedure DovrebbeTenereGliAddonFuoriDallaLista;
    [Test]
    procedure DovrebbeCercareNegliAddonSeRichiesto;
    [Test]
    procedure DovrebbeTenereGliAddonConSearchAddons;
    [Test]
    procedure DovrebbeDareIChecksumDeiPakInOrdine;
    [Test]
    procedure DovrebbeElencareUnaVoltaOgniNomeDaCartelleEPak;
    [Test]
    procedure DovrebbeElencareConPiuEstensioni;
    [Test]
    procedure DovrebbeElencareLeCartelleDeiPak;
    [Test]
    procedure DovrebbeElencareConIlPercorsoRelativoCompleto;
    [Test]
    procedure DovrebbeElencareLAlberoConLeCartellePrima;
    [Test]
    procedure DovrebbeOrdinareLElenco;
    [Test]
    procedure DovrebbeElencareConIlNomeDelPakInMinuscolo;
    [Test]
    procedure DovrebbeElencareConGameDir;
    [Test]
    procedure DovrebbeRiavviareDopoLoShutdown;
    [Test]
    procedure DovrebbeLeggereUnaCartellaVuotaComeTutteLeVoci;
  end;

implementation

uses
  System.Zip, System.Generics.Collections, DelphiDoom.IdLib.Hashing.Md4, DelphiDoom.IdLib.Hashing.Types,
  DelphiDoom.Wad.Fs.Paths, DelphiDoom.Wad.Fs.Pack, DelphiDoom.Wad.Fs.PackLoader, DelphiDoom.Wad.Fs.Factory;

const
  BASE_DIR = 'C:\d3';

{ TTestGameFsPaths }

procedure TTestGameFsPaths.DovrebbeCalcolareLHashDeiNomi;
begin
  // 'a' = 97 * 119 = 11543; 11543 and 1023 = 279
  Assert.AreEqual(279, TGameFsPaths.HashFileName('a'));
  // 97 * 119 + 98 * 120 = 23303; 23303 and 1023 = 775; the extension is not hashed
  Assert.AreEqual(775, TGameFsPaths.HashFileName('ab.c'));
  Assert.AreEqual(0, TGameFsPaths.HashFileName(''));
end;

procedure TTestGameFsPaths.DovrebbeIgnorareMaiuscoleESeparatoriNellHash;
begin
  // 97 * 119 + 47 * 120 + 98 * 121 = 29041; and 1023 = 369
  Assert.AreEqual(369, TGameFsPaths.HashFileName('a/b'));
  Assert.AreEqual(369, TGameFsPaths.HashFileName('A\B'));
  // ':' is not a separator for the hash: 97 * 119 + 58 * 120 + 98 * 121 = 30361; and 1023 = 665
  Assert.AreEqual(665, TGameFsPaths.HashFileName('a:b'));
end;

procedure TTestGameFsPaths.DovrebbeFermareLHashAlPrimoPunto;
begin
  Assert.AreEqual(TGameFsPaths.HashFileName('tex'), TGameFsPaths.HashFileName('tex.tga'));
  Assert.AreEqual(TGameFsPaths.HashFileName('tex'), TGameFsPaths.HashFileName('tex.a.b'));
end;

procedure TTestGameFsPaths.DovrebbeConfrontareIgnorandoMaiuscoleESeparatori;
begin
  Assert.IsTrue(TGameFsPaths.NamesEqual('Textures\Wall.TGA', 'textures/wall.tga'));
  Assert.IsTrue(TGameFsPaths.NamesEqual('a:b', 'a/b'));
  Assert.IsFalse(TGameFsPaths.NamesEqual('a/b', 'a/bc'));
  Assert.IsFalse(TGameFsPaths.NamesEqual('a/b', 'a/c'));
  Assert.IsTrue(TGameFsPaths.NamesEqual('', ''));
  Assert.IsTrue(TGameFsPaths.SameIgnoringCase('ABC', 'abc'));
  Assert.IsFalse(TGameFsPaths.SameIgnoringCase('a/b', 'a\b'));
  // only A to Z change
  Assert.AreEqual('abc/' + #$00C4, TGameFsPaths.ToLowerAscii('ABC/' + #$00C4));
end;

procedure TTestGameFsPaths.DovrebbeRifiutareIPercorsiCheRisalgono;
var
  LClean: string;
begin
  Assert.IsFalse(TGameFsPaths.CleanRelativePath('../x', LClean));
  Assert.IsFalse(TGameFsPaths.CleanRelativePath('a/../x', LClean));
  Assert.IsFalse(TGameFsPaths.CleanRelativePath('c::x', LClean));
  // '..' anywhere counts, as strstr in the original
  Assert.IsFalse(TGameFsPaths.CleanRelativePath('a..b', LClean));
  Assert.IsTrue(TGameFsPaths.CleanRelativePath('c:x', LClean));
end;

procedure TTestGameFsPaths.DovrebbeToglierelaBarraIniziale;
var
  LClean: string;
begin
  Assert.IsTrue(TGameFsPaths.CleanRelativePath('/a/b', LClean));
  Assert.AreEqual('a/b', LClean);
  Assert.IsTrue(TGameFsPaths.CleanRelativePath('\a', LClean));
  Assert.AreEqual('a', LClean);
  // only one
  Assert.IsTrue(TGameFsPaths.CleanRelativePath('//a', LClean));
  Assert.AreEqual('/a', LClean);
  Assert.IsTrue(TGameFsPaths.CleanRelativePath('', LClean));
  Assert.AreEqual('', LClean);
end;

procedure TTestGameFsPaths.DovrebbeCostruireIlPercorsoDelSistema;
begin
  Assert.AreEqual('C:\d3\base\a\b.txt', TGameFsPaths.BuildOSPath('C:\d3\', 'base', 'a/b.txt'));
  Assert.AreEqual('C:\d3\base\a\b.txt', TGameFsPaths.BuildOSPath('C:/d3//', 'base', 'a\b.txt'));
  Assert.AreEqual('C:\d3\base\', TGameFsPaths.BuildOSPath('C:\d3', 'base', ''));
end;

procedure TTestGameFsPaths.DovrebbeDividereLeEstensioni;
var
  LList: TArray<string>;
begin
  LList := TGameFsPaths.SplitExtensions('tga|dds');
  Assert.AreEqual(2, Length(LList));
  Assert.AreEqual('tga', LList[0]);
  Assert.AreEqual('dds', LList[1]);
  LList := TGameFsPaths.SplitExtensions('');
  Assert.AreEqual(1, Length(LList));
  Assert.AreEqual('', LList[0]);
  LList := TGameFsPaths.SplitExtensions('a|');
  Assert.AreEqual(2, Length(LList));
  Assert.AreEqual('', LList[1]);
  LList := TGameFsPaths.SplitExtensions('/');
  Assert.AreEqual('/', LList[0]);
end;

procedure TTestGameFsPaths.DovrebbeOrdinareConLeCartellePrima;
var
  LList: TArray<string>;
begin
  LList := TArray<string>.Create('b.txt', 'a/z.txt', 'A.txt', 'a/b.txt');
  TGameFsPaths.SortPaths(LList);
  Assert.AreEqual('a/b.txt,a/z.txt,A.txt,b.txt', string.Join(',', LList));
end;

procedure TTestGameFsPaths.DovrebbeTogliereLeBarreFinali;
begin
  Assert.AreEqual('a/b', TGameFsPaths.StripTrailingSlashes('a/b//'));
  Assert.AreEqual('', TGameFsPaths.StripTrailingSlashes('/'));
  Assert.AreEqual('a\', TGameFsPaths.StripTrailingSlashes('a\'));
end;

{ TTestGamePack }

type
  TPackHarness = class
  public
    class function Load(const AZip: TBytes; out ADisk: IGameDisk): IGamePack; static;
  end;

class function TPackHarness.Load(const AZip: TBytes; out ADisk: IGameDisk): IGamePack;
var
  LDisk: TMemoryGameDisk;
begin
  LDisk := TMemoryGameDisk.Create;
  ADisk := LDisk;
  LDisk.AddFile('C:\p\test.pk4', AZip);
  Result := TZipPackLoader.Create(ADisk).Load('C:\p\test.pk4');
end;

procedure TTestGamePack.DovrebbeTrovareUnaVoceSenzaMaiuscoleESeparatori;
var
  LDisk: IGameDisk;
  LPack: IGamePack;
begin
  LPack := TPackHarness.Load(TMemoryZip.Make(['Textures/Wall.TGA', 'a.txt'], ['w', 'a']), LDisk);
  Assert.AreEqual(2, LPack.EntryCount);
  Assert.AreEqual('textures/wall.tga', LPack.EntryName(0));
  Assert.AreEqual(0, LPack.FindEntry('TEXTURES\wall.tga'));
  Assert.AreEqual(1, LPack.FindEntry('A.TXT'));
  Assert.AreEqual(-1, LPack.FindEntry('b.txt'));
  Assert.AreEqual(-1, LPack.FindEntry('textures'));
  Assert.AreEqual('C:\p\test.pk4', LPack.FileName);
end;

procedure TTestGamePack.DovrebbeFarVincereLUltimaVoceDoppia;
var
  LDisk: IGameDisk;
  LPack: IGamePack;
begin
  LPack := TPackHarness.Load(TMemoryZip.Make(['a.txt', 'x.txt', 'A.TXT'], ['first', 'x', 'second']), LDisk);
  Assert.AreEqual(2, LPack.FindEntry('a.txt'));
  Assert.AreEqual('second', TEncoding.UTF8.GetString(LPack.ReadEntry(LPack.FindEntry('a.txt'))));
end;

procedure TTestGamePack.DovrebbeNonTrovareConDuePuntiDoveCeUnaBarra;
var
  LDisk: IGameDisk;
  LPack: IGamePack;
begin
  LPack := TPackHarness.Load(TMemoryZip.Make(['a/b'], ['x']), LDisk);
  Assert.AreEqual(0, LPack.FindEntry('a/b'));
  // equal for FilenameCompare, but another bucket of the hash: not found, as in the original
  Assert.IsTrue(TGameFsPaths.NamesEqual('a:b', 'a/b'));
  Assert.AreEqual(-1, LPack.FindEntry('a:b'));
end;

procedure TTestGamePack.DovrebbeCalcolareIlChecksumSulleVociNonVuote;
var
  LDisk: IGameDisk;
  LPack: IGamePack;
  LCrcs: TArray<Cardinal>;
  LZip: TZipFile;
  LStream: TBytesStream;
  LBytes: TBytes;
  LExpected: Cardinal;
begin
  LBytes := TMemoryZip.Make(['one.txt', 'dir/', 'two.txt'], ['hello', '', 'world!']);
  LPack := TPackHarness.Load(LBytes, LDisk);
  // the CRCs read again from the central directory, by hand
  LStream := TBytesStream.Create(LBytes);
  LZip := TZipFile.Create;
  try
    LZip.Open(LStream, TZipMode.zmRead);
    Assert.AreEqual(3, LZip.FileCount);
    SetLength(LCrcs, 2);
    LCrcs[0] := LZip.FileInfos[0].CRC32;
    LCrcs[1] := LZip.FileInfos[2].CRC32;
  finally
    LZip.Free;
    LStream.Free;
  end;
  // the empty entry does not count
  LExpected := TIdMd4.BlockChecksum(LCrcs[0], 8);
  Assert.AreEqual(LExpected, LPack.Checksum);
  Assert.AreEqual(Int64(Length(LBytes)), LPack.Length);
end;

procedure TTestGamePack.DovrebbeRiconoscereUnAddon;
var
  LDisk: IGameDisk;
begin
  Assert.IsTrue(TPackHarness.Load(TMemoryZip.Make(['Addon.CONF', 'x'], ['', 'x']), LDisk).IsAddon);
  Assert.IsFalse(TPackHarness.Load(TMemoryZip.Make(['sub/addon.conf'], ['']), LDisk).IsAddon);
end;

procedure TTestGamePack.DovrebbeLeggereIByteDiUnaVoce;
var
  LDisk: IGameDisk;
  LPack: IGamePack;
begin
  LPack := TPackHarness.Load(TMemoryZip.Make(['a.bin'], ['bytes of a']), LDisk);
  Assert.AreEqual(Int64(10), LPack.EntrySize(0));
  Assert.AreEqual('bytes of a', TEncoding.UTF8.GetString(LPack.ReadEntry(0)));
  Assert.IsFalse(LPack.Referenced);
  LPack.Referenced := True;
  Assert.IsTrue(LPack.Referenced);
end;

procedure TTestGamePack.DovrebbeRifiutareUnFileCheNonEUnoZip;
var
  LDisk: IGameDisk;
begin
  Assert.IsNull(TPackHarness.Load(TMemoryZip.Bytes('this is not a zip file at all'), LDisk));
end;

procedure TTestGamePack.DovrebbeDareNilSeIlFileManca;
var
  LDisk: IGameDisk;
begin
  TPackHarness.Load(TMemoryZip.Make(['a'], ['a']), LDisk);
  Assert.IsNull(TZipPackLoader.Create(LDisk).Load('C:\p\missing.pk4'));
end;

procedure TTestGamePack.DovrebbeTenereLeVociDelleCartelle;
var
  LDisk: IGameDisk;
  LPack: IGamePack;
begin
  LPack := TPackHarness.Load(TMemoryZip.Make(['sound/', 'sound/x.wav'], ['', 'x']), LDisk);
  Assert.AreEqual(2, LPack.EntryCount);
  Assert.AreEqual('sound/', LPack.EntryName(0));
end;

{ TTestGameFileSystem }

procedure TTestGameFileSystem.Setup;
begin
  FDisk := TMemoryGameDisk.Create;
  FDiskIntf := FDisk;
  FDisk.AddFile('C:\d3\base\pak000.pk4', TMemoryZip.Make(
    ['textures/wall.tga', 'def/a.def', 'maps/Test.map', 'sound/', 'sound/x.wav', 'sound/sub/', 'sound/sub/y.wav', 'readme.txt'],
    ['p0wall', 'p0a', 'p0map', '', 'p0x', '', 'p0y', 'p0readme']));
  FDisk.AddFile('C:\d3\base\pak001.pk4', TMemoryZip.Make(
    ['Textures/WALL.TGA', 'def/b.def'], ['p1wall', 'p1b']));
  FDisk.AddFile('C:\d3\base\bad.pk4', TMemoryZip.Bytes('garbage'));
  FDisk.AddFile('C:\d3\base\loose.txt', TMemoryZip.Bytes('loose'), 1234);
  FDisk.AddText('C:\d3\base\def\a.def', 'looseA');
  FDisk.AddText('C:\d3\base\sound\z.wav', 'z');
  FDisk.AddFile('C:\d3\mod\pak000.pk4', TMemoryZip.Make(
    ['textures/wall.tga', 'mod.txt'], ['modwall', 'modtxt']));
  FSettings := Default(TGameFsSettings);
  FSettings.BasePath := BASE_DIR;
end;

procedure TTestGameFileSystem.TearDown;
begin
  FDiskIntf := nil;
  FDisk := nil;
end;

function TTestGameFileSystem.MakeSystem: IGameFileSystem;
begin
  Result := TGameFileSystemFactory.CreateWithDisk(FDiskIntf, FSettings);
  Result.Startup;
end;

function TTestGameFileSystem.ReadText(const AFileSystem: IGameFileSystem; const APath: string): string;
var
  LData: TBytes;
begin
  if AFileSystem.ReadFile(APath, LData) then
    Result := TEncoding.UTF8.GetString(LData)
  else
    Result := '<missing>';
end;

class function TTestGameFileSystem.Join(const AValues: TArray<string>): string;
begin
  Result := string.Join(',', AValues);
end;

procedure TTestGameFileSystem.DovrebbeRifiutareLeChiamateSenzaStartup;
var
  LSystem: IGameFileSystem;
  LData: TBytes;
begin
  LSystem := TGameFileSystemFactory.CreateWithDisk(FDiskIntf, FSettings);
  Assert.IsFalse(LSystem.IsInitialized);
  Assert.WillRaise(procedure begin LSystem.OpenFileRead('a'); end, EGameFsException);
  Assert.WillRaise(procedure begin LSystem.ReadFile('a', LData); end, EGameFsException);
  Assert.WillRaise(procedure begin LSystem.ListFiles('a', 'b'); end, EGameFsException);
  Assert.WillRaise(procedure begin LSystem.FileIsInPak('a'); end, EGameFsException);
  Assert.WillRaise(procedure begin LSystem.SearchPaths; end, EGameFsException);
end;

procedure TTestGameFileSystem.DovrebbeOrdinareLaListaDiRicercaConIlModSopraLaBase;
var
  LPaths: TArray<TGameSearchPath>;
begin
  FSettings.Game := 'mod';
  LPaths := MakeSystem.SearchPaths;
  // the folder, then its paks from the last, then what was added before
  Assert.AreEqual(5, Length(LPaths));
  Assert.IsTrue(LPaths[0].IsDirectory);
  Assert.AreEqual('mod', LPaths[0].GameDir);
  Assert.AreEqual('C:\d3\mod\pak000.pk4', LPaths[1].PackFileName);
  Assert.IsTrue(LPaths[2].IsDirectory);
  Assert.AreEqual('base', LPaths[2].GameDir);
  Assert.AreEqual(BASE_DIR, LPaths[2].Path);
  Assert.AreEqual('C:\d3\base\pak001.pk4', LPaths[3].PackFileName);
  Assert.AreEqual('C:\d3\base\pak000.pk4', LPaths[4].PackFileName);
end;

procedure TTestGameFileSystem.DovrebbeOrdinareICamminiCdBaseDevSave;
var
  LPaths: TArray<TGameSearchPath>;
begin
  FSettings.CdPath := 'C:\cd';
  FSettings.DevPath := 'C:\dev';
  FSettings.SavePath := 'C:\save';
  FSettings.GameBase := 'gb';
  LPaths := MakeSystem.SearchPaths;
  // for each game folder cd, base, dev, save are added, so save comes first; then gb over base
  Assert.AreEqual('C:\save|gb', LPaths[0].Path + '|' + LPaths[0].GameDir);
  Assert.AreEqual('C:\dev|gb', LPaths[1].Path + '|' + LPaths[1].GameDir);
  Assert.AreEqual('C:\d3|gb', LPaths[2].Path + '|' + LPaths[2].GameDir);
  Assert.AreEqual('C:\cd|gb', LPaths[3].Path + '|' + LPaths[3].GameDir);
  Assert.AreEqual('C:\save|base', LPaths[4].Path + '|' + LPaths[4].GameDir);
  Assert.AreEqual('C:\dev|base', LPaths[5].Path + '|' + LPaths[5].GameDir);
  Assert.AreEqual('C:\d3|base', LPaths[6].Path + '|' + LPaths[6].GameDir);
  Assert.AreEqual('C:\d3\base\pak001.pk4', LPaths[7].PackFileName);
  Assert.AreEqual('C:\d3\base\pak000.pk4', LPaths[8].PackFileName);
  Assert.AreEqual('C:\cd|base', LPaths[9].Path + '|' + LPaths[9].GameDir);
  Assert.AreEqual(10, Length(LPaths));
end;

procedure TTestGameFileSystem.DovrebbeIgnorareGameUgualeAllaBase;
begin
  FSettings.Game := 'BASE';
  FSettings.GameBase := 'Base';
  Assert.AreEqual(3, Length(MakeSystem.SearchPaths));
end;

procedure TTestGameFileSystem.DovrebbeIgnorareGameUgualeAGameBase;
var
  LPaths: TArray<TGameSearchPath>;
begin
  FSettings.GameBase := 'mod';
  FSettings.Game := 'MOD';
  LPaths := MakeSystem.SearchPaths;
  Assert.AreEqual(5, Length(LPaths));
  Assert.AreEqual('mod', LPaths[0].GameDir);
end;

procedure TTestGameFileSystem.DovrebbeSaltareUnPakRotto;
var
  LPath: TGameSearchPath;
begin
  for LPath in MakeSystem.SearchPaths do
    Assert.IsFalse(LPath.PackFileName.EndsWith('bad.pk4'));
end;

procedure TTestGameFileSystem.DovrebbeFarVincereIFileDellaCartellaSuiPak;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.AreEqual('looseA', ReadText(LSystem, 'def/a.def'));
  Assert.AreEqual('p1b', ReadText(LSystem, 'def/b.def'));
end;

procedure TTestGameFileSystem.DovrebbeFarVincereIlPakPiuAlto;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  // pak001 over pak000, the name in another case
  Assert.AreEqual('p1wall', ReadText(LSystem, 'textures/wall.tga'));
  Assert.AreEqual('p0readme', ReadText(LSystem, 'readme.txt'));
end;

procedure TTestGameFileSystem.DovrebbeFarVincereIlModSopraLaBase;
var
  LSystem: IGameFileSystem;
begin
  FSettings.Game := 'mod';
  LSystem := MakeSystem;
  Assert.AreEqual('modwall', ReadText(LSystem, 'textures/wall.tga'));
  Assert.AreEqual('modtxt', ReadText(LSystem, 'mod.txt'));
  // what the mod does not have comes from the base
  Assert.AreEqual('loose', ReadText(LSystem, 'loose.txt'));
end;

procedure TTestGameFileSystem.DovrebbeTrovareConMaiuscoleEBarreInverse;
begin
  Assert.AreEqual('p1wall', ReadText(MakeSystem, 'TEXTURES\Wall.tga'));
  Assert.AreEqual('p0map', ReadText(MakeSystem, 'Maps\TEST.MAP'));
  Assert.AreEqual('loose', ReadText(MakeSystem, 'LOOSE.TXT'));
end;

procedure TTestGameFileSystem.DovrebbeAccettareLaBarraIniziale;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.AreEqual('p0readme', ReadText(LSystem, '/readme.txt'));
  Assert.AreEqual('p0readme', ReadText(LSystem, '\readme.txt'));
  Assert.AreEqual('<missing>', ReadText(LSystem, '//readme.txt'));
end;

procedure TTestGameFileSystem.DovrebbeRifiutarePercorsiNonValidi;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.IsNull(LSystem.OpenFileRead('../base/loose.txt'));
  Assert.IsNull(LSystem.OpenFileRead('def/../loose.txt'));
  Assert.IsNull(LSystem.OpenFileRead('c::loose.txt'));
  Assert.IsNull(LSystem.OpenFileRead(''));
  Assert.IsNull(LSystem.OpenFileRead('/'));
  Assert.IsNull(LSystem.OpenFileRead('nothing.txt'));
  // a folder is not a file
  Assert.IsNull(LSystem.OpenFileRead('def'));
end;

procedure TTestGameFileSystem.DovrebbeDareIlTimestampSoloAiFileDelleCartelle;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.AreEqual(Int64(1234), LSystem.OpenFileRead('loose.txt').Timestamp);
  Assert.AreEqual(Int64(0), LSystem.OpenFileRead('readme.txt').Timestamp);
end;

procedure TTestGameFileSystem.DovrebbeDareNomeEPercorsoCompletoDelFile;
var
  LSystem: IGameFileSystem;
  LFile: IGameFile;
begin
  LSystem := MakeSystem;
  LFile := LSystem.OpenFileRead('/Loose.TXT');
  Assert.AreEqual('Loose.TXT', LFile.Name);
  Assert.AreEqual('C:\d3\base\Loose.TXT', LFile.FullPath);
  Assert.IsNull(LFile.Pack);
  LFile := LSystem.OpenFileRead('Readme.txt');
  Assert.AreEqual('Readme.txt', LFile.Name);
  Assert.AreEqual('C:\d3\base\pak000.pk4/Readme.txt', LFile.FullPath);
  Assert.AreEqual('C:\d3\base\pak000.pk4', LFile.Pack.FileName);
end;

procedure TTestGameFileSystem.DovrebbeLeggereIFileInMemoria;
var
  LSystem: IGameFileSystem;
  LFile: IGameFile;
begin
  LSystem := MakeSystem;
  LFile := LSystem.OpenFileRead('loose.txt');
  Assert.AreEqual(5, LFile.Length);
  Assert.AreEqual('loose', TEncoding.UTF8.GetString(LFile.ReadAll));
  // twice, from the start
  Assert.AreEqual('loose', TEncoding.UTF8.GetString(LFile.ReadAll));
  LFile := LSystem.OpenFileRead('maps/test.map');
  Assert.AreEqual(5, LFile.Length);
  Assert.AreEqual('p0map', TEncoding.UTF8.GetString(LFile.ReadAll));
end;

procedure TTestGameFileSystem.DovrebbeDareLaLunghezzaOMenoUno;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.AreEqual(5, LSystem.FileLength('loose.txt'));
  Assert.AreEqual(8, LSystem.FileLength('readme.txt'));
  Assert.AreEqual(-1, LSystem.FileLength('nothing'));
end;

procedure TTestGameFileSystem.DovrebbeRifiutareUnNomeVuotoInReadFile;
var
  LSystem: IGameFileSystem;
  LData: TBytes;
begin
  LSystem := MakeSystem;
  Assert.WillRaise(procedure begin LSystem.ReadFile('', LData); end, EGameFsException);
  Assert.WillRaise(procedure begin LSystem.FileLength(''); end, EGameFsException);
  Assert.IsFalse(LSystem.ReadFile('nothing', LData));
  Assert.AreEqual(0, Length(LData));
end;

procedure TTestGameFileSystem.DovrebbeCercareSoloNeiPakOSoloNelleCartelle;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.IsNull(LSystem.OpenFileRead('readme.txt', [TGameSearchFlag.SearchDirs]));
  Assert.IsNull(LSystem.OpenFileRead('loose.txt', [TGameSearchFlag.SearchPaks]));
  Assert.IsNull(LSystem.OpenFileRead('loose.txt', []));
  // only in the paks: the folder file is skipped, the pak with the name is the one of pak000
  Assert.AreEqual('p0a', TEncoding.UTF8.GetString(LSystem.OpenFileRead('def/a.def', [TGameSearchFlag.SearchPaks]).ReadAll));
end;

procedure TTestGameFileSystem.DovrebbeMarcareIPakLettiComeReferenziati;
var
  LSystem: IGameFileSystem;
  LFile: IGameFile;
begin
  LSystem := MakeSystem;
  LFile := LSystem.OpenFileRead('readme.txt');
  Assert.IsTrue(LFile.Pack.Referenced);
end;

procedure TTestGameFileSystem.DovrebbeNonMarcareConNoReference;
var
  LSystem: IGameFileSystem;
  LFile: IGameFile;
begin
  LSystem := MakeSystem;
  LFile := LSystem.OpenFileRead('readme.txt', [TGameSearchFlag.SearchDirs, TGameSearchFlag.SearchPaks, TGameSearchFlag.NoReference]);
  Assert.IsFalse(LFile.Pack.Referenced);
end;

procedure TTestGameFileSystem.DovrebbeLimitareLeCartelleAlGameDirMaNonIPak;
var
  LSystem: IGameFileSystem;
begin
  FSettings.Game := 'mod';
  LSystem := MakeSystem;
  // the folder base is skipped, mod has no loose.txt
  Assert.IsNull(LSystem.OpenFileRead('loose.txt', GAMEFS_DEFAULT_FLAGS, 'mod'));
  Assert.IsNotNull(LSystem.OpenFileRead('loose.txt', GAMEFS_DEFAULT_FLAGS, 'base'));
  // the paks are not limited (as in the original): the pak of mod is found asking for base
  Assert.AreEqual('modwall', TEncoding.UTF8.GetString(LSystem.OpenFileRead('textures/wall.tga', GAMEFS_DEFAULT_FLAGS, 'base').ReadAll));
  // the game folder is compared with the case
  Assert.IsNull(LSystem.OpenFileRead('loose.txt', GAMEFS_DEFAULT_FLAGS, 'BASE'));
end;

procedure TTestGameFileSystem.DovrebbeDireSeUnFileEInUnPak;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.IsTrue(LSystem.FileIsInPak('readme.txt'));
  Assert.IsTrue(LSystem.FileIsInPak('/Textures\WALL.tga'));
  // there is a file in the folder, and a pak has it too
  Assert.IsTrue(LSystem.FileIsInPak('def/a.def'));
  Assert.IsFalse(LSystem.FileIsInPak('loose.txt'));
  Assert.IsFalse(LSystem.FileIsInPak('../readme.txt'));
  Assert.IsFalse(LSystem.FileIsInPak('c::readme.txt'));
  Assert.IsFalse(LSystem.FileIsInPak('nothing'));
end;

procedure TTestGameFileSystem.DovrebbeTenereGliAddonFuoriDallaLista;
var
  LSystem: IGameFileSystem;
  LPath: TGameSearchPath;
begin
  FDisk.AddFile('C:\d3\base\pak002.pk4', TMemoryZip.Make(['addon.conf', 'addon/only.txt'], ['', 'addon text']));
  LSystem := MakeSystem;
  for LPath in LSystem.SearchPaths do
    Assert.IsFalse(LPath.PackFileName.EndsWith('pak002.pk4'));
  Assert.AreEqual('C:\d3\base\pak002.pk4', Join(LSystem.AddonPackFileNames));
  Assert.IsNull(LSystem.OpenFileRead('addon/only.txt'));
  Assert.IsFalse(LSystem.FileIsInPak('addon/only.txt'));
  // the others are as before
  Assert.AreEqual(2, Length(LSystem.PackChecksums));
end;

procedure TTestGameFileSystem.DovrebbeCercareNegliAddonSeRichiesto;
var
  LSystem: IGameFileSystem;
begin
  FDisk.AddFile('C:\d3\base\pak002.pk4', TMemoryZip.Make(['addon.conf', 'addon/only.txt'], ['', 'addon text']));
  LSystem := MakeSystem;
  Assert.AreEqual('addon text', TEncoding.UTF8.GetString(
    LSystem.OpenFileRead('addon/only.txt', GAMEFS_DEFAULT_FLAGS + [TGameSearchFlag.SearchAddons]).ReadAll));
  // the files of the search list come first
  Assert.AreEqual('p0readme', TEncoding.UTF8.GetString(
    LSystem.OpenFileRead('readme.txt', GAMEFS_DEFAULT_FLAGS + [TGameSearchFlag.SearchAddons]).ReadAll));
end;

procedure TTestGameFileSystem.DovrebbeTenereGliAddonConSearchAddons;
var
  LSystem: IGameFileSystem;
  LPaths: TArray<TGameSearchPath>;
begin
  FDisk.AddFile('C:\d3\base\pak002.pk4', TMemoryZip.Make(['addon.conf', 'addon/only.txt'], ['', 'addon text']));
  FSettings.SearchAddons := True;
  LSystem := MakeSystem;
  LPaths := LSystem.SearchPaths;
  Assert.AreEqual(4, Length(LPaths));
  // the last pak is the first after the folder
  Assert.AreEqual('C:\d3\base\pak002.pk4', LPaths[1].PackFileName);
  Assert.IsTrue(LPaths[1].IsAddon);
  Assert.AreEqual(0, Length(LSystem.AddonPackFileNames));
  Assert.AreEqual('addon text', TEncoding.UTF8.GetString(LSystem.OpenFileRead('addon/only.txt').ReadAll));
end;

procedure TTestGameFileSystem.DovrebbeDareIChecksumDeiPakInOrdine;
var
  LSystem: IGameFileSystem;
  LPaths: TArray<TGameSearchPath>;
  LChecksums: TArray<Cardinal>;
begin
  FSettings.Game := 'mod';
  LSystem := MakeSystem;
  LPaths := LSystem.SearchPaths;
  LChecksums := LSystem.PackChecksums;
  Assert.AreEqual(3, Length(LChecksums));
  Assert.AreEqual(LPaths[1].Checksum, LChecksums[0]);
  Assert.AreEqual(LPaths[3].Checksum, LChecksums[1]);
  Assert.AreEqual(LPaths[4].Checksum, LChecksums[2]);
  Assert.AreNotEqual(LChecksums[1], LChecksums[2]);
end;

procedure TTestGameFileSystem.DovrebbeElencareUnaVoltaOgniNomeDaCartelleEPak;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  // a.def: in the folder and in pak000; b.def in pak001; the folder is read first, then pak001, then pak000
  Assert.AreEqual('a.def,b.def', Join(LSystem.ListFiles('def', 'def')));
  // the same name in another case is the same name
  Assert.AreEqual('wall.tga', Join(LSystem.ListFiles('textures', 'tga')));
end;

procedure TTestGameFileSystem.DovrebbeElencareConPiuEstensioni;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.AreEqual('x.wav,z.wav', Join(LSystem.ListFiles('sound', 'wav|txt', True)));
  Assert.AreEqual('', Join(LSystem.ListFiles('sound', 'tga')));
  // an empty extension is every file (and, in a pak, every folder entry too)
  Assert.AreEqual('z.wav,x.wav,sub', Join(LSystem.ListFiles('sound', '')));
end;

procedure TTestGameFileSystem.DovrebbeElencareLeCartelleDeiPak;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.AreEqual('sub', Join(LSystem.ListFiles('sound', '/')));
  Assert.AreEqual('', Join(LSystem.ListFiles('def', '/')));
end;

procedure TTestGameFileSystem.DovrebbeElencareConIlPercorsoRelativoCompleto;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.AreEqual('sound/sub', Join(LSystem.ListFiles('sound', '/', False, True)));
  Assert.AreEqual('sound/z.wav,sound/x.wav', Join(LSystem.ListFiles('sound', 'wav', False, True)));
end;

procedure TTestGameFileSystem.DovrebbeElencareLAlberoConLeCartellePrima;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  // the subfolders first, then the files of the folder
  Assert.AreEqual('sound/sub/y.wav,sound/z.wav,sound/x.wav', Join(LSystem.ListFilesTree('sound', 'wav')));
  Assert.AreEqual('sound/sub/y.wav,sound/x.wav,sound/z.wav', Join(LSystem.ListFilesTree('sound', 'wav', True)));
  Assert.AreEqual('', Join(LSystem.ListFilesTree('nothing', 'wav')));
end;

procedure TTestGameFileSystem.DovrebbeOrdinareLElenco;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.AreEqual('x.wav,z.wav', Join(LSystem.ListFiles('sound', 'wav', True)));
  Assert.AreEqual('x.wav,z.wav', Join(LSystem.ListFiles('SOUND', 'WAV', True)));
end;

procedure TTestGameFileSystem.DovrebbeElencareConIlNomeDelPakInMinuscolo;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  // 'maps/Test.map' is stored lower case in the pak
  Assert.AreEqual('test.map', Join(LSystem.ListFiles('maps', 'map')));
  Assert.AreEqual('test.map', Join(LSystem.ListFiles('maps', 'MAP')));
end;

procedure TTestGameFileSystem.DovrebbeElencareConGameDir;
var
  LSystem: IGameFileSystem;
begin
  FSettings.Game := 'mod';
  LSystem := MakeSystem;
  // the folders are limited to the game folder, the paks are all searched
  Assert.AreEqual('b.def,a.def', Join(LSystem.ListFiles('def', 'def', False, False, 'mod')));
  Assert.AreEqual('a.def,b.def', Join(LSystem.ListFiles('def', 'def', False, False, 'base')));
  Assert.AreEqual('wall.tga', Join(LSystem.ListFiles('textures', 'tga', False, False, 'mod')));
end;

procedure TTestGameFileSystem.DovrebbeRiavviareDopoLoShutdown;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  Assert.IsTrue(LSystem.IsInitialized);
  LSystem.Shutdown;
  Assert.IsFalse(LSystem.IsInitialized);
  Assert.WillRaise(procedure begin LSystem.OpenFileRead('loose.txt'); end, EGameFsException);
  LSystem.Restart;
  Assert.IsTrue(LSystem.IsInitialized);
  Assert.AreEqual(2, Length(LSystem.PackChecksums));
  // Startup twice does not repeat the folders
  LSystem.Startup;
  Assert.AreEqual(3, Length(LSystem.SearchPaths));
end;

procedure TTestGameFileSystem.DovrebbeLeggereUnaCartellaVuotaComeTutteLeVoci;
var
  LSystem: IGameFileSystem;
begin
  LSystem := MakeSystem;
  // the root: files of the folder, and in the paks the ones with no folder (see the notes of the unit on the
  // empty path, which the original reads outside the string)
  Assert.AreEqual('loose.txt,readme.txt', Join(LSystem.ListFiles('', 'txt', True)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGameFsPaths);
  TDUnitX.RegisterTestFixture(TTestGamePack);
  TDUnitX.RegisterTestFixture(TTestGameFileSystem);

end.
