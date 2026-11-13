{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdOdeRK4Adaptive, RK4 with an      }
{  error estimate                                                              }
{                                                                              }
{  Port of idODE_RK4Adaptive (idlib\math\Ode.h and Ode.cpp) of the Doom 3 GPL  }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Ode.RK4Adaptive;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Ode.Intf, DelphiDoom.MathCore.Float.Ode.Base;

type
  /// <summary>
  ///   Fourth order Runge-Kutta with step doubling (idODE_RK4Adaptive): it compares one step of
  ///   size delta with two steps of size delta / 2 and, while the relative error is above
  ///   <c>MaxError</c>, divides the step by four (at most four tries). Returns the step covered:
  ///   <c>4 * delta</c> when the error is acceptable (the original returns the quadruple of the
  ///   step it tried, so the caller advances faster after a successful step). The default maximum
  ///   error is 0.01. <c>ANewState</c> must not be the same array as <c>AState</c>.
  ///   Defect of the original, kept for parity: the second half step starts again from the initial
  ///   state (not from the midpoint) and uses the first derivative of the first half, so the two
  ///   half steps cover only half of the interval and disagree with the full step whenever the
  ///   derivative is not zero. Every try is rejected unless the error limit is above 0.5 or the
  ///   derivative is zero; after four tries the step that comes back is the initial one divided by 256.
  /// </summary>
  TIdOdeRK4Adaptive = class(TIdOde, IIdOdeAdaptive)
  strict private
    FMaxError: Single;
    FTempState: TArray<Single>;
    FD1: TArray<Single>;
    FD1Half: TArray<Single>;
    FD2: TArray<Single>;
    FD3: TArray<Single>;
    FD4: TArray<Single>;
  public
    constructor Create(const ADimension: Integer; const ADerive: TIdOdeDeriveProc);
    function Evaluate(const AState: TArray<Single>; var ANewState: TArray<Single>;
      const AT0, AT1: Single): Single; override;
    function GetMaxError: Single;
    procedure SetMaxError(const AError: Single);
    property MaxError: Single read FMaxError write SetMaxError;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

{ TIdOdeRK4Adaptive }

constructor TIdOdeRK4Adaptive.Create(const ADimension: Integer; const ADerive: TIdOdeDeriveProc);
begin
  inherited Create(ADimension, ADerive);
  FMaxError := 0.01;
  SetLength(FTempState, ADimension);
  SetLength(FD1, ADimension);
  SetLength(FD1Half, ADimension);
  SetLength(FD2, ADimension);
  SetLength(FD3, ADimension);
  SetLength(FD4, ADimension);
end;

function TIdOdeRK4Adaptive.GetMaxError: Single;
begin
  Result := FMaxError;
end;

procedure TIdOdeRK4Adaptive.SetMaxError(const AError: Single);
begin
  if AError > 0.0 then
    FMaxError := AError;
end;

function TIdOdeRK4Adaptive.Evaluate(const AState: TArray<Single>; var ANewState: TArray<Single>;
  const AT0, AT1: Single): Single;
var
  LDelta, LHalfDelta, LFourthDelta, LSixthDelta, LProduct, LSum, LError, LMax, LRatio: Double;
  LTime, LPair, LDifference: Single;
  LIndex, LTry: Integer;
begin
  CheckArrays(AState, ANewState);
  LDelta := Single(AT1 - AT0);

  for LTry := 0 to 3 do
  begin
    LHalfDelta := LDelta * 0.5;
    LFourthDelta := LDelta * 0.25;

    // first step of first half delta
    Derive(AT0, AState, FD1);
    for LIndex := 0 to Dimension - 1 do
    begin
      LProduct := LFourthDelta * FD1[LIndex];
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;
    // second step of first half delta
    LSum := AT0 + LFourthDelta;
    LTime := LSum;
    Derive(LTime, FTempState, FD2);
    for LIndex := 0 to Dimension - 1 do
    begin
      LProduct := LFourthDelta * FD2[LIndex];
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;
    // third step of first half delta
    LSum := AT0 + LFourthDelta;
    LTime := LSum;
    Derive(LTime, FTempState, FD3);
    for LIndex := 0 to Dimension - 1 do
    begin
      LProduct := LHalfDelta * FD3[LIndex];
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;
    // fourth step of first half delta
    LSum := AT0 + LHalfDelta;
    LTime := LSum;
    Derive(LTime, FTempState, FD4);

    LSixthDelta := LHalfDelta * (1.0 / 6.0);
    for LIndex := 0 to Dimension - 1 do
    begin
      LPair := FD2[LIndex] + FD3[LIndex];
      LSum := FD1[LIndex] + 2.0 * LPair + FD4[LIndex];
      LProduct := LSixthDelta * LSum;
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;

    // first step of second half delta
    LSum := AT0 + LHalfDelta;
    LTime := LSum;
    Derive(LTime, FTempState, FD1Half);
    for LIndex := 0 to Dimension - 1 do
    begin
      LProduct := LFourthDelta * FD1Half[LIndex];
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;
    // second step of second half delta
    LSum := AT0 + LHalfDelta + LFourthDelta;
    LTime := LSum;
    Derive(LTime, FTempState, FD2);
    for LIndex := 0 to Dimension - 1 do
    begin
      LProduct := LFourthDelta * FD2[LIndex];
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;
    // third step of second half delta
    LSum := AT0 + LHalfDelta + LFourthDelta;
    LTime := LSum;
    Derive(LTime, FTempState, FD3);
    for LIndex := 0 to Dimension - 1 do
    begin
      LProduct := LHalfDelta * FD3[LIndex];
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;
    // fourth step of second half delta
    LSum := AT0 + LDelta;
    LTime := LSum;
    Derive(LTime, FTempState, FD4);

    LSixthDelta := LHalfDelta * (1.0 / 6.0);
    for LIndex := 0 to Dimension - 1 do
    begin
      LPair := FD2[LIndex] + FD3[LIndex];
      LSum := FD1[LIndex] + 2.0 * LPair + FD4[LIndex];
      LProduct := LSixthDelta * LSum;
      LSum := AState[LIndex] + LProduct;
      ANewState[LIndex] := LSum;
    end;

    // first step of full delta
    for LIndex := 0 to Dimension - 1 do
    begin
      LProduct := LHalfDelta * FD1[LIndex];
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;
    // second step of full delta
    LSum := AT0 + LHalfDelta;
    LTime := LSum;
    Derive(LTime, FTempState, FD2);
    for LIndex := 0 to Dimension - 1 do
    begin
      LProduct := LHalfDelta * FD2[LIndex];
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;
    // third step of full delta
    LSum := AT0 + LHalfDelta;
    LTime := LSum;
    Derive(LTime, FTempState, FD3);
    for LIndex := 0 to Dimension - 1 do
    begin
      LProduct := LDelta * FD3[LIndex];
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;
    // fourth step of full delta
    LSum := AT0 + LDelta;
    LTime := LSum;
    Derive(LTime, FTempState, FD4);

    LSixthDelta := LDelta * (1.0 / 6.0);
    for LIndex := 0 to Dimension - 1 do
    begin
      LPair := FD2[LIndex] + FD3[LIndex];
      LSum := FD1[LIndex] + 2.0 * LPair + FD4[LIndex];
      LProduct := LSixthDelta * LSum;
      LSum := AState[LIndex] + LProduct;
      FTempState[LIndex] := LSum;
    end;

    // get max estimated error: idMath::Fabs takes a float
    LMax := 0.0;
    for LIndex := 0 to Dimension - 1 do
    begin
      LDifference := ANewState[LIndex] - FTempState[LIndex];
      LProduct := LDelta * FD1[LIndex];
      LRatio := LDifference / (LProduct + 1E-10);
      LError := TIdMath.Fabs(LRatio);
      if LError > LMax then
        LMax := LError;
    end;
    LError := LMax / FMaxError;

    if LError <= 1.0 then
    begin
      Result := LDelta * 4.0;
      Exit;
    end;
    if LDelta <= 1E-7 then
    begin
      Result := LDelta;
      Exit;
    end;
    LDelta := LDelta * 0.25;
  end;
  Result := LDelta;
end;

end.
