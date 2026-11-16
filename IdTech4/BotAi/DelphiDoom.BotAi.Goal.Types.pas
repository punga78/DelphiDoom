{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - the types and constants of the goals                   }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the structures and  }
{  the constants of code\botlib\be_ai_goal.c and code\game\be_ai_goal.h. Based }
{  on the Quake III Arena GPL Source Code (id Software). Copyright (C)         }
{  1999-2005 Id Software, Inc.                                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.Types;

interface

uses
  DelphiDoom.MathCore.Types;

const
  /// <summary>MAX_AVOIDGOALS</summary>
  MAX_AVOIDGOALS = 256;
  /// <summary>MAX_GOALSTACK</summary>
  MAX_GOALSTACK = 8;

  /// <summary>The goal flags (GFL_*)</summary>
  GFL_NONE = 0;
  GFL_ITEM = 1;
  GFL_ROAM = 2;
  GFL_DROPPED = 4;

  /// <summary>The item flags of be_ai_goal.c (IFL_*)</summary>
  IFL_NOTFREE = 1;
  IFL_NOTTEAM = 2;
  IFL_NOTSINGLE = 4;
  IFL_NOTBOT = 8;
  IFL_ROAM = 16;

  /// <summary>The game types the item flags depend on (gametype_t, without MISSIONPACK)</summary>
  GT_FFA = 0;
  GT_TOURNAMENT = 1;
  GT_SINGLE_PLAYER = 2;
  GT_TEAM = 3;
  GT_CTF = 4;

  /// <summary>AVOID_MINIMUM_TIME, AVOID_DEFAULT_TIME, AVOID_DROPPED_TIME: seconds</summary>
  AVOID_MINIMUM_TIME = 10;
  AVOID_DEFAULT_TIME = 30;
  AVOID_DROPPED_TIME = 10;

  /// <summary>The size of the fields of text of iteminfo_t</summary>
  ITEM_CLASSNAME_SIZE = 32;
  /// <summary>ET_ITEM of bg_public.h: the type of an item entity</summary>
  ET_ITEM = 2;

type
  /// <summary>bot_goal_t: a bot goal</summary>
  TBotGoal = record
    /// <summary>Origin of the goal</summary>
    Origin: TVec3;
    /// <summary>Area number of the goal</summary>
    AreaNum: Integer;
    Mins: TVec3;
    Maxs: TVec3;
    /// <summary>Number of the goal entity</summary>
    EntityNum: Integer;
    /// <summary>Goal number</summary>
    Number: Integer;
    Flags: Integer;
    /// <summary>Item information (index in the item config)</summary>
    ItemInfo: Integer;
  end;

  PBotGoal = ^TBotGoal;

  /// <summary>
  ///   iteminfo_t with the layout of the C structure (236 bytes): the fields of text of 32 and 80 bytes. The
  ///   structure reader fills it as a buffer of bytes.
  /// </summary>
  TBotItemInfo = packed record
    /// <summary>classname of the item</summary>
    ClassName: array[0..31] of AnsiChar;
    /// <summary>name of the item</summary>
    Name: array[0..79] of AnsiChar;
    Model: array[0..79] of AnsiChar;
    ModelIndex: Integer;
    /// <summary>type: the item type</summary>
    ItemType: Integer;
    /// <summary>index in the inventory</summary>
    Index: Integer;
    RespawnTime: Single;
    Mins: TVec3;
    Maxs: TVec3;
    /// <summary>Number of the item info</summary>
    Number: Integer;
  end;

  /// <summary>maplocation_t: a location of the map (target_location)</summary>
  TBotMapLocation = record
    Origin: TVec3;
    AreaNum: Integer;
    Name: AnsiString;
  end;

  /// <summary>campspot_t: a camp spot (info_camp)</summary>
  TBotCampSpot = record
    Origin: TVec3;
    AreaNum: Integer;
    Name: AnsiString;
    Range: Single;
    Weight: Single;
    Wait: Single;
    Random: Single;
  end;

  /// <summary>levelitem_t: an item of the level (the links are indexes in the heap, -1 is NULL)</summary>
  TBotLevelItem = record
    /// <summary>Number of the level item</summary>
    Number: Integer;
    /// <summary>Index into the item info</summary>
    ItemInfo: Integer;
    Flags: Integer;
    /// <summary>Fixed roam weight</summary>
    Weight: Single;
    Origin: TVec3;
    /// <summary>Area the item is in</summary>
    GoalAreaNum: Integer;
    /// <summary>Goal origin within the area</summary>
    GoalOrigin: TVec3;
    EntityNum: Integer;
    /// <summary>The item is removed after this time (0: never)</summary>
    Timeout: Single;
    Prev: Integer;
    Next: Integer;
  end;

implementation

end.
