{******************************************************************************}
{                                                                              }
{  DelphiDoom: definitions library - the factory: the composition root         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Definitions.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Definitions.Types, DelphiDoom.Definitions.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the library</summary>
  TDefinitionsFactory = class
  public
    /// <param name="ALog">May be nil</param>
    class function CreateAnimDefsParser(const ACatalog: IDefAnimNameCatalog;
      const ALog: ILog): IDefAnimDefsParser; static;
    /// <param name="AHasSound">True for the lump of Strife (24 bytes an entry)</param>
    class function CreateSwitchLumpReader(AHasSound: Boolean): IDefSwitchLumpReader; static;
    /// <param name="ALog">May be nil</param>
    class function CreateSwitchSelector(const ATextures: IDefTextureLookup;
      const ALog: ILog): IDefSwitchSelector; static;
    /// <summary>The table that was compiled in the game, without the terminator</summary>
    class function CreateSwitchTable(AGame: TDefGame): TArray<TDefSwitchPair>; static;
    class function CreateTerrainTable(AGame: TDefGame): IDefTerrainTable; static;
    /// <summary>A list of the caller (tests, tools)</summary>
    class function CreateTerrainTableFrom(const AEntries: TArray<TDefTerrainEntry>): IDefTerrainTable; static;
  end;

implementation

uses
  DelphiDoom.Definitions.AnimDefsParser, DelphiDoom.Definitions.SwitchLumpReader,
  DelphiDoom.Definitions.SwitchSelector, DelphiDoom.Definitions.SwitchTables,
  DelphiDoom.Definitions.TerrainTable, DelphiDoom.Definitions.TerrainTables;

{ TDefinitionsFactory }

class function TDefinitionsFactory.CreateAnimDefsParser(const ACatalog: IDefAnimNameCatalog;
  const ALog: ILog): IDefAnimDefsParser;
begin
  Result := TAnimDefsParser.Create(ACatalog, ALog);
end;

class function TDefinitionsFactory.CreateSwitchLumpReader(AHasSound: Boolean): IDefSwitchLumpReader;
begin
  Result := TSwitchLumpReader.Create(AHasSound);
end;

class function TDefinitionsFactory.CreateSwitchSelector(const ATextures: IDefTextureLookup;
  const ALog: ILog): IDefSwitchSelector;
begin
  Result := TSwitchSelector.Create(ATextures, ALog);
end;

class function TDefinitionsFactory.CreateSwitchTable(AGame: TDefGame): TArray<TDefSwitchPair>;
begin
  Result := TSwitchTables.ForGame(AGame);
end;

class function TDefinitionsFactory.CreateTerrainTable(AGame: TDefGame): IDefTerrainTable;
begin
  Result := TTerrainTable.Create(TTerrainTables.ForGame(AGame));
end;

class function TDefinitionsFactory.CreateTerrainTableFrom(
  const AEntries: TArray<TDefTerrainEntry>): IDefTerrainTable;
begin
  Result := TTerrainTable.Create(AEntries);
end;

end.
