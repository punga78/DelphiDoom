{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the scenario of the routing golden   }
{                                                                              }
{  The twin of Tools\Verifica\122\route\routegen.c: every line that the real   }
{  routing of Quake III prints is printed here with the same text.             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Route.Scenario;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.MathCore.Types,
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf,
  DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Route.Router;

type
  /// <summary>Runs the scenario on one AAS file and writes the lines of the C tool</summary>
  TAasRouteScenario = class
  strict private
    FOutput: TStrings;
    FMemoryLimit: Integer;
    FSeed: Cardinal;
    FReach: TArray<Integer>;
    FFile: IAasFile;
    FRouter: TAasRouter;
    FRouterIntf: IAasRouter;
    function Rnd: Cardinal;
    function Pick: Integer;
    function Vector(const ATag: string; const AValue: TVec3): string;
    procedure Counts(const ATag: string);
    procedure Routes(const ATag: string; const ACount, AVariant: Integer);
    procedure Predict(const ACount: Integer);
    procedure Alternatives(const ACount: Integer);
    procedure Enables;
    procedure Reaches;
    procedure DumpData;
  public
    /// <summary>The lines go to <c>AOutput</c>; <c>AMemoryLimit</c> 0: the memory is never short</summary>
    constructor Create(const AOutput: TStrings; const AMemoryLimit: Integer);
    /// <summary>
    ///   Loads the bytes of an .aas file (the checksum of the BSP is the one in its header) and runs the scenario
    /// </summary>
    procedure Run(const AName: string; const ABytes: TBytes);
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.HeaderCipher, DelphiDoom.Aas.Factory,
  DelphiDoom.Aas.Route.Data, DelphiDoom.Tests.Aas.Support;

type
  TScenarioImport = class(TInterfacedObject, IBotImport)
  strict private
    FOutput: TStrings;
  public
    constructor Create(const AOutput: TStrings);
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    procedure LogWrite(const AMessage: AnsiString);
    function Time: Single;
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
  end;

  /// <summary>
  ///   The memory that is left, as the C tool says: the limit minus what the routing cache holds (0: never short)
  /// </summary>
  TScenarioMemory = class(TInterfacedObject, IAasRoutingMemory)
  strict private
    FLimit: Integer;
    FRouter: TAasRouter;
  public
    constructor Create(const ALimit: Integer);
    procedure SetRouter(const ARouter: TAasRouter);
    function AvailableMemory: Integer;
  end;

const
  FLAGS: array[0..2] of Integer = (
    TFL_DEFAULT,
    TFL_WALK or TFL_CROUCH or TFL_AIR or TFL_WATER,
    TFL_DEFAULT and not (TFL_WALKOFFLEDGE or TFL_JUMP or TFL_JUMPPAD));

{ TScenarioImport }

constructor TScenarioImport.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TScenarioImport.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
  FOutput.Add(Format('P%d|%s', [ALevel, Escaped(string(AMessage))]));
end;

procedure TScenarioImport.LogWrite(const AMessage: AnsiString);
begin
end;

function TScenarioImport.Time: Single;
begin
  Result := 0;
end;

procedure TScenarioImport.Command(const AClient: Integer; const ACommand: AnsiString);
begin
end;

{ TScenarioMemory }

constructor TScenarioMemory.Create(const ALimit: Integer);
begin
  inherited Create;
  FLimit := ALimit;
end;

procedure TScenarioMemory.SetRouter(const ARouter: TAasRouter);
begin
  FRouter := ARouter;
end;

function TScenarioMemory.AvailableMemory: Integer;
var
  LAreas, LPortals, LMemory: Integer;
begin
  if (FLimit = 0) or not Assigned(FRouter) then
    Exit(1 shl 30);
  FRouter.CacheStatistics(LAreas, LPortals, LMemory);
  Result := FLimit - LMemory;
end;

{ TAasRouteScenario }

constructor TAasRouteScenario.Create(const AOutput: TStrings; const AMemoryLimit: Integer);
begin
  inherited Create;
  FOutput := AOutput;
  FMemoryLimit := AMemoryLimit;
end;

function TAasRouteScenario.Rnd: Cardinal;
begin
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

function TAasRouteScenario.Pick: Integer;
begin
  Result := FReach[Rnd mod Cardinal(Length(FReach))];
end;

function TAasRouteScenario.Vector(const ATag: string; const AValue: TVec3): string;
begin
  Result := Format(' %s #%s #%s #%s', [ATag, Hex(Bits(AValue[0])), Hex(Bits(AValue[1])), Hex(Bits(AValue[2]))]);
end;

procedure TAasRouteScenario.Counts(const ATag: string);
var
  LAreas, LPortals, LMemory, LAreaUpdates, LPortalUpdates: Integer;
begin
  FRouter.CacheStatistics(LAreas, LPortals, LMemory);
  FRouter.UpdateCounts(LAreaUpdates, LPortalUpdates);
  FOutput.Add(Format('%s %d %d %d %d %d', [ATag, LAreas, LPortals, LMemory, LAreaUpdates, LPortalUpdates]));
end;

procedure TAasRouteScenario.Routes(const ATag: string; const ACount, AVariant: Integer);
var
  LIndex, LA, LB, LV, LTime, LReach: Integer;
  LOk: Boolean;
  LOrigin: TVec3;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    LA := Pick;
    LB := Pick;
    if AVariant >= 0 then
      LV := AVariant
    else
      LV := LIndex mod 3;
    LTime := -7;
    LReach := -1;
    LOrigin := FFile.Areas[LA].Center;
    LOk := FRouterIntf.AreaRouteToGoalArea(LA, @LOrigin, LB, FLAGS[LV], LTime, LReach);
    FOutput.Add(Format('%s %d %d %d %d %d %d %d', [ATag, LIndex, LA, LB, LV, Ord(LOk), LTime, LReach]));
    LTime := -7;
    LReach := -1;
    LOk := FRouterIntf.AreaRouteToGoalArea(LA, nil, LB, FLAGS[LV], LTime, LReach);
    FOutput.Add(Format('%sN %d %d %d %d %d %d %d', [ATag, LIndex, LA, LB, LV, Ord(LOk), LTime, LReach]));
  end;
end;

procedure TAasRouteScenario.Predict(const ACount: Integer);
const
  EVENTS: array[0..4] of Integer = (RSE_NONE, RSE_USETRAVELTYPE, RSE_ENTERCONTENTS, RSE_ENTERAREA,
    RSE_USETRAVELTYPE or RSE_ENTERCONTENTS or RSE_ENTERAREA);
var
  LIndex, LA, LB, LV, LStopArea: Integer;
  LOk: Boolean;
  LRoute: TAasPredictRoute;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    LA := Pick;
    LB := Pick;
    LV := LIndex mod 3;
    FillChar(LRoute, SizeOf(LRoute), 0);
    LStopArea := Pick;
    LOk := FRouterIntf.PredictRoute(LRoute, LA, FFile.Areas[LA].Center, LB, FLAGS[LV], (LIndex mod 4) * 5,
      (LIndex mod 3) * 400, EVENTS[LIndex mod 5], AREACONTENTS_WATER or AREACONTENTS_JUMPPAD or AREACONTENTS_TELEPORTER,
      TFL_JUMP or TFL_TELEPORT or TFL_JUMPPAD or TFL_WATER or TFL_ELEVATOR, LStopArea);
    FOutput.Add(Format('PR %d %d %d %d %d', [LIndex, LA, LB, LV, Ord(LOk)]) + Vector('P', LRoute.EndPos) +
      Format(' %d %d %d %d %d', [LRoute.EndArea, LRoute.StopEvent, LRoute.EndContents, LRoute.EndTravelFlags,
      LRoute.Time]));
  end;
end;

procedure TAasRouteScenario.Alternatives(const ACount: Integer);
const
  TYPES: array[0..2] of Integer = (ALTROUTEGOAL_ALL, ALTROUTEGOAL_CLUSTERPORTALS,
    ALTROUTEGOAL_CLUSTERPORTALS or ALTROUTEGOAL_VIEWPORTALS);
var
  LIndex, LA, LB, LNum, LGoal: Integer;
  LGoals: TArray<TAasAltRouteGoal>;
  LLine: string;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    LA := Pick;
    LB := Pick;
    SetLength(LGoals, 8);
    LNum := FRouterIntf.AlternativeRouteGoals(FFile.Areas[LA].Center, LA, FFile.Areas[LB].Center, LB, TFL_DEFAULT,
      LGoals, 8, TYPES[LIndex mod 3]);
    LLine := Format('AL %d %d %d %d', [LIndex, LA, LB, LNum]);
    for LGoal := 0 to LNum - 1 do
      LLine := LLine + Vector('G', LGoals[LGoal].Origin) + Format(' %d %d %d %d', [LGoals[LGoal].AreaNum,
        Integer(LGoals[LGoal].StartTravelTime), Integer(LGoals[LGoal].GoalTravelTime),
        Integer(LGoals[LGoal].ExtraTravelTime)]);
    FOutput.Add(LLine);
  end;
end;

procedure TAasRouteScenario.Enables;
var
  LIndex, LA, LR: Integer;
  LSettings: TArray<TAasAreaSettings>;
begin
  LSettings := FFile.AreaSettings;
  for LIndex := 0 to 3 do
  begin
    LA := Pick;
    LR := FRouterIntf.EnableRoutingArea(LA, -1);
    FOutput.Add(Format('EN %d %d read %d', [LIndex, LA, LR]) + Format(' off %d', [FRouterIntf.EnableRoutingArea(LA, 0)]) +
      Format(' flags %d', [LSettings[LA].AreaFlags]));
    Routes('RD', 20, 0);
    Counts('CD');
    LR := FRouterIntf.EnableRoutingArea(LA, 1);
    FOutput.Add(Format('EN %d %d on %d flags %d', [LIndex, LA, LR, LSettings[LA].AreaFlags]));
    Routes('RE', 10, 0);
  end;
  FOutput.Add(Format('EN0 %d', [FRouterIntf.EnableRoutingArea(0, 1)]));
  FOutput.Add(Format('ENN %d', [FRouterIntf.EnableRoutingArea(Length(FFile.Areas), -1)]));
end;

procedure TAasRouteScenario.Reaches;
var
  LIndex, LA, LR, LSteps, LGuard, LNext: Integer;
  LLine: string;
  LReach: TAasReachability;
  LSettings: TArray<TAasAreaSettings>;
begin
  LSettings := FFile.AreaSettings;
  for LIndex := 0 to 7 do
  begin
    LA := Pick;
    LLine := Format('NR %d %d %d', [LIndex, LA, LSettings[LA].NumReachableAreas]);
    LR := 0;
    LSteps := 0;
    while LSteps < 40 do
    begin
      LR := FRouterIntf.NextAreaReachability(LA, LR);
      LLine := LLine + ' ' + IntToStr(LR);
      if LR = 0 then
        Break;
      Inc(LSteps);
    end;
    FOutput.Add(LLine);
  end;
  FOutput.Add(Format('NR0 %d', [FRouterIntf.NextAreaReachability(0, 0)]));
  for LIndex := 0 to 3 do
  begin
    if Length(FFile.Reachability) > 0 then
      LR := Integer(Rnd mod Cardinal(Length(FFile.Reachability)))
    else
      LR := 0;
    FRouterIntf.ReachabilityFromNum(LR, LReach);
    FOutput.Add(Format('RF %d %d %d %d %d', [LIndex, LR, LReach.AreaNum, LReach.FaceNum, LReach.EdgeNum]) +
      Vector('S', LReach.StartPoint) + Vector('E', LReach.EndPoint) +
      Format(' %d %d', [LReach.TravelType, Integer(LReach.TravelTime)]));
  end;
  FRouterIntf.ReachabilityFromNum(-1, LReach);
  FOutput.Add(Format('RFN %d %d', [LReach.AreaNum, LReach.TravelType]));
  FRouterIntf.ReachabilityFromNum(Length(FFile.Reachability), LReach);
  FOutput.Add(Format('RFM %d %d', [LReach.AreaNum, LReach.TravelType]));
  for LIndex := 0 to 5 do
  begin
    LNext := 0;
    LGuard := 0;
    LLine := Format('NM %d', [LIndex]);
    repeat
      LNext := FRouterIntf.NextModelReachability(LNext, LIndex);
      if (LNext <> 0) and (LGuard < 40) then
      begin
        LLine := LLine + ' ' + IntToStr(LNext);
        Inc(LGuard);
      end;
    until (LNext = 0) or (LGuard >= 40);
    FOutput.Add(LLine);
  end;
end;

procedure TAasRouteScenario.DumpData;
var
  LData: TAasRouteData;
  LIndex, LLeaving, LArriving: Integer;
  LHash: Cardinal;
  LSettings: TArray<TAasAreaSettings>;
begin
  LData := FRouter.RouteData;
  LSettings := FFile.AreaSettings;
  for LIndex := 0 to Length(FFile.Portals) - 1 do
    FOutput.Add(Format('PM %d %d', [LIndex, LData.PortalMaxTravelTimes[LIndex]]));
  for LIndex := 0 to Length(FFile.Reachability) - 1 do
  begin
    if LIndex >= 4000 then
      Break;
    FOutput.Add(Format('RA %d %d %d', [LIndex, LData.ReachabilityAreaFirst[LIndex], LData.ReachabilityAreaCount[LIndex]]));
  end;
  LHash := 2166136261;
  for LIndex := 0 to LData.AreaCount - 1 do
    for LLeaving := 0 to LSettings[LIndex].NumReachableAreas - 1 do
      for LArriving := 0 to Length(LData.Reversed[LIndex]) - 1 do
      begin
        LHash := LHash xor LData.AreaTravelTimes[LData.AreaTravelTimeStart[LIndex] + LLeaving *
          Length(LData.Reversed[LIndex]) + LArriving];
        LHash := LHash * 16777619;
      end;
  FOutput.Add(Format('ATT %u', [LHash]));
  for LIndex := 0 to MAX_TRAVELTYPES - 1 do
    FOutput.Add(Format('TF %d %d', [LIndex, FRouterIntf.TravelFlagForType(LIndex)]));
  FOutput.Add(Format('TF -1 %d', [FRouterIntf.TravelFlagForType(-1)]));
  FOutput.Add(Format('TF 99 %d', [FRouterIntf.TravelFlagForType(99)]));
end;

procedure TAasRouteScenario.Run(const AName: string; const ABytes: TBytes);
var
  LHeader: TAasFileHeader;
  LImport: IBotImport;
  LMemory: TScenarioMemory;
  LMemoryIntf: IAasRoutingMemory;
  LIndex, LAreas: Integer;
  LReaches: TList<Integer>;
begin
  FOutput.Add('FILE ' + AName);
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  if LHeader.Version = AAS_VERSION then
    TAasHeaderCipher.Apply(LHeader);
  LImport := TScenarioImport.Create(FOutput);
  FFile := TAasFactory.CreateReader(LImport, nil, nil).ParseBytes(ABytes, 'maps/routing.aas', LHeader.BspChecksum);
  FOutput.Add('LOAD 0');
  LMemory := TScenarioMemory.Create(FMemoryLimit);
  LMemoryIntf := LMemory;
  FRouterIntf := TAasRouter.Create(FFile, LImport, TAasFactory.CreateTracer(FFile, LImport), LMemoryIntf, True);
  FRouter := TAasRouter(FRouterIntf as TObject);
  LMemory.SetRouter(FRouter);
  LAreas := Length(FFile.Areas);
  FOutput.Add(Format('AAS %d %d %d %d', [LAreas, Length(FFile.Clusters), Length(FFile.Portals),
    Length(FFile.Reachability)]));
  if LAreas < 3 then
    Exit;
  DumpData;
  LReaches := TList<Integer>.Create;
  try
    for LIndex := 1 to LAreas - 1 do
      if FFile.AreaSettings[LIndex].NumReachableAreas <> 0 then
        LReaches.Add(LIndex);
    FReach := LReaches.ToArray;
  finally
    LReaches.Free;
  end;
  FOutput.Add(Format('PK %d', [Length(FReach)]));
  if Length(FReach) < 2 then
    Exit;
  FSeed := 2463534242;
  Counts('C0');
  Routes('RT', 300, -1);
  Counts('C1');
  Predict(60);
  Alternatives(12);
  Enables;
  Counts('C2');
  Reaches;
  Counts('C3');
  FRouterIntf := nil;
  FRouter := nil;
end;

end.
