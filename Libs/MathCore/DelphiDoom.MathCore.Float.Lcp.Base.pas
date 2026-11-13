{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdLcpBase, the part that the two   }
{  LCP solvers share                                                           }
{                                                                              }
{  Port of idLCP_Square and idLCP_Symmetric (idlib\math\Lcp.cpp) of the        }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a          }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Lcp.Base;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.MathCore.Float.Lcp.Intf, DelphiDoom.MathCore.Float.MatX,
  DelphiDoom.MathCore.Float.Types, DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   The solver as one class: the two C++ classes (<c>idLCP_Square</c>, <c>idLCP_Symmetric</c>)
  ///   have the same <c>Solve</c>, <c>Swap</c>, <c>CalcAccelDelta</c>, <c>ChangeForce</c>,
  ///   <c>ChangeAccel</c> and <c>GetMaxStep</c> twice; here they are written once, and the
  ///   descendants only give the factorization of the clamped sub matrix (LU or LDL') and the
  ///   few steps that differ. The original keeps its working vectors in members that point at
  ///   stack memory; here they are created for the duration of <c>Solve</c>. The messages of the
  ///   original go to the injected log (nil: silent); the failures are only reported when
  ///   <c>lcp_showFailures</c> would be on.
  /// </summary>
  TIdLcpBase = class(TInterfacedObject, IIdLcp)
  strict private
    FLog: ILog;
    FShowFailures: Boolean;
    FMaxIterations: Integer;
    procedure UnpermuteMatrix;
  protected
    /// <summary>The original matrix (shares the memory of the caller's matrix)</summary>
    FMatrix: TIdMatX;
    FB: TIdVecX;
    FLow, FHigh: TIdVecX;
    FForce, FAcceleration: TIdVecX;
    FDeltaForce, FDeltaAcceleration: TIdVecX;
    /// <summary>The factored sub matrix of the clamped variables</summary>
    FClamped: TIdMatX;
    /// <summary>The reciprocal of the diagonal of the factored sub matrix</summary>
    FDiagonal: TIdVecX;
    FNumUnbounded: Integer;
    FNumClamped: Integer;
    /// <summary>Offset in floats of each row of the matrix (the C++ swaps row pointers)</summary>
    FRowOffsets: TArray<Integer>;
    FHasBoxIndex: Boolean;
    FBoxIndex: TArray<Integer>;
    /// <summary>-1 at the low boundary, 1 at the high boundary, 0 in between</summary>
    FSide: TArray<Integer>;
    FPermuted: TArray<Integer>;
    procedure Print(const AText: string);
    function RowPointer(const ARow: Integer): PIdSingleArray;
    procedure Swap(const AI, AJ: Integer);
    procedure CalcAccelDelta(const ADelta: Integer);
    procedure ChangeForce(const ADelta: Integer; const AStep: Single);
    procedure ChangeAccel(const ADelta: Integer; const AStep: Single);
    procedure GetMaxStep(const ADelta: Integer; const ADirection: Single; out AMaxStep: Single;
      out ALimit, ALimitSide: Integer);
    function FactorClamped: Boolean; virtual; abstract;
    procedure SolveClamped(const AX: TIdVecX; const AB: PIdSingleArray); virtual; abstract;
    procedure AddClamped(const ARow: Integer; const AUseSolveCache: Boolean); virtual; abstract;
    procedure RemoveClamped(const ARow: Integer); virtual; abstract;
    procedure CalcForceDelta(const ADelta: Integer; const ADirection: Single); virtual; abstract;
    /// <summary>Creates the working vectors that only one of the solvers has</summary>
    procedure CreateExtra(const ARows: Integer); virtual;
    procedure FreeExtra; virtual;
    /// <summary>Called before each bounded variable is handled</summary>
    procedure BeginVariable; virtual;
  public
    constructor Create(const ALog: ILog = nil; const AShowFailures: Boolean = False);
    function Solve(const AMatrix: TIdMatX; const AX: TIdVecX; const AB, ALow, AHigh: TIdVecX;
      const ABoxIndex: TArray<Integer>): Boolean;
    procedure SetMaxIterations(const AMax: Integer);
    function GetMaxIterations: Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math, DelphiDoom.MathCore.Float.MatX.Kernels;

{ TIdLcpBase }

constructor TIdLcpBase.Create(const ALog: ILog; const AShowFailures: Boolean);
begin
  inherited Create;
  FLog := ALog;
  FShowFailures := AShowFailures;
  FMaxIterations := LCP_DEFAULT_MAX_ITERATIONS;
end;

procedure TIdLcpBase.SetMaxIterations(const AMax: Integer);
begin
  FMaxIterations := AMax;
end;

function TIdLcpBase.GetMaxIterations: Integer;
begin
  Result := FMaxIterations;
end;

procedure TIdLcpBase.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Info(AText + sLineBreak);
end;

procedure TIdLcpBase.CreateExtra(const ARows: Integer);
begin
end;

procedure TIdLcpBase.FreeExtra;
begin
end;

procedure TIdLcpBase.BeginVariable;
begin
end;

function TIdLcpBase.RowPointer(const ARow: Integer): PIdSingleArray;
begin
  Result := PIdSingleArray(@FMatrix.Data^[FRowOffsets[ARow]]);
end;

procedure TIdLcpBase.Swap(const AI, AJ: Integer);
var
  LTemp: Integer;
begin
  if AI = AJ then
    Exit;
  LTemp := FRowOffsets[AI];
  FRowOffsets[AI] := FRowOffsets[AJ];
  FRowOffsets[AJ] := LTemp;
  FMatrix.SwapColumns(AI, AJ);
  FB.SwapElements(AI, AJ);
  FLow.SwapElements(AI, AJ);
  FHigh.SwapElements(AI, AJ);
  FAcceleration.SwapElements(AI, AJ);
  FForce.SwapElements(AI, AJ);
  if FHasBoxIndex then
  begin
    LTemp := FBoxIndex[AI];
    FBoxIndex[AI] := FBoxIndex[AJ];
    FBoxIndex[AJ] := LTemp;
  end;
  LTemp := FSide[AI];
  FSide[AI] := FSide[AJ];
  FSide[AJ] := LTemp;
  LTemp := FPermuted[AI];
  FPermuted[AI] := FPermuted[AJ];
  FPermuted[AJ] := LTemp;
end;

procedure TIdLcpBase.CalcAccelDelta(const ADelta: Integer);
var
  LIndex: Integer;
  LDot: Single;
begin
  // only the not clamped variables, including the current variable, can have a change in
  // acceleration; only the clamped variables and the current variable have a force delta
  for LIndex := FNumClamped to ADelta do
  begin
    LDot := TIdMatXKernels.Dot(RowPointer(LIndex), FDeltaForce.Data, FNumClamped);
    FDeltaAcceleration[LIndex] := LDot + RowPointer(LIndex)^[ADelta] * FDeltaForce[ADelta];
  end;
end;

procedure TIdLcpBase.ChangeForce(const ADelta: Integer; const AStep: Single);
begin
  // only the clamped variables and current variable have a force delta unequal zero
  TIdMatXKernels.MultiplyAdd(FForce.Data, AStep, FDeltaForce.Data, FNumClamped);
  FForce[ADelta] := FForce[ADelta] + AStep * FDeltaForce[ADelta];
end;

procedure TIdLcpBase.ChangeAccel(const ADelta: Integer; const AStep: Single);
begin
  // only the not clamped variables, including the current variable, can have an acceleration
  TIdMatXKernels.MultiplyAdd(PIdSingleArray(@FAcceleration.Data^[FNumClamped]), AStep,
    PIdSingleArray(@FDeltaAcceleration.Data^[FNumClamped]), ADelta - FNumClamped + 1);
end;

procedure TIdLcpBase.GetMaxStep(const ADelta: Integer; const ADirection: Single;
  out AMaxStep: Single; out ALimit, ALimitSide: Integer);
var
  LIndex: Integer;
  LStep: Single;
begin
  // default to a full step for the current variable
  if TIdMath.Fabs(FDeltaAcceleration[ADelta]) > LCP_DELTA_ACCEL_EPSILON then
    AMaxStep := -FAcceleration[ADelta] / FDeltaAcceleration[ADelta]
  else
    AMaxStep := 0.0;
  ALimit := ADelta;
  ALimitSide := 0;
  // test the current variable
  if ADirection < 0.0 then
  begin
    if FLow[ADelta] <> -ID_INFINITY then
    begin
      LStep := (FLow[ADelta] - FForce[ADelta]) / ADirection;
      if LStep < AMaxStep then
      begin
        AMaxStep := LStep;
        ALimitSide := -1;
      end;
    end;
  end
  else
  begin
    if FHigh[ADelta] <> ID_INFINITY then
    begin
      LStep := (FHigh[ADelta] - FForce[ADelta]) / ADirection;
      if LStep < AMaxStep then
      begin
        AMaxStep := LStep;
        ALimitSide := 1;
      end;
    end;
  end;
  // test the clamped bounded variables
  for LIndex := FNumUnbounded to FNumClamped - 1 do
  begin
    if FDeltaForce[LIndex] < -LCP_DELTA_FORCE_EPSILON then
    begin
      // if there is a low boundary
      if FLow[LIndex] <> -ID_INFINITY then
      begin
        LStep := (FLow[LIndex] - FForce[LIndex]) / FDeltaForce[LIndex];
        if LStep < AMaxStep then
        begin
          AMaxStep := LStep;
          ALimit := LIndex;
          ALimitSide := -1;
        end;
      end;
    end
    else if FDeltaForce[LIndex] > LCP_DELTA_FORCE_EPSILON then
    begin
      // if there is a high boundary
      if FHigh[LIndex] <> ID_INFINITY then
      begin
        LStep := (FHigh[LIndex] - FForce[LIndex]) / FDeltaForce[LIndex];
        if LStep < AMaxStep then
        begin
          AMaxStep := LStep;
          ALimit := LIndex;
          ALimitSide := 1;
        end;
      end;
    end;
  end;
  // test the not clamped bounded variables
  for LIndex := FNumClamped to ADelta - 1 do
  begin
    if FSide[LIndex] = -1 then
    begin
      if FDeltaAcceleration[LIndex] >= -LCP_DELTA_ACCEL_EPSILON then
        Continue;
    end
    else if FSide[LIndex] = 1 then
    begin
      if FDeltaAcceleration[LIndex] <= LCP_DELTA_ACCEL_EPSILON then
        Continue;
    end
    else
      Continue;
    // ignore variables for which the force is not allowed to take any substantial value
    if (FLow[LIndex] >= -LCP_BOUND_EPSILON) and (FHigh[LIndex] <= LCP_BOUND_EPSILON) then
      Continue;
    LStep := -FAcceleration[LIndex] / FDeltaAcceleration[LIndex];
    if LStep < AMaxStep then
    begin
      AMaxStep := LStep;
      ALimit := LIndex;
      ALimitSide := 0;
    end;
  end;
end;

procedure TIdLcpBase.UnpermuteMatrix;
var
  LI, LJ, LTemp: Integer;
begin
  for LI := 0 to FMatrix.NumRows - 1 do
  begin
    LJ := 0;
    while LJ < FMatrix.NumRows do
    begin
      if FPermuted[LJ] = LI then
        Break;
      Inc(LJ);
    end;
    if LI <> LJ then
    begin
      FMatrix.SwapColumns(LI, LJ);
      LTemp := FPermuted[LI];
      FPermuted[LI] := FPermuted[LJ];
      FPermuted[LJ] := LTemp;
    end;
  end;
end;

function TIdLcpBase.Solve(const AMatrix: TIdMatX; const AX: TIdVecX; const AB, ALow,
  AHigh: TIdVecX; const ABoxIndex: TArray<Integer>): Boolean;
var
  LRows, LI, LJ, LN, LLimit, LLimitSide, LBoxStartIndex, LNumIgnored: Integer;
  LDirection, LMaxStep, LDot, LScale: Single;
  LFailed: string;
begin
  Assert((AMatrix.NumRows = AMatrix.NumColumns) or
    (((AMatrix.NumRows + 3) and not 3) = AMatrix.NumColumns));
  Assert(AX.Size = AMatrix.NumRows);
  Assert(AB.Size = AMatrix.NumRows);
  Assert(ALow.Size = AMatrix.NumRows);
  Assert(AHigh.Size = AMatrix.NumRows);
  LRows := AMatrix.NumRows;
  FHasBoxIndex := System.Length(ABoxIndex) > 0;
  FMatrix := TIdMatX.Create(LRows, AMatrix.NumColumns, AMatrix.Data);
  FForce := TIdVecX.Create(LRows);
  FAcceleration := TIdVecX.Create(AB.Size);
  FB := TIdVecX.Create(AB.Size);
  FLow := TIdVecX.Create(ALow.Size);
  FHigh := TIdVecX.Create(AHigh.Size);
  FClamped := TIdMatX.Create(LRows, AMatrix.NumColumns);
  FDiagonal := TIdVecX.Create(LRows);
  FDeltaForce := TIdVecX.Create(LRows);
  FDeltaAcceleration := TIdVecX.Create(LRows);
  try
    CreateExtra(LRows);
    if FHasBoxIndex then
    begin
      SetLength(FBoxIndex, AX.Size);
      for LI := 0 to AX.Size - 1 do
      begin
        FBoxIndex[LI] := ABoxIndex[LI];
      end;
    end
    else
      SetLength(FBoxIndex, 0);
    FForce.Zero;
    FAcceleration.Zero;
    FB.Assign(AB);
    FLow.Assign(ALow);
    FHigh.Assign(AHigh);
    // offsets of the rows of m
    SetLength(FRowOffsets, LRows);
    for LI := 0 to LRows - 1 do
    begin
      FRowOffsets[LI] := LI * AMatrix.NumColumns;
    end;
    // tells if a variable is at the low boundary, high boundary or inbetween
    SetLength(FSide, LRows);
    // index to keep track of the permutation
    SetLength(FPermuted, LRows);
    for LI := 0 to LRows - 1 do
    begin
      FPermuted[LI] := LI;
    end;
    // permute input so all unbounded variables come first
    FNumUnbounded := 0;
    for LI := 0 to LRows - 1 do
    begin
      if (FLow[LI] = -ID_INFINITY) and (FHigh[LI] = ID_INFINITY) then
      begin
        if FNumUnbounded <> LI then
          Swap(FNumUnbounded, LI);
        Inc(FNumUnbounded);
      end;
    end;
    // permute input so all variables using the boxIndex come last
    LBoxStartIndex := LRows;
    if FHasBoxIndex then
    begin
      for LI := LRows - 1 downto FNumUnbounded do
      begin
        if (FBoxIndex[LI] >= 0) and ((FLow[LI] <> -ID_INFINITY) or (FHigh[LI] <> ID_INFINITY)) then
        begin
          Dec(LBoxStartIndex);
          if LBoxStartIndex <> LI then
            Swap(LBoxStartIndex, LI);
        end;
      end;
    end;
    // all unbounded variables are clamped
    FNumClamped := FNumUnbounded;
    // if there are unbounded variables
    if FNumUnbounded > 0 then
    begin
      // factor and solve for unbounded variables
      if not FactorClamped then
      begin
        Print(ClassName + '::Solve: unbounded factorization failed');
        // the original returns here with the columns of the caller's matrix still permuted
        UnpermuteMatrix;
        Exit(False);
      end;
      SolveClamped(FForce, FB.Data);
      // if there are no bounded variables we are done
      if FNumUnbounded = LRows then
      begin
        AX.Assign(FForce);
        Exit(True);
      end;
    end;
    LNumIgnored := 0;
    // solve for bounded variables
    LFailed := '';
    LI := FNumUnbounded;
    while LI < LRows do
    begin
      BeginVariable;
      // once we hit the box start index we can initialize the low and high boundaries of the
      // variables using the box index
      if LI = LBoxStartIndex then
      begin
        for LJ := 0 to LBoxStartIndex - 1 do
        begin
          AX[FPermuted[LJ]] := FForce[LJ];
        end;
        for LJ := LBoxStartIndex to LRows - 1 do
        begin
          LScale := AX[FBoxIndex[LJ]];
          if FLow[LJ] <> -ID_INFINITY then
            FLow[LJ] := -TIdMath.Fabs(FLow[LJ] * LScale);
          if FHigh[LJ] <> ID_INFINITY then
            FHigh[LJ] := TIdMath.Fabs(FHigh[LJ] * LScale);
        end;
      end;
      // calculate acceleration for current variable
      LDot := TIdMatXKernels.Dot(RowPointer(LI), FForce.Data, LI);
      FAcceleration[LI] := LDot - FB[LI];
      // if already at the low boundary
      if (FLow[LI] >= -LCP_BOUND_EPSILON) and (FAcceleration[LI] >= -LCP_ACCEL_EPSILON) then
      begin
        FSide[LI] := -1;
        Inc(LI);
        Continue;
      end;
      // if already at the high boundary
      if (FHigh[LI] <= LCP_BOUND_EPSILON) and (FAcceleration[LI] <= LCP_ACCEL_EPSILON) then
      begin
        FSide[LI] := 1;
        Inc(LI);
        Continue;
      end;
      // if inside the clamped region
      if TIdMath.Fabs(FAcceleration[LI]) <= LCP_ACCEL_EPSILON then
      begin
        FSide[LI] := 0;
        AddClamped(LI, False);
        Inc(LI);
        Continue;
      end;
      // drive the current variable into a valid region
      LN := 0;
      while LN < FMaxIterations do
      begin
        // direction to move
        if FAcceleration[LI] <= 0.0 then
          LDirection := 1.0
        else
          LDirection := -1.0;
        // calculate force delta
        CalcForceDelta(LI, LDirection);
        // calculate acceleration delta: delta_a = m * delta_f
        CalcAccelDelta(LI);
        // maximum step we can take
        GetMaxStep(LI, LDirection, LMaxStep, LLimit, LLimitSide);
        if LMaxStep <= 0.0 then
        begin
          // ignore the current variable completely
          FLow[LI] := 0.0;
          FHigh[LI] := 0.0;
          FForce[LI] := 0.0;
          FSide[LI] := -1;
          Inc(LNumIgnored);
          Break;
        end;
        // change force
        ChangeForce(LI, LMaxStep);
        // change acceleration
        ChangeAccel(LI, LMaxStep);
        // clamp/unclamp the variable that limited this step
        FSide[LLimit] := LLimitSide;
        case LLimitSide of
          0:
            begin
              FAcceleration[LLimit] := 0.0;
              AddClamped(LLimit, LLimit = LI);
            end;
          -1:
            begin
              FForce[LLimit] := FLow[LLimit];
              if LLimit <> LI then
                RemoveClamped(LLimit);
            end;
          1:
            begin
              FForce[LLimit] := FHigh[LLimit];
              if LLimit <> LI then
                RemoveClamped(LLimit);
            end;
        end;
        // if the current variable limited the step we can continue with the next variable
        if LLimit = LI then
          Break;
        Inc(LN);
      end;
      if LN >= FMaxIterations then
      begin
        LFailed := Format('max iterations %d', [FMaxIterations]);
        Break;
      end;
      Inc(LI);
    end;
    if (LNumIgnored > 0) and FShowFailures then
    begin
      Print(Format('%s::Solve: %d of %d bounded variables ignored',
        [ClassName, LNumIgnored, LRows - FNumUnbounded]));
    end;
    // if failed clear remaining forces
    if LFailed <> '' then
    begin
      if FShowFailures then
      begin
        Print(Format('%s::Solve: %s (%d of %d bounded variables ignored)',
          [ClassName, LFailed, LRows - LI, LRows - FNumUnbounded]));
      end;
      for LJ := LI to LRows - 1 do
      begin
        FForce[LJ] := 0.0;
      end;
    end;
    // unpermute result
    for LI := 0 to FForce.Size - 1 do
    begin
      AX[FPermuted[LI]] := FForce[LI];
    end;
    // unpermute original matrix
    UnpermuteMatrix;
    Result := True;
  finally
    FreeExtra;
    FreeAndNil(FDeltaAcceleration);
    FreeAndNil(FDeltaForce);
    FreeAndNil(FDiagonal);
    FreeAndNil(FClamped);
    FreeAndNil(FHigh);
    FreeAndNil(FLow);
    FreeAndNil(FB);
    FreeAndNil(FAcceleration);
    FreeAndNil(FForce);
    FreeAndNil(FMatrix);
  end;
end;

end.
