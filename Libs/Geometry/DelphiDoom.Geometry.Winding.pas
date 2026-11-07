{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the winding (idWinding)                      }
{                                                                              }
{  Port of the used part of idWinding (Winding.h, Winding.cpp) of Doom 3 GPL   }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Doom 3 Source Code: GNU General Public License version 3 with      }
{  additional terms. This unit is a derived work (GPL v3). The texture         }
{  coordinates of idVec5 are not ported: a point is a TGeoVec3.                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Winding;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds;

type
  /// <summary>A convex polygon as a list of points in order (idWinding and idFixedWinding)</summary>
  TGeoWinding = class
  private
    FPoints: TArray<TGeoVec3>;
    FCount: Integer;
    function GetPoint(AIndex: Integer): TGeoVec3;
    procedure SetPoint(AIndex: Integer; const AValue: TGeoVec3);
  public
    constructor Create; overload;
    /// <summary>A winding with a copy of the points</summary>
    constructor Create(const APoints: array of TGeoVec3); overload;
    /// <summary>A huge quadrilateral lying on the plane (idWinding::BaseForPlane)</summary>
    constructor CreateForPlane(const APlane: TGeoPlane);

    property NumPoints: Integer read FCount;
    property Points[AIndex: Integer]: TGeoVec3 read GetPoint write SetPoint; default;

    procedure Clear;
    procedure AddPoint(const APoint: TGeoVec3);
    procedure BaseForPlane(const ANormal: TGeoVec3; ADist: Single); overload;
    procedure BaseForPlane(const APlane: TGeoPlane); overload;
    /// <summary>
    ///   Keeps the part in front of the plane (idWinding::ClipInPlace). Returns false when
    ///   nothing is left (then the winding is empty)
    /// </summary>
    function ClipInPlace(const APlane: TGeoPlane; AEpsilon: Single = 0.1; AKeepOn: Boolean = False): Boolean;
    procedure ReverseSelf;
    function GetBounds: TGeoBounds;
    /// <summary>True when a point is outside of the world limits (idWinding::IsHuge)</summary>
    function IsHuge: Boolean;
    function Copy: TGeoWinding;
  end;

implementation

uses
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath;

{ TGeoWinding }

constructor TGeoWinding.Create;
begin
  inherited Create;
end;

constructor TGeoWinding.Create(const APoints: array of TGeoVec3);
var
  LIndex: Integer;
begin
  inherited Create;
  for LIndex := 0 to High(APoints) do
    AddPoint(APoints[LIndex]);
end;

constructor TGeoWinding.CreateForPlane(const APlane: TGeoPlane);
begin
  inherited Create;
  BaseForPlane(APlane);
end;

function TGeoWinding.GetPoint(AIndex: Integer): TGeoVec3;
begin
  Result := FPoints[AIndex];
end;

procedure TGeoWinding.SetPoint(AIndex: Integer; const AValue: TGeoVec3);
begin
  FPoints[AIndex] := AValue;
end;

procedure TGeoWinding.Clear;
begin
  FCount := 0;
end;

procedure TGeoWinding.AddPoint(const APoint: TGeoVec3);
begin
  if FCount >= Length(FPoints) then
    SetLength(FPoints, FCount * 2 + 4);
  FPoints[FCount] := APoint;
  Inc(FCount);
end;

procedure TGeoWinding.BaseForPlane(const ANormal: TGeoVec3; ADist: Single);
var
  LOrigin: TGeoVec3;
  LRight: TGeoVec3;
  LUp: TGeoVec3;
begin
  LOrigin := ANormal * ADist;
  ANormal.NormalVectors(LUp, LRight);
  LUp := LUp * MAX_WORLD_SIZE;
  LRight := LRight * MAX_WORLD_SIZE;

  FCount := 0;
  AddPoint(LOrigin - LRight + LUp);
  AddPoint(LOrigin + LRight + LUp);
  AddPoint(LOrigin + LRight - LUp);
  AddPoint(LOrigin - LRight - LUp);
end;

procedure TGeoWinding.BaseForPlane(const APlane: TGeoPlane);
begin
  BaseForPlane(APlane.Normal, APlane.Dist);
end;

function TGeoWinding.ClipInPlace(const APlane: TGeoPlane; AEpsilon: Single; AKeepOn: Boolean): Boolean;
var
  LDists: TArray<Single>;
  LSides: TArray<Integer>;
  LCounts: array[0..2] of Integer;
  LNewPoints: TArray<TGeoVec3>;
  LNewCount: Integer;
  LDot: Single;
  LIndex: Integer;
  LAxis: Integer;
  LNext: Integer;
  LP1: TGeoVec3;
  LP2: TGeoVec3;
  LMid: TGeoVec3;
  LPlaneNormal: TGeoVec3;
  LPlaneDist: Single;
begin
  LPlaneNormal := APlane.Normal;
  LPlaneDist := APlane.Dist;
  SetLength(LDists, FCount + 4);
  SetLength(LSides, FCount + 4);
  LCounts[PLANESIDE_FRONT] := 0;
  LCounts[PLANESIDE_BACK] := 0;
  LCounts[PLANESIDE_ON] := 0;

  // determine sides for each point
  for LIndex := 0 to FCount - 1 do
  begin
    LDot := APlane.Distance(FPoints[LIndex]);
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

  // if the winding is on the plane and we should keep it
  if AKeepOn and (LCounts[PLANESIDE_FRONT] = 0) and (LCounts[PLANESIDE_BACK] = 0) then
    Exit(True);
  // if nothing at the front of the clipping plane
  if LCounts[PLANESIDE_FRONT] = 0 then
  begin
    FCount := 0;
    Exit(False);
  end;
  // if nothing at the back of the clipping plane
  if LCounts[PLANESIDE_BACK] = 0 then
    Exit(True);

  SetLength(LNewPoints, FCount + 4);
  LNewCount := 0;
  for LIndex := 0 to FCount - 1 do
  begin
    LP1 := FPoints[LIndex];
    if LSides[LIndex] = PLANESIDE_ON then
    begin
      LNewPoints[LNewCount] := LP1;
      Inc(LNewCount);
      Continue;
    end;
    if LSides[LIndex] = PLANESIDE_FRONT then
    begin
      LNewPoints[LNewCount] := LP1;
      Inc(LNewCount);
    end;
    if (LSides[LIndex + 1] = PLANESIDE_ON) or (LSides[LIndex + 1] = LSides[LIndex]) then
      Continue;

    // generate a split point
    LNext := (LIndex + 1) mod FCount;
    LP2 := FPoints[LNext];
    LDot := LDists[LIndex] / (LDists[LIndex] - LDists[LIndex + 1]);
    for LAxis := 0 to 2 do
    begin
      // avoid round off error when possible
      if LPlaneNormal[LAxis] = 1 then
        LMid[LAxis] := LPlaneDist
      else if LPlaneNormal[LAxis] = -1 then
        LMid[LAxis] := -LPlaneDist
      else
        LMid[LAxis] := LP1[LAxis] + LDot * (LP2[LAxis] - LP1[LAxis]);
    end;
    LNewPoints[LNewCount] := LMid;
    Inc(LNewCount);
  end;

  FPoints := LNewPoints;
  FCount := LNewCount;
  Result := True;
end;

procedure TGeoWinding.ReverseSelf;
var
  LIndex: Integer;
  LTemp: TGeoVec3;
begin
  for LIndex := 0 to (FCount shr 1) - 1 do
  begin
    LTemp := FPoints[LIndex];
    FPoints[LIndex] := FPoints[FCount - LIndex - 1];
    FPoints[FCount - LIndex - 1] := LTemp;
  end;
end;

function TGeoWinding.GetBounds: TGeoBounds;
var
  LIndex: Integer;
  LAxis: Integer;
begin
  if FCount = 0 then
  begin
    Result.Clear;
    Exit;
  end;
  Result.Mins := FPoints[0];
  Result.Maxs := FPoints[0];
  for LIndex := 1 to FCount - 1 do
    for LAxis := 0 to 2 do
      if FPoints[LIndex][LAxis] < Result.Mins[LAxis] then
        Result.Mins[LAxis] := FPoints[LIndex][LAxis]
      else if FPoints[LIndex][LAxis] > Result.Maxs[LAxis] then
        Result.Maxs[LAxis] := FPoints[LIndex][LAxis];
end;

function TGeoWinding.IsHuge: Boolean;
var
  LIndex: Integer;
  LAxis: Integer;
begin
  for LIndex := 0 to FCount - 1 do
    for LAxis := 0 to 2 do
      if (FPoints[LIndex][LAxis] <= MIN_WORLD_COORD) or (FPoints[LIndex][LAxis] >= MAX_WORLD_COORD) then
        Exit(True);
  Result := False;
end;

function TGeoWinding.Copy: TGeoWinding;
var
  LIndex: Integer;
begin
  Result := TGeoWinding.Create;
  for LIndex := 0 to FCount - 1 do
    Result.AddPoint(FPoints[LIndex]);
end;

end.
