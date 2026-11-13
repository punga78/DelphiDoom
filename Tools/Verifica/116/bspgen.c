/*
 * Parity driver of the issue #116 (BSP of Quake III Arena, IBSP 46).
 *
 *   bspgen write <variant> <file>   writes a small BSP built here (no data of any game)
 *   bspgen read <file>              reads it as the engine does and prints what it found
 *
 * "read" takes the header, the sizes of the records (from the real structs of qfiles.h), the
 * CRC-32 of every lump, and runs the real ParseMesh, R_StitchAllPatches and
 * R_FixSharedVertexLodError of tr_bsp.c (the lines of the original, see build.sh) on the
 * patch surfaces; the grids are printed before and after the stitching. The same BSPs are
 * built by Tests\Source\DelphiDoom.Tests.MapFile.Bsp.Sample.pas, with the same formulas.
 */
#include "stubs.h"
#include "bsp_original.inc"

/* ---- the world, as far as the extracted functions use it ---- */
#include "bsp_nodes.inc"
static byte *fileBase;
typedef struct {
	char name[64];
	int numsurfaces;
	msurface_t *surfaces;
	int numShaders;
	dshader_t *shaders;
	cplane_t *planes;
	mnode_t *nodes;
	int numnodes;
	int numDecisionNodes;
	msurface_t **marksurfaces;
	int numClusters;
	bmodel_t *bmodels;
	vec3_t lightGridOrigin;
	vec3_t lightGridSize;
	vec3_t lightGridInverseSize;
	int lightGridBounds[3];
	byte *lightGridData;
} world_t;
static world_t s_worldData;

#include "bsp_world.inc"

/* the lightmap textures: R_CreateImage only keeps the FNV-1a hash of the 128 x 128 x 4 bytes it is given */
static unsigned g_imgHash[256];
static image_t g_images[256];
static int g_imgCalls;
static char *va(const char *fmt, ...) {
	static char buf[64];
	va_list args;
	va_start(args, fmt);
	vsprintf(buf, fmt, args);
	va_end(args);
	return buf;
}
static image_t *R_CreateImage(const char *name, const byte *pic, int width, int height, int mipmap, int allowPicmip, int wrap) {
	unsigned h = 2166136261u;
	int i;
	(void)name; (void)mipmap; (void)allowPicmip; (void)wrap;
	for (i = 0; i < width * height * 4; i++) h = (h ^ pic[i]) * 16777619u;
	g_imgHash[g_imgCalls] = h;
	g_images[g_imgCalls].index = g_imgCalls;
	return &g_images[g_imgCalls++];
}

#include "bsp_load.inc"

static unsigned bits(float f) { unsigned u; memcpy(&u, &f, 4); return u; }

/* ------------------------------------------------------------------ generator ---- */

typedef struct { unsigned char *p; int n; int cap; } buf_t;

static void put(buf_t *b, const void *data, int n) {
	if (b->n + n > b->cap) {
		b->cap = (b->n + n) * 2 + 64;
		b->p = realloc(b->p, b->cap);
	}
	memcpy(b->p + b->n, data, n);
	b->n += n;
}
static void put_int(buf_t *b, int v) { put(b, &v, 4); }
static void put_float(buf_t *b, float v) { put(b, &v, 4); }
static void put_name(buf_t *b, const char *s) {
	char name[MAX_QPATH];
	memset(name, 0, sizeof(name));
	strcpy(name, s);
	put(b, name, MAX_QPATH);
}

static unsigned g_seed;
static unsigned next_random(void) {
	g_seed ^= g_seed << 13;
	g_seed ^= g_seed >> 17;
	g_seed ^= g_seed << 5;
	return g_seed;
}

typedef struct { float ox, oy; int w, h; float bulge; int shader; int fog; int group; } patch_t;
static patch_t g_patches[32];
static int g_numpatches;

static void add_patch(float ox, float oy, int w, int h, float bulge, int shader, int fog, int group) {
	patch_t *p = &g_patches[g_numpatches++];
	p->ox = ox; p->oy = oy; p->w = w; p->h = h; p->bulge = bulge;
	p->shader = shader; p->fog = fog; p->group = group;
}

static void make_patches(int variant) {
	int a, b;
	g_numpatches = 0;
	if (variant == 0) {
		add_patch(0, 0, 3, 3, 128.0f, 2, 0, 0);
		add_patch(128, 0, 3, 3, 0.0f, 2, -1, 0);
		add_patch(0, 128, 3, 3, -96.0f, 2, -1, 0);
		add_patch(512, 0, 3, 3, 32.0f, 1, -1, 0);
		add_patch(1000, 1000, 5, 5, 64.0f, 2, -1, 1);
	} else {
		g_seed = variant == 1 ? 0x1234ABCDu : 0x0BADF00Du;
		for (b = 0; b < 3; b++)
			for (a = 0; a < 3; a++)
				add_patch((float)(a * 128), (float)(b * 128), 3, 3,
					(float)((int)(next_random() % 321) - 160), 2, -1, 0);
		add_patch(1000, 1000, 5, 3, 48.0f, 2, -1, 1);
		add_patch(1128, 1000, 3, 5, -48.0f, 2, -1, 1);
	}
}

static const float group_min[2][3] = { { 0, 0, -128 }, { 1000, 1000, -128 } };
static const float group_max[2][3] = { { 256, 256, 256 }, { 1256, 1256, 256 } };

static float edge_z(float x, float y) {
	return (float)(((((int)x) / 32) * 7 + (((int)y) / 32) * 13) % 5 * 8);
}

static void put_patch_verts(buf_t *b, const patch_t *p) {
	int i, j;
	for (j = 0; j < p->h; j++)
		for (i = 0; i < p->w; i++) {
			float x = p->ox + (float)(i * (128 / (p->w - 1)));
			float y = p->oy + (float)(j * (128 / (p->h - 1)));
			float z = (i > 0 && i < p->w - 1 && j > 0 && j < p->h - 1) ? p->bulge : edge_z(x, y);
			float s = (float)i / (float)(p->w - 1), t = (float)j / (float)(p->h - 1);
			put_float(b, x); put_float(b, y); put_float(b, z);
			put_float(b, s); put_float(b, t);
			put_float(b, s * 0.5f); put_float(b, t * 0.5f);
			put_float(b, 0); put_float(b, 0); put_float(b, 0);
			{
				unsigned char c[4];
				c[0] = (unsigned char)((i * 37 + j * 91) & 255);
				c[1] = (unsigned char)((i * 11 + j * 53 + 7) & 255);
				c[2] = (unsigned char)(255 - ((i * 29 + j * 13) & 255));
				c[3] = (unsigned char)((i + j) * 17 & 255);
				put(b, c, 4);
			}
		}
}

static void put_plane(buf_t *b, float x, float y, float z, float d) {
	put_float(b, x); put_float(b, y); put_float(b, z); put_float(b, d);
}

static void put_surface(buf_t *b, int shader, int fog, int type, int firstVert, int numVerts,
	int firstIndex, int numIndexes, int lightmapNum, int lw, int lh, const float origin[3],
	const float vecs[3][3], int pw, int ph) {
	int i, j;
	put_int(b, shader); put_int(b, fog); put_int(b, type);
	put_int(b, firstVert); put_int(b, numVerts); put_int(b, firstIndex); put_int(b, numIndexes);
	put_int(b, lightmapNum); put_int(b, 0); put_int(b, 0); put_int(b, lw); put_int(b, lh);
	for (i = 0; i < 3; i++) put_float(b, origin[i]);
	for (i = 0; i < 3; i++) for (j = 0; j < 3; j++) put_float(b, vecs[i][j]);
	put_int(b, pw); put_int(b, ph);
}

static int write_bsp(int variant, const char *path) {
	buf_t lump[HEADER_LUMPS];
	static const float zero3[3] = { 0, 0, 0 };
	static const float quad_vecs[3][3] = { { 128, 0, 0 }, { 0, 128, 0 }, { 0, 0, 1 } };
	static const float quad_origin[3] = { -64, -64, 0 };
	static const float flare_origin[3] = { 0, 0, 32 };
	float vecs[3][3];
	int i, j, nsurf, vert, offset;
	char text[512];
	FILE *f;
	unsigned char header[sizeof(dheader_t)];
	dheader_t *hdr = (dheader_t *)header;

	memset(lump, 0, sizeof(lump));
	make_patches(variant);
	nsurf = 3 + g_numpatches;

	sprintf(text, "{\n\"classname\" \"worldspawn\"\n\"message\" \"q3 test variant %d\"\n}\n"
		"{\n\"classname\" \"info_player_deathmatch\"\n\"origin\" \"0 0 24\"\n\"angle\" \"90\"\n}\n", variant);
	put(&lump[LUMP_ENTITIES], text, (int)strlen(text) + 1);

	put_name(&lump[LUMP_SHADERS], "textures/test/wall"); put_int(&lump[LUMP_SHADERS], 0); put_int(&lump[LUMP_SHADERS], 1);
	put_name(&lump[LUMP_SHADERS], "textures/test/nodraw"); put_int(&lump[LUMP_SHADERS], SURF_NODRAW); put_int(&lump[LUMP_SHADERS], 0);
	put_name(&lump[LUMP_SHADERS], "textures/test/curve"); put_int(&lump[LUMP_SHADERS], 0); put_int(&lump[LUMP_SHADERS], 0);

	for (i = 0; i < 3; i++) {
		float n[3] = { 0, 0, 0 };
		n[i] = 1; put_plane(&lump[LUMP_PLANES], n[0], n[1], n[2], 64);
		n[i] = -1; put_plane(&lump[LUMP_PLANES], n[0], n[1], n[2], 64);
	}
	put_plane(&lump[LUMP_PLANES], 0.25f, 0.5f, 0.75f, 12.5f);
	put_plane(&lump[LUMP_PLANES], 0.0f, 0.5f, 0.75f, -32.0f);

	put_int(&lump[LUMP_NODES], 6); put_int(&lump[LUMP_NODES], -1); put_int(&lump[LUMP_NODES], -2);
	for (i = 0; i < 3; i++) put_int(&lump[LUMP_NODES], -64);
	for (i = 0; i < 3; i++) put_int(&lump[LUMP_NODES], 64);

	for (j = 0; j < 2; j++) {
		put_int(&lump[LUMP_LEAFS], j); put_int(&lump[LUMP_LEAFS], 0);
		for (i = 0; i < 3; i++) put_int(&lump[LUMP_LEAFS], -64);
		for (i = 0; i < 3; i++) put_int(&lump[LUMP_LEAFS], 64);
		put_int(&lump[LUMP_LEAFS], 0); put_int(&lump[LUMP_LEAFS], j == 0 ? nsurf : 0);
		put_int(&lump[LUMP_LEAFS], 0); put_int(&lump[LUMP_LEAFS], j == 0 ? 1 : 0);
	}
	for (i = 0; i < nsurf; i++) put_int(&lump[LUMP_LEAFSURFACES], i);
	put_int(&lump[LUMP_LEAFBRUSHES], 0);

	for (i = 0; i < 3; i++) put_float(&lump[LUMP_MODELS], -64.0f);
	for (i = 0; i < 3; i++) put_float(&lump[LUMP_MODELS], 64.0f);
	put_int(&lump[LUMP_MODELS], 0); put_int(&lump[LUMP_MODELS], nsurf);
	put_int(&lump[LUMP_MODELS], 0); put_int(&lump[LUMP_MODELS], 1);

	put_int(&lump[LUMP_BRUSHES], 0); put_int(&lump[LUMP_BRUSHES], 6); put_int(&lump[LUMP_BRUSHES], 0);
	for (i = 0; i < 6; i++) { put_int(&lump[LUMP_BRUSHSIDES], i); put_int(&lump[LUMP_BRUSHSIDES], 0); }

	/* the quad: 4 vertices */
	{
		static const float qx[4] = { -64, 64, 64, -64 }, qy[4] = { -64, -64, 64, 64 };
		static const float qs[4] = { 0, 1, 1, 0 }, qt[4] = { 0, 0, 1, 1 };
		for (i = 0; i < 4; i++) {
			unsigned char c[4] = { 255, 128, 64, 255 };
			put_float(&lump[LUMP_DRAWVERTS], qx[i]); put_float(&lump[LUMP_DRAWVERTS], qy[i]); put_float(&lump[LUMP_DRAWVERTS], 0);
			put_float(&lump[LUMP_DRAWVERTS], qs[i]); put_float(&lump[LUMP_DRAWVERTS], qt[i]);
			put_float(&lump[LUMP_DRAWVERTS], qs[i] * 0.5f); put_float(&lump[LUMP_DRAWVERTS], qt[i] * 0.5f);
			put_float(&lump[LUMP_DRAWVERTS], 0); put_float(&lump[LUMP_DRAWVERTS], 0); put_float(&lump[LUMP_DRAWVERTS], 1);
			put(&lump[LUMP_DRAWVERTS], c, 4);
		}
	}
	{ static const int idx[6] = { 0, 1, 2, 0, 2, 3 }; for (i = 0; i < 6; i++) put_int(&lump[LUMP_DRAWINDEXES], idx[i]); }

	put_name(&lump[LUMP_FOGS], "textures/test/fog"); put_int(&lump[LUMP_FOGS], 0); put_int(&lump[LUMP_FOGS], -1);

	put_surface(&lump[LUMP_SURFACES], 0, -1, 1, 0, 4, 0, 6, 0, 128, 128, quad_origin, quad_vecs, 0, 0);
	put_surface(&lump[LUMP_SURFACES], 0, -1, 3, 0, 4, 0, 6, -1, 0, 0, zero3, quad_vecs, 0, 0);
	put_surface(&lump[LUMP_SURFACES], 0, -1, 4, 0, 1, 0, 0, -1, 0, 0, flare_origin, quad_vecs, 0, 0);
	vert = 4;
	for (i = 0; i < g_numpatches; i++) {
		const patch_t *p = &g_patches[i];
		memset(vecs, 0, sizeof(vecs));
		for (j = 0; j < 3; j++) { vecs[0][j] = group_min[p->group][j]; vecs[1][j] = group_max[p->group][j]; }
		put_surface(&lump[LUMP_SURFACES], p->shader, p->fog, 2, vert, p->w * p->h, 0, 0, -1, 0, 0, zero3, vecs, p->w, p->h);
		put_patch_verts(&lump[LUMP_DRAWVERTS], p);
		vert += p->w * p->h;
	}

	g_seed = 0xA5A5A5A5u ^ (unsigned)variant;
	for (i = 0; i < 2 * 128 * 128 * 3; i++) { unsigned char c = (unsigned char)(next_random() >> 7); put(&lump[LUMP_LIGHTMAPS], &c, 1); }
	for (i = 0; i < 6 * 8; i++) { unsigned char c = (unsigned char)(next_random() >> 11); put(&lump[LUMP_LIGHTGRID], &c, 1); }
	put_int(&lump[LUMP_VISIBILITY], 2); put_int(&lump[LUMP_VISIBILITY], 8);
	for (i = 0; i < 16; i++) { unsigned char c = (unsigned char)(next_random() >> 3); put(&lump[LUMP_VISIBILITY], &c, 1); }

	memset(header, 0, sizeof(header));
	hdr->ident = BSP_IDENT;
	hdr->version = BSP_VERSION;
	offset = (int)sizeof(dheader_t);
	for (i = 0; i < HEADER_LUMPS; i++) {
		hdr->lumps[i].fileofs = offset;
		hdr->lumps[i].filelen = lump[i].n;
		offset += (lump[i].n + 3) & ~3;
	}
	f = fopen(path, "wb");
	if (!f) return 1;
	fwrite(header, 1, sizeof(header), f);
	for (i = 0; i < HEADER_LUMPS; i++) {
		static const unsigned char pad[4] = { 0, 0, 0, 0 };
		fwrite(lump[i].p, 1, lump[i].n, f);
		fwrite(pad, 1, ((lump[i].n + 3) & ~3) - lump[i].n, f);
	}
	fclose(f);
	return 0;
}

/* ------------------------------------------------------------------ reader ---- */

static unsigned crc_table[256];
static unsigned crc32_of(const unsigned char *p, int n) {
	unsigned c = 0xFFFFFFFFu;
	int i, k;
	if (!crc_table[1]) {
		for (i = 0; i < 256; i++) {
			unsigned v = (unsigned)i;
			for (k = 0; k < 8; k++) v = (v & 1) ? (0xEDB88320u ^ (v >> 1)) : (v >> 1);
			crc_table[i] = v;
		}
	}
	for (i = 0; i < n; i++) c = crc_table[(c ^ p[i]) & 255] ^ (c >> 8);
	return c ^ 0xFFFFFFFFu;
}

static unsigned fnv_byte(unsigned h, unsigned b) { return (h ^ (b & 255)) * 16777619u; }
static unsigned fnv_float(unsigned h, float f) {
	unsigned u = bits(f);
	h = fnv_byte(h, u); h = fnv_byte(h, u >> 8); h = fnv_byte(h, u >> 16);
	return fnv_byte(h, u >> 24);
}

static void print_grid(const char *tag, int index, const srfGridMesh_t *g) {
	int i, n = g->width * g->height;
	unsigned h = 2166136261u;
	for (i = 0; i < n; i++) {
		const drawVert_t *v = &g->verts[i];
		h = fnv_float(h, v->xyz[0]); h = fnv_float(h, v->xyz[1]); h = fnv_float(h, v->xyz[2]);
		h = fnv_float(h, v->st[0]); h = fnv_float(h, v->st[1]);
		h = fnv_float(h, v->lightmap[0]); h = fnv_float(h, v->lightmap[1]);
		h = fnv_float(h, v->normal[0]); h = fnv_float(h, v->normal[1]); h = fnv_float(h, v->normal[2]);
		h = fnv_byte(h, v->color[0]); h = fnv_byte(h, v->color[1]);
		h = fnv_byte(h, v->color[2]); h = fnv_byte(h, v->color[3]);
	}
	printf("%s %d %d %d %08x\n", tag, index, g->width, g->height, h);
	printf("we");
	for (i = 0; i < g->width; i++) printf(" %08x", bits(g->widthLodError[i]));
	printf("\nhe");
	for (i = 0; i < g->height; i++) printf(" %08x", bits(g->heightLodError[i]));
	printf("\nlod %08x %08x %08x %08x\n", bits(g->lodOrigin[0]), bits(g->lodOrigin[1]), bits(g->lodOrigin[2]),
		bits(g->lodRadius));
}

static void print_grids(const char *tag) {
	int i;
	for (i = 0; i < s_worldData.numsurfaces; i++) {
		srfGridMesh_t *g = (srfGridMesh_t *)s_worldData.surfaces[i].data;
		if (g->surfaceType == SF_GRID) print_grid(tag, i, g);
	}
}

static int read_bsp(const char *path) {
	FILE *f = fopen(path, "rb");
	unsigned char *buf;
	long size;
	dheader_t header;
	int i, count, numsurf = 0, stitches;
	dsurface_t *surfs;
	drawVert_t *dv;
	static surfaceType_t other = SF_FACE;
	static const struct { const char *name; int lump; int size; } recs[] = {
		{ "shaders", LUMP_SHADERS, sizeof(dshader_t) }, { "planes", LUMP_PLANES, sizeof(dplane_t) },
		{ "nodes", LUMP_NODES, sizeof(dnode_t) }, { "leafs", LUMP_LEAFS, sizeof(dleaf_t) },
		{ "leafsurfaces", LUMP_LEAFSURFACES, 4 }, { "leafbrushes", LUMP_LEAFBRUSHES, 4 },
		{ "models", LUMP_MODELS, sizeof(dmodel_t) }, { "brushes", LUMP_BRUSHES, sizeof(dbrush_t) },
		{ "brushsides", LUMP_BRUSHSIDES, sizeof(dbrushside_t) }, { "drawverts", LUMP_DRAWVERTS, sizeof(drawVert_t) },
		{ "drawindexes", LUMP_DRAWINDEXES, 4 }, { "fogs", LUMP_FOGS, sizeof(dfog_t) },
		{ "surfaces", LUMP_SURFACES, sizeof(dsurface_t) } };
	if (!f) return 1;
	fseek(f, 0, SEEK_END); size = ftell(f); fseek(f, 0, SEEK_SET);
	buf = malloc(size);
	fread(buf, 1, size, f);
	fclose(f);
	header = *(dheader_t *)buf;
	printf("header %d %d size %d\n", header.version, (int)sizeof(dheader_t), (int)size);
	for (i = 0; i < HEADER_LUMPS; i++)
		printf("lump %d %d %d %08x\n", i, header.lumps[i].fileofs, header.lumps[i].filelen,
			crc32_of(buf + header.lumps[i].fileofs, header.lumps[i].filelen));
	for (i = 0; i < (int)(sizeof(recs) / sizeof(recs[0])); i++) {
		int len = header.lumps[recs[i].lump].filelen;
		if (len % recs[i].size) printf("funny %s\n", recs[i].name);
		printf("count %s %d size %d\n", recs[i].name, len / recs[i].size, recs[i].size);
	}
	printf("sizeof dplane %d dnode %d dleaf %d dmodel %d dbrush %d dbrushside %d dfog %d dshader %d dsurface %d drawvert %d\n",
		(int)sizeof(dplane_t), (int)sizeof(dnode_t), (int)sizeof(dleaf_t), (int)sizeof(dmodel_t), (int)sizeof(dbrush_t),
		(int)sizeof(dbrushside_t), (int)sizeof(dfog_t), (int)sizeof(dshader_t), (int)sizeof(dsurface_t), (int)sizeof(drawVert_t));

	/* R_LoadSurfaces */
	surfs = (dsurface_t *)(buf + header.lumps[LUMP_SURFACES].fileofs);
	count = header.lumps[LUMP_SURFACES].filelen / sizeof(dsurface_t);
	dv = (drawVert_t *)(buf + header.lumps[LUMP_DRAWVERTS].fileofs);
	s_worldData.shaders = (dshader_t *)(buf + header.lumps[LUMP_SHADERS].fileofs);
	s_worldData.numShaders = header.lumps[LUMP_SHADERS].filelen / sizeof(dshader_t);
	s_worldData.surfaces = calloc(count, sizeof(msurface_t));
	s_worldData.numsurfaces = count;
	for (i = 0; i < count; i++) {
		msurface_t *out = &s_worldData.surfaces[i];
		switch (LittleLong(surfs[i].surfaceType)) {
		case MST_PATCH: ParseMesh(&surfs[i], dv, out); numsurf++; break;
		default: out->data = &other; break;
		}
	}
	printf("patches %d\n", numsurf);
	print_grids("pre");
	stitches = 0;
#ifdef PATCH_STITCHING
	R_StitchAllPatches();
#endif
	R_FixSharedVertexLodError();
	print_grids("grid");
	(void)stitches;
	return 0;
}

/* ------------------------------------------------------------------ second slice ---- */

static unsigned fnv_bytes(const unsigned char *p, int n) {
	unsigned h = 2166136261u;
	int i;
	for (i = 0; i < n; i++) h = fnv_byte(h, p[i]);
	return h;
}

static void fill_random(unsigned char *p, int n, unsigned seed) {
	int i;
	g_seed = seed;
	for (i = 0; i < n; i++) p[i] = (unsigned char)(next_random() >> 9);
}

/* R_LoadLightmaps with four shifts: r_mapOverBrightBits - overbrightBits = 1, 2, 0 and 3 */
static void lightmap_case(const char *tag, unsigned char *base, int ofs, int len) {
	static const int mob[4] = { 2, 2, 1, 3 }, obb[4] = { 1, 0, 1, 0 };
	lump_t l;
	int k, i;
	l.fileofs = ofs; l.filelen = len;
	fileBase = base;
	for (k = 0; k < 4; k++) {
		r_mapOverBrightBits_storage.integer = mob[k]; tr.overbrightBits = obb[k];
		tr.numLightmaps = 0; g_imgCalls = 0;
		R_LoadLightmaps(&l);
		printf("lm %s len %d shift %d count %d\n", tag, len, mob[k] - obb[k], tr.numLightmaps);
		for (i = 0; i < g_imgCalls; i++) printf("lmimg %d %08x\n", i, g_imgHash[i]);
	}
}

static void print_vec_bits(const char *tag, const float v[3]) {
	printf(" %s %08x %08x %08x", tag, bits(v[0]), bits(v[1]), bits(v[2]));
}

/* R_LoadLightGrid: the box of the model 0 and the size of a cell come from the arguments */
static void grid_case(int index, const float mn[3], const float mx[3], const float sz[3], int mob, int obb, int delta) {
	bmodel_t bm;
	lump_t l;
	unsigned char *data;
	int n;
	memset(&bm, 0, sizeof(bm));
	VectorCopy(mn, bm.bounds[0]); VectorCopy(mx, bm.bounds[1]);
	s_worldData.bmodels = &bm;
	VectorCopy(sz, s_worldData.lightGridSize);
	r_mapOverBrightBits_storage.integer = mob; tr.overbrightBits = obb;
	l.fileofs = 0; l.filelen = 1;
	fileBase = (byte *)"";
	R_LoadLightGrid(&l); /* a lump of a byte never fits: this only gives the cells */
	n = s_worldData.lightGridBounds[0] * s_worldData.lightGridBounds[1] * s_worldData.lightGridBounds[2];
	data = calloc(1, (n > 0 ? n : 0) * 8 + 64);
	fill_random(data, (n > 0 ? n : 0) * 8 + 8, 777u + (unsigned)index);
	l.fileofs = 0; l.filelen = n * 8 + delta;
	fileBase = data;
	R_LoadLightGrid(&l);
	printf("grid %d bounds %d %d %d n %d", index, s_worldData.lightGridBounds[0], s_worldData.lightGridBounds[1],
		s_worldData.lightGridBounds[2], n);
	print_vec_bits("origin", s_worldData.lightGridOrigin);
	print_vec_bits("size", s_worldData.lightGridSize);
	print_vec_bits("inv", s_worldData.lightGridInverseSize);
	if (s_worldData.lightGridData) printf(" data %08x\n", fnv_bytes(s_worldData.lightGridData, n * 8));
	else printf(" data null\n");
	free(data);
}

static void print_tree(const char *tag) {
	int i, total = s_worldData.numnodes;
	printf("tree %s nodes %d decision %d clusters %d\n", tag, total, s_worldData.numDecisionNodes, s_worldData.numClusters);
	for (i = 0; i < total; i++) {
		mnode_t *n = &s_worldData.nodes[i];
		int parent = n->parent ? (int)(n->parent - s_worldData.nodes) : -1;
		int plane = n->plane ? (int)(n->plane - s_worldData.planes) : -1;
		int c0 = n->children[0] ? (int)(n->children[0] - s_worldData.nodes) : -1;
		int c1 = n->children[1] ? (int)(n->children[1] - s_worldData.nodes) : -1;
		int mark = n->firstmarksurface ? (int)(n->firstmarksurface - s_worldData.marksurfaces) : -1;
		printf("n %d %d %d %d %d %d | %d %d %d | %d %d %d | %d %d %d %d\n", i, n->contents, parent, plane, c0, c1,
			(int)n->mins[0], (int)n->mins[1], (int)n->mins[2], (int)n->maxs[0], (int)n->maxs[1], (int)n->maxs[2],
			n->cluster, n->area, mark, n->nummarksurfaces);
	}
}

static void tree_case(const char *tag, unsigned char *base, int nodeOfs, int nodeLen, int leafOfs, int leafLen) {
	lump_t nl, ll;
	nl.fileofs = nodeOfs; nl.filelen = nodeLen;
	ll.fileofs = leafOfs; ll.filelen = leafLen;
	fileBase = base;
	memset(&s_worldData.nodes, 0, sizeof(s_worldData.nodes));
	s_worldData.numClusters = 0;
	s_worldData.planes = calloc(16, sizeof(cplane_t));
	s_worldData.marksurfaces = calloc(128, sizeof(msurface_t *));
	R_LoadNodesAndLeafs(&nl, &ll);
	print_tree(tag);
}

/* 40 nodes in the layout of a heap and the 41 leafs that fill the free places: a tree of depth 6 */
static void make_tree(unsigned char *out, int *nodeLen, int *leafLen) {
	dnode_t *nodes = (dnode_t *)out;
	dleaf_t *leafs = (dleaf_t *)(out + 40 * sizeof(dnode_t));
	int i, j, k, leaf = 0;
	g_seed = 0x5EED1234u;
	for (i = 0; i < 40; i++) {
		nodes[i].planeNum = i % 8;
		for (j = 0; j < 2; j++) {
			int c = 2 * i + 1 + j;
			nodes[i].children[j] = c < 40 ? c : -1 - leaf++;
		}
		for (k = 0; k < 3; k++) nodes[i].mins[k] = (int)(next_random() % 2001) - 1000;
		for (k = 0; k < 3; k++) nodes[i].maxs[k] = nodes[i].mins[k] + (int)(next_random() % 500);
	}
	for (i = 0; i < 41; i++) {
		leafs[i].cluster = (int)(next_random() % 14) - 1;
		leafs[i].area = (int)(next_random() % 5);
		for (k = 0; k < 3; k++) leafs[i].mins[k] = (int)(next_random() % 2001) - 1000;
		for (k = 0; k < 3; k++) leafs[i].maxs[k] = leafs[i].mins[k] + (int)(next_random() % 500);
		leafs[i].firstLeafSurface = (int)(next_random() % 50);
		leafs[i].numLeafSurfaces = (int)(next_random() % 7);
		leafs[i].firstLeafBrush = (int)(next_random() % 10);
		leafs[i].numLeafBrushes = (int)(next_random() % 3);
	}
	*nodeLen = 40 * (int)sizeof(dnode_t);
	*leafLen = 41 * (int)sizeof(dleaf_t);
}

static int extras(const char *path) {
	FILE *f = fopen(path, "rb");
	unsigned char *buf, *scratch;
	long size;
	dheader_t header;
	int nodeLen, leafLen;
	static const float m0[3] = { -64, -64, -64 }, x0[3] = { 64, 64, 64 }, s0[3] = { 64, 64, 128 };
	static const float m1[3] = { -100, -37.5f, -8 }, x1[3] = { 230.25f, 90, 300 };
	static const float m2[3] = { -1000, -900.5f, -1200 }, x2[3] = { 1800, 1500.75f, 2200 }, s2[3] = { 50, 40, 30 };
	static const float m3[3] = { 10, 10, 10 }, x3[3] = { 500, 500, 500 }, s3[3] = { 100, 100, 100 };
	if (!f) return 1;
	fseek(f, 0, SEEK_END); size = ftell(f); fseek(f, 0, SEEK_SET);
	buf = malloc(size);
	fread(buf, 1, size, f);
	fclose(f);
	header = *(dheader_t *)buf;
	scratch = calloc(1, 4 * 128 * 128 * 3);

	/* lightmaps: the lump of the file, then a lump of one lightmap (the hack of the original reads the
	   second from beyond the lump: zero bytes here), 2.5 lightmaps, nothing */
	lightmap_case("file", buf, header.lumps[LUMP_LIGHTMAPS].fileofs, header.lumps[LUMP_LIGHTMAPS].filelen);
	fill_random(scratch, 49152, 4242u);
	lightmap_case("one", scratch, 0, 49152);
	fill_random(scratch, 49152 * 2 + 1000, 99u);
	lightmap_case("twoandahalf", scratch, 0, 49152 * 2 + 1000);
	lightmap_case("none", scratch, 0, 0);
	r_vertexLight_storage.integer = 1;
	lightmap_case("vertexlight", scratch, 0, 49152 * 2);
	r_vertexLight_storage.integer = 0;

	grid_case(0, m0, x0, s0, 2, 1, 0);
	grid_case(1, m1, x1, s0, 2, 1, 0);
	grid_case(2, m2, x2, s2, 3, 0, 0);
	grid_case(3, m3, x3, s3, 2, 2, 0);
	grid_case(4, m1, x1, s0, 2, 1, 8);

	memset(scratch, 0, 4 * 128 * 128 * 3);
	make_tree(scratch, &nodeLen, &leafLen);
	tree_case("heap", scratch, 0, nodeLen, nodeLen, leafLen);
	tree_case("file", buf, header.lumps[LUMP_NODES].fileofs, header.lumps[LUMP_NODES].filelen,
		header.lumps[LUMP_LEAFS].fileofs, header.lumps[LUMP_LEAFS].filelen);
	return 0;
}
int main(int argc, char **argv) {
	if (argc >= 4 && !strcmp(argv[1], "write")) return write_bsp(atoi(argv[2]), argv[3]);
	if (argc >= 3 && !strcmp(argv[1], "read")) return read_bsp(argv[2]);
	if (argc >= 3 && !strcmp(argv[1], "extras")) return extras(argv[2]);
	fprintf(stderr, "usage: bspgen write <variant> <file> | read <file>\n");
	return 2;
}
