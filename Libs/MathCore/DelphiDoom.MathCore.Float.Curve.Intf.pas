{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - arithmetic strategy of the curves   }
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
unit DelphiDoom.MathCore.Float.Curve.Intf;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The arithmetic a curve needs on its value type (the C++ template calls the operators of
  ///   <c>type</c>: <c>+</c>, <c>-</c>, <c>float *</c>, <c>/ float</c>, <c>GetDimension</c> and
  ///   <c>[]</c>). It is injected in the constructor of every curve; strategies exist for
  ///   Single, TIdVec2, TIdVec3 and TIdVec4. The division is a separate operation because the
  ///   vectors multiply by the reciprocal while a Single divides. Implementations must not change
  ///   their arguments.
  /// </summary>
  IIdCurveArithmetic<T> = interface
    /// <summary>A + B</summary>
    function Add(const A, B: T): T;
    /// <summary>A - B</summary>
    function Subtract(const A, B: T): T;
    /// <summary>AFactor * A</summary>
    function Multiply(const A: T; const AFactor: Single): T;
    /// <summary>A / ADivisor</summary>
    function Divide(const A: T; const ADivisor: Single): T;
    /// <summary>The number of components of a value (GetDimension)</summary>
    function GetDimension(const A: T): Integer;
    /// <summary>A[AIndex]</summary>
    function GetComponent(const A: T; const AIndex: Integer): Single;
    /// <summary>A[AIndex] = AComponent</summary>
    procedure SetComponent(var A: T; const AIndex: Integer; const AComponent: Single);
  end;

implementation

end.
