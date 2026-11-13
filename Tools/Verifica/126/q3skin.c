/* Parity driver of the issue #126, second slice: the skins and the files of a player model.
   Usage: q3skin <folder with fs.txt and the .skin files>
   It runs the original RE_RegisterSkin / CommaParse / R_GetSkinByHandle (renderer\tr_image.c) and
   CG_FindClientModelFile / CG_FindClientHeadFile (cgame\cg_players.c) and writes one line per case:
   "inputs | outputs". Strings are written between [ ]. */
#include "stubs.h"

#define MAX_SKINS 1024
#define MAX_TEST_FILES 256

typedef struct shader_s { char name[MAX_QPATH]; int index; struct shader_s *next; } shader_t;
typedef struct {
	char		name[MAX_QPATH];
	shader_t	*shader;
} skinSurface_t;

typedef struct skin_s {
	char		name[MAX_QPATH];		// game path, including extension
	int			numSurfaces;
	skinSurface_t	*surfaces[MD3_MAX_SURFACES];
} skin_t;

typedef struct {
	int numSkins;
	skin_t *skins[MAX_SKINS];
	shader_t *defaultShader;
} trGlobals_t;
static trGlobals_t tr;

#define PRINT_ALL 0
#define PRINT_DEVELOPER 1
#define PRINT_WARNING 2
#define h_low 0

/* ---------------- messages ---------------- */
static char g_msgs[64][512];
static int g_msgCount;
void Com_Printf(const char *fmt, ...) {
	va_list ap;
	char *p;
	va_start(ap, fmt);
	vsnprintf(g_msgs[g_msgCount < 63 ? g_msgCount : 63], 512, fmt, ap);
	va_end(ap);
	p = g_msgs[g_msgCount < 63 ? g_msgCount : 63];
	if (strlen(p) && p[strlen(p) - 1] == '\n') p[strlen(p) - 1] = 0;
	g_msgCount++;
}
void Com_Error(int level, const char *fmt, ...) {
	va_list ap;
	va_start(ap, fmt);
	vprintf(fmt, ap);
	va_end(ap);
	exit(2);
}
static void ri_Printf(int level, const char *fmt, ...) {
	va_list ap;
	char *p;
	if (level == PRINT_DEVELOPER) return;
	va_start(ap, fmt);
	vsnprintf(g_msgs[g_msgCount < 63 ? g_msgCount : 63], 512, fmt, ap);
	va_end(ap);
	p = g_msgs[g_msgCount < 63 ? g_msgCount : 63];
	if (strlen(p) && p[strlen(p) - 1] == '\n') p[strlen(p) - 1] = 0;
	g_msgCount++;
}
static void flush_msgs(void) {
	int i;
	for (i = 0; i < g_msgCount && i < 64; i++) printf("msg %d | [%s]\n", i, g_msgs[i]);
	g_msgCount = 0;
}

/* ---------------- the file system ---------------- */
static char g_folder[512];
static char g_fsNames[MAX_TEST_FILES][128];
static int g_fsLens[MAX_TEST_FILES];
static int g_fsCount;
static void load_fs(void) {
	char path[1024], line[256];
	FILE *f;
	snprintf(path, sizeof(path), "%s/fs.txt", g_folder);
	f = fopen(path, "r");
	if (!f) { fprintf(stderr, "no fs.txt\n"); exit(1); }
	while (fgets(line, sizeof(line), f) && g_fsCount < MAX_TEST_FILES) {
		char name[128];
		int len;
		if (sscanf(line, "%127s %d", name, &len) == 2) {
			strcpy(g_fsNames[g_fsCount], name);
			g_fsLens[g_fsCount++] = len;
		}
	}
	fclose(f);
}
static int trap_FS_FOpenFile(const char *qpath, fileHandle_t *f, int mode) {
	int i;
	for (i = 0; i < g_fsCount; i++)
		if (!strcmp(g_fsNames[i], qpath)) return g_fsLens[i];
	return -1;
}
static int ri_FS_ReadFile(const char *name, void **buffer) {
	char path[1024];
	FILE *f;
	long len;
	char *text;
	snprintf(path, sizeof(path), "%s/%s", g_folder, name);
	f = fopen(path, "rb");
	if (!f) { *buffer = NULL; return -1; }
	fseek(f, 0, SEEK_END);
	len = ftell(f);
	fseek(f, 0, SEEK_SET);
	text = (char *)malloc(len + 1);
	fread(text, 1, len, f);
	text[len] = 0;
	fclose(f);
	*buffer = text;
	return (int)len;
}
static void ri_FS_FreeFile(void *buffer) { free(buffer); }
static void *ri_Hunk_Alloc(int size, int preference) { return calloc(1, size); }
static void R_SyncRenderThread(void) {}

/* the shaders: one object for every name, the empty name is the default shader */
static shader_t *g_shaders;
static shader_t *R_FindShader(const char *name, int lightmapIndex, qboolean mipRawImage) {
	shader_t *s;
	if (!name[0]) return tr.defaultShader;
	for (s = g_shaders; s; s = s->next)
		if (!strcmp(s->name, name)) return s;
	s = (shader_t *)calloc(1, sizeof(*s));
	strncpy(s->name, name, MAX_QPATH - 1);
	s->next = g_shaders;
	g_shaders = s;
	return s;
}
#define LIGHTMAP_NONE -1

/* the original calls ri.Printf, ri.Hunk_Alloc, ri.FS_ReadFile, ri.FS_FreeFile */
static struct {
	void (*Printf)(int, const char *, ...);
	void *(*Hunk_Alloc)(int, int);
	int (*FS_ReadFile)(const char *, void **);
	void (*FS_FreeFile)(void *);
} ri = { ri_Printf, ri_Hunk_Alloc, ri_FS_ReadFile, ri_FS_FreeFile };

#include "skin_original.inc"

/* ---------------- the game that the finders read ---------------- */
typedef struct { int team; } clientInfo_t;
typedef struct { int gametype; } cgs_t;
static cgs_t cgs;


#include "types_original.inc"
#include "finder_original.inc"

/* ---------------- the driver ---------------- */
static void dump_skin(int handle) {
	skin_t *skin = R_GetSkinByHandle(handle);
	int i;
	printf("skin %d | [%s] %d", handle, skin->name, skin->numSurfaces);
	/* the default skin of R_InitSkins writes a shader pointer past a block of sizeof(skinSurface_t *): its shader is not listed */
	for (i = 0; i < skin->numSurfaces && handle > 0 && handle < tr.numSkins; i++)
		printf(" [%s]=[%s]", skin->surfaces[i]->name, skin->surfaces[i]->shader->name);
	printf("\n");
	flush_msgs();
}

static void reg(const char *name) {
	int h = RE_RegisterSkin(name);
	printf("reg [%s] | %d %d\n", name, h, tr.numSkins);
	flush_msgs();
	if (h > 0) dump_skin(h);
}

static void find_scenarios(void) {
	static const char *teamNames[] = { "-", "Stroggs/" };
	static const char *models[] = { "test", "gen", "none" };
	static const char *skins[] = { "default", "red", "blue", "alt" };
	static const char *heads[] = { "test", "*kate", "gen", "*nobody" };
	static const char *modelBases[] = { "lower", "upper" };
	static const char *headBases[] = { "head", "icon" };
	static const char *exts[] = { "skin", "tga" };
	int gt, team, tn, m, s, b, e;
	char filename[MAX_QPATH];
	clientInfo_t ci;
	for (gt = 0; gt < 2; gt++)
		for (team = 0; team < 4; team++)
			for (tn = 0; tn < 2; tn++)
				for (s = 0; s < 4; s++) {
					cgs.gametype = gt ? GT_TEAM : 0;
					ci.team = team;
					for (m = 0; m < 3; m++)
						for (b = 0; b < 2; b++) {
							int ok = CG_FindClientModelFile(filename, sizeof(filename), &ci, tn ? teamNames[tn] : "", models[m], skins[s], modelBases[b], "skin");
							printf("findm %d %d [%s] [%s] [%s] [%s] | %d [%s]\n", gt, team, tn ? teamNames[tn] : "", models[m], skins[s], modelBases[b], ok, filename);
							flush_msgs();
						}
					for (m = 0; m < 4; m++)
						for (b = 0; b < 2; b++)
							for (e = 0; e < 2; e++) {
								int ok = CG_FindClientHeadFile(filename, sizeof(filename), &ci, tn ? teamNames[tn] : "", heads[m], skins[s], headBases[b], exts[e]);
								printf("findh %d %d [%s] [%s] [%s] [%s] [%s] | %d [%s]\n", gt, team, tn ? teamNames[tn] : "", heads[m], skins[s], headBases[b], exts[e], ok, filename);
								flush_msgs();
							}
				}
}

int main(int argc, char **argv) {
	char line[512];
	char path[1024];
	FILE *f;
	if (argc < 2) return 1;
	snprintf(g_folder, sizeof(g_folder), "%s", argv[1]);
	load_fs();
	tr.defaultShader = (shader_t *)calloc(1, sizeof(shader_t));
	R_InitSkins();
	/* the names to register, one per line of regs.txt, in order */
	snprintf(path, sizeof(path), "%s/regs.txt", g_folder);
	f = fopen(path, "r");
	if (!f) return 1;
	while (fgets(line, sizeof(line), f)) {
		size_t n = strlen(line);
		while (n && (line[n - 1] == '\n' || line[n - 1] == '\r')) line[--n] = 0;
		if (line[0] == '#') continue;
		if (!strcmp(line, "<empty>")) line[0] = 0;
		reg(line);
	}
	fclose(f);
	dump_skin(0);
	dump_skin(99999);
	find_scenarios();
	return 0;
}
