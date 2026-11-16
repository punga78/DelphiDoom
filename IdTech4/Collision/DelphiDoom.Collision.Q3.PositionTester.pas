{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  position testing                                                            }
{                                                                              }
{  Port of CM_TestBoxInBrush, CM_TestInLeaf and CM_PositionTest of cm_trace.c  }
{  from the Quake III Arena GPL Source Code (id Software). Copyright (C)       }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.PositionTester;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.ClipMap, DelphiDoom.Collision.Q3.LeafLister;

type
  /// <summary>Tests whether the box of a trace work, standing still, is inside something solid</summary>
  TQ3PositionTester = class
  strict private
    FMap: TQ3ClipMap;
    FLister: TQ3LeafLister;
  public
    constructor Create(const AMap: TQ3ClipMap; const ALister: TQ3LeafLister);
    /// <summary>CM_TestBoxInBrush</summary>
    procedure TestBoxInBrush(var AWork: TQ3TraceWork; const ABrush: PQ3Brush);
    /// <summary>CM_TestInLeaf</summary>
    procedure TestInLeaf(var AWork: TQ3TraceWork; const ALeaf: PQ3Leaf);
    /// <summary>CM_PositionTest: the leaves the box touches, and what is in them</summary>
    procedure PositionTest(var AWork: TQ3TraceWork);
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Math;

constructor TQ3PositionTester.Create(const AMap: TQ3ClipMap; const ALister: TQ3LeafLister);
begin
  inherited Create;
  FMap := AMap;
  FLister := ALister;
end;

procedure TQ3PositionTester.TestBoxInBrush(var AWork: TQ3TraceWork; const ABrush: PQ3Brush);
var
  LIndex: Integer;
  LPlane: PQ3Plane;
  LDist, LDist1, LProduct: Single;
  LStartPoint: TQ3Vec3;
begin
  if ABrush^.NumSides = 0 then
    Exit;

  // special test for axial
  if (AWork.Bounds[0][0] > ABrush^.Bounds[1][0]) or (AWork.Bounds[0][1] > ABrush^.Bounds[1][1]) or
     (AWork.Bounds[0][2] > ABrush^.Bounds[1][2]) or (AWork.Bounds[1][0] < ABrush^.Bounds[0][0]) or
     (AWork.Bounds[1][1] < ABrush^.Bounds[0][1]) or (AWork.Bounds[1][2] < ABrush^.Bounds[0][2]) then
    Exit;

  // the first six planes are the axial planes, so we only need to test the remainder
  for LIndex := 6 to ABrush^.NumSides - 1 do
  begin
    LPlane := @FMap.Planes[FMap.BrushSides[ABrush^.FirstSide + LIndex].PlaneNum];

    if AWork.Sphere.Use then
    begin
      // adjust the plane distance apropriately for radius
      LDist := LPlane^.Dist + AWork.Sphere.Radius;
      // find the closest point on the capsule to the plane
      LProduct := TQ3Math.Dot(LPlane^.Normal, AWork.Sphere.Offset);
      if LProduct > 0 then
      begin
        LStartPoint[0] := AWork.Start[0] - AWork.Sphere.Offset[0];
        LStartPoint[1] := AWork.Start[1] - AWork.Sphere.Offset[1];
        LStartPoint[2] := AWork.Start[2] - AWork.Sphere.Offset[2];
      end
      else
      begin
        LStartPoint[0] := AWork.Start[0] + AWork.Sphere.Offset[0];
        LStartPoint[1] := AWork.Start[1] + AWork.Sphere.Offset[1];
        LStartPoint[2] := AWork.Start[2] + AWork.Sphere.Offset[2];
      end;
      LDist1 := TQ3Math.Dot(LStartPoint, LPlane^.Normal);
      LDist1 := LDist1 - LDist;
    end
    else
    begin
      // adjust the plane distance apropriately for mins/maxs
      LProduct := TQ3Math.Dot(AWork.Offsets[LPlane^.SignBits], LPlane^.Normal);
      LDist := LPlane^.Dist - LProduct;
      LDist1 := TQ3Math.Dot(AWork.Start, LPlane^.Normal);
      LDist1 := LDist1 - LDist;
    end;

    // if completely in front of face, no intersection
    if LDist1 > 0 then
      Exit;
  end;

  // inside this brush
  AWork.Trace.StartSolid := True;
  AWork.Trace.AllSolid := True;
  AWork.Trace.Fraction := 0;
  AWork.Trace.Contents := ABrush^.Contents;
end;

procedure TQ3PositionTester.TestInLeaf(var AWork: TQ3TraceWork; const ALeaf: PQ3Leaf);
var
  LK, LBrushNum, LSurface: Integer;
  LBrush: PQ3Brush;
  LPatch: PQ3Patch;
begin
  // test box position against all brushes in the leaf
  for LK := 0 to ALeaf^.NumLeafBrushes - 1 do
  begin
    LBrushNum := FMap.LeafBrushes[ALeaf^.FirstLeafBrush + LK];
    LBrush := @FMap.Brushes[LBrushNum];
    if LBrush^.CheckCount = FMap.CheckCount then
      Continue; // already checked this brush in another leaf
    LBrush^.CheckCount := FMap.CheckCount;

    if (LBrush^.Contents and AWork.Contents) = 0 then
      Continue;

    TestBoxInBrush(AWork, LBrush);
    if AWork.Trace.AllSolid then
      Exit;
  end;

  // test against all patches
  if not FMap.NoCurves then
    for LK := 0 to ALeaf^.NumLeafSurfaces - 1 do
    begin
      LSurface := FMap.LeafSurfaces[ALeaf^.FirstLeafSurface + LK];
      LPatch := @FMap.Patches[LSurface];
      if not LPatch^.Present then
        Continue;
      if LPatch^.CheckCount = FMap.CheckCount then
        Continue; // already checked this patch in another leaf
      LPatch^.CheckCount := FMap.CheckCount;

      if (LPatch^.Contents and AWork.Contents) = 0 then
        Continue;

      if Assigned(FMap.PatchCollides[LSurface]) and FMap.PatchCollides[LSurface].PositionTest(AWork) then
      begin
        AWork.Trace.StartSolid := True;
        AWork.Trace.AllSolid := True;
        AWork.Trace.Fraction := 0;
        AWork.Trace.Contents := LPatch^.Contents;
        Exit;
      end;
    end;
end;

procedure TQ3PositionTester.PositionTest(var AWork: TQ3TraceWork);
var
  LList: TQ3LeafList;
  LIndex: Integer;
begin
  // identify the leafs we are touching
  TQ3LeafLister.Start(LList, AWork.Start, AWork.Start, Q3_MAX_POSITION_LEAFS, False);
  for LIndex := 0 to 2 do
  begin
    LList.Bounds[0][LIndex] := AWork.Start[LIndex] + AWork.Size[0][LIndex];
    LList.Bounds[1][LIndex] := AWork.Start[LIndex] + AWork.Size[1][LIndex];
    LList.Bounds[0][LIndex] := LList.Bounds[0][LIndex] - 1;
    LList.Bounds[1][LIndex] := LList.Bounds[1][LIndex] + 1;
  end;

  Inc(FMap.CheckCount);

  FLister.Walk(LList, 0);

  Inc(FMap.CheckCount);

  // test the contents of the leafs
  for LIndex := 0 to LList.Count - 1 do
  begin
    TestInLeaf(AWork, @FMap.Leafs[LList.List[LIndex]]);
    if AWork.Trace.AllSolid then
      Break;
  end;
end;

end.
