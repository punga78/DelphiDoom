{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - arithmetic of the curves for a      }
{  Single value                                                                }
{                                                                              }
{  Port of idCurve<float> (idlib\math\Curve.h) of the Doom 3 GPL Source Code.  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.Arithmetic.Scalar;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>
  ///   The arithmetic of a curve of Singles (<c>idCurve&lt;float&gt;</c>): one component. A Single
  ///   is divided, not multiplied by the reciprocal as the vectors are. The original cannot use
  ///   the arc length functions on a float curve (they need <c>GetDimension</c>); here they work.
  /// </summary>
  TIdCurveScalarArithmetic = class(TInterfacedObject, IIdCurveArithmetic<Single>)
  public
    function Add(const A, B: Single): Single;
    function Subtract(const A, B: Single): Single;
    function Multiply(const A: Single; const AFactor: Single): Single;
    function Divide(const A: Single; const ADivisor: Single): Single;
    function GetDimension(const A: Single): Integer;
    function GetComponent(const A: Single; const AIndex: Integer): Single;
    procedure SetComponent(var A: Single; const AIndex: Integer; const AComponent: Single);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Float.Curve.Types;

{ TIdCurveScalarArithmetic }

function TIdCurveScalarArithmetic.Add(const A, B: Single): Single;
begin
  Result := A + B;
end;

function TIdCurveScalarArithmetic.Subtract(const A, B: Single): Single;
begin
  Result := A - B;
end;

function TIdCurveScalarArithmetic.Multiply(const A: Single; const AFactor: Single): Single;
begin
  Result := AFactor * A;
end;

function TIdCurveScalarArithmetic.Divide(const A: Single; const ADivisor: Single): Single;
begin
  Result := A / ADivisor;
end;

function TIdCurveScalarArithmetic.GetDimension(const A: Single): Integer;
begin
  Result := 1;
end;

function TIdCurveScalarArithmetic.GetComponent(const A: Single; const AIndex: Integer): Single;
begin
  if AIndex <> 0 then
    raise EIdCurveException.CreateFmt(SIdCurveComponentRange, [AIndex]);
  Result := A;
end;

procedure TIdCurveScalarArithmetic.SetComponent(var A: Single; const AIndex: Integer;
  const AComponent: Single);
begin
  if AIndex <> 0 then
    raise EIdCurveException.CreateFmt(SIdCurveComponentRange, [AIndex]);
  A := AComponent;
end;

end.
