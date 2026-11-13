/*
 * Minimal stubs for the BSP part of Quake III Arena (code/renderer/tr_bsp.c, tr_curve.c),
 * which is included by bspgen.c with the lines of the original (see build.sh).
 * Issue #116. The stubs replace the renderer: the memory manager (zeroed, like Z_Malloc;
 * ri.Free does nothing, like a zone block that is not reused at once), the cvars, the
 * shader system and the world structure; nothing of the algorithms is changed.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdarg.h>

typedef unsigned char byte;
#define qfalse 0
#define qtrue 1
typedef int qboolean;
typedef float vec_t;
typedef vec_t vec3_t[3];

#define MAX_PATCH_SIZE 32
#define MAX_GRID_SIZE 65
#define MAC_STATIC
#define PATCH_STITCHING
#define SMP_FRAMES 1
#define ID_INLINE inline
#define Com_Memcpy memcpy
#define Com_Memset memset
#define LittleLong(x) (x)
#define LittleFloat(x) (x)
#define PRINT_ALL 0
#define SURF_NODRAW 0x80

#define DotProduct(x,y)			((x)[0]*(y)[0]+(x)[1]*(y)[1]+(x)[2]*(y)[2])
#define VectorSubtract(a,b,c)	((c)[0]=(a)[0]-(b)[0],(c)[1]=(a)[1]-(b)[1],(c)[2]=(a)[2]-(b)[2])
#define VectorAdd(a,b,c)		((c)[0]=(a)[0]+(b)[0],(c)[1]=(a)[1]+(b)[1],(c)[2]=(a)[2]+(b)[2])
#define VectorCopy(a,b)			((b)[0]=(a)[0],(b)[1]=(a)[1],(b)[2]=(a)[2])
#define	VectorScale(v, s, o)	((o)[0]=(v)[0]*(s),(o)[1]=(v)[1]*(s),(o)[2]=(v)[2]*(s))
#define VectorClear(a)			((a)[0]=(a)[1]=(a)[2]=0)

typedef enum {
	SF_BAD,
	SF_SKIP,
	SF_FACE,
	SF_GRID,
	SF_TRIANGLES,
	SF_POLY,
	SF_MD3,
	SF_MD4,
	SF_FLARE,
	SF_ENTITY
} surfaceType_t;

typedef struct { int integer; float value; } cvar_t;
static cvar_t r_subdivisions_storage = { 4, 4.0f };
static cvar_t *r_subdivisions = &r_subdivisions_storage;
static cvar_t r_singleShader_storage = { 0, 0.0f };
static cvar_t *r_singleShader = &r_singleShader_storage;
static cvar_t r_mapOverBrightBits_storage = { 2, 2.0f };
static cvar_t *r_mapOverBrightBits = &r_mapOverBrightBits_storage;
/* issue #116, second slice: the lightmap loader, the light grid and the nodes (tr_bsp.c) */
static cvar_t r_vertexLight_storage = { 0, 0.0f };
static cvar_t *r_vertexLight = &r_vertexLight_storage;
static cvar_t r_lightmap_storage = { 0, 0.0f };
static cvar_t *r_lightmap = &r_lightmap_storage;
static struct { int hardwareType; } glConfig = { 0 };
#define GLHW_PERMEDIA2 1
#define GL_CLAMP 0x2900
#define h_low 0
#define ERR_DROP 1
#define PRINT_WARNING 1
#define CONTENTS_NODE -1
typedef struct cplane_s { vec3_t normal; float dist; byte type; byte signbits; byte pad[2]; } cplane_t;
typedef struct { int index; } image_t;
static void R_SyncRenderThread(void) {}

static void *stub_malloc(int n) { return calloc(1, n + 64); }
static void stub_free(void *p) { (void)p; }
static void stub_printf(int level, const char *fmt, ...) {
	va_list args;
	(void)level;
	printf("ri ");
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);
}
static void stub_error(int level, const char *fmt, ...) {
	va_list args;
	(void)level;
	printf("ERROR ");
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);
	printf("\n");
	exit(1);
}
static struct {
	void *(*Malloc)(int);
	void *(*Hunk_Alloc)(int, ...);
	void (*Free)(void *);
	void (*Printf)(int, const char *, ...);
	void (*Error)(int, const char *, ...);
} ri = { stub_malloc, (void *(*)(int, ...))stub_malloc, stub_free, stub_printf, stub_error };

typedef struct { int isSky; } shader_t;
static shader_t g_shader;
static struct { int overbrightBits; shader_t *defaultShader; int numLightmaps; image_t *lightmaps[256]; } tr = { 1, &g_shader };

typedef struct {
	int viewCount;
	shader_t *shader;
	int fogIndex;
	surfaceType_t *data;
} msurface_t;

static shader_t *ShaderForShaderNum(int shaderNum, int lightmapNum) {
	(void)shaderNum; (void)lightmapNum;
	return &g_shader;
}
