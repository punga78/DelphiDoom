{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the Steam applications in the registry            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.SteamRegistry;

interface

uses
  DelphiDoom.Iwad.Intf;

type
  /// <summary>
  ///   Reads where Steam installed an application from the uninstall keys of the registry
  ///   (the 32 bit view, then the 64 bit one, then the 32 bit one of a 64 bit Windows)
  /// </summary>
  TIwadSteamRegistry = class(TInterfacedObject, IIwadSteam)
  strict private
    class function ReadInstallLocation(AAccess, AApplicationId: Integer): string; static;
  public
    function GetInstallDirectory(AApplicationId: Integer): string;
  end;

implementation

uses
  System.SysUtils, System.Win.Registry, Winapi.Windows;

const
  KEY_WOW64_64KEY = $100;
  KEY_WOW64_32KEY = $200;
  UNINSTALL_KEY = '\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App ';
  UNINSTALL_KEY_WOW6432 = '\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App ';
  INSTALL_VALUE = 'InstallLocation';

{ TIwadSteamRegistry }

class function TIwadSteamRegistry.ReadInstallLocation(AAccess, AApplicationId: Integer): string;
var
  LRegistry: TRegistry;
begin
  LRegistry := TRegistry.Create(AAccess);
  try
    LRegistry.RootKey := HKEY_LOCAL_MACHINE;
    if LRegistry.OpenKey(UNINSTALL_KEY + IntToStr(AApplicationId), False) then
      Result := LRegistry.ReadString(INSTALL_VALUE)
    else if LRegistry.OpenKey(UNINSTALL_KEY_WOW6432 + IntToStr(AApplicationId), False) then
      Result := LRegistry.ReadString(INSTALL_VALUE)
    else
      Result := '';
  finally
    LRegistry.Free;
  end;
end;

function TIwadSteamRegistry.GetInstallDirectory(AApplicationId: Integer): string;
begin
  Result := ReadInstallLocation(KEY_READ, AApplicationId);
  if Result = '' then
  begin
    Result := ReadInstallLocation(KEY_READ or KEY_WOW64_64KEY, AApplicationId);
    if Result = '' then
      Result := ReadInstallLocation(KEY_READ or KEY_WOW64_32KEY, AApplicationId);
  end;
  if Result <> '' then
  begin
    Result := StringReplace(Result, '/', '\', [rfReplaceAll]);
    if Result[Length(Result)] <> '\' then
      Result := Result + '\';
  end;
end;

end.
