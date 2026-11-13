{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdVec5, the 5D vector              }
{                                                                              }
{  Port of idVec5 (idlib\math\Vector.h and Vector.cpp) of the Doom 3 GPL       }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Vec5;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3;

type
  /// <summary>A 5D vector of Singles (idVec5: position and texture coordinates), 20 bytes</summary>
  TIdVec5 = record
    X: Single;
    Y: Single;
    Z: Single;
    S: Single;
    T: Single;
  private
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
  public
    class function Create(const AX, AY, AZ, ATextureS, ATextureT: Single): TIdVec5; overload; static;
    class function Create(const AXYZ: TIdVec3; const AST: TIdVec2): TIdVec5; overload; static;
    /// <summary>idVec5::operator=(idVec3): copies xyz and clears s and t</summary>
    class function FromVec3(const AValue: TIdVec3): TIdVec5; static;
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    function GetDimension: Integer;
    /// <summary>The first three components (a copy: the C++ returns a reference into the vector)</summary>
    function ToVec3: TIdVec3;
    procedure Lerp(const AV1, AV2: TIdVec5; const AL: Single);
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

{ TIdVec5 }

class function TIdVec5.Create(const AX, AY, AZ, ATextureS, ATextureT: Single): TIdVec5;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
  Result.S := ATextureS;
  Result.T := ATextureT;
end;

class function TIdVec5.Create(const AXYZ: TIdVec3; const AST: TIdVec2): TIdVec5;
begin
  Result.X := AXYZ.X;
  Result.Y := AXYZ.Y;
  Result.Z := AXYZ.Z;
  Result.S := AST.X;
  Result.T := AST.Y;
end;

class function TIdVec5.FromVec3(const AValue: TIdVec3): TIdVec5;
begin
  Result.X := AValue.X;
  Result.Y := AValue.Y;
  Result.Z := AValue.Z;
  Result.S := 0.0;
  Result.T := 0.0;
end;

function TIdVec5.GetItem(const AIndex: Integer): Single;
begin
  Result := PSingle(PByte(@X) + AIndex * SizeOf(Single))^;
end;

procedure TIdVec5.SetItem(const AIndex: Integer; const AValue: Single);
begin
  PSingle(PByte(@X) + AIndex * SizeOf(Single))^ := AValue;
end;

function TIdVec5.GetDimension: Integer;
begin
  Result := 5;
end;

function TIdVec5.ToVec3: TIdVec3;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

procedure TIdVec5.Lerp(const AV1, AV2: TIdVec5; const AL: Single);
begin
  if AL <= 0.0 then
  begin
    Self := AV1;
  end
  else if AL >= 1.0 then
  begin
    Self := AV2;
  end
  else
  begin
    X := AV1.X + AL * (AV2.X - AV1.X);
    Y := AV1.Y + AL * (AV2.Y - AV1.Y);
    Z := AV1.Z + AL * (AV2.Z - AV1.Z);
    S := AV1.S + AL * (AV2.S - AV1.S);
    T := AV1.T + AL * (AV2.T - AV1.T);
  end;
end;

function TIdVec5.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString([X, Y, Z, S, T], APrecision);
end;

end.
