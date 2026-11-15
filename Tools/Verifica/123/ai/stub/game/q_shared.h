/*
 * Stub of code/game/q_shared.h of Quake III Arena for the parity tool of the bot AI (issue #123: goals,
 * movement and genetic selection) that links the REAL be_ai_goal.c, be_ai_move.c, be_ai_gen.c, be_ea.c,
 * be_ai_weight.c, be_aas_file.c, be_aas_sample.c, be_aas_route.c, be_aas_routealt.c, be_aas_move.c,
 * be_aas_bspq3.c, l_script.c, l_precomp.c, l_struct.c and l_libvar.c. The macros are copied from the real file
 * (lines 611-643, 676, 1371); VectorLength, VectorNormalize, VectorNormalize2, vectoangles, AngleVectors are
 * the real functions of q_math.c (build.sh pastes them). Nothing of the algorithms is here.
 */
#ifndef STUB_Q_SHARED_H
#define STUB_Q_SHARED_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <limits.h>
#include <ctype.h>
#include <time.h>
#include <math.h>
#include <assert.h>
#include <stddef.h>

typedef int qboolean;
#define qfalse 0
#define qtrue 1
#define QDECL
#define MAX_QPATH 64
#define MAX_PATH 260
#define MAX_CLIENTS 64
#define MAX_GENTITIES 1024
#define ENTITYNUM_NONE (MAX_GENTITIES-1)
#define ENTITYNUM_WORLD (MAX_GENTITIES-2)
#define MAX_MODELS 256
#define PATHSEPERATOR_CHAR '\\'
#define ERR_FATAL 0
#define ERR_DROP 1
typedef unsigned char byte;
typedef float vec_t;
typedef vec_t vec3_t[3];
typedef vec_t vec2_t[2];

#define MAX_TOKENLENGTH 1024
typedef struct pc_token_s
{
	int type;
	int subtype;
	int intvalue;
	float floatvalue;
	char string[MAX_TOKENLENGTH];
} pc_token_t;

#define CONTENTS_SOLID 1
#define CONTENTS_LAVA 8
#define CONTENTS_SLIME 16
#define CONTENTS_WATER 32
#define CONTENTS_PLAYERCLIP 0x10000
#define CONTENTS_BODY 0x2000000

#define DotProduct(x,y)			((x)[0]*(y)[0]+(x)[1]*(y)[1]+(x)[2]*(y)[2])
#define VectorSubtract(a,b,c)	((c)[0]=(a)[0]-(b)[0],(c)[1]=(a)[1]-(b)[1],(c)[2]=(a)[2]-(b)[2])
#define VectorAdd(a,b,c)		((c)[0]=(a)[0]+(b)[0],(c)[1]=(a)[1]+(b)[1],(c)[2]=(a)[2]+(b)[2])
#define VectorCopy(a,b)			((b)[0]=(a)[0],(b)[1]=(a)[1],(b)[2]=(a)[2])
#define	VectorScale(v, s, o)	((o)[0]=(v)[0]*(s),(o)[1]=(v)[1]*(s),(o)[2]=(v)[2]*(s))
#define	VectorMA(v, s, b, o)	((o)[0]=(v)[0]+(b)[0]*(s),(o)[1]=(v)[1]+(b)[1]*(s),(o)[2]=(v)[2]+(b)[2]*(s))
#define VectorClear(a)			((a)[0]=(a)[1]=(a)[2]=0)
#define VectorNegate(a,b)		((b)[0]=-(a)[0],(b)[1]=-(a)[1],(b)[2]=-(a)[2])
#define VectorSet(v, x, y, z)	((v)[0]=(x), (v)[1]=(y), (v)[2]=(z))
#define Square(x) ((x)*(x))

static void VectorInverse( vec3_t v ){
	v[0] = -v[0];
	v[1] = -v[1];
	v[2] = -v[2];
}

static void CrossProduct( const vec3_t v1, const vec3_t v2, vec3_t cross ) {
	cross[0] = v1[1]*v2[2] - v1[2]*v2[1];
	cross[1] = v1[2]*v2[0] - v1[0]*v2[2];
	cross[2] = v1[0]*v2[1] - v1[1]*v2[0];
}

static vec_t VectorLengthSquared( const vec3_t v ) {
	return (v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
}

vec_t VectorLength( const vec3_t v );
vec_t VectorNormalize( vec3_t v );
vec_t VectorNormalize2( const vec3_t v, vec3_t out );
void vectoangles( const vec3_t value1, vec3_t angles );
void AngleVectors( const vec3_t angles, vec3_t forward, vec3_t right, vec3_t up);

/* little endian machine: the macros of q_shared.h do nothing */
#define LittleShort(x) (x)
#define LittleLong(x) (x)
#define LittleFloat(x) (x)

#define Com_Memset memset
#define Com_Memcpy memcpy

#define PITCH 0
#define YAW 1
#define ROLL 2
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif
static const vec3_t vec3_origin = {0, 0, 0};
/* VectorCompare of q_math.c: exact comparison */
static int VectorCompare( const vec3_t v1, const vec3_t v2 ) {
	if (v1[0] != v2[0] || v1[1] != v2[1] || v1[2] != v2[2]) return 0;
	return 1;
}

/* q_shared.h: ((rand () & 0x7fff) / ((float)0x7fff)) */
#define random()	((rand () & 0x7fff) / ((float)0x7fff))

/* q_shared.h: crandom() */
#define crandom()	(2.0 * (random() - 0.5))

#define Q_stricmp _stricmp
int Com_sprintf(char *dest, int size, const char *fmt, ...);
void Com_Error(int level, const char *fmt, ...);
char *va(char *format, ...);
void Q_strncpyz(char *dest, const char *src, int destsize);
int COM_Compress(char *data_p);

typedef struct cplane_s
{
	vec3_t normal;
	float dist;
	byte type;
	byte signbits;
	byte pad[2];
} cplane_t;

#endif
