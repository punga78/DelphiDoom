// Issue #255 (Doom 3, phase 3, ondata 12a): driver of the fourth parity harness. Written for this repository. It is linked with
// the REAL idlib and with, cut out of the source by Build-Harness-World.ps1 (see the header of that script for the list):
//   the REAL Trigger.h and Mover.h (the classes of the triggers and of the movers), the REAL idEntityPtr,
//   the REAL event queue (idEvent and the posting and processing of idClass),
//   the REAL bodies of Class.cpp/Event.cpp (types), Entity.cpp, Game_local.cpp, Physics_Parametric.cpp, Trigger.cpp and Mover.cpp.
// What the original asks of the renderer, the sound, the clipping and the script machine is a stub here that does nothing (or, for
// the script thread, writes down the call); the entity and physics classes are declared here with the members the real bodies use.
//
// Usage: harness_world.exe <scenario.scn> <golden.txt>
//
// SCENARIO: one command per line; empty lines and '#' lines are skipped; every command is echoed as "CMD <line>".
//   def <name> [<key> <value>]...        an entityDef (spawnclass, defaults)
//   func <name>                          a script function (a trigger can call it)
//   spawn [<key> <value>]...             SpawnEntityDef; "RET <0|1> ent=<number>"
//   frame [<n>]                          n frames (think, then the events due); each frame is followed by the "FRAME" line
//   event <ent> <name> [<arg>...]        ProcessEvent: an argument is an entity number (e), an integer (d), a float (f) or x,y,z (v)
//   post <ent> <ms> <name> [<arg>...]    PostEventMS
//   touch <ent> <other>                  the <touch> event of <ent>
//   thread <n>                           the number of the script thread that is "running" (CurrentThreadNum)
//   dump <ent>                           the private state of the entity by class
//   queue                                the pending events in order
//   startup <0|1>                        GameState STARTUP (1) or ACTIVE (0)
//   remove <ent>                         delete the entity
//   find <name>
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
// a float as its bits: the golden compares bit for bit
static unsigned int fb( float f ) { unsigned int u; memcpy( &u, &f, 4 ); return u; }

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
void idCVarSystem::SetCVarString( const char *name, const char *value, int flags ) {}
void idCVarSystem::SetCVarBool( const char *name, const bool value, int flags ) {}

// ---------------------------------------------------------------- the constants of Game_local.h, Entity.h and the render world
#define MAX_CLIENTS				32
#define GENTITYNUM_BITS			12
#define MAX_GENTITIES			(1<<GENTITYNUM_BITS)
#define ENTITYNUM_NONE			(MAX_GENTITIES-1)
#define ENTITYNUM_WORLD			(MAX_GENTITIES-2)
#define ENTITYNUM_MAX_NORMAL	(MAX_GENTITIES-2)
enum { TH_ALL = -1, TH_THINK = 1, TH_PHYSICS = 2, TH_ANIMATE = 4, TH_UPDATEVISUALS = 8, TH_UPDATEPARTICLES = 16 };
enum gameState_t { GAMESTATE_UNINITIALIZED, GAMESTATE_NOMAP, GAMESTATE_STARTUP, GAMESTATE_ACTIVE, GAMESTATE_SHUTDOWN };
const int USERCMD_HZ = 60;
const int USERCMD_MSEC = 1000 / USERCMD_HZ;
const int SHADERPARM_MODE = 7;
const int MAX_RENDERENTITY_GUI = 3;
const int INVALID_JOINT = -1;
#define MASK_SOLID 1
#define CONTENTS_TRIGGER 2
#define CONTENTS_FLASHLIGHT_TRIGGER 4
#define SND_CHANNEL_ANY 0
#define SND_CHANNEL_BODY 1
#define SND_CHANNEL_BODY2 2
#define SSF_NO_OCCLUSION 1
enum { SIG_TRIGGER = 0, SIG_REMOVED, SIG_DAMAGE, SIG_BLOCKED, SIG_MOVER_POS1, SIG_MOVER_POS2, SIG_MOVER_1TO2, SIG_MOVER_2TO1 };
typedef int qhandle_t;
typedef int jointHandle_t;
typedef int s_channelType;
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
	const idMaterial *FindMaterial( const char *name, bool makeDefault ) { static idMaterial m; return &m; }
};
static idDeclManagerGame g_declManager;
static idDeclManagerGame *declManager = &g_declManager;

// the script program and the thread (fakes that write down the calls)
struct function_t { std::string name; const char *Name() const { return name.c_str(); } };
class idProgramFake {
public:
	std::vector<function_t *> functions;
	const function_t *FindFunction( const char *name ) { for ( size_t i = 0; i < functions.size(); i++ ) if ( functions[i]->name == name ) return functions[i]; return NULL; }
	void SetEntity( const char *name, class idEntity *ent );
};
static int g_currentThread = 0;
class idThread {
public:
	idThread( const function_t *func ) { out( "CALL idThread %s", func->name.c_str() ); }
	void DelayedStart( int delay ) { out( "CALL idThread.DelayedStart %d", delay ); }
	static int CurrentThreadNum( void ) { return g_currentThread; }
	static idThread *CurrentThread( void ) { return NULL; }
	static void ReturnInt( int value ) { out( "RETURN d %d", value ); }
	static void ReturnFloat( float value ) { out( "RETURN f %08X", fb( value ) ); }
	static void ReturnString( const char *text ) { out( "RETURN s %s", text ); }
	static void ObjectMoveDone( int threadnum, class idEntity *obj );
};
static idCVar g_skill( "g_skill", "1", 0, "" ), g_debugTriggers( "g_debugTriggers", "0", 0, "" ), g_debugMover( "g_debugMover", "0", 0, "" );

// ---------------------------------------------------------------- the stubs of the engine parts that are not here
class idSaveGame; class idRestoreGame; class idBitMsgDelta; class idEditEntities; class idPlayer; class idEntity; class idActor;
class idTraceModel {
public:
	idBounds bounds;
	idTraceModel() {}
	idTraceModel( const idBounds &b ) { bounds = b; }
	void SetupBox( const idBounds &b ) { bounds = b; }
	void SetupCylinder( const idBounds &b, int sides ) { bounds = b; }
	void SetupCone( const idBounds &b, int sides ) { bounds = b; }
};
class idClip { public: int dummy; };
class idClipModel {
public:
	idBounds bounds, absBounds;
	int contents, id;
	bool enabled;
	idClipModel() : contents( 0 ), id( 0 ), enabled( true ) {}
	explicit idClipModel( const idTraceModel &trm ) : contents( 0 ), id( 0 ), enabled( true ) { bounds = trm.bounds; absBounds = bounds; }
	explicit idClipModel( const char *name ) : contents( 0 ), id( 0 ), enabled( true ) {}
	explicit idClipModel( const idClipModel *model ) : contents( 0 ), id( 0 ), enabled( true ) { if ( model ) { bounds = model->bounds; absBounds = model->absBounds; contents = model->contents; } }
	static bool CheckModel( const char *name ) { return false; }
	void Link( idClip &clip, idEntity *ent, int newId, const idVec3 &newOrigin, const idMat3 &newAxis ) { id = newId; absBounds = bounds; absBounds[0] += newOrigin; absBounds[1] += newOrigin; }
	void Unlink( void ) {}
	void SetContents( int c ) { contents = c; }
	int GetContents( void ) const { return contents; }
	const idBounds &GetBounds( void ) const { return bounds; }
	const idBounds &GetAbsBounds( void ) const { return absBounds; }
	const idVec3 &GetOrigin( void ) const { static idVec3 o( 0, 0, 0 ); return o; }
	int GetId( void ) const { return id; }
	void Enable( void ) { enabled = true; }
	void Disable( void ) { enabled = false; }
};
struct refSound_t { idVec3 origin; struct { int soundShaderFlags; } parms; };
struct renderEntity_t { void *hModel; float shaderParms[12]; idVec3 origin; idMat3 axis; idBounds bounds; idJointMat *joints; int numJoints; };
class idRenderWorldFake { public: int FindPortal( const idBounds &b ) { return 0; } };
static idRenderWorldFake g_renderWorld;
static idRenderWorldFake *gameRenderWorld = &g_renderWorld;
// idPush: nothing is ever pushed or blocked (idPush::ClipPush is not in this harness)
class idPushFake {
public:
	void ClipPush( trace_t &results, idEntity *pusher, int flags, const idVec3 &oldOrigin, const idMat3 &oldAxis, const idVec3 &newOrigin, const idMat3 &newAxis ) { results.fraction = 1.0f; }
	void InitSavingPushedEntityPositions( void ) {}
	void RestorePushedEntityPositions( void ) {}
	int GetNumPushedEntities( void ) const { return 0; }
	idEntity *GetPushedEntity( int index ) const { return NULL; }
};
// the animation system (no model has a skeleton here: GetAnimator() is NULL, the code that uses the animator is never reached
// but compiles)
class idAnim { public: const void *MD5Anim( int num ) const { return NULL; } };
class idDeclModelDefFake { public: idVec3 GetVisualOffset( void ) const { return vec3_zero; } };
class idAnimator {
public:
	int GetJointHandle( const char *name ) const { return INVALID_JOINT; }
	int GetAnim( const char *name ) const { return 0; }
	const idAnim *GetAnim( int num ) const { return NULL; }
	void CreateFrame( int currentTime, bool force ) {}
	void ForceUpdate( void ) {}
	const void *ModelHandle( void ) const { return NULL; }
	const idDeclModelDefFake *ModelDef( void ) const { return NULL; }
	bool RemoveOrigin( void ) const { return false; }
	void GetJointTransform( jointHandle_t jointHandle, int currentTime, idVec3 &offset, idMat3 &axis ) {}
};
class idGameEditFake { public: void ANIM_CreateAnimFrame( const void *model, const void *anim, int numJoints, idJointMat *frame, int frameNum, const idVec3 &modelOffset, bool removeOriginOffset ) {} };
static idGameEditFake g_gameEdit;
static idGameEditFake *gameEdit = &g_gameEdit;
class idPlayerView { public: void Fade( const idVec4 &color, int time ) { out( "CALL playerView.Fade" ); } };

// ---------------------------------------------------------------- idEntityPtr (real) and the physics classes of the harness
class idGameLocal;
#include "../world/entityptr_class.inc"

class idPhysics {
public:
	idEntity *self;
	idPhysics() : self( NULL ) {}
	virtual ~idPhysics() {}
	static int SnapTimeToPhysicsFrame( int t );
	virtual void SetSelf( idEntity *e ) { self = e; }
	virtual void SetClipModel( idClipModel *model, float density, int id = 0, bool freeOld = true ) = 0;
	virtual idClipModel *GetClipModel( int id = 0 ) const = 0;
	virtual void SetContents( int contents, int id = -1 ) = 0;
	virtual int GetContents( int id = -1 ) const = 0;
	virtual const idBounds &GetAbsBounds( int id = -1 ) const = 0;
	virtual bool Evaluate( int timeStepMSec, int endTimeMSec ) = 0;
	virtual void UpdateTime( int endTimeMSec ) = 0;
	virtual int GetTime( void ) const = 0;
	virtual bool IsAtRest( void ) const = 0;
	virtual void SetOrigin( const idVec3 &newOrigin, int id = -1 ) = 0;
	virtual void SetAxis( const idMat3 &newAxis, int id = -1 ) = 0;
	virtual const idVec3 &GetOrigin( int id = 0 ) const = 0;
	virtual const idMat3 &GetAxis( int id = 0 ) const = 0;
	virtual void DisableClip( void ) = 0;
	virtual void EnableClip( void ) = 0;
	virtual idEntity *GetBlockingEntity( void ) const { return NULL; }
	virtual int GetLinearEndTime( void ) const { return 0; }
	virtual int GetAngularEndTime( void ) const { return 0; }
	virtual void SaveState( void ) {}
	virtual void RestoreState( void ) {}
	// what the real entity code asks of the physics of the bodies that are not here (the real bodies of the two classes below
	// override the ones that matter)
	virtual void Activate( void ) {}
	virtual void SetMaster( idEntity *master, const bool orientated = true ) {}
	virtual void ClearContacts( void ) {}
	virtual void SetPushed( int deltaTime ) {}
	// idEntity::BecomeActive and idGameLocal::SortActiveEntityList ask IsType( idPhysics_Parametric::Type ) and IsType( idPhysics_Actor::Type )
	virtual bool IsParametric( void ) const { return false; }
};
class idPhysics_Base : public idPhysics {
public:
	idBounds bounds, absBounds;
	const idBounds &GetBounds( int id = -1 ) const { return bounds; }
	const idBounds &GetAbsBounds( int id = -1 ) const { return absBounds; }
};
#include "../world/sstate.inc"
class idPhysics_Static : public idPhysics {
public:
	idPhysics_Static( void );
	virtual ~idPhysics_Static( void );
	void SetClipModel( idClipModel *model, float density, int id = 0, bool freeOld = true );
	idClipModel *GetClipModel( int id = 0 ) const { return clipModel; }
	void SetContents( int contents, int id = -1 );
	int GetContents( int id = -1 ) const;
	const idBounds &GetAbsBounds( int id = -1 ) const;
	bool Evaluate( int timeStepMSec, int endTimeMSec );
	// the bodies of these are empty or a single return in the original
	void UpdateTime( int endTimeMSec ) {}
	int GetTime( void ) const { return 0; }
	void Activate( void ) {}
	bool IsAtRest( void ) const { return true; }
	void SetOrigin( const idVec3 &newOrigin, int id = -1 );
	void SetAxis( const idMat3 &newAxis, int id = -1 );
	const idVec3 &GetOrigin( int id = 0 ) const;
	const idMat3 &GetAxis( int id = 0 ) const;
	void DisableClip( void );
	void EnableClip( void );
	void SetMaster( idEntity *master, const bool orientated = true );
	void SaveState( void ) {}
	void RestoreState( void ) {}
	void SetPushed( int deltaTime ) {}
	void ClearContacts( void ) {}
private:
	staticPState_t current;
	idClipModel *clipModel;
	bool hasMaster;
	bool isOrientated;
};
#include "../world/pstate.inc"
class idPhysics_Parametric : public idPhysics_Base {
public:
	void SetSelf( idEntity *e ) { self = e; }
	idPhysics_Parametric( void );
	~idPhysics_Parametric( void );
	void SetPusher( int flags );
	bool IsPusher( void ) const;
	void SetLinearExtrapolation( extrapolation_t type, int time, int duration, const idVec3 &base, const idVec3 &speed, const idVec3 &baseSpeed );
	void SetAngularExtrapolation( extrapolation_t type, int time, int duration, const idAngles &base, const idAngles &speed, const idAngles &baseSpeed );
	extrapolation_t GetLinearExtrapolationType( void ) const;
	extrapolation_t GetAngularExtrapolationType( void ) const;
	void SetLinearInterpolation( int time, int accelTime, int decelTime, int duration, const idVec3 &startPos, const idVec3 &endPos );
	void SetAngularInterpolation( int time, int accelTime, int decelTime, int duration, const idAngles &startAng, const idAngles &endAng );
	void GetLocalOrigin( idVec3 &curOrigin ) const;
	void GetLocalAngles( idAngles &curAngles ) const;
	void SetClipModel( idClipModel *model, float density, int id = 0, bool freeOld = true );
	idClipModel *GetClipModel( int id = 0 ) const;
	void SetContents( int contents, int id = -1 );
	int GetContents( int id = -1 ) const;
	const idBounds &GetBounds( int id = -1 ) const;
	const idBounds &GetAbsBounds( int id = -1 ) const;
	bool Evaluate( int timeStepMSec, int endTimeMSec );
	void UpdateTime( int endTimeMSec );
	int GetTime( void ) const;
	void Activate( void );
	bool IsAtRest( void ) const;
	void SaveState( void );
	void RestoreState( void );
	void SetOrigin( const idVec3 &newOrigin, int id = -1 );
	void SetAxis( const idMat3 &newAxis, int id = -1 );
	const idVec3 &GetOrigin( int id = 0 ) const;
	const idMat3 &GetAxis( int id = 0 ) const;
	void DisableClip( void );
	void EnableClip( void );
	idEntity *GetBlockingEntity( void ) const;
	int GetLinearEndTime( void ) const;
	int GetAngularEndTime( void ) const;
	void SetClipMask( int mask ) {}
	idClipModel *GetClipModel() { return clipModel; }
	void SetMaster( idEntity *master, const bool orientated = true );
	bool IsParametric( void ) const { return true; }
	void SetPushed( int deltaTime ) {}
	void GetAngles( idAngles &curAngles ) const { curAngles = current.angles; }
private:
	parametricPState_t current;
	parametricPState_t saved;
	bool isPusher;
	idClipModel *clipModel;
	int pushFlags;
	trace_t pushResults;
	bool isBlocked;
	bool hasMaster;
	bool isOrientated;
	bool TestIfAtRest( void ) const;
	void Rest( void );
};

// ---------------------------------------------------------------- the entity class of the harness and gameLocal
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
	idList< idEntityPtr<idEntity> >	targets;
	struct { bool hidden; bool takedamage; bool solidForTeam; bool networkSync; bool forcePhysicsUpdate; bool bindOrientated; } fl;
	idPhysics *				physics;
	idPhysics_Static		defaultPhysicsObj;
	idEntity *				bindMaster;
	jointHandle_t			bindJoint;
	int						bindBody;
	idEntity *				teamMaster;
	idEntity *				teamChain;
	refSound_t				refSound;
	renderEntity_t			renderEntity;

							idEntity();
	virtual					~idEntity();
	void					Spawn( void );
	virtual void			Think( void );
	const char *			GetEntityDefName( void ) const;
	void					SetName( const char *name );
	const char *			GetName( void ) const;
	bool					IsActive( void ) const;
	bool					IsAtRest( void ) const;
	void					BecomeActive( int flags );
	void					BecomeInactive( int flags );
	virtual bool			IsHidden( void ) const;
	virtual void			Hide( void );
	virtual void			Show( void );
	void					FindTargets( void );
	void					RemoveNullTargets( void );
	void					ActivateTargets( idEntity *activator ) const;
	bool					RunPhysics( void );
	idPhysics *				GetPhysics( void ) const { return physics; }
	void					SetPhysics( idPhysics *phys );
	void					SetOrigin( const idVec3 &org );
	void					SetAxis( const idMat3 &axis );
	void					SetAngles( const idAngles &ang );
	void					InitDefaultPhysics( const idVec3 &origin, const idMat3 &axis );
	idVec3					GetLocalVector( const idVec3 &vec ) const;
	idVec3					GetLocalCoordinates( const idVec3 &vec ) const;
	idVec3					GetWorldVector( const idVec3 &vec ) const;
	idVec3					GetWorldCoordinates( const idVec3 &vec ) const;
	bool					GetMasterPosition( idVec3 &masterOrigin, idMat3 &masterAxis ) const;
	// binding and the physics teams
	virtual void			PreBind( void );
	virtual void			PostBind( void );
	virtual void			PreUnbind( void ) {}
	virtual void			PostUnbind( void ) {}
	bool					InitBind( idEntity *master );
	void					FinishBind( void );
	void					Bind( idEntity *master, bool orientated );
	void					BindToJoint( idEntity *master, const char *jointname, bool orientated );
	void					BindToBody( idEntity *master, int bodyId, bool orientated );
	void					Unbind( void );
	void					RemoveBinds( void );
	bool					IsBound( void ) const;
	bool					IsBoundTo( idEntity *master ) const;
	idEntity *				GetBindMaster( void ) const;
	jointHandle_t			GetBindJoint( void ) const;
	int						GetBindBody( void ) const;
	idEntity *				GetTeamMaster( void ) const;
	idEntity *				GetNextTeamEntity( void ) const;
	void					JoinTeam( idEntity *teammember );
	void					QuitTeam( void );
	idAnimator *			GetAnimator( void ) { return NULL; }
	void					UpdateFromPhysics( bool moveBack );
	void					UpdateModelTransform( void );
	bool					GetPhysicsToVisualTransform( idVec3 &origin, idMat3 &axis ) { return false; }
	void					Event_Bind( idEntity *master );
	void					Event_BindPosition( idEntity *master );
	void					Event_Unbind( void );
	void					Event_RemoveBinds( void );
	void					Event_SpawnBind( void );
	bool					HasSignal( int signalnum ) const { return false; }
	void					Signal( int signalnum ) {}
	void					UpdateVisuals( void );
	void					FreeModelDef( void ) {}
	void					Present( void ) {}
	bool					UpdateAnimationControllers( void ) { return false; }
	void					SetShaderParm( int parmnum, float value ) {}
	bool					StartSound( const char *soundName, const s_channelType channel, int soundShaderFlags, bool broadcast, int *length ) { return false; }
	void					StopSound( const s_channelType channel, bool broadcast ) {}
	virtual void			Damage( idEntity *inflictor, idEntity *attacker, const idVec3 &dir, const char *damageDefName, const float damageScale, const int location ) {}
	void					Event_FindTargets( void );
	void					Event_ActivateTargets( idEntity *activator );
	void					Event_Hide( void );
	void					Event_Show( void );
};

class idPlayer : public idEntity {
public:
	CLASS_PROTOTYPE( idPlayer );
	bool spectating;
	idAngles viewAngles;
	idPlayerView playerView;
	// the inventory: one dictionary per item, named by "inv_name" (idPlayer::inventory is far larger: only what RequirementMet asks)
	std::vector<idDict *> items;
	idDict *FindInventoryItem( const char *name ) {
		for ( size_t i = 0; i < items.size(); i++ ) if ( idStr::Icmp( items[i]->GetString( "inv_name" ), name ) == 0 ) return items[i];
		return NULL;
	}
	void RemoveInventoryItem( idDict *item ) {
		for ( size_t i = 0; i < items.size(); i++ ) if ( items[i] == item ) { items.erase( items.begin() + i ); return; }
	}
};

class idEditEntities { public: void RemoveSelectedEntity( idEntity *ent ) {} };
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
	idEntity *				world;
	idProgramFake			program;
	int						time, previousTime, msec, framenum, realClientTime;
	idRandom				random;
	idClip					clip;
	idPushFake				push;
	gameState_t				gamestate;

	gameState_t				GameState( void ) const { return gamestate; }
	void					Printf( const char *fmt, ... ) const;
	void					Warning( const char *fmt, ... ) const;
	void					Error( const char *fmt, ... ) const;
	void					RegisterEntity( idEntity *ent );
	void					UnregisterEntity( idEntity *ent );
	bool					SpawnEntityDef( const idDict &args, idEntity **ent = NULL, bool setDefaults = true );
	const idDeclEntityDef *	FindEntityDef( const char *name, bool makeDefault = true ) const;
	void					AddEntityToHash( const char *name, idEntity *ent );
	bool					RemoveEntityFromHash( const char *name, idEntity *ent );
	idEntity *				FindEntity( const char *name ) const;
	int						GetTargets( const idDict &args, idList< idEntityPtr<idEntity> > &list, const char *ref ) const;
	bool					RequirementMet( idEntity *activator, const idStr &requires, int removeItem );
	idPlayer *				GetLocalPlayer( void ) const { return NULL; }
	void					RunFrameThink( void );
	void					SortActiveEntityList( void );
	void					NewMap( void );
};
static idGameLocal gameLocal;

#include "../world/entityptr_impl.inc"

void idGameLocal::Printf( const char *fmt, ... ) const { char b[16384]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( b, sizeof( b ), fmt, ap ); va_end( ap ); outs( "PRINT", b ); }
void idGameLocal::Warning( const char *fmt, ... ) const { char b[16384]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( b, sizeof( b ), fmt, ap ); va_end( ap ); outs( "WARNING", b ); }
// gameLocal.Error leaves by longjmp to the command loop (bcc32c crashes on exceptions through some of the real functions)
#include <setjmp.h>
static jmp_buf g_errJmp; static std::string g_errText;
void idGameLocal::Error( const char *fmt, ... ) const {
	char b[16384]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( b, sizeof( b ), fmt, ap ); va_end( ap );
	g_quiet = false; outs( "ERROR", b ); g_errText = b; longjmp( g_errJmp, 1 );
}
void idProgramFake::SetEntity( const char *name, idEntity *ent ) { out( "CALL program.SetEntity %s %d", name, ent ? ent->entityNumber : -1 ); }
void idThread::ObjectMoveDone( int threadnum, idEntity *obj ) { if ( !threadnum ) return; out( "CALL idThread.ObjectMoveDone %d %d", threadnum, obj->entityNumber ); }

void *idClass::operator new( size_t s ) { return calloc( 1, s ); }
void *idClass::operator new( size_t s, int, int, char *, int ) { return calloc( 1, s ); }
void idClass::operator delete( void *p ) { free( p ); }
void idClass::operator delete( void *p, int, int, char *, int ) { free( p ); }

// the real headers of the triggers and of the movers
#include "../world/Trigger.h"
#include "../world/Mover.h"

// the real bodies of Event.cpp, Class.cpp (types and events)
#include "../gamefw/event_extract.inc"
#include "../gamefw/class_extract.inc"

// ---------------------------------------------------------------- the events
#include "../world/entity_events.inc"
const idEventDef EV_Thread_SetCallback( "<script_setcallback>", NULL );
#include "../world/mover_events.inc"
#define MAX_EVENTSPERFRAME 4096
#include "../world/event_rt.inc"
static const char *guiBinaryMoverStates[] = { "1", "2", "3", "4" };
static idCVar g_timeentities( "g_timeentities", "0", 0, "" ), g_cinematic( "g_cinematic", "1", 0, "" );

// the entities of the harness
class idRecorder : public idEntity {
public:
	CLASS_PROTOTYPE( idRecorder );
	void Spawn( void ) {}
	void Event_Activate( idEntity *activator );
	virtual void Damage( idEntity *inflictor, idEntity *attacker, const idVec3 &dir, const char *damageDefName, const float damageScale, const int location ) { out( "DAMAGE %s %s", name.c_str(), damageDefName ); }
};
class idWorldspawn : public idEntity {
public:
	CLASS_PROTOTYPE( idWorldspawn );
	void Spawn( void ) { gameLocal.world = this; }
};

// the order of the declarations is the order of the static initialization
ABSTRACT_DECLARATION( idClass, idEntity )
	EVENT( EV_FindTargets,			idEntity::Event_FindTargets )
	EVENT( EV_ActivateTargets,		idEntity::Event_ActivateTargets )
	EVENT( EV_Hide,					idEntity::Event_Hide )
	EVENT( EV_Show,					idEntity::Event_Show )
	EVENT( EV_RemoveBinds,			idEntity::Event_RemoveBinds )
	EVENT( EV_Bind,					idEntity::Event_Bind )
	EVENT( EV_BindPosition,			idEntity::Event_BindPosition )
	EVENT( EV_Unbind,				idEntity::Event_Unbind )
	EVENT( EV_SpawnBind,			idEntity::Event_SpawnBind )
END_CLASS
CLASS_DECLARATION( idEntity, idPlayer )
END_CLASS
CLASS_DECLARATION( idEntity, idRecorder )
	EVENT( EV_Activate,				idRecorder::Event_Activate )
END_CLASS
CLASS_DECLARATION( idEntity, idWorldspawn )
END_CLASS
#include "../world/trigger_decl.inc"
CLASS_DECLARATION( idEntity, idMover_Binary )
	EVENT( EV_Thread_SetCallback,		idMover_Binary::Event_SetCallback )
	EVENT( EV_Mover_ReturnToPos1,		idMover_Binary::Event_ReturnToPos1 )
	EVENT( EV_Activate,					idMover_Binary::Event_Use_BinaryMover )
	EVENT( EV_ReachedPos,				idMover_Binary::Event_Reached_BinaryMover )
	EVENT( EV_Mover_MatchTeam,			idMover_Binary::Event_MatchActivateTeam )
	EVENT( EV_Mover_Enable,				idMover_Binary::Event_Enable )
	EVENT( EV_Mover_Disable,			idMover_Binary::Event_Disable )
END_CLASS
CLASS_DECLARATION( idMover_Binary, idDoor )
	EVENT( EV_Activate,					idDoor::Event_Activate )
	EVENT( EV_Door_StartOpen,			idDoor::Event_StartOpen )
	EVENT( EV_Door_SpawnDoorTrigger,	idDoor::Event_SpawnDoorTrigger )
	EVENT( EV_Door_Open,				idDoor::Event_Open )
	EVENT( EV_Door_Close,				idDoor::Event_Close )
	EVENT( EV_Door_Lock,				idDoor::Event_Lock )
	EVENT( EV_Door_IsOpen,				idDoor::Event_IsOpen )
	EVENT( EV_Door_IsLocked,			idDoor::Event_Locked )
	EVENT( EV_ReachedPos,				idDoor::Event_Reached_BinaryMover )
END_CLASS
CLASS_DECLARATION( idEntity, idMover )
	EVENT( EV_Thread_SetCallback,	idMover::Event_SetCallback )
	EVENT( EV_ReachedPos,			idMover::Event_UpdateMove )
	EVENT( EV_StopMoving,			idMover::Event_StopMoving )
	EVENT( EV_Speed,				idMover::Event_SetMoveSpeed )
	EVENT( EV_Time,					idMover::Event_SetMoveTime )
	EVENT( EV_AccelTime,			idMover::Event_SetAccellerationTime )
	EVENT( EV_DecelTime,			idMover::Event_SetDecelerationTime )
	EVENT( EV_MoveTo,				idMover::Event_MoveTo )
	EVENT( EV_MoveToPos,			idMover::Event_MoveToPos )
	EVENT( EV_Move,					idMover::Event_MoveDir )
	EVENT( EV_IsMoving,				idMover::Event_IsMoving )
	EVENT( EV_ReachedAng,			idMover::Event_UpdateRotation )
	EVENT( EV_StopRotating,			idMover::Event_StopRotating )
	EVENT( EV_RotateDownTo,			idMover::Event_RotateDownTo )
	EVENT( EV_RotateUpTo,			idMover::Event_RotateUpTo )
	EVENT( EV_RotateTo,				idMover::Event_RotateTo )
	EVENT( EV_Rotate,				idMover::Event_Rotate )
	EVENT( EV_RotateOnce,			idMover::Event_RotateOnce )
	EVENT( EV_IsRotating,			idMover::Event_IsRotating )
END_CLASS

// ---------------------------------------------------------------- the real bodies
#include "../world/game2.inc"
#include "../world/entity_ctor.inc"
void idEntity::Spawn( void ) {
	const char *temp;
	const char *classname;
	idVec3 origin;
	idMat3 axis;
	float angle;
#include "../world/spawn.inc"
}
// idEntity::UpdateVisuals is UpdateModel and UpdateSound; here only the part that gives the render entity its position (the
// TH_UPDATEVISUALS flag that UpdateModel sets and Present clears is not ported, see D3Game\CLAUDE.md)
void idEntity::UpdateVisuals( void ) { UpdateModelTransform(); }
// empty in the original
void idEntity::PreBind( void ) {}
void idEntity::PostBind( void ) {}
#include "../world/entity.inc"
#include "../world/physics.inc"
#include "../world/trigger.inc"
#include "../world/mover.inc"

void idRecorder::Event_Activate( idEntity *activator ) { out( "ACTIVATE %s by %s t=%d", name.c_str(), activator ? activator->name.c_str() : "(none)", gameLocal.time ); }
// the save game members (no save games here) and what the real bodies leave to others
void idTrigger::Save( idSaveGame *savefile ) const {} void idTrigger::Restore( idRestoreGame *savefile ) {}
void idTrigger_Multi::Save( idSaveGame *savefile ) const {} void idTrigger_Multi::Restore( idRestoreGame *savefile ) {}
void idTrigger_EntityName::Save( idSaveGame *savefile ) const {} void idTrigger_EntityName::Restore( idRestoreGame *savefile ) {}
void idTrigger_Timer::Save( idSaveGame *savefile ) const {} void idTrigger_Timer::Restore( idRestoreGame *savefile ) {}
void idTrigger_Count::Save( idSaveGame *savefile ) const {} void idTrigger_Count::Restore( idRestoreGame *savefile ) {}
void idTrigger_Hurt::Save( idSaveGame *savefile ) const {} void idTrigger_Hurt::Restore( idRestoreGame *savefile ) {}
void idMover_Binary::Save( idSaveGame *savefile ) const {} void idMover_Binary::Restore( idRestoreGame *savefile ) {}
void idDoor::Save( idSaveGame *savefile ) const {} void idDoor::Restore( idRestoreGame *savefile ) {}
void idMover::Save( idSaveGame *savefile ) const {} void idMover::Restore( idRestoreGame *savefile ) {}
void idMover::FindGuiTargets( void ) {}
void idMover::Killed( idEntity *inflictor, idEntity *attacker, int damage, const idVec3 &dir, int location ) {}
void idMover::WriteToSnapshot( idBitMsgDelta &msg ) const {}
void idMover::ReadFromSnapshot( const idBitMsgDelta &msg ) {}
void idMover::Hide( void ) { idEntity::Hide(); }
void idMover::Show( void ) { idEntity::Show(); }
void idMover::Event_FindGuiTargets( void ) {}
void idMover::Event_InitGuiTargets( void ) {}
void idMover_Binary::WriteToSnapshot( idBitMsgDelta &msg ) const {}
void idMover_Binary::ReadFromSnapshot( const idBitMsgDelta &msg ) {}
void idMover_Binary::FindGuiTargets( void ) {}
void idMover_Binary::Event_FindGuiTargets( void ) {}
void idMover_Binary::Event_InitGuiTargets( void ) {}
void idMover_Binary::SetGuiState( const char *key, const char *val ) const {}
void idMover_Binary::SetPortalState( bool open ) {}
void idMover_Binary::Event_OpenPortal( void ) {}
void idMover_Binary::Event_ClosePortal( void ) {}
void idDoor::Hide( void ) { idEntity::Hide(); }
void idDoor::Show( void ) { idEntity::Show(); }
void idDoor::SetAASAreaState( bool closed ) {}
void idDoor::GetLocalTriggerPosition( const idClipModel *trigger ) {}
void idDoor::Event_OpenPortal( void ) {}
void idDoor::Event_ClosePortal( void ) {}
void idDoor::Event_TeamBlocked( idEntity *blockedEntity, idEntity *blockingEntity ) {}
void idDoor::Event_PartBlocked( idEntity *blockingEntity ) {}
void idDoor::Event_Touch( idEntity *other, trace_t *trace ) {}
void idDoor::Event_SpawnSoundTrigger( void ) {}
void idDoor::Event_SpectatorTouch( idEntity *other, trace_t *trace ) {}
void idDoor::SetCompanion( idDoor *door ) {}
void idDoor::Use( idEntity *other, idEntity *activator ) {}

void idGameLocal::NewMap( void ) {
	// the entity statements of the real idGameLocal::InitFromNewMap and Clear, cut out by Build-Harness-Game.ps1
#include "../gamefw/newmap_extract.inc"
	random.SetSeed( 0 );
	gamestate = GAMESTATE_STARTUP;
}
void idGameLocal::RunFrameThink( void ) {
	idEntity *	ent;
	int			num;
	float		ms;
	idTimer		timer_singlethink;
#include "../gamefw/frame_head.inc"
	// sort the active entity list (the real call of idGameLocal::RunFrame, between the time update and the think loop)
	SortActiveEntityList();
#include "../gamefw/think_extract.inc"
}

// ---------------------------------------------------------------- the driver
static std::vector<std::string> g_words;
static idEntity *entityAt( const std::string &s ) {
	int n = atoi( s.c_str() );
	return ( n >= 0 && n < MAX_GENTITIES ) ? gameLocal.entities[n] : NULL;
}
static void fillDict( idDict &d, size_t from ) {
	for ( size_t i = from; i + 1 < g_words.size(); i += 2 ) d.Set( g_words[i].c_str(), g_words[i + 1].c_str() );
}
static std::string vecs( const idVec3 &v ) { char b[64]; sprintf( b, "%08X %08X %08X", fb( v.x ), fb( v.y ), fb( v.z ) ); return b; }
static void dumpEntity( idEntity *e ) {
	out( "ENT %d name=%s class=%s think=%d active=%d hidden=%d origin=%s targets=%d", e->entityNumber, e->name.c_str(), e->GetClassname(), e->thinkFlags, e->IsActive() ? 1 : 0, e->fl.hidden ? 1 : 0,
		vecs( e->GetPhysics()->GetOrigin() ).c_str(), e->targets.Num() );
	if ( e->IsType( idTrigger_Multi::Type ) ) {
		idTrigger_Multi *t = static_cast<idTrigger_Multi *>( e );
		out( "MULTI wait=%08X random=%08X delay=%08X random_delay=%08X next=%d triggerFirst=%d", fb( t->wait ), fb( t->random ), fb( t->delay ), fb( t->random_delay ), t->nextTriggerTime, t->triggerFirst ? 1 : 0 );
	}
	if ( e->IsType( idTrigger_EntityName::Type ) ) {
		idTrigger_EntityName *t = static_cast<idTrigger_EntityName *>( e );
		out( "ENAME wait=%08X random=%08X delay=%08X random_delay=%08X next=%d triggerFirst=%d entityName=%s", fb( t->wait ), fb( t->random ), fb( t->delay ), fb( t->random_delay ), t->nextTriggerTime, t->triggerFirst ? 1 : 0, t->entityName.c_str() );
	}
	if ( e->IsType( idTrigger_Timer::Type ) ) {
		idTrigger_Timer *t = static_cast<idTrigger_Timer *>( e );
		out( "TIMER on=%d random=%08X wait=%08X delay=%08X", t->on ? 1 : 0, fb( t->random ), fb( t->wait ), fb( t->delay ) );
	}
	if ( e->IsType( idTrigger_Count::Type ) ) {
		idTrigger_Count *t = static_cast<idTrigger_Count *>( e );
		out( "COUNT goal=%d count=%d delay=%08X", t->goal, t->count, fb( t->delay ) );
	}
	if ( e->IsType( idTrigger_Hurt::Type ) ) {
		idTrigger_Hurt *t = static_cast<idTrigger_Hurt *>( e );
		out( "HURT on=%d delay=%08X nextTime=%d", t->on ? 1 : 0, fb( t->delay ), t->nextTime );
	}
	if ( e->IsType( idMover_Binary::Type ) ) {
		idMover_Binary *m = static_cast<idMover_Binary *>( e );
		out( "BINARY state=%d pos1=%s pos2=%s duration=%d accel=%d decel=%d enabled=%d wait=%08X start=%d blocked=%d master=%d chain=%d", (int)m->moverState, vecs( m->pos1 ).c_str(), vecs( m->pos2 ).c_str(), m->duration,
			m->accelTime, m->decelTime, m->enabled ? 1 : 0, fb( m->wait ), m->stateStartTime, m->blocked ? 1 : 0, m->moveMaster ? m->moveMaster->entityNumber : -1, m->activateChain ? m->activateChain->entityNumber : -1 );
	}
	if ( e->IsType( idMover::Type ) ) {
		idMover *m = static_cast<idMover *>( e );
		out( "MOVE stage=%d accel=%d movetime=%d decel=%d dir=%s dest=%s speed=%08X time=%d acceltime=%d deceltime=%d last=%d thread=%d", (int)m->move.stage, m->move.acceleration, m->move.movetime, m->move.deceleration,
			vecs( m->move.dir ).c_str(), vecs( m->dest_position ).c_str(), fb( m->move_speed ), m->move_time, m->acceltime, m->deceltime, (int)m->lastCommand, m->move_thread );
	}
}
static std::string angs( const idAngles &a ) { char b[64]; sprintf( b, "%08X %08X %08X", fb( a.pitch ), fb( a.yaw ), fb( a.roll ) ); return b; }
static std::string mats( const idMat3 &m ) {
	std::string s;
	for ( int i = 0; i < 3; i++ ) { if ( i ) s += " "; s += vecs( m[i] ); }
	return s;
}
static int entNum( const idEntity *e ) { return e ? e->entityNumber : -1; }
// the binding and the team of an entity, its physics and its visual position
static void dumpBind( idEntity *e ) {
	out( "BIND %d bindMaster=%d joint=%d body=%d oriented=%d teamMaster=%d teamChain=%d think=%d origin=%s axis=%s render=%s %s", e->entityNumber, entNum( e->bindMaster ), (int)e->bindJoint, e->bindBody,
		e->fl.bindOrientated ? 1 : 0, entNum( e->teamMaster ), entNum( e->teamChain ), e->thinkFlags, vecs( e->GetPhysics()->GetOrigin() ).c_str(), mats( e->GetPhysics()->GetAxis() ).c_str(),
		vecs( e->renderEntity.origin ).c_str(), mats( e->renderEntity.axis ).c_str() );
}
// the angular state of a parametric physics
static void dumpRot( idEntity *e ) {
	idPhysics *p = e->GetPhysics();
	if ( !p->IsParametric() ) { out( "ROT %d static axis=%s", e->entityNumber, mats( p->GetAxis() ).c_str() ); return; }
	idPhysics_Parametric *pp = static_cast<idPhysics_Parametric *>( p );
	idAngles local, world;
	pp->GetLocalAngles( local ); pp->GetAngles( world );
	// the world angles are idMat3::ToAngles of the axis (atan2 and asin of the C runtime: a few ULP from the x87 of Delphi, tested with a
	// tolerance in the unit tests): only whether they are the local angles to 1/1000 degree is written
	idAngles d = world - local; d.Normalize180();
	bool same = idMath::Fabs( d.pitch ) < 0.001f && idMath::Fabs( d.yaw ) < 0.001f && idMath::Fabs( d.roll ) < 0.001f;
	out( "ROT %d local=%s anglesSame=%d axis=%s type=%d end=%d", e->entityNumber, angs( local ).c_str(), same ? 1 : 0, mats( p->GetAxis() ).c_str(), (int)pp->GetAngularExtrapolationType(), pp->GetAngularEndTime() );
}
// the local angles and the axis in ten thousandths: after SetAxis the local angles come from idMat3::ToAngles, whose atan2 and asin (float
// overloads of the C runtime) are not the x87 ones of Delphi in the last bit
static int q4( float v ) { return (int)floor( v * 10000.0f + 0.5f ); }
static void dumpRotQ( idEntity *e ) {
	idPhysics *p = e->GetPhysics();
	if ( !p->IsParametric() ) { out( "ROTQ %d static", e->entityNumber ); return; }
	idAngles local; static_cast<idPhysics_Parametric *>( p )->GetLocalAngles( local );
	const idMat3 &a = p->GetAxis();
	out( "ROTQ %d local=%d %d %d axis=%d %d %d %d %d %d %d %d %d", e->entityNumber, q4( local.pitch ), q4( local.yaw ), q4( local.roll ),
		q4( a[0][0] ), q4( a[0][1] ), q4( a[0][2] ), q4( a[1][0] ), q4( a[1][1] ), q4( a[1][2] ), q4( a[2][0] ), q4( a[2][1] ), q4( a[2][2] ) );
}
static void dumpQueue() {
	std::string s;
	for ( idEvent *e = EventQueue.Next(); e != NULL; e = e->eventNode.Next() ) {
		char t[64]; sprintf( t, " %s@%d", e->eventdef->GetName(), e->time ); s += t;
	}
	outs( "QUEUE", s );
}
static void dumpFrame() {
	std::string s;
	for ( idEntity *e = gameLocal.spawnedEntities.Next(); e != NULL; e = e->spawnNode.Next() ) {
		if ( e->IsType( idMover_Binary::Type ) ) { char t[96]; sprintf( t, " %d:%d:%s", e->entityNumber, (int)static_cast<idMover_Binary *>( e )->moverState, vecs( e->GetPhysics()->GetOrigin() ).c_str() ); s += t; }
		else if ( e->IsType( idMover::Type ) ) { char t[96]; sprintf( t, " %d:m:%s", e->entityNumber, vecs( e->GetPhysics()->GetOrigin() ).c_str() ); s += t; }
	}
	out( "FRAME t=%d toDeactivate=%d%s", gameLocal.time, gameLocal.numEntitiesToDeactivate, s.c_str() );
}
// the arguments of a command: by the format of the event
static void argsFor( const idEventDef *ev, size_t from, idEventArg *args, idVec3 *vecsStore, std::string *strs ) {
	const char *f = ev->GetArgFormat();
	for ( int i = 0; i < ev->GetNumArgs(); i++ ) {
		std::string w = from + i < g_words.size() ? g_words[from + i] : "0";
		switch ( f[i] ) {
		case 'e': { int n = atoi( w.c_str() ); args[i] = idEventArg( n >= 0 ? (const idEntity *)gameLocal.entities[n] : (const idEntity *)NULL ); break; }
		case 'd': args[i] = idEventArg( atoi( w.c_str() ) ); break;
		case 'f': args[i] = idEventArg( (float)atof( w.c_str() ) ); break;
		case 'v': { float a = 0, b = 0, c = 0; sscanf( w.c_str(), "%f,%f,%f", &a, &b, &c ); vecsStore[i].Set( a, b, c ); args[i] = idEventArg( vecsStore[i] ); break; }
		case 's': strs[i] = w; args[i] = idEventArg( strs[i].c_str() ); break;
		default: args[i] = idEventArg( (const trace_s *)NULL ); break;
		}
	}
}
static void callEvent( idEntity *o, const idEventDef *ev, size_t from, int time, bool post ) {
	idEventArg args[8]; idVec3 vs[8]; std::string ss[8];
	argsFor( ev, from, args, vs, ss );
	bool r = false;
	switch ( ev->GetNumArgs() ) {
	case 0: r = post ? o->PostEventMS( ev, time ) : o->ProcessEvent( ev ); break;
	case 1: r = post ? o->PostEventMS( ev, time, args[0] ) : o->ProcessEvent( ev, args[0] ); break;
	case 2: r = post ? o->PostEventMS( ev, time, args[0], args[1] ) : o->ProcessEvent( ev, args[0], args[1] ); break;
	default: break;
	}
	out( "%s %d", post ? "POSTED" : "PROCESSED", r ? 1 : 0 );
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
	if ( cmd == "def" ) {
		idDeclEntityDef *d = new idDeclEntityDef; d->name = w[0].c_str(); d->index = (int)g_declManager.defs.size(); fillDict( d->dict, 1 ); g_declManager.defs.push_back( d );
	}
	else if ( cmd == "func" ) { function_t *f = new function_t; f->name = w[0]; gameLocal.program.functions.push_back( f ); }
	else if ( cmd == "spawn" ) {
		idDict args; fillDict( args, 0 ); idEntity *ent = NULL;
		bool r = gameLocal.SpawnEntityDef( args, &ent );
		out( "RET %d ent=%d", r ? 1 : 0, ent ? ent->entityNumber : -1 );
	}
	else if ( cmd == "frame" ) {
		int n = w.empty() ? 1 : atoi( w[0].c_str() );
		for ( int i = 0; i < n; i++ ) { gameLocal.RunFrameThink(); idEvent::ServiceEvents(); dumpFrame(); }
	}
	else if ( cmd == "event" || cmd == "post" ) {
		bool post = cmd == "post";
		idEntity *e = entityAt( w[0] ); const idEventDef *ev = idEventDef::FindEvent( w[post ? 2 : 1].c_str() );
		if ( !e || !ev ) { out( "NOTFOUND" ); return; }
		callEvent( e, ev, post ? 3 : 2, post ? atoi( w[1].c_str() ) : 0, post );
	}
	else if ( cmd == "touch" ) {
		idEntity *e = entityAt( w[0] ), *o = entityAt( w[1] );
		if ( !e || !o ) { out( "NOTFOUND" ); return; }
		bool r = e->ProcessEvent( &EV_Touch, o, (const trace_s *)NULL ); out( "PROCESSED %d", r ? 1 : 0 );
	}
	else if ( cmd == "thread" ) g_currentThread = atoi( w[0].c_str() );
	else if ( cmd == "dump" ) { idEntity *e = entityAt( w[0] ); if ( e ) dumpEntity( e ); else out( "NOTFOUND" ); }
	else if ( cmd == "queue" ) dumpQueue();
	else if ( cmd == "startup" ) gameLocal.gamestate = atoi( w[0].c_str() ) ? GAMESTATE_STARTUP : GAMESTATE_ACTIVE;
	else if ( cmd == "remove" ) { idEntity *e = entityAt( w[0] ); if ( e ) { delete e; out( "REMOVED %s", w[0].c_str() ); } else out( "NOTFOUND" ); }
	else if ( cmd == "find" ) { idEntity *e = gameLocal.FindEntity( w.empty() ? "" : w[0].c_str() ); out( "FOUND %d", e ? e->entityNumber : -1 ); }
	else if ( cmd == "bind" ) { idEntity *e = entityAt( w[0] ), *m = entityAt( w[1] ); if ( !e ) { out( "NOTFOUND" ); return; } e->Bind( m, w.size() < 3 || atoi( w[2].c_str() ) != 0 ); out( "BOUND" ); }
	else if ( cmd == "unbind" ) { idEntity *e = entityAt( w[0] ); if ( !e ) { out( "NOTFOUND" ); return; } e->Unbind(); out( "UNBOUND" ); }
	else if ( cmd == "removebinds" ) { idEntity *e = entityAt( w[0] ); if ( !e ) { out( "NOTFOUND" ); return; } e->RemoveBinds(); out( "BINDSREMOVED" ); }
	else if ( cmd == "bindstate" ) { idEntity *e = entityAt( w[0] ); if ( e ) dumpBind( e ); else out( "NOTFOUND" ); }
	else if ( cmd == "rot" ) { idEntity *e = entityAt( w[0] ); if ( e ) dumpRot( e ); else out( "NOTFOUND" ); }
	else if ( cmd == "give" ) { idEntity *e = entityAt( w[0] ); if ( !e || !e->IsType( idPlayer::Type ) ) { out( "NOTFOUND" ); return; } idDict *d = new idDict; d->Set( "inv_name", w[1].c_str() ); static_cast<idPlayer *>( e )->items.push_back( d ); out( "GIVEN" ); }
	else if ( cmd == "spectate" ) { idEntity *e = entityAt( w[0] ); if ( !e || !e->IsType( idPlayer::Type ) ) { out( "NOTFOUND" ); return; } static_cast<idPlayer *>( e )->spectating = atoi( w[1].c_str() ) != 0; out( "SPECTATING" ); }
	else if ( cmd == "viewangles" ) { idEntity *e = entityAt( w[0] ); float a = 0, b = 0, c = 0; if ( !e || !e->IsType( idPlayer::Type ) ) { out( "NOTFOUND" ); return; } sscanf( w[1].c_str(), "%f,%f,%f", &a, &b, &c ); static_cast<idPlayer *>( e )->viewAngles = idAngles( a, b, c ); out( "VIEWANGLES" ); }
	else if ( cmd == "items" ) { idEntity *e = entityAt( w[0] ); if ( !e || !e->IsType( idPlayer::Type ) ) { out( "NOTFOUND" ); return; } idPlayer *p = static_cast<idPlayer *>( e ); std::string s; for ( size_t i = 0; i < p->items.size(); i++ ) { s += " "; s += p->items[i]->GetString( "inv_name" ); } outs( "ITEMS", s ); }
	else if ( cmd == "rotq" ) { idEntity *e = entityAt( w[0] ); if ( e ) dumpRotQ( e ); else out( "NOTFOUND" ); }
	else if ( cmd == "setorigin" ) { idEntity *e = entityAt( w[0] ); float a = 0, b = 0, c = 0; if ( !e ) { out( "NOTFOUND" ); return; } sscanf( w[1].c_str(), "%f,%f,%f", &a, &b, &c ); e->SetOrigin( idVec3( a, b, c ) ); out( "ORIGINSET" ); }
	else if ( cmd == "setangles" ) { idEntity *e = entityAt( w[0] ); float a = 0, b = 0, c = 0; if ( !e ) { out( "NOTFOUND" ); return; } sscanf( w[1].c_str(), "%f,%f,%f", &a, &b, &c ); e->SetAngles( idAngles( a, b, c ) ); out( "ANGLESSET" ); }
	else if ( cmd == "world" ) { out( "WORLD %d", entNum( gameLocal.world ) ); }
	else out( "UNKNOWN %s", cmd.c_str() );
}

int main( int argc, char **argv ) {
	if ( argc < 3 ) { fprintf( stderr, "usage: harness_world <scenario> <golden>\n" ); return 2; }
	g_golden = fopen( argv[2], "wb" );
	FILE *scn = fopen( argv[1], "rb" );
	if ( !scn || !g_golden ) { fprintf( stderr, "cannot open files\n" ); return 2; }
	// the tables of idMath (the square root of idVec3::Length is a table seeded Newton iteration)
	idMath::Init();
	g_quiet = true;
	idClass::Init();
	idEvent::Init();
	idEvent::initialized = true;
	g_quiet = false;
	memset( gameLocal.entities, 0, sizeof( gameLocal.entities ) );
	memset( gameLocal.spawnIds, -1, sizeof( gameLocal.spawnIds ) );
	gameLocal.firstFreeIndex = 0; gameLocal.num_entities = 0; gameLocal.numEntitiesToDeactivate = 0;
	gameLocal.sortPushers = false; gameLocal.sortTeamMasters = false; gameLocal.editEntities = NULL; gameLocal.world = NULL; gameLocal.entityHash.Clear( 1024, MAX_GENTITIES );
	gameLocal.inCinematic = false; gameLocal.framenum = 0; gameLocal.previousTime = 0; gameLocal.time = 0; gameLocal.msec = 16; gameLocal.isMultiplayer = false; gameLocal.isClient = false;
	gameLocal.spawnCount = idGameLocal::INITIAL_SPAWN_COUNT; gameLocal.mapSpawnCount = 0;
	gameLocal.spawnedEntities.Clear(); gameLocal.activeEntities.Clear();
	gameLocal.random.SetSeed( 0 );
	gameLocal.NewMap();
	gameLocal.gamestate = GAMESTATE_ACTIVE;
	char line[8192];
	while ( fgets( line, sizeof( line ), scn ) ) {
		std::string l = line;
		while ( !l.empty() && ( l[l.size() - 1] == '\n' || l[l.size() - 1] == '\r' ) ) l.erase( l.size() - 1 );
		if ( l.empty() || l[0] == '#' ) continue;
		outs( "CMD", l );
		size_t sp = l.find( ' ' );
		std::string cmd = l.substr( 0, sp ), rest = sp == std::string::npos ? "" : l.substr( sp + 1 );
		if ( setjmp( g_errJmp ) == 0 ) { try { runCommand( cmd, rest ); } catch ( idException &e ) { outs( "THROW", e.error ); } }
		else outs( "THROW", g_errText );
	}
	fclose( scn ); fclose( g_golden );
	return 0;
}
