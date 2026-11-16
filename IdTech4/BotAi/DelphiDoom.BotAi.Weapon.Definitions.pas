{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeaponDefinitions, the fields of the weapon files  }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): weaponinfo_fields,  }
{  projectileinfo_fields, weaponinfo_struct and projectileinfo_struct of       }
{  code\botlib\be_ai_weap.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weapon.Definitions;

interface

uses
  DelphiDoom.BotAi.Struct.Types;

type
  /// <summary>
  ///   The two structure descriptions. Defect of the original that is kept: the field <c>model</c> of a
  ///   projectile uses the offset of <c>weaponinfo_t.model</c> (WEAPON_OFS, 88), so the model of a
  ///   projectile is written 8 bytes into <c>model</c> and over <c>flags</c> and <c>gravity</c>.
  /// </summary>
  TBotWeaponDefinitions = class
  strict private
    FWeapon: TBotStructDefinition;
    FProjectile: TBotStructDefinition;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>weaponinfo_struct</summary>
    property Weapon: TBotStructDefinition read FWeapon;
    /// <summary>projectileinfo_struct</summary>
    property Projectile: TBotStructDefinition read FProjectile;
  end;

implementation

uses
  DelphiDoom.BotAi.Weapon.Types;

{ TBotWeaponDefinitions }

constructor TBotWeaponDefinitions.Create;
var
  LWeapon: TBotWeaponInfo;
  LProjectile: TBotProjectileInfo;
  LWeaponFields: TArray<TBotFieldDefinition>;
  LProjectileFields: TArray<TBotFieldDefinition>;

  // WEAPON_OFS(x): the offset of a field of the weapon structure
  function WeaponOffset(const AField): Integer;
  begin
    Result := NativeInt(@AField) - NativeInt(@LWeapon);
  end;

  // PROJECTILE_OFS(x)
  function ProjectileOffset(const AField): Integer;
  begin
    Result := NativeInt(@AField) - NativeInt(@LProjectile);
  end;

begin
  inherited Create;
  LWeapon := Default(TBotWeaponInfo);
  LProjectile := Default(TBotProjectileInfo);
  LWeaponFields := [
    TBotFieldDefinition.Make('number', WeaponOffset(LWeapon.Number), FT_INT),
    TBotFieldDefinition.Make('name', WeaponOffset(LWeapon.Name), FT_STRING),
    TBotFieldDefinition.Make('level', WeaponOffset(LWeapon.Level), FT_INT),
    TBotFieldDefinition.Make('model', WeaponOffset(LWeapon.Model), FT_STRING),
    TBotFieldDefinition.Make('weaponindex', WeaponOffset(LWeapon.WeaponIndex), FT_INT),
    TBotFieldDefinition.Make('flags', WeaponOffset(LWeapon.Flags), FT_INT),
    TBotFieldDefinition.Make('projectile', WeaponOffset(LWeapon.Projectile), FT_STRING),
    TBotFieldDefinition.Make('numprojectiles', WeaponOffset(LWeapon.NumProjectiles), FT_INT),
    TBotFieldDefinition.Make('hspread', WeaponOffset(LWeapon.HorizontalSpread), FT_FLOAT),
    TBotFieldDefinition.Make('vspread', WeaponOffset(LWeapon.VerticalSpread), FT_FLOAT),
    TBotFieldDefinition.Make('speed', WeaponOffset(LWeapon.Speed), FT_FLOAT),
    TBotFieldDefinition.Make('acceleration', WeaponOffset(LWeapon.Acceleration), FT_FLOAT),
    TBotFieldDefinition.Make('recoil', WeaponOffset(LWeapon.Recoil), FT_FLOAT or FT_ARRAY, 3),
    TBotFieldDefinition.Make('offset', WeaponOffset(LWeapon.Offset), FT_FLOAT or FT_ARRAY, 3),
    TBotFieldDefinition.Make('angleoffset', WeaponOffset(LWeapon.AngleOffset), FT_FLOAT or FT_ARRAY, 3),
    TBotFieldDefinition.Make('extrazvelocity', WeaponOffset(LWeapon.ExtraZVelocity), FT_FLOAT),
    TBotFieldDefinition.Make('ammoamount', WeaponOffset(LWeapon.AmmoAmount), FT_INT),
    TBotFieldDefinition.Make('ammoindex', WeaponOffset(LWeapon.AmmoIndex), FT_INT),
    TBotFieldDefinition.Make('activate', WeaponOffset(LWeapon.Activate), FT_FLOAT),
    TBotFieldDefinition.Make('reload', WeaponOffset(LWeapon.Reload), FT_FLOAT),
    TBotFieldDefinition.Make('spinup', WeaponOffset(LWeapon.SpinUp), FT_FLOAT),
    TBotFieldDefinition.Make('spindown', WeaponOffset(LWeapon.SpinDown), FT_FLOAT)];
  LProjectileFields := [
    TBotFieldDefinition.Make('name', ProjectileOffset(LProjectile.Name), FT_STRING),
    // the offset of the weapon structure, as in the original
    TBotFieldDefinition.Make('model', WeaponOffset(LWeapon.Model), FT_STRING),
    TBotFieldDefinition.Make('flags', ProjectileOffset(LProjectile.Flags), FT_INT),
    TBotFieldDefinition.Make('gravity', ProjectileOffset(LProjectile.Gravity), FT_FLOAT),
    TBotFieldDefinition.Make('damage', ProjectileOffset(LProjectile.Damage), FT_INT),
    TBotFieldDefinition.Make('radius', ProjectileOffset(LProjectile.Radius), FT_FLOAT),
    TBotFieldDefinition.Make('visdamage', ProjectileOffset(LProjectile.VisDamage), FT_INT),
    TBotFieldDefinition.Make('damagetype', ProjectileOffset(LProjectile.DamageType), FT_INT),
    TBotFieldDefinition.Make('healthinc', ProjectileOffset(LProjectile.HealthInc), FT_INT),
    TBotFieldDefinition.Make('push', ProjectileOffset(LProjectile.Push), FT_FLOAT),
    TBotFieldDefinition.Make('detonation', ProjectileOffset(LProjectile.Detonation), FT_FLOAT),
    TBotFieldDefinition.Make('bounce', ProjectileOffset(LProjectile.Bounce), FT_FLOAT),
    TBotFieldDefinition.Make('bouncefric', ProjectileOffset(LProjectile.BounceFriction), FT_FLOAT),
    TBotFieldDefinition.Make('bouncestop', ProjectileOffset(LProjectile.BounceStop), FT_FLOAT)];
  FWeapon := TBotStructDefinition.Create(SizeOf(TBotWeaponInfo), LWeaponFields);
  FProjectile := TBotStructDefinition.Create(SizeOf(TBotProjectileInfo), LProjectileFields);
end;

destructor TBotWeaponDefinitions.Destroy;
begin
  FProjectile.Free;
  FWeapon.Free;
  inherited Destroy;
end;

end.
