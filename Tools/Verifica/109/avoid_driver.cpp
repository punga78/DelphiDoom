// Issue #109: scenario of the obstacle avoidance of Doom 3 (AI_pathing.cpp), run on the REAL functions.
// Build-AvoidHarness.ps1 puts in front of this tail: the head of Tests\Data\MapFile\harness\aas_driver.cpp.txt (up to main:
// files in memory, idCommon that prints "P:" and "W:" lines) and the real lines of AI_pathing.cpp (obstacle avoidance and
// Ballistics). The Delphi twin is Tests\Source\DelphiDoom.Tests.Aas.D3.AvoidScenario.pas: every line printed here is printed
// there with the same text.

idGameLocal gameLocal;
// the debug drawing (AAS_debug.cpp) is not linked
void idAASLocal::Test( const idVec3 & ) {}
void idAASLocal::ShowWalkPath( const idVec3 &, int, const idVec3 & ) const {}
void idAASLocal::ShowFlyPath( const idVec3 &, int, const idVec3 & ) const {}
idRenderWorld *gameRenderWorld = 0;
idVec4 colorWhite, colorGreen, colorYellow, colorBlue, colorRed, colorCyan;
idCVar ai_showObstacleAvoidance( "ai_showObstacleAvoidance", "0", 0, "" );
idTypeInfo idActor::Type;
idTypeInfo idMoveable::Type;
static idTypeInfo otherType;

void idGameLocal::Printf( const char *fmt, ... ) { char b[4096]; va_list ap; va_start( ap, fmt ); vsprintf( b, fmt, ap ); va_end( ap ); printf( "P: %s\n", esc( b ) ); }
void idGameLocal::Warning( const char *fmt, ... ) { char b[4096]; va_list ap; va_start( ap, fmt ); vsprintf( b, fmt, ap ); va_end( ap ); printf( "W: %s\n", esc( b ) ); }
void idGameLocal::Error( const char *fmt, ... ) { char b[4096]; va_list ap; va_start( ap, fmt ); vsprintf( b, fmt, ap ); va_end( ap ); throw idException( b ); }

// the models of the scenario that the physics "touch"
static idClipModel *g_models[MAX_GENTITIES];
static int g_numModels = 0;
int idClip::ClipModelsTouchingBounds( const idBounds &bounds, int mask, idClipModel **list, int maxCount ) {
	int i, n = 0;
	for ( i = 0; i < g_numModels && n < maxCount; i++ ) {
		if ( g_models[i]->absBounds.IntersectsBounds( bounds ) ) list[n++] = g_models[i];
	}
	return n;
}

static unsigned g_seed;
static unsigned rnd( void ) { g_seed ^= g_seed << 13; g_seed ^= g_seed >> 17; g_seed ^= g_seed << 5; return g_seed; }
static void pv( const char *tag, const idVec3 &v ) { printf( " %s #%08x #%08x #%08x", tag, F(v.x), F(v.y), F(v.z) ); }
static void p2( const char *tag, const idVec2 &v ) { printf( " %s #%08x #%08x", tag, F(v.x), F(v.y) ); }
static const float MILLI = 0.001f;
static int entNum( const idEntity *e ) { return e ? e->number : 0; }

// 4 axes: no rotation, two rotations by a made up angle and a quarter turn
static const float AXC[4] = { 1.0f, 0.8f, 0.0f, -0.6f };
static const float AXS[4] = { 0.0f, 0.6f, 1.0f, 0.8f };

// ---------------------------------------------------------------------------------------------------------------------
// scenario A: idAI::FindPathAroundObstacles on a real idAASLocal, with models in the way

static idEntity g_ents[256];
static idClipModel g_clip[256];
static idPhysics g_self, g_other;

static void scenarioA( idAASLocal &aas, int count ) {
	int k, i, n, a;
	idPhysics self;
	for ( k = 0; k < count; k++ ) {
		idVec3 start, seek, vel;
		obstaclePath_t path;
		idEntity ignore, selfEnt;
		{ float x = 16.0f + (float)( rnd() % 3840 ) * 0.125f; float y = 16.0f + (float)( rnd() % 1280 ) * 0.125f; start = idVec3( x, y, 1.0f ); }
		{ float x = 16.0f + (float)( rnd() % 3840 ) * 0.125f; float y = 16.0f + (float)( rnd() % 1280 ) * 0.125f; seek = idVec3( x, y, 1.0f ); }
		a = rnd() % 3;
		vel = a == 0 ? idVec3( 0, 0, 0 ) : ( a == 1 ? idVec3( 60, 0, 0 ) : idVec3( -60, 0, 0 ) );
		self.bounds = idBounds( idVec3( -16, -16, 0 ), idVec3( 16, 16, 72 ) );
		self.origin = start;
		self.absBounds = idBounds( start + self.bounds[0], start + self.bounds[1] );
		self.gravityNormal = idVec3( 0, 0, -1 );
		self.linearVelocity = vel;
		self.clipMask = 1;
		selfEnt.number = 1; selfEnt.health = 100; selfEnt.type = &idActor::Type; selfEnt.phys = &self;
		ignore.number = 2; ignore.health = 100; ignore.type = &idActor::Type; ignore.phys = &g_other;
		g_numModels = 0;
		n = rnd() % 8;
		for ( i = 0; i < n; i++ ) {
			int kind = rnd() % 8, ax = rnd() % 4;
			float t = (float)( rnd() % 1001 ) * MILLI;
			idVec3 point = start + ( seek - start ) * t;
			float ox = point.x + (float)( (int)( rnd() % 641 ) - 320 ) * 0.125f;
			float oy = point.y + (float)( (int)( rnd() % 641 ) - 320 ) * 0.125f;
			idVec3 org = idVec3( ox, oy, 0.0f );
			float hx = 8.0f + (float)( rnd() % 129 ) * 0.125f;
			float hy = 8.0f + (float)( rnd() % 129 ) * 0.125f;
			float hz = 16.0f + (float)( rnd() % 65 );
			float r = ( hx > hy ? hx : hy ) * 1.5f;
			idEntity &e = g_ents[i];
			idClipModel &m = g_clip[i];
			e.number = 100 + i;
			e.health = 100;
			e.phys = &g_other;
			// 0 moveable, 1 alive actor, 2 dead actor, 3 something else, 4 actor moving along +x, 5 the entity to ignore, 6 the walker itself
			e.type = &idActor::Type;
			if ( kind == 0 ) e.type = &idMoveable::Type;
			if ( kind == 2 ) e.health = 0;
			if ( kind == 3 ) e.type = &otherType;
			if ( kind == 4 ) { static idPhysics moving[256]; moving[i].linearVelocity = idVec3( 50, 0, 0 ); e.phys = &moving[i]; }
			if ( kind == 6 ) e.phys = &self;
			m.entity = &e;
			m.bounds = idBounds( idVec3( -hx, -hy, 0 ), idVec3( hx, hy, hz ) );
			m.origin = org;
			m.absBounds = idBounds( idVec3( org.x - r, org.y - r, 0.0f ), idVec3( org.x + r, org.y + r, hz ) );
			m.axis = idMat3( AXC[ax], AXS[ax], 0.0f, -AXS[ax], AXC[ax], 0.0f, 0.0f, 0.0f, 1.0f );
			g_models[g_numModels++] = &m;
			// the pointer of the entity to ignore is the one of the "ignore" entity: the scenario uses its own copy
			if ( kind == 5 ) g_models[g_numModels - 1]->entity = &ignore;
		}
		bool ok = idAI::FindPathAroundObstacles( &self, &aas, &ignore, start, seek, path );
		printf( "FP %d %d %d", k, ok ? 1 : 0, n );
		pv( "S", path.seekPos ); printf( " %d", entNum( path.firstObstacle ) );
		pv( "O", path.startPosOutsideObstacles ); printf( " %d", entNum( path.startPosObstacle ) );
		pv( "G", path.seekPosOutsideObstacles ); printf( " %d\n", entNum( path.seekPosObstacle ) );
	}
}

// ---------------------------------------------------------------------------------------------------------------------
// scenario B: the functions on windings made here

static void dumpTree( const pathNode_t *node, int depth, bool withDist ) {
	if ( !node ) return;
	printf( "TN %d %d", depth, node->dir ); p2( "P", node->pos ); p2( "D", node->delta );
	printf( " %d %d %d", node->obstacle, node->edgeNum, node->numNodes );
	// the distance is set by PrunePathTree: before it the original leaves it as it was in the memory
	if ( withDist ) printf( " #%08x", F(node->dist) );
	printf( "\n" );
	dumpTree( node->children[0], depth + 1, withDist );
	dumpTree( node->children[1], depth + 1, withDist );
}

static void scenarioB( int count ) {
	int k, i, j;
	static obstacle_t obstacles[8];
	for ( k = 0; k < count; k++ ) {
		int n = 1 + rnd() % 6;
		idBounds clipBounds( idVec3( 0, 0, -100 ), idVec3( 520, 200, 100 ) );
		idVec2 expMins( -17.0f, -17.0f ), expMaxs( 17.0f, 17.0f );
		float sx = 16.0f + (float)( rnd() % 3840 ) * 0.125f; float sy = 16.0f + (float)( rnd() % 1280 ) * 0.125f;
		idVec2 start( sx, sy );
		float gx = 16.0f + (float)( rnd() % 3840 ) * 0.125f; float gy = 16.0f + (float)( rnd() % 1280 ) * 0.125f;
		idVec2 seek( gx, gy );
		idVec2 expB[2]; expB[0] = expMins; expB[1] = expMaxs;
		for ( i = 0; i < n; i++ ) {
			int ax = rnd() % 4;
			float cx = 16.0f + (float)( rnd() % 3840 ) * 0.125f, cy = 16.0f + (float)( rnd() % 1280 ) * 0.125f;
			float hx = 8.0f + (float)( rnd() % 129 ) * 0.125f, hy = 8.0f + (float)( rnd() % 129 ) * 0.125f;
			float lx[4] = { -hx, hx, hx, -hx }, ly[4] = { -hy, -hy, hy, hy };
			obstacles[i].winding.Clear();
			for ( j = 0; j < 4; j++ ) {
				idVec2 p( cx + AXC[ax] * lx[j] - AXS[ax] * ly[j], cy + AXS[ax] * lx[j] + AXC[ax] * ly[j] );
				obstacles[i].winding.AddPoint( p );
			}
			obstacles[i].winding.ExpandForAxialBox( expB );
			obstacles[i].winding.GetBounds( obstacles[i].bounds );
			obstacles[i].entity = (idEntity *)0;
			if ( i & 1 ) { static idEntity dummy[8]; dummy[i].number = 100 + i; obstacles[i].entity = &dummy[i]; }
		}
		printf( "OB %d %d", k, n ); p2( "S", start ); p2( "G", seek ); printf( "\n" );
		// the point inside an obstacle and the way out
		{
			int inside = PointInsideObstacle( obstacles, n, start );
			idVec2 out = start; int ob, edge;
			GetPointOutsideObstacles( obstacles, n, out, &ob, &edge );
			printf( "PI %d %d", k, inside ); p2( "O", out ); printf( " %d %d\n", ob, edge );
			out = seek;
			GetPointOutsideObstacles( obstacles, n, out, &ob, &edge );
			printf( "PO %d", k ); p2( "O", out ); printf( " %d %d\n", ob, edge );
		}
		// the first obstacle that blocks the movement
		{
			float scale = 0; int bo = -9, be = -9;
			bool b = GetFirstBlockingObstacle( obstacles, n, -1, start, seek - start, scale, bo, be );
			printf( "BL %d %d #%08x %d %d\n", k, b ? 1 : 0, F(scale), bo, be );
		}
		// the path tree
		{
			obstaclePath_t path;
			path.firstObstacle = 0;
			idVec2 s2 = start, g2 = seek;
			pathNode_t *root = BuildPathTree( obstacles, n, clipBounds, s2, g2, path );
			printf( "BT %d %d %d\n", k, entNum( path.firstObstacle ), pathNodeAllocator.GetAllocCount() );
			dumpTree( root, 0, false );
			PrunePathTree( root, g2 );
			printf( "PT %d %d\n", k, pathNodeAllocator.GetAllocCount() );
			dumpTree( root, 0, true );
			idVec3 seekPos;
			float dx = (float)( (int)( rnd() % 21 ) - 10 ); float dy = (float)( (int)( rnd() % 21 ) - 10 );
			bool ok = FindOptimalPath( root, obstacles, n, 5.0f, idVec3( dx, dy, 0.0f ), seekPos );
			printf( "FO %d %d", k, ok ? 1 : 0 ); pv( "S", seekPos ); printf( "\n" );
			FreePathTree_r( root );
			printf( "FT %d %d\n", k, pathNodeAllocator.GetAllocCount() );
		}
	}
}

// the shots
static void scenarioC( int count ) {
	int k, n, i;
	for ( k = 0; k < count; k++ ) {
		float s0 = (float)( rnd() % 400 ) * 0.25f; float s1 = (float)( rnd() % 400 ) * 0.25f; float s2 = (float)( rnd() % 200 ) * 0.25f;
		float e0 = (float)( rnd() % 400 ) * 0.25f; float e1 = (float)( rnd() % 400 ) * 0.25f; float e2 = (float)( rnd() % 200 ) * 0.25f;
		idVec3 s( s0, s1, s2 ), e( e0, e1, e2 );
		float speed = 100.0f + (float)( rnd() % 1500 );
		float gravity = 100.0f + (float)( rnd() % 900 );
		float zvel = (float)( rnd() % 700 ) - 300.0f;
		ballistics_t bal[2];
		memset( bal, 0, sizeof( bal ) );
		n = Ballistics( s, e, speed, gravity, bal );
		printf( "BA %d %d", k, n );
		for ( i = 0; i < n; i++ ) printf( " #%08x #%08x", F(bal[i].angle), F(bal[i].time) );
		printf( " #%08x\n", F(HeightForTrajectory( s, zvel, gravity )) );
	}
}

int main( int argc, char **argv ) {
	idLib::common = &theCommon; idLib::fileSystem = &theFs; fileSystem = &theFs; common = &theCommon;
	idMath::Init(); idDict::Init();
	if ( argc < 2 ) { printf( "usage: avoid <folder>\n" ); return 1; }
	char path[1024];
	sprintf( path, "%s\\cases.txt", argv[1] );
	Blob cases = readAll( path );
	char *p = cases.p;
	while ( p && *p ) {
		char *e = strchr( p, '\n' ); if ( e ) *e = 0;
		char line[512]; strcpy( line, p );
		if ( e ) p = e + 1; else p = 0;
		int l = (int)strlen( line ); while ( l > 0 && ( line[l - 1] == '\r' || line[l - 1] == ' ' ) ) line[--l] = 0;
		if ( !l || line[0] == '#' ) continue;
		char name[256]; unsigned int crc = 0;
		if ( sscanf( line, "%255s %u", name, &crc ) < 2 ) continue;
		sprintf( path, "%s\\%s", argv[1], name );
		Blob data = readAll( path );
		numFiles = 0;
		if ( data.p ) { Entry *en = putFile( name ); en->data.Append( data.p, data.n ); }
		printf( "CASE %s\n", name );
		try {
			idAASLocal aas;
			bool ok = aas.Init( idStr( name ), crc );
			printf( "INIT %d\n", ok ? 1 : 0 );
			if ( !ok ) continue;
			g_seed = 2463534242u;
			scenarioA( aas, 150 );
			printf( "NODES %d\n", pathNodeAllocator.GetAllocCount() );
			scenarioB( 120 );
			scenarioC( 60 );
		} catch ( idException &ex ) {
			printf( "EXC %s\n", esc( ex.error ) );
		}
	}
	return 0;
}
