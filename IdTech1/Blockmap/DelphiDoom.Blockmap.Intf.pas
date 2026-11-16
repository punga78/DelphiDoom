{******************************************************************************}
{                                                                              }
{  DelphiDoom: blockmap - contracts                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Blockmap.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Blockmap.Types;

type
  /// <summary>Makes the blockmap of a level from its vertexes and lines (killough's algorithm)</summary>
  IBlockmapBuilder = interface
    ['{5B6E2D41-7C3A-4F18-9A52-0D8E41C7B3A6}']
    /// <summary>Builds a blockmap that encloses all the vertexes</summary>
    /// <exception cref="EBlockmapException">There are no vertexes or the map is too big</exception>
    function Build(const AVertexes: TArray<TBlockmapPoint>;
      const ALines: TArray<TBlockmapLine>): TBlockmapData;
  end;

  /// <summary>Reads the BLOCKMAP lump of a WAD</summary>
  IBlockmapLumpReader = interface
    ['{A1F3C6D8-2E94-4B07-8D35-6C9B07E5F214}']
    /// <summary>
    ///   True when the lump can be used: it holds the header and fewer values than
    ///   the 16 bit offsets can reach, and the header does not claim more blocks
    ///   than the lump has offsets for
    /// </summary>
    function IsUsable(const ALump: TBytes): Boolean;
    /// <summary>Converts a usable lump (16 bit values) to the 32 bit format of the engine</summary>
    function Read(const ALump: TBytes): TBlockmapData;
  end;

  /// <summary>Moves the vertexes of the segs that are not ends of their line onto that line (killough 10/98)</summary>
  ISlimeTrailRemover = interface
    ['{C7D90E52-3B18-4A6F-B2E1-94F5A8D03C7B}']
    /// <summary>Changes the coordinates in AVertexes; a vertex is moved at most once</summary>
    /// <exception cref="EBlockmapException">A seg or a line points to a vertex that does not exist</exception>
    procedure Remove(var AVertexes: TArray<TBlockmapPoint>; const ASegs: TArray<TBlockmapSeg>);
  end;

implementation

end.
