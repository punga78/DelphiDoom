{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TWaveGameFileSystem (DUnitX)                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.WaveFileSystem;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Audio.WaveFile.Intf, DelphiDoom.Audio.WaveFile.GameFileSystem;

type
  /// <summary>A file system with one file, "a.wav", and nothing else</summary>
  TOneFileGameSystem = class(TInterfacedObject, IGameFileSystem)
  public
    procedure Startup;
    procedure Restart;
    procedure Shutdown;
    function IsInitialized: Boolean;
    function OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags; const AGameDir: string): IGameFile;
    function ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
    function FileLength(const ARelativePath: string): Integer;
    function FileIsInPak(const ARelativePath: string): Boolean;
    function ListFiles(const ARelativePath, AExtension: string; ASort, AFullRelativePath: Boolean;
      const AGameDir: string): TArray<string>;
    function ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean;
      const AGameDir: string): TArray<string>;
    function SearchPaths: TArray<TGameSearchPath>;
    function PackChecksums: TArray<Cardinal>;
    function AddonPackFileNames: TArray<string>;
  end;

  [TestFixture]
  [Category('audio')]
  TTestWaveGameFileSystem = class(TObject)
  public
    [Test]
    procedure DovrebbeInoltrareLunghezzaELetturaAlFileSystem;
    [Test]
    procedure DovrebbeDareTimestampZeroSeIlFileNonSiApre;
  end;

implementation

{ TOneFileGameSystem }

procedure TOneFileGameSystem.Startup;
begin
end;

procedure TOneFileGameSystem.Restart;
begin
end;

procedure TOneFileGameSystem.Shutdown;
begin
end;

function TOneFileGameSystem.IsInitialized: Boolean;
begin
  Result := True;
end;

function TOneFileGameSystem.OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags;
  const AGameDir: string): IGameFile;
begin
  Result := nil;
end;

function TOneFileGameSystem.ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
begin
  Result := SameText(ARelativePath, 'a.wav');
  if Result then
    AData := TBytes.Create(1, 2, 3)
  else
    AData := nil;
end;

function TOneFileGameSystem.FileLength(const ARelativePath: string): Integer;
begin
  if SameText(ARelativePath, 'a.wav') then
    Result := 3
  else
    Result := -1;
end;

function TOneFileGameSystem.FileIsInPak(const ARelativePath: string): Boolean;
begin
  Result := False;
end;

function TOneFileGameSystem.ListFiles(const ARelativePath, AExtension: string; ASort, AFullRelativePath: Boolean;
  const AGameDir: string): TArray<string>;
begin
  Result := nil;
end;

function TOneFileGameSystem.ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean;
  const AGameDir: string): TArray<string>;
begin
  Result := nil;
end;

function TOneFileGameSystem.SearchPaths: TArray<TGameSearchPath>;
begin
  Result := nil;
end;

function TOneFileGameSystem.PackChecksums: TArray<Cardinal>;
begin
  Result := nil;
end;

function TOneFileGameSystem.AddonPackFileNames: TArray<string>;
begin
  Result := nil;
end;

{ TTestWaveGameFileSystem }

procedure TTestWaveGameFileSystem.DovrebbeInoltrareLunghezzaELetturaAlFileSystem;
var
  LFiles: IWaveFileSystem;
  LData: TBytes;
begin
  LFiles := TWaveGameFileSystem.Create(TOneFileGameSystem.Create);
  Assert.AreEqual(3, LFiles.FileLength('a.wav'));
  Assert.AreEqual(-1, LFiles.FileLength('b.wav'));
  Assert.IsTrue(LFiles.TryReadFile('a.wav', LData));
  Assert.AreEqual<Integer>(3, Length(LData));
  Assert.IsFalse(LFiles.TryReadFile('b.wav', LData));
end;

procedure TTestWaveGameFileSystem.DovrebbeDareTimestampZeroSeIlFileNonSiApre;
var
  LFiles: IWaveFileSystem;
begin
  LFiles := TWaveGameFileSystem.Create(TOneFileGameSystem.Create);
  Assert.AreEqual<Int64>(0, LFiles.Timestamp('a.wav'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWaveGameFileSystem);

end.
