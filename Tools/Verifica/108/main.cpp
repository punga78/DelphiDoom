// Parity harness for the Doom 3 collision model (issue #108).
//
//   harness.exe <map file> <golden file> [seed] [queriesPerKind]
//
// Builds the collision models of the map with the REAL neo\cm code (the .cm file is written beside the map), frees
// them, loads them again from that .cm file (so the queries run on exactly the model that the Delphi reader gets),
// then runs scripted translations, rotations, position tests and contact searches with trace models of every kind
// and writes one line per query: the inputs and the answer, every float as its bits (#xxxxxxxx).
#include "../idlib/precompiled.h"
#pragma hdrstop
#define private public
#include "../cm/CollisionModel_local.h"
#undef private
#include "../idlib/math/Simd_Generic.h"
#include <direct.h>

extern idCollisionModelManagerLocal collisionModelManagerLocal;
extern int harnessVerbose;
static idCollisionModelManagerLocal &cm = collisionModelManagerLocal;
static FILE *out;

// ------------------------------------------------------------------------------------------ numbers

static unsigned int rngState;
static unsigned int Rnd( void ) { rngState = rngState * 1664525u + 1013904223u; return rngState >> 8; }
static float Rf( float lo, float hi ) { return lo + ( hi - lo ) * ( Rnd() / 16777216.0f ); }
static int Ri( int n ) { return (int) ( Rnd() % (unsigned) n ); }
// a coordinate on the half unit grid one time in three: this is where edges and planes meet exactly
static float Rg( float lo, float hi ) {
	float f = Rf( lo, hi );
	return ( Ri( 3 ) == 0 ) ? idMath::Floor( f * 2.0f + 0.5f ) * 0.5f : f;
}

static void F( float f ) {
	unsigned int u;
	memcpy( &u, &f, 4 );
	fprintf( out, " #%08x", u );
}
static void V( const idVec3 &v ) { F( v.x ); F( v.y ); F( v.z ); }
static void M( const idMat3 &m ) { V( m[0] ); V( m[1] ); V( m[2] ); }
static void I( int i ) { fprintf( out, " %d", i ); }
static void S( const char *s ) { fprintf( out, " %s", s ); }

// ------------------------------------------------------------------------------------------ trace models

typedef struct {
	char kind;	// P point, B box, Y cylinder, N bone
	idBounds b;
	int sides;
	float len, width;
	idTraceModel trm;
} trmSpec_t;

static void PrintTrm( const trmSpec_t &t ) {
	fprintf( out, " %c", t.kind );
	switch ( t.kind ) {
		case 'B': V( t.b[0] ); V( t.b[1] ); break;
		case 'Y': V( t.b[0] ); V( t.b[1] ); I( t.sides ); break;
		case 'N': F( t.len ); F( t.width ); break;
	}
}

static void RandomTrm( trmSpec_t &t ) {
	int k = Ri( 8 );
	t.kind = ( k == 0 ) ? 'P' : ( k < 4 ) ? 'B' : ( k < 6 ) ? 'Y' : 'N';
	if ( t.kind == 'B' || t.kind == 'Y' ) {
		float x = Rg( 2, 20 ), y = Rg( 2, 20 ), z = Rg( 2, 40 );
		float ox = Rg( -4, 4 ), oy = Rg( -4, 4 ), oz = Rg( -4, 4 );
		t.b[0].Set( ox - x, oy - y, oz - z );
		t.b[1].Set( ox + x, oy + y, oz + z );
		t.sides = 3 + Ri( 6 );
		if ( t.kind == 'B' ) t.trm.SetupBox( t.b ); else t.trm.SetupCylinder( t.b, t.sides );
	} else if ( t.kind == 'N' ) {
		t.len = Rg( 8, 48 );
		t.width = Rg( 2, 12 );
		t.trm.SetupBone( t.len, t.width );
	}
}

static idMat3 RandomAxis( void ) {
	int k = Ri( 4 );
	if ( k < 2 ) return mat3_identity;
	if ( k == 2 ) return idAngles( 0.0f, 90.0f * Ri( 4 ), 0.0f ).ToMat3();
	return idAngles( Rf( -180, 180 ), Rf( -180, 180 ), Rf( -180, 180 ) ).ToMat3();
}

// ------------------------------------------------------------------------------------------ results

static void CollectPolygons( cm_node_t *node, idList<cm_polygon_t *> &list ) {
	while ( node ) {
		for ( cm_polygonRef_t *pref = node->polygons; pref; pref = pref->next ) {
			if ( pref->p && list.FindIndex( pref->p ) < 0 ) list.Append( pref->p );
		}
		if ( node->planeType == -1 ) break;
		CollectPolygons( node->children[0], list );
		node = node->children[1];
	}
}

static idList<cm_polygon_t *> polygons;

static int FeatureOf( const contactInfo_t &c ) {
	if ( c.type == CONTACT_TRMVERTEX ) {
		// the C++ code stores the address of the polygon: the number of the polygon in tree order stands for it
		cm_polygon_t *p = *reinterpret_cast<cm_polygon_t * const *>( &c.modelFeature );
		return polygons.FindIndex( p );
	}
	return c.modelFeature;
}

static void PrintContact( const contactInfo_t &c ) {
	I( (int) c.type );
	V( c.normal ); F( c.dist ); I( c.contents );
	S( c.material ? c.material->GetName() : "-" );
	I( FeatureOf( c ) ); I( c.trmFeature );
	V( c.point );
}

static void PrintTrace( const trace_t &r ) {
	F( r.fraction ); V( r.endpos ); M( r.endAxis );
	if ( r.fraction < 1.0f ) PrintContact( r.c );
}

// ------------------------------------------------------------------------------------------ queries

static void Frame( idBounds &b, idVec3 &modelOrigin, idMat3 &modelAxis ) {
	if ( Ri( 3 ) == 0 ) {
		modelOrigin.Set( Rg( -128, 128 ), Rg( -128, 128 ), Rg( -64, 64 ) );
		modelAxis = RandomAxis();
	} else {
		modelOrigin.Zero();
		modelAxis = mat3_identity;
	}
}

static void RandomPoint( const idBounds &b, idVec3 &p ) {
	p.Set( Rg( b[0].x, b[1].x ), Rg( b[0].y, b[1].y ), Rg( b[0].z, b[1].z ) );
}

static void RunQueries( int model, int count ) {
	idBounds b = cm.models[model]->bounds;
	b[0] -= idVec3( 48, 48, 48 );
	b[1] += idVec3( 48, 48, 48 );
	int masks[] = { -1, CONTENTS_SOLID, CONTENTS_PLAYERCLIP | CONTENTS_MONSTERCLIP, CONTENTS_WATER, CONTENTS_SOLID | CONTENTS_BODY };

	for ( int n = 0; n < count; n++ ) {
		trmSpec_t t;
		idVec3 start, end, modelOrigin;
		idMat3 trmAxis, modelAxis;
		trace_t r;
		int mask;
		idBounds fb = b;

		// translation
		RandomTrm( t );
		trmAxis = RandomAxis();
		Frame( fb, modelOrigin, modelAxis );
		mask = masks[Ri( 5 )];
		RandomPoint( b, start );
		float len = ( Ri( 6 ) == 0 ) ? Rf( 200, 700 ) : Rf( 1, 120 );
		idVec3 dir( Rg( -1, 1 ), Rg( -1, 1 ), Rg( -1, 1 ) );
		if ( dir.Normalize() == 0.0f ) dir.Set( 1, 0, 0 );
		if ( Ri( 4 ) == 0 ) { dir.Set( 0, 0, 0 ); dir[Ri( 3 )] = ( Ri( 2 ) ? 1.0f : -1.0f ); }
		end = start + dir * len;
		cm.Translation( &r, start, end, t.kind == 'P' ? NULL : &t.trm, trmAxis, mask, model, modelOrigin, modelAxis );
		fprintf( out, "T %d %d |", model, mask ); V( start ); V( end ); fprintf( out, " |" ); PrintTrm( t );
		fprintf( out, " |" ); M( trmAxis ); fprintf( out, " |" ); V( modelOrigin ); M( modelAxis ); fprintf( out, " |" );
		PrintTrace( r ); fprintf( out, "\n" );

		// rotation
		RandomTrm( t );
		trmAxis = RandomAxis();
		Frame( fb, modelOrigin, modelAxis );
		mask = masks[Ri( 5 )];
		RandomPoint( b, start );
		idVec3 org, vec;
		RandomPoint( b, org );
		vec.Set( Rg( -1, 1 ), Rg( -1, 1 ), Rg( -1, 1 ) );
		if ( vec.Normalize() == 0.0f ) vec.Set( 0, 0, 1 );
		if ( Ri( 3 ) == 0 ) { vec.Set( 0, 0, 0 ); vec[Ri( 3 )] = 1.0f; }
		float angle;
		switch ( Ri( 12 ) ) {
			case 0: angle = 0.0f; break;
			case 1: angle = Rf( 181, 400 ); break;
			case 2: angle = -Rf( 181, 400 ); break;
			case 3: angle = ( Ri( 2 ) ? 90.0f : -90.0f ); break;
			default: angle = Rf( -179, 179 ); break;
		}
		idRotation rot( org, vec, angle );
		cm.Rotation( &r, start, rot, t.kind == 'P' ? NULL : &t.trm, trmAxis, mask, model, modelOrigin, modelAxis );
		fprintf( out, "R %d %d |", model, mask ); V( start ); V( org ); V( vec ); F( angle ); fprintf( out, " |" ); PrintTrm( t );
		fprintf( out, " |" ); M( trmAxis ); fprintf( out, " |" ); V( modelOrigin ); M( modelAxis ); fprintf( out, " |" );
		PrintTrace( r ); fprintf( out, "\n" );

		// position test
		if ( n % 2 == 0 ) {
			RandomTrm( t );
			trmAxis = RandomAxis();
			Frame( fb, modelOrigin, modelAxis );
			mask = masks[Ri( 5 )];
			RandomPoint( b, start );
			int c = cm.Contents( start, t.kind == 'P' ? NULL : &t.trm, trmAxis, mask, model, modelOrigin, modelAxis );
			fprintf( out, "C %d %d |", model, mask ); V( start ); fprintf( out, " |" ); PrintTrm( t );
			fprintf( out, " |" ); M( trmAxis ); fprintf( out, " |" ); V( modelOrigin ); M( modelAxis ); fprintf( out, " | %d\n", c );
		}

		// contacts
		if ( n % 3 == 0 ) {
			RandomTrm( t );
			trmAxis = RandomAxis();
			Frame( fb, modelOrigin, modelAxis );
			mask = masks[Ri( 5 )];
			RandomPoint( b, start );
			idVec6 d6;
			idVec3 cd( Rg( -1, 1 ), Rg( -1, 1 ), Rg( -1, 1 ) );
			if ( cd.Normalize() == 0.0f ) cd.Set( 0, 0, -1 );
			d6.Set( cd.x, cd.y, cd.z, 0, 0, 0 );
			float depth = Rg( 0.5f, 8.0f );
			contactInfo_t contacts[32];
			int nc = cm.Contacts( contacts, 32, start, d6, depth, t.kind == 'P' ? NULL : &t.trm, trmAxis, mask, model, modelOrigin, modelAxis );
			fprintf( out, "K %d %d |", model, mask ); V( start ); V( cd ); F( depth ); fprintf( out, " |" ); PrintTrm( t );
			fprintf( out, " |" ); M( trmAxis ); fprintf( out, " |" ); V( modelOrigin ); M( modelAxis ); fprintf( out, " | %d", nc );
			for ( int i = 0; i < nc; i++ ) { fprintf( out, " ;" ); PrintContact( contacts[i] ); }
			fprintf( out, "\n" );
		}
	}
}

int main( int argc, char **argv ) {
	if ( argc < 3 ) {
		fprintf( stderr, "usage: harness <map> <golden> [seed] [count]\n" );
		return 1;
	}
	rngState = ( argc > 3 ) ? (unsigned) atoi( argv[3] ) : 1u;
	int count = ( argc > 4 ) ? atoi( argv[4] ) : 100;

	static idSIMD_Generic generic;
	SIMDProcessor = &generic;
	Swap_Init();
	idMath::Init();
	idStr::InitMemory();
	idDict::Init();
	idLib::sys = sys;
	idLib::common = common;
	idLib::fileSystem = fileSystem;
	harnessVerbose = ( getenv( "HARNESS_VERBOSE" ) != NULL );

	// idStr::SetFileExtension cuts at the last '.' of the whole path, so work from the folder of the map (a path
	// with a dot in a folder name, like ".claude", would lose its tail)
	char goldenPath[1024];
	_fullpath( goldenPath, argv[2], sizeof( goldenPath ) );
	char mapDir[1024];
	_fullpath( mapDir, argv[1], sizeof( mapDir ) );
	char *slash = strrchr( mapDir, '\\' );
	if ( !slash ) return 1;
	*slash = 0;
	if ( chdir( mapDir ) != 0 ) return 1;
	const char *mapName = strrchr( argv[1], '\\' );
	mapName = mapName ? mapName + 1 : argv[1];
	if ( strrchr( mapName, '/' ) ) mapName = strrchr( mapName, '/' ) + 1;
	argv[2] = goldenPath;

	idMapFile map;
	if ( !map.Parse( mapName, false, true ) ) {
		fprintf( stderr, "cannot read %s\n", argv[1] );
		return 1;
	}
	// build, write the .cm file, free, then load that file again
	cm.LoadMap( &map );
	int built = cm.numModels;
	cm.FreeMap();
	cm.LoadMap( &map );
	if ( cm.numModels != built ) {
		fprintf( stderr, "reloaded %d models instead of %d\n", cm.numModels, built );
		return 1;
	}

	out = fopen( argv[2], "wb" );
	if ( !out ) return 1;
	for ( int m = 0; m < cm.numModels; m++ ) {
		// the models are listed so that a model that cannot be read back is noticed
		polygons.Clear();
		CollectPolygons( cm.models[m]->node, polygons );
		// the polygons of a model read from a file are allocated in file order, one after the other: the rank of
		// the address is the number that the Delphi reader gives (its Id minus one)
		for ( int i = 1; i < polygons.Num(); i++ ) {
			cm_polygon_t *p = polygons[i];
			int j = i - 1;
			while ( j >= 0 && (unsigned long) polygons[j] > (unsigned long) p ) { polygons[j + 1] = polygons[j]; j--; }
			polygons[j + 1] = p;
		}
		fprintf( out, "# model %d \"%s\" polygons %d vertices %d edges %d\n", m, cm.models[m]->name.c_str(),
			cm.models[m]->numPolygons, cm.models[m]->numVertices, cm.models[m]->numEdges );
		RunQueries( m, count );
	}
	fclose( out );
	return 0;
}
