{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the factory: the composition root            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.Factory;

interface

uses
  DelphiDoom.Platform.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the platform</summary>
  TPlatformFactory = class
  public
    /// <summary>Whole files on the disk</summary>
    class function CreateFileStore: IFileStore; static;
    /// <summary>The temporary files, in a directory, deleted through a store</summary>
    class function CreateTempFiles(const ADirectory: ITempDirectory;
      const AStore: IFileStore): ITempFiles; static;
    /// <summary>The operating system, from Windows</summary>
    class function CreateOperatingSystemInfo: IOperatingSystemInfo; overload; static;
    /// <summary>The operating system, from any source (a fake one, in the tests)</summary>
    class function CreateOperatingSystemInfo(
      const ASource: IOperatingSystemSource): IOperatingSystemInfo; overload; static;
    /// <summary>Operating system, processor, executable, drives, DPI and priority of Windows</summary>
    class function CreateServices: IPlatformServices; static;
  end;

implementation

uses
  DelphiDoom.Platform.FileStore, DelphiDoom.Platform.TempFiles,
  DelphiDoom.Platform.WindowsVersionSource, DelphiDoom.Platform.OperatingSystemInfo,
  DelphiDoom.Platform.WindowsCpuInfo, DelphiDoom.Platform.ExecutableInfo,
  DelphiDoom.Platform.WindowsDriveInfo, DelphiDoom.Platform.WindowsDisplayDpi,
  DelphiDoom.Platform.WindowsThreadPriority, DelphiDoom.Platform.Services;

{ TPlatformFactory }

class function TPlatformFactory.CreateFileStore: IFileStore;
begin
  Result := TFileStore.Create;
end;

class function TPlatformFactory.CreateTempFiles(const ADirectory: ITempDirectory;
  const AStore: IFileStore): ITempFiles;
begin
  Result := TTempFiles.Create(ADirectory, AStore);
end;

class function TPlatformFactory.CreateOperatingSystemInfo: IOperatingSystemInfo;
begin
  Result := TOperatingSystemInfo.Create(TWindowsVersionSource.Create);
end;

class function TPlatformFactory.CreateOperatingSystemInfo(
  const ASource: IOperatingSystemSource): IOperatingSystemInfo;
begin
  Result := TOperatingSystemInfo.Create(ASource);
end;

class function TPlatformFactory.CreateServices: IPlatformServices;
begin
  Result := TPlatformServices.Create(CreateOperatingSystemInfo, TWindowsCpuInfo.Create,
    TExecutableInfo.Create, TWindowsDriveInfo.Create, TWindowsDisplayDpi.Create,
    TWindowsThreadPriority.Create);
end;

end.
