{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  the collision geometry of a patch                                           }
{                                                                              }
{  Port of CM_GeneratePatchCollide and of the functions it uses               }
{  (CM_PatchCollideFromGrid, CM_FindPlane, CM_FindPlane2, CM_PlaneEqual,       }
{  CM_SnapVector, CM_PointOnPlaneSide, CM_GridPlane, CM_EdgePlaneNum,          }
{  CM_SetBorderInward, CM_ValidateFacet, CM_AddFacetBevels) of cm_patch.c of   }
{  the Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005  }
{  Id Software, Inc. This unit is derived from the Quake III Arena source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 2 or (at your option) any later version.                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.PatchCollideBuilder;

{$Q-}
{$R-}

interface

uses
  System.Generics.Collections, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Intf,
  DelphiDoom.Collision.Q3.PatchGrid;

const
  /// <summary>MAX_FACETS of cm_patch.h</summary>
  Q3_MAX_FACETS = 1024;
  /// <summary>MAX_PATCH_PLANES of cm_patch.h</summary>
  Q3_MAX_PATCH_PLANES = 2048;

type
  /// <summary>
  ///   Creates the collision geometry of a patch from its control points (CM_GeneratePatchCollide):
  ///   the grid is subdivided until it is on the curve, every triangle (or quad) of the grid becomes
  ///   a facet bounded by border planes, axial bevels and edge bevels. The static planes and facets
  ///   of the C are fields: one object builds one patch at a time. The errors of the original
  ///   (ERR_DROP) are EQ3CollisionException
  /// </summary>
  TQ3PatchCollideBuilder = class(TInterfacedObject, IQ3PatchCollideBuilder)
  private
    type
      TGridPlanes = TArray<Integer>;
  private
    FPlanes: TList<TQ3PatchPlane>;
    FFacets: TList<TQ3Facet>;
    FGrid: TQ3PatchGrid;
    FGridPlanes: TGridPlanes;
    function GridPlaneAt(AColumn, ARow, ATriangle: Integer): Integer; inline;
    class function PlaneFromPoints(out APlane: TQ3PatchPlane; const A, B, C: TQ3Vec3): Boolean; static;
    class function PlaneEqual(const AExisting: TQ3PatchPlane; const APlane: TQ3PatchPlaneValue;
      out AFlipped: Boolean): Boolean; static;
    class procedure SnapVector(var ANormal: TQ3Vec3); static;
    function FindPlane2(const APlane: TQ3PatchPlaneValue; out AFlipped: Boolean): Integer;
    function FindPlane(const AP1, AP2, AP3: TQ3Vec3): Integer;
    function PointOnPlaneSide(const APoint: TQ3Vec3; APlaneNum: Integer): Integer;
    function GridPlane(AColumn, ARow, ATriangle: Integer): Integer;
    function EdgePlaneNum(AColumn, ARow, AWhich: Integer): Integer;
    procedure SetBorderInward(var AFacet: TQ3Facet; AColumn, ARow, AWhich: Integer);
    function ValidateFacet(const AFacet: TQ3Facet): Boolean;
    procedure AddFacetBevels(var AFacet: TQ3Facet);
    procedure PatchCollideFromGrid;
  public
    constructor Create;
    destructor Destroy; override;
    function Generate(const AWidth, AHeight: Integer; const APoints: TArray<TQ3Vec3>): IQ3PatchCollide;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Math, DelphiDoom.Collision.Q3.VectorMath,
  DelphiDoom.Collision.Q3.Winding, DelphiDoom.Collision.Q3.PatchCollide;

resourcestring
  SMaxPatchPlanes = 'MAX_PATCH_PLANES';
  SMaxFacets = 'MAX_FACETS';
  SBadParameters = 'CM_GeneratePatchFacets: bad parameters: (%d, %d, %p)';
  SEvenSizes = 'CM_GeneratePatchFacets: even sizes are invalid for quadratic meshes';
  SSourceTooBig = 'CM_GeneratePatchFacets: source is > MAX_GRID_SIZE';
  SBadWhich = 'CM_EdgePlaneNum: bad k';
  STooManyBevels = 'CM_AddFacetBevels: too many bevels';

const
  SIDE_FRONT = 0;
  SIDE_BACK = 1;
  SIDE_ON = 2;
  // #define constants of cm_patch.c: doubles in the C
  NORMAL_EPSILON: Double = 0.0001;
  DIST_EPSILON: Double = 0.02;
  PLANE_TRI_EPSILON: Double = 0.1;
  /// <summary>the 0.1f of ChopWindingInPlace and of the bevel test</summary>
  CHOP_EPSILON: Single = 0.1;
  BEVEL_POINT_EPSILON: Double = 0.1;
  EN_TOP = 0;
  EN_RIGHT = 1;
  EN_BOTTOM = 2;
  EN_LEFT = 3;
  MAX_BORDERS = 26;


function Normal3(const APlane: TQ3PatchPlaneValue): TQ3Vec3;
begin
  Result[0] := APlane[0];
  Result[1] := APlane[1];
  Result[2] := APlane[2];
end;

function ToValue(const APlane: TQ3PatchPlane): TQ3PatchPlaneValue;
begin
  Result[0] := APlane.Plane[0];
  Result[1] := APlane.Plane[1];
  Result[2] := APlane.Plane[2];
  Result[3] := APlane.Plane[3];
end;

{ TQ3PatchCollideBuilder }

constructor TQ3PatchCollideBuilder.Create;
begin
  inherited Create;
  FPlanes := TList<TQ3PatchPlane>.Create;
  FFacets := TList<TQ3Facet>.Create;
  FGrid := TQ3PatchGrid.Create;
  SetLength(FGridPlanes, Q3_MAX_GRID_SIZE * Q3_MAX_GRID_SIZE * 2);
end;

destructor TQ3PatchCollideBuilder.Destroy;
begin
  FGrid.Free;
  FFacets.Free;
  FPlanes.Free;
  inherited Destroy;
end;

function TQ3PatchCollideBuilder.GridPlaneAt(AColumn, ARow, ATriangle: Integer): Integer;
begin
  Result := FGridPlanes[(AColumn * Q3_MAX_GRID_SIZE + ARow) * 2 + ATriangle];
end;

class function TQ3PatchCollideBuilder.PlaneFromPoints(out APlane: TQ3PatchPlane; const A, B, C: TQ3Vec3): Boolean;
var
  LD1: TQ3Vec3;
  LD2: TQ3Vec3;
  LNormal: TQ3Vec3;
begin
  APlane := Default(TQ3PatchPlane);
  LD1 := TQ3VectorMath.Subtract(B, A);
  LD2 := TQ3VectorMath.Subtract(C, A);
  LNormal := TQ3VectorMath.Cross(LD2, LD1);
  if TQ3VectorMath.Normalize(LNormal) = 0 then
    Exit(False);
  APlane.Plane[0] := LNormal[0];
  APlane.Plane[1] := LNormal[1];
  APlane.Plane[2] := LNormal[2];
  APlane.Plane[3] := TQ3Math.Dot(A, LNormal);
  Result := True;
end;

class function TQ3PatchCollideBuilder.PlaneEqual(const AExisting: TQ3PatchPlane; const APlane: TQ3PatchPlaneValue;
  out AFlipped: Boolean): Boolean;
var
  LInverse: array[0..3] of Single;
begin
  if (Abs(Double(AExisting.Plane[0] - APlane[0])) < NORMAL_EPSILON) and
    (Abs(Double(AExisting.Plane[1] - APlane[1])) < NORMAL_EPSILON) and
    (Abs(Double(AExisting.Plane[2] - APlane[2])) < NORMAL_EPSILON) and
    (Abs(Double(AExisting.Plane[3] - APlane[3])) < DIST_EPSILON) then
  begin
    AFlipped := False;
    Exit(True);
  end;

  LInverse[0] := -APlane[0];
  LInverse[1] := -APlane[1];
  LInverse[2] := -APlane[2];
  LInverse[3] := -APlane[3];

  if (Abs(Double(AExisting.Plane[0] - LInverse[0])) < NORMAL_EPSILON) and
    (Abs(Double(AExisting.Plane[1] - LInverse[1])) < NORMAL_EPSILON) and
    (Abs(Double(AExisting.Plane[2] - LInverse[2])) < NORMAL_EPSILON) and
    (Abs(Double(AExisting.Plane[3] - LInverse[3])) < DIST_EPSILON) then
  begin
    AFlipped := True;
    Exit(True);
  end;
  AFlipped := False;
  Result := False;
end;

class procedure TQ3PatchCollideBuilder.SnapVector(var ANormal: TQ3Vec3);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
  begin
    if Abs(Double(ANormal[LIndex] - 1)) < NORMAL_EPSILON then
    begin
      ANormal[0] := 0;
      ANormal[1] := 0;
      ANormal[2] := 0;
      ANormal[LIndex] := 1;
      Break;
    end;
    if Abs(Double(ANormal[LIndex] - -1)) < NORMAL_EPSILON then
    begin
      ANormal[0] := 0;
      ANormal[1] := 0;
      ANormal[2] := 0;
      ANormal[LIndex] := -1;
      Break;
    end;
  end;
end;

function TQ3PatchCollideBuilder.FindPlane2(const APlane: TQ3PatchPlaneValue; out AFlipped: Boolean): Integer;
var
  LIndex: Integer;
  LNew: TQ3PatchPlane;
begin
  // see if the points are close enough to an existing plane
  for LIndex := 0 to FPlanes.Count - 1 do
    if PlaneEqual(FPlanes[LIndex], APlane, AFlipped) then
      Exit(LIndex);

  // add a new plane
  if FPlanes.Count = Q3_MAX_PATCH_PLANES then
    raise EQ3CollisionException.Create(SMaxPatchPlanes);

  LNew.Plane[0] := APlane[0];
  LNew.Plane[1] := APlane[1];
  LNew.Plane[2] := APlane[2];
  LNew.Plane[3] := APlane[3];
  LNew.SignBits := TQ3Math.SignBitsOf(Normal3(APlane));
  FPlanes.Add(LNew);
  AFlipped := False;
  Result := FPlanes.Count - 1;
end;

function TQ3PatchCollideBuilder.FindPlane(const AP1, AP2, AP3: TQ3Vec3): Integer;
var
  LPlane: TQ3PatchPlane;
  LIndex: Integer;
  LD: Single;
  LExisting: TQ3PatchPlane;
  LNormal: TQ3Vec3;
  LExistingNormal: TQ3Vec3;
begin
  if not PlaneFromPoints(LPlane, AP1, AP2, AP3) then
    Exit(-1);

  LNormal := Normal3(LPlane.Plane);
  // see if the points are close enough to an existing plane
  for LIndex := 0 to FPlanes.Count - 1 do
  begin
    LExisting := FPlanes[LIndex];
    LExistingNormal := Normal3(LExisting.Plane);
    if TQ3Math.Dot(LNormal, LExistingNormal) < 0 then
      Continue; // allow backwards planes?

    LD := TQ3Math.Dot(AP1, LExistingNormal);
    LD := LD - LExisting.Plane[3];
    if (LD < -PLANE_TRI_EPSILON) or (LD > PLANE_TRI_EPSILON) then
      Continue;

    LD := TQ3Math.Dot(AP2, LExistingNormal);
    LD := LD - LExisting.Plane[3];
    if (LD < -PLANE_TRI_EPSILON) or (LD > PLANE_TRI_EPSILON) then
      Continue;

    LD := TQ3Math.Dot(AP3, LExistingNormal);
    LD := LD - LExisting.Plane[3];
    if (LD < -PLANE_TRI_EPSILON) or (LD > PLANE_TRI_EPSILON) then
      Continue;

    // found it
    Exit(LIndex);
  end;

  // add a new plane
  if FPlanes.Count = Q3_MAX_PATCH_PLANES then
    raise EQ3CollisionException.Create(SMaxPatchPlanes);

  LPlane.SignBits := TQ3Math.SignBitsOf(LNormal);
  FPlanes.Add(LPlane);
  Result := FPlanes.Count - 1;
end;

function TQ3PatchCollideBuilder.PointOnPlaneSide(const APoint: TQ3Vec3; APlaneNum: Integer): Integer;
var
  LPlane: TQ3PatchPlane;
  LD: Single;
begin
  if APlaneNum = -1 then
    Exit(SIDE_ON);
  LPlane := FPlanes[APlaneNum];

  LD := TQ3Math.Dot(APoint, Normal3(LPlane.Plane));
  LD := LD - LPlane.Plane[3];

  if LD > PLANE_TRI_EPSILON then
    Exit(SIDE_FRONT);
  if LD < -PLANE_TRI_EPSILON then
    Exit(SIDE_BACK);
  Result := SIDE_ON;
end;

function TQ3PatchCollideBuilder.GridPlane(AColumn, ARow, ATriangle: Integer): Integer;
begin
  Result := GridPlaneAt(AColumn, ARow, ATriangle);
  if Result <> -1 then
    Exit;
  Result := GridPlaneAt(AColumn, ARow, 1 - ATriangle);
  if Result <> -1 then
    Exit;
  // should never happen: the original prints a warning
  Result := -1;
end;

function TQ3PatchCollideBuilder.EdgePlaneNum(AColumn, ARow, AWhich: Integer): Integer;
var
  LP1: TQ3Vec3;
  LP2: TQ3Vec3;
  LUp: TQ3Vec3;
  LPlane: Integer;
begin
  case AWhich of
    0: // top border
      begin
        LP1 := FGrid[AColumn, ARow];
        LP2 := FGrid[AColumn + 1, ARow];
        LPlane := GridPlane(AColumn, ARow, 0);
        LUp := TQ3VectorMath.MultiplyAdd(LP1, 4, Normal3(FPlanes[LPlane].Plane));
        Result := FindPlane(LP1, LP2, LUp);
      end;
    2: // bottom border
      begin
        LP1 := FGrid[AColumn, ARow + 1];
        LP2 := FGrid[AColumn + 1, ARow + 1];
        LPlane := GridPlane(AColumn, ARow, 1);
        LUp := TQ3VectorMath.MultiplyAdd(LP1, 4, Normal3(FPlanes[LPlane].Plane));
        Result := FindPlane(LP2, LP1, LUp);
      end;
    3: // left border
      begin
        LP1 := FGrid[AColumn, ARow];
        LP2 := FGrid[AColumn, ARow + 1];
        LPlane := GridPlane(AColumn, ARow, 1);
        LUp := TQ3VectorMath.MultiplyAdd(LP1, 4, Normal3(FPlanes[LPlane].Plane));
        Result := FindPlane(LP2, LP1, LUp);
      end;
    1: // right border
      begin
        LP1 := FGrid[AColumn + 1, ARow];
        LP2 := FGrid[AColumn + 1, ARow + 1];
        LPlane := GridPlane(AColumn, ARow, 0);
        LUp := TQ3VectorMath.MultiplyAdd(LP1, 4, Normal3(FPlanes[LPlane].Plane));
        Result := FindPlane(LP1, LP2, LUp);
      end;
    4: // diagonal out of triangle 0
      begin
        LP1 := FGrid[AColumn + 1, ARow + 1];
        LP2 := FGrid[AColumn, ARow];
        LPlane := GridPlane(AColumn, ARow, 0);
        LUp := TQ3VectorMath.MultiplyAdd(LP1, 4, Normal3(FPlanes[LPlane].Plane));
        Result := FindPlane(LP1, LP2, LUp);
      end;
    5: // diagonal out of triangle 1
      begin
        LP1 := FGrid[AColumn, ARow];
        LP2 := FGrid[AColumn + 1, ARow + 1];
        LPlane := GridPlane(AColumn, ARow, 1);
        LUp := TQ3VectorMath.MultiplyAdd(LP1, 4, Normal3(FPlanes[LPlane].Plane));
        Result := FindPlane(LP1, LP2, LUp);
      end;
  else
    raise EQ3CollisionException.Create(SBadWhich);
  end;
end;

procedure TQ3PatchCollideBuilder.SetBorderInward(var AFacet: TQ3Facet; AColumn, ARow, AWhich: Integer);
var
  LK: Integer;
  LL: Integer;
  LPoints: array[0..3] of TQ3Vec3;
  LNumPoints: Integer;
  LFront: Integer;
  LBack: Integer;
  LSide: Integer;
begin
  case AWhich of
    -1:
      begin
        LPoints[0] := FGrid[AColumn, ARow];
        LPoints[1] := FGrid[AColumn + 1, ARow];
        LPoints[2] := FGrid[AColumn + 1, ARow + 1];
        LPoints[3] := FGrid[AColumn, ARow + 1];
        LNumPoints := 4;
      end;
    0:
      begin
        LPoints[0] := FGrid[AColumn, ARow];
        LPoints[1] := FGrid[AColumn + 1, ARow];
        LPoints[2] := FGrid[AColumn + 1, ARow + 1];
        LNumPoints := 3;
      end;
    1:
      begin
        LPoints[0] := FGrid[AColumn + 1, ARow + 1];
        LPoints[1] := FGrid[AColumn, ARow + 1];
        LPoints[2] := FGrid[AColumn, ARow];
        LNumPoints := 3;
      end;
  else
    raise EQ3CollisionException.Create('CM_SetBorderInward: bad parameter');
  end;

  for LK := 0 to AFacet.NumBorders - 1 do
  begin
    LFront := 0;
    LBack := 0;

    for LL := 0 to LNumPoints - 1 do
    begin
      LSide := PointOnPlaneSide(LPoints[LL], AFacet.BorderPlanes[LK]);
      if LSide = SIDE_FRONT then
        Inc(LFront);
      if LSide = SIDE_BACK then
        Inc(LBack);
    end;

    if (LFront <> 0) and (LBack = 0) then
      AFacet.BorderInward[LK] := 1
    else if (LBack <> 0) and (LFront = 0) then
      AFacet.BorderInward[LK] := 0
    else if (LFront = 0) and (LBack = 0) then
      // flat side border
      AFacet.BorderPlanes[LK] := -1
    else
      // bisecting side border
      AFacet.BorderInward[LK] := 0;
  end;
end;

function TQ3PatchCollideBuilder.ValidateFacet(const AFacet: TQ3Facet): Boolean;
var
  LPlane: TQ3PatchPlaneValue;
  LJ: Integer;
  LW: TQ3Winding;
  LMins: TQ3Vec3;
  LMaxs: TQ3Vec3;
begin
  if AFacet.SurfacePlane = -1 then
    Exit(False);

  LPlane := ToValue(FPlanes[AFacet.SurfacePlane]);
  LW := TQ3Winding.CreateForPlane(Normal3(LPlane), LPlane[3]);
  try
    LJ := 0;
    while (LJ < AFacet.NumBorders) and (LW.NumPoints > 0) do
    begin
      if AFacet.BorderPlanes[LJ] = -1 then
        Exit(False);
      LPlane := ToValue(FPlanes[AFacet.BorderPlanes[LJ]]);
      if AFacet.BorderInward[LJ] = 0 then
      begin
        // VectorSubtract( vec3_origin, plane, plane )
        LPlane[0] := 0 - LPlane[0];
        LPlane[1] := 0 - LPlane[1];
        LPlane[2] := 0 - LPlane[2];
        LPlane[3] := -LPlane[3];
      end;
      if not LW.ChopInPlace(Normal3(LPlane), LPlane[3], CHOP_EPSILON) then
        // winding was completely chopped away
        Exit(False);
      Inc(LJ);
    end;

    // see if the facet is unreasonably large
    LW.Bounds(LMins, LMaxs);
  finally
    LW.Free;
  end;

  for LJ := 0 to 2 do
  begin
    if LMaxs[LJ] - LMins[LJ] > Q3_MAX_MAP_BOUNDS then
      Exit(False); // we must be missing a plane
    if LMins[LJ] >= Q3_MAX_MAP_BOUNDS then
      Exit(False);
    if LMaxs[LJ] <= -Q3_MAX_MAP_BOUNDS then
      Exit(False);
  end;
  Result := True; // winding is fine
end;

procedure TQ3PatchCollideBuilder.AddFacetBevels(var AFacet: TQ3Facet);
var
  LI: Integer;
  LJ: Integer;
  LK: Integer;
  LL: Integer;
  LAxis: Integer;
  LDir: Integer;
  LFlipped: Boolean;
  LPlane: TQ3PatchPlaneValue;
  LNewPlane: TQ3PatchPlaneValue;
  LD: Single;
  LW: TQ3Winding;
  LW2: TQ3Winding;
  LMins: TQ3Vec3;
  LMaxs: TQ3Vec3;
  LVec: TQ3Vec3;
  LVec2: TQ3Vec3;
  LNormal: TQ3Vec3;
  LNext: Integer;
  LPlaneVec: TQ3Vec3;
begin
  LPlane := ToValue(FPlanes[AFacet.SurfacePlane]);

  LW := TQ3Winding.CreateForPlane(Normal3(LPlane), LPlane[3]);
  try
    LJ := 0;
    while (LJ < AFacet.NumBorders) and (LW.NumPoints > 0) do
    begin
      if AFacet.BorderPlanes[LJ] = AFacet.SurfacePlane then
      begin
        Inc(LJ);
        Continue;
      end;
      LPlane := ToValue(FPlanes[AFacet.BorderPlanes[LJ]]);

      if AFacet.BorderInward[LJ] = 0 then
      begin
        LPlane[0] := 0 - LPlane[0];
        LPlane[1] := 0 - LPlane[1];
        LPlane[2] := 0 - LPlane[2];
        LPlane[3] := -LPlane[3];
      end;

      if not LW.ChopInPlace(Normal3(LPlane), LPlane[3], CHOP_EPSILON) then
        Exit;
      Inc(LJ);
    end;
    if LW.NumPoints = 0 then
      Exit;

    LW.Bounds(LMins, LMaxs);

    // add the axial planes
    for LAxis := 0 to 2 do
    begin
      LDir := -1;
      while LDir <= 1 do
      begin
        LPlane[0] := 0;
        LPlane[1] := 0;
        LPlane[2] := 0;
        LPlane[LAxis] := LDir;
        if LDir = 1 then
          LPlane[3] := LMaxs[LAxis]
        else
          LPlane[3] := -LMins[LAxis];
        // if it's the surface plane
        if PlaneEqual(FPlanes[AFacet.SurfacePlane], LPlane, LFlipped) then
        begin
          Inc(LDir, 2);
          Continue;
        end;
        // see if the plane is allready present
        LI := 0;
        while LI < AFacet.NumBorders do
        begin
          if PlaneEqual(FPlanes[AFacet.BorderPlanes[LI]], LPlane, LFlipped) then
            Break;
          Inc(LI);
        end;

        if LI = AFacet.NumBorders then
        begin
          if AFacet.NumBorders >= MAX_BORDERS then
            raise EQ3CollisionException.Create(STooManyBevels);
          AFacet.BorderPlanes[AFacet.NumBorders] := FindPlane2(LPlane, LFlipped);
          AFacet.BorderNoAdjust[AFacet.NumBorders] := 0;
          AFacet.BorderInward[AFacet.NumBorders] := Ord(LFlipped);
          Inc(AFacet.NumBorders);
        end;
        Inc(LDir, 2);
      end;
    end;

    // add the edge bevels: test the non-axial plane edges
    for LJ := 0 to LW.NumPoints - 1 do
    begin
      LNext := (LJ + 1) mod LW.NumPoints;
      LVec := TQ3VectorMath.Subtract(LW[LJ], LW[LNext]);
      // if it's a degenerate edge
      if TQ3VectorMath.Normalize(LVec) < 0.5 then
        Continue;
      SnapVector(LVec);
      LK := 0;
      while LK < 3 do
      begin
        if (LVec[LK] = -1) or (LVec[LK] = 1) then
          Break; // axial
        Inc(LK);
      end;
      if LK < 3 then
        Continue; // only test non-axial edges

      // try the six possible slanted axials from this edge
      for LAxis := 0 to 2 do
      begin
        LDir := -1;
        while LDir <= 1 do
        begin
          // construct a plane
          LVec2[0] := 0;
          LVec2[1] := 0;
          LVec2[2] := 0;
          LVec2[LAxis] := LDir;
          LPlaneVec := TQ3VectorMath.Cross(LVec, LVec2);
          if TQ3VectorMath.Normalize(LPlaneVec) < 0.5 then
          begin
            Inc(LDir, 2);
            Continue;
          end;
          LPlane[0] := LPlaneVec[0];
          LPlane[1] := LPlaneVec[1];
          LPlane[2] := LPlaneVec[2];
          LPlane[3] := TQ3Math.Dot(LW[LJ], LPlaneVec);

          // if all the points of the facet winding are behind this plane, it is a proper edge bevel
          LL := 0;
          while LL < LW.NumPoints do
          begin
            LD := TQ3Math.Dot(LW[LL], LPlaneVec);
            LD := LD - LPlane[3];
            if LD > BEVEL_POINT_EPSILON then
              Break; // point in front
            Inc(LL);
          end;
          if LL < LW.NumPoints then
          begin
            Inc(LDir, 2);
            Continue;
          end;

          // if it's the surface plane
          if PlaneEqual(FPlanes[AFacet.SurfacePlane], LPlane, LFlipped) then
          begin
            Inc(LDir, 2);
            Continue;
          end;
          // see if the plane is allready present
          LI := 0;
          while LI < AFacet.NumBorders do
          begin
            if PlaneEqual(FPlanes[AFacet.BorderPlanes[LI]], LPlane, LFlipped) then
              Break;
            Inc(LI);
          end;

          if LI = AFacet.NumBorders then
          begin
            if AFacet.NumBorders >= MAX_BORDERS then
              raise EQ3CollisionException.Create(STooManyBevels);
            AFacet.BorderPlanes[AFacet.NumBorders] := FindPlane2(LPlane, LFlipped);

            AFacet.BorderNoAdjust[AFacet.NumBorders] := 0;
            AFacet.BorderInward[AFacet.NumBorders] := Ord(LFlipped);

            LW2 := LW.Copy;
            try
              LNewPlane := ToValue(FPlanes[AFacet.BorderPlanes[AFacet.NumBorders]]);
              if AFacet.BorderInward[AFacet.NumBorders] = 0 then
              begin
                // VectorNegate
                LNewPlane[0] := -LNewPlane[0];
                LNewPlane[1] := -LNewPlane[1];
                LNewPlane[2] := -LNewPlane[2];
                LNewPlane[3] := -LNewPlane[3];
              end;
              if not LW2.ChopInPlace(Normal3(LNewPlane), LNewPlane[3], CHOP_EPSILON) then
              begin
                // invalid bevel: the plane stays in the list but not in the facet
                Inc(LDir, 2);
                Continue;
              end;
            finally
              LW2.Free;
            end;
            Inc(AFacet.NumBorders);
          end;
          Inc(LDir, 2);
        end;
      end;
    end;
  finally
    LW.Free;
  end;

  // add opposite plane
  if AFacet.NumBorders >= MAX_BORDERS then
    raise EQ3CollisionException.Create(STooManyBevels);
  AFacet.BorderPlanes[AFacet.NumBorders] := AFacet.SurfacePlane;
  AFacet.BorderNoAdjust[AFacet.NumBorders] := 0;
  AFacet.BorderInward[AFacet.NumBorders] := 1;
  Inc(AFacet.NumBorders);
end;

procedure TQ3PatchCollideBuilder.PatchCollideFromGrid;
var
  LI: Integer;
  LJ: Integer;
  LFacet: TQ3Facet;
  LBorders: array[0..3] of Integer;
  LNoAdjust: array[0..3] of Integer;
  LPlane0: Integer;
  LPlane1: Integer;

  procedure SetGridPlane(AColumn, ARow, ATriangle, AValue: Integer);
  begin
    FGridPlanes[(AColumn * Q3_MAX_GRID_SIZE + ARow) * 2 + ATriangle] := AValue;
  end;

  procedure AddValid(var AFacetToAdd: TQ3Facet; AWhich: Integer);
  begin
    SetBorderInward(AFacetToAdd, LI, LJ, AWhich);
    if ValidateFacet(AFacetToAdd) then
    begin
      AddFacetBevels(AFacetToAdd);
      FFacets.Add(AFacetToAdd);
    end;
  end;

begin
  FPlanes.Clear;
  FFacets.Clear;

  // find the planes for each triangle of the grid
  for LI := 0 to FGrid.Width - 2 do
    for LJ := 0 to FGrid.Height - 2 do
    begin
      SetGridPlane(LI, LJ, 0, FindPlane(FGrid[LI, LJ], FGrid[LI + 1, LJ], FGrid[LI + 1, LJ + 1]));
      SetGridPlane(LI, LJ, 1, FindPlane(FGrid[LI + 1, LJ + 1], FGrid[LI, LJ + 1], FGrid[LI, LJ]));
    end;

  // create the borders for each facet
  for LI := 0 to FGrid.Width - 2 do
    for LJ := 0 to FGrid.Height - 2 do
    begin
      LPlane0 := GridPlaneAt(LI, LJ, 0);
      LPlane1 := GridPlaneAt(LI, LJ, 1);

      LBorders[EN_TOP] := -1;
      if LJ > 0 then
        LBorders[EN_TOP] := GridPlaneAt(LI, LJ - 1, 1)
      else if FGrid.WrapHeight then
        LBorders[EN_TOP] := GridPlaneAt(LI, FGrid.Height - 2, 1);
      LNoAdjust[EN_TOP] := Ord(LBorders[EN_TOP] = LPlane0);
      if (LBorders[EN_TOP] = -1) or (LNoAdjust[EN_TOP] <> 0) then
        LBorders[EN_TOP] := EdgePlaneNum(LI, LJ, 0);

      LBorders[EN_BOTTOM] := -1;
      if LJ < FGrid.Height - 2 then
        LBorders[EN_BOTTOM] := GridPlaneAt(LI, LJ + 1, 0)
      else if FGrid.WrapHeight then
        LBorders[EN_BOTTOM] := GridPlaneAt(LI, 0, 0);
      LNoAdjust[EN_BOTTOM] := Ord(LBorders[EN_BOTTOM] = LPlane1);
      if (LBorders[EN_BOTTOM] = -1) or (LNoAdjust[EN_BOTTOM] <> 0) then
        LBorders[EN_BOTTOM] := EdgePlaneNum(LI, LJ, 2);

      LBorders[EN_LEFT] := -1;
      if LI > 0 then
        LBorders[EN_LEFT] := GridPlaneAt(LI - 1, LJ, 0)
      else if FGrid.WrapWidth then
        LBorders[EN_LEFT] := GridPlaneAt(FGrid.Width - 2, LJ, 0);
      LNoAdjust[EN_LEFT] := Ord(LBorders[EN_LEFT] = LPlane1);
      if (LBorders[EN_LEFT] = -1) or (LNoAdjust[EN_LEFT] <> 0) then
        LBorders[EN_LEFT] := EdgePlaneNum(LI, LJ, 3);

      LBorders[EN_RIGHT] := -1;
      if LI < FGrid.Width - 2 then
        LBorders[EN_RIGHT] := GridPlaneAt(LI + 1, LJ, 1)
      else if FGrid.WrapWidth then
        LBorders[EN_RIGHT] := GridPlaneAt(0, LJ, 1);
      LNoAdjust[EN_RIGHT] := Ord(LBorders[EN_RIGHT] = LPlane0);
      if (LBorders[EN_RIGHT] = -1) or (LNoAdjust[EN_RIGHT] <> 0) then
        LBorders[EN_RIGHT] := EdgePlaneNum(LI, LJ, 1);

      if FFacets.Count = Q3_MAX_FACETS then
        raise EQ3CollisionException.Create(SMaxFacets);
      LFacet := Default(TQ3Facet);

      if LPlane0 = LPlane1 then
      begin
        if LPlane0 = -1 then
          Continue; // degenrate
        LFacet.SurfacePlane := LPlane0;
        LFacet.NumBorders := 4;
        LFacet.BorderPlanes[0] := LBorders[EN_TOP];
        LFacet.BorderNoAdjust[0] := LNoAdjust[EN_TOP];
        LFacet.BorderPlanes[1] := LBorders[EN_RIGHT];
        LFacet.BorderNoAdjust[1] := LNoAdjust[EN_RIGHT];
        LFacet.BorderPlanes[2] := LBorders[EN_BOTTOM];
        LFacet.BorderNoAdjust[2] := LNoAdjust[EN_BOTTOM];
        LFacet.BorderPlanes[3] := LBorders[EN_LEFT];
        LFacet.BorderNoAdjust[3] := LNoAdjust[EN_LEFT];
        AddValid(LFacet, -1);
      end
      else
      begin
        // two seperate triangles
        LFacet.SurfacePlane := LPlane0;
        LFacet.NumBorders := 3;
        LFacet.BorderPlanes[0] := LBorders[EN_TOP];
        LFacet.BorderNoAdjust[0] := LNoAdjust[EN_TOP];
        LFacet.BorderPlanes[1] := LBorders[EN_RIGHT];
        LFacet.BorderNoAdjust[1] := LNoAdjust[EN_RIGHT];
        LFacet.BorderPlanes[2] := LPlane1;
        if LFacet.BorderPlanes[2] = -1 then
        begin
          LFacet.BorderPlanes[2] := LBorders[EN_BOTTOM];
          if LFacet.BorderPlanes[2] = -1 then
            LFacet.BorderPlanes[2] := EdgePlaneNum(LI, LJ, 4);
        end;
        AddValid(LFacet, 0);

        if FFacets.Count = Q3_MAX_FACETS then
          raise EQ3CollisionException.Create(SMaxFacets);
        LFacet := Default(TQ3Facet);

        LFacet.SurfacePlane := LPlane1;
        LFacet.NumBorders := 3;
        LFacet.BorderPlanes[0] := LBorders[EN_BOTTOM];
        LFacet.BorderNoAdjust[0] := LNoAdjust[EN_BOTTOM];
        LFacet.BorderPlanes[1] := LBorders[EN_LEFT];
        LFacet.BorderNoAdjust[1] := LNoAdjust[EN_LEFT];
        LFacet.BorderPlanes[2] := LPlane0;
        if LFacet.BorderPlanes[2] = -1 then
        begin
          LFacet.BorderPlanes[2] := LBorders[EN_TOP];
          if LFacet.BorderPlanes[2] = -1 then
            LFacet.BorderPlanes[2] := EdgePlaneNum(LI, LJ, 5);
        end;
        AddValid(LFacet, 1);
      end;
    end;
end;

function TQ3PatchCollideBuilder.Generate(const AWidth, AHeight: Integer;
  const APoints: TArray<TQ3Vec3>): IQ3PatchCollide;
var
  LI: Integer;
  LJ: Integer;
  LMins: TQ3Vec3;
  LMaxs: TQ3Vec3;
  LPoint: TQ3Vec3;
  LAxis: Integer;
begin
  if (AWidth <= 2) or (AHeight <= 2) or (Length(APoints) = 0) then
    raise EQ3CollisionException.CreateFmt(SBadParameters, [AWidth, AHeight, Pointer(APoints)]);

  if ((AWidth and 1) = 0) or ((AHeight and 1) = 0) then
    raise EQ3CollisionException.Create(SEvenSizes);

  if (AWidth > Q3_MAX_GRID_SIZE) or (AHeight > Q3_MAX_GRID_SIZE) then
    raise EQ3CollisionException.Create(SSourceTooBig);

  if Length(APoints) < AWidth * AHeight then
    raise EQ3CollisionException.CreateFmt(SBadParameters, [AWidth, AHeight, Pointer(APoints)]);

  // build a grid
  FGrid.Load(AWidth, AHeight, APoints);

  // subdivide the grid
  FGrid.SetWrapWidth;
  FGrid.SubdivideColumns;
  FGrid.RemoveDegenerateColumns;

  FGrid.Transpose;

  FGrid.SetWrapWidth;
  FGrid.SubdivideColumns;
  FGrid.RemoveDegenerateColumns;

  // we now have a grid of points exactly on the curve: the aproximate surface defined by these points will be
  // collided against
  for LAxis := 0 to 2 do
  begin
    LMins[LAxis] := 99999;
    LMaxs[LAxis] := -99999;
  end;
  for LI := 0 to FGrid.Width - 1 do
    for LJ := 0 to FGrid.Height - 1 do
    begin
      LPoint := FGrid[LI, LJ];
      for LAxis := 0 to 2 do
      begin
        if LPoint[LAxis] < LMins[LAxis] then
          LMins[LAxis] := LPoint[LAxis];
        if LPoint[LAxis] > LMaxs[LAxis] then
          LMaxs[LAxis] := LPoint[LAxis];
      end;
    end;

  // generate a bsp tree for the surface
  PatchCollideFromGrid;

  // expand by one unit for epsilon purposes
  for LAxis := 0 to 2 do
  begin
    LMins[LAxis] := LMins[LAxis] - 1;
    LMaxs[LAxis] := LMaxs[LAxis] + 1;
  end;

  Result := TQ3PatchCollide.Create(LMins, LMaxs, FPlanes.ToArray, FFacets.ToArray);
end;

end.
