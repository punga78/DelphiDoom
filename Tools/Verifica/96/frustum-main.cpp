// Parity harness for idFrustum (issue #96, second slice): writes "name inputs | outputs" lines, floats as #bits.
#include "idlib/precompiled.h"


idSIMDProcessor *processor = NULL;
idSIMDProcessor *generic = NULL;
idSIMDProcessor *SIMDProcessor = NULL;
idSys *sys0 = NULL;
idCommon *common0 = NULL;
idSys *idLib::sys = NULL;
idCommon *idLib::common = NULL;
idCVarSystem *idLib::cvarSystem = NULL;
idFileSystem *idLib::fileSystem = NULL;
int idLib::frameNumber = 0;
void idLib::Error(const char *, ...) {}
void idLib::Warning(const char *, ...) {}
void *Mem_Alloc(const int size) { return malloc(size); }
void Mem_Free(void *p) { free(p); }

static FILE *out;
static unsigned int seed = 12345;

static unsigned int nextRaw() { seed = seed * 1664525u + 1013904223u; return seed; }
static float rnd() { return (float)(nextRaw() >> 8) / 16777216.0f; }
static float rng(float a, float b) { return a + (b - a) * rnd(); }
static int rint2(int n) { return (int)(rnd() * n) % n; }

static void pf(float f) { unsigned int u; memcpy(&u, &f, 4); fprintf(out, " #%08x", u); }
static void pi(int i) { fprintf(out, " %d", i); }
static void pb(bool b) { fprintf(out, b ? " 1" : " 0"); }
static void pv(const idVec3 &v) { pf(v.x); pf(v.y); pf(v.z); }
static void pm(const idMat3 &m) { pv(m[0]); pv(m[1]); pv(m[2]); }
static void pp(const idPlane &p) { pf(p[0]); pf(p[1]); pf(p[2]); pf(p[3]); }
static void pbd(const idBounds &b) { pv(b[0]); pv(b[1]); }
static void psp(const idSphere &s) { pv(s.GetOrigin()); pf(s.GetRadius()); }
static void pbx(const idBox &b) { pv(b.GetCenter()); pv(b.GetExtents()); pm(b.GetAxis()); }
static void pfr(const idFrustum &f) { pv(f.origin); pm(f.axis); pf(f.dNear); pf(f.dFar); pf(f.dLeft); pf(f.dUp); pf(f.invFar); }
static void pfrIn(const idFrustum &f) { pv(f.origin); pm(f.axis); pf(f.dNear); pf(f.dFar); pf(f.dLeft); pf(f.dUp); }
static void name(const char *n) { fprintf(out, "%s", n); }
static void bar() { fprintf(out, " |"); }
static void eol() { fprintf(out, "\n"); }

static idVec3 rvec(float r) { return idVec3(rng(-r, r), rng(-r, r), rng(-r, r)); }
static idMat3 gridAxis() {
	static const int perm[6][3] = { {0,1,2},{0,2,1},{1,0,2},{1,2,0},{2,0,1},{2,1,0} };
	int p = rint2(6);
	idMat3 m;
	m.Zero();
	for (int i = 0; i < 3; i++) m[i][perm[p][i]] = (rint2(2) ? 1.0f : -1.0f);
	return m;
}
static idMat3 randAxis() {
	idVec3 a = rvec(1.0f);
	if (a.Normalize() == 0.0f) a = idVec3(1, 0, 0);
	idVec3 b = rvec(1.0f);
	b = b - (b * a) * a;
	if (b.Normalize() == 0.0f) b = idVec3(0, 1, 0);
	idVec3 c = a.Cross(b);
	idMat3 m;
	m[0] = a; m[1] = b; m[2] = c;
	return m;
}
static idMat3 axisFor(bool grid) { return grid ? gridAxis() : randAxis(); }

static idFrustum genFrustum(bool grid) {
	idFrustum f;
	static const float nears[4] = { 0.0f, 0.5f, 1.0f, 2.0f };
	static const float fars[3] = { 4.0f, 8.0f, 16.0f };
	static const float sizes[4] = { 0.5f, 1.0f, 2.0f, 4.0f };
	if (grid) {
		f.SetOrigin(idVec3((float)(rint2(9) - 4) * 0.5f, (float)(rint2(9) - 4) * 0.5f, (float)(rint2(9) - 4) * 0.5f));
		f.SetAxis(gridAxis());
		f.SetSize(nears[rint2(4)], fars[rint2(3)], sizes[rint2(4)], sizes[rint2(4)]);
	} else {
		f.SetOrigin(rvec(8.0f));
		f.SetAxis(randAxis());
		float n = (rint2(5) == 0) ? 0.0f : rng(0.1f, 4.0f);
		f.SetSize(n, n + rng(1.0f, 20.0f), rng(0.3f, 6.0f), rng(0.3f, 6.0f));
	}
	return f;
}
// a point near the frustum, in world space
static idVec3 nearPoint(const idFrustum &f, bool grid) {
	float x, y, z;
	if (grid) {
		x = (float)(rint2(25) - 2) * 0.5f * (f.dFar / 8.0f);
		y = (float)(rint2(9) - 4) * 0.5f;
		z = (float)(rint2(9) - 4) * 0.5f;
	} else {
		x = rng(-1.0f, f.dFar * 1.2f);
		float s = (x < 0.0f ? 0.0f : x) * f.invFar;
		y = rng(-1.3f, 1.3f) * (f.dLeft * s + 1.0f);
		z = rng(-1.3f, 1.3f) * (f.dUp * s + 1.0f);
	}
	return f.origin + f.axis[0] * x + f.axis[1] * y + f.axis[2] * z;
}
static idBounds genBounds(const idFrustum &f, bool grid) {
	idVec3 c = nearPoint(f, grid);
	idVec3 h;
	if (grid) {
		static const float s[3] = { 0.5f, 1.0f, 2.0f };
		h = idVec3(s[rint2(3)], s[rint2(3)], s[rint2(3)]);
	} else {
		h = idVec3(rng(0.2f, 5.0f), rng(0.2f, 5.0f), rng(0.2f, 5.0f));
	}
	return idBounds(c - h, c + h);
}
static idBox genBox(const idFrustum &f, bool grid) {
	idBounds b = genBounds(f, grid);
	idVec3 c = (b[0] + b[1]) * 0.5f;
	return idBox(c, b[1] - c, axisFor(grid));
}
static idSphere genSphere(const idFrustum &f, bool grid) {
	idVec3 c = nearPoint(f, grid);
	static const float s[3] = { 0.5f, 1.0f, 2.0f };
	return idSphere(c, grid ? s[rint2(3)] : rng(0.2f, 5.0f));
}
static idFrustum genOther(const idFrustum &f, bool grid) {
	idFrustum g = genFrustum(grid);
	g.SetOrigin(nearPoint(f, grid));
	return g;
}
static void genWinding(const idFrustum &f, bool grid, idWinding &w) {
	idVec3 c = nearPoint(f, grid);
	idMat3 ax = axisFor(grid);
	float r = grid ? 1.0f : rng(0.3f, 5.0f);
	int n = grid ? 4 : 3 + rint2(6);
	float a0 = grid ? 0.0f : rng(0.0f, 6.28f);
	w.Clear();
	for (int i = 0; i < n; i++) {
		float a = a0 + 6.2831853f * (float)i / (float)n;
		w.AddPoint(c + ax[1] * (r * cosf(a)) + ax[2] * (r * sinf(a)));
	}
}
static void pwin(const idWinding &w) {
	pi(w.GetNumPoints());
	for (int i = 0; i < w.GetNumPoints(); i++) pv(w[i].ToVec3());
}
static idPlane genPlane(const idFrustum &f, bool grid) {
	idPlane p;
	idVec3 n;
	if (grid) { n = gridAxis()[0]; }
	else { n = rvec(1.0f); if (n.Normalize() == 0.0f) n = idVec3(1, 0, 0); }
	p.SetNormal(n);
	p.FitThroughPoint(nearPoint(f, grid));
	return p;
}

#define N 170
#define LOOP for (int it = 0; it < N; it++) { bool grid = (it % 4) == 3; idFrustum f = genFrustum(grid); (void)grid;

int main(int argc, char **argv) {
	out = fopen(argv[1], "w");
	generic = NULL;
	processor = generic;
	SIMDProcessor = generic;
	idMath::Init();

	LOOP name("FR_center"); pfrIn(f); bar(); pv(f.GetCenter()); eol(); }
	LOOP name("FR_valid"); pfrIn(f); bar(); pb(f.IsValid()); eol(); }
	LOOP name("FR_pyramid"); pfrIn(f); bar();
		idFrustum g = f; g.SetPyramid(f.dNear, f.dFar); pfr(g); eol(); }
	LOOP name("FR_movenear"); pfrIn(f); float d = rng(0.0f, 3.0f); pf(d); bar();
		idFrustum g = f; g.MoveNearDistance(d); pfr(g); eol(); }
	LOOP name("FR_movefar"); pfrIn(f); float d = f.dNear + rng(0.5f, 20.0f); pf(d); bar();
		idFrustum g = f; g.MoveFarDistance(d); pfr(g); eol(); }
	LOOP name("FR_expand"); pfrIn(f); float d = rng(-0.4f, 3.0f); if (grid) d = 0.5f; pf(d); bar();
		pfr(f.Expand(d)); idFrustum g = f; g.ExpandSelf(d); pfr(g); eol(); }
	LOOP name("FR_translate"); pfrIn(f); idVec3 t = rvec(5.0f); pv(t); bar();
		pfr(f.Translate(t)); idFrustum g = f; g.TranslateSelf(t); pfr(g); eol(); }
	LOOP name("FR_rotate"); pfrIn(f); idMat3 m = axisFor(grid); pm(m); bar();
		pfr(f.Rotate(m)); idFrustum g = f; g.RotateSelf(m); pfr(g); eol(); }
	LOOP name("FR_pdist"); pfrIn(f); idPlane p = genPlane(f, grid); pp(p); bar(); pf(f.PlaneDistance(p)); eol(); }
	LOOP name("FR_pside"); pfrIn(f); idPlane p = genPlane(f, grid); float e = grid ? 0.1f : rng(0.0f, 0.5f); pp(p); pf(e); bar(); pi(f.PlaneSide(p, e)); eol(); }
	LOOP name("FR_cullpoint"); pfrIn(f); idVec3 p = nearPoint(f, grid); pv(p); bar(); pb(f.CullPoint(p)); pb(f.ContainsPoint(p)); eol(); }
	LOOP name("FR_cullbounds"); pfrIn(f); idBounds b = genBounds(f, grid); pbd(b); bar(); pb(f.CullBounds(b)); eol(); }
	LOOP name("FR_cullbox"); pfrIn(f); idBox b = genBox(f, grid); pbx(b); bar(); pb(f.CullBox(b)); eol(); }
	LOOP name("FR_cullsphere"); pfrIn(f); idSphere s = genSphere(f, grid); psp(s); bar(); pb(f.CullSphere(s)); eol(); }
	LOOP name("FR_cullfrustum"); pfrIn(f); idFrustum g = genOther(f, grid); pfrIn(g); bar(); pb(f.CullFrustum(g)); eol(); }
	LOOP name("FR_cullwinding"); pfrIn(f); idWinding w; genWinding(f, grid, w); pwin(w); bar(); pb(f.CullWinding(w)); eol(); }
	LOOP name("FR_ibounds"); pfrIn(f); idBounds b = genBounds(f, grid); pbd(b); bar(); pb(f.IntersectsBounds(b)); eol(); }
	LOOP name("FR_ibox"); pfrIn(f); idBox b = genBox(f, grid); pbx(b); bar(); pb(f.IntersectsBox(b)); eol(); }
	LOOP name("FR_isphere"); pfrIn(f); idSphere s = genSphere(f, grid); psp(s); bar(); pb(f.IntersectsSphere(s)); eol(); }
	LOOP name("FR_ifrustum"); pfrIn(f); idFrustum g = genOther(f, grid); pfrIn(g); bar(); pb(f.IntersectsFrustum(g)); eol(); }
	LOOP name("FR_iwinding"); pfrIn(f); idWinding w; genWinding(f, grid, w); pwin(w); bar(); pb(f.IntersectsWinding(w)); eol(); }
	LOOP name("FR_line"); pfrIn(f); idVec3 a = nearPoint(f, grid), b = nearPoint(f, grid); pv(a); pv(b); bar(); pb(f.LineIntersection(a, b)); eol(); }
	LOOP name("FR_ray"); pfrIn(f); idVec3 a = nearPoint(f, grid);
		idVec3 d = grid ? gridAxis()[0] : rvec(1.0f); pv(a); pv(d); bar();
		float s1 = -7.0f, s2 = -7.0f; bool r = f.RayIntersection(a, d, s1, s2); pb(r); pf(s1); pf(s2); eol(); }
	LOOP name("FR_planes"); pfrIn(f); bar(); idPlane pl[6]; f.ToPlanes(pl); for (int i = 0; i < 6; i++) pp(pl[i]); eol(); }
	LOOP name("FR_points"); pfrIn(f); bar(); idVec3 pt[8]; f.ToPoints(pt); for (int i = 0; i < 8; i++) pv(pt[i]); eol(); }
	LOOP name("FR_axisproj"); pfrIn(f); idVec3 d = grid ? gridAxis()[0] : rvec(1.0f); pv(d); bar();
		float mn, mx; f.AxisProjection(d, mn, mx); pf(mn); pf(mx); eol(); }
	LOOP name("FR_axisprojmat"); pfrIn(f); idMat3 m = axisFor(grid); pm(m); bar();
		idBounds b; f.AxisProjection(m, b); pbd(b); eol(); }
	LOOP name("FR_fromproj_bounds"); pfrIn(f); idBounds b = genBounds(f, grid); idVec3 o = rvec(25.0f); float fr = rng(5.0f, 60.0f);
		pbd(b); pv(o); pf(fr); bar(); idFrustum g = f; bool r = g.FromProjection(b, o, fr); pb(r); pfr(g); eol(); }
	LOOP name("FR_fromproj_box"); pfrIn(f); idBox b = genBox(f, grid); idVec3 o = rvec(25.0f); float fr = rng(5.0f, 60.0f);
		pbx(b); pv(o); pf(fr); bar(); idFrustum g = f; bool r = g.FromProjection(b, o, fr); pb(r); pfr(g); eol(); }
	LOOP name("FR_fromproj_sphere"); pfrIn(f); idSphere s = genSphere(f, grid); idVec3 o = rvec(25.0f); float fr = rng(5.0f, 60.0f);
		psp(s); pv(o); pf(fr); bar(); idFrustum g = f; bool r = g.FromProjection(s, o, fr); pb(r); pfr(g); eol(); }
	LOOP name("FR_constrain_bounds"); pfrIn(f); idBounds b = genBounds(f, grid); pbd(b); bar();
		idFrustum g = f; bool r = g.ConstrainToBounds(b); pb(r); pfr(g); eol(); }
	LOOP name("FR_constrain_box"); pfrIn(f); idBox b = genBox(f, grid); pbx(b); bar();
		idFrustum g = f; bool r = g.ConstrainToBox(b); pb(r); pfr(g); eol(); }
	LOOP name("FR_constrain_sphere"); pfrIn(f); idSphere s = genSphere(f, grid); psp(s); bar();
		idFrustum g = f; bool r = g.ConstrainToSphere(s); pb(r); pfr(g); eol(); }
	LOOP name("FR_constrain_frustum"); pfrIn(f); idFrustum o = genOther(f, grid); pfrIn(o); bar();
		idFrustum g = f; bool r = g.ConstrainToFrustum(o); pb(r); pfr(g); eol(); }
	LOOP name("FR_pb_bounds"); pfrIn(f); idBounds b = genBounds(f, grid); pbd(b); bar();
		idBounds pb0; pb0.Zero(); bool r = f.ProjectionBounds(b, pb0); pb(r); pbd(pb0); eol(); }
	LOOP name("FR_pb_box"); pfrIn(f); idBox b = genBox(f, grid); pbx(b); bar();
		idBounds pb0; pb0.Zero(); bool r = f.ProjectionBounds(b, pb0); pb(r); pbd(pb0); eol(); }
	LOOP name("FR_pb_sphere"); pfrIn(f); idSphere s = genSphere(f, grid); psp(s); bar();
		idBounds pb0; pb0.Zero(); bool r = f.ProjectionBounds(s, pb0); pb(r); pbd(pb0); eol(); }
	LOOP name("FR_pb_frustum"); pfrIn(f); idFrustum g = genOther(f, grid); pfrIn(g); bar();
		idBounds pb0; pb0.Zero(); bool r = f.ProjectionBounds(g, pb0); pb(r); pbd(pb0); eol(); }
	LOOP name("FR_pb_winding"); pfrIn(f); idWinding w; genWinding(f, grid, w); pwin(w); bar();
		idBounds pb0; pb0.Zero(); bool r = f.ProjectionBounds(w, pb0); pb(r); pbd(pb0); eol(); }
	LOOP name("FR_cpb"); pfrIn(f); idFrustum g = genOther(f, grid); idBox b = genBox(f, grid); pfrIn(g); pbx(b); bar();
		idBounds pb0; pb0.Zero(); bool r = f.ClippedProjectionBounds(g, b, pb0); pb(r); pbd(pb0); eol(); }
	fclose(out);
	return 0;
}



