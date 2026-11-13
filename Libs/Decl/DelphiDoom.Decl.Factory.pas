{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclFactory, the place that knows the    }
{  concrete classes                                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Factory;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Source.Intf,
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Write.Intf;

type
  /// <summary>Builds a declaration manager (the composition root of the library)</summary>
  TDeclFactory = class sealed
  public
    /// <summary>An empty manager: no type is registered, no file is read</summary>
    class function CreateManager(const ASource: IDeclSource; const ALog: IIdLibLog = nil): IDeclManager; static;
    /// <summary>
    ///   A manager with the standard types of Doom 3 registered (<c>TDeclStandardTypes.RegisterTypes</c>) and, if
    ///   <c>ALoadFolders</c>, the standard folders loaded
    /// </summary>
    class function CreateStandardManager(const ASource: IDeclSource; const ALog: IIdLibLog = nil;
      const ALoadFolders: Boolean = True): IDeclManager; static;
    /// <summary>
    ///   The decl files as the file system of <c>Libs\Wad</c> has them (folders, PK4 and PK3). The writer may be nil
    ///   (a read-only source); decl files are written to the dev path
    /// </summary>
    class function CreateFileSystemSource(const AFileSystem: IGameFileSystem;
      const AWriter: IGameFileWriter = nil): IDeclSource; static;
    /// <summary>
    ///   <c>CreateStandardManager</c> over the decl files of a started file system: the game folder, the paks, and
    ///   <c>OpenFileWrite</c> for the saves
    /// </summary>
    class function CreateStandardManagerOnFileSystem(const AFileSystem: IGameFileSystem;
      const AWriter: IGameFileWriter = nil; const ALog: IIdLibLog = nil;
      const ALoadFolders: Boolean = True): IDeclManager; static;
    /// <summary>
    ///   <c>CreateStandardManager</c> on the disk of the machine: builds the file system and the writer from the
    ///   settings (the cvars of the paths), starts the file system and reads the standard folders
    /// </summary>
    class function CreateStandardManagerOnDisk(const ASettings: TGameFsSettings; const ALog: IIdLibLog = nil;
      const ALoadFolders: Boolean = True): IDeclManager; static;
    /// <summary>
    ///   A manager for the shaders of Quake III (<c>.shader</c> files in <c>scripts</c>, read with their own scanner)
    ///   and nothing else: the types of Doom 3 are not registered. With <c>ALoadFolder</c> the folder is read now.
    /// </summary>
    class function CreateQuake3ShaderManager(const ASource: IDeclSource; const ALog: IIdLibLog = nil;
      const ALoadFolder: Boolean = True): IDeclManager; static;
    /// <summary>The Quake III shader manager over a started file system (the PK3 of the game and its folders)</summary>
    class function CreateQuake3ShaderManagerOnFileSystem(const AFileSystem: IGameFileSystem;
      const AWriter: IGameFileWriter = nil; const ALog: IIdLibLog = nil;
      const ALoadFolder: Boolean = True): IDeclManager; static;
    /// <summary>The Quake III shader manager on the disk of the machine (the file system is built and started)</summary>
    class function CreateQuake3ShaderManagerOnDisk(const ASettings: TGameFsSettings; const ALog: IIdLibLog = nil;
      const ALoadFolder: Boolean = True): IDeclManager; static;
  end;

implementation

uses
  DelphiDoom.Decl.Manager, DelphiDoom.Decl.StandardTypes, DelphiDoom.Decl.Source.GameFs,
  DelphiDoom.Decl.Q3Shader.Registration, DelphiDoom.Wad.Fs.Factory;

{ TDeclFactory }

class function TDeclFactory.CreateManager(const ASource: IDeclSource; const ALog: IIdLibLog): IDeclManager;
begin
  Result := TDeclManager.Create(ASource, ALog);
end;

class function TDeclFactory.CreateStandardManager(const ASource: IDeclSource; const ALog: IIdLibLog;
  const ALoadFolders: Boolean): IDeclManager;
begin
  Result := CreateManager(ASource, ALog);
  TDeclStandardTypes.RegisterTypes(Result.GetRegistry, []);
  if ALoadFolders then
    TDeclStandardTypes.RegisterFolders(Result.GetRegistry);
end;

class function TDeclFactory.CreateFileSystemSource(const AFileSystem: IGameFileSystem;
  const AWriter: IGameFileWriter): IDeclSource;
begin
  Result := TDeclGameFileSource.Create(AFileSystem, AWriter);
end;

class function TDeclFactory.CreateStandardManagerOnFileSystem(const AFileSystem: IGameFileSystem;
  const AWriter: IGameFileWriter; const ALog: IIdLibLog; const ALoadFolders: Boolean): IDeclManager;
begin
  Result := CreateStandardManager(CreateFileSystemSource(AFileSystem, AWriter), ALog, ALoadFolders);
end;

class function TDeclFactory.CreateStandardManagerOnDisk(const ASettings: TGameFsSettings; const ALog: IIdLibLog;
  const ALoadFolders: Boolean): IDeclManager;
var
  LFileSystem: IGameFileSystem;
begin
  LFileSystem := TGameFileSystemFactory.CreateOnDisk(ASettings);
  LFileSystem.Startup;
  Result := CreateStandardManagerOnFileSystem(LFileSystem,
    TGameFileSystemFactory.CreateWriterOnDisk(LFileSystem, ASettings), ALog, ALoadFolders);
end;

class function TDeclFactory.CreateQuake3ShaderManager(const ASource: IDeclSource; const ALog: IIdLibLog;
  const ALoadFolder: Boolean): IDeclManager;
begin
  Result := CreateManager(ASource, ALog);
  TQ3ShaderRegistration.RegisterType(Result.GetRegistry, []);
  if ALoadFolder then
    TQ3ShaderRegistration.RegisterFolder(Result.GetRegistry);
end;

class function TDeclFactory.CreateQuake3ShaderManagerOnFileSystem(const AFileSystem: IGameFileSystem;
  const AWriter: IGameFileWriter; const ALog: IIdLibLog; const ALoadFolder: Boolean): IDeclManager;
begin
  Result := CreateQuake3ShaderManager(CreateFileSystemSource(AFileSystem, AWriter), ALog, ALoadFolder);
end;

class function TDeclFactory.CreateQuake3ShaderManagerOnDisk(const ASettings: TGameFsSettings; const ALog: IIdLibLog;
  const ALoadFolder: Boolean): IDeclManager;
var
  LFileSystem: IGameFileSystem;
begin
  LFileSystem := TGameFileSystemFactory.CreateOnDisk(ASettings);
  LFileSystem.Startup;
  Result := CreateQuake3ShaderManagerOnFileSystem(LFileSystem,
    TGameFileSystemFactory.CreateWriterOnDisk(LFileSystem, ASettings), ALog, ALoadFolder);
end;

end.
