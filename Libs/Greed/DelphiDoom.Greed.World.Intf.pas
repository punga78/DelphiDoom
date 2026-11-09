{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contracts of the world                       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): r_public.pas, utils.pas     }
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
    property DoorCount: Integer read GetDoorCount;
    property SpawnAreaCount: Integer read GetSpawnAreaCount;
  end;

implementation

end.
