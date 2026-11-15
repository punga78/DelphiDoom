/*
 * Parity tool of the issue #123 (goals, movement and genetic selection of the bots of Quake III Arena).
 *
 * It links the REAL be_ai_goal.c, be_ai_move.c, be_ai_gen.c, be_ea.c, be_ai_weight.c, be_aas_file.c, be_aas_sample.c,
 * be_aas_route.c, be_aas_routealt.c, be_aas_move.c and be_aas_bspq3.c of code/botlib (included below, one translation
 * unit, read only, copied by build.sh) plus l_struct.c, l_libvar.c, l_script.c and l_precomp.c with the stubs of the
 * folder stub/, and runs the commands of a scenario file, one per line:
 *     command|argument|argument...
 * For every command the line is echoed (prefix ">") and the results are printed. What the library prints
 * (botimport.Print) is a line "P<level>|text", what it writes to its log "L|text", what it sends to the game
 * (botimport.BotClientCommand) "C|client|text". Floats are printed as the 8 hexadecimal digits of their bits.
 * The twin of this file is Tests/Source/DelphiDoom.Tests.BotAi.GoalMoveScenario.pas: every line printed here is
 * printed there with the same text.
 *
 *   aigen <data folder> <scenario file>   (the data folder contains botfiles/ and the .aas files)
 *
 * The world that is not the AAS (the BSP of the game) is a twin that Delphi has too: botimport.Trace is the trace of
 * the box of a standing client through the AAS (AAS_TraceClientBBox), plus the solid boxes of the scenario (command
 * "solid"); the contents of a point are those of its AAS area; the entities (aas_entityinfo_t) are the table of the
 * command "entity"; the models are the table of the command "model"; AAS_BestReachableArea is the area of the point
 * when it has reachabilities.
 * Compiled without DEBUG, RANDOMIZE and MISSIONPACK (so FuzzyWeight, not FuzzyWeightUndecided, and GT_TEAM is 3).
 */
#include "game/q_shared.h"
#include "game/botlib.h"
#include "botlib/aasfile.h"
#include "game/be_aas.h"
#include "botlib/be_aas_funcs.h"
#include "botlib/be_interface.h"
#include "botlib/be_aas_def.h"
#include "botlib/l_crc.h"
#include "botlib/l_log.h"
#include "botlib/l_libvar.h"
#include "botlib/l_script.h"
#include "botlib/l_precomp.h"
#include "botlib/l_struct.h"

#include "vmath.inc"
#include "aaserror.inc"
#include "areareach.inc"
#include "projectpoint.inc"

float AAS_Time(void);
int Sys_MilliSeconds(void);
void Com_sprintf2(char *dest, int size, const char *fmt, ...);
int AvailableMemory(void);
float AAS_AreaGroundFaceArea(int areanum);
void AAS_DecompressVis(byte *in, int numareas, byte *decompressed);
int AAS_CompressVis(byte *vis, int numareas, byte *dest);


#include "botlib/be_aas_file.c"
#include "botlib/be_aas_sample.c"
#include "botlib/be_aas_route.c"
#include "botlib/be_aas_routealt.c"
#define LINECOLOR_RED 1
#define LINECOLOR_BLUE 4
void AAS_DebugLine(vec3_t start, vec3_t end, int color) {}
void AAS_ClearShownDebugLines(void) {}
#include "botlib/be_aas_move.c"
#include "botlib/be_aas_bspq3.c"
int AAS_Loaded(void) { return aasworld.loaded; }

botlib_import_t botimport;
int bot_developer = 0;
botlib_globals_t botlibglobals;
int Sys_MilliSeconds(void) { return 0; }
aas_t aasworld;
static const char *datafolder;
static FILE *fo;

#include "botlib/be_ai_weight.c"
#include "botlib/be_ai_goal.c"
#include "botlib/be_ai_move.c"
#include "botlib/be_ai_gen.c"
#include "botlib/be_ea.c"

/* ---------------------------------------------------------------- output */

static void print_escaped(FILE *f, const char *s)
{
	for (; *s; s++)
	{
		unsigned char c = (unsigned char) *s;
		if (c < 32 || c > 126 || c == '\\') fprintf(f, "\\x%02X", c);
		else fputc(c, f);
	}
}

static void Stub_Print(int type, char *fmt, ...)
{
	char text[4096];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(text, sizeof(text), fmt, ap);
	va_end(ap);
	fprintf(fo, "P%d|", type);
	print_escaped(fo, text);
	fputc('\n', fo);
}

void QDECL Log_Write(char *fmt, ...)
{
	char text[4096];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(text, sizeof(text), fmt, ap);
	va_end(ap);
	fprintf(fo, "L|");
	print_escaped(fo, text);
	fputc('\n', fo);
}
void Log_Print(char *fmt, ...) { (void) fmt; }
FILE *Log_FilePointer(void) { return NULL; }
FILE *Log_FileStruct(void) { return NULL; }

static void Stub_Command(int client, char *command)
{
	fprintf(fo, "E|%d|", client);
	print_escaped(fo, command);
	fputc('\n', fo);
}

/* ---------------------------------------------------------------- q_shared */

int Com_sprintf(char *dest, int size, const char *fmt, ...)
{
	va_list ap;
	int len;
	va_start(ap, fmt);
	len = vsnprintf(dest, size, fmt, ap);
	va_end(ap);
	if (len >= size) len = size - 1;
	return len;
}
void Com_sprintf2(char *dest, int size, const char *fmt, ...) { (void) dest; (void) size; (void) fmt; }
void Com_Error(int level, const char *fmt, ...) { (void) level; fprintf(fo, "FATAL %s\n", fmt); exit(2); }
char *va(char *format, ...)
{
	static char string[2][32000];
	static int index = 0;
	char *buf;
	va_list ap;
	index ^= 1;
	buf = string[index];
	va_start(ap, format);
	vsnprintf(buf, sizeof(string[0]), format, ap);
	va_end(ap);
	return buf;
}
void Q_strncpyz(char *dest, const char *src, int destsize)
{
	strncpy(dest, src, destsize - 1);
	dest[destsize - 1] = 0;
}
#include "comcompress.inc"

/* ---------------------------------------------------------------- the AAS that is not compiled */

qboolean AAS_EntityCollision2(void) { return qfalse; }
unsigned short CRC_ProcessString(unsigned char *data, int length) { return 0; }
void AAS_DecompressVis(byte *in, int numareas, byte *decompressed) {}
int AAS_CompressVis(byte *vis, int numareas, byte *dest) { return 0; }
float AAS_AreaGroundFaceArea(int areanum) { return 0; }
float AAS_Time(void) { return aasworld.time; }
int AvailableMemory(void) { return 1 << 30; }
int AAS_Initialized(void) { return aasworld.initialized; }
int AAS_BestReachableFromJumpPadArea(vec3_t origin, vec3_t mins, vec3_t maxs) { return 0; }
int AAS_BestReachableArea(vec3_t origin, vec3_t mins, vec3_t maxs, vec3_t goalorigin)
{
	int areanum = AAS_PointAreaNum(origin);
	VectorCopy(origin, goalorigin);
	if (areanum && AAS_AreaReachability(areanum)) return areanum;
	return 0;
}

/* ---------------------------------------------------------------- file system: files of the data folder */

static FILE *handles[64];
static unsigned char *g_aasfile;
static int g_aassize, g_aaspos;
static char g_aasname[260];
static char g_checksum[32];

static int Stub_FOpenFile(const char *qpath, fileHandle_t *file, fsMode_t mode)
{
	char path[1024];
	int i, length;
	FILE *f;
	(void) mode;
	*file = 0;
	if (g_aasfile && strcmp(qpath, g_aasname) == 0) { *file = 63; g_aaspos = 0; return g_aassize; }
	snprintf(path, sizeof(path), "%s/%s", datafolder, qpath);
	for (i = 0; path[i]; i++) if (path[i] == '\\') path[i] = '/';
	f = fopen(path, "rb");
	if (!f) return 0;
	fseek(f, 0, SEEK_END);
	length = (int) ftell(f);
	fseek(f, 0, SEEK_SET);
	for (i = 1; i < 63; i++)
	{
		if (!handles[i]) { handles[i] = f; *file = i; break; }
	}
	return length;
}
static int Stub_Read(void *buffer, int len, fileHandle_t f)
{
	if (f == 63)
	{
		int n = g_aassize - g_aaspos;
		if (n > len) n = len;
		if (n < 0) n = 0;
		memcpy(buffer, g_aasfile + g_aaspos, n);
		g_aaspos += n;
		return n;
	}
	return (int) fread(buffer, 1, len, handles[f]);
}
static int Stub_Write(const void *buffer, int len, fileHandle_t f) { return 0; }
static void Stub_Close(fileHandle_t f) { if (f != 63) { fclose(handles[f]); handles[f] = NULL; } }
static int Stub_Seek(fileHandle_t f, long offset, int origin) { if (f == 63) g_aaspos = (int) offset; return 0; }

/* ---------------------------------------------------------------- the world twin */

#define MAXSOLIDS 16
#define MAXMODELS 32
#define MAXENTS 64
static struct { int ent; vec3_t mins, maxs; } solids[MAXSOLIDS];
static int numsolids;
#define MAXLIQUIDS 8
static struct { int contents; vec3_t mins, maxs; } liquids[MAXLIQUIDS];
static int numliquids;
static struct { vec3_t mins, maxs, origin; } models[MAXMODELS];
static aas_entityinfo_t ents[MAXENTS];
static char *entitydata = "";

static void Twin_Trace(bsp_trace_t *t, vec3_t start, vec3_t mins, vec3_t maxs, vec3_t end, int passent, int contentmask)
{
	aas_trace_t a = AAS_TraceClientBBox(start, end, PRESENCE_NORMAL, -1);
	int i, k;
	memset(t, 0, sizeof(*t));
	t->startsolid = a.startsolid;
	t->fraction = a.fraction;
	VectorCopy(a.endpos, t->endpos);
	t->ent = (a.fraction < 1 || a.startsolid) ? ENTITYNUM_WORLD : ENTITYNUM_NONE;
	for (i = 0; i < numsolids; i++)
	{
		vec3_t emin, emax;
		float tmin = 0, tmax = 1, d, t1, t2, tmp;
		int miss = 0, inside = 1;
		if (solids[i].ent == passent) continue;
		for (k = 0; k < 3; k++)
		{
			emin[k] = solids[i].mins[k] - (maxs ? maxs[k] : 0);
			emax[k] = solids[i].maxs[k] - (mins ? mins[k] : 0);
		}
		for (k = 0; k < 3; k++)
		{
			d = end[k] - start[k];
			if (start[k] < emin[k] || start[k] > emax[k]) inside = 0;
			if (d == 0)
			{
				if (start[k] < emin[k] || start[k] > emax[k]) { miss = 1; break; }
			}
			else
			{
				t1 = (emin[k] - start[k]) / d;
				t2 = (emax[k] - start[k]) / d;
				if (t1 > t2) { tmp = t1; t1 = t2; t2 = tmp; }
				if (t1 > tmin) tmin = t1;
				if (t2 < tmax) tmax = t2;
				if (tmin > tmax) { miss = 1; break; }
			}
		}
		if (miss) continue;
		if (inside)
		{
			t->startsolid = qtrue;
			t->allsolid = qfalse;
			t->fraction = 0;
			VectorCopy(start, t->endpos);
			t->ent = solids[i].ent;
			continue;
		}
		if (tmin < t->fraction)
		{
			t->fraction = tmin;
			for (k = 0; k < 3; k++) t->endpos[k] = start[k] + (end[k] - start[k]) * tmin;
			t->ent = solids[i].ent;
		}
	}
}
static void Twin_EntityTrace(bsp_trace_t *t, vec3_t start, vec3_t mins, vec3_t maxs, vec3_t end, int entnum, int contentmask)
{
	memset(t, 0, sizeof(*t));
	t->fraction = 1;
}
static int Twin_PointContents(vec3_t point)
{
	int areanum = AAS_PointAreaNum(point), contents = 0;
	if (areanum)
	{
		if (aasworld.areasettings[areanum].contents & AREACONTENTS_WATER) contents |= CONTENTS_WATER;
		if (aasworld.areasettings[areanum].contents & AREACONTENTS_LAVA) contents |= CONTENTS_LAVA;
		if (aasworld.areasettings[areanum].contents & AREACONTENTS_SLIME) contents |= CONTENTS_SLIME;
	}
	for (areanum = 0; areanum < numliquids; areanum++)
	{
		if (point[0] >= liquids[areanum].mins[0] && point[0] <= liquids[areanum].maxs[0] &&
			point[1] >= liquids[areanum].mins[1] && point[1] <= liquids[areanum].maxs[1] &&
			point[2] >= liquids[areanum].mins[2] && point[2] <= liquids[areanum].maxs[2]) contents |= liquids[areanum].contents;
	}
	return contents;
}
static int Twin_inPVS(vec3_t p1, vec3_t p2) { return qtrue; }
static char *Twin_BSPEntityData(void) { return entitydata; }
static void Twin_ModelMinsMaxsOrigin(int modelnum, vec3_t angles, vec3_t mins, vec3_t maxs, vec3_t origin)
{
	if (modelnum < 0 || modelnum >= MAXMODELS) { if (mins) VectorClear(mins); if (maxs) VectorClear(maxs); if (origin) VectorClear(origin); return; }
	if (mins) VectorCopy(models[modelnum].mins, mins);
	if (maxs) VectorCopy(models[modelnum].maxs, maxs);
	if (origin) VectorCopy(models[modelnum].origin, origin);
}

/* the entities of be_aas_entity.c (the table of the scenario) */
#define ET_MOVER 4
int AAS_EntityType(int entnum) { if (entnum < 0 || entnum >= MAXENTS) return 0; return ents[entnum].type; }
int AAS_EntityModelindex(int entnum) { if (entnum < 0 || entnum >= MAXENTS) return 0; return ents[entnum].modelindex; }
int AAS_EntityModelNum(int entnum) { if (entnum < 0 || entnum >= MAXENTS) return 0; return ents[entnum].modelindex; }
void AAS_EntityInfo(int entnum, aas_entityinfo_t *info)
{
	if (entnum < 0 || entnum >= MAXENTS) { memset(info, 0, sizeof(*info)); return; }
	*info = ents[entnum];
}
int AAS_NextEntity(int entnum)
{
	if (!aasworld.loaded) return 0;
	if (entnum < 0) entnum = -1;
	while (++entnum < MAXENTS) if (ents[entnum].valid) return entnum;
	return 0;
}
int AAS_OriginOfMoverWithModelNum(int modelnum, vec3_t origin)
{
	int i;
	for (i = 0; i < MAXENTS; i++)
		if (ents[i].type == ET_MOVER && ents[i].modelindex == modelnum) { VectorCopy(ents[i].origin, origin); return qtrue; }
	return qfalse;
}

/* ---------------------------------------------------------------- scenario */

static int unescape(char *s)
{
	char *r = s, *w = s;
	while (*r)
	{
		if (*r == '\\' && r[1])
		{
			r++;
			if (*r == 't') *w++ = '\t';
			else if (*r == 'n') *w++ = '\n';
			else if (*r == 'r') *w++ = '\r';
			else if (*r == '\\') *w++ = '\\';
			else if (*r == 'x' && r[1] && r[2])
			{
				char hex[3] = { r[1], r[2], 0 };
				*w++ = (char) strtol(hex, NULL, 16);
				r += 2;
			}
			else *w++ = *r;
			r++;
		}
		else *w++ = *r++;
	}
	*w = 0;
	return (int) (w - s);
}

#define MAXARGS 400
static char *args[MAXARGS];
static int numargs;

static char *arg(int i)
{
	if (i >= numargs) return "";
	return args[i];
}
static long num(int i) { return strtol(arg(i), NULL, 0); }
static float fnum(int i) { return (float) atof(arg(i)); }
static void vnum(int i, vec3_t v) { v[0] = fnum(i); v[1] = fnum(i + 1); v[2] = fnum(i + 2); }

static unsigned fb(float f) { unsigned u; memcpy(&u, &f, 4); return u; }
static void pv(const char *tag, const vec3_t v) { fprintf(fo, " %s #%08x #%08x #%08x", tag, fb(v[0]), fb(v[1]), fb(v[2])); }
static void pf(const char *tag, float f) { fprintf(fo, " %s #%08x", tag, fb(f)); }

static void print_goal(const char *tag, const bot_goal_t *g)
{
	fprintf(fo, "%s", tag);
	pv("O", g->origin);
	fprintf(fo, " A %d", g->areanum);
	pv("N", g->mins);
	pv("X", g->maxs);
	fprintf(fo, " E %d NUM %d F %d I %d\n", g->entitynum, g->number, g->flags, g->iteminfo);
}

static void print_input(const char *tag, const bot_input_t *bi)
{
	fprintf(fo, "%s", tag);
	pf("T", bi->thinktime);
	pv("D", bi->dir);
	pf("S", bi->speed);
	pv("V", bi->viewangles);
	fprintf(fo, " A %d W %d\n", bi->actionflags, bi->weapon);
}

static void print_result(const char *tag, const bot_moveresult_t *r)
{
	fprintf(fo, "%s F %d T %d B %d BE %d TT %d FL %d W %d", tag, r->failure, r->type, r->blocked, r->blockentity, r->traveltype, r->flags, r->weapon);
	pv("D", r->movedir);
	pv("V", r->ideal_viewangles);
	fprintf(fo, "\n");
}

static unsigned char *g_file;

static int load_aas(const char *name)
{
	char path[1024];
	FILE *f;
	aas_header_t header;
	int code;
	snprintf(path, sizeof(path), "%s/%s", datafolder, name);
	f = fopen(path, "rb");
	if (!f) { fprintf(fo, "FILE %s missing\n", name); return -1; }
	fseek(f, 0, SEEK_END); g_aassize = ftell(f); fseek(f, 0, SEEK_SET);
	if (g_aasfile) free(g_aasfile);
	g_aasfile = (unsigned char *) malloc(g_aassize + 1);
	fread(g_aasfile, 1, g_aassize, f);
	fclose(f);
	strcpy(g_aasname, "maps/bots.aas");
	memset(&aasworld, 0, sizeof(aasworld));
	memcpy(&header, g_aasfile, sizeof(header));
	if (header.version == AASVERSION) AAS_DData((unsigned char *) &header + 8, sizeof(aas_header_t) - 8);
	sprintf(g_checksum, "%d", header.bspchecksum);
	code = AAS_LoadAASFile(g_aasname);
	fprintf(fo, "LOAD %d\n", code);
	if (code != BLERR_NOERROR) return code;
	aasworld.loaded = qtrue;
	aasworld.initialized = qtrue;
	/* no entity is linked into the areas (the Delphi tracer has none either) */
	aasworld.arealinkedentities = (aas_link_t **) calloc(aasworld.numareas + 1, sizeof(aas_link_t *));
	AAS_InitSettings();
	routingcachesize = 0;
	AAS_InitRouting();

	fprintf(fo, "AAS %d %d %d %d\n", aasworld.numareas, aasworld.numclusters, aasworld.numportals, aasworld.reachabilitysize);
	return code;
}

float LibVarGetValueStub(char *n) { return LibVarGetValue(n); }

static void run_command(void);

int main(int argc, char **argv)
{
	FILE *f;
	char line[8192];
	fo = stdout;
	setvbuf(stdout, NULL, _IONBF, 0);
	if (argc < 3) { printf("usage: aigen <data folder> <scenario file>\n"); return 1; }
	datafolder = argv[1];
	botimport.Print = Stub_Print;
	botimport.FS_FOpenFile = Stub_FOpenFile;
	botimport.FS_Read = Stub_Read;
	botimport.FS_Write = Stub_Write;
	botimport.FS_FCloseFile = Stub_Close;
	botimport.FS_Seek = Stub_Seek;
	botimport.BotClientCommand = Stub_Command;
	botimport.Trace = Twin_Trace;
	botimport.EntityTrace = Twin_EntityTrace;
	botimport.PointContents = Twin_PointContents;
	botimport.inPVS = Twin_inPVS;
	botimport.BSPEntityData = Twin_BSPEntityData;
	botimport.BSPModelMinsMaxsOrigin = Twin_ModelMinsMaxsOrigin;
	f = fopen(argv[2], "rb");
	if (!f) { printf("cannot open %s\n", argv[2]); return 1; }
	while (fgets(line, sizeof(line), f))
	{
		char *p;
		int len = (int) strlen(line);
		while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r')) line[--len] = 0;
		if (!len || line[0] == '#') continue;
		fprintf(fo, ">%s\n", line);
		numargs = 0;
		for (p = line; ; )
		{
			args[numargs++] = p;
			p = strchr(p, '|');
			if (!p || numargs >= MAXARGS) break;
			*p++ = 0;
		}
		{ int i; for (i = 0; i < numargs; i++) unescape(args[i]); }
		run_command();
	}
	fclose(f);
	return 0;
}

#include "commands.inc"
