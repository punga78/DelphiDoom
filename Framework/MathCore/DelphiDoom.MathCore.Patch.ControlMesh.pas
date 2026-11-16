{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore - patches of Quake III Arena: the working mesh         }
{                                                                              }
{  Port of the ctrl[MAX_GRID_SIZE][MAX_GRID_SIZE] array of tr_curve.c with     }
{  Transpose, InvertCtrl and PutPointsOnCurve. Based on the Quake III Arena    }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Patch.ControlMesh;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Patch.Types;

type
  /// <summary>
  ///   The square working array of MAX_GRID_SIZE x MAX_GRID_SIZE vertices the subdivision
  ///   works in (cells are [Row, Column]; the live part is Width x Height, which the caller
  ///   keeps). Out of range cells raise EPatchException (the C array has no check).
  /// </summary>
  TPatchControlMesh = class
  strict private
    FCells: TArray<TPatchVertex>;
    function GetCell(const ARow, AColumn: Integer): TPatchVertex;
    procedure SetCell(const ARow, AColumn: Integer; const AValue: TPatchVertex);
  public
    constructor Create;
    /// <summary>Transpose: swaps rows and columns of a Width x Height mesh (in place)</summary>
    procedure Transpose(const AWidth, AHeight: Integer);
    /// <summary>InvertCtrl: reverses every row</summary>
    procedure InvertColumns(const AWidth, AHeight: Integer);
    /// <summary>PutPointsOnCurve: moves the odd control points onto the curve</summary>
    procedure PutPointsOnCurve(const AWidth, AHeight: Integer);
    property Cells[const ARow, AColumn: Integer]: TPatchVertex read GetCell write SetCell; default;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Patch.VertexMath;

constructor TPatchControlMesh.Create;
begin
  inherited Create;
  SetLength(FCells, MAX_GRID_SIZE * MAX_GRID_SIZE);
end;

function TPatchControlMesh.GetCell(const ARow, AColumn: Integer): TPatchVertex;
begin
  if (ARow < 0) or (ARow >= MAX_GRID_SIZE) or (AColumn < 0) or (AColumn >= MAX_GRID_SIZE) then
    raise EPatchException.CreateFmt(SPatchCellOutOfRange, [ARow, AColumn]);
  Result := FCells[ARow * MAX_GRID_SIZE + AColumn];
end;

procedure TPatchControlMesh.SetCell(const ARow, AColumn: Integer; const AValue: TPatchVertex);
begin
  if (ARow < 0) or (ARow >= MAX_GRID_SIZE) or (AColumn < 0) or (AColumn >= MAX_GRID_SIZE) then
    raise EPatchException.CreateFmt(SPatchCellOutOfRange, [ARow, AColumn]);
  FCells[ARow * MAX_GRID_SIZE + AColumn] := AValue;
end;

procedure TPatchControlMesh.Transpose(const AWidth, AHeight: Integer);
var
  LI, LJ: Integer;
  LTemp: TPatchVertex;
begin
  if AWidth > AHeight then
  begin
    for LI := 0 to AHeight - 1 do
      for LJ := LI + 1 to AWidth - 1 do
      begin
        if LJ < AHeight then
        begin
          LTemp := Cells[LJ, LI];
          Cells[LJ, LI] := Cells[LI, LJ];
          Cells[LI, LJ] := LTemp;
        end
        else
          Cells[LJ, LI] := Cells[LI, LJ];
      end;
  end
  else
  begin
    for LI := 0 to AWidth - 1 do
      for LJ := LI + 1 to AHeight - 1 do
      begin
        if LJ < AWidth then
        begin
          LTemp := Cells[LI, LJ];
          Cells[LI, LJ] := Cells[LJ, LI];
          Cells[LJ, LI] := LTemp;
        end
        else
          Cells[LI, LJ] := Cells[LJ, LI];
      end;
  end;
end;

procedure TPatchControlMesh.InvertColumns(const AWidth, AHeight: Integer);
var
  LI, LJ: Integer;
  LTemp: TPatchVertex;
begin
  for LI := 0 to AHeight - 1 do
    for LJ := 0 to AWidth div 2 - 1 do
    begin
      LTemp := Cells[LI, LJ];
      Cells[LI, LJ] := Cells[LI, AWidth - 1 - LJ];
      Cells[LI, AWidth - 1 - LJ] := LTemp;
    end;
end;

procedure TPatchControlMesh.PutPointsOnCurve(const AWidth, AHeight: Integer);
var
  LI, LJ: Integer;
  LPrev, LNext: TPatchVertex;
begin
  for LI := 0 to AWidth - 1 do
  begin
    LJ := 1;
    while LJ < AHeight do
    begin
      LPrev := TPatchVertexMath.Lerp(Cells[LJ, LI], Cells[LJ + 1, LI]);
      LNext := TPatchVertexMath.Lerp(Cells[LJ, LI], Cells[LJ - 1, LI]);
      Cells[LJ, LI] := TPatchVertexMath.Lerp(LPrev, LNext);
      Inc(LJ, 2);
    end;
  end;
  for LJ := 0 to AHeight - 1 do
  begin
    LI := 1;
    while LI < AWidth do
    begin
      LPrev := TPatchVertexMath.Lerp(Cells[LJ, LI], Cells[LJ, LI + 1]);
      LNext := TPatchVertexMath.Lerp(Cells[LJ, LI], Cells[LJ, LI - 1]);
      Cells[LJ, LI] := TPatchVertexMath.Lerp(LPrev, LNext);
      Inc(LI, 2);
    end;
  end;
end;

end.
