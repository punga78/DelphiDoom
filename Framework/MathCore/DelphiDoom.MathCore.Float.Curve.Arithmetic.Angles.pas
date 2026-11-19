{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - arithmetic of the curves for a      }
{  TIdAngles value                                                             }
{                                                                              }
{  Port of the arithmetic that idExtrapolate<idAngles> and                     }
{  idInterpolateAccelDecelLinear<idAngles> (idlib\math\Extrapolate.h,          }
{  Interpolate.h) of the Doom 3 GPL Source Code do on an idAngles: component   }
{  by component, in Single.                                                    }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.Arithmetic.Angles;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Angles, DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>The arithmetic of a curve of Euler angles (<c>idExtrapolate&lt;idAngles&gt;</c>)</summary>
  TIdCurveAnglesArithmetic = class(TInterfacedObject, IIdCurveArithmetic<TIdAngles>)
  public
    function Add(const A, B: TIdAngles): TIdAngles;
    function Subtract(const A, B: TIdAngles): TIdAngles;
    function Multiply(const A: TIdAngles; const AFactor: Single): TIdAngles;
    function Divide(const A: TIdAngles; const ADivisor: Single): TIdAngles;
    function GetDimension(const A: TIdAngles): Integer;
    function GetComponent(const A: TIdAngles; const AIndex: Integer): Single;
    procedure SetComponent(var A: TIdAngles; const AIndex: Integer; const AComponent: Single);
  end;

implementation

{ TIdCurveAnglesArithmetic }

function TIdCurveAnglesArithmetic.Add(const A, B: TIdAngles): TIdAngles;
begin
  Result := A + B;
end;

function TIdCurveAnglesArithmetic.Subtract(const A, B: TIdAngles): TIdAngles;
begin
  Result := A - B;
end;

function TIdCurveAnglesArithmetic.Multiply(const A: TIdAngles; const AFactor: Single): TIdAngles;
begin
  Result := AFactor * A;
end;

function TIdCurveAnglesArithmetic.Divide(const A: TIdAngles; const ADivisor: Single): TIdAngles;
begin
  Result := A / ADivisor;
end;

function TIdCurveAnglesArithmetic.GetDimension(const A: TIdAngles): Integer;
begin
  Result := 3;
end;

function TIdCurveAnglesArithmetic.GetComponent(const A: TIdAngles; const AIndex: Integer): Single;
begin
  Result := A[AIndex];
end;

procedure TIdCurveAnglesArithmetic.SetComponent(var A: TIdAngles; const AIndex: Integer;
  const AComponent: Single);
begin
  A[AIndex] := AComponent;
end;

end.
