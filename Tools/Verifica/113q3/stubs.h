/* Minimal replacement of the engine around cmd.c and cvar.c of Quake III (issue #113, Quake III profile). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <ctype.h>
#include <assert.h>

typedef unsigned char byte;
typedef enum {qfalse, qtrue} qboolean;
typedef float vec_t;

#define QDECL
#define ERR_FATAL 0
#define ERR_DROP 1
#define Com_Memset memset
#define Com_Memcpy memcpy
#define S_Malloc(size) calloc(1, (size))
#define Z_Free free

typedef void (*xcommand_t) (void);
typedef int fileHandle_t;
typedef int cvarHandle_t;
