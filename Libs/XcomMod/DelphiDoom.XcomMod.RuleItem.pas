{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - an item (RuleItem)                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleItem;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.ModOffsets;

type
  /// <summary>
  ///   Constant data of a type of item: storage size, prices, sprites and sounds, damage, accuracy, time units,
  ///   ranges, medical effects, recovery, vapor... (RuleItem). The damage type and the battle type are the
  ///   numbers of ItemDamageType and BattleType (the C++ casts them without checking)
  /// </summary>
  TXcomRuleItem = class
  public
    const
      /// <summary>ItemDamageType</summary>
      DT_NONE = 0; DT_AP = 1; DT_IN = 2; DT_HE = 3; DT_LASER = 4; DT_PLASMA = 5; DT_STUN = 6; DT_MELEE = 7;
      DT_ACID = 8; DT_SMOKE = 9;
      /// <summary>BattleType</summary>
      BT_NONE = 0; BT_FIREARM = 1; BT_AMMO = 2; BT_MELEE = 3; BT_GRENADE = 4; BT_PROXIMITYGRENADE = 5;
      BT_MEDIKIT = 6; BT_SCANNER = 7; BT_MINDPROBE = 8; BT_PSIAMP = 9; BT_FLARE = 10; BT_CORPSE = 11;
  strict private
    FType: string;
    FName: string;
    FRequires: TArray<string>;
    FSize: Double;
    FCostBuy: Integer;
    FCostSell: Integer;
    FTransferTime: Integer;
    FWeight: Integer;
    FBigSprite: Integer;
    FFloorSprite: Integer;
    FHandSprite: Integer;
    FBulletSprite: Integer;
    FFireSound: Integer;
    FHitSound: Integer;
    FHitAnimation: Integer;
    FPower: Integer;
    FCompatibleAmmo: TArray<string>;
    FDamageType: Integer;
    FAccuracyAuto: Integer;
    FAccuracySnap: Integer;
    FAccuracyAimed: Integer;
    FTuAuto: Integer;
    FTuSnap: Integer;
    FTuAimed: Integer;
    FClipSize: Integer;
    FAccuracyMelee: Integer;
    FTuMelee: Integer;
    FBattleType: Integer;
    FTwoHanded: Boolean;
    FFixedWeapon: Boolean;
    FWaypoints: Integer;
    FInvWidth: Integer;
    FInvHeight: Integer;
    FPainKiller: Integer;
    FHeal: Integer;
    FStimulant: Integer;
    FWoundRecovery: Integer;
    FHealthRecovery: Integer;
    FStunRecovery: Integer;
    FEnergyRecovery: Integer;
    FTuUse: Integer;
    FRecoveryPoints: Integer;
    FArmor: Integer;
    FTurretType: Integer;
    FRecover: Boolean;
    FIgnoreInBaseDefense: Boolean;
    FLiveAlien: Boolean;
    FBlastRadius: Integer;
    FAttraction: Integer;
    FFlatRate: Boolean;
    FArcingShot: Boolean;
    FListOrder: Integer;
    FMaxRange: Integer;
    FAimRange: Integer;
    FSnapRange: Integer;
    FAutoRange: Integer;
    FMinRange: Integer;
    FDropoff: Integer;
    FBulletSpeed: Integer;
    FExplosionSpeed: Integer;
    FAutoShots: Integer;
    FShotgunPellets: Integer;
    FZombieUnit: string;
    FStrengthApplied: Boolean;
    FSkillApplied: Boolean;
    FLosRequired: Boolean;
    FUnderwaterOnly: Boolean;
    FLandOnly: Boolean;
    FMeleeSound: Integer;
    FMeleePower: Integer;
    FMeleeAnimation: Integer;
    FMeleeHitSound: Integer;
    FSpecialType: Integer;
    FVaporColor: Integer;
    FVaporDensity: Integer;
    FVaporProbability: Integer;
  public
    /// <summary>A blank ruleset for a type of item</summary>
    constructor Create(const AType: string);
    /// <summary>
    ///   Loads the item from a YAML node; AListOrder is the default of listOrder. A weapon (firearm or melee)
    ///   with no clip size and no compatible ammo is EXcomModException
    /// </summary>
    procedure Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets; AListOrder: Integer);
    /// <summary>getExplosionRadius: the blast radius, or the one that the damage type and power give (at most 11)</summary>
    function ExplosionRadius: Integer;
    /// <summary>getMaxRangeSq (the product wraps like an int)</summary>
    function MaxRangeSquared: Integer;
    /// <summary>isRifle: a firearm or melee weapon held with two hands</summary>
    function IsRifle: Boolean;
    /// <summary>isPistol: a firearm or melee weapon held with one hand</summary>
    function IsPistol: Boolean;
    property ItemType: string read FType;
    property Name: string read FName;
    property Requirements: TArray<string> read FRequires;
    property Size: Double read FSize;
    property BuyCost: Integer read FCostBuy;
    property SellCost: Integer read FCostSell;
    property TransferTime: Integer read FTransferTime;
    property Weight: Integer read FWeight;
    property BigSprite: Integer read FBigSprite;
    property FloorSprite: Integer read FFloorSprite;
    property HandSprite: Integer read FHandSprite;
    property BulletSprite: Integer read FBulletSprite;
    property FireSound: Integer read FFireSound;
    property HitSound: Integer read FHitSound;
    property HitAnimation: Integer read FHitAnimation;
    property Power: Integer read FPower;
    property CompatibleAmmo: TArray<string> read FCompatibleAmmo;
    property DamageType: Integer read FDamageType;
    property AccuracyAuto: Integer read FAccuracyAuto;
    property AccuracySnap: Integer read FAccuracySnap;
    property AccuracyAimed: Integer read FAccuracyAimed;
    property TimeUnitsAuto: Integer read FTuAuto;
    property TimeUnitsSnap: Integer read FTuSnap;
    property TimeUnitsAimed: Integer read FTuAimed;
    property ClipSize: Integer read FClipSize;
    property AccuracyMelee: Integer read FAccuracyMelee;
    property TimeUnitsMelee: Integer read FTuMelee;
    property BattleType: Integer read FBattleType;
    property TwoHanded: Boolean read FTwoHanded;
    property FixedWeapon: Boolean read FFixedWeapon;
    property Waypoints: Integer read FWaypoints;
    property InventoryWidth: Integer read FInvWidth;
    property InventoryHeight: Integer read FInvHeight;
    property PainKiller: Integer read FPainKiller;
    property Heal: Integer read FHeal;
    property Stimulant: Integer read FStimulant;
    property WoundRecovery: Integer read FWoundRecovery;
    property HealthRecovery: Integer read FHealthRecovery;
    property StunRecovery: Integer read FStunRecovery;
    property EnergyRecovery: Integer read FEnergyRecovery;
    property TimeUnitsUse: Integer read FTuUse;
    property RecoveryPoints: Integer read FRecoveryPoints;
    property Armor: Integer read FArmor;
    property TurretType: Integer read FTurretType;
    property Recoverable: Boolean read FRecover;
    property IgnoreInBaseDefense: Boolean read FIgnoreInBaseDefense;
    property LiveAlien: Boolean read FLiveAlien;
    property BlastRadius: Integer read FBlastRadius;
    property Attraction: Integer read FAttraction;
    property FlatRate: Boolean read FFlatRate;
    property ArcingShot: Boolean read FArcingShot;
    property ListOrder: Integer read FListOrder;
    property MaxRange: Integer read FMaxRange;
    property AimRange: Integer read FAimRange;
    property SnapRange: Integer read FSnapRange;
    property AutoRange: Integer read FAutoRange;
    property MinRange: Integer read FMinRange;
    property Dropoff: Integer read FDropoff;
    property BulletSpeed: Integer read FBulletSpeed;
    property ExplosionSpeed: Integer read FExplosionSpeed;
    property AutoShots: Integer read FAutoShots;
    property ShotgunPellets: Integer read FShotgunPellets;
    property ZombieUnit: string read FZombieUnit;
    property StrengthApplied: Boolean read FStrengthApplied;
    property SkillApplied: Boolean read FSkillApplied;
    property LineOfSightRequired: Boolean read FLosRequired;
    property UnderwaterOnly: Boolean read FUnderwaterOnly;
    property LandOnly: Boolean read FLandOnly;
    property MeleeSound: Integer read FMeleeSound;
    property MeleePower: Integer read FMeleePower;
    property MeleeAnimation: Integer read FMeleeAnimation;
    property MeleeHitSound: Integer read FMeleeHitSound;
    property SpecialType: Integer read FSpecialType;
    property VaporColor: Integer read FVaporColor;
    property VaporDensity: Integer read FVaporDensity;
    property VaporProbability: Integer read FVaporProbability;
  end;

implementation

uses
  DelphiDoom.XcomMod.Types;

resourcestring
  SItemNoAmmo = 'Weapon %s has clip size 0 and no ammo defined. Please use ''clipSize: -1'' for unlimited ammo, ' +
    'or allocate a compatibleAmmo item.';

{ TXcomRuleItem }

constructor TXcomRuleItem.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FName := AType;
  FTransferTime := 24;
  FWeight := 3;
  FBigSprite := -1;
  FFloorSprite := -1;
  FHandSprite := 120;
  FBulletSprite := -1;
  FFireSound := -1;
  FHitSound := -1;
  FHitAnimation := -1;
  FInvWidth := 1;
  FInvHeight := 1;
  FArmor := 20;
  FTurretType := -1;
  FRecover := True;
  FBlastRadius := -1;
  FMaxRange := 200;
  FAimRange := 200;
  FSnapRange := 15;
  FAutoRange := 7;
  FDropoff := 2;
  FAutoShots := 3;
  FSkillApplied := True;
  FMeleeSound := 39;
  FMeleeHitSound := -1;
  FSpecialType := -1;
  FVaporColor := -1;
  FVaporProbability := 15;
end;

procedure TXcomRuleItem.Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets; AListOrder: Integer);
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FName := TXcomNodeReader.ReadString(ANode, 'name', FName);
  FRequires := TXcomNodeReader.ReadStrings(ANode, 'requires', FRequires);
  FSize := TXcomNodeReader.ReadDouble(ANode, 'size', FSize);
  FCostBuy := TXcomNodeReader.ReadInteger(ANode, 'costBuy', FCostBuy);
  FCostSell := TXcomNodeReader.ReadInteger(ANode, 'costSell', FCostSell);
  FTransferTime := TXcomNodeReader.ReadInteger(ANode, 'transferTime', FTransferTime);
  FWeight := TXcomNodeReader.ReadInteger(ANode, 'weight', FWeight);
  AOffsets.LoadSpriteOffset(FType, FBigSprite, TXcomNodeReader.Field(ANode, 'bigSprite'), 'BIGOBS.PCK');
  AOffsets.LoadSpriteOffset(FType, FFloorSprite, TXcomNodeReader.Field(ANode, 'floorSprite'), 'FLOOROB.PCK');
  AOffsets.LoadSpriteOffset(FType, FHandSprite, TXcomNodeReader.Field(ANode, 'handSprite'), 'HANDOB.PCK');
  // Projectiles: 35 sprites per projectile, 11 projectiles
  AOffsets.LoadSpriteOffset(FType, FBulletSprite, TXcomNodeReader.Field(ANode, 'bulletSprite'), 'Projectiles', 35);
  AOffsets.LoadSoundOffset(FType, FFireSound, TXcomNodeReader.Field(ANode, 'fireSound'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset(FType, FHitSound, TXcomNodeReader.Field(ANode, 'hitSound'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset(FType, FMeleeSound, TXcomNodeReader.Field(ANode, 'meleeSound'), 'BATTLE.CAT');
  AOffsets.LoadSpriteOffset(FType, FHitAnimation, TXcomNodeReader.Field(ANode, 'hitAnimation'), 'SMOKE.PCK');
  AOffsets.LoadSpriteOffset(FType, FMeleeAnimation, TXcomNodeReader.Field(ANode, 'meleeAnimation'), 'HIT.PCK');
  AOffsets.LoadSoundOffset(FType, FMeleeHitSound, TXcomNodeReader.Field(ANode, 'meleeHitSound'), 'BATTLE.CAT');
  FPower := TXcomNodeReader.ReadInteger(ANode, 'power', FPower);
  FCompatibleAmmo := TXcomNodeReader.ReadStrings(ANode, 'compatibleAmmo', FCompatibleAmmo);
  FDamageType := TXcomNodeReader.ReadInteger(ANode, 'damageType', FDamageType);
  FAccuracyAuto := TXcomNodeReader.ReadInteger(ANode, 'accuracyAuto', FAccuracyAuto);
  FAccuracySnap := TXcomNodeReader.ReadInteger(ANode, 'accuracySnap', FAccuracySnap);
  FAccuracyAimed := TXcomNodeReader.ReadInteger(ANode, 'accuracyAimed', FAccuracyAimed);
  FTuAuto := TXcomNodeReader.ReadInteger(ANode, 'tuAuto', FTuAuto);
  FTuSnap := TXcomNodeReader.ReadInteger(ANode, 'tuSnap', FTuSnap);
  FTuAimed := TXcomNodeReader.ReadInteger(ANode, 'tuAimed', FTuAimed);
  FClipSize := TXcomNodeReader.ReadInteger(ANode, 'clipSize', FClipSize);
  FAccuracyMelee := TXcomNodeReader.ReadInteger(ANode, 'accuracyMelee', FAccuracyMelee);
  FTuMelee := TXcomNodeReader.ReadInteger(ANode, 'tuMelee', FTuMelee);
  FBattleType := TXcomNodeReader.ReadInteger(ANode, 'battleType', FBattleType);
  if ((FBattleType = BT_MELEE) or (FBattleType = BT_FIREARM)) and (FClipSize = 0) and (Length(FCompatibleAmmo) = 0) then
    raise EXcomModException.CreateFmt(SItemNoAmmo, [FType]);
  FTwoHanded := TXcomNodeReader.ReadBoolean(ANode, 'twoHanded', FTwoHanded);
  FWaypoints := TXcomNodeReader.ReadInteger(ANode, 'waypoints', FWaypoints);
  FFixedWeapon := TXcomNodeReader.ReadBoolean(ANode, 'fixedWeapon', FFixedWeapon);
  FInvWidth := TXcomNodeReader.ReadInteger(ANode, 'invWidth', FInvWidth);
  FInvHeight := TXcomNodeReader.ReadInteger(ANode, 'invHeight', FInvHeight);
  FPainKiller := TXcomNodeReader.ReadInteger(ANode, 'painKiller', FPainKiller);
  FHeal := TXcomNodeReader.ReadInteger(ANode, 'heal', FHeal);
  FStimulant := TXcomNodeReader.ReadInteger(ANode, 'stimulant', FStimulant);
  FWoundRecovery := TXcomNodeReader.ReadInteger(ANode, 'woundRecovery', FWoundRecovery);
  FHealthRecovery := TXcomNodeReader.ReadInteger(ANode, 'healthRecovery', FHealthRecovery);
  FStunRecovery := TXcomNodeReader.ReadInteger(ANode, 'stunRecovery', FStunRecovery);
  FEnergyRecovery := TXcomNodeReader.ReadInteger(ANode, 'energyRecovery', FEnergyRecovery);
  FTuUse := TXcomNodeReader.ReadInteger(ANode, 'tuUse', FTuUse);
  FRecoveryPoints := TXcomNodeReader.ReadInteger(ANode, 'recoveryPoints', FRecoveryPoints);
  FArmor := TXcomNodeReader.ReadInteger(ANode, 'armor', FArmor);
  FTurretType := TXcomNodeReader.ReadInteger(ANode, 'turretType', FTurretType);
  FRecover := TXcomNodeReader.ReadBoolean(ANode, 'recover', FRecover);
  FIgnoreInBaseDefense := TXcomNodeReader.ReadBoolean(ANode, 'ignoreInBaseDefense', FIgnoreInBaseDefense);
  FLiveAlien := TXcomNodeReader.ReadBoolean(ANode, 'liveAlien', FLiveAlien);
  FBlastRadius := TXcomNodeReader.ReadInteger(ANode, 'blastRadius', FBlastRadius);
  FAttraction := TXcomNodeReader.ReadInteger(ANode, 'attraction', FAttraction);
  FFlatRate := TXcomNodeReader.ReadBoolean(ANode, 'flatRate', FFlatRate);
  FArcingShot := TXcomNodeReader.ReadBoolean(ANode, 'arcingShot', FArcingShot);
  FListOrder := TXcomNodeReader.ReadInteger(ANode, 'listOrder', FListOrder);
  FMaxRange := TXcomNodeReader.ReadInteger(ANode, 'maxRange', FMaxRange);
  FAimRange := TXcomNodeReader.ReadInteger(ANode, 'aimRange', FAimRange);
  FSnapRange := TXcomNodeReader.ReadInteger(ANode, 'snapRange', FSnapRange);
  FAutoRange := TXcomNodeReader.ReadInteger(ANode, 'autoRange', FAutoRange);
  FMinRange := TXcomNodeReader.ReadInteger(ANode, 'minRange', FMinRange);
  FDropoff := TXcomNodeReader.ReadInteger(ANode, 'dropoff', FDropoff);
  FBulletSpeed := TXcomNodeReader.ReadInteger(ANode, 'bulletSpeed', FBulletSpeed);
  FExplosionSpeed := TXcomNodeReader.ReadInteger(ANode, 'explosionSpeed', FExplosionSpeed);
  FAutoShots := TXcomNodeReader.ReadInteger(ANode, 'autoShots', FAutoShots);
  FShotgunPellets := TXcomNodeReader.ReadInteger(ANode, 'shotgunPellets', FShotgunPellets);
  FZombieUnit := TXcomNodeReader.ReadString(ANode, 'zombieUnit', FZombieUnit);
  FStrengthApplied := TXcomNodeReader.ReadBoolean(ANode, 'strengthApplied', FStrengthApplied);
  FSkillApplied := TXcomNodeReader.ReadBoolean(ANode, 'skillApplied', FSkillApplied);
  FLosRequired := TXcomNodeReader.ReadBoolean(ANode, 'LOSRequired', FLosRequired);
  FMeleePower := TXcomNodeReader.ReadInteger(ANode, 'meleePower', FMeleePower);
  FUnderwaterOnly := TXcomNodeReader.ReadBoolean(ANode, 'underwaterOnly', FUnderwaterOnly);
  FLandOnly := TXcomNodeReader.ReadBoolean(ANode, 'landOnly', FLandOnly);
  FSpecialType := TXcomNodeReader.ReadInteger(ANode, 'specialType', FSpecialType);
  AOffsets.LoadTransparencyOffset(FType, FVaporColor, TXcomNodeReader.Field(ANode, 'vaporColor'));
  FVaporDensity := TXcomNodeReader.ReadInteger(ANode, 'vaporDensity', FVaporDensity);
  FVaporProbability := TXcomNodeReader.ReadInteger(ANode, 'vaporProbability', FVaporProbability);
  if FListOrder = 0 then
    FListOrder := AListOrder;
end;

function TXcomRuleItem.ExplosionRadius: Integer;
begin
  if FBlastRadius = -1 then
  begin
    // heavy explosions, incendiary, smoke or stun bombs create areas; the rest hits one point
    Result := 0;
    if FDamageType = DT_IN then
      Result := (FPower div 30) + 1
    else if (FDamageType = DT_HE) or (FDamageType = DT_STUN) or (FDamageType = DT_SMOKE) then
      Result := FPower div 20;
    if Result > 11 then
      Result := 11;
  end
  else
    Result := FBlastRadius;
end;

function TXcomRuleItem.MaxRangeSquared: Integer;
begin
  Result := Integer(Int64(FMaxRange) * FMaxRange);
end;

function TXcomRuleItem.IsRifle: Boolean;
begin
  Result := ((FBattleType = BT_FIREARM) or (FBattleType = BT_MELEE)) and FTwoHanded;
end;

function TXcomRuleItem.IsPistol: Boolean;
begin
  Result := ((FBattleType = BT_FIREARM) or (FBattleType = BT_MELEE)) and not FTwoHanded;
end;

end.
