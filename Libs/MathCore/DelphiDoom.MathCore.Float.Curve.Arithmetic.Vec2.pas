{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - arithmetic of the curves for a      }
{  TIdVec2 value                                                               }
{                                                                              }
{  Port of idCurve<idVec2> (idlib\math\Curve.h) of the Doom 3 GPL Source       }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec2;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>The arithmetic of a curve of 2D vectors (<c>idCurve&lt;idVec2&gt;</c>)</summary>
  TIdCurveVec2Arithmetic = class(TInterfacedObject, IIdCurveArithmetic<TIdVec2>)
  public
    function Add(const A, B: TIdVec2): TIdVec2;
    function Subtract(const A, B: TIdVec2): TIdVec2;
    function Multiply(const A: TIdVec2; const AFactor: Single): TIdVec2;
    function Divide(const A: TIdVec2; const ADivisor: Single): TIdVec2;
    function GetDimension(const A: TIdVec2): Integer;
    function GetComponent(const A: TIdVec2; const AIndex: Integer): Single;
    procedure SetComponent(var A: TIdVec2; const AIndex: Integer; const AComponent: Single);
  end;

implementation

{ TIdCurveVec2Arithmetic }

function TIdCurveVec2Arithmetic.Add(const A, B: TIdVec2): TIdVec2;
begin
  Result := A + B;
end;

function TIdCurveVec2Arithmetic.Subtract(const A, B: TIdVec2): TIdVec2;
begin
  Result := A - B;
end;

function TIdCurveVec2Arithmetic.Multiply(const A: TIdVec2; const AFactor: Single): TIdVec2;
begin
  Result := AFactor * A;
end;

function TIdCurveVec2Arithmetic.Divide(const A: TIdVec2; const ADivisor: Single): TIdVec2;
begin
  Result := A / ADivisor;
end;

function TIdCurveVec2Arithmetic.GetDimension(const A: TIdVec2): Integer;
begin
  Result := 2;
end;

function TIdCurveVec2Arithmetic.GetComponent(const A: TIdVec2; const AIndex: Integer): Single;
begin
  Result := A[AIndex];
end;

procedure TIdCurveVec2Arithmetic.SetComponent(var A: TIdVec2; const AIndex: Integer;
  const AComponent: Single);
begin
  A[AIndex] := AComponent;
end;

end.
