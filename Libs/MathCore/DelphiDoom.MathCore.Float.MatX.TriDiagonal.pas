{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatXTriDiagonal, tri-diagonal    }
{  matrices                                                                    }
{                                                                              }
{  Port of the TriDiagonal_* members of idMatX (idlib\math\Matrix.cpp) of the  }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a          }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX.TriDiagonal;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>Clearing, solving and inverting a tri-diagonal matrix (the <c>TriDiagonal_*</c> members of idMatX)</summary>
  TIdMatXTriDiagonal = class sealed
  public
    /// <summary>Zeroes everything but the diagonal and the two next to it</summary>
    class procedure ClearTriangles(const AMatrix: TIdMatX); static;
    /// <summary>Solves Ax = b; false if a pivot is zero</summary>
    class function Solve(const AMatrix: TIdMatX; const AX, AB: TIdVecX): Boolean; static;
    class procedure Inverse(const AMatrix: TIdMatX; const AInverse: TIdMatX); static;
  end;

implementation

{ TIdMatXTriDiagonal }

class procedure TIdMatXTriDiagonal.ClearTriangles(const AMatrix: TIdMatX);
var
  LI, LJ: Integer;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  for LI := 0 to AMatrix.NumRows - 3 do
  begin
    for LJ := LI + 2 to AMatrix.NumColumns - 1 do
    begin
      AMatrix[LI, LJ] := 0.0;
      AMatrix[LJ, LI] := 0.0;
    end;
  end;
end;

class function TIdMatXTriDiagonal.Solve(const AMatrix: TIdMatX; const AX, AB: TIdVecX): Boolean;
var
  LI, LRows: Integer;
  LD: Single;
  LTemp: TIdVecX;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert((AX.Size >= AMatrix.NumRows) and (AB.Size >= AMatrix.NumRows));
  LRows := AMatrix.NumRows;
  LTemp := TIdVecX.Create(LRows);
  try
    LD := AMatrix[0, 0];
    if LD = 0.0 then
      Exit(False);
    LD := 1.0 / LD;
    AX[0] := AB[0] * LD;
    for LI := 1 to LRows - 1 do
    begin
      LTemp[LI] := AMatrix[LI - 1, LI] * LD;
      LD := AMatrix[LI, LI] - AMatrix[LI, LI - 1] * LTemp[LI];
      if LD = 0.0 then
        Exit(False);
      LD := 1.0 / LD;
      AX[LI] := (AB[LI] - AMatrix[LI, LI - 1] * AX[LI - 1]) * LD;
    end;
    for LI := LRows - 2 downto 0 do
    begin
      AX[LI] := AX[LI] - LTemp[LI + 1] * AX[LI + 1];
    end;
    Result := True;
  finally
    LTemp.Free;
  end;
end;

class procedure TIdMatXTriDiagonal.Inverse(const AMatrix: TIdMatX; const AInverse: TIdMatX);
var
  LI, LJ: Integer;
  LX, LB: TIdVecX;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  LX := TIdVecX.Create(AMatrix.NumRows);
  LB := TIdVecX.Create(AMatrix.NumRows);
  try
    LB.Zero;
    AInverse.SetSize(AMatrix.NumRows, AMatrix.NumColumns);
    for LI := 0 to AMatrix.NumRows - 1 do
    begin
      LB[LI] := 1.0;
      Solve(AMatrix, LX, LB);
      for LJ := 0 to AMatrix.NumRows - 1 do
      begin
        AInverse[LJ, LI] := LX[LJ];
      end;
      LB[LI] := 0.0;
    end;
  finally
    LB.Free;
    LX.Free;
  end;
end;

end.
