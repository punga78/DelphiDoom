/* Minimal replacement of the engine around msg.c, huffman.c and net_chan.c (issue #121). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <setjmp.h>
#include <assert.h>

typedef unsigned char byte;
typedef enum {qfalse, qtrue} qboolean;
typedef float vec_t;
typedef vec_t vec3_t[3];

#define QDECL
#define ERR_FATAL 0
#define ERR_DROP 1
#define Com_Memset memset
#define Com_Memcpy memcpy
#define LittleShort(x) (x)
#define LittleLong(x) (x)

typedef struct { int integer; } cvar_t;
