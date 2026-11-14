/*
 * Parity tool of the routing of Quake III Arena (issue #122): it links the REAL be_aas_file.c, be_aas_sample.c,
 * be_aas_route.c and be_aas_routealt.c of code/botlib (included below, read only, copied by build.sh) with the stubs
 * of the folders stub/ and ../stub/, loads each .aas file that is given on the command line, makes the routing
 * (AAS_InitRouting, AAS_InitAlternativeRouting) and runs a scenario of fixed seed on it. The twin of this file is
 * Tests/Source/DelphiDoom.Tests.Aas.Route.Scenario.pas: every line printed here is printed there with the same text.
 *
 *   routegen <memory limit> <file.aas> [<file.aas> ...]
 *
 * <memory limit>: the routing drops its caches while the memory that is "available" (limit - routingcachesize, as the
 * tool says) is under 1 MB: 0 means that the memory is never short.
 * Floats are printed as the 8 hexadecimal digits of their bits.
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

#include "vmath.inc"
#include "aaserror.inc"
#include "areareach.inc"
#include "projectpoint.inc"

/* the prototypes that the real headers (be_aas_main.h, be_aas_route.h, l_memory.h ...) give */
float AAS_Time(void);
int Sys_MilliSeconds(void);
int AAS_AreaTravelTimeToGoalArea(int areanum, vec3_t origin, int goalareanum, int travelflags);
void Com_sprintf(char *dest, int size, const char *fmt, ...);
int AvailableMemory(void);
float AAS_AreaGroundFaceArea(int areanum);
void AAS_DecompressVis(byte *in, int numareas, byte *decompressed);
int AAS_CompressVis(byte *vis, int numareas, byte *dest);
#define random() ((rand() & 0x7fff) / ((float)0x7fff))
int Sys_MilliSeconds(void) { return 0; }

#include "botlib/be_aas_file.c"
#include "botlib/be_aas_sample.c"
#include "botlib/be_aas_route.c"
#include "botlib/be_aas_routealt.c"

/* the movement (be_aas_move.c). The BSP of the game is replaced by a twin that Delphi has too: the contents of a point
   are those of its AAS area, and AAS_Trace is the trace of the box of a standing client through the AAS */
#include "anglevec.inc"
int AAS_PredictClientMovement(struct aas_clientmove_s *move, int entnum, vec3_t origin, int presencetype, int onground, vec3_t velocity, vec3_t cmdmove, int cmdframes, int maxframes, float frametime, int stopevent, int stopareanum, int visualize);
#define LINECOLOR_RED 1
#define LINECOLOR_BLUE 4
void AAS_DebugLine(vec3_t start, vec3_t end, int color) {}
void AAS_ClearShownDebugLines(void) {}
int AAS_PointContents(vec3_t point)
{
	int areanum = AAS_PointAreaNum(point), contents = 0;
	if (areanum)
	{
		if (aasworld.areasettings[areanum].contents & AREACONTENTS_WATER) contents |= CONTENTS_WATER;
		if (aasworld.areasettings[areanum].contents & AREACONTENTS_LAVA) contents |= CONTENTS_LAVA;
		if (aasworld.areasettings[areanum].contents & AREACONTENTS_SLIME) contents |= CONTENTS_SLIME;
	}
	return contents;
}
bsp_trace_t AAS_Trace(vec3_t start, vec3_t mins, vec3_t maxs, vec3_t end, int passent, int contentmask)
{
	bsp_trace_t result;
	aas_trace_t trace = AAS_TraceClientBBox(start, end, PRESENCE_NORMAL, -1);
	memset(&result, 0, sizeof(result));
	result.startsolid = trace.startsolid;
	result.fraction = trace.fraction;
	VectorCopy(trace.endpos, result.endpos);
	return result;
}
#include "botlib/be_aas_move.c"

botlib_import_t botimport;
int bot_developer = 1;
aas_t aasworld;
static int g_memory_limit;

/* ------------------------------------------------------------ stubs */

static void print_escaped(const char *s)
{
	for (; *s; s++)
	{
		unsigned char c = (unsigned char) *s;
		if (c < 32 || c > 126 || c == '\\') printf("\\x%02X", c);
		else putchar(c);
	}
}

static void Stub_Print(int type, char *fmt, ...)
{
	char text[4096];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(text, sizeof(text), fmt, ap);
	va_end(ap);
	printf("P%d|", type);
	print_escaped(text);
	putchar('\n');
}

static unsigned char *g_file;
static int g_size, g_pos;
static char g_name[260];
static char g_checksum[32];

static int Stub_FOpenFile(const char *qpath, fileHandle_t *file, fsMode_t mode)
{
	if (mode != FS_READ || strcmp(qpath, g_name) != 0) { *file = 0; return -1; }
	*file = 1;
	g_pos = 0;
	return g_size;
}
static int Stub_Read(void *buffer, int len, fileHandle_t f)
{
	int n = g_size - g_pos;
	if (n > len) n = len;
	if (n < 0) n = 0;
	memcpy(buffer, g_file + g_pos, n);
	g_pos += n;
	return n;
}
static int Stub_Write(const void *buffer, int len, fileHandle_t f) { return 0; }
static void Stub_Close(fileHandle_t f) {}
static int Stub_Seek(fileHandle_t f, long offset, int origin) { g_pos = (int) offset; return 0; }

float LibVarValue(char *var_name, char *value) { return (float) atof(value); }
char *LibVarGetString(char *var_name) { return g_checksum; }
qboolean AAS_EntityCollision(int entnum, vec3_t start, vec3_t boxmins, vec3_t boxmaxs, vec3_t end,
								int contentmask, bsp_trace_t *trace) { return qfalse; }
void QDECL Log_Write(char *fmt, ...) {}
unsigned short CRC_ProcessString(unsigned char *data, int length) { return 0; }
void AAS_DecompressVis(byte *in, int numareas, byte *decompressed) {}
int AAS_CompressVis(byte *vis, int numareas, byte *dest) { return 0; }
float AAS_AreaGroundFaceArea(int areanum) { return 0; }
float AAS_Time(void) { return aasworld.time; }
/* the memory that is left: the limit minus what the routing cache holds (0: never short) */
int AvailableMemory(void) { return g_memory_limit ? g_memory_limit - routingcachesize : 1 << 30; }
void Com_sprintf(char *dest, int size, const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(dest, size, fmt, ap);
	va_end(ap);
}

static unsigned fb(float f) { unsigned u; memcpy(&u, &f, 4); return u; }
static void pv(const char *tag, const vec3_t v) { printf(" %s #%08x #%08x #%08x", tag, fb(v[0]), fb(v[1]), fb(v[2])); }

static unsigned g_seed;
static unsigned rnd(void) { g_seed ^= g_seed << 13; g_seed ^= g_seed >> 17; g_seed ^= g_seed << 5; return g_seed; }
/* the areas that have reachabilities: the others are no start or goal of a route */
static int *g_reach, g_numreach;
static int pick(void) { return g_reach[rnd() % g_numreach]; }

static const int FLAGS[3] = {
	TFL_DEFAULT,
	TFL_WALK | TFL_CROUCH | TFL_AIR | TFL_WATER,
	(TFL_DEFAULT) & ~(TFL_WALKOFFLEDGE | TFL_JUMP | TFL_JUMPPAD)  /* TFL_DEFAULT has no parentheses in be_aas.h: the parentheses are needed here */
};

static void counts(const char *tag)
{
	int na = 0, np = 0;
	aas_routingcache_t *c;
	for (c = aasworld.oldestcache; c; c = c->time_next) { if (c->type == CACHETYPE_AREA) na++; else np++; }
	printf("%s %d %d %d %d %d\n", tag, na, np, routingcachesize, numareacacheupdates, numportalcacheupdates);
}

static void routes(const char *tag, int count, int variant)
{
	int k, n = aasworld.numareas, a, b, v, tt, rn, ok;
	for (k = 0; k < count; k++)
	{
		a = pick();
		b = pick();
		v = (variant >= 0) ? variant : k % 3;
		tt = -7; rn = -1;
		ok = AAS_AreaRouteToGoalArea(a, aasworld.areas[a].center, b, FLAGS[v], &tt, &rn);
		printf("%s %d %d %d %d %d %d %d\n", tag, k, a, b, v, ok, tt, rn);
		tt = -7; rn = -1;
		ok = AAS_AreaRouteToGoalArea(a, NULL, b, FLAGS[v], &tt, &rn);
		printf("%sN %d %d %d %d %d %d %d\n", tag, k, a, b, v, ok, tt, rn);
	}
}

static void predict(int count)
{
	int k, n = aasworld.numareas, a, b, v, ok, events[5] = { RSE_NONE, RSE_USETRAVELTYPE, RSE_ENTERCONTENTS, RSE_ENTERAREA, RSE_USETRAVELTYPE | RSE_ENTERCONTENTS | RSE_ENTERAREA };
	for (k = 0; k < count; k++)
	{
		aas_predictroute_t route;
		a = pick();
		b = pick();
		v = k % 3;
		memset(&route, 0, sizeof(route));
		ok = AAS_PredictRoute(&route, a, aasworld.areas[a].center, b, FLAGS[v], (k % 4) * 5, (k % 3) * 400,
			events[k % 5], AREACONTENTS_WATER | AREACONTENTS_JUMPPAD | AREACONTENTS_TELEPORTER,
			TFL_JUMP | TFL_TELEPORT | TFL_JUMPPAD | TFL_WATER | TFL_ELEVATOR, pick());
		printf("PR %d %d %d %d %d", k, a, b, v, ok);
		pv("P", route.endpos);
		printf(" %d %d %d %d %d\n", route.endarea, route.stopevent, route.endcontents, route.endtravelflags, route.time);
	}
}

static void alternatives(int count)
{
	int k, n = aasworld.numareas, a, b, i, num, types[3] = { ALTROUTEGOAL_ALL, ALTROUTEGOAL_CLUSTERPORTALS, ALTROUTEGOAL_CLUSTERPORTALS | ALTROUTEGOAL_VIEWPORTALS };
	for (k = 0; k < count; k++)
	{
		aas_altroutegoal_t goals[8];
		a = pick();
		b = pick();
		memset(goals, 0, sizeof(goals));
		num = AAS_AlternativeRouteGoals(aasworld.areas[a].center, a, aasworld.areas[b].center, b, TFL_DEFAULT, goals, 8, types[k % 3]);
		printf("AL %d %d %d %d", k, a, b, num);
		for (i = 0; i < num; i++)
		{
			pv("G", goals[i].origin);
			printf(" %d %d %d %d", goals[i].areanum, goals[i].starttraveltime, goals[i].goaltraveltime, goals[i].extratraveltime);
		}
		printf("\n");
	}
}

static void hides(int count) __attribute__((unused));
static void hides(int count)
{
	int k, n = aasworld.numareas, a, e, r;
	for (k = 0; k < count; k++)
	{
		a = pick();
		e = pick();
		r = AAS_NearestHideArea(0, aasworld.areas[a].center, a, 1, aasworld.areas[e].center, e, FLAGS[k % 3]);
		printf("HD %d %d %d %d\n", k, a, e, r);
	}
}

static void enables(void)
{
	int k, n = aasworld.numareas, a, r;
	for (k = 0; k < 4; k++)
	{
		a = pick();
		r = AAS_EnableRoutingArea(a, -1);
		printf("EN %d %d read %d", k, a, r);
		r = AAS_EnableRoutingArea(a, 0);
		printf(" off %d", r);
		printf(" flags %d\n", aasworld.areasettings[a].areaflags);
		routes("RD", 20, 0);
		counts("CD");
		r = AAS_EnableRoutingArea(a, 1);
		printf("EN %d %d on %d flags %d\n", k, a, r, aasworld.areasettings[a].areaflags);
		routes("RE", 10, 0);
	}
	printf("EN0 %d\n", AAS_EnableRoutingArea(0, 1));
	printf("ENN %d\n", AAS_EnableRoutingArea(n, -1));
}

static void reaches(void)
{
	int k, n = aasworld.numareas, a, r, steps;
	for (k = 0; k < 8; k++)
	{
		a = pick();
		printf("NR %d %d %d", k, a, aasworld.areasettings[a].numreachableareas);
		r = 0; steps = 0;
		while (steps < 40)
		{
			r = AAS_NextAreaReachability(a, r);
			printf(" %d", r);
			if (!r) break;
			steps++;
		}
		printf("\n");
	}
	printf("NR0 %d\n", AAS_NextAreaReachability(0, 0));
	for (k = 0; k < 4; k++)
	{
		aas_reachability_t reach;
		r = aasworld.reachabilitysize ? rnd() % aasworld.reachabilitysize : 0;
		AAS_ReachabilityFromNum(r, &reach);
		printf("RF %d %d %d %d %d", k, r, reach.areanum, reach.facenum, reach.edgenum);
		pv("S", reach.start); pv("E", reach.end);
		printf(" %d %d\n", reach.traveltype, reach.traveltime);
	}
	{
		aas_reachability_t reach;
		AAS_ReachabilityFromNum(-1, &reach);
		printf("RFN %d %d\n", reach.areanum, reach.traveltype);
		AAS_ReachabilityFromNum(aasworld.reachabilitysize, &reach);
		printf("RFM %d %d\n", reach.areanum, reach.traveltype);
	}
	for (k = 0; k < 6; k++)
	{
		int next = 0, guard = 0;
		printf("NM %d", k);
		while ((next = AAS_NextModelReachability(next, k)) != 0 && guard < 40) { printf(" %d", next); guard++; }
		printf("\n");
	}
}

static void run_file(const char *path)
{
	FILE *f = fopen(path, "rb");
	aas_header_t header;
	int code, i, n;
	if (!f) { printf("FILE %s missing\n", path); return; }
	fseek(f, 0, SEEK_END); g_size = ftell(f); fseek(f, 0, SEEK_SET);
	g_file = (unsigned char *) malloc(g_size + 1);
	fread(g_file, 1, g_size, f);
	fclose(f);
	strcpy(g_name, "maps/routing.aas");
	memset(&aasworld, 0, sizeof(aasworld));
	/* the checksum of the file: the header after the first 8 bytes is encrypted from version 5 on */
	memcpy(&header, g_file, sizeof(header));
	if (header.version == AASVERSION) AAS_DData((unsigned char *) &header + 8, sizeof(aas_header_t) - 8);
	sprintf(g_checksum, "%d", header.bspchecksum);
	routingcachesize = 0;
	{ const char *s = path, *p; for (p = path; *p; p++) if (*p == '/' || *p == '\\') s = p + 1; printf("FILE %s\n", s); }
	code = AAS_LoadAASFile(g_name);
	printf("LOAD %d\n", code);
	if (code != BLERR_NOERROR) { free(g_file); return; }
	aasworld.loaded = qtrue;
	aasworld.initialized = qtrue;
	AAS_InitRouting();
	AAS_InitAlternativeRouting();
	n = aasworld.numareas;
	printf("AAS %d %d %d %d\n", n, aasworld.numclusters, aasworld.numportals, aasworld.reachabilitysize);
	if (n < 3) { free(g_file); return; }
	for (i = 0; i < aasworld.numportals; i++) printf("PM %d %d\n", i, aasworld.portalmaxtraveltimes[i]);
	for (i = 0; i < aasworld.reachabilitysize && i < 4000; i++)
		printf("RA %d %d %d\n", i, aasworld.reachabilityareas[i].firstarea, aasworld.reachabilityareas[i].numareas);
	{
		/* a hash of the travel times through the areas: every row of every area */
		unsigned h = 2166136261u; int l, m;
		for (i = 0; i < n; i++)
			for (l = 0; l < aasworld.areasettings[i].numreachableareas; l++)
				for (m = 0; m < aasworld.reversedreachability[i].numlinks; m++)
				{ h ^= aasworld.areatraveltimes[i][l][m]; h *= 16777619u; }
		printf("ATT %u\n", h);
	}
	for (i = 0; i < MAX_TRAVELTYPES; i++) printf("TF %d %d\n", i, AAS_TravelFlagForType(i));
	printf("TF -1 %d\n", AAS_TravelFlagForType(-1));
	printf("TF 99 %d\n", AAS_TravelFlagForType(99));
	g_reach = (int *) malloc(n * sizeof(int)); g_numreach = 0;
	for (i = 1; i < n; i++) if (aasworld.areasettings[i].numreachableareas) g_reach[g_numreach++] = i;
	printf("PK %d\n", g_numreach);
	if (g_numreach < 2) { free(g_file); return; }
	g_seed = 2463534242u;
	counts("C0");
	routes("RT", 300, -1);
	counts("C1");
	predict(60);
	alternatives(12);
	/* hides(12): AAS_NearestHideArea indexes aasworld.areaupdate (made for maxreachabilityareas entries) by the area number: a heap overflow in the original, that is not run here */
	enables();
	counts("C2");
	reaches();
	counts("C3");
	AAS_FreeRoutingCaches();
	free(g_file);
}

/* ------------------------------------------------------------ the movement scenario (routegen move <files>) */

static float rf(int range) { return ((int) (rnd() % (2 * range * 8 + 1)) - range * 8) / 8.0f; }

static void ptrace(const char *tag, const aas_trace_t *t)
{
	printf("%s %d #%08x", tag, (int) t->startsolid, fb(t->fraction));
	pv("E", t->endpos);
	printf(" %d %d %d %d\n", t->ent, t->lastarea, t->area, t->planenum);
}

static void pmove(const char *tag, const aas_clientmove_t *m)
{
	printf("%s", tag);
	pv("P", m->endpos); pv("V", m->velocity);
	printf(" %d %d %d %d #%08x %d", m->endarea, m->presencetype, m->stopevent, m->endcontents, fb(m->time), m->frames);
	printf(" TR %d #%08x", (int) m->trace.startsolid, fb(m->trace.fraction));
	pv("TE", m->trace.endpos);
	printf(" %d %d %d %d\n", m->trace.ent, m->trace.lastarea, m->trace.area, m->trace.planenum);
}

static void run_move(const char *path)
{
	FILE *f = fopen(path, "rb");
	aas_header_t header;
	int code, k, n, a, i;
	if (!f) { printf("FILE %s missing\n", path); return; }
	fseek(f, 0, SEEK_END); g_size = ftell(f); fseek(f, 0, SEEK_SET);
	g_file = (unsigned char *) malloc(g_size + 1);
	fread(g_file, 1, g_size, f);
	fclose(f);
	strcpy(g_name, "maps/routing.aas");
	memset(&aasworld, 0, sizeof(aasworld));
	memcpy(&header, g_file, sizeof(header));
	if (header.version == AASVERSION) AAS_DData((unsigned char *) &header + 8, sizeof(aas_header_t) - 8);
	sprintf(g_checksum, "%d", header.bspchecksum);
	{ const char *s = path, *p; for (p = path; *p; p++) if (*p == '/' || *p == '\\') s = p + 1; printf("FILE %s\n", s); }
	code = AAS_LoadAASFile(g_name);
	printf("LOAD %d\n", code);
	if (code != BLERR_NOERROR) { free(g_file); return; }
	aasworld.loaded = qtrue;
	AAS_InitSettings();
	n = aasworld.numareas;
	printf("AAS %d\n", n);
	if (n < 3) { free(g_file); return; }
	g_seed = 2463534242u;
	/* the functions of the physics that need no world */
	for (k = 0; k < 40; k++)
	{
		vec3_t v, w, u;
		float ws, ac, ft, fr, ss = 100, zv;
		v[0] = rf(40); v[1] = rf(40); v[2] = rf(40);
		w[0] = rf(2); w[1] = rf(2); w[2] = rf(2);
		VectorNormalize(w);
		ws = (float) (rnd() % 64) * 8;
		ac = (float) (rnd() % 20) + 1;
		ft = 0.05f * (1 + rnd() % 4);
		AAS_Accelerate(v, ft, w, ws, ac);
		printf("AC %d", k); pv("V", v); printf("\n");
		fr = (float) (rnd() % 10 + 1);
		u[0] = rf(40); u[1] = rf(40); u[2] = rf(40);
		AAS_ApplyFriction(u, fr, ss, ft);
		printf("FR %d", k); pv("V", u); printf("\n");
	}
	for (k = 0; k < 40; k++)
	{
		vec3_t s, e;
		float zv, vel = -1;
		zv = 270 + rf(40);
		s[0] = rf(100); s[1] = rf(100); s[2] = rf(100);
		e[0] = rf(100); e[1] = rf(100); e[2] = rf(100);
		a = AAS_HorizontalVelocityForJump(zv, s, e, &vel);
		printf("HV %d %d #%08x\n", k, a, fb(vel));
	}
	for (k = 0; k < 40; k++)
	{
		vec3_t s, e, mins, maxs;
		aas_trace_t t;
		int pres;
		memset(&t, 0, sizeof(t));
		s[0] = rf(100); s[1] = rf(100); s[2] = rf(100);
		e[0] = rf(100); e[1] = rf(100); e[2] = rf(100);
		mins[0] = rf(60); mins[1] = rf(60); mins[2] = rf(60);
		maxs[0] = mins[0] + (float) (rnd() % 64 + 1); maxs[1] = mins[1] + (float) (rnd() % 64 + 1); maxs[2] = mins[2] + (float) (rnd() % 64 + 1);
		pres = (rnd() & 1) ? PRESENCE_NORMAL : PRESENCE_CROUCH;
		a = AAS_ClipToBBox(&t, s, e, pres, mins, maxs);
		printf("CB %d %d", k, a);
		ptrace(" T", &t);
	}
	for (k = 0; k < 8; k++)
	{
		vec3_t ang, dir;
		if (k == 0) { ang[0] = 0; ang[1] = -1; ang[2] = 0; }
		else if (k == 1) { ang[0] = 0; ang[1] = -2; ang[2] = 0; }
		else { ang[0] = rf(180); ang[1] = rf(180); ang[2] = rf(180); }
		AAS_SetMovedir(ang, dir);
		printf("MD %d", k); pv("D", dir); printf("\n");
	}
	/* the functions that look at the world */
	for (k = 0; k < 40; k++)
	{
		vec3_t org;
		a = 1 + rnd() % (n - 1);
		VectorCopy(aasworld.areas[a].center, org);
		printf("WO %d %d %d %d %d\n", k, a, AAS_Swimming(org), AAS_OnGround(org, PRESENCE_NORMAL, -1), AAS_AgainstLadder(org));
	}
	for (k = 0; k < 10; k++)
	{
		vec3_t org, mins, maxs;
		a = 1 + rnd() % (n - 1);
		VectorCopy(aasworld.areas[a].center, org);
		mins[0] = -15; mins[1] = -15; mins[2] = -24; maxs[0] = 15; maxs[1] = 15; maxs[2] = 32;
		i = AAS_DropToFloor(org, mins, maxs);
		printf("DF %d %d %d", k, a, i); pv("O", org);
		printf(" #%08x #%08x\n", fb(AAS_RocketJumpZVelocity(org)), fb(AAS_BFGJumpZVelocity(org)));
	}
	for (k = 0; k < 10; k++)
	{
		aas_reachability_t reach;
		vec3_t rs;
		i = aasworld.reachabilitysize ? rnd() % aasworld.reachabilitysize : 0;
		reach = aasworld.reachability[i];
		AAS_JumpReachRunStart(&reach, rs);
		printf("JR %d %d", k, i); pv("R", rs); printf("\n");
	}
	{
		static const int EVENTS[8] = { SE_NONE, SE_HITGROUND, SE_LEAVEGROUND | SE_GAP, SE_ENTERWATER | SE_ENTERSLIME | SE_ENTERLAVA,
			SE_HITGROUNDDAMAGE, SE_ENTERAREA | SE_TOUCHJUMPPAD | SE_TOUCHTELEPORTER | SE_TOUCHCLUSTERPORTAL, SE_HITGROUNDAREA, SE_HITGROUND | SE_HITGROUNDDAMAGE | SE_LEAVEGROUND };
		static const float CMDZ[4] = { 0, 224, -400, 10 };
		for (k = 0; k < 120; k++)
		{
			aas_clientmove_t move;
			vec3_t org, vel, cmd;
			int pres, onground, cmdframes, maxframes, stopevent, stoparea;
			float ft;
			a = 1 + rnd() % (n - 1);
			VectorCopy(aasworld.areas[a].center, org);
			vel[0] = rf(40); vel[1] = rf(40); vel[2] = rf(20);
			cmd[0] = rf(50); cmd[1] = rf(50); cmd[2] = CMDZ[rnd() % 4];
			cmdframes = rnd() % 6;
			maxframes = 5 + rnd() % 20;
			ft = (k % 3 == 0) ? 0.0f : ((k % 3 == 1) ? 0.1f : 0.05f);
			stopevent = EVENTS[rnd() % 8];
			stoparea = 1 + rnd() % (n - 1);
			onground = rnd() & 1;
			pres = (rnd() & 1) ? PRESENCE_NORMAL : PRESENCE_CROUCH;
			printf("PI %d", k); pv("O", org); pv("V", vel); pv("C", cmd); printf(" %d %d %d %d #%08x %d\n", cmdframes, maxframes, pres, onground, fb(ft), stoparea);
			code = AAS_PredictClientMovement(&move, -1, org, pres, onground, vel, cmd, cmdframes, maxframes, ft, stopevent, stoparea, qfalse);
			printf("PM %d %d %d %d", k, a, code, stopevent);
			pmove(" M", &move);
		}
		for (k = 0; k < 12; k++)
		{
			aas_clientmove_t move;
			vec3_t org, vel, cmd, mins, maxs, c;
			int b;
			a = 1 + rnd() % (n - 1);
			b = 1 + rnd() % (n - 1);
			VectorCopy(aasworld.areas[a].center, org);
			VectorCopy(aasworld.areas[b].center, c);
			mins[0] = c[0] - 20; mins[1] = c[1] - 20; mins[2] = c[2] - 20;
			maxs[0] = c[0] + 20; maxs[1] = c[1] + 20; maxs[2] = c[2] + 20;
			vel[0] = rf(40); vel[1] = rf(40); vel[2] = 0;
			cmd[0] = rf(50); cmd[1] = rf(50); cmd[2] = 0;
			code = AAS_ClientMovementHitBBox(&move, -1, org, PRESENCE_NORMAL, qtrue, vel, cmd, 20, 30, 0.1f, mins, maxs, qfalse);
			printf("HB %d %d %d %d", k, a, b, code);
			pmove(" M", &move);
		}
	}
	for (k = 0; k < 150; k++)
	{
		vec3_t s, e;
		aas_trace_t t;
		int pres;
		a = 1 + rnd() % (n - 1);
		VectorCopy(aasworld.areas[a].center, s);
		s[0] = s[0] + rf(8); s[1] = s[1] + rf(8); s[2] = s[2] + rf(8);
		e[0] = s[0] + rf(100); e[1] = s[1] + rf(100); e[2] = s[2] + rf(100);
		pres = (rnd() & 1) ? PRESENCE_NORMAL : PRESENCE_CROUCH;
		t = AAS_TraceClientBBox(s, e, pres, -1);
		printf("TB %d %d %d", k, a, pres);
		ptrace(" T", &t);
	}
	free(g_file);
}
int main(int argc, char **argv)
{
	int i;
	botimport.Print = Stub_Print;
	botimport.FS_FOpenFile = Stub_FOpenFile;
	botimport.FS_Read = Stub_Read;
	botimport.FS_Write = Stub_Write;
	botimport.FS_FCloseFile = Stub_Close;
	botimport.FS_Seek = Stub_Seek;
	if (argc >= 3 && strcmp(argv[1], "move") == 0) { for (i = 2; i < argc; i++) run_move(argv[i]); return 0; }
	if (argc < 3) { printf("usage: routegen <memory limit> <file.aas> ... | routegen move <file.aas> ...\n"); return 1; }
	g_memory_limit = atoi(argv[1]);
	for (i = 2; i < argc; i++) run_file(argv[i]);
	return 0;
}
