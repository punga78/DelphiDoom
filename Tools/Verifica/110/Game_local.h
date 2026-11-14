// Issue #110 (id Tech 4 script): FAKE Game_local.h for the parity harness. Written for this repository. It declares
// the smallest game that the REAL Script_*.cpp, Event.cpp and Class.cpp of Doom 3 need: gameLocal, cvars, save game
// on a memory buffer, fake entities. Every stub that the scripts can reach prints a "HOST ..." line (main.cpp).
#ifndef __GAME_LOCAL_H__
#define __GAME_LOCAL_H__

#define GENTITYNUM_BITS			12
#define MAX_GENTITIES			( 1 << GENTITYNUM_BITS )
#define ENTITYNUM_NONE			( MAX_GENTITIES - 1 )
#define ENTITYNUM_WORLD			( MAX_GENTITIES - 2 )
#define MAX_CLIENTS				32
#define INITIAL_SPAWN_COUNT		3
#define MAX_GLOBAL_SHADER_PARMS	12
#define USERCMD_HZ				60
#define SCRIPT_DEFAULTDEFS		"script/doom_defs.script"

void gameError( const char *fmt, ... );

// ---- cvars ----
class idCVar {
public:
	idCVar( const char *name, const char *value );
	bool			GetBool( void ) const { return atoi( value.c_str() ) != 0; }
	int				GetInteger( void ) const { return atoi( value.c_str() ); }
	const char *	GetString( void ) const { return value.c_str(); }
	void			SetString( const char *v ) { value = v; }
	std::string		name;
	std::string		value;
	idCVar *		next;
	static idCVar *	list;
};
extern idCVar g_disasm;
extern idCVar g_debugScript;
extern idCVar g_debugTriggers;
extern idCVar developer;

class idCVarSystem {
public:
	void			SetCVarString( const char *name, const char *value, int flags = 0 );
	const char *	GetCVarString( const char *name ) const;
};
extern idCVarSystem *cvarSystem;

typedef enum { CMD_EXEC_NOW, CMD_EXEC_INSERT, CMD_EXEC_APPEND } cmdExecution_t;
class idCmdSystem {
public:
	void			BufferCommandText( cmdExecution_t exec, const char *text );
};
extern idCmdSystem *cmdSystem;

// ---- declarations, renderer, sound ----
class idMaterial { public: const char *GetName( void ) const { return "material"; } };
class idSoundShader {};
class idDeclManager {
public:
	const idMaterial *		FindMaterial( const char *name, bool makeDefault = true );
	const idSoundShader *	FindSound( const char *name, bool makeDefault = true );
};
extern idDeclManager *declManager;

class idRenderWorld {
public:
	void	DebugLine( const idVec4 &color, const idVec3 &start, const idVec3 &end, const int lifetime );
	void	DebugArrow( const idVec4 &color, const idVec3 &start, const idVec3 &end, int size, const int lifetime );
	void	DebugCircle( const idVec4 &color, const idVec3 &origin, const idVec3 &dir, const float radius, const int numSteps, const int lifetime );
	void	DebugBounds( const idVec4 &color, const idBounds &bounds, const idVec3 &org, const int lifetime );
	void	DrawText( const char *text, const idVec3 &origin, float scale, const idVec4 &color, const idMat3 &viewAxis, const int align, const int lifetime );
};
extern idRenderWorld *gameRenderWorld;

class idSoundWorld {
public:
	void	PlayShaderDirectly( const char *name );
};
extern idSoundWorld *gameSoundWorld;

// ---- collision ----
typedef struct contactInfo_s {
	int					type;
	idVec3				point;
	idVec3				normal;
	float				dist;
	int					contents;
	const idMaterial *	material;
	int					modelFeature;
	int					trmFeature;
	int					entityNum;
	int					id;
} contactInfo_t;

typedef struct trace_s {
	float				fraction;
	idVec3				endpos;
	idMat3				endAxis;
	contactInfo_t		c;
} trace_t;

#define CLIPMODEL_ID_TO_JOINT_HANDLE( id )	( ( id ) >= 0 ? -1 : ( -1 - ( id ) ) )

class idEntity;
class idClass;
class idThread;

class idClip {
public:
	bool	TracePoint( trace_t &results, const idVec3 &start, const idVec3 &end, int contentMask, const idEntity *passEntity );
	bool	TraceBounds( trace_t &results, const idVec3 &start, const idVec3 &end, const idBounds &bounds, int contentMask, const idEntity *passEntity );
};

// ---- save games on a memory buffer, with the primitives of the real SaveGame.cpp ----
class idSaveGame {
public:
	std::string	buf;
	void	Write( const void *buffer, int len ) { buf.append( ( const char * )buffer, len ); }
	void	WriteInt( const int value ) { Write( &value, 4 ); }
	void	WriteFloat( const float value ) { Write( &value, 4 ); }
	void	WriteByte( const byte value ) { Write( &value, 1 ); }
	void	WriteBool( const bool value ) { byte b = value ? 1 : 0; Write( &b, 1 ); }
	void	WriteString( const char *string ) { int len = ( int )strlen( string ); WriteInt( len ); Write( string, len ); }
	void	WriteVec3( const idVec3 &vec ) { Write( &vec, 12 ); }
	void	WriteMat3( const idMat3 &mat ) { Write( &mat, 36 ); }
	void	WriteDict( const idDict *dict );
	void	WriteObject( const idClass *obj );
};

class idRestoreGame {
public:
	std::string	buf;
	size_t		pos;
	idRestoreGame() : pos( 0 ) {}
	void	Error( const char *fmt, ... );
	void	Read( void *buffer, int len );
	void	ReadInt( int &value ) { Read( &value, 4 ); }
	void	ReadFloat( float &value ) { Read( &value, 4 ); }
	void	ReadByte( byte &value ) { Read( &value, 1 ); }
	void	ReadBool( bool &value ) { byte b; Read( &b, 1 ); value = ( b != 0 ); }
	void	ReadString( idStr &string );
	void	ReadVec3( idVec3 &vec ) { Read( &vec, 12 ); }
	void	ReadMat3( idMat3 &mat ) { Read( &mat, 36 ); }
	void	ReadDict( idDict *dict );
	void	ReadObject( idClass *&obj );
};

// ---- the real event system, class system and script system ----
#include "gamesys/Event.h"
#include "gamesys/Class.h"
#include "script/Script_Program.h"

typedef enum {
	SIG_TOUCH, SIG_USE, SIG_TRIGGER, SIG_REMOVE, SIG_DAMAGE, SIG_BLOCKED,
	SIG_MOVER_POS1, SIG_MOVER_POS2, SIG_MOVER_1TO2, SIG_MOVER_2TO1,
	NUM_SIGNALS
} signalNum_t;

#include "script/Script_Compiler.h"

// ---- fake entities (main.cpp says which events each class answers and what they print) ----
extern const idEventDef EV_Activate;
extern const idEventDef EV_SetShaderParm;
extern const idEventDef EV_CacheSoundShader;

struct harnessSignal_t { int threadnum; const function_t *function; };

class idEntity : public idClass {
public:
	CLASS_PROTOTYPE( idEntity );
					idEntity();
	virtual			~idEntity();
	const char *	GetName( void ) const { return name.c_str(); }
	void			Signal( signalNum_t signalnum );
	void			SetSignal( signalNum_t signalnum, idThread *thread, const function_t *function );
	void			ClearSignalThread( signalNum_t signalnum, idThread *thread );
	void			TriggerGuis( void );
	idThread *		ConstructScriptObject( void );
	void			DeconstructScriptObject( void );

	int				entityNumber;
	idStr			name;
	idDict			spawnArgs;
	idScriptObject	scriptObject;
	float			value;
	idVec3			origin;
	int				owner;				// entity number + 1, 0 = none
	std::vector<harnessSignal_t>	signals[ NUM_SIGNALS ];

	void			Event_Activate( idEntity *activator );
	void			Event_SetShaderParm( int parmnum, float value );
	void			Event_CacheSoundShader( const char *soundName );
	void			Event_GetName( void );
	void			Event_SetName( const char *newname );
	void			Event_SetValue( float value );
	void			Event_GetValue( void );
	void			Event_SetOrigin( idVec3 &org );
	void			Event_GetOrigin( void );
	void			Event_SetOwner( idEntity *owner );
	void			Event_GetOwner( void );
	void			Event_Bind( idEntity *master );
	void			Event_SetKey( const char *key, const char *value );
	void			Event_GetKey( const char *key );
	void			Event_AddInts( int a, int b );
	void			Event_Mix( float f, int d, idVec3 &v, const char *s, idEntity *e );
	void			Event_HostPing( int value );
};

class idMover : public idEntity {
public:
	CLASS_PROTOTYPE( idMover );
					idMover();
	bool			moving;
	int				move_thread;
	idVec3			dest;
	int				turnLeft;
	void			Event_MoveTo( idVec3 &dest, float time );
	void			Event_MoveDone( void );
	void			Event_IsMoving( void );
	void			Event_SetCallback( void );
	void			Event_SlowTurn( float frames );
};

class idCamera : public idEntity {
public:
	CLASS_PROTOTYPE( idCamera );
};

class idPlayerView {
public:
	void			Fade( idVec4 color, int time );
};

class idPlayer : public idEntity {
public:
	CLASS_PROTOTYPE( idPlayer );
					idPlayer();
	idPlayerView	playerView;
	idAngles		viewAngles;
	int				influenceLevel;
	int				GetInfluenceLevel( void ) { return influenceLevel; }
};

class idAFBody { public: const char *GetName( void ) const { return name.c_str(); } idStr name; };
class idPhysics_AF { public: idAFBody *GetBody( const int id ); idAFBody body; };
class idAnimator { public: const char *GetJointName( int handle ) const; };
class idAFEntity_Base : public idEntity {
public:
	CLASS_PROTOTYPE( idAFEntity_Base );
	bool			IsActiveAF( void ) const { return true; }
	idAnimator *	GetAnimator( void ) { return &animator; }
	int				BodyForClipModelId( int id ) const { return id; }
	idPhysics_AF *	GetAFPhysics( void ) { return &physics; }
	idAnimator		animator;
	idPhysics_AF	physics;
};

// the real idEntityPtr: the spawn id and the entity number in one int
template< class type >
class idEntityPtr {
public:
	idEntityPtr() : spawnId( 0 ) {}
	idEntityPtr<type> &	operator=( type *ent );
	type *				GetEntity( void ) const;
	int					spawnId;
};

typedef enum { GAMESTATE_UNINITIALIZED, GAMESTATE_NOMAP, GAMESTATE_STARTUP, GAMESTATE_ACTIVE, GAMESTATE_SHUTDOWN } gameState_t;

class idGameLocal {
public:
	idEntity *		entities[ MAX_GENTITIES ];
	int				spawnIds[ MAX_GENTITIES ];
	int				spawnCount;
	idProgram		program;
	idRandom		random;
	idClip			clip;
	idDict			persistentLevelInfo;
	float			globalShaderParms[ MAX_GLOBAL_SHADER_PARMS ];
	int				framenum;
	int				time;
	int				msec;
	int				realClientTime;
	bool			isClient;
	bool			isMultiplayer;
	idPlayer *		localPlayer;
	idEntity *		camera;

					idGameLocal();
	void			Printf( const char *fmt, ... ) const;
	void			DPrintf( const char *fmt, ... ) const;
	void			Warning( const char *fmt, ... ) const;
	void			DWarning( const char *fmt, ... ) const;
	void			Error( const char *fmt, ... ) const;
	gameState_t		GameState( void ) const { return GAMESTATE_ACTIVE; }
	idPlayer *		GetLocalPlayer( void ) const { return localPlayer; }
	idEntity *		FindEntity( const char *name ) const;
	bool			SpawnEntityDef( const idDict &args, idEntity **ent = NULL );
	void			SetCamera( idCamera *cam );
	void			RadiusDamage( const idVec3 &origin, idEntity *inflictor, idEntity *attacker, idEntity *ignoreDamage, idEntity *ignorePush, const char *damageDefName, float dmgPower = 1.0f );
};
extern idGameLocal gameLocal;

template< class type >
ID_INLINE idEntityPtr<type> &idEntityPtr<type>::operator=( type *ent ) {
	if ( ent == NULL ) {
		spawnId = 0;
	} else {
		spawnId = ( gameLocal.spawnIds[ ent->entityNumber ] << GENTITYNUM_BITS ) | ent->entityNumber;
	}
	return *this;
}

template< class type >
ID_INLINE type *idEntityPtr<type>::GetEntity( void ) const {
	int entityNum = spawnId & ( ( 1 << GENTITYNUM_BITS ) - 1 );
	if ( ( gameLocal.spawnIds[ entityNum ] == ( spawnId >> GENTITYNUM_BITS ) ) ) {
		return static_cast<type *>( gameLocal.entities[ entityNum ] );
	}
	return NULL;
}

#include "script/Script_Interpreter.h"
#include "script/Script_Thread.h"

#endif
