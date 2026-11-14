{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - types of the movement prediction (be_aas_move.c)  }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Move.Types;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types;

const
  /// <summary>The stop events of the movement prediction (SE_* of game/be_aas.h)</summary>
  SE_NONE = 0;
  SE_HITGROUND = 1;
  SE_LEAVEGROUND = 2;
  SE_ENTERWATER = 4;
  SE_ENTERSLIME = 8;
  SE_ENTERLAVA = 16;
  SE_HITGROUNDDAMAGE = 32;
  SE_GAP = 64;
  SE_TOUCHJUMPPAD = 128;
  SE_TOUCHTELEPORTER = 256;
  SE_ENTERAREA = 512;
  SE_HITGROUNDAREA = 1024;
  SE_HITBOUNDINGBOX = 2048;
  SE_TOUCHCLUSTERPORTAL = 4096;

  /// <summary>The contents of a point in the BSP (CONTENTS_* of surfaceflags.h that the movement looks at)</summary>
  BSP_CONTENTS_SOLID = 1;
  BSP_CONTENTS_LAVA = 8;
  BSP_CONTENTS_SLIME = 16;
  BSP_CONTENTS_WATER = 32;

type
  /// <summary>aas_clientmove_t: where a client ends up and why the prediction stopped</summary>
  TAasClientMove = record
    EndPos: TVec3;
    EndArea: Integer;
    Velocity: TVec3;
    Trace: TAasTrace;
    PresenceType: Integer;
    StopEvent: Integer;
    EndContents: Integer;
    Time: Single;
    Frames: Integer;
  end;

  /// <summary>
  ///   The part of bsp_trace_t that the botlib reads (be_aas_bsp.h): a box or a point swept through
  ///   the world and the entities of the game
  /// </summary>
  TAasBspTrace = record
    AllSolid: Boolean;
    StartSolid: Boolean;
    Fraction: Single;
    EndPos: TVec3;
    Contents: Integer;
    EntityNum: Integer;
  end;

  /// <summary>
  ///   aassettings: the physics and the rates of the bots, read from the library variables
  ///   (AAS_InitSettings). Names as in the original
  /// </summary>
  TAasMoveSettings = record
    PhysGravityDirection: TVec3;
    PhysFriction: Single;
    PhysStopSpeed: Single;
    PhysGravity: Single;
    PhysWaterFriction: Single;
    PhysWaterGravity: Single;
    PhysMaxVelocity: Single;
    PhysMaxWalkVelocity: Single;
    PhysMaxCrouchVelocity: Single;
    PhysMaxSwimVelocity: Single;
    PhysWalkAccelerate: Single;
    PhysAirAccelerate: Single;
    PhysSwimAccelerate: Single;
    PhysMaxStep: Single;
    PhysMaxSteepness: Single;
    PhysMaxWaterJump: Single;
    PhysMaxBarrier: Single;
    PhysJumpVel: Single;
    PhysFallDelta5: Single;
    PhysFallDelta10: Single;
    RsWaterJump: Single;
    RsTeleport: Single;
    RsBarrierJump: Single;
    RsStartCrouch: Single;
    RsStartGrapple: Single;
    RsStartWalkOffLedge: Single;
    RsStartJump: Single;
    RsRocketJump: Single;
    RsBfgJump: Single;
    RsJumpPad: Single;
    RsAirControlledJumpPad: Single;
    RsFuncBob: Single;
    RsStartElevator: Single;
    RsFallDamage5: Single;
    RsFallDamage10: Single;
    RsMaxFallHeight: Single;
    RsMaxJumpFallHeight: Single;
  end;

  /// <summary>The movement cannot be predicted: a plane number outside the file</summary>
  EAasMoveException = class(Exception);

implementation

end.
