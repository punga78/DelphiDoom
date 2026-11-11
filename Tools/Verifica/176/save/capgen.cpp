// Harness for Libs\XcomSave (the capacities of a base): runs the REAL OpenXcom objects (linked from a real build, see
// build5.cmd): Mod::loadAll on the real TFTD mods, SavedGame::load of every saveNN.sav of Tests\Data\XcomSave\realsave
// and prints, for every base, what Base::getAvailableXxx/getUsedXxx/getXxxMaintenance... answer.
// Contains no OpenXcom code; the output goes in Tests\Data\XcomSave\capacity.golden.txt.
// usage: capgen <data folder> <user folder> <folder with the saves> <count>
#include <yaml-cpp/yaml.h>
#include <utility>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <sstream>
#define private public
#define protected public
#include "Mod/Mod.h"
#include "Savegame/SavedGame.h"
#include "Savegame/Base.h"
#include "Savegame/Craft.h"
#include "Savegame/BaseFacility.h"
#include "Savegame/Soldier.h"
#include "Savegame/Transfer.h"
#include "Savegame/ItemContainer.h"
#include "Savegame/Production.h"
#include "Savegame/ResearchProject.h"
#include "Mod/RuleBaseFacility.h"
#include "Engine/Options.h"
#include "Engine/Logger.h"
#include "Engine/FileMap.h"
#include "Engine/Exception.h"
#include "Engine/CrossPlatform.h"
#undef main
using namespace OpenXcom;

int main(int argc, char** argv) {
  if (argc < 5) { fprintf(stderr, "usage: capgen <data> <user> <saves folder> <count>\n"); return 2; }
  std::string data = argv[1], user = argv[2], saves = argv[3];
  int count = atoi(argv[4]);
  static char a0[] = "capgen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
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
      char name[64];
      snprintf(name, sizeof name, "save%02d.sav", v);
      {
        std::ifstream in((saves + "/" + name).c_str(), std::ios::binary);
        std::ofstream o((folder + name).c_str(), std::ios::binary);
        o << in.rdbuf();
      }
      SavedGame* s = new SavedGame();
      s->load(name, mod);
      printf("save|%d|bases=%d|maintenance=%lld\n", v, (int)s->getBases()->size(), (long long)s->getBaseMaintenance());
      int b = 0;
      for (std::vector<Base*>::iterator i = s->getBases()->begin(); i != s->getBases()->end(); ++i, ++b) {
        Base* base = *i;
        printf("base|%d|%d|soldiers=%d,%d,%d,%d|scientists=%d,%d,%d|engineers=%d,%d,%d|quarters=%d,%d\n", v, b,
          base->getAvailableSoldiers(false), base->getAvailableSoldiers(true), base->getTotalSoldiers(), (int)base->getSoldiers()->size(),
          base->getAvailableScientists(), base->getTotalScientists(), base->getScientists(),
          base->getAvailableEngineers(), base->getTotalEngineers(), base->getEngineers(),
          base->getUsedQuarters(), base->getAvailableQuarters());
        printf("base|%d|%d|stores=%.17g,%d,%.17g,%d|laboratories=%d,%d,%d|workshops=%d,%d,%d|hangars=%d,%d\n", v, b,
          base->getUsedStores(), base->getAvailableStores(), base->getIgnoredStores(), (int)base->storesOverfull(0),
          base->getUsedLaboratories(), base->getAvailableLaboratories(), base->getFreeLaboratories(),
          base->getUsedWorkshops(), base->getAvailableWorkshops(), base->getFreeWorkshops(),
          base->getUsedHangars(), base->getAvailableHangars());
        printf("base|%d|%d|psi=%d,%d|containment=%d,%d|defense=%d|gravs=%d|detection=%d\n", v, b,
          base->getUsedPsiLabs(), base->getAvailablePsiLabs(), base->getUsedContainment(), base->getAvailableContainment(),
          base->getDefenseValue(), base->getGravShields(), (int)base->getDetectionChance());
        printf("base|%d|%d|maintenance=%d,%d,%d,%d\n", v, b, base->getCraftMaintenance(), base->getPersonnelMaintenance(),
          base->getFacilityMaintenance(), base->getMonthlyMaintenace());
      }
      delete s;
    }
  } catch (Exception& e) {
    fprintf(stderr, "EXCEPTION: %s\n", e.what());
    return 1;
  }
  return 0;
}
