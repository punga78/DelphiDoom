{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  the grid of a patch                                                         }
{                                                                              }
{  Port of cGrid_t and of the grid subdivision of cm_patch.c (CM_Subdivide,    }
{  CM_NeedsSubdivision, CM_TransposeGrid, CM_SetGridWrapWidth,                 }
{  CM_SubdivideGridColumns, CM_ComparePoints, CM_RemoveDegenerateColumns) of   }
{  the Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005  }
{  Id Software, Inc. This unit is derived from the Quake III Arena source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 2 or (at your option) any later version.                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.PatchGrid;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Collision.Q3.Types;

const
  /// <summary>MAX_GRID_SIZE of cm_patch.h</summary>
  Q3_MAX_GRID_SIZE = 129;
  /// <summary>SUBDIVIDE_DISTANCE: never more than this units away from the curve</summary>
  Q3_SUBDIVIDE_DISTANCE = 16;

type
  /// <summary>
  ///   The control points of a patch, subdivided until they are on the curve (cGrid_t). The points are
  ///   [width][height]. The original writes past its arrays if the subdivision grows beyond
  ///   MAX_GRID_SIZE: here that is an EQ3CollisionException
  /// </summary>
  TQ3PatchGrid = class
  private
    FPoints: array of TQ3Vec3;
    function GetPoint(AColumn, ARow: Integer): TQ3Vec3;
    procedure SetPoint(AColumn, ARow: Integer; const AValue: TQ3Vec3);
    class function NeedsSubdivision(const A, B, C: TQ3Vec3): Boolean; static;
    class function ComparePoints(const A, B: TQ3Vec3): Boolean; static;
    function Index(AColumn, ARow: Integer): Integer; inline;
  public
    Width: Integer;
    Height: Integer;
    WrapWidth: Boolean;
    WrapHeight: Boolean;
    constructor Create;
    /// <summary>The grid of the control points: AWidth * AHeight points packed as rows (points[j * width + i])</summary>
    procedure Load(AWidth, AHeight: Integer; const APoints: TArray<TQ3Vec3>);
    /// <summary>CM_TransposeGrid: swaps the rows and the columns</summary>
    procedure Transpose;
    /// <summary>CM_SetGridWrapWidth: if the left and right columns are equal the grid wraps</summary>
    procedure SetWrapWidth;
    /// <summary>CM_SubdivideGridColumns: adds columns until all the points are within the distance of the curve</summary>
    procedure SubdivideColumns;
    /// <summary>CM_RemoveDegenerateColumns: identical neighbour columns are removed</summary>
    procedure RemoveDegenerateColumns;
    property Points[AColumn, ARow: Integer]: TQ3Vec3 read GetPoint write SetPoint; default;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Collision.Q3.VectorMath;

resourcestring
  SGridTooBig = 'CM_SubdivideGridColumns: the grid is bigger than MAX_GRID_SIZE';

const
  // #define WRAP_POINT_EPSILON 0.1 and POINT_EPSILON 0.1: doubles in the C
  WRAP_POINT_EPSILON: Double = 0.1;
  POINT_EPSILON: Double = 0.1;

{ TQ3PatchGrid }

constructor TQ3PatchGrid.Create;
begin
  inherited Create;
  SetLength(FPoints, Q3_MAX_GRID_SIZE * Q3_MAX_GRID_SIZE);
end;

function TQ3PatchGrid.Index(AColumn, ARow: Integer): Integer;
begin
  Result := AColumn * Q3_MAX_GRID_SIZE + ARow;
end;

function TQ3PatchGrid.GetPoint(AColumn, ARow: Integer): TQ3Vec3;
begin
  Result := FPoints[Index(AColumn, ARow)];
end;

procedure TQ3PatchGrid.SetPoint(AColumn, ARow: Integer; const AValue: TQ3Vec3);
begin
  FPoints[Index(AColumn, ARow)] := AValue;
end;

procedure TQ3PatchGrid.Load(AWidth, AHeight: Integer; const APoints: TArray<TQ3Vec3>);
var
  LColumn: Integer;
  LRow: Integer;
begin
  Width := AWidth;
  Height := AHeight;
  WrapWidth := False;
  WrapHeight := False;
  for LColumn := 0 to AWidth - 1 do
    for LRow := 0 to AHeight - 1 do
      FPoints[Index(LColumn, LRow)] := APoints[LRow * AWidth + LColumn];
end;

class function TQ3PatchGrid.NeedsSubdivision(const A, B, C: TQ3Vec3): Boolean;
var
  LLinearMid: TQ3Vec3;
  LCurveMid: TQ3Vec3;
  LDelta: TQ3Vec3;
  LIndex: Integer;
  LSumAB: Single;
  LSumBC: Single;
  LSumAC: Single;
  LHalfAB: Double;
  LHalfBC: Double;
  LHalfSum: Double;
begin
  for LIndex := 0 to 2 do
  begin
    // calculate the linear midpoint: 0.5 is a double in the C, the product is exact
    LSumAC := A[LIndex] + C[LIndex];
    LLinearMid[LIndex] := 0.5 * LSumAC;
    // calculate the exact curve midpoint
    LSumAB := A[LIndex] + B[LIndex];
    LSumBC := B[LIndex] + C[LIndex];
    LHalfAB := 0.5 * Double(LSumAB);
    LHalfBC := 0.5 * Double(LSumBC);
    LHalfSum := LHalfAB + LHalfBC;
    LCurveMid[LIndex] := 0.5 * LHalfSum;
  end;
  // see if the curve is far enough away from the linear mid
  LDelta := TQ3VectorMath.Subtract(LCurveMid, LLinearMid);
  Result := TQ3VectorMath.Length(LDelta) >= Q3_SUBDIVIDE_DISTANCE;
end;

procedure TQ3PatchGrid.Transpose;
var
  LI: Integer;
  LJ: Integer;
  LTemp: TQ3Vec3;
  LL: Integer;
  LWrap: Boolean;
begin
  if Width > Height then
  begin
    for LI := 0 to Height - 1 do
      for LJ := LI + 1 to Width - 1 do
        if LJ < Height then
        begin
          // swap the value
          LTemp := FPoints[Index(LI, LJ)];
          FPoints[Index(LI, LJ)] := FPoints[Index(LJ, LI)];
          FPoints[Index(LJ, LI)] := LTemp;
        end
        else
          // just copy
          FPoints[Index(LI, LJ)] := FPoints[Index(LJ, LI)];
  end
  else
  begin
    for LI := 0 to Width - 1 do
      for LJ := LI + 1 to Height - 1 do
        if LJ < Width then
        begin
          // swap the value
          LTemp := FPoints[Index(LJ, LI)];
          FPoints[Index(LJ, LI)] := FPoints[Index(LI, LJ)];
          FPoints[Index(LI, LJ)] := LTemp;
        end
        else
          // just copy
          FPoints[Index(LJ, LI)] := FPoints[Index(LI, LJ)];
  end;

  LL := Width;
  Width := Height;
  Height := LL;

  LWrap := WrapWidth;
  WrapWidth := WrapHeight;
  WrapHeight := LWrap;
end;

procedure TQ3PatchGrid.SetWrapWidth;
var
  LI: Integer;
  LJ: Integer;
  LD: Single;
begin
  LI := 0;
  while LI < Height do
  begin
    LJ := 0;
    while LJ < 3 do
    begin
      LD := FPoints[Index(0, LI)][LJ] - FPoints[Index(Width - 1, LI)][LJ];
      if (LD < -WRAP_POINT_EPSILON) or (LD > WRAP_POINT_EPSILON) then
        Break;
      Inc(LJ);
    end;
    if LJ <> 3 then
      Break;
    Inc(LI);
  end;
  WrapWidth := LI = Height;
end;

procedure TQ3PatchGrid.SubdivideColumns;
var
  LI: Integer;
  LJ: Integer;
  LK: Integer;
  LPrev: TQ3Vec3;
  LMid: TQ3Vec3;
  LNext: TQ3Vec3;
  LOut1: TQ3Vec3;
  LOut2: TQ3Vec3;
  LOut3: TQ3Vec3;
  LAxis: Integer;
  LSum: Single;
begin
  LI := 0;
  while LI < Width - 2 do
  begin
    // grid->points[i][x] is an interpolating control point
    // grid->points[i+1][x] is an aproximating control point
    // grid->points[i+2][x] is an interpolating control point

    // first see if we can collapse the aproximating collumn away
    LJ := 0;
    while LJ < Height do
    begin
      if NeedsSubdivision(FPoints[Index(LI, LJ)], FPoints[Index(LI + 1, LJ)], FPoints[Index(LI + 2, LJ)]) then
        Break;
      Inc(LJ);
    end;
    if LJ = Height then
    begin
      // all of the points were close enough to the linear midpoints that we can collapse the entire column away
      for LJ := 0 to Height - 1 do
        // remove the column
        for LK := LI + 2 to Width - 1 do
          FPoints[Index(LK - 1, LJ)] := FPoints[Index(LK, LJ)];

      Dec(Width);

      // go to the next curve segment
      Inc(LI);
      Continue;
    end;

    // we need to subdivide the curve
    if Width + 2 > Q3_MAX_GRID_SIZE then
      raise EQ3CollisionException.Create(SGridTooBig);
    for LJ := 0 to Height - 1 do
    begin
      // save the control points now
      LPrev := FPoints[Index(LI, LJ)];
      LMid := FPoints[Index(LI + 1, LJ)];
      LNext := FPoints[Index(LI + 2, LJ)];

      // make room for two additional columns in the grid
      // columns i+1 will be replaced, column i+2 will become i+4
      // i+1, i+2, and i+3 will be generated
      for LK := Width - 1 downto LI + 2 do
        FPoints[Index(LK + 2, LJ)] := FPoints[Index(LK, LJ)];

      // generate the subdivided points (CM_Subdivide: 0.5 is a double, the products are exact)
      for LAxis := 0 to 2 do
      begin
        LSum := LPrev[LAxis] + LMid[LAxis];
        LOut1[LAxis] := 0.5 * LSum;
        LSum := LMid[LAxis] + LNext[LAxis];
        LOut3[LAxis] := 0.5 * LSum;
        LSum := LOut1[LAxis] + LOut3[LAxis];
        LOut2[LAxis] := 0.5 * LSum;
      end;
      FPoints[Index(LI + 1, LJ)] := LOut1;
      FPoints[Index(LI + 2, LJ)] := LOut2;
      FPoints[Index(LI + 3, LJ)] := LOut3;
    end;

    Inc(Width, 2);

    // the new aproximating point at i+1 may need to be removed or subdivided farther, so don't advance i
  end;
end;

class function TQ3PatchGrid.ComparePoints(const A, B: TQ3Vec3): Boolean;
var
  LD: Single;
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
  begin
    LD := A[LIndex] - B[LIndex];
    if (LD < -POINT_EPSILON) or (LD > POINT_EPSILON) then
      Exit(False);
  end;
  Result := True;
end;

procedure TQ3PatchGrid.RemoveDegenerateColumns;
var
  LI: Integer;
  LJ: Integer;
  LK: Integer;
begin
  LI := 0;
  while LI < Width - 1 do
  begin
    LJ := 0;
    while LJ < Height do
    begin
      if not ComparePoints(FPoints[Index(LI, LJ)], FPoints[Index(LI + 1, LJ)]) then
        Break;
      Inc(LJ);
    end;

    if LJ <> Height then
    begin
      Inc(LI);
      Continue; // not degenerate
    end;

    for LJ := 0 to Height - 1 do
      // remove the column
      for LK := LI + 2 to Width - 1 do
        FPoints[Index(LK - 1, LJ)] := FPoints[Index(LK, LJ)];
    Dec(Width);

    // check against the next column: the loop increments i, the original decrements it first
  end;
end;

end.
