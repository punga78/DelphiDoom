{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the optimizer (be_aas_optimize.c)                 }
{                                                                              }
{  Port of AAS_Optimize and its helpers: only the ladder faces and what they   }
{  need (edges, vertices) are kept. Based on the Quake III Arena GPL Source    }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Optimize.Optimizer;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf,
  DelphiDoom.Aas.Cluster.Intf;

type
  /// <summary>
  ///   Rewrites the vertices, edges, faces and areas of a file so that they hold only the faces with FACE_LADDER and the
  ///   edges and vertices of those; the reachabilities that point at faces and edges are renumbered. The file must
  ///   be changeable (IAasFileEditor). The file and the import are not owned
  /// </summary>
  TAasOptimizer = class(TInterfacedObject, IAasOptimizer)
  strict private
    FFile: IAasFile;
    FImport: IBotImport;
    FVertexes: TArray<TVec3>;
    FEdges: TArray<TAasEdge>;
    FEdgeIndex: TArray<Integer>;
    FFaces: TArray<TAasFace>;
    FFaceIndex: TArray<Integer>;
    FAreas: TArray<TAasArea>;
    FSourceVertexes: TArray<TVec3>;
    FSourceEdges: TArray<TAasEdge>;
    FSourceEdgeIndex: TArray<Integer>;
    FSourceFaces: TArray<TAasFace>;
    FSourceFaceIndex: TArray<Integer>;
    FSourceAreas: TArray<TAasArea>;
    FNumVertexes: Integer;
    FNumEdges: Integer;
    FEdgeIndexSize: Integer;
    FNumFaces: Integer;
    FFaceIndexSize: Integer;
    FVertexOptimizeIndex: TArray<Integer>;
    FEdgeOptimizeIndex: TArray<Integer>;
    FFaceOptimizeIndex: TArray<Integer>;
    procedure Validate;
    function OptimizeEdge(const AEdgeNum: Integer): Integer;
    function OptimizeFace(const AFaceNum: Integer): Integer;
    procedure OptimizeArea(const AAreaNum: Integer);
  public
    constructor Create(const AFile: IAasFile; const AImport: IBotImport);
    /// <summary>AAS_Optimize; an index that is outside the tables of the file is an EAasClusterException</summary>
    procedure Optimize;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Editor.Intf, DelphiDoom.Aas.Cluster.Types;

resourcestring
  SNotEditable = 'AAS optimizer: the file cannot be changed (it does not implement IAasFileEditor)';
  SOutOfRange = 'AAS optimizer: %s %d refers to a table entry that the file does not hold';
  STableFull = 'AAS optimizer: the %s table is full (the C writes past the end of it)';

{ TAasOptimizer }

constructor TAasOptimizer.Create(const AFile: IAasFile; const AImport: IBotImport);
begin
  inherited Create;
  FFile := AFile;
  FImport := AImport;
end;

procedure TAasOptimizer.Validate;
var
  LIndex, LPosition: Integer;
  LReach: TAasReachability;
  LType: Integer;
begin
  // only what the optimizer reaches is checked: the edges of the faces that are kept (the dummy edge 0 of a file that
  // was optimized already uses a vertex that the file does not hold, and the C never reads it)
  for LIndex := 0 to High(FSourceFaces) do
  begin
    if (FSourceFaces[LIndex].FaceFlags and FACE_LADDER) = 0 then
      Continue;
    if (FSourceFaces[LIndex].FirstEdge < 0) or (FSourceFaces[LIndex].NumEdges < 0) or
      (Int64(FSourceFaces[LIndex].FirstEdge) + FSourceFaces[LIndex].NumEdges > Length(FSourceEdgeIndex)) then
      raise EAasClusterException.Create(Format(SOutOfRange, ['face', LIndex]));
    for LPosition := FSourceFaces[LIndex].FirstEdge to
      FSourceFaces[LIndex].FirstEdge + FSourceFaces[LIndex].NumEdges - 1 do
      if Abs(FSourceEdgeIndex[LPosition]) >= Length(FSourceEdges) then
        raise EAasClusterException.Create(Format(SOutOfRange, ['face', LIndex]));
  end;
  for LIndex := 1 to High(FSourceAreas) do
  begin
    if (FSourceAreas[LIndex].FirstFace < 0) or (FSourceAreas[LIndex].NumFaces < 0) or
      (Int64(FSourceAreas[LIndex].FirstFace) + FSourceAreas[LIndex].NumFaces > Length(FSourceFaceIndex)) then
      raise EAasClusterException.Create(Format(SOutOfRange, ['area', LIndex]));
    for LPosition := FSourceAreas[LIndex].FirstFace to
      FSourceAreas[LIndex].FirstFace + FSourceAreas[LIndex].NumFaces - 1 do
      if Abs(FSourceFaceIndex[LPosition]) >= Length(FSourceFaces) then
        raise EAasClusterException.Create(Format(SOutOfRange, ['area', LIndex]));
  end;
  for LIndex := 0 to High(FFile.Reachability) do
  begin
    LReach := FFile.Reachability[LIndex];
    LType := LReach.TravelType and TRAVELTYPE_MASK;
    if (LType = TRAVEL_ELEVATOR) or (LType = TRAVEL_JUMPPAD) or (LType = TRAVEL_FUNCBOB) then
      Continue;
    if (Abs(Int64(LReach.FaceNum)) >= Length(FSourceFaces)) or (Abs(Int64(LReach.EdgeNum)) >= Length(FSourceEdges)) then
      raise EAasClusterException.Create(Format(SOutOfRange, ['reachability', LIndex]));
  end;
end;

function TAasOptimizer.OptimizeEdge(const AEdgeNum: Integer): Integer;
var
  LIndex, LOptEdgeNum, LVertex: Integer;
  LEdge: TAasEdge;
begin
  LEdge := FSourceEdges[Abs(AEdgeNum)];
  // AAS_KeepEdge keeps every edge
  LOptEdgeNum := FEdgeOptimizeIndex[Abs(AEdgeNum)];
  if LOptEdgeNum <> 0 then
  begin
    // keep the edge reversed sign
    if AEdgeNum > 0 then
      Exit(LOptEdgeNum)
    else
      Exit(-LOptEdgeNum);
  end;
  if FNumEdges >= Length(FEdges) then
    raise EAasClusterException.Create(Format(STableFull, ['edge']));
  for LIndex := 0 to 1 do
  begin
    LVertex := LEdge.Vertexes[LIndex];
    if (LVertex < 0) or (LVertex >= Length(FSourceVertexes)) then
      raise EAasClusterException.Create(Format(SOutOfRange, ['edge', Abs(AEdgeNum)]));
    // vertex 0 is also "not stored yet" in the original: an edge that uses the first vertex stored adds it again
    if FVertexOptimizeIndex[LVertex] <> 0 then
      FEdges[FNumEdges].Vertexes[LIndex] := FVertexOptimizeIndex[LVertex]
    else
    begin
      if FNumVertexes >= Length(FVertexes) then
        raise EAasClusterException.Create(Format(STableFull, ['vertex']));
      FVertexes[FNumVertexes] := FSourceVertexes[LVertex];
      FEdges[FNumEdges].Vertexes[LIndex] := FNumVertexes;
      FVertexOptimizeIndex[LVertex] := FNumVertexes;
      Inc(FNumVertexes);
    end;
  end;
  FEdgeOptimizeIndex[Abs(AEdgeNum)] := FNumEdges;
  LOptEdgeNum := FNumEdges;
  Inc(FNumEdges);
  // keep the edge reversed sign
  if AEdgeNum > 0 then
    Result := LOptEdgeNum
  else
    Result := -LOptEdgeNum;
end;

function TAasOptimizer.OptimizeFace(const AFaceNum: Integer): Integer;
var
  LIndex, LEdgeNum, LOptEdgeNum, LOptFaceNum: Integer;
  LFace: TAasFace;
begin
  LFace := FSourceFaces[Abs(AFaceNum)];
  // AAS_KeepFace: only the ladder faces
  if (LFace.FaceFlags and FACE_LADDER) = 0 then
    Exit(0);
  LOptFaceNum := FFaceOptimizeIndex[Abs(AFaceNum)];
  if LOptFaceNum <> 0 then
  begin
    // keep the face side sign
    if AFaceNum > 0 then
      Exit(LOptFaceNum)
    else
      Exit(-LOptFaceNum);
  end;
  if FNumFaces >= Length(FFaces) then
    raise EAasClusterException.Create(Format(STableFull, ['face']));
  FFaces[FNumFaces] := LFace;
  FFaces[FNumFaces].NumEdges := 0;
  FFaces[FNumFaces].FirstEdge := FEdgeIndexSize;
  for LIndex := 0 to LFace.NumEdges - 1 do
  begin
    LEdgeNum := FSourceEdgeIndex[LFace.FirstEdge + LIndex];
    LOptEdgeNum := OptimizeEdge(LEdgeNum);
    if LOptEdgeNum <> 0 then
    begin
      if FFaces[FNumFaces].FirstEdge + FFaces[FNumFaces].NumEdges >= Length(FEdgeIndex) then
        raise EAasClusterException.Create(Format(STableFull, ['edge index']));
      FEdgeIndex[FFaces[FNumFaces].FirstEdge + FFaces[FNumFaces].NumEdges] := LOptEdgeNum;
      Inc(FFaces[FNumFaces].NumEdges);
      Inc(FEdgeIndexSize);
    end;
  end;
  FFaceOptimizeIndex[Abs(AFaceNum)] := FNumFaces;
  LOptFaceNum := FNumFaces;
  Inc(FNumFaces);
  // keep the face side sign
  if AFaceNum > 0 then
    Result := LOptFaceNum
  else
    Result := -LOptFaceNum;
end;

procedure TAasOptimizer.OptimizeArea(const AAreaNum: Integer);
var
  LIndex, LFaceNum, LOptFaceNum: Integer;
  LArea: TAasArea;
begin
  LArea := FSourceAreas[AAreaNum];
  FAreas[AAreaNum] := LArea;
  FAreas[AAreaNum].NumFaces := 0;
  FAreas[AAreaNum].FirstFace := FFaceIndexSize;
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LFaceNum := FSourceFaceIndex[LArea.FirstFace + LIndex];
    LOptFaceNum := OptimizeFace(LFaceNum);
    if LOptFaceNum <> 0 then
    begin
      if FAreas[AAreaNum].FirstFace + FAreas[AAreaNum].NumFaces >= Length(FFaceIndex) then
        raise EAasClusterException.Create(Format(STableFull, ['face index']));
      FFaceIndex[FAreas[AAreaNum].FirstFace + FAreas[AAreaNum].NumFaces] := LOptFaceNum;
      Inc(FAreas[AAreaNum].NumFaces);
      Inc(FFaceIndexSize);
    end;
  end;
end;

procedure TAasOptimizer.Optimize;
var
  LEditor: IAasFileEditor;
  LIndex, LSign, LType: Integer;
  LReaches: TArray<TAasReachability>;
begin
  if not Supports(FFile, IAasFileEditor, LEditor) then
    raise EAasClusterException.Create(SNotEditable);
  FSourceVertexes := FFile.Vertexes;
  FSourceEdges := FFile.Edges;
  FSourceEdgeIndex := FFile.EdgeIndex;
  FSourceFaces := FFile.Faces;
  FSourceFaceIndex := FFile.FaceIndex;
  FSourceAreas := FFile.Areas;
  Validate;
  // AAS_OptimizeAlloc: tables with the sizes of the originals (the optimized tables are never larger)
  FVertexes := nil;
  FEdges := nil;
  FEdgeIndex := nil;
  FFaces := nil;
  FFaceIndex := nil;
  FAreas := nil;
  SetLength(FVertexes, Length(FSourceVertexes));
  FNumVertexes := 0;
  SetLength(FEdges, Length(FSourceEdges));
  FNumEdges := 1; // edge zero is a dummy
  SetLength(FEdgeIndex, Length(FSourceEdgeIndex));
  FEdgeIndexSize := 0;
  SetLength(FFaces, Length(FSourceFaces));
  FNumFaces := 1; // face zero is a dummy
  SetLength(FFaceIndex, Length(FSourceFaceIndex));
  FFaceIndexSize := 0;
  SetLength(FAreas, Length(FSourceAreas));
  SetLength(FVertexOptimizeIndex, Length(FSourceVertexes));
  SetLength(FEdgeOptimizeIndex, Length(FSourceEdges));
  SetLength(FFaceOptimizeIndex, Length(FSourceFaces));
  for LIndex := 1 to High(FSourceAreas) do
    OptimizeArea(LIndex);
  // reset the reachability face pointers
  LReaches := FFile.Reachability;
  for LIndex := 0 to High(LReaches) do
  begin
    LType := LReaches[LIndex].TravelType and TRAVELTYPE_MASK;
    // for TRAVEL_ELEVATOR the facenum is the model number of the elevator; for TRAVEL_JUMPPAD the facenum is the Z
    // velocity and the edgenum the horizontal one; for TRAVEL_FUNCBOB they contain other coded information
    if (LType = TRAVEL_ELEVATOR) or (LType = TRAVEL_JUMPPAD) or (LType = TRAVEL_FUNCBOB) then
      Continue;
    LSign := LReaches[LIndex].FaceNum;
    LReaches[LIndex].FaceNum := FFaceOptimizeIndex[Abs(LReaches[LIndex].FaceNum)];
    if LSign < 0 then
      LReaches[LIndex].FaceNum := -LReaches[LIndex].FaceNum;
    LSign := LReaches[LIndex].EdgeNum;
    LReaches[LIndex].EdgeNum := FEdgeOptimizeIndex[Abs(LReaches[LIndex].EdgeNum)];
    if LSign < 0 then
      LReaches[LIndex].EdgeNum := -LReaches[LIndex].EdgeNum;
  end;
  // store the optimized AAS data into aasworld: the tables have the counts of the original
  LEditor.ReplaceGeometry(Copy(FVertexes, 0, FNumVertexes), Copy(FEdges, 0, FNumEdges),
    Copy(FEdgeIndex, 0, FEdgeIndexSize), Copy(FFaces, 0, FNumFaces), Copy(FFaceIndex, 0, FFaceIndexSize), FAreas);
  if Assigned(FImport) then
    FImport.Print(PRT_MESSAGE, 'AAS data optimized.'#10);
end;

end.
