// Harness for Libs\XcomBattle (BattlescapeGenerator): runs the REAL BattlescapeGenerator (linked from the real OpenXcom
// build, see build.cmd) on the real TFTD mods and writes, for every scenario,
//   genNN.sav  the saved game just before the run (SavedGame::save: base, soldiers, craft, items)
//   genNN.scn  the parameters of the run (key=value lines) and the RNG state before and after it
//   genNN.yml  what SavedBattleGame::save writes after BattlescapeGenerator::run
//   genNN.err  (instead of .yml) the message of the Exception that run threw, when it threw
// The Game that the generator asks for the saved game and the mod is a block of zeroed memory with only those two
// fields set: the generator reads nothing else of it. Contains no OpenXcom code.
// usage: gengen <data folder> <user folder> <output folder> <count> <seed> [first]
#include <yaml-cpp/yaml.h>
#include <utility>
#include <cstdio>
#include <cstdlib>
#include <cstring>
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
#include "Mod/MapDataSet.h"
#include "Mod/RuleItem.h"
#include "Mod/RuleCraft.h"
#include "Mod/RuleUfo.h"
#include "Mod/RuleGlobe.h"
#include "Mod/Texture.h"
#include "Mod/AlienDeployment.h"
#include "Mod/AlienRace.h"
#include "Mod/RuleTerrain.h"
#include "Savegame/SavedGame.h"
#include "Savegame/SavedBattleGame.h"
#include "Savegame/Base.h"
#include "Savegame/Craft.h"
#include "Savegame/Ufo.h"
#include "Savegame/Vehicle.h"
#include "Savegame/Soldier.h"
#include "Savegame/Tile.h"
#include "Savegame/Node.h"
#include "Savegame/BattleUnit.h"
#include "Savegame/BattleItem.h"
#include "Mod/MapData.h"
#include "Savegame/ItemContainer.h"
#include "Battlescape/BattlescapeGenerator.h"
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

static void WriteNode(const std::string& path, const YAML::Node& node) {
  YAML::Emitter out;
  out << node;
  std::ofstream o(path.c_str(), std::ios::binary);
  o << out.c_str();
}

static void WriteText(const std::string& path, const std::string& text) {
  std::ofstream o(path.c_str(), std::ios::binary);
  o << text;
}

// what loadMapResources does without initUtilities and the tile engine
static void LoadMapResourcesNoEngine(Mod* mod, SavedBattleGame* b) {
  for (std::vector<MapDataSet*>::const_iterator i = b->_mapDataSets.begin(); i != b->_mapDataSets.end(); ++i)
    (*i)->loadData(mod->getMCDPatch((*i)->getName()));
  int mdsID, mdID;
  for (int i = 0; i < b->_mapsize_z * b->_mapsize_y * b->_mapsize_x; ++i) {
    for (int part = O_FLOOR; part <= O_OBJECT; part++) {
      TilePart tp = (TilePart)part;
      b->_tiles[i]->getMapData(&mdID, &mdsID, tp);
      if (mdID != -1 && mdsID != -1) b->_tiles[i]->setMapData(b->_mapDataSets[mdsID]->getObject(mdID), mdID, mdsID, tp);
    }
  }
}

template <class T>
static std::vector<std::string> Keys(const std::map<std::string, T>& m) {
  std::vector<std::string> r;
  for (typename std::map<std::string, T>::const_iterator i = m.begin(); i != m.end(); ++i) r.push_back(i->first);
  return r;
}

int main(int argc, char** argv) {
  if (argc < 6) { fprintf(stderr, "usage: gengen <data> <user> <out folder> <count> <seed>\n"); return 2; }
  std::string data = argv[1], user = argv[2], out = argv[3];
  int count = atoi(argv[4]);
  uint64_t seed = (uint64_t)atoll(argv[5]);
  int first = argc > 6 ? atoi(argv[6]) : 0;  // the scenario to start from (a crash of the real generator on one scenario loses only that one)
  static char a0[] = "gengen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
  std::string cfg = user;
  char* args[] = {a0, a1, (char*)data.c_str(), a3, (char*)user.c_str(), a5, (char*)cfg.c_str()};
  Logger::reportingLevel() = LOG_ERROR;
  if (!Options::init(7, args)) return 3;
  int errors = 0;
  try {
    Options::updateMods();
    Mod::resetGlobalStatics();
    Mod* mod = new Mod();
    mod->loadAll(FileMap::getRulesets());
    std::string folder = Options::getMasterUserFolder();
    std::vector<std::string> deployments = Keys(mod->_alienDeployments);
    std::vector<std::string> races = Keys(mod->_alienRaces);
    std::vector<std::string> ufos = Keys(mod->_ufos);
    std::vector<std::string> terrains = Keys(mod->_terrains);
    std::vector<std::string> items;
    for (std::map<std::string, RuleItem*>::iterator i = mod->_items.begin(); i != mod->_items.end(); ++i) {
      BattleType t = i->second->getBattleType();
      if ((t == BT_FIREARM || t == BT_AMMO || t == BT_GRENADE || t == BT_MEDIKIT || t == BT_MELEE || t == BT_FLARE) && i->second->getBigSprite() > -1) items.push_back(i->first);
    }
    std::vector<int> textures;
    for (std::map<int, Texture*>::iterator i = mod->getGlobe()->_textures.begin(); i != mod->getGlobe()->_textures.end(); ++i) textures.push_back(i->first);
    for (int v = first; v < first + count; v++) {
      RNG::setSeed(seed + v);
      SavedGame* s = mod->newSave();
      s->setDifficulty((GameDifficulty)Pick(5));
      SavedBattleGame* b = new SavedBattleGame();
      Base* base = s->getBases()->front();
      Craft* craft = 0;
      Ufo* ufo = 0;
      std::ostringstream scn;
      int kind = v % 5;  // 0 no craft, 1 craft on a terrain mission, 2 craft and ufo, 3 base defense, 4 ufo without craft
      std::string mission = deployments[Pick(deployments.size())];
      if (kind == 3) mission = "STR_BASE_DEFENSE";
      if ((kind == 1 || kind == 2) && !base->getCrafts()->empty()) craft = base->getCrafts()->front();
      if (kind == 2 || kind == 4) {
        // a ufo: its type is the deployment
        std::string ut = ufos[Pick(ufos.size())];
        ufo = new Ufo(mod->getUfo(ut));
        ufo->setLongitude((Pick(3600) / 3600.0 - 0.5) * 6.2831853);
        ufo->setLatitude((Pick(1800) / 1800.0 - 0.5) * 3.1415926);
        ufo->setStatus(Pick(2) ? Ufo::CRASHED : Ufo::LANDED);
        mission = ut;
      }
      b->setMissionType(mission);
      // soldiers into the craft, items in the craft (and in every craft of the base for the new battle)
      if (craft) {
        int n = 1 + Pick(8);
        std::vector<Soldier*>* sol = base->getSoldiers();
        for (size_t i = 0; i < sol->size() && (int)i < n; i++) (*sol)[i]->setCraft(craft);
      }
      std::vector<Craft*> allCrafts = *base->getCrafts();
      for (size_t c = 0; c < allCrafts.size(); c++) {
        int ni = 3 + Pick(10);
        for (int k = 0; k < ni && !items.empty(); k++) {
          std::string it = items[Pick(items.size())];
          allCrafts[c]->getItems()->addItem(it, 1 + Pick(3));
          RuleItem* r = mod->getItem(it);
          if (!r->getCompatibleAmmo()->empty()) allCrafts[c]->getItems()->addItem(r->getCompatibleAmmo()->front(), 1 + Pick(3));
        }
      }
      char name[64];
      snprintf(name, sizeof name, "gen%02d", v);
      std::string basePath = out + "/" + name;
      s->save(std::string(name) + ".sav");
      {
        std::string from = folder + name + ".sav";
        std::ifstream in(from.c_str(), std::ios::binary);
        std::ofstream o((basePath + ".sav").c_str(), std::ios::binary);
        o << in.rdbuf();
      }
      s->setBattleGame(b);  // after the save: the saved game of the test has no battle yet
      Game* game = (Game*)calloc(1, sizeof(Game));
      game->_save = s;
      game->_mod = mod;
      BattlescapeGenerator gen(game);
      if (craft) gen.setCraft(craft);
      if (!craft) gen.setBase(base);
      if (ufo) gen.setUfo(ufo);
      std::string race = races[Pick(races.size())];
      gen.setAlienRace(race);
      int itemLevel = Pick(10);
      gen.setAlienItemlevel(itemLevel);
      int shade = Pick(16);
      gen.setWorldShade(shade);
      int texture = -1;
      std::string terrain;
      AlienDeployment* rd = mod->getDeployment(mission, true);
      if (rd->getTerrains().empty()) {
        if (ufo && Pick(2)) {
          texture = textures[Pick(textures.size())];
          gen.setWorldTexture(mod->getGlobe()->getTexture(texture));
        } else {
          terrain = terrains[Pick(terrains.size())];
          gen.setTerrain(mod->getTerrain(terrain, true));
        }
      }
      uint64_t runSeed = seed * 1000 + v;
      RNG::setSeed(runSeed);
      srand((unsigned)runSeed);  // the colors of the units use rand(): the port reproduces the generator of the C library
      scn << "mission=" << mission << "\nkind=" << kind << "\nrace=" << race << "\nitemlevel=" << itemLevel << "\nshade=" << shade
          << "\ntexture=" << texture << "\nterrain=" << terrain << "\ncraft=" << (craft ? 1 : 0) << "\nbase=" << (!craft ? 1 : 0) << "\n";
      if (ufo) scn << "ufo=" << ufo->getRules()->getType() << "\nufostatus=" << (int)ufo->getStatus() << "\nuforlon=" << ufo->getLongitude() << "\nuforlat=" << ufo->getLatitude() << "\n";
      scn << "runseed=" << runSeed << "\n";
      bool ok = true;
      try {
        gen.run();
      } catch (Exception& e) {
        ok = false;
        errors++;
        WriteText(basePath + ".err", e.what());
      }
      if (ok) {
        // the order of the memory addresses of the tiles: explode keeps the tiles it reached in a std::set<Tile*>
        std::vector<std::pair<uintptr_t, int> > byAddress;
        for (int i = 0; i < b->getMapSizeXYZ(); i++) byAddress.push_back(std::make_pair((uintptr_t)b->_tiles[i], i));
        std::sort(byAddress.begin(), byAddress.end());
        scn << "tileorder=";
        for (size_t i = 0; i < byAddress.size(); i++) scn << (i ? "," : "") << byAddress[i].second;
        scn << "\n";
      }
      scn << "seedafter=" << RNG::getSeed() << "\nok=" << (ok ? 1 : 0) << "\n";
      WriteText(basePath + ".scn", scn.str());
      if (ok) WriteNode(basePath + ".yml", b->save());
      if (ok) {
        // the saved game in the battle (SavedGame::save has the battleGame) and the real load and save of it
        std::string after = std::string(name) + "a.sav";
        s->save(after);
        {
          std::string from = folder + after;
          std::ifstream in(from.c_str(), std::ios::binary);
          std::ofstream o((basePath + ".after.sav").c_str(), std::ios::binary);
          o << in.rdbuf();
        }
        SavedBattleGame* c = new SavedBattleGame();
        c->load(b->save(), mod, s);
        LoadMapResourcesNoEngine(mod, c);
        WriteNode(basePath + ".re.yml", c->save());
        delete c;
      }
      free(game);
    }
  } catch (Exception& e) {
    fprintf(stderr, "EXCEPTION: %s\n", e.what());
    return 1;
  }
  fprintf(stderr, "ok (%d scenarios threw)\n", errors);
  return 0;
}
