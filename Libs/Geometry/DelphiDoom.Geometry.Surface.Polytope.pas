{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the polytope surface                         }
{                                                                              }
{  Port of idSurface_Polytope (idlib\geometry\Surface_Polytope.h and .cpp) of  }
{  the Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a      }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Surface.Polytope;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Surface;

type
  /// <summary>
  ///   A convex surface (idSurface_Polytope): vertices are not duplicated for texture coordinates.
  ///   <c>SetupDodecahedron</c>, <c>SetupIcosahedron</c>, <c>SetupCylinder</c> and <c>SetupCone</c> of
  ///   the original have empty bodies and are not ported.
  /// </summary>
  TGeoSurfacePolytope = class(TGeoSurface)
  public
    /// <summary>
    ///   Builds the polytope bounded by the planes (the normals point outwards). Differs from the
    ///   original, whose vertex search loop increments the wrong variable and cannot finish once a
    ///   vertex exists
    /// </summary>
    procedure FromPlanes(const APlanes: array of TGeoPlane);
    procedure SetupTetrahedron(const ABounds: TGeoBounds);
    procedure SetupHexahedron(const ABounds: TGeoBounds);
    procedure SetupOctahedron(const ABounds: TGeoBounds);
    /// <summary>
    ///   Splits into a front and a back polytope and closes the cut (new objects owned by the
    ///   caller; when one side is empty it is an empty polytope, never nil). Returns PLANESIDE_*
    /// </summary>
    function SplitPolytope(const APlane: TGeoPlane; AEpsilon: Single;
      out AFront, ABack: TGeoSurfacePolytope): Integer;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.DrawVert, DelphiDoom.Geometry.Winding,
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath;

const
  POLYTOPE_VERTEX_EPSILON: Single = 0.1;
  MAX_POINTS_ON_WINDING = 64;

procedure SetIndexes(var AIndexes: TArray<Integer>; const AValues: array of Integer);
var
  LIndex: Integer;
begin
  SetLength(AIndexes, Length(AValues));
  for LIndex := 0 to High(AValues) do
    AIndexes[LIndex] := AValues[LIndex];
end;

{ TGeoSurfacePolytope }

procedure TGeoSurfacePolytope.FromPlanes(const APlanes: array of TGeoPlane);
var
  LPlane, LOther, LPoint, LVertexIndex, LCount: Integer;
  LWinding: TGeoWinding;
  LNewVert: TGeoDrawVert;
  LWindingVerts: array[0..MAX_POINTS_ON_WINDING - 1] of Integer;
begin
  FillChar(LNewVert, SizeOf(LNewVert), 0);
  for LPlane := 0 to High(APlanes) do
  begin
    LWinding := TGeoWinding.Create;
    try
      LWinding.BaseForPlane(APlanes[LPlane]);
      for LOther := 0 to High(APlanes) do
      begin
        if LOther = LPlane then
          Continue;
        if not LWinding.ClipInPlace(-APlanes[LOther], ON_EPSILON, True) then
          Break;
      end;
      if LWinding.NumPoints = 0 then
        Continue;
      for LPoint := 0 to LWinding.NumPoints - 1 do
      begin
        LVertexIndex := 0;
        while LVertexIndex < Length(FVerts) do
        begin
          if FVerts[LVertexIndex].Xyz.Compare(LWinding[LPoint], POLYTOPE_VERTEX_EPSILON) then
            Break;
          Inc(LVertexIndex);
        end;
        if LVertexIndex >= Length(FVerts) then
        begin
          LNewVert.Xyz := LWinding[LPoint];
          SetLength(FVerts, Length(FVerts) + 1);
          FVerts[High(FVerts)] := LNewVert;
          LVertexIndex := High(FVerts);
        end;
        LWindingVerts[LPoint] := LVertexIndex;
      end;
      for LPoint := 2 to LWinding.NumPoints - 1 do
      begin
        LCount := Length(FIndexes);
        SetLength(FIndexes, LCount + 3);
        FIndexes[LCount] := LWindingVerts[0];
        FIndexes[LCount + 1] := LWindingVerts[LPoint - 1];
        FIndexes[LCount + 2] := LWindingVerts[LPoint];
      end;
    finally
      LWinding.Free;
    end;
  end;
  GenerateEdgeIndexes;
end;

procedure TGeoSurfacePolytope.SetupTetrahedron(const ABounds: TGeoBounds);
var
  LCenter, LScale: TGeoVec3;
  LC1, LC2, LC3: Single;
begin
  LC1 := 0.4714045207;
  LC2 := 0.8164965809;
  LC3 := -0.3333333333;
  LCenter := ABounds.GetCenter;
  LScale := ABounds.Maxs - LCenter;
  SetLength(FVerts, 4);
  FVerts[0].Xyz := LCenter + TGeoVec3.Make(0, 0, LScale.Z);
  FVerts[1].Xyz := LCenter + TGeoVec3.Make(2.0 * LC1 * LScale.X, 0, LC3 * LScale.Z);
  FVerts[2].Xyz := LCenter + TGeoVec3.Make(-LC1 * LScale.X, LC2 * LScale.Y, LC3 * LScale.Z);
  FVerts[3].Xyz := LCenter + TGeoVec3.Make(-LC1 * LScale.X, -LC2 * LScale.Y, LC3 * LScale.Z);
  SetIndexes(FIndexes, [0, 1, 2, 0, 2, 3, 0, 3, 1, 1, 3, 2]);
  GenerateEdgeIndexes;
end;

procedure TGeoSurfacePolytope.SetupHexahedron(const ABounds: TGeoBounds);
var
  LCenter, LScale: TGeoVec3;
begin
  LCenter := ABounds.GetCenter;
  LScale := ABounds.Maxs - LCenter;
  SetLength(FVerts, 8);
  FVerts[0].Xyz := LCenter + TGeoVec3.Make(-LScale.X, -LScale.Y, -LScale.Z);
  FVerts[1].Xyz := LCenter + TGeoVec3.Make(LScale.X, -LScale.Y, -LScale.Z);
  FVerts[2].Xyz := LCenter + TGeoVec3.Make(LScale.X, LScale.Y, -LScale.Z);
  FVerts[3].Xyz := LCenter + TGeoVec3.Make(-LScale.X, LScale.Y, -LScale.Z);
  FVerts[4].Xyz := LCenter + TGeoVec3.Make(-LScale.X, -LScale.Y, LScale.Z);
  FVerts[5].Xyz := LCenter + TGeoVec3.Make(LScale.X, -LScale.Y, LScale.Z);
  FVerts[6].Xyz := LCenter + TGeoVec3.Make(LScale.X, LScale.Y, LScale.Z);
  FVerts[7].Xyz := LCenter + TGeoVec3.Make(-LScale.X, LScale.Y, LScale.Z);
  SetIndexes(FIndexes, [0, 3, 2, 0, 2, 1, 0, 1, 5, 0, 5, 4, 0, 4, 7, 0, 7, 3, 6, 5, 1, 6, 1, 2, 6, 2, 3,
    6, 3, 7, 6, 7, 4, 6, 4, 5]);
  GenerateEdgeIndexes;
end;

procedure TGeoSurfacePolytope.SetupOctahedron(const ABounds: TGeoBounds);
var
  LCenter, LScale: TGeoVec3;
begin
  LCenter := ABounds.GetCenter;
  LScale := ABounds.Maxs - LCenter;
  SetLength(FVerts, 6);
  FVerts[0].Xyz := LCenter + TGeoVec3.Make(LScale.X, 0, 0);
  FVerts[1].Xyz := LCenter + TGeoVec3.Make(-LScale.X, 0, 0);
  FVerts[2].Xyz := LCenter + TGeoVec3.Make(0, LScale.Y, 0);
  FVerts[3].Xyz := LCenter + TGeoVec3.Make(0, -LScale.Y, 0);
  FVerts[4].Xyz := LCenter + TGeoVec3.Make(0, 0, LScale.Z);
  FVerts[5].Xyz := LCenter + TGeoVec3.Make(0, 0, -LScale.Z);
  SetIndexes(FIndexes, [4, 0, 2, 4, 2, 1, 4, 1, 3, 4, 3, 0, 5, 2, 0, 5, 1, 2, 5, 3, 1, 5, 0, 3]);
  GenerateEdgeIndexes;
end;

function TGeoSurfacePolytope.SplitPolytope(const APlane: TGeoPlane; AEpsilon: Single;
  out AFront, ABack: TGeoSurfacePolytope): Integer;
var
  LSide, LS, LI, LJ, LV0, LV1, LV2, LEdgeNumber, LTemp, LCount: Integer;
  LSurface: array[0..1] of TGeoSurface;
  LPolytopes: array[0..1] of TGeoSurfacePolytope;
  LOnPlaneEdges: array[0..1] of TArray<Integer>;
  LEdge: TGeoSurfaceEdge;
  LSurf: TGeoSurfacePolytope;
begin
  SetLength(LOnPlaneEdges[0], Length(FIndexes) * 4 + 16);
  SetLength(LOnPlaneEdges[1], Length(FIndexes) * 4 + 16);
  LOnPlaneEdges[0][0] := -1;
  LOnPlaneEdges[1][0] := -1;
  LSide := Split(APlane, AEpsilon, LSurface[0], LSurface[1], @LOnPlaneEdges[0][0], @LOnPlaneEdges[1][0]);
  for LS := 0 to 1 do
  begin
    LPolytopes[LS] := TGeoSurfacePolytope.Create;
    if Assigned(LSurface[LS]) then
    begin
      LPolytopes[LS].SwapTriangles(LSurface[LS]);
      LSurface[LS].Free;
    end;
  end;
  AFront := LPolytopes[0];
  ABack := LPolytopes[1];
  if LSide <> PLANESIDE_CROSS then
    Exit(LSide);
  // add triangles to close off the front and back polytope
  for LS := 0 to 1 do
  begin
    LSurf := LPolytopes[LS];
    if LOnPlaneEdges[LS][0] < 0 then
      Continue;
    LEdgeNumber := LSurf.FEdgeIndexes[LOnPlaneEdges[LS][0]];
    LEdge := LSurf.FEdges[Abs(LEdgeNumber)];
    LV0 := LEdge.Verts[Integer(TGeoMath.IntSignBitSet(LEdgeNumber))];
    LV1 := LEdge.Verts[Integer(TGeoMath.IntSignBitNotSet(LEdgeNumber))];
    LI := 1;
    while LOnPlaneEdges[LS][LI] >= 0 do
    begin
      LJ := LI + 1;
      while LOnPlaneEdges[LS][LJ] >= 0 do
      begin
        LEdgeNumber := LSurf.FEdgeIndexes[LOnPlaneEdges[LS][LJ]];
        LEdge := LSurf.FEdges[Abs(LEdgeNumber)];
        if LV1 = LEdge.Verts[Integer(TGeoMath.IntSignBitSet(LEdgeNumber))] then
        begin
          LV1 := LEdge.Verts[Integer(TGeoMath.IntSignBitNotSet(LEdgeNumber))];
          LTemp := LOnPlaneEdges[LS][LI];
          LOnPlaneEdges[LS][LI] := LOnPlaneEdges[LS][LJ];
          LOnPlaneEdges[LS][LJ] := LTemp;
          Break;
        end;
        Inc(LJ);
      end;
      Inc(LI);
    end;
    LI := 2;
    while LOnPlaneEdges[LS][LI] >= 0 do
    begin
      LEdgeNumber := LSurf.FEdgeIndexes[LOnPlaneEdges[LS][LI]];
      LEdge := LSurf.FEdges[Abs(LEdgeNumber)];
      LV1 := LEdge.Verts[Integer(TGeoMath.IntSignBitNotSet(LEdgeNumber))];
      LV2 := LEdge.Verts[Integer(TGeoMath.IntSignBitSet(LEdgeNumber))];
      LCount := Length(LSurf.FIndexes);
      SetLength(LSurf.FIndexes, LCount + 3);
      LSurf.FIndexes[LCount] := LV0;
      LSurf.FIndexes[LCount + 1] := LV1;
      LSurf.FIndexes[LCount + 2] := LV2;
      Inc(LI);
    end;
    LSurf.GenerateEdgeIndexes;
  end;
  Result := LSide;
end;

end.
