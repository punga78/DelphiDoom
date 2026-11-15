{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - arithmetic of the curves on idVecX  }
{                                                                              }
{  Port of idCurve (idlib\math\Curve.h) of the Doom 3 GPL Source Code.         }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.Arithmetic.VecX;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve.Intf;

type
  /// <summary>
  ///   A value of a curve of vectors of any size: the floats of an <c>idVecX</c> as a value
  ///   (a copy, so that a curve owns its values; <c>TIdVecX</c> is a class and cannot be the
  ///   type argument of a curve)
  /// </summary>
  TIdVecXValue = TArray<Single>;

  /// <summary>
  ///   The arithmetic of a curve of vectors of any size (<c>idCurve&lt;idVecX&gt;</c>). The
  ///   operands of a sum or a difference must have the same size (the C++ asserts it):
  ///   <c>EArgumentException</c> otherwise; an empty value is a zero vector of any size (the
  ///   solver of the natural spline starts from default values, which in the C++ have no memory). The result has the size of the operands and the
  ///   dimension of a value is its length.
  /// </summary>
  TIdCurveVecXArithmetic = class(TInterfacedObject, IIdCurveArithmetic<TIdVecXValue>)
  public
    function Add(const A, B: TIdVecXValue): TIdVecXValue;
    function Subtract(const A, B: TIdVecXValue): TIdVecXValue;
    function Multiply(const A: TIdVecXValue; const AFactor: Single): TIdVecXValue;
    function Divide(const A: TIdVecXValue; const ADivisor: Single): TIdVecXValue;
    function GetDimension(const A: TIdVecXValue): Integer;
    function GetComponent(const A: TIdVecXValue; const AIndex: Integer): Single;
    procedure SetComponent(var A: TIdVecXValue; const AIndex: Integer; const AComponent: Single);
  end;

implementation

uses
  System.SysUtils;

const
  SSizeMismatch = 'The vectors of a curve must have the same size';

{ TIdCurveVecXArithmetic }

function TIdCurveVecXArithmetic.Add(const A, B: TIdVecXValue): TIdVecXValue;
var
  LIndex: Integer;
begin
  if Length(A) = 0 then
    Exit(Copy(B));
  if Length(B) = 0 then
    Exit(Copy(A));
  if Length(A) <> Length(B) then
    raise EArgumentException.Create(SSizeMismatch);
  SetLength(Result, Length(A));
  for LIndex := 0 to High(A) do
  begin
    Result[LIndex] := A[LIndex] + B[LIndex];
  end;
end;

function TIdCurveVecXArithmetic.Subtract(const A, B: TIdVecXValue): TIdVecXValue;
var
  LIndex: Integer;
begin
  if Length(B) = 0 then
    Exit(Copy(A));
  if (Length(A) = 0) then
    Exit(Multiply(B, -1.0));
  if Length(A) <> Length(B) then
    raise EArgumentException.Create(SSizeMismatch);
  SetLength(Result, Length(A));
  for LIndex := 0 to High(A) do
  begin
    Result[LIndex] := A[LIndex] - B[LIndex];
  end;
end;

function TIdCurveVecXArithmetic.Multiply(const A: TIdVecXValue; const AFactor: Single): TIdVecXValue;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(A));
  for LIndex := 0 to High(A) do
  begin
    Result[LIndex] := A[LIndex] * AFactor;
  end;
end;

function TIdCurveVecXArithmetic.Divide(const A: TIdVecXValue; const ADivisor: Single): TIdVecXValue;
var
  LIndex: Integer;
  LInverse: Single;
begin
  // idVecX::operator/( float ) multiplies by the reciprocal
  LInverse := 1.0 / ADivisor;
  SetLength(Result, Length(A));
  for LIndex := 0 to High(A) do
  begin
    Result[LIndex] := A[LIndex] * LInverse;
  end;
end;

function TIdCurveVecXArithmetic.GetDimension(const A: TIdVecXValue): Integer;
begin
  Result := Length(A);
end;

function TIdCurveVecXArithmetic.GetComponent(const A: TIdVecXValue; const AIndex: Integer): Single;
begin
  Result := A[AIndex];
end;

procedure TIdCurveVecXArithmetic.SetComponent(var A: TIdVecXValue; const AIndex: Integer;
  const AComponent: Single);
begin
  A[AIndex] := AComponent;
end;

end.
