// Harness for Libs\XcomBattle (BattlescapeGenerator): runs the REAL BattlescapeGenerator (linked from the real OpenXcom
// build, see build.cmd) on the real TFTD mods and writes, for every scenario,
//   genNN.sav  the saved game just before the run (SavedGame::save: base, soldiers, craft, items)
//   genNN.scn  the parameters of the run (key=value lines) and the RNG state before and after it
//   genNN.yml  what SavedBattleGame::save writes after BattlescapeGenerator::run
//   genNN.err  (instead of .yml) the message of the Exception that run threw, when it threw
// The Game that the generator asks for the saved game and the mod is a block of zeroed memory with only those two
// fields set: the generator reads nothing else of it. Contains no OpenXcom code.
// With GEN_STAGE=1, for a mission whose deployment has a next stage (GEN_MISSION=<deployment> forces the mission of the
// scenarios without a UFO), the first stage is given an outcome (units killed, soldiers put on the exit tiles, aborted
// or won: the "actions" of genNN.stage, which the test repeats) and the REAL BattlescapeGenerator::nextStage runs:
//   genNN.stage      the outcome, the seed before and after nextStage, or its error
//   genNN.stage.yml  what SavedBattleGame::save writes after nextStage
// With GEN_EXTRA=1 a scenario with a craft gets what the debriefing harness needs and the plain scenarios lack: the
// mission site or the alien base of its deployment in the saved game (the destination of the craft, in the
// battlescape) and two vehicles in the craft.
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
#include "Mod/Armor.h"
#include "Savegame/SavedGame.h"
#include "Savegame/SavedBattleGame.h"
#include "Savegame/Base.h"
#include "Savegame/Craft.h"
#include "Savegame/Ufo.h"
#include "Savegame/Vehicle.h"
#include "Savegame/MissionSite.h"
#include "Savegame/AlienBase.h"
#include "Mod/RuleAlienMission.h"
#include "Mod/Unit.h"
#include "Savegame/Soldier.h"
#include "Savegame/Tile.h"
#include "Savegame/Node.h"
#include "Savegame/BattleUnit.h"
#include "Savegame/BattleItem.h"
#include "Mod/MapData.h"
#include "Savegame/ItemContainer.h"
#include "Battlescape/BattlescapeGenerator.h"
#include "Engine/Game.h"
#include "Engine/State.h"
#include "Battlescape/BattlescapeState.h"
#include "Battlescape/BattlescapeGame.h"
#include "Battlescape/AIModule.h"
#include "Battlescape/Pathfinding.h"
#include "Battlescape/TileEngine.h"
#include "Mod/RuleItem.h"
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
      if (getenv("GEN_MISSION") && (kind == 0 || kind == 1)) mission = getenv("GEN_MISSION");
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
      if (getenv("GEN_EXTRA") && craft) {
        // two vehicles: the first fixed weapons of the rules that have a unit (a tank), with a full clip
        int added = 0;
        for (std::map<std::string, RuleItem*>::iterator i = mod->_items.begin(); i != mod->_items.end() && added < 2; ++i) {
          RuleItem* r = i->second;
          if (!r->isFixed() || !mod->getUnit(i->first)) continue;
          int clip = r->getClipSize();
          if (!r->getCompatibleAmmo()->empty()) clip = mod->getItem(r->getCompatibleAmmo()->front(), true)->getClipSize();
          int size = mod->getArmor(mod->getUnit(i->first)->getArmor(), true)->getSize();
          craft->getVehicles()->push_back(new Vehicle(r, clip, size * size));
          added++;
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
      if (getenv("GEN_EXTRA") && craft && !ufo) {
        AlienDeployment* dep = mod->getDeployment(mission, true);
        if (dep->isAlienBase()) {
          AlienBase* ab = new AlienBase(dep);
          ab->setId(s->getId(dep->getMarkerName()));
          ab->setAlienRace(race);
          ab->setLongitude(0.5);
          ab->setLatitude(0.1);
          ab->setDiscovered(true);
          s->getAlienBases()->push_back(ab);
          gen.setAlienBase(ab);
          craft->setDestination(ab);
        } else if (!dep->getMarkerName().empty()) {
          MissionSite* ms = new MissionSite(mod->getAlienMission("STR_ALIEN_SURFACE_ATTACK", true), dep);
          ms->setId(s->getId(dep->getMarkerName()));
          ms->setAlienRace(race);
          ms->setSecondsRemaining(3600);
          ms->setLongitude(0.5);
          ms->setLatitude(0.1);
          ms->setDetected(true);
          s->getMissionSites()->push_back(ms);
          gen.setMissionSite(ms);
          craft->setDestination(ms);
        }
      }
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
      if (ok && getenv("GEN_STAGE") && !rd->getNextStage().empty()) {
        // the outcome of the first stage, then the real nextStage on the same saved battle
        uint64_t stageSeed = runSeed * 31 + 7;
        RNG::setSeed(stageSeed);
        std::ostringstream st, acts;
        std::vector<Tile*> exits;
        for (int i = 0; i < b->getMapSizeXYZ(); i++) {
          Tile* t = b->_tiles[i];
          if (t->getMapData(O_FLOOR) && t->getMapData(O_FLOOR)->getSpecialType() == END_POINT && !t->getUnit()) exits.push_back(t);
        }
        int mode = (exits.empty() || Pick(2) == 0) ? 0 : 1;  // 0 every alien dies (the stage is won), 1 aborted with soldiers on the exit
        size_t nextExit = 0;
        int inExit = 0, soldiers = 0;
        bool firstSoldier = true;
        for (size_t ui = 0; ui < b->_units.size(); ui++) {
          BattleUnit* u = b->_units[ui];
          if (u->isOut()) continue;
          if (u->getOriginalFaction() == FACTION_HOSTILE) {
            if (mode == 0 || Pick(3) == 0) { u->instaKill(); acts << "kill:" << u->getId() << ";"; }
          } else if (u->getOriginalFaction() == FACTION_NEUTRAL) {
            if (Pick(2) == 0) { u->instaKill(); acts << "kill:" << u->getId() << ";"; }
          } else {
            // the first soldier always lives (and goes to the exit when the mission is aborted): somebody must go on
            bool keep = firstSoldier;
            firstSoldier = false;
            if (!keep && Pick(5) == 0) { u->instaKill(); acts << "kill:" << u->getId() << ";"; continue; }
            soldiers++;
            if (mode == 1 && (keep || Pick(3) != 0) && u->getArmor()->getSize() == 1) {
              while (nextExit < exits.size()) {
                Tile* old = u->getTile();
                Position p = exits[nextExit++]->getPosition();
                if (b->setUnitPosition(u, p)) {
                  if (old && old != u->getTile()) old->setUnit(0);
                  acts << "move:" << u->getId() << ":" << p.x << ":" << p.y << ":" << p.z << ";";
                  inExit++;
                  break;
                }
              }
            }
          }
        }
        if (soldiers > 0 && (mode == 0 || inExit > 0)) {
          b->setAborted(mode == 1);
          std::string next = rd->getNextStage();
          b->setMissionType(next);
          uint64_t genSeed = stageSeed * 3 + 1;
          RNG::setSeed(genSeed);
          srand((unsigned)genSeed);
          bool ok2 = true;
          std::string err;
          try {
            BattlescapeGenerator gen2(game);
            gen2.nextStage();
          } catch (Exception& e) {
            ok2 = false;
            err = e.what();
          }
          st << "mission=" << next << "\naborted=" << (mode == 1 ? 1 : 0) << "\ninexit=" << inExit << "\nactions=" << acts.str() << "\nstageseed=" << genSeed
             << "\nseedafter=" << RNG::getSeed() << "\nok=" << (ok2 ? 1 : 0) << "\n";
          if (!ok2) st << "error=" << err << "\n";
          WriteText(basePath + ".stage", st.str());
          if (ok2) WriteNode(basePath + ".stage.yml", b->save());
        }
      }
      if (ok && getenv("GEN_AI")) {
        // the thinking of the AI of every unit that has one, in order (they affect each other: nodes, turns), with the real AIModule::think
        State::_game = game;
        SavedBattleGame* c2 = new SavedBattleGame();
        c2->load(b->save(), mod, s);
        c2->loadMapResources(mod);
        BattlescapeState* bst = (BattlescapeState*)calloc(1, sizeof(BattlescapeState));
        c2->_battleState = bst;
        TileEngine* te = c2->getTileEngine();
        te->calculateSunShading();
        te->calculateTerrainLighting();
        te->calculateUnitLighting();
        te->recalculateFOV();
        std::ostringstream ai;
        int idx = 0;
        {
          // the real Pathfinding from every unit that has an AI to every node (before anything moves)
          std::ostringstream pf;
          Pathfinding* pfg = c2->getPathfinding();
          for (size_t ui = 0; ui < c2->_units.size(); ui++) {
            BattleUnit* pu = c2->_units[ui];
            if (!pu->getAIModule() || pu->isOut()) continue;
            for (int dd = 0; dd < 10; dd++) { Position e2; pfg->setUnit(pu); int c = pfg->getTUCost(pu->getPosition(), dd, &e2, pu, 0, false); pf << "tu " << pu->getId() << " " << dd << " = " << c << " " << e2.x << "/" << e2.y << "/" << e2.z << "\n"; }
            for (size_t ni = 0; ni < c2->getNodes()->size(); ni++) {
              Node* nd = (*c2->getNodes())[ni];
              if (nd->isDummy()) continue;
              pfg->calculate(pu, nd->getPosition());
              pf << "path " << pu->getId() << " " << nd->getID() << " = " << pfg->getStartDirection() << " " << pfg->getTotalTUCost() << " " << pfg->getPath().size() << " dirs="; { std::vector<int> pp = pfg->getPath(); for (size_t k = pp.size(); k > 0; k--) pf << pp[k - 1]; } pf << "\n";
              pfg->abortPath();
            }
          }
          WriteText(basePath + ".aip", pf.str());
        }
        std::vector<BattleUnit*> thinkers;
        for (size_t ui = 0; ui < c2->_units.size(); ui++)
          if (c2->_units[ui]->getAIModule() && !c2->_units[ui]->isOut()) thinkers.push_back(c2->_units[ui]);
        RNG::setSeed(runSeed * 13 + 5);
        for (int round = 0; round < 2 * (int)thinkers.size() + 2 && !thinkers.empty(); round++) {
          BattleUnit* u = thinkers[Pick(thinkers.size())];
          if (u->isOut()) continue;
          // most rounds put the unit near a unit of another faction so that it sees and is seen (the real setUnitPosition and recalculateFOV)
          Position moved(-1, -1, -1);
          if (round > 0 && Pick(4) != 0) {
            BattleUnit* other = c2->_units[Pick(c2->_units.size())];
            if (other->getFaction() != u->getFaction() && !other->isOut()) {
              Position p = other->getPosition() + Position(Pick(11) - 5, Pick(11) - 5, 0);
              if (c2->getTile(p) && c2->setUnitPosition(u, p)) { moved = p; te->recalculateFOV(); }
            }
          }
          uint64_t aiSeed = runSeed * 7 + idx;
          RNG::setSeed(aiSeed);
          BattleAction act;
          act.number = 1 + (idx % 3);
          idx++;
          AIModule* m = u->getAIModule();
          u->getAIModule()->think(&act);
          ai << "think " << u->getId() << " " << aiSeed << " " << (idx - 1) % 3 + 1 << " " << moved.x << "/" << moved.y << "/" << moved.z << " = type=" << (int)act.type << " target=" << act.target.x << "/" << act.target.y << "/" << act.target.z
             << " weapon=" << (act.weapon ? act.weapon->getId() : 0) << " facing=" << act.finalFacing << " final=" << (act.finalAction ? 1 : 0) << " desperate=" << (act.desperate ? 1 : 0)
             << " number=" << act.number << " tu=" << act.TU << " wp=" << act.waypoints.size();
          for (std::list<Position>::iterator w = act.waypoints.begin(); w != act.waypoints.end(); ++w) ai << ":" << w->x << "/" << w->y << "/" << w->z;
          ai << " mode=" << m->_AIMode << " reserve=" << (int)m->getReserveMode() << " esc=" << m->_escapeTUs << " amb=" << m->_ambushTUs << " to=" << (m->_toNode ? m->_toNode->getID() : -1)
             << " from=" << (m->_fromNode ? m->_fromNode->getID() : -1) << " pos=" << u->getPosition().x << "/" << u->getPosition().y << "/" << u->getPosition().z << " dir=" << u->getDirection()
             << " utu=" << u->getTimeUnits() << " charging=" << (u->getCharging() ? u->getCharging()->getId() : 0) << " hiding=" << (u->isHiding() ? 1 : 0)
             << " aggro=" << (m->getTarget() ? m->getTarget()->getId() : 0) << " known=" << m->_knownEnemies << " vis=" << m->_visibleEnemies << " spot=" << m->_spottingEnemies << " rng=" << RNG::getSeed() << "\n";
        }
        WriteText(basePath + ".ai", ai.str());
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
