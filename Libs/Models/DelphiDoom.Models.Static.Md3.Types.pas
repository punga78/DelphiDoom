{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: MD3 (Quake 3), the data      }
{  read from the file                                                          }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md3.h.    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This      }
{  unit is derived from the Doom 3 GPL source code and is therefore            }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Md3.Types;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3;

const
  /// <summary>The only version of the format that the engine reads (MD3_VERSION)</summary>
  MD3_VERSION = 15;
  /// <summary>Limits of a surface that the loader enforces (SHADER_MAX_VERTEXES, SHADER_MAX_INDEXES)</summary>
  MD3_SHADER_MAX_VERTEXES = 1000;
  MD3_SHADER_MAX_INDEXES = 6 * MD3_SHADER_MAX_VERTEXES;
  /// <summary>The scale of the positions of a vertex: 1/64 (MD3_XYZ_SCALE)</summary>
  MD3_XYZ_SCALE = 1.0 / 64;
  /// <summary>The size of the names in the file (MAX_MD3PATH)</summary>
  MD3_MAX_PATH = 64;
  /// <summary>The size in bytes of the header, of a frame, of a tag, of the header of a surface</summary>
  MD3_HEADER_SIZE = 108;
  MD3_FRAME_SIZE = 56;
  MD3_TAG_SIZE = 112;
  MD3_SURFACE_HEADER_SIZE = 108;

type
  /// <summary>A frame (md3Frame_t): the box, the local origin and the radius</summary>
  TMd3Frame = record
    BoundsMin: TIdVec3;
    BoundsMax: TIdVec3;
    LocalOrigin: TIdVec3;
    Radius: Single;
    Name: AnsiString;
  end;

  /// <summary>A tag (md3Tag_t): a point of attachment with its axes</summary>
  TMd3Tag = record
    Name: AnsiString;
    Origin: TIdVec3;
    Axis: array[0..2] of TIdVec3;
  end;

  /// <summary>
  ///   A surface (md3Surface_t and its chunks). The name is lowercase without a trailing "_1" or
  ///   "_2". The positions are the shorts of the file: four for every vertex of every frame
  ///   (x, y, z and the packed normal).
  /// </summary>
  TMd3Surface = record
    Name: AnsiString;
    Flags: Integer;
    NumFrames: Integer;
    NumVerts: Integer;
    Shaders: TArray<AnsiString>;
    /// <summary>Three indexes for every triangle</summary>
    Triangles: TArray<Integer>;
    St: TArray<TIdVec2>;
    XyzNormals: TArray<SmallInt>;
  end;

  /// <summary>The model of a file (md3Header_t and the chunks): frames, tags of every frame, surfaces</summary>
  TMd3Model = record
    Name: AnsiString;
    Flags: Integer;
    NumSkins: Integer;
    Frames: TArray<TMd3Frame>;
    /// <summary>NumTags tags for each frame, the frames one after the other</summary>
    Tags: TArray<TMd3Tag>;
    NumTags: Integer;
    Surfaces: TArray<TMd3Surface>;
  end;

resourcestring
  SStaticMd3Version = 'MD3: wrong version (%d should be %d)';
  SStaticMd3NoFrames = 'MD3: the model has no frames';
  SStaticMd3TooManyVerts = 'MD3: more than %d verts on a surface (%d)';
  SStaticMd3TooManyTriangles = 'MD3: more than %d triangles on a surface (%d)';
  SStaticMd3Offset = 'MD3: the %s is out of the file (offset %d, %d bytes)';
  SStaticMd3BadCount = 'MD3: %s is negative (%d)';
  SStaticMd3BadFrame = 'MD3: the frame %d does not exist (%d frames)';

implementation

end.
