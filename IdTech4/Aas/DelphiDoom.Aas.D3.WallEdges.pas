{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - edges of the walls around an area       }
{                                                                              }
{  Port of idAASLocal::GetWallEdges, SortWallEdges, GetEdgeVertexNumbers and   }
{  GetEdge (AAS.cpp, AAS_pathing.cpp), Doom 3 GPL Source Code.                 }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Framework\IdLib); the repository as a whole is }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.WallEdges;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Aas.D3.Topology;

type
  /// <summary>The edges of the floor of an area that are not shared with another floor face and not used by a reachability</summary>
  TAasWallEdges = class
  strict private
    FTopology: TAasTopology;
    procedure CheckEdge(const AEdgeNum: Integer);
  public
    constructor Create(const ATopology: TAasTopology);
    /// <summary>
    ///   The numbers of the wall edges of the area and of the areas that can be reached from it with
    ///   the travel flags and touch the bounds; the edges go in <c>AEdges</c> (which holds at least
    ///   <c>AMaxEdges</c> entries) and the result is how many there are
    /// </summary>
    function GetWallEdges(const AAreaNum: Integer; const ABounds: TGeoBounds; const ATravelFlags: Integer;
      var AEdges: TArray<Integer>; const AMaxEdges: Integer): Integer;
    /// <summary>Puts the edges in sequences in which the end of an edge is the start of the next one</summary>
    procedure SortWallEdges(var AEdges: TArray<Integer>; const ANumEdges: Integer);
    /// <summary>The numbers of the vertices of the edge, swapped if the number of the edge is negative</summary>
    procedure GetEdgeVertexNumbers(const AEdgeNum: Integer; out AVertex0, AVertex1: Integer);
    procedure GetEdge(const AEdgeNum: Integer; out AStart, AEnd: TGeoVec3);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.FloatMath, DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area,
  DelphiDoom.MapFile.Aas.Reachability, DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.Aas.D3.Types;

resourcestring
  SEdgeOutOfRange = 'AAS edge %d is not in the file';
  SFaceOutOfRange = 'AAS face %d or one of its edges is not in the file';
  SWallEdgeLimit = 'AAS wall edges: more edges than the array can hold';

type
  TWallEdge = record
    EdgeNum: Integer;
    Verts: array[0..1] of Integer;
    Next: Integer;
  end;

{ TAasWallEdges }

constructor TAasWallEdges.Create(const ATopology: TAasTopology);
begin
  inherited Create;
  FTopology := ATopology;
end;

procedure TAasWallEdges.CheckEdge(const AEdgeNum: Integer);
begin
  if (Abs(AEdgeNum) < 0) or (Abs(AEdgeNum) >= FTopology.AasFile.NumEdges) then
    raise EAasRoutingException.Create(Format(SEdgeOutOfRange, [AEdgeNum]));
end;

procedure TAasWallEdges.GetEdgeVertexNumbers(const AEdgeNum: Integer; out AVertex0, AVertex1: Integer);
var
  LEdge: TAasEdge;
begin
  CheckEdge(AEdgeNum);
  LEdge := FTopology.AasFile.Edges[Abs(AEdgeNum)];
  AVertex0 := LEdge.VertexNum[TGeoMath.IntSignBitSet(AEdgeNum)];
  AVertex1 := LEdge.VertexNum[TGeoMath.IntSignBitNotSet(AEdgeNum)];
end;

procedure TAasWallEdges.GetEdge(const AEdgeNum: Integer; out AStart, AEnd: TGeoVec3);
var
  LVertex0, LVertex1: Integer;
begin
  GetEdgeVertexNumbers(AEdgeNum, LVertex0, LVertex1);
  AStart := FTopology.AasFile.Vertices[LVertex0];
  AEnd := FTopology.AasFile.Vertices[LVertex1];
end;

procedure TAasWallEdges.SortWallEdges(var AEdges: TArray<Integer>; const ANumEdges: Integer);
var
  LIndex, LOther, LK, LNumSequences, LWallEdge, LPosition: Integer;
  LWallEdges: TArray<TWallEdge>;
  LSequenceFirst, LSequenceLast: TArray<Integer>;
begin
  SetLength(LWallEdges, ANumEdges);
  SetLength(LSequenceFirst, ANumEdges);
  SetLength(LSequenceLast, ANumEdges);

  for LIndex := 0 to ANumEdges - 1 do
  begin
    LWallEdges[LIndex].EdgeNum := AEdges[LIndex];
    GetEdgeVertexNumbers(AEdges[LIndex], LWallEdges[LIndex].Verts[0], LWallEdges[LIndex].Verts[1]);
    LWallEdges[LIndex].Next := -1;
    LSequenceFirst[LIndex] := LIndex;
    LSequenceLast[LIndex] := LIndex;
  end;
  LNumSequences := ANumEdges;

  LIndex := 0;
  while LIndex < LNumSequences do
  begin
    LOther := LIndex + 1;
    while LOther < LNumSequences do
    begin
      if LWallEdges[LSequenceFirst[LIndex]].Verts[0] = LWallEdges[LSequenceLast[LOther]].Verts[1] then
      begin
        LWallEdges[LSequenceLast[LOther]].Next := LSequenceFirst[LIndex];
        LSequenceFirst[LIndex] := LSequenceFirst[LOther];
        Break;
      end;
      if LWallEdges[LSequenceLast[LIndex]].Verts[1] = LWallEdges[LSequenceFirst[LOther]].Verts[0] then
      begin
        LWallEdges[LSequenceLast[LIndex]].Next := LSequenceFirst[LOther];
        Break;
      end;
      Inc(LOther);
    end;
    if LOther < LNumSequences then
    begin
      Dec(LNumSequences);
      for LK := LOther to LNumSequences - 1 do
      begin
        LSequenceFirst[LK] := LSequenceFirst[LK + 1];
        LSequenceLast[LK] := LSequenceLast[LK + 1];
      end;
      LIndex := -1;
    end;
    Inc(LIndex);
  end;

  LPosition := 0;
  for LIndex := 0 to LNumSequences - 1 do
  begin
    LWallEdge := LSequenceFirst[LIndex];
    while LWallEdge >= 0 do
    begin
      AEdges[LPosition] := LWallEdges[LWallEdge].EdgeNum;
      Inc(LPosition);
      LWallEdge := LWallEdges[LWallEdge].Next;
    end;
  end;
end;

function TAasWallEdges.GetWallEdges(const AAreaNum: Integer; const ABounds: TGeoBounds; const ATravelFlags: Integer;
  var AEdges: TArray<Integer>; const AMaxEdges: Integer): Integer;
var
  LIndex, LJ, LK, LL, LFace1Num, LFace2Num, LEdge1Num, LEdge2Num, LNumEdges, LAbsEdge1Num: Integer;
  LQueueStart, LQueueEnd, LCurArea: Integer;
  LAreaQueue: TArray<Integer>;
  LAreasVisited: TArray<Boolean>;
  LArea: TAasArea;
  LFace1, LFace2: TAasFace;
  LReach: TAasReachability;
  LFile: TAasFile;
  LUsed: Boolean;
begin
  LFile := FTopology.AasFile;
  LNumEdges := 0;

  SetLength(LAreasVisited, FTopology.NumAreas);
  SetLength(LAreaQueue, FTopology.NumAreas);

  LQueueStart := -1;
  LQueueEnd := 0;
  LAreaQueue[0] := AAreaNum;
  LAreasVisited[AAreaNum] := True;

  LCurArea := AAreaNum;
  while LQueueStart < LQueueEnd do
  begin
    LArea := FTopology.Areas[LCurArea];

    for LIndex := 0 to LArea.NumFaces - 1 do
    begin
      LFace1Num := LFile.FaceIndex[LArea.FirstFace + LIndex];
      LFace1 := LFile.Faces[Abs(LFace1Num)];

      if (LFace1.Flags and FACE_FLOOR) = 0 then
        Continue;

      for LJ := 0 to LFace1.NumEdges - 1 do
      begin
        LEdge1Num := LFile.EdgeIndex[LFace1.FirstEdge + LJ];
        LAbsEdge1Num := Abs(LEdge1Num);

        // test if the edge is shared by another floor face of this area
        LK := 0;
        while LK < LArea.NumFaces do
        begin
          if LK <> LIndex then
          begin
            LFace2Num := LFile.FaceIndex[LArea.FirstFace + LK];
            LFace2 := LFile.Faces[Abs(LFace2Num)];

            if (LFace2.Flags and FACE_FLOOR) <> 0 then
            begin
              LL := 0;
              while LL < LFace2.NumEdges do
              begin
                LEdge2Num := Abs(LFile.EdgeIndex[LFace2.FirstEdge + LL]);
                if LEdge2Num = LAbsEdge1Num then
                  Break;
                Inc(LL);
              end;
              if LL < LFace2.NumEdges then
                Break;
            end;
          end;
          Inc(LK);
        end;
        if LK < LArea.NumFaces then
          Continue;

        // test if the edge is used by a reachability
        LUsed := False;
        for LReach in FTopology.Reach[LCurArea] do
          if (LReach.TravelType and ATravelFlags) <> 0 then
            if LReach.EdgeNum = LAbsEdge1Num then
            begin
              LUsed := True;
              Break;
            end;
        if LUsed then
          Continue;

        // test if the edge is already in the list
        LK := 0;
        while LK < LNumEdges do
        begin
          if LEdge1Num = AEdges[LK] then
            Break;
          Inc(LK);
        end;
        if LK < LNumEdges then
          Continue;

        // add the edge to the list
        AEdges[LNumEdges] := LEdge1Num;
        Inc(LNumEdges);
        if LNumEdges >= AMaxEdges then
          Exit(LNumEdges);
      end;
    end;

    // add new areas to the queue
    for LReach in FTopology.Reach[LCurArea] do
      if (LReach.TravelType and ATravelFlags) <> 0 then
        // if the area the reachability leads to hasn't been visited yet and the area bounds touch the search bounds
        if (not LAreasVisited[LReach.ToAreaNum]) and ABounds.IntersectsBounds(FTopology.Areas[LReach.ToAreaNum].Bounds) then
        begin
          // areaQueue[queueEnd++]: the first one overwrites the start area, which was already taken
          LAreaQueue[LQueueEnd] := LReach.ToAreaNum;
          Inc(LQueueEnd);
          LAreasVisited[LReach.ToAreaNum] := True;
        end;

    Inc(LQueueStart);
    LCurArea := LAreaQueue[LQueueStart];
  end;
  Result := LNumEdges;
end;

end.
