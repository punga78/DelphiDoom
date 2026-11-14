{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixWeaponRules                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the rules of the weapons of the craft: radix_weapons.pas (refire,   }
{  energy drain, volleys of the neutron cannons and of the plasma spreader,    }
{  tables of the EPC, plasma bomb), the refire tics of d_items.pas and         }
{  P_CheckAmmo of p_pspr.pas of Rad-X                                          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Weapon.Rules;

interface

{$SCOPEDENUMS ON}

type
  /// <summary>Which missile a shot of a volley is</summary>
  TRadixShotKind = (
    /// <summary>The only missile of the weapon (neutron ball, EPC shell)</summary>
    Standard,
    /// <summary>The ball of the plasma spreader that drifts to the left</summary>
    SpreadLeft,
    /// <summary>The ball of the plasma spreader that drifts to the right</summary>
    SpreadRight);

  /// <summary>Where a missile leaves the craft, in fixed point (16.16) units</summary>
  TRadixShot = record
    /// <summary>To the side of the craft: negative is left</summary>
    Offset: Integer;
    /// <summary>Above the origin of the craft</summary>
    Z: Integer;
    Kind: TRadixShotKind;
  end;

  /// <summary>What one pull of the trigger of an energy weapon does</summary>
  TRadixVolley = record
    /// <summary>How many of Shots are fired, in order</summary>
    Count: Integer;
    Shots: array[0..3] of TRadixShot;
    /// <summary>The amount given to DrainPlasmaEnergy; 0 when the energy is not touched</summary>
    Drain: Integer;
    /// <summary>The new value of the left/right flag of the weapon</summary>
    Alternate: Boolean;
  end;

  /// <summary>The part of the craft that an energy weapon consumes</summary>
  TRadixWeaponEnergy = record
    Energy: Integer;
    /// <summary>The energy kept aside by the rapid energy: it is consumed first</summary>
    Reserve: Integer;
    /// <summary>The energy goes down by one when this count is over</summary>
    Countdown: Integer;
    /// <summary>Tics during which the energy does not come back</summary>
    FireTics: Integer;
  end;

  /// <summary>The patterns of the shells of the three EPC (the super one fires two in turn)</summary>
  TRadixEpcTable = (Standard, Enhanced, Super1, Super2);

  /// <summary>The rules of the weapons of the craft that do not need the engine</summary>
  TRadixWeaponRules = class
  public const
    FRACUNIT = 1 shl 16;
    WEAPONS = 9;
    AMMO_TYPES = 4;
    WEAPON_NEUTRON_CANNONS = 0;
    WEAPON_STANDARD_EPC = 1;
    WEAPON_PLASMA_SPREADER = 2;
    WEAPON_SEEKING_MISSILES = 3;
    WEAPON_NUKE = 4;
    WEAPON_PHASE_TORPEDOES = 5;
    WEAPON_GRAVITY_WAVE = 6;
    WEAPON_ENHANCED_EPC = 7;
    WEAPON_SUPER_EPC = 8;
    AMMO_SHELLS = 0;
    AMMO_MISSILES = 1;
    AMMO_TORPEDOES = 2;
    AMMO_NUKES = 3;
    /// <summary>The ammo "type" of a weapon that needs none</summary>
    NO_AMMO = -1;
    WEAPON_SIDE_OFFSET = 32 * FRACUNIT;
    WEAPON_Z_OFFSET = 32 * FRACUNIT;
    /// <summary>A missile does not leave the craft higher or lower than this</summary>
    MAX_WEAPON_Z_OFFSET = 32 * FRACUNIT;
    PLASMA_ENERGY_DRAIN_TICS = 5;
    /// <summary>One second without regeneration after an energy weapon fires</summary>
    PLASMA_ENERGY_FIRE_TICS = 35;
    /// <summary>At least 2 points of energy to fire an energy weapon</summary>
    PLASMA_ENERGY_MIN = 2;
    /// <summary>The energy of a gravity wave (GAMEDEF can change it)</summary>
    GRAVITY_WAVE_ENERGY = 30;
    /// <summary>The seeking missiles leave in pairs</summary>
    SEEKING_MISSILES_PER_SHOT = 2;
    PLASMA_BOMB_RADIUS = 2048 * FRACUNIT;
    PLASMA_BOMB_DAMAGE = 50;
    /// <summary>The tics of the flash of a plasma bomb: no other bomb until they are over</summary>
    PLASMA_BOMB_TICS = 8;
    NEUTRON_LEVELS = 7;
  public
    /// <summary>The tics between two shots of a weapon</summary>
    /// <param name="AFast">The "fast weapon refire" option of Rad-X</param>
    class function RefireTics(AWeapon: Integer; AFast: Boolean): Integer; static;
    /// <summary>False while the weapon fired less than ARefireTics ago</summary>
    class function CanRefire(ALevelTime, ALastFire, ARefireTics: Integer): Boolean; static;
    /// <summary>The fire level (0..3) of a level (0..6) of the neutron cannons or of the spreader</summary>
    class function FireLevel(ALevel: Integer): Integer; static;
    /// <summary>The craft has the energy to fire an energy weapon</summary>
    class function HasPlasmaEnergy(AEnergy: Integer): Boolean; static;
    /// <summary>
    ///   One shot of an energy weapon: every PLASMA_ENERGY_DRAIN_TICS units of AAmount a point
    ///   of the reserve (or of the energy when there is none) is consumed
    /// </summary>
    class procedure DrainPlasmaEnergy(var AEnergy: TRadixWeaponEnergy; AAmount: Integer); static;
    /// <summary>The volley of the neutron cannons. Call it only when HasPlasmaEnergy</summary>
    /// <param name="ALevel">The level of the cannons (0..6)</param>
    /// <param name="AAlternate">The left/right flag of the weapon</param>
    /// <param name="AVanillaLevel1">The first level fires both cannons every second shot, as Radix did</param>
    class function NeutronVolley(ALevel, AEnergy: Integer; AAlternate, AVanillaLevel1: Boolean): TRadixVolley; static;
    /// <summary>The volley of the plasma spreader. Call it only when HasPlasmaEnergy</summary>
    class function SpreaderVolley(ALevel, AEnergy: Integer; AAlternate, AVanillaLevel1: Boolean): TRadixVolley; static;
    /// <summary>How many shells a pattern of the EPC has</summary>
    class function EpcSize(ATable: TRadixEpcTable): Integer; static;
    /// <summary>The spread of the shells of a pattern: lower is more accurate, 0 is none</summary>
    class function EpcAccuracy(ATable: TRadixEpcTable): Integer; static;
    /// <summary>Where the shell AIndex of a pattern leaves the craft</summary>
    class function EpcShot(ATable: TRadixEpcTable; AIndex: Integer): TRadixShot; static;
    /// <summary>The shells that are fired: the whole pattern, or the ones that are left</summary>
    class function EpcShells(AAmmo, ASize: Integer): Integer; static;
    /// <summary>
    ///   The weapon can fire: the gravity wave needs its energy, the seeking missiles two of
    ///   them, the others one unit of their ammo when they have one
    /// </summary>
    /// <param name="AAmmo">The ammo of the weapon; ignored when AAmmoType is NO_AMMO</param>
    class function CanFire(AWeapon, AAmmoType, AAmmo, AEnergy, AGravityWaveEnergy: Integer): Boolean; static;
    /// <summary>The weapon the craft changes to when the one in use cannot fire</summary>
    /// <param name="AShareware">Torpedoes and nukes are not of the shareware game</param>
    class function NextWeapon(const AOwned: array of Boolean; const AAmmo: array of Integer;
      ANeutronCannonLevel: Integer; AShareware: Boolean): Integer; static;
    /// <summary>
    ///   The weapon the craft changes to after the last gravity wave: the first one it owns
    ///   (the loop of Rad-X went down to it); -1 when it owns none
    /// </summary>
    class function WeaponAfterGravityWave(const AOwned: array of Boolean): Integer; static;
    /// <summary>A plasma bomb can be fired: there is one and the flash of the last one is over</summary>
    class function CanFirePlasmaBomb(ABombs, AFlashTics: Integer): Boolean; static;
  end;

implementation

const
  REFIRE_TICS: array[0..TRadixWeaponRules.WEAPONS - 1] of Integer = (5, 2, 5, 20, 18, 20, 35, 2, 3);
  // the phase torpedoes had no "alt refire" in d_items of Rad-X: 0, they refire at every tic
  FAST_REFIRE_TICS: array[0..TRadixWeaponRules.WEAPONS - 1] of Integer = (3, 2, 3, 18, 16, 0, 30, 2, 3);
  FIRE_LEVELS: array[0..TRadixWeaponRules.NEUTRON_LEVELS - 1] of Integer = (0, 1, 1, 2, 2, 2, 3);

  SIDE = TRadixWeaponRules.WEAPON_SIDE_OFFSET;
  UNIT_ = TRadixWeaponRules.FRACUNIT;
  ZOFS = TRadixWeaponRules.WEAPON_Z_OFFSET;

  STANDARD_EPC: array[0..1] of TRadixShot = (
    (Offset: -SIDE; Z: -32 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: SIDE; Z: -32 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard));
  ENHANCED_EPC: array[0..3] of TRadixShot = (
    (Offset: -SIDE; Z: 32 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: SIDE; Z: 32 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: -SIDE; Z: -32 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: SIDE; Z: -32 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard));
  SUPER_EPC_1: array[0..5] of TRadixShot = (
    (Offset: 0; Z: 32 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: 28 * SIDE div 32; Z: 16 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: 28 * SIDE div 32; Z: -16 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: 0; Z: -32 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: -28 * SIDE div 32; Z: -16 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: -28 * SIDE div 32; Z: 16 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard));
  SUPER_EPC_2: array[0..5] of TRadixShot = (
    (Offset: 16 * SIDE div 32; Z: 28 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: 32 * SIDE div 32; Z: 0 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: 16 * SIDE div 32; Z: -28 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: -16 * SIDE div 32; Z: -28 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: -32 * SIDE div 32; Z: 0 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard),
    (Offset: -16 * SIDE div 32; Z: 28 * UNIT_ + ZOFS; Kind: TRadixShotKind.Standard));

procedure AddShot(var AVolley: TRadixVolley; AKind: TRadixShotKind; AOffset, AZ: Integer);
begin
  AVolley.Shots[AVolley.Count].Kind := AKind;
  AVolley.Shots[AVolley.Count].Offset := AOffset;
  AVolley.Shots[AVolley.Count].Z := AZ;
  Inc(AVolley.Count);
end;

{ TRadixWeaponRules }

class function TRadixWeaponRules.RefireTics(AWeapon: Integer; AFast: Boolean): Integer;
begin
  if (AWeapon < 0) or (AWeapon >= WEAPONS) then
    Exit(0);
  if AFast then
    Result := FAST_REFIRE_TICS[AWeapon]
  else
    Result := REFIRE_TICS[AWeapon];
end;

class function TRadixWeaponRules.CanRefire(ALevelTime, ALastFire, ARefireTics: Integer): Boolean;
begin
  Result := ALevelTime - ALastFire >= ARefireTics;
end;

class function TRadixWeaponRules.FireLevel(ALevel: Integer): Integer;
begin
  if ALevel < 0 then
    Result := FIRE_LEVELS[0]
  else if ALevel >= NEUTRON_LEVELS then
    Result := FIRE_LEVELS[NEUTRON_LEVELS - 1]
  else
    Result := FIRE_LEVELS[ALevel];
end;

class function TRadixWeaponRules.HasPlasmaEnergy(AEnergy: Integer): Boolean;
begin
  Result := AEnergy >= PLASMA_ENERGY_MIN;
end;

class procedure TRadixWeaponRules.DrainPlasmaEnergy(var AEnergy: TRadixWeaponEnergy; AAmount: Integer);
begin
  AEnergy.FireTics := PLASMA_ENERGY_FIRE_TICS;
  if AEnergy.Countdown <= 0 then
  begin
    if AEnergy.Reserve > 0 then
      Dec(AEnergy.Reserve)
    else if AEnergy.Energy > 0 then
      Dec(AEnergy.Energy);
    AEnergy.Countdown := PLASMA_ENERGY_DRAIN_TICS;
  end
  else
    Dec(AEnergy.Countdown, AAmount);
end;

class function TRadixWeaponRules.NeutronVolley(ALevel, AEnergy: Integer;
  AAlternate, AVanillaLevel1: Boolean): TRadixVolley;
const
  KIND = TRadixShotKind.Standard;
  LOW = -32 * FRACUNIT + WEAPON_Z_OFFSET;
  HIGH = 32 * FRACUNIT + WEAPON_Z_OFFSET;
  SINGLE = -8 * FRACUNIT + WEAPON_Z_OFFSET;
var
  LLevel: Integer;
  LOutOfEnergy: Boolean;
begin
  Result := Default(TRadixVolley);
  Result.Alternate := AAlternate;

  LOutOfEnergy := False;
  LLevel := FireLevel(ALevel);
  if (LLevel > 0) and (AEnergy < 2 * PLASMA_ENERGY_MIN) then
  begin
    // low on energy: only the base level fires
    LOutOfEnergy := True;
    LLevel := 0;
  end;

  case LLevel of
    0:
      if AVanillaLevel1 then
      begin
        if AAlternate then
        begin
          if LOutOfEnergy then
            Result.Drain := 2
          else
            Result.Drain := 3;
          AddShot(Result, KIND, -WEAPON_SIDE_OFFSET, LOW);
          AddShot(Result, KIND, WEAPON_SIDE_OFFSET, LOW);
        end;
        Result.Alternate := not AAlternate;
      end
      else
      begin
        Result.Drain := 2;
        if AAlternate then
          AddShot(Result, KIND, -WEAPON_SIDE_OFFSET, SINGLE)
        else
          AddShot(Result, KIND, WEAPON_SIDE_OFFSET, SINGLE);
        Result.Alternate := not AAlternate;
      end;
    1:
      begin
        Result.Drain := 3;
        AddShot(Result, KIND, -WEAPON_SIDE_OFFSET, LOW);
        AddShot(Result, KIND, WEAPON_SIDE_OFFSET, LOW);
      end;
    2:
      begin
        Result.Drain := 3;
        AddShot(Result, KIND, -WEAPON_SIDE_OFFSET, LOW);
        // the third cannon of Rad-X is in the middle, without the offset of the others
        AddShot(Result, KIND, 0, 32 * FRACUNIT);
        AddShot(Result, KIND, WEAPON_SIDE_OFFSET, LOW);
      end;
  else
    Result.Drain := 3;
    AddShot(Result, KIND, -WEAPON_SIDE_OFFSET, LOW);
    AddShot(Result, KIND, -WEAPON_SIDE_OFFSET, HIGH);
    AddShot(Result, KIND, WEAPON_SIDE_OFFSET, LOW);
    AddShot(Result, KIND, WEAPON_SIDE_OFFSET, HIGH);
  end;
end;

class function TRadixWeaponRules.SpreaderVolley(ALevel, AEnergy: Integer;
  AAlternate, AVanillaLevel1: Boolean): TRadixVolley;
const
  LEFT = TRadixShotKind.SpreadLeft;
  RIGHT = TRadixShotKind.SpreadRight;
  LOW = -32 * FRACUNIT + WEAPON_Z_OFFSET;
  HIGH = 32 * FRACUNIT + WEAPON_Z_OFFSET;
  SINGLE = -8 * FRACUNIT + WEAPON_Z_OFFSET;
var
  LLevel: Integer;
begin
  Result := Default(TRadixVolley);
  Result.Alternate := AAlternate;

  LLevel := FireLevel(ALevel);
  if (LLevel > 0) and (AEnergy < 2 * PLASMA_ENERGY_MIN) then
    LLevel := 0; // low on energy: only the base level fires

  case LLevel of
    0:
      begin
        // the energy goes down also at the shot that, as Radix did, fires nothing
        Result.Drain := 1;
        if AVanillaLevel1 then
        begin
          if AAlternate then
          begin
            AddShot(Result, LEFT, -WEAPON_SIDE_OFFSET, LOW);
            AddShot(Result, RIGHT, WEAPON_SIDE_OFFSET, LOW);
          end;
        end
        else if AAlternate then
          AddShot(Result, LEFT, -WEAPON_SIDE_OFFSET, SINGLE)
        else
          AddShot(Result, RIGHT, WEAPON_SIDE_OFFSET, SINGLE);
        Result.Alternate := not AAlternate;
      end;
    1:
      begin
        Result.Drain := 1;
        AddShot(Result, LEFT, -WEAPON_SIDE_OFFSET, LOW);
        AddShot(Result, RIGHT, WEAPON_SIDE_OFFSET, LOW);
      end;
    2:
      begin
        Result.Drain := 2;
        AddShot(Result, LEFT, -WEAPON_SIDE_OFFSET, LOW);
        AddShot(Result, RIGHT, WEAPON_SIDE_OFFSET, LOW);
        if AAlternate then
          AddShot(Result, RIGHT, -WEAPON_SIDE_OFFSET, HIGH)
        else
          AddShot(Result, LEFT, WEAPON_SIDE_OFFSET, HIGH);
        Result.Alternate := not AAlternate;
      end;
  else
    Result.Drain := 3;
    AddShot(Result, LEFT, WEAPON_SIDE_OFFSET, LOW);
    AddShot(Result, RIGHT, WEAPON_SIDE_OFFSET, HIGH);
    AddShot(Result, RIGHT, -WEAPON_SIDE_OFFSET, LOW);
    AddShot(Result, LEFT, -WEAPON_SIDE_OFFSET, HIGH);
  end;
end;

class function TRadixWeaponRules.EpcSize(ATable: TRadixEpcTable): Integer;
begin
  case ATable of
    TRadixEpcTable.Standard:
      Result := Length(STANDARD_EPC);
    TRadixEpcTable.Enhanced:
      Result := Length(ENHANCED_EPC);
    TRadixEpcTable.Super1:
      Result := Length(SUPER_EPC_1);
  else
    Result := Length(SUPER_EPC_2);
  end;
end;

class function TRadixWeaponRules.EpcAccuracy(ATable: TRadixEpcTable): Integer;
begin
  case ATable of
    TRadixEpcTable.Standard:
      Result := 1;
    TRadixEpcTable.Enhanced:
      Result := 2;
  else
    Result := 3;
  end;
end;

class function TRadixWeaponRules.EpcShot(ATable: TRadixEpcTable; AIndex: Integer): TRadixShot;
begin
  if (AIndex < 0) or (AIndex >= EpcSize(ATable)) then
    Exit(Default(TRadixShot));
  case ATable of
    TRadixEpcTable.Standard:
      Result := STANDARD_EPC[AIndex];
    TRadixEpcTable.Enhanced:
      Result := ENHANCED_EPC[AIndex];
    TRadixEpcTable.Super1:
      Result := SUPER_EPC_1[AIndex];
  else
    Result := SUPER_EPC_2[AIndex];
  end;
end;

class function TRadixWeaponRules.EpcShells(AAmmo, ASize: Integer): Integer;
begin
  if AAmmo >= ASize then
    Result := ASize
  else if AAmmo > 0 then
    Result := AAmmo
  else
    Result := 0;
end;

class function TRadixWeaponRules.CanFire(AWeapon, AAmmoType, AAmmo, AEnergy,
  AGravityWaveEnergy: Integer): Boolean;
begin
  if (AWeapon = WEAPON_GRAVITY_WAVE) and (AEnergy < AGravityWaveEnergy) then
    Result := False
  else if (AWeapon = WEAPON_SEEKING_MISSILES) and (AAmmo < SEEKING_MISSILES_PER_SHOT) then
    Result := False
  else
    Result := (AAmmoType = NO_AMMO) or (AAmmo > 0);
end;

class function TRadixWeaponRules.NextWeapon(const AOwned: array of Boolean; const AAmmo: array of Integer;
  ANeutronCannonLevel: Integer; AShareware: Boolean): Integer;

  function Owned(AWeapon: Integer): Boolean;
  begin
    Result := (AWeapon < Length(AOwned)) and AOwned[AWeapon];
  end;

  function Ammo(AType: Integer): Integer;
  begin
    if AType < Length(AAmmo) then
      Result := AAmmo[AType]
    else
      Result := 0;
  end;

begin
  if Owned(WEAPON_PHASE_TORPEDOES) and (Ammo(AMMO_TORPEDOES) <> 0) and not AShareware then
    Result := WEAPON_PHASE_TORPEDOES
  else if Owned(WEAPON_NUKE) and (Ammo(AMMO_NUKES) > 0) and not AShareware then
    Result := WEAPON_NUKE
  else if Owned(WEAPON_SEEKING_MISSILES) and (Ammo(AMMO_MISSILES) <> 0) then
    Result := WEAPON_SEEKING_MISSILES
  // Rad-X looked at the level of the cannons here, not at the one of the spreader
  else if Owned(WEAPON_PLASMA_SPREADER) and (ANeutronCannonLevel < 1) then
    Result := WEAPON_PLASMA_SPREADER
  else
    Result := WEAPON_NEUTRON_CANNONS;
end;

class function TRadixWeaponRules.WeaponAfterGravityWave(const AOwned: array of Boolean): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := 0 to WEAPON_GRAVITY_WAVE - 1 do
    if (LIndex < Length(AOwned)) and AOwned[LIndex] then
      Exit(LIndex);
end;

class function TRadixWeaponRules.CanFirePlasmaBomb(ABombs, AFlashTics: Integer): Boolean;
begin
  Result := (ABombs > 0) and (AFlashTics = 0);
end;

end.
