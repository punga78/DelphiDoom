// Harness for Libs\XcomBattle (BattlescapeGame and its states): the REAL OpenXcom objects (see build.cmd) with a REAL
// Game (SDL dummy video and audio drivers), a real Mod with its resources and a real BattlescapeState/Map/Camera load a
// battle from a saved game and execute a script of orders. After every order the real BattlescapeGame::handleState runs
// until the list of states is empty; the harness writes the SavedBattleGame (YAML), the RNG seed and the names of the
// states that ran. Contains no OpenXcom code.
// usage: bgame <data> <user> <save name> <out folder> <script file|auto:<count>:<seed>>
// Orders (one per line, a tile is x y z):
//   select <unit id>                     setSelectedUnit
//   placegrenade <x> <y> <z> <type> <fuse> <owner id>   a new grenade on the floor (BattleItem) with the fuse and the previous owner
//   endturn                              BattlescapeGame::endTurn (+ the states it pushes) and the AI turn of the other side
//   explode <x> <y> <z> <type> <owner id> <tile 0/1>   an ExplosionBState of an item of the type at the voxel center of the tile
#include <yaml-cpp/yaml.h>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <typeinfo>
#include <windows.h>
#define private public
#define protected public
#include "Engine/Game.h"
#include "Engine/State.h"
#include "Engine/Options.h"
#include "Engine/Logger.h"
#include "Engine/Exception.h"
#include "Engine/RNG.h"
#include "Engine/Screen.h"
#include "Engine/Language.h"
#include "Mod/Mod.h"
#include "Mod/RuleItem.h"
#include "Savegame/SavedGame.h"
#include "Savegame/SavedBattleGame.h"
#include "Savegame/Tile.h"
#include "Savegame/BattleUnit.h"
#include "Savegame/BattleItem.h"
#include "Battlescape/TileEngine.h"
#include "Battlescape/Pathfinding.h"
#include "Battlescape/BattlescapeState.h"
#include "Battlescape/BattlescapeGame.h"
#include "Battlescape/BattleState.h"
#include "Battlescape/ExplosionBState.h"
#include "Battlescape/UnitTurnBState.h"
#include "Battlescape/Map.h"
#include "Battlescape/Camera.h"
#include "Battlescape/Projectile.h"
#undef protected
#undef private
#undef main
using namespace OpenXcom;

static void WriteText(const std::string& path, const std::string& text) {
  std::ofstream o(path.c_str(), std::ios::binary);
  o << text;
}

static void WriteNode(const std::string& path, const YAML::Node& node) {
  YAML::Emitter out;
  out << node;
  WriteText(path, out.c_str());
}

static std::vector<std::string> Split(const std::string& line) {
  std::vector<std::string> r;
  std::istringstream s(line);
  std::string w;
  while (s >> w) r.push_back(w);
  return r;
}

static BattleUnit* FindUnit(SavedBattleGame* b, int id) {
  for (size_t i = 0; i < b->_units.size(); i++)
    if (b->_units[i]->getId() == id) return b->_units[i];
  return 0;
}

static std::string StateName(BattleState* s) {
  std::string n = typeid(*s).name();  // N8OpenXcom15ExplosionBStateE
  size_t i = 10;
  while (i < n.size() && isdigit((unsigned char)n[i])) i++;
  return n.substr(i, n.size() - i - 1);
}

static std::string g_trace;
static Map* g_map = 0;
static int g_tick = 0;

// runs the states until none is left (the end of the turn of the other side included); a guard stops a loop
static void RunStates(BattlescapeGame* bg, int guard = 3000) {
  while (guard-- > 0) {
    if (bg->_states.empty()) break;
    BattleState* f = bg->_states.front();
    g_trace += f ? StateName(f) : std::string("EndTurn");
    if (f && StateName(f) == "ProjectileFlyBState") {
      Projectile* pr = g_map->getProjectile();
      if (pr) { Position pp = pr->getPosition(); char tb[96]; snprintf(tb, sizeof tb, "[%d/%d/%d n=%d]", pp.x, pp.y, pp.z, (int)pr->_trajectory.size()); g_trace += tb; } else g_trace += "[none]";
    }
    if (f && StateName(f) == "ExplosionBState") { ExplosionBState* ex = (ExplosionBState*)f; char tb[96]; snprintf(tb, sizeof tb, "[p=%d aoe=%d c=%d/%d/%d]", ex->_power, ex->_areaOfEffect ? 1 : 0, ex->_center.x, ex->_center.y, ex->_center.z); g_trace += tb; }
    g_trace += "@" + std::to_string((unsigned long long)RNG::getSeed());
    g_trace += "\n";
    bg->handleState();
    if (++g_tick % 3 == 0) g_map->animate(false);  // the animation timer of the game runs about every third tick of the states (UFO doors open with it)
    if (g_map->getBlastFlash()) g_map->draw();  // the real loop draws after every tick: drawTerrain ends the blast flash
  }
  if (guard <= 0) g_trace += "GUARD\n";
}

// the idle loop of the game: the states run, then think() looks for falling units (the player's side only: the
// AI turn is not part of the checks yet) and so on until nothing is left
static void Settle(BattlescapeGame* bg, SavedBattleGame* b) {
  RunStates(bg);
  for (int i = 0; i < 100 && b->getSide() == FACTION_PLAYER; i++) {
    bg->think();
    if (bg->_states.empty()) break;
    RunStates(bg);
  }
}

static void Run(Game* game, BattlescapeState* bs, const std::string& out, const std::vector<std::string>& script) {
  SavedBattleGame* b = game->getSavedGame()->getSavedBattle();
  BattlescapeGame* bg = bs->getBattleGame();
  g_map = bs->getMap();
  Mod* mod = game->getMod();
  for (size_t n = 0; n < script.size(); n++) {
    std::vector<std::string> w = Split(script[n]);
    if (w.empty()) continue;
    g_trace = "# " + script[n] + "\n";
    try {
      if (w[0] == "select") {
        b->setSelectedUnit(FindUnit(b, atoi(w[1].c_str())));
      } else if (w[0] == "placegrenade") {
        Position p(atoi(w[1].c_str()), atoi(w[2].c_str()), atoi(w[3].c_str()));
        BattleItem* it = new BattleItem(mod->getItem(w[4], true), b->getCurrentItemId());
        it->setFuseTimer(atoi(w[5].c_str()));
        it->setPreviousOwner(FindUnit(b, atoi(w[6].c_str())));
        b->getTile(p)->addItem(it, mod->getInventory("STR_GROUND", true));
        b->getItems()->push_back(it);
      } else if (w[0] == "explode") {
        Position p(atoi(w[1].c_str()), atoi(w[2].c_str()), atoi(w[3].c_str()));
        BattleItem* it = new BattleItem(mod->getItem(w[4], true), b->getCurrentItemId());
        Position c(p.x * 16 + 8, p.y * 16 + 8, p.z * 24 + 10);
        bg->statePushBack(new ExplosionBState(bg, c, it, FindUnit(b, atoi(w[5].c_str())), atoi(w[6].c_str()) ? b->getTile(p) : 0));
      } else if (w[0] == "walk" || w[0] == "shoot" || w[0] == "throw" || w[0] == "kneel" || w[0] == "turn") {
        // what the player does with the mouse: select a soldier, choose the action, click on the map (primaryAction)
        BattleUnit* u = FindUnit(b, atoi(w[1].c_str()));
        b->setSelectedUnit(u);
        BattleAction* a = &bg->_currentAction;
        a->targeting = false;
        a->type = BA_NONE;
        a->actor = u;
        a->weapon = 0;
        a->waypoints.clear();
        a->autoShotCounter = 0;
        size_t at = 2;
        if (w[0] == "shoot" || w[0] == "throw") {
          if (w[0] == "shoot") {
            a->type = (BattleActionType)atoi(w[at++].c_str());
            a->weapon = u->getMainHandWeapon();
          } else {
            a->type = BA_THROW;
            a->weapon = u->getGrenadeFromBelt();
            if (a->weapon) a->weapon->setFuseTimer(0);
          }
          a->TU = a->weapon ? u->getActionTUs(a->type, a->weapon) : 0;
          a->targeting = a->weapon != 0;
        }
        if (w[0] == "kneel") {
          bg->kneel(u);
        } else if (w[0] == "turn") {
          // the turn of a unit towards a tile (the right click on the map)
          Position t(atoi(w[2].c_str()), atoi(w[3].c_str()), atoi(w[4].c_str()));
          a->target = t;
          bg->statePushBack(new UnitTurnBState(bg, *a));
        } else if (w[0] != "shoot" || a->weapon) {
          if (w[0] != "throw" || a->weapon)
            bg->primaryAction(Position(atoi(w[at].c_str()), atoi(w[at + 1].c_str()), atoi(w[at + 2].c_str())));
        }
      } else if (w[0] == "endturn") {
        bg->_endTurnRequested = true;
        bg->statePushBack(0);
      }
      Settle(bg, b);
      if (w[0] == "endturn" && getenv("BGAME_AI")) {
        // the other side plays: think() chooses the AI actions until it ends its turn
        int guard = 2000;
        while (b->getSide() != FACTION_PLAYER && guard-- > 0) {
          bg->think();
          RunStates(bg);
        }
      }
    } catch (Exception& e) {
      g_trace += std::string("EXCEPTION ") + e.what() + "\n";
    }
    char name[64];
    snprintf(name, sizeof name, "/step%03d", (int)n);
    WriteNode(out + name + ".yml", b->save());
    std::ostringstream t;
    t << g_trace << "seed=" << RNG::getSeed() << " side=" << (int)b->getSide() << " turn=" << b->getTurn() << "\n";
    WriteText(out + name + ".txt", t.str());
  }
}

// the orders of an automatic script are chosen with a generator of the harness (not RNG): the battle keeps its own seed
static unsigned long long g_pick = 1;
static int Pick(int n) {
  g_pick = g_pick * 6364136223846793005ULL + 1442695040888963407ULL;
  return n <= 0 ? 0 : (int)((g_pick >> 33) % (unsigned long long)n);
}

int main(int argc, char** argv) {
  if (argc < 6) { fprintf(stderr, "usage: bgame <data> <user> <save> <out> <script|auto:count:seed>\n"); return 2; }
  _putenv("SDL_VIDEODRIVER=dummy");
  _putenv("SDL_AUDIODRIVER=dummy");
  std::string data = argv[1], user = argv[2], save = argv[3], out = argv[4], scriptArg = argv[5];
  static char a0[] = "bgame", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
  std::string cfg = user;
  char* args[] = {a0, a1, (char*)data.c_str(), a3, (char*)user.c_str(), a5, (char*)cfg.c_str()};
  Logger::reportingLevel() = LOG_ERROR;
  if (!Options::init(7, args)) return 3;
  try {
    Options::updateMods();
    Game* game = new Game("bgame");
    State::setGamePtr(game);
    Options::baseXResolution = Options::displayWidth;
    Options::baseYResolution = Options::displayHeight;
    game->loadMods();
    game->loadLanguages();
    SavedGame* s = new SavedGame();
    s->load(save, game->getMod());
    game->setSavedGame(s);
    SavedBattleGame* b = s->getSavedBattle();
    if (!b) { fprintf(stderr, "no battle in the saved game\n"); return 4; }
    b->loadMapResources(game->getMod());
    BattlescapeState* bs = new BattlescapeState();
    b->setBattleState(bs);
    game->pushState(bs);
    bs->init();
    std::vector<std::string> script;
    if (scriptArg.compare(0, 5, "auto:") == 0) {
      int count = 10;
      unsigned long long seed = 1;
      sscanf(scriptArg.c_str(), "auto:%d:%llu", &count, &seed);
      g_pick = seed;
      std::vector<std::string> grenades;
      const std::vector<std::string>& items = game->getMod()->getItemsList();
      for (size_t i = 0; i < items.size(); i++) {
        RuleItem* r = game->getMod()->getItem(items[i]);
        if (r && r->getBattleType() == BT_GRENADE) grenades.push_back(items[i]);
      }
      std::vector<BattleUnit*>& units = b->_units;
      for (int k = 0; k < count; k++) {
        std::ostringstream o;
        int what = Pick(6);
        BattleUnit* u = units[Pick((int)units.size())];
        Position p = u->getPosition() + Position(Pick(5) - 2, Pick(5) - 2, 0);
        const std::string& g = grenades[Pick((int)grenades.size())];
        int fuse = Pick(2);
        // a soldier of the player for the orders of the mouse
        std::vector<BattleUnit*> mine;
        for (size_t q = 0; q < units.size(); q++)
          if (units[q]->getFaction() == FACTION_PLAYER && !units[q]->isOut()) mine.push_back(units[q]);
        BattleUnit* s = mine.empty() ? u : mine[Pick((int)mine.size())];
        Position farpos = s->getPosition() + Position(Pick(15) - 7, Pick(15) - 7, 0);
        int mode = Pick(100);
        bool hasMouse = !mine.empty() && b->getTile(farpos);
        if (hasMouse && mode < 40) o << "walk " << s->getId() << " " << farpos.x << " " << farpos.y << " " << farpos.z;
        else if (hasMouse && mode < 65 && s->getMainHandWeapon()) o << "shoot " << s->getId() << " " << (BA_SNAPSHOT + Pick(3)) << " " << farpos.x << " " << farpos.y << " " << farpos.z;
        else if (hasMouse && mode < 75 && s->getGrenadeFromBelt()) o << "throw " << s->getId() << " " << farpos.x << " " << farpos.y << " " << farpos.z;
        else if (hasMouse && mode < 80) o << "kneel " << s->getId();
        else if (hasMouse && mode < 85) o << "turn " << s->getId() << " " << farpos.x << " " << farpos.y << " " << farpos.z;
        else if (mode < 90) o << "endturn\nendturn";
        else if (!b->getTile(p)) o << "select " << u->getId();
        else if (what == 1) o << "explode " << p.x << " " << p.y << " " << p.z << " " << g << " " << u->getId() << " 0";
        else o << "placegrenade " << p.x << " " << p.y << " " << p.z << " " << g << " " << fuse << " " << u->getId();
        std::string str = o.str();
        size_t nl = str.find('\n');
        if (nl != std::string::npos) {
          script.push_back(str.substr(0, nl));
          script.push_back(str.substr(nl + 1));
        } else {
          script.push_back(str);
        }
      }
      std::string all;
      for (size_t i = 0; i < script.size(); i++) all += script[i] + "\n";
      WriteText(out + "/script.txt", all);
    } else {
      std::ifstream in(scriptArg.c_str());
      std::string line;
      while (std::getline(in, line)) script.push_back(line);
    }
    WriteNode(out + "/start.yml", b->save());
    {
      // the whole saved game of the start (with the battle): the port loads it and plays the same script
      s->save("bgamestart.sav");
      std::ifstream in((Options::getMasterUserFolder() + "bgamestart.sav").c_str(), std::ios::binary);
      std::ofstream o((out + "/start.sav").c_str(), std::ios::binary);
      o << in.rdbuf();
    }
    {
      // explode keeps the tiles it reached in a std::set<Tile*>: the order of the memory addresses of the tiles
      std::vector<std::pair<uintptr_t, int> > byAddress;
      for (int i = 0; i < b->getMapSizeXYZ(); i++) byAddress.push_back(std::make_pair((uintptr_t)b->_tiles[i], i));
      std::sort(byAddress.begin(), byAddress.end());
      std::string order;
      for (size_t i = 0; i < byAddress.size(); i++) order += (i ? "," : "") + std::to_string(byAddress[i].second);
      WriteText(out + "/start.txt", "seed=" + std::to_string((unsigned long long)RNG::getSeed()) + "\ntileorder=" + order + "\n");
    }
    Run(game, bs, out, script);
  } catch (Exception& e) {
    fprintf(stderr, "EXCEPTION: %s\n", e.what());
    return 1;
  }
  fprintf(stderr, "ok\n");
  return 0;
}
