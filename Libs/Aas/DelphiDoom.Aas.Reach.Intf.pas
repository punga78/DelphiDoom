{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - contracts of the reachability calculation         }
{                                                                              }
{  The functions of be_aas_reach.c that the rest of the botlib calls           }
{  (be_ai_goal.c, be_ai_move.c, be_aas_entity.c, be_aas_main.c). Based on the  }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Intf;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Reach.Types;

type
  /// <summary>The faces and the volumes of the areas: AAS_FaceArea, AAS_AreaVolume, AAS_AreaGroundFaceArea, AAS_FaceCenter</summary>
  IAasReachGeometry = interface
    ['{7A1D5C20-3E48-4B9F-A6D2-1C0E8B53F794}']
    /// <summary>AAS_FaceArea: the surface area of the face</summary>
    function FaceArea(const AFaceNum: Integer): Single;
    /// <summary>AAS_AreaVolume</summary>
    function AreaVolume(const AAreaNum: Integer): Single;
    /// <summary>AAS_AreaGroundFaceArea: the surface area of all the ground faces of the area together</summary>
    function AreaGroundFaceArea(const AAreaNum: Integer): Single;
    /// <summary>AAS_FaceCenter</summary>
    procedure FaceCenter(const AFaceNum: Integer; out ACenter: TVec3);
  end;

  /// <summary>What the player can do, from the settings: AAS_FallDamageDistance, AAS_FallDelta, AAS_MaxJumpHeight ...</summary>
  IAasReachPhysics = interface
    ['{7A1D5C20-3E48-4B9F-A6D2-1C0E8B53F795}']
    /// <summary>AAS_FallDamageDistance: the maximum distance a player can fall before being damaged (truncated to an integer)</summary>
    function FallDamageDistance: Integer;
    /// <summary>AAS_FallDelta: the fall damage of a fall of the distance</summary>
    function FallDelta(const ADistance: Single): Single;
    /// <summary>AAS_MaxJumpHeight</summary>
    function MaxJumpHeight(const APhysJumpVel: Single): Single;
    /// <summary>AAS_MaxJumpDistance</summary>
    function MaxJumpDistance(const APhysJumpVel: Single): Single;
    /// <summary>AAS_BarrierJumpTravelTime</summary>
    function BarrierJumpTravelTime: Word;
  end;

  /// <summary>The areas for goals and items: AAS_BestReachableArea, AAS_BestReachableLinkArea, AAS_BestReachableFromJumpPadArea</summary>
  IAasBestReachable = interface
    ['{7A1D5C20-3E48-4B9F-A6D2-1C0E8B53F796}']
    /// <summary>
    ///   AAS_BestReachableArea: the area for an item at the origin (a box of AMins..AMaxs around it); AGoalOrigin is the
    ///   point to go to
    /// </summary>
    function BestReachableArea(const AOrigin, AMins, AMaxs: TVec3; var AGoalOrigin: TVec3): Integer;
    /// <summary>
    ///   AAS_BestReachableLinkArea: the area of a list of links of an entity (the first link of the list, AAS_NO_LINK for
    ///   none) that is grounded or swimmable
    /// </summary>
    function BestReachableLinkArea(const ALinkHead: Integer): Integer;
    /// <summary>AAS_BestReachableFromJumpPadArea</summary>
    function BestReachableFromJumpPadArea(const AOrigin, AMins, AMaxs: TVec3): Integer;
  end;

  /// <summary>AAS_InitReachability and AAS_ContinueInitReachability</summary>
  IAasReachInitializer = interface
    ['{7A1D5C20-3E48-4B9F-A6D2-1C0E8B53F797}']
    /// <summary>AAS_InitReachability: nothing to do if the file has reachabilities and forcereachability is not set</summary>
    procedure InitReachability;
    /// <summary>
    ///   AAS_ContinueInitReachability: the next step; True while it is not finished (the step that stores the table also
    ///   gives True). The time is not used by the original
    /// </summary>
    function ContinueInitReachability(const ATime: Single): Boolean;
    function GetNumReachabilityAreas: Integer;
    function GetCounters: TAasReachCounters;
    /// <summary>numreachabilityareas: 1 at the start, numareas + 2 when it is all done</summary>
    property NumReachabilityAreas: Integer read GetNumReachabilityAreas;
    /// <summary>The numbers of reachabilities of each type</summary>
    property Counters: TAasReachCounters read GetCounters;
  end;

  /// <summary>
  ///   Replaces the table of the reachabilities of a file (AAS_StoreReachability allocates a new one). The settings of the
  ///   areas change in place
  /// </summary>
  IAasReachabilityEditor = interface
    ['{7A1D5C20-3E48-4B9F-A6D2-1C0E8B53F798}']
    procedure ReplaceReachability(const AReachability: TArray<TAasReachability>);
  end;

implementation

end.
