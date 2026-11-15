{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotLevelItemInitializer, BotInitLevelItems            }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotInitLevelItems   }
{  of code\botlib\be_ai_goal.c. Based on the Quake III Arena GPL Source Code   }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.ItemInitializer;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.Goal.Context;

type
  /// <summary>
  ///   Makes the level items of the loaded map from its entities: a floating item that is not near the ground needs
  ///   a jump pad area, the others are dropped to the floor and get the best area the bots can reach.
  ///   Differences from the original (a defect): with <c>max_levelitems</c> 0 the original writes before its heap;
  ///   here there are no level items and the first one prints "out of level items".
  /// </summary>
  TBotLevelItemInitializer = class
  strict private
    FImport: IBotImport;
    FLibVars: IBotLibVars;
    FWorld: IBotAasWorld;
    FContext: TBotGoalContext;
    FDeveloper: Boolean;
    function InitEntity(const AEntity: Integer; const ANames: TArray<AnsiString>): Boolean;
  public
    constructor Create(const AImport: IBotImport; const ALibVars: IBotLibVars; const AWorld: IBotAasWorld;
      const AContext: TBotGoalContext; const ADeveloper: Boolean);
    /// <summary>BotInitLevelItems</summary>
    procedure Init;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Bsp.Intf,
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Text.CFormat, DelphiDoom.BotAi.Weapon.Types, DelphiDoom.BotAi.Goal.Types,
  DelphiDoom.BotAi.Goal.ItemConfig, DelphiDoom.BotAi.Goal.LevelItems;

const
  MAX_EPAIRKEY = 128;
  /// <summary>CONTENTS_SOLID or CONTENTS_PLAYERCLIP of surfaceflags.h</summary>
  MASK_SOLID_PLAYERCLIP = $00010001;

{ TBotLevelItemInitializer }

constructor TBotLevelItemInitializer.Create(const AImport: IBotImport; const ALibVars: IBotLibVars;
  const AWorld: IBotAasWorld; const AContext: TBotGoalContext; const ADeveloper: Boolean);
begin
  inherited Create;
  FImport := AImport;
  FLibVars := ALibVars;
  FWorld := AWorld;
  FContext := AContext;
  FDeveloper := ADeveloper;
end;

function TBotLevelItemInitializer.InitEntity(const AEntity: Integer; const ANames: TArray<AnsiString>): Boolean;
var
  LEntities: IAasBspEntities;
  LItems: TBotLevelItems;
  LConfig: TBotItemConfig;
  LInfo: TBotItemInfo;
  LClassName: AnsiString;
  LSpawnFlags: Integer;
  LValue: Integer;
  LIndex: Integer;
  LOrigin: TVec3;
  LEnd: TVec3;
  LMins: TVec3;
  LMaxs: TVec3;
  LTrace: TAasBspTrace;
  LGoalArea: Integer;
  LItem: Integer;
  LLevelItem: PBotLevelItem;
begin
  // False only when the heap of level items is empty ("return" of the original); True goes on to the next entity
  Result := True;
  LEntities := FWorld.BspEntities;
  LItems := FContext.LevelItems;
  LConfig := FContext.ItemConfig;
  if not LEntities.ValueForKey(AEntity, 'classname', LClassName, MAX_EPAIRKEY) then
    Exit;
  LSpawnFlags := 0;
  LEntities.IntForKey(AEntity, 'spawnflags', LSpawnFlags);
  LIndex := 0;
  while (LIndex < LConfig.Count) and (LClassName <> ANames[LIndex]) do
    Inc(LIndex);
  if LIndex >= LConfig.Count then
  begin
    FImport.LogWrite('entity ' + LClassName + ' unknown item'#13#10);
    Exit;
  end;
  LInfo := LConfig.Info(LIndex);
  // get the origin of the item
  if not LEntities.VectorForKey(AEntity, 'origin', LOrigin) then
  begin
    FImport.Print(PRT_ERROR, 'item ' + LClassName + ' without origin'#10);
    Exit;
  end;
  LGoalArea := 0;
  // if it is a floating item
  if (LSpawnFlags and 1) <> 0 then
  begin
    // if the item is not floating in water
    if (FWorld.Bsp.PointContents(LOrigin) and BSP_CONTENTS_WATER) = 0 then
    begin
      LEnd := LOrigin;
      LEnd[2] := LEnd[2] - 32;
      LMins := LInfo.Mins;
      LMaxs := LInfo.Maxs;
      LTrace := FWorld.Bsp.Trace(LOrigin, @LMins, @LMaxs, LEnd, -1, MASK_SOLID_PLAYERCLIP);
      // if the item not near the ground
      if LTrace.Fraction >= 1 then
      begin
        // if the item is not reachable from a jumppad
        LGoalArea := FWorld.BestReachable.BestReachableFromJumpPadArea(LOrigin, LInfo.Mins, LInfo.Maxs);
        FImport.LogWrite('item ' + ANames[LIndex] + ' reachable from jumppad area ' + TBotCFormat.Int(LGoalArea) +
          #13#10);
        if LGoalArea = 0 then
          Exit;
      end;
    end;
  end;
  LItem := LItems.Alloc;
  if LItem = TBotLevelItems.NoItem then
    Exit(False);
  LLevelItem := LItems.Item(LItem);
  Inc(FContext.NumLevelItems);
  LLevelItem.Number := FContext.NumLevelItems;
  LLevelItem.Timeout := 0;
  LLevelItem.EntityNum := 0;
  LLevelItem.Flags := 0;
  LValue := 0;
  LEntities.IntForKey(AEntity, 'notfree', LValue);
  if LValue <> 0 then
    LLevelItem.Flags := LLevelItem.Flags or IFL_NOTFREE;
  LEntities.IntForKey(AEntity, 'notteam', LValue);
  if LValue <> 0 then
    LLevelItem.Flags := LLevelItem.Flags or IFL_NOTTEAM;
  LEntities.IntForKey(AEntity, 'notsingle', LValue);
  if LValue <> 0 then
    LLevelItem.Flags := LLevelItem.Flags or IFL_NOTSINGLE;
  LEntities.IntForKey(AEntity, 'notbot', LValue);
  if LValue <> 0 then
    LLevelItem.Flags := LLevelItem.Flags or IFL_NOTBOT;
  if LClassName = 'item_botroam' then
  begin
    LLevelItem.Flags := LLevelItem.Flags or IFL_ROAM;
    LEntities.FloatForKey(AEntity, 'weight', LLevelItem.Weight);
  end;
  // if not a stationary item
  if (LSpawnFlags and 1) = 0 then
  begin
    if not FWorld.Movement.DropToFloor(LOrigin, LInfo.Mins, LInfo.Maxs) then
      FImport.Print(PRT_MESSAGE, LClassName + ' in solid at (' + TBotCFormat.Fixed1(LOrigin[0]) + ' ' +
        TBotCFormat.Fixed1(LOrigin[1]) + ' ' + TBotCFormat.Fixed1(LOrigin[2]) + ')'#10);
  end;
  // item info of the level item
  LLevelItem.ItemInfo := LIndex;
  // origin of the item
  LLevelItem.Origin := LOrigin;
  if LGoalArea <> 0 then
  begin
    LLevelItem.GoalAreaNum := LGoalArea;
    LLevelItem.GoalOrigin := LOrigin;
  end
  else
  begin
    // get the item goal area and goal origin
    LLevelItem.GoalAreaNum := FWorld.BestReachable.BestReachableArea(LOrigin, LInfo.Mins, LInfo.Maxs,
      LLevelItem.GoalOrigin);
    if LLevelItem.GoalAreaNum = 0 then
      FImport.Print(PRT_MESSAGE, LClassName + ' not reachable for bots at (' + TBotCFormat.Fixed1(LOrigin[0]) + ' ' +
        TBotCFormat.Fixed1(LOrigin[1]) + ' ' + TBotCFormat.Fixed1(LOrigin[2]) + ')'#10);
  end;
  LItems.AddToList(LItem);
end;

procedure TBotLevelItemInitializer.Init;
var
  LConfig: TBotItemConfig;
  LInfo: TBotItemInfo;
  LNames: TArray<AnsiString>;
  LIndex: Integer;
  LEntity: Integer;
  LEntities: IAasBspEntities;
begin
  // initialize the map locations and camp spots
  FContext.InfoEntities.Init(FWorld, FDeveloper);
  // initialize the level item heap
  FContext.LevelItems.Init(Trunc(FLibVars.GetValueOrCreate('max_levelitems', '256')));
  FContext.LevelItems.ClearList;
  FContext.NumLevelItems := 0;
  LConfig := FContext.ItemConfig;
  if not Assigned(LConfig) then
    Exit;
  // if there's no AAS file loaded
  if not FWorld.Loaded then
    Exit;
  // update the modelindexes of the item info
  SetLength(LNames, LConfig.Count);
  for LIndex := 0 to LConfig.Count - 1 do
  begin
    LInfo := LConfig.Info(LIndex);
    LNames[LIndex] := BotFieldText(LInfo.ClassName);
    if LInfo.ModelIndex = 0 then
      FImport.LogWrite('item ' + LNames[LIndex] + ' has modelindex 0');
  end;
  LEntities := FWorld.BspEntities;
  LEntity := LEntities.NextEntity(0);
  while LEntity <> 0 do
  begin
    if not InitEntity(LEntity, LNames) then
      Exit;
    LEntity := LEntities.NextEntity(LEntity);
  end;
  FImport.Print(PRT_MESSAGE, 'found ' + TBotCFormat.Int(FContext.NumLevelItems) + ' level items'#10);
end;

end.
