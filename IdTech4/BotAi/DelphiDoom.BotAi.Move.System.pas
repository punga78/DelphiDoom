{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMoveSystem, the movement AI of the bots            }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the states and the  }
{  functions of code\botlib\be_ai_move.c (BotMoveToGoal, BotMoveInGoalArea,    }
{  BotInitMoveState ...). Based on the Quake III Arena GPL Source Code (id     }
{  Software). Copyright (C) 1999-2005 Id Software, Inc.                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.System;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types,
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.Goal.Types,
  DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Context,
  DelphiDoom.BotAi.Move.Basics, DelphiDoom.BotAi.Move.Movers, DelphiDoom.BotAi.Move.ReachChooser,
  DelphiDoom.BotAi.Move.Predictor, DelphiDoom.BotAi.Move.Travel.Intf, DelphiDoom.BotAi.Move.Intf;

type
  /// <summary>
  ///   The globals of be_ai_move.c (<c>botmovestates[MAX_CLIENTS + 1]</c>) are fields. The travel types are given to
  ///   it as a table (the travel type without the flag bits to the class that moves along it), the grapple reset and
  ///   the locator of the areas as interfaces. Differences from the original (defects): see
  ///   <c>ResetLastAvoidReach</c> and the class of the brush model types.
  /// </summary>
  TBotMoveSystem = class(TInterfacedObject, IBotMoveSystem)
  strict private
    FImport: IBotImport;
    FContext: TBotMoveContext;
    FBasics: TBotMoveBasics;
    FMovers: TBotMovers;
    FChooser: TBotReachabilityChooser;
    FPredictor: TBotMovePredictor;
    FLocator: IBotReachabilityLocator;
    FGrapple: IBotGrappleReset;
    FTravelTypes: TDictionary<Integer, IBotTravelType>;
    FStates: array[1..BOT_MAX_CLIENTS] of TBotMoveState;
    function StateFromHandle(const AHandle: Integer): TBotMoveState;
    function ReachabilityTime(const AReach: TAasReachability): Integer;
    function MoveInGoalArea(const AState: TBotMoveState; const AGoal: TBotGoal): TBotMoveResult;
    function StandingOnEntity(const AState: TBotMoveState; var AResult: TBotMoveResult): Boolean;
    procedure FindJumpPadReachability(const AState: TBotMoveState; const AGoal: TBotGoal;
      const ATravelFlags: Integer);
    function TravelOnGround(const AState: TBotMoveState; const AGoal: TBotGoal; const ATravelFlags: Integer;
      var AResult: TBotMoveResult): Boolean;
    procedure TravelInAir(const AState: TBotMoveState; const AGoal: TBotGoal; const ATravelFlags: Integer;
      var AResult: TBotMoveResult);
  public
    constructor Create(const AContext: TBotMoveContext; const ABasics: TBotMoveBasics; const AMovers: TBotMovers;
      const AChooser: TBotReachabilityChooser; const APredictor: TBotMovePredictor;
      const ALocator: IBotReachabilityLocator; const AGrapple: IBotGrappleReset;
      const ATravelTypes: TDictionary<Integer, IBotTravelType>);
    destructor Destroy; override;
    function Setup: Integer;
    procedure Shutdown;
    procedure SetBrushModelTypes;
    function AllocMoveState: Integer;
    procedure FreeMoveState(const AHandle: Integer);
    procedure InitMoveState(const AHandle: Integer; const AInit: TBotInitMove);
    procedure ResetMoveState(const AHandle: Integer);
    procedure ResetAvoidReach(const AHandle: Integer);
    procedure ResetLastAvoidReach(const AHandle: Integer);
    procedure AddAvoidSpot(const AHandle: Integer; const AOrigin: TVec3; const ARadius: Single; const AType: Integer);
    function MoveToGoal(const AHandle: Integer; const AGoal: PBotGoal; const ATravelFlags: Integer): TBotMoveResult;
    function MoveInDirection(const AHandle: Integer; const ADir: TVec3; const ASpeed: Single;
      const AType: Integer): Boolean;
    function MovementViewTarget(const AHandle: Integer; const AGoal: PBotGoal; const ATravelFlags: Integer;
      const ALookAhead: Single; out ATarget: TVec3): Boolean;
    function PredictVisiblePosition(const AOrigin: TVec3; const AAreaNum: Integer; const AGoal: PBotGoal;
      const ATravelFlags: Integer; out ATarget: TVec3): Boolean;
    function ReachabilityArea(const AOrigin: TVec3; const AClient: Integer): Integer;
    function Locator: IBotReachabilityLocator;
  end;

implementation

uses
  DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Text.CFormat,
  DelphiDoom.BotAi.Move.VectorMath;

const
  /// <summary>AVOIDREACH_TIME: links are avoided for 6 seconds after use</summary>
  AVOIDREACH_TIME = 6;

{ TBotMoveSystem }

constructor TBotMoveSystem.Create(const AContext: TBotMoveContext; const ABasics: TBotMoveBasics;
  const AMovers: TBotMovers; const AChooser: TBotReachabilityChooser; const APredictor: TBotMovePredictor;
  const ALocator: IBotReachabilityLocator; const AGrapple: IBotGrappleReset;
  const ATravelTypes: TDictionary<Integer, IBotTravelType>);
begin
  inherited Create;
  FContext := AContext;
  FImport := AContext.Import;
  FBasics := ABasics;
  FMovers := AMovers;
  FChooser := AChooser;
  FPredictor := APredictor;
  FLocator := ALocator;
  FGrapple := AGrapple;
  FTravelTypes := ATravelTypes;
end;

destructor TBotMoveSystem.Destroy;
var
  LHandle: Integer;
begin
  for LHandle := Low(FStates) to High(FStates) do
    FreeAndNil(FStates[LHandle]);
  FTravelTypes.Free;
  FPredictor.Free;
  FChooser.Free;
  FMovers.Free;
  FBasics.Free;
  FContext.Free;
  inherited Destroy;
end;

function TBotMoveSystem.Locator: IBotReachabilityLocator;
begin
  Result := FLocator;
end;

function TBotMoveSystem.StateFromHandle(const AHandle: Integer): TBotMoveState;
begin
  if (AHandle <= 0) or (AHandle > BOT_MAX_CLIENTS) then
  begin
    FImport.Print(PRT_FATAL, 'move state handle ' + TBotCFormat.Int(AHandle) + ' out of range'#10);
    Exit(nil);
  end;
  if not Assigned(FStates[AHandle]) then
  begin
    FImport.Print(PRT_FATAL, 'invalid move state ' + TBotCFormat.Int(AHandle) + #10);
    Exit(nil);
  end;
  Result := FStates[AHandle];
end;

function TBotMoveSystem.Setup: Integer;
begin
  SetBrushModelTypes;
  FContext.Vars.Setup;
  Result := BLERR_NOERROR;
end;

procedure TBotMoveSystem.Shutdown;
var
  LHandle: Integer;
begin
  for LHandle := Low(FStates) to High(FStates) do
    FreeAndNil(FStates[LHandle]);
end;

procedure TBotMoveSystem.SetBrushModelTypes;
begin
  FContext.ModelTypes.Find(FContext.World);
end;

function TBotMoveSystem.AllocMoveState: Integer;
var
  LHandle: Integer;
begin
  for LHandle := Low(FStates) to High(FStates) do
  begin
    if not Assigned(FStates[LHandle]) then
    begin
      FStates[LHandle] := TBotMoveState.Create;
      Exit(LHandle);
    end;
  end;
  Result := 0;
end;

procedure TBotMoveSystem.FreeMoveState(const AHandle: Integer);
begin
  if (AHandle <= 0) or (AHandle > BOT_MAX_CLIENTS) then
  begin
    FImport.Print(PRT_FATAL, 'move state handle ' + TBotCFormat.Int(AHandle) + ' out of range'#10);
    Exit;
  end;
  if not Assigned(FStates[AHandle]) then
  begin
    FImport.Print(PRT_FATAL, 'invalid move state ' + TBotCFormat.Int(AHandle) + #10);
    Exit;
  end;
  FreeAndNil(FStates[AHandle]);
end;

procedure TBotMoveSystem.InitMoveState(const AHandle: Integer; const AInit: TBotInitMove);
var
  LState: TBotMoveState;
  LFlags: Integer;
  LFlag: Integer;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  LState.Origin := AInit.Origin;
  LState.Velocity := AInit.Velocity;
  LState.ViewOffset := AInit.ViewOffset;
  LState.EntityNum := AInit.EntityNum;
  LState.Client := AInit.Client;
  LState.ThinkTime := AInit.ThinkTime;
  LState.PresenceType := AInit.PresenceType;
  LState.ViewAngles := AInit.ViewAngles;
  // the flags of the player state replace these five
  LFlags := LState.MoveFlags;
  for LFlag in [MFL_ONGROUND, MFL_TELEPORTED, MFL_WATERJUMP, MFL_WALK, MFL_GRAPPLEPULL] do
  begin
    LFlags := LFlags and not LFlag;
    if (AInit.OrMoveFlags and LFlag) <> 0 then
      LFlags := LFlags or LFlag;
  end;
  LState.MoveFlags := LFlags;
end;

procedure TBotMoveSystem.ResetMoveState(const AHandle: Integer);
var
  LState: TBotMoveState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  LState.Reset;
end;

procedure TBotMoveSystem.ResetAvoidReach(const AHandle: Integer);
var
  LState: TBotMoveState;
  LIndex: Integer;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  for LIndex := 0 to MAX_AVOIDREACH - 1 do
  begin
    LState.AvoidReach[LIndex] := 0;
    LState.AvoidReachTimes[LIndex] := 0;
    LState.AvoidReachTries[LIndex] := 0;
  end;
end;

procedure TBotMoveSystem.ResetLastAvoidReach(const AHandle: Integer);
var
  LState: TBotMoveState;
  LIndex: Integer;
  LLatest: Integer;
  LLatestTime: Single;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  LLatestTime := 0;
  LLatest := 0;
  for LIndex := 0 to MAX_AVOIDREACH - 1 do
  begin
    if LState.AvoidReachTimes[LIndex] > LLatestTime then
    begin
      LLatestTime := LState.AvoidReachTimes[LIndex];
      LLatest := LIndex;
    end;
  end;
  if LLatestTime <> 0 then
  begin
    LState.AvoidReachTimes[LLatest] := 0;
    // the original tests avoidreachtries[MAX_AVOIDREACH], one entry after the array: here the entry that is cleared
    if LState.AvoidReachTries[LLatest] > 0 then
      Dec(LState.AvoidReachTries[LLatest]);
  end;
end;

procedure TBotMoveSystem.AddAvoidSpot(const AHandle: Integer; const AOrigin: TVec3; const ARadius: Single;
  const AType: Integer);
var
  LState: TBotMoveState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  if AType = AVOID_CLEAR then
  begin
    LState.NumAvoidSpots := 0;
    Exit;
  end;
  if LState.NumAvoidSpots >= MAX_AVOIDSPOTS then
    Exit;
  LState.AvoidSpots[LState.NumAvoidSpots].Origin := AOrigin;
  LState.AvoidSpots[LState.NumAvoidSpots].Radius := ARadius;
  LState.AvoidSpots[LState.NumAvoidSpots].SpotType := AType;
  Inc(LState.NumAvoidSpots);
end;

function TBotMoveSystem.ReachabilityTime(const AReach: TAasReachability): Integer;
begin
  // time before the reachability times out
  case AReach.TravelType and TRAVELTYPE_MASK of
    TRAVEL_WALK, TRAVEL_CROUCH, TRAVEL_BARRIERJUMP, TRAVEL_WALKOFFLEDGE, TRAVEL_JUMP, TRAVEL_SWIM, TRAVEL_WATERJUMP,
      TRAVEL_TELEPORT:
      Result := 5;
    TRAVEL_LADDER, TRAVEL_ROCKETJUMP, TRAVEL_BFGJUMP:
      Result := 6;
    TRAVEL_ELEVATOR, TRAVEL_JUMPPAD, TRAVEL_FUNCBOB:
      Result := 10;
    TRAVEL_GRAPPLEHOOK:
      Result := 8;
  else
    begin
      FImport.Print(PRT_ERROR, 'travel type ' + TBotCFormat.Int(AReach.TravelType) + ' not implemented yet'#10);
      Result := 8;
    end;
  end;
end;

function TBotMoveSystem.MoveInGoalArea(const AState: TBotMoveState; const AGoal: TBotGoal): TBotMoveResult;
var
  LDir: TVec3;
  LDist: Single;
  LSpeed: Single;
  LProduct: Single;
  LInner: Single;
begin
  Result := Default(TBotMoveResult);
  // walk straight to the goal origin
  LDir[0] := AGoal.Origin[0] - AState.Origin[0];
  LDir[1] := AGoal.Origin[1] - AState.Origin[1];
  if (AState.MoveFlags and MFL_SWIMMING) <> 0 then
  begin
    LDir[2] := AGoal.Origin[2] - AState.Origin[2];
    Result.TravelType := TRAVEL_SWIM;
  end
  else
  begin
    LDir[2] := 0;
    Result.TravelType := TRAVEL_WALK;
  end;
  LDist := TAasVectorMath.Normalize(LDir);
  if LDist > 100 then
    LDist := 100;
  LProduct := 4 * LDist;
  LInner := 400 - LProduct;
  LSpeed := 400 - LInner;
  if LSpeed < 10 then
    LSpeed := 0;
  FBasics.CheckBlocked(AState, LDir, True, Result);
  // elemantary action move in direction
  FContext.Actions.Move(AState.Client, LDir, LSpeed);
  Result.MoveDir := LDir;
  if (AState.MoveFlags and MFL_SWIMMING) <> 0 then
  begin
    TBotVectorMath.ToAngles(LDir, Result.IdealViewAngles);
    Result.Flags := Result.Flags or MOVERESULT_SWIMVIEW;
  end;
  AState.LastReachNum := 0;
  AState.LastAreaNum := 0;
  AState.LastGoalAreaNum := AGoal.AreaNum;
  AState.LastOrigin := AState.Origin;
end;

function TBotMoveSystem.MoveInDirection(const AHandle: Integer; const ADir: TVec3; const ASpeed: Single;
  const AType: Integer): Boolean;
var
  LState: TBotMoveState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit(False);
  Result := FBasics.MoveInDirection(LState, ADir, ASpeed, AType);
end;

function TBotMoveSystem.MovementViewTarget(const AHandle: Integer; const AGoal: PBotGoal;
  const ATravelFlags: Integer; const ALookAhead: Single; out ATarget: TVec3): Boolean;
var
  LState: TBotMoveState;
begin
  ATarget := Default(TVec3);
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit(False);
  Result := FPredictor.MovementViewTarget(LState, AGoal, ATravelFlags, ALookAhead, ATarget);
end;

function TBotMoveSystem.PredictVisiblePosition(const AOrigin: TVec3; const AAreaNum: Integer; const AGoal: PBotGoal;
  const ATravelFlags: Integer; out ATarget: TVec3): Boolean;
begin
  Result := FPredictor.PredictVisiblePosition(AOrigin, AAreaNum, AGoal, ATravelFlags, ATarget);
end;

function TBotMoveSystem.ReachabilityArea(const AOrigin: TVec3; const AClient: Integer): Integer;
begin
  Result := FLocator.ReachabilityArea(AOrigin, AClient);
end;


function TBotMoveSystem.StandingOnEntity(const AState: TBotMoveState; var AResult: TBotMoveResult): Boolean;
var
  LEntity: Integer;
  LModelNum: Integer;
  LModelType: Integer;
  LReachNum: Integer;
  LReach: TAasReachability;
  LKind: Integer;
  LOwnType: Integer;
  LName: AnsiString;
  LFlag: Integer;
begin
  // True when BotMoveToGoal returns at once
  LEntity := FMovers.OnTopOfEntity(AState);
  if LEntity = -1 then
    Exit(False);
  LModelNum := FContext.World.Entities.EntityModelIndex(LEntity);
  if (LModelNum < 0) or (LModelNum >= BOT_MAX_MODELS) then
    Exit(False);
  LModelType := FContext.ModelTypes.ModelType(LModelNum);
  if (LModelType = MODELTYPE_FUNC_PLAT) or (LModelType = MODELTYPE_FUNC_BOB) then
  begin
    if LModelType = MODELTYPE_FUNC_PLAT then
    begin
      LOwnType := TRAVEL_ELEVATOR;
      LName := 'func_plat';
      LFlag := MOVERESULT_ONTOPOF_ELEVATOR;
    end
    else
    begin
      LOwnType := TRAVEL_FUNCBOB;
      LName := 'func_bobbing';
      LFlag := MOVERESULT_ONTOPOF_FUNCBOB;
    end;
    FContext.World.Router.ReachabilityFromNum(AState.LastReachNum, LReach);
    LKind := LReach.TravelType and TRAVELTYPE_MASK;
    // if the bot is Not using the elevator (the func bobbing); NOTE: the face number is the model number
    if (LKind <> LOwnType) or ((LReach.FaceNum and $0000FFFF) <> LModelNum) then
    begin
      LReachNum := FContext.World.Router.NextModelReachability(0, LModelNum);
      if LReachNum <> 0 then
      begin
        FContext.World.Router.ReachabilityFromNum(LReachNum, LReach);
        AState.LastReachNum := LReachNum;
        AState.ReachabilityTime := FContext.World.Time + ReachabilityTime(LReach);
      end
      else
      begin
        if FContext.Developer then
          FImport.Print(PRT_MESSAGE, 'client ' + TBotCFormat.Int(AState.Client) + ': on ' + LName +
            ' without reachability'#10);
        AResult.Blocked := True;
        AResult.BlockEntity := LEntity;
        AResult.Flags := AResult.Flags or MOVERESULT_ONTOPOFOBSTACLE;
        Exit(True);
      end;
    end;
    AResult.Flags := AResult.Flags or LFlag;
  end
  else if (LModelType = MODELTYPE_FUNC_STATIC) or (LModelType = MODELTYPE_FUNC_DOOR) then
  begin
    // check if ontop of a door bridge ?
    AState.AreaNum := FLocator.FuzzyPointReachabilityArea(AState.Origin);
    // if not in a reachability area
    if FContext.World.Areas.AreaReachability(AState.AreaNum) = 0 then
    begin
      AResult.Blocked := True;
      AResult.BlockEntity := LEntity;
      AResult.Flags := AResult.Flags or MOVERESULT_ONTOPOFOBSTACLE;
      Exit(True);
    end;
  end
  else
  begin
    AResult.Blocked := True;
    AResult.BlockEntity := LEntity;
    AResult.Flags := AResult.Flags or MOVERESULT_ONTOPOFOBSTACLE;
    Exit(True);
  end;
  Result := False;
end;

function TBotMoveSystem.TravelOnGround(const AState: TBotMoveState; const AGoal: TBotGoal;
  const ATravelFlags: Integer; var AResult: TBotMoveResult): Boolean;
var
  LLastReach: TAasReachability;
  LReach: TAasReachability;
  LReachNum: Integer;
  LKind: Integer;
  LResultFlags: Integer;
  LTravel: IBotTravelType;
begin
  // True when BotMoveToGoal returns at once
  FContext.World.Router.ReachabilityFromNum(AState.LastReachNum, LLastReach);
  // reachability area the bot is in
  AState.AreaNum := FLocator.FuzzyPointReachabilityArea(AState.Origin);
  if AState.AreaNum = 0 then
  begin
    AResult.Failure := True;
    AResult.Blocked := True;
    AResult.BlockEntity := 0;
    AResult.ResultType := RESULTTYPE_INSOLIDAREA;
    Exit(True);
  end;
  // if the bot is in the goal area
  if AState.AreaNum = AGoal.AreaNum then
  begin
    AResult := MoveInGoalArea(AState, AGoal);
    Exit(True);
  end;
  // assume we can use the reachability from the last frame
  LReachNum := AState.LastReachNum;
  // if there is a last reachability
  if LReachNum <> 0 then
  begin
    FContext.World.Router.ReachabilityFromNum(LReachNum, LReach);
    LKind := LReach.TravelType and TRAVELTYPE_MASK;
    // check if the reachability is still valid
    if (FContext.World.Router.TravelFlagForType(LReach.TravelType) and ATravelFlags) = 0 then
      LReachNum := 0
    // special grapple hook case
    else if LKind = TRAVEL_GRAPPLEHOOK then
    begin
      if (AState.ReachabilityTime < FContext.World.Time) or ((AState.MoveFlags and MFL_GRAPPLERESET) <> 0) then
        LReachNum := 0;
    end
    // special elevator case
    else if (LKind = TRAVEL_ELEVATOR) or (LKind = TRAVEL_FUNCBOB) then
    begin
      // the original tests MOVERESULT_ONTOPOF_FUNCBOB twice
      if ((AResult.Flags and MOVERESULT_ONTOPOF_FUNCBOB) <> 0) or ((AResult.Flags and MOVERESULT_ONTOPOF_FUNCBOB) <> 0) then
        AState.ReachabilityTime := FContext.World.Time + 5;
      // if the bot was going for an elevator and reached the reachability area
      if (AState.AreaNum = LReach.AreaNum) or (AState.ReachabilityTime < FContext.World.Time) then
        LReachNum := 0;
    end
    else
    begin
      // if the goal area changed or the reachability timed out or the area changed
      if (AState.LastGoalAreaNum <> AGoal.AreaNum) or (AState.ReachabilityTime < FContext.World.Time) or
        (AState.LastAreaNum <> AState.AreaNum) then
        LReachNum := 0;
    end;
  end;
  LResultFlags := 0;
  // if the bot needs a new reachability
  if LReachNum = 0 then
  begin
    // get a new reachability leading towards the goal
    LReachNum := FChooser.GetReachabilityToGoal(AState.Origin, AState.AreaNum, AState.LastGoalAreaNum,
      AState.LastAreaNum, AState.AvoidReach, AState.AvoidReachTimes, AState.AvoidReachTries, AGoal, ATravelFlags,
      ATravelFlags, AState.AvoidSpots, AState.NumAvoidSpots, @LResultFlags);
    // the area number the reachability starts in
    AState.ReachAreaNum := AState.AreaNum;
    // reset some state variables: for TRAVEL_JUMP, for TRAVEL_GRAPPLEHOOK
    AState.JumpReach := 0;
    AState.MoveFlags := AState.MoveFlags and not MFL_GRAPPLERESET;
    // if there is a reachability to the goal
    if LReachNum <> 0 then
    begin
      FContext.World.Router.ReachabilityFromNum(LReachNum, LReach);
      // set a timeout for this reachability
      AState.ReachabilityTime := FContext.World.Time + ReachabilityTime(LReach);
      // add the reachability to the reachabilities to avoid for a while
      AState.AddToAvoidReach(LReachNum, AVOIDREACH_TIME, FContext.World.Time);
    end;
  end;
  AState.LastReachNum := LReachNum;
  AState.LastGoalAreaNum := AGoal.AreaNum;
  AState.LastAreaNum := AState.AreaNum;
  // if the bot has a reachability
  if LReachNum <> 0 then
  begin
    // get the reachability from the number
    FContext.World.Router.ReachabilityFromNum(LReachNum, LReach);
    AResult.TravelType := LReach.TravelType;
    if FTravelTypes.TryGetValue(LReach.TravelType and TRAVELTYPE_MASK, LTravel) then
      AResult := LTravel.Travel(AState, LReach)
    else
      FImport.Print(PRT_FATAL, 'travel type ' + TBotCFormat.Int(LReach.TravelType and TRAVELTYPE_MASK) +
        ' not implemented yet'#10);
    AResult.TravelType := LReach.TravelType;
    AResult.Flags := AResult.Flags or LResultFlags;
  end
  else
  begin
    AResult.Failure := True;
    AResult.Flags := AResult.Flags or LResultFlags;
  end;
  Result := False;
end;

procedure TBotMoveSystem.FindJumpPadReachability(const AState: TBotMoveState; const AGoal: TBotGoal;
  const ATravelFlags: Integer);
var
  LEnd: TVec3;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
  LNumAreas: Integer;
  LIndex: Integer;
  LReachNum: Integer;
  LReach: TAasReachability;
  LFoundJumpPad: Boolean;
  LDone: Boolean;
begin
  // special handling of jump pads when the bot uses a jump pad without knowing it
  LFoundJumpPad := False;
  TBotVectorMath.MultiplyAdd(AState.Origin, -2 * AState.ThinkTime, AState.Velocity, LEnd);
  LNumAreas := FContext.World.Tracer.TraceAreas(AState.Origin, LEnd, 16, LAreas, LPoints);
  LDone := False;
  LIndex := LNumAreas - 1;
  while (LIndex >= 0) and (not LDone) do
  begin
    if FContext.World.Areas.AreaJumpPad(LAreas[LIndex]) then
    begin
      LFoundJumpPad := True;
      LReachNum := FChooser.GetReachabilityToGoal(LEnd, LAreas[LIndex], AState.LastGoalAreaNum, AState.LastAreaNum,
        AState.AvoidReach, AState.AvoidReachTimes, AState.AvoidReachTries, AGoal, ATravelFlags, TFL_JUMPPAD,
        AState.AvoidSpots, AState.NumAvoidSpots, nil);
      if LReachNum <> 0 then
      begin
        AState.LastReachNum := LReachNum;
        AState.LastAreaNum := LAreas[LIndex];
        LDone := True;
      end
      else
      begin
        LReachNum := FContext.World.Router.NextAreaReachability(LAreas[LIndex], 0);
        while LReachNum <> 0 do
        begin
          // get the reachability from the number
          FContext.World.Router.ReachabilityFromNum(LReachNum, LReach);
          if (LReach.TravelType and TRAVELTYPE_MASK) = TRAVEL_JUMPPAD then
          begin
            AState.LastReachNum := LReachNum;
            AState.LastAreaNum := LAreas[LIndex];
            Break;
          end;
          LReachNum := FContext.World.Router.NextAreaReachability(LAreas[LIndex], LReachNum);
        end;
        if LReachNum <> 0 then
          LDone := True;
      end;
    end;
    Dec(LIndex);
  end;
  if FContext.Developer then
  begin
    // if a jumppad is found with the trace but no reachability is found
    if LFoundJumpPad and (AState.LastReachNum = 0) then
      FImport.Print(PRT_MESSAGE, 'client ' + TBotCFormat.Int(AState.Client) + ' didn''t find jumppad reachability'#10);
  end;
end;

procedure TBotMoveSystem.TravelInAir(const AState: TBotMoveState; const AGoal: TBotGoal;
  const ATravelFlags: Integer; var AResult: TBotMoveResult);
var
  LReach: TAasReachability;
  LTravel: IBotTravelType;
begin
  FindJumpPadReachability(AState, AGoal, ATravelFlags);
  if AState.LastReachNum <> 0 then
  begin
    FContext.World.Router.ReachabilityFromNum(AState.LastReachNum, LReach);
    AResult.TravelType := LReach.TravelType;
    if FTravelTypes.TryGetValue(LReach.TravelType and TRAVELTYPE_MASK, LTravel) then
      AResult := LTravel.FinishTravel(AState, LReach)
    else
      FImport.Print(PRT_FATAL, '(last) travel type ' + TBotCFormat.Int(LReach.TravelType and TRAVELTYPE_MASK) +
        ' not implemented yet'#10);
    AResult.TravelType := LReach.TravelType;
  end;
end;

function TBotMoveSystem.MoveToGoal(const AHandle: Integer; const AGoal: PBotGoal;
  const ATravelFlags: Integer): TBotMoveResult;
var
  LState: TBotMoveState;
begin
  Result := Default(TBotMoveResult);
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  // reset the grapple before testing if the bot has a valid goal because the bot could loose all it's goals when
  // stuck to a wall
  FGrapple.ResetGrapple(LState);
  if not Assigned(AGoal) then
  begin
    Result.Failure := True;
    Exit;
  end;
  // remove some of the move flags
  LState.MoveFlags := LState.MoveFlags and not (MFL_SWIMMING or MFL_AGAINSTLADDER);
  // set some of the move flags: the MFL_ONGROUND flag is also set in the higher AI
  if FContext.World.Movement.OnGround(LState.Origin, LState.PresenceType, LState.EntityNum) then
    LState.MoveFlags := LState.MoveFlags or MFL_ONGROUND;
  if (LState.MoveFlags and MFL_ONGROUND) <> 0 then
  begin
    if StandingOnEntity(LState, Result) then
      Exit;
  end;
  // if swimming
  if FContext.World.Movement.Swimming(LState.Origin) then
    LState.MoveFlags := LState.MoveFlags or MFL_SWIMMING;
  // if against a ladder
  if FContext.World.Movement.AgainstLadder(LState.Origin) then
    LState.MoveFlags := LState.MoveFlags or MFL_AGAINSTLADDER;
  // if the bot is on the ground, swimming or against a ladder
  if (LState.MoveFlags and (MFL_ONGROUND or MFL_SWIMMING or MFL_AGAINSTLADDER)) <> 0 then
  begin
    if TravelOnGround(LState, AGoal^, ATravelFlags, Result) then
      Exit;
  end
  else
    TravelInAir(LState, AGoal^, ATravelFlags, Result);
  // FIXME: is it right to do this here?
  if Result.Blocked then
    LState.ReachabilityTime := LState.ReachabilityTime - 10 * LState.ThinkTime;
  // copy the last origin
  LState.LastOrigin := LState.Origin;
end;

end.
