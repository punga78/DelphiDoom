{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - an I3D file made in memory     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.I3dFileBuilder;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  /// <summary>A vertex of a face of the file to build</summary>
  TI3dBuilderCorner = record
    VertexIndex: Integer;
    /// <summary>-1 for no normal</summary>
    NormalIndex: Integer;
    TextureX: Integer;
    TextureY: Integer;
  end;

  /// <summary>
  ///   Writes the bytes of an I3D file from a short description: the same file for the old loader
  ///   (the temporary harness) and for the library, so the golden files cover cases that the
  ///   shareware does not have (tires, wide textures, a scale of zero). The layout is the one of
  ///   the game: the object, the vertexes, the normals, the materials, the cache of the faces,
  ///   then the pixels of the textures. The offsets are relative to the start of the image.
  /// </summary>
  TI3dFileBuilder = class
  strict private
    type
      TMaterialSpec = record
        Color: Byte;
        Flags: Word;
        Name: AnsiString;
        TextureSeed: Integer;
        HasTexture: Boolean;
      end;
      TFaceSpec = record
        MaterialIndex: Integer;
        Flags: Cardinal;
        Corners: TArray<TI3dBuilderCorner>;
      end;
  strict private
    FVertices: TList<TArray<Integer>>;
    FNormals: TList<TArray<Integer>>;
    FMaterials: TList<TMaterialSpec>;
    FFaces: TList<TFaceSpec>;
    FFlags: Word;
    FScale: array[0..2] of Integer;
    FCenter: array[0..2] of Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function AddVertex(const AX, AY, AZ: Integer): Integer;
    function AddNormal(const AX, AY, AZ: Integer): Integer;
    /// <summary>A material; with ATextureSeed >= 0 the file holds a texture of pixels made from the seed</summary>
    function AddMaterial(const AColor: Byte; const AFlags: Word; const AName: AnsiString;
      const ATextureSeed: Integer): Integer;
    /// <summary>A face made of the corners, with AMaterialIndex -1 for none</summary>
    procedure AddFace(const AMaterialIndex: Integer; const AFlags: Cardinal;
      const ACorners: array of TI3dBuilderCorner);
    class function Corner(const AVertexIndex, ANormalIndex, ATextureX, ATextureY: Integer): TI3dBuilderCorner; static;
    procedure SetObjectFlags(const AFlags: Word);
    procedure SetScale(const AX, AY, AZ: Integer);
    procedure SetCenter(const AX, AY, AZ: Integer);
    function Build: TBytes;
    /// <summary>Two materials (flat and textured) and three faces: a triangle, a quad and a face with no vertexes</summary>
    class function SmallModel: TBytes; static;
    /// <summary>A car: 64 faces for the four tires (16 each), a body of 6 faces, one wide texture and one narrow; scale 0</summary>
    class function CarModel: TBytes; static;
    /// <summary>A model with 70 faces and no tire flag, a translucent material, scale and center</summary>
    class function PlainModel: TBytes; static;
  end;

implementation

{ TI3dFileBuilder }

constructor TI3dFileBuilder.Create;
begin
  inherited Create;
  FVertices := TList<TArray<Integer>>.Create;
  FNormals := TList<TArray<Integer>>.Create;
  FMaterials := TList<TMaterialSpec>.Create;
  FFaces := TList<TFaceSpec>.Create;
end;

destructor TI3dFileBuilder.Destroy;
begin
  FFaces.Free;
  FMaterials.Free;
  FNormals.Free;
  FVertices.Free;
  inherited Destroy;
end;

function TI3dFileBuilder.AddVertex(const AX, AY, AZ: Integer): Integer;
begin
  Result := FVertices.Add([AX, AY, AZ]);
end;

function TI3dFileBuilder.AddNormal(const AX, AY, AZ: Integer): Integer;
begin
  Result := FNormals.Add([AX, AY, AZ]);
end;

function TI3dFileBuilder.AddMaterial(const AColor: Byte; const AFlags: Word; const AName: AnsiString;
  const ATextureSeed: Integer): Integer;
var
  LSpec: TMaterialSpec;
begin
  LSpec.Color := AColor;
  LSpec.Flags := AFlags;
  LSpec.Name := AName;
  LSpec.TextureSeed := ATextureSeed;
  LSpec.HasTexture := ATextureSeed >= 0;
  Result := FMaterials.Add(LSpec);
end;

class function TI3dFileBuilder.Corner(const AVertexIndex, ANormalIndex, ATextureX,
  ATextureY: Integer): TI3dBuilderCorner;
begin
  Result.VertexIndex := AVertexIndex;
  Result.NormalIndex := ANormalIndex;
  Result.TextureX := ATextureX;
  Result.TextureY := ATextureY;
end;

procedure TI3dFileBuilder.AddFace(const AMaterialIndex: Integer; const AFlags: Cardinal;
  const ACorners: array of TI3dBuilderCorner);
var
  LSpec: TFaceSpec;
  LIndex: Integer;
begin
  LSpec.MaterialIndex := AMaterialIndex;
  LSpec.Flags := AFlags;
  SetLength(LSpec.Corners, Length(ACorners));
  for LIndex := 0 to High(ACorners) do
    LSpec.Corners[LIndex] := ACorners[LIndex];
  FFaces.Add(LSpec);
end;

procedure TI3dFileBuilder.SetObjectFlags(const AFlags: Word);
begin
  FFlags := AFlags;
end;

procedure TI3dFileBuilder.SetScale(const AX, AY, AZ: Integer);
begin
  FScale[0] := AX;
  FScale[1] := AY;
  FScale[2] := AZ;
end;

procedure TI3dFileBuilder.SetCenter(const AX, AY, AZ: Integer);
begin
  FCenter[0] := AX;
  FCenter[1] := AY;
  FCenter[2] := AZ;
end;

function TI3dFileBuilder.Build: TBytes;
const
  OBJECT_SIZE = 60;
  VERTEX_SIZE = 36;
  NORMAL_SIZE = 28;
  MATERIAL_SIZE = 28;
  FACE_HEADER_SIZE = 48;
  FACE_VERTEX_SIZE = 20;
var
  LImage: TBytes;
  LVerticesOffset, LNormalsOffset, LMaterialsOffset, LCacheOffset, LCachePosition: Integer;
  LCornerCount: Integer;
  LIndex, LCorner, LPixel: Integer;
  LFace: TFaceSpec;
  LMaterial: TMaterialSpec;
  LPosition: Integer;
  LNameIndex: Integer;
  LTextures: TBytes;
  LTextureSize, LTextureBase: Integer;
  LImageSize: Integer;

  procedure PutWord(const AOffset: Integer; const AValue: Word);
  begin
    LImage[AOffset] := AValue and $FF;
    LImage[AOffset + 1] := AValue shr 8;
  end;

  procedure PutInt(const AOffset: Integer; const AValue: Integer);
  begin
    PutWord(AOffset, Word(AValue and $FFFF));
    PutWord(AOffset + 2, Word((Cardinal(AValue) shr 16) and $FFFF));
  end;

begin
  LCornerCount := 0;
  for LFace in FFaces do
    Inc(LCornerCount, Length(LFace.Corners));

  LVerticesOffset := OBJECT_SIZE;
  LNormalsOffset := LVerticesOffset + FVertices.Count * VERTEX_SIZE;
  LMaterialsOffset := LNormalsOffset + FNormals.Count * NORMAL_SIZE;
  LCacheOffset := LMaterialsOffset + FMaterials.Count * MATERIAL_SIZE;
  SetLength(LImage, LCacheOffset + FFaces.Count * FACE_HEADER_SIZE + LCornerCount * FACE_VERTEX_SIZE);

  PutWord(0, FVertices.Count);
  PutWord(2, FNormals.Count);
  PutWord(4, FFaces.Count);
  PutWord(6, LCornerCount);
  PutWord(8, FMaterials.Count);
  PutWord(10, FFlags);
  PutInt(12, LVerticesOffset);
  PutInt(16, LNormalsOffset);
  PutInt(20, LCacheOffset);
  PutInt(24, LMaterialsOffset);
  PutInt(28, 0);
  PutInt(32, 0);
  PutInt(36, FScale[0]);
  PutInt(40, FScale[1]);
  PutInt(44, FScale[2]);
  PutInt(48, FCenter[0]);
  PutInt(52, FCenter[1]);
  PutInt(56, FCenter[2]);

  for LIndex := 0 to FVertices.Count - 1 do
  begin
    PutInt(LVerticesOffset + LIndex * VERTEX_SIZE, FVertices[LIndex][0]);
    PutInt(LVerticesOffset + LIndex * VERTEX_SIZE + 4, FVertices[LIndex][1]);
    PutInt(LVerticesOffset + LIndex * VERTEX_SIZE + 8, FVertices[LIndex][2]);
    // the run-time numbers of the old renderer are left as the tools wrote them: not zero
    PutInt(LVerticesOffset + LIndex * VERTEX_SIZE + 12, LIndex);
  end;
  for LIndex := 0 to FNormals.Count - 1 do
  begin
    PutInt(LNormalsOffset + LIndex * NORMAL_SIZE, FNormals[LIndex][0]);
    PutInt(LNormalsOffset + LIndex * NORMAL_SIZE + 4, FNormals[LIndex][1]);
    PutInt(LNormalsOffset + LIndex * NORMAL_SIZE + 8, FNormals[LIndex][2]);
  end;

  LTextureBase := 0;
  SetLength(LTextures, 0);
  for LIndex := 0 to FMaterials.Count - 1 do
  begin
    LMaterial := FMaterials[LIndex];
    LPosition := LMaterialsOffset + LIndex * MATERIAL_SIZE;
    LImage[LPosition] := LMaterial.Color;
    LImage[LPosition + 1] := $FF; // the identifier the loader of the game wrote: never read
    PutWord(LPosition + 2, LMaterial.Flags);
    PutInt(LPosition + 4, 100 + LIndex);
    PutInt(LPosition + 8, 200 + LIndex);
    PutInt(LPosition + 12, 300 + LIndex);
    for LNameIndex := 1 to 8 do
      if LNameIndex <= Length(LMaterial.Name) then
        LImage[LPosition + 15 + LNameIndex] := Byte(LMaterial.Name[LNameIndex])
      else
        LImage[LPosition + 15 + LNameIndex] := 0;
    if LMaterial.HasTexture then
    begin
      // the value is only a flag for the loader
      PutInt(LPosition + 24, $12345678);
      if LMaterial.Flags and $0008 <> 0 then
        LTextureSize := 256 * 64
      else
        LTextureSize := 64 * 64;
      SetLength(LTextures, LTextureBase + LTextureSize);
      for LPixel := 0 to LTextureSize - 1 do
        LTextures[LTextureBase + LPixel] := Byte((LPixel * 7 + LMaterial.TextureSeed * 31 + (LPixel shr 6)) and $FF);
      Inc(LTextureBase, LTextureSize);
    end;
  end;

  LCachePosition := LCacheOffset;
  for LFace in FFaces do
  begin
    PutWord(LCachePosition, 1);
    PutWord(LCachePosition + 2, Length(LFace.Corners));
    PutInt(LCachePosition + 4, Integer(LFace.Flags));
    if LFace.MaterialIndex >= 0 then
      PutInt(LCachePosition + 8, LMaterialsOffset + LFace.MaterialIndex * MATERIAL_SIZE);
    PutInt(LCachePosition + 12, 11);
    PutInt(LCachePosition + 16, 12);
    PutInt(LCachePosition + 20, 13);
    PutInt(LCachePosition + 24, 14);
    PutInt(LCachePosition + 28, 15);
    Inc(LCachePosition, FACE_HEADER_SIZE);
    for LCorner := 0 to High(LFace.Corners) do
    begin
      PutInt(LCachePosition, LVerticesOffset + LFace.Corners[LCorner].VertexIndex * VERTEX_SIZE);
      if LFace.Corners[LCorner].NormalIndex >= 0 then
        PutInt(LCachePosition + 4, LNormalsOffset + LFace.Corners[LCorner].NormalIndex * NORMAL_SIZE);
      PutInt(LCachePosition + 12, LFace.Corners[LCorner].TextureX);
      PutInt(LCachePosition + 16, LFace.Corners[LCorner].TextureY);
      Inc(LCachePosition, FACE_VERTEX_SIZE);
    end;
  end;

  SetLength(Result, 8 + Length(LImage) + Length(LTextures));
  Result[0] := $42;
  Result[1] := $33;
  Result[2] := $44;
  Result[3] := 0;
  LImageSize := Length(LImage);
  Move(LImageSize, Result[4], 4);
  Move(LImage[0], Result[8], Length(LImage));
  if Length(LTextures) > 0 then
    Move(LTextures[0], Result[8 + Length(LImage)], Length(LTextures));
end;

class function TI3dFileBuilder.SmallModel: TBytes;
var
  LBuilder: TI3dFileBuilder;
  LFlat, LTextured: Integer;
begin
  LBuilder := TI3dFileBuilder.Create;
  try
    LBuilder.SetScale(0, 0, 0);
    LBuilder.AddVertex(0, 0, 0);
    LBuilder.AddVertex(1000000, 0, 0);
    LBuilder.AddVertex(1000000, 2000000, 0);
    LBuilder.AddVertex(0, 2000000, 500000);
    LBuilder.AddVertex(-300000, -400000, 600000);
    LBuilder.AddNormal(0, 0, 65536);
    LBuilder.AddNormal(0, 65536, 0);
    LFlat := LBuilder.AddMaterial(12, 0, 'FLAT', -1);
    LTextured := LBuilder.AddMaterial(40, $0004, 'ROAD', 3);
    LBuilder.AddFace(LFlat, 1, [Corner(0, 0, 0, 0), Corner(1, 0, 16777216, 0), Corner(2, 1, 16777216, 16777216)]);
    LBuilder.AddFace(LTextured, 0, [Corner(0, -1, 0, 0), Corner(1, 0, 4194304, 0), Corner(2, 1, 4194304, 4194304),
      Corner(3, 1, 0, 4194304)]);
    LBuilder.AddFace(LTextured, 2, []);
    LBuilder.AddFace(LFlat, 4, [Corner(4, 0, -5, 7), Corner(3, 1, 11, -13), Corner(0, 1, 17, 19)]);
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

class function TI3dFileBuilder.CarModel: TBytes;
var
  LBuilder: TI3dFileBuilder;
  LBody, LTextured, LWide, LTrans: Integer;
  LTire, LFace, LBase: Integer;
  LCenterX, LCenterZ: Integer;
begin
  LBuilder := TI3dFileBuilder.Create;
  try
    LBuilder.SetObjectFlags(1);
    LBuilder.SetScale(0, 3000000, 0);
    LBuilder.SetCenter(100, -200, 300);
    LBody := LBuilder.AddMaterial(77, 0, '', -1);
    LTextured := LBuilder.AddMaterial(1, 0, 'LIVERY', 5);
    LWide := LBuilder.AddMaterial(2, $0008, 'WIDE', 9);
    LTrans := LBuilder.AddMaterial(200, $0002, '', -1);
    LBuilder.AddNormal(0, 65536, 0);
    for LTire := 0 to 3 do
    begin
      if LTire mod 2 = 0 then
        LCenterX := -900000
      else
        LCenterX := 900000;
      if LTire < 2 then
        LCenterZ := 1500000
      else
        LCenterZ := -1500000;
      for LFace := 0 to 15 do
      begin
        LBase := LBuilder.AddVertex(LCenterX + (LFace mod 4) * 20000, -300000 + LFace * 40000 + LTire * 111,
          LCenterZ + LFace * 5000);
        LBuilder.AddVertex(LCenterX + 60000, 300000 - LFace * 35000, LCenterZ - LFace * 4000 + LTire);
        LBuilder.AddVertex(LCenterX - 70000, LFace * 17000 - 100000, LCenterZ + 90000);
        LBuilder.AddFace(LBody, 0, [Corner(LBase, 0, 0, 0), Corner(LBase + 1, 0, 100, 200),
          Corner(LBase + 2, -1, 300, 400)]);
      end;
    end;
    for LFace := 0 to 5 do
    begin
      LBase := LBuilder.AddVertex(-800000 + LFace * 1000, 100000, -2000000);
      LBuilder.AddVertex(800000, 100000 + LFace * 7000, -2000000);
      LBuilder.AddVertex(800000, 400000, 2000000 - LFace * 3000);
      LBuilder.AddVertex(-800000, 400000, 2000000);
      case LFace mod 3 of
        0: LBuilder.AddFace(LTextured, 0, [Corner(LBase, 0, 0, 0), Corner(LBase + 1, 0, 8388608, 0),
             Corner(LBase + 2, 0, 8388608, 8388608), Corner(LBase + 3, 0, 0, 8388608)]);
        1: LBuilder.AddFace(LWide, 1, [Corner(LBase, 0, 0, 0), Corner(LBase + 1, 0, 33554432, 0),
             Corner(LBase + 2, 0, 33554432, 8388608), Corner(LBase + 3, 0, 0, 8388608)]);
      else
        LBuilder.AddFace(LTrans, 4, [Corner(LBase, 0, 1, 2), Corner(LBase + 1, 0, 3, 4), Corner(LBase + 2, 0, 5, 6)]);
      end;
    end;
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

class function TI3dFileBuilder.PlainModel: TBytes;
var
  LBuilder: TI3dFileBuilder;
  LMaterial, LTrans: Integer;
  LFace, LBase: Integer;
begin
  LBuilder := TI3dFileBuilder.Create;
  try
    // 70 faces but no tire flag: the tires are not measured and not turned
    LBuilder.SetScale(2000000, 1000000, 500000);
    LBuilder.SetCenter(-50, 60, -70);
    LMaterial := LBuilder.AddMaterial(33, 0, 'PLAIN', -1);
    LTrans := LBuilder.AddMaterial(34, 2, 'GLASS', -1);
    for LFace := 0 to 69 do
    begin
      LBase := LBuilder.AddVertex(LFace * 1000, LFace * 2000 - 7, -LFace * 300);
      LBuilder.AddVertex(LFace * 1000 + 500, LFace * 2000 + 100, LFace);
      LBuilder.AddVertex(LFace * 1000 - 400, LFace * 2000 + 900, LFace * 3);
      if LFace mod 2 = 0 then
        LBuilder.AddFace(LMaterial, 0, [Corner(LBase, -1, 1, 1), Corner(LBase + 1, -1, 2, 2), Corner(LBase + 2, -1, 3, 3)])
      else
        LBuilder.AddFace(LTrans, 0, [Corner(LBase, -1, 1, 1), Corner(LBase + 1, -1, 2, 2), Corner(LBase + 2, -1, 3, 3)]);
    end;
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

end.
