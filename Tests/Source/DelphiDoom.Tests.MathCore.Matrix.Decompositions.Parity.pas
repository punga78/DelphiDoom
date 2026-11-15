{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of MathCore - parity with the C++ idLib of the LU         }
{  updates, the QR and SVD factorizations and the general eigenvalue solver    }
{  of idMatX                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Matrix.Decompositions.Parity;

{$Q-}
{$R-}

interface

uses
  System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the real idlib\math of Doom 3 (Tests\Data\MathCore\matx2.golden.txt, 222 lines
  ///   written by the C++ classes compiled with bcc32c on the x87, harness in
  ///   Tests\Data\MathCore\harness\ext). A line is "name inputs | outputs" with a ';name' token
  ///   before each operation; every line is recomputed from its inputs.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMatrixDecompositionsParity = class(TObject)
  private
    FLines: TStringList;
    procedure Run(const APrefix: string; const AMaxUlps: Integer; const ARelative,
      AAbsolute: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TIdMatXLuUpdateSenzaPivotDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMatXLuUpdateConPivotDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMatXQrDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMatXSvdDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMatXEigenGeneralDovrebbeDareGliStessiAutovaloriPerIlCpp;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.MatX.EigenGeneral,
  DelphiDoom.MathCore.Float.MatX.LuUpdate, DelphiDoom.MathCore.Float.MatX.Qr,
  DelphiDoom.MathCore.Float.MatX.Svd, DelphiDoom.MathCore.Float.Types,
  DelphiDoom.MathCore.Float.VecX, DelphiDoom.Tests.MathCore.Matrix.Lines;

function VectorOf(const AFloats: TFloats; const AStart, ASize: Integer): TIdVecX;
var
  LIndex: Integer;
begin
  Result := TIdVecX.Create(ASize);
  for LIndex := 0 to ASize - 1 do
  begin
    Result[LIndex] := AFloats[AStart + LIndex];
  end;
end;

procedure PutIndex(var ALine: string; const AIndex: TArray<Integer>; const ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    TMatrixLines.PutInt(ALine, AIndex[LIndex]);
  end;
end;

procedure ComputeLuUpdate(const AFloats: TFloats; const APivot: Boolean; var ALine: string);
var
  LN, LRow, LSource: Integer;
  LAlpha, LDeterminant: Single;
  LMatrix, LFactored, LUpdated: TIdMatX;
  LV, LW, LWRow, LWIncrement, LVN, LWN, LWRowN, LColumn, LRowVector, LURow: TIdVecX;
  LPermutation, LCopy: TArray<Integer>;
  LOk: Boolean;
  LIndex: PIdIntegerArray;
  LItem: Integer;
begin
  LN := Round(AFloats[0]);
  LRow := Round(AFloats[1]);
  LAlpha := AFloats[2];
  LMatrix := TIdMatX.Create;
  LFactored := TIdMatX.Create;
  LUpdated := TIdMatX.Create;
  LV := VectorOf(AFloats, 3 + LN * LN, LN + 1);
  LW := VectorOf(AFloats, 3 + LN * LN + LN + 1, LN + 1);
  LWRow := TIdVecX.Create(LN + 1);
  LWIncrement := TIdVecX.Create(LN + 1);
  LVN := TIdVecX.Create(LN);
  LWN := TIdVecX.Create(LN);
  LWRowN := TIdVecX.Create(LN);
  LColumn := TIdVecX.Create(LN);
  LRowVector := TIdVecX.Create(LN);
  LURow := TIdVecX.Create(LN);
  SetLength(LPermutation, 16);
  SetLength(LCopy, 16);
  try
    LMatrix.SetValues(LN, LN, PIdSingleArray(@AFloats[3]));
    for LItem := 0 to LN do
    begin
      LWRow[LItem] := LW[LItem];
      LWIncrement[LItem] := LW[LItem];
    end;
    LWRow[LRow] := 0.0;
    LWIncrement[LN] := 0.0;
    for LItem := 0 to LN - 1 do
    begin
      LVN[LItem] := LV[LItem];
      LWN[LItem] := LW[LItem];
      LWRowN[LItem] := LWRow[LItem];
    end;
    LFactored.Assign(LMatrix);
    if APivot then
      LIndex := PIdIntegerArray(@LPermutation[0])
    else
      LIndex := nil;
    LDeterminant := 0.0;
    LOk := LFactored.LuFactor(LIndex, @LDeterminant);
    TMatrixLines.Sep(ALine, 'YL_factor');
    TMatrixLines.PutFlag(ALine, LOk);
    if not LOk then
      Exit;
    TMatrixLines.PutMatX(ALine, LFactored);
    if APivot then
      PutIndex(ALine, LPermutation, LN);
    // rank one
    LUpdated.Assign(LFactored);
    LCopy := Copy(LPermutation);
    if APivot then
      LIndex := PIdIntegerArray(@LCopy[0])
    else
      LIndex := nil;
    LOk := TIdMatXLuUpdate.UpdateRankOne(LUpdated, LVN, LWN, LAlpha, LIndex);
    TMatrixLines.Sep(ALine, 'YL_rank1');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LUpdated);
    // row and column
    LUpdated.Assign(LFactored);
    LCopy := Copy(LPermutation);
    if APivot then
      LIndex := PIdIntegerArray(@LCopy[0])
    else
      LIndex := nil;
    LOk := TIdMatXLuUpdate.UpdateRowColumn(LUpdated, LVN, LWRowN, LRow, LIndex);
    TMatrixLines.Sep(ALine, 'YL_rowcol');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LUpdated);
    // increment
    LUpdated.Assign(LFactored);
    LCopy := Copy(LPermutation);
    if APivot then
      LIndex := PIdIntegerArray(@LCopy[0])
    else
      LIndex := nil;
    LOk := TIdMatXLuUpdate.UpdateIncrement(LUpdated, LV, LWIncrement, LIndex);
    TMatrixLines.Sep(ALine, 'YL_incr');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LUpdated);
    if APivot then
      PutIndex(ALine, LCopy, LN + 1);
    // decrement: v = column r, w = row r, u = row index[r] of the original matrix
    for LItem := 0 to LN - 1 do
    begin
      LColumn[LItem] := LMatrix[LItem, LRow];
      LRowVector[LItem] := LMatrix[LRow, LItem];
    end;
    if APivot then
      LSource := LPermutation[LRow]
    else
      LSource := LRow;
    for LItem := 0 to LN - 1 do
    begin
      LURow[LItem] := LMatrix[LSource, LItem];
    end;
    LUpdated.Assign(LFactored);
    LCopy := Copy(LPermutation);
    if APivot then
      LIndex := PIdIntegerArray(@LCopy[0])
    else
      LIndex := nil;
    LOk := TIdMatXLuUpdate.UpdateDecrement(LUpdated, LColumn, LRowVector, LURow, LRow, LIndex);
    TMatrixLines.Sep(ALine, 'YL_decr');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LUpdated);
    if APivot then
      PutIndex(ALine, LCopy, LN - 1);
  finally
    LURow.Free;
    LRowVector.Free;
    LColumn.Free;
    LWRowN.Free;
    LWN.Free;
    LVN.Free;
    LWIncrement.Free;
    LWRow.Free;
    LW.Free;
    LV.Free;
    LUpdated.Free;
    LFactored.Free;
    LMatrix.Free;
  end;
end;

procedure ComputeQr(const AFloats: TFloats; var ALine: string);
var
  LN, LRow, LItem: Integer;
  LAlpha: Single;
  LMatrix, LFactored, LInverse, LQ, LR, LBack, LQ2, LR2: TIdMatX;
  LC, LD, LX, LB, LV, LW, LWRow, LWIncrement, LVN, LWN, LWRowN, LVV, LColumn, LRowVector: TIdVecX;
  LOk: Boolean;
begin
  LN := Round(AFloats[0]);
  LRow := Round(AFloats[1]);
  LAlpha := AFloats[2];
  LMatrix := TIdMatX.Create;
  LFactored := TIdMatX.Create;
  LInverse := TIdMatX.Create;
  LQ := TIdMatX.Create;
  LR := TIdMatX.Create;
  LBack := TIdMatX.Create(LN, LN);
  LQ2 := TIdMatX.Create;
  LR2 := TIdMatX.Create;
  LC := TIdVecX.Create(LN);
  LD := TIdVecX.Create(LN);
  LX := TIdVecX.Create(LN);
  LV := VectorOf(AFloats, 3 + LN * LN, LN + 1);
  LW := VectorOf(AFloats, 3 + LN * LN + LN + 1, LN + 1);
  LB := VectorOf(AFloats, 3 + LN * LN + 2 * (LN + 1), LN);
  LWRow := TIdVecX.Create(LN + 1);
  LWIncrement := TIdVecX.Create(LN + 1);
  LVN := TIdVecX.Create(LN);
  LWN := TIdVecX.Create(LN);
  LWRowN := TIdVecX.Create(LN);
  LVV := TIdVecX.Create(LN + 1);
  LColumn := TIdVecX.Create(LN);
  LRowVector := TIdVecX.Create(LN);
  try
    LMatrix.SetValues(LN, LN, PIdSingleArray(@AFloats[3]));
    for LItem := 0 to LN do
    begin
      LWRow[LItem] := LW[LItem];
      LWIncrement[LItem] := LW[LItem];
      LVV[LItem] := LV[LItem];
    end;
    LWRow[LRow] := 0.0;
    LWIncrement[LN] := 0.0;
    for LItem := 0 to LN - 1 do
    begin
      LVN[LItem] := LV[LItem];
      LWN[LItem] := LW[LItem];
      LWRowN[LItem] := LWRow[LItem];
    end;
    LFactored.Assign(LMatrix);
    LOk := TIdMatXQr.Factor(LFactored, LC, LD);
    TMatrixLines.Sep(ALine, 'YQ_factor');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LFactored);
    TMatrixLines.PutVecX(ALine, LC);
    TMatrixLines.PutVecX(ALine, LD);
    if not LOk then
      Exit;
    TIdMatXQr.Solve(LFactored, LX, LB, LC, LD);
    TMatrixLines.Sep(ALine, 'YQ_solve');
    TMatrixLines.PutVecX(ALine, LX);
    TIdMatXQr.Inverse(LFactored, LInverse, LC, LD);
    TMatrixLines.Sep(ALine, 'YQ_inv');
    TMatrixLines.PutMatX(ALine, LInverse);
    TIdMatXQr.UnpackFactors(LFactored, LQ, LR, LC, LD);
    TMatrixLines.Sep(ALine, 'YQ_unpack');
    TMatrixLines.PutMatX(ALine, LQ);
    TMatrixLines.PutMatX(ALine, LR);
    TIdMatXQr.MultiplyFactors(LFactored, LBack, LC, LD);
    TMatrixLines.Sep(ALine, 'YQ_mul');
    TMatrixLines.PutMatX(ALine, LBack);
    TIdMatXQr.Solve(LQ, LX, LB, LR);
    TMatrixLines.Sep(ALine, 'YQ_solveR');
    TMatrixLines.PutVecX(ALine, LX);
    LQ2.Assign(LQ);
    LR2.Assign(LR);
    LOk := TIdMatXQr.UpdateRankOne(LQ2, LR2, LVN, LWN, LAlpha);
    TMatrixLines.Sep(ALine, 'YQ_rank1');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LQ2);
    TMatrixLines.PutMatX(ALine, LR2);
    LQ2.Assign(LQ);
    LR2.Assign(LR);
    LOk := TIdMatXQr.UpdateRowColumn(LQ2, LR2, LVN, LWRowN, LRow);
    TMatrixLines.Sep(ALine, 'YQ_rowcol');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LQ2);
    TMatrixLines.PutMatX(ALine, LR2);
    LQ2.Assign(LQ);
    LR2.Assign(LR);
    LOk := TIdMatXQr.UpdateIncrement(LQ2, LR2, LVV, LWIncrement);
    TMatrixLines.Sep(ALine, 'YQ_incr');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LQ2);
    TMatrixLines.PutMatX(ALine, LR2);
    for LItem := 0 to LN - 1 do
    begin
      LColumn[LItem] := LMatrix[LItem, LRow];
      LRowVector[LItem] := LMatrix[LRow, LItem];
    end;
    LQ2.Assign(LQ);
    LR2.Assign(LR);
    LOk := TIdMatXQr.UpdateDecrement(LQ2, LR2, LColumn, LRowVector, LRow);
    TMatrixLines.Sep(ALine, 'YQ_decr');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LQ2);
    TMatrixLines.PutMatX(ALine, LR2);
  finally
    LRowVector.Free;
    LColumn.Free;
    LVV.Free;
    LWRowN.Free;
    LWN.Free;
    LVN.Free;
    LWIncrement.Free;
    LWRow.Free;
    LB.Free;
    LW.Free;
    LV.Free;
    LX.Free;
    LD.Free;
    LC.Free;
    LR2.Free;
    LQ2.Free;
    LBack.Free;
    LR.Free;
    LQ.Free;
    LInverse.Free;
    LFactored.Free;
    LMatrix.Free;
  end;
end;

procedure ComputeSvd(const AFloats: TFloats; var ALine: string);
var
  LM, LN: Integer;
  LFactored, LV, LBack, LInverse: TIdMatX;
  LW, LB, LX: TIdVecX;
  LOk: Boolean;
begin
  LM := Round(AFloats[0]);
  LN := Round(AFloats[1]);
  LFactored := TIdMatX.Create;
  LV := TIdMatX.Create;
  LBack := TIdMatX.Create;
  LInverse := TIdMatX.Create;
  LW := TIdVecX.Create;
  LB := VectorOf(AFloats, 2 + LM * LN, LM);
  LX := TIdVecX.Create(LN);
  try
    LFactored.SetSize(LM, LN);
    Move(AFloats[2], LFactored.Data^, LM * LN * SizeOf(Single));
    LOk := TIdMatXSvd.Factor(LFactored, LW, LV);
    TMatrixLines.Sep(ALine, 'YS_factor');
    TMatrixLines.PutFlag(ALine, LOk);
    if not LOk then
      Exit;
    TMatrixLines.PutVecX(ALine, LW);
    if LM = LN then
    begin
      TIdMatXSvd.MultiplyFactors(LFactored, LBack, LW, LV);
      TMatrixLines.Sep(ALine, 'YS_mul');
      TMatrixLines.PutMatX(ALine, LBack);
    end;
    TIdMatXSvd.Solve(LFactored, LX, LB, LW, LV);
    TMatrixLines.Sep(ALine, 'YS_solve');
    TMatrixLines.PutVecX(ALine, LX);
    if LM = LN then
    begin
      LInverse.SetSize(LN, LN);
      TIdMatXSvd.Inverse(LFactored, LInverse, LW, LV);
      TMatrixLines.Sep(ALine, 'YS_inv');
      TMatrixLines.PutMatX(ALine, LInverse);
    end;
  finally
    LX.Free;
    LB.Free;
    LW.Free;
    LInverse.Free;
    LBack.Free;
    LV.Free;
    LFactored.Free;
  end;
end;

procedure ComputeEigenGeneral(const AFloats: TFloats; var ALine: string);
var
  LN, LI, LJ, LTemp: Integer;
  LFactored: TIdMatX;
  LReal, LImaginary: TIdVecX;
  LOrder: array[0..7] of Integer;
  LOk: Boolean;
begin
  LN := Round(AFloats[0]);
  LFactored := TIdMatX.Create;
  LReal := TIdVecX.Create;
  LImaginary := TIdVecX.Create;
  try
    LFactored.SetSize(LN, LN);
    Move(AFloats[1], LFactored.Data^, LN * LN * SizeOf(Single));
    LOk := TIdMatXEigenGeneral.Solve(LFactored, LReal, LImaginary);
    TMatrixLines.Sep(ALine, 'YG_solve');
    TMatrixLines.PutFlag(ALine, LOk);
    if not LOk then
      Exit;
    // sorted by real part and then by imaginary part, as the harness does
    for LI := 0 to LN - 1 do
    begin
      LOrder[LI] := LI;
    end;
    for LI := 0 to LN - 1 do
    begin
      for LJ := LI + 1 to LN - 1 do
      begin
        if (LReal[LOrder[LJ]] < LReal[LOrder[LI]]) or
          ((LReal[LOrder[LJ]] = LReal[LOrder[LI]]) and
           (LImaginary[LOrder[LJ]] < LImaginary[LOrder[LI]])) then
        begin
          LTemp := LOrder[LI];
          LOrder[LI] := LOrder[LJ];
          LOrder[LJ] := LTemp;
        end;
      end;
    end;
    for LI := 0 to LN - 1 do
    begin
      TMatrixLines.Put(ALine, LReal[LOrder[LI]]);
      TMatrixLines.Put(ALine, LImaginary[LOrder[LI]]);
    end;
  finally
    LImaginary.Free;
    LReal.Free;
    LFactored.Free;
  end;
end;

{ TTestMatrixDecompositionsParity }

procedure TTestMatrixDecompositionsParity.Setup;
begin
  FLines := TStringList.Create;
  FLines.LoadFromFile(TMatrixLines.DataPath('matx2.golden.txt'));
end;

procedure TTestMatrixDecompositionsParity.TearDown;
begin
  FLines.Free;
end;

procedure TTestMatrixDecompositionsParity.Run(const APrefix: string; const AMaxUlps: Integer;
  const ARelative, AAbsolute: Single);
var
  LIndex: Integer;
  LName, LLine: string;
  LFloats: TFloats;
  LActual, LExpected: TStringList;
begin
  LActual := TStringList.Create;
  LExpected := TStringList.Create;
  try
    for LIndex := 0 to FLines.Count - 1 do
    begin
      if not FLines[LIndex].StartsWith(APrefix + ' ') then
        Continue;
      LFloats := TMatrixLines.ParseInputs(FLines[LIndex], LName);
      LLine := TMatrixLines.HeadOf(FLines[LIndex]);
      if LName = 'YLn_all' then
        ComputeLuUpdate(LFloats, False, LLine)
      else if LName = 'YLp_all' then
        ComputeLuUpdate(LFloats, True, LLine)
      else if LName = 'YQ_all' then
        ComputeQr(LFloats, LLine)
      else if LName = 'YS_all' then
        ComputeSvd(LFloats, LLine)
      else if LName = 'YG_all' then
        ComputeEigenGeneral(LFloats, LLine)
      else
        Assert.Fail('operazione sconosciuta ' + LName);
      LActual.Add(LLine);
      LExpected.Add(FLines[LIndex]);
    end;
    Assert.IsTrue(LExpected.Count > 0, 'nessuna riga nel golden per ' + APrefix);
    TMatrixLines.CompareLines(LExpected, LActual, AMaxUlps, ARelative, AAbsolute);
  finally
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestMatrixDecompositionsParity.TIdMatXLuUpdateSenzaPivotDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('YLn_all', 2, 1E-4, 1E-5);
end;

procedure TTestMatrixDecompositionsParity.TIdMatXLuUpdateConPivotDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('YLp_all', 2, 1E-4, 1E-5);
end;

procedure TTestMatrixDecompositionsParity.TIdMatXQrDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('YQ_all', 2, 1E-4, 1E-5);
end;

procedure TTestMatrixDecompositionsParity.TIdMatXSvdDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('YS_all', 2, 1E-4, 1E-5);
end;

procedure TTestMatrixDecompositionsParity.TIdMatXEigenGeneralDovrebbeDareGliStessiAutovaloriPerIlCpp;
begin
  Run('YG_all', 2, 1E-4, 1E-5);
end;

end.
