{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the axis aligned box (idBounds)              }
{                                                                              }
{  Port of the used part of idBounds (Bounds.h, Bounds.cpp) of Doom 3 GPL      }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Doom 3 Source Code: GNU General Public License version 3 with      }
{  additional terms. This unit is a derived work (GPL v3).                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Bounds;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Sphere;

type
  /// <summary>An axis aligned box: Mins is b[0] and Maxs is b[1] of idBounds (24 bytes)</summary>
  TGeoBounds = record
    Mins: TGeoVec3;
    Maxs: TGeoVec3;
  public
    class function Make(const AMins, AMaxs: TGeoVec3): TGeoBounds; static;
    /// <summary>Empty box: mins at +1e30 and maxs at -1e30 (idBounds::Clear)</summary>
    class function Cleared: TGeoBounds; static;

    procedure Clear;
    procedure Zero;
    function IsCleared: Boolean;
    function GetCenter: TGeoVec3;
    /// <summary>Grows the box to contain the point; true when it grew</summary>
    function AddPoint(const APoint: TGeoVec3): Boolean;
    /// <summary>Union with another box (idBounds::operator+=(idBounds))</summary>
    function AddBounds(const ABounds: TGeoBounds): Boolean;
    procedure TranslateSelf(const ATranslation: TGeoVec3);
    function ContainsPoint(const APoint: TGeoVec3): Boolean;
    function IntersectsBounds(const ABounds: TGeoBounds): Boolean;
    /// <summary>Signed distance of the box from the plane, 0 when the plane crosses the box</summary>
    function PlaneDistance(const APlane: TGeoPlane): Single;
    /// <summary>PLANESIDE_FRONT, _BACK or _CROSS</summary>
    function PlaneSide(const APlane: TGeoPlane; AEpsilon: Single = 0.1): Integer;
    function Compare(const ABounds: TGeoBounds): Boolean; overload;
    function Compare(const ABounds: TGeoBounds; AEpsilon: Single): Boolean; overload;
    /// <summary>The radius of the sphere around the origin that contains the box</summary>
    function GetRadius: Single; overload;
    /// <summary>The radius of the sphere around the given centre that contains the box</summary>
    function GetRadius(const ACenter: TGeoVec3): Single; overload;
    /// <summary>0 when the box is empty or flat</summary>
    function GetVolume: Single;
    /// <summary>The overlap of the two boxes (idBounds::Intersect), inside out when disjoint</summary>
    function Intersect(const ABounds: TGeoBounds): TGeoBounds;
    procedure IntersectSelf(const ABounds: TGeoBounds);
    function Expand(ADelta: Single): TGeoBounds;
    procedure ExpandSelf(ADelta: Single);
    function Translate(const ATranslation: TGeoVec3): TGeoBounds;
    /// <summary>The tightest box around this one rotated about the origin by the matrix</summary>
    function Rotate(const ARotation: TGeoMat3): TGeoBounds;
    procedure RotateSelf(const ARotation: TGeoMat3);
    /// <summary>True when the segment between start and end meets the box</summary>
    function LineIntersection(const AStart, AEnd: TGeoVec3): Boolean;
    /// <summary>
    ///   The ray meets the box at start + dir * scale, in both directions from the start; a
    ///   start inside the box gives scale 0 (idBounds::RayIntersection)
    /// </summary>
    function RayIntersection(const AStart, ADir: TGeoVec3; out AScale: Single): Boolean;
    /// <summary>The tightest box for a box moved by an origin and an axis (idBounds::FromTransformedBounds)</summary>
    procedure FromTransformedBounds(const ABounds: TGeoBounds; const AOrigin: TGeoVec3; const AAxis: TGeoMat3);
    /// <summary>The tightest box for a point set (with no points the box is inside out)</summary>
    procedure FromPoints(const APoints: array of TGeoVec3);
    procedure FromPointTranslation(const APoint, ATranslation: TGeoVec3);
    procedure FromBoundsTranslation(const ABounds: TGeoBounds; const AOrigin: TGeoVec3;
      const AAxis: TGeoMat3; const ATranslation: TGeoVec3);
    /// <summary>The eight corners in the order of idBounds::ToPoints (bit 0 of x, 1 of y, 2 of z, Gray coded in x)</summary>
    procedure ToPoints(var APoints: array of TGeoVec3);
    function ToSphere: TGeoSphere;
    /// <summary>The interval the box covers along the direction</summary>
    procedure AxisProjection(const ADir: TGeoVec3; out AMin, AMax: Single); overload;
    /// <summary>The same for the box moved by an origin and an axis</summary>
    procedure AxisProjection(const AOrigin: TGeoVec3; const AAxis: TGeoMat3; const ADir: TGeoVec3;
      out AMin, AMax: Single); overload;
  end;

implementation

uses
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath;

{ TGeoBounds }

class function TGeoBounds.Make(const AMins, AMaxs: TGeoVec3): TGeoBounds;
begin
  Result.Mins := AMins;
  Result.Maxs := AMaxs;
end;

class function TGeoBounds.Cleared: TGeoBounds;
begin
  Result.Clear;
end;

procedure TGeoBounds.Clear;
begin
  Mins.SetValues(GEO_INFINITY, GEO_INFINITY, GEO_INFINITY);
  Maxs.SetValues(-GEO_INFINITY, -GEO_INFINITY, -GEO_INFINITY);
end;

procedure TGeoBounds.Zero;
begin
  Mins.Zero;
  Maxs.Zero;
end;

function TGeoBounds.IsCleared: Boolean;
begin
  Result := Mins.X > Maxs.X;
end;

function TGeoBounds.GetCenter: TGeoVec3;
begin
  Result.X := (Maxs.X + Mins.X) * 0.5;
  Result.Y := (Maxs.Y + Mins.Y) * 0.5;
  Result.Z := (Maxs.Z + Mins.Z) * 0.5;
end;

function TGeoBounds.AddPoint(const APoint: TGeoVec3): Boolean;
var
  LAxis: Integer;
begin
  Result := False;
  for LAxis := 0 to 2 do
  begin
    if APoint[LAxis] < Mins[LAxis] then
    begin
      Mins[LAxis] := APoint[LAxis];
      Result := True;
    end;
    if APoint[LAxis] > Maxs[LAxis] then
    begin
      Maxs[LAxis] := APoint[LAxis];
      Result := True;
    end;
  end;
end;

function TGeoBounds.AddBounds(const ABounds: TGeoBounds): Boolean;
var
  LAxis: Integer;
begin
  Result := False;
  for LAxis := 0 to 2 do
  begin
    if ABounds.Mins[LAxis] < Mins[LAxis] then
    begin
      Mins[LAxis] := ABounds.Mins[LAxis];
      Result := True;
    end;
    if ABounds.Maxs[LAxis] > Maxs[LAxis] then
    begin
      Maxs[LAxis] := ABounds.Maxs[LAxis];
      Result := True;
    end;
  end;
end;

procedure TGeoBounds.TranslateSelf(const ATranslation: TGeoVec3);
begin
  Mins := Mins + ATranslation;
  Maxs := Maxs + ATranslation;
end;

function TGeoBounds.ContainsPoint(const APoint: TGeoVec3): Boolean;
begin
  Result := not ((APoint.X < Mins.X) or (APoint.Y < Mins.Y) or (APoint.Z < Mins.Z) or
    (APoint.X > Maxs.X) or (APoint.Y > Maxs.Y) or (APoint.Z > Maxs.Z));
end;

function TGeoBounds.IntersectsBounds(const ABounds: TGeoBounds): Boolean;
begin
  Result := not ((ABounds.Maxs.X < Mins.X) or (ABounds.Maxs.Y < Mins.Y) or (ABounds.Maxs.Z < Mins.Z) or
    (ABounds.Mins.X > Maxs.X) or (ABounds.Mins.Y > Maxs.Y) or (ABounds.Mins.Z > Maxs.Z));
end;

function TGeoBounds.PlaneDistance(const APlane: TGeoPlane): Single;
var
  LCenter: TGeoVec3;
  LD1: Single;
  LD2: Single;
begin
  LCenter := (Mins + Maxs) * 0.5;
  LD1 := APlane.Distance(LCenter);
  LD2 := TGeoMath.Fabs((Maxs.X - LCenter.X) * APlane.A) +
    TGeoMath.Fabs((Maxs.Y - LCenter.Y) * APlane.B) +
    TGeoMath.Fabs((Maxs.Z - LCenter.Z) * APlane.C);
  if LD1 - LD2 > 0 then
    Result := LD1 - LD2
  else if LD1 + LD2 < 0 then
    Result := LD1 + LD2
  else
    Result := 0;
end;

function TGeoBounds.PlaneSide(const APlane: TGeoPlane; AEpsilon: Single): Integer;
var
  LCenter: TGeoVec3;
  LD1: Single;
  LD2: Single;
begin
  LCenter := (Mins + Maxs) * 0.5;
  LD1 := APlane.Distance(LCenter);
  LD2 := TGeoMath.Fabs((Maxs.X - LCenter.X) * APlane.A) +
    TGeoMath.Fabs((Maxs.Y - LCenter.Y) * APlane.B) +
    TGeoMath.Fabs((Maxs.Z - LCenter.Z) * APlane.C);
  if LD1 - LD2 > AEpsilon then
    Result := PLANESIDE_FRONT
  else if LD1 + LD2 < -AEpsilon then
    Result := PLANESIDE_BACK
  else
    Result := PLANESIDE_CROSS;
end;

function TGeoBounds.Compare(const ABounds: TGeoBounds): Boolean;
begin
  Result := Mins.Compare(ABounds.Mins) and Maxs.Compare(ABounds.Maxs);
end;

function TGeoBounds.Compare(const ABounds: TGeoBounds; AEpsilon: Single): Boolean;
begin
  Result := Mins.Compare(ABounds.Mins, AEpsilon) and Maxs.Compare(ABounds.Maxs, AEpsilon);
end;

function TGeoBounds.GetRadius: Single;
var
  LAxis: Integer;
  LTotal: Single;
  LB0: Single;
  LB1: Single;
begin
  LTotal := 0;
  for LAxis := 0 to 2 do
  begin
    LB0 := TGeoMath.Fabs(Mins[LAxis]);
    LB1 := TGeoMath.Fabs(Maxs[LAxis]);
    if LB0 > LB1 then
      LTotal := LTotal + LB0 * LB0
    else
      LTotal := LTotal + LB1 * LB1;
  end;
  Result := TGeoMath.Sqrt(LTotal);
end;

function TGeoBounds.GetRadius(const ACenter: TGeoVec3): Single;
var
  LAxis: Integer;
  LTotal: Single;
  LB0: Single;
  LB1: Single;
begin
  LTotal := 0;
  for LAxis := 0 to 2 do
  begin
    LB0 := TGeoMath.Fabs(ACenter[LAxis] - Mins[LAxis]);
    LB1 := TGeoMath.Fabs(Maxs[LAxis] - ACenter[LAxis]);
    if LB0 > LB1 then
      LTotal := LTotal + LB0 * LB0
    else
      LTotal := LTotal + LB1 * LB1;
  end;
  Result := TGeoMath.Sqrt(LTotal);
end;

function TGeoBounds.GetVolume: Single;
begin
  if (Mins.X >= Maxs.X) or (Mins.Y >= Maxs.Y) or (Mins.Z >= Maxs.Z) then
    Exit(0);
  Result := (Maxs.X - Mins.X) * (Maxs.Y - Mins.Y) * (Maxs.Z - Mins.Z);
end;

function TGeoBounds.Intersect(const ABounds: TGeoBounds): TGeoBounds;
var
  LAxis: Integer;
begin
  for LAxis := 0 to 2 do
  begin
    if ABounds.Mins[LAxis] > Mins[LAxis] then
      Result.Mins[LAxis] := ABounds.Mins[LAxis]
    else
      Result.Mins[LAxis] := Mins[LAxis];
    if ABounds.Maxs[LAxis] < Maxs[LAxis] then
      Result.Maxs[LAxis] := ABounds.Maxs[LAxis]
    else
      Result.Maxs[LAxis] := Maxs[LAxis];
  end;
end;

procedure TGeoBounds.IntersectSelf(const ABounds: TGeoBounds);
var
  LAxis: Integer;
begin
  for LAxis := 0 to 2 do
  begin
    if ABounds.Mins[LAxis] > Mins[LAxis] then
      Mins[LAxis] := ABounds.Mins[LAxis];
    if ABounds.Maxs[LAxis] < Maxs[LAxis] then
      Maxs[LAxis] := ABounds.Maxs[LAxis];
  end;
end;

function TGeoBounds.Expand(ADelta: Single): TGeoBounds;
begin
  Result.Mins.SetValues(Mins.X - ADelta, Mins.Y - ADelta, Mins.Z - ADelta);
  Result.Maxs.SetValues(Maxs.X + ADelta, Maxs.Y + ADelta, Maxs.Z + ADelta);
end;

procedure TGeoBounds.ExpandSelf(ADelta: Single);
begin
  Mins.SetValues(Mins.X - ADelta, Mins.Y - ADelta, Mins.Z - ADelta);
  Maxs.SetValues(Maxs.X + ADelta, Maxs.Y + ADelta, Maxs.Z + ADelta);
end;

function TGeoBounds.Translate(const ATranslation: TGeoVec3): TGeoBounds;
begin
  Result.Mins := Mins + ATranslation;
  Result.Maxs := Maxs + ATranslation;
end;

function TGeoBounds.Rotate(const ARotation: TGeoMat3): TGeoBounds;
begin
  Result.FromTransformedBounds(Self, TGeoVec3.Origin, ARotation);
end;

procedure TGeoBounds.RotateSelf(const ARotation: TGeoMat3);
begin
  FromTransformedBounds(Self, TGeoVec3.Origin, ARotation);
end;

function TGeoBounds.LineIntersection(const AStart, AEnd: TGeoVec3): Boolean;
var
  LLineDistance: array[0..2] of Single;
  LCenter: TGeoVec3;
  LExtents: TGeoVec3;
  LLineDir: TGeoVec3;
  LLineCenter: TGeoVec3;
  LDir: TGeoVec3;
  LCross: TGeoVec3;
begin
  LCenter := (Mins + Maxs) * 0.5;
  LExtents := Maxs - LCenter;
  LLineDir := 0.5 * (AEnd - AStart);
  LLineCenter := AStart + LLineDir;
  LDir := LLineCenter - LCenter;
  LLineDistance[0] := TGeoMath.Fabs(LLineDir.X);
  if TGeoMath.Fabs(LDir.X) > LExtents.X + LLineDistance[0] then
    Exit(False);
  LLineDistance[1] := TGeoMath.Fabs(LLineDir.Y);
  if TGeoMath.Fabs(LDir.Y) > LExtents.Y + LLineDistance[1] then
    Exit(False);
  LLineDistance[2] := TGeoMath.Fabs(LLineDir.Z);
  if TGeoMath.Fabs(LDir.Z) > LExtents.Z + LLineDistance[2] then
    Exit(False);
  LCross := LLineDir.Cross(LDir);
  if TGeoMath.Fabs(LCross.X) > LExtents.Y * LLineDistance[2] + LExtents.Z * LLineDistance[1] then
    Exit(False);
  if TGeoMath.Fabs(LCross.Y) > LExtents.X * LLineDistance[2] + LExtents.Z * LLineDistance[0] then
    Exit(False);
  if TGeoMath.Fabs(LCross.Z) > LExtents.X * LLineDistance[1] + LExtents.Y * LLineDistance[0] then
    Exit(False);
  Result := True;
end;

function TGeoBounds.RayIntersection(const AStart, ADir: TGeoVec3; out AScale: Single): Boolean;
var
  LAxis: Integer;
  LAx0: Integer;
  LAx1: Integer;
  LAx2: Integer;
  LInside: Integer;
  LSide: Integer;
  LDistance: Single;
  LHit: TGeoVec3;
begin
  AScale := 0;
  LAx0 := -1;
  LInside := 0;
  LHit.Zero;
  for LAxis := 0 to 2 do
  begin
    if AStart[LAxis] < Mins[LAxis] then
      LSide := 0
    else if AStart[LAxis] > Maxs[LAxis] then
      LSide := 1
    else
    begin
      Inc(LInside);
      Continue;
    end;
    if ADir[LAxis] = 0 then
      Continue;
    if LSide = 0 then
      LDistance := AStart[LAxis] - Mins[LAxis]
    else
      LDistance := AStart[LAxis] - Maxs[LAxis];
    if (LAx0 < 0) or (TGeoMath.Fabs(LDistance) > TGeoMath.Fabs(AScale * ADir[LAxis])) then
    begin
      AScale := -(LDistance / ADir[LAxis]);
      LAx0 := LAxis;
    end;
  end;
  if LAx0 < 0 then
  begin
    AScale := 0;
    // true when the start point is inside the box
    Exit(LInside = 3);
  end;
  LAx1 := (LAx0 + 1) mod 3;
  LAx2 := (LAx0 + 2) mod 3;
  LHit[LAx1] := AStart[LAx1] + AScale * ADir[LAx1];
  LHit[LAx2] := AStart[LAx2] + AScale * ADir[LAx2];
  Result := (LHit[LAx1] >= Mins[LAx1]) and (LHit[LAx1] <= Maxs[LAx1]) and
    (LHit[LAx2] >= Mins[LAx2]) and (LHit[LAx2] <= Maxs[LAx2]);
end;

procedure TGeoBounds.FromTransformedBounds(const ABounds: TGeoBounds; const AOrigin: TGeoVec3;
  const AAxis: TGeoMat3);
var
  LAxis: Integer;
  LCenter: TGeoVec3;
  LExtents: TGeoVec3;
  LRotatedExtents: TGeoVec3;
begin
  LCenter := (ABounds.Mins + ABounds.Maxs) * 0.5;
  LExtents := ABounds.Maxs - LCenter;
  for LAxis := 0 to 2 do
    LRotatedExtents[LAxis] := TGeoMath.Fabs(LExtents.X * AAxis.Rows[0][LAxis]) +
      TGeoMath.Fabs(LExtents.Y * AAxis.Rows[1][LAxis]) +
      TGeoMath.Fabs(LExtents.Z * AAxis.Rows[2][LAxis]);
  LCenter := AOrigin + LCenter * AAxis;
  Mins := LCenter - LRotatedExtents;
  Maxs := LCenter + LRotatedExtents;
end;

procedure TGeoBounds.FromPoints(const APoints: array of TGeoVec3);
var
  LIndex: Integer;
begin
  Clear;
  for LIndex := 0 to High(APoints) do
    AddPoint(APoints[LIndex]);
end;

procedure TGeoBounds.FromPointTranslation(const APoint, ATranslation: TGeoVec3);
var
  LAxis: Integer;
begin
  for LAxis := 0 to 2 do
    if ATranslation[LAxis] < 0 then
    begin
      Mins[LAxis] := APoint[LAxis] + ATranslation[LAxis];
      Maxs[LAxis] := APoint[LAxis];
    end
    else
    begin
      Mins[LAxis] := APoint[LAxis];
      Maxs[LAxis] := APoint[LAxis] + ATranslation[LAxis];
    end;
end;

procedure TGeoBounds.FromBoundsTranslation(const ABounds: TGeoBounds; const AOrigin: TGeoVec3;
  const AAxis: TGeoMat3; const ATranslation: TGeoVec3);
var
  LAxis: Integer;
begin
  if AAxis.IsRotated then
    FromTransformedBounds(ABounds, AOrigin, AAxis)
  else
  begin
    Mins := ABounds.Mins + AOrigin;
    Maxs := ABounds.Maxs + AOrigin;
  end;
  for LAxis := 0 to 2 do
    if ATranslation[LAxis] < 0 then
      Mins[LAxis] := Mins[LAxis] + ATranslation[LAxis]
    else
      Maxs[LAxis] := Maxs[LAxis] + ATranslation[LAxis];
end;

procedure TGeoBounds.ToPoints(var APoints: array of TGeoVec3);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
  begin
    if ((LIndex xor (LIndex shr 1)) and 1) = 0 then
      APoints[LIndex].X := Mins.X
    else
      APoints[LIndex].X := Maxs.X;
    if ((LIndex shr 1) and 1) = 0 then
      APoints[LIndex].Y := Mins.Y
    else
      APoints[LIndex].Y := Maxs.Y;
    if ((LIndex shr 2) and 1) = 0 then
      APoints[LIndex].Z := Mins.Z
    else
      APoints[LIndex].Z := Maxs.Z;
  end;
end;

function TGeoBounds.ToSphere: TGeoSphere;
begin
  Result.Origin := (Mins + Maxs) * 0.5;
  Result.Radius := (Maxs - Result.Origin).Length;
end;

procedure TGeoBounds.AxisProjection(const ADir: TGeoVec3; out AMin, AMax: Single);
var
  LCenter: TGeoVec3;
  LExtents: TGeoVec3;
  LD1: Single;
  LD2: Single;
begin
  LCenter := (Mins + Maxs) * 0.5;
  LExtents := Maxs - LCenter;
  LD1 := ADir.Dot(LCenter);
  LD2 := TGeoMath.Fabs(LExtents.X * ADir.X) + TGeoMath.Fabs(LExtents.Y * ADir.Y) +
    TGeoMath.Fabs(LExtents.Z * ADir.Z);
  AMin := LD1 - LD2;
  AMax := LD1 + LD2;
end;

procedure TGeoBounds.AxisProjection(const AOrigin: TGeoVec3; const AAxis: TGeoMat3; const ADir: TGeoVec3;
  out AMin, AMax: Single);
var
  LCenter: TGeoVec3;
  LExtents: TGeoVec3;
  LD1: Single;
  LD2: Single;
begin
  LCenter := (Mins + Maxs) * 0.5;
  LExtents := Maxs - LCenter;
  LCenter := AOrigin + LCenter * AAxis;
  LD1 := ADir.Dot(LCenter);
  LD2 := TGeoMath.Fabs(LExtents.X * ADir.Dot(AAxis.Rows[0])) +
    TGeoMath.Fabs(LExtents.Y * ADir.Dot(AAxis.Rows[1])) +
    TGeoMath.Fabs(LExtents.Z * ADir.Dot(AAxis.Rows[2]));
  AMin := LD1 - LD2;
  AMax := LD1 + LD2;
end;

end.
