{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the I3D types (Speed Haste)                 }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of OPENGL\i3d_structs.pas of Speed. The format is OBJECT3D of Iguana   }
{  (Jare and JCAB, 1995): a memory image of the object where the pointers are  }
{  offsets from the start of the image.                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The first four bytes of an I3D file: "B3D" and a zero byte</summary>
  I3D_MAGIC = $443342;
  /// <summary>The scale of an object that does not give one (the application default of the old loader)</summary>
  I3D_DEFAULT_SCALE = 256 * 2048;
  /// <summary>The unit of the texture points: 262144 * 64 (the old UVGLCONST)</summary>
  I3D_UV_CONSTANT = 262144 * 64;
  /// <summary>The characters of the name of the texture of a material</summary>
  I3D_TEXTURE_NAME_SIZE = 8;
  /// <summary>The size in bytes of a texture of 64x64 pixels (one byte of palette each)</summary>
  I3D_TEXTURE_SIZE_NARROW = 64 * 64;
  /// <summary>The size in bytes of a texture of 256x64 pixels (material flag I3D_MATERIAL_WIDE)</summary>
  I3D_TEXTURE_SIZE_WIDE = 256 * 64;
  /// <summary>How many faces make the four tires of a car: the first 64, 16 for each tire</summary>
  I3D_TIRE_FACE_COUNT = 64;
  /// <summary>How many faces make one tire</summary>
  I3D_FACES_PER_TIRE = 16;

  /// <summary>Object flag: the first 64 faces are the four tires of a car (they turn)</summary>
  I3D_OBJECT_HAS_TIRES = $0001;

  // Material flags
  /// <summary>Do not apply any lighting</summary>
  I3D_MATERIAL_NO_SHADE = $0001;
  /// <summary>Translucent</summary>
  I3D_MATERIAL_TRANSLUCENT = $0002;
  /// <summary>The color 0 of the texture is transparent</summary>
  I3D_MATERIAL_HOLES = $0004;
  /// <summary>The texture is 256 pixels wide</summary>
  I3D_MATERIAL_WIDE = $0008;

  // Face flags
  /// <summary>The face is flat shaded (the normal of the first vertex)</summary>
  I3D_FACE_FLAT = $0001;
  /// <summary>The face is drawn before the others</summary>
  I3D_FACE_FIRST = $0002;
  /// <summary>The face is always visible</summary>
  I3D_FACE_ALWAYS_VISIBLE = $0004;

  /// <summary>The primitive of a face for the renderer: the number of GL_TRIANGLE_FAN</summary>
  I3D_PRIMITIVE_TRIANGLE_FAN = 6;

  /// <summary>The size in bytes of the header of an I3D file: the magic and the size of the image</summary>
  I3D_FILE_HEADER_SIZE = 8;

resourcestring
  SModelsI3dInvalidIndex = 'The item %d of the I3D model does not exist';
  SModelsI3dTooShort ='The I3D model is too short (%d bytes)';
  SModelsI3dInvalidMagic = 'Invalid I3D model magic (%d)!';
  SModelsI3dInvalidImageSize = 'The I3D model has an image of %d bytes in a file of %d';
  SModelsI3dOutside = 'The I3D model is truncated: %s is outside the image (offset %d, size %d)';
  SModelsI3dInvalidReference = 'The face %d of the I3D model uses the %s at %d, that does not exist';
  SModelsI3dTextureTruncated = 'The I3D model is truncated: the texture of the material %d is not in the file';
  SModelsI3dMeshStackEmpty = 'The matrix stack of the I3D mesh is empty: PopMatrix without PushMatrix';
  SModelsI3dCorrectionText ='Invalid I3D corrections: expected %s near "%s"';

type
  /// <summary>The name of the texture of a material, as the bytes of the file</summary>
  TI3dTextureName = array[0..I3D_TEXTURE_NAME_SIZE - 1] of AnsiChar;

  /// <summary>A vertex or a normal on disk: three integers (O3DF_TVertex), 12 bytes</summary>
  TI3dDiskVector = packed record
    X: Integer;
    Y: Integer;
    Z: Integer;
  end;

  /// <summary>
  ///   The object as it is on disk (the start of the image), 60 bytes, little endian. The five
  ///   offsets that were pointers are 32 bit offsets from the start of the image; at 32 and 64 bit
  ///   the file is the same, so the record has no pointers.
  /// </summary>
  TI3dDiskObject = packed record
    VertexCount: Word;
    NormalCount: Word;
    FaceCount: Word;
    FaceVertexCount: Word;
    MaterialCount: Word;
    Flags: Word;
    VerticesOffset: Cardinal;
    NormalsOffset: Cardinal;
    FaceCacheOffset: Cardinal;
    MaterialsOffset: Cardinal;
    /// <summary>The position of the object (0 = the default): never used by the game</summary>
    PositionOffset: Cardinal;
    /// <summary>The angles of the object (0 = the default): never used by the game</summary>
    RotationOffset: Cardinal;
    ScaleX: Integer;
    ScaleY: Integer;
    ScaleZ: Integer;
    CenterX: Integer;
    CenterY: Integer;
    CenterZ: Integer;
  end;

  /// <summary>
  ///   A vertex of the image (O3DM_TVertex): the position and six numbers that the old renderer
  ///   calculated at run time (rotated position, screen position, light), 36 bytes
  /// </summary>
  TI3dDiskVertex = packed record
    X: Integer;
    Y: Integer;
    Z: Integer;
    RotatedX: Integer;
    RotatedY: Integer;
    RotatedZ: Integer;
    ScreenX: Integer;
    ScreenY: Integer;
    Light: Integer;
  end;

  /// <summary>A normal of the image (O3DM_TNormal), 28 bytes</summary>
  TI3dDiskNormal = packed record
    X: Integer;
    Y: Integer;
    Z: Integer;
    RotatedX: Integer;
    RotatedY: Integer;
    RotatedZ: Integer;
    Light: Integer;
  end;

  /// <summary>
  ///   A material of the image (O3DM_TMaterial), 28 bytes. The name of the texture is empty for a
  ///   flat color; TextureOffset is not zero when the pixels of the texture follow the image in the
  ///   file (the value itself is never used as an offset).
  /// </summary>
  TI3dDiskMaterial = packed record
    Color: Byte;
    /// <summary>Used by the old loader at run time (the index of the texture)</summary>
    TextureIdentifier: ShortInt;
    Flags: Word;
    Ambient: Integer;
    Diffuse: Integer;
    Reflected: Integer;
    TextureName: TI3dTextureName;
    TextureOffset: Cardinal;
  end;

  /// <summary>
  ///   The header of a face in the cache of the faces (O3DM_TFaceHeader), 48 bytes. The vertexes of
  ///   the face (TI3dDiskFaceVertex) follow it.
  /// </summary>
  TI3dDiskFaceHeader = packed record
    Visible: Word;
    VertexCount: Word;
    Flags: Cardinal;
    MaterialOffset: Cardinal;
    TextureOriginX: Integer;
    TextureOriginY: Integer;
    TextureScaleX: Integer;
    TextureScaleY: Integer;
    TextureAngle: Integer;
    BackOffset: Cardinal;
    FrontOffset: Cardinal;
    Depth: Integer;
    NextOffset: Cardinal;
  end;

  /// <summary>A vertex of a face (O3DM_TFaceVertex), 20 bytes: where the position and the normal are in the image, the light and the texture point</summary>
  TI3dDiskFaceVertex = packed record
    VertexOffset: Cardinal;
    NormalOffset: Cardinal;
    Light: Integer;
    TextureX: Integer;
    TextureY: Integer;
  end;

  /// <summary>The numbers of the header of an object that the renderer needs</summary>
  TI3dHeader = record
    VertexCount: Integer;
    NormalCount: Integer;
    FaceCount: Integer;
    FaceVertexCount: Integer;
    MaterialCount: Integer;
    Flags: Integer;
    /// <summary>Scale factors: the file value, or I3D_DEFAULT_SCALE when the file has 0</summary>
    ScaleX: Integer;
    ScaleY: Integer;
    ScaleZ: Integer;
    CenterX: Integer;
    CenterY: Integer;
    CenterZ: Integer;
  end;

  /// <summary>A material of a model. TextureIndex is the position in the textures of the model, or -1</summary>
  TI3dMaterial = record
    Color: Byte;
    Flags: Word;
    Ambient: Integer;
    Diffuse: Integer;
    Reflected: Integer;
    TextureName: TI3dTextureName;
    TextureIndex: Integer;
  end;

  /// <summary>A texture of a model: the pixels are indexes of the palette of the model</summary>
  TI3dTexture = record
    Width: Integer;
    Height: Integer;
    Pixels: TBytes;
  end;

  /// <summary>A vertex of a face: its own copy of the position (a correction moves one vertex of one face) and the texture point</summary>
  TI3dFaceVertex = record
    X: Integer;
    Y: Integer;
    Z: Integer;
    /// <summary>The normal of the model at this vertex, or -1</summary>
    NormalIndex: Integer;
    TextureX: Integer;
    TextureY: Integer;
  end;

  /// <summary>
  ///   A face of a model. MaterialIndex is -1 when the face has no material (the old loader
  ///   stopped on it). Color is the palette color of the material of this face (a correction can
  ///   change it for one face only).
  /// </summary>
  TI3dFace = record
    Visible: Boolean;
    Flags: Cardinal;
    MaterialIndex: Integer;
    Color: Byte;
    TextureOriginX: Integer;
    TextureOriginY: Integer;
    TextureScaleX: Integer;
    TextureScaleY: Integer;
    TextureAngle: Integer;
    Vertices: TArray<TI3dFaceVertex>;
  end;

  /// <summary>
  ///   A correction of a vertex of a face (the file .txt next to the model: "face 3 vertex 1
  ///   visible 1 x 0 y 0 z 0 tx 0 ty 0 color 5")
  /// </summary>
  TI3dCorrection = record
    Face: Integer;
    Vertex: Integer;
    Visible: Boolean;
    X: Integer;
    Y: Integer;
    Z: Integer;
    TextureX: Integer;
    TextureY: Integer;
    Color: Byte;
  end;

  /// <summary>The state of the four tires of a car when the model is drawn: the rotation of each (degrees) and the steering angle of the front ones</summary>
  TI3dTireState = record
    Rotation: array[0..3] of Single;
    Angle: Single;
  end;

  /// <summary>The center and the size of a tire (the box of its 16 faces), in the units of the file</summary>
  TI3dTireBox = record
    CenterX: Integer;
    CenterY: Integer;
    CenterZ: Integer;
    /// <summary>The height of the box (the old "perimeter")</summary>
    Perimeter: Integer;
  end;

  /// <summary>A color of the palette of the models as three numbers from 0 to 1</summary>
  TI3dColor3f = record
    R: Single;
    G: Single;
    B: Single;
  end;

  /// <summary>
  ///   A vertex of a model ready to be drawn: the position after the matrices (the turning of the
  ///   tires included) and the point of the texture. 20 bytes, the layout of a vertex array
  /// </summary>
  TI3dMeshVertex = packed record
    X: Single;
    Y: Single;
    Z: Single;
    U: Single;
    V: Single;
  end;

  /// <summary>
  ///   The triangles of a model that are drawn with the same state: three vertexes for a triangle,
  ///   one texture (the position in the textures of the model) or none, one color
  /// </summary>
  TI3dMeshBatch = record
    Textured: Boolean;
    /// <summary>-1 when the batch has no texture</summary>
    TextureIndex: Integer;
    Red: Single;
    Green: Single;
    Blue: Single;
    Alpha: Single;
    Vertices: TArray<TI3dMeshVertex>;
  end;

implementation

end.

