// Harness for Libs\XcomBattle (Pathfinding): the REAL OpenXcom objects (linked from a real build, see build.cmd) build
// maps of tiles with the real MCD parts picked by type (floors, walls, objects), put units of the real rules on them and
// answer path questions with the real Pathfinding. Writes
//   <name>.yml     the SavedBattleGame of the map (what SavedBattleGame::save writes)
//   <name>.txt     one line per question with the answer of the real Pathfinding
// Contains no OpenXcom code; the output goes in Tests\Data\XcomBattle\path.
// usage: pathgen <data folder> <user folder> <output folder> <count> <seed>
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
#include "Mod/MapDataSet.h"
#include "Mod/MapData.h"
#include "Mod/Unit.h"
#include "Mod/Armor.h"
#include "Savegame/SavedGame.h"
#include "Savegame/SavedBattleGame.h"
#include "Savegame/Tile.h"
#include "Savegame/BattleUnit.h"
#include "Savegame/BattleUnitStatistics.h"
#include "Battlescape/Pathfinding.h"
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

static void BuildMap(Mod* mod, SavedGame* s, SavedBattleGame* b, std::vector<BattleUnit*>& units) {
  int sx = 10 * (1 + Pick(2)), sy = 10 * (1 + Pick(2)), sz = 1 + Pick(3);
  b->initMap(sx, sy, sz);
  b->setMissionType("STR_TERROR_MISSION");
  b->_depth = Pick(2) ? 0 : 1 + Pick(3);
  std::vector<std::string> names;
  for (std::map<std::string, MapDataSet*>::iterator i = mod->_mapDataSets.begin(); i != mod->_mapDataSets.end(); ++i) names.push_back(i->first);
  // parts by type over two sets
  std::vector<std::vector<std::pair<int, int> > > parts(4);  // (set index, part index) by object type
  for (int k = 0; k < 2; k++) {
    std::string n = names[Pick(names.size())];
    MapDataSet* mds = mod->getMapDataSet(n);
    if (std::find(b->_mapDataSets.begin(), b->_mapDataSets.end(), mds) != b->_mapDataSets.end()) continue;
    mds->loadData(mod->getMCDPatch(n));
    int idx = b->_mapDataSets.size();
    b->_mapDataSets.push_back(mds);
    for (size_t i = 0; i < mds->getSize(); i++) {
      int t = (int)mds->getObject(i)->getObjectType();
      if (t >= 0 && t < 4) parts[t].push_back(std::make_pair(idx, (int)i));
    }
  }
  int wallDensity = 5 + Pick(30), objDensity = 5 + Pick(30), upperFloor = 20 + Pick(70);
  for (int i = 0; i < b->getMapSizeXYZ(); i++) {
    Tile* t = b->_tiles[i];
    int z = t->getPosition().z;
    for (int part = 0; part < 4; part++) {
      int density = part == 0 ? (z == 0 ? 100 : upperFloor) : (part == 3 ? objDensity : wallDensity);
      if (Pick(100) < density && !parts[part].empty()) {
        std::pair<int, int> p = parts[part][Pick(parts[part].size())];
        MapDataSet* mds = b->_mapDataSets[p.first];
        t->setMapData(mds->getObject(p.second), p.second, p.first, (TilePart)part);
      }
    }
    if (Pick(40) == 0) t->_fire = 1 + Pick(5);
    if (Pick(40) == 0) t->_smoke = 1 + Pick(10);
    // a tile with fire and no smoke is "void" and is not saved (the game always has smoke with fire)
    if (t->_fire > 0 && t->_smoke == 0) t->_smoke = 1 + Pick(10);
    if (Pick(20) == 0) t->_currentFrame[1] = 7;
    if (Pick(20) == 0) t->_currentFrame[2] = 7;
  }
  std::vector<std::string> unitNames;
  for (std::map<std::string, Unit*>::iterator i = mod->_units.begin(); i != mod->_units.end(); ++i) unitNames.push_back(i->first);
  int nu = 2 + Pick(5);
  for (int i = 0; i < nu; i++) {
    Unit* ur = mod->getUnit(unitNames[Pick(unitNames.size())]);
    Armor* ar = mod->getArmor(ur->getArmor());
    if (!ar) continue;
    UnitFaction f = (UnitFaction)Pick(3);
    BattleUnit* u = new BattleUnit(ur, f, 1000000 + i, ar, mod->getStatAdjustment(s->getDifficulty()), b->_depth);
    int size = ar->getSize();
    Position p(Pick(sx - size + 1), Pick(sy - size + 1), 0);
    u->setPosition(p);
    u->setDirection(Pick(8));
    if (Pick(4) == 0) u->_visible = true;
    if (Pick(4) == 0) u->_turnsSinceSpotted = Pick(10);
    b->getUnits()->push_back(u);
    units.push_back(u);
  }
  b->resetUnitTiles();
}

static std::string PathText(Pathfinding* pf) {
  std::ostringstream o;
  const std::vector<int>& p = pf->getPath();
  for (std::vector<int>::const_reverse_iterator i = p.rbegin(); i != p.rend(); ++i) o << *i << ",";
  return o.str();
}

int main(int argc, char** argv) {
  if (argc < 6) { fprintf(stderr, "usage: pathgen <data> <user> <out folder> <count> <seed>\n"); return 2; }
  std::string data = argv[1], user = argv[2], out = argv[3];
  int count = atoi(argv[4]);
  uint64_t seed = (uint64_t)atoll(argv[5]);
  static char a0[] = "pathgen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
  std::string cfg = user;
  char* args[] = {a0, a1, (char*)data.c_str(), a3, (char*)user.c_str(), a5, (char*)cfg.c_str()};
  Logger::reportingLevel() = LOG_ERROR;
  if (!Options::init(7, args)) return 3;
  try {
    Options::updateMods();
    Mod::resetGlobalStatics();
    Mod* mod = new Mod();
    mod->loadAll(FileMap::getRulesets());
    for (int v = 0; v < count; v++) {
      RNG::setSeed(seed + v);
      SavedGame* s = mod->newSave();
      SavedBattleGame* b = new SavedBattleGame();
      std::vector<BattleUnit*> units;
      BuildMap(mod, s, b, units);
      char name[64];
      snprintf(name, sizeof name, "path%02d", v);
      std::string base = out + "/" + name;
      WriteNode(base + ".yml", b->save());
      Pathfinding* pf = new Pathfinding(b);
      b->_pathfinding = pf;
      std::ostringstream res;
      int sx = b->_mapsize_x, sy = b->_mapsize_y, sz = b->_mapsize_z;
      for (size_t ui = 0; ui < units.size(); ui++) {
        BattleUnit* u = units[ui];
        int id = u->getId();
        for (int q = 0; q < 8; q++) {
          Position dest(Pick(sx), Pick(sy), Pick(sz));
          int maxTu = Pick(3) == 0 ? 20 + Pick(80) : 1000;
          pf->calculate(u, dest, 0, maxTu);
          res << "calc " << id << " " << dest.x << " " << dest.y << " " << dest.z << " " << maxTu << " = " << PathText(pf)
              << " tu=" << pf->getTotalTUCost() << "\n";
        }
        // a missile to another unit
        for (size_t oi = 0; oi < units.size() && oi < 3; oi++) {
          if (oi == ui) continue;
          BattleUnit* t = units[oi];
          pf->calculate(u, t->getPosition(), t, -1);
          res << "missile " << id << " " << t->getId() << " = " << PathText(pf) << " tu=" << pf->getTotalTUCost() << "\n";
        }
        // steps
        for (int q = 0; q < 12; q++) {
          Position from(Pick(sx), Pick(sy), Pick(sz));
          int dir = Pick(10);
          Position end;
          int cost = pf->getTUCost(from, dir, &end, u, 0, false);
          res << "step " << id << " " << from.x << " " << from.y << " " << from.z << " " << dir << " = " << cost << " "
              << end.x << " " << end.y << " " << end.z << "\n";
        }
        int tuMax = 10 + Pick(60);
        std::vector<int> r = pf->findReachable(u, tuMax);
        std::vector<int> sorted(r);
        std::sort(sorted.begin(), sorted.end());
        // the list is sorted by cost with std::sort, that does not keep the order of equal costs: when more tiles
        // have the cost of the first one (a fall costs nothing) which comes first depends on the compiler: "tie"
        int ties = 0;
        for (size_t k = 0; k < r.size(); k++)
          if (pf->_nodes[r[k]].getTUCost(false) == pf->_nodes[r[0]].getTUCost(false)) ties++;
        res << "reach " << id << " " << tuMax << " = " << r.size() << " first=";
        if (ties > 1) res << "tie"; else res << (r.empty() ? -1 : r[0]);
        res << " set=";
        for (size_t k = 0; k < sorted.size(); k++) res << sorted[k] << ",";
        res << "\n";
      }
      if (getenv("PATHGEN_ALL")) {
        // every step of every tile for the unit that is asked: used to find the first step that differs
        BattleUnit* u = units[atoi(getenv("PATHGEN_ALL")) % units.size()];
        pf->setUnit(u);
        res << "setunit " << u->getId() << "\n";
        for (int i = 0; i < b->getMapSizeXYZ(); i++) {
          Position from;
          b->getTileCoords(i, &from.x, &from.y, &from.z);
          for (int dir = 0; dir < 10; dir++) {
            Position end;
            int cost = pf->getTUCost(from, dir, &end, u, 0, false);
            res << "step " << u->getId() << " " << from.x << " " << from.y << " " << from.z << " " << dir << " = " << cost << " "
                << end.x << " " << end.y << " " << end.z << "\n";
          }
        }
      }
      std::ofstream o((base + ".txt").c_str(), std::ios::binary);
      o << res.str();
      for (size_t i = 0; i < b->_mapDataSets.size(); i++) b->_mapDataSets[i]->unloadData();
      delete s;
    }
  } catch (Exception& e) {
    fprintf(stderr, "EXCEPTION: %s\n", e.what());
    return 1;
  }
  fprintf(stderr, "ok\n");
  return 0;
}
