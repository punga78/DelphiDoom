{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - contract to replace tables of an AAS file         }
{                                                                              }
{  The clustering (be_aas_cluster.c) and the optimizer (be_aas_optimize.c)     }
{  write new tables into aasworld. Based on the Quake III Arena GPL Source     }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Editor.Intf;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types;

type
  /// <summary>
  ///   Replaces whole tables of a file that is loaded. The getters of <c>IAasFile</c> give the arrays themselves
  ///   (not copies), so the elements of the area settings and of the reachabilities are changed in place; a table
  ///   that changes its length goes through this interface
  /// </summary>
  IAasFileEditor = interface
    ['{6C2D4F18-9A57-4E3B-B1D6-0E8A3F5C7B21}']
    /// <summary>The portals, the portal index and the clusters (aasworld.portals, portalindex, clusters)</summary>
    procedure ReplaceClusterData(const AClusters: TArray<TAasCluster>; const APortals: TArray<TAasPortal>;
      const APortalIndex: TArray<Integer>);
    /// <summary>The geometry that AAS_Optimize rewrites</summary>
    procedure ReplaceGeometry(const AVertexes: TArray<TVec3>; const AEdges: TArray<TAasEdge>;
      const AEdgeIndex: TArray<Integer>; const AFaces: TArray<TAasFace>; const AFaceIndex: TArray<Integer>;
      const AAreas: TArray<TAasArea>);
  end;

implementation

end.
