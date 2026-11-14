// Engine stubs for the Doom 3 collision harness (issue #108): the pieces of the engine that the code under
// test calls, as little as it takes to compile and link it unchanged.
#include "../idlib/precompiled.h"
#pragma hdrstop

idCommon		commonImpl;
idSys			sysImpl;
idFileSystem	fileSystemImpl;
idDeclManager	declManagerImpl;
idRenderModelManager renderModelManagerImpl;
idCommon *		common = &commonImpl;
idSys *			sys = &sysImpl;
idFileSystem *	fileSystem = &fileSystemImpl;
idDeclManager *	declManager = &declManagerImpl;
idRenderModelManager *renderModelManager = &renderModelManagerImpl;
idCVar			cm_debugCollision( "cm_debugCollision", "0", 0, "" );
idSIMDProcessor *SIMDProcessor = NULL;
idSession		sessionImpl;
idSession *		session = &sessionImpl;

// messages go to stderr only when the harness asks for them
int harnessVerbose = 0;

void idCommon::Printf( const char *fmt, ... ) {
	if ( harnessVerbose ) { va_list a; va_start( a, fmt ); vfprintf( stderr, fmt, a ); va_end( a ); }
}
void idCommon::Warning( const char *fmt, ... ) {
	va_list a; va_start( a, fmt ); fprintf( stderr, "WARNING: " ); vfprintf( stderr, fmt, a ); fprintf( stderr, "\n" ); va_end( a );
}
void idCommon::Error( const char *fmt, ... ) {
	va_list a; va_start( a, fmt ); fprintf( stderr, "ERROR: " ); vfprintf( stderr, fmt, a ); fprintf( stderr, "\n" ); va_end( a ); exit( 2 );
}
void idCommon::FatalError( const char *fmt, ... ) {
	va_list a; va_start( a, fmt ); fprintf( stderr, "FATAL: " ); vfprintf( stderr, fmt, a ); fprintf( stderr, "\n" ); va_end( a ); exit( 3 );
}

ID_TIME_T Sys_FileTimeStamp( FILE *fp ) { return 0; }

// the materials of the synthetic maps: the name picks the contents and the culling
const idMaterial *idDeclManager::FindMaterial( const char *name, bool makeDefault ) {
	static const idMaterial solid( "textures/solid", CONTENTS_SOLID, CT_FRONT_SIDED, false );
	static const idMaterial clip( "textures/clip", CONTENTS_PLAYERCLIP | CONTENTS_MONSTERCLIP, CT_FRONT_SIDED, false );
	static const idMaterial water( "textures/water", CONTENTS_WATER, CT_FRONT_SIDED, false );
	static const idMaterial glass( "textures/glass", CONTENTS_SOLID | CONTENTS_OPAQUE, CT_TWO_SIDED, false );
	static const idMaterial backs( "textures/backsides", CONTENTS_SOLID, CT_FRONT_SIDED, true );
	static const idMaterial body( "textures/body", CONTENTS_BODY, CT_FRONT_SIDED, false );
	static const idMaterial portal( "textures/areaportal", CONTENTS_AREAPORTAL, CT_FRONT_SIDED, false );
	static const idMaterial nonsolid( "textures/nonsolid", 0, CT_FRONT_SIDED, false );
	static const idMaterial trm( "_tracemodel", CONTENTS_SOLID, CT_FRONT_SIDED, false );
	if ( idStr::Icmp( name, "_tracemodel" ) == 0 ) return &trm;
	if ( idStr::Icmp( name, "textures/solid" ) == 0 ) return &solid;
	if ( idStr::Icmp( name, "textures/clip" ) == 0 ) return &clip;
	if ( idStr::Icmp( name, "textures/water" ) == 0 ) return &water;
	if ( idStr::Icmp( name, "textures/glass" ) == 0 ) return &glass;
	if ( idStr::Icmp( name, "textures/backsides" ) == 0 ) return &backs;
	if ( idStr::Icmp( name, "textures/body" ) == 0 ) return &body;
	if ( idStr::Icmp( name, "textures/areaportal" ) == 0 ) return &portal;
	if ( idStr::Icmp( name, "textures/nonsolid" ) == 0 ) return &nonsolid;
	return &solid;
}

static int FileLength( FILE *f ) {
	int pos = ftell( f );
	fseek( f, 0, SEEK_END );
	int end = ftell( f );
	fseek( f, pos, SEEK_SET );
	return end;
}

idFile *idFileSystem::OpenExplicitFileRead( const char *OSPath ) {
	FILE *fp = fopen( OSPath, "rb" );
	if ( !fp ) return NULL;
	idFile_Permanent *f = new idFile_Permanent();
	f->o = fp;
	f->name = OSPath;
	f->fullPath = OSPath;
	f->mode = ( 1 << FS_READ );
	f->fileSize = FileLength( fp );
	return f;
}
idFile *idFileSystem::OpenExplicitFileWrite( const char *OSPath ) {
	FILE *fp = fopen( OSPath, "wb" );
	if ( !fp ) return NULL;
	idFile_Permanent *f = new idFile_Permanent();
	f->o = fp;
	f->name = OSPath;
	f->fullPath = OSPath;
	f->mode = ( 1 << FS_WRITE );
	f->fileSize = 0;
	return f;
}
idFile *idFileSystem::OpenFileRead( const char *relativePath, bool allowCopyFiles, const char *gamedir ) { return OpenExplicitFileRead( relativePath ); }
idFile *idFileSystem::OpenFileWrite( const char *relativePath, const char *basePath ) { return OpenExplicitFileWrite( relativePath ); }
void idFileSystem::CloseFile( idFile *f ) { delete f; }
int idFileSystem::ReadFile( const char *relativePath, void **buffer, ID_TIME_T *timestamp ) {
	FILE *fp = fopen( relativePath, "rb" );
	if ( !fp ) { if ( buffer ) *buffer = NULL; return -1; }
	int len = FileLength( fp );
	if ( buffer ) {
		char *b = (char *) malloc( len + 1 );
		fread( b, 1, len, fp );
		b[len] = 0;
		*buffer = b;
	}
	if ( timestamp ) *timestamp = 0;
	fclose( fp );
	return len;
}
void idFileSystem::FreeFile( void *buffer ) { free( buffer ); }
