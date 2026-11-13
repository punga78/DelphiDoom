{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - arithmetic of the curves for a      }
{  TIdVec3 value                                                               }
{                                                                              }
{  Port of idCurve<idVec3> (idlib\math\Curve.h) of the Doom 3 GPL Source       }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec3;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>The arithmetic of a curve of 3D vectors (<c>idCurve&lt;idVec3&gt;</c>)</summary>
  TIdCurveVec3Arithmetic = class(TInterfacedObject, IIdCurveArithmetic<TIdVec3>)
  public
    function Add(const A, B: TIdVec3): TIdVec3;
    function Subtract(const A, B: TIdVec3): TIdVec3;
    function Multiply(const A: TIdVec3; const AFactor: Single): TIdVec3;
    function Divide(const A: TIdVec3; const ADivisor: Single): TIdVec3;
    function GetDimension(const A: TIdVec3): Integer;
    function GetComponent(const A: TIdVec3; const AIndex: Integer): Single;
    procedure SetComponent(var A: TIdVec3; const AIndex: Integer; const AComponent: Single);
  end;

implementation

{ TIdCurveVec3Arithmetic }

function TIdCurveVec3Arithmetic.Add(const A, B: TIdVec3): TIdVec3;
begin
  Result := A + B;
end;

function TIdCurveVec3Arithmetic.Subtract(const A, B: TIdVec3): TIdVec3;
begin
  Result := A - B;
end;

function TIdCurveVec3Arithmetic.Multiply(const A: TIdVec3; const AFactor: Single): TIdVec3;
begin
  Result := AFactor * A;
end;

function TIdCurveVec3Arithmetic.Divide(const A: TIdVec3; const ADivisor: Single): TIdVec3;
begin
  Result := A / ADivisor;
end;

function TIdCurveVec3Arithmetic.GetDimension(const A: TIdVec3): Integer;
begin
  Result := 3;
end;

function TIdCurveVec3Arithmetic.GetComponent(const A: TIdVec3; const AIndex: Integer): Single;
begin
  Result := A[AIndex];
end;

procedure TIdCurveVec3Arithmetic.SetComponent(var A: TIdVec3; const AIndex: Integer;
  const AComponent: Single);
begin
  A[AIndex] := AComponent;
end;

end.
