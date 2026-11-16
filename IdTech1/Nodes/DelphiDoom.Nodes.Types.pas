{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - types and records of the node lumps             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>'gNd2' (little endian): first four bytes of GL_VERT in V2 and V3 nodes, and of GL_VERT of a GWA</summary>
  NODES_GL_MAGIC_V2 = Cardinal($32644E67);
  /// <summary>'gNd3': first four bytes of GL_SEGS and GL_SSECT of V3 nodes</summary>
  NODES_GL_MAGIC_V3 = Cardinal($33644E67);
  /// <summary>'gNd4': first four bytes of GL_VERT of V4 nodes</summary>
  NODES_GL_MAGIC_V4 = Cardinal($34644E67);
  /// <summary>'gNd5': first four bytes of GL_VERT of V5 nodes</summary>
  NODES_GL_MAGIC_V5 = Cardinal($35644E67);

  /// <summary>Flag of a child of a V1 node: the child is a subsector</summary>
  NODES_CHILD_SUBSECTOR_V1 = Cardinal($8000);
  /// <summary>Flag of a child of a V5 node: the child is a subsector</summary>
  NODES_CHILD_SUBSECTOR_V5 = Cardinal($80000000);

  /// <summary>Names of the lumps of the GL nodes</summary>
  NODES_LUMP_GL_VERT = 'GL_VERT';
  NODES_LUMP_GL_SEGS = 'GL_SEGS';
  NODES_LUMP_GL_SSECT = 'GL_SSECT';
  NODES_LUMP_GL_NODES = 'GL_NODES';
  /// <summary>Name of the lump that glBSP writes for a map with a long name</summary>
  NODES_LUMP_GL_LEVEL = 'GL_LEVEL';
  /// <summary>The longest name of a lump</summary>
  NODES_LUMP_NAME_LENGTH = 8;

  /// <summary>Position of each lump of a map, counted from its label (as the ML_* of the engine)</summary>
  NODES_MAP_LABEL = 0;
  NODES_MAP_THINGS = 1;
  NODES_MAP_LINEDEFS = 2;
  NODES_MAP_SIDEDEFS = 3;
  NODES_MAP_VERTEXES = 4;
  NODES_MAP_SEGS = 5;
  NODES_MAP_SSECTORS = 6;
  NODES_MAP_NODES = 7;
  NODES_MAP_SECTORS = 8;
  NODES_MAP_REJECT = 9;
  NODES_MAP_BLOCKMAP = 10;
  NODES_MAP_BEHAVIOR = 11;

  /// <summary>The most lumps that a standalone GWA may have (label, GL_VERT, GL_SEGS, GL_SSECT, GL_NODES, GL_PVS...)</summary>
  NODES_GWA_MAX_LUMPS = 10;

  /// <summary>Size of the header of a WAD and of an entry of its directory</summary>
  NODES_WAD_HEADER_SIZE = 12;
  NODES_WAD_ENTRY_SIZE = 16;

type
  /// <summary>Raised for data that cannot be read: the file is not a GWA, a lump is out of the file</summary>
  ENodesException = class(Exception);

  /// <summary>GL_VERT of V1 nodes: map units as 16 bit integers</summary>
  TNodesGlVertex1 = packed record
    X: SmallInt;
    Y: SmallInt;
  end;

  /// <summary>GL_VERT of V2 and later (after the magic): 16.16 fixed point. The neutral vertex of the library</summary>
  TNodesGlVertex = packed record
    X: Integer;
    Y: Integer;
  end;

  /// <summary>GL_SEGS of V1 and V2</summary>
  TNodesGlSeg1 = packed record
    StartVertex: Word;
    EndVertex: Word;
    Linedef: Word;
    Side: Word;
    PartnerSeg: Word;
  end;

  /// <summary>GL_SEGS of V3 and later. The neutral seg of the library</summary>
  TNodesGlSeg = packed record
    StartVertex: Cardinal;
    EndVertex: Cardinal;
    Linedef: Word;
    Side: Word;
    PartnerSeg: Cardinal;
  end;

  /// <summary>GL_SSECT of V1 and V2</summary>
  TNodesGlSubsector1 = packed record
    Count: Word;
    FirstSeg: Word;
  end;

  /// <summary>GL_SSECT of V3 and later. The neutral subsector of the library</summary>
  TNodesGlSubsector = packed record
    Count: Cardinal;
    FirstSeg: Cardinal;
  end;

  /// <summary>GL_NODES of V1..V3 (and the NODES of the maps)</summary>
  TNodesGlNode1 = packed record
    X: SmallInt;
    Y: SmallInt;
    DeltaX: SmallInt;
    DeltaY: SmallInt;
    RightBoundingBox: array[0..3] of SmallInt;
    LeftBoundingBox: array[0..3] of SmallInt;
    RightChild: Word;
    LeftChild: Word;
  end;

  /// <summary>GL_NODES of V4 and V5. The neutral node of the library: a child with NODES_CHILD_SUBSECTOR_V5 is a subsector</summary>
  TNodesGlNode = packed record
    X: SmallInt;
    Y: SmallInt;
    DeltaX: SmallInt;
    DeltaY: SmallInt;
    RightBoundingBox: array[0..3] of SmallInt;
    LeftBoundingBox: array[0..3] of SmallInt;
    RightChild: Cardinal;
    LeftChild: Cardinal;
  end;

  /// <summary>Header of a WAD (identification 'IWAD' or 'PWAD')</summary>
  TNodesWadHeader = packed record
    Identification: Integer;
    LumpCount: Integer;
    DirectoryOffset: Integer;
  end;

  /// <summary>One entry of the directory of a WAD</summary>
  TNodesWadEntry = packed record
    Position: Integer;
    Size: Integer;
    Name: array[0..NODES_LUMP_NAME_LENGTH - 1] of AnsiChar;
  end;

  /// <summary>THINGS of Doom, Heretic and Strife: 10 bytes</summary>
  TNodesVanillaThing = packed record
    X: SmallInt;
    Y: SmallInt;
    Angle: SmallInt;
    ThingType: Word;
    Options: SmallInt;
  end;

  /// <summary>THINGS of Hexen: 20 bytes</summary>
  TNodesHexenThing = packed record
    Tid: SmallInt;
    X: SmallInt;
    Y: SmallInt;
    Height: SmallInt;
    Angle: SmallInt;
    ThingType: Word;
    Options: SmallInt;
    Special: Byte;
    Arguments: array[0..4] of Byte;
  end;

  /// <summary>LINEDEFS of Doom, Heretic and Strife: 14 bytes</summary>
  TNodesVanillaLinedef = packed record
    Vertex1: SmallInt;
    Vertex2: SmallInt;
    Flags: SmallInt;
    Special: SmallInt;
    Tag: SmallInt;
    SideNumber: array[0..1] of SmallInt;
  end;

  /// <summary>LINEDEFS of Hexen: 16 bytes</summary>
  TNodesHexenLinedef = packed record
    Vertex1: SmallInt;
    Vertex2: SmallInt;
    Flags: SmallInt;
    Special: Byte;
    Arguments: array[0..4] of Byte;
    SideNumber: array[0..1] of SmallInt;
  end;

  /// <summary>SEGS of a map: 12 bytes</summary>
  TNodesVanillaSeg = packed record
    Vertex1: SmallInt;
    Vertex2: SmallInt;
    Angle: SmallInt;
    Linedef: SmallInt;
    Side: SmallInt;
    Offset: SmallInt;
  end;

  /// <summary>SSECTORS of a map: 4 bytes</summary>
  TNodesVanillaSubsector = packed record
    SegCount: Word;
    FirstSeg: Word;
  end;

  /// <summary>NODES of a map: 28 bytes. A child with NODES_CHILD_SUBSECTOR_V1 is a subsector</summary>
  TNodesVanillaNode = packed record
    X: SmallInt;
    Y: SmallInt;
    DeltaX: SmallInt;
    DeltaY: SmallInt;
    BoundingBox: array[0..1, 0..3] of SmallInt;
    Children: array[0..1] of Word;
  end;

  /// <summary>
  ///   Where the lumps of a map are, as a distance from its label (1 for THINGS, 2 for
  ///   LINEDEFS...), or -1 for a lump that the map does not have
  /// </summary>
  TNodesMapLayout = record
    Things: Integer;
    Linedefs: Integer;
    Sidedefs: Integer;
    Vertexes: Integer;
    Segs: Integer;
    Subsectors: Integer;
    Nodes: Integer;
    Sectors: Integer;
    Reject: Integer;
    Blockmap: Integer;
    Behavior: Integer;
    /// <summary>A layout without any lump</summary>
    class function Missing: TNodesMapLayout; static;
    /// <summary>True if every lump is where a WAD puts it (the map needs nothing from the node builder)</summary>
    function IsComplete(AHexen: Boolean): Boolean;
    /// <summary>True if the lumps that the node builder reads are there: things, lines, sides, vertexes, sectors</summary>
    function CanBuildNodes: Boolean;
  end;

implementation

{ TNodesMapLayout }

class function TNodesMapLayout.Missing: TNodesMapLayout;
begin
  Result.Things := -1;
  Result.Linedefs := -1;
  Result.Sidedefs := -1;
  Result.Vertexes := -1;
  Result.Segs := -1;
  Result.Subsectors := -1;
  Result.Nodes := -1;
  Result.Sectors := -1;
  Result.Reject := -1;
  Result.Blockmap := -1;
  Result.Behavior := -1;
end;

function TNodesMapLayout.IsComplete(AHexen: Boolean): Boolean;
begin
  Result := (Things = NODES_MAP_THINGS) and (Linedefs = NODES_MAP_LINEDEFS) and
    (Sidedefs = NODES_MAP_SIDEDEFS) and (Vertexes = NODES_MAP_VERTEXES) and
    (Segs = NODES_MAP_SEGS) and (Subsectors = NODES_MAP_SSECTORS) and
    (Nodes = NODES_MAP_NODES) and (Sectors = NODES_MAP_SECTORS) and
    (Reject = NODES_MAP_REJECT) and (Blockmap = NODES_MAP_BLOCKMAP);
  if AHexen then
    Result := Result and (Behavior = NODES_MAP_BEHAVIOR);
end;

function TNodesMapLayout.CanBuildNodes: Boolean;
begin
  Result := (Things > 0) and (Linedefs > 0) and (Sidedefs > 0) and (Vertexes > 0) and
    (Sectors > 0);
end;

end.
