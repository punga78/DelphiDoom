{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - contract of the navigator (idAAS)       }
{                                                                              }
{  Port of the class idAAS and of idAASCallback (AAS.h), Doom 3 GPL Source     }
{  Code. Based on the Doom 3 GPL Source Code (id Software). Copyright (C)      }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3 or (at your option) any later version,    }
{  with the additional terms of the Doom 3 Source Code License                 }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Intf;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Plane,
  DelphiDoom.MapFile.Aas.Reachability, DelphiDoom.MapFile.Aas.Settings, DelphiDoom.MapFile.Aas.Trace,
  DelphiDoom.Aas.D3.Types;

type
  IAasNavigator = interface;

  /// <summary>
  ///   idAASCallback: the test that FindNearestGoal calls for a candidate area. The only call through
  ///   an interface that the search makes for an area, as in the original (a virtual call)
  /// </summary>
  IAasAreaCallback = interface
    ['{7A1E5C20-3B84-4D6F-8E19-0C5A9D2F4B01}']
    function TestArea(const ANavigator: IAasNavigator; const AAreaNum: Integer): Boolean;
  end;

  /// <summary>
  ///   idAAS: the navigation of the AI on a loaded .aas file: areas, travel times, routes and paths.
  ///   A navigator without a file answers like the original when <c>file</c> is NULL (nothing is
  ///   reachable, paths are straight). The reachabilities that are returned belong to the file
  /// </summary>
  IAasNavigator = interface
    ['{7A1E5C20-3B84-4D6F-8E19-0C5A9D2F4B02}']
    /// <summary>The settings the file was built with; nil without a file</summary>
    function GetSettings: TAasSettings;
    /// <summary>The number of the area the origin is in; 0 in solid or without a file</summary>
    function PointAreaNum(const AOrigin: TGeoVec3): Integer;
    function PointReachableAreaNum(const AOrigin: TGeoVec3; const ASearchBounds: TGeoBounds;
      const AAreaFlags: Integer): Integer;
    function BoundsReachableAreaNum(const ABounds: TGeoBounds; const AAreaFlags: Integer): Integer;
    procedure PushPointIntoAreaNum(const AAreaNum: Integer; var AOrigin: TGeoVec3);
    /// <summary>A reachable point inside the area (the centre kept at load)</summary>
    function AreaCenter(const AAreaNum: Integer): TGeoVec3;
    function AreaFlags(const AAreaNum: Integer): Integer;
    function AreaTravelFlags(const AAreaNum: Integer): Integer;
    function Trace(var ATrace: TAasTrace; const AStart, AEnd: TGeoVec3): Boolean;
    function GetPlane(const APlaneNum: Integer): TGeoPlane;
    /// <summary>The edges of the walls around the area inside the bounds; returns how many were stored (at most AMaxEdges)</summary>
    function GetWallEdges(const AAreaNum: Integer; const ABounds: TGeoBounds; const ATravelFlags: Integer;
      var AEdges: TArray<Integer>; const AMaxEdges: Integer): Integer;
    procedure SortWallEdges(var AEdges: TArray<Integer>; const ANumEdges: Integer);
    procedure GetEdgeVertexNumbers(const AEdgeNum: Integer; out AVertex0, AVertex1: Integer);
    procedure GetEdge(const AEdgeNum: Integer; out AStart, AEnd: TGeoVec3);
    /// <summary>Disables or enables the areas with the contents given that are in or touch the bounds</summary>
    function SetAreaState(const ABounds: TGeoBounds; const AAreaContents: Integer; const ADisabled: Boolean): Boolean;
    /// <summary>Adds an obstacle to the routing and returns its handle (-1 without a file)</summary>
    function AddObstacle(const ABounds: TGeoBounds): Integer;
    procedure RemoveObstacle(const AHandle: Integer);
    procedure RemoveAllObstacles;
    /// <summary>The travel time to the goal area in 100th of a second; 0 if there is no route</summary>
    function TravelTimeToGoalArea(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum,
      ATravelFlags: Integer): Integer;
    /// <summary>The travel time and the first reachability to use towards the goal; False if there is no route</summary>
    function RouteToGoalArea(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum,
      ATravelFlags: Integer; out ATravelTime: Integer; out AReach: TAasReachability): Boolean;
    function WalkPathToGoal(out APath: TAasPath; const AAreaNum: Integer; const AOrigin: TGeoVec3;
      const AGoalAreaNum: Integer; const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer): Boolean;
    function WalkPathValid(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum: Integer;
      const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer; out AEndPos: TGeoVec3;
      out AEndAreaNum: Integer): Boolean;
    function FlyPathToGoal(out APath: TAasPath; const AAreaNum: Integer; const AOrigin: TGeoVec3;
      const AGoalAreaNum: Integer; const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer): Boolean;
    function FlyPathValid(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum: Integer;
      const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer; out AEndPos: TGeoVec3;
      out AEndAreaNum: Integer): Boolean;
    /// <summary>
    ///   The nearest area that the callback accepts. <c>AObstacles</c> gets the expanded bounds filled
    ///   (idAAS::FindNearestGoal does so in its argument)
    /// </summary>
    function FindNearestGoal(out AGoal: TAasGoal; const AAreaNum: Integer; const AOrigin, ATarget: TGeoVec3;
      const ATravelFlags: Integer; var AObstacles: array of TAasObstacle;
      const ACallback: IAasAreaCallback): Boolean;
  end;

  /// <summary>
  ///   A navigator that loads the AAS of a map (idAASLocal::Init and Shutdown), with the queries of
  ///   <c>IAasNavigator</c>. Hold it as an interface: the navigator passes itself to the callback of
  ///   <c>FindNearestGoal</c>
  /// </summary>
  IAasMapNavigator = interface(IAasNavigator)
    ['{7A1E5C20-3B84-4D6F-8E19-0C5A9D2F4B03}']
    /// <summary>
    ///   Loads the AAS of the map; if the file loaded is the one asked for (name and CRC) it is kept and the
    ///   obstacles are removed. False, with a warning, if it cannot be loaded or is not fit for routing
    /// </summary>
    function Init(const AMapName: AnsiString; const AMapFileCrc: Cardinal): Boolean;
    /// <summary>Frees the file and the routing data (idAASLocal::Shutdown)</summary>
    procedure Shutdown;
  end;

implementation

end.
