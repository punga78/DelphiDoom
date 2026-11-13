{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclGameFileSource, the decl files in    }
{  the file system of id Tech 4                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Source.GameFs;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Write.Intf,
  DelphiDoom.Decl.Source.Intf;

type
  /// <summary>
  ///   An <c>IDeclSource</c> over the file system of <c>Libs\Wad</c> (issue #99): the files of the search list,
  ///   the ones in folders and the ones in the paks (PK4 and PK3: the same ZIP reader), the first in the list
  ///   winning, exactly as <c>fileSystem->ReadFile</c> and <c>ListFilesTree</c> do for the declaration manager.
  ///   Writing goes through an <c>IGameFileWriter</c> to the dev path (the original opens decl files with
  ///   <c>OpenFileWrite(name, "fs_devpath")</c>; the file system falls back to the save path when it is not set);
  ///   without a writer <c>WriteFile</c> says False. Names are bytes in the manager and Unicode in the file
  ///   system: they are converted with the code page of the system, which is the identity for the ASCII names the
  ///   game files have. The time of a file in a pak is 0, as for <c>idFile_InZip</c> (a reload sees no change).
  /// </summary>
  TDeclGameFileSource = class(TInterfacedObject, IDeclSource)
  strict private
    FFileSystem: IGameFileSystem;
    FWriter: IGameFileWriter;
    FWriteBase: TGameWriteBase;
  public
    /// <summary>EArgumentNilException when the file system is nil; the writer may be nil</summary>
    constructor Create(const AFileSystem: IGameFileSystem; const AWriter: IGameFileWriter = nil;
      const AWriteBase: TGameWriteBase = TGameWriteBase.DevPath);
    function ListFiles(const AFolder, AExtension: AnsiString): TArray<AnsiString>;
    function TryReadFile(const AName: AnsiString; out AText: AnsiString; out ATimestamp: Int64): Boolean;
    function TryGetFileInfo(const AName: AnsiString; out ALength: Integer; out ATimestamp: Int64): Boolean;
    function WriteFile(const AName, AText: AnsiString): Boolean;
  end;

implementation

const
  SNilFileSystem = 'TDeclGameFileSource.Create: the file system is nil';

{ TDeclGameFileSource }

constructor TDeclGameFileSource.Create(const AFileSystem: IGameFileSystem; const AWriter: IGameFileWriter;
  const AWriteBase: TGameWriteBase);
begin
  inherited Create;
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create(SNilFileSystem);
  FFileSystem := AFileSystem;
  FWriter := AWriter;
  FWriteBase := AWriteBase;
end;

function TDeclGameFileSource.ListFiles(const AFolder, AExtension: AnsiString): TArray<AnsiString>;
var
  LFound: TArray<string>;
  LPrefix, LName: string;
  LIndex, LCount: Integer;
begin
  // ListFilesTree( folder, extension, true ): the paths are relative to the game, sorted; the manager wants
  // them relative to the folder
  LFound := FFileSystem.ListFilesTree(string(AFolder), string(AExtension), True);
  LPrefix := string(AFolder) + '/';
  SetLength(Result, Length(LFound));
  LCount := 0;
  for LIndex := 0 to High(LFound) do
  begin
    LName := LFound[LIndex];
    if LName.StartsWith(LPrefix, True) then
      LName := Copy(LName, Length(LPrefix) + 1, MaxInt);
    Result[LCount] := AnsiString(LName);
    Inc(LCount);
  end;
  SetLength(Result, LCount);
end;

function TDeclGameFileSource.TryReadFile(const AName: AnsiString; out AText: AnsiString;
  out ATimestamp: Int64): Boolean;
var
  LFile: IGameFile;
  LBytes: TBytes;
begin
  AText := '';
  ATimestamp := 0;
  LFile := FFileSystem.OpenFileRead(string(AName));
  Result := Assigned(LFile);
  if not Result then
    Exit;
  LBytes := LFile.ReadAll;
  SetLength(AText, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], AText[1], Length(LBytes));
  ATimestamp := LFile.Timestamp;
end;

function TDeclGameFileSource.TryGetFileInfo(const AName: AnsiString; out ALength: Integer;
  out ATimestamp: Int64): Boolean;
var
  LFile: IGameFile;
begin
  ALength := -1;
  ATimestamp := 0;
  LFile := FFileSystem.OpenFileRead(string(AName));
  Result := Assigned(LFile);
  if Result then
  begin
    ALength := LFile.Length;
    ATimestamp := LFile.Timestamp;
  end;
end;

function TDeclGameFileSource.WriteFile(const AName, AText: AnsiString): Boolean;
var
  LBytes: TBytes;
begin
  if not Assigned(FWriter) then
    Exit(False);
  SetLength(LBytes, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], LBytes[0], Length(AText));
  Result := FWriter.WriteFile(string(AName), LBytes, FWriteBase) >= 0;
end;

end.
