{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - contract of the clustering and of the optimizer   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Cluster.Intf;

interface

type
  /// <summary>AAS_InitClustering on a file that is loaded</summary>
  IAasClusterInitializer = interface
    ['{6C2D4F18-9A57-4E3B-B1D6-0E8A3F5C7B22}']
    /// <summary>
    ///   Makes the portals and the clusters (and the numbers of the areas in them). False if the file already has
    ///   clusters and neither forceclustering nor forcereachability is set: nothing is done
    /// </summary>
    function InitClustering: Boolean;
  end;

  /// <summary>AAS_Optimize: keeps of the geometry only what the bots need (the ladder faces)</summary>
  IAasOptimizer = interface
    ['{6C2D4F18-9A57-4E3B-B1D6-0E8A3F5C7B23}']
    procedure Optimize;
  end;

implementation

end.
