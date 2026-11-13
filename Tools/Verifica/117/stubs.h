/*
 * Minimal stubs for the patch subdivision of Quake III Arena (code/renderer/tr_curve.c),
 * which is included by patchgen.c with the lines of the original (see build.sh).
 * Issue #117. The stubs replace the renderer: the memory manager, the cvar r_subdivisions
 * and the few vector macros of q_shared.h; nothing of the algorithm is changed.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

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
#define SF_GRID 5
typedef int surfaceType_t;

#define DotProduct(x,y)			((x)[0]*(y)[0]+(x)[1]*(y)[1]+(x)[2]*(y)[2])
#define VectorSubtract(a,b,c)	((c)[0]=(a)[0]-(b)[0],(c)[1]=(a)[1]-(b)[1],(c)[2]=(a)[2]-(b)[2])
#define VectorAdd(a,b,c)		((c)[0]=(a)[0]+(b)[0],(c)[1]=(a)[1]+(b)[1],(c)[2]=(a)[2]+(b)[2])
#define VectorCopy(a,b)			((b)[0]=(a)[0],(b)[1]=(a)[1],(b)[2]=(a)[2])
#define	VectorScale(v, s, o)	((o)[0]=(v)[0]*(s),(o)[1]=(v)[1]*(s),(o)[2]=(v)[2]*(s))
#define VectorClear(a)			((a)[0]=(a)[1]=(a)[2]=0)

typedef struct { float value; } cvar_t;
static cvar_t r_subdivisions_storage = { 4.0f };
static cvar_t *r_subdivisions = &r_subdivisions_storage;

static void *stub_malloc(int n) { return malloc(n); }
static void stub_free(void *p) { free(p); }
static struct {
	void *(*Malloc)(int);
	void *(*Hunk_Alloc)(int);
	void (*Free)(void *);
} ri = { stub_malloc, stub_malloc, stub_free };
