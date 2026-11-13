{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdOdeRK4, the fourth order         }
{  Runge-Kutta method                                                          }
{                                                                              }
{  Port of idODE_RK4 (idlib\math\Ode.h and Ode.cpp) of the Doom 3 GPL Source   }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Ode.RK4;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Ode.Intf, DelphiDoom.MathCore.Float.Ode.Base;

type
  /// <summary>
  ///   Classic fourth order Runge-Kutta step (idODE_RK4), four calls to the derive function per
  ///   step. The steps are computed in Double as in the original (the locals of the C++ are
  ///   doubles) and the results are rounded to Single. <c>ANewState</c> must not be the same
  ///   array as <c>AState</c>.
  /// </summary>
  TIdOdeRK4 = class(TIdOde)
  strict private
    FTempState: TArray<Single>;
    FD1: TArray<Single>;
    FD2: TArray<Single>;
    FD3: TArray<Single>;
    FD4: TArray<Single>;
  public
    constructor Create(const ADimension: Integer; const ADerive: TIdOdeDeriveProc);
    function Evaluate(const AState: TArray<Single>; var ANewState: TArray<Single>;
      const AT0, AT1: Single): Single; override;
  end;

implementation

{ TIdOdeRK4 }

constructor TIdOdeRK4.Create(const ADimension: Integer; const ADerive: TIdOdeDeriveProc);
begin
  inherited Create(ADimension, ADerive);
  SetLength(FTempState, ADimension);
  SetLength(FD1, ADimension);
  SetLength(FD2, ADimension);
  SetLength(FD3, ADimension);
  SetLength(FD4, ADimension);
end;

function TIdOdeRK4.Evaluate(const AState: TArray<Single>; var ANewState: TArray<Single>;
  const AT0, AT1: Single): Single;
var
  LDelta, LHalfDelta, LSixthDelta, LProduct, LSum: Double;
  LTime, LPair: Single;
  LIndex: Integer;
begin
  CheckArrays(AState, ANewState);
  LDelta := Single(AT1 - AT0);
  LHalfDelta := LDelta * 0.5;
  // first step
  Derive(AT0, AState, FD1);
  for LIndex := 0 to Dimension - 1 do
  begin
    LProduct := LHalfDelta * FD1[LIndex];
    LSum := AState[LIndex] + LProduct;
    FTempState[LIndex] := LSum;
  end;
  // second step
  LSum := AT0 + LHalfDelta;
  LTime := LSum;
  Derive(LTime, FTempState, FD2);
  for LIndex := 0 to Dimension - 1 do
  begin
    LProduct := LHalfDelta * FD2[LIndex];
    LSum := AState[LIndex] + LProduct;
    FTempState[LIndex] := LSum;
  end;
  // third step
  LSum := AT0 + LHalfDelta;
  LTime := LSum;
  Derive(LTime, FTempState, FD3);
  for LIndex := 0 to Dimension - 1 do
  begin
    LProduct := LDelta * FD3[LIndex];
    LSum := AState[LIndex] + LProduct;
    FTempState[LIndex] := LSum;
  end;
  // fourth step
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
    ANewState[LIndex] := LSum;
  end;
  Result := LDelta;
end;

end.
