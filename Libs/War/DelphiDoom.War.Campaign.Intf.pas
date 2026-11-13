{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contracts of the campaigns                        }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Campaign.Intf;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Types;

type
  /// <summary>The table of the campaign maps</summary>
  IWarCampaigns = interface
    ['{6D1F8A52-0C3B-47E9-9B25-F4A7E1C3D860}']
    /// <summary>
    ///   wcamp_getCampaignData; a type that is not in the table gets the data of the custom map (the original
    ///   used the type as an index into the table, 141, and read past its end)
    /// </summary>
    function GetData(AMapType: Integer): TWarCampaignMapData;
    /// <summary>wcamp_tryGetMapType: the map of a mission (1..12) of the humans or the orcs</summary>
    function TryGetMapType(ARace: TWarRace; AMission: Integer; out AMapType: Integer): Boolean;
    /// <summary>wmap_getCampaignMapTypeByLevelInfoIndex: the type of the map that is the level info AIndex</summary>
    function MapTypeOfLevel(AIndex: Integer): Integer;
    /// <summary>True for the two missions after which the demo ends (updateObjectives)</summary>
    function IsDemoLastLevel(AIndex: Integer): Boolean;
  end;

  /// <summary>What the objectives need to know of the game in course (wu_* of the original)</summary>
  IWarCensus = interface
    ['{B27E4C90-5A18-4D63-8F0A-1E9C6B3D7A45}']
    function GetPlayerRace(APlayer: Integer): TWarRace;
    /// <summary>wu_getNumberOfBuildingsOfType with alreadyBuilt = true</summary>
    function GetBuildingsOfType(APlayer: Integer; AUnitType: Byte): Integer;
    /// <summary>wu_getTotalNumberOfUnits</summary>
    function GetTotalUnits(APlayer: Integer): Integer;
    /// <summary>wu_getTotalNumberOfDudes: the fighters, without summoned creatures and skeletons</summary>
    function GetTotalDudes(APlayer: Integer): Integer;
  end;

  /// <summary>The condition of victory and defeat of the maps</summary>
  IWarObjectives = interface
    ['{4E9A2D07-8B61-4C35-A0F2-7D5C1B8E3946}']
    /// <summary>
    ///   The three wcamp_check*Objectives; wlrNone for the maps that have no condition. Player 0 is the one who plays,
    ///   player 1 the enemy
    /// </summary>
    function Check(AMapType: Integer; const ACensus: IWarCensus): TWarLevelResult;
  end;

implementation

end.
