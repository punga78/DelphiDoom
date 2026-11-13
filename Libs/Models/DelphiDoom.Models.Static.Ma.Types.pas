{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: Maya ASCII (MA), the types  }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_ma.h.     }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This unit }
{  is derived from the Doom 3 GPL source code and is therefore available       }
{  under the GNU General Public License, version 3, with the additional terms  }
{  of the Doom 3 Source Code License (see README.md of Libs\IdLib); the        }
{  repository as a whole is GPL v2 or later.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Ma.Types;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4;

type
  /// <summary>maTransform_t: the transform of a group of objects; the parent is a reference (the model owns all)</summary>
  TMaTransform = class
  public
    Translate: TIdVec3;
    Rotate: TIdVec3;
    Scale: TIdVec3;
    Parent: TMaTransform;
  end;

  /// <summary>maFace_t: a triangle with edge, vertex, texture, colour and normal indexes</summary>
  TMaFace = record
    Edge: array[0..2] of Integer;
    VertexNum: array[0..2] of Integer;
    TVertexNum: array[0..2] of Integer;
    VertexColors: array[0..2] of Integer;
    VertexNormals: array[0..2] of TIdVec3;
  end;

  /// <summary>maMesh_t: what a mesh node gives; an array that was never given is empty</summary>
  TMaMesh = record
    Transform: TMaTransform;
    Vertexes: TArray<TIdVec3>;
    /// <summary>The offsets of "pt" (xyz) with the index of the vertex in W</summary>
    VertTransforms: TArray<TIdVec4>;
    NextVertTransformIndex: Integer;
    TVertexes: TArray<TIdVec2>;
    /// <summary>Per edge: the first and second vertex in X and Y, 1 in Z when the edge is shared by smooth normals</summary>
    Edges: TArray<TIdVec3>;
    /// <summary>Four bytes (RGBA) for every colour</summary>
    Colors: TArray<Byte>;
    Faces: TArray<TMaFace>;
    Normals: TArray<TIdVec3>;
    NormalsParsed: Boolean;
    NextNormal: Integer;
    /// <summary>The data was given by a header (the original tests the pointer, not the size)</summary>
    HasVertexes: Boolean;
    HasVertTransforms: Boolean;
    HasTVertexes: Boolean;
    HasEdges: Boolean;
    HasColors: Boolean;
    HasFaces: Boolean;
    HasNormals: Boolean;
  end;

  /// <summary>maObject_t: a mesh node with the name of its material</summary>
  TMaObject = class
  public
    Name: AnsiString;
    /// <summary>The index in the materials of the model, -1 if none</summary>
    MaterialRef: Integer;
    MaterialName: AnsiString;
    Mesh: TMaMesh;
  end;

  /// <summary>maFileNode_t: a "file" node with the path of the picture</summary>
  TMaFileNode = class
  public
    Name: AnsiString;
    Path: AnsiString;
  end;

  /// <summary>maMaterialNode_t: a shading node; it leads to a file through its child nodes</summary>
  TMaMaterialNode = class
  public
    Name: AnsiString;
    Child: TMaMaterialNode;
    FileNode: TMaFileNode;
  end;

  /// <summary>
  ///   maModel_t: the objects, the materials found (the path of the picture, as the engine names
  ///   it) and the nodes that were read. It owns the transforms and the nodes.
  /// </summary>
  TMaModel = class
  strict private
    FTimeStamp: Int64;
    FMaterials: TList<AnsiString>;
    FObjects: TObjectList<TMaObject>;
    FTransforms: TDictionary<AnsiString, TMaTransform>;
    FFileNodes: TDictionary<AnsiString, TMaFileNode>;
    FMaterialNodes: TDictionary<AnsiString, TMaMaterialNode>;
    FOwned: TObjectList<TObject>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Gives a node to the model: it frees it with the model (a node that is replaced in a table stays alive, as in the original)</summary>
    function Own<T: class>(const AItem: T): T;
    property TimeStamp: Int64 read FTimeStamp write FTimeStamp;
    property Materials: TList<AnsiString> read FMaterials;
    property Objects: TObjectList<TMaObject> read FObjects;
    property Transforms: TDictionary<AnsiString, TMaTransform> read FTransforms;
    property FileNodes: TDictionary<AnsiString, TMaFileNode> read FFileNodes;
    property MaterialNodes: TDictionary<AnsiString, TMaMaterialNode> read FMaterialNodes;
  end;

resourcestring
  SMaInvalidVec3 = 'Maya Loader ''%s'': Invalid Vec3';
  SMaNotTriangle = 'Maya Loader ''%s'': Face is not a triangle.';
  SMaInvalidTexCoords = 'Maya Loader ''%s'': Invalid texture coordinates.';
  SMaInvalidColor = 'Maya Loader ''%s'': Invalid vertex color.';
  SMaInvalidNormals = 'Maya Loader ''%s'': Invalid Normals Index.';
  SMaInvalidConnect = 'Maya Loader ''%s'': Invalid Connect Attribute.';
  SMaIndexRange = 'Maya Loader ''%s'': %s index %d out of range (%d)';
  SMaNoObjects = 'MA: the model has no objects';
  SMaBadVertex = 'ConvertMAToModelSurfaces: bad vertex index in MA file %s';
  SMaBadTexCoord = 'ConvertMAToModelSurfaces: bad tex coord index in MA file %s';

implementation

{ TMaModel }

function TMaModel.Own<T>(const AItem: T): T;
begin
  FOwned.Add(AItem);
  Result := AItem;
end;

constructor TMaModel.Create;
begin
  inherited Create;
  FMaterials := TList<AnsiString>.Create;
  FObjects := TObjectList<TMaObject>.Create(True);
  // idHashTable compares the keys with idStr::Cmp: case sensitive
  FTransforms := TDictionary<AnsiString, TMaTransform>.Create;
  FFileNodes := TDictionary<AnsiString, TMaFileNode>.Create;
  FMaterialNodes := TDictionary<AnsiString, TMaMaterialNode>.Create;
  FOwned := TObjectList<TObject>.Create(True);
end;

destructor TMaModel.Destroy;
begin
  FOwned.Free;
  FMaterialNodes.Free;
  FFileNodes.Free;
  FTransforms.Free;
  FObjects.Free;
  FMaterials.Free;
  inherited Destroy;
end;

end.
