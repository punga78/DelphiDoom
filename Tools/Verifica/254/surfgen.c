/*
 * surfgen.c - the REAL surface functions of the renderer of Quake III (issue #254, renderer phase R1b).
 *
 * build-surf.sh compiles renderer/tr_surface.c (RB_SurfaceGrid with LodErrorForVolume, RB_SurfacePolychain,
 * RB_SurfaceSprite through RB_AddQuadStamp, RB_SurfaceBeam, the rail and the lightning surfaces, RB_SurfaceMesh with
 * LerpMeshVertexes) and renderer/tr_curve.c (R_SubdividePatchToGrid) as they are, includes renderer/tr_bsp.c (ParseMesh,
 * R_StitchAllPatches, R_FixSharedVertexLodError, so the grids of a real map are the stitched ones the game makes) and
 * runs the commands of a text file (Tests/Data/Q3Render/surf.cases.txt). The rest of the renderer is the stubs of this
 * file: tess and backEnd are plain memory, RB_BeginSurface and RB_EndSurface only keep and print what the surface
 * functions put in tess.
 *
 * Output, per command: "case <line number>" then one "batch" line for every flush of tess (the numbers of vertexes
 * and indexes, the dlight bits and the FNV-1a of the positions, normals, texture coordinates, colours and indexes,
 * floats as their bits); beams print the GL calls they make (they draw straight with qglBegin).
 *
 * Licensed under the GNU General Public License, version 2 or later (it includes code of the Quake III Arena GPL
 * Source Code, id Software).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "tr_local.h"

/* the stubs the renderer files need */
glconfig_t glConfig;
shaderCommands_t tess;
trGlobals_t tr;
backEndState_t backEnd;
glstate_t glState;
refimport_t ri;

#define CV(name) static cvar_t cv_##name; cvar_t *name = &cv_##name
CV(r_lodCurveError); CV(r_subdivisions); CV(r_railWidth); CV(r_railCoreWidth); CV(r_railSegmentLength);
CV(r_mapOverBrightBits); CV(r_vertexLight); CV(r_fullbright); CV(r_singleShader); CV(r_lightmap);
CV(r_ambientScale); CV(r_directedScale); CV(r_debugLight); CV(r_drawSun); CV(r_fastsky); CV(r_flareFade);
CV(r_flareSize); CV(r_flares); CV(r_lodbias); CV(r_lodscale); CV(r_shadows); CV(r_showsky);

static void *ri_malloc(int n) { return malloc(n); }
static void *ri_hunk(int n, ha_pref p) { return malloc(n); }
static void ri_printf(int level, const char *fmt, ...) {}
static void ri_error(int level, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	vfprintf(stderr, fmt, args);
	va_end(args);
	exit(2);
}
void Com_Error(int level, const char *fmt, ...) { va_list a; va_start(a, fmt); vfprintf(stderr, fmt, a); va_end(a); exit(2); }
void Com_Printf(const char *fmt, ...) {}
void Com_Memset(void *dest, const int val, const size_t count) { memset(dest, val, count); }
void Com_Memcpy(void *dest, const void *src, const size_t count) { memcpy(dest, src, count); }

/* what tr_surface.c, tr_curve.c and tr_bsp.c ask of the rest of the renderer */
void R_SyncRenderThread(void) {}
image_t *R_CreateImage(const char *name, const byte *pic, int width, int height, qboolean mipmap, qboolean allowPicmip, int glWrapClampMode) { return NULL; }
void R_RemapShader(const char *oldShader, const char *newShader, const char *timeOffset) {}
model_t *R_AllocModel(void) { return NULL; }
static shader_t g_shaders[2];
shader_t *R_FindShader(const char *name, int lightmapIndex, qboolean mipRawImage) { return &g_shaders[0]; }
void R_AddDrawSurf(surfaceType_t *surface, shader_t *shader, int fogIndex, int dlightMap) {}
static void dump_batch(void);
void RB_StageIteratorGeneric(void) { printf("generic\n"); dump_batch(); }
long myftol(float f) { return (long)f; }
/* Q_acos of qcommon/common.c, as it is (that file is the whole engine and is not linked) */
float Q_acos(float c) {
	float angle;
	angle = acos(c);
	if (angle > M_PI) {
		return (float)M_PI;
	}
	if (angle < -M_PI) {
		return (float)M_PI;
	}
	return angle;
}
shader_t *R_GetShaderByHandle(qhandle_t hShader) { return &g_shaders[0]; }
skin_t *R_GetSkinByHandle(qhandle_t hSkin) { return NULL; }
void R_SetupEntityLighting(const trRefdef_t *refdef, trRefEntity_t *ent) {}
void R_TransformModelToClip(const vec3_t src, const float *modelMatrix, const float *projectionMatrix, vec4_t eye, vec4_t dst) {}
void R_TransformClipToWindow(const vec4_t clip, const viewParms_t *view, vec4_t normalized, vec4_t window) {}
int R_CullLocalBox(vec3_t bounds[2]) { return 0; }
int R_CullLocalPointAndRadius(vec3_t pt, float radius) { return 0; }
void GL_Bind(image_t *image) { if (image) printf("gl bind %d\n", image->texnum); else printf("gl bind\n"); }
void GL_State(unsigned long stateBits) { printf("gl state %08lx\n", stateBits); }
void RB_SurfaceAnim(md4Surface_t *surfType) {}
void (APIENTRY *qglBegin)(GLenum mode);
void (APIENTRY *qglCallList)(GLuint list);
void (APIENTRY *qglColor3f)(GLfloat red, GLfloat green, GLfloat blue);
void (APIENTRY *qglDepthRange)(GLclampd zNear, GLclampd zFar);
void (APIENTRY *qglDisable)(GLenum cap);
void (APIENTRY *qglEnd)(void);
void (APIENTRY *qglLineWidth)(GLfloat width);
void (APIENTRY *qglLoadIdentity)(void);
void (APIENTRY *qglLoadMatrixf)(const GLfloat *m);
void (APIENTRY *qglMatrixMode)(GLenum mode);
void (APIENTRY *qglOrtho)(GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble zNear, GLdouble zFar);
void (APIENTRY *qglPopMatrix)(void);
void (APIENTRY *qglPushMatrix)(void);
void (APIENTRY *qglReadPixels)(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid *pixels);
void (APIENTRY *qglTexCoord2fv)(const GLfloat *v);
void (APIENTRY *qglTranslatef)(GLfloat x, GLfloat y, GLfloat z);
void (APIENTRY *qglVertex3f)(GLfloat x, GLfloat y, GLfloat z);
void (APIENTRY *qglVertex3fv)(const GLfloat *v);

static unsigned bits(float f) { union { float f; unsigned u; } c; c.f = f; return c.u; }
/* the payload of a NaN depends on the instruction that made it (x87 or SSE): all NaNs are one value */
static unsigned cbits(float f) { return f != f ? 0x7fc00000u : bits(f); }
static unsigned fnv_byte(unsigned h, unsigned b) { return (h ^ (b & 255)) * 16777619u; }
static unsigned fnv_u32(unsigned h, unsigned v) { int i; for (i = 0; i < 4; i++) h = fnv_byte(h, v >> (8 * i)); return h; }

static void APIENTRY sh_begin(GLenum mode) { printf("gl begin %x\n", mode); }
static void APIENTRY sh_end(void) { printf("gl end\n"); }
static void APIENTRY sh_color3f(GLfloat r, GLfloat g, GLfloat b) { printf("gl color3f %08x %08x %08x\n", bits(r), bits(g), bits(b)); }
static int g_quiet; static unsigned g_qhash = 2166136261u; static int g_qcount;
static unsigned qfeed(unsigned h, unsigned v) { int i; for (i = 0; i < 4; i++) h = (h ^ ((v >> (8 * i)) & 255)) * 16777619u; return h; }
static void APIENTRY sh_vertex3fv(const GLfloat *v) { if (g_quiet) { g_qhash = qfeed(qfeed(qfeed(g_qhash, bits(v[0])), bits(v[1])), bits(v[2])); g_qcount++; return; } printf("gl vertex3fv %08x %08x %08x\n", bits(v[0]), bits(v[1]), bits(v[2])); }
static void APIENTRY sh_push(void) { printf("gl pushmatrix\n"); }
static void APIENTRY sh_pop(void) { printf("gl popmatrix\n"); }
static void APIENTRY sh_translate(GLfloat x, GLfloat y, GLfloat z) { printf("gl translatef %08x %08x %08x\n", bits(x), bits(y), bits(z)); }
static void APIENTRY sh_texcoord2fv(const GLfloat *v) { if (g_quiet) { g_qhash = qfeed(qfeed(g_qhash, bits(v[0])), bits(v[1])); g_qcount++; return; } printf("gl texcoord2fv %08x %08x\n", bits(v[0]), bits(v[1])); }
static void APIENTRY sh_depthrange(GLclampd a, GLclampd b) { printf("gl depthrange %g %g\n", (double)a, (double)b); }
static void APIENTRY sh_loadmatrix(const GLfloat *m) { printf("gl loadmatrixf\n"); }

/* the batch of tess, as it would go to the stage iterators */
static void dump_batch(void) {
	unsigned hx = 2166136261u, hn = 2166136261u, ht = 2166136261u, hc = 2166136261u, hi = 2166136261u;
	int i, k;
	for (i = 0; i < tess.numVertexes; i++) {
		for (k = 0; k < 3; k++) hx = fnv_u32(hx, cbits(tess.xyz[i][k]));
		for (k = 0; k < 3; k++) hn = fnv_u32(hn, cbits(tess.normal[i][k]));
		for (k = 0; k < 2; k++) { ht = fnv_u32(ht, cbits(tess.texCoords[i][0][k])); }
		for (k = 0; k < 2; k++) { ht = fnv_u32(ht, cbits(tess.texCoords[i][1][k])); }
		for (k = 0; k < 4; k++) hc = fnv_byte(hc, tess.vertexColors[i][k]);
	}
	for (i = 0; i < tess.numIndexes; i++) hi = fnv_u32(hi, (unsigned)tess.indexes[i]);
	printf("batch %d %d %x %08x %08x %08x %08x %08x\n", tess.numVertexes, tess.numIndexes, tess.dlightBits, hx, hn, ht,
		hc, hi);
}

void RB_BeginSurface(shader_t *shader, int fogNum) {
	tess.numIndexes = 0;
	tess.numVertexes = 0;
	tess.shader = shader;
	tess.fogNum = fogNum;
	tess.dlightBits = 0;
}

void RB_EndSurface(void) {
	if (tess.numIndexes == 0) return;
	dump_batch();
	tess.numIndexes = 0;
	tess.numVertexes = 0;
}

#include "tr_bsp.c"
/* the whole sky file: its statics (the clip of the polygons, the boxes, the cloud tables) are read below */
#include "tr_sky.c"

static void set_axis(float axis[3][3], const float *angles) { AngleVectors(angles, axis[0], axis[1], axis[2]); }
static void reset_tess(int needsNormal) {
	memset(&tess, 0, sizeof(tess));
	g_shaders[0].needsNormal = needsNormal;
	RB_BeginSurface(&g_shaders[0], 0);
}

/* the cases: patches built from formulas (the same ones are in the Delphi test) */
static drawVert_t g_points[MAX_PATCH_SIZE * MAX_PATCH_SIZE];

static void make_points(int w, int h, int bulge) {
	int i, j;
	for (j = 0; j < h; j++) {
		for (i = 0; i < w; i++) {
			drawVert_t *dv = &g_points[j * w + i];
			int di = i - w / 2, dj = j - h / 2;
			memset(dv, 0, sizeof(*dv));
			dv->xyz[0] = (float)(i * 40 + ((i * 13 + j * 7) % 9) - 4);
			dv->xyz[1] = (float)(j * 40 + ((i * 5 + j * 11) % 7) - 3);
			dv->xyz[2] = (float)(bulge - (di * di + dj * dj) * bulge / 8 + ((i * 3 + j * 17) % 5));
			dv->st[0] = (float)i / (float)(w - 1);
			dv->st[1] = (float)j / (float)(h - 1);
			dv->lightmap[0] = (float)(i * 2) / 32.0f;
			dv->lightmap[1] = (float)(j * 2) / 32.0f;
			dv->normal[0] = 0; dv->normal[1] = 0; dv->normal[2] = 1;
			dv->color[0] = (byte)(i * 31 + j * 7); dv->color[1] = (byte)(i * 11 + j * 29);
			dv->color[2] = (byte)(i * 5 + j * 3); dv->color[3] = 255;
		}
	}
}

static trRefEntity_t g_entity;

static void draw_poly(int n) {
	static polyVert_t verts[64];
	srfPoly_t p;
	int i;
	for (i = 0; i < n; i++) {
		verts[i].xyz[0] = (float)(i * 8 + 3); verts[i].xyz[1] = (float)((i * 5) % 11 - 5); verts[i].xyz[2] = (float)(i % 3 * 4);
		verts[i].st[0] = (float)i / 8.0f; verts[i].st[1] = (float)(n - i) / 16.0f;
		verts[i].modulate[0] = (byte)(i * 9); verts[i].modulate[1] = (byte)(255 - i * 3);
		verts[i].modulate[2] = (byte)(i * 17); verts[i].modulate[3] = (byte)(200 + i % 50);
	}
	p.surfaceType = SF_POLY; p.hShader = 0; p.fogIndex = 0; p.numVerts = n; p.verts = verts;
	rb_surfaceTable[SF_POLY](&p);
}

static byte *make_md3_surface(int numVerts, int numTris, int numFrames, int seed) {
	int size = sizeof(md3Surface_t) + numTris * 12 + numVerts * 8 + numVerts * numFrames * 8;
	byte *buf = calloc(1, size);
	md3Surface_t *s = (md3Surface_t *)buf;
	int *tri;
	float *st;
	short *xn;
	int i, f;
	s->numFrames = numFrames; s->numVerts = numVerts; s->numTriangles = numTris;
	s->ofsTriangles = sizeof(md3Surface_t);
	s->ofsSt = s->ofsTriangles + numTris * 12;
	s->ofsXyzNormals = s->ofsSt + numVerts * 8;
	s->ofsEnd = size;
	tri = (int *)(buf + s->ofsTriangles);
	for (i = 0; i < numTris; i++) { tri[i * 3] = (i * 3 + seed) % numVerts; tri[i * 3 + 1] = (i * 5 + 1) % numVerts; tri[i * 3 + 2] = (i * 7 + 2) % numVerts; }
	st = (float *)(buf + s->ofsSt);
	for (i = 0; i < numVerts; i++) { st[i * 2] = (float)(i % 17) / 16.0f; st[i * 2 + 1] = (float)(i % 13) / 12.0f; }
	xn = (short *)(buf + s->ofsXyzNormals);
	for (f = 0; f < numFrames; f++) {
		for (i = 0; i < numVerts; i++) {
			short *v = xn + (f * numVerts + i) * 4;
			int lat = (i * 7 + f * 3 + seed) & 255, lng = (i * 13 + f * 5) & 255;
			v[0] = (short)(((i * 37 + f * 11 + seed) % 2001) - 1000);
			v[1] = (short)(((i * 53 + f * 7) % 2001) - 1000);
			v[2] = (short)(((i * 29 + f * 19) % 1601) - 800);
			v[3] = (short)((lat << 8) | lng);
		}
	}
	return buf;
}

static void run_entity(int reType, const float *origin, const float *oldorigin, float radius, float rotation, const int *rgba) {
	int i;
	memset(&g_entity, 0, sizeof(g_entity));
	g_entity.e.reType = reType;
	for (i = 0; i < 3; i++) { g_entity.e.origin[i] = origin[i]; g_entity.e.oldorigin[i] = oldorigin[i]; }
	g_entity.e.radius = radius; g_entity.e.rotation = rotation;
	for (i = 0; i < 4; i++) g_entity.e.shaderRGBA[i] = (byte)rgba[i];
	backEnd.currentEntity = &g_entity;
	rb_surfaceTable[SF_ENTITY](NULL);
}

static void run_mesh_bytes(byte *surf, int frame, int oldframe, float backlerp) {
	memset(&g_entity, 0, sizeof(g_entity));
	g_entity.e.frame = frame; g_entity.e.oldframe = oldframe; g_entity.e.backlerp = backlerp;
	backEnd.currentEntity = &g_entity;
	rb_surfaceTable[SF_MD3](surf);
}

static unsigned char *g_file;
static int g_lump_ofs(int n) { return ((int *)(g_file + 8))[n * 2]; }
static int g_lump_len(int n) { return ((int *)(g_file + 8))[n * 2 + 1]; }

static void load_map(const char *path) {
	FILE *f = fopen(path, "rb");
	long size;
	int i, count;
	dsurface_t *ds;
	drawVert_t *dv;
	if (!f) { fprintf(stderr, "no file %s\n", path); exit(1); }
	fseek(f, 0, SEEK_END); size = ftell(f); fseek(f, 0, SEEK_SET);
	g_file = malloc(size);
	fread(g_file, 1, size, f);
	fclose(f);
	s_worldData.numShaders = g_lump_len(LUMP_SHADERS) / sizeof(dshader_t);
	s_worldData.shaders = (dshader_t *)(g_file + g_lump_ofs(LUMP_SHADERS));
	count = g_lump_len(LUMP_SURFACES) / sizeof(dsurface_t);
	ds = (dsurface_t *)(g_file + g_lump_ofs(LUMP_SURFACES));
	dv = (drawVert_t *)(g_file + g_lump_ofs(LUMP_DRAWVERTS));
	s_worldData.numsurfaces = count;
	s_worldData.surfaces = calloc(count, sizeof(msurface_t));
	for (i = 0; i < count; i++) {
		static surfaceType_t skip = SF_SKIP;
		s_worldData.surfaces[i].data = &skip;
		if (ds[i].surfaceType == MST_PATCH) {
			ParseMesh(&ds[i], dv, &s_worldData.surfaces[i]);
		}
	}
	R_StitchAllPatches();
	R_FixSharedVertexLodError();
}

static void draw_map_grids(void) {
	int i;
	for (i = 0; i < s_worldData.numsurfaces; i++) {
		srfGridMesh_t *g = (srfGridMesh_t *)s_worldData.surfaces[i].data;
		if (g->surfaceType != SF_GRID) continue;
		g->dlightBits[0] = (int)(((unsigned)i * 2654435761u) >> 16) & 0xFFFF;
		reset_tess(i & 1);
		printf("surface %d %d %d %08x %08x %08x %08x\n", i, g->width, g->height, bits(g->lodOrigin[0]),
			bits(g->lodOrigin[1]), bits(g->lodOrigin[2]), bits(g->lodRadius));
		rb_surfaceTable[SF_GRID](g);
		RB_EndSurface();
		if (getenv("SURFGEN_DUMP") && atoi(getenv("SURFGEN_DUMP")) == i) {
			int k, n = g->width * g->height;
			for (k = 0; k < n; k++) {
				fprintf(stderr, "v %d %08x %08x %08x %08x %08x\n", k, bits(g->verts[k].st[0]), bits(g->verts[k].st[1]),
					bits(g->verts[k].lightmap[0]), bits(g->verts[k].lightmap[1]), bits(g->verts[k].xyz[0]));
			}
		}
	}
}

int main(int argc, char **argv) {
	FILE *cases;
	char line[1024];
	int number = 0, i;
	ri.Printf = ri_printf;
	ri.Error = (void (*)(int, const char *, ...))ri_error;
	ri.Malloc = ri_malloc;
	ri.Hunk_Alloc = ri_hunk;
	qglBegin = sh_begin; qglEnd = sh_end; qglColor3f = sh_color3f; qglVertex3fv = sh_vertex3fv;
	qglPushMatrix = sh_push; qglPopMatrix = sh_pop; qglTranslatef = sh_translate; qglTexCoord2fv = sh_texcoord2fv;
	qglDepthRange = sh_depthrange; qglLoadMatrixf = sh_loadmatrix;
	for (i = 0; i < FUNCTABLE_SIZE; i++) {
		tr.sinTable[i] = sin(DEG2RAD(i * 360.0f / ((float)(FUNCTABLE_SIZE - 1))));
	}
	/* the defaults of the cvars of tr_init.c */
	r_lodCurveError->value = 250; r_subdivisions->value = 4; r_subdivisions->integer = 4;
	r_railWidth->integer = 16; r_railCoreWidth->integer = 6; r_railSegmentLength->value = 32;
	r_mapOverBrightBits->integer = 2; tr.overbrightBits = 1;
	if (argc < 2) { fprintf(stderr, "surfgen <cases.txt> [map.bsp]\n"); return 1; }
	if (argc > 2) load_map(argv[2]);
	cases = fopen(argv[1], "r");
	if (!cases) { fprintf(stderr, "no cases\n"); return 1; }
	while (fgets(line, sizeof(line), cases)) {
		float a[16];
		int n[16];
		char word[32];
		number++;
		if (line[0] == '#' || line[0] == '\n' || line[0] == '\r') continue;
		if (sscanf(line, "%31s", word) < 1) continue;
		if (!strcmp(word, "lod")) { sscanf(line, "lod %f", &a[0]); r_lodCurveError->value = a[0]; continue; }
		if (!strcmp(word, "subdiv")) { sscanf(line, "subdiv %d", &n[0]); r_subdivisions->value = (float)n[0]; r_subdivisions->integer = n[0]; continue; }
		if (!strcmp(word, "rail")) {
			sscanf(line, "rail %d %d %f", &n[0], &n[1], &a[0]);
			r_railWidth->integer = n[0]; r_railCoreWidth->integer = n[1]; r_railSegmentLength->value = a[0]; continue;
		}
		if (!strcmp(word, "view")) {
			float ang[3];
			sscanf(line, "view %f %f %f %f %f %f %d", &backEnd.viewParms.or.origin[0], &backEnd.viewParms.or.origin[1],
				&backEnd.viewParms.or.origin[2], &ang[0], &ang[1], &ang[2], &n[0]);
			set_axis(backEnd.viewParms.or.axis, ang);
			backEnd.viewParms.isMirror = n[0];
			continue;
		}
		if (!strcmp(word, "or")) {
			float ang[3];
			sscanf(line, "or %f %f %f %f %f %f", &backEnd.or.origin[0], &backEnd.or.origin[1], &backEnd.or.origin[2],
				&ang[0], &ang[1], &ang[2]);
			set_axis(backEnd.or.axis, ang);
			continue;
		}
		printf("case %d\n", number);
		if (!strcmp(word, "grid")) {
			int w, h, bulge, dl, normal;
			float lod[4];
			srfGridMesh_t *g;
			sscanf(line, "grid %d %d %d %d %d %f %f %f %f", &w, &h, &bulge, &dl, &normal, &lod[0], &lod[1], &lod[2], &lod[3]);
			make_points(w, h, bulge);
			g = R_SubdividePatchToGrid(w, h, g_points);
			g->lodOrigin[0] = lod[0]; g->lodOrigin[1] = lod[1]; g->lodOrigin[2] = lod[2]; g->lodRadius = lod[3];
			g->dlightBits[0] = dl;
			printf("grid %d %d\n", g->width, g->height);
			reset_tess(normal);
			rb_surfaceTable[SF_GRID](g);
			RB_EndSurface();
		} else if (!strcmp(word, "mapgrids")) {
			draw_map_grids();
		} else if (!strcmp(word, "poly")) {
			int count, polys;
			sscanf(line, "poly %d %d", &count, &polys);
			reset_tess(0);
			while (polys-- > 0) draw_poly(count);
			RB_EndSurface();
		} else if (!strcmp(word, "sprite") || !strcmp(word, "beam") || !strcmp(word, "railcore") ||
			!strcmp(word, "railrings") || !strcmp(word, "lightning")) {
			float o[3], oo[3], radius, rot;
			int rgba[4], type = !strcmp(word, "sprite") ? RT_SPRITE : !strcmp(word, "beam") ? RT_BEAM :
				!strcmp(word, "railcore") ? RT_RAIL_CORE : !strcmp(word, "railrings") ? RT_RAIL_RINGS : RT_LIGHTNING;
			sscanf(line, "%*s %f %f %f %f %f %f %f %f %d %d %d %d", &o[0], &o[1], &o[2], &oo[0], &oo[1], &oo[2], &radius,
				&rot, &rgba[0], &rgba[1], &rgba[2], &rgba[3]);
			reset_tess(0);
			run_entity(type, o, oo, radius, rot, rgba);
			RB_EndSurface();
		} else if (!strcmp(word, "skyinit")) {
			unsigned h1 = 2166136261u, h2 = 2166136261u;
			int i2, t2, s2;
			sscanf(line, "skyinit %f", &a[0]);
			R_InitSkyTexCoords(a[0]);
			for (i2 = 0; i2 < 6; i2++) for (t2 = 0; t2 <= SKY_SUBDIVISIONS; t2++) for (s2 = 0; s2 <= SKY_SUBDIVISIONS; s2++) {
				h1 = fnv_u32(h1, cbits(s_cloudTexCoords[i2][t2][s2][0]));
				h1 = fnv_u32(h1, cbits(s_cloudTexCoords[i2][t2][s2][1]));
				h2 = fnv_u32(h2, cbits(s_cloudTexP[i2][t2][s2]));
			}
			printf("cloud %08x %08x\n", h1, h2);
			/* a few of the numbers themselves */
			printf("cloudsample %08x %08x %08x %08x\n", bits(s_cloudTexCoords[4][4][4][0]), bits(s_cloudTexCoords[4][4][4][1]),
				bits(s_cloudTexCoords[0][2][7][0]), bits(s_cloudTexP[0][2][7]));
		} else if (!strcmp(word, "sky")) {
			static image_t images[12], defaultImage;
			static shader_t skyShader;
			static shaderStage_t stages[MAX_SHADER_STAGES];
			static shaderStage_t *stagePointers[MAX_SHADER_STAGES + 1];
			int outer, numStages, fast, show, count, seed, k, j, i2;
			float identity, zfar, cloud;
			sscanf(line, "sky %d %d %d %d %f %f %f %d %d", &outer, &numStages, &fast, &show, &identity, &zfar, &cloud, &count,
				&seed);
			for (i2 = 0; i2 < 12; i2++) images[i2].texnum = i2 + 1;
			defaultImage.texnum = 99;
			tr.defaultImage = &defaultImage;
			memset(&skyShader, 0, sizeof(skyShader));
			skyShader.isSky = qtrue;
			skyShader.sky.cloudHeight = cloud;
			for (i2 = 0; i2 < 6; i2++) skyShader.sky.outerbox[i2] = outer ? &images[i2] : NULL;
			if (outer == 2) skyShader.sky.outerbox[0] = &defaultImage;
			for (i2 = 0; i2 < numStages; i2++) stagePointers[i2] = &stages[i2];
			stagePointers[numStages] = NULL;
			reset_tess(0);
			tess.shader = &skyShader;
			tess.xstages = stagePointers;
			backEnd.viewParms.zFar = zfar;
			backEnd.skyRenderedThisView = qfalse;
			r_fastsky->integer = fast;
			r_showsky->integer = show;
			tr.identityLight = identity;
			for (k = 0; k < count; k++) {
				for (j = 0; j < 3; j++) {
					float *p = tess.xyz[k * 3 + j];
					p[0] = backEnd.viewParms.or.origin[0] + (float)(((k * 37 + j * 53 + seed) % 201) - 100) * 20;
					p[1] = backEnd.viewParms.or.origin[1] + (float)(((k * 91 + j * 17 + seed * 3) % 201) - 100) * 20;
					p[2] = backEnd.viewParms.or.origin[2] + (float)(((k * 29 + j * 71 + seed * 7) % 201) - 100) * 20;
					tess.indexes[k * 3 + j] = k * 3 + j;
				}
			}
			tess.numVertexes = count * 3;
			tess.numIndexes = count * 3;
			g_quiet = 1; g_qhash = 2166136261u; g_qcount = 0;
			RB_StageIteratorSky();
			g_quiet = 0;
			printf("skyverts %d %08x\n", g_qcount, g_qhash);
			printf("skyrendered %d\n", backEnd.skyRenderedThisView);
			for (i2 = 0; i2 < 6; i2++)
				printf("skyside %d %08x %08x %08x %08x\n", i2, bits(sky_mins[0][i2]), bits(sky_mins[1][i2]), bits(sky_maxs[0][i2]),
					bits(sky_maxs[1][i2]));
			tess.numIndexes = 0;
			tess.numVertexes = 0;
		} else if (!strcmp(word, "sun")) {
			float d[3], zfar2;
			int rendered, draw;
			sscanf(line, "sun %f %f %f %f %d %d", &d[0], &d[1], &d[2], &zfar2, &rendered, &draw);
			tr.sunDirection[0] = d[0]; tr.sunDirection[1] = d[1]; tr.sunDirection[2] = d[2];
			backEnd.skyRenderedThisView = rendered;
			r_drawSun->integer = draw;
			backEnd.viewParms.zFar = zfar2;
			reset_tess(0);
			RB_DrawSun();
			RB_EndSurface();
		} else if (!strcmp(word, "mesh")) {
			int nv, nt, nf, frame, oldframe, seed, repeat;
			float lerp;
			byte *surf;
			sscanf(line, "mesh %d %d %d %d %d %f %d %d", &nv, &nt, &nf, &frame, &oldframe, &lerp, &seed, &repeat);
			surf = make_md3_surface(nv, nt, nf, seed);
			reset_tess(1);
			while (repeat-- > 0) run_mesh_bytes(surf, frame, oldframe, lerp);
			RB_EndSurface();
		} else {
			fprintf(stderr, "unknown command: %s", line);
			return 1;
		}
	}
	return 0;
}
