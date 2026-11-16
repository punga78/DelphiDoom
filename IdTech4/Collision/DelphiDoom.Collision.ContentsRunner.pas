{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - contents of a volume                        }
{                                                                              }
{  Port of PointNode, PointContents, TransformedPointContents and ContentsTrm  }
{  of CollisionModel_contents.cpp, Doom 3 GPL Source Code.                     }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.ContentsRunner;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.TraceModel,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.CheckCounter, DelphiDoom.Collision.Model,
  DelphiDoom.Collision.Model.Node, DelphiDoom.Collision.Tracer;

type
  /// <summary>Finds the contents of a point or of a trace model standing in a model</summary>
  TCollisionContentsRunner = class
  private
    FCounter: TCollisionCheckCounter;
    FTracer: TCollisionTracer;
  public
    /// <summary>The counter and the tracer are not owned</summary>
    constructor Create(ACounter: TCollisionCheckCounter; ATracer: TCollisionTracer);
    /// <summary>The leaf containing the point (PointNode)</summary>
    function PointNode(const APoint: TGeoVec3; AModel: TCollisionModel): TCmNode;
    /// <summary>Contents of the brush that contains the point, or 0 (PointContents)</summary>
    function PointContents(const APoint: TGeoVec3; AModel: TCollisionModel): Integer;
    /// <summary>PointContents for a model placed at an origin with an axis (TransformedPointContents)</summary>
    function TransformedPointContents(const APoint: TGeoVec3; AModel: TCollisionModel;
      const AOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Integer;
    /// <summary>
    ///   Position test of a trace model (ContentsTrm). AResults.Fraction is 1 when nothing is
    ///   touched, else 0; returns the contents. ATrm may be nil for a point
    /// </summary>
    function ContentsTrm(var AResults: TCollisionTrace; const AStart: TGeoVec3; ATrm: TTraceModel;
      const ATrmAxis: TGeoMat3; AContentMask: Integer; AModel: TCollisionModel;
      const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.FloatMath, DelphiDoom.Collision.Model.Brush,
  DelphiDoom.Collision.TraceWork, DelphiDoom.Geometry.Bounds;

{ TCollisionContentsRunner }

constructor TCollisionContentsRunner.Create(ACounter: TCollisionCheckCounter; ATracer: TCollisionTracer);
begin
  inherited Create;
  FCounter := ACounter;
  FTracer := ATracer;
end;

function TCollisionContentsRunner.PointNode(const APoint: TGeoVec3; AModel: TCollisionModel): TCmNode;
begin
  Result := AModel.Node;
  while Result.PlaneType <> -1 do
    if APoint[Result.PlaneType] > Result.PlaneDist then
      Result := Result.Children[0]
    else
      Result := Result.Children[1];
end;

function TCollisionContentsRunner.PointContents(const APoint: TGeoVec3; AModel: TCollisionModel): Integer;
var
  LNode: TCmNode;
  LBrush: TCmBrush;
  LIndex: Integer;
  LInBounds: Boolean;
begin
  LNode := PointNode(APoint, AModel);
  for LBrush in LNode.Brushes do
  begin
    // test if the point is within the brush bounds
    LInBounds := True;
    for LIndex := 0 to 2 do
      if (APoint[LIndex] < LBrush.Bounds.Mins[LIndex]) or (APoint[LIndex] > LBrush.Bounds.Maxs[LIndex]) then
      begin
        LInBounds := False;
        Break;
      end;
    if not LInBounds then
      Continue;
    // test if the point is inside the brush
    LIndex := 0;
    while LIndex < LBrush.NumPlanes do
    begin
      if LBrush.Planes[LIndex].Distance(APoint) >= 0 then
        Break;
      Inc(LIndex);
    end;
    if LIndex >= LBrush.NumPlanes then
      Exit(LBrush.Contents);
  end;
  Result := 0;
end;

function TCollisionContentsRunner.TransformedPointContents(const APoint: TGeoVec3; AModel: TCollisionModel;
  const AOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Integer;
var
  LLocal: TGeoVec3;
begin
  // subtract origin offset
  LLocal := APoint - AOrigin;
  if AModelAxis.IsRotated then
    LLocal := LLocal * AModelAxis;
  Result := PointContents(LLocal, AModel);
end;

function TCollisionContentsRunner.ContentsTrm(var AResults: TCollisionTrace; const AStart: TGeoVec3;
  ATrm: TTraceModel; const ATrmAxis: TGeoMat3; AContentMask: Integer; AModel: TCollisionModel;
  const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Integer;
var
  LTw: TCmTraceWork;
  LIndex: Integer;
  LAxis: Integer;
  LModelRotated: Boolean;
  LTrmRotated: Boolean;
  LInvModelAxis: TGeoMat3;
  LTmpAxis: TGeoMat3;
  LDir: TGeoVec3;
begin
  // fast point case
  if (not Assigned(ATrm)) or ((ATrm.Bounds.Maxs.X - ATrm.Bounds.Mins.X <= 0) and
    (ATrm.Bounds.Maxs.Y - ATrm.Bounds.Mins.Y <= 0) and (ATrm.Bounds.Maxs.Z - ATrm.Bounds.Mins.Z <= 0)) then
  begin
    AResults.C.Contents := TransformedPointContents(AStart, AModel, AModelOrigin, AModelAxis);
    if AResults.C.Contents = 0 then
      AResults.Fraction := 1
    else
      AResults.Fraction := 0;
    AResults.EndPos := AStart;
    AResults.EndAxis := ATrmAxis;
    Exit(AResults.C.Contents);
  end;

  FCounter.Next;

  LTw := TCmTraceWork.Create;
  try
    LTw.Trace.Fraction := 1;
    LTw.Trace.C.Contents := 0;
    LTw.Trace.C.ContactType := ctNone;
    LTw.Contents := AContentMask;
    LTw.IsConvex := True;
    LTw.PositionTest := True;
    LTw.PointTrace := False;
    LTw.QuickExit := False;
    LTw.Model := AModel;
    LTw.Start := AStart - AModelOrigin;
    LTw.EndPoint := LTw.Start;

    LModelRotated := AModelAxis.IsRotated;
    if LModelRotated then
      LInvModelAxis := AModelAxis.Transpose;

    // setup trm structure
    LTw.SetupTrm(ATrm);

    LTrmRotated := ATrmAxis.IsRotated;

    // calculate vertex positions
    if LTrmRotated then
      for LIndex := 0 to LTw.NumVerts - 1 do
        // rotate trm around the start position
        LTw.Vertices[LIndex].P := LTw.Vertices[LIndex].P * ATrmAxis;
    for LIndex := 0 to LTw.NumVerts - 1 do
      // set trm at start position
      LTw.Vertices[LIndex].P := LTw.Vertices[LIndex].P + LTw.Start;
    if LModelRotated then
      for LIndex := 0 to LTw.NumVerts - 1 do
        // rotate trm around model instead of rotating the model
        LTw.Vertices[LIndex].P := LTw.Vertices[LIndex].P * LInvModelAxis;

    // add offset to start point
    if LTrmRotated then
    begin
      LDir := ATrm.Offset * ATrmAxis;
      LTw.Start := LTw.Start + LDir;
      LTw.EndPoint := LTw.EndPoint + LDir;
    end
    else
    begin
      LTw.Start := LTw.Start + ATrm.Offset;
      LTw.EndPoint := LTw.EndPoint + ATrm.Offset;
    end;
    if LModelRotated then
    begin
      // rotate trace instead of model
      LTw.Start := LTw.Start * LInvModelAxis;
      LTw.EndPoint := LTw.EndPoint * LInvModelAxis;
    end;

    // setup trm vertices
    LTw.Size.Clear;
    for LIndex := 0 to LTw.NumVerts - 1 do
      // get axial trm size after rotations
      LTw.Size.AddPoint(LTw.Vertices[LIndex].P - LTw.Start);

    // setup trm edges
    for LIndex := 1 to LTw.NumEdges do
    begin
      // edge start, end and pluecker coordinate
      LTw.Edges[LIndex].Start := LTw.Vertices[LTw.Edges[LIndex].VertexNum[0]].P;
      LTw.Edges[LIndex].EndPoint := LTw.Vertices[LTw.Edges[LIndex].VertexNum[1]].P;
      LTw.Edges[LIndex].Pl.FromLine(LTw.Edges[LIndex].Start, LTw.Edges[LIndex].EndPoint);
    end;

    // setup trm polygons
    if LTrmRotated and LModelRotated then
    begin
      LTmpAxis := ATrmAxis * LInvModelAxis;
      for LIndex := 0 to LTw.NumPolys - 1 do
        LTw.Polys[LIndex].Plane.RotateNormal(LTmpAxis);
    end
    else if LTrmRotated then
    begin
      for LIndex := 0 to LTw.NumPolys - 1 do
        LTw.Polys[LIndex].Plane.RotateNormal(ATrmAxis);
    end
    else if LModelRotated then
    begin
      for LIndex := 0 to LTw.NumPolys - 1 do
        LTw.Polys[LIndex].Plane.RotateNormal(LInvModelAxis);
    end;
    for LIndex := 0 to LTw.NumPolys - 1 do
      LTw.Polys[LIndex].Plane.FitThroughPoint(LTw.Edges[Abs(LTw.Polys[LIndex].Edges[0])].Start);

    // bounds for full trace, a little bit larger for epsilons
    for LAxis := 0 to 2 do
    begin
      if LTw.Start[LAxis] < LTw.EndPoint[LAxis] then
      begin
        LTw.Bounds.Mins[LAxis] := LTw.Start[LAxis] + LTw.Size.Mins[LAxis] - CM_BOX_EPSILON;
        LTw.Bounds.Maxs[LAxis] := LTw.EndPoint[LAxis] + LTw.Size.Maxs[LAxis] + CM_BOX_EPSILON;
      end
      else
      begin
        LTw.Bounds.Mins[LAxis] := LTw.EndPoint[LAxis] + LTw.Size.Mins[LAxis] - CM_BOX_EPSILON;
        LTw.Bounds.Maxs[LAxis] := LTw.Start[LAxis] + LTw.Size.Maxs[LAxis] + CM_BOX_EPSILON;
      end;
      if TGeoMath.Fabs(LTw.Size.Mins[LAxis]) > TGeoMath.Fabs(LTw.Size.Maxs[LAxis]) then
        LTw.Extents[LAxis] := TGeoMath.Fabs(LTw.Size.Mins[LAxis]) + CM_BOX_EPSILON
      else
        LTw.Extents[LAxis] := TGeoMath.Fabs(LTw.Size.Maxs[LAxis]) + CM_BOX_EPSILON;
    end;

    // trace through the model
    FTracer.TraceThroughModel(LTw);

    AResults := LTw.Trace;
    if AResults.C.Contents = 0 then
      AResults.Fraction := 1
    else
      AResults.Fraction := 0;
    AResults.EndPos := AStart;
    AResults.EndAxis := ATrmAxis;

    Result := AResults.C.Contents;
  finally
    LTw.Free;
  end;
end;

end.
