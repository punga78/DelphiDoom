{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - normals, tangents and planes of surfaces    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\tr_trisurf.cpp  }
{  (R_DeriveFacePlanes, R_DeriveTangents, R_DeriveTangentsWithoutNormals,      }
{  R_DeriveUnsmoothedTangents) and idlib\math\Simd_Generic.cpp (DeriveTriPlanes,}
{  DeriveTangents, DeriveUnsmoothedTangents, NormalizeTangents). Copyright (C) }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3, with the additional terms of the Doom 3  }
{  Source Code License (see README.md of Libs\IdLib); the repository as a      }
{  whole is GPL v2 or later.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.TangentDeriver;

interface

uses
  DelphiDoom.Geometry.Plane,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Deform.Types;

type
  /// <summary>
  ///   Derives the face planes, the vertex normals and the two tangents of a surface with the
  ///   generic processor of the engine (no SIMD): the vertexes are the array given, changed in
  ///   place. It has no state.
  /// </summary>
  TStaticTangentDeriver = class
  public
    /// <summary>R_DeriveFacePlanes: one plane for every triangle, through the first vertex</summary>
    class function DeriveFacePlanes(const AVerts: TArray<TStaticDrawVert>;
      const AIndexes: TArray<Integer>): TArray<TGeoPlane>; static;
    /// <summary>
    ///   R_DeriveTangents: smooth normals and tangents over all the triangles of a vertex, with
    ///   the normals of duplicated vertexes added (ADupVerts are pairs). With dominant triangles
    ///   it is R_DeriveUnsmoothedTangents and no planes are given. The planes are the face
    ///   planes (nil when the dominant triangles are used).
    /// </summary>
    class function DeriveTangents(var AVerts: TArray<TStaticDrawVert>; const AIndexes: TArray<Integer>;
      const ADupVerts: TArray<Integer>; const ADominantTris: TArray<TStaticDominantTri>): TArray<TGeoPlane>; static;
    /// <summary>
    ///   R_DeriveTangentsWithoutNormals: the normals are kept; the tangents are summed over the
    ///   triangles from each face in isolation, then projected on the normal plane
    /// </summary>
    class procedure DeriveTangentsWithoutNormals(var AVerts: TArray<TStaticDrawVert>;
      const AIndexes: TArray<Integer>); static;
    /// <summary>R_DeriveUnsmoothedTangents: the dominant triangle of every vertex alone</summary>
    class procedure DeriveUnsmoothedTangents(var AVerts: TArray<TStaticDrawVert>;
      const ADominantTris: TArray<TStaticDominantTri>); static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Math,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Geometry.Vec3;

function ToGeo(const AValue: TIdVec3): TGeoVec3;
begin
  Result := TGeoVec3.Make(AValue.X, AValue.Y, AValue.Z);
end;

function FlipSign(const AValue: Single; const ASign: Cardinal): Single;
var
  LBits: Cardinal;
begin
  LBits := PCardinal(@AValue)^ xor ASign;
  Result := PSingle(@LBits)^;
end;

function MakePlane(const AA: TStaticDrawVert; const ANormal: TIdVec3): TGeoPlane;
begin
  Result.Zero;
  Result.SetNormal(ToGeo(ANormal));
  Result.FitThroughPoint(ToGeo(AA.Xyz));
end;

{ TStaticTangentDeriver }

class function TStaticTangentDeriver.DeriveFacePlanes(const AVerts: TArray<TStaticDrawVert>;
  const AIndexes: TArray<Integer>): TArray<TGeoPlane>;
var
  LIndex: Integer;
  LA, LB, LC: Integer;
  D0, D1: array[0..2] of Single;
  LNormal: TIdVec3;
  LFactor: Single;
begin
  SetLength(Result, Length(AIndexes) div 3);
  LIndex := 0;
  while LIndex + 2 < Length(AIndexes) do
  begin
    LA := AIndexes[LIndex];
    LB := AIndexes[LIndex + 1];
    LC := AIndexes[LIndex + 2];
    D0[0] := AVerts[LB].Xyz.X - AVerts[LA].Xyz.X;
    D0[1] := AVerts[LB].Xyz.Y - AVerts[LA].Xyz.Y;
    D0[2] := AVerts[LB].Xyz.Z - AVerts[LA].Xyz.Z;
    D1[0] := AVerts[LC].Xyz.X - AVerts[LA].Xyz.X;
    D1[1] := AVerts[LC].Xyz.Y - AVerts[LA].Xyz.Y;
    D1[2] := AVerts[LC].Xyz.Z - AVerts[LA].Xyz.Z;
    LNormal.X := D1[1] * D0[2] - D1[2] * D0[1];
    LNormal.Y := D1[2] * D0[0] - D1[0] * D0[2];
    LNormal.Z := D1[0] * D0[1] - D1[1] * D0[0];
    LFactor := TIdMath.RSqrt(LNormal.X * LNormal.X + LNormal.Y * LNormal.Y + LNormal.Z * LNormal.Z);
    LNormal.X := LNormal.X * LFactor;
    LNormal.Y := LNormal.Y * LFactor;
    LNormal.Z := LNormal.Z * LFactor;
    Result[LIndex div 3] := MakePlane(AVerts[LA], LNormal);
    Inc(LIndex, 3);
  end;
end;

class procedure TStaticTangentDeriver.DeriveUnsmoothedTangents(var AVerts: TArray<TStaticDrawVert>;
  const ADominantTris: TArray<TStaticDominantTri>);
var
  LIndex: Integer;
  LB, LC: Integer;
  D0, D1, D2, D3, D4, D5, D6, D7, D8, D9: Single;
  S0, S1, S2, N0, N1, N2, T0, T1, T2, T3, T4, T5: Single;
begin
  for LIndex := 0 to High(AVerts) do
  begin
    LB := ADominantTris[LIndex].V2;
    LC := ADominantTris[LIndex].V3;
    D0 := AVerts[LB].Xyz.X - AVerts[LIndex].Xyz.X;
    D1 := AVerts[LB].Xyz.Y - AVerts[LIndex].Xyz.Y;
    D2 := AVerts[LB].Xyz.Z - AVerts[LIndex].Xyz.Z;
    D3 := AVerts[LB].St.X - AVerts[LIndex].St.X;
    D4 := AVerts[LB].St.Y - AVerts[LIndex].St.Y;
    D5 := AVerts[LC].Xyz.X - AVerts[LIndex].Xyz.X;
    D6 := AVerts[LC].Xyz.Y - AVerts[LIndex].Xyz.Y;
    D7 := AVerts[LC].Xyz.Z - AVerts[LIndex].Xyz.Z;
    D8 := AVerts[LC].St.X - AVerts[LIndex].St.X;
    D9 := AVerts[LC].St.Y - AVerts[LIndex].St.Y;
    S0 := ADominantTris[LIndex].NormalizationScale[0];
    S1 := ADominantTris[LIndex].NormalizationScale[1];
    S2 := ADominantTris[LIndex].NormalizationScale[2];
    N0 := S2 * (D6 * D2 - D7 * D1);
    N1 := S2 * (D7 * D0 - D5 * D2);
    N2 := S2 * (D5 * D1 - D6 * D0);
    T0 := S0 * (D0 * D9 - D4 * D5);
    T1 := S0 * (D1 * D9 - D4 * D6);
    T2 := S0 * (D2 * D9 - D4 * D7);
    // DERIVE_UNSMOOTHED_BITANGENT is defined in the generic processor
    T3 := S1 * (N2 * T1 - N1 * T2);
    T4 := S1 * (N0 * T2 - N2 * T0);
    T5 := S1 * (N1 * T0 - N0 * T1);
    AVerts[LIndex].Normal := TIdVec3.Create(N0, N1, N2);
    AVerts[LIndex].Tangents[0] := TIdVec3.Create(T0, T1, T2);
    AVerts[LIndex].Tangents[1] := TIdVec3.Create(T3, T4, T5);
  end;
end;

class function TStaticTangentDeriver.DeriveTangents(var AVerts: TArray<TStaticDrawVert>;
  const AIndexes: TArray<Integer>; const ADupVerts: TArray<Integer>;
  const ADominantTris: TArray<TStaticDominantTri>): TArray<TGeoPlane>;
var
  LUsed: TArray<Boolean>;
  LIndex, LCorner, LVertex, LPair: Integer;
  LCorners: array[0..2] of Integer;
  D0, D1: array[0..4] of Single;
  LFactor, LArea: Single;
  LSign: Cardinal;
  LNormal, LT0, LT1: TIdVec3;
  LNumVerts: Integer;
  LF: Single;
begin
  Result := nil;
  if Length(ADominantTris) > 0 then
  begin
    DeriveUnsmoothedTangents(AVerts, ADominantTris);
    Exit;
  end;
  LNumVerts := Length(AVerts);
  SetLength(LUsed, LNumVerts);
  SetLength(Result, Length(AIndexes) div 3);
  LIndex := 0;
  while LIndex + 2 < Length(AIndexes) do
  begin
    LCorners[0] := AIndexes[LIndex];
    LCorners[1] := AIndexes[LIndex + 1];
    LCorners[2] := AIndexes[LIndex + 2];
    D0[0] := AVerts[LCorners[1]].Xyz.X - AVerts[LCorners[0]].Xyz.X;
    D0[1] := AVerts[LCorners[1]].Xyz.Y - AVerts[LCorners[0]].Xyz.Y;
    D0[2] := AVerts[LCorners[1]].Xyz.Z - AVerts[LCorners[0]].Xyz.Z;
    D0[3] := AVerts[LCorners[1]].St.X - AVerts[LCorners[0]].St.X;
    D0[4] := AVerts[LCorners[1]].St.Y - AVerts[LCorners[0]].St.Y;
    D1[0] := AVerts[LCorners[2]].Xyz.X - AVerts[LCorners[0]].Xyz.X;
    D1[1] := AVerts[LCorners[2]].Xyz.Y - AVerts[LCorners[0]].Xyz.Y;
    D1[2] := AVerts[LCorners[2]].Xyz.Z - AVerts[LCorners[0]].Xyz.Z;
    D1[3] := AVerts[LCorners[2]].St.X - AVerts[LCorners[0]].St.X;
    D1[4] := AVerts[LCorners[2]].St.Y - AVerts[LCorners[0]].St.Y;

    LNormal.X := D1[1] * D0[2] - D1[2] * D0[1];
    LNormal.Y := D1[2] * D0[0] - D1[0] * D0[2];
    LNormal.Z := D1[0] * D0[1] - D1[1] * D0[0];
    LFactor := TIdMath.RSqrt(LNormal.X * LNormal.X + LNormal.Y * LNormal.Y + LNormal.Z * LNormal.Z);
    LNormal.X := LNormal.X * LFactor;
    LNormal.Y := LNormal.Y * LFactor;
    LNormal.Z := LNormal.Z * LFactor;
    Result[LIndex div 3] := MakePlane(AVerts[LCorners[0]], LNormal);

    LArea := D0[3] * D1[4] - D0[4] * D1[3];
    LSign := PCardinal(@LArea)^ and $80000000;

    LT0.X := D0[0] * D1[4] - D0[4] * D1[0];
    LT0.Y := D0[1] * D1[4] - D0[4] * D1[1];
    LT0.Z := D0[2] * D1[4] - D0[4] * D1[2];
    LF := TIdMath.RSqrt(LT0.X * LT0.X + LT0.Y * LT0.Y + LT0.Z * LT0.Z);
    LF := FlipSign(LF, LSign);
    LT0.X := LT0.X * LF;
    LT0.Y := LT0.Y * LF;
    LT0.Z := LT0.Z * LF;

    LT1.X := D0[3] * D1[0] - D0[0] * D1[3];
    LT1.Y := D0[3] * D1[1] - D0[1] * D1[3];
    LT1.Z := D0[3] * D1[2] - D0[2] * D1[3];
    LF := TIdMath.RSqrt(LT1.X * LT1.X + LT1.Y * LT1.Y + LT1.Z * LT1.Z);
    LF := FlipSign(LF, LSign);
    LT1.X := LT1.X * LF;
    LT1.Y := LT1.Y * LF;
    LT1.Z := LT1.Z * LF;

    for LCorner := 0 to 2 do
    begin
      LVertex := LCorners[LCorner];
      if LUsed[LVertex] then
      begin
        AVerts[LVertex].Normal := AVerts[LVertex].Normal + LNormal;
        AVerts[LVertex].Tangents[0] := AVerts[LVertex].Tangents[0] + LT0;
        AVerts[LVertex].Tangents[1] := AVerts[LVertex].Tangents[1] + LT1;
      end
      else
      begin
        AVerts[LVertex].Normal := LNormal;
        AVerts[LVertex].Tangents[0] := LT0;
        AVerts[LVertex].Tangents[1] := LT1;
        LUsed[LVertex] := True;
      end;
    end;
    Inc(LIndex, 3);
  end;

  // add the normal of a duplicated vertex to the normal of the first vertex with the same XYZ
  for LPair := 0 to (Length(ADupVerts) div 2) - 1 do
    AVerts[ADupVerts[LPair * 2]].Normal :=
      AVerts[ADupVerts[LPair * 2]].Normal + AVerts[ADupVerts[LPair * 2 + 1]].Normal;
  // copy vertex normals to duplicated vertices
  for LPair := 0 to (Length(ADupVerts) div 2) - 1 do
    AVerts[ADupVerts[LPair * 2 + 1]].Normal := AVerts[ADupVerts[LPair * 2]].Normal;

  // NormalizeTangents
  for LVertex := 0 to LNumVerts - 1 do
  begin
    LF := TIdMath.RSqrt(AVerts[LVertex].Normal.X * AVerts[LVertex].Normal.X +
      AVerts[LVertex].Normal.Y * AVerts[LVertex].Normal.Y + AVerts[LVertex].Normal.Z * AVerts[LVertex].Normal.Z);
    AVerts[LVertex].Normal := AVerts[LVertex].Normal * LF;
    for LCorner := 0 to 1 do
    begin
      LNormal := AVerts[LVertex].Tangents[LCorner];
      LNormal := LNormal - (LNormal * AVerts[LVertex].Normal) * AVerts[LVertex].Normal;
      LF := TIdMath.RSqrt(LNormal.X * LNormal.X + LNormal.Y * LNormal.Y + LNormal.Z * LNormal.Z);
      AVerts[LVertex].Tangents[LCorner] := LNormal * LF;
    end;
  end;
end;

class procedure TStaticTangentDeriver.DeriveTangentsWithoutNormals(var AVerts: TArray<TStaticDrawVert>;
  const AIndexes: TArray<Integer>);
type
  TFaceTangents = record
    Tangents: array[0..1] of TIdVec3;
  end;
var
  LFaces: TArray<TFaceTangents>;
  LIndex, LCorner, LVertex, LTangent: Integer;
  LA, LB, LC: Integer;
  D0, D1: array[0..4] of Single;
  LArea, LDot, LInva: Single;
  LTemp: TIdVec3;
begin
  SetLength(LFaces, Length(AIndexes) div 3);
  LIndex := 0;
  while LIndex + 2 < Length(AIndexes) do
  begin
    LA := AIndexes[LIndex];
    LB := AIndexes[LIndex + 1];
    LC := AIndexes[LIndex + 2];
    D0[0] := AVerts[LB].Xyz.X - AVerts[LA].Xyz.X;
    D0[1] := AVerts[LB].Xyz.Y - AVerts[LA].Xyz.Y;
    D0[2] := AVerts[LB].Xyz.Z - AVerts[LA].Xyz.Z;
    D0[3] := AVerts[LB].St.X - AVerts[LA].St.X;
    D0[4] := AVerts[LB].St.Y - AVerts[LA].St.Y;
    D1[0] := AVerts[LC].Xyz.X - AVerts[LA].Xyz.X;
    D1[1] := AVerts[LC].Xyz.Y - AVerts[LA].Xyz.Y;
    D1[2] := AVerts[LC].Xyz.Z - AVerts[LA].Xyz.Z;
    D1[3] := AVerts[LC].St.X - AVerts[LA].St.X;
    D1[4] := AVerts[LC].St.Y - AVerts[LA].St.Y;
    LArea := D0[3] * D1[4] - D0[4] * D1[3];
    if Abs(LArea) < 1E-20 then
    begin
      LFaces[LIndex div 3].Tangents[0].Zero;
      LFaces[LIndex div 3].Tangents[1].Zero;
    end
    else
    begin
      // USE_INVA is defined in tr_trisurf.cpp: the vectors are multiplied by the sign of the area
      if LArea < 0 then
        LInva := -1
      else
        LInva := 1;
      LTemp.X := (D0[0] * D1[4] - D0[4] * D1[0]) * LInva;
      LTemp.Y := (D0[1] * D1[4] - D0[4] * D1[1]) * LInva;
      LTemp.Z := (D0[2] * D1[4] - D0[4] * D1[2]) * LInva;
      LTemp.Normalize;
      LFaces[LIndex div 3].Tangents[0] := LTemp;
      LTemp.X := (D0[3] * D1[0] - D0[0] * D1[3]) * LInva;
      LTemp.Y := (D0[3] * D1[1] - D0[1] * D1[3]) * LInva;
      LTemp.Z := (D0[3] * D1[2] - D0[2] * D1[3]) * LInva;
      LTemp.Normalize;
      LFaces[LIndex div 3].Tangents[1] := LTemp;
    end;
    Inc(LIndex, 3);
  end;

  for LVertex := 0 to High(AVerts) do
  begin
    AVerts[LVertex].Tangents[0].Zero;
    AVerts[LVertex].Tangents[1].Zero;
  end;
  LIndex := 0;
  while LIndex + 2 < Length(AIndexes) do
  begin
    for LCorner := 0 to 2 do
    begin
      LVertex := AIndexes[LIndex + LCorner];
      AVerts[LVertex].Tangents[0] := AVerts[LVertex].Tangents[0] + LFaces[LIndex div 3].Tangents[0];
      AVerts[LVertex].Tangents[1] := AVerts[LVertex].Tangents[1] + LFaces[LIndex div 3].Tangents[1];
    end;
    Inc(LIndex, 3);
  end;

  for LVertex := 0 to High(AVerts) do
    for LTangent := 0 to 1 do
    begin
      LDot := AVerts[LVertex].Tangents[LTangent] * AVerts[LVertex].Normal;
      LTemp := AVerts[LVertex].Tangents[LTangent] - LDot * AVerts[LVertex].Normal;
      LTemp.Normalize;
      AVerts[LVertex].Tangents[LTangent] := LTemp;
    end;
end;

end.
