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
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Write.Intf, DelphiDoom.Wad.Fs.ModList.Intf,
  DelphiDoom.Wad.Fs.PureServer.Intf;

type
  /// <summary>The only place of the file system of id Tech 4 that knows the concrete classes</summary>
  TGameFileSystemFactory = class
  public
    /// <summary>The file system on the disk of the machine, not started (call Startup)</summary>
    class function CreateOnDisk(const ASettings: TGameFsSettings): IGameFileSystem; static;
    /// <summary>The file system on a disk given by the caller (a test double, a virtual disk), not started</summary>
    class function CreateWithDisk(const ADisk: IGameDisk; const ASettings: TGameFsSettings): IGameFileSystem; static;
    /// <summary>
    ///   The writing side on the disk of the machine; <c>AFileSystem</c> must be a file system made by this factory
    ///   (it gives the game folder)
    /// </summary>
    class function CreateWriterOnDisk(const AFileSystem: IGameFileSystem; const ASettings: TGameFsSettings): IGameFileWriter; static;
    /// <summary>The writing side on a disk given by the caller</summary>
    class function CreateWriterWithDisk(const ADisk: IGameDiskWriter; const AFileSystem: IGameFileSystem;
      const ASettings: TGameFsSettings): IGameFileWriter; static;
    /// <summary>ListMods on the disk of the machine (<c>AHasExpansion</c>: the expansion pak is installed)</summary>
    class function CreateModListerOnDisk(const ASettings: TGameFsSettings; AHasExpansion: Boolean = False): IGameModLister; static;
    /// <summary>ListMods on a disk given by the caller</summary>
    class function CreateModListerWithDisk(const ADisk: IGameDisk; const ASettings: TGameFsSettings;
      AHasExpansion: Boolean = False): IGameModLister; static;
    /// <summary>The pure server lock over a file system made by this factory</summary>
    class function CreatePureServer(const AFileSystem: IGameFileSystem): IGamePureServer; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Disk, DelphiDoom.Wad.Fs.PackLoader, DelphiDoom.Wad.Fs.FileSystem,
  DelphiDoom.Wad.Fs.DiskWriter, DelphiDoom.Wad.Fs.Writer, DelphiDoom.Wad.Fs.ModLister, DelphiDoom.Wad.Fs.PureServer;

const
  SNotAGameFileSystem = 'The file system was not made by TGameFileSystemFactory';

function InspectorOf(const AFileSystem: IGameFileSystem): IGameFileSystemInspector;
begin
  if not Supports(AFileSystem, IGameFileSystemInspector, Result) then
    raise EGameFsException.Create(SNotAGameFileSystem);
end;

{ TGameFileSystemFactory }

class function TGameFileSystemFactory.CreateOnDisk(const ASettings: TGameFsSettings): IGameFileSystem;
begin
  Result := CreateWithDisk(TGameDisk.Create, ASettings);
end;

class function TGameFileSystemFactory.CreateWithDisk(const ADisk: IGameDisk; const ASettings: TGameFsSettings): IGameFileSystem;
begin
  Result := TGameFileSystem.Create(ADisk, TZipPackLoader.Create(ADisk), ASettings);
end;

class function TGameFileSystemFactory.CreateWriterOnDisk(const AFileSystem: IGameFileSystem;
  const ASettings: TGameFsSettings): IGameFileWriter;
begin
  Result := CreateWriterWithDisk(TGameDiskWriter.Create, AFileSystem, ASettings);
end;

class function TGameFileSystemFactory.CreateWriterWithDisk(const ADisk: IGameDiskWriter;
  const AFileSystem: IGameFileSystem; const ASettings: TGameFsSettings): IGameFileWriter;
begin
  Result := TGameFileWriter.Create(ADisk, InspectorOf(AFileSystem), ASettings);
end;

class function TGameFileSystemFactory.CreateModListerOnDisk(const ASettings: TGameFsSettings;
  AHasExpansion: Boolean): IGameModLister;
begin
  Result := CreateModListerWithDisk(TGameDisk.Create, ASettings, AHasExpansion);
end;

class function TGameFileSystemFactory.CreateModListerWithDisk(const ADisk: IGameDisk;
  const ASettings: TGameFsSettings; AHasExpansion: Boolean): IGameModLister;
begin
  Result := TGameModLister.Create(ADisk, ASettings, AHasExpansion);
end;

class function TGameFileSystemFactory.CreatePureServer(const AFileSystem: IGameFileSystem): IGamePureServer;
begin
  Result := TGamePureServer.Create(InspectorOf(AFileSystem));
end;

end.
