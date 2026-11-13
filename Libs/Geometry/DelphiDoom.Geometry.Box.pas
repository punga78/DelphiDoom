{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the oriented box (idBox)                     }
{                                                                              }
{  Port of idBox (idlib\bv\Box.h and Box.cpp) of the Doom 3 GPL Source Code.   }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based     }
{  on the Doom 3 GPL Source Code (id Software).                                }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Box;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Sphere;

type
  /// <summary>
  ///   An oriented bounding box (idBox): centre, half sizes along the axes and the axes as
  ///   rows of a matrix (60 bytes). Negative extents are the cleared (inside out) box.
  ///   Not ported: <c>FromPoints</c> (principal axes of the point set: needs idMatX, the
  ///   eigenvalue solver of MathCore is not done), and <c>FromPointTranslation</c>,
  ///   <c>FromBoxTranslation</c>, <c>FromPointRotation</c>, <c>FromBoxRotation</c>, which are
  ///   empty "FIXME: implement" functions in the original.
  /// </summary>
  TGeoBox = record
    Center: TGeoVec3;
    Extents: TGeoVec3;
    Axis: TGeoMat3;
  public
    class function Make(const ACenter, AExtents: TGeoVec3; const AAxis: TGeoMat3): TGeoBox; overload; static;
    /// <summary>A box of size zero at the point, axes aligned</summary>
    class function Make(const APoint: TGeoVec3): TGeoBox; overload; static;
    /// <summary>The box of an axis aligned box</summary>
    class function Make(const ABounds: TGeoBounds): TGeoBox; overload; static;
    /// <summary>The box of a box moved by an origin and an axis</summary>
    class function Make(const ABounds: TGeoBounds; const AOrigin: TGeoVec3; const AAxis: TGeoMat3): TGeoBox;
      overload; static;
    /// <summary>Inside out box: extents -1e30, axes the identity</summary>
    procedure Clear;
    procedure Zero;
    function IsCleared: Boolean;
    function Compare(const ABox: TGeoBox): Boolean; overload;
    function Compare(const ABox: TGeoBox; AEpsilon: Single): Boolean; overload;
    /// <summary>
    ///   What the original calls the volume: the squared length of the full size vector
    ///   ((extents * 2).LengthSqr()), which is not a volume. Kept because AddPoint and AddBox
    ///   choose between candidate boxes with it
    /// </summary>
    function GetVolume: Single;
    /// <summary>Grows the box to contain the point; true when it grew</summary>
    function AddPoint(const APoint: TGeoVec3): Boolean;
    /// <summary>
    ///   Grows the box to contain the other box. The original returns false when the result is a
    ///   new box built from the best of four axis pairs although it did grow: kept
    /// </summary>
    function AddBox(const ABox: TGeoBox): Boolean;
    function Expand(ADelta: Single): TGeoBox;
    procedure ExpandSelf(ADelta: Single);
    function Translate(const ATranslation: TGeoVec3): TGeoBox;
    procedure TranslateSelf(const ATranslation: TGeoVec3);
    /// <summary>Centre and axes rotated by the matrix</summary>
    function Rotate(const ARotation: TGeoMat3): TGeoBox;
    procedure RotateSelf(const ARotation: TGeoMat3);
    function PlaneDistance(const APlane: TGeoPlane): Single;
    /// <summary>PLANESIDE_FRONT, _BACK or _CROSS</summary>
    function PlaneSide(const APlane: TGeoPlane; AEpsilon: Single = 0.1): Integer;
    /// <summary>Includes touching</summary>
    function ContainsPoint(const APoint: TGeoVec3): Boolean;
    /// <summary>Separating axis test of the two boxes, includes touching</summary>
    function IntersectsBox(const ABox: TGeoBox): Boolean;
    function LineIntersection(const AStart, AEnd: TGeoVec3): Boolean;
    /// <summary>
    ///   The ray meets the box at start + dir * scale1 and start + dir * scale2 in both
    ///   directions from the start (scale1 &lt; 0 when the start is inside)
    /// </summary>
    function RayIntersection(const AStart, ADir: TGeoVec3; out AScale1, AScale2: Single): Boolean;
    /// <summary>The eight corners, in the order of idBox::ToPoints; APoints has at least eight items</summary>
    procedure ToPoints(var APoints: array of TGeoVec3);
    function ToSphere: TGeoSphere;
    /// <summary>The interval the box covers along the direction</summary>
    procedure AxisProjection(const ADir: TGeoVec3; out AMin, AMax: Single); overload;
    /// <summary>The bounds of the box projected on the three axes of the matrix</summary>
    procedure AxisProjection(const AAxis: TGeoMat3; out ABounds: TGeoBounds); overload;
    /// <summary>
    ///   Silhouette of the box seen from a point: up to six corners, in order. Returns the count
    ///   (0 when the point is inside the box); ASilVerts needs six items
    /// </summary>
    function GetProjectionSilhouetteVerts(const AProjectionOrigin: TGeoVec3; var ASilVerts: array of TGeoVec3): Integer;
    /// <summary>The same for a parallel projection along a direction</summary>
    function GetParallelProjectionSilhouetteVerts(const AProjectionDir: TGeoVec3;
      var ASilVerts: array of TGeoVec3): Integer;
  end;

implementation

uses
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath;

const
  // boxPlaneBitsSilVerts: per set of seen planes the count and the corners of the silhouette
  BOX_PLANE_BITS_SIL_VERTS: array[0..63, 0..6] of Integer = (
    (0,0,0,0,0,0,0),
    (4,7,4,0,3,0,0),
    (4,5,6,2,1,0,0),
    (0,0,0,0,0,0,0),
    (4,4,5,1,0,0,0),
    (6,3,7,4,5,1,0),
    (6,4,5,6,2,1,0),
    (0,0,0,0,0,0,0),
    (4,6,7,3,2,0,0),
    (6,6,7,4,0,3,2),
    (6,5,6,7,3,2,1),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (4,0,1,2,3,0,0),
    (6,0,1,2,3,7,4),
    (6,3,2,6,5,1,0),
    (0,0,0,0,0,0,0),
    (6,1,2,3,0,4,5),
    (6,1,2,3,7,4,5),
    (6,2,3,0,4,5,6),
    (0,0,0,0,0,0,0),
    (6,0,1,2,6,7,3),
    (6,0,1,2,6,7,4),
    (6,0,1,5,6,7,3),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (4,7,6,5,4,0,0),
    (6,7,6,5,4,0,3),
    (6,5,4,7,6,2,1),
    (0,0,0,0,0,0,0),
    (6,4,7,6,5,1,0),
    (6,3,7,6,5,1,0),
    (6,4,7,6,2,1,0),
    (0,0,0,0,0,0,0),
    (6,6,5,4,7,3,2),
    (6,6,5,4,0,3,2),
    (6,5,4,7,3,2,1),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0)
  );

function Min3Index(AX, AY, AZ: Single): Integer;
begin
  // template Min3Index of idlib, with strict comparisons
  if AX < AY then
  begin
    if AX < AZ then
      Result := 0
    else
      Result := 2;
  end
  else if AY < AZ then
    Result := 1
  else
    Result := 2;
end;

// FLOATNOTZERO: any bit but the sign
function FloatNotZero(AValue: Single): Boolean;
begin
  Result := (PCardinal(@AValue)^ and $7FFFFFFF) <> 0;
end;

function BoxPlaneClip(ADenominator, ANumerator: Single; var AScale0, AScale1: Single): Boolean;
begin
  if ADenominator > 0 then
  begin
    if ANumerator > ADenominator * AScale1 then
      Exit(False);
    if ANumerator > ADenominator * AScale0 then
      AScale0 := ANumerator / ADenominator;
    Result := True;
  end
  else if ADenominator < 0 then
  begin
    if ANumerator > ADenominator * AScale0 then
      Exit(False);
    if ANumerator > ADenominator * AScale1 then
      AScale1 := ANumerator / ADenominator;
    Result := True;
  end
  else
    Result := ANumerator <= 0;
end;

// the bounds of the centre projected on the axes, grown by the extents
function ProjectedBounds(const ACenter, AExtents: TGeoVec3; const AAxis: TGeoMat3): TGeoBounds;
var
  LValue: TGeoVec3;
begin
  LValue.SetValues(ACenter.Dot(AAxis.Rows[0]), ACenter.Dot(AAxis.Rows[1]), ACenter.Dot(AAxis.Rows[2]));
  Result.Mins := LValue - AExtents;
  Result.Maxs := LValue + AExtents;
end;

{ TGeoBox }

class function TGeoBox.Make(const ACenter, AExtents: TGeoVec3; const AAxis: TGeoMat3): TGeoBox;
begin
  Result.Center := ACenter;
  Result.Extents := AExtents;
  Result.Axis := AAxis;
end;

class function TGeoBox.Make(const APoint: TGeoVec3): TGeoBox;
begin
  Result.Center := APoint;
  Result.Extents.Zero;
  Result.Axis := TGeoMat3.Identity;
end;

class function TGeoBox.Make(const ABounds: TGeoBounds): TGeoBox;
begin
  Result.Center := (ABounds.Mins + ABounds.Maxs) * 0.5;
  Result.Extents := ABounds.Maxs - Result.Center;
  Result.Axis := TGeoMat3.Identity;
end;

class function TGeoBox.Make(const ABounds: TGeoBounds; const AOrigin: TGeoVec3; const AAxis: TGeoMat3): TGeoBox;
begin
  Result.Center := (ABounds.Mins + ABounds.Maxs) * 0.5;
  Result.Extents := ABounds.Maxs - Result.Center;
  Result.Center := AOrigin + Result.Center * AAxis;
  Result.Axis := AAxis;
end;

procedure TGeoBox.Clear;
begin
  Center.Zero;
  Extents.SetValues(-GEO_INFINITY, -GEO_INFINITY, -GEO_INFINITY);
  Axis := TGeoMat3.Identity;
end;

procedure TGeoBox.Zero;
begin
  Center.Zero;
  Extents.Zero;
  Axis := TGeoMat3.Identity;
end;

function TGeoBox.IsCleared: Boolean;
begin
  Result := Extents.X < 0;
end;

function TGeoBox.Compare(const ABox: TGeoBox): Boolean;
begin
  Result := Center.Compare(ABox.Center) and Extents.Compare(ABox.Extents) and Axis.Compare(ABox.Axis);
end;

function TGeoBox.Compare(const ABox: TGeoBox; AEpsilon: Single): Boolean;
begin
  Result := Center.Compare(ABox.Center, AEpsilon) and Extents.Compare(ABox.Extents, AEpsilon) and
    Axis.Compare(ABox.Axis, AEpsilon);
end;

function TGeoBox.GetVolume: Single;
begin
  Result := (Extents * 2.0).LengthSqr;
end;

function TGeoBox.AddPoint(const APoint: TGeoVec3): Boolean;
var
  LAxis2: TGeoMat3;
  LBounds1: TGeoBounds;
  LBounds2: TGeoBounds;
begin
  if Extents.X < 0 then
  begin
    Extents.Zero;
    Center := APoint;
    Axis := TGeoMat3.Identity;
    Exit(True);
  end;
  LBounds1 := ProjectedBounds(Center, Extents, Axis);
  if not LBounds1.AddPoint(TGeoVec3.Make(APoint.Dot(Axis.Rows[0]), APoint.Dot(Axis.Rows[1]),
    APoint.Dot(Axis.Rows[2]))) then
    // point is contained in the box
    Exit(False);
  LAxis2.Rows[0] := APoint - Center;
  LAxis2.Rows[0].NormalizeSelf;
  LAxis2.Rows[1] := Axis.Rows[Min3Index(LAxis2.Rows[0].Dot(Axis.Rows[0]), LAxis2.Rows[0].Dot(Axis.Rows[1]),
    LAxis2.Rows[0].Dot(Axis.Rows[2]))];
  LAxis2.Rows[1] := LAxis2.Rows[1] - LAxis2.Rows[1].Dot(LAxis2.Rows[0]) * LAxis2.Rows[0];
  LAxis2.Rows[1].NormalizeSelf;
  LAxis2.Rows[2] := LAxis2.Rows[0].Cross(LAxis2.Rows[1]);
  AxisProjection(LAxis2, LBounds2);
  LBounds2.AddPoint(TGeoVec3.Make(APoint.Dot(LAxis2.Rows[0]), APoint.Dot(LAxis2.Rows[1]),
    APoint.Dot(LAxis2.Rows[2])));
  // create new box based on the smallest bounds
  if LBounds1.GetVolume < LBounds2.GetVolume then
  begin
    Center := (LBounds1.Mins + LBounds1.Maxs) * 0.5;
    Extents := LBounds1.Maxs - Center;
    Center := Center * Axis;
  end
  else
  begin
    Center := (LBounds2.Mins + LBounds2.Maxs) * 0.5;
    Extents := LBounds2.Maxs - Center;
    Center := Center * LAxis2;
    Axis := LAxis2;
  end;
  Result := True;
end;

function TGeoBox.AddBox(const ABox: TGeoBox): Boolean;
var
  LIndex: Integer;
  LBestIndex: Integer;
  LVolume: Single;
  LBestVolume: Single;
  LDir: TGeoVec3;
  LAxes: array[0..3] of TGeoMat3;
  LBounds: array[0..3] of TGeoBounds;
  LOther: TGeoBounds;
begin
  if ABox.Extents.X < 0 then
    Exit(False);
  if Extents.X < 0 then
  begin
    Center := ABox.Center;
    Extents := ABox.Extents;
    Axis := ABox.Axis;
    Exit(True);
  end;
  // test axis of this box
  LAxes[0] := Axis;
  LBounds[0] := ProjectedBounds(Center, Extents, LAxes[0]);
  ABox.AxisProjection(LAxes[0], LOther);
  if not LBounds[0].AddBounds(LOther) then
    // the other box is contained in this box
    Exit(False);
  // test axis of other box
  LAxes[1] := ABox.Axis;
  LBounds[1] := ProjectedBounds(ABox.Center, ABox.Extents, LAxes[1]);
  AxisProjection(LAxes[1], LOther);
  if not LBounds[1].AddBounds(LOther) then
  begin
    // this box is contained in the other box
    Center := ABox.Center;
    Extents := ABox.Extents;
    Axis := ABox.Axis;
    Exit(True);
  end;
  // test axes aligned with the vector between the box centers and one of the box axis
  LDir := ABox.Center - Center;
  LDir.NormalizeSelf;
  for LIndex := 2 to 3 do
  begin
    LAxes[LIndex].Rows[0] := LDir;
    LAxes[LIndex].Rows[1] := LAxes[LIndex - 2].Rows[Min3Index(LDir.Dot(LAxes[LIndex - 2].Rows[0]),
      LDir.Dot(LAxes[LIndex - 2].Rows[1]), LDir.Dot(LAxes[LIndex - 2].Rows[2]))];
    LAxes[LIndex].Rows[1] := LAxes[LIndex].Rows[1] - LAxes[LIndex].Rows[1].Dot(LDir) * LDir;
    LAxes[LIndex].Rows[1].NormalizeSelf;
    LAxes[LIndex].Rows[2] := LDir.Cross(LAxes[LIndex].Rows[1]);
    AxisProjection(LAxes[LIndex], LBounds[LIndex]);
    ABox.AxisProjection(LAxes[LIndex], LOther);
    LBounds[LIndex].AddBounds(LOther);
  end;
  // get the bounds with the smallest volume
  LBestVolume := GEO_INFINITY;
  LBestIndex := 0;
  for LIndex := 0 to 3 do
  begin
    LVolume := LBounds[LIndex].GetVolume;
    if LVolume < LBestVolume then
    begin
      LBestVolume := LVolume;
      LBestIndex := LIndex;
    end;
  end;
  // create a box from the smallest bounds axis pair
  Center := (LBounds[LBestIndex].Mins + LBounds[LBestIndex].Maxs) * 0.5;
  Extents := LBounds[LBestIndex].Maxs - Center;
  Center := Center * LAxes[LBestIndex];
  Axis := LAxes[LBestIndex];
  Result := False;
end;

function TGeoBox.Expand(ADelta: Single): TGeoBox;
begin
  Result := Make(Center, Extents + TGeoVec3.Make(ADelta, ADelta, ADelta), Axis);
end;

procedure TGeoBox.ExpandSelf(ADelta: Single);
begin
  Extents.X := Extents.X + ADelta;
  Extents.Y := Extents.Y + ADelta;
  Extents.Z := Extents.Z + ADelta;
end;

function TGeoBox.Translate(const ATranslation: TGeoVec3): TGeoBox;
begin
  Result := Make(Center + ATranslation, Extents, Axis);
end;

procedure TGeoBox.TranslateSelf(const ATranslation: TGeoVec3);
begin
  Center := Center + ATranslation;
end;

function TGeoBox.Rotate(const ARotation: TGeoMat3): TGeoBox;
begin
  Result := Make(Center * ARotation, Extents, Axis * ARotation);
end;

procedure TGeoBox.RotateSelf(const ARotation: TGeoMat3);
begin
  Center := Center * ARotation;
  Axis := Axis * ARotation;
end;

function TGeoBox.PlaneDistance(const APlane: TGeoPlane): Single;
var
  LD1: Single;
  LD2: Single;
begin
  LD1 := APlane.Distance(Center);
  LD2 := TGeoMath.Fabs(Extents.X * APlane.A) + TGeoMath.Fabs(Extents.Y * APlane.B) +
    TGeoMath.Fabs(Extents.Z * APlane.C);
  if LD1 - LD2 > 0 then
    Exit(LD1 - LD2);
  if LD1 + LD2 < 0 then
    Exit(LD1 + LD2);
  Result := 0;
end;

function TGeoBox.PlaneSide(const APlane: TGeoPlane; AEpsilon: Single): Integer;
var
  LD1: Single;
  LD2: Single;
begin
  LD1 := APlane.Distance(Center);
  LD2 := TGeoMath.Fabs(Extents.X * APlane.A) + TGeoMath.Fabs(Extents.Y * APlane.B) +
    TGeoMath.Fabs(Extents.Z * APlane.C);
  if LD1 - LD2 > AEpsilon then
    Exit(PLANESIDE_FRONT);
  if LD1 + LD2 < -AEpsilon then
    Exit(PLANESIDE_BACK);
  Result := PLANESIDE_CROSS;
end;

function TGeoBox.ContainsPoint(const APoint: TGeoVec3): Boolean;
var
  LLocal: TGeoVec3;
begin
  LLocal := APoint - Center;
  Result := not ((TGeoMath.Fabs(LLocal.Dot(Axis.Rows[0])) > Extents.X) or
    (TGeoMath.Fabs(LLocal.Dot(Axis.Rows[1])) > Extents.Y) or
    (TGeoMath.Fabs(LLocal.Dot(Axis.Rows[2])) > Extents.Z));
end;

function TGeoBox.IntersectsBox(const ABox: TGeoBox): Boolean;
var
  LDir: TGeoVec3;
  C: array[0..2, 0..2] of Single;
  AC: array[0..2, 0..2] of Single;
  LAxisDir: array[0..2] of Single;
  LRow: Integer;
  LColumn: Integer;
  D: Single;
  E0: Single;
  E1: Single;
begin
  LDir := ABox.Center - Center;
  // axes C0 + t * A0, A1 and A2
  for LRow := 0 to 2 do
  begin
    for LColumn := 0 to 2 do
    begin
      C[LRow, LColumn] := Axis.Rows[LRow].Dot(ABox.Axis.Rows[LColumn]);
      AC[LRow, LColumn] := TGeoMath.Fabs(C[LRow, LColumn]);
    end;
    LAxisDir[LRow] := Axis.Rows[LRow].Dot(LDir);
    D := TGeoMath.Fabs(LAxisDir[LRow]);
    E0 := Extents[LRow];
    E1 := ABox.Extents.X * AC[LRow, 0] + ABox.Extents.Y * AC[LRow, 1] + ABox.Extents.Z * AC[LRow, 2];
    if D > E0 + E1 then
      Exit(False);
  end;
  // axes C0 + t * B0, B1 and B2
  for LColumn := 0 to 2 do
  begin
    D := TGeoMath.Fabs(ABox.Axis.Rows[LColumn].Dot(LDir));
    E0 := Extents.X * AC[0, LColumn] + Extents.Y * AC[1, LColumn] + Extents.Z * AC[2, LColumn];
    E1 := ABox.Extents[LColumn];
    if D > E0 + E1 then
      Exit(False);
  end;
  // axis C0 + t * A0xB0
  D := TGeoMath.Fabs(LAxisDir[2] * C[1, 0] - LAxisDir[1] * C[2, 0]);
  E0 := Extents.Y * AC[2, 0] + Extents.Z * AC[1, 0];
  E1 := ABox.Extents.Y * AC[0, 2] + ABox.Extents.Z * AC[0, 1];
  if D > E0 + E1 then
    Exit(False);
  // A0xB1
  D := TGeoMath.Fabs(LAxisDir[2] * C[1, 1] - LAxisDir[1] * C[2, 1]);
  E0 := Extents.Y * AC[2, 1] + Extents.Z * AC[1, 1];
  E1 := ABox.Extents.X * AC[0, 2] + ABox.Extents.Z * AC[0, 0];
  if D > E0 + E1 then
    Exit(False);
  // A0xB2
  D := TGeoMath.Fabs(LAxisDir[2] * C[1, 2] - LAxisDir[1] * C[2, 2]);
  E0 := Extents.Y * AC[2, 2] + Extents.Z * AC[1, 2];
  E1 := ABox.Extents.X * AC[0, 1] + ABox.Extents.Y * AC[0, 0];
  if D > E0 + E1 then
    Exit(False);
  // A1xB0
  D := TGeoMath.Fabs(LAxisDir[0] * C[2, 0] - LAxisDir[2] * C[0, 0]);
  E0 := Extents.X * AC[2, 0] + Extents.Z * AC[0, 0];
  E1 := ABox.Extents.Y * AC[1, 2] + ABox.Extents.Z * AC[1, 1];
  if D > E0 + E1 then
    Exit(False);
  // A1xB1
  D := TGeoMath.Fabs(LAxisDir[0] * C[2, 1] - LAxisDir[2] * C[0, 1]);
  E0 := Extents.X * AC[2, 1] + Extents.Z * AC[0, 1];
  E1 := ABox.Extents.X * AC[1, 2] + ABox.Extents.Z * AC[1, 0];
  if D > E0 + E1 then
    Exit(False);
  // A1xB2
  D := TGeoMath.Fabs(LAxisDir[0] * C[2, 2] - LAxisDir[2] * C[0, 2]);
  E0 := Extents.X * AC[2, 2] + Extents.Z * AC[0, 2];
  E1 := ABox.Extents.X * AC[1, 1] + ABox.Extents.Y * AC[1, 0];
  if D > E0 + E1 then
    Exit(False);
  // A2xB0
  D := TGeoMath.Fabs(LAxisDir[1] * C[0, 0] - LAxisDir[0] * C[1, 0]);
  E0 := Extents.X * AC[1, 0] + Extents.Y * AC[0, 0];
  E1 := ABox.Extents.Y * AC[2, 2] + ABox.Extents.Z * AC[2, 1];
  if D > E0 + E1 then
    Exit(False);
  // A2xB1
  D := TGeoMath.Fabs(LAxisDir[1] * C[0, 1] - LAxisDir[0] * C[1, 1]);
  E0 := Extents.X * AC[1, 1] + Extents.Y * AC[0, 1];
  E1 := ABox.Extents.X * AC[2, 2] + ABox.Extents.Z * AC[2, 0];
  if D > E0 + E1 then
    Exit(False);
  // A2xB2
  D := TGeoMath.Fabs(LAxisDir[1] * C[0, 2] - LAxisDir[0] * C[1, 2]);
  E0 := Extents.X * AC[1, 2] + Extents.Y * AC[0, 2];
  E1 := ABox.Extents.X * AC[2, 1] + ABox.Extents.Y * AC[2, 0];
  Result := not (D > E0 + E1);
end;

function TGeoBox.LineIntersection(const AStart, AEnd: TGeoVec3): Boolean;
var
  LLineDistance: array[0..2] of Single;
  LLineDir: TGeoVec3;
  LLineCenter: TGeoVec3;
  LDir: TGeoVec3;
  LCross: TGeoVec3;
begin
  LLineDir := 0.5 * (AEnd - AStart);
  LLineCenter := AStart + LLineDir;
  LDir := LLineCenter - Center;
  LLineDistance[0] := TGeoMath.Fabs(LLineDir.Dot(Axis.Rows[0]));
  if TGeoMath.Fabs(LDir.Dot(Axis.Rows[0])) > Extents.X + LLineDistance[0] then
    Exit(False);
  LLineDistance[1] := TGeoMath.Fabs(LLineDir.Dot(Axis.Rows[1]));
  if TGeoMath.Fabs(LDir.Dot(Axis.Rows[1])) > Extents.Y + LLineDistance[1] then
    Exit(False);
  LLineDistance[2] := TGeoMath.Fabs(LLineDir.Dot(Axis.Rows[2]));
  if TGeoMath.Fabs(LDir.Dot(Axis.Rows[2])) > Extents.Z + LLineDistance[2] then
    Exit(False);
  LCross := LLineDir.Cross(LDir);
  if TGeoMath.Fabs(LCross.Dot(Axis.Rows[0])) > Extents.Y * LLineDistance[2] + Extents.Z * LLineDistance[1] then
    Exit(False);
  if TGeoMath.Fabs(LCross.Dot(Axis.Rows[1])) > Extents.X * LLineDistance[2] + Extents.Z * LLineDistance[0] then
    Exit(False);
  if TGeoMath.Fabs(LCross.Dot(Axis.Rows[2])) > Extents.X * LLineDistance[1] + Extents.Y * LLineDistance[0] then
    Exit(False);
  Result := True;
end;

function TGeoBox.RayIntersection(const AStart, ADir: TGeoVec3; out AScale1, AScale2: Single): Boolean;
var
  LTranspose: TGeoMat3;
  LLocalStart: TGeoVec3;
  LLocalDir: TGeoVec3;
begin
  LTranspose := Axis.Transpose;
  LLocalStart := (AStart - Center) * LTranspose;
  LLocalDir := ADir * LTranspose;
  AScale1 := -GEO_INFINITY;
  AScale2 := GEO_INFINITY;
  Result := BoxPlaneClip(LLocalDir.X, -LLocalStart.X - Extents.X, AScale1, AScale2) and
    BoxPlaneClip(-LLocalDir.X, LLocalStart.X - Extents.X, AScale1, AScale2) and
    BoxPlaneClip(LLocalDir.Y, -LLocalStart.Y - Extents.Y, AScale1, AScale2) and
    BoxPlaneClip(-LLocalDir.Y, LLocalStart.Y - Extents.Y, AScale1, AScale2) and
    BoxPlaneClip(LLocalDir.Z, -LLocalStart.Z - Extents.Z, AScale1, AScale2) and
    BoxPlaneClip(-LLocalDir.Z, LLocalStart.Z - Extents.Z, AScale1, AScale2);
end;

procedure TGeoBox.ToPoints(var APoints: array of TGeoVec3);
var
  LAxes: TGeoMat3;
  LTemp: array[0..3] of TGeoVec3;
begin
  LAxes.Rows[0] := Extents.X * Axis.Rows[0];
  LAxes.Rows[1] := Extents.Y * Axis.Rows[1];
  LAxes.Rows[2] := Extents.Z * Axis.Rows[2];
  LTemp[0] := Center - LAxes.Rows[0];
  LTemp[1] := Center + LAxes.Rows[0];
  LTemp[2] := LAxes.Rows[1] - LAxes.Rows[2];
  LTemp[3] := LAxes.Rows[1] + LAxes.Rows[2];
  APoints[0] := LTemp[0] - LTemp[3];
  APoints[1] := LTemp[1] - LTemp[3];
  APoints[2] := LTemp[1] + LTemp[2];
  APoints[3] := LTemp[0] + LTemp[2];
  APoints[4] := LTemp[0] - LTemp[2];
  APoints[5] := LTemp[1] - LTemp[2];
  APoints[6] := LTemp[1] + LTemp[3];
  APoints[7] := LTemp[0] + LTemp[3];
end;

function TGeoBox.ToSphere: TGeoSphere;
begin
  Result := TGeoSphere.Make(Center, Extents.Length);
end;

procedure TGeoBox.AxisProjection(const ADir: TGeoVec3; out AMin, AMax: Single);
var
  LD1: Single;
  LD2: Single;
begin
  LD1 := ADir.Dot(Center);
  LD2 := TGeoMath.Fabs(Extents.X * ADir.Dot(Axis.Rows[0])) + TGeoMath.Fabs(Extents.Y * ADir.Dot(Axis.Rows[1])) +
    TGeoMath.Fabs(Extents.Z * ADir.Dot(Axis.Rows[2]));
  AMin := LD1 - LD2;
  AMax := LD1 + LD2;
end;

procedure TGeoBox.AxisProjection(const AAxis: TGeoMat3; out ABounds: TGeoBounds);
var
  LIndex: Integer;
  LD1: Single;
  LD2: Single;
begin
  for LIndex := 0 to 2 do
  begin
    LD1 := AAxis.Rows[LIndex].Dot(Center);
    LD2 := TGeoMath.Fabs(Extents.X * AAxis.Rows[LIndex].Dot(Axis.Rows[0])) +
      TGeoMath.Fabs(Extents.Y * AAxis.Rows[LIndex].Dot(Axis.Rows[1])) +
      TGeoMath.Fabs(Extents.Z * AAxis.Rows[LIndex].Dot(Axis.Rows[2]));
    ABounds.Mins[LIndex] := LD1 - LD2;
    ABounds.Maxs[LIndex] := LD1 + LD2;
  end;
end;

function TGeoBox.GetProjectionSilhouetteVerts(const AProjectionOrigin: TGeoVec3;
  var ASilVerts: array of TGeoVec3): Integer;
var
  LPoints: array[0..7] of TGeoVec3;
  LDir1: TGeoVec3;
  LDir2: TGeoVec3;
  LPlaneBits: Cardinal;
  LIndex: Integer;
begin
  ToPoints(LPoints);
  LDir1 := LPoints[0] - AProjectionOrigin;
  LDir2 := LPoints[6] - AProjectionOrigin;
  LPlaneBits := TGeoMath.FloatSignBitNotSet(LDir1.Dot(Axis.Rows[0]));
  LPlaneBits := LPlaneBits or (TGeoMath.FloatSignBitSet(LDir2.Dot(Axis.Rows[0])) shl 1);
  LPlaneBits := LPlaneBits or (TGeoMath.FloatSignBitNotSet(LDir1.Dot(Axis.Rows[1])) shl 2);
  LPlaneBits := LPlaneBits or (TGeoMath.FloatSignBitSet(LDir2.Dot(Axis.Rows[1])) shl 3);
  LPlaneBits := LPlaneBits or (TGeoMath.FloatSignBitNotSet(LDir1.Dot(Axis.Rows[2])) shl 4);
  LPlaneBits := LPlaneBits or (TGeoMath.FloatSignBitSet(LDir2.Dot(Axis.Rows[2])) shl 5);
  Result := BOX_PLANE_BITS_SIL_VERTS[LPlaneBits, 0];
  for LIndex := 0 to Result - 1 do
    ASilVerts[LIndex] := LPoints[BOX_PLANE_BITS_SIL_VERTS[LPlaneBits, LIndex + 1]];
end;

function TGeoBox.GetParallelProjectionSilhouetteVerts(const AProjectionDir: TGeoVec3;
  var ASilVerts: array of TGeoVec3): Integer;
var
  LPoints: array[0..7] of TGeoVec3;
  LValue: Single;
  LPlaneBits: Cardinal;
  LIndex: Integer;
begin
  ToPoints(LPoints);
  LPlaneBits := 0;
  LValue := AProjectionDir.Dot(Axis.Rows[0]);
  if FloatNotZero(LValue) then
    LPlaneBits := Cardinal(1) shl TGeoMath.FloatSignBitSet(LValue);
  LValue := AProjectionDir.Dot(Axis.Rows[1]);
  if FloatNotZero(LValue) then
    LPlaneBits := LPlaneBits or (Cardinal(4) shl TGeoMath.FloatSignBitSet(LValue));
  LValue := AProjectionDir.Dot(Axis.Rows[2]);
  if FloatNotZero(LValue) then
    LPlaneBits := LPlaneBits or (Cardinal(16) shl TGeoMath.FloatSignBitSet(LValue));
  Result := BOX_PLANE_BITS_SIL_VERTS[LPlaneBits, 0];
  for LIndex := 0 to Result - 1 do
    ASilVerts[LIndex] := LPoints[BOX_PLANE_BITS_SIL_VERTS[LPlaneBits, LIndex + 1]];
end;

end.
