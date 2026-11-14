{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - clustering: constants and exception               }
{                                                                              }
{  Constants of be_aas_cluster.c. Based on the Quake III Arena GPL Source      }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Cluster.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>AAS_MAX_PORTALS, AAS_MAX_PORTALINDEXSIZE and AAS_MAX_CLUSTERS: the tables are made this large</summary>
  AAS_MAX_PORTALS = 65536;
  AAS_MAX_PORTALINDEXSIZE = 65536;
  AAS_MAX_CLUSTERS = 65536;
  /// <summary>MAX_PORTALAREAS: the areas of a possible portal, and of the lists that the search keeps</summary>
  MAX_PORTALAREAS = 1024;

type
  /// <summary>
  ///   The AAS file cannot be clustered or optimized: a number that the code uses as an index is outside the tables of
  ///   the file, a list of a possible portal is longer than MAX_PORTALAREAS (the C overflows its arrays), or the search
  ///   for clusters would never end (the C loops for ever)
  /// </summary>
  EAasClusterException = class(Exception);

implementation

end.
