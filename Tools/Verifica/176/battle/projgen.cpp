// Harness for Libs\XcomBattle (Projectile and the parts of TileEngine that use a BattlescapeGame): the REAL objects of the
// OpenXcom build (see build.cmd) answer, on the maps of enginegen (BuildMap), questions about
//   getOriginVoxel, getDirectionTo, validateThrow (with ProjectileFlyBState::validThrowRange),
//   Projectile (calculateTrajectory, calculateThrow, applyAccuracy, move, the getters) and TileEngine::hit.
// The BattlescapeGame/BattlescapeState that the code asks for are blocks of zeroed memory with only the fields these
// calls read (the panic flag, the current action, the reserved action, a list of states that gets the pushed
// ExplosionBState). Contains no OpenXcom code.
// usage: projgen <data> <user> <out folder> <count> <seed> <LOFTEMPS.DAT> [first]
#define NO_ENGINE_MAIN
#include <windows.h>
#include <setjmp.h>
#include "enginegen.cpp"
#define private public
#define protected public
#include "Mod/RuleItem.h"
#include "Mod/Armor.h"
#include "Engine/SurfaceSet.h"
#include "Battlescape/Projectile.h"
#include "Battlescape/ProjectileFlyBState.h"
#include "Battlescape/BattlescapeGame.h"
#include "Battlescape/BattlescapeState.h"
#include "Battlescape/ExplosionBState.h"
#include "Battlescape/BattleState.h"
#undef protected
#undef private
#undef main

static std::string Fmt(const char* f, ...) {
  char buf[512];
  va_list a;
  va_start(a, f);
  vsnprintf(buf, sizeof buf, f, a);
  va_end(a);
  return buf;
}

static std::string P3(const Position& p) { return Fmt("%d/%d/%d", p.x, p.y, p.z); }

static unsigned long ObstacleSum(SavedBattleGame* b) {
  unsigned long h = 0;
  for (int i = 0; i < b->getMapSizeXYZ(); i++) h = h * 31u + (unsigned)b->_tiles[i]->_obstacle;
  return h;
}

// the real validateThrow takes trajectory.back() of an arc that may be empty (undefined behaviour: it crashes)
static jmp_buf g_jump;
static volatile bool g_guard = false;
static LONG WINAPI CrashFilter(EXCEPTION_POINTERS*) {
  if (g_guard) longjmp(g_jump, 1);
  return EXCEPTION_CONTINUE_SEARCH;
}
static bool ArcsAreSafe(TileEngine* te, const Position& o, const Position& t, BattleUnit* actor) {
  SetUnhandledExceptionFilter(CrashFilter);
  g_guard = true;
  if (setjmp(g_jump) != 0) { g_guard = false; return false; }
  for (int k = 1; k <= 9; k++) {
    std::vector<Position> traj;
    if (getenv("PROJ_TRACE")) { fprintf(stderr, " arc k=%d o=%d/%d/%d t=%d/%d/%d actor=%d\n", k, o.x, o.y, o.z, t.x, t.y, t.z, actor->getId()); fflush(stderr); }
    te->calculateParabola(o, t, true, &traj, actor, 0.5 * k, Position(0, 0, 0));
    if (traj.empty()) { g_guard = false; return false; }
  }
  g_guard = false;
  return true;
}

int main(int argc, char** argv) {
  if (argc < 7) { fprintf(stderr, "usage: projgen <data> <user> <out folder> <count> <seed> <LOFTEMPS.DAT>\n"); return 2; }
  std::string data = argv[1], user = argv[2], out = argv[3];
  int count = atoi(argv[4]);
  uint64_t seed = (uint64_t)atoll(argv[5]);
  std::vector<Uint16> voxels;
  {
    std::ifstream in(argv[6], std::ios::binary);
    std::vector<char> bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    for (size_t i = 0; i + 1 < bytes.size(); i += 2) voxels.push_back((Uint8)bytes[i] | ((Uint8)bytes[i + 1] << 8));
  }
  static char a0[] = "projgen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
  std::string cfg = user;
  char* args[] = {a0, a1, (char*)data.c_str(), a3, (char*)user.c_str(), a5, (char*)cfg.c_str()};
  Logger::reportingLevel() = LOG_ERROR;
  if (!Options::init(7, args)) return 3;
  try {
    Options::updateMods();
    Mod::resetGlobalStatics();
    Mod* mod = new Mod();
    mod->loadAll(FileMap::getRulesets());
    if (mod->_sets.find("FLOOROB.PCK") == mod->_sets.end()) {
      SurfaceSet* fs = new SurfaceSet(32, 40);
      for (int i = 0; i < 400; i++) fs->addFrame(i);
      mod->_sets["FLOOROB.PCK"] = fs;
    }
    std::vector<std::string> firearms, grenades, anyitems;
    for (std::map<std::string, RuleItem*>::iterator i = mod->_items.begin(); i != mod->_items.end(); ++i) {
      BattleType t = i->second->getBattleType();
      if (t == BT_FIREARM && !i->second->getCompatibleAmmo()->empty()) firearms.push_back(i->first);
      if (t == BT_GRENADE) grenades.push_back(i->first);
      if (i->second->getFloorSprite() > -1 && i->second->getWeight() > 0) anyitems.push_back(i->first);
    }
    int first = argc > 7 ? atoi(argv[7]) : 0;  // the scenario to start from (a crash of the real code loses only that one)
    for (int v = first; v < first + count; v++) {
      RNG::setSeed(seed + v);
      SavedGame* s = mod->newSave();
      SavedBattleGame* b = new SavedBattleGame();
      std::vector<BattleUnit*> units;
      BuildMap(mod, s, b, units);
      b->_depth = 0;  // the vapor trail of a shot under water draws on the map
      char name[64];
      snprintf(name, sizeof name, "proj%02d", v);
      std::string base = out + "/" + name;
      WriteNode(base + ".yml", b->save());
      TileEngine* te = new TileEngine(b, &voxels);
      b->_tileEngine = te;
      b->_pathfinding = new Pathfinding(b);
      BattlescapeGame* bg = (BattlescapeGame*)calloc(1, sizeof(BattlescapeGame));
      new (&bg->_states) std::list<BattleState*>();
      new (&bg->_deleted) std::list<BattleState*>();
      new (&bg->_currentAction.waypoints) std::list<Position>();
      new (&bg->_currentAction.result) std::string();
      new (&bg->_infoboxQueue) std::vector<InfoboxOKState*>();
      bg->_save = b;
      bg->_playerPanicHandled = Pick(3) != 0;
      BattlescapeState* bst = (BattlescapeState*)calloc(1, sizeof(BattlescapeState));
      bst->_battleGame = bg;
      b->_battleState = bst;
      bg->_states.push_back(new BattleState(bg));
      b->_tuReserved = (BattleActionType)(Pick(2) ? BA_NONE : BA_SNAPSHOT + Pick(3));
      std::ostringstream res;
      res << "panic " << (bg->_playerPanicHandled ? 1 : 0) << " reserved " << (int)b->_tuReserved << "\n";
      int sx = b->_mapsize_x, sy = b->_mapsize_y, sz = b->_mapsize_z;
      int itemId = 90000;
      for (int q = 0; q < 160; q++) {
        int kind = Pick(10);
        BattleUnit* u = units[Pick(units.size())];
        if (getenv("PROJ_TRACE")) { fprintf(stderr, "q%d kind %d\n", q, kind); fflush(stderr); }
        if (kind == 0) {
          // direction
          Position a(Pick(sx), Pick(sy), Pick(sz)), c(Pick(sx), Pick(sy), Pick(sz));
          res << "dir " << a.x << " " << a.y << " " << a.z << " " << c.x << " " << c.y << " " << c.z << " = " << te->getDirectionTo(a, c) << "\n";
        } else if (kind == 1) {
          // origin voxel of an action
          BattleAction act;
          int types[4] = {BA_THROW, BA_AUTOSHOT, BA_LAUNCH, BA_SNAPSHOT};
          act.type = (BattleActionType)types[Pick(4)];
          act.actor = u;
          act.target = Position(Pick(sx), Pick(sy), Pick(sz));
          std::string wname = grenades.empty() ? firearms[0] : grenades[Pick(grenades.size())];
          Position ot(-1, -1, -1);
          Tile* t = 0;
          if (Pick(2)) { ot = Position(Pick(sx), Pick(sy), Pick(sz)); t = b->getTile(ot); }
          if (act.actor->getTile() == 0) { res << "skip\n"; continue; }
          if (!t && act.type == BA_LAUNCH && Pick(2)) { /* launch from a tile that is not the unit's */ }
          Position r = te->getOriginVoxel(act, t);
          res << "origin " << u->getId() << " " << (int)act.type << " " << P3(act.target) << " " << P3(ot) << " = " << P3(r) << "\n";
        } else if (kind == 2 || kind == 3) {
          // validateThrow
          BattleAction act;
          act.type = kind == 2 ? BA_THROW : (Pick(2) ? BA_AUTOSHOT : BA_LAUNCH);
          act.actor = u;
          act.target = Position(Pick(sx), Pick(sy), Pick(sz));
          std::string wname = act.type == BA_THROW ? anyitems[Pick(anyitems.size())] : firearms[Pick(firearms.size())];
          BattleItem* w = new BattleItem(mod->getItem(wname), &itemId);
          act.weapon = w;
          if (u->getTile() == 0) { res << "skip\n"; continue; }
          Position ov = te->getOriginVoxel(act, 0);
          Position tv = act.target * Position(16, 16, 24) + Position(8, 8, 1 + Pick(20));
          bool forced = Pick(8) == 0;
          double curve = -1.0;
          int vt = -2;
          b->_tiles[0]->resetObstacle();
          for (int i = 0; i < b->getMapSizeXYZ(); i++) b->_tiles[i]->resetObstacle();
          if (!ArcsAreSafe(te, ov, tv, u)) { res << "skip\n"; delete w; continue; }
          if (getenv("PROJ_TRACE")) { fprintf(stderr, " validate %s type %d ov %s tv %s kneel %d\n", wname.c_str(), (int)act.type, P3(ov).c_str(), P3(tv).c_str(), (int)u->isKneeled()); fflush(stderr); }
          bool r = te->validateThrow(act, ov, tv, &curve, &vt, forced);
          res << "throw " << u->getId() << " " << wname << " " << (int)act.type << " " << P3(act.target) << " " << P3(ov) << " " << P3(tv) << " " << (forced ? 1 : 0)
              << " = " << (r ? 1 : 0) << " " << Fmt("%.9f", curve) << " " << vt << " obst=" << ObstacleSum(b) << "\n";
          delete w;
        } else if (kind >= 4 && kind <= 7) {
          // a projectile
          BattleAction act;
          int types[7] = {BA_THROW, BA_AUTOSHOT, BA_SNAPSHOT, BA_AIMEDSHOT, BA_LAUNCH, BA_HIT, BA_THROW};
          int ti = Pick(7);
          act.type = (BattleActionType)types[ti];
          act.actor = u;
          act.target = Position(Pick(sx), Pick(sy), Pick(sz));
          act.autoShotCounter = Pick(3) == 0 ? 2 : 1;
          if (act.type == BA_LAUNCH) { int nw = Pick(3); for (int k = 0; k < nw; k++) act.waypoints.push_back(Position(Pick(sx), Pick(sy), Pick(sz))); }
          std::string wname = act.type == BA_THROW ? anyitems[Pick(anyitems.size())] : firearms[Pick(firearms.size())];
          BattleItem* w = new BattleItem(mod->getItem(wname), &itemId);
          std::string aname = "-";
          BattleItem* ammo = 0;
          if (act.type != BA_THROW && !w->getRules()->getCompatibleAmmo()->empty() && Pick(4) != 0) {
            aname = (*w->getRules()->getCompatibleAmmo())[0];
            ammo = new BattleItem(mod->getItem(aname), &itemId);
            w->setAmmoItem(ammo);
          } else if (act.type != BA_THROW && Pick(5) == 0) {
            ammo = w;  // a weapon that is its own ammo
            aname = "self";
          }
          act.weapon = w;
          if (u->getTile() == 0) { res << "skip\n"; continue; }
          int mode = Pick(4);  // 0 calculateTrajectory(acc), 1 with the origin voxel, 2 calculateThrow, 3 applyAccuracy
          if (act.type == BA_THROW || act.type == BA_LAUNCH) mode = Pick(3) == 0 ? 0 : 2;
          if (act.type == BA_HIT && mode == 2) mode = 0;
          Position ov = te->getOriginVoxel(act, 0);
          Position tv = act.target * Position(16, 16, 24) + Position(Pick(16), Pick(16), Pick(24));
          bool exclude = Pick(2) == 0;
          int accuracy = Pick(130);
          int rseed = 1000 + Pick(100000);
          bool keep = Pick(2) == 0, ext = Pick(2) == 0;
          RNG::setSeed(rseed);
          for (int i = 0; i < b->getMapSizeXYZ(); i++) b->_tiles[i]->resetObstacle();
          if (mode == 2 && !ArcsAreSafe(te, ov, tv, u)) { res << "skip\n"; if (ammo && ammo != w) delete ammo; delete w; continue; }
          Projectile* p = new Projectile(mod, b, act, u->getPosition(), tv, ammo);
          int r = 0;
          Position nt = tv;
          if (mode == 0) r = p->calculateTrajectory(accuracy / 100.0);
          else if (mode == 1) r = p->calculateTrajectory(accuracy / 100.0, ov, exclude);
          else if (mode == 2) r = p->calculateThrow(accuracy / 100.0);
          else { p->applyAccuracy(ov, &nt, accuracy / 100.0, keep, ext); r = 0; }
          res << "proj " << u->getId() << " " << wname << " " << aname << " " << (int)act.type << " " << act.autoShotCounter << " " << P3(act.target) << " " << P3(tv) << " " << mode << " " << accuracy << " " << rseed << " " << (exclude ? 1 : 0)
              << " " << act.waypoints.size() << " " << (int)b->_tuReserved << " " << P3(ov) << " " << (keep ? 1 : 0) << " " << (ext ? 1 : 0) << " ";
          if (mode == 3) res << "= nt=" << P3(nt) << " rng=" << RNG::getSeed() << "\n";
          else {
            res << "= " << r << " " << TrajText(p->_trajectory) << " rng=" << RNG::getSeed() << " obst=" << ObstacleSum(b) << " speed=" << p->_speed << " tv=" << P3(p->_targetVoxel) << " rev=" << (p->isReversed() ? 1 : 0)
                << " part=" << p->getParticle(2) << " rangesprite=" << ((act.type == BA_THROW && p->getItem()) ? p->getItem()->getRules()->getFloorSprite() : -9);
            if (!p->_trajectory.empty()) {
              res << " org=" << P3(p->getOrigin()) << " tgt=" << P3(p->getTarget());
              int steps = 0;
              while (p->move() && steps < 5000) steps++;
              res << " steps=" << steps << " pos=" << P3(p->getPosition(0)) << " pos-2=" << P3(p->getPosition(-2)) << " pos+3=" << P3(p->getPosition(3)) << " rng2=" << RNG::getSeed();
            }
            res << "\n";
          }
          delete p;
          if (ammo && ammo != w) delete ammo;
          delete w;
        } else {
          // a hit on a voxel: near a unit most of the time
          Position c(Pick(sx * 16), Pick(sy * 16), Pick(sz * 24));
          if (Pick(4) != 0) {
            BattleUnit* at = units[Pick(units.size())];
            int size = at->getArmor()->getSize();
            c = Position(at->getPosition().x * 16 + Pick(16 * size), at->getPosition().y * 16 + Pick(16 * size), at->getPosition().z * 24 + Pick(24));
          }
          int type = Pick(10);
          int power = 10 + Pick(130);
          BattleUnit* who = Pick(2) ? 0 : units[Pick(units.size())];
          int hseed = 1000 + Pick(100000);
          int curType = Pick(2) ? BA_NONE : BA_HIT;
          bg->_currentAction.type = (BattleActionType)curType;
          RNG::setSeed(hseed);
          size_t before = bg->_states.size();
          BattleUnit* hitu = te->hit(c, power, (ItemDamageType)type, who);
          res << "hit " << P3(c) << " " << type << " " << power << " " << (who ? who->getId() : 0) << " " << hseed << " " << curType << " = u" << (hitu ? hitu->getId() : 0) << " rng=" << RNG::getSeed()
              << " obj=" << b->_objectivesDestroyed << " pushed=" << (bg->_states.size() - before);
          {
            size_t k = 0;
            for (std::list<BattleState*>::iterator i = bg->_states.begin(); i != bg->_states.end(); ++i, ++k) {
              ExplosionBState* e = dynamic_cast<ExplosionBState*>(*i);
              if (e && k > 0) res << " explosion@" << P3(e->_center);
            }
          }
          res << " " << StateText(b) << "\n";
          // drop what the hit pushed so that the next question counts from the sentinel again
          while (bg->_states.size() > 1) bg->_states.pop_back();
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
