{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - the types of the logic of a level               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{  Copyright (C) 1995 by Epic MegaGames, Inc. (Radix - beyond the void)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the constants of radix_level.pas and radix_grid.pas of Rad-X that   }
{  the triggers and the actions of a level use while the game runs             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.LevelLogic.Types;

interface

uses
  DelphiDoom.Radix.Level.Types;

const
  // what an action of a trigger does to its action (activationflags; SPR_FLG_???? of Rad-X)
  RADIX_TRIGGER_ACTIVATE = 0;
  RADIX_TRIGGER_DEACTIVATE = 1;
  RADIX_TRIGGER_ACTIVATE_ON_SPACE = 2;
  RADIX_TRIGGER_TOGGLE = 3;

  /// <summary>The cells of the grid that a craft can cross in one tic (MAXMOVEMENTGRIDPOSITIONS)</summary>
  RADIX_MAX_GRID_POSITIONS = 3;

  /// <summary>No trigger in a cell of the grid, no trigger touched by a player yet</summary>
  RADIX_NO_TRIGGER = -1;

  // the kinds of action (action_type of radixaction_t; the "sprite types" of RADIX.DAT)
  RADIX_ACTION_SCROLLING_WALL = 0;
  RADIX_ACTION_MOVING_SURFACE = 1;
  RADIX_ACTION_SWITCH_WALL_BITMAP = 2;
  RADIX_ACTION_SWITCH_SECTOR_BITMAP = 3;
  RADIX_ACTION_TOGGLE_WALL_BITMAP = 4;
  RADIX_ACTION_TOGGLE_SECTOR_BITMAP = 5;
  RADIX_ACTION_CIRCLE_BITMAP = 6;
  RADIX_ACTION_LIGHT_FLICKER = 7;
  RADIX_ACTION_LIGHTS_OFF = 8;
  RADIX_ACTION_LIGHTS_ON = 9;
  RADIX_ACTION_LIGHT_OSCILLATE = 10;
  RADIX_ACTION_PLANE_TELEPORT = 11;
  RADIX_ACTION_PLANE_TRANSPO = 12;
  RADIX_ACTION_NEW_MOVING_SURFACE = 13;
  RADIX_ACTION_PLAY_SOUND = 14;
  RADIX_ACTION_RANDOM_LIGHTS_FLICKER = 15;
  RADIX_ACTION_END_OF_LEVEL = 16;
  RADIX_ACTION_SPRITE_TRIGGER_ACTIVATE = 17;
  RADIX_ACTION_SECTOR_BASED_GRAVITY = 18;
  RADIX_ACTION_DEACTIVATE_TRIGGER = 19;
  RADIX_ACTION_ACTIVATE_TRIGGER = 20;
  RADIX_ACTION_COMPLETE_MISSILE_WALL = 21;
  RADIX_ACTION_SCANNER_JAM = 22;
  RADIX_ACTION_PRINT_MESSAGE = 23;
  RADIX_ACTION_FLOOR_MISSILE_WALL = 24;
  RADIX_ACTION_CEILING_MISSILE_WALL = 25;
  RADIX_ACTION_BIG_SPRITE_TRIGGER = 26;
  RADIX_ACTION_MASSIVE_EXPLOSION = 27;
  RADIX_ACTION_WALL_DEAD_CHECK = 28;
  RADIX_ACTION_SECONDARY_OBJECTIVE = 29;
  RADIX_ACTION_SEEK_COMPLETE_MISSILE_WALL = 30;
  RADIX_ACTION_LIGHT_MOVEMENT = 31;
  RADIX_ACTION_MULTIPLE_LIGHT_OSCILLATE = 32;
  RADIX_ACTION_MULTIPLE_RANDOM_LIGHTS_FLICKER = 33;
  RADIX_ACTION_KILL_RATIO = 34;
  RADIX_ACTION_HURT_PLAYER_EXPLOSION = 35;
  RADIX_ACTION_SWITCH_SHADE_TYPE = 36;
  RADIX_ACTION_SIX_LIGHT_MOVEMENT = 37;
  RADIX_ACTION_SURFACE_POWER_UP = 38;
  RADIX_ACTION_SECRET_SPRITE = 39;
  RADIX_ACTION_BOSS_EYE_HANDLER = 40;
  RADIX_ACTION_VERTICAL_EXPLOSION = 41;
  RADIX_ACTION_CHANGE_FLOOR_OFFSETS = 42;
  RADIX_ACTION_MASSIVE_LIGHT_MOVEMENT = 43;
  RADIX_ACTION_KINDS = 44;

  // wall flags that the game sets and reads (the others are in DelphiDoom.Radix.Level.Types)
  RWF_PEGTOP_FLOOR = 32;
  RWF_PEGTOP_CEILING = 64;
  RWF_PEGBOTTOM_FLOOR = 128;
  RWF_PEGBOTTOM_CEILING = 256;
  RWF_ACTIVATETRIGGER = 1024;
  RWF_MISSILEWALL = 2048;
  RWF_LINEBRIEFINGIGNORE = $4000000;
  RWF_SHOOTABLE = $8000000;
  RWF_FORCEINTERPOLATE = $10000000;

  /// <summary>The hit points of a wall that fires missiles when RMAP gives it none</summary>
  RADIX_MISSILE_WALL_HIT_POINTS = 100;

type
  PRadixLevelAction = ^TRadixLevelAction;
  PRadixLevelTrigger = ^TRadixLevelTrigger;

  /// <summary>
  ///   The lump RGRID read: the trigger of every cell (RADIX_NO_TRIGGER: none), row after row.
  ///   Width and Height are 0 for a level without grid, and then Cells are all RADIX_NO_TRIGGER
  /// </summary>
  TRadixTriggerGridData = record
    Width: Integer;
    Height: Integer;
    Cells: TArray<SmallInt>;
  end;

  /// <summary>The cells of the grid a craft is in during one tic, each once (gridmovementpositions_t)</summary>
  TRadixGridPositions = record
    Count: Integer;
    Cells: array[0..RADIX_MAX_GRID_POSITIONS - 1] of Integer;
    /// <summary>Adds a cell that is not there yet; a cell past the third is dropped</summary>
    procedure Add(ACell: Integer);
    class function Empty: TRadixGridPositions; static;
  end;

  /// <summary>A point of the map in map units</summary>
  TRadixMapPosition = record
    X: Integer;
    Y: Integer;
  end;

  /// <summary>The three places where the grid is asked for a craft that moves (RX_PosInGrid)</summary>
  TRadixMovementSamples = array[0..RADIX_MAX_GRID_POSITIONS - 1] of TRadixMapPosition;

implementation

{ TRadixGridPositions }

class function TRadixGridPositions.Empty: TRadixGridPositions;
begin
  Result.Count := 0;
  Result.Cells[0] := 0;
  Result.Cells[1] := 0;
  Result.Cells[2] := 0;
end;

procedure TRadixGridPositions.Add(ACell: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to Count - 1 do
    if Cells[LIndex] = ACell then
      Exit;
  if Count < RADIX_MAX_GRID_POSITIONS then
  begin
    Cells[Count] := ACell;
    Inc(Count);
  end;
end;

end.
