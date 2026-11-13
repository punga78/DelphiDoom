{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - an area of an .aas file                      }
{                                                                              }
{  Model of aasArea_t (AASFile.h), Doom 3 GPL Source Code.                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Area;

interface

uses
  System.Generics.Collections, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Aas.Reachability;

type
  /// <summary>
  ///   An area with the boundary of faces that the file says (<c>FirstFace</c> and
  ///   <c>NumFaces</c> in the face index). The reachabilities that start here belong to the
  ///   area and are in the order of the chain of the original (<c>reach</c>, <c>next</c>), which
  ///   is the reverse of the order of the file; the ones that lead here are in the order of
  ///   <c>rev_reach</c> and belong to the areas they start from. <c>Bounds</c> and
  ///   <c>TravelFlags</c> are not in the file: the reader computes them as idAASFileLocal does
  /// </summary>
  TAasArea = class
  strict private
    FNumFaces: Integer;
    FFirstFace: Integer;
    FBounds: TGeoBounds;
    FFlags: Word;
    FContents: Word;
    FCluster: SmallInt;
    FClusterAreaNum: SmallInt;
    FTravelFlags: Integer;
    FReach: TObjectList<TAasReachability>;
    FReverseReach: TList<TAasReachability>;
  public
    constructor Create;
    destructor Destroy; override;
    property NumFaces: Integer read FNumFaces write FNumFaces;
    property FirstFace: Integer read FFirstFace write FFirstFace;
    property Bounds: TGeoBounds read FBounds write FBounds;
    /// <summary>The AREA_ flags</summary>
    property Flags: Word read FFlags write FFlags;
    /// <summary>The AREACONTENTS_ flags</summary>
    property Contents: Word read FContents write FContents;
    /// <summary>The cluster the area belongs to; if negative it is a portal</summary>
    property Cluster: SmallInt read FCluster write FCluster;
    property ClusterAreaNum: SmallInt read FClusterAreaNum write FClusterAreaNum;
    /// <summary>The TFL_ flags for travelling through the area (TFL_WATER or TFL_AIR after a read)</summary>
    property TravelFlags: Integer read FTravelFlags write FTravelFlags;
    /// <summary>The reachabilities that start from this area (owned)</summary>
    property Reach: TObjectList<TAasReachability> read FReach;
    /// <summary>The reachabilities that lead to this area (not owned)</summary>
    property ReverseReach: TList<TAasReachability> read FReverseReach;
  end;

implementation

{ TAasArea }

constructor TAasArea.Create;
begin
  inherited Create;
  FReach := TObjectList<TAasReachability>.Create(True);
  FReverseReach := TList<TAasReachability>.Create;
end;

destructor TAasArea.Destroy;
begin
  FReverseReach.Free;
  FReach.Free;
  inherited Destroy;
end;

end.
