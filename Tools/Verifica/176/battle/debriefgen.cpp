// Harness for Libs\XcomDebriefing (DebriefingState::prepareDebriefing): the REAL OpenXcom objects (see build.cmd) with a
// REAL Game (SDL dummy drivers) and a real Mod. For every saved game "genNN.after.sav" of gengen (a battle just
// generated: base, craft, soldiers, UFO or mission site in the battle) and for every variant the harness
//   - plays an outcome on the battle: units killed, stunned, mind controlled, moved to the exit area, items on the
//     floor, aborted or not, objectives destroyed, kills, a containment facility or not, research done or not
//   - writes debNNvV.pre.sav (the saved game at the end of the battle, the input of the port) and debNNvV.seed
//   - runs the real DebriefingState (constructor and init(), the part that calls prepareDebriefing) and writes
//     debNNvV.txt (the title, the rating, the lists of statistics, soldiers' improvements, missing items, flags,
//     the commended soldiers, the states that it pushed, the seed after) and debNNvV.post.sav (SavedGame::save after)
//   - with DEBRIEF_PIXELS also debNNvV.pix: the first page of the screen of the state after init() (width, height, then
//     the indexes of the colors) and debNNvV.pix2 the second one (soldier stats); and "cannot" for CannotReequipState;
//     ".promo" PromotionsState (when somebody was promoted), ".contain" ManageAlienContainmentState of the base,
//     ".comm" CommendationState and ".commlate" CommendationLateState on two medals made here (the TFTD mods have no
//     commendations): see AwardTestMedals, which the test of the port repeats
//   - with DEBRIEF_STATSTRINGS the mod gets the stat strings of kStatStrings (the TFTD mods have none) and the text
//     gets a line "statstring|soldier id|string" for every soldier of every base after the debriefing
//   - with DEBRIEF_REPLAY=<folder> the outcome is not played: debNNvV.pre.sav and debNNvV.txt (aborted=) of that folder
//     are the input (the cases that are in the repository can be run again, for the pixels, without the gen folder)
// Contains no OpenXcom code.
// usage: debriefgen <data> <user> <gen folder> <out folder> <variants per save> <seed> [first save index] [last]
#include <yaml-cpp/yaml.h>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <algorithm>
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
#include "Engine/Surface.h"
#include "Engine/Language.h"
#include "Engine/LocalizedText.h"
#include "Interface/Text.h"
#include "Interface/TextList.h"
#include "Mod/Mod.h"
#include "Mod/RuleItem.h"
#include "Mod/RuleResearch.h"
#include "Mod/RuleBaseFacility.h"
#include "Mod/Armor.h"
#include "Mod/MapData.h"
#include "Savegame/SavedGame.h"
#include "Savegame/SavedBattleGame.h"
#include "Savegame/Base.h"
#include "Savegame/BaseFacility.h"
#include "Savegame/Craft.h"
#include "Savegame/Ufo.h"
#include "Savegame/MissionStatistics.h"
#include "Savegame/AlienMission.h"
#include "Mod/RuleAlienMission.h"
#include "Mod/UfoTrajectory.h"
#include "Savegame/Soldier.h"
#include "Savegame/SoldierDiary.h"
#include "Savegame/Tile.h"
#include "Savegame/BattleUnit.h"
#include "Savegame/BattleUnitStatistics.h"
#include "Savegame/BattleItem.h"
#include "Savegame/ItemContainer.h"
#include "Battlescape/DebriefingState.h"
#include "Battlescape/CannotReequipState.h"
#include "Battlescape/PromotionsState.h"
#include "Battlescape/CommendationState.h"
#include "Battlescape/CommendationLateState.h"
#include "Basescape/ManageAlienContainmentState.h"
#include "Mod/RuleCommendations.h"
#include "Mod/StatString.h"
#undef protected
#undef private
#undef main
using namespace OpenXcom;

static unsigned long long g_pick = 1;
static int Pick(int n) {
  g_pick = g_pick * 6364136223846793005ULL + 1442695040888963407ULL;
  return n <= 0 ? 0 : (int)((g_pick >> 33) % (unsigned long long)n);
}

static void WriteText(const std::string& path, const std::string& text) {
  std::ofstream o(path.c_str(), std::ios::binary);
  o << text;
}

static void CopyFileBinary(const std::string& from, const std::string& to) {
  std::ifstream in(from.c_str(), std::ios::binary);
  std::ofstream o(to.c_str(), std::ios::binary);
  o << in.rdbuf();
}

static std::string Num(long long v) { return std::to_string(v); }

// the screen of a state after init(): the surfaces of the state blit on a surface the size of the screen
static void DumpState(State* st, Game* game, const std::string& path) {
  Surface* screen = new Surface(Options::baseXResolution, Options::baseYResolution, 0, 0);
  screen->setPalette(st->_palette, 0, 256);
  screen->clear();
  for (std::vector<Surface*>::iterator i = st->_surfaces.begin(); i != st->_surfaces.end(); ++i) {
    (*i)->draw();
    (*i)->blit(screen);
  }
  SDL_Surface* s = screen->getSurface();
  std::string data;
  int w = s->w, h = s->h;
  data.append((const char*)&w, 4);
  data.append((const char*)&h, 4);
  for (int y = 0; y < h; y++) data.append((const char*)s->pixels + y * s->pitch, w);
  // the palette of the state (RGB, 256 colors) follows: the colors, not the indexes, are what is compared
  SDL_Color* c = st->_palette;
  for (int i = 0; i < 256; i++) { data.push_back((char)c[i].r); data.push_back((char)c[i].g); data.push_back((char)c[i].b); }
  WriteText(path, data);
  delete screen;
}

// the stat strings of DEBRIEF_STATSTRINGS (the test of the port has the same text)
static const char* kStatStrings =
  "- string: \"x\"\n  psiStrength: [~, 30]\n"
  "- string: \"P\"\n  psiStrength: [80, ~]\n"
  "- string: \"K\"\n  psiSkill: [20, ~]\n"
  "- string: \"b\"\n  bravery: [60, ~]\n"
  "- string: \"F\"\n  firing: [60, ~]\n"
  "- string: \"r\"\n  reactions: [50, ~]\n"
  "- string: \"S\"\n  strength: [35, ~]\n"
  "- string: \"t\"\n  tu: [58, ~]\n"
  "- string: \"h\"\n  health: [0, 30]\n"
  "- string: \"w\"\n  firing: [0, 45]\n  throwing: [0, 60]\n";

// two medals for the screens of the commendations: "STR_NEW_RANK" (plain) and "STR_SPACE_USED" (its text has {0}: a
// medal with a noun). The first three soldiers of the base and the first two dead soldiers get them
static void AwardTestMedals(Game* game, Base* base, std::vector<Soldier*>& alive, std::vector<Soldier*>& dead) {
  Mod* mod = game->getMod();
  RuleCommendations* a = new RuleCommendations();
  a->load(YAML::Load("description: A\ncriteria:\n  totalKills: [1, 2, 2, 5]\nsprite: 0\n"));
  RuleCommendations* b = new RuleCommendations();
  b->load(YAML::Load("description: B\ncriteria:\n  totalMissions: [3, 3, 6]\nsprite: 1\n"));
  mod->_commendations["STR_NEW_RANK"] = a;
  mod->_commendations["STR_SPACE_USED"] = b;
  std::vector<Soldier*>* bs = base->getSoldiers();
  for (size_t i = 0; i < bs->size() && i < 3; i++) {
    Soldier* s = (*bs)[i];
    std::vector<SoldierCommendations*>* c = s->getDiary()->getSoldierCommendations();
    if (i == 0) c->push_back(new SoldierCommendations("STR_NEW_RANK", "noNoun"));
    if (i == 1) {
      SoldierCommendations* x = new SoldierCommendations("STR_NEW_RANK", "noNoun");
      x->addDecoration(); x->addDecoration();
      c->push_back(x);
      c->push_back(new SoldierCommendations("STR_SPACE_USED", "STR_AQUATOID"));
    }
    if (i == 2) {
      c->push_back(new SoldierCommendations("STR_SPACE_USED", "STR_GILLMAN"));
      SoldierCommendations* x = new SoldierCommendations("STR_SPACE_USED", "STR_AQUATOID");
      x->addDecoration();
      c->push_back(x);
    }
    alive.push_back(s);
  }
  std::vector<Soldier*>* ds = game->getSavedGame()->getDeadSoldiers();
  for (size_t i = 0; i < ds->size() && i < 2; i++) {
    Soldier* s = (*ds)[i];
    std::vector<SoldierCommendations*>* c = s->getDiary()->getSoldierCommendations();
    if (i == 0) {
      SoldierCommendations* x = new SoldierCommendations("STR_NEW_RANK", "noNoun");
      x->addDecoration();
      c->push_back(x);
      c->push_back(new SoldierCommendations("STR_SPACE_USED", "STR_GILLMAN"));
    }
    dead.push_back(s);
  }
}

static void RemoveTestMedals(Game* game) {
  Mod* mod = game->getMod();
  delete mod->_commendations["STR_NEW_RANK"];
  delete mod->_commendations["STR_SPACE_USED"];
  mod->_commendations.clear();
}

static void ApplyOutcome(Game* game, SavedGame* s, SavedBattleGame* b, int variant) {
  Mod* mod = game->getMod();
  // the world: months passed (the first battle of a new game is -1), research done, a containment facility
  if (Pick(3) == 0) s->_monthsPassed = Pick(5);
  const std::vector<std::string>& rl = mod->getResearchList();
  for (size_t i = 0; i < rl.size(); i++)
    if (Pick(4) == 0) s->_discovered.push_back(mod->getResearch(rl[i]));
  Base* base = s->getBases()->front();
  // the UFO of a "UFO" mission: gengen gave it to the generator only, the saved game has none (and it needs a mission)
  if (mod->getUfo(b->getMissionType()) && s->getUfos()->empty() && !mod->_ufoTrajectories.empty()) {
    // the saved game keeps the mission of a UFO only after the first month (Ufo::load): the UFO has one
    if (s->_monthsPassed < 0) s->_monthsPassed = 0;
    Ufo* ufo = new Ufo(mod->getUfo(b->getMissionType()));
    ufo->setLongitude((Pick(3600) / 3600.0 - 0.5) * 6.2831853);
    ufo->setLatitude((Pick(1800) / 1800.0 - 0.5) * 3.1415926);
    ufo->setStatus(Pick(2) ? Ufo::CRASHED : Ufo::LANDED);
    AlienMission* am = new AlienMission(*mod->getAlienMission(mod->getAlienMissionList().front(), true));
    am->setRace(mod->_alienRaces.begin()->first);
    am->setId(s->getId("ALIEN_MISSIONS"));
    s->getAlienMissions().push_back(am);
    ufo->setMissionInfo(am, mod->_ufoTrajectories.begin()->second);
    ufo->setId(s->getId("STR_UFO"));
    ufo->setInBattlescape(true);
    s->getUfos()->push_back(ufo);
  }
  // the craft that flew to the UFO that is in the battle (the generator does not give it a destination)
  for (size_t ci = 0; ci < base->getCrafts()->size(); ci++) {
    Craft* c = (*base->getCrafts())[ci];
    if (!c->isInBattlescape()) continue;
    for (size_t ui = 0; ui < s->getUfos()->size(); ui++)
      if ((*s->getUfos())[ui]->isInBattlescape()) c->setDestination((*s->getUfos())[ui]);
  }
  if (Pick(2) == 0) {
    for (std::map<std::string, RuleBaseFacility*>::iterator i = mod->_facilities.begin(); i != mod->_facilities.end(); ++i) {
      if (i->second->getAliens() > 0) {
        bool used[6][6] = {{false}};
        for (size_t k = 0; k < base->_facilities.size(); k++) {
          BaseFacility* f = base->_facilities[k];
          for (int x = 0; x < f->getRules()->getSize(); x++)
            for (int y = 0; y < f->getRules()->getSize(); y++)
              if (f->getX() + x < 6 && f->getY() + y < 6) used[f->getX() + x][f->getY() + y] = true;
        }
        for (int x = 0; x < 6; x++)
          for (int y = 0; y < 6; y++)
            if (!used[x][y]) {
              BaseFacility* f = new BaseFacility(i->second, base);
              f->setX(x);
              f->setY(y);
              f->setBuildTime(0);
              base->_facilities.push_back(f);
              x = 6;
              break;
            }
        break;
      }
    }
  }
  // random stores: the debriefing reequips the craft from them
  if (Pick(2) == 0) {
    std::vector<std::string> keys;
    for (std::map<std::string, int>::iterator i = base->getStorageItems()->getContents()->begin(); i != base->getStorageItems()->getContents()->end(); ++i) keys.push_back(i->first);
    for (size_t k = 0; k < keys.size(); k++) base->getStorageItems()->addItem(keys[k], Pick(4));
  }
  b->setAborted(Pick(3) == 0);
  if (b->_objectivesNeeded > 0 && Pick(3) == 0) b->_objectivesDestroyed = b->_objectivesNeeded;
  std::vector<Position> endTiles;
  for (int i = 0; i < b->getMapSizeXYZ(); i++) {
    Tile* t = b->_tiles[i];
    if (t->getMapData(O_FLOOR) && t->getMapData(O_FLOOR)->getSpecialType() == END_POINT) endTiles.push_back(t->getPosition());
  }
  std::vector<BattleUnit*>& units = b->_units;
  std::vector<std::string> items;
  for (std::map<std::string, RuleItem*>::iterator i = mod->_items.begin(); i != mod->_items.end(); ++i) items.push_back(i->first);
  int deadWeight = Pick(40) + 5;
  for (size_t i = 0; i < units.size(); i++) {
    BattleUnit* u = units[i];
    int r = Pick(100);
    Tile* tile = u->getTile();
    if (u->getOriginalFaction() == FACTION_PLAYER) {
      if (r < deadWeight / 2) {
        u->instaKill();
        u->_killedBy = (UnitFaction)Pick(3);
        u->_murdererId = units[Pick(units.size())]->getId();
      } else if (r < deadWeight) {
        u->_status = STATUS_UNCONSCIOUS;
        u->_stunlevel = u->_health + Pick(5);
      } else if (r < deadWeight + 12) {
        u->_faction = FACTION_HOSTILE;  // mind controlled by the aliens
      } else if (r < deadWeight + 22 && !endTiles.empty()) {
        Position p = endTiles[Pick(endTiles.size())];
        u->setPosition(p);
        u->setTile(b->getTile(p));
      } else if (r < deadWeight + 30) {
        u->_status = STATUS_IGNORE_ME;
      } else if (r < deadWeight + 45) {
        // on a tile that is not the start of the craft nor the exit: far from both
        Position p(Pick(b->_mapsize_x), Pick(b->_mapsize_y), 0);
        if (b->getTile(p) && !b->getTile(p)->getUnit()) {
          u->setPosition(p);
          u->setTile(b->getTile(p));
        }
      }
      if (u->_status != STATUS_DEAD && u->_health > 1 && Pick(3) == 0) u->_health -= Pick(u->_health - 1);
      if (u->getGeoscapeSoldier()) {
        u->_expFiring = Pick(5);
        u->_expReactions = Pick(4);
        u->_expThrowing = Pick(3);
        u->_expMelee = Pick(3);
        u->_expBravery = Pick(11);
        u->_expPsiSkill = Pick(2);
        u->_expPsiStrength = Pick(2);
        u->_kills = Pick(4);
      }
    } else if (u->getOriginalFaction() == FACTION_HOSTILE) {
      if (r < 35 || r < 55) {
        if (r < 35) {
          u->instaKill();
          u->_killedBy = Pick(8) ? FACTION_PLAYER : FACTION_NEUTRAL;
        } else {
          u->_status = STATUS_UNCONSCIOUS;
          u->_stunlevel = u->_health + Pick(5);
        }
        // the body: a corpse item on the tile (UnitDieBState / the fall state make it)
        if (tile && !u->getArmor()->getCorpseBattlescape().empty()) {
          RuleItem* cr = mod->getItem(u->getArmor()->getCorpseBattlescape().front());
          if (cr) {
            BattleItem* c = new BattleItem(cr, b->getCurrentItemId());
            c->setUnit(u);
            tile->addItem(c, mod->getInventory("STR_GROUND", true));
            b->getItems()->push_back(c);
          }
        }
      } else if (r < 62) {
        u->_faction = FACTION_PLAYER;  // mind controlled
      }
    } else {
      if (r < 40) {
        u->instaKill();
        u->_killedBy = Pick(2) ? FACTION_PLAYER : FACTION_HOSTILE;
      }
    }
  }
  // DEBRIEF_ZOMBIES: a unit that turns into another when it dies (a zombie), taken by psi-capture: the debriefing does
  // not recover it, it converts it (SavedBattleGame::convertUnit) and recovers what it becomes
  if (getenv("DEBRIEF_ZOMBIES")) {
    Unit* zr = 0;
    for (std::map<std::string, Unit*>::iterator i = mod->_units.begin(); i != mod->_units.end() && !zr; ++i)
      if (!i->second->getSpawnUnit().empty() && mod->getUnit(i->second->getSpawnUnit())) zr = i->second;
    for (int tries = 0; zr && tries < 50; tries++) {
      Position p(Pick(b->_mapsize_x), Pick(b->_mapsize_y), 0);
      Tile* t = b->getTile(p);
      if (!t || t->getUnit() || !t->getMapData(O_FLOOR) || t->getMapData(O_OBJECT)) continue;
      BattleUnit* z = new BattleUnit(zr, FACTION_HOSTILE, units.back()->getId() + 1, mod->getArmor(zr->getArmor(), true), mod->getStatAdjustment(s->getDifficulty()), b->getDepth());
      z->setPosition(p);
      z->setTile(t, b->getTile(p + Position(0, 0, -1)));
      t->setUnit(z, b->getTile(p + Position(0, 0, -1)));
      z->_faction = FACTION_PLAYER;
      units.push_back(z);
      break;
    }
  }
  // kills: the statistics of the units
  for (size_t i = 0; i < units.size(); i++) {
    if (!units[i]->getGeoscapeSoldier() && Pick(2)) continue;
    int n = Pick(5);
    for (int k = 0; k < n; k++) {
      BattleUnit* v = units[Pick(units.size())];
      BattleUnitKills* bk = new BattleUnitKills();
      bk->name = v->getType();
      bk->type = v->getType();
      bk->faction = v->getOriginalFaction();
      bk->status = v->getStatus() == STATUS_DEAD || Pick(2) ? STATUS_DEAD : STATUS_UNCONSCIOUS;
      bk->mission = Pick(3);
      bk->turn = 1 + Pick(40);
      bk->id = Pick(8) == 0 ? units[i]->getId() : v->getId();
      bk->side = SIDE_FRONT;
      bk->bodypart = BODYPART_HEAD;
      units[i]->getStatistics()->kills.push_back(bk);
    }
    if (Pick(6) == 0) units[i]->_murdererId = units[i]->getId();
  }
  // the loose items on the floor
  int n = 2 + Pick(14);
  for (int k = 0; k < n; k++) {
    RuleItem* r = mod->getItem(items[Pick(items.size())]);
    Position p(Pick(b->_mapsize_x), Pick(b->_mapsize_y), 0);
    Tile* t = b->getTile(p);
    if (!t || !r || r->getBattleType() == BT_CORPSE) continue;
    BattleItem* it = new BattleItem(r, b->getCurrentItemId());
    if (r->getBattleType() == BT_AMMO || r->getBattleType() == BT_FIREARM) it->setAmmoQuantity(Pick(r->getClipSize() > 0 ? r->getClipSize() + 1 : 5));
    it->setXCOMProperty(Pick(3) == 0);
    t->addItem(it, mod->getInventory("STR_GROUND", true));
    b->getItems()->push_back(it);
  }
  // some tiles of the start get the loose items too: the craft floor
  for (int i = 0; i < b->getMapSizeXYZ() && variant >= 0; i++) {
    Tile* t = b->_tiles[i];
    if (t->getMapData(O_FLOOR) && t->getMapData(O_FLOOR)->getSpecialType() == START_POINT && Pick(15) == 0) {
      RuleItem* r = mod->getItem(items[Pick(items.size())]);
      if (!r || r->getBattleType() == BT_CORPSE) continue;
      BattleItem* it = new BattleItem(r, b->getCurrentItemId());
      t->addItem(it, mod->getInventory("STR_GROUND", true));
      b->getItems()->push_back(it);
    }
  }
}

int main(int argc, char** argv) {
  if (argc < 7) { fprintf(stderr, "usage: debriefgen <data> <user> <gen folder> <out> <variants> <seed> [first] [last]\n"); return 2; }
  _putenv("SDL_VIDEODRIVER=dummy");
  _putenv("SDL_AUDIODRIVER=dummy");
  std::string data = argv[1], user = argv[2], gen = argv[3], out = argv[4];
  int variants = atoi(argv[5]);
  unsigned long long seed = (unsigned long long)atoll(argv[6]);
  int first = argc > 7 ? atoi(argv[7]) : 0;
  int last = argc > 8 ? atoi(argv[8]) : 100000;
  bool pixels = getenv("DEBRIEF_PIXELS") != 0;
  bool statStrings = getenv("DEBRIEF_STATSTRINGS") != 0;
  std::string replay = getenv("DEBRIEF_REPLAY") ? getenv("DEBRIEF_REPLAY") : "";
  static char a0[] = "debriefgen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
  std::string cfg = user;
  char* args[] = {a0, a1, (char*)data.c_str(), a3, (char*)user.c_str(), a5, (char*)cfg.c_str()};
  Logger::reportingLevel() = LOG_ERROR;
  if (!Options::init(7, args)) return 3;
  int done = 0;
  try {
    Options::updateMods();
    Game* game = new Game("debriefgen");
    State::setGamePtr(game);
    Options::baseXResolution = Options::displayWidth;
    Options::baseYResolution = Options::displayHeight;
    game->loadMods();
    game->loadLanguages();
    Options::mute = true;
    if (statStrings) {
      YAML::Node list = YAML::Load(kStatStrings);
      for (YAML::const_iterator i = list.begin(); i != list.end(); ++i) {
        StatString* ss = new StatString();
        ss->load(*i);
        game->getMod()->_statStrings.push_back(ss);
      }
    }
    if (!pixels) game->_lang = new Language();  // no texts loaded: tr(key) gives the key, which is what the port compares
    std::string folder = Options::getMasterUserFolder();
    for (int save = first; save <= last; save++) {
      char name[64];
      snprintf(name, sizeof name, "gen%02d.after.sav", save);
      std::string src = gen + "/" + name;
      if (replay.empty() && !std::ifstream(src.c_str(), std::ios::binary)) continue;
      for (int v = 0; v < variants; v++) {
        snprintf(name, sizeof name, "deb%02dv%d", save, v);
        std::string base = out + "/" + name;
        SavedGame* s = 0;
        SavedBattleGame* b = 0;
        bool aborted = false;
        if (!replay.empty()) {
          // the input is a case that was written before: the saved game at the end of the battle and its "aborted"
          std::string pre = replay + "/" + name + ".pre.sav";
          if (!std::ifstream(pre.c_str(), std::ios::binary)) continue;
          CopyFileBinary(pre, folder + "debpre.sav");
          CopyFileBinary(pre, base + ".pre.sav");
          std::ifstream txt((replay + "/" + name + ".txt").c_str());
          std::string line;
          while (std::getline(txt, line)) if (line.compare(0, 9, "aborted=1") == 0) aborted = true;
        } else {
          CopyFileBinary(src, folder + "debin.sav");
          g_pick = seed * 1000003ULL + save * 101ULL + v;
          RNG::setSeed(seed * 7919ULL + save * 31ULL + v);
          s = new SavedGame();
          fprintf(stderr, "load %s\n", name); s->load("debin.sav", game->getMod()); fprintf(stderr, "loaded\n");
          game->setSavedGame(s);
          b = s->getSavedBattle();
          if (!b) { delete s; continue; }
          { bool any = false; for (size_t bi = 0; bi < s->getBases()->size(); bi++) { Base* bb = (*s->getBases())[bi]; if (bb->isInBattlescape() && b->getMissionType() == "STR_BASE_DEFENSE") any = true; for (size_t ci = 0; ci < bb->getCrafts()->size(); ci++) if ((*bb->getCrafts())[ci]->isInBattlescape()) any = true; } if (!any) continue; }
          try { b->loadMapResources(game->getMod()); } catch (std::exception& ex) { fprintf(stderr, "skipped %s (resources): %s\n", name, ex.what()); continue; }
          // the look of the aliens and the civilians is std::rand (cosmetic): not part of what is compared
          try { ApplyOutcome(game, s, b, v); } catch (std::exception& ex) { fprintf(stderr, "skipped %s: %s\n", name, ex.what()); continue; }
          s->save("debpre.sav");
          CopyFileBinary(folder + "debpre.sav", base + ".pre.sav");
          aborted = b->isAborted();
        }
        {
          // the debriefing runs on what the file gives back (the port reads the file): the UFOs have their
          // waypoint, the craft their hangars... what the objects built by hand do not have
          SavedGame* s2 = new SavedGame();
          s2->load("debpre.sav", game->getMod());
          game->setSavedGame(s2);
          s = s2;
          b = s->getSavedBattle();
          b->loadMapResources(game->getMod());
          b->setAborted(aborted);
        }
        unsigned long long seed0 = RNG::getSeed();
        size_t statesBefore = game->_states.size();
        // the screens are dumped at the original size: the constructor of DebriefingState sets the resolution of the
        // geoscape (0 in this harness, which never opened one), and centerAllSurfaces and DumpState read it
        Options::baseXGeoscape = 320;
        Options::baseYGeoscape = 200;
        fprintf(stderr, "state\n"); DebriefingState* st = new DebriefingState(); fprintf(stderr, "init\n");
        std::ostringstream t;
        t << "seed0=" << seed0 << "\n" << "aborted=" << (b->isAborted() ? 1 : 0) << "\n";
        try {
          st->init();
        } catch (std::exception& e) {
          t << "EXCEPTION " << e.what() << "\n";
        }
        t << "seed1=" << RNG::getSeed() << "\n";
        t << "title=" << st->_txtTitle->getText() << "\n";
        t << "rating=" << st->_missionStatistics->rating << "\n";
        t << "recovery=" << st->_txtRecovery->getText() << "\n";
        t << "flags=" << st->_destroyBase << st->_manageContainment << st->_noContainment << st->_positiveScore << st->_promotions << " limits=" << st->_limitsEnforced << "\n";
        t << "pushed=" << (game->_states.size() - statesBefore) << "\n";
        for (size_t i = 0; i < st->_stats.size(); i++)
          t << "stat|" << st->_stats[i]->item << "|" << st->_stats[i]->qty << "|" << st->_stats[i]->score << "|" << (st->_stats[i]->recovery ? 1 : 0) << "\n";
        for (size_t i = 0; i < st->_soldierStats.size(); i++) {
          const UnitStats& u = st->_soldierStats[i].second;
          t << "soldier|" << st->_soldierStats[i].first << "|" << u.tu << "|" << u.stamina << "|" << u.health << "|" << u.bravery << "|" << u.reactions << "|" << u.firing << "|" << u.throwing << "|" << u.strength << "|" << u.psiStrength << "|" << u.psiSkill << "|" << u.melee << "\n";
        }
        for (size_t i = 0; i < st->_missingItems.size(); i++)
          t << "missing|" << st->_missingItems[i].item << "|" << st->_missingItems[i].qty << "|" << st->_missingItems[i].craft << "\n";
        for (std::map<int, RecoveryItem*>::iterator i = st->_recoveryStats.begin(); i != st->_recoveryStats.end(); ++i)
          t << "special|" << i->first << "|" << i->second->name << "|" << i->second->value << "\n";
        for (size_t i = 0; i < st->_soldiersCommended.size(); i++) t << "commended|" << st->_soldiersCommended[i]->getId() << "\n";
        for (size_t i = 0; i < st->_deadSoldiersCommended.size(); i++) t << "deadcommended|" << st->_deadSoldiersCommended[i]->getId() << "\n";
        if (statStrings)
          for (size_t bi = 0; bi < s->getBases()->size(); bi++) {
            std::vector<Soldier*>* bs = (*s->getBases())[bi]->getSoldiers();
            for (size_t i = 0; i < bs->size(); i++) t << "statstring|" << (*bs)[i]->getId() << "|" << (*bs)[i]->_statString << "\n";
          }
        t << "total=" << st->_lstTotal->getCellText(0, 1) << "\n";
        t << "lists=" << st->_lstStats->getRows() << "," << st->_lstRecovery->getRows() << "," << st->_lstSoldierStats->getRows() << "\n";
        WriteText(base + ".txt", t.str());
        if (pixels) {
          DumpState(st, game, base + ".pix");
          st->btnStatsClick(0);
          DumpState(st, game, base + ".pix2");
          if (!st->_missingItems.empty()) {
            CannotReequipState* ce = new CannotReequipState(st->_missingItems);
            ce->init();
            DumpState(ce, game, base + ".cannot");
            delete ce;
          }
        }
        s->save("debpost.sav");
        CopyFileBinary(folder + "debpost.sav", base + ".post.sav");
        if (pixels) {
          // the screens that btnOkClick pushes, after the save (isPromoted and makeOld change the soldiers)
          if (st->_promotions) {
            PromotionsState* ps = new PromotionsState();
            ps->init();
            DumpState(ps, game, base + ".promo");
            delete ps;
          }
          if (st->_base && !st->_destroyBase) {
            ManageAlienContainmentState* ms = new ManageAlienContainmentState(st->_base, OPT_BATTLESCAPE);
            ms->init();
            DumpState(ms, game, base + ".contain");
            delete ms;
            std::vector<Soldier*> alive, dead;
            AwardTestMedals(game, st->_base, alive, dead);
            if (!dead.empty()) {
              CommendationLateState* cl = new CommendationLateState(dead);
              cl->init();
              DumpState(cl, game, base + ".commlate");
              delete cl;
            }
            if (!alive.empty()) {
              CommendationState* cs = new CommendationState(alive);
              cs->init();
              DumpState(cs, game, base + ".comm");
              delete cs;
            }
            RemoveTestMedals(game);
          }
        }
        delete st;
        done++;
      }
    }
  } catch (std::exception& e) {
    fprintf(stderr, "EXCEPTION: %s\n", e.what());
    return 1;
  }
  fprintf(stderr, "ok (%d outcomes)\n", done);
  return 0;
}
