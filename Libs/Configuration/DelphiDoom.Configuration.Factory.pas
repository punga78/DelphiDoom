{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - the factory: the composition root       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.Factory;

interface

uses
  System.SysUtils,
  DelphiDoom.Configuration.Types,
  DelphiDoom.Configuration.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the library</summary>
  TConfigurationFactory = class
  public
    class function CreateFormat: IConfigurationFormat; static;
    /// <summary>A row with a value; AAccess reaches its variable</summary>
    class function CreateItem(const AName: string; AKind: TConfigurationItemKind; ASetable: Byte;
      const ADefaults: TConfigurationDefaults;
      const AAccess: IConfigurationValueAccess): IConfigurationItem; static;
    /// <summary>A row that is the name of a group of the file</summary>
    class function CreateGroup(const AName: string): IConfigurationItem; static;
    class function CreateTable(const AItems: TArray<IConfigurationItem>): IConfigurationTable; static;
    class function CreateTableStore(const ATable: IConfigurationTable;
      const AFormat: IConfigurationFormat): IConfigurationTableStore; static;
  end;

implementation

uses
  DelphiDoom.Configuration.Format,
  DelphiDoom.Configuration.Item,
  DelphiDoom.Configuration.Table,
  DelphiDoom.Configuration.TableStore;

{ TConfigurationFactory }

class function TConfigurationFactory.CreateFormat: IConfigurationFormat;
begin
  Result := TConfigurationFormat.Create;
end;

class function TConfigurationFactory.CreateItem(const AName: string;
  AKind: TConfigurationItemKind; ASetable: Byte; const ADefaults: TConfigurationDefaults;
  const AAccess: IConfigurationValueAccess): IConfigurationItem;
begin
  Result := TConfigurationItem.Create(AName, AKind, ASetable, ADefaults, AAccess);
end;

class function TConfigurationFactory.CreateGroup(const AName: string): IConfigurationItem;
var
  LDefaults: TConfigurationDefaults;
begin
  LDefaults := Default(TConfigurationDefaults);
  Result := TConfigurationItem.Create(AName, cikGroup, CONFIGURATION_SET_NEVER, LDefaults, nil);
end;

class function TConfigurationFactory.CreateTable(
  const AItems: TArray<IConfigurationItem>): IConfigurationTable;
begin
  Result := TConfigurationTable.Create(AItems);
end;

class function TConfigurationFactory.CreateTableStore(const ATable: IConfigurationTable;
  const AFormat: IConfigurationFormat): IConfigurationTableStore;
begin
  Result := TConfigurationTableStore.Create(ATable, AFormat);
end;

end.
