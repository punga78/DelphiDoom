{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdOdeMidpoint, the midpoint        }
{  method                                                                      }
{                                                                              }
{  Port of idODE_Midpoint (idlib\math\Ode.h and Ode.cpp) of the Doom 3 GPL     }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Ode.Midpoint;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Ode.Intf, DelphiDoom.MathCore.Float.Ode.Base;

type
  /// <summary>
  ///   Second order midpoint step (idODE_Midpoint): an Euler half step, then a full step with the
  ///   derivative at the midpoint. The steps are computed in Double as in the original (the
  ///   locals of the C++ are doubles) and the results are rounded to Single.
  /// </summary>
  TIdOdeMidpoint = class(TIdOde)
  strict private
    FTempState: TArray<Single>;
    FDerivatives: TArray<Single>;
  public
    constructor Create(const ADimension: Integer; const ADerive: TIdOdeDeriveProc);
    function Evaluate(const AState: TArray<Single>; var ANewState: TArray<Single>;
      const AT0, AT1: Single): Single; override;
  end;

implementation

{ TIdOdeMidpoint }

constructor TIdOdeMidpoint.Create(const ADimension: Integer; const ADerive: TIdOdeDeriveProc);
begin
  inherited Create(ADimension, ADerive);
  SetLength(FTempState, ADimension);
  SetLength(FDerivatives, ADimension);
end;

function TIdOdeMidpoint.Evaluate(const AState: TArray<Single>; var ANewState: TArray<Single>;
  const AT0, AT1: Single): Single;
var
  LDelta, LHalfDelta, LProduct, LSum: Double;
  LMidTime: Single;
  LIndex: Integer;
begin
  CheckArrays(AState, ANewState);
  LDelta := Single(AT1 - AT0);
  LHalfDelta := LDelta * 0.5;
  // first step
  Derive(AT0, AState, FDerivatives);
  for LIndex := 0 to Dimension - 1 do
  begin
    LProduct := LHalfDelta * FDerivatives[LIndex];
    LSum := AState[LIndex] + LProduct;
    FTempState[LIndex] := LSum;
  end;
  // second step
  LSum := AT0 + LHalfDelta;
  LMidTime := LSum;
  Derive(LMidTime, FTempState, FDerivatives);
  for LIndex := 0 to Dimension - 1 do
  begin
    LProduct := LDelta * FDerivatives[LIndex];
    LSum := AState[LIndex] + LProduct;
    ANewState[LIndex] := LSum;
  end;
  Result := LDelta;
end;

end.
