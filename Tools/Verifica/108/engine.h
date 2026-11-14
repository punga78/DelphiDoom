// Engine stubs for the Doom 3 collision harness (issue #108): the pieces of the Doom 3 engine that neo\cm and
// idlib\MapFile talk to. The values of the content and surface flags are those of renderer\Material.h.
#ifndef __HARNESS_ENGINE_H__
#define __HARNESS_ENGINE_H__

#define PROC_FILE_EXT "proc"
#define PROC_FILE_ID "mapProcFile003"
class idRenderWorld { public: void DebugArrow( const idVec4 &, const idVec3 &, const idVec3 &, int, int = 0 ) {} };
class idSession { public: idSession() : rw( NULL ) {} idRenderWorld *rw; };
extern idSession *session;
typedef enum { FS_READ = 0, FS_WRITE = 1, FS_APPEND = 2 } fsMode_t;
typedef enum { CT_FRONT_SIDED, CT_BACK_SIDED, CT_TWO_SIDED } cullType_t;

enum {
	CONTENTS_SOLID = BIT(0), CONTENTS_OPAQUE = BIT(1), CONTENTS_WATER = BIT(2), CONTENTS_PLAYERCLIP = BIT(3),
	CONTENTS_MONSTERCLIP = BIT(4), CONTENTS_MOVEABLECLIP = BIT(5), CONTENTS_IKCLIP = BIT(6), CONTENTS_BLOOD = BIT(7),
	CONTENTS_BODY = BIT(8), CONTENTS_PROJECTILE = BIT(9), CONTENTS_CORPSE = BIT(10), CONTENTS_RENDERMODEL = BIT(11),
	CONTENTS_TRIGGER = BIT(12), CONTENTS_AAS_SOLID = BIT(13), CONTENTS_AAS_OBSTACLE = BIT(14),
	CONTENTS_FLASHLIGHT_TRIGGER = BIT(15), CONTENTS_AREAPORTAL = BIT(20), CONTENTS_NOCSG = BIT(21),
	CONTENTS_REMOVE_UTIL = ~(CONTENTS_AREAPORTAL | CONTENTS_NOCSG)
};
enum { SURF_COLLISION = BIT(6) };

// the material as the collision code sees it
class idMaterial {
public:
	idMaterial( const char *n, int c, cullType_t ct, bool back ) : name( n ), contents( c ), cull( ct ), backSides( back ) {}
	const char *		GetName( void ) const { return name.c_str(); }
	int					GetContentFlags( void ) const { return contents; }
	int					GetSurfaceFlags( void ) const { return 0; }
	cullType_t			GetCullType( void ) const { return cull; }
	bool				ShouldCreateBackSides( void ) const { return backSides; }
private:
	idStr				name;
	int					contents;
	cullType_t			cull;
	bool				backSides;
};

class idDeclManager {
public:
	// a fixed table of materials, the same one the Delphi tests use
	const idMaterial *	FindMaterial( const char *name, bool makeDefault = true );
};

// render models (only the ASE/LWO loader of the collision code uses them: not supported)
struct srfTriangles_s { int numVerts; int numIndexes; idDrawVert *verts; int *indexes; };
typedef struct srfTriangles_s srfTriangles_t;
struct modelSurface_s { int id; const idMaterial *shader; srfTriangles_t *geometry; };
typedef struct modelSurface_s modelSurface_t;
class idRenderModel {
public:
	int					NumSurfaces( void ) const { return 0; }
	const modelSurface_t *Surface( int ) const { return NULL; }
	idBounds			Bounds( const void * ) const { return idBounds(); }
};
class idRenderModelManager {
public:
	bool				CheckModel( const char * ) { return false; }
	idRenderModel *		FindModel( const char * ) { return NULL; }
};

// the file system: plain disk files
class idFileSystem {
public:
	idFile *			OpenFileRead( const char *relativePath, bool allowCopyFiles = true, const char *gamedir = NULL );
	idFile *			OpenFileWrite( const char *relativePath, const char *basePath = "fs_savepath" );
	idFile *			OpenExplicitFileRead( const char *OSPath );
	idFile *			OpenExplicitFileWrite( const char *OSPath );
	void				CloseFile( idFile *f );
	int					ReadFile( const char *relativePath, void **buffer, ID_TIME_T *timestamp = NULL );
	void				FreeFile( void *buffer );
	void				AddToReadCount( int ) {}
};

extern idCommon *			common;
extern idSys *				sys;
extern idFileSystem *		fileSystem;
extern idDeclManager *		declManager;
extern idRenderModelManager *renderModelManager;
extern idCVar				cm_debugCollision;
ID_TIME_T Sys_FileTimeStamp( FILE *fp );

#endif
