{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the contracts of the I3D models             }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.Intf;

type
  /// <summary>
  ///   The data of an I3D model (OBJECT3D of Speed Haste): faces made of vertexes with their own
  ///   position, the materials, the textures of the file, and where the four tires of a car are.
  ///   The model keeps what the file says; how to draw it is up to II3dModelRenderer.
  /// </summary>
  II3dModel = interface
    ['{7B3E91C5-2A4D-4F68-B0E7-5D19C8A3F462}']
    function GetHeader: TI3dHeader;
    function GetFaceCount: Integer;
    /// <summary>
    ///   All the faces (the array belongs to the model: do not change it). The renderer reads it
    ///   once for the whole model, not once for each face.
    /// </summary>
    function GetFaces: TArray<TI3dFace>;
    function GetMaterialCount: Integer;
    function GetMaterial(const AIndex: Integer): TI3dMaterial;
    function GetTextureCount: Integer;
    function GetTexture(const AIndex: Integer): TI3dTexture;
    function GetHasTires: Boolean;
    /// <summary>The box of one of the four tires (0..3), zero if the model has no tires or fewer than 64 faces</summary>
    function GetTire(const AIndex: Integer): TI3dTireBox;
    /// <summary>The texture of a material as $FFBBGGRR pixels (the bytes in memory are R, G, B, A), for a texture of the GPU</summary>
    function TextureToRgba(const AIndex: Integer): TArray<Cardinal>;
    /// <summary>The first material whose texture has this name (the case counts), or -1</summary>
    function FindMaterialByTextureName(const AName: string): Integer;
    /// <summary>
    ///   Applies the corrections of the file .txt next to the model, in order: a vertex that moves,
    ///   a face that is hidden or shown, the color of a face. A correction that points outside the
    ///   model is ignored. The tires are measured again.
    /// </summary>
    procedure ApplyCorrections(const ACorrections: TArray<TI3dCorrection>);
    property Header: TI3dHeader read GetHeader;
    property FaceCount: Integer read GetFaceCount;
    property MaterialCount: Integer read GetMaterialCount;
    property Materials[const AIndex: Integer]: TI3dMaterial read GetMaterial;
    property TextureCount: Integer read GetTextureCount;
    property Textures[const AIndex: Integer]: TI3dTexture read GetTexture;
    property HasTires: Boolean read GetHasTires;
    property Tires[const AIndex: Integer]: TI3dTireBox read GetTire;
  end;

  /// <summary>Reads the bytes of an I3D file</summary>
  II3dParser = interface
    ['{2F68A0D4-91C7-4B3E-8A55-C4E7D0B19F36}']
    /// <summary>
    ///   Makes the model from the bytes of the file. Raises EModelsException if the file is not a
    ///   valid I3D (too short, wrong magic, an array or a reference outside the image, a texture
    ///   that is not in the file).
    /// </summary>
    function Parse(const ABytes: TBytes): II3dModel;
  end;

  /// <summary>Reads the text of the corrections of an I3D model</summary>
  II3dCorrectionReader = interface
    ['{B40D5E87-3C21-4A96-9F7B-62E8A1D05C39}']
    /// <summary>
    ///   The corrections of a text file in the order they are written; words before the first
    ///   "face" are skipped (and lines that start with //). Raises EModelsException if a
    ///   correction is not complete.
    /// </summary>
    function Parse(const AText: string): TArray<TI3dCorrection>;
  end;

  /// <summary>
  ///   Where an I3D model is drawn: the calls of IModelRenderer for the faces (a triangle fan for
  ///   each, with the colors, the matrices of the tires) and the choice of the texture. A texture
  ///   is the position in the textures of the model: the engine keeps the textures of the GPU.
  /// </summary>
  II3dRenderTarget = interface(IModelRenderer)
    ['{E1A7C3B9-5F02-4D84-B6A1-97C0D2E4F538}']
    /// <summary>Turns the texturing on or off (glEnable and glDisable of GL_TEXTURE_2D)</summary>
    procedure SetTexturing(const AEnabled: Boolean);
    /// <summary>Selects a texture of the model for the next faces</summary>
    procedure BindTexture(const ATextureIndex: Integer);
    /// <summary>The target forgets the texture it last used (the model changed it behind its back)</summary>
    procedure ResetTextureCache;
  end;

  /// <summary>Draws an I3D model on a target (the old RenderGL)</summary>
  II3dModelRenderer = interface
    ['{6C92F3A8-D157-4E0B-8B43-A5F7E1C90D26}']
    /// <summary>
    ///   Sends the faces of the model to the target: the vertexes in the placement, the faces
    ///   that are hidden or equal to ASelectedFace (-1 for none) skipped, the first 64 faces of a
    ///   car turned as the tire state says. Gives the number of triangles drawn.
    /// </summary>
    function Render(const AModel: II3dModel; const ATarget: II3dRenderTarget;
      const APlacement: TModelPlacement; const ASelectedFace: Integer;
      const ATires: TI3dTireState): Integer;
  end;

  /// <summary>
  ///   A target that keeps what is drawn instead of drawing it: the faces of a model become
  ///   triangles, with the matrices already applied, grouped by texture and color. The adapter of
  ///   a graphics API (or a software rasterizer) draws the batches with no knowledge of the format
  ///   of the models.
  /// </summary>
  II3dMeshBuilder = interface(II3dRenderTarget)
    ['{9D4F1B62-A735-4C08-8E21-3B6A0F5D7C94}']
    function GetBatchCount: Integer;
    function GetBatch(const AIndex: Integer): TI3dMeshBatch;
    function GetTriangleCount: Integer;
    /// <summary>Forgets the batches, the matrices and the state: ready for another model</summary>
    procedure Clear;
    property BatchCount: Integer read GetBatchCount;
    /// <summary>The batches in the order in which they were opened; EModelsException for a wrong index</summary>
    property Batches[const AIndex: Integer]: TI3dMeshBatch read GetBatch;
    /// <summary>The triangles of all the batches</summary>
    property TriangleCount: Integer read GetTriangleCount;
  end;

implementation

end.
