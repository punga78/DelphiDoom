{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contracts of the world                       }
{  Port of xGreed (Jim Valavanis): r_public.pas, utils.pas                      }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.World.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

const
  /// <summary>MAXDOORS</summary>
  GREED_MAX_DOORS = 32;
  /// <summary>MAXSPAWNAREAS</summary>
  GREED_MAX_SPAWN_AREAS = 96;

  // ---- the flags of the tiles (mapflags) ----

  GREED_FL_DOOR = 128;
  GREED_FL_FLOOR = 7;
  GREED_FL_CEILING = 56;
  GREED_FLS_FLOOR = 0;
  GREED_FLS_CEILING = 3;
  /// <summary>The shape of a floor or ceiling of a tile</summary>
  GREED_POLY_FLAT = 0;
  GREED_POLY_SLOPE = 1;
  GREED_POLY_UL_TO_LR = 2;
  GREED_POLY_UR_TO_LL = 3;

type
  /// <summary>orientation_t</summary>
  TGreedDoorOrientation = (gdoHorizontal, gdoVertical, gdoHorizontal2, gdoVertical2);

  /// <summary>doorobj_t: a door of the map</summary>
  TGreedDoor = record
    TileX: Integer;
    TileY: Integer;
    Open: Boolean;
    Opening: Boolean;
    Closing: Boolean;
    Blocked: Boolean;
    Bumpable: Boolean;
    Size: Integer;
    Timer: Integer;
    Locks: Byte;
    Orientation: TGreedDoorOrientation;
    /// <summary>The picture has masked areas</summary>
    Transparent: Boolean;
    /// <summary>Lump of the picture, from the first door</summary>
    Pic: Integer;
    /// <summary>The floor height, in general</summary>
    Height: Integer;
    /// <summary>0 (open) .. 64 * FRACUNIT (closed)</summary>
    Position: TGreedFixed;
  end;

  /// <summary>spawnarea_t: where monsters are made (a generator, or an area that waits)</summary>
  TGreedSpawnArea = packed record
    MapSpot: Integer;
    MapX: TGreedFixed;
    MapY: TGreedFixed;
    Kind: Integer;
    Time: Integer;
  end;

  PGreedDoor = ^TGreedDoor;
  /// <summary>The bytes of a plane, one for each tile (y * 64 + x)</summary>
  TGreedTiles = array[0..GREED_MAP_TILES - 1] of Byte;
  PGreedTiles = ^TGreedTiles;
  /// <summary>doorlist</summary>
  TGreedDoorList = array[0..GREED_MAX_DOORS - 1] of TGreedDoor;
  PGreedDoorList = ^TGreedDoorList;

  /// <summary>
  ///   The memory of a world, for the code that reads or writes it for every tile of every sprite at every tic
  ///   (the logic of the sprites): the planes, the flags of the tiles and the list of the doors as the original
  ///   keeps them in its global arrays, without a call for each byte. IGreedWorld.View gives it once; the pointers
  ///   stay valid, and show what the world holds at any moment, as long as the world lives (Load does not move
  ///   the planes). Value and Flags read a tile outside the map as 0, as IGreedWorld.GetValue and GetMapFlags do;
  ///   who writes through Planes, MapFlags or Doors checks the tile and the number of the door itself
  /// </summary>
  TGreedWorldView = record
    Planes: array[TGreedPlane] of PGreedTiles;
    MapFlags: PGreedTiles;
    Doors: PGreedDoorList;
    /// <summary>How many doors of Doors are in use (it changes when a door is added)</summary>
    DoorCount: PInteger;
    /// <summary>The byte of a plane at a tile; 0 outside 0..4095</summary>
    function Value(APlane: TGreedPlane; ASpot: Integer): Byte; inline;
    /// <summary>mapflags of a tile; 0 outside the map</summary>
    function Flags(ASpot: Integer): Byte; inline;
  end;
  PGreedWorldView = ^TGreedWorldView;

  /// <summary>
  ///   The level that is being played, as the original keeps it in the globals of the map: the 18 planes (one byte for
  ///   each tile of 64 x 64), the flags of the tiles (mapflags: the shape of the floor and of the ceiling, the doors)
  ///   and the lists of doors and of spawn areas. A tile outside the map reads as 0 (the original read the memory
  ///   that came after the array)
  /// </summary>
  IGreedWorld = interface
    ['{2C8D47E9-B1A5-4F30-96D2-0E5B73A8C614}']
    /// <summary>
    ///   LoadNewMap without the textures: clears the lists (RF_ClearWorld), copies the planes, clears the flags,
    ///   turns a floordef or ceilingdef of 0 into 56 and activates the slopes (ActivateSlopes)
    /// </summary>
    procedure Load(const AMap: IGreedMap);
    /// <summary>The byte of a plane at a tile (y * 64 + x); 0 outside 0..4095</summary>
    function GetValue(APlane: TGreedPlane; ASpot: Integer): Byte;
    procedure SetValue(APlane: TGreedPlane; ASpot: Integer; AValue: Byte);
    /// <summary>Copies the 4096 bytes of a plane to ADest (the renderer reads a plane at a time)</summary>
    procedure CopyPlane(APlane: TGreedPlane; ADest: PByte);
    /// <summary>Copies the 4096 flags of the tiles (mapflags) to ADest</summary>
    procedure CopyMapFlags(ADest: PByte);
    /// <summary>mapflags of a tile; 0 outside the map</summary>
    function GetMapFlags(ASpot: Integer): Byte;
    procedure SetMapFlags(ASpot: Integer; AValue: Byte);
    /// <summary>
    ///   RF_GetDoor: a new door on the tile, which gets the door flag. EGreedException if there are 32 doors
    /// </summary>
    function AddDoor(ATileX, ATileY: Integer): Integer;
    function GetDoorCount: Integer;
    function GetDoor(AIndex: Integer): TGreedDoor;
    procedure SetDoor(AIndex: Integer; const ADoor: TGreedDoor);
    /// <summary>RF_GetSpawnArea: a new area, all zero. EGreedException if there are 96</summary>
    function AddSpawnArea: Integer;
    function GetSpawnAreaCount: Integer;
    function GetSpawnArea(AIndex: Integer): TGreedSpawnArea;
    procedure SetSpawnArea(AIndex: Integer; const AArea: TGreedSpawnArea);
    /// <summary>
    ///   The memory of the planes, of the flags and of the doors, for the loops over tiles and sprites: asked once
    ///   (when a class is made, or at the start of a tic), never for each tile. Valid as long as the world lives
    /// </summary>
    function View: PGreedWorldView;
    property DoorCount: Integer read GetDoorCount;
    property SpawnAreaCount: Integer read GetSpawnAreaCount;
  end;

implementation

{ TGreedWorldView }

function TGreedWorldView.Value(APlane: TGreedPlane; ASpot: Integer): Byte;
begin
  // one unsigned comparison for both ends of the map
  if Cardinal(ASpot) < GREED_MAP_TILES then
    Result := Planes[APlane]^[ASpot]
  else
    Result := 0;
end;

function TGreedWorldView.Flags(ASpot: Integer): Byte;
begin
  if Cardinal(ASpot) < GREED_MAP_TILES then
    Result := MapFlags^[ASpot]
  else
    Result := 0;
end;

end.
