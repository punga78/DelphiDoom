{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the drives of Windows                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.WindowsDriveInfo;

interface

uses
  DelphiDoom.Platform.Intf;

type
  /// <summary>IDriveInfo on GetDriveType</summary>
  TWindowsDriveInfo = class(TInterfacedObject, IDriveInfo)
  public
    /// <summary>
    ///   The root a program started from: the first three characters of its path ('C:\'), or
    ///   empty (the current drive) when the path is too short to have one
    /// </summary>
    class function RootOfProgram(const AProgramPath: string): string; static;
    /// <summary>The root of a drive letter: 'X:\'</summary>
    class function RootOfDrive(ADrive: Char): string; static;
    /// <summary>True if the drive of a root ('C:\') is a CD-ROM; an empty root is the current one</summary>
    function IsCdRom(const ARoot: string): Boolean;
    function IsCdRomDrive(ADrive: Char): Boolean;
    function IsProgramOnCdRom(const AProgramPath: string): Boolean;
  end;

implementation

uses
  Winapi.Windows;

{ TWindowsDriveInfo }

class function TWindowsDriveInfo.RootOfProgram(const AProgramPath: string): string;
begin
  if Length(AProgramPath) > 4 then
    Result := Copy(AProgramPath, 1, 3)
  else
    Result := '';
end;

class function TWindowsDriveInfo.RootOfDrive(ADrive: Char): string;
begin
  Result := ADrive + ':\';
end;

function TWindowsDriveInfo.IsCdRom(const ARoot: string): Boolean;
begin
  if ARoot = '' then
    Result := GetDriveType(nil) = DRIVE_CDROM
  else
    Result := GetDriveType(PChar(ARoot)) = DRIVE_CDROM;
end;

function TWindowsDriveInfo.IsCdRomDrive(ADrive: Char): Boolean;
begin
  Result := IsCdRom(RootOfDrive(ADrive));
end;

function TWindowsDriveInfo.IsProgramOnCdRom(const AProgramPath: string): Boolean;
begin
  Result := IsCdRom(RootOfProgram(AProgramPath));
end;

end.
