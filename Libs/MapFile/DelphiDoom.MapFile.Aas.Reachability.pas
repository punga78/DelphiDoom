{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - a reachability of an .aas file               }
{                                                                              }
{  Model of idReachability and idReachability_Special (AASFile.h), Doom 3 GPL  }
{  Source Code.                                                                }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Reachability;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Scanner.IdDict;

type
  /// <summary>
  ///   The movement from an area to another. The types of the original (walk, barrier jump,
  ///   water jump, walk off ledge, swim, fly, special) are one class told apart by
  ///   <c>TravelType</c> (one of the TFL_ flags); the special one has a dictionary, which the
  ///   others have not. The narrow types of the original are kept. The reachabilities that lead
  ///   to this one's area (<c>rev_next</c>) and the routing times (<c>areaTravelTimes</c>) belong to
  ///   the area and to the routing, not to the file
  /// </summary>
  TAasReachability = class
  strict private
    FTravelType: Integer;
    FToAreaNum: SmallInt;
    FFromAreaNum: SmallInt;
    FStart: TGeoVec3;
    FEnd: TGeoVec3;
    FEdgeNum: Integer;
    FTravelTime: Word;
    FNumber: Byte;
    FDisableCount: Byte;
    FSpecial: TIdDict;
  public
    destructor Destroy; override;
    /// <summary>Type of travel required to get to the area</summary>
    property TravelType: Integer read FTravelType write FTravelType;
    property ToAreaNum: SmallInt read FToAreaNum write FToAreaNum;
    property FromAreaNum: SmallInt read FFromAreaNum write FFromAreaNum;
    /// <summary>Start point of the inter area movement (start)</summary>
    property StartPoint: TGeoVec3 read FStart write FStart;
    property EndPoint: TGeoVec3 read FEnd write FEnd;
    /// <summary>The edge crossed by this reachability</summary>
    property EdgeNum: Integer read FEdgeNum write FEdgeNum;
    property TravelTime: Word read FTravelTime write FTravelTime;
    property Number: Byte read FNumber write FNumber;
    property DisableCount: Byte read FDisableCount write FDisableCount;
    /// <summary>The pairs of a special reachability (owned); nil for the others</summary>
    property Special: TIdDict read FSpecial;
    /// <summary>Gives the reachability its dictionary (TFL_SPECIAL); does nothing if it has one</summary>
    function EnsureSpecial: TIdDict;
  end;

implementation

{ TAasReachability }

destructor TAasReachability.Destroy;
begin
  FSpecial.Free;
  inherited Destroy;
end;

function TAasReachability.EnsureSpecial: TIdDict;
begin
  if not Assigned(FSpecial) then
    FSpecial := TIdDict.Create;
  Result := FSpecial;
end;

end.
