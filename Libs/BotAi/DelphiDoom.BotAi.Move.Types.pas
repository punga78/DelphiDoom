{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - the types and constants of the movement                }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\game\          }
{  be_ai_move.h and the constants of code\botlib\be_ai_move.c. Based on the    }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Types;

interface

uses
  DelphiDoom.MathCore.Types;

const
  /// <summary>The movement types (MOVE_*)</summary>
  MOVE_WALK = 1;
  MOVE_CROUCH = 2;
  MOVE_JUMP = 4;
  MOVE_GRAPPLE = 8;
  MOVE_ROCKETJUMP = 16;
  MOVE_BFGJUMP = 32;

  /// <summary>The move flags (MFL_*)</summary>
  MFL_BARRIERJUMP = 1;
  MFL_ONGROUND = 2;
  MFL_SWIMMING = 4;
  MFL_AGAINSTLADDER = 8;
  MFL_WATERJUMP = 16;
  MFL_TELEPORTED = 32;
  MFL_GRAPPLEPULL = 64;
  MFL_ACTIVEGRAPPLE = 128;
  MFL_GRAPPLERESET = 256;
  MFL_WALK = 512;

  /// <summary>The move result flags (MOVERESULT_*)</summary>
  MOVERESULT_MOVEMENTVIEW = 1;
  MOVERESULT_SWIMVIEW = 2;
  MOVERESULT_WAITING = 4;
  MOVERESULT_MOVEMENTVIEWSET = 8;
  MOVERESULT_MOVEMENTWEAPON = 16;
  MOVERESULT_ONTOPOFOBSTACLE = 32;
  MOVERESULT_ONTOPOF_FUNCBOB = 64;
  MOVERESULT_ONTOPOF_ELEVATOR = 128;
  MOVERESULT_BLOCKEDBYAVOIDSPOT = 256;

  /// <summary>MAX_AVOIDREACH, MAX_AVOIDSPOTS</summary>
  MAX_AVOIDREACH = 1;
  MAX_AVOIDSPOTS = 32;

  /// <summary>The avoid spot types (AVOID_*)</summary>
  AVOID_CLEAR = 0;
  AVOID_ALWAYS = 1;
  AVOID_DONTBLOCK = 2;

  /// <summary>The result types (RESULTTYPE_*)</summary>
  RESULTTYPE_ELEVATORUP = 1;
  RESULTTYPE_WAITFORFUNCBOBBING = 2;
  RESULTTYPE_BADGRAPPLEPATH = 4;
  RESULTTYPE_INSOLIDAREA = 8;

  /// <summary>The types of the brush models of the map (MODELTYPE_*)</summary>
  MODELTYPE_FUNC_PLAT = 1;
  MODELTYPE_FUNC_BOB = 2;
  MODELTYPE_FUNC_DOOR = 3;
  MODELTYPE_FUNC_STATIC = 4;

  /// <summary>MAX_MODELS: the number of brush models</summary>
  BOT_MAX_MODELS = 256;
  /// <summary>ENTITYNUM_NONE and ENTITYNUM_WORLD (MAX_GENTITIES is 1024)</summary>
  ENTITYNUM_NONE = 1023;
  ENTITYNUM_WORLD = 1022;

type
  /// <summary>bot_avoidspot_t: a spot the bot should stay away from</summary>
  TBotAvoidSpot = record
    Origin: TVec3;
    Radius: Single;
    /// <summary>One of AVOID_ALWAYS, AVOID_DONTBLOCK (AVOID_CLEAR clears the spots)</summary>
    SpotType: Integer;
  end;

  /// <summary>bot_initmove_t: what the movement state needs from the game each frame</summary>
  TBotInitMove = record
    Origin: TVec3;
    Velocity: TVec3;
    ViewOffset: TVec3;
    EntityNum: Integer;
    Client: Integer;
    ThinkTime: Single;
    PresenceType: Integer;
    ViewAngles: TVec3;
    /// <summary>The MFL_ONGROUND, MFL_TELEPORTED, MFL_WATERJUMP, MFL_WALK and MFL_GRAPPLEPULL that come from the player state</summary>
    OrMoveFlags: Integer;
  end;

  /// <summary>bot_moveresult_t: the result of a movement; the ideal view angles are valid if MOVERESULT_MOVEMENTVIEW is set</summary>
  TBotMoveResult = record
    /// <summary>True if the movement failed all together</summary>
    Failure: Boolean;
    /// <summary>Failure or blocked type (RESULTTYPE_*)</summary>
    ResultType: Integer;
    /// <summary>True if blocked by an entity</summary>
    Blocked: Boolean;
    /// <summary>The entity blocking the bot</summary>
    BlockEntity: Integer;
    /// <summary>The last executed travel type</summary>
    TravelType: Integer;
    Flags: Integer;
    /// <summary>The weapon used for the movement</summary>
    Weapon: Integer;
    MoveDir: TVec3;
    IdealViewAngles: TVec3;
  end;

implementation

end.
