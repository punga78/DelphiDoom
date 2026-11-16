{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - faces and volumes of the areas                    }
{                                                                              }
{  Port of AAS_FaceArea, AAS_AreaVolume, AAS_AreaGroundFaceArea and            }
{  AAS_FaceCenter of be_aas_reach.c. Based on the Quake III Arena GPL Source   }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Geometry;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Reach.Intf;

type
  /// <summary>Faces and volumes of the areas of a file (the file is not owned)</summary>
  TAasReachGeometry = class(TInterfacedObject, IAasReachGeometry)
  strict private
    FFile: IAasFile;
  public
    constructor Create(const AFile: IAasFile);
    function FaceArea(const AFaceNum: Integer): Single;
    function AreaVolume(const AAreaNum: Integer): Single;
    function AreaGroundFaceArea(const AAreaNum: Integer): Single;
    procedure FaceCenter(const AFaceNum: Integer; out ACenter: TVec3);
  end;

implementation

uses
  System.Math, DelphiDoom.Aas.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Vectors;

const
  CHalf: Double = 0.5;

{ TAasReachGeometry }

constructor TAasReachGeometry.Create(const AFile: IAasFile);
begin
  inherited Create;
  FFile := AFile;
end;

function TAasReachGeometry.FaceArea(const AFaceNum: Integer): Single;
var
  LIndex, LEdgeNum, LSide: Integer;
  LFace: TAasFace;
  LVertexes: TArray<TVec3>;
  LEdges: TArray<TAasEdge>;
  LEdgeIndex: TArray<Integer>;
  LCorner, LD1, LD2, LCross: TVec3;
  LTotal: Single;
  LTerm, LSum: Double;
begin
  LFace := FFile.Faces[AFaceNum];
  LVertexes := FFile.Vertexes;
  LEdges := FFile.Edges;
  LEdgeIndex := FFile.EdgeIndex;
  LEdgeNum := LEdgeIndex[LFace.FirstEdge];
  LSide := Ord(LEdgeNum < 0);
  LCorner := LVertexes[LEdges[Abs(LEdgeNum)].Vertexes[LSide]];
  LTotal := 0;
  LIndex := 1;
  while LIndex < LFace.NumEdges - 1 do
  begin
    LEdgeNum := LEdgeIndex[LFace.FirstEdge + LIndex];
    LSide := Ord(LEdgeNum < 0);
    TAasVectorMath.Subtract(LVertexes[LEdges[Abs(LEdgeNum)].Vertexes[LSide]], LCorner, LD1);
    TAasVectorMath.Subtract(LVertexes[LEdges[Abs(LEdgeNum)].Vertexes[1 - LSide]], LCorner, LD2);
    TAasVectorMath.Cross(LD1, LD2, LCross);
    // total += 0.5 * VectorLength(cross): the product and the sum are doubles
    LTerm := CHalf * TAasVectorMath.Length(LCross);
    LSum := LTotal + LTerm;
    LTotal := LSum;
    Inc(LIndex);
  end;
  Result := LTotal;
end;

function TAasReachGeometry.AreaVolume(const AAreaNum: Integer): Single;
var
  LIndex, LFaceNum, LEdgeNum, LSide: Integer;
  LArea: TAasArea;
  LFace: TAasFace;
  LPlane: TAasPlane;
  LCorner: TVec3;
  LD, LA, LVolume, LDot, LProduct: Single;
begin
  LArea := FFile.Areas[AAreaNum];
  LFaceNum := FFile.FaceIndex[LArea.FirstFace];
  LFace := FFile.Faces[Abs(LFaceNum)];
  LEdgeNum := FFile.EdgeIndex[LFace.FirstEdge];
  LCorner := FFile.Vertexes[FFile.Edges[Abs(LEdgeNum)].Vertexes[0]];
  // tetrahedrons to all other faces
  LVolume := 0;
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LFaceNum := Abs(FFile.FaceIndex[LArea.FirstFace + LIndex]);
    LFace := FFile.Faces[LFaceNum];
    LSide := Ord(LFace.BackArea <> AAreaNum);
    LPlane := FFile.Planes[LFace.PlaneNum xor LSide];
    LDot := TAasVectorMath.Dot(LCorner, LPlane.Normal);
    LDot := LDot - LPlane.Dist;
    LD := -LDot;
    LA := FaceArea(LFaceNum);
    LProduct := LD * LA;
    LVolume := LVolume + LProduct;
  end;
  LVolume := LVolume / 3;
  Result := LVolume;
end;

function TAasReachGeometry.AreaGroundFaceArea(const AAreaNum: Integer): Single;
var
  LIndex: Integer;
  LArea: TAasArea;
  LFaceNum: Integer;
  LFaceArea, LTotal: Single;
begin
  LTotal := 0;
  LArea := FFile.Areas[AAreaNum];
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LFaceNum := Abs(FFile.FaceIndex[LArea.FirstFace + LIndex]);
    if (FFile.Faces[LFaceNum].FaceFlags and FACE_GROUND) = 0 then
      Continue;
    LFaceArea := FaceArea(LFaceNum);
    LTotal := LTotal + LFaceArea;
  end;
  Result := LTotal;
end;

procedure TAasReachGeometry.FaceCenter(const AFaceNum: Integer; out ACenter: TVec3);
var
  LIndex, LNumEdges: Integer;
  LFace: TAasFace;
  LEdge: TAasEdge;
  LScale: Single;
  LScaleDouble: Double;
  LVertexes: TArray<TVec3>;
begin
  // a negative number reads the memory before the faces in the original (be_aas_reach.c passes the face number of the
  // face index with its sign): a zero face, with no edge, whose center is 0 * infinity, not a number
  if AFaceNum < 0 then
  begin
    ACenter[0] := NaN;
    ACenter[1] := NaN;
    ACenter[2] := NaN;
    Exit;
  end;
  LFace := FFile.Faces[AFaceNum];
  LVertexes := FFile.Vertexes;
  ACenter[0] := 0;
  ACenter[1] := 0;
  ACenter[2] := 0;
  LNumEdges := LFace.NumEdges;
  for LIndex := 0 to LNumEdges - 1 do
  begin
    LEdge := FFile.Edges[Abs(FFile.EdgeIndex[LFace.FirstEdge + LIndex])];
    TAasReachVectors.Add(ACenter, LVertexes[LEdge.Vertexes[0]], ACenter);
    TAasReachVectors.Add(ACenter, LVertexes[LEdge.Vertexes[1]], ACenter);
  end;
  // scale = 0.5 / face->numedges: a double, then a float (a face with no edge gives infinity as in C)
  if LNumEdges = 0 then
    LScaleDouble := Infinity
  else
    LScaleDouble := CHalf / LNumEdges;
  LScale := LScaleDouble;
  TAasReachVectors.Scale(ACenter, LScale, ACenter);
end;

end.
