// Emitter part of the parity harness for Libs\Yaml (own code, no OpenXcom code).
// "emit-gen <dir>" writes the corpora (scripts of emitter operations, one per case, cases separated by "%%%%"),
// "emit-run <file>" runs every case on the real YAML::Emitter and prints what it did.
//
// A script is one operation per line, words separated by one space; a text argument is the hex of its bytes
// ("-" for the empty text). The Delphi test reads the same corpus files and runs the same operations.
//   S txt | B 0/1 | C n | N | I n | U n | H n | W n | L n | Q n | D hex16 | F hex8 | BIN hex
//   M Name | IND n | PF n | PD n | PB n | AL txt | AN txt | TV txt | TP txt | TN prefix txt | CM txt
//   G<Setter> arg   (global setters: the result is written to the log)
#include <cstdint>
#include <cstring>
#include <limits>
#include <map>

namespace emitcases {

static std::string HexOf(const std::string& s) {
  if (s.empty()) return "-";
  static const char* d = "0123456789abcdef";
  std::string r;
  for (unsigned char c : s) { r += d[c >> 4]; r += d[c & 15]; }
  return r;
}
static std::string FromHex(const std::string& h) {
  std::string r;
  if (h == "-") return r;
  for (size_t i = 0; i + 1 < h.size(); i += 2) r += (char)strtol(h.substr(i, 2).c_str(), nullptr, 16);
  return r;
}

static const char* ManipNames[] = {
  "Auto", "TagByKind", "Newline", "EmitNonAscii", "EscapeNonAscii", "EscapeAsJson", "SingleQuoted", "DoubleQuoted",
  "Literal", "LowerNull", "UpperNull", "CamelNull", "TildeNull", "YesNoBool", "TrueFalseBool", "OnOffBool",
  "UpperCase", "LowerCase", "CamelCase", "LongBool", "ShortBool", "Dec", "Hex", "Oct", "BeginDoc", "EndDoc",
  "BeginSeq", "EndSeq", "Flow", "Block", "BeginMap", "EndMap", "Key", "Value", "LongKey"};
static const YAML::EMITTER_MANIP ManipValues[] = {
  YAML::Auto, YAML::TagByKind, YAML::Newline, YAML::EmitNonAscii, YAML::EscapeNonAscii, YAML::EscapeAsJson,
  YAML::SingleQuoted, YAML::DoubleQuoted, YAML::Literal, YAML::LowerNull, YAML::UpperNull, YAML::CamelNull,
  YAML::TildeNull, YAML::YesNoBool, YAML::TrueFalseBool, YAML::OnOffBool, YAML::UpperCase, YAML::LowerCase,
  YAML::CamelCase, YAML::LongBool, YAML::ShortBool, YAML::Dec, YAML::Hex, YAML::Oct, YAML::BeginDoc, YAML::EndDoc,
  YAML::BeginSeq, YAML::EndSeq, YAML::Flow, YAML::Block, YAML::BeginMap, YAML::EndMap, YAML::Key, YAML::Value,
  YAML::LongKey};
static const int ManipCount = sizeof ManipValues / sizeof *ManipValues;

static YAML::EMITTER_MANIP ManipByName(const std::string& n) {
  for (int i = 0; i < ManipCount; i++) if (n == ManipNames[i]) return ManipValues[i];
  return YAML::Auto;
}

static std::vector<std::string> Words(const std::string& line) {
  std::vector<std::string> v;
  std::istringstream is(line);
  std::string w;
  while (is >> w) v.push_back(w);
  return v;
}

static void Exec(const std::string& script, std::ostream& o) {
  YAML::Emitter em;
  std::istringstream is(script);
  std::string line;
  while (std::getline(is, line)) {
    auto w = Words(line);
    if (w.empty()) continue;
    const std::string& op = w[0];
    auto arg = [&](size_t i) { return i < w.size() ? w[i] : std::string("-"); };
    if (op == "S") em << FromHex(arg(1));
    else if (op == "B") em << (arg(1) == "1");
    else if (op == "C") em << (char)atoi(arg(1).c_str());
    else if (op == "UC") em << (unsigned char)atoi(arg(1).c_str());
    else if (op == "N") em << YAML::Null;
    else if (op == "I") em << (int)strtoll(arg(1).c_str(), nullptr, 10);
    else if (op == "U") em << (unsigned int)strtoull(arg(1).c_str(), nullptr, 10);
    else if (op == "H") em << (short)strtoll(arg(1).c_str(), nullptr, 10);
    else if (op == "W") em << (unsigned short)strtoull(arg(1).c_str(), nullptr, 10);
    else if (op == "L") em << (long long)strtoll(arg(1).c_str(), nullptr, 10);
    else if (op == "Q") em << (unsigned long long)strtoull(arg(1).c_str(), nullptr, 10);
    else if (op == "D") { uint64_t b = strtoull(arg(1).c_str(), nullptr, 16); double d; memcpy(&d, &b, 8); em << d; }
    else if (op == "F") { uint32_t b = (uint32_t)strtoull(arg(1).c_str(), nullptr, 16); float f; memcpy(&f, &b, 4); em << f; }
    else if (op == "BIN") { std::string d = FromHex(arg(1)); em << YAML::Binary((const unsigned char*)d.data(), d.size()); }
    else if (op == "M") em << ManipByName(arg(1));
    else if (op == "IND") em << YAML::Indent(atoi(arg(1).c_str()));
    else if (op == "PF") em << YAML::FloatPrecision(atoi(arg(1).c_str()));
    else if (op == "PD") em << YAML::DoublePrecision(atoi(arg(1).c_str()));
    else if (op == "PB") em << YAML::Precision(atoi(arg(1).c_str()));
    else if (op == "AL") em << YAML::Alias(FromHex(arg(1)));
    else if (op == "AN") em << YAML::Anchor(FromHex(arg(1)));
    else if (op == "TV") em << YAML::VerbatimTag(FromHex(arg(1)));
    else if (op == "TP") em << YAML::LocalTag(FromHex(arg(1)));
    else if (op == "TN") em << YAML::LocalTag(FromHex(arg(1)), FromHex(arg(2)));
    else if (op == "CM") em << YAML::Comment(FromHex(arg(1)));
    else if (op[0] == 'G') {
      bool ok = false;
      std::string a = arg(1);
      if (op == "GSetOutputCharset") ok = em.SetOutputCharset(ManipByName(a));
      else if (op == "GSetStringFormat") ok = em.SetStringFormat(ManipByName(a));
      else if (op == "GSetBoolFormat") ok = em.SetBoolFormat(ManipByName(a));
      else if (op == "GSetNullFormat") ok = em.SetNullFormat(ManipByName(a));
      else if (op == "GSetIntBase") ok = em.SetIntBase(ManipByName(a));
      else if (op == "GSetSeqFormat") ok = em.SetSeqFormat(ManipByName(a));
      else if (op == "GSetMapFormat") ok = em.SetMapFormat(ManipByName(a));
      else if (op == "GSetIndent") ok = em.SetIndent(atoi(a.c_str()));
      else if (op == "GSetPreCommentIndent") ok = em.SetPreCommentIndent(atoi(a.c_str()));
      else if (op == "GSetPostCommentIndent") ok = em.SetPostCommentIndent(atoi(a.c_str()));
      else if (op == "GSetFloatPrecision") ok = em.SetFloatPrecision(atoi(a.c_str()));
      else if (op == "GSetDoublePrecision") ok = em.SetDoublePrecision(atoi(a.c_str()));
      else if (op == "GRestore") { em.RestoreGlobalModifiedSettings(); ok = true; }
      o << "set " << op << " " << a << " -> " << (ok ? 1 : 0) << "\n";
    }
  }
  o << (em.good() ? "good" : "bad:" + HexOf(em.GetLastError())) << " size=" << em.size() << "\n";
  std::string s = em.c_str() ? em.c_str() : "";
  std::istringstream ls(s);
  std::string l;
  while (std::getline(ls, l)) o << "| " << HexOf(l) << "\n";
  o << "|.\n";
}

// ---- corpus generation ----

struct Gen {
  std::mt19937 rng{1760};
  int R(int n) { return (int)(rng() % (unsigned)n); }

  static std::string Op(const std::string& op, const std::string& a = "") { return a.empty() ? op + "\n" : op + " " + a + "\n"; }
  static std::string S(const std::string& s) { return "S " + HexOf(s) + "\n"; }
  static std::string M(const char* n) { return std::string("M ") + n + "\n"; }

  std::vector<std::string> Strings() {
    std::vector<std::string> v = {
        "", " ", "a", "hello world", "  lead", "trail  ", "a: b", "a #b", "# c", "- x", "-", "?", ":", "---", "...",
        "null", "~", "Null", "NULL", "true", "yes", "123", "12.5", "0x1F", "\xC3\xA9", "\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E",
        "\xF0\x9F\x98\x80", "\xFF\xFE", "a\nb", "a\n", "\n", "tab\there", "cr\rlf", std::string("a\0b", 3),
        "\x01\x07", "\x7F", "\xC2\x85", "\xC2\xA0", "\xEF\xBB\xBF", "\xEF\xBF\xBE", "\xED\xA0\x80", "\xF4\x90\x80\x80",
        "\xC0\xAF", "\xE2\x82", "[a]", "{a}", "a,b", "a'b", "a\"b", "back\\slash", "&anchor", "*alias", "!tag",
        "|x", ">x", "%x", "@x", "`x", "a:", ":a", "a: ", "-a", "?a", "key: value", "x\n\ny", "line1\nline2\n\nline4",
        "trailing newline\n", "\n\nlead newlines", "  two lead\nand more", "a\tb", "a  b", "\x1F", "\x1B[0m",
        "\xC2\x80", "\xC2\x9F", "\xC2\xA1", "caf\xC3\xA9 \xE2\x82\xAC", "\xE2\x80\xA8", "\xEF\xBF\xBD",
        "0o14", "1e3", ".inf", "-.inf", ".nan", "Yes", "NO", "on", "off", "y", "n", "{", "}", "[", "]", ",", "a,",
        "- ", "? ", ": ", "a b: c", "http://x.y/z?q=1#f", "x ", " x", "x #", "x\t#y"};
    v.push_back(std::string(1100, 'a'));
    v.push_back(std::string(1025, 'b') + "\nc");
    v.push_back("2001:db8::1");
    return v;
  }

  // (a) every string as a document scalar, in a sequence, as a key and as a value, with every format
  void StringCases(std::ostream& o) {
    auto strs = Strings();
    const char* fmts[] = {"Auto", "SingleQuoted", "DoubleQuoted", "Literal"};
    const char* flows[] = {"Block", "Flow"};
    const char* sets[] = {"EmitNonAscii", "EscapeNonAscii", "EscapeAsJson"};
    int count = 0;
    for (size_t k = 0; k < strs.size(); k++) {
      const std::string& s = strs[k];
      for (int f = 0; f < 4; f++)
        for (int fl = 0; fl < 2; fl++)
          for (int ctx = 0; ctx < 4; ctx++) {
            std::string c = M(fmts[f]);
            if (fl == 1 && ctx != 0) c += M("Flow");
            switch (ctx) {
              case 0: if (fl == 1) c += M("Flow"); c += S(s); break;
              case 1: c += M("BeginSeq") + S(s) + S("second") + M("EndSeq"); break;
              case 2: c += M("BeginMap") + M("Key") + S(s) + M("Value") + S("v") + M("EndMap"); break;
              default: c += M("BeginMap") + M("Key") + S("k") + M("Value") + S(s) + M("EndMap"); break;
            }
            if (count++) o << "%%%%\n";
            o << c;
          }
      // the three charsets on a scalar, with a double quoted and an automatic format
      for (int cs = 0; cs < 3; cs++)
        for (int f = 0; f < 4; f += 2) {
          if (count++) o << "%%%%\n";
          o << M(sets[cs]) << M(fmts[f]) << M("BeginSeq") << S(s) << M("EndSeq");
        }
      // a global string format and charset
      if (count++) o << "%%%%\n";
      o << "GSetOutputCharset " << sets[k % 3] << "\n" << "GSetStringFormat " << fmts[k % 4] << "\n"
        << M("BeginSeq") << S(s) << S(s) << M("EndSeq") << S(s);
    }
  }

  // (c) numbers, booleans, null and binary
  void ValueCases(std::ostream& o) {
    int count = 0;
    auto sep = [&]() { if (count++) o << "%%%%\n"; };
    const char* bases[] = {"Dec", "Hex", "Oct"};
    long long ints[] = {0, 1, -1, 7, 8, 9, 10, 255, 256, -255, 32767, -32768, 65535, 65536, 2147483647LL,
                        -2147483648LL, 4294967295LL, 4294967296LL, 9223372036854775807LL, -9223372036854775807LL - 1};
    for (int b = 0; b < 3; b++)
      for (long long v : ints) {
        sep();
        o << "M " << bases[b] << "\n" << "I " << (int)v << "\n" << "U " << (unsigned)v << "\n" << "H " << (short)v << "\n"
          << "W " << (unsigned short)v << "\n" << "L " << v << "\n" << "Q " << (unsigned long long)v << "\n";
      }
    for (int b = 0; b < 3; b++) {
      sep();
      o << "GSetIntBase " << bases[b] << "\nM BeginSeq\nI -5\nI 42\nL -5\nU 4000000000\nM EndSeq\n";
    }
    // booleans in every format
    const char* bf[] = {"YesNoBool", "TrueFalseBool", "OnOffBool"};
    const char* bc[] = {"UpperCase", "LowerCase", "CamelCase"};
    const char* bl[] = {"LongBool", "ShortBool"};
    for (auto a : bf) for (auto b : bc) for (auto c : bl) {
      sep();
      o << "M " << a << "\nM " << b << "\nM " << c << "\nM BeginSeq\nB 1\nB 0\nM EndSeq\nB 1\n";
      sep();
      o << "GSetBoolFormat " << a << "\nGSetBoolFormat " << b << "\nGSetBoolFormat " << c << "\nB 1\n";
    }
    const char* nf[] = {"LowerNull", "UpperNull", "CamelNull", "TildeNull"};
    for (auto a : nf) { sep(); o << "M " << a << "\nM BeginSeq\nN\nN\nM EndSeq\nN\n"; sep(); o << "GSetNullFormat " << a << "\nN\n"; }
    // floating point
    double ds[] = {0.0, -0.0, 1.0, -1.0, 0.1, 0.5, 1.0 / 3.0, 2.0 / 3.0, 3.14159265358979323846, 1e-5, 1e-4, 1e5, 1e15,
                   1e16, 1e17, 123456789012345678.0, 1.5e300, -2.5e-300, 4.9406564584124654e-324,
                   1.7976931348623157e308, 100.0, 1000000.0, 0.0001, 0.00001234, 12345.6789, 999999.5, 9.9999999999999995,
                   0.30000000000000004, 5e-324, 2.2250738585072014e-308, std::numeric_limits<double>::infinity(),
                   -std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()};
    int precs[] = {-1, 0, 1, 2, 3, 6, 9, 15, 17, 18};
    for (double d : ds) {
      uint64_t bits; memcpy(&bits, &d, 8);
      float f = (float)d; uint32_t fb; memcpy(&fb, &f, 4);
      char buf[64];
      for (int p : precs) {
        sep();
        snprintf(buf, sizeof buf, "%016llx", (unsigned long long)bits);
        if (p >= 0) o << "PD " << p << "\n";
        o << "D " << buf << "\n";
        snprintf(buf, sizeof buf, "%08x", fb);
        if (p >= 0) o << "PF " << p << "\n";
        o << "F " << buf << "\n";
        o << "M BeginSeq\n";
        snprintf(buf, sizeof buf, "%016llx", (unsigned long long)bits);
        o << "D " << buf << "\n";
        snprintf(buf, sizeof buf, "%08x", fb);
        o << "F " << buf << "\nM EndSeq\n";
      }
    }
    for (int p : precs) {
      if (p < 0) continue;
      sep();
      o << "GSetDoublePrecision " << p << "\nGSetFloatPrecision " << p << "\nD 3fb999999999999a\nF 3dcccccd\nM BeginSeq\nD 400921fb54442d18\nF 40490fdb\nM EndSeq\n";
    }
    // chars
    for (int c : {0, 7, 8, 9, 10, 12, 13, 27, 32, 34, 39, 65, 92, 97, 122, 126, 127, 128, 169, 255}) {
      sep();
      o << "C " << c << "\nM EscapeNonAscii\nC " << c << "\nM EscapeAsJson\nC " << c << "\nUC " << c << "\n";
    }
    // binary
    std::string bins[] = {"", "a", "ab", "abc", "abcd", std::string("\0\1\2\3\4\5", 6), std::string(100, '\xFF')};
    for (auto& b : bins) { sep(); o << "BIN " << HexOf(b) << "\n"; sep(); o << "M BeginMap\nM Key\nS 6b\nM Value\nBIN " << HexOf(b) << "\nM EndMap\n"; }
  }

  // (d) the settings: every global setter with every kind of value (also the wrong ones), then a document
  void SettingCases(std::ostream& o) {
    int count = 0;
    auto sep = [&]() { if (count++) o << "%%%%\n"; };
    const char* setters[] = {"GSetOutputCharset", "GSetStringFormat", "GSetBoolFormat", "GSetNullFormat", "GSetIntBase",
                             "GSetSeqFormat", "GSetMapFormat"};
    for (auto s : setters)
      for (int i = 0; i < ManipCount; i++) {
        sep();
        o << s << " " << ManipNames[i] << "\nM BeginMap\nM Key\nS 6b\nM Value\nS 76616c0a31\nM Key\nM BeginSeq\nB 1\nN\nI 255\nM EndSeq\nM Value\nM BeginMap\nM Key\nS 61\nM Value\nS 62\nM EndMap\nM EndMap\n";
      }
    const char* nsetters[] = {"GSetIndent", "GSetPreCommentIndent", "GSetPostCommentIndent", "GSetFloatPrecision", "GSetDoublePrecision"};
    for (auto s : nsetters)
      for (int n : {0, 1, 2, 3, 4, 8, 9, 10, 17, 18, 100}) {
        sep();
        o << s << " " << n << "\nM BeginMap\nM Key\nS 6b\nM Value\nM BeginSeq\nS 78\nCM 6e6f7465\nD 3fb999999999999a\nF 3dcccccd\nM BeginMap\nM Key\nS 61\nM Value\nS 62\nM EndMap\nM EndSeq\nM EndMap\n";
      }
    for (int n : {0, 1, 2, 3, 5, 7})
      for (int ctx = 0; ctx < 2; ctx++) {
        sep();
        o << "IND " << n << "\nM BeginSeq\nS 61\nM BeginMap\nM Key\nS 6b\nM Value\nS 76\nM EndMap\nM EndSeq\n";
        if (ctx) o << "M BeginMap\nM Key\nS 6b\nM Value\nM BeginSeq\nS 78\nM EndSeq\nM EndMap\n";
      }
    // local settings that must be gone after the node / group
    sep();
    o << "M Hex\nI 255\nI 255\nM BeginSeq\nM Oct\nI 8\nI 8\nM EndSeq\nI 255\n";
    sep();
    o << "M Flow\nM BeginSeq\nS 61\nM EndSeq\nM BeginSeq\nS 62\nM EndSeq\n";
    sep();
    o << "GSetSeqFormat Flow\nGSetMapFormat Flow\nM BeginSeq\nS 61\nM Block\nM BeginSeq\nS 62\nM EndSeq\nM EndSeq\n";
    sep();
    o << "M DoubleQuoted\nM Block\nM BeginSeq\nS 61\nS 62\nM EndSeq\nS 63\nS 64\n";
    sep();
    o << "GSetStringFormat DoubleQuoted\nM Auto\nS 61\nS 62\nGRestore\nS 63\n";
    sep();
    o << "GSetIndent 4\nM BeginMap\nM Key\nS 61\nM Value\nM BeginSeq\nS 62\nM IND 6\nM EndSeq\nM EndMap\nGSetIndent 3\nM BeginSeq\nS 63\nM EndSeq\n";
    sep();
    o << "IND 4\nM BeginSeq\nS 61\nM EndSeq\nM BeginSeq\nS 62\nM EndSeq\n";
  }

  // (b) random sequences of operations
  std::string RandomScalarOp() {
    switch (R(12)) {
      case 0: return S(Strings()[R((int)Strings().size())]);
      case 1: return S("key");
      case 2: return "I " + std::to_string(R(2000) - 1000) + "\n";
      case 3: return "B " + std::to_string(R(2)) + "\n";
      case 4: return "N\n";
      case 5: { char b[64]; double d = (R(1000) - 500) / 8.0; uint64_t u; memcpy(&u, &d, 8); snprintf(b, sizeof b, "D %016llx\n", (unsigned long long)u); return b; }
      case 6: return "C " + std::to_string(R(256)) + "\n";
      case 7: return S("multi\nline");
      case 8: return S("a b c");
      case 9: return "L " + std::to_string((long long)R(100000) * 100003) + "\n";
      case 10: return S("42");
      default: return S("v" + std::to_string(R(100)));
    }
  }
  std::string RandomOps(int maxDepth) {
    std::string c;
    std::vector<char> stack;  // 'S' seq, 'M' map, 'k' map awaiting key, 'v' awaiting value
    int n = 3 + R(30);
    const char* formatOps[] = {"Flow", "Block", "DoubleQuoted", "SingleQuoted", "Literal", "Auto", "LongKey", "Hex", "Oct",
                               "Dec", "UpperCase", "CamelCase", "ShortBool", "LongBool", "YesNoBool", "OnOffBool", "UpperNull",
                               "CamelNull", "EscapeNonAscii", "EscapeAsJson", "EmitNonAscii", "TagByKind"};
    for (int i = 0; i < n; i++) {
      int k = R(100);
      bool inMap = !stack.empty() && stack.back() == 'M';
      if (k < 28) {
        if (inMap && R(4) != 0) c += M(R(2) ? "Key" : "Value");
        c += RandomScalarOp();
      } else if (k < 40 && (int)stack.size() < maxDepth) {
        if (inMap && R(4) != 0) c += M(R(2) ? "Key" : "Value");
        if (R(2)) { c += M("BeginSeq"); stack.push_back('S'); } else { c += M("BeginMap"); stack.push_back('M'); }
      } else if (k < 52) {
        if (!stack.empty() && R(40) != 0) { c += M(stack.back() == 'S' ? "EndSeq" : "EndMap"); stack.pop_back(); }
        else if (stack.empty() && R(30)) c += RandomScalarOp(); else c += M(R(2) ? "EndSeq" : "EndMap");
      } else if (k < 58) c += M("Key");
      else if (k < 62) c += M("Value");
      else if (k < 68) c += std::string("CM ") + HexOf(R(2) ? "a comment" : "two\nlines") + "\n";
      else if (k < 73) c += "AN " + HexOf(R(25) ? "anc" + std::to_string(R(5)) : "bad anchor") + "\n";
      else if (k < 77) c += "AL " + HexOf(R(25) ? "anc" + std::to_string(R(5)) : "bad alias") + "\n";
      else if (k < 81) {
        switch (R(4)) {
          case 0: case 3: c += "TV " + HexOf("tag:yaml.org,2002:str") + "\n"; break;
          case 1: c += "TP " + HexOf("local") + "\n"; break;
          case 2: c += "TN " + HexOf("e") + " " + HexOf("name") + "\n"; break;
          default: c += R(8) ? "TP " + HexOf("t") + "\n" : "TV " + HexOf("bad tag{") + "\n"; break;
        }
      }
      else if (k < 84) c += M("Newline");
      else if (k < 86) c += (stack.empty() || !R(40)) ? M(R(2) ? "BeginDoc" : "EndDoc") : M("Newline");
      else if (k < 94) c += M(formatOps[R((int)(sizeof formatOps / sizeof *formatOps))]);
      else if (k < 96) c += "IND " + std::to_string(R(6)) + "\n";
      else if (k < 97) c += "PB " + std::to_string(R(18)) + "\n";
      else if (k < 98) c += std::string("GSetSeqFormat ") + (R(2) ? "Flow" : "Block") + "\n";
      else if (k < 99) c += std::string("GSetMapFormat ") + (R(2) ? "Flow" : "Block") + "\n";
      else c += "GSetIndent " + std::to_string(R(6)) + "\n";
    }
    // most of the time close the groups
    while (!stack.empty() && R(40) != 0) { c += M(stack.back() == 'S' ? "EndSeq" : "EndMap"); stack.pop_back(); }
    return c;
  }
  void RandomCases(std::ostream& o, int count) {
    for (int i = 0; i < count; i++) {
      if (i) o << "%%%%\n";
      o << RandomOps(1 + R(4));
    }
  }
};

}  // namespace emitcases
