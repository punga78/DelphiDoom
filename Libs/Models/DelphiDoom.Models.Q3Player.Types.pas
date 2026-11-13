{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, shared types       }
{                                                                              }
{  Port of the structures of cgame\cg_local.h, game\bg_public.h and            }
{  game\q_shared.h (animation_t, lerpFrame_t, playerEntity_t, orientation_t,   }
{  refEntity_t). Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Types;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3;

const
  /// <summary>The animations of animation.cfg (MAX_ANIMATIONS)</summary>
  Q3_MAX_ANIMATIONS = 31;
  /// <summary>The animations including the derived ones (MAX_TOTALANIMATIONS)</summary>
  Q3_MAX_TOTAL_ANIMATIONS = 37;
  /// <summary>The bit that the game flips every time an animation restarts (ANIM_TOGGLEBIT)</summary>
  Q3_ANIM_TOGGLEBIT = 128;
  /// <summary>PAIN_TWITCH_TIME: the milliseconds of the twitch of the torso</summary>
  Q3_PAIN_TWITCH_TIME = 200;

  // animNumber_t
  Q3_BOTH_DEATH1 = 0;
  Q3_BOTH_DEAD1 = 1;
  Q3_BOTH_DEATH2 = 2;
  Q3_BOTH_DEAD2 = 3;
  Q3_BOTH_DEATH3 = 4;
  Q3_BOTH_DEAD3 = 5;
  Q3_TORSO_GESTURE = 6;
  Q3_TORSO_ATTACK = 7;
  Q3_TORSO_ATTACK2 = 8;
  Q3_TORSO_DROP = 9;
  Q3_TORSO_RAISE = 10;
  Q3_TORSO_STAND = 11;
  Q3_TORSO_STAND2 = 12;
  Q3_LEGS_WALKCR = 13;
  Q3_LEGS_WALK = 14;
  Q3_LEGS_RUN = 15;
  Q3_LEGS_BACK = 16;
  Q3_LEGS_SWIM = 17;
  Q3_LEGS_JUMP = 18;
  Q3_LEGS_LAND = 19;
  Q3_LEGS_JUMPB = 20;
  Q3_LEGS_LANDB = 21;
  Q3_LEGS_IDLE = 22;
  Q3_LEGS_IDLECR = 23;
  Q3_LEGS_TURN = 24;
  Q3_TORSO_GETFLAG = 25;
  Q3_TORSO_GUARDBASE = 26;
  Q3_TORSO_PATROL = 27;
  Q3_TORSO_FOLLOWME = 28;
  Q3_TORSO_AFFIRMATIVE = 29;
  Q3_TORSO_NEGATIVE = 30;
  // the animations that the parser derives (after MAX_ANIMATIONS)
  Q3_LEGS_BACKCR = 32;
  Q3_LEGS_BACKWALK = 33;
  Q3_FLAG_RUN = 34;
  Q3_FLAG_STAND = 35;
  Q3_FLAG_STAND2RUN = 36;

type
  /// <summary>footstep_t: the sounds of the steps</summary>
  TQ3Footsteps = (qfNormal = 0, qfBoot = 1, qfFlesh = 2, qfMech = 3, qfEnergy = 4, qfMetal = 5, qfSplash = 6);

  /// <summary>gender_t</summary>
  TQ3Gender = (qgMale = 0, qgFemale = 1, qgNeuter = 2);

  /// <summary>animation_t: a sequence of frames of the model</summary>
  TQ3Animation = record
    FirstFrame: Integer;
    NumFrames: Integer;
    /// <summary>0 to NumFrames: how many of the last frames loop (0: the animation stops at the end)</summary>
    LoopFrames: Integer;
    /// <summary>The milliseconds between two frames</summary>
    FrameLerp: Integer;
    /// <summary>The milliseconds to get to the first frame</summary>
    InitialLerp: Integer;
    Reversed: Boolean;
    Flipflop: Boolean;
  end;

  /// <summary>
  ///   lerpFrame_t: the state of one level of the animation (legs, torso). The "animation_t *" of
  ///   the original is the index into the animations of the configuration.
  /// </summary>
  TQ3LerpFrame = record
    OldFrame: Integer;
    /// <summary>The time when OldFrame was exactly on</summary>
    OldFrameTime: Integer;
    Frame: Integer;
    /// <summary>The time when Frame will be exactly on</summary>
    FrameTime: Integer;
    /// <summary>The weight of OldFrame in the interpolation, 0 to 1</summary>
    BackLerp: Single;
    YawAngle: Single;
    Yawing: Boolean;
    PitchAngle: Single;
    Pitching: Boolean;
    /// <summary>May include Q3_ANIM_TOGGLEBIT</summary>
    AnimationNumber: Integer;
    /// <summary>False until an animation is set (the null pointer of the original)</summary>
    HasAnimation: Boolean;
    /// <summary>The index of the current animation, valid if HasAnimation</summary>
    AnimationIndex: Integer;
    /// <summary>The time when the first frame of the animation will be exact</summary>
    AnimationTime: Integer;
  end;

  /// <summary>playerEntity_t, the part that the animation and the angles read and write</summary>
  TQ3PlayerEntity = record
    Legs: TQ3LerpFrame;
    Torso: TQ3LerpFrame;
    Flag: TQ3LerpFrame;
    PainTime: Integer;
    /// <summary>Flips from 0 to 1</summary>
    PainDirection: Integer;
  end;

  /// <summary>vec3_t axis[3]: the three axes of an orientation, one vector each</summary>
  TQ3Axis = array[0..2] of TIdVec3;

  /// <summary>orientation_t: a point and the three axes of a tag</summary>
  TQ3Orientation = record
    Origin: TIdVec3;
    Axis: TQ3Axis;
  end;

  /// <summary>The part of refEntity_t that places a model on a tag: origin, axes and frames</summary>
  TQ3Entity = record
    Origin: TIdVec3;
    Axis: TQ3Axis;
    OldFrame: Integer;
    Frame: Integer;
    BackLerp: Single;
  end;

  /// <summary>The frames that CG_PlayerAnimation gives for the two levels of the model</summary>
  TQ3PlayerFrames = record
    LegsOld: Integer;
    Legs: Integer;
    LegsBackLerp: Single;
    TorsoOld: Integer;
    Torso: Integer;
    TorsoBackLerp: Single;
  end;

  /// <summary>
  ///   What CG_PlayerAngles reads of the entity: the angles of the view, the animations, whether
  ///   it is dead, the direction of the movement (angles2[YAW], 0 to 7) and the velocity
  /// </summary>
  TQ3PlayerAngleInput = record
    LerpAngles: TIdVec3;
    LegsAnim: Integer;
    TorsoAnim: Integer;
    Dead: Boolean;
    MovementDirection: Single;
    Velocity: TIdVec3;
    /// <summary>cg.time and cg.frametime, in milliseconds</summary>
    Time: Integer;
    FrameTime: Integer;
  end;

  /// <summary>Raised when a player model cannot be configured or posed; Line is the line of the text, 0 if there is none</summary>
  EQ3PlayerException = class(Exception)
  strict private
    FLine: Integer;
  public
    constructor CreateAtLine(const AMessage: string; const ALine: Integer);
    property Line: Integer read FLine;
  end;

  /// <summary>The animation file is missing or empty (the original returns false without a message)</summary>
  EQ3AnimationMissingException = class(EQ3PlayerException);

resourcestring
  SQ3AnimationMissing = 'The animation file %s is missing or empty';
  SQ3AnimationTooLong = 'File %s too long';
  SQ3AnimationParse = 'Error parsing animation file: %s';
  SQ3AnimationHeaderEnd = 'The animation file %s ends before the first animation (the original loops forever)';
  SQ3BadFootsteps = 'Bad footsteps parm in %s: %s';
  SQ3UnknownToken = 'unknown token ''%s'' is %s';
  SQ3BadAnimationNumber = 'Bad animation number: %d';
  SQ3BadMovementAngle = 'Bad player movement angle';
  SQ3BadFrame = 'The frame %d does not exist';
  SQ3AngleOutOfRange = 'The angle %g is too large to be reduced to a turn';

implementation

constructor EQ3PlayerException.CreateAtLine(const AMessage: string; const ALine: Integer);
begin
  inherited Create(AMessage);
  FLine := ALine;
end;

end.
