{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore - patches of Quake III Arena: the subdivider           }
{                                                                              }
{  Port of R_SubdividePatchToGrid and InvertErrorTable (tr_curve.c). Based on  }
{  the Quake III Arena GPL Source Code (id Software). Copyright (C)            }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Patch.Subdivider;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Patch.Intf, DelphiDoom.MathCore.Patch.Types;

type
  /// <summary>
  ///   Subdivides a patch of control points into a grid with the "level of detail" rule of
  ///   Quake III: direction independent, based only on the distance of the curve from the
  ///   straight line between the control points. Where the distance is at most
  ///   <c>Subdivisions</c> (r_subdivisions) the span is not subdivided, where all points lie
  ///   on the line (less than 0.1) the column or row is removed.
  /// </summary>
  TPatchSubdivider = class(TInterfacedObject, IPatchSubdivider)
  strict private
    FSubdivisions: Single;
  public
    constructor Create(const ASubdivisions: Single);
    function SubdividePatchToGrid(const AWidth, AHeight: Integer;
      const APoints: TArray<TPatchVertex>): IPatchGrid;
    /// <summary>r_subdivisions</summary>
    property Subdivisions: Single read FSubdivisions;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Patch.ControlMesh,
  DelphiDoom.MathCore.Patch.Grid, DelphiDoom.MathCore.Patch.Normals,
  DelphiDoom.MathCore.Patch.VertexMath;

const
  // "maxLen < 0.1f": typed, a literal of Delphi would be an Extended
  COLLINEAR_LENGTH: Single = 0.1;

type
  TErrorTable = array[0..1, 0..MAX_GRID_SIZE - 1] of Single;

constructor TPatchSubdivider.Create(const ASubdivisions: Single);
begin
  inherited Create;
  FSubdivisions := ASubdivisions;
end;

function TPatchSubdivider.SubdividePatchToGrid(const AWidth, AHeight: Integer;
  const APoints: TArray<TPatchVertex>): IPatchGrid;
var
  LMesh: TPatchControlMesh;
  LErrors, LCopy: TErrorTable;
  LWidth, LHeight, LDir, LI, LJ, LK, LTemp, LL: Integer;
  LMaxLen, LLen, LProjection: Single;
  LMid, LDirection, LDelta, LProjected: TIdVec3;
  LPrev, LNext, LMiddle: TPatchVertex;
  LFirst, LSecond, LThird: TIdVec3;
  LSplit: Boolean;
begin
  if (AWidth < MIN_PATCH_SIZE) or (AHeight < MIN_PATCH_SIZE) or (AWidth > MAX_PATCH_SIZE) or
    (AHeight > MAX_PATCH_SIZE) or (not Odd(AWidth)) or (not Odd(AHeight)) then
    raise EPatchException.CreateFmt(SPatchSizeInvalid,
      [AWidth, AHeight, MIN_PATCH_SIZE, MAX_PATCH_SIZE]);
  if Length(APoints) < AWidth * AHeight then
    raise EPatchException.CreateFmt(SPatchPointsMissing,
      [AWidth, AHeight, AWidth * AHeight, Length(APoints)]);

  FillChar(LErrors, SizeOf(LErrors), 0);
  LMesh := TPatchControlMesh.Create;
  try
    LWidth := AWidth;
    LHeight := AHeight;
    for LI := 0 to LWidth - 1 do
      for LJ := 0 to LHeight - 1 do
        LMesh[LJ, LI] := APoints[LJ * LWidth + LI];

    for LDir := 0 to 1 do
    begin
      for LJ := 0 to MAX_GRID_SIZE - 1 do
        LErrors[LDir, LJ] := 0;

      // horizontal subdivisions
      LJ := 0;
      while LJ + 2 < LWidth do
      begin
        // check subdivided midpoints against control points
        LMaxLen := 0;
        for LI := 0 to LHeight - 1 do
        begin
          // calculate the point on the curve
          LFirst := LMesh[LI, LJ].Position;
          LSecond := LMesh[LI, LJ + 1].Position;
          LThird := LMesh[LI, LJ + 2].Position;
          LMid.X := TPatchVertexMath.QuadraticMidpoint(LFirst.X, LSecond.X, LThird.X);
          LMid.Y := TPatchVertexMath.QuadraticMidpoint(LFirst.Y, LSecond.Y, LThird.Y);
          LMid.Z := TPatchVertexMath.QuadraticMidpoint(LFirst.Z, LSecond.Z, LThird.Z);

          // see how far off the line it is (dist-from-line, not dist-from-midpoint)
          LMid := LMid - LFirst;
          LDirection := LThird - LFirst;
          TPatchVertexMath.Normalize(LDirection);

          LProjection := TPatchVertexMath.Dot(LMid, LDirection);
          LProjected := LDirection * LProjection;
          LDelta := LMid - LProjected;
          LLen := TPatchVertexMath.LengthSquared(LDelta); // we will do the sqrt later
          if LLen > LMaxLen then
            LMaxLen := LLen;
        end;

        LMaxLen := TPatchVertexMath.SqrtSingle(LMaxLen);

        LSplit := False;
        if LMaxLen < COLLINEAR_LENGTH then
        begin
          // all the points are on the lines: remove the entire columns
          LErrors[LDir, LJ + 1] := PATCH_COLLINEAR_ERROR;
        end
        else if LWidth + 2 > MAX_GRID_SIZE then
          LErrors[LDir, LJ + 1] := 1 / LMaxLen // can't subdivide any more
        else if LMaxLen <= FSubdivisions then
          LErrors[LDir, LJ + 1] := 1 / LMaxLen // didn't need subdivision
        else
        begin
          LErrors[LDir, LJ + 2] := 1 / LMaxLen;
          LSplit := True;
        end;

        if not LSplit then
        begin
          Inc(LJ, 2);
          Continue;
        end;

        // insert two columns and replace the peak
        Inc(LWidth, 2);
        for LI := 0 to LHeight - 1 do
        begin
          LPrev := TPatchVertexMath.Lerp(LMesh[LI, LJ], LMesh[LI, LJ + 1]);
          LNext := TPatchVertexMath.Lerp(LMesh[LI, LJ + 1], LMesh[LI, LJ + 2]);
          LMiddle := TPatchVertexMath.Lerp(LPrev, LNext);
          for LK := LWidth - 1 downto LJ + 4 do
            LMesh[LI, LK] := LMesh[LI, LK - 2];
          LMesh[LI, LJ + 1] := LPrev;
          LMesh[LI, LJ + 2] := LMiddle;
          LMesh[LI, LJ + 3] := LNext;
        end;
        // back up and recheck this set again, it may need more subdivision: j stays
      end;

      LMesh.Transpose(LWidth, LHeight);
      LTemp := LWidth;
      LWidth := LHeight;
      LHeight := LTemp;
    end;

    // put all the approximating points on the curve
    LMesh.PutPointsOnCurve(LWidth, LHeight);

    // cull out any rows or columns that are collinear
    LI := 1;
    while LI < LWidth - 1 do
    begin
      if LErrors[0, LI] = PATCH_COLLINEAR_ERROR then
      begin
        for LJ := LI + 1 to LWidth - 1 do
        begin
          for LK := 0 to LHeight - 1 do
            LMesh[LK, LJ - 1] := LMesh[LK, LJ];
          LErrors[0, LJ - 1] := LErrors[0, LJ];
        end;
        Dec(LWidth);
      end;
      Inc(LI);
    end;

    LI := 1;
    while LI < LHeight - 1 do
    begin
      if LErrors[1, LI] = PATCH_COLLINEAR_ERROR then
      begin
        for LJ := LI + 1 to LHeight - 1 do
        begin
          for LK := 0 to LWidth - 1 do
            LMesh[LJ - 1, LK] := LMesh[LJ, LK];
          LErrors[1, LJ - 1] := LErrors[1, LJ];
        end;
        Dec(LHeight);
      end;
      Inc(LI);
    end;

    // flip for longest tristrips as an optimization (visually identical without it)
    if LHeight > LWidth then
    begin
      LMesh.Transpose(LWidth, LHeight);
      // InvertErrorTable( errorTable, width, height ), with the sizes before the swap
      LCopy := LErrors;
      for LL := 0 to LWidth - 1 do
        LErrors[1, LL] := LCopy[0, LL];
      for LL := 0 to LHeight - 1 do
        LErrors[0, LL] := LCopy[1, LHeight - 1 - LL];
      LTemp := LWidth;
      LWidth := LHeight;
      LHeight := LTemp;
      LMesh.InvertColumns(LWidth, LHeight);
    end;

    // calculate normals
    TPatchNormals.Compute(LMesh, LWidth, LHeight);

    Result := TPatchGrid.Create(LMesh, LWidth, LHeight, LErrors[0], LErrors[1]);
  finally
    LMesh.Free;
  end;
end;

end.
