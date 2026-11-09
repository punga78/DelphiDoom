{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL level geometry - the contracts                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlLevel.Intf;

interface

uses
  DelphiDoom.GlLevel.Types;

type
  /// <summary>The BSP of the level as the carver reads it</summary>
  IGlFlatWorld = interface
    ['{2F6B9D14-73A0-4C58-9E17-B8D05A3C61E2}']
    function GetSubsectorCount: Integer;
    function GetNode(const AIndex: Integer): TGlCarverNode;
    function GetSubsector(const AIndex: Integer): TGlCarverSubsector;
    function GetSeg(const AIndex: Integer): TGlCarverSeg;
  end;

  /// <summary>Where the polygons of the flats go: one convex polygon (a fan) for a sector at a time</summary>
  IGlFlatLoopSink = interface
    ['{A41E7C08-5D92-4B36-8F20-61C9D7B3E4F5}']
    /// <summary>The points are valid only during the call</summary>
    procedure AddLoop(const ASectorId: Integer; const APoints: PGlFixedPoint; const ACount: Integer);
  end;

  /// <summary>The sectors and lines of the level as gld_PreprocessSectors reads and writes them</summary>
  IGlSectorWorld = interface
    ['{5C8E1A37-0B4D-4F62-A9D3-E71F20B96C48}']
    function GetSectorCount: Integer;
    /// <summary>The number of vertexes of the level</summary>
    function GetVertexCount: Integer;
    function GetLineCount(const ASector: Integer): Integer;
    function GetLine(const ASector, ALine: Integer): TGlSectorLine;
    /// <summary>no_toptextures and no_bottomtextures of the sector (the special effects of r_bsp.c R_Subsector)</summary>
    procedure SetNoTextures(const ASector: Integer; const ANoTop, ANoBottom: Boolean);
    /// <summary>The line is not shared with another line of its sector (LRF_ISOLATED)</summary>
    procedure MarkIsolated(const ASector, ALine: Integer);
  end;

  /// <summary>The checks on the sectors that the OpenGL renderer needs once for each level</summary>
  IGlSectorPreprocessor = interface
    ['{B2D74F90-18C3-4E5A-86B1-4A9F03DE57C2}']
    /// <summary>
    ///   For each sector: the flags of the special effects (gld_PrepareSectorSpecialEffects) and the
    ///   isolated lines (the vertex check of gld_PreprocessSectors)
    /// </summary>
    procedure Preprocess;
  end;

  /// <summary>The flats of a level: the polygons of every subsector, by carving the BSP or from the GL nodes</summary>
  IGlFlatCarver = interface
    ['{9D3052B7-E6A1-4F84-B2C9-0A57F1D8E3C6}']
    /// <summary>
    ///   The old gld_CarveFlats from the root: each subsector whose sector is not closed is cut out of
    ///   the whole map by the partition lines of the nodes above it and by its segs
    /// </summary>
    procedure CarveFlats(const ARootNode: Integer; const AIsClosed: TGlSectorClosed);
    /// <summary>The old gld_GetSubSectorVertices: the polygon of a subsector is the start of its segs (GL nodes)</summary>
    procedure AddSubsectorLoops(const AIsClosed: TGlSectorClosed);
  end;

implementation

end.
