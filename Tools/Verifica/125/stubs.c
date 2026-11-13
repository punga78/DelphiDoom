/* Stubs of the engine services that ui_shared.c, l_script.c, l_precomp.c and l_memory.c ask for.
   Nothing here is game logic: file reads come from a folder, memory from malloc, the log is a list of lines. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "../game/q_shared.h"
#include "../game/botlib.h"
#include "../botlib/be_interface.h"
#include "../botlib/l_log.h"
#include "ui_shared.h"

extern char g_root[512];
extern void LogLine(const char *fmt, ...);

/* ---- botlib import ---- */
static FILE *files[64];

static void QDECL BI_Print(int type, char *fmt, ...) {
	char buf[4096];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	LogLine("botlib[%d] %s", type, buf);
}
static void *BI_GetMemory(int size) { return malloc(size); }
static void BI_FreeMemory(void *p) { free(p); }
static int BI_AvailableMemory(void) { return 1 << 28; }
static void *BI_HunkAlloc(int size) { return malloc(size); }
static int BI_FOpen(const char *qpath, fileHandle_t *file, fsMode_t mode) {
	char path[1024];
	int i, len;
	FILE *f;
	snprintf(path, sizeof(path), "%s/%s", g_root, qpath);
	f = fopen(path, "rb");
	if (!f) { *file = 0; return -1; }
	fseek(f, 0, SEEK_END);
	len = (int)ftell(f);
	fseek(f, 0, SEEK_SET);
	for (i = 1; i < 64; i++) if (!files[i]) break;
	files[i] = f;
	*file = i;
	return len;
}
static int BI_Read(void *buffer, int len, fileHandle_t f) { return (int)fread(buffer, 1, len, files[f]); }
static void BI_Close(fileHandle_t f) { fclose(files[f]); files[f] = NULL; }

botlib_import_t botimport;
void InitBotImport(void) {
	memset(&botimport, 0, sizeof(botimport));
	botimport.Print = BI_Print;
	botimport.GetMemory = BI_GetMemory;
	botimport.FreeMemory = BI_FreeMemory;
	botimport.AvailableMemory = BI_AvailableMemory;
	botimport.HunkAlloc = BI_HunkAlloc;
	botimport.FS_FOpenFile = BI_FOpen;
	botimport.FS_Read = BI_Read;
	botimport.FS_FCloseFile = BI_Close;
}

/* ---- l_log.h ---- */
void Log_Open(char *filename) {}
void Log_Close(void) {}
void Log_Shutdown(void) {}
void QDECL Log_Write(char *fmt, ...) {}
void QDECL Log_WriteTimeStamped(char *fmt, ...) {}
FILE *Log_FilePointer(void) { return NULL; }
void Log_Flush(void) {}

/* ---- q_shared.c services ---- */
void QDECL Com_Error(int level, const char *error, ...) {
	char buf[4096];
	va_list ap;
	va_start(ap, error);
	vsnprintf(buf, sizeof(buf), error, ap);
	va_end(ap);
	printf("FATAL %s\n", buf);
	exit(3);
}
void QDECL Com_Printf(const char *msg, ...) {
	char buf[4096];
	va_list ap;
	va_start(ap, msg);
	vsnprintf(buf, sizeof(buf), msg, ap);
	va_end(ap);
	LogLine("%s", buf);
}

/* ---- the trap calls of the ui module, over the botlib precompiler ---- */
int PC_LoadSourceHandle(const char *filename);
int PC_FreeSourceHandle(int handle);
int PC_ReadTokenHandle(int handle, pc_token_t *pc_token);
int PC_SourceFileAndLine(int handle, char *filename, int *line);
int PC_AddGlobalDefine(char *string);

int trap_PC_AddGlobalDefine(char *define) { return PC_AddGlobalDefine(define); }
int trap_PC_LoadSource(const char *filename) { return PC_LoadSourceHandle(filename); }
int trap_PC_FreeSource(int handle) { return PC_FreeSourceHandle(handle); }
int trap_PC_ReadToken(int handle, pc_token_t *pc_token) { return PC_ReadTokenHandle(handle, pc_token); }
int trap_PC_SourceFileAndLine(int handle, char *filename, int *line) { return PC_SourceFileAndLine(handle, filename, line); }


/* q_shared.c / q_math.c (inline assembler of MSVC) services that the parser never reaches */
void Com_Memset(void *dest, const int val, const size_t count) { memset(dest, val, count); }
void Com_Memcpy(void *dest, const void *src, const size_t count) { memcpy(dest, src, count); }
void AxisClear(vec3_t axis[3]) {}
void AnglesToAxis(const vec3_t angles, vec3_t axis[3]) {}
