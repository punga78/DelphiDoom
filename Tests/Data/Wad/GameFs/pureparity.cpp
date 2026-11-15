// Derived from the Doom 3 GPL Source Code (id Software, GPL v3 with additional terms): the code is copied from
// neo\framework\FileSystem.cpp. Build with bcc32c (no flags), run, compare with
// Tests\Source\DelphiDoom.Tests.Wad.PureServer.pas (the expected output is pureparity.expected.txt).
// Parity harness for the pure server: the pure exclusion table and GetPackStatus (the content loop and the name
// check), the checksum parse of ParseAddonDef (the two sscanf) and the loop of SetPureServerChecksums, with idStr
// replaced by std::string and the packs by small structs (the bodies of the loops are verbatim, without the debug
// output and without the game code pak).
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>
using namespace std;

static char ToLowerC(char c) { return (c >= 'A' && c <= 'Z') ? c + ('a' - 'A') : c; }
static int Icmp(const char *a, const char *b) {
	for (;; a++, b++) {
		int c1 = ToLowerC(*a), c2 = ToLowerC(*b);
		if (c1 != c2) return c1 < c2 ? -1 : 1;
		if (!c1) return 0;
	}
}
static int IcmpnPath(const char *s1, const char *s2, int n) {
	int c1, c2;
	do {
		c1 = *s1++;
		c2 = *s2++;
		if (!n--) return 0;
		if (c1 != c2) {
			if (c1 >= 'a' && c1 <= 'z') c1 -= ('a' - 'A');
			if (c2 >= 'a' && c2 <= 'z') c2 -= ('a' - 'A');
			if (c1 == '\\') c1 = '/';
			if (c2 == '\\') c2 = '/';
			if (c1 < c2) return -1;
			if (c1 > c2) return 1;
		}
	} while (c1);
	return 0;
}

#define DOOM3_PURE_SPECIAL_CASES
typedef bool (*pureExclusionFunc_t)(const struct pureExclusion_s &excl, int l, const string &name);
typedef struct pureExclusion_s {
	int nameLen;
	int extLen;
	const char *name;
	const char *ext;
	pureExclusionFunc_t func;
} pureExclusion_t;

bool excludeExtension(const pureExclusion_t &excl, int l, const string &name) {
	if (l > excl.extLen && !Icmp(name.c_str() + l - excl.extLen, excl.ext)) {
		return true;
	}
	return false;
}
bool excludePathPrefixAndExtension(const pureExclusion_t &excl, int l, const string &name) {
	if (l > excl.nameLen && !Icmp(name.c_str() + l - excl.extLen, excl.ext) && !IcmpnPath(name.c_str(), excl.name, (int)strlen(excl.name))) {
		return true;
	}
	return false;
}
bool excludeFullName(const pureExclusion_t &excl, int l, const string &name) {
	if (l == excl.nameLen && !Icmp(name.c_str(), excl.name)) {
		return true;
	}
	return false;
}

static pureExclusion_t pureExclusions[] = {
	{ 0,	0,	NULL,											"/",		excludeExtension },
	{ 0,	0,	NULL,											"\\",		excludeExtension },
	{ 0,	0,	NULL,											".pda",		excludeExtension },
	{ 0,	0,	NULL,											".gui",		excludeExtension },
	{ 0,	0,	NULL,											".pd",		excludeExtension },
	{ 0,	0,	NULL,											".lang",	excludeExtension },
	{ 0,	0,	"sound/VO",										".ogg",		excludePathPrefixAndExtension },
	{ 0,	0,	"sound/VO",										".wav",		excludePathPrefixAndExtension },
#if	defined DOOM3_PURE_SPECIAL_CASES
	{ 0,	0,	"sound/ed/marscity/vo_intro_cutscene.ogg",		NULL,		excludeFullName },
	{ 0,	0,	"sound/weapons/soulcube/energize_01.ogg",		NULL,		excludeFullName },
	{ 0,	0,	"sound/xian/creepy/vocal_fx",					".ogg",		excludePathPrefixAndExtension },
	{ 0,	0,	"sound/xian/creepy/vocal_fx",					".wav",		excludePathPrefixAndExtension },
	{ 0,	0,	"sound/feedback",								".ogg",		excludePathPrefixAndExtension },
	{ 0,	0,	"sound/feedback",								".wav",		excludePathPrefixAndExtension },
	{ 0,	0,	"guis/assets/mainmenu/chnote.tga",				NULL,		excludeFullName },
	{ 0,	0,	"sound/levels/alphalabs2/uac_better_place.ogg",	NULL,		excludeFullName },
	{ 0,	0,	"textures/bigchars.tga",						NULL,		excludeFullName },
	{ 0,	0,	"dds/textures/bigchars.dds",					NULL,		excludeFullName },
	{ 0,	0,	"fonts",										".tga",		excludePathPrefixAndExtension },
	{ 0,	0,	"dds/fonts",									".dds",		excludePathPrefixAndExtension },
	{ 0,	0,	"default.cfg",									NULL,		excludeFullName },
	{ 0,	0,  "fonts",										".dat",		excludePathPrefixAndExtension },
	{ 0,	0,	"guis/temp.guied",								NULL,		excludeFullName },
#endif
	{ 0,	0,	NULL,											NULL,		NULL }
};

static void InitExclusions() {
	for (int i = 0; pureExclusions[i].func != NULL; i++) {
		if (pureExclusions[i].name) pureExclusions[i].nameLen = (int)strlen(pureExclusions[i].name);
		if (pureExclusions[i].ext) pureExclusions[i].extLen = (int)strlen(pureExclusions[i].ext);
	}
}

static bool IsExcluded(const string &name) {
	int l = (int)name.length();
	for (int j = 0; pureExclusions[j].func != NULL; j++) {
		if (pureExclusions[j].func(pureExclusions[j], l, name)) return true;
	}
	return false;
}

// GetPackStatus: 0 unknown, 1 neutral, 2 always, 3 never (the numbers of pureStatus_t)
static int PackStatus(const vector<string> &names, const string &pakFilename) {
	size_t i = 0;
	bool abrt = false;
	for (size_t n = 0; n < names.size(); n++) {
		abrt = true;
		int l = (int)names[n].length();
		for (int j = 0; pureExclusions[j].func != NULL; j++) {
			if (pureExclusions[j].func(pureExclusions[j], l, names[n])) {
				abrt = false;
				break;
			}
		}
		if (abrt) break;
		i++;
	}
	if (i == names.size()) return 3;
	string name = pakFilename;
	size_t slash = name.find_last_of("/\\");
	if (slash != string::npos) name = name.substr(slash + 1);
	if (!IcmpnPath(name.c_str(), "pak", 3)) return 2;
	return 1;
}

struct Pack { unsigned int checksum; bool addon; bool addon_search; bool referenced; int status; bool hasDll; };
static vector<Pack *> searchPacks;
static vector<Pack *> addonPacks;
static vector<Pack *> serverPaks;

static Pack *GetPackForChecksum(int checksum, bool searchAddons) {
	for (size_t i = 0; i < searchPacks.size(); i++) {
		if ((int)searchPacks[i]->checksum == checksum) return searchPacks[i];
	}
	if (searchAddons) {
		for (size_t i = 0; i < addonPacks.size(); i++) {
			if ((int)addonPacks[i]->checksum == checksum) return addonPacks[i];
		}
	}
	return NULL;
}

static void UpdatePureServerChecksums() {
	serverPaks.clear();
	for (size_t s = 0; s < searchPacks.size(); s++) {
		Pack *p = searchPacks[s];
		int status = p->status;
		if (status == 3) continue;
		if (status == 1 && !p->referenced) continue;
		serverPaks.push_back(p);
	}
}

// 0 ok, 1 restart, 2 missing
static int SetPureServerChecksums(const int *pureChecksums, bool loadedFileFromDir, vector<int> &missing) {
	Pack *pack;
	int i, j;
	bool success = true;
	bool canPrepend = true;
	missing.clear();
	if (pureChecksums[0] == 0) {
		serverPaks.clear();
		return 0;
	}
	if (!serverPaks.size()) {
		UpdatePureServerChecksums();
	}
	i = 0; j = 0;
	while (pureChecksums[i]) {
		if (j < (int)serverPaks.size() && (int)serverPaks[j]->checksum == pureChecksums[i]) {
			canPrepend = false;
			i++; j++;
		} else {
			pack = GetPackForChecksum(pureChecksums[i], true);
			if (pack && pack->addon && !pack->addon_search) {
				success = false;
			}
			if (pack) {
				if (canPrepend) {
					serverPaks.insert(serverPaks.begin() + j, pack);
					i++; j++;
				} else {
					success = false;
					i++;
				}
			} else {
				success = false;
				missing.push_back(pureChecksums[i]);
				i++;
			}
		}
	}
	while (j < (int)serverPaks.size()) {
		success = false;
		j++;
	}
	if (missing.size()) return 2;
	if (loadedFileFromDir) success = false;
	return success ? 0 : 1;
}

static void PrintServer() {
	printf(" server=");
	for (size_t i = 0; i < serverPaks.size(); i++) printf("%s%x", i ? "," : "", serverPaks[i]->checksum);
}

static Pack MakePack(unsigned int checksum, bool addon, bool addon_search, bool referenced, int status, bool hasDll = false) {
	Pack p; p.checksum = checksum; p.addon = addon; p.addon_search = addon_search; p.referenced = referenced; p.status = status; p.hasDll = hasDll;
	return p;
}

// ---- the game code pak (issue #236): the DLL block of SetPureServerChecksums and SetRestartChecksums, verbatim
// from FileSystem.cpp; "the pak has the DLL" replaces the walk of the hash chain with FilenameCompare, and the
// fatal error of SetRestartChecksums is a flag
static int gamePakChecksum = 0;
static vector<int> restartChecksums;
static vector<int> addonChecksums;
static int restartGamePakChecksum = 0;
static bool restartFatal = false;

// the loop of SetPureServerChecksums above, then the DLL part. 0 ok, 1 restart, 2 missing, 3 no dll
static int SetPureServerChecksumsDll(const int *pureChecksums, bool loadedFileFromDir, int _gamePakChecksum, vector<int> &missing, int *missingGamePakChecksum) {
	int reply = SetPureServerChecksums(pureChecksums, loadedFileFromDir, missing);
	// SetPureServerChecksums answered 0 for an empty list without reading the code pak: the original returns there too
	if (pureChecksums[0] == 0) return reply;
	int imissing = (int)missing.size();
	*missingGamePakChecksum = 0;
	// DLL checksuming
	if (!_gamePakChecksum) {
		// server doesn't have knowledge of code we can use ( OS issue )
		return 3;
	}
	if (_gamePakChecksum != gamePakChecksum) {
		// current DLL is wrong, search for a pak with the approriate checksum
		Pack *pack = GetPackForChecksum(_gamePakChecksum, false);
		if (!pack) {
			*missingGamePakChecksum = _gamePakChecksum;
			return 2;
		}
		// if assets paks are missing, don't try any of the DLL restart / NODLL
		if (imissing) return 2;
		// make sure there is a valid DLL for us
		if (pack->hasDll) {
			gamePakChecksum = _gamePakChecksum;
			return 1;
		}
		return 3;
	}
	return reply;
}

static void SetRestartChecksums(const int *pureChecksums, int gamePak) {
	restartChecksums.clear();
	restartFatal = false;
	int i = 0;
	while (pureChecksums[i]) {
		Pack *pack = GetPackForChecksum(pureChecksums[i], true);
		if (!pack) {
			restartFatal = true;
			return;
		}
		bool found = false;
		for (size_t k = 0; k < addonChecksums.size(); k++) if (addonChecksums[k] == (int)pack->checksum) found = true;
		if (pack->addon && !found) addonChecksums.push_back(pack->checksum);
		restartChecksums.push_back(pureChecksums[i]);
		i++;
	}
	restartGamePakChecksum = gamePak;
}

static void PrintList(const vector<int> &v) {
	for (size_t i = 0; i < v.size(); i++) printf("%s%x", i ? "," : "", v[i]);
}

static void Scenario(const char *name, const int *list, bool fromDir) {
	vector<int> missing;
	int reply = SetPureServerChecksums(list, fromDir, missing);
	printf("pure %s reply=%d missing=", name, reply);
	for (size_t i = 0; i < missing.size(); i++) printf("%s%x", i ? "," : "", missing[i]);
	PrintServer();
	printf("\n");
}

int main() {
	InitExclusions();
	const char *names[] = {
		"guis/main.gui", "sound/vo/line.ogg", "SOUND\\VO\\line.WAV", "sound/vox/line.ogg", "sound", "sound/", "x\\", "fonts/a.tga",
		"fonts/a.dat", "FONTS/b.TGA", "dds/fonts/a.dds", "dds/fonts", "default.cfg", "Default.cfg", "default.cfg2", "textures/bigchars.tga",
		"guis/temp.guied", "readme.txt", "a.pd", ".pd", "a.pda", "maps/a.lang", "sound/feedback/x.ogg", "sound/feedbacks/x.ogg",
		"sound/xian/creepy/vocal_fx/a.wav", "sound/ed/marscity/vo_intro_cutscene.ogg", "sound/ed/marscity/vo_intro_cutscene.ogg2", "", "a", NULL
	};
	for (int i = 0; names[i]; i++) printf("excl %s %d\n", names[i], IsExcluded(names[i]) ? 1 : 0);

	{
		vector<string> v;
		v.push_back("a.gui"); v.push_back("b/");
		printf("status gui-only %d\n", PackStatus(v, "c:\\d3\\base\\pak000.pk4"));
		v.push_back("c.txt");
		printf("status pak-name %d\n", PackStatus(v, "c:\\d3\\base\\PAK000.pk4"));
		printf("status pak-slash %d\n", PackStatus(v, "c:/d3/base/Pak001.pk4"));
		printf("status other %d\n", PackStatus(v, "c:\\d3\\base\\zpak001.pk4"));
		printf("status no-folder %d\n", PackStatus(v, "pakx.pk4"));
		vector<string> empty;
		printf("status empty %d\n", PackStatus(empty, "pak.pk4"));
	}

	const char *chk[] = { "0x1A2B3C4D", "0X1a2b", "1a2b3c4d", "0x", "xyz", "", "  0x10", "12zz", "0xffffffff", "0x1ffffffff", "-1", "0", "0xg", NULL };
	for (int i = 0; chk[i]; i++) {
		int checksum = 0;
		bool ok = !(sscanf(chk[i], "0x%x", &checksum) != 1 && sscanf(chk[i], "%x", &checksum) != 1);
		printf("chk [%s] %d %x\n", chk[i], ok ? 1 : 0, ok ? checksum : 0);
	}

	// local paks: 1 always, 2 neutral referenced, 3 neutral not referenced, 4 never, 5 addon searched, 6 addon left out
	Pack p1 = MakePack(0x11, false, false, false, 2);
	Pack p2 = MakePack(0x22, false, false, true, 1);
	Pack p3 = MakePack(0x33, false, false, false, 1);
	Pack p4 = MakePack(0x44, false, false, false, 3);
	Pack p5 = MakePack(0x55, true, true, false, 2);
	Pack p6 = MakePack(0x66, true, false, false, 1);
	searchPacks.push_back(&p1); searchPacks.push_back(&p2); searchPacks.push_back(&p3);
	searchPacks.push_back(&p4); searchPacks.push_back(&p5);
	addonPacks.push_back(&p6);

	{ serverPaks.clear(); UpdatePureServerChecksums(); printf("update"); PrintServer(); printf("\n"); }
	{ int l[] = { 0 }; serverPaks.clear(); Scenario("empty-clears", l, false); }
	{ int l[] = { 0x11, 0x22, 0x55, 0 }; serverPaks.clear(); Scenario("same", l, false); }
	{ int l[] = { 0x11, 0x22, 0x55, 0 }; serverPaks.clear(); Scenario("same-fromdir", l, true); }
	{ int l[] = { 0x33, 0x11, 0x22, 0x55, 0 }; serverPaks.clear(); Scenario("prepend", l, false); }
	{ int l[] = { 0x11, 0x33, 0x22, 0x55, 0 }; serverPaks.clear(); Scenario("wrong-order", l, false); }
	{ int l[] = { 0x11, 0x22, 0 }; serverPaks.clear(); Scenario("extra-local", l, false); }
	{ int l[] = { 0x99, 0x11, 0x22, 0x55, 0 }; serverPaks.clear(); Scenario("missing-first", l, false); }
	{ int l[] = { 0x11, 0x99, 0x22, 0x88, 0x55, 0 }; serverPaks.clear(); Scenario("missing-two", l, false); }
	{ int l[] = { 0x66, 0x11, 0x22, 0x55, 0 }; serverPaks.clear(); Scenario("addon-left-out", l, false); }
	{ int l[] = { 0x11, 0x22, 0x55, 0x66, 0 }; serverPaks.clear(); Scenario("addon-after", l, false); }
	{ int l[] = { 0x44, 0x11, 0x22, 0x55, 0 }; serverPaks.clear(); Scenario("never-pak-asked", l, false); }
	{ int l[] = { 0x22, 0x11, 0 }; serverPaks.clear(); Scenario("swapped", l, false); }
	{
		// a lock that already exists is kept and extended
		int first[] = { 0x22, 0 };
		serverPaks.clear(); Scenario("lock-one", first, false);
		int second[] = { 0x33, 0x22, 0 };
		Scenario("lock-extend", second, false);
	}

	// the game code (issue #236): the loaded code pak is 0x70; 0x77 holds the DLL, 0x88 does not
	Pack p7 = MakePack(0x77, false, false, false, 2, true);
	Pack p8 = MakePack(0x88, false, false, false, 2, false);
	searchPacks.push_back(&p7); searchPacks.push_back(&p8);
	struct DllCase { const char *name; int list[8]; bool fromDir; int game; };
	const DllCase dll[] = {
		{ "no-code", { 0x11, 0x22, 0x55, 0x77, 0x88, 0 }, false, 0 },
		{ "same-code", { 0x11, 0x22, 0x55, 0x77, 0x88, 0 }, false, 0x70 },
		{ "same-code-fromdir", { 0x11, 0x22, 0x55, 0x77, 0x88, 0 }, true, 0x70 },
		{ "other-code", { 0x11, 0x22, 0x55, 0x77, 0x88, 0 }, false, 0x77 },
		{ "code-without-dll", { 0x11, 0x22, 0x55, 0x77, 0x88, 0 }, false, 0x88 },
		{ "code-not-installed", { 0x11, 0x22, 0x55, 0x77, 0x88, 0 }, false, 0x99 },
		{ "other-code-assets-missing", { 0x11, 0xaa, 0x22, 0x55, 0x77, 0x88, 0 }, false, 0x77 },
		{ "same-code-assets-missing", { 0x11, 0xaa, 0x22, 0x55, 0x77, 0x88, 0 }, false, 0x70 },
		{ "not-installed-assets-missing", { 0x11, 0xaa, 0x22, 0x55, 0x77, 0x88, 0 }, false, 0x99 },
		{ "empty-list", { 0 }, false, 0x77 },
	};
	for (size_t c = 0; c < sizeof(dll) / sizeof(dll[0]); c++) {
		vector<int> missing;
		int missingGame = 0;
		gamePakChecksum = 0x70;
		serverPaks.clear();
		int reply = SetPureServerChecksumsDll(dll[c].list, dll[c].fromDir, dll[c].game, missing, &missingGame);
		printf("dll %s reply=%d missing=", dll[c].name, reply);
		PrintList(missing);
		printf(" gamemissing=%x gamepak=%x", missingGame, gamePakChecksum);
		PrintServer();
		printf("\n");
	}

	// SetRestartChecksums
	{
		struct RestartCase { const char *name; int list[6]; int game; };
		const RestartCase rc[] = {
			{ "plain", { 0x11, 0x22, 0 }, 0x77 },
			{ "addon-searched", { 0x55, 0x11, 0 }, 0x70 },
			{ "addon-left-out", { 0x66, 0x11, 0 }, 0x70 },
			{ "addon-again", { 0x66, 0x22, 0 }, 0x71 },
			{ "unknown", { 0x11, 0x99, 0 }, 0x72 },
			{ "empty", { 0 }, 0x73 },
		};
		for (size_t c = 0; c < sizeof(rc) / sizeof(rc[0]); c++) {
			SetRestartChecksums(rc[c].list, rc[c].game);
			printf("restart %s fatal=%d restart=", rc[c].name, restartFatal ? 1 : 0);
			if (!restartFatal) PrintList(restartChecksums);
			printf(" addons=");
			PrintList(addonChecksums);
			printf(" game=%x\n", restartFatal ? 0 : restartGamePakChecksum);
		}
	}
	return 0;
}
