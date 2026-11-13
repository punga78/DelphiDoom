/*
 * Stubs for the collision model of Quake III Arena (issue #118): memory, errors, cvars, file
 * system, and a patch collide that never collides (cm_patch.c is not ported yet).
 */
#include "qcommon/cm_local.h"
#include <stdarg.h>

/* one arena: cm_load.c turns the difference of two hunk pointers into an int index (the
   submodel leaf lists), which works when the blocks are close to each other */
static unsigned char g_arena[64 * 1024 * 1024];
static size_t g_used;

void *Hunk_Alloc(int size, ha_pref preference) {
	void *result = g_arena + g_used;
	(void)preference;
	g_used += ((size_t)size + 31) & ~(size_t)15;
	if (g_used > sizeof(g_arena)) {
		printf("ERROR arena\n");
		exit(2);
	}
	return result;
}

void Com_Error(int level, const char *fmt, ...) {
	va_list args;
	(void)level;
	printf("ERROR ");
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);
	printf("\n");
	exit(2);
}

void Com_DPrintf(const char *fmt, ...) {
	(void)fmt;
}

void Com_Printf(const char *fmt, ...) {
	(void)fmt;
}

cvar_t *Cvar_Get(const char *name, const char *value, int flags) {
	(void)name; (void)value; (void)flags;
	return calloc(1, sizeof(cvar_t));
}

int FS_ReadFile(const char *qpath, void **buffer) {
	FILE *f = fopen(qpath, "rb");
	long length;
	if (!f) {
		*buffer = NULL;
		return -1;
	}
	fseek(f, 0, SEEK_END);
	length = ftell(f);
	fseek(f, 0, SEEK_SET);
	*buffer = malloc(length + 1);
	fread(*buffer, 1, length, f);
	fclose(f);
	return (int)length;
}

void FS_FreeFile(void *buffer) {
	free(buffer);
}

unsigned Com_BlockChecksum(const void *buffer, int length) {
	const unsigned char *p = buffer;
	unsigned h = 2166136261u;
	int i;
	for (i = 0; i < length; i++) {
		h = (h ^ p[i]) * 16777619u;
	}
	return h;
}

void Q_strncpyz(char *dest, const char *src, int destsize) {
	strncpy(dest, src, destsize - 1);
	dest[destsize - 1] = 0;
}

/* the patch collide: present as a pointer, never collides */
static int g_patch_marker;

struct patchCollide_s *CM_GeneratePatchCollide(int width, int height, vec3_t *points) {
	(void)width; (void)height; (void)points;
	return (struct patchCollide_s *)&g_patch_marker;
}

void CM_TraceThroughPatchCollide(traceWork_t *tw, const struct patchCollide_s *pc) {
	(void)tw; (void)pc;
}

qboolean CM_PositionTestInPatchCollide(traceWork_t *tw, const struct patchCollide_s *pc) {
	(void)tw; (void)pc;
	return qfalse;
}

void CM_ClearLevelPatches(void) {
}
