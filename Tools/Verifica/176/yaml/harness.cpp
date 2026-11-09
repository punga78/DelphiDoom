// Parity harness for Libs\Yaml: runs the real yaml-cpp 0.7.0 over a corpus and prints a canonical dump.
// Own code (no OpenXcom code). Build: see build.sh
#include <yaml-cpp/yaml.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <random>

static std::string Esc(const std::string& s) {
  std::string r;
  char buf[8];
  for (unsigned char c : s) {
    if (c == '\\') r += "\\\\";
    else if (c == '\n') r += "\\n";
    else if (c == '\r') r += "\\r";
    else if (c == '\t') r += "\\t";
    else if (c < 32 || c >= 127) { snprintf(buf, sizeof buf, "\\x%02X", c); r += buf; }
    else r += (char)c;
  }
  return r;
}

static std::string Unesc(const std::string& s) {
  std::string r;
  for (size_t i = 0; i < s.size(); i++) {
    if (s[i] != '\\') { r += s[i]; continue; }
    i++;
    char c = s[i];
    if (c == 'n') r += '\n';
    else if (c == 'r') r += '\r';
    else if (c == 't') r += '\t';
    else if (c == '\\') r += '\\';
    else if (c == 'x') { r += (char)strtol(s.substr(i + 1, 2).c_str(), nullptr, 16); i += 2; }
  }
  return r;
}

template <class T>
static std::string Conv(const YAML::Node& n) {
  try {
    T v = n.as<T>();
    std::ostringstream o;
    o.precision(17);
    o << v;
    return o.str();
  } catch (...) { return "!"; }
}

static std::string Num(const YAML::Node& n) {
  std::string r = "i=" + Conv<int>(n) + " u=" + Conv<unsigned>(n) + " l=" + Conv<long long>(n) +
                  " s=" + Conv<short>(n) + " c=" + Conv<char>(n) + " d=" + Conv<double>(n) + " f=" + Conv<float>(n);
  try { r += std::string(" b=") + (n.as<bool>() ? "T" : "F"); } catch (...) { r += " b=!"; }
  return r;
}

static void Dump(const YAML::Node& n, int ind, std::ostream& o, const char* pre) {
  std::string sp(ind * 2, ' ');
  if (ind > 30) { o << sp << pre << "CYCLE\n"; return; }
  switch (n.Type()) {
    case YAML::NodeType::Undefined: o << sp << pre << "UNDEF\n"; break;
    case YAML::NodeType::Null: o << sp << pre << "NULL tag=" << Esc(n.Tag()) << "\n"; break;
    case YAML::NodeType::Scalar:
      o << sp << pre << "S \"" << Esc(n.Scalar()) << "\" tag=" << Esc(n.Tag()) << " " << Num(n) << "\n";
      break;
    case YAML::NodeType::Sequence:
      o << sp << pre << "Q " << (n.Style() == YAML::EmitterStyle::Flow ? "F" : "B") << " tag=" << Esc(n.Tag()) << " n=" << n.size() << "\n";
      for (auto it = n.begin(); it != n.end(); ++it) Dump(*it, ind + 1, o, "- ");
      break;
    case YAML::NodeType::Map:
      o << sp << pre << "M " << (n.Style() == YAML::EmitterStyle::Flow ? "F" : "B") << " tag=" << Esc(n.Tag()) << " n=" << n.size() << "\n";
      for (auto it = n.begin(); it != n.end(); ++it) {
        Dump(it->first, ind + 1, o, "K ");
        Dump(it->second, ind + 1, o, "V ");
      }
      break;
  }
}

static void RunCase(const std::string& text, std::ostream& o) {
  std::vector<YAML::Node> docs;
  try {
    docs = YAML::LoadAll(text);
  } catch (const YAML::Exception& e) {
    o << "ERR " << Esc(e.msg) << " @" << e.mark.line << ":" << e.mark.column << "\n";
    return;
  } catch (...) { o << "ERR other\n"; return; }
  o << "OK docs=" << docs.size() << "\n";
  for (auto& d : docs) {
    o << "DOC\n";
    Dump(d, 0, o, "");
    YAML::Emitter out;
    out << d;
    o << "EMIT " << (out.good() ? "good" : "bad:" + Esc(out.GetLastError())) << "\n";
    std::string s = out.c_str() ? out.c_str() : "";
    std::istringstream is(s);
    std::string line;
    while (std::getline(is, line)) o << "| " << Esc(line) << "\n";
    o << "|.\n";
  }
}

// ---- random corpus ----
static std::mt19937 rng;
static int R(int n) { return (int)(rng() % (unsigned)n); }
static const char* Words[] = {"alpha", "beta", "gamma", "delta", "x", "y", "z", "name", "id", "value", "type",
                              "STR_FOO", "a b", "k-1", "k_2", "hello world", "1", "true", "null", "~", "yes",
                              "12.5", "-3", "0x1F", "é", "日本", "a:b", "q?", "colon:", "# no", "- dash"};
static std::string Word() { return Words[R(sizeof Words / sizeof *Words)]; }
static std::string Quote(const std::string& w) {
  if (R(2)) {
    std::string r = "\"";
    for (char c : w) { if (c == '"' || c == '\\') r += '\\'; r += c; }
    if (R(4) == 0) r += "\\n\\t\\x41";
    return r + "\"";
  }
  std::string r = "'";
  for (char c : w) { if (c == '\'') r += '\''; r += c; }
  return r + "'";
}
static std::string Scalar(bool key) {
  switch (R(key ? 5 : 11)) {
    case 0: return Word();
    case 1: return Quote(Word());
    case 2: return std::to_string(R(2000) - 500);
    case 3: return Word();
    case 4: return Word() + " " + Word();
    case 5: return "null";
    case 6: return std::to_string(R(1000)) + "." + std::to_string(R(100));
    case 7: return R(2) ? "true" : "false";
    case 8: return "";
    case 9: return Quote(Word() + "\n" + Word());
    default: return Word();
  }
}
static std::string Flow(int depth) {
  if (depth <= 0 || R(3) == 0) {
    std::string s = Scalar(false);
    return s.empty() ? "~" : s;
  }
  std::string r;
  int n = R(4);
  if (R(2)) {
    r = "[";
    for (int i = 0; i < n; i++) { if (i) r += ", "; r += Flow(depth - 1); }
    return r + "]";
  }
  r = "{";
  for (int i = 0; i < n; i++) { if (i) r += ", "; std::string k = Scalar(true); r += (k.empty() ? "k" : k) + ": " + Flow(depth - 1); }
  return r + "}";
}
static void Block(std::string& out, int indent, int depth, bool inSeqItem);
static void Value(std::string& out, int indent, int depth, const std::string& lead) {
  // lead is e.g. "key:" or "-"; writes lead and value
  int k = depth <= 0 ? R(4) : R(9);
  std::string sp(indent, ' ');
  switch (k) {
    case 0: case 1: { std::string s = Scalar(false); out += lead + (s.empty() ? "" : " " + s) + "\n"; break; }
    case 2: out += lead + " " + Flow(2) + "\n"; break;
    case 3: { std::string s = Scalar(false); out += lead + (s.empty() ? "" : " " + s) + " # c\n"; break; }
    case 4: {
      const char* h[] = {"|", "|-", "|+", ">", ">-", ">+", "|2"};
      out += lead + " " + h[R(7)] + "\n";
      int n = R(4);
      for (int i = 0; i < n; i++) out += (R(5) == 0 ? std::string("") : sp + "  " + Word() + (R(3) == 0 ? "\n" + sp + "    more" : "")) + "\n";
      if (n == 0) out += sp + "  x\n";
      break;
    }
    case 5: out += lead + " " + Word() + "\n" + sp + "  " + Word() + "\n"; break;
    default: {
      out += lead + "\n";
      Block(out, (lead == "-" ? indent + 2 : indent + 2), depth - 1, false);
      break;
    }
  }
}
static void Block(std::string& out, int indent, int depth, bool) {
  std::string sp(indent, ' ');
  int n = 1 + R(4);
  if (R(2)) {
    for (int i = 0; i < n; i++) {
      if (R(4) == 0) {
        // inline map in seq item
        std::string k = Scalar(true);
        out += sp + "- " + (k.empty() ? "k" : k) + ":";
        std::string tmp;
        Value(tmp, indent + 2, depth - 1, "");
        out += tmp;
        if (R(2)) { std::string k2 = Word(); std::string t2; Value(t2, indent + 2, depth - 1, std::string(indent + 2, ' ') + k2 + ":"); out += t2; }
      } else {
        std::string tmp;
        Value(tmp, indent, depth, sp + "-");
        out += tmp;
      }
      if (R(8) == 0) out += "\n";
      if (R(10) == 0) out += sp + "# comment\n";
    }
  } else {
    for (int i = 0; i < n; i++) {
      std::string k = Scalar(true);
      if (k.empty()) k = "k";
      if (k.find('\n') != std::string::npos) k = "kk";
      std::string tmp;
      Value(tmp, indent, depth, sp + k + ":");
      out += tmp;
      if (R(8) == 0) out += "\n";
    }
  }
}
static std::string RandomDoc() {
  std::string out;
  if (R(8) == 0) out += "---\n";
  if (R(2)) Block(out, 0, 3, false);
  else { std::string t; Value(t, 0, 2, "-"); out += t; }
  if (R(10) == 0) out += "...\n";
  return out;
}
static std::string Mutate(std::string s) {
  const char* junk = ":-[]{}#&*!|>'\"%@,? \n\t\\";
  int times = 1 + R(2);
  for (int t = 0; t < times && !s.empty(); t++) {
    size_t p = (size_t)R((int)s.size());
    switch (R(3)) {
      case 0: s.erase(p, 1); break;
      case 1: s.insert(p, 1, junk[R((int)strlen(junk))]); break;
      default: s[p] = junk[R((int)strlen(junk))]; break;
    }
  }
  return s;
}

static std::vector<std::string> Split(const std::string& all) {
  std::vector<std::string> v;
  std::string cur;
  std::istringstream is(all);
  std::string line;
  bool first = true;
  while (std::getline(is, line)) {
    if (line == "%%%%") { v.push_back(cur); cur.clear(); first = true; continue; }
    cur += line + "\n";
  }
  v.push_back(cur);
  return v;
}

int main(int argc, char** argv) {
  std::string mode = argc > 1 ? argv[1] : "";
  if (mode == "gen") {  // gen handwritten out count seed
    std::ifstream f(argv[2], std::ios::binary);
    std::stringstream ss; ss << f.rdbuf();
    std::string hw = ss.str();
    rng.seed(atoi(argv[5]));
    std::ofstream o(argv[3], std::ios::binary);
    o << hw;
    int count = atoi(argv[4]);
    for (int i = 0; i < count; i++) {
      std::string d = RandomDoc();
      if (R(10) < 3) d = Mutate(d);
      o << "%%%%\n" << d;
      if (d.empty() || d.back() != '\n') o << "\n";
    }
    return 0;
  }
  if (mode == "run") {  // run corpus
    std::ifstream f(argv[2], std::ios::binary);
    std::stringstream ss; ss << f.rdbuf();
    auto cases = Split(ss.str());
    for (size_t i = 0; i < cases.size(); i++) {
      std::cout << "#" << i << "\n";
      RunCase(cases[i], std::cout);
    }
    return 0;
  }
  if (mode == "emit") return 0;
  return 1;
}
