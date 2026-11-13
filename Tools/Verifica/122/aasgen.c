/*
 * Parity tool of the issue #122 (AAS of Quake III Arena).
 *
 * It links the REAL be_aas_file.c and be_aas_sample.c of code/botlib (included below, read only, copied by
 * build.sh) with the stubs of the folder stub/. It builds small .aas files in memory (a row of boxes of 64
 * units: the same recipe as Tests/Source/DelphiDoom.Tests.Aas.Sample.pas), serves them to AAS_LoadAASFile
 * through the stubs of botimport and runs the sampling functions on points of a fixed seed. Nothing is read
 * from a game: no .aas file of any game is used.
 *
 *   aasgen        prints the golden file (Tests/Data/Aas/aas.golden.txt) on the standard output
 *   aasgen dump <variant> <file>   writes the sample file of a variant
 *
 * Lines: "P<level>|text" is botimport.Print (bytes below 32, above 126 and the backslash as \xNN); floats are
 * printed as the 8 hexadecimal digits of their bits.
 */
#include "game/q_shared.h"
#include "game/botlib.h"
#include "botlib/aasfile.h"
#include "game/be_aas.h"
#include "botlib/be_aas_funcs.h"
#include "botlib/be_interface.h"
#include "botlib/be_aas_def.h"

#include "vmath.inc"
#include "aaserror.inc"
#include "areareach.inc"

#include "botlib/be_aas_file.c"
#include "botlib/be_aas_sample.c"

botlib_import_t botimport;
int bot_developer;
aas_t aasworld;

/* ------------------------------------------------------------ output and stubs */

static void print_escaped(const char *s)
{
	for (; *s; s++)
	{
		unsigned char c = (unsigned char) *s;
		if (c < 32 || c > 126 || c == '\\') printf("\\x%02X", c);
		else putchar(c);
	}
}

static void Stub_Print(int type, char *fmt, ...)
{
	char text[4096];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(text, sizeof(text), fmt, ap);
	va_end(ap);
	printf("P%d|", type);
	print_escaped(text);
	putchar('\n');
}

static unsigned char *g_file;
static int g_size, g_pos;
static const char *g_name = "maps/sample.aas";
static char g_checksum[32];

static int Stub_FOpenFile(const char *qpath, fileHandle_t *file, fsMode_t mode)
{
	if (mode != FS_READ || strcmp(qpath, g_name) != 0) { *file = 0; return -1; }
	*file = 1;
	g_pos = 0;
	return g_size;
}
static int Stub_Read(void *buffer, int len, fileHandle_t f)
{
	int n = g_size - g_pos;
	if (n > len) n = len;
	if (n < 0) n = 0;
	memcpy(buffer, g_file + g_pos, n);
	g_pos += n;
	return n;
}
static int Stub_Write(const void *buffer, int len, fileHandle_t f) { return 0; }
static void Stub_Close(fileHandle_t f) {}
static int Stub_Seek(fileHandle_t f, long offset, int origin) { g_pos = (int) offset; return 0; }

float LibVarValue(char *var_name, char *value) { return (float) atof(value); }
char *LibVarGetString(char *var_name) { return g_checksum; }
qboolean AAS_EntityCollision(int entnum, vec3_t start, vec3_t boxmins, vec3_t boxmaxs, vec3_t end,
								int contentmask, bsp_trace_t *trace) { return qfalse; }

static unsigned fb(float f) { unsigned u; memcpy(&u, &f, 4); return u; }

static unsigned crc_table[256];
static unsigned crc32(const unsigned char *p, int n)
{
	unsigned c = 0xFFFFFFFFu;
	int i, k;
	if (!crc_table[1])
		for (i = 0; i < 256; i++)
		{
			unsigned v = i;
			for (k = 0; k < 8; k++) v = (v & 1) ? 0xEDB88320u ^ (v >> 1) : v >> 1;
			crc_table[i] = v;
		}
	for (i = 0; i < n; i++) c = crc_table[(c ^ p[i]) & 255] ^ (c >> 8);
	return ~c;
}

/* ------------------------------------------------------------ the sample file (the recipe of Sample.pas) */

#define SAMPLE_CHECKSUM 0x12345678

static aas_bbox_t s_bboxes[2];
static aas_vertex_t s_vertexes[64];
static aas_plane_t s_planes[64];
static aas_edge_t s_edges[256];
static aas_edgeindex_t s_edgeindex[512];
static aas_face_t s_faces[128];
static aas_faceindex_t s_faceindex[128];
static aas_area_t s_areas[16];
static aas_areasettings_t s_settings[16];
static aas_reachability_t s_reach[64];
static aas_node_t s_nodes[32];
static aas_portal_t s_portals[4];
static aas_portalindex_t s_portalindex[2];
static aas_cluster_t s_clusters[4];
static int n_vertexes, n_planes, n_edges, n_edgeindex, n_faces, n_faceindex, n_areas_total, n_settings, n_reach,
	n_nodes, n_portals, n_clusters;
static int s_areas_count;
static int s_skew;

static void vec(float *v, float x, float y, float z) { v[0] = x; v[1] = y; v[2] = z; }
static int vtx(int x, int y, int z) { return 1 + x * 4 + y * 2 + z; }

static void add_pair(float nx, float ny, float nz, float dist, int type)
{
	vec(s_planes[n_planes].normal, nx, ny, nz);
	s_planes[n_planes].dist = dist;
	s_planes[n_planes].type = type;
	n_planes++;
	vec(s_planes[n_planes].normal, -nx, -ny, -nz);
	s_planes[n_planes].dist = -dist;
	s_planes[n_planes].type = type;
	n_planes++;
}

static int add_node(int plane, int front, int back)
{
	s_nodes[n_nodes].planenum = plane;
	s_nodes[n_nodes].children[0] = front;
	s_nodes[n_nodes].children[1] = back;
	return n_nodes++;
}

static int root_x_pair;

static int build_x(int low, int high)
{
	int middle, node, front, back, plane;
	if (high - low == 1) return -(low + 1);
	middle = (low + high) / 2;
	if (s_skew && low == 0 && high == s_areas_count) plane = 2 * root_x_pair;
	else plane = 2 * (4 + middle);
	node = add_node(plane, 0, 0);
	front = build_x(middle, high);
	back = build_x(low, middle);
	s_nodes[node].children[0] = front;
	s_nodes[node].children[1] = back;
	return node;
}

static int find_edge(int first, int second)
{
	int i;
	for (i = 1; i < n_edges; i++)
	{
		if (s_edges[i].v[0] == first && s_edges[i].v[1] == second) return i;
		if (s_edges[i].v[0] == second && s_edges[i].v[1] == first) return -i;
	}
	s_edges[n_edges].v[0] = first;
	s_edges[n_edges].v[1] = second;
	return n_edges++;
}

static void add_face(int axis, int coord, int u0, int u1, int v0, int v1, int plane, int flags, int front, int back)
{
	int u = (axis + 1) % 3, v = (axis + 2) % 3, i, points[4], grid[3];
	int cu[4] = { u0, u0, u1, u1 }, cv[4] = { v0, v1, v1, v0 };
	for (i = 0; i < 4; i++)
	{
		grid[axis] = coord;
		grid[u] = cu[i];
		grid[v] = cv[i];
		points[i] = vtx(grid[0], grid[1], grid[2]);
	}
	s_faces[n_faces].planenum = plane;
	s_faces[n_faces].faceflags = flags;
	s_faces[n_faces].numedges = 4;
	s_faces[n_faces].firstedge = n_edgeindex;
	s_faces[n_faces].frontarea = front;
	s_faces[n_faces].backarea = back;
	for (i = 0; i < 4; i++) s_edgeindex[n_edgeindex++] = find_edge(points[i], points[(i + 1) % 4]);
	n_faces++;
}

static void build_sample(int variant)
{
	int areas = variant == 1 ? 6 : 4, x, y, z, a, nb, cluster_one = 0, cluster_two = 0, contents, flags, count, facenum;
	int node_y1, node_z0, node_z1, node_y0, root;
	s_areas_count = areas;
	s_skew = variant == 1;
	n_vertexes = n_planes = n_edges = n_edgeindex = n_faces = n_faceindex = n_settings = n_reach = n_nodes = 0;
	n_portals = n_clusters = 0;
	memset(s_bboxes, 0, sizeof(s_bboxes)); memset(s_vertexes, 0, sizeof(s_vertexes));
	memset(s_planes, 0, sizeof(s_planes)); memset(s_edges, 0, sizeof(s_edges));
	memset(s_edgeindex, 0, sizeof(s_edgeindex)); memset(s_faces, 0, sizeof(s_faces));
	memset(s_faceindex, 0, sizeof(s_faceindex)); memset(s_areas, 0, sizeof(s_areas));
	memset(s_settings, 0, sizeof(s_settings)); memset(s_reach, 0, sizeof(s_reach));
	memset(s_nodes, 0, sizeof(s_nodes)); memset(s_portals, 0, sizeof(s_portals));
	memset(s_clusters, 0, sizeof(s_clusters));

	s_bboxes[0].presencetype = PRESENCE_NORMAL; vec(s_bboxes[0].mins, -15, -15, -24); vec(s_bboxes[0].maxs, 15, 15, 32);
	s_bboxes[1].presencetype = PRESENCE_CROUCH; vec(s_bboxes[1].mins, -15, -15, -24); vec(s_bboxes[1].maxs, 15, 15, 8);

	vec(s_vertexes[n_vertexes++], 0, 0, 0);
	for (x = 0; x <= areas; x++) for (y = 0; y < 2; y++) for (z = 0; z < 2; z++)
		vec(s_vertexes[n_vertexes++], (float)(x * 64), (float)(y * 64), (float)(z * 64));

	add_pair(0, 1, 0, 0, 1);
	add_pair(0, 1, 0, 64, 1);
	add_pair(0, 0, 1, 0, 2);
	add_pair(0, 0, 1, 64, 2);
	for (x = 0; x <= areas; x++) add_pair(1, 0, 0, (float)(x * 64), 0);
	root_x_pair = 4 + areas + 1;
	add_pair(0.75f, 0.5f, 0, (float)((areas / 2) * 48 + 16), 3);

	add_node(0, 0, 0);
	node_y0 = add_node(0, 0, 0);
	node_y1 = add_node(2 * 1, 0, 0);
	node_z0 = add_node(2 * 2, 0, 0);
	node_z1 = add_node(2 * 3, 0, 0);
	s_nodes[node_y0].children[0] = node_y1; s_nodes[node_y0].children[1] = 0;
	s_nodes[node_y1].children[0] = 0; s_nodes[node_y1].children[1] = node_z0;
	s_nodes[node_z0].children[0] = node_z1; s_nodes[node_z0].children[1] = 0;
	root = build_x(0, areas);
	s_nodes[node_z1].children[0] = 0; s_nodes[node_z1].children[1] = root;

	n_faces = 1; n_edges = 1; n_edgeindex = 1;
	for (x = 0; x <= areas; x++)
		add_face(0, x, 0, 1, 0, 1, 2 * (4 + x), (x == 0 || x == areas) ? FACE_SOLID : 0, x < areas ? x + 1 : 0, x > 0 ? x : 0);
	for (a = 1; a <= areas; a++)
	{
		add_face(1, 0, 0, 1, a - 1, a, 0, FACE_SOLID, a, 0);
		add_face(1, 1, 0, 1, a - 1, a, 2, FACE_SOLID, 0, a);
		add_face(2, 0, a - 1, a, 0, 1, 4, FACE_SOLID | FACE_GROUND, a, 0);
		add_face(2, 1, a - 1, a, 0, 1, 6, FACE_SOLID, 0, a);
	}

	n_faceindex = 1;
	n_areas_total = areas + 1;
	for (a = 1; a <= areas; a++)
	{
		s_areas[a].areanum = a;
		s_areas[a].numfaces = 6;
		s_areas[a].firstface = n_faceindex;
		vec(s_areas[a].mins, (float)((a - 1) * 64), 0, 0);
		vec(s_areas[a].maxs, (float)(a * 64), 64, 64);
		vec(s_areas[a].center, (float)(a * 64 - 32), 32, 32);
		s_faceindex[n_faceindex++] = a;
		s_faceindex[n_faceindex++] = -(a + 1);
		s_faceindex[n_faceindex++] = areas + 1 + (a - 1) * 4 + 1;
		s_faceindex[n_faceindex++] = -(areas + 1 + (a - 1) * 4 + 2);
		s_faceindex[n_faceindex++] = areas + 1 + (a - 1) * 4 + 3;
		s_faceindex[n_faceindex++] = -(areas + 1 + (a - 1) * 4 + 4);
	}

	n_settings = 1;
	n_reach = 1;
	for (a = 1; a <= areas; a++)
	{
		switch (a)
		{
			case 1: contents = 0; flags = AREA_GROUNDED; break;
			case 2: contents = AREACONTENTS_WATER; flags = AREA_GROUNDED | AREA_LIQUID; break;
			case 3: contents = AREACONTENTS_JUMPPAD; flags = AREA_GROUNDED | AREA_LADDER; break;
			case 4: contents = AREACONTENTS_CLUSTERPORTAL; flags = AREA_GROUNDED; break;
			case 5: contents = AREACONTENTS_DONOTENTER; flags = AREA_GROUNDED; break;
			default: contents = AREACONTENTS_TELEPORTER | AREACONTENTS_LAVA; flags = AREA_GROUNDED | AREA_BRIDGE; break;
		}
		s_settings[a].contents = contents;
		s_settings[a].areaflags = flags;
		s_settings[a].presencetype = PRESENCE_NORMAL | PRESENCE_CROUCH;
		if (a == 2) s_settings[a].presencetype = PRESENCE_CROUCH;
		if (variant == 1 && a == 5) s_settings[a].presencetype = PRESENCE_NONE;
		if (a == 4) { s_settings[a].cluster = -1; s_settings[a].clusterareanum = 3; }
		else if (a <= 2) { s_settings[a].cluster = 1; s_settings[a].clusterareanum = ++cluster_one; }
		else { s_settings[a].cluster = 2; s_settings[a].clusterareanum = ++cluster_two; }
		s_settings[a].firstreachablearea = n_reach;
		count = 0;
		for (nb = a - 1; nb <= a + 1; nb++)
		{
			if (nb == a || nb < 1 || nb > areas) continue;
			facenum = nb > a ? a + 1 : a;
			s_reach[n_reach].areanum = nb;
			s_reach[n_reach].facenum = facenum;
			s_reach[n_reach].edgenum = s_edgeindex[s_faces[facenum].firstedge];
			vec(s_reach[n_reach].start, (float)(a * 64 - 32), 32, 32);
			vec(s_reach[n_reach].end, (float)(nb * 64 - 32), 32, 32);
			s_reach[n_reach].traveltype = TRAVEL_WALK;
			s_reach[n_reach].traveltime = 100 + a * 10 + nb;
			n_reach++;
			count++;
		}
		s_settings[a].numreachableareas = count;
		n_settings++;
	}
	n_portals = 2;
	s_portals[1].areanum = 4; s_portals[1].frontcluster = 1; s_portals[1].backcluster = 2;
	s_portals[1].clusterareanum[0] = 3; s_portals[1].clusterareanum[1] = 1;
	s_portalindex[0] = 1; s_portalindex[1] = 1;
	n_clusters = 3;
	s_clusters[1].numareas = cluster_one + 1; s_clusters[1].numreachabilityareas = cluster_one + 1;
	s_clusters[1].numportals = 1; s_clusters[1].firstportal = 0;
	s_clusters[2].numareas = cluster_two + 1; s_clusters[2].numreachabilityareas = cluster_two + 1;
	s_clusters[2].numportals = 1; s_clusters[2].firstportal = 1;
}

static unsigned char s_bytes[8192];

typedef struct { const void *data; int length; } lumpsrc_t;

static int layout_sample(int version, int gap)
{
	aas_header_t header;
	lumpsrc_t lumps[AAS_LUMPS];
	int i, offset;
	lumps[AASLUMP_BBOXES].data = s_bboxes; lumps[AASLUMP_BBOXES].length = 2 * sizeof(aas_bbox_t);
	lumps[AASLUMP_VERTEXES].data = s_vertexes; lumps[AASLUMP_VERTEXES].length = n_vertexes * sizeof(aas_vertex_t);
	lumps[AASLUMP_PLANES].data = s_planes; lumps[AASLUMP_PLANES].length = n_planes * sizeof(aas_plane_t);
	lumps[AASLUMP_EDGES].data = s_edges; lumps[AASLUMP_EDGES].length = n_edges * sizeof(aas_edge_t);
	lumps[AASLUMP_EDGEINDEX].data = s_edgeindex; lumps[AASLUMP_EDGEINDEX].length = n_edgeindex * sizeof(aas_edgeindex_t);
	lumps[AASLUMP_FACES].data = s_faces; lumps[AASLUMP_FACES].length = n_faces * sizeof(aas_face_t);
	lumps[AASLUMP_FACEINDEX].data = s_faceindex; lumps[AASLUMP_FACEINDEX].length = n_faceindex * sizeof(aas_faceindex_t);
	lumps[AASLUMP_AREAS].data = s_areas; lumps[AASLUMP_AREAS].length = n_areas_total * sizeof(aas_area_t);
	lumps[AASLUMP_AREASETTINGS].data = s_settings; lumps[AASLUMP_AREASETTINGS].length = n_settings * sizeof(aas_areasettings_t);
	lumps[AASLUMP_REACHABILITY].data = s_reach; lumps[AASLUMP_REACHABILITY].length = n_reach * sizeof(aas_reachability_t);
	lumps[AASLUMP_NODES].data = s_nodes; lumps[AASLUMP_NODES].length = n_nodes * sizeof(aas_node_t);
	lumps[AASLUMP_PORTALS].data = s_portals; lumps[AASLUMP_PORTALS].length = n_portals * sizeof(aas_portal_t);
	lumps[AASLUMP_PORTALINDEX].data = s_portalindex; lumps[AASLUMP_PORTALINDEX].length = 2 * sizeof(aas_portalindex_t);
	lumps[AASLUMP_CLUSTERS].data = s_clusters; lumps[AASLUMP_CLUSTERS].length = n_clusters * sizeof(aas_cluster_t);
	memset(&header, 0, sizeof(header));
	memset(s_bytes, 0, sizeof(s_bytes));
	header.ident = AASID;
	header.version = version;
	header.bspchecksum = SAMPLE_CHECKSUM;
	offset = sizeof(aas_header_t);
	for (i = 0; i < AAS_LUMPS; i++)
	{
		if (gap && i == AASLUMP_FACES) offset += gap;
		header.lumps[i].fileofs = offset;
		header.lumps[i].filelen = lumps[i].length;
		if (lumps[i].length) memcpy(s_bytes + offset, lumps[i].data, lumps[i].length);
		offset += lumps[i].length;
	}
	if (version == AASVERSION) AAS_DData((unsigned char *) &header + 8, sizeof(aas_header_t) - 8);
	memcpy(s_bytes, &header, sizeof(header));
	return offset;
}

/* ------------------------------------------------------------ the random numbers (xorshift32) */

static unsigned rng;
static unsigned next_random(void)
{
	rng ^= rng << 13;
	rng ^= rng >> 17;
	rng ^= rng << 5;
	return rng;
}
static int rint_(int n) { return (int) (next_random() % (unsigned) n); }

static void random_point(vec3_t p, int areas)
{
	p[0] = (float) (rint_((areas * 64 + 128) * 8) - 512) / 8.0f;
	p[1] = (float) (rint_(1024) - 256) / 8.0f;
	p[2] = (float) (rint_(1024) - 256) / 8.0f;
}

static void print_vec(const char *tag, vec3_t v) { printf(" %s%08x %08x %08x", tag, fb(v[0]), fb(v[1]), fb(v[2])); }

static int face_index(aas_face_t *face) { return face ? (int) (face - aasworld.faces) : 0; }

static void sample(void)
{
	int i, k, a, presence, cluster, areas = aasworld.numareas - 1, n, areaslist[16], found[8], presences[2] = { PRESENCE_NORMAL, PRESENCE_CROUCH };
	vec3_t p, q, mins, maxs, points[16], normal;
	aas_trace_t trace;
	aas_areainfo_t info;
	float dist;

	aasworld.initialized = 1;
	AAS_InitAASLinkHeap();
	AAS_InitAASLinkedEntities();
	rng = 2463534242u;

	for (i = 0; i < 120; i++)
	{
		random_point(p, areas);
		a = AAS_PointAreaNum(p);
		presence = AAS_PointPresenceType(p);
		cluster = a > 0 ? AAS_AreaCluster(a) : 0;
		printf("pt %d", i); print_vec("p", p);
		printf(" area %d presence %d cluster %d", a, presence, cluster);
		if (a > 0 && aasworld.areasettings[a].cluster < 0) printf(" reach P");
		else printf(" reach %d", AAS_PointReachabilityAreaIndex(p));
		if (a > 0)
		{
			n = AAS_AreaInfo(a, &info);
			printf(" info %d %d %d %d %d", n, info.contents, info.flags, info.presencetype, info.cluster);
			print_vec("a", info.mins); print_vec("b", info.maxs); print_vec("c", info.center);
		}
		putchar('\n');
	}

	for (i = 0; i < 80; i++)
	{
		random_point(p, areas);
		random_point(q, areas);
		n = AAS_TraceAreas(p, q, areaslist, points, 16);
		printf("ta %d", i); print_vec("s", p); print_vec("e", q); printf(" n %d", n);
		for (k = 0; k < n; k++) { printf(" %d", areaslist[k]); print_vec("", points[k]); }
		putchar('\n');
		n = AAS_TraceAreas(p, q, areaslist, NULL, 2);
		printf("ta2 %d n %d %d %d\n", i, n, areaslist[0], n > 1 ? areaslist[1] : 0);
		for (k = 0; k < 2; k++)
		{
			trace = AAS_TraceClientBBox(p, q, presences[k], -1);
			printf("tb %d %d solid %d fraction %08x", i, presences[k], trace.startsolid, fb(trace.fraction));
			print_vec("end", trace.endpos);
			printf(" ent %d area %d last %d plane %d endface %d\n", trace.ent, trace.area, trace.lastarea,
				trace.planenum, face_index(AAS_TraceEndFace(&trace)));
		}
	}

	for (i = 0; i < 60; i++)
	{
		int f = 1 + rint_(aasworld.numfaces - 1);
		random_point(p, areas);
		printf("face %d f %d", i, f); print_vec("p", p);
		printf(" pif %d pif0 %d inf %d", AAS_PointInsideFace(f, p, 0.01f), AAS_PointInsideFace(f, p, 0.0f),
			AAS_InsideFace(&aasworld.faces[f], aasworld.planes[aasworld.faces[f].planenum].normal, p, 0.01f));
		AAS_FacePlane(f, normal, &dist);
		print_vec("n", normal); printf(" d %08x", fb(dist));
		a = 1 + rint_(areas);
		printf(" ground %d %d\n", a, face_index(AAS_AreaGroundFace(a, p)));
	}

	for (i = 0; i < 60; i++)
	{
		int plane = rint_(aasworld.numplanes);
		random_point(mins, areas);
		maxs[0] = mins[0] + (float) rint_(320) / 8.0f;
		maxs[1] = mins[1] + (float) rint_(320) / 8.0f;
		maxs[2] = mins[2] + (float) rint_(320) / 8.0f;
		printf("box %d", i); print_vec("m", mins); print_vec("x", maxs);
		n = AAS_BBoxAreas(mins, maxs, found, 8);
		printf(" n8 %d", n);
		for (k = 0; k < n; k++) printf(" %d", found[k]);
		n = AAS_BBoxAreas(mins, maxs, found, 2);
		printf(" n2 %d", n);
		for (k = 0; k < n; k++) printf(" %d", found[k]);
		printf(" plane %d side2 %d side %d", plane, AAS_BoxOnPlaneSide2(mins, maxs, &aasworld.planes[plane]),
			AAS_BoxOnPlaneSide(mins, maxs, &aasworld.planes[plane]));
		AAS_PresenceTypeBoundingBox(presences[i & 1], mins, maxs);
		printf(" od0 %08x od1 %08x\n", fb(AAS_BoxOriginDistanceFromPlane(aasworld.planes[plane].normal, mins, maxs, 0)),
			fb(AAS_BoxOriginDistanceFromPlane(aasworld.planes[plane].normal, mins, maxs, 1)));
	}

	for (a = 0; a <= areas + 2; a++)
	{
		presence = AAS_AreaPresenceType(a);
		cluster = AAS_AreaCluster(a);
		k = AAS_AreaReachability(a);
		printf("area %d presence %d cluster %d reach %d", a, presence, cluster, k);
		if (a <= areas)
			printf(" grounded %d ladder %d liquid %d swim %d lava %d slime %d jumppad %d teleporter %d portal %d donotenter %d",
				!!AAS_AreaGrounded(a), !!AAS_AreaLadder(a), !!AAS_AreaLiquid(a), !!AAS_AreaSwim(a),
				!!AAS_AreaLava(a), !!AAS_AreaSlime(a), !!AAS_AreaJumpPad(a), !!AAS_AreaTeleporter(a),
				!!AAS_AreaClusterPortal(a), !!AAS_AreaDoNotEnter(a));
		putchar('\n');
	}
	for (k = 2; k <= 4; k++)
	{
		AAS_PresenceTypeBoundingBox(k, mins, maxs);
		printf("bbox %d", k); print_vec("m", mins); print_vec("x", maxs); putchar('\n');
	}
	printf("reachabilityareas %d\n", AAS_PointReachabilityAreaIndex(NULL));
	AAS_FreeAASLinkedEntities();
	AAS_FreeAASLinkHeap();
}

static unsigned lump_crc(int i, void *data, int length) { return length ? crc32((const unsigned char *) data, length) : 0; }

static void run_case(int variant, int mutation)
{
	int size, version = variant == 2 ? AASVERSION_OLD : AASVERSION, gap = variant == 3 ? 16 : 0, code, i;
	build_sample(variant == 2 || variant == 3 ? 0 : variant);
	size = layout_sample(version, gap);
	if (mutation == 1) s_bytes[0] ^= 1;
	if (mutation == 2) { int v = 6; memcpy(s_bytes + 4, &v, 4); }
	g_file = s_bytes;
	g_size = size;
	sprintf(g_checksum, "%d", mutation == 3 ? SAMPLE_CHECKSUM + 1 : SAMPLE_CHECKSUM);
	printf("case %d %d size %d crc %08x\n", variant, mutation, size, crc32(s_bytes, size));
	code = AAS_LoadAASFile(mutation == 4 ? "maps/other.aas" : (char *) g_name);
	printf("result %d\n", code);
	if (code != BLERR_NOERROR) return;
	printf("hdr %d\n", aasworld.bspchecksum);
	printf("counts %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n", aasworld.numbboxes, aasworld.numvertexes,
		aasworld.numplanes, aasworld.numedges, aasworld.edgeindexsize, aasworld.numfaces, aasworld.faceindexsize,
		aasworld.numareas, aasworld.numareasettings, aasworld.reachabilitysize, aasworld.numnodes, aasworld.numportals,
		aasworld.portalindexsize, aasworld.numclusters);
	printf("crcs %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x\n",
		lump_crc(0, aasworld.bboxes, aasworld.numbboxes * sizeof(aas_bbox_t)),
		lump_crc(1, aasworld.vertexes, aasworld.numvertexes * sizeof(aas_vertex_t)),
		lump_crc(2, aasworld.planes, aasworld.numplanes * sizeof(aas_plane_t)),
		lump_crc(3, aasworld.edges, aasworld.numedges * sizeof(aas_edge_t)),
		lump_crc(4, aasworld.edgeindex, aasworld.edgeindexsize * sizeof(aas_edgeindex_t)),
		lump_crc(5, aasworld.faces, aasworld.numfaces * sizeof(aas_face_t)),
		lump_crc(6, aasworld.faceindex, aasworld.faceindexsize * sizeof(aas_faceindex_t)),
		lump_crc(7, aasworld.areas, aasworld.numareas * sizeof(aas_area_t)),
		lump_crc(8, aasworld.areasettings, aasworld.numareasettings * sizeof(aas_areasettings_t)),
		lump_crc(9, aasworld.reachability, aasworld.reachabilitysize * sizeof(aas_reachability_t)),
		lump_crc(10, aasworld.nodes, aasworld.numnodes * sizeof(aas_node_t)),
		lump_crc(11, aasworld.portals, aasworld.numportals * sizeof(aas_portal_t)),
		lump_crc(12, aasworld.portalindex, aasworld.portalindexsize * sizeof(aas_portalindex_t)),
		lump_crc(13, aasworld.clusters, aasworld.numclusters * sizeof(aas_cluster_t)));
	(void) i;
	sample();
}

int main(int argc, char **argv)
{
	botimport.Print = Stub_Print;
	botimport.FS_FOpenFile = Stub_FOpenFile;
	botimport.FS_Read = Stub_Read;
	botimport.FS_Write = Stub_Write;
	botimport.FS_FCloseFile = Stub_Close;
	botimport.FS_Seek = Stub_Seek;
	if (argc == 4 && strcmp(argv[1], "dump") == 0)
	{
		int variant = atoi(argv[2]), size;
		FILE *f;
		build_sample(variant == 2 || variant == 3 ? 0 : variant);
		size = layout_sample(variant == 2 ? AASVERSION_OLD : AASVERSION, variant == 3 ? 16 : 0);
		f = fopen(argv[3], "wb");
		fwrite(s_bytes, 1, size, f);
		fclose(f);
		return 0;
	}
	printf("sizes header %d bbox %d vertex %d plane %d edge %d face %d area %d settings %d reach %d node %d portal %d cluster %d\n",
		(int) sizeof(aas_header_t), (int) sizeof(aas_bbox_t), (int) sizeof(aas_vertex_t), (int) sizeof(aas_plane_t),
		(int) sizeof(aas_edge_t), (int) sizeof(aas_face_t), (int) sizeof(aas_area_t), (int) sizeof(aas_areasettings_t),
		(int) sizeof(aas_reachability_t), (int) sizeof(aas_node_t), (int) sizeof(aas_portal_t), (int) sizeof(aas_cluster_t));
	run_case(0, 0);
	run_case(1, 0);
	run_case(2, 0);
	run_case(3, 0);
	run_case(0, 1);
	run_case(0, 2);
	run_case(0, 3);
	run_case(0, 4);
	return 0;
}
