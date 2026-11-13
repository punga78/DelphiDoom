{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdJointQuat, the joint quaternion  }
{                                                                              }
{  Port of idJointQuat (idlib\geometry\JointTransform.h) of the Doom 3 GPL     }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.JointQuat;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Quat;

type
  /// <summary>The transform of a skeleton joint as a rotation and a translation (idJointQuat), 28 bytes</summary>
  TIdJointQuat = record
    Q: TIdQuat;
    T: TIdVec3;
  end;

implementation

end.
