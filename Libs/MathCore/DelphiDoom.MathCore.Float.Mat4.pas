{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMat4, the 4x4 matrix             }
{                                                                              }
{  Port of idMat4 (idlib\math\Matrix.h and Matrix.cpp) of the Doom 3 GPL       }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Mat4;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.MathCore.Float.Mat3;

type
  /// <summary>
  ///   A 4x4 matrix of Single stored by rows (idMat4), 64 bytes. Unlike idMat3 the product with a
  ///   vector is the usual matrix times column vector; the 3D vector overload divides by w.
  /// </summary>
  TIdMat4 = record
    Rows: array[0..3] of TIdVec4;
  public
    class function Create(const AX, AY, AZ, AW: TIdVec4): TIdMat4; overload; static;
    class function Create(const AXX, AXY, AXZ, AXW, AYX, AYY, AYZ, AYW, AZX, AZY, AZZ, AZW, AWX,
      AWY, AWZ, AWW: Single): TIdMat4; overload; static;
    /// <summary>idMat4(rotation, translation): the idMat3 is transposed because it is column-major</summary>
    class function Create(const ARotation: TIdMat3; const ATranslation: TIdVec3): TIdMat4;
      overload; static;
    /// <summary>idMat3::ToMat4</summary>
    class function FromMat3(const AValue: TIdMat3): TIdMat4; static;
    class function Identity: TIdMat4; static;
    class operator Add(const A, B: TIdMat4): TIdMat4;
    class operator Subtract(const A, B: TIdMat4): TIdMat4;
    class operator Multiply(const A, B: TIdMat4): TIdMat4;
    class operator Multiply(const A: TIdMat4; const B: Single): TIdMat4;
    class operator Multiply(const A: Single; const B: TIdMat4): TIdMat4;
    class operator Multiply(const A: TIdMat4; const B: TIdVec4): TIdVec4;
    class operator Multiply(const A: TIdVec4; const B: TIdMat4): TIdVec4;
    class operator Multiply(const A: TIdMat4; const B: TIdVec3): TIdVec3;
    class operator Multiply(const A: TIdVec3; const B: TIdMat4): TIdVec3;
    class operator Equal(const A, B: TIdMat4): Boolean;
    class operator NotEqual(const A, B: TIdMat4): Boolean;
    function Compare(const A: TIdMat4; const AEpsilon: Single): Boolean;
    procedure Zero;
    procedure SetIdentity;
    function IsIdentity(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsSymmetric(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsDiagonal(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsRotated: Boolean;
    procedure ProjectVector(const ASource: TIdVec4; out ADestination: TIdVec4);
    procedure UnprojectVector(const ASource: TIdVec4; out ADestination: TIdVec4);
    function Trace: Single;
    function Determinant: Single;
    function Transpose: TIdMat4;
    procedure TransposeSelf;
    function Inverse: TIdMat4;
    /// <summary>Inverts in place; false (and no change) if the determinant is almost zero</summary>
    function InverseSelf: Boolean;
    function InverseFast: TIdMat4;
    function InverseFastSelf: Boolean;
    function GetDimension: Integer;
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

type
  TFlat = array[0..15] of Single;
  PFlat = ^TFlat;

{ TIdMat4 }

class function TIdMat4.Create(const AX, AY, AZ, AW: TIdVec4): TIdMat4;
begin
  Result.Rows[0] := AX;
  Result.Rows[1] := AY;
  Result.Rows[2] := AZ;
  Result.Rows[3] := AW;
end;

class function TIdMat4.Create(const AXX, AXY, AXZ, AXW, AYX, AYY, AYZ, AYW, AZX, AZY, AZZ, AZW, AWX,
  AWY, AWZ, AWW: Single): TIdMat4;
begin
  Result.Rows[0].SetValues(AXX, AXY, AXZ, AXW);
  Result.Rows[1].SetValues(AYX, AYY, AYZ, AYW);
  Result.Rows[2].SetValues(AZX, AZY, AZZ, AZW);
  Result.Rows[3].SetValues(AWX, AWY, AWZ, AWW);
end;

class function TIdMat4.Create(const ARotation: TIdMat3; const ATranslation: TIdVec3): TIdMat4;
begin
  Result.Rows[0].SetValues(ARotation.Rows[0].X, ARotation.Rows[1].X, ARotation.Rows[2].X,
    ATranslation.X);
  Result.Rows[1].SetValues(ARotation.Rows[0].Y, ARotation.Rows[1].Y, ARotation.Rows[2].Y,
    ATranslation.Y);
  Result.Rows[2].SetValues(ARotation.Rows[0].Z, ARotation.Rows[1].Z, ARotation.Rows[2].Z,
    ATranslation.Z);
  Result.Rows[3].SetValues(0.0, 0.0, 0.0, 1.0);
end;

class function TIdMat4.FromMat3(const AValue: TIdMat3): TIdMat4;
begin
  Result := Create(AValue, TIdVec3.Create(0.0, 0.0, 0.0));
end;

class function TIdMat4.Identity: TIdMat4;
begin
  Result := Create(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
end;

class operator TIdMat4.Add(const A, B: TIdMat4): TIdMat4;
var
  LRow: Integer;
begin
  for LRow := 0 to 3 do
  begin
    Result.Rows[LRow] := A.Rows[LRow] + B.Rows[LRow];
  end;
end;

class operator TIdMat4.Subtract(const A, B: TIdMat4): TIdMat4;
var
  LRow: Integer;
begin
  for LRow := 0 to 3 do
  begin
    Result.Rows[LRow] := A.Rows[LRow] - B.Rows[LRow];
  end;
end;

class operator TIdMat4.Multiply(const A, B: TIdMat4): TIdMat4;
var
  LRow, LColumn, LK: Integer;
  LFirst, LSecond, LDestination: PFlat;
  LSum: Single;
begin
  LFirst := PFlat(@A.Rows[0]);
  LSecond := PFlat(@B.Rows[0]);
  LDestination := PFlat(@Result.Rows[0]);
  for LRow := 0 to 3 do
  begin
    for LColumn := 0 to 3 do
    begin
      LSum := LFirst^[LRow * 4] * LSecond^[LColumn];
      for LK := 1 to 3 do
      begin
        LSum := LSum + LFirst^[LRow * 4 + LK] * LSecond^[LK * 4 + LColumn];
      end;
      LDestination^[LRow * 4 + LColumn] := LSum;
    end;
  end;
end;

class operator TIdMat4.Multiply(const A: TIdMat4; const B: Single): TIdMat4;
var
  LRow: Integer;
begin
  for LRow := 0 to 3 do
  begin
    Result.Rows[LRow] := A.Rows[LRow] * B;
  end;
end;

class operator TIdMat4.Multiply(const A: Single; const B: TIdMat4): TIdMat4;
begin
  Result := B * A;
end;

class operator TIdMat4.Multiply(const A: TIdMat4; const B: TIdVec4): TIdVec4;
begin
  Result.X := A.Rows[0].X * B.X + A.Rows[0].Y * B.Y + A.Rows[0].Z * B.Z + A.Rows[0].W * B.W;
  Result.Y := A.Rows[1].X * B.X + A.Rows[1].Y * B.Y + A.Rows[1].Z * B.Z + A.Rows[1].W * B.W;
  Result.Z := A.Rows[2].X * B.X + A.Rows[2].Y * B.Y + A.Rows[2].Z * B.Z + A.Rows[2].W * B.W;
  Result.W := A.Rows[3].X * B.X + A.Rows[3].Y * B.Y + A.Rows[3].Z * B.Z + A.Rows[3].W * B.W;
end;

class operator TIdMat4.Multiply(const A: TIdVec4; const B: TIdMat4): TIdVec4;
begin
  Result := B * A;
end;

class operator TIdMat4.Multiply(const A: TIdMat4; const B: TIdVec3): TIdVec3;
var
  LScale, LInverseScale: Single;
begin
  LScale := A.Rows[3].X * B.X + A.Rows[3].Y * B.Y + A.Rows[3].Z * B.Z + A.Rows[3].W;
  if LScale = 0.0 then
  begin
    Result.SetValues(0.0, 0.0, 0.0);
  end
  else if LScale = 1.0 then
  begin
    Result.X := A.Rows[0].X * B.X + A.Rows[0].Y * B.Y + A.Rows[0].Z * B.Z + A.Rows[0].W;
    Result.Y := A.Rows[1].X * B.X + A.Rows[1].Y * B.Y + A.Rows[1].Z * B.Z + A.Rows[1].W;
    Result.Z := A.Rows[2].X * B.X + A.Rows[2].Y * B.Y + A.Rows[2].Z * B.Z + A.Rows[2].W;
  end
  else
  begin
    LInverseScale := 1.0 / LScale;
    Result.X := (A.Rows[0].X * B.X + A.Rows[0].Y * B.Y + A.Rows[0].Z * B.Z + A.Rows[0].W) *
      LInverseScale;
    Result.Y := (A.Rows[1].X * B.X + A.Rows[1].Y * B.Y + A.Rows[1].Z * B.Z + A.Rows[1].W) *
      LInverseScale;
    Result.Z := (A.Rows[2].X * B.X + A.Rows[2].Y * B.Y + A.Rows[2].Z * B.Z + A.Rows[2].W) *
      LInverseScale;
  end;
end;

class operator TIdMat4.Multiply(const A: TIdVec3; const B: TIdMat4): TIdVec3;
begin
  Result := B * A;
end;

class operator TIdMat4.Equal(const A, B: TIdMat4): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to 15 do
  begin
    if PFlat(@A.Rows[0])^[LIndex] <> PFlat(@B.Rows[0])^[LIndex] then
    begin
      Result := False;
      Break;
    end;
  end;
end;

class operator TIdMat4.NotEqual(const A, B: TIdMat4): Boolean;
begin
  Result := not (A = B);
end;

function TIdMat4.Compare(const A: TIdMat4; const AEpsilon: Single): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to 15 do
  begin
    if TIdMath.Fabs(PFlat(@Rows[0])^[LIndex] - PFlat(@A.Rows[0])^[LIndex]) > AEpsilon then
    begin
      Result := False;
      Break;
    end;
  end;
end;

procedure TIdMat4.Zero;
var
  LRow: Integer;
begin
  for LRow := 0 to 3 do
  begin
    Rows[LRow].Zero;
  end;
end;

procedure TIdMat4.SetIdentity;
begin
  Self := Identity;
end;

function TIdMat4.IsIdentity(const AEpsilon: Single): Boolean;
begin
  Result := Compare(Identity, AEpsilon);
end;

function TIdMat4.IsSymmetric(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
  LMat: PFlat;
begin
  LMat := PFlat(@Rows[0]);
  Result := True;
  for LRow := 1 to 3 do
  begin
    for LColumn := 0 to LRow - 1 do
    begin
      if TIdMath.Fabs(LMat^[LRow * 4 + LColumn] - LMat^[LColumn * 4 + LRow]) > AEpsilon then
        Exit(False);
    end;
  end;
end;

function TIdMat4.IsDiagonal(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
  LMat: PFlat;
begin
  LMat := PFlat(@Rows[0]);
  Result := True;
  for LRow := 0 to 3 do
  begin
    for LColumn := 0 to 3 do
    begin
      if (LRow <> LColumn) and (TIdMath.Fabs(LMat^[LRow * 4 + LColumn]) > AEpsilon) then
        Exit(False);
    end;
  end;
end;

function TIdMat4.IsRotated: Boolean;
begin
  Result := not ((Rows[0].Y = 0.0) and (Rows[0].Z = 0.0) and (Rows[1].X = 0.0) and
    (Rows[1].Z = 0.0) and (Rows[2].X = 0.0) and (Rows[2].Y = 0.0));
end;

procedure TIdMat4.ProjectVector(const ASource: TIdVec4; out ADestination: TIdVec4);
begin
  ADestination.X := ASource * Rows[0];
  ADestination.Y := ASource * Rows[1];
  ADestination.Z := ASource * Rows[2];
  ADestination.W := ASource * Rows[3];
end;

procedure TIdMat4.UnprojectVector(const ASource: TIdVec4; out ADestination: TIdVec4);
begin
  ADestination := Rows[0] * ASource.X + Rows[1] * ASource.Y + Rows[2] * ASource.Z +
    Rows[3] * ASource.W;
end;

function TIdMat4.Trace: Single;
begin
  Result := Rows[0].X + Rows[1].Y + Rows[2].Z + Rows[3].W;
end;

function TIdMat4.Transpose: TIdMat4;
var
  LRow, LColumn: Integer;
begin
  for LRow := 0 to 3 do
  begin
    for LColumn := 0 to 3 do
    begin
      Result.Rows[LRow][LColumn] := Rows[LColumn][LRow];
    end;
  end;
end;

procedure TIdMat4.TransposeSelf;
var
  LRow, LColumn: Integer;
  LTemp: Single;
begin
  for LRow := 0 to 3 do
  begin
    for LColumn := LRow + 1 to 3 do
    begin
      LTemp := Rows[LRow][LColumn];
      Rows[LRow][LColumn] := Rows[LColumn][LRow];
      Rows[LColumn][LRow] := LTemp;
    end;
  end;
end;

function TIdMat4.Inverse: TIdMat4;
begin
  Result := Self;
  Result.InverseSelf;
end;

function TIdMat4.InverseFast: TIdMat4;
begin
  Result := Self;
  Result.InverseFastSelf;
end;

function TIdMat4.GetDimension: Integer;
begin
  Result := 16;
end;

function TIdMat4.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString(PFlat(@Rows[0])^, APrecision);
end;

function TIdMat4.Determinant: Single;
var
  LMat: PFlat;
  LDet2_01_01, LDet2_01_02, LDet2_01_03, LDet2_01_12, LDet2_01_13, LDet2_01_23: Single;
  LDet3_201_012, LDet3_201_013, LDet3_201_023, LDet3_201_123: Single;
begin
  LMat := PFlat(@Rows[0]);
  // 2x2 sub-determinants
  LDet2_01_01 := LMat^[0*4+0] * LMat^[1*4+1] - LMat^[0*4+1] * LMat^[1*4+0];
  LDet2_01_02 := LMat^[0*4+0] * LMat^[1*4+2] - LMat^[0*4+2] * LMat^[1*4+0];
  LDet2_01_03 := LMat^[0*4+0] * LMat^[1*4+3] - LMat^[0*4+3] * LMat^[1*4+0];
  LDet2_01_12 := LMat^[0*4+1] * LMat^[1*4+2] - LMat^[0*4+2] * LMat^[1*4+1];
  LDet2_01_13 := LMat^[0*4+1] * LMat^[1*4+3] - LMat^[0*4+3] * LMat^[1*4+1];
  LDet2_01_23 := LMat^[0*4+2] * LMat^[1*4+3] - LMat^[0*4+3] * LMat^[1*4+2];
  
  // 3x3 sub-determinants
  LDet3_201_012 := LMat^[2*4+0] * LDet2_01_12 - LMat^[2*4+1] * LDet2_01_02 + LMat^[2*4+2] * LDet2_01_01;
  LDet3_201_013 := LMat^[2*4+0] * LDet2_01_13 - LMat^[2*4+1] * LDet2_01_03 + LMat^[2*4+3] * LDet2_01_01;
  LDet3_201_023 := LMat^[2*4+0] * LDet2_01_23 - LMat^[2*4+2] * LDet2_01_03 + LMat^[2*4+3] * LDet2_01_02;
  LDet3_201_123 := LMat^[2*4+1] * LDet2_01_23 - LMat^[2*4+2] * LDet2_01_13 + LMat^[2*4+3] * LDet2_01_12;
  
  Result := ( - LDet3_201_123 * LMat^[3*4+0] + LDet3_201_023 * LMat^[3*4+1] - LDet3_201_013 * LMat^[3*4+2] + LDet3_201_012 * LMat^[3*4+3] );
end;

function TIdMat4.InverseSelf: Boolean;
var
  LMat: PFlat;
  LDet2_01_01, LDet2_01_02, LDet2_01_03, LDet2_01_12, LDet2_01_13, LDet2_01_23: Single;
  LDet2_03_01, LDet2_03_02, LDet2_03_03, LDet2_03_12, LDet2_03_13, LDet2_03_23: Single;
  LDet2_13_01, LDet2_13_02, LDet2_13_03, LDet2_13_12, LDet2_13_13, LDet2_13_23: Single;
  LDet3_201_012, LDet3_201_013, LDet3_201_023, LDet3_201_123, LDet3_203_012, LDet3_203_013: Single;
  LDet3_203_023, LDet3_203_123, LDet3_213_012, LDet3_213_013, LDet3_213_023, LDet3_213_123: Single;
  LDet3_301_012, LDet3_301_013, LDet3_301_023, LDet3_301_123: Single;
  LDet, LInvDet: Double;
begin
  LMat := PFlat(@Rows[0]);
  // 84+4+16 = 104 multiplications
  //         1 division
  
  // 2x2 sub-determinants required to calculate 4x4 determinant
  LDet2_01_01 := LMat^[0*4+0] * LMat^[1*4+1] - LMat^[0*4+1] * LMat^[1*4+0];
  LDet2_01_02 := LMat^[0*4+0] * LMat^[1*4+2] - LMat^[0*4+2] * LMat^[1*4+0];
  LDet2_01_03 := LMat^[0*4+0] * LMat^[1*4+3] - LMat^[0*4+3] * LMat^[1*4+0];
  LDet2_01_12 := LMat^[0*4+1] * LMat^[1*4+2] - LMat^[0*4+2] * LMat^[1*4+1];
  LDet2_01_13 := LMat^[0*4+1] * LMat^[1*4+3] - LMat^[0*4+3] * LMat^[1*4+1];
  LDet2_01_23 := LMat^[0*4+2] * LMat^[1*4+3] - LMat^[0*4+3] * LMat^[1*4+2];
  
  // 3x3 sub-determinants required to calculate 4x4 determinant
  LDet3_201_012 := LMat^[2*4+0] * LDet2_01_12 - LMat^[2*4+1] * LDet2_01_02 + LMat^[2*4+2] * LDet2_01_01;
  LDet3_201_013 := LMat^[2*4+0] * LDet2_01_13 - LMat^[2*4+1] * LDet2_01_03 + LMat^[2*4+3] * LDet2_01_01;
  LDet3_201_023 := LMat^[2*4+0] * LDet2_01_23 - LMat^[2*4+2] * LDet2_01_03 + LMat^[2*4+3] * LDet2_01_02;
  LDet3_201_123 := LMat^[2*4+1] * LDet2_01_23 - LMat^[2*4+2] * LDet2_01_13 + LMat^[2*4+3] * LDet2_01_12;
  
  LDet := ( - LDet3_201_123 * LMat^[3*4+0] + LDet3_201_023 * LMat^[3*4+1] - LDet3_201_013 * LMat^[3*4+2] + LDet3_201_012 * LMat^[3*4+3] );
  
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  
  LInvDet := 1.0 / LDet;
  
  // remaining 2x2 sub-determinants
  LDet2_03_01 := LMat^[0*4+0] * LMat^[3*4+1] - LMat^[0*4+1] * LMat^[3*4+0];
  LDet2_03_02 := LMat^[0*4+0] * LMat^[3*4+2] - LMat^[0*4+2] * LMat^[3*4+0];
  LDet2_03_03 := LMat^[0*4+0] * LMat^[3*4+3] - LMat^[0*4+3] * LMat^[3*4+0];
  LDet2_03_12 := LMat^[0*4+1] * LMat^[3*4+2] - LMat^[0*4+2] * LMat^[3*4+1];
  LDet2_03_13 := LMat^[0*4+1] * LMat^[3*4+3] - LMat^[0*4+3] * LMat^[3*4+1];
  LDet2_03_23 := LMat^[0*4+2] * LMat^[3*4+3] - LMat^[0*4+3] * LMat^[3*4+2];
  
  LDet2_13_01 := LMat^[1*4+0] * LMat^[3*4+1] - LMat^[1*4+1] * LMat^[3*4+0];
  LDet2_13_02 := LMat^[1*4+0] * LMat^[3*4+2] - LMat^[1*4+2] * LMat^[3*4+0];
  LDet2_13_03 := LMat^[1*4+0] * LMat^[3*4+3] - LMat^[1*4+3] * LMat^[3*4+0];
  LDet2_13_12 := LMat^[1*4+1] * LMat^[3*4+2] - LMat^[1*4+2] * LMat^[3*4+1];
  LDet2_13_13 := LMat^[1*4+1] * LMat^[3*4+3] - LMat^[1*4+3] * LMat^[3*4+1];
  LDet2_13_23 := LMat^[1*4+2] * LMat^[3*4+3] - LMat^[1*4+3] * LMat^[3*4+2];
  
  // remaining 3x3 sub-determinants
  LDet3_203_012 := LMat^[2*4+0] * LDet2_03_12 - LMat^[2*4+1] * LDet2_03_02 + LMat^[2*4+2] * LDet2_03_01;
  LDet3_203_013 := LMat^[2*4+0] * LDet2_03_13 - LMat^[2*4+1] * LDet2_03_03 + LMat^[2*4+3] * LDet2_03_01;
  LDet3_203_023 := LMat^[2*4+0] * LDet2_03_23 - LMat^[2*4+2] * LDet2_03_03 + LMat^[2*4+3] * LDet2_03_02;
  LDet3_203_123 := LMat^[2*4+1] * LDet2_03_23 - LMat^[2*4+2] * LDet2_03_13 + LMat^[2*4+3] * LDet2_03_12;
  
  LDet3_213_012 := LMat^[2*4+0] * LDet2_13_12 - LMat^[2*4+1] * LDet2_13_02 + LMat^[2*4+2] * LDet2_13_01;
  LDet3_213_013 := LMat^[2*4+0] * LDet2_13_13 - LMat^[2*4+1] * LDet2_13_03 + LMat^[2*4+3] * LDet2_13_01;
  LDet3_213_023 := LMat^[2*4+0] * LDet2_13_23 - LMat^[2*4+2] * LDet2_13_03 + LMat^[2*4+3] * LDet2_13_02;
  LDet3_213_123 := LMat^[2*4+1] * LDet2_13_23 - LMat^[2*4+2] * LDet2_13_13 + LMat^[2*4+3] * LDet2_13_12;
  
  LDet3_301_012 := LMat^[3*4+0] * LDet2_01_12 - LMat^[3*4+1] * LDet2_01_02 + LMat^[3*4+2] * LDet2_01_01;
  LDet3_301_013 := LMat^[3*4+0] * LDet2_01_13 - LMat^[3*4+1] * LDet2_01_03 + LMat^[3*4+3] * LDet2_01_01;
  LDet3_301_023 := LMat^[3*4+0] * LDet2_01_23 - LMat^[3*4+2] * LDet2_01_03 + LMat^[3*4+3] * LDet2_01_02;
  LDet3_301_123 := LMat^[3*4+1] * LDet2_01_23 - LMat^[3*4+2] * LDet2_01_13 + LMat^[3*4+3] * LDet2_01_12;
  
  LMat^[0*4+0] := - LDet3_213_123 * LInvDet;
  LMat^[1*4+0] := + LDet3_213_023 * LInvDet;
  LMat^[2*4+0] := - LDet3_213_013 * LInvDet;
  LMat^[3*4+0] := + LDet3_213_012 * LInvDet;
  
  LMat^[0*4+1] := + LDet3_203_123 * LInvDet;
  LMat^[1*4+1] := - LDet3_203_023 * LInvDet;
  LMat^[2*4+1] := + LDet3_203_013 * LInvDet;
  LMat^[3*4+1] := - LDet3_203_012 * LInvDet;
  
  LMat^[0*4+2] := + LDet3_301_123 * LInvDet;
  LMat^[1*4+2] := - LDet3_301_023 * LInvDet;
  LMat^[2*4+2] := + LDet3_301_013 * LInvDet;
  LMat^[3*4+2] := - LDet3_301_012 * LInvDet;
  
  LMat^[0*4+3] := - LDet3_201_123 * LInvDet;
  LMat^[1*4+3] := + LDet3_201_023 * LInvDet;
  LMat^[2*4+3] := - LDet3_201_013 * LInvDet;
  LMat^[3*4+3] := + LDet3_201_012 * LInvDet;
  
  Result := true;
end;

function TIdMat4.InverseFastSelf: Boolean;
var
  LMat: PFlat;
  LA, LDet, LInvDet: Single;
  LR0: array[0..1, 0..1] of Single;
  LR1: array[0..1, 0..1] of Single;
  LR2: array[0..1, 0..1] of Single;
  LR3: array[0..1, 0..1] of Single;
begin
  LMat := PFlat(@Rows[0]);
  //  6*8+2*6 = 60 multiplications
  //    2*1 =  2 divisions
  
  // r0 = m0.Inverse();
  LDet := LMat^[0*4+0] * LMat^[1*4+1] - LMat^[0*4+1] * LMat^[1*4+0];
  
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  
  LInvDet := 1.0 / LDet;
  
  LR0[0][0] := LMat^[1*4+1] * LInvDet;
  LR0[0][1] := - LMat^[0*4+1] * LInvDet;
  LR0[1][0] := - LMat^[1*4+0] * LInvDet;
  LR0[1][1] := LMat^[0*4+0] * LInvDet;
  
  // r1 = r0 * m1;
  LR1[0][0] := LR0[0][0] * LMat^[0*4+2] + LR0[0][1] * LMat^[1*4+2];
  LR1[0][1] := LR0[0][0] * LMat^[0*4+3] + LR0[0][1] * LMat^[1*4+3];
  LR1[1][0] := LR0[1][0] * LMat^[0*4+2] + LR0[1][1] * LMat^[1*4+2];
  LR1[1][1] := LR0[1][0] * LMat^[0*4+3] + LR0[1][1] * LMat^[1*4+3];
  
  // r2 = m2 * r1;
  LR2[0][0] := LMat^[2*4+0] * LR1[0][0] + LMat^[2*4+1] * LR1[1][0];
  LR2[0][1] := LMat^[2*4+0] * LR1[0][1] + LMat^[2*4+1] * LR1[1][1];
  LR2[1][0] := LMat^[3*4+0] * LR1[0][0] + LMat^[3*4+1] * LR1[1][0];
  LR2[1][1] := LMat^[3*4+0] * LR1[0][1] + LMat^[3*4+1] * LR1[1][1];
  
  // r3 = r2 - m3;
  LR3[0][0] := LR2[0][0] - LMat^[2*4+2];
  LR3[0][1] := LR2[0][1] - LMat^[2*4+3];
  LR3[1][0] := LR2[1][0] - LMat^[3*4+2];
  LR3[1][1] := LR2[1][1] - LMat^[3*4+3];
  
  // r3.InverseSelf();
  LDet := LR3[0][0] * LR3[1][1] - LR3[0][1] * LR3[1][0];
  
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  
  LInvDet := 1.0 / LDet;
  
  LA := LR3[0][0];
  LR3[0][0] := LR3[1][1] * LInvDet;
  LR3[0][1] := - LR3[0][1] * LInvDet;
  LR3[1][0] := - LR3[1][0] * LInvDet;
  LR3[1][1] := LA * LInvDet;
  
  // r2 = m2 * r0;
  LR2[0][0] := LMat^[2*4+0] * LR0[0][0] + LMat^[2*4+1] * LR0[1][0];
  LR2[0][1] := LMat^[2*4+0] * LR0[0][1] + LMat^[2*4+1] * LR0[1][1];
  LR2[1][0] := LMat^[3*4+0] * LR0[0][0] + LMat^[3*4+1] * LR0[1][0];
  LR2[1][1] := LMat^[3*4+0] * LR0[0][1] + LMat^[3*4+1] * LR0[1][1];
  
  // m2 = r3 * r2;
  LMat^[2*4+0] := LR3[0][0] * LR2[0][0] + LR3[0][1] * LR2[1][0];
  LMat^[2*4+1] := LR3[0][0] * LR2[0][1] + LR3[0][1] * LR2[1][1];
  LMat^[3*4+0] := LR3[1][0] * LR2[0][0] + LR3[1][1] * LR2[1][0];
  LMat^[3*4+1] := LR3[1][0] * LR2[0][1] + LR3[1][1] * LR2[1][1];
  
  // m0 = r0 - r1 * m2;
  LMat^[0*4+0] := LR0[0][0] - LR1[0][0] * LMat^[2*4+0] - LR1[0][1] * LMat^[3*4+0];
  LMat^[0*4+1] := LR0[0][1] - LR1[0][0] * LMat^[2*4+1] - LR1[0][1] * LMat^[3*4+1];
  LMat^[1*4+0] := LR0[1][0] - LR1[1][0] * LMat^[2*4+0] - LR1[1][1] * LMat^[3*4+0];
  LMat^[1*4+1] := LR0[1][1] - LR1[1][0] * LMat^[2*4+1] - LR1[1][1] * LMat^[3*4+1];
  
  // m1 = r1 * r3;
  LMat^[0*4+2] := LR1[0][0] * LR3[0][0] + LR1[0][1] * LR3[1][0];
  LMat^[0*4+3] := LR1[0][0] * LR3[0][1] + LR1[0][1] * LR3[1][1];
  LMat^[1*4+2] := LR1[1][0] * LR3[0][0] + LR1[1][1] * LR3[1][0];
  LMat^[1*4+3] := LR1[1][0] * LR3[0][1] + LR1[1][1] * LR3[1][1];
  
  // m3 = -r3;
  LMat^[2*4+2] := -LR3[0][0];
  LMat^[2*4+3] := -LR3[0][1];
  LMat^[3*4+2] := -LR3[1][0];
  LMat^[3*4+3] := -LR3[1][1];
  
  Result := true;
end;

end.
