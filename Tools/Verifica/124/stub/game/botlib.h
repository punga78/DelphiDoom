/* Stub of code/game/botlib.h: the print levels, the file system part of botimport and the error codes */
#ifndef STUB_BOTLIB_H
#define STUB_BOTLIB_H

#define BOTLIB_API_VERSION 2
#define BLERR_NOERROR 0
#define BLERR_CANNOTLOADICHAT 20

#define PRT_MESSAGE 1
#define PRT_WARNING 2
#define PRT_ERROR 3
#define PRT_FATAL 4
#define PRT_EXIT 5

typedef int fileHandle_t;
typedef enum { FS_READ, FS_WRITE, FS_APPEND, FS_APPEND_SYNC } fsMode_t;

typedef struct botlib_import_s
{
	void (*Print)(int type, char *fmt, ...);
	int (*FS_FOpenFile)(const char *qpath, fileHandle_t *file, fsMode_t mode);
	int (*FS_Read)(void *buffer, int len, fileHandle_t f);
	void (*FS_FCloseFile)(fileHandle_t f);
} botlib_import_t;

#endif
