{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ruleset library - what a loaded ruleset   }
{  holds, as text lines (the same that modload.exe prints from the real Mod)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.ModDump;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Areas,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.Tests.XcomMod.DumpWriter;

type
  /// <summary>
  ///   Prints the rules of a TXcomRuleset like dump_rules.h prints those of the real Mod: one section per kind of
  ///   rule, in the order of the names, with the sections of Sections only (the ones that are ported)
  /// </summary>
  TXcomModDump = class
  strict private
    FWriter: TXcomDumpWriter;
    FMod: TXcomRuleset;
    procedure DumpAreas(const AAreas: TXcomGlobeAreas);
    procedure DumpCountries;
    procedure DumpRegions;
    procedure DumpCraftWeapons;
    procedure DumpItems;
    procedure DumpInventories;
    procedure DumpResearch;
    procedure DumpManufacture;
    procedure DumpAlienRaces;
    procedure DumpTrajectories;
    procedure DumpMusics;
    procedure DumpCommendations;
  public
    constructor Create(const AMod: TXcomRuleset);
    destructor Destroy; override;
    /// <summary>The sections that Dump prints, in order</summary>
    class function Sections: TArray<string>; static;
    /// <summary>The lines of every section of Sections</summary>
    function Dump: TStringList;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleCountry, DelphiDoom.XcomMod.RuleRegion, DelphiDoom.XcomMod.RuleCraftWeapon,
  DelphiDoom.XcomMod.RuleInventory, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomMod.RuleManufacture,
  DelphiDoom.XcomMod.AlienRace, DelphiDoom.XcomMod.UfoTrajectory, DelphiDoom.XcomMod.RuleMusic,
  DelphiDoom.XcomMod.RuleCommendations;

{ TXcomModDump }

constructor TXcomModDump.Create(const AMod: TXcomRuleset);
begin
  inherited Create;
  FMod := AMod;
  FWriter := TXcomDumpWriter.Create;
end;

destructor TXcomModDump.Destroy;
begin
  FWriter.Free;
  inherited Destroy;
end;

class function TXcomModDump.Sections: TArray<string>;
begin
  Result := TArray<string>.Create('countries', 'regions', 'craftWeapons', 'items', 'invs', 'research', 'manufacture',
    'alienRaces', 'ufoTrajectories', 'musics', 'commendations');
end;

procedure TXcomModDump.DumpAreas(const AAreas: TXcomGlobeAreas);
begin
  FWriter.Dbls('lonMin', AAreas.LonMin);
  FWriter.Dbls('lonMax', AAreas.LonMax);
  FWriter.Dbls('latMin', AAreas.LatMin);
  FWriter.Dbls('latMax', AAreas.LatMax);
end;

procedure TXcomModDump.DumpCountries;
var
  LIndex: Integer;
  LRule: TXcomRuleCountry;
begin
  for LIndex := 0 to FMod.Countries.Count - 1 do
  begin
    LRule := FMod.Countries.Rule(LIndex);
    FWriter.Begin_('countries', FMod.Countries.Name(LIndex));
    FWriter.Str('type', LRule.CountryType);
    FWriter.Int('fundingBase', LRule.FundingBase);
    FWriter.Int('fundingCap', LRule.FundingCap);
    FWriter.Dbl('labelLon', LRule.LabelLongitude);
    FWriter.Dbl('labelLat', LRule.LabelLatitude);
    DumpAreas(LRule.Areas);
  end;
end;

procedure TXcomModDump.DumpRegions;
var
  LIndex, LZone, LArea: Integer;
  LRule: TXcomRuleRegion;
  LMissionArea: TXcomMissionArea;
begin
  for LIndex := 0 to FMod.Regions.Count - 1 do
  begin
    LRule := FMod.Regions.Rule(LIndex);
    FWriter.Begin_('regions', FMod.Regions.Name(LIndex));
    FWriter.Str('type', LRule.RegionType);
    FWriter.Int('cost', LRule.BaseCost);
    FWriter.Card('weight', LRule.Weight);
    FWriter.Str('missionRegion', LRule.MissionRegion);
    DumpAreas(LRule.Areas);
    FWriter.CardMap('weights', LRule.MissionWeights.Choices);
    FWriter.Card('zones', Length(LRule.MissionZones));
    for LZone := 0 to High(LRule.MissionZones) do
      for LArea := 0 to High(LRule.MissionZones[LZone].Areas) do
      begin
        LMissionArea := LRule.MissionZones[LZone].Areas[LArea];
        FWriter.Line('zone' + IntToStr(LZone) + '_' + IntToStr(LArea),
          TXcomDumpWriter.HexDouble(LMissionArea.LonMin) + ',' + TXcomDumpWriter.HexDouble(LMissionArea.LonMax) +
          ',' + TXcomDumpWriter.HexDouble(LMissionArea.LatMin) + ',' +
          TXcomDumpWriter.HexDouble(LMissionArea.LatMax) + ',' + IntToStr(LMissionArea.Texture) + ',' +
          TXcomDumpWriter.Quote(LMissionArea.Name));
      end;
  end;
end;

procedure TXcomModDump.DumpCraftWeapons;
var
  LIndex: Integer;
  LRule: TXcomRuleCraftWeapon;
begin
  for LIndex := 0 to FMod.CraftWeapons.Count - 1 do
  begin
    LRule := FMod.CraftWeapons.Rule(LIndex);
    FWriter.Begin_('craftWeapons', FMod.CraftWeapons.Name(LIndex));
    FWriter.Str('type', LRule.WeaponType);
    FWriter.Int('sprite', LRule.Sprite);
    FWriter.Int('sound', LRule.Sound);
    FWriter.Int('damage', LRule.Damage);
    FWriter.Int('range', LRule.Range);
    FWriter.Int('accuracy', LRule.Accuracy);
    FWriter.Int('reloadCautious', LRule.CautiousReload);
    FWriter.Int('reloadStandard', LRule.StandardReload);
    FWriter.Int('reloadAggressive', LRule.AggressiveReload);
    FWriter.Int('ammoMax', LRule.AmmoMax);
    FWriter.Int('rearmRate', LRule.RearmRate);
    FWriter.Int('projectileType', LRule.ProjectileType);
    FWriter.Int('projectileSpeed', LRule.ProjectileSpeed);
    FWriter.Str('launcher', LRule.LauncherItem);
    FWriter.Str('clip', LRule.ClipItem);
    FWriter.Bool('underwaterOnly', LRule.UnderwaterOnly);
  end;
end;

procedure TXcomModDump.DumpItems;
var
  LIndex: Integer;
  LRule: TXcomRuleItem;
begin
  for LIndex := 0 to FMod.Items.Count - 1 do
  begin
    LRule := FMod.Items.Rule(LIndex);
    FWriter.Begin_('items', FMod.Items.Name(LIndex));
    FWriter.Str('type', LRule.ItemType);
    FWriter.Str('name', LRule.Name);
    FWriter.Strs('requires', LRule.Requirements);
    FWriter.Dbl('size', LRule.Size);
    FWriter.Int('costBuy', LRule.BuyCost);
    FWriter.Int('costSell', LRule.SellCost);
    FWriter.Int('transferTime', LRule.TransferTime);
    FWriter.Int('weight', LRule.Weight);
    FWriter.Int('bigSprite', LRule.BigSprite);
    FWriter.Int('floorSprite', LRule.FloorSprite);
    FWriter.Int('handSprite', LRule.HandSprite);
    FWriter.Int('bulletSprite', LRule.BulletSprite);
    FWriter.Int('fireSound', LRule.FireSound);
    FWriter.Int('hitSound', LRule.HitSound);
    FWriter.Int('hitAnimation', LRule.HitAnimation);
    FWriter.Int('power', LRule.Power);
    FWriter.Strs('compatibleAmmo', LRule.CompatibleAmmo);
    FWriter.Int('damageType', LRule.DamageType);
    FWriter.Int('accuracyAuto', LRule.AccuracyAuto);
    FWriter.Int('accuracySnap', LRule.AccuracySnap);
    FWriter.Int('accuracyAimed', LRule.AccuracyAimed);
    FWriter.Int('tuAuto', LRule.TimeUnitsAuto);
    FWriter.Int('tuSnap', LRule.TimeUnitsSnap);
    FWriter.Int('tuAimed', LRule.TimeUnitsAimed);
    FWriter.Int('clipSize', LRule.ClipSize);
    FWriter.Int('accuracyMelee', LRule.AccuracyMelee);
    FWriter.Int('tuMelee', LRule.TimeUnitsMelee);
    FWriter.Int('battleType', LRule.BattleType);
    FWriter.Bool('twoHanded', LRule.TwoHanded);
    FWriter.Bool('fixedWeapon', LRule.FixedWeapon);
    FWriter.Int('waypoints', LRule.Waypoints);
    FWriter.Int('invWidth', LRule.InventoryWidth);
    FWriter.Int('invHeight', LRule.InventoryHeight);
    FWriter.Int('painKiller', LRule.PainKiller);
    FWriter.Int('heal', LRule.Heal);
    FWriter.Int('stimulant', LRule.Stimulant);
    FWriter.Int('woundRecovery', LRule.WoundRecovery);
    FWriter.Int('healthRecovery', LRule.HealthRecovery);
    FWriter.Int('stunRecovery', LRule.StunRecovery);
    FWriter.Int('energyRecovery', LRule.EnergyRecovery);
    FWriter.Int('tuUse', LRule.TimeUnitsUse);
    FWriter.Int('recoveryPoints', LRule.RecoveryPoints);
    FWriter.Int('armor', LRule.Armor);
    FWriter.Int('turretType', LRule.TurretType);
    FWriter.Bool('recover', LRule.Recoverable);
    FWriter.Bool('ignoreInBaseDefense', LRule.IgnoreInBaseDefense);
    FWriter.Bool('liveAlien', LRule.LiveAlien);
    FWriter.Int('blastRadius', LRule.BlastRadius);
    FWriter.Int('attraction', LRule.Attraction);
    FWriter.Bool('flatRate', LRule.FlatRate);
    FWriter.Bool('arcingShot', LRule.ArcingShot);
    FWriter.Int('listOrder', LRule.ListOrder);
    FWriter.Int('maxRange', LRule.MaxRange);
    FWriter.Int('aimRange', LRule.AimRange);
    FWriter.Int('snapRange', LRule.SnapRange);
    FWriter.Int('autoRange', LRule.AutoRange);
    FWriter.Int('minRange', LRule.MinRange);
    FWriter.Int('dropoff', LRule.Dropoff);
    FWriter.Int('bulletSpeed', LRule.BulletSpeed);
    FWriter.Int('explosionSpeed', LRule.ExplosionSpeed);
    FWriter.Int('autoShots', LRule.AutoShots);
    FWriter.Int('shotgunPellets', LRule.ShotgunPellets);
    FWriter.Str('zombieUnit', LRule.ZombieUnit);
    FWriter.Bool('strengthApplied', LRule.StrengthApplied);
    FWriter.Bool('skillApplied', LRule.SkillApplied);
    FWriter.Bool('LOSRequired', LRule.LineOfSightRequired);
    FWriter.Bool('underwaterOnly', LRule.UnderwaterOnly);
    FWriter.Bool('landOnly', LRule.LandOnly);
    FWriter.Int('meleeSound', LRule.MeleeSound);
    FWriter.Int('meleePower', LRule.MeleePower);
    FWriter.Int('meleeAnimation', LRule.MeleeAnimation);
    FWriter.Int('meleeHitSound', LRule.MeleeHitSound);
    FWriter.Int('specialType', LRule.SpecialType);
    FWriter.Int('vaporColor', LRule.VaporColor);
    FWriter.Int('vaporDensity', LRule.VaporDensity);
    FWriter.Int('vaporProbability', LRule.VaporProbability);
    FWriter.Int('explosionRadius', LRule.ExplosionRadius);
    FWriter.Int('maxRangeSq', LRule.MaxRangeSquared);
    FWriter.Bool('isRifle', LRule.IsRifle);
    FWriter.Bool('isPistol', LRule.IsPistol);
  end;
end;

procedure TXcomModDump.DumpInventories;
var
  LIndex, LSlot: Integer;
  LRule: TXcomRuleInventory;
  LText: string;
begin
  for LIndex := 0 to FMod.Inventories.Count - 1 do
  begin
    LRule := FMod.Inventories.Rule(LIndex);
    FWriter.Begin_('invs', FMod.Inventories.Name(LIndex));
    FWriter.Str('id', LRule.Id);
    FWriter.Int('x', LRule.X);
    FWriter.Int('y', LRule.Y);
    FWriter.Int('type', LRule.InventoryType);
    FWriter.Int('listOrder', LRule.ListOrder);
    LText := '[';
    for LSlot := 0 to High(LRule.Slots) do
    begin
      if LSlot > 0 then
        LText := LText + ',';
      LText := LText + IntToStr(LRule.Slots[LSlot].X) + '/' + IntToStr(LRule.Slots[LSlot].Y);
    end;
    FWriter.Line('slots', LText + ']');
    FWriter.IntMap('costs', LRule.Costs);
  end;
end;

procedure TXcomModDump.DumpResearch;
var
  LIndex: Integer;
  LRule: TXcomRuleResearch;
begin
  for LIndex := 0 to FMod.Research.Count - 1 do
  begin
    LRule := FMod.Research.Rule(LIndex);
    FWriter.Begin_('research', FMod.Research.Name(LIndex));
    FWriter.Str('name', LRule.Name);
    FWriter.Str('lookup', LRule.Lookup);
    FWriter.Str('cutscene', LRule.Cutscene);
    FWriter.Int('cost', LRule.Cost);
    FWriter.Int('points', LRule.Points);
    FWriter.Strs('dependencies', LRule.Dependencies);
    FWriter.Strs('unlocks', LRule.Unlocks);
    FWriter.Strs('getOneFree', LRule.GetOneFree);
    FWriter.Strs('requires', LRule.Requirements);
    FWriter.Bool('needItem', LRule.NeedItem);
    FWriter.Bool('destroyItem', LRule.DestroyItem);
    FWriter.Int('listOrder', LRule.ListOrder);
  end;
  FWriter.Begin_('research', '*');
  FWriter.Str('final', FMod.FinalResearch);
end;

procedure TXcomModDump.DumpManufacture;
var
  LIndex: Integer;
  LRule: TXcomRuleManufacture;
begin
  for LIndex := 0 to FMod.Manufacture.Count - 1 do
  begin
    LRule := FMod.Manufacture.Rule(LIndex);
    FWriter.Begin_('manufacture', FMod.Manufacture.Name(LIndex));
    FWriter.Str('name', LRule.Name);
    FWriter.Str('category', LRule.Category);
    FWriter.Strs('requires', LRule.Requirements);
    FWriter.Int('space', LRule.RequiredSpace);
    FWriter.Int('time', LRule.ManufactureTime);
    FWriter.Int('cost', LRule.ManufactureCost);
    FWriter.IntMap('requiredItems', LRule.RequiredItems);
    FWriter.IntMap('producedItems', LRule.ProducedItems);
    FWriter.Int('listOrder', LRule.ListOrder);
  end;
end;

procedure TXcomModDump.DumpAlienRaces;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FMod.AlienRaces.Count - 1 do
  begin
    FWriter.Begin_('alienRaces', FMod.AlienRaces.Name(LIndex));
    FWriter.Str('id', FMod.AlienRaces.Rule(LIndex).Id);
    FWriter.Strs('members', FMod.AlienRaces.Rule(LIndex).Members);
  end;
end;

procedure TXcomModDump.DumpTrajectories;
var
  LIndex, LPoint: Integer;
  LRule: TXcomUfoTrajectory;
  LText: string;
begin
  for LIndex := 0 to FMod.UfoTrajectories.Count - 1 do
  begin
    LRule := FMod.UfoTrajectories.Rule(LIndex);
    FWriter.Begin_('ufoTrajectories', FMod.UfoTrajectories.Name(LIndex));
    FWriter.Str('id', LRule.Id);
    FWriter.Card('groundTimer', LRule.GroundTimer);
    LText := '[';
    for LPoint := 0 to High(LRule.Waypoints) do
    begin
      if LPoint > 0 then
        LText := LText + ',';
      LText := LText + UIntToStr(LRule.Waypoints[LPoint].Zone) + '/' + UIntToStr(LRule.Waypoints[LPoint].Altitude) +
        '/' + UIntToStr(LRule.Waypoints[LPoint].Speed);
    end;
    FWriter.Line('waypoints', LText + ']');
  end;
end;

procedure TXcomModDump.DumpMusics;
var
  LIndex: Integer;
  LRule: TXcomRuleMusic;
begin
  for LIndex := 0 to FMod.Musics.Count - 1 do
  begin
    LRule := FMod.Musics.Rule(LIndex);
    FWriter.Begin_('musics', FMod.Musics.Name(LIndex));
    FWriter.Str('type', LRule.MusicType);
    FWriter.Str('name', LRule.Name);
    FWriter.Int('catPos', LRule.CatPos);
    FWriter.Sgl('normalization', LRule.Normalization);
  end;
end;

procedure TXcomModDump.DumpCommendations;
var
  LIndex, LAlternative, LCondition, LName: Integer;
  LRule: TXcomRuleCommendations;
  LText: string;
begin
  for LIndex := 0 to FMod.Commendations.Count - 1 do
  begin
    LRule := FMod.Commendations.Value(LIndex);
    FWriter.Begin_('commendations', FMod.Commendations.Key(LIndex));
    FWriter.Str('description', LRule.Description);
    FWriter.Int('sprite', LRule.Sprite);
    LText := '{';
    for LName := 0 to LRule.Criteria.Count - 1 do
    begin
      if LName > 0 then
        LText := LText + ',';
      LText := LText + TXcomDumpWriter.Quote(LRule.Criteria.Key(LName)) + ':' +
        TXcomDumpWriter.IntList(LRule.Criteria.Value(LName));
    end;
    FWriter.Line('criteria', LText + '}');
    LText := '[';
    for LAlternative := 0 to High(LRule.KillCriteria) do
    begin
      if LAlternative > 0 then
        LText := LText + ';';
      for LCondition := 0 to High(LRule.KillCriteria[LAlternative]) do
      begin
        if LCondition > 0 then
          LText := LText + '+';
        LText := LText + IntToStr(LRule.KillCriteria[LAlternative][LCondition].Count) +
          TXcomDumpWriter.QuoteList(LRule.KillCriteria[LAlternative][LCondition].Names);
      end;
    end;
    FWriter.Line('killCriteria', LText + ']');
  end;
end;

function TXcomModDump.Dump: TStringList;
begin
  FWriter.Lines.Clear;
  DumpCountries;
  DumpRegions;
  DumpCraftWeapons;
  DumpItems;
  DumpInventories;
  DumpResearch;
  DumpManufacture;
  DumpAlienRaces;
  DumpTrajectories;
  DumpMusics;
  DumpCommendations;
  Result := FWriter.Lines;
end;

end.
