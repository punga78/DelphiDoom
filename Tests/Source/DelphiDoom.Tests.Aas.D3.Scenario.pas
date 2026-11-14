{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 AAS navigation - the scenario of the golden }
{                                                                              }
{  The twin of Tools\Verifica\109\route_driver.cpp: every line that the real   }
{  idAASLocal prints is printed here with the same text.                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.D3.Scenario;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Aas.D3.Navigator;

type
  /// <summary>Runs the scenario on the .aas files of Tests\Data\AasD3 and writes what the C++ driver writes</summary>
  TD3ScenarioRunner = class
  strict private
    FOutput: TStrings;
    FMaxCacheMemory: Integer;
    FNavigator: TAasNavigator;
    procedure Emit(const ALine: string);
    procedure DumpAreas;
    procedure DumpCache;
    procedure Routes(const ATag: string; const AVariant, AStep: Integer);
    procedure Changes(const ATag: string);
    procedure Paths;
    procedure Goals;
    procedure Walls;
    procedure Obstacles;
    procedure RunCase(const AName: string; const ACrc: Cardinal);
  public
    /// <summary>The lines go to <c>AOutput</c>; <c>AMaxCacheMemory</c> is the limit of the routing caches</summary>
    constructor Create(const AOutput: TStrings; const AMaxCacheMemory: Integer);
    /// <summary>Runs the cases listed in the text (name and CRC, one per line, # for a comment)</summary>
    procedure Run(const ACases: TStrings);
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Aas.Types,
  DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Area, DelphiDoom.MapFile.Aas.Reachability,
  DelphiDoom.Aas.D3.Types, DelphiDoom.Aas.D3.Intf, DelphiDoom.Aas.D3.Factory, DelphiDoom.Tests.Aas.D3.Support;

const
  TRAVEL: array[0..2] of Integer = (
    TFL_WALK or TFL_CROUCH or TFL_WALKOFFLEDGE or TFL_BARRIERJUMP or TFL_JUMP or TFL_LADDER or TFL_SWIM or
      TFL_WATERJUMP or TFL_TELEPORT or TFL_ELEVATOR or TFL_FLY or TFL_WATER or TFL_AIR,
    TFL_WALK or TFL_CROUCH or TFL_AIR,
    TFL_WALK or TFL_CROUCH or TFL_WALKOFFLEDGE or TFL_BARRIERJUMP or TFL_JUMP or TFL_LADDER or TFL_SWIM or
      TFL_WATERJUMP or TFL_TELEPORT or TFL_ELEVATOR or TFL_WATER or TFL_AIR);

type
  /// <summary>The log of the original in the output: Printf and Warning of the C++ driver</summary>
  TScenarioLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FOutput: TStrings;
  public
    constructor Create(const AOutput: TStrings);
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
  end;

  TModuloCallback = class(TInterfacedObject, IAasAreaCallback)
  strict private
    FModulus: Integer;
    FRemainder: Integer;
    FAsked: Integer;
  public
    constructor Create(const AModulus, ARemainder: Integer);
    function TestArea(const ANavigator: IAasNavigator; const AAreaNum: Integer): Boolean;
    property Asked: Integer read FAsked;
  end;

function B(const AValue: TGeoVec3): string;
begin
  Result := D3VectorBits(AValue);
end;

function BoolInt(const AValue: Boolean): Integer;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

{ TScenarioLog }

constructor TScenarioLog.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TScenarioLog.Printf(const AMessage: string);
begin
  FOutput.Add('P: ' + AMessage + '\n');
end;

procedure TScenarioLog.Warning(const AMessage: string);
begin
  FOutput.Add('W: ' + AMessage);
end;

{ TModuloCallback }

constructor TModuloCallback.Create(const AModulus, ARemainder: Integer);
begin
  inherited Create;
  FModulus := AModulus;
  FRemainder := ARemainder;
end;

function TModuloCallback.TestArea(const ANavigator: IAasNavigator; const AAreaNum: Integer): Boolean;
begin
  Inc(FAsked);
  Result := (AAreaNum * 7 + FRemainder) mod FModulus = 0;
end;

{ TD3ScenarioRunner }

constructor TD3ScenarioRunner.Create(const AOutput: TStrings; const AMaxCacheMemory: Integer);
begin
  inherited Create;
  FOutput := AOutput;
  FMaxCacheMemory := AMaxCacheMemory;
end;

procedure TD3ScenarioRunner.Emit(const ALine: string);
begin
  FOutput.Add(ALine);
end;

procedure TD3ScenarioRunner.DumpAreas;
var
  LFile: TAasFile;
  LIndex, LNumber: Integer;
  LArea: TAasArea;
  LReach: TAasReachability;
begin
  LFile := FNavigator.AasFile;
  Emit(Format('AREAS %d %d %d', [LFile.NumAreas, LFile.NumClusters, LFile.NumPortals]));
  for LIndex := 0 to LFile.NumAreas - 1 do
  begin
    LArea := LFile.Areas[LIndex];
    Emit(Format('AR %d %d %d %d %d %d C %s', [LIndex, Integer(LArea.Flags), LArea.TravelFlags, Integer(LArea.Contents),
      Integer(LArea.Cluster), Integer(LArea.ClusterAreaNum), B(FNavigator.AreaCenter(LIndex))]));
  end;
  for LIndex := 1 to LFile.NumPortals - 1 do
    Emit(Format('PT %d %d %d', [LIndex, Integer(LFile.Portals[LIndex].AreaNum),
      Integer(LFile.Portals[LIndex].MaxAreaTravelTime)]));
  for LIndex := 0 to LFile.NumAreas - 1 do
    for LNumber := 0 to LFile.Areas[LIndex].Reach.Count - 1 do
    begin
      LReach := LFile.Areas[LIndex].Reach[LNumber];
      Emit(Format('RE %d %d %d %d %d %d %d', [LIndex, LNumber, LReach.TravelType, Integer(LReach.ToAreaNum),
        Integer(LReach.Number), Integer(LReach.DisableCount), Integer(LReach.TravelTime)]));
    end;
end;

procedure TD3ScenarioRunner.DumpCache;
var
  LAreas, LPortals: Integer;
begin
  FNavigator.CacheCounts(LAreas, LPortals);
  Emit(Format('CACHE %d %d %d', [LAreas, LPortals, FNavigator.CacheMemory]));
end;

procedure TD3ScenarioRunner.Routes(const ATag: string; const AVariant, AStep: Integer);
var
  LNum, LA, LB, LTime: Integer;
  LReach: TAasReachability;
  LOk: Boolean;
  LOrigin: TGeoVec3;
  LTo, LNumber: Integer;
begin
  LNum := FNavigator.AasFile.NumAreas;
  LA := 1;
  while LA < LNum do
  begin
    for LB := 1 to LNum - 1 do
    begin
      if LA = LB then
        Continue;
      LReach := nil;
      LTime := -7;
      LOrigin := FNavigator.AreaCenter(LA);
      LOk := FNavigator.RouteToGoalArea(LA, LOrigin, LB, TRAVEL[AVariant], LTime, LReach);
      LTo := -1;
      LNumber := -1;
      if Assigned(LReach) then
      begin
        LTo := LReach.ToAreaNum;
        LNumber := LReach.Number;
      end;
      Emit(Format('%s %d %d %d %d %d %d %d', [ATag, AVariant, LA, LB, BoolInt(LOk), LTime, LTo, LNumber]));
    end;
    Inc(LA, AStep);
  end;
end;

procedure TD3ScenarioRunner.Changes(const ATag: string);
var
  LFile: TAasFile;
  LIndex, LNumber: Integer;
  LArea: TAasArea;
  LReach: TAasReachability;
begin
  LFile := FNavigator.AasFile;
  for LIndex := 1 to LFile.NumAreas - 1 do
  begin
    LArea := LFile.Areas[LIndex];
    if (LArea.TravelFlags and TFL_INVALID) <> 0 then
      Emit(Format('%s AF %d %d', [ATag, LIndex, LArea.TravelFlags]));
    for LNumber := 0 to LArea.Reach.Count - 1 do
    begin
      LReach := LArea.Reach[LNumber];
      if ((LReach.TravelType and TFL_INVALID) <> 0) or (LReach.DisableCount <> 0) then
        Emit(Format('%s RF %d %d %d %d', [ATag, LIndex, LNumber, LReach.TravelType, Integer(LReach.DisableCount)]));
    end;
  end;
end;

procedure TD3ScenarioRunner.Paths;
var
  LNum, LA, LB, LV, LEndArea: Integer;
  LOrigin, LGoal, LEndPos: TGeoVec3;
  LPath: TAasPath;
  LOk: Boolean;
  LNumber: Integer;
begin
  LNum := FNavigator.AasFile.NumAreas;
  for LA := 1 to LNum - 1 do
  begin
    LB := (LA * 5 + 3) mod (LNum - 1) + 1;
    if LB = LA then
      LB := LB mod (LNum - 1) + 1;
    LOrigin := FNavigator.AreaCenter(LA);
    LOrigin.X := LOrigin.X + 6;
    LOrigin.Y := LOrigin.Y - 5;
    LOrigin.Z := LOrigin.Z + 1;
    LGoal := FNavigator.AreaCenter(LB);
    LGoal.X := LGoal.X - 7;
    LGoal.Y := LGoal.Y + 4;
    LGoal.Z := LGoal.Z + 1;
    for LV := 0 to 1 do
    begin
      LOk := FNavigator.WalkPathToGoal(LPath, LA, LOrigin, LB, LGoal, TRAVEL[LV]);
      LNumber := -1;
      if Assigned(LPath.Reachability) then
        LNumber := LPath.Reachability.Number;
      Emit(Format('WP %d %d %d %d %d G %s %d S %s %d', [LV, LA, LB, BoolInt(LOk), LPath.Kind, B(LPath.MoveGoal),
        LPath.MoveAreaNum, B(LPath.SecondaryGoal), LNumber]));
    end;
    LEndArea := -99;
    LOk := FNavigator.WalkPathValid(LA, LOrigin, LB, LGoal, TRAVEL[0], LEndPos, LEndArea);
    if not LOk then
      LEndArea := -1;
    Emit(Format('WV %d %d %d E %s %d', [LA, LB, BoolInt(LOk), B(LEndPos), LEndArea]));
    LEndArea := -99;
    LOk := FNavigator.WalkPathValid(LA, LOrigin, LA, LGoal, TRAVEL[1], LEndPos, LEndArea);
    if not LOk then
      LEndArea := -1;
    Emit(Format('WW %d %d %d E %s %d', [LA, LB, BoolInt(LOk), B(LEndPos), LEndArea]));

    LOk := FNavigator.FlyPathToGoal(LPath, LA, LOrigin, LB, LGoal, TRAVEL[0]);
    Emit(Format('FP %d %d %d %d G %s %d S %s', [LA, LB, BoolInt(LOk), LPath.Kind, B(LPath.MoveGoal),
      LPath.MoveAreaNum, B(LPath.SecondaryGoal)]));
    LEndArea := -99;
    LOk := FNavigator.FlyPathValid(LA, LOrigin, LB, LGoal, TRAVEL[0], LEndPos, LEndArea);
    Emit(Format('FV %d %d %d E %s %d', [LA, LB, BoolInt(LOk), B(LEndPos), LEndArea]));
  end;
end;

procedure TD3ScenarioRunner.Goals;
var
  LNum, LA, LB, LM, LO, LModulus: Integer;
  LOrigin, LTarget, LCenter: TGeoVec3;
  LCallback: TModuloCallback;
  LCallbackIntf: IAasAreaCallback;
  LObstacles: TArray<TAasObstacle>;
  LGoal: TAasGoal;
  LOk: Boolean;
  LLine: string;
begin
  LNum := FNavigator.AasFile.NumAreas;
  for LA := 1 to LNum - 1 do
  begin
    LB := (LA * 3 + 1) mod (LNum - 1) + 1;
    LOrigin := FNavigator.AreaCenter(LA);
    LTarget := FNavigator.AreaCenter(LB);
    for LM := 0 to 2 do
      for LO := 0 to 1 do
      begin
        case LM of
          0: LModulus := 5;
          1: LModulus := 3;
        else
          LModulus := 11;
        end;
        LCallback := TModuloCallback.Create(LModulus, (LA + LM) mod 3);
        LCallbackIntf := LCallback;
        SetLength(LObstacles, 0);
        if LO <> 0 then
        begin
          SetLength(LObstacles, 1);
          LCenter := FNavigator.AreaCenter((LA * 2) mod (LNum - 1) + 1);
          LObstacles[0].AbsBounds.Mins := TGeoVec3.Make(LCenter.X - 10, LCenter.Y - 10, LCenter.Z);
          LObstacles[0].AbsBounds.Maxs := TGeoVec3.Make(LCenter.X + 10, LCenter.Y + 10, LCenter.Z + 40);
        end;
        LGoal.AreaNum := -5;
        LGoal.Origin := TGeoVec3.Make(1, 2, 3);
        if LM = 2 then
          LOk := FNavigator.FindNearestGoal(LGoal, LA, LOrigin, LTarget, TRAVEL[2], LObstacles, LCallbackIntf)
        else
          LOk := FNavigator.FindNearestGoal(LGoal, LA, LOrigin, LTarget, TRAVEL[0], LObstacles, LCallbackIntf);
        LLine := Format('FG %d %d %d %d %d %d O %s %d', [LA, LB, LM, LO, BoolInt(LOk), LGoal.AreaNum,
          B(LGoal.Origin), LCallback.Asked]);
        if Length(LObstacles) > 0 then
          LLine := LLine + Format(' X %s Y %s', [B(LObstacles[0].ExpAbsBounds.Mins), B(LObstacles[0].ExpAbsBounds.Maxs)]);
        Emit(LLine);
      end;
  end;
end;

procedure TD3ScenarioRunner.Walls;
var
  LNum, LA, LK, LCount, LIndex: Integer;
  LAll, LSmall, LBounds: TGeoBounds;
  LEdges: TArray<Integer>;
  LLine: string;
  LVertex0, LVertex1: Integer;
  LStart, LEnd: TGeoVec3;
begin
  LNum := FNavigator.AasFile.NumAreas;
  LAll := TGeoBounds.Make(TGeoVec3.Make(-10000, -10000, -10000), TGeoVec3.Make(10000, 10000, 10000));
  LSmall := TGeoBounds.Make(TGeoVec3.Make(-10000, -10000, -10000), TGeoVec3.Make(10, 10, 10000));
  for LA := 1 to LNum - 1 do
    for LK := 0 to 1 do
    begin
      if LK <> 0 then
        LBounds := LSmall
      else
        LBounds := LAll;
      SetLength(LEdges, 64);
      LCount := FNavigator.GetWallEdges(LA, LBounds, TRAVEL[0], LEdges, 64);
      LLine := Format('WE %d %d %d', [LA, LK, LCount]);
      for LIndex := 0 to LCount - 1 do
        LLine := LLine + ' ' + IntToStr(LEdges[LIndex]);
      Emit(LLine);
      FNavigator.SortWallEdges(LEdges, LCount);
      LLine := Format('WS %d %d', [LA, LK]);
      for LIndex := 0 to LCount - 1 do
        LLine := LLine + ' ' + IntToStr(LEdges[LIndex]);
      Emit(LLine);
    end;
  for LA := -3 to 3 do
  begin
    FNavigator.GetEdgeVertexNumbers(LA, LVertex0, LVertex1);
    FNavigator.GetEdge(LA, LStart, LEnd);
    Emit(Format('EV %d %d %d S %s E %s', [LA, LVertex0, LVertex1, B(LStart), B(LEnd)]));
  end;
end;

procedure TD3ScenarioRunner.Obstacles;
var
  LNum, LIndex: Integer;
  LCenter: TGeoVec3;
  LBounds: TGeoBounds;
  LOk: Boolean;
  LHandle: array[0..2] of Integer;
begin
  LNum := FNavigator.AasFile.NumAreas;
  // areas that are cluster portals are shut and opened
  for LIndex := 1 to LNum - 1 do
  begin
    if (FNavigator.AasFile.Areas[LIndex].Contents and AREACONTENTS_CLUSTERPORTAL) = 0 then
      Continue;
    LCenter := FNavigator.AreaCenter(LIndex);
    LBounds := TGeoBounds.Make(TGeoVec3.Make(LCenter.X - 2, LCenter.Y - 2, LCenter.Z),
      TGeoVec3.Make(LCenter.X + 2, LCenter.Y + 2, LCenter.Z + 8));
    LOk := FNavigator.SetAreaState(LBounds, AREACONTENTS_CLUSTERPORTAL, True);
    Emit(Format('SAS %d %d', [LIndex, BoolInt(LOk)]));
    Changes('SD');
    Routes('RD', 0, 5);
    DumpCache;
    LOk := FNavigator.SetAreaState(LBounds, AREACONTENTS_CLUSTERPORTAL, False);
    Emit(Format('SAE %d %d', [LIndex, BoolInt(LOk)]));
    Changes('SE');
    Routes('RE2', 0, 7);
  end;
  LBounds := TGeoBounds.Make(TGeoVec3.Make(-5000, -5000, 500), TGeoVec3.Make(-4000, -4000, 600));
  Emit(Format('SAN %d', [BoolInt(FNavigator.SetAreaState(LBounds, AREACONTENTS_CLUSTERPORTAL, True))]));
  // AddObstacle calls SetObstacleState( obstacle, true ) and RemoveObstacle calls it with false: the original
  // wraps the unsigned char count and ends with reachabilities that stay invalid, and so does this
  for LIndex := 0 to 2 do
  begin
    LCenter := FNavigator.AreaCenter(1 + (LIndex * 5) mod (LNum - 1));
    LBounds := TGeoBounds.Make(TGeoVec3.Make(LCenter.X - 40, LCenter.Y - 40, LCenter.Z),
      TGeoVec3.Make(LCenter.X + 40, LCenter.Y + 40, LCenter.Z + 60));
    LHandle[LIndex] := FNavigator.AddObstacle(LBounds);
    Emit(Format('AO %d %d', [LIndex, LHandle[LIndex]]));
    Changes('OA');
    Routes('RO', 0, 6);
  end;
  FNavigator.RemoveObstacle(1);
  Emit('RO1');
  Changes('OR');
  Routes('RR', 1, 6);
  FNavigator.RemoveObstacle(7);
  Emit('RO7');
  FNavigator.RemoveObstacle(-1);
  Emit('ROm');
  FNavigator.RemoveAllObstacles;
  Emit('ROA');
  Changes('OZ');
  Routes('RZ', 0, 6);
  DumpCache;
end;

procedure TD3ScenarioRunner.RunCase(const AName: string; const ACrc: Cardinal);
var
  LNavigatorIntf: IAasMapNavigator;
  LLog: IIdLibLog;
  LTime: Integer;
  LReach: TAasReachability;
begin
  Emit('CASE ' + AName);
  LLog := TScenarioLog.Create(FOutput);
  LNavigatorIntf := TAasNavigationFactory.CreateNavigatorForFile(D3LoadFile(AName, ACrc), True, LLog, FMaxCacheMemory);
  FNavigator := TAasNavigator(LNavigatorIntf as TObject);
  Emit('INIT 1');
  DumpAreas;
  Routes('RT', 0, 1);
  Routes('RT', 1, 2);
  Routes('RT', 2, 2);
  Emit(Format('RT0 %d', [BoolInt(FNavigator.RouteToGoalArea(0, TGeoVec3.Make(0, 0, 0), 1, TRAVEL[0], LTime, LReach))]));
  Emit(Format('RTN %d', [BoolInt(FNavigator.RouteToGoalArea(1, TGeoVec3.Make(0, 0, 0), FNavigator.AasFile.NumAreas,
    TRAVEL[0], LTime, LReach))]));
  Emit(Format('TT %d %d', [FNavigator.TravelTimeToGoalArea(1, FNavigator.AreaCenter(1), 2, TRAVEL[0]),
    FNavigator.TravelTimeToGoalArea(2, FNavigator.AreaCenter(2), 2, TRAVEL[0])]));
  DumpCache;
  Paths;
  Goals;
  Walls;
  Obstacles;
  DumpCache;
  Emit(Format('INIT2 %d', [BoolInt(LNavigatorIntf.Init(AnsiString(AName), ACrc))]));
  DumpCache;
  FNavigator := nil;
end;

procedure TD3ScenarioRunner.Run(const ACases: TStrings);
var
  LIndex, LSpace: Integer;
  LLine: string;
begin
  for LIndex := 0 to ACases.Count - 1 do
  begin
    LLine := Trim(ACases[LIndex]);
    if (LLine = '') or (LLine[1] = '#') then
      Continue;
    LSpace := Pos(' ', LLine);
    RunCase(Copy(LLine, 1, LSpace - 1), StrToUInt(Trim(Copy(LLine, LSpace + 1, MaxInt))));
  end;
end;

end.
