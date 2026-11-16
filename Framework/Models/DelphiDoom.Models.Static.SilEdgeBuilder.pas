{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - silhouette edges of a surface               }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\tr_trisurf.cpp  }
{  (R_DefineEdge, SilEdgeSort, R_IdentifySilEdges). Copyright (C) 1999-2011    }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Framework\IdLib); the repository as a whole is }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.SilEdgeBuilder;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Models.Static.Deform.Types;

const
  /// <summary>MAX_SIL_EDGES: a surface that has more edges loses the ones that do not fit (with a warning)</summary>
  STATIC_MAX_SIL_EDGES = $10000;
  /// <summary>SILEDGE_HASH_SIZE</summary>
  STATIC_SILEDGE_HASH_SIZE = 1024;

type
  /// <summary>
  ///   The silhouette edges of a surface (R_IdentifySilEdges): every edge between two vertexes
  ///   (as the silIndexes name them) with the two triangles that share it, or the triangle and the
  ///   "fake dangling" plane (the number of triangles) when it has only one side. Only the shadow
  ///   volumes use them. The coplanar-edge culling of the original is off in the original too
  ///   (<c>omitCoplanarEdges = false</c> "doesn't work for some reason") and is not ported.
  /// </summary>
  TStaticSilEdgeBuilder = class sealed
  public
    /// <summary>
    ///   The edges for the silIndexes (3 for every triangle), sorted by the two planes (p1, then
    ///   p2); edges with the same two planes stay in the order they were defined (the original
    ///   sorts them with qsort, which does not say). APerfectHull is true when every edge has two
    ///   sides. A direction used twice or an edge used by three triangles is a warning in ALog
    ///   (nil: silent) and still makes a new edge.
    /// </summary>
    class function Identify(const ASilIndexes: TArray<Integer>; out APerfectHull: Boolean;
      const ALog: IIdLibLog = nil): TArray<TStaticSilEdge>; static;
  end;

implementation

uses
  System.Generics.Collections,
  System.Generics.Defaults,
  DelphiDoom.IdLib.Containers.HashIndex;

{ TStaticSilEdgeBuilder }

class function TStaticSilEdgeBuilder.Identify(const ASilIndexes: TArray<Integer>; out APerfectHull: Boolean;
  const ALog: IIdLibLog): TArray<TStaticSilEdge>;
var
  LEdges: TList<TStaticSilEdge>;
  LHash: TIdHashIndex;
  LNumPlanes, LDuplicated, LTripled, LTriangle, LSingle, LItem: Integer;
  LOrder: TArray<Integer>;
  LCopy: TArray<TStaticSilEdge>;

  procedure DefineEdge(const AV1, AV2, APlane: Integer);
  var
    LKey, LIndex: Integer;
    LEdge: TStaticSilEdge;
  begin
    // a degenerate edge
    if AV1 = AV2 then
      Exit;
    LKey := LHash.GenerateKey(AV1, AV2);
    // look for a matching other side
    LIndex := LHash.First(LKey);
    while (LIndex >= 0) and (LIndex < STATIC_MAX_SIL_EDGES) do
    begin
      LEdge := LEdges[LIndex];
      if (LEdge.V1 = AV1) and (LEdge.V2 = AV2) then
        // it can still make a new edge
        Inc(LDuplicated)
      else if (LEdge.V2 = AV1) and (LEdge.V1 = AV2) then
      begin
        if LEdge.P2 <> LNumPlanes then
          // a third triangle on the edge: it can still make a new edge
          Inc(LTripled)
        else
        begin
          // this is a matching back side
          LEdge.P2 := APlane;
          LEdges[LIndex] := LEdge;
          Exit;
        end;
      end;
      LIndex := LHash.Next(LIndex);
    end;
    // define the new edge
    if LEdges.Count = STATIC_MAX_SIL_EDGES then
    begin
      if Assigned(ALog) then
        ALog.Warning('MAX_SIL_EDGES');
      Exit;
    end;
    LHash.Add(LKey, LEdges.Count);
    LEdge.P1 := APlane;
    LEdge.P2 := LNumPlanes;
    LEdge.V1 := AV1;
    LEdge.V2 := AV2;
    LEdges.Add(LEdge);
  end;

begin
  LNumPlanes := Length(ASilIndexes) div 3;
  LDuplicated := 0;
  LTripled := 0;
  LEdges := TList<TStaticSilEdge>.Create;
  // the hash needs room for 3 edges for every triangle at most
  LHash := TIdHashIndex.Create(STATIC_SILEDGE_HASH_SIZE, Length(ASilIndexes) + 1);
  try
    for LTriangle := 0 to LNumPlanes - 1 do
    begin
      DefineEdge(ASilIndexes[LTriangle * 3], ASilIndexes[LTriangle * 3 + 1], LTriangle);
      DefineEdge(ASilIndexes[LTriangle * 3 + 1], ASilIndexes[LTriangle * 3 + 2], LTriangle);
      DefineEdge(ASilIndexes[LTriangle * 3 + 2], ASilIndexes[LTriangle * 3], LTriangle);
    end;
    if ((LDuplicated <> 0) or (LTripled <> 0)) and Assigned(ALog) then
      ALog.Warning(Format('%d duplicated edge directions, %d tripled edges', [LDuplicated, LTripled]));
    // sort the edges by plane number; the position breaks the ties, so the order is the same everywhere
    LCopy := LEdges.ToArray;
    SetLength(LOrder, Length(LCopy));
    for LItem := 0 to High(LOrder) do
      LOrder[LItem] := LItem;
    TArray.Sort<Integer>(LOrder, TComparer<Integer>.Construct(
      function(const ALeft, ARight: Integer): Integer
      begin
        if LCopy[ALeft].P1 <> LCopy[ARight].P1 then
          Result := Ord(LCopy[ALeft].P1 > LCopy[ARight].P1) - Ord(LCopy[ALeft].P1 < LCopy[ARight].P1)
        else if LCopy[ALeft].P2 <> LCopy[ARight].P2 then
          Result := Ord(LCopy[ALeft].P2 > LCopy[ARight].P2) - Ord(LCopy[ALeft].P2 < LCopy[ARight].P2)
        else
          Result := Ord(ALeft > ARight) - Ord(ALeft < ARight);
      end));
    SetLength(Result, Length(LCopy));
    LSingle := 0;
    for LItem := 0 to High(LOrder) do
    begin
      Result[LItem] := LCopy[LOrder[LItem]];
      if Result[LItem].P2 = LNumPlanes then
        Inc(LSingle);
    end;
    // a perfectly built model has only shared edges; most have some dangling ones
    APerfectHull := LSingle = 0;
  finally
    LHash.Free;
    LEdges.Free;
  end;
end;

end.
