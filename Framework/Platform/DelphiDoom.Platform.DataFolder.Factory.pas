{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the factory of the folder of the data         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.DataFolder.Factory;

interface

uses
  DelphiDoom.Platform.DataFolder.Intf;

type
  /// <summary>The only place that knows the classes behind IDataFolderLocator and IDataFolderProbe</summary>
  TDataFolderFactory = class
  public
    /// <summary>The locator that looks at the disk</summary>
    class function CreateLocator: IDataFolderLocator; static;
    /// <summary>The locator on a probe given by the caller (a fake in the tests)</summary>
    class function CreateLocatorOn(const AProbe: IDataFolderProbe): IDataFolderLocator; static;
  end;

implementation

uses
  DelphiDoom.Platform.DataFolder, DelphiDoom.Platform.DataFolder.Disk;

class function TDataFolderFactory.CreateLocator: IDataFolderLocator;
begin
  Result := TDataFolderLocator.Create(TDiskDataFolderProbe.Create);
end;

class function TDataFolderFactory.CreateLocatorOn(const AProbe: IDataFolderProbe): IDataFolderLocator;
begin
  Result := TDataFolderLocator.Create(AProbe);
end;

end.
