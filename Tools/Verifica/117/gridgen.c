/*
 * Parity driver of the issue #117: runs R_SubdividePatchToGrid, R_GridInsertColumn and
 * R_GridInsertRow of Quake III Arena (the lines of the original, see build.sh) on patches
 * written here and prints, for each, the size, the LOD error tables, the bounds, the
 * FNV-1a 32 of the vertices and a few vertices as hexadecimal float bits.
 * The same patches are built by Tests\Source\DelphiDoom.Tests.MathCore.Patch*.pas.
 */
#include "stubs.h"
#include "grid_original.inc"

static unsigned g_seed;

static unsigned next_random(void) {
	g_seed ^= g_seed << 13;
	g_seed ^= g_seed >> 17;
	g_seed ^= g_seed << 5;
	return g_seed;
}

static unsigned bits(float f) {
	unsigned u;
	memcpy(&u, &f, 4);
	return u;
}

static unsigned fnv_byte(unsigned h, unsigned b) {
	return (h ^ (b & 255)) * 16777619u;
}

static unsigned fnv_float(unsigned h, float f) {
	unsigned u = bits(f);
	h = fnv_byte(h, u);
	h = fnv_byte(h, u >> 8);
	h = fnv_byte(h, u >> 16);
	h = fnv_byte(h, u >> 24);
	return h;
}

static void set_vertex(drawVert_t *v, int i, int j, int w, int h, float x, float y, float z) {
	v->xyz[0] = x; v->xyz[1] = y; v->xyz[2] = z;
	v->st[0] = (float)i / (float)(w - 1);
	v->st[1] = (float)j / (float)(h - 1);
	v->lightmap[0] = v->st[0] * 0.5f;
	v->lightmap[1] = v->st[1] * 0.5f;
	v->normal[0] = v->normal[1] = v->normal[2] = 0;
	v->color[0] = (byte)((i * 37 + j * 91) & 255);
	v->color[1] = (byte)((i * 11 + j * 53 + 7) & 255);
	v->color[2] = (byte)(255 - ((i * 29 + j * 13) & 255));
	v->color[3] = (byte)((i + j) * 17 & 255);
}

static void print_vertex(const char *tag, int index, const drawVert_t *v) {
	printf("%s %d %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %02x%02x%02x%02x\n", tag, index,
		bits(v->xyz[0]), bits(v->xyz[1]), bits(v->xyz[2]), bits(v->st[0]), bits(v->st[1]),
		bits(v->lightmap[0]), bits(v->lightmap[1]), bits(v->normal[0]), bits(v->normal[1]),
		bits(v->normal[2]), v->color[0], v->color[1], v->color[2], v->color[3]);
}

static void print_grid(const char *name, srfGridMesh_t *g) {
	int i, n;
	unsigned h = 2166136261u;
	if (!g) {
		printf("case %s null\n", name);
		return;
	}
	n = g->width * g->height;
	for (i = 0; i < n; i++) {
		const drawVert_t *v = &g->verts[i];
		h = fnv_float(h, v->xyz[0]); h = fnv_float(h, v->xyz[1]); h = fnv_float(h, v->xyz[2]);
		h = fnv_float(h, v->st[0]); h = fnv_float(h, v->st[1]);
		h = fnv_float(h, v->lightmap[0]); h = fnv_float(h, v->lightmap[1]);
		h = fnv_float(h, v->normal[0]); h = fnv_float(h, v->normal[1]); h = fnv_float(h, v->normal[2]);
		h = fnv_byte(h, v->color[0]); h = fnv_byte(h, v->color[1]);
		h = fnv_byte(h, v->color[2]); h = fnv_byte(h, v->color[3]);
	}
	printf("case %s %d %d %08x\n", name, g->width, g->height, h);
	printf("we");
	for (i = 0; i < g->width; i++) printf(" %08x", bits(g->widthLodError[i]));
	printf("\nhe");
	for (i = 0; i < g->height; i++) printf(" %08x", bits(g->heightLodError[i]));
	printf("\nbounds %08x %08x %08x %08x %08x %08x\n", bits(g->meshBounds[0][0]), bits(g->meshBounds[0][1]),
		bits(g->meshBounds[0][2]), bits(g->meshBounds[1][0]), bits(g->meshBounds[1][1]), bits(g->meshBounds[1][2]));
	printf("origin %08x %08x %08x radius %08x lod %08x %08x %08x %08x\n", bits(g->localOrigin[0]),
		bits(g->localOrigin[1]), bits(g->localOrigin[2]), bits(g->meshRadius), bits(g->lodOrigin[0]),
		bits(g->lodOrigin[1]), bits(g->lodOrigin[2]), bits(g->lodRadius));
	print_vertex("first", 0, &g->verts[0]);
	print_vertex("mid", n / 2, &g->verts[n / 2]);
	print_vertex("last", n - 1, &g->verts[n - 1]);
}

static drawVert_t g_points[MAX_PATCH_SIZE * MAX_PATCH_SIZE];

static srfGridMesh_t *subdivide(const char *name, int w, int h, float subdivisions) {
	srfGridMesh_t *g;
	r_subdivisions->value = subdivisions;
	g = R_SubdividePatchToGrid(w, h, g_points);
	print_grid(name, g);
	return g;
}

/* z = (i == 1 ? a : 0) + (j == 1 ? b : 0) on a 64 unit lattice */
static void make_bulge(int w, int h, float a, float b) {
	int i, j;
	for (j = 0; j < h; j++)
		for (i = 0; i < w; i++)
			set_vertex(&g_points[j * w + i], i, j, w, h, (float)(i * 64), (float)(j * 64),
				(i % 2 == 1 ? a : 0.0f) + (j % 2 == 1 ? b : 0.0f));
}

static void make_random(int w, int h, int range) {
	int i, j;
	for (j = 0; j < h; j++)
		for (i = 0; i < w; i++) {
			float x = (float)((int)(next_random() % 2049) - 1024) / 8.0f;
			float y = (float)((int)(next_random() % 2049) - 1024) / 8.0f;
			float z = (float)((int)(next_random() % (unsigned)(range * 2 + 1)) - range) / 8.0f;
			set_vertex(&g_points[j * w + i], i, j, w, h, (float)(i * 64) + x, (float)(j * 64) + y, z);
		}
}

int main(void) {
	srfGridMesh_t *g, *g2;
	int n, w, h, i, j;
	static const float subs[5] = { 1.0f, 2.0f, 4.0f, 8.0f, 16.0f };
	static const int sizes[6] = { 3, 5, 7, 9, 11, 17 };

	make_bulge(3, 3, 0.0f, 0.0f);
	subdivide("flat3x3", 3, 3, 4.0f);

	make_bulge(3, 3, 96.0f, 48.0f);
	g = subdivide("arc3x3_s4", 3, 3, 4.0f);
	subdivide("arc3x3_s1", 3, 3, 1.0f);
	subdivide("arc3x3_s16", 3, 3, 16.0f);
	subdivide("arc3x3_s0", 3, 3, 0.0f);

	make_bulge(3, 5, 128.0f, -96.0f);
	subdivide("w3h5", 3, 5, 2.0f);
	make_bulge(5, 3, 128.0f, -96.0f);
	subdivide("w5h3", 5, 3, 2.0f);
	make_bulge(9, 9, 300.0f, 200.0f);
	subdivide("w9h9", 9, 9, 1.0f);
	make_bulge(3, 3, 6000.0f, 6000.0f);
	subdivide("huge3x3", 3, 3, 0.25f);

	/* a column that is a straight line and a row that is not: only some lines are culled */
	make_bulge(5, 3, 0.0f, 90.0f);
	subdivide("flatrows", 5, 3, 4.0f);
	make_bulge(3, 5, 90.0f, 0.0f);
	subdivide("flatcols", 3, 5, 4.0f);

	/* width wraps: first column = last column on a closed ring */
	{
		static const float ring[5][2] = { {64, 0}, {64, 64}, {-64, 64}, {-64, -64}, {64, 0} };
		w = 5; h = 3;
		for (j = 0; j < h; j++)
			for (i = 0; i < w; i++)
				set_vertex(&g_points[j * w + i], i, j, w, h, ring[i][0], ring[i][1], (float)(j * 64));
		subdivide("wrapwidth", w, h, 4.0f);
		/* the same ring as a column: height wraps */
		w = 3; h = 5;
		for (j = 0; j < h; j++)
			for (i = 0; i < w; i++)
				set_vertex(&g_points[j * w + i], i, j, w, h, ring[j][0], ring[j][1], (float)(i * 64));
		subdivide("wrapheight", w, h, 4.0f);
	}

	/* degenerate: every control point at the same place */
	for (i = 0; i < 9; i++) set_vertex(&g_points[i], i % 3, i / 3, 3, 3, 10.0f, 20.0f, 30.0f);
	subdivide("point3x3", 3, 3, 4.0f);

	/* degenerate: a line (two rows equal, third apart) */
	for (j = 0; j < 3; j++)
		for (i = 0; i < 3; i++)
			set_vertex(&g_points[j * 3 + i], i, j, 3, 3, (float)(i * 64), 0.0f, 0.0f);
	subdivide("line3x3", 3, 3, 4.0f);

	/* the limit of the grid size: a 31x31 patch with a large noise at 1 unit of error */
	g_seed = 0x2545F491u;
	make_random(31, 31, 4000);
	subdivide("limit31", 31, 31, 1.0f);
	make_random(31, 3, 4000);
	subdivide("limit32x3", 31, 3, 1.0f);

	/* random patches */
	g_seed = 0x12345678u;
	for (n = 0; n < 24; n++) {
		char name[32];
		w = sizes[next_random() % 6];
		h = sizes[next_random() % 6];
		if (w > 11) w = 11;
		make_random(w, h, 200 + (int)(next_random() % 600));
		sprintf(name, "random%02d_%dx%d", n, w, h);
		subdivide(name, w, h, subs[next_random() % 5]);
	}

	/* inserted columns and rows on the arc */
	r_subdivisions->value = 4.0f;
	make_bulge(3, 3, 96.0f, 48.0f);
	g = R_SubdividePatchToGrid(3, 3, g_points);
	g2 = R_GridInsertColumn(g, 2, 1, (float[]){ 70.5f, 31.25f, 12.0f }, 0.5f);
	print_grid("insertcol_2_1", g2);
	g2 = R_GridInsertRow(g2, 1, 2, (float[]){ -8.0f, 4.5f, 9.0f }, 0.25f);
	print_grid("insertrow_1_2", g2);
	g2 = R_GridInsertColumn(g2, 3, 3, (float[]){ 1.0f, 2.0f, 3.0f }, 0.125f);
	print_grid("insertcol_3_3", g2);
	/* the grid that cannot grow any more: NULL */
	make_random(31, 31, 4000);
	r_subdivisions->value = 1.0f;
	g = R_SubdividePatchToGrid(31, 31, g_points);
	w = g->width;
	h = g->height;
	printf("limit31 width %d height %d\n", w, h);
	g2 = R_GridInsertColumn(g, 2, 1, (float[]){ 0, 0, 0 }, 1.0f);
	print_grid(w >= MAX_GRID_SIZE ? "insertcol_full" : "insertcol_notfull", g2);
	g = R_SubdividePatchToGrid(31, 31, g_points);
	g2 = R_GridInsertRow(g, 2, 1, (float[]){ 0, 0, 0 }, 1.0f);
	print_grid(h >= MAX_GRID_SIZE ? "insertrow_full" : "insertrow_notfull", g2);
	return 0;
}
