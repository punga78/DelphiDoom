{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the default texture axes of a plane          }
{                                                                              }
{  Port of ComputeAxisBase (MapFile.cpp, idlib), Doom 3 GPL Source Code.       }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.TextureAxis;

interface

uses
  DelphiDoom.Geometry.Vec3;

type
  /// <summary>The planar texture axes the texture matrix of a brush side is relative to</summary>
  TMapTextureAxis = class
  public
    /// <summary>
    ///   The S and T axes of a plane with the given normal (ComputeAxisBase). The original uses
    ///   the double functions of the C library on floats; the results are the same up to the
    ///   last bit of the float
    /// </summary>
    class procedure ComputeAxisBase(const ANormal: TGeoVec3; out ATexS, ATexT: TGeoVec3); static;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Math;

const
  CLEAN_EPSILON: Single = 1e-6;

{ TMapTextureAxis }

class procedure TMapTextureAxis.ComputeAxisBase(const ANormal: TGeoVec3; out ATexS, ATexT: TGeoVec3);
var
  LRotY, LRotZ: Single;
  LSinY, LCosY, LSinZ, LCosZ: Single;
  LNormal: array[0..2] of Single;
  LIndex: Integer;
  LRadius: Single;
begin
  // do some cleaning
  for LIndex := 0 to 2 do
  begin
    if TIdMath.Fabs(ANormal[LIndex]) < CLEAN_EPSILON then
      LNormal[LIndex] := 0
    else
      LNormal[LIndex] := ANormal[LIndex];
  end;
  LRadius := TIdMath.Sqrt(LNormal[1] * LNormal[1] + LNormal[0] * LNormal[0]);
  // the angles are floats in the original: that is what makes cos(pi/2) a small number, not zero
  LRotY := -ArcTan2(LNormal[2], LRadius);
  LRotZ := ArcTan2(LNormal[1], LNormal[0]);
  LSinY := Sin(LRotY);
  LCosY := Cos(LRotY);
  LSinZ := Sin(LRotZ);
  LCosZ := Cos(LRotZ);
  // rotate (0,1,0) and (0,0,1) to compute texS and texT
  ATexS.X := -LSinZ;
  ATexS.Y := LCosZ;
  ATexS.Z := 0;
  // the texT vector is along -Z (the T texture coordinates axis)
  ATexT.X := -LSinY * LCosZ;
  ATexT.Y := -LSinY * LSinZ;
  ATexT.Z := -LCosY;
end;

end.
