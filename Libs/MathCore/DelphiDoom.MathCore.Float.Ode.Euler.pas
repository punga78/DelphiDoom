{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdOdeEuler, the Euler method       }
{                                                                              }
{  Port of idODE_Euler (idlib\math\Ode.h and Ode.cpp) of the Doom 3 GPL        }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Ode.Euler;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Ode.Intf, DelphiDoom.MathCore.Float.Ode.Base;

type
  /// <summary>
  ///   First order Euler step (idODE_Euler): <c>new = state + delta * derivative</c>, one call to
  ///   the derive function per step; the returned step is <c>t1 - t0</c>.
  /// </summary>
  TIdOdeEuler = class(TIdOde)
  strict private
    FDerivatives: TArray<Single>;
  public
    constructor Create(const ADimension: Integer; const ADerive: TIdOdeDeriveProc);
    function Evaluate(const AState: TArray<Single>; var ANewState: TArray<Single>;
      const AT0, AT1: Single): Single; override;
  end;

implementation

{ TIdOdeEuler }

constructor TIdOdeEuler.Create(const ADimension: Integer; const ADerive: TIdOdeDeriveProc);
begin
  inherited Create(ADimension, ADerive);
  SetLength(FDerivatives, ADimension);
end;

function TIdOdeEuler.Evaluate(const AState: TArray<Single>; var ANewState: TArray<Single>;
  const AT0, AT1: Single): Single;
var
  LDelta, LStep: Single;
  LIndex: Integer;
begin
  CheckArrays(AState, ANewState);
  Derive(AT0, AState, FDerivatives);
  LDelta := AT1 - AT0;
  for LIndex := 0 to Dimension - 1 do
  begin
    LStep := LDelta * FDerivatives[LIndex];
    ANewState[LIndex] := AState[LIndex] + LStep;
  end;
  Result := LDelta;
end;

end.
