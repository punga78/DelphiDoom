/*
 * Minimal stubs for the RoQ decoder of Quake III Arena (code/client/cl_cin.c),
 * which is included by roqextract.c with the lines of the original (see build.sh).
 * Issue #114. The stubs replace the engine: the file system, the sound, the
 * clock and the renderer configuration; nothing of the decoder is changed.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned char byte;
typedef int qboolean;
#define qfalse 0
#define qtrue 1
typedef int fileHandle_t;
#define MAX_OSPATH 256

typedef enum {
	FMV_IDLE,
	FMV_PLAY,
	FMV_EOF,
	FMV_ID_BLT,
	FMV_ID_IDLE,
	FMV_LOOPED,
	FMV_ID_WAIT
} e_status;

typedef struct { int hardwareType; int maxTextureSize; } glconfig_t;
#define GLHW_RAGEPRO 3
static glconfig_t glConfig = { 0, 4096 };

typedef struct { float value; } cvar_t;
static cvar_t com_timescale_storage = { 1.0f };
static cvar_t *com_timescale = &com_timescale_storage;

#define LittleLong(x) (x)
#define Com_Printf(...) ((void)0)
#define Com_DPrintf(...) ((void)0)
#define Com_Memcpy memcpy

static int CL_ScaledMilliseconds(void) { return 0; }
static int s_paintedtime, s_rawend, s_soundtime;
static void S_Update(void) {}

/* the audio the decoder hands to the mixer is recorded by the driver */
static void S_RawSamples(int samples, int rate, int width, int channels, const byte *data, float volume);

/* a file in memory instead of the file system */
static const byte *g_file;
static long g_fileSize;
static long g_filePos;
static void Sys_EndStreamedFile(fileHandle_t f) { (void)f; }
static void FS_FCloseFile(fileHandle_t f) { (void)f; }
static int FS_FOpenFileRead(const char *name, fileHandle_t *f, qboolean uniq) {
	(void)name; (void)uniq; *f = 1; g_filePos = 0; return (int)g_fileSize;
}
static void Sys_BeginStreamedFile(fileHandle_t f, int readahead) { (void)f; (void)readahead; }
static int Sys_StreamedRead(void *buffer, int size, int count, fileHandle_t f) {
	long n = (long)size * count;
	(void)f;
	if (g_filePos + n > g_fileSize) n = g_fileSize - g_filePos;
	if (n < 0) n = 0;
	memcpy(buffer, g_file + g_filePos, n);
	/* the rest of the buffer keeps what it had, as with a short read of a real file */
	g_filePos += n;
	return count;
}
