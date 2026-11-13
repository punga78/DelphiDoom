{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contracts of the game map                         }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Intf;

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types;

type
  /// <summary>What the game knows of each unit type: sizes, statistics and the kind of unit</summary>
  IWarUnitCatalog = interface
    ['{5E1B7A94-2C63-4D08-B9F5-0A7D3E6C1F82}']
    /// <summary>wu_getUnitData: False if the type is not in the table</summary>
    function TryGetData(AUnitType: Integer; out AData: TWarUnitData): Boolean;
    /// <summary>wu_isDudeUnitType: the units that move (types 0..28)</summary>
    function IsDudeType(AUnitType: Integer): Boolean;
    /// <summary>wu_isBuildingUnitType: the buildings and the gold mine (types 32..50)</summary>
    function IsBuildingType(AUnitType: Integer): Boolean;
    /// <summary>wu_isSummonUnitType: spider, scorpion, the dead, daemon and water elemental</summary>
    function IsSummonType(AUnitType: Integer): Boolean;
    /// <summary>wu_isCorpseUnitType: the two corpses</summary>
    function IsCorpseType(AUnitType: Integer): Boolean;
    /// <summary>wu_getUnitSightRange: the sight of a building or of a unit; EWarException if the type is not in the tables</summary>
    function SightRange(AUnitType: Integer): Integer;
    /// <summary>
    ///   we_createUnit (the data, not the entity): the unit with its size from the table and, for the units that
    ///   move or the buildings, its hit points, mana, armor and weapon. EWarException if the type is not in the
    ///   tables (the original stops on an assert)
    /// </summary>
    function CreateUnit(AId: Word; AUnitType, ATileX, ATileY: Integer; APlayer: Byte; AResourceKind: TWarResourceKind;
      AAmount: Cardinal): TWarMapUnit;
  end;

  /// <summary>Where the game map writes the tile of the map that a change makes different (wmap_setMapTileIndex)</summary>
  IWarTilePainter = interface
    ['{A3D90E57-6B14-4C2F-8E71-F5B2C08D4A36}']
    /// <summary>Sets the tile of the visual map in the cell (X, Y) and updates its pixel of the minimap</summary>
    procedure SetTileIndex(AX, AY, ATile: Integer);
    /// <summary>wmap_getMapTileIndex</summary>
    function GetTileIndex(AX, AY: Integer): Integer;
    /// <summary>The 64 x 64 tiles of the visual map, row by row (a copy)</summary>
    function GetVisual: TArray<Word>;
  end;

implementation

end.
