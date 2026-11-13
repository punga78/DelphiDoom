{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing a brush in the format of Quake III   }
{                                                                              }
{  Written for this library as the inverse of idMapBrush::ParseQ3 (MapFile.cpp)}
{  of the Doom 3 GPL Source Code and of the brushes of GtkRadiant for Quake    }
{  III Arena: three points, the material, shift, rotation, scale and the       }
{  three numbers of the contents.                                              }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Q3BrushWriter;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.MapFile.Brush, DelphiDoom.MapFile.TextWriter;

type
  /// <summary>
  ///   Writes the sides of a brush as three points each. What the model does not keep is
  ///   written neutral: the reader of Quake 3 brushes drops shift, rotation and scale (the
  ///   texture matrix is the fixed scale 1/32), so the writer gives 0 0 0 and the scale 0.5 0.5
  ///   of the editor, and no contents. A plane has no points of its own: three are made on it,
  ///   at a distance of 64 along two axes of the plane, so that <c>idPlane::FromPoints</c> gives
  ///   the same plane back exactly for the planes of the axes and within the precision of ten
  ///   decimals for any other
  /// </summary>
  TMapQ3BrushWriter = class
  strict private
    class procedure AddPoint(const AOutput: TMapTextWriter; const APoint: TGeoVec3); static;
    class function Material(const AName: AnsiString): AnsiString; static;
  public
    /// <summary>
    ///   The three points of a plane in the order that <c>FromPoints</c> turns into its normal
    ///   (the original takes (p1 - p2) x (p3 - p2)); <c>AOrigin</c> is added to them
    /// </summary>
    class procedure PlanePoints(const APlane: TGeoPlane; const AOrigin: TGeoVec3;
      out APoint1, APoint2, APoint3: TGeoVec3); static;
    /// <summary>
    ///   The "// brush N" comment and the brush; the origin of each side is added to its points
    ///   (the reader takes the origin of the entity off). The pairs of the brush are not written
    /// </summary>
    class procedure Write(const AOutput: TMapTextWriter; const ABrush: TMapBrush;
      const ABrushNumber: Integer); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.BrushSide;

const
  POINT_DISTANCE = 64;
  TEXTURES_PREFIX: AnsiString = 'textures/';

{ TMapQ3BrushWriter }

class procedure TMapQ3BrushWriter.AddPoint(const AOutput: TMapTextWriter; const APoint: TGeoVec3);
begin
  AOutput.Add('( ');
  AOutput.AddFloat(APoint.X);
  AOutput.Add(' ');
  AOutput.AddFloat(APoint.Y);
  AOutput.Add(' ');
  AOutput.AddFloat(APoint.Z);
  AOutput.Add(' ) ');
end;

class function TMapQ3BrushWriter.Material(const AName: AnsiString): AnsiString;
begin
  // the reader puts "textures/" in front of every material of this format
  if SameText(string(Copy(AName, 1, Length(TEXTURES_PREFIX))), string(TEXTURES_PREFIX)) then
    Result := Copy(AName, Length(TEXTURES_PREFIX) + 1, MaxInt)
  else
    Result := AName;
end;

class procedure TMapQ3BrushWriter.PlanePoints(const APlane: TGeoPlane; const AOrigin: TGeoVec3;
  out APoint1, APoint2, APoint3: TGeoVec3);
var
  LNormal, LAxis, LFirst, LSecond: TGeoVec3;
  LBest: Integer;
begin
  LNormal := APlane.Normal;
  // the axis the normal is least aligned with
  LBest := 0;
  if Abs(LNormal.Y) < Abs(LNormal.Items[LBest]) then
    LBest := 1;
  if Abs(LNormal.Z) < Abs(LNormal.Items[LBest]) then
    LBest := 2;
  LAxis := TGeoVec3.Origin;
  LAxis.Items[LBest] := 1;
  LFirst := LNormal.Cross(LAxis);
  LFirst.NormalizeSelf;
  // first x second = normal
  LSecond := LNormal.Cross(LFirst);
  APoint2 := LNormal * APlane.Dist + AOrigin;
  APoint1 := APoint2 + LFirst * POINT_DISTANCE;
  APoint3 := APoint2 + LSecond * POINT_DISTANCE;
end;

class procedure TMapQ3BrushWriter.Write(const AOutput: TMapTextWriter; const ABrush: TMapBrush;
  const ABrushNumber: Integer);
var
  LIndex: Integer;
  LSide: TMapBrushSide;
  LPoint1, LPoint2, LPoint3: TGeoVec3;
begin
  AOutput.Add('// brush ');
  AOutput.AddInteger(ABrushNumber);
  AOutput.Add(#10'{'#10);
  for LIndex := 0 to ABrush.GetNumSides - 1 do
  begin
    LSide := ABrush.GetSide(LIndex);
    PlanePoints(LSide.Plane, LSide.Origin, LPoint1, LPoint2, LPoint3);
    AddPoint(AOutput, LPoint1);
    AddPoint(AOutput, LPoint2);
    AddPoint(AOutput, LPoint3);
    AOutput.Add(Material(LSide.Material) + ' 0 0 0 0.5 0.5 0 0 0'#10);
  end;
  AOutput.Add('}'#10);
end;

end.
