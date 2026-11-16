{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeaponConfig, the weapons and projectiles          }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): weaponconfig_t of   }
{  code\botlib\be_ai_weap.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weapon.Config;

interface

uses
  DelphiDoom.BotAi.Weapon.Types;

type
  /// <summary>
  ///   weaponconfig_t: <c>NumWeapons</c> is the size of the table of weapons (max_weaponinfo), not the
  ///   number of weapons defined: a weapon is there if its <c>Valid</c> is set. The projectiles are the
  ///   ones defined, in the order of the file.
  /// </summary>
  TBotWeaponConfig = class
  public
    NumWeapons: Integer;
    NumProjectiles: Integer;
    Weapons: TArray<TBotWeaponInfo>;
    Projectiles: TArray<TBotProjectileInfo>;
    constructor Create(const AMaxWeapons, AMaxProjectiles: Integer);
  end;

implementation

{ TBotWeaponConfig }

constructor TBotWeaponConfig.Create(const AMaxWeapons, AMaxProjectiles: Integer);
begin
  inherited Create;
  SetLength(Weapons, AMaxWeapons);
  SetLength(Projectiles, AMaxProjectiles);
  NumWeapons := AMaxWeapons;
  NumProjectiles := 0;
end;

end.
