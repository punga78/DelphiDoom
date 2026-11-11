{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a unit that dies or falls            }
{  unconscious (UnitDieBState)                                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.UnitDieState;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action,
  DelphiDoom.XcomBattle.State.Intf, DelphiDoom.XcomBattle.Game.Intf;

type
  /// <summary>
  ///   The step of a unit that dies or is knocked out: the pirouette, the fall, the sound, the corpse or the zombie
  ///   that replaces it, the items that drop (UnitDieBState)
  /// </summary>
  TXcomUnitDieState = class(TInterfacedObject, IXcomBattleState)
  strict private
    FGame: IXcomBattlescapeGame;
    FUnit: TXcomBattleUnit;
    FDamageType: Integer;
    FNoSound: Boolean;
    FNoCorpse: Boolean;
    FExtraFrame: Integer;
    procedure ConvertUnitToCorpse;
    procedure PlayDeathSound;
  public
    /// <param name="ADamageType">The kind of damage (DT_*): HE and unconsciousness skip the pirouette</param>
    constructor Create(const AGame: IXcomBattlescapeGame; const AUnit: TXcomBattleUnit; ADamageType: Integer;
      ANoSound, ANoCorpse: Boolean);
    procedure Init;
    procedure Think;
    procedure Cancel;
    procedure Deinit;
    function StateName: string;
    function Action: TXcomBattleAction;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.Node;

constructor TXcomUnitDieState.Create(const AGame: IXcomBattlescapeGame; const AUnit: TXcomBattleUnit;
  ADamageType: Integer; ANoSound, ANoCorpse: Boolean);
var
  LNode: TXcomNode;
begin
  inherited Create;
  FGame := AGame;
  FUnit := AUnit;
  FDamageType := ADamageType;
  FNoSound := ANoSound;
  FNoCorpse := ANoCorpse;
  FExtraFrame := 0;
  // don't show the "fall to death" animation when a unit is blasted with explosives or he is already unconscious
  if (FDamageType = TXcomRuleItem.DT_HE) or (FUnit.Status = STATUS_UNCONSCIOUS) then
  begin
    // any unit that is going to skip its death pirouette must have its direction set to 3 first
    FUnit.SetDirection(3);
    FUnit.StartFalling;
    while FUnit.Status = STATUS_COLLAPSING do
      FUnit.KeepFalling;
    if FGame.Save.BeforeGame then
    begin
      if not FNoCorpse then
        ConvertUnitToCorpse;
      FExtraFrame := 3; // shortcut to popState()
    end;
  end
  else
  begin
    if FUnit.Faction = FACTION_PLAYER then
      FGame.View.SetUnitDying(True);
    FGame.View.SetStateInterval(100);
    if FUnit.Direction <> 3 then
      FGame.View.SetStateInterval(33);
  end;
  FUnit.ClearVisibleTiles;
  FUnit.ClearVisibleUnits;
  FUnit.FreePatrolTarget;
  if (not FGame.Save.BeforeGame) and (FUnit.Faction = FACTION_HOSTILE) then
    for LNode in FGame.Save.Nodes do
      if (not LNode.Dummy) and (FGame.TileEngine.DistanceSq(LNode.Position, FUnit.Position) < 4) then
        LNode.NodeType := LNode.NodeType or NODE_TYPE_DANGEROUS;
end;

function TXcomUnitDieState.Action: TXcomBattleAction;
begin
  Result := nil;
end;

procedure TXcomUnitDieState.Init;
begin
  // check for presence of battlestate to ensure that we're not pre-battle
  // check for the unit's tile to make sure we're not trying to kill a dead guy
  if (not FGame.Save.BeforeGame) and (not Assigned(FUnit.Tile)) then
    FGame.PopState;
end;

procedure TXcomUnitDieState.Think;
var
  LDirection: Integer;
begin
  if FExtraFrame = 3 then
  begin
    FGame.PopState;
    Exit;
  end;
  if (FUnit.Direction <> 3) and (FDamageType <> TXcomRuleItem.DT_HE) then
  begin
    LDirection := FUnit.Direction + 1;
    if LDirection = 8 then
      LDirection := 0;
    FUnit.LookAt(LDirection);
    FUnit.Turn;
    if LDirection = 3 then
      FGame.View.SetStateInterval(100);
  end
  else if FUnit.Status = STATUS_COLLAPSING then
    FUnit.KeepFalling
  else if not FUnit.IsOut then
  begin
    FUnit.StartFalling;
    if not FNoSound then
      PlayDeathSound;
    if FUnit.Respawn then
      while FUnit.Status = STATUS_COLLAPSING do
        FUnit.KeepFalling;
  end;
  if FExtraFrame = 2 then
  begin
    FGame.View.SetUnitDying(False);
    FGame.TileEngine.CalculateUnitLighting;
    FGame.PopState;
    if FUnit.OriginalFaction = FACTION_PLAYER then
    begin
      if FUnit.Status = STATUS_DEAD then
      begin
        if (FDamageType = TXcomRuleItem.DT_NONE) and (FUnit.SpawnUnit = '') then
          FGame.View.ShowUnitMessage(FUnit, 'STR_HAS_DIED_FROM_A_FATAL_WOUND', True)
        else if FGame.Options.BattleNotifyDeath and Assigned(FUnit.GeoscapeSoldier) then
          FGame.View.ShowUnitMessage(FUnit, 'STR_HAS_BEEN_KILLED', False);
      end
      else
        FGame.View.ShowUnitMessage(FUnit, 'STR_HAS_BECOME_UNCONSCIOUS', True);
    end;
    // if all units from either faction are killed - auto-end the mission.
    if FGame.Save.Side = FACTION_PLAYER then
      FGame.AutoEndBattle;
  end
  else if FExtraFrame = 1 then
    Inc(FExtraFrame)
  else if FUnit.IsOut then
  begin
    FExtraFrame := 1;
    if (not FNoSound) and (FDamageType = TXcomRuleItem.DT_HE) and (FUnit.Status <> STATUS_UNCONSCIOUS) then
      PlayDeathSound;
    if (FUnit.Status = STATUS_UNCONSCIOUS) and (not FUnit.Capturable) then
      FUnit.InstaKill;
    if FUnit.TurnsSinceSpotted < 255 then
      FUnit.TurnsSinceSpotted := 255;
    if FUnit.SpawnUnit <> '' then
      // converts the dead zombie to a chryssalid
      FGame.ConvertUnit(FUnit)
    else if not FNoCorpse then
      ConvertUnitToCorpse;
    if FUnit = FGame.Save.SelectedUnit then
      FGame.Save.SelectedUnit := nil;
  end;
  FGame.View.CacheUnit(FUnit);
end;

procedure TXcomUnitDieState.Cancel;
begin
end;

procedure TXcomUnitDieState.Deinit;
begin
end;

function TXcomUnitDieState.StateName: string;
begin
  Result := 'UnitDieBState';
end;

procedure TXcomUnitDieState.ConvertUnitToCorpse;
var
  LLastPosition: TXcomPosition;
  LSize: Integer;
  LDropItems: Boolean;
  LKeep: TArray<TXcomBattleItem>;
  LItem: TXcomBattleItem;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LCorpse: TXcomBattleItem;
  LRules: TXcomRuleItem;
  LId: Integer;
  LCorpseTile: TXcomTile;
begin
  LLastPosition := FUnit.Position;
  LSize := FUnit.Armor.Size;
  LDropItems := FUnit.HasInventory and ((not FGame.Options.WeaponSelfDestruction) or
    (FUnit.OriginalFaction <> FACTION_HOSTILE) or (FUnit.Status = STATUS_UNCONSCIOUS));
  if not FNoSound then
    FGame.View.ShowPsiButton(False);
  // remove the unconscious body item corresponding to this unit, and if it was being carried, keep track of what slot it was in
  if not ((LLastPosition.X = -1) and (LLastPosition.Y = -1) and (LLastPosition.Z = -1)) then
    FGame.Save.RemoveUnconsciousBodyItem(FUnit);
  // move inventory from unit to the ground
  if LDropItems then
  begin
    LKeep := nil;
    // DropItem does not change the inventory of the unit (the item is not removed from its owner)
    for LItem in FUnit.Inventory.ToArray do
    begin
      FGame.DropItem(LLastPosition, LItem);
      if not LItem.Rules.FixedWeapon then
        LItem.SetOwner(nil)
      else
        LKeep := LKeep + [LItem];
    end;
    FUnit.Inventory.Clear;
    for LItem in LKeep do
      FUnit.Inventory.Add(LItem);
  end;
  // remove unit-tile link
  FUnit.SetTile(nil);
  if (LLastPosition.X = -1) and (LLastPosition.Y = -1) and (LLastPosition.Z = -1) then
  begin
    // we're being carried: replace the unconscious body item with a corpse in the carrying unit's inventory
    for LItem in FGame.Save.Items.ToArray do
      if LItem.CorpseUnit = FUnit then
      begin
        // we're in an inventory, so we must be a 1x1 unit
        LRules := FGame.Ruleset.Items.Find(FUnit.Armor.CorpseBattlescape[0]);
        LItem.ConvertToCorpse(LRules);
        Break;
      end;
  end
  else
  begin
    LIndex := LSize * LSize - 1;
    for LY := LSize - 1 downto 0 do
      for LX := LSize - 1 downto 0 do
      begin
        LId := FGame.Save.CurrentItemId;
        LCorpse := TXcomBattleItem.Create(FGame.Ruleset.Items.Find(FUnit.Armor.CorpseBattlescape[LIndex]), LId);
        FGame.Save.CurrentItemId := LId;
        LCorpse.CorpseUnit := FUnit;
        // check in case unit was displaced by another unit
        LCorpseTile := FGame.Save.TileAt(LLastPosition + TXcomPosition.Make(LX, LY, 0));
        if LCorpseTile.CurrentUnit = FUnit then
          LCorpseTile.SetUnit(nil);
        FGame.DropItem(LLastPosition + TXcomPosition.Make(LX, LY, 0), LCorpse, True);
        Dec(LIndex);
      end;
  end;
end;

procedure TXcomUnitDieState.PlayDeathSound;
var
  LSounds: TArray<Integer>;
  LIndex: Integer;
begin
  LSounds := FUnit.DeathSounds;
  if Length(LSounds) > 0 then
  begin
    LIndex := LSounds[FGame.Save.Random.Generate(0, Length(LSounds) - 1)];
    if LIndex >= 0 then
      FGame.View.PlaySound(LIndex, FUnit.Position);
  end;
end;

end.
