{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatX, the matrix of any size     }
{                                                                              }
{  Port of idMatX (idlib\math\Matrix.h and Matrix.cpp) of the Doom 3 GPL       }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Types, DelphiDoom.MathCore.Float.Vec6,
  DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   A matrix of Single of any size stored by rows (idMatX). As for <c>TIdVecX</c> the matrix
  ///   is a class that owns its memory (or points at memory given by <c>SetData</c>, never freed
  ///   here), the operators that make a new matrix are functions whose result the caller frees,
  ///   and the storage is padded with zeros to a multiple of four floats. This unit has the
  ///   matrix itself, its tests, the update formulas and the LU factorization (the generic
  ///   determinant and inverse need it); the other factorizations are in
  ///   <c>TIdMatXInverse</c>, <c>TIdMatXQr</c>, <c>TIdMatXSvd</c>, <c>TIdMatXCholesky</c>,
  ///   <c>TIdMatXLdlt</c>, <c>TIdMatXTriDiagonal</c> and <c>TIdMatXEigen</c>.
  /// </summary>
  TIdMatX = class
  strict private
    FRows: Integer;
    FColumns: Integer;
    FStorage: TArray<Single>;
    FData: PIdSingleArray;
    FExternal: Boolean;
    function GetItem(const ARow, AColumn: Integer): Single;
    procedure SetItem(const ARow, AColumn: Integer; const AValue: Single);
    procedure ClearEnd;
    function DeterminantGeneric: Single;
    function InverseSelfGeneric: Boolean;
  public
    constructor Create; overload;
    constructor Create(const ARows, AColumns: Integer); overload;
    /// <summary>A matrix over memory of the caller (idMatX(rows, columns, src)); never freed here</summary>
    constructor Create(const ARows, AColumns: Integer; const AData: PIdSingleArray); overload;
    property Items[const ARow, AColumn: Integer]: Single read GetItem write SetItem; default;
    property NumRows: Integer read FRows;
    property NumColumns: Integer read FColumns;
    /// <summary>idMatX::ToFloatPtr: the values by rows</summary>
    property Data: PIdSingleArray read FData;
    /// <summary>operator[]: the first float of a row, to be indexed like the C pointer</summary>
    function Row(const ARow: Integer): PIdSingleArray;
    procedure SetValues(const ARows, AColumns: Integer; const ASource: PIdSingleArray); overload;
    procedure SetValues(const AM1, AM2: TIdMat3); overload;
    procedure SetValues(const AM1, AM2, AM3, AM4: TIdMat3); overload;
    /// <summary>operator=: takes the size and the values of another matrix</summary>
    procedure Assign(const A: TIdMatX);
    /// <summary>operator*=(float)</summary>
    procedure MultiplyAssign(const A: Single); overload;
    /// <summary>operator*=(idMatX)</summary>
    procedure MultiplyAssign(const A: TIdMatX); overload;
    procedure AddAssign(const A: TIdMatX);
    procedure SubtractAssign(const A: TIdMatX);
    function Multiply(const A: Single): TIdMatX; overload;
    /// <summary>The product with a vector as a new vector</summary>
    function Multiply(const AVector: TIdVecX): TIdVecX; overload;
    function Multiply(const A: TIdMatX): TIdMatX; overload;
    function Add(const A: TIdMatX): TIdMatX;
    function Subtract(const A: TIdMatX): TIdMatX;
    function TransposeMultiply(const AVector: TIdVecX): TIdVecX; overload;
    function TransposeMultiply(const A: TIdMatX): TIdMatX; overload;
    procedure Multiply(const ADestination, AVector: TIdVecX); overload;
    procedure MultiplyAdd(const ADestination, AVector: TIdVecX);
    procedure MultiplySub(const ADestination, AVector: TIdVecX);
    procedure TransposeMultiply(const ADestination, AVector: TIdVecX); overload;
    procedure TransposeMultiplyAdd(const ADestination, AVector: TIdVecX);
    procedure TransposeMultiplySub(const ADestination, AVector: TIdVecX);
    procedure Multiply(const ADestination, A: TIdMatX); overload;
    procedure TransposeMultiply(const ADestination, A: TIdMatX); overload;
    /// <summary>Exact comparison</summary>
    function Compare(const A: TIdMatX): Boolean; overload;
    function Compare(const A: TIdMatX; const AEpsilon: Single): Boolean; overload;
    procedure SetSize(const ARows, AColumns: Integer);
    procedure ChangeSize(const ARows, AColumns: Integer; const AMakeZero: Boolean = False);
    procedure SetData(const ARows, AColumns: Integer; const AData: PIdSingleArray);
    procedure Zero; overload;
    procedure Zero(const ARows, AColumns: Integer); overload;
    procedure Identity; overload;
    procedure Identity(const ARows, AColumns: Integer); overload;
    procedure Diag(const AVector: TIdVecX);
    procedure Random(const ASeed: Integer; const ALower: Single = 0.0; const AUpper: Single = 1.0);
      overload;
    procedure Random(const ARows, AColumns, ASeed: Integer; const ALower: Single = 0.0;
      const AUpper: Single = 1.0); overload;
    procedure Negate;
    procedure Clamp(const AMin, AMax: Single);
    procedure SwapRows(const AFirst, ASecond: Integer);
    procedure SwapColumns(const AFirst, ASecond: Integer);
    procedure SwapRowsColumns(const AFirst, ASecond: Integer);
    procedure RemoveRow(const ARow: Integer);
    procedure RemoveColumn(const AColumn: Integer);
    procedure RemoveRowColumn(const AIndex: Integer);
    procedure ClearUpperTriangle;
    procedure ClearLowerTriangle;
    procedure SquareSubMatrix(const AMatrix: TIdMatX; const ASize: Integer);
    function MaxDifference(const AMatrix: TIdMatX): Single;
    function IsSquare: Boolean;
    function IsZero(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsIdentity(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsDiagonal(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsTriDiagonal(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsSymmetric(const AEpsilon: Single = MAT_EPSILON): Boolean;
    /// <summary>Faithful to the C++, including the loop that reuses its own counter</summary>
    function IsOrthogonal(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsOrthonormal(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsPMatrix(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsZMatrix(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsPositiveDefinite(const AEpsilon: Single = MAT_EPSILON): Boolean;
    function IsPositiveSemiDefinite(const AEpsilon: Single = MAT_EPSILON): Boolean;
    /// <summary>The sum of the diagonal (the header of the C++ says product)</summary>
    function Trace: Single;
    function Determinant: Single;
    /// <summary>The transpose as a new matrix</summary>
    function Transpose: TIdMatX;
    procedure TransposeSelf;
    /// <summary>The inverse as a new matrix (the C++ asserts that the matrix is invertible)</summary>
    function Inverse: TIdMatX;
    /// <summary>Inverts in place; false if the determinant is zero (sizes above 6: LU)</summary>
    function InverseSelf: Boolean;
    function InverseFast: TIdMatX;
    function InverseFastSelf: Boolean;
    function LowerTriangularInverse: Boolean;
    function UpperTriangularInverse: Boolean;
    function GetDimension: Integer;
    /// <summary>The first six floats of a row as a vector (a copy)</summary>
    function GetSubVec6(const ARow: Integer): TIdVec6;
    procedure SetSubVec6(const ARow: Integer; const AValue: TIdVec6);
    /// <summary>A vector over a whole row; shares the memory with the matrix and must be freed by the caller</summary>
    function SubVecX(const ARow: Integer): TIdVecX;
    function ToString(const APrecision: Integer = 2): AnsiString; reintroduce;
    procedure UpdateRankOne(const AV, AW: TIdVecX; const AAlpha: Single);
    procedure UpdateRankOneSymmetric(const AV: TIdVecX; const AAlpha: Single);
    procedure UpdateRowColumn(const AV, AW: TIdVecX; const ARow: Integer);
    procedure UpdateRowColumnSymmetric(const AV: TIdVecX; const ARow: Integer);
    procedure UpdateIncrement(const AV, AW: TIdVecX);
    procedure UpdateIncrementSymmetric(const AV: TIdVecX);
    procedure UpdateDecrement(const ARow: Integer);
    /// <summary>
    ///   In-place factorization L*U (LU_Factor): L in the lower triangle with an implicit unit
    ///   diagonal, U in the upper one. With <c>AIndex</c> assigned (one integer per row) partial
    ///   pivoting is used and the row permutation is stored there; with <c>ADeterminant</c>
    ///   assigned the determinant is stored there. False if the matrix is singular.
    /// </summary>
    function LuFactor(const AIndex: PIdIntegerArray; const ADeterminant: PSingle = nil): Boolean;
    /// <summary>Solves Ax = b with A factored in place as LU</summary>
    procedure LuSolve(const AX, AB: TIdVecX; const AIndex: PIdIntegerArray);
    procedure LuInverse(const AInverse: TIdMatX; const AIndex: PIdIntegerArray);
    procedure LuUnpackFactors(const AL, AU: TIdMatX);
    procedure LuMultiplyFactors(const AMatrix: TIdMatX; const AIndex: PIdIntegerArray);
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Random, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.MathCore.Float.Mat2, DelphiDoom.MathCore.Float.Mat4, DelphiDoom.MathCore.Float.Mat5,
  DelphiDoom.MathCore.Float.Mat6;

{ TIdMatX }

constructor TIdMatX.Create;
begin
  inherited Create;
  FRows := 0;
  FColumns := 0;
  FData := nil;
end;

constructor TIdMatX.Create(const ARows, AColumns: Integer);
begin
  Create;
  SetSize(ARows, AColumns);
end;

constructor TIdMatX.Create(const ARows, AColumns: Integer; const AData: PIdSingleArray);
begin
  Create;
  SetData(ARows, AColumns, AData);
end;

procedure TIdMatX.ClearEnd;
var
  LIndex: Integer;
begin
  LIndex := FRows * FColumns;
  while LIndex < ((LIndex + 3) and not 3) do
  begin
    FData^[LIndex] := 0.0;
    Inc(LIndex);
  end;
end;

function TIdMatX.GetItem(const ARow, AColumn: Integer): Single;
begin
  Assert((ARow >= 0) and (ARow < FRows));
  Result := FData^[ARow * FColumns + AColumn];
end;

procedure TIdMatX.SetItem(const ARow, AColumn: Integer; const AValue: Single);
begin
  Assert((ARow >= 0) and (ARow < FRows));
  FData^[ARow * FColumns + AColumn] := AValue;
end;

function TIdMatX.Row(const ARow: Integer): PIdSingleArray;
begin
  Assert((ARow >= 0) and (ARow < FRows));
  Result := PIdSingleArray(@FData^[ARow * FColumns]);
end;

procedure TIdMatX.SetSize(const ARows, AColumns: Integer);
var
  LAlloc: Integer;
begin
  LAlloc := (ARows * AColumns + 3) and not 3;
  if (not FExternal) and (LAlloc > System.Length(FStorage)) then
  begin
    SetLength(FStorage, LAlloc);
    FData := PIdSingleArray(FStorage);
  end;
  FRows := ARows;
  FColumns := AColumns;
  ClearEnd;
end;

procedure TIdMatX.ChangeSize(const ARows, AColumns: Integer; const AMakeZero: Boolean);
var
  LAlloc, LRow, LColumn, LMinRow, LMinColumn: Integer;
  LOld: TArray<Single>;
begin
  LAlloc := (ARows * AColumns + 3) and not 3;
  if (not FExternal) and (LAlloc > System.Length(FStorage)) then
  begin
    LOld := FStorage;
    SetLength(FStorage, 0);
    SetLength(FStorage, LAlloc);
    FData := PIdSingleArray(FStorage);
    if System.Length(LOld) > 0 then
    begin
      LMinRow := FRows;
      if ARows < LMinRow then
        LMinRow := ARows;
      LMinColumn := FColumns;
      if AColumns < LMinColumn then
        LMinColumn := AColumns;
      for LRow := 0 to LMinRow - 1 do
      begin
        for LColumn := 0 to LMinColumn - 1 do
        begin
          FData^[LRow * AColumns + LColumn] := LOld[LRow * FColumns + LColumn];
        end;
      end;
    end;
  end
  else
  begin
    if AColumns < FColumns then
    begin
      LMinRow := FRows;
      if ARows < LMinRow then
        LMinRow := ARows;
      for LRow := 0 to LMinRow - 1 do
      begin
        for LColumn := 0 to AColumns - 1 do
        begin
          FData^[LRow * AColumns + LColumn] := FData^[LRow * FColumns + LColumn];
        end;
      end;
    end
    else if AColumns > FColumns then
    begin
      LMinRow := FRows;
      if ARows < LMinRow then
        LMinRow := ARows;
      for LRow := LMinRow - 1 downto 0 do
      begin
        if AMakeZero then
        begin
          for LColumn := AColumns - 1 downto FColumns do
          begin
            FData^[LRow * AColumns + LColumn] := 0.0;
          end;
        end;
        for LColumn := FColumns - 1 downto 0 do
        begin
          FData^[LRow * AColumns + LColumn] := FData^[LRow * FColumns + LColumn];
        end;
      end;
    end;
    if AMakeZero and (ARows > FRows) then
    begin
      for LColumn := FRows * AColumns to ARows * AColumns - 1 do
      begin
        FData^[LColumn] := 0.0;
      end;
    end;
  end;
  FRows := ARows;
  FColumns := AColumns;
  ClearEnd;
end;

procedure TIdMatX.SetData(const ARows, AColumns: Integer; const AData: PIdSingleArray);
begin
  FStorage := nil;
  FData := AData;
  FExternal := True;
  FRows := ARows;
  FColumns := AColumns;
  ClearEnd;
end;

procedure TIdMatX.SetValues(const ARows, AColumns: Integer; const ASource: PIdSingleArray);
var
  LIndex: Integer;
begin
  SetSize(ARows, AColumns);
  for LIndex := 0 to ARows * AColumns - 1 do
  begin
    FData^[LIndex] := ASource^[LIndex];
  end;
end;

procedure TIdMatX.SetValues(const AM1, AM2: TIdMat3);
var
  LRow, LColumn: Integer;
begin
  SetSize(3, 6);
  for LRow := 0 to 2 do
  begin
    for LColumn := 0 to 2 do
    begin
      FData^[LRow * FColumns + LColumn] := AM1.Rows[LRow][LColumn];
      FData^[LRow * FColumns + LColumn + 3] := AM2.Rows[LRow][LColumn];
    end;
  end;
end;

procedure TIdMatX.SetValues(const AM1, AM2, AM3, AM4: TIdMat3);
var
  LRow, LColumn: Integer;
begin
  SetSize(6, 6);
  for LRow := 0 to 2 do
  begin
    for LColumn := 0 to 2 do
    begin
      FData^[LRow * FColumns + LColumn] := AM1.Rows[LRow][LColumn];
      FData^[LRow * FColumns + LColumn + 3] := AM2.Rows[LRow][LColumn];
      FData^[(LRow + 3) * FColumns + LColumn] := AM3.Rows[LRow][LColumn];
      FData^[(LRow + 3) * FColumns + LColumn + 3] := AM4.Rows[LRow][LColumn];
    end;
  end;
end;

procedure TIdMatX.Assign(const A: TIdMatX);
var
  LIndex: Integer;
begin
  SetSize(A.FRows, A.FColumns);
  for LIndex := 0 to A.FRows * A.FColumns - 1 do
  begin
    FData^[LIndex] := A.FData^[LIndex];
  end;
end;

procedure TIdMatX.MultiplyAssign(const A: Single);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    FData^[LIndex] := FData^[LIndex] * A;
  end;
end;

procedure TIdMatX.MultiplyAssign(const A: TIdMatX);
var
  LProduct: TIdMatX;
begin
  LProduct := Multiply(A);
  try
    Assign(LProduct);
  finally
    LProduct.Free;
  end;
end;

procedure TIdMatX.AddAssign(const A: TIdMatX);
var
  LIndex: Integer;
begin
  Assert((FRows = A.FRows) and (FColumns = A.FColumns));
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    FData^[LIndex] := FData^[LIndex] + A.FData^[LIndex];
  end;
end;

procedure TIdMatX.SubtractAssign(const A: TIdMatX);
var
  LIndex: Integer;
begin
  Assert((FRows = A.FRows) and (FColumns = A.FColumns));
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    FData^[LIndex] := FData^[LIndex] - A.FData^[LIndex];
  end;
end;

function TIdMatX.Multiply(const A: Single): TIdMatX;
var
  LIndex: Integer;
begin
  Result := TIdMatX.Create(FRows, FColumns);
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    Result.FData^[LIndex] := FData^[LIndex] * A;
  end;
end;

function TIdMatX.Multiply(const AVector: TIdVecX): TIdVecX;
begin
  Assert(FColumns = AVector.Size);
  Result := TIdVecX.Create(FRows);
  Multiply(Result, AVector);
end;

function TIdMatX.Multiply(const A: TIdMatX): TIdMatX;
begin
  Assert(FColumns = A.FRows);
  Result := TIdMatX.Create(FRows, A.FColumns);
  Multiply(Result, A);
end;

function TIdMatX.Add(const A: TIdMatX): TIdMatX;
var
  LIndex: Integer;
begin
  Assert((FRows = A.FRows) and (FColumns = A.FColumns));
  Result := TIdMatX.Create(FRows, FColumns);
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    Result.FData^[LIndex] := FData^[LIndex] + A.FData^[LIndex];
  end;
end;

function TIdMatX.Subtract(const A: TIdMatX): TIdMatX;
var
  LIndex: Integer;
begin
  Assert((FRows = A.FRows) and (FColumns = A.FColumns));
  Result := TIdMatX.Create(FRows, FColumns);
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    Result.FData^[LIndex] := FData^[LIndex] - A.FData^[LIndex];
  end;
end;

function TIdMatX.TransposeMultiply(const AVector: TIdVecX): TIdVecX;
begin
  Assert(FRows = AVector.Size);
  Result := TIdVecX.Create(FColumns);
  TransposeMultiply(Result, AVector);
end;

function TIdMatX.TransposeMultiply(const A: TIdMatX): TIdMatX;
begin
  Assert(FRows = A.FRows);
  Result := TIdMatX.Create(FColumns, A.FColumns);
  TransposeMultiply(Result, A);
end;

procedure TIdMatX.Multiply(const ADestination, AVector: TIdVecX);
var
  LRow, LColumn: Integer;
  LSum: Single;
begin
  for LRow := 0 to FRows - 1 do
  begin
    LSum := FData^[LRow * FColumns] * AVector.Data^[0];
    for LColumn := 1 to FColumns - 1 do
    begin
      LSum := LSum + FData^[LRow * FColumns + LColumn] * AVector.Data^[LColumn];
    end;
    ADestination.Data^[LRow] := LSum;
  end;
end;

procedure TIdMatX.MultiplyAdd(const ADestination, AVector: TIdVecX);
var
  LRow, LColumn: Integer;
  LSum: Single;
begin
  for LRow := 0 to FRows - 1 do
  begin
    LSum := FData^[LRow * FColumns] * AVector.Data^[0];
    for LColumn := 1 to FColumns - 1 do
    begin
      LSum := LSum + FData^[LRow * FColumns + LColumn] * AVector.Data^[LColumn];
    end;
    ADestination.Data^[LRow] := ADestination.Data^[LRow] + LSum;
  end;
end;

procedure TIdMatX.MultiplySub(const ADestination, AVector: TIdVecX);
var
  LRow, LColumn: Integer;
  LSum: Single;
begin
  for LRow := 0 to FRows - 1 do
  begin
    LSum := FData^[LRow * FColumns] * AVector.Data^[0];
    for LColumn := 1 to FColumns - 1 do
    begin
      LSum := LSum + FData^[LRow * FColumns + LColumn] * AVector.Data^[LColumn];
    end;
    ADestination.Data^[LRow] := ADestination.Data^[LRow] - LSum;
  end;
end;

procedure TIdMatX.TransposeMultiply(const ADestination, AVector: TIdVecX);
var
  LRow, LColumn: Integer;
  LSum: Single;
begin
  for LColumn := 0 to FColumns - 1 do
  begin
    LSum := FData^[LColumn] * AVector.Data^[0];
    for LRow := 1 to FRows - 1 do
    begin
      LSum := LSum + FData^[LRow * FColumns + LColumn] * AVector.Data^[LRow];
    end;
    ADestination.Data^[LColumn] := LSum;
  end;
end;

procedure TIdMatX.TransposeMultiplyAdd(const ADestination, AVector: TIdVecX);
var
  LRow, LColumn: Integer;
  LSum: Single;
begin
  for LColumn := 0 to FColumns - 1 do
  begin
    LSum := FData^[LColumn] * AVector.Data^[0];
    for LRow := 1 to FRows - 1 do
    begin
      LSum := LSum + FData^[LRow * FColumns + LColumn] * AVector.Data^[LRow];
    end;
    ADestination.Data^[LColumn] := ADestination.Data^[LColumn] + LSum;
  end;
end;

procedure TIdMatX.TransposeMultiplySub(const ADestination, AVector: TIdVecX);
var
  LRow, LColumn: Integer;
  LSum: Single;
begin
  for LColumn := 0 to FColumns - 1 do
  begin
    LSum := FData^[LColumn] * AVector.Data^[0];
    for LRow := 1 to FRows - 1 do
    begin
      LSum := LSum + FData^[LRow * FColumns + LColumn] * AVector.Data^[LRow];
    end;
    ADestination.Data^[LColumn] := ADestination.Data^[LColumn] - LSum;
  end;
end;

procedure TIdMatX.Multiply(const ADestination, A: TIdMatX);
var
  LRow, LColumn, LK: Integer;
  LSum: Double;
begin
  Assert(FColumns = A.FRows);
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to A.FColumns - 1 do
    begin
      LSum := FData^[LRow * FColumns] * A.FData^[LColumn];
      for LK := 1 to FColumns - 1 do
      begin
        LSum := LSum + FData^[LRow * FColumns + LK] * A.FData^[LK * A.FColumns + LColumn];
      end;
      ADestination.FData^[LRow * A.FColumns + LColumn] := LSum;
    end;
  end;
end;

procedure TIdMatX.TransposeMultiply(const ADestination, A: TIdMatX);
var
  LRow, LColumn, LK: Integer;
  LSum: Double;
begin
  Assert(FRows = A.FRows);
  for LRow := 0 to FColumns - 1 do
  begin
    for LColumn := 0 to A.FColumns - 1 do
    begin
      LSum := FData^[LRow] * A.FData^[LColumn];
      for LK := 1 to FRows - 1 do
      begin
        LSum := LSum + FData^[LK * FColumns + LRow] * A.FData^[LK * A.FColumns + LColumn];
      end;
      ADestination.FData^[LRow * A.FColumns + LColumn] := LSum;
    end;
  end;
end;

function TIdMatX.Compare(const A: TIdMatX): Boolean;
var
  LIndex: Integer;
begin
  Assert((FRows = A.FRows) and (FColumns = A.FColumns));
  Result := True;
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    if FData^[LIndex] <> A.FData^[LIndex] then
      Exit(False);
  end;
end;

function TIdMatX.Compare(const A: TIdMatX; const AEpsilon: Single): Boolean;
var
  LIndex: Integer;
begin
  Assert((FRows = A.FRows) and (FColumns = A.FColumns));
  Result := True;
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    if TIdMath.Fabs(FData^[LIndex] - A.FData^[LIndex]) > AEpsilon then
      Exit(False);
  end;
end;

procedure TIdMatX.Zero;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    FData^[LIndex] := 0.0;
  end;
end;

procedure TIdMatX.Zero(const ARows, AColumns: Integer);
begin
  SetSize(ARows, AColumns);
  Zero;
end;

procedure TIdMatX.Identity;
var
  LIndex: Integer;
begin
  Assert(FRows = FColumns);
  Zero;
  for LIndex := 0 to FRows - 1 do
  begin
    FData^[LIndex * FColumns + LIndex] := 1.0;
  end;
end;

procedure TIdMatX.Identity(const ARows, AColumns: Integer);
begin
  Assert(ARows = AColumns);
  SetSize(ARows, AColumns);
  Identity;
end;

procedure TIdMatX.Diag(const AVector: TIdVecX);
var
  LIndex: Integer;
begin
  Zero(AVector.Size, AVector.Size);
  for LIndex := 0 to AVector.Size - 1 do
  begin
    FData^[LIndex * FColumns + LIndex] := AVector[LIndex];
  end;
end;

procedure TIdMatX.Random(const ASeed: Integer; const ALower, AUpper: Single);
var
  LIndex: Integer;
  LRange: Single;
  LRandom: TIdRandom;
begin
  LRandom := TIdRandom.Create(ASeed);
  LRange := AUpper - ALower;
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    FData^[LIndex] := ALower + LRandom.RandomFloat * LRange;
  end;
end;

procedure TIdMatX.Random(const ARows, AColumns, ASeed: Integer; const ALower, AUpper: Single);
begin
  SetSize(ARows, AColumns);
  Random(ASeed, ALower, AUpper);
end;

procedure TIdMatX.Negate;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    FData^[LIndex] := -FData^[LIndex];
  end;
end;

procedure TIdMatX.Clamp(const AMin, AMax: Single);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    if FData^[LIndex] < AMin then
      FData^[LIndex] := AMin
    else if FData^[LIndex] > AMax then
      FData^[LIndex] := AMax;
  end;
end;

procedure TIdMatX.SwapRows(const AFirst, ASecond: Integer);
var
  LColumn: Integer;
  LTemp: Single;
begin
  for LColumn := 0 to FColumns - 1 do
  begin
    LTemp := FData^[AFirst * FColumns + LColumn];
    FData^[AFirst * FColumns + LColumn] := FData^[ASecond * FColumns + LColumn];
    FData^[ASecond * FColumns + LColumn] := LTemp;
  end;
end;

procedure TIdMatX.SwapColumns(const AFirst, ASecond: Integer);
var
  LRow: Integer;
  LTemp: Single;
begin
  for LRow := 0 to FRows - 1 do
  begin
    LTemp := FData^[LRow * FColumns + AFirst];
    FData^[LRow * FColumns + AFirst] := FData^[LRow * FColumns + ASecond];
    FData^[LRow * FColumns + ASecond] := LTemp;
  end;
end;

procedure TIdMatX.SwapRowsColumns(const AFirst, ASecond: Integer);
begin
  SwapRows(AFirst, ASecond);
  SwapColumns(AFirst, ASecond);
end;

procedure TIdMatX.RemoveRow(const ARow: Integer);
var
  LRow, LColumn: Integer;
begin
  Assert(ARow < FRows);
  Dec(FRows);
  for LRow := ARow to FRows - 1 do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      FData^[LRow * FColumns + LColumn] := FData^[(LRow + 1) * FColumns + LColumn];
    end;
  end;
end;

procedure TIdMatX.RemoveColumn(const AColumn: Integer);
var
  LRow, LColumn, LOldColumns: Integer;
begin
  Assert(AColumn < FColumns);
  LOldColumns := FColumns;
  Dec(FColumns);
  // the rows are packed again front to back; the last row only has the columns after the removed one
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      if LColumn >= AColumn then
        FData^[LRow * FColumns + LColumn] := FData^[LRow * LOldColumns + LColumn + 1]
      else if LRow > 0 then
        FData^[LRow * FColumns + LColumn] := FData^[LRow * LOldColumns + LColumn];
    end;
  end;
end;

procedure TIdMatX.RemoveRowColumn(const AIndex: Integer);
var
  LRow, LColumn, LOldColumns: Integer;
  LCopy: TArray<Single>;
begin
  Assert((AIndex < FRows) and (AIndex < FColumns));
  LOldColumns := FColumns;
  SetLength(LCopy, FRows * FColumns);
  for LRow := 0 to FRows * FColumns - 1 do
  begin
    LCopy[LRow] := FData^[LRow];
  end;
  Dec(FRows);
  Dec(FColumns);
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      FData^[LRow * FColumns + LColumn] := LCopy[(LRow + Ord(LRow >= AIndex)) * LOldColumns +
        LColumn + Ord(LColumn >= AIndex)];
    end;
  end;
end;

procedure TIdMatX.ClearUpperTriangle;
var
  LRow, LColumn: Integer;
begin
  Assert(FRows = FColumns);
  for LRow := FRows - 2 downto 0 do
  begin
    for LColumn := LRow + 1 to FColumns - 1 do
    begin
      FData^[LRow * FColumns + LColumn] := 0.0;
    end;
  end;
end;

procedure TIdMatX.ClearLowerTriangle;
var
  LRow, LColumn: Integer;
begin
  Assert(FRows = FColumns);
  for LRow := 1 to FRows - 1 do
  begin
    for LColumn := 0 to LRow - 1 do
    begin
      FData^[LRow * FColumns + LColumn] := 0.0;
    end;
  end;
end;

procedure TIdMatX.SquareSubMatrix(const AMatrix: TIdMatX; const ASize: Integer);
var
  LRow, LColumn: Integer;
begin
  Assert((ASize <= AMatrix.FRows) and (ASize <= AMatrix.FColumns));
  SetSize(ASize, ASize);
  for LRow := 0 to ASize - 1 do
  begin
    for LColumn := 0 to ASize - 1 do
    begin
      FData^[LRow * FColumns + LColumn] := AMatrix.FData^[LRow * AMatrix.FColumns + LColumn];
    end;
  end;
end;

function TIdMatX.MaxDifference(const AMatrix: TIdMatX): Single;
var
  LRow, LColumn: Integer;
  LDifference: Single;
begin
  Assert((FRows = AMatrix.FRows) and (FColumns = AMatrix.FColumns));
  Result := -1.0;
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      LDifference := TIdMath.Fabs(FData^[LRow * FColumns + LColumn] - AMatrix[LRow, LColumn]);
      if (Result < 0.0) or (LDifference > Result) then
        Result := LDifference;
    end;
  end;
end;

function TIdMatX.IsSquare: Boolean;
begin
  Result := FRows = FColumns;
end;

function TIdMatX.IsZero(const AEpsilon: Single): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    if TIdMath.Fabs(FData^[LIndex]) > AEpsilon then
      Exit(False);
  end;
end;

function TIdMatX.IsIdentity(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
  LExpected: Single;
begin
  Assert(FRows = FColumns);
  Result := True;
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      LExpected := Ord(LRow = LColumn);
      if TIdMath.Fabs(FData^[LRow * FColumns + LColumn] - LExpected) > AEpsilon then
        Exit(False);
    end;
  end;
end;

function TIdMatX.IsDiagonal(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
begin
  Assert(FRows = FColumns);
  Result := True;
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      if (LRow <> LColumn) and (TIdMath.Fabs(FData^[LRow * FColumns + LColumn]) > AEpsilon) then
        Exit(False);
    end;
  end;
end;

function TIdMatX.IsTriDiagonal(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
begin
  Result := True;
  if FRows <> FColumns then
    Exit(False);
  for LRow := 0 to FRows - 3 do
  begin
    for LColumn := LRow + 2 to FColumns - 1 do
    begin
      if TIdMath.Fabs(FData^[LRow * FColumns + LColumn]) > AEpsilon then
        Exit(False);
      if TIdMath.Fabs(FData^[LColumn * FColumns + LRow]) > AEpsilon then
        Exit(False);
    end;
  end;
end;

function TIdMatX.IsSymmetric(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
begin
  Result := True;
  if FRows <> FColumns then
    Exit(False);
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      if TIdMath.Fabs(FData^[LRow * FColumns + LColumn] - FData^[LColumn * FColumns + LRow]) >
        AEpsilon then
        Exit(False);
    end;
  end;
end;

function TIdMatX.IsOrthogonal(const AEpsilon: Single): Boolean;
var
  LRow, LColumn, LK: Integer;
  LSum: Single;
begin
  Result := True;
  if not IsSquare then
    Exit(False);
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      LSum := FData^[LRow * FColumns] * FData^[LColumn] - Ord(LRow = LColumn);
      for LK := 1 to FColumns - 1 do
      begin
        LSum := LSum + FData^[LRow * FColumns + LK] * FData^[LK * FColumns + LColumn];
      end;
      if TIdMath.Fabs(LSum) > AEpsilon then
        Exit(False);
    end;
  end;
end;

function TIdMatX.IsOrthonormal(const AEpsilon: Single): Boolean;
var
  LRow, LColumn, LK, LOffset: Integer;
  LSum: Single;
begin
  Result := True;
  if not IsSquare then
    Exit(False);
  LRow := 0;
  while LRow < FRows do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      LSum := FData^[LRow * FColumns] * FData^[LColumn] - Ord(LRow = LColumn);
      for LK := 1 to FColumns - 1 do
      begin
        LSum := LSum + FData^[LRow * FColumns + LK] * FData^[LK * FColumns + LColumn];
      end;
      if TIdMath.Fabs(LSum) > AEpsilon then
        Exit(False);
    end;
    // the C++ computes the column norm with the same counter as the outer loop (conserved):
    // ptr2 walks down column i, and ptr2[i] is read with the loop counter itself
    LOffset := LRow;
    LSum := FData^[LOffset] * FData^[LOffset] - 1.0;
    LRow := 1;
    while LRow < FRows do
    begin
      Inc(LOffset, FColumns);
      LSum := LSum + FData^[LOffset + LRow] * FData^[LOffset + LRow];
      Inc(LRow);
    end;
    if TIdMath.Fabs(LSum) > AEpsilon then
      Exit(False);
    Inc(LRow);
  end;
end;

function TIdMatX.IsPMatrix(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
  LFactor: Single;
  LMinor: TIdMatX;
begin
  if not IsSquare then
    Exit(False);
  if FRows <= 0 then
    Exit(True);
  if FData^[0] <= AEpsilon then
    Exit(False);
  if FRows <= 1 then
    Exit(True);
  LMinor := TIdMatX.Create(FRows - 1, FColumns - 1);
  try
    for LRow := 1 to FRows - 1 do
    begin
      for LColumn := 1 to FColumns - 1 do
      begin
        LMinor[LRow - 1, LColumn - 1] := FData^[LRow * FColumns + LColumn];
      end;
    end;
    if not LMinor.IsPMatrix(AEpsilon) then
      Exit(False);
    for LRow := 1 to FRows - 1 do
    begin
      LFactor := FData^[LRow * FColumns] / FData^[0];
      for LColumn := 1 to FColumns - 1 do
      begin
        LMinor[LRow - 1, LColumn - 1] := FData^[LRow * FColumns + LColumn] - LFactor * FData^[LColumn];
      end;
    end;
    Result := LMinor.IsPMatrix(AEpsilon);
  finally
    LMinor.Free;
  end;
end;

function TIdMatX.IsZMatrix(const AEpsilon: Single): Boolean;
var
  LRow, LColumn: Integer;
begin
  if not IsSquare then
    Exit(False);
  Result := True;
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      if (FData^[LRow * FColumns + LColumn] > AEpsilon) and (LRow <> LColumn) then
        Exit(False);
    end;
  end;
end;

function TIdMatX.IsPositiveDefinite(const AEpsilon: Single): Boolean;
var
  LRow, LColumn, LK: Integer;
  LInverse, LScale: Single;
  LCopy: TIdMatX;
begin
  if not IsSquare then
    Exit(False);
  LCopy := TIdMatX.Create;
  try
    LCopy.Assign(Self);
    for LRow := 0 to FRows - 1 do
    begin
      for LColumn := 0 to FColumns - 1 do
      begin
        LCopy[LRow, LColumn] := LCopy[LRow, LColumn] + FData^[LColumn * FColumns + LRow];
      end;
    end;
    for LRow := 0 to FRows - 1 do
    begin
      for LColumn := LRow to FColumns - 1 do
      begin
        if LCopy[LColumn, LColumn] <= AEpsilon then
          Exit(False);
      end;
      LInverse := 1.0 / LCopy[LRow, LRow];
      for LColumn := LRow + 1 to FColumns - 1 do
      begin
        LScale := LInverse * LCopy[LColumn, LRow];
        LCopy[LColumn, LRow] := 0.0;
        for LK := LRow + 1 to FRows - 1 do
        begin
          LCopy[LColumn, LK] := LCopy[LColumn, LK] - LScale * LCopy[LRow, LK];
        end;
      end;
    end;
    Result := True;
  finally
    LCopy.Free;
  end;
end;

function TIdMatX.IsPositiveSemiDefinite(const AEpsilon: Single): Boolean;
var
  LRow, LColumn, LK: Integer;
  LInverse, LScale: Single;
  LCopy: TIdMatX;
begin
  if not IsSquare then
    Exit(False);
  LCopy := TIdMatX.Create;
  try
    LCopy.Assign(Self);
    for LRow := 0 to FRows - 1 do
    begin
      for LColumn := 0 to FColumns - 1 do
      begin
        LCopy[LRow, LColumn] := LCopy[LRow, LColumn] + FData^[LColumn * FColumns + LRow];
      end;
    end;
    for LRow := 0 to FRows - 1 do
    begin
      for LColumn := LRow to FColumns - 1 do
      begin
        if LCopy[LColumn, LColumn] < -AEpsilon then
          Exit(False);
        if LCopy[LColumn, LColumn] > AEpsilon then
          Continue;
        for LK := 0 to FRows - 1 do
        begin
          if TIdMath.Fabs(LCopy[LK, LColumn]) > AEpsilon then
            Exit(False);
          if TIdMath.Fabs(LCopy[LColumn, LK]) > AEpsilon then
            Exit(False);
        end;
      end;
      if LCopy[LRow, LRow] <= AEpsilon then
        Continue;
      LInverse := 1.0 / LCopy[LRow, LRow];
      for LColumn := LRow + 1 to FColumns - 1 do
      begin
        LScale := LInverse * LCopy[LColumn, LRow];
        LCopy[LColumn, LRow] := 0.0;
        for LK := LRow + 1 to FRows - 1 do
        begin
          LCopy[LColumn, LK] := LCopy[LColumn, LK] - LScale * LCopy[LRow, LK];
        end;
      end;
    end;
    Result := True;
  finally
    LCopy.Free;
  end;
end;

function TIdMatX.Trace: Single;
var
  LIndex: Integer;
begin
  Assert(FRows = FColumns);
  Result := 0.0;
  for LIndex := 0 to FRows - 1 do
  begin
    Result := Result + FData^[LIndex * FRows + LIndex];
  end;
end;

function TIdMatX.Determinant: Single;
var
  LMat2: TIdMat2;
  LMat3: TIdMat3;
  LMat4: TIdMat4;
  LMat5: TIdMat5;
  LMat6: TIdMat6;
begin
  Assert(FRows = FColumns);
  case FRows of
    1:
      Result := FData^[0];
    2:
      begin
        Move(FData^, LMat2, SizeOf(LMat2));
        Result := LMat2.Determinant;
      end;
    3:
      begin
        Move(FData^, LMat3, SizeOf(LMat3));
        Result := LMat3.Determinant;
      end;
    4:
      begin
        Move(FData^, LMat4, SizeOf(LMat4));
        Result := LMat4.Determinant;
      end;
    5:
      begin
        Move(FData^, LMat5, SizeOf(LMat5));
        Result := LMat5.Determinant;
      end;
    6:
      begin
        Move(FData^, LMat6, SizeOf(LMat6));
        Result := LMat6.Determinant;
      end;
  else
    Result := DeterminantGeneric;
  end;
end;

function TIdMatX.DeterminantGeneric: Single;
var
  LIndex: TArray<Integer>;
  LCopy: TIdMatX;
  LDeterminant: Single;
begin
  SetLength(LIndex, FRows);
  LCopy := TIdMatX.Create;
  try
    LCopy.Assign(Self);
    if not LCopy.LuFactor(PIdIntegerArray(LIndex), @LDeterminant) then
      Exit(0.0);
    Result := LDeterminant;
  finally
    LCopy.Free;
  end;
end;

function TIdMatX.Transpose: TIdMatX;
var
  LRow, LColumn: Integer;
begin
  Result := TIdMatX.Create(FColumns, FRows);
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to FColumns - 1 do
    begin
      Result.FData^[LColumn * Result.FColumns + LRow] := FData^[LRow * FColumns + LColumn];
    end;
  end;
end;

procedure TIdMatX.TransposeSelf;
var
  LTransposed: TIdMatX;
begin
  LTransposed := Transpose;
  try
    Assign(LTransposed);
  finally
    LTransposed.Free;
  end;
end;

function TIdMatX.Inverse: TIdMatX;
begin
  Result := TIdMatX.Create(FRows, FColumns);
  Result.Assign(Self);
  Result.InverseSelf;
end;

function TIdMatX.InverseSelf: Boolean;
var
  LMat2: TIdMat2;
  LMat3: TIdMat3;
  LMat4: TIdMat4;
  LMat5: TIdMat5;
  LMat6: TIdMat6;
begin
  Assert(FRows = FColumns);
  case FRows of
    1:
      begin
        if TIdMath.Fabs(FData^[0]) < MAT_INVERSE_EPSILON then
          Exit(False);
        FData^[0] := 1.0 / FData^[0];
        Result := True;
      end;
    2:
      begin
        Move(FData^, LMat2, SizeOf(LMat2));
        Result := LMat2.InverseSelf;
        Move(LMat2, FData^, SizeOf(LMat2));
      end;
    3:
      begin
        Move(FData^, LMat3, SizeOf(LMat3));
        Result := LMat3.InverseSelf;
        Move(LMat3, FData^, SizeOf(LMat3));
      end;
    4:
      begin
        Move(FData^, LMat4, SizeOf(LMat4));
        Result := LMat4.InverseSelf;
        Move(LMat4, FData^, SizeOf(LMat4));
      end;
    5:
      begin
        Move(FData^, LMat5, SizeOf(LMat5));
        Result := LMat5.InverseSelf;
        Move(LMat5, FData^, SizeOf(LMat5));
      end;
    6:
      begin
        Move(FData^, LMat6, SizeOf(LMat6));
        Result := LMat6.InverseSelf;
        Move(LMat6, FData^, SizeOf(LMat6));
      end;
  else
    Result := InverseSelfGeneric;
  end;
end;

function TIdMatX.InverseSelfGeneric: Boolean;
var
  LRow, LColumn: Integer;
  LIndex: TArray<Integer>;
  LCopy: TIdMatX;
  LX, LB: TIdVecX;
begin
  SetLength(LIndex, FRows);
  LCopy := TIdMatX.Create;
  LX := TIdVecX.Create(FRows);
  LB := TIdVecX.Create(FRows);
  try
    LCopy.Assign(Self);
    if not LCopy.LuFactor(PIdIntegerArray(LIndex)) then
      Exit(False);
    LB.Zero;
    for LRow := 0 to FRows - 1 do
    begin
      LB[LRow] := 1.0;
      LCopy.LuSolve(LX, LB, PIdIntegerArray(LIndex));
      for LColumn := 0 to FRows - 1 do
      begin
        FData^[LColumn * FColumns + LRow] := LX[LColumn];
      end;
      LB[LRow] := 0.0;
    end;
    Result := True;
  finally
    LB.Free;
    LX.Free;
    LCopy.Free;
  end;
end;

function TIdMatX.InverseFast: TIdMatX;
begin
  Result := TIdMatX.Create(FRows, FColumns);
  Result.Assign(Self);
  Result.InverseFastSelf;
end;

function TIdMatX.InverseFastSelf: Boolean;
var
  LMat2: TIdMat2;
  LMat3: TIdMat3;
  LMat4: TIdMat4;
  LMat5: TIdMat5;
  LMat6: TIdMat6;
begin
  Assert(FRows = FColumns);
  case FRows of
    1:
      begin
        if TIdMath.Fabs(FData^[0]) < MAT_INVERSE_EPSILON then
          Exit(False);
        FData^[0] := 1.0 / FData^[0];
        Result := True;
      end;
    2:
      begin
        Move(FData^, LMat2, SizeOf(LMat2));
        Result := LMat2.InverseFastSelf;
        Move(LMat2, FData^, SizeOf(LMat2));
      end;
    3:
      begin
        Move(FData^, LMat3, SizeOf(LMat3));
        Result := LMat3.InverseFastSelf;
        Move(LMat3, FData^, SizeOf(LMat3));
      end;
    4:
      begin
        Move(FData^, LMat4, SizeOf(LMat4));
        Result := LMat4.InverseFastSelf;
        Move(LMat4, FData^, SizeOf(LMat4));
      end;
    5:
      begin
        Move(FData^, LMat5, SizeOf(LMat5));
        Result := LMat5.InverseFastSelf;
        Move(LMat5, FData^, SizeOf(LMat5));
      end;
    6:
      begin
        Move(FData^, LMat6, SizeOf(LMat6));
        Result := LMat6.InverseFastSelf;
        Move(LMat6, FData^, SizeOf(LMat6));
      end;
  else
    Result := InverseSelfGeneric;
  end;
end;

function TIdMatX.LowerTriangularInverse: Boolean;
var
  LRow, LColumn, LK: Integer;
  LDiagonal, LSum: Double;
begin
  for LRow := 0 to FRows - 1 do
  begin
    LDiagonal := FData^[LRow * FColumns + LRow];
    if LDiagonal = 0.0 then
      Exit(False);
    LDiagonal := 1.0 / LDiagonal;
    FData^[LRow * FColumns + LRow] := LDiagonal;
    for LColumn := 0 to LRow - 1 do
    begin
      LSum := 0.0;
      for LK := LColumn to LRow - 1 do
      begin
        LSum := LSum - FData^[LRow * FColumns + LK] * FData^[LK * FColumns + LColumn];
      end;
      FData^[LRow * FColumns + LColumn] := LSum * LDiagonal;
    end;
  end;
  Result := True;
end;

function TIdMatX.UpperTriangularInverse: Boolean;
var
  LRow, LColumn, LK: Integer;
  LDiagonal, LSum: Double;
begin
  for LRow := FRows - 1 downto 0 do
  begin
    LDiagonal := FData^[LRow * FColumns + LRow];
    if LDiagonal = 0.0 then
      Exit(False);
    LDiagonal := 1.0 / LDiagonal;
    FData^[LRow * FColumns + LRow] := LDiagonal;
    for LColumn := FRows - 1 downto LRow + 1 do
    begin
      LSum := 0.0;
      for LK := LColumn downto LRow + 1 do
      begin
        LSum := LSum - FData^[LRow * FColumns + LK] * FData^[LK * FColumns + LColumn];
      end;
      FData^[LRow * FColumns + LColumn] := LSum * LDiagonal;
    end;
  end;
  Result := True;
end;

function TIdMatX.GetDimension: Integer;
begin
  Result := FRows * FColumns;
end;

function TIdMatX.GetSubVec6(const ARow: Integer): TIdVec6;
var
  LIndex: Integer;
begin
  Assert((FColumns >= 6) and (ARow >= 0) and (ARow < FRows));
  for LIndex := 0 to 5 do
  begin
    Result.P[LIndex] := FData^[ARow * FColumns + LIndex];
  end;
end;

procedure TIdMatX.SetSubVec6(const ARow: Integer; const AValue: TIdVec6);
var
  LIndex: Integer;
begin
  Assert((FColumns >= 6) and (ARow >= 0) and (ARow < FRows));
  for LIndex := 0 to 5 do
  begin
    FData^[ARow * FColumns + LIndex] := AValue.P[LIndex];
  end;
end;

function TIdMatX.SubVecX(const ARow: Integer): TIdVecX;
begin
  Assert((ARow >= 0) and (ARow < FRows));
  Result := TIdVecX.Create(FColumns, PIdSingleArray(@FData^[ARow * FColumns]));
end;

function TIdMatX.ToString(const APrecision: Integer): AnsiString;
var
  LValues: TArray<Single>;
  LIndex: Integer;
begin
  SetLength(LValues, FRows * FColumns);
  for LIndex := 0 to FRows * FColumns - 1 do
  begin
    LValues[LIndex] := FData^[LIndex];
  end;
  Result := TIdStrings.FloatArrayToString(LValues, APrecision);
end;

procedure TIdMatX.UpdateRankOne(const AV, AW: TIdVecX; const AAlpha: Single);
var
  LRow, LColumn: Integer;
  LScale: Single;
begin
  Assert((AV.Size >= FRows) and (AW.Size >= FColumns));
  for LRow := 0 to FRows - 1 do
  begin
    LScale := AAlpha * AV[LRow];
    for LColumn := 0 to FColumns - 1 do
    begin
      FData^[LRow * FColumns + LColumn] := FData^[LRow * FColumns + LColumn] + LScale * AW[LColumn];
    end;
  end;
end;

procedure TIdMatX.UpdateRankOneSymmetric(const AV: TIdVecX; const AAlpha: Single);
var
  LRow, LColumn: Integer;
  LScale: Single;
begin
  Assert((FRows = FColumns) and (AV.Size >= FRows));
  for LRow := 0 to FRows - 1 do
  begin
    LScale := AAlpha * AV[LRow];
    for LColumn := 0 to FColumns - 1 do
    begin
      FData^[LRow * FColumns + LColumn] := FData^[LRow * FColumns + LColumn] + LScale * AV[LColumn];
    end;
  end;
end;

procedure TIdMatX.UpdateRowColumn(const AV, AW: TIdVecX; const ARow: Integer);
var
  LIndex: Integer;
begin
  Assert(AW[ARow] = 0.0);
  Assert((AV.Size >= FColumns) and (AW.Size >= FRows));
  for LIndex := 0 to FRows - 1 do
  begin
    FData^[LIndex * FColumns + ARow] := FData^[LIndex * FColumns + ARow] + AV[LIndex];
  end;
  for LIndex := 0 to FColumns - 1 do
  begin
    FData^[ARow * FColumns + LIndex] := FData^[ARow * FColumns + LIndex] + AW[LIndex];
  end;
end;

procedure TIdMatX.UpdateRowColumnSymmetric(const AV: TIdVecX; const ARow: Integer);
var
  LIndex: Integer;
begin
  Assert((FRows = FColumns) and (AV.Size >= FRows));
  for LIndex := 0 to ARow - 1 do
  begin
    FData^[LIndex * FColumns + ARow] := FData^[LIndex * FColumns + ARow] + AV[LIndex];
    FData^[ARow * FColumns + LIndex] := FData^[ARow * FColumns + LIndex] + AV[LIndex];
  end;
  FData^[ARow * FColumns + ARow] := FData^[ARow * FColumns + ARow] + AV[ARow];
  for LIndex := ARow + 1 to FRows - 1 do
  begin
    FData^[LIndex * FColumns + ARow] := FData^[LIndex * FColumns + ARow] + AV[LIndex];
    FData^[ARow * FColumns + LIndex] := FData^[ARow * FColumns + LIndex] + AV[LIndex];
  end;
end;

procedure TIdMatX.UpdateIncrement(const AV, AW: TIdVecX);
var
  LIndex: Integer;
begin
  Assert((FRows = FColumns) and (AV.Size >= FRows + 1) and (AW.Size >= FColumns + 1));
  ChangeSize(FRows + 1, FColumns + 1, False);
  for LIndex := 0 to FRows - 1 do
  begin
    FData^[LIndex * FColumns + FColumns - 1] := AV[LIndex];
  end;
  for LIndex := 0 to FColumns - 2 do
  begin
    FData^[(FRows - 1) * FColumns + LIndex] := AW[LIndex];
  end;
end;

procedure TIdMatX.UpdateIncrementSymmetric(const AV: TIdVecX);
var
  LIndex: Integer;
begin
  Assert((FRows = FColumns) and (AV.Size >= FRows + 1));
  ChangeSize(FRows + 1, FColumns + 1, False);
  for LIndex := 0 to FRows - 2 do
  begin
    FData^[LIndex * FColumns + FColumns - 1] := AV[LIndex];
  end;
  for LIndex := 0 to FColumns - 1 do
  begin
    FData^[(FRows - 1) * FColumns + LIndex] := AV[LIndex];
  end;
end;

procedure TIdMatX.UpdateDecrement(const ARow: Integer);
begin
  RemoveRowColumn(ARow);
end;

function TIdMatX.LuFactor(const AIndex: PIdIntegerArray; const ADeterminant: PSingle): Boolean;
var
  LRow, LColumn, LK, LNewRow, LMin: Integer;
  LPivot, LTemp, LScale, LSign: Double;
begin
  if Assigned(AIndex) then
  begin
    for LRow := 0 to FRows - 1 do
    begin
      AIndex^[LRow] := LRow;
    end;
  end;
  LSign := 1.0;
  LMin := FRows;
  if FColumns < LMin then
    LMin := FColumns;
  for LRow := 0 to LMin - 1 do
  begin
    LNewRow := LRow;
    LPivot := TIdMath.Fabs(FData^[LRow * FColumns + LRow]);
    if Assigned(AIndex) then
    begin
      // find the largest absolute pivot
      for LColumn := LRow + 1 to FRows - 1 do
      begin
        LTemp := TIdMath.Fabs(FData^[LColumn * FColumns + LRow]);
        if LTemp > LPivot then
        begin
          LNewRow := LColumn;
          LPivot := LTemp;
        end;
      end;
    end;
    if LPivot = 0.0 then
      Exit(False);
    if LNewRow <> LRow then
    begin
      LSign := -LSign;
      LK := AIndex^[LRow];
      AIndex^[LRow] := AIndex^[LNewRow];
      AIndex^[LNewRow] := LK;
      for LColumn := 0 to FColumns - 1 do
      begin
        LTemp := FData^[LNewRow * FColumns + LColumn];
        FData^[LNewRow * FColumns + LColumn] := FData^[LRow * FColumns + LColumn];
        FData^[LRow * FColumns + LColumn] := LTemp;
      end;
    end;
    if LRow < FRows then
    begin
      LScale := 1.0 / FData^[LRow * FColumns + LRow];
      for LColumn := LRow + 1 to FRows - 1 do
      begin
        FData^[LColumn * FColumns + LRow] := FData^[LColumn * FColumns + LRow] * LScale;
      end;
    end;
    if LRow < LMin - 1 then
    begin
      for LColumn := LRow + 1 to FRows - 1 do
      begin
        LScale := FData^[LColumn * FColumns + LRow];
        for LK := LRow + 1 to FColumns - 1 do
        begin
          FData^[LColumn * FColumns + LK] := FData^[LColumn * FColumns + LK] -
            LScale * FData^[LRow * FColumns + LK];
        end;
      end;
    end;
  end;
  if Assigned(ADeterminant) then
  begin
    for LRow := 0 to FRows - 1 do
    begin
      LSign := LSign * FData^[LRow * FColumns + LRow];
    end;
    ADeterminant^ := LSign;
  end;
  Result := True;
end;

procedure TIdMatX.LuSolve(const AX, AB: TIdVecX; const AIndex: PIdIntegerArray);
var
  LRow, LColumn: Integer;
  LSum: Double;
begin
  Assert((AX.Size = FColumns) and (AB.Size = FRows));
  // solve L
  for LRow := 0 to FRows - 1 do
  begin
    if Assigned(AIndex) then
      LSum := AB[AIndex^[LRow]]
    else
      LSum := AB[LRow];
    for LColumn := 0 to LRow - 1 do
    begin
      LSum := LSum - FData^[LRow * FColumns + LColumn] * AX[LColumn];
    end;
    AX[LRow] := LSum;
  end;
  // solve U
  for LRow := FRows - 1 downto 0 do
  begin
    LSum := AX[LRow];
    for LColumn := LRow + 1 to FRows - 1 do
    begin
      LSum := LSum - FData^[LRow * FColumns + LColumn] * AX[LColumn];
    end;
    AX[LRow] := LSum / FData^[LRow * FColumns + LRow];
  end;
end;

procedure TIdMatX.LuInverse(const AInverse: TIdMatX; const AIndex: PIdIntegerArray);
var
  LRow, LColumn: Integer;
  LX, LB: TIdVecX;
begin
  Assert(FRows = FColumns);
  LX := TIdVecX.Create(FRows);
  LB := TIdVecX.Create(FRows);
  try
    LB.Zero;
    AInverse.SetSize(FRows, FColumns);
    for LRow := 0 to FRows - 1 do
    begin
      LB[LRow] := 1.0;
      LuSolve(LX, LB, AIndex);
      for LColumn := 0 to FRows - 1 do
      begin
        AInverse[LColumn, LRow] := LX[LColumn];
      end;
      LB[LRow] := 0.0;
    end;
  finally
    LB.Free;
    LX.Free;
  end;
end;

procedure TIdMatX.LuUnpackFactors(const AL, AU: TIdMatX);
var
  LRow, LColumn: Integer;
begin
  AL.Zero(FRows, FColumns);
  AU.Zero(FRows, FColumns);
  for LRow := 0 to FRows - 1 do
  begin
    for LColumn := 0 to LRow - 1 do
    begin
      AL[LRow, LColumn] := FData^[LRow * FColumns + LColumn];
    end;
    AL[LRow, LRow] := 1.0;
    for LColumn := LRow to FColumns - 1 do
    begin
      AU[LRow, LColumn] := FData^[LRow * FColumns + LColumn];
    end;
  end;
end;

procedure TIdMatX.LuMultiplyFactors(const AMatrix: TIdMatX; const AIndex: PIdIntegerArray);
var
  LRow, LPermuted, LColumn, LK: Integer;
  LSum: Double;
begin
  AMatrix.SetSize(FRows, FColumns);
  for LRow := 0 to FRows - 1 do
  begin
    if Assigned(AIndex) then
      LPermuted := AIndex^[LRow]
    else
      LPermuted := LRow;
    for LColumn := 0 to FColumns - 1 do
    begin
      if LColumn >= LRow then
        LSum := FData^[LRow * FColumns + LColumn]
      else
        LSum := 0.0;
      LK := 0;
      while (LK <= LColumn) and (LK < LRow) do
      begin
        LSum := LSum + FData^[LRow * FColumns + LK] * FData^[LK * FColumns + LColumn];
        Inc(LK);
      end;
      AMatrix[LPermuted, LColumn] := LSum;
    end;
  end;
end;

end.
