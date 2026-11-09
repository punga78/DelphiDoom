{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the sprites and the elevators of a level         }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): r_public_h.pas              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Actor.Types;

interface

uses
  DelphiDoom.Greed.Types;

const
  /// <summary>MAXSPRITES</summary>
  GREED_MAX_SPRITES = 4096;
  /// <summary>MAXELEVATORS</summary>
  GREED_MAX_ELEVATORS = 128;

type
  /// <summary>rotate_t: how many pictures a sprite has for its angles</summary>
  TGreedRotate = (grOne, grFour, grEight);

  /// <summary>special_t</summary>
  TGreedSpecialType = (gstNone, gstNoClip, gstTransparent, gstMaxLight);

  /// <summary>elevtype</summary>
  TGreedElevatorType = (
    getNormal, getSwitchDown, getSwitchDown2, getTimed, getSwitchUp, getSwap, getSecret, getTriggered,
    getPressureHigh, getPressureLow);

  /// <summary>
  ///   scaleobj_t without the two list links (the pool keeps them): everything an object of the level has. The
  ///   field order is the one of the original
  /// </summary>
  TGreedSprite = record
    Animation: Integer;
    AnimationTime: Integer;
    MoveSpeed: TGreedFixed;
    /// <summary>zadj: the height above the floor</summary>
    ZAdjust: TGreedFixed;
    X, Y, Z: TGreedFixed;
    LastX: TGreedFixed;
    LastY: TGreedFixed;
    /// <summary>The lump is the first sprite plus BasePic plus the rotation</summary>
    BasePic: Integer;
    Rotate: TGreedRotate;
    Angle: Integer;
    Angle2: Integer;
    MoveSize: Integer;
    Active: Boolean;
    NoFalling: Boolean;
    Intelligence: Integer;
    Bullet: Integer;
    Enraged: Integer;
    MoveTime: Integer;
    ModeTime: Integer;
    ActionTime: Integer;
    ScanTime: Integer;
    FireTime: Integer;
    Heat: Integer;
    StartPic: Integer;
    MoveMode: Integer;
    StartSpot: Integer;
    Damage: Integer;
    HitPoints: Integer;
    /// <summary>typ: the id of the kind (S_MONSTER1 ...)</summary>
    Kind: Integer;
    SpawnId: Integer;
    Score: Integer;
    MaxMove: Integer;
    Regen: Integer;
    DeathEvent: Integer;
    Height: TGreedFixed;
    SpecialType: TGreedSpecialType;
    Scale: Integer;
    OldX, OldY, OldZ: Integer;
    OldAngle, OldAngle2, OldFloorZ: Integer;
    NewX, NewY, NewZ: Integer;
    NewAngle, NewAngle2, NewFloorZ: Integer;
    Grounded: Boolean;
  end;

  /// <summary>elevobj_t without the list links</summary>
  TGreedElevator = record
    Up: Boolean;
    Down: Boolean;
    Position: Integer;
    Position64: Integer;
    /// <summary>The time of the next movement</summary>
    Timer: Integer;
    /// <summary>floorheight of the tile at the start</summary>
    Floor: Integer;
    /// <summary>ceilingheight of the tile minus 64</summary>
    Ceiling: Integer;
    MapSpot: Integer;
    Speed: Integer;
    Eval: Integer;
    EndEval: Integer;
    NoSave: Integer;
    Kind: TGreedElevatorType;
  end;

implementation

end.
