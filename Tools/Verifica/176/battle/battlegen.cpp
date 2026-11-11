// Harness for Libs\XcomBattle (SavedBattleGame): runs the REAL OpenXcom objects (linked from a real build, see
// build.cmd) to make saved battles: Mod::loadAll on the real TFTD mods, Mod::newSave() for the soldiers, then a battle
// built by hand with the real constructors and setters (tiles with parts of the real MCD files, soldiers and aliens,
// items with ammo, nodes, fire, smoke, wounds), and writes
//   <name>.sav     the saved game with the soldiers (SavedGame::save)
//   <name>.yml     what SavedBattleGame::save writes
//   <name>.re.yml  what SavedBattleGame::load + save of that file writes again (loadMapResources without the
//                  tile engine: the map data of the tiles, but no light and no field of view)
// Contains no OpenXcom code; the output goes in Tests\Data\XcomBattle.
// usage: battlegen <data folder> <user folder> <output folder> <count> <seed>
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
#include "Mod/RuleItem.h"
#include "Mod/RuleInventory.h"
#include "Mod/Unit.h"
#include "Mod/Armor.h"
#include "Savegame/SavedGame.h"
#include "Savegame/SavedBattleGame.h"
#include "Savegame/Base.h"
#include "Savegame/Soldier.h"
#include "Savegame/Tile.h"
#include "Savegame/Node.h"
#include "Savegame/BattleUnit.h"
#include "Savegame/BattleItem.h"
#include "Savegame/BattleUnitStatistics.h"
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

static Position RandomPos(SavedBattleGame* b) {
  return Position(Pick(b->_mapsize_x), Pick(b->_mapsize_y), Pick(b->_mapsize_z));
}

static void BuildBattle(Mod* mod, SavedGame* s, SavedBattleGame* b, int variant) {
  int sx = 10 * (1 + Pick(2)), sy = 10 * (1 + Pick(2)), sz = 2 + Pick(3);
  b->initMap(sx, sy, sz);
  const char* missions[] = {"STR_TERROR_MISSION", "STR_BASE_DEFENSE", "STR_UFO_CRASH", "STR_ALIEN_BASE_ASSAULT"};
  b->setMissionType(missions[variant % 4]);
  b->setGlobalShade(Pick(16));
  b->_turn = 1 + Pick(30);
  b->_depth = Pick(4);
  b->_side = (UnitFaction)Pick(3);
  // map data sets: a few real MCD files
  std::vector<MapDataSet*> sets;
  std::vector<std::string> names;
  for (std::map<std::string, MapDataSet*>::iterator i = mod->_mapDataSets.begin(); i != mod->_mapDataSets.end(); ++i)
    names.push_back(i->first);
  int nsets = 1 + Pick(3);
  for (int k = 0; k < nsets && !names.empty(); k++) {
    std::string n = names[Pick(names.size())];
    MapDataSet* mds = mod->getMapDataSet(n);
    if (std::find(b->_mapDataSets.begin(), b->_mapDataSets.end(), mds) != b->_mapDataSets.end()) continue;
    mds->loadData(mod->getMCDPatch(n));
    if (mds->getSize() == 0) continue;
    b->_mapDataSets.push_back(mds);
  }
  // tiles
  int density = 20 + Pick(70);
  for (int i = 0; i < b->getMapSizeXYZ(); i++) {
    Tile* t = b->_tiles[i];
    for (int part = 0; part < 4; part++) {
      if (Pick(100) < density && !b->_mapDataSets.empty()) {
        int ds = Pick(b->_mapDataSets.size());
        MapDataSet* mds = b->_mapDataSets[ds];
        int id = Pick(mds->getSize());
        t->setMapData(mds->getObject(id), id, ds, (TilePart)part);
      }
    }
    if (Pick(12) == 0) t->_fire = 1 + Pick(10);
    if (Pick(10) == 0) t->_smoke = 1 + Pick(15);
    for (int d = 0; d < 3; d++) t->_discovered[d] = Pick(3) == 0;
    if (Pick(15) == 0) t->_currentFrame[1] = 7;
    if (Pick(15) == 0) t->_currentFrame[2] = 7;
  }
  // nodes
  int nn = Pick(8);
  for (int i = 0; i < nn; i++) {
    Node* n = new Node(i, RandomPos(b), Pick(4), Pick(8), Pick(9), Pick(20), Pick(6), Pick(10));
    for (int l = Pick(5); l > 0; l--) n->getNodeLinks()->push_back(Pick(nn) - Pick(2));
    if (Pick(5) == 0) n->setDummy(true);
    if (Pick(4) == 0) n->allocateNode();
    b->getNodes()->push_back(n);
  }
  // units: the soldiers of the first base, aliens and civilians
  std::vector<Soldier*>* soldiers = s->getBases()->front()->getSoldiers();
  std::vector<std::string> unitNames;
  for (std::map<std::string, Unit*>::iterator i = mod->_units.begin(); i != mod->_units.end(); ++i) unitNames.push_back(i->first);
  int ns = std::min((int)soldiers->size(), 1 + Pick(6));
  for (int i = 0; i < ns; i++) {
    BattleUnit* u = new BattleUnit((*soldiers)[i], b->_depth);
    b->getUnits()->push_back(u);
  }
  int na = Pick(8);
  for (int i = 0; i < na && !unitNames.empty(); i++) {
    Unit* ur = mod->getUnit(unitNames[Pick(unitNames.size())]);
    Armor* ar = mod->getArmor(ur->getArmor());
    if (!ar) continue;
    UnitFaction f = (UnitFaction)(1 + Pick(2));
    BattleUnit* u = new BattleUnit(ur, f, 1000000 + i, ar, mod->getStatAdjustment(s->getDifficulty()), b->_depth);
    b->getUnits()->push_back(u);
  }
  for (size_t i = 0; i < b->getUnits()->size(); i++) {
    BattleUnit* u = (*b->getUnits())[i];
    Position p = RandomPos(b);
    int size = u->getArmor()->getSize();
    if (p.x + size > b->_mapsize_x) p.x = b->_mapsize_x - size;
    if (p.y + size > b->_mapsize_y) p.y = b->_mapsize_y - size;
    u->setPosition(p);
    u->setDirection(Pick(8));
    if (Pick(3) == 0) u->kneel(true);
    // real methods with the real generator
    for (int k = Pick(4); k > 0; k--) u->damage(Position(Pick(33) - 16, Pick(33) - 16, Pick(24)), Pick(60), (ItemDamageType)Pick(10));
    if (Pick(3) == 0) u->setFire(Pick(5));
    if (Pick(3) == 0) u->moraleChange(-Pick(60));
    if (Pick(3) == 0) u->spendTimeUnits(Pick(u->getTimeUnits() + 1));
    if (Pick(3) == 0) u->spendEnergy(Pick(40));
    if (Pick(4) == 0) u->addFiringExp();
    if (Pick(4) == 0) u->addReactionExp();
    if (Pick(4) == 0) u->addKillCount();
    if (Pick(4) == 0) u->setTurretType(Pick(3) - 1);
    if (Pick(5) == 0) u->setActiveHand("STR_LEFT_HAND");
    if (Pick(6) == 0) u->_status = (UnitStatus)Pick(11);
    if (Pick(6) == 0) u->_visible = true;
    if (Pick(6) == 0) u->_turnsSinceSpotted = Pick(256);
    if (Pick(6) == 0) u->setRankInt(Pick(6));
    if (Pick(8) == 0) u->setSpawnUnit("STR_ZOMBIE");
    if (Pick(8) == 0) u->setRespawn(true);
    if (Pick(8) == 0) u->setMurdererId(Pick(100));
    if (Pick(8) == 0) u->setMurdererWeapon("STR_WEAPON_" + std::to_string(Pick(9)));
    if (Pick(8) == 0) u->setMindControllerId(Pick(100));
    if (Pick(8) == 0) u->_dontReselect = true;
    if (Pick(8) == 0) u->_motionPoints = Pick(60);
    if (Pick(8) == 0) u->_statistics->hitCounter = Pick(9);
    if (Pick(8) == 0) u->_statistics->shotsFiredCounter = Pick(9);
  }
  // keep the original faction of a converted unit sometimes
  for (size_t i = 0; i < b->getUnits()->size(); i++)
    if (Pick(8) == 0) (*b->getUnits())[i]->convertToFaction((UnitFaction)Pick(3));
  // items: on the units (their real slots), on the ground and in the recovery lists
  std::vector<std::string> itemNames;
  for (std::map<std::string, RuleItem*>::iterator i = mod->_items.begin(); i != mod->_items.end(); ++i) itemNames.push_back(i->first);
  std::vector<std::string> slotNames;
  for (std::map<std::string, RuleInventory*>::iterator i = mod->_invs.begin(); i != mod->_invs.end(); ++i) slotNames.push_back(i->first);
  RuleInventory* ground = mod->getInventory("STR_GROUND", true);
  int ni = Pick(25);
  for (int i = 0; i < ni && !itemNames.empty(); i++) {
    RuleItem* r = mod->getItem(itemNames[Pick(itemNames.size())]);
    BattleItem* it = new BattleItem(r, b->getCurrentItemId());
    BattleItem* ammo = 0;
    if (it->needsAmmo() && !r->getCompatibleAmmo()->empty()) {
      RuleItem* ar = mod->getItem((*r->getCompatibleAmmo())[Pick(r->getCompatibleAmmo()->size())]);
      if (ar) {
        ammo = new BattleItem(ar, b->getCurrentItemId());
        ammo->setAmmoQuantity(Pick(ar->getClipSize() + 1));
        it->setAmmoItem(ammo);
      }
    }
    if (Pick(4) == 0) it->setFuseTimer(Pick(5));
    if (Pick(5) == 0) it->setXCOMProperty(true);
    if (Pick(5) == 0) it->setTurnFlag(true);
    if (Pick(6) == 0) it->setHealQuantity(Pick(5));
    int where = Pick(10);
    std::vector<BattleItem*>* target = b->getItems();
    if (where < 4 && !b->getUnits()->empty()) {
      BattleUnit* u = (*b->getUnits())[Pick(b->getUnits()->size())];
      it->moveToOwner(u);
      RuleInventory* slot = mod->getInventory(slotNames[Pick(slotNames.size())]);
      it->setSlot(slot);
      it->setSlotX(Pick(10));
      it->setSlotY(Pick(10));
      if (ammo) { ammo->moveToOwner(u); }
    } else if (where < 8) {
      Tile* t = b->_tiles[Pick(b->getMapSizeXYZ())];
      t->addItem(it, ground);
      if (ammo) t->addItem(ammo, ground);
    } else if (where == 8) {
      target = b->getGuaranteedRecoveredItems();
    } else {
      target = b->getConditionalRecoveredItems();
    }
    target->push_back(it);
    if (ammo) target->push_back(ammo);
  }
  // an item of an unconscious unit
  if (b->getUnits()->size() > 1 && Pick(2)) {
    RuleItem* corpse = 0;
    for (std::map<std::string, RuleItem*>::iterator i = mod->_items.begin(); i != mod->_items.end(); ++i)
      if (i->second->getBattleType() == BT_CORPSE) { corpse = i->second; break; }
    if (corpse) {
      BattleItem* it = new BattleItem(corpse, b->getCurrentItemId());
      it->setUnit((*b->getUnits())[1]);
      b->_tiles[Pick(b->getMapSizeXYZ())]->addItem(it, ground);
      b->getItems()->push_back(it);
    }
  }
  // the units on their tiles (what resetUnitTiles does)
  b->resetUnitTiles();
  b->_objectiveType = Pick(15) - 1;
  b->_objectivesNeeded = Pick(4);
  b->_objectivesDestroyed = b->_objectivesNeeded ? Pick(b->_objectivesNeeded + 1) : 0;
  b->_tuReserved = (BattleActionType)Pick(14);
  b->_kneelReserved = Pick(2) == 0;
  b->_ambience = Pick(5) - 1;
  b->_ambientVolume = 0.1 * Pick(11);
  b->_music = Pick(2) ? "GMTACTIC" : "";
  b->_turnLimit = Pick(30);
  b->_chronoTrigger = (ChronoTrigger)Pick(3);
  b->_cheatTurn = 10 + Pick(20);
  if (variant % 4 == 1) {
    b->_baseModules.resize(sx / 10, std::vector<std::pair<int, int> >(sy / 10, std::make_pair(-1, -1)));
    for (size_t x = 0; x < b->_baseModules.size(); x++)
      for (size_t y = 0; y < b->_baseModules[x].size(); y++)
        b->_baseModules[x][y] = std::make_pair(Pick(4) - 1, Pick(4) - 1);
  }
  for (size_t i = 0; i < b->getUnits()->size(); i++)
    if ((*b->getUnits())[i]->getFaction() == FACTION_PLAYER && !b->_selectedUnit) b->_selectedUnit = (*b->getUnits())[i];
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

int main(int argc, char** argv) {
  if (argc < 6) { fprintf(stderr, "usage: battlegen <data> <user> <out folder> <count> <seed>\n"); return 2; }
  std::string data = argv[1], user = argv[2], out = argv[3];
  int count = atoi(argv[4]);
  uint64_t seed = (uint64_t)atoll(argv[5]);
  static char a0[] = "battlegen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
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
      SavedBattleGame* b = new SavedBattleGame();
      BuildBattle(mod, s, b, v);
      char name[64];
      snprintf(name, sizeof name, "battle%02d", v);
      std::string base = out + "/" + name;
      s->save(std::string(name) + ".sav");
      {
        std::string from = folder + name + ".sav";
        std::ifstream in(from.c_str(), std::ios::binary);
        std::ofstream o((base + ".sav").c_str(), std::ios::binary);
        o << in.rdbuf();
      }
      WriteNode(base + ".yml", b->save());
      // the real load and save of that file
      YAML::Node node = YAML::LoadFile(base + ".yml");
      SavedBattleGame* c = new SavedBattleGame();
      c->load(node, mod, s);
      LoadMapResourcesNoEngine(mod, c);
      WriteNode(base + ".re.yml", c->save());
      delete c;
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
