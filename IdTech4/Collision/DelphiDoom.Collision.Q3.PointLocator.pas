{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  where a point is                                                            }
{                                                                              }
{  Port of CM_PointLeafnum_r, CM_PointLeafnum, CM_PointContents and            }
{  CM_TransformedPointContents of cm_test.c from the Quake III Arena GPL       }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.PointLocator;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.ClipMap;

type
  /// <summary>The leaf and the contents of a point</summary>
  TQ3PointLocator = class
  strict private
    FMap: TQ3ClipMap;
    function PointLeafnumRecursive(const APoint: TQ3Vec3; ANum: Integer): Integer;
  public
    constructor Create(const AMap: TQ3ClipMap);
    /// <summary>CM_PointLeafnum: 0 if the map is not loaded</summary>
    function PointLeafnum(const APoint: TQ3Vec3): Integer;
    /// <summary>CM_PointContents: the contents of all the brushes of the leaf that hold the point</summary>
    function PointContents(const APoint: TQ3Vec3; const AModel: Integer): Integer;
    /// <summary>CM_TransformedPointContents: for moving and rotating entities</summary>
    function TransformedPointContents(const APoint: TQ3Vec3; const AModel: Integer;
      const AOrigin, AAngles: TQ3Vec3): Integer;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Math;

constructor TQ3PointLocator.Create(const AMap: TQ3ClipMap);
begin
  inherited Create;
  FMap := AMap;
end;

function TQ3PointLocator.PointLeafnumRecursive(const APoint: TQ3Vec3; ANum: Integer): Integer;
var
  LNode: PQ3Node;
  LPlane: PQ3Plane;
  LDist: Single;
begin
  while ANum >= 0 do
  begin
    LNode := @FMap.Nodes[ANum];
    LPlane := @FMap.Planes[LNode^.PlaneNum];

    if LPlane^.PlaneType < 3 then
      LDist := APoint[LPlane^.PlaneType] - LPlane^.Dist
    else
      LDist := TQ3Math.Dot(LPlane^.Normal, APoint) - LPlane^.Dist;
    if LDist < 0 then
      ANum := LNode^.Children[1]
    else
      ANum := LNode^.Children[0];
  end;

  Inc(FMap.PointContentsCount); // optimize counter

  Result := -1 - ANum;
end;

function TQ3PointLocator.PointLeafnum(const APoint: TQ3Vec3): Integer;
begin
  if FMap.NumNodes = 0 then
    Exit(0); // map not loaded
  Result := PointLeafnumRecursive(APoint, 0);
end;

function TQ3PointLocator.PointContents(const APoint: TQ3Vec3; const AModel: Integer): Integer;
var
  LLeaf: PQ3Leaf;
  LK, LIndex: Integer;
  LBrush: PQ3Brush;
  LPlane: PQ3Plane;
  LDist: Single;
begin
  if FMap.NumNodes = 0 then
    Exit(0); // map not loaded

  if AModel <> 0 then
    LLeaf := @FMap.ClipHandleToModel(AModel)^.Leaf
  else
    LLeaf := @FMap.Leafs[PointLeafnumRecursive(APoint, 0)];

  Result := 0;
  for LK := 0 to LLeaf^.NumLeafBrushes - 1 do
  begin
    LBrush := @FMap.Brushes[FMap.LeafBrushes[LLeaf^.FirstLeafBrush + LK]];

    // see if the point is in the brush
    LIndex := 0;
    while LIndex < LBrush^.NumSides do
    begin
      LPlane := @FMap.Planes[FMap.BrushSides[LBrush^.FirstSide + LIndex].PlaneNum];
      LDist := TQ3Math.Dot(APoint, LPlane^.Normal);
      if LDist > LPlane^.Dist then
        Break;
      Inc(LIndex);
    end;

    if LIndex = LBrush^.NumSides then
      Result := Result or LBrush^.Contents;
  end;
end;

function TQ3PointLocator.TransformedPointContents(const APoint: TQ3Vec3; const AModel: Integer;
  const AOrigin, AAngles: TQ3Vec3): Integer;
var
  LLocal, LTemp, LForward, LRight, LUp: TQ3Vec3;
  LIndex: Integer;
begin
  // subtract origin offset
  for LIndex := 0 to 2 do
    LLocal[LIndex] := APoint[LIndex] - AOrigin[LIndex];

  // rotate start and end into the models frame of reference
  if (AModel <> Q3_BOX_MODEL_HANDLE) and ((AAngles[0] <> 0) or (AAngles[1] <> 0) or (AAngles[2] <> 0)) then
  begin
    TQ3Math.AngleVectors(AAngles, LForward, LRight, LUp);

    LTemp := LLocal;
    LLocal[0] := TQ3Math.Dot(LTemp, LForward);
    LLocal[1] := -TQ3Math.Dot(LTemp, LRight);
    LLocal[2] := TQ3Math.Dot(LTemp, LUp);
  end;

  Result := PointContents(LLocal, AModel);
end;

end.
