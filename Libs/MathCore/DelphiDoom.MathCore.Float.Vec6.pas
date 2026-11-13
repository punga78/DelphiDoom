{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdVec6, the 6D vector              }
{                                                                              }
{  Port of idVec6 (idlib\math\Vector.h and Vector.cpp) of the Doom 3 GPL       }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Vec6;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3;

type
  /// <summary>A 6D vector of Singles (idVec6: spatial vectors of the articulated figures), 24 bytes</summary>
  TIdVec6 = record
    P: array[0..5] of Single;
  private
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
  public
    class function Create(const A1, A2, A3, A4, A5, A6: Single): TIdVec6; static;
    procedure SetValues(const A1, A2, A3, A4, A5, A6: Single);
    procedure Zero;
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    class operator Negative(const A: TIdVec6): TIdVec6;
    class operator Add(const A, B: TIdVec6): TIdVec6;
    class operator Subtract(const A, B: TIdVec6): TIdVec6;
    /// <summary>The dot product</summary>
    class operator Multiply(const A, B: TIdVec6): Single;
    class operator Multiply(const A: TIdVec6; const B: Single): TIdVec6;
    class operator Multiply(const A: Single; const B: TIdVec6): TIdVec6;
    /// <summary>Multiplies by the reciprocal of the divisor, as the C++ does</summary>
    class operator Divide(const A: TIdVec6; const B: Single): TIdVec6;
    class operator Equal(const A, B: TIdVec6): Boolean;
    class operator NotEqual(const A, B: TIdVec6): Boolean;
    function Compare(const A: TIdVec6; const AEpsilon: Single): Boolean;
    function Length: Single;
    function LengthSqr: Single;
    function Normalize: Single;
    function NormalizeFast: Single;
    function GetDimension: Integer;
    /// <summary>The first (0) or second (1) three components (a copy)</summary>
    function GetSubVec3(const AIndex: Integer): TIdVec3;
    procedure SetSubVec3(const AIndex: Integer; const AValue: TIdVec3);
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

{ TIdVec6 }

class function TIdVec6.Create(const A1, A2, A3, A4, A5, A6: Single): TIdVec6;
begin
  Result.SetValues(A1, A2, A3, A4, A5, A6);
end;

procedure TIdVec6.SetValues(const A1, A2, A3, A4, A5, A6: Single);
begin
  P[0] := A1;
  P[1] := A2;
  P[2] := A3;
  P[3] := A4;
  P[4] := A5;
  P[5] := A6;
end;

procedure TIdVec6.Zero;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 5 do
  begin
    P[LIndex] := 0.0;
  end;
end;

function TIdVec6.GetItem(const AIndex: Integer): Single;
begin
  Result := P[AIndex];
end;

procedure TIdVec6.SetItem(const AIndex: Integer; const AValue: Single);
begin
  P[AIndex] := AValue;
end;

class operator TIdVec6.Negative(const A: TIdVec6): TIdVec6;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 5 do
  begin
    Result.P[LIndex] := -A.P[LIndex];
  end;
end;

class operator TIdVec6.Add(const A, B: TIdVec6): TIdVec6;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 5 do
  begin
    Result.P[LIndex] := A.P[LIndex] + B.P[LIndex];
  end;
end;

class operator TIdVec6.Subtract(const A, B: TIdVec6): TIdVec6;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 5 do
  begin
    Result.P[LIndex] := A.P[LIndex] - B.P[LIndex];
  end;
end;

class operator TIdVec6.Multiply(const A, B: TIdVec6): Single;
begin
  Result := A.P[0] * B.P[0] + A.P[1] * B.P[1] + A.P[2] * B.P[2] + A.P[3] * B.P[3] +
    A.P[4] * B.P[4] + A.P[5] * B.P[5];
end;

class operator TIdVec6.Multiply(const A: TIdVec6; const B: Single): TIdVec6;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 5 do
  begin
    Result.P[LIndex] := A.P[LIndex] * B;
  end;
end;

class operator TIdVec6.Multiply(const A: Single; const B: TIdVec6): TIdVec6;
begin
  Result := B * A;
end;

class operator TIdVec6.Divide(const A: TIdVec6; const B: Single): TIdVec6;
var
  LInverse: Single;
begin
  LInverse := 1.0 / B;
  Result := A * LInverse;
end;

class operator TIdVec6.Equal(const A, B: TIdVec6): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to 5 do
  begin
    if A.P[LIndex] <> B.P[LIndex] then
    begin
      Result := False;
      Break;
    end;
  end;
end;

class operator TIdVec6.NotEqual(const A, B: TIdVec6): Boolean;
begin
  Result := not (A = B);
end;

function TIdVec6.Compare(const A: TIdVec6; const AEpsilon: Single): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to 5 do
  begin
    if TIdMath.Fabs(P[LIndex] - A.P[LIndex]) > AEpsilon then
    begin
      Result := False;
      Break;
    end;
  end;
end;

function TIdVec6.Length: Single;
begin
  Result := TIdMath.Sqrt(LengthSqr);
end;

function TIdVec6.LengthSqr: Single;
begin
  Result := P[0] * P[0] + P[1] * P[1] + P[2] * P[2] + P[3] * P[3] + P[4] * P[4] + P[5] * P[5];
end;

function TIdVec6.Normalize: Single;
var
  LSqrLength, LInvLength: Single;
  LIndex: Integer;
begin
  LSqrLength := LengthSqr;
  LInvLength := TIdMath.InvSqrt(LSqrLength);
  for LIndex := 0 to 5 do
  begin
    P[LIndex] := P[LIndex] * LInvLength;
  end;
  Result := LInvLength * LSqrLength;
end;

function TIdVec6.NormalizeFast: Single;
var
  LSqrLength, LInvLength: Single;
  LIndex: Integer;
begin
  LSqrLength := LengthSqr;
  LInvLength := TIdMath.RSqrt(LSqrLength);
  for LIndex := 0 to 5 do
  begin
    P[LIndex] := P[LIndex] * LInvLength;
  end;
  Result := LInvLength * LSqrLength;
end;

function TIdVec6.GetDimension: Integer;
begin
  Result := 6;
end;

function TIdVec6.GetSubVec3(const AIndex: Integer): TIdVec3;
begin
  Result := TIdVec3.Create(P[AIndex * 3], P[AIndex * 3 + 1], P[AIndex * 3 + 2]);
end;

procedure TIdVec6.SetSubVec3(const AIndex: Integer; const AValue: TIdVec3);
begin
  P[AIndex * 3] := AValue.X;
  P[AIndex * 3 + 1] := AValue.Y;
  P[AIndex * 3 + 2] := AValue.Z;
end;

function TIdVec6.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString(P, APrecision);
end;

end.
