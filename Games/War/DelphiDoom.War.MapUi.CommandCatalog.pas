{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the tables say about a command               }
{                                                                              }
{  Port of war1 (acoto87/war1), wu_getCommandBaseData, wu_getCommandMapping,   }
{  wu_getCommandMappingFromUnitType and FromUpgradeType of war_units.c,        }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Games\War\LICENSE-war1.txt). This is an altered version, not the original.  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.CommandCatalog;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.MapUi.CommandData.Data;

type
  /// <summary>
  ///   The tables of the commands (the generated data of the original) with the searches the original does on them: the
  ///   data of a command by its number, the unit, upgrade or spell that it is for, the command that trains a unit or
  ///   researches an upgrade, and the portraits. Nothing is kept: every call is a lookup
  /// </summary>
  TWarCommandCatalog = class sealed
  public
    /// <summary>wu_getCommandBaseData; EWarException for a number that is not a command</summary>
    class function Base(ACommandType: Integer): TWarCommandBase; static;
    /// <summary>wu_getCommandMapping: the type that the command is for (unit, upgrade or spell); EWarException if it has none</summary>
    class function MappedType(ACommandType: Integer): Integer; static;
    /// <summary>
    ///   wu_getCommandMappingFromUnitType: the first train or build command of the table for a unit type (the first 30 rows);
    ///   -1 if none (the original stops on an assert)
    /// </summary>
    class function CommandOfUnit(AUnitType: Integer): Integer; static;
    /// <summary>
    ///   wu_getCommandMappingFromUpgradeType: the first upgrade command of the table for an upgrade (the rows 30 to 49: the
    ///   shield of the humans is before the one of the orcs); -1 if none
    /// </summary>
    class function CommandOfUpgrade(AUpgradeType: Integer): Integer; static;
    /// <summary>The frame of the record 361 for a unit type: unitData->portraitFrameIndex (0 for a type the table does not have)</summary>
    class function PortraitOfUnit(AUnitType: Integer): Integer; static;
    /// <summary>upgradeData->frameIndices[level]</summary>
    class function UpgradeFrame(AUpgradeType, ALevel: Integer): Integer; static;
    /// <summary>spell->portraitFrameIndex</summary>
    class function SpellPortrait(ASpellType: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.MapUi.UnitNames.Data;

const
  SWarCommandNotInTables = 'The command %d has no data in the tables of the original';

{ TWarCommandCatalog }

class function TWarCommandCatalog.Base(ACommandType: Integer): TWarCommandBase;
begin
  if (ACommandType < 0) or (ACommandType > High(WAR_COMMAND_BASE)) then
    raise EWarException.CreateFmt(SWarCommandNotInTables, [ACommandType]);
  Result := WAR_COMMAND_BASE[ACommandType];
end;

class function TWarCommandCatalog.MappedType(ACommandType: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(WAR_COMMAND_MAPPINGS) do
    if WAR_COMMAND_MAPPINGS[LIndex].CommandType = ACommandType then
      Exit(WAR_COMMAND_MAPPINGS[LIndex].MappedType);
  raise EWarException.CreateFmt(SWarCommandNotInTables, [ACommandType]);
end;

class function TWarCommandCatalog.CommandOfUnit(AUnitType: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 29 do
    if WAR_COMMAND_MAPPINGS[LIndex].MappedType = AUnitType then
      Exit(WAR_COMMAND_MAPPINGS[LIndex].CommandType);
  Result := -1;
end;

class function TWarCommandCatalog.CommandOfUpgrade(AUpgradeType: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 30 to 49 do
    if WAR_COMMAND_MAPPINGS[LIndex].MappedType = AUpgradeType then
      Exit(WAR_COMMAND_MAPPINGS[LIndex].CommandType);
  Result := -1;
end;

class function TWarCommandCatalog.PortraitOfUnit(AUnitType: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(WAR_UNIT_NAMES) do
    if WAR_UNIT_NAMES[LIndex].UnitType = AUnitType then
      Exit(WAR_UNIT_NAMES[LIndex].Portrait);
  Result := 0;
end;

class function TWarCommandCatalog.UpgradeFrame(AUpgradeType, ALevel: Integer): Integer;
begin
  if ALevel = 0 then
    Result := WAR_UPGRADE_FRAMES[AUpgradeType].Frame1
  else
    Result := WAR_UPGRADE_FRAMES[AUpgradeType].Frame2;
end;

class function TWarCommandCatalog.SpellPortrait(ASpellType: Integer): Integer;
begin
  Result := WAR_SPELL_PORTRAITS[ASpellType];
end;

end.
