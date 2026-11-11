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
