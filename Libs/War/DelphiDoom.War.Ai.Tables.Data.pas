{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - tables of the computer player (GENERATED)         }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.c and war_units.c, (c) 2019 Alejandro    }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an     }
{  altered version, not the original.                                          }
{                                                                              }
{  Written by Tools\Verifica\194\Make-WarAiTables.ps1 from the output of the   }
{  original C code (Tests\Data\War\ai.tables.golden.txt): do not edit by hand  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.Tables.Data;

interface

uses
  DelphiDoom.War.Ai.Types;

const
  /// <summary>The number of commands of the script that wai_initAI gives to a player</summary>
  WAR_AI_SCRIPT_LENGTH = 6;

  /// <summary>
  ///   The script of wai_initAI by race (0 neutral, 1 humans, 2 orcs): the commands the original makes, in order (the unit types
  ///   are already those of the race)
  /// </summary>
  WAR_AI_SCRIPT: array[0..2, 0..5] of TWarAiScriptEntry = (
    ((Kind: 0; UnitType: 40; Count: 1), (Kind: 1; UnitType: 40; Count: 1), (Kind: 0; UnitType: 2; Count: 2), (Kind: 1; UnitType: 2; Count: 2), (Kind: 0; UnitType: 2; Count: 2), (Kind: 1; UnitType: 2; Count: 4)),
    ((Kind: 0; UnitType: 40; Count: 1), (Kind: 1; UnitType: 40; Count: 1), (Kind: 0; UnitType: 2; Count: 2), (Kind: 1; UnitType: 2; Count: 2), (Kind: 0; UnitType: 2; Count: 2), (Kind: 1; UnitType: 2; Count: 4)),
    ((Kind: 0; UnitType: 41; Count: 1), (Kind: 1; UnitType: 41; Count: 1), (Kind: 0; UnitType: 3; Count: 2), (Kind: 1; UnitType: 3; Count: 2), (Kind: 0; UnitType: 3; Count: 2), (Kind: 1; UnitType: 3; Count: 4)));

  /// <summary>wu_getProducerUnitOfType by unit type: the building that trains the unit, -1 for a type nothing trains</summary>
  WAR_UNIT_PRODUCERS: array[0..53] of Integer = (
    34, 35, 40, 41, 34, 35, 34, 35, 34, 35, 38, 39, 36, 37, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1);

implementation

end.
