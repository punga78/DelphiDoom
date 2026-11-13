{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: the list of mods        }
{                                                                              }
{  Port of idFileSystemLocal::ListMods of framework\FileSystem.cpp (id         }
{  Software, GPL v3). Copyright (C) 1999-2011 id Software LLC, a ZeniMax       }
{  Media company.                                                              }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.ModLister;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.ModList.Intf;

type
  /// <summary>
  ///   ListMods: looks for game folders with paks in the save path, the dev path, the base path and the cd
  ///   path (in that order). Defects of the original that are kept: <c>pk4s</c> is cleared once per path and not
  ///   once per folder, so after the first folder with a pak every later folder of that path counts as a mod;
  ///   the description is the first line with its line feed, cut at 255 characters (<c>fgets</c>).
  /// </summary>
  TGameModLister = class(TInterfacedObject, IGameModLister)
  strict private
    const
      MAX_DESCRIPTION = 256;
    var
      FDisk: IGameDisk;
      FSettings: TGameFsSettings;
      FHasExpansion: Boolean;
      FBaseDescription: string;
    function SearchPaths: TArray<string>;
    function ReadDescription(const AFileName: string; out ADescription: string): Boolean;
  public
    /// <summary>
    ///   <c>AHasExpansion</c> is HasD3XP: the expansion folder is listed only when its pak is there (the caller
    ///   knows how to tell); <c>ABaseDescription</c> is the text of the base game
    /// </summary>
    constructor Create(const ADisk: IGameDisk; const ASettings: TGameFsSettings; AHasExpansion: Boolean = False;
      const ABaseDescription: string = 'Doom 3');
    function ListMods: TGameModList;
  end;

implementation

uses
  System.Classes, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Wad.Fs.Paths;

const
  SNilDisk = 'TGameModLister.Create: the disk is nil';
  SExpansionFolder = 'd3xp';

{ TGameModLister }

constructor TGameModLister.Create(const ADisk: IGameDisk; const ASettings: TGameFsSettings; AHasExpansion: Boolean;
  const ABaseDescription: string);
begin
  inherited Create;
  if not Assigned(ADisk) then
    raise EArgumentNilException.Create(SNilDisk);
  FDisk := ADisk;
  FSettings := ASettings;
  FHasExpansion := AHasExpansion;
  FBaseDescription := ABaseDescription;
end;

function TGameModLister.SearchPaths: TArray<string>;
begin
  Result := [FSettings.SavePath, FSettings.DevPath, FSettings.BasePath, FSettings.CdPath];
end;

// fgets( desc, MAX_DESCRIPTION, f ) on a file opened as text: up to 255 characters or the end of the first line,
// whose line feed is kept; False when nothing could be read
function TGameModLister.ReadDescription(const AFileName: string; out ADescription: string): Boolean;
var
  LStream: TStream;
  LByte: Byte;
  LText: string;
begin
  ADescription := '';
  LStream := FDisk.OpenRead(AFileName);
  if not Assigned(LStream) then
    Exit(False);
  try
    LText := '';
    while (Length(LText) < MAX_DESCRIPTION - 1) and (LStream.Read(LByte, 1) = 1) do
    begin
      // text mode: a carriage return before a line feed is not there
      if LByte = 13 then
      begin
        if (LStream.Read(LByte, 1) = 1) and (LByte = 10) then
        begin
          LText := LText + #10;
          Break;
        end;
        LText := LText + #13 + Chr(LByte);
        Continue;
      end;
      LText := LText + Chr(LByte);
      if LByte = 10 then
        Break;
    end;
  finally
    LStream.Free;
  end;
  ADescription := LText;
  Result := LText <> '';
end;

function TGameModLister.ListMods: TGameModList;
var
  LMods: TList<string>;
  LDirectories, LPakFiles: TList<string>;
  LSearch, LDirectory, LDescription: string;
  LDescribed: Boolean;
  LPakExtension: string;
  LName: string;
  LIndex, LSearchIndex: Integer;
  LSearchPaths: TArray<string>;
  LDescriptions: TList<string>;
begin
  LMods := TList<string>.Create;
  LDirectories := TList<string>.Create;
  LPakFiles := TList<string>.Create;
  LDescriptions := TList<string>.Create;
  try
    LSearchPaths := SearchPaths;
    for LSearch in LSearchPaths do
    begin
      LDirectories.Clear;
      LPakFiles.Clear;
      if LSearch = '' then
        Continue;
      // scan for directories
      LDirectories.AddRange(FDisk.ListFiles(LSearch, '/'));
      LPakExtension := FSettings.PakExtension;
      if LPakExtension = '' then
        LPakExtension := GAMEFS_PAK_EXTENSION;
      for LName in ['.', '..', 'base', 'pb'] do
        LDirectories.Remove(LName);
      // see if there are any pk4 files in each directory
      for LDirectory in LDirectories do
      begin
        LPakFiles.AddRange(FDisk.ListFiles(ExcludeTrailingPathDelimiter(TGameFsPaths.BuildOSPath(LSearch, LDirectory, '')),
          LPakExtension));
        if (LPakFiles.Count > 0) and not LMods.Contains(LDirectory) then
          // only list the expansion if its pak is present
          if not TGameFsPaths.SameIgnoringCase(LDirectory, SExpansionFolder) or FHasExpansion then
            LMods.Add(LDirectory);
      end;
    end;
    LMods.Sort(TComparer<string>.Construct(
      function(const ALeft, ARight: string): Integer
      begin
        Result := TGameFsPaths.CompareIgnoringCase(ALeft, ARight);
        if Result = 0 then
          Result := CompareStr(ALeft, ARight);
      end));
    // read the descriptions for each mod - search all paths
    for LIndex := 0 to LMods.Count - 1 do
    begin
      LDescribed := False;
      for LSearchIndex := 0 to High(LSearchPaths) do
      begin
        LDescribed := ReadDescription(
          TGameFsPaths.BuildOSPath(LSearchPaths[LSearchIndex], LMods[LIndex], 'description.txt'), LDescription);
        if LDescribed then
        begin
          LDescriptions.Add(LDescription);
          Break;
        end;
      end;
      if not LDescribed then
        LDescriptions.Add(LMods[LIndex]);
    end;
    LMods.Insert(0, '');
    LDescriptions.Insert(0, FBaseDescription);
    Result.Mods := LMods.ToArray;
    Result.Descriptions := LDescriptions.ToArray;
  finally
    LDescriptions.Free;
    LPakFiles.Free;
    LDirectories.Free;
    LMods.Free;
  end;
end;

end.
