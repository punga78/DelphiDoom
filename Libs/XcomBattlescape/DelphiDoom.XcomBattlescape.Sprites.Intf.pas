{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape drawing library - where the sprites come from   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.Sprites.Intf;

interface

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet;

type
  /// <summary>
  ///   The surface sets of the battlescape (Mod::getSurfaceSet): the units, the objects in hand and on the floor,
  ///   the cursor, the smoke, the explosions; and the sprites of the parts of the terrain (the PCK of a MCD file)
  /// </summary>
  IXcomBattleSprites = interface
    ['{5E2B7C19-3D84-4A6F-B0C1-8F9A21D4E763}']
    /// <summary>getSurfaceSet(name): nil when the mod has no such set. The set belongs to the provider</summary>
    function SurfaceSet(const AName: string): TXcomSurfaceSet;
    /// <summary>The frame of the sprites of a terrain file (name of the MCD, without extension), or nil</summary>
    function TerrainFrame(const ADataSetName: string; AIndex: Integer): TXcomSurface;
  end;

implementation

end.
