{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixDamageRules                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the damage of P_DamageMobj (p_inter.pas), PIT_CheckThing            }
{  (p_map.pas) and P_GetThingDamage (g_gameplay.pas) of Rad-X                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Physics.Damage;

interface

type
  /// <summary>
  ///   The damage of Radix: how much of a hit reaches a craft at each skill, the damage of a
  ///   missile with an alternate one, the damage of a thing that a pilot touches
  /// </summary>
  TRadixDamageRules = class
  public const
    /// <summary>The hardest skill (sk_nightmare): the hit is not scaled</summary>
    NIGHTMARE_SKILL = 4;
  public
    /// <summary>
    ///   What is left of a hit to a craft: damage * (1 + skill) div 5 below the hardest skill,
    ///   then * (128 + random) div 384; never less than 1
    /// </summary>
    /// <param name="ASkill">0 (sk_baby) .. 4 (sk_nightmare)</param>
    /// <param name="ARandom">A number of the game generator, 0..255</param>
    class function CraftDamage(ADamage, ASkill, ARandom: Integer): Integer; static;
    /// <summary>
    ///   The damage of a thing: the alternate one for a thing that has it (MF3_EX_USEALTDAMAGE)
    ///   when the option "vanilla player weapon damage" is on, never in a demo
    /// </summary>
    class function ThingDamage(ADamage, AAltDamage: Integer; AUseAltDamage, AVanillaWeaponDamage,
      ADemo: Boolean): Integer; static;
    /// <summary>
    ///   The damage that a thing takes when another one touches it; 0 for none. Rad-X tested
    ///   MF3_EX_DAMAGEONPLAYERTOUCH with "or" in the place of "and": every shootable thing with
    ///   a touch damage takes it from a pilot, with the flag or without. Kept
    /// </summary>
    /// <param name="ADamageWhenTouched">MF3_EX_DAMAGEWHENTOUCHED: any thing that touches counts</param>
    class function TouchDamage(AShootable: Boolean; AHealth, ATouchDamage: Integer; ADamageWhenTouched,
      AToucherIsPlayer: Boolean): Integer; static;
  end;

implementation

{ TRadixDamageRules }

class function TRadixDamageRules.CraftDamage(ADamage, ASkill, ARandom: Integer): Integer;
begin
  Result := ADamage;
  if ASkill <> NIGHTMARE_SKILL then
  begin
    Result := Integer(Int64(Result) * (1 + ASkill) div (1 + NIGHTMARE_SKILL));
    if Result < 1 then
      Result := 1;
  end;
  Result := Integer(Int64(Result) * (128 + ARandom) div 384);
  if Result < 1 then
    Result := 1;
end;

class function TRadixDamageRules.ThingDamage(ADamage, AAltDamage: Integer; AUseAltDamage, AVanillaWeaponDamage,
  ADemo: Boolean): Integer;
begin
  if AVanillaWeaponDamage and AUseAltDamage and not ADemo then
    Result := AAltDamage
  else
    Result := ADamage;
end;

class function TRadixDamageRules.TouchDamage(AShootable: Boolean; AHealth, ATouchDamage: Integer;
  ADamageWhenTouched, AToucherIsPlayer: Boolean): Integer;
begin
  Result := 0;
  if not AShootable or (AHealth <= 0) or (ATouchDamage <= 0) then
    Exit;
  if ADamageWhenTouched or AToucherIsPlayer then
    Result := ATouchDamage;
end;

end.
