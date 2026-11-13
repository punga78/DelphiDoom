{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: 3D Studio Max ASCII export   }
{  (ASE), the data read from the file                                          }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_ase.h.    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This      }
{  unit is derived from the Doom 3 GPL source code and is therefore            }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Ase.Types;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Types;

type
  /// <summary>
  ///   Turns the path of a bitmap in the file (the one of the machine of the artist, with
  ///   backslashes already changed to slashes) into the name of a material, as
  ///   idFileSystem::OSPathToRelativePath does. The default keeps the path.
  /// </summary>
  TStaticPathResolver = reference to function(const APath: AnsiString): AnsiString;

  /// <summary>A face (aseFace_t): the original leaves the fields that the file does not give uninitialized; here they are zero</summary>
  TAseFace = record
    VertexNum: array[0..2] of Integer;
    TVertexNum: array[0..2] of Integer;
    FaceNormal: TIdVec3;
    VertexNormals: array[0..2] of TIdVec3;
    VertexColors: array[0..2] of TStaticColor;
  end;

  /// <summary>A mesh (aseMesh_t): a frame of an object</summary>
  TAseMesh = record
    TimeValue: Integer;
    NumVertexes: Integer;
    NumTVertexes: Integer;
    NumCVertexes: Integer;
    NumFaces: Integer;
    NumTVFaces: Integer;
    NumCVFaces: Integer;
    /// <summary>The rows of the transform of the node, applied to the normals</summary>
    Transform: array[0..3] of TIdVec3;
    ColorsParsed: Boolean;
    NormalsParsed: Boolean;
    Vertexes: TArray<TIdVec3>;
    TVertexes: TArray<TIdVec2>;
    CVertexes: TArray<TIdVec3>;
    Faces: TArray<TAseFace>;
  end;

  /// <summary>A material (aseMaterial_t): the name of the bitmap and its texture matrix</summary>
  TAseMaterial = record
    Name: AnsiString;
    UOffset: Single;
    VOffset: Single;
    UTiling: Single;
    VTiling: Single;
    /// <summary>In clockwise radians</summary>
    Angle: Single;
  end;

  /// <summary>An object (aseObject_t): a mesh and the frames of its animation, if any</summary>
  TAseObject = record
    Name: AnsiString;
    MaterialRef: Integer;
    Mesh: TAseMesh;
    Frames: TArray<TAseMesh>;
  end;

  /// <summary>The model of a file (aseModel_t)</summary>
  TAseModel = record
    Materials: TArray<TAseMaterial>;
    Objects: TArray<TAseObject>;
  end;

implementation

end.
