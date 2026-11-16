{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  the temporary box model                                                     }
{                                                                              }
{  Port of CM_InitBoxHull and CM_TempBoxModel of cm_load.c from the Quake III  }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.BoxHull;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.ClipMap;

type
  /// <summary>
  ///   To allow boxes to be treated as brush models, the map has the planes, brush sides and
  ///   brush of a box after its own (the arrays have the room for them); CM_TempBoxModel sets
  ///   their distances and bounds from a box and hands back a handle for it.
  /// </summary>
  TQ3BoxHull = class
  public
    /// <summary>CM_InitBoxHull: the six planes and sides of the box hull; the map must have the room for them</summary>
    class procedure Initialize(const AMap: TQ3ClipMap); static;
    /// <summary>CM_TempBoxModel: Q3_BOX_MODEL_HANDLE, or the capsule handle (the bounds are set as well)</summary>
    class function TempBoxModel(const AMap: TQ3ClipMap; const AMins, AMaxs: TQ3Vec3;
      const ACapsule: Boolean): Integer; static;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Math;

class procedure TQ3BoxHull.Initialize(const AMap: TQ3ClipMap);
var
  LIndex, LSide, LAxis: Integer;
  LPlane: PQ3Plane;
begin
  AMap.BoxBrush := AMap.NumBrushes;
  AMap.Brushes[AMap.NumBrushes].NumSides := 6;
  AMap.Brushes[AMap.NumBrushes].FirstSide := AMap.NumBrushSides;
  AMap.Brushes[AMap.NumBrushes].Contents := Q3_CONTENTS_BODY;

  AMap.BoxModel.Leaf.NumLeafBrushes := 1;
  AMap.BoxModel.Leaf.FirstLeafBrush := AMap.NumLeafBrushes;
  AMap.LeafBrushes[AMap.NumLeafBrushes] := AMap.NumBrushes;

  for LIndex := 0 to 5 do
  begin
    LSide := LIndex and 1;
    LAxis := LIndex shr 1;

    // brush sides
    AMap.BrushSides[AMap.NumBrushSides + LIndex].PlaneNum := AMap.NumPlanes + LIndex * 2 + LSide;
    AMap.BrushSides[AMap.NumBrushSides + LIndex].SurfaceFlags := 0;

    // planes
    LPlane := @AMap.Planes[AMap.NumPlanes + LIndex * 2];
    LPlane^.PlaneType := LAxis;
    LPlane^.SignBits := 0;
    LPlane^.Normal[0] := 0;
    LPlane^.Normal[1] := 0;
    LPlane^.Normal[2] := 0;
    LPlane^.Normal[LAxis] := 1;

    LPlane := @AMap.Planes[AMap.NumPlanes + LIndex * 2 + 1];
    LPlane^.PlaneType := 3 + LAxis;
    LPlane^.Normal[0] := 0;
    LPlane^.Normal[1] := 0;
    LPlane^.Normal[2] := 0;
    LPlane^.Normal[LAxis] := -1;
    LPlane^.SignBits := TQ3Math.SignBitsOf(LPlane^.Normal);
  end;
end;

class function TQ3BoxHull.TempBoxModel(const AMap: TQ3ClipMap; const AMins, AMaxs: TQ3Vec3;
  const ACapsule: Boolean): Integer;
var
  LBase, LAxis: Integer;
begin
  AMap.BoxModel.Mins := AMins;
  AMap.BoxModel.Maxs := AMaxs;

  if ACapsule then
    Exit(Q3_CAPSULE_MODEL_HANDLE);

  LBase := AMap.NumPlanes;
  for LAxis := 0 to 2 do
  begin
    AMap.Planes[LBase + LAxis * 4].Dist := AMaxs[LAxis];
    AMap.Planes[LBase + LAxis * 4 + 1].Dist := -AMaxs[LAxis];
    AMap.Planes[LBase + LAxis * 4 + 2].Dist := AMins[LAxis];
    AMap.Planes[LBase + LAxis * 4 + 3].Dist := -AMins[LAxis];
  end;

  AMap.Brushes[AMap.BoxBrush].Bounds[0] := AMins;
  AMap.Brushes[AMap.BoxBrush].Bounds[1] := AMaxs;

  Result := Q3_BOX_MODEL_HANDLE;
end;

end.
