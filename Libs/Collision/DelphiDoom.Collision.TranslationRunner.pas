{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the translation of a trace model            }
{                                                                              }
{  Port of idCollisionModelManagerLocal::Translation (CollisionModel_          }
{  translate.cpp), Doom 3 GPL Source Code. Copyright (C) 1999-2011 id          }
{  Software LLC, a ZeniMax Media company. Doom 3 Source Code: GNU General      }
{  Public License version 3 with additional terms. This unit is a derived      }
{  work (GPL v3).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.TranslationRunner;

interface

uses
  System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3,
  DelphiDoom.Geometry.TraceModel, DelphiDoom.Logging.Intf, DelphiDoom.Collision.Types,
  DelphiDoom.Collision.CheckCounter, DelphiDoom.Collision.Model, DelphiDoom.Collision.Tracer,
  DelphiDoom.Collision.ContentsRunner;

type
  /// <summary>Moves a trace model (or a point) along a straight line through a model and finds the first collision</summary>
  TCollisionTranslationRunner = class
  private
    FLog: ILog;
    FCounter: TCollisionCheckCounter;
    FTracer: TCollisionTracer;
    FContentsRunner: TCollisionContentsRunner;
  public
    /// <summary>Nothing is owned; ALog may be nil</summary>
    constructor Create(const ALog: ILog; ACounter: TCollisionCheckCounter; ATracer: TCollisionTracer;
      AContentsRunner: TCollisionContentsRunner);
    /// <summary>
    ///   Translates a trm and reports the first collision if any (Translation). With
    ///   AStart = AEnd it does a position test. When AContacts is not nil all the contacts
    ///   are stored in it, up to AMaxContacts, and AResults is left empty (as the C++ code does
    ///   when getContacts is set). ATrm = nil traces a point
    /// </summary>
    procedure Translate(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3; ATrm: TTraceModel;
      const ATrmAxis: TGeoMat3; AContentMask: Integer; AModel: TCollisionModel;
      const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3; AContacts: TList<TContactInfo> = nil;
      AMaxContacts: Integer = 0);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.FloatMath, DelphiDoom.Collision.TraceWork;

resourcestring
  SHugeTranslation = 'TCollisionTranslationRunner.Translate: huge translation';

{ TCollisionTranslationRunner }

constructor TCollisionTranslationRunner.Create(const ALog: ILog; ACounter: TCollisionCheckCounter;
  ATracer: TCollisionTracer; AContentsRunner: TCollisionContentsRunner);
begin
  inherited Create;
  FLog := ALog;
  FCounter := ACounter;
  FTracer := ATracer;
  FContentsRunner := AContentsRunner;
end;

procedure TCollisionTranslationRunner.Translate(var AResults: TCollisionTrace; const AStart,
  AEnd: TGeoVec3; ATrm: TTraceModel; const ATrmAxis: TGeoMat3; AContentMask: Integer;
  AModel: TCollisionModel; const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3;
  AContacts: TList<TContactInfo>; AMaxContacts: Integer);
var
  LTw: TCmTraceWork;
  LIndex: Integer;
  LJ: Integer;
  LAxis: Integer;
  LDist: Single;
  LModelRotated: Boolean;
  LTrmRotated: Boolean;
  LDir: TGeoVec3;
  LInvModelAxis: TGeoMat3;
  LTmpAxis: TGeoMat3;
  LContact: TContactInfo;
begin
  AResults := Default(TCollisionTrace);

  // if case special position test
  if (AStart.X = AEnd.X) and (AStart.Y = AEnd.Y) and (AStart.Z = AEnd.Z) then
  begin
    FContentsRunner.ContentsTrm(AResults, AStart, ATrm, ATrmAxis, AContentMask, AModel, AModelOrigin,
      AModelAxis);
    Exit;
  end;

  FCounter.Next;

  LTw := TCmTraceWork.Create;
  try
    LTw.Trace.Fraction := 1;
    LTw.Trace.C.Contents := 0;
    LTw.Trace.C.ContactType := ctNone;
    LTw.Contents := AContentMask;
    LTw.IsConvex := True;
    LTw.PositionTest := False;
    LTw.QuickExit := False;
    LTw.GetContacts := Assigned(AContacts);
    LTw.Contacts := AContacts;
    LTw.MaxContacts := AMaxContacts;
    LTw.Model := AModel;
    LTw.Start := AStart - AModelOrigin;
    LTw.EndPoint := AEnd - AModelOrigin;
    LTw.Dir := AEnd - AStart;

    LModelRotated := AModelAxis.IsRotated;
    if LModelRotated then
      LInvModelAxis := AModelAxis.Transpose;

    // if optimized point trace
    if (not Assigned(ATrm)) or ((ATrm.Bounds.Maxs.X - ATrm.Bounds.Mins.X <= 0) and
      (ATrm.Bounds.Maxs.Y - ATrm.Bounds.Mins.Y <= 0) and (ATrm.Bounds.Maxs.Z - ATrm.Bounds.Mins.Z <= 0)) then
    begin
      if LModelRotated then
      begin
        // rotate trace instead of model
        LTw.Start := LTw.Start * LInvModelAxis;
        LTw.EndPoint := LTw.EndPoint * LInvModelAxis;
        LTw.Dir := LTw.Dir * LInvModelAxis;
      end;

      // trace bounds
      for LAxis := 0 to 2 do
        if LTw.Start[LAxis] < LTw.EndPoint[LAxis] then
        begin
          LTw.Bounds.Mins[LAxis] := LTw.Start[LAxis] - CM_BOX_EPSILON;
          LTw.Bounds.Maxs[LAxis] := LTw.EndPoint[LAxis] + CM_BOX_EPSILON;
        end
        else
        begin
          LTw.Bounds.Mins[LAxis] := LTw.EndPoint[LAxis] - CM_BOX_EPSILON;
          LTw.Bounds.Maxs[LAxis] := LTw.Start[LAxis] + CM_BOX_EPSILON;
        end;
      LTw.Extents.SetValues(CM_BOX_EPSILON, CM_BOX_EPSILON, CM_BOX_EPSILON);
      LTw.Size.Zero;

      // setup trace heart planes
      LTw.SetupTranslationHeartPlanes;
      LTw.MaxDistFromHeartPlane1 := CM_BOX_EPSILON;
      LTw.MaxDistFromHeartPlane2 := CM_BOX_EPSILON;
      // collision with single point
      LTw.NumVerts := 1;
      LTw.Vertices[0].P := LTw.Start;
      LTw.Vertices[0].EndP := LTw.Vertices[0].P + LTw.Dir;
      LTw.Vertices[0].Pl.FromRay(LTw.Vertices[0].P, LTw.Dir);
      LTw.NumEdges := 0;
      LTw.NumPolys := 0;
      LTw.PointTrace := True;
      // trace through the model
      FTracer.TraceThroughModel(LTw);
      // store results
      AResults := LTw.Trace;
      AResults.EndPos := AStart + (AEnd - AStart) * AResults.Fraction;
      AResults.EndAxis := TGeoMat3.Identity;

      if AResults.Fraction < 1 then
      begin
        // rotate trace plane normal if there was a collision with a rotated model
        if LModelRotated then
        begin
          AResults.C.Normal := AResults.C.Normal * AModelAxis;
          AResults.C.Point := AResults.C.Point * AModelAxis;
        end;
        AResults.C.Point := AResults.C.Point + AModelOrigin;
        AResults.C.Dist := AResults.C.Dist + AModelOrigin.Dot(AResults.C.Normal);
      end;
      Exit;
    end;

    // the trace fraction is too inaccurate to describe translations over huge distances
    if LTw.Dir.LengthSqr > CM_MAX_TRACE_DIST * CM_MAX_TRACE_DIST then
    begin
      AResults.Fraction := 0;
      AResults.EndPos := AStart;
      AResults.EndAxis := ATrmAxis;
      AResults.C.Normal := TGeoVec3.Origin;
      AResults.C.Material := nil;
      AResults.C.Point := AStart;
      if Assigned(FLog) then
        FLog.Info(SHugeTranslation + #10);
      Exit;
    end;

    LTw.PointTrace := False;
    LTw.Size.Clear;

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
      LTw.Dir := LTw.Dir * LInvModelAxis;
    end;

    // rotate trm polygon planes
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

    // setup trm polygons
    for LIndex := 0 to LTw.NumPolys - 1 do
    begin
      // if the trm poly plane is facing in the movement direction
      LDist := LTw.Polys[LIndex].Plane.Normal.Dot(LTw.Dir);
      if (LDist > 0) or ((not ATrm.IsConvex) and (LDist = 0)) then
      begin
        // this trm poly and it's edges and vertices need to be used for collision
        LTw.Polys[LIndex].Used := True;
        for LJ := 0 to LTw.Polys[LIndex].NumEdges - 1 do
        begin
          LTw.Edges[Abs(LTw.Polys[LIndex].Edges[LJ])].Used := True;
          LTw.Vertices[LTw.Edges[Abs(LTw.Polys[LIndex].Edges[LJ])].VertexNum[0]].Used := True;
          LTw.Vertices[LTw.Edges[Abs(LTw.Polys[LIndex].Edges[LJ])].VertexNum[1]].Used := True;
        end;
      end;
    end;

    // setup trm vertices
    for LIndex := 0 to LTw.NumVerts - 1 do
    begin
      if not LTw.Vertices[LIndex].Used then
        Continue;
      // get axial trm size after rotations
      LTw.Size.AddPoint(LTw.Vertices[LIndex].P - LTw.Start);
      // calculate the end position of each vertex for a full trace
      LTw.Vertices[LIndex].EndP := LTw.Vertices[LIndex].P + LTw.Dir;
      // pluecker coordinate for vertex movement line
      LTw.Vertices[LIndex].Pl.FromRay(LTw.Vertices[LIndex].P, LTw.Dir);
    end;

    // setup trm edges
    for LIndex := 1 to LTw.NumEdges do
    begin
      if not LTw.Edges[LIndex].Used then
        Continue;
      // edge start, end and pluecker coordinate
      LTw.Edges[LIndex].Start := LTw.Vertices[LTw.Edges[LIndex].VertexNum[0]].P;
      LTw.Edges[LIndex].EndPoint := LTw.Vertices[LTw.Edges[LIndex].VertexNum[1]].P;
      LTw.Edges[LIndex].Pl.FromLine(LTw.Edges[LIndex].Start, LTw.Edges[LIndex].EndPoint);
      // calculate normal of plane through movement plane created by the edge
      LDir := LTw.Edges[LIndex].Start - LTw.Edges[LIndex].EndPoint;
      LTw.Edges[LIndex].Cross.X := LDir.X * LTw.Dir.Y - LDir.Y * LTw.Dir.X;
      LTw.Edges[LIndex].Cross.Y := LDir.X * LTw.Dir.Z - LDir.Z * LTw.Dir.X;
      LTw.Edges[LIndex].Cross.Z := LDir.Y * LTw.Dir.Z - LDir.Z * LTw.Dir.Y;
      // bit for vertex sidedness bit cache
      LTw.Edges[LIndex].BitNum := LIndex;
    end;

    // set trm plane distances
    for LIndex := 0 to LTw.NumPolys - 1 do
      if LTw.Polys[LIndex].Used then
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

    // setup trace heart planes
    LTw.SetupTranslationHeartPlanes;
    LTw.MaxDistFromHeartPlane1 := 0;
    LTw.MaxDistFromHeartPlane2 := 0;
    // calculate maximum trm vertex distance from both heart planes
    for LIndex := 0 to LTw.NumVerts - 1 do
    begin
      if not LTw.Vertices[LIndex].Used then
        Continue;
      LDist := TGeoMath.Fabs(LTw.HeartPlane1.Distance(LTw.Vertices[LIndex].P));
      if LDist > LTw.MaxDistFromHeartPlane1 then
        LTw.MaxDistFromHeartPlane1 := LDist;
      LDist := TGeoMath.Fabs(LTw.HeartPlane2.Distance(LTw.Vertices[LIndex].P));
      if LDist > LTw.MaxDistFromHeartPlane2 then
        LTw.MaxDistFromHeartPlane2 := LDist;
    end;
    // for epsilons
    LTw.MaxDistFromHeartPlane1 := LTw.MaxDistFromHeartPlane1 + CM_BOX_EPSILON;
    LTw.MaxDistFromHeartPlane2 := LTw.MaxDistFromHeartPlane2 + CM_BOX_EPSILON;

    // trace through the model
    FTracer.TraceThroughModel(LTw);

    // if we're getting contacts
    if LTw.GetContacts then
    begin
      // move all contacts to world space
      if LModelRotated then
        for LIndex := 0 to AContacts.Count - 1 do
        begin
          LContact := AContacts[LIndex];
          LContact.Normal := LContact.Normal * AModelAxis;
          LContact.Point := LContact.Point * AModelAxis;
          AContacts[LIndex] := LContact;
        end;
      if not AModelOrigin.Compare(TGeoVec3.Origin) then
        for LIndex := 0 to AContacts.Count - 1 do
        begin
          LContact := AContacts[LIndex];
          LContact.Point := LContact.Point + AModelOrigin;
          LContact.Dist := LContact.Dist + AModelOrigin.Dot(LContact.Normal);
          AContacts[LIndex] := LContact;
        end;
    end
    else
    begin
      // store results
      AResults := LTw.Trace;
      AResults.EndPos := AStart + (AEnd - AStart) * AResults.Fraction;
      AResults.EndAxis := ATrmAxis;

      if AResults.Fraction < 1 then
      begin
        // if the fraction is tiny the actual movement could end up zero
        if (AResults.Fraction > 0) and AResults.EndPos.Compare(AStart) then
          AResults.Fraction := 0;
        // rotate trace plane normal if there was a collision with a rotated model
        if LModelRotated then
        begin
          AResults.C.Normal := AResults.C.Normal * AModelAxis;
          AResults.C.Point := AResults.C.Point * AModelAxis;
        end;
        AResults.C.Point := AResults.C.Point + AModelOrigin;
        AResults.C.Dist := AResults.C.Dist + AModelOrigin.Dot(AResults.C.Normal);
      end;
    end;
  finally
    LTw.Free;
  end;
end;

end.
