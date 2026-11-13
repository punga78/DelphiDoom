// Parity harness of the second slice of issue #96 (DrawVert, Winding2D, Surface, Surface_Polytope,
// Surface_Patch, JointTransform). Writes "name inputs... | outputs..." lines, floats as #bits.
#include "idlib/precompiled.h"
#include "idlib/math/Simd_Generic.h"

idSys *idLib::sys = NULL; idCommon *idLib::common = NULL; idCVarSystem *idLib::cvarSystem = NULL;
idFileSystem *idLib::fileSystem = NULL; int idLib::frameNumber = 0;
idSIMDProcessor *SIMDProcessor = NULL; idSIMDProcessor *generic = NULL; idSIMDProcessor *processor = NULL;

static FILE *out; static int meshCount = 0;
static unsigned st = 20261113u;
static unsigned nx() { st = st * 1664525u + 1013904223u; return st; }
static float rf(float r) { return ((nx() >> 8) / 8388608.0f - 1.0f) * r; }
static int ri(int n) { return (int)((nx() >> 8) % (unsigned)n); }
static float gf(float r) { return floorf(rf(r) * 2.0f + 0.5f) / 2.0f; }

static void N(const char *n) { fprintf(out, "%s", n); }
static void F(float f) { unsigned u; memcpy(&u, &f, 4); fprintf(out, " #%08x", u); }
static void I(int i) { fprintf(out, " %d", i); }
static void U(unsigned i) { fprintf(out, " %u", i); }
static void Bar() { fprintf(out, " |"); }
static void End() { fprintf(out, "\n"); fflush(out); }
static void V3(const idVec3 &v) { F(v.x); F(v.y); F(v.z); }
static void V2(const idVec2 &v) { F(v.x); F(v.y); }
static void Pl(const idPlane &p) { F(p[0]); F(p[1]); F(p[2]); F(p[3]); }
static void M3(const idMat3 &m) { V3(m[0]); V3(m[1]); V3(m[2]); }
static void DV(const idDrawVert &v) {
	V3(v.xyz); V2(v.st); V3(v.normal); V3(v.tangents[0]); V3(v.tangents[1]); U(v.GetColor());
}
static void DV3(const idDrawVert &v) { V3(v.xyz); V2(v.st); V3(v.normal); }

static idVec3 rv(float r) { return idVec3(rf(r), rf(r), rf(r)); }
static idVec3 rdir() { idVec3 v = rv(1.0f); if (v.Normalize() == 0.0f) v = idVec3(0, 0, 1); return v; }
static idPlane rplane() { idVec3 n = rdir(); return idPlane(n.x, n.y, n.z, rf(2.0f)); }
static idPlane gplane() {
	// axial planes through the 0.5 grid, to hit vertices and edges exactly
	idVec3 n(0, 0, 0); n[ri(3)] = (ri(2) ? 1.0f : -1.0f);
	return idPlane(n.x, n.y, n.z, gf(1.5f));
}
static idDrawVert rvert(float r) {
	idDrawVert v;
	v.xyz = rv(r); v.st = idVec2(rf(2), rf(2)); v.normal = rdir(); v.tangents[0] = rdir(); v.tangents[1] = rdir();
	v.SetColor(nx());
	return v;
}

// ------------------------------------------------------------------ meshes

struct Mesh {
	idList<idDrawVert> verts;
	idList<int> idx;
};

static void MeshOut(const Mesh &m) {
	I(m.verts.Num());
	for (int i = 0; i < m.verts.Num(); i++) DV(m.verts[i]);
	I(m.idx.Num());
	for (int i = 0; i < m.idx.Num(); i++) I(m.idx[i]);
}

static bool g_xyzOnly = false;
static void SurfOut(const idSurface &s) {
	I(s.GetNumVertices()); I(s.GetNumIndexes());
	const surfaceEdge_t *e = s.GetEdges();
	int ne = 0;
	// the number of edges is not exposed: every triangle has three edge indexes, the highest one is the count - 1
	for (int i = 0; i < s.GetNumIndexes(); i++) { int a = abs(s.GetEdgeIndexes()[i]); if (a + 1 > ne) ne = a + 1; }
	I(ne);
	for (int i = 0; i < s.GetNumVertices(); i++) { if (g_xyzOnly) V3(s.GetVertices()[i].xyz); else DV(s.GetVertices()[i]); }
	for (int i = 0; i < s.GetNumIndexes(); i++) I(s.GetIndexes()[i]);
	for (int i = 0; i < ne; i++) { I(e[i].verts[0]); I(e[i].verts[1]); I(e[i].tris[0]); I(e[i].tris[1]); }
	for (int i = 0; i < s.GetNumIndexes(); i++) I(s.GetEdgeIndexes()[i]);
}

static void Grid(Mesh &m, int nx_, int ny_, bool snap, float jitter) {
	for (int j = 0; j <= ny_; j++) for (int i = 0; i <= nx_; i++) {
		idDrawVert v = rvert(1.0f);
		v.xyz.x = i * 0.5f - nx_ * 0.25f; v.xyz.y = j * 0.5f - ny_ * 0.25f;
		v.xyz.z = snap ? 0.0f : rf(jitter);
		if (!snap) { v.xyz.x += rf(jitter * 0.3f); v.xyz.y += rf(jitter * 0.3f); }
		m.verts.Append(v);
	}
	for (int j = 0; j < ny_; j++) for (int i = 0; i < nx_; i++) {
		int a = j * (nx_ + 1) + i, b = a + 1, c = a + nx_ + 2, d = a + nx_ + 1;
		if (ri(2)) { m.idx.Append(a); m.idx.Append(b); m.idx.Append(c); m.idx.Append(a); m.idx.Append(c); m.idx.Append(d); }
		else { m.idx.Append(a); m.idx.Append(b); m.idx.Append(d); m.idx.Append(b); m.idx.Append(c); m.idx.Append(d); }
	}
}

static void Soup(Mesh &m, int tris) {
	for (int t = 0; t < tris; t++) {
		idVec3 c = rv(1.0f);
		for (int k = 0; k < 3; k++) { idDrawVert v = rvert(1.0f); v.xyz = c + rv(0.6f); m.verts.Append(v); m.idx.Append(t * 3 + k); }
	}
}

static void Poly(Mesh &m, int kind) {
	idSurface_Polytope p;
	idVec3 c = rv(1.0f), e(0.2f + fabsf(rf(1.0f)), 0.2f + fabsf(rf(1.0f)), 0.2f + fabsf(rf(1.0f)));
	idBounds b(c - e, c + e);
	if (kind == 0) p.SetupTetrahedron(b); else if (kind == 1) p.SetupHexahedron(b); else p.SetupOctahedron(b);
	for (int i = 0; i < p.GetNumVertices(); i++) { idDrawVert v = rvert(1.0f); v.xyz = p.GetVertices()[i].xyz; m.verts.Append(v); }
	for (int i = 0; i < p.GetNumIndexes(); i++) m.idx.Append(p.GetIndexes()[i]);
}

static void MakeMesh(Mesh &m, int &kind) {
	kind = ri(9);
	switch (kind) {
	case 0: case 1: Grid(m, 1 + ri(3), 1 + ri(3), false, 0.5f); break;
	case 2: case 3: Grid(m, 1 + ri(4), 1 + ri(3), true, 0.0f); break;
	case 4: Soup(m, 1 + ri(4)); break;
	default: Poly(m, kind % 3); break;
	}
}

// ------------------------------------------------------------------ cases

static void DrawVerts() {
	for (int n = 0; n < 60; n++) {
		idDrawVert a = rvert(2), b = rvert(2), r;
		float f = (n % 4 == 0) ? (float)(n % 3) * 0.5f : fabsf(rf(1.0f));
		r.Clear(); r.Lerp(a, b, f);
		N("dv_lerp"); DV(a); DV(b); F(f); Bar(); DV(r); End();
		r.Clear(); r.LerpAll(a, b, f);
		N("dv_lerpall"); DV(a); DV(b); F(f); Bar(); DV(r); End();
		r = rvert(2); idDrawVert o = r; r.Normalize();
		N("dv_normalize"); DV(o); Bar(); DV(r); End();
		idDrawVert q; q.Clear(); unsigned col = nx(); q.SetColor(col);
		N("dv_color"); U(col); Bar(); I(q.color[0]); I(q.color[1]); I(q.color[2]); I(q.color[3]); U(q.GetColor()); End();
		int ix = ri(5);
		N("dv_index"); DV(a); I(ix); Bar(); F(a[ix]); End();
	}
}

static void Surfaces() {
	for (int n = 0; n < 36; n++) {
		Mesh m; int kind; MakeMesh(m, kind); int mid = ++meshCount; N("mesh"); I(mid); MeshOut(m); End();
		idSurface s(m.verts.Ptr(), m.verts.Num(), m.idx.Ptr(), m.idx.Num());
		N("sf_build"); I(mid); Bar(); SurfOut(s);
		I(s.IsConnected()); I(s.IsClosed()); I(s.IsPolytope(0.1f)); I(s.IsPolytope(0.5f)); End();
		for (int k = 0; k < 3; k++) {
			idPlane pl = (n % 3 == 0) ? gplane() : rplane();
			float eps = (k == 0) ? 0.1f : (k == 1 ? 0.0f : 0.3f);
			N("sf_plane"); I(mid); Pl(pl); F(eps); Bar(); F(s.PlaneDistance(pl)); I(s.PlaneSide(pl, eps)); End();

			idSurface *front, *back; int fe[512], be[512];
			int side = s.Split(pl, eps, &front, &back, fe, be);
			N("sf_split"); I(mid); Pl(pl); F(eps); Bar(); I(side); I(front != NULL); I(back != NULL);
			if (front) SurfOut(*front);
			if (back) SurfOut(*back);
			if (side == SIDE_CROSS) {
				int c0 = 0, c1 = 0; while (fe[c0] >= 0) c0++; while (be[c1] >= 0) c1++;
				I(c0); for (int i = 0; i < c0; i++) I(fe[i]);
				I(c1); for (int i = 0; i < c1; i++) I(be[i]);
			}
			End();
			delete front; delete back;

			idSurface c(s);
			bool keep = (k == 2);
			bool r = c.ClipInPlace(pl, eps, keep);
			N("sf_clip"); I(mid); Pl(pl); F(eps); I(keep); Bar(); I(r); SurfOut(c); End();
		}
		for (int k = 0; k < 4; k++) {
			idVec3 start = rv(2.0f), dir = rdir() * (0.5f + fabsf(rf(2.0f)));
			if (k == 3) { start = idVec3(rf(0.5f), rf(0.5f), 2.0f); dir = idVec3(0, 0, -1.0f); }
			float sc; bool hit = s.RayIntersection(start, dir, sc, (k & 1) != 0);
			N("sf_ray"); I(mid); V3(start); V3(dir); I((k & 1) != 0); Bar(); I(hit); F(sc); End();
			idVec3 end = start + dir * 2.0f;
			N("sf_line"); I(mid); V3(start); V3(end); Bar(); I(s.LineIntersection(start, end)); End();
		}
		{
			idAngles ang(rf(180), rf(180), rf(180)); idMat3 mat = ang.ToMat3(); idVec3 tr = rv(2.0f);
			idSurface c(s); c.TranslateSelf(tr);
			N("sf_translate"); I(mid); V3(tr); Bar(); SurfOut(c); End();
			idSurface d(s); d.RotateSelf(mat);
			N("sf_rotate"); I(mid); M3(mat); Bar(); SurfOut(d); End();
			Mesh m2; int k2; MakeMesh(m2, k2); int mid2 = ++meshCount; N("mesh"); I(mid2); MeshOut(m2); End();
			idSurface s2(m2.verts.Ptr(), m2.verts.Num(), m2.idx.Ptr(), m2.idx.Num());
			idSurface e(s); e += s2;
			N("sf_append"); I(mid); I(mid2); Bar(); SurfOut(e); End();
		}
	}
}

static void Polytopes() {
	g_xyzOnly = true;
	for (int n = 0; n < 24; n++) {
		idSurface_Polytope p; int kind = n % 3;
		idVec3 c = rv(1.0f), e(0.2f + fabsf(rf(1.0f)), 0.2f + fabsf(rf(1.0f)), 0.2f + fabsf(rf(1.0f)));
		idBounds b(c - e, c + e);
		if (kind == 0) p.SetupTetrahedron(b); else if (kind == 1) p.SetupHexahedron(b); else p.SetupOctahedron(b);
		N("pt_setup"); I(kind); V3(b[0]); V3(b[1]); Bar(); SurfOut(p);
		I(p.IsConnected()); I(p.IsClosed()); I(p.IsPolytope(0.1f)); End();
		for (int k = 0; k < 3; k++) {
			idPlane pl = (k == 0) ? idPlane(1, 0, 0, -c.x) : rplane();
			float eps = (k == 2) ? 0.3f : 0.1f;
			idSurface_Polytope *front, *back;
			int side = p.SplitPolytope(pl, eps, &front, &back);
			N("pt_split"); I(kind); V3(b[0]); V3(b[1]); Pl(pl); F(eps); Bar(); I(side);
			SurfOut(*front); SurfOut(*back); I(front->IsClosed()); I(back->IsClosed()); End();
			delete front; delete back;
		}
	}
}

static void Patch(int w, int h, int type, idSurface_Patch &p) {
	p.SetSize(w, h);
	for (int j = 0; j < h; j++) for (int i = 0; i < w; i++) {
		idDrawVert v; v.Clear();
		float x = i * 2.0f, y = j * 2.0f, z;
		switch (type) {
		case 0: z = rf(2.0f); break;                       // random bumps
		case 1: z = 0.0f; break;                           // flat
		case 2: z = (float)((i + j) & 1) * 3.0f; break;    // saw
		case 3: z = (i == w / 2) ? 4.0f : 0.0f; break;     // ridge
		default: z = 0.0f; break;
		}
		if (type == 4) {                                    // a cylinder that closes in width
			float a = 6.2831853f * i / (float)(w - 1);
			x = 3.0f * cosf(a); y = 3.0f * sinf(a); z = j * 2.0f;
			if (i == w - 1) { x = 3.0f; y = 0.0f; }
		}
		v.xyz = idVec3(x, y, z);
		v.st = idVec2((float)i / (w - 1), (float)j / (h - 1));
		v.normal = idVec3(rf(1), rf(1), 1.0f);
		p[j * w + i] = v;
	}
}

static void PatchOut(const idSurface_Patch &p) {
	I(p.GetWidth()); I(p.GetHeight()); I(p.GetNumVertices()); I(p.GetNumIndexes());
	for (int i = 0; i < p.GetNumVertices(); i++) DV3(p.GetVertices()[i]);
	for (int i = 0; i < p.GetNumIndexes(); i++) I(p.GetIndexes()[i]);
	const idSurface &s = p;
	int ne = 0; for (int i = 0; i < s.GetNumIndexes(); i++) { int a = abs(s.GetEdgeIndexes()[i]); if (a + 1 > ne) ne = a + 1; }
	I(ne);
}

static void Patches() {
	static const int sizes[] = { 3, 5, 7, 3, 9 };
	for (int n = 0; n < 60; n++) {
		int w = sizes[ri(5)], h = sizes[ri(5)], type = n % 5;
		if (type == 4 && w < 5) w = 5;
		{
			idSurface_Patch p(w, h); Patch(w, h, type, p);
			int hs = 1 + ri(4), vs = 1 + ri(4); bool gn = ri(2), rl = ri(2);
			// the control mesh is printed as built
			N("pa_explicit"); I(w); I(h); I(type);
			for (int i = 0; i < w * h; i++) DV3(p.GetVertices()[i]);
			I(hs); I(vs); I(gn); I(rl); Bar();
			p.SubdivideExplicit(hs, vs, gn, rl);
			PatchOut(p); End();
		}
		{
			idSurface_Patch p(w, h); Patch(w, h, type, p);
			float he = 0.1f + fabsf(rf(1.5f)), ve = 0.1f + fabsf(rf(1.5f)), len = (ri(3) == 0) ? 0.0f : 1.0f + fabsf(rf(4.0f));
			bool gn = ri(2);
			N("pa_subdivide"); I(w); I(h); I(type);
			for (int i = 0; i < w * h; i++) DV3(p.GetVertices()[i]);
			F(he); F(ve); F(len); I(gn); Bar();
			p.Subdivide(he, ve, len, gn);
			PatchOut(p); End();
		}
	}
}

// ------------------------------------------------------------------ 2D windings

static void W2Out(const idWinding2D *w) {
	if (!w) { I(-1); return; }
	I(w->GetNumPoints());
	for (int i = 0; i < w->GetNumPoints(); i++) V2((*w)[i]);
}

static void W2In(const idWinding2D &w) { W2Out(&w); }

static void MakeW2(idWinding2D &w, int kind) {
	w.Clear();
	if (kind == 0) { // axis aligned square on the 0.5 grid
		float x = gf(2), y = gf(2), s = 0.5f + fabsf(gf(1.5f));
		w.AddPoint(idVec2(x, y)); w.AddPoint(idVec2(x + s, y)); w.AddPoint(idVec2(x + s, y + s)); w.AddPoint(idVec2(x, y + s));
		return;
	}
	int n = 3 + ri(kind == 1 ? 4 : 11); // up to 14 points
	float cx = rf(2), cy = rf(2), r = 0.5f + fabsf(rf(2.0f));
	for (int i = 0; i < n; i++) {
		float a = 6.2831853f * (i + 0.3f * rf(1.0f)) / n;
		float rr = r * (0.8f + 0.2f * fabsf(rf(1.0f)));
		w.AddPoint(idVec2(cx + rr * cosf(a), cy + rr * sinf(a)));
	}
}

static idVec3 rplane2() {
	idVec2 d(rf(1), rf(1)); if (d.Normalize() == 0.0f) d = idVec2(1, 0);
	return idVec3(d.x, d.y, rf(2.0f));
}

static void Windings2D() {
	for (int n = 0; n < 90; n++) {
		idWinding2D w; MakeW2(w, n % 3);
		idVec2 ctr = w.GetCenter(); idVec2 bb[2]; w.GetBounds(bb);
		N("w2_basic"); W2In(w); Bar(); F(w.GetArea()); V2(ctr); F(w.GetRadius(ctr)); V2(bb[0]); V2(bb[1]);
		I(w.IsTiny()); I(w.IsHuge()); End();
		idWinding2D *rv2 = w.Reverse();
		N("w2_reverse"); W2In(w); Bar(); W2Out(rv2); End(); delete rv2;
		for (int k = 0; k < 4; k++) {
			idVec3 pl = (k == 0 && n % 2) ? idVec3(1, 0, -gf(1.5f)) : rplane2();
			float eps = (k == 3) ? 0.0f : 0.1f;
			N("w2_plane"); W2In(w); V3(pl); F(eps); Bar(); F(w.PlaneDistance(pl)); I(w.PlaneSide(pl, eps)); End();
			idWinding2D *f, *b; int side = w.Split(pl, eps, &f, &b);
			N("w2_split"); W2In(w); V3(pl); F(eps); Bar(); I(side); W2Out(f); W2Out(b); End(); delete f; delete b;
			idWinding2D c = w; bool keep = (k == 2);
			bool r = c.ClipInPlace(pl, eps, keep);
			N("w2_clip"); W2In(w); V3(pl); F(eps); I(keep); Bar(); I(r); W2Out(&c); End();
		}
		{
			idWinding2D c = w; float d = rf(1.0f); c.Expand(d);
			N("w2_expand"); W2In(w); F(d); Bar(); W2Out(&c); End();
			idWinding2D e = w; idVec2 bd[2] = { idVec2(-fabsf(rf(0.5f)), -fabsf(rf(0.5f))), idVec2(fabsf(rf(0.5f)), fabsf(rf(0.5f))) };
			e.ExpandForAxialBox(bd);
			N("w2_expandbox"); W2In(w); V2(bd[0]); V2(bd[1]); Bar(); W2Out(&e); End();
		}
		for (int k = 0; k < 3; k++) {
			idVec2 pt(rf(2), rf(2)); float eps = (k == 2) ? 0.3f : 0.0f;
			N("w2_inside"); W2In(w); V2(pt); F(eps); Bar(); I(w.PointInside(pt, eps)); End();
			idVec2 s(rf(3), rf(3)), e(rf(3), rf(3));
			N("w2_line"); W2In(w); V2(s); V2(e); Bar(); I(w.LineIntersection(s, e)); End();
			idVec2 dir(rf(1), rf(1)); float s1, s2; int ed[2] = { -1, -1 };
			bool hit = w.RayIntersection(s, dir, s1, s2, ed);
			N("w2_ray"); W2In(w); V2(s); V2(dir); Bar(); I(hit); F(s1); F(s2); I(ed[0]); I(ed[1]); End();
		}
		{
			idVec2 a(rf(2), rf(2)), b(rf(2), rf(2)), d(rf(2), rf(2));
			idVec3 p1 = idWinding2D::Plane2DFromPoints(a, b, false), p2 = idWinding2D::Plane2DFromPoints(a, b, true);
			idVec3 p3 = idWinding2D::Plane2DFromVecs(a, d, false), p4 = idWinding2D::Plane2DFromVecs(a, d, true);
			idVec2 pt(0, 0); bool ok = idWinding2D::Plane2DIntersection(p2, p4, pt);
			N("w2_plane2d"); V2(a); V2(b); V2(d); Bar(); V3(p1); V3(p2); V3(p3); V3(p4); I(ok); V2(pt); End();
		}
	}
}

// ------------------------------------------------------------------ joint matrices

static void JointMats() {
	for (int n = 0; n < 80; n++) {
		idJointMat a, b;
		idAngles aa(rf(180), rf(180), rf(180)), ab(rf(180), rf(180), rf(180));
		idMat3 ma = aa.ToMat3(), mb = ab.ToMat3(); idVec3 ta = rv(3), tb = rv(3);
		if (n % 8 == 0) { ma = mat3_identity; }
		if (n % 8 == 1) { ma = idAngles(0, rf(180), 0).ToMat3(); }
		a.SetRotation(ma); a.SetTranslation(ta); b.SetRotation(mb); b.SetTranslation(tb);
		idVec3 v = rv(2); idVec4 v4(rf(2), rf(2), rf(2), rf(2));
		N("jm_ops"); M3(ma); V3(ta); M3(mb); V3(tb); V3(v); F(v4.x); F(v4.y); F(v4.z); F(v4.w); Bar();
		V3(a * v); V3(a * v4);
		idJointMat m = a; m *= b; M3(m.ToMat3()); V3(m.ToVec3());
		idJointMat d = a; d /= b; M3(d.ToMat3()); V3(d.ToVec3());
		M3(a.ToMat3()); V3(a.ToVec3());
		I(a.Compare(a)); I(a.Compare(b)); I(a.Compare(b, 1.0f)); I(a.Compare(a, 0.0f));
		End();
		idJointQuat q = a.ToJointQuat();
		N("jm_quat"); M3(ma); V3(ta); Bar(); F(q.q.x); F(q.q.y); F(q.q.z); F(q.q.w); V3(q.t); End();
	}
	// the three branches of ToJointQuat on diagonal-dominant matrices
	for (int n = 0; n < 12; n++) {
		idMat3 ma(1, 0, 0, 0, 1, 0, 0, 0, 1);
		int axis = n % 3; float s = (n < 6) ? -1.0f : -0.9f;
		ma[0][0] = ma[1][1] = ma[2][2] = s; ma[axis][axis] = 1.0f;
		ma[0][1] = ma[1][0] = rf(0.05f); ma[0][2] = ma[2][0] = rf(0.05f); ma[1][2] = ma[2][1] = rf(0.05f);
		idJointMat a; a.SetRotation(ma); a.SetTranslation(rv(1));
		idJointQuat q = a.ToJointQuat();
		N("jm_quat"); M3(ma); V3(a.ToVec3()); Bar(); F(q.q.x); F(q.q.y); F(q.q.z); F(q.q.w); V3(q.t); End();
	}
}

int main(int argc, char **argv) {
	idSys s; idCommon c; idLib::sys = &s; idLib::common = &c; idMath::Init();
	generic = new idSIMD_Generic; SIMDProcessor = generic;
	out = fopen(argc > 1 ? argv[1] : "surface.golden.txt", "w");
	DrawVerts();
	JointMats();
	Windings2D();
	Surfaces();
	Polytopes();
	g_xyzOnly = false;
	Patches();
	fclose(out);
	return 0;
}
