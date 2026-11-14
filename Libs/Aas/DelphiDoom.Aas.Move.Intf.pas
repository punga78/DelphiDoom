{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - contracts of the movement prediction              }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Move.Intf;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Route.Types,
  DelphiDoom.Aas.Move.Types;

type
  /// <summary>
  ///   What the botlib asks of the game about the BSP (AAS_PointContents and AAS_Trace of be_aas_bspq3.c,
  ///   which call botimport.PointContents and botimport.Trace)
  /// </summary>
  IAasBspWorld = interface
    ['{6C4F1B33-2D70-4A96-B1E5-8F03A7D26C14}']
    /// <summary>The contents of the point (BSP_CONTENTS_* ORed)</summary>
    function PointContents(const APoint: TVec3): Integer;
    /// <summary>
    ///   A box (or a point if both are nil) from the start to the end; the entity to pass and the contents
    ///   that block (AAS_Trace)
    /// </summary>
    function Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const APassEnt,
      AContentMask: Integer): TAasBspTrace;
  end;

  /// <summary>The physics of a client of the game, as the bots predict it (be_aas_move.c)</summary>
  IAasMovement = interface
    ['{6C4F1B33-2D70-4A96-B1E5-8F03A7D26C15}']
    function GetSettings: TAasMoveSettings;
    /// <summary>The settings that were read (aassettings)</summary>
    property Settings: TAasMoveSettings read GetSettings;
    /// <summary>Drops the origin 100 units; False if the box starts in solid</summary>
    function DropToFloor(var AOrigin: TVec3; const AMins, AMaxs: TVec3): Boolean;
    function AgainstLadder(const AOrigin: TVec3): Boolean;
    function OnGround(const AOrigin: TVec3; const APresenceType, APassEnt: Integer): Boolean;
    function Swimming(const AOrigin: TVec3): Boolean;
    procedure SetMovedir(const AAngles: TVec3; out AMoveDir: TVec3);
    procedure JumpReachRunStart(const AReach: TAasReachability; out ARunStart: TVec3);
    function WeaponJumpZVelocity(const AOrigin: TVec3; const ARadiusDamage: Single): Single;
    function RocketJumpZVelocity(const AOrigin: TVec3): Single;
    function BFGJumpZVelocity(const AOrigin: TVec3): Single;
    function ClipToBBox(var ATrace: TAasTrace; const AStart, AEnd: TVec3; const APresenceType: Integer;
      const AMins, AMaxs: TVec3): Boolean;
    /// <summary>AAS_PredictClientMovement: the box and the visualization of the original are not given</summary>
    function PredictClientMovement(out AMove: TAasClientMove; const AEntNum: Integer; const AOrigin: TVec3;
      const APresenceType: Integer; const AOnGround: Boolean; const AVelocity, ACmdMove: TVec3;
      const ACmdFrames, AMaxFrames: Integer; const AFrameTime: Single; const AStopEvent, AStopAreaNum: Integer;
      const AVisualize: Boolean): Boolean;
    /// <summary>AAS_ClientMovementHitBBox: the prediction stops when the client hits the box</summary>
    function ClientMovementHitBBox(out AMove: TAasClientMove; const AEntNum: Integer; const AOrigin: TVec3;
      const APresenceType: Integer; const AOnGround: Boolean; const AVelocity, ACmdMove: TVec3;
      const ACmdFrames, AMaxFrames: Integer; const AFrameTime: Single; const AMins, AMaxs: TVec3;
      const AVisualize: Boolean): Boolean;
    /// <summary>
    ///   AAS_HorizontalVelocityForJump: the horizontal speed to jump from the start to the end with the vertical
    ///   speed given; False (and the maximum speed) if it cannot be done
    /// </summary>
    function HorizontalVelocityForJump(const AZVel: Single; const AStart, AEnd: TVec3; out AVelocity: Single): Boolean;
  end;

implementation

end.
