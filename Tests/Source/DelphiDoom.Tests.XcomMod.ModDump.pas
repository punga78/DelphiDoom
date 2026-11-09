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
  DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomMod.RuleTerrain, DelphiDoom.XcomMod.Ruleset, DelphiDoom.Tests.XcomMod.DumpWriter;

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
    procedure DumpTerrainBody(const ATerrain: TXcomRuleTerrain);
    procedure DumpTerrains;
    procedure DumpMapDataSets;
    procedure DumpFacilities;
    procedure DumpCrafts;
    procedure DumpUfos;
    class function StatsText(const AStats: TXcomUnitStats): string; static;
    procedure DumpArmors;
    procedure DumpSoldiers;
    procedure DumpUnits;
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
  DelphiDoom.XcomMod.RuleCommendations, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomMod.RuleCraft,
  DelphiDoom.XcomMod.RuleUfo, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleSoldier,
  DelphiDoom.XcomMod.RuleUnit, DelphiDoom.XcomMod.SoldierNamePool;

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
  Result := TArray<string>.Create('countries', 'regions', 'facilities', 'crafts', 'craftWeapons', 'items', 'ufos',
    'invs', 'terrains', 'mapDataSets', 'armors', 'soldiers', 'units', 'research', 'manufacture', 'alienRaces', 'ufoTrajectories', 'musics',
    'commendations');
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

procedure TXcomModDump.DumpTerrainBody(const ATerrain: TXcomRuleTerrain);
var
  LIndex, LItem, LPosition: Integer;
  LNames: TArray<string>;
  LBlock: TXcomMapBlock;
  LText: string;
begin
  SetLength(LNames, ATerrain.MapDataSets.Count);
  for LIndex := 0 to High(LNames) do
    LNames[LIndex] := ATerrain.MapDataSets[LIndex].Name;
  FWriter.Strs('mapDataSets', LNames);
  FWriter.Str('name', ATerrain.Name);
  FWriter.Str('script', ATerrain.Script);
  FWriter.Strs('civilianTypes', ATerrain.CivilianTypes);
  FWriter.Strs('music', ATerrain.Music);
  FWriter.Int('minDepth', ATerrain.MinDepth);
  FWriter.Int('maxDepth', ATerrain.MaxDepth);
  FWriter.Int('ambience', ATerrain.Ambience);
  FWriter.Dbl('ambientVolume', ATerrain.AmbientVolume);
  FWriter.Card('blocks', ATerrain.MapBlocks.Count);
  for LIndex := 0 to ATerrain.MapBlocks.Count - 1 do
  begin
    LBlock := ATerrain.MapBlocks[LIndex];
    LText := '{';
    for LItem := 0 to LBlock.Items.Count - 1 do
    begin
      if LItem > 0 then
        LText := LText + ',';
      LText := LText + TXcomDumpWriter.Quote(LBlock.Items.Key(LItem)) + ':[';
      for LPosition := 0 to High(LBlock.Items.Value(LItem)) do
      begin
        if LPosition > 0 then
          LText := LText + ';';
        LText := LText + IntToStr(LBlock.Items.Value(LItem)[LPosition].X) + '/' +
          IntToStr(LBlock.Items.Value(LItem)[LPosition].Y) + '/' + IntToStr(LBlock.Items.Value(LItem)[LPosition].Z);
      end;
      LText := LText + ']';
    end;
    FWriter.Line('block' + IntToStr(LIndex), TXcomDumpWriter.Quote(LBlock.Name) + ',' + IntToStr(LBlock.SizeX) +
      ',' + IntToStr(LBlock.SizeY) + ',' + IntToStr(LBlock.SizeZ) + ',' + TXcomDumpWriter.IntList(LBlock.Groups) +
      ',' + TXcomDumpWriter.IntList(LBlock.RevealedFloors) + ',' + LText + '}');
  end;
end;

procedure TXcomModDump.DumpTerrains;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FMod.Terrains.Count - 1 do
  begin
    FWriter.Begin_('terrains', FMod.Terrains.Name(LIndex));
    DumpTerrainBody(FMod.Terrains.Rule(LIndex));
  end;
end;

procedure TXcomModDump.DumpMapDataSets;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FMod.MapDataSets.Count - 1 do
  begin
    FWriter.Begin_('mapDataSets', FMod.MapDataSets.Name(LIndex));
    FWriter.Str('name', FMod.MapDataSets.Rule(LIndex).Name);
  end;
end;

procedure TXcomModDump.DumpFacilities;
var
  LIndex: Integer;
  LRule: TXcomRuleBaseFacility;
begin
  for LIndex := 0 to FMod.Facilities.Count - 1 do
  begin
    LRule := FMod.Facilities.Rule(LIndex);
    FWriter.Begin_('facilities', FMod.Facilities.Name(LIndex));
    FWriter.Str('type', LRule.FacilityType);
    FWriter.Strs('requires', LRule.Requirements);
    FWriter.Int('spriteShape', LRule.SpriteShape);
    FWriter.Int('spriteFacility', LRule.SpriteFacility);
    FWriter.Bool('lift', LRule.IsLift);
    FWriter.Bool('hyper', LRule.IsHyperwave);
    FWriter.Bool('mind', LRule.IsMindShield);
    FWriter.Bool('grav', LRule.IsGravShield);
    FWriter.Int('size', LRule.Size);
    FWriter.Int('buildCost', LRule.BuildCost);
    FWriter.Int('buildTime', LRule.BuildTime);
    FWriter.Int('monthlyCost', LRule.MonthlyCost);
    FWriter.Int('storage', LRule.Storage);
    FWriter.Int('personnel', LRule.Personnel);
    FWriter.Int('aliens', LRule.Aliens);
    FWriter.Int('crafts', LRule.Crafts);
    FWriter.Int('labs', LRule.Laboratories);
    FWriter.Int('workshops', LRule.Workshops);
    FWriter.Int('psiLabs', LRule.PsiLaboratories);
    FWriter.Int('radarRange', LRule.RadarRange);
    FWriter.Int('radarChance', LRule.RadarChance);
    FWriter.Int('defense', LRule.DefenseValue);
    FWriter.Int('hitRatio', LRule.HitRatio);
    FWriter.Int('fireSound', LRule.FireSound);
    FWriter.Int('hitSound', LRule.HitSound);
    FWriter.Str('mapName', LRule.MapName);
    FWriter.Int('listOrder', LRule.ListOrder);
  end;
end;

procedure TXcomModDump.DumpCrafts;
var
  LIndex, LRow: Integer;
  LRule: TXcomRuleCraft;
  LText: string;
begin
  for LIndex := 0 to FMod.Crafts.Count - 1 do
  begin
    LRule := FMod.Crafts.Rule(LIndex);
    FWriter.Begin_('crafts', FMod.Crafts.Name(LIndex));
    FWriter.Str('type', LRule.CraftType);
    FWriter.Strs('requires', LRule.Requirements);
    FWriter.Int('sprite', LRule.Sprite);
    FWriter.Int('marker', LRule.Marker);
    FWriter.Int('fuelMax', LRule.MaxFuel);
    FWriter.Int('damageMax', LRule.MaxDamage);
    FWriter.Int('speedMax', LRule.MaxSpeed);
    FWriter.Int('accel', LRule.Acceleration);
    FWriter.Int('weapons', LRule.Weapons);
    FWriter.Int('soldiers', LRule.Soldiers);
    FWriter.Int('vehicles', LRule.Vehicles);
    FWriter.Int('costBuy', LRule.BuyCost);
    FWriter.Int('costRent', LRule.RentCost);
    FWriter.Int('costSell', LRule.SellCost);
    FWriter.Str('refuelItem', LRule.RefuelItem);
    FWriter.Int('repairRate', LRule.RepairRate);
    FWriter.Int('refuelRate', LRule.RefuelRate);
    FWriter.Int('radarRange', LRule.RadarRange);
    FWriter.Int('radarChance', LRule.RadarChance);
    FWriter.Int('sightRange', LRule.SightRange);
    FWriter.Int('transferTime', LRule.TransferTime);
    FWriter.Int('score', LRule.Score);
    LText := '[';
    for LRow := 0 to High(LRule.Deployment) do
    begin
      if LRow > 0 then
        LText := LText + ',';
      LText := LText + TXcomDumpWriter.IntList(LRule.Deployment[LRow]);
    end;
    FWriter.Line('deployment', LText + ']');
    FWriter.Bool('spacecraft', LRule.Spacecraft);
    FWriter.Int('listOrder', LRule.ListOrder);
    FWriter.Int('maxItems', LRule.MaxItems);
    FWriter.Int('maxAltitude', LRule.MaxAltitude);
    FWriter.Bool('hasTerrain', Assigned(LRule.BattlescapeTerrainData));
    if Assigned(LRule.BattlescapeTerrainData) then
      DumpTerrainBody(LRule.BattlescapeTerrainData);
  end;
end;

procedure TXcomModDump.DumpUfos;
var
  LIndex: Integer;
  LRule: TXcomRuleUfo;
begin
  for LIndex := 0 to FMod.Ufos.Count - 1 do
  begin
    LRule := FMod.Ufos.Rule(LIndex);
    FWriter.Begin_('ufos', FMod.Ufos.Name(LIndex));
    FWriter.Str('type', LRule.UfoType);
    FWriter.Str('size', LRule.Size);
    FWriter.Int('sprite', LRule.Sprite);
    FWriter.Int('marker', LRule.Marker);
    FWriter.Int('markerLand', LRule.LandMarker);
    FWriter.Int('markerCrash', LRule.CrashMarker);
    FWriter.Int('damageMax', LRule.MaxDamage);
    FWriter.Int('speedMax', LRule.MaxSpeed);
    FWriter.Int('power', LRule.WeaponPower);
    FWriter.Int('range', LRule.WeaponRange);
    FWriter.Int('score', LRule.Score);
    FWriter.Int('reload', LRule.WeaponReload);
    FWriter.Int('breakOffTime', LRule.BreakOffTime);
    FWriter.Int('sightRange', LRule.SightRange);
    FWriter.Int('missionScore', LRule.MissionScore);
    FWriter.Str('modSprite', LRule.ModSprite);
    FWriter.Int('radius', LRule.Radius);
    FWriter.Bool('hasTerrain', Assigned(LRule.BattlescapeTerrainData));
    if Assigned(LRule.BattlescapeTerrainData) then
      DumpTerrainBody(LRule.BattlescapeTerrainData);
  end;
end;

class function TXcomModDump.StatsText(const AStats: TXcomUnitStats): string;
begin
  Result := Format('%d/%d/%d/%d/%d/%d/%d/%d/%d/%d/%d', [AStats.TimeUnits, AStats.Stamina, AStats.Health,
    AStats.Bravery, AStats.Reactions, AStats.Firing, AStats.Throwing, AStats.Strength, AStats.PsiStrength,
    AStats.PsiSkill, AStats.Melee]);
end;

procedure TXcomModDump.DumpArmors;
var
  LIndex, LType: Integer;
  LRule: TXcomArmor;
  LText: string;
begin
  for LIndex := 0 to FMod.Armors.Count - 1 do
  begin
    LRule := FMod.Armors.Rule(LIndex);
    FWriter.Begin_('armors', FMod.Armors.Name(LIndex));
    FWriter.Str('type', LRule.ArmorType);
    FWriter.Str('spriteSheet', LRule.SpriteSheet);
    FWriter.Str('spriteInv', LRule.SpriteInventory);
    FWriter.Str('corpseGeo', LRule.CorpseGeoscape);
    FWriter.Str('storeItem', LRule.StoreItem);
    FWriter.Str('specWeapon', LRule.SpecialWeapon);
    FWriter.Strs('corpseBattle', LRule.CorpseBattlescape);
    FWriter.Int('frontArmor', LRule.FrontArmor);
    FWriter.Int('sideArmor', LRule.SideArmor);
    FWriter.Int('rearArmor', LRule.RearArmor);
    FWriter.Int('underArmor', LRule.UnderArmor);
    FWriter.Int('drawingRoutine', LRule.DrawingRoutine);
    FWriter.Bool('drawBubbles', LRule.DrawBubbles);
    FWriter.Int('movementType', LRule.MovementType);
    FWriter.Int('size', LRule.Size);
    FWriter.Int('weight', LRule.Weight);
    LText := '[';
    for LType := 0 to TXcomArmor.DAMAGE_TYPES - 1 do
    begin
      if LType > 0 then
        LText := LText + ',';
      LText := LText + TXcomDumpWriter.HexSingle(LRule.DamageModifier[LType]);
    end;
    FWriter.Line('damageModifier', LText + ']');
    FWriter.Ints('loftempsSet', LRule.LoftempsSet);
    FWriter.Line('stats', StatsText(LRule.Stats));
    FWriter.Int('deathFrames', LRule.DeathFrames);
    FWriter.Bool('constantAnimation', LRule.ConstantAnimation);
    FWriter.Bool('hasInventory', LRule.HasInventory);
    FWriter.Int('forcedTorso', LRule.ForcedTorso);
    FWriter.Int('faceColorGroup', LRule.FaceColorGroup);
    FWriter.Int('hairColorGroup', LRule.HairColorGroup);
    FWriter.Int('utileColorGroup', LRule.UtileColorGroup);
    FWriter.Int('rankColorGroup', LRule.RankColorGroup);
    FWriter.Ints('faceColor', LRule.FaceColor);
    FWriter.Ints('hairColor', LRule.HairColor);
    FWriter.Ints('utileColor', LRule.UtileColor);
    FWriter.Ints('rankColor', LRule.RankColor);
    FWriter.Strs('units', LRule.Units);
  end;
end;

procedure TXcomModDump.DumpSoldiers;
var
  LIndex, LPool: Integer;
  LRule: TXcomRuleSoldier;
  LNames: TXcomSoldierNamePool;
begin
  for LIndex := 0 to FMod.Soldiers.Count - 1 do
  begin
    LRule := FMod.Soldiers.Rule(LIndex);
    FWriter.Begin_('soldiers', FMod.Soldiers.Name(LIndex));
    FWriter.Str('type', LRule.SoldierType);
    FWriter.Strs('requires', LRule.Requirements);
    FWriter.Line('minStats', StatsText(LRule.MinStats));
    FWriter.Line('maxStats', StatsText(LRule.MaxStats));
    FWriter.Line('statCaps', StatsText(LRule.StatCaps));
    FWriter.Str('armor', LRule.ArmorName);
    FWriter.Int('costBuy', LRule.BuyCost);
    FWriter.Int('costSalary', LRule.SalaryCost);
    FWriter.Int('standHeight', LRule.StandHeight);
    FWriter.Int('kneelHeight', LRule.KneelHeight);
    FWriter.Int('floatHeight', LRule.FloatHeight);
    FWriter.Int('femaleFrequency', LRule.FemaleFrequency);
    FWriter.Int('value', LRule.Value);
    FWriter.Int('transferTime', LRule.TransferTime);
    FWriter.Ints('deathSoundMale', LRule.DeathSoundMale);
    FWriter.Ints('deathSoundFemale', LRule.DeathSoundFemale);
    FWriter.Card('pools', LRule.Names.Count);
    for LPool := 0 to LRule.Names.Count - 1 do
    begin
      LNames := LRule.Names[LPool];
      FWriter.Line('pool' + IntToStr(LPool), TXcomDumpWriter.QuoteList(LNames.MaleFirst) + ';' +
        TXcomDumpWriter.QuoteList(LNames.FemaleFirst) + ';' + TXcomDumpWriter.QuoteList(LNames.MaleLast) + ';' +
        TXcomDumpWriter.QuoteList(LNames.FemaleLast) + ';' + TXcomDumpWriter.IntList(LNames.LookWeights) + ';' +
        IntToStr(LNames.TotalWeight) + ';' + IntToStr(LNames.FemaleFrequency));
    end;
  end;
end;

procedure TXcomModDump.DumpUnits;
var
  LIndex, LRow: Integer;
  LRule: TXcomRuleUnit;
  LText: string;
begin
  for LIndex := 0 to FMod.Units.Count - 1 do
  begin
    LRule := FMod.Units.Rule(LIndex);
    FWriter.Begin_('units', FMod.Units.Name(LIndex));
    FWriter.Str('type', LRule.UnitType);
    FWriter.Str('race', LRule.Race);
    FWriter.Str('rank', LRule.Rank);
    FWriter.Line('stats', StatsText(LRule.Stats));
    FWriter.Str('armor', LRule.Armor);
    FWriter.Int('standHeight', LRule.StandHeight);
    FWriter.Int('kneelHeight', LRule.KneelHeight);
    FWriter.Int('floatHeight', LRule.FloatHeight);
    FWriter.Ints('deathSound', LRule.DeathSounds);
    FWriter.Int('value', LRule.Value);
    FWriter.Int('aggroSound', LRule.AggroSound);
    FWriter.Int('moveSound', LRule.MoveSound);
    FWriter.Int('intelligence', LRule.Intelligence);
    FWriter.Int('aggression', LRule.Aggression);
    FWriter.Int('energyRecovery', LRule.EnergyRecovery);
    FWriter.Int('specab', LRule.SpecialAbility);
    FWriter.Str('spawnUnit', LRule.SpawnUnit);
    FWriter.Bool('livingWeapon', LRule.LivingWeapon);
    FWriter.Str('meleeWeapon', LRule.MeleeWeapon);
    FWriter.Str('psiWeapon', LRule.PsiWeapon);
    LText := '[';
    for LRow := 0 to High(LRule.BuiltInWeapons) do
    begin
      if LRow > 0 then
        LText := LText + ',';
      LText := LText + TXcomDumpWriter.QuoteList(LRule.BuiltInWeapons[LRow]);
    end;
    FWriter.Line('builtInWeapons', LText + ']');
    FWriter.Bool('capturable', LRule.Capturable);
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
  DumpFacilities;
  DumpCrafts;
  DumpCraftWeapons;
  DumpItems;
  DumpUfos;
  DumpInventories;
  DumpTerrains;
  DumpMapDataSets;
  DumpArmors;
  DumpSoldiers;
  DumpUnits;
  DumpResearch;
  DumpManufacture;
  DumpAlienRaces;
  DumpTrajectories;
  DumpMusics;
  DumpCommendations;
  Result := FWriter.Lines;
end;

end.
