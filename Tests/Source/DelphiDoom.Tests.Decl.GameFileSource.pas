{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - the decl files in the file   }
{  system of id Tech 4 (TDeclGameFileSource)                                   }
{                                                                              }
{  The file system and the writer are fakes written for the test; the          }
{  integration with the real file system is in                                 }
{  DelphiDoom.Tests.Decl.GameFsManager.                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.GameFileSource;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Wad.Fs.Types,
  DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Write.Intf, DelphiDoom.Decl.Source.Intf;

type
  /// <summary>A file of the fake file system</summary>
  TFakeGameFile = class(TInterfacedObject, IGameFile)
  strict private
    FName: string;
    FData: TBytes;
    FTimestamp: Int64;
  public
    constructor Create(const AName: string; const AData: TBytes; ATimestamp: Int64);
    function GetName: string;
    function GetFullPath: string;
    function GetLength: Integer;
    function GetTimestamp: Int64;
    function GetPack: IGamePack;
    function ReadAll: TBytes;
  end;

  /// <summary>An IGameFileSystem that answers what the test says and remembers how it was asked</summary>
  TFakeGameFileSystem = class(TInterfacedObject, IGameFileSystem)
  strict private
    FFiles: TDictionary<string, TBytes>;
    FTimestamps: TDictionary<string, Int64>;
    FTree: TArray<string>;
    FTreeFolder: string;
    FTreeExtension: string;
    FTreeSorted: Boolean;
    FTreeCalls: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddFile(const APath, AText: string; ATimestamp: Int64 = 0);
    procedure SetTree(const APaths: TArray<string>);
    procedure Startup;
    procedure Restart;
    procedure Shutdown;
    function IsInitialized: Boolean;
    function OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags = [TGameSearchFlag.SearchDirs, TGameSearchFlag.SearchPaks];
      const AGameDir: string = ''): IGameFile;
    function ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
    function FileLength(const ARelativePath: string): Integer;
    function FileIsInPak(const ARelativePath: string): Boolean;
    function ListFiles(const ARelativePath, AExtension: string; ASort: Boolean = False;
      AFullRelativePath: Boolean = False; const AGameDir: string = ''): TArray<string>;
    function ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean = False;
      const AGameDir: string = ''): TArray<string>;
    function SearchPaths: TArray<TGameSearchPath>;
    function PackChecksums: TArray<Cardinal>;
    function AddonPackFileNames: TArray<string>;
    property TreeFolder: string read FTreeFolder;
    property TreeExtension: string read FTreeExtension;
    property TreeSorted: Boolean read FTreeSorted;
    property TreeCalls: Integer read FTreeCalls;
  end;

  /// <summary>An IGameFileWriter that keeps what it is given</summary>
  TFakeGameFileWriter = class(TInterfacedObject, IGameFileWriter)
  strict private
    FWrittenPath: string;
    FWrittenData: TBytes;
    FWrittenBase: TGameWriteBase;
    FResult: Integer;
    FCalls: Integer;
  public
    constructor Create;
    function OpenFileWrite(const ARelativePath: string; ABase: TGameWriteBase = TGameWriteBase.SavePath): IGameWriteFile;
    function OpenFileAppend(const ARelativePath: string; ASync: Boolean = False;
      ABase: TGameWriteBase = TGameWriteBase.SavePath): IGameWriteFile;
    function WriteFile(const ARelativePath: string; const AData: TBytes;
      ABase: TGameWriteBase = TGameWriteBase.SavePath): Integer;
    procedure RemoveFile(const ARelativePath: string);
    function RelativePathToOSPath(const ARelativePath: string; ABase: TGameWriteBase = TGameWriteBase.SavePath): string;
    /// <summary>What WriteFile answers; -1 is a file that cannot be opened. Default: the number of bytes</summary>
    property Answer: Integer read FResult write FResult;
    property WrittenPath: string read FWrittenPath;
    property WrittenData: TBytes read FWrittenData;
    property WrittenBase: TGameWriteBase read FWrittenBase;
    property Calls: Integer read FCalls;
  end;

  [TestFixture]
  [Category('decl')]
  TTestDeclGameFileSource = class(TObject)
  strict private
    FSystem: TFakeGameFileSystem;
    FSystemIntf: IGameFileSystem;
    FWriter: TFakeGameFileWriter;
    FWriterIntf: IGameFileWriter;
    function Source(AWithWriter: Boolean = True): IDeclSource;
    class function Join(const AValues: TArray<AnsiString>): string; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnFileSystemNil;
    [Test]
    procedure DovrebbeElencareRelativoAllaCartella;
    [Test]
    procedure DovrebbeChiedereLAlberoOrdinatoConCartellaEdEstensione;
    [Test]
    procedure DovrebbeTogliereLaCartellaIgnorandoLeMaiuscole;
    [Test]
    procedure DovrebbeTenereIlNomeCheNonComincia;
    [Test]
    procedure DovrebbeElencareVuotoSenzaFile;
    [Test]
    procedure DovrebbeLeggereIlTestoEIlTempoDiUnFile;
    [Test]
    procedure DovrebbeLeggereIByteNonAsciiSenzaCambiarli;
    [Test]
    procedure DovrebbeLeggereUnFileVuoto;
    [Test]
    procedure DovrebbeDareFalsoPerUnFileCheManca;
    [Test]
    procedure DovrebbeDareLunghezzaETempoSenzaLeggere;
    [Test]
    procedure DovrebbeDareMenoUnoPerUnFileCheManca;
    [Test]
    procedure DovrebbeScrivereNelDevPathPerDefault;
    [Test]
    procedure DovrebbeScrivereNelPercorsoDato;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileNonSiApre;
    [Test]
    procedure DovrebbeDareFalsoSenzaUnScrittore;
    [Test]
    procedure DovrebbeScrivereUnTestoVuoto;
  end;

implementation

uses
  DelphiDoom.Decl.Source.GameFs;

{ TFakeGameFile }

constructor TFakeGameFile.Create(const AName: string; const AData: TBytes; ATimestamp: Int64);
begin
  inherited Create;
  FName := AName;
  FData := AData;
  FTimestamp := ATimestamp;
end;

function TFakeGameFile.GetName: string;
begin
  Result := FName;
end;

function TFakeGameFile.GetFullPath: string;
begin
  Result := 'fake/' + FName;
end;

function TFakeGameFile.GetLength: Integer;
begin
  Result := Length(FData);
end;

function TFakeGameFile.GetTimestamp: Int64;
begin
  Result := FTimestamp;
end;

function TFakeGameFile.GetPack: IGamePack;
begin
  Result := nil;
end;

function TFakeGameFile.ReadAll: TBytes;
begin
  Result := FData;
end;

{ TFakeGameFileSystem }

constructor TFakeGameFileSystem.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
  FTimestamps := TDictionary<string, Int64>.Create;
end;

destructor TFakeGameFileSystem.Destroy;
begin
  FTimestamps.Free;
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeGameFileSystem.AddFile(const APath, AText: string; ATimestamp: Int64);
begin
  FFiles.AddOrSetValue(LowerCase(APath), TEncoding.GetEncoding(28591).GetBytes(AText));
  FTimestamps.AddOrSetValue(LowerCase(APath), ATimestamp);
end;

procedure TFakeGameFileSystem.SetTree(const APaths: TArray<string>);
begin
  FTree := APaths;
end;

procedure TFakeGameFileSystem.Startup;
begin
end;

procedure TFakeGameFileSystem.Restart;
begin
end;

procedure TFakeGameFileSystem.Shutdown;
begin
end;

function TFakeGameFileSystem.IsInitialized: Boolean;
begin
  Result := True;
end;

function TFakeGameFileSystem.OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags;
  const AGameDir: string): IGameFile;
var
  LData: TBytes;
  LTimestamp: Int64;
begin
  if not FFiles.TryGetValue(LowerCase(ARelativePath), LData) then
    Exit(nil);
  FTimestamps.TryGetValue(LowerCase(ARelativePath), LTimestamp);
  Result := TFakeGameFile.Create(ARelativePath, LData, LTimestamp);
end;

function TFakeGameFileSystem.ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
begin
  Result := FFiles.TryGetValue(LowerCase(ARelativePath), AData);
end;

function TFakeGameFileSystem.FileLength(const ARelativePath: string): Integer;
var
  LData: TBytes;
begin
  if FFiles.TryGetValue(LowerCase(ARelativePath), LData) then
    Result := Length(LData)
  else
    Result := -1;
end;

function TFakeGameFileSystem.FileIsInPak(const ARelativePath: string): Boolean;
begin
  Result := False;
end;

function TFakeGameFileSystem.ListFiles(const ARelativePath, AExtension: string; ASort, AFullRelativePath: Boolean;
  const AGameDir: string): TArray<string>;
begin
  Result := nil;
end;

function TFakeGameFileSystem.ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean;
  const AGameDir: string): TArray<string>;
begin
  Inc(FTreeCalls);
  FTreeFolder := ARelativePath;
  FTreeExtension := AExtension;
  FTreeSorted := ASort;
  Result := FTree;
end;

function TFakeGameFileSystem.SearchPaths: TArray<TGameSearchPath>;
begin
  Result := nil;
end;

function TFakeGameFileSystem.PackChecksums: TArray<Cardinal>;
begin
  Result := nil;
end;

function TFakeGameFileSystem.AddonPackFileNames: TArray<string>;
begin
  Result := nil;
end;

{ TFakeGameFileWriter }

constructor TFakeGameFileWriter.Create;
begin
  inherited Create;
  FResult := Low(Integer);
end;

function TFakeGameFileWriter.OpenFileWrite(const ARelativePath: string; ABase: TGameWriteBase): IGameWriteFile;
begin
  Result := nil;
end;

function TFakeGameFileWriter.OpenFileAppend(const ARelativePath: string; ASync: Boolean;
  ABase: TGameWriteBase): IGameWriteFile;
begin
  Result := nil;
end;

function TFakeGameFileWriter.WriteFile(const ARelativePath: string; const AData: TBytes; ABase: TGameWriteBase): Integer;
begin
  Inc(FCalls);
  FWrittenPath := ARelativePath;
  FWrittenData := AData;
  FWrittenBase := ABase;
  if FResult = Low(Integer) then
    Result := Length(AData)
  else
    Result := FResult;
end;

procedure TFakeGameFileWriter.RemoveFile(const ARelativePath: string);
begin
end;

function TFakeGameFileWriter.RelativePathToOSPath(const ARelativePath: string; ABase: TGameWriteBase): string;
begin
  Result := ARelativePath;
end;

{ TTestDeclGameFileSource }

procedure TTestDeclGameFileSource.Setup;
begin
  FSystem := TFakeGameFileSystem.Create;
  FSystemIntf := FSystem;
  FWriter := TFakeGameFileWriter.Create;
  FWriterIntf := FWriter;
end;

procedure TTestDeclGameFileSource.TearDown;
begin
  FWriterIntf := nil;
  FSystemIntf := nil;
  FWriter := nil;
  FSystem := nil;
end;

function TTestDeclGameFileSource.Source(AWithWriter: Boolean): IDeclSource;
begin
  if AWithWriter then
    Result := TDeclGameFileSource.Create(FSystemIntf, FWriterIntf)
  else
    Result := TDeclGameFileSource.Create(FSystemIntf);
end;

class function TTestDeclGameFileSource.Join(const AValues: TArray<AnsiString>): string;
var
  LValue: AnsiString;
begin
  Result := '';
  for LValue in AValues do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + string(LValue);
  end;
end;

procedure TTestDeclGameFileSource.DovrebbeRifiutareUnFileSystemNil;
begin
  Assert.WillRaise(procedure begin TDeclGameFileSource.Create(nil); end, EArgumentNilException);
end;

procedure TTestDeclGameFileSource.DovrebbeElencareRelativoAllaCartella;
begin
  FSystem.SetTree(['materials/a.mtr', 'materials/sub/b.mtr']);
  Assert.AreEqual('a.mtr,sub/b.mtr', Join(Source.ListFiles('materials', '.mtr')));
end;

procedure TTestDeclGameFileSource.DovrebbeChiedereLAlberoOrdinatoConCartellaEdEstensione;
begin
  Source.ListFiles('skins', '.skin');
  Assert.AreEqual('skins', FSystem.TreeFolder);
  Assert.AreEqual('.skin', FSystem.TreeExtension);
  Assert.IsTrue(FSystem.TreeSorted);
  Assert.AreEqual(1, FSystem.TreeCalls);
end;

procedure TTestDeclGameFileSource.DovrebbeTogliereLaCartellaIgnorandoLeMaiuscole;
begin
  FSystem.SetTree(['Materials/A.MTR']);
  Assert.AreEqual('A.MTR', Join(Source.ListFiles('materials', '.mtr')));
end;

procedure TTestDeclGameFileSource.DovrebbeTenereIlNomeCheNonComincia;
begin
  // a name that does not start with the folder (it should not happen) is given as it is
  FSystem.SetTree(['other/x.mtr']);
  Assert.AreEqual('other/x.mtr', Join(Source.ListFiles('materials', '.mtr')));
end;

procedure TTestDeclGameFileSource.DovrebbeElencareVuotoSenzaFile;
begin
  Assert.AreEqual<Integer>(0, Length(Source.ListFiles('materials', '.mtr')));
end;

procedure TTestDeclGameFileSource.DovrebbeLeggereIlTestoEIlTempoDiUnFile;
var
  LText: AnsiString;
  LTimestamp: Int64;
begin
  FSystem.AddFile('materials/a.mtr', 'table x { }', 1234);
  Assert.IsTrue(Source.TryReadFile('materials/a.mtr', LText, LTimestamp));
  Assert.AreEqual('table x { }', string(LText));
  Assert.AreEqual<Int64>(1234, LTimestamp);
end;

procedure TTestDeclGameFileSource.DovrebbeLeggereIByteNonAsciiSenzaCambiarli;
var
  LText: AnsiString;
  LTimestamp: Int64;
begin
  FSystem.AddFile('materials/a.mtr', 'caf' + Chr(233) + Chr(200));
  Assert.IsTrue(Source.TryReadFile('materials/a.mtr', LText, LTimestamp));
  Assert.AreEqual<Integer>(5, Length(LText));
  Assert.AreEqual(233, Ord(LText[4]));
  Assert.AreEqual(200, Ord(LText[5]));
end;

procedure TTestDeclGameFileSource.DovrebbeLeggereUnFileVuoto;
var
  LText: AnsiString;
  LTimestamp: Int64;
begin
  FSystem.AddFile('empty.txt', '');
  Assert.IsTrue(Source.TryReadFile('empty.txt', LText, LTimestamp));
  Assert.AreEqual('', string(LText));
end;

procedure TTestDeclGameFileSource.DovrebbeDareFalsoPerUnFileCheManca;
var
  LText: AnsiString;
  LTimestamp: Int64;
begin
  LText := 'old';
  LTimestamp := 7;
  Assert.IsFalse(Source.TryReadFile('missing.txt', LText, LTimestamp));
  Assert.AreEqual('', string(LText));
  Assert.AreEqual<Int64>(0, LTimestamp);
end;

procedure TTestDeclGameFileSource.DovrebbeDareLunghezzaETempoSenzaLeggere;
var
  LLength: Integer;
  LTimestamp: Int64;
begin
  FSystem.AddFile('a.txt', 'hello', 99);
  Assert.IsTrue(Source.TryGetFileInfo('a.txt', LLength, LTimestamp));
  Assert.AreEqual(5, LLength);
  Assert.AreEqual<Int64>(99, LTimestamp);
end;

procedure TTestDeclGameFileSource.DovrebbeDareMenoUnoPerUnFileCheManca;
var
  LLength: Integer;
  LTimestamp: Int64;
begin
  Assert.IsFalse(Source.TryGetFileInfo('missing.txt', LLength, LTimestamp));
  Assert.AreEqual(-1, LLength);
  Assert.AreEqual<Int64>(0, LTimestamp);
end;

procedure TTestDeclGameFileSource.DovrebbeScrivereNelDevPathPerDefault;
begin
  Assert.IsTrue(Source.WriteFile('def/new.def', 'abc'));
  Assert.AreEqual('def/new.def', FWriter.WrittenPath);
  Assert.AreEqual<Integer>(3, Length(FWriter.WrittenData));
  Assert.AreEqual(Ord(TGameWriteBase.DevPath), Ord(FWriter.WrittenBase));
end;

procedure TTestDeclGameFileSource.DovrebbeScrivereNelPercorsoDato;
var
  LSource: IDeclSource;
begin
  LSource := TDeclGameFileSource.Create(FSystemIntf, FWriterIntf, TGameWriteBase.SavePath);
  Assert.IsTrue(LSource.WriteFile('a.def', 'x'));
  Assert.AreEqual(Ord(TGameWriteBase.SavePath), Ord(FWriter.WrittenBase));
end;

procedure TTestDeclGameFileSource.DovrebbeDareFalsoSeIlFileNonSiApre;
begin
  FWriter.Answer := -1;
  Assert.IsFalse(Source.WriteFile('a.def', 'x'));
  Assert.AreEqual(1, FWriter.Calls);
end;

procedure TTestDeclGameFileSource.DovrebbeDareFalsoSenzaUnScrittore;
begin
  Assert.IsFalse(Source(False).WriteFile('a.def', 'x'));
  Assert.AreEqual(0, FWriter.Calls);
end;

procedure TTestDeclGameFileSource.DovrebbeScrivereUnTestoVuoto;
begin
  FWriter.Answer := 0;
  Assert.IsTrue(Source.WriteFile('empty.def', ''));
  Assert.AreEqual<Integer>(0, Length(FWriter.WrittenData));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclGameFileSource);

end.
