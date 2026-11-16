{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the player movement of Quake III Arena:         }
{  constants and types                                                         }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): bg_public.h,    }
{  bg_local.h, q_shared.h, surfaceflags.h. Copyright (C) 1999-2005 Id          }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Types;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Net.Q3.Types;

const
  // pmtype_t
  Q3_PM_NORMAL = 0;
  Q3_PM_NOCLIP = 1;
  Q3_PM_SPECTATOR = 2;
  Q3_PM_DEAD = 3;
  Q3_PM_FREEZE = 4;
  Q3_PM_INTERMISSION = 5;
  Q3_PM_SPINTERMISSION = 6;

  // weaponstate_t
  Q3_WEAPON_READY = 0;
  Q3_WEAPON_RAISING = 1;
  Q3_WEAPON_DROPPING = 2;
  Q3_WEAPON_FIRING = 3;

  // pmove->pm_flags
  Q3_PMF_DUCKED = 1;
  Q3_PMF_JUMP_HELD = 2;
  Q3_PMF_BACKWARDS_JUMP = 8;
  Q3_PMF_BACKWARDS_RUN = 16;
  Q3_PMF_TIME_LAND = 32;
  Q3_PMF_TIME_KNOCKBACK = 64;
  Q3_PMF_TIME_WATERJUMP = 256;
  Q3_PMF_RESPAWNED = 512;
  Q3_PMF_USE_ITEM_HELD = 1024;
  Q3_PMF_GRAPPLE_PULL = 2048;
  Q3_PMF_FOLLOW = 4096;
  Q3_PMF_SCOREBOARD = 8192;
  Q3_PMF_INVULEXPAND = 16384;
  Q3_PMF_ALL_TIMES = Q3_PMF_TIME_WATERJUMP or Q3_PMF_TIME_LAND or Q3_PMF_TIME_KNOCKBACK;

  /// <summary>MAXTOUCH: the entities one Pmove call reports</summary>
  Q3_MAXTOUCH = 32;

  // statIndex_t (baseq3, MISSIONPACK is not defined)
  Q3_STAT_HEALTH = 0;
  Q3_STAT_HOLDABLE_ITEM = 1;
  Q3_STAT_WEAPONS = 2;
  Q3_STAT_ARMOR = 3;
  Q3_STAT_DEAD_YAW = 4;
  Q3_STAT_CLIENTS_READY = 5;
  Q3_STAT_MAX_HEALTH = 6;

  // persEnum_t
  Q3_PERS_SCORE = 0;
  Q3_PERS_TEAM = 3;

  // team_t
  Q3_TEAM_FREE = 0;
  Q3_TEAM_RED = 1;
  Q3_TEAM_BLUE = 2;
  Q3_TEAM_SPECTATOR = 3;

  // entityState_t->eFlags
  Q3_EF_FIRING = $00000100;
  Q3_EF_TALK = $00001000;

  // powerup_t
  Q3_PW_NONE = 0;
  Q3_PW_QUAD = 1;
  Q3_PW_BATTLESUIT = 2;
  Q3_PW_HASTE = 3;
  Q3_PW_INVIS = 4;
  Q3_PW_REGEN = 5;
  Q3_PW_FLIGHT = 6;
  Q3_PW_INVULNERABILITY = 14;

  // holdable_t
  Q3_HI_NONE = 0;
  Q3_HI_TELEPORTER = 1;
  Q3_HI_MEDKIT = 2;

  // weapon_t (baseq3)
  Q3_WP_NONE = 0;
  Q3_WP_GAUNTLET = 1;
  Q3_WP_MACHINEGUN = 2;
  Q3_WP_SHOTGUN = 3;
  Q3_WP_GRENADE_LAUNCHER = 4;
  Q3_WP_ROCKET_LAUNCHER = 5;
  Q3_WP_LIGHTNING = 6;
  Q3_WP_RAILGUN = 7;
  Q3_WP_PLASMAGUN = 8;
  Q3_WP_BFG = 9;
  Q3_WP_GRAPPLING_HOOK = 10;
  Q3_WP_NUM_WEAPONS = 11;

  // entity_event_t (the ones the movement generates)
  Q3_EV_NONE = 0;
  Q3_EV_FOOTSTEP = 1;
  Q3_EV_FOOTSTEP_METAL = 2;
  Q3_EV_FOOTSPLASH = 3;
  Q3_EV_FOOTWADE = 4;
  Q3_EV_SWIM = 5;
  Q3_EV_STEP_4 = 6;
  Q3_EV_STEP_8 = 7;
  Q3_EV_STEP_12 = 8;
  Q3_EV_STEP_16 = 9;
  Q3_EV_FALL_SHORT = 10;
  Q3_EV_FALL_MEDIUM = 11;
  Q3_EV_FALL_FAR = 12;
  Q3_EV_JUMP_PAD = 13;
  Q3_EV_JUMP = 14;
  Q3_EV_WATER_TOUCH = 15;
  Q3_EV_WATER_LEAVE = 16;
  Q3_EV_WATER_UNDER = 17;
  Q3_EV_WATER_CLEAR = 18;
  Q3_EV_NOAMMO = 21;
  Q3_EV_CHANGE_WEAPON = 22;
  Q3_EV_FIRE_WEAPON = 23;
  Q3_EV_USE_ITEM0 = 24;
  /// <summary>EV_TAUNT (the first one after EV_DEBUG_LINE and EV_STOPLOOPINGSOUND)</summary>
  Q3_EV_TAUNT = 76;

  // the animation numbers (animNumber_t, ANIM_TOGGLEBIT) are those of DelphiDoom.Models.Q3Player.Types, which
  // the player animator uses: the same constants, not a second copy

  // buttons of usercmd_t
  Q3_BUTTON_ATTACK = 1;
  Q3_BUTTON_TALK = 2;
  Q3_BUTTON_USE_HOLDABLE = 4;
  Q3_BUTTON_GESTURE = 8;
  Q3_BUTTON_WALKING = 16;

  // sizes of the player
  Q3_MINS_Z = -24;
  Q3_DEFAULT_VIEWHEIGHT = 26;
  Q3_CROUCH_VIEWHEIGHT = 12;
  Q3_DEAD_VIEWHEIGHT = -16;

  // bg_local.h
  Q3_STEPSIZE = 18;
  Q3_JUMP_VELOCITY = 270;
  Q3_TIMER_LAND = 130;
  Q3_TIMER_GESTURE = 34 * 66 + 50;
  /// <summary>PS_PMOVEFRAMECOUNTBITS</summary>
  Q3_PS_PMOVEFRAMECOUNTBITS = 6;

  // entity numbers
  Q3_ENTITYNUM_NONE = Q3_MAX_GENTITIES - 1;
  Q3_ENTITYNUM_WORLD = Q3_MAX_GENTITIES - 2;

  // surfaceflags.h
  Q3_CONTENTS_LAVA = 8;
  Q3_CONTENTS_SLIME = 16;
  Q3_CONTENTS_WATER = 32;
  Q3_CONTENTS_PLAYERCLIP = $10000;
  Q3_SURF_NODAMAGE = $1;
  Q3_SURF_SLICK = $2;
  Q3_SURF_METALSTEPS = $1000;
  Q3_SURF_NOSTEPS = $2000;

  // bg_public.h
  Q3_MASK_ALL = -1;
  Q3_MASK_SOLID = Q3_CONTENTS_SOLID;
  Q3_MASK_PLAYERSOLID = Q3_CONTENTS_SOLID or Q3_CONTENTS_PLAYERCLIP or Q3_CONTENTS_BODY;
  Q3_MASK_DEADSOLID = Q3_CONTENTS_SOLID or Q3_CONTENTS_PLAYERCLIP;
  Q3_MASK_WATER = Q3_CONTENTS_WATER or Q3_CONTENTS_LAVA or Q3_CONTENTS_SLIME;

  /// <summary>OVERCLIP is a float constant (1.001f)</summary>
  Q3_OVERCLIP: Single = 1.001;
  /// <summary>MIN_WALK_NORMAL is a float constant (0.7f): can't walk on very steep slopes</summary>
  Q3_MIN_WALK_NORMAL: Single = 0.7;

  // the double constants of the C expressions: a float compared or multiplied with them is computed as a
  // double (the tests check their bits against the compiler of the original)
  /// <summary>pml.frametime = pml.msec * 0.001</summary>
  Q3_MSEC_TO_SECONDS: Double = 0.001;
  /// <summary>into >= 0.1 and DotProduct (...) >= 0.1 in PM_SlideMove</summary>
  Q3_CLIP_INTO: Double = 0.1;
  /// <summary>DotProduct (trace.plane.normal, planes[i]) > 0.99 in PM_SlideMove</summary>
  Q3_SAME_PLANE: Double = 0.99;
  /// <summary>DotProduct(trace.plane.normal, up) < 0.7 in PM_StepSlideMove</summary>
  Q3_STEP_NORMAL: Double = 0.7;
  /// <summary>delta = delta*delta * 0.0001 in PM_CrashLand</summary>
  Q3_FALL_SCALE: Double = 0.0001;
  /// <summary>waterScale = pm->waterlevel / 3.0 in PM_WalkMove</summary>
  Q3_WATER_DIVISOR: Double = 3.0;
  /// <summary>addTime /= 1.3 in PM_Weapon</summary>
  Q3_HASTE_DIVISOR: Double = 1.3;

  /// <summary>Of the PITCH, YAW and ROLL of q_shared.h</summary>
  Q3_PITCH = 0;
  Q3_YAW = 1;
  Q3_ROLL = 2;

resourcestring
  SPmoveInvalidFixedMsec = 'Pmove: pmove_fixed with pmove_msec %d (it must be at least 1, the original does not end)';

type
  /// <summary>Raised for a call the original answers with a crash or a loop that never ends</summary>
  EPmoveException = class(Exception);

  /// <summary>
  ///   The movement parameters of bg_pmove.c (pm_stopspeed ... pm_spectatorfriction): plain globals in the
  ///   original, here a value that is handed to the mover so that two movers can differ
  /// </summary>
  TPmoveTuning = record
    StopSpeed: Single;
    DuckScale: Single;
    SwimScale: Single;
    WadeScale: Single;
    Accelerate: Single;
    AirAccelerate: Single;
    WaterAccelerate: Single;
    FlyAccelerate: Single;
    Friction: Single;
    WaterFriction: Single;
    FlightFriction: Single;
    SpectatorFriction: Single;
    /// <summary>The values of bg_pmove.c</summary>
    class function Default: TPmoveTuning; static;
  end;

  /// <summary>pmove_t: the state and the command in, the results out (the world is the trace given to the mover)</summary>
  TPmove = record
    // state (in / out)
    Ps: TQ3PlayerState;
    // command (in; the call changes it: the buttons, the moves and the server time)
    Cmd: TQ3UserCmd;
    /// <summary>tracemask: collide against these types of surfaces</summary>
    TraceMask: Integer;
    /// <summary>debugLevel: when not zero the diagnostic lines go to the log of the mover</summary>
    DebugLevel: Integer;
    /// <summary>noFootsteps: the game is set up for no footsteps</summary>
    NoFootsteps: Boolean;
    /// <summary>gauntletHit: a gauntlet attack would hit something</summary>
    GauntletHit: Boolean;
    FrameCount: Integer;
    // results (out)
    NumTouch: Integer;
    TouchEnts: array[0..Q3_MAXTOUCH - 1] of Integer;
    Mins: TQ3Vec3;
    Maxs: TQ3Vec3;
    WaterType: Integer;
    WaterLevel: Integer;
    XySpeed: Single;
    // for fixed msec Pmove
    PmoveFixed: Boolean;
    PmoveMsec: Integer;
  end;
  PPmove = ^TPmove;

  /// <summary>pml_t: the locals of one PmoveSingle (zeroed before each)</summary>
  TPmoveLocals = record
    Forward: TQ3Vec3;
    Right: TQ3Vec3;
    Up: TQ3Vec3;
    FrameTime: Single;
    Msec: Integer;
    Walking: Boolean;
    GroundPlane: Boolean;
    GroundTrace: TQ3Trace;
    ImpactSpeed: Single;
    PreviousOrigin: TQ3Vec3;
    PreviousVelocity: TQ3Vec3;
    PreviousWaterLevel: Integer;
  end;
  PPmoveLocals = ^TPmoveLocals;

implementation

class function TPmoveTuning.Default: TPmoveTuning;
begin
  Result.StopSpeed := 100.0;
  Result.DuckScale := 0.25;
  Result.SwimScale := 0.50;
  Result.WadeScale := 0.70;
  Result.Accelerate := 10.0;
  Result.AirAccelerate := 1.0;
  Result.WaterAccelerate := 4.0;
  Result.FlyAccelerate := 8.0;
  Result.Friction := 6.0;
  Result.WaterFriction := 1.0;
  Result.FlightFriction := 3.0;
  Result.SpectatorFriction := 5.0;
end;

end.
