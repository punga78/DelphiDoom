{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdBoxFit, the tight box of a set   }
{  of points                                                                   }
{                                                                              }
{  Port of idBox::FromPoints (idlib\bv\Box.cpp) of the Doom 3 GPL Source Code. }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.BoxFit;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Box, DelphiDoom.Geometry.Vec3;

type
  /// <summary>
  ///   <c>idBox::FromPoints</c> as a function over <c>TGeoBox</c> of <c>Libs\Geometry</c>: the
  ///   box is a type of that library, which cannot depend on the eigenvector solver of MathCore.
  ///   The axes are the eigenvectors of the covariance matrix of the points, then the center
  ///   and the extents are refined with the bounds of the points projected onto the axes.
  /// </summary>
  TIdBoxFit = class sealed
  public
    /// <summary>The tight box of the points (at least one); false if the eigenvalue solver does not converge</summary>
    class function FromPoints(var ABox: TGeoBox; const APoints: array of TGeoVec3): Boolean; static;
  end;

implementation

uses
  DelphiDoom.Geometry.Bounds, DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.MatX.Eigen,
  DelphiDoom.MathCore.Float.VecX;

{ TIdBoxFit }

class function TIdBoxFit.FromPoints(var ABox: TGeoBox; const APoints: array of TGeoVec3): Boolean;
var
  LIndex, LCount, LRow, LColumn: Integer;
  LInverseCount, LSumXX, LSumXY, LSumXZ, LSumYY, LSumYZ, LSumZZ: Single;
  LDirection, LCenter: TGeoVec3;
  LBounds: TGeoBounds;
  LEigenVectors: TIdMatX;
  LEigenValues: TIdVecX;
begin
  LCount := Length(APoints);
  // compute mean of points
  LCenter := APoints[0];
  for LIndex := 1 to LCount - 1 do
  begin
    LCenter := LCenter + APoints[LIndex];
  end;
  LInverseCount := 1.0 / LCount;
  LCenter := LCenter * LInverseCount;
  // compute covariances of points
  LSumXX := 0.0;
  LSumXY := 0.0;
  LSumXZ := 0.0;
  LSumYY := 0.0;
  LSumYZ := 0.0;
  LSumZZ := 0.0;
  for LIndex := 0 to LCount - 1 do
  begin
    LDirection := APoints[LIndex] - LCenter;
    LSumXX := LSumXX + LDirection.X * LDirection.X;
    LSumXY := LSumXY + LDirection.X * LDirection.Y;
    LSumXZ := LSumXZ + LDirection.X * LDirection.Z;
    LSumYY := LSumYY + LDirection.Y * LDirection.Y;
    LSumYZ := LSumYZ + LDirection.Y * LDirection.Z;
    LSumZZ := LSumZZ + LDirection.Z * LDirection.Z;
  end;
  LSumXX := LSumXX * LInverseCount;
  LSumXY := LSumXY * LInverseCount;
  LSumXZ := LSumXZ * LInverseCount;
  LSumYY := LSumYY * LInverseCount;
  LSumYZ := LSumYZ * LInverseCount;
  LSumZZ := LSumZZ * LInverseCount;
  // compute eigenvectors for covariance matrix
  LEigenValues := TIdVecX.Create(3);
  LEigenVectors := TIdMatX.Create(3, 3);
  try
    LEigenVectors[0, 0] := LSumXX;
    LEigenVectors[0, 1] := LSumXY;
    LEigenVectors[0, 2] := LSumXZ;
    LEigenVectors[1, 0] := LSumXY;
    LEigenVectors[1, 1] := LSumYY;
    LEigenVectors[1, 2] := LSumYZ;
    LEigenVectors[2, 0] := LSumXZ;
    LEigenVectors[2, 1] := LSumYZ;
    LEigenVectors[2, 2] := LSumZZ;
    // the original ignores the result of the solver
    Result := TIdMatXEigen.SolveSymmetric(LEigenVectors, LEigenValues);
    TIdMatXEigen.SortIncreasing(LEigenVectors, LEigenValues);
    for LRow := 0 to 2 do
    begin
      for LColumn := 0 to 2 do
      begin
        ABox.Axis.Rows[LRow][LColumn] := LEigenVectors[LRow, LColumn];
      end;
    end;
    ABox.Extents := TGeoVec3.Make(LEigenValues[0], LEigenValues[0], LEigenValues[0]);
  finally
    LEigenVectors.Free;
    LEigenValues.Free;
  end;
  // refine by calculating the bounds of the points projected onto the axis and adjusting the
  // center and extents
  LBounds.Clear;
  for LIndex := 0 to LCount - 1 do
  begin
    LBounds.AddPoint(TGeoVec3.Make(APoints[LIndex].Dot(ABox.Axis.Rows[0]),
      APoints[LIndex].Dot(ABox.Axis.Rows[1]), APoints[LIndex].Dot(ABox.Axis.Rows[2])));
  end;
  LCenter := (LBounds.Mins + LBounds.Maxs) * 0.5;
  ABox.Extents := LBounds.Maxs - LCenter;
  ABox.Center := LCenter * ABox.Axis;
end;

end.
