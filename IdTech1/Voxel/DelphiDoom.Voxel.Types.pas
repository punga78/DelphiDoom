{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the shared types and constants                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The biggest side of a voxel model (and of a cube) in voxels</summary>
  VOXEL_MAX_SIZE = 256;
  /// <summary>The bytes of the palette at the end of a KVX or VOX file: 256 colors of 3 bytes</summary>
  VOXEL_PALETTE_BYTES = 768;
  /// <summary>The color of a voxel that is black in the palette (zero means no voxel)</summary>
  VOXEL_BLACK_COLOR = $000001;

  /// <summary>The bytes of the header of a KVX file: the byte count, the three sizes and the three pivots</summary>
  KVX_HEADER_SIZE = 28;
  /// <summary>The bytes of the header of a VOX file (Slab6): the three sizes</summary>
  SLAB6_HEADER_SIZE = 12;
  /// <summary>The value of a byte of a VOX file that is not a voxel</summary>
  SLAB6_EMPTY = 255;
  /// <summary>The pivot of a KVX file is in 1/256 of a voxel</summary>
  KVX_PIVOT_UNIT = 256;

  /// <summary>The first four bytes of a DDMESH file: DDMS</summary>
  DDMESH_MAGIC = $534D4444;
  /// <summary>The only version of the DDMESH file</summary>
  DDMESH_VERSION = 1;
  /// <summary>The bytes of the header of a DDMESH file: the magic, the version, the size and the quad count</summary>
  DDMESH_HEADER_SIZE = 16;
  /// <summary>The bytes of a quad of a DDMESH file: the color and four vertexes of three integers</summary>
  DDMESH_QUAD_SIZE = 52;
  /// <summary>The bytes of a voxel of a DDMESH file: x, y, z and the color</summary>
  DDMESH_VOXEL_SIZE = 7;

  /// <summary>The flag of a voxel definition that is clipped by the walls</summary>
  VOXEL_FLAG_CLIPPED = 1;

resourcestring
  SVoxelTruncated = 'The voxel file is truncated (%d bytes, %d more needed at %d)';
  SVoxelInvalidSize = 'The voxel file has an invalid size (%d, %d, %d)';
  SVoxelTooShort = 'The voxel file is too short (%d bytes)';
  SVoxelDdvoxSize = 'The DDVOX file has an invalid size (%d)';
  SVoxelDdvoxOverrun = 'The DDVOX file has more voxels in a column than its size (%d)';
  SVoxelDdmeshMagic = 'File does not have DDMESH magic header!';
  SVoxelDdmeshVersion = 'File is from unsupported version = %d!';
  SVoxelDdmeshCounts = 'The DDMESH file has invalid counts (size %d, quads %d, voxels %d)';
  SVoxelKvxData = 'The KVX file has an invalid data size (%d bytes for the byte count %d)';
  SVoxelKvxOffsets = 'The KVX file has a slab outside its data (column %d, %d)';
  SVoxelKvxSlab = 'The KVX file has a slab outside the model (column %d, %d, top %d, length %d)';
  SVoxelLoaderFailed = 'TVoxelLoader.Load(): %s: %s';
  SVoxelInvalidModel = 'A voxel model needs %d cells and has %d';
  SVoxelDefTokenExpected = 'SC_ParseVoxelDefinition(): Token expected at line %d'#13#10;
  SVoxelDefSpriteExpected = 'SC_ParseVoxelDefinition(): "SPRITE" expected at line %d'#13#10;
  SVoxelDefSpriteNotFound = 'SC_ParseVoxelDefinition(): Can not find sprite %s at line %d'#13#10;
  SVoxelDefUnknownState = 'SC_ParseVoxelDefinition(): Unknown state "%s" at line %d'#13#10;
  SVoxelDefUnknownToken = 'SC_ParseVoxelDefinition(): Unknown token "%s" at line %d'#13#10;

type
  /// <summary>The kinds of voxel files the library reads</summary>
  TVoxelFormatKind = (vfDdvox, vfDdmesh, vfKvx, vfSlab6);

  /// <summary>
  ///   How a model is put in a cube: the renderers want a cube a bit bigger than the model
  ///   (and one odd side), the sprites want an even side
  /// </summary>
  TVoxelCubeFit = (cfRenderer, cfSprite);

  /// <summary>A vertex of a quad of a DDMESH file, in voxels</summary>
  TVoxelQuadVertex = record
    X: Integer;
    Y: Integer;
    Z: Integer;
  end;

  /// <summary>A face of a mesh of a DDMESH file: the color as $00RRGGBB and the four vertexes</summary>
  TVoxelQuad = record
    Color: Cardinal;
    Vertexes: array[0..3] of TVoxelQuadVertex;
  end;

  /// <summary>A voxel or a state definition of a VOXELDEF lump (offset and scale are as they are written)</summary>
  TVoxelDefinitionItem = record
    Name: string;
    Offset: Single;
    Scale: Single;
    AngleOffset: Integer;
    DroppedSpin: Integer;
    PlacedSpin: Integer;
    Flags: Cardinal;
  end;

  /// <summary>
  ///   A state that shows a voxel: the index that the sink gave to the voxel (-1 if none), the
  ///   frame and the index of the state
  /// </summary>
  TVoxelDefinitionState = record
    VoxelIndex: Integer;
    Frame: Integer;
    State: Integer;
  end;

  /// <summary>A voxel file that cannot be read: the message says why</summary>
  EVoxelException = class(Exception);

implementation

end.
