/* Stub of code/game/botlib.h: print levels, error codes, the file system part of botimport, bsp_trace_t */
#ifndef STUB_BOTLIB_H
#define STUB_BOTLIB_H

#define BLERR_NOERROR 0
#define BLERR_CANNOTOPENAASFILE 4
#define BLERR_WRONGAASFILEID 5
#define BLERR_WRONGAASFILEVERSION 6
#define BLERR_CANNOTREADAASLUMP 7

#define PRT_MESSAGE 1
#define PRT_WARNING 2
#define PRT_ERROR 3
#define PRT_FATAL 4
#define PRT_EXIT 5

#define FS_SEEK_SET 0

typedef int fileHandle_t;
typedef enum { FS_READ, FS_WRITE, FS_APPEND, FS_APPEND_SYNC } fsMode_t;

typedef struct botlib_import_s
{
	void (*Print)(int type, char *fmt, ...);
	int (*FS_FOpenFile)(const char *qpath, fileHandle_t *file, fsMode_t mode);
	int (*FS_Read)(void *buffer, int len, fileHandle_t f);
	int (*FS_Write)(const void *buffer, int len, fileHandle_t f);
	void (*FS_FCloseFile)(fileHandle_t f);
	int (*FS_Seek)(fileHandle_t f, long offset, int origin);
} botlib_import_t;

/* only the fields be_aas_sample.c touches */
typedef struct bsp_trace_s
{
	qboolean startsolid;
	float fraction;
	vec3_t endpos;
	int ent;
} bsp_trace_t;

#endif
