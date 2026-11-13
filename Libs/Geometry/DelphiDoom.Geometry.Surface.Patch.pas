{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the Bezier patch surface                     }
{                                                                              }
{  Port of idSurface_Patch (idlib\geometry\Surface_Patch.h and .cpp) of the    }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a          }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Surface.Patch;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.DrawVert, DelphiDoom.Geometry.Surface;

type
  /// <summary>
  ///   A grid of control points that is tessellated into a triangle surface (idSurface_Patch). The
  ///   vertices are stored row by row, <c>Width</c> per row; while subdividing they are spread over
  ///   a <c>MaxWidth</c> x <c>MaxHeight</c> buffer. Only the position, the normal and the texture
  ///   coordinates are interpolated: the tangents and the colour of new vertices are zero (in the
  ///   original they are uninitialised memory).
  /// </summary>
  TGeoSurfacePatch = class(TGeoSurface)
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FMaxWidth: Integer;
    FMaxHeight: Integer;
    FExpanded: Boolean;
    procedure PutOnCurve;
    procedure RemoveLinearColumnsRows;
    procedure ResizeExpanded(ANewHeight, ANewWidth: Integer);
    procedure Expand;
    procedure Collapse;
    procedure GenerateNormals;
    procedure GenerateIndexes;
    class procedure ProjectPointOntoVector(const APoint, AStart, AEnd: TGeoVec3; out AProjection: TGeoVec3); static;
    class procedure LerpVert(const AFirst, ASecond: TGeoDrawVert; var AOut: TGeoDrawVert); static;
    class procedure SampleSinglePatchPoint(const ACtrl: array of TGeoDrawVert; AU, AV: Single;
      var AOut: TGeoDrawVert); static;
    class procedure SampleSinglePatch(const ACtrl: array of TGeoDrawVert; ABaseColumn, ABaseRow, AWidth,
      AHorizontal, AVertical: Integer; var AOutVerts: TArray<TGeoDrawVert>); static;
  public
    constructor Create; overload;
    /// <summary>A patch with room for a maximum number of columns and rows</summary>
    constructor Create(AMaxWidth, AMaxHeight: Integer); overload;
    procedure Assign(const ASurface: TGeoSurface); override;

    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property MaxWidth: Integer read FMaxWidth;
    property MaxHeight: Integer read FMaxHeight;

    procedure SetSize(AWidth, AHeight: Integer);
    /// <summary>Subdivides the patch mesh according to the errors and the maximum span length</summary>
    procedure Subdivide(AMaxHorizontalError, AMaxVerticalError, AMaxLength: Single; AGenerateNormals: Boolean = False);
    /// <summary>Subdivides every 3x3 patch into a fixed number of horizontal and vertical steps</summary>
    procedure SubdivideExplicit(AHorizontalSubdivisions, AVerticalSubdivisions: Integer; AGenerateNormals: Boolean;
      ARemoveLinear: Boolean = False);
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath;

const
  COPLANAR_EPSILON: Single = 0.1;

type
  TNeighbor = array[0..1] of Integer;

const
  NEIGHBORS: array[0..7] of TNeighbor = ((0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (-1, 1));

function Square(AValue: Single): Single; inline;
begin
  Result := AValue * AValue;
end;

{ TGeoSurfacePatch }

constructor TGeoSurfacePatch.Create;
begin
  inherited Create;
end;

constructor TGeoSurfacePatch.Create(AMaxWidth, AMaxHeight: Integer);
begin
  inherited Create;
  FMaxWidth := AMaxWidth;
  FMaxHeight := AMaxHeight;
  SetLength(FVerts, FMaxWidth * FMaxHeight);
end;

procedure TGeoSurfacePatch.Assign(const ASurface: TGeoSurface);
begin
  inherited Assign(ASurface);
  if ASurface is TGeoSurfacePatch then
  begin
    FWidth := TGeoSurfacePatch(ASurface).FWidth;
    FHeight := TGeoSurfacePatch(ASurface).FHeight;
    FMaxWidth := TGeoSurfacePatch(ASurface).FMaxWidth;
    FMaxHeight := TGeoSurfacePatch(ASurface).FMaxHeight;
    FExpanded := TGeoSurfacePatch(ASurface).FExpanded;
  end;
end;

procedure TGeoSurfacePatch.SetSize(AWidth, AHeight: Integer);
begin
  if (AWidth < 1) or (AWidth > FMaxWidth) then
    raise EGeometryException.Create('TGeoSurfacePatch.SetSize: invalid patch width');
  if (AHeight < 1) or (AHeight > FMaxHeight) then
    raise EGeometryException.Create('TGeoSurfacePatch.SetSize: invalid patch height');
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FVerts, FWidth * FHeight);
end;

class procedure TGeoSurfacePatch.LerpVert(const AFirst, ASecond: TGeoDrawVert; var AOut: TGeoDrawVert);
begin
  AOut.Xyz.X := 0.5 * (AFirst.Xyz.X + ASecond.Xyz.X);
  AOut.Xyz.Y := 0.5 * (AFirst.Xyz.Y + ASecond.Xyz.Y);
  AOut.Xyz.Z := 0.5 * (AFirst.Xyz.Z + ASecond.Xyz.Z);
  AOut.Normal.X := 0.5 * (AFirst.Normal.X + ASecond.Normal.X);
  AOut.Normal.Y := 0.5 * (AFirst.Normal.Y + ASecond.Normal.Y);
  AOut.Normal.Z := 0.5 * (AFirst.Normal.Z + ASecond.Normal.Z);
  AOut.St.X := 0.5 * (AFirst.St.X + ASecond.St.X);
  AOut.St.Y := 0.5 * (AFirst.St.Y + ASecond.St.Y);
end;

procedure TGeoSurfacePatch.PutOnCurve;
var
  LColumn, LRow: Integer;
  LPrev, LNext, LResult: TGeoDrawVert;
begin
  FillChar(LPrev, SizeOf(LPrev), 0);
  FillChar(LNext, SizeOf(LNext), 0);
  // all the approximating points on the curve
  for LColumn := 0 to FWidth - 1 do
  begin
    LRow := 1;
    while LRow < FHeight do
    begin
      LerpVert(FVerts[LRow * FMaxWidth + LColumn], FVerts[(LRow + 1) * FMaxWidth + LColumn], LPrev);
      LerpVert(FVerts[LRow * FMaxWidth + LColumn], FVerts[(LRow - 1) * FMaxWidth + LColumn], LNext);
      LResult := FVerts[LRow * FMaxWidth + LColumn];
      LerpVert(LPrev, LNext, LResult);
      FVerts[LRow * FMaxWidth + LColumn] := LResult;
      Inc(LRow, 2);
    end;
  end;
  for LRow := 0 to FHeight - 1 do
  begin
    LColumn := 1;
    while LColumn < FWidth do
    begin
      LerpVert(FVerts[LRow * FMaxWidth + LColumn], FVerts[LRow * FMaxWidth + LColumn + 1], LPrev);
      LerpVert(FVerts[LRow * FMaxWidth + LColumn], FVerts[LRow * FMaxWidth + LColumn - 1], LNext);
      LResult := FVerts[LRow * FMaxWidth + LColumn];
      LerpVert(LPrev, LNext, LResult);
      FVerts[LRow * FMaxWidth + LColumn] := LResult;
      Inc(LColumn, 2);
    end;
  end;
end;

class procedure TGeoSurfacePatch.ProjectPointOntoVector(const APoint, AStart, AEnd: TGeoVec3;
  out AProjection: TGeoVec3);
var
  LPointVector, LVector: TGeoVec3;
begin
  LPointVector := APoint - AStart;
  LVector := AEnd - AStart;
  LVector.NormalizeSelf;
  // project onto the direction of the segment
  AProjection := AStart + LPointVector.Dot(LVector) * LVector;
end;

procedure TGeoSurfacePatch.RemoveLinearColumnsRows;
var
  LI, LJ, LK: Integer;
  LLength, LMaxLength: Single;
  LProjection, LDir: TGeoVec3;
begin
  LJ := 1;
  while LJ < FWidth - 1 do
  begin
    LMaxLength := 0;
    for LI := 0 to FHeight - 1 do
    begin
      ProjectPointOntoVector(FVerts[LI * FMaxWidth + LJ].Xyz, FVerts[LI * FMaxWidth + LJ - 1].Xyz,
        FVerts[LI * FMaxWidth + LJ + 1].Xyz, LProjection);
      LDir := FVerts[LI * FMaxWidth + LJ].Xyz - LProjection;
      LLength := LDir.LengthSqr;
      if LLength > LMaxLength then
        LMaxLength := LLength;
    end;
    if LMaxLength < Square(0.2) then
    begin
      Dec(FWidth);
      for LI := 0 to FHeight - 1 do
        for LK := LJ to FWidth - 1 do
          FVerts[LI * FMaxWidth + LK] := FVerts[LI * FMaxWidth + LK + 1];
      Dec(LJ);
    end;
    Inc(LJ);
  end;
  LJ := 1;
  while LJ < FHeight - 1 do
  begin
    LMaxLength := 0;
    for LI := 0 to FWidth - 1 do
    begin
      ProjectPointOntoVector(FVerts[LJ * FMaxWidth + LI].Xyz, FVerts[(LJ - 1) * FMaxWidth + LI].Xyz,
        FVerts[(LJ + 1) * FMaxWidth + LI].Xyz, LProjection);
      LDir := FVerts[LJ * FMaxWidth + LI].Xyz - LProjection;
      LLength := LDir.LengthSqr;
      if LLength > LMaxLength then
        LMaxLength := LLength;
    end;
    if LMaxLength < Square(0.2) then
    begin
      Dec(FHeight);
      for LI := 0 to FWidth - 1 do
        for LK := LJ to FHeight - 1 do
          FVerts[LK * FMaxWidth + LI] := FVerts[(LK + 1) * FMaxWidth + LI];
      Dec(LJ);
    end;
    Inc(LJ);
  end;
end;

procedure TGeoSurfacePatch.ResizeExpanded(ANewHeight, ANewWidth: Integer);
var
  LI, LJ: Integer;
begin
  if (ANewHeight <= FMaxHeight) and (ANewWidth <= FMaxWidth) then
    Exit;
  if ANewHeight * ANewWidth > FMaxHeight * FMaxWidth then
    SetLength(FVerts, ANewHeight * ANewWidth);
  // space out the vertices for the new height and width
  for LJ := FMaxHeight - 1 downto 0 do
    for LI := FMaxWidth - 1 downto 0 do
      FVerts[LJ * ANewWidth + LI] := FVerts[LJ * FMaxWidth + LI];
  FMaxHeight := ANewHeight;
  FMaxWidth := ANewWidth;
end;

procedure TGeoSurfacePatch.Collapse;
var
  LI, LJ: Integer;
begin
  if not FExpanded then
    raise EGeometryException.Create('TGeoSurfacePatch.Collapse: patch not expanded');
  FExpanded := False;
  if FWidth <> FMaxWidth then
    for LJ := 0 to FHeight - 1 do
      for LI := 0 to FWidth - 1 do
        FVerts[LJ * FWidth + LI] := FVerts[LJ * FMaxWidth + LI];
  SetLength(FVerts, FWidth * FHeight);
end;

procedure TGeoSurfacePatch.Expand;
var
  LI, LJ: Integer;
begin
  if FExpanded then
    raise EGeometryException.Create('TGeoSurfacePatch.Expand: patch already expanded');
  FExpanded := True;
  SetLength(FVerts, FMaxWidth * FMaxHeight);
  if FWidth <> FMaxWidth then
    for LJ := FHeight - 1 downto 0 do
      for LI := FWidth - 1 downto 0 do
        FVerts[LJ * FMaxWidth + LI] := FVerts[LJ * FWidth + LI];
end;

procedure TGeoSurfacePatch.GenerateNormals;
var
  LI, LJ, LK, LDist, LX, LY: Integer;
  LNorm, LSum, LBase, LDelta, LTemp: TGeoVec3;
  LAround: array[0..7] of TGeoVec3;
  LGood: array[0..7] of Boolean;
  LExtent: array[0..2] of TGeoVec3;
  LOffset, LD: Single;
  LWrapWidth, LWrapHeight: Boolean;
begin
  // if all the points are coplanar, set all the normals to that plane
  LExtent[0] := FVerts[FWidth - 1].Xyz - FVerts[0].Xyz;
  LExtent[1] := FVerts[(FHeight - 1) * FWidth + FWidth - 1].Xyz - FVerts[0].Xyz;
  LExtent[2] := FVerts[(FHeight - 1) * FWidth].Xyz - FVerts[0].Xyz;
  LNorm := LExtent[0].Cross(LExtent[1]);
  if LNorm.LengthSqr = 0 then
  begin
    LNorm := LExtent[0].Cross(LExtent[2]);
    if LNorm.LengthSqr = 0 then
      LNorm := LExtent[1].Cross(LExtent[2]);
  end;
  // wrapped patches may not get a valid normal here
  if LNorm.NormalizeSelf <> 0 then
  begin
    LOffset := FVerts[0].Xyz.Dot(LNorm);
    LI := 1;
    while LI < FWidth * FHeight do
    begin
      LD := FVerts[LI].Xyz.Dot(LNorm);
      if TGeoMath.Fabs(LD - LOffset) > COPLANAR_EPSILON then
        Break;
      Inc(LI);
    end;
    if LI = FWidth * FHeight then
    begin
      for LI := 0 to FWidth * FHeight - 1 do
        FVerts[LI].Normal := LNorm;
      Exit;
    end;
  end;
  // wrapped edges smooth across themselves
  LWrapWidth := False;
  LI := 0;
  while LI < FHeight do
  begin
    LDelta := FVerts[LI * FWidth].Xyz - FVerts[LI * FWidth + FWidth - 1].Xyz;
    if LDelta.LengthSqr > Square(1.0) then
      Break;
    Inc(LI);
  end;
  if LI = FHeight then
    LWrapWidth := True;
  LWrapHeight := False;
  LI := 0;
  while LI < FWidth do
  begin
    LDelta := FVerts[LI].Xyz - FVerts[(FHeight - 1) * FWidth + LI].Xyz;
    if LDelta.LengthSqr > Square(1.0) then
      Break;
    Inc(LI);
  end;
  if LI = FWidth then
    LWrapHeight := True;
  for LI := 0 to FWidth - 1 do
  begin
    for LJ := 0 to FHeight - 1 do
    begin
      LBase := FVerts[LJ * FWidth + LI].Xyz;
      for LK := 0 to 7 do
      begin
        LAround[LK].Zero;
        LGood[LK] := False;
        for LDist := 1 to 3 do
        begin
          LX := LI + NEIGHBORS[LK][0] * LDist;
          LY := LJ + NEIGHBORS[LK][1] * LDist;
          if LWrapWidth then
          begin
            if LX < 0 then
              LX := FWidth - 1 + LX
            else if LX >= FWidth then
              LX := 1 + LX - FWidth;
          end;
          if LWrapHeight then
          begin
            if LY < 0 then
              LY := FHeight - 1 + LY
            else if LY >= FHeight then
              LY := 1 + LY - FHeight;
          end;
          if (LX < 0) or (LX >= FWidth) or (LY < 0) or (LY >= FHeight) then
            Break; // edge of the patch
          LTemp := FVerts[LY * FWidth + LX].Xyz - LBase;
          if LTemp.NormalizeSelf = 0 then
            Continue; // degenerate edge, get more distance
          LGood[LK] := True;
          LAround[LK] := LTemp;
          Break;
        end;
      end;
      // the original counts the neighbours that gave a normal and never uses the count
      LSum.Zero;
      for LK := 0 to 7 do
      begin
        if (not LGood[LK]) or (not LGood[(LK + 1) and 7]) then
          Continue; // did not get two points
        LNorm := LAround[(LK + 1) and 7].Cross(LAround[LK]);
        if LNorm.NormalizeSelf = 0 then
          Continue;
        LSum := LSum + LNorm;
      end;
      FVerts[LJ * FWidth + LI].Normal := LSum;
      FVerts[LJ * FWidth + LI].Normal.NormalizeSelf;
    end;
  end;
end;

procedure TGeoSurfacePatch.GenerateIndexes;
var
  LI, LJ, LV1, LV2, LV3, LV4, LIndex: Integer;
begin
  SetLength(FIndexes, (FWidth - 1) * (FHeight - 1) * 2 * 3);
  LIndex := 0;
  for LI := 0 to FWidth - 2 do
  begin
    for LJ := 0 to FHeight - 2 do
    begin
      LV1 := LJ * FWidth + LI;
      LV2 := LV1 + 1;
      LV3 := LV1 + FWidth + 1;
      LV4 := LV1 + FWidth;
      FIndexes[LIndex] := LV1;
      FIndexes[LIndex + 1] := LV3;
      FIndexes[LIndex + 2] := LV2;
      FIndexes[LIndex + 3] := LV1;
      FIndexes[LIndex + 4] := LV4;
      FIndexes[LIndex + 5] := LV3;
      Inc(LIndex, 6);
    end;
  end;
  GenerateEdgeIndexes;
end;

class procedure TGeoSurfacePatch.SampleSinglePatchPoint(const ACtrl: array of TGeoDrawVert; AU, AV: Single;
  var AOut: TGeoDrawVert);
var
  LVCtrl: array[0..2, 0..7] of Single;
  LVPoint, LAxis: Integer;
  LA, LB, LC, LQA, LQB, LQC: Single;

  // ACtrl[k * 3 + l] is ctrl[k][l]
  function Pick(AColumn, APoint, AAxisNumber: Integer): Single;
  begin
    if AAxisNumber < 3 then
      Result := ACtrl[AColumn * 3 + APoint].Xyz[AAxisNumber]
    else if AAxisNumber < 6 then
      Result := ACtrl[AColumn * 3 + APoint].Normal[AAxisNumber - 3]
    else
      Result := ACtrl[AColumn * 3 + APoint].St[AAxisNumber - 6];
  end;

begin
  for LVPoint := 0 to 2 do
  begin
    for LAxis := 0 to 7 do
    begin
      LA := Pick(0, LVPoint, LAxis);
      LB := Pick(1, LVPoint, LAxis);
      LC := Pick(2, LVPoint, LAxis);
      LQA := LA - 2.0 * LB + LC;
      LQB := 2.0 * LB - 2.0 * LA;
      LQC := LA;
      LVCtrl[LVPoint][LAxis] := LQA * AU * AU + LQB * AU + LQC;
    end;
  end;
  for LAxis := 0 to 7 do
  begin
    LA := LVCtrl[0][LAxis];
    LB := LVCtrl[1][LAxis];
    LC := LVCtrl[2][LAxis];
    LQA := LA - 2.0 * LB + LC;
    LQB := 2.0 * LB - 2.0 * LA;
    LQC := LA;
    if LAxis < 3 then
      AOut.Xyz[LAxis] := LQA * AV * AV + LQB * AV + LQC
    else if LAxis < 6 then
      AOut.Normal[LAxis - 3] := LQA * AV * AV + LQB * AV + LQC
    else
      AOut.St[LAxis - 6] := LQA * AV * AV + LQB * AV + LQC;
  end;
end;

class procedure TGeoSurfacePatch.SampleSinglePatch(const ACtrl: array of TGeoDrawVert; ABaseColumn, ABaseRow,
  AWidth, AHorizontal, AVertical: Integer; var AOutVerts: TArray<TGeoDrawVert>);
var
  LI, LJ: Integer;
  LU, LV: Single;
begin
  Inc(AHorizontal);
  Inc(AVertical);
  for LI := 0 to AHorizontal - 1 do
  begin
    for LJ := 0 to AVertical - 1 do
    begin
      LU := LI / (AHorizontal - 1);
      LV := LJ / (AVertical - 1);
      SampleSinglePatchPoint(ACtrl, LU, LV, AOutVerts[(ABaseRow + LJ) * AWidth + LI + ABaseColumn]);
    end;
  end;
end;

procedure TGeoSurfacePatch.SubdivideExplicit(AHorizontalSubdivisions, AVerticalSubdivisions: Integer;
  AGenerateNormals: Boolean; ARemoveLinear: Boolean);
var
  LI, LJ, LK, LL, LOutWidth, LOutHeight, LBaseColumn, LBaseRow: Integer;
  LSample: array[0..8] of TGeoDrawVert;
  LOut: TArray<TGeoDrawVert>;
begin
  LOutWidth := ((FWidth - 1) div 2 * AHorizontalSubdivisions) + 1;
  LOutHeight := ((FHeight - 1) div 2 * AVerticalSubdivisions) + 1;
  SetLength(LOut, LOutWidth * LOutHeight);
  // normals of the control mesh
  if AGenerateNormals then
    GenerateNormals;
  LBaseColumn := 0;
  LI := 0;
  while LI + 2 < FWidth do
  begin
    LBaseRow := 0;
    LJ := 0;
    while LJ + 2 < FHeight do
    begin
      for LK := 0 to 2 do
        for LL := 0 to 2 do
          LSample[LK * 3 + LL] := FVerts[((LJ + LL) * FWidth) + LI + LK];
      SampleSinglePatch(LSample, LBaseColumn, LBaseRow, LOutWidth, AHorizontalSubdivisions,
        AVerticalSubdivisions, LOut);
      Inc(LBaseRow, AVerticalSubdivisions);
      Inc(LJ, 2);
    end;
    Inc(LBaseColumn, AHorizontalSubdivisions);
    Inc(LI, 2);
  end;
  FVerts := LOut;
  FWidth := LOutWidth;
  FMaxWidth := LOutWidth;
  FHeight := LOutHeight;
  FMaxHeight := LOutHeight;
  FExpanded := False;
  if ARemoveLinear then
  begin
    Expand;
    RemoveLinearColumnsRows;
    Collapse;
  end;
  // normalise all the interpolated normals
  if AGenerateNormals then
    for LI := 0 to FWidth * FHeight - 1 do
      FVerts[LI].Normal.NormalizeSelf;
  GenerateIndexes;
end;

procedure TGeoSurfacePatch.Subdivide(AMaxHorizontalError, AMaxVerticalError, AMaxLength: Single;
  AGenerateNormals: Boolean);
var
  LI, LJ, LK, LL: Integer;
  LPrev, LNext, LMid: TGeoDrawVert;
  LPrevXyz, LNextXyz, LMidXyz, LDelta: TGeoVec3;
  LMaxHorizontalErrorSqr, LMaxVerticalErrorSqr, LMaxLengthSqr: Single;
begin
  FillChar(LPrev, SizeOf(LPrev), 0);
  FillChar(LNext, SizeOf(LNext), 0);
  FillChar(LMid, SizeOf(LMid), 0);
  if AGenerateNormals then
    GenerateNormals;
  LMaxHorizontalErrorSqr := Square(AMaxHorizontalError);
  LMaxVerticalErrorSqr := Square(AMaxVerticalError);
  LMaxLengthSqr := Square(AMaxLength);
  Expand;
  // horizontal subdivisions
  LJ := 0;
  while LJ + 2 < FWidth do
  begin
    // check the subdivided midpoints against the control points
    LI := 0;
    while LI < FHeight do
    begin
      for LL := 0 to 2 do
      begin
        LPrevXyz[LL] := FVerts[LI * FMaxWidth + LJ + 1].Xyz[LL] - FVerts[LI * FMaxWidth + LJ].Xyz[LL];
        LNextXyz[LL] := FVerts[LI * FMaxWidth + LJ + 2].Xyz[LL] - FVerts[LI * FMaxWidth + LJ + 1].Xyz[LL];
        LMidXyz[LL] := (FVerts[LI * FMaxWidth + LJ].Xyz[LL] + FVerts[LI * FMaxWidth + LJ + 1].Xyz[LL] * 2.0 +
          FVerts[LI * FMaxWidth + LJ + 2].Xyz[LL]) * 0.25;
      end;
      if AMaxLength > 0 then
        // a span that is too long forces a subdivision
        if (LPrevXyz.LengthSqr > LMaxLengthSqr) or (LNextXyz.LengthSqr > LMaxLengthSqr) then
          Break;
      LDelta := FVerts[LI * FMaxWidth + LJ + 1].Xyz - LMidXyz;
      if LDelta.LengthSqr > LMaxHorizontalErrorSqr then
        Break;
      Inc(LI);
    end;
    if LI = FHeight then
    begin
      Inc(LJ, 2);
      Continue; // no subdivision needed
    end;
    if FWidth + 2 >= FMaxWidth then
      ResizeExpanded(FMaxHeight, FMaxWidth + 4);
    // insert two columns and replace the peak
    Inc(FWidth, 2);
    for LI := 0 to FHeight - 1 do
    begin
      LerpVert(FVerts[LI * FMaxWidth + LJ], FVerts[LI * FMaxWidth + LJ + 1], LPrev);
      LerpVert(FVerts[LI * FMaxWidth + LJ + 1], FVerts[LI * FMaxWidth + LJ + 2], LNext);
      LerpVert(LPrev, LNext, LMid);
      LK := FWidth - 1;
      while LK > LJ + 3 do
      begin
        FVerts[LI * FMaxWidth + LK] := FVerts[LI * FMaxWidth + LK - 2];
        Dec(LK);
      end;
      FVerts[LI * FMaxWidth + LJ + 1] := LPrev;
      FVerts[LI * FMaxWidth + LJ + 2] := LMid;
      FVerts[LI * FMaxWidth + LJ + 3] := LNext;
    end;
    // back up and check this set again, it may need more subdivision
    // (the original does j -= 2 then j += 2)
  end;
  // vertical subdivisions
  LJ := 0;
  while LJ + 2 < FHeight do
  begin
    LI := 0;
    while LI < FWidth do
    begin
      for LL := 0 to 2 do
      begin
        LPrevXyz[LL] := FVerts[(LJ + 1) * FMaxWidth + LI].Xyz[LL] - FVerts[LJ * FMaxWidth + LI].Xyz[LL];
        LNextXyz[LL] := FVerts[(LJ + 2) * FMaxWidth + LI].Xyz[LL] - FVerts[(LJ + 1) * FMaxWidth + LI].Xyz[LL];
        LMidXyz[LL] := (FVerts[LJ * FMaxWidth + LI].Xyz[LL] + FVerts[(LJ + 1) * FMaxWidth + LI].Xyz[LL] * 2.0 +
          FVerts[(LJ + 2) * FMaxWidth + LI].Xyz[LL]) * 0.25;
      end;
      if AMaxLength > 0 then
        if (LPrevXyz.LengthSqr > LMaxLengthSqr) or (LNextXyz.LengthSqr > LMaxLengthSqr) then
          Break;
      LDelta := FVerts[(LJ + 1) * FMaxWidth + LI].Xyz - LMidXyz;
      if LDelta.LengthSqr > LMaxVerticalErrorSqr then
        Break;
      Inc(LI);
    end;
    if LI = FWidth then
    begin
      Inc(LJ, 2);
      Continue;
    end;
    if FHeight + 2 >= FMaxHeight then
      ResizeExpanded(FMaxHeight + 4, FMaxWidth);
    Inc(FHeight, 2);
    for LI := 0 to FWidth - 1 do
    begin
      LerpVert(FVerts[LJ * FMaxWidth + LI], FVerts[(LJ + 1) * FMaxWidth + LI], LPrev);
      LerpVert(FVerts[(LJ + 1) * FMaxWidth + LI], FVerts[(LJ + 2) * FMaxWidth + LI], LNext);
      LerpVert(LPrev, LNext, LMid);
      LK := FHeight - 1;
      while LK > LJ + 3 do
      begin
        FVerts[LK * FMaxWidth + LI] := FVerts[(LK - 2) * FMaxWidth + LI];
        Dec(LK);
      end;
      FVerts[(LJ + 1) * FMaxWidth + LI] := LPrev;
      FVerts[(LJ + 2) * FMaxWidth + LI] := LMid;
      FVerts[(LJ + 3) * FMaxWidth + LI] := LNext;
    end;
  end;
  PutOnCurve;
  RemoveLinearColumnsRows;
  Collapse;
  // normalise all the interpolated normals
  if AGenerateNormals then
    for LI := 0 to FWidth * FHeight - 1 do
      FVerts[LI].Normal.NormalizeSelf;
  GenerateIndexes;
end;

end.
