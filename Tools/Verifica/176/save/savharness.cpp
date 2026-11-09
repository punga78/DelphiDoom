// Harness for Libs\XcomSave: loads random nodes into the REAL OpenXcom saved game classes (GameTime, Country, Region,
// ResearchProject, SerializationHelper) with the real yaml-cpp, saves them and prints the emitted YAML.
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
#include "Mod/RuleCountry.h"
#include "Mod/RuleRegion.h"
#include "Mod/RuleResearch.h"
#include "Savegame/GameTime.h"
#include "Savegame/Country.h"
#include "Savegame/Region.h"
#include "Savegame/ResearchProject.h"
#include "Savegame/SerializationHelper.h"
#undef private
#include "Engine/RNG.h"
#include "Engine/Exception.h"

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
static std::string Gen(char kind) {
  bool bad = R(14) == 0;
  switch (kind) {
    case 'i': return bad ? Bad() : Num();
    case 'b': return bad ? Bad() : (R(2) ? "true" : (R(2) ? "no" : "false"));
    case 'I': {
      if (bad) return Bad();
      std::string r = "[";
      int n = R(6);
      for (int i = 0; i < n; i++) { if (i) r += ", "; r += Num(); }
      return r + "]";
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
static void Generate(const char* path, int count, unsigned seed) {
  rng.seed(seed);
  std::ofstream o(path, std::ios::binary);
  o << "# corpus of the saved game classes: a header line (kind, arguments) and a YAML node\n";
  for (int i = 0; i < count; i++) {
    switch (R(5)) {
      case 0: {
        // plausible start of the game most of the times
        std::string h = "gametime " + std::to_string(Rg(1, 7)) + " " + std::to_string(Rg(1, 31)) + " " + std::to_string(Rg(1, 12)) + " " +
                        std::to_string(Rg(1999, 2004)) + " " + std::to_string(Rg(0, 23)) + " " + std::to_string(Rg(0, 59)) + " " + std::to_string(Rg(0, 59));
        Case(o, h, Doc({{"second", 'i'}, {"minute", 'i'}, {"hour", 'i'}, {"weekday", 'i'}, {"day", 'i'}, {"month", 'i'}, {"year", 'i'}}));
        break;
      }
      case 1: Case(o, std::string("country ") + (R(2) ? "gen" : "nogen"), Doc({{"funding", 'I'}, {"activityXcom", 'I'}, {"activityAlien", 'I'}, {"pact", 'b'}, {"newPact", 'b'}})); break;
      case 2: Case(o, "region", Doc({{"activityXcom", 'I'}, {"activityAlien", 'I'}})); break;
      case 3: Case(o, "project " + std::to_string(Rg(0, 200)) + " " + std::to_string(Rg(0, 50)), Doc({{"assigned", 'i'}, {"spent", 'i'}, {"cost", 'i'}})); break;
      default: {
        std::string h = "binary " + std::to_string(Rg(-70000, 70000)) + " " + std::to_string(R(3) == 0 ? 1 : (R(2) ? 2 : 4));
        Case(o, h, "x: 1");
        break;
      }
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
static std::string Vec(const std::vector<int>& v) {
  std::string r = "[";
  for (int x : v) r += std::to_string(x) + ",";
  return r + "]";
}
static std::string Dbits(double v) {
  unsigned long long b;
  memcpy(&b, &v, 8);
  char buf[40];
  snprintf(buf, sizeof buf, "%016llX", b);
  return buf;
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
    if (kind == "gametime") {
      int a[7];
      for (int i = 0; i < 7; i++) hs >> a[i];
      GameTime t(a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
      t.load(node);
      printf("t %d %d %d %d %d %d %d\n", t.getWeekday(), t.getDay(), t.getMonth(), t.getYear(), t.getHour(), t.getMinute(), t.getSecond());
      Out(t.save());
      if (t._month >= 1 && t._month <= 12) {
        printf("daylight=%s\n", Dbits(t.getDaylight()).c_str());
        if (t._weekday >= 1 && t._weekday <= 7) printf("wd=%s\n", t.getWeekdayString().c_str());
        printf("mo=%s\n", t.getMonthString().c_str());
        std::string trig;
        for (int i = 0; i < 40; i++) {
          if (t._month < 1 || t._month > 12) break;
          int tr = (int)t.advance();
          trig += std::to_string(tr);
        }
        printf("adv=%s -> %d %d %d %d %d %d %d\n", trig.c_str(), t.getWeekday(), t.getDay(), t.getMonth(), t.getYear(), t.getHour(), t.getMinute(), t.getSecond());
      }
    } else if (kind == "country") {
      std::string gen;
      hs >> gen;
      RuleCountry rc("STR_COUNTRY");
      rc.load(YAML::Load("fundingBase: 7\nfundingCap: 100\n"));
      RNG::setSeed(4242);
      Country c(&rc, gen == "gen");
      printf("init %s\n", Vec(c._funding).c_str());
      c.load(node);
      printf("c %s %s %s %d %d\n", Vec(c._funding).c_str(), Vec(c._activityXcom).c_str(), Vec(c._activityAlien).c_str(), c._pact, c._newPact);
      Out(c.save());
      if (!c._funding.empty() && !c._activityXcom.empty() && !c._activityAlien.empty()) {
        RNG::setSeed(99);
        for (int k = 0; k < 4; k++) {
          c.newMonth(((k + 1) * 137 % 600) * 3, (k + 1) * 311 % 900, k * 7);
          printf("month %d sat=%d %s %s %s %d %d\n", k, c.getSatisfaction(), Vec(c._funding).c_str(), Vec(c._activityXcom).c_str(), Vec(c._activityAlien).c_str(), c._pact, c._newPact);
        }
        Out(c.save());
      }
    } else if (kind == "region") {
      RuleRegion rr("STR_REGION");
      Region r(&rr);
      r.load(node);
      printf("r %s %s\n", Vec(r._activityXcom).c_str(), Vec(r._activityAlien).c_str());
      Out(r.save());
      if (!r._activityXcom.empty() && !r._activityAlien.empty()) {
        r.addActivityXcom(5);
        r.addActivityAlien(-3);
        for (int k = 0; k < 14; k++) r.newMonth();
        printf("r2 %s %s\n", Vec(r._activityXcom).c_str(), Vec(r._activityAlien).c_str());
      }
    } else if (kind == "project") {
      int cost, assigned;
      hs >> cost >> assigned;
      RuleResearch rr("STR_TOPIC");
      rr.load(YAML::Load("cost: " + std::to_string(cost) + "\n"), 1);
      ResearchProject p(&rr, cost);
      p.setAssigned(assigned);
      p.load(node);
      printf("p %d %d %d\n", p.getAssigned(), p.getSpent(), p.getCost());
      Out(p.save());
      printf("progress=%s\n", p.getResearchProgress().c_str());
      bool fin = p.step();
      printf("step=%d spent=%d finished=%d\n", fin, p.getSpent(), p.isFinished());
    } else if (kind == "binary") {
      int value, size;
      hs >> value >> size;
      unsigned char buf[8] = {0};
      unsigned char* p = buf;
      if ((size == 1 && value >= 256) || (size == 2 && value >= 65536)) { printf("skip\n"); return; }
      serializeInt(&p, (Uint8)size, value);
      std::string hex;
      char b[4];
      for (int i = 0; i < 4; i++) { snprintf(b, sizeof b, "%02X", buf[i]); hex += b; }
      p = buf;
      printf("bytes=%s back=%d\n", hex.c_str(), unserializeInt(&p, (Uint8)size));
      double ds[] = {0.0, 1.0, -1.5, 3.14159265358979, 1e-7, 123456789.123456789, 1e21, 1.0 / 3.0, (double)value / 7.0};
      std::string t;
      for (double d : ds) t += serializeDouble(d) + ";";
      printf("doubles=%s\n", t.c_str());
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
