// Harness for Libs\XcomMod: loads random rule nodes with the REAL OpenXcom rule classes and the real yaml-cpp.
// Contains no OpenXcom code; output stays outside the repository (only the golden is committed).
#include <yaml-cpp/yaml.h>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <map>
#include <random>
#include <sstream>
#include <vector>
#include <string>
#include <set>
#include <algorithm>
#include <memory>
#include <utility>
#include <sstream>
#define private public
#include "Mod/RuleInventory.h"
#include "Mod/Mod.h"
#include "Mod/RuleCraftWeapon.h"
#undef main
#include "Mod/RuleCountry.h"
#include "Mod/RuleRegion.h"
#include "Mod/RuleResearch.h"
#include "Mod/RuleManufacture.h"
#include "Mod/AlienRace.h"
#include "Mod/UfoTrajectory.h"
#include "Mod/RuleMusic.h"
#include "Battlescape/Position.h"
#include "Mod/MapBlock.h"
#include "Mod/RuleCommendations.h"
#include "Engine/RNG.h"
#include "Engine/Exception.h"
#include "Savegame/WeightedOptions.h"
#undef private

using namespace OpenXcom;

static std::mt19937 rng;
static int R(int n) { return (int)(rng() % (unsigned)n); }
static int Rg(int lo, int hi) { return lo + R(hi - lo + 1); }

static std::string Esc(const std::string& s) {
  std::string r;
  char buf[8];
  for (unsigned char c : s) {
    if (c == '\\') r += "\\\\";
    else if (c == '\n') r += "\\n";
    else if (c < 32 || c >= 127) { snprintf(buf, sizeof buf, "\\x%02X", c); r += buf; }
    else r += (char)c;
  }
  return r;
}
static std::string D(double v) {
  unsigned long long b;
  memcpy(&b, &v, 8);
  char buf[40];
  snprintf(buf, sizeof buf, "%016llX", b);
  return buf;
}

// ---------------- generation ----------------
static const char* Words[] = {"STR_ALPHA", "STR_BETA", "STR_GAMMA", "x", "y", "a b", "STR_LONG_NAME_1", "é", "7", "true", "null"};
static std::string W() { return Words[R(sizeof Words / sizeof *Words)]; }
static std::string Num() {
  switch (R(8)) {
    case 0: return std::to_string(Rg(-5, 5));
    case 1: return std::to_string(Rg(0, 300));
    case 2: return std::to_string(Rg(-100000, 100000));
    case 3: return "2147483647";
    case 4: return "0x10";
    case 5: return "-1";
    default: return std::to_string(Rg(0, 40));
  }
}
static std::string Dbl() {
  switch (R(6)) {
    case 0: return std::to_string(Rg(-180, 180));
    case 1: return std::to_string(Rg(-90, 90)) + "." + std::to_string(Rg(0, 99));
    case 2: return "0";
    case 3: return std::to_string(Rg(0, 360)) + ".5";
    case 4: return "1e2";
    default: return std::to_string(Rg(-180, 180)) + "." + std::to_string(Rg(0, 999));
  }
}
static std::string Bad() {
  switch (R(5)) {
    case 0: return "[1, 2]";
    case 1: return "{k: v}";
    case 2: return "abc";
    case 3: return "~";
    default: return "";
  }
}
static std::string Gen(char kind) {
  bool bad = R(14) == 0;
  switch (kind) {
    case 'i': return bad ? Bad() : Num();
    case 'd': return bad ? Bad() : Dbl();
    case 'b': return bad ? Bad() : (R(2) ? "true" : (R(2) ? "no" : "false"));
    case 's': return bad && R(2) ? Bad() : W();
    case 'S': {  // string list
      if (bad) return Bad();
      std::string r = "[";
      int n = R(5);
      for (int i = 0; i < n; i++) { if (i) r += ", "; r += W(); }
      return r + "]";
    }
    case 'M': {  // string -> int map
      if (bad) return Bad();
      std::string r = "{";
      int n = R(4);
      for (int i = 0; i < n; i++) { if (i) r += ", "; r += W() + ": " + Num(); }
      return r + "}";
    }
    case 'A': {  // areas: list of 4 numbers
      if (bad) return Bad();
      std::string r = "[";
      int n = R(4);
      for (int i = 0; i < n; i++) {
        if (i) r += ", ";
        r += "[" + Dbl() + ", " + Dbl() + ", " + Dbl() + ", " + Dbl();
        if (R(8) == 0) r += ", " + Num();
        r += "]";
      }
      return r + "]";
    }
    case 'Z': {  // mission zones: list of lists of areas
      if (bad) return Bad();
      std::string r = "[";
      int n = R(3);
      for (int i = 0; i < n; i++) {
        if (i) r += ", ";
        r += "[";
        int m = R(3);
        for (int j = 0; j < m; j++) {
          if (j) r += ", ";
          r += "[" + Dbl() + ", " + Dbl() + ", " + Dbl() + ", " + Dbl();
          if (R(3) == 0) r += ", " + Num() + ", " + W();
          r += "]";
        }
        r += "]";
      }
      return r + "]";
    }
    case 'L': {  // slots: list of [x, y]
      if (bad) return Bad();
      std::string r = "[";
      int n = R(8);
      for (int i = 0; i < n; i++) { if (i) r += ", "; r += "[" + std::to_string(Rg(0, 8)) + ", " + std::to_string(Rg(0, 5)) + "]"; }
      return r + "]";
    }
    case 'T': {  // waypoints
      if (bad) return Bad();
      std::string r = "[";
      int n = R(5);
      for (int i = 0; i < n; i++) {
        if (i) r += ", ";
        r += "[" + std::to_string(Rg(0, 6)) + ", " + std::to_string(Rg(0, 4)) + ", " + std::to_string(Rg(0, 100)) + "]";
      }
      return r + "]";
    }
    case 'F': {  // float
      if (bad) return Bad();
      switch (R(5)) { case 0: return "0.76"; case 1: return "1"; case 2: return "-2.5"; case 3: return "3.14159"; default: return Dbl(); }
    }
    case 'G': {  // list of ints, a scalar int, or bad
      if (bad) return Bad();
      if (R(3) == 0) return Num();
      std::string r = "[";
      int n = R(5);
      for (int i = 0; i < n; i++) { if (i) r += ", "; r += Num(); }
      return r + "]";
    }
    case 'P': {  // map string -> list of positions
      if (bad) return Bad();
      std::string r = "{";
      int n = R(3);
      for (int i = 0; i < n; i++) {
        if (i) r += ", ";
        r += W() + ": [";
        int m = R(3);
        for (int j = 0; j < m; j++) { if (j) r += ", "; r += "[" + Num() + ", " + Num() + ", " + Num() + "]"; }
        r += "]";
      }
      return r + "}";
    }
    case 'C': {  // map string -> list of ints
      if (bad) return Bad();
      std::string r = "{";
      int n = R(3);
      for (int i = 0; i < n; i++) {
        if (i) r += ", ";
        r += W() + ": [";
        int m = R(4);
        for (int j = 0; j < m; j++) { if (j) r += ", "; r += Num(); }
        r += "]";
      }
      return r + "}";
    }
    case 'K': {  // kill criteria: list of lists of [int, [strings]]
      if (bad) return Bad();
      std::string r = "[";
      int n = R(3);
      for (int i = 0; i < n; i++) {
        if (i) r += ", ";
        r += "[";
        int m = R(3);
        for (int j = 0; j < m; j++) {
          if (j) r += ", ";
          r += "[" + Num() + ", [";
          int k = R(3);
          for (int q = 0; q < k; q++) { if (q) r += ", "; r += W(); }
          r += "]]";
          if (R(20) == 0) r = r.substr(0, r.size() - 1) + ", 1]";
        }
        r += "]";
      }
      return r + "]";
    }
    case 'O': {  // an offset: a number, or {index, mod}
      if (bad) return Bad();
      if (R(3)) return std::to_string(Rg(-3, 60));
      static const char* mods[] = {"master", "current", "xcom1", "nomod"};
      std::string r = "{";
      if (R(10)) r += "index: " + std::to_string(Rg(-3, 700));
      if (R(10)) r += std::string(r.size() > 1 ? ", " : "") + "mod: " + mods[R(4)];
      return r + "}";
    }    case 'W': {  // weights map string -> size_t
      if (bad) return Bad();
      std::string r = "{";
      int n = R(4);
      for (int i = 0; i < n; i++) { if (i) r += ", "; r += W() + ": " + std::to_string(Rg(0, 50)); }
      return r + "}";
    }
  }
  return "";
}

struct Field { const char* key; char kind; };
static std::string Doc(const std::vector<Field>& fields) {
  std::string out;
  std::vector<int> order;
  for (size_t i = 0; i < fields.size(); i++) if (R(10) < 8) order.push_back((int)i);
  for (size_t i = order.size(); i > 1; i--) std::swap(order[i - 1], order[R((int)i)]);
  for (int i : order) {
    std::string v = Gen(fields[i].kind);
    out += std::string(fields[i].key) + ":" + (v.empty() ? "" : " " + v) + "\n";
    if (R(15) == 0) out += std::string(fields[i].key) + ": " + Gen(fields[i].kind) + "\n";  // repeated key
  }
  return out;
}

static void Case(std::ostream& corpus, const std::string& header, const std::string& body) {
  corpus << "%%%%\n" << header << "\n" << body;
  if (body.empty() || body.back() != '\n') corpus << "\n";
}

static void Generate(const char* path, int count, unsigned seed) {
  rng.seed(seed);
  std::ofstream o(path, std::ios::binary);
  o << "# corpus of the rule classes: a case is a header line (kind, extra arguments) and a YAML node\n";
  for (int i = 0; i < count; i++) {
    switch (R(11)) {
      case 0: Case(o, "inventory " + std::to_string(Rg(0, 9)), Doc({{"id", 's'}, {"x", 'i'}, {"y", 'i'}, {"type", 'i'}, {"slots", 'L'}, {"costs", 'M'}, {"listOrder", 'i'}})); break;
      case 1: Case(o, "country " + std::string(R(2) ? "STR_USA" : "STR_X"), Doc({{"type", 's'}, {"fundingBase", 'i'}, {"fundingCap", 'i'}, {"labelLon", 'd'}, {"labelLat", 'd'}, {"areas", 'A'}})); break;
      case 2: Case(o, "region STR_R", Doc({{"type", 's'}, {"cost", 'i'}, {"areas", 'A'}, {"missionZones", 'Z'}, {"missionWeights", 'W'}, {"regionWeight", 'i'}, {"missionRegion", 's'}})); break;
      case 3: Case(o, "research " + std::string(R(2) ? "STR_TOPIC" : "STR_Q") + " " + std::to_string(Rg(0, 9)), Doc({{"name", 's'}, {"lookup", 's'}, {"cutscene", 's'}, {"cost", 'i'}, {"points", 'i'}, {"dependencies", 'S'}, {"unlocks", 'S'}, {"getOneFree", 'S'}, {"requires", 'S'}, {"needItem", 'b'}, {"destroyItem", 'b'}, {"listOrder", 'i'}})); break;
      case 4: Case(o, "manufacture " + std::string(R(2) ? "STR_ITEM" : "STR_OTHER") + " " + std::to_string(Rg(0, 9)), Doc({{"name", 's'}, {"category", 's'}, {"requires", 'S'}, {"space", 'i'}, {"time", 'i'}, {"cost", 'i'}, {"requiredItems", 'M'}, {"producedItems", 'M'}, {"listOrder", 'i'}})); break;
      case 5: Case(o, "race STR_RACE", Doc({{"id", 's'}, {"members", 'S'}})); break;
      case 6: Case(o, "music STR_MUSIC", Doc({{"name", 's'}, {"catPos", 'i'}, {"normalization", 'F'}})); break;
      case 7: Case(o, "mapblock STR_BLOCK", Doc({{"name", 's'}, {"width", 'i'}, {"length", 'i'}, {"height", 'i'}, {"groups", 'G'}, {"revealedFloors", 'G'}, {"items", 'P'}})); break;
      case 8: Case(o, "commendation", Doc({{"description", 's'}, {"criteria", 'C'}, {"sprite", 'i'}, {"killCriteria", 'K'}})); break;
      case 9: Case(o, "craftweapon STR_CW " + std::to_string(R(3)), Doc({{"type", 's'}, {"sprite", 'O'}, {"sound", 'O'}, {"damage", 'i'}, {"range", 'i'}, {"accuracy", 'i'}, {"reloadCautious", 'i'}, {"reloadStandard", 'i'}, {"reloadAggressive", 'i'}, {"ammoMax", 'i'}, {"rearmRate", 'i'}, {"projectileType", 'i'}, {"projectileSpeed", 'i'}, {"launcher", 's'}, {"clip", 's'}, {"underwaterOnly", 'b'}})); break;
      default: Case(o, "trajectory STR_T", Doc({{"id", 's'}, {"groundTimer", 'i'}, {"waypoints", 'T'}})); break;
    }
  }
}

// ---------------- run ----------------
static uint64_t gState;
static void Line(const char* fmt, ...) {
  va_list a; va_start(a, fmt); vprintf(fmt, a); va_end(a); printf("\n");
}
static std::string StrVec(const std::vector<std::string>& v) {
  std::string r = "[";
  for (auto& s : v) r += Esc(s) + "|";
  return r + "]";
}
static std::string StrMap(const std::map<std::string, int>& m) {
  std::string r = "{";
  for (auto& p : m) r += Esc(p.first) + "=" + std::to_string(p.second) + "|";
  return r + "}";
}

static void RunCase(const std::string& header, const std::string& body) {
  std::istringstream hs(header);
  std::string kind, a1, a2;
  hs >> kind >> a1 >> a2;
  YAML::Node node;
  try {
    node = YAML::Load(body);
  } catch (const YAML::Exception& e) {
    Line("PARSE_ERR");
    return;
  }
  try {
    if (kind == "inventory") {
      RuleInventory r(a1);
      r.load(node, 5);
      Line("id=%s x=%d y=%d type=%d order=%d", Esc(r.getId()).c_str(), r.getX(), r.getY(), (int)r.getType(), r.getListOrder());
      std::string s = "slots=";
      for (auto& sl : *r.getSlots()) s += std::to_string(sl.x) + "," + std::to_string(sl.y) + ";";
      Line("%s", s.c_str());
      std::string inside = "inside=";
      for (int yy = -4; yy < 210; yy += 13)
        for (int xx = -4; xx < 330; xx += 17) { int px = xx, py = yy; inside += r.checkSlotInPosition(&px, &py) ? '1' : '0'; }
      Line("%s", inside.c_str());
      RuleInventory other("STR_ALPHA");
      YAML::Node on = YAML::Load("costs: {STR_ALPHA: 3, " + a1 + ": 4}");
      other.load(on, 1);
      if (r._costs.find(other.getId()) == r._costs.end()) Line("cost=undefined"); else Line("cost=%d", r.getCost(&other));
    } else if (kind == "country") {
      RuleCountry r(a1);
      r.load(node);
      Line("type=%s cap=%d lon=%s lat=%s", Esc(r.getType()).c_str(), r.getFundingCap(), D(r.getLabelLongitude()).c_str(), D(r.getLabelLatitude()).c_str());
      RNG::setSeed(12345);
      if (r._fundingBase * 2 - r._fundingBase + 1 == 0) Line("funding=undefined"); else { int f1 = r.generateFunding(); int f2 = r.generateFunding(); Line("funding=%d %d", f1, f2); }
      std::string inside = "inside=";
      for (int i = 0; i < 60; i++) {
        double lon = (i * 0.37) - 0.5, lat = ((i * 0.53) - 1.7);
        if (i % 7 == 0) lat = 0;
        inside += r.insideCountry(lon, lat) ? '1' : '0';
      }
      Line("%s", inside.c_str());
    } else if (kind == "region") {
      RuleRegion r(a1);
      r.load(node);
      Line("type=%s cost=%d weight=%u mr=%s", Esc(r.getType()).c_str(), r.getBaseCost(), (unsigned)r.getWeight(), Esc(r._missionRegion).c_str());
      std::string inside = "inside=";
      for (int i = 0; i < 60; i++) {
        double lon = (i * 0.37) - 0.5, lat = ((i * 0.53) - 1.7);
        inside += r.insideRegion(lon, lat) ? '1' : '0';
      }
      Line("%s", inside.c_str());
      Line("zones=%d", (int)r._missionZones.size());
      { std::string w = "weights="; for (auto& nm : r._missionWeights.getNames()) w += Esc(nm) + ";"; Line("%s", w.c_str()); RNG::setSeed(99); std::string c = "choose="; for (int k = 0; k < 4; k++) c += Esc(r._missionWeights.choose()) + ";"; Line("%s", c.c_str()); }
      for (size_t z = 0; z < r._missionZones.size(); z++)
        for (auto& ma : r._missionZones[z].areas)
          Line(" area %zu %s %s %s %s name=%s", z, D(ma.lonMin).c_str(), D(ma.lonMax).c_str(), D(ma.latMin).c_str(), D(ma.latMax).c_str(), Esc(ma.name).c_str());
      RNG::setSeed(777);
      for (size_t z = 0; z < r._missionZones.size(); z++) { if (r._missionZones[z].areas.empty()) continue; auto p = r.getRandomPoint(z); Line(" point %zu %s %s", z, D(p.first).c_str(), D(p.second).c_str()); }
    } else if (kind == "research") {
      RuleResearch r(a1);
      r.load(node, atoi(a2.c_str()));
      Line("name=%s cost=%d points=%d order=%d need=%d destroy=%d lookup=%s cut=%s", Esc(r.getName()).c_str(), r.getCost(), r.getPoints(), r.getListOrder(), r.needItem(), r.destroyItem(), Esc(r.getLookup()).c_str(), Esc(r.getCutscene()).c_str());
      Line("dep=%s unl=%s free=%s req=%s", StrVec(r.getDependencies()).c_str(), StrVec(r.getUnlocked()).c_str(), StrVec(r.getGetOneFree()).c_str(), StrVec(r.getRequirements()).c_str());
    } else if (kind == "manufacture") {
      RuleManufacture r(a1);
      r.load(node, atoi(a2.c_str()));
      Line("name=%s cat=%s space=%d time=%d cost=%d order=%d", Esc(r.getName()).c_str(), Esc(r.getCategory()).c_str(), r.getRequiredSpace(), r.getManufactureTime(), r.getManufactureCost(), r.getListOrder());
      Line("req=%s items=%s produced=%s", StrVec(r.getRequirements()).c_str(), StrMap(r.getRequiredItems()).c_str(), StrMap(r.getProducedItems()).c_str());
    } else if (kind == "race") {
      AlienRace r(a1);
      r.load(node);
      Line("id=%s members=%s", Esc(r.getId()).c_str(), StrVec(r._members).c_str());
    } else if (kind == "music") {
      RuleMusic r(a1);
      r.load(node);
      float nf = r.getNormalization(); double nd = nf; unsigned nb; memcpy(&nb, &nf, 4);
      Line("name=%s pos=%d norm=%08X %s", Esc(r.getName()).c_str(), r.getCatPos(), nb, D(nd).c_str());
    } else if (kind == "mapblock") {
      MapBlock r(a1);
      r.load(node);
      std::string g = "groups=", rv = "revealed=", it = "items=";
      for (int x : r._groups) g += std::to_string(x) + ",";
      for (int x : r._revealedFloors) rv += std::to_string(x) + ",";
      for (auto& p : r._items) { it += Esc(p.first) + ":"; for (auto& q : p.second) it += std::to_string(q.x) + "/" + std::to_string(q.y) + "/" + std::to_string(q.z) + ";"; it += "|"; }
      Line("name=%s size=%d,%d,%d", Esc(r.getName()).c_str(), r.getSizeX(), r.getSizeY(), r.getSizeZ());
      Line("%s %s %s", g.c_str(), rv.c_str(), it.c_str());
      std::string in = "in=";
      for (int k = -1; k < 6; k++) { in += r.isInGroup(k) ? '1' : '0'; in += r.isFloorRevealed(k) ? '1' : '0'; }
      Line("%s", in.c_str());
    } else if (kind == "commendation") {
      RuleCommendations r;
      r.load(node);
      std::string c = "criteria=", k = "kill=";
      for (auto& p : r._criteria) { c += Esc(p.first) + ":"; for (int x : p.second) c += std::to_string(x) + ","; c += "|"; }
      for (auto& v : r._killCriteria) { k += "["; for (auto& pr : v) { k += std::to_string(pr.first) + "("; for (auto& s : pr.second) k += Esc(s) + ","; k += ")"; } k += "]"; }
      Line("desc=%s sprite=%d %s %s", Esc(r.getDescription()).c_str(), r.getSprite(), c.c_str(), k.c_str());
    } else if (kind == "craftweapon") {
      // a Mod with only its offset tables: master (offset 0), xcom1 (1000) and the mod that is loading (2000)
      static Mod* mod = 0;
      if (!mod) {
        mod = (Mod*)calloc(1, sizeof(Mod));
        new (&mod->_modData) std::vector<ModData>();
        ModData d;
        d.info = 0;
        d.name = "master"; d.offset = 0; d.size = 1000; mod->_modData.push_back(d);
        d.name = "xcom1"; d.offset = 1000; d.size = 500; mod->_modData.push_back(d);
        d.name = "mymod"; d.offset = 2000; d.size = 300; mod->_modData.push_back(d);
      }
      mod->_modCurrent = &mod->_modData[atoi(a2.c_str())];
      RuleCraftWeapon r(a1);
      r.load(node, mod);
      Line("type=%s sprite=%d sound=%d dmg=%d range=%d acc=%d rc=%d rs=%d ra=%d ammo=%d rearm=%d ptype=%d pspeed=%d water=%d", Esc(r.getType()).c_str(), r.getSprite(), r.getSound(), r.getDamage(), r.getRange(), r.getAccuracy(), r.getCautiousReload(), r.getStandardReload(), r.getAggressiveReload(), r.getAmmoMax(), r.getRearmRate(), (int)r.getProjectileType(), r.getProjectileSpeed(), (int)r._underwaterOnly);
      Line("launcher=%s clip=%s", Esc(r.getLauncherItem()).c_str(), Esc(r.getClipItem()).c_str());    } else if (kind == "trajectory") {
      UfoTrajectory r(a1);
      r.load(node);
      Line("id=%s timer=%u count=%u", Esc(r.getID()).c_str(), (unsigned)r.groundTimer(), (unsigned)r.getWaypointCount());
      for (size_t i = 0; i < r.getWaypointCount(); i++)
        Line(" wp %u %u %u", (unsigned)r.getZone(i), (unsigned)r._waypoints[i].altitude, (unsigned)r._waypoints[i].speed);
    }
  } catch (const YAML::Exception& e) {
    Line("YAML_ERR %s", Esc(e.msg).c_str());
  } catch (const OpenXcom::Exception& e) {
    Line("MOD_ERR %s", Esc(e.what()).c_str());
  } catch (const std::exception& e) {
    Line("STD_ERR");
  }
}

int main(int argc, char** argv) {
  std::string mode = argv[1];
  if (mode == "gen") { Generate(argv[2], atoi(argv[3]), atoi(argv[4])); return 0; }
  std::ifstream f(argv[2], std::ios::binary);
  std::string line, header, body;
  int n = -1;
  bool inCase = false, haveHeader = false;
  auto flush = [&]() {
    if (inCase && haveHeader) { printf("#%d %s\n", n, header.c_str()); RunCase(header, body); }
  };
  while (std::getline(f, line)) {
    if (line == "%%%%") { flush(); n++; inCase = true; haveHeader = false; body.clear(); continue; }
    if (!inCase) continue;
    if (!haveHeader) { header = line; haveHeader = true; continue; }
    body += line + "\n";
  }
  flush();
  return 0;
}
