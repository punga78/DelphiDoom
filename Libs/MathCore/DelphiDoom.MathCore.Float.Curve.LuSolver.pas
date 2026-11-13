{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveLuSolver, the linear        }
{  solver of the closed natural spline                                         }
{                                                                              }
{  Port of idMatX::LU_Factor and idMatX::LU_Solve (idlib\math\Matrix.cpp) of   }
{  the Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a      }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.LuSolver;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The LU factorisation without pivoting and the solution of a square system, as
  ///   <c>idMatX::LU_Factor( NULL )</c> and <c>LU_Solve( x, b, NULL )</c> do for the closed
  ///   natural cubic spline. It exists because idMatX is not ported yet; when it is, the spline
  ///   can use it instead. The matrix is a row-major array of N * N Singles; sums and products
  ///   are computed in Double like the doubles of the original.
  /// </summary>
  TIdCurveLuSolver = class sealed
  public
    /// <summary>Factors the matrix in place; false if a pivot is zero (the matrix is then only partly factored, as in the original)</summary>
    class function Factor(var AMatrix: TArray<Single>; const ASize: Integer): Boolean; static;
    /// <summary>Solves in place: <c>AVector</c> holds b on entry and x on exit</summary>
    class procedure Solve(const AMatrix: TArray<Single>; const ASize: Integer;
      var AVector: TArray<Single>); static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

{ TIdCurveLuSolver }

class function TIdCurveLuSolver.Factor(var AMatrix: TArray<Single>; const ASize: Integer): Boolean;
var
  LI, LJ, LK: Integer;
  LS, LD, LProduct, LValue: Double;
  LReciprocal: Single;
begin
  Result := True;
  for LI := 0 to ASize - 1 do
  begin
    LS := TIdMath.Fabs(AMatrix[LI * ASize + LI]);
    if LS = 0.0 then
    begin
      Result := False;
      Exit;
    end;

    LReciprocal := 1.0 / AMatrix[LI * ASize + LI];
    LD := LReciprocal;
    for LJ := LI + 1 to ASize - 1 do
    begin
      LProduct := AMatrix[LJ * ASize + LI] * LD;
      AMatrix[LJ * ASize + LI] := LProduct;
    end;

    if LI < ASize - 1 then
      for LJ := LI + 1 to ASize - 1 do
      begin
        LD := AMatrix[LJ * ASize + LI];
        for LK := LI + 1 to ASize - 1 do
        begin
          LProduct := LD * AMatrix[LI * ASize + LK];
          LValue := AMatrix[LJ * ASize + LK] - LProduct;
          AMatrix[LJ * ASize + LK] := LValue;
        end;
      end;
  end;
end;

class procedure TIdCurveLuSolver.Solve(const AMatrix: TArray<Single>; const ASize: Integer;
  var AVector: TArray<Single>);
var
  LI, LJ: Integer;
  LSum: Double;
  LProduct: Single;
begin
  // solve L
  for LI := 0 to ASize - 1 do
  begin
    LSum := AVector[LI];
    for LJ := 0 to LI - 1 do
    begin
      LProduct := AMatrix[LI * ASize + LJ] * AVector[LJ];
      LSum := LSum - LProduct;
    end;
    AVector[LI] := LSum;
  end;

  // solve U
  for LI := ASize - 1 downto 0 do
  begin
    LSum := AVector[LI];
    for LJ := LI + 1 to ASize - 1 do
    begin
      LProduct := AMatrix[LI * ASize + LJ] * AVector[LJ];
      LSum := LSum - LProduct;
    end;
    AVector[LI] := LSum / AMatrix[LI * ASize + LI];
  end;
end;

end.
