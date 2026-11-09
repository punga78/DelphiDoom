// What is dumped for each rule kind. One function per section; the Pascal side (Tests\Source\
// DelphiDoom.Tests.XcomMod.ModDump.pas) prints the same lines, in the same order and with the same names.
template <class T> static std::string IndexOf(const T&) { return ""; }

static void DumpManifest(Mod* m) {
  for (size_t i = 0; i < m->_modData.size(); i++) {
    Begin("mods", m->_modData[i].name);
    F("offset", m->_modData[i].offset);
    F("size", m->_modData[i].size);
  }
  for (std::map<std::string, SurfaceSet*>::iterator i = m->_sets.begin(); i != m->_sets.end(); ++i) {
    Begin("sprites", i->first);
    F("maxShared", i->second->getMaxSharedFrames());
  }
  for (std::map<std::string, SoundSet*>::iterator i = m->_sounds.begin(); i != m->_sounds.end(); ++i) {
    Begin("sounds", i->first);
    F("maxShared", i->second->getMaxSharedSounds());
  }
}

static void DumpAreas(const std::vector<double>& a, const std::vector<double>& b, const std::vector<double>& c, const std::vector<double>& d) {
  F("lonMin", a); F("lonMax", b); F("latMin", c); F("latMax", d);
}

static void DumpCountries(Mod* m) {
  for (auto& p : m->_countries) {
    RuleCountry* r = p.second;
    Begin("countries", p.first);
    F("type", r->_type); F("fundingBase", r->_fundingBase); F("fundingCap", r->_fundingCap);
    F("labelLon", r->_labelLon); F("labelLat", r->_labelLat);
    DumpAreas(r->_lonMin, r->_lonMax, r->_latMin, r->_latMax);
  }
}

static void DumpRegions(Mod* m) {
  for (auto& p : m->_regions) {
    RuleRegion* r = p.second;
    Begin("regions", p.first);
    F("type", r->_type); F("cost", r->_cost); F("weight", r->_regionWeight); F("missionRegion", r->_missionRegion);
    DumpAreas(r->_lonMin, r->_lonMax, r->_latMin, r->_latMax);
    F("weights", r->_missionWeights._choices);
    F("zones", r->_missionZones.size());
    for (size_t z = 0; z < r->_missionZones.size(); z++)
      for (size_t a = 0; a < r->_missionZones[z].areas.size(); a++) {
        MissionArea& ma = r->_missionZones[z].areas[a];
        std::string key = "zone" + std::to_string(z) + "_" + std::to_string(a);
        Line(key.c_str(), V(ma.lonMin) + "," + V(ma.lonMax) + "," + V(ma.latMin) + "," + V(ma.latMax) + ",_," + V(ma.name));  // texture is not initialized by the C++ when the row is short: not dumped
      }
  }
}

static void DumpCraftWeapons(Mod* m) {
  for (auto& p : m->_craftWeapons) {
    RuleCraftWeapon* r = p.second;
    Begin("craftWeapons", p.first);
    F("type", r->_type); F("sprite", r->_sprite); F("sound", r->_sound); F("damage", r->_damage); F("range", r->_range);
    F("accuracy", r->_accuracy); F("reloadCautious", r->_reloadCautious); F("reloadStandard", r->_reloadStandard);
    F("reloadAggressive", r->_reloadAggressive); F("ammoMax", r->_ammoMax); F("rearmRate", r->_rearmRate);
    F("projectileType", (int)r->_projectileType); F("projectileSpeed", r->_projectileSpeed);
    F("launcher", r->_launcher); F("clip", r->_clip); F("underwaterOnly", r->_underwaterOnly);
  }
}

// F of a member: the key is the name of the member without its underscore
#define FM(x) F(#x + 1, r->x)
static void DumpItems(Mod* m) {
  for (auto& p : m->_items) {
    RuleItem* r = p.second;
    Begin("items", p.first);
    FM(_type); FM(_name); FM(_requires); FM(_size); FM(_costBuy); FM(_costSell); FM(_transferTime); FM(_weight);
    FM(_bigSprite); FM(_floorSprite); FM(_handSprite); FM(_bulletSprite); FM(_fireSound); FM(_hitSound); FM(_hitAnimation);
    FM(_power); FM(_compatibleAmmo); F("damageType", (int)r->_damageType);
    FM(_accuracyAuto); FM(_accuracySnap); FM(_accuracyAimed); FM(_tuAuto); FM(_tuSnap); FM(_tuAimed); FM(_clipSize);
    FM(_accuracyMelee); FM(_tuMelee); F("battleType", (int)r->_battleType); FM(_twoHanded); FM(_fixedWeapon);
    FM(_waypoints); FM(_invWidth); FM(_invHeight); FM(_painKiller); FM(_heal); FM(_stimulant); FM(_woundRecovery);
    FM(_healthRecovery); FM(_stunRecovery); FM(_energyRecovery); FM(_tuUse); FM(_recoveryPoints); FM(_armor);
    FM(_turretType); FM(_recover); FM(_ignoreInBaseDefense); FM(_liveAlien); FM(_blastRadius); FM(_attraction);
    FM(_flatRate); FM(_arcingShot); FM(_listOrder); FM(_maxRange); FM(_aimRange); FM(_snapRange); FM(_autoRange);
    FM(_minRange); FM(_dropoff); FM(_bulletSpeed); FM(_explosionSpeed); FM(_autoShots); FM(_shotgunPellets);
    FM(_zombieUnit); FM(_strengthApplied); FM(_skillApplied); FM(_LOSRequired); FM(_underwaterOnly); FM(_landOnly);
    FM(_meleeSound); FM(_meleePower); FM(_meleeAnimation); FM(_meleeHitSound); FM(_specialType); FM(_vaporColor);
    FM(_vaporDensity); FM(_vaporProbability);
    F("explosionRadius", r->getExplosionRadius()); F("maxRangeSq", r->getMaxRangeSq()); F("isRifle", r->isRifle());
    F("isPistol", r->isPistol());
  }
}

static void DumpTerrainBody(RuleTerrain* t) {
  std::vector<std::string> sets;
  for (size_t i = 0; i < t->_mapDataSets.size(); i++) sets.push_back(t->_mapDataSets[i]->getName());
  F("mapDataSets", sets);
  F("name", t->_name); F("script", t->_script); F("civilianTypes", t->_civilianTypes); F("music", t->_music);
  F("minDepth", t->_minDepth); F("maxDepth", t->_maxDepth); F("ambience", t->_ambience); F("ambientVolume", t->_ambientVolume);
  F("blocks", t->_mapBlocks.size());
  for (size_t i = 0; i < t->_mapBlocks.size(); i++) {
    MapBlock* b = t->_mapBlocks[i];
    std::string items = "{";
    bool first = true;
    for (auto& p : b->_items) {
      if (!first) items += ",";
      first = false;
      items += V(p.first) + ":[";
      for (size_t k = 0; k < p.second.size(); k++) { if (k) items += ";"; items += V(p.second[k].x) + "/" + V(p.second[k].y) + "/" + V(p.second[k].z); }
      items += "]";
    }
    Line(("block" + std::to_string(i)).c_str(), V(b->_name) + "," + V(b->_size_x) + "," + V(b->_size_y) + "," + V(b->_size_z) + "," + V(b->_groups) + "," + V(b->_revealedFloors) + "," + items + "}");
  }
}

static void DumpTerrains(Mod* m) {
  for (auto& p : m->_terrains) { Begin("terrains", p.first); DumpTerrainBody(p.second); }
}

static void DumpMapDataSets(Mod* m) {
  for (auto& p : m->_mapDataSets) { Begin("mapDataSets", p.first); F("name", p.second->_name); }
}

static void DumpFacilities(Mod* m) {
  for (auto& p : m->_facilities) {
    RuleBaseFacility* r = p.second;
    Begin("facilities", p.first);
    FM(_type); FM(_requires); FM(_spriteShape); FM(_spriteFacility); FM(_lift); FM(_hyper); FM(_mind); FM(_grav); FM(_size);
    FM(_buildCost); FM(_buildTime); FM(_monthlyCost); FM(_storage); FM(_personnel); FM(_aliens); FM(_crafts); FM(_labs);
    FM(_workshops); FM(_psiLabs); FM(_radarRange); FM(_radarChance); FM(_defense); FM(_hitRatio); FM(_fireSound);
    FM(_hitSound); FM(_mapName); FM(_listOrder);
  }
}

static void DumpCrafts(Mod* m) {
  for (auto& p : m->_crafts) {
    RuleCraft* r = p.second;
    Begin("crafts", p.first);
    FM(_type); FM(_requires); FM(_sprite); FM(_marker); FM(_fuelMax); FM(_damageMax); FM(_speedMax); FM(_accel); FM(_weapons);
    FM(_soldiers); FM(_vehicles); FM(_costBuy); FM(_costRent); FM(_costSell); FM(_refuelItem); FM(_repairRate); FM(_refuelRate);
    FM(_radarRange); FM(_radarChance); FM(_sightRange); FM(_transferTime); FM(_score); FM(_deployment); FM(_spacecraft);
    FM(_listOrder); FM(_maxItems); FM(_maxAltitude);
    F("hasTerrain", r->_battlescapeTerrainData != 0);
    if (r->_battlescapeTerrainData) DumpTerrainBody(r->_battlescapeTerrainData);
  }
}

static void DumpUfos(Mod* m) {
  for (auto& p : m->_ufos) {
    RuleUfo* r = p.second;
    Begin("ufos", p.first);
    FM(_type); FM(_size); FM(_sprite); FM(_marker); FM(_markerLand); FM(_markerCrash); FM(_damageMax); FM(_speedMax); FM(_power);
    FM(_range); FM(_score); FM(_reload); FM(_breakOffTime); FM(_sightRange); FM(_missionScore); FM(_modSprite);
    F("radius", r->getRadius());
    F("hasTerrain", r->_battlescapeTerrainData != 0);
    if (r->_battlescapeTerrainData) DumpTerrainBody(r->_battlescapeTerrainData);
  }
}

static std::string StatsStr(const UnitStats& s) {
  return V(s.tu) + "/" + V(s.stamina) + "/" + V(s.health) + "/" + V(s.bravery) + "/" + V(s.reactions) + "/" + V(s.firing) + "/" + V(s.throwing) + "/" + V(s.strength) + "/" + V(s.psiStrength) + "/" + V(s.psiSkill) + "/" + V(s.melee);
}

static void DumpArmors(Mod* m) {
  for (auto& p : m->_armors) {
    Armor* r = p.second;
    Begin("armors", p.first);
    FM(_type); FM(_spriteSheet); FM(_spriteInv); FM(_corpseGeo); FM(_storeItem); FM(_specWeapon); FM(_corpseBattle);
    FM(_frontArmor); FM(_sideArmor); FM(_rearArmor); FM(_underArmor); FM(_drawingRoutine); FM(_drawBubbles);
    F("movementType", (int)r->_movementType); FM(_size); FM(_weight);
    F("damageModifier", std::vector<float>(r->_damageModifier, r->_damageModifier + Armor::DAMAGE_TYPES));
    FM(_loftempsSet); Line("stats", StatsStr(r->_stats)); FM(_deathFrames); FM(_constantAnimation); FM(_hasInventory);
    F("forcedTorso", (int)r->_forcedTorso); FM(_faceColorGroup); FM(_hairColorGroup); FM(_utileColorGroup); FM(_rankColorGroup);
    FM(_faceColor); FM(_hairColor); FM(_utileColor); FM(_rankColor); FM(_units);
  }
}

static void DumpSoldiers(Mod* m) {
  for (auto& p : m->_soldiers) {
    RuleSoldier* r = p.second;
    Begin("soldiers", p.first);
    FM(_type); FM(_requires); Line("minStats", StatsStr(r->_minStats)); Line("maxStats", StatsStr(r->_maxStats));
    Line("statCaps", StatsStr(r->_statCaps)); FM(_armor); FM(_costBuy); FM(_costSalary); FM(_standHeight); FM(_kneelHeight);
    FM(_floatHeight); FM(_femaleFrequency); FM(_value); FM(_transferTime); FM(_deathSoundMale); FM(_deathSoundFemale);
    F("pools", r->_names.size());
    for (size_t i = 0; i < r->_names.size(); i++) {
      SoldierNamePool* n = r->_names[i];
      Line(("pool" + std::to_string(i)).c_str(), V(n->_maleFirst) + ";" + V(n->_femaleFirst) + ";" + V(n->_maleLast) + ";" + V(n->_femaleLast) + ";" + V(n->_lookWeights) + ";" + V(n->_totalWeight) + ";" + V(n->_femaleFrequency));
    }
  }
}

static void DumpUnits(Mod* m) {
  for (auto& p : m->_units) {
    Unit* r = p.second;
    Begin("units", p.first);
    FM(_type); FM(_race); FM(_rank); Line("stats", StatsStr(r->_stats)); FM(_armor); FM(_standHeight); FM(_kneelHeight);
    FM(_floatHeight); FM(_deathSound); FM(_value); FM(_aggroSound); FM(_moveSound); FM(_intelligence); FM(_aggression);
    FM(_energyRecovery); F("specab", (int)r->_specab); FM(_spawnUnit); FM(_livingWeapon); FM(_meleeWeapon); FM(_psiWeapon);
    FM(_builtInWeapons); FM(_capturable);
  }
}

static std::string WeightsStr(const std::vector<std::pair<size_t, WeightedOptions*> >& v) {
  std::string s = "[";
  for (size_t i = 0; i < v.size(); i++) { if (i) s += ";"; s += std::to_string(v[i].first) + V(v[i].second->_choices); }
  return s + "]";
}

static void DumpDeployments(Mod* m) {
  for (auto& p : m->_alienDeployments) {
    AlienDeployment* r = p.second;
    Begin("alienDeployments", p.first);
    FM(_type); F("data", r->_data.size());
    for (size_t i = 0; i < r->_data.size(); i++) {
      DeploymentData& d = r->_data[i];
      std::string sets = "[";
      for (size_t k = 0; k < d.itemSets.size(); k++) { if (k) sets += ";"; sets += V(d.itemSets[k].items); }
      Line(("data" + std::to_string(i)).c_str(), V(d.alienRank) + "," + V(d.lowQty) + "," + V(d.highQty) + "," + V(d.dQty) + "," + V(d.extraQty) + "," + V(d.percentageOutsideUfo) + "," + sets + "]");
    }
    FM(_width); FM(_length); FM(_height); FM(_civilians); FM(_terrains); FM(_music); FM(_shade); FM(_nextStage); FM(_race);
    FM(_script); FM(_finalDestination); FM(_isAlienBase); FM(_winCutscene); FM(_loseCutscene); FM(_abortCutscene);
    FM(_alert); FM(_alertBackground);
    BriefingData& b = r->_briefingData;
    Line("briefing", V(b.palette) + "," + V(b.textOffset) + "," + V(b.title) + "," + V(b.desc) + "," + V(b.music) + "," + V(b.background) + "," + V(b.cutscene) + "," + V(b.showCraft) + "," + V(b.showTarget));
    FM(_markerName); FM(_objectivePopup); FM(_objectiveCompleteText); FM(_objectiveFailedText);
    F("genMission", r->_genMission._choices); FM(_markerIcon); FM(_durationMin); FM(_durationMax); FM(_minDepth); FM(_maxDepth);
    FM(_genMissionFrequency); FM(_objectiveType); FM(_objectivesRequired); FM(_objectiveCompleteScore); FM(_objectiveFailedScore);
    FM(_despawnPenalty); FM(_points); FM(_turnLimit); FM(_cheatTurn); F("chronoTrigger", (int)r->_chronoTrigger);
    F("escapeType", (int)r->_escapeType);
  }
}

static void DumpAlienMissions(Mod* m) {
  for (auto& p : m->_alienMissions) {
    RuleAlienMission* r = p.second;
    Begin("alienMissions", p.first);
    FM(_type); FM(_spawnUfo); Line("raceDistribution", WeightsStr(r->_raceDistribution)); FM(_weights); FM(_points);
    F("objective", (int)r->_objective); FM(_spawnZone); FM(_retaliationOdds); FM(_siteType);
    F("waves", r->_waves.size());
    for (size_t i = 0; i < r->_waves.size(); i++) {
      MissionWave& w = r->_waves[i];
      Line(("wave" + std::to_string(i)).c_str(), V(w.ufoType) + "," + V(w.ufoCount) + "," + V(w.trajectory) + "," + V(w.spawnTimer) + "," + V(w.objective));
    }
  }
}

static void DumpMissionScripts(Mod* m) {
  for (auto& p : m->_missionScripts) {
    RuleMissionScript* r = p.second;
    Begin("missionScripts", p.first);
    FM(_type); FM(_varName); FM(_firstMonth); FM(_lastMonth); FM(_label); FM(_executionOdds); FM(_targetBaseOdds);
    FM(_minDifficulty); FM(_maxRuns); FM(_avoidRepeats); FM(_delay); FM(_conditionals);
    Line("regionWeights", WeightsStr(r->_regionWeights)); Line("missionWeights", WeightsStr(r->_missionWeights));
    Line("raceWeights", WeightsStr(r->_raceWeights)); FM(_researchTriggers); FM(_useTable); FM(_siteType);
  }
}

static void DumpIndexes(Mod* m) {
  Begin("indexes", "lists");
  F("countries", m->_countriesIndex); F("regions", m->_regionsIndex); F("facilities", m->_facilitiesIndex);
  F("crafts", m->_craftsIndex); F("craftWeapons", m->_craftWeaponsIndex); F("items", m->_itemsIndex);
  F("invs", m->_invsIndex); F("ufos", m->_ufosIndex); F("soldiers", m->_soldiersIndex); F("aliens", m->_aliensIndex);
  F("deployments", m->_deploymentsIndex); /* armors: itemless armors are ordered by the address of the objects (not reproducible), not dumped */ F("ufopaedia", m->_ufopaediaIndex);
  F("ufopaediaCat", m->_ufopaediaCatIndex); F("research", m->_researchIndex); F("manufacture", m->_manufactureIndex);
  F("alienMissions", m->_alienMissionsIndex); F("terrains", m->_terrainIndex); F("missionScripts", m->_missionScriptIndex);
  F("ufopaediaSections", m->_ufopaediaSections);
}

static std::string RectStr(const ArticleDefinitionRect& r) { return V(r.x) + "/" + V(r.y) + "/" + V(r.width) + "/" + V(r.height); }

static void DumpArticles(Mod* m) {
  for (auto& p : m->_ufopaediaArticles) {
    ArticleDefinition* r = p.second;
    Begin("ufopaedia", p.first);
    F("id", r->id); F("title", r->title); F("section", r->section); F("requires", r->_requires); F("listOrder", r->getListOrder());
    if (ArticleDefinitionCraft* a = dynamic_cast<ArticleDefinitionCraft*>(r)) { F("class", "craft"); F("image_id", a->image_id); Line("rect_stats", RectStr(a->rect_stats)); Line("rect_text", RectStr(a->rect_text)); F("text", a->text); }
    else if (ArticleDefinitionCraftWeapon* a = dynamic_cast<ArticleDefinitionCraftWeapon*>(r)) { F("class", "craftWeapon"); F("image_id", a->image_id); F("text", a->text); }
    else if (ArticleDefinitionTextImage* a = dynamic_cast<ArticleDefinitionTextImage*>(r)) { F("class", "textImage"); F("image_id", a->image_id); F("text", a->text); F("text_width", a->text_width); }
    else if (ArticleDefinitionTFTD* a = dynamic_cast<ArticleDefinitionTFTD*>(r)) { F("class", "tftd"); F("type_id", (int)a->_type_id); F("image_id", a->image_id); F("text", a->text); F("text_width", a->text_width); F("weapon", a->weapon); }
    else if (ArticleDefinitionVehicle* a = dynamic_cast<ArticleDefinitionVehicle*>(r)) { F("class", "vehicle"); F("weapon", a->weapon); F("text", a->text); }
    else if (ArticleDefinitionText* a = dynamic_cast<ArticleDefinitionText*>(r)) { F("class", "text"); F("text", a->text); }
    else if (ArticleDefinitionItem* a = dynamic_cast<ArticleDefinitionItem*>(r)) { F("class", "item"); F("text", a->text); }
    else if (ArticleDefinitionUfo* a = dynamic_cast<ArticleDefinitionUfo*>(r)) { F("class", "ufo"); F("text", a->text); }
    else if (ArticleDefinitionArmor* a = dynamic_cast<ArticleDefinitionArmor*>(r)) { F("class", "armor"); F("text", a->text); }
    else if (ArticleDefinitionBaseFacility* a = dynamic_cast<ArticleDefinitionBaseFacility*>(r)) { F("class", "baseFacility"); F("text", a->text); }
  }
}

static void DumpMapScripts(Mod* m) {
  for (auto& p : m->_mapScripts) {
    Begin("mapScripts", p.first);
    F("count", p.second.size());
    for (size_t i = 0; i < p.second.size(); i++) {
      MapScript* r = p.second[i];
      std::string rects = "[";
      for (size_t k = 0; k < r->_rects.size(); k++) { if (k) rects += ";"; rects += V(r->_rects[k]->x) + "/" + V(r->_rects[k]->y) + "/" + V(r->_rects[k]->w) + "/" + V(r->_rects[k]->h); }
      std::string tunnel = "none";
      if (r->_tunnelData) {
        tunnel = "level" + V(r->_tunnelData->level) + "{";
        bool first = true;
        for (auto& q : r->_tunnelData->replacements) { if (!first) tunnel += ","; first = false; tunnel += V(q.first) + ":" + V(q.second.set) + "/" + V(q.second.entry); }
        tunnel += "}";
      }
      Line(("cmd" + std::to_string(i)).c_str(), V((int)r->_type) + "|" + rects + "]|" + V(r->_groups) + "|" + V(r->_blocks) + "|" + V(r->_frequencies) + "|" + V(r->_maxUses) + "|" + V(r->_conditionals) + "|" + V(r->_sizeX) + "," + V(r->_sizeY) + "," + V(r->_sizeZ) + "|" + V(r->_executionChances) + "," + V(r->_executions) + "," + V(r->_label) + "|" + V((int)r->_direction) + "|" + tunnel + "|" + V(r->_ufoName));
    }
  }
}

static void DumpMcdPatches(Mod* m) {
  for (auto& p : m->_MCDPatches) {
    MCDPatch* r = p.second;
    Begin("mcdPatches", p.first);
    FM(_bigWalls); FM(_TUWalks); FM(_TUFlys); FM(_TUSlides); FM(_deathTiles); FM(_terrainHeight); FM(_specialTypes);
    FM(_explosives); FM(_armors); FM(_flammabilities); FM(_fuels); FM(_footstepSounds); FM(_HEBlocks); FM(_noFloors);
    FM(_LOFTS); FM(_stopLOSses); FM(_objectTypes);
  }
}

static void DumpExtras(Mod* m) {
  for (auto& p : m->_extraSprites) {
    Begin("extraSprites", p.first);
    F("count", p.second.size());
    for (size_t i = 0; i < p.second.size(); i++) {
      ExtraSprites* r = p.second[i];
      Line(("set" + std::to_string(i)).c_str(), V(r->_type) + "|" + V(r->_sprites) + "|" + V(r->_width) + "," + V(r->_height) + "," + V(r->_singleImage) + "," + V(r->_subX) + "," + V(r->_subY) + "|" + r->_current->name + ":" + V((unsigned)r->_current->offset) + ":" + V((unsigned)r->_current->size));
    }
  }
  Begin("extraSounds", "list");
  F("count", m->_extraSounds.size());
  for (size_t i = 0; i < m->_extraSounds.size(); i++) {
    ExtraSounds* r = m->_extraSounds[i].second;
    Line(("set" + std::to_string(i)).c_str(), V(m->_extraSounds[i].first) + "|" + V(r->_type) + "|" + V(r->_sounds) + "|" + r->_current->name + ":" + V((unsigned)r->_current->offset) + ":" + V((unsigned)r->_current->size));
  }
  for (auto& p : m->_extraStrings) { Begin("extraStrings", p.first); F("strings", p.second->_strings); }
  Begin("statStrings", "list");
  F("count", m->_statStrings.size());
  for (size_t i = 0; i < m->_statStrings.size(); i++) {
    StatString* r = m->_statStrings[i];
    std::string c = "[";
    for (size_t k = 0; k < r->_conditions.size(); k++) { if (k) c += ";"; c += V(r->_conditions[k]->_conditionName) + "/" + V(r->_conditions[k]->_minVal) + "/" + V(r->_conditions[k]->_maxVal); }
    Line(("s" + std::to_string(i)).c_str(), V(r->_stringToBeAddedIfAllConditionsAreMet) + "|" + c + "]");
  }
}

static void DumpInterfacesEtc(Mod* m) {
  for (auto& p : m->_interfaces) {
    RuleInterface* r = p.second;
    Begin("interfaces", p.first);
    FM(_type); FM(_palette); FM(_parent); FM(_music); F("count", r->_elements.size());
    for (auto& e : r->_elements) Line(("e_" + Esc(e.first)).c_str(), V(e.second.x) + "/" + V(e.second.y) + "/" + V(e.second.w) + "/" + V(e.second.h) + "/" + V(e.second.color) + "/" + V(e.second.color2) + "/" + V(e.second.border) + "/" + V(e.second.TFTDMode));
  }
  for (auto& p : m->_videos) {
    RuleVideo* r = p.second;
    Begin("videos", p.first);
    FM(_id); FM(_useUfoAudioSequence); FM(_videos); FM(_audioTracks);
    Line("header", V(r->_slideshowHeader.musicId) + "," + V(r->_slideshowHeader.transitionSeconds));
    F("slides", r->_slides.size());
    for (size_t i = 0; i < r->_slides.size(); i++) {
      SlideshowSlide& s = r->_slides[i];
      Line(("slide" + std::to_string(i)).c_str(), V(s.imagePath) + "," + V(s.caption) + "," + V(s.w) + "," + V(s.h) + "," + V(s.x) + "," + V(s.y) + "," + V(s.color) + "," + V((int)s.align) + "," + V(s.transitionSeconds));
    }
  }
  RuleGlobe* gl = m->_globe;
  Begin("globe", "data");
  {
    // FNV-1a 64 over the points of every polygon (count, texture, longitudes and latitudes as bits)
    unsigned long long h = 14695981039346656037ULL;
    auto mix = [&h](const void* p, size_t n) { const unsigned char* b = (const unsigned char*)p; for (size_t k = 0; k < n; k++) { h ^= b[k]; h *= 1099511628211ULL; } };
    size_t first = 0;
    for (std::list<Polygon*>::iterator i = gl->_polygons.begin(); i != gl->_polygons.end(); ++i, first++) {
      Polygon* pg = *i;
      int pts = pg->_points, tex = pg->_texture;
      mix(&pts, 4); mix(&tex, 4);
      for (int k = 0; k < pts; k++) { mix(&pg->_lon[k], 8); mix(&pg->_lat[k], 8); }
      if (first < 3 || first + 3 >= gl->_polygons.size()) {
        std::string t = V(pts) + "," + V(tex);
        for (int k = 0; k < pts; k++) t += "," + V(pg->_lon[k]) + "," + V(pg->_lat[k]);
        Line(("polygon" + std::to_string(first)).c_str(), t);
      }
    }
    F("polygons", gl->_polygons.size());
    char hb[32]; snprintf(hb, sizeof hb, "%016llX", h); Line("polygonHash", hb);
    h = 14695981039346656037ULL;
    for (std::list<Polyline*>::iterator i = gl->_polylines.begin(); i != gl->_polylines.end(); ++i) {
      Polyline* pl = *i;
      int pts = pl->_points;
      mix(&pts, 4);
      for (int k = 0; k < pts; k++) { mix(&pl->_lon[k], 8); mix(&pl->_lat[k], 8); }
    }
    F("polylines", gl->_polylines.size());
    snprintf(hb, sizeof hb, "%016llX", h); Line("polylineHash", hb);
  }
  F("countryColor", (int)Globe::COUNTRY_LABEL_COLOR); F("cityColor", (int)Globe::CITY_LABEL_COLOR);
  F("baseColor", (int)Globe::BASE_LABEL_COLOR); F("lineColor", (int)Globe::LINE_COLOR);
  F("oceanColor", (int)Globe::OCEAN_COLOR); F("oceanShading", Globe::OCEAN_SHADING);
  for (std::map<int, Texture*>::iterator i = gl->_textures.begin(); i != gl->_textures.end(); ++i) {
    Texture* t = i->second;
    Begin("textures", std::to_string(i->first));
    F("id", t->_id); F("deployments", t->_deployments);
    Line("count", V((int)t->_terrain.size()));
    for (size_t k = 0; k < t->_terrain.size(); k++) {
      TerrainCriteria& c = t->_terrain[k];
      Line(("t" + std::to_string(k)).c_str(), V(c.name) + "," + V(c.weight) + "," + V(c.lonMin) + "," + V(c.lonMax) + "," + V(c.latMin) + "," + V(c.latMax));
    }
  }
  {
    // getTerrains("") and the terrains of every deployment of the textures
    std::set<std::string> names;
    for (std::map<int, Texture*>::iterator i = gl->_textures.begin(); i != gl->_textures.end(); ++i)
      for (std::map<std::string, int>::const_iterator d = i->second->_deployments.begin(); d != i->second->_deployments.end(); ++d) names.insert(d->first);
    Begin("globeTerrains", "all");
    Line("none", V(gl->getTerrains("")));
    for (std::set<std::string>::iterator n = names.begin(); n != names.end(); ++n) Line(("d_" + Esc(*n)).c_str(), V(gl->getTerrains(*n)));
  }
  RuleConverter* c = m->_converter;
  Begin("converter", "data");
  F("offsets", c->_offsets); F("markers", c->_markers); F("countries", c->_countries); F("regions", c->_regions);
  F("facilities", c->_facilities); F("items", c->_items); F("crews", c->_crews); F("crafts", c->_crafts); F("ufos", c->_ufos);
  F("craftWeapons", c->_craftWeapons); F("missions", c->_missions); F("armor", c->_armor); F("alienRaces", c->_alienRaces);
  F("alienRanks", c->_alienRanks); F("research", c->_research); F("manufacture", c->_manufacture); F("ufopaedia", c->_ufopaedia);
  Begin("constants", "values");
  F("DOOR_OPEN", Mod::DOOR_OPEN); F("SLIDING_DOOR_OPEN", Mod::SLIDING_DOOR_OPEN); F("SLIDING_DOOR_CLOSE", Mod::SLIDING_DOOR_CLOSE);
  F("SMALL_EXPLOSION", Mod::SMALL_EXPLOSION); F("LARGE_EXPLOSION", Mod::LARGE_EXPLOSION); F("EXPLOSION_OFFSET", Mod::EXPLOSION_OFFSET);
  F("SMOKE_OFFSET", Mod::SMOKE_OFFSET); F("UNDERWATER_SMOKE_OFFSET", Mod::UNDERWATER_SMOKE_OFFSET); F("ITEM_DROP", Mod::ITEM_DROP);
  F("ITEM_THROW", Mod::ITEM_THROW); F("ITEM_RELOAD", Mod::ITEM_RELOAD); F("WALK_OFFSET", Mod::WALK_OFFSET);
  F("FLYING_SOUND", Mod::FLYING_SOUND); F("BUTTON_PRESS", Mod::BUTTON_PRESS);
  F("WINDOW_POPUP", std::vector<int>(Mod::WINDOW_POPUP, Mod::WINDOW_POPUP + 3)); F("UFO_FIRE", Mod::UFO_FIRE); F("UFO_HIT", Mod::UFO_HIT);
  F("UFO_CRASH", Mod::UFO_CRASH); F("UFO_EXPLODE", Mod::UFO_EXPLODE); F("INTERCEPTOR_HIT", Mod::INTERCEPTOR_HIT);
  F("INTERCEPTOR_EXPLODE", Mod::INTERCEPTOR_EXPLODE); F("GEOSCAPE_CURSOR", Mod::GEOSCAPE_CURSOR);
  F("BASESCAPE_CURSOR", Mod::BASESCAPE_CURSOR); F("BATTLESCAPE_CURSOR", Mod::BATTLESCAPE_CURSOR); F("UFOPAEDIA_CURSOR", Mod::UFOPAEDIA_CURSOR);
  F("GRAPHS_CURSOR", Mod::GRAPHS_CURSOR); F("DAMAGE_RANGE", Mod::DAMAGE_RANGE); F("EXPLOSIVE_DAMAGE_RANGE", Mod::EXPLOSIVE_DAMAGE_RANGE);
  F("FIRE_DAMAGE_RANGE", std::vector<int>(Mod::FIRE_DAMAGE_RANGE, Mod::FIRE_DAMAGE_RANGE + 2)); F("DEBRIEF_MUSIC_GOOD", Mod::DEBRIEF_MUSIC_GOOD);
  F("DEBRIEF_MUSIC_BAD", Mod::DEBRIEF_MUSIC_BAD);
  Begin("settings", "values");
  F("costEngineer", m->_costEngineer); F("costScientist", m->_costScientist); F("timePersonnel", m->_timePersonnel);
  F("initialFunding", m->_initialFunding); F("turnAIUseGrenade", m->_turnAIUseGrenade); F("turnAIUseBlaster", m->_turnAIUseBlaster);
  F("defeatScore", m->_defeatScore); F("defeatFunds", m->_defeatFunds); F("difficultyDemigod", m->_difficultyDemigod);
  F("alienFuel", m->_alienFuel); F("fontName", m->_fontName); F("alienItemLevels", m->_alienItemLevels);
  F("difficultyCoefficient", std::vector<int>(Mod::DIFFICULTY_COEFFICIENT, Mod::DIFFICULTY_COEFFICIENT + 5));
  for (int i = 0; i < 5; i++) {
    Line(("adjust" + std::to_string(i)).c_str(), StatsStr(m->_statAdjustment[i].statGrowth) + "|" + V(m->_statAdjustment[i].growthMultiplier) + "|" + V(m->_statAdjustment[i].aimAndArmorMultiplier));
  }
  Begin("startingBase", "keys");
  std::vector<std::string> keys;
  for (YAML::const_iterator i = m->_startingBase.begin(); i != m->_startingBase.end(); ++i) keys.push_back(i->first.as<std::string>());
  std::sort(keys.begin(), keys.end());  // the YAML node keeps the order of the file, the Pascal map the order of the keys
  F("keys", keys);
}

static void DumpInventories(Mod* m) {
  for (auto& p : m->_invs) {
    RuleInventory* r = p.second;
    Begin("invs", p.first);
    F("id", r->_id); F("x", r->_x); F("y", r->_y); F("type", (int)r->_type); F("listOrder", r->_listOrder);
    std::string s = "[";
    for (size_t i = 0; i < r->_slots.size(); i++) { if (i) s += ","; s += std::to_string(r->_slots[i].x) + "/" + std::to_string(r->_slots[i].y); }
    Line("slots", s + "]");
    F("costs", r->_costs);
  }
}

static void DumpResearch(Mod* m) {
  for (auto& p : m->_research) {
    RuleResearch* r = p.second;
    Begin("research", p.first);
    F("name", r->_name); F("lookup", r->_lookup); F("cutscene", r->_cutscene); F("cost", r->_cost); F("points", r->_points);
    F("dependencies", r->_dependencies); F("unlocks", r->_unlocks); F("getOneFree", r->_getOneFree); F("requires", r->_requires);
    F("needItem", r->_needItem); F("destroyItem", r->_destroyItem); F("listOrder", r->_listOrder);
  }
  Begin("research", "*"); F("final", m->_finalResearch);
}

static void DumpManufacture(Mod* m) {
  for (auto& p : m->_manufacture) {
    RuleManufacture* r = p.second;
    Begin("manufacture", p.first);
    F("name", r->_name); F("category", r->_category); F("requires", r->_requires); F("space", r->_space); F("time", r->_time);
    F("cost", r->_cost); F("requiredItems", r->_requiredItems); F("producedItems", r->_producedItems); F("listOrder", r->_listOrder);
  }
}

static void DumpAlienRaces(Mod* m) {
  for (auto& p : m->_alienRaces) {
    Begin("alienRaces", p.first);
    F("id", p.second->_id); F("members", p.second->_members);
  }
}

static void DumpTrajectories(Mod* m) {
  for (auto& p : m->_ufoTrajectories) {
    UfoTrajectory* r = p.second;
    Begin("ufoTrajectories", p.first);
    F("id", r->_id); F("groundTimer", r->_groundTimer);
    std::string s = "[";
    for (size_t i = 0; i < r->_waypoints.size(); i++) { if (i) s += ","; s += std::to_string(r->_waypoints[i].zone) + "/" + std::to_string(r->_waypoints[i].altitude) + "/" + std::to_string(r->_waypoints[i].speed); }
    Line("waypoints", s + "]");
  }
}

static void DumpMusics(Mod* m) {
  for (auto& p : m->_musicDefs) {
    Begin("musics", p.first);
    F("type", p.second->_type); F("name", p.second->getName()); F("catPos", p.second->_catPos); F("normalization", p.second->_normalization);
  }
}

static void DumpCommendations(Mod* m) {
  for (auto& p : m->_commendations) {
    RuleCommendations* r = p.second;
    Begin("commendations", p.first);
    F("description", r->_description); F("sprite", r->_sprite); F("criteria", r->_criteria);
    std::string k = "[";
    for (size_t i = 0; i < r->_killCriteria.size(); i++) {
      if (i) k += ";";
      for (size_t j = 0; j < r->_killCriteria[i].size(); j++) { if (j) k += "+"; k += std::to_string(r->_killCriteria[i][j].first) + V(r->_killCriteria[i][j].second); }
    }
    Line("killCriteria", k + "]");
  }
}

static void DumpAll(Mod* m, const std::set<std::string>& only) {
  gOnly = only;
  DumpManifest(m);
  if (Wanted("countries")) DumpCountries(m);
  if (Wanted("regions")) DumpRegions(m);
  if (Wanted("facilities")) DumpFacilities(m);
  if (Wanted("crafts")) DumpCrafts(m);
  if (Wanted("craftWeapons")) DumpCraftWeapons(m);
  if (Wanted("items")) DumpItems(m);
  if (Wanted("ufos")) DumpUfos(m);
  if (Wanted("invs")) DumpInventories(m);
  if (Wanted("terrains")) DumpTerrains(m);
  if (Wanted("mapDataSets")) DumpMapDataSets(m);
  if (Wanted("armors")) DumpArmors(m);
  if (Wanted("soldiers")) DumpSoldiers(m);
  if (Wanted("units")) DumpUnits(m);
  if (Wanted("alienDeployments")) DumpDeployments(m);
  if (Wanted("alienMissions")) DumpAlienMissions(m);
  if (Wanted("missionScripts")) DumpMissionScripts(m);
  if (Wanted("ufopaedia")) DumpArticles(m);
  if (Wanted("mapScripts")) DumpMapScripts(m);
  if (Wanted("mcdPatches")) DumpMcdPatches(m);
  if (Wanted("extras")) DumpExtras(m);
  if (Wanted("interfaces")) DumpInterfacesEtc(m);
  if (Wanted("indexes")) DumpIndexes(m);
  if (Wanted("research")) DumpResearch(m);
  if (Wanted("manufacture")) DumpManufacture(m);
  if (Wanted("alienRaces")) DumpAlienRaces(m);
  if (Wanted("ufoTrajectories")) DumpTrajectories(m);
  if (Wanted("musics")) DumpMusics(m);
  if (Wanted("commendations")) DumpCommendations(m);
}
