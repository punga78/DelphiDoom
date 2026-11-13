{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMat6, the 6x6 matrix             }
{                                                                              }
{  Port of idMat6 (idlib\math\Matrix.h and Matrix.cpp) of the Doom 3 GPL       }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Mat6;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Vec6;

type
  /// <summary>
  ///   A 6x6 matrix of Single stored by rows (idMat6), 144 bytes: the spatial matrices of the
  ///   articulated figures, four 3x3 blocks.
  /// </summary>
  TIdMat6 = record
    Rows: array[0..5] of TIdVec6;
  public
    class function Create(const A0, A1, A2, A3, A4, A5: TIdVec6): TIdMat6; overload; static;
    /// <summary>The four 3x3 blocks (top left, top right, bottom left, bottom right)</summary>
    class function Create(const AM0, AM1, AM2, AM3: TIdMat3): TIdMat6; overload; static;
    class function Identity: TIdMat6; static;
    class operator Add(const A, B: TIdMat6): TIdMat6;
    class operator Subtract(const A, B: TIdMat6): TIdMat6;
    class operator Multiply(const A, B: TIdMat6): TIdMat6;
    class operator Multiply(const A: TIdMat6; const B: Single): TIdMat6;
    class operator Multiply(const A: Single; const B: TIdMat6): TIdMat6;
    class operator Multiply(const A: TIdMat6; const B: TIdVec6): TIdVec6;
    class operator Multiply(const A: TIdVec6; const B: TIdMat6): TIdVec6;
    class operator Equal(const A, B: TIdMat6): Boolean;
    class operator NotEqual(const A, B: TIdMat6): Boolean;
    function Compare(const A: TIdMat6; const AEpsilon: Single): Boolean;
    procedure Zero;
    procedure SetIdentity;
    function IsIdentity(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsSymmetric(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsDiagonal(const AEpsilon: Single = MAT_EPSILON): Boolean;
    /// <summary>Block n (0..3) as a 3x3 matrix</summary>
    function SubMat3(const AIndex: Integer): TIdMat3;
    function Trace: Single;
    function Determinant: Single;
    function Transpose: TIdMat6;
    procedure TransposeSelf;
    function Inverse: TIdMat6;
    /// <summary>Inverts in place; false (and no change) if the determinant is almost zero</summary>
    function InverseSelf: Boolean;
    function InverseFast: TIdMat6;
    function InverseFastSelf: Boolean;
    function GetDimension: Integer;
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

type
  TFlat = array[0..35] of Single;
  PFlat = ^TFlat;

{ TIdMat6 }

class function TIdMat6.Create(const A0, A1, A2, A3, A4, A5: TIdVec6): TIdMat6;
begin
  Result.Rows[0] := A0;
  Result.Rows[1] := A1;
  Result.Rows[2] := A2;
  Result.Rows[3] := A3;
  Result.Rows[4] := A4;
  Result.Rows[5] := A5;
end;

class function TIdMat6.Create(const AM0, AM1, AM2, AM3: TIdMat3): TIdMat6;
var
  LRow: Integer;
begin
  for LRow := 0 to 2 do
  begin
    Result.Rows[LRow].SetValues(AM0.Rows[LRow].X, AM0.Rows[LRow].Y, AM0.Rows[LRow].Z,
      AM1.Rows[LRow].X, AM1.Rows[LRow].Y, AM1.Rows[LRow].Z);
    Result.Rows[3 + LRow].SetValues(AM2.Rows[LRow].X, AM2.Rows[LRow].Y, AM2.Rows[LRow].Z,
      AM3.Rows[LRow].X, AM3.Rows[LRow].Y, AM3.Rows[LRow].Z);
  end;
end;

class function TIdMat6.Identity: TIdMat6;
var
  LIndex: Integer;
begin
  Result.Zero;
  for LIndex := 0 to 5 do
  begin
    Result.Rows[LIndex][LIndex] := 1.0;
  end;
end;

class operator TIdMat6.Add(const A, B: TIdMat6): TIdMat6;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 35 do
  begin
    PFlat(@Result.Rows[0])^[LIndex] := PFlat(@A.Rows[0])^[LIndex] + PFlat(@B.Rows[0])^[LIndex];
  end;
end;

class operator TIdMat6.Subtract(const A, B: TIdMat6): TIdMat6;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 35 do
  begin
    PFlat(@Result.Rows[0])^[LIndex] := PFlat(@A.Rows[0])^[LIndex] - PFlat(@B.Rows[0])^[LIndex];
  end;
end;

class operator TIdMat6.Multiply(const A, B: TIdMat6): TIdMat6;
var
  LRow, LColumn, LK: Integer;
  LFirst, LSecond, LDestination: PFlat;
  LSum: Single;
begin
  LFirst := PFlat(@A.Rows[0]);
  LSecond := PFlat(@B.Rows[0]);
  LDestination := PFlat(@Result.Rows[0]);
  for LRow := 0 to 5 do
  begin
    for LColumn := 0 to 5 do
    begin
      LSum := LFirst^[LRow * 6] * LSecond^[LColumn];
      for LK := 1 to 5 do
      begin
        LSum := LSum + LFirst^[LRow * 6 + LK] * LSecond^[LK * 6 + LColumn];
      end;
      LDestination^[LRow * 6 + LColumn] := LSum;
    end;
  end;
end;

class operator TIdMat6.Multiply(const A: TIdMat6; const B: Single): TIdMat6;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 35 do
  begin
    PFlat(@Result.Rows[0])^[LIndex] := PFlat(@A.Rows[0])^[LIndex] * B;
  end;
end;

class operator TIdMat6.Multiply(const A: Single; const B: TIdMat6): TIdMat6;
begin
  Result := B * A;
end;

class operator TIdMat6.Multiply(const A: TIdMat6; const B: TIdVec6): TIdVec6;
var
  LRow, LColumn: Integer;
  LSum: Single;
begin
  for LRow := 0 to 5 do
  begin
    LSum := A.Rows[LRow][0] * B[0];
    for LColumn := 1 to 5 do
    begin
      LSum := LSum + A.Rows[LRow][LColumn] * B[LColumn];
    end;
    Result[LRow] := LSum;
  end;
end;

class operator TIdMat6.Multiply(const A: TIdVec6; const B: TIdMat6): TIdVec6;
begin
  Result := B * A;
end;

class operator TIdMat6.Equal(const A, B: TIdMat6): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to 35 do
  begin
    if PFlat(@A.Rows[0])^[LIndex] <> PFlat(@B.Rows[0])^[LIndex] then
    begin
      Result := False;
      Break;
    end;
  end;
end;

class operator TIdMat6.NotEqual(const A, B: TIdMat6): Boolean;
begin
  Result := not (A = B);
end;

function TIdMat6.Compare(const A: TIdMat6; const AEpsilon: Single): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to 35 do
  begin
    if TIdMath.Fabs(PFlat(@Rows[0])^[LIndex] - PFlat(@A.Rows[0])^[LIndex]) > AEpsilon then
    begin
      Result := False;
      Break;
    end;
  end;
end;

procedure TIdMat6.Zero;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 35 do
  begin
    PFlat(@Rows[0])^[LIndex] := 0.0;
  end;
end;

procedure TIdMat6.SetIdentity;
begin
  Self := Identity;
end;

function TIdMat6.IsIdentity(const AEpsilon: Single): Boolean;
begin
  Result := Compare(Identity, AEpsilon);
end;

function TIdMat6.IsSymmetric(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
begin
  Result := True;
  for LRow := 1 to 5 do
  begin
    for LColumn := 0 to LRow - 1 do
    begin
      if TIdMath.Fabs(Rows[LRow][LColumn] - Rows[LColumn][LRow]) > AEpsilon then
        Exit(False);
    end;
  end;
end;

function TIdMat6.IsDiagonal(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
begin
  Result := True;
  for LRow := 0 to 5 do
  begin
    for LColumn := 0 to 5 do
    begin
      if (LRow <> LColumn) and (TIdMath.Fabs(Rows[LRow][LColumn]) > AEpsilon) then
        Exit(False);
    end;
  end;
end;

function TIdMat6.SubMat3(const AIndex: Integer): TIdMat3;
var
  LRowBase, LColumnBase, LRow, LColumn: Integer;
begin
  LRowBase := ((AIndex and 2) shr 1) * 3;
  LColumnBase := (AIndex and 1) * 3;
  for LRow := 0 to 2 do
  begin
    for LColumn := 0 to 2 do
    begin
      Result.Rows[LRow][LColumn] := Rows[LRowBase + LRow][LColumnBase + LColumn];
    end;
  end;
end;

function TIdMat6.Trace: Single;
begin
  Result := Rows[0][0] + Rows[1][1] + Rows[2][2] + Rows[3][3] + Rows[4][4] + Rows[5][5];
end;

function TIdMat6.Transpose: TIdMat6;
var
  LRow, LColumn: Integer;
begin
  for LRow := 0 to 5 do
  begin
    for LColumn := 0 to 5 do
    begin
      Result.Rows[LRow][LColumn] := Rows[LColumn][LRow];
    end;
  end;
end;

procedure TIdMat6.TransposeSelf;
var
  LRow, LColumn: Integer;
  LTemp: Single;
begin
  for LRow := 0 to 5 do
  begin
    for LColumn := LRow + 1 to 5 do
    begin
      LTemp := Rows[LRow][LColumn];
      Rows[LRow][LColumn] := Rows[LColumn][LRow];
      Rows[LColumn][LRow] := LTemp;
    end;
  end;
end;

function TIdMat6.Inverse: TIdMat6;
begin
  Result := Self;
  Result.InverseSelf;
end;

function TIdMat6.InverseFast: TIdMat6;
begin
  Result := Self;
  Result.InverseFastSelf;
end;

function TIdMat6.GetDimension: Integer;
begin
  Result := 36;
end;

function TIdMat6.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString(PFlat(@Rows[0])^, APrecision);
end;

function TIdMat6.Determinant: Single;
var
  LMat: PFlat;
  LDet2_45_01, LDet2_45_02, LDet2_45_03, LDet2_45_04, LDet2_45_05, LDet2_45_12: Single;
  LDet2_45_13, LDet2_45_14, LDet2_45_15, LDet2_45_23, LDet2_45_24, LDet2_45_25: Single;
  LDet2_45_34, LDet2_45_35, LDet2_45_45, LDet3_345_012, LDet3_345_013, LDet3_345_014: Single;
  LDet3_345_015, LDet3_345_023, LDet3_345_024, LDet3_345_025, LDet3_345_034, LDet3_345_035: Single;
  LDet3_345_045, LDet3_345_123, LDet3_345_124, LDet3_345_125, LDet3_345_134, LDet3_345_135: Single;
  LDet3_345_145, LDet3_345_234, LDet3_345_235, LDet3_345_245, LDet3_345_345, LDet4_2345_0123: Single;
  LDet4_2345_0124, LDet4_2345_0125, LDet4_2345_0134, LDet4_2345_0135, LDet4_2345_0145, LDet4_2345_0234: Single;
  LDet4_2345_0235, LDet4_2345_0245, LDet4_2345_0345, LDet4_2345_1234, LDet4_2345_1235, LDet4_2345_1245: Single;
  LDet4_2345_1345, LDet4_2345_2345, LDet5_12345_01234, LDet5_12345_01235, LDet5_12345_01245, LDet5_12345_01345: Single;
  LDet5_12345_02345, LDet5_12345_12345: Single;
begin
  LMat := PFlat(@Rows[0]);
  
  // 2x2 sub-determinants required to calculate 6x6 determinant
  LDet2_45_01 := LMat^[4*6+0] * LMat^[5*6+1] - LMat^[4*6+1] * LMat^[5*6+0];
  LDet2_45_02 := LMat^[4*6+0] * LMat^[5*6+2] - LMat^[4*6+2] * LMat^[5*6+0];
  LDet2_45_03 := LMat^[4*6+0] * LMat^[5*6+3] - LMat^[4*6+3] * LMat^[5*6+0];
  LDet2_45_04 := LMat^[4*6+0] * LMat^[5*6+4] - LMat^[4*6+4] * LMat^[5*6+0];
  LDet2_45_05 := LMat^[4*6+0] * LMat^[5*6+5] - LMat^[4*6+5] * LMat^[5*6+0];
  LDet2_45_12 := LMat^[4*6+1] * LMat^[5*6+2] - LMat^[4*6+2] * LMat^[5*6+1];
  LDet2_45_13 := LMat^[4*6+1] * LMat^[5*6+3] - LMat^[4*6+3] * LMat^[5*6+1];
  LDet2_45_14 := LMat^[4*6+1] * LMat^[5*6+4] - LMat^[4*6+4] * LMat^[5*6+1];
  LDet2_45_15 := LMat^[4*6+1] * LMat^[5*6+5] - LMat^[4*6+5] * LMat^[5*6+1];
  LDet2_45_23 := LMat^[4*6+2] * LMat^[5*6+3] - LMat^[4*6+3] * LMat^[5*6+2];
  LDet2_45_24 := LMat^[4*6+2] * LMat^[5*6+4] - LMat^[4*6+4] * LMat^[5*6+2];
  LDet2_45_25 := LMat^[4*6+2] * LMat^[5*6+5] - LMat^[4*6+5] * LMat^[5*6+2];
  LDet2_45_34 := LMat^[4*6+3] * LMat^[5*6+4] - LMat^[4*6+4] * LMat^[5*6+3];
  LDet2_45_35 := LMat^[4*6+3] * LMat^[5*6+5] - LMat^[4*6+5] * LMat^[5*6+3];
  LDet2_45_45 := LMat^[4*6+4] * LMat^[5*6+5] - LMat^[4*6+5] * LMat^[5*6+4];
  
  // 3x3 sub-determinants required to calculate 6x6 determinant
  LDet3_345_012 := LMat^[3*6+0] * LDet2_45_12 - LMat^[3*6+1] * LDet2_45_02 + LMat^[3*6+2] * LDet2_45_01;
  LDet3_345_013 := LMat^[3*6+0] * LDet2_45_13 - LMat^[3*6+1] * LDet2_45_03 + LMat^[3*6+3] * LDet2_45_01;
  LDet3_345_014 := LMat^[3*6+0] * LDet2_45_14 - LMat^[3*6+1] * LDet2_45_04 + LMat^[3*6+4] * LDet2_45_01;
  LDet3_345_015 := LMat^[3*6+0] * LDet2_45_15 - LMat^[3*6+1] * LDet2_45_05 + LMat^[3*6+5] * LDet2_45_01;
  LDet3_345_023 := LMat^[3*6+0] * LDet2_45_23 - LMat^[3*6+2] * LDet2_45_03 + LMat^[3*6+3] * LDet2_45_02;
  LDet3_345_024 := LMat^[3*6+0] * LDet2_45_24 - LMat^[3*6+2] * LDet2_45_04 + LMat^[3*6+4] * LDet2_45_02;
  LDet3_345_025 := LMat^[3*6+0] * LDet2_45_25 - LMat^[3*6+2] * LDet2_45_05 + LMat^[3*6+5] * LDet2_45_02;
  LDet3_345_034 := LMat^[3*6+0] * LDet2_45_34 - LMat^[3*6+3] * LDet2_45_04 + LMat^[3*6+4] * LDet2_45_03;
  LDet3_345_035 := LMat^[3*6+0] * LDet2_45_35 - LMat^[3*6+3] * LDet2_45_05 + LMat^[3*6+5] * LDet2_45_03;
  LDet3_345_045 := LMat^[3*6+0] * LDet2_45_45 - LMat^[3*6+4] * LDet2_45_05 + LMat^[3*6+5] * LDet2_45_04;
  LDet3_345_123 := LMat^[3*6+1] * LDet2_45_23 - LMat^[3*6+2] * LDet2_45_13 + LMat^[3*6+3] * LDet2_45_12;
  LDet3_345_124 := LMat^[3*6+1] * LDet2_45_24 - LMat^[3*6+2] * LDet2_45_14 + LMat^[3*6+4] * LDet2_45_12;
  LDet3_345_125 := LMat^[3*6+1] * LDet2_45_25 - LMat^[3*6+2] * LDet2_45_15 + LMat^[3*6+5] * LDet2_45_12;
  LDet3_345_134 := LMat^[3*6+1] * LDet2_45_34 - LMat^[3*6+3] * LDet2_45_14 + LMat^[3*6+4] * LDet2_45_13;
  LDet3_345_135 := LMat^[3*6+1] * LDet2_45_35 - LMat^[3*6+3] * LDet2_45_15 + LMat^[3*6+5] * LDet2_45_13;
  LDet3_345_145 := LMat^[3*6+1] * LDet2_45_45 - LMat^[3*6+4] * LDet2_45_15 + LMat^[3*6+5] * LDet2_45_14;
  LDet3_345_234 := LMat^[3*6+2] * LDet2_45_34 - LMat^[3*6+3] * LDet2_45_24 + LMat^[3*6+4] * LDet2_45_23;
  LDet3_345_235 := LMat^[3*6+2] * LDet2_45_35 - LMat^[3*6+3] * LDet2_45_25 + LMat^[3*6+5] * LDet2_45_23;
  LDet3_345_245 := LMat^[3*6+2] * LDet2_45_45 - LMat^[3*6+4] * LDet2_45_25 + LMat^[3*6+5] * LDet2_45_24;
  LDet3_345_345 := LMat^[3*6+3] * LDet2_45_45 - LMat^[3*6+4] * LDet2_45_35 + LMat^[3*6+5] * LDet2_45_34;
  
  // 4x4 sub-determinants required to calculate 6x6 determinant
  LDet4_2345_0123 := LMat^[2*6+0] * LDet3_345_123 - LMat^[2*6+1] * LDet3_345_023 + LMat^[2*6+2] * LDet3_345_013 - LMat^[2*6+3] * LDet3_345_012;
  LDet4_2345_0124 := LMat^[2*6+0] * LDet3_345_124 - LMat^[2*6+1] * LDet3_345_024 + LMat^[2*6+2] * LDet3_345_014 - LMat^[2*6+4] * LDet3_345_012;
  LDet4_2345_0125 := LMat^[2*6+0] * LDet3_345_125 - LMat^[2*6+1] * LDet3_345_025 + LMat^[2*6+2] * LDet3_345_015 - LMat^[2*6+5] * LDet3_345_012;
  LDet4_2345_0134 := LMat^[2*6+0] * LDet3_345_134 - LMat^[2*6+1] * LDet3_345_034 + LMat^[2*6+3] * LDet3_345_014 - LMat^[2*6+4] * LDet3_345_013;
  LDet4_2345_0135 := LMat^[2*6+0] * LDet3_345_135 - LMat^[2*6+1] * LDet3_345_035 + LMat^[2*6+3] * LDet3_345_015 - LMat^[2*6+5] * LDet3_345_013;
  LDet4_2345_0145 := LMat^[2*6+0] * LDet3_345_145 - LMat^[2*6+1] * LDet3_345_045 + LMat^[2*6+4] * LDet3_345_015 - LMat^[2*6+5] * LDet3_345_014;
  LDet4_2345_0234 := LMat^[2*6+0] * LDet3_345_234 - LMat^[2*6+2] * LDet3_345_034 + LMat^[2*6+3] * LDet3_345_024 - LMat^[2*6+4] * LDet3_345_023;
  LDet4_2345_0235 := LMat^[2*6+0] * LDet3_345_235 - LMat^[2*6+2] * LDet3_345_035 + LMat^[2*6+3] * LDet3_345_025 - LMat^[2*6+5] * LDet3_345_023;
  LDet4_2345_0245 := LMat^[2*6+0] * LDet3_345_245 - LMat^[2*6+2] * LDet3_345_045 + LMat^[2*6+4] * LDet3_345_025 - LMat^[2*6+5] * LDet3_345_024;
  LDet4_2345_0345 := LMat^[2*6+0] * LDet3_345_345 - LMat^[2*6+3] * LDet3_345_045 + LMat^[2*6+4] * LDet3_345_035 - LMat^[2*6+5] * LDet3_345_034;
  LDet4_2345_1234 := LMat^[2*6+1] * LDet3_345_234 - LMat^[2*6+2] * LDet3_345_134 + LMat^[2*6+3] * LDet3_345_124 - LMat^[2*6+4] * LDet3_345_123;
  LDet4_2345_1235 := LMat^[2*6+1] * LDet3_345_235 - LMat^[2*6+2] * LDet3_345_135 + LMat^[2*6+3] * LDet3_345_125 - LMat^[2*6+5] * LDet3_345_123;
  LDet4_2345_1245 := LMat^[2*6+1] * LDet3_345_245 - LMat^[2*6+2] * LDet3_345_145 + LMat^[2*6+4] * LDet3_345_125 - LMat^[2*6+5] * LDet3_345_124;
  LDet4_2345_1345 := LMat^[2*6+1] * LDet3_345_345 - LMat^[2*6+3] * LDet3_345_145 + LMat^[2*6+4] * LDet3_345_135 - LMat^[2*6+5] * LDet3_345_134;
  LDet4_2345_2345 := LMat^[2*6+2] * LDet3_345_345 - LMat^[2*6+3] * LDet3_345_245 + LMat^[2*6+4] * LDet3_345_235 - LMat^[2*6+5] * LDet3_345_234;
  
  // 5x5 sub-determinants required to calculate 6x6 determinant
  LDet5_12345_01234 := LMat^[1*6+0] * LDet4_2345_1234 - LMat^[1*6+1] * LDet4_2345_0234 + LMat^[1*6+2] * LDet4_2345_0134 - LMat^[1*6+3] * LDet4_2345_0124 + LMat^[1*6+4] * LDet4_2345_0123;
  LDet5_12345_01235 := LMat^[1*6+0] * LDet4_2345_1235 - LMat^[1*6+1] * LDet4_2345_0235 + LMat^[1*6+2] * LDet4_2345_0135 - LMat^[1*6+3] * LDet4_2345_0125 + LMat^[1*6+5] * LDet4_2345_0123;
  LDet5_12345_01245 := LMat^[1*6+0] * LDet4_2345_1245 - LMat^[1*6+1] * LDet4_2345_0245 + LMat^[1*6+2] * LDet4_2345_0145 - LMat^[1*6+4] * LDet4_2345_0125 + LMat^[1*6+5] * LDet4_2345_0124;
  LDet5_12345_01345 := LMat^[1*6+0] * LDet4_2345_1345 - LMat^[1*6+1] * LDet4_2345_0345 + LMat^[1*6+3] * LDet4_2345_0145 - LMat^[1*6+4] * LDet4_2345_0135 + LMat^[1*6+5] * LDet4_2345_0134;
  LDet5_12345_02345 := LMat^[1*6+0] * LDet4_2345_2345 - LMat^[1*6+2] * LDet4_2345_0345 + LMat^[1*6+3] * LDet4_2345_0245 - LMat^[1*6+4] * LDet4_2345_0235 + LMat^[1*6+5] * LDet4_2345_0234;
  LDet5_12345_12345 := LMat^[1*6+1] * LDet4_2345_2345 - LMat^[1*6+2] * LDet4_2345_1345 + LMat^[1*6+3] * LDet4_2345_1245 - LMat^[1*6+4] * LDet4_2345_1235 + LMat^[1*6+5] * LDet4_2345_1234;
  
  // determinant of 6x6 matrix
  Result := LMat^[0*6+0] * LDet5_12345_12345 - LMat^[0*6+1] * LDet5_12345_02345 + LMat^[0*6+2] * LDet5_12345_01345 -
      LMat^[0*6+3] * LDet5_12345_01245 + LMat^[0*6+4] * LDet5_12345_01235 - LMat^[0*6+5] * LDet5_12345_01234;
end;

function TIdMat6.InverseSelf: Boolean;
var
  LMat: PFlat;
  LDet2_34_01, LDet2_34_02, LDet2_34_03, LDet2_34_04, LDet2_34_05, LDet2_34_12: Single;
  LDet2_34_13, LDet2_34_14, LDet2_34_15, LDet2_34_23, LDet2_34_24, LDet2_34_25: Single;
  LDet2_34_34, LDet2_34_35, LDet2_34_45, LDet2_35_01, LDet2_35_02, LDet2_35_03: Single;
  LDet2_35_04, LDet2_35_05, LDet2_35_12, LDet2_35_13, LDet2_35_14, LDet2_35_15: Single;
  LDet2_35_23, LDet2_35_24, LDet2_35_25, LDet2_35_34, LDet2_35_35, LDet2_35_45: Single;
  LDet2_45_01, LDet2_45_02, LDet2_45_03, LDet2_45_04, LDet2_45_05, LDet2_45_12: Single;
  LDet2_45_13, LDet2_45_14, LDet2_45_15, LDet2_45_23, LDet2_45_24, LDet2_45_25: Single;
  LDet2_45_34, LDet2_45_35, LDet2_45_45, LDet3_234_012, LDet3_234_013, LDet3_234_014: Single;
  LDet3_234_015, LDet3_234_023, LDet3_234_024, LDet3_234_025, LDet3_234_034, LDet3_234_035: Single;
  LDet3_234_045, LDet3_234_123, LDet3_234_124, LDet3_234_125, LDet3_234_134, LDet3_234_135: Single;
  LDet3_234_145, LDet3_234_234, LDet3_234_235, LDet3_234_245, LDet3_234_345, LDet3_235_012: Single;
  LDet3_235_013, LDet3_235_014, LDet3_235_015, LDet3_235_023, LDet3_235_024, LDet3_235_025: Single;
  LDet3_235_034, LDet3_235_035, LDet3_235_045, LDet3_235_123, LDet3_235_124, LDet3_235_125: Single;
  LDet3_235_134, LDet3_235_135, LDet3_235_145, LDet3_235_234, LDet3_235_235, LDet3_235_245: Single;
  LDet3_235_345, LDet3_245_012, LDet3_245_013, LDet3_245_014, LDet3_245_015, LDet3_245_023: Single;
  LDet3_245_024, LDet3_245_025, LDet3_245_034, LDet3_245_035, LDet3_245_045, LDet3_245_123: Single;
  LDet3_245_124, LDet3_245_125, LDet3_245_134, LDet3_245_135, LDet3_245_145, LDet3_245_234: Single;
  LDet3_245_235, LDet3_245_245, LDet3_245_345, LDet3_345_012, LDet3_345_013, LDet3_345_014: Single;
  LDet3_345_015, LDet3_345_023, LDet3_345_024, LDet3_345_025, LDet3_345_034, LDet3_345_035: Single;
  LDet3_345_045, LDet3_345_123, LDet3_345_124, LDet3_345_125, LDet3_345_134, LDet3_345_135: Single;
  LDet3_345_145, LDet3_345_234, LDet3_345_235, LDet3_345_245, LDet3_345_345, LDet4_1234_0123: Single;
  LDet4_1234_0124, LDet4_1234_0125, LDet4_1234_0134, LDet4_1234_0135, LDet4_1234_0145, LDet4_1234_0234: Single;
  LDet4_1234_0235, LDet4_1234_0245, LDet4_1234_0345, LDet4_1234_1234, LDet4_1234_1235, LDet4_1234_1245: Single;
  LDet4_1234_1345, LDet4_1234_2345, LDet4_1235_0123, LDet4_1235_0124, LDet4_1235_0125, LDet4_1235_0134: Single;
  LDet4_1235_0135, LDet4_1235_0145, LDet4_1235_0234, LDet4_1235_0235, LDet4_1235_0245, LDet4_1235_0345: Single;
  LDet4_1235_1234, LDet4_1235_1235, LDet4_1235_1245, LDet4_1235_1345, LDet4_1235_2345, LDet4_1245_0123: Single;
  LDet4_1245_0124, LDet4_1245_0125, LDet4_1245_0134, LDet4_1245_0135, LDet4_1245_0145, LDet4_1245_0234: Single;
  LDet4_1245_0235, LDet4_1245_0245, LDet4_1245_0345, LDet4_1245_1234, LDet4_1245_1235, LDet4_1245_1245: Single;
  LDet4_1245_1345, LDet4_1245_2345, LDet4_1345_0123, LDet4_1345_0124, LDet4_1345_0125, LDet4_1345_0134: Single;
  LDet4_1345_0135, LDet4_1345_0145, LDet4_1345_0234, LDet4_1345_0235, LDet4_1345_0245, LDet4_1345_0345: Single;
  LDet4_1345_1234, LDet4_1345_1235, LDet4_1345_1245, LDet4_1345_1345, LDet4_1345_2345, LDet4_2345_0123: Single;
  LDet4_2345_0124, LDet4_2345_0125, LDet4_2345_0134, LDet4_2345_0135, LDet4_2345_0145, LDet4_2345_0234: Single;
  LDet4_2345_0235, LDet4_2345_0245, LDet4_2345_0345, LDet4_2345_1234, LDet4_2345_1235, LDet4_2345_1245: Single;
  LDet4_2345_1345, LDet4_2345_2345, LDet5_01234_01234, LDet5_01234_01235, LDet5_01234_01245, LDet5_01234_01345: Single;
  LDet5_01234_02345, LDet5_01234_12345, LDet5_01235_01234, LDet5_01235_01235, LDet5_01235_01245, LDet5_01235_01345: Single;
  LDet5_01235_02345, LDet5_01235_12345, LDet5_01245_01234, LDet5_01245_01235, LDet5_01245_01245, LDet5_01245_01345: Single;
  LDet5_01245_02345, LDet5_01245_12345, LDet5_01345_01234, LDet5_01345_01235, LDet5_01345_01245, LDet5_01345_01345: Single;
  LDet5_01345_02345, LDet5_01345_12345, LDet5_02345_01234, LDet5_02345_01235, LDet5_02345_01245, LDet5_02345_01345: Single;
  LDet5_02345_02345, LDet5_02345_12345, LDet5_12345_01234, LDet5_12345_01235, LDet5_12345_01245, LDet5_12345_01345: Single;
  LDet5_12345_02345, LDet5_12345_12345: Single;
  LDet, LInvDet: Double;
begin
  LMat := PFlat(@Rows[0]);
  //        1 division
  
  // 2x2 sub-determinants required to calculate 6x6 determinant
  LDet2_45_01 := LMat^[4*6+0] * LMat^[5*6+1] - LMat^[4*6+1] * LMat^[5*6+0];
  LDet2_45_02 := LMat^[4*6+0] * LMat^[5*6+2] - LMat^[4*6+2] * LMat^[5*6+0];
  LDet2_45_03 := LMat^[4*6+0] * LMat^[5*6+3] - LMat^[4*6+3] * LMat^[5*6+0];
  LDet2_45_04 := LMat^[4*6+0] * LMat^[5*6+4] - LMat^[4*6+4] * LMat^[5*6+0];
  LDet2_45_05 := LMat^[4*6+0] * LMat^[5*6+5] - LMat^[4*6+5] * LMat^[5*6+0];
  LDet2_45_12 := LMat^[4*6+1] * LMat^[5*6+2] - LMat^[4*6+2] * LMat^[5*6+1];
  LDet2_45_13 := LMat^[4*6+1] * LMat^[5*6+3] - LMat^[4*6+3] * LMat^[5*6+1];
  LDet2_45_14 := LMat^[4*6+1] * LMat^[5*6+4] - LMat^[4*6+4] * LMat^[5*6+1];
  LDet2_45_15 := LMat^[4*6+1] * LMat^[5*6+5] - LMat^[4*6+5] * LMat^[5*6+1];
  LDet2_45_23 := LMat^[4*6+2] * LMat^[5*6+3] - LMat^[4*6+3] * LMat^[5*6+2];
  LDet2_45_24 := LMat^[4*6+2] * LMat^[5*6+4] - LMat^[4*6+4] * LMat^[5*6+2];
  LDet2_45_25 := LMat^[4*6+2] * LMat^[5*6+5] - LMat^[4*6+5] * LMat^[5*6+2];
  LDet2_45_34 := LMat^[4*6+3] * LMat^[5*6+4] - LMat^[4*6+4] * LMat^[5*6+3];
  LDet2_45_35 := LMat^[4*6+3] * LMat^[5*6+5] - LMat^[4*6+5] * LMat^[5*6+3];
  LDet2_45_45 := LMat^[4*6+4] * LMat^[5*6+5] - LMat^[4*6+5] * LMat^[5*6+4];
  
  // 3x3 sub-determinants required to calculate 6x6 determinant
  LDet3_345_012 := LMat^[3*6+0] * LDet2_45_12 - LMat^[3*6+1] * LDet2_45_02 + LMat^[3*6+2] * LDet2_45_01;
  LDet3_345_013 := LMat^[3*6+0] * LDet2_45_13 - LMat^[3*6+1] * LDet2_45_03 + LMat^[3*6+3] * LDet2_45_01;
  LDet3_345_014 := LMat^[3*6+0] * LDet2_45_14 - LMat^[3*6+1] * LDet2_45_04 + LMat^[3*6+4] * LDet2_45_01;
  LDet3_345_015 := LMat^[3*6+0] * LDet2_45_15 - LMat^[3*6+1] * LDet2_45_05 + LMat^[3*6+5] * LDet2_45_01;
  LDet3_345_023 := LMat^[3*6+0] * LDet2_45_23 - LMat^[3*6+2] * LDet2_45_03 + LMat^[3*6+3] * LDet2_45_02;
  LDet3_345_024 := LMat^[3*6+0] * LDet2_45_24 - LMat^[3*6+2] * LDet2_45_04 + LMat^[3*6+4] * LDet2_45_02;
  LDet3_345_025 := LMat^[3*6+0] * LDet2_45_25 - LMat^[3*6+2] * LDet2_45_05 + LMat^[3*6+5] * LDet2_45_02;
  LDet3_345_034 := LMat^[3*6+0] * LDet2_45_34 - LMat^[3*6+3] * LDet2_45_04 + LMat^[3*6+4] * LDet2_45_03;
  LDet3_345_035 := LMat^[3*6+0] * LDet2_45_35 - LMat^[3*6+3] * LDet2_45_05 + LMat^[3*6+5] * LDet2_45_03;
  LDet3_345_045 := LMat^[3*6+0] * LDet2_45_45 - LMat^[3*6+4] * LDet2_45_05 + LMat^[3*6+5] * LDet2_45_04;
  LDet3_345_123 := LMat^[3*6+1] * LDet2_45_23 - LMat^[3*6+2] * LDet2_45_13 + LMat^[3*6+3] * LDet2_45_12;
  LDet3_345_124 := LMat^[3*6+1] * LDet2_45_24 - LMat^[3*6+2] * LDet2_45_14 + LMat^[3*6+4] * LDet2_45_12;
  LDet3_345_125 := LMat^[3*6+1] * LDet2_45_25 - LMat^[3*6+2] * LDet2_45_15 + LMat^[3*6+5] * LDet2_45_12;
  LDet3_345_134 := LMat^[3*6+1] * LDet2_45_34 - LMat^[3*6+3] * LDet2_45_14 + LMat^[3*6+4] * LDet2_45_13;
  LDet3_345_135 := LMat^[3*6+1] * LDet2_45_35 - LMat^[3*6+3] * LDet2_45_15 + LMat^[3*6+5] * LDet2_45_13;
  LDet3_345_145 := LMat^[3*6+1] * LDet2_45_45 - LMat^[3*6+4] * LDet2_45_15 + LMat^[3*6+5] * LDet2_45_14;
  LDet3_345_234 := LMat^[3*6+2] * LDet2_45_34 - LMat^[3*6+3] * LDet2_45_24 + LMat^[3*6+4] * LDet2_45_23;
  LDet3_345_235 := LMat^[3*6+2] * LDet2_45_35 - LMat^[3*6+3] * LDet2_45_25 + LMat^[3*6+5] * LDet2_45_23;
  LDet3_345_245 := LMat^[3*6+2] * LDet2_45_45 - LMat^[3*6+4] * LDet2_45_25 + LMat^[3*6+5] * LDet2_45_24;
  LDet3_345_345 := LMat^[3*6+3] * LDet2_45_45 - LMat^[3*6+4] * LDet2_45_35 + LMat^[3*6+5] * LDet2_45_34;
  
  // 4x4 sub-determinants required to calculate 6x6 determinant
  LDet4_2345_0123 := LMat^[2*6+0] * LDet3_345_123 - LMat^[2*6+1] * LDet3_345_023 + LMat^[2*6+2] * LDet3_345_013 - LMat^[2*6+3] * LDet3_345_012;
  LDet4_2345_0124 := LMat^[2*6+0] * LDet3_345_124 - LMat^[2*6+1] * LDet3_345_024 + LMat^[2*6+2] * LDet3_345_014 - LMat^[2*6+4] * LDet3_345_012;
  LDet4_2345_0125 := LMat^[2*6+0] * LDet3_345_125 - LMat^[2*6+1] * LDet3_345_025 + LMat^[2*6+2] * LDet3_345_015 - LMat^[2*6+5] * LDet3_345_012;
  LDet4_2345_0134 := LMat^[2*6+0] * LDet3_345_134 - LMat^[2*6+1] * LDet3_345_034 + LMat^[2*6+3] * LDet3_345_014 - LMat^[2*6+4] * LDet3_345_013;
  LDet4_2345_0135 := LMat^[2*6+0] * LDet3_345_135 - LMat^[2*6+1] * LDet3_345_035 + LMat^[2*6+3] * LDet3_345_015 - LMat^[2*6+5] * LDet3_345_013;
  LDet4_2345_0145 := LMat^[2*6+0] * LDet3_345_145 - LMat^[2*6+1] * LDet3_345_045 + LMat^[2*6+4] * LDet3_345_015 - LMat^[2*6+5] * LDet3_345_014;
  LDet4_2345_0234 := LMat^[2*6+0] * LDet3_345_234 - LMat^[2*6+2] * LDet3_345_034 + LMat^[2*6+3] * LDet3_345_024 - LMat^[2*6+4] * LDet3_345_023;
  LDet4_2345_0235 := LMat^[2*6+0] * LDet3_345_235 - LMat^[2*6+2] * LDet3_345_035 + LMat^[2*6+3] * LDet3_345_025 - LMat^[2*6+5] * LDet3_345_023;
  LDet4_2345_0245 := LMat^[2*6+0] * LDet3_345_245 - LMat^[2*6+2] * LDet3_345_045 + LMat^[2*6+4] * LDet3_345_025 - LMat^[2*6+5] * LDet3_345_024;
  LDet4_2345_0345 := LMat^[2*6+0] * LDet3_345_345 - LMat^[2*6+3] * LDet3_345_045 + LMat^[2*6+4] * LDet3_345_035 - LMat^[2*6+5] * LDet3_345_034;
  LDet4_2345_1234 := LMat^[2*6+1] * LDet3_345_234 - LMat^[2*6+2] * LDet3_345_134 + LMat^[2*6+3] * LDet3_345_124 - LMat^[2*6+4] * LDet3_345_123;
  LDet4_2345_1235 := LMat^[2*6+1] * LDet3_345_235 - LMat^[2*6+2] * LDet3_345_135 + LMat^[2*6+3] * LDet3_345_125 - LMat^[2*6+5] * LDet3_345_123;
  LDet4_2345_1245 := LMat^[2*6+1] * LDet3_345_245 - LMat^[2*6+2] * LDet3_345_145 + LMat^[2*6+4] * LDet3_345_125 - LMat^[2*6+5] * LDet3_345_124;
  LDet4_2345_1345 := LMat^[2*6+1] * LDet3_345_345 - LMat^[2*6+3] * LDet3_345_145 + LMat^[2*6+4] * LDet3_345_135 - LMat^[2*6+5] * LDet3_345_134;
  LDet4_2345_2345 := LMat^[2*6+2] * LDet3_345_345 - LMat^[2*6+3] * LDet3_345_245 + LMat^[2*6+4] * LDet3_345_235 - LMat^[2*6+5] * LDet3_345_234;
  
  // 5x5 sub-determinants required to calculate 6x6 determinant
  LDet5_12345_01234 := LMat^[1*6+0] * LDet4_2345_1234 - LMat^[1*6+1] * LDet4_2345_0234 + LMat^[1*6+2] * LDet4_2345_0134 - LMat^[1*6+3] * LDet4_2345_0124 + LMat^[1*6+4] * LDet4_2345_0123;
  LDet5_12345_01235 := LMat^[1*6+0] * LDet4_2345_1235 - LMat^[1*6+1] * LDet4_2345_0235 + LMat^[1*6+2] * LDet4_2345_0135 - LMat^[1*6+3] * LDet4_2345_0125 + LMat^[1*6+5] * LDet4_2345_0123;
  LDet5_12345_01245 := LMat^[1*6+0] * LDet4_2345_1245 - LMat^[1*6+1] * LDet4_2345_0245 + LMat^[1*6+2] * LDet4_2345_0145 - LMat^[1*6+4] * LDet4_2345_0125 + LMat^[1*6+5] * LDet4_2345_0124;
  LDet5_12345_01345 := LMat^[1*6+0] * LDet4_2345_1345 - LMat^[1*6+1] * LDet4_2345_0345 + LMat^[1*6+3] * LDet4_2345_0145 - LMat^[1*6+4] * LDet4_2345_0135 + LMat^[1*6+5] * LDet4_2345_0134;
  LDet5_12345_02345 := LMat^[1*6+0] * LDet4_2345_2345 - LMat^[1*6+2] * LDet4_2345_0345 + LMat^[1*6+3] * LDet4_2345_0245 - LMat^[1*6+4] * LDet4_2345_0235 + LMat^[1*6+5] * LDet4_2345_0234;
  LDet5_12345_12345 := LMat^[1*6+1] * LDet4_2345_2345 - LMat^[1*6+2] * LDet4_2345_1345 + LMat^[1*6+3] * LDet4_2345_1245 - LMat^[1*6+4] * LDet4_2345_1235 + LMat^[1*6+5] * LDet4_2345_1234;
  
  // determinant of 6x6 matrix
  LDet := LMat^[0*6+0] * LDet5_12345_12345 - LMat^[0*6+1] * LDet5_12345_02345 + LMat^[0*6+2] * LDet5_12345_01345 -
        LMat^[0*6+3] * LDet5_12345_01245 + LMat^[0*6+4] * LDet5_12345_01235 - LMat^[0*6+5] * LDet5_12345_01234;
  
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  
  LInvDet := 1.0 / LDet;
  
  // remaining 2x2 sub-determinants
  LDet2_34_01 := LMat^[3*6+0] * LMat^[4*6+1] - LMat^[3*6+1] * LMat^[4*6+0];
  LDet2_34_02 := LMat^[3*6+0] * LMat^[4*6+2] - LMat^[3*6+2] * LMat^[4*6+0];
  LDet2_34_03 := LMat^[3*6+0] * LMat^[4*6+3] - LMat^[3*6+3] * LMat^[4*6+0];
  LDet2_34_04 := LMat^[3*6+0] * LMat^[4*6+4] - LMat^[3*6+4] * LMat^[4*6+0];
  LDet2_34_05 := LMat^[3*6+0] * LMat^[4*6+5] - LMat^[3*6+5] * LMat^[4*6+0];
  LDet2_34_12 := LMat^[3*6+1] * LMat^[4*6+2] - LMat^[3*6+2] * LMat^[4*6+1];
  LDet2_34_13 := LMat^[3*6+1] * LMat^[4*6+3] - LMat^[3*6+3] * LMat^[4*6+1];
  LDet2_34_14 := LMat^[3*6+1] * LMat^[4*6+4] - LMat^[3*6+4] * LMat^[4*6+1];
  LDet2_34_15 := LMat^[3*6+1] * LMat^[4*6+5] - LMat^[3*6+5] * LMat^[4*6+1];
  LDet2_34_23 := LMat^[3*6+2] * LMat^[4*6+3] - LMat^[3*6+3] * LMat^[4*6+2];
  LDet2_34_24 := LMat^[3*6+2] * LMat^[4*6+4] - LMat^[3*6+4] * LMat^[4*6+2];
  LDet2_34_25 := LMat^[3*6+2] * LMat^[4*6+5] - LMat^[3*6+5] * LMat^[4*6+2];
  LDet2_34_34 := LMat^[3*6+3] * LMat^[4*6+4] - LMat^[3*6+4] * LMat^[4*6+3];
  LDet2_34_35 := LMat^[3*6+3] * LMat^[4*6+5] - LMat^[3*6+5] * LMat^[4*6+3];
  LDet2_34_45 := LMat^[3*6+4] * LMat^[4*6+5] - LMat^[3*6+5] * LMat^[4*6+4];
  LDet2_35_01 := LMat^[3*6+0] * LMat^[5*6+1] - LMat^[3*6+1] * LMat^[5*6+0];
  LDet2_35_02 := LMat^[3*6+0] * LMat^[5*6+2] - LMat^[3*6+2] * LMat^[5*6+0];
  LDet2_35_03 := LMat^[3*6+0] * LMat^[5*6+3] - LMat^[3*6+3] * LMat^[5*6+0];
  LDet2_35_04 := LMat^[3*6+0] * LMat^[5*6+4] - LMat^[3*6+4] * LMat^[5*6+0];
  LDet2_35_05 := LMat^[3*6+0] * LMat^[5*6+5] - LMat^[3*6+5] * LMat^[5*6+0];
  LDet2_35_12 := LMat^[3*6+1] * LMat^[5*6+2] - LMat^[3*6+2] * LMat^[5*6+1];
  LDet2_35_13 := LMat^[3*6+1] * LMat^[5*6+3] - LMat^[3*6+3] * LMat^[5*6+1];
  LDet2_35_14 := LMat^[3*6+1] * LMat^[5*6+4] - LMat^[3*6+4] * LMat^[5*6+1];
  LDet2_35_15 := LMat^[3*6+1] * LMat^[5*6+5] - LMat^[3*6+5] * LMat^[5*6+1];
  LDet2_35_23 := LMat^[3*6+2] * LMat^[5*6+3] - LMat^[3*6+3] * LMat^[5*6+2];
  LDet2_35_24 := LMat^[3*6+2] * LMat^[5*6+4] - LMat^[3*6+4] * LMat^[5*6+2];
  LDet2_35_25 := LMat^[3*6+2] * LMat^[5*6+5] - LMat^[3*6+5] * LMat^[5*6+2];
  LDet2_35_34 := LMat^[3*6+3] * LMat^[5*6+4] - LMat^[3*6+4] * LMat^[5*6+3];
  LDet2_35_35 := LMat^[3*6+3] * LMat^[5*6+5] - LMat^[3*6+5] * LMat^[5*6+3];
  LDet2_35_45 := LMat^[3*6+4] * LMat^[5*6+5] - LMat^[3*6+5] * LMat^[5*6+4];
  
  // remaining 3x3 sub-determinants
  LDet3_234_012 := LMat^[2*6+0] * LDet2_34_12 - LMat^[2*6+1] * LDet2_34_02 + LMat^[2*6+2] * LDet2_34_01;
  LDet3_234_013 := LMat^[2*6+0] * LDet2_34_13 - LMat^[2*6+1] * LDet2_34_03 + LMat^[2*6+3] * LDet2_34_01;
  LDet3_234_014 := LMat^[2*6+0] * LDet2_34_14 - LMat^[2*6+1] * LDet2_34_04 + LMat^[2*6+4] * LDet2_34_01;
  LDet3_234_015 := LMat^[2*6+0] * LDet2_34_15 - LMat^[2*6+1] * LDet2_34_05 + LMat^[2*6+5] * LDet2_34_01;
  LDet3_234_023 := LMat^[2*6+0] * LDet2_34_23 - LMat^[2*6+2] * LDet2_34_03 + LMat^[2*6+3] * LDet2_34_02;
  LDet3_234_024 := LMat^[2*6+0] * LDet2_34_24 - LMat^[2*6+2] * LDet2_34_04 + LMat^[2*6+4] * LDet2_34_02;
  LDet3_234_025 := LMat^[2*6+0] * LDet2_34_25 - LMat^[2*6+2] * LDet2_34_05 + LMat^[2*6+5] * LDet2_34_02;
  LDet3_234_034 := LMat^[2*6+0] * LDet2_34_34 - LMat^[2*6+3] * LDet2_34_04 + LMat^[2*6+4] * LDet2_34_03;
  LDet3_234_035 := LMat^[2*6+0] * LDet2_34_35 - LMat^[2*6+3] * LDet2_34_05 + LMat^[2*6+5] * LDet2_34_03;
  LDet3_234_045 := LMat^[2*6+0] * LDet2_34_45 - LMat^[2*6+4] * LDet2_34_05 + LMat^[2*6+5] * LDet2_34_04;
  LDet3_234_123 := LMat^[2*6+1] * LDet2_34_23 - LMat^[2*6+2] * LDet2_34_13 + LMat^[2*6+3] * LDet2_34_12;
  LDet3_234_124 := LMat^[2*6+1] * LDet2_34_24 - LMat^[2*6+2] * LDet2_34_14 + LMat^[2*6+4] * LDet2_34_12;
  LDet3_234_125 := LMat^[2*6+1] * LDet2_34_25 - LMat^[2*6+2] * LDet2_34_15 + LMat^[2*6+5] * LDet2_34_12;
  LDet3_234_134 := LMat^[2*6+1] * LDet2_34_34 - LMat^[2*6+3] * LDet2_34_14 + LMat^[2*6+4] * LDet2_34_13;
  LDet3_234_135 := LMat^[2*6+1] * LDet2_34_35 - LMat^[2*6+3] * LDet2_34_15 + LMat^[2*6+5] * LDet2_34_13;
  LDet3_234_145 := LMat^[2*6+1] * LDet2_34_45 - LMat^[2*6+4] * LDet2_34_15 + LMat^[2*6+5] * LDet2_34_14;
  LDet3_234_234 := LMat^[2*6+2] * LDet2_34_34 - LMat^[2*6+3] * LDet2_34_24 + LMat^[2*6+4] * LDet2_34_23;
  LDet3_234_235 := LMat^[2*6+2] * LDet2_34_35 - LMat^[2*6+3] * LDet2_34_25 + LMat^[2*6+5] * LDet2_34_23;
  LDet3_234_245 := LMat^[2*6+2] * LDet2_34_45 - LMat^[2*6+4] * LDet2_34_25 + LMat^[2*6+5] * LDet2_34_24;
  LDet3_234_345 := LMat^[2*6+3] * LDet2_34_45 - LMat^[2*6+4] * LDet2_34_35 + LMat^[2*6+5] * LDet2_34_34;
  LDet3_235_012 := LMat^[2*6+0] * LDet2_35_12 - LMat^[2*6+1] * LDet2_35_02 + LMat^[2*6+2] * LDet2_35_01;
  LDet3_235_013 := LMat^[2*6+0] * LDet2_35_13 - LMat^[2*6+1] * LDet2_35_03 + LMat^[2*6+3] * LDet2_35_01;
  LDet3_235_014 := LMat^[2*6+0] * LDet2_35_14 - LMat^[2*6+1] * LDet2_35_04 + LMat^[2*6+4] * LDet2_35_01;
  LDet3_235_015 := LMat^[2*6+0] * LDet2_35_15 - LMat^[2*6+1] * LDet2_35_05 + LMat^[2*6+5] * LDet2_35_01;
  LDet3_235_023 := LMat^[2*6+0] * LDet2_35_23 - LMat^[2*6+2] * LDet2_35_03 + LMat^[2*6+3] * LDet2_35_02;
  LDet3_235_024 := LMat^[2*6+0] * LDet2_35_24 - LMat^[2*6+2] * LDet2_35_04 + LMat^[2*6+4] * LDet2_35_02;
  LDet3_235_025 := LMat^[2*6+0] * LDet2_35_25 - LMat^[2*6+2] * LDet2_35_05 + LMat^[2*6+5] * LDet2_35_02;
  LDet3_235_034 := LMat^[2*6+0] * LDet2_35_34 - LMat^[2*6+3] * LDet2_35_04 + LMat^[2*6+4] * LDet2_35_03;
  LDet3_235_035 := LMat^[2*6+0] * LDet2_35_35 - LMat^[2*6+3] * LDet2_35_05 + LMat^[2*6+5] * LDet2_35_03;
  LDet3_235_045 := LMat^[2*6+0] * LDet2_35_45 - LMat^[2*6+4] * LDet2_35_05 + LMat^[2*6+5] * LDet2_35_04;
  LDet3_235_123 := LMat^[2*6+1] * LDet2_35_23 - LMat^[2*6+2] * LDet2_35_13 + LMat^[2*6+3] * LDet2_35_12;
  LDet3_235_124 := LMat^[2*6+1] * LDet2_35_24 - LMat^[2*6+2] * LDet2_35_14 + LMat^[2*6+4] * LDet2_35_12;
  LDet3_235_125 := LMat^[2*6+1] * LDet2_35_25 - LMat^[2*6+2] * LDet2_35_15 + LMat^[2*6+5] * LDet2_35_12;
  LDet3_235_134 := LMat^[2*6+1] * LDet2_35_34 - LMat^[2*6+3] * LDet2_35_14 + LMat^[2*6+4] * LDet2_35_13;
  LDet3_235_135 := LMat^[2*6+1] * LDet2_35_35 - LMat^[2*6+3] * LDet2_35_15 + LMat^[2*6+5] * LDet2_35_13;
  LDet3_235_145 := LMat^[2*6+1] * LDet2_35_45 - LMat^[2*6+4] * LDet2_35_15 + LMat^[2*6+5] * LDet2_35_14;
  LDet3_235_234 := LMat^[2*6+2] * LDet2_35_34 - LMat^[2*6+3] * LDet2_35_24 + LMat^[2*6+4] * LDet2_35_23;
  LDet3_235_235 := LMat^[2*6+2] * LDet2_35_35 - LMat^[2*6+3] * LDet2_35_25 + LMat^[2*6+5] * LDet2_35_23;
  LDet3_235_245 := LMat^[2*6+2] * LDet2_35_45 - LMat^[2*6+4] * LDet2_35_25 + LMat^[2*6+5] * LDet2_35_24;
  LDet3_235_345 := LMat^[2*6+3] * LDet2_35_45 - LMat^[2*6+4] * LDet2_35_35 + LMat^[2*6+5] * LDet2_35_34;
  LDet3_245_012 := LMat^[2*6+0] * LDet2_45_12 - LMat^[2*6+1] * LDet2_45_02 + LMat^[2*6+2] * LDet2_45_01;
  LDet3_245_013 := LMat^[2*6+0] * LDet2_45_13 - LMat^[2*6+1] * LDet2_45_03 + LMat^[2*6+3] * LDet2_45_01;
  LDet3_245_014 := LMat^[2*6+0] * LDet2_45_14 - LMat^[2*6+1] * LDet2_45_04 + LMat^[2*6+4] * LDet2_45_01;
  LDet3_245_015 := LMat^[2*6+0] * LDet2_45_15 - LMat^[2*6+1] * LDet2_45_05 + LMat^[2*6+5] * LDet2_45_01;
  LDet3_245_023 := LMat^[2*6+0] * LDet2_45_23 - LMat^[2*6+2] * LDet2_45_03 + LMat^[2*6+3] * LDet2_45_02;
  LDet3_245_024 := LMat^[2*6+0] * LDet2_45_24 - LMat^[2*6+2] * LDet2_45_04 + LMat^[2*6+4] * LDet2_45_02;
  LDet3_245_025 := LMat^[2*6+0] * LDet2_45_25 - LMat^[2*6+2] * LDet2_45_05 + LMat^[2*6+5] * LDet2_45_02;
  LDet3_245_034 := LMat^[2*6+0] * LDet2_45_34 - LMat^[2*6+3] * LDet2_45_04 + LMat^[2*6+4] * LDet2_45_03;
  LDet3_245_035 := LMat^[2*6+0] * LDet2_45_35 - LMat^[2*6+3] * LDet2_45_05 + LMat^[2*6+5] * LDet2_45_03;
  LDet3_245_045 := LMat^[2*6+0] * LDet2_45_45 - LMat^[2*6+4] * LDet2_45_05 + LMat^[2*6+5] * LDet2_45_04;
  LDet3_245_123 := LMat^[2*6+1] * LDet2_45_23 - LMat^[2*6+2] * LDet2_45_13 + LMat^[2*6+3] * LDet2_45_12;
  LDet3_245_124 := LMat^[2*6+1] * LDet2_45_24 - LMat^[2*6+2] * LDet2_45_14 + LMat^[2*6+4] * LDet2_45_12;
  LDet3_245_125 := LMat^[2*6+1] * LDet2_45_25 - LMat^[2*6+2] * LDet2_45_15 + LMat^[2*6+5] * LDet2_45_12;
  LDet3_245_134 := LMat^[2*6+1] * LDet2_45_34 - LMat^[2*6+3] * LDet2_45_14 + LMat^[2*6+4] * LDet2_45_13;
  LDet3_245_135 := LMat^[2*6+1] * LDet2_45_35 - LMat^[2*6+3] * LDet2_45_15 + LMat^[2*6+5] * LDet2_45_13;
  LDet3_245_145 := LMat^[2*6+1] * LDet2_45_45 - LMat^[2*6+4] * LDet2_45_15 + LMat^[2*6+5] * LDet2_45_14;
  LDet3_245_234 := LMat^[2*6+2] * LDet2_45_34 - LMat^[2*6+3] * LDet2_45_24 + LMat^[2*6+4] * LDet2_45_23;
  LDet3_245_235 := LMat^[2*6+2] * LDet2_45_35 - LMat^[2*6+3] * LDet2_45_25 + LMat^[2*6+5] * LDet2_45_23;
  LDet3_245_245 := LMat^[2*6+2] * LDet2_45_45 - LMat^[2*6+4] * LDet2_45_25 + LMat^[2*6+5] * LDet2_45_24;
  LDet3_245_345 := LMat^[2*6+3] * LDet2_45_45 - LMat^[2*6+4] * LDet2_45_35 + LMat^[2*6+5] * LDet2_45_34;
  
  // remaining 4x4 sub-determinants
  LDet4_1234_0123 := LMat^[1*6+0] * LDet3_234_123 - LMat^[1*6+1] * LDet3_234_023 + LMat^[1*6+2] * LDet3_234_013 - LMat^[1*6+3] * LDet3_234_012;
  LDet4_1234_0124 := LMat^[1*6+0] * LDet3_234_124 - LMat^[1*6+1] * LDet3_234_024 + LMat^[1*6+2] * LDet3_234_014 - LMat^[1*6+4] * LDet3_234_012;
  LDet4_1234_0125 := LMat^[1*6+0] * LDet3_234_125 - LMat^[1*6+1] * LDet3_234_025 + LMat^[1*6+2] * LDet3_234_015 - LMat^[1*6+5] * LDet3_234_012;
  LDet4_1234_0134 := LMat^[1*6+0] * LDet3_234_134 - LMat^[1*6+1] * LDet3_234_034 + LMat^[1*6+3] * LDet3_234_014 - LMat^[1*6+4] * LDet3_234_013;
  LDet4_1234_0135 := LMat^[1*6+0] * LDet3_234_135 - LMat^[1*6+1] * LDet3_234_035 + LMat^[1*6+3] * LDet3_234_015 - LMat^[1*6+5] * LDet3_234_013;
  LDet4_1234_0145 := LMat^[1*6+0] * LDet3_234_145 - LMat^[1*6+1] * LDet3_234_045 + LMat^[1*6+4] * LDet3_234_015 - LMat^[1*6+5] * LDet3_234_014;
  LDet4_1234_0234 := LMat^[1*6+0] * LDet3_234_234 - LMat^[1*6+2] * LDet3_234_034 + LMat^[1*6+3] * LDet3_234_024 - LMat^[1*6+4] * LDet3_234_023;
  LDet4_1234_0235 := LMat^[1*6+0] * LDet3_234_235 - LMat^[1*6+2] * LDet3_234_035 + LMat^[1*6+3] * LDet3_234_025 - LMat^[1*6+5] * LDet3_234_023;
  LDet4_1234_0245 := LMat^[1*6+0] * LDet3_234_245 - LMat^[1*6+2] * LDet3_234_045 + LMat^[1*6+4] * LDet3_234_025 - LMat^[1*6+5] * LDet3_234_024;
  LDet4_1234_0345 := LMat^[1*6+0] * LDet3_234_345 - LMat^[1*6+3] * LDet3_234_045 + LMat^[1*6+4] * LDet3_234_035 - LMat^[1*6+5] * LDet3_234_034;
  LDet4_1234_1234 := LMat^[1*6+1] * LDet3_234_234 - LMat^[1*6+2] * LDet3_234_134 + LMat^[1*6+3] * LDet3_234_124 - LMat^[1*6+4] * LDet3_234_123;
  LDet4_1234_1235 := LMat^[1*6+1] * LDet3_234_235 - LMat^[1*6+2] * LDet3_234_135 + LMat^[1*6+3] * LDet3_234_125 - LMat^[1*6+5] * LDet3_234_123;
  LDet4_1234_1245 := LMat^[1*6+1] * LDet3_234_245 - LMat^[1*6+2] * LDet3_234_145 + LMat^[1*6+4] * LDet3_234_125 - LMat^[1*6+5] * LDet3_234_124;
  LDet4_1234_1345 := LMat^[1*6+1] * LDet3_234_345 - LMat^[1*6+3] * LDet3_234_145 + LMat^[1*6+4] * LDet3_234_135 - LMat^[1*6+5] * LDet3_234_134;
  LDet4_1234_2345 := LMat^[1*6+2] * LDet3_234_345 - LMat^[1*6+3] * LDet3_234_245 + LMat^[1*6+4] * LDet3_234_235 - LMat^[1*6+5] * LDet3_234_234;
  LDet4_1235_0123 := LMat^[1*6+0] * LDet3_235_123 - LMat^[1*6+1] * LDet3_235_023 + LMat^[1*6+2] * LDet3_235_013 - LMat^[1*6+3] * LDet3_235_012;
  LDet4_1235_0124 := LMat^[1*6+0] * LDet3_235_124 - LMat^[1*6+1] * LDet3_235_024 + LMat^[1*6+2] * LDet3_235_014 - LMat^[1*6+4] * LDet3_235_012;
  LDet4_1235_0125 := LMat^[1*6+0] * LDet3_235_125 - LMat^[1*6+1] * LDet3_235_025 + LMat^[1*6+2] * LDet3_235_015 - LMat^[1*6+5] * LDet3_235_012;
  LDet4_1235_0134 := LMat^[1*6+0] * LDet3_235_134 - LMat^[1*6+1] * LDet3_235_034 + LMat^[1*6+3] * LDet3_235_014 - LMat^[1*6+4] * LDet3_235_013;
  LDet4_1235_0135 := LMat^[1*6+0] * LDet3_235_135 - LMat^[1*6+1] * LDet3_235_035 + LMat^[1*6+3] * LDet3_235_015 - LMat^[1*6+5] * LDet3_235_013;
  LDet4_1235_0145 := LMat^[1*6+0] * LDet3_235_145 - LMat^[1*6+1] * LDet3_235_045 + LMat^[1*6+4] * LDet3_235_015 - LMat^[1*6+5] * LDet3_235_014;
  LDet4_1235_0234 := LMat^[1*6+0] * LDet3_235_234 - LMat^[1*6+2] * LDet3_235_034 + LMat^[1*6+3] * LDet3_235_024 - LMat^[1*6+4] * LDet3_235_023;
  LDet4_1235_0235 := LMat^[1*6+0] * LDet3_235_235 - LMat^[1*6+2] * LDet3_235_035 + LMat^[1*6+3] * LDet3_235_025 - LMat^[1*6+5] * LDet3_235_023;
  LDet4_1235_0245 := LMat^[1*6+0] * LDet3_235_245 - LMat^[1*6+2] * LDet3_235_045 + LMat^[1*6+4] * LDet3_235_025 - LMat^[1*6+5] * LDet3_235_024;
  LDet4_1235_0345 := LMat^[1*6+0] * LDet3_235_345 - LMat^[1*6+3] * LDet3_235_045 + LMat^[1*6+4] * LDet3_235_035 - LMat^[1*6+5] * LDet3_235_034;
  LDet4_1235_1234 := LMat^[1*6+1] * LDet3_235_234 - LMat^[1*6+2] * LDet3_235_134 + LMat^[1*6+3] * LDet3_235_124 - LMat^[1*6+4] * LDet3_235_123;
  LDet4_1235_1235 := LMat^[1*6+1] * LDet3_235_235 - LMat^[1*6+2] * LDet3_235_135 + LMat^[1*6+3] * LDet3_235_125 - LMat^[1*6+5] * LDet3_235_123;
  LDet4_1235_1245 := LMat^[1*6+1] * LDet3_235_245 - LMat^[1*6+2] * LDet3_235_145 + LMat^[1*6+4] * LDet3_235_125 - LMat^[1*6+5] * LDet3_235_124;
  LDet4_1235_1345 := LMat^[1*6+1] * LDet3_235_345 - LMat^[1*6+3] * LDet3_235_145 + LMat^[1*6+4] * LDet3_235_135 - LMat^[1*6+5] * LDet3_235_134;
  LDet4_1235_2345 := LMat^[1*6+2] * LDet3_235_345 - LMat^[1*6+3] * LDet3_235_245 + LMat^[1*6+4] * LDet3_235_235 - LMat^[1*6+5] * LDet3_235_234;
  LDet4_1245_0123 := LMat^[1*6+0] * LDet3_245_123 - LMat^[1*6+1] * LDet3_245_023 + LMat^[1*6+2] * LDet3_245_013 - LMat^[1*6+3] * LDet3_245_012;
  LDet4_1245_0124 := LMat^[1*6+0] * LDet3_245_124 - LMat^[1*6+1] * LDet3_245_024 + LMat^[1*6+2] * LDet3_245_014 - LMat^[1*6+4] * LDet3_245_012;
  LDet4_1245_0125 := LMat^[1*6+0] * LDet3_245_125 - LMat^[1*6+1] * LDet3_245_025 + LMat^[1*6+2] * LDet3_245_015 - LMat^[1*6+5] * LDet3_245_012;
  LDet4_1245_0134 := LMat^[1*6+0] * LDet3_245_134 - LMat^[1*6+1] * LDet3_245_034 + LMat^[1*6+3] * LDet3_245_014 - LMat^[1*6+4] * LDet3_245_013;
  LDet4_1245_0135 := LMat^[1*6+0] * LDet3_245_135 - LMat^[1*6+1] * LDet3_245_035 + LMat^[1*6+3] * LDet3_245_015 - LMat^[1*6+5] * LDet3_245_013;
  LDet4_1245_0145 := LMat^[1*6+0] * LDet3_245_145 - LMat^[1*6+1] * LDet3_245_045 + LMat^[1*6+4] * LDet3_245_015 - LMat^[1*6+5] * LDet3_245_014;
  LDet4_1245_0234 := LMat^[1*6+0] * LDet3_245_234 - LMat^[1*6+2] * LDet3_245_034 + LMat^[1*6+3] * LDet3_245_024 - LMat^[1*6+4] * LDet3_245_023;
  LDet4_1245_0235 := LMat^[1*6+0] * LDet3_245_235 - LMat^[1*6+2] * LDet3_245_035 + LMat^[1*6+3] * LDet3_245_025 - LMat^[1*6+5] * LDet3_245_023;
  LDet4_1245_0245 := LMat^[1*6+0] * LDet3_245_245 - LMat^[1*6+2] * LDet3_245_045 + LMat^[1*6+4] * LDet3_245_025 - LMat^[1*6+5] * LDet3_245_024;
  LDet4_1245_0345 := LMat^[1*6+0] * LDet3_245_345 - LMat^[1*6+3] * LDet3_245_045 + LMat^[1*6+4] * LDet3_245_035 - LMat^[1*6+5] * LDet3_245_034;
  LDet4_1245_1234 := LMat^[1*6+1] * LDet3_245_234 - LMat^[1*6+2] * LDet3_245_134 + LMat^[1*6+3] * LDet3_245_124 - LMat^[1*6+4] * LDet3_245_123;
  LDet4_1245_1235 := LMat^[1*6+1] * LDet3_245_235 - LMat^[1*6+2] * LDet3_245_135 + LMat^[1*6+3] * LDet3_245_125 - LMat^[1*6+5] * LDet3_245_123;
  LDet4_1245_1245 := LMat^[1*6+1] * LDet3_245_245 - LMat^[1*6+2] * LDet3_245_145 + LMat^[1*6+4] * LDet3_245_125 - LMat^[1*6+5] * LDet3_245_124;
  LDet4_1245_1345 := LMat^[1*6+1] * LDet3_245_345 - LMat^[1*6+3] * LDet3_245_145 + LMat^[1*6+4] * LDet3_245_135 - LMat^[1*6+5] * LDet3_245_134;
  LDet4_1245_2345 := LMat^[1*6+2] * LDet3_245_345 - LMat^[1*6+3] * LDet3_245_245 + LMat^[1*6+4] * LDet3_245_235 - LMat^[1*6+5] * LDet3_245_234;
  LDet4_1345_0123 := LMat^[1*6+0] * LDet3_345_123 - LMat^[1*6+1] * LDet3_345_023 + LMat^[1*6+2] * LDet3_345_013 - LMat^[1*6+3] * LDet3_345_012;
  LDet4_1345_0124 := LMat^[1*6+0] * LDet3_345_124 - LMat^[1*6+1] * LDet3_345_024 + LMat^[1*6+2] * LDet3_345_014 - LMat^[1*6+4] * LDet3_345_012;
  LDet4_1345_0125 := LMat^[1*6+0] * LDet3_345_125 - LMat^[1*6+1] * LDet3_345_025 + LMat^[1*6+2] * LDet3_345_015 - LMat^[1*6+5] * LDet3_345_012;
  LDet4_1345_0134 := LMat^[1*6+0] * LDet3_345_134 - LMat^[1*6+1] * LDet3_345_034 + LMat^[1*6+3] * LDet3_345_014 - LMat^[1*6+4] * LDet3_345_013;
  LDet4_1345_0135 := LMat^[1*6+0] * LDet3_345_135 - LMat^[1*6+1] * LDet3_345_035 + LMat^[1*6+3] * LDet3_345_015 - LMat^[1*6+5] * LDet3_345_013;
  LDet4_1345_0145 := LMat^[1*6+0] * LDet3_345_145 - LMat^[1*6+1] * LDet3_345_045 + LMat^[1*6+4] * LDet3_345_015 - LMat^[1*6+5] * LDet3_345_014;
  LDet4_1345_0234 := LMat^[1*6+0] * LDet3_345_234 - LMat^[1*6+2] * LDet3_345_034 + LMat^[1*6+3] * LDet3_345_024 - LMat^[1*6+4] * LDet3_345_023;
  LDet4_1345_0235 := LMat^[1*6+0] * LDet3_345_235 - LMat^[1*6+2] * LDet3_345_035 + LMat^[1*6+3] * LDet3_345_025 - LMat^[1*6+5] * LDet3_345_023;
  LDet4_1345_0245 := LMat^[1*6+0] * LDet3_345_245 - LMat^[1*6+2] * LDet3_345_045 + LMat^[1*6+4] * LDet3_345_025 - LMat^[1*6+5] * LDet3_345_024;
  LDet4_1345_0345 := LMat^[1*6+0] * LDet3_345_345 - LMat^[1*6+3] * LDet3_345_045 + LMat^[1*6+4] * LDet3_345_035 - LMat^[1*6+5] * LDet3_345_034;
  LDet4_1345_1234 := LMat^[1*6+1] * LDet3_345_234 - LMat^[1*6+2] * LDet3_345_134 + LMat^[1*6+3] * LDet3_345_124 - LMat^[1*6+4] * LDet3_345_123;
  LDet4_1345_1235 := LMat^[1*6+1] * LDet3_345_235 - LMat^[1*6+2] * LDet3_345_135 + LMat^[1*6+3] * LDet3_345_125 - LMat^[1*6+5] * LDet3_345_123;
  LDet4_1345_1245 := LMat^[1*6+1] * LDet3_345_245 - LMat^[1*6+2] * LDet3_345_145 + LMat^[1*6+4] * LDet3_345_125 - LMat^[1*6+5] * LDet3_345_124;
  LDet4_1345_1345 := LMat^[1*6+1] * LDet3_345_345 - LMat^[1*6+3] * LDet3_345_145 + LMat^[1*6+4] * LDet3_345_135 - LMat^[1*6+5] * LDet3_345_134;
  LDet4_1345_2345 := LMat^[1*6+2] * LDet3_345_345 - LMat^[1*6+3] * LDet3_345_245 + LMat^[1*6+4] * LDet3_345_235 - LMat^[1*6+5] * LDet3_345_234;
  
  // remaining 5x5 sub-determinants
  LDet5_01234_01234 := LMat^[0*6+0] * LDet4_1234_1234 - LMat^[0*6+1] * LDet4_1234_0234 + LMat^[0*6+2] * LDet4_1234_0134 - LMat^[0*6+3] * LDet4_1234_0124 + LMat^[0*6+4] * LDet4_1234_0123;
  LDet5_01234_01235 := LMat^[0*6+0] * LDet4_1234_1235 - LMat^[0*6+1] * LDet4_1234_0235 + LMat^[0*6+2] * LDet4_1234_0135 - LMat^[0*6+3] * LDet4_1234_0125 + LMat^[0*6+5] * LDet4_1234_0123;
  LDet5_01234_01245 := LMat^[0*6+0] * LDet4_1234_1245 - LMat^[0*6+1] * LDet4_1234_0245 + LMat^[0*6+2] * LDet4_1234_0145 - LMat^[0*6+4] * LDet4_1234_0125 + LMat^[0*6+5] * LDet4_1234_0124;
  LDet5_01234_01345 := LMat^[0*6+0] * LDet4_1234_1345 - LMat^[0*6+1] * LDet4_1234_0345 + LMat^[0*6+3] * LDet4_1234_0145 - LMat^[0*6+4] * LDet4_1234_0135 + LMat^[0*6+5] * LDet4_1234_0134;
  LDet5_01234_02345 := LMat^[0*6+0] * LDet4_1234_2345 - LMat^[0*6+2] * LDet4_1234_0345 + LMat^[0*6+3] * LDet4_1234_0245 - LMat^[0*6+4] * LDet4_1234_0235 + LMat^[0*6+5] * LDet4_1234_0234;
  LDet5_01234_12345 := LMat^[0*6+1] * LDet4_1234_2345 - LMat^[0*6+2] * LDet4_1234_1345 + LMat^[0*6+3] * LDet4_1234_1245 - LMat^[0*6+4] * LDet4_1234_1235 + LMat^[0*6+5] * LDet4_1234_1234;
  LDet5_01235_01234 := LMat^[0*6+0] * LDet4_1235_1234 - LMat^[0*6+1] * LDet4_1235_0234 + LMat^[0*6+2] * LDet4_1235_0134 - LMat^[0*6+3] * LDet4_1235_0124 + LMat^[0*6+4] * LDet4_1235_0123;
  LDet5_01235_01235 := LMat^[0*6+0] * LDet4_1235_1235 - LMat^[0*6+1] * LDet4_1235_0235 + LMat^[0*6+2] * LDet4_1235_0135 - LMat^[0*6+3] * LDet4_1235_0125 + LMat^[0*6+5] * LDet4_1235_0123;
  LDet5_01235_01245 := LMat^[0*6+0] * LDet4_1235_1245 - LMat^[0*6+1] * LDet4_1235_0245 + LMat^[0*6+2] * LDet4_1235_0145 - LMat^[0*6+4] * LDet4_1235_0125 + LMat^[0*6+5] * LDet4_1235_0124;
  LDet5_01235_01345 := LMat^[0*6+0] * LDet4_1235_1345 - LMat^[0*6+1] * LDet4_1235_0345 + LMat^[0*6+3] * LDet4_1235_0145 - LMat^[0*6+4] * LDet4_1235_0135 + LMat^[0*6+5] * LDet4_1235_0134;
  LDet5_01235_02345 := LMat^[0*6+0] * LDet4_1235_2345 - LMat^[0*6+2] * LDet4_1235_0345 + LMat^[0*6+3] * LDet4_1235_0245 - LMat^[0*6+4] * LDet4_1235_0235 + LMat^[0*6+5] * LDet4_1235_0234;
  LDet5_01235_12345 := LMat^[0*6+1] * LDet4_1235_2345 - LMat^[0*6+2] * LDet4_1235_1345 + LMat^[0*6+3] * LDet4_1235_1245 - LMat^[0*6+4] * LDet4_1235_1235 + LMat^[0*6+5] * LDet4_1235_1234;
  LDet5_01245_01234 := LMat^[0*6+0] * LDet4_1245_1234 - LMat^[0*6+1] * LDet4_1245_0234 + LMat^[0*6+2] * LDet4_1245_0134 - LMat^[0*6+3] * LDet4_1245_0124 + LMat^[0*6+4] * LDet4_1245_0123;
  LDet5_01245_01235 := LMat^[0*6+0] * LDet4_1245_1235 - LMat^[0*6+1] * LDet4_1245_0235 + LMat^[0*6+2] * LDet4_1245_0135 - LMat^[0*6+3] * LDet4_1245_0125 + LMat^[0*6+5] * LDet4_1245_0123;
  LDet5_01245_01245 := LMat^[0*6+0] * LDet4_1245_1245 - LMat^[0*6+1] * LDet4_1245_0245 + LMat^[0*6+2] * LDet4_1245_0145 - LMat^[0*6+4] * LDet4_1245_0125 + LMat^[0*6+5] * LDet4_1245_0124;
  LDet5_01245_01345 := LMat^[0*6+0] * LDet4_1245_1345 - LMat^[0*6+1] * LDet4_1245_0345 + LMat^[0*6+3] * LDet4_1245_0145 - LMat^[0*6+4] * LDet4_1245_0135 + LMat^[0*6+5] * LDet4_1245_0134;
  LDet5_01245_02345 := LMat^[0*6+0] * LDet4_1245_2345 - LMat^[0*6+2] * LDet4_1245_0345 + LMat^[0*6+3] * LDet4_1245_0245 - LMat^[0*6+4] * LDet4_1245_0235 + LMat^[0*6+5] * LDet4_1245_0234;
  LDet5_01245_12345 := LMat^[0*6+1] * LDet4_1245_2345 - LMat^[0*6+2] * LDet4_1245_1345 + LMat^[0*6+3] * LDet4_1245_1245 - LMat^[0*6+4] * LDet4_1245_1235 + LMat^[0*6+5] * LDet4_1245_1234;
  LDet5_01345_01234 := LMat^[0*6+0] * LDet4_1345_1234 - LMat^[0*6+1] * LDet4_1345_0234 + LMat^[0*6+2] * LDet4_1345_0134 - LMat^[0*6+3] * LDet4_1345_0124 + LMat^[0*6+4] * LDet4_1345_0123;
  LDet5_01345_01235 := LMat^[0*6+0] * LDet4_1345_1235 - LMat^[0*6+1] * LDet4_1345_0235 + LMat^[0*6+2] * LDet4_1345_0135 - LMat^[0*6+3] * LDet4_1345_0125 + LMat^[0*6+5] * LDet4_1345_0123;
  LDet5_01345_01245 := LMat^[0*6+0] * LDet4_1345_1245 - LMat^[0*6+1] * LDet4_1345_0245 + LMat^[0*6+2] * LDet4_1345_0145 - LMat^[0*6+4] * LDet4_1345_0125 + LMat^[0*6+5] * LDet4_1345_0124;
  LDet5_01345_01345 := LMat^[0*6+0] * LDet4_1345_1345 - LMat^[0*6+1] * LDet4_1345_0345 + LMat^[0*6+3] * LDet4_1345_0145 - LMat^[0*6+4] * LDet4_1345_0135 + LMat^[0*6+5] * LDet4_1345_0134;
  LDet5_01345_02345 := LMat^[0*6+0] * LDet4_1345_2345 - LMat^[0*6+2] * LDet4_1345_0345 + LMat^[0*6+3] * LDet4_1345_0245 - LMat^[0*6+4] * LDet4_1345_0235 + LMat^[0*6+5] * LDet4_1345_0234;
  LDet5_01345_12345 := LMat^[0*6+1] * LDet4_1345_2345 - LMat^[0*6+2] * LDet4_1345_1345 + LMat^[0*6+3] * LDet4_1345_1245 - LMat^[0*6+4] * LDet4_1345_1235 + LMat^[0*6+5] * LDet4_1345_1234;
  LDet5_02345_01234 := LMat^[0*6+0] * LDet4_2345_1234 - LMat^[0*6+1] * LDet4_2345_0234 + LMat^[0*6+2] * LDet4_2345_0134 - LMat^[0*6+3] * LDet4_2345_0124 + LMat^[0*6+4] * LDet4_2345_0123;
  LDet5_02345_01235 := LMat^[0*6+0] * LDet4_2345_1235 - LMat^[0*6+1] * LDet4_2345_0235 + LMat^[0*6+2] * LDet4_2345_0135 - LMat^[0*6+3] * LDet4_2345_0125 + LMat^[0*6+5] * LDet4_2345_0123;
  LDet5_02345_01245 := LMat^[0*6+0] * LDet4_2345_1245 - LMat^[0*6+1] * LDet4_2345_0245 + LMat^[0*6+2] * LDet4_2345_0145 - LMat^[0*6+4] * LDet4_2345_0125 + LMat^[0*6+5] * LDet4_2345_0124;
  LDet5_02345_01345 := LMat^[0*6+0] * LDet4_2345_1345 - LMat^[0*6+1] * LDet4_2345_0345 + LMat^[0*6+3] * LDet4_2345_0145 - LMat^[0*6+4] * LDet4_2345_0135 + LMat^[0*6+5] * LDet4_2345_0134;
  LDet5_02345_02345 := LMat^[0*6+0] * LDet4_2345_2345 - LMat^[0*6+2] * LDet4_2345_0345 + LMat^[0*6+3] * LDet4_2345_0245 - LMat^[0*6+4] * LDet4_2345_0235 + LMat^[0*6+5] * LDet4_2345_0234;
  LDet5_02345_12345 := LMat^[0*6+1] * LDet4_2345_2345 - LMat^[0*6+2] * LDet4_2345_1345 + LMat^[0*6+3] * LDet4_2345_1245 - LMat^[0*6+4] * LDet4_2345_1235 + LMat^[0*6+5] * LDet4_2345_1234;
  
  LMat^[0*6+0] := LDet5_12345_12345 * LInvDet;
  LMat^[0*6+1] := -LDet5_02345_12345 * LInvDet;
  LMat^[0*6+2] := LDet5_01345_12345 * LInvDet;
  LMat^[0*6+3] := -LDet5_01245_12345 * LInvDet;
  LMat^[0*6+4] := LDet5_01235_12345 * LInvDet;
  LMat^[0*6+5] := -LDet5_01234_12345 * LInvDet;
  
  LMat^[1*6+0] := -LDet5_12345_02345 * LInvDet;
  LMat^[1*6+1] := LDet5_02345_02345 * LInvDet;
  LMat^[1*6+2] := -LDet5_01345_02345 * LInvDet;
  LMat^[1*6+3] := LDet5_01245_02345 * LInvDet;
  LMat^[1*6+4] := -LDet5_01235_02345 * LInvDet;
  LMat^[1*6+5] := LDet5_01234_02345 * LInvDet;
  
  LMat^[2*6+0] := LDet5_12345_01345 * LInvDet;
  LMat^[2*6+1] := -LDet5_02345_01345 * LInvDet;
  LMat^[2*6+2] := LDet5_01345_01345 * LInvDet;
  LMat^[2*6+3] := -LDet5_01245_01345 * LInvDet;
  LMat^[2*6+4] := LDet5_01235_01345 * LInvDet;
  LMat^[2*6+5] := -LDet5_01234_01345 * LInvDet;
  
  LMat^[3*6+0] := -LDet5_12345_01245 * LInvDet;
  LMat^[3*6+1] := LDet5_02345_01245 * LInvDet;
  LMat^[3*6+2] := -LDet5_01345_01245 * LInvDet;
  LMat^[3*6+3] := LDet5_01245_01245 * LInvDet;
  LMat^[3*6+4] := -LDet5_01235_01245 * LInvDet;
  LMat^[3*6+5] := LDet5_01234_01245 * LInvDet;
  
  LMat^[4*6+0] := LDet5_12345_01235 * LInvDet;
  LMat^[4*6+1] := -LDet5_02345_01235 * LInvDet;
  LMat^[4*6+2] := LDet5_01345_01235 * LInvDet;
  LMat^[4*6+3] := -LDet5_01245_01235 * LInvDet;
  LMat^[4*6+4] := LDet5_01235_01235 * LInvDet;
  LMat^[4*6+5] := -LDet5_01234_01235 * LInvDet;
  
  LMat^[5*6+0] := -LDet5_12345_01234 * LInvDet;
  LMat^[5*6+1] := LDet5_02345_01234 * LInvDet;
  LMat^[5*6+2] := -LDet5_01345_01234 * LInvDet;
  LMat^[5*6+3] := LDet5_01245_01234 * LInvDet;
  LMat^[5*6+4] := -LDet5_01235_01234 * LInvDet;
  LMat^[5*6+5] := LDet5_01234_01234 * LInvDet;
  
  Result := true;
end;

function TIdMat6.InverseFastSelf: Boolean;
var
  LMat: PFlat;
  LC0, LC1, LC2, LDet, LInvDet: Single;
  LR0: array[0..2, 0..2] of Single;
  LR1: array[0..2, 0..2] of Single;
  LR2: array[0..2, 0..2] of Single;
  LR3: array[0..2, 0..2] of Single;
begin
  LMat := PFlat(@Rows[0]);
  // 6*27+2*30 = 222 multiplications
  //    2*1  =   2 divisions
  
  // r0 = m0.Inverse();
  LC0 := LMat^[1*6+1] * LMat^[2*6+2] - LMat^[1*6+2] * LMat^[2*6+1];
  LC1 := LMat^[1*6+2] * LMat^[2*6+0] - LMat^[1*6+0] * LMat^[2*6+2];
  LC2 := LMat^[1*6+0] * LMat^[2*6+1] - LMat^[1*6+1] * LMat^[2*6+0];
  
  LDet := LMat^[0*6+0] * LC0 + LMat^[0*6+1] * LC1 + LMat^[0*6+2] * LC2;
  
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  
  LInvDet := 1.0 / LDet;
  
  LR0[0][0] := LC0 * LInvDet;
  LR0[0][1] := ( LMat^[0*6+2] * LMat^[2*6+1] - LMat^[0*6+1] * LMat^[2*6+2] ) * LInvDet;
  LR0[0][2] := ( LMat^[0*6+1] * LMat^[1*6+2] - LMat^[0*6+2] * LMat^[1*6+1] ) * LInvDet;
  LR0[1][0] := LC1 * LInvDet;
  LR0[1][1] := ( LMat^[0*6+0] * LMat^[2*6+2] - LMat^[0*6+2] * LMat^[2*6+0] ) * LInvDet;
  LR0[1][2] := ( LMat^[0*6+2] * LMat^[1*6+0] - LMat^[0*6+0] * LMat^[1*6+2] ) * LInvDet;
  LR0[2][0] := LC2 * LInvDet;
  LR0[2][1] := ( LMat^[0*6+1] * LMat^[2*6+0] - LMat^[0*6+0] * LMat^[2*6+1] ) * LInvDet;
  LR0[2][2] := ( LMat^[0*6+0] * LMat^[1*6+1] - LMat^[0*6+1] * LMat^[1*6+0] ) * LInvDet;
  
  // r1 = r0 * m1;
  LR1[0][0] := LR0[0][0] * LMat^[0*6+3] + LR0[0][1] * LMat^[1*6+3] + LR0[0][2] * LMat^[2*6+3];
  LR1[0][1] := LR0[0][0] * LMat^[0*6+4] + LR0[0][1] * LMat^[1*6+4] + LR0[0][2] * LMat^[2*6+4];
  LR1[0][2] := LR0[0][0] * LMat^[0*6+5] + LR0[0][1] * LMat^[1*6+5] + LR0[0][2] * LMat^[2*6+5];
  LR1[1][0] := LR0[1][0] * LMat^[0*6+3] + LR0[1][1] * LMat^[1*6+3] + LR0[1][2] * LMat^[2*6+3];
  LR1[1][1] := LR0[1][0] * LMat^[0*6+4] + LR0[1][1] * LMat^[1*6+4] + LR0[1][2] * LMat^[2*6+4];
  LR1[1][2] := LR0[1][0] * LMat^[0*6+5] + LR0[1][1] * LMat^[1*6+5] + LR0[1][2] * LMat^[2*6+5];
  LR1[2][0] := LR0[2][0] * LMat^[0*6+3] + LR0[2][1] * LMat^[1*6+3] + LR0[2][2] * LMat^[2*6+3];
  LR1[2][1] := LR0[2][0] * LMat^[0*6+4] + LR0[2][1] * LMat^[1*6+4] + LR0[2][2] * LMat^[2*6+4];
  LR1[2][2] := LR0[2][0] * LMat^[0*6+5] + LR0[2][1] * LMat^[1*6+5] + LR0[2][2] * LMat^[2*6+5];
  
  // r2 = m2 * r1;
  LR2[0][0] := LMat^[3*6+0] * LR1[0][0] + LMat^[3*6+1] * LR1[1][0] + LMat^[3*6+2] * LR1[2][0];
  LR2[0][1] := LMat^[3*6+0] * LR1[0][1] + LMat^[3*6+1] * LR1[1][1] + LMat^[3*6+2] * LR1[2][1];
  LR2[0][2] := LMat^[3*6+0] * LR1[0][2] + LMat^[3*6+1] * LR1[1][2] + LMat^[3*6+2] * LR1[2][2];
  LR2[1][0] := LMat^[4*6+0] * LR1[0][0] + LMat^[4*6+1] * LR1[1][0] + LMat^[4*6+2] * LR1[2][0];
  LR2[1][1] := LMat^[4*6+0] * LR1[0][1] + LMat^[4*6+1] * LR1[1][1] + LMat^[4*6+2] * LR1[2][1];
  LR2[1][2] := LMat^[4*6+0] * LR1[0][2] + LMat^[4*6+1] * LR1[1][2] + LMat^[4*6+2] * LR1[2][2];
  LR2[2][0] := LMat^[5*6+0] * LR1[0][0] + LMat^[5*6+1] * LR1[1][0] + LMat^[5*6+2] * LR1[2][0];
  LR2[2][1] := LMat^[5*6+0] * LR1[0][1] + LMat^[5*6+1] * LR1[1][1] + LMat^[5*6+2] * LR1[2][1];
  LR2[2][2] := LMat^[5*6+0] * LR1[0][2] + LMat^[5*6+1] * LR1[1][2] + LMat^[5*6+2] * LR1[2][2];
  
  // r3 = r2 - m3;
  LR3[0][0] := LR2[0][0] - LMat^[3*6+3];
  LR3[0][1] := LR2[0][1] - LMat^[3*6+4];
  LR3[0][2] := LR2[0][2] - LMat^[3*6+5];
  LR3[1][0] := LR2[1][0] - LMat^[4*6+3];
  LR3[1][1] := LR2[1][1] - LMat^[4*6+4];
  LR3[1][2] := LR2[1][2] - LMat^[4*6+5];
  LR3[2][0] := LR2[2][0] - LMat^[5*6+3];
  LR3[2][1] := LR2[2][1] - LMat^[5*6+4];
  LR3[2][2] := LR2[2][2] - LMat^[5*6+5];
  
  // r3.InverseSelf();
  LR2[0][0] := LR3[1][1] * LR3[2][2] - LR3[1][2] * LR3[2][1];
  LR2[1][0] := LR3[1][2] * LR3[2][0] - LR3[1][0] * LR3[2][2];
  LR2[2][0] := LR3[1][0] * LR3[2][1] - LR3[1][1] * LR3[2][0];
  
  LDet := LR3[0][0] * LR2[0][0] + LR3[0][1] * LR2[1][0] + LR3[0][2] * LR2[2][0];
  
  if TIdMath.Fabs(Single(LDet)) < MAT_INVERSE_EPSILON then
    Exit(False);
  
  LInvDet := 1.0 / LDet;
  
  LR2[0][1] := LR3[0][2] * LR3[2][1] - LR3[0][1] * LR3[2][2];
  LR2[0][2] := LR3[0][1] * LR3[1][2] - LR3[0][2] * LR3[1][1];
  LR2[1][1] := LR3[0][0] * LR3[2][2] - LR3[0][2] * LR3[2][0];
  LR2[1][2] := LR3[0][2] * LR3[1][0] - LR3[0][0] * LR3[1][2];
  LR2[2][1] := LR3[0][1] * LR3[2][0] - LR3[0][0] * LR3[2][1];
  LR2[2][2] := LR3[0][0] * LR3[1][1] - LR3[0][1] * LR3[1][0];
  
  LR3[0][0] := LR2[0][0] * LInvDet;
  LR3[0][1] := LR2[0][1] * LInvDet;
  LR3[0][2] := LR2[0][2] * LInvDet;
  LR3[1][0] := LR2[1][0] * LInvDet;
  LR3[1][1] := LR2[1][1] * LInvDet;
  LR3[1][2] := LR2[1][2] * LInvDet;
  LR3[2][0] := LR2[2][0] * LInvDet;
  LR3[2][1] := LR2[2][1] * LInvDet;
  LR3[2][2] := LR2[2][2] * LInvDet;
  
  // r2 = m2 * r0;
  LR2[0][0] := LMat^[3*6+0] * LR0[0][0] + LMat^[3*6+1] * LR0[1][0] + LMat^[3*6+2] * LR0[2][0];
  LR2[0][1] := LMat^[3*6+0] * LR0[0][1] + LMat^[3*6+1] * LR0[1][1] + LMat^[3*6+2] * LR0[2][1];
  LR2[0][2] := LMat^[3*6+0] * LR0[0][2] + LMat^[3*6+1] * LR0[1][2] + LMat^[3*6+2] * LR0[2][2];
  LR2[1][0] := LMat^[4*6+0] * LR0[0][0] + LMat^[4*6+1] * LR0[1][0] + LMat^[4*6+2] * LR0[2][0];
  LR2[1][1] := LMat^[4*6+0] * LR0[0][1] + LMat^[4*6+1] * LR0[1][1] + LMat^[4*6+2] * LR0[2][1];
  LR2[1][2] := LMat^[4*6+0] * LR0[0][2] + LMat^[4*6+1] * LR0[1][2] + LMat^[4*6+2] * LR0[2][2];
  LR2[2][0] := LMat^[5*6+0] * LR0[0][0] + LMat^[5*6+1] * LR0[1][0] + LMat^[5*6+2] * LR0[2][0];
  LR2[2][1] := LMat^[5*6+0] * LR0[0][1] + LMat^[5*6+1] * LR0[1][1] + LMat^[5*6+2] * LR0[2][1];
  LR2[2][2] := LMat^[5*6+0] * LR0[0][2] + LMat^[5*6+1] * LR0[1][2] + LMat^[5*6+2] * LR0[2][2];
  
  // m2 = r3 * r2;
  LMat^[3*6+0] := LR3[0][0] * LR2[0][0] + LR3[0][1] * LR2[1][0] + LR3[0][2] * LR2[2][0];
  LMat^[3*6+1] := LR3[0][0] * LR2[0][1] + LR3[0][1] * LR2[1][1] + LR3[0][2] * LR2[2][1];
  LMat^[3*6+2] := LR3[0][0] * LR2[0][2] + LR3[0][1] * LR2[1][2] + LR3[0][2] * LR2[2][2];
  LMat^[4*6+0] := LR3[1][0] * LR2[0][0] + LR3[1][1] * LR2[1][0] + LR3[1][2] * LR2[2][0];
  LMat^[4*6+1] := LR3[1][0] * LR2[0][1] + LR3[1][1] * LR2[1][1] + LR3[1][2] * LR2[2][1];
  LMat^[4*6+2] := LR3[1][0] * LR2[0][2] + LR3[1][1] * LR2[1][2] + LR3[1][2] * LR2[2][2];
  LMat^[5*6+0] := LR3[2][0] * LR2[0][0] + LR3[2][1] * LR2[1][0] + LR3[2][2] * LR2[2][0];
  LMat^[5*6+1] := LR3[2][0] * LR2[0][1] + LR3[2][1] * LR2[1][1] + LR3[2][2] * LR2[2][1];
  LMat^[5*6+2] := LR3[2][0] * LR2[0][2] + LR3[2][1] * LR2[1][2] + LR3[2][2] * LR2[2][2];
  
  // m0 = r0 - r1 * m2;
  LMat^[0*6+0] := LR0[0][0] - LR1[0][0] * LMat^[3*6+0] - LR1[0][1] * LMat^[4*6+0] - LR1[0][2] * LMat^[5*6+0];
  LMat^[0*6+1] := LR0[0][1] - LR1[0][0] * LMat^[3*6+1] - LR1[0][1] * LMat^[4*6+1] - LR1[0][2] * LMat^[5*6+1];
  LMat^[0*6+2] := LR0[0][2] - LR1[0][0] * LMat^[3*6+2] - LR1[0][1] * LMat^[4*6+2] - LR1[0][2] * LMat^[5*6+2];
  LMat^[1*6+0] := LR0[1][0] - LR1[1][0] * LMat^[3*6+0] - LR1[1][1] * LMat^[4*6+0] - LR1[1][2] * LMat^[5*6+0];
  LMat^[1*6+1] := LR0[1][1] - LR1[1][0] * LMat^[3*6+1] - LR1[1][1] * LMat^[4*6+1] - LR1[1][2] * LMat^[5*6+1];
  LMat^[1*6+2] := LR0[1][2] - LR1[1][0] * LMat^[3*6+2] - LR1[1][1] * LMat^[4*6+2] - LR1[1][2] * LMat^[5*6+2];
  LMat^[2*6+0] := LR0[2][0] - LR1[2][0] * LMat^[3*6+0] - LR1[2][1] * LMat^[4*6+0] - LR1[2][2] * LMat^[5*6+0];
  LMat^[2*6+1] := LR0[2][1] - LR1[2][0] * LMat^[3*6+1] - LR1[2][1] * LMat^[4*6+1] - LR1[2][2] * LMat^[5*6+1];
  LMat^[2*6+2] := LR0[2][2] - LR1[2][0] * LMat^[3*6+2] - LR1[2][1] * LMat^[4*6+2] - LR1[2][2] * LMat^[5*6+2];
  
  // m1 = r1 * r3;
  LMat^[0*6+3] := LR1[0][0] * LR3[0][0] + LR1[0][1] * LR3[1][0] + LR1[0][2] * LR3[2][0];
  LMat^[0*6+4] := LR1[0][0] * LR3[0][1] + LR1[0][1] * LR3[1][1] + LR1[0][2] * LR3[2][1];
  LMat^[0*6+5] := LR1[0][0] * LR3[0][2] + LR1[0][1] * LR3[1][2] + LR1[0][2] * LR3[2][2];
  LMat^[1*6+3] := LR1[1][0] * LR3[0][0] + LR1[1][1] * LR3[1][0] + LR1[1][2] * LR3[2][0];
  LMat^[1*6+4] := LR1[1][0] * LR3[0][1] + LR1[1][1] * LR3[1][1] + LR1[1][2] * LR3[2][1];
  LMat^[1*6+5] := LR1[1][0] * LR3[0][2] + LR1[1][1] * LR3[1][2] + LR1[1][2] * LR3[2][2];
  LMat^[2*6+3] := LR1[2][0] * LR3[0][0] + LR1[2][1] * LR3[1][0] + LR1[2][2] * LR3[2][0];
  LMat^[2*6+4] := LR1[2][0] * LR3[0][1] + LR1[2][1] * LR3[1][1] + LR1[2][2] * LR3[2][1];
  LMat^[2*6+5] := LR1[2][0] * LR3[0][2] + LR1[2][1] * LR3[1][2] + LR1[2][2] * LR3[2][2];
  
  // m3 = -r3;
  LMat^[3*6+3] := -LR3[0][0];
  LMat^[3*6+4] := -LR3[0][1];
  LMat^[3*6+5] := -LR3[0][2];
  LMat^[4*6+3] := -LR3[1][0];
  LMat^[4*6+4] := -LR3[1][1];
  LMat^[4*6+5] := -LR3[1][2];
  LMat^[5*6+3] := -LR3[2][0];
  LMat^[5*6+4] := -LR3[2][1];
  LMat^[5*6+5] := -LR3[2][2];
  
  Result := true;
end;

end.
