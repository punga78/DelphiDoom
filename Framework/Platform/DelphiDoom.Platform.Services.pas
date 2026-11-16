{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the services about the machine               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.Services;

interface

uses
  DelphiDoom.Platform.Intf;

type
  /// <summary>IPlatformServices: holds the services it is given</summary>
  TPlatformServices = class(TInterfacedObject, IPlatformServices)
  strict private
    FOperatingSystem: IOperatingSystemInfo;
    FCpu: ICpuInfo;
    FExecutable: IExecutableInfo;
    FDrives: IDriveInfo;
    FDpi: IDisplayDpi;
    FPriority: IThreadPriority;
  public
    constructor Create(const AOperatingSystem: IOperatingSystemInfo; const ACpu: ICpuInfo;
      const AExecutable: IExecutableInfo; const ADrives: IDriveInfo; const ADpi: IDisplayDpi;
      const APriority: IThreadPriority);
    function GetOperatingSystem: IOperatingSystemInfo;
    function GetCpu: ICpuInfo;
    function GetExecutable: IExecutableInfo;
    function GetDrives: IDriveInfo;
    function GetDpi: IDisplayDpi;
    function GetPriority: IThreadPriority;
  end;

implementation

uses
  System.SysUtils;

{ TPlatformServices }

constructor TPlatformServices.Create(const AOperatingSystem: IOperatingSystemInfo;
  const ACpu: ICpuInfo; const AExecutable: IExecutableInfo; const ADrives: IDriveInfo;
  const ADpi: IDisplayDpi; const APriority: IThreadPriority);
begin
  inherited Create;
  if not Assigned(AOperatingSystem) then
    raise EArgumentNilException.Create('AOperatingSystem');
  if not Assigned(ACpu) then
    raise EArgumentNilException.Create('ACpu');
  if not Assigned(AExecutable) then
    raise EArgumentNilException.Create('AExecutable');
  if not Assigned(ADrives) then
    raise EArgumentNilException.Create('ADrives');
  if not Assigned(ADpi) then
    raise EArgumentNilException.Create('ADpi');
  if not Assigned(APriority) then
    raise EArgumentNilException.Create('APriority');
  FOperatingSystem := AOperatingSystem;
  FCpu := ACpu;
  FExecutable := AExecutable;
  FDrives := ADrives;
  FDpi := ADpi;
  FPriority := APriority;
end;

function TPlatformServices.GetOperatingSystem: IOperatingSystemInfo;
begin
  Result := FOperatingSystem;
end;

function TPlatformServices.GetCpu: ICpuInfo;
begin
  Result := FCpu;
end;

function TPlatformServices.GetExecutable: IExecutableInfo;
begin
  Result := FExecutable;
end;

function TPlatformServices.GetDrives: IDriveInfo;
begin
  Result := FDrives;
end;

function TPlatformServices.GetDpi: IDisplayDpi;
begin
  Result := FDpi;
end;

function TPlatformServices.GetPriority: IThreadPriority;
begin
  Result := FPriority;
end;

end.
