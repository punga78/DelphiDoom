{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - one entry of the routing cache          }
{                                                                              }
{  Port of idRoutingCache and idRoutingUpdate (AAS_local.h), Doom 3 GPL        }
{  Source Code.                                                                }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Framework\IdLib); the repository as a whole is }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.RoutingCache;

interface

uses
  DelphiDoom.Geometry.Vec3;

type
  /// <summary>
  ///   The travel times and the reachabilities to use from every area of a cluster (or every portal)
  ///   towards one goal area, with the travel flags that were allowed. The links are the lists of the
  ///   original: <c>Next</c> and <c>Prev</c> in the list of the caches of an area, <c>TimeNext</c>
  ///   and <c>TimePrev</c> in the list sorted from the oldest to the newest. The store owns the entries
  /// </summary>
  TAasRoutingCache = class
  public
    /// <summary>AAS_CACHETYPE_AREA or AAS_CACHETYPE_PORTAL</summary>
    Kind: Integer;
    /// <summary>The number of entries in the arrays</summary>
    Size: Integer;
    Cluster: Integer;
    AreaNum: Integer;
    TravelFlags: Integer;
    Next: TAasRoutingCache;
    Prev: TAasRoutingCache;
    TimeNext: TAasRoutingCache;
    TimePrev: TAasRoutingCache;
    StartTravelTime: Word;
    /// <summary>The number of the reachability to use, for every area (or portal)</summary>
    Reachabilities: TArray<Byte>;
    /// <summary>The travel time for every area (or portal); 0 if the goal is not reachable from it</summary>
    TravelTimes: TArray<Word>;
    constructor Create(const ASize: Integer);
    /// <summary>
    ///   Size(): the memory the original counts for the entry, with the size of its 32 bit class (see
    ///   AAS_ROUTING_CACHE_HEADER_SIZE)
    /// </summary>
    function Footprint: Integer;
  end;

  /// <summary>
  ///   idRoutingUpdate: an area or a portal in the list of the areas to update by the flood of the
  ///   routing. The lists are made of indices into an array of updates (-1 ends a list), as the
  ///   original links the elements of an array
  /// </summary>
  TAasRoutingUpdate = record
    Cluster: Integer;
    AreaNum: Integer;
    TmpTravelTime: Word;
    /// <summary>The index in the travel times of the topology of the row to use; -1 is a row of zeros</summary>
    TravelTimesRow: Integer;
    Start: TGeoVec3;
    Next: Integer;
    Prev: Integer;
    IsInList: Boolean;
  end;

implementation

uses
  DelphiDoom.Aas.D3.Types;

{ TAasRoutingCache }

constructor TAasRoutingCache.Create(const ASize: Integer);
begin
  inherited Create;
  Size := ASize;
  SetLength(Reachabilities, ASize);
  SetLength(TravelTimes, ASize);
end;

function TAasRoutingCache.Footprint: Integer;
begin
  Result := AAS_ROUTING_CACHE_HEADER_SIZE + Size * SizeOf(Byte) + Size * SizeOf(Word);
end;

end.
