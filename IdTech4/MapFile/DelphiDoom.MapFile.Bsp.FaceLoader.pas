{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: planar faces     }
{                                                                              }
{  Port of ParseFace (tr_bsp.c). Based on the Quake III Arena GPL Source Code  }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is       }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.FaceLoader;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.RenderTypes,
  DelphiDoom.MapFile.Bsp.Types;

type
  /// <summary>
  ///   ParseFace. The plane is the one of the third lightmap vector, and its distance is the
  ///   dot product of the first point with it done in single precision step by step, as the
  ///   C code does with floats (each product and each sum is rounded to a Single). What the
  ///   shader system decides (r_singleShader, the shader being defective) is left to the
  ///   renderer: the loader says only that the default shader is needed because of
  ///   MAX_FACE_POINTS. A face without vertices has a plane distance of the dot product with
  ///   a zero point (the memory of the original is zeroed).
  /// </summary>
  TBspFaceLoader = class(TInterfacedObject, IBspFaceLoader)
  strict private
    FColorShift: Integer;
    FLog: IIdLibLog;
  public
    /// <param name="AColorShift">r_mapOverBrightBits - overbrightBits (see TBspColorShift)</param>
    /// <param name="ALog">gets the MAX_FACE_POINTS warning; may be nil</param>
    constructor Create(const AColorShift: Integer; const ALog: IIdLibLog = nil);
    function Parse(const ASurface: TBspSurface; const AVerts: TArray<TBspDrawVert>;
      const AIndexes: TArray<Integer>; const AShaderCount: Integer): TBspFaceSurface;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.ColorShift, DelphiDoom.MapFile.Bsp.SurfaceGuard;

const
  /// <summary>MAX_FACE_POINTS of tr_local.h</summary>
  MAX_FACE_POINTS = 64;
  PLANE_X = 0;
  PLANE_Y = 1;
  PLANE_Z = 2;
  PLANE_NON_AXIAL = 3;

resourcestring
  SFaceTooManyPoints = 'WARNING: MAX_FACE_POINTS exceeded: %d'#10;
  SFaceVerts = 'vertexes';
  SFaceIndexes = 'indexes';

{ TBspFaceLoader }

constructor TBspFaceLoader.Create(const AColorShift: Integer; const ALog: IIdLibLog);
begin
  inherited Create;
  FColorShift := AColorShift;
  FLog := ALog;
end;

function TBspFaceLoader.Parse(const ASurface: TBspSurface; const AVerts: TArray<TBspDrawVert>;
  const AIndexes: TArray<Integer>; const AShaderCount: Integer): TBspFaceSurface;
var
  LNumPoints, LIndex, LAxis: Integer;
  LColor, LShifted: TBspColor;
  LX, LY, LZ, LSum: Single;
begin
  Result.UsesDefaultShader := False;
  TBspSurfaceGuard.CheckShaderNum(ASurface.ShaderNum, AShaderCount);
  // get fog volume
  Result.FogIndex := ASurface.FogNum + 1;
  Result.ShaderNum := ASurface.ShaderNum;

  LNumPoints := ASurface.NumVerts;
  if LNumPoints > MAX_FACE_POINTS then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format(SFaceTooManyPoints, [LNumPoints]));
    LNumPoints := MAX_FACE_POINTS;
    Result.UsesDefaultShader := True;
  end;
  if LNumPoints < 0 then
    LNumPoints := 0;
  TBspSurfaceGuard.CheckRange(SFaceVerts, ASurface.FirstVert, LNumPoints, Length(AVerts));
  TBspSurfaceGuard.CheckRange(SFaceIndexes, ASurface.FirstIndex, ASurface.NumIndexes, Length(AIndexes));

  SetLength(Result.Points, LNumPoints);
  for LIndex := 0 to LNumPoints - 1 do
  begin
    with AVerts[ASurface.FirstVert + LIndex] do
    begin
      for LAxis := 0 to 2 do
        Result.Points[LIndex].Xyz[LAxis] := Xyz[LAxis];
      for LAxis := 0 to 1 do
      begin
        Result.Points[LIndex].St[LAxis] := St[LAxis];
        Result.Points[LIndex].Lightmap[LAxis] := Lightmap[LAxis];
      end;
      for LAxis := 0 to 3 do
        LColor[LAxis] := Color[LAxis];
    end;
    TBspColorShift.Apply(FColorShift, LColor, LShifted);
    Result.Points[LIndex].Color := LShifted;
  end;

  SetLength(Result.Indexes, ASurface.NumIndexes);
  for LIndex := 0 to ASurface.NumIndexes - 1 do
    Result.Indexes[LIndex] := AIndexes[ASurface.FirstIndex + LIndex];

  // take the plane information from the lightmap vector
  for LAxis := 0 to 2 do
    Result.PlaneNormal[LAxis] := ASurface.LightmapVecs[2, LAxis];
  if LNumPoints > 0 then
  begin
    LX := Result.Points[0].Xyz[0] * Result.PlaneNormal[0];
    LY := Result.Points[0].Xyz[1] * Result.PlaneNormal[1];
    LZ := Result.Points[0].Xyz[2] * Result.PlaneNormal[2];
  end
  else
  begin
    LX := 0 * Result.PlaneNormal[0];
    LY := 0 * Result.PlaneNormal[1];
    LZ := 0 * Result.PlaneNormal[2];
  end;
  // DotProduct: (x * x + y * y) + z * z, a float operation at a time
  LSum := LX + LY;
  Result.PlaneDist := LSum + LZ;

  // SetPlaneSignbits
  Result.PlaneSignBits := 0;
  for LAxis := 0 to 2 do
    if Result.PlaneNormal[LAxis] < 0 then
      Result.PlaneSignBits := Result.PlaneSignBits or (1 shl LAxis);
  // PlaneTypeForNormal
  if Result.PlaneNormal[0] = 1.0 then
    Result.PlaneType := PLANE_X
  else if Result.PlaneNormal[1] = 1.0 then
    Result.PlaneType := PLANE_Y
  else if Result.PlaneNormal[2] = 1.0 then
    Result.PlaneType := PLANE_Z
  else
    Result.PlaneType := PLANE_NON_AXIAL;
end;

end.
