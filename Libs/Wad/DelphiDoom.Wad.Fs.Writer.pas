{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: the writing side        }
{                                                                              }
{  Port of OpenFileWrite, OpenFileAppend, WriteFile, RemoveFile,               }
{  CreateOSPath and RelativePathToOSPath of framework\FileSystem.cpp (id       }
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
unit DelphiDoom.Wad.Fs.Writer;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Write.Intf;

type
  /// <summary>
  ///   Writes the files of the game below one of the base folders (the save path unless another is asked
  ///   for) and the game folder of the file system, creating the folders on the way. The disk, the settings
  ///   and the file system whose game folder it uses come from the constructor. Not ported: the cache of
  ///   folder listings that the original flushes (the file system lists the disk each time),
  ///   <c>OpenExplicitFileWrite</c>, <c>fs_copyfiles</c> and <c>fs_caseSensitiveOS</c>.
  /// </summary>
  TGameFileWriter = class(TInterfacedObject, IGameFileWriter)
  strict private
    FDisk: IGameDiskWriter;
    FState: IGameFileSystemInspector;
    FSettings: TGameFsSettings;
    procedure EnsureInitialized;
    function BaseFolder(ABase: TGameWriteBase): string;
    procedure CreateOSPath(const AOSPath: string);
    function OpenFile(const ARelativePath: string; AAppend, ASync: Boolean; ABase: TGameWriteBase): IGameWriteFile;
  public
    /// <summary>EArgumentNilException when the disk or the file system is nil</summary>
    constructor Create(const ADisk: IGameDiskWriter; const AState: IGameFileSystemInspector;
      const ASettings: TGameFsSettings);
    function OpenFileWrite(const ARelativePath: string; ABase: TGameWriteBase = TGameWriteBase.SavePath): IGameWriteFile;
    function OpenFileAppend(const ARelativePath: string; ASync: Boolean = False;
      ABase: TGameWriteBase = TGameWriteBase.SavePath): IGameWriteFile;
    function WriteFile(const ARelativePath: string; const AData: TBytes;
      ABase: TGameWriteBase = TGameWriteBase.SavePath): Integer;
    procedure RemoveFile(const ARelativePath: string);
    function RelativePathToOSPath(const ARelativePath: string; ABase: TGameWriteBase = TGameWriteBase.SavePath): string;
  end;

implementation

uses
  System.Classes, DelphiDoom.Wad.Fs.Paths, DelphiDoom.Wad.Fs.WriteFile;

const
  SNotInitialized = 'Filesystem call made without initialization';
  SNilDisk = 'TGameFileWriter.Create: the disk is nil';
  SNilState = 'TGameFileWriter.Create: the file system is nil';

{ TGameFileWriter }

constructor TGameFileWriter.Create(const ADisk: IGameDiskWriter; const AState: IGameFileSystemInspector;
  const ASettings: TGameFsSettings);
begin
  inherited Create;
  if not Assigned(ADisk) then
    raise EArgumentNilException.Create(SNilDisk);
  if not Assigned(AState) then
    raise EArgumentNilException.Create(SNilState);
  FDisk := ADisk;
  FState := AState;
  FSettings := ASettings;
end;

procedure TGameFileWriter.EnsureInitialized;
begin
  if not FState.IsInitialized then
    raise EGameFsException.Create(SNotInitialized);
end;

function TGameFileWriter.BaseFolder(ABase: TGameWriteBase): string;
begin
  case ABase of
    TGameWriteBase.DevPath:
      Result := FSettings.DevPath;
    TGameWriteBase.BasePath:
      Result := FSettings.BasePath;
    TGameWriteBase.CdPath:
      Result := FSettings.CdPath;
  else
    Result := FSettings.SavePath;
  end;
  // a cvar that is not set: the save path
  if Result = '' then
    Result := FSettings.SavePath;
end;

function TGameFileWriter.RelativePathToOSPath(const ARelativePath: string; ABase: TGameWriteBase): string;
begin
  EnsureInitialized;
  Result := TGameFsPaths.BuildOSPath(BaseFolder(ABase), FState.GameFolder, ARelativePath);
end;

procedure TGameFileWriter.CreateOSPath(const AOSPath: string);
var
  LIndex: Integer;
begin
  // make absolutely sure that it can't back up the path
  if (Pos('..', AOSPath) > 0) or (Pos('::', AOSPath) > 0) then
    Exit;
  // from the second character: a leading separator is not a folder to create
  for LIndex := 2 to Length(AOSPath) do
    if AOSPath[LIndex] = PathDelim then
      FDisk.CreateDirectory(Copy(AOSPath, 1, LIndex - 1));
end;

function TGameFileWriter.OpenFile(const ARelativePath: string; AAppend, ASync: Boolean;
  ABase: TGameWriteBase): IGameWriteFile;
var
  LOSPath: string;
  LStream: TStream;
begin
  EnsureInitialized;
  Result := nil;
  if (Pos('..', ARelativePath) > 0) or (Pos('::', ARelativePath) > 0) then
    Exit;
  LOSPath := TGameFsPaths.BuildOSPath(BaseFolder(ABase), FState.GameFolder, ARelativePath);
  CreateOSPath(LOSPath);
  LStream := FDisk.OpenWrite(LOSPath, AAppend);
  if not Assigned(LStream) then
    Exit;
  Result := TGameWriteFile.Create(ARelativePath, LOSPath, LStream, AAppend, ASync);
end;

function TGameFileWriter.OpenFileWrite(const ARelativePath: string; ABase: TGameWriteBase): IGameWriteFile;
begin
  Result := OpenFile(ARelativePath, False, False, ABase);
end;

function TGameFileWriter.OpenFileAppend(const ARelativePath: string; ASync: Boolean;
  ABase: TGameWriteBase): IGameWriteFile;
begin
  Result := OpenFile(ARelativePath, True, ASync, ABase);
end;

function TGameFileWriter.WriteFile(const ARelativePath: string; const AData: TBytes; ABase: TGameWriteBase): Integer;
var
  LFile: IGameWriteFile;
begin
  LFile := OpenFileWrite(ARelativePath, ABase);
  if not Assigned(LFile) then
    Exit(-1);
  Result := LFile.Write(AData);
end;

procedure TGameFileWriter.RemoveFile(const ARelativePath: string);
begin
  EnsureInitialized;
  // the original does not look at the path; a file outside the game folder is not ours to remove
  if (Pos('..', ARelativePath) > 0) or (Pos('::', ARelativePath) > 0) then
    Exit;
  if FSettings.DevPath <> '' then
    FDisk.RemoveFile(TGameFsPaths.BuildOSPath(FSettings.DevPath, FState.GameFolder, ARelativePath));
  FDisk.RemoveFile(TGameFsPaths.BuildOSPath(FSettings.SavePath, FState.GameFolder, ARelativePath));
end;

end.
