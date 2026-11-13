{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the 2D winding (idWinding2D)                 }
{                                                                              }
{  Port of idWinding2D (idlib\geometry\Winding2D.h and Winding2D.cpp) of the   }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a          }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Winding2D;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Vec3;

const
  /// <summary>Capacity of a 2D winding (MAX_POINTS_ON_WINDING_2D)</summary>
  MAX_POINTS_ON_WINDING_2D = 16;

type
  /// <summary>
  ///   A convex 2D polygon of at most 16 points (idWinding2D). A 2D "plane" is a
  ///   <c>TGeoVec3</c> (x, y = normal, z = distance term), as in the original. The storage has
  ///   four spare points because <c>Split</c> of a full winding can produce 18 points, which the
  ///   original writes past the end of its array.
  /// </summary>
  TGeoWinding2D = class
  strict private
    FCount: Integer;
    FPoints: array[0..MAX_POINTS_ON_WINDING_2D + 3] of TIdVec2;
    function GetPoint(AIndex: Integer): TIdVec2;
    procedure SetPoint(AIndex: Integer; const AValue: TIdVec2);
  public
    property NumPoints: Integer read FCount;
    property Points[AIndex: Integer]: TIdVec2 read GetPoint write SetPoint; default;

    procedure Clear;
    procedure AddPoint(const APoint: TIdVec2);
    /// <summary>Copies the points of another winding (idWinding2D::operator=)</summary>
    procedure Assign(const AWinding: TGeoWinding2D);
    /// <summary>Moves every edge outwards by the distance</summary>
    procedure Expand(ADistance: Single);
    /// <summary>Expands the winding so that an axial box with the given mins and maxs fits</summary>
    procedure ExpandForAxialBox(const AMins, AMaxs: TIdVec2);
    /// <summary>
    ///   Splits into a front and a back winding (new objects owned by the caller, nil when
    ///   empty); this winding is unchanged. Returns PLANESIDE_FRONT, _BACK or _CROSS
    /// </summary>
    function Split(const APlane: TGeoVec3; AEpsilon: Single; out AFront, ABack: TGeoWinding2D): Integer;
    /// <summary>
    ///   Cuts off the part behind the plane; false when nothing is in front (then there are no
    ///   points left)
    /// </summary>
    function ClipInPlace(const APlane: TGeoVec3; AEpsilon: Single = 0.1; AKeepOn: Boolean = False): Boolean;
    function Copy: TGeoWinding2D;
    function Reverse: TGeoWinding2D;
    function GetArea: Single;
    /// <summary>The mean of the points; NaN for an empty winding (0 * 1/0 in the original)</summary>
    function GetCenter: TIdVec2;
    function GetRadius(const ACenter: TIdVec2): Single;
    procedure GetBounds(out AMins, AMaxs: TIdVec2);
    function IsTiny: Boolean;
    function IsHuge: Boolean;
    function PlaneDistance(const APlane: TGeoVec3): Single;
    function PlaneSide(const APlane: TGeoVec3; AEpsilon: Single = 0.1): Integer;
    function PointInside(const APoint: TIdVec2; AEpsilon: Single): Boolean;
    function LineIntersection(const AStart, AEnd: TIdVec2): Boolean;
    /// <summary>The ray meets the winding at start + dir * scale1 and scale2 (nearest first)</summary>
    function RayIntersection(const AStart, ADir: TIdVec2; out AScale1, AScale2: Single): Boolean; overload;
    /// <summary>Same, also giving the numbers of the two edges that were hit (-1 when nothing is hit)</summary>
    function RayIntersection(const AStart, ADir: TIdVec2; out AScale1, AScale2: Single;
      out AEdge1, AEdge2: Integer): Boolean; overload;
    class function Plane2DFromPoints(const AStart, AEnd: TIdVec2; ANormalize: Boolean = False): TGeoVec3; static;
    class function Plane2DFromVecs(const AStart, ADir: TIdVec2; ANormalize: Boolean = False): TGeoVec3; static;
    class function Plane2DIntersection(const APlane1, APlane2: TGeoVec3; out APoint: TIdVec2): Boolean; static;
  end;

implementation

uses
  System.Math, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath;

const
  EDGE_LENGTH: Single = 0.2;

function PlaneValue(const APlane: TGeoVec3; const APoint: TIdVec2): Single;
begin
  Result := APlane.X * APoint.X + APlane.Y * APoint.Y + APlane.Z;
end;

procedure NormalizeXY(var APlane: TGeoVec3);
var
  LVector: TIdVec2;
begin
  // plane.ToVec2().Normalize(): the first two floats seen as an idVec2
  LVector := TIdVec2.Create(APlane.X, APlane.Y);
  LVector.Normalize;
  APlane.X := LVector.X;
  APlane.Y := LVector.Y;
end;

/// <summary>GetAxialBevel of Winding2D.cpp: a 45 degree bevel plane at a corner of the polygon</summary>
function GetAxialBevel(const APlane1, APlane2: TGeoVec3; const APoint: TIdVec2; var ABevel: TGeoVec3): Boolean;
begin
  if (TGeoMath.FloatSignBitSet(APlane1.X) xor TGeoMath.FloatSignBitSet(APlane2.X)) <> 0 then
  begin
    if (TGeoMath.Fabs(APlane1.X) > 0.1) and (TGeoMath.Fabs(APlane2.X) > 0.1) then
    begin
      ABevel.X := 0;
      if TGeoMath.FloatSignBitSet(APlane1.Y) <> 0 then
        ABevel.Y := -1
      else
        ABevel.Y := 1;
      ABevel.Z := -(APoint.X * ABevel.X + APoint.Y * ABevel.Y);
      Exit(True);
    end;
  end;
  if (TGeoMath.FloatSignBitSet(APlane1.Y) xor TGeoMath.FloatSignBitSet(APlane2.Y)) <> 0 then
  begin
    if (TGeoMath.Fabs(APlane1.Y) > 0.1) and (TGeoMath.Fabs(APlane2.Y) > 0.1) then
    begin
      ABevel.Y := 0;
      if TGeoMath.FloatSignBitSet(APlane1.X) <> 0 then
        ABevel.X := -1
      else
        ABevel.X := 1;
      ABevel.Z := -(APoint.X * ABevel.X + APoint.Y * ABevel.Y);
      Exit(True);
    end;
  end;
  Result := False;
end;

{ TGeoWinding2D }

function TGeoWinding2D.GetPoint(AIndex: Integer): TIdVec2;
begin
  Result := FPoints[AIndex];
end;

procedure TGeoWinding2D.SetPoint(AIndex: Integer; const AValue: TIdVec2);
begin
  FPoints[AIndex] := AValue;
end;

procedure TGeoWinding2D.Clear;
begin
  FCount := 0;
end;

procedure TGeoWinding2D.AddPoint(const APoint: TIdVec2);
begin
  if FCount > High(FPoints) then
    raise EGeometryException.Create('TGeoWinding2D.AddPoint: too many points');
  FPoints[FCount] := APoint;
  Inc(FCount);
end;

procedure TGeoWinding2D.Assign(const AWinding: TGeoWinding2D);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AWinding.FCount - 1 do
    FPoints[LIndex] := AWinding.FPoints[LIndex];
  FCount := AWinding.FCount;
end;

class function TGeoWinding2D.Plane2DFromPoints(const AStart, AEnd: TIdVec2; ANormalize: Boolean): TGeoVec3;
begin
  Result.X := AStart.Y - AEnd.Y;
  Result.Y := AEnd.X - AStart.X;
  if ANormalize then
    NormalizeXY(Result);
  Result.Z := -(AStart.X * Result.X + AStart.Y * Result.Y);
end;

class function TGeoWinding2D.Plane2DFromVecs(const AStart, ADir: TIdVec2; ANormalize: Boolean): TGeoVec3;
begin
  Result.X := -ADir.Y;
  Result.Y := ADir.X;
  if ANormalize then
    NormalizeXY(Result);
  Result.Z := -(AStart.X * Result.X + AStart.Y * Result.Y);
end;

class function TGeoWinding2D.Plane2DIntersection(const APlane1, APlane2: TGeoVec3; out APoint: TIdVec2): Boolean;
var
  LN00, LN01, LN11, LDet, LInvDet, LF0, LF1: Single;
begin
  LN00 := APlane1.X * APlane1.X + APlane1.Y * APlane1.Y;
  LN01 := APlane1.X * APlane2.X + APlane1.Y * APlane2.Y;
  LN11 := APlane2.X * APlane2.X + APlane2.Y * APlane2.Y;
  LDet := LN00 * LN11 - LN01 * LN01;
  if TGeoMath.Fabs(LDet) < 1e-6 then
  begin
    APoint.Zero;
    Exit(False);
  end;
  LInvDet := 1.0 / LDet;
  LF0 := (LN01 * APlane2.Z - LN11 * APlane1.Z) * LInvDet;
  LF1 := (LN01 * APlane1.Z - LN00 * APlane2.Z) * LInvDet;
  APoint.X := LF0 * APlane1.X + LF1 * APlane2.X;
  APoint.Y := LF0 * APlane1.Y + LF1 * APlane2.Y;
  Result := True;
end;

procedure TGeoWinding2D.ExpandForAxialBox(const AMins, AMaxs: TIdVec2);
var
  LIndex, LNext, LPlaneCount: Integer;
  LPlanes: array[0..MAX_POINTS_ON_WINDING_2D * 2] of TGeoVec3;
  LPlane, LBevel: TGeoVec3;
  LDelta: TIdVec2;
  LExpand: TIdVec2;
begin
  LPlaneCount := 0;
  // planes of the edges and bevels at the corners
  for LIndex := 0 to FCount - 1 do
  begin
    LNext := (LIndex + 1) mod FCount;
    LDelta := FPoints[LNext] - FPoints[LIndex];
    if LDelta.LengthSqr < 0.01 then
      Continue;
    LPlane := Plane2DFromPoints(FPoints[LIndex], FPoints[LNext], True);
    if LIndex <> 0 then
    begin
      if GetAxialBevel(LPlanes[LPlaneCount - 1], LPlane, FPoints[LIndex], LBevel) then
      begin
        LPlanes[LPlaneCount] := LBevel;
        Inc(LPlaneCount);
      end;
    end;
    LPlanes[LPlaneCount] := LPlane;
    Inc(LPlaneCount);
  end;
  // the original reads planes[-1] when every edge was skipped: nothing to do then
  if LPlaneCount = 0 then
  begin
    FCount := 0;
    Exit;
  end;
  if GetAxialBevel(LPlanes[LPlaneCount - 1], LPlanes[0], FPoints[0], LBevel) then
  begin
    LPlanes[LPlaneCount] := LBevel;
    Inc(LPlaneCount);
  end;
  // expand the planes
  for LIndex := 0 to LPlaneCount - 1 do
  begin
    if TGeoMath.FloatSignBitSet(LPlanes[LIndex].X) <> 0 then
      LExpand.X := AMaxs.X
    else
      LExpand.X := AMins.X;
    if TGeoMath.FloatSignBitSet(LPlanes[LIndex].Y) <> 0 then
      LExpand.Y := AMaxs.Y
    else
      LExpand.Y := AMins.Y;
    LPlanes[LIndex].Z := LPlanes[LIndex].Z + (LExpand.X * LPlanes[LIndex].X + LExpand.Y * LPlanes[LIndex].Y);
  end;
  // intersection points of the planes
  FCount := 0;
  for LIndex := 0 to LPlaneCount - 1 do
  begin
    if Plane2DIntersection(LPlanes[(LIndex + LPlaneCount - 1) mod LPlaneCount], LPlanes[LIndex],
      FPoints[FCount]) then
      Inc(FCount);
  end;
end;

procedure TGeoWinding2D.Expand(ADistance: Single);
var
  LIndex: Integer;
  LEdgeNormals: array[0..MAX_POINTS_ON_WINDING_2D - 1] of TIdVec2;
begin
  for LIndex := 0 to FCount - 1 do
  begin
    LEdgeNormals[LIndex].X := FPoints[LIndex].Y - FPoints[(LIndex + 1) mod FCount].Y;
    LEdgeNormals[LIndex].Y := FPoints[(LIndex + 1) mod FCount].X - FPoints[LIndex].X;
    LEdgeNormals[LIndex].Normalize;
    LEdgeNormals[LIndex] := LEdgeNormals[LIndex] * ADistance;
  end;
  for LIndex := 0 to FCount - 1 do
    FPoints[LIndex] := FPoints[LIndex] + (LEdgeNormals[LIndex] + LEdgeNormals[(LIndex + FCount - 1) mod FCount]);
end;

function TGeoWinding2D.Split(const APlane: TGeoVec3; AEpsilon: Single; out AFront, ABack: TGeoWinding2D): Integer;
var
  LDists: array[0..MAX_POINTS_ON_WINDING_2D] of Single;
  LSides: array[0..MAX_POINTS_ON_WINDING_2D] of Byte;
  LCounts: array[0..2] of Integer;
  LDot: Single;
  LIndex, LAxis: Integer;
  LPoint1, LPoint2, LMid: TIdVec2;
begin
  LCounts[0] := 0;
  LCounts[1] := 0;
  LCounts[2] := 0;
  for LIndex := 0 to FCount - 1 do
  begin
    LDot := PlaneValue(APlane, FPoints[LIndex]);
    LDists[LIndex] := LDot;
    if LDot > AEpsilon then
      LSides[LIndex] := PLANESIDE_FRONT
    else if LDot < -AEpsilon then
      LSides[LIndex] := PLANESIDE_BACK
    else
      LSides[LIndex] := PLANESIDE_ON;
    Inc(LCounts[LSides[LIndex]]);
  end;
  // the original writes sides[numPoints] and dists[numPoints] even for 16 points (past its arrays)
  LSides[FCount] := LSides[0];
  LDists[FCount] := LDists[0];
  AFront := nil;
  ABack := nil;
  if LCounts[PLANESIDE_FRONT] = 0 then
  begin
    ABack := Copy;
    Exit(PLANESIDE_BACK);
  end;
  if LCounts[PLANESIDE_BACK] = 0 then
  begin
    AFront := Copy;
    Exit(PLANESIDE_FRONT);
  end;
  AFront := TGeoWinding2D.Create;
  ABack := TGeoWinding2D.Create;
  for LIndex := 0 to FCount - 1 do
  begin
    LPoint1 := FPoints[LIndex];
    if LSides[LIndex] = PLANESIDE_ON then
    begin
      AFront.AddPoint(LPoint1);
      ABack.AddPoint(LPoint1);
      Continue;
    end;
    if LSides[LIndex] = PLANESIDE_FRONT then
      AFront.AddPoint(LPoint1);
    if LSides[LIndex] = PLANESIDE_BACK then
      ABack.AddPoint(LPoint1);
    if (LSides[LIndex + 1] = PLANESIDE_ON) or (LSides[LIndex + 1] = LSides[LIndex]) then
      Continue;
    LPoint2 := FPoints[(LIndex + 1) mod FCount];
    // the split is always calculated going from the same side
    if LSides[LIndex] = PLANESIDE_FRONT then
    begin
      LDot := LDists[LIndex] / (LDists[LIndex] - LDists[LIndex + 1]);
      for LAxis := 0 to 1 do
      begin
        if APlane[LAxis] = 1.0 then
          LMid[LAxis] := APlane.Z
        else if APlane[LAxis] = -1.0 then
          LMid[LAxis] := -APlane.Z
        else
          LMid[LAxis] := LPoint1[LAxis] + LDot * (LPoint2[LAxis] - LPoint1[LAxis]);
      end;
    end
    else
    begin
      LDot := LDists[LIndex + 1] / (LDists[LIndex + 1] - LDists[LIndex]);
      for LAxis := 0 to 1 do
      begin
        if APlane[LAxis] = 1.0 then
          LMid[LAxis] := APlane.Z
        else if APlane[LAxis] = -1.0 then
          LMid[LAxis] := -APlane.Z
        else
          LMid[LAxis] := LPoint2[LAxis] + LDot * (LPoint1[LAxis] - LPoint2[LAxis]);
      end;
    end;
    AFront.AddPoint(LMid);
    ABack.AddPoint(LMid);
  end;
  Result := PLANESIDE_CROSS;
end;

function TGeoWinding2D.ClipInPlace(const APlane: TGeoVec3; AEpsilon: Single; AKeepOn: Boolean): Boolean;
var
  LSides: array[0..MAX_POINTS_ON_WINDING_2D] of Integer;
  LDists: array[0..MAX_POINTS_ON_WINDING_2D] of Single;
  LCounts: array[0..2] of Integer;
  LNewPoints: array[0..MAX_POINTS_ON_WINDING_2D + 3] of TIdVec2;
  LDot: Single;
  LIndex, LAxis, LMaxPoints, LNewCount: Integer;
  LPoint1, LPoint2, LMid: TIdVec2;
begin
  LCounts[0] := 0;
  LCounts[1] := 0;
  LCounts[2] := 0;
  for LIndex := 0 to FCount - 1 do
  begin
    LDot := PlaneValue(APlane, FPoints[LIndex]);
    LDists[LIndex] := LDot;
    if LDot > AEpsilon then
      LSides[LIndex] := PLANESIDE_FRONT
    else if LDot < -AEpsilon then
      LSides[LIndex] := PLANESIDE_BACK
    else
      LSides[LIndex] := PLANESIDE_ON;
    Inc(LCounts[LSides[LIndex]]);
  end;
  LSides[FCount] := LSides[0];
  LDists[FCount] := LDists[0];
  if AKeepOn and (LCounts[PLANESIDE_FRONT] = 0) and (LCounts[PLANESIDE_BACK] = 0) then
    Exit(True);
  if LCounts[PLANESIDE_FRONT] = 0 then
  begin
    FCount := 0;
    Exit(False);
  end;
  if LCounts[PLANESIDE_BACK] = 0 then
    Exit(True);
  LMaxPoints := FCount + 4;
  LNewCount := 0;
  for LIndex := 0 to FCount - 1 do
  begin
    LPoint1 := FPoints[LIndex];
    if LNewCount + 1 > LMaxPoints then
      Exit(True);
    if LSides[LIndex] = PLANESIDE_ON then
    begin
      LNewPoints[LNewCount] := LPoint1;
      Inc(LNewCount);
      Continue;
    end;
    if LSides[LIndex] = PLANESIDE_FRONT then
    begin
      LNewPoints[LNewCount] := LPoint1;
      Inc(LNewCount);
    end;
    if (LSides[LIndex + 1] = PLANESIDE_ON) or (LSides[LIndex + 1] = LSides[LIndex]) then
      Continue;
    if LNewCount + 1 > LMaxPoints then
      Exit(True);
    LPoint2 := FPoints[(LIndex + 1) mod FCount];
    LDot := LDists[LIndex] / (LDists[LIndex] - LDists[LIndex + 1]);
    for LAxis := 0 to 1 do
    begin
      if APlane[LAxis] = 1.0 then
        LMid[LAxis] := APlane.Z
      else if APlane[LAxis] = -1.0 then
        LMid[LAxis] := -APlane.Z
      else
        LMid[LAxis] := LPoint1[LAxis] + LDot * (LPoint2[LAxis] - LPoint1[LAxis]);
    end;
    LNewPoints[LNewCount] := LMid;
    Inc(LNewCount);
  end;
  if LNewCount >= MAX_POINTS_ON_WINDING_2D then
    Exit(True);
  FCount := LNewCount;
  for LIndex := 0 to LNewCount - 1 do
    FPoints[LIndex] := LNewPoints[LIndex];
  Result := True;
end;

function TGeoWinding2D.Copy: TGeoWinding2D;
begin
  Result := TGeoWinding2D.Create;
  Result.Assign(Self);
end;

function TGeoWinding2D.Reverse: TGeoWinding2D;
var
  LIndex: Integer;
begin
  Result := TGeoWinding2D.Create;
  Result.FCount := FCount;
  for LIndex := 0 to FCount - 1 do
    Result.FPoints[FCount - LIndex - 1] := FPoints[LIndex];
end;

function TGeoWinding2D.GetArea: Single;
var
  LIndex: Integer;
  LFirst, LSecond: TIdVec2;
  LTotal: Single;
begin
  LTotal := 0;
  for LIndex := 2 to FCount - 1 do
  begin
    LFirst := FPoints[LIndex - 1] - FPoints[0];
    LSecond := FPoints[LIndex] - FPoints[0];
    LTotal := LTotal + (LFirst.X * LSecond.Y - LFirst.Y * LSecond.X);
  end;
  Result := LTotal * 0.5;
end;

function TGeoWinding2D.GetCenter: TIdVec2;
var
  LIndex: Integer;
  LScale: Single;
begin
  if FCount = 0 then
  begin
    Result.X := Single(NaN);
    Result.Y := Result.X;
    Exit;
  end;
  Result.Zero;
  for LIndex := 0 to FCount - 1 do
    Result := Result + FPoints[LIndex];
  LScale := 1.0 / FCount;
  Result := Result * LScale;
end;

function TGeoWinding2D.GetRadius(const ACenter: TIdVec2): Single;
var
  LIndex: Integer;
  LRadius, LSquare: Single;
  LDir: TIdVec2;
begin
  LRadius := 0;
  for LIndex := 0 to FCount - 1 do
  begin
    LDir := FPoints[LIndex] - ACenter;
    LSquare := LDir * LDir;
    if LSquare > LRadius then
      LRadius := LSquare;
  end;
  Result := TGeoMath.Sqrt(LRadius);
end;

procedure TGeoWinding2D.GetBounds(out AMins, AMaxs: TIdVec2);
var
  LIndex: Integer;
begin
  if FCount = 0 then
  begin
    AMins.X := GEO_INFINITY;
    AMins.Y := GEO_INFINITY;
    AMaxs.X := -GEO_INFINITY;
    AMaxs.Y := -GEO_INFINITY;
    Exit;
  end;
  AMins := FPoints[0];
  AMaxs := FPoints[0];
  for LIndex := 1 to FCount - 1 do
  begin
    if FPoints[LIndex].X < AMins.X then
      AMins.X := FPoints[LIndex].X
    else if FPoints[LIndex].X > AMaxs.X then
      AMaxs.X := FPoints[LIndex].X;
    if FPoints[LIndex].Y < AMins.Y then
      AMins.Y := FPoints[LIndex].Y
    else if FPoints[LIndex].Y > AMaxs.Y then
      AMaxs.Y := FPoints[LIndex].Y;
  end;
end;

function TGeoWinding2D.IsTiny: Boolean;
var
  LIndex, LEdges: Integer;
  LDelta: TIdVec2;
begin
  LEdges := 0;
  for LIndex := 0 to FCount - 1 do
  begin
    LDelta := FPoints[(LIndex + 1) mod FCount] - FPoints[LIndex];
    if LDelta.Length > EDGE_LENGTH then
    begin
      Inc(LEdges);
      if LEdges = 3 then
        Exit(False);
    end;
  end;
  Result := True;
end;

function TGeoWinding2D.IsHuge: Boolean;
var
  LIndex, LAxis: Integer;
begin
  for LIndex := 0 to FCount - 1 do
    for LAxis := 0 to 1 do
      if (FPoints[LIndex][LAxis] <= MIN_WORLD_COORD) or (FPoints[LIndex][LAxis] >= MAX_WORLD_COORD) then
        Exit(True);
  Result := False;
end;

function TGeoWinding2D.PlaneDistance(const APlane: TGeoVec3): Single;
var
  LIndex: Integer;
  LDistance, LMin, LMax: Single;
begin
  LMin := GEO_INFINITY;
  LMax := -LMin;
  for LIndex := 0 to FCount - 1 do
  begin
    LDistance := PlaneValue(APlane, FPoints[LIndex]);
    if LDistance < LMin then
    begin
      LMin := LDistance;
      if (TGeoMath.FloatSignBitSet(LMin) and TGeoMath.FloatSignBitNotSet(LMax)) <> 0 then
        Exit(0);
    end;
    if LDistance > LMax then
    begin
      LMax := LDistance;
      if (TGeoMath.FloatSignBitSet(LMin) and TGeoMath.FloatSignBitNotSet(LMax)) <> 0 then
        Exit(0);
    end;
  end;
  if TGeoMath.FloatSignBitNotSet(LMin) <> 0 then
    Exit(LMin);
  if TGeoMath.FloatSignBitSet(LMax) <> 0 then
    Exit(LMax);
  Result := 0;
end;

function TGeoWinding2D.PlaneSide(const APlane: TGeoVec3; AEpsilon: Single): Integer;
var
  LIndex: Integer;
  LDistance: Single;
  LFront, LBack: Boolean;
begin
  LFront := False;
  LBack := False;
  for LIndex := 0 to FCount - 1 do
  begin
    LDistance := PlaneValue(APlane, FPoints[LIndex]);
    if LDistance < -AEpsilon then
    begin
      if LFront then
        Exit(PLANESIDE_CROSS);
      LBack := True;
    end
    else if LDistance > AEpsilon then
    begin
      if LBack then
        Exit(PLANESIDE_CROSS);
      LFront := True;
    end;
  end;
  if LBack then
    Exit(PLANESIDE_BACK);
  if LFront then
    Exit(PLANESIDE_FRONT);
  Result := PLANESIDE_ON;
end;

function TGeoWinding2D.PointInside(const APoint: TIdVec2; AEpsilon: Single): Boolean;
var
  LIndex: Integer;
  LPlane: TGeoVec3;
begin
  for LIndex := 0 to FCount - 1 do
  begin
    LPlane := Plane2DFromPoints(FPoints[LIndex], FPoints[(LIndex + 1) mod FCount]);
    if PlaneValue(LPlane, APoint) > AEpsilon then
      Exit(False);
  end;
  Result := True;
end;

function TGeoWinding2D.LineIntersection(const AStart, AEnd: TIdVec2): Boolean;
var
  LIndex, LEdgeCount: Integer;
  LSides: array[0..MAX_POINTS_ON_WINDING_2D] of Integer;
  LCounts: array[0..2] of Integer;
  LDist1, LDist2: Single;
  LPlane: TGeoVec3;
  LEdges: array[0..1] of TGeoVec3;
begin
  LCounts[0] := 0;
  LCounts[1] := 0;
  LCounts[2] := 0;
  LPlane := Plane2DFromPoints(AStart, AEnd);
  for LIndex := 0 to FCount - 1 do
  begin
    LDist1 := PlaneValue(LPlane, FPoints[LIndex]);
    if LDist1 > 0.1 then
      LSides[LIndex] := PLANESIDE_FRONT
    else if LDist1 < -0.1 then
      LSides[LIndex] := PLANESIDE_BACK
    else
      LSides[LIndex] := PLANESIDE_ON;
    Inc(LCounts[LSides[LIndex]]);
  end;
  LSides[FCount] := LSides[0];
  if LCounts[PLANESIDE_FRONT] = 0 then
    Exit(False);
  if LCounts[PLANESIDE_BACK] = 0 then
    Exit(False);
  LEdgeCount := 0;
  for LIndex := 0 to FCount - 1 do
  begin
    if (LSides[LIndex] <> LSides[LIndex + 1]) and (LSides[LIndex + 1] <> PLANESIDE_ON) then
    begin
      LEdges[LEdgeCount] := Plane2DFromPoints(FPoints[LIndex], FPoints[(LIndex + 1) mod FCount]);
      Inc(LEdgeCount);
      if LEdgeCount >= 2 then
        Break;
    end;
  end;
  if LEdgeCount < 2 then
    Exit(False);
  LDist1 := PlaneValue(LEdges[0], AStart);
  LDist2 := PlaneValue(LEdges[0], AEnd);
  if (TGeoMath.FloatSignBitNotSet(LDist1) and TGeoMath.FloatSignBitNotSet(LDist2)) <> 0 then
    Exit(False);
  LDist1 := PlaneValue(LEdges[1], AStart);
  LDist2 := PlaneValue(LEdges[1], AEnd);
  if (TGeoMath.FloatSignBitNotSet(LDist1) and TGeoMath.FloatSignBitNotSet(LDist2)) <> 0 then
    Exit(False);
  Result := True;
end;

function TGeoWinding2D.RayIntersection(const AStart, ADir: TIdVec2; out AScale1, AScale2: Single): Boolean;
var
  LEdge1, LEdge2: Integer;
begin
  Result := RayIntersection(AStart, ADir, AScale1, AScale2, LEdge1, LEdge2);
end;

function TGeoWinding2D.RayIntersection(const AStart, ADir: TIdVec2; out AScale1, AScale2: Single;
  out AEdge1, AEdge2: Integer): Boolean;
var
  LIndex, LEdgeCount, LTemp: Integer;
  LSides: array[0..MAX_POINTS_ON_WINDING_2D] of Integer;
  LCounts: array[0..2] of Integer;
  LLocalEdges: array[0..1] of Integer;
  LDist1, LDist2, LSwap: Single;
  LPlane: TGeoVec3;
  LEdges: array[0..1] of TGeoVec3;
begin
  AScale1 := 0;
  AScale2 := 0;
  AEdge1 := -1;
  AEdge2 := -1;
  LCounts[0] := 0;
  LCounts[1] := 0;
  LCounts[2] := 0;
  LPlane := Plane2DFromVecs(AStart, ADir);
  for LIndex := 0 to FCount - 1 do
  begin
    LDist1 := PlaneValue(LPlane, FPoints[LIndex]);
    if LDist1 > 0.1 then
      LSides[LIndex] := PLANESIDE_FRONT
    else if LDist1 < -0.1 then
      LSides[LIndex] := PLANESIDE_BACK
    else
      LSides[LIndex] := PLANESIDE_ON;
    Inc(LCounts[LSides[LIndex]]);
  end;
  LSides[FCount] := LSides[0];
  if LCounts[PLANESIDE_FRONT] = 0 then
    Exit(False);
  if LCounts[PLANESIDE_BACK] = 0 then
    Exit(False);
  LEdgeCount := 0;
  for LIndex := 0 to FCount - 1 do
  begin
    if (LSides[LIndex] <> LSides[LIndex + 1]) and (LSides[LIndex + 1] <> PLANESIDE_ON) then
    begin
      LLocalEdges[LEdgeCount] := LIndex;
      LEdges[LEdgeCount] := Plane2DFromPoints(FPoints[LIndex], FPoints[(LIndex + 1) mod FCount]);
      Inc(LEdgeCount);
      if LEdgeCount >= 2 then
        Break;
    end;
  end;
  if LEdgeCount < 2 then
    Exit(False);
  LDist1 := PlaneValue(LEdges[0], AStart);
  LDist2 := -(LEdges[0].X * ADir.X + LEdges[0].Y * ADir.Y);
  if LDist2 = 0 then
    Exit(False);
  AScale1 := LDist1 / LDist2;
  LDist1 := PlaneValue(LEdges[1], AStart);
  LDist2 := -(LEdges[1].X * ADir.X + LEdges[1].Y * ADir.Y);
  if LDist2 = 0 then
    Exit(False);
  AScale2 := LDist1 / LDist2;
  if TGeoMath.Fabs(AScale1) > TGeoMath.Fabs(AScale2) then
  begin
    LSwap := AScale1;
    AScale1 := AScale2;
    AScale2 := LSwap;
    LTemp := LLocalEdges[0];
    LLocalEdges[0] := LLocalEdges[1];
    LLocalEdges[1] := LTemp;
  end;
  AEdge1 := LLocalEdges[0];
  AEdge2 := LLocalEdges[1];
  Result := True;
end;

end.
