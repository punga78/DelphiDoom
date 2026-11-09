// Harness for the objects of Libs\XcomSave (second family: Target, Waypoint, AlienBase, MissionSite, Node,
// EquipmentLayoutItem, ...): loads random YAML nodes into the REAL OpenXcom classes (linked from the objects of a
// real OpenXcom build, see build2.cmd) with the real yaml-cpp, saves them and prints the emitted YAML.
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
#include <set>
#include <sstream>
#include <vector>
#include <string>
#include <algorithm>
#include <memory>
#include <utility>
#define private public
#include "Savegame/Waypoint.h"
#include "Savegame/AlienBase.h"
#include "Savegame/MissionSite.h"
#include "Savegame/Node.h"
#include "Savegame/EquipmentLayoutItem.h"
#include "Mod/AlienDeployment.h"
#include "Mod/RuleAlienMission.h"
#undef private
#include "Engine/Exception.h"
#undef main

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
static std::string Num() {
  switch (R(8)) {
    case 0: return std::to_string(Rg(-5, 5));
    case 1: return std::to_string(Rg(0, 300));
    case 2: return std::to_string(Rg(-100000, 100000));
    case 3: return "2147483647";
    case 4: return "-2147483648";
    case 5: return "0x10";
    default: return std::to_string(Rg(0, 40));
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
static std::string Dbl() {
  switch (R(9)) {
    case 0: return "0";
    case 1: return "1.5";
    case 2: return "-0.25";
    case 3: return "3.14159265358979";
    case 4: return "6.5";
    case 5: return ".inf";
    case 6: return "1e3";
    case 7: return std::to_string(Rg(-700, 700) / 100.0);
    default: return std::to_string(Rg(0, 628) / 100.0);
  }
}
static std::string Str() {
  static const char* v[] = {"hello", "STR_FOO", "yes", "123", "a b", "", "with: colon", "#c", "caf\xC3\xA9", "STR_HUMAN", "NONE", "- x", "'q'", "STR_AVALON"};
  return v[R(14)];
}
static std::string Gen(char kind) {
  bool bad = R(14) == 0;
  switch (kind) {
    case 'i': return bad ? Bad() : Num();
    case 'b': return bad ? Bad() : (R(2) ? "true" : (R(2) ? "no" : "false"));
    case 'd': return bad ? Bad() : Dbl();
    case 's': return bad ? Bad() : Str();
    case 'I': {
      if (bad) return Bad();
      std::string r = "[";
      int n = R(6);
      for (int i = 0; i < n; i++) { if (i) r += ", "; r += Num(); }
      return r + "]";
    }
    case 'P': {
      if (bad) return Bad();
      if (R(8) == 0) return "[1, 2]";
      if (R(10) == 0) return "[1, 2, x]";
      return "[" + std::to_string(Rg(0, 60)) + ", " + std::to_string(Rg(0, 60)) + ", " + std::to_string(Rg(0, 3)) + "]";
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
  }
  return out;
}
static void Case(std::ostream& corpus, const std::string& header, const std::string& body) {
  corpus << "%%%%\n" << header << "\n" << body;
  if (body.empty() || body.back() != '\n') corpus << "\n";
}
static std::string Dbits(double v) {
  unsigned long long b;
  memcpy(&b, &v, 8);
  char buf[40];
  snprintf(buf, sizeof buf, "%016llX", b);
  return buf;
}
static double FromBits(const std::string& s) {
  unsigned long long b = strtoull(s.c_str(), 0, 16);
  double v;
  memcpy(&v, &b, 8);
  return v;
}
static std::string RandAngle() {
  double v;
  switch (R(4)) {
    case 0: v = (R(2001) - 1000) / 100.0; break;
    case 1: v = (R(200) - 100) / 7.0; break;
    case 2: v = R(2000) / 1000.0; break;
    default: v = (R(2001) - 1000) / 1000.0 * 3.14159; break;
  }
  return Dbits(v);
}

static std::vector<Field> TargetFields() { return {{"lon", 'd'}, {"lat", 'd'}, {"id", 'i'}, {"name", 's'}}; }

static void Generate(const char* path, int count, unsigned seed) {
  rng.seed(seed);
  std::ofstream o(path, std::ios::binary);
  o << "# corpus of the saved game objects, second family: a header line (kind, arguments) and a YAML node\n";
  for (int i = 0; i < count; i++) {
    switch (R(5)) {
      case 0: Case(o, "waypoint " + RandAngle() + " " + RandAngle() + " " + RandAngle() + " " + RandAngle(), Doc(TargetFields())); break;
      case 1: {
        auto f = TargetFields();
        f.push_back({"race", 's'}); f.push_back({"inBattlescape", 'b'}); f.push_back({"discovered", 'b'});
        Case(o, std::string("alienbase STR_AB_MARK ") + std::to_string(Rg(-1, 9)) + " STR_ALIENBASE_DEP", Doc(f));
        break;
      }
      case 2: {
        auto f = TargetFields();
        f.push_back({"texture", 'i'}); f.push_back({"secondsRemaining", 'i'}); f.push_back({"race", 's'});
        f.push_back({"inBattlescape", 'b'}); f.push_back({"detected", 'b'});
        Case(o, std::string("missionsite STR_SITE_MARK ") + std::to_string(Rg(-1, 9)) + " STR_SITE_DEP STR_MISSION", Doc(f));
        break;
      }
      case 3: Case(o, "node", Doc({{"id", 'i'}, {"position", 'P'}, {"type", 'i'}, {"rank", 'i'}, {"flags", 'i'}, {"reserved", 'i'}, {"priority", 'i'}, {"allocated", 'b'}, {"links", 'I'}, {"dummy", 'b'}})); break;
      default: Case(o, "equip", Doc({{"itemType", 's'}, {"slot", 's'}, {"slotX", 'i'}, {"slotY", 'i'}, {"ammoItem", 's'}, {"fuseTimer", 'i'}})); break;
    }
  }
}

static void Out(const YAML::Node& node) {
  YAML::Emitter out;
  out << node;
  printf("EMIT %s\n", out.good() ? "good" : ("bad:" + Esc(out.GetLastError())).c_str());
  std::istringstream is(out.c_str() ? out.c_str() : "");
  std::string line;
  while (std::getline(is, line)) printf("| %s\n", Esc(line).c_str());
  printf("|.\n");
}

static void TargetOps(Target& t, std::istringstream& hs) {
  std::string a, b, c, d;
  hs >> a >> b >> c >> d;
  printf("ll %s %s id=%d\n", Dbits(t.getLongitude()).c_str(), Dbits(t.getLatitude()).c_str(), t.getId());
  Out(t.save());
  Out(t.saveId());
  t.setLongitude(FromBits(a));
  t.setLatitude(FromBits(b));
  printf("set %s %s\n", Dbits(t.getLongitude()).c_str(), Dbits(t.getLatitude()).c_str());
  printf("dist=%.10g\n", t.getDistance(FromBits(c), FromBits(d)));
  printf("self=%.10g\n", t.getDistance(t.getLongitude(), t.getLatitude()));
  printf("marker=%s id=%d\n", Esc(t.getMarkerName()).c_str(), t.getMarkerId());
}

static void RunCase(const std::string& header, const std::string& body) {
  std::istringstream hs(header);
  std::string kind;
  hs >> kind;
  YAML::Node node;
  try {
    node = YAML::Load(body);
  } catch (const YAML::Exception&) {
    printf("PARSE_ERR\n");
    return;
  }
  try {
    if (kind == "waypoint") {
      Waypoint w;
      w.load(node);
      TargetOps(w, hs);
      printf("type=%s marker=%d\n", w.getType().c_str(), w.getMarker());
    } else if (kind == "alienbase") {
      std::string markerName, depType;
      int icon;
      hs >> markerName >> icon >> depType;
      AlienDeployment dep(depType);
      dep._markerName = markerName;
      dep._markerIcon = icon;
      AlienBase ab(&dep);
      ab.load(node);
      printf("race=%s battle=%d disc=%d\n", Esc(ab.getAlienRace()).c_str(), ab.isInBattlescape(), ab.isDiscovered());
      Out(ab.save());
      Out(ab.saveId());
      printf("type=%s marker=%d\n", ab.getType().c_str(), ab.getMarker());
      ab.setDiscovered(true);
      printf("marker=%d\n", ab.getMarker());
      std::string none;
      TargetOps(ab, hs);
    } else if (kind == "missionsite") {
      std::string markerName, depType, missionType;
      int icon;
      hs >> markerName >> icon >> depType >> missionType;
      AlienDeployment dep(depType);
      dep._markerName = markerName;
      dep._markerIcon = icon;
      RuleAlienMission rules(missionType);
      MissionSite s(&rules, &dep);
      s.load(node);
      printf("tex=%d secs=%u race=%s battle=%d det=%d\n", s.getTexture(), (unsigned)s.getSecondsRemaining(), Esc(s.getAlienRace()).c_str(), s.isInBattlescape(), s.getDetected());
      Out(s.save());
      Out(s.saveId());
      printf("type=%s marker=%d\n", s.getType().c_str(), s.getMarker());
      s.setDetected(true);
      printf("marker=%d\n", s.getMarker());
      s.setCity("STR_CITY");
      printf("city=%s\n", s.getCity().c_str());
    } else if (kind == "node") {
      Node n;
      n.load(node);
      Position p = n.getPosition();
      printf("n %d %d,%d,%d %d %d %d %d %d alloc=%d dummy=%d target=%d\n", n.getID(), p.x, p.y, p.z, n.getType(), (int)n.getRank(), n.getFlags(), n._reserved, n.getPriority(), n.isAllocated(), n.isDummy(), n.isTarget());
      std::string links = "[";
      for (int x : *n.getNodeLinks()) links += std::to_string(x) + ",";
      printf("links=%s]\n", links.c_str());
      Out(n.save());
      n.allocateNode();
      printf("alloc=%d\n", n.isAllocated());
      n.freeNode();
      printf("alloc=%d\n", n.isAllocated());
    } else if (kind == "equip") {
      EquipmentLayoutItem e(node);
      printf("e %s %s %d %d %s %d\n", Esc(e.getItemType()).c_str(), Esc(e.getSlot()).c_str(), e.getSlotX(), e.getSlotY(), Esc(e.getAmmoItem()).c_str(), e.getFuseTimer());
      Out(e.save());
    }
  } catch (const YAML::Exception& e) {
    printf("YAML_ERR %s\n", Esc(e.msg).c_str());
  } catch (const std::exception&) {
    printf("STD_ERR\n");
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
