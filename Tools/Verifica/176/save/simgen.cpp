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
#include <stdarg.h>
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
#include "Savegame/Transfer.h"
#include "Savegame/ResearchProject.h"
#include "Savegame/GameTime.h"
#include "Mod/RuleResearch.h"
#include "Mod/RuleCountry.h"
#include "Mod/RuleBaseFacility.h"
#include "Savegame/Transfer.h"
#include "Savegame/ResearchProject.h"
#include "Savegame/GameTime.h"
#include "Mod/RuleResearch.h"
#include "Mod/RuleBaseFacility.h"
#include "Geoscape/Globe.h"
#include "Engine/Game.h"
#include "Geoscape/GeoscapeState.h"
#include "Mod/RuleMissionScript.h"
#include "Mod/StatString.h"
#include "Mod/Unit.h"
#include "Savegame/SavedGame.h"
#include "Savegame/AlienStrategy.h"
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
    int n = 6 + Pick(10);
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

// ---- the time of the geoscape: the code of GeoscapeState::time5Seconds ... time1Month with the popups written as
// lines of the log (the windows are not made); the dogfights, the battle of a base under attack and the cascade of a
// research are not run (what the Delphi port leaves out too)
struct Clock {
  Game* game; Globe* globe; SavedGame* save; Mod* mod; int dogfights;
};

static void Ev(const char* fmt, ...) {
  va_list args;
  va_start(args, fmt);
  fprintf(gOut, "ev|");
  vfprintf(gOut, fmt, args);
  fprintf(gOut, "\n");
  va_end(args);
}

class DetectXCOMBase2 {
public:
  DetectXCOMBase2(const Base &base) : _base(base) {}
  bool operator()(const Ufo *ufo) const {
    if (ufo->getTrajectoryPoint() <= 1) return false;
    if (ufo->getTrajectory().getZone(ufo->getTrajectoryPoint()) == 5) return false;
    if ((ufo->getMission()->getRules().getObjective() != OBJECTIVE_RETALIATION && !Options::aggressiveRetaliation) ||
        ufo->getTrajectory().getID() == UfoTrajectory::RETALIATION_ASSAULT_RUN ||
        ufo->isCrashed() ||
        _base.getDistance(ufo) >= Nautical(ufo->getRules()->getSightRange())) return false;
    return RNG::percent(_base.getDetectionChance());
  }
private:
  const Base &_base;
};

static void Time5Seconds(Clock& g) {
  SavedGame* sg = g.save;
  if (sg->getBases()->empty()) sg->setEnding(END_LOSE);
  if (sg->getEnding() == END_LOSE) { Ev("GameLost"); return; }
  for (std::vector<Ufo*>::iterator i = sg->getUfos()->begin(); i != sg->getUfos()->end(); ++i) {
    switch ((*i)->getStatus()) {
    case Ufo::FLYING:
      (*i)->think();
      if ((*i)->reachedDestination()) {
        size_t count = sg->getMissionSites()->size();
        AlienMission *mission = (*i)->getMission();
        bool detected = (*i)->getDetected();
        mission->ufoReachedWaypoint(**i, *g.game, *g.globe);
        if (detected != (*i)->getDetected() && !(*i)->getFollowers()->empty()) {
          if (!((*i)->getTrajectory().getID() == UfoTrajectory::RETALIATION_ASSAULT_RUN && (*i)->getStatus() == Ufo::LANDED))
            Ev("UfoLost|%d", (*i)->getId());
        }
        if (count < sg->getMissionSites()->size()) {
          MissionSite *site = sg->getMissionSites()->back();
          site->setDetected(true);
          Ev("MissionDetected|%d", site->getId());
        }
        if ((*i)->getStatus() == Ufo::DESTROYED) return;
        if (Base *base = dynamic_cast<Base*>((*i)->getDestination())) {
          mission->setWaveCountdown(30 * (RNG::generate(0, 400) + 48));
          (*i)->setDestination(0);
          Ev("BaseAttacked|%d|%d", base->getLongitude() > 0 ? 1 : 0, (*i)->getId());
          (*i)->setStatus(Ufo::DESTROYED);
          return;
        }
      }
      break;
    case Ufo::LANDED:
      (*i)->think();
      if ((*i)->getSecondsRemaining() == 0) {
        AlienMission *mission = (*i)->getMission();
        bool detected = (*i)->getDetected();
        mission->ufoLifting(**i, *sg);
        if (detected != (*i)->getDetected() && !(*i)->getFollowers()->empty()) Ev("UfoLost|%d", (*i)->getId());
      }
      break;
    case Ufo::CRASHED:
      (*i)->think();
      if ((*i)->getSecondsRemaining() == 0) { (*i)->setDetected(false); (*i)->setStatus(Ufo::DESTROYED); }
      break;
    case Ufo::DESTROYED:
      break;
    }
  }
  for (std::vector<Base*>::iterator i = sg->getBases()->begin(); i != sg->getBases()->end(); ++i) {
    for (std::vector<Craft*>::iterator j = (*i)->getCrafts()->begin(); j != (*i)->getCrafts()->end();) {
      if ((*j)->isDestroyed()) {
        for (std::vector<Country*>::iterator country = sg->getCountries()->begin(); country != sg->getCountries()->end(); ++country) {
          if ((*country)->getRules()->insideCountry((*j)->getLongitude(), (*j)->getLatitude())) { (*country)->addActivityXcom(-(*j)->getRules()->getScore()); break; }
        }
        for (std::vector<Region*>::iterator region = sg->getRegions()->begin(); region != sg->getRegions()->end(); ++region) {
          if ((*region)->getRules()->insideRegion((*j)->getLongitude(), (*j)->getLatitude())) { (*region)->addActivityXcom(-(*j)->getRules()->getScore()); break; }
        }
        if ((*j)->getRules()->getSoldiers() > 0) {
          for (std::vector<Soldier*>::iterator k = (*i)->getSoldiers()->begin(); k != (*i)->getSoldiers()->end();) {
            if ((*k)->getCraft() == (*j)) k = sg->killSoldier(*k); else ++k;
          }
        }
        Craft *craft = *j;
        j = (*i)->removeCraft(craft, false);
        delete craft;
        continue;
      }
      if ((*j)->getDestination() != 0) {
        Ufo* u = dynamic_cast<Ufo*>((*j)->getDestination());
        if (u != 0) {
          if (!u->getDetected()) {
            if (u->getTrajectory().getID() == UfoTrajectory::RETALIATION_ASSAULT_RUN && (u->getStatus() == Ufo::LANDED || u->getStatus() == Ufo::DESTROYED)) {
              (*j)->returnToBase();
            } else {
              Waypoint *w = new Waypoint();
              w->setLongitude(u->getLongitude());
              w->setLatitude(u->getLatitude());
              w->setId(u->getId());
              (*j)->setDestination(0);
              Ev("CraftNeedsOrders|%d|%d", (*j)->getId(), w->getId());
              delete w;
            }
          }
          if (u->getStatus() == Ufo::LANDED && (*j)->isInDogfight()) (*j)->setInDogfight(false);
          else if (u->getStatus() == Ufo::DESTROYED) (*j)->returnToBase();
        } else {
          if ((*j)->isInDogfight()) (*j)->setInDogfight(false);
        }
      }
      (*j)->think();
      if ((*j)->reachedDestination()) {
        Ufo* u = dynamic_cast<Ufo*>((*j)->getDestination());
        Waypoint *w = dynamic_cast<Waypoint*>((*j)->getDestination());
        MissionSite* m = dynamic_cast<MissionSite*>((*j)->getDestination());
        AlienBase* b = dynamic_cast<AlienBase*>((*j)->getDestination());
        if (u != 0) {
          switch (u->getStatus()) {
          case Ufo::FLYING:
            if (g.dogfights >= 4) { ++j; continue; }
            if (!(*j)->isInDogfight() && u->getSpeed() <= (*j)->getRules()->getMaxSpeed()) {
              (*j)->setInDogfight(true);
              g.dogfights++;
              Ev("Dogfight|%d|%d", (*j)->getId(), u->getId());
              if ((*j)->getRules()->isWaterOnly() && u->getAltitudeInt() > (*j)->getRules()->getMaxAltitude()) Ev("DogfightImpossible|%d|depth", (*j)->getId());
              else if ((*j)->getRules()->isWaterOnly() && !g.globe->insideLand((*j)->getLongitude(), (*j)->getLatitude())) Ev("DogfightImpossible|%d|airborne", (*j)->getId());
            }
            break;
          case Ufo::LANDED:
          case Ufo::CRASHED:
          case Ufo::DESTROYED:
            if ((*j)->getNumSoldiers() > 0 || (*j)->getNumVehicles() > 0) {
              if (!(*j)->isInDogfight()) Ev("Landing|%d|ufo", (*j)->getId());
            } else if (u->getStatus() != Ufo::LANDED) {
              (*j)->returnToBase();
            }
            break;
          }
        } else if (w != 0) {
          Ev("Patrol|%d", (*j)->getId());
          (*j)->setDestination(0);
        } else if (m != 0) {
          if ((*j)->getNumSoldiers() > 0 || (*j)->getNumVehicles() > 0) Ev("Landing|%d|site", (*j)->getId());
          else (*j)->returnToBase();
        } else if (b != 0) {
          if (b->isDiscovered()) {
            if ((*j)->getNumSoldiers() > 0 || (*j)->getNumVehicles() > 0) Ev("Landing|%d|alienbase", (*j)->getId());
            else (*j)->returnToBase();
          }
        }
      }
      ++j;
    }
  }
  for (std::vector<Ufo*>::iterator i = sg->getUfos()->begin(); i != sg->getUfos()->end();) {
    if ((*i)->getStatus() == Ufo::DESTROYED) { delete *i; i = sg->getUfos()->erase(i); } else ++i;
  }
  for (std::vector<Waypoint*>::iterator i = sg->getWaypoints()->begin(); i != sg->getWaypoints()->end();) {
    if ((*i)->getFollowers()->empty()) { delete *i; i = sg->getWaypoints()->erase(i); } else ++i;
  }
}

struct SetRetaliationTarget2 { void operator()(const std::pair<const Region* const, Base*> &iter) const { iter.second->setRetaliationTarget(true); } };

static void Time10Minutes(Clock& g) {
  SavedGame* sg = g.save;
  for (std::vector<Base*>::iterator i = sg->getBases()->begin(); i != sg->getBases()->end(); ++i) {
    for (std::vector<Craft*>::iterator j = (*i)->getCrafts()->begin(); j != (*i)->getCrafts()->end(); ++j) {
      if ((*j)->getStatus() == "STR_OUT") {
        (*j)->consumeFuel();
        if (!(*j)->getLowFuel() && (*j)->getFuel() <= (*j)->getFuelLimit()) {
          (*j)->setLowFuel(true);
          (*j)->returnToBase();
          Ev("LowFuel|%d", (*j)->getId());
        }
        if ((*j)->getDestination() == 0) {
          double range = Nautical((*j)->getRules()->getSightRange());
          for (std::vector<AlienBase*>::iterator b = sg->getAlienBases()->begin(); b != sg->getAlienBases()->end(); ++b) {
            if ((*j)->getDistance(*b) <= range) {
              if (RNG::percent(50 - ((*j)->getDistance(*b) / range) * 50) && !(*b)->isDiscovered()) (*b)->setDiscovered(true);
            }
          }
        }
      }
    }
  }
  if (Options::aggressiveRetaliation) {
    for (std::vector<Base*>::iterator iBase = sg->getBases()->begin(); iBase != sg->getBases()->end(); ++iBase) {
      std::vector<Ufo*>::const_iterator uu = std::find_if(sg->getUfos()->begin(), sg->getUfos()->end(), DetectXCOMBase2(**iBase));
      if (uu != sg->getUfos()->end()) (*iBase)->setRetaliationTarget(true);
    }
  } else {
    std::map<const Region *, Base *> discovered;
    for (std::vector<Base*>::iterator iBase = sg->getBases()->begin(); iBase != sg->getBases()->end(); ++iBase) {
      std::vector<Ufo*>::const_iterator uu = std::find_if(sg->getUfos()->begin(), sg->getUfos()->end(), DetectXCOMBase2(**iBase));
      if (uu != sg->getUfos()->end()) discovered[sg->locateRegion(**iBase)] = *iBase;
    }
    for (std::map<const Region *, Base *>::iterator d = discovered.begin(); d != discovered.end(); ++d) d->second->setRetaliationTarget(true);
  }
}

static bool ProcessMissionSite(Clock& g, MissionSite *site) {
  SavedGame* sg = g.save;
  bool removeSite = site->getSecondsRemaining() < 30 * 60;
  if (!removeSite) site->setSecondsRemaining(site->getSecondsRemaining() - 30 * 60);
  else removeSite = site->getFollowers()->empty();
  int score = removeSite ? site->getDeployment()->getDespawnPenalty() : site->getDeployment()->getPoints();
  Region *region = sg->locateRegion(*site);
  if (region) region->addActivityAlien(score);
  for (std::vector<Country*>::iterator k = sg->getCountries()->begin(); k != sg->getCountries()->end(); ++k) {
    if ((*k)->getRules()->insideCountry(site->getLongitude(), site->getLatitude())) { (*k)->addActivityAlien(score); break; }
  }
  if (!removeSite) return false;
  delete site;
  return true;
}

static void Time30Minutes(Clock& g) {
  SavedGame* sg = g.save;
  for (size_t m = 0; m < sg->getAlienMissions().size(); m++) sg->getAlienMissions()[m]->think(*g.game, *g.globe);
  for (std::vector<AlienMission*>::iterator am = sg->getAlienMissions().begin(); am != sg->getAlienMissions().end();) {
    if ((*am)->isOver()) { delete *am; am = sg->getAlienMissions().erase(am); } else ++am;
  }
  for (std::vector<Ufo*>::iterator u = sg->getUfos()->begin(); u != sg->getUfos()->end(); ++u) {
    if ((*u)->getStatus() == Ufo::CRASHED) {
      if ((*u)->getSecondsRemaining() >= 30 * 60) (*u)->setSecondsRemaining((*u)->getSecondsRemaining() - 30 * 60);
      else (*u)->setStatus(Ufo::DESTROYED);
    }
  }
  for (std::vector<Base*>::iterator i = sg->getBases()->begin(); i != sg->getBases()->end(); ++i) {
    for (std::vector<Craft*>::iterator j = (*i)->getCrafts()->begin(); j != (*i)->getCrafts()->end(); ++j) {
      if ((*j)->getStatus() == "STR_REFUELLING") {
        std::string s = (*j)->refuel();
        if (!s.empty()) Ev("CraftShortage|%d|%s|refuel", (*j)->getId(), s.c_str());
      }
    }
  }
  for (std::vector<Ufo*>::iterator u = sg->getUfos()->begin(); u != sg->getUfos()->end(); ++u) {
    int points = (*u)->getRules()->getMissionScore();
    switch ((*u)->getStatus()) {
    case Ufo::LANDED:
      points *= 2;
    case Ufo::FLYING:
      for (std::vector<Region*>::iterator k = sg->getRegions()->begin(); k != sg->getRegions()->end(); ++k) {
        if ((*k)->getRules()->insideRegion((*u)->getLongitude(), (*u)->getLatitude())) { (*k)->addActivityAlien(points); break; }
      }
      for (std::vector<Country*>::iterator k = sg->getCountries()->begin(); k != sg->getCountries()->end(); ++k) {
        if ((*k)->getRules()->insideCountry((*u)->getLongitude(), (*u)->getLatitude())) { (*k)->addActivityAlien(points); break; }
      }
      if (!(*u)->getDetected()) {
        bool detected = false, hyperdetected = false;
        for (std::vector<Base*>::iterator b = sg->getBases()->begin(); !hyperdetected && b != sg->getBases()->end(); ++b) {
          switch ((*b)->detect(*u)) {
          case 2:
            (*u)->setHyperDetected(true);
            hyperdetected = true;
          case 1:
            detected = true;
          }
          for (std::vector<Craft*>::iterator c = (*b)->getCrafts()->begin(); !detected && c != (*b)->getCrafts()->end(); ++c) {
            if ((*c)->getStatus() == "STR_OUT" && (*c)->detect(*u)) { detected = true; break; }
          }
        }
        if (detected) { (*u)->setDetected(true); Ev("UfoDetected|%d|%d", (*u)->getId(), (int)(*u)->getHyperDetected()); }
      } else {
        bool detected = false, hyperdetected = false;
        for (std::vector<Base*>::iterator b = sg->getBases()->begin(); !hyperdetected && b != sg->getBases()->end(); ++b) {
          switch ((*b)->insideRadarRange(*u)) {
          case 2:
            detected = true;
            hyperdetected = true;
            (*u)->setHyperDetected(true);
            break;
          case 1:
            detected = true;
            hyperdetected = (*u)->getHyperDetected();
          }
          for (std::vector<Craft*>::iterator c = (*b)->getCrafts()->begin(); !detected && c != (*b)->getCrafts()->end(); ++c) {
            if ((*c)->getStatus() == "STR_OUT" && (*c)->insideRadarRange(*u)) { detected = true; hyperdetected = (*u)->getHyperDetected(); break; }
          }
        }
        if (!detected) {
          (*u)->setDetected(false);
          (*u)->setHyperDetected(false);
          if (!(*u)->getFollowers()->empty()) Ev("UfoLost|%d", (*u)->getId());
        }
      }
      break;
    case Ufo::CRASHED:
    case Ufo::DESTROYED:
      break;
    }
  }
  for (std::vector<MissionSite*>::iterator site = sg->getMissionSites()->begin(); site != sg->getMissionSites()->end();) {
    if (ProcessMissionSite(g, *site)) site = sg->getMissionSites()->erase(site); else ++site;
  }
}

static void Time1Hour(Clock& g) {
  SavedGame* sg = g.save;
  for (std::vector<Base*>::iterator i = sg->getBases()->begin(); i != sg->getBases()->end(); ++i) {
    for (std::vector<Craft*>::iterator j = (*i)->getCrafts()->begin(); j != (*i)->getCrafts()->end(); ++j) {
      if ((*j)->getStatus() == "STR_REPAIRS") (*j)->repair();
      else if ((*j)->getStatus() == "STR_REARMING") {
        std::string s = (*j)->rearm(g.mod);
        if (!s.empty()) Ev("CraftShortage|%d|%s|rearm", (*j)->getId(), s.c_str());
      }
    }
  }
  bool window = false;
  for (std::vector<Base*>::iterator i = sg->getBases()->begin(); i != sg->getBases()->end(); ++i) {
    for (std::vector<Transfer*>::iterator j = (*i)->getTransfers()->begin(); j != (*i)->getTransfers()->end(); ++j) {
      (*j)->advance(*i);
      if (!window && (*j)->getHours() <= 0) window = true;
    }
  }
  if (window) {
    Ev("ItemsArriving");
    // ItemsArrivingState
    for (std::vector<Base*>::iterator i = sg->getBases()->begin(); i != sg->getBases()->end(); ++i) {
      for (std::vector<Transfer*>::iterator j = (*i)->getTransfers()->begin(); j != (*i)->getTransfers()->end();) {
        if ((*j)->getHours() == 0) {
          if ((*j)->getType() == TRANSFER_ITEM) {
            RuleItem *item = g.mod->getItem((*j)->getItems(), true);
            if (item->getBattleType() == BT_NONE) {
              for (std::vector<Craft*>::iterator c = (*i)->getCrafts()->begin(); c != (*i)->getCrafts()->end(); ++c) (*c)->reuseItem((*j)->getItems());
            }
          }
          delete *j;
          j = (*i)->getTransfers()->erase(j);
        } else ++j;
      }
    }
  }
  int bi = 0;
  for (std::vector<Base*>::iterator i = sg->getBases()->begin(); i != sg->getBases()->end(); ++i, ++bi) {
    std::vector<std::pair<Production*, productionProgress_e> > toRemove;
    for (std::vector<Production*>::const_iterator j = (*i)->getProductions().begin(); j != (*i)->getProductions().end(); ++j) {
      toRemove.push_back(std::make_pair(*j, (*j)->step((*i), sg, g.mod)));
    }
    for (size_t j = 0; j < toRemove.size(); j++) {
      if (toRemove[j].second > PROGRESS_NOT_COMPLETE) {
        Ev("ProductionFinished|%d|%s|%d", bi, toRemove[j].first->getRules()->getName().c_str(), (int)toRemove[j].second);
        (*i)->removeProduction(toRemove[j].first);
      }
    }
    if (Options::storageLimitsEnforced && (*i)->storesOverfull()) Ev("StorageExceeded|%d", bi);
  }
  for (std::vector<MissionSite*>::iterator i = sg->getMissionSites()->begin(); i != sg->getMissionSites()->end(); ++i) {
    if (!(*i)->getDetected()) { (*i)->setDetected(true); Ev("MissionDetected|%d", (*i)->getId()); break; }
  }
}

static void Time1Day(Clock& g) {
  SavedGame* sg = g.save;
  int bi = 0;
  for (std::vector<Base*>::iterator i = sg->getBases()->begin(); i != sg->getBases()->end(); ++i, ++bi) {
    for (std::vector<BaseFacility*>::iterator j = (*i)->getFacilities()->begin(); j != (*i)->getFacilities()->end(); ++j) {
      if ((*j)->getBuildTime() > 0) {
        (*j)->build();
        if ((*j)->getBuildTime() == 0) Ev("FacilityBuilt|%d|%s", bi, (*j)->getRules()->getType().c_str());
      }
    }
    std::vector<ResearchProject*> finished;
    for (std::vector<ResearchProject*>::const_iterator iter = (*i)->getResearch().begin(); iter != (*i)->getResearch().end(); ++iter) {
      if ((*iter)->step()) finished.push_back(*iter);
    }
    for (std::vector<ResearchProject*>::iterator iter = finished.begin(); iter != finished.end(); ++iter) {
      std::string name = (*iter)->getRules()->getName();
      (*i)->removeResearch(*iter);
      Ev("ResearchFinished|%d|%s", bi, name.c_str());
    }
    for (std::vector<Soldier*>::iterator j = (*i)->getSoldiers()->begin(); j != (*i)->getSoldiers()->end(); ++j) {
      if ((*j)->getWoundRecovery() > 0) (*j)->heal();
    }
    if ((*i)->getAvailablePsiLabs() > 0 && Options::anytimePsiTraining) {
      for (std::vector<Soldier*>::const_iterator s = (*i)->getSoldiers()->begin(); s != (*i)->getSoldiers()->end(); ++s) (*s)->trainPsi1Day();
    }
  }
  for (std::vector<AlienBase*>::const_iterator b = sg->getAlienBases()->begin(); b != sg->getAlienBases()->end(); ++b) {
    for (std::vector<Region*>::iterator k = sg->getRegions()->begin(); k != sg->getRegions()->end(); ++k) {
      if ((*k)->getRules()->insideRegion((*b)->getLongitude(), (*b)->getLatitude())) { (*k)->addActivityAlien((*b)->getDeployment()->getPoints()); break; }
    }
    for (std::vector<Country*>::iterator k = sg->getCountries()->begin(); k != sg->getCountries()->end(); ++k) {
      if ((*k)->getRules()->insideCountry((*b)->getLongitude(), (*b)->getLatitude())) { (*k)->addActivityAlien((*b)->getDeployment()->getPoints()); break; }
    }
  }
  for (std::vector<AlienBase*>::iterator ab = sg->getAlienBases()->begin(); ab != sg->getAlienBases()->end(); ++ab) {
    const AlienBase* base = *ab;
    std::string missionName = base->getDeployment()->chooseGenMissionType();
    if (g.mod->getAlienMission(missionName)) {
      if (RNG::percent(base->getDeployment()->getGenMissionFrequency())) {
        const RuleAlienMission &rule = *g.mod->getAlienMission(missionName);
        AlienMission *mission = new AlienMission(rule);
        mission->setRegion(sg->locateRegion(*base)->getRules()->getType(), *g.mod);
        mission->setId(sg->getId("ALIEN_MISSIONS"));
        mission->setRace(base->getAlienRace());
        mission->setAlienBase(base);
        mission->start();
        sg->getAlienMissions().push_back(mission);
      }
    } else if (!missionName.empty()) {
      throw Exception("Alien Base tried to generate undefined mission: " + missionName);
    }
  }
  int day = sg->getTime()->getDay();
  if (day == 10 || day == 20) {
    if (sg->isIronman()) Ev("Autosave|ironman");
    else if (Options::autosave) Ev("Autosave|auto");
  }
}

// GeoscapeState::determineAlienMissions: not copied (it is a member that reaches for the screen); the scenario that
// calls the month step uses the same function through a GeoscapeState made without a constructor
static void Tick(Clock& g) {
  TimeTrigger trigger = g.save->getTime()->advance();
  switch (trigger) {
  case TIME_1MONTH: Ev("Month");
  case TIME_1DAY: Time1Day(g);
  case TIME_1HOUR: Time1Hour(g);
  case TIME_30MIN: Time30Minutes(g);
  case TIME_10MIN: Time10Minutes(g);
  case TIME_5SEC: Time5Seconds(g);
  }
}

static void PrepareTime(Clock& g, Mod* mod, SavedGame* s, int v) {
  // the clock: day 2 at midnight, so that 20 days do not reach the end of the month
  GameTime* t = s->getTime();
  t->_second = 0; t->_minute = 0; t->_hour = 0; t->_day = 2; t->_weekday = 3;
  // the UFOs that the first saved games have with no mission and no trajectory cannot fly (the C++ crashes): removed
  for (size_t ui = 0; ui < s->getUfos()->size();) {
    Ufo* u = (*s->getUfos())[ui];
    if (u->_mission == 0 || u->_trajectory == 0) { delete u; s->getUfos()->erase(s->getUfos()->begin() + ui); } else ui++;
  }
  // the missions of the saved game have a region chosen at random: the ones that lack a zone stop, with their UFOs
  for (size_t mi = 0; mi < s->_activeMissions.size(); mi++) {
    AlienMission* m = s->_activeMissions[mi];
    if (RegionOk(mod, m->_rule, mod->getRegion(m->getRegion()))) continue;
    m->_nextWave = m->_rule.getWaveCount();
    for (size_t ui = 0; ui < s->getUfos()->size();) {
      Ufo* u = (*s->getUfos())[ui];
      if (u->_mission == m) { delete u; s->getUfos()->erase(s->getUfos()->begin() + ui); } else ui++;
    }
  }
  // new missions of every type
  const std::vector<std::string>& missions = mod->getAlienMissionList();
  const std::vector<std::string>& regions = mod->getRegionsList();
  for (size_t k = 0; k < missions.size(); k++) {
    const RuleAlienMission* rule = mod->getAlienMission(missions[k]);
    std::vector<std::string> ok;
    for (size_t r = 0; r < regions.size(); r++) {
      const RuleRegion* rr = mod->getRegion(regions[r]);
      std::string eff = rr->getMissionRegion().empty() ? regions[r] : rr->getMissionRegion();
      if (RegionOk(mod, *rule, mod->getRegion(eff))) ok.push_back(regions[r]);
    }
    if (ok.empty()) continue;
    AlienMission* m = new AlienMission(*rule);
    m->setId(s->getId("ALIEN_MISSIONS"));
    m->setRegion(ok[Pick((int)ok.size())], *mod);
    m->setRace(rule->generateRace(s->getMonthsPassed() < 0 ? 0 : s->getMonthsPassed()));
    m->start(Pick(2) == 0 ? 0 : 30 * (1 + Pick(5)));
    if (Pick(3) == 0) m->setMissionSiteZone(0);
    if (!s->getAlienBases()->empty() && Pick(2) == 0) m->setAlienBase(s->getAlienBases()->front());
    s->_activeMissions.push_back(m);
  }
  // some crafts go out: to a UFO or to a waypoint
  int bi = 0;
  for (std::vector<Base*>::iterator bp = s->getBases()->begin(); bp != s->getBases()->end(); ++bp, ++bi) {
    for (size_t ci = 0; ci < (*bp)->getCrafts()->size(); ci++) {
      Craft* c = (*(*bp)->getCrafts())[ci];
      if (Pick(3) != 0) continue;
      c->setStatus("STR_OUT");
      if (!s->getUfos()->empty() && Pick(2) == 0) {
        Ufo* u = (*s->getUfos())[Pick((int)s->getUfos()->size())];
        u->setDetected(true);
        c->setDestination(u);
      } else {
        Waypoint* w = new Waypoint();
        w->setLongitude(Pick(628) * 0.01);
        w->setLatitude((Pick(200) - 100) * 0.01);
        w->setId(s->getId("STR_WAYPOINT"));
        s->getWaypoints()->push_back(w);
        c->setDestination(w);
      }
      Ev("launch|%d|%d|%d", v, bi, (int)ci);
    }
  }
}

static void RunDays(Clock& g, int v, int days) {
  SavedGame* s = g.save;
  int day = 0;
  for (int tick = 0; tick < days * 24 * 720; tick++) {
    Tick(g);
    if (tick % (24 * 720) == 24 * 720 - 1) {
      day++;
      size_t liveUfos = s->getUfos()->size();
      fprintf(gOut, "day|%d|%d|ufos=%d|sites=%d|bases=%d|missions=%d|waypoints=%d|funds=%lld\n", v, day, (int)liveUfos,
        (int)s->getMissionSites()->size(), (int)s->getAlienBases()->size(), (int)s->_activeMissions.size(),
        (int)s->getWaypoints()->size(), (long long)s->getFunds());
    }
  }
  // the end: positions and states of the targets
  for (size_t ui = 0; ui < s->getUfos()->size(); ui++) PrintUfo(v, 0, 0, (int)ui, "final", (*s->getUfos())[ui]);
}

static Clock MakeClock(Mod* mod, SavedGame* s) {
  Clock g;
  g.game = (Game*)calloc(1, sizeof(Game));
  g.game->_save = s;
  g.game->_mod = mod;
  g.globe = (Globe*)calloc(1, sizeof(Globe));
  g.globe->_rules = mod->getGlobe();
  g.save = s;
  g.mod = mod;
  g.dogfights = 0;
  return g;
}

static void ScenarioTime(Mod* mod, SavedGame* s, int v) {
  Clock g = MakeClock(mod, s);
  PrepareTime(g, mod, s, v);
  RunDays(g, v, 20);
}

// The month: GeoscapeState::time1Month with the real determineAlienMissions (a member that only reads _game, called on a
// GeoscapeState that was never constructed), then ten days of time; three times
static void Time1Month(Clock& g, GeoscapeState* gs) {
  SavedGame* sg = g.save;
  sg->addMonth();
  gs->determineAlienMissions();
  bool psi = false;
  if (!Options::anytimePsiTraining) {
    for (std::vector<Base*>::const_iterator b = sg->getBases()->begin(); b != sg->getBases()->end(); ++b) {
      if ((*b)->getAvailablePsiLabs() > 0) {
        psi = true;
        for (std::vector<Soldier*>::const_iterator s = (*b)->getSoldiers()->begin(); s != (*b)->getSoldiers()->end(); ++s) {
          if ((*s)->isInPsiTraining()) (*s)->trainPsi();
        }
      }
    }
  }
  sg->monthlyFunding();
  Ev("MonthlyReport|%d", (int)psi);
  if (!sg->getAlienBases()->empty() && RNG::percent(20)) {
    for (std::vector<AlienBase*>::const_iterator b = sg->getAlienBases()->begin(); b != sg->getAlienBases()->end(); ++b) {
      if (!(*b)->isDiscovered()) { (*b)->setDiscovered(true); Ev("AlienBaseDiscovered"); break; }
    }
  }
}

static void ScenarioMonth(Mod* mod, SavedGame* s, int v) {
  Clock g = MakeClock(mod, s);
  GeoscapeState* gs = (GeoscapeState*)calloc(1, sizeof(GeoscapeState));
  gs->_game = g.game;
  PrepareTime(g, mod, s, v);
  for (int m = 0; m < 8; m++) {
    Time1Month(g, gs);
    fprintf(gOut, "month|%d|%d|missions=%d|funds=%lld|months=%d\n", v, m, (int)s->_activeMissions.size(), (long long)s->getFunds(), s->getMonthsPassed());
    GameTime* t = s->getTime();
    t->_second = 0; t->_minute = 0; t->_hour = 0; t->_day = 2; t->_weekday = 3;
    RunDays(g, v, 10);
  }
}

// Soldier stat strings: StatString::calcStatString on random stats with the statStrings of the mod
static void ScenarioStatString(Mod* mod, SavedGame* s, int v) {
  // the statStrings of the TFTD mod are none: the strings of the test are written here (the Delphi test has the same)
  static const char* kYaml =
  "- {string: \"P\", psiStrength: [60, 100], psiSkill: [1, 100]}\n"
  "- {string: \"!\", psiTraining: [1, 1]}\n"
  "- {string: \"+\", tu: [70, 100], strength: [40, 100]}\n"
  "- {string: \"--\", health: [0, 25], bravery: [0, 30]}\n"
  "- {string: \"-\", reactions: [0, 20]}\n"
  "- {string: \"b\", bravery: [60, 100]}\n"
  "- {string: \"s\", stamina: [70, 100]}\n"
  "- {string: \"f\", firing: [70, 100], throwing: [50, 100]}\n"
  "- {string: \"m\", melee: [80, 100]}\n"
  "- {string: \"x\", psiSkill: [1, 100]}\n"
  "- {string: \"ab\", tu: [0, 100]}\n";
  YAML::Node doc = YAML::Load(kYaml);
  std::vector<StatString*> strings;
  for (size_t i = 0; i < doc.size(); i++) { StatString* st = new StatString(); st->load(doc[i]); strings.push_back(st); }
  fprintf(gOut, "count|%d|%d\n", v, (int)strings.size());
  for (int k = 0; k < 150; k++) {
    UnitStats st;
    st.tu = Pick(90); st.stamina = Pick(90); st.health = Pick(60); st.bravery = Pick(10) * 10; st.reactions = Pick(80);
    st.firing = Pick(90); st.throwing = Pick(90); st.strength = Pick(60); st.psiStrength = Pick(100);
    st.psiSkill = Pick(3) == 0 ? 0 : Pick(70); st.melee = Pick(90);
    bool eval = Pick(2) == 0, training = Pick(3) == 0;
    std::string r = StatString::calcStatString(st, strings, eval, training);
    fprintf(gOut, "stat|%d|%d|%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d|%d|%d|%s\n", v, k, st.tu, st.stamina, st.health, st.bravery, st.reactions,
      st.firing, st.throwing, st.strength, st.psiStrength, st.psiSkill, st.melee, (int)eval, (int)training, r.c_str());
  }
}

// The research cascade: GeoscapeState::time1Day, the part about the science projects (steps 1 to 3j), with the popups
// written as ev| lines. The scenario puts projects of the topics that can be researched in the first base, one step
// from the end, and lets eight days go; the real SavedGame functions (getAvailableResearchProjects,
// addFinishedResearch, getNewlyAvailableResearchProjects, getDependableManufacture) and the real RNG do the work.
static std::string Names(const std::vector<RuleResearch*>& v) {
  std::string r;
  for (size_t i = 0; i < v.size(); i++) { if (i) r += ","; r += v[i]->getName(); }
  return r;
}

static void ResearchDay(Mod* mod, SavedGame* sg, Base* base, int bi) {
  std::vector<ResearchProject*> finished;
  for (std::vector<ResearchProject*>::const_iterator iter = base->getResearch().begin(); iter != base->getResearch().end(); ++iter) {
    if ((*iter)->step()) finished.push_back(*iter);
  }
  std::vector<RuleResearch*> before;
  if (!finished.empty()) sg->getAvailableResearchProjects(before, mod, base);
  for (std::vector<ResearchProject*>::iterator iter = finished.begin(); iter != finished.end(); ++iter) {
    const RuleResearch* bonus = 0;
    const RuleResearch* research = (*iter)->getRules();
    base->removeResearch(*iter);
    (*iter) = 0;
    if (!research->getGetOneFree().empty()) {
      std::vector<std::string> possibilities;
      for (std::vector<std::string>::const_iterator f = research->getGetOneFree().begin(); f != research->getGetOneFree().end(); ++f) {
        if (!sg->isResearched(*f, false)) possibilities.push_back(*f);
      }
      if (!possibilities.empty()) {
        size_t pick = RNG::generate(0, possibilities.size() - 1);
        std::string sel = possibilities.at(pick);
        bonus = mod->getResearch(sel, true);
        sg->addFinishedResearch(bonus, mod, base);
        if (!bonus->getLookup().empty()) sg->addFinishedResearch(mod->getResearch(bonus->getLookup(), true), mod, base);
      }
    }
    const RuleResearch* newResearch = research;
    std::string name = research->getLookup().empty() ? research->getName() : research->getLookup();
    if (sg->isResearched(name, false)) newResearch = 0;
    sg->addFinishedResearch(research, mod, base);
    if (!research->getLookup().empty()) sg->addFinishedResearch(mod->getResearch(research->getLookup(), true), mod, base);
    std::string weapon;
    if (newResearch) {
      RuleItem* item = mod->getItem(newResearch->getName());
      if (item && item->getBattleType() == BT_FIREARM && !item->getCompatibleAmmo()->empty()) {
        RuleManufacture* man = mod->getManufacture(item->getType());
        if (man && !man->getRequirements().empty()) {
          const std::vector<std::string>& req = man->getRequirements();
          RuleItem* ammo = mod->getItem(item->getCompatibleAmmo()->front());
          if (ammo && std::find(req.begin(), req.end(), ammo->getType()) != req.end() && !sg->isResearched(req, true)) weapon = item->getType();
        }
      }
    }
    std::vector<RuleResearch*> after;
    sg->getAvailableResearchProjects(after, mod, base);
    std::vector<RuleResearch*> newPossibleResearch;
    sg->getNewlyAvailableResearchProjects(before, after, newPossibleResearch);
    std::vector<RuleManufacture*> newPossibleManufacture;
    sg->getDependableManufacture(newPossibleManufacture, research, mod, base);
    std::string manufacture;
    for (size_t m = 0; m < newPossibleManufacture.size(); m++) { if (m) manufacture += ","; manufacture += newPossibleManufacture[m]->getName(); }
    Ev("research|%d|%s|bonus=%s|new=%s|weapon=%s|possible=%s|manufacture=%s", bi, research->getName().c_str(),
      bonus ? bonus->getName().c_str() : "", newResearch ? newResearch->getName().c_str() : "", weapon.c_str(),
      Names(newPossibleResearch).c_str(), manufacture.c_str());
    for (std::vector<Base*>::iterator j = sg->getBases()->begin(); j != sg->getBases()->end(); ++j) {
      for (std::vector<ResearchProject*>::const_iterator iter2 = (*j)->getResearch().begin(); iter2 != (*j)->getResearch().end(); ++iter2) {
        if (research->getName() == (*iter2)->getRules()->getName()) {
          if (!sg->isResearched(research->getGetOneFree(), false)) {
          } else if (sg->hasUndiscoveredProtectedUnlock(research, mod)) {
          } else {
            (*j)->removeResearch(*iter2);
            break;
          }
        }
      }
    }
  }
}

static void ScenarioResearch(Mod* mod, SavedGame* s, int v) {
  if (s->getBases()->empty()) return;
  Base* base = s->getBases()->front();
  for (int round = 0; round < 12; round++) {
    std::vector<RuleResearch*> avail;
    s->getAvailableResearchProjects(avail, mod, base);
    fprintf(gOut, "avail|%d|%d|%s\n", v, round, Names(avail).c_str());
    std::vector<RuleManufacture*> prod;
    s->getAvailableProductions(prod, mod, base);
    fprintf(gOut, "productions|%d|%d|%d\n", v, round, (int)prod.size());
    int added = 0;
    while (added < 3 && !avail.empty()) {
      size_t pick = Pick((int)avail.size());
      RuleResearch* r = avail[pick];
      avail.erase(avail.begin() + pick);
      // the topics with "requires" are not shown to the player
      if (!r->getRequirements().empty()) continue;
      ResearchProject* p = new ResearchProject(r, r->getCost());
      p->setAssigned(1);
      p->setSpent(r->getCost());
      base->addResearch(p);
      added++;
    }
    ResearchDay(mod, s, base, 0);
    fprintf(gOut, "day|%d|%d|discovered=%d|popped=%d|score=%d\n", v, round, (int)s->getDiscoveredResearch().size(),
      (int)s->_poppedResearch.size(), s->_researchScores.back());
  }
}

// The monthly report: MonthlyReportState::calculateChanges and the part of its constructor that judges the rating (the
// state needs a screen: the code is copied, with the text written as the key of the language). The scenario gives
// every region and country some activity, some research score and a random amount of funds, closes the month (the real
// addMonth and monthlyFunding) and lets the council judge; six months
static std::string Join(const std::vector<std::string>& v) {
  std::string r;
  for (size_t i = 0; i < v.size(); i++) { if (i) r += ","; r += v[i]; }
  return r;
}

static void ScenarioReport(Mod* mod, SavedGame* s, int v) {
  // the UFOs that the first saved games have with no mission and no trajectory cannot be saved after a month (the C++
  // crashes): removed, as the scenarios of the time do
  for (size_t ui = 0; ui < s->getUfos()->size();) {
    Ufo* u = (*s->getUfos())[ui];
    if (u->_mission == 0 || u->_trajectory == 0) { delete u; s->getUfos()->erase(s->getUfos()->begin() + ui); } else ui++;
  }
  for (int month = 0; month < 6; month++) {
    for (std::vector<Region*>::iterator k = s->getRegions()->begin(); k != s->getRegions()->end(); ++k) {
      (*k)->addActivityAlien(Pick(400));
      (*k)->addActivityXcom(Pick(400));
    }
    for (std::vector<Country*>::iterator k = s->getCountries()->begin(); k != s->getCountries()->end(); ++k) {
      (*k)->addActivityAlien(Pick(300));
      (*k)->addActivityXcom(Pick(300));
    }
    if (Pick(2) == 0) s->addResearchScore(Pick(300));
    s->addMonth();
    s->monthlyFunding();
    s->setFunds((int64_t)(Pick(7) - 3) * 1000000 + Pick(1000));
    // calculateChanges
    int lastMonthsRating = 0, xcomSubTotal = 0, xcomTotal = 0, alienTotal = 0, fundingDiff = 0;
    std::vector<std::string> happyList, sadList, pactList;
    int monthOffset = s->getFundsList().size() - 2;
    int lastMonthOffset = s->getFundsList().size() - 3;
    if (lastMonthOffset < 0) lastMonthOffset += 2;
    for (std::vector<Region*>::iterator k = s->getRegions()->begin(); k != s->getRegions()->end(); ++k) {
      (*k)->newMonth();
      if ((*k)->getActivityXcom().size() > 2)
        lastMonthsRating += (*k)->getActivityXcom().at(lastMonthOffset) - (*k)->getActivityAlien().at(lastMonthOffset);
      xcomSubTotal += (*k)->getActivityXcom().at(monthOffset);
      alienTotal += (*k)->getActivityAlien().at(monthOffset);
    }
    if (s->getMonthsPassed() > 1) s->getResearchScores().at(monthOffset) += 400;
    xcomTotal = s->getResearchScores().at(monthOffset) + xcomSubTotal;
    if (s->getResearchScores().size() > 2) lastMonthsRating += s->getResearchScores().at(lastMonthOffset);
    const RuleAlienMission* infiltration = mod->getRandomMission(OBJECTIVE_INFILTRATION, s->getMonthsPassed());
    int pactScore = 0;
    if (infiltration) pactScore = infiltration->getPoints();
    for (std::vector<Country*>::iterator k = s->getCountries()->begin(); k != s->getCountries()->end(); ++k) {
      if ((*k)->getNewPact()) pactList.push_back((*k)->getRules()->getType());
      (*k)->newMonth(xcomTotal, alienTotal, pactScore);
      fundingDiff += (*k)->getFunding().back() - (*k)->getFunding().at((*k)->getFunding().size() - 2);
      switch ((*k)->getSatisfaction()) {
      case 1: sadList.push_back((*k)->getRules()->getType()); break;
      case 3: happyList.push_back((*k)->getRules()->getType()); break;
      default: break;
      }
    }
    int ratingTotal = xcomTotal - alienTotal;
    // the constructor
    int threshold = mod->getDefeatScore() + 100 * s->getDifficultyCoefficient();
    std::string rating = "STR_RATING_TERRIBLE";
    if (ratingTotal > threshold - 300) rating = "STR_RATING_POOR";
    if (ratingTotal > threshold) rating = "STR_RATING_OK";
    if (ratingTotal > 0) rating = "STR_RATING_GOOD";
    if (ratingTotal > 500) rating = "STR_RATING_EXCELLENT";
    std::string satisfaction = "STR_COUNCIL_IS_DISSATISFIED";
    bool resetWarning = true, gameOver = false, debts = false;
    if (ratingTotal > threshold) satisfaction = "STR_COUNCIL_IS_GENERALLY_SATISFIED";
    if (ratingTotal > 500) satisfaction = "STR_COUNCIL_IS_VERY_PLEASED";
    if (lastMonthsRating <= threshold && ratingTotal <= threshold) {
      satisfaction = "STR_YOU_HAVE_NOT_SUCCEEDED";
      pactList.clear(); happyList.clear(); sadList.clear();
      gameOver = true;
    }
    if (!gameOver) {
      if (s->getFunds() <= mod->getDefeatFunds()) {
        if (s->getWarned()) {
          satisfaction = "STR_YOU_HAVE_NOT_SUCCEEDED";
          pactList.clear(); happyList.clear(); sadList.clear();
          gameOver = true;
        } else {
          debts = true;
          s->setWarned(true);
          resetWarning = false;
        }
      }
    }
    if (resetWarning && s->getWarned()) s->setWarned(false);
    fprintf(gOut, "report|%d|%d|rating=%d|last=%d|diff=%d|%s|%s|debts=%d|over=%d|income=%d|maintenance=%d|funds=%lld|happy=%s|sad=%s|pact=%s|infiltration=%s\n",
      v, month, ratingTotal, lastMonthsRating, fundingDiff, rating.c_str(), satisfaction.c_str(), (int)debts, (int)gameOver,
      s->getCountryFunding(), (int)s->getBaseMaintenance(), (long long)s->getFunds(), Join(happyList).c_str(), Join(sadList).c_str(),
      Join(pactList).c_str(), infiltration ? infiltration->getType().c_str() : "");
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
      else if (scenario == "time") ScenarioTime(mod, s, v);
      else if (scenario == "month") ScenarioMonth(mod, s, v);
      else if (scenario == "statstring") ScenarioStatString(mod, s, v);
      else if (scenario == "research") ScenarioResearch(mod, s, v);
      else if (scenario == "report") ScenarioReport(mod, s, v);
      else if (scenario == "time") ScenarioTime(mod, s, v);
      else if (scenario == "month") ScenarioMonth(mod, s, v);
      else if (scenario == "statstring") ScenarioStatString(mod, s, v);
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
