{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5 (idTech 4): shared constants and types  }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.h,        }
{  game\anim\Anim.h. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media  }
{  company. This unit is derived from the Doom 3 GPL source code and is        }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.Types;

interface

const
  /// <summary>The first word of an MD5 file (MD5_VERSION_STRING)</summary>
  MD5_VERSION_STRING = 'MD5Version';
  /// <summary>The only version of the format that the engine reads (MD5_VERSION)</summary>
  MD5_VERSION = 10;

  /// <summary>Animation bits of a joint: the component is animated (ANIM_TX..ANIM_QZ)</summary>
  ANIM_TX = 1 shl 0;
  ANIM_TY = 1 shl 1;
  ANIM_TZ = 1 shl 2;
  ANIM_QX = 1 shl 3;
  ANIM_QY = 1 shl 4;
  ANIM_QZ = 1 shl 5;
  /// <summary>The translation bits together</summary>
  ANIM_TRANSLATION = ANIM_TX or ANIM_TY or ANIM_TZ;
  /// <summary>The rotation bits together</summary>
  ANIM_ROTATION = ANIM_QX or ANIM_QY or ANIM_QZ;

  /// <summary>The handle returned for an unknown joint name (INVALID_JOINT)</summary>
  MD5_INVALID_JOINT = -1;
  /// <summary>The name of an invalid joint handle</summary>
  MD5_INVALID_JOINT_NAME = '<invalid joint>';

type
  /// <summary>A joint of the skeleton of a model (idMD5Joint): its name and the index of the parent, -1 for the root</summary>
  TMd5Joint = record
    Name: AnsiString;
    Parent: Integer;
  end;

  /// <summary>Which two frames to blend and how much (frameBlend_t)</summary>
  TMd5FrameBlend = record
    CycleCount: Integer;
    Frame1: Integer;
    Frame2: Integer;
    FrontLerp: Single;
    BackLerp: Single;
  end;

  /// <summary>How a joint is animated (jointAnimInfo_t without the name index: the name is a string)</summary>
  TMd5AnimJointInfo = record
    Name: AnsiString;
    ParentNum: Integer;
    AnimBits: Integer;
    FirstComponent: Integer;
  end;

resourcestring
  SMd5InvalidJointIndex = 'MD5 skeleton: the joint %d does not exist (%d joints)';
  SMd5InvalidParent = 'MD5 skeleton: the parent %d of the joint %d is not before it';
  SMd5ArrayLength = 'MD5 skeleton: %d joints expected, %d given';
  SMd5InvalidAnimData = 'MD5 animation: inconsistent data (frames, joints, frame rate or components)';
  SMd5InvalidMesh = 'MD5 model: the mesh %d does not exist (%d meshes)';
  SMd5InvalidFrame = 'MD5 animation: the frame %d does not exist (%d frames)';

implementation

end.
