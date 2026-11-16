{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - options of a node build                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of nodebuildinfo_t of glBSP 2.24 (C) 2000-2007 Andrew Apted            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Options;

interface

const
  DEFAULT_FACTOR = 11;
  DEFAULT_BLOCK_LIMIT = 16000;
  DEFAULT_SPEC_VERSION = 2;

type
  /// <summary>
  ///   What the node builder is asked to do. The defaults are those of the
  ///   glbsp command line without options
  /// </summary>
  TGlbspOptions = record
    /// <summary>Cost of splitting a seg when choosing a partition (-factor)</summary>
    Factor: Integer;
    NoReject: Boolean;
    MiniWarnings: Boolean;
    ForceHexen: Boolean;
    PackSides: Boolean;
    Fast: Boolean;
    /// <summary>GL-Nodes specification: 1, 2, 3 or 5</summary>
    SpecVersion: Integer;
    /// <summary>Load every lump in memory instead of copying it on write</summary>
    LoadAll: Boolean;
    NoNormal: Boolean;
    ForceNormal: Boolean;
    /// <summary>Write only the new lumps (a GWA file)</summary>
    GwaMode: Boolean;
    PruneSect: Boolean;
    NoPrune: Boolean;
    MergeVert: Boolean;
    SkipSelfRef: Boolean;
    WindowFx: Boolean;
    BlockLimit: Integer;

    class function Default: TGlbspOptions; static;
  end;

implementation

{ TGlbspOptions }

class function TGlbspOptions.Default: TGlbspOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Factor := DEFAULT_FACTOR;
  Result.SpecVersion := DEFAULT_SPEC_VERSION;
  Result.BlockLimit := DEFAULT_BLOCK_LIMIT;
end;

end.
