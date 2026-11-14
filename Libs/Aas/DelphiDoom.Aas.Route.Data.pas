{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the data of the routing (AAS_InitRouting)         }
{                                                                              }
{  Port of AAS_InitTravelFlagFromType, AAS_InitAreaContentsTravelFlags,        }
{  AAS_CreateReversedReachability, AAS_AreaTravelTime,                         }
{  AAS_CalculateAreaTravelTimes, AAS_InitPortalMaxTravelTimes and              }
{  AAS_InitReachabilityAreas of be_aas_route.c. Based on the Quake III Arena   }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Route.Data;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types,
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Types;

type
  /// <summary>aas_reversedlink_t: the area a reachability starts in and the number of the reachability</summary>
  TAasReversedLink = record
    AreaNum: Integer;
    LinkNum: Integer;
  end;

  /// <summary>
  ///   What the routing computes once for a file: the reachabilities that lead to each area, the time to cross every
  ///   area from the end of one reachability that arrives to the start of one that leaves, the longest crossing of
  ///   every portal, the travel flags of the contents of the areas and the areas that a reachability goes through.
  ///   The arrays of the file are shared, not copied: a change of the area flags is a change of the file. The file,
  ///   the import and the tracer are not owned
  /// </summary>
  TAasRouteData = class
  strict private
    FImport: IBotImport;
    FAreaSettings: TArray<TAasAreaSettings>;
    FReachability: TArray<TAasReachability>;
    FAreaCount: Integer;
    FTravelFlagForType: array[0..MAX_TRAVELTYPES - 1] of Integer;
    FAreaContentsTravelFlags: TArray<Integer>;
    FReversed: TArray<TArray<TAasReversedLink>>;
    FAreaTravelTimes: TArray<Word>;
    FAreaTravelTimeStart: TArray<Integer>;
    FPortalMaxTravelTimes: TArray<Integer>;
    FReachabilityAreaFirst: TArray<Integer>;
    FReachabilityAreaCount: TArray<Integer>;
    FReachabilityAreaIndex: TArray<Integer>;
    procedure Validate(const AFile: IAasFile);
    procedure InitTravelFlagFromType;
    procedure InitAreaContentsTravelFlags;
    procedure CreateReversedReachability;
    procedure CalculateAreaTravelTimes;
    procedure InitPortalMaxTravelTimes(const APortals: TArray<TAasPortal>);
    procedure InitReachabilityAreas(const ATracer: IAasTracer);
    function AreaContentsFlags(const AAreaNum: Integer): Integer;
  public
    /// <summary>
    ///   Computes everything. A number in the file that is outside its array is an EAasRouteException, where the
    ///   original reads outside the memory
    /// </summary>
    constructor Create(const AFile: IAasFile; const AImport: IBotImport; const ATracer: IAasTracer);
    /// <summary>AAS_AreaTravelTime: the time to cross an area, from <c>AStart</c> to <c>AEnd</c>, at least 1</summary>
    function AreaTravelTime(const AAreaNum: Integer; const AStart, AEnd: TVec3): Word;
    /// <summary>AAS_TravelFlagForType_inline</summary>
    function TravelFlagForType(const ATravelType: Integer): Integer;
    function AreaContentsTravelFlags(const AAreaNum: Integer): Integer;
    property AreaCount: Integer read FAreaCount;
    property AreaSettings: TArray<TAasAreaSettings> read FAreaSettings;
    property Reachability: TArray<TAasReachability> read FReachability;
    /// <summary>The reachabilities that lead to the area, in the order of the reversed chain of the original</summary>
    property Reversed: TArray<TArray<TAasReversedLink>> read FReversed;
    property AreaTravelTimes: TArray<Word> read FAreaTravelTimes;
    /// <summary>
    ///   The first entry in <c>AreaTravelTimes</c> of the row of the area, <c>l</c>th reachability that leaves it:
    ///   <c>AreaTravelTimeStart[area] + l * Length(Reversed[area])</c>
    /// </summary>
    property AreaTravelTimeStart: TArray<Integer> read FAreaTravelTimeStart;
    property PortalMaxTravelTimes: TArray<Integer> read FPortalMaxTravelTimes;
    property ReachabilityAreaFirst: TArray<Integer> read FReachabilityAreaFirst;
    property ReachabilityAreaCount: TArray<Integer> read FReachabilityAreaCount;
    property ReachabilityAreaIndex: TArray<Integer> read FReachabilityAreaIndex;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.VectorMath;

resourcestring
  SMoreThan128 = 'area %d has more than 128 reachabilities'#10;
  SNoAreas = 'AAS routing: the file has no areas';
  SSettingsMissing = 'AAS routing: the file has %d areas and %d area settings';
  SReachOutOfRange = 'AAS routing: area %d has reachabilities that are not in the reachability lump';
  SReachAreaOutOfRange = 'AAS routing: a reachability leads to area %d, which the file does not hold';
  SClusterOutOfRange = 'AAS routing: area %d is in cluster %d, which the file does not hold';
  SPortalOutOfRange = 'AAS routing: portal %d refers to an area or a cluster that the file does not hold';
  SClusterPortalsOutOfRange = 'AAS routing: cluster %d has portals outside the portal index';

const
  // 1.3f, 1 and 0.33f of the DISTANCEFACTOR_ macros: the float constants, not literals that are rounded as extended
  CCrouchFactor: Single = 1.2999999523162841796875;
  CSwimFactor: Single = 1.0;
  CWalkFactor: Single = 0.3300000131130218505859375;

{ TAasRouteData }

constructor TAasRouteData.Create(const AFile: IAasFile; const AImport: IBotImport; const ATracer: IAasTracer);
begin
  inherited Create;
  FImport := AImport;
  FAreaSettings := AFile.AreaSettings;
  FReachability := AFile.Reachability;
  FAreaCount := Length(AFile.Areas);
  Validate(AFile);
  InitTravelFlagFromType;
  InitAreaContentsTravelFlags;
  CreateReversedReachability;
  CalculateAreaTravelTimes;
  InitPortalMaxTravelTimes(AFile.Portals);
  InitReachabilityAreas(ATracer);
end;

procedure TAasRouteData.Validate(const AFile: IAasFile);
var
  LIndex, LPosition: Integer;
  LSettings: TAasAreaSettings;
  LPortals: TArray<TAasPortal>;
  LClusters: TArray<TAasCluster>;
  LPortalIndex: TArray<Integer>;
begin
  if FAreaCount < 1 then
    raise EAasRouteException.Create(SNoAreas);
  if Length(FAreaSettings) < FAreaCount then
    raise EAasRouteException.Create(Format(SSettingsMissing, [FAreaCount, Length(FAreaSettings)]));
  LPortals := AFile.Portals;
  LClusters := AFile.Clusters;
  LPortalIndex := AFile.PortalIndex;
  for LIndex := 0 to FAreaCount - 1 do
  begin
    LSettings := FAreaSettings[LIndex];
    if (LSettings.FirstReachableArea < 0) or (LSettings.NumReachableAreas < 0) or
      (Int64(LSettings.FirstReachableArea) + LSettings.NumReachableAreas > Length(FReachability)) then
      raise EAasRouteException.Create(Format(SReachOutOfRange, [LIndex]));
    if LIndex = 0 then
      Continue;
    if (LSettings.Cluster >= Length(LClusters)) or ((LSettings.Cluster < 0) and (-LSettings.Cluster >= Length(LPortals))) then
      raise EAasRouteException.Create(Format(SClusterOutOfRange, [LIndex, LSettings.Cluster]));
  end;
  for LIndex := 0 to High(FReachability) do
    if (FReachability[LIndex].AreaNum < 0) or (FReachability[LIndex].AreaNum >= FAreaCount) then
      raise EAasRouteException.Create(Format(SReachAreaOutOfRange, [FReachability[LIndex].AreaNum]));
  for LIndex := 0 to High(LPortals) do
    if (LPortals[LIndex].AreaNum < 0) or (LPortals[LIndex].AreaNum >= FAreaCount) or
      (LPortals[LIndex].FrontCluster < 0) or (LPortals[LIndex].FrontCluster >= Length(LClusters)) or
      (LPortals[LIndex].BackCluster < 0) or (LPortals[LIndex].BackCluster >= Length(LClusters)) then
      raise EAasRouteException.Create(Format(SPortalOutOfRange, [LIndex]));
  for LIndex := 0 to High(LClusters) do
  begin
    if (LClusters[LIndex].FirstPortal < 0) or (LClusters[LIndex].NumPortals < 0) or
      (Int64(LClusters[LIndex].FirstPortal) + LClusters[LIndex].NumPortals > Length(LPortalIndex)) then
      raise EAasRouteException.Create(Format(SClusterPortalsOutOfRange, [LIndex]));
    for LPosition := LClusters[LIndex].FirstPortal to LClusters[LIndex].FirstPortal + LClusters[LIndex].NumPortals - 1 do
      if (LPortalIndex[LPosition] < 0) or (LPortalIndex[LPosition] >= Length(LPortals)) then
        raise EAasRouteException.Create(Format(SClusterPortalsOutOfRange, [LIndex]));
  end;
end;

procedure TAasRouteData.InitTravelFlagFromType;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_TRAVELTYPES - 1 do
    FTravelFlagForType[LIndex] := TFL_INVALID;
  FTravelFlagForType[TRAVEL_INVALID] := TFL_INVALID;
  FTravelFlagForType[TRAVEL_WALK] := TFL_WALK;
  FTravelFlagForType[TRAVEL_CROUCH] := TFL_CROUCH;
  FTravelFlagForType[TRAVEL_BARRIERJUMP] := TFL_BARRIERJUMP;
  FTravelFlagForType[TRAVEL_JUMP] := TFL_JUMP;
  FTravelFlagForType[TRAVEL_LADDER] := TFL_LADDER;
  FTravelFlagForType[TRAVEL_WALKOFFLEDGE] := TFL_WALKOFFLEDGE;
  FTravelFlagForType[TRAVEL_SWIM] := TFL_SWIM;
  FTravelFlagForType[TRAVEL_WATERJUMP] := TFL_WATERJUMP;
  FTravelFlagForType[TRAVEL_TELEPORT] := TFL_TELEPORT;
  FTravelFlagForType[TRAVEL_ELEVATOR] := TFL_ELEVATOR;
  FTravelFlagForType[TRAVEL_ROCKETJUMP] := TFL_ROCKETJUMP;
  FTravelFlagForType[TRAVEL_BFGJUMP] := TFL_BFGJUMP;
  FTravelFlagForType[TRAVEL_GRAPPLEHOOK] := TFL_GRAPPLEHOOK;
  FTravelFlagForType[TRAVEL_DOUBLEJUMP] := TFL_DOUBLEJUMP;
  FTravelFlagForType[TRAVEL_RAMPJUMP] := TFL_RAMPJUMP;
  FTravelFlagForType[TRAVEL_STRAFEJUMP] := TFL_STRAFEJUMP;
  FTravelFlagForType[TRAVEL_JUMPPAD] := TFL_JUMPPAD;
  FTravelFlagForType[TRAVEL_FUNCBOB] := TFL_FUNCBOB;
end;

function TAasRouteData.TravelFlagForType(const ATravelType: Integer): Integer;
var
  LType: Integer;
begin
  // the first lines of the original test the flags that are still 0: they do nothing
  LType := ATravelType and TRAVELTYPE_MASK;
  if (LType < 0) or (LType >= MAX_TRAVELTYPES) then
    Exit(TFL_INVALID);
  Result := FTravelFlagForType[LType];
end;

function TAasRouteData.AreaContentsFlags(const AAreaNum: Integer): Integer;
var
  LContents: Integer;
begin
  LContents := FAreaSettings[AAreaNum].Contents;
  Result := 0;
  if (LContents and AREACONTENTS_WATER) <> 0 then
    Result := Result or TFL_WATER
  else if (LContents and AREACONTENTS_SLIME) <> 0 then
    Result := Result or TFL_SLIME
  else if (LContents and AREACONTENTS_LAVA) <> 0 then
    Result := Result or TFL_LAVA
  else
    Result := Result or TFL_AIR;
  if (LContents and AREACONTENTS_DONOTENTER) <> 0 then
    Result := Result or TFL_DONOTENTER;
  if (LContents and AREACONTENTS_NOTTEAM1) <> 0 then
    Result := Result or TFL_NOTTEAM1;
  if (LContents and AREACONTENTS_NOTTEAM2) <> 0 then
    Result := Result or TFL_NOTTEAM2;
  if (FAreaSettings[AAreaNum].AreaFlags and AREA_BRIDGE) <> 0 then
    Result := Result or TFL_BRIDGE;
end;

procedure TAasRouteData.InitAreaContentsTravelFlags;
var
  LIndex: Integer;
begin
  SetLength(FAreaContentsTravelFlags, FAreaCount);
  for LIndex := 0 to FAreaCount - 1 do
    FAreaContentsTravelFlags[LIndex] := AreaContentsFlags(LIndex);
end;

function TAasRouteData.AreaContentsTravelFlags(const AAreaNum: Integer): Integer;
begin
  Result := FAreaContentsTravelFlags[AAreaNum];
end;

procedure TAasRouteData.CreateReversedReachability;
var
  LIndex, LNumber, LTarget, LCount: Integer;
  LSettings: TAasAreaSettings;
  LInsertion: TArray<TArray<TAasReversedLink>>;
  LLink: TAasReversedLink;
begin
  // the original pushes every link at the head of the chain of the area it leads to: the chain is the reverse of
  // the order of the insertion, which goes by area and by reachability
  SetLength(LInsertion, FAreaCount);
  for LIndex := 1 to FAreaCount - 1 do
  begin
    LSettings := FAreaSettings[LIndex];
    if LSettings.NumReachableAreas >= 128 then
      FImport.Print(PRT_WARNING, AnsiString(Format(SMoreThan128, [LIndex])));
    LNumber := 0;
    while (LNumber < LSettings.NumReachableAreas) and (LNumber < 128) do
    begin
      LTarget := FReachability[LSettings.FirstReachableArea + LNumber].AreaNum;
      LLink.AreaNum := LIndex;
      LLink.LinkNum := LSettings.FirstReachableArea + LNumber;
      LCount := Length(LInsertion[LTarget]);
      SetLength(LInsertion[LTarget], LCount + 1);
      LInsertion[LTarget][LCount] := LLink;
      Inc(LNumber);
    end;
  end;
  SetLength(FReversed, FAreaCount);
  for LIndex := 0 to FAreaCount - 1 do
  begin
    LCount := Length(LInsertion[LIndex]);
    SetLength(FReversed[LIndex], LCount);
    for LNumber := 0 to LCount - 1 do
      FReversed[LIndex][LNumber] := LInsertion[LIndex][LCount - 1 - LNumber];
  end;
end;

function TAasRouteData.AreaTravelTime(const AAreaNum: Integer; const AStart, AEnd: TVec3): Word;
var
  LDir: TVec3;
  LDist: Single;
  LInteger: Integer;
begin
  TAasVectorMath.Subtract(AStart, AEnd, LDir);
  LDist := TAasVectorMath.Length(LDir);
  // if crouch only area
  if (FAreaSettings[AAreaNum].PresenceType and PRESENCE_NORMAL) = 0 then
    LDist := LDist * CCrouchFactor
  // if swim area
  else if (FAreaSettings[AAreaNum].AreaFlags and AREA_LIQUID) <> 0 then
    LDist := LDist * CSwimFactor
  // normal walk area
  else
    LDist := LDist * CWalkFactor;
  LInteger := Trunc(LDist);
  // make sure the distance isn't zero
  if LInteger <= 0 then
    LInteger := 1;
  Result := Word(LInteger and $FFFF);
end;

procedure TAasRouteData.CalculateAreaTravelTimes;
var
  LIndex, LLeaving, LArriving, LTotal, LPosition: Integer;
  LSettings: TAasAreaSettings;
  LReach: TAasReachability;
  LEnd: TVec3;
begin
  SetLength(FAreaTravelTimeStart, FAreaCount);
  LTotal := 0;
  for LIndex := 0 to FAreaCount - 1 do
  begin
    FAreaTravelTimeStart[LIndex] := LTotal;
    Inc(LTotal, FAreaSettings[LIndex].NumReachableAreas * Length(FReversed[LIndex]));
  end;
  SetLength(FAreaTravelTimes, LTotal);
  for LIndex := 0 to FAreaCount - 1 do
  begin
    LSettings := FAreaSettings[LIndex];
    for LLeaving := 0 to LSettings.NumReachableAreas - 1 do
    begin
      LReach := FReachability[LSettings.FirstReachableArea + LLeaving];
      LPosition := FAreaTravelTimeStart[LIndex] + LLeaving * Length(FReversed[LIndex]);
      for LArriving := 0 to Length(FReversed[LIndex]) - 1 do
      begin
        LEnd := FReachability[FReversed[LIndex][LArriving].LinkNum].EndPoint;
        FAreaTravelTimes[LPosition + LArriving] := AreaTravelTime(LIndex, LEnd, LReach.StartPoint);
      end;
    end;
  end;
end;

procedure TAasRouteData.InitPortalMaxTravelTimes(const APortals: TArray<TAasPortal>);
var
  LIndex, LLeaving, LArriving, LTime, LMax, LArea: Integer;
begin
  SetLength(FPortalMaxTravelTimes, Length(APortals));
  for LIndex := 0 to High(APortals) do
  begin
    LArea := APortals[LIndex].AreaNum;
    LMax := 0;
    for LLeaving := 0 to FAreaSettings[LArea].NumReachableAreas - 1 do
      for LArriving := 0 to Length(FReversed[LArea]) - 1 do
      begin
        LTime := FAreaTravelTimes[FAreaTravelTimeStart[LArea] + LLeaving * Length(FReversed[LArea]) + LArriving];
        if LTime > LMax then
          LMax := LTime;
      end;
    FPortalMaxTravelTimes[LIndex] := LMax;
  end;
end;

procedure TAasRouteData.InitReachabilityAreas(const ATracer: IAasTracer);
var
  LIndex, LJ, LCount, LTotal: Integer;
  LReach: TAasReachability;
  LStart, LEnd: TVec3;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
begin
  SetLength(FReachabilityAreaFirst, Length(FReachability));
  SetLength(FReachabilityAreaCount, Length(FReachability));
  SetLength(FReachabilityAreaIndex, 0);
  LTotal := 0;
  for LIndex := 0 to High(FReachability) do
  begin
    LReach := FReachability[LIndex];
    LCount := 0;
    case LReach.TravelType and TRAVELTYPE_MASK of
      // trace areas from start to end
      TRAVEL_BARRIERJUMP, TRAVEL_WATERJUMP:
        begin
          LEnd := LReach.StartPoint;
          LEnd[2] := LReach.EndPoint[2];
          LCount := ATracer.TraceAreas(LReach.StartPoint, LEnd, MAX_REACHABILITYPASSAREAS, LAreas, LPoints);
        end;
      TRAVEL_WALKOFFLEDGE:
        begin
          LStart := LReach.EndPoint;
          LStart[2] := LReach.StartPoint[2];
          LCount := ATracer.TraceAreas(LStart, LReach.EndPoint, MAX_REACHABILITYPASSAREAS, LAreas, LPoints);
        end;
      TRAVEL_GRAPPLEHOOK:
        LCount := ATracer.TraceAreas(LReach.StartPoint, LReach.EndPoint, MAX_REACHABILITYPASSAREAS, LAreas, LPoints);
      // the arches, the elevators, the walks, ladders, swims, teleports: no areas in between
    end;
    FReachabilityAreaFirst[LIndex] := LTotal;
    FReachabilityAreaCount[LIndex] := LCount;
    SetLength(FReachabilityAreaIndex, LTotal + LCount);
    for LJ := 0 to LCount - 1 do
      FReachabilityAreaIndex[LTotal + LJ] := LAreas[LJ];
    Inc(LTotal, LCount);
  end;
end;

end.
