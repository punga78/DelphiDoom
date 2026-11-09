{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - FileMap of OpenXcom (the virtual folders   }
{  that merge the common data, the mod and the game files)                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FileMap;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   A list of root folders seen as one: a file name relative to the virtual root is looked for in the roots from
  ///   the last added (the one that overrides) to the first. Names ignore the case, as the files of the game do
  /// </summary>
  TXcomFileMap = class
  strict private
    FFiles: IXcomFileSystem;
    FRoots: TList<string>;
    function Combine(const ARoot, ARelative: string): string;
  public
    constructor Create(const AFiles: IXcomFileSystem);
    destructor Destroy; override;
    /// <summary>The last root added wins when two have the same file</summary>
    procedure AddRoot(const AFolder: string);
    /// <summary>FileMap::getFilePath: the real path, EXcomEngineException when no root has the file</summary>
    function FilePath(const ARelative: string): string;
    function TryFilePath(const ARelative: string; out APath: string): Boolean;
    function Exists(const ARelative: string): Boolean;
    function ReadAll(const ARelative: string): TBytes;
    /// <summary>The real folders that make a virtual folder, first root first (FileMap::getVFolderContents)</summary>
    function Folders(const ARelative: string): TArray<string>;
  end;

implementation

constructor TXcomFileMap.Create(const AFiles: IXcomFileSystem);
begin
  inherited Create;
  FFiles := AFiles;
  FRoots := TList<string>.Create;
end;

destructor TXcomFileMap.Destroy;
begin
  FRoots.Free;
  inherited Destroy;
end;

function TXcomFileMap.Combine(const ARoot, ARelative: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ARoot) + StringReplace(ARelative, '/', PathDelim, [rfReplaceAll]);
end;

procedure TXcomFileMap.AddRoot(const AFolder: string);
begin
  FRoots.Add(AFolder);
end;

function TXcomFileMap.TryFilePath(const ARelative: string; out APath: string): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := FRoots.Count - 1 downto 0 do
  begin
    APath := Combine(FRoots[LIndex], ARelative);
    if FFiles.FileExists(APath) then
      Exit(True);
  end;
  APath := '';
  Result := False;
end;

function TXcomFileMap.FilePath(const ARelative: string): string;
begin
  if not TryFilePath(ARelative, Result) then
    raise EXcomEngineException.Create(ARelative + ' not found');
end;

function TXcomFileMap.Exists(const ARelative: string): Boolean;
var
  LPath: string;
begin
  Result := TryFilePath(ARelative, LPath);
end;

function TXcomFileMap.ReadAll(const ARelative: string): TBytes;
begin
  Result := FFiles.ReadAll(FilePath(ARelative));
end;

function TXcomFileMap.Folders(const ARelative: string): TArray<string>;
var
  LList: TList<string>;
  LRoot: string;
  LPath: string;
begin
  LList := TList<string>.Create;
  try
    for LRoot in FRoots do
    begin
      LPath := Combine(LRoot, ARelative);
      if FFiles.FolderExists(LPath) then
        LList.Add(LPath);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

end.
