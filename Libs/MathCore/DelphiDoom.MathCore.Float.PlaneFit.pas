{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdPlaneFit, a plane fitted to a    }
{  set of points                                                               }
{                                                                              }
{  Port of idPlane::HeightFit (idlib\math\Plane.cpp) of the Doom 3 GPL Source  }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.PlaneFit;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Vec3;

type
  /// <summary>
  ///   <c>idPlane::HeightFit</c> as a function over <c>TGeoPlane</c> of <c>Libs\Geometry</c>: the
  ///   plane is a member of that library, which cannot depend on <c>TIdMat2</c> of MathCore.
  /// </summary>
  TIdPlaneFit = class sealed
  public
    /// <summary>
    ///   Fits the plane z = -(a x + b y + d) / c to the points by least squares (c = 1 before
    ///   the normalization); false when the points give a singular system (for example on
    ///   a vertical line)
    /// </summary>
    class function HeightFit(var APlane: TGeoPlane; const APoints: array of TGeoVec3): Boolean; static;
  end;

implementation

uses
  DelphiDoom.MathCore.Float.Mat2;

{ TIdPlaneFit }

class function TIdPlaneFit.HeightFit(var APlane: TGeoPlane;
  const APoints: array of TGeoVec3): Boolean;
var
  LIndex, LCount: Integer;
  LSumXX, LSumXY, LSumXZ, LSumYY, LSumYZ: Single;
  LSum, LAverage, LDirection, LNormal: TGeoVec3;
  LMatrix: TIdMat2;
  LInverseCount: Single;
begin
  LCount := Length(APoints);
  if LCount = 1 then
  begin
    APlane.A := 0.0;
    APlane.B := 0.0;
    APlane.C := 1.0;
    APlane.D := -APoints[0].Z;
    Exit(True);
  end;
  if LCount = 2 then
  begin
    LDirection := APoints[1] - APoints[0];
    LNormal := LDirection.Cross(TGeoVec3.Make(0.0, 0.0, 1.0)).Cross(LDirection);
    APlane.SetNormal(LNormal);
    APlane.NormalizeSelf;
    APlane.D := -(APlane.Normal.Dot(APoints[0]));
    Exit(True);
  end;
  LSumXX := 0.0;
  LSumXY := 0.0;
  LSumXZ := 0.0;
  LSumYY := 0.0;
  LSumYZ := 0.0;
  LSum.Zero;
  for LIndex := 0 to LCount - 1 do
  begin
    LSum := LSum + APoints[LIndex];
  end;
  // idVec3 / int divides by multiplying with the reciprocal of the count
  LInverseCount := 1.0 / LCount;
  LAverage := LSum * LInverseCount;
  for LIndex := 0 to LCount - 1 do
  begin
    LDirection := APoints[LIndex] - LAverage;
    LSumXX := LSumXX + LDirection.X * LDirection.X;
    LSumXY := LSumXY + LDirection.X * LDirection.Y;
    LSumXZ := LSumXZ + LDirection.X * LDirection.Z;
    LSumYY := LSumYY + LDirection.Y * LDirection.Y;
    LSumYZ := LSumYZ + LDirection.Y * LDirection.Z;
  end;
  LMatrix := TIdMat2.Create(LSumXX, LSumXY, LSumXY, LSumYY);
  if not LMatrix.InverseSelf then
    Exit(False);
  APlane.A := -LSumXZ * LMatrix.Rows[0].X - LSumYZ * LMatrix.Rows[0].Y;
  APlane.B := -LSumXZ * LMatrix.Rows[1].X - LSumYZ * LMatrix.Rows[1].Y;
  APlane.C := 1.0;
  APlane.NormalizeSelf;
  APlane.D := -(APlane.A * LAverage.X + APlane.B * LAverage.Y + APlane.C * LAverage.Z);
  Result := True;
end;

end.
