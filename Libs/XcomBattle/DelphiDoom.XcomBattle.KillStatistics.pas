{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the kill statistics of a unit         }
{  (BattleUnitKills::setUnitStats and the copy of a BattleUnitKills)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.KillStatistics;

interface

uses
  DelphiDoom.XcomSave.BattleUnitKills, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model;

type
  /// <summary>
  ///   What the statistics of a kill (or a panic, or a mind control) record about the victim: name or type, rank
  ///   and race by faction. Shared by the casualties and the psionic attack
  /// </summary>
  TXcomKillStatistics = class
  public
    /// <summary>BattleUnitKills::setUnitStats</summary>
    class procedure Fill(const AKill: TXcomBattleUnitKills; const AUnit: TXcomBattleUnit); static;
    /// <summary>The copy constructor of BattleUnitKills: the caller owns the new object</summary>
    class function Copy(const ASource: TXcomBattleUnitKills): TXcomBattleUnitKills; static;
  end;

implementation

class function TXcomKillStatistics.Copy(const ASource: TXcomBattleUnitKills): TXcomBattleUnitKills;
begin
  Result := TXcomBattleUnitKills.Create;
  Result.Name := ASource.Name;
  Result.UnitType := ASource.UnitType;
  Result.Rank := ASource.Rank;
  Result.Race := ASource.Race;
  Result.Weapon := ASource.Weapon;
  Result.WeaponAmmo := ASource.WeaponAmmo;
  Result.Faction := ASource.Faction;
  Result.Status := ASource.Status;
  Result.Mission := ASource.Mission;
  Result.Turn := ASource.Turn;
  Result.Id := ASource.Id;
  Result.Side := ASource.Side;
  Result.BodyPart := ASource.BodyPart;
end;

class procedure TXcomKillStatistics.Fill(const AKill: TXcomBattleUnitKills; const AUnit: TXcomBattleUnit);
begin
  AKill.Name := '';
  AKill.UnitType := '';
  if Assigned(AUnit.GeoscapeSoldier) then
    AKill.Name := AUnit.GeoscapeSoldier.Name
  else
    AKill.UnitType := AUnit.UnitType;
  if AUnit.OriginalFaction = FACTION_PLAYER then
  begin
    if Assigned(AUnit.GeoscapeSoldier) then
    begin
      if AUnit.RankString <> '' then
        AKill.Rank := AUnit.RankString
      else
        AKill.Rank := 'STR_SOLDIER';
    end
    else if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Rank <> '') then
      AKill.Rank := AUnit.UnitRules.Rank
    else
      AKill.Rank := 'STR_HWPS';
    if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Race <> '') then
      AKill.Race := AUnit.UnitRules.Race
    else
      AKill.Race := 'STR_FRIENDLY';
  end
  else if AUnit.OriginalFaction = FACTION_HOSTILE then
  begin
    if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Rank <> '') then
      AKill.Rank := AUnit.UnitRules.Rank
    else
      AKill.Rank := 'STR_LIVE_SOLDIER';
    if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Race <> '') then
      AKill.Race := AUnit.UnitRules.Race
    else
      AKill.Race := 'STR_HOSTILE';
  end
  else if AUnit.OriginalFaction = FACTION_NEUTRAL then
  begin
    if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Rank <> '') then
      AKill.Rank := AUnit.UnitRules.Rank
    else
      AKill.Rank := 'STR_CIVILIAN';
    if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Race <> '') then
      AKill.Race := AUnit.UnitRules.Race
    else
      AKill.Race := 'STR_NEUTRAL';
  end
  else
  begin
    AKill.Rank := 'STR_UNKNOWN';
    AKill.Race := 'STR_UNKNOWN';
  end;
end;

end.
