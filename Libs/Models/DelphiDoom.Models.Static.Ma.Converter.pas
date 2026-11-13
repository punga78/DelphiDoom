{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: MA objects to surfaces       }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (idRenderModelStatic::ConvertMAToModelSurfaces). Copyright (C) 1999-2011    }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Ma.Converter;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Ma.Types;

type
  /// <summary>
  ///   Builds the surfaces of a model from the objects of a Maya file: one surface per material
  ///   (merged by name when the options say so), the positions, texture points, colours and
  ///   normals welded into vertexes. Differences from the original: the materials are names (no
  ///   renderbump, no "discrete" materials), a model without objects is an empty model as in
  ///   the original (the result of the conversion is ignored there) and an out of range index
  ///   of the file is an error where the original reads outside the arrays. The time stamp of
  ///   the file is not kept by the static model.
  /// </summary>
  TMaConverter = class
  strict private
    FOptions: TStaticLoadOptions;
  public
    constructor Create(const AOptions: TStaticLoadOptions);
    function Convert(const AModel: TMaModel; const AName: string): IStaticModel;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Model,
  DelphiDoom.Models.Static.SurfacePlanner,
  DelphiDoom.Models.Static.VectorSubset,
  DelphiDoom.Models.Static.VertexWelder;

{ TMaConverter }

constructor TMaConverter.Create(const AOptions: TStaticLoadOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

function TMaConverter.Convert(const AModel: TMaModel; const AName: string): IStaticModel;
var
  LModel: TStaticModel;
  LNames: TArray<AnsiString>;
  LMergeTo, LVRemap, LTvRemap: TArray<Integer>;
  LObject: TMaObject;
  LObjectIndex, LIndex, LFace, LCorner, LV, LTv: Integer;
  LNormalEpsilon, LU, LTexV: Single;
  LNormalsParsed: Boolean;
  LWelder: TStaticVertexWelder;
  LTriangles: TStaticTriangles;
  LNormal: TIdVec3;
  LColor: TStaticColor;
  LVertex: TStaticDrawVert;
begin
  LModel := TStaticModel.Create(AName);
  Result := LModel;
  if AModel.Objects.Count < 1 then
  begin
    LModel.Finish;
    Exit;
  end;

  // the modeling programs can save out multiple surfaces with a common
  // material, but we would like to merge them together where possible
  SetLength(LMergeTo, AModel.Objects.Count);
  if AModel.Materials.Count = 0 then
  begin
    // if we don't have any materials, dump everything into a single surface
    LModel.AddSurface(STATIC_DEFAULT_MATERIAL);
  end
  else
  begin
    SetLength(LNames, AModel.Objects.Count);
    for LIndex := 0 to High(LNames) do
      if AModel.Objects[LIndex].MaterialRef >= 0 then
        LNames[LIndex] := AModel.Materials[AModel.Objects[LIndex].MaterialRef]
      else
        LNames[LIndex] := STATIC_DEFAULT_MATERIAL;
    LMergeTo := TStaticSurfacePlanner.Plan(LModel, LNames, FOptions.MergeSurfaces);
  end;

  for LObjectIndex := 0 to AModel.Objects.Count - 1 do
  begin
    LObject := AModel.Objects[LObjectIndex];
    LNormalsParsed := LObject.Mesh.NormalsParsed;

    // the tools often generate verts and texcoords slightly separated that should be merged
    if FOptions.FastLoad then
    begin
      SetLength(LVRemap, Length(LObject.Mesh.Vertexes));
      for LIndex := 0 to High(LVRemap) do
        LVRemap[LIndex] := LIndex;
      SetLength(LTvRemap, Length(LObject.Mesh.TVertexes));
      for LIndex := 0 to High(LTvRemap) do
        LTvRemap[LIndex] := LIndex;
    end
    else
    begin
      LVRemap := nil;
      if Length(LObject.Mesh.Vertexes) > 0 then
        LVRemap := TStaticVectorSubset.RemapPositions(LObject.Mesh.Vertexes, FOptions.SlopVertex);
      LTvRemap := nil;
      if Length(LObject.Mesh.TVertexes) > 0 then
        LTvRemap := TStaticVectorSubset.RemapTexCoords(LObject.Mesh.TVertexes, FOptions.SlopTexCoord);
    end;
    LNormalEpsilon := 1.0 - FOptions.SlopNormal;

    LWelder := TStaticVertexWelder.Create(Length(LObject.Mesh.Vertexes), Length(LObject.Mesh.Faces) * 3);
    try
      LTriangles := Default(TStaticTriangles);
      SetLength(LTriangles.Indexes, Length(LObject.Mesh.Faces) * 3);
      LNormal.Zero;
      LColor := TStaticColor.Make(255, 255, 255, 255);
      LTv := 0;
      // find all the unique combinations
      for LFace := 0 to High(LObject.Mesh.Faces) do
        for LCorner := 0 to 2 do
        begin
          LV := LObject.Mesh.Faces[LFace].VertexNum[LCorner];
          if (LV < 0) or (LV >= Length(LObject.Mesh.Vertexes)) then
            raise EStaticModelException.CreateAtLine(Format(SMaBadVertex, [AName]), 0);
          // collapse the position if it was slightly offset
          LV := LVRemap[LV];
          // we may or may not have texcoords to compare
          if Length(LObject.Mesh.TVertexes) <> 0 then
          begin
            LTv := LObject.Mesh.Faces[LFace].TVertexNum[LCorner];
            if (LTv < 0) or (LTv >= Length(LObject.Mesh.TVertexes)) then
              raise EStaticModelException.CreateAtLine(Format(SMaBadTexCoord, [AName]), 0);
            LTv := LTvRemap[LTv];
          end;
          // we may or may not have normals to compare
          if LNormalsParsed then
            LNormal := LObject.Mesh.Faces[LFace].VertexNormals[LCorner];
          // we may or may not have colors to compare: the last one stays when a vertex has none
          LIndex := LObject.Mesh.Faces[LFace].VertexColors[LCorner];
          if (LIndex <> -1) and (LIndex <> -999) then
          begin
            if (LIndex < 0) or (LIndex * 4 + 3 >= Length(LObject.Mesh.Colors)) then
              raise EStaticModelException.CreateAtLine(Format(SMaIndexRange,
                [AName, 'color', LIndex, Length(LObject.Mesh.Colors) div 4]), 0);
            LColor := TStaticColor.Make(LObject.Mesh.Colors[LIndex * 4], LObject.Mesh.Colors[LIndex * 4 + 1],
              LObject.Mesh.Colors[LIndex * 4 + 2], LObject.Mesh.Colors[LIndex * 4 + 3]);
          end;
          LTriangles.Indexes[LFace * 3 + LCorner] :=
            LWelder.Find(LV, LTv, LColor.ToCardinal, LNormal, LNormalsParsed, LNormalEpsilon);
        end;
      LTriangles.GenerateNormals := not LNormalsParsed;

      // an MA allows no texture matrix: the texture coordinates are taken as they are
      SetLength(LTriangles.Verts, LWelder.Count);
      for LIndex := 0 to LWelder.Count - 1 do
      begin
        LVertex.Clear;
        LVertex.Xyz := LObject.Mesh.Vertexes[LWelder.Position(LIndex)];
        LVertex.Normal := LWelder.Normal(LIndex);
        LVertex.Color := TStaticColor.FromCardinal(LWelder.Color(LIndex));
        if Length(LObject.Mesh.TVertexes) <> 0 then
        begin
          LU := LObject.Mesh.TVertexes[LWelder.TexCoord(LIndex)].X * 1.0 + 0.0;
          LTexV := LObject.Mesh.TVertexes[LWelder.TexCoord(LIndex)].Y * 1.0 + 0.0;
          // the texture matrix of the original with the angle zero: cos 1, sin 0
          LVertex.St.X := LU * 1.0 + LTexV * 0.0;
          LVertex.St.Y := LU * -0.0 + LTexV * 1.0;
        end;
        LTriangles.Verts[LIndex] := LVertex;
      end;
    finally
      LWelder.Free;
    end;
    if AModel.Materials.Count = 0 then
      LModel.AddGeometry(0, LTriangles)
    else
      LModel.AddGeometry(LMergeTo[LObjectIndex], LTriangles);
  end;
  LModel.Finish;
end;

end.
