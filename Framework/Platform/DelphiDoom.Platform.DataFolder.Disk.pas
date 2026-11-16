{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the folders of the data of a program on the   }
{  disk                                                                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.DataFolder.Disk;

interface

uses
  System.SysUtils, DelphiDoom.Platform.DataFolder.Intf;

type
  /// <summary>IDataFolderProbe on the disk</summary>
  TDiskDataFolderProbe = class(TInterfacedObject, IDataFolderProbe)
  strict private
    class function HasFile(const AFolder, AMask: string): Boolean; static;
  public
    function FolderExists(const AFolder: string): Boolean;
    function HasGameFiles(const AFolder: string): Boolean;
    function FullPath(const AFolder: string): string;
  end;

implementation

uses
  System.IOUtils;

const
  GAME_FILE_MASKS: array[0..4] of string = ('*.wad', '*.pk3', '*.swd', '*.ini', '*.dat');
  GAME_DATA_FOLDER = 'DATA';

class function TDiskDataFolderProbe.HasFile(const AFolder, AMask: string): Boolean;
var
  LFiles: TArray<string>;
begin
  LFiles := TDirectory.GetFiles(AFolder, AMask);
  Result := Length(LFiles) > 0;
end;

function TDiskDataFolderProbe.FolderExists(const AFolder: string): Boolean;
begin
  Result := TDirectory.Exists(AFolder);
end;

function TDiskDataFolderProbe.HasGameFiles(const AFolder: string): Boolean;
var
  LMask: string;
begin
  Result := False;
  if not TDirectory.Exists(AFolder) then
    Exit;
  if TDirectory.Exists(TPath.Combine(AFolder, GAME_DATA_FOLDER)) then
    Exit(True);
  for LMask in GAME_FILE_MASKS do
    if HasFile(AFolder, LMask) then
      Exit(True);
end;

function TDiskDataFolderProbe.FullPath(const AFolder: string): string;
begin
  Result := ExpandFileName(AFolder);
end;

end.
