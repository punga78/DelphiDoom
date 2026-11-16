{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the types of the quads of a voxel mesh          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.MeshTypes;

interface

const
  /// <summary>Most passes of the full optimizer that the engine option can ask for</summary>
  VOXEL_MESH_MAX_PASSES = 3;

type
  /// <summary>A vertex of a quad, in the axes of the cube it was made from</summary>
  TVoxelMeshVertex = record
    x, y, z: Single;
  end;

  PVoxelMeshVertex = ^TVoxelMeshVertex;

  /// <summary>A quad of the mesh: the color of the voxel and four vertexes</summary>
  TVoxelMeshQuad = record
    color: Cardinal;
    vertexes: array[0..3] of TVoxelMeshVertex;
    valid: Boolean;
    orientation: Char;
  end;

  PVoxelMeshQuad = ^TVoxelMeshQuad;

  // The array is indexed past its declared size on purpose (it is a block of memory that the
  // optimizer grows); range checking is off in the unit that does it
  TVoxelMeshQuadArray = array[0..$FFF] of TVoxelMeshQuad;

  PVoxelMeshQuadArray = ^TVoxelMeshQuadArray;

  /// <summary>Which optimizer made a result</summary>
  TVoxelMeshOptimizeKind = (vokFast, vokFull);

  /// <summary>What an optimization did, for the message that the engine prints</summary>
  TVoxelMeshOptimizeResult = record
    Kind: TVoxelMeshOptimizeKind;
    OldQuadCount: Integer;
    NewQuadCount: Integer;
    /// <summary>Passes done by the full optimizer (0 for the fast one)</summary>
    Passes: Integer;
  end;

implementation

end.
