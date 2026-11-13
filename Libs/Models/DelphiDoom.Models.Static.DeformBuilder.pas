{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - deform info of a surface                    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\tr_trisurf.cpp  }
{  (R_BuildDeformInfo, R_CreateSilRemap, R_CreateSilIndexes, R_CreateDupVerts, }
{  R_DuplicateMirroredVertexes, R_BuildDominantTris). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.DeformBuilder;

interface

uses
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Deform.Types;

type
  /// <summary>
  ///   Builds the deform info of a mesh (R_BuildDeformInfo): the silhouette remap of the
  ///   vertexes with the same position, the duplication of the vertexes that are used by both
  ///   texture polarities, the pairs of duplicated vertexes and, if asked, the dominant
  ///   triangles. The silhouette edges are not built. It has no state.
  /// </summary>
  TStaticDeformBuilder = class
  strict private
    class function CreateSilRemap(const AVerts: TArray<TStaticDrawVert>): TArray<Integer>; static;
    class function NegativePolarity(const AVerts: TArray<TStaticDrawVert>; const AIndexes: TArray<Integer>;
      const AFirstIndex: Integer): Boolean; static;
    class procedure DuplicateMirroredVertexes(var AVerts: TArray<TStaticDrawVert>;
      var AIndexes: TArray<Integer>; out AMirrored: TArray<Integer>); static;
    class function CreateDupVerts(const ANumVerts: Integer; const AIndexes, ASilIndexes: TArray<Integer>): TArray<Integer>; static;
    class function BuildDominantTris(const AVerts: TArray<TStaticDrawVert>;
      const AIndexes: TArray<Integer>): TArray<TStaticDominantTri>; static;
  public
    /// <summary>
    ///   R_BuildDeformInfo. The vertexes need only the positions and the texture points; the
    ///   indexes must be in range (EStaticModelException otherwise, as R_RangeCheckIndexes).
    ///   Where the original sorts the indexes of a vertex with qsort (not stable), the faces of
    ///   a vertex are taken in the order they appear: it matters only for equal areas.
    /// </summary>
    class function Build(const AVerts: TArray<TStaticDrawVert>; const AIndexes: TArray<Integer>;
      const AUseUnsmoothedTangents: Boolean): TStaticDeformInfo; static;
    /// <summary>R_CreateSilIndexes: every index replaced by the first vertex with the same position</summary>
    class function CreateSilIndexes(const AVerts: TArray<TStaticDrawVert>;
      const AIndexes: TArray<Integer>): TArray<Integer>; static;
    /// <summary>R_RangeCheckIndexes</summary>
    class procedure RangeCheckIndexes(const ANumVerts: Integer; const AIndexes: TArray<Integer>); static;
    /// <summary>
    ///   R_DuplicateMirroredVertexes as it is used by R_CleanupTriangles: the vertexes (with the
    ///   new ones at the end) and the indexes change; the sources of the new vertexes are given.
    /// </summary>
    class procedure SplitMirroredVertexes(var AVerts: TArray<TStaticDrawVert>;
      var AIndexes: TArray<Integer>; out AMirrored: TArray<Integer>); static;
    /// <summary>R_CreateDupVerts: the pairs of duplicated vertexes</summary>
    class function FindDupVerts(const ANumVerts: Integer; const AIndexes, ASilIndexes: TArray<Integer>): TArray<Integer>; static;
    /// <summary>R_BuildDominantTris</summary>
    class function FindDominantTris(const AVerts: TArray<TStaticDrawVert>;
      const AIndexes: TArray<Integer>): TArray<TStaticDominantTri>; static;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  DelphiDoom.IdLib.Containers.HashIndex,
  DelphiDoom.IdLib.Math.Vec3;

{ TStaticDeformBuilder }

class procedure TStaticDeformBuilder.RangeCheckIndexes(const ANumVerts: Integer; const AIndexes: TArray<Integer>);
var
  LIndex: Integer;
begin
  if (Length(AIndexes) mod 3) <> 0 then
    raise EStaticModelException.CreateAtLine(SStaticDeformIndexCount, 0);
  for LIndex := 0 to High(AIndexes) do
    if (AIndexes[LIndex] < 0) or (AIndexes[LIndex] >= ANumVerts) then
      raise EStaticModelException.CreateAtLine(SStaticDeformIndexRange, 0);
end;

class function TStaticDeformBuilder.CreateSilRemap(const AVerts: TArray<TStaticDrawVert>): TArray<Integer>;
var
  LHash: TIdHashIndex;
  LVertex, LOther, LKey: Integer;
begin
  SetLength(Result, Length(AVerts));
  LHash := TIdHashIndex.Create(1024, Length(AVerts));
  try
    for LVertex := 0 to High(AVerts) do
    begin
      LKey := LHash.GenerateKey(AVerts[LVertex].Xyz.X, AVerts[LVertex].Xyz.Y, AVerts[LVertex].Xyz.Z);
      LOther := LHash.First(LKey);
      while LOther >= 0 do
      begin
        if (AVerts[LOther].Xyz.X = AVerts[LVertex].Xyz.X) and (AVerts[LOther].Xyz.Y = AVerts[LVertex].Xyz.Y) and
          (AVerts[LOther].Xyz.Z = AVerts[LVertex].Xyz.Z) then
        begin
          Result[LVertex] := LOther;
          Break;
        end;
        LOther := LHash.Next(LOther);
      end;
      if LOther < 0 then
      begin
        Result[LVertex] := LVertex;
        LHash.Add(LKey, LVertex);
      end;
    end;
  finally
    LHash.Free;
  end;
end;

class function TStaticDeformBuilder.CreateSilIndexes(const AVerts: TArray<TStaticDrawVert>;
  const AIndexes: TArray<Integer>): TArray<Integer>;
var
  LRemap: TArray<Integer>;
  LIndex: Integer;
begin
  LRemap := CreateSilRemap(AVerts);
  SetLength(Result, Length(AIndexes));
  for LIndex := 0 to High(AIndexes) do
    Result[LIndex] := LRemap[AIndexes[LIndex]];
end;

class function TStaticDeformBuilder.NegativePolarity(const AVerts: TArray<TStaticDrawVert>;
  const AIndexes: TArray<Integer>; const AFirstIndex: Integer): Boolean;
var
  LA, LB, LC: Integer;
  LArea: Single;
begin
  LA := AIndexes[AFirstIndex];
  LB := AIndexes[AFirstIndex + 1];
  LC := AIndexes[AFirstIndex + 2];
  LArea := (AVerts[LB].St.X - AVerts[LA].St.X) * (AVerts[LC].St.Y - AVerts[LA].St.Y) -
    (AVerts[LB].St.Y - AVerts[LA].St.Y) * (AVerts[LC].St.X - AVerts[LA].St.X);
  Result := not (LArea >= 0);
end;

class procedure TStaticDeformBuilder.DuplicateMirroredVertexes(var AVerts: TArray<TStaticDrawVert>;
  var AIndexes: TArray<Integer>; out AMirrored: TArray<Integer>);
var
  LUsed: TArray<array[0..1] of Boolean>;
  LRemap: TArray<Integer>;
  LIndex, LCorner, LPolarity, LTotal, LNumVerts, LCount: Integer;
begin
  LNumVerts := Length(AVerts);
  SetLength(LUsed, LNumVerts);
  SetLength(LRemap, LNumVerts);
  LIndex := 0;
  while LIndex + 2 < Length(AIndexes) do
  begin
    LPolarity := Ord(NegativePolarity(AVerts, AIndexes, LIndex));
    for LCorner := 0 to 2 do
      LUsed[AIndexes[LIndex + LCorner]][LPolarity] := True;
    Inc(LIndex, 3);
  end;
  LTotal := LNumVerts;
  for LIndex := 0 to LNumVerts - 1 do
    if LUsed[LIndex][0] and LUsed[LIndex][1] then
    begin
      LRemap[LIndex] := LTotal;
      Inc(LTotal);
    end;
  AMirrored := nil;
  if LTotal = LNumVerts then
    Exit;
  SetLength(AMirrored, LTotal - LNumVerts);
  SetLength(AVerts, LTotal);
  LCount := 0;
  for LIndex := 0 to LNumVerts - 1 do
    if LRemap[LIndex] <> 0 then
    begin
      AVerts[LRemap[LIndex]] := AVerts[LIndex];
      AMirrored[LCount] := LIndex;
      Inc(LCount);
    end;
  // the polarity of a face is read from the vertexes as they are while the indexes change
  for LIndex := 0 to High(AIndexes) do
    if (LRemap[AIndexes[LIndex]] <> 0) and NegativePolarity(AVerts, AIndexes, 3 * (LIndex div 3)) then
      AIndexes[LIndex] := LRemap[AIndexes[LIndex]];
end;

class procedure TStaticDeformBuilder.SplitMirroredVertexes(var AVerts: TArray<TStaticDrawVert>;
  var AIndexes: TArray<Integer>; out AMirrored: TArray<Integer>);
begin
  DuplicateMirroredVertexes(AVerts, AIndexes, AMirrored);
end;

class function TStaticDeformBuilder.CreateDupVerts(const ANumVerts: Integer;
  const AIndexes, ASilIndexes: TArray<Integer>): TArray<Integer>;
var
  LRemap: TArray<Integer>;
  LIndex, LCount: Integer;
begin
  SetLength(LRemap, ANumVerts);
  for LIndex := 0 to ANumVerts - 1 do
    LRemap[LIndex] := LIndex;
  for LIndex := 0 to High(AIndexes) do
    LRemap[AIndexes[LIndex]] := ASilIndexes[LIndex];
  SetLength(Result, ANumVerts * 2);
  LCount := 0;
  for LIndex := 0 to ANumVerts - 1 do
    if LRemap[LIndex] <> LIndex then
    begin
      Result[LCount * 2] := LIndex;
      Result[LCount * 2 + 1] := LRemap[LIndex];
      Inc(LCount);
    end;
  SetLength(Result, LCount * 2);
end;

class function TStaticDeformBuilder.FindDupVerts(const ANumVerts: Integer;
  const AIndexes, ASilIndexes: TArray<Integer>): TArray<Integer>;
begin
  Result := CreateDupVerts(ANumVerts, AIndexes, ASilIndexes);
end;

class function TStaticDeformBuilder.BuildDominantTris(const AVerts: TArray<TStaticDrawVert>;
  const AIndexes: TArray<Integer>): TArray<TStaticDominantTri>;
var
  LOrder: TArray<Integer>;
  LIndex, LRun, LVertex, LFace, I1, I2, I3: Integer;
  LMaxArea, LArea, LLength: Single;
  D0, D1: array[0..4] of Single;
  LNormal, LTangent: TIdVec3;
begin
  // indexes sorted by vertex, faces in ascending order within a vertex
  SetLength(LOrder, Length(AIndexes));
  for LIndex := 0 to High(LOrder) do
    LOrder[LIndex] := LIndex;
  TArray.Sort<Integer>(LOrder, TComparer<Integer>.Construct(
    function(const ALeft, ARight: Integer): Integer
    begin
      if AIndexes[ALeft] < AIndexes[ARight] then
        Exit(-1);
      if AIndexes[ALeft] > AIndexes[ARight] then
        Exit(1);
      Result := ALeft - ARight;
    end));
  SetLength(Result, Length(AVerts));
  FillChar(Result[0], Length(Result) * SizeOf(TStaticDominantTri), 0);
  LIndex := 0;
  while LIndex < Length(LOrder) do
  begin
    LMaxArea := 0;
    LVertex := AIndexes[LOrder[LIndex]];
    LRun := 0;
    while (LIndex + LRun < Length(LOrder)) and (AIndexes[LOrder[LIndex + LRun]] = LVertex) do
    begin
      LFace := LOrder[LIndex + LRun] div 3;
      I1 := AIndexes[LFace * 3];
      I2 := AIndexes[LFace * 3 + 1];
      I3 := AIndexes[LFace * 3 + 2];
      D0[0] := AVerts[I2].Xyz.X - AVerts[I1].Xyz.X;
      D0[1] := AVerts[I2].Xyz.Y - AVerts[I1].Xyz.Y;
      D0[2] := AVerts[I2].Xyz.Z - AVerts[I1].Xyz.Z;
      D0[3] := AVerts[I2].St.X - AVerts[I1].St.X;
      D0[4] := AVerts[I2].St.Y - AVerts[I1].St.Y;
      D1[0] := AVerts[I3].Xyz.X - AVerts[I1].Xyz.X;
      D1[1] := AVerts[I3].Xyz.Y - AVerts[I1].Xyz.Y;
      D1[2] := AVerts[I3].Xyz.Z - AVerts[I1].Xyz.Z;
      D1[3] := AVerts[I3].St.X - AVerts[I1].St.X;
      D1[4] := AVerts[I3].St.Y - AVerts[I1].St.Y;
      LNormal.X := D1[1] * D0[2] - D1[2] * D0[1];
      LNormal.Y := D1[2] * D0[0] - D1[0] * D0[2];
      LNormal.Z := D1[0] * D0[1] - D1[1] * D0[0];
      LArea := LNormal.Length;
      if not (LArea < LMaxArea) then
      begin
        LMaxArea := LArea;
        if I1 = LVertex then
        begin
          Result[LVertex].V2 := I2;
          Result[LVertex].V3 := I3;
        end
        else if I2 = LVertex then
        begin
          Result[LVertex].V2 := I3;
          Result[LVertex].V3 := I1;
        end
        else
        begin
          Result[LVertex].V2 := I1;
          Result[LVertex].V3 := I2;
        end;
        LLength := LArea;
        if LLength < 0.001 then
          LLength := 0.001;
        Result[LVertex].NormalizationScale[2] := 1.0 / LLength;
        LArea := D0[3] * D1[4] - D0[4] * D1[3];
        LTangent.X := D0[0] * D1[4] - D0[4] * D1[0];
        LTangent.Y := D0[1] * D1[4] - D0[4] * D1[1];
        LTangent.Z := D0[2] * D1[4] - D0[4] * D1[2];
        LLength := LTangent.Length;
        if LLength < 0.001 then
          LLength := 0.001;
        if LArea > 0 then
          Result[LVertex].NormalizationScale[0] := 1 / LLength
        else
          Result[LVertex].NormalizationScale[0] := -1 / LLength;
        // USE_INVA and DERIVE_UNSMOOTHED_BITANGENT are defined in tr_trisurf.cpp: the scale of
        // the bitangent is only the sign, the derivation orthogonalises the bitangent
        if LArea > 0 then
          Result[LVertex].NormalizationScale[1] := 1
        else
          Result[LVertex].NormalizationScale[1] := -1;
      end;
      Inc(LRun);
    end;
    Inc(LIndex, LRun);
  end;
end;

class function TStaticDeformBuilder.FindDominantTris(const AVerts: TArray<TStaticDrawVert>;
  const AIndexes: TArray<Integer>): TArray<TStaticDominantTri>;
begin
  Result := BuildDominantTris(AVerts, AIndexes);
end;

class function TStaticDeformBuilder.Build(const AVerts: TArray<TStaticDrawVert>;
  const AIndexes: TArray<Integer>; const AUseUnsmoothedTangents: Boolean): TStaticDeformInfo;
var
  LVerts: TArray<TStaticDrawVert>;
  LIndexes: TArray<Integer>;
begin
  RangeCheckIndexes(Length(AVerts), AIndexes);
  LVerts := Copy(AVerts);
  LIndexes := Copy(AIndexes);
  Result.NumSourceVerts := Length(AVerts);
  Result.SilIndexes := CreateSilIndexes(LVerts, LIndexes);
  DuplicateMirroredVertexes(LVerts, LIndexes, Result.MirroredVerts);
  Result.NumOutputVerts := Length(LVerts);
  Result.DupVerts := CreateDupVerts(Length(LVerts), LIndexes, Result.SilIndexes);
  Result.DominantTris := nil;
  if AUseUnsmoothedTangents then
    Result.DominantTris := BuildDominantTris(LVerts, LIndexes);
  Result.Indexes := LIndexes;
end;

end.
