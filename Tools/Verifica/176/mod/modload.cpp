// Harness for Libs\XcomMod (Mod::loadAll): runs the REAL OpenXcom Mod loader (linked from the objects of a real
// OpenXcom build, see build3.cmd) on a real mod set and dumps what the ruleset holds as text lines
// "section|name|field=value". Contains no OpenXcom code; the output goes in Tests\Data\XcomMod\*.golden.txt.
// usage: modload <data folder> <user folder> <output file> [section ...]   (the mods come from options.cfg)
#include <yaml-cpp/yaml.h>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <map>
#include <set>
#include <sstream>
#include <vector>
#include <string>
#include <algorithm>
#include <memory>
#include <utility>
#define private public
#define protected public
#include "Mod/Mod.h"
#include "Mod/SoundDefinition.h"
#include "Mod/RuleCountry.h"
#include "Mod/RuleRegion.h"
#include "Mod/RuleInventory.h"
#include "Mod/RuleResearch.h"
#include "Mod/RuleManufacture.h"
#include "Mod/AlienRace.h"
#include "Mod/UfoTrajectory.h"
#include "Mod/RuleMusic.h"
#include "Mod/RuleCommendations.h"
#include "Mod/RuleCraftWeapon.h"
#include "Mod/RuleItem.h"
#include "Mod/RuleCraft.h"
#include "Mod/RuleBaseFacility.h"
#include "Mod/RuleSoldier.h"
#include "Mod/Armor.h"
#include "Mod/RuleUfo.h"
#include "Mod/RuleTerrain.h"
#include "Mod/RuleAlienMission.h"
#include "Mod/RuleInterface.h"
#include "Mod/RuleVideo.h"
#include "Mod/RuleMissionScript.h"
#include "Mod/MapDataSet.h"
#include "Mod/MapData.h"
#include "Mod/MapScript.h"
#include "Battlescape/Position.h"
#include "Mod/MapBlock.h"
#include "Engine/RNG.h"
#include "Mod/Unit.h"
#include "Mod/SoldierNamePool.h"
#include "Mod/AlienDeployment.h"
#include "Mod/ExtraSprites.h"
#include "Mod/ExtraSounds.h"
#include "Mod/ExtraStrings.h"
#include "Mod/StatString.h"
#include "Mod/StatStringCondition.h"
#include "Mod/MCDPatch.h"
#include "Mod/RuleGlobe.h"
#include "Mod/Polygon.h"
#include "Mod/Polyline.h"
#include "Mod/Texture.h"
#include "Geoscape/Globe.h"
#include "Mod/RuleConverter.h"
#include "Mod/Polygon.h"
#include "Mod/Polyline.h"
#include "Mod/Texture.h"
#include "Mod/City.h"
#include "Mod/ArticleDefinition.h"
#include "Savegame/WeightedOptions.h"
#include "Savegame/GameTime.h"
#include "Engine/Options.h"
#include "Engine/FileMap.h"
#include "Engine/Logger.h"
#include "Engine/Exception.h"
#include "Engine/SurfaceSet.h"
#include "Engine/Surface.h"
#include "Engine/Sound.h"
#include "Engine/SoundSet.h"
#include "Engine/CrossPlatform.h"
#undef protected
#undef private
#undef main

using namespace OpenXcom;

#include "dump_common.h"
#include "dump_rules.h"

int main(int argc, char** argv) {
  if (argc < 4) { fprintf(stderr, "usage: modload <data> <user> <out> [sections...]\n"); return 2; }
  std::string data = argv[1], user = argv[2], outName = argv[3];
  std::set<std::string> only;
  for (int i = 4; i < argc; i++) only.insert(argv[i]);
  static char a0[] = "modload", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
  std::string cfg = user;
  char* args[] = {a0, a1, (char*)data.c_str(), a3, (char*)user.c_str(), a5, (char*)cfg.c_str()};
  Logger::reportingLevel() = LOG_INFO;
  if (!Options::init(7, args)) return 3;
  try {
    Options::updateMods();
    Mod::resetGlobalStatics();
    Mod* mod = new Mod();
    mod->loadAll(FileMap::getRulesets());
    FILE* f = fopen(outName.c_str(), "wb");
    gOut = f;
    // the files of every mod, relative to the data folder (or the user folder), in load order
    {
      std::vector<std::pair<std::string, std::vector<std::string> > > rs = FileMap::getRulesets();
      for (size_t i = 0; i < rs.size(); i++) {
        Begin("files", rs[i].first);
        std::vector<std::string> rel;
        for (size_t j = 0; j < rs[i].second.size(); j++) {
          std::string p = rs[i].second[j];
          std::replace(p.begin(), p.end(), '\\', '/');
          for (const std::string& root : {data, user}) {
            std::string q = root;
            std::replace(q.begin(), q.end(), '\\', '/');
            if (!q.empty() && q.back() != '/') q += "/";
            if (p.compare(0, q.size(), q) == 0) { p = p.substr(q.size()); break; }
          }
          rel.push_back(p);
        }
        F("list", rel);
      }
    }
    DumpAll(mod, only);
    fclose(f);
  } catch (Exception& e) {
    fprintf(stderr, "EXCEPTION: %s\n", e.what());
    return 1;
  }
  fprintf(stderr, "ok\n");
  return 0;
}
