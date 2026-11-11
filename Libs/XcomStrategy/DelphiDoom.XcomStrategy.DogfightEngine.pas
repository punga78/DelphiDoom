{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the logic of a dogfight (DogfightState  }
{  without its window: update, weapons, UFO fire, the end of the combat)        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.DogfightEngine;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.RuleCraftWeapon, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.CraftWeapon, DelphiDoom.XcomSave.CraftWeaponProjectile, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomStrategy.LandMap.Intf, DelphiDoom.XcomStrategy.Dogfight.Listener.Intf;

type
  /// <summary>The attitude of the interceptor: the buttons of the window (the group of image buttons)</summary>
  TXcomDogfightMode = (dmStandoff, dmCautious, dmStandard, dmAggressive, dmDisengage);

  /// <summary>
  ///   One dogfight between a craft and a UFO: the distance, the weapons, the projectiles, the fire of the UFO,
  ///   the damage, the retaliation and the end. Think is what DogfightState::think does each step of the
  ///   dogfight timer; the window reads the state and is told what to show with IXcomDogfightListener.
  ///   Not ported: the window itself (see TXcomDogfightState in XcomGeoscape)
  /// </summary>
  TXcomDogfightEngine = class
  public
    const
      /// <summary>STANDOFF_DIST</summary>
      STANDOFF_DIST = 560;
  strict private
    FGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    FLand: IXcomLandMap;
    FListener: IXcomDogfightListener;
    FCraft: TXcomCraft;
    FUfo: TXcomUfo;
    FProjectiles: TObjectList<TXcomCraftWeaponProjectile>;
    FMode: TXcomDogfightMode;
    FTimeout: Integer;
    FCurrentDist: Integer;
    FTargetDist: Integer;
    FWeaponCountdown: array[0..1] of Integer;
    FWeaponInterval: array[0..1] of Integer;
    FWeaponEnabled: array[0..1] of Boolean;
    FEnd: Boolean;
    FDestroyUfo: Boolean;
    FDestroyCraft: Boolean;
    FUfoBreakingOff: Boolean;
    FMinimized: Boolean;
    FEndDogfight: Boolean;
    FAnimatingHit: Boolean;
    FWaitForPoly: Boolean;
    FWaitForAltitude: Boolean;
    FUfoSize: Integer;
    FInterceptionNumber: Integer;
    FStatusShown: Boolean;
    function Percent(AValue: Integer): Boolean;
    function WeaponAt(AIndex: Integer): TXcomCraftWeapon;
    function WeaponRule(AIndex: Integer): TXcomRuleCraftWeapon;
    function Difficulty: Integer;
    function CanAct: Boolean;
    function ShotDownByThisCraft: Boolean;
    procedure SetStatus(const AKey: string);
    procedure Animate;
    procedure Update;
    procedure FireWeapon(AIndex: Integer);
    procedure UfoFireWeapon;
    procedure MinimumDistance;
    procedure MaximumDistance;
    procedure SetWeaponIntervals(AWhich: Integer);
    procedure Retaliate;
    procedure ScoreForXcom(APoints: Integer);
    procedure EndDogfight;
  public
    /// <param name="AGame">The saved game (not owned)</param>
    /// <param name="ARuleset">The ruleset (not owned)</param>
    /// <param name="ACraft">The craft that intercepts (not owned)</param>
    /// <param name="AUfo">The UFO (not owned)</param>
    /// <param name="AListener">What shows the dogfight (nil: nobody)</param>
    constructor Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset; const ARandom: IXcomRandom;
      const ALand: IXcomLandMap; const AListener: IXcomDogfightListener; const ACraft: TXcomCraft;
      const AUfo: TXcomUfo);
    destructor Destroy; override;
    /// <summary>DogfightState::think</summary>
    procedure Think;
    /// <summary>The button of an attitude was pressed (the group sets the mode, then the handler acts)</summary>
    procedure PressMode(AMode: TXcomDogfightMode);
    /// <summary>btnMinimizeClick</summary>
    procedure MinimizeClick;
    /// <summary>btnMinimizedIconClick: the dogfight opens again unless the craft cannot engage</summary>
    procedure MinimizedIconClick;
    /// <summary>weapon1Click / weapon2Click: toggles the weapon</summary>
    procedure ToggleWeapon(AIndex: Integer);
    /// <summary>setMinimized</summary>
    procedure SetMinimized(AMinimized: Boolean);
    /// <summary>setInterceptionNumber</summary>
    procedure SetInterceptionNumber(ANumber: Integer);
    procedure SetWaitForPoly(AWait: Boolean);
    procedure SetWaitForAltitude(AWait: Boolean);
    property Craft: TXcomCraft read FCraft;
    property Ufo: TXcomUfo read FUfo;
    property Mode: TXcomDogfightMode read FMode;
    property CurrentDistance: Integer read FCurrentDist;
    property TargetDistance: Integer read FTargetDist;
    property Projectiles: TObjectList<TXcomCraftWeaponProjectile> read FProjectiles;
    property UfoSize: Integer read FUfoSize;
    property Minimized: Boolean read FMinimized;
    property Ended: Boolean read FEndDogfight;
    property InterceptionNumber: Integer read FInterceptionNumber;
    property WaitForPoly: Boolean read FWaitForPoly;
    property WaitForAltitude: Boolean read FWaitForAltitude;
    property Timeout: Integer read FTimeout;
    property AnimatingHit: Boolean read FAnimatingHit;
    function WeaponEnabled(AIndex: Integer): Boolean;
    /// <summary>The wait of the weapons between two shots (the attitude changes it)</summary>
    function WeaponInterval(AIndex: Integer): Integer;
    function WeaponCountdown(AIndex: Integer): Integer;
    property UfoBreakingOff: Boolean read FUfoBreakingOff;
    property DestroyUfo: Boolean read FDestroyUfo;
    property DestroyCraft: Boolean read FDestroyCraft;
    property Finishing: Boolean read FEnd;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomMod.RulesetSettings, DelphiDoom.XcomSave.AlienMission,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.Region, DelphiDoom.XcomSave.Country,
  DelphiDoom.XcomStrategy.Geography, DelphiDoom.XcomStrategy.RandomMission;

{ TXcomDogfightEngine }

constructor TXcomDogfightEngine.Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
  const ARandom: IXcomRandom; const ALand: IXcomLandMap; const AListener: IXcomDogfightListener;
  const ACraft: TXcomCraft; const AUfo: TXcomUfo);
var
  LBase: TXcomBase;
  LOther: TXcomCraft;
  LMax, LEscape: Integer;
begin
  inherited Create;
  FGame := AGame;
  FRuleset := ARuleset;
  FRandom := ARandom;
  FLand := ALand;
  FListener := AListener;
  FCraft := ACraft;
  FUfo := AUfo;
  FProjectiles := TObjectList<TXcomCraftWeaponProjectile>.Create(True);
  FMode := dmStandoff;
  FTimeout := 50;
  // the window starts with STR_STANDOFF
  FStatusShown := True;
  FCurrentDist := 640;
  FTargetDist := 560;
  FWeaponEnabled[0] := True;
  FWeaponEnabled[1] := True;
  FCraft.InDogfight := True;
  // the number on the minimized icon: the next one after those that are in use
  if FCraft.InterceptionOrder = 0 then
  begin
    LMax := 0;
    for LBase in FGame.Bases do
      for LOther in LBase.Crafts do
        if LOther.InterceptionOrder > LMax then
          LMax := LOther.InterceptionOrder;
    FCraft.InterceptionOrder := LMax + 1;
  end;
  // don't set these variables if the UFO is already engaged in a dogfight
  if FUfo.EscapeCountdown = 0 then
  begin
    FUfo.FireCountdown := 0;
    LEscape := FUfo.Rules.BreakOffTime + FRandom.Generate(0, FUfo.Rules.BreakOffTime) - 30 * Difficulty;
    FUfo.EscapeCountdown := Max(1, LEscape);
  end;
  if WeaponAt(0) <> nil then
    FWeaponInterval[0] := WeaponRule(0).StandardReload;
  if WeaponAt(1) <> nil then
    FWeaponInterval[1] := WeaponRule(1).StandardReload;
  // the size of the UFO on the radar
  if FUfo.Rules.Size = 'STR_VERY_SMALL' then
    FUfoSize := 0
  else if FUfo.Rules.Size = 'STR_SMALL' then
    FUfoSize := 1
  else if FUfo.Rules.Size = 'STR_MEDIUM_UC' then
    FUfoSize := 2
  else if FUfo.Rules.Size = 'STR_LARGE' then
    FUfoSize := 3
  else
    FUfoSize := 4;
end;

destructor TXcomDogfightEngine.Destroy;
begin
  FProjectiles.Free;
  inherited Destroy;
end;

function TXcomDogfightEngine.Percent(AValue: Integer): Boolean;
begin
  // RNG::percent
  Result := FRandom.Generate(0, 99) < AValue;
end;

function TXcomDogfightEngine.WeaponAt(AIndex: Integer): TXcomCraftWeapon;
begin
  if (AIndex < FCraft.Rules.Weapons) and (AIndex < FCraft.Weapons.Count) then
    Result := FCraft.Weapons[AIndex]
  else
    Result := nil;
end;

function TXcomDogfightEngine.WeaponRule(AIndex: Integer): TXcomRuleCraftWeapon;
begin
  Result := FRuleset.CraftWeapons.Find(WeaponAt(AIndex).Rules.WeaponType);
end;

function TXcomDogfightEngine.Difficulty: Integer;
begin
  Result := FRuleset.Settings.DifficultyCoefficient[FGame.Difficulty];
end;

function TXcomDogfightEngine.CanAct: Boolean;
begin
  Result := (not FUfo.IsCrashed) and (not FCraft.IsDestroyed) and (not FUfoBreakingOff);
end;

function TXcomDogfightEngine.ShotDownByThisCraft: Boolean;
begin
  // the CraftId of the C++ is a pair: type and id
  Result := (FUfo.ShotDownByCraftId.CraftType = FCraft.UniqueId.CraftType) and
    (FUfo.ShotDownByCraftId.Id = FCraft.UniqueId.Id);
end;

procedure TXcomDogfightEngine.SetStatus(const AKey: string);
begin
  if Assigned(FListener) then
    FListener.StatusChanged(AKey);
  FTimeout := 50;
  FStatusShown := True;
end;

function TXcomDogfightEngine.WeaponEnabled(AIndex: Integer): Boolean;
begin
  Result := FWeaponEnabled[AIndex];
end;

function TXcomDogfightEngine.WeaponInterval(AIndex: Integer): Integer;
begin
  Result := FWeaponInterval[AIndex];
end;

function TXcomDogfightEngine.WeaponCountdown(AIndex: Integer): Integer;
begin
  Result := FWeaponCountdown[AIndex];
end;

procedure TXcomDogfightEngine.Think;
begin
  if not FEndDogfight then
    Update;
  if (not FCraft.InDogfight) or (FCraft.Destination <> FUfo) or (FUfo.Status = TXcomUfo.STATUS_LANDED) then
    EndDogfight;
end;

procedure TXcomDogfightEngine.Animate;
var
  LLastHitFrame: Boolean;
begin
  // the radar and the blobs are the window's; here what the animation changes in the game
  if FTimeout = 0 then
  begin
    // the text is cleared after a while (once: the window keeps it clear)
    if FStatusShown then
    begin
      if Assigned(FListener) then
        FListener.StatusChanged('');
      FStatusShown := False;
    end;
  end
  else
    Dec(FTimeout);
  // animate the UFO hit
  LLastHitFrame := False;
  if FAnimatingHit and (FUfo.HitFrame > 0) then
  begin
    FUfo.HitFrame := FUfo.HitFrame - 1;
    if FUfo.HitFrame = 0 then
    begin
      FAnimatingHit := False;
      LLastHitFrame := True;
    end;
  end;
  // animate the UFO crash landing
  if FUfo.IsCrashed and (FUfo.HitFrame = 0) and not LLastHitFrame then
    Dec(FUfoSize);
end;

procedure TXcomDogfightEngine.ScoreForXcom(APoints: Integer);
var
  LCountry: TXcomCountry;
  LRegion: TXcomRegion;
begin
  LCountry := TXcomGeography.LocateCountry(FGame, FUfo.Longitude, FUfo.Latitude);
  if Assigned(LCountry) then
    LCountry.AddActivityXcom(APoints);
  LRegion := TXcomGeography.LocateRegion(FGame, FUfo.Longitude, FUfo.Latitude);
  if Assigned(LRegion) then
    LRegion.AddActivityXcom(APoints);
end;

procedure TXcomDogfightEngine.Retaliate;
var
  LMission, LNew: TXcomAlienMission;
  LRule: TXcomRuleAlienMission;
  LOdds: Integer;
  LTarget: string;
  LRegion: TXcomRegion;
  LFound: Boolean;
begin
  // the retaliation trigger
  LMission := FUfo.Mission;
  LOdds := LMission.Rule.RetaliationOdds;
  if LOdds = -1 then
    LOdds := 100 - (4 * (24 - Difficulty));
  if not Percent(LOdds) then
    Exit;
  if Percent(50 - 6 * Difficulty) then
    // attack on the region of the mission of the UFO
    LTarget := LMission.Region
  else
  begin
    // try to find and attack the originating base
    LRegion := TXcomGeography.LocateRegion(FGame, FCraft.Base.Longitude, FCraft.Base.Latitude);
    LTarget := LRegion.Rules.RegionType;
  end;
  // difference from the original: no retaliation until the final UFO lands
  LFound := False;
  for LNew in FGame.ActiveMissions do
    if (LNew.Region = LTarget) and (LNew.Rule.Objective = TXcomRuleAlienMission.OBJECTIVE_RETALIATION) then
    begin
      LFound := True;
      Break;
    end;
  if LFound then
    Exit;
  LRule := TXcomRandomMission.Choose(FRuleset, FRandom, TXcomRuleAlienMission.OBJECTIVE_RETALIATION,
    Cardinal(FGame.MonthsPassed));
  LNew := TXcomAlienMission.Create(LRule);
  LNew.SetId(FGame.GetId('ALIEN_MISSIONS'));
  LNew.SetRegion(LTarget, FRuleset.Regions.Find(LTarget));
  LNew.Race := FUfo.AlienRace;
  // fixed delay for the first scout
  LNew.Start(LNew.Rule.Waves[0].SpawnTimer, FRandom);
  FGame.ActiveMissions.Add(LNew);
end;

procedure TXcomDogfightEngine.Update;
var
  LFinalRun, LProjectileInFlight: Boolean;
  LDistanceChange, LIndex, LEscape, LDamage: Integer;
  LProjectile: TXcomCraftWeaponProjectile;
  LWeapon: TXcomCraftWeapon;
  LTimer: Integer;
  LFollower: TXcomTarget;
  LFollowers: TArray<TXcomTarget>;
begin
  LFinalRun := False;
  // the craft is not low on fuel while the window is minimized and its destination was not changed
  if (not (FCraft.Destination is TXcomUfo)) or (FCraft.Destination <> FUfo) or (not FCraft.InDogfight) or
    FCraft.LowFuel or (FMinimized and FUfo.IsCrashed) then
  begin
    EndDogfight;
    Exit;
  end;
  if not FMinimized then
  begin
    Animate;
    if (not FUfo.IsCrashed) and (not FUfo.IsDestroyed) and (not FCraft.IsDestroyed) and
      (not FUfo.InterceptionProcessed) then
    begin
      FUfo.InterceptionProcessed := True;
      LEscape := FUfo.EscapeCountdown;
      if LEscape > 0 then
      begin
        Dec(LEscape);
        FUfo.EscapeCountdown := LEscape;
        // the UFO is breaking off
        if LEscape = 0 then
          FUfo.SetSpeed(FUfo.Rules.MaxSpeed);
      end;
      if FUfo.FireCountdown > 0 then
        FUfo.FireCountdown := FUfo.FireCountdown - 1;
    end;
  end;
  // a crappy craft is chasing the UFO
  if FUfo.Speed > FCraft.Rules.MaxSpeed then
  begin
    FUfoBreakingOff := True;
    LFinalRun := True;
    SetStatus('STR_UFO_OUTRUNNING_INTERCEPTOR');
  end
  else
    FUfoBreakingOff := False;
  LProjectileInFlight := False;
  if not FMinimized then
  begin
    LDistanceChange := 0;
    if not FUfoBreakingOff then
    begin
      if (FCurrentDist < FTargetDist) and (not FUfo.IsCrashed) and (not FCraft.IsDestroyed) then
      begin
        LDistanceChange := 4;
        if FCurrentDist + LDistanceChange > FTargetDist then
          LDistanceChange := FTargetDist - FCurrentDist;
      end
      else if (FCurrentDist > FTargetDist) and (not FUfo.IsCrashed) and (not FCraft.IsDestroyed) then
        LDistanceChange := -2;
      // don't let the interceptor mystically push or pull its fired projectiles
      for LProjectile in FProjectiles do
        if (LProjectile.Kind <> pkBeam) and (LProjectile.Direction = TXcomCraftWeaponProjectile.DIRECTION_UP) then
          LProjectile.Position := LProjectile.Position + LDistanceChange;
    end
    else
      // the UFOs can try to outrun the missiles: their positions are not adjusted
      LDistanceChange := 4;
    Inc(FCurrentDist, LDistanceChange);
    // move the projectiles and check for hits
    for LProjectile in FProjectiles do
    begin
      LProjectile.Move;
      if LProjectile.Direction = TXcomCraftWeaponProjectile.DIRECTION_UP then
      begin
        // the projectile reached the UFO: is it a hit?
        if ((LProjectile.Position >= FCurrentDist) or ((LProjectile.Kind = pkBeam) and LProjectile.ToBeRemoved)) and
          (not FUfo.IsCrashed) and (not LProjectile.Missed) then
        begin
          if Percent((LProjectile.Accuracy * (100 + 300 div (5 - FUfoSize)) + 100) div 200) then
          begin
            // the formula of Volutar
            LDamage := FRandom.Generate(LProjectile.Damage div 2, LProjectile.Damage);
            FUfo.SetDamage(FUfo.Damage + LDamage);
            if FUfo.IsCrashed then
            begin
              FUfo.ShotDownByCraftId := FCraft.UniqueId;
              FUfo.SetSpeed(0);
              FUfo.SetDestination(nil);
              // if the UFO got destroyed here, these no longer apply
              FUfoBreakingOff := False;
              LFinalRun := False;
              FEnd := False;
            end;
            if FUfo.HitFrame = 0 then
            begin
              FAnimatingHit := True;
              FUfo.HitFrame := 3;
            end;
            SetStatus('STR_UFO_HIT');
            if Assigned(FListener) then
              FListener.SoundPlayed(dsUfoHit, 0);
            LProjectile.Remove;
          end
          else if LProjectile.Kind = pkBeam then
            LProjectile.Remove
          else
            LProjectile.Missed := True;
        end;
        // did the projectile pass its maximum range?
        if (LProjectile.Kind = pkMissile) and (LProjectile.Position div 8 >= LProjectile.Range) then
          LProjectile.Remove
        else if not FUfo.IsCrashed then
          LProjectileInFlight := True;
      end
      else if LProjectile.Direction = TXcomCraftWeaponProjectile.DIRECTION_DOWN then
      begin
        if (LProjectile.Kind = pkMissile) or ((LProjectile.Kind = pkBeam) and LProjectile.ToBeRemoved) then
        begin
          if Percent(LProjectile.Accuracy) then
          begin
            // the formula of Volutar
            LDamage := FRandom.Generate(0, FUfo.Rules.WeaponPower);
            if LDamage <> 0 then
            begin
              FCraft.SetDamage(FCraft.Damage + LDamage);
              if Assigned(FListener) then
                FListener.CraftDamaged;
              SetStatus('STR_INTERCEPTOR_DAMAGED');
              if Assigned(FListener) then
                FListener.SoundPlayed(dsInterceptorHit, 0);
              if (FMode = dmCautious) and (FCraft.DamagePercentage >= 50) then
                FTargetDist := STANDOFF_DIST;
            end;
          end;
          LProjectile.Remove;
        end;
      end;
    end;
    // remove the projectiles that hit or missed their target
    LIndex := 0;
    while LIndex < FProjectiles.Count do
      if FProjectiles[LIndex].ToBeRemoved or (FProjectiles[LIndex].Missed and (FProjectiles[LIndex].Position <= 0)) then
        FProjectiles.Delete(LIndex)
      else
        Inc(LIndex);
    // the weapons and the craft distance
    for LIndex := 0 to FCraft.Rules.Weapons - 1 do
    begin
      LWeapon := WeaponAt(LIndex);
      if LWeapon = nil then
        Continue;
      LTimer := FWeaponCountdown[Min(LIndex, 1)];
      // weapon firing
      if (LTimer = 0) and (FCurrentDist <= WeaponRule(LIndex).Range * 8) and (LWeapon.Ammo > 0) and
        (FMode <> dmStandoff) and (FMode <> dmDisengage) and (not FUfo.IsCrashed) and (not FCraft.IsDestroyed) then
      begin
        if FWeaponEnabled[Min(LIndex, 1)] then
        begin
          FireWeapon(Min(LIndex, 1));
          LProjectileInFlight := True;
        end;
      end
      else if LTimer > 0 then
        Dec(FWeaponCountdown[Min(LIndex, 1)]);
      if (LWeapon.Ammo = 0) and (not LProjectileInFlight) and (not FCraft.IsDestroyed) then
      begin
        // the craft distance by the attitude and the ammunition left
        if FMode = dmCautious then
          MinimumDistance
        else if FMode = dmStandard then
          MaximumDistance;
      end;
    end;
    // the UFO fires
    if (FCurrentDist <= FUfo.Rules.WeaponRange * 8) and (not FUfo.IsCrashed) and (not FCraft.IsDestroyed) then
    begin
      if FUfo.ShootingAt = 0 then
        FUfo.ShootingAt := FInterceptionNumber;
      if FUfo.ShootingAt = FInterceptionNumber then
        if FUfo.FireCountdown = 0 then
          UfoFireWeapon;
    end
    else if FUfo.ShootingAt = FInterceptionNumber then
      FUfo.ShootingAt := 0;
  end;
  // check when the battle is over
  if FEnd and (((FCurrentDist > 640) or FMinimized) and ((FMode = dmDisengage) or FUfoBreakingOff) or
    ((FTimeout = 0) and (FUfo.IsCrashed or FCraft.IsDestroyed))) then
  begin
    if FUfoBreakingOff then
    begin
      FUfo.Move;
      FCraft.SetDestination(FUfo);
    end;
    if (not FDestroyCraft) and (FDestroyUfo or (FMode = dmDisengage)) then
      FCraft.ReturnToBase;
    if FUfo.IsCrashed then
    begin
      LFollowers := FUfo.Followers.ToArray;
      for LFollower in LFollowers do
        if LFollower is TXcomCraft then
          if (TXcomCraft(LFollower).NumSoldiers(TXcomBase(TXcomCraft(LFollower).Base).Soldiers) = 0) and
            (TXcomCraft(LFollower).NumVehicles = 0) then
            TXcomCraft(LFollower).ReturnToBase;
    end;
    EndDogfight;
  end;
  if (FCurrentDist > 640) and FUfoBreakingOff then
    LFinalRun := True;
  // end the dogfight if the craft is destroyed
  if not FEnd then
  begin
    if FCraft.IsDestroyed then
    begin
      SetStatus('STR_INTERCEPTOR_DESTROYED');
      Inc(FTimeout, 30);
      if Assigned(FListener) then
        FListener.SoundPlayed(dsInterceptorExplode, 0);
      LFinalRun := True;
      FDestroyCraft := True;
      FUfo.ShootingAt := 0;
    end;
    // end the dogfight if the UFO is crashed or destroyed
    if FUfo.IsCrashed then
    begin
      // declared difference: the C++ dereferences a null mission (crash); a UFO without one gives no retaliation
      if Assigned(FUfo.Mission) then
      begin
        FUfo.Mission.UfoShotDown(True, FRandom);
        Retaliate;
      end;
      if FUfo.IsDestroyed then
      begin
        if ShotDownByThisCraft then
        begin
          ScoreForXcom(FUfo.Rules.Score * 2);
          SetStatus('STR_UFO_DESTROYED');
          if Assigned(FListener) then
            FListener.SoundPlayed(dsUfoExplode, 0);
        end;
        FDestroyUfo := True;
      end
      else
      begin
        if ShotDownByThisCraft then
        begin
          SetStatus('STR_UFO_CRASH_LANDS');
          if Assigned(FListener) then
            FListener.SoundPlayed(dsUfoCrash, 0);
          ScoreForXcom(FUfo.Rules.Score);
        end;
        if not FLand.InsideLand(FUfo.Longitude, FUfo.Latitude) then
        begin
          FUfo.Status := TXcomUfo.STATUS_DESTROYED;
          FDestroyUfo := True;
        end
        else
        begin
          FUfo.SecondsRemaining := Cardinal(FRandom.Generate(24, 96) * 3600);
          FUfo.SetAltitude('STR_GROUND');
          if FUfo.CrashId = 0 then
            FUfo.CrashId := FGame.GetId('STR_CRASH_SITE');
        end;
      end;
      Inc(FTimeout, 30);
      if not ShotDownByThisCraft then
      begin
        Inc(FTimeout, 50);
        FUfo.HitFrame := 3;
      end;
      LFinalRun := True;
      if FUfo.Status = TXcomUfo.STATUS_LANDED then
      begin
        Inc(FTimeout, 30);
        LFinalRun := True;
        FUfo.ShootingAt := 0;
      end;
    end;
  end;
  if (not LProjectileInFlight) and LFinalRun then
    FEnd := True;
end;

procedure TXcomDogfightEngine.FireWeapon(AIndex: Integer);
var
  LWeapon: TXcomCraftWeapon;
  LRule: TXcomRuleCraftWeapon;
  LProjectile: TXcomCraftWeaponProjectile;
begin
  LWeapon := WeaponAt(AIndex);
  if LWeapon.SetAmmo(LWeapon.Ammo - 1) then
  begin
    FWeaponCountdown[AIndex] := FWeaponInterval[AIndex];
    if Assigned(FListener) then
      FListener.AmmoChanged(AIndex, LWeapon.Ammo);
    LRule := WeaponRule(AIndex);
    // CraftWeapon::fire
    LProjectile := TXcomCraftWeaponProjectile.Create;
    LProjectile.SetType(TXcomProjectileType(LRule.ProjectileType));
    LProjectile.Speed := LRule.ProjectileSpeed;
    LProjectile.Accuracy := LRule.Accuracy;
    LProjectile.Damage := LRule.Damage;
    LProjectile.Range := LRule.Range;
    LProjectile.SetDirection(TXcomCraftWeaponProjectile.DIRECTION_UP);
    if AIndex = 0 then
      LProjectile.HorizontalPosition := TXcomCraftWeaponProjectile.HORIZONTAL_LEFT
    else
      LProjectile.HorizontalPosition := TXcomCraftWeaponProjectile.HORIZONTAL_RIGHT;
    FProjectiles.Add(LProjectile);
    if Assigned(FListener) then
      FListener.SoundPlayed(dsWeapon, LRule.Sound);
  end;
end;

procedure TXcomDogfightEngine.UfoFireWeapon;
var
  LCountdown: Integer;
  LProjectile: TXcomCraftWeaponProjectile;
begin
  // each time the UFO tries to fire its cannons a calculation is made
  LCountdown := Max(1, FUfo.Rules.WeaponReload - 2 * Difficulty);
  FUfo.FireCountdown := FRandom.Generate(0, LCountdown) + LCountdown;
  SetStatus('STR_UFO_RETURN_FIRE');
  LProjectile := TXcomCraftWeaponProjectile.Create;
  LProjectile.SetType(ptPlasmaBeam);
  LProjectile.Accuracy := 60;
  LProjectile.Damage := FUfo.Rules.WeaponPower;
  LProjectile.SetDirection(TXcomCraftWeaponProjectile.DIRECTION_DOWN);
  LProjectile.HorizontalPosition := TXcomCraftWeaponProjectile.HORIZONTAL_CENTER;
  LProjectile.Position := FCurrentDist - (FUfo.Rules.Radius div 2);
  FProjectiles.Add(LProjectile);
  if Assigned(FListener) then
    FListener.SoundPlayed(dsUfoFire, 0);
end;

procedure TXcomDogfightEngine.MinimumDistance;
var
  LIndex, LMax: Integer;
  LWeapon: TXcomCraftWeapon;
begin
  LMax := 0;
  for LIndex := 0 to FCraft.Weapons.Count - 1 do
  begin
    LWeapon := FCraft.Weapons[LIndex];
    if LWeapon = nil then
      Continue;
    if (WeaponRule(LIndex).Range > LMax) and (LWeapon.Ammo > 0) then
      LMax := WeaponRule(LIndex).Range;
  end;
  if LMax = 0 then
    FTargetDist := STANDOFF_DIST
  else
    FTargetDist := LMax * 8;
end;

procedure TXcomDogfightEngine.MaximumDistance;
var
  LIndex, LMin: Integer;
  LWeapon: TXcomCraftWeapon;
begin
  LMin := 1000;
  for LIndex := 0 to FCraft.Weapons.Count - 1 do
  begin
    LWeapon := FCraft.Weapons[LIndex];
    if LWeapon = nil then
      Continue;
    if (WeaponRule(LIndex).Range < LMin) and (LWeapon.Ammo > 0) then
      LMin := WeaponRule(LIndex).Range;
  end;
  if LMin = 1000 then
    FTargetDist := STANDOFF_DIST
  else
    FTargetDist := LMin * 8;
end;

procedure TXcomDogfightEngine.SetWeaponIntervals(AWhich: Integer);
var
  LIndex: Integer;
begin
  // AWhich: 1 cautious reload, 2 standard, 3 aggressive
  for LIndex := 0 to 1 do
    if WeaponAt(LIndex) <> nil then
      case AWhich of
        1: FWeaponInterval[LIndex] := WeaponRule(LIndex).CautiousReload;
        2: FWeaponInterval[LIndex] := WeaponRule(LIndex).StandardReload;
        3: FWeaponInterval[LIndex] := WeaponRule(LIndex).AggressiveReload;
      end;
end;

procedure TXcomDogfightEngine.PressMode(AMode: TXcomDogfightMode);
begin
  // the group of the buttons selects the pressed one whatever the handler does
  FMode := AMode;
  if not CanAct then
    Exit;
  case AMode of
    dmStandoff:
      begin
        FEnd := False;
        SetStatus('STR_STANDOFF');
        FTargetDist := STANDOFF_DIST;
      end;
    dmCautious:
      begin
        FEnd := False;
        SetStatus('STR_CAUTIOUS_ATTACK');
        SetWeaponIntervals(1);
        MinimumDistance;
      end;
    dmStandard:
      begin
        FEnd := False;
        SetStatus('STR_STANDARD_ATTACK');
        SetWeaponIntervals(2);
        MaximumDistance;
      end;
    dmAggressive:
      begin
        FEnd := False;
        SetStatus('STR_AGGRESSIVE_ATTACK');
        SetWeaponIntervals(3);
        FTargetDist := 64;
      end;
    dmDisengage:
      begin
        FEnd := True;
        SetStatus('STR_DISENGAGING');
        FTargetDist := 800;
      end;
  end;
end;

procedure TXcomDogfightEngine.MinimizeClick;
begin
  if CanAct then
  begin
    if FCurrentDist >= STANDOFF_DIST then
      SetMinimized(True)
    else
      SetStatus('STR_MINIMISE_AT_STANDOFF_RANGE_ONLY');
  end;
end;

procedure TXcomDogfightEngine.MinimizedIconClick;
begin
  if (FCraft.Rules.MaxAltitude > -1) and (FUfo.AltitudeInt > FCraft.Rules.MaxAltitude) then
  begin
    if Assigned(FListener) then
      FListener.CannotEngage('STR_UNABLE_TO_ENGAGE_DEPTH');
    FWaitForAltitude := True;
  end
  else if (FCraft.Rules.MaxAltitude > -1) and (not FLand.InsideLand(FCraft.Longitude, FCraft.Latitude)) then
  begin
    if Assigned(FListener) then
      FListener.CannotEngage('STR_UNABLE_TO_ENGAGE_AIRBORNE');
    FWaitForPoly := True;
  end
  else
    SetMinimized(False);
end;

procedure TXcomDogfightEngine.ToggleWeapon(AIndex: Integer);
begin
  FWeaponEnabled[AIndex] := not FWeaponEnabled[AIndex];
end;

procedure TXcomDogfightEngine.SetMinimized(AMinimized: Boolean);
begin
  FMinimized := AMinimized;
end;

procedure TXcomDogfightEngine.SetInterceptionNumber(ANumber: Integer);
begin
  FInterceptionNumber := ANumber;
end;

procedure TXcomDogfightEngine.SetWaitForPoly(AWait: Boolean);
begin
  FWaitForPoly := AWait;
end;

procedure TXcomDogfightEngine.SetWaitForAltitude(AWait: Boolean);
begin
  FWaitForAltitude := AWait;
end;

procedure TXcomDogfightEngine.EndDogfight;
begin
  if FEndDogfight then
    Exit;
  FCraft.InDogfight := False;
  FCraft.InterceptionOrder := 0;
  // the UFO is free for the next engagement
  FUfo.InterceptionProcessed := False;
  FEndDogfight := True;
end;

end.
