/*
 * Parity tool of the reachabilities of Quake III Arena (issue #122): it links the REAL be_aas_file.c, be_aas_sample.c,
 * be_aas_move.c and be_aas_reach.c of code/botlib (included below, read only, copied by build.sh) with the stubs of the folders
 * stub/ and ../stub/, loads an .aas file, throws away the reachabilities of the file and calculates them again with the
 * real AAS_InitReachability and AAS_ContinueInitReachability. The twin of this file is
 * Tests/Source/DelphiDoom.Tests.Aas.Reach.Scenario.pas: every line printed here is printed there with the same text.
 *
 *   reachgen <full|digest> <grapple 0|1> <file.aas> <file.bsp> [<file.aas> <file.bsp> ...]
 *
 * The BSP of the game is replaced by twins that Delphi has too (declared in the header of the Delphi twin): the contents of
 * a point are those of its AAS area, AAS_Trace is the trace of the box of a standing client through the AAS (the surface
 * flags are 0), the entities and the bounds of the models come from the .bsp file (lumps 0 and 7, the bounds are spread by
 * one unit as cm_load.c does) and the entity functions of be_aas_bspq3.c are a small twin of the parser. What this proves is
 * the LOGIC of be_aas_reach.c: the reachabilities that come out are not those of the file of the game (the trace is not the
 * BSP) and that is expected.
 * Floats are printed as the 8 hexadecimal digits of their bits. "digest" prints a hash of the reachabilities of each area
 * (and the lines of the first area of each travel type), "full" every reachability.
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
#include "projectpoint.inc"

#define MAX_EPAIRKEY 128
#define SURF_SKY 0x4
#define VectorSet(v, x, y, z)	((v)[0]=(x), (v)[1]=(y), (v)[2]=(z))
#define LINECOLOR_RED 1
#define LINECOLOR_BLUE 4

float AAS_Time(void);
int Sys_MilliSeconds(void);
float LibVarValue(char *var_name, char *value);
float LibVarGetValue(char *var_name);
void Com_sprintf(char *dest, int size, const char *fmt, ...);
int AvailableMemory(void);
#define random() ((rand() & 0x7fff) / ((float)0x7fff))
int Sys_MilliSeconds(void) { return 0; }

int AAS_NextBSPEntity(int ent);
int AAS_ValueForBSPEpairKey(int ent, char *key, char *value, int size);
int AAS_VectorForBSPEpairKey(int ent, char *key, vec3_t v);
int AAS_FloatForBSPEpairKey(int ent, char *key, float *value);
int AAS_IntForBSPEpairKey(int ent, char *key, int *value);
void AAS_BSPModelMinsMaxsOrigin(int modelnum, vec3_t angles, vec3_t mins, vec3_t maxs, vec3_t origin);
void AAS_PermanentLine(vec3_t start, vec3_t end, int color);
int AAS_PointContents(vec3_t point);
bsp_trace_t AAS_Trace(vec3_t start, vec3_t mins, vec3_t maxs, vec3_t end, int passent, int contentmask);
float AAS_AreaGroundFaceArea(int areanum);
int AAS_AreaReachability(int areanum);
int AAS_AreaGrounded(int areanum);
int AAS_AreaSwim(int areanum);
int AAS_AreaJumpPad(int areanum);
int AAS_AreaClusterPortal(int areanum);
int AAS_AreaTeleporter(int areanum);
int AAS_AreaCrouch(int areanum);
int AAS_AreaLadder(int areanum);
int AAS_ReachabilityExists(int area1num, int area2num);
int AAS_BestReachableArea(vec3_t origin, vec3_t mins, vec3_t maxs, vec3_t goalorigin);
float AAS_FallDelta(float distance);
float AAS_MaxJumpHeight(float phys_jumpvel);
float AAS_MaxJumpDistance(float phys_jumpvel);
int AAS_FallDamageDistance(void);
float AAS_FaceArea(aas_face_t *face);

#include "botlib/be_aas_file.c"
#include "botlib/be_aas_sample.c"

#include "anglevec.inc"
int AAS_PredictClientMovement(struct aas_clientmove_s *move, int entnum, vec3_t origin, int presencetype, int onground, vec3_t velocity, vec3_t cmdmove, int cmdframes, int maxframes, float frametime, int stopevent, int stopareanum, int visualize);
void AAS_DebugLine(vec3_t start, vec3_t end, int color) {}
void AAS_ClearShownDebugLines(void) {}
void AAS_PermanentLine(vec3_t start, vec3_t end, int color) {}
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
#include "botlib/be_aas_reach.c"

botlib_import_t botimport;
int bot_developer = 1;
aas_t aasworld;
static int g_grapple;

/* ------------------------------------------------------------ stubs */

static unsigned g_pct_count, g_pct_hash = 2166136261u;
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
	if (text[0] == '\r')
	{
		/* the percentage lines: about one per area, only counted and hashed */
		const char *p;
		g_pct_count++;
		for (p = text; *p; p++) { g_pct_hash ^= (unsigned char) *p; g_pct_hash *= 16777619u; }
		return;
	}
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
float LibVarGetValue(char *var_name)
{
	if (!strcmp(var_name, "grapplereach")) return (float) g_grapple;
	return 0;
}
char *LibVarGetString(char *var_name) { return g_checksum; }
qboolean AAS_EntityCollision(int entnum, vec3_t start, vec3_t boxmins, vec3_t boxmaxs, vec3_t end,
								int contentmask, bsp_trace_t *trace) { return qfalse; }
void QDECL Log_Write(char *fmt, ...) {}
unsigned short CRC_ProcessString(unsigned char *data, int length) { return 0; }
float AAS_Time(void) { return aasworld.time; }
int AvailableMemory(void) { return 1 << 30; }
void Com_sprintf(char *dest, int size, const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(dest, size, fmt, ap);
	va_end(ap);
}

/* ------------------------------------------------------------ the BSP twins */

#define MAX_ENTITIES 4096
#define MAX_PAIRS 48
typedef struct { char key[MAX_EPAIRKEY]; char value[256]; } epair_t;
typedef struct { int numpairs; epair_t pairs[MAX_PAIRS]; } bspent_t;
static bspent_t *g_ents;
static int g_numents;                   /* entities + 1: the entity 0 does not exist */
static float g_modelmins[1024][3], g_modelmaxs[1024][3];
static int g_nummodels;

static void parse_entities(const char *text, int length)
{
	int i = 0;
	g_numents = 1;
	while (i < length)
	{
		if (text[i] != '{') { i++; continue; }
		i++;
		if (g_numents >= MAX_ENTITIES) break;
		g_ents[g_numents].numpairs = 0;
		while (i < length && text[i] != '}')
		{
			if (text[i] == '"')
			{
				char *k = g_ents[g_numents].pairs[g_ents[g_numents].numpairs].key;
				char *v = g_ents[g_numents].pairs[g_ents[g_numents].numpairs].value;
				int n = 0;
				i++;
				while (i < length && text[i] != '"') { if (n < MAX_EPAIRKEY - 1) k[n++] = text[i]; i++; }
				k[n] = 0; i++;
				while (i < length && text[i] != '"') i++;
				i++; n = 0;
				while (i < length && text[i] != '"') { if (n < 255) v[n++] = text[i]; i++; }
				v[n] = 0; i++;
				if (g_ents[g_numents].numpairs < MAX_PAIRS - 1) g_ents[g_numents].numpairs++;
			}
			else i++;
		}
		i++;
		g_numents++;
	}
}

int AAS_NextBSPEntity(int ent)
{
	ent++;
	if (ent >= 1 && ent < g_numents) return ent;
	return 0;
}
int AAS_ValueForBSPEpairKey(int ent, char *key, char *value, int size)
{
	int i;
	value[0] = '\0';
	if (ent <= 0 || ent >= g_numents) return qfalse;
	/* the real parser puts each pair at the head of the list: a key given twice answers with the second value */
	for (i = g_ents[ent].numpairs - 1; i >= 0; i--)
	{
		if (!strcmp(g_ents[ent].pairs[i].key, key))
		{
			strncpy(value, g_ents[ent].pairs[i].value, size - 1);
			value[size - 1] = '\0';
			return qtrue;
		}
	}
	return qfalse;
}
int AAS_VectorForBSPEpairKey(int ent, char *key, vec3_t v)
{
	char buf[MAX_EPAIRKEY];
	double v1, v2, v3;
	VectorClear(v);
	if (!AAS_ValueForBSPEpairKey(ent, key, buf, MAX_EPAIRKEY)) return qfalse;
	v1 = v2 = v3 = 0;
	sscanf(buf, "%lf %lf %lf", &v1, &v2, &v3);
	v[0] = v1; v[1] = v2; v[2] = v3;
	return qtrue;
}
int AAS_FloatForBSPEpairKey(int ent, char *key, float *value)
{
	char buf[MAX_EPAIRKEY];
	*value = 0;
	if (!AAS_ValueForBSPEpairKey(ent, key, buf, MAX_EPAIRKEY)) return qfalse;
	*value = atof(buf);
	return qtrue;
}
int AAS_IntForBSPEpairKey(int ent, char *key, int *value)
{
	char buf[MAX_EPAIRKEY];
	*value = 0;
	if (!AAS_ValueForBSPEpairKey(ent, key, buf, MAX_EPAIRKEY)) return qfalse;
	*value = atoi(buf);
	return qtrue;
}
void AAS_BSPModelMinsMaxsOrigin(int modelnum, vec3_t angles, vec3_t mins, vec3_t maxs, vec3_t origin)
{
	/* the angles are always 0 in be_aas_reach.c; a model that is not in the file has empty bounds */
	if (modelnum < 0 || modelnum >= g_nummodels) { VectorClear(mins); VectorClear(maxs); }
	else { VectorCopy(g_modelmins[modelnum], mins); VectorCopy(g_modelmaxs[modelnum], maxs); }
	if (origin) VectorClear(origin);
}

static unsigned fb(float f) { unsigned u; memcpy(&u, &f, 4); return u; }

/* ------------------------------------------------------------ the scenario */

static int g_full;
static int g_seen[MAX_TRAVELTYPES];

static void print_reach(int area, int k, aas_reachability_t *r)
{
	printf("R %d %d %d %d %d S #%08x #%08x #%08x E #%08x #%08x #%08x %d %d\n", area, k, r->areanum, r->facenum, r->edgenum,
		fb(r->start[0]), fb(r->start[1]), fb(r->start[2]), fb(r->end[0]), fb(r->end[1]), fb(r->end[2]),
		r->traveltype, (int) r->traveltime);
}

static unsigned mix(unsigned h, unsigned v)
{
	int i;
	for (i = 0; i < 4; i++) { h ^= (v >> (8 * i)) & 255; h *= 16777619u; }
	return h;
}

static void run_file(const char *aaspath, const char *bsppath)
{
	FILE *f = fopen(aaspath, "rb");
	aas_header_t header;
	int code, i, k, n, bspsize = 0;
	unsigned char *bsp = NULL;
	if (!f) { printf("FILE %s missing\n", aaspath); return; }
	fseek(f, 0, SEEK_END); g_size = ftell(f); fseek(f, 0, SEEK_SET);
	g_file = (unsigned char *) malloc(g_size + 1);
	fread(g_file, 1, g_size, f);
	fclose(f);
	strcpy(g_name, "maps/reach.aas");
	memset(&aasworld, 0, sizeof(aasworld));
	memcpy(&header, g_file, sizeof(header));
	if (header.version == AASVERSION) AAS_DData((unsigned char *) &header + 8, sizeof(aas_header_t) - 8);
	sprintf(g_checksum, "%d", header.bspchecksum);
	{ const char *s = aaspath, *p; for (p = aaspath; *p; p++) if (*p == '/' || *p == '\\') s = p + 1; printf("FILE %s\n", s); }
	code = AAS_LoadAASFile(g_name);
	printf("LOAD %d\n", code);
	if (code != BLERR_NOERROR) { free(g_file); return; }
	aasworld.loaded = qtrue;
	n = aasworld.numareas;
	printf("AAS %d %d\n", n, aasworld.reachabilitysize);
	printf("GEO %d %d %d %d\n", aasworld.numfaces, aasworld.numedges, aasworld.numvertexes, aasworld.faceindexsize);
	if (n < 3) { free(g_file); return; }
	/* the BSP: entities (lump 0) and models (lump 7) */
	g_numents = 1; g_nummodels = 0;
	f = fopen(bsppath, "rb");
	if (f)
	{
		fseek(f, 0, SEEK_END); bspsize = ftell(f); fseek(f, 0, SEEK_SET);
		bsp = (unsigned char *) malloc(bspsize + 1);
		fread(bsp, 1, bspsize, f);
		fclose(f);
		{
			int *lumps = (int *) (bsp + 8);
			int eofs = lumps[0], elen = lumps[1], mofs = lumps[14], mlen = lumps[15];
			parse_entities((const char *) bsp + eofs, elen);
			g_nummodels = mlen / 40;
			if (g_nummodels > 1024) g_nummodels = 1024;
			for (i = 0; i < g_nummodels; i++)
			{
				float *m = (float *) (bsp + mofs + i * 40);
				for (k = 0; k < 3; k++) { g_modelmins[i][k] = m[k] - 1; g_modelmaxs[i][k] = m[3 + k] + 1; }
			}
		}
		free(bsp);
	}
	printf("BSP %d %d\n", g_numents - 1, g_nummodels);
	/* throw away the reachabilities of the file */
	free(aasworld.reachability);
	aasworld.reachability = NULL;
	aasworld.reachabilitysize = 0;
	for (i = 0; i < n; i++) { aasworld.areasettings[i].numreachableareas = 0; aasworld.areasettings[i].firstreachablearea = 0; }
	aasworld.numreachabilityareas = 0;
	/* be_aas_reach.c passes face numbers WITH their sign to AAS_FaceCenter, which reads faces[-n]: the memory before the faces.
	   The tool puts zero faces there (a zero face has no edge, its center is 0 * infinity); the Delphi port does the same. */
	{
		aas_face_t *pad = (aas_face_t *) calloc(2 * aasworld.numfaces + 1, sizeof(aas_face_t));
		memcpy(pad + aasworld.numfaces, aasworld.faces, aasworld.numfaces * sizeof(aas_face_t));
		aasworld.faces = pad + aasworld.numfaces;
	}
	AAS_InitSettings();
	AAS_InitAASLinkHeap();
	AAS_InitAASLinkedEntities();
	g_pct_count = 0; g_pct_hash = 2166136261u;
	AAS_InitReachability();
	{
		int calls = 0;
		while (AAS_ContinueInitReachability(0)) calls++;
		printf("CALLS %d\n", calls);
	}
	printf("PCT %u %u\n", g_pct_count, g_pct_hash);
	printf("CT %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n", reach_swim, reach_equalfloor, reach_step, reach_walk,
		reach_barrier, reach_waterjump, reach_walkoffledge, reach_jump, reach_ladder, reach_teleport, reach_elevator,
		reach_funcbob, reach_grapple, reach_doublejump, reach_rampjump, reach_strafejump, reach_rocketjump, reach_bfgjump,
		reach_jumppad);
	printf("RS %d %d\n", aasworld.reachabilitysize, aasworld.numreachabilityareas);
	memset(g_seen, 0, sizeof(g_seen));
	for (i = 0; i < n; i++)
	{
		aas_areasettings_t *as = &aasworld.areasettings[i];
		unsigned h = 2166136261u;
		int newtype = 0;
		for (k = 0; k < as->numreachableareas; k++)
		{
			aas_reachability_t *r = &aasworld.reachability[as->firstreachablearea + k];
			int t = r->traveltype & TRAVELTYPE_MASK;
			h = mix(h, r->areanum); h = mix(h, r->facenum); h = mix(h, r->edgenum);
			h = mix(h, fb(r->start[0])); h = mix(h, fb(r->start[1])); h = mix(h, fb(r->start[2]));
			h = mix(h, fb(r->end[0])); h = mix(h, fb(r->end[1])); h = mix(h, fb(r->end[2]));
			h = mix(h, r->traveltype); h = mix(h, r->traveltime);
			if (t >= 0 && t < MAX_TRAVELTYPES && !g_seen[t]) { g_seen[t] = 1; newtype = 1; }
		}
		printf("A %d %d %d %u\n", i, as->numreachableareas, as->areaflags, h);
		if (g_full || newtype)
			for (k = 0; k < as->numreachableareas; k++)
				print_reach(i, k, &aasworld.reachability[as->firstreachablearea + k]);
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
	if (argc < 5) { printf("usage: reachgen <full|digest> <grapple> <file.aas> <file.bsp> ...\n"); return 1; }
	g_full = !strcmp(argv[1], "full");
	g_grapple = atoi(argv[2]);
	g_ents = (bspent_t *) calloc(MAX_ENTITIES, sizeof(bspent_t));
	for (i = 3; i + 1 < argc; i += 2) run_file(argv[i], argv[i + 1]);
	return 0;
}
