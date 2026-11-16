{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - one entry of the routing cache                    }
{                                                                              }
{  Port of aas_routingcache_t and aas_routingupdate_t (be_aas_def.h). Based    }
{  on the Quake III Arena GPL Source Code (id Software). Copyright (C)         }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Route.Cache;

interface

type
  /// <summary>
  ///   The travel times from the areas of a cluster (area cache) or from the portals (portal cache) towards one goal
  ///   area, with the travel flags that were allowed. <c>Next</c> and <c>Prev</c> link the caches of one area,
  ///   <c>TimeNext</c> and <c>TimePrev</c> the list from the oldest to the newest. The store owns the entries
  /// </summary>
  TAasRouteCache = class
  public
    /// <summary>ROUTE_CACHETYPE_PORTAL or ROUTE_CACHETYPE_AREA</summary>
    Kind: Integer;
    Size: Integer;
    Cluster: Integer;
    AreaNum: Integer;
    TravelFlags: Integer;
    StartTravelTime: Word;
    Prev: TAasRouteCache;
    Next: TAasRouteCache;
    TimePrev: TAasRouteCache;
    TimeNext: TAasRouteCache;
    /// <summary>The number of the reachability to take (inside the area), for every area; never set in a portal cache</summary>
    Reachabilities: TArray<Byte>;
    TravelTimes: TArray<Word>;
    /// <summary>
    ///   The memory the original counts: the structure (with its first travel time) and the tables. A table has
    ///   at least one entry, as the structure has one
    /// </summary>
    constructor Create(const ANumTravelTimes: Integer);
  end;

  /// <summary>aas_routingupdate_t: an area in the list of the areas to update, linked by index (-1 ends a list)</summary>
  TAasRouteUpdate = record
    Cluster: Integer;
    AreaNum: Integer;
    TmpTravelTime: Word;
    /// <summary>The first entry in the travel times of the route data of the row to use; -1 is a row of zeros</summary>
    TravelTimesRow: Integer;
    Next: Integer;
    Prev: Integer;
    InList: Boolean;
  end;

implementation

uses
  DelphiDoom.Aas.Route.Types;

{ TAasRouteCache }

constructor TAasRouteCache.Create(const ANumTravelTimes: Integer);
begin
  inherited Create;
  SetLength(Reachabilities, ANumTravelTimes);
  SetLength(TravelTimes, ANumTravelTimes);
  Size := ROUTE_CACHE_HEADER_SIZE + ANumTravelTimes * SizeOf(Word) + ANumTravelTimes * SizeOf(Byte);
end;

end.
