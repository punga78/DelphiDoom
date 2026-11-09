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
