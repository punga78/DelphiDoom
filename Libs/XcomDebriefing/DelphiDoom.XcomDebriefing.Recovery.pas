{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - what the battle gives back to the base: }
{  the items and the live aliens (DebriefingState::recoverItems, recoverAlien)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.Recovery;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.BaseCapacity,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomDebriefing.Types;

type
  /// <summary>
  ///   Gives the objects of the battle to the stores of a base and writes what they are worth in the report: the
  ///   fuel of the aliens, the corpses, the artifacts that were not researched, the clips (counted in rounds, they are
  ///   turned into clips at the end) and the live aliens (they need a containment). The report, the saved game and
  ///   the ruleset are not owned
  /// </summary>
  TXcomMissionRecovery = class
  strict private
    FGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FReport: TXcomDebriefingReport;
    FCapacity: TXcomBaseCapacity;
    FOptions: TXcomDebriefingOptions;
    FZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>;
    procedure CountRounds(const AItem: TXcomBattleItem);
  public
    /// <param name="AZombieConverter">
    ///   SavedBattleGame::convertUnit for the zombie that psi-capture could take: it gives the new unit; nil if the
    ///   caller has none (a zombie then is an error)
    /// </param>
    constructor Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
      const AReport: TXcomDebriefingReport; const ACapacity: TXcomBaseCapacity; const AOptions: TXcomDebriefingOptions;
      const AZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>);
    /// <summary>recoverItems: converts the inventory of the battle into the stores of the base</summary>
    procedure RecoverItems(const AItems: TList<TXcomBattleItem>; const ABase: TXcomBase);
    /// <summary>recoverAlien: a live alien goes to the containment, or it dies for lack of one</summary>
    procedure RecoverAlien(const AUnit: TXcomBattleUnit; const ABase: TXcomBase);
    /// <summary>The clips that the rounds left in the recovered clips make go to the stores</summary>
    procedure StoreClips(const ABase: TXcomBase);
  end;

  /// <summary>The zombie of psi-capture cannot be converted: the caller gave no converter</summary>
  EXcomDebriefingException = class(Exception);

implementation

const
  SNoZombieConverter = 'Xcom: a zombie was recovered and the debriefing has no converter of units';

{ TXcomMissionRecovery }

constructor TXcomMissionRecovery.Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
  const AReport: TXcomDebriefingReport; const ACapacity: TXcomBaseCapacity; const AOptions: TXcomDebriefingOptions;
  const AZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>);
begin
  inherited Create;
  FGame := AGame;
  FRuleset := ARuleset;
  FReport := AReport;
  FCapacity := ACapacity;
  FOptions := AOptions;
  FZombieConverter := AZombieConverter;
end;

procedure TXcomMissionRecovery.CountRounds(const AItem: TXcomBattleItem);
var
  LRounds: Integer;
  LClip: TXcomBattleItem;
begin
  case AItem.Rules.BattleType of
    TXcomRuleItem.BT_CORPSE:
      ;
    TXcomRuleItem.BT_AMMO:
      begin
        // a clip: the rounds that are left
        FReport.Rounds.TryGetValue(AItem.Rules.ItemType, LRounds);
        FReport.Rounds.AddOrSetValue(AItem.Rules.ItemType, LRounds + AItem.AmmoQuantity);
      end;
    TXcomRuleItem.BT_FIREARM, TXcomRuleItem.BT_MELEE:
      begin
        // a weapon: the rounds of its clip, and then the weapon itself
        LClip := AItem.AmmoItem;
        if Assigned(LClip) and (LClip.Rules.ClipSize > 0) and (LClip <> AItem) then
        begin
          FReport.Rounds.TryGetValue(LClip.Rules.ItemType, LRounds);
          FReport.Rounds.AddOrSetValue(LClip.Rules.ItemType, LRounds + LClip.AmmoQuantity);
        end;
      end;
  end;
end;

procedure TXcomMissionRecovery.RecoverItems(const AItems: TList<TXcomBattleItem>; const ABase: TXcomBase);
var
  LItem: TXcomBattleItem;
  LCorpseUnit: TXcomBattleUnit;
  LCraft: TXcomCraft;
begin
  for LItem in AItems.ToArray do
  begin
    if LItem.Rules.ItemType = FRuleset.Settings.AlienFuelName then
      // a special case of an item that is counted as a statistic
      FReport.AddStat(FRuleset.Settings.AlienFuelName, FRuleset.Settings.AlienFuelQuantity, LItem.Rules.RecoveryPoints)
    else
    begin
      if LItem.Rules.Recoverable and (not LItem.XcomProperty) then
      begin
        if LItem.Rules.BattleType = TXcomRuleItem.BT_CORPSE then
        begin
          LCorpseUnit := LItem.CorpseUnit;
          if LCorpseUnit.Status = STATUS_DEAD then
          begin
            ABase.StorageItems.AddItem(LCorpseUnit.Armor.CorpseGeoscape, 1);
            FReport.AddStat('STR_ALIEN_CORPSES_RECOVERED', 1, LItem.Rules.RecoveryPoints);
          end
          // or it is in timeout because it is unconscious from the previous stage: units can be in timeout and
          // alive, and they flee
          else if (LCorpseUnit.Status = STATUS_UNCONSCIOUS) or ((LCorpseUnit.Status = STATUS_IGNORE_ME) and
            (LCorpseUnit.Health > 0) and (LCorpseUnit.Health < LCorpseUnit.StunLevel)) then
          begin
            if LCorpseUnit.OriginalFaction = FACTION_HOSTILE then
              RecoverAlien(LCorpseUnit, ABase);
          end;
        end
        // only the unresearched items give points
        else if not FGame.IsResearched(LItem.Rules.Requirements) then
          FReport.AddStat('STR_ALIEN_ARTIFACTS_RECOVERED', 1, LItem.Rules.RecoveryPoints);
      end;
      // the items go back to the base
      if (not LItem.Rules.FixedWeapon) and LItem.Rules.Recoverable then
      begin
        CountRounds(LItem);
        if LItem.Rules.BattleType <> TXcomRuleItem.BT_CORPSE then
          if LItem.Rules.BattleType <> TXcomRuleItem.BT_AMMO then
            ABase.StorageItems.AddItem(LItem.Rules.ItemType, 1);
        if LItem.Rules.BattleType = TXcomRuleItem.BT_NONE then
          for LCraft in ABase.Crafts do
            LCraft.ReuseItem(LItem.Rules.ItemType, FRuleset);
      end;
    end;
  end;
end;

procedure TXcomMissionRecovery.RecoverAlien(const AUnit: TXcomBattleUnit; const ABase: TXcomBase);
var
  LNewUnit: TXcomBattleUnit;
  LCorpseRule: TXcomRuleItem;
  LType: string;
begin
  // a zombie is not recovered: it is converted and mind controlled (psi-capture)
  if AUnit.SpawnUnit <> '' then
  begin
    if not Assigned(FZombieConverter) then
      raise EXcomDebriefingException.Create(SNoZombieConverter);
    LNewUnit := FZombieConverter(AUnit);
    LNewUnit.ConvertToFaction(FACTION_PLAYER);
    Exit;
  end;
  LType := AUnit.UnitType;
  if (FCapacity.AvailableContainment(ABase) = 0) and (FGame.MonthsPassed > -1) then
  begin
    FReport.NoContainment := True;
    if Length(AUnit.Armor.CorpseBattlescape) > 0 then
    begin
      LCorpseRule := FRuleset.Items.Find(AUnit.Armor.CorpseBattlescape[0]);
      if Assigned(LCorpseRule) and LCorpseRule.Recoverable then
      begin
        FReport.AddStat('STR_ALIEN_CORPSES_RECOVERED', 1, LCorpseRule.RecoveryPoints);
        ABase.StorageItems.AddItem(AUnit.Armor.CorpseGeoscape, 1);
      end;
    end;
  end
  else
  begin
    // more points if the alien is not researched
    if Assigned(FRuleset.Research.Find(LType)) and (not FGame.IsResearched(LType)) then
      FReport.AddStat('STR_LIVE_ALIENS_RECOVERED', 1, AUnit.Value * 2)
    else
      // 10 points for recovery
      FReport.AddStat('STR_LIVE_ALIENS_RECOVERED', 1, 10);
    ABase.StorageItems.AddItem(LType, 1);
    FReport.ManageContainment := FCapacity.AvailableContainment(ABase) -
      (FCapacity.UsedContainment(ABase) * Ord(FOptions.StorageLimitsEnforced)) < 0;
  end;
end;

procedure TXcomMissionRecovery.StoreClips(const ABase: TXcomBase);
var
  LPair: TPair<string, Integer>;
  LClips: Integer;
  LRules: TXcomRuleItem;
  LNames: TArray<string>;
  LName: string;
  LRounds: Integer;
begin
  // the order of the clips does not change the stores (a map by name)
  LNames := FReport.Rounds.Keys.ToArray;
  for LName in LNames do
  begin
    LRounds := FReport.Rounds[LName];
    LRules := FRuleset.Items.Find(LName);
    if Assigned(LRules) and (LRules.ClipSize > 0) then
    begin
      LClips := LRounds div LRules.ClipSize;
      if LClips > 0 then
        ABase.StorageItems.AddItem(LRules.ItemType, LClips);
    end;
  end;
end;

end.
