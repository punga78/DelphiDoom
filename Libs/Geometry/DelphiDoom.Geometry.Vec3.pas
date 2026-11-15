{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the 3D vector (idVec3)                       }
{                                                                              }
{  Port of idVec3 (Vector.h) of Doom 3 GPL Source Code.                        }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Vec3;

interface

type
  /// <summary>A vector of three Single, like idVec3 (12 bytes, no padding)</summary>
  TGeoVec3 = record
    X: Single;
    Y: Single;
    Z: Single;
  private
    function GetItem(AIndex: Integer): Single;
    procedure SetItem(AIndex: Integer; AValue: Single);
  public
    class function Make(AX, AY, AZ: Single): TGeoVec3; static;
    class function Origin: TGeoVec3; static;

    /// <summary>Component 0, 1 or 2 (idVec3::operator[])</summary>
    property Items[AIndex: Integer]: Single read GetItem write SetItem; default;

    class operator Add(const A, B: TGeoVec3): TGeoVec3;
    class operator Subtract(const A, B: TGeoVec3): TGeoVec3;
    class operator Negative(const A: TGeoVec3): TGeoVec3;
    class operator Multiply(const A: TGeoVec3; AScale: Single): TGeoVec3;
    class operator Multiply(AScale: Single; const A: TGeoVec3): TGeoVec3;

    procedure SetValues(AX, AY, AZ: Single);
    procedure Zero;
    /// <summary>Exact comparison, no epsilon (idVec3::Compare)</summary>
    function Compare(const A: TGeoVec3): Boolean; overload;
    function Compare(const A: TGeoVec3; AEpsilon: Single): Boolean; overload;
    function Dot(const A: TGeoVec3): Single;
    function Cross(const A: TGeoVec3): TGeoVec3;
    function Length: Single;
    function LengthSqr: Single;
    /// <summary>Normalises in place and returns the old length (idVec3::Normalize)</summary>
    function NormalizeSelf: Single;
    /// <summary>Makes an almost axial normal exactly axial; true when it changed (idVec3::FixDegenerateNormal)</summary>
    function FixDegenerateNormal: Boolean;
    /// <summary>Two vectors orthogonal to this one, which should be normalised (idVec3::NormalVectors)</summary>
    procedure NormalVectors(out ALeft, ADown: TGeoVec3);
  end;

  PGeoVec3 = ^TGeoVec3;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3;

{ TGeoVec3 }

class function TGeoVec3.Make(AX, AY, AZ: Single): TGeoVec3;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

class function TGeoVec3.Origin: TGeoVec3;
begin
  Result.X := 0;
  Result.Y := 0;
  Result.Z := 0;
end;

function TGeoVec3.GetItem(AIndex: Integer): Single;
begin
  case AIndex of
    0: Result := X;
    1: Result := Y;
  else
    Result := Z;
  end;
end;

procedure TGeoVec3.SetItem(AIndex: Integer; AValue: Single);
begin
  case AIndex of
    0: X := AValue;
    1: Y := AValue;
  else
    Z := AValue;
  end;
end;

class operator TGeoVec3.Add(const A, B: TGeoVec3): TGeoVec3;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
end;

class operator TGeoVec3.Subtract(const A, B: TGeoVec3): TGeoVec3;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
end;

class operator TGeoVec3.Negative(const A: TGeoVec3): TGeoVec3;
begin
  Result.X := -A.X;
  Result.Y := -A.Y;
  Result.Z := -A.Z;
end;

class operator TGeoVec3.Multiply(const A: TGeoVec3; AScale: Single): TGeoVec3;
begin
  Result.X := A.X * AScale;
  Result.Y := A.Y * AScale;
  Result.Z := A.Z * AScale;
end;

class operator TGeoVec3.Multiply(AScale: Single; const A: TGeoVec3): TGeoVec3;
begin
  Result.X := A.X * AScale;
  Result.Y := A.Y * AScale;
  Result.Z := A.Z * AScale;
end;

procedure TGeoVec3.SetValues(AX, AY, AZ: Single);
begin
  X := AX;
  Y := AY;
  Z := AZ;
end;

procedure TGeoVec3.Zero;
begin
  X := 0;
  Y := 0;
  Z := 0;
end;

// The functions below are the ones of TIdVec3 (Libs\IdLib\Math): the two records have the same
// layout (three Single), so they are called through a typecast and exist once.

function TGeoVec3.Compare(const A: TGeoVec3): Boolean;
begin
  Result := TIdVec3(Self) = TIdVec3(A);
end;

function TGeoVec3.Compare(const A: TGeoVec3; AEpsilon: Single): Boolean;
begin
  Result := TIdVec3(Self).Compare(TIdVec3(A), AEpsilon);
end;

function TGeoVec3.Dot(const A: TGeoVec3): Single;
begin
  Result := TIdVec3(Self) * TIdVec3(A);
end;

function TGeoVec3.Cross(const A: TGeoVec3): TGeoVec3;
begin
  TIdVec3(Result) := TIdVec3(Self).Cross(TIdVec3(A));
end;

function TGeoVec3.Length: Single;
begin
  Result := TIdVec3(Self).Length;
end;

function TGeoVec3.LengthSqr: Single;
begin
  Result := TIdVec3(Self).LengthSqr;
end;

function TGeoVec3.NormalizeSelf: Single;
begin
  Result := TIdVec3(Self).Normalize;
end;

function TGeoVec3.FixDegenerateNormal: Boolean;
begin
  Result := TIdVec3(Self).FixDegenerateNormal;
end;

procedure TGeoVec3.NormalVectors(out ALeft, ADown: TGeoVec3);
begin
  TIdVec3(Self).NormalVectors(TIdVec3(ALeft), TIdVec3(ADown));
end;
end.
