{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - arithmetic of the curves for a      }
{  TIdVec4 value                                                               }
{                                                                              }
{  Port of idCurve<idVec4> (idlib\math\Curve.h) of the Doom 3 GPL Source       }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec4;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>The arithmetic of a curve of 4D vectors (<c>idCurve&lt;idVec4&gt;</c>)</summary>
  TIdCurveVec4Arithmetic = class(TInterfacedObject, IIdCurveArithmetic<TIdVec4>)
  public
    function Add(const A, B: TIdVec4): TIdVec4;
    function Subtract(const A, B: TIdVec4): TIdVec4;
    function Multiply(const A: TIdVec4; const AFactor: Single): TIdVec4;
    function Divide(const A: TIdVec4; const ADivisor: Single): TIdVec4;
    function GetDimension(const A: TIdVec4): Integer;
    function GetComponent(const A: TIdVec4; const AIndex: Integer): Single;
    procedure SetComponent(var A: TIdVec4; const AIndex: Integer; const AComponent: Single);
  end;

implementation

{ TIdCurveVec4Arithmetic }

function TIdCurveVec4Arithmetic.Add(const A, B: TIdVec4): TIdVec4;
begin
  Result := A + B;
end;

function TIdCurveVec4Arithmetic.Subtract(const A, B: TIdVec4): TIdVec4;
begin
  Result := A - B;
end;

function TIdCurveVec4Arithmetic.Multiply(const A: TIdVec4; const AFactor: Single): TIdVec4;
begin
  Result := AFactor * A;
end;

function TIdCurveVec4Arithmetic.Divide(const A: TIdVec4; const ADivisor: Single): TIdVec4;
begin
  Result := A / ADivisor;
end;

function TIdCurveVec4Arithmetic.GetDimension(const A: TIdVec4): Integer;
begin
  Result := 4;
end;

function TIdCurveVec4Arithmetic.GetComponent(const A: TIdVec4; const AIndex: Integer): Single;
begin
  Result := A[AIndex];
end;

procedure TIdCurveVec4Arithmetic.SetComponent(var A: TIdVec4; const AIndex: Integer;
  const AComponent: Single);
begin
  A[AIndex] := AComponent;
end;

end.
