// Harness for Libs\XcomSave (SavedGame): runs the REAL OpenXcom objects (linked from a real build, see build4.cmd) to
// make saved games: Mod::loadAll on the real TFTD mods, Mod::newSave(), then states that a game would reach (UFOs,
// missions, alien bases, transfers, research, production, wounded soldiers, diaries, months passed), and writes
//   <name>.sav     what SavedGame::save writes
//   <name>.re.sav  what SavedGame::load + save of that file writes again
// Contains no OpenXcom code; the output goes in Tests\Data\XcomSave\realsave.
// usage: savegen <data folder> <user folder> <output folder> <count> <seed>
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
#include "Mod/RuleAlienMission.h"
#include "Mod/RuleUfo.h"
#include "Mod/RuleCraft.h"
#include "Mod/RuleSoldier.h"
#include "Mod/RuleResearch.h"
#include "Mod/RuleManufacture.h"
#include "Mod/RuleBaseFacility.h"
#include "Mod/AlienDeployment.h"
#include "Mod/UfoTrajectory.h"
#include "Mod/RuleRegion.h"
#include "Savegame/SavedGame.h"
#include "Savegame/Base.h"
#include "Savegame/Craft.h"
#include "Savegame/Ufo.h"
#include "Savegame/Waypoint.h"
#include "Savegame/MissionSite.h"
#include "Savegame/AlienBase.h"
#include "Savegame/AlienMission.h"
#include "Savegame/AlienStrategy.h"
#include "Savegame/Soldier.h"
#include "Savegame/SoldierDiary.h"
#include "Savegame/Transfer.h"
#include "Savegame/ResearchProject.h"
#include "Savegame/Production.h"
#include "Savegame/Country.h"
#include "Savegame/Region.h"
#include "Savegame/ItemContainer.h"
#include "Savegame/MissionStatistics.h"
#include "Savegame/GameTime.h"
#include "Engine/Options.h"
#include "Engine/FileMap.h"
#include "Engine/Logger.h"
#include "Engine/Exception.h"
#include "Engine/RNG.h"
#include "Engine/CrossPlatform.h"
#undef protected
#undef private
#undef main

using namespace OpenXcom;

static int Pick(int n) { return n <= 0 ? 0 : RNG::generate(0, n - 1); }

// A state that a game could reach: every piece is made with the real constructors and setters
static void Play(Mod* mod, SavedGame* s, int variant) {
  s->setDifficulty((GameDifficulty)(variant % 5));
  s->setGlobeZoom(variant % 6);
  s->setGlobeLongitude(0.1 * variant);
  s->setGlobeLatitude(-0.05 * variant);
  Base* base = s->getBases()->front();
  base->_name = "Base " + std::to_string(variant);
  base->_lon = 0.5 + 0.1 * variant;
  base->_lat = 0.2;
  for (std::vector<Craft*>::iterator c = base->getCrafts()->begin(); c != base->getCrafts()->end(); ++c) {
    (*c)->setLongitude(base->getLongitude());
    (*c)->setLatitude(base->getLatitude());
  }
  if (variant == 0) return;

  // regions and countries: activity
  for (size_t i = 0; i < s->getRegions()->size(); i++) {
    (*s->getRegions())[i]->addActivityAlien(Pick(40));
    (*s->getRegions())[i]->addActivityXcom(Pick(40));
  }
  for (size_t i = 0; i < s->getCountries()->size(); i++) (*s->getCountries())[i]->addActivityAlien(Pick(30));

  // soldiers: wounds, ranks, kills, psi, diary
  std::vector<Soldier*>* soldiers = base->getSoldiers();
  for (size_t i = 0; i < soldiers->size(); i++) {
    Soldier* so = (*soldiers)[i];
    if (Pick(3) == 0) so->setWoundRecovery(1 + Pick(20));
    for (int k = Pick(4); k > 0; k--) so->promoteRank();
    so->addKillCount(Pick(9));
    so->addMissionCount();
    if (Pick(3) == 0) so->setPsiTraining(true);
    SoldierDiary* d = so->getDiary();
    if (Pick(2) == 0) { d->getMissionIdList().push_back(Pick(30)); d->getMissionIdList().push_back(Pick(30)); }
    if (Pick(2) == 0) d->addMonthlyService();
    if (Pick(4) == 0) d->awardOriginalEightCommendation();
    if (Pick(4) == 0) d->_hitCounterTotal = Pick(50);
    if (Pick(5) == 0) d->_bestSoldier = true;
  }
  // the crafts: damage, fuel, items
  for (std::vector<Craft*>::iterator c = base->getCrafts()->begin(); c != base->getCrafts()->end(); ++c) {
    (*c)->setDamage(Pick((*c)->getRules()->getMaxDamage()));
    (*c)->setFuel(Pick((*c)->getRules()->getMaxFuel() + 1));
    if (Pick(3) == 0) (*c)->setStatus("STR_REPAIRS");
  }
  if (variant == 1) return;

  // alien bases and missions
  const std::vector<std::string>& dep = mod->getDeploymentsList();
  std::vector<std::string> regions = mod->getRegionsList();
  std::vector<AlienBase*> abases;
  if (!dep.empty()) {
    for (int k = 0; k < 2; k++) {
      AlienDeployment* ad = 0;
      for (size_t t = 0; t < dep.size() && !ad; t++) {
        AlienDeployment* x = mod->getDeployment(dep[(t + k + variant) % dep.size()]);
        if (x && !x->getMarkerName().empty() && x->getMarkerIcon() == 7 /* alien base marker */) ad = x;
      }
      if (!ad) {
        for (size_t t = 0; t < dep.size() && !ad; t++) { AlienDeployment* x = mod->getDeployment(dep[t]); if (x && !x->getMarkerName().empty()) ad = x; }
      }
      if (ad) {
        AlienBase* ab = new AlienBase(ad);
        ab->setId(s->getId(ad->getMarkerName()));
        ab->setAlienRace("STR_SOMETHING_" + std::to_string(k));
        ab->setLongitude(1.0 + k); ab->setLatitude(0.3 * k);
        ab->setDiscovered(Pick(2) == 0);
        s->getAlienBases()->push_back(ab);
        abases.push_back(ab);
      }
    }
  }
  std::vector<AlienMission*> missions;
  std::vector<std::string> mrules = mod->getAlienMissionList();
  for (int k = 0; k < 3 && !mrules.empty(); k++) {
    const RuleAlienMission* r = mod->getAlienMission(mrules[(variant + k) % mrules.size()]);
    if (!r || r->getWaveCount() == 0) continue;
    AlienMission* m = new AlienMission(*r);
    m->setId(s->getId("ALIEN_MISSIONS"));
    m->setRegion(regions[(variant + k) % regions.size()], *mod);
    m->setRace("STR_RACE_" + std::to_string(k));
    m->start(Pick(2) ? 0 : 30 * (1 + Pick(40)));
    if (k == 1 && !abases.empty()) m->setAlienBase(abases[0]);
    m->_missionSiteZone = Pick(3) - 1;
    m->_nextUfoCounter = Pick(4);
    s->getAlienMissions().push_back(m);
    missions.push_back(m);
  }
  if (variant == 2) return;

  // UFOs with their trajectories, waypoints, a mission site
  std::vector<std::string> ufos = mod->getUfosList();
  std::vector<std::string> trajs;
  for (std::map<std::string, UfoTrajectory*>::iterator t = mod->_ufoTrajectories.begin(); t != mod->_ufoTrajectories.end(); ++t) trajs.push_back(t->first);
  for (int k = 0; k < 3 && !ufos.empty() && !missions.empty() && !trajs.empty(); k++) {
    const RuleUfo* r = mod->getUfo(ufos[(variant + k) % ufos.size()]);
    if (!r) continue;
    Ufo* u = new Ufo(r);
    u->setId(s->getId("STR_UFO"));
    u->setMissionInfo(missions[k % missions.size()], mod->getUfoTrajectory(trajs[(variant + k) % trajs.size()]));
    u->setLongitude(0.3 * (k + 1)); u->setLatitude(0.1 * k);
    Waypoint* w = new Waypoint();
    w->setLongitude(1.0 + 0.2 * k); w->setLatitude(0.2 * k);
    u->setSpeed(r->getMaxSpeed());
    u->setDestination(w);
    u->setDamage(Pick(r->getMaxDamage() + 1));
    if (k == 1) { u->setAltitude("STR_GROUND"); u->setSecondsRemaining(5 * (1 + Pick(100))); u->setLandId(s->getId("STR_LANDING_SITE")); }
    if (k == 2) u->setAltitude("STR_VERY_LOW");
    u->setDetected(Pick(2) == 0);
    u->setHyperDetected(Pick(3) == 0);
    u->setTrajectoryPoint(Pick(4));
    s->getUfos()->push_back(u);
  }
  Waypoint* wp = new Waypoint();
  wp->setId(s->getId("STR_WAY_POINT"));
  wp->setLongitude(2.0); wp->setLatitude(0.4);
  s->getWaypoints()->push_back(wp);
  if (!s->getUfos()->empty() && !base->getCrafts()->empty()) {
    Craft* c = base->getCrafts()->front();
    c->setStatus("STR_OUT");
    c->setDestination(s->getUfos()->front());
  }
  if (base->getCrafts()->size() > 1 && Pick(2) == 0) {
    Craft* c = (*base->getCrafts())[1];
    c->setStatus("STR_OUT");
    c->setDestination(wp);
  }
  if (variant == 3) return;

  // transfers, research, productions, items, funds, months
  std::vector<std::string> items = mod->getItemsList();
  if (!items.empty()) {
    Transfer* t = new Transfer(24 + Pick(48));
    t->setItems(items[Pick(items.size())], 1 + Pick(20));
    base->getTransfers()->push_back(t);
    base->getStorageItems()->addItem(items[Pick(items.size())], 1 + Pick(50));
  }
  Transfer* ts = new Transfer(12); ts->setScientists(3); base->getTransfers()->push_back(ts);
  Transfer* te = new Transfer(18); te->setEngineers(2); base->getTransfers()->push_back(te);
  if (!soldiers->empty() && mod->getSoldier(mod->getSoldiersList().front())) {
    Transfer* tso = new Transfer(30);
    Soldier* ns = new Soldier(mod->getSoldier(mod->getSoldiersList().front()), mod->getArmor(mod->getSoldier(mod->getSoldiersList().front())->getArmor()), s->getId("STR_SOLDIER"));
    tso->setSoldier(ns);
    base->getTransfers()->push_back(tso);
  }
  std::vector<std::string> res = mod->getResearchList();
  for (int k = 0; k < 3 && !res.empty(); k++) {
    RuleResearch* rr = mod->getResearch(res[(variant * 3 + k) % res.size()]);
    if (rr) {
      ResearchProject* p = new ResearchProject(rr, rr->getCost());
      p->setAssigned(1 + Pick(5)); p->setSpent(Pick(20));
      base->addResearch(p);
    }
  }
  if (!res.empty()) { RuleResearch* rr = mod->getResearch(res[(variant + 7) % res.size()]); if (rr) s->addFinishedResearchSimple(rr); }
  std::vector<std::string> man = mod->getManufactureList();
  for (int k = 0; k < 2 && !man.empty(); k++) {
    RuleManufacture* mr = mod->getManufacture(man[(variant + k) % man.size()]);
    if (mr) {
      Production* p = new Production(mr, 1 + Pick(10));
      p->setAssignedEngineers(1 + Pick(6)); p->setTimeSpent(Pick(100));
      if (k == 1) p->setInfiniteAmount(true);
      base->addProduction(p);
    }
  }
  base->setScientists(Pick(30));
  base->setEngineers(Pick(30));
  s->setFunds(s->getFunds() + 1000000 * (int64_t)(Pick(9) - 3));
  if (variant >= 5) {
    s->addMonth();
    s->getTime()->advance();
    s->monthlyFunding();
    s->getAlienStrategy().init(mod);
    s->getAlienStrategy().addMissionRun("var" + std::to_string(Pick(3)), 1 + Pick(3));
    s->getAlienStrategy().addMissionLocation("loc" + std::to_string(Pick(3)), regions[Pick(regions.size())], Pick(4), 5);
    s->getAlienStrategy().addMissionLocation("loc" + std::to_string(Pick(3)), regions[Pick(regions.size())], Pick(4), 5);
    MissionStatistics* ms = new MissionStatistics();
    ms->id = Pick(20); ms->markerName = Pick(2) ? "STR_UFO_" : ""; ms->markerId = Pick(9);
    ms->time = *s->getTime();
    ms->region = regions[Pick(regions.size())]; ms->country = "STR_COUNTRY_X"; ms->type = "STR_UFO_CRASH_RECOVERY";
    ms->ufo = "STR_SMALL_SCOUT"; ms->success = Pick(2); ms->rating = "STR_EXCELLENT"; ms->score = Pick(100);
    ms->alienRace = "STR_SECTOID"; ms->daylight = Pick(16); ms->injuryList[Pick(5)] = Pick(5); ms->injuryList[Pick(5)] = Pick(5);
    ms->valiantCrux = Pick(2); ms->lootValue = Pick(5000);
    s->getMissionStatistics()->push_back(ms);
    if (!soldiers->empty() && Pick(2)) {
      Soldier* dead = (*soldiers).back();
      soldiers->pop_back();
      s->getDeadSoldiers()->push_back(dead);
    }
  }
}

int main(int argc, char** argv) {
  if (argc < 6) { fprintf(stderr, "usage: savegen <data> <user> <out folder> <count> <seed>\n"); return 2; }
  std::string data = argv[1], user = argv[2], out = argv[3];
  int count = atoi(argv[4]);
  uint64_t seed = (uint64_t)atoll(argv[5]);
  static char a0[] = "savegen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
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
      RNG::setSeed(seed + v);
      SavedGame* s = mod->newSave();
      Play(mod, s, v);
      char name[64];
      snprintf(name, sizeof name, "save%02d.sav", v);
      s->save(name);
      SavedGame* t = new SavedGame();
      t->load(name, mod);
      snprintf(name, sizeof name, "save%02d.re.sav", v);
      t->save(name);
      delete t;
      delete s;
      snprintf(name, sizeof name, "save%02d", v);
      // copy both files out of the user folder
      for (const char* ext : {".sav", ".re.sav"}) {
        std::string from = folder + name + ext, to = out + "/" + name + ext;
        std::ifstream in(from.c_str(), std::ios::binary);
        std::ofstream o(to.c_str(), std::ios::binary);
        o << in.rdbuf();
      }
    }
  } catch (Exception& e) {
    fprintf(stderr, "EXCEPTION: %s\n", e.what());
    return 1;
  }
  fprintf(stderr, "ok\n");
  return 0;
}
