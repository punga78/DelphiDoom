{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: from an ASE model to a model }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (idRenderModelStatic::ConvertASEToModelSurfaces). Copyright (C) 1999-2011   }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Ase.Converter;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Ase.Types;

type
  /// <summary>
  ///   Builds the surfaces of a model from the objects of an ASE file: one surface per material
  ///   (merged by name when the options say so), the vertexes (ASE keeps positions and texture
  ///   vertexes apart) welded, the texture matrix of the material applied to the texture
  ///   coordinates. Differences from the original: a model without materials goes into a single
  ///   surface of the default material (the original reads the first material anyway), and the
  ///   materials are names (no renderbump, no "discrete" materials).
  /// </summary>
  TAseConverter = class
  strict private
    FOptions: TStaticLoadOptions;
  public
    constructor Create(const AOptions: TStaticLoadOptions);
    function Convert(const AModel: TAseModel; const AName: string): IStaticModel;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math,
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Model,
  DelphiDoom.Models.Static.SurfacePlanner,
  DelphiDoom.Models.Static.VectorSubset,
  DelphiDoom.Models.Static.VertexWelder;

{ TAseConverter }

constructor TAseConverter.Create(const AOptions: TStaticLoadOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

function TAseConverter.Convert(const AModel: TAseModel; const AName: string): IStaticModel;
var
  LModel: TStaticModel;
  LNames: TArray<AnsiString>;
  LMergeTo, LVRemap, LTvRemap: TArray<Integer>;
  LObjectIndex, LIndex, LFace, LCorner, LV, LTv: Integer;
  LNormalEpsilon: Single;
  LMesh: ^TAseMesh;
  LMaterial: TAseMaterial;
  LHasMaterials, LHasTexCoords, LNormalsParsed: Boolean;
  LWelder: TStaticVertexWelder;
  LTriangles: TStaticTriangles;
  LNormal: TIdVec3;
  LColor: TStaticColor;
  LUOffset, LVOffset, LUTiling, LVTiling, LSin, LCos, LU, LVCoord: Single;
  LVertex: TStaticDrawVert;
begin
  if Length(AModel.Objects) < 1 then
    raise EStaticModelException.CreateAtLine(SStaticAseNoObjects, 0);
  LHasMaterials := Length(AModel.Materials) > 0;
  LModel := TStaticModel.Create(AName);
  Result := LModel;

  // the modeling programs can save out multiple surfaces with a common
  // material, but we would like to merge them together where possible
  SetLength(LMergeTo, Length(AModel.Objects));
  if not LHasMaterials then
  begin
    LModel.AddSurface(STATIC_DEFAULT_MATERIAL);
    for LIndex := 0 to High(LMergeTo) do
      LMergeTo[LIndex] := 0;
  end
  else
  begin
    SetLength(LNames, Length(AModel.Objects));
    for LIndex := 0 to High(LNames) do
    begin
      if (AModel.Objects[LIndex].MaterialRef < 0) or
        (AModel.Objects[LIndex].MaterialRef >= Length(AModel.Materials)) then
        raise EStaticModelException.CreateAtLine(Format(SStaticAseBadMaterial,
          [LIndex, AModel.Objects[LIndex].MaterialRef, Length(AModel.Materials)]), 0);
      LNames[LIndex] := AModel.Materials[AModel.Objects[LIndex].MaterialRef].Name;
    end;
    LMergeTo := TStaticSurfacePlanner.Plan(LModel, LNames, FOptions.MergeSurfaces);
  end;

  for LObjectIndex := 0 to High(AModel.Objects) do
  begin
    LMesh := @AModel.Objects[LObjectIndex].Mesh;
    LNormalsParsed := LMesh^.NormalsParsed;

    // the tools often generate verts and texcoords slightly separated that should be merged
    if FOptions.FastLoad then
    begin
      SetLength(LVRemap, Length(LMesh^.Vertexes));
      for LIndex := 0 to High(LVRemap) do
        LVRemap[LIndex] := LIndex;
      SetLength(LTvRemap, Length(LMesh^.TVertexes));
      for LIndex := 0 to High(LTvRemap) do
        LTvRemap[LIndex] := LIndex;
    end
    else
    begin
      LVRemap := TStaticVectorSubset.RemapPositions(LMesh^.Vertexes, FOptions.SlopVertex);
      LTvRemap := TStaticVectorSubset.RemapTexCoords(LMesh^.TVertexes, FOptions.SlopTexCoord);
    end;
    LNormalEpsilon := 1.0 - FOptions.SlopNormal;
    LHasTexCoords := (LMesh^.NumTVFaces = LMesh^.NumFaces) and (LMesh^.NumTVertexes <> 0);

    LWelder := TStaticVertexWelder.Create(Length(LMesh^.Vertexes), Length(LMesh^.Faces) * 3);
    try
      SetLength(LTriangles.Indexes, 0);
      SetLength(LTriangles.Indexes, Length(LMesh^.Faces) * 3);
      LNormal.Zero;
      LColor := TStaticColor.Make(255, 255, 255, 255);
      LTv := 0;
      // find all the unique combinations
      for LFace := 0 to High(LMesh^.Faces) do
        for LCorner := 0 to 2 do
        begin
          LV := LMesh^.Faces[LFace].VertexNum[LCorner];
          if (LV < 0) or (LV >= Length(LMesh^.Vertexes)) then
            raise EStaticModelException.CreateAtLine(SStaticAseBadVertex, 0);
          // collapse the position if it was slightly offset
          LV := LVRemap[LV];
          // we may or may not have texcoords to compare
          if LHasTexCoords then
          begin
            LTv := LMesh^.Faces[LFace].TVertexNum[LCorner];
            if (LTv < 0) or (LTv >= Length(LMesh^.TVertexes)) then
              raise EStaticModelException.CreateAtLine(SStaticAseBadTexCoord, 0);
            LTv := LTvRemap[LTv];
          end;
          if LNormalsParsed then
            LNormal := LMesh^.Faces[LFace].VertexNormals[LCorner];
          if LMesh^.ColorsParsed then
            LColor := LMesh^.Faces[LFace].VertexColors[LCorner];
          LTriangles.Indexes[LFace * 3 + LCorner] :=
            LWelder.Find(LV, LTv, LColor.ToCardinal, LNormal, LNormalsParsed, LNormalEpsilon);
        end;
      LTriangles.GenerateNormals := not LNormalsParsed;

      // an ASE allows the texture coordinates to be scaled, translated, and rotated
      if not LHasMaterials then
      begin
        LUOffset := 0.0;
        LVOffset := 0.0;
        LUTiling := 1.0;
        LVTiling := 1.0;
        LSin := 0.0;
        LCos := 1.0;
      end
      else
      begin
        LMaterial := AModel.Materials[AModel.Objects[LObjectIndex].MaterialRef];
        LUOffset := -LMaterial.UOffset;
        LVOffset := LMaterial.VOffset;
        LUTiling := LMaterial.UTiling;
        LVTiling := LMaterial.VTiling;
        LSin := TIdMath.Sin(LMaterial.Angle);
        LCos := TIdMath.Cos(LMaterial.Angle);
      end;

      // now generate the combined vertexes
      LTriangles.Verts := nil;
      SetLength(LTriangles.Verts, LWelder.Count);
      for LIndex := 0 to LWelder.Count - 1 do
      begin
        LVertex.Clear;
        LVertex.Xyz := LMesh^.Vertexes[LWelder.Position(LIndex)];
        LVertex.Normal := LWelder.Normal(LIndex);
        LVertex.Color := TStaticColor.FromCardinal(LWelder.Color(LIndex));
        if LHasTexCoords then
        begin
          LU := LMesh^.TVertexes[LWelder.TexCoord(LIndex)].X * LUTiling + LUOffset;
          LVCoord := LMesh^.TVertexes[LWelder.TexCoord(LIndex)].Y * LVTiling + LVOffset;
          LVertex.St.X := LU * LCos + LVCoord * LSin;
          LVertex.St.Y := LU * -LSin + LVCoord * LCos;
        end;
        LTriangles.Verts[LIndex] := LVertex;
      end;
    finally
      LWelder.Free;
    end;
    LModel.AddGeometry(LMergeTo[LObjectIndex], LTriangles);
    LTriangles.Indexes := nil;
  end;
  LModel.Finish;
end;

end.
