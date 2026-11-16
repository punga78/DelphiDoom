{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  the collision of one patch                                                  }
{                                                                              }
{  Port of patchCollide_t and of CM_TraceThroughPatchCollide,                  }
{  CM_TracePointThroughPatchCollide, CM_CheckFacetPlane and                    }
{  CM_PositionTestInPatchCollide (cm_patch.c) of the Quake III Arena GPL       }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.PatchCollide;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Intf;

type
  /// <summary>
  ///   The facets and planes of a patch (patchCollide_t) and the tests of a trace against them. The
  ///   data is read only after construction, so one object can be used by several traces
  /// </summary>
  TQ3PatchCollide = class(TInterfacedObject, IQ3PatchCollide)
  private
    FBounds: array[0..1] of TQ3Vec3;
    FPlanes: TArray<TQ3PatchPlane>;
    FFacets: TArray<TQ3Facet>;
    procedure TracePointThrough(var AWork: TQ3TraceWork);
    class function CheckFacetPlane(const APlane: TQ3PatchPlaneValue; const AStart, AEnd: TQ3Vec3;
      var AEnterFrac, ALeaveFrac: Single; out AHit: Boolean): Boolean; static;
  public
    /// <summary>The bounds are those of the grid (the builder widens them by one unit)</summary>
    constructor Create(const AMins, AMaxs: TQ3Vec3; const APlanes: TArray<TQ3PatchPlane>;
      const AFacets: TArray<TQ3Facet>);
    procedure TraceThrough(var AWork: TQ3TraceWork);
    function PositionTest(const AWork: TQ3TraceWork): Boolean;
    function Bounds(AIndex: Integer): TQ3Vec3;
    function NumPlanes: Integer;
    function NumFacets: Integer;
    function Plane(AIndex: Integer): TQ3PatchPlane;
    function Facet(AIndex: Integer): TQ3Facet;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Math, DelphiDoom.Collision.Q3.VectorMath;


/// <summary>DotProduct( vec, plane ) of a vec3_t and the first three floats of a plane</summary>
function DotPlane(const AVector: TQ3Vec3; const APlane: TQ3PatchPlaneValue): Single;
var
  LX, LY, LZ: Single;
begin
  LX := AVector[0] * APlane[0];
  LY := AVector[1] * APlane[1];
  LZ := AVector[2] * APlane[2];
  Result := LX + LY;
  Result := Result + LZ;
end;

/// <summary>The plane of the facet, pushed out by the box or the capsule (the code that trace and position test share)</summary>
procedure CapsuleEnds(const AWork: TQ3TraceWork; const APlane: TQ3PatchPlaneValue; var AStart, AEnd: TQ3Vec3);
var
  LT: Single;
  LNormal: TQ3Vec3;
begin
  LNormal[0] := APlane[0];
  LNormal[1] := APlane[1];
  LNormal[2] := APlane[2];
  // find the closest point on the capsule to the plane
  LT := TQ3Math.Dot(LNormal, AWork.Sphere.Offset);
  if LT > 0 then
  begin
    AStart := TQ3VectorMath.Subtract(AWork.Start, AWork.Sphere.Offset);
    AEnd := TQ3VectorMath.Subtract(AWork.EndPoint, AWork.Sphere.Offset);
  end
  else
  begin
    AStart := TQ3VectorMath.Add(AWork.Start, AWork.Sphere.Offset);
    AEnd := TQ3VectorMath.Add(AWork.EndPoint, AWork.Sphere.Offset);
  end;
end;

{ TQ3PatchCollide }

constructor TQ3PatchCollide.Create(const AMins, AMaxs: TQ3Vec3; const APlanes: TArray<TQ3PatchPlane>;
  const AFacets: TArray<TQ3Facet>);
begin
  inherited Create;
  FBounds[0] := AMins;
  FBounds[1] := AMaxs;
  FPlanes := APlanes;
  FFacets := AFacets;
end;

function TQ3PatchCollide.Bounds(AIndex: Integer): TQ3Vec3;
begin
  Result := FBounds[AIndex];
end;

function TQ3PatchCollide.NumPlanes: Integer;
begin
  Result := Length(FPlanes);
end;

function TQ3PatchCollide.NumFacets: Integer;
begin
  Result := Length(FFacets);
end;

function TQ3PatchCollide.Plane(AIndex: Integer): TQ3PatchPlane;
begin
  Result := FPlanes[AIndex];
end;

function TQ3PatchCollide.Facet(AIndex: Integer): TQ3Facet;
begin
  Result := FFacets[AIndex];
end;

procedure TQ3PatchCollide.TracePointThrough(var AWork: TQ3TraceWork);
const
  UNREACHED = 99999;
var
  LFrontFacing: TArray<Boolean>;
  LIntersection: TArray<Single>;
  LIntersect: Single;
  LIndex: Integer;
  LBorder: Integer;
  LPlane: Integer;
  LOffset: Single;
  LD1: Single;
  LD2: Single;
  LDelta: Single;
  LValue: TQ3PatchPlaneValue;
begin
  if (not AWork.PlayerCurveClip) or (not AWork.IsPoint) then
    Exit;

  // determine the trace's relationship to all planes
  SetLength(LFrontFacing, Length(FPlanes));
  SetLength(LIntersection, Length(FPlanes));
  for LIndex := 0 to High(FPlanes) do
  begin
    LValue := FPlanes[LIndex].Plane;
    LOffset := DotPlane(AWork.Offsets[FPlanes[LIndex].SignBits], LValue);
    LD1 := DotPlane(AWork.Start, LValue);
    LD1 := LD1 - FPlanes[LIndex].Plane[3];
    LD1 := LD1 + LOffset;
    LD2 := DotPlane(AWork.EndPoint, LValue);
    LD2 := LD2 - FPlanes[LIndex].Plane[3];
    LD2 := LD2 + LOffset;
    LFrontFacing[LIndex] := LD1 > 0;
    if LD1 = LD2 then
      LIntersection[LIndex] := UNREACHED
    else
    begin
      LDelta := LD1 - LD2;
      LIntersection[LIndex] := LD1 / LDelta;
      if LIntersection[LIndex] <= 0 then
        LIntersection[LIndex] := UNREACHED;
    end;
  end;

  // see if any of the surface planes are intersected
  for LIndex := 0 to High(FFacets) do
  begin
    if not LFrontFacing[FFacets[LIndex].SurfacePlane] then
      Continue;
    LIntersect := LIntersection[FFacets[LIndex].SurfacePlane];
    if LIntersect < 0 then
      Continue; // surface is behind the starting point
    if LIntersect > AWork.Trace.Fraction then
      Continue; // already hit something closer
    LBorder := 0;
    while LBorder < FFacets[LIndex].NumBorders do
    begin
      LPlane := FFacets[LIndex].BorderPlanes[LBorder];
      if (LFrontFacing[LPlane] xor (FFacets[LIndex].BorderInward[LBorder] <> 0)) then
      begin
        if LIntersection[LPlane] > LIntersect then
          Break;
      end
      else
      begin
        if LIntersection[LPlane] < LIntersect then
          Break;
      end;
      Inc(LBorder);
    end;
    if LBorder = FFacets[LIndex].NumBorders then
    begin
      // we hit this facet
      LPlane := FFacets[LIndex].SurfacePlane;
      LValue := FPlanes[LPlane].Plane;

      // calculate intersection with a slight pushoff
      LOffset := DotPlane(AWork.Offsets[FPlanes[LPlane].SignBits], LValue);
      LD1 := DotPlane(AWork.Start, LValue);
      LD1 := LD1 - LValue[3];
      LD1 := LD1 + LOffset;
      LD2 := DotPlane(AWork.EndPoint, LValue);
      LD2 := LD2 - LValue[3];
      LD2 := LD2 + LOffset;
      // SURFACE_CLIP_EPSILON is a double: the division is done in double
      LDelta := LD1 - LD2;
      AWork.Trace.Fraction := (Double(LD1) - Q3_SURFACE_CLIP_EPSILON) / Double(LDelta);

      if AWork.Trace.Fraction < 0 then
        AWork.Trace.Fraction := 0;

      AWork.Trace.Plane.Normal[0] := LValue[0];
      AWork.Trace.Plane.Normal[1] := LValue[1];
      AWork.Trace.Plane.Normal[2] := LValue[2];
      AWork.Trace.Plane.Dist := LValue[3];
    end;
  end;
end;

class function TQ3PatchCollide.CheckFacetPlane(const APlane: TQ3PatchPlaneValue; const AStart, AEnd: TQ3Vec3;
  var AEnterFrac, ALeaveFrac: Single; out AHit: Boolean): Boolean;
var
  LD1: Single;
  LD2: Single;
  LF: Single;
  LDelta: Single;
  LValue: TQ3PatchPlaneValue;
begin
  AHit := False;
  LValue[0] := APlane[0];
  LValue[1] := APlane[1];
  LValue[2] := APlane[2];
  LValue[3] := APlane[3];

  LD1 := DotPlane(AStart, LValue);
  LD1 := LD1 - LValue[3];
  LD2 := DotPlane(AEnd, LValue);
  LD2 := LD2 - LValue[3];

  // if completely in front of face, no intersection with the entire facet
  if (LD1 > 0) and ((LD2 >= Q3_SURFACE_CLIP_EPSILON) or (LD2 >= LD1)) then
    Exit(False);

  // if it doesn't cross the plane, the plane isn't relevent
  if (LD1 <= 0) and (LD2 <= 0) then
    Exit(True);

  LDelta := LD1 - LD2;
  // crosses face
  if LD1 > LD2 then
  begin
    // enter
    LF := (Double(LD1) - Q3_SURFACE_CLIP_EPSILON) / Double(LDelta);
    if LF < 0 then
      LF := 0;
    // always favor previous plane hits and thus also the surface plane hit
    if LF > AEnterFrac then
    begin
      AEnterFrac := LF;
      AHit := True;
    end;
  end
  else
  begin
    // leave
    LF := (Double(LD1) + Q3_SURFACE_CLIP_EPSILON) / Double(LDelta);
    if LF > 1 then
      LF := 1;
    if LF < ALeaveFrac then
      ALeaveFrac := LF;
  end;
  Result := True;
end;

procedure TQ3PatchCollide.TraceThrough(var AWork: TQ3TraceWork);
var
  LFacetIndex: Integer;
  LBorder: Integer;
  LHit: Boolean;
  LHitNum: Integer;
  LOffset: Single;
  LEnterFrac: Single;
  LLeaveFrac: Single;
  LPlane: TQ3PatchPlaneValue;
  LBestPlane: TQ3PatchPlaneValue;
  LSource: TQ3PatchPlane;
  LStartP: TQ3Vec3;
  LEndP: TQ3Vec3;
  LFacet: ^TQ3Facet;
  LSum: Double;
begin
  if AWork.IsPoint then
  begin
    TracePointThrough(AWork);
    Exit;
  end;

  for LFacetIndex := 0 to High(FFacets) do
  begin
    LFacet := @FFacets[LFacetIndex];
    LEnterFrac := -1.0;
    LLeaveFrac := 1.0;
    LHitNum := -1;
    LBestPlane := Default(TQ3PatchPlaneValue);

    LSource := FPlanes[LFacet.SurfacePlane];
    LPlane := LSource.Plane;
    if AWork.Sphere.Use then
    begin
      // adjust the plane distance apropriately for radius
      LPlane[3] := LPlane[3] + AWork.Sphere.Radius;
      CapsuleEnds(AWork, LPlane, LStartP, LEndP);
    end
    else
    begin
      LOffset := DotPlane(AWork.Offsets[LSource.SignBits], LPlane);
      LPlane[3] := LPlane[3] - LOffset;
      LStartP := AWork.Start;
      LEndP := AWork.EndPoint;
    end;

    if not CheckFacetPlane(LPlane, LStartP, LEndP, LEnterFrac, LLeaveFrac, LHit) then
      Continue;
    if LHit then
      LBestPlane := LPlane;

    LBorder := 0;
    while LBorder < LFacet.NumBorders do
    begin
      LSource := FPlanes[LFacet.BorderPlanes[LBorder]];
      if LFacet.BorderInward[LBorder] <> 0 then
      begin
        LPlane[0] := -LSource.Plane[0];
        LPlane[1] := -LSource.Plane[1];
        LPlane[2] := -LSource.Plane[2];
        LPlane[3] := -LSource.Plane[3];
      end
      else
        LPlane := LSource.Plane;
      if AWork.Sphere.Use then
      begin
        // adjust the plane distance apropriately for radius
        LPlane[3] := LPlane[3] + AWork.Sphere.Radius;
        CapsuleEnds(AWork, LPlane, LStartP, LEndP);
      end
      else
      begin
        // NOTE: this works even though the plane might be flipped because the bbox is centered
        LOffset := DotPlane(AWork.Offsets[LSource.SignBits], LPlane);
        // fabs() returns a double: the sum is done in double
        LSum := Double(LPlane[3]) + Abs(Double(LOffset));
        LPlane[3] := LSum;
        LStartP := AWork.Start;
        LEndP := AWork.EndPoint;
      end;

      if not CheckFacetPlane(LPlane, LStartP, LEndP, LEnterFrac, LLeaveFrac, LHit) then
        Break;
      if LHit then
      begin
        LHitNum := LBorder;
        LBestPlane := LPlane;
      end;
      Inc(LBorder);
    end;
    if LBorder < LFacet.NumBorders then
      Continue;
    // never clip against the back side
    if LHitNum = LFacet.NumBorders - 1 then
      Continue;

    if (LEnterFrac < LLeaveFrac) and (LEnterFrac >= 0) then
      if LEnterFrac < AWork.Trace.Fraction then
      begin
        if LEnterFrac < 0 then
          LEnterFrac := 0;
        AWork.Trace.Fraction := LEnterFrac;
        AWork.Trace.Plane.Normal[0] := LBestPlane[0];
        AWork.Trace.Plane.Normal[1] := LBestPlane[1];
        AWork.Trace.Plane.Normal[2] := LBestPlane[2];
        AWork.Trace.Plane.Dist := LBestPlane[3];
      end;
  end;
end;

function TQ3PatchCollide.PositionTest(const AWork: TQ3TraceWork): Boolean;
var
  LFacetIndex: Integer;
  LBorder: Integer;
  LOffset: Single;
  LPlane: TQ3PatchPlaneValue;
  LSource: TQ3PatchPlane;
  LStartP: TQ3Vec3;
  LEndP: TQ3Vec3;
  LFacet: ^TQ3Facet;
  LDistance: Single;
begin
  if AWork.IsPoint then
    Exit(False);

  for LFacetIndex := 0 to High(FFacets) do
  begin
    LFacet := @FFacets[LFacetIndex];
    LSource := FPlanes[LFacet.SurfacePlane];
    LPlane := LSource.Plane;
    if AWork.Sphere.Use then
    begin
      // adjust the plane distance apropriately for radius
      LPlane[3] := LPlane[3] + AWork.Sphere.Radius;
      CapsuleEnds(AWork, LPlane, LStartP, LEndP);
    end
    else
    begin
      LOffset := DotPlane(AWork.Offsets[LSource.SignBits], LPlane);
      LPlane[3] := LPlane[3] - LOffset;
      LStartP := AWork.Start;
    end;

    LDistance := DotPlane(LStartP, LPlane);
    if LDistance - LPlane[3] > 0 then
      Continue;

    LBorder := 0;
    while LBorder < LFacet.NumBorders do
    begin
      LSource := FPlanes[LFacet.BorderPlanes[LBorder]];
      if LFacet.BorderInward[LBorder] <> 0 then
      begin
        LPlane[0] := -LSource.Plane[0];
        LPlane[1] := -LSource.Plane[1];
        LPlane[2] := -LSource.Plane[2];
        LPlane[3] := -LSource.Plane[3];
      end
      else
        LPlane := LSource.Plane;
      if AWork.Sphere.Use then
      begin
        // adjust the plane distance apropriately for radius
        LPlane[3] := LPlane[3] + AWork.Sphere.Radius;
        CapsuleEnds(AWork, LPlane, LStartP, LEndP);
      end
      else
      begin
        // NOTE: this works even though the plane might be flipped because the bbox is centered
        LOffset := DotPlane(AWork.Offsets[LSource.SignBits], LPlane);
        LPlane[3] := Double(LPlane[3]) + Abs(Double(LOffset));
        LStartP := AWork.Start;
      end;

      LDistance := DotPlane(LStartP, LPlane);
      if LDistance - LPlane[3] > 0 then
        Break;
      Inc(LBorder);
    end;
    if LBorder < LFacet.NumBorders then
      Continue;
    // inside this patch facet
    Exit(True);
  end;
  Result := False;
end;

end.
