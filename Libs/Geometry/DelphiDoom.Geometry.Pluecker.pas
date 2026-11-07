{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - Pluecker coordinates (idPluecker)            }
{                                                                              }
{  Port of the used part of idPluecker (Pluecker.h) of Doom 3 GPL Source Code. }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Pluecker;

interface

uses
  DelphiDoom.Geometry.Vec3;

type
  /// <summary>Six Single describing a line in 3D (24 bytes)</summary>
  TGeoPluecker = record
    P: array[0..5] of Single;
  public
    procedure Zero;
    /// <summary>The line through two points (idPluecker::FromLine)</summary>
    procedure FromLine(const AStart, AEnd: TGeoVec3);
    /// <summary>The line through a point with a direction (idPluecker::FromRay)</summary>
    procedure FromRay(const AStart, ADir: TGeoVec3);
    /// <summary>Permuted inner product: its sign tells on which side a line passes another</summary>
    function PermutedInnerProduct(const AOther: TGeoPluecker): Single;
  end;

  PGeoPluecker = ^TGeoPluecker;

implementation

{ TGeoPluecker }

procedure TGeoPluecker.Zero;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 5 do
    P[LIndex] := 0;
end;

procedure TGeoPluecker.FromLine(const AStart, AEnd: TGeoVec3);
begin
  P[0] := AStart.X * AEnd.Y - AEnd.X * AStart.Y;
  P[1] := AStart.X * AEnd.Z - AEnd.X * AStart.Z;
  P[2] := AStart.X - AEnd.X;
  P[3] := AStart.Y * AEnd.Z - AEnd.Y * AStart.Z;
  P[4] := AStart.Z - AEnd.Z;
  P[5] := AEnd.Y - AStart.Y;
end;

procedure TGeoPluecker.FromRay(const AStart, ADir: TGeoVec3);
begin
  P[0] := AStart.X * ADir.Y - ADir.X * AStart.Y;
  P[1] := AStart.X * ADir.Z - ADir.X * AStart.Z;
  P[2] := -ADir.X;
  P[3] := AStart.Y * ADir.Z - ADir.Y * AStart.Z;
  P[4] := -ADir.Z;
  P[5] := ADir.Y;
end;

function TGeoPluecker.PermutedInnerProduct(const AOther: TGeoPluecker): Single;
begin
  Result := P[0] * AOther.P[4] + P[1] * AOther.P[5] + P[2] * AOther.P[3] +
    P[4] * AOther.P[0] + P[5] * AOther.P[1] + P[3] * AOther.P[2];
end;

end.
