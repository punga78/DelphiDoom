{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the factory of the files in several folders   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.FolderFiles.Factory;

interface

uses
  DelphiDoom.Platform.FolderFiles.Intf;

type
  /// <summary>
  ///   The only place that knows the class behind IFolderFiles. It is apart from TPlatformFactory so that a library
  ///   that only reads data files does not link the services of Windows
  /// </summary>
  TFolderFilesFactory = class
  public
    /// <summary>The files of the folders of the disk, the first folder first</summary>
    class function CreateFolderFiles(const AFolders: array of string): IFolderFiles; static;
    /// <summary>The same, but a name with a folder in it is never found (names that come from data)</summary>
    class function CreateFileNamesOnly(const AFolders: array of string): IFolderFiles; static;
  end;

implementation

uses
  DelphiDoom.Platform.FolderFiles;

class function TFolderFilesFactory.CreateFolderFiles(const AFolders: array of string): IFolderFiles;
begin
  Result := TFolderFiles.Create(AFolders, False);
end;

class function TFolderFilesFactory.CreateFileNamesOnly(const AFolders: array of string): IFolderFiles;
begin
  Result := TFolderFiles.Create(AFolders, True);
end;

end.
