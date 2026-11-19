{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1b) - the surface     }
{  functions of the backend                                                    }
{                                                                              }
{  RB_SurfaceGrid (with LodErrorForVolume), RB_SurfacePolychain,               }
{  RB_SurfaceSprite, RB_SurfaceBeam, RB_SurfaceRailCore, RB_SurfaceRailRings,  }
{  RB_SurfaceLightningBolt and RB_SurfaceMesh (LerpMeshVertexes) of renderer\  }
{  tr_surface.c: they fill the buffers of TQ3ShaderTess. Based on the Quake    }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Backend.Surfaces;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Decl.Q3Shader.Calc.Types,
  DelphiDoom.MathCore.Patch.Intf, DelphiDoom.MathCore.Patch.Types, DelphiDoom.Models.Static.Md3.Types, DelphiDoom.Q3Render.Scene.Types;

type
  /// <summary>
  ///   The tessellation of the surfaces that are not part of the world lists: what the surface functions of the
  ///   original read from backEnd (the orientation of the entity, the viewer, the cvars) is held here. The buffers
  ///   are the tess of the backend, given to every call; a surface that does not fit flushes it (RB_CheckOverflow)
  ///   through the two procedures given to the constructor.
  /// </summary>
  TQ3SurfaceTessellator = class
  strict private
    FEndSurface: TProc;
    FBeginSurface: TProc;
    FSinTable: TArray<Single>;
    FOrientation: TQ3ViewOrientation;
    FViewOrientation: TQ3ViewOrientation;
    FIsMirror: Boolean;
    FLodCurveError: Single;
    FRailWidth: Integer;
    FRailCoreWidth: Integer;
    FRailSegmentLength: Single;
    function LodErrorForVolume(const ALocal: TQ3Vec3; ARadius: Single): Single;
    procedure DoRailCore(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity; const AStart, AEnd, AUp: TQ3Vec3;
      ALength, ASpanWidth: Single);
    procedure DoRailDiscs(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity; ANumSegs: Integer;
      const AStart, ADirection, ARight, AUp: TQ3Vec3);
    procedure LerpMeshVertexes(var ATess: TQ3ShaderTess; const ASurface: TMd3Surface; AFrame, AOldFrame: Integer;
      ABackLerp: Single);
    procedure RailVectors(const AEntity: TQ3RefEntity; const AStart, AEnd: TQ3Vec3; out ALength: Integer;
      out ADirection, ARight: TQ3Vec3);
  public
    /// <param name="AEndSurface">RB_EndSurface: draws what is in the buffers</param>
    /// <param name="ABeginSurface">RB_BeginSurface(tess.shader, tess.fogNum): starts again with the same shader</param>
    /// <param name="ASinTable">tr.sinTable (1024 floats)</param>
    constructor Create(const AEndSurface, ABeginSurface: TProc; const ASinTable: TArray<Single>);
    /// <summary>backEnd.or: where the entity is (the surfaces of an entity are in its own space)</summary>
    procedure SetEntityOrientation(const AOrientation: TQ3ViewOrientation);
    /// <summary>backEnd.viewParms.or and isMirror</summary>
    procedure SetView(const AOrientation: TQ3ViewOrientation; AIsMirror: Boolean);
    /// <summary>r_lodCurveError, r_railWidth, r_railCoreWidth and r_railSegmentLength</summary>
    procedure SetRailSettings(ARailWidth, ARailCoreWidth: Integer; ARailSegmentLength: Single);
    procedure SetLodCurveError(AValue: Single);
    /// <summary>RB_CheckOverflow</summary>
    procedure CheckOverflow(var ATess: TQ3ShaderTess; AVertexes, AIndexes: Integer);
    /// <summary>
    ///   RB_SurfaceGrid: the rows and columns of the LOD for the distance, in as many passes as the buffers need.
    ///   ADlightBits is tess.dlightBits (the dlight bits of the grid are ORed in)
    /// </summary>
    procedure Grid(var ATess: TQ3ShaderTess; var ADlightBits: Integer; ANeedsNormal: Boolean;
      const AGrid: IPatchGrid; AGridDlightBits: Integer);
    /// <summary>RB_SurfacePolychain: the fan of a polygon of the scene</summary>
    procedure Polychain(var ATess: TQ3ShaderTess; const APoly: TQ3ScenePoly);
    /// <summary>RB_SurfaceSprite</summary>
    procedure Sprite(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity);
    /// <summary>
    ///   RB_SurfaceBeam: the vertexes of the triangle strip that the original draws with glBegin (empty when the
    ///   beam has no length)
    /// </summary>
    function BeamStrip(const AEntity: TQ3RefEntity): TArray<TQ3Vec3>;
    /// <summary>RB_SurfaceRailRings</summary>
    procedure RailRings(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity);
    /// <summary>RB_SurfaceRailCore</summary>
    procedure RailCore(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity);
    /// <summary>RB_SurfaceLightningBolt</summary>
    procedure LightningBolt(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity);
    /// <summary>
    ///   RB_SurfaceMesh: a surface of an md3 for the frame (and the old frame, with the back lerp) of the entity.
    ///   A frame that the model does not have is an EQ3RenderException (the C reads past the surface)
    /// </summary>
    procedure Mesh(var ATess: TQ3ShaderTess; const ASurface: TMd3Surface; AFrame, AOldFrame: Integer;
      ABackLerp: Single);
  end;

implementation

uses
  DelphiDoom.Collision.Q3.VectorMath,
  DelphiDoom.Collision.Q3.Math, DelphiDoom.Decl.Q3Shader.Calc.QuadStamp, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Q3Render.Types;

const
  SHADER_MAX_VERTEXES = 1000;
  SHADER_MAX_INDEXES = 6 * SHADER_MAX_VERTEXES;
  MAX_GRID_SIZE = 65;
  NUM_BEAM_SEGS = 6;
  FUNCTABLE_SIZE = 1024;
  FUNCTABLE_MASK = FUNCTABLE_SIZE - 1;
  // M_PI as q_shared.h makes it: a float
  PiFloat: Single = 3.14159265358979323846;
  MD3_SCALE = 1.0 / 64;
  SMeshFrame = 'RB_SurfaceMesh: the frame %d is not in the surface (%d frames)';
  SOverflowVerts = 'RB_CheckOverflow: verts > MAX (%d > %d)';
  SOverflowIndexes = 'RB_CheckOverflow: indices > MAX (%d > %d)';

function ColorOf(const AEntity: TQ3RefEntity): Cardinal;
begin
  Result := Cardinal(AEntity.ShaderRGBA[0]) or (Cardinal(AEntity.ShaderRGBA[1]) shl 8) or
    (Cardinal(AEntity.ShaderRGBA[2]) shl 16) or (Cardinal(AEntity.ShaderRGBA[3]) shl 24);
end;

{ TQ3SurfaceTessellator }

constructor TQ3SurfaceTessellator.Create(const AEndSurface, ABeginSurface: TProc; const ASinTable: TArray<Single>);
begin
  inherited Create;
  FEndSurface := AEndSurface;
  FBeginSurface := ABeginSurface;
  FSinTable := ASinTable;
  FLodCurveError := 250;
  FRailWidth := 16;
  FRailCoreWidth := 6;
  FRailSegmentLength := 32;
end;

procedure TQ3SurfaceTessellator.SetEntityOrientation(const AOrientation: TQ3ViewOrientation);
begin
  FOrientation := AOrientation;
end;

procedure TQ3SurfaceTessellator.SetView(const AOrientation: TQ3ViewOrientation; AIsMirror: Boolean);
begin
  FViewOrientation := AOrientation;
  FIsMirror := AIsMirror;
end;

procedure TQ3SurfaceTessellator.SetRailSettings(ARailWidth, ARailCoreWidth: Integer; ARailSegmentLength: Single);
begin
  FRailWidth := ARailWidth;
  FRailCoreWidth := ARailCoreWidth;
  FRailSegmentLength := ARailSegmentLength;
end;

procedure TQ3SurfaceTessellator.SetLodCurveError(AValue: Single);
begin
  FLodCurveError := AValue;
end;

procedure TQ3SurfaceTessellator.CheckOverflow(var ATess: TQ3ShaderTess; AVertexes, AIndexes: Integer);
begin
  if (ATess.NumVertexes + AVertexes < SHADER_MAX_VERTEXES) and (ATess.NumIndexes + AIndexes < SHADER_MAX_INDEXES) then
    Exit;
  FEndSurface();
  if AVertexes >= SHADER_MAX_VERTEXES then
    raise EQ3RenderException.CreateFmt(SOverflowVerts, [AVertexes, SHADER_MAX_VERTEXES]);
  if AIndexes >= SHADER_MAX_INDEXES then
    raise EQ3RenderException.CreateFmt(SOverflowIndexes, [AIndexes, SHADER_MAX_INDEXES]);
  FBeginSurface();
end;

function TQ3SurfaceTessellator.LodErrorForVolume(const ALocal: TQ3Vec3; ARadius: Single): Single;
var
  LWorld: TQ3Vec3;
  LAxis: Integer;
  LProduct, LSum, LDistance: Single;
begin
  // never let it go negative
  if FLodCurveError < 0 then
    Exit(0);
  for LAxis := 0 to 2 do
  begin
    LSum := ALocal[0] * FOrientation.Axis[0][LAxis];
    LProduct := ALocal[1] * FOrientation.Axis[1][LAxis];
    LSum := LSum + LProduct;
    LProduct := ALocal[2] * FOrientation.Axis[2][LAxis];
    LSum := LSum + LProduct;
    LWorld[LAxis] := LSum + FOrientation.Origin[LAxis];
  end;
  LWorld := TQ3VectorMath.Subtract(LWorld, FViewOrientation.Origin);
  LDistance := TQ3Math.Dot(LWorld, FViewOrientation.Axis[0]);
  if LDistance < 0 then
    LDistance := -LDistance;
  LDistance := LDistance - ARadius;
  if LDistance < 1 then
    LDistance := 1;
  Result := FLodCurveError / LDistance;
end;

procedure TQ3SurfaceTessellator.Grid(var ATess: TQ3ShaderTess; var ADlightBits: Integer; ANeedsNormal: Boolean;
  const AGrid: IPatchGrid; AGridDlightBits: Integer);
var
  LWidthTable, LHeightTable: array[0..MAX_GRID_SIZE - 1] of Integer;
  LLodWidth, LLodHeight, LIndex, LRow, LColumn, LUsed, LRows, LVRows, LIRows, LNumVertexes, LNumIndexes: Integer;
  LLodError: Single;
  LOrigin: TQ3Vec3;
  LVertex: TPatchVertex;
  LBase, LWidth, LHeight, LV1, LV2, LV3, LV4: Integer;
begin
  ADlightBits := ADlightBits or AGridDlightBits;
  // determine the allowable discrepance
  LOrigin[0] := AGrid.LodOrigin.X;
  LOrigin[1] := AGrid.LodOrigin.Y;
  LOrigin[2] := AGrid.LodOrigin.Z;
  LLodError := LodErrorForVolume(LOrigin, AGrid.LodRadius);
  LWidth := AGrid.Width;
  LHeight := AGrid.Height;
  // determine which rows and columns of the subdivision we are actually going to use
  LWidthTable[0] := 0;
  LLodWidth := 1;
  for LIndex := 1 to LWidth - 2 do
    if AGrid.WidthLodError[LIndex] <= LLodError then
    begin
      LWidthTable[LLodWidth] := LIndex;
      Inc(LLodWidth);
    end;
  LWidthTable[LLodWidth] := LWidth - 1;
  Inc(LLodWidth);
  LHeightTable[0] := 0;
  LLodHeight := 1;
  for LIndex := 1 to LHeight - 2 do
    if AGrid.HeightLodError[LIndex] <= LLodError then
    begin
      LHeightTable[LLodHeight] := LIndex;
      Inc(LLodHeight);
    end;
  LHeightTable[LLodHeight] := LHeight - 1;
  Inc(LLodHeight);
  // very large grids may have more points or indexes than can be fit in the tess structure: several passes
  LUsed := 0;
  while LUsed < LLodHeight - 1 do
  begin
    // see how many rows of both verts and indexes we can add without overflowing
    repeat
      LVRows := (SHADER_MAX_VERTEXES - ATess.NumVertexes) div LLodWidth;
      LIRows := (SHADER_MAX_INDEXES - ATess.NumIndexes) div (LLodWidth * 6);
      // if we don't have enough space for at least one strip, flush the buffer
      if (LVRows < 2) or (LIRows < 1) then
      begin
        FEndSurface();
        FBeginSurface();
      end
      else
        Break;
    until False;
    LRows := LIRows;
    if LVRows < LIRows + 1 then
      LRows := LVRows - 1;
    if LUsed + LRows > LLodHeight then
      LRows := LLodHeight - LUsed;
    LNumVertexes := ATess.NumVertexes;
    for LRow := 0 to LRows - 1 do
      for LColumn := 0 to LLodWidth - 1 do
      begin
        LVertex := AGrid.Vertices[LHeightTable[LUsed + LRow] * LWidth + LWidthTable[LColumn]];
        LBase := (LNumVertexes + LRow * LLodWidth + LColumn) * 4;
        ATess.Xyz[LBase] := LVertex.Position.X;
        ATess.Xyz[LBase + 1] := LVertex.Position.Y;
        ATess.Xyz[LBase + 2] := LVertex.Position.Z;
        ATess.TexCoords[LBase] := LVertex.TexCoord.X;
        ATess.TexCoords[LBase + 1] := LVertex.TexCoord.Y;
        ATess.TexCoords[LBase + 2] := LVertex.Lightmap.X;
        ATess.TexCoords[LBase + 3] := LVertex.Lightmap.Y;
        if ANeedsNormal then
        begin
          ATess.Normal[LBase] := LVertex.Normal.X;
          ATess.Normal[LBase + 1] := LVertex.Normal.Y;
          ATess.Normal[LBase + 2] := LVertex.Normal.Z;
        end;
        ATess.VertexColors[LBase] := LVertex.Color[0];
        ATess.VertexColors[LBase + 1] := LVertex.Color[1];
        ATess.VertexColors[LBase + 2] := LVertex.Color[2];
        ATess.VertexColors[LBase + 3] := LVertex.Color[3];
      end;
    // add the indexes, in the order that is recognized as tristrips
    LNumIndexes := ATess.NumIndexes;
    for LRow := 0 to LRows - 2 do
      for LColumn := 0 to LLodWidth - 2 do
      begin
        LV1 := LNumVertexes + LRow * LLodWidth + LColumn + 1;
        LV2 := LV1 - 1;
        LV3 := LV2 + LLodWidth;
        LV4 := LV3 + 1;
        ATess.Indexes[LNumIndexes] := LV2;
        ATess.Indexes[LNumIndexes + 1] := LV3;
        ATess.Indexes[LNumIndexes + 2] := LV1;
        ATess.Indexes[LNumIndexes + 3] := LV1;
        ATess.Indexes[LNumIndexes + 4] := LV3;
        ATess.Indexes[LNumIndexes + 5] := LV4;
        Inc(LNumIndexes, 6);
      end;
    ATess.NumIndexes := LNumIndexes;
    Inc(ATess.NumVertexes, LRows * LLodWidth);
    Inc(LUsed, LRows - 1);
  end;
end;

procedure TQ3SurfaceTessellator.Polychain(var ATess: TQ3ShaderTess; const APoly: TQ3ScenePoly);
var
  LIndex, LNumVerts, LNumber, LBase: Integer;
begin
  LNumVerts := Length(APoly.Verts);
  CheckOverflow(ATess, LNumVerts, 3 * (LNumVerts - 2));
  // fan triangles into the tess array
  LNumber := ATess.NumVertexes;
  for LIndex := 0 to LNumVerts - 1 do
  begin
    LBase := (LNumber + LIndex) * 4;
    ATess.Xyz[LBase] := APoly.Verts[LIndex].Xyz[0];
    ATess.Xyz[LBase + 1] := APoly.Verts[LIndex].Xyz[1];
    ATess.Xyz[LBase + 2] := APoly.Verts[LIndex].Xyz[2];
    ATess.TexCoords[LBase] := APoly.Verts[LIndex].St[0];
    ATess.TexCoords[LBase + 1] := APoly.Verts[LIndex].St[1];
    ATess.VertexColors[LBase] := APoly.Verts[LIndex].Modulate[0];
    ATess.VertexColors[LBase + 1] := APoly.Verts[LIndex].Modulate[1];
    ATess.VertexColors[LBase + 2] := APoly.Verts[LIndex].Modulate[2];
    ATess.VertexColors[LBase + 3] := APoly.Verts[LIndex].Modulate[3];
  end;
  // generate fan indexes into the tess array
  for LIndex := 0 to LNumVerts - 3 do
  begin
    ATess.Indexes[ATess.NumIndexes] := LNumber;
    ATess.Indexes[ATess.NumIndexes + 1] := LNumber + LIndex + 1;
    ATess.Indexes[ATess.NumIndexes + 2] := LNumber + LIndex + 2;
    Inc(ATess.NumIndexes, 3);
  end;
  ATess.NumVertexes := LNumber + LNumVerts;
end;

procedure TQ3SurfaceTessellator.Sprite(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity);
var
  LLeft, LUp, LZero: TQ3Vec3;
  LAxis: Integer;
  LAngle, LSin, LCos, LScale, LTerm: Single;
  LDouble: Double;
begin
  // calculate the xyz locations for the four corners
  if AEntity.Rotation = 0 then
  begin
    LLeft := TQ3VectorMath.Scale(FViewOrientation.Axis[1], AEntity.Radius);
    LUp := TQ3VectorMath.Scale(FViewOrientation.Axis[2], AEntity.Radius);
  end
  else
  begin
    LAngle := PiFloat * AEntity.Rotation;
    LAngle := LAngle / 180;
    LDouble := Sin(Double(LAngle));
    LSin := LDouble;
    LDouble := Cos(Double(LAngle));
    LCos := LDouble;
    LScale := LCos * AEntity.Radius;
    LLeft := TQ3VectorMath.Scale(FViewOrientation.Axis[1], LScale);
    LTerm := -LSin;
    LScale := LTerm * AEntity.Radius;
    LLeft := TQ3VectorMath.MultiplyAdd(LLeft, LScale, FViewOrientation.Axis[2]);
    LScale := LCos * AEntity.Radius;
    LUp := TQ3VectorMath.Scale(FViewOrientation.Axis[2], LScale);
    LScale := LSin * AEntity.Radius;
    LUp := TQ3VectorMath.MultiplyAdd(LUp, LScale, FViewOrientation.Axis[1]);
  end;
  if FIsMirror then
  begin
    FillChar(LZero, SizeOf(LZero), 0);
    LLeft := TQ3VectorMath.Subtract(LZero, LLeft);
  end;
  CheckOverflow(ATess, 4, 6);
  for LAxis := 0 to 2 do
  begin
    ATess.View.Axis[0][LAxis] := FViewOrientation.Axis[0][LAxis];
    ATess.View.Axis[1][LAxis] := FViewOrientation.Axis[1][LAxis];
    ATess.View.Axis[2][LAxis] := FViewOrientation.Axis[2][LAxis];
    ATess.View.Origin[LAxis] := FViewOrientation.Origin[LAxis];
  end;
  TQ3QuadStamp.Add(ATess, AEntity.Origin, LLeft, LUp, ColorOf(AEntity));
end;

function TQ3SurfaceTessellator.BeamStrip(const AEntity: TQ3RefEntity): TArray<TQ3Vec3>;
var
  LDirection, LNormalized, LPerp: TQ3Vec3;
  LStart, LEnd: array[0..NUM_BEAM_SEGS - 1] of TQ3Vec3;
  LIndex: Integer;
  LDegrees: Single;
begin
  SetLength(Result, 0);
  LDirection := TQ3VectorMath.Subtract(AEntity.OldOrigin, AEntity.Origin);
  LNormalized := LDirection;
  if TQ3VectorMath.Normalize(LNormalized) = 0 then
    Exit;
  LPerp := TQ3VectorMath.PerpendicularVector(LNormalized);
  LPerp := TQ3VectorMath.Scale(LPerp, 4);
  for LIndex := 0 to NUM_BEAM_SEGS - 1 do
  begin
    LDegrees := (360.0 / NUM_BEAM_SEGS) * LIndex;
    LStart[LIndex] := TQ3VectorMath.RotatePointAroundVector(LNormalized, LPerp, LDegrees);
    LEnd[LIndex] := TQ3VectorMath.Add(LStart[LIndex], LDirection);
  end;
  SetLength(Result, (NUM_BEAM_SEGS + 1) * 2);
  for LIndex := 0 to NUM_BEAM_SEGS do
  begin
    Result[LIndex * 2] := LStart[LIndex mod NUM_BEAM_SEGS];
    Result[LIndex * 2 + 1] := LEnd[LIndex mod NUM_BEAM_SEGS];
  end;
end;

procedure TQ3SurfaceTessellator.DoRailCore(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity; const AStart, AEnd,
  AUp: TQ3Vec3; ALength, ASpanWidth: Single);
var
  LSpanWidth2, LTexCoord: Single;
  LBase, LNumber, LAxis: Integer;
  LPoint: TQ3Vec3;
begin
  LTexCoord := ALength / 256.0;
  LBase := ATess.NumVertexes;
  LSpanWidth2 := -ASpanWidth;
  // FIXME of the original: use quad stamp?
  for LNumber := 0 to 3 do
  begin
    case LNumber of
      0: LPoint := TQ3VectorMath.MultiplyAdd(AStart, ASpanWidth, AUp);
      1: LPoint := TQ3VectorMath.MultiplyAdd(AStart, LSpanWidth2, AUp);
      2: LPoint := TQ3VectorMath.MultiplyAdd(AEnd, ASpanWidth, AUp);
    else
      LPoint := TQ3VectorMath.MultiplyAdd(AEnd, LSpanWidth2, AUp);
    end;
    for LAxis := 0 to 2 do
      ATess.Xyz[(LBase + LNumber) * 4 + LAxis] := LPoint[LAxis];
    if LNumber < 2 then
      ATess.TexCoords[(LBase + LNumber) * 4] := 0
    else
      ATess.TexCoords[(LBase + LNumber) * 4] := LTexCoord;
    ATess.TexCoords[(LBase + LNumber) * 4 + 1] := LNumber and 1;
    for LAxis := 0 to 2 do
      if LNumber = 0 then
        ATess.VertexColors[(LBase + LNumber) * 4 + LAxis] := Byte(Trunc(AEntity.ShaderRGBA[LAxis] * 0.25))
      else
        ATess.VertexColors[(LBase + LNumber) * 4 + LAxis] := AEntity.ShaderRGBA[LAxis];
  end;
  Inc(ATess.NumVertexes, 4);
  ATess.Indexes[ATess.NumIndexes] := LBase;
  ATess.Indexes[ATess.NumIndexes + 1] := LBase + 1;
  ATess.Indexes[ATess.NumIndexes + 2] := LBase + 2;
  ATess.Indexes[ATess.NumIndexes + 3] := LBase + 2;
  ATess.Indexes[ATess.NumIndexes + 4] := LBase + 1;
  ATess.Indexes[ATess.NumIndexes + 5] := LBase + 3;
  Inc(ATess.NumIndexes, 6);
end;

procedure TQ3SurfaceTessellator.DoRailDiscs(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity; ANumSegs: Integer;
  const AStart, ADirection, ARight, AUp: TQ3Vec3);
const
  Scale: Single = 0.25;
var
  LIndex, LSegment, LCorner, LAxis, LSpanWidth, LBase: Integer;
  LPos: array[0..3] of TQ3Vec3;
  LV: TQ3Vec3;
  LCos, LSin, LAngle, LTerm, LSecond: Single;
  LDouble: Double;
begin
  LSpanWidth := FRailWidth;
  if ANumSegs > 1 then
    Dec(ANumSegs);
  if ANumSegs = 0 then
    Exit;
  for LIndex := 0 to 3 do
  begin
    // DEG2RAD(a) is ((a) * M_PI) / 180.0f, in floats
    LAngle := (45 + LIndex * 90) * PiFloat;
    LAngle := LAngle / 180.0;
    LDouble := Cos(Double(LAngle));
    LCos := LDouble;
    LDouble := Sin(Double(LAngle));
    LSin := LDouble;
    for LAxis := 0 to 2 do
    begin
      LTerm := ARight[LAxis] * LCos;
      LSecond := AUp[LAxis] * LSin;
      LTerm := LTerm + LSecond;
      LTerm := LTerm * Scale;
      LV[LAxis] := LTerm * LSpanWidth;
    end;
    LPos[LIndex] := TQ3VectorMath.Add(AStart, LV);
    if ANumSegs > 1 then
      // offset by 1 segment if we're doing a long distance shot
      LPos[LIndex] := TQ3VectorMath.Add(LPos[LIndex], ADirection);
  end;
  for LSegment := 0 to ANumSegs - 1 do
  begin
    CheckOverflow(ATess, 4, 6);
    for LCorner := 0 to 3 do
    begin
      LBase := ATess.NumVertexes * 4;
      for LAxis := 0 to 2 do
        ATess.Xyz[LBase + LAxis] := LPos[LCorner][LAxis];
      if LCorner < 2 then
        ATess.TexCoords[LBase] := 1
      else
        ATess.TexCoords[LBase] := 0;
      if (LCorner <> 0) and (LCorner <> 3) then
        ATess.TexCoords[LBase + 1] := 1
      else
        ATess.TexCoords[LBase + 1] := 0;
      for LAxis := 0 to 2 do
        ATess.VertexColors[LBase + LAxis] := AEntity.ShaderRGBA[LAxis];
      Inc(ATess.NumVertexes);
      LPos[LCorner] := TQ3VectorMath.Add(LPos[LCorner], ADirection);
    end;
    LBase := ATess.NumVertexes - 4;
    ATess.Indexes[ATess.NumIndexes] := LBase;
    ATess.Indexes[ATess.NumIndexes + 1] := LBase + 1;
    ATess.Indexes[ATess.NumIndexes + 2] := LBase + 3;
    ATess.Indexes[ATess.NumIndexes + 3] := LBase + 3;
    ATess.Indexes[ATess.NumIndexes + 4] := LBase + 1;
    ATess.Indexes[ATess.NumIndexes + 5] := LBase + 2;
    Inc(ATess.NumIndexes, 6);
  end;
end;

procedure TQ3SurfaceTessellator.RailRings(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity);
var
  LVector, LRight, LUp: TQ3Vec3;
  LLength, LNumSegs: Integer;
  LFloatLength: Single;
begin
  // start is the old origin, end the origin
  LVector := TQ3VectorMath.Subtract(AEntity.Origin, AEntity.OldOrigin);
  LFloatLength := TQ3VectorMath.Normalize(LVector);
  LLength := TQ3CMath.FloatToInt(LFloatLength);
  TQ3VectorMath.MakeNormalVectors(LVector, LRight, LUp);
  LFloatLength := LLength / FRailSegmentLength;
  LNumSegs := TQ3CMath.FloatToInt(LFloatLength);
  if LNumSegs <= 0 then
    LNumSegs := 1;
  LVector := TQ3VectorMath.Scale(LVector, FRailSegmentLength);
  DoRailDiscs(ATess, AEntity, LNumSegs, AEntity.OldOrigin, LVector, LRight, LUp);
end;

procedure TQ3SurfaceTessellator.RailVectors(const AEntity: TQ3RefEntity; const AStart, AEnd: TQ3Vec3;
  out ALength: Integer; out ADirection, ARight: TQ3Vec3);
var
  LV1, LV2: TQ3Vec3;
begin
  ADirection := TQ3VectorMath.Subtract(AEnd, AStart);
  ALength := TQ3CMath.FloatToInt(TQ3VectorMath.Normalize(ADirection));
  // compute side vector
  LV1 := TQ3VectorMath.Subtract(AStart, FViewOrientation.Origin);
  TQ3VectorMath.Normalize(LV1);
  LV2 := TQ3VectorMath.Subtract(AEnd, FViewOrientation.Origin);
  TQ3VectorMath.Normalize(LV2);
  ARight := TQ3VectorMath.Cross(LV1, LV2);
  TQ3VectorMath.Normalize(ARight);
end;

procedure TQ3SurfaceTessellator.RailCore(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity);
var
  LLength: Integer;
  LDirection, LRight: TQ3Vec3;
begin
  RailVectors(AEntity, AEntity.OldOrigin, AEntity.Origin, LLength, LDirection, LRight);
  DoRailCore(ATess, AEntity, AEntity.OldOrigin, AEntity.Origin, LRight, LLength, FRailCoreWidth);
end;

procedure TQ3SurfaceTessellator.LightningBolt(var ATess: TQ3ShaderTess; const AEntity: TQ3RefEntity);
var
  LLength, LIndex: Integer;
  LDirection, LRight: TQ3Vec3;
begin
  RailVectors(AEntity, AEntity.Origin, AEntity.OldOrigin, LLength, LDirection, LRight);
  for LIndex := 0 to 3 do
  begin
    DoRailCore(ATess, AEntity, AEntity.Origin, AEntity.OldOrigin, LRight, LLength, 8);
    LRight := TQ3VectorMath.RotatePointAroundVector(LDirection, LRight, 45);
  end;
end;

procedure TQ3SurfaceTessellator.LerpMeshVertexes(var ATess: TQ3ShaderTess; const ASurface: TMd3Surface; AFrame,
  AOldFrame: Integer; ABackLerp: Single);
var
  LNumVerts, LVertex, LBase, LNew, LOld, LLat, LLng, LAxis: Integer;
  LNewXyzScale, LOldXyzScale, LNewNormalScale, LOldNormalScale, LFirst, LSecond: Single;
  LNewNormal, LOldNormal: TQ3Vec3;

  procedure Decode(ASource: SmallInt; var ANormal: TQ3Vec3);
  var
    LProduct: Single;
  begin
    LLat := (Integer(ASource) shr 8) and $FF;
    LLng := Integer(ASource) and $FF;
    LLat := LLat * (FUNCTABLE_SIZE div 256);
    LLng := LLng * (FUNCTABLE_SIZE div 256);
    // decode X as cos( lat ) * sin( long ), Y as sin( lat ) * sin( long ), Z as cos( long )
    LProduct := FSinTable[(LLat + (FUNCTABLE_SIZE div 4)) and FUNCTABLE_MASK] * FSinTable[LLng];
    ANormal[0] := LProduct;
    LProduct := FSinTable[LLat] * FSinTable[LLng];
    ANormal[1] := LProduct;
    ANormal[2] := FSinTable[(LLng + (FUNCTABLE_SIZE div 4)) and FUNCTABLE_MASK];
  end;

begin
  LNumVerts := ASurface.NumVerts;
  LNew := AFrame * LNumVerts * 4;
  LNewXyzScale := MD3_SCALE * (1.0 - ABackLerp);
  LNewNormalScale := 1.0 - ABackLerp;
  if ABackLerp = 0 then
  begin
    // just copy the vertexes
    for LVertex := 0 to LNumVerts - 1 do
    begin
      LBase := (ATess.NumVertexes + LVertex) * 4;
      for LAxis := 0 to 2 do
        ATess.Xyz[LBase + LAxis] := ASurface.XyzNormals[LNew + LVertex * 4 + LAxis] * LNewXyzScale;
      Decode(ASurface.XyzNormals[LNew + LVertex * 4 + 3], LNewNormal);
      for LAxis := 0 to 2 do
        ATess.Normal[LBase + LAxis] := LNewNormal[LAxis];
    end;
  end
  else
  begin
    // interpolate and copy the vertex and normal
    LOld := AOldFrame * LNumVerts * 4;
    LOldXyzScale := MD3_SCALE * ABackLerp;
    LOldNormalScale := ABackLerp;
    for LVertex := 0 to LNumVerts - 1 do
    begin
      LBase := (ATess.NumVertexes + LVertex) * 4;
      for LAxis := 0 to 2 do
      begin
        LFirst := ASurface.XyzNormals[LOld + LVertex * 4 + LAxis] * LOldXyzScale;
        LSecond := ASurface.XyzNormals[LNew + LVertex * 4 + LAxis] * LNewXyzScale;
        ATess.Xyz[LBase + LAxis] := LFirst + LSecond;
      end;
      Decode(ASurface.XyzNormals[LNew + LVertex * 4 + 3], LNewNormal);
      Decode(ASurface.XyzNormals[LOld + LVertex * 4 + 3], LOldNormal);
      for LAxis := 0 to 2 do
      begin
        LFirst := LOldNormal[LAxis] * LOldNormalScale;
        LSecond := LNewNormal[LAxis] * LNewNormalScale;
        ATess.Normal[LBase + LAxis] := LFirst + LSecond;
      end;
    end;
    // VectorArrayNormalize: VectorNormalizeFast of every normal
    for LVertex := 0 to LNumVerts - 1 do
      TQ3CMath.NormalizeFast(ATess.Normal, (ATess.NumVertexes + LVertex) * 4);
  end;
end;

procedure TQ3SurfaceTessellator.Mesh(var ATess: TQ3ShaderTess; const ASurface: TMd3Surface; AFrame, AOldFrame: Integer;
  ABackLerp: Single);
var
  LBackLerp: Single;
  LIndexes, LIndex, LDoug, LBob: Integer;
begin
  if AOldFrame = AFrame then
    LBackLerp := 0
  else
    LBackLerp := ABackLerp;
  if (AFrame < 0) or (AFrame >= ASurface.NumFrames) then
    raise EQ3RenderException.CreateFmt(SMeshFrame, [AFrame, ASurface.NumFrames]);
  if (LBackLerp <> 0) and ((AOldFrame < 0) or (AOldFrame >= ASurface.NumFrames)) then
    raise EQ3RenderException.CreateFmt(SMeshFrame, [AOldFrame, ASurface.NumFrames]);
  CheckOverflow(ATess, ASurface.NumVerts, Length(ASurface.Triangles));
  LerpMeshVertexes(ATess, ASurface, AFrame, AOldFrame, LBackLerp);
  LIndexes := Length(ASurface.Triangles);
  LBob := ATess.NumIndexes;
  LDoug := ATess.NumVertexes;
  for LIndex := 0 to LIndexes - 1 do
    ATess.Indexes[LBob + LIndex] := LDoug + ASurface.Triangles[LIndex];
  Inc(ATess.NumIndexes, LIndexes);
  for LIndex := 0 to ASurface.NumVerts - 1 do
  begin
    ATess.TexCoords[(LDoug + LIndex) * 4] := ASurface.St[LIndex].X;
    ATess.TexCoords[(LDoug + LIndex) * 4 + 1] := ASurface.St[LIndex].Y;
  end;
  Inc(ATess.NumVertexes, ASurface.NumVerts);
end;

end.
