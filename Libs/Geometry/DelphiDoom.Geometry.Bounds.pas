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
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane;

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
    function Compare(const ABounds: TGeoBounds): Boolean;
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

end.
