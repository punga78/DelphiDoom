{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotEntityItemUpdater, BotUpdateEntityItems            }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotUpdateEntityItems}
{  of code\botlib\be_ai_goal.c. Based on the Quake III Arena GPL Source Code   }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.EntityItems;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Entity.Types, DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.Goal.Types,
  DelphiDoom.BotAi.Goal.LevelItems, DelphiDoom.BotAi.Goal.Context;

type
  /// <summary>
  ///   The items that are in the game as entities (dropped weapons, flags ...): they time out after 30 seconds,
  ///   an entity that is near a level item of the same model is linked to it, any other known model becomes a new
  ///   level item that is numbered <c>numlevelitems + entity</c>. Items that were dropped into a jump pad are not
  ///   wanted. The entities that are still moving are skipped.
  /// </summary>
  TBotEntityItemUpdater = class
  strict private
    FWorld: IBotAasWorld;
    FContext: TBotGoalContext;
    function ItemAllowed(const AItem: PBotLevelItem): Boolean;
    procedure MoveItem(const AItem: PBotLevelItem; const AInfo: TAasEntityInfo);
    function FindStoredItem(const AEntity, AModelIndex: Integer; const AInfo: TAasEntityInfo): Boolean;
    procedure HandleEntity(const AEntity: Integer);
    function LinkToLevelItem(const AEntity, AModelIndex: Integer; const AInfo: TAasEntityInfo): Boolean;
    procedure AddNewItem(const AEntity, AModelIndex: Integer; const AInfo: TAasEntityInfo);
    procedure RemoveTimedOut;
  public
    constructor Create(const AWorld: IBotAasWorld; const AContext: TBotGoalContext);
    /// <summary>BotUpdateEntityItems</summary>
    procedure Update;
  end;

implementation

uses
  DelphiDoom.Aas.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Goal.ItemConfig;

const
  /// <summary>A new level item for a dropped item disappears after 30 seconds</summary>
  DROPPED_ITEM_TIME = 30;
  /// <summary>An entity closer than this to a level item of the same model is that item</summary>
  LINK_DISTANCE = 30;

function SameOrigin(const AFirst, ASecond: TVec3): Boolean;
begin
  Result := (AFirst[0] = ASecond[0]) and (AFirst[1] = ASecond[1]) and (AFirst[2] = ASecond[2]);
end;

{ TBotEntityItemUpdater }

constructor TBotEntityItemUpdater.Create(const AWorld: IBotAasWorld; const AContext: TBotGoalContext);
begin
  inherited Create;
  FWorld := AWorld;
  FContext := AContext;
end;

function TBotEntityItemUpdater.ItemAllowed(const AItem: PBotLevelItem): Boolean;
begin
  Result := False;
  if FContext.GameType = GT_SINGLE_PLAYER then
  begin
    if (AItem.Flags and IFL_NOTSINGLE) <> 0 then
      Exit;
  end
  else if FContext.GameType >= GT_TEAM then
  begin
    if (AItem.Flags and IFL_NOTTEAM) <> 0 then
      Exit;
  end
  else
  begin
    if (AItem.Flags and IFL_NOTFREE) <> 0 then
      Exit;
  end;
  Result := True;
end;

procedure TBotEntityItemUpdater.MoveItem(const AItem: PBotLevelItem; const AInfo: TAasEntityInfo);
var
  LItemInfo: TBotItemInfo;
begin
  AItem.Origin := AInfo.Origin;
  LItemInfo := FContext.ItemConfig.Info(AItem.ItemInfo);
  // also update the goal area number
  AItem.GoalAreaNum := FWorld.BestReachable.BestReachableArea(AItem.Origin, LItemInfo.Mins, LItemInfo.Maxs,
    AItem.GoalOrigin);
end;

procedure TBotEntityItemUpdater.RemoveTimedOut;
var
  LCurrent: Integer;
  LNext: Integer;
  LItem: PBotLevelItem;
begin
  // timeout current entity items if necessary
  LCurrent := FContext.LevelItems.Head;
  while LCurrent <> TBotLevelItems.NoItem do
  begin
    LItem := FContext.LevelItems.Item(LCurrent);
    LNext := LItem.Next;
    // if it is a item that will time out
    if (LItem.Timeout <> 0) and (LItem.Timeout < FWorld.Time) then
    begin
      // timeout the item
      FContext.LevelItems.RemoveFromList(LCurrent);
      FContext.LevelItems.Release(LCurrent);
    end;
    LCurrent := LNext;
  end;
end;

function TBotEntityItemUpdater.FindStoredItem(const AEntity, AModelIndex: Integer;
  const AInfo: TAasEntityInfo): Boolean;
var
  LCurrent: Integer;
  LItem: PBotLevelItem;
begin
  // True if the entity is stored as a level item of its model (stored with another model: the item is removed and
  // the entity is dealt with as a new one)
  Result := False;
  LCurrent := FContext.LevelItems.Head;
  while LCurrent <> TBotLevelItems.NoItem do
  begin
    LItem := FContext.LevelItems.Item(LCurrent);
    // if the level item is linked to an entity
    if (LItem.EntityNum <> 0) and (LItem.EntityNum = AEntity) then
    begin
      // the entity is re-used if the models are different
      if FContext.ItemConfig.Info(LItem.ItemInfo).ModelIndex <> AModelIndex then
      begin
        // remove this level item
        FContext.LevelItems.RemoveFromList(LCurrent);
        FContext.LevelItems.Release(LCurrent);
        Exit;
      end;
      if not SameOrigin(AInfo.Origin, LItem.Origin) then
        MoveItem(LItem, AInfo);
      Exit(True);
    end;
    LCurrent := LItem.Next;
  end;
end;

function TBotEntityItemUpdater.LinkToLevelItem(const AEntity, AModelIndex: Integer;
  const AInfo: TAasEntityInfo): Boolean;
var
  LCurrent: Integer;
  LItem: PBotLevelItem;
  LDirection: TVec3;
begin
  Result := False;
  LCurrent := FContext.LevelItems.Head;
  while LCurrent <> TBotLevelItems.NoItem do
  begin
    LItem := FContext.LevelItems.Item(LCurrent);
    LCurrent := LItem.Next;
    // if this level item is already linked
    if LItem.EntityNum <> 0 then
      Continue;
    if not ItemAllowed(LItem) then
      Continue;
    // if the model of the level item and the entity are the same
    if FContext.ItemConfig.Info(LItem.ItemInfo).ModelIndex = AModelIndex then
    begin
      // check if the entity is very close
      TAasVectorMath.Subtract(LItem.Origin, AInfo.Origin, LDirection);
      if TAasVectorMath.Length(LDirection) < LINK_DISTANCE then
      begin
        // found an entity for this level item
        LItem.EntityNum := AEntity;
        // if the origin is different
        if not SameOrigin(AInfo.Origin, LItem.Origin) then
          MoveItem(LItem, AInfo);
        Exit(True);
      end;
    end;
  end;
end;

procedure TBotEntityItemUpdater.AddNewItem(const AEntity, AModelIndex: Integer; const AInfo: TAasEntityInfo);
var
  LConfig: TBotItemConfig;
  LIndex: Integer;
  LItem: Integer;
  LLevelItem: PBotLevelItem;
  LItemInfo: TBotItemInfo;
begin
  LConfig := FContext.ItemConfig;
  // check if the model is from a known item
  LIndex := 0;
  while (LIndex < LConfig.Count) and (LConfig.Info(LIndex).ModelIndex <> AModelIndex) do
    Inc(LIndex);
  // if the model is not from a known item
  if LIndex >= LConfig.Count then
    Exit;
  // allocate a new level item
  LItem := FContext.LevelItems.Alloc;
  if LItem = TBotLevelItems.NoItem then
    Exit;
  LLevelItem := FContext.LevelItems.Item(LItem);
  // entity number of the level item
  LLevelItem.EntityNum := AEntity;
  // number for the level item
  LLevelItem.Number := FContext.NumLevelItems + AEntity;
  // set the item info index for the level item
  LLevelItem.ItemInfo := LIndex;
  // origin of the item
  LLevelItem.Origin := AInfo.Origin;
  // get the item goal area and goal origin
  LItemInfo := LConfig.Info(LIndex);
  LLevelItem.GoalAreaNum := FWorld.BestReachable.BestReachableArea(LLevelItem.Origin, LItemInfo.Mins,
    LItemInfo.Maxs, LLevelItem.GoalOrigin);
  // never go for items dropped into jumppads
  if FWorld.Areas.AreaJumpPad(LLevelItem.GoalAreaNum) then
  begin
    FContext.LevelItems.Release(LItem);
    Exit;
  end;
  // time this item out after 30 seconds: dropped items disappear after 30 seconds
  LLevelItem.Timeout := FWorld.Time + DROPPED_ITEM_TIME;
  // add the level item to the list
  FContext.LevelItems.AddToList(LItem);
end;

procedure TBotEntityItemUpdater.HandleEntity(const AEntity: Integer);
var
  LModelIndex: Integer;
  LInfo: TAasEntityInfo;
begin
  if FWorld.Entities.EntityType(AEntity) <> ET_ITEM then
    Exit;
  // get the model index of the entity
  LModelIndex := FWorld.Entities.EntityModelIndex(AEntity);
  if LModelIndex = 0 then
    Exit;
  // get info about the entity
  LInfo := FWorld.Entities.EntityInfo(AEntity);
  // if the entity is still moving
  if not SameOrigin(LInfo.Origin, LInfo.LastVisOrigin) then
    Exit;
  // check if the entity is already stored as a level item
  if FindStoredItem(AEntity, LModelIndex, LInfo) then
    Exit;
  // try to link the entity to a level item
  if LinkToLevelItem(AEntity, LModelIndex, LInfo) then
    Exit;
  AddNewItem(AEntity, LModelIndex, LInfo);
end;

procedure TBotEntityItemUpdater.Update;
var
  LEntity: Integer;
begin
  RemoveTimedOut;
  // find new entity items
  if not Assigned(FContext.ItemConfig) then
    Exit;
  LEntity := FWorld.Entities.NextEntity(0);
  while LEntity <> 0 do
  begin
    HandleEntity(LEntity);
    LEntity := FWorld.Entities.NextEntity(LEntity);
  end;
end;

end.
