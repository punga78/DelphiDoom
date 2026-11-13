{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - IIdLcp, the box constrained mixed   }
{  linear complementarity problem solver                                       }
{                                                                              }
{  Port of idLCP (idlib\math\Lcp.h and Lcp.cpp) of the Doom 3 GPL Source       }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Lcp.Intf;

interface

uses
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.VecX;

const
  /// <summary>LCP_BOUND_EPSILON: a bound closer to zero than this counts as zero</summary>
  LCP_BOUND_EPSILON: Single = 1E-5;
  /// <summary>LCP_ACCEL_EPSILON: an acceleration smaller than this counts as zero</summary>
  LCP_ACCEL_EPSILON: Single = 1E-5;
  LCP_DELTA_ACCEL_EPSILON: Single = 1E-9;
  LCP_DELTA_FORCE_EPSILON: Single = 1E-9;
  /// <summary>The default number of iterations of AllocSquare and AllocSymmetric</summary>
  LCP_DEFAULT_MAX_ITERATIONS = 32;

type
  /// <summary>
  ///   Solves A x = b + t for x with the complementarity condition
  ///   (x[i] - lo[i]) * (x[i] - hi[i]) * t[i] = 0 for each i: lo[i] &lt; x[i] &lt; hi[i] and
  ///   t[i] = 0, or x[i] = lo[i] and t[i] &gt;= 0, or x[i] = hi[i] and t[i] &lt;= 0. Bounds of
  ///   -/+ <c>ID_INFINITY</c> leave the variable partly bounded or unbounded. With a box index
  ///   (an array with one entry per variable) <c>boxIndex[i] &lt;&gt; -1</c> makes
  ///   <c>lo[i] = -|lo[i] * x[boxIndex[i]]|</c> and <c>hi[i] = |hi[i] * x[boxIndex[i]]|</c>;
  ///   <c>boxIndex[boxIndex[i]]</c> must be -1. The unbounded variables and those with
  ///   <c>boxIndex = -1</c> are solved first.
  /// </summary>
  IIdLcp = interface
    ['{5C9D6C51-3E0A-4F45-9D0F-9A6B8D2E7C14}']
    /// <summary>
    ///   Solves the problem; false only when the factorization of the unbounded variables
    ///   fails. The matrix is permuted while solving and restored on exit. <c>ABoxIndex</c> may
    ///   be empty (no box).
    /// </summary>
    function Solve(const AMatrix: TIdMatX; const AX: TIdVecX; const AB, ALow, AHigh: TIdVecX;
      const ABoxIndex: TArray<Integer>): Boolean;
    procedure SetMaxIterations(const AMax: Integer);
    function GetMaxIterations: Integer;
  end;

implementation

end.
