{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  windings of the patch collision                                             }
{                                                                              }
{  Port of the part of cm_polylib.c that cm_patch.c uses (BaseWindingForPlane, }
{  ChopWindingInPlace, CopyWinding, WindingBounds) of the Quake III Arena GPL  }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.Winding;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Collision.Q3.Types;

const
  /// <summary>MAX_MAP_BOUNDS of cm_polylib.h</summary>
  Q3_MAX_MAP_BOUNDS = 65535;
  /// <summary>MAX_POINTS_ON_WINDING of cm_polylib.h</summary>
  Q3_MAX_POINTS_ON_WINDING = 64;

type
  /// <summary>winding_t: a convex polygon as a list of points (the plane is not stored)</summary>
  TQ3Winding = class
  private
    FPoints: TArray<TQ3Vec3>;
    FCount: Integer;
    function GetPoint(AIndex: Integer): TQ3Vec3;
  public
    /// <summary>BaseWindingForPlane: a huge quadrilateral on the plane normal * p = dist</summary>
    constructor CreateForPlane(const ANormal: TQ3Vec3; ADist: Single);
    /// <summary>CopyWinding</summary>
    function Copy: TQ3Winding;
    /// <summary>
    ///   ChopWindingInPlace: keeps the part in front of the plane (normal * p - dist &gt; epsilon). Returns False when
    ///   nothing is left (the original frees the winding and sets the pointer to NULL)
    /// </summary>
    function ChopInPlace(const ANormal: TQ3Vec3; ADist, AEpsilon: Single): Boolean;
    /// <summary>WindingBounds</summary>
    procedure Bounds(out AMins, AMaxs: TQ3Vec3);
    property NumPoints: Integer read FCount;
    property Points[AIndex: Integer]: TQ3Vec3 read GetPoint; default;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Math, DelphiDoom.Collision.Q3.VectorMath;

resourcestring
  SNoAxis = 'BaseWindingForPlane: no axis found';
  SPointsExceeded = 'ClipWinding: points exceeded estimate';
  STooManyPoints = 'ClipWinding: MAX_POINTS_ON_WINDING';

const
  SIDE_FRONT = 0;
  SIDE_BACK = 1;
  SIDE_ON = 2;

{ TQ3Winding }

constructor TQ3Winding.CreateForPlane(const ANormal: TQ3Vec3; ADist: Single);
var
  LIndex: Integer;
  LAxis: Integer;
  LMax: Single;
  LValue: Single;
  LOrigin: TQ3Vec3;
  LRight: TQ3Vec3;
  LUp: TQ3Vec3;
  LCorner: TQ3Vec3;
begin
  inherited Create;
  // find the major axis
  LMax := -Q3_MAX_MAP_BOUNDS;
  LAxis := -1;
  for LIndex := 0 to 2 do
  begin
    LValue := Abs(ANormal[LIndex]);
    if LValue > LMax then
    begin
      LAxis := LIndex;
      LMax := LValue;
    end;
  end;
  if LAxis = -1 then
    raise EQ3CollisionException.Create(SNoAxis);

  LUp[0] := 0;
  LUp[1] := 0;
  LUp[2] := 0;
  case LAxis of
    0, 1:
      LUp[2] := 1;
    2:
      LUp[0] := 1;
  end;

  LValue := TQ3Math.Dot(LUp, ANormal);
  LUp := TQ3VectorMath.MultiplyAdd(LUp, -LValue, ANormal);
  TQ3VectorMath.Normalize(LUp);

  LOrigin := TQ3VectorMath.Scale(ANormal, ADist);
  LRight := TQ3VectorMath.Cross(LUp, ANormal);
  LUp := TQ3VectorMath.Scale(LUp, Q3_MAX_MAP_BOUNDS);
  LRight := TQ3VectorMath.Scale(LRight, Q3_MAX_MAP_BOUNDS);

  // project a really big axis aligned box onto the plane
  SetLength(FPoints, 4);
  LCorner := TQ3VectorMath.Subtract(LOrigin, LRight);
  FPoints[0] := TQ3VectorMath.Add(LCorner, LUp);
  LCorner := TQ3VectorMath.Add(LOrigin, LRight);
  FPoints[1] := TQ3VectorMath.Add(LCorner, LUp);
  LCorner := TQ3VectorMath.Add(LOrigin, LRight);
  FPoints[2] := TQ3VectorMath.Subtract(LCorner, LUp);
  LCorner := TQ3VectorMath.Subtract(LOrigin, LRight);
  FPoints[3] := TQ3VectorMath.Subtract(LCorner, LUp);
  FCount := 4;
end;

function TQ3Winding.GetPoint(AIndex: Integer): TQ3Vec3;
begin
  Result := FPoints[AIndex];
end;

function TQ3Winding.Copy: TQ3Winding;
begin
  Result := TQ3Winding.Create;
  Result.FPoints := System.Copy(FPoints, 0, FCount);
  Result.FCount := FCount;
end;

function TQ3Winding.ChopInPlace(const ANormal: TQ3Vec3; ADist, AEpsilon: Single): Boolean;
var
  LDists: array[0..Q3_MAX_POINTS_ON_WINDING + 4] of Single;
  LSides: array[0..Q3_MAX_POINTS_ON_WINDING + 4] of Integer;
  LCounts: array[0..2] of Integer;
  LFront: TArray<TQ3Vec3>;
  LFrontCount: Integer;
  LMaxPoints: Integer;
  LIndex: Integer;
  LAxis: Integer;
  LDot: Single;
  LP1: TQ3Vec3;
  LP2: TQ3Vec3;
  LMid: TQ3Vec3;
  LDelta: Single;
begin
  if FCount > Q3_MAX_POINTS_ON_WINDING then
    raise EQ3CollisionException.Create(STooManyPoints);
  LCounts[0] := 0;
  LCounts[1] := 0;
  LCounts[2] := 0;

  // determine sides for each point
  for LIndex := 0 to FCount - 1 do
  begin
    LDot := TQ3Math.Dot(FPoints[LIndex], ANormal);
    LDot := LDot - ADist;
    LDists[LIndex] := LDot;
    if LDot > AEpsilon then
      LSides[LIndex] := SIDE_FRONT
    else if LDot < -AEpsilon then
      LSides[LIndex] := SIDE_BACK
    else
      LSides[LIndex] := SIDE_ON;
    Inc(LCounts[LSides[LIndex]]);
  end;
  LSides[FCount] := LSides[0];
  LDists[FCount] := LDists[0];

  if LCounts[0] = 0 then
  begin
    FPoints := nil;
    FCount := 0;
    Exit(False);
  end;
  if LCounts[1] = 0 then
    Exit(True); // the winding stays the same

  // cant use counts[0]+2 because of fp grouping errors
  LMaxPoints := FCount + 4;
  SetLength(LFront, LMaxPoints);
  LFrontCount := 0;

  for LIndex := 0 to FCount - 1 do
  begin
    LP1 := FPoints[LIndex];

    if LSides[LIndex] = SIDE_ON then
    begin
      LFront[LFrontCount] := LP1;
      Inc(LFrontCount);
      Continue;
    end;

    if LSides[LIndex] = SIDE_FRONT then
    begin
      LFront[LFrontCount] := LP1;
      Inc(LFrontCount);
    end;

    if (LSides[LIndex + 1] = SIDE_ON) or (LSides[LIndex + 1] = LSides[LIndex]) then
      Continue;

    // generate a split point
    LP2 := FPoints[(LIndex + 1) mod FCount];

    // the difference is a float of its own in the C (the divisions of Delphi would use it unrounded)
    LDelta := LDists[LIndex] - LDists[LIndex + 1];
    LDot := LDists[LIndex] / LDelta;
    for LAxis := 0 to 2 do
      // avoid round off error when possible
      if ANormal[LAxis] = 1 then
        LMid[LAxis] := ADist
      else if ANormal[LAxis] = -1 then
        LMid[LAxis] := -ADist
      else
      begin
        LDelta := LP2[LAxis] - LP1[LAxis];
        LDelta := LDot * LDelta;
        LMid[LAxis] := LP1[LAxis] + LDelta;
      end;

    LFront[LFrontCount] := LMid;
    Inc(LFrontCount);
  end;

  if LFrontCount > LMaxPoints then
    raise EQ3CollisionException.Create(SPointsExceeded);
  if LFrontCount > Q3_MAX_POINTS_ON_WINDING then
    raise EQ3CollisionException.Create(STooManyPoints);

  FPoints := System.Copy(LFront, 0, LFrontCount);
  FCount := LFrontCount;
  Result := True;
end;

procedure TQ3Winding.Bounds(out AMins, AMaxs: TQ3Vec3);
var
  LIndex: Integer;
  LAxis: Integer;
  LValue: Single;
begin
  AMins[0] := Q3_MAX_MAP_BOUNDS;
  AMins[1] := Q3_MAX_MAP_BOUNDS;
  AMins[2] := Q3_MAX_MAP_BOUNDS;
  AMaxs[0] := -Q3_MAX_MAP_BOUNDS;
  AMaxs[1] := -Q3_MAX_MAP_BOUNDS;
  AMaxs[2] := -Q3_MAX_MAP_BOUNDS;
  for LIndex := 0 to FCount - 1 do
    for LAxis := 0 to 2 do
    begin
      LValue := FPoints[LIndex][LAxis];
      if LValue < AMins[LAxis] then
        AMins[LAxis] := LValue;
      if LValue > AMaxs[LAxis] then
        AMaxs[LAxis] := LValue;
    end;
end;

end.
