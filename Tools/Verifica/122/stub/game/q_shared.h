/*
 * Stub of code/game/q_shared.h of Quake III Arena for the parity tool of the issue #122: the types
 * and the vector macros that be_aas_file.c and be_aas_sample.c use. The macros are copied from the
 * real file (lines 611-616, 641-642); VectorLength and VectorNormalize are the real functions of
 * q_math.c (build.sh pastes them into vmath.inc); VectorInverse and CrossProduct are the real
 * inline functions. Nothing of the algorithms of the AAS is here.
 */
#ifndef STUB_Q_SHARED_H
#define STUB_Q_SHARED_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <math.h>

typedef int qboolean;
#define qfalse 0
#define qtrue 1
#define QDECL
#define MAX_QPATH 64
#define MAX_PATH 260
typedef unsigned char byte;
typedef float vec_t;
typedef vec_t vec3_t[3];

#define CONTENTS_SOLID 1
#define CONTENTS_PLAYERCLIP 0x10000

#define DotProduct(x,y)			((x)[0]*(y)[0]+(x)[1]*(y)[1]+(x)[2]*(y)[2])
#define VectorSubtract(a,b,c)	((c)[0]=(a)[0]-(b)[0],(c)[1]=(a)[1]-(b)[1],(c)[2]=(a)[2]-(b)[2])
#define VectorAdd(a,b,c)		((c)[0]=(a)[0]+(b)[0],(c)[1]=(a)[1]+(b)[1],(c)[2]=(a)[2]+(b)[2])
#define VectorCopy(a,b)			((b)[0]=(a)[0],(b)[1]=(a)[1],(b)[2]=(a)[2])
#define	VectorScale(v, s, o)	((o)[0]=(v)[0]*(s),(o)[1]=(v)[1]*(s),(o)[2]=(v)[2]*(s))
#define	VectorMA(v, s, b, o)	((o)[0]=(v)[0]+(b)[0]*(s),(o)[1]=(v)[1]+(b)[1]*(s),(o)[2]=(v)[2]+(b)[2]*(s))
#define VectorClear(a)			((a)[0]=(a)[1]=(a)[2]=0)
#define VectorNegate(a,b)		((b)[0]=-(a)[0],(b)[1]=-(a)[1],(b)[2]=-(a)[2])

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

vec_t VectorLength( const vec3_t v );
vec_t VectorNormalize( vec3_t v );

/* little endian machine: the macros of q_shared.h do nothing */
#define LittleShort(x) (x)
#define LittleLong(x) (x)
#define LittleFloat(x) (x)

#define Com_Memset memset
#define Com_Memcpy memcpy

#endif
