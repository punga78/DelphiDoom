{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - what the saved battle asks of the     }
{  pathfinding and of the tile engine                                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Services.Intf;

interface

uses
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Model;

type
  /// <summary>
  ///   The part of Pathfinding that SavedBattleGame uses (the pathfinding holds the saved battle, so the saved
  ///   battle talks to it through this interface)
  /// </summary>
  IXcomBattlePathfinder = interface
    ['{91C3E7A0-58D2-4A1B-B6F4-0D2E8A735C19}']
    procedure SetUnit(const AUnit: TXcomBattleUnit);
    function IsBlocked(const AStart, AEnd: TXcomTile; ADirection: Integer; const ATarget: TXcomBattleUnit)
      : Boolean;
  end;

  /// <summary>The part of TileEngine that SavedBattleGame uses</summary>
  IXcomBattleTileEngine = interface
    ['{C45E0B8D-1A72-4E39-8F60-B3D17A9E4C25}']
    procedure CalculateSunShading;
    procedure CalculateTerrainLighting;
    procedure CalculateUnitLighting;
    procedure RecalculateFov;
    procedure CalculateFov(const AUnit: TXcomBattleUnit);
    /// <summary>horizontalBlockage(startTile, endTile, type)</summary>
    function HorizontalBlockage(const AStart, AEnd: TXcomTile; ADamageType: Integer): Integer;
    procedure ApplyGravity(const ATile: TXcomTile);
  end;

  /// <summary>
  ///   What BattlescapeGenerator asks of the tile engine besides the light and the field of view: the window a unit
  ///   faces, distances and explosions (crashed UFO power sources)
  /// </summary>
  IXcomGeneratorTileEngine = interface(IXcomBattleTileEngine)
    ['{5E2A7C90-3B14-4D68-A0F7-18C9D6E4B253}']
    function FaceWindow(const APosition: TXcomPosition): Integer;
    function Distance(const AFirst, ASecond: TXcomPosition): Integer;
    procedure Explode(const ACenter: TXcomPosition; APower, ADamageType, AMaxRadius: Integer;
      const AUnit: TXcomBattleUnit = nil);
    function CheckForTerrainExplosions: TXcomTile;
  end;

implementation

end.
