/* Parity driver of the issue #119 (Quake III shaders).
   Includes, unchanged, renderer/tr_shader.c of Quake III Arena, so that its static functions (ScanAndLoadShaderFiles,
   ParseShader, FinishShader ...) are the ones that run, and calls R_FindShader. Everything the renderer would give is a
   stub: the images only remember their name, the file system is a folder, the cvars are numbers.
   Scenario lines (one command each, read from the file of the second argument):
     detail 0|1       r_detailTextures
     scan             ScanAndLoadShaderFiles (the .shader files of <root>/scripts, sorted by name)
     find <name>      R_FindShader(name, LIGHTMAP_NONE, qtrue) and a dump of what it returns
     internal         CreateInternalShaders ("<default>" is index 0, "<stencil shadow>" index 1)
     reg <name> <lm>  RE_RegisterShaderLightMap; the images whose name begins with "nofile" do not exist
     remap <name> <new name> [<time offset> | -]   R_RemapShader
     remapdump        every shader: index, name, lightmap, default flag, remapped index, time offset
   The dump: every float as the hexadecimal bits, every string as it is. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <setjmp.h>
#include <dirent.h>
#include "tr_shader.c"

trGlobals_t tr;
glconfig_t glConfig;
refimport_t ri;
backEndData_t *backEndData[SMP_FRAMES];
void (APIENTRY *qglActiveTextureARB)(GLenum texture) = NULL;

static cvar_t cv_detail, cv_zero;
cvar_t *r_detailTextures = &cv_detail;
cvar_t *r_ignoreFastPath = &cv_zero;
cvar_t *r_printShaders = &cv_zero;
cvar_t *r_smp = &cv_zero;
cvar_t *r_uiFullScreen = &cv_zero;
cvar_t *r_vertexLight = &cv_zero;

static char g_root[512];
static jmp_buf g_drop;
static image_t g_images[4096];
static int g_numImages;
static image_t g_white, g_scratch;

void R_SyncRenderThread(void) {}
void R_InitSkyTexCoords(float cloudLayerHeight) {}
void RB_StageIteratorGeneric(void) {}
void RB_StageIteratorSky(void) {}
void RB_StageIteratorVertexLitTexture(void) {}
void RB_StageIteratorLightmappedMultitexture(void) {}
void R_DecomposeSort(unsigned sort, int *entityNum, shader_t **shader, int *fogNum, int *dlightMap) {}

image_t *R_FindImageFile(const char *name, qboolean mipmap, qboolean allowPicmip, int glWrapClampMode) {
	int i;
	/* the images whose name begins with "nofile" do not exist (the remap scenario of R_RemapShader) */
	if (!strncmp(name, "nofile", 6)) return NULL;
	for (i = 0; i < g_numImages; i++)
		if (!strcmp(g_images[i].imgName, name)) return &g_images[i];
	strncpy(g_images[g_numImages].imgName, name, MAX_QPATH - 1);
	return &g_images[g_numImages++];
}

void QDECL Com_Printf(const char *fmt, ...) {}
void QDECL Com_Error(int level, const char *fmt, ...) { printf("com_error\n"); exit(2); }
void Com_Memset(void *dest, const int val, const size_t count) { memset(dest, val, count); }
void Com_Memcpy(void *dest, const void *src, const size_t count) { memcpy(dest, src, count); }

vec_t VectorNormalize(vec3_t v) {
	float length, ilength;
	length = v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
	length = sqrt(length);
	if (length) {
		ilength = 1 / length;
		v[0] *= ilength;
		v[1] *= ilength;
		v[2] *= ilength;
	}
	return length;
}

static void QDECL RI_Printf(int level, const char *fmt, ...) {
	char buf[4096];
	va_list ap;
	int n;
	va_start(ap, fmt);
	vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	if (level != PRINT_WARNING) return;
	n = (int)strlen(buf);
	while (n > 0 && (buf[n - 1] == '\n')) buf[--n] = 0;
	printf("log %s\n", strncmp(buf, "WARNING: ", 9) ? buf : buf + 9);
}

static void QDECL RI_Error(int level, const char *fmt, ...) {
	char buf[4096];
	va_list ap;
	int n;
	va_start(ap, fmt);
	vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	n = (int)strlen(buf);
	while (n > 0 && (buf[n - 1] == '\n')) buf[--n] = 0;
	printf("log %s\n", buf);
	longjmp(g_drop, 1);
}

static void *RI_HunkAlloc(int size, ha_pref pref) { return calloc(1, size); }

static int cmpnames(const void *a, const void *b) { return Q_stricmp(*(char **)a, *(char **)b); }

static char **RI_ListFiles(const char *name, const char *extension, int *num) {
	char path[1024];
	DIR *d;
	struct dirent *e;
	char **list = calloc(256, sizeof(char *));
	int n = 0, len, elen = (int)strlen(extension);
	snprintf(path, sizeof(path), "%s/%s", g_root, name);
	d = opendir(path);
	if (d) {
		while ((e = readdir(d)) != NULL) {
			len = (int)strlen(e->d_name);
			if (len > elen && !strcmp(e->d_name + len - elen, extension)) list[n++] = strdup(e->d_name);
		}
		closedir(d);
	}
	qsort(list, n, sizeof(char *), cmpnames);
	*num = n;
	return list;
}

static int RI_ReadFile(const char *name, void **buf) {
	char path[1024];
	FILE *f;
	int len;
	char *b;
	snprintf(path, sizeof(path), "%s/%s", g_root, name);
	f = fopen(path, "rb");
	if (!f) { *buf = NULL; return -1; }
	fseek(f, 0, SEEK_END);
	len = (int)ftell(f);
	fseek(f, 0, SEEK_SET);
	b = malloc(len + 1);
	fread(b, 1, len, f);
	b[len] = 0;
	fclose(f);
	*buf = b;
	return len;
}
static void RI_FreeFile(void *buf) { free(buf); }
static void RI_FreeFileList(char **list) {}
static int RI_CinPlay(const char *arg0, int x, int y, int w, int h, int bits) { return 0; }

static void bits(float f) {
	unsigned u;
	memcpy(&u, &f, 4);
	printf(" %08x", u);
}

static void wave(const waveForm_t *w) {
	printf(" w%d", (int)w->func);
	bits(w->base); bits(w->amplitude); bits(w->phase); bits(w->frequency);
}

static void dump(const shader_t *s, int sunSet) {
	int i, k, m;
	printf("shader %s\n", s->name);
	printf("head sort"); bits(s->sort);
	printf(" default=%d explicit=%d surf=%x cont=%x merge=%d sky=%d cull=%d poff=%d nomip=%d nopic=%d fogpass=%d passes=%d\n",
		s->defaultShader, s->explicitlyDefined, s->surfaceFlags, (unsigned)s->contentFlags, s->entityMergable, s->isSky,
		(int)s->cullType, s->polygonOffset, s->noMipMaps, s->noPicMip, (int)s->fogPass, s->numUnfoggedPasses);
	printf("misc portal"); bits(s->portalRange); printf(" clamp"); bits(s->clampTime); printf("\n");
	printf("fog"); bits(s->fogParms.color[0]); bits(s->fogParms.color[1]); bits(s->fogParms.color[2]);
	bits(s->fogParms.depthForOpaque); printf("\n");
	printf("sky"); bits(s->sky.cloudHeight);
	for (i = 0; i < 6; i++) printf(" %s", s->sky.outerbox[i] ? s->sky.outerbox[i]->imgName : "-");
	for (i = 0; i < 6; i++) printf(" %s", s->sky.innerbox[i] ? s->sky.innerbox[i]->imgName : "-");
	printf("\n");
	if (sunSet) {
		printf("sun"); bits(tr.sunLight[0]); bits(tr.sunLight[1]); bits(tr.sunLight[2]);
		bits(tr.sunDirection[0]); bits(tr.sunDirection[1]); bits(tr.sunDirection[2]); printf("\n");
	}
	printf("deforms %d\n", s->numDeforms);
	for (i = 0; i < MAX_SHADER_DEFORMS && i < s->numDeforms; i++) {
		const deformStage_t *d = &s->deforms[i];
		printf("deform %d type=%d move", i, (int)d->deformation);
		bits(d->moveVector[0]); bits(d->moveVector[1]); bits(d->moveVector[2]);
		wave(&d->deformationWave); printf(" spread"); bits(d->deformationSpread);
		printf(" bulge"); bits(d->bulgeWidth); bits(d->bulgeHeight); bits(d->bulgeSpeed); printf("\n");
	}
	for (i = 0; i < s->numUnfoggedPasses && s->stages[i]; i++) {
		const shaderStage_t *st = s->stages[i];
		const textureBundle_t *b = &st->bundle[0];
		printf("stage %d detail=%d rgb=%d alpha=%d state=%x acff=%d const=%d,%d,%d,%d\n", i, st->isDetail,
			(int)st->rgbGen, (int)st->alphaGen, st->stateBits, (int)st->adjustColorsForFog, st->constantColor[0],
			st->constantColor[1], st->constantColor[2], st->constantColor[3]);
		printf(" rgbwave"); wave(&st->rgbWave); printf(" alphawave"); wave(&st->alphaWave); printf("\n");
		printf(" bundle tcgen=%d lightmap=%d video=%d anims=%d speed", (int)b->tcGen, b->isLightmap, b->isVideoMap,
			b->numImageAnimations);
		bits(b->imageAnimationSpeed);
		printf(" images");
		for (k = 0; k < (b->numImageAnimations > 0 ? b->numImageAnimations : 1); k++)
			printf(" %s", b->isLightmap ? "$lightmap" : (b->image[k] ? b->image[k]->imgName : "-"));
		printf("\n");
		printf(" tcvec"); for (k = 0; k < 6; k++) bits(b->tcGenVectors[k / 3][k % 3]); printf("\n");
		printf(" texmods %d\n", b->numTexMods);
		for (k = 0; k < b->numTexMods; k++) {
			const texModInfo_t *t = &b->texMods[k];
			printf("  mod %d type=%d", k, (int)t->type);
			wave(&t->wave);
			for (m = 0; m < 4; m++) bits(t->matrix[m / 2][m % 2]);
			bits(t->translate[0]); bits(t->translate[1]); bits(t->scale[0]); bits(t->scale[1]);
			bits(t->scroll[0]); bits(t->scroll[1]); bits(t->rotateSpeed);
			printf("\n");
		}
	}
}

static void find(const char *name) {
	shader_t *sh;
	tr.sunLight[0] = -12345.0f;
	/* the original keeps the texMods of the previous shader (it clears the stages, not these): the
	   harness clears them, a reading of one shader must not depend on the ones before it */
	memset(texMods, 0, sizeof(texMods));
	printf("find %s\n", name);
	if (setjmp(g_drop) == 0) {
		sh = R_FindShader(name, LIGHTMAP_NONE, qtrue);
		dump(sh, tr.sunLight[0] != -12345.0f);
	} else {
		printf("drop\n");
	}
}

int main(int argc, char **argv) {
	char line[1024];
	FILE *f;
	if (argc < 3) return 1;
	strncpy(g_root, argv[1], sizeof(g_root) - 1);
	f = fopen(argv[2], "r");
	if (!f) return 1;
	ri.Printf = RI_Printf;
	ri.Error = RI_Error;
	ri.Hunk_Alloc = RI_HunkAlloc;
	ri.FS_ListFiles = RI_ListFiles;
	ri.FS_ReadFile = RI_ReadFile;
	ri.FS_FreeFile = RI_FreeFile;
	ri.FS_FreeFileList = RI_FreeFileList;
	ri.CIN_PlayCinematic = RI_CinPlay;
	backEndData[0] = calloc(1, sizeof(backEndData_t));
	strcpy(g_white.imgName, "$whiteimage");
	strcpy(g_scratch.imgName, "$scratch");
	tr.whiteImage = &g_white;
	tr.scratchImage[0] = &g_scratch;
	tr.defaultImage = &g_white;
	cv_detail.integer = 1;
	while (fgets(line, sizeof(line), f)) {
		int n = (int)strlen(line);
		while (n > 0 && (line[n - 1] == '\n' || line[n - 1] == '\r')) line[--n] = 0;
		if (!strncmp(line, "detail ", 7)) cv_detail.integer = atoi(line + 7);
		else if (!strcmp(line, "scan")) ScanAndLoadShaderFiles();
		else if (!strcmp(line, "internal")) {
			/* CreateInternalShaders: "<default>" is index 0, "<stencil shadow>" index 1 */
			memset(hashTable, 0, sizeof(hashTable));
			CreateInternalShaders();
		}
		else if (!strncmp(line, "reg ", 4)) {
			/* reg <name> <lightmap index>: RE_RegisterShaderLightMap */
			char name[256];
			int lm, h;
			if (sscanf(line + 4, "%255s %d", name, &lm) == 2) {
				if (setjmp(g_drop) == 0) {
					h = RE_RegisterShaderLightMap(name, lm);
					printf("reg %s %d -> %d\n", name, lm, h);
				} else printf("drop\n");
			}
		}
		else if (!strncmp(line, "remap ", 6)) {
			/* remap <name> <new name> [<time offset> | -]: R_RemapShader */
			char a[256], b[256], c[256];
			int n = sscanf(line + 6, "%255s %255s %255s", a, b, c);
			printf("remap %s %s %s\n", a, b, n == 3 ? c : "-");
			if (setjmp(g_drop) == 0) R_RemapShader(a, b, (n == 3 && strcmp(c, "-")) ? c : NULL);
			else printf("drop\n");
		}
		else if (!strcmp(line, "remapdump")) {
			int i;
			for (i = 0; i < tr.numShaders; i++) {
				shader_t *s = tr.shaders[i];
				printf("shader %d %s lm=%d default=%d remap=%d", i, s->name, s->lightmapIndex, s->defaultShader,
					s->remappedShader ? s->remappedShader->index : -1);
				bits(s->timeOffset);
				printf("\n");
			}
		}
		else if (!strncmp(line, "find ", 5)) find(line + 5);
		else if (!strcmp(line, "findall")) {
			/* every name of the scanned text, in the order of the text (a local check on real files) */
			char *p = s_shaderText, *token;
			char **names = calloc(65536, sizeof(char *));
			int count = 0, i;
			while (p) {
				token = COM_ParseExt(&p, qtrue);
				if (!token[0]) break;
				names[count++] = strdup(token);
				SkipBracedSection(&p);
			}
			for (i = 0; i < count; i++) find(names[i]);
		}
	}
	return 0;
}
