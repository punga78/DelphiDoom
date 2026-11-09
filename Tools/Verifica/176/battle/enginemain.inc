// the questions and main of enginegen.cpp (TileEngine): light, field of view, blockage, lines of fire, voxels
static unsigned HashStep(unsigned h, const Position& p) { return h * 31u + (unsigned)(p.x * 7 + p.y * 13 + p.z); }

static std::string TrajText(const std::vector<Position>& t) {
  std::ostringstream o;
  unsigned h = 17;
  for (size_t i = 0; i < t.size(); i++) h = HashStep(h, t[i]);
  o << "n=" << t.size();
  if (!t.empty()) o << " first=" << t.front().x << "/" << t.front().y << "/" << t.front().z << " last=" << t.back().x << "/" << t.back().y << "/" << t.back().z;
  o << " h=" << h;
  return o.str();
}

static std::string MapText(SavedBattleGame* b, int what) {
  std::ostringstream o;
  for (int i = 0; i < b->getMapSizeXYZ(); i++) {
    Tile* t = b->_tiles[i];
    int v = 0;
    if (what == 0) v = t->getShade();
    else v = t->getVisible() * 8 + (t->_discovered[0] ? 1 : 0) + (t->_discovered[1] ? 2 : 0) + (t->_discovered[2] ? 4 : 0);
    o << v << ",";
  }
  return o.str();
}

int main(int argc, char** argv) {
  if (argc < 7) { fprintf(stderr, "usage: enginegen <data> <user> <out folder> <count> <seed> <LOFTEMPS.DAT>\n"); return 2; }
  std::string data = argv[1], user = argv[2], out = argv[3];
  int count = atoi(argv[4]);
  uint64_t seed = (uint64_t)atoll(argv[5]);
  std::vector<Uint16> voxels;
  {
    std::ifstream in(argv[6], std::ios::binary);
    std::vector<char> bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    for (size_t i = 0; i + 1 < bytes.size(); i += 2) voxels.push_back((Uint8)bytes[i] | ((Uint8)bytes[i + 1] << 8));
  }
  static char a0[] = "enginegen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
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
      snprintf(name, sizeof name, "engine%02d", v);
      std::string base = out + "/" + name;
      WriteNode(base + ".yml", b->save());
      TileEngine* te = new TileEngine(b, &voxels);
      b->_tileEngine = te;
      b->_pathfinding = new Pathfinding(b);
      std::ostringstream res;
      int sx = b->_mapsize_x, sy = b->_mapsize_y, sz = b->_mapsize_z;
      // light
      for (int k = 0; k < 4; k++) {
        int shade = k == 0 ? 0 : (k == 1 ? 4 : (k == 2 ? 9 : 15));
        b->setGlobalShade(shade);
        te->calculateSunShading();
        te->calculateTerrainLighting();
        te->calculateUnitLighting();
        res << "light " << shade << " = " << MapText(b, 0) << "\n";
      }
      // field of view of every unit in order
      b->setGlobalShade(Pick(16));
      te->calculateSunShading();
      te->calculateTerrainLighting();
      te->calculateUnitLighting();
      res << "shade " << b->getGlobalShade() << "\n";
      for (size_t ui = 0; ui < units.size(); ui++) {
        BattleUnit* u = units[ui];
        bool r = te->calculateFOV(u);
        res << "fov " << u->getId() << " = " << (r ? 1 : 0) << " units=";
        for (size_t k = 0; k < u->getVisibleUnits()->size(); k++) res << (*u->getVisibleUnits())[k]->getId() << ",";
        res << " spotted=" << u->getUnitsSpottedThisTurn().size() << " map=" << MapText(b, 1) << "\n";
      }
      te->recalculateFOV();
      res << "fovall map=" << MapText(b, 1) << "\n";
      for (size_t ui = 0; ui < units.size(); ui++) {
        BattleUnit* u = units[ui];
        res << "visible " << u->getId() << " =";
        for (size_t oi = 0; oi < units.size(); oi++)
          if (oi != ui && units[oi]->getTile()) res << " " << (te->visible(u, units[oi]->getTile()) ? 1 : 0);
        res << " tilesvis=" << u->getVisibleTiles()->size() << "\n";
        for (size_t oi = 0; oi < units.size(); oi++) {
          if (oi == ui || !units[oi]->getTile()) continue;
          Position o = te->getSightOriginVoxel(u);
          Position sc;
          bool can = te->canTargetUnit(&o, units[oi]->getTile(), &sc, u, false);
          int ex = te->checkVoxelExposure(&o, units[oi]->getTile(), u, 0);
          res << "target " << u->getId() << " " << units[oi]->getId() << " = " << (can ? 1 : 0) << " scan=" << (can ? sc.x : 0) << "/" << (can ? sc.y : 0) << "/" << (can ? sc.z : 0) << " exposure=" << ex << " origin=" << o.x << "/" << o.y << "/" << o.z << "\n";
        }
      }
      // blockage between adjacent tiles
      for (int q = 0; q < 60; q++) {
        Position a(Pick(sx), Pick(sy), Pick(sz));
        int dir = Pick(10);
        Position d;
        Pathfinding::directionToVector(dir, &d);
        Position e = a + d;
        Tile* ta = b->getTile(a);
        Tile* tb = b->getTile(e);
        int type = Pick(10);
        bool skip = Pick(2) == 0;
        res << "block " << a.x << " " << a.y << " " << a.z << " " << dir << " " << type << " " << (skip ? 1 : 0) << " = h" << te->horizontalBlockage(ta, tb, (ItemDamageType)type, skip)
            << " v" << te->verticalBlockage(ta, tb, (ItemDamageType)type, skip) << "\n";
      }
      // lines and voxels
      for (int q = 0; q < 60; q++) {
        Position o(Pick(sx * 16), Pick(sy * 16), Pick(sz * 24));
        Position t(Pick(sx * 16), Pick(sy * 16), Pick(sz * 24));
        BattleUnit* ex = Pick(2) ? 0 : units[Pick(units.size())];
        bool store = Pick(2) == 0;
        bool vox = Pick(4) != 0;
        std::vector<Position> traj;
        int r = te->calculateLine(o, t, store, &traj, ex, vox);
        res << "line " << o.x << " " << o.y << " " << o.z << " " << t.x << " " << t.y << " " << t.z << " " << (ex ? ex->getId() : 0) << " " << (store ? 1 : 0) << " " << (vox ? 1 : 0) << " = " << r << " " << TrajText(traj) << "\n";
      }
      for (int q = 0; q < 80; q++) {
        Position p(Pick(sx * 16), Pick(sy * 16), Pick(sz * 24));
        res << "voxel " << p.x << " " << p.y << " " << p.z << " = " << te->voxelCheck(p, 0) << " shade=" << te->castedShade(p) << " vis=" << (te->isVoxelVisible(p) ? 1 : 0) << "\n";
      }
      for (int q = 0; q < 30; q++) {
        Position o(Pick(sx * 16), Pick(sy * 16), 8 + Pick(sz * 24 - 8));
        Position t(Pick(sx * 16), Pick(sy * 16), Pick(sz * 24));
        double curve = 1.0 + 0.5 * Pick(5);
        Position delta(Pick(5) - 2, Pick(5) - 2, Pick(5) - 2);
        bool store = Pick(2) == 0;
        std::vector<Position> traj;
        int r = te->calculateParabola(o, t, store, &traj, 0, curve, delta);
        res << "parabola " << o.x << " " << o.y << " " << o.z << " " << t.x << " " << t.y << " " << t.z << " " << (int)(curve * 10) << " " << delta.x << " " << delta.y << " " << delta.z << " " << (store ? 1 : 0) << " = " << r << " " << TrajText(traj) << "\n";
      }
      for (int q = 0; q < 20; q++) {
        Position a(Pick(sx), Pick(sy), Pick(sz)), c(Pick(sx), Pick(sy), Pick(sz));
        res << "dist " << a.x << " " << a.y << " " << a.z << " " << c.x << " " << c.y << " " << c.z << " = " << te->distance(a, c) << " " << te->distanceSq(a, c) << " " << te->distanceSq(a, c, false) << "\n";
      }
      res << "doors = " << te->closeUfoDoors() << " map=" << MapText(b, 1) << "\n";
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
