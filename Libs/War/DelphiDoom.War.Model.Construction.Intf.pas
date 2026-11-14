{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what building and training ask of the game         }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Construction.Intf;

interface

type
  /// <summary>
  ///   The things around the model that the states of building, repairing, training and collapsing need: the images
  ///   (how many frames a building under construction has), the sounds and the fog of war. The calls are rare (once per
  ///   purchase, once per building), never per unit and tic, so an interface is fine
  /// </summary>
  IWarConstructionHost = interface
    ['{A4C7E193-5D28-4B60-9E1F-83B6D2A05C47}']
    /// <summary>
    ///   The frames of the sprite that a unit of the type has when it is made (the original reads them from the resource
    ///   of the image of DATA.WAR): the model only keeps the number
    /// </summary>
    function UnitFrames(AUnitType: Integer): Integer;
    /// <summary>The frames of the image of a building of the type while it is built (buildingsData[type].buildingResource)</summary>
    function ConstructionFrames(AUnitType: Integer): Integer;
    /// <summary>wa_createAudio: a sound by its id (WAR_SOUND_* of the Construction.Types)</summary>
    procedure PlaySound(AAudioId: Integer);
    /// <summary>wa_createAudioRandom: one of the sounds from the first id to the last</summary>
    procedure PlayRandomSound(AFromId, AToId: Integer);
    /// <summary>wa_playAcknowledgementSound: the worker or the unit answers the order of the player</summary>
    procedure Acknowledge(APlayer: Integer);
    /// <summary>not wmap_isTileUnknown: the tile is not in the black of the fog of war (always true without fog)</summary>
    function IsTileKnown(ATileX, ATileY: Integer): Boolean;
  end;

  /// <summary>
  ///   What the model asks of the grid of the tiles besides marking and freeing them (IWarOccupancy): whether a tile is
  ///   free and the nearest free one (wpath_isEmpty and wpath_findEmptyTile). A grid that can answer implements it
  ///   together with IWarOccupancy; without it every tile is free and a unit appears where it was
  /// </summary>
  IWarOccupancyProbe = interface
    ['{5E92B7D4-0C3A-4F18-A6D9-17E4C8B3F052}']
    /// <summary>wpath_isEmpty</summary>
    function IsEmpty(ATileX, ATileY: Integer): Boolean;
    /// <summary>
    ///   wpath_findEmptyTile: the first empty tile in a breadth first search that starts at the tile (the tile itself if
    ///   it is empty, or if the whole map is full)
    /// </summary>
    procedure FindEmptyTile(ATileX, ATileY: Integer; out AFoundX, AFoundY: Integer);
  end;

implementation

end.
