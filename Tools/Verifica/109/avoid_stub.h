// Issue #109: the part of the game that AI_pathing.cpp (obstacle avoidance) needs, as stubs. This text is put in
// precompiled.h of the harness by Build-AvoidHarness.ps1, after AASFile.h, AAS.h and the idlib headers.
// Nothing here is Doom 3 code except obstaclePath_t, copied from AI.h (the lines 111-118).
#include "bv/Box.h"
#include "geometry/Winding2D.h"
#include "containers/Queue.h"

#define MIN_WORLD_COORD ( -128 * 1024 )
#define MAX_GENTITIES		4096
#define CM_BOX_EPSILON		1.0f

class idTypeInfo { public: int dummy; };
class idPhysics;
class idEntity {
public:
	int				health;
	int				number;
	const idTypeInfo *type;
	idPhysics *		phys;
	bool			IsType( const idTypeInfo &t ) const { return type == &t; }
	idPhysics *		GetPhysics( void ) const { return phys; }
};
class idActor { public: static idTypeInfo Type; };
class idMoveable { public: static idTypeInfo Type; };

class idPhysics {
public:
	idBounds		bounds, absBounds;
	idVec3			gravityNormal, linearVelocity, origin;
	int				clipMask;
	const idBounds &GetBounds( void ) const { return bounds; }
	const idBounds &GetAbsBounds( void ) const { return absBounds; }
	const idVec3 &	GetGravityNormal( void ) const { return gravityNormal; }
	const idVec3 &	GetLinearVelocity( void ) const { return linearVelocity; }
	const idVec3 &	GetOrigin( void ) const { return origin; }
	int				GetClipMask( void ) const { return clipMask; }
};

class idClipModel {
public:
	idEntity *		entity;
	idBounds		bounds, absBounds;
	idVec3			origin;
	idMat3			axis;
	bool			IsTraceModel( void ) const { return true; }
	idEntity *		GetEntity( void ) const { return entity; }
	const idBounds &GetBounds( void ) const { return bounds; }
	const idBounds &GetAbsBounds( void ) const { return absBounds; }
	const idVec3 &	GetOrigin( void ) const { return origin; }
	const idMat3 &	GetAxis( void ) const { return axis; }
};

class idClip {
public:
	int				ClipModelsTouchingBounds( const idBounds &bounds, int mask, idClipModel **list, int maxCount );
};

class idGameLocal {
public:
	idClip			clip;
	void			Printf( const char *fmt, ... );
	void			Warning( const char *fmt, ... );
	void			Error( const char *fmt, ... );
};
extern idGameLocal gameLocal;

class idRenderWorld { public: void DebugArrow( const idVec4 &c, const idVec3 &a, const idVec3 &b, int size, int lifetime = 0 ) {} };
extern idRenderWorld *gameRenderWorld;
extern idVec4 colorWhite, colorGreen, colorYellow, colorBlue, colorRed, colorCyan;
extern idCVar ai_showObstacleAvoidance;

typedef struct obstaclePath_s {
	idVec3				seekPos;					// seek position avoiding obstacles
	idEntity *			firstObstacle;				// if != NULL the first obstacle along the path
	idVec3				startPosOutsideObstacles;	// start position outside obstacles
	idEntity *			startPosObstacle;			// if != NULL the obstacle containing the start position
	idVec3				seekPosOutsideObstacles;	// seek position outside obstacles
	idEntity *			seekPosObstacle;			// if != NULL the obstacle containing the seek position
} obstaclePath_t;

class idAI {
public:
	static bool		FindPathAroundObstacles( const idPhysics *physics, const idAAS *aas, const idEntity *ignore, const idVec3 &startPos, const idVec3 &seekPos, obstaclePath_t &path );
	static void		FreeObstacleAvoidanceNodes( void );
};
