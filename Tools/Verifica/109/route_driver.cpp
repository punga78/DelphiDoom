// Issue #109: scenario of the routing of Doom 3 (AAS.cpp, AAS_routing.cpp, AAS_pathing.cpp), run on the REAL idAASLocal.
// This is the tail of the driver; Build-Harness.ps1 puts the head of Tests\Data\MapFile\harness\aas_driver.cpp.txt (up to
// main, files in memory, idCommon that prints "P:" and "W:" lines) in front of it. The Delphi twin is
// Tests\Source\DelphiDoom.Tests.Aas.D3.Scenario.pas: every line printed here is printed there with the same text.

// the part of the game that AAS_routing.cpp uses
// (the class is declared in precompiled.h, where AAS_routing.cpp finds it in place of Game_local.h)
void idGameLocal::Printf(const char *fmt, ...) { char b[4096]; va_list ap; va_start(ap, fmt); vsprintf(b, fmt, ap); va_end(ap); printf("P: %s\n", esc(b)); }
void idGameLocal::Error(const char *fmt, ...) { char b[4096]; va_list ap; va_start(ap, fmt); vsprintf(b, fmt, ap); va_end(ap); throw idException(b); }
idGameLocal gameLocal;
// the debug drawing (AAS_debug.cpp) is not linked
void idAASLocal::Test(const idVec3 &) {}
void idAASLocal::ShowWalkPath(const idVec3 &, int, const idVec3 &) const {}
void idAASLocal::ShowFlyPath(const idVec3 &, int, const idVec3 &) const {}

class moduloCallback : public idAASCallback {
public:
	int mod, rem, asked;
	moduloCallback(int m, int r) : mod(m), rem(r), asked(0) {}
	virtual bool TestArea(const idAAS *aas, int areaNum) { asked++; return (areaNum * 7 + rem) % mod == 0; }
};

static const int TRAVEL[3] = {
	TFL_WALK | TFL_CROUCH | TFL_WALKOFFLEDGE | TFL_BARRIERJUMP | TFL_JUMP | TFL_LADDER | TFL_SWIM | TFL_WATERJUMP | TFL_TELEPORT | TFL_ELEVATOR | TFL_FLY | TFL_WATER | TFL_AIR,
	TFL_WALK | TFL_CROUCH | TFL_AIR,
	TFL_WALK | TFL_CROUCH | TFL_WALKOFFLEDGE | TFL_BARRIERJUMP | TFL_JUMP | TFL_LADDER | TFL_SWIM | TFL_WATERJUMP | TFL_TELEPORT | TFL_ELEVATOR | TFL_WATER | TFL_AIR
};

static void pv(const char *tag, const idVec3 &v) { printf("%s #%08x #%08x #%08x", tag, F(v.x), F(v.y), F(v.z)); }

static void dumpAreas(idAASLocal &aas) {
	idAASFile *f = aas.file;
	int n = f->GetNumAreas(), i;
	printf("AREAS %d %d %d\n", n, f->GetNumClusters(), f->GetNumPortals());
	for (i = 0; i < n; i++) {
		const aasArea_t &a = f->GetArea(i);
		printf("AR %d %d %d %d %d %d", i, (int)a.flags, (int)a.travelFlags, (int)a.contents, (int)a.cluster, (int)a.clusterAreaNum);
		pv(" C", a.center); printf("\n");
	}
	for (i = 1; i < f->GetNumPortals(); i++) printf("PT %d %d %d\n", i, (int)f->GetPortal(i).areaNum, (int)f->GetPortal(i).maxAreaTravelTime);
	for (i = 0; i < n; i++) {
		int k = 0;
		for (const idReachability *r = f->GetArea(i).reach; r; r = r->next, k++)
			printf("RE %d %d %d %d %d %d %d\n", i, k, (int)r->travelType, (int)r->toAreaNum, (int)r->number, (int)r->disableCount, (int)r->travelTime);
	}
}

static void dumpCache(idAASLocal &aas) {
	int na = 0, np = 0;
	for (idRoutingCache *c = aas.cacheListStart; c; c = c->time_next) { if (c->type == 1) na++; else np++; }
	printf("CACHE %d %d %d\n", na, np, aas.totalCacheMemory);
}

static void routes(idAASLocal &aas, const char *tag, int v, int step) {
	int n = aas.file->GetNumAreas(), a, b;
	for (a = 1; a < n; a += step) for (b = 1; b < n; b++) {
		if (a == b) continue;
		idReachability *r = NULL; int tt = -7;
		idVec3 org = aas.AreaCenter(a);
		bool ok = aas.RouteToGoalArea(a, org, b, TRAVEL[v], tt, &r);
		printf("%s %d %d %d %d %d %d %d\n", tag, v, a, b, ok ? 1 : 0, tt, r ? (int)r->toAreaNum : -1, r ? (int)r->number : -1);
	}
}

static void changes(idAASLocal &aas, const char *tag) {
	int n = aas.file->GetNumAreas(), i;
	for (i = 1; i < n; i++) {
		const aasArea_t &a = aas.file->GetArea(i);
		if (a.travelFlags & TFL_INVALID) printf("%s AF %d %d\n", tag, i, (int)a.travelFlags);
		int k = 0;
		for (const idReachability *r = a.reach; r; r = r->next, k++)
			if ((r->travelType & TFL_INVALID) || r->disableCount) printf("%s RF %d %d %d %d\n", tag, i, k, (int)r->travelType, (int)r->disableCount);
	}
}

static void paths(idAASLocal &aas) {
	int n = aas.file->GetNumAreas(), a, b, v;
	for (a = 1; a < n; a++) {
		b = (a * 5 + 3) % (n - 1) + 1;
		if (b == a) b = b % (n - 1) + 1;
		idVec3 org = aas.AreaCenter(a); org.x = org.x + 6; org.y = org.y - 5; org.z = org.z + 1;
		idVec3 goal = aas.AreaCenter(b); goal.x = goal.x - 7; goal.y = goal.y + 4; goal.z = goal.z + 1;
		for (v = 0; v < 2; v++) {
			aasPath_t p; bool ok = aas.WalkPathToGoal(p, a, org, b, goal, TRAVEL[v]);
			printf("WP %d %d %d %d %d", v, a, b, ok ? 1 : 0, p.type); pv(" G", p.moveGoal); printf(" %d", p.moveAreaNum); pv(" S", p.secondaryGoal);
			printf(" %d\n", p.reachability ? (int)p.reachability->number : -1);
		}
		{
			idVec3 endPos; int endArea = -99;
			bool ok = aas.WalkPathValid(a, org, b, goal, TRAVEL[0], endPos, endArea);
			printf("WV %d %d %d", a, b, ok ? 1 : 0); pv(" E", endPos); printf(" %d\n", ok ? endArea : -1);
			// the same line in the area of the goal itself, so that the loop is walked to the end
			ok = aas.WalkPathValid(a, org, a, goal, TRAVEL[1], endPos, endArea);
			printf("WW %d %d %d", a, b, ok ? 1 : 0); pv(" E", endPos); printf(" %d\n", ok ? endArea : -1);
		}
		{
			aasPath_t p; bool ok = aas.FlyPathToGoal(p, a, org, b, goal, TRAVEL[0]);
			printf("FP %d %d %d %d", a, b, ok ? 1 : 0, p.type); pv(" G", p.moveGoal); printf(" %d", p.moveAreaNum); pv(" S", p.secondaryGoal); printf("\n");
			idVec3 endPos; int endArea = -99;
			ok = aas.FlyPathValid(a, org, b, goal, TRAVEL[0], endPos, endArea);
			printf("FV %d %d %d", a, b, ok ? 1 : 0); pv(" E", endPos); printf(" %d\n", endArea);
		}
	}
}

static void goals(idAASLocal &aas) {
	int n = aas.file->GetNumAreas(), a, b, m, o;
	for (a = 1; a < n; a++) {
		b = (a * 3 + 1) % (n - 1) + 1;
		idVec3 org = aas.AreaCenter(a), target = aas.AreaCenter(b);
		for (m = 0; m < 3; m++) for (o = 0; o < 2; o++) {
			moduloCallback cb(m == 0 ? 5 : (m == 1 ? 3 : 11), (a + m) % 3);
			aasObstacle_t obs[1]; int numObs = 0;
			if (o) {
				idVec3 c = aas.AreaCenter((a * 2) % (n - 1) + 1);
				obs[0].absBounds = idBounds(idVec3(c.x - 10, c.y - 10, c.z), idVec3(c.x + 10, c.y + 10, c.z + 40));
				// FindNearestGoal fills expAbsBounds only after the first area has been tested: when that area is
				// accepted the original leaves it as it was (stack garbage), so the scenario starts it from zero
				obs[0].expAbsBounds = idBounds(idVec3(0, 0, 0), idVec3(0, 0, 0));
				numObs = 1;
			}
			aasGoal_t goal; goal.areaNum = -5; goal.origin = idVec3(1, 2, 3);
			bool ok = aas.FindNearestGoal(goal, a, org, target, TRAVEL[m == 2 ? 2 : 0], obs, numObs, cb);
			printf("FG %d %d %d %d %d %d", a, b, m, o, ok ? 1 : 0, goal.areaNum); pv(" O", goal.origin); printf(" %d", cb.asked);
			if (numObs) { pv(" X", obs[0].expAbsBounds[0]); pv(" Y", obs[0].expAbsBounds[1]); }
			printf("\n");
		}
	}
}

static void walls(idAASLocal &aas) {
	int n = aas.file->GetNumAreas(), a, k;
	idBounds all(idVec3(-10000, -10000, -10000), idVec3(10000, 10000, 10000));
	idBounds small(idVec3(-10000, -10000, -10000), idVec3(10, 10, 10000));
	for (a = 1; a < n; a++) for (k = 0; k < 2; k++) {
		int edges[64]; int num = aas.GetWallEdges(a, k ? small : all, TRAVEL[0], edges, 64);
		printf("WE %d %d %d", a, k, num);
		for (int i = 0; i < num; i++) printf(" %d", edges[i]);
		printf("\n");
		aas.SortWallEdges(edges, num);
		printf("WS %d %d", a, k);
		for (int i = 0; i < num; i++) printf(" %d", edges[i]);
		printf("\n");
	}
	for (a = -3; a <= 3; a++) {
		int v[2]; aas.GetEdgeVertexNumbers(a, v);
		idVec3 s, e; aas.GetEdge(a, s, e);
		printf("EV %d %d %d", a, v[0], v[1]); pv(" S", s); pv(" E", e); printf("\n");
	}
}

static void obstacles(idAASLocal &aas) {
	int n = aas.file->GetNumAreas(), i, h[3];
	// areas that are cluster portals are shut and opened
	for (i = 1; i < n; i++) {
		if (!(aas.file->GetArea(i).contents & AREACONTENTS_CLUSTERPORTAL)) continue;
		idVec3 c = aas.AreaCenter(i);
		idBounds b(idVec3(c.x - 2, c.y - 2, c.z), idVec3(c.x + 2, c.y + 2, c.z + 8));
		bool ok = aas.SetAreaState(b, AREACONTENTS_CLUSTERPORTAL, true);
		printf("SAS %d %d\n", i, ok ? 1 : 0);
		changes(aas, "SD");
		routes(aas, "RD", 0, 5);
		dumpCache(aas);
		ok = aas.SetAreaState(b, AREACONTENTS_CLUSTERPORTAL, false);
		printf("SAE %d %d\n", i, ok ? 1 : 0);
		changes(aas, "SE");
		routes(aas, "RE2", 0, 7);
	}
	{
		idBounds none(idVec3(-5000, -5000, 500), idVec3(-4000, -4000, 600));
		printf("SAN %d\n", aas.SetAreaState(none, AREACONTENTS_CLUSTERPORTAL, true) ? 1 : 0);
	}
	// obstacles: AddObstacle calls SetObstacleState( obstacle, true ) and RemoveObstacle calls it with false: the original
	// wraps the unsigned char count and ends with reachabilities that stay invalid, and the scenario keeps all of that
	for (i = 0; i < 3; i++) {
		idVec3 c = aas.AreaCenter(1 + (i * 5) % (n - 1));
		idBounds b(idVec3(c.x - 40, c.y - 40, c.z), idVec3(c.x + 40, c.y + 40, c.z + 60));
		h[i] = aas.AddObstacle(b);
		printf("AO %d %d\n", i, h[i]);
		changes(aas, "OA");
		routes(aas, "RO", 0, 6);
	}
	aas.RemoveObstacle(1); printf("RO1\n"); changes(aas, "OR"); routes(aas, "RR", 1, 6);
	aas.RemoveObstacle(7); printf("RO7\n");
	aas.RemoveObstacle(-1); printf("ROm\n");
	aas.RemoveAllObstacles(); printf("ROA\n"); changes(aas, "OZ"); routes(aas, "RZ", 0, 6);
	dumpCache(aas);
}

int main(int argc, char **argv) {
	idLib::common = &theCommon; idLib::fileSystem = &theFs; fileSystem = &theFs; common = &theCommon;
	idMath::Init(); idDict::Init();
	if (argc < 2) { printf("usage: route <folder>\n"); return 1; }
	char path[1024];
	sprintf(path, "%s\\cases.txt", argv[1]);
	Blob cases = readAll(path);
	char *p = cases.p;
	while (p && *p) {
		char *e = strchr(p, '\n'); if (e) *e = 0;
		char line[512]; strcpy(line, p);
		if (e) p = e + 1; else p = 0;
		int l = (int)strlen(line); while (l > 0 && (line[l - 1] == '\r' || line[l - 1] == ' ')) line[--l] = 0;
		if (!l || line[0] == '#') continue;
		char name[256]; unsigned int crc = 0;
		if (sscanf(line, "%255s %u", name, &crc) < 2) continue;
		sprintf(path, "%s\\%s", argv[1], name);
		Blob data = readAll(path);
		numFiles = 0;
		if (data.p) { Entry *en = putFile(name); en->data.Append(data.p, data.n); }
		printf("CASE %s\n", name);
		try {
			idAASLocal aas;
			bool ok = aas.Init(idStr(name), crc);
			printf("INIT %d\n", ok ? 1 : 0);
			if (!ok) continue;
			dumpAreas(aas);
			routes(aas, "RT", 0, 1);
			routes(aas, "RT", 1, 2);
			routes(aas, "RT", 2, 2);
			{
				int tt; idReachability *r;
				printf("RT0 %d\n", aas.RouteToGoalArea(0, idVec3(0, 0, 0), 1, TRAVEL[0], tt, &r) ? 1 : 0);
				printf("RTN %d\n", aas.RouteToGoalArea(1, idVec3(0, 0, 0), aas.file->GetNumAreas(), TRAVEL[0], tt, &r) ? 1 : 0);
			}
			printf("TT %d %d\n", aas.TravelTimeToGoalArea(1, aas.AreaCenter(1), 2, TRAVEL[0]), aas.TravelTimeToGoalArea(2, aas.AreaCenter(2), 2, TRAVEL[0]));
			dumpCache(aas);
			paths(aas);
			goals(aas);
			walls(aas);
			obstacles(aas);
			dumpCache(aas);
			printf("INIT2 %d\n", aas.Init(idStr(name), crc) ? 1 : 0);
			dumpCache(aas);
		} catch (idException &ex) {
			printf("EXC %s\n", esc(ex.error));
		}
	}
	return 0;
}
