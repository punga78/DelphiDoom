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
        Line(key.c_str(), V(ma.lonMin) + "," + V(ma.lonMax) + "," + V(ma.latMin) + "," + V(ma.latMax) + "," + V(ma.texture) + "," + V(ma.name));
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
  if (Wanted("craftWeapons")) DumpCraftWeapons(m);
  if (Wanted("invs")) DumpInventories(m);
  if (Wanted("research")) DumpResearch(m);
  if (Wanted("manufacture")) DumpManufacture(m);
  if (Wanted("alienRaces")) DumpAlienRaces(m);
  if (Wanted("ufoTrajectories")) DumpTrajectories(m);
  if (Wanted("musics")) DumpMusics(m);
  if (Wanted("commendations")) DumpCommendations(m);
}
