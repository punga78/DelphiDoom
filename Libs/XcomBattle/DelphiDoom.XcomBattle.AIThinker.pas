{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - how the AI of an alien or a civilian  }
{  thinks (AIModule::think and the behaviours: patrol, ambush, attack, escape)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.AIThinker;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.Node, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.Action,
  DelphiDoom.XcomBattle.AIModule, DelphiDoom.XcomBattle.Directions, DelphiDoom.XcomBattle.TileEngine,
  DelphiDoom.XcomBattle.Pathfinding;

type
  /// <summary>What the AI reads of the game rules and of the saved game outside the battle</summary>
  TXcomAIConfig = record
    /// <summary>SavedGame::getDifficultyCoefficient</summary>
    DifficultyCoefficient: Integer;
    /// <summary>Mod::getTurnAIUseGrenade: the turn from which aliens throw grenades</summary>
    TurnUseGrenade: Integer;
    /// <summary>Mod::getTurnAIUseBlaster</summary>
    TurnUseBlaster: Integer;
    /// <summary>Options::battleExplosionHeight</summary>
    ExplosionHeight: Integer;
  end;

  /// <summary>
  ///   The thinking of the AI of one unit: it reads and writes the state that its TXcomAIModule keeps and gives
  ///   the action to carry out (AIModule). The C++ writes tile markers when Options::traceAI is on: not here
  /// </summary>
  TXcomAIThinker = class
  strict private
    FSave: TXcomSavedBattleGame;
    FEngine: TXcomTileEngine;
    FPathfinding: TXcomPathfinding;
    FConfig: TXcomAIConfig;
    FModule: TXcomAIModule;
    FUnit: TXcomBattleUnit;
    function Random(AMin, AMax: Integer): Integer;
    function Percent(AValue: Integer): Boolean;
    procedure Shuffle(var AList: TArray<TXcomPosition>);
    class function Contains(const AList: TArray<Integer>; AValue: Integer): Boolean; static;
    class procedure ScaleBy(var AValue: Integer; AFactor: Double); static;
    procedure SetupPatrol;
    procedure SetupAmbush;
    procedure SetupAttack;
    procedure SetupEscape;
    function CountKnownTargets: Integer;
    function GetSpottingUnits(const APosition: TXcomPosition): Integer;
    function SelectNearestTarget: Integer;
    function SelectClosestKnownEnemy: Boolean;
    function SelectRandomTarget: Boolean;
    function SelectPointNearTarget(const ATarget: TXcomBattleUnit; AMaxTus: Integer): Boolean;
    procedure EvaluateAIMode;
    function FindFirePoint: Boolean;
    function ExplosiveEfficacy(const ATargetPosition: TXcomPosition; const AAttackingUnit: TXcomBattleUnit;
      ARadius, ADifficulty: Integer; AGrenade: Boolean = False): Boolean;
    procedure MeleeAction;
    procedure WayPointAction;
    procedure ProjectileAction;
    procedure SelectFireMethod;
    procedure GrenadeAction;
    function PsiAction: Boolean;
    procedure MeleeAttack;
    function ValidTarget(const AUnit: TXcomBattleUnit; AAssessDanger, AIncludeCivilians: Boolean): Boolean;
    procedure SelectMeleeOrRanged;
    function GetNodeOfBestEfficacy(const AAction: TXcomBattleAction): Boolean;
  public
    constructor Create(const ASave: TXcomSavedBattleGame; const AEngine: TXcomTileEngine;
      const APathfinding: TXcomPathfinding; const AConfig: TXcomAIConfig);
    /// <summary>
    ///   think: runs the AI cycle of the unit of a module and fills the action to carry out (BA_RETHINK when there
    ///   is nothing to do). The action keeps its number and the actor is set
    /// </summary>
    procedure Think(const AModule: TXcomAIModule; const AAction: TXcomBattleAction);
    /// <summary>explosiveEfficacy (public: the reaction fire of the hostile units asks it)</summary>
    function WorthExploding(const ATargetPosition: TXcomPosition; const AAttackingUnit: TXcomBattleUnit;
      ARadius, ADifficulty: Integer): Boolean;
  end;

implementation

{ TXcomAIThinker }

constructor TXcomAIThinker.Create(const ASave: TXcomSavedBattleGame; const AEngine: TXcomTileEngine;
  const APathfinding: TXcomPathfinding; const AConfig: TXcomAIConfig);
begin
  inherited Create;
  FSave := ASave;
  FEngine := AEngine;
  FPathfinding := APathfinding;
  FConfig := AConfig;
end;

function TXcomAIThinker.Random(AMin, AMax: Integer): Integer;
begin
  Result := FSave.Random.Generate(AMin, AMax);
end;

function TXcomAIThinker.Percent(AValue: Integer): Boolean;
begin
  Result := TXcomBattleRandom.Percent(FSave.Random, AValue);
end;

procedure TXcomAIThinker.Shuffle(var AList: TArray<TXcomPosition>);
var
  LIndex: Integer;
  LOther: Integer;
  LSwap: TXcomPosition;
begin
  if Length(AList) = 0 then
    Exit;
  for LIndex := High(AList) downto 1 do
  begin
    LOther := Random(0, LIndex);
    LSwap := AList[LIndex];
    AList[LIndex] := AList[LOther];
    AList[LOther] := LSwap;
  end;
end;

class function TXcomAIThinker.Contains(const AList: TArray<Integer>; AValue: Integer): Boolean;
var
  LItem: Integer;
begin
  for LItem in AList do
    if LItem = AValue then
      Exit(True);
  Result := False;
end;

class procedure TXcomAIThinker.ScaleBy(var AValue: Integer; AFactor: Double);
var
  LProduct: Double;
begin
  // int *= double: the product is a double (SSE) and is truncated; a variable keeps it from the x87 extended
  LProduct := AValue * AFactor;
  AValue := Trunc(LProduct);
end;

procedure TXcomAIThinker.Think(const AModule: TXcomAIModule; const AAction: TXcomBattleAction);
var
  LRule: TXcomRuleItem;
  LEvaluate: Boolean;
begin
  FModule := AModule;
  FUnit := AModule.Owner;
  AAction.ActionType := BA_RETHINK;
  AAction.Actor := FUnit;
  AAction.Weapon := FUnit.GetMainHandWeapon(False);
  FModule.AttackAction.Diff := FConfig.DifficultyCoefficient;
  FModule.AttackAction.Actor := FUnit;
  FModule.AttackAction.Weapon := AAction.Weapon;
  FModule.AttackAction.Number := AAction.Number;
  FModule.EscapeAction.Number := AAction.Number;
  FModule.KnownEnemies := CountKnownTargets;
  FModule.VisibleEnemies := SelectNearestTarget;
  FModule.SpottingEnemies := GetSpottingUnits(FUnit.Position);
  FModule.Melee := (FUnit.GetMeleeWeapon <> nil);
  FModule.Rifle := False;
  FModule.Blaster := False;
  FModule.Reachable := FPathfinding.FindReachable(FUnit, FUnit.TimeUnits);
  FModule.WasHitBy := nil;
  if Assigned(FUnit.Charging) and FUnit.Charging.IsOut then
    FUnit.Charging := nil;
  if Assigned(AAction.Weapon) then
  begin
    LRule := AAction.Weapon.Rules;
    if FSave.IsItemUsable(AAction.Weapon) then
    begin
      if LRule.BattleType = TXcomRuleItem.BT_FIREARM then
      begin
        if (LRule.Waypoints <> 0) or (Assigned(AAction.Weapon.AmmoItem) and
          (AAction.Weapon.AmmoItem.Rules.Waypoints <> 0)) then
        begin
          FModule.Blaster := True;
          FModule.ReachableWithAttack := FPathfinding.FindReachable(FUnit,
            FUnit.TimeUnits - FUnit.GetActionTus(BA_AIMEDSHOT, AAction.Weapon));
        end
        else
        begin
          FModule.Rifle := True;
          FModule.ReachableWithAttack := FPathfinding.FindReachable(FUnit,
            FUnit.TimeUnits - FUnit.GetActionTus(BA_SNAPSHOT, AAction.Weapon));
        end;
      end
      else if LRule.BattleType = TXcomRuleItem.BT_MELEE then
      begin
        FModule.Melee := True;
        FModule.ReachableWithAttack := FPathfinding.FindReachable(FUnit,
          FUnit.TimeUnits - FUnit.GetActionTus(BA_HIT, AAction.Weapon));
      end;
    end
    else
      AAction.Weapon := nil;
  end;
  if (FModule.SpottingEnemies <> 0) and (FModule.EscapeTus = 0) then
    SetupEscape;
  if (FModule.KnownEnemies <> 0) and (not FModule.Melee) and (FModule.AmbushTus = 0) then
    SetupAmbush;
  SetupAttack;
  SetupPatrol;
  if (FModule.PsiAction.ActionType <> BA_NONE) and (not FModule.DidPsi) then
  begin
    FModule.DidPsi := True;
    AAction.ActionType := FModule.PsiAction.ActionType;
    AAction.Target := FModule.PsiAction.Target;
    Dec(AAction.Number);
    AAction.Weapon := FModule.PsiAction.Weapon;
    Exit;
  end
  else
    FModule.DidPsi := False;
  LEvaluate := False;
  case FModule.AIMode of
    AI_PATROL:
      LEvaluate := (FModule.SpottingEnemies <> 0) or (FModule.VisibleEnemies <> 0) or (FModule.KnownEnemies <> 0) or
        Percent(10);
    AI_AMBUSH:
      LEvaluate := (not FModule.Rifle) or (FModule.AmbushTus = 0) or (FModule.VisibleEnemies <> 0);
    AI_COMBAT:
      LEvaluate := FModule.AttackAction.ActionType = BA_RETHINK;
    AI_ESCAPE:
      LEvaluate := (FModule.SpottingEnemies = 0) or (FModule.KnownEnemies = 0);
  end;
  if (FModule.SpottingEnemies > 2) or (FUnit.Health < 2 * FUnit.Stats.Health div 3) or
    (Assigned(FModule.AggroTarget) and (FModule.AggroTarget.TurnsSinceSpotted > FModule.Intelligence)) then
    LEvaluate := True;
  if FSave.Cheating and (FModule.AIMode <> AI_COMBAT) then
    LEvaluate := True;
  if LEvaluate then
    EvaluateAIMode;
  FModule.ReserveMode := BA_NONE;
  case FModule.AIMode of
    AI_ESCAPE:
      begin
        FUnit.Charging := nil;
        AAction.ActionType := FModule.EscapeAction.ActionType;
        AAction.Target := FModule.EscapeAction.Target;
        // end this unit's turn
        AAction.FinalAction := True;
        // ignore new targets
        AAction.Desperate := True;
        // spin 180 at the end of the route
        FUnit.IsHiding := True;
      end;
    AI_PATROL:
      begin
        FUnit.Charging := nil;
        if Assigned(AAction.Weapon) and (AAction.Weapon.Rules.BattleType = TXcomRuleItem.BT_FIREARM) then
        begin
          case FUnit.Aggression of
            0: FModule.ReserveMode := BA_AIMEDSHOT;
            1: FModule.ReserveMode := BA_AUTOSHOT;
            2: FModule.ReserveMode := BA_SNAPSHOT;
          end;
        end;
        AAction.ActionType := FModule.PatrolAction.ActionType;
        AAction.Target := FModule.PatrolAction.Target;
      end;
    AI_COMBAT:
      begin
        AAction.ActionType := FModule.AttackAction.ActionType;
        AAction.Target := FModule.AttackAction.Target;
        // this may have changed to a grenade
        AAction.Weapon := FModule.AttackAction.Weapon;
        if Assigned(AAction.Weapon) and (AAction.ActionType = BA_THROW) and
          (AAction.Weapon.Rules.BattleType = TXcomRuleItem.BT_GRENADE) then
          FUnit.SpendTimeUnits(4 + FUnit.GetActionTus(BA_PRIME, AAction.Weapon));
        // if this is a firepoint action, set our facing
        AAction.FinalFacing := FModule.AttackAction.FinalFacing;
        AAction.TimeUnits := FUnit.GetActionTus(FModule.AttackAction.ActionType, FModule.AttackAction.Weapon);
        // if this is a "find fire point" action, do not increment the AI counter
        if (AAction.ActionType = BA_WALK) and FModule.Rifle and
          // so long as we can take a shot afterwards
          (FUnit.TimeUnits > FUnit.GetActionTus(BA_SNAPSHOT, AAction.Weapon)) then
          Dec(AAction.Number)
        else if AAction.ActionType = BA_LAUNCH then
        begin
          AAction.Waypoints.Clear;
          AAction.Waypoints.AddRange(FModule.AttackAction.Waypoints);
        end;
      end;
    AI_AMBUSH:
      begin
        FUnit.Charging := nil;
        AAction.ActionType := FModule.AmbushAction.ActionType;
        AAction.Target := FModule.AmbushAction.Target;
        // face where we think our target will appear
        AAction.FinalFacing := FModule.AmbushAction.FinalFacing;
        // end this unit's turn
        AAction.FinalAction := True;
      end;
  end;
  if AAction.ActionType = BA_WALK then
  begin
    // if we are moving, we will have to re-evaluate our escape/ambush position
    if AAction.Target <> FUnit.Position then
    begin
      FModule.EscapeTus := 0;
      FModule.AmbushTus := 0;
    end
    else
      AAction.ActionType := BA_NONE;
  end;
end;

procedure TXcomAIThinker.SetupPatrol;
var
  LNode: TXcomNode;
  LDirection: Integer;
  LClosest: Integer;
  LDistance: Integer;
  LTriesLeft: Integer;
  LScout: Boolean;
  LTile: TXcomTile;
  LX: Integer;
  LY: Integer;
  LStartX: Integer;
  LStartY: Integer;
  LData: TXcomMapData;
  LAttackWeapon: TXcomBattleItem;
  LAmmo: TXcomBattleItem;
  LPosition: TXcomPosition;
  LModuleTile: TXcomTile;
begin
  FModule.PatrolAction.TimeUnits := 0;
  if Assigned(FModule.ToNode) and (FUnit.Position = FModule.ToNode.Position) then
  begin
    // destination reached: head off to the next patrol node
    FModule.FromNode := FModule.ToNode;
    FModule.FreePatrolTarget;
    FModule.ToNode := nil;
    // take a peek through a window before walking to the next node
    LDirection := FEngine.FaceWindow(FUnit.Position);
    if (LDirection <> -1) and (LDirection <> FUnit.Direction) then
    begin
      FUnit.LookAt(LDirection);
      while FUnit.Status = STATUS_TURNING do
        FUnit.Turn;
    end;
  end;
  if not Assigned(FModule.FromNode) then
  begin
    // assume the closest node as "from node", on the same level, and it has to match the unit size
    LClosest := 1000000;
    for LNode in FSave.Nodes do
    begin
      if LNode.Dummy then
        Continue;
      LDistance := FEngine.DistanceSq(FUnit.Position, LNode.Position);
      if (FUnit.Position.Z = LNode.Position.Z) and (LDistance < LClosest) and
        (((LNode.NodeType and NODE_TYPE_SMALL) = 0) or (FUnit.Armor.Size = 1)) then
      begin
        FModule.FromNode := LNode;
        LClosest := LDistance;
      end;
    end;
  end;
  LTriesLeft := 5;
  while (not Assigned(FModule.ToNode)) and (LTriesLeft > 0) do
  begin
    Dec(LTriesLeft);
    // look for a new node to walk towards
    LScout := True;
    LAttackWeapon := FModule.AttackAction.Weapon;
    if FSave.MissionType <> 'STR_BASE_DEFENSE' then
    begin
      // after turn 20 or if the morale is low, everyone moves out and scouts; anyone standing in fire moves too
      LTile := FSave.TileAt(FUnit.Position);
      LScout := FSave.Cheating or (not Assigned(FModule.FromNode)) or (FModule.FromNode.Rank = 0) or
        (Assigned(LTile) and (LTile.Fire <> 0));
    end
    // in base defense missions, the smaller aliens walk towards target nodes, or shoot objects around them
    else if (FUnit.Armor.Size = 1) and Assigned(LAttackWeapon) and (LAttackWeapon.Rules.AccuracySnap <> 0) and
      (not LAttackWeapon.Rules.ArcingShot) and Assigned(LAttackWeapon.AmmoItem) then
    begin
      LAmmo := LAttackWeapon.AmmoItem;
      if (not LAmmo.Rules.ArcingShot) and (LAmmo.Rules.DamageType <> TXcomRuleItem.DT_HE) and
        (LAmmo.Rules.DamageType <> TXcomRuleItem.DT_STUN) then
      begin
        // can a node be shot at?
        if FModule.FromNode.IsTarget and
          (FSave.ModuleMap[FModule.FromNode.Position.X div 10][FModule.FromNode.Position.Y div 10].Value > 0) then
        begin
          // scan this room for objects to destroy
          LStartX := (FUnit.Position.X div 10) * 10;
          LStartY := (FUnit.Position.Y div 10) * 10;
          for LX := LStartX to LStartX + 8 do
            for LY := LStartY to LStartY + 8 do
            begin
              LModuleTile := FSave.TileAt(TXcomPosition.Make(LX, LY, 1));
              LData := LModuleTile.MapData[XCOM_PART_OBJECT];
              if Assigned(LData) and LData.IsBaseModule then
              begin
                FModule.PatrolAction.Actor := FUnit;
                FModule.PatrolAction.Target := TXcomPosition.Make(LX, LY, 1);
                FModule.PatrolAction.Weapon := LAttackWeapon;
                FModule.PatrolAction.ActionType := BA_SNAPSHOT;
                FModule.PatrolAction.TimeUnits := FModule.PatrolAction.Actor.GetActionTus(
                  FModule.PatrolAction.ActionType, FModule.PatrolAction.Weapon);
                Exit;
              end;
            end;
        end
        else
        begin
          // find the closest high value target that is not already allocated
          LClosest := 1000000;
          for LNode in FSave.Nodes do
          begin
            if LNode.Dummy then
              Continue;
            LTile := FSave.TileAt(LNode.Position);
            if Assigned(LTile.CurrentUnit) and (LTile.CurrentUnit.Faction = FUnit.Faction) then
              Continue;
            if LNode.IsTarget and (not LNode.Allocated) and
              (FSave.ModuleMap[LNode.Position.X div 10][LNode.Position.Y div 10].Value > 0) then
            begin
              LDistance := FEngine.DistanceSq(FUnit.Position, LNode.Position);
              if (not Assigned(FModule.ToNode)) or ((LDistance < LClosest) and (LNode <> FModule.FromNode)) then
              begin
                FModule.ToNode := LNode;
                LClosest := LDistance;
              end;
            end;
          end;
        end;
      end;
    end;
    if not Assigned(FModule.ToNode) then
    begin
      FModule.ToNode := FSave.GetPatrolNode(LScout, FUnit, FModule.FromNode);
      if not Assigned(FModule.ToNode) then
        FModule.ToNode := FSave.GetPatrolNode(not LScout, FUnit, FModule.FromNode);
    end;
    if Assigned(FModule.ToNode) then
    begin
      FPathfinding.Calculate(FUnit, FModule.ToNode.Position);
      if FPathfinding.GetStartDirection = -1 then
        FModule.ToNode := nil;
      FPathfinding.AbortPath;
    end;
  end;
  if Assigned(FModule.ToNode) then
  begin
    FModule.ToNode.Allocate;
    FModule.PatrolAction.Actor := FUnit;
    FModule.PatrolAction.ActionType := BA_WALK;
    FModule.PatrolAction.Target := FModule.ToNode.Position;
  end
  else
    FModule.PatrolAction.ActionType := BA_RETHINK;
end;

procedure TXcomAIThinker.SetupAmbush;
const
  BASE_SYSTEMATIC_SUCCESS = 100;
  COVER_BONUS = 25;
  FAST_PASS_THRESHOLD = 80;
var
  LBestScore: Integer;
  LPath: TArray<Integer>;
  LOrigin: TXcomPosition;
  LNode: TXcomNode;
  LPosition: TXcomPosition;
  LTile: TXcomTile;
  LTarget: TXcomPosition;
  LAmbushTus: Integer;
  LScore: Integer;
  LCurrent: TXcomPosition;
  LNext: TXcomPosition;
  LTries: Integer;
  LIndex: Integer;
begin
  FModule.AmbushAction.ActionType := BA_RETHINK;
  LBestScore := 0;
  FModule.AmbushTus := 0;
  LPath := nil;
  if SelectClosestKnownEnemy then
  begin
    LOrigin := FEngine.GetSightOriginVoxel(FModule.AggroTarget);
    // the node positions are used: it gives the map makers a good degree of control over how the units use the map
    for LNode in FSave.Nodes do
    begin
      if LNode.Dummy then
        Continue;
      LPosition := LNode.Position;
      LTile := FSave.TileAt(LPosition);
      if (not Assigned(LTile)) or (FEngine.Distance(LPosition, FUnit.Position) > 10) or
        (LPosition.Z <> FUnit.Position.Z) or LTile.Dangerous or
        (not Contains(FModule.ReachableWithAttack, FSave.TileIndex(LPosition))) then
        Continue; // just ignore unreachable tiles
      // make sure we cannot be seen here
      if (not FEngine.CanTargetUnit(LOrigin, LTile, LTarget, FModule.AggroTarget, False, FUnit)) and
        (GetSpottingUnits(LPosition) = 0) then
      begin
        FPathfinding.Calculate(FUnit, LPosition);
        LAmbushTus := FPathfinding.TotalTuCost;
        // make sure we can move here
        if FPathfinding.GetStartDirection <> -1 then
        begin
          LScore := BASE_SYSTEMATIC_SUCCESS;
          Dec(LScore, LAmbushTus);
          // make sure our enemy can reach here too
          FPathfinding.Calculate(FModule.AggroTarget, LPosition);
          if FPathfinding.GetStartDirection <> -1 then
          begin
            // ideally behind some cover, like a window or a low wall
            if FEngine.FaceWindow(LPosition) <> -1 then
              Inc(LScore, COVER_BONUS);
            if LScore > LBestScore then
            begin
              LPath := FPathfinding.Path;
              LBestScore := LScore;
              if LPosition = FUnit.Position then
                FModule.AmbushTus := 1
              else
                FModule.AmbushTus := LAmbushTus;
              FModule.AmbushAction.Target := LPosition;
              if LBestScore > FAST_PASS_THRESHOLD then
                Break;
            end;
          end;
        end;
      end;
    end;
    if LBestScore > 0 then
    begin
      FModule.AmbushAction.ActionType := BA_WALK;
      // 4 because -2 is the eyes and 2 below that is the rifle
      LOrigin := (FModule.AmbushAction.Target * TXcomPosition.Make(16, 16, 24)) +
        TXcomPosition.Make(8, 8, FUnit.GetHeight + FUnit.FloatHeight -
        FSave.TileAt(FModule.AmbushAction.Target).GetTerrainLevel - 4);
      LCurrent := FModule.AggroTarget.Position;
      FPathfinding.SetUnit(FModule.AggroTarget);
      LTries := Length(LPath);
      LIndex := 0;
      // hypothetically walk the target through the path
      while LTries > 0 do
      begin
        FPathfinding.GetTuCost(LCurrent, LPath[LIndex], LNext, FModule.AggroTarget, nil, False);
        Inc(LIndex);
        LCurrent := LNext;
        LTile := FSave.TileAt(LCurrent);
        // a virtual fire calculation
        if FEngine.CanTargetUnit(LOrigin, LTile, LTarget, FUnit, False, FModule.AggroTarget) then
        begin
          // if we can virtually fire at the hypothetical target, we know which way to face
          FModule.AmbushAction.FinalFacing := FEngine.GetDirectionTo(FModule.AmbushAction.Target, LCurrent);
          Break;
        end;
        Dec(LTries);
      end;
    end;
  end;
end;

procedure TXcomAIThinker.SetupAttack;
begin
  FModule.AttackAction.ActionType := BA_RETHINK;
  FModule.PsiAction.ActionType := BA_NONE;
  // if enemies are known to us but not necessarily visible, we can attack them with a blaster launcher or psi
  if FModule.KnownEnemies <> 0 then
  begin
    if PsiAction then
      // the unit WILL make a psionic attack this turn
      Exit;
    if FModule.Blaster then
      WayPointAction;
  end;
  // if we CAN see someone, that makes them a viable target for "regular" attacks
  if SelectNearestTarget <> 0 then
  begin
    // if we have both types of weapon, make a determination on which to use
    if FModule.Melee and FModule.Rifle then
      SelectMeleeOrRanged;
    if (FUnit.GetGrenadeFromBelt <> nil) then
      GrenadeAction;
    if FModule.Melee then
      MeleeAction;
    if FModule.Rifle then
      ProjectileAction;
  end;
  if FModule.AttackAction.ActionType <> BA_RETHINK then
    Exit
  else if (FModule.SpottingEnemies <> 0) or (FUnit.Aggression < Random(0, 3)) then
  begin
    // if enemies can see us, or if we are feeling lucky, we can try to spot the enemy
    if FindFirePoint then
      Exit;
  end;
end;

procedure TXcomAIThinker.SetupEscape;
const
  EXPOSURE_PENALTY = 10;
  FIRE_PENALTY = 40;
  BASE_SYSTEMATIC_SUCCESS = 100;
  BASE_DESPERATE_SUCCESS = 110;
  FAST_PASS_THRESHOLD = 100;
var
  LUnitsSpottingMe: Integer;
  LCurrentTilePreference: Integer;
  LTries: Integer;
  LCoverFound: Boolean;
  LDistance: Integer;
  LBestTileScore: Integer;
  LScore: Integer;
  LBestTile: TXcomPosition;
  LTile: TXcomTile;
  LRandomTileSearch: TArray<TXcomPosition>;
  LDistanceFromTarget: Integer;
  LSpotters: Integer;
  LTarget: TXcomPosition;
begin
  LUnitsSpottingMe := GetSpottingUnits(FUnit.Position);
  LCurrentTilePreference := 15;
  LTries := -1;
  LCoverFound := False;
  SelectNearestTarget;
  FModule.EscapeTus := 0;
  if Assigned(FModule.AggroTarget) then
    LDistance := FEngine.Distance(FUnit.Position, FModule.AggroTarget.Position)
  else
    LDistance := 0;
  LBestTileScore := -100000;
  LBestTile := TXcomPosition.Make(0, 0, 0);
  LRandomTileSearch := Copy(FSave.TileSearch);
  Shuffle(LRandomTileSearch);
  while (LTries < 150) and (not LCoverFound) do
  begin
    // start looking in a direction away from the enemy
    LTarget := FUnit.Position;
    LScore := 0;
    if LTries = -1 then
    begin
      // maybe stay where we are and not risk reaction fire, or continue to wherever we were running to
      if Assigned(FSave.TileAt(FUnit.LastCover)) then
        LTarget := FUnit.LastCover;
    end
    else if LTries < 121 then
    begin
      // looking for cover
      Inc(LTarget.X, LRandomTileSearch[LTries].X);
      Inc(LTarget.Y, LRandomTileSearch[LTries].Y);
      LScore := BASE_SYSTEMATIC_SUCCESS;
      if LTarget = FUnit.Position then
      begin
        if LUnitsSpottingMe > 0 then
        begin
          // maybe do not stay in the same spot
          Inc(LTarget.X, Random(-20, 20));
          Inc(LTarget.Y, Random(-20, 20));
        end
        else
          Inc(LScore, LCurrentTilePreference);
      end;
    end
    else
    begin
      LScore := BASE_DESPERATE_SUCCESS; // run
      LTarget := FUnit.Position;
      Inc(LTarget.X, Random(-10, 10));
      Inc(LTarget.Y, Random(-10, 10));
      LTarget.Z := FUnit.Position.Z + Random(-1, 1);
      if LTarget.Z < 0 then
        LTarget.Z := 0
      else if LTarget.Z >= FSave.MapSizeZ then
        LTarget.Z := FUnit.Position.Z;
    end;
    FModule.EscapeAction.Target := LTarget;
    Inc(LTries);
    LTile := FSave.TileAt(LTarget);
    if Assigned(FModule.AggroTarget) then
      LDistanceFromTarget := FEngine.Distance(FModule.AggroTarget.Position, LTarget)
    else
      LDistanceFromTarget := 0;
    if LDistance >= LDistanceFromTarget then
      Dec(LScore, (LDistanceFromTarget - LDistance) * 10)
    else
      Inc(LScore, (LDistanceFromTarget - LDistance) * 10);
    if not Assigned(LTile) then
      LScore := -100001 // running off the map does not quit the battlefield
    else
    begin
      LSpotters := GetSpottingUnits(LTarget);
      if not Contains(FModule.Reachable, FSave.TileIndex(LTarget)) then
        Continue; // just ignore unreachable tiles
      if (FModule.SpottingEnemies <> 0) or (LSpotters <> 0) then
      begin
        if FModule.SpottingEnemies <= LSpotters then
          Dec(LScore, (1 + LSpotters - FModule.SpottingEnemies) * EXPOSURE_PENALTY) // for giving away our position
        else
          Inc(LScore, (FModule.SpottingEnemies - LSpotters) * EXPOSURE_PENALTY);
      end;
      if LTile.Fire <> 0 then
        Dec(LScore, FIRE_PENALTY);
      if LTile.Dangerous then
        Dec(LScore, BASE_SYSTEMATIC_SUCCESS);
    end;
    if Assigned(LTile) and (LScore > LBestTileScore) then
    begin
      // the time units to the tile
      FPathfinding.Calculate(FUnit, LTarget);
      if (LTarget = FUnit.Position) or (FPathfinding.GetStartDirection <> -1) then
      begin
        LBestTileScore := LScore;
        LBestTile := LTarget;
        FModule.EscapeTus := FPathfinding.TotalTuCost;
        if LTarget = FUnit.Position then
          FModule.EscapeTus := 1;
      end;
      FPathfinding.AbortPath;
      if LBestTileScore > FAST_PASS_THRESHOLD then
        LCoverFound := True; // good enough
    end;
  end;
  FModule.EscapeAction.Target := LBestTile;
  if LBestTileScore <= -100000 then
    FModule.EscapeAction.ActionType := BA_RETHINK // do something, just do not look dumbstruck
  else
    FModule.EscapeAction.ActionType := BA_WALK;
end;

function TXcomAIThinker.CountKnownTargets: Integer;
var
  LUnit: TXcomBattleUnit;
begin
  Result := 0;
  if FUnit.Faction = FACTION_HOSTILE then
    for LUnit in FSave.Units do
      if ValidTarget(LUnit, True, True) then
        Inc(Result);
end;

function TXcomAIThinker.GetSpottingUnits(const APosition: TXcomPosition): Integer;
var
  LChecking: Boolean;
  LUnit: TXcomBattleUnit;
  LDistance: Integer;
  LOriginVoxel: TXcomPosition;
  LTargetVoxel: TXcomPosition;
begin
  // if we do not actually occupy the position being checked, a virtual LOF check
  LChecking := APosition <> FUnit.Position;
  Result := 0;
  for LUnit in FSave.Units do
  begin
    if ValidTarget(LUnit, False, False) then
    begin
      LDistance := FEngine.Distance(APosition, LUnit.Position);
      if LDistance > 20 then
        Continue;
      LOriginVoxel := FEngine.GetSightOriginVoxel(LUnit);
      Dec(LOriginVoxel.Z, 2);
      if LChecking then
      begin
        if FEngine.CanTargetUnit(LOriginVoxel, FSave.TileAt(APosition), LTargetVoxel, LUnit, False, FUnit) then
          Inc(Result);
      end
      else if FEngine.CanTargetUnit(LOriginVoxel, FSave.TileAt(APosition), LTargetVoxel, LUnit, False) then
        Inc(Result);
    end;
  end;
end;

function TXcomAIThinker.SelectNearestTarget: Integer;
var
  LTally: Integer;
  LUnit: TXcomBattleUnit;
  LDistance: Integer;
  LValid: Boolean;
  LAction: TXcomBattleAction;
  LOrigin: TXcomPosition;
  LTarget: TXcomPosition;
  LDirection: Integer;
  LDestination: TXcomPosition;
begin
  LTally := 0;
  FModule.ClosestDistance := 100;
  FModule.AggroTarget := nil;
  for LUnit in FSave.Units do
  begin
    if ValidTarget(LUnit, True, FUnit.Faction = FACTION_HOSTILE) and FEngine.Visible(FUnit, LUnit.Tile) then
    begin
      Inc(LTally);
      LDistance := FEngine.Distance(FUnit.Position, LUnit.Position);
      if LDistance < FModule.ClosestDistance then
      begin
        LValid := False;
        if FModule.Rifle or (not FModule.Melee) then
        begin
          LAction := TXcomBattleAction.Create;
          try
            LAction.Actor := FUnit;
            LAction.Weapon := FModule.AttackAction.Weapon;
            LAction.Target := LUnit.Position;
            LOrigin := FEngine.GetOriginVoxel(LAction, nil);
            LValid := FEngine.CanTargetUnit(LOrigin, LUnit.Tile, LTarget, FUnit, False);
          finally
            LAction.Free;
          end;
        end
        else if SelectPointNearTarget(LUnit, FUnit.TimeUnits) then
        begin
          LDirection := FEngine.GetDirectionTo(FModule.AttackAction.Target, LUnit.Position);
          LValid := FEngine.ValidMeleeRange(FModule.AttackAction.Target, LDirection, FUnit, LUnit, LDestination);
        end;
        if LValid then
        begin
          FModule.ClosestDistance := LDistance;
          FModule.AggroTarget := LUnit;
        end;
      end;
    end;
  end;
  if Assigned(FModule.AggroTarget) then
    Result := LTally
  else
    Result := 0;
end;

function TXcomAIThinker.SelectClosestKnownEnemy: Boolean;
var
  LUnit: TXcomBattleUnit;
  LMinDistance: Integer;
  LDistance: Integer;
begin
  FModule.AggroTarget := nil;
  LMinDistance := 255;
  for LUnit in FSave.Units do
    if ValidTarget(LUnit, True, False) then
    begin
      LDistance := FEngine.Distance(LUnit.Position, FUnit.Position);
      if LDistance < LMinDistance then
      begin
        LMinDistance := LDistance;
        FModule.AggroTarget := LUnit;
      end;
    end;
  Result := Assigned(FModule.AggroTarget);
end;

function TXcomAIThinker.SelectRandomTarget: Boolean;
var
  LFarthest: Integer;
  LUnit: TXcomBattleUnit;
  LDistance: Integer;
begin
  LFarthest := -100;
  FModule.AggroTarget := nil;
  for LUnit in FSave.Units do
    if ValidTarget(LUnit, True, FUnit.Faction = FACTION_HOSTILE) then
    begin
      LDistance := Random(0, 20) - FEngine.Distance(FUnit.Position, LUnit.Position);
      if LDistance > LFarthest then
      begin
        LFarthest := LDistance;
        FModule.AggroTarget := LUnit;
      end;
    end;
  Result := Assigned(FModule.AggroTarget);
end;

function TXcomAIThinker.SelectPointNearTarget(const ATarget: TXcomBattleUnit; AMaxTus: Integer): Boolean;
var
  LSize: Integer;
  LTargetSize: Integer;
  LDistance: Cardinal;
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LCheckPath: TXcomPosition;
  LDirection: Integer;
  LValid: Boolean;
  LFitHere: Boolean;
  LDestination: TXcomPosition;
  LPathLength: Integer;
begin
  LSize := FUnit.Armor.Size;
  LTargetSize := ATarget.Armor.Size;
  Result := False;
  LDistance := 1000;
  for LZ := -1 to 1 do
    for LX := -LSize to LTargetSize do
      for LY := -LSize to LTargetSize do
      begin
        if (LX <> 0) or (LY <> 0) then // skip the unit itself
        begin
          LCheckPath := ATarget.Position + TXcomPosition.Make(LX, LY, LZ);
          if (not Assigned(FSave.TileAt(LCheckPath))) or
            (not Contains(FModule.Reachable, FSave.TileIndex(LCheckPath))) then
            Continue;
          LDirection := FEngine.GetDirectionTo(LCheckPath, ATarget.Position);
          LValid := FEngine.ValidMeleeRange(LCheckPath, LDirection, FUnit, ATarget, LDestination);
          LFitHere := FSave.SetUnitPosition(FUnit, LCheckPath, True);
          if LValid and LFitHere and (not FSave.TileAt(LCheckPath).Dangerous) then
          begin
            FPathfinding.Calculate(FUnit, LCheckPath, nil, AMaxTus);
            LPathLength := Length(FPathfinding.Path);
            if (FPathfinding.GetStartDirection <> -1) and (Cardinal(LPathLength) < LDistance) then
            begin
              FModule.AttackAction.Target := LCheckPath;
              Result := True;
              LDistance := Cardinal(LPathLength);
            end;
            FPathfinding.AbortPath;
          end;
        end;
      end;
end;

procedure TXcomAIThinker.EvaluateAIMode;
var
  LEscapeOdds: Integer;
  LAmbushOdds: Integer;
  LCombatOdds: Integer;
  LPatrolOdds: Integer;
  LDecision: Integer;
  LHealth: Integer;
  LClamped: Double;
begin
  if Assigned(FUnit.Charging) and (FModule.AttackAction.ActionType <> BA_RETHINK) then
  begin
    FModule.AIMode := AI_COMBAT;
    Exit;
  end;
  // do not try to run away as often if we are a melee type, and really do not with a viable melee target, or 50%
  // or more of the time units remaining
  LEscapeOdds := 15;
  if FModule.Melee then
    LEscapeOdds := 12;
  if (FUnit.Faction = FACTION_HOSTILE) and ((FUnit.TimeUnits > FUnit.Stats.TimeUnits div 2) or
    Assigned(FUnit.Charging)) then
    LEscapeOdds := 5;
  LAmbushOdds := 12;
  LCombatOdds := 20;
  if FModule.VisibleEnemies <> 0 then
    LPatrolOdds := 15
  else
    LPatrolOdds := 30;
  // if enemies can see us, patrolling is not an option; make sure an escape plan is ready
  if FModule.SpottingEnemies <> 0 then
  begin
    LPatrolOdds := 0;
    if FModule.EscapeTus = 0 then
      SetupEscape;
  end;
  // no ranged weapon or no ambush spot: ambush is not an option, and melee types like combat more
  if (not FModule.Rifle) or (FModule.AmbushTus = 0) then
  begin
    LAmbushOdds := 0;
    if FModule.Melee then
      ScaleBy(LCombatOdds, 1.3);
  end;
  if FModule.KnownEnemies <> 0 then
  begin
    if FModule.KnownEnemies = 1 then
      ScaleBy(LCombatOdds, 1.2);
    if FModule.EscapeTus = 0 then
    begin
      if SelectClosestKnownEnemy then
        SetupEscape
      else
        LEscapeOdds := 0;
    end;
  end
  else if FUnit.Faction = FACTION_HOSTILE then
  begin
    // no enemies: nothing to fight or run from
    LCombatOdds := 0;
    LEscapeOdds := 0;
  end;
  // the current mode has a bonus
  case FModule.AIMode of
    AI_PATROL: ScaleBy(LPatrolOdds, 1.1);
    AI_AMBUSH: ScaleBy(LAmbushOdds, 1.1);
    AI_COMBAT: ScaleBy(LCombatOdds, 1.1);
    AI_ESCAPE: ScaleBy(LEscapeOdds, 1.1);
  end;
  // the more wounded, the more it wants to run
  LHealth := FUnit.Stats.Health;
  if FUnit.Health < LHealth div 3 then
  begin
    ScaleBy(LEscapeOdds, 1.7);
    ScaleBy(LCombatOdds, 0.6);
    ScaleBy(LAmbushOdds, 0.75);
  end
  else if FUnit.Health < 2 * (LHealth div 3) then
  begin
    ScaleBy(LEscapeOdds, 1.4);
    ScaleBy(LCombatOdds, 0.8);
    ScaleBy(LAmbushOdds, 0.8);
  end
  else if FUnit.Health < LHealth then
    ScaleBy(LEscapeOdds, 1.1);
  // the aggression of the unit
  case FUnit.Aggression of
    0:
      begin
        ScaleBy(LEscapeOdds, 1.4);
        ScaleBy(LCombatOdds, 0.7);
      end;
    1: ScaleBy(LAmbushOdds, 1.1);
    2:
      begin
        ScaleBy(LCombatOdds, 1.4);
        ScaleBy(LEscapeOdds, 0.7);
      end;
  else
    LClamped := Min(Max(1.2 + (FUnit.Aggression / 10.0), 0.1), 2.0);
    ScaleBy(LCombatOdds, LClamped);
    LClamped := Min(Max(0.9 - (FUnit.Aggression / 10.0), 0.1), 2.0);
    ScaleBy(LEscapeOdds, LClamped);
  end;
  if FModule.AIMode = AI_COMBAT then
    ScaleBy(LAmbushOdds, 1.5);
  if FModule.SpottingEnemies <> 0 then
  begin
    LEscapeOdds := 10 * LEscapeOdds * (FModule.SpottingEnemies + 10) div 100;
    LCombatOdds := 5 * LCombatOdds * (FModule.SpottingEnemies + 20) div 100;
  end
  else
    LEscapeOdds := LEscapeOdds div 2;
  if FModule.VisibleEnemies <> 0 then
  begin
    LCombatOdds := 10 * LCombatOdds * (FModule.VisibleEnemies + 10) div 100;
    if FModule.ClosestDistance < 5 then
      LAmbushOdds := 0;
  end;
  // the ambush needs a spot to ambush from
  if FModule.AmbushTus <> 0 then
    ScaleBy(LAmbushOdds, 1.7)
  else
    LAmbushOdds := 0;
  // base defense: the aliens are more aggressive
  if FSave.MissionType = 'STR_BASE_DEFENSE' then
  begin
    ScaleBy(LEscapeOdds, 0.75);
    ScaleBy(LAmbushOdds, 0.6);
  end;
  // no way to fight: do not even try
  if (not FModule.Melee) and (not FModule.Rifle) and (not FModule.Blaster) and
    (not (FUnit.GetGrenadeFromBelt <> nil)) and (FUnit.Stats.PsiSkill = 0) then
  begin
    LCombatOdds := 0;
    LAmbushOdds := 0;
  end;
  LDecision := Random(1, Max(1, LPatrolOdds + LAmbushOdds + LEscapeOdds + LCombatOdds));
  if LDecision > LEscapeOdds then
  begin
    if LDecision > LEscapeOdds + LAmbushOdds then
    begin
      if LDecision > LEscapeOdds + LAmbushOdds + LCombatOdds then
        FModule.AIMode := AI_PATROL
      else
        FModule.AIMode := AI_COMBAT;
    end
    else
      FModule.AIMode := AI_AMBUSH;
  end
  else
    FModule.AIMode := AI_ESCAPE;
  // enforce the validity of the decision; aliens cheating or charging always attack
  if ((FUnit.Faction = FACTION_HOSTILE) and FSave.Cheating) or Assigned(FUnit.Charging) then
    FModule.AIMode := AI_COMBAT;
  // if the decision is combat, check there is a valid target
  if FModule.AIMode = AI_COMBAT then
  begin
    if Assigned(FSave.TileAt(FModule.AttackAction.Target)) and
      Assigned(FSave.TileAt(FModule.AttackAction.Target).CurrentUnit) then
    begin
      if FModule.AttackAction.ActionType <> BA_RETHINK then
        Exit;
      if FindFirePoint then
        Exit;
    end
    else if SelectRandomTarget and FindFirePoint then
      Exit;
    FModule.AIMode := AI_PATROL;
  end;
  // if the decision is patrol, there must be a node to go to
  if FModule.AIMode = AI_PATROL then
  begin
    if Assigned(FModule.ToNode) then
      Exit;
    if FModule.PatrolAction.ActionType = BA_SNAPSHOT then
      Exit;
    FModule.AIMode := AI_AMBUSH;
  end;
  // if the decision is ambush, there must be a spot
  if FModule.AIMode = AI_AMBUSH then
  begin
    if FModule.AmbushTus <> 0 then
      Exit;
    FModule.AIMode := AI_ESCAPE;
  end;
end;

function TXcomAIThinker.FindFirePoint: Boolean;
const
  BASE_SYSTEMATIC_SUCCESS = 100;
  FAST_PASS_THRESHOLD = 125;
var
  LRandomTileSearch: TArray<TXcomPosition>;
  LTarget: TXcomPosition;
  LBestScore: Integer;
  LOffset: TXcomPosition;
  LPosition: TXcomPosition;
  LTile: TXcomTile;
  LScore: Integer;
  LOrigin: TXcomPosition;
begin
  if not SelectClosestKnownEnemy then
    Exit(False);
  LRandomTileSearch := Copy(FSave.TileSearch);
  Shuffle(LRandomTileSearch);
  LBestScore := 0;
  FModule.AttackAction.ActionType := BA_RETHINK;
  for LOffset in LRandomTileSearch do
  begin
    LPosition := FUnit.Position + LOffset;
    LTile := FSave.TileAt(LPosition);
    if (not Assigned(LTile)) or (not Contains(FModule.ReachableWithAttack, FSave.TileIndex(LPosition))) then
      Continue;
    LOrigin := (LPosition * TXcomPosition.Make(16, 16, 24)) +
      TXcomPosition.Make(8, 8, FUnit.GetHeight + FUnit.FloatHeight - LTile.GetTerrainLevel - 4);
    if FEngine.CanTargetUnit(LOrigin, FModule.AggroTarget.Tile, LTarget, FUnit, False) then
    begin
      FPathfinding.Calculate(FUnit, LPosition);
      if FPathfinding.GetStartDirection <> -1 then
      begin
        LScore := BASE_SYSTEMATIC_SUCCESS - GetSpottingUnits(LPosition) * 10;
        Inc(LScore, FUnit.TimeUnits - FPathfinding.TotalTuCost);
        if not FModule.AggroTarget.CheckViewSector(LPosition) then
          Inc(LScore, 10);
        if LScore > LBestScore then
        begin
          LBestScore := LScore;
          FModule.AttackAction.Target := LPosition;
          FModule.AttackAction.FinalFacing := FEngine.GetDirectionTo(LPosition, FModule.AggroTarget.Position);
          if LScore > FAST_PASS_THRESHOLD then
            Break;
        end;
      end;
    end;
  end;
  if LBestScore > 70 then
  begin
    FModule.AttackAction.ActionType := BA_WALK;
    Exit(True);
  end;
  Result := False;
end;

function TXcomAIThinker.WorthExploding(const ATargetPosition: TXcomPosition; const AAttackingUnit: TXcomBattleUnit;
  ARadius, ADifficulty: Integer): Boolean;
begin
  Result := ExplosiveEfficacy(ATargetPosition, AAttackingUnit, ARadius, ADifficulty);
end;

function TXcomAIThinker.ExplosiveEfficacy(const ATargetPosition: TXcomPosition;
  const AAttackingUnit: TXcomBattleUnit; ARadius, ADifficulty: Integer; AGrenade: Boolean): Boolean;
var
  LTargetTile: TXcomTile;
  LDistance: Integer;
  LInjuryLevel: Integer;
  LDesperation: Integer;
  LEnemiesAffected: Integer;
  LEfficacy: Integer;
  LTarget: TXcomBattleUnit;
  LUnit: TXcomBattleUnit;
  LVoxelA: TXcomPosition;
  LVoxelB: TXcomPosition;
  LTrajectory: TList<TXcomPosition>;
  LCollides: Integer;
begin
  if ((not AGrenade) and (FSave.Turn < FConfig.TurnUseBlaster)) or
    (AGrenade and (FSave.Turn < FConfig.TurnUseGrenade)) then
    Exit(False);
  LTargetTile := FSave.TileAt(ATargetPosition);
  if AGrenade and (ATargetPosition.Z > 0) and
    LTargetTile.HasNoFloor(FSave.TileAt(ATargetPosition - TXcomPosition.Make(0, 0, 1))) then
    Exit(False);
  if ADifficulty = -1 then
    ADifficulty := FConfig.DifficultyCoefficient;
  LDistance := FEngine.Distance(AAttackingUnit.Position, ATargetPosition);
  LInjuryLevel := AAttackingUnit.Stats.Health - AAttackingUnit.Health;
  LDesperation := (100 - AAttackingUnit.Morale) div 10;
  LEnemiesAffected := 0;
  if LInjuryLevel > (AAttackingUnit.Stats.Health div 3) * 2 then
    Inc(LDesperation, 3);
  LEfficacy := LDesperation;
  // we are within the blast radius: bad
  if (Abs(AAttackingUnit.Position.Z - ATargetPosition.Z) <= FConfig.ExplosionHeight) and (LDistance <= ARadius) then
    Dec(LEfficacy, 4);
  Inc(LEfficacy, ADifficulty div 2);
  LTarget := LTargetTile.CurrentUnit;
  if Assigned(LTarget) and (not LTargetTile.Dangerous) then
  begin
    Inc(LEnemiesAffected);
    Inc(LEfficacy);
  end;
  LTrajectory := TList<TXcomPosition>.Create;
  try
    for LUnit in FSave.Units do
    begin
      if (not LUnit.IsOut) and (LUnit <> AAttackingUnit) and (LUnit <> LTarget) and
        (Abs(LUnit.Position.Z - ATargetPosition.Z) <= FConfig.ExplosionHeight) and
        (FEngine.Distance(LUnit.Position, ATargetPosition) <= ARadius) then
      begin
        if LUnit.Tile.Dangerous or ((LUnit.Faction = FModule.TargetFaction) and
          (LUnit.TurnsSinceSpotted > FModule.Intelligence)) then
          Continue;
        // the explosion at the target position may reach the unit: a line between the two centers
        LVoxelA := TXcomPosition.Make(ATargetPosition.X * 16 + 8, ATargetPosition.Y * 16 + 8, ATargetPosition.Z * 24 + 12);
        LVoxelB := TXcomPosition.Make(LUnit.Position.X * 16 + 8, LUnit.Position.Y * 16 + 8, LUnit.Position.Z * 24 + 12);
        LTrajectory.Clear;
        LCollides := FEngine.CalculateLine(LVoxelA, LVoxelB, False, LTrajectory, LTarget, True, False, LUnit);
        if (LCollides = V_UNIT) and (LTrajectory.First div TXcomPosition.Make(16, 16, 24) = LUnit.Position) then
        begin
          if LUnit.Faction = FModule.TargetFaction then
          begin
            Inc(LEnemiesAffected);
            Inc(LEfficacy);
          end
          else if (LUnit.Faction = AAttackingUnit.Faction) or ((AAttackingUnit.Faction = FACTION_NEUTRAL) and
            (LUnit.Faction = FACTION_PLAYER)) then
            Dec(LEfficacy, 2); // friendlies count double
        end;
      end;
    end;
  finally
    LTrajectory.Free;
  end;
  // do not throw a grenade for one or no enemies when not desperate
  if AGrenade and (LDesperation < 6) and (LEnemiesAffected < 2) then
    Exit(False);
  Result := (LEfficacy > 0) or (LEnemiesAffected >= 10);
end;

procedure TXcomAIThinker.MeleeAction;
var
  LAttackCost: Integer;
  LChargeReserve: Integer;
  LDistance: Integer;
  LNewDistance: Integer;
  LUnit: TXcomBattleUnit;
  LDestination: TXcomPosition;
begin
  LAttackCost := FUnit.GetActionTus(BA_HIT, FUnit.GetMeleeWeapon);
  if FUnit.TimeUnits < LAttackCost then
    Exit;
  // a target that is in range: attack
  if Assigned(FModule.AggroTarget) and (not FModule.AggroTarget.IsOut) then
  begin
    if FEngine.ValidMeleeRange(FUnit, FModule.AggroTarget,
      FEngine.GetDirectionTo(FUnit.Position, FModule.AggroTarget.Position)) then
    begin
      MeleeAttack;
      Exit;
    end;
  end;
  // the time units that remain after the attack are the distance that can be charged
  LChargeReserve := FUnit.TimeUnits - LAttackCost;
  LDistance := (LChargeReserve div 4) + 1;
  FModule.AggroTarget := nil;
  for LUnit in FSave.Units do
  begin
    LNewDistance := FEngine.Distance(FUnit.Position, LUnit.Position);
    if (LNewDistance > 20) or (not ValidTarget(LUnit, True, FUnit.Faction = FACTION_HOSTILE)) then
      Continue;
    // pick the closest target: do not take one that is out of reach
    if ((LNewDistance < LDistance) or (LNewDistance = 1)) and (not LUnit.IsOut) then
    begin
      if (LNewDistance = 1) or SelectPointNearTarget(LUnit, LChargeReserve) then
      begin
        FModule.AggroTarget := LUnit;
        FModule.AttackAction.ActionType := BA_WALK;
        FUnit.Charging := FModule.AggroTarget;
        LDistance := LNewDistance;
      end;
    end;
  end;
  if Assigned(FModule.AggroTarget) then
  begin
    if FEngine.ValidMeleeRange(FUnit, FModule.AggroTarget,
      FEngine.GetDirectionTo(FUnit.Position, FModule.AggroTarget.Position)) then
      MeleeAttack;
  end;
  LDestination := FUnit.Position;
end;

procedure TXcomAIThinker.WayPointAction;
var
  LAttackCost: Integer;
  LUnit: TXcomBattleUnit;
  LMaxWaypoints: Integer;
  LLastWayPoint: TXcomPosition;
  LLastPosition: TXcomPosition;
  LCurrentPosition: TXcomPosition;
  LPathDirection: Integer;
  LVoxelA: TXcomPosition;
  LVoxelB: TXcomPosition;
  LCollidesWith: Integer;
  LTarget: TXcomBattleUnit;
  LIndex: Integer;
begin
  LAttackCost := FUnit.GetActionTus(BA_LAUNCH, FModule.AttackAction.Weapon);
  if FUnit.TimeUnits < LAttackCost then
    Exit;
  FModule.AggroTarget := nil;
  LIndex := 0;
  while (LIndex < FSave.Units.Count) and (not Assigned(FModule.AggroTarget)) do
  begin
    LUnit := FSave.Units[LIndex];
    Inc(LIndex);
    if not ValidTarget(LUnit, True, FUnit.Faction = FACTION_HOSTILE) then
      Continue;
    FPathfinding.Calculate(FUnit, LUnit.Position, LUnit, -1);
    if (FPathfinding.GetStartDirection <> -1) and
      ExplosiveEfficacy(LUnit.Position, FUnit, (FModule.AttackAction.Weapon.AmmoItem.Rules.Power div 20) + 1,
      FModule.AttackAction.Diff) then
      FModule.AggroTarget := LUnit;
    FPathfinding.AbortPath;
  end;
  if Assigned(FModule.AggroTarget) then
  begin
    FModule.AttackAction.ActionType := BA_LAUNCH;
    FModule.AttackAction.TimeUnits := FUnit.GetActionTus(BA_LAUNCH, FModule.AttackAction.Weapon);
    if FModule.AttackAction.TimeUnits > FUnit.TimeUnits then
    begin
      FModule.AttackAction.ActionType := BA_RETHINK;
      Exit;
    end;
    FModule.AttackAction.Waypoints.Clear;
    LMaxWaypoints := FModule.AttackAction.Weapon.Rules.Waypoints;
    if LMaxWaypoints = 0 then
      LMaxWaypoints := FModule.AttackAction.Weapon.AmmoItem.Rules.Waypoints;
    if LMaxWaypoints = -1 then
      LMaxWaypoints := 6 + (FModule.AttackAction.Diff * 2);
    LLastWayPoint := FUnit.Position;
    LCurrentPosition := FUnit.Position;
    FPathfinding.Calculate(FUnit, FModule.AggroTarget.Position, FModule.AggroTarget, -1);
    LPathDirection := FPathfinding.DequeuePath;
    while (LPathDirection <> -1) and (FModule.AttackAction.Waypoints.Count < LMaxWaypoints) do
    begin
      LLastPosition := LCurrentPosition;
      LCurrentPosition := LCurrentPosition + TXcomDirections.ToVector(LPathDirection);
      LVoxelA := TXcomPosition.Make(LCurrentPosition.X * 16 + 8, LCurrentPosition.Y * 16 + 8,
        LCurrentPosition.Z * 24 + 16);
      LVoxelB := TXcomPosition.Make(LLastWayPoint.X * 16 + 8, LLastWayPoint.Y * 16 + 8, LLastWayPoint.Z * 24 + 16);
      LCollidesWith := FEngine.CalculateLine(LVoxelA, LVoxelB, False, nil, FUnit, True);
      if (LCollidesWith > V_EMPTY) and (LCollidesWith < V_UNIT) then
      begin
        FModule.AttackAction.Waypoints.Add(LLastPosition);
        LLastWayPoint := LLastPosition;
      end
      else if LCollidesWith = V_UNIT then
      begin
        LTarget := FSave.TileAt(LCurrentPosition).CurrentUnit;
        if LTarget = FModule.AggroTarget then
        begin
          FModule.AttackAction.Waypoints.Add(LCurrentPosition);
          LLastWayPoint := LCurrentPosition;
        end;
      end;
      LPathDirection := FPathfinding.DequeuePath;
    end;
    FModule.AttackAction.Target := FModule.AttackAction.Waypoints.First;
    if LLastWayPoint <> FModule.AggroTarget.Position then
      FModule.AttackAction.ActionType := BA_RETHINK;
  end;
end;

procedure TXcomAIThinker.ProjectileAction;
var
  LAmmoRules: TXcomRuleItem;
begin
  FModule.AttackAction.Target := FModule.AggroTarget.Position;
  LAmmoRules := FModule.AttackAction.Weapon.AmmoItem.Rules;
  if (LAmmoRules.ExplosionRadius = 0) or ExplosiveEfficacy(FModule.AggroTarget.Position, FUnit,
    LAmmoRules.ExplosionRadius, FModule.AttackAction.Diff) then
    SelectFireMethod;
end;

procedure TXcomAIThinker.SelectFireMethod;
var
  LDistance: Integer;
  LTuAuto: Integer;
  LTuSnap: Integer;
  LTuAimed: Integer;
  LCurrentTu: Integer;
  LWeapon: TXcomBattleItem;
begin
  LDistance := FEngine.Distance(FUnit.Position, FModule.AttackAction.Target);
  FModule.AttackAction.ActionType := BA_RETHINK;
  LWeapon := FModule.AttackAction.Weapon;
  LTuAuto := LWeapon.Rules.TimeUnitsAuto;
  LTuSnap := LWeapon.Rules.TimeUnitsSnap;
  LTuAimed := LWeapon.Rules.TimeUnitsAimed;
  LCurrentTu := FUnit.TimeUnits;
  if LDistance < 4 then
  begin
    if (LTuAuto <> 0) and (LCurrentTu >= FUnit.GetActionTus(BA_AUTOSHOT, LWeapon)) then
    begin
      FModule.AttackAction.ActionType := BA_AUTOSHOT;
      Exit;
    end;
    if (LTuSnap = 0) or (LCurrentTu < FUnit.GetActionTus(BA_SNAPSHOT, LWeapon)) then
    begin
      if (LTuAimed <> 0) and (LCurrentTu >= FUnit.GetActionTus(BA_AIMEDSHOT, LWeapon)) then
        FModule.AttackAction.ActionType := BA_AIMEDSHOT;
      Exit;
    end;
    FModule.AttackAction.ActionType := BA_SNAPSHOT;
    Exit;
  end;
  if LDistance > 12 then
  begin
    if (LTuAimed <> 0) and (LCurrentTu >= FUnit.GetActionTus(BA_AIMEDSHOT, LWeapon)) then
    begin
      FModule.AttackAction.ActionType := BA_AIMEDSHOT;
      Exit;
    end;
    if (LDistance < 20) and (LTuSnap <> 0) and (LCurrentTu >= FUnit.GetActionTus(BA_SNAPSHOT, LWeapon)) then
    begin
      FModule.AttackAction.ActionType := BA_SNAPSHOT;
      Exit;
    end;
  end;
  if (LTuSnap <> 0) and (LCurrentTu >= FUnit.GetActionTus(BA_SNAPSHOT, LWeapon)) then
  begin
    FModule.AttackAction.ActionType := BA_SNAPSHOT;
    Exit;
  end;
  if (LTuAimed <> 0) and (LCurrentTu >= FUnit.GetActionTus(BA_AIMEDSHOT, LWeapon)) then
  begin
    FModule.AttackAction.ActionType := BA_AIMEDSHOT;
    Exit;
  end;
  if (LTuAuto <> 0) and (LCurrentTu >= FUnit.GetActionTus(BA_AUTOSHOT, LWeapon)) then
    FModule.AttackAction.ActionType := BA_AUTOSHOT;
end;

procedure TXcomAIThinker.GrenadeAction;
var
  LGrenade: TXcomBattleItem;
  LTu: Integer;
  LAction: TXcomBattleAction;
  LOriginVoxel: TXcomPosition;
  LTargetVoxel: TXcomPosition;
  LCurve: Double;
  LVoxelType: Integer;
begin
  // do we have a grenade on our belt?
  LGrenade := FUnit.GetGrenadeFromBelt;
  LTu := 4; // 4 time units for picking up the grenade
  Inc(LTu, FUnit.GetActionTus(BA_PRIME, LGrenade));
  Inc(LTu, FUnit.GetActionTus(BA_THROW, LGrenade));
  // do we have enough time units to prime and throw the grenade?
  if LTu <= FUnit.TimeUnits then
  begin
    LAction := TXcomBattleAction.Create;
    try
      LAction.Weapon := LGrenade;
      LAction.ActionType := BA_THROW;
      LAction.Actor := FUnit;
      if ExplosiveEfficacy(FModule.AggroTarget.Position, FUnit, LGrenade.Rules.ExplosionRadius,
        FModule.AttackAction.Diff, True) then
        LAction.Target := FModule.AggroTarget.Position
      else if not GetNodeOfBestEfficacy(LAction) then
        Exit;
      LOriginVoxel := FEngine.GetOriginVoxel(LAction, nil);
      LTargetVoxel := LAction.Target * TXcomPosition.Make(16, 16, 24) +
        TXcomPosition.Make(8, 8, 2 + -FSave.TileAt(LAction.Target).GetTerrainLevel);
      LCurve := 0;
      LVoxelType := 0;
      if FEngine.ValidateThrow(LAction, LOriginVoxel, LTargetVoxel, LCurve, LVoxelType, False) then
      begin
        FModule.AttackAction.Weapon := LGrenade;
        FModule.AttackAction.Target := LAction.Target;
        FModule.AttackAction.ActionType := BA_THROW;
        FModule.AttackAction.TimeUnits := LTu;
        FModule.Rifle := False;
        FModule.Melee := False;
      end;
    finally
      LAction.Free;
    end;
  end;
end;

function TXcomAIThinker.PsiAction: Boolean;
var
  LItem: TXcomBattleItem;
  LRules: TXcomRuleItem;
  LCost: Integer;
  LCostFloat: Single;
  LLosRequired: Boolean;
  LPsiAttackStrength: Integer;
  LChanceToAttack: Integer;
  LUnit: TXcomBattleUnit;
  LChanceToAttackMe: Integer;
  LValue: Double;
  LTerm: Double;
  LControlOdds: Integer;
  LMorale: Integer;
  LBravery: Integer;
  LVisible: Boolean;
  LOther: TXcomBattleUnit;
begin
  LItem := FUnit.GetSpecialWeapon(TXcomRuleItem.BT_PSIAMP);
  if not Assigned(LItem) then
    Exit(False);
  LRules := LItem.Rules;
  LCost := LRules.TimeUnitsUse;
  if not LRules.FlatRate then
  begin
    LCostFloat := Single(FUnit.Stats.TimeUnits * LCost);
    LCostFloat := LCostFloat / 100.0;
    LCost := Floor(LCostFloat);
  end;
  LLosRequired := LRules.LineOfSightRequired;
  FModule.AggroTarget := nil;
  if (FUnit.OriginalFaction = FUnit.Faction) and (FUnit.TimeUnits > FModule.EscapeTus + LCost) and
    (not FModule.DidPsi) then
  begin
    LPsiAttackStrength := FUnit.Stats.PsiSkill * FUnit.Stats.PsiStrength div 50;
    LChanceToAttack := 0;
    for LUnit in FSave.Units do
    begin
      LVisible := False;
      if LLosRequired then
        for LOther in FUnit.VisibleUnits do
          if LOther = LUnit then
            LVisible := True;
      if (LUnit.Armor.Size = 1) and ValidTarget(LUnit, True, False) and
        (LUnit.OriginalFaction = FModule.TargetFaction) and ((not LLosRequired) or LVisible) then
      begin
        // the sum is a double (a term of 0.4 times the skill): the integers are converted one after the other
        LValue := LPsiAttackStrength;
        if LUnit.Stats.PsiSkill > 0 then
        begin
          LTerm := LUnit.Stats.PsiSkill * -0.4;
          LValue := LValue + LTerm;
        end
        else
          LValue := LValue + 0;
        LValue := LValue - FEngine.Distance(LUnit.Position, FUnit.Position);
        LValue := LValue - LUnit.Stats.PsiStrength;
        LValue := LValue + Random(55, 105);
        LChanceToAttackMe := Trunc(LValue);
        if LChanceToAttackMe > LChanceToAttack then
        begin
          LChanceToAttack := LChanceToAttackMe;
          FModule.AggroTarget := LUnit;
        end;
      end;
    end;
    if (not Assigned(FModule.AggroTarget)) or (LChanceToAttack = 0) then
      Exit(False);
    if (FModule.VisibleEnemies <> 0) and Assigned(FModule.AttackAction.Weapon) and
      Assigned(FModule.AttackAction.Weapon.AmmoItem) then
    begin
      if FModule.AttackAction.Weapon.AmmoItem.Rules.Power >= LChanceToAttack then
        Exit(False);
    end
    else if Random(35, 155) >= LChanceToAttack then
      Exit(False);
    if LChanceToAttack >= 30 then
    begin
      LControlOdds := 40;
      LMorale := FModule.AggroTarget.Morale;
      LBravery := (110 - FModule.AggroTarget.Stats.Bravery) div 10;
      if LBravery > 6 then
        Dec(LControlOdds, 15);
      if LBravery < 4 then
        Inc(LControlOdds, 15);
      if LMorale >= 40 then
      begin
        if LMorale - 10 * LBravery < 50 then
          Dec(LControlOdds, 15);
      end
      else
        Inc(LControlOdds, 15);
      if LMorale = 0 then
        LControlOdds := 100;
      if Percent(LControlOdds) then
      begin
        FModule.PsiAction.ActionType := BA_MINDCONTROL;
        FModule.PsiAction.Target := FModule.AggroTarget.Position;
        FModule.PsiAction.Weapon := LItem;
        Exit(True);
      end;
    end;
    FModule.PsiAction.ActionType := BA_PANIC;
    FModule.PsiAction.Target := FModule.AggroTarget.Position;
    FModule.PsiAction.Weapon := LItem;
    Exit(True);
  end;
  Result := False;
end;

procedure TXcomAIThinker.MeleeAttack;
begin
  FUnit.LookAt(FModule.AggroTarget.Position + TXcomPosition.Make(FUnit.Armor.Size - 1, FUnit.Armor.Size - 1, 0),
    False);
  while FUnit.Status = STATUS_TURNING do
    FUnit.Turn;
  FModule.AttackAction.Target := FModule.AggroTarget.Position;
  FModule.AttackAction.ActionType := BA_HIT;
  FModule.AttackAction.Weapon := FUnit.GetMeleeWeapon;
end;

function TXcomAIThinker.ValidTarget(const AUnit: TXcomBattleUnit; AAssessDanger, AIncludeCivilians: Boolean): Boolean;
begin
  // ignore units that are dead or unconscious, that the alien has not seen for too long, that are in a dangerous
  // tile or of the same faction
  if AUnit.IsOut or ((FUnit.Faction = FACTION_HOSTILE) and (FModule.Intelligence < AUnit.TurnsSinceSpotted)) or
    (AAssessDanger and AUnit.Tile.Dangerous) or (AUnit.Faction = FUnit.Faction) then
    Exit(False);
  if AIncludeCivilians then
    Exit(True);
  Result := AUnit.Faction = FModule.TargetFaction;
end;

procedure TXcomAIThinker.SelectMeleeOrRanged;
var
  LRangedWeapon: TXcomRuleItem;
  LMeleeWeapon: TXcomRuleItem;
  LMeleeOdds: Integer;
  LDamage: Integer;
  LDamageFloat: Single;
begin
  LRangedWeapon := FModule.AttackAction.Weapon.Rules;
  if (FUnit.GetMeleeWeapon <> nil) then
    LMeleeWeapon := FUnit.GetMeleeWeapon.Rules
  else
    LMeleeWeapon := nil;
  if not Assigned(LMeleeWeapon) then
  begin
    FModule.Melee := False;
    Exit;
  end;
  if (not Assigned(LRangedWeapon)) or (not Assigned(FModule.AttackAction.Weapon.AmmoItem)) then
  begin
    FModule.Rifle := False;
    Exit;
  end;
  // the melee odds: 10, plus the damage over 50 over two, minus 20 for each visible enemy but the first
  LMeleeOdds := 10;
  LDamage := LMeleeWeapon.Power;
  if LMeleeWeapon.StrengthApplied then
    Inc(LDamage, FUnit.Stats.Strength);
  // int *= float: the product is a float
  LDamageFloat := LDamage;
  LDamageFloat := LDamageFloat * FModule.AggroTarget.Armor.DamageModifier[LMeleeWeapon.DamageType];
  LDamage := Trunc(LDamageFloat);
  if LDamage > 50 then
    Inc(LMeleeOdds, (LDamage - 50) div 2);
  if FModule.VisibleEnemies > 1 then
    Dec(LMeleeOdds, 20 * (FModule.VisibleEnemies - 1));
  if (LMeleeOdds > 0) and (FUnit.Health >= 2 * FUnit.Stats.Health div 3) then
  begin
    if FUnit.Aggression = 0 then
      Dec(LMeleeOdds, 20)
    else if FUnit.Aggression > 1 then
      Inc(LMeleeOdds, 10 * FUnit.Aggression);
    if Percent(LMeleeOdds) then
    begin
      // no ranged attack
      FModule.Rifle := False;
      FModule.ReachableWithAttack := FPathfinding.FindReachable(FUnit,
        FUnit.TimeUnits - FUnit.GetActionTus(BA_HIT, FUnit.GetMeleeWeapon));
      Exit;
    end;
  end;
  // no melee attack
  FModule.Melee := False;
end;

function TXcomAIThinker.GetNodeOfBestEfficacy(const AAction: TXcomBattleAction): Boolean;
var
  LBestScore: Integer;
  LOriginVoxel: TXcomPosition;
  LTargetVoxel: TXcomPosition;
  LNode: TXcomNode;
  LUnit: TXcomBattleUnit;
  LDistance: Integer;
  LNodePoints: Integer;
  LTargetOriginVoxel: TXcomPosition;
begin
  if FSave.Turn < FConfig.TurnUseGrenade then
    Exit(False);
  LBestScore := 2;
  LOriginVoxel := FEngine.GetSightOriginVoxel(FUnit);
  for LNode in FSave.Nodes do
  begin
    if LNode.Dummy then
      Continue;
    LDistance := FEngine.Distance(LNode.Position, FUnit.Position);
    if (LDistance <= 20) and (LDistance > AAction.Weapon.Rules.ExplosionRadius) and
      FEngine.CanTargetTile(LOriginVoxel, FSave.TileAt(LNode.Position), XCOM_PART_FLOOR, LTargetVoxel, FUnit, False) then
    begin
      LNodePoints := 0;
      for LUnit in FSave.Units do
      begin
        LDistance := FEngine.Distance(LNode.Position, LUnit.Position);
        if (not LUnit.IsOut) and (LDistance < AAction.Weapon.Rules.ExplosionRadius) then
        begin
          LTargetOriginVoxel := FEngine.GetSightOriginVoxel(LUnit);
          if FEngine.CanTargetTile(LTargetOriginVoxel, FSave.TileAt(LNode.Position), XCOM_PART_FLOOR, LTargetVoxel,
            LUnit, False) then
          begin
            if ((FUnit.Faction = FACTION_HOSTILE) and (LUnit.Faction <> FACTION_HOSTILE)) or
              ((FUnit.Faction = FACTION_NEUTRAL) and (LUnit.Faction = FACTION_HOSTILE)) then
            begin
              if LUnit.TurnsSinceSpotted <= FModule.Intelligence then
                Inc(LNodePoints);
            end
            else
              Dec(LNodePoints, 2);
          end;
        end;
      end;
      if LNodePoints > LBestScore then
      begin
        LBestScore := LNodePoints;
        AAction.Target := LNode.Position;
      end;
    end;
  end;
  Result := LBestScore > 2;
end;

end.
