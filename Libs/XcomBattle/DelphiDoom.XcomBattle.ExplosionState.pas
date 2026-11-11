{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - an explosion or a hit in the list of  }
{  steps (ExplosionBState)                                                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.ExplosionState;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.State.Intf, DelphiDoom.XcomBattle.Host.Intf,
  DelphiDoom.XcomBattle.Game.Intf;

type
  /// <summary>
  ///   The step that carries an explosion (a grenade, a blast, a unit that explodes when it dies) or the hit of a
  ///   bullet: the animation starts in Init (and takes the random numbers of the sprites) and when it is over
  ///   Think applies the effects with the tile engine
  /// </summary>
  TXcomExplosionState = class(TInterfacedObject, IXcomBattleState)
  strict private
    FHost: IXcomBattleHost;
    FGame: IXcomBattlescapeGame;
    FUnit: TXcomBattleUnit;
    FCenter: TXcomPosition;
    FItem: TXcomBattleItem;
    FTile: TXcomTile;
    FLowerWeapon: Boolean;
    FCosmetic: Boolean;
    FPower: Integer;
    FAreaOfEffect: Boolean;
    function Game: IXcomBattlescapeGame;
    procedure Explode;
  public
    /// <param name="ACenter">Center in voxels</param>
    /// <param name="AItem">Item involved (a grenade), or nil</param>
    /// <param name="AUnit">Unit that causes it, or nil</param>
    /// <param name="ATile">Tile that explodes (a chained explosion), or nil</param>
    /// <param name="ALowerWeapon">Whether the unit puts the weapon down at the end</param>
    /// <param name="ACosmetic">Only the animation, without effects</param>
    constructor Create(const AHost: IXcomBattleHost; const ACenter: TXcomPosition; const AItem: TXcomBattleItem;
      const AUnit: TXcomBattleUnit; const ATile: TXcomTile; ALowerWeapon: Boolean = True; ACosmetic: Boolean = False);
    procedure Init;
    procedure Think;
    procedure Cancel;
    procedure Deinit;
    function StateName: string;
    function Action: TXcomBattleAction;
    /// <summary>The power and whether it hits an area, as the init decided (for the traces)</summary>
    function Description: string;
    property Center: TXcomPosition read FCenter;
    property Item: TXcomBattleItem read FItem;
    property CausingUnit: TXcomBattleUnit read FUnit;
    property Tile: TXcomTile read FTile;
    property LowerWeapon: Boolean read FLowerWeapon;
    property Cosmetic: Boolean read FCosmetic;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem;

const
  SNotAFullGame = 'The explosion step needs the game in progress (IXcomBattlescapeGame) as its host';
  EXPLODE_FRAMES = 8;

constructor TXcomExplosionState.Create(const AHost: IXcomBattleHost; const ACenter: TXcomPosition;
  const AItem: TXcomBattleItem; const AUnit: TXcomBattleUnit; const ATile: TXcomTile; ALowerWeapon, ACosmetic: Boolean);
begin
  inherited Create;
  FHost := AHost;
  FCenter := ACenter;
  FItem := AItem;
  FUnit := AUnit;
  FTile := ATile;
  FLowerWeapon := ALowerWeapon;
  FCosmetic := ACosmetic;
end;

function TXcomExplosionState.Game: IXcomBattlescapeGame;
begin
  if not Assigned(FGame) then
    if not Supports(FHost, IXcomBattlescapeGame, FGame) then
      raise EXcomBattleException.Create(SNotAFullGame);
  Result := FGame;
end;

function TXcomExplosionState.Action: TXcomBattleAction;
begin
  Result := nil;
end;

function TXcomExplosionState.Description: string;
begin
  Result := Format('p=%d aoe=%d c=%d/%d/%d', [FPower, Ord(FAreaOfEffect), FCenter.X, FCenter.Y, FCenter.Z]);
end;

procedure TXcomExplosionState.Init;
var
  LGame: IXcomBattlescapeGame;
  LFrame: Integer;
  LDelay: Integer;
  LCounter: Integer;
  LLimit: Integer;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LTile: TXcomTile;
  LAnimation: Integer;
  LSound: Integer;
  LTarget: TXcomBattleUnit;
  LPosition: TXcomPosition;
begin
  LGame := Game;
  if Assigned(FItem) then
  begin
    FPower := FItem.Rules.Power;
    // this usually only applies to melee, but as a concession for modders it is here in case they want a bow
    if FItem.Rules.StrengthApplied and Assigned(FUnit) then
      Inc(FPower, FUnit.Stats.Strength);
    FAreaOfEffect := (FItem.Rules.BattleType <> TXcomRuleItem.BT_MELEE) and (FItem.Rules.ExplosionRadius <> 0) and
      (not FCosmetic);
  end
  else if Assigned(FTile) then
  begin
    FPower := FTile.Explosive;
    FAreaOfEffect := True;
  end
  else if Assigned(FUnit) and ((FUnit.SpecialAbility = SPECAB_EXPLODEONDEATH) or
    (FUnit.SpecialAbility = SPECAB_BURN_AND_EXPLODE)) then
  begin
    FPower := LGame.Ruleset.Items.Find(FUnit.Armor.CorpseGeoscape).Power;
    FAreaOfEffect := True;
  end
  else
  begin
    FPower := 120;
    FAreaOfEffect := True;
  end;
  LTile := LGame.Save.TileAt(TXcomPosition.Make(FCenter.X div 16, FCenter.Y div 16, FCenter.Z div 24));
  if FAreaOfEffect then
  begin
    if FPower <> 0 then
    begin
      LFrame := LGame.Ruleset.Constants.ExplosionOffset;
      if Assigned(FItem) then
        LFrame := FItem.Rules.HitAnimation;
      if LGame.Depth > 0 then
        Dec(LFrame, EXPLODE_FRAMES);
      LDelay := 0;
      LCounter := Max(1, (FPower div 5) div 5);
      LGame.View.SetBlastFlash(True);
      LLimit := Max(1, FPower div 5);
      for LIndex := 0 to LLimit - 1 do
      begin
        LX := LGame.Save.Random.Generate(-FPower div 2, FPower div 2);
        LY := LGame.Save.Random.Generate(-FPower div 2, FPower div 2);
        LGame.View.AddExplosion(TXcomPosition.Make(FCenter.X + LX, FCenter.Y + LY, FCenter.Z), LFrame, LDelay, True,
          False);
        if (LIndex > 0) and (LIndex mod LCounter = 0) then
          Inc(LDelay);
      end;
      LGame.View.SetStateInterval(15);
      if FPower <= 80 then
        LGame.View.PlaySound(LGame.Ruleset.Constants.SmallExplosion, TXcomPosition.Make(-1, -1, -1))
      else
        LGame.View.PlaySound(LGame.Ruleset.Constants.LargeExplosion, TXcomPosition.Make(-1, -1, -1));
      LGame.View.CenterOnPosition(LTile.Position, False);
    end
    else
      LGame.PopState;
  end
  else
  begin
    // create a bullet hit
    LGame.View.SetStateInterval(Max(1, 15 - 10 * FItem.Rules.ExplosionSpeed));
    LAnimation := FItem.Rules.HitAnimation;
    LSound := FItem.Rules.HitSound;
    if FCosmetic then
      LAnimation := FItem.Rules.MeleeAnimation;
    if LAnimation <> -1 then
      LGame.View.AddExplosion(FCenter, LAnimation, 0, False, FCosmetic);
    LGame.View.SetViewLevel(FCenter.Z div 24);
    LTarget := LTile.CurrentUnit;
    if FCosmetic and (LGame.Save.Side = FACTION_HOSTILE) and Assigned(LTarget) and
      (LTarget.Faction = FACTION_PLAYER) then
      LGame.View.CenterOnPosition(LTile.Position, False);
    if (LSound <> -1) and (not FCosmetic) then
    begin
      LPosition := TXcomPosition.Make(FCenter.X div 16, FCenter.Y div 16, FCenter.Z div 24);
      LGame.View.PlaySound(LSound, LPosition);
    end;
  end;
end;

procedure TXcomExplosionState.Think;
begin
  if not Game.View.BlastFlash then
    if Game.View.AnimateExplosions then
      Explode;
end;

procedure TXcomExplosionState.Explode;
var
  LGame: IXcomBattlescapeGame;
  LTerrainExplosion: Boolean;
  LVictim: TXcomBattleUnit;
  LDamageType: Integer;
  LRadius: Integer;
  LTile: TXcomTile;
  LPosition: TXcomPosition;
begin
  LGame := Game;
  LTerrainExplosion := False;
  // after the animation is done, the real explosion/hit takes place
  if Assigned(FItem) then
  begin
    if (not Assigned(FUnit)) and Assigned(FItem.PreviousOwner) then
      FUnit := FItem.PreviousOwner;
    LVictim := nil;
    if FAreaOfEffect then
      LGame.TileEngine.Explode(FCenter, FPower, FItem.Rules.DamageType, FItem.Rules.ExplosionRadius, FUnit)
    else if not FCosmetic then
      LVictim := LGame.TileEngine.Hit(FCenter, FPower, FItem.Rules.DamageType, FUnit);
    // check if this unit turns others into zombies
    if (FItem.Rules.ZombieUnit <> '') and Assigned(LVictim) and (LVictim.Armor.Size = 1) and
      (Assigned(LVictim.GeoscapeSoldier) or (LVictim.UnitRules.Race = 'STR_CIVILIAN')) and
      (LVictim.SpawnUnit = '') then
    begin
      // converts the victim to a zombie on death
      LVictim.Respawn := True;
      LVictim.SpawnUnit := FItem.Rules.ZombieUnit;
    end;
  end;
  if Assigned(FTile) then
  begin
    case FTile.ExplosiveType of
      0: LDamageType := TXcomRuleItem.DT_HE;
      5: LDamageType := TXcomRuleItem.DT_IN;
      6: LDamageType := TXcomRuleItem.DT_STUN;
    else
      LDamageType := TXcomRuleItem.DT_SMOKE;
    end;
    if LDamageType <> TXcomRuleItem.DT_HE then
      FTile.SetExplosive(0, 0, True);
    LGame.TileEngine.Explode(FCenter, FPower, LDamageType, FPower div 10);
    LTerrainExplosion := True;
  end;
  if (not Assigned(FTile)) and (not Assigned(FItem)) then
  begin
    LRadius := 6;
    // explosion not caused by terrain or an item, must be by a unit (cyberdisc)
    if Assigned(FUnit) and ((FUnit.SpecialAbility = SPECAB_EXPLODEONDEATH) or
      (FUnit.SpecialAbility = SPECAB_BURN_AND_EXPLODE)) then
      LRadius := LGame.Ruleset.Items.Find(FUnit.Armor.CorpseGeoscape).ExplosionRadius;
    LGame.TileEngine.Explode(FCenter, FPower, TXcomRuleItem.DT_HE, LRadius);
    LTerrainExplosion := True;
  end;
  if not FCosmetic then
    // now check for new casualties
    LGame.CheckForCasualties(FItem, FUnit, False, LTerrainExplosion);
  // if this explosion was caused by a unit shooting, now it's the time to put the gun down
  if Assigned(FUnit) and (not FUnit.IsOut) and FLowerWeapon then
  begin
    FUnit.Aim(False);
    FUnit.CacheInvalid := True;
  end;
  LGame.View.CacheUnits;
  LGame.PopState;
  // check for terrain explosions
  LTile := LGame.TileEngine.CheckForTerrainExplosions;
  if Assigned(LTile) then
  begin
    LPosition := TXcomPosition.Make(LTile.Position.X * 16 + 8, LTile.Position.Y * 16 + 8, LTile.Position.Z * 24);
    LGame.StatePushFront(TXcomExplosionState.Create(LGame, LPosition, nil, FUnit, LTile));
  end;
  if Assigned(FItem) and ((FItem.Rules.BattleType = TXcomRuleItem.BT_GRENADE) or
    (FItem.Rules.BattleType = TXcomRuleItem.BT_PROXIMITYGRENADE)) then
    LGame.Save.RemoveItem(FItem);
end;

procedure TXcomExplosionState.Cancel;
begin
  // explosions cannot be cancelled
end;

procedure TXcomExplosionState.Deinit;
begin
end;

function TXcomExplosionState.StateName: string;
begin
  Result := 'ExplosionBState';
end;

end.
