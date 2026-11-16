{******************************************************************************}
{                                                                              }
{  DelphiDoom: tools core library - the backup copy of a file                   }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.FileBackup;

interface

uses
  DelphiDoom.Tools.Intf;

type
  /// <summary>The old BackupFile of the tools: the file is copied to the same name plus "_bak"</summary>
  TToolFileBackup = class(TInterfacedObject, IToolFileBackup)
  strict private
    FFileSystem: IToolFileSystem;
  public
    constructor Create(const AFileSystem: IToolFileSystem);
    function Backup(const APath: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Tools.Types;

{ TToolFileBackup }

constructor TToolFileBackup.Create(const AFileSystem: IToolFileSystem);
begin
  inherited Create;
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  FFileSystem := AFileSystem;
end;

function TToolFileBackup.Backup(const APath: string): Boolean;
begin
  if not FFileSystem.FileExists(APath) then
    Exit(True);
  Result := FFileSystem.TryCopyFile(APath, APath + TOOLS_BACKUP_SUFFIX);
end;

end.
