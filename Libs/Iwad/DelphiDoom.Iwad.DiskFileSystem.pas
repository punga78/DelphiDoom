{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the files of the disk                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.DiskFileSystem;

interface

uses
  DelphiDoom.Iwad.Intf;

type
  /// <summary>The disk of the computer</summary>
  TIwadDiskFileSystem = class(TInterfacedObject, IIwadFileSystem)
  public
    function FileExists(const APath: string): Boolean;
    function ExpandPath(const APath: string): string;
  end;

implementation

uses
  System.SysUtils;

{ TIwadDiskFileSystem }

function TIwadDiskFileSystem.FileExists(const APath: string): Boolean;
begin
  // qualified: inside the class the name is this method
  Result := System.SysUtils.FileExists(APath);
end;

function TIwadDiskFileSystem.ExpandPath(const APath: string): string;
begin
  Result := ExpandFileName(APath);
end;

end.
