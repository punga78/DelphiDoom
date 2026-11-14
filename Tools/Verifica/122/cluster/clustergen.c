/*
 * Parity tool of the clustering and of the optimizer of Quake III Arena (issue #122): it links the REAL be_aas_file.c,
 * be_aas_sample.c, be_aas_cluster.c and be_aas_optimize.c of code/botlib (included below, read only, copied by build.sh)
 * with the stubs of ../stub/ and ../route/stub/, loads each .aas file given on the command line and runs four cases:
 *   A  AAS_InitClustering on the file as it is (it has clusters and nothing is forced: nothing happens)
 *   B  the same with the library variable forceclustering = 1
 *   C  the same on a file whose clusters, portals, portal index and the cluster numbers of the areas were wiped
 *   D  AAS_Optimize
 * The twin of this file is Tests/Source/DelphiDoom.Tests.Aas.Cluster.Scenario.pas: every line printed here is printed there
 * with the same text. Floats are the 8 hexadecimal digits of their bits.
 *
 *   clustergen <file.aas> [<file.aas> ...]
 */
#include "game/q_shared.h"
#include "game/botlib.h"
#include "botlib/aasfile.h"
#include "game/be_aas.h"
#include "botlib/be_aas_funcs.h"
#include "botlib/be_interface.h"
#include "botlib/be_aas_def.h"
#include "botlib/l_log.h"

#include "vmath.inc"
#include "aaserror.inc"
#include "areareach.inc"

float LibVarGetValue(char *var_name);
void Com_sprintf(char *dest, int size, const char *fmt, ...);
#include "botlib/be_aas_file.c"
#include "botlib/be_aas_sample.c"
#include "botlib/be_aas_cluster.c"
#include "botlib/be_aas_optimize.c"

botlib_import_t botimport;
int bot_developer = 1;
aas_t aasworld;
static int g_force;

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

void QDECL Log_Write(char *fmt, ...)
{
	char text[4096];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(text, sizeof(text), fmt, ap);
	va_end(ap);
	printf("L|");
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
float LibVarGetValue(char *var_name) { return (g_force && !strcmp(var_name, "forceclustering")) ? 1.0f : 0.0f; }
qboolean AAS_EntityCollision(int entnum, vec3_t start, vec3_t boxmins, vec3_t boxmaxs, vec3_t end,
								int contentmask, bsp_trace_t *trace) { return qfalse; }
void Com_sprintf(char *dest, int size, const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(dest, size, fmt, ap);
	va_end(ap);
}

static unsigned fb(float f) { unsigned u; memcpy(&u, &f, 4); return u; }

static unsigned g_hash;
static void h(unsigned v) { g_hash ^= v; g_hash *= 16777619u; }

static void dump_clusters(const char *tag)
{
	int i, n = aasworld.numareas;
	printf("%s %d %d %d\n", tag, aasworld.numportals, aasworld.portalindexsize, aasworld.numclusters);
	for (i = 1; i < aasworld.numportals; i++)
		printf("PO %d %d %d %d %d %d\n", i, aasworld.portals[i].areanum, aasworld.portals[i].frontcluster,
			aasworld.portals[i].backcluster, aasworld.portals[i].clusterareanum[0], aasworld.portals[i].clusterareanum[1]);
	for (i = 1; i < aasworld.numclusters; i++)
		printf("CL %d %d %d %d %d\n", i, aasworld.clusters[i].numareas, aasworld.clusters[i].numreachabilityareas,
			aasworld.clusters[i].numportals, aasworld.clusters[i].firstportal);
	g_hash = 2166136261u;
	for (i = 0; i < aasworld.portalindexsize; i++) h(aasworld.portalindex[i]);
	printf("PI %u\n", g_hash);
	g_hash = 2166136261u;
	for (i = 0; i < n; i++) { h(aasworld.areasettings[i].contents); h(aasworld.areasettings[i].cluster); h(aasworld.areasettings[i].clusterareanum); h(aasworld.areasettings[i].areaflags); }
	printf("SH %u\n", g_hash);
	for (i = 0; i < n && i < 40; i++)
		printf("SA %d %d %d %d\n", i, aasworld.areasettings[i].contents, aasworld.areasettings[i].cluster, aasworld.areasettings[i].clusterareanum);
}

static void dump_geometry(void)
{
	int i, j;
	printf("GEO %d %d %d %d %d %d\n", aasworld.numvertexes, aasworld.numedges, aasworld.edgeindexsize, aasworld.numfaces,
		aasworld.faceindexsize, aasworld.numareas);
	g_hash = 2166136261u;
	for (i = 0; i < aasworld.numvertexes; i++) for (j = 0; j < 3; j++) h(fb(aasworld.vertexes[i][j]));
	printf("GV %u\n", g_hash);
	g_hash = 2166136261u;
	for (i = 0; i < aasworld.numedges; i++) { h(aasworld.edges[i].v[0]); h(aasworld.edges[i].v[1]); }
	printf("GD %u\n", g_hash);
	g_hash = 2166136261u;
	for (i = 0; i < aasworld.edgeindexsize; i++) h(aasworld.edgeindex[i]);
	printf("GI %u\n", g_hash);
	g_hash = 2166136261u;
	for (i = 0; i < aasworld.numfaces; i++) { h(aasworld.faces[i].planenum); h(aasworld.faces[i].faceflags); h(aasworld.faces[i].numedges);
		h(aasworld.faces[i].firstedge); h(aasworld.faces[i].frontarea); h(aasworld.faces[i].backarea); }
	printf("GC %u\n", g_hash);
	g_hash = 2166136261u;
	for (i = 0; i < aasworld.faceindexsize; i++) h(aasworld.faceindex[i]);
	printf("GJ %u\n", g_hash);
	g_hash = 2166136261u;
	for (i = 0; i < aasworld.numareas; i++) {
		h(aasworld.areas[i].areanum); h(aasworld.areas[i].numfaces); h(aasworld.areas[i].firstface);
		for (j = 0; j < 3; j++) { h(fb(aasworld.areas[i].mins[j])); h(fb(aasworld.areas[i].maxs[j])); h(fb(aasworld.areas[i].center[j])); } }
	printf("GR %u\n", g_hash);
	g_hash = 2166136261u;
	for (i = 0; i < aasworld.reachabilitysize; i++) { h(aasworld.reachability[i].facenum); h(aasworld.reachability[i].edgenum); }
	printf("GK %u\n", g_hash);
	for (i = 0; i < aasworld.numedges && i < 12; i++) printf("GE %d %d %d\n", i, aasworld.edges[i].v[0], aasworld.edges[i].v[1]);
	for (i = 0; i < aasworld.numfaces && i < 12; i++) printf("GF %d %d %d %d %d %d %d\n", i, aasworld.faces[i].planenum, aasworld.faces[i].faceflags,
		aasworld.faces[i].numedges, aasworld.faces[i].firstedge, aasworld.faces[i].frontarea, aasworld.faces[i].backarea);
	for (i = 0; i < aasworld.numareas && i < 12; i++) printf("GA %d %d %d\n", i, aasworld.areas[i].numfaces, aasworld.areas[i].firstface);
}

static int load(const char *path)
{
	FILE *f = fopen(path, "rb");
	aas_header_t header;
	int code;
	if (!f) { printf("FILE %s missing\n", path); return 0; }
	fseek(f, 0, SEEK_END); g_size = ftell(f); fseek(f, 0, SEEK_SET);
	g_file = (unsigned char *) malloc(g_size + 1);
	fread(g_file, 1, g_size, f);
	fclose(f);
	strcpy(g_name, "maps/cluster.aas");
	memset(&aasworld, 0, sizeof(aasworld));
	memcpy(&header, g_file, sizeof(header));
	if (header.version == AASVERSION) AAS_DData((unsigned char *) &header + 8, sizeof(aas_header_t) - 8);
	sprintf(g_checksum, "%d", header.bspchecksum);
	code = AAS_LoadAASFile(g_name);
	if (code != BLERR_NOERROR) { printf("LOAD %d\n", code); free(g_file); return 0; }
	aasworld.loaded = qtrue;
	return 1;
}

static void run_file(const char *path)
{
	const char *base = path, *p;
	int i;
	for (p = path; *p; p++) if (*p == '/' || *p == '\\') base = p + 1;
	printf("FILE %s\n", base);
	g_force = 0;
	if (!load(path)) return;
	printf("LOAD 0\n");
	/* A: nothing is forced */
	AAS_InitClustering();
	dump_clusters("A");
	/* B: forced */
	g_force = 1;
	AAS_InitClustering();
	dump_clusters("B");
	g_force = 0;
	free(g_file);
	/* C: the clusters are wiped */
	if (!load(path)) return;
	aasworld.numclusters = 0;
	aasworld.numportals = 0;
	aasworld.portalindexsize = 0;
	for (i = 0; i < aasworld.numareas; i++) { aasworld.areasettings[i].cluster = 0; aasworld.areasettings[i].clusterareanum = 0; }
	AAS_InitClustering();
	dump_clusters("C");
	free(g_file);
	/* D: the optimizer */
	if (!load(path)) return;
	AAS_Optimize();
	dump_geometry();
	free(g_file);
	/* E: the optimizer on a file where every seventh face is a ladder face (the maps have none) */
	if (!load(path)) return;
	for (i = 0; i < aasworld.numfaces; i++) if (i % 7 == 3) aasworld.faces[i].faceflags |= FACE_LADDER;
	AAS_Optimize();
	dump_geometry();
	free(g_file);
	/* F: the clusters wiped and flooded through the faces too (nofaceflood is a global of the original) */
	if (!load(path)) return;
	aasworld.numclusters = 0;
	aasworld.numportals = 0;
	aasworld.portalindexsize = 0;
	for (i = 0; i < aasworld.numareas; i++) { aasworld.areasettings[i].cluster = 0; aasworld.areasettings[i].clusterareanum = 0; }
	nofaceflood = qfalse;
	AAS_InitClustering();
	dump_clusters("F");
	nofaceflood = qtrue;
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
	if (argc < 2) { printf("usage: clustergen <file.aas> ...\n"); return 1; }
	for (i = 1; i < argc; i++) run_file(argv[i]);
	return 0;
}
