{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - an alien that picks up what lies      }
{  on the floor (BattlescapeGame::findItem, surveyItems, worthTaking,           }
{  takeItemFromGround, takeItem)                                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.ItemScavenger;

interface

uses
  System.SysUtils, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action,
  DelphiDoom.XcomBattle.Game.Intf;

type
  /// <summary>
  ///   The part of the turn of the AI in which a unit without a loaded weapon that sees nobody looks for the item
  ///   that was dropped on the alien turn and is most worth the walk, goes there and takes it
  /// </summary>
  TXcomItemScavenger = class
  strict private
    FGame: IXcomBattlescapeGame;
    function SurveyItems(const AAction: TXcomBattleAction): TXcomBattleItem;
    function WorthTaking(const AItem: TXcomBattleItem; const AAction: TXcomBattleAction): Boolean;
    function TakeItem(const AItem: TXcomBattleItem; const AAction: TXcomBattleAction): Boolean;
  public
    constructor Create(const AGame: IXcomBattlescapeGame);
    /// <summary>findItem: picks the best item (a walk action towards it, or takes it when it is underfoot)</summary>
    procedure FindItem(const AAction: TXcomBattleAction);
    /// <summary>
    ///   takeItemFromGround: 0 if successful, 1 for no time units, 2 for not enough room, 3 for "won't fit"
    /// </summary>
    function TakeItemFromGround(const AItem: TXcomBattleItem; const AAction: TXcomBattleAction): Integer;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.XcomMod.RuleItem;

constructor TXcomItemScavenger.Create(const AGame: IXcomBattlescapeGame);
begin
  inherited Create;
  FGame := AGame;
end;

procedure TXcomItemScavenger.FindItem(const AAction: TXcomBattleAction);
var
  LTarget: TXcomBattleItem;
begin
  // terrorists don't have hands
  if AAction.Actor.RankString = 'STR_LIVE_TERRORIST' then
    Exit;
  // pick the best available item and make sure it's worth taking
  LTarget := SurveyItems(AAction);
  if Assigned(LTarget) and WorthTaking(LTarget, AAction) then
  begin
    // if we're already standing on it, try to pick it up
    if LTarget.Tile.Position = AAction.Actor.Position then
    begin
      if TakeItemFromGround(LTarget, AAction) = 0 then
        // if it isn't loaded or it is ammo, try to load our weapon
        if not Assigned(LTarget.AmmoItem) then
          AAction.Actor.CheckAmmo;
    end
    else if (not Assigned(LTarget.Tile.CurrentUnit)) or LTarget.Tile.CurrentUnit.IsOut then
    begin
      // if we're not standing on it, we should try to get to it
      AAction.Target := LTarget.Tile.Position;
      AAction.ActionType := BA_WALK;
    end;
  end;
end;

function TXcomItemScavenger.SurveyItems(const AAction: TXcomBattleAction): TXcomBattleItem;
var
  LDropped: TList<TXcomBattleItem>;
  LItem: TXcomBattleItem;
  LMaxWorth: Integer;
  LWorth: Integer;
begin
  Result := nil;
  LDropped := TList<TXcomBattleItem>.Create;
  try
    // first fill a list with items on the ground that were dropped on the alien turn, and have an attraction value
    for LItem in FGame.Save.Items do
      if Assigned(LItem.Slot) and (LItem.Slot.Id = 'STR_GROUND') and Assigned(LItem.Tile) and LItem.TurnFlag and
        (LItem.Rules.Attraction <> 0) then
        LDropped.Add(LItem);
    // now select the most suitable candidate depending on attractiveness and distance
    LMaxWorth := 0;
    for LItem in LDropped do
    begin
      LWorth := LItem.Rules.Attraction div
        (FGame.TileEngine.Distance(AAction.Actor.Position, LItem.Tile.Position) * 2 + 1);
      if LWorth > LMaxWorth then
      begin
        LMaxWorth := LWorth;
        Result := LItem;
      end;
    end;
  finally
    LDropped.Free;
  end;
end;

function TXcomItemScavenger.WorthTaking(const AItem: TXcomBattleItem; const AAction: TXcomBattleAction): Boolean;
var
  LWorth: Integer;
  LAmmoFound: Boolean;
  LWeaponFound: Boolean;
  LOwned: TXcomBattleItem;
  LName: string;
  LFreeSlots: Integer;
begin
  LWorth := 0;
  // don't even think about making a move for that gun if you can see a target
  if AAction.Actor.VisibleUnits.Count = 0 then
  begin
    // retrieve an insignificantly low value from the ruleset
    LWorth := AItem.Rules.Attraction;
    // it's always going to be worth while to try and take a blaster launcher, apparently
    if (AItem.Rules.Waypoints = 0) and (AItem.Rules.BattleType <> TXcomRuleItem.BT_AMMO) then
    begin
      // we only want weapons that HAVE ammo, or weapons that we have ammo FOR
      LAmmoFound := True;
      if not Assigned(AItem.AmmoItem) then
      begin
        LAmmoFound := False;
        for LOwned in AAction.Actor.Inventory do
        begin
          if LAmmoFound then
            Break;
          if LOwned.Rules.BattleType = TXcomRuleItem.BT_AMMO then
            for LName in AItem.Rules.CompatibleAmmo do
              if LOwned.Rules.Name = LName then
              begin
                LAmmoFound := True;
                Break;
              end;
        end;
      end;
      if not LAmmoFound then
        Exit(False);
    end;
    if AItem.Rules.BattleType = TXcomRuleItem.BT_AMMO then
    begin
      // similar to the above, but this time we're checking if the ammo is suitable for a weapon we have
      LWeaponFound := False;
      for LOwned in AAction.Actor.Inventory do
      begin
        if LWeaponFound then
          Break;
        if LOwned.Rules.BattleType = TXcomRuleItem.BT_FIREARM then
          for LName in LOwned.Rules.CompatibleAmmo do
            if LOwned.Rules.Name = LName then
            begin
              LWeaponFound := True;
              Break;
            end;
      end;
      if not LWeaponFound then
        Exit(False);
    end;
  end;
  if LWorth <> 0 then
  begin
    // use bad logic to determine if we'll have room for the item
    LFreeSlots := 25;
    for LOwned in AAction.Actor.Inventory do
      Dec(LFreeSlots, LOwned.Rules.InventoryHeight * LOwned.Rules.InventoryWidth);
    if LFreeSlots < AItem.Rules.InventoryHeight * AItem.Rules.InventoryWidth then
      Exit(False);
  end;
  // false for any item that we aren't standing directly on top of with an attraction value less than 6 (always)
  Result := (LWorth - FGame.TileEngine.Distance(AAction.Actor.Position, AItem.Tile.Position) * 2) > 5;
end;

function TXcomItemScavenger.TakeItemFromGround(const AItem: TXcomBattleItem;
  const AAction: TXcomBattleAction): Integer;
const
  SUCCESS = 0;
  NOT_ENOUGH_TIME_UNITS = 1;
  NOT_ENOUGH_SPACE = 2;
  COULD_NOT_FIT = 3;
var
  LFreeSlots: Integer;
  LOwned: TXcomBattleItem;
begin
  LFreeSlots := 25;
  // make sure we have time units
  if AAction.Actor.TimeUnits < 6 then
    Exit(NOT_ENOUGH_TIME_UNITS);
  // check to make sure we have enough space by checking all the sizes of items in our inventory
  for LOwned in AAction.Actor.Inventory do
    Dec(LFreeSlots, LOwned.Rules.InventoryHeight * LOwned.Rules.InventoryWidth);
  if LFreeSlots < AItem.Rules.InventoryHeight * AItem.Rules.InventoryWidth then
    Exit(NOT_ENOUGH_SPACE);
  // check that the item will fit in our inventory, and if so, take it
  if TakeItem(AItem, AAction) then
  begin
    AAction.Actor.SpendTimeUnits(6);
    AItem.Tile.RemoveItem(AItem);
    Result := SUCCESS;
  end
  else
    Result := COULD_NOT_FIT;
end;

function TXcomItemScavenger.TakeItem(const AItem: TXcomBattleItem; const AAction: TXcomBattleAction): Boolean;
var
  LIndex: Integer;
  LRightHand: TXcomBattleItem;

  function PlaceInBelt: Boolean;
  var
    LSlot: Integer;
  begin
    for LSlot := 0 to 3 do
      if not Assigned(AAction.Actor.GetItem('STR_BELT', LSlot)) then
      begin
        AItem.MoveToOwner(AAction.Actor);
        AItem.Slot := FGame.Ruleset.Inventories.Find('STR_BELT');
        AItem.SlotX := LSlot;
        Exit(True);
      end;
    Result := False;
  end;

  function PlaceInSlot(const ASlot: string): Boolean;
  begin
    Result := not Assigned(AAction.Actor.GetItem(ASlot));
    if Result then
    begin
      AItem.MoveToOwner(AAction.Actor);
      AItem.Slot := FGame.Ruleset.Inventories.Find(ASlot);
    end;
  end;

begin
  Result := False;
  LIndex := AItem.Rules.BattleType;
  if LIndex = TXcomRuleItem.BT_AMMO then
  begin
    // find equipped weapons that can be loaded with this ammo
    LRightHand := AAction.Actor.GetItem('STR_RIGHT_HAND');
    if Assigned(LRightHand) and (not Assigned(LRightHand.AmmoItem)) then
      Result := LRightHand.SetAmmoItem(AItem) = 0
    else
      Result := PlaceInBelt;
  end
  else if (LIndex = TXcomRuleItem.BT_GRENADE) or (LIndex = TXcomRuleItem.BT_PROXIMITYGRENADE) then
    Result := PlaceInBelt
  else if (LIndex = TXcomRuleItem.BT_FIREARM) or (LIndex = TXcomRuleItem.BT_MELEE) then
    Result := PlaceInSlot('STR_RIGHT_HAND')
  else if (LIndex = TXcomRuleItem.BT_MEDIKIT) or (LIndex = TXcomRuleItem.BT_SCANNER) then
    Result := PlaceInSlot('STR_BACK_PACK')
  else if LIndex = TXcomRuleItem.BT_MINDPROBE then
    Result := PlaceInSlot('STR_LEFT_HAND');
end;

end.
