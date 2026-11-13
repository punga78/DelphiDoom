/*
 * Stub of qcommon.h for the collision model of Quake III Arena (issue #118): the few things
 * that cm_load.c, cm_test.c and cm_trace.c take from the engine. The memory manager is calloc,
 * the cvars are fixed (all zero), the file system reads the file, Com_Error stops the program.
 */
#ifndef QCOMMON_STUB_H
#define QCOMMON_STUB_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "qfiles.h"
#include "cm_public.h"

#define Com_Memcpy memcpy
#define Com_Memset memset
#undef LittleLong
#undef LittleFloat
#define LittleLong(x) (x)
#define LittleFloat(x) (x)

#define ERR_DROP 1
#define CVAR_CHEAT 0
#define CVAR_ARCHIVE 0

void Com_Error(int level, const char *fmt, ...);
void Com_DPrintf(const char *fmt, ...);
cvar_t *Cvar_Get(const char *name, const char *value, int flags);
int FS_ReadFile(const char *qpath, void **buffer);
void FS_FreeFile(void *buffer);
unsigned Com_BlockChecksum(const void *buffer, int length);

#endif
