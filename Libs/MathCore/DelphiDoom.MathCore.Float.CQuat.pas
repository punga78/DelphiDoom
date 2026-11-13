{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCQuat, the compressed quaternion }
{                                                                              }
{  Port of idCQuat (idlib\math\Quat.h and Quat.cpp) of the Doom 3 GPL Source   }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.CQuat;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Quat;

type
  /// <summary>
  ///   A quaternion without w (idCQuat), 12 bytes: w is rebuilt as the square root of
  ///   |1 - (x*x + y*y + z*z)|, so the stored w must be non-negative.
  /// </summary>
  TIdCQuat = record
    X: Single;
    Y: Single;
    Z: Single;
  private
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
  public
    class function Create(const AX, AY, AZ: Single): TIdCQuat; static;
    procedure SetValues(const AX, AY, AZ: Single);
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    class operator Equal(const A, B: TIdCQuat): Boolean;
    class operator NotEqual(const A, B: TIdCQuat): Boolean;
    function Compare(const A: TIdCQuat; const AEpsilon: Single): Boolean;
    function GetDimension: Integer;
    function ToQuat: TIdQuat;
  end;

implementation

{ TIdCQuat }

class function TIdCQuat.Create(const AX, AY, AZ: Single): TIdCQuat;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

procedure TIdCQuat.SetValues(const AX, AY, AZ: Single);
begin
  X := AX;
  Y := AY;
  Z := AZ;
end;

function TIdCQuat.GetItem(const AIndex: Integer): Single;
begin
  Result := PSingle(PByte(@X) + AIndex * SizeOf(Single))^;
end;

procedure TIdCQuat.SetItem(const AIndex: Integer; const AValue: Single);
begin
  PSingle(PByte(@X) + AIndex * SizeOf(Single))^ := AValue;
end;

class operator TIdCQuat.Equal(const A, B: TIdCQuat): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z);
end;

class operator TIdCQuat.NotEqual(const A, B: TIdCQuat): Boolean;
begin
  Result := not (A = B);
end;

function TIdCQuat.Compare(const A: TIdCQuat; const AEpsilon: Single): Boolean;
var
  LDelta: Single;
begin
  Result := False;
  LDelta := X - A.X;
  if System.Abs(LDelta) > AEpsilon then
    Exit;
  LDelta := Y - A.Y;
  if System.Abs(LDelta) > AEpsilon then
    Exit;
  LDelta := Z - A.Z;
  if System.Abs(LDelta) > AEpsilon then
    Exit;
  Result := True;
end;

function TIdCQuat.GetDimension: Integer;
begin
  Result := 3;
end;

function TIdCQuat.ToQuat: TIdQuat;
var
  LValue: Single;
begin
  LValue := System.Abs(1.0 - (X * X + Y * Y + Z * Z));
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
  Result.W := System.Sqrt(LValue);
end;

end.
