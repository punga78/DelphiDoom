// Parity harness of idTraceModel (issue #236, part A): SetupOctahedron, SetupDodecahedron, SetupCone and, to
// compare, SetupCylinder. Writes "trm kind sides f1..f6 | outputs" lines, floats as #bits.
// kinds: 0 octahedron(bounds), 1 dodecahedron(bounds), 2 cone(bounds, sides), 3 cylinder(bounds, sides),
//        4 octahedron(size), 5 dodecahedron(size), 6 cone(height, width, sides)
// outputs: type, numVerts, numEdges, numPolys, isConvex, offset, bounds, the vertices, the edges (v0 v1 normal),
//          the polygons (numEdges, the edges, normal, dist, bounds)
#include "idlib/precompiled.h"
#include "idlib/math/Simd_Generic.h"

idSys *idLib::sys = NULL; idCommon *idLib::common = NULL; idCVarSystem *idLib::cvarSystem = NULL;
idFileSystem *idLib::fileSystem = NULL; int idLib::frameNumber = 0;
idSIMDProcessor *SIMDProcessor = NULL; idSIMDProcessor *generic = NULL; idSIMDProcessor *processor = NULL;

void *Mem_Alloc16( const int size ) { return _aligned_malloc( size, 16 ); }
void Mem_Free16( void *ptr ) { _aligned_free( ptr ); }

static FILE *out;
static unsigned st = 20261116u;
static unsigned nx() { st = st * 1664525u + 1013904223u; return st; }
static float rf(float r) { return ((nx() >> 8) / 8388608.0f - 1.0f) * r; }
static void F(float f) { unsigned u; memcpy(&u, &f, 4); fprintf(out, " #%08x", u); }
static void I(int i) { fprintf(out, " %d", i); }
static void V3(const idVec3 &v) { F(v.x); F(v.y); F(v.z); }

static void Case(int kind, int sides, const float *f) {
	idTraceModel t;
	idBounds b;
	b[0].Set(f[0], f[1], f[2]); b[1].Set(f[3], f[4], f[5]);
	fprintf(out, "trm %d %d", kind, sides);
	for (int i = 0; i < 6; i++) F(f[i]);
	fprintf(out, " |");
	switch (kind) {
		case 0: t.SetupOctahedron(b); break;
		case 1: t.SetupDodecahedron(b); break;
		case 2: t.SetupCone(b, sides); break;
		case 3: t.SetupCylinder(b, sides); break;
		case 4: t.SetupOctahedron(f[0]); break;
		case 5: t.SetupDodecahedron(f[0]); break;
		case 6: t.SetupCone(f[0], f[1], sides); break;
	}
	I((int)t.type); I(t.numVerts); I(t.numEdges); I(t.numPolys); I(t.isConvex ? 1 : 0);
	V3(t.offset); V3(t.bounds[0]); V3(t.bounds[1]);
	for (int i = 0; i < t.numVerts; i++) V3(t.verts[i]);
	for (int i = 1; i <= t.numEdges; i++) { I(t.edges[i].v[0]); I(t.edges[i].v[1]); V3(t.edges[i].normal); }
	for (int i = 0; i < t.numPolys; i++) {
		I(t.polys[i].numEdges);
		for (int j = 0; j < t.polys[i].numEdges; j++) I(t.polys[i].edges[j]);
		V3(t.polys[i].normal); F(t.polys[i].dist); V3(t.polys[i].bounds[0]); V3(t.polys[i].bounds[1]);
	}
	fprintf(out, "\n");
}

int main(int argc, char **argv) {
	out = fopen(argv[1], "wb");
	idLib::common = new idCommon();	// the "too many vertices" warnings of the Setup functions print
	idMath::Init();
	for (int n = 0; n < 40; n++) {
		float f[6];
		for (int i = 0; i < 3; i++) { f[i] = -1.0f - (nx() % 4000) / 100.0f; f[3 + i] = 1.0f + (nx() % 4000) / 100.0f; }
		if (n % 5 == 0) { f[0] = f[1] = f[2] = -16.0f; f[3] = f[4] = f[5] = 16.0f; }
		if (n % 5 == 1) { f[0] = f[1] = f[2] = -0.5f; f[3] = f[4] = f[5] = 0.5f; }
		if (n % 5 == 2) { f[0] = -4.0f; f[1] = 4.0f; f[2] = 0.0f; f[3] = 12.0f; f[4] = 20.0f; f[5] = 60.0f; }
		Case(0, 0, f);
		Case(1, 0, f);
	}
	static const int sides[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 15, 16, 17, 20, 31, 32, 33, 100 };
	for (int n = 0; n < 40; n++) {
		float f[6];
		for (int i = 0; i < 3; i++) { f[i] = -1.0f - (nx() % 4000) / 100.0f; f[3 + i] = 1.0f + (nx() % 4000) / 100.0f; }
		if (n % 4 == 0) { f[0] = f[1] = f[2] = -16.0f; f[3] = f[4] = f[5] = 16.0f; }
		int s = sides[n % (sizeof(sides) / sizeof(sides[0]))];
		Case(2, s, f);
		Case(3, s, f);
	}
	for (int n = 0; n < 12; n++) {
		float f[6] = { 0, 0, 0, 0, 0, 0 };
		f[0] = 1.0f + (nx() % 6400) / 100.0f; f[1] = 1.0f + (nx() % 3200) / 100.0f;
		Case(4, 0, f);
		Case(5, 0, f);
		Case(6, 3 + n, f);
	}
	fclose(out);
	return 0;
}
