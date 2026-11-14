{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - disabled areas and routing obstacles    }
{                                                                              }
{  Port of idAASLocal::SetAreaState, AddObstacle, RemoveObstacle,              }
{  RemoveAllObstacles, DisableArea, EnableArea, SetObstacleState and           }
{  GetBoundsAreas_r (AAS_routing.cpp), Doom 3 GPL Source Code.                 }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Obstacles;

interface

uses
  System.Generics.Collections, DelphiDoom.Geometry.Bounds, DelphiDoom.Aas.D3.Topology, DelphiDoom.Aas.D3.CacheStore;

type
  /// <summary>
  ///   idRoutingObstacle: the bounds of an obstacle (expanded by the box of the actors) and the areas
  ///   they are in
  /// </summary>
  TAasRoutingObstacle = class
  public
    Bounds: TGeoBounds;
    Areas: TArray<Integer>;
  end;

  /// <summary>
  ///   Switches areas off (cluster portals that doors close) and blocks the reachabilities that pass
  ///   through the bounds of an obstacle. Every change drops the caches that depend on the areas. The
  ///   topology and the store are not owned
  /// </summary>
  TAasObstacleManager = class
  strict private
    FTopology: TAasTopology;
    FStore: TAasCacheStore;
    FObstacles: TObjectList<TAasRoutingObstacle>;
    procedure DisableArea(const AAreaNum: Integer);
    procedure EnableArea(const AAreaNum: Integer);
    function SetAreaStateFrom(const ANodeNum: Integer; const ABounds: TGeoBounds; const AAreaContents: Integer;
      const ADisabled: Boolean; const ADepth: Integer): Boolean;
    procedure GetBoundsAreasFrom(const ANodeNum: Integer; const ABounds: TGeoBounds; var AAreas: TArray<Integer>;
      const ADepth: Integer);
    procedure SetObstacleState(const AObstacle: TAasRoutingObstacle; const AEnable: Boolean);
    function ExpandBounds(const ABounds: TGeoBounds): TGeoBounds;
  public
    constructor Create(const ATopology: TAasTopology; const AStore: TAasCacheStore);
    destructor Destroy; override;
    /// <summary>
    ///   Finds the areas with the contents given that are in or touch the bounds (expanded by the box
    ///   of the actors) and disables or enables them for routing; True if one was found
    /// </summary>
    function SetAreaState(const ABounds: TGeoBounds; const AAreaContents: Integer; const ADisabled: Boolean): Boolean;
    /// <summary>Returns the handle: the index of the obstacle in the list, which changes when one is removed</summary>
    function AddObstacle(const ABounds: TGeoBounds): Integer;
    procedure RemoveObstacle(const AHandle: Integer);
    procedure RemoveAllObstacles;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.Aas.Types,
  DelphiDoom.MapFile.Aas.Reachability, DelphiDoom.MapFile.Aas.Area, DelphiDoom.MapFile.Aas.AasFile,
  DelphiDoom.Aas.D3.Types;

resourcestring
  STreeNodeOutOfRange = 'AAS tree: node %d is not in the file';
  STreeTooDeep = 'AAS tree: deeper than its number of nodes';
  SAreaNotInFile = 'AAS tree: area %d is not in the file';

{ TAasObstacleManager }

constructor TAasObstacleManager.Create(const ATopology: TAasTopology; const AStore: TAasCacheStore);
begin
  inherited Create;
  FTopology := ATopology;
  FStore := AStore;
  FObstacles := TObjectList<TAasRoutingObstacle>.Create(True);
end;

destructor TAasObstacleManager.Destroy;
begin
  FObstacles.Free;
  inherited Destroy;
end;

function TAasObstacleManager.ExpandBounds(const ABounds: TGeoBounds): TGeoBounds;
begin
  Result.Mins := ABounds.Mins - FTopology.AasFile.Settings.BoundingBoxes[0].Maxs;
  Result.Maxs := ABounds.Maxs - FTopology.AasFile.Settings.BoundingBoxes[0].Mins;
end;

procedure TAasObstacleManager.DisableArea(const AAreaNum: Integer);
begin
  if (FTopology.Areas[AAreaNum].TravelFlags and TFL_INVALID) <> 0 then
    Exit;
  FTopology.Areas[AAreaNum].TravelFlags := FTopology.Areas[AAreaNum].TravelFlags or TFL_INVALID;
  FStore.RemoveRoutingCacheUsingArea(AAreaNum);
end;

procedure TAasObstacleManager.EnableArea(const AAreaNum: Integer);
begin
  if (FTopology.Areas[AAreaNum].TravelFlags and TFL_INVALID) = 0 then
    Exit;
  FTopology.Areas[AAreaNum].TravelFlags := FTopology.Areas[AAreaNum].TravelFlags and not TFL_INVALID;
  FStore.RemoveRoutingCacheUsingArea(AAreaNum);
end;

function TAasObstacleManager.SetAreaStateFrom(const ANodeNum: Integer; const ABounds: TGeoBounds;
  const AAreaContents: Integer; const ADisabled: Boolean; const ADepth: Integer): Boolean;
var
  LNodeNum, LSide: Integer;
  LNode: TAasNode;
begin
  Result := False;
  LNodeNum := ANodeNum;
  if ADepth > FTopology.AasFile.NumNodes then
    raise EAasRoutingException.Create(STreeTooDeep);
  while LNodeNum <> 0 do
  begin
    if LNodeNum < 0 then
    begin
      if -LNodeNum >= FTopology.NumAreas then
        raise EAasRoutingException.Create(Format(SAreaNotInFile, [-LNodeNum]));
      // if this area is a cluster portal
      if (FTopology.Areas[-LNodeNum].Contents and AAreaContents) <> 0 then
      begin
        if ADisabled then
          DisableArea(-LNodeNum)
        else
          EnableArea(-LNodeNum);
        Result := True;
      end;
      Break;
    end;
    if LNodeNum >= FTopology.AasFile.NumNodes then
      raise EAasRoutingException.Create(Format(STreeNodeOutOfRange, [LNodeNum]));
    LNode := FTopology.AasFile.Nodes[LNodeNum];
    if LNode.PlaneNum >= FTopology.AasFile.NumPlanes then
      raise EAasRoutingException.Create(Format(STreeNodeOutOfRange, [LNodeNum]));
    LSide := ABounds.PlaneSide(FTopology.AasFile.Planes[LNode.PlaneNum]);
    if LSide = PLANESIDE_BACK then
      LNodeNum := LNode.Children[1]
    else if LSide = PLANESIDE_FRONT then
      LNodeNum := LNode.Children[0]
    else
    begin
      if SetAreaStateFrom(LNode.Children[1], ABounds, AAreaContents, ADisabled, ADepth + 1) then
        Result := True;
      LNodeNum := LNode.Children[0];
    end;
  end;
end;

function TAasObstacleManager.SetAreaState(const ABounds: TGeoBounds; const AAreaContents: Integer;
  const ADisabled: Boolean): Boolean;
begin
  Result := SetAreaStateFrom(1, ExpandBounds(ABounds), AAreaContents, ADisabled, 0);
end;

procedure TAasObstacleManager.GetBoundsAreasFrom(const ANodeNum: Integer; const ABounds: TGeoBounds;
  var AAreas: TArray<Integer>; const ADepth: Integer);
var
  LNodeNum, LSide: Integer;
  LNode: TAasNode;
begin
  LNodeNum := ANodeNum;
  if ADepth > FTopology.AasFile.NumNodes then
    raise EAasRoutingException.Create(STreeTooDeep);
  while LNodeNum <> 0 do
  begin
    if LNodeNum < 0 then
    begin
      if -LNodeNum >= FTopology.NumAreas then
        raise EAasRoutingException.Create(Format(SAreaNotInFile, [-LNodeNum]));
      SetLength(AAreas, Length(AAreas) + 1);
      AAreas[High(AAreas)] := -LNodeNum;
      Break;
    end;
    if LNodeNum >= FTopology.AasFile.NumNodes then
      raise EAasRoutingException.Create(Format(STreeNodeOutOfRange, [LNodeNum]));
    LNode := FTopology.AasFile.Nodes[LNodeNum];
    if LNode.PlaneNum >= FTopology.AasFile.NumPlanes then
      raise EAasRoutingException.Create(Format(STreeNodeOutOfRange, [LNodeNum]));
    LSide := ABounds.PlaneSide(FTopology.AasFile.Planes[LNode.PlaneNum]);
    if LSide = PLANESIDE_BACK then
      LNodeNum := LNode.Children[1]
    else if LSide = PLANESIDE_FRONT then
      LNodeNum := LNode.Children[0]
    else
    begin
      GetBoundsAreasFrom(LNode.Children[1], ABounds, AAreas, ADepth + 1);
      LNodeNum := LNode.Children[0];
    end;
  end;
end;

procedure TAasObstacleManager.SetObstacleState(const AObstacle: TAasRoutingObstacle; const AEnable: Boolean);
var
  LIndex, LAreaNum: Integer;
  LReach, LRevReach: TAasReachability;
  LInside: Boolean;
begin
  for LIndex := 0 to Length(AObstacle.Areas) - 1 do
  begin
    LAreaNum := AObstacle.Areas[LIndex];
    FStore.RemoveRoutingCacheUsingArea(LAreaNum);

    for LRevReach in FTopology.RevReach[LAreaNum] do
    begin
      if (LRevReach.TravelType and TFL_INVALID) <> 0 then
        Continue;

      LInside := False;

      if AObstacle.Bounds.ContainsPoint(LRevReach.EndPoint) then
        LInside := True
      else
        for LReach in FTopology.Reach[LAreaNum] do
          if AObstacle.Bounds.LineIntersection(LRevReach.EndPoint, LReach.StartPoint) then
          begin
            LInside := True;
            Break;
          end;

      if LInside then
      begin
        if AEnable then
        begin
          // disableCount is an unsigned char in the original: enabling a reachability that
          // is not disabled wraps to 255 and the reachability stays as it is
          LRevReach.DisableCount := Byte(LRevReach.DisableCount - 1);
          if LRevReach.DisableCount = 0 then
            LRevReach.TravelType := LRevReach.TravelType and not TFL_INVALID;
        end
        else
        begin
          LRevReach.TravelType := LRevReach.TravelType or TFL_INVALID;
          LRevReach.DisableCount := Byte(LRevReach.DisableCount + 1);
        end;
      end;
    end;
  end;
end;

function TAasObstacleManager.AddObstacle(const ABounds: TGeoBounds): Integer;
var
  LObstacle: TAasRoutingObstacle;
begin
  LObstacle := TAasRoutingObstacle.Create;
  try
    LObstacle.Bounds := ExpandBounds(ABounds);
    GetBoundsAreasFrom(1, LObstacle.Bounds, LObstacle.Areas, 0);
    SetObstacleState(LObstacle, True);
  except
    LObstacle.Free;
    raise;
  end;
  FObstacles.Add(LObstacle);
  Result := FObstacles.Count - 1;
end;

procedure TAasObstacleManager.RemoveObstacle(const AHandle: Integer);
begin
  if (AHandle >= 0) and (AHandle < FObstacles.Count) then
  begin
    SetObstacleState(FObstacles[AHandle], False);
    FObstacles.Delete(AHandle);
  end;
end;

procedure TAasObstacleManager.RemoveAllObstacles;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FObstacles.Count - 1 do
    SetObstacleState(FObstacles[LIndex], False);
  FObstacles.Clear;
end;

end.
