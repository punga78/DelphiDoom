{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - blending of animations: shared types        }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim.h and     }
{  Anim_Blend.cpp (idAnimBlend, idAnimator). Copyright (C) 1999-2011 id        }
{  Software LLC, a ZeniMax Media company. This unit is derived from the Doom   }
{  3 GPL source code and is therefore available under the GNU General Public   }
{  License, version 3, with the additional terms of the Doom 3 Source Code     }
{  License (see README.md of Libs\IdLib); the repository as a whole is GPL v2  }
{  or later.                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.Blend.Types;

interface

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.Models.Anim.Types,
  DelphiDoom.Models.Anim.Intf;

const
  /// <summary>ANIM_MaxAnimsPerChannel: the animations a channel keeps (the current and the ones it fades out)</summary>
  ANIM_MAX_ANIMS_PER_CHANNEL = 3;
  /// <summary>TH_ANIMATE: the entity runs its animation every frame</summary>
  ANIM_THINK_ANIMATE = 4;
  /// <summary>TH_UPDATEVISUALS: the entity updates its render entity</summary>
  ANIM_THINK_UPDATE_VISUALS = 8;

type
  /// <summary>
  ///   A random number in [0, 1) (<c>gameLocal.random.RandomFloat</c>): the animation that starts
  ///   at a random time asks for it
  /// </summary>
  TAnimRandomFloat = reference to function: Single;

  /// <summary>jointModTransform_t</summary>
  TAnimJointModTransform = (jmNone, jmLocal, jmLocalOverride, jmWorld, jmWorldOverride);

  /// <summary>jointMod_t: a change that the game makes to the pose of a joint</summary>
  TAnimJointMod = record
    JointNum: Integer;
    Mat: TIdMat3;
    Pos: TIdVec3;
    TransformPos: TAnimJointModTransform;
    TransformAxis: TAnimJointModTransform;
  end;

  /// <summary>AFJointModType_t</summary>
  TAnimAfJointModType = (afAxis, afOrigin, afBoth);

  /// <summary>idAFPoseJointMod: what an articulated figure imposes on a joint</summary>
  TAnimAfPoseJointMod = record
    Kind: TAnimAfJointModType;
    Axis: TIdMat3;
    Origin: TIdVec3;
  end;

  /// <summary>
  ///   Where the commands of the frames go (the entity that <c>idAnim::CallFrameCommands</c> calls).
  ///   The animator does not run them: it hands every command to the game.
  /// </summary>
  IAnimFrameCommandSink = interface
    ['{6D3B9E52-0A74-4C18-B5E1-93F72A8C40D6}']
    /// <summary>One command of a frame (zero based) of an animation</summary>
    procedure CallFrameCommand(const AAnim: IAnim; const AFrame: Integer; const ACommand: TAnimFrameCommand);
  end;

  /// <summary>
  ///   The entity that owns an animator (idEntity as the animator uses it): it receives the frame
  ///   commands and is told when it has to run or to stop running the animation
  /// </summary>
  IAnimatorEntity = interface(IAnimFrameCommandSink)
    ['{B27E5D90-C316-4F8A-9D04-1A6E73F8B52C}']
    /// <summary>BecomeActive with one of the ANIM_THINK_* flags</summary>
    procedure BecomeActive(const AFlags: Integer);
    /// <summary>BecomeInactive with one of the ANIM_THINK_* flags</summary>
    procedure BecomeInactive(const AFlags: Integer);
  end;

/// <summary>FRAME2MS: milliseconds of a frame number at the fixed 24 frames per second</summary>
function AnimFrameToMilliseconds(const AFrameNumber: Integer): Integer;

implementation

function AnimFrameToMilliseconds(const AFrameNumber: Integer): Integer;
begin
  Result := (AFrameNumber * 1000) div 24;
end;

end.
