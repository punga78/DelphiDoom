/*
 * Parity tool of the issue #118: the collision model of Quake III Arena.
 *   cmgen write <variant> <file>      writes a small synthetic BSP (no game data)
 *   cmgen run <file> <seed>           loads it with the real cm_load.c and prints the answers of
 *                                     cm_test.c and cm_trace.c to a list of queries
 * The BSP is made here (k-d tree over random axial and bevelled brushes, a submodel that is not
 * in the tree, two patches, an entity string and, for variant 0, a visibility lump). Floats are
 * printed as the 8 hex digits of their bits. A line of the output is "<query> | <answer>".
 */
#include "qcommon/cm_local.h"
#include <stdarg.h>

static unsigned g_seed;

static unsigned rnd(void) {
	g_seed ^= g_seed << 13;
	g_seed ^= g_seed >> 17;
	g_seed ^= g_seed << 5;
	return g_seed;
}

static int rint_(int lo, int hi) {
	return lo + (int)(rnd() % (unsigned)(hi - lo + 1));
}

static unsigned fb(float f) {
	unsigned u;
	memcpy(&u, &f, 4);
	return u;
}

/* ------------------------------------------------------------------ the BSP writer */

#define MAXB 128
static dshader_t shaders[4];
static dplane_t planes[2048];
static int np;
static dbrushside_t sides[MAXB * 12];
static int nsides;
static dbrush_t brushes[MAXB];
static float bmin[MAXB][3], bmax[MAXB][3];
static int nbrushes;
static dnode_t nodes[1024];
static int nnodes;
static dleaf_t leafs[1024];
static int nleafs;
static int leafbrushes[8192];
static int nleafbrushes;
static int leafsurfaces[1024];
static int nleafsurfaces;

static int add_plane(float x, float y, float z, float d) {
	planes[np].normal[0] = x;
	planes[np].normal[1] = y;
	planes[np].normal[2] = z;
	planes[np].dist = d;
	return np++;
}

static void add_side(int plane) {
	sides[nsides].planeNum = plane;
	sides[nsides].shaderNum = rint_(0, 3);
	nsides++;
}

static void add_brush(float cx, float cy, float cz, float hx, float hy, float hz, int bevel, int shader) {
	dbrush_t *b = &brushes[nbrushes];
	b->firstSide = nsides;
	b->shaderNum = shader;
	add_side(add_plane(-1, 0, 0, -(cx - hx)));
	add_side(add_plane(1, 0, 0, cx + hx));
	add_side(add_plane(0, -1, 0, -(cy - hy)));
	add_side(add_plane(0, 1, 0, cy + hy));
	add_side(add_plane(0, 0, -1, -(cz - hz)));
	add_side(add_plane(0, 0, 1, cz + hz));
	b->numSides = 6;
	if (bevel) {
		float n = 0.70710678f, m = 0.57735027f;
		add_side(add_plane(n, n, 0, n * (cx + hx) + n * (cy + hy) - 0.35f * hx));
		add_side(add_plane(-m, 0, m, -m * (cx - hx) + m * (cz + hz) - 0.3f * hz));
		add_side(add_plane(m, -m, m, m * (cx + hx) - m * (cy - hy) + m * (cz + hz) - 0.4f * hz));
		b->numSides = 9;
	}
	bmin[nbrushes][0] = cx - hx; bmin[nbrushes][1] = cy - hy; bmin[nbrushes][2] = cz - hz;
	bmax[nbrushes][0] = cx + hx; bmax[nbrushes][1] = cy + hy; bmax[nbrushes][2] = cz + hz;
	nbrushes++;
}

static int build(int *ids, int count, int depth) {
	int axis = depth % 3, i, j, front[MAXB], back[MAXB], nfront = 0, nback = 0;
	float centers[MAXB], split, t;
	int node, li;

	if (depth > 0 && (count <= 3 || depth >= 8)) {
		goto leaf;
	}
	for (i = 0; i < count; i++) {
		centers[i] = (bmin[ids[i]][axis] + bmax[ids[i]][axis]) * 0.5f;
	}
	for (i = 1; i < count; i++) {
		t = centers[i];
		for (j = i - 1; j >= 0 && centers[j] > t; j--) {
			centers[j + 1] = centers[j];
		}
		centers[j + 1] = t;
	}
	split = count > 0 ? (float)(int)centers[count / 2] : 0.0f;
	for (i = 0; i < count; i++) {
		if (bmax[ids[i]][axis] > split) {
			front[nfront++] = ids[i];
		}
		if (bmin[ids[i]][axis] < split) {
			back[nback++] = ids[i];
		}
	}
	if (depth > 0 && nfront == count && nback == count) {
		goto leaf;
	}
	node = nnodes++;
	{
		float nx = axis == 0, ny = axis == 1, nz = axis == 2;
		nodes[node].planeNum = add_plane(nx, ny, nz, split);
	}
	for (i = 0; i < 3; i++) {
		nodes[node].mins[i] = -4096;
		nodes[node].maxs[i] = 4096;
	}
	nodes[node].children[0] = build(front, nfront, depth + 1);
	nodes[node].children[1] = build(back, nback, depth + 1);
	return node;
leaf:
	li = nleafs++;
	leafs[li].cluster = li;
	leafs[li].area = li % 3;
	for (i = 0; i < 3; i++) {
		leafs[li].mins[i] = -4096;
		leafs[li].maxs[i] = 4096;
	}
	leafs[li].firstLeafBrush = nleafbrushes;
	leafs[li].numLeafBrushes = count;
	for (i = 0; i < count; i++) {
		leafbrushes[nleafbrushes++] = ids[i];
	}
	leafs[li].firstLeafSurface = nleafsurfaces;
	if (li % 4 == 0) {
		leafsurfaces[nleafsurfaces++] = 0;
		leafs[li].numLeafSurfaces = 1;
	} else if (li % 4 == 1) {
		leafsurfaces[nleafsurfaces++] = 1;
		leafsurfaces[nleafsurfaces++] = 2;
		leafs[li].numLeafSurfaces = 2;
	}
	return -(li + 1);
}

static void put_vert(drawVert_t *v, float x, float y, float z) {
	memset(v, 0, sizeof(*v));
	v->xyz[0] = x; v->xyz[1] = y; v->xyz[2] = z;
	v->normal[2] = 1;
}

static void write_bsp(int variant, const char *path) {
	static dmodel_t models[3];
	static dsurface_t surfaces[3];
	static drawVert_t verts[4 + 9 + 15];
	static int indexes[6] = { 0, 1, 2, 0, 2, 3 };
	static char entities[256];
	static unsigned char vis[8 + 4096];
	dheader_t header;
	int ntree = variant == 0 ? 45 : 30;
	int ids[MAXB], i, j, ofs, nvis = 0;
	const void *data[HEADER_LUMPS];
	int len[HEADER_LUMPS];
	FILE *f;
	static const char *names[4] = { "textures/q3/solid", "textures/q3/water", "textures/q3/clip", "textures/q3/curve" };
	static const int contents[4] = { CONTENTS_SOLID, CONTENTS_WATER, CONTENTS_PLAYERCLIP, CONTENTS_SOLID };
	static const int surf[4] = { 0, 0, 0x20, 0x1000 };

	g_seed = variant == 0 ? 0x1234ABCDu : 0x0BADF00Du;
	for (i = 0; i < 4; i++) {
		strcpy(shaders[i].shader, names[i]);
		shaders[i].contentFlags = contents[i];
		shaders[i].surfaceFlags = surf[i];
	}
	for (i = 0; i < ntree + 3; i++) {
		int cx = rint_(-400, 400), cy = rint_(-400, 400), cz = rint_(-200, 200);
		int hx = rint_(30, 150), hy = rint_(30, 150), hz = rint_(30, 150);
		add_brush((float)cx, (float)cy, (float)cz, (float)hx, (float)hy, (float)hz, i % 3 == 2, i % 3);
	}
	for (i = 0; i < ntree; i++) {
		ids[i] = i;
	}
	build(ids, ntree, 0);

	for (i = 0; i < 2; i++) {
		models[i].mins[0] = models[i].mins[1] = models[i].mins[2] = -1024;
		models[i].maxs[0] = models[i].maxs[1] = models[i].maxs[2] = 1024;
	}
	models[0].firstSurface = 0; models[0].numSurfaces = 3;
	models[0].firstBrush = 0; models[0].numBrushes = ntree;
	for (j = 0; j < 3; j++) {
		models[1].mins[j] = bmin[ntree][j];
		models[1].maxs[j] = bmax[ntree][j];
	}
	models[1].firstSurface = 1; models[1].numSurfaces = 1;
	models[1].firstBrush = ntree; models[1].numBrushes = 3;
	models[2].firstBrush = ntree; models[2].numBrushes = 0;

	put_vert(&verts[0], -64, -64, 0);
	put_vert(&verts[1], 64, -64, 0);
	put_vert(&verts[2], 64, 64, 0);
	put_vert(&verts[3], -64, 64, 0);
	for (j = 0; j < 3; j++) {
		for (i = 0; i < 3; i++) {
			put_vert(&verts[4 + j * 3 + i], i * 64 - 64, j * 64 - 64, (i == 1 && j == 1) ? 48 : 0);
		}
	}
	for (j = 0; j < 3; j++) {
		for (i = 0; i < 5; i++) {
			put_vert(&verts[13 + j * 5 + i], 400 + i * 32, j * 64, (i == 2 && j == 1) ? -32 : 8);
		}
	}
	surfaces[0].shaderNum = 0; surfaces[0].fogNum = -1; surfaces[0].surfaceType = MST_PLANAR;
	surfaces[0].firstVert = 0; surfaces[0].numVerts = 4; surfaces[0].firstIndex = 0; surfaces[0].numIndexes = 6;
	surfaces[0].lightmapNum = -1;
	surfaces[1].shaderNum = 3; surfaces[1].fogNum = -1; surfaces[1].surfaceType = MST_PATCH;
	surfaces[1].firstVert = 4; surfaces[1].numVerts = 9; surfaces[1].lightmapNum = -1;
	surfaces[1].patchWidth = 3; surfaces[1].patchHeight = 3;
	surfaces[2].shaderNum = 3; surfaces[2].fogNum = -1; surfaces[2].surfaceType = MST_PATCH;
	surfaces[2].firstVert = 13; surfaces[2].numVerts = 15; surfaces[2].lightmapNum = -1;
	surfaces[2].patchWidth = 5; surfaces[2].patchHeight = 3;

	memset(entities, 0, sizeof(entities));
	strcpy(entities, "{\n\"classname\" \"worldspawn\"\n\"message\" \"q3 collision sample\"\n}\n");

	if (variant == 0) {
		int cb = (nleafs + 7) >> 3;
		((int *)vis)[0] = nleafs;
		((int *)vis)[1] = cb;
		for (i = 0; i < nleafs * cb; i++) {
			vis[8 + i] = (unsigned char)(rnd() >> 5);
		}
		nvis = 8 + nleafs * cb;
	}

	memset(data, 0, sizeof(data));
	memset(len, 0, sizeof(len));
	data[LUMP_ENTITIES] = entities; len[LUMP_ENTITIES] = (int)strlen(entities) + 1;
	data[LUMP_SHADERS] = shaders; len[LUMP_SHADERS] = sizeof(shaders);
	data[LUMP_PLANES] = planes; len[LUMP_PLANES] = np * sizeof(dplane_t);
	data[LUMP_NODES] = nodes; len[LUMP_NODES] = nnodes * sizeof(dnode_t);
	data[LUMP_LEAFS] = leafs; len[LUMP_LEAFS] = nleafs * sizeof(dleaf_t);
	data[LUMP_LEAFSURFACES] = leafsurfaces; len[LUMP_LEAFSURFACES] = nleafsurfaces * 4;
	data[LUMP_LEAFBRUSHES] = leafbrushes; len[LUMP_LEAFBRUSHES] = nleafbrushes * 4;
	data[LUMP_MODELS] = models; len[LUMP_MODELS] = sizeof(models);
	data[LUMP_BRUSHES] = brushes; len[LUMP_BRUSHES] = nbrushes * sizeof(dbrush_t);
	data[LUMP_BRUSHSIDES] = sides; len[LUMP_BRUSHSIDES] = nsides * sizeof(dbrushside_t);
	data[LUMP_DRAWVERTS] = verts; len[LUMP_DRAWVERTS] = sizeof(verts);
	data[LUMP_DRAWINDEXES] = indexes; len[LUMP_DRAWINDEXES] = sizeof(indexes);
	data[LUMP_SURFACES] = surfaces; len[LUMP_SURFACES] = sizeof(surfaces);
	data[LUMP_VISIBILITY] = vis; len[LUMP_VISIBILITY] = nvis;

	memset(&header, 0, sizeof(header));
	header.ident = BSP_IDENT;
	header.version = BSP_VERSION;
	ofs = sizeof(header);
	for (i = 0; i < HEADER_LUMPS; i++) {
		header.lumps[i].fileofs = ofs;
		header.lumps[i].filelen = len[i];
		ofs += (len[i] + 3) & ~3;
	}
	f = fopen(path, "wb");
	fwrite(&header, sizeof(header), 1, f);
	for (i = 0; i < HEADER_LUMPS; i++) {
		static const char zeroes[4] = { 0, 0, 0, 0 };
		if (len[i]) {
			fwrite(data[i], 1, len[i], f);
		}
		fwrite(zeroes, 1, ((len[i] + 3) & ~3) - len[i], f);
	}
	fclose(f);
}

/* ------------------------------------------------------------------ the queries */

static unsigned fnv(unsigned h, unsigned v) {
	int i;
	for (i = 0; i < 4; i++) {
		h = (h ^ ((v >> (i * 8)) & 255)) * 16777619u;
	}
	return h;
}

static float rf(int lo, int hi) {
	return (float)rint_(lo, hi) * 0.25f;
}

static void put3(const float *v) {
	printf(" %08x %08x %08x", fb(v[0]), fb(v[1]), fb(v[2]));
}

static void print_load(void) {
	unsigned h;
	int i, patches = 0;
	printf("load %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", cm.numShaders, cm.numPlanes, cm.numNodes,
		cm.numLeafs, cm.numLeafBrushes, cm.numLeafSurfaces, cm.numSubModels, cm.numBrushes, cm.numBrushSides,
		cm.numClusters, cm.clusterBytes, cm.vised, cm.numAreas, cm.numEntityChars, cm.numSurfaces);
	for (i = 0; i < cm.numSurfaces; i++) {
		if (cm.surfaces[i]) {
			patches++;
		}
	}
	printf(" %d\n", patches);
	h = 2166136261u;
	for (i = 0; i < cm.numPlanes; i++) {
		h = fnv(h, fb(cm.planes[i].normal[0]));
		h = fnv(h, fb(cm.planes[i].normal[1]));
		h = fnv(h, fb(cm.planes[i].normal[2]));
		h = fnv(h, fb(cm.planes[i].dist));
		h = fnv(h, cm.planes[i].type);
		h = fnv(h, cm.planes[i].signbits);
	}
	printf("hash planes %08x\n", h);
	h = 2166136261u;
	for (i = 0; i < cm.numBrushes; i++) {
		int k;
		h = fnv(h, cm.brushes[i].shaderNum);
		h = fnv(h, cm.brushes[i].contents);
		h = fnv(h, cm.brushes[i].numsides);
		h = fnv(h, (unsigned)(cm.brushes[i].sides - cm.brushsides));
		for (k = 0; k < 3; k++) {
			h = fnv(h, fb(cm.brushes[i].bounds[0][k]));
			h = fnv(h, fb(cm.brushes[i].bounds[1][k]));
		}
	}
	for (i = 0; i < cm.numBrushSides; i++) {
		h = fnv(h, (unsigned)(cm.brushsides[i].plane - cm.planes));
		h = fnv(h, cm.brushsides[i].surfaceFlags);
		h = fnv(h, cm.brushsides[i].shaderNum);
	}
	printf("hash brushes %08x\n", h);
	h = 2166136261u;
	for (i = 0; i < cm.numLeafs; i++) {
		h = fnv(h, cm.leafs[i].cluster);
		h = fnv(h, cm.leafs[i].area);
		h = fnv(h, cm.leafs[i].firstLeafBrush);
		h = fnv(h, cm.leafs[i].numLeafBrushes);
		h = fnv(h, cm.leafs[i].firstLeafSurface);
		h = fnv(h, cm.leafs[i].numLeafSurfaces);
	}
	for (i = 0; i < cm.numLeafBrushes; i++) {
		h = fnv(h, cm.leafbrushes[i]);
	}
	for (i = 0; i < cm.numLeafSurfaces; i++) {
		h = fnv(h, cm.leafsurfaces[i]);
	}
	printf("hash leafs %08x\n", h);
	h = 2166136261u;
	for (i = 0; i < cm.numNodes; i++) {
		h = fnv(h, (unsigned)(cm.nodes[i].plane - cm.planes));
		h = fnv(h, cm.nodes[i].children[0]);
		h = fnv(h, cm.nodes[i].children[1]);
	}
	printf("hash nodes %08x\n", h);
	h = 2166136261u;
	for (i = 0; i < cm.numSubModels; i++) {
		int k;
		for (k = 0; k < 3; k++) {
			h = fnv(h, fb(cm.cmodels[i].mins[k]));
			h = fnv(h, fb(cm.cmodels[i].maxs[k]));
		}
		h = fnv(h, cm.cmodels[i].leaf.numLeafBrushes);
		h = fnv(h, cm.cmodels[i].leaf.numLeafSurfaces);
		if (i > 0) {
			for (k = 0; k < cm.cmodels[i].leaf.numLeafBrushes; k++) {
				h = fnv(h, cm.leafbrushes[cm.cmodels[i].leaf.firstLeafBrush + k]);
			}
			for (k = 0; k < cm.cmodels[i].leaf.numLeafSurfaces; k++) {
				h = fnv(h, cm.leafsurfaces[cm.cmodels[i].leaf.firstLeafSurface + k]);
			}
		}
	}
	printf("hash models %08x\n", h);
	h = 2166136261u;
	for (i = 0; i < cm.clusterBytes * (cm.vised ? cm.numClusters : 1); i++) {
		h = fnv(h, cm.visibility[i]);
	}
	printf("hash vis %08x\n", h);
	h = 2166136261u;
	for (i = 0; i < cm.numAreas; i++) {
		h = fnv(h, cm.areas[i].floodnum);
	}
	printf("hash areas %08x\n", h);
	h = 2166136261u;
	for (i = 0; i < cm.numEntityChars; i++) {
		h = fnv(h, (unsigned char)cm.entityString[i]);
	}
	printf("hash entities %08x\n", h);
}

static void print_trace(const trace_t *t) {
	printf(" | %d %d %08x", t->allsolid, t->startsolid, fb(t->fraction));
	put3(t->endpos);
	put3(t->plane.normal);
	printf(" %08x %d %d %d %d\n", fb(t->plane.dist), t->plane.type, t->plane.signbits, t->surfaceFlags, t->contents);
}

static const int masks[] = { 1, 0x10001, 0x21, 0x2000001, 0x10, 0x10000, -1 };

static void random_box(float *mins, float *maxs) {
	int kind = rint_(0, 4), i;
	for (i = 0; i < 3; i++) {
		mins[i] = maxs[i] = 0;
	}
	if (kind == 1 || kind == 2) {
		mins[0] = mins[1] = -15; maxs[0] = maxs[1] = 15;
		mins[2] = -24; maxs[2] = 32;
	} else if (kind == 3) {
		for (i = 0; i < 3; i++) {
			mins[i] = -rf(4, 120);
			maxs[i] = rf(4, 120);
		}
	} else if (kind == 4) {
		mins[0] = mins[1] = mins[2] = -8;
		maxs[0] = maxs[1] = maxs[2] = 8;
	}
}

static void run_traces(int count, int transformed, int tempbox) {
	int i, k;
	for (i = 0; i < count; i++) {
		float start[3], end[3], mins[3], maxs[3], origin[3], angles[3];
		int model, mask, capsule, zero = rint_(0, 99) < 15;
		trace_t t;
		model = tempbox ? 255 : (rint_(0, 99) < 70 ? 0 : rint_(1, 2));
		mask = masks[rint_(0, 6)];
		capsule = rint_(0, 99) < 30;
		for (k = 0; k < 3; k++) {
			start[k] = rf(-1600, 1600) * (k == 2 ? 0.5f : 1.0f);
			end[k] = zero ? start[k] : start[k] + rf(-1600, 1600);
		}
		if (rint_(0, 3) == 0) {
			/* a short move, to touch brushes at the end of it */
			for (k = 0; k < 3; k++) {
				end[k] = zero ? start[k] : start[k] + rf(-80, 80);
			}
		}
		if (model != 0 && !tempbox) {
			/* the submodels are around the origin of their own frame */
			for (k = 0; k < 3; k++) {
				start[k] = rf(-1600, 1600);
				end[k] = zero ? start[k] : start[k] + rf(-1000, 1000);
			}
		}
		random_box(mins, maxs);
		for (k = 0; k < 3; k++) {
			origin[k] = transformed ? rf(-200, 200) : 0;
			angles[k] = 0;
		}
		if (transformed && rint_(0, 2) > 0) {
			angles[rint_(0, 2)] = (float)(rint_(-8, 8) * 15) + (rint_(0, 1) ? 0.5f : 0);
			if (rint_(0, 1)) {
				angles[rint_(0, 2)] = (float)(rint_(-4, 4) * 30);
			}
		}
		printf("%s", transformed ? "ttrace" : "trace");
		put3(start);
		put3(end);
		put3(mins);
		put3(maxs);
		printf(" %d %d %d", model, mask, capsule);
		if (transformed) {
			put3(origin);
			put3(angles);
			CM_TransformedBoxTrace(&t, start, end, mins, maxs, model, mask, origin, angles, capsule);
		} else {
			CM_BoxTrace(&t, start, end, mins, maxs, model, mask, capsule);
		}
		print_trace(&t);
	}
}

static void run_queries(int seed) {
	int i, k;
	g_seed = (unsigned)seed;

	for (i = 0; i < 120; i++) {
		float p[3];
		int model;
		for (k = 0; k < 3; k++) {
			p[k] = rf(-1600, 1600) * (k == 2 ? 0.5f : 1.0f);
		}
		if (i % 3 == 0) {
			for (k = 0; k < 3; k++) {
				p[k] = rf(-1800, 1800) * (k == 2 ? 0.5f : 1.0f);
			}
		}
		printf("pointleaf");
		put3(p);
		printf(" | %d\n", CM_PointLeafnum(p));
		for (model = 0; model < 3; model++) {
			printf("pointcontents");
			put3(p);
			printf(" %d | %d\n", model, CM_PointContents(p, model));
		}
	}
	for (i = 0; i < 80; i++) {
		float p[3], origin[3], angles[3];
		int model = rint_(0, 2);
		for (k = 0; k < 3; k++) {
			p[k] = rf(-1600, 1600) * (k == 2 ? 0.5f : 1.0f);
			origin[k] = rf(-400, 400);
			angles[k] = (float)(rint_(0, 3) == 0 ? rint_(-6, 6) * 15 : 0);
		}
		printf("tpointcontents");
		put3(p);
		printf(" %d", model);
		put3(origin);
		put3(angles);
		printf(" | %d\n", CM_TransformedPointContents(p, model, origin, angles));
	}
	for (i = 0; i < 60; i++) {
		float mins[3], maxs[3];
		int list[64], listsize = rint_(0, 3) == 0 ? 3 : 64, last, count, k2;
		unsigned h = 2166136261u;
		for (k = 0; k < 3; k++) {
			float c = rf(-1800, 1800), e = rf(1, 600);
			mins[k] = c - e;
			maxs[k] = c + e;
		}
		printf("boxleafs");
		put3(mins);
		put3(maxs);
		count = CM_BoxLeafnums(mins, maxs, list, listsize, &last);
		for (k2 = 0; k2 < count; k2++) {
			h = fnv(h, list[k2]);
		}
		printf(" %d | %d %d %08x\n", listsize, count, last, h);
	}
	for (i = 0; i < 60; i++) {
		float mins[3], maxs[3];
		cbrush_t *list[128];
		int listsize = rint_(0, 3) == 0 ? 3 : 128, count, k2;
		unsigned h = 2166136261u;
		for (k = 0; k < 3; k++) {
			float c = rf(-1800, 1800), e = rf(1, 600);
			mins[k] = c - e;
			maxs[k] = c + e;
		}
		printf("boxbrushes");
		put3(mins);
		put3(maxs);
		count = CM_BoxBrushes(mins, maxs, list, listsize);
		for (k2 = 0; k2 < count; k2++) {
			h = fnv(h, (unsigned)(list[k2] - cm.brushes));
		}
		printf(" %d | %d %08x\n", listsize, count, h);
	}
	run_traces(300, 0, 0);
	run_traces(120, 1, 0);

	/* a temporary box model, as the game uses it for entities */
	for (i = 0; i < 4; i++) {
		float mins[3], maxs[3];
		int handle, capsule = i == 3;
		for (k = 0; k < 3; k++) {
			mins[k] = -rf(8, 100);
			maxs[k] = rf(8, 100);
		}
		printf("tempbox");
		put3(mins);
		put3(maxs);
		handle = CM_TempBoxModel(mins, maxs, capsule);
		printf(" %d | %d\n", capsule, handle);
		if (!capsule) {
			float b0[3], b1[3];
			CM_ModelBounds(handle, b0, b1);
			printf("modelbounds %d |", handle);
			put3(b0);
			put3(b1);
			printf("\n");
			run_traces(25, 0, 1);
			for (k = 0; k < 15; k++) {
				float p[3];
				int j;
				for (j = 0; j < 3; j++) {
					p[j] = rf(-110, 110);
				}
				printf("pointcontents");
				put3(p);
				printf(" 255 | %d\n", CM_PointContents(p, handle));
			}
		}
	}
	for (i = 0; i < 3; i++) {
		float b0[3], b1[3];
		CM_ModelBounds(i, b0, b1);
		printf("modelbounds %d |", i);
		put3(b0);
		put3(b1);
		printf("\n");
	}
	printf("inline %d | %d\n", 1, CM_InlineModel(1));
	printf("counts | %d %d %d\n", CM_NumClusters(), CM_NumInlineModels(), (int)strlen(CM_EntityString()));
	for (i = 0; i < cm.numLeafs && i < 6; i++) {
		printf("leaf %d | %d %d\n", i, CM_LeafCluster(i), CM_LeafArea(i));
	}
	for (i = 0; i < 4; i++) {
		int cluster = i == 3 ? 9999 : i;
		byte *row = CM_ClusterPVS(cluster);
		int n = cm.clusterBytes < 4 ? cm.clusterBytes : 4, j;
		printf("pvs %d |", cluster);
		for (j = 0; j < n; j++) {
			printf(" %02x", row[j]);
		}
		printf("\n");
	}
}

static void run_areas(void) {
	byte buffer[64];
	int i, j, bytes;
	static const int ops[][3] = { { 0, 1, 1 }, { 1, 2, 1 }, { 0, 1, 0 }, { 0, 2, 1 }, { 0, 2, 0 }, { 1, 2, 0 } };
	printf("areas %d\n", cm.numAreas);
	for (i = 0; i < 6; i++) {
		CM_AdjustAreaPortalState(ops[i][0], ops[i][1], ops[i][2]);
		printf("adjust %d %d %d |", ops[i][0], ops[i][1], ops[i][2]);
		for (j = 0; j < 3; j++) {
			printf(" %d%d%d", CM_AreasConnected(0, j), CM_AreasConnected(1, j), CM_AreasConnected(2, j));
		}
		memset(buffer, 0, sizeof(buffer));
		bytes = CM_WriteAreaBits(buffer, i % 3);
		printf(" bits %d %02x\n", bytes, buffer[0]);
	}
	CM_AdjustAreaPortalState(0, 1, 1);
	printf("connected -1 0 | %d\n", CM_AreasConnected(-1, 0));
	memset(buffer, 0, sizeof(buffer));
	bytes = CM_WriteAreaBits(buffer, -1);
	printf("bits -1 | %d %02x\n", bytes, buffer[0]);
	cm_noAreas->integer = 1;
	printf("noareas | %d", CM_AreasConnected(0, 2));
	memset(buffer, 0, sizeof(buffer));
	bytes = CM_WriteAreaBits(buffer, 1);
	printf(" %d %02x\n", bytes, buffer[0]);
	cm_noAreas->integer = 0;
}

int main(int argc, char **argv) {
	int checksum;
	if (argc >= 4 && !strcmp(argv[1], "write")) {
		write_bsp(atoi(argv[2]), argv[3]);
		return 0;
	}
	if (argc >= 4 && !strcmp(argv[1], "run")) {
		CM_LoadMap(argv[2], qfalse, &checksum);
		print_load();
		run_queries(atoi(argv[3]));
		run_areas();
		return 0;
	}
	return 1;
}
