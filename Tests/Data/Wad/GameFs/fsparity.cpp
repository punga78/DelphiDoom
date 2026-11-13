// Derived from the Doom 3 GPL Source Code (id Software, GPL v3 with additional terms): the loops are copied from
// neo\framework\FileSystem.cpp. Build with bcc32c (no flags), run, compare with Tests\Source\DelphiDoom.Tests.Wad.GameFileSystem.pas.
// Parity harness: the pak branch of idFileSystemLocal::GetFileList, HashFileName, FilenameCompare and
// GetFileListTree, copied from Reference\doom3\neo\framework\FileSystem.cpp with idStr replaced by std::string
// (the bodies of the loops are verbatim). Output is compared with the Delphi port in the DUnitX tests.
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>
using namespace std;
typedef vector<string> idStrList;

static char ToLowerC(char c) { return (c >= 'A' && c <= 'Z') ? c + ('a' - 'A') : c; }
static int Icmp(const char *a, const char *b) {
	for (;; a++, b++) {
		int c1 = ToLowerC(*a), c2 = ToLowerC(*b);
		if (c1 != c2) return c1 < c2 ? -1 : 1;
		if (!c1) return 0;
	}
}
static int Icmpn(const char *a, const char *b, int n) {
	do {
		int c1 = ToLowerC(*a++), c2 = ToLowerC(*b++);
		if (!n--) return 0;
		if (c1 != c2) return c1 < c2 ? -1 : 1;
		if (!c1) return 0;
	} while (1);
}
static void StripTrailing(string &s, char c) { while (!s.empty() && s.back() == c) s.pop_back(); }

#define FILE_HASH_SIZE 1024
long HashFileName(const char *fname) {
	int i; long hash; char letter;
	hash = 0; i = 0;
	while (fname[i] != '\0') {
		letter = ToLowerC(fname[i]);
		if (letter == '.') break;
		if (letter == '\\') letter = '/';
		hash += (long)(letter) * (i + 119);
		i++;
	}
	hash &= (FILE_HASH_SIZE - 1);
	return hash;
}
bool FilenameCompare(const char *s1, const char *s2) {
	int c1, c2;
	do {
		c1 = *s1++; c2 = *s2++;
		if (c1 >= 'a' && c1 <= 'z') c1 -= ('a' - 'A');
		if (c2 >= 'a' && c2 <= 'z') c2 -= ('a' - 'A');
		if (c1 == '\\' || c1 == ':') c1 = '/';
		if (c2 == '\\' || c2 == ':') c2 = '/';
		if (c1 != c2) return true;
	} while (c1);
	return false;
}

static vector<string> pak;
static int AddUnique(const string &name, idStrList &list) {
	for (size_t i = 0; i < list.size(); i++) if (Icmp(list[i].c_str(), name.c_str()) == 0) return (int)i;
	list.push_back(name);
	return (int)list.size() - 1;
}

int GetFileList(const char *relativePath, const idStrList &extensions, idStrList &list, bool fullRelativePath) {
	int i, j, pathLength, length;
	const char *name;
	string work;
	if (!extensions.size()) return 0;
	pathLength = strlen(relativePath);
	if (pathLength) pathLength++;
	for (i = 0; i < (int)pak.size(); i++) {
		length = pak[i].length();
		if (length <= pathLength) continue;
		name = pak[i].c_str();
		if (pathLength && Icmpn(name, relativePath, pathLength - 1) != 0) continue;
		if (name[pathLength] == '\0' || name[pathLength - 1] != '/') continue;
		for (j = pathLength; name[j + 1] != '\0'; j++) { if (name[j] == '/') break; }
		if (name[j + 1]) continue;
		for (j = 0; j < (int)extensions.size(); j++) {
			if (length >= (int)extensions[j].length() && Icmp(extensions[j].c_str(), name + length - extensions[j].length()) == 0) break;
		}
		if (j >= (int)extensions.size()) continue;
		if (fullRelativePath) {
			work = relativePath; work += "/"; work += name + pathLength;
			StripTrailing(work, '/');
			AddUnique(work, list);
		} else {
			work = name + pathLength;
			StripTrailing(work, '/');
			AddUnique(work, list);
		}
	}
	return (int)list.size();
}

int GetFileListTree(const char *relativePath, const idStrList &extensions, idStrList &list) {
	int i;
	idStrList slash, folders;
	slash.push_back("/");
	GetFileList(relativePath, slash, folders, true);
	for (i = 0; i < (int)folders.size(); i++) {
		if (folders[i][0] == '.') continue;
		if (Icmp(folders[i].c_str(), relativePath) == 0) continue;
		GetFileListTree(folders[i].c_str(), extensions, list);
	}
	GetFileList(relativePath, extensions, list, true);
	return (int)list.size();
}

static idStrList Split(const char *e) {
	idStrList r; string s = e; size_t st = 0;
	for (;;) { size_t b = s.find('|', st); if (b == string::npos) { r.push_back(s.substr(st)); break; } r.push_back(s.substr(st, b - st)); st = b + 1; }
	return r;
}
static void Print(const char *tag, const idStrList &l) {
	printf("%s=", tag);
	for (size_t i = 0; i < l.size(); i++) printf("%s%s", i ? "," : "", l[i].c_str());
	printf("\n");
}

int main() {
	const char *names[] = { "textures/wall.tga", "textures/sub/a.tga", "textures/sub/deep/b.tga", "textures/", "textures/sub/", "textures/sub/deep/",
		"def/a.def", "def/b.def", "def.txt", "deftxt/x.def", "readme.txt", "sound/", "sound/x.wav", "maps/test.map", "a/b/c/d.e", "a/b/", "a/", "a", "Zed/Up.TGA" };
	for (const char *n : names) { string l = n; for (auto &c : l) c = ToLowerC(c); pak.push_back(l); }
	const char *hashes[] = { "a", "ab.c", "a/b", "A\\B", "a:b", "textures/wall.tga", "TEXTURES\\Wall.TGA", "def/a.def", "readme.txt", "zed/up.tga", "" };
	for (const char *h : hashes) printf("H|%s|%ld\n", h, HashFileName(h));
	const char *cmp[][2] = { {"Textures\\Wall.TGA", "textures/wall.tga"}, {"a:b", "a/b"}, {"a/b", "a/bc"}, {"a/b", "a/c"}, {"", ""}, {"abc", "ABD"} };
	for (auto &p : cmp) printf("C|%s|%s|%d\n", p[0], p[1], FilenameCompare(p[0], p[1]) ? 0 : 1);
	struct Q { const char *path; const char *ext; bool full; } qs[] = {
		{"textures", "tga", false}, {"textures", "tga", true}, {"textures", "/", false}, {"textures", "/", true}, {"textures/sub", "tga|def", false},
		{"def", "def", false}, {"def", "", false}, {"a", "/", true}, {"a/b", "", true}, {"TEXTURES", "tga", false}, {"textures/", "tga", false},
		{"nothing", "tga", false}, {"sound", "wav|WAV", true}, {"zed", "tga", false}, {"tex", "", false}, {"a", "", false} };
	for (auto &q : qs) { idStrList r; GetFileList(q.path, Split(q.ext), r, q.full); char tag[200]; sprintf(tag, "L|%s|%s|%d", q.path, q.ext, q.full ? 1 : 0); Print(tag, r); }
	struct T { const char *path; const char *ext; } ts[] = { {"textures", "tga"}, {"a", ""}, {"", "tga"}, {"sound", "wav"} };
	for (auto &t : ts) { if (!t.path[0]) continue; idStrList r; GetFileListTree(t.path, Split(t.ext), r); char tag[200]; sprintf(tag, "T|%s|%s", t.path, t.ext); Print(tag, r); }
	return 0;
}

