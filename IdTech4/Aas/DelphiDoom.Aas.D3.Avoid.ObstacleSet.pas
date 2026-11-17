{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - obstacle avoidance, the obstacles       }
{                                                                              }
{  Port of PointInsideObstacle, GetPointOutsideObstacles and                   }
{  GetFirstBlockingObstacle (AI_pathing.cpp), Doom 3 GPL Source Code. Based    }
{  on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011 id     }
{  Software LLC, a ZeniMax Media company. This unit is derived from the Doom   }
{  3 GPL source code and is therefore available under the GNU General Public   }
{  License, version 3 or (at your option) any later version, with the          }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Avoid.ObstacleSet;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.Aas.D3.Avoid.Obstacle;

type
  /// <summary>
  ///   The obstacles around a body, at most AVOID_MAX_OBSTACLES, and the questions that the search of a path asks
  ///   of them: which obstacle contains a point, where to push a point out of the obstacles, which obstacle blocks
  ///   a movement first. The set owns the obstacles
  /// </summary>
  TAvoidObstacleSet = class
  strict private
    FItems: TObjectList<TAvoidObstacle>;
    FLog: IIdLibLog;
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): TAvoidObstacle;
  public
    /// <summary>The log gets the warning of GetPointOutsideObstacles (nil is silent)</summary>
    constructor Create(const ALog: IIdLibLog = nil);
    destructor Destroy; override;
    /// <summary>Adds an empty obstacle that the caller fills; an EAasAvoidException if there are already AVOID_MAX_OBSTACLES</summary>
    function Add: TAvoidObstacle;
    procedure Clear;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TAvoidObstacle read GetItem; default;
    /// <summary>The first obstacle that contains the point (with a margin of 0.1), -1 if none</summary>
    function PointInsideObstacle(const APoint: TIdVec2): Integer;
    /// <summary>
    ///   Pushes the point out of the obstacle it is in (a bit beyond the nearest edge, or out of the group of
    ///   obstacles that touch it). <c>AObstacle</c> is the obstacle that held the point, <c>AEdgeNum</c> the edge
    ///   it was pushed through; -1 and -1 if it was not inside any
    /// </summary>
    procedure GetPointOutsideObstacles(var APoint: TIdVec2; out AObstacle, AEdgeNum: Integer);
    /// <summary>
    ///   The first obstacle (but <c>ASkipObstacle</c>) that blocks a movement from the start along the delta:
    ///   True if there is one before the end of the movement; <c>AScale</c> is the fraction of the movement that is
    ///   free (a huge number if nothing blocks), the others the obstacle and its edge
    /// </summary>
    function GetFirstBlockingObstacle(const ASkipObstacle: Integer; const AStartPos, ADelta: TIdVec2;
      out AScale: Single; var AObstacle, AEdgeNum: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Winding2D, DelphiDoom.Geometry.FloatMath,
  DelphiDoom.Aas.D3.Avoid.Types;

resourcestring
  STooManyObstacles = 'AAS obstacle avoidance: more than %d obstacles';
  SNoValidPoint = 'GetPointOutsideObstacles: no valid point found';

const
  // idMath::INFINITY, PUSH_OUTSIDE_OBSTACLES, CM_BOX_EPSILON and the float constants of the original
  CInfinity: Single = 1E30;
  CPushOutside: Single = 0.5;
  CBoxEpsilon: Single = 1.0;
  CPointMargin: Single = 0.100000001490116119384765625;
  CExpandMore: Single = 0.20000000298023223876953125;
  CBlockEpsilon: Single = 0.00999999977648258209228515625;

{ TAvoidObstacleSet }

constructor TAvoidObstacleSet.Create(const ALog: IIdLibLog);
begin
  inherited Create;
  FLog := ALog;
  FItems := TObjectList<TAvoidObstacle>.Create(True);
end;

destructor TAvoidObstacleSet.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TAvoidObstacleSet.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TAvoidObstacleSet.GetItem(const AIndex: Integer): TAvoidObstacle;
begin
  Result := FItems[AIndex];
end;

function TAvoidObstacleSet.Add: TAvoidObstacle;
begin
  if FItems.Count >= AVOID_MAX_OBSTACLES then
    raise EAasAvoidException.Create(Format(STooManyObstacles, [AVOID_MAX_OBSTACLES]));
  Result := TAvoidObstacle.Create;
  FItems.Add(Result);
end;

procedure TAvoidObstacleSet.Clear;
begin
  FItems.Clear;
end;

function TAvoidObstacleSet.PointInsideObstacle(const APoint: TIdVec2): Integer;
var
  LIndex: Integer;
  LObstacle: TAvoidObstacle;
begin
  for LIndex := 0 to FItems.Count - 1 do
  begin
    LObstacle := FItems[LIndex];
    if (APoint.X < LObstacle.BoundsMin.X) or (APoint.Y < LObstacle.BoundsMin.Y) or
      (APoint.X > LObstacle.BoundsMax.X) or (APoint.Y > LObstacle.BoundsMax.Y) then
      Continue;
    if not LObstacle.Winding.PointInside(APoint, CPointMargin) then
      Continue;
    Exit(LIndex);
  end;
  Result := -1;
end;

procedure TAvoidObstacleSet.GetPointOutsideObstacles(var APoint: TIdVec2; out AObstacle, AEdgeNum: Integer);
var
  LIndex, LJ, LK, LN, LBestObstacle, LBestEdgeNum, LQueueStart, LQueueEnd: Integer;
  LEdgeNums: array[0..1] of Integer;
  LD, LBestD, LScalar: Single;
  LScale: array[0..1] of Single;
  LPlane, LBestPlane: TGeoVec3;
  LNewPoint, LDir, LBestPoint: TIdVec2;
  LQueue: TArray<Integer>;
  LVisited: TArray<Boolean>;
  LW1, LW2: TGeoWinding2D;
  LW: TGeoWinding2D;
  LCurrent, LOther: TAvoidObstacle;
begin
  AObstacle := -1;
  AEdgeNum := -1;

  LBestObstacle := PointInsideObstacle(APoint);
  if LBestObstacle = -1 then
    Exit;

  LW := FItems[LBestObstacle].Winding;
  LBestD := CInfinity;
  LBestEdgeNum := 0;
  LBestPlane.Zero;
  for LIndex := 0 to LW.NumPoints - 1 do
  begin
    LPlane := TGeoWinding2D.Plane2DFromPoints(LW[(LIndex + 1) mod LW.NumPoints], LW[LIndex], True);
    LD := LPlane.X * APoint.X + LPlane.Y * APoint.Y + LPlane.Z;
    if LD < LBestD then
    begin
      LBestD := LD;
      LBestPlane := LPlane;
      LBestEdgeNum := LIndex;
    end;
    // if this is a wall always try to pop out at the first edge
    if FItems[LBestObstacle].EntityId = AVOID_NO_ENTITY then
      Break;
  end;

  LScalar := LBestD + CPushOutside;
  LNewPoint := APoint - LScalar * TIdVec2.Create(LBestPlane.X, LBestPlane.Y);
  if PointInsideObstacle(LNewPoint) = -1 then
  begin
    APoint := LNewPoint;
    AObstacle := LBestObstacle;
    AEdgeNum := LBestEdgeNum;
    Exit;
  end;

  SetLength(LQueue, FItems.Count + 1);
  SetLength(LVisited, FItems.Count);
  LQueueStart := 0;
  LQueueEnd := 1;
  LQueue[0] := LBestObstacle;
  LVisited[LBestObstacle] := True;

  LBestD := CInfinity;
  LW1 := TGeoWinding2D.Create;
  LW2 := TGeoWinding2D.Create;
  try
    LIndex := LQueue[0];
    while LQueueStart < LQueueEnd do
    begin
      LCurrent := FItems[LIndex];
      LW1.Assign(LCurrent.Winding);
      LW1.Expand(CPushOutside);

      for LJ := 0 to FItems.Count - 1 do
      begin
        // if the obstacle has been visited already
        if LVisited[LJ] then
          Continue;
        LOther := FItems[LJ];
        // if the bounds do not intersect
        if (LOther.BoundsMin.X > LCurrent.BoundsMax.X) or (LOther.BoundsMin.Y > LCurrent.BoundsMax.Y) or
          (LOther.BoundsMax.X < LCurrent.BoundsMin.X) or (LOther.BoundsMax.Y < LCurrent.BoundsMin.Y) then
          Continue;

        LQueue[LQueueEnd] := LJ;
        Inc(LQueueEnd);
        LVisited[LJ] := True;

        LW2.Assign(LOther.Winding);
        LW2.Expand(CExpandMore);

        for LK := 0 to LW1.NumPoints - 1 do
        begin
          LDir := LW1[(LK + 1) mod LW1.NumPoints] - LW1[LK];
          if not LW2.RayIntersection(LW1[LK], LDir, LScale[0], LScale[1], LEdgeNums[0], LEdgeNums[1]) then
            Continue;
          for LN := 0 to 1 do
          begin
            LNewPoint := LW1[LK] + LScale[LN] * LDir;
            if PointInsideObstacle(LNewPoint) = -1 then
            begin
              LD := (LNewPoint - APoint).LengthSqr;
              if LD < LBestD then
              begin
                LBestD := LD;
                LBestPoint := LNewPoint;
                LBestEdgeNum := LEdgeNums[LN];
                LBestObstacle := LJ;
              end;
            end;
          end;
        end;
      end;

      if LBestD < CInfinity then
      begin
        APoint := LBestPoint;
        AObstacle := LBestObstacle;
        AEdgeNum := LBestEdgeNum;
        Exit;
      end;
      Inc(LQueueStart);
      LIndex := LQueue[LQueueStart];
    end;
  finally
    LW2.Free;
    LW1.Free;
  end;
  if Assigned(FLog) then
    FLog.Warning(SNoValidPoint);
end;

function TAvoidObstacleSet.GetFirstBlockingObstacle(const ASkipObstacle: Integer; const AStartPos,
  ADelta: TIdVec2; out AScale: Single; var AObstacle, AEdgeNum: Integer): Boolean;
var
  LIndex: Integer;
  LEdgeNums: array[0..1] of Integer;
  LDist, LScale1, LScale2: Single;
  LBounds: array[0..1] of TIdVec2;
  LObstacle: TAvoidObstacle;
begin
  // get bounds for the current movement delta
  LBounds[0] := AStartPos - TIdVec2.Create(CBoxEpsilon, CBoxEpsilon);
  LBounds[1] := AStartPos + TIdVec2.Create(CBoxEpsilon, CBoxEpsilon);
  LBounds[TGeoMath.FloatSignBitNotSet(ADelta.X)].X := LBounds[TGeoMath.FloatSignBitNotSet(ADelta.X)].X + ADelta.X;
  LBounds[TGeoMath.FloatSignBitNotSet(ADelta.Y)].Y := LBounds[TGeoMath.FloatSignBitNotSet(ADelta.Y)].Y + ADelta.Y;

  // test for obstacles blocking the path
  AScale := CInfinity;
  LDist := ADelta.Length;
  for LIndex := 0 to FItems.Count - 1 do
  begin
    if LIndex = ASkipObstacle then
      Continue;
    LObstacle := FItems[LIndex];
    if (LBounds[0].X > LObstacle.BoundsMax.X) or (LBounds[0].Y > LObstacle.BoundsMax.Y) or
      (LBounds[1].X < LObstacle.BoundsMin.X) or (LBounds[1].Y < LObstacle.BoundsMin.Y) then
      Continue;
    if LObstacle.Winding.RayIntersection(AStartPos, ADelta, LScale1, LScale2, LEdgeNums[0], LEdgeNums[1]) then
      if (LScale1 < AScale) and (LScale1 * LDist > -CBlockEpsilon) and (LScale2 * LDist > CBlockEpsilon) then
      begin
        AScale := LScale1;
        AObstacle := LIndex;
        AEdgeNum := LEdgeNums[0];
      end;
  end;
  Result := AScale < 1.0;
end;

end.
