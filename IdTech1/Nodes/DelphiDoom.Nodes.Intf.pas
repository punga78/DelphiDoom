{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - the contracts                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Nodes.Types;

type
  /// <summary>
  ///   The lumps of the WAD directory as the library needs them: by number, in the order of the
  ///   directory (the lumps of a map follow its label). The engine answers with its own directory
  /// </summary>
  INodesLumpSource = interface
    ['{4E1B7A52-90C3-4D68-B2F5-6A07C1E93D84}']
    function GetLumpCount: Integer;
    /// <summary>The name of a lump without the padding (1 to 8 characters); an empty string if the number is not a lump</summary>
    function LumpName(ALump: Integer): string;
    function LumpLength(ALump: Integer): Integer;
    /// <summary>All the bytes of a lump</summary>
    function ReadLump(ALump: Integer): TBytes;
    /// <summary>The last lump with that name (case does not matter), or -1</summary>
    function FindLump(const AName: string): Integer;
    property LumpCount: Integer read GetLumpCount;
  end;

  /// <summary>Tells which version of GL nodes follows a label of a map</summary>
  INodesGlDetector = interface
    ['{B3A97E10-5C4F-4E2D-8A61-F0D2589B7C13}']
    /// <summary>
    ///   2, 3, 4 or 5 for GL nodes in the four lumps that follow ABaseLump (GL_VERT, GL_SEGS,
    ///   GL_SSECT, GL_NODES), 0 for anything else (also for V1 nodes, which have no magic number)
    /// </summary>
    function DetectVersion(ABaseLump: Integer): Integer;
  end;

  /// <summary>Finds the GL nodes of a map by the checksum of the map</summary>
  INodesGlMapFinder = interface
    ['{7D2C84E9-31A5-4B07-9E6C-A18F5D03B246}']
    /// <summary>
    ///   The label of the GL nodes that were built for the map (their checksum is the one of
    ///   VERTEXES and LINEDEFS of the map), or -1
    /// </summary>
    function FindGlMapLump(AMapLump: Integer): Integer;
  end;

  /// <summary>Makes the WAD that the node builder reads: the lumps of a map, from the label</summary>
  INodesGlbspInputBuilder = interface
    ['{C09E3F68-A27D-4B15-8D40-1E56B7A98F32}']
    /// <summary>
    ///   The WAD of the map: label, THINGS .. BLOCKMAP and BEHAVIOR if the map has it (in a game
    ///   that is not Hexen the things and the lines of a map with BEHAVIOR become Hexen records)
    /// </summary>
    function BuildForMap(AMapLabel: Integer): TBytes;
    /// <summary>
    ///   The WAD for a map without nodes: the 11 lumps (12 in Hexen) in order, with the empty ones
    ///   that the builder will fill; the lumps that the map does not have are empty
    /// </summary>
    function BuildForMapWithoutNodes(AMapLabel: Integer; const ALayout: TNodesMapLayout): TBytes;
  end;

  /// <summary>The nodes of a standalone GWA, as neutral records</summary>
  INodesGwa = interface
    ['{5A60D1B7-E8C2-4F93-A7B4-2D91C03E6F58}']
    function GetVersion: Integer;
    function GetGlVertexes: TArray<TNodesGlVertex>;
    function GetSubsectors: TArray<TNodesGlSubsector>;
    function GetNodes: TArray<TNodesGlNode>;
    function GetSegs: TArray<TNodesGlSeg>;
    /// <summary>0 for V1 (no magic number), 2..5</summary>
    property Version: Integer read GetVersion;
    /// <summary>The extra vertices, in 16.16 fixed point</summary>
    property GlVertexes: TArray<TNodesGlVertex> read GetGlVertexes;
    property Subsectors: TArray<TNodesGlSubsector> read GetSubsectors;
    /// <summary>Always in the V5 form: a child that is a subsector has NODES_CHILD_SUBSECTOR_V5</summary>
    property Nodes: TArray<TNodesGlNode> read GetNodes;
    property Segs: TArray<TNodesGlSeg> read GetSegs;
  end;

implementation

end.
