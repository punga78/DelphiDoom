{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - contracts of the AAS system (be_aas_main.c)        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Main.Intf;

interface

uses
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Links, DelphiDoom.Aas.Bsp.Intf;

type
  /// <summary>The flags and the clock of aasworld that the entities and the initialization read</summary>
  IAasFrameState = interface
    ['{6C4F1B33-2D70-4A96-B1E5-8F03A7D26C20}']
    function GetLoaded: Boolean;
    function GetInitialized: Boolean;
    function GetTime: Single;
    function GetNumFrames: Integer;
    /// <summary>aasworld.loaded: an AAS file is in memory</summary>
    property Loaded: Boolean read GetLoaded;
    /// <summary>aasworld.initialized: the reachabilities, the clusters and the routing are ready</summary>
    property Initialized: Boolean read GetInitialized;
    /// <summary>AAS_Time: the time of the last AAS_StartFrame</summary>
    property Time: Single read GetTime;
    /// <summary>aasworld.numframes: the frames since AAS_Setup</summary>
    property NumFrames: Integer read GetNumFrames;
  end;

  /// <summary>
  ///   The steps that AAS_LoadMap and AAS_ContinueInit take on a loaded file, behind the classes that implement
  ///   them (the reachabilities, the clusters and the routing): the system does not know them
  /// </summary>
  IAasInitSteps = interface
    ['{6C4F1B33-2D70-4A96-B1E5-8F03A7D26C21}']
    /// <summary>AAS_InitSettings</summary>
    procedure InitSettings;
    /// <summary>AAS_InitReachability: the heap and the lists; no area is calculated yet</summary>
    procedure InitReachability;
    /// <summary>
    ///   AAS_ContinueInitReachability: calculates the reachabilities of some more areas; True while there is more to
    ///   do (the system comes back at the next frame)
    /// </summary>
    function ContinueInitReachability(const ATime: Single): Boolean;
    /// <summary>AAS_InitClustering</summary>
    procedure InitClustering;
    /// <summary>AAS_Optimize, when the library variable aasoptimize asks for it</summary>
    procedure Optimize;
    /// <summary>AAS_InitRouting</summary>
    procedure InitRouting;
    /// <summary>AAS_InitAlternativeRouting</summary>
    procedure InitAlternativeRouting;
    /// <summary>aasworld.savefile: the reachabilities were calculated, not read, so the file should be written</summary>
    function SaveFile: Boolean;
    /// <summary>AAS_FreeRoutingCaches and the like: before the next map or at the end</summary>
    procedure FreeRouting;
  end;

  /// <summary>What is made of a loaded file: the file, its entity links and the steps of the initialization</summary>
  IAasMap = interface
    ['{6C4F1B33-2D70-4A96-B1E5-8F03A7D26C22}']
    function GetFile: IAasFile;
    function GetLinks: TAasEntityLinks;
    function GetSteps: IAasInitSteps;
    property AasFile: IAasFile read GetFile;
    property Links: TAasEntityLinks read GetLinks;
    property Steps: IAasInitSteps read GetSteps;
  end;

  /// <summary>Makes the map of a loaded file (the composition root knows the classes)</summary>
  IAasMapBuilder = interface
    ['{6C4F1B33-2D70-4A96-B1E5-8F03A7D26C23}']
    /// <summary>The links of the entities have AMaxLinks entries (the library variable max_aaslinks)</summary>
    function Build(const AFile: IAasFile; const AMaxLinks: Integer; const AEntities: IAasBspEntities): IAasMap;
  end;

implementation

end.
