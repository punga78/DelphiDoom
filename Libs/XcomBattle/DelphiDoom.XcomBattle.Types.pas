{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - constants and errors                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Types;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Random;

const
  /// <summary>UnitStatus</summary>
  STATUS_STANDING = 0;
  STATUS_WALKING = 1;
  STATUS_FLYING = 2;
  STATUS_TURNING = 3;
  STATUS_AIMING = 4;
  STATUS_COLLAPSING = 5;
  STATUS_DEAD = 6;
  STATUS_UNCONSCIOUS = 7;
  STATUS_PANICKING = 8;
  STATUS_BERSERK = 9;
  STATUS_IGNORE_ME = 10;
  /// <summary>UnitFaction</summary>
  FACTION_PLAYER = 0;
  FACTION_HOSTILE = 1;
  FACTION_NEUTRAL = 2;
  /// <summary>UnitSide</summary>
  SIDE_FRONT = 0;
  SIDE_LEFT = 1;
  SIDE_RIGHT = 2;
  SIDE_REAR = 3;
  SIDE_UNDER = 4;
  /// <summary>UnitBodyPart</summary>
  BODYPART_HEAD = 0;
  BODYPART_TORSO = 1;
  BODYPART_RIGHTARM = 2;
  BODYPART_LEFTARM = 3;
  BODYPART_RIGHTLEG = 4;
  BODYPART_LEFTLEG = 5;
  /// <summary>BattleActionType</summary>
  BA_NONE = 0;
  BA_TURN = 1;
  BA_WALK = 2;
  BA_PRIME = 3;
  BA_THROW = 4;
  BA_AUTOSHOT = 5;
  BA_SNAPSHOT = 6;
  BA_AIMEDSHOT = 7;
  BA_HIT = 8;
  BA_USE = 9;
  BA_LAUNCH = 10;
  BA_MINDCONTROL = 11;
  BA_PANIC = 12;
  BA_RETHINK = 13;
  /// <summary>InventoryType</summary>
  INV_SLOT = 0;
  INV_HAND = 1;
  INV_GROUND = 2;
  /// <summary>SpecialAbility</summary>
  SPECAB_NONE = 0;
  SPECAB_EXPLODEONDEATH = 1;
  SPECAB_BURNFLOOR = 2;
  SPECAB_BURN_AND_EXPLODE = 3;
  /// <summary>ChronoTrigger</summary>
  FORCE_LOSE = 0;
  FORCE_ABORT = 1;
  FORCE_WIN = 2;
  /// <summary>Soldier ranks and genders</summary>
  RANK_ROOKIE = 0;
  RANK_SQUADDIE = 1;
  RANK_SERGEANT = 2;
  RANK_CAPTAIN = 3;
  RANK_COLONEL = 4;
  RANK_COMMANDER = 5;
  GENDER_MALE = 0;
  GENDER_FEMALE = 1;
  /// <summary>MovementType (the numbers of the C++ enumeration)</summary>
  MT_WALK = 0;
  MT_FLY = 1;
  MT_SLIDE = 2;
  MT_FLOAT = 3;
  MT_SINK = 4;
  /// <summary>Directions of the pathfinding that are not on the plane (Pathfinding::DIR_UP, DIR_DOWN)</summary>
  DIR_UP = 8;
  DIR_DOWN = 9;
  /// <summary>Tile::LIGHTLAYERS and Tile::NOT_CALCULATED</summary>
  LIGHT_LAYERS = 3;
  /// <summary>BattleUnit::MAX_SOLDIER_ID</summary>
  MAX_SOLDIER_ID = 1000000;
  SPEC_WEAPON_MAX = 3;
  /// <summary>Node::nodeRank, Node::TYPE_*</summary>
  NODE_TYPE_FLYING = $01;
  NODE_TYPE_SMALL = $02;
  NODE_TYPE_DANGEROUS = $04;
  /// <summary>VoxelType: what a line of fire meets</summary>
  V_EMPTY = -1;
  V_FLOOR = 0;
  V_WESTWALL = 1;
  V_NORTHWALL = 2;
  V_OBJECT = 3;
  V_UNIT = 4;
  V_OUTOFBOUNDS = 5;

const
  /// <summary>Node::nodeRank: the node ranks where each rank of alien spawns, in order of preference</summary>
  NODE_RANK: array[0..7, 0..6] of Integer = (
    (4, 3, 5, 8, 7, 2, 0),
    (4, 3, 5, 8, 7, 2, 0),
    (5, 4, 3, 2, 7, 8, 0),
    (7, 6, 2, 8, 3, 4, 0),
    (3, 4, 5, 2, 7, 8, 0),
    (2, 5, 3, 4, 6, 8, 0),
    (2, 5, 3, 4, 6, 8, 0),
    (2, 5, 3, 4, 6, 8, 0));

type
  /// <summary>The errors of the battlescape library</summary>
  EXcomBattleException = class(Exception);

  /// <summary>RNG::percent(x): a number from 0 to 99 is less than x</summary>
  TXcomBattleRandom = class
  public
    class function Percent(const ARandom: IXcomRandom; AValue: Integer): Boolean; static;
  end;

implementation

class function TXcomBattleRandom.Percent(const ARandom: IXcomRandom; AValue: Integer): Boolean;
begin
  Result := ARandom.Generate(0, 99) < AValue;
end;

end.
