/*
 * Stub of code/game/q_shared.h of Quake III Arena for the parity tool of the issue #124:
 * only what be_ai_chat.c, l_script.c and l_precomp.c use. Nothing of the algorithms is here.
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

typedef int qboolean;
#define qfalse 0
#define qtrue 1
#define QDECL
#define MAX_QPATH 64
#define MAX_PATH 260
#define MAX_CLIENTS 64
#define PATHSEPERATOR_CHAR '\\'
#define ERR_FATAL 0
#define ERR_DROP 1

#define MAX_TOKENLENGTH 1024
typedef struct pc_token_s
{
	int type;
	int subtype;
	int intvalue;
	float floatvalue;
	char string[MAX_TOKENLENGTH];
} pc_token_t;

#define Com_Memcpy memcpy
#define Com_Memset memset

/* q_shared.h: ((rand () & 0x7fff) / ((float)0x7fff)) */
#define random()	((rand () & 0x7fff) / ((float)0x7fff))

#define Q_stricmp _stricmp
int Com_sprintf(char *dest, int size, const char *fmt, ...);
void Com_Error(int level, const char *fmt, ...);
char *va(char *format, ...);
void Q_strncpyz(char *dest, const char *src, int destsize);
int COM_Compress(char *data_p);

#endif
