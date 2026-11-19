/*
 * frontgen.c - the REAL front end of the renderer of Quake III (issue #254, renderer phase R1).
 *
 * build-front.sh compiles renderer/tr_main.c and renderer/tr_world.c of Quake III as they are (with game/q_math.c
 * for BoxOnPlaneSide, SetPlaneSignbits, AngleVectors ...) and this file around them: it loads a .bsp the way
 * R_LoadNodesAndLeafs, R_LoadMarksurfaces, R_LoadVisibility and the ParseFace / ParseTriSurf / ParseFlare of tr_bsp.c
 * do (the nodes, the PVS, the surfaces with the plane of a face and the bounds of a triangle soup; a patch would be
 * a skip surface: oa_dm1 has none), gives every shader of the file a made up culling and sort position, and runs
 * R_RenderView for the views of a text file:
 *
 *     view <ox> <oy> <oz> <yaw> <pitch> <roll> <fovx> <fovy> [dlight <x> <y> <z> <radius>]...
 *
 * The shaders are not the ones of the game: shader k of the file is made like this (the test of the Delphi port does
 * the same with a table of its own): cullType = k % 3, sort = SS_OPAQUE and sortedIndex = (k * 3) % 8 + 1, so that a lot
 * of surfaces have the same key and the order of qsortFast is what the golden shows.
 *
 * Output, per view (floats as the 8 digits of their bits):
 *     view <n> axis <9 values>
 *     frustum <i> <normal x y z> <dist>
 *     proj <16 values>
 *     zfar <value>   visbounds <6 values>
 *     count <numDrawSurfs> leafs <number of the leafs added>
 *     d <sort as 8 digits> <index of the surface>
 *
 * Licensed under the GNU General Public License, version 2 or later (it includes code of the Quake III Arena GPL
 * Source Code, id Software).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "tr_local.h"

#define CONTENTS_NODE_ -1

/* what tr_main.c and tr_world.c need from the rest of the renderer */
glconfig_t glConfig;
shaderCommands_t tess;
void (*rb_surfaceTable[SF_NUM_SURFACE_TYPES])(void *);
void (APIENTRY *qglBegin)(GLenum mode);
void (APIENTRY *qglColor3f)(GLfloat red, GLfloat green, GLfloat blue);
void (APIENTRY *qglDepthRange)(GLclampd zNear, GLclampd zFar);
void (APIENTRY *qglEnd)(void);
void (APIENTRY *qglVertex3fv)(const GLfloat *v);

static cvar_t cv_facePlaneCull, cv_nocull, cv_novis, cv_lockpvs, cv_showcluster, cv_znear, cv_drawworld,
	cv_drawentities, cv_nocurves, cv_noportals, cv_portalOnly, cv_fastsky, cv_debugSurface;
cvar_t *r_facePlaneCull = &cv_facePlaneCull, *r_nocull = &cv_nocull, *r_novis = &cv_novis, *r_lockpvs = &cv_lockpvs,
	*r_showcluster = &cv_showcluster, *r_znear = &cv_znear, *r_drawworld = &cv_drawworld,
	*r_drawentities = &cv_drawentities, *r_nocurves = &cv_nocurves, *r_noportals = &cv_noportals,
	*r_portalOnly = &cv_portalOnly, *r_fastsky = &cv_fastsky, *r_debugSurface = &cv_debugSurface;

void GL_Bind(image_t *image) {}
void GL_State(unsigned long stateVector) {}
void GL_Cull(int cullType) {}
void RB_BeginSurface(shader_t *shader, int fogNum) {}
void R_SyncRenderThread(void) {}
void R_AddDrawSurfCmd(drawSurf_t *drawSurfs, int numDrawSurfs) {}
void R_AddAnimSurfaces(trRefEntity_t *ent) {}
void R_AddMD3Surfaces(trRefEntity_t *ent) {}
void R_AddPolygonSurfaces(void) {}
void R_DlightBmodel(bmodel_t *bmodel) {}
model_t *R_GetModelByHandle(qhandle_t index) { return NULL; }
shader_t *R_GetShaderByHandle(qhandle_t hShader) { return tr.defaultShader; }
void Com_Memset(void *dest, const int val, const size_t count) { memset(dest, val, count); }
void Com_Memcpy(void *dest, const void *src, const size_t count) { memcpy(dest, src, count); }

static void ri_printf(int level, const char *fmt, ...) {}
static void ri_error(int level, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	vfprintf(stderr, fmt, args);
	va_end(args);
	exit(2);
}
void Com_Error(int level, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	vfprintf(stderr, fmt, args);
	va_end(args);
	exit(2);
}
void Com_Printf(const char *fmt, ...) {}
byte *CM_ClusterPVS(int cluster) { return NULL; }

/* the lumps of qfiles.h */
#define L_SHADERS 1
#define L_PLANES 2
#define L_NODES 3
#define L_LEAFS 4
#define L_LEAFSURFACES 5
#define L_FOGS 12
#define L_SURFACES 13
#define L_VISIBILITY 16
#define L_DRAWVERTS 10

static unsigned char *g_file;
static world_t g_world;
static shader_t *g_shaders;
static int g_numShaders;
static int *g_firstOfName;
static msurface_t *g_surfaces;

static int lump_ofs(int n) { return ((int *)(g_file + 8))[n * 2]; }
static int lump_len(int n) { return ((int *)(g_file + 8))[n * 2 + 1]; }
static unsigned bits(float f) { union { float f; unsigned u; } c; c.f = f; return c.u; }

static void set_parent(mnode_t *node, mnode_t *parent) {
	node->parent = parent;
	if (node->contents != CONTENTS_NODE_) {
		return;
	}
	set_parent(node->children[0], node);
	set_parent(node->children[1], node);
}

static void load(const char *path) {
	FILE *f = fopen(path, "rb");
	long size;
	int i, j, count, numDecision, numLeafs;
	if (!f) { fprintf(stderr, "no file %s\n", path); exit(1); }
	fseek(f, 0, SEEK_END); size = ftell(f); fseek(f, 0, SEEK_SET);
	g_file = malloc(size);
	fread(g_file, 1, size, f);
	fclose(f);

	/* planes */
	count = lump_len(L_PLANES) / 16;
	g_world.planes = calloc(count, sizeof(cplane_t));
	for (i = 0; i < count; i++) {
		float *in = (float *)(g_file + lump_ofs(L_PLANES) + i * 16);
		for (j = 0; j < 3; j++) g_world.planes[i].normal[j] = in[j];
		g_world.planes[i].dist = in[3];
		g_world.planes[i].type = PlaneTypeForNormal(g_world.planes[i].normal);
		SetPlaneSignbits(&g_world.planes[i]);
	}

	/* the shaders of the file */
	g_numShaders = lump_len(L_SHADERS) / 72;
	g_shaders = calloc(g_numShaders, sizeof(shader_t));
	g_firstOfName = calloc(g_numShaders, sizeof(int));
	for (i = 0; i < g_numShaders; i++) {
		const char *name = (const char *)(g_file + lump_ofs(L_SHADERS) + i * 72);
		int first = i;
		for (j = 0; j < i; j++) {
			if (!strcmp(name, (const char *)(g_file + lump_ofs(L_SHADERS) + j * 72))) { first = j; break; }
		}
		g_firstOfName[i] = first;
	}
	for (i = 0; i < g_numShaders; i++) {
		g_shaders[i].cullType = i % 3;
		g_shaders[i].sort = SS_OPAQUE;
		g_shaders[i].sortedIndex = (i * 3) % 8 + 1;
	}

	/* surfaces (R_LoadSurfaces: the plane of a face from the third lightmap vector, the bounds of a soup) */
	count = lump_len(L_SURFACES) / 104;
	g_surfaces = calloc(count, sizeof(msurface_t));
	g_world.surfaces = g_surfaces;
	g_world.numsurfaces = count;
	for (i = 0; i < count; i++) {
		int *ds = (int *)(g_file + lump_ofs(L_SURFACES) + i * 104);
		float *fs = (float *)ds;
		int shaderNum = ds[0], fogNum = ds[1], type = ds[2], firstVert = ds[3], numVerts = ds[4];
		float *verts = (float *)(g_file + lump_ofs(L_DRAWVERTS)) + firstVert * 11;
		msurface_t *surf = &g_surfaces[i];
		surf->fogIndex = fogNum + 1;
		surf->shader = &g_shaders[g_firstOfName[shaderNum]];
		if (type == 1) {
			srfSurfaceFace_t *cv = calloc(1, sizeof(srfSurfaceFace_t));
			cv->surfaceType = SF_FACE;
			for (j = 0; j < 3; j++) cv->plane.normal[j] = fs[21 + j];
			cv->plane.dist = DotProduct(verts, cv->plane.normal);
			cv->plane.type = PlaneTypeForNormal(cv->plane.normal);
			SetPlaneSignbits(&cv->plane);
			surf->data = (surfaceType_t *)cv;
		} else if (type == 3) {
			srfTriangles_t *tri = calloc(1, sizeof(srfTriangles_t));
			tri->surfaceType = SF_TRIANGLES;
			ClearBounds(tri->bounds[0], tri->bounds[1]);
			for (j = 0; j < numVerts; j++) {
				AddPointToBounds(verts + j * 11, tri->bounds[0], tri->bounds[1]);
			}
			surf->data = (surfaceType_t *)tri;
		} else if (type == 4) {
			srfFlare_t *flare = calloc(1, sizeof(srfFlare_t));
			flare->surfaceType = SF_FLARE;
			surf->data = (surfaceType_t *)flare;
		} else {
			/* a patch would have a grid: none in the map of the test */
			static surfaceType_t skip = SF_SKIP;
			surf->data = &skip;
		}
	}

	/* the marksurfaces */
	count = lump_len(L_LEAFSURFACES) / 4;
	g_world.marksurfaces = calloc(count, sizeof(msurface_t *));
	g_world.nummarksurfaces = count;
	for (i = 0; i < count; i++) {
		g_world.marksurfaces[i] = g_surfaces + ((int *)(g_file + lump_ofs(L_LEAFSURFACES)))[i];
	}

	/* the tree */
	numDecision = lump_len(L_NODES) / 36;
	numLeafs = lump_len(L_LEAFS) / 48;
	g_world.numDecisionNodes = numDecision;
	g_world.numnodes = numDecision + numLeafs;
	g_world.nodes = calloc(g_world.numnodes, sizeof(mnode_t));
	for (i = 0; i < numDecision; i++) {
		int *in = (int *)(g_file + lump_ofs(L_NODES) + i * 36);
		mnode_t *out = &g_world.nodes[i];
		for (j = 0; j < 3; j++) {
			out->mins[j] = in[3 + j];
			out->maxs[j] = in[6 + j];
		}
		out->plane = g_world.planes + in[0];
		out->contents = CONTENTS_NODE_;
		for (j = 0; j < 2; j++) {
			int p = in[1 + j];
			if (p >= 0) {
				out->children[j] = g_world.nodes + p;
			} else {
				out->children[j] = g_world.nodes + numDecision + (-1 - p);
			}
		}
	}
	g_world.numClusters = 0;
	for (i = 0; i < numLeafs; i++) {
		int *in = (int *)(g_file + lump_ofs(L_LEAFS) + i * 48);
		mnode_t *out = &g_world.nodes[numDecision + i];
		for (j = 0; j < 3; j++) {
			out->mins[j] = in[2 + j];
			out->maxs[j] = in[5 + j];
		}
		out->cluster = in[0];
		out->area = in[1];
		if (out->cluster >= g_world.numClusters) {
			g_world.numClusters = out->cluster + 1;
		}
		out->firstmarksurface = g_world.marksurfaces + in[8];
		out->nummarksurfaces = in[9];
	}
	set_parent(g_world.nodes, NULL);

	/* the visibility: the novis row, then the lump if it has rows */
	{
		int len = (g_world.numClusters + 63) & ~63;
		g_world.novis = malloc(len);
		memset(g_world.novis, 0xff, len);
		if (lump_len(L_VISIBILITY)) {
			int *buf = (int *)(g_file + lump_ofs(L_VISIBILITY));
			g_world.numClusters = buf[0];
			g_world.clusterBytes = buf[1];
			g_world.vis = (byte *)(buf + 2);
		}
	}
	g_world.numfogs = lump_len(L_FOGS) / 72 + 1;
	g_world.fogs = calloc(g_world.numfogs, sizeof(fog_t));
}

static void print_floats(const char *label, float *v, int n) {
	int i;
	printf("%s", label);
	for (i = 0; i < n; i++) printf(" %08x", bits(v[i]));
	printf("\n");
}

#define MAX_VIEW_DLIGHTS 32

int main(int argc, char **argv) {
	FILE *views;
	char line[1024];
	static drawSurf_t drawSurfs[MAX_DRAWSURFS];
	static dlight_t dlights[MAX_VIEW_DLIGHTS];
	int viewNumber = 0, i, k;
	if (argc < 3) {
		fprintf(stderr, "frontgen <map.bsp> <views.txt>\n");
		return 1;
	}
	ri.Printf = ri_printf;
	ri.Error = (void (*)(int, const char *, ...))ri_error;
	load(argv[1]);
	tr.world = &g_world;
	tr.viewCluster = -1;
	glConfig.vidHeight = 480;
	cv_facePlaneCull.integer = 1;
	cv_znear.value = 4;
	cv_znear.integer = 4;
	cv_drawworld.integer = 1;
	cv_drawentities.integer = 1;
	/* the cvar is new: its modified flag is set, which makes the first marking of the leafs happen */
	cv_showcluster.modified = qtrue;
	for (i = 0; i < MAX_SHADERS; i++) {
		static shader_t opaque;
		opaque.sort = SS_OPAQUE;
		tr.sortedShaders[i] = &opaque;
	}
	tr.defaultShader = &g_shaders[0];
	views = fopen(argv[2], "r");
	if (!views) { fprintf(stderr, "no views\n"); return 1; }
	while (fgets(line, sizeof(line), views)) {
		float ox, oy, oz, yaw, pitch, roll, fovx, fovy;
		int consumed = 0, n = 0;
		vec3_t angles, axis[3];
		viewParms_t parms;
		char *rest;
		if (sscanf(line, "view %f %f %f %f %f %f %f %f%n", &ox, &oy, &oz, &yaw, &pitch, &roll, &fovx, &fovy,
				&consumed) < 8) {
			continue;
		}
		rest = line + consumed;
		while (n < MAX_VIEW_DLIGHTS) {
			float x, y, z, r;
			int used = 0;
			if (sscanf(rest, " dlight %f %f %f %f%n", &x, &y, &z, &r, &used) < 4) break;
			rest += used;
			dlights[n].origin[0] = x; dlights[n].origin[1] = y; dlights[n].origin[2] = z;
			dlights[n].radius = r;
			n++;
		}
		angles[0] = pitch; angles[1] = yaw; angles[2] = roll;
		AngleVectors(angles, axis[0], axis[1], axis[2]);
		/* RE_RenderScene */
		memset(&tr.refdef, 0, sizeof(tr.refdef));
		tr.refdef.x = 0; tr.refdef.y = 0; tr.refdef.width = 640; tr.refdef.height = 480;
		tr.refdef.fov_x = fovx; tr.refdef.fov_y = fovy;
		VectorCopy(axis[0], tr.refdef.viewaxis[0]);
		VectorCopy(axis[1], tr.refdef.viewaxis[1]);
		VectorCopy(axis[2], tr.refdef.viewaxis[2]);
		tr.refdef.vieworg[0] = ox; tr.refdef.vieworg[1] = oy; tr.refdef.vieworg[2] = oz;
		tr.refdef.numDrawSurfs = 0;
		tr.refdef.drawSurfs = drawSurfs;
		tr.refdef.num_dlights = n;
		tr.refdef.dlights = dlights;
		memset(&parms, 0, sizeof(parms));
		parms.viewportX = 0;
		parms.viewportY = glConfig.vidHeight - (tr.refdef.y + tr.refdef.height);
		parms.viewportWidth = tr.refdef.width;
		parms.viewportHeight = tr.refdef.height;
		parms.isPortal = qfalse;
		parms.fovX = fovx; parms.fovY = fovy;
		VectorCopy(tr.refdef.vieworg, parms.or.origin);
		VectorCopy(axis[0], parms.or.axis[0]);
		VectorCopy(axis[1], parms.or.axis[1]);
		VectorCopy(axis[2], parms.or.axis[2]);
		VectorCopy(tr.refdef.vieworg, parms.pvsOrigin);
		R_RenderView(&parms);

		printf("view %d axis", viewNumber);
		for (i = 0; i < 3; i++) for (k = 0; k < 3; k++) printf(" %08x", bits(axis[i][k]));
		printf("\n");
		for (i = 0; i < 4; i++) {
			printf("frustum %d", i);
			for (k = 0; k < 3; k++) printf(" %08x", bits(tr.viewParms.frustum[i].normal[k]));
			printf(" %08x\n", bits(tr.viewParms.frustum[i].dist));
		}
		print_floats("proj", tr.viewParms.projectionMatrix, 16);
		printf("zfar %08x\n", bits(tr.viewParms.zFar));
		printf("visbounds");
		for (k = 0; k < 3; k++) printf(" %08x", bits(tr.viewParms.visBounds[0][k]));
		for (k = 0; k < 3; k++) printf(" %08x", bits(tr.viewParms.visBounds[1][k]));
		printf("\n");
		printf("count %d\n", tr.refdef.numDrawSurfs);
		for (i = 0; i < tr.refdef.numDrawSurfs; i++) {
			int index = -1;
			for (k = 0; k < g_world.numsurfaces; k++) {
				if (g_surfaces[k].data == drawSurfs[i].surface) { index = k; break; }
			}
			printf("d %08x %d\n", drawSurfs[i].sort, index);
		}
		viewNumber++;
	}
	fclose(views);
	return 0;
}
