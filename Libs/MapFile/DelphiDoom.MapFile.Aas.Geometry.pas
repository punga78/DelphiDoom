{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the shapes that follow from an .aas file     }
{                                                                              }
{  Port of EdgeCenter, FaceCenter, AreaCenter, EdgeBounds, FaceBounds,         }
{  AreaBounds, AreaContentsTravelFlags and MaxTreeDepth of idAASFileLocal      }
{  (AASFile_sample.cpp), Doom 3 GPL Source Code.                               }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Geometry;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Aas.AasFile;

type
  /// <summary>
  ///   Centres, bounds and the depth of the tree, computed from the lists of the file. The
  ///   original indexes its lists with whatever the file says; here an index outside its list
  ///   is an EAasFileException (a file the original reads and then crashes on)
  /// </summary>
  TAasGeometry = class
  strict private
    class function EdgeVertex(const AFile: TAasFile; const AEdgeNum, ASide: Integer): TGeoVec3; static;
    class function VertexOfEdge(const AFile: TAasFile; const AEdgeEntry: Integer): TGeoVec3; static;
    class procedure CheckIndex(const AWhat: string; const AIndex, ACount: Integer); static;
  public
    class function EdgeCenter(const AFile: TAasFile; const AEdgeNum: Integer): TGeoVec3; static;
    class function FaceCenter(const AFile: TAasFile; const AFaceNum: Integer): TGeoVec3; static;
    /// <summary>The mean of the centres of the faces (not the reachable goal, which needs a trace)</summary>
    class function AreaCenter(const AFile: TAasFile; const AAreaNum: Integer): TGeoVec3; static;
    class function EdgeBounds(const AFile: TAasFile; const AEdgeNum: Integer): TGeoBounds; static;
    class function FaceBounds(const AFile: TAasFile; const AFaceNum: Integer): TGeoBounds; static;
    class function AreaBounds(const AFile: TAasFile; const AAreaNum: Integer): TGeoBounds; static;
    /// <summary>TFL_WATER if the contents have AREACONTENTS_WATER, TFL_AIR otherwise</summary>
    class function AreaContentsTravelFlags(const AContents: Integer): Integer; static;
    /// <summary>
    ///   The depth of the tree from node 1 (node 0 is the solid dummy); 0 when the tree has no
    ///   node 1. A node reached twice (a cycle, or a node with two parents) is an error: the
    ///   original would loop or take exponential time
    /// </summary>
    class function MaxTreeDepth(const AFile: TAasFile): Integer; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area;

resourcestring
  SBadIndex = '%s %d is not in 0..%d';
  SNodeReachedTwice = 'node %d is reached twice in the tree';
  SChildOutOfRange = 'child %d of the tree is not a node (0..%d)';

{ TAasGeometry }

class procedure TAasGeometry.CheckIndex(const AWhat: string; const AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise EAasFileException.Create(Format(SBadIndex, [AWhat, AIndex, ACount - 1]));
end;

class function TAasGeometry.EdgeVertex(const AFile: TAasFile; const AEdgeNum, ASide: Integer): TGeoVec3;
begin
  CheckIndex('edge', AEdgeNum, AFile.NumEdges);
  CheckIndex('vertex', AFile.Edges[AEdgeNum].VertexNum[ASide], AFile.NumVertices);
  Result := AFile.Vertices[AFile.Edges[AEdgeNum].VertexNum[ASide]];
end;

class function TAasGeometry.VertexOfEdge(const AFile: TAasFile; const AEdgeEntry: Integer): TGeoVec3;
var
  LSide: Integer;
begin
  // a negative entry of the edge index is the edge walked backwards: INTSIGNBITSET
  if AEdgeEntry < 0 then
    LSide := 1
  else
    LSide := 0;
  Result := EdgeVertex(AFile, Abs(AEdgeEntry), LSide);
end;

class function TAasGeometry.EdgeCenter(const AFile: TAasFile; const AEdgeNum: Integer): TGeoVec3;
begin
  Result := (EdgeVertex(AFile, AEdgeNum, 0) + EdgeVertex(AFile, AEdgeNum, 1)) * Single(0.5);
end;

class function TAasGeometry.FaceCenter(const AFile: TAasFile; const AFaceNum: Integer): TGeoVec3;
var
  LFace: TAasFace;
  LIndex, LEntry: Integer;
begin
  CheckIndex('face', AFaceNum, AFile.NumFaces);
  Result := TGeoVec3.Origin;
  LFace := AFile.Faces[AFaceNum];
  if LFace.NumEdges > 0 then
  begin
    for LIndex := 0 to LFace.NumEdges - 1 do
    begin
      CheckIndex('edge index', LFace.FirstEdge + LIndex, Length(AFile.EdgeIndex));
      LEntry := AFile.EdgeIndex[LFace.FirstEdge + LIndex];
      Result := Result + VertexOfEdge(AFile, LEntry);
    end;
    // idVec3::operator/= multiplies by the inverse
    Result := Result * (Single(1.0) / Single(LFace.NumEdges));
  end;
end;

class function TAasGeometry.AreaCenter(const AFile: TAasFile; const AAreaNum: Integer): TGeoVec3;
var
  LArea: TAasArea;
  LIndex, LFaceNum: Integer;
begin
  CheckIndex('area', AAreaNum, AFile.NumAreas);
  Result := TGeoVec3.Origin;
  LArea := AFile.Areas[AAreaNum];
  if LArea.NumFaces > 0 then
  begin
    for LIndex := 0 to LArea.NumFaces - 1 do
    begin
      CheckIndex('face index', LArea.FirstFace + LIndex, Length(AFile.FaceIndex));
      LFaceNum := AFile.FaceIndex[LArea.FirstFace + LIndex];
      Result := Result + FaceCenter(AFile, Abs(LFaceNum));
    end;
    Result := Result * (Single(1.0) / Single(LArea.NumFaces));
  end;
end;

class function TAasGeometry.EdgeBounds(const AFile: TAasFile; const AEdgeNum: Integer): TGeoBounds;
var
  LEdgeNum: Integer;
begin
  LEdgeNum := Abs(AEdgeNum);
  CheckIndex('edge', LEdgeNum, AFile.NumEdges);
  Result := TGeoBounds.Cleared;
  Result.AddPoint(EdgeVertex(AFile, LEdgeNum, 0));
  Result.AddPoint(EdgeVertex(AFile, LEdgeNum, 1));
end;

class function TAasGeometry.FaceBounds(const AFile: TAasFile; const AFaceNum: Integer): TGeoBounds;
var
  LFace: TAasFace;
  LIndex: Integer;
begin
  CheckIndex('face', AFaceNum, AFile.NumFaces);
  LFace := AFile.Faces[AFaceNum];
  Result := TGeoBounds.Cleared;
  for LIndex := 0 to LFace.NumEdges - 1 do
  begin
    CheckIndex('edge index', LFace.FirstEdge + LIndex, Length(AFile.EdgeIndex));
    Result.AddPoint(VertexOfEdge(AFile, AFile.EdgeIndex[LFace.FirstEdge + LIndex]));
  end;
end;

class function TAasGeometry.AreaBounds(const AFile: TAasFile; const AAreaNum: Integer): TGeoBounds;
var
  LArea: TAasArea;
  LIndex: Integer;
begin
  CheckIndex('area', AAreaNum, AFile.NumAreas);
  LArea := AFile.Areas[AAreaNum];
  Result := TGeoBounds.Cleared;
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    CheckIndex('face index', LArea.FirstFace + LIndex, Length(AFile.FaceIndex));
    Result.AddBounds(FaceBounds(AFile, Abs(AFile.FaceIndex[LArea.FirstFace + LIndex])));
  end;
end;

class function TAasGeometry.AreaContentsTravelFlags(const AContents: Integer): Integer;
begin
  if (AContents and AREACONTENTS_WATER) <> 0 then
    Result := TFL_WATER
  else
    Result := TFL_AIR;
end;

class function TAasGeometry.MaxTreeDepth(const AFile: TAasFile): Integer;
var
  LStackNodes, LStackDepths: TArray<Integer>;
  LTop, LNodeNum, LDepth, LSide, LChild: Integer;
  LVisited: TArray<Boolean>;
begin
  Result := 0;
  if AFile.NumNodes <= 1 then
    Exit;
  SetLength(LVisited, AFile.NumNodes);
  // an explicit stack: a chain of 4 million nodes would overflow the stack of the thread
  SetLength(LStackNodes, 64);
  SetLength(LStackDepths, 64);
  LStackNodes[0] := 1;
  LStackDepths[0] := 1;
  LTop := 1;
  while LTop > 0 do
  begin
    Dec(LTop);
    LNodeNum := LStackNodes[LTop];
    LDepth := LStackDepths[LTop];
    if LVisited[LNodeNum] then
      raise EAasFileException.Create(Format(SNodeReachedTwice, [LNodeNum]));
    LVisited[LNodeNum] := True;
    if LDepth > Result then
      Result := LDepth;
    for LSide := 0 to 1 do
    begin
      LChild := AFile.Nodes[LNodeNum].Children[LSide];
      // zero is solid, negative is an area
      if LChild <= 0 then
        Continue;
      if LChild >= AFile.NumNodes then
        raise EAasFileException.Create(Format(SChildOutOfRange, [LChild, AFile.NumNodes - 1]));
      if LTop >= Length(LStackNodes) then
      begin
        SetLength(LStackNodes, LTop * 2);
        SetLength(LStackDepths, LTop * 2);
      end;
      LStackNodes[LTop] := LChild;
      LStackDepths[LTop] := LDepth + 1;
      Inc(LTop);
    end;
  end;
end;

end.
