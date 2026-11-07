{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the version numbers from Windows             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.WindowsVersionSource;

interface

uses
  DelphiDoom.Platform.Intf, DelphiDoom.Platform.Types;

type
  /// <summary>
  ///   IOperatingSystemSource on GetVersionEx, as the old engine did: without a manifest that
  ///   lists the newer systems Windows reports the numbers of Windows 8
  /// </summary>
  TWindowsVersionSource = class(TInterfacedObject, IOperatingSystemSource)
  public
    function Read: TOperatingSystemVersion;
  end;

implementation

uses
  Winapi.Windows;

{ TWindowsVersionSource }

{$WARN SYMBOL_DEPRECATED OFF}
function TWindowsVersionSource.Read: TOperatingSystemVersion;
var
  LInfo: TOSVersionInfo;
begin
  ZeroMemory(@LInfo, SizeOf(LInfo));
  LInfo.dwOSVersionInfoSize := SizeOf(LInfo);
  GetVersionEx(LInfo);
  case LInfo.dwPlatformId of
    VER_PLATFORM_WIN32_WINDOWS:
      Result.Family := osfWindows9x;
    VER_PLATFORM_WIN32_NT:
      Result.Family := osfWindowsNT;
  else
    Result.Family := osfUnknown;
  end;
  Result.MajorVersion := LInfo.dwMajorVersion;
  Result.MinorVersion := LInfo.dwMinorVersion;
  Result.BuildNumber := LInfo.dwBuildNumber;
  Result.ServicePack := PChar(@LInfo.szCSDVersion[0]);
end;
{$WARN SYMBOL_DEPRECATED ON}

end.
