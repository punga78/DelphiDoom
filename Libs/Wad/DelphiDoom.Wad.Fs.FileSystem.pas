{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4 (idFileSystemLocal)      }
{                                                                              }
{  Port of the file system of Doom 3 (id Software, GPL v3): the reading side   }
{  of framework\FileSystem.cpp (AddGameDirectory, SetupGameDirectories,        }
{  Startup, OpenFileReadFlags, ReadFile, FileIsInPAK, GetFileList,             }
{  GetFileListTree). Copyright (C) 1999-2011 id Software LLC, a ZeniMax        }
{  Media company.                                                              }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.FileSystem;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Wad.Fs.Types,
  DelphiDoom.Wad.Fs.Intf;

type
  /// <summary>
  ///   The search list of folders and paks of id Tech 4 and what is read from it. The list is searched
  ///   from the first element: the folders added last (fs_game over fs_game_base over base; save path
  ///   over dev path over base path over cd path) come first, and after each folder its paks from the
  ///   last in alphabetical order (pak1.pk4 before pak0.pk4). The disk and the loader of the paks are
  ///   injected. Writing is <c>TGameFileWriter</c>, the pure server <c>TGamePureServer</c>, ListMods
  ///   <c>TGameModLister</c> (they read the game folder and the paks through <c>IGameFileSystemInspector</c>, which
  ///   this class implements); an addon pak is read (<c>TGameAddonParser</c>) and the addons asked for by
  ///   checksum, and the paks they depend on, stay in the search list. Not ported: fs_copyfiles, the restart
  ///   in pure mode (restartChecksums), binary.conf, the journal, the keys, FindDLL and the download of paks.
  /// </summary>
  TGameFileSystem = class(TInterfacedObject, IGameFileSystem, IGameFileSystemInspector)
  strict private
    type
      TSearchEntry = record
        IsDirectory: Boolean;
        Path: string;
        GameDir: string;
        Pack: IGamePack;
      end;
  strict private
    FDisk: IGameDisk;
    FLoader: IGamePackLoader;
    FSettings: TGameFsSettings;
    FSearch: TList<TSearchEntry>;
    FAddons: TList<IGamePack>;
    FInitialized: Boolean;
    FGameFolder: string;
    procedure EnsureInitialized;
    procedure AddGameDirectory(const APath, ADirectory: string);
    procedure SetupGameDirectories(const AGameName: string);
    procedure FilterAddons;
    procedure FollowAddonDependencies(const APack: IGamePack; ASearched: TList<IGamePack>);
    function GetFileList(const ARelativePath: string; const AExtensions: TArray<string>; AList: TList<string>;
      ASeen: TDictionary<string, Integer>; AFullRelativePath: Boolean; const AGameDir: string): Integer;
    function GetFileListTree(const ARelativePath: string; const AExtensions: TArray<string>; AList: TList<string>;
      ASeen: TDictionary<string, Integer>; const AGameDir: string): Integer;
    class function AddUnique(const AName: string; AList: TList<string>; ASeen: TDictionary<string, Integer>): Integer; static;
    function FindInPack(const APack: IGamePack; const ARelativePath: string): IGameFile;
  public
    constructor Create(const ADisk: IGameDisk; const ALoader: IGamePackLoader; const ASettings: TGameFsSettings);
    destructor Destroy; override;
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
    function GameFolder: string;
    function Packs: TArray<IGamePack>;
    function AddonPacks: TArray<IGamePack>;
  end;

implementation

uses
  System.Generics.Defaults, DelphiDoom.Wad.Fs.Paths, DelphiDoom.Wad.Fs.GameFile;

const
  SNotInitialized = 'Filesystem call made without initialization';
  SEmptyName = 'TGameFileSystem.ReadFile with empty name';

{ TGameFileSystem }

constructor TGameFileSystem.Create(const ADisk: IGameDisk; const ALoader: IGamePackLoader;
  const ASettings: TGameFsSettings);
begin
  inherited Create;
  FDisk := ADisk;
  FLoader := ALoader;
  FSettings := ASettings;
  FSearch := TList<TSearchEntry>.Create;
  FAddons := TList<IGamePack>.Create;
end;

destructor TGameFileSystem.Destroy;
begin
  FAddons.Free;
  FSearch.Free;
  inherited Destroy;
end;

procedure TGameFileSystem.EnsureInitialized;
begin
  if not FInitialized then
    raise EGameFsException.Create(SNotInitialized);
end;

procedure TGameFileSystem.AddGameDirectory(const APath, ADirectory: string);
var
  LEntry: TSearchEntry;
  LPakFiles: TArray<string>;
  LPakDirectory, LName: string;
  LPack: IGamePack;
begin
  // the folder is already in the list
  for LEntry in FSearch do
    if LEntry.IsDirectory and (LEntry.Path = APath) and (LEntry.GameDir = ADirectory) then
      Exit;
  FGameFolder := ADirectory;
  LEntry := Default(TSearchEntry);
  LEntry.IsDirectory := True;
  LEntry.Path := APath;
  LEntry.GameDir := ADirectory;
  FSearch.Insert(0, LEntry);
  LPakDirectory := ExcludeTrailingPathDelimiter(TGameFsPaths.BuildOSPath(APath, ADirectory, ''));
  if FSettings.PakExtension <> '' then
    LPakFiles := FDisk.ListFiles(LPakDirectory, FSettings.PakExtension)
  else
    LPakFiles := FDisk.ListFiles(LPakDirectory, GAMEFS_PAK_EXTENSION);
  // later names override earlier ones: pak1.pk4 over pak0.pk4 (the order ignores the case, as idStrList::Sort)
  TArray.Sort<string>(LPakFiles, TComparer<string>.Construct(
    function(const ALeft, ARight: string): Integer
    begin
      Result := TGameFsPaths.CompareIgnoringCase(ALeft, ARight);
    end));
  for LName in LPakFiles do
  begin
    LPack := FLoader.Load(TGameFsPaths.BuildOSPath(APath, ADirectory, LName));
    if not Assigned(LPack) then
      Continue;
    LEntry := Default(TSearchEntry);
    LEntry.Pack := LPack;
    // right after the folder it comes from
    FSearch.Insert(1, LEntry);
  end;
end;

procedure TGameFileSystem.SetupGameDirectories(const AGameName: string);
begin
  if FSettings.CdPath <> '' then
    AddGameDirectory(FSettings.CdPath, AGameName);
  if FSettings.BasePath <> '' then
    AddGameDirectory(FSettings.BasePath, AGameName);
  if FSettings.DevPath <> '' then
    AddGameDirectory(FSettings.DevPath, AGameName);
  if FSettings.SavePath <> '' then
    AddGameDirectory(FSettings.SavePath, AGameName);
end;

procedure TGameFileSystem.FollowAddonDependencies(const APack: IGamePack; ASearched: TList<IGamePack>);
var
  LChecksum: Cardinal;
  LEntry: TSearchEntry;
  LDependency: IGamePack;
begin
  if not APack.HasAddonInfo then
    Exit;
  for LChecksum in APack.AddonInfo.Depends do
  begin
    LDependency := nil;
    for LEntry in FSearch do
      if Assigned(LEntry.Pack) and (LEntry.Pack.Checksum = LChecksum) then
      begin
        LDependency := LEntry.Pack;
        Break;
      end;
    // a checksum that no pak has is "depends on unknown pak" in the original, a message only
    if Assigned(LDependency) and not ASearched.Contains(LDependency) then
    begin
      ASearched.Add(LDependency);
      FollowAddonDependencies(LDependency, ASearched);
    end;
  end;
end;

procedure TGameFileSystem.FilterAddons;
var
  LIndex: Integer;
  LPack: IGamePack;
  LChecksum: Cardinal;
  LSearched: TList<IGamePack>;
begin
  if FSettings.SearchAddons then
    Exit;
  LSearched := TList<IGamePack>.Create;
  try
    // the addons that were asked for (and the paks they depend on) stay in the search list
    for LChecksum in FSettings.AddonChecksums do
      for LIndex := 0 to FSearch.Count - 1 do
      begin
        LPack := FSearch[LIndex].Pack;
        if Assigned(LPack) and LPack.IsAddon and (LPack.Checksum = LChecksum) and not LSearched.Contains(LPack) then
        begin
          LSearched.Add(LPack);
          FollowAddonDependencies(LPack, LSearched);
        end;
      end;
    // the others leave the search list for the list of addons (the last one out comes first)
    LIndex := 0;
    while LIndex < FSearch.Count do
    begin
      LPack := FSearch[LIndex].Pack;
      if Assigned(LPack) and LPack.IsAddon and not LSearched.Contains(LPack) then
      begin
        FSearch.Delete(LIndex);
        FAddons.Insert(0, LPack);
      end
      else
        Inc(LIndex);
    end;
  finally
    LSearched.Free;
  end;
end;

procedure TGameFileSystem.Startup;
begin
  FSearch.Clear;
  FAddons.Clear;
  FGameFolder := '';
  SetupGameDirectories(GAMEFS_BASE_GAMEDIR);
  if (FSettings.GameBase <> '') and not TGameFsPaths.SameIgnoringCase(FSettings.GameBase, GAMEFS_BASE_GAMEDIR) then
    SetupGameDirectories(FSettings.GameBase);
  if (FSettings.Game <> '') and not TGameFsPaths.SameIgnoringCase(FSettings.Game, GAMEFS_BASE_GAMEDIR)
    and not TGameFsPaths.SameIgnoringCase(FSettings.Game, FSettings.GameBase) then
    SetupGameDirectories(FSettings.Game);
  FilterAddons;
  FInitialized := True;
end;

procedure TGameFileSystem.Shutdown;
begin
  FSearch.Clear;
  FAddons.Clear;
  FGameFolder := '';
  FInitialized := False;
end;

procedure TGameFileSystem.Restart;
begin
  Shutdown;
  Startup;
end;

function TGameFileSystem.IsInitialized: Boolean;
begin
  Result := FInitialized;
end;

function TGameFileSystem.FindInPack(const APack: IGamePack; const ARelativePath: string): IGameFile;
var
  LIndex: Integer;
begin
  Result := nil;
  LIndex := APack.FindEntry(ARelativePath);
  if LIndex >= 0 then
    Result := TGameFile.CreateFromPack(ARelativePath, APack, LIndex);
end;

function TGameFileSystem.OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags;
  const AGameDir: string): IGameFile;
var
  LPath, LNetPath: string;
  LEntry: TSearchEntry;
  LStream: TStream;
  LPack: IGamePack;
begin
  EnsureInitialized;
  Result := nil;
  // no leading slash, no way back up the path
  if not TGameFsPaths.CleanRelativePath(ARelativePath, LPath) then
    Exit;
  if LPath = '' then
    Exit;
  for LEntry in FSearch do
  begin
    if LEntry.IsDirectory then
    begin
      if not (TGameSearchFlag.SearchDirs in AFlags) then
        Continue;
      if (AGameDir <> '') and (LEntry.GameDir <> AGameDir) then
        Continue;
      LNetPath := TGameFsPaths.BuildOSPath(LEntry.Path, LEntry.GameDir, LPath);
      LStream := FDisk.OpenRead(LNetPath);
      if not Assigned(LStream) then
        Continue;
      Exit(TGameFile.CreateFromDirectory(LPath, LNetPath, LStream, FDisk.FileTimestamp(LNetPath)));
    end
    else if TGameSearchFlag.SearchPaks in AFlags then
    begin
      Result := FindInPack(LEntry.Pack, LPath);
      if Assigned(Result) then
      begin
        if not (TGameSearchFlag.NoReference in AFlags) then
          LEntry.Pack.Referenced := True;
        Exit;
      end;
    end;
  end;
  if TGameSearchFlag.SearchAddons in AFlags then
    for LPack in FAddons do
    begin
      Result := FindInPack(LPack, LPath);
      if Assigned(Result) then
        Exit;
    end;
end;

function TGameFileSystem.ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
var
  LFile: IGameFile;
begin
  EnsureInitialized;
  if ARelativePath = '' then
    raise EGameFsException.Create(SEmptyName);
  AData := nil;
  LFile := OpenFileRead(ARelativePath);
  Result := Assigned(LFile);
  if Result then
    AData := LFile.ReadAll;
end;

function TGameFileSystem.FileLength(const ARelativePath: string): Integer;
var
  LFile: IGameFile;
begin
  EnsureInitialized;
  if ARelativePath = '' then
    raise EGameFsException.Create(SEmptyName);
  LFile := OpenFileRead(ARelativePath);
  if Assigned(LFile) then
    Result := LFile.Length
  else
    Result := -1;
end;

function TGameFileSystem.FileIsInPak(const ARelativePath: string): Boolean;
var
  LPath: string;
  LEntry: TSearchEntry;
begin
  EnsureInitialized;
  Result := False;
  if not TGameFsPaths.CleanRelativePath(ARelativePath, LPath) then
    Exit;
  for LEntry in FSearch do
    if Assigned(LEntry.Pack) and (LEntry.Pack.FindEntry(LPath) >= 0) then
      Exit(True);
end;

class function TGameFileSystem.AddUnique(const AName: string; AList: TList<string>;
  ASeen: TDictionary<string, Integer>): Integer;
var
  LKey: string;
begin
  LKey := TGameFsPaths.ToLowerAscii(AName);
  if ASeen.TryGetValue(LKey, Result) then
    Exit;
  Result := AList.Add(AName);
  ASeen.Add(LKey, Result);
end;

function TGameFileSystem.GetFileList(const ARelativePath: string; const AExtensions: TArray<string>;
  AList: TList<string>; ASeen: TDictionary<string, Integer>; AFullRelativePath: Boolean;
  const AGameDir: string): Integer;
var
  LEntry: TSearchEntry;
  LPathLength, LLength, LIndex, LScan, LExt: Integer;
  LNetPath, LName, LWork, LFile: string;
  LExtension: string;
  LPack: IGamePack;
  LMatched: Boolean;
begin
  EnsureInitialized;
  Result := 0;
  if Length(AExtensions) = 0 then
    Exit;
  LPathLength := Length(ARelativePath);
  if LPathLength > 0 then
    Inc(LPathLength); // for the trailing '/'
  for LEntry in FSearch do
  begin
    if LEntry.IsDirectory then
    begin
      if (AGameDir <> '') and (LEntry.GameDir <> AGameDir) then
        Continue;
      LNetPath := TGameFsPaths.BuildOSPath(LEntry.Path, LEntry.GameDir, ARelativePath);
      for LExtension in AExtensions do
        for LFile in FDisk.ListFiles(LNetPath, LExtension) do
          if AFullRelativePath then
            AddUnique(ARelativePath + '/' + LFile, AList, ASeen)
          else
            AddUnique(LFile, AList, ASeen);
    end
    else
    begin
      LPack := LEntry.Pack;
      for LIndex := 0 to LPack.EntryCount - 1 do
      begin
        LName := LPack.EntryName(LIndex);
        LLength := Length(LName);
        // the name must be longer than the path
        if LLength <= LPathLength then
          Continue;
        if LPathLength > 0 then
        begin
          // the path without the trailing '/'
          if not TGameFsPaths.SameIgnoringCase(Copy(LName, 1, LPathLength - 1), ARelativePath) then
            Continue;
          // a path, not just a file name that starts with it
          if LName[LPathLength] <> '/' then
            Continue;
        end;
        // not in a subfolder: no '/' from the first character after the path to the one before the last
        LScan := LPathLength;
        while (LScan + 1 < LLength) and (LName[LScan + 1] <> '/') do
          Inc(LScan);
        if LScan + 1 < LLength then
          Continue;
        // the extension
        LMatched := False;
        for LExt := 0 to High(AExtensions) do
          if (LLength >= Length(AExtensions[LExt])) and
            TGameFsPaths.SameIgnoringCase(AExtensions[LExt], Copy(LName, LLength - Length(AExtensions[LExt]) + 1, MaxInt)) then
          begin
            LMatched := True;
            Break;
          end;
        if not LMatched then
          Continue;
        LWork := Copy(LName, LPathLength + 1, MaxInt);
        if AFullRelativePath then
          LWork := ARelativePath + '/' + LWork;
        AddUnique(TGameFsPaths.StripTrailingSlashes(LWork), AList, ASeen);
      end;
    end;
  end;
  Result := AList.Count;
end;

function TGameFileSystem.GetFileListTree(const ARelativePath: string; const AExtensions: TArray<string>;
  AList: TList<string>; ASeen: TDictionary<string, Integer>; const AGameDir: string): Integer;
var
  LFolders: TList<string>;
  LFolderSeen: TDictionary<string, Integer>;
  LFolder: string;
  LIndex: Integer;
begin
  LFolders := TList<string>.Create;
  LFolderSeen := TDictionary<string, Integer>.Create;
  try
    // recurse through the subfolders
    GetFileList(ARelativePath, ['/'], LFolders, LFolderSeen, True, AGameDir);
    for LIndex := 0 to LFolders.Count - 1 do
    begin
      LFolder := LFolders[LIndex];
      if (LFolder <> '') and (LFolder[1] = '.') then
        Continue;
      if TGameFsPaths.SameIgnoringCase(LFolder, ARelativePath) then
        Continue;
      GetFileListTree(LFolder, AExtensions, AList, ASeen, AGameDir);
    end;
  finally
    LFolderSeen.Free;
    LFolders.Free;
  end;
  // the files of this folder
  GetFileList(ARelativePath, AExtensions, AList, ASeen, True, AGameDir);
  Result := AList.Count;
end;

function TGameFileSystem.ListFiles(const ARelativePath, AExtension: string; ASort: Boolean;
  AFullRelativePath: Boolean; const AGameDir: string): TArray<string>;
var
  LList: TList<string>;
  LSeen: TDictionary<string, Integer>;
begin
  EnsureInitialized;
  LList := TList<string>.Create;
  LSeen := TDictionary<string, Integer>.Create;
  try
    GetFileList(ARelativePath, TGameFsPaths.SplitExtensions(AExtension), LList, LSeen, AFullRelativePath, AGameDir);
    Result := LList.ToArray;
  finally
    LSeen.Free;
    LList.Free;
  end;
  if ASort then
    TGameFsPaths.SortPaths(Result);
end;

function TGameFileSystem.ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean;
  const AGameDir: string): TArray<string>;
var
  LList: TList<string>;
  LSeen: TDictionary<string, Integer>;
begin
  EnsureInitialized;
  LList := TList<string>.Create;
  LSeen := TDictionary<string, Integer>.Create;
  try
    GetFileListTree(ARelativePath, TGameFsPaths.SplitExtensions(AExtension), LList, LSeen, AGameDir);
    Result := LList.ToArray;
  finally
    LSeen.Free;
    LList.Free;
  end;
  if ASort then
    TGameFsPaths.SortPaths(Result);
end;

function TGameFileSystem.SearchPaths: TArray<TGameSearchPath>;
var
  LIndex: Integer;
begin
  EnsureInitialized;
  SetLength(Result, FSearch.Count);
  for LIndex := 0 to FSearch.Count - 1 do
  begin
    Result[LIndex] := Default(TGameSearchPath);
    Result[LIndex].IsDirectory := FSearch[LIndex].IsDirectory;
    if FSearch[LIndex].IsDirectory then
    begin
      Result[LIndex].Path := FSearch[LIndex].Path;
      Result[LIndex].GameDir := FSearch[LIndex].GameDir;
    end
    else
    begin
      Result[LIndex].PackFileName := FSearch[LIndex].Pack.FileName;
      Result[LIndex].Checksum := FSearch[LIndex].Pack.Checksum;
      Result[LIndex].IsAddon := FSearch[LIndex].Pack.IsAddon;
    end;
  end;
end;

function TGameFileSystem.PackChecksums: TArray<Cardinal>;
var
  LEntry: TSearchEntry;
begin
  EnsureInitialized;
  Result := nil;
  for LEntry in FSearch do
    if Assigned(LEntry.Pack) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LEntry.Pack.Checksum;
    end;
end;

function TGameFileSystem.AddonPackFileNames: TArray<string>;
var
  LIndex: Integer;
begin
  EnsureInitialized;
  SetLength(Result, FAddons.Count);
  for LIndex := 0 to FAddons.Count - 1 do
    Result[LIndex] := FAddons[LIndex].FileName;
end;

function TGameFileSystem.GameFolder: string;
begin
  Result := FGameFolder;
end;

function TGameFileSystem.Packs: TArray<IGamePack>;
var
  LEntry: TSearchEntry;
begin
  EnsureInitialized;
  Result := nil;
  for LEntry in FSearch do
    if Assigned(LEntry.Pack) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LEntry.Pack;
    end;
end;

function TGameFileSystem.AddonPacks: TArray<IGamePack>;
begin
  EnsureInitialized;
  Result := FAddons.ToArray;
end;

end.
