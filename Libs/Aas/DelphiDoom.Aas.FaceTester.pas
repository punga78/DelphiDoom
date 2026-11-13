{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - points and faces (be_aas_sample.c)                }
{                                                                              }
{  Port of AAS_InsideFace, AAS_PointInsideFace, AAS_AreaGroundFace,            }
{  AAS_TraceEndFace and AAS_FacePlane. Based on the Quake III Arena GPL Source }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.FaceTester;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf;

type
  /// <summary>
  ///   The face tests of the original. Faces are given by number (the original uses
  ///   pointers; the number 0 is the dummy face, so 0 also means "no face" in the results).
  ///   An edge, a vertex or a face out of range, which the original would read outside its
  ///   arrays, is an error that is printed and the answer is False (or 0).
  /// </summary>
  TAasFaceTester = class(TInterfacedObject, IAasFaceTester)
  strict private
    FFile: IAasFile;
    FImport: IBotImport;
    function EdgePoints(const AFace: TAasFace; const AIndex: Integer; out AStart, AEnd: TVec3): Boolean;
    function Inside(const AFace: TAasFace; const ANormal, APoint: TVec3; const AEpsilon: Single): Boolean;
    function FaceByNumber(const AFaceNum: Integer; out AFace: TAasFace): Boolean;
  public
    constructor Create(const AFile: IAasFile; const AImport: IBotImport);
    function InsideFace(const AFaceNum: Integer; const ANormal, APoint: TVec3; const AEpsilon: Single): Boolean;
    function PointInsideFace(const AFaceNum: Integer; const APoint: TVec3; const AEpsilon: Single): Boolean;
    function AreaGroundFace(const AAreaNum: Integer; const APoint: TVec3): Integer;
    function TraceEndFace(const ATrace: TAasTrace): Integer;
    procedure FacePlane(const AFaceNum: Integer; out ANormal: TVec3; out ADist: Single);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Printer, DelphiDoom.Aas.VectorMath;

resourcestring
  SFaceOutOfRange = 'AAS_InsideFace: face %d out of range'#10;
  SEdgeOutOfRange = 'AAS_InsideFace: an edge of the face %d is out of range'#10;

const
  // the float literal 0.01f of the callers
  GROUND_EPSILON: Single = 0.01;

{ TAasFaceTester }

constructor TAasFaceTester.Create(const AFile: IAasFile; const AImport: IBotImport);
begin
  inherited Create;
  FFile := AFile;
  FImport := AImport;
end;

function TAasFaceTester.FaceByNumber(const AFaceNum: Integer; out AFace: TAasFace): Boolean;
var
  LFaces: TArray<TAasFace>;
begin
  LFaces := FFile.Faces;
  Result := (AFaceNum >= 0) and (AFaceNum < Length(LFaces));
  if Result then
    AFace := LFaces[AFaceNum]
  else
  begin
    FillChar(AFace, SizeOf(AFace), 0);
    TAasPrinter.Print(FImport, PRT_ERROR, Format(SFaceOutOfRange, [AFaceNum]));
  end;
end;

function TAasFaceTester.EdgePoints(const AFace: TAasFace; const AIndex: Integer; out AStart, AEnd: TVec3): Boolean;
var
  LEdgeNum, LEdgeSlot, LFirst: Integer;
  LEdge: TAasEdge;
  LEdgeIndex: TArray<Integer>;
  LVertexes: TArray<TVec3>;
begin
  Result := False;
  LEdgeIndex := FFile.EdgeIndex;
  LVertexes := FFile.Vertexes;
  LEdgeSlot := AFace.FirstEdge + AIndex;
  if (LEdgeSlot < 0) or (LEdgeSlot >= Length(LEdgeIndex)) then
    Exit;
  LEdgeNum := LEdgeIndex[LEdgeSlot];
  if (Abs(LEdgeNum) >= Length(FFile.Edges)) then
    Exit;
  LEdge := FFile.Edges[Abs(LEdgeNum)];
  // the first vertex of the edge; a negative number is an edge that is walked backwards
  if LEdgeNum < 0 then
    LFirst := 1
  else
    LFirst := 0;
  if (LEdge.Vertexes[LFirst] < 0) or (LEdge.Vertexes[LFirst] >= Length(LVertexes)) or
     (LEdge.Vertexes[1 - LFirst] < 0) or (LEdge.Vertexes[1 - LFirst] >= Length(LVertexes)) then
    Exit;
  AStart := LVertexes[LEdge.Vertexes[LFirst]];
  AEnd := LVertexes[LEdge.Vertexes[1 - LFirst]];
  Result := True;
end;

function TAasFaceTester.Inside(const AFace: TAasFace; const ANormal, APoint: TVec3; const AEpsilon: Single): Boolean;
var
  LIndex: Integer;
  LStart, LEnd, LEdgeVector, LPointVector, LSeparator: TVec3;
  LDot, LLimit: Single;
begin
  Result := False;
  LLimit := -AEpsilon;
  for LIndex := 0 to AFace.NumEdges - 1 do
  begin
    if not EdgePoints(AFace, LIndex, LStart, LEnd) then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, Format(SEdgeOutOfRange, [AFace.FirstEdge]));
      Exit;
    end;
    TAasVectorMath.Subtract(LEnd, LStart, LEdgeVector);
    // the vector from the first point of the edge to the point
    TAasVectorMath.Subtract(APoint, LStart, LPointVector);
    // orthogonal to the edge and to the normal of the plane: the side the point is on
    // says if it is inside the boundary of the face
    TAasVectorMath.Cross(LEdgeVector, ANormal, LSeparator);
    LDot := TAasVectorMath.Dot(LPointVector, LSeparator);
    if LDot < LLimit then
      Exit;
  end;
  Result := True;
end;

function TAasFaceTester.InsideFace(const AFaceNum: Integer; const ANormal, APoint: TVec3;
  const AEpsilon: Single): Boolean;
var
  LFace: TAasFace;
begin
  Result := FaceByNumber(AFaceNum, LFace) and Inside(LFace, ANormal, APoint, AEpsilon);
end;

function TAasFaceTester.PointInsideFace(const AFaceNum: Integer; const APoint: TVec3;
  const AEpsilon: Single): Boolean;
var
  LFace: TAasFace;
  LPlanes: TArray<TAasPlane>;
begin
  Result := False;
  if not FaceByNumber(AFaceNum, LFace) then
    Exit;
  LPlanes := FFile.Planes;
  if (LFace.PlaneNum < 0) or (LFace.PlaneNum >= Length(LPlanes)) then
  begin
    TAasPrinter.Print(FImport, PRT_ERROR, Format(SFaceOutOfRange, [AFaceNum]));
    Exit;
  end;
  // the same test as AAS_InsideFace (the original repeats the code with the plane of the face)
  Result := Inside(LFace, LPlanes[LFace.PlaneNum].Normal, APoint, AEpsilon);
end;

function TAasFaceTester.AreaGroundFace(const AAreaNum: Integer; const APoint: TVec3): Integer;
var
  LAreas: TArray<TAasArea>;
  LArea: TAasArea;
  LFaceIndex: TArray<Integer>;
  LFaces: TArray<TAasFace>;
  LPlanes: TArray<TAasPlane>;
  LIndex, LFaceNum, LSlot: Integer;
  LNormal: TVec3;
begin
  Result := 0;
  LAreas := FFile.Areas;
  if (AAreaNum < 0) or (AAreaNum >= Length(LAreas)) then
    Exit;
  LArea := LAreas[AAreaNum];
  LFaceIndex := FFile.FaceIndex;
  LFaces := FFile.Faces;
  LPlanes := FFile.Planes;
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LSlot := LArea.FirstFace + LIndex;
    if (LSlot < 0) or (LSlot >= Length(LFaceIndex)) then
      Exit;
    LFaceNum := Abs(LFaceIndex[LSlot]);
    if LFaceNum >= Length(LFaces) then
      Exit;
    if (LFaces[LFaceNum].FaceFlags and FACE_GROUND) <> 0 then
    begin
      if (LFaces[LFaceNum].PlaneNum < 0) or (LFaces[LFaceNum].PlaneNum >= Length(LPlanes)) then
        Exit;
      // the up or down normal
      LNormal[0] := 0;
      LNormal[1] := 0;
      if LPlanes[LFaces[LFaceNum].PlaneNum].Normal[2] < 0 then
        LNormal[2] := -1
      else
        LNormal[2] := 1;
      if Inside(LFaces[LFaceNum], LNormal, APoint, GROUND_EPSILON) then
        Exit(LFaceNum);
    end;
  end;
end;

function TAasFaceTester.TraceEndFace(const ATrace: TAasTrace): Integer;
var
  LAreas: TArray<TAasArea>;
  LArea: TAasArea;
  LFaceIndex: TArray<Integer>;
  LFaces: TArray<TAasFace>;
  LPlanes: TArray<TAasPlane>;
  LIndex, LFaceNum, LSlot: Integer;
begin
  Result := 0;
  // if the trace started in solid no face was hit
  if ATrace.StartSolid then
    Exit;
  LAreas := FFile.Areas;
  if (ATrace.LastArea < 0) or (ATrace.LastArea >= Length(LAreas)) then
    Exit;
  LArea := LAreas[ATrace.LastArea];
  LFaceIndex := FFile.FaceIndex;
  LFaces := FFile.Faces;
  LPlanes := FFile.Planes;
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LSlot := LArea.FirstFace + LIndex;
    if (LSlot < 0) or (LSlot >= Length(LFaceIndex)) then
      Exit;
    LFaceNum := Abs(LFaceIndex[LSlot]);
    if LFaceNum >= Length(LFaces) then
      Exit;
    // the face is in the plane of the end of the trace (a plane and its opposite are the same plane)
    if (LFaces[LFaceNum].PlaneNum and not 1) = (ATrace.PlaneNum and not 1) then
    begin
      if (LFaces[LFaceNum].PlaneNum < 0) or (LFaces[LFaceNum].PlaneNum >= Length(LPlanes)) then
        Exit;
      if Inside(LFaces[LFaceNum], LPlanes[LFaces[LFaceNum].PlaneNum].Normal, ATrace.EndPos, GROUND_EPSILON) then
        Exit(LFaceNum);
    end;
  end;
  // the original has a "first face" it never sets: no face is found
end;

procedure TAasFaceTester.FacePlane(const AFaceNum: Integer; out ANormal: TVec3; out ADist: Single);
var
  LFace: TAasFace;
  LPlanes: TArray<TAasPlane>;
begin
  ANormal[0] := 0;
  ANormal[1] := 0;
  ANormal[2] := 0;
  ADist := 0;
  if not FaceByNumber(AFaceNum, LFace) then
    Exit;
  LPlanes := FFile.Planes;
  if (LFace.PlaneNum < 0) or (LFace.PlaneNum >= Length(LPlanes)) then
    Exit;
  ANormal := LPlanes[LFace.PlaneNum].Normal;
  ADist := LPlanes[LFace.PlaneNum].Dist;
end;

end.
