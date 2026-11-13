{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - types of the weapon configuration                      }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): projectileinfo_t,   }
{  weaponinfo_t and the flags of code\game\be_ai_weap.h. Based on the Quake    }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weapon.Types;

interface

uses
  DelphiDoom.BotAi.Struct.Types;

const
  /// <summary>Projectile flags</summary>
  PFL_WINDOWDAMAGE = 1;
  PFL_RETURN = 2;
  /// <summary>Weapon flags</summary>
  WFL_FIRERELEASED = 1;
  /// <summary>Damage types</summary>
  DAMAGETYPE_IMPACT = 1;
  DAMAGETYPE_RADIAL = 2;
  DAMAGETYPE_VISIBLE = 4;

type
  /// <summary>vec3_t</summary>
  TBotVector = array[0..2] of Single;

  /// <summary>
  ///   projectileinfo_t, with the layout of the C structure (208 bytes): the configuration files are read
  ///   into it through the offsets of the fields, as the original does.
  /// </summary>
  TBotProjectileInfo = packed record
    Name: array[0..MAX_STRINGFIELD - 1] of AnsiChar;
    Model: array[0..MAX_STRINGFIELD - 1] of AnsiChar;
    Flags: Integer;
    Gravity: Single;
    Damage: Integer;
    Radius: Single;
    VisDamage: Integer;
    DamageType: Integer;
    HealthInc: Integer;
    Push: Single;
    Detonation: Single;
    Bounce: Single;
    BounceFriction: Single;
    BounceStop: Single;
  end;

  /// <summary>weaponinfo_t, with the layout of the C structure (552 bytes)</summary>
  TBotWeaponInfo = packed record
    /// <summary>true if the weapon info is valid (a Byte-sized boolean would not keep the layout)</summary>
    Valid: Integer;
    Number: Integer;
    Name: array[0..MAX_STRINGFIELD - 1] of AnsiChar;
    Model: array[0..MAX_STRINGFIELD - 1] of AnsiChar;
    Level: Integer;
    WeaponIndex: Integer;
    Flags: Integer;
    Projectile: array[0..MAX_STRINGFIELD - 1] of AnsiChar;
    NumProjectiles: Integer;
    HorizontalSpread: Single;
    VerticalSpread: Single;
    Speed: Single;
    Acceleration: Single;
    Recoil: TBotVector;
    Offset: TBotVector;
    AngleOffset: TBotVector;
    ExtraZVelocity: Single;
    AmmoAmount: Integer;
    AmmoIndex: Integer;
    Activate: Single;
    Reload: Single;
    SpinUp: Single;
    SpinDown: Single;
    /// <summary>The projectile used by the weapon (a copy, not a pointer)</summary>
    Proj: TBotProjectileInfo;
  end;

/// <summary>A text of a C structure: the characters up to the first zero</summary>
function BotFieldText(const AField: array of AnsiChar): AnsiString;

implementation

function BotFieldText(const AField: array of AnsiChar): AnsiString;
var
  LLength: Integer;
begin
  LLength := 0;
  while (LLength < Length(AField)) and (AField[LLength] <> #0) do
    Inc(LLength);
  SetString(Result, PAnsiChar(@AField[0]), LLength);
end;

end.
