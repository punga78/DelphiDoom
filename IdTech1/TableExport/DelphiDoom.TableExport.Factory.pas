{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - the factory: the composition root         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.Factory;

interface

uses
  DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf, DelphiDoom.TableExport.Profile;

type
  /// <summary>The only place that knows the classes behind the TableExport contracts</summary>
  TTableExportFactory = class
  public
    class function CreateDehWriter(AGame: TExportGame; const AThings: IExportThingSource;
      const AStates: IExportStateSource; const AWeapons: IExportWeaponSource;
      const ASettings: IExportSettingsSource; const AFlags: IExportFlagNames;
      const ALookups: IExportLookups): IExportDehWriter; static;
    class function CreateCsvWriter(const AStates: IExportStateSource;
      const AEnums: IExportEnumNames): IExportCsvWriter; static;
    class function CreateActorDefWriter(const AThings: IExportThingSource;
      const AStates: IExportStateSource; const AEnums: IExportEnumNames; const AFlags: IExportFlagNames;
      const ALookups: IExportLookups): IExportActorDefWriter; static;
    class function CreateWeaponDefWriter(AGame: TExportGame; const AWeapons: IExportWeaponSource;
      const AStates: IExportStateSource; const AEnums: IExportEnumNames;
      const AFlags: IExportFlagNames): IExportWeaponDefWriter; static;
    class function CreateStateOwnersWriter(const AStates: IExportStateSource;
      const ALookups: IExportLookups): IExportStateOwnersWriter; static;
    /// <param name="ABuiltInThings">The table before any patch; nil to use AThings</param>
    class function CreatePascalWriter(AGame: TExportGame; const AThings, ABuiltInThings: IExportThingSource;
      const AStates: IExportStateSource; const AEnums: IExportEnumNames; const AFlags: IExportFlagNames;
      const ALookups: IExportLookups): IExportPascalWriter; static;
  end;

implementation

uses
  DelphiDoom.TableExport.Profiles, DelphiDoom.TableExport.DehWriter, DelphiDoom.TableExport.CsvWriter,
  DelphiDoom.TableExport.ActorDefWriter, DelphiDoom.TableExport.WeaponDefWriter,
  DelphiDoom.TableExport.StateOwnersWriter, DelphiDoom.TableExport.PascalWriter;

{ TTableExportFactory }

class function TTableExportFactory.CreateDehWriter(AGame: TExportGame; const AThings: IExportThingSource;
  const AStates: IExportStateSource; const AWeapons: IExportWeaponSource;
  const ASettings: IExportSettingsSource; const AFlags: IExportFlagNames;
  const ALookups: IExportLookups): IExportDehWriter;
begin
  Result := TExportDehWriter.Create(TExportProfiles.ForGame(AGame), AThings, AStates, AWeapons,
    ASettings, AFlags, ALookups);
end;

class function TTableExportFactory.CreateCsvWriter(const AStates: IExportStateSource;
  const AEnums: IExportEnumNames): IExportCsvWriter;
begin
  Result := TExportCsvWriter.Create(AStates, AEnums);
end;

class function TTableExportFactory.CreateActorDefWriter(const AThings: IExportThingSource;
  const AStates: IExportStateSource; const AEnums: IExportEnumNames; const AFlags: IExportFlagNames;
  const ALookups: IExportLookups): IExportActorDefWriter;
begin
  Result := TExportActorDefWriter.Create(AThings, AStates, AEnums, AFlags, ALookups);
end;

class function TTableExportFactory.CreateWeaponDefWriter(AGame: TExportGame;
  const AWeapons: IExportWeaponSource; const AStates: IExportStateSource; const AEnums: IExportEnumNames;
  const AFlags: IExportFlagNames): IExportWeaponDefWriter;
begin
  Result := TExportWeaponDefWriter.Create(TExportProfiles.ForGame(AGame), AWeapons, AStates, AEnums, AFlags);
end;

class function TTableExportFactory.CreateStateOwnersWriter(const AStates: IExportStateSource;
  const ALookups: IExportLookups): IExportStateOwnersWriter;
begin
  Result := TExportStateOwnersWriter.Create(AStates, ALookups);
end;

class function TTableExportFactory.CreatePascalWriter(AGame: TExportGame; const AThings,
  ABuiltInThings: IExportThingSource; const AStates: IExportStateSource; const AEnums: IExportEnumNames;
  const AFlags: IExportFlagNames; const ALookups: IExportLookups): IExportPascalWriter;
begin
  Result := TExportPascalWriter.Create(TExportProfiles.ForGame(AGame), AThings, ABuiltInThings, AStates,
    AEnums, AFlags, ALookups);
end;

end.
