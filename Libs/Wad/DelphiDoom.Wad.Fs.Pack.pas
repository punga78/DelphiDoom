{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: a pak (pack_t)          }
{                                                                              }
{  Port of the file system of Doom 3 (id Software, GPL v3): pack_t and         }
{  LoadZipFile (framework\FileSystem.cpp). Copyright (C) 1999-2011 id          }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.Pack;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Zip.Intf, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf;

type
  /// <summary>
  ///   A pak: the entries of a ZIP (read by TZipFileSource, not by a second ZIP reader) with the names
  ///   as the file system compares them and the hash table of the original, in which the entry added
  ///   last comes first. The checksum is the one of LoadZipFile.
  /// </summary>
  TGamePack = class(TInterfacedObject, IGamePack)
  strict private
    FArchive: IZipArchive;
    FLength: Int64;
    FNames: TArray<string>;
    FBuckets: array of TArray<Integer>;
    FChecksum: Cardinal;
    FIsAddon: Boolean;
    FReferenced: Boolean;
    FHasAddonInfo: Boolean;
    FAddonInfo: TGameAddonInfo;
    procedure ReadAddonConfig;
  public
    /// <summary>ALength is the size of the file of the pak</summary>
    constructor Create(const AArchive: IZipArchive; ALength: Int64);
    function GetFileName: string;
    function GetEntryCount: Integer;
    function GetChecksum: Cardinal;
    function GetLength: Int64;
    function GetIsAddon: Boolean;
    function GetReferenced: Boolean;
    procedure SetReferenced(AValue: Boolean);
    function GetHasAddonInfo: Boolean;
    function GetAddonInfo: TGameAddonInfo;
    function EntryName(AIndex: Integer): string;
    function FindEntry(const ARelativePath: string): Integer;
    function EntrySize(AIndex: Integer): Int64;
    function ReadEntry(AIndex: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.Wad.Fs.Paths, DelphiDoom.Wad.Fs.AddonParser, DelphiDoom.IdLib.Hashing.Md4;

{ TGamePack }

constructor TGamePack.Create(const AArchive: IZipArchive; ALength: Int64);
var
  LIndex, LHash, LCount: Integer;
  LName: string;
  LCrcs: TArray<Cardinal>;
  LEmpty: Cardinal;
begin
  inherited Create;
  FArchive := AArchive;
  FLength := ALength;
  SetLength(FNames, AArchive.ArchiveEntryCount);
  SetLength(FBuckets, GAMEFS_FILE_HASH_SIZE);
  SetLength(LCrcs, AArchive.ArchiveEntryCount);
  LCount := 0;
  for LIndex := 0 to High(FNames) do
  begin
    LName := AArchive.ArchiveEntryName(LIndex);
    if AArchive.ArchiveEntrySize(LIndex) > 0 then
    begin
      LCrcs[LCount] := AArchive.ArchiveEntryCrc(LIndex);
      Inc(LCount);
    end;
    LHash := TGameFsPaths.HashFileName(LName);
    FNames[LIndex] := StringReplace(TGameFsPaths.ToLowerAscii(LName), '\', '/', [rfReplaceAll]);
    SetLength(FBuckets[LHash], Length(FBuckets[LHash]) + 1);
    FBuckets[LHash][High(FBuckets[LHash])] := LIndex;
  end;
  FIsAddon := FindEntry(GAMEFS_ADDON_CONFIG) >= 0;
  if FIsAddon then
    ReadAddonConfig;
  if LCount > 0 then
    FChecksum := TIdMd4.BlockChecksum(LCrcs[0], 4 * LCount)
  else
  begin
    LEmpty := 0;
    FChecksum := TIdMd4.BlockChecksum(LEmpty, 0);
  end;
end;

function TGamePack.GetFileName: string;
begin
  Result := FArchive.ArchiveName;
end;

function TGamePack.GetEntryCount: Integer;
begin
  Result := Length(FNames);
end;

function TGamePack.GetChecksum: Cardinal;
begin
  Result := FChecksum;
end;

function TGamePack.GetLength: Int64;
begin
  Result := FLength;
end;

function TGamePack.GetIsAddon: Boolean;
begin
  Result := FIsAddon;
end;

procedure TGamePack.ReadAddonConfig;
var
  LBytes: TBytes;
  LText: AnsiString;
begin
  // may be just an empty file if you don't bother about the mapDef
  LBytes := ReadEntry(FindEntry(GAMEFS_ADDON_CONFIG));
  if Length(LBytes) = 0 then
    Exit;
  SetLength(LText, Length(LBytes));
  Move(LBytes[0], LText[1], Length(LBytes));
  FHasAddonInfo := TGameAddonParser.Parse(LText, FAddonInfo);
  if not FHasAddonInfo then
    FAddonInfo := Default(TGameAddonInfo);
end;

function TGamePack.GetHasAddonInfo: Boolean;
begin
  Result := FHasAddonInfo;
end;

function TGamePack.GetAddonInfo: TGameAddonInfo;
begin
  Result := FAddonInfo;
end;

function TGamePack.GetReferenced: Boolean;
begin
  Result := FReferenced;
end;

procedure TGamePack.SetReferenced(AValue: Boolean);
begin
  FReferenced := AValue;
end;

function TGamePack.EntryName(AIndex: Integer): string;
begin
  Result := FNames[AIndex];
end;

function TGamePack.FindEntry(const ARelativePath: string): Integer;
var
  LBucket: TArray<Integer>;
  LPosition: Integer;
begin
  LBucket := FBuckets[TGameFsPaths.HashFileName(ARelativePath)];
  // the chain of the original starts with the entry added last
  for LPosition := High(LBucket) downto 0 do
    if TGameFsPaths.NamesEqual(FNames[LBucket[LPosition]], ARelativePath) then
      Exit(LBucket[LPosition]);
  Result := -1;
end;

function TGamePack.EntrySize(AIndex: Integer): Int64;
begin
  Result := FArchive.ArchiveEntrySize(AIndex);
end;

function TGamePack.ReadEntry(AIndex: Integer): TBytes;
begin
  Result := FArchive.ReadArchiveEntry(AIndex);
end;

end.
