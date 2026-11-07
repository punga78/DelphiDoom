{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - tracing through the axial BSP tree          }
{                                                                              }
{  Port of CollisionModel_trace.cpp (without the rotational branch), Doom 3    }
{  GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media   }
{  company. Doom 3 Source Code: GNU General Public License version 3 with      }
{  additional terms. This unit is a derived work (GPL v3).                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Tracer;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Collision.TraceWork, DelphiDoom.Collision.Model.Node,
  DelphiDoom.Collision.Translator, DelphiDoom.Collision.ContentsTester;

type
  /// <summary>
  ///   Walks the spatial subdivision along a trace and hands the polygons and brushes of the
  ///   leaves it crosses to the translator (movement) or to the contents tester (position test)
  /// </summary>
  TCollisionTracer = class
  private
    FTranslator: TCollisionTranslator;
    FContentsTester: TCollisionContentsTester;
    procedure TraceTrmThroughNode(ATraceWork: TCmTraceWork; ANode: TCmNode);
    procedure TraceThroughAxialBSPTree(ATraceWork: TCmTraceWork; ANode: TCmNode; AP1F, AP2F: Single;
      const AP1, AP2: TGeoVec3);
  public
    /// <summary>The translator and the tester are not owned</summary>
    constructor Create(ATranslator: TCollisionTranslator; AContentsTester: TCollisionContentsTester);
    /// <summary>Traces through the whole model of the trace work (TraceThroughModel)</summary>
    procedure TraceThroughModel(ATraceWork: TCmTraceWork);
  end;

implementation

uses
  DelphiDoom.Collision.Model.Polygon, DelphiDoom.Collision.Model.Brush;

{ TCollisionTracer }

constructor TCollisionTracer.Create(ATranslator: TCollisionTranslator;
  AContentsTester: TCollisionContentsTester);
begin
  inherited Create;
  FTranslator := ATranslator;
  FContentsTester := AContentsTester;
end;

procedure TCollisionTracer.TraceTrmThroughNode(ATraceWork: TCmTraceWork; ANode: TCmNode);
var
  LBrush: TCmBrush;
  LPolygon: TCmPolygon;
begin
  // position test
  if ATraceWork.PositionTest then
  begin
    // if already stuck in solid
    if ATraceWork.Trace.Fraction = 0 then
      Exit;
    // test if any of the trm vertices is inside a brush
    for LBrush in ANode.Brushes do
      if FContentsTester.TestTrmVertsInBrush(ATraceWork, LBrush) then
        Exit;
    // if just testing a point we're done
    if ATraceWork.PointTrace then
      Exit;
    // test if the trm is stuck in any polygons
    for LPolygon in ANode.Polygons do
      if FContentsTester.TestTrmInPolygon(ATraceWork, LPolygon) then
        Exit;
  end
  else
  begin
    // trace through all polygons in this leaf
    for LPolygon in ANode.Polygons do
      if FTranslator.TranslateTrmThroughPolygon(ATraceWork, LPolygon) then
        Exit;
  end;
end;

procedure TCollisionTracer.TraceThroughAxialBSPTree(ATraceWork: TCmTraceWork; ANode: TCmNode; AP1F,
  AP2F: Single; const AP1, AP2: TGeoVec3);
var
  LT1: Single;
  LT2: Single;
  LOffset: Single;
  LFrac: Single;
  LFrac2: Single;
  LIDist: Single;
  LMid: TGeoVec3;
  LSide: Integer;
  LMidF: Single;
begin
  if not Assigned(ANode) then
    Exit;

  if ATraceWork.QuickExit then
    Exit; // stop immediately

  if ATraceWork.Trace.Fraction <= AP1F then
    Exit; // already hit something nearer

  // if we need to test this node for collisions
  if (ANode.Polygons.Count > 0) or (ATraceWork.PositionTest and (ANode.Brushes.Count > 0)) then
    // trace through node with collision data
    TraceTrmThroughNode(ATraceWork, ANode);
  // if already stuck in solid
  if ATraceWork.PositionTest and (ATraceWork.Trace.Fraction = 0) then
    Exit;
  // if this is a leaf node
  if ANode.PlaneType = -1 then
    Exit;
  // distance from plane for trace start and end
  LT1 := AP1[ANode.PlaneType] - ANode.PlaneDist;
  LT2 := AP2[ANode.PlaneType] - ANode.PlaneDist;
  // adjust the plane distance appropriately for mins/maxs
  LOffset := ATraceWork.Extents[ANode.PlaneType];
  // see which sides we need to consider
  if (LT1 >= LOffset) and (LT2 >= LOffset) then
  begin
    TraceThroughAxialBSPTree(ATraceWork, ANode.Children[0], AP1F, AP2F, AP1, AP2);
    Exit;
  end;

  if (LT1 < -LOffset) and (LT2 < -LOffset) then
  begin
    TraceThroughAxialBSPTree(ATraceWork, ANode.Children[1], AP1F, AP2F, AP1, AP2);
    Exit;
  end;

  if LT1 < LT2 then
  begin
    LIDist := 1.0 / (LT1 - LT2);
    LSide := 1;
    LFrac2 := (LT1 + LOffset) * LIDist;
    LFrac := (LT1 - LOffset) * LIDist;
  end
  else if LT1 > LT2 then
  begin
    LIDist := 1.0 / (LT1 - LT2);
    LSide := 0;
    LFrac2 := (LT1 - LOffset) * LIDist;
    LFrac := (LT1 + LOffset) * LIDist;
  end
  else
  begin
    LSide := 0;
    LFrac := 1.0;
    LFrac2 := 0.0;
  end;

  // move up to the node
  if LFrac < 0 then
    LFrac := 0
  else if LFrac > 1 then
    LFrac := 1;

  LMidF := AP1F + (AP2F - AP1F) * LFrac;

  LMid.X := AP1.X + LFrac * (AP2.X - AP1.X);
  LMid.Y := AP1.Y + LFrac * (AP2.Y - AP1.Y);
  LMid.Z := AP1.Z + LFrac * (AP2.Z - AP1.Z);

  TraceThroughAxialBSPTree(ATraceWork, ANode.Children[LSide], AP1F, LMidF, AP1, LMid);

  // go past the node
  if LFrac2 < 0 then
    LFrac2 := 0
  else if LFrac2 > 1 then
    LFrac2 := 1;

  LMidF := AP1F + (AP2F - AP1F) * LFrac2;

  LMid.X := AP1.X + LFrac2 * (AP2.X - AP1.X);
  LMid.Y := AP1.Y + LFrac2 * (AP2.Y - AP1.Y);
  LMid.Z := AP1.Z + LFrac2 * (AP2.Z - AP1.Z);

  TraceThroughAxialBSPTree(ATraceWork, ANode.Children[LSide xor 1], LMidF, AP2F, LMid, AP2);
end;

procedure TCollisionTracer.TraceThroughModel(ATraceWork: TCmTraceWork);
begin
  // trace through spatial subdivision and then through leafs
  TraceThroughAxialBSPTree(ATraceWork, ATraceWork.Model.Node, 0, 1, ATraceWork.Start, ATraceWork.EndPoint);
end;

end.
