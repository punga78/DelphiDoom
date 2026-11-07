{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the plane (idPlane)                          }
{                                                                              }
{  Port of idPlane (Plane.h, Plane.cpp) of Doom 3 GPL Source Code.             }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Plane;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3;

type
  /// <summary>
  ///   A plane a*x + b*y + c*z + d = 0, like idPlane (16 bytes). The normal is (a, b, c);
  ///   Dist is -d, so a point is in front when Distance is positive
  /// </summary>
  TGeoPlane = record
    A: Single;
    B: Single;
    C: Single;
    D: Single;
  public
    class function Make(AA, AB, AC, AD: Single): TGeoPlane; overload; static;
    class function Make(const ANormal: TGeoVec3; ADist: Single): TGeoPlane; overload; static;

    class operator Negative(const A: TGeoPlane): TGeoPlane;

    procedure Zero;
    function Normal: TGeoVec3;
    procedure SetNormal(const ANormal: TGeoVec3);
    /// <summary>Distance from the origin: -d</summary>
    function Dist: Single;
    procedure SetDist(ADist: Single);
    /// <summary>Plane type, one of PLANETYPE_* (idPlane::Type)</summary>
    function PlaneType: Integer;
    /// <summary>Normalises the normal and returns its old length (idPlane::Normalize)</summary>
    function NormalizeSelf(AFixDegenerate: Boolean = True): Single;
    function FixDegenerateNormal: Boolean;
    /// <summary>Snaps an almost axial normal and its distance (idPlane::FixDegeneracies)</summary>
    function FixDegeneracies(ADistEpsilon: Single): Boolean;
    /// <summary>The plane through three points; false when they are collinear</summary>
    function FromPoints(const AP1, AP2, AP3: TGeoVec3; AFixDegenerate: Boolean = True): Boolean;
    /// <summary>Moves the plane so that it contains the point, keeping the normal</summary>
    procedure FitThroughPoint(const APoint: TGeoVec3);
    function Distance(const AVector: TGeoVec3): Single;
    /// <summary>PLANESIDE_FRONT, _BACK or _ON</summary>
    function Side(const AVector: TGeoVec3; AEpsilon: Single = 0.1): Integer;
    /// <summary>Exact comparison</summary>
    function Compare(const APlane: TGeoPlane): Boolean;
    /// <summary>The normal is multiplied by the matrix, the distance is kept (idPlane::operator*=)</summary>
    procedure RotateNormal(const AMatrix: TGeoMat3);
  end;

  PGeoPlane = ^TGeoPlane;

implementation

uses
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath;

{ TGeoPlane }

class function TGeoPlane.Make(AA, AB, AC, AD: Single): TGeoPlane;
begin
  Result.A := AA;
  Result.B := AB;
  Result.C := AC;
  Result.D := AD;
end;

class function TGeoPlane.Make(const ANormal: TGeoVec3; ADist: Single): TGeoPlane;
begin
  Result.A := ANormal.X;
  Result.B := ANormal.Y;
  Result.C := ANormal.Z;
  Result.D := -ADist;
end;

class operator TGeoPlane.Negative(const A: TGeoPlane): TGeoPlane;
begin
  Result.A := -A.A;
  Result.B := -A.B;
  Result.C := -A.C;
  Result.D := -A.D;
end;

procedure TGeoPlane.Zero;
begin
  A := 0;
  B := 0;
  C := 0;
  D := 0;
end;

function TGeoPlane.Normal: TGeoVec3;
begin
  Result.X := A;
  Result.Y := B;
  Result.Z := C;
end;

procedure TGeoPlane.SetNormal(const ANormal: TGeoVec3);
begin
  A := ANormal.X;
  B := ANormal.Y;
  C := ANormal.Z;
end;

function TGeoPlane.Dist: Single;
begin
  Result := -D;
end;

procedure TGeoPlane.SetDist(ADist: Single);
begin
  D := -ADist;
end;

function TGeoPlane.PlaneType: Integer;
begin
  if A = 0 then
  begin
    if B = 0 then
    begin
      if C > 0 then
        Result := PLANETYPE_Z
      else
        Result := PLANETYPE_NEGZ;
    end
    else if C = 0 then
    begin
      if B > 0 then
        Result := PLANETYPE_Y
      else
        Result := PLANETYPE_NEGY;
    end
    else
      Result := PLANETYPE_ZEROX;
  end
  else if B = 0 then
  begin
    if C = 0 then
    begin
      if A > 0 then
        Result := PLANETYPE_X
      else
        Result := PLANETYPE_NEGX;
    end
    else
      Result := PLANETYPE_ZEROY;
  end
  else if C = 0 then
    Result := PLANETYPE_ZEROZ
  else
    Result := PLANETYPE_NONAXIAL;
end;

function TGeoPlane.NormalizeSelf(AFixDegenerate: Boolean): Single;
var
  LNormal: TGeoVec3;
begin
  LNormal := Normal;
  Result := LNormal.NormalizeSelf;
  SetNormal(LNormal);
  if AFixDegenerate then
    FixDegenerateNormal;
end;

function TGeoPlane.FixDegenerateNormal: Boolean;
var
  LNormal: TGeoVec3;
begin
  LNormal := Normal;
  Result := LNormal.FixDegenerateNormal;
  SetNormal(LNormal);
end;

function TGeoPlane.FixDegeneracies(ADistEpsilon: Single): Boolean;
begin
  Result := FixDegenerateNormal;
  // only fix dist if the normal was degenerate
  if Result then
    if TGeoMath.Fabs(D - TGeoMath.Rint(D)) < ADistEpsilon then
      D := TGeoMath.Rint(D);
end;

function TGeoPlane.FromPoints(const AP1, AP2, AP3: TGeoVec3; AFixDegenerate: Boolean): Boolean;
var
  LNormal: TGeoVec3;
begin
  LNormal := (AP1 - AP2).Cross(AP3 - AP2);
  SetNormal(LNormal);
  if NormalizeSelf(AFixDegenerate) = 0 then
    Exit(False);
  D := -(Normal.Dot(AP2));
  Result := True;
end;

procedure TGeoPlane.FitThroughPoint(const APoint: TGeoVec3);
begin
  D := -(A * APoint.X + B * APoint.Y + C * APoint.Z);
end;

function TGeoPlane.Distance(const AVector: TGeoVec3): Single;
begin
  Result := A * AVector.X + B * AVector.Y + C * AVector.Z + D;
end;

function TGeoPlane.Side(const AVector: TGeoVec3; AEpsilon: Single): Integer;
var
  LDistance: Single;
begin
  LDistance := Distance(AVector);
  if LDistance > AEpsilon then
    Result := PLANESIDE_FRONT
  else if LDistance < -AEpsilon then
    Result := PLANESIDE_BACK
  else
    Result := PLANESIDE_ON;
end;

function TGeoPlane.Compare(const APlane: TGeoPlane): Boolean;
begin
  Result := (A = APlane.A) and (B = APlane.B) and (C = APlane.C) and (D = APlane.D);
end;

procedure TGeoPlane.RotateNormal(const AMatrix: TGeoMat3);
begin
  SetNormal(Normal * AMatrix);
end;

end.
