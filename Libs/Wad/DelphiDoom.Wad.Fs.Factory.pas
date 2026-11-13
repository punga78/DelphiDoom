{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: the factory             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.Factory;

interface

uses
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf;

type
  /// <summary>The only place of the file system of id Tech 4 that knows the concrete classes</summary>
  TGameFileSystemFactory = class
  public
    /// <summary>The file system on the disk of the machine, not started (call Startup)</summary>
    class function CreateOnDisk(const ASettings: TGameFsSettings): IGameFileSystem; static;
    /// <summary>The file system on a disk given by the caller (a test double, a virtual disk), not started</summary>
    class function CreateWithDisk(const ADisk: IGameDisk; const ASettings: TGameFsSettings): IGameFileSystem; static;
  end;

implementation

uses
  DelphiDoom.Wad.Fs.Disk, DelphiDoom.Wad.Fs.PackLoader, DelphiDoom.Wad.Fs.FileSystem;

{ TGameFileSystemFactory }

class function TGameFileSystemFactory.CreateOnDisk(const ASettings: TGameFsSettings): IGameFileSystem;
begin
  Result := CreateWithDisk(TGameDisk.Create, ASettings);
end;

class function TGameFileSystemFactory.CreateWithDisk(const ADisk: IGameDisk; const ASettings: TGameFsSettings): IGameFileSystem;
begin
  Result := TGameFileSystem.Create(ADisk, TZipPackLoader.Create(ADisk), ASettings);
end;

end.
