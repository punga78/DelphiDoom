// Issue #255 (Doom 3, phase 3 "the game without a renderer"): driver of the third parity harness. Written for this
// repository. It is linked with the REAL idlib and with
//   the REAL game\gamesys\Class.h and Event.h,
//   the REAL bodies of game\gamesys\Class.cpp (idTypeInfo, idClass: registration, Init/Shutdown, GetClass, GetType,
//     CreateInstance, CallSpawn, ListClasses_f, GetClassname, GetSuperclass, Event_Remove, Event_SafeRemove),
//   the REAL bodies of game\gamesys\Event.cpp (idEventDef constructor, NumEventCommands, GetEventCommand, FindEvent),
//   the REAL bodies of game\Game_local.cpp (RegisterEntity, UnregisterEntity, SpawnEntityType, SpawnEntityDef,
//     FindEntityDef, FindEntityDefDict, InhibitEntitySpawn, SpawnMapEntities, AddEntityToHash, RemoveEntityFromHash,
//     FindEntity, FindEntityUsingDef, MapPopulate) and the think loop of RunFrame (the lines between "let entities think"
//     and "numEntitiesToDeactivate = 0"),
//   the REAL bodies of game\Entity.cpp (GetEntityDefName, SetName, GetName, IsActive, BecomeActive, BecomeInactive; the
//     physics-team blocks of the last two are cut out: this harness has no physics),
// cut out of the source by Build-Harness-Game.ps1, against fakes of the engine that trace every call. The entity
// classes of the harness (idEntity, idMover, idDoor, ...) are written here: idEntity::Spawn and the destructor are
// REDUCED versions (they keep the lines of the original that this phase ports, in the same order).
//
// Usage: harness_game.exe <scenario.scn> <golden.txt>
//
// SCENARIO: one command per line; empty lines and '#' lines are skipped; every command is echoed as "CMD <line>". A word
// may contain the escapes \n \t \r \" \\ and \xHH (\x20 is a space). An idException ends the command and prints
// "THROW <text>".
//
//   types:    dumptypes | gettype <n> | getclass <name> | super <name> | istype <a> <b> | numtypes | typenumbits | list
//             inittypes | shutdowntypes | responds <class> <event> | evshare <class>
//   objects:  create <class> | spawnobj <class> | callevent <obj> <event> | destroy <obj> | objs
//   events:   events | event <name>
//   game:     cvar <skill|multiplayer> <n> | def <name> [<key> <value>]... | newmap | spawndef [<key> <value>]...
//             spawntype <class> [<key> <value>]... | remove <entnum> | find <name> | finddef <entnum|-1> <defname>
//             setname <entnum> <name> | active <entnum> <flags> | inactive <entnum> <flags> | think <entnum>
//             mapclear | mapent [<key> <value>]... | spawnmap | populate | frame <msec> | state | inhibit [<key> <value>]...
#include "../gameinc/precompiled.h"
#pragma hdrstop

static FILE *g_golden;
static std::string esc( const std::string &s ) {
	std::string r;
	for ( size_t i = 0; i < s.size(); i++ ) {
		unsigned char c = (unsigned char)s[i];
		if ( c == '\\' ) r += "\\\\";
		else if ( c == '\n' ) r += "\\n";
		else if ( c == '\r' ) r += "\\r";
		else if ( c == '\t' ) r += "\\t";
		else if ( c == '"' ) r += "\\\"";
		else if ( c < 32 || c > 126 ) { char t[8]; sprintf( t, "\\x%02X", c ); r += t; }
		else r += (char)c;
	}
	return r;
}
static std::string unesc( const std::string &s ) {
	std::string r;
	for ( size_t i = 0; i < s.size(); i++ ) {
		if ( s[i] != '\\' || i + 1 >= s.size() ) { r += s[i]; continue; }
		char c = s[++i];
		if ( c == 'n' ) r += '\n';
		else if ( c == 't' ) r += '\t';
		else if ( c == 'r' ) r += '\r';
		else if ( c == '"' ) r += '"';
		else if ( c == '\\' ) r += '\\';
		else if ( c == 'x' && i + 2 < s.size() + 0 ) { r += (char)strtol( s.substr( i + 1, 2 ).c_str(), 0, 16 ); i += 2; }
		else { r += '\\'; r += c; }
	}
	return r;
}
static bool g_quiet = false;
static void out( const char *fmt, ... ) {
	if ( g_quiet ) return;
	char buf[16384]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( buf, sizeof( buf ), fmt, ap ); va_end( ap );
	fputs( buf, g_golden ); fputc( '\n', g_golden ); fflush( g_golden );
}
static void outs( const char *tag, const std::string &text ) { if ( g_quiet ) return; fprintf( g_golden, "%s %s\n", tag, esc( text ).c_str() ); fflush( g_golden ); }

// ---------------------------------------------------------------- what idlib needs
int idLib::frameNumber = 0;
idSys *idLib::sys = 0; idCommon *idLib::common = 0; idFileSystem *idLib::fileSystem = 0; idCVarSystem *idLib::cvarSystem = 0;
idCommon *common = 0; idSys *sys = 0; idCVarSystem *cvarSystem = 0;
void idLib::Init() {} void idLib::ShutDown() {}
void idLib::Error( const char *fmt, ... ) { char b[4096]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( b, sizeof( b ), fmt, ap ); va_end( ap ); throw idException( b ); }
void idLib::Warning( const char *fmt, ... ) {}
const char *idLangDict::GetString( const char *id ) const { return id; }
int idFile::Write( const void *buffer, int len ) { return 0; }
int idFile::Read( void *buffer, int len ) { return 0; }
void idFile::Flush() {} void idFile::ForceFlush() {}
int idFile::Printf( const char *fmt, ... ) { return 0; }
idCVar::idCVar( const char *name, const char *value, int flags, const char *description, float valueMin, float valueMax, argCompletion_t valueCompletion ) { n = name; v = value; }
bool idCVarSystem::IsInitialized() const { return true; }
int idCVarSystem::GetCVarInteger( const char *name ) const { return 0; }
bool idCVarSystem::GetCVarBool( const char *name ) const { return false; }
const char *idCVarSystem::GetCVarString( const char *name ) const { return ""; }
void idCVarSystem::SetCVarString( const char *name, const char *value, int flags ) { out( "CALL cvar.SetString %s %s", name, value ); }
void idCVarSystem::SetCVarBool( const char *name, const bool value, int flags ) { out( "CALL cvar.SetBool %s %d", name, value ? 1 : 0 ); }

// ---------------------------------------------------------------- the constants of Game_local.h and Entity.h
#define MAX_CLIENTS				32
#define GENTITYNUM_BITS			12
#define MAX_GENTITIES			(1<<GENTITYNUM_BITS)
#define ENTITYNUM_NONE			(MAX_GENTITIES-1)
#define ENTITYNUM_WORLD			(MAX_GENTITIES-2)
#define ENTITYNUM_MAX_NORMAL	(MAX_GENTITIES-2)
enum { TH_ALL = -1, TH_THINK = 1, TH_PHYSICS = 2, TH_ANIMATE = 4, TH_UPDATEVISUALS = 8, TH_UPDATEPARTICLES = 16 };
#define DECL_ENTITYDEF 1

// the declarations (the fake of declManager): entityDefs by name
class idDecl { public: idStr name; int index; const char *GetName() const { return name.c_str(); } int Index() const { return index; } };
class idDeclEntityDef : public idDecl { public: idDict dict; };
class idDeclManagerGame {
public:
	std::vector<idDeclEntityDef *> defs;
	const idDecl *FindType( int type, const char *name, bool makeDefault ) {
		if ( !name ) return NULL;
		for ( size_t i = 0; i < defs.size(); i++ ) if ( defs[i]->name.Icmp( name ) == 0 ) return defs[i];
		return NULL;
	}
	const idDecl *DeclByIndex( int type, int index, bool forceParse ) { return defs[index]; }
};
static idDeclManagerGame g_declManager;
static idDeclManagerGame *declManager = &g_declManager;

// the script program, the thread, the map file and the edit entities (fakes)
struct function_t { std::string name; };
class idEditEntities { public: void RemoveSelectedEntity( idEntity *ent ); };
class idProgramFake {
public:
	std::vector<function_t *> functions;
	const function_t *FindFunction( const char *name ) { for ( size_t i = 0; i < functions.size(); i++ ) if ( functions[i]->name == name ) return functions[i]; return NULL; }
	void SetEntity( const char *name, idEntity *ent );
};
class idThread {
public:
	idThread( const function_t *func ) { out( "CALL idThread %s", func->name.c_str() ); }
	void DelayedStart( int delay ) { out( "CALL idThread.DelayedStart %d", delay ); }
};
struct idMapEntityFake { idDict epairs; };
class idMapFileFake {
public:
	std::vector<idMapEntityFake *> ents;
	int GetNumEntities() const { return (int)ents.size(); }
	idMapEntityFake *GetEntity( int i ) const { return ents[i]; }
};
// cvars of the game
static idCVar g_skill( "g_skill", "1", 0, "" ), g_timeentities( "g_timeentities", "0", 0, "" ), g_cinematic( "g_cinematic", "1", 0, "" );

// ---------------------------------------------------------------- the entity class of the harness and gameLocal
class idGameLocal;
class idPhysicsFake { public: void UpdateTime( int t ); };
class idEntity : public idClass {
public:
	ABSTRACT_PROTOTYPE( idEntity );

	int						entityNumber;
	int						entityDefNumber;
	int						thinkFlags;
	bool					cinematic;
	int						health;
	idStr					name;
	idDict					spawnArgs;
	idLinkList<idEntity>	spawnNode;
	idLinkList<idEntity>	activeNode;

							idEntity();
	virtual					~idEntity();
	void					Spawn( void );
	virtual void			Think( void );
	const char *			GetEntityDefName( void ) const;
	void					SetName( const char *name );
	const char *			GetName( void ) const;
	bool					IsActive( void ) const;
	void					BecomeActive( int flags );
	void					BecomeInactive( int flags );
	idPhysicsFake *			GetPhysics( void ) const;
	void					Event_Hide( void );
};

class idGameLocal {
public:
	const static int		INITIAL_SPAWN_COUNT = 1;

	idEntity *				entities[MAX_GENTITIES];
	int						spawnIds[MAX_GENTITIES];
	int						num_entities;
	idHashIndex				entityHash;
	idDict					spawnArgs;
	idLinkList<idEntity>	spawnedEntities;
	idLinkList<idEntity>	activeEntities;
	int						numEntitiesToDeactivate;
	bool					sortPushers;
	bool					sortTeamMasters;
	int						firstFreeIndex;
	int						spawnCount;
	int						mapSpawnCount;
	bool					isMultiplayer;
	bool					isClient;
	bool					inCinematic;
	idEditEntities *		editEntities;
	idMapFileFake *			mapFile;
	idProgramFake			program;
	int						time, previousTime, msec, framenum;

	void					Printf( const char *fmt, ... ) const;
	void					Warning( const char *fmt, ... ) const;
	void					Error( const char *fmt, ... ) const;
	void					RegisterEntity( idEntity *ent );
	void					UnregisterEntity( idEntity *ent );
	idEntity *				SpawnEntityType( const idTypeInfo &classdef, const idDict *args = NULL, bool bIsClientReadSnapshot = false );
	bool					SpawnEntityDef( const idDict &args, idEntity **ent = NULL, bool setDefaults = true );
	const idDeclEntityDef *	FindEntityDef( const char *name, bool makeDefault = true ) const;
	const idDict *			FindEntityDefDict( const char *name, bool makeDefault = true ) const;
	bool					InhibitEntitySpawn( idDict &spawnArgs );
	void					SpawnMapEntities( void );
	void					AddEntityToHash( const char *name, idEntity *ent );
	bool					RemoveEntityFromHash( const char *name, idEntity *ent );
	idEntity *				FindEntity( const char *name ) const;
	idEntity *				FindEntityUsingDef( idEntity *from, const char *match ) const;
	void					MapPopulate( void );
	void					SetSkill( int value );
	void					CacheDictionaryMedia( const idDict *dict );
	void					SpreadLocations( void );
	void					RandomizeInitialSpawns( void );
	void					RunFrameThink( void );
	void					NewMap( void );
};
static idGameLocal gameLocal;

void idGameLocal::Printf( const char *fmt, ... ) const { char b[16384]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( b, sizeof( b ), fmt, ap ); va_end( ap ); outs( "PRINT", b ); }
void idGameLocal::Warning( const char *fmt, ... ) const { char b[16384]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( b, sizeof( b ), fmt, ap ); va_end( ap ); outs( "WARNING", b ); }
// bcc32c crashes when an exception unwinds through a function with a try block that does not catch it (SpawnEntityType
// catches idAllocError only): Error leaves by longjmp to the command loop, as the host harness does for Sys_Quit
#include <setjmp.h>
static jmp_buf g_errJmp; static std::string g_errText; static int g_fillCount = -1;
void idGameLocal::Error( const char *fmt, ... ) const {
	char b[16384]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( b, sizeof( b ), fmt, ap ); va_end( ap );
	g_quiet = false; outs( "ERROR", b ); g_errText = b; longjmp( g_errJmp, 1 );
}
void idGameLocal::SetSkill( int value ) { out( "CALL SetSkill %d", value ); }
void idGameLocal::CacheDictionaryMedia( const idDict *dict ) { outs( "CALL CacheDictionaryMedia", dict->GetString( "classname" ) ); }
void idGameLocal::SpreadLocations( void ) { out( "CALL SpreadLocations" ); }
void idGameLocal::RandomizeInitialSpawns( void ) { out( "CALL RandomizeInitialSpawns" ); }
void idEditEntities::RemoveSelectedEntity( idEntity *ent ) { out( "CALL editEntities.RemoveSelectedEntity" ); }
void idProgramFake::SetEntity( const char *name, idEntity *ent ) { out( "CALL program.SetEntity %s %d", name, ent ? ent->entityNumber : -1 ); }
void idPhysicsFake::UpdateTime( int t ) { out( "CALL physics.UpdateTime %d", t ); }
idPhysicsFake *idEntity::GetPhysics( void ) const { static idPhysicsFake p; return &p; }
void idEvent::CancelEvents( const idClass *obj, const idEventDef *evdef ) { out( "CALL idEvent.CancelEvents" ); }
void idEvent::ServiceEvents( void ) { out( "CALL idEvent.ServiceEvents" ); }
bool idEvent::initialized = false;
idDynamicBlockAlloc<byte, 16 * 1024, 256> idEvent::eventDataAllocator;
bool idClass::PostEventMS( const idEventDef *ev, int time ) { outs( "CALL PostEventMS", ev->GetName() ); return true; }
void *idClass::operator new( size_t s ) { return calloc( 1, s ); }
void *idClass::operator new( size_t s, int, int, char *, int ) { return calloc( 1, s ); }
void idClass::operator delete( void *p ) { free( p ); }
void idClass::operator delete( void *p, int, int, char *, int ) { free( p ); }

// the entity classes of the harness (declarations: the REAL bodies below need idWorldspawn and the others)
class idItem : public idEntity {
public:
	CLASS_PROTOTYPE( idItem );
							idItem() { out( "CTOR idItem" ); }
	void					Spawn( void );
	void					Event_Show( void );
};
class idMover : public idEntity {
public:
	CLASS_PROTOTYPE( idMover );
	int						thinkCount;
							idMover() { thinkCount = 0; out( "CTOR idMover" ); }
	void					Spawn( void );
	virtual void			Think( void );
	void					Event_Open( void );
};
class idDoor : public idMover {
public:
	CLASS_PROTOTYPE( idDoor );
							idDoor() { out( "CTOR idDoor" ); }
	void					Spawn( void );
	void					Event_Activate( void );
	void					Event_Hide( void );
};
class idPlat : public idMover {			// no Spawn, no events of its own
public:
	CLASS_PROTOTYPE( idPlat );
							idPlat() { out( "CTOR idPlat" ); }
};
class idLight : public idEntity {		// no Spawn, no events of its own
public:
	CLASS_PROTOTYPE( idLight );
							idLight() { out( "CTOR idLight" ); }
};
class idPlayerStart : public idEntity {
public:
	CLASS_PROTOTYPE( idPlayerStart );
							idPlayerStart() { out( "CTOR idPlayerStart" ); }
	void					Spawn( void );
};
class idWorldspawn : public idEntity {
public:
	CLASS_PROTOTYPE( idWorldspawn );
							idWorldspawn() { out( "CTOR idWorldspawn" ); }
	void					Spawn( void );
};
class idTrigger_Multi : public idEntity {
public:
	CLASS_PROTOTYPE( idTrigger_Multi );
							idTrigger_Multi() { out( "CTOR idTrigger_Multi" ); }
	void					Spawn( void );
	void					Event_Ping( void );
};
class idDebugHelper : public idClass {	// not an entity
public:
	CLASS_PROTOTYPE( idDebugHelper );
							idDebugHelper() { out( "CTOR idDebugHelper" ); }
	void					Spawn( void );
};
class idBinder : public idEntity {		// abstract
public:
	ABSTRACT_PROTOTYPE( idBinder );
	void					Spawn( void );
};

// the real bodies, cut out of the source by Build-Harness-Game.ps1
#include "../gamefw/event_extract.inc"
#include "../gamefw/class_extract.inc"

// ---------------------------------------------------------------- the events and the classes of the harness
const idEventDef EV_Activate( "activate", "e" );
const idEventDef EV_Hide( "hide" );
const idEventDef EV_Show( "show" );
const idEventDef EV_Open( "open" );
const idEventDef EV_ActivateAgain( "activate", "e" );		// the same name and format: the same event number
const idEventDef EV_Ping( "ping", "d" );

// the order of the declarations is the order of the static initialization: a class before its superclass on purpose
CLASS_DECLARATION( idMover, idDoor )
	EVENT( EV_Activate,				idDoor::Event_Activate )
	EVENT( EV_Hide,					idDoor::Event_Hide )
END_CLASS
CLASS_DECLARATION( idEntity, idMover )
	EVENT( EV_Open,					idMover::Event_Open )
END_CLASS
ABSTRACT_DECLARATION( idClass, idEntity )
	EVENT( EV_Hide,					idEntity::Event_Hide )
END_CLASS
CLASS_DECLARATION( idEntity, idItem )
	EVENT( EV_Show,					idItem::Event_Show )
END_CLASS
CLASS_DECLARATION( idEntity, idPlayerStart )
END_CLASS
CLASS_DECLARATION( idEntity, idLight )
END_CLASS
CLASS_DECLARATION( idEntity, idWorldspawn )
END_CLASS
CLASS_DECLARATION( idEntity, idTrigger_Multi )
	EVENT( EV_Ping,					idTrigger_Multi::Event_Ping )
END_CLASS
CLASS_DECLARATION( idClass, idDebugHelper )
END_CLASS
CLASS_DECLARATION( idMover, idPlat )
END_CLASS
ABSTRACT_DECLARATION( idEntity, idBinder )
END_CLASS

// the entity: the lines of idEntity::idEntity, ::Spawn and ::~idEntity that this phase ports, in the order of the original
idEntity::idEntity() {
	entityNumber	= ENTITYNUM_NONE;
	entityDefNumber = -1;
	spawnNode.SetOwner( this );
	activeNode.SetOwner( this );
	thinkFlags		= 0;
	cinematic		= false;
	health			= 0;
}
idEntity::~idEntity( void ) {
	if ( thinkFlags ) {
		BecomeInactive( thinkFlags );
	}
	activeNode.Remove();
	gameLocal.RemoveEntityFromHash( name.c_str(), this );
	gameLocal.UnregisterEntity( this );
}
void idEntity::Spawn( void ) {
	const char			*temp;
	const char			*classname;

	gameLocal.RegisterEntity( this );

	spawnArgs.GetString( "classname", NULL, &classname );
	const idDeclEntityDef *def = gameLocal.FindEntityDef( classname, false );
	if ( def ) {
		entityDefNumber = def->Index();
	}

	cinematic = spawnArgs.GetBool( "cinematic", "0" );

	// every object will have a unique name
	temp = spawnArgs.GetString( "name", va( "%s_%s_%d", GetClassname(), spawnArgs.GetString( "classname" ), entityNumber ) );
	SetName( temp );

	health = spawnArgs.GetInt( "health" );
}
void idEntity::Think( void ) { out( "THINK %s", name.c_str() ); }
void idEntity::Event_Hide( void ) { out( "EVENT idEntity.Hide %s", name.c_str() ); }
void idItem::Spawn( void ) { out( "SPAWN idItem %s", name.c_str() ); }
void idItem::Event_Show( void ) { out( "EVENT idItem.Show %s", name.c_str() ); }
void idMover::Spawn( void ) { out( "SPAWN idMover %s", name.c_str() ); BecomeActive( TH_THINK ); }
void idMover::Think( void ) {
	out( "THINK idMover %s %d", name.c_str(), ++thinkCount );
	if ( thinkCount >= spawnArgs.GetInt( "thinks", "2" ) ) {
		BecomeInactive( TH_THINK );
	}
}
void idMover::Event_Open( void ) { out( "EVENT idMover.Open %s", name.c_str() ); }
void idDoor::Spawn( void ) { out( "SPAWN idDoor %s", name.c_str() ); }
void idDoor::Event_Activate( void ) { out( "EVENT idDoor.Activate %s", name.c_str() ); }
void idDoor::Event_Hide( void ) { out( "EVENT idDoor.Hide %s", name.c_str() ); }
void idPlayerStart::Spawn( void ) { out( "SPAWN idPlayerStart %s", name.c_str() ); }
void idWorldspawn::Spawn( void ) { out( "SPAWN idWorldspawn %s", name.c_str() ); }
void idTrigger_Multi::Spawn( void ) { out( "SPAWN idTrigger_Multi %s", name.c_str() ); BecomeActive( TH_THINK ); }
void idTrigger_Multi::Event_Ping( void ) { out( "EVENT idTrigger_Multi.Ping %s", name.c_str() ); }
void idDebugHelper::Spawn( void ) { out( "SPAWN idDebugHelper" ); }
void idBinder::Spawn( void ) { out( "SPAWN idBinder" ); }

// the real bodies of Entity.cpp and Game_local.cpp
#include "../gamefw/game_extract.inc"

void idGameLocal::NewMap( void ) {
	// the entity lines of idGameLocal::InitFromNewMap (Game_local.cpp), before the render world, sound and clip are set up
	memset( entities, 0, sizeof( entities ) );
	memset( spawnIds, -1, sizeof( spawnIds ) );
	spawnCount = INITIAL_SPAWN_COUNT;

	spawnedEntities.Clear();
	activeEntities.Clear();
	numEntitiesToDeactivate = 0;
	sortTeamMasters = false;
	sortPushers = false;

	// always leave room for the max number of clients,
	// even if they aren't all used, so numbers inside that
	// range are NEVER anything but clients
	num_entities	= MAX_CLIENTS;
	firstFreeIndex	= MAX_CLIENTS;

	previousTime	= 0;
	time			= 0;
	framenum		= 0;

	spawnArgs.Clear();
	inCinematic = false;
	entityHash.Clear( 1024, MAX_GENTITIES );
}

void idGameLocal::RunFrameThink( void ) {
	idEntity *	ent;
	int			num;
	float		ms;
	idTimer		timer_singlethink;

	framenum++;
	previousTime = time;
	time += msec;

#include "../gamefw/think_extract.inc"
}

// ---------------------------------------------------------------- the driver
static std::vector<idClass *> g_objs;
static std::vector<std::string> g_words;

static idEntity *entityAt( const std::string &s ) {
	int n = atoi( s.c_str() );
	return ( n >= 0 && n < MAX_GENTITIES ) ? gameLocal.entities[n] : NULL;
}
static void fillDict( idDict &d, size_t from ) {
	for ( size_t i = from; i + 1 < g_words.size(); i += 2 ) d.Set( g_words[i].c_str(), g_words[i + 1].c_str() );
}
static void showObject( const char *tag, idClass *obj ) {
	if ( !obj ) { out( "%s null", tag ); return; }
	int index = -1;
	for ( size_t i = 0; i < g_objs.size(); i++ ) if ( g_objs[i] == obj ) index = (int)i;
	if ( index < 0 ) { index = (int)g_objs.size(); g_objs.push_back( obj ); }
	out( "%s obj=%d class=%s", tag, index, obj->GetClassname() );
}
static void dumpState() {
	out( "STATE num_entities=%d firstFree=%d spawnCount=%d mapSpawnCount=%d toDeactivate=%d time=%d frame=%d inCinematic=%d", gameLocal.num_entities, gameLocal.firstFreeIndex,
		gameLocal.spawnCount, gameLocal.mapSpawnCount, gameLocal.numEntitiesToDeactivate, gameLocal.time, gameLocal.framenum, gameLocal.inCinematic ? 1 : 0 );
	for ( int i = 0; i < MAX_GENTITIES; i++ ) {
		idEntity *e = gameLocal.entities[i];
		if ( !e ) continue;
		out( "ENT %d name=%s class=%s def=%s spawnId=%d think=%d active=%d cinematic=%d health=%d number=%d", i, e->name.c_str(), e->GetClassname(), e->GetEntityDefName(), gameLocal.spawnIds[i], e->thinkFlags,
			e->IsActive() ? 1 : 0, e->cinematic ? 1 : 0, e->health, e->entityNumber );
	}
	std::string s;
	for ( idEntity *e = gameLocal.spawnedEntities.Next(); e != NULL; e = e->spawnNode.Next() ) { char t[16]; sprintf( t, " %d", e->entityNumber ); s += t; }
	outs( "SPAWNLIST", s );
	s.clear();
	for ( idEntity *e = gameLocal.activeEntities.Next(); e != NULL; e = e->activeNode.Next() ) { char t[16]; sprintf( t, " %d", e->entityNumber ); s += t; }
	outs( "ACTIVELIST", s );
}

static void runCommand( const std::string &cmd, const std::string &rest ) {
	g_words.clear();
	{
		size_t p = 0;
		while ( p < rest.size() ) {
			size_t q = rest.find( ' ', p );
			if ( q == std::string::npos ) q = rest.size();
			if ( q > p ) g_words.push_back( unesc( rest.substr( p, q - p ) ) );
			p = q + 1;
		}
	}
	std::vector<std::string> &w = g_words;
	// ---- the type system
	if ( cmd == "inittypes" ) idClass::Init();
	else if ( cmd == "shutdowntypes" ) idClass::Shutdown();
	else if ( cmd == "numtypes" ) out( "RET %d", idClass::GetNumTypes() );
	else if ( cmd == "typenumbits" ) out( "RET %d", idClass::GetTypeNumBits() );
	else if ( cmd == "list" ) idClass::ListClasses_f( idCmdArgs() );
		else if ( cmd == "getclass" ) {
		idTypeInfo *t = idClass::GetClass( w[0].c_str() );
		if ( t ) out( "CLASS %s super=%s typeNum=%d lastChild=%d", t->classname, t->superclass, t->typeNum, t->lastChild ); else out( "CLASS null" );
	}
	else if ( cmd == "gettype" ) {
		idTypeInfo *t = idClass::GetType( atoi( w[0].c_str() ) );
		if ( t ) out( "TYPE %s", t->classname ); else out( "TYPE null" );
	}
	else if ( cmd == "super" ) {
		idTypeInfo *t = idClass::GetClass( w[0].c_str() );
		if ( t ) outs( "SUPER", t->super ? t->super->classname : "(none)" ); else out( "CLASS null" );
	}
	else if ( cmd == "istype" ) {
		idTypeInfo *a = idClass::GetClass( w[0].c_str() ), *b = idClass::GetClass( w[1].c_str() );
		if ( a && b ) out( "RET %d", a->IsType( *b ) ? 1 : 0 ); else out( "CLASS null" );
	}
	else if ( cmd == "responds" ) {
		idTypeInfo *a = idClass::GetClass( w[0].c_str() ); const idEventDef *ev = idEventDef::FindEvent( w[1].c_str() );
		if ( a && ev ) out( "RET %d", a->RespondsTo( *ev ) ? 1 : 0 ); else out( "NOTFOUND" );
	}
	else if ( cmd == "evshare" ) {
		idTypeInfo *a = idClass::GetClass( w[0].c_str() );
		if ( a ) out( "EVSHARE %s shared=%d free=%d hasMap=%d", a->classname, ( a->super && a->eventMap == a->super->eventMap ) ? 1 : 0, a->freeEventMap ? 1 : 0, a->eventMap ? 1 : 0 );
	}
	else if ( cmd == "dumptypes" ) {
		for ( idTypeInfo *c = typelist; c != NULL; c = c->next )
			out( "TYPE %s super=%s superPtr=%s typeNum=%d lastChild=%d free=%d map=%d", c->classname, c->superclass, c->super ? c->super->classname : "(none)", c->typeNum, c->lastChild, c->freeEventMap ? 1 : 0, c->eventMap ? 1 : 0 );
		out( "INIT initialized=%d types=%d typenums=%d bits=%d", idClass::initialized ? 1 : 0, idClass::types.Num(), idClass::typenums.Num(), idClass::typeNumBits );
	}
	// ---- the events
	else if ( cmd == "events" ) {
		out( "EVENTS %d", idEventDef::NumEventCommands() );
		for ( int i = 0; i < idEventDef::NumEventCommands(); i++ ) { const idEventDef *e = idEventDef::GetEventCommand( i ); out( "EVENT %d %s format=%s args=%d", e->GetEventNum(), e->GetName(), e->GetArgFormat(), e->GetNumArgs() ); }
	}
	else if ( cmd == "event" ) { const idEventDef *e = idEventDef::FindEvent( w[0].c_str() ); if ( e ) out( "EVENT %d %s", e->GetEventNum(), e->GetName() ); else out( "EVENT null" ); }
	else if ( cmd == "evinit" ) idEvent::initialized = true;
	// ---- objects
	else if ( cmd == "create" ) showObject( "OBJ", idClass::CreateInstance( w[0].c_str() ) );
	else if ( cmd == "spawnobj" ) {
		idClass *o = idClass::CreateInstance( w[0].c_str() );
		if ( o ) o->CallSpawn();
		showObject( "OBJ", o );
	}
	else if ( cmd == "callevent" ) {
		idClass *o = ( w[0] == "ent" ) ? (idClass *)entityAt( w[1] ) : ( (size_t)atoi( w[1].c_str() ) < g_objs.size() ? g_objs[atoi( w[1].c_str() )] : NULL );
		const idEventDef *ev = idEventDef::FindEvent( w[2].c_str() );
		if ( !o || !ev ) { out( "NOTFOUND" ); return; }
		out( "RESPONDS %d", o->RespondsTo( *ev ) ? 1 : 0 );
		if ( o->RespondsTo( *ev ) ) {
			eventCallback_t fn = o->GetType()->eventMap[ev->GetEventNum()]; ( o->*fn )();
			// the immediate remove deletes the object: the list must not give its address again
			if ( w[0] == "obj" && ev == &EV_Remove ) g_objs[atoi( w[1].c_str() )] = NULL;
		}
	}
	else if ( cmd == "destroy" ) {
		size_t n = atoi( w[0].c_str() );
		if ( n < g_objs.size() && g_objs[n] ) { delete g_objs[n]; g_objs[n] = NULL; out( "DESTROYED %d", (int)n ); } else out( "NOTFOUND" );
	}
	// ---- the game
	else if ( cmd == "cvar" ) { if ( w[0] == "skill" ) g_skill.SetInteger( atoi( w[1].c_str() ) ); else gameLocal.isMultiplayer = atoi( w[1].c_str() ) != 0; }
	else if ( cmd == "def" ) {
		idDeclEntityDef *d = new idDeclEntityDef; d->name = w[0].c_str(); d->index = (int)g_declManager.defs.size(); fillDict( d->dict, 1 ); g_declManager.defs.push_back( d );
	}
	else if ( cmd == "func" ) { function_t *f = new function_t; f->name = w[0]; gameLocal.program.functions.push_back( f ); }
	else if ( cmd == "newmap" ) gameLocal.NewMap();
	else if ( cmd == "spawndef" ) {
		idDict args; fillDict( args, 0 ); idEntity *ent = NULL;
		bool r = gameLocal.SpawnEntityDef( args, &ent );
		out( "RET %d ent=%d", r ? 1 : 0, ent ? ent->entityNumber : -1 );
	}
	else if ( cmd == "spawntype" ) {
		idTypeInfo *t = idClass::GetClass( w[0].c_str() );
		if ( !t ) { out( "CLASS null" ); return; }
		idDict args; fillDict( args, 1 );
		idEntity *e = gameLocal.SpawnEntityType( *t, &args );
		out( "RET ent=%d", e ? e->entityNumber : -1 );
	}
	else if ( cmd == "fill" ) {
		idTypeInfo *t = idClass::GetClass( w[0].c_str() );
		if ( !t ) { out( "CLASS null" ); return; }
		int n = atoi( w[1].c_str() ), i = 0;
		g_quiet = true;
		for ( g_fillCount = 0; g_fillCount < n; g_fillCount++ ) { idDict args; args.Set( "name", va( "fill%d", g_fillCount ) ); gameLocal.SpawnEntityType( *t, &args ); }
		g_quiet = false;
		out( "FILLED %d", g_fillCount );
		g_fillCount = -1;
	}
	else if ( cmd == "remove" ) {
		idEntity *e = entityAt( w[0] );
		if ( e ) { delete e; out( "REMOVED %s", w[0].c_str() ); } else out( "NOTFOUND" );
	}
	else if ( cmd == "find" ) { idEntity *e = gameLocal.FindEntity( w.empty() ? "" : w[0].c_str() ); out( "FOUND %d", e ? e->entityNumber : -1 ); }
	else if ( cmd == "finddef" ) {
		idEntity *from = atoi( w[0].c_str() ) < 0 ? NULL : entityAt( w[0] );
		idEntity *e = gameLocal.FindEntityUsingDef( from, w[1].c_str() ); out( "FOUND %d", e ? e->entityNumber : -1 );
	}
	else if ( cmd == "setname" ) { idEntity *e = entityAt( w[0] ); if ( e ) e->SetName( w.size() > 1 ? w[1].c_str() : "" ); else out( "NOTFOUND" ); }
	else if ( cmd == "active" ) { idEntity *e = entityAt( w[0] ); if ( e ) e->BecomeActive( atoi( w[1].c_str() ) ); else out( "NOTFOUND" ); }
	else if ( cmd == "inactive" ) { idEntity *e = entityAt( w[0] ); if ( e ) e->BecomeInactive( atoi( w[1].c_str() ) ); else out( "NOTFOUND" ); }
	else if ( cmd == "isactive" ) { idEntity *e = entityAt( w[0] ); out( "RET %d", e && e->IsActive() ? 1 : 0 ); }
	else if ( cmd == "mapclear" ) { if ( gameLocal.mapFile ) { delete gameLocal.mapFile; gameLocal.mapFile = NULL; } }
	else if ( cmd == "mapnew" ) { gameLocal.mapFile = new idMapFileFake; }
	else if ( cmd == "mapent" ) { idMapEntityFake *m = new idMapEntityFake; fillDict( m->epairs, 0 ); gameLocal.mapFile->ents.push_back( m ); }
	else if ( cmd == "spawnmap" ) gameLocal.SpawnMapEntities();
	else if ( cmd == "populate" ) gameLocal.MapPopulate();
	else if ( cmd == "inhibit" ) { idDict d; fillDict( d, 0 ); out( "RET %d", gameLocal.InhibitEntitySpawn( d ) ? 1 : 0 ); }
	else if ( cmd == "msec" ) gameLocal.msec = atoi( w[0].c_str() );
	else if ( cmd == "cinematic" ) gameLocal.inCinematic = atoi( w[0].c_str() ) != 0;
	else if ( cmd == "frame" ) gameLocal.RunFrameThink();
	else if ( cmd == "state" ) dumpState();
	else out( "UNKNOWN %s", cmd.c_str() );
}

static void runGuarded( const std::string &cmd, const std::string &rest ) {
	try { runCommand( cmd, rest ); }
	catch ( idException &e ) { outs( "THROW", e.error ); }
}

int main( int argc, char **argv ) {
	if ( argc < 3 ) { fprintf( stderr, "usage: harness_game <scenario> <golden>\n" ); return 2; }
	g_golden = fopen( argv[2], "wb" );
	FILE *scn = fopen( argv[1], "rb" );
	if ( !scn || !g_golden ) { fprintf( stderr, "cannot open files\n" ); return 2; }
	// idGameLocal::Clear (the entity table)
	memset( gameLocal.entities, 0, sizeof( gameLocal.entities ) );
	memset( gameLocal.spawnIds, -1, sizeof( gameLocal.spawnIds ) );
	gameLocal.firstFreeIndex = 0; gameLocal.num_entities = 0; gameLocal.numEntitiesToDeactivate = 0;
	gameLocal.sortPushers = false; gameLocal.sortTeamMasters = false; gameLocal.editEntities = NULL; gameLocal.entityHash.Clear( 1024, MAX_GENTITIES );
	gameLocal.inCinematic = false; gameLocal.framenum = 0; gameLocal.previousTime = 0; gameLocal.time = 0; gameLocal.msec = 16; gameLocal.mapFile = NULL;
	gameLocal.spawnCount = idGameLocal::INITIAL_SPAWN_COUNT; gameLocal.mapSpawnCount = 0; gameLocal.isMultiplayer = false; gameLocal.isClient = false;
	gameLocal.spawnedEntities.Clear(); gameLocal.activeEntities.Clear();
	char line[8192];
	while ( fgets( line, sizeof( line ), scn ) ) {
		std::string l = line;
		while ( !l.empty() && ( l[l.size() - 1] == '\n' || l[l.size() - 1] == '\r' ) ) l.erase( l.size() - 1 );
		if ( l.empty() || l[0] == '#' ) continue;
		outs( "CMD", l );
		size_t sp = l.find( ' ' );
		std::string cmd = l.substr( 0, sp ), rest = sp == std::string::npos ? "" : l.substr( sp + 1 );
		if ( setjmp( g_errJmp ) == 0 ) runGuarded( cmd, rest );
		else {
			if ( g_fillCount >= 0 ) { out( "FILLED %d", g_fillCount ); g_fillCount = -1; }
			outs( "THROW", g_errText );
		}
	}
	fclose( scn ); fclose( g_golden );
	return 0;
}
