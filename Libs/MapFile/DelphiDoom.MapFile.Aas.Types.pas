{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - constants, records and errors of .aas files  }
{                                                                              }
{  Port of the constants and the records of AASFile.h (tools\compilers\aas),   }
{  Doom 3 GPL Source Code.                                                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Types;

interface

uses
  DelphiDoom.IdLib.Text.Types, DelphiDoom.MapFile.Types;

const
  /// <summary>The first token of a .aas file (AAS_FILEID)</summary>
  AAS_FILEID = 'DewmAAS';
  /// <summary>The version that is read (AAS_FILEVERSION), a token like "1.07"</summary>
  AAS_FILEVERSION = '1.07';
  /// <summary>The flags of the lexer of idAASFileLocal::Load, without LEXFL_NOFATALERRORS</summary>
  AAS_LEXER_FLAGS = LEXFL_NOSTRINGESCAPECHARS or LEXFL_NOSTRINGCONCAT or LEXFL_ALLOWPATHNAMES;

  // travel flags
  TFL_INVALID = 1 shl 0;
  TFL_WALK = 1 shl 1;
  TFL_CROUCH = 1 shl 2;
  TFL_WALKOFFLEDGE = 1 shl 3;
  TFL_BARRIERJUMP = 1 shl 4;
  TFL_JUMP = 1 shl 5;
  TFL_LADDER = 1 shl 6;
  TFL_SWIM = 1 shl 7;
  TFL_WATERJUMP = 1 shl 8;
  TFL_TELEPORT = 1 shl 9;
  TFL_ELEVATOR = 1 shl 10;
  TFL_FLY = 1 shl 11;
  TFL_SPECIAL = 1 shl 12;
  TFL_WATER = 1 shl 21;
  TFL_AIR = 1 shl 22;

  // face flags
  FACE_SOLID = 1 shl 0;
  FACE_LADDER = 1 shl 1;
  FACE_FLOOR = 1 shl 2;
  FACE_LIQUID = 1 shl 3;
  FACE_LIQUIDSURFACE = 1 shl 4;

  // area flags
  AREA_FLOOR = 1 shl 0;
  AREA_GAP = 1 shl 1;
  AREA_LEDGE = 1 shl 2;
  AREA_LADDER = 1 shl 3;
  AREA_LIQUID = 1 shl 4;
  AREA_CROUCH = 1 shl 5;
  AREA_REACHABLE_WALK = 1 shl 6;
  AREA_REACHABLE_FLY = 1 shl 7;

  // area contents flags
  AREACONTENTS_SOLID = 1 shl 0;
  AREACONTENTS_WATER = 1 shl 1;
  AREACONTENTS_CLUSTERPORTAL = 1 shl 2;
  AREACONTENTS_OBSTACLE = 1 shl 3;
  AREACONTENTS_TELEPORTER = 1 shl 4;
  /// <summary>Bits for the different bounding boxes</summary>
  AREACONTENTS_BBOX_BIT = 24;

  MAX_REACH_PER_AREA = 256;
  /// <summary>A deeper tree makes the load report a warning (the file is still read)</summary>
  MAX_AAS_TREE_DEPTH = 128;
  MAX_AAS_BOUNDING_BOXES = 4;
  /// <summary>
  ///   Upper bound of any count of the file. The original allocates what the file says; a
  ///   hostile file would exhaust the memory
  /// </summary>
  MAX_AAS_ELEMENTS = 1 shl 22;

type
  /// <summary>aasEdge_t: the numbers of the two vertices</summary>
  TAasEdge = record
    VertexNum: array[0..1] of Integer;
  end;

  /// <summary>
  ///   aasFace_t, with the same narrow types: a value of the file wraps as it does in C. The
  ///   edges of a face are <c>NumEdges</c> entries of the edge index from <c>FirstEdge</c>; a
  ///   negative edge number is the edge traversed backwards
  /// </summary>
  TAasFace = record
    PlaneNum: Word;
    Flags: Word;
    NumEdges: Integer;
    FirstEdge: Integer;
    /// <summary>The area at the front and at the back of the face</summary>
    Areas: array[0..1] of SmallInt;
  end;

  /// <summary>aasNode_t: a child of 0 is solid, a negative child is -(area number)</summary>
  TAasNode = record
    PlaneNum: Word;
    Children: array[0..1] of Integer;
  end;

  /// <summary>
  ///   aasPortal_t. The file does not hold <c>MaxAreaTravelTime</c> (the routing computes it
  ///   later): it is 0 after a read
  /// </summary>
  TAasPortal = record
    AreaNum: SmallInt;
    Clusters: array[0..1] of SmallInt;
    ClusterAreaNum: array[0..1] of SmallInt;
    MaxAreaTravelTime: Word;
  end;

  /// <summary>aasCluster_t</summary>
  TAasCluster = record
    NumAreas: Integer;
    NumReachableAreas: Integer;
    NumPortals: Integer;
    FirstPortal: Integer;
  end;

  /// <summary>
  ///   A .aas file that cannot be read; the message and the line are those of EMapFileException
  /// </summary>
  EAasFileException = class(EMapFileException);

  /// <summary>
  ///   The file was written for another map: the CRC of the map file it holds is not the one that
  ///   the caller expects (the original warns "is out of date" and does not load it)
  /// </summary>
  EAasFileOutOfDateException = class(EAasFileException);

implementation

end.
