{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - constants and types of building and training       }
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.h, war_cheats.h and war_enums.h,     }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Construction.Types;

interface

const
  /// <summary>CHEAT_SPEED_UP_FACTOR of war_cheats.h: with the hurry up cheat a building, a unit or an upgrade is made 100 times faster</summary>
  WAR_MODEL_HURRY_UP_FACTOR: Single = 100.0;
  /// <summary>WAR_WALL_GOLD_COST, WAR_WALL_WOOD_COST and WAR_WALL_MAX_HP of war_units.h</summary>
  WAR_WALL_GOLD_COST = 100;
  WAR_WALL_WOOD_COST = 0;
  WAR_WALL_MAX_HP = 60;
  /// <summary>
  ///   What the repair of a building gives and takes each time the worker swings the hammer (a second of work): one
  ///   gold and one lumber for 9 hit points (12 percent of the damage costs the repair, 1 / 12 of the hit points is 8.33,
  ///   which the original rounds to 9)
  /// </summary>
  WAR_REPAIR_HP_PER_STEP = 9;
  /// <summary>The collapse animation: 17 frames of a tenth of a second (wanim_createCollapseAnimation)</summary>
  WAR_COLLAPSE_FRAMES = 17;

  // WarAudioId of war_enums.h that the states ask for (the ids of the sounds of the original)
  WAR_SOUND_BUILDING_COLLAPSE_1 = 481;
  WAR_SOUND_BUILDING_COLLAPSE_3 = 483;
  WAR_SOUND_UI_CANCEL = 486;
  WAR_SOUND_ORC_WORK_COMPLETE = 501;
  WAR_SOUND_HUMAN_WORK_COMPLETE = 502;
  WAR_SOUND_ORC_READY = 507;
  WAR_SOUND_HUMAN_READY = 508;
  WAR_SOUND_BUILD_ROAD = 533;

type
  /// <summary>
  ///   WarWallPiece: one tile of wall with its hit points. The type is the piece that fits its neighbors (the same
  ///   numbers as the pieces of the roads, WAR_WALL_PIECE_LEFT ...)
  /// </summary>
  TWarWallPiece = record
    PieceType: Byte;
    Hp: Integer;
    MaxHp: Integer;
    TileX: Integer;
    TileY: Integer;
    Player: Byte;
  end;

  PWarWallPiece = ^TWarWallPiece;

resourcestring
  SWarModelNoBuildState = 'The building %d is being built but has no build state';
  SWarModelNoBuildingData = 'The building type %d has no image of its construction';
  SWarModelBadWallPiece = 'The wall has no piece number %d';

implementation

end.
