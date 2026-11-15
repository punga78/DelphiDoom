// Parity harness of idSurface_SweptSpline (issue #236, part A). Writes "name inputs... | outputs..." lines,
// floats as #bits: the vertices (xyz, st, normal, two tangents, colour) and the indexes of the tessellation.
#include "idlib/precompiled.h"
#include "idlib/math/Simd_Generic.h"

idSys *idLib::sys = NULL; idCommon *idLib::common = NULL; idCVarSystem *idLib::cvarSystem = NULL;
idFileSystem *idLib::fileSystem = NULL; int idLib::frameNumber = 0;
idSIMDProcessor *SIMDProcessor = NULL; idSIMDProcessor *generic = NULL; idSIMDProcessor *processor = NULL;

void *Mem_Alloc16( const int size ) { return _aligned_malloc( size, 16 ); }
void Mem_Free16( void *ptr ) { _aligned_free( ptr ); }

static FILE *out;
static unsigned st = 20261115u;
static unsigned nx() { st = st * 1664525u + 1013904223u; return st; }
static float rf(float r) { return ((nx() >> 8) / 8388608.0f - 1.0f) * r; }
static void F(float f) { unsigned u; memcpy(&u, &f, 4); fprintf(out, " #%08x", u); }
static void I(int i) { fprintf(out, " %d", i); }
static void V3(const idVec3 &v) { F(v.x); F(v.y); F(v.z); }

// kinds of curve: 0 open Catmull-Rom, 1 closed Catmull-Rom, 2 open NURBS, 3 closed NURBS, 4 natural cubic spline, 5 clamped Catmull-Rom
static idCurve_Spline<idVec4> *MakeCurve(int kind, int n, const float *k) {
	idCurve_Spline<idVec4> *c;
	if (kind == 0 || kind == 1 || kind == 5) c = new idCurve_CatmullRomSpline<idVec4>();
	else if (kind == 4) c = new idCurve_NaturalCubicSpline<idVec4>();
	else c = new idCurve_NURBS<idVec4>();
	for (int i = 0; i < n; i++) c->AddValue(k[i * 5], idVec4(k[i * 5 + 1], k[i * 5 + 2], k[i * 5 + 3], k[i * 5 + 4]));
	if (kind == 1 || kind == 3) { c->SetBoundaryType(idCurve_Spline<idVec4>::BT_CLOSED); c->SetCloseTime(100.0f); }
	if (kind == 5) c->SetBoundaryType(idCurve_Spline<idVec4>::BT_CLAMPED);
	return c;
}

static void Case(int mainKind, int mainCount, int sweptKind, int sweptCount, float radius, int splineSub, int sweptSub) {
	float mainKnots[8 * 5], sweptKnots[8 * 5];
	for (int i = 0; i < mainCount; i++) {
		mainKnots[i * 5] = 100.0f * i; mainKnots[i * 5 + 1] = rf(40.0f) + 30.0f * i; mainKnots[i * 5 + 2] = rf(40.0f); mainKnots[i * 5 + 3] = rf(40.0f) + 10.0f * i; mainKnots[i * 5 + 4] = (float)i / mainCount;
	}
	for (int i = 0; i < sweptCount; i++) {
		float a = 6.2831853f * i / sweptCount;
		sweptKnots[i * 5] = 100.0f * i; sweptKnots[i * 5 + 1] = radius * cosf(a) + rf(2.0f); sweptKnots[i * 5 + 2] = radius * sinf(a) + rf(2.0f); sweptKnots[i * 5 + 3] = rf(1.0f); sweptKnots[i * 5 + 4] = (float)i / sweptCount;
	}
	fprintf(out, "sw %d %d %d %d", mainKind, mainCount, sweptKind, sweptCount); F(radius); I(splineSub); I(sweptSub);
	for (int i = 0; i < mainCount * 5; i++) F(mainKnots[i]);
	for (int i = 0; i < sweptCount * 5; i++) F(sweptKnots[i]);
	fprintf(out, " |");
	idSurface_SweptSpline s;
	s.SetSpline(MakeCurve(mainKind, mainCount, mainKnots));
	if (sweptKind < 0) s.SetSweptCircle(radius); else s.SetSweptSpline(MakeCurve(sweptKind, sweptCount, sweptKnots));
	s.Tessellate(splineSub, sweptSub);
	I(s.GetNumVertices());
	for (int i = 0; i < s.GetNumVertices(); i++) {
		const idDrawVert &v = s[i];
		V3(v.xyz); F(v.st[0]); F(v.st[1]); V3(v.normal); V3(v.tangents[0]); V3(v.tangents[1]);
		I(v.color[0]); I(v.color[1]); I(v.color[2]); I(v.color[3]);
	}
	I(s.GetNumIndexes());
	for (int i = 0; i < s.GetNumIndexes(); i++) I(s.GetIndexes()[i]);
	fprintf(out, "\n"); fflush(out);
}

int main(int argc, char **argv) {
	idSys s; idCommon c; idLib::sys = &s; idLib::common = &c; idMath::Init();
	generic = new idSIMD_Generic; SIMDProcessor = generic;
	out = fopen(argc > 1 ? argv[1] : "swept.golden.txt", "w");
	// the circle of the original (NURBS closed) swept along open and closed splines of every kind
	int mains[] = { 0, 1, 2, 3, 5 };
	for (int m = 0; m < 5; m++) for (int rep = 0; rep < 3; rep++) {
		int count = 4 + (rep + m) % 4;
		Case(mains[m], count, -1, 4, 5.0f + rep, 4 + rep * 3, 6 + rep * 2);
	}
	// custom swept splines
	for (int rep = 0; rep < 12; rep++) {
		int mk = (rep % 3 == 0) ? 0 : (rep % 3 == 1 ? 2 : 1);
		int sk = (rep % 4 == 0) ? 1 : (rep % 4 == 1 ? 3 : (rep % 4 == 2 ? 0 : 5));
		Case(mk, 5 + rep % 3, sk, 4 + rep % 4, 3.0f + rep * 0.5f, 3 + rep % 6, 3 + (rep * 5) % 7);
	}
	fclose(out);
	return 0;
}
