{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMat5, the 5x5 matrix             }
{                                                                              }
{  Port of idMat5 (idlib\math\Matrix.h and Matrix.cpp) of the Doom 3 GPL       }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Mat5;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Vec5;

type
  /// <summary>A 5x5 matrix of Single stored by rows (idMat5), 100 bytes</summary>
  TIdMat5 = record
    Rows: array[0..4] of TIdVec5;
  public
    class function Create(const A0, A1, A2, A3, A4: TIdVec5): TIdMat5; static;
    class function Identity: TIdMat5; static;
    class operator Add(const A, B: TIdMat5): TIdMat5;
    class operator Subtract(const A, B: TIdMat5): TIdMat5;
    class operator Multiply(const A, B: TIdMat5): TIdMat5;
    class operator Multiply(const A: TIdMat5; const B: Single): TIdMat5;
    class operator Multiply(const A: Single; const B: TIdMat5): TIdMat5;
    class operator Multiply(const A: TIdMat5; const B: TIdVec5): TIdVec5;
    class operator Multiply(const A: TIdVec5; const B: TIdMat5): TIdVec5;
    class operator Equal(const A, B: TIdMat5): Boolean;
    class operator NotEqual(const A, B: TIdMat5): Boolean;
    function Compare(const A: TIdMat5; const AEpsilon: Single): Boolean;
    procedure Zero;
    procedure SetIdentity;
    function IsIdentity(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsSymmetric(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsDiagonal(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function Trace: Single;
    function Determinant: Single;
    function Transpose: TIdMat5;
    procedure TransposeSelf;
    function Inverse: TIdMat5;
    /// <summary>Inverts in place; false (and no change) if the determinant is almost zero</summary>
    function InverseSelf: Boolean;
    function InverseFast: TIdMat5;
    function InverseFastSelf: Boolean;
    function GetDimension: Integer;
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

type
  TFlat = array[0..24] of Single;
  PFlat = ^TFlat;

{ TIdMat5 }

class function TIdMat5.Create(const A0, A1, A2, A3, A4: TIdVec5): TIdMat5;
begin
  Result.Rows[0] := A0;
  Result.Rows[1] := A1;
  Result.Rows[2] := A2;
  Result.Rows[3] := A3;
  Result.Rows[4] := A4;
end;

class function TIdMat5.Identity: TIdMat5;
var
  LIndex: Integer;
begin
  Result.Zero;
  for LIndex := 0 to 4 do
  begin
    Result.Rows[LIndex][LIndex] := 1.0;
  end;
end;

class operator TIdMat5.Add(const A, B: TIdMat5): TIdMat5;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 24 do
  begin
    PFlat(@Result.Rows[0])^[LIndex] := PFlat(@A.Rows[0])^[LIndex] + PFlat(@B.Rows[0])^[LIndex];
  end;
end;

class operator TIdMat5.Subtract(const A, B: TIdMat5): TIdMat5;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 24 do
  begin
    PFlat(@Result.Rows[0])^[LIndex] := PFlat(@A.Rows[0])^[LIndex] - PFlat(@B.Rows[0])^[LIndex];
  end;
end;

class operator TIdMat5.Multiply(const A, B: TIdMat5): TIdMat5;
var
  LRow, LColumn, LK: Integer;
  LFirst, LSecond, LDestination: PFlat;
  LSum: Single;
begin
  LFirst := PFlat(@A.Rows[0]);
  LSecond := PFlat(@B.Rows[0]);
  LDestination := PFlat(@Result.Rows[0]);
  for LRow := 0 to 4 do
  begin
    for LColumn := 0 to 4 do
    begin
      LSum := LFirst^[LRow * 5] * LSecond^[LColumn];
      for LK := 1 to 4 do
      begin
        LSum := LSum + LFirst^[LRow * 5 + LK] * LSecond^[LK * 5 + LColumn];
      end;
      LDestination^[LRow * 5 + LColumn] := LSum;
    end;
  end;
end;

class operator TIdMat5.Multiply(const A: TIdMat5; const B: Single): TIdMat5;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 24 do
  begin
    PFlat(@Result.Rows[0])^[LIndex] := PFlat(@A.Rows[0])^[LIndex] * B;
  end;
end;

class operator TIdMat5.Multiply(const A: Single; const B: TIdMat5): TIdMat5;
begin
  Result := B * A;
end;

class operator TIdMat5.Multiply(const A: TIdMat5; const B: TIdVec5): TIdVec5;
var
  LRow, LColumn: Integer;
  LSum: Single;
begin
  for LRow := 0 to 4 do
  begin
    LSum := A.Rows[LRow][0] * B[0];
    for LColumn := 1 to 4 do
    begin
      LSum := LSum + A.Rows[LRow][LColumn] * B[LColumn];
    end;
    Result[LRow] := LSum;
  end;
end;

class operator TIdMat5.Multiply(const A: TIdVec5; const B: TIdMat5): TIdVec5;
begin
  Result := B * A;
end;

class operator TIdMat5.Equal(const A, B: TIdMat5): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to 24 do
  begin
    if PFlat(@A.Rows[0])^[LIndex] <> PFlat(@B.Rows[0])^[LIndex] then
    begin
      Result := False;
      Break;
    end;
  end;
end;

class operator TIdMat5.NotEqual(const A, B: TIdMat5): Boolean;
begin
  Result := not (A = B);
end;

function TIdMat5.Compare(const A: TIdMat5; const AEpsilon: Single): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to 24 do
  begin
    if TIdMath.Fabs(PFlat(@Rows[0])^[LIndex] - PFlat(@A.Rows[0])^[LIndex]) > AEpsilon then
    begin
      Result := False;
      Break;
    end;
  end;
end;

procedure TIdMat5.Zero;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 24 do
  begin
    PFlat(@Rows[0])^[LIndex] := 0.0;
  end;
end;

procedure TIdMat5.SetIdentity;
begin
  Self := Identity;
end;

function TIdMat5.IsIdentity(const AEpsilon: Single): Boolean;
begin
  Result := Compare(Identity, AEpsilon);
end;

function TIdMat5.IsSymmetric(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
begin
  Result := True;
  for LRow := 1 to 4 do
  begin
    for LColumn := 0 to LRow - 1 do
    begin
      if TIdMath.Fabs(Rows[LRow][LColumn] - Rows[LColumn][LRow]) > AEpsilon then
        Exit(False);
    end;
  end;
end;

function TIdMat5.IsDiagonal(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
begin
  Result := True;
  for LRow := 0 to 4 do
  begin
    for LColumn := 0 to 4 do
    begin
      if (LRow <> LColumn) and (TIdMath.Fabs(Rows[LRow][LColumn]) > AEpsilon) then
        Exit(False);
    end;
  end;
end;

function TIdMat5.Trace: Single;
begin
  Result := Rows[0][0] + Rows[1][1] + Rows[2][2] + Rows[3][3] + Rows[4][4];
end;

function TIdMat5.Transpose: TIdMat5;
var
  LRow, LColumn: Integer;
begin
  for LRow := 0 to 4 do
  begin
    for LColumn := 0 to 4 do
    begin
      Result.Rows[LRow][LColumn] := Rows[LColumn][LRow];
    end;
  end;
end;

procedure TIdMat5.TransposeSelf;
var
  LRow, LColumn: Integer;
  LTemp: Single;
begin
  for LRow := 0 to 4 do
  begin
    for LColumn := LRow + 1 to 4 do
    begin
      LTemp := Rows[LRow][LColumn];
      Rows[LRow][LColumn] := Rows[LColumn][LRow];
      Rows[LColumn][LRow] := LTemp;
    end;
  end;
end;

function TIdMat5.Inverse: TIdMat5;
begin
  Result := Self;
  Result.InverseSelf;
end;

function TIdMat5.InverseFast: TIdMat5;
begin
  Result := Self;
  Result.InverseFastSelf;
end;

function TIdMat5.GetDimension: Integer;
begin
  Result := 25;
end;

function TIdMat5.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString(PFlat(@Rows[0])^, APrecision);
end;

function TIdMat5.Determinant: Single;
var
  LMat: PFlat;
  LDet2_34_01, LDet2_34_02, LDet2_34_03, LDet2_34_04, LDet2_34_12, LDet2_34_13: Single;
  LDet2_34_14, LDet2_34_23, LDet2_34_24, LDet2_34_34, LDet3_234_012, LDet3_234_013: Single;
  LDet3_234_014, LDet3_234_023, LDet3_234_024, LDet3_234_034, LDet3_234_123, LDet3_234_124: Single;
  LDet3_234_134, LDet3_234_234, LDet4_1234_0123, LDet4_1234_0124, LDet4_1234_0134, LDet4_1234_0234: Single;
  LDet4_1234_1234: Single;
begin
  LMat := PFlat(@Rows[0]);
  
  // 2x2 sub-determinants required to calculate 5x5 determinant
  LDet2_34_01 := LMat^[3*5+0] * LMat^[4*5+1] - LMat^[3*5+1] * LMat^[4*5+0];
  LDet2_34_02 := LMat^[3*5+0] * LMat^[4*5+2] - LMat^[3*5+2] * LMat^[4*5+0];
  LDet2_34_03 := LMat^[3*5+0] * LMat^[4*5+3] - LMat^[3*5+3] * LMat^[4*5+0];
  LDet2_34_04 := LMat^[3*5+0] * LMat^[4*5+4] - LMat^[3*5+4] * LMat^[4*5+0];
  LDet2_34_12 := LMat^[3*5+1] * LMat^[4*5+2] - LMat^[3*5+2] * LMat^[4*5+1];
  LDet2_34_13 := LMat^[3*5+1] * LMat^[4*5+3] - LMat^[3*5+3] * LMat^[4*5+1];
  LDet2_34_14 := LMat^[3*5+1] * LMat^[4*5+4] - LMat^[3*5+4] * LMat^[4*5+1];
  LDet2_34_23 := LMat^[3*5+2] * LMat^[4*5+3] - LMat^[3*5+3] * LMat^[4*5+2];
  LDet2_34_24 := LMat^[3*5+2] * LMat^[4*5+4] - LMat^[3*5+4] * LMat^[4*5+2];
  LDet2_34_34 := LMat^[3*5+3] * LMat^[4*5+4] - LMat^[3*5+4] * LMat^[4*5+3];
  
  // 3x3 sub-determinants required to calculate 5x5 determinant
  LDet3_234_012 := LMat^[2*5+0] * LDet2_34_12 - LMat^[2*5+1] * LDet2_34_02 + LMat^[2*5+2] * LDet2_34_01;
  LDet3_234_013 := LMat^[2*5+0] * LDet2_34_13 - LMat^[2*5+1] * LDet2_34_03 + LMat^[2*5+3] * LDet2_34_01;
  LDet3_234_014 := LMat^[2*5+0] * LDet2_34_14 - LMat^[2*5+1] * LDet2_34_04 + LMat^[2*5+4] * LDet2_34_01;
  LDet3_234_023 := LMat^[2*5+0] * LDet2_34_23 - LMat^[2*5+2] * LDet2_34_03 + LMat^[2*5+3] * LDet2_34_02;
  LDet3_234_024 := LMat^[2*5+0] * LDet2_34_24 - LMat^[2*5+2] * LDet2_34_04 + LMat^[2*5+4] * LDet2_34_02;
  LDet3_234_034 := LMat^[2*5+0] * LDet2_34_34 - LMat^[2*5+3] * LDet2_34_04 + LMat^[2*5+4] * LDet2_34_03;
  LDet3_234_123 := LMat^[2*5+1] * LDet2_34_23 - LMat^[2*5+2] * LDet2_34_13 + LMat^[2*5+3] * LDet2_34_12;
  LDet3_234_124 := LMat^[2*5+1] * LDet2_34_24 - LMat^[2*5+2] * LDet2_34_14 + LMat^[2*5+4] * LDet2_34_12;
  LDet3_234_134 := LMat^[2*5+1] * LDet2_34_34 - LMat^[2*5+3] * LDet2_34_14 + LMat^[2*5+4] * LDet2_34_13;
  LDet3_234_234 := LMat^[2*5+2] * LDet2_34_34 - LMat^[2*5+3] * LDet2_34_24 + LMat^[2*5+4] * LDet2_34_23;
  
  // 4x4 sub-determinants required to calculate 5x5 determinant
  LDet4_1234_0123 := LMat^[1*5+0] * LDet3_234_123 - LMat^[1*5+1] * LDet3_234_023 + LMat^[1*5+2] * LDet3_234_013 - LMat^[1*5+3] * LDet3_234_012;
  LDet4_1234_0124 := LMat^[1*5+0] * LDet3_234_124 - LMat^[1*5+1] * LDet3_234_024 + LMat^[1*5+2] * LDet3_234_014 - LMat^[1*5+4] * LDet3_234_012;
  LDet4_1234_0134 := LMat^[1*5+0] * LDet3_234_134 - LMat^[1*5+1] * LDet3_234_034 + LMat^[1*5+3] * LDet3_234_014 - LMat^[1*5+4] * LDet3_234_013;
  LDet4_1234_0234 := LMat^[1*5+0] * LDet3_234_234 - LMat^[1*5+2] * LDet3_234_034 + LMat^[1*5+3] * LDet3_234_024 - LMat^[1*5+4] * LDet3_234_023;
  LDet4_1234_1234 := LMat^[1*5+1] * LDet3_234_234 - LMat^[1*5+2] * LDet3_234_134 + LMat^[1*5+3] * LDet3_234_124 - LMat^[1*5+4] * LDet3_234_123;
  
  // determinant of 5x5 matrix
  Result := LMat^[0*5+0] * LDet4_1234_1234 - LMat^[0*5+1] * LDet4_1234_0234 + LMat^[0*5+2] * LDet4_1234_0134 - LMat^[0*5+3] * LDet4_1234_0124 + LMat^[0*5+4] * LDet4_1234_0123;
end;

function TIdMat5.InverseSelf: Boolean;
var
  LMat: PFlat;
  LDet2_23_01, LDet2_23_02, LDet2_23_03, LDet2_23_04, LDet2_23_12, LDet2_23_13: Single;
  LDet2_23_14, LDet2_23_23, LDet2_23_24, LDet2_23_34, LDet2_24_01, LDet2_24_02: Single;
  LDet2_24_03, LDet2_24_04, LDet2_24_12, LDet2_24_13, LDet2_24_14, LDet2_24_23: Single;
  LDet2_24_24, LDet2_24_34, LDet2_34_01, LDet2_34_02, LDet2_34_03, LDet2_34_04: Single;
  LDet2_34_12, LDet2_34_13, LDet2_34_14, LDet2_34_23, LDet2_34_24, LDet2_34_34: Single;
  LDet3_123_012, LDet3_123_013, LDet3_123_014, LDet3_123_023, LDet3_123_024, LDet3_123_034: Single;
  LDet3_123_123, LDet3_123_124, LDet3_123_134, LDet3_123_234, LDet3_124_012, LDet3_124_013: Single;
  LDet3_124_014, LDet3_124_023, LDet3_124_024, LDet3_124_034, LDet3_124_123, LDet3_124_124: Single;
  LDet3_124_134, LDet3_124_234, LDet3_134_012, LDet3_134_013, LDet3_134_014, LDet3_134_023: Single;
  LDet3_134_024, LDet3_134_034, LDet3_134_123, LDet3_134_124, LDet3_134_134, LDet3_134_234: Single;
  LDet3_234_012, LDet3_234_013, LDet3_234_014, LDet3_234_023, LDet3_234_024, LDet3_234_034: Single;
  LDet3_234_123, LDet3_234_124, LDet3_234_134, LDet3_234_234, LDet4_0123_0123, LDet4_0123_0124: Single;
  LDet4_0123_0134, LDet4_0123_0234, LDet4_0123_1234, LDet4_0124_0123, LDet4_0124_0124, LDet4_0124_0134: Single;
  LDet4_0124_0234, LDet4_0124_1234, LDet4_0134_0123, LDet4_0134_0124, LDet4_0134_0134, LDet4_0134_0234: Single;
  LDet4_0134_1234, LDet4_0234_0123, LDet4_0234_0124, LDet4_0234_0134, LDet4_0234_0234, LDet4_0234_1234: Single;
  LDet4_1234_0123, LDet4_1234_0124, LDet4_1234_0134, LDet4_1234_0234, LDet4_1234_1234: Single;
  LDet, LInvDet: Double;
begin
  LMat := PFlat(@Rows[0]);
  // 280+5+25 = 310 multiplications
  //        1 division
  
  // 2x2 sub-determinants required to calculate 5x5 determinant
  LDet2_34_01 := LMat^[3*5+0] * LMat^[4*5+1] - LMat^[3*5+1] * LMat^[4*5+0];
  LDet2_34_02 := LMat^[3*5+0] * LMat^[4*5+2] - LMat^[3*5+2] * LMat^[4*5+0];
  LDet2_34_03 := LMat^[3*5+0] * LMat^[4*5+3] - LMat^[3*5+3] * LMat^[4*5+0];
  LDet2_34_04 := LMat^[3*5+0] * LMat^[4*5+4] - LMat^[3*5+4] * LMat^[4*5+0];
  LDet2_34_12 := LMat^[3*5+1] * LMat^[4*5+2] - LMat^[3*5+2] * LMat^[4*5+1];
  LDet2_34_13 := LMat^[3*5+1] * LMat^[4*5+3] - LMat^[3*5+3] * LMat^[4*5+1];
  LDet2_34_14 := LMat^[3*5+1] * LMat^[4*5+4] - LMat^[3*5+4] * LMat^[4*5+1];
  LDet2_34_23 := LMat^[3*5+2] * LMat^[4*5+3] - LMat^[3*5+3] * LMat^[4*5+2];
  LDet2_34_24 := LMat^[3*5+2] * LMat^[4*5+4] - LMat^[3*5+4] * LMat^[4*5+2];
  LDet2_34_34 := LMat^[3*5+3] * LMat^[4*5+4] - LMat^[3*5+4] * LMat^[4*5+3];
  
  // 3x3 sub-determinants required to calculate 5x5 determinant
  LDet3_234_012 := LMat^[2*5+0] * LDet2_34_12 - LMat^[2*5+1] * LDet2_34_02 + LMat^[2*5+2] * LDet2_34_01;
  LDet3_234_013 := LMat^[2*5+0] * LDet2_34_13 - LMat^[2*5+1] * LDet2_34_03 + LMat^[2*5+3] * LDet2_34_01;
  LDet3_234_014 := LMat^[2*5+0] * LDet2_34_14 - LMat^[2*5+1] * LDet2_34_04 + LMat^[2*5+4] * LDet2_34_01;
  LDet3_234_023 := LMat^[2*5+0] * LDet2_34_23 - LMat^[2*5+2] * LDet2_34_03 + LMat^[2*5+3] * LDet2_34_02;
  LDet3_234_024 := LMat^[2*5+0] * LDet2_34_24 - LMat^[2*5+2] * LDet2_34_04 + LMat^[2*5+4] * LDet2_34_02;
  LDet3_234_034 := LMat^[2*5+0] * LDet2_34_34 - LMat^[2*5+3] * LDet2_34_04 + LMat^[2*5+4] * LDet2_34_03;
  LDet3_234_123 := LMat^[2*5+1] * LDet2_34_23 - LMat^[2*5+2] * LDet2_34_13 + LMat^[2*5+3] * LDet2_34_12;
  LDet3_234_124 := LMat^[2*5+1] * LDet2_34_24 - LMat^[2*5+2] * LDet2_34_14 + LMat^[2*5+4] * LDet2_34_12;
  LDet3_234_134 := LMat^[2*5+1] * LDet2_34_34 - LMat^[2*5+3] * LDet2_34_14 + LMat^[2*5+4] * LDet2_34_13;
  LDet3_234_234 := LMat^[2*5+2] * LDet2_34_34 - LMat^[2*5+3] * LDet2_34_24 + LMat^[2*5+4] * LDet2_34_23;
  
  // 4x4 sub-determinants required to calculate 5x5 determinant
  LDet4_1234_0123 := LMat^[1*5+0] * LDet3_234_123 - LMat^[1*5+1] * LDet3_234_023 + LMat^[1*5+2] * LDet3_234_013 - LMat^[1*5+3] * LDet3_234_012;
  LDet4_1234_0124 := LMat^[1*5+0] * LDet3_234_124 - LMat^[1*5+1] * LDet3_234_024 + LMat^[1*5+2] * LDet3_234_014 - LMat^[1*5+4] * LDet3_234_012;
  LDet4_1234_0134 := LMat^[1*5+0] * LDet3_234_134 - LMat^[1*5+1] * LDet3_234_034 + LMat^[1*5+3] * LDet3_234_014 - LMat^[1*5+4] * LDet3_234_013;
  LDet4_1234_0234 := LMat^[1*5+0] * LDet3_234_234 - LMat^[1*5+2] * LDet3_234_034 + LMat^[1*5+3] * LDet3_234_024 - LMat^[1*5+4] * LDet3_234_023;
  LDet4_1234_1234 := LMat^[1*5+1] * LDet3_234_234 - LMat^[1*5+2] * LDet3_234_134 + LMat^[1*5+3] * LDet3_234_124 - LMat^[1*5+4] * LDet3_234_123;
  
  // determinant of 5x5 matrix
  LDet := LMat^[0*5+0] * LDet4_1234_1234 - LMat^[0*5+1] * LDet4_1234_0234 + LMat^[0*5+2] * LDet4_1234_0134 - LMat^[0*5+3] * LDet4_1234_0124 + LMat^[0*5+4] * LDet4_1234_0123;
  
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  
  LInvDet := 1.0 / LDet;
  
  // remaining 2x2 sub-determinants
  LDet2_23_01 := LMat^[2*5+0] * LMat^[3*5+1] - LMat^[2*5+1] * LMat^[3*5+0];
  LDet2_23_02 := LMat^[2*5+0] * LMat^[3*5+2] - LMat^[2*5+2] * LMat^[3*5+0];
  LDet2_23_03 := LMat^[2*5+0] * LMat^[3*5+3] - LMat^[2*5+3] * LMat^[3*5+0];
  LDet2_23_04 := LMat^[2*5+0] * LMat^[3*5+4] - LMat^[2*5+4] * LMat^[3*5+0];
  LDet2_23_12 := LMat^[2*5+1] * LMat^[3*5+2] - LMat^[2*5+2] * LMat^[3*5+1];
  LDet2_23_13 := LMat^[2*5+1] * LMat^[3*5+3] - LMat^[2*5+3] * LMat^[3*5+1];
  LDet2_23_14 := LMat^[2*5+1] * LMat^[3*5+4] - LMat^[2*5+4] * LMat^[3*5+1];
  LDet2_23_23 := LMat^[2*5+2] * LMat^[3*5+3] - LMat^[2*5+3] * LMat^[3*5+2];
  LDet2_23_24 := LMat^[2*5+2] * LMat^[3*5+4] - LMat^[2*5+4] * LMat^[3*5+2];
  LDet2_23_34 := LMat^[2*5+3] * LMat^[3*5+4] - LMat^[2*5+4] * LMat^[3*5+3];
  LDet2_24_01 := LMat^[2*5+0] * LMat^[4*5+1] - LMat^[2*5+1] * LMat^[4*5+0];
  LDet2_24_02 := LMat^[2*5+0] * LMat^[4*5+2] - LMat^[2*5+2] * LMat^[4*5+0];
  LDet2_24_03 := LMat^[2*5+0] * LMat^[4*5+3] - LMat^[2*5+3] * LMat^[4*5+0];
  LDet2_24_04 := LMat^[2*5+0] * LMat^[4*5+4] - LMat^[2*5+4] * LMat^[4*5+0];
  LDet2_24_12 := LMat^[2*5+1] * LMat^[4*5+2] - LMat^[2*5+2] * LMat^[4*5+1];
  LDet2_24_13 := LMat^[2*5+1] * LMat^[4*5+3] - LMat^[2*5+3] * LMat^[4*5+1];
  LDet2_24_14 := LMat^[2*5+1] * LMat^[4*5+4] - LMat^[2*5+4] * LMat^[4*5+1];
  LDet2_24_23 := LMat^[2*5+2] * LMat^[4*5+3] - LMat^[2*5+3] * LMat^[4*5+2];
  LDet2_24_24 := LMat^[2*5+2] * LMat^[4*5+4] - LMat^[2*5+4] * LMat^[4*5+2];
  LDet2_24_34 := LMat^[2*5+3] * LMat^[4*5+4] - LMat^[2*5+4] * LMat^[4*5+3];
  
  // remaining 3x3 sub-determinants
  LDet3_123_012 := LMat^[1*5+0] * LDet2_23_12 - LMat^[1*5+1] * LDet2_23_02 + LMat^[1*5+2] * LDet2_23_01;
  LDet3_123_013 := LMat^[1*5+0] * LDet2_23_13 - LMat^[1*5+1] * LDet2_23_03 + LMat^[1*5+3] * LDet2_23_01;
  LDet3_123_014 := LMat^[1*5+0] * LDet2_23_14 - LMat^[1*5+1] * LDet2_23_04 + LMat^[1*5+4] * LDet2_23_01;
  LDet3_123_023 := LMat^[1*5+0] * LDet2_23_23 - LMat^[1*5+2] * LDet2_23_03 + LMat^[1*5+3] * LDet2_23_02;
  LDet3_123_024 := LMat^[1*5+0] * LDet2_23_24 - LMat^[1*5+2] * LDet2_23_04 + LMat^[1*5+4] * LDet2_23_02;
  LDet3_123_034 := LMat^[1*5+0] * LDet2_23_34 - LMat^[1*5+3] * LDet2_23_04 + LMat^[1*5+4] * LDet2_23_03;
  LDet3_123_123 := LMat^[1*5+1] * LDet2_23_23 - LMat^[1*5+2] * LDet2_23_13 + LMat^[1*5+3] * LDet2_23_12;
  LDet3_123_124 := LMat^[1*5+1] * LDet2_23_24 - LMat^[1*5+2] * LDet2_23_14 + LMat^[1*5+4] * LDet2_23_12;
  LDet3_123_134 := LMat^[1*5+1] * LDet2_23_34 - LMat^[1*5+3] * LDet2_23_14 + LMat^[1*5+4] * LDet2_23_13;
  LDet3_123_234 := LMat^[1*5+2] * LDet2_23_34 - LMat^[1*5+3] * LDet2_23_24 + LMat^[1*5+4] * LDet2_23_23;
  LDet3_124_012 := LMat^[1*5+0] * LDet2_24_12 - LMat^[1*5+1] * LDet2_24_02 + LMat^[1*5+2] * LDet2_24_01;
  LDet3_124_013 := LMat^[1*5+0] * LDet2_24_13 - LMat^[1*5+1] * LDet2_24_03 + LMat^[1*5+3] * LDet2_24_01;
  LDet3_124_014 := LMat^[1*5+0] * LDet2_24_14 - LMat^[1*5+1] * LDet2_24_04 + LMat^[1*5+4] * LDet2_24_01;
  LDet3_124_023 := LMat^[1*5+0] * LDet2_24_23 - LMat^[1*5+2] * LDet2_24_03 + LMat^[1*5+3] * LDet2_24_02;
  LDet3_124_024 := LMat^[1*5+0] * LDet2_24_24 - LMat^[1*5+2] * LDet2_24_04 + LMat^[1*5+4] * LDet2_24_02;
  LDet3_124_034 := LMat^[1*5+0] * LDet2_24_34 - LMat^[1*5+3] * LDet2_24_04 + LMat^[1*5+4] * LDet2_24_03;
  LDet3_124_123 := LMat^[1*5+1] * LDet2_24_23 - LMat^[1*5+2] * LDet2_24_13 + LMat^[1*5+3] * LDet2_24_12;
  LDet3_124_124 := LMat^[1*5+1] * LDet2_24_24 - LMat^[1*5+2] * LDet2_24_14 + LMat^[1*5+4] * LDet2_24_12;
  LDet3_124_134 := LMat^[1*5+1] * LDet2_24_34 - LMat^[1*5+3] * LDet2_24_14 + LMat^[1*5+4] * LDet2_24_13;
  LDet3_124_234 := LMat^[1*5+2] * LDet2_24_34 - LMat^[1*5+3] * LDet2_24_24 + LMat^[1*5+4] * LDet2_24_23;
  LDet3_134_012 := LMat^[1*5+0] * LDet2_34_12 - LMat^[1*5+1] * LDet2_34_02 + LMat^[1*5+2] * LDet2_34_01;
  LDet3_134_013 := LMat^[1*5+0] * LDet2_34_13 - LMat^[1*5+1] * LDet2_34_03 + LMat^[1*5+3] * LDet2_34_01;
  LDet3_134_014 := LMat^[1*5+0] * LDet2_34_14 - LMat^[1*5+1] * LDet2_34_04 + LMat^[1*5+4] * LDet2_34_01;
  LDet3_134_023 := LMat^[1*5+0] * LDet2_34_23 - LMat^[1*5+2] * LDet2_34_03 + LMat^[1*5+3] * LDet2_34_02;
  LDet3_134_024 := LMat^[1*5+0] * LDet2_34_24 - LMat^[1*5+2] * LDet2_34_04 + LMat^[1*5+4] * LDet2_34_02;
  LDet3_134_034 := LMat^[1*5+0] * LDet2_34_34 - LMat^[1*5+3] * LDet2_34_04 + LMat^[1*5+4] * LDet2_34_03;
  LDet3_134_123 := LMat^[1*5+1] * LDet2_34_23 - LMat^[1*5+2] * LDet2_34_13 + LMat^[1*5+3] * LDet2_34_12;
  LDet3_134_124 := LMat^[1*5+1] * LDet2_34_24 - LMat^[1*5+2] * LDet2_34_14 + LMat^[1*5+4] * LDet2_34_12;
  LDet3_134_134 := LMat^[1*5+1] * LDet2_34_34 - LMat^[1*5+3] * LDet2_34_14 + LMat^[1*5+4] * LDet2_34_13;
  LDet3_134_234 := LMat^[1*5+2] * LDet2_34_34 - LMat^[1*5+3] * LDet2_34_24 + LMat^[1*5+4] * LDet2_34_23;
  
  // remaining 4x4 sub-determinants
  LDet4_0123_0123 := LMat^[0*5+0] * LDet3_123_123 - LMat^[0*5+1] * LDet3_123_023 + LMat^[0*5+2] * LDet3_123_013 - LMat^[0*5+3] * LDet3_123_012;
  LDet4_0123_0124 := LMat^[0*5+0] * LDet3_123_124 - LMat^[0*5+1] * LDet3_123_024 + LMat^[0*5+2] * LDet3_123_014 - LMat^[0*5+4] * LDet3_123_012;
  LDet4_0123_0134 := LMat^[0*5+0] * LDet3_123_134 - LMat^[0*5+1] * LDet3_123_034 + LMat^[0*5+3] * LDet3_123_014 - LMat^[0*5+4] * LDet3_123_013;
  LDet4_0123_0234 := LMat^[0*5+0] * LDet3_123_234 - LMat^[0*5+2] * LDet3_123_034 + LMat^[0*5+3] * LDet3_123_024 - LMat^[0*5+4] * LDet3_123_023;
  LDet4_0123_1234 := LMat^[0*5+1] * LDet3_123_234 - LMat^[0*5+2] * LDet3_123_134 + LMat^[0*5+3] * LDet3_123_124 - LMat^[0*5+4] * LDet3_123_123;
  LDet4_0124_0123 := LMat^[0*5+0] * LDet3_124_123 - LMat^[0*5+1] * LDet3_124_023 + LMat^[0*5+2] * LDet3_124_013 - LMat^[0*5+3] * LDet3_124_012;
  LDet4_0124_0124 := LMat^[0*5+0] * LDet3_124_124 - LMat^[0*5+1] * LDet3_124_024 + LMat^[0*5+2] * LDet3_124_014 - LMat^[0*5+4] * LDet3_124_012;
  LDet4_0124_0134 := LMat^[0*5+0] * LDet3_124_134 - LMat^[0*5+1] * LDet3_124_034 + LMat^[0*5+3] * LDet3_124_014 - LMat^[0*5+4] * LDet3_124_013;
  LDet4_0124_0234 := LMat^[0*5+0] * LDet3_124_234 - LMat^[0*5+2] * LDet3_124_034 + LMat^[0*5+3] * LDet3_124_024 - LMat^[0*5+4] * LDet3_124_023;
  LDet4_0124_1234 := LMat^[0*5+1] * LDet3_124_234 - LMat^[0*5+2] * LDet3_124_134 + LMat^[0*5+3] * LDet3_124_124 - LMat^[0*5+4] * LDet3_124_123;
  LDet4_0134_0123 := LMat^[0*5+0] * LDet3_134_123 - LMat^[0*5+1] * LDet3_134_023 + LMat^[0*5+2] * LDet3_134_013 - LMat^[0*5+3] * LDet3_134_012;
  LDet4_0134_0124 := LMat^[0*5+0] * LDet3_134_124 - LMat^[0*5+1] * LDet3_134_024 + LMat^[0*5+2] * LDet3_134_014 - LMat^[0*5+4] * LDet3_134_012;
  LDet4_0134_0134 := LMat^[0*5+0] * LDet3_134_134 - LMat^[0*5+1] * LDet3_134_034 + LMat^[0*5+3] * LDet3_134_014 - LMat^[0*5+4] * LDet3_134_013;
  LDet4_0134_0234 := LMat^[0*5+0] * LDet3_134_234 - LMat^[0*5+2] * LDet3_134_034 + LMat^[0*5+3] * LDet3_134_024 - LMat^[0*5+4] * LDet3_134_023;
  LDet4_0134_1234 := LMat^[0*5+1] * LDet3_134_234 - LMat^[0*5+2] * LDet3_134_134 + LMat^[0*5+3] * LDet3_134_124 - LMat^[0*5+4] * LDet3_134_123;
  LDet4_0234_0123 := LMat^[0*5+0] * LDet3_234_123 - LMat^[0*5+1] * LDet3_234_023 + LMat^[0*5+2] * LDet3_234_013 - LMat^[0*5+3] * LDet3_234_012;
  LDet4_0234_0124 := LMat^[0*5+0] * LDet3_234_124 - LMat^[0*5+1] * LDet3_234_024 + LMat^[0*5+2] * LDet3_234_014 - LMat^[0*5+4] * LDet3_234_012;
  LDet4_0234_0134 := LMat^[0*5+0] * LDet3_234_134 - LMat^[0*5+1] * LDet3_234_034 + LMat^[0*5+3] * LDet3_234_014 - LMat^[0*5+4] * LDet3_234_013;
  LDet4_0234_0234 := LMat^[0*5+0] * LDet3_234_234 - LMat^[0*5+2] * LDet3_234_034 + LMat^[0*5+3] * LDet3_234_024 - LMat^[0*5+4] * LDet3_234_023;
  LDet4_0234_1234 := LMat^[0*5+1] * LDet3_234_234 - LMat^[0*5+2] * LDet3_234_134 + LMat^[0*5+3] * LDet3_234_124 - LMat^[0*5+4] * LDet3_234_123;
  
  LMat^[0*5+0] := LDet4_1234_1234 * LInvDet;
  LMat^[0*5+1] := -LDet4_0234_1234 * LInvDet;
  LMat^[0*5+2] := LDet4_0134_1234 * LInvDet;
  LMat^[0*5+3] := -LDet4_0124_1234 * LInvDet;
  LMat^[0*5+4] := LDet4_0123_1234 * LInvDet;
  
  LMat^[1*5+0] := -LDet4_1234_0234 * LInvDet;
  LMat^[1*5+1] := LDet4_0234_0234 * LInvDet;
  LMat^[1*5+2] := -LDet4_0134_0234 * LInvDet;
  LMat^[1*5+3] := LDet4_0124_0234 * LInvDet;
  LMat^[1*5+4] := -LDet4_0123_0234 * LInvDet;
  
  LMat^[2*5+0] := LDet4_1234_0134 * LInvDet;
  LMat^[2*5+1] := -LDet4_0234_0134 * LInvDet;
  LMat^[2*5+2] := LDet4_0134_0134 * LInvDet;
  LMat^[2*5+3] := -LDet4_0124_0134 * LInvDet;
  LMat^[2*5+4] := LDet4_0123_0134 * LInvDet;
  
  LMat^[3*5+0] := -LDet4_1234_0124 * LInvDet;
  LMat^[3*5+1] := LDet4_0234_0124 * LInvDet;
  LMat^[3*5+2] := -LDet4_0134_0124 * LInvDet;
  LMat^[3*5+3] := LDet4_0124_0124 * LInvDet;
  LMat^[3*5+4] := -LDet4_0123_0124 * LInvDet;
  
  LMat^[4*5+0] := LDet4_1234_0123 * LInvDet;
  LMat^[4*5+1] := -LDet4_0234_0123 * LInvDet;
  LMat^[4*5+2] := LDet4_0134_0123 * LInvDet;
  LMat^[4*5+3] := -LDet4_0124_0123 * LInvDet;
  LMat^[4*5+4] := LDet4_0123_0123 * LInvDet;
  
  Result := true;
end;

function TIdMat5.InverseFastSelf: Boolean;
var
  LMat: PFlat;
  LC0, LC1, LC2, LDet, LInvDet: Single;
  LR0: array[0..2, 0..2] of Single;
  LR1: array[0..2, 0..2] of Single;
  LR2: array[0..2, 0..2] of Single;
  LR3: array[0..2, 0..2] of Single;
begin
  LMat := PFlat(@Rows[0]);
  // 86+30+6 = 122 multiplications
  //    2*1  =   2 divisions
  
  // r0 = m0.Inverse();  // 3x3
  LC0 := LMat^[1*5+1] * LMat^[2*5+2] - LMat^[1*5+2] * LMat^[2*5+1];
  LC1 := LMat^[1*5+2] * LMat^[2*5+0] - LMat^[1*5+0] * LMat^[2*5+2];
  LC2 := LMat^[1*5+0] * LMat^[2*5+1] - LMat^[1*5+1] * LMat^[2*5+0];
  
  LDet := LMat^[0*5+0] * LC0 + LMat^[0*5+1] * LC1 + LMat^[0*5+2] * LC2;
  
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  
  LInvDet := 1.0 / LDet;
  
  LR0[0][0] := LC0 * LInvDet;
  LR0[0][1] := ( LMat^[0*5+2] * LMat^[2*5+1] - LMat^[0*5+1] * LMat^[2*5+2] ) * LInvDet;
  LR0[0][2] := ( LMat^[0*5+1] * LMat^[1*5+2] - LMat^[0*5+2] * LMat^[1*5+1] ) * LInvDet;
  LR0[1][0] := LC1 * LInvDet;
  LR0[1][1] := ( LMat^[0*5+0] * LMat^[2*5+2] - LMat^[0*5+2] * LMat^[2*5+0] ) * LInvDet;
  LR0[1][2] := ( LMat^[0*5+2] * LMat^[1*5+0] - LMat^[0*5+0] * LMat^[1*5+2] ) * LInvDet;
  LR0[2][0] := LC2 * LInvDet;
  LR0[2][1] := ( LMat^[0*5+1] * LMat^[2*5+0] - LMat^[0*5+0] * LMat^[2*5+1] ) * LInvDet;
  LR0[2][2] := ( LMat^[0*5+0] * LMat^[1*5+1] - LMat^[0*5+1] * LMat^[1*5+0] ) * LInvDet;
  
  // r1 = r0 * m1;    // 3x2 = 3x3 * 3x2
  LR1[0][0] := LR0[0][0] * LMat^[0*5+3] + LR0[0][1] * LMat^[1*5+3] + LR0[0][2] * LMat^[2*5+3];
  LR1[0][1] := LR0[0][0] * LMat^[0*5+4] + LR0[0][1] * LMat^[1*5+4] + LR0[0][2] * LMat^[2*5+4];
  LR1[1][0] := LR0[1][0] * LMat^[0*5+3] + LR0[1][1] * LMat^[1*5+3] + LR0[1][2] * LMat^[2*5+3];
  LR1[1][1] := LR0[1][0] * LMat^[0*5+4] + LR0[1][1] * LMat^[1*5+4] + LR0[1][2] * LMat^[2*5+4];
  LR1[2][0] := LR0[2][0] * LMat^[0*5+3] + LR0[2][1] * LMat^[1*5+3] + LR0[2][2] * LMat^[2*5+3];
  LR1[2][1] := LR0[2][0] * LMat^[0*5+4] + LR0[2][1] * LMat^[1*5+4] + LR0[2][2] * LMat^[2*5+4];
  
  // r2 = m2 * r1;    // 2x2 = 2x3 * 3x2
  LR2[0][0] := LMat^[3*5+0] * LR1[0][0] + LMat^[3*5+1] * LR1[1][0] + LMat^[3*5+2] * LR1[2][0];
  LR2[0][1] := LMat^[3*5+0] * LR1[0][1] + LMat^[3*5+1] * LR1[1][1] + LMat^[3*5+2] * LR1[2][1];
  LR2[1][0] := LMat^[4*5+0] * LR1[0][0] + LMat^[4*5+1] * LR1[1][0] + LMat^[4*5+2] * LR1[2][0];
  LR2[1][1] := LMat^[4*5+0] * LR1[0][1] + LMat^[4*5+1] * LR1[1][1] + LMat^[4*5+2] * LR1[2][1];
  
  // r3 = r2 - m3;    // 2x2 = 2x2 - 2x2
  LR3[0][0] := LR2[0][0] - LMat^[3*5+3];
  LR3[0][1] := LR2[0][1] - LMat^[3*5+4];
  LR3[1][0] := LR2[1][0] - LMat^[4*5+3];
  LR3[1][1] := LR2[1][1] - LMat^[4*5+4];
  
  // r3.InverseSelf();  // 2x2
  LDet := LR3[0][0] * LR3[1][1] - LR3[0][1] * LR3[1][0];
  
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  
  LInvDet := 1.0 / LDet;
  
  LC0 := LR3[0][0];
  LR3[0][0] := LR3[1][1] * LInvDet;
  LR3[0][1] := - LR3[0][1] * LInvDet;
  LR3[1][0] := - LR3[1][0] * LInvDet;
  LR3[1][1] := LC0 * LInvDet;
  
  // r2 = m2 * r0;    // 2x3 = 2x3 * 3x3
  LR2[0][0] := LMat^[3*5+0] * LR0[0][0] + LMat^[3*5+1] * LR0[1][0] + LMat^[3*5+2] * LR0[2][0];
  LR2[0][1] := LMat^[3*5+0] * LR0[0][1] + LMat^[3*5+1] * LR0[1][1] + LMat^[3*5+2] * LR0[2][1];
  LR2[0][2] := LMat^[3*5+0] * LR0[0][2] + LMat^[3*5+1] * LR0[1][2] + LMat^[3*5+2] * LR0[2][2];
  LR2[1][0] := LMat^[4*5+0] * LR0[0][0] + LMat^[4*5+1] * LR0[1][0] + LMat^[4*5+2] * LR0[2][0];
  LR2[1][1] := LMat^[4*5+0] * LR0[0][1] + LMat^[4*5+1] * LR0[1][1] + LMat^[4*5+2] * LR0[2][1];
  LR2[1][2] := LMat^[4*5+0] * LR0[0][2] + LMat^[4*5+1] * LR0[1][2] + LMat^[4*5+2] * LR0[2][2];
  
  // m2 = r3 * r2;    // 2x3 = 2x2 * 2x3
  LMat^[3*5+0] := LR3[0][0] * LR2[0][0] + LR3[0][1] * LR2[1][0];
  LMat^[3*5+1] := LR3[0][0] * LR2[0][1] + LR3[0][1] * LR2[1][1];
  LMat^[3*5+2] := LR3[0][0] * LR2[0][2] + LR3[0][1] * LR2[1][2];
  LMat^[4*5+0] := LR3[1][0] * LR2[0][0] + LR3[1][1] * LR2[1][0];
  LMat^[4*5+1] := LR3[1][0] * LR2[0][1] + LR3[1][1] * LR2[1][1];
  LMat^[4*5+2] := LR3[1][0] * LR2[0][2] + LR3[1][1] * LR2[1][2];
  
  // m0 = r0 - r1 * m2;  // 3x3 = 3x3 - 3x2 * 2x3
  LMat^[0*5+0] := LR0[0][0] - LR1[0][0] * LMat^[3*5+0] - LR1[0][1] * LMat^[4*5+0];
  LMat^[0*5+1] := LR0[0][1] - LR1[0][0] * LMat^[3*5+1] - LR1[0][1] * LMat^[4*5+1];
  LMat^[0*5+2] := LR0[0][2] - LR1[0][0] * LMat^[3*5+2] - LR1[0][1] * LMat^[4*5+2];
  LMat^[1*5+0] := LR0[1][0] - LR1[1][0] * LMat^[3*5+0] - LR1[1][1] * LMat^[4*5+0];
  LMat^[1*5+1] := LR0[1][1] - LR1[1][0] * LMat^[3*5+1] - LR1[1][1] * LMat^[4*5+1];
  LMat^[1*5+2] := LR0[1][2] - LR1[1][0] * LMat^[3*5+2] - LR1[1][1] * LMat^[4*5+2];
  LMat^[2*5+0] := LR0[2][0] - LR1[2][0] * LMat^[3*5+0] - LR1[2][1] * LMat^[4*5+0];
  LMat^[2*5+1] := LR0[2][1] - LR1[2][0] * LMat^[3*5+1] - LR1[2][1] * LMat^[4*5+1];
  LMat^[2*5+2] := LR0[2][2] - LR1[2][0] * LMat^[3*5+2] - LR1[2][1] * LMat^[4*5+2];
  
  // m1 = r1 * r3;    // 3x2 = 3x2 * 2x2
  LMat^[0*5+3] := LR1[0][0] * LR3[0][0] + LR1[0][1] * LR3[1][0];
  LMat^[0*5+4] := LR1[0][0] * LR3[0][1] + LR1[0][1] * LR3[1][1];
  LMat^[1*5+3] := LR1[1][0] * LR3[0][0] + LR1[1][1] * LR3[1][0];
  LMat^[1*5+4] := LR1[1][0] * LR3[0][1] + LR1[1][1] * LR3[1][1];
  LMat^[2*5+3] := LR1[2][0] * LR3[0][0] + LR1[2][1] * LR3[1][0];
  LMat^[2*5+4] := LR1[2][0] * LR3[0][1] + LR1[2][1] * LR3[1][1];
  
  // m3 = -r3;      // 2x2 = - 2x2
  LMat^[3*5+3] := -LR3[0][0];
  LMat^[3*5+4] := -LR3[0][1];
  LMat^[4*5+3] := -LR3[1][0];
  LMat^[4*5+4] := -LR3[1][1];
  
  Result := true;
end;

end.
