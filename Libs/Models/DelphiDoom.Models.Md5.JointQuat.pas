{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: the pose of a joint (quaternion)       }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): idlib\geometry\          }
{  JointTransform.h (idJointQuat). Copyright (C) 1999-2011 id Software LLC, a  }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source code }
{  and is therefore available under the GNU General Public License, version 3, }
{  with the additional terms of the Doom 3 Source Code License (see README.md  }
{  of Libs\IdLib); the repository as a whole is GPL v2 or later.               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.JointQuat;

interface

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Quat;

type
  /// <summary>The rotation and the translation of a joint, relative to its parent (idJointQuat)</summary>
  TMd5JointQuat = record
    Q: TIdQuat;
    T: TIdVec3;
  end;

implementation

end.
