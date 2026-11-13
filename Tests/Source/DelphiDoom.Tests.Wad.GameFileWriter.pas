{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - file system of id Tech 4, writing   }
{  (OpenFileWrite, OpenFileAppend, WriteFile, RemoveFile)                      }
{                                                                              }
{  The expected values come from reading framework\FileSystem.cpp of Doom 3;  }
{  the disk is in memory, and the disk of the machine is used in a folder      }
{  that each test makes and removes.                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.GameFileWriter;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Wad.Fs.Write.Intf, DelphiDoom.Tests.Wad.MemoryWriteDisk;

type
  [TestFixture]
  [Category('wad')]
  TTestGameFileWriter = class(TObject)
  strict private
    FDisk: TMemoryWriteDisk;
    FDiskRead: IGameDisk;
    FDiskWrite: IGameDiskWriter;
    FSettings: TGameFsSettings;
    FSystem: IGameFileSystem;
    FWriter: IGameFileWriter;
    procedure Start;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereNelSavePathSottoLaCartellaDelGioco;
    [Test]
    procedure DovrebbeCreareLeCartelleIntermedie;
    [Test]
    procedure DovrebbeScrivereNelDevPathSeRichiesto;
    [Test]
    procedure DovrebbeRicadereSulSavePathSeIlPercorsoNonEImpostato;
    [Test]
    procedure DovrebbeUsareLaCartellaBaseSenzaGioco;
    [Test]
    procedure DovrebbeSvuotareUnFileCheEsiste;
    [Test]
    procedure DovrebbeAggiungereInCodaAdUnFileCheEsiste;
    [Test]
    procedure DovrebbeCreareUnFileNuovoInAppend;
    [Test]
    procedure DovrebbeContareIByteScritti;
    [Test]
    procedure DovrebbeScrivereUnTestoComeByte;
    [Test]
    procedure DovrebbeDareMenoUnoSeIlFileNonSiApre;
    [Test]
    procedure DovrebbeDareNilSeIlFileNonSiApre;
    [Test]
    procedure DovrebbeRifiutareIPercorsiCheRisalgono;
    [Test]
    procedure DovrebbeRifiutareLeChiamateSenzaStartup;
    [Test]
    procedure DovrebbeRimuovereIlFileDaDevESave;
    [Test]
    procedure DovrebbeRimuovereSoloDalSaveSenzaDevPath;
    [Test]
    procedure DovrebbeNonRimuovereUnPercorsoCheRisale;
    [Test]
    procedure DovrebbeFarLeggereAlFileSystemCioCheHaScritto;
    [Test]
    procedure DovrebbeDareIlPercorsoDelSistema;
    [Test]
    procedure DovrebbeFlushareDopoOgniScritturaInSync;
    [Test]
    procedure DovrebbeRifiutareDipendenzeNil;
  end;

  [TestFixture]
  [Category('wad')]
  TTestGameDiskWriter = class(TObject)
  strict private
    FFolder: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCreareUnaCartellaEDirePerUnaCheEsiste;
    [Test]
    procedure DovrebbeCreareAncheLeCartelleMadre;
    [Test]
    procedure DovrebbeDareFalsoSeUnaCartellaMadreEUnFile;
    [Test]
    procedure DovrebbeDareNilSeIlFileEBloccato;
    [Test]
    procedure DovrebbeScrivereEAggiungereInCoda;
    [Test]
    procedure DovrebbeSvuotareUnFileSenzaAppend;
    [Test]
    procedure DovrebbeRimuovereUnFile;
    [Test]
    procedure DovrebbeDareFalsoRimuovendoUnFileCheManca;
    [Test]
    procedure DovrebbeScrivereTramiteIlFileSystemSulDiscoVero;
  end;

implementation

uses
  System.IOUtils, Winapi.Windows, DelphiDoom.Wad.Fs.Factory, DelphiDoom.Wad.Fs.DiskWriter, DelphiDoom.Wad.Fs.WriteFile;

const
  SAVE_DIR = 'C:\save';
  DEV_DIR = 'C:\dev';

{ TTestGameFileWriter }

procedure TTestGameFileWriter.Setup;
begin
  FDisk := TMemoryWriteDisk.Create;
  FDiskRead := FDisk;
  FDiskWrite := FDisk;
  FSettings := Default(TGameFsSettings);
  FSettings.BasePath := 'C:\d3';
  FSettings.SavePath := SAVE_DIR;
  FSettings.DevPath := DEV_DIR;
  FSettings.Game := 'mod';
end;

procedure TTestGameFileWriter.TearDown;
begin
  FWriter := nil;
  FSystem := nil;
  FDiskRead := nil;
  FDiskWrite := nil;
  FDisk := nil;
end;

procedure TTestGameFileWriter.Start;
begin
  FSystem := TGameFileSystemFactory.CreateWithDisk(FDiskRead, FSettings);
  FSystem.Startup;
  FWriter := TGameFileSystemFactory.CreateWriterWithDisk(FDiskWrite, FSystem, FSettings);
end;

procedure TTestGameFileWriter.DovrebbeScrivereNelSavePathSottoLaCartellaDelGioco;
begin
  Start;
  Assert.AreEqual(5, FWriter.WriteFile('a.txt', TEncoding.UTF8.GetBytes('hello')));
  Assert.AreEqual('hello', FDisk.ReadText('C:\save\mod\a.txt'));
end;

procedure TTestGameFileWriter.DovrebbeCreareLeCartelleIntermedie;
begin
  Start;
  FWriter.WriteFile('maps/sub/x.txt', TEncoding.UTF8.GetBytes('x'));
  Assert.IsTrue(FDisk.Directories.IndexOf('C:\save') >= 0, 'save');
  Assert.IsTrue(FDisk.Directories.IndexOf('C:\save\mod') >= 0, 'game folder');
  Assert.IsTrue(FDisk.Directories.IndexOf('C:\save\mod\maps') >= 0, 'maps');
  Assert.IsTrue(FDisk.Directories.IndexOf('C:\save\mod\maps\sub') >= 0, 'sub');
  Assert.AreEqual('x', FDisk.ReadText('C:\save\mod\maps\sub\x.txt'));
end;

procedure TTestGameFileWriter.DovrebbeScrivereNelDevPathSeRichiesto;
begin
  Start;
  FWriter.WriteFile('d.txt', TEncoding.UTF8.GetBytes('dev'), TGameWriteBase.DevPath);
  Assert.AreEqual('dev', FDisk.ReadText('C:\dev\mod\d.txt'));
  Assert.IsFalse(FDisk.Exists('C:\save\mod\d.txt'));
end;

procedure TTestGameFileWriter.DovrebbeRicadereSulSavePathSeIlPercorsoNonEImpostato;
begin
  FSettings.DevPath := '';
  Start;
  FWriter.WriteFile('d.txt', TEncoding.UTF8.GetBytes('dev'), TGameWriteBase.DevPath);
  Assert.AreEqual('dev', FDisk.ReadText('C:\save\mod\d.txt'));
end;

procedure TTestGameFileWriter.DovrebbeUsareLaCartellaBaseSenzaGioco;
begin
  FSettings.Game := '';
  Start;
  FWriter.WriteFile('b.txt', TEncoding.UTF8.GetBytes('b'));
  Assert.AreEqual('b', FDisk.ReadText('C:\save\base\b.txt'));
end;

procedure TTestGameFileWriter.DovrebbeSvuotareUnFileCheEsiste;
begin
  FDisk.AddText('C:\save\mod\a.txt', 'old content that is long');
  Start;
  FWriter.WriteFile('a.txt', TEncoding.UTF8.GetBytes('new'));
  Assert.AreEqual('new', FDisk.ReadText('C:\save\mod\a.txt'));
end;

procedure TTestGameFileWriter.DovrebbeAggiungereInCodaAdUnFileCheEsiste;
var
  LFile: IGameWriteFile;
begin
  FDisk.AddText('C:\save\mod\log.txt', 'one;');
  Start;
  LFile := FWriter.OpenFileAppend('log.txt');
  Assert.IsTrue(LFile.IsAppend);
  Assert.AreEqual<Int64>(4, LFile.Length);
  LFile.WriteText('two;');
  Assert.AreEqual<Int64>(8, LFile.Length);
  LFile := nil;
  Assert.AreEqual('one;two;', FDisk.ReadText('C:\save\mod\log.txt'));
end;

procedure TTestGameFileWriter.DovrebbeCreareUnFileNuovoInAppend;
var
  LFile: IGameWriteFile;
begin
  Start;
  LFile := FWriter.OpenFileAppend('sub/new.txt');
  Assert.AreEqual<Int64>(0, LFile.Length);
  LFile.WriteText('abc');
  LFile := nil;
  Assert.AreEqual('abc', FDisk.ReadText('C:\save\mod\sub\new.txt'));
end;

procedure TTestGameFileWriter.DovrebbeContareIByteScritti;
var
  LFile: IGameWriteFile;
begin
  Start;
  LFile := FWriter.OpenFileWrite('a.bin');
  Assert.IsFalse(LFile.IsAppend);
  Assert.AreEqual('a.bin', LFile.Name);
  Assert.AreEqual('C:\save\mod\a.bin', LFile.FullPath);
  Assert.AreEqual(3, LFile.Write([1, 2, 3]));
  Assert.AreEqual(0, LFile.Write(nil));
  Assert.AreEqual<Int64>(3, LFile.Length);
end;

procedure TTestGameFileWriter.DovrebbeScrivereUnTestoComeByte;
var
  LFile: IGameWriteFile;
  LText: AnsiString;
  LStream: TStream;
begin
  Start;
  LText := AnsiString('a') + AnsiChar(#200) + AnsiString('b');
  LFile := FWriter.OpenFileWrite('t.bin');
  Assert.AreEqual(3, LFile.WriteText(LText));
  Assert.AreEqual(0, LFile.WriteText(''));
  LFile := nil;
  LStream := FDisk.OpenRead('C:\save\mod\t.bin');
  try
    Assert.AreEqual<Int64>(3, LStream.Size);
  finally
    LStream.Free;
  end;
end;

procedure TTestGameFileWriter.DovrebbeDareMenoUnoSeIlFileNonSiApre;
begin
  Start;
  FDisk.Refuse := True;
  Assert.AreEqual(-1, FWriter.WriteFile('a.txt', TEncoding.UTF8.GetBytes('x')));
end;

procedure TTestGameFileWriter.DovrebbeDareNilSeIlFileNonSiApre;
begin
  Start;
  FDisk.Refuse := True;
  Assert.IsNull(FWriter.OpenFileWrite('a.txt'));
  Assert.IsNull(FWriter.OpenFileAppend('a.txt'));
end;

procedure TTestGameFileWriter.DovrebbeRifiutareIPercorsiCheRisalgono;
begin
  Start;
  Assert.IsNull(FWriter.OpenFileWrite('../evil.txt'));
  Assert.IsNull(FWriter.OpenFileAppend('a/../../evil.txt'));
  Assert.IsNull(FWriter.OpenFileWrite('c::evil.txt'));
  Assert.AreEqual(-1, FWriter.WriteFile('../evil.txt', TEncoding.UTF8.GetBytes('x')));
  Assert.AreEqual(0, FDisk.Directories.Count);
end;

procedure TTestGameFileWriter.DovrebbeRifiutareLeChiamateSenzaStartup;
begin
  FSystem := TGameFileSystemFactory.CreateWithDisk(FDiskRead, FSettings);
  FWriter := TGameFileSystemFactory.CreateWriterWithDisk(FDiskWrite, FSystem, FSettings);
  Assert.WillRaise(procedure begin FWriter.OpenFileWrite('a'); end, EGameFsException);
  Assert.WillRaise(procedure begin FWriter.OpenFileAppend('a'); end, EGameFsException);
  Assert.WillRaise(procedure begin FWriter.WriteFile('a', nil); end, EGameFsException);
  Assert.WillRaise(procedure begin FWriter.RemoveFile('a'); end, EGameFsException);
  Assert.WillRaise(procedure begin FWriter.RelativePathToOSPath('a'); end, EGameFsException);
end;

procedure TTestGameFileWriter.DovrebbeRimuovereIlFileDaDevESave;
begin
  FDisk.AddText('C:\dev\mod\a.txt', 'd');
  FDisk.AddText('C:\save\mod\a.txt', 's');
  Start;
  FWriter.RemoveFile('a.txt');
  Assert.IsFalse(FDisk.Exists('C:\dev\mod\a.txt'));
  Assert.IsFalse(FDisk.Exists('C:\save\mod\a.txt'));
  Assert.AreEqual(2, FDisk.Removed.Count);
end;

procedure TTestGameFileWriter.DovrebbeRimuovereSoloDalSaveSenzaDevPath;
begin
  FSettings.DevPath := '';
  FDisk.AddText('C:\save\mod\a.txt', 's');
  Start;
  FWriter.RemoveFile('a.txt');
  Assert.AreEqual(1, FDisk.Removed.Count);
  Assert.IsFalse(FDisk.Exists('C:\save\mod\a.txt'));
  // a file that is not there is not an error
  FWriter.RemoveFile('missing.txt');
  Assert.AreEqual(2, FDisk.Removed.Count);
end;

procedure TTestGameFileWriter.DovrebbeNonRimuovereUnPercorsoCheRisale;
begin
  Start;
  FWriter.RemoveFile('../x.txt');
  Assert.AreEqual(0, FDisk.Removed.Count);
end;

procedure TTestGameFileWriter.DovrebbeFarLeggereAlFileSystemCioCheHaScritto;
var
  LData: TBytes;
begin
  Start;
  FWriter.WriteFile('read/back.txt', TEncoding.UTF8.GetBytes('back'));
  Assert.IsTrue(FSystem.ReadFile('read/back.txt', LData));
  Assert.AreEqual('back', TEncoding.UTF8.GetString(LData));
end;

procedure TTestGameFileWriter.DovrebbeDareIlPercorsoDelSistema;
begin
  Start;
  Assert.AreEqual('C:\save\mod\a\b.txt', FWriter.RelativePathToOSPath('a/b.txt'));
  Assert.AreEqual('C:\dev\mod\a\b.txt', FWriter.RelativePathToOSPath('a/b.txt', TGameWriteBase.DevPath));
  Assert.AreEqual('C:\d3\mod\a\b.txt', FWriter.RelativePathToOSPath('a/b.txt', TGameWriteBase.BasePath));
  // the cd path is not set: the save path
  Assert.AreEqual('C:\save\mod\a\b.txt', FWriter.RelativePathToOSPath('a/b.txt', TGameWriteBase.CdPath));
end;

procedure TTestGameFileWriter.DovrebbeFlushareDopoOgniScritturaInSync;
var
  LFile: IGameWriteFile;
begin
  Start;
  LFile := FWriter.OpenFileAppend('sync.txt', True);
  LFile.WriteText('a');
  LFile.Flush;
  Assert.AreEqual<Int64>(1, LFile.Length);
end;

procedure TTestGameFileWriter.DovrebbeRifiutareDipendenzeNil;
begin
  Start;
  Assert.WillRaise(procedure begin TGameFileSystemFactory.CreateWriterWithDisk(nil, FSystem, FSettings); end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TGameFileSystemFactory.CreateWriterWithDisk(FDiskWrite, nil, FSettings); end,
    EGameFsException);
  Assert.WillRaise(procedure begin TGameWriteFile.Create('a', 'a', nil, False, False); end, EGameFsException);
end;

{ TTestGameDiskWriter }

procedure TTestGameDiskWriter.Setup;
begin
  FFolder := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + 'dd_fs_write_' + IntToStr(GetCurrentProcessId);
  ForceDirectories(FFolder);
end;

procedure TTestGameDiskWriter.TearDown;
begin
  if TDirectory.Exists(FFolder) then
    TDirectory.Delete(FFolder, True);
end;

procedure TTestGameDiskWriter.DovrebbeCreareUnaCartellaEDirePerUnaCheEsiste;
var
  LDisk: IGameDiskWriter;
begin
  LDisk := TGameDiskWriter.Create;
  Assert.IsTrue(LDisk.CreateDirectory(FFolder + '\new'));
  Assert.IsTrue(DirectoryExists(FFolder + '\new'));
  Assert.IsTrue(LDisk.CreateDirectory(FFolder + '\new'));
  RemoveDir(FFolder + '\new');
end;

procedure TTestGameDiskWriter.DovrebbeCreareAncheLeCartelleMadre;
var
  LDisk: IGameDiskWriter;
begin
  LDisk := TGameDiskWriter.Create;
  // System.IOUtils creates the parents too: what the original does by hand, level by level, comes to the same
  Assert.IsTrue(LDisk.CreateDirectory(FFolder + '\a\b'));
  Assert.IsTrue(DirectoryExists(FFolder + '\a\b'));
  RemoveDir(FFolder + '\a\b');
  RemoveDir(FFolder + '\a');
  // an invalid name is False
  Assert.IsFalse(LDisk.CreateDirectory(FFolder + '\bad<>name'));
end;

procedure TTestGameDiskWriter.DovrebbeDareFalsoSeUnaCartellaMadreEUnFile;
var
  LDisk: IGameDiskWriter;
  LStream: TStream;
begin
  LDisk := TGameDiskWriter.Create;
  LStream := LDisk.OpenWrite(FFolder + '\afile', False);
  LStream.Free;
  Assert.IsFalse(LDisk.CreateDirectory(FFolder + '\afile\sub'));
end;

procedure TTestGameDiskWriter.DovrebbeDareNilSeIlFileEBloccato;
var
  LDisk: IGameDiskWriter;
  LLock, LStream: TStream;
begin
  LDisk := TGameDiskWriter.Create;
  LStream := LDisk.OpenWrite(FFolder + '\locked.bin', False);
  LStream.Free;
  LLock := TFileStream.Create(FFolder + '\locked.bin', fmOpenReadWrite or fmShareExclusive);
  try
    // an existing file that cannot be opened for appending
    Assert.IsNull(LDisk.OpenWrite(FFolder + '\locked.bin', True));
  finally
    LLock.Free;
  end;
end;

procedure TTestGameDiskWriter.DovrebbeScrivereEAggiungereInCoda;
var
  LDisk: IGameDiskWriter;
  LStream: TStream;
  LByte: Byte;
begin
  LDisk := TGameDiskWriter.Create;
  LStream := LDisk.OpenWrite(FFolder + '\f.bin', False);
  try
    LByte := 1;
    LStream.WriteBuffer(LByte, 1);
  finally
    LStream.Free;
  end;
  LStream := LDisk.OpenWrite(FFolder + '\f.bin', True);
  try
    LByte := 2;
    LStream.WriteBuffer(LByte, 1);
  finally
    LStream.Free;
  end;
  LStream := TFileStream.Create(FFolder + '\f.bin', fmOpenRead);
  try
    Assert.AreEqual<Int64>(2, LStream.Size);
  finally
    LStream.Free;
  end;
end;

procedure TTestGameDiskWriter.DovrebbeSvuotareUnFileSenzaAppend;
var
  LDisk: IGameDiskWriter;
  LStream: TStream;
  LByte: Byte;
begin
  LDisk := TGameDiskWriter.Create;
  LStream := LDisk.OpenWrite(FFolder + '\f.bin', False);
  LByte := 7;
  LStream.WriteBuffer(LByte, 1);
  LStream.WriteBuffer(LByte, 1);
  LStream.Free;
  LStream := LDisk.OpenWrite(FFolder + '\f.bin', False);
  LStream.Free;
  LStream := TFileStream.Create(FFolder + '\f.bin', fmOpenRead);
  try
    Assert.AreEqual<Int64>(0, LStream.Size);
  finally
    LStream.Free;
  end;
  // append to a file that is not there creates it
  LStream := LDisk.OpenWrite(FFolder + '\g.bin', True);
  Assert.IsNotNull(LStream);
  LStream.Free;
  // a file in a folder that is not there cannot be opened
  Assert.IsNull(LDisk.OpenWrite(FFolder + '\missing\h.bin', False));
end;

procedure TTestGameDiskWriter.DovrebbeRimuovereUnFile;
var
  LDisk: IGameDiskWriter;
  LStream: TStream;
begin
  LDisk := TGameDiskWriter.Create;
  LStream := LDisk.OpenWrite(FFolder + '\f.bin', False);
  LStream.Free;
  Assert.IsTrue(LDisk.RemoveFile(FFolder + '\f.bin'));
  Assert.IsFalse(FileExists(FFolder + '\f.bin'));
end;

procedure TTestGameDiskWriter.DovrebbeDareFalsoRimuovendoUnFileCheManca;
var
  LDisk: IGameDiskWriter;
  LStream: TStream;
begin
  LDisk := TGameDiskWriter.Create;
  Assert.IsFalse(LDisk.RemoveFile(FFolder + '\missing.bin'));
  // a file that is open cannot be removed
  LStream := LDisk.OpenWrite(FFolder + '\busy.bin', False);
  try
    Assert.IsFalse(LDisk.RemoveFile(FFolder + '\busy.bin'));
  finally
    LStream.Free;
  end;
end;

procedure TTestGameDiskWriter.DovrebbeScrivereTramiteIlFileSystemSulDiscoVero;
var
  LSettings: TGameFsSettings;
  LSystem: IGameFileSystem;
  LWriter: IGameFileWriter;
  LData: TBytes;
begin
  LSettings := Default(TGameFsSettings);
  LSettings.SavePath := FFolder;
  LSettings.Game := 'mod';
  LSystem := TGameFileSystemFactory.CreateOnDisk(LSettings);
  LSystem.Startup;
  LWriter := TGameFileSystemFactory.CreateWriterOnDisk(LSystem, LSettings);
  Assert.AreEqual(3, LWriter.WriteFile('sub/x.txt', TEncoding.UTF8.GetBytes('abc')));
  Assert.IsTrue(FileExists(FFolder + '\mod\sub\x.txt'));
  LSystem.Restart;
  Assert.IsTrue(LSystem.ReadFile('sub/x.txt', LData));
  Assert.AreEqual('abc', TEncoding.UTF8.GetString(LData));
  LWriter.RemoveFile('sub/x.txt');
  Assert.IsFalse(FileExists(FFolder + '\mod\sub\x.txt'));
  RemoveDir(FFolder + '\mod\sub');
  RemoveDir(FFolder + '\mod');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGameFileWriter);
  TDUnitX.RegisterTestFixture(TTestGameDiskWriter);

end.
