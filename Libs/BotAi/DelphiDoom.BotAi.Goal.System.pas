{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotGoalSystem, the goal AI of the bots                }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the states and the  }
{  functions of code\botlib\be_ai_goal.c. Based on the Quake III Arena GPL     }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.System;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Import.Intf,
  DelphiDoom.BotAi.LibVars.Intf,
  DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.Weight.Intf, DelphiDoom.BotAi.Weight.Config,
  DelphiDoom.BotAi.Weight.Breeder,
  DelphiDoom.BotAi.Move.Intf, DelphiDoom.BotAi.Goal.Types, DelphiDoom.BotAi.Goal.ItemConfig,
  DelphiDoom.BotAi.Goal.ItemDefinitions, DelphiDoom.BotAi.Goal.ItemConfigLoader, DelphiDoom.BotAi.Goal.Context,
  DelphiDoom.BotAi.Goal.State, DelphiDoom.BotAi.Goal.Chooser, DelphiDoom.BotAi.Goal.ItemInitializer,
  DelphiDoom.BotAi.Goal.EntityItems, DelphiDoom.BotAi.Goal.Intf;

type
  /// <summary>
  ///   The globals of be_ai_goal.c (<c>botgoalstates[MAX_CLIENTS + 1]</c>, <c>itemconfig</c>, the level items, the
  ///   map locations, the camp spots, <c>g_gametype</c>, <c>droppedweight</c>) are fields. Differences from the
  ///   original (it would crash or read outside its memory): <c>BotInterbreedGoalFuzzyLogic</c> and
  ///   <c>BotMutateGoalFuzzyLogic</c> with a bot that has no weights do nothing; <c>BotFreeItemWeights</c> leaves the
  ///   state without the weights (the original leaves the pointers dangling).
  /// </summary>
  TBotGoalSystem = class(TInterfacedObject, IBotGoalSystem)
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    FLibVars: IBotLibVarStore;
    FWeights: IBotWeightCache;
    FWorld: IBotAasWorld;
    FDefinitions: TBotItemDefinitions;
    FLoader: TBotItemConfigLoader;
    FContext: TBotGoalContext;
    FChooser: TBotGoalChooser;
    FInitializer: TBotLevelItemInitializer;
    FUpdater: TBotEntityItemUpdater;
    FBreeder: TBotWeightBreeder;
    FStates: array[1..BOT_MAX_CLIENTS] of TBotGoalState;
    function StateFromHandle(const AHandle: Integer): TBotGoalState;
    procedure AddToAvoid(const AState: TBotGoalState; const ANumber: Integer; const AAvoidTime: Single);
    function ItemWeightIndex(const AWeights: TBotWeightConfig; const AConfig: TBotItemConfig): TArray<Integer>;
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVarStore;
      const AWeights: IBotWeightCache; const AWorld: IBotAasWorld; const ALocator: IBotReachabilityLocator;
      const ARandom: IBotRandom; const ADeveloper: Boolean);
    destructor Destroy; override;
    function Setup: Integer;
    procedure Shutdown;
    function AllocGoalState(const AClient: Integer): Integer;
    procedure FreeGoalState(const AHandle: Integer);
    procedure ResetGoalState(const AHandle: Integer);
    procedure ResetAvoidGoals(const AHandle: Integer);
    procedure RemoveFromAvoidGoals(const AHandle, ANumber: Integer);
    procedure PushGoal(const AHandle: Integer; const AGoal: TBotGoal);
    procedure PopGoal(const AHandle: Integer);
    procedure EmptyGoalStack(const AHandle: Integer);
    procedure DumpAvoidGoals(const AHandle: Integer);
    procedure DumpGoalStack(const AHandle: Integer);
    function GoalName(const ANumber, ASize: Integer): AnsiString;
    function GetTopGoal(const AHandle: Integer; out AGoal: TBotGoal): Boolean;
    function GetSecondGoal(const AHandle: Integer; out AGoal: TBotGoal): Boolean;
    function ChooseLTGItem(const AHandle: Integer; const AOrigin: TVec3; const AInventory: TArray<Integer>;
      const ATravelFlags: Integer): Boolean;
    function ChooseNBGItem(const AHandle: Integer; const AOrigin: TVec3; const AInventory: TArray<Integer>;
      const ATravelFlags: Integer; const ALtg: PBotGoal; const AMaxTime: Single): Boolean;
    function TouchingGoal(const AOrigin: TVec3; const AGoal: TBotGoal): Boolean;
    function ItemGoalInVisButNotVisible(const AViewer: Integer; const AEye, AViewAngles: TVec3;
      const AGoal: TBotGoal): Boolean;
    function GetLevelItemGoal(const AIndex: Integer; const AName: AnsiString; var AGoal: TBotGoal): Integer;
    function GetNextCampSpotGoal(const ANum: Integer; var AGoal: TBotGoal): Integer;
    function GetMapLocationGoal(const AName: AnsiString; var AGoal: TBotGoal): Boolean;
    function AvoidGoalTime(const AHandle, ANumber: Integer): Single;
    procedure SetAvoidGoalTime(const AHandle, ANumber: Integer; const AAvoidTime: Single);
    procedure InitLevelItems;
    procedure UpdateEntityItems;
    procedure InterbreedGoalFuzzyLogic(const AParent1, AParent2, AChild: Integer);
    procedure SaveGoalFuzzyLogic(const AHandle: Integer; const AFileName: AnsiString);
    procedure MutateGoalFuzzyLogic(const AHandle: Integer; const ARange: Single);
    function LoadItemWeights(const AHandle: Integer; const AFileName: AnsiString): Integer;
    procedure FreeItemWeights(const AHandle: Integer);
    function ItemConfig: TBotItemConfig;
    function LevelItemCount: Integer;
    /// <summary>What the goal AI shares (the level items, the camp spots ...), for the tools and the tests</summary>
    function Context: TBotGoalContext;
  end;

implementation

uses
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Entity.Types, DelphiDoom.Aas.BoxMath,
  DelphiDoom.BotAi.Text.CFormat,
  DelphiDoom.BotAi.Chat.Text, DelphiDoom.BotAi.Weapon.Types,
  DelphiDoom.BotAi.Goal.LevelItems;

const
  /// <summary>CONTENTS_SOLID of surfaceflags.h</summary>
  MASK_SOLID = 1;

{ TBotGoalSystem }

constructor TBotGoalSystem.Create(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVarStore; const AWeights: IBotWeightCache; const AWorld: IBotAasWorld;
  const ALocator: IBotReachabilityLocator; const ARandom: IBotRandom; const ADeveloper: Boolean);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
  FLibVars := ALibVars;
  FWeights := AWeights;
  FWorld := AWorld;
  FDefinitions := TBotItemDefinitions.Create;
  FLoader := TBotItemConfigLoader.Create(AImport, AFiles, ALibVars, FDefinitions);
  FContext := TBotGoalContext.Create(AImport);
  FChooser := TBotGoalChooser.Create(AWorld, ALibVars, ALocator, FContext);
  FInitializer := TBotLevelItemInitializer.Create(AImport, ALibVars, AWorld, FContext, ADeveloper);
  FUpdater := TBotEntityItemUpdater.Create(AWorld, FContext);
  FBreeder := TBotWeightBreeder.Create(AImport, ARandom);
end;

destructor TBotGoalSystem.Destroy;
var
  LHandle: Integer;
begin
  for LHandle := Low(FStates) to High(FStates) do
    FreeAndNil(FStates[LHandle]);
  FBreeder.Free;
  FUpdater.Free;
  FInitializer.Free;
  FChooser.Free;
  FContext.Free;
  FLoader.Free;
  FDefinitions.Free;
  inherited Destroy;
end;

function TBotGoalSystem.StateFromHandle(const AHandle: Integer): TBotGoalState;
begin
  if (AHandle <= 0) or (AHandle > BOT_MAX_CLIENTS) then
  begin
    FImport.Print(PRT_FATAL, 'goal state handle ' + TBotCFormat.Int(AHandle) + ' out of range'#10);
    Exit(nil);
  end;
  if not Assigned(FStates[AHandle]) then
  begin
    FImport.Print(PRT_FATAL, 'invalid goal state ' + TBotCFormat.Int(AHandle) + #10);
    Exit(nil);
  end;
  Result := FStates[AHandle];
end;

procedure TBotGoalSystem.AddToAvoid(const AState: TBotGoalState; const ANumber: Integer; const AAvoidTime: Single);
begin
  AState.AddToAvoidGoals(ANumber, AAvoidTime, FWorld.Time);
end;

function TBotGoalSystem.ItemWeightIndex(const AWeights: TBotWeightConfig; const AConfig: TBotItemConfig): TArray<Integer>;
var
  LIndex: Integer;
  LName: AnsiString;
  LInfo: TBotItemInfo;
begin
  // initialize item weight index
  SetLength(Result, AConfig.Count);
  for LIndex := 0 to AConfig.Count - 1 do
  begin
    LInfo := AConfig.Info(LIndex);
    LName := BotFieldText(LInfo.ClassName);
    Result[LIndex] := AWeights.FindFuzzyWeight(LName);
    if Result[LIndex] < 0 then
      FImport.LogWrite('item info ' + TBotCFormat.Int(LIndex) + ' "' + LName + '" has no fuzzy weight'#13#10);
  end;
end;

function TBotGoalSystem.Setup: Integer;
var
  LFileName: AnsiString;
  LConfig: TBotItemConfig;
begin
  // check if teamplay is on
  FContext.GameType := Trunc(FLibVars.GetValueOrCreate('g_gametype', '0'));
  // item configuration file
  LFileName := FLibVars.GetStringOrCreate('itemconfig', 'items.c');
  // load the item configuration
  LConfig := FLoader.Load(LFileName);
  FContext.ReplaceItemConfig(LConfig);
  if not Assigned(LConfig) then
  begin
    FImport.Print(PRT_FATAL, 'couldn''t load item config'#10);
    Exit(BLERR_CANNOTLOADITEMCONFIG);
  end;
  FLibVars.GetValueOrCreate('droppedweight', '1000');
  // everything went ok
  Result := BLERR_NOERROR;
end;

procedure TBotGoalSystem.Shutdown;
var
  LHandle: Integer;
begin
  FContext.ReplaceItemConfig(nil);
  FContext.LevelItems.Reset;
  FContext.NumLevelItems := 0;
  FContext.InfoEntities.Clear;
  for LHandle := Low(FStates) to High(FStates) do
  begin
    if Assigned(FStates[LHandle]) then
      FreeGoalState(LHandle);
  end;
end;

function TBotGoalSystem.AllocGoalState(const AClient: Integer): Integer;
var
  LHandle: Integer;
begin
  for LHandle := Low(FStates) to High(FStates) do
  begin
    if not Assigned(FStates[LHandle]) then
    begin
      FStates[LHandle] := TBotGoalState.Create;
      FStates[LHandle].Client := AClient;
      Exit(LHandle);
    end;
  end;
  Result := 0;
end;

procedure TBotGoalSystem.FreeGoalState(const AHandle: Integer);
begin
  if (AHandle <= 0) or (AHandle > BOT_MAX_CLIENTS) then
  begin
    FImport.Print(PRT_FATAL, 'goal state handle ' + TBotCFormat.Int(AHandle) + ' out of range'#10);
    Exit;
  end;
  if not Assigned(FStates[AHandle]) then
  begin
    FImport.Print(PRT_FATAL, 'invalid goal state handle ' + TBotCFormat.Int(AHandle) + #10);
    Exit;
  end;
  FreeItemWeights(AHandle);
  FreeAndNil(FStates[AHandle]);
end;

procedure TBotGoalSystem.ResetGoalState(const AHandle: Integer);
var
  LState: TBotGoalState;
  LIndex: Integer;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  for LIndex := 0 to MAX_GOALSTACK - 1 do
    LState.GoalStack[LIndex] := Default(TBotGoal);
  LState.GoalStackTop := 0;
  ResetAvoidGoals(AHandle);
end;

procedure TBotGoalSystem.ResetAvoidGoals(const AHandle: Integer);
var
  LState: TBotGoalState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  LState.ResetAvoidGoals;
end;

procedure TBotGoalSystem.RemoveFromAvoidGoals(const AHandle, ANumber: Integer);
var
  LState: TBotGoalState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  LState.RemoveFromAvoidGoals(ANumber, FWorld.Time);
end;

procedure TBotGoalSystem.PushGoal(const AHandle: Integer; const AGoal: TBotGoal);
var
  LState: TBotGoalState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  if LState.GoalStackTop >= MAX_GOALSTACK - 1 then
  begin
    FImport.Print(PRT_ERROR, 'goal heap overflow'#10);
    DumpGoalStack(AHandle);
    Exit;
  end;
  Inc(LState.GoalStackTop);
  LState.GoalStack[LState.GoalStackTop] := AGoal;
end;

procedure TBotGoalSystem.PopGoal(const AHandle: Integer);
var
  LState: TBotGoalState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  if LState.GoalStackTop > 0 then
    Dec(LState.GoalStackTop);
end;

procedure TBotGoalSystem.EmptyGoalStack(const AHandle: Integer);
var
  LState: TBotGoalState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  LState.GoalStackTop := 0;
end;

procedure TBotGoalSystem.DumpAvoidGoals(const AHandle: Integer);
var
  LState: TBotGoalState;
  LIndex: Integer;
  LTime: Single;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  for LIndex := 0 to MAX_AVOIDGOALS - 1 do
  begin
    if LState.AvoidGoalUntil(LIndex) >= FWorld.Time then
    begin
      LTime := LState.AvoidGoalUntil(LIndex) - FWorld.Time;
      FImport.LogWrite('avoid goal ' + GoalName(LState.AvoidGoalNumber(LIndex), 32) + ', number ' +
        TBotCFormat.Int(LState.AvoidGoalNumber(LIndex)) + ' for ' + TBotCFormat.Fixed6(LTime) + ' seconds');
    end;
  end;
end;

procedure TBotGoalSystem.DumpGoalStack(const AHandle: Integer);
var
  LState: TBotGoalState;
  LIndex: Integer;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  for LIndex := 1 to LState.GoalStackTop do
    FImport.LogWrite(TBotCFormat.Int(LIndex) + ': ' + GoalName(LState.GoalStack[LIndex].Number, 32));
end;

function TBotGoalSystem.GoalName(const ANumber, ASize: Integer): AnsiString;
var
  LCurrent: Integer;
  LItem: PBotLevelItem;
  LInfo: TBotItemInfo;
begin
  Result := '';
  if not Assigned(FContext.ItemConfig) then
    Exit;
  LCurrent := FContext.LevelItems.Head;
  while LCurrent <> TBotLevelItems.NoItem do
  begin
    LItem := FContext.LevelItems.Item(LCurrent);
    if LItem.Number = ANumber then
    begin
      // strncpy(name, name, size - 1); name[size - 1] = 0
      LInfo := FContext.ItemConfig.Info(LItem.ItemInfo);
      Result := Copy(BotFieldText(LInfo.Name), 1, ASize - 1);
      Exit;
    end;
    LCurrent := LItem.Next;
  end;
end;

function TBotGoalSystem.GetTopGoal(const AHandle: Integer; out AGoal: TBotGoal): Boolean;
var
  LState: TBotGoalState;
begin
  AGoal := Default(TBotGoal);
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit(False);
  if LState.GoalStackTop = 0 then
    Exit(False);
  AGoal := LState.GoalStack[LState.GoalStackTop];
  Result := True;
end;

function TBotGoalSystem.GetSecondGoal(const AHandle: Integer; out AGoal: TBotGoal): Boolean;
var
  LState: TBotGoalState;
begin
  AGoal := Default(TBotGoal);
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit(False);
  if LState.GoalStackTop <= 1 then
    Exit(False);
  AGoal := LState.GoalStack[LState.GoalStackTop - 1];
  Result := True;
end;

function TBotGoalSystem.ChooseLTGItem(const AHandle: Integer; const AOrigin: TVec3;
  const AInventory: TArray<Integer>; const ATravelFlags: Integer): Boolean;
var
  LState: TBotGoalState;
  LGoal: TBotGoal;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit(False);
  if not FChooser.ChooseLongTerm(LState, AOrigin, AInventory, ATravelFlags, LGoal) then
    Exit(False);
  // push the goal on the stack
  PushGoal(AHandle, LGoal);
  Result := True;
end;

function TBotGoalSystem.ChooseNBGItem(const AHandle: Integer; const AOrigin: TVec3;
  const AInventory: TArray<Integer>; const ATravelFlags: Integer; const ALtg: PBotGoal;
  const AMaxTime: Single): Boolean;
var
  LState: TBotGoalState;
  LGoal: TBotGoal;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit(False);
  if not FChooser.ChooseNearby(LState, AOrigin, AInventory, ATravelFlags, ALtg, AMaxTime, LGoal) then
    Exit(False);
  // push the goal on the stack
  PushGoal(AHandle, LGoal);
  Result := True;
end;

function TBotGoalSystem.TouchingGoal(const AOrigin: TVec3; const AGoal: TBotGoal): Boolean;
var
  LBoxMins: TVec3;
  LBoxMaxs: TVec3;
  LAbsMins: TVec3;
  LAbsMaxs: TVec3;
  LIndex: Integer;
begin
  TAasBoxMath.PresenceTypeBoundingBox(FImport, PRESENCE_NORMAL, LBoxMins, LBoxMaxs);
  for LIndex := 0 to 2 do
  begin
    LAbsMins[LIndex] := AGoal.Mins[LIndex] - LBoxMaxs[LIndex];
    LAbsMaxs[LIndex] := AGoal.Maxs[LIndex] - LBoxMins[LIndex];
    LAbsMins[LIndex] := LAbsMins[LIndex] + AGoal.Origin[LIndex];
    LAbsMaxs[LIndex] := LAbsMaxs[LIndex] + AGoal.Origin[LIndex];
    // make the box a little smaller for safety: the safety boxes are zero
    LAbsMaxs[LIndex] := LAbsMaxs[LIndex] - 0;
    LAbsMins[LIndex] := LAbsMins[LIndex] - 0;
  end;
  for LIndex := 0 to 2 do
  begin
    if (AOrigin[LIndex] < LAbsMins[LIndex]) or (AOrigin[LIndex] > LAbsMaxs[LIndex]) then
      Exit(False);
  end;
  Result := True;
end;

function TBotGoalSystem.ItemGoalInVisButNotVisible(const AViewer: Integer; const AEye, AViewAngles: TVec3;
  const AGoal: TBotGoal): Boolean;
var
  LMiddle: TVec3;
  LTrace: TAasBspTrace;
  LInfo: TAasEntityInfo;
  LIndex: Integer;
begin
  Result := False;
  if (AGoal.Flags and GFL_ITEM) = 0 then
    Exit;
  // the original adds the mins to the mins (not the maxs): kept
  for LIndex := 0 to 2 do
  begin
    LMiddle[LIndex] := AGoal.Mins[LIndex] + AGoal.Mins[LIndex];
    LMiddle[LIndex] := LMiddle[LIndex] * 0.5;
    LMiddle[LIndex] := AGoal.Origin[LIndex] + LMiddle[LIndex];
  end;
  LTrace := FWorld.Bsp.Trace(AEye, nil, nil, LMiddle, AViewer, MASK_SOLID);
  // if the goal middle point is visible
  if LTrace.Fraction >= 1 then
  begin
    // the goal entity number doesn't have to be valid: just assume it's valid
    if AGoal.EntityNum <= 0 then
      Exit(False);
    // if the entity data isn't valid
    LInfo := FWorld.Entities.EntityInfo(AGoal.EntityNum);
    // NOTE: for some wacko reason entities are sometimes not updated
    if Double(LInfo.LocalTime) < Double(FWorld.Time) - 0.5 then
      Exit(True);
  end;
end;

function TBotGoalSystem.GetLevelItemGoal(const AIndex: Integer; const AName: AnsiString;
  var AGoal: TBotGoal): Integer;
var
  LCurrent: Integer;
  LItem: PBotLevelItem;
  LInfo: TBotItemInfo;
begin
  if not Assigned(FContext.ItemConfig) then
    Exit(-1);
  LCurrent := FContext.LevelItems.Head;
  if AIndex >= 0 then
  begin
    while LCurrent <> TBotLevelItems.NoItem do
    begin
      LItem := FContext.LevelItems.Item(LCurrent);
      if LItem.Number = AIndex then
      begin
        LCurrent := LItem.Next;
        Break;
      end;
      LCurrent := LItem.Next;
    end;
  end;
  while LCurrent <> TBotLevelItems.NoItem do
  begin
    LItem := FContext.LevelItems.Item(LCurrent);
    LCurrent := LItem.Next;
    if FContext.GameType = GT_SINGLE_PLAYER then
    begin
      if (LItem.Flags and IFL_NOTSINGLE) <> 0 then
        Continue;
    end
    else if FContext.GameType >= GT_TEAM then
    begin
      if (LItem.Flags and IFL_NOTTEAM) <> 0 then
        Continue;
    end
    else
    begin
      if (LItem.Flags and IFL_NOTFREE) <> 0 then
        Continue;
    end;
    if (LItem.Flags and IFL_NOTBOT) <> 0 then
      Continue;
    LInfo := FContext.ItemConfig.Info(LItem.ItemInfo);
    if TBotChatText.SameTextAscii(AName, BotFieldText(LInfo.Name)) then
    begin
      AGoal.AreaNum := LItem.GoalAreaNum;
      AGoal.Origin := LItem.GoalOrigin;
      AGoal.EntityNum := LItem.EntityNum;
      AGoal.Mins := LInfo.Mins;
      AGoal.Maxs := LInfo.Maxs;
      AGoal.Number := LItem.Number;
      AGoal.Flags := GFL_ITEM;
      if LItem.Timeout <> 0 then
        AGoal.Flags := AGoal.Flags or GFL_DROPPED;
      Exit(LItem.Number);
    end;
  end;
  Result := -1;
end;

function TBotGoalSystem.GetNextCampSpotGoal(const ANum: Integer; var AGoal: TBotGoal): Integer;
begin
  Result := FContext.InfoEntities.GetNextCampSpotGoal(ANum, AGoal);
end;

function TBotGoalSystem.GetMapLocationGoal(const AName: AnsiString; var AGoal: TBotGoal): Boolean;
begin
  Result := FContext.InfoEntities.GetMapLocationGoal(AName, AGoal);
end;

function TBotGoalSystem.AvoidGoalTime(const AHandle, ANumber: Integer): Single;
var
  LState: TBotGoalState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit(0);
  Result := LState.AvoidGoalTime(ANumber, FWorld.Time);
end;

procedure TBotGoalSystem.SetAvoidGoalTime(const AHandle, ANumber: Integer; const AAvoidTime: Single);
var
  LState: TBotGoalState;
  LCurrent: Integer;
  LItem: PBotLevelItem;
  LAvoidTime: Single;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  if AAvoidTime < 0 then
  begin
    if not Assigned(FContext.ItemConfig) then
      Exit;
    LCurrent := FContext.LevelItems.Head;
    while LCurrent <> TBotLevelItems.NoItem do
    begin
      LItem := FContext.LevelItems.Item(LCurrent);
      if LItem.Number = ANumber then
      begin
        LAvoidTime := FContext.ItemConfig.Info(LItem.ItemInfo).RespawnTime;
        if LAvoidTime = 0 then
          LAvoidTime := AVOID_DEFAULT_TIME;
        if LAvoidTime < AVOID_MINIMUM_TIME then
          LAvoidTime := AVOID_MINIMUM_TIME;
        AddToAvoid(LState, ANumber, LAvoidTime);
        Exit;
      end;
      LCurrent := LItem.Next;
    end;
  end
  else
    AddToAvoid(LState, ANumber, AAvoidTime);
end;

procedure TBotGoalSystem.InitLevelItems;
begin
  FInitializer.Init;
end;

procedure TBotGoalSystem.UpdateEntityItems;
begin
  FUpdater.Update;
end;

procedure TBotGoalSystem.InterbreedGoalFuzzyLogic(const AParent1, AParent2, AChild: Integer);
var
  LFirst: TBotGoalState;
  LSecond: TBotGoalState;
  LChild: TBotGoalState;
begin
  LFirst := StateFromHandle(AParent1);
  LSecond := StateFromHandle(AParent2);
  LChild := StateFromHandle(AChild);
  // the original dereferences a state that does not exist or has no weights
  if (not Assigned(LFirst)) or (not Assigned(LSecond)) or (not Assigned(LChild)) then
    Exit;
  if (not Assigned(LFirst.ItemWeightConfig)) or (not Assigned(LSecond.ItemWeightConfig)) or
    (not Assigned(LChild.ItemWeightConfig)) then
    Exit;
  FBreeder.Interbreed(LFirst.ItemWeightConfig, LSecond.ItemWeightConfig, LChild.ItemWeightConfig);
end;

procedure TBotGoalSystem.SaveGoalFuzzyLogic(const AHandle: Integer; const AFileName: AnsiString);
begin
  // WriteWeightConfig(filename, gs->itemweightconfig) is commented out in the original: only the handle is checked
  StateFromHandle(AHandle);
end;

procedure TBotGoalSystem.MutateGoalFuzzyLogic(const AHandle: Integer; const ARange: Single);
var
  LState: TBotGoalState;
begin
  LState := StateFromHandle(AHandle);
  if (not Assigned(LState)) or (not Assigned(LState.ItemWeightConfig)) then
    Exit;
  FBreeder.Evolve(LState.ItemWeightConfig);
end;

function TBotGoalSystem.LoadItemWeights(const AHandle: Integer; const AFileName: AnsiString): Integer;
var
  LState: TBotGoalState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit(BLERR_CANNOTLOADITEMWEIGHTS);
  // load the weight configuration
  LState.ItemWeightConfig := FWeights.ReadWeightConfig(AFileName);
  if not Assigned(LState.ItemWeightConfig) then
  begin
    FImport.Print(PRT_FATAL, 'couldn''t load weights'#10);
    Exit(BLERR_CANNOTLOADITEMWEIGHTS);
  end;
  // if there's no item configuration
  if not Assigned(FContext.ItemConfig) then
    Exit(BLERR_CANNOTLOADITEMWEIGHTS);
  // create the item weight index
  LState.ItemWeightIndex := ItemWeightIndex(LState.ItemWeightConfig, FContext.ItemConfig);
  // everything went ok
  Result := BLERR_NOERROR;
end;

procedure TBotGoalSystem.FreeItemWeights(const AHandle: Integer);
var
  LState: TBotGoalState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  if Assigned(LState.ItemWeightConfig) then
    FWeights.FreeWeightConfig(LState.ItemWeightConfig);
  // the original frees the index and leaves both pointers dangling (a goal chosen afterwards reads freed memory)
  LState.ItemWeightConfig := nil;
  LState.ItemWeightIndex := nil;
end;

function TBotGoalSystem.ItemConfig: TBotItemConfig;
begin
  Result := FContext.ItemConfig;
end;

function TBotGoalSystem.LevelItemCount: Integer;
begin
  Result := FContext.NumLevelItems;
end;

function TBotGoalSystem.Context: TBotGoalContext;
begin
  Result := FContext;
end;

end.
