{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - reaction fire (TileEngine::           }
{  checkReactionFire, getSpottingUnits, getReactor, determineReactionType,      }
{  tryReaction)                                                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.ReactionFire;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Game.Intf, DelphiDoom.XcomBattle.BattlescapeGame, DelphiDoom.XcomBattle.AIThinker;

type
  /// <summary>
  ///   Asks whether the player has researched what an item needs (SavedGame::isResearched): the soldiers of the
  ///   player can only react with what the player knows
  /// </summary>
  TXcomResearchCheck = reference to function(const ARequirements: TArray<string>): Boolean;

  /// <summary>
  ///   When a unit of the side that plays moves, turns or shoots, the units of the other side that see it
  ///   may react with a snap shot (or a hit): the one with the best reaction score first, until the moving unit
  ///   has the best score. The shots are ProjectileFlyBState steps pushed in the game
  /// </summary>
  TXcomReactionFire = class(TInterfacedObject, IXcomReactionFire)
  strict private
  type
    TSpotter = record
      SpottingUnit: TXcomBattleUnit;
      AttackType: Integer;
    end;
  strict private
    FGame: IXcomBattlescapeGame;
    FThinker: TXcomAIThinker;
    FResearch: TXcomResearchCheck;
    function GetSpottingUnits(const AUnit: TXcomBattleUnit): TList<TSpotter>;
    function GetReactor(const ASpotters: TList<TSpotter>; out AAttackType: Integer; const AUnit: TXcomBattleUnit)
      : TXcomBattleUnit;
    function DetermineReactionType(const AUnit, ATarget: TXcomBattleUnit): Integer;
    function TryReaction(const AUnit, ATarget: TXcomBattleUnit; AAttackType: Integer): Boolean;
    function IsResearched(const AUnit: TXcomBattleUnit; const AItem: TXcomBattleItem): Boolean;
  public
    /// <param name="AThinker">The AI that tells whether an explosive reaction is worth it (not owned)</param>
    /// <param name="AResearch">The research check of the saved game, or nil (everything is researched)</param>
    constructor Create(const AGame: IXcomBattlescapeGame; const AThinker: TXcomAIThinker;
      const AResearch: TXcomResearchCheck = nil);
    /// <summary>checkReactionFire: true when a unit reacted</summary>
    function Check(const AUnit: TXcomBattleUnit): Boolean;
    /// <summary>The research check of a player who has discovered the researches with these names</summary>
    class function ResearchOf(const ADiscovered: TArray<string>): TXcomResearchCheck; static;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.TileEngine,
  DelphiDoom.XcomBattle.AIModule, DelphiDoom.XcomBattle.ProjectileFlyState, DelphiDoom.XcomBattle.MeleeAttackState;

const
  /// <summary>TileEngine::MAX_VIEW_DISTANCE_SQR (20 tiles)</summary>
  MAX_VIEW_DISTANCE_SQR = 20 * 20;

constructor TXcomReactionFire.Create(const AGame: IXcomBattlescapeGame; const AThinker: TXcomAIThinker;
  const AResearch: TXcomResearchCheck);
begin
  inherited Create;
  FGame := AGame;
  FThinker := AThinker;
  FResearch := AResearch;
end;

class function TXcomReactionFire.ResearchOf(const ADiscovered: TArray<string>): TXcomResearchCheck;
begin
  Result :=
    function(const ARequirements: TArray<string>): Boolean
    var
      LRequirement: string;
      LName: string;
      LFound: Boolean;
    begin
      for LRequirement in ARequirements do
      begin
        LFound := False;
        for LName in ADiscovered do
          if LName = LRequirement then
          begin
            LFound := True;
            Break;
          end;
        if not LFound then
          Exit(False);
      end;
      Result := True;
    end;
end;

function TXcomReactionFire.IsResearched(const AUnit: TXcomBattleUnit; const AItem: TXcomBattleItem): Boolean;
begin
  Result := (AUnit.OriginalFaction <> FACTION_PLAYER) or (not Assigned(FResearch)) or
    FResearch(AItem.Rules.Requirements);
end;

function TXcomReactionFire.Check(const AUnit: TXcomBattleUnit): Boolean;
var
  LSpotters: TList<TSpotter>;
  LReactor: TXcomBattleUnit;
  LAttackType: Integer;
  LIndex: Integer;
begin
  Result := False;
  // reaction fire only triggered when the actioning unit is of the currently playing side, and is still on the map (alive)
  if (AUnit.Faction <> FGame.Save.Side) or (not Assigned(AUnit.Tile)) then
    Exit;
  LSpotters := GetSpottingUnits(AUnit);
  try
    // not mind controlled, or controlled by the player
    if (AUnit.Faction = AUnit.OriginalFaction) or (AUnit.Faction <> FACTION_HOSTILE) then
    begin
      // get the first man up to bat.
      LReactor := GetReactor(LSpotters, LAttackType, AUnit);
      // start iterating through the possible reactors until the current unit is the one with the highest score.
      while LReactor <> AUnit do
      begin
        if not TryReaction(LReactor, AUnit, LAttackType) then
        begin
          // can't make a reaction snapshot for whatever reason, boot this guy from the vector.
          for LIndex := 0 to LSpotters.Count - 1 do
            if LSpotters[LIndex].SpottingUnit = LReactor then
            begin
              LSpotters.Delete(LIndex);
              Break;
            end;
          // avoid setting result to true, but carry on
          LReactor := GetReactor(LSpotters, LAttackType, AUnit);
          Continue;
        end;
        // nice shot, kid. don't get cocky.
        LReactor := GetReactor(LSpotters, LAttackType, AUnit);
        Result := True;
      end;
    end;
  finally
    LSpotters.Free;
  end;
end;

function TXcomReactionFire.GetSpottingUnits(const AUnit: TXcomBattleUnit): TList<TSpotter>;
var
  LTile: TXcomTile;
  LCandidate: TXcomBattleUnit;
  LFalseAction: TXcomBattleAction;
  LOriginVoxel: TXcomPosition;
  LTargetVoxel: TXcomPosition;
  LGotHit: Boolean;
  LAttackType: Integer;
  LSpotter: TSpotter;
begin
  Result := TList<TSpotter>.Create;
  LTile := AUnit.Tile;
  // no reaction on civilian turn.
  if FGame.Save.Side = FACTION_NEUTRAL then
    Exit;
  for LCandidate in FGame.Save.Units do
    if (not LCandidate.IsOut) and (LCandidate.Health <> 0) and (LCandidate.StunLevel < LCandidate.Health) and
      (LCandidate.Faction <> FGame.Save.Side) and (LCandidate.Faction <> FACTION_NEUTRAL) and
      (FGame.TileEngine.DistanceSq(AUnit.Position, LCandidate.Position) <= MAX_VIEW_DISTANCE_SQR) then
    begin
      LFalseAction := TXcomBattleAction.Create;
      try
        LFalseAction.ActionType := BA_SNAPSHOT;
        LFalseAction.Actor := LCandidate;
        LFalseAction.Target := AUnit.Position;
        LOriginVoxel := FGame.TileEngine.GetOriginVoxel(LFalseAction, nil);
      finally
        LFalseAction.Free;
      end;
      // the flag of a unit with an AI is the list of the units that hit it, the one of the others the hit state
      if Assigned(LCandidate.AI) then
        LGotHit := (LCandidate.AI as TXcomAIModule).GetWasHitBy(AUnit.Id)
      else
        LGotHit := LCandidate.HitState;
      // can actually see the target Tile, or we got hit
      if (LCandidate.CheckViewSector(AUnit.Position) or LGotHit) and
        // can actually target the unit
        FGame.TileEngine.CanTargetUnit(LOriginVoxel, LTile, LTargetVoxel, LCandidate, False) and
        // can actually see the unit
        FGame.TileEngine.Visible(LCandidate, LTile) then
      begin
        if LCandidate.Faction = FACTION_PLAYER then
          AUnit.Visible := True;
        LCandidate.AddToVisibleUnits(AUnit);
        LAttackType := DetermineReactionType(LCandidate, AUnit);
        if LAttackType <> BA_NONE then
        begin
          LSpotter.SpottingUnit := LCandidate;
          LSpotter.AttackType := LAttackType;
          Result.Add(LSpotter);
        end;
      end;
    end;
end;

function TXcomReactionFire.GetReactor(const ASpotters: TList<TSpotter>; out AAttackType: Integer;
  const AUnit: TXcomBattleUnit): TXcomBattleUnit;
var
  LBestScore: Integer;
  LSpotter: TSpotter;
begin
  LBestScore := -1;
  Result := nil;
  AAttackType := BA_NONE;
  for LSpotter in ASpotters do
    if (not LSpotter.SpottingUnit.IsOut) and (not LSpotter.SpottingUnit.Respawn) and
      (DetermineReactionType(LSpotter.SpottingUnit, AUnit) <> BA_NONE) and
      (LSpotter.SpottingUnit.GetReactionScore > LBestScore) then
    begin
      LBestScore := Trunc(LSpotter.SpottingUnit.GetReactionScore);
      Result := LSpotter.SpottingUnit;
      AAttackType := LSpotter.AttackType;
    end;
  if AUnit.GetReactionScore <= LBestScore then
  begin
    if Result.OriginalFaction = FACTION_PLAYER then
      Result.AddReactionExp;
  end
  else
  begin
    Result := AUnit;
    AAttackType := BA_NONE;
  end;
end;

function TXcomReactionFire.DetermineReactionType(const AUnit, ATarget: TXcomBattleUnit): Integer;
var
  LMelee: TXcomBattleItem;
  LWeapon: TXcomBattleItem;
begin
  // prioritize melee
  LMelee := AUnit.GetMeleeWeapon;
  if Assigned(LMelee) and
    // has a melee weapon and is in melee range
    FGame.TileEngine.ValidMeleeRange(AUnit, ATarget, AUnit.Direction) and
    (AUnit.GetActionTus(BA_HIT, LMelee) > 0) and (AUnit.TimeUnits > AUnit.GetActionTus(BA_HIT, LMelee)) and
    IsResearched(AUnit, LMelee) and FGame.Save.IsItemUsable(LMelee) then
    Exit(BA_HIT);
  LWeapon := AUnit.GetMainHandWeapon(AUnit.Faction <> FACTION_PLAYER);
  // has a weapon
  if Assigned(LWeapon) and
    // has a gun capable of snap shot with ammo
    ((LWeapon.Rules.BattleType <> TXcomRuleItem.BT_MELEE) and (LWeapon.Rules.TimeUnitsSnap <> 0) and
    (FGame.TileEngine.DistanceSq(AUnit.Position, ATarget.Position, False) < LWeapon.Rules.MaxRangeSquared) and
    Assigned(LWeapon.AmmoItem) and (AUnit.GetActionTus(BA_SNAPSHOT, LWeapon) > 0) and
    (AUnit.TimeUnits > AUnit.GetActionTus(BA_SNAPSHOT, LWeapon))) and IsResearched(AUnit, LWeapon) and
    FGame.Save.IsItemUsable(LWeapon) then
    Exit(BA_SNAPSHOT);
  Result := BA_NONE;
end;

function TXcomReactionFire.TryReaction(const AUnit, ATarget: TXcomBattleUnit; AAttackType: Integer): Boolean;
var
  LAction: TXcomBattleAction;
begin
  Result := False;
  LAction := TXcomBattleAction.Create;
  try
    LAction.Actor := AUnit;
    if AAttackType = BA_HIT then
      LAction.Weapon := AUnit.GetMeleeWeapon
    else
      LAction.Weapon := AUnit.GetMainHandWeapon(AUnit.Faction <> FACTION_PLAYER);
    if not Assigned(LAction.Weapon) then
      Exit;
    LAction.ActionType := AAttackType;
    LAction.Target := ATarget.Position;
    LAction.TimeUnits := AUnit.GetActionTus(LAction.ActionType, LAction.Weapon);
    if Assigned(LAction.Weapon.AmmoItem) and (LAction.Weapon.AmmoItem.AmmoQuantity <> 0) and
      (AUnit.TimeUnits >= LAction.TimeUnits) then
    begin
      LAction.Targeting := True;
      // hostile units will go into an "aggro" state when they react.
      if AUnit.Faction = FACTION_HOSTILE then
        if (LAction.ActionType <> BA_HIT) and (LAction.Weapon.AmmoItem.Rules.ExplosionRadius <> 0) and
          (not FThinker.WorthExploding(LAction.Target, AUnit, LAction.Weapon.AmmoItem.Rules.ExplosionRadius, -1)) then
          LAction.Targeting := False;
      if LAction.Targeting and AUnit.SpendTimeUnits(LAction.TimeUnits) then
      begin
        LAction.TimeUnits := 0;
        if LAction.ActionType = BA_HIT then
          FGame.StatePushBack(TXcomMeleeAttackState.Create(FGame, LAction))
        else
          FGame.StatePushBack(TXcomProjectileFlyState.Create(FGame, LAction));
        Result := True;
      end;
    end;
  finally
    LAction.Free;
  end;
end;

end.
