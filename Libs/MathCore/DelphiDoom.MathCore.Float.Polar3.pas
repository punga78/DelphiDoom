{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdPolar3, polar coordinates        }
{                                                                              }
{  Port of idPolar3 (idlib\math\Vector.h) of the Doom 3 GPL Source Code.       }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Polar3;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3;

type
  /// <summary>Polar coordinates (idPolar3), 12 bytes; <c>TIdVec3.ToPolar</c> is the opposite conversion</summary>
  TIdPolar3 = record
    Radius: Single;
    Theta: Single;
    Phi: Single;
  private
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
  public
    class function Create(const ARadius, ATheta, APhi: Single): TIdPolar3; static;
    procedure SetValues(const ARadius, ATheta, APhi: Single);
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    class operator Negative(const A: TIdPolar3): TIdPolar3;
    function ToVec3: TIdVec3;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

{ TIdPolar3 }

class function TIdPolar3.Create(const ARadius, ATheta, APhi: Single): TIdPolar3;
begin
  Result.SetValues(ARadius, ATheta, APhi);
end;

procedure TIdPolar3.SetValues(const ARadius, ATheta, APhi: Single);
begin
  Radius := ARadius;
  Theta := ATheta;
  Phi := APhi;
end;

function TIdPolar3.GetItem(const AIndex: Integer): Single;
begin
  Result := PSingle(PByte(@Radius) + AIndex * SizeOf(Single))^;
end;

procedure TIdPolar3.SetItem(const AIndex: Integer; const AValue: Single);
begin
  PSingle(PByte(@Radius) + AIndex * SizeOf(Single))^ := AValue;
end;

class operator TIdPolar3.Negative(const A: TIdPolar3): TIdPolar3;
begin
  Result := Create(A.Radius, -A.Theta, -A.Phi);
end;

function TIdPolar3.ToVec3: TIdVec3;
var
  LSinPhi, LCosPhi, LSinTheta, LCosTheta: Single;
  LTemp: Single;
begin
  TIdMath.SinCos(Phi, LSinPhi, LCosPhi);
  TIdMath.SinCos(Theta, LSinTheta, LCosTheta);
  LTemp := LCosPhi * Radius;
  Result.X := LTemp * LCosTheta;
  Result.Y := LTemp * LSinTheta;
  Result.Z := Radius * LSinPhi;
end;

end.
