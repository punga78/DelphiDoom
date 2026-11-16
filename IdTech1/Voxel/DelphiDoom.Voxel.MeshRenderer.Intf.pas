{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - where the quads of a voxel mesh are drawn       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.MeshRenderer.Intf;

interface

uses
  DelphiDoom.Voxel.MeshTypes;

type
  /// <summary>
  ///   Takes the quads of a mesh one vertex at a time. The engine implements it with the calls
  ///   of OpenGL (a display list is made at load time, never per frame); the tests with a recorder
  /// </summary>
  IVoxelMeshRenderer = interface
    ['{5B7D3A20-4C18-4E6F-9A52-0E81D6B3C7A4}']
    procedure BeginQuads;
    /// <summary>The texture coordinate of the next vertexes (the color of the quad in the voxel texture)</summary>
    procedure TexCoord(const ACoordS, ACoordT: Single);
    procedure Vertex(const AX, AY, AZ: Single);
    procedure EndQuads;
  end;

  /// <summary>
  ///   Where a vertex of the cube goes in the space of the engine: each model format has its own
  ///   axes, offset and scale
  /// </summary>
  IVoxelMeshVertexMap = interface
    ['{C3E19F64-7D2A-4B85-A1F0-62D4B8E5A913}']
    procedure Map(const AVertex: TVoxelMeshVertex; out AX, AY, AZ: Single);
  end;

implementation

end.
