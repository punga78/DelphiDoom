{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a craft weapon (RuleCraftWeapon)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleCraftWeapon;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.ModOffsets;

type
  /// <summary>
  ///   Constant data of a type of craft weapon: damage, range, accuracy, reload times, ammunition, the items it
  ///   uses and the sprite and sound (RuleCraftWeapon)
  /// </summary>
  TXcomRuleCraftWeapon = class
  strict private
    FType: string;
    FSprite: Integer;
    FSound: Integer;
    FDamage: Integer;
    FRange: Integer;
    FAccuracy: Integer;
    FReloadCautious: Integer;
    FReloadStandard: Integer;
    FReloadAggressive: Integer;
    FAmmoMax: Integer;
    FRearmRate: Integer;
    FProjectileType: Integer;
    FProjectileSpeed: Integer;
    FLauncher: string;
    FClip: string;
    FUnderwaterOnly: Boolean;
  public
    const
      /// <summary>CWPT_CANNON_ROUND (the third of the enum): the projectile that a weapon has when the ruleset does not say</summary>
      PROJECTILE_CANNON_ROUND = 2;
    /// <summary>A blank ruleset for a type of craft weapon</summary>
    constructor Create(const AType: string);
    /// <summary>
    ///   Loads the weapon from a YAML node. The sprite is moved by the offset of the mod when it is over 5 (BASEBITS
    ///   and INTICON); the sound is looked up in GEO.CAT
    /// </summary>
    procedure Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets);
    property WeaponType: string read FType;
    property Sprite: Integer read FSprite;
    property Sound: Integer read FSound;
    property Damage: Integer read FDamage;
    property Range: Integer read FRange;
    property Accuracy: Integer read FAccuracy;
    property CautiousReload: Integer read FReloadCautious;
    property StandardReload: Integer read FReloadStandard;
    property AggressiveReload: Integer read FReloadAggressive;
    property AmmoMax: Integer read FAmmoMax;
    property RearmRate: Integer read FRearmRate;
    /// <summary>The number of CraftWeaponProjectileType (the C++ does not check it)</summary>
    property ProjectileType: Integer read FProjectileType;
    property ProjectileSpeed: Integer read FProjectileSpeed;
    property LauncherItem: string read FLauncher;
    property ClipItem: string read FClip;
    property UnderwaterOnly: Boolean read FUnderwaterOnly;
  end;

implementation

{ TXcomRuleCraftWeapon }

constructor TXcomRuleCraftWeapon.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FSprite := -1;
  FSound := -1;
  FRearmRate := 1;
  FProjectileType := PROJECTILE_CANNON_ROUND;
end;

procedure TXcomRuleCraftWeapon.Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets);
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  if TXcomNodeReader.Field(ANode, 'sprite').IsDefined then
    FSprite := AOffsets.GetOffset(TXcomNodeReader.ReadInteger(ANode, 'sprite', FSprite), 5);
  AOffsets.LoadSoundOffset(FType, FSound, TXcomNodeReader.Field(ANode, 'sound'), 'GEO.CAT');
  FDamage := TXcomNodeReader.ReadInteger(ANode, 'damage', FDamage);
  FRange := TXcomNodeReader.ReadInteger(ANode, 'range', FRange);
  FAccuracy := TXcomNodeReader.ReadInteger(ANode, 'accuracy', FAccuracy);
  FReloadCautious := TXcomNodeReader.ReadInteger(ANode, 'reloadCautious', FReloadCautious);
  FReloadStandard := TXcomNodeReader.ReadInteger(ANode, 'reloadStandard', FReloadStandard);
  FReloadAggressive := TXcomNodeReader.ReadInteger(ANode, 'reloadAggressive', FReloadAggressive);
  FAmmoMax := TXcomNodeReader.ReadInteger(ANode, 'ammoMax', FAmmoMax);
  FRearmRate := TXcomNodeReader.ReadInteger(ANode, 'rearmRate', FRearmRate);
  FProjectileType := TXcomNodeReader.ReadInteger(ANode, 'projectileType', FProjectileType);
  FProjectileSpeed := TXcomNodeReader.ReadInteger(ANode, 'projectileSpeed', FProjectileSpeed);
  FLauncher := TXcomNodeReader.ReadString(ANode, 'launcher', FLauncher);
  FClip := TXcomNodeReader.ReadString(ANode, 'clip', FClip);
  FUnderwaterOnly := TXcomNodeReader.ReadBoolean(ANode, 'underwaterOnly', FUnderwaterOnly);
end;

end.
