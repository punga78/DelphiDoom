{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - the rows of statistics that the         }
{  articles of OpenXcom show (the parts of ArticleState*.cpp without widgets)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleFormat;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleUnit,
  DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomUfopaedia.Types;

type
  /// <summary>
  ///   What the articles write in their lists, as ids of labels and values: the UFO and the TFTD articles of the
  ///   same kind show the same rows in different places. No state
  /// </summary>
  TXcomArticleFormat = class
  public
    /// <summary>ArticleState::getDamageTypeText: the id of the name of a kind of damage (STR_UNKNOWN for the others)</summary>
    class function DamageTypeText(ADamageType: Integer): string; static;
    /// <summary>Unicode::formatPercentage</summary>
    class function FormatPercentage(AValue: Integer): string; static;
    /// <summary>The number as an ostream writes it, with a plus before a positive one when APlus</summary>
    class function Signed(AValue: Integer; APlus: Boolean): string; static;
    /// <summary>The power of an item, followed by "x" and the pellets of a shotgun when AWithPellets</summary>
    class function PowerText(AItem: TXcomRuleItem; AWithPellets: Boolean = True): string; static;
    /// <summary>
    ///   The rows of an armor: the five sides that are not zero, a blank row, the damage modifiers that are not
    ///   100%, a blank row and the bonuses to the statistics that are not zero
    /// </summary>
    class function ArmorRows(AArmor: TXcomArmor): TArray<TXcomArticleRow>; static;
    /// <summary>The rows of the shots of a firearm (auto, snap, aimed) that cost time units</summary>
    class function ShotRows(AItem: TXcomRuleItem): TArray<TXcomArticleShot>; static;
    /// <summary>The first seven rows of a vehicle: time units, health and the five sides of its armor</summary>
    class function VehicleBodyRows(AUnit: TXcomRuleUnit; AArmor: TXcomArmor): TArray<TXcomArticleRow>; static;
    /// <summary>
    ///   The rows of the weapon of a vehicle: the weapon, and its power alone (AAmmo nil) or the power of the
    ///   ammunition, its name and the rounds
    /// </summary>
    class function VehicleWeaponRows(const AWeaponId: string; AItem, AAmmo: TXcomRuleItem)
      : TArray<TXcomArticleRow>; static;
    /// <summary>The defense rows of a base facility (value and hit ratio), none without defense</summary>
    class function FacilityDefenseRows(AFacility: TXcomRuleBaseFacility): TArray<TXcomArticleRow>; static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomUi.Math;

{ TXcomArticleFormat }

class function TXcomArticleFormat.DamageTypeText(ADamageType: Integer): string;
begin
  case ADamageType of
    TXcomRuleItem.DT_AP:
      Result := 'STR_DAMAGE_ARMOR_PIERCING';
    TXcomRuleItem.DT_IN:
      Result := 'STR_DAMAGE_INCENDIARY';
    TXcomRuleItem.DT_HE:
      Result := 'STR_DAMAGE_HIGH_EXPLOSIVE';
    TXcomRuleItem.DT_LASER:
      Result := 'STR_DAMAGE_LASER_BEAM';
    TXcomRuleItem.DT_PLASMA:
      Result := 'STR_DAMAGE_PLASMA_BEAM';
    TXcomRuleItem.DT_STUN:
      Result := 'STR_DAMAGE_STUN';
    TXcomRuleItem.DT_MELEE:
      Result := 'STR_DAMAGE_MELEE';
    TXcomRuleItem.DT_ACID:
      Result := 'STR_DAMAGE_ACID';
    TXcomRuleItem.DT_SMOKE:
      Result := 'STR_DAMAGE_SMOKE';
  else
    Result := 'STR_UNKNOWN';
  end;
end;

class function TXcomArticleFormat.FormatPercentage(AValue: Integer): string;
begin
  Result := IntToStr(AValue) + '%';
end;

class function TXcomArticleFormat.Signed(AValue: Integer; APlus: Boolean): string;
begin
  Result := IntToStr(AValue);
  if APlus and (AValue > 0) then
    Result := '+' + Result;
end;

class function TXcomArticleFormat.PowerText(AItem: TXcomRuleItem; AWithPellets: Boolean): string;
begin
  Result := IntToStr(AItem.Power);
  if AWithPellets and (AItem.ShotgunPellets <> 0) then
    Result := Result + 'x' + IntToStr(AItem.ShotgunPellets);
end;

class function TXcomArticleFormat.ArmorRows(AArmor: TXcomArmor): TArray<TXcomArticleRow>;
var
  LRows: TList<TXcomArticleRow>;
  LType, LPercentage: Integer;
  LScaled: Single;
  LDamage: string;
  LStats: TXcomUnitStats;

  procedure AddStat(const ALabelId: string; AValue: Integer; APlus: Boolean);
  begin
    if AValue <> 0 then
      LRows.Add(TXcomArticleRow.Make(ALabelId, Signed(AValue, APlus)));
  end;

begin
  LRows := TList<TXcomArticleRow>.Create;
  try
    AddStat('STR_FRONT_ARMOR', AArmor.FrontArmor, False);
    AddStat('STR_LEFT_ARMOR', AArmor.SideArmor, False);
    AddStat('STR_RIGHT_ARMOR', AArmor.SideArmor, False);
    AddStat('STR_REAR_ARMOR', AArmor.RearArmor, False);
    AddStat('STR_UNDER_ARMOR', AArmor.UnderArmor, False);
    LRows.Add(TXcomArticleRow.MakeBlank);
    for LType := 0 to TXcomArmor.DAMAGE_TYPES - 1 do
    begin
      // (int)Round(modifier * 100.0f): the product is a float
      LScaled := AArmor.DamageModifier[LType] * 100;
      LPercentage := TXcomMath.RoundToInt(LScaled);
      LDamage := DamageTypeText(LType);
      if (LPercentage <> 100) and (LDamage <> 'STR_UNKNOWN') then
        LRows.Add(TXcomArticleRow.Make(LDamage, FormatPercentage(LPercentage)));
    end;
    LRows.Add(TXcomArticleRow.MakeBlank);
    LStats := AArmor.Stats;
    AddStat('STR_TIME_UNITS', LStats.TimeUnits, True);
    AddStat('STR_STAMINA', LStats.Stamina, True);
    AddStat('STR_HEALTH', LStats.Health, True);
    AddStat('STR_BRAVERY', LStats.Bravery, True);
    AddStat('STR_REACTIONS', LStats.Reactions, True);
    AddStat('STR_FIRING_ACCURACY', LStats.Firing, True);
    AddStat('STR_THROWING_ACCURACY', LStats.Throwing, True);
    AddStat('STR_MELEE_ACCURACY', LStats.Melee, True);
    AddStat('STR_STRENGTH', LStats.Strength, True);
    AddStat('STR_PSIONIC_STRENGTH', LStats.PsiStrength, True);
    AddStat('STR_PSIONIC_SKILL', LStats.PsiSkill, True);
    Result := LRows.ToArray;
  finally
    LRows.Free;
  end;
end;

class function TXcomArticleFormat.ShotRows(AItem: TXcomRuleItem): TArray<TXcomArticleShot>;
var
  LRows: TList<TXcomArticleShot>;

  procedure AddShot(const ALabelId: string; ACost, AAccuracy: Integer);
  var
    LShot: TXcomArticleShot;
  begin
    if ACost <= 0 then
      Exit;
    LShot.LabelId := ALabelId;
    LShot.Accuracy := FormatPercentage(AAccuracy);
    // a flat rate is a number of time units, not a part of them: no percent sign
    if AItem.FlatRate then
      LShot.Cost := IntToStr(ACost)
    else
      LShot.Cost := FormatPercentage(ACost);
    LRows.Add(LShot);
  end;

begin
  LRows := TList<TXcomArticleShot>.Create;
  try
    AddShot('STR_SHOT_TYPE_AUTO', AItem.TimeUnitsAuto, AItem.AccuracyAuto);
    AddShot('STR_SHOT_TYPE_SNAP', AItem.TimeUnitsSnap, AItem.AccuracySnap);
    AddShot('STR_SHOT_TYPE_AIMED', AItem.TimeUnitsAimed, AItem.AccuracyAimed);
    Result := LRows.ToArray;
  finally
    LRows.Free;
  end;
end;

class function TXcomArticleFormat.VehicleBodyRows(AUnit: TXcomRuleUnit; AArmor: TXcomArmor)
  : TArray<TXcomArticleRow>;
begin
  Result := [
    TXcomArticleRow.Make('STR_TIME_UNITS', IntToStr(AUnit.Stats.TimeUnits)),
    TXcomArticleRow.Make('STR_HEALTH', IntToStr(AUnit.Stats.Health)),
    TXcomArticleRow.Make('STR_FRONT_ARMOR', IntToStr(AArmor.FrontArmor)),
    TXcomArticleRow.Make('STR_LEFT_ARMOR', IntToStr(AArmor.SideArmor)),
    TXcomArticleRow.Make('STR_RIGHT_ARMOR', IntToStr(AArmor.SideArmor)),
    TXcomArticleRow.Make('STR_REAR_ARMOR', IntToStr(AArmor.RearArmor)),
    TXcomArticleRow.Make('STR_UNDER_ARMOR', IntToStr(AArmor.UnderArmor))];
end;

class function TXcomArticleFormat.VehicleWeaponRows(const AWeaponId: string; AItem, AAmmo: TXcomRuleItem)
  : TArray<TXcomArticleRow>;
var
  LRounds: Integer;
begin
  if not Assigned(AAmmo) then
  begin
    Result := [
      TXcomArticleRow.Make('STR_WEAPON', AWeaponId, True),
      TXcomArticleRow.Make('STR_WEAPON_POWER', IntToStr(AItem.Power))];
    Exit;
  end;
  if AItem.ClipSize > 0 then
    LRounds := AItem.ClipSize
  else
    LRounds := AAmmo.ClipSize;
  Result := [
    TXcomArticleRow.Make('STR_WEAPON', AWeaponId, True),
    TXcomArticleRow.Make('STR_WEAPON_POWER', IntToStr(AAmmo.Power)),
    TXcomArticleRow.Make('STR_AMMUNITION', AAmmo.Name, True),
    TXcomArticleRow.Make('STR_ROUNDS', IntToStr(LRounds))];
end;

class function TXcomArticleFormat.FacilityDefenseRows(AFacility: TXcomRuleBaseFacility): TArray<TXcomArticleRow>;
begin
  if AFacility.DefenseValue <= 0 then
    Exit(nil);
  Result := [
    TXcomArticleRow.Make('STR_DEFENSE_VALUE', IntToStr(AFacility.DefenseValue)),
    TXcomArticleRow.Make('STR_HIT_RATIO', FormatPercentage(AFacility.HitRatio))];
end;

end.
