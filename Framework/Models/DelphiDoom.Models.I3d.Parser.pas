{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the reader of I3D files                     }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The old TI3DModelLoader.LoadFromStream without the stream, the pointers     }
{  and OpenGL: the file is checked against its own size instead of trusted.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.Parser;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.I3d.Intf;

type
  /// <summary>
  ///   From the bytes of an I3D file to the model. The file is the magic, the size of the image,
  ///   the image (the object, its vertexes, normals, materials and the cache of the faces: every
  ///   pointer is an offset from the start of the image) and then the pixels of the textures of the
  ///   materials that have one. Every offset is checked, so a damaged file raises
  ///   EModelsException instead of reading memory that is not there.
  /// </summary>
  TI3dParser = class(TInterfacedObject, II3dParser)
  strict private
    class procedure CheckRange(const AWhat: string; const AOffset, ASize, AImageSize: Int64); static;
    class function IndexInPool(const AFace: Integer; const AWhat: string; const AOffset,
      APoolOffset, APoolCount, AItemSize: Int64): Integer; static;
  public
    function Parse(const ABytes: TBytes): II3dModel;
  end;

implementation

uses
  DelphiDoom.Models.I3d.Model;

{ TI3dParser }

class procedure TI3dParser.CheckRange(const AWhat: string; const AOffset, ASize, AImageSize: Int64);
begin
  if (AOffset < 0) or (ASize < 0) or (AOffset + ASize > AImageSize) then
    raise EModelsException.CreateFmt(SModelsI3dOutside, [AWhat, AOffset, ASize]);
end;

class function TI3dParser.IndexInPool(const AFace: Integer; const AWhat: string; const AOffset,
  APoolOffset, APoolCount, AItemSize: Int64): Integer;
var
  LRelative: Int64;
begin
  LRelative := AOffset - APoolOffset;
  if (LRelative < 0) or (LRelative mod AItemSize <> 0) or (LRelative div AItemSize >= APoolCount) then
    raise EModelsException.CreateFmt(SModelsI3dInvalidReference, [AFace, AWhat, AOffset]);
  Result := Integer(LRelative div AItemSize);
end;

function TI3dParser.Parse(const ABytes: TBytes): II3dModel;
var
  LImageSize: Int64;
  LImage: Int64;
  LDisk: TI3dDiskObject;
  LHeader: TI3dHeader;
  LVertices: TArray<TI3dDiskVertex>;
  LDiskMaterials: TArray<TI3dDiskMaterial>;
  LMaterials: TArray<TI3dMaterial>;
  LTextures: TArray<TI3dTexture>;
  LFaces: TArray<TI3dFace>;
  LFaceHeader: TI3dDiskFaceHeader;
  LFaceVertex: TI3dDiskFaceVertex;
  LVertexIndex: Integer;
  LFace, LCorner, LMaterial: Integer;
  LPosition: Int64;
  LTexturePosition: Int64;
  LTextureSize: Integer;
begin
  if Length(ABytes) < I3D_FILE_HEADER_SIZE + SizeOf(TI3dDiskObject) then
    raise EModelsException.CreateFmt(SModelsI3dTooShort, [Length(ABytes)]);
  if PCardinal(@ABytes[0])^ <> I3D_MAGIC then
    raise EModelsException.CreateFmt(SModelsI3dInvalidMagic, [PInteger(@ABytes[0])^]);
  LImageSize := PInteger(@ABytes[4])^;
  if (LImageSize < SizeOf(TI3dDiskObject)) or (I3D_FILE_HEADER_SIZE + LImageSize > Length(ABytes)) then
    raise EModelsException.CreateFmt(SModelsI3dInvalidImageSize, [LImageSize, Length(ABytes)]);
  LImage := I3D_FILE_HEADER_SIZE;

  Move(ABytes[LImage], LDisk, SizeOf(TI3dDiskObject));
  CheckRange('the vertexes', LDisk.VerticesOffset, Int64(LDisk.VertexCount) * SizeOf(TI3dDiskVertex), LImageSize);
  CheckRange('the normals', LDisk.NormalsOffset, Int64(LDisk.NormalCount) * SizeOf(TI3dDiskNormal), LImageSize);
  CheckRange('the materials', LDisk.MaterialsOffset, Int64(LDisk.MaterialCount) * SizeOf(TI3dDiskMaterial), LImageSize);
  CheckRange('the faces', LDisk.FaceCacheOffset, 0, LImageSize);

  LHeader.VertexCount := LDisk.VertexCount;
  LHeader.NormalCount := LDisk.NormalCount;
  LHeader.FaceCount := LDisk.FaceCount;
  LHeader.FaceVertexCount := LDisk.FaceVertexCount;
  LHeader.MaterialCount := LDisk.MaterialCount;
  LHeader.Flags := LDisk.Flags;
  LHeader.ScaleX := LDisk.ScaleX;
  LHeader.ScaleY := LDisk.ScaleY;
  LHeader.ScaleZ := LDisk.ScaleZ;
  LHeader.CenterX := LDisk.CenterX;
  LHeader.CenterY := LDisk.CenterY;
  LHeader.CenterZ := LDisk.CenterZ;
  if LHeader.ScaleX = 0 then
    LHeader.ScaleX := I3D_DEFAULT_SCALE;
  if LHeader.ScaleY = 0 then
    LHeader.ScaleY := I3D_DEFAULT_SCALE;
  if LHeader.ScaleZ = 0 then
    LHeader.ScaleZ := I3D_DEFAULT_SCALE;

  SetLength(LVertices, LDisk.VertexCount);
  if LDisk.VertexCount > 0 then
    Move(ABytes[LImage + LDisk.VerticesOffset], LVertices[0], LDisk.VertexCount * SizeOf(TI3dDiskVertex));
  SetLength(LDiskMaterials, LDisk.MaterialCount);
  if LDisk.MaterialCount > 0 then
    Move(ABytes[LImage + LDisk.MaterialsOffset], LDiskMaterials[0], LDisk.MaterialCount * SizeOf(TI3dDiskMaterial));

  // the materials; a texture is numbered in the order of the materials that have one
  SetLength(LMaterials, LDisk.MaterialCount);
  SetLength(LTextures, 0);
  LTexturePosition := LImage + LImageSize;
  for LMaterial := 0 to LDisk.MaterialCount - 1 do
  begin
    LMaterials[LMaterial].Color := LDiskMaterials[LMaterial].Color;
    LMaterials[LMaterial].Flags := LDiskMaterials[LMaterial].Flags;
    LMaterials[LMaterial].Ambient := LDiskMaterials[LMaterial].Ambient;
    LMaterials[LMaterial].Diffuse := LDiskMaterials[LMaterial].Diffuse;
    LMaterials[LMaterial].Reflected := LDiskMaterials[LMaterial].Reflected;
    LMaterials[LMaterial].TextureName := LDiskMaterials[LMaterial].TextureName;
    LMaterials[LMaterial].TextureIndex := -1;
    if LDiskMaterials[LMaterial].TextureOffset = 0 then
      Continue;

    SetLength(LTextures, Length(LTextures) + 1);
    LMaterials[LMaterial].TextureIndex := High(LTextures);
    if LDiskMaterials[LMaterial].Flags and I3D_MATERIAL_WIDE <> 0 then
    begin
      LTextureSize := I3D_TEXTURE_SIZE_WIDE;
      LTextures[High(LTextures)].Width := 256;
    end
    else
    begin
      LTextureSize := I3D_TEXTURE_SIZE_NARROW;
      LTextures[High(LTextures)].Width := 64;
    end;
    LTextures[High(LTextures)].Height := 64;
    if LTexturePosition + LTextureSize > Length(ABytes) then
      raise EModelsException.CreateFmt(SModelsI3dTextureTruncated, [LMaterial]);
    SetLength(LTextures[High(LTextures)].Pixels, LTextureSize);
    Move(ABytes[LTexturePosition], LTextures[High(LTextures)].Pixels[0], LTextureSize);
    Inc(LTexturePosition, LTextureSize);
  end;

  // the faces: a header and its vertexes one after the other in the cache of the faces
  SetLength(LFaces, LDisk.FaceCount);
  LPosition := LDisk.FaceCacheOffset;
  for LFace := 0 to LDisk.FaceCount - 1 do
  begin
    CheckRange('the header of a face', LPosition, SizeOf(TI3dDiskFaceHeader), LImageSize);
    Move(ABytes[LImage + LPosition], LFaceHeader, SizeOf(TI3dDiskFaceHeader));
    Inc(LPosition, SizeOf(TI3dDiskFaceHeader));
    CheckRange('the vertexes of a face', LPosition, Int64(LFaceHeader.VertexCount) * SizeOf(TI3dDiskFaceVertex),
      LImageSize);

    LFaces[LFace].Visible := True;
    LFaces[LFace].Flags := LFaceHeader.Flags;
    LFaces[LFace].TextureOriginX := LFaceHeader.TextureOriginX;
    LFaces[LFace].TextureOriginY := LFaceHeader.TextureOriginY;
    LFaces[LFace].TextureScaleX := LFaceHeader.TextureScaleX;
    LFaces[LFace].TextureScaleY := LFaceHeader.TextureScaleY;
    LFaces[LFace].TextureAngle := LFaceHeader.TextureAngle;
    if LFaceHeader.MaterialOffset = 0 then
    begin
      LFaces[LFace].MaterialIndex := -1;
      LFaces[LFace].Color := 0;
    end
    else
    begin
      LFaces[LFace].MaterialIndex := IndexInPool(LFace, 'material', LFaceHeader.MaterialOffset,
        LDisk.MaterialsOffset, LDisk.MaterialCount, SizeOf(TI3dDiskMaterial));
      LFaces[LFace].Color := LMaterials[LFaces[LFace].MaterialIndex].Color;
    end;

    SetLength(LFaces[LFace].Vertices, LFaceHeader.VertexCount);
    for LCorner := 0 to LFaceHeader.VertexCount - 1 do
    begin
      Move(ABytes[LImage + LPosition], LFaceVertex, SizeOf(TI3dDiskFaceVertex));
      Inc(LPosition, SizeOf(TI3dDiskFaceVertex));
      LVertexIndex := IndexInPool(LFace, 'vertex', LFaceVertex.VertexOffset, LDisk.VerticesOffset,
        LDisk.VertexCount, SizeOf(TI3dDiskVertex));
      LFaces[LFace].Vertices[LCorner].X := LVertices[LVertexIndex].X;
      LFaces[LFace].Vertices[LCorner].Y := LVertices[LVertexIndex].Y;
      LFaces[LFace].Vertices[LCorner].Z := LVertices[LVertexIndex].Z;
      LFaces[LFace].Vertices[LCorner].TextureX := LFaceVertex.TextureX;
      LFaces[LFace].Vertices[LCorner].TextureY := LFaceVertex.TextureY;
      if LFaceVertex.NormalOffset = 0 then
        LFaces[LFace].Vertices[LCorner].NormalIndex := -1
      else
        LFaces[LFace].Vertices[LCorner].NormalIndex := IndexInPool(LFace, 'normal',
          LFaceVertex.NormalOffset, LDisk.NormalsOffset, LDisk.NormalCount, SizeOf(TI3dDiskNormal));
    end;
  end;

  Result := TI3dModel.Create(LHeader, LFaces, LMaterials, LTextures);
end;

end.

