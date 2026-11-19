{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1b) - the sky         }
{                                                                              }
{  R_InitSkyTexCoords, RB_ClipSkyPolygons (with ClipSkyPolygon and             }
{  AddSkyPolygon), MakeSkyVec, DrawSkyBox, R_BuildCloudData (FillCloudBox and  }
{  FillCloudySkySide) and RB_DrawSun of renderer\tr_sky.c. Based on the Quake  }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Backend.Sky;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Decl.Q3Shader.Calc.Types,
  DelphiDoom.Q3Render.Backend.Gl;

const
  /// <summary>SKY_SUBDIVISIONS and HALF_SKY_SUBDIVISIONS of tr_sky.c</summary>
  Q3_SKY_SUBDIVISIONS = 8;
  Q3_HALF_SKY_SUBDIVISIONS = Q3_SKY_SUBDIVISIONS div 2;

type
  /// <summary>One vertex of a strip of the sky box: the texture coordinate and the position (qglTexCoord2fv, qglVertex3fv)</summary>
  TQ3SkyVertex = record
    St: array[0..1] of Single;
    Xyz: TQ3Vec3;
  end;

  /// <summary>One triangle strip of a side of the box (qglBegin(GL_TRIANGLE_STRIP) ... qglEnd)</summary>
  TQ3SkyStrip = TArray<TQ3SkyVertex>;

  /// <summary>The strips of a side and the index of its image in the outer box (sky_texorder applied)</summary>
  TQ3SkySideDraw = record
    ImageIndex: Integer;
    Strips: TArray<TQ3SkyStrip>;
  end;

  /// <summary>
  ///   The sky of a view: the faces of the box that the sky polygons touch (RB_ClipSkyPolygons), the vertexes of those
  ///   faces for the outer box (DrawSkyBox) or for the layer of clouds (R_BuildCloudData), and the tables of the clouds
  ///   (R_InitSkyTexCoords). The statics of the original are the fields
  /// </summary>
  /// <remarks>
  ///   The tables of the clouds are global in the original and are rebuilt by every sky shader that is parsed (the
  ///   last one wins for every sky); here the caller gives the height of the clouds of the shader that is drawn
  /// </remarks>
  TQ3SkyBox = class
  strict private
    FSkyMins: array[0..1, 0..5] of Single;
    FSkyMaxs: array[0..1, 0..5] of Single;
    FSkyMin: Single;
    FSkyMax: Single;
    FPoints: array[0..Q3_SKY_SUBDIVISIONS, 0..Q3_SKY_SUBDIVISIONS] of TQ3Vec3;
    FTexCoords: array[0..Q3_SKY_SUBDIVISIONS, 0..Q3_SKY_SUBDIVISIONS, 0..1] of Single;
    FCloudTexCoords: array[0..5, 0..Q3_SKY_SUBDIVISIONS, 0..Q3_SKY_SUBDIVISIONS, 0..1] of Single;
    FCloudTexP: array[0..5, 0..Q3_SKY_SUBDIVISIONS, 0..Q3_SKY_SUBDIVISIONS] of Single;
    FCloudHeight: Single;
    FHaveClouds: Boolean;
    procedure AddSkyPolygon(ANumPoints: Integer; const AVecs: array of Single);
    procedure ClipSkyPolygon(ANumPoints: Integer; const AVecs: array of Single; AStage: Integer);
    procedure ClearSkyBox;
    procedure MakeSkyVec(ASPos, ATPos: Single; AAxis: Integer; AZFar: Single; out AOutS, AOutT: Single;
      out AOutXyz: TQ3Vec3);
    procedure FillCloudySkySide(const AMins, AMaxs: array of Integer; AAddIndexes: Boolean;
      const AViewOrigin: TQ3Vec3; var ATess: TQ3ShaderTess);
    procedure FillCloudBox(AStage: Integer; AZFar: Single; const AViewOrigin: TQ3Vec3; var ATess: TQ3ShaderTess);
  public
    /// <summary>R_InitSkyTexCoords: the tables of the clouds for a height (zFar is 1024 for the calls of MakeSkyVec)</summary>
    procedure InitTexCoords(AHeightCloud: Single);
    /// <summary>RB_ClipSkyPolygons: the faces of the box that the triangles of tess touch</summary>
    procedure ClipPolygons(const ATess: TQ3ShaderTess; const AViewOrigin: TQ3Vec3);
    /// <summary>
    ///   DrawSkyBox: the strips of every face that has sky, with the index of the image of the outer box that goes with
    ///   it. The minimums and maximums of the faces are rounded to the subdivisions, as the original leaves them
    /// </summary>
    function OuterBox(AZFar: Single): TArray<TQ3SkySideDraw>;
    /// <summary>
    ///   R_BuildCloudData: tess is emptied and the layer of clouds is put in it, once for every stage of the shader
    ///   (indexes only for the first). More than SHADER_MAX_VERTEXES vertexes is an EDeclQ3ShaderCalcException
    ///   (ri.Error of the original)
    /// </summary>
    procedure BuildCloudData(var ATess: TQ3ShaderTess; AStageCount: Integer; ACloudHeight, AZFar: Single;
      const AViewOrigin: TQ3Vec3);
    /// <summary>
    ///   RB_StageIteratorSky: all of the visible sky triangles are in tess. Projects them on the box, draws the outer
    ///   box (the GL calls go to the sink, the bound image and the state through the procedures), builds the clouds in
    ///   tess and has the generic iterator draw them. False when r_fastsky skips the sky (the sun is then not drawn)
    /// </summary>
    /// <param name="AOuterBox">the shader has an outer box that is not the default image</param>
    /// <param name="ABind">GL_Bind of the image of the outer box with this index</param>
    /// <param name="AState">GL_State</param>
    /// <param name="AGeneric">RB_StageIteratorGeneric</param>
    function StageIterator(var ATess: TQ3ShaderTess; const AViewOrigin: TQ3Vec3; AZFar: Single; AFastSky, AShowSky,
      AOuterBox: Boolean; AIdentityLight, ACloudHeight: Single; AStageCount: Integer; const ASink: IQ3GlSink;
      const ABind: TProc<Integer>; const AState: TProc<Cardinal>; const AGeneric: TProc): Boolean;
    /// <summary>
    ///   RB_DrawSun after RB_BeginSurface: the quad of the sun at the far end of the sun direction (the caller moves
    ///   the matrix to the viewer and sets the depth range)
    /// </summary>
    class procedure SunQuad(var ATess: TQ3ShaderTess; const ASunDirection: TQ3Vec3; AZFar: Single); static;
    /// <summary>
    ///   RB_DrawSun: the quad of the sun with the matrix moved to the viewer and the farthest depth range. Nothing
    ///   unless a sky was drawn in this view and r_drawSun is on. The original never calls it (it is under #if 0 in
    ///   RB_RenderDrawSurfList)
    /// </summary>
    class function DrawSun(var ATess: TQ3ShaderTess; const ASunDirection, AViewOrigin: TQ3Vec3; AZFar: Single;
      const AWorldModelMatrix: array of Single; ASkyRendered, ADrawSun: Boolean; const ASink: IQ3GlSink;
      const ABeginSurface, AEndSurface: TProc): Boolean; static;
    /// <summary>sky_mins[AAxis][AFace]</summary>
    function SkyMin(AAxis, AFace: Integer): Single;
    /// <summary>sky_maxs[AAxis][AFace]</summary>
    function SkyMax(AAxis, AFace: Integer): Single;
    /// <summary>s_cloudTexCoords[AFace][ATPos][ASPos][AIndex]</summary>
    function CloudTexCoord(AFace, ATPos, ASPos, AIndex: Integer): Single;
    /// <summary>s_cloudTexP[AFace][ATPos][ASPos]</summary>
    function CloudTexP(AFace, ATPos, ASPos: Integer): Single;
  end;

implementation

uses
  System.Math, DelphiDoom.Collision.Q3.VectorMath, DelphiDoom.Q3Host.ClientMathSyscalls, DelphiDoom.Q3Render.Types;

const
  SHADER_MAX_VERTEXES = 1000;
  ON_EPSILON: Single = 0.1;
  MAX_CLIP_VERTS = 64;
  // dv < 0.001 compares a float with a double
  DIVIDE_EPSILON: Double = 0.001;
  SQ3RenderSkyVertexes = 'SHADER_MAX_VERTEXES hit in FillCloudySkySide()';
  SQ3RenderSkyClip = 'ClipSkyPolygon: MAX_CLIP_VERTS';

  SkyClip: array[0..5, 0..2] of Single = ((1, 1, 0), (1, -1, 0), (0, -1, 1), (0, 1, 1), (1, 0, 1), (-1, 0, 1));
  // s = [0]/[2], t = [1]/[2]
  VecToSt: array[0..5, 0..2] of Integer = ((-2, 3, 1), (2, 3, -1), (1, 3, 2), (-1, 3, -2), (-2, -1, 3), (-2, 1, -3));
  // 1 = s, 2 = t, 3 = 2048
  StToVec: array[0..5, 0..2] of Integer = ((3, -1, 2), (-3, 1, 2), (1, 3, 2), (-1, -3, 2), (-2, -1, 3), (2, -1, -3));
  SkyTexOrder: array[0..5] of Integer = (0, 2, 1, 3, 4, 5);

{ TQ3SkyBox }

function TQ3SkyBox.SkyMin(AAxis, AFace: Integer): Single;
begin
  Result := FSkyMins[AAxis, AFace];
end;

function TQ3SkyBox.SkyMax(AAxis, AFace: Integer): Single;
begin
  Result := FSkyMaxs[AAxis, AFace];
end;

function TQ3SkyBox.CloudTexCoord(AFace, ATPos, ASPos, AIndex: Integer): Single;
begin
  Result := FCloudTexCoords[AFace, ATPos, ASPos, AIndex];
end;

function TQ3SkyBox.CloudTexP(AFace, ATPos, ASPos: Integer): Single;
begin
  Result := FCloudTexP[AFace, ATPos, ASPos];
end;

procedure TQ3SkyBox.ClearSkyBox;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 5 do
  begin
    FSkyMins[0, LIndex] := 9999;
    FSkyMins[1, LIndex] := 9999;
    FSkyMaxs[0, LIndex] := -9999;
    FSkyMaxs[1, LIndex] := -9999;
  end;
end;

procedure TQ3SkyBox.AddSkyPolygon(ANumPoints: Integer; const AVecs: array of Single);
var
  LIndex, LJ, LAxis: Integer;
  V, LAbs: TQ3Vec3;
  LS, LT, LDv: Single;
begin
  // decide which face it maps to
  V[0] := 0;
  V[1] := 0;
  V[2] := 0;
  for LIndex := 0 to ANumPoints - 1 do
  begin
    V[0] := AVecs[LIndex * 3] + V[0];
    V[1] := AVecs[LIndex * 3 + 1] + V[1];
    V[2] := AVecs[LIndex * 3 + 2] + V[2];
  end;
  LAbs[0] := Abs(V[0]);
  LAbs[1] := Abs(V[1]);
  LAbs[2] := Abs(V[2]);
  if (LAbs[0] > LAbs[1]) and (LAbs[0] > LAbs[2]) then
  begin
    if V[0] < 0 then
      LAxis := 1
    else
      LAxis := 0;
  end
  else if (LAbs[1] > LAbs[2]) and (LAbs[1] > LAbs[0]) then
  begin
    if V[1] < 0 then
      LAxis := 3
    else
      LAxis := 2;
  end
  else
  begin
    if V[2] < 0 then
      LAxis := 5
    else
      LAxis := 4;
  end;
  // project new texture coords
  for LIndex := 0 to ANumPoints - 1 do
  begin
    LJ := VecToSt[LAxis, 2];
    if LJ > 0 then
      LDv := AVecs[LIndex * 3 + LJ - 1]
    else
      LDv := -AVecs[LIndex * 3 - LJ - 1];
    // don't divide by zero
    if LDv < DIVIDE_EPSILON then
      Continue;
    LJ := VecToSt[LAxis, 0];
    if LJ < 0 then
      LS := -AVecs[LIndex * 3 - LJ - 1] / LDv
    else
      LS := AVecs[LIndex * 3 + LJ - 1] / LDv;
    LJ := VecToSt[LAxis, 1];
    if LJ < 0 then
      LT := -AVecs[LIndex * 3 - LJ - 1] / LDv
    else
      LT := AVecs[LIndex * 3 + LJ - 1] / LDv;
    if LS < FSkyMins[0, LAxis] then
      FSkyMins[0, LAxis] := LS;
    if LT < FSkyMins[1, LAxis] then
      FSkyMins[1, LAxis] := LT;
    if LS > FSkyMaxs[0, LAxis] then
      FSkyMaxs[0, LAxis] := LS;
    if LT > FSkyMaxs[1, LAxis] then
      FSkyMaxs[1, LAxis] := LT;
  end;
end;

procedure TQ3SkyBox.ClipSkyPolygon(ANumPoints: Integer; const AVecs: array of Single; AStage: Integer);
var
  LFront, LBack: Boolean;
  LDists: array[0..MAX_CLIP_VERTS - 1] of Single;
  LSides: array[0..MAX_CLIP_VERTS - 1] of Integer;
  LNewV: array[0..1] of array[0..MAX_CLIP_VERTS * 3 - 1] of Single;
  LNewC: array[0..1] of Integer;
  LVecs: array[0..(MAX_CLIP_VERTS + 1) * 3 - 1] of Single;
  LIndex, LJ: Integer;
  D, E, LTerm, LSum: Single;
begin
  if ANumPoints > MAX_CLIP_VERTS - 2 then
    raise EQ3RenderException.Create(SQ3RenderSkyClip);
  if AStage = 6 then
  begin
    // fully clipped, so draw it
    AddSkyPolygon(ANumPoints, AVecs);
    Exit;
  end;
  LFront := False;
  LBack := False;
  for LIndex := 0 to ANumPoints - 1 do
  begin
    LSum := AVecs[LIndex * 3] * SkyClip[AStage, 0];
    LTerm := AVecs[LIndex * 3 + 1] * SkyClip[AStage, 1];
    LSum := LSum + LTerm;
    LTerm := AVecs[LIndex * 3 + 2] * SkyClip[AStage, 2];
    D := LSum + LTerm;
    if D > ON_EPSILON then
    begin
      LFront := True;
      LSides[LIndex] := 0;
    end
    else if D < -ON_EPSILON then
    begin
      LBack := True;
      LSides[LIndex] := 1;
    end
    else
      LSides[LIndex] := 2;
    LDists[LIndex] := D;
  end;
  if (not LFront) or (not LBack) then
  begin
    // not clipped
    ClipSkyPolygon(ANumPoints, AVecs, AStage + 1);
    Exit;
  end;
  // clip it: the first point is repeated after the last
  for LIndex := 0 to ANumPoints * 3 - 1 do
    LVecs[LIndex] := AVecs[LIndex];
  LSides[ANumPoints] := LSides[0];
  LDists[ANumPoints] := LDists[0];
  LVecs[ANumPoints * 3] := LVecs[0];
  LVecs[ANumPoints * 3 + 1] := LVecs[1];
  LVecs[ANumPoints * 3 + 2] := LVecs[2];
  LNewC[0] := 0;
  LNewC[1] := 0;
  for LIndex := 0 to ANumPoints - 1 do
  begin
    case LSides[LIndex] of
      0:
        begin
          for LJ := 0 to 2 do
            LNewV[0][LNewC[0] * 3 + LJ] := LVecs[LIndex * 3 + LJ];
          Inc(LNewC[0]);
        end;
      1:
        begin
          for LJ := 0 to 2 do
            LNewV[1][LNewC[1] * 3 + LJ] := LVecs[LIndex * 3 + LJ];
          Inc(LNewC[1]);
        end;
    else
      begin
        for LJ := 0 to 2 do
          LNewV[0][LNewC[0] * 3 + LJ] := LVecs[LIndex * 3 + LJ];
        Inc(LNewC[0]);
        for LJ := 0 to 2 do
          LNewV[1][LNewC[1] * 3 + LJ] := LVecs[LIndex * 3 + LJ];
        Inc(LNewC[1]);
      end;
    end;
    if (LSides[LIndex] = 2) or (LSides[LIndex + 1] = 2) or (LSides[LIndex + 1] = LSides[LIndex]) then
      Continue;
    LTerm := LDists[LIndex] - LDists[LIndex + 1];
    D := LDists[LIndex] / LTerm;
    for LJ := 0 to 2 do
    begin
      LTerm := LVecs[LIndex * 3 + LJ + 3] - LVecs[LIndex * 3 + LJ];
      LTerm := D * LTerm;
      E := LVecs[LIndex * 3 + LJ] + LTerm;
      LNewV[0][LNewC[0] * 3 + LJ] := E;
      LNewV[1][LNewC[1] * 3 + LJ] := E;
    end;
    Inc(LNewC[0]);
    Inc(LNewC[1]);
  end;
  // continue
  ClipSkyPolygon(LNewC[0], LNewV[0], AStage + 1);
  ClipSkyPolygon(LNewC[1], LNewV[1], AStage + 1);
end;

procedure TQ3SkyBox.ClipPolygons(const ATess: TQ3ShaderTess; const AViewOrigin: TQ3Vec3);
var
  LIndex, LJ, LAxis: Integer;
  LPoints: array[0..14] of Single;
begin
  ClearSkyBox;
  LIndex := 0;
  while LIndex < ATess.NumIndexes do
  begin
    for LJ := 0 to 2 do
      for LAxis := 0 to 2 do
        LPoints[LJ * 3 + LAxis] := ATess.Xyz[ATess.Indexes[LIndex + LJ] * 4 + LAxis] - AViewOrigin[LAxis];
    ClipSkyPolygon(3, LPoints, 0);
    Inc(LIndex, 3);
  end;
end;

procedure TQ3SkyBox.MakeSkyVec(ASPos, ATPos: Single; AAxis: Integer; AZFar: Single; out AOutS, AOutT: Single;
  out AOutXyz: TQ3Vec3);
var
  B: TQ3Vec3;
  LJ, LK: Integer;
  LBoxSize: Single;
  LDouble: Double;
begin
  LDouble := AZFar / 1.75;
  LBoxSize := LDouble;
  B[0] := ASPos * LBoxSize;
  B[1] := ATPos * LBoxSize;
  B[2] := LBoxSize;
  for LJ := 0 to 2 do
  begin
    LK := StToVec[AAxis, LJ];
    if LK < 0 then
      AOutXyz[LJ] := -B[-LK - 1]
    else
      AOutXyz[LJ] := B[LK - 1];
  end;
  // avoid bilerp seam
  LDouble := (ASPos + 1) * 0.5;
  ASPos := LDouble;
  LDouble := (ATPos + 1) * 0.5;
  ATPos := LDouble;
  if ASPos < FSkyMin then
    ASPos := FSkyMin
  else if ASPos > FSkyMax then
    ASPos := FSkyMax;
  if ATPos < FSkyMin then
    ATPos := FSkyMin
  else if ATPos > FSkyMax then
    ATPos := FSkyMax;
  LDouble := 1.0 - ATPos;
  ATPos := LDouble;
  AOutS := ASPos;
  AOutT := ATPos;
end;

function TQ3SkyBox.OuterBox(AZFar: Single): TArray<TQ3SkySideDraw>;
var
  LFace, LS, LT, LAxis: Integer;
  LMinsSubd, LMaxsSubd: array[0..1] of Integer;
  LSide: TQ3SkySideDraw;
  LStrip: TQ3SkyStrip;
  LSS, LST: Single;
  LDouble: Double;
  LList: TArray<TQ3SkySideDraw>;

  function Clamp(AValue: Integer): Integer;
  begin
    if AValue < -Q3_HALF_SKY_SUBDIVISIONS then
      Result := -Q3_HALF_SKY_SUBDIVISIONS
    else if AValue > Q3_HALF_SKY_SUBDIVISIONS then
      Result := Q3_HALF_SKY_SUBDIVISIONS
    else
      Result := AValue;
  end;

begin
  SetLength(LList, 0);
  FSkyMin := 0;
  FSkyMax := 1;
  FillChar(FTexCoords, SizeOf(FTexCoords), 0);
  for LFace := 0 to 5 do
  begin
    for LAxis := 0 to 1 do
    begin
      LDouble := Floor(Double(FSkyMins[LAxis, LFace] * Q3_HALF_SKY_SUBDIVISIONS)) / Q3_HALF_SKY_SUBDIVISIONS;
      FSkyMins[LAxis, LFace] := LDouble;
      LDouble := Ceil(Double(FSkyMaxs[LAxis, LFace] * Q3_HALF_SKY_SUBDIVISIONS)) / Q3_HALF_SKY_SUBDIVISIONS;
      FSkyMaxs[LAxis, LFace] := LDouble;
    end;
    if (FSkyMins[0, LFace] >= FSkyMaxs[0, LFace]) or (FSkyMins[1, LFace] >= FSkyMaxs[1, LFace]) then
      Continue;
    for LAxis := 0 to 1 do
    begin
      LMinsSubd[LAxis] := Clamp(Trunc(FSkyMins[LAxis, LFace] * Q3_HALF_SKY_SUBDIVISIONS));
      LMaxsSubd[LAxis] := Clamp(Trunc(FSkyMaxs[LAxis, LFace] * Q3_HALF_SKY_SUBDIVISIONS));
    end;
    // iterate through the subdivisions
    for LT := LMinsSubd[1] + Q3_HALF_SKY_SUBDIVISIONS to LMaxsSubd[1] + Q3_HALF_SKY_SUBDIVISIONS do
      for LS := LMinsSubd[0] + Q3_HALF_SKY_SUBDIVISIONS to LMaxsSubd[0] + Q3_HALF_SKY_SUBDIVISIONS do
      begin
        MakeSkyVec((LS - Q3_HALF_SKY_SUBDIVISIONS) / Single(Q3_HALF_SKY_SUBDIVISIONS),
          (LT - Q3_HALF_SKY_SUBDIVISIONS) / Single(Q3_HALF_SKY_SUBDIVISIONS), LFace, AZFar, LSS, LST,
          FPoints[LT, LS]);
        FTexCoords[LT, LS, 0] := LSS;
        FTexCoords[LT, LS, 1] := LST;
      end;
    // DrawSkySide
    LSide := Default(TQ3SkySideDraw);
    LSide.ImageIndex := SkyTexOrder[LFace];
    for LT := LMinsSubd[1] + Q3_HALF_SKY_SUBDIVISIONS to LMaxsSubd[1] + Q3_HALF_SKY_SUBDIVISIONS - 1 do
    begin
      SetLength(LStrip, 0);
      for LS := LMinsSubd[0] + Q3_HALF_SKY_SUBDIVISIONS to LMaxsSubd[0] + Q3_HALF_SKY_SUBDIVISIONS do
      begin
        SetLength(LStrip, Length(LStrip) + 2);
        LStrip[High(LStrip) - 1].St[0] := FTexCoords[LT, LS, 0];
        LStrip[High(LStrip) - 1].St[1] := FTexCoords[LT, LS, 1];
        LStrip[High(LStrip) - 1].Xyz := FPoints[LT, LS];
        LStrip[High(LStrip)].St[0] := FTexCoords[LT + 1, LS, 0];
        LStrip[High(LStrip)].St[1] := FTexCoords[LT + 1, LS, 1];
        LStrip[High(LStrip)].Xyz := FPoints[LT + 1, LS];
      end;
      SetLength(LSide.Strips, Length(LSide.Strips) + 1);
      LSide.Strips[High(LSide.Strips)] := LStrip;
    end;
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := LSide;
  end;
  Result := LList;
end;

procedure TQ3SkyBox.FillCloudySkySide(const AMins, AMaxs: array of Integer; AAddIndexes: Boolean;
  const AViewOrigin: TQ3Vec3; var ATess: TQ3ShaderTess);
var
  LS, LT, LVertexStart, LHeight, LWidth, LBase, LAxis: Integer;
begin
  LVertexStart := ATess.NumVertexes;
  LHeight := AMaxs[1] - AMins[1] + 1;
  LWidth := AMaxs[0] - AMins[0] + 1;
  for LT := AMins[1] + Q3_HALF_SKY_SUBDIVISIONS to AMaxs[1] + Q3_HALF_SKY_SUBDIVISIONS do
    for LS := AMins[0] + Q3_HALF_SKY_SUBDIVISIONS to AMaxs[0] + Q3_HALF_SKY_SUBDIVISIONS do
    begin
      LBase := ATess.NumVertexes * 4;
      for LAxis := 0 to 2 do
        ATess.Xyz[LBase + LAxis] := FPoints[LT, LS][LAxis] + AViewOrigin[LAxis];
      ATess.TexCoords[LBase] := FTexCoords[LT, LS, 0];
      ATess.TexCoords[LBase + 1] := FTexCoords[LT, LS, 1];
      Inc(ATess.NumVertexes);
      if ATess.NumVertexes >= SHADER_MAX_VERTEXES then
        raise EQ3RenderException.Create(SQ3RenderSkyVertexes);
    end;
  // only add indexes for one pass, otherwise it would draw multiple times for each pass
  if AAddIndexes then
    for LT := 0 to LHeight - 2 do
      for LS := 0 to LWidth - 2 do
      begin
        ATess.Indexes[ATess.NumIndexes] := LVertexStart + LS + LT * LWidth;
        ATess.Indexes[ATess.NumIndexes + 1] := LVertexStart + LS + (LT + 1) * LWidth;
        ATess.Indexes[ATess.NumIndexes + 2] := LVertexStart + LS + 1 + LT * LWidth;
        ATess.Indexes[ATess.NumIndexes + 3] := LVertexStart + LS + (LT + 1) * LWidth;
        ATess.Indexes[ATess.NumIndexes + 4] := LVertexStart + LS + 1 + (LT + 1) * LWidth;
        ATess.Indexes[ATess.NumIndexes + 5] := LVertexStart + LS + 1 + LT * LWidth;
        Inc(ATess.NumIndexes, 6);
      end;
end;

procedure TQ3SkyBox.FillCloudBox(AStage: Integer; AZFar: Single; const AViewOrigin: TQ3Vec3;
  var ATess: TQ3ShaderTess);
var
  LFace, LS, LT, LAxis: Integer;
  LMinsSubd, LMaxsSubd: array[0..1] of Integer;
  LMinT: Integer;
  LDouble: Double;
  LSS, LST: Single;

  function ClampS(AValue: Integer): Integer;
  begin
    if AValue < -Q3_HALF_SKY_SUBDIVISIONS then
      Result := -Q3_HALF_SKY_SUBDIVISIONS
    else if AValue > Q3_HALF_SKY_SUBDIVISIONS then
      Result := Q3_HALF_SKY_SUBDIVISIONS
    else
      Result := AValue;
  end;

  function ClampT(AValue: Integer): Integer;
  begin
    if AValue < LMinT then
      Result := LMinT
    else if AValue > Q3_HALF_SKY_SUBDIVISIONS then
      Result := Q3_HALF_SKY_SUBDIVISIONS
    else
      Result := AValue;
  end;

begin
  for LFace := 0 to 5 do
  begin
    LMinT := -Q3_HALF_SKY_SUBDIVISIONS;
    // still don't want to draw the bottom, even if fullClouds
    if LFace = 5 then
      Continue;
    for LAxis := 0 to 1 do
    begin
      LDouble := Floor(Double(FSkyMins[LAxis, LFace] * Q3_HALF_SKY_SUBDIVISIONS)) / Q3_HALF_SKY_SUBDIVISIONS;
      FSkyMins[LAxis, LFace] := LDouble;
      LDouble := Ceil(Double(FSkyMaxs[LAxis, LFace] * Q3_HALF_SKY_SUBDIVISIONS)) / Q3_HALF_SKY_SUBDIVISIONS;
      FSkyMaxs[LAxis, LFace] := LDouble;
    end;
    if (FSkyMins[0, LFace] >= FSkyMaxs[0, LFace]) or (FSkyMins[1, LFace] >= FSkyMaxs[1, LFace]) then
      Continue;
    LMinsSubd[0] := ClampS(Trunc(FSkyMins[0, LFace] * Q3_HALF_SKY_SUBDIVISIONS));
    LMinsSubd[1] := ClampT(Trunc(FSkyMins[1, LFace] * Q3_HALF_SKY_SUBDIVISIONS));
    LMaxsSubd[0] := ClampS(Trunc(FSkyMaxs[0, LFace] * Q3_HALF_SKY_SUBDIVISIONS));
    LMaxsSubd[1] := ClampT(Trunc(FSkyMaxs[1, LFace] * Q3_HALF_SKY_SUBDIVISIONS));
    // iterate through the subdivisions
    for LT := LMinsSubd[1] + Q3_HALF_SKY_SUBDIVISIONS to LMaxsSubd[1] + Q3_HALF_SKY_SUBDIVISIONS do
      for LS := LMinsSubd[0] + Q3_HALF_SKY_SUBDIVISIONS to LMaxsSubd[0] + Q3_HALF_SKY_SUBDIVISIONS do
      begin
        MakeSkyVec((LS - Q3_HALF_SKY_SUBDIVISIONS) / Single(Q3_HALF_SKY_SUBDIVISIONS),
          (LT - Q3_HALF_SKY_SUBDIVISIONS) / Single(Q3_HALF_SKY_SUBDIVISIONS), LFace, AZFar, LSS, LST,
          FPoints[LT, LS]);
        FTexCoords[LT, LS, 0] := FCloudTexCoords[LFace, LT, LS, 0];
        FTexCoords[LT, LS, 1] := FCloudTexCoords[LFace, LT, LS, 1];
      end;
    // only add indexes for first stage
    FillCloudySkySide(LMinsSubd, LMaxsSubd, AStage = 0, AViewOrigin, ATess);
  end;
end;

procedure TQ3SkyBox.BuildCloudData(var ATess: TQ3ShaderTess; AStageCount: Integer; ACloudHeight, AZFar: Single;
  const AViewOrigin: TQ3Vec3);
var
  LStage: Integer;
begin
  FSkyMin := 1.0 / 256.0;
  FSkyMax := 255.0 / 256.0;
  // set up for drawing
  ATess.NumIndexes := 0;
  ATess.NumVertexes := 0;
  if ACloudHeight <> 0 then
  begin
    if (not FHaveClouds) or (FCloudHeight <> ACloudHeight) then
      InitTexCoords(ACloudHeight);
    for LStage := 0 to AStageCount - 1 do
      FillCloudBox(LStage, AZFar, AViewOrigin, ATess);
  end;
end;

procedure TQ3SkyBox.InitTexCoords(AHeightCloud: Single);
const
  RadiusWorld: Single = 4096;
var
  LFace, LS, LT: Integer;
  LSkyVec, LV: TQ3Vec3;
  LSS, LST: Single;
  LP, LInverse, LNegative, LSqrtArg: Single;
  LA, LB, LTerm: Single;
  LRoot, LDoubleSum, LDoubleP: Double;
begin
  FSkyMin := 0;
  FSkyMax := 1;
  FCloudHeight := AHeightCloud;
  FHaveClouds := True;
  for LFace := 0 to 5 do
    for LT := 0 to Q3_SKY_SUBDIVISIONS do
      for LS := 0 to Q3_SKY_SUBDIVISIONS do
      begin
        // compute vector from view origin to sky side integral point (zFar is 1024 here)
        MakeSkyVec((LS - Q3_HALF_SKY_SUBDIVISIONS) / Single(Q3_HALF_SKY_SUBDIVISIONS),
          (LT - Q3_HALF_SKY_SUBDIVISIONS) / Single(Q3_HALF_SKY_SUBDIVISIONS), LFace, 1024, LSS, LST, LSkyVec);
        // compute parametric value 'p' that intersects with cloud layer
        LInverse := TQ3VectorMath.Dot(LSkyVec, LSkyVec);
        LInverse := 2 * LInverse;
        LInverse := 1.0 / LInverse;
        // SQR( skyVec[2] ) * SQR( radiusWorld )
        LA := LSkyVec[2] * LSkyVec[2];
        LB := RadiusWorld * RadiusWorld;
        LSqrtArg := LA * LB;
        // + 2 * SQR( skyVec[0] ) * radiusWorld * heightCloud
        LA := LSkyVec[0] * LSkyVec[0];
        LA := 2 * LA;
        LA := LA * RadiusWorld;
        LA := LA * AHeightCloud;
        LSqrtArg := LSqrtArg + LA;
        // + SQR( skyVec[0] ) * SQR( heightCloud )
        LA := LSkyVec[0] * LSkyVec[0];
        LB := AHeightCloud * AHeightCloud;
        LA := LA * LB;
        LSqrtArg := LSqrtArg + LA;
        LA := LSkyVec[1] * LSkyVec[1];
        LA := 2 * LA;
        LA := LA * RadiusWorld;
        LA := LA * AHeightCloud;
        LSqrtArg := LSqrtArg + LA;
        LA := LSkyVec[1] * LSkyVec[1];
        LB := AHeightCloud * AHeightCloud;
        LA := LA * LB;
        LSqrtArg := LSqrtArg + LA;
        LA := LSkyVec[2] * LSkyVec[2];
        LA := 2 * LA;
        LA := LA * RadiusWorld;
        LA := LA * AHeightCloud;
        LSqrtArg := LSqrtArg + LA;
        LA := LSkyVec[2] * LSkyVec[2];
        LB := AHeightCloud * AHeightCloud;
        LA := LA * LB;
        LSqrtArg := LSqrtArg + LA;
        // ( -2 * skyVec[2] * radiusWorld + 2 * sqrt( ... ) ): the sum is a double
        LNegative := -2 * LSkyVec[2];
        LNegative := LNegative * RadiusWorld;
        LRoot := Sqrt(Double(LSqrtArg));
        LDoubleSum := LRoot;
        LDoubleSum := 2 * LDoubleSum;
        LDoubleSum := LNegative + LDoubleSum;
        LDoubleP := LInverse * LDoubleSum;
        LP := LDoubleP;
        FCloudTexP[LFace, LT, LS] := LP;
        // compute intersection point based on p
        LV := TQ3VectorMath.Scale(LSkyVec, LP);
        LTerm := LV[2] + RadiusWorld;
        LV[2] := LTerm;
        // compute vector from world origin to intersection point 'v'
        TQ3VectorMath.Normalize(LV);
        FCloudTexCoords[LFace, LT, LS, 0] := TQ3ClientMathSyscalls.Acos(LV[0]);
        FCloudTexCoords[LFace, LT, LS, 1] := TQ3ClientMathSyscalls.Acos(LV[1]);
      end;
end;

function TQ3SkyBox.StageIterator(var ATess: TQ3ShaderTess; const AViewOrigin: TQ3Vec3; AZFar: Single; AFastSky,
  AShowSky, AOuterBox: Boolean; AIdentityLight, ACloudHeight: Single; AStageCount: Integer; const ASink: IQ3GlSink;
  const ABind: TProc<Integer>; const AState: TProc<Cardinal>; const AGeneric: TProc): Boolean;
var
  LSides: TArray<TQ3SkySideDraw>;
  LSide, LStrip, LVertex: Integer;
begin
  Result := False;
  if AFastSky then
    Exit;
  // go through all the polygons and project them onto the sky box to see which blocks on each side need to be drawn
  ClipPolygons(ATess, AViewOrigin);
  // r_showsky will let all the sky blocks be drawn in front of everything
  if AShowSky then
    ASink.Call('glDepthRange', [TQ3GlArg.FromDouble(0), TQ3GlArg.FromDouble(0)])
  else
    ASink.Call('glDepthRange', [TQ3GlArg.FromDouble(1), TQ3GlArg.FromDouble(1)]);
  // draw the outer skybox
  if AOuterBox then
  begin
    ASink.Call('glColor3f', [TQ3GlArg.FromSingle(AIdentityLight), TQ3GlArg.FromSingle(AIdentityLight),
      TQ3GlArg.FromSingle(AIdentityLight)]);
    ASink.Call('glPushMatrix', []);
    AState(0);
    ASink.Call('glTranslatef', [TQ3GlArg.FromSingle(AViewOrigin[0]), TQ3GlArg.FromSingle(AViewOrigin[1]),
      TQ3GlArg.FromSingle(AViewOrigin[2])]);
    LSides := OuterBox(AZFar);
    for LSide := 0 to High(LSides) do
    begin
      ABind(LSides[LSide].ImageIndex);
      for LStrip := 0 to High(LSides[LSide].Strips) do
      begin
        ASink.Call('glBegin', [TQ3GlArg.FromEnum($0005)]);
        for LVertex := 0 to High(LSides[LSide].Strips[LStrip]) do
        begin
          ASink.Call('glTexCoord2fv', [TQ3GlArg.FromSingle(LSides[LSide].Strips[LStrip][LVertex].St[0]),
            TQ3GlArg.FromSingle(LSides[LSide].Strips[LStrip][LVertex].St[1])]);
          ASink.Call('glVertex3fv', [TQ3GlArg.FromSingle(LSides[LSide].Strips[LStrip][LVertex].Xyz[0]),
            TQ3GlArg.FromSingle(LSides[LSide].Strips[LStrip][LVertex].Xyz[1]),
            TQ3GlArg.FromSingle(LSides[LSide].Strips[LStrip][LVertex].Xyz[2])]);
        end;
        ASink.Call('glEnd', []);
      end;
    end;
    ASink.Call('glPopMatrix', []);
  end;
  // generate the vertexes for all the clouds, which will be drawn by the generic shader routine
  BuildCloudData(ATess, AStageCount, ACloudHeight, AZFar, AViewOrigin);
  AGeneric();
  // back to normal depth range
  ASink.Call('glDepthRange', [TQ3GlArg.FromDouble(0), TQ3GlArg.FromDouble(1)]);
  Result := True;
end;

class function TQ3SkyBox.DrawSun(var ATess: TQ3ShaderTess; const ASunDirection, AViewOrigin: TQ3Vec3; AZFar: Single;
  const AWorldModelMatrix: array of Single; ASkyRendered, ADrawSun: Boolean; const ASink: IQ3GlSink;
  const ABeginSurface, AEndSurface: TProc): Boolean;
var
  LMatrix: TBytes;
  LIndex: Integer;
begin
  Result := False;
  if (not ASkyRendered) or (not ADrawSun) then
    Exit;
  SetLength(LMatrix, Length(AWorldModelMatrix) * 4);
  for LIndex := 0 to High(AWorldModelMatrix) do
    PSingle(@LMatrix[LIndex * 4])^ := AWorldModelMatrix[LIndex];
  ASink.Call('glLoadMatrixf', [TQ3GlArg.FromBytes(LMatrix)]);
  ASink.Call('glTranslatef', [TQ3GlArg.FromSingle(AViewOrigin[0]), TQ3GlArg.FromSingle(AViewOrigin[1]),
    TQ3GlArg.FromSingle(AViewOrigin[2])]);
  // farthest depth range
  ASink.Call('glDepthRange', [TQ3GlArg.FromDouble(1), TQ3GlArg.FromDouble(1)]);
  ABeginSurface();
  SunQuad(ATess, ASunDirection, AZFar);
  AEndSurface();
  // back to normal depth range
  ASink.Call('glDepthRange', [TQ3GlArg.FromDouble(0), TQ3GlArg.FromDouble(1)]);
  Result := True;
end;

class procedure TQ3SkyBox.SunQuad(var ATess: TQ3ShaderTess; const ASunDirection: TQ3Vec3; AZFar: Single);
var
  LDistance, LSize: Single;
  LDouble: Double;
  LOrigin, LVec1, LVec2, LTemp: TQ3Vec3;
  LCorner, LAxis: Integer;
begin
  LDouble := AZFar / 1.75;
  LDistance := LDouble;
  LDouble := LDistance * 0.4;
  LSize := LDouble;
  LOrigin := TQ3VectorMath.Scale(ASunDirection, LDistance);
  LVec1 := TQ3VectorMath.PerpendicularVector(ASunDirection);
  LVec2 := TQ3VectorMath.Cross(ASunDirection, LVec1);
  LVec1 := TQ3VectorMath.Scale(LVec1, LSize);
  LVec2 := TQ3VectorMath.Scale(LVec2, LSize);
  for LCorner := 0 to 3 do
  begin
    LTemp := LOrigin;
    // origin - v1 - v2, origin + v1 - v2, origin + v1 + v2, origin - v1 + v2
    if LCorner in [1, 2] then
      LTemp := TQ3VectorMath.Add(LTemp, LVec1)
    else
      LTemp := TQ3VectorMath.Subtract(LTemp, LVec1);
    if LCorner in [2, 3] then
      LTemp := TQ3VectorMath.Add(LTemp, LVec2)
    else
      LTemp := TQ3VectorMath.Subtract(LTemp, LVec2);
    for LAxis := 0 to 2 do
      ATess.Xyz[(ATess.NumVertexes) * 4 + LAxis] := LTemp[LAxis];
    ATess.TexCoords[ATess.NumVertexes * 4] := LCorner div 2;
    // 0, 1, 1, 0
    if LCorner in [1, 2] then
      ATess.TexCoords[ATess.NumVertexes * 4 + 1] := 1
    else
      ATess.TexCoords[ATess.NumVertexes * 4 + 1] := 0;
    ATess.VertexColors[ATess.NumVertexes * 4] := 255;
    ATess.VertexColors[ATess.NumVertexes * 4 + 1] := 255;
    ATess.VertexColors[ATess.NumVertexes * 4 + 2] := 255;
    Inc(ATess.NumVertexes);
  end;
  ATess.Indexes[ATess.NumIndexes] := 0;
  ATess.Indexes[ATess.NumIndexes + 1] := 1;
  ATess.Indexes[ATess.NumIndexes + 2] := 2;
  ATess.Indexes[ATess.NumIndexes + 3] := 0;
  ATess.Indexes[ATess.NumIndexes + 4] := 2;
  ATess.Indexes[ATess.NumIndexes + 5] := 3;
  Inc(ATess.NumIndexes, 6);
end;

end.
