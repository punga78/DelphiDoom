{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contract of the graphic resources                 }
{                                                                              }
{  Port of war1 (acoto87/war1), war_resources.h, (c) 2019 Alejandro Coto       }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an         }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Graphics.Intf;

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types;

type
  /// <summary>
  ///   The graphic records of DATA.WAR decoded to pixels. Every call decodes the record again (the original
  ///   decoded them all when the game started); the type the catalog gives to the record must be the one asked
  /// </summary>
  IWarGraphics = interface
    ['{7D2A4C19-3E85-4B06-9F71-C58A0E2D6B34}']
    /// <summary>
    ///   A palette record (wres_loadPaletteResource): 768 bytes, each of the file multiplied by 4, with the
    ///   corrections the original makes to the palettes 255 and 217
    /// </summary>
    function GetPalette(AIndex: Integer): TBytes;
    /// <summary>The palette of an image, sprite, cursor or tiles (wres_getPalette): the palette AIndex1 completed by AIndex2; 0 = none</summary>
    function ComposePalette(AIndex1, AIndex2: Integer): TBytes;
    /// <summary>An image record with the palettes of the catalog applied (wres_loadImageResource)</summary>
    function GetImage(AIndex: Integer): TWarImage;
    /// <summary>A sprite record with its frames (wres_loadSpriteResource)</summary>
    function GetSprite(AIndex: Integer): TWarSprite;
    /// <summary>A cursor record (wres_loadCursor)</summary>
    function GetCursor(AIndex: Integer): TWarCursor;
    /// <summary>A tiles record as it is, with its palettes (wres_loadTiles)</summary>
    function GetTiles(AIndex: Integer): TWarTiles;
    /// <summary>The image of a tileset record, made from the tiles record the catalog points to (wres_loadTileset)</summary>
    function GetTileset(AIndex: Integer): TWarTileset;
  end;

implementation

end.
