{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  the model                                                                   }
{                                                                              }
{  The public functions of cm_public.h (cm_load.c, cm_test.c, cm_trace.c) on   }
{  top of a clip map, from the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.Model;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Intf, DelphiDoom.Collision.Q3.ClipMap,
  DelphiDoom.Collision.Q3.LeafLister, DelphiDoom.Collision.Q3.PointLocator, DelphiDoom.Collision.Q3.PositionTester,
  DelphiDoom.Collision.Q3.Tracer, DelphiDoom.Collision.Q3.AreaFlood;

type
  /// <summary>IQ3CollisionModel on a clip map that the object owns</summary>
  TQ3CollisionModel = class(TInterfacedObject, IQ3CollisionModel)
  strict private
    FMap: TQ3ClipMap;
    FLister: TQ3LeafLister;
    FLocator: TQ3PointLocator;
    FPositionTester: TQ3PositionTester;
    FTracer: TQ3Tracer;
    FFlood: TQ3AreaFlood;
  public
    /// <param name="AMap">the model takes it and frees it</param>
    constructor Create(const AMap: TQ3ClipMap);
    destructor Destroy; override;
    function GetNumClusters: Integer;
    function GetNumInlineModels: Integer;
    function GetNumAreas: Integer;
    function GetEntityString: AnsiString;
    function GetNoAreas: Boolean;
    procedure SetNoAreas(const AValue: Boolean);
    function GetNoCurves: Boolean;
    procedure SetNoCurves(const AValue: Boolean);
    function GetTraceCount: Integer;
    function GetBrushTraceCount: Integer;
    function GetPatchTraceCount: Integer;
    function GetPointContentsCount: Integer;
    function InlineModel(const AIndex: Integer): Integer;
    function TempBoxModel(const AMins, AMaxs: TQ3Vec3; const ACapsule: Boolean): Integer;
    procedure ModelBounds(const AModel: Integer; out AMins, AMaxs: TQ3Vec3);
    function PointLeafnum(const APoint: TQ3Vec3): Integer;
    function PointContents(const APoint: TQ3Vec3; const AModel: Integer): Integer;
    function TransformedPointContents(const APoint: TQ3Vec3; const AModel: Integer;
      const AOrigin, AAngles: TQ3Vec3): Integer;
    function BoxLeafnums(const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer; out ALeafs: TArray<Integer>;
      out ALastLeaf: Integer): Integer;
    function BoxBrushes(const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer): TArray<Integer>;
    function BoxTrace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel, ABrushMask: Integer;
      const ACapsule: Boolean): TQ3Trace;
    function TransformedBoxTrace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel, ABrushMask: Integer;
      const AOrigin, AAngles: TQ3Vec3; const ACapsule: Boolean): TQ3Trace;
    function LeafCluster(const ALeaf: Integer): Integer;
    function LeafArea(const ALeaf: Integer): Integer;
    function ClusterPVS(const ACluster: Integer): TBytes;
    procedure AdjustAreaPortalState(const AArea1, AArea2: Integer; const AOpen: Boolean);
    function AreasConnected(const AArea1, AArea2: Integer): Boolean;
    function WriteAreaBits(var ABuffer: TBytes; const AArea: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.BoxHull;

resourcestring
  SBadInlineModel = 'CM_InlineModel: bad number';
  SBadLeafCluster = 'CM_LeafCluster: bad number';
  SBadLeafArea = 'CM_LeafArea: bad number';
  SNoBoxHull = 'CM_TempBoxModel: the map has no box hull';

constructor TQ3CollisionModel.Create(const AMap: TQ3ClipMap);
begin
  inherited Create;
  FMap := AMap;
  FLister := TQ3LeafLister.Create(FMap);
  FLocator := TQ3PointLocator.Create(FMap);
  FPositionTester := TQ3PositionTester.Create(FMap, FLister);
  FTracer := TQ3Tracer.Create(FMap, FPositionTester);
  FFlood := TQ3AreaFlood.Create(FMap);
end;

destructor TQ3CollisionModel.Destroy;
begin
  FFlood.Free;
  FTracer.Free;
  FPositionTester.Free;
  FLocator.Free;
  FLister.Free;
  FMap.Free;
  inherited Destroy;
end;

function TQ3CollisionModel.GetNumClusters: Integer;
begin
  Result := FMap.NumClusters;
end;

function TQ3CollisionModel.GetNumInlineModels: Integer;
begin
  Result := FMap.NumSubModels;
end;

function TQ3CollisionModel.GetNumAreas: Integer;
begin
  Result := FMap.NumAreas;
end;

function TQ3CollisionModel.GetEntityString: AnsiString;
begin
  Result := FMap.EntityString;
end;

function TQ3CollisionModel.GetNoAreas: Boolean;
begin
  Result := FMap.NoAreas;
end;

procedure TQ3CollisionModel.SetNoAreas(const AValue: Boolean);
begin
  FMap.NoAreas := AValue;
end;

function TQ3CollisionModel.GetNoCurves: Boolean;
begin
  Result := FMap.NoCurves;
end;

procedure TQ3CollisionModel.SetNoCurves(const AValue: Boolean);
begin
  FMap.NoCurves := AValue;
end;

function TQ3CollisionModel.GetTraceCount: Integer;
begin
  Result := FMap.TraceCount;
end;

function TQ3CollisionModel.GetBrushTraceCount: Integer;
begin
  Result := FMap.BrushTraceCount;
end;

function TQ3CollisionModel.GetPatchTraceCount: Integer;
begin
  Result := FMap.PatchTraceCount;
end;

function TQ3CollisionModel.GetPointContentsCount: Integer;
begin
  Result := FMap.PointContentsCount;
end;

function TQ3CollisionModel.InlineModel(const AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex >= FMap.NumSubModels) then
    raise EQ3CollisionException.Create(SBadInlineModel);
  Result := AIndex;
end;

function TQ3CollisionModel.TempBoxModel(const AMins, AMaxs: TQ3Vec3; const ACapsule: Boolean): Integer;
begin
  if Length(FMap.Planes) < FMap.NumPlanes + Q3_BOX_PLANES then
    raise EQ3CollisionException.Create(SNoBoxHull);
  Result := TQ3BoxHull.TempBoxModel(FMap, AMins, AMaxs, ACapsule);
end;

procedure TQ3CollisionModel.ModelBounds(const AModel: Integer; out AMins, AMaxs: TQ3Vec3);
var
  LModel: PQ3Model;
begin
  LModel := FMap.ClipHandleToModel(AModel);
  AMins := LModel^.Mins;
  AMaxs := LModel^.Maxs;
end;

function TQ3CollisionModel.PointLeafnum(const APoint: TQ3Vec3): Integer;
begin
  Result := FLocator.PointLeafnum(APoint);
end;

function TQ3CollisionModel.PointContents(const APoint: TQ3Vec3; const AModel: Integer): Integer;
begin
  Result := FLocator.PointContents(APoint, AModel);
end;

function TQ3CollisionModel.TransformedPointContents(const APoint: TQ3Vec3; const AModel: Integer;
  const AOrigin, AAngles: TQ3Vec3): Integer;
begin
  Result := FLocator.TransformedPointContents(APoint, AModel, AOrigin, AAngles);
end;

function TQ3CollisionModel.BoxLeafnums(const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer;
  out ALeafs: TArray<Integer>; out ALastLeaf: Integer): Integer;
begin
  Result := FLister.BoxLeafnums(AMins, AMaxs, AMaxCount, ALeafs, ALastLeaf);
end;

function TQ3CollisionModel.BoxBrushes(const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer): TArray<Integer>;
begin
  Result := FLister.BoxBrushes(AMins, AMaxs, AMaxCount);
end;

function TQ3CollisionModel.BoxTrace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel, ABrushMask: Integer;
  const ACapsule: Boolean): TQ3Trace;
begin
  Result := FTracer.BoxTrace(AStart, AEnd, AMins, AMaxs, AModel, ABrushMask, ACapsule);
end;

function TQ3CollisionModel.TransformedBoxTrace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel,
  ABrushMask: Integer; const AOrigin, AAngles: TQ3Vec3; const ACapsule: Boolean): TQ3Trace;
begin
  Result := FTracer.TransformedBoxTrace(AStart, AEnd, AMins, AMaxs, AModel, ABrushMask, AOrigin, AAngles,
    ACapsule);
end;

function TQ3CollisionModel.LeafCluster(const ALeaf: Integer): Integer;
begin
  if (ALeaf < 0) or (ALeaf >= FMap.NumLeafs) then
    raise EQ3CollisionException.Create(SBadLeafCluster);
  Result := FMap.Leafs[ALeaf].Cluster;
end;

function TQ3CollisionModel.LeafArea(const ALeaf: Integer): Integer;
begin
  if (ALeaf < 0) or (ALeaf >= FMap.NumLeafs) then
    raise EQ3CollisionException.Create(SBadLeafArea);
  Result := FMap.Leafs[ALeaf].Area;
end;

function TQ3CollisionModel.ClusterPVS(const ACluster: Integer): TBytes;
var
  LOffset: Integer;
begin
  if (ACluster < 0) or (ACluster >= FMap.NumClusters) or not FMap.Vised then
    LOffset := 0
  else
    LOffset := ACluster * FMap.ClusterBytes;
  Result := Copy(FMap.Visibility, LOffset, FMap.ClusterBytes);
end;

procedure TQ3CollisionModel.AdjustAreaPortalState(const AArea1, AArea2: Integer; const AOpen: Boolean);
begin
  FFlood.AdjustPortalState(AArea1, AArea2, AOpen);
end;

function TQ3CollisionModel.AreasConnected(const AArea1, AArea2: Integer): Boolean;
begin
  Result := FFlood.AreasConnected(AArea1, AArea2);
end;

function TQ3CollisionModel.WriteAreaBits(var ABuffer: TBytes; const AArea: Integer): Integer;
begin
  Result := FFlood.WriteAreaBits(ABuffer, AArea);
end;

end.
