{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the commands ask the map                     }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.Intf;

interface

type
  /// <summary>
  ///   What an order given on a point of the map has to know: who stands on a tile and what the player sees of it. The
  ///   calls are one per order, never per tic. TWarGridCommandMap answers from the grid of the map (and from its fog,
  ///   if it has one)
  /// </summary>
  IWarCommandMap = interface
    ['{9B4E27D1-C3A8-4F50-8E16-52D7A09B63C4}']
    /// <summary>wpath_getTileEntityId: the id of the entity that occupies the tile, 0 if none or outside the map</summary>
    function EntityIdAt(ATileX, ATileY: Integer): Word;
    /// <summary>wmap_isTileVisible, wmap_isTileFog and wmap_isTileUnknown</summary>
    function IsTileVisible(ATileX, ATileY: Integer): Boolean;
    function IsTileFog(ATileX, ATileY: Integer): Boolean;
    function IsTileUnknown(ATileX, ATileY: Integer): Boolean;
    /// <summary>wmap_isUnitUnknown: every tile of the rectangle is unknown</summary>
    function IsAreaUnknown(ATileX, ATileY, AWidth, AHeight: Integer): Boolean;
    /// <summary>wmap_isUnitPartiallyVisible: a tile of the rectangle is visible</summary>
    function IsAreaPartiallyVisible(ATileX, ATileY, AWidth, AHeight: Integer): Boolean;
  end;

implementation

end.
