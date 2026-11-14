{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the calculation of all the reachabilities of a    }
{  file                                                                        }
{                                                                              }
{  Port of AAS_InitReachability, AAS_ContinueInitReachability,                 }
{  AAS_StoreReachability and of the global state that goes with them           }
{  (be_aas_reach.c). Based on the Quake III Arena GPL Source Code (id          }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Calculator;

{$Q-}
{$R+}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Move.Intf,
  DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Links, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Intf,
  DelphiDoom.Aas.Reach.Context, DelphiDoom.Aas.Reach.JumpPadInfo, DelphiDoom.Aas.Reach.BestReachable,
  DelphiDoom.Aas.Reach.WeaponFlags, DelphiDoom.Aas.Reach.Swim, DelphiDoom.Aas.Reach.EqualFloor,
  DelphiDoom.Aas.Reach.Step, DelphiDoom.Aas.Reach.Ladder, DelphiDoom.Aas.Reach.Jump, DelphiDoom.Aas.Reach.Grapple,
  DelphiDoom.Aas.Reach.WeaponJump, DelphiDoom.Aas.Reach.WalkOffLedge, DelphiDoom.Aas.Reach.JumpPad,
  DelphiDoom.Aas.Reach.Teleport, DelphiDoom.Aas.Reach.Elevator, DelphiDoom.Aas.Reach.FuncBobbing;

type
  /// <summary>
  ///   Calculates the reachabilities in steps: <c>InitReachability</c> and then <c>ContinueInitReachability</c> until it
  ///   gives False. It owns the context and the calculators of the kinds of reachability and also answers the
  ///   <c>IAasBestReachable</c> questions. The file must be a <c>TAasFile</c> (it implements
  ///   <c>IAasReachabilityEditor</c>); the other objects and the links are not owned
  /// </summary>
  TAasReachCalculator = class(TInterfacedObject, IAasReachInitializer, IAasBestReachable)
  strict private
    FFile: IAasFile;
    FEditor: IAasReachabilityEditor;
    FImport: IBotImport;
    FLibVars: IBotLibVars;
    FClock: TAasMilliseconds;
    FContext: TAasReachContext;
    FJumpPadInfo: TAasReachJumpPadInfo;
    FBest: TAasReachBest;
    FWeaponFlags: TAasReachWeaponFlags;
    FSwim: TAasReachSwim;
    FEqualFloor: TAasReachEqualFloor;
    FStep: TAasReachStep;
    FLadder: TAasReachLadder;
    FJump: TAasReachJump;
    FGrapple: TAasReachGrapple;
    FWeaponJump: TAasReachWeaponJump;
    FWalkOffLedge: TAasReachWalkOffLedge;
    FJumpPad: TAasReachJumpPad;
    FTeleport: TAasReachTeleport;
    FElevator: TAasReachElevator;
    FFuncBobbing: TAasReachFuncBobbing;
    FNumReachabilityAreas: Integer;
    FFrameReachability: Single;
    FReachabilityDelay: Single;
    FLastPercentage: Integer;
    procedure Say(const AText: string);
    procedure StoreReachability;
    procedure CalculateAreaPairs(const AArea: Integer);
    procedure CalculateWeaponAndGrapple(const AArea: Integer);
    function Run: Boolean;
    function GetNumReachabilityAreas: Integer;
    function GetCounters: TAasReachCounters;
  public
    /// <summary>
    ///   The variables give grapplereach and forcereachability (and may be nil: both are 0); the clock is Sys_MilliSeconds
    ///   (nil: it is always 0, so a call never stops for the time)
    /// </summary>
    constructor Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer;
      const AFaces: IAasFaceTester; const AMovement: IAasMovement; const AWorld: IAasBspWorld;
      const AModels: IAasBspModels; const AEntities: IAasBspEntities; const ALinks: TAasEntityLinks;
      const AImport: IBotImport; const ALibVars: IBotLibVars; const AGeometry: IAasReachGeometry;
      const APhysics: IAasReachPhysics; const AClock: TAasMilliseconds = nil);
    destructor Destroy; override;
    procedure InitReachability;
    function ContinueInitReachability(const ATime: Single): Boolean;
    function BestReachableArea(const AOrigin, AMins, AMaxs: TVec3; var AGoalOrigin: TVec3): Integer;
    function BestReachableLinkArea(const ALinkHead: Integer): Integer;
    function BestReachableFromJumpPadArea(const AOrigin, AMins, AMaxs: TVec3): Integer;
    property NumReachabilityAreas: Integer read GetNumReachabilityAreas;
    property Counters: TAasReachCounters read GetCounters;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Printer, DelphiDoom.Aas.Reach.Heap,
  DelphiDoom.Aas.Reach.Format, DelphiDoom.Aas.Reach.FloatMode;

resourcestring
  SNotInitialized = 'AAS reachability: InitReachability was not called';
  SNoEditor = 'AAS reachability: the file cannot take a table of reachabilities (it is not a TAasFile)';

{ TAasReachCalculator }

constructor TAasReachCalculator.Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer;
  const AFaces: IAasFaceTester; const AMovement: IAasMovement; const AWorld: IAasBspWorld;
  const AModels: IAasBspModels; const AEntities: IAasBspEntities; const ALinks: TAasEntityLinks;
  const AImport: IBotImport; const ALibVars: IBotLibVars; const AGeometry: IAasReachGeometry;
  const APhysics: IAasReachPhysics; const AClock: TAasMilliseconds);
begin
  inherited Create;
  FFile := AFile;
  if not Supports(AFile, IAasReachabilityEditor, FEditor) then
    raise EAasReachException.Create(SNoEditor);
  FImport := AImport;
  FLibVars := ALibVars;
  FClock := AClock;
  FContext := TAasReachContext.Create(AFile, ASampler, ATracer, AFaces, AMovement, AWorld, AModels, AEntities, ALinks,
    AImport, AGeometry, APhysics);
  FJumpPadInfo := TAasReachJumpPadInfo.Create(FContext);
  FBest := TAasReachBest.Create(FContext, FJumpPadInfo);
  FWeaponFlags := TAasReachWeaponFlags.Create(FContext, FBest);
  FSwim := TAasReachSwim.Create(FContext);
  FEqualFloor := TAasReachEqualFloor.Create(FContext);
  FStep := TAasReachStep.Create(FContext);
  FLadder := TAasReachLadder.Create(FContext);
  FJump := TAasReachJump.Create(FContext);
  FGrapple := TAasReachGrapple.Create(FContext);
  FWeaponJump := TAasReachWeaponJump.Create(FContext);
  FWalkOffLedge := TAasReachWalkOffLedge.Create(FContext);
  FJumpPad := TAasReachJumpPad.Create(FContext, FJumpPadInfo);
  FTeleport := TAasReachTeleport.Create(FContext);
  FElevator := TAasReachElevator.Create(FContext);
  FFuncBobbing := TAasReachFuncBobbing.Create(FContext);
end;

destructor TAasReachCalculator.Destroy;
begin
  FFuncBobbing.Free;
  FElevator.Free;
  FTeleport.Free;
  FJumpPad.Free;
  FWalkOffLedge.Free;
  FWeaponJump.Free;
  FGrapple.Free;
  FJump.Free;
  FLadder.Free;
  FStep.Free;
  FEqualFloor.Free;
  FSwim.Free;
  FWeaponFlags.Free;
  FBest.Free;
  FJumpPadInfo.Free;
  if Assigned(FContext) then
  begin
    FContext.Heap.Free;
    FContext.Free;
  end;
  inherited Destroy;
end;

function TAasReachCalculator.GetNumReachabilityAreas: Integer;
begin
  Result := FNumReachabilityAreas;
end;

function TAasReachCalculator.GetCounters: TAasReachCounters;
begin
  Result := FContext.Counters^;
end;

procedure TAasReachCalculator.Say(const AText: string);
begin
  TAasPrinter.Print(FImport, PRT_MESSAGE, AText);
end;

procedure TAasReachCalculator.InitReachability;
var
  LMode: IInterface;
begin
  if Length(FFile.Reachability) > 0 then
  begin
    if (FLibVars = nil) or (Trunc(FLibVars.GetValue('forcereachability')) = 0) then
    begin
      FNumReachabilityAreas := FContext.NumAreas + 2;
      Exit;
    end;
  end;
  LMode := TAasReachFloatMode.Enter;
  if FLibVars <> nil then
    FContext.CalculateGrapple := FLibVars.GetValue('grapplereach') <> 0
  else
    FContext.CalculateGrapple := False;
  // start with area 1 because area zero is a dummy
  FNumReachabilityAreas := 1;
  // the heap with the links and the lists of the areas
  FContext.Heap.Free;
  FContext.Heap := TAasReachHeap.Create(FImport, FContext.NumAreas);
  FWeaponFlags.Calculate;
end;

// the reachabilities from the area to the other areas: the swim, walk, step, ladder and jump ones
procedure TAasReachCalculator.CalculateAreaPairs(const AArea: Integer);
var
  LJ: Integer;
  LSettings: TArray<TAasAreaSettings>;
begin
  LSettings := FContext.AreaSettings;
  for LJ := 1 to FContext.NumAreas - 1 do
  begin
    if AArea = LJ then
      Continue;
    // never create reachabilities from teleporter or jump pad areas to regular areas
    if (LSettings[AArea].Contents and (AREACONTENTS_TELEPORTER or AREACONTENTS_JUMPPAD)) <> 0 then
      if (LSettings[LJ].Contents and (AREACONTENTS_TELEPORTER or AREACONTENTS_JUMPPAD)) = 0 then
        Continue;
    // if there already is a reachability link from area i to j
    if FContext.ReachabilityExists(AArea, LJ) then
      Continue;
    if FSwim.Calculate(AArea, LJ) then
      Continue;
    if FEqualFloor.Calculate(AArea, LJ) then
      Continue;
    if FStep.Calculate(AArea, LJ) then
      Continue;
    if FLadder.Calculate(AArea, LJ) then
      Continue;
    if FJump.Calculate(AArea, LJ) then
      Continue;
  end;
end;

procedure TAasReachCalculator.CalculateWeaponAndGrapple(const AArea: Integer);
var
  LJ: Integer;
begin
  for LJ := 1 to FContext.NumAreas - 1 do
  begin
    if AArea = LJ then
      Continue;
    if FContext.ReachabilityExists(AArea, LJ) then
      Continue;
    if FContext.CalculateGrapple then
      FGrapple.Calculate(AArea, LJ);
    FWeaponJump.Calculate(AArea, LJ);
  end;
end;

procedure TAasReachCalculator.StoreReachability;
var
  LIndex, LCount, LSize: Integer;
  LTable: TArray<TAasReachability>;
  LLink: PAasLinkedReach;
  LSettings: TArray<TAasAreaSettings>;
begin
  LSettings := FContext.AreaSettings;
  SetLength(LTable, FContext.Heap.Count + 10);
  LSize := 1;
  for LIndex := 0 to FContext.NumAreas - 1 do
  begin
    LSettings[LIndex].FirstReachableArea := LSize;
    LSettings[LIndex].NumReachableAreas := 0;
    LLink := FContext.Heap.Head(LIndex);
    LCount := 0;
    while LLink <> nil do
    begin
      LTable[LSize + LCount].AreaNum := LLink^.AreaNum;
      LTable[LSize + LCount].FaceNum := LLink^.FaceNum;
      LTable[LSize + LCount].EdgeNum := LLink^.EdgeNum;
      LTable[LSize + LCount].StartPoint := LLink^.Start;
      LTable[LSize + LCount].EndPoint := LLink^.EndPoint;
      LTable[LSize + LCount].TravelType := LLink^.TravelType;
      LTable[LSize + LCount].TravelTime := LLink^.TravelTime;
      Inc(LCount);
      LLink := LLink^.Next;
    end;
    LSettings[LIndex].NumReachableAreas := LCount;
    Inc(LSize, LCount);
  end;
  // the table of the file has the links that are used (the original allocates 10 more)
  SetLength(LTable, LSize);
  FEditor.ReplaceReachability(LTable);
end;

function TAasReachCalculator.Run: Boolean;
var
  LI, LTodo, LStartTime, LNumAreas: Integer;
  LSettings: TArray<TAasAreaSettings>;
begin
  Result := False;
  LNumAreas := FContext.NumAreas;
  // if the reachability is calculated for all areas
  if FNumReachabilityAreas >= LNumAreas + 2 then
    Exit;
  if FContext.Heap = nil then
    raise EAasReachException.Create(SNotInitialized);
  // if starting with area 1 (area 0 is a dummy)
  if FNumReachabilityAreas = 1 then
  begin
    Say('calculating reachability...'#10);
    FLastPercentage := 0;
    FFrameReachability := AAS_REACH_AREAS_PER_CALL;
    FReachabilityDelay := AAS_REACH_DELAY_MILLISECONDS;
  end;
  LSettings := FContext.AreaSettings;
  // the number of areas to calculate the reachability for in this call
  LTodo := FNumReachabilityAreas + Trunc(FFrameReachability);
  if Assigned(FClock) then
    LStartTime := FClock()
  else
    LStartTime := 0;
  LI := FNumReachabilityAreas;
  while (LI < LNumAreas) and (LI < LTodo) do
  begin
    Inc(FNumReachabilityAreas);
    // only create jump pad reachabilities from jump pad areas
    if (LSettings[LI].Contents and AREACONTENTS_JUMPPAD) <> 0 then
    begin
      Inc(LI);
      Continue;
    end;
    CalculateAreaPairs(LI);
    // never create these reachabilities from teleporter or jump pad areas
    if (LSettings[LI].Contents and (AREACONTENTS_TELEPORTER or AREACONTENTS_JUMPPAD)) <> 0 then
    begin
      Inc(LI);
      Continue;
    end;
    CalculateWeaponAndGrapple(LI);
    // if the calculation took more time than the maximum reachability delay
    if Assigned(FClock) and (FClock() - LStartTime > Trunc(FReachabilityDelay)) then
      Break;
    if FNumReachabilityAreas * 1000 div LNumAreas > FLastPercentage then
      Break;
    Inc(LI);
  end;
  if FNumReachabilityAreas = LNumAreas then
  begin
    Say(#13 + TAasReachFormat.Fixed(Single(100.0), 1, 6) + '%');
    Say(#10'please wait while storing reachability...'#10);
    Inc(FNumReachabilityAreas);
  end
  else if FNumReachabilityAreas = LNumAreas + 1 then
  begin
    // additional walk off ledge reachabilities for every area
    for LI := 1 to LNumAreas - 1 do
    begin
      // only create jump pad reachabilities from jump pad areas
      if (LSettings[LI].Contents and AREACONTENTS_JUMPPAD) <> 0 then
        Continue;
      FWalkOffLedge.Calculate(LI);
    end;
    FJumpPad.Calculate;
    FTeleport.Calculate;
    FElevator.Calculate;
    FFuncBobbing.Calculate;
    // store all the reachabilities and free the link heap
    StoreReachability;
    FContext.Heap.Free;
    FContext.Heap := nil;
    Inc(FNumReachabilityAreas);
    Say('calculating clusters...'#10);
  end
  else
  begin
    FLastPercentage := FNumReachabilityAreas * 1000 div LNumAreas;
    Say(#13 + TAasReachFormat.Fixed(Single(FLastPercentage) / 10, 1, 6) + '%');
  end;
  // not yet finished
  Result := True;
end;

function TAasReachCalculator.ContinueInitReachability(const ATime: Single): Boolean;
var
  LMode: IInterface;
begin
  LMode := TAasReachFloatMode.Enter;
  try
    Result := Run;
  except
    on E: ERangeError do
      raise EAasReachException.Create('AAS reachability: a table of the file was read outside its size (' + E.Message + ')');
  end;
end;

function TAasReachCalculator.BestReachableArea(const AOrigin, AMins, AMaxs: TVec3; var AGoalOrigin: TVec3): Integer;
var
  LMode: IInterface;
begin
  LMode := TAasReachFloatMode.Enter;
  Result := FBest.BestReachableArea(AOrigin, AMins, AMaxs, AGoalOrigin);
end;

function TAasReachCalculator.BestReachableLinkArea(const ALinkHead: Integer): Integer;
begin
  Result := FBest.BestReachableLinkArea(ALinkHead);
end;

function TAasReachCalculator.BestReachableFromJumpPadArea(const AOrigin, AMins, AMaxs: TVec3): Integer;
var
  LMode: IInterface;
begin
  LMode := TAasReachFloatMode.Enter;
  Result := FBest.BestReachableFromJumpPadArea(AOrigin, AMins, AMaxs);
end;

end.
