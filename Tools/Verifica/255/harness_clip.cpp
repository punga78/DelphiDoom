// Issue #255 (Doom 3, phase 3, ondata 13): driver of the fifth parity harness (idClip). Written for this repository. It is linked with the
// REAL idlib, the REAL neo\cm (the collision model manager, built as in Tools\Verifica\108) and the REAL Clip.h; the text marked
// CLIP_REAL is the REAL Clip.cpp (without Save/Restore and the debug drawing) and ENTITY_REAL the REAL bodies of
// idEntity::TouchTriggers and idPhysics_Static::ClipContents/GetClipModel/GetNumClipModels/GetAbsBounds/SetClipModel/LinkClip, both cut out of the
// source by Build-Harness-Clip.ps1 at build time (nothing of Doom 3 is stored in the repository).
//
// The entities are fakes: a number, a name, a static physics with a clip model, and whether it answers <touch>. idPlayer::Think and
// idAI::Think are what calls TouchTriggers in the game; here the scenario command "touchtriggers" stands in for them.
//
// Usage: harness_clip.exe <scenario.scn> <golden.txt>   (run in the folder of room.map: the world is the collision model "worldMap")
//
// SCENARIO (one command per line, '#' and empty lines skipped, every command echoed as "CMD <line>"); numbers are floats written in decimal:
//   init                                       idClip::Init (prints the two lines of the original)
//   ent <n> [touch]                            a fake entity of that number; "touch" = it answers <touch>
//   box <k> <ent> <id> <contents> x0 y0 z0 x1 y1 z1       a clip model of a box trace model (entity <ent>, id <id>)
//   cyl <k> <ent> <id> <contents> x0 y0 z0 x1 y1 z1 sides  idem, a cylinder
//   bone <k> <ent> <id> <contents> length width            idem, a bone
//   physclip <ent> <k>                         the physics of the entity has the clip model k (SetClipModel: it is linked at the origin of the physics)
//   physorigin <ent> x y z pitch yaw roll      the origin and axis of the static physics (and of its clip model, relinked)
//   owner <k> <ent>                            the owner of the clip model (-1 none)
//   link <k> x y z pitch yaw roll              Link( clip, ent, id, origin, axis )
//   unlink <k> | enable <k> | disable <k> | contents <k> <value>
//   trans <k|-> sx sy sz ex ey ez pitch yaw roll mask pass
//   transents <k|-> ... idem                   idClip::TranslationEntities
//   rot <k|-> sx sy sz vx vy vz angle pitch yaw roll mask pass     rotation about the axis v through s
//   motion <k> sx sy sz ex ey ez vx vy vz angle pitch yaw roll mask pass    rotation origin = s
//   contentsat <k|-> sx sy sz pitch yaw roll mask pass
//   tracepoint sx sy sz ex ey ez mask pass | tracebounds sx sy sz ex ey ez bx0 by0 bz0 bx1 by1 bz1 mask pass
//   touching x0 y0 z0 x1 y1 z1 mask | entities x0 y0 z0 x1 y1 z1 mask
//   touchtriggers <ent>
// pass = entity number or "-" (none). Floats are written as their bits (%08X).
#include "../idlib/precompiled.h"
#pragma hdrstop
#define private public
#include "../cm/CollisionModel_local.h"
#undef private
#include "../idlib/math/Simd_Generic.h"
#include <direct.h>

extern idCollisionModelManagerLocal collisionModelManagerLocal;
static idCollisionModelManagerLocal &cm = collisionModelManagerLocal;
static FILE *g_golden;
static bool g_ready = false;

#define ENTITYNUM_BITS 12
#define MAX_GENTITIES ( 1 << ENTITYNUM_BITS )
#define ENTITYNUM_NONE ( MAX_GENTITIES - 1 )
#define ENTITYNUM_WORLD ( MAX_GENTITIES - 2 )
#define SIG_TOUCH 1
#define mat3_default mat3_identity
#define INVALID_JOINT ( (jointHandle_t) -1 )
typedef int jointHandle_t;
class idSaveGame;
class idRestoreGame;
struct idEventDef { int x; };
idEventDef EV_Touch;
class idMaterial;
class idClipModel;
class idEntity;
class idPhysics_Static;
class idClip;
struct modelTrace_s { float fraction; idVec3 point; idVec3 normal; const idMaterial *material; int jointNumber; };
typedef struct modelTrace_s modelTrace_t;
struct renderEntity_s { idBounds bounds; };
typedef struct renderEntity_s renderEntity_t;
class idRenderWorldHarness {
public:
	const renderEntity_t *GetRenderEntity( int ) const { return NULL; }
	bool ModelTrace( modelTrace_t &, int, const idVec3 &, const idVec3 &, float ) const { return false; }
};
static idRenderWorldHarness harnessRenderWorldImpl;
static idRenderWorldHarness *harnessRenderWorld = &harnessRenderWorldImpl;

@@CLIP_H@@

class idPhysics_Static {
public:
	idEntity *self;
	idClipModel *clipModel;
	struct { idVec3 origin; idMat3 axis; } current;
	idPhysics_Static() : self( NULL ), clipModel( NULL ) { current.origin.Zero(); current.axis.Identity(); }
	idClipModel *GetClipModel( int id = 0 ) const;
	int GetNumClipModels( void ) const;
	const idBounds &GetAbsBounds( int id = -1 ) const;
	const idVec3 &GetOrigin( int id = 0 ) const { return current.origin; }
	const idMat3 &GetAxis( int id = 0 ) const { return current.axis; }
	int ClipContents( const idClipModel *model ) const;
	void SetClipModel( idClipModel *model, float density, int id = 0, bool freeOld = true );
	void LinkClip( void );
};

class idEntity {
public:
	int entityNumber;
	idStr name;
	idPhysics_Static physics;
	bool respondsToTouch;
	idPhysics_Static *GetPhysics( void ) const { return const_cast<idPhysics_Static *>( &physics ); }
	const char *GetName( void ) const { return name.c_str(); }
	bool RespondsTo( const idEventDef & ) const { return respondsToTouch; }
	bool HasSignal( int ) const { return false; }
	void Signal( int ) {}
	bool ProcessEvent( const idEventDef *, const idEntity *other, trace_t *trace );
	bool TouchTriggers( void ) const;
};

class idGameLocalHarness {
public:
	idClip clip;
	idEntity *entities[ MAX_GENTITIES ];
	void Printf( const char *fmt, ... );
	void Warning( const char *fmt, ... );
	void Error( const char *fmt, ... );
};
static idGameLocalHarness gameLocal;

static const char *trimNl( char *s ) { int n = (int) strlen( s ); while ( n > 0 && s[n - 1] == 10 ) s[--n] = 0; return s; }
void idGameLocalHarness::Printf( const char *fmt, ... ) { char b[1024]; va_list a; va_start( a, fmt ); vsprintf( b, fmt, a ); va_end( a ); fprintf( g_golden, "PRINT %s\n", trimNl( b ) ); }
void idGameLocalHarness::Warning( const char *fmt, ... ) { char b[1024]; va_list a; va_start( a, fmt ); vsprintf( b, fmt, a ); va_end( a ); fprintf( g_golden, "WARNING %s\n", trimNl( b ) ); }
void idGameLocalHarness::Error( const char *fmt, ... ) { char b[1024]; va_list a; va_start( a, fmt ); vsprintf( b, fmt, a ); va_end( a ); fprintf( g_golden, "ERROR %s\n", trimNl( b ) ); fclose( g_golden ); exit( 4 ); }

// the REAL Clip.cpp (renamed: the globals of the fakes are idGameLocalHarness)
@@CLIP_REAL@@

// the REAL bodies of the entity and the static physics
@@ENTITY_REAL@@

bool idEntity::ProcessEvent( const idEventDef *, const idEntity *other, trace_t *trace ) {
	fprintf( g_golden, "TOUCH ent=%d by=%d contents=%d entityNum=%d id=%d endpos", entityNumber, other->entityNumber, trace->c.contents, trace->c.entityNum, trace->c.id );
	for ( int i = 0; i < 3; i++ ) { unsigned int u; memcpy( &u, &trace->endpos[i], 4 ); fprintf( g_golden, " %08X", u ); }
	for ( int r = 0; r < 3; r++ ) for ( int c = 0; c < 3; c++ ) { unsigned int u; memcpy( &u, &trace->endAxis[r][c], 4 ); fprintf( g_golden, " %08X", u ); }
	fprintf( g_golden, "\n" );
	return true;
}

// ------------------------------------------------------------------------------------------ the driver

static void F( float f ) { unsigned int u; memcpy( &u, &f, 4 ); fprintf( g_golden, " %08X", u ); }
static void V( const idVec3 &v ) { F( v.x ); F( v.y ); F( v.z ); }
static void M( const idMat3 &m ) { V( m[0] ); V( m[1] ); V( m[2] ); }

static idClipModel *clipModels[ 64 ];
static idTraceModel *traceModels[ 64 ];
static char tok[ 64 ][ 128 ];
static int ntok = 0;

static float Wf( size_t i ) { return (float) atof( tok[i] ); }
static int Wi( size_t i ) { return atoi( tok[i] ); }
static idVec3 Wv( size_t i ) { return idVec3( Wf( i ), Wf( i + 1 ), Wf( i + 2 ) ); }
static idMat3 Wa( size_t i ) { return idAngles( Wf( i ), Wf( i + 1 ), Wf( i + 2 ) ).ToMat3(); }
static idEntity *Pass( size_t i ) { return strcmp( tok[i], "-" ) == 0 ? NULL : gameLocal.entities[ Wi( i ) ]; }
static idClipModel *Mdl( size_t i ) { return strcmp( tok[i], "-" ) == 0 ? NULL : clipModels[ Wi( i ) ]; }

static void PrintTrace( int ret, const trace_t &t ) {
	fprintf( g_golden, "TRACE %d", ret );
	F( t.fraction ); V( t.endpos ); M( t.endAxis );
	if ( t.fraction < 1.0f ) {
		fprintf( g_golden, " type=%d", (int) t.c.type );
		V( t.c.point ); V( t.c.normal ); F( t.c.dist );
		fprintf( g_golden, " contents=%d modelFeature=%d trmFeature=%d", t.c.contents, t.c.type == CONTACT_TRMVERTEX ? 0 : t.c.modelFeature, t.c.trmFeature );
	}
	// the id of a trace that hit nothing is whatever the memory held (the collision model leaves it alone): not written
	fprintf( g_golden, " entityNum=%d", t.c.entityNum );
	if ( t.fraction < 1.0f ) fprintf( g_golden, " id=%d", t.c.id );
	fprintf( g_golden, "\n" );
}

static void Run( const idStr &cmd ) {
	if ( cmd == "init" ) { gameLocal.clip.Init(); return; }
	if ( cmd == "ent" ) {
		idEntity *e = new idEntity();
		e->entityNumber = Wi( 1 );
		e->name = va( "ent%d", e->entityNumber );
		e->physics.self = e;
		e->respondsToTouch = ( ntok > 2 && strcmp( tok[2], "touch" ) == 0 );
		gameLocal.entities[ e->entityNumber ] = e;
		return;
	}
	if ( cmd == "box" || cmd == "cyl" || cmd == "bone" ) {
		idTraceModel *t = new idTraceModel();
		if ( cmd == "box" ) t->SetupBox( idBounds( Wv( 5 ), Wv( 8 ) ) );
		else if ( cmd == "cyl" ) t->SetupCylinder( idBounds( Wv( 5 ), Wv( 8 ) ), Wi( 11 ) );
		else t->SetupBone( Wf( 5 ), Wf( 6 ) );
		idClipModel *m = new idClipModel( *t );
		m->SetEntity( gameLocal.entities[ Wi( 2 ) ] );
		m->SetId( Wi( 3 ) );
		m->SetContents( Wi( 4 ) );
		clipModels[ Wi( 1 ) ] = m;
		traceModels[ Wi( 1 ) ] = t;
		return;
	}
	if ( cmd == "physclip" ) { gameLocal.entities[ Wi( 1 ) ]->physics.SetClipModel( clipModels[ Wi( 2 ) ], 1.0f, 0, false ); return; }
	if ( cmd == "physorigin" ) {
		idPhysics_Static &p = gameLocal.entities[ Wi( 1 ) ]->physics;
		p.current.origin = Wv( 2 );
		p.current.axis = Wa( 5 );
		if ( p.clipModel ) { p.clipModel->Unlink(); p.LinkClip(); }
		return;
	}
	if ( cmd == "owner" ) { clipModels[ Wi( 1 ) ]->SetOwner( Wi( 2 ) < 0 ? NULL : gameLocal.entities[ Wi( 2 ) ] ); return; }
	if ( cmd == "link" ) {
		idClipModel *m = clipModels[ Wi( 1 ) ];
		m->Link( gameLocal.clip, m->GetEntity(), m->GetId(), Wv( 2 ), Wa( 5 ) );
		fprintf( g_golden, "LINK %d linked=%d", Wi( 1 ), m->IsLinked() ? 1 : 0 );
		V( m->GetAbsBounds()[0] ); V( m->GetAbsBounds()[1] );
		fprintf( g_golden, " axis" ); M( m->GetAxis() );
		fprintf( g_golden, "\n" );
		return;
	}
	if ( cmd == "unlink" ) { clipModels[ Wi( 1 ) ]->Unlink(); return; }
	if ( cmd == "enable" ) { clipModels[ Wi( 1 ) ]->Enable(); return; }
	if ( cmd == "disable" ) { clipModels[ Wi( 1 ) ]->Disable(); return; }
	if ( cmd == "contents" ) { clipModels[ Wi( 1 ) ]->SetContents( Wi( 2 ) ); return; }
	if ( cmd == "trans" || cmd == "transents" ) {
		trace_t t; memset( &t, 0, sizeof( t ) );
		int ret = 0;
		if ( cmd == "trans" ) ret = gameLocal.clip.Translation( t, Wv( 2 ), Wv( 5 ), Mdl( 1 ), Wa( 8 ), Wi( 11 ), Pass( 12 ) );
		else gameLocal.clip.TranslationEntities( t, Wv( 2 ), Wv( 5 ), Mdl( 1 ), Wa( 8 ), Wi( 11 ), Pass( 12 ) );
		PrintTrace( ret, t );
		return;
	}
	if ( cmd == "rot" ) {
		trace_t t; memset( &t, 0, sizeof( t ) );
		idRotation r( Wv( 2 ), Wv( 5 ), Wf( 8 ) );
		int ret = gameLocal.clip.Rotation( t, Wv( 2 ), r, Mdl( 1 ), Wa( 9 ), Wi( 12 ), Pass( 13 ) );
		PrintTrace( ret, t );
		return;
	}
	if ( cmd == "motion" ) {
		trace_t t; memset( &t, 0, sizeof( t ) );
		idRotation r( Wv( 2 ), Wv( 8 ), Wf( 11 ) );
		int ret = gameLocal.clip.Motion( t, Wv( 2 ), Wv( 5 ), r, Mdl( 1 ), Wa( 12 ), Wi( 15 ), Pass( 16 ) );
		PrintTrace( ret, t );
		return;
	}
	if ( cmd == "contentsat" ) {
		int c = gameLocal.clip.Contents( Wv( 2 ), Mdl( 1 ), Wa( 5 ), Wi( 8 ), Pass( 9 ) );
		fprintf( g_golden, "CONTENTS %d\n", c );
		return;
	}
	if ( cmd == "tracepoint" ) {
		trace_t t; memset( &t, 0, sizeof( t ) );
		int ret = gameLocal.clip.TracePoint( t, Wv( 1 ), Wv( 4 ), Wi( 7 ), Pass( 8 ) );
		PrintTrace( ret, t );
		return;
	}
	if ( cmd == "tracebounds" ) {
		trace_t t; memset( &t, 0, sizeof( t ) );
		int ret = gameLocal.clip.TraceBounds( t, Wv( 1 ), Wv( 4 ), idBounds( Wv( 7 ), Wv( 10 ) ), Wi( 13 ), Pass( 14 ) );
		PrintTrace( ret, t );
		return;
	}
	if ( cmd == "touching" ) {
		idClipModel *list[ MAX_GENTITIES ];
		int n = gameLocal.clip.ClipModelsTouchingBounds( idBounds( Wv( 1 ), Wv( 4 ) ), Wi( 7 ), list, MAX_GENTITIES );
		fprintf( g_golden, "TOUCHING %d", n );
		for ( int i = 0; i < n; i++ ) fprintf( g_golden, " %d:%d", list[i]->GetEntity()->entityNumber, list[i]->GetId() );
		fprintf( g_golden, "\n" );
		return;
	}
	if ( cmd == "entities" ) {
		idEntity *list[ MAX_GENTITIES ];
		int n = gameLocal.clip.EntitiesTouchingBounds( idBounds( Wv( 1 ), Wv( 4 ) ), Wi( 7 ), list, MAX_GENTITIES );
		fprintf( g_golden, "ENTITIES %d", n );
		for ( int i = 0; i < n; i++ ) fprintf( g_golden, " %d", list[i]->entityNumber );
		fprintf( g_golden, "\n" );
		return;
	}
	if ( cmd == "touchtriggers" ) {
		bool r = gameLocal.entities[ Wi( 1 ) ]->TouchTriggers();
		fprintf( g_golden, "TOUCHTRIGGERS %d ret=%d\n", Wi( 1 ), r ? 1 : 0 );
		return;
	}
	fprintf( g_golden, "UNKNOWN %s\n", cmd.c_str() );
}

int main( int argc, char **argv ) {
	if ( argc < 3 ) { fprintf( stderr, "usage: harness_clip <scenario> <golden>\n" ); return 1; }
	static idSIMD_Generic generic;
	SIMDProcessor = &generic;
	Swap_Init();
	idMath::Init();
	idStr::InitMemory();
	idDict::Init();
	idLib::sys = sys;
	idLib::common = common;
	idLib::fileSystem = fileSystem;

	char scnPath[1024], goldenPath[1024], mapDir[1024];
	_fullpath( scnPath, argv[1], sizeof( scnPath ) );
	_fullpath( goldenPath, argv[2], sizeof( goldenPath ) );
	strcpy( mapDir, scnPath );
	char *slash = strrchr( mapDir, '\\' );
	if ( !slash ) return 1;
	*slash = 0;
	// the world: room.map beside the scratch folder's harness (copied there by the build script)
	char *harnessDir = getenv( "HARNESS_MAPDIR" );
	if ( !harnessDir || chdir( harnessDir ) != 0 ) { fprintf( stderr, "HARNESS_MAPDIR is not set\n" ); return 1; }
	idMapFile map;
	if ( !map.Parse( "room.map", false, true ) ) { fprintf( stderr, "cannot read room.map\n" ); return 1; }
	cm.LoadMap( &map );

	for ( int i = 0; i < MAX_GENTITIES; i++ ) gameLocal.entities[i] = NULL;
	g_golden = fopen( goldenPath, "wb" );
	if ( !g_golden ) return 1;
	FILE *scn = fopen( scnPath, "rb" );
	if ( !scn ) return 1;
	char line[2048];
	while ( fgets( line, sizeof( line ), scn ) ) {
		int n = (int) strlen( line );
		while ( n > 0 && ( line[n - 1] == 10 || line[n - 1] == 13 ) ) line[--n] = 0;
		if ( n == 0 || line[0] == 35 ) continue;
		fprintf( g_golden, "CMD %s\n", line );
		ntok = 0;
		for ( char *t = strtok( line, " " ); t && ntok < 64; t = strtok( NULL, " " ) ) { strcpy( tok[ ntok++ ], t ); }
		Run( idStr( tok[0] ) );
	}
	fclose( scn );
	fclose( g_golden );
	return 0;
}
