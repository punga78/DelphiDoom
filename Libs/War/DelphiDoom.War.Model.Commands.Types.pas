{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the types of the commands                         }
{                                                                              }
{  Port of war1 (acoto87/war1), WarUnitCommandType of war_enums.h and          }
{  WarUnitCommand of war_commands.h, (c) 2019 Alejandro Coto Gutierrez, zlib   }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not    }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.Types;

interface

uses
  DelphiDoom.War.Model.Types;

const
  // WarUnitCommandType: the numbers of the original
  WAR_COMMAND_NONE = 0;
  WAR_COMMAND_MOVE = 1;
  WAR_COMMAND_STOP = 2;
  WAR_COMMAND_HARVEST = 3;
  WAR_COMMAND_DELIVER = 4;
  WAR_COMMAND_REPAIR = 5;
  WAR_COMMAND_ATTACK = 6;
  /// <summary>TRAIN_FOOTMAN .. TRAIN_NECROLYTE: 14 commands in the order of the table of the units trained</summary>
  WAR_COMMAND_TRAIN_FIRST = 7;
  WAR_COMMAND_TRAIN_LAST = 20;
  WAR_COMMAND_SPELL_HEALING = 21;
  WAR_COMMAND_SPELL_FAR_SIGHT = 22;
  WAR_COMMAND_SPELL_INVISIBILITY = 23;
  WAR_COMMAND_SPELL_RAIN_OF_FIRE = 24;
  WAR_COMMAND_SPELL_POISON_CLOUD = 25;
  WAR_COMMAND_SPELL_RAISE_DEAD = 26;
  WAR_COMMAND_SPELL_DARK_VISION = 27;
  WAR_COMMAND_SPELL_UNHOLY_ARMOR = 28;
  WAR_COMMAND_SUMMON_SPIDER = 29;
  WAR_COMMAND_SUMMON_SCORPION = 30;
  WAR_COMMAND_SUMMON_DAEMON = 31;
  WAR_COMMAND_SUMMON_WATER_ELEMENTAL = 32;
  WAR_COMMAND_BUILD_BASIC = 33;
  WAR_COMMAND_BUILD_ADVANCED = 34;
  /// <summary>BUILD_FARM_HUMANS .. BUILD_BLACKSMITH_ORCS: 16 commands in the order of the building types</summary>
  WAR_COMMAND_BUILD_FIRST = 35;
  WAR_COMMAND_BUILD_LAST = 50;
  WAR_COMMAND_BUILD_ROAD = 51;
  WAR_COMMAND_BUILD_WALL = 52;
  /// <summary>UPGRADE_SWORDS .. UPGRADE_UNHOLY_ARMOR: 20 commands</summary>
  WAR_COMMAND_UPGRADE_FIRST = 53;
  WAR_COMMAND_UPGRADE_LAST = 72;
  WAR_COMMAND_CANCEL = 73;
  WAR_COMMAND_COUNT = 74;

  /// <summary>WAR_ROAD_GOLD_COST and WAR_ROAD_WOOD_COST of war_units.h</summary>
  WAR_ROAD_GOLD_COST = 50;
  WAR_ROAD_WOOD_COST = 0;
  /// <summary>WAR_NORMAL_SPELL of war_enums.h: the sound of a summon (the spells with a place tell IWarSpellEvents)</summary>
  WAR_SOUND_NORMAL_SPELL = 532;

type
  /// <summary>
  ///   An order with what it needs: the type, the point of the map (pixels) for the orders that have one and whether the
  ///   order is added to what the units are doing (SHIFT held: a waypoint more). The units that obey are the selection
  ///   of who gives the order. The unit to train, the upgrade and the building are told by the type of the command
  /// </summary>
  TWarCommand = record
    CommandType: Integer;
    Target: TWarVec2;
    Queue: Boolean;
  end;

  /// <summary>What an order did: nothing (it could not be executed and stays the current command) or it was executed</summary>
  TWarCommandOutcome = (wcoNotExecuted, wcoExecuted);

implementation

end.
