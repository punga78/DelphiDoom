// Text dump helpers shared by modload.cpp: every value is one line "section|name|field=value".
static FILE* gOut = 0;
static std::string gSection, gName;
static std::set<std::string> gOnly;

static std::string Esc(const std::string& s) {
  std::string r;
  char buf[8];
  for (unsigned char c : s) {
    if (c == '\\') r += "\\\\";
    else if (c == '\n') r += "\\n";
    else if (c == '|') r += "\\x7C";
    else if (c < 32 || c >= 127) { snprintf(buf, sizeof buf, "\\x%02X", c); r += buf; }
    else r += (char)c;
  }
  return r;
}
static std::string HexD(double v) {
  unsigned long long b;
  memcpy(&b, &v, 8);
  char buf[40];
  snprintf(buf, sizeof buf, "%016llX", b);
  return buf;
}
static std::string HexF(float v) {
  unsigned int b;
  memcpy(&b, &v, 4);
  char buf[40];
  snprintf(buf, sizeof buf, "%08X", b);
  return buf;
}
template <class T> static std::string V(const std::vector<T>& v);
template <class T> static std::string V(const std::set<T>& v);
template <class A, class B> static std::string V(const std::pair<A, B>& v);
template <class A, class B> static std::string V(const std::map<A, B>& v);
static void Begin(const char* section, const std::string& name) { gSection = section; gName = Esc(name); }
static void Line(const char* key, const std::string& value) {
  fprintf(gOut, "%s|%s|%s=%s\n", gSection.c_str(), gName.c_str(), key, value.c_str());
}
static std::string V(int v) { return std::to_string(v); }
static std::string V(unsigned v) { return std::to_string(v); }
static std::string V(long v) { return std::to_string(v); }
static std::string V(unsigned long v) { return std::to_string(v); }
static std::string V(long long v) { return std::to_string(v); }
static std::string V(unsigned char v) { return std::to_string((int)v); }
static std::string V(unsigned short v) { return std::to_string((int)v); }
static std::string V(signed char v) { return std::to_string((int)v); }
static std::string V(bool v) { return v ? "1" : "0"; }
static std::string V(double v) { return HexD(v); }
static std::string V(float v) { return HexF(v); }
static std::string V(const std::string& v) { return "'" + Esc(v) + "'"; }
static std::string V(const char* v) { return "'" + Esc(v) + "'"; }
template <class T> static std::string V(const std::vector<T>& v) {
  std::string r = "[";
  for (size_t i = 0; i < v.size(); i++) { if (i) r += ","; r += V(v[i]); }
  return r + "]";
}
template <class T> static std::string V(const std::set<T>& v) {
  std::string r = "{";
  bool first = true;
  for (typename std::set<T>::const_iterator i = v.begin(); i != v.end(); ++i) { if (!first) r += ","; first = false; r += V(*i); }
  return r + "}";
}
template <class A, class B> static std::string V(const std::pair<A, B>& v) { return "(" + V(v.first) + "," + V(v.second) + ")"; }
template <class A, class B> static std::string V(const std::map<A, B>& v) {
  std::string r = "{";
  bool first = true;
  for (typename std::map<A, B>::const_iterator i = v.begin(); i != v.end(); ++i) { if (!first) r += ","; first = false; r += V(i->first) + ":" + V(i->second); }
  return r + "}";
}
template <class T> static void F(const char* key, const T& v) { Line(key, V(v)); }
static bool Wanted(const char* section) { return gOnly.empty() || gOnly.count(section) > 0; }
