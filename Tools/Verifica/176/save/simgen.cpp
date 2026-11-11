// Harness for Libs\XcomStrategy (the strategic logic): runs the REAL OpenXcom objects (linked from a real build, see
// build6.cmd) on the saved games of Tests\Data\XcomSave\realsave: SavedGame::load, then a scenario that changes the
// state with the real Craft/Production/AlienMission/Ufo code driven by the real RNG with a fixed seed, and writes
//   simNN.<scenario>.sav   what SavedGame::save writes after the scenario
//   simNN.<scenario>.txt   what the functions answered (return values), one line per call
// Contains no OpenXcom code; the output goes in Tests\Data\XcomStrategy.
// usage: simgen <data folder> <user folder> <saves folder> <output folder> <count> <scenario>
// scenarios: craft, production, mission
#include <yaml-cpp/yaml.h>
#include <utility>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>
#include <map>
#include <set>
#include <fstream>
#include <sstream>
#include <algorithm>
#define private public
#define protected public
#include "Mod/Mod.h"
#include "Mod/RuleCraft.h"
#include "Mod/RuleCraftWeapon.h"
#include "Mod/RuleItem.h"
#include "Mod/RuleManufacture.h"
#include "Mod/RuleAlienMission.h"
#include "Mod/RuleRegion.h"
#include "Mod/RuleGlobe.h"
#include "Mod/UfoTrajectory.h"
#include "Mod/AlienDeployment.h"
#include "Mod/RuleUfo.h"
#include "Savegame/SavedGame.h"
#include "Savegame/Base.h"
#include "Savegame/Craft.h"
#include "Savegame/CraftWeapon.h"
#include "Savegame/Ufo.h"
#include "Savegame/Waypoint.h"
#include "Savegame/MissionSite.h"
#include "Savegame/AlienBase.h"
#include "Savegame/AlienMission.h"
#include "Savegame/Soldier.h"
#include "Savegame/Production.h"
#include "Savegame/ItemContainer.h"
#include "Savegame/BaseFacility.h"
#include "Savegame/Country.h"
#include "Savegame/Region.h"
#include "Geoscape/Globe.h"
#include "Engine/Game.h"
#include "Engine/Options.h"
#include "Engine/FileMap.h"
#include "Engine/Logger.h"
#include "Engine/Exception.h"
#include "Engine/RNG.h"
#undef protected
#undef private
#undef main

using namespace OpenXcom;

static int Pick(int n) { return n <= 0 ? 0 : RNG::generate(0, n - 1); }

static FILE* gOut = 0;

static std::string Ammo(Craft* c) {
  std::string s;
  for (size_t i = 0; i < c->_weapons.size(); i++) {
    char b[32];
    if (c->_weapons[i]) snprintf(b, sizeof b, "%s%d%s", i ? "," : "", c->_weapons[i]->getAmmo(), c->_weapons[i]->isRearming() ? "r" : "");
    else snprintf(b, sizeof b, "%s-", i ? "," : "");
    s += b;
  }
  return s;
}

static std::string Storage(Base* b) {
  std::string s;
  for (std::map<std::string, int>::iterator i = b->getStorageItems()->getContents()->begin(); i != b->getStorageItems()->getContents()->end(); ++i) {
    char n[16];
    snprintf(n, sizeof n, "=%d;", i->second);
    s += i->first + n;
  }
  return s;
}

// Craft: rearm, detect, getNumSoldiers, reuseItem, unload
static void ScenarioCraft(Mod* mod, SavedGame* s, int v) {
  int bi = 0;
  for (std::vector<Base*>::iterator bp = s->getBases()->begin(); bp != s->getBases()->end(); ++bp, ++bi) {
    Base* base = *bp;
    for (size_t ci = 0; ci < base->getCrafts()->size(); ci++) {
      Craft* c = (*base->getCrafts())[ci];
      for (size_t i = 0; i < c->_weapons.size(); i++)
        if (c->_weapons[i]) base->getStorageItems()->addItem(c->_weapons[i]->getRules()->getClipItem(), Pick(20));
    }
    for (size_t ci = 0; ci < base->getCrafts()->size(); ci++) {
      Craft* c = (*base->getCrafts())[ci];
      fprintf(gOut, "craft|%d|%d|%d|soldiers=%d\n", v, bi, (int)ci, c->getNumSoldiers());
      for (size_t i = 0; i < c->_weapons.size(); i++) {
        if (!c->_weapons[i]) continue;
        c->_weapons[i]->setAmmo(Pick(c->_weapons[i]->getRules()->getAmmoMax() + 1));
        c->_weapons[i]->setRearming(true);
      }
      c->setStatus("STR_REARMING");
      fprintf(gOut, "craft|%d|%d|%d|before|%s|%s\n", v, bi, (int)ci, Ammo(c).c_str(), Storage(base).c_str());
      for (int step = 0; step < 14; step++) {
        std::string r = c->rearm(mod);
        fprintf(gOut, "rearm|%d|%d|%d|%d|%s|%s|%s\n", v, bi, (int)ci, step, r.c_str(), c->getStatus().c_str(), Ammo(c).c_str());
        if (c->getStatus() == "STR_REFUELLING") break;
      }
      fprintf(gOut, "craft|%d|%d|%d|after|%s\n", v, bi, (int)ci, Storage(base).c_str());
      // reuse of items: ammunition and fuel
      c->setStatus("STR_READY");
      for (size_t i = 0; i < c->_weapons.size(); i++) {
        if (!c->_weapons[i]) continue;
        c->_weapons[i]->setAmmo(Pick(c->_weapons[i]->getRules()->getAmmoMax()));
        c->reuseItem(c->_weapons[i]->getRules()->getClipItem());
      }
      c->reuseItem(c->getRules()->getRefuelItem());
      fprintf(gOut, "reuse|%d|%d|%d|%s|%s\n", v, bi, (int)ci, c->getStatus().c_str(), Ammo(c).c_str());
      // radar
      for (size_t ui = 0; ui < s->getUfos()->size(); ui++) {
        Ufo* u = (*s->getUfos())[ui];
        // volatile: every step is rounded to a double (the x87 of this build would keep extended intermediates)
        volatile double offset = (Pick(100) - 50) * 0.004;
        volatile double lon = u->getLongitude() + offset;
        c->setLongitude(lon);
        offset = (Pick(100) - 50) * 0.004;
        volatile double lat = u->getLatitude() + offset;
        c->setLatitude(lat);
        bool d = c->detect(u);
        fprintf(gOut, "detect|%d|%d|%d|%d|%d|vis=%d\n", v, bi, (int)ci, (int)ui, (int)d, u->getVisibility());
      }
    }
    // unload the first and the last craft
    for (int which = 0; which < 2 && !base->getCrafts()->empty(); which++) {
      Craft* c = which == 0 ? base->getCrafts()->front() : base->getCrafts()->back();
      if (which == 1 && c == base->getCrafts()->front()) break;
      c->unload(mod);
      fprintf(gOut, "unload|%d|%d|%d|%s|%s\n", v, bi, which, Storage(base).c_str(), Ammo(c).c_str());
      int still = 0;
      for (size_t k = 0; k < base->getSoldiers()->size(); k++) if ((*base->getSoldiers())[k]->getCraft() == c) still++;
      fprintf(gOut, "unload|%d|%d|%d|soldiers=%d|vehicles=%d\n", v, bi, which, still, (int)c->getVehicles()->size());
    }
  }
}

// Production: new productions of random rules and the steps of every production of every base
static void ScenarioProduction(Mod* mod, SavedGame* s, int v) {
  int bi = 0;
  s->setFunds(1000000 + Pick(3000000));
  const std::vector<std::string>& list = mod->getManufactureList();
  for (std::vector<Base*>::iterator bp = s->getBases()->begin(); bp != s->getBases()->end(); ++bp, ++bi) {
    Base* base = *bp;
    int n = 3 + Pick(5);
    for (int k = 0; k < n; k++) {
      RuleManufacture* r = mod->getManufacture(list[Pick((int)list.size())], true);
      Production* p = new Production(r, 1 + Pick(6));
      p->setAssignedEngineers(1 + Pick(40));
      p->setInfiniteAmount(Pick(8) == 0);
      p->setSellItems(Pick(3) == 0);
      for (std::map<std::string, int>::const_iterator i = r->getRequiredItems().begin(); i != r->getRequiredItems().end(); ++i) {
        if (mod->getItem(i->first) != 0) base->getStorageItems()->addItem(i->first, Pick(40));
        else if (mod->getCraft(i->first) != 0 && Pick(2) == 0) base->getCrafts()->push_back(new Craft(mod->getCraft(i->first, true), base, s->getId(i->first)));
      }
      base->addProduction(p);
    }
    fprintf(gOut, "base|%d|%d|productions=%d|funds=%lld|%s\n", v, bi, (int)base->_productions.size(), (long long)s->getFunds(), Storage(base).c_str());
    for (size_t pi = 0; pi < base->_productions.size(); pi++) {
      Production* p = base->_productions[pi];
      int steps = 0;
      productionProgress_e res = PROGRESS_NOT_COMPLETE;
      while (steps < 600) {
        res = p->step(base, s, mod);
        steps++;
        if (res != PROGRESS_NOT_COMPLETE) break;
      }
      fprintf(gOut, "prod|%d|%d|%d|%s|steps=%d|res=%d|spent=%d|produced=%d|funds=%lld|crafts=%d|%s\n", v, bi, (int)pi,
        p->getRules()->getName().c_str(), steps, (int)res, p->getTimeSpent(), p->getAmountProduced(), (long long)s->getFunds(),
        (int)base->getCrafts()->size(), Storage(base).c_str());
    }
  }
}

// Whether every zone that a mission and its trajectories use exists (with areas) in the region
static bool RegionOk(Mod* mod, const RuleAlienMission& rule, const RuleRegion* region) {
  const std::vector<MissionZone>& z = region->getMissionZones();
  std::set<size_t> zones;
  if (rule.getSpawnZone() >= 0) zones.insert((size_t)rule.getSpawnZone());
  for (size_t w = 0; w < rule.getWaveCount(); w++) {
    const UfoTrajectory* t = mod->getUfoTrajectory(rule.getWave(w).trajectory);
    if (!t) return false;
    for (size_t k = 0; k < t->getWaypointCount(); k++) zones.insert(t->getZone(k));
  }
  const UfoTrajectory* a = mod->getUfoTrajectory(UfoTrajectory::RETALIATION_ASSAULT_RUN);
  if (a) for (size_t k = 0; k < a->getWaypointCount(); k++) zones.insert(a->getZone(k));
  for (std::set<size_t>::iterator i = zones.begin(); i != zones.end(); ++i)
    if (*i >= z.size() || z[*i].areas.empty()) return false;
  return true;
}

static void PrintUfo(int v, int mi, int round, int ui, const char* action, Ufo* u) {
  fprintf(gOut, "ufo|%d|%d|%d|%d|%s|status=%d|tp=%d|lon=%.17g|lat=%.17g|alt=%s|secs=%u|land=%d|det=%d|speed=%d|dest=%d\n", v, mi, round, ui,
    action, (int)u->getStatus(), (int)u->getTrajectoryPoint(), u->getLongitude(), u->getLatitude(), u->getAltitude().c_str(),
    (unsigned)u->getSecondsRemaining(), u->getLandId(), (int)u->getDetected(), u->getSpeed(), (int)(u->getDestination() != 0));
}

// AlienMission: new missions of every type in regions that have the zones, then rounds of think and of the UFOs of the
// mission arriving at a waypoint or lifting off
static void ScenarioMission(Mod* mod, SavedGame* s, int v) {
  Game* game = (Game*)calloc(1, sizeof(Game));
  game->_save = s;
  game->_mod = mod;
  Globe* globe = (Globe*)calloc(1, sizeof(Globe));
  globe->_rules = mod->getGlobe();
  const std::vector<std::string>& missions = mod->getAlienMissionList();
  const std::vector<std::string>& regions = mod->getRegionsList();
  if (!s->getBases()->empty()) s->getBases()->front()->setRetaliationTarget(true);
  for (size_t k = 0; k < missions.size(); k++) {
    const RuleAlienMission* rule = mod->getAlienMission(missions[k]);
    // the regions where the mission can run, in the order of the list
    std::vector<std::string> ok;
    for (size_t r = 0; r < regions.size(); r++) {
      const RuleRegion* rr = mod->getRegion(regions[r]);
      std::string eff = rr->getMissionRegion().empty() ? regions[r] : rr->getMissionRegion();
      if (RegionOk(mod, *rule, mod->getRegion(eff))) ok.push_back(regions[r]);
    }
    if (ok.empty()) { fprintf(gOut, "skip|%d|%s\n", v, missions[k].c_str()); continue; }
    AlienMission* m = new AlienMission(*rule);
    m->setId(s->getId("ALIEN_MISSIONS"));
    m->setRegion(ok[Pick((int)ok.size())], *mod);
    m->setRace(rule->generateRace(s->getMonthsPassed() < 0 ? 0 : s->getMonthsPassed()));
    m->start(Pick(2) == 0 ? 0 : 30 * (1 + Pick(5)));
    if (Pick(3) == 0) m->setMissionSiteZone(0);
    if (!s->getAlienBases()->empty() && Pick(2) == 0) m->setAlienBase(s->getAlienBases()->front());
    s->_activeMissions.push_back(m);
    fprintf(gOut, "mission|%d|%s|region=%s|race=%s|countdown=%u\n", v, missions[k].c_str(), m->getRegion().c_str(), m->getRace().c_str(), (unsigned)m->_spawnCountdown);
  }
  for (size_t mi = 0; mi < s->_activeMissions.size(); mi++) {
    AlienMission* m = s->_activeMissions[mi];
    // the missions of the saved game have a region chosen at random: the ones that lack a zone are skipped
    if (!RegionOk(mod, m->_rule, mod->getRegion(m->getRegion()))) { fprintf(gOut, "skipmission|%d|%d\n", v, (int)mi); continue; }
    for (int round = 0; round < 40; round++) {
      if (m->_spawnCountdown > 30 && Pick(2) == 0) m->_spawnCountdown = 30;
      m->think(*game, *globe);
      fprintf(gOut, "think|%d|%d|%d|wave=%u|ctr=%u|cd=%u|live=%u|ufos=%d|sites=%d|bases=%d\n", v, (int)mi, round, (unsigned)m->_nextWave,
        (unsigned)m->_nextUfoCounter, (unsigned)m->_spawnCountdown, (unsigned)m->_liveUfos, (int)s->getUfos()->size(),
        (int)s->getMissionSites()->size(), (int)s->getAlienBases()->size());
      for (size_t ui = 0; ui < s->getUfos()->size();) {
        Ufo* u = (*s->getUfos())[ui];
        if (u->getMission() != m || Pick(3) == 0) { ui++; continue; }
        const char* action = "none";
        if (u->getStatus() == Ufo::FLYING) {
          if (Pick(2) == 0) u->setDetected(true);
          m->ufoReachedWaypoint(*u, *game, *globe);
          action = "reach";
        } else if (u->getStatus() == Ufo::LANDED || u->getStatus() == Ufo::CRASHED) {
          if (u->getStatus() == Ufo::LANDED && Pick(8) == 0) u->setStatus(Ufo::CRASHED);
          m->ufoLifting(*u, *s);
          action = "lift";
        }
        PrintUfo(v, (int)mi, round, (int)ui, action, u);
        if (u->getStatus() == Ufo::DESTROYED) {
          delete u;
          s->getUfos()->erase(s->getUfos()->begin() + ui);
        } else ui++;
      }
    }
  }
}

int main(int argc, char** argv) {
  if (argc < 7) { fprintf(stderr, "usage: simgen <data> <user> <saves> <out> <count> <scenario>\n"); return 2; }
  std::string data = argv[1], user = argv[2], saves = argv[3], out = argv[4];
  int count = atoi(argv[5]);
  std::string scenario = argv[6];
  static char a0[] = "simgen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
  std::string cfg = user;
  char* args[] = {a0, a1, (char*)data.c_str(), a3, (char*)user.c_str(), a5, (char*)cfg.c_str()};
  Logger::reportingLevel() = LOG_ERROR;
  if (!Options::init(7, args)) return 3;
  try {
    Options::updateMods();
    Mod::resetGlobalStatics();
    Mod* mod = new Mod();
    mod->loadAll(FileMap::getRulesets());
    std::string folder = Options::getMasterUserFolder();
    for (int v = 0; v < count; v++) {
      char name[1024];
      snprintf(name, sizeof name, "save%02d.sav", v);
      {
        std::ifstream in((saves + "/" + name).c_str(), std::ios::binary);
        std::ofstream o((folder + name).c_str(), std::ios::binary);
        o << in.rdbuf();
      }
      SavedGame* s = new SavedGame();
      s->load(name, mod);
      RNG::setSeed(5000 + v);
      snprintf(name, sizeof name, "%s/sim%02d.%s.txt", out.c_str(), v, scenario.c_str());
      gOut = fopen(name, "wb");
      if (scenario == "craft") ScenarioCraft(mod, s, v);
      else if (scenario == "production") ScenarioProduction(mod, s, v);
      else if (scenario == "mission") ScenarioMission(mod, s, v);
      else { fprintf(stderr, "unknown scenario\n"); return 2; }
      fprintf(gOut, "rng|%d|%llu\n", v, (unsigned long long)RNG::getSeed());
      fclose(gOut);
      snprintf(name, sizeof name, "sim%02d.%s.sav", v, scenario.c_str());
      s->save(name);
      std::string from = folder + name, to = out + "/" + name;
      std::ifstream in(from.c_str(), std::ios::binary);
      std::ofstream o(to.c_str(), std::ios::binary);
      o << in.rdbuf();
      delete s;
    }
  } catch (Exception& e) {
    fprintf(stderr, "EXCEPTION: %s\n", e.what());
    return 1;
  }
  fprintf(stderr, "ok\n");
  return 0;
}
