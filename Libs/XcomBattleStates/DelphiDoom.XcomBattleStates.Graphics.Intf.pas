{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the pictures of the battle     }
{  (what Mod::loadBattlescapeResources loads: the screens of UFOGRAPH, the      }
{  sets of sprites, the palettes of the depths, the voxel data)                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.Graphics.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomBattlescape.Sprites.Intf;

type
  /// <summary>
  ///   The graphic resources of the battle, read the first time they are asked for. The surfaces and the sets are
  ///   the giver's: a state blits them and never frees them
  /// </summary>
  IXcomBattleGraphics = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000401}']
    /// <summary>The sets of sprites (PCK of UNITS, UFOGRAPH and TERRAIN, the DAT sets and the extra sprites of the rules)</summary>
    function Sprites: IXcomBattleSprites;
    /// <summary>Mod::getSurfaceSet; nil when the game has no such set</summary>
    function SurfaceSet(const AName: string): TXcomSurfaceSet;
    /// <summary>
    ///   Mod::getSurface for a screen of UFOGRAPH (TAC00.SCR, ICONS.PCK, UNIBORD.PCK, MAN_0F0.SPK...) or a single
    ///   extra sprite of the rules; nil when the game has none of that name
    /// </summary>
    function Surface(const AName: string): TXcomSurface;
    /// <summary>The palette PAL_BATTLESCAPE (depth 0) or PAL_BATTLESCAPE_n: 256 colors</summary>
    function Palette(ADepth: Integer): PXcomColor;
    /// <summary>Mod::getLUTs()->at(depth): the transparency tables of the palette of a depth; empty when it has none</summary>
    function Transparencies(ADepth: Integer): TBytes;
    /// <summary>
    ///   Mod::setPalette: the 256 colors of the state on screen become the palette of every surface and set, also of
    ///   those read later (a blit between surfaces of different palettes would map the colors)
    /// </summary>
    procedure SetPalette(AColors: PXcomColor);
    /// <summary>Mod::getVoxelData: LOFTEMPS.DAT</summary>
    function VoxelData: TArray<Word>;
  end;

implementation

end.
