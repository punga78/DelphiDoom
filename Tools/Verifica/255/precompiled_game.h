// Issue #255 (Doom 3, phase 3 "the game without a renderer"): stub of idlib/precompiled.h for the third parity
// harness. Written for this repository. It declares what the REAL game\gamesys\Class.h, Event.h and the REAL bodies
// of game\gamesys\Class.cpp, game\gamesys\Event.cpp (idEventDef), game\Game_local.cpp (entity table, spawning) and
// game\Entity.cpp (names, activity) need from the rest of the engine as fakes that the driver (harness_game.cpp)
// implements and traces, and then includes the real idlib headers of the scratch copy. The idlib objects are the ones
// that Build-Harness.ps1 compiled (same first virtual functions of idCommon). See Build-Harness-Game.ps1.
#ifndef __PRECOMPILED_H__
#define __PRECOMPILED_H__
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>
#include <math.h>
#include <float.h>
#include <malloc.h>
#include <stdint.h>
#include <time.h>
#include <string>
#include <map>
#include <vector>

// the driver prints the private state of the real classes
#define private public
#define protected public

#define ID_INLINE inline
#define id_attribute(x)
#define _alloca16(x) ((void *)((((uintptr_t)_alloca((x)+15)) + 15) & ~(uintptr_t)15))
#define ID_FORCE_INLINE inline
#define ID_TIME_T long
#define ALIGN16(x) x
#define ASSERT_ALIGN16(x)
#define ID_MSVC_INLINE
#define MAX_STRING_CHARS 1024
#define MAX_STRING_LEN 128
#define CPU_EASYARGS 1
typedef unsigned char byte; typedef unsigned short word; typedef unsigned int dword; typedef unsigned int uint; typedef unsigned long ulong;
class idVec3; class idVec4; class idFile;
#ifndef BIT
#define BIT(num) (1<<(num))
#endif
class idException { public: char error[4096]; idException(const char*t=""){strncpy(error,t,4095);error[4095]=0;} };
template<class T> ID_INLINE T Max(T x,T y){return (x>y)?x:y;}
template<class T> ID_INLINE T Min(T x,T y){return (x<y)?x:y;}

class idCommon;
class idSys {
public:
	const char* GetCallStackCurStr(int){return "";} void LockMemory(void*,int){} void UnlockMemory(void*,int){}
	double GetClockTicks(){return 0.0;} double ClockTicksPerSecond(){return 1000.0;}
};
class idFileSystem;
class idCVarSystem;
class idLib {
public:
	static idSys* sys; static idCommon* common; static idFileSystem* fileSystem; static idCVarSystem* cvarSystem;
	static int frameNumber;
	static void Init(); static void ShutDown();
	static void Error(const char*fmt,...); static void Warning(const char*fmt,...);
};
typedef int cpuid_t; enum { CPUID_NONE=0, CPUID_GENERIC=0 };
#define MAX_WORLD_COORD (128*1024)
#define PATHSEPERATOR_STR "\\"
#define STRTABLE_ID "#str_"
#define STRTABLE_ID_LENGTH 5
inline int LittleLong(int l) { return l; }
inline short LittleShort(short l) { return l; }
extern idSys* sys;

class idLangDict { public: const char *GetString( const char *id ) const; void Clear() {} };

class idCommon {
public:
	virtual ~idCommon() {}
	virtual void Printf( const char *fmt, ... ) = 0;
	virtual void DPrintf( const char *fmt, ... ) = 0;
	virtual void Warning( const char *fmt, ... ) = 0;
	virtual void DWarning( const char *fmt, ... ) = 0;
	virtual void Error( const char *fmt, ... ) = 0;
	virtual void FatalError( const char *fmt, ... ) = 0;
	virtual void StartupVariable( const char *match, bool once ) = 0;
	virtual const idLangDict *GetLanguageDict( void ) = 0;
};
extern idCommon* common;

#define CVAR_ALL 0xFFFFFFFF
#define CVAR_BOOL 1
#define CVAR_INTEGER 2
#define CVAR_FLOAT 4
#define CVAR_SYSTEM 8
#define CVAR_INIT 16
#define CVAR_ROM 32
#define CVAR_ARCHIVE 64
#define CVAR_NOCHEAT 128
#define CVAR_SERVERINFO 256
class idCmdArgs;
typedef void (*argCompletion_t)( const idCmdArgs &args, void(*callback)( const char *s ) );

class idCVar {
public:
	idCVar( const char *name, const char *value, int flags, const char *description, float valueMin = 1, float valueMax = -1, argCompletion_t valueCompletion = 0 );
	const char *GetName() const { return n.c_str(); }
	int GetInteger() const { return atoi( v.c_str() ); }
	float GetFloat() const { return (float)atof( v.c_str() ); }
	bool GetBool() const { return atoi( v.c_str() ) != 0; }
	const char *GetString() const { return v.c_str(); }
	void SetString( const char *s ) { v = s; }
	void SetBool( bool b ) { v = b ? "1" : "0"; }
	void SetInteger( int i ) { char t[32]; sprintf( t, "%d", i ); v = t; }
	std::string n, v;
};
class idCVarSystem {
public:
	bool IsInitialized() const;
	int GetCVarInteger( const char *name ) const;
	bool GetCVarBool( const char *name ) const;
	const char *GetCVarString( const char *name ) const;
	void SetCVarString( const char *name, const char *value, int flags = 0 );
	void SetCVarBool( const char *name, const bool value, int flags = 0 );
};
extern idCVarSystem *cvarSystem;

#include "Heap.h"
#include "containers/List.h"
#include "math/Simd.h"
#include "math/Math.h"
#include "math/Random.h"
#include "math/Complex.h"
#include "math/Vector.h"
#include "math/Matrix.h"
#include "math/Angles.h"
#include "math/Quat.h"
#include "math/Rotation.h"
#include "math/Plane.h"
#include "math/Pluecker.h"
#include "math/Polynomial.h"
#include "math/Extrapolate.h"
#include "math/Interpolate.h"
#include "math/Curve.h"
#include "math/Ode.h"
#include "math/Lcp.h"
#include "Str.h"
#include "bv/Sphere.h"
#include "bv/Bounds.h"
struct dominantTri_s { int v2, v3; float normalizationScale[3]; };
#include "geometry/DrawVert.h"
#include "geometry/JointTransform.h"
#include "hashing/CRC32.h"
#include "hashing/MD4.h"
#include "containers/HashIndex.h"
#include "containers/StrList.h"
#include "containers/StrPool.h"
#include "containers/StaticList.h"
#include "containers/LinkList.h"
#include "containers/Hierarchy.h"
#include "Token.h"
#include "Lexer.h"
#include "Parser.h"
#include "CmdArgs.h"
#include "Dict.h"
#include "Timer.h"

// a file (idDict reads and writes through it; the harness never does)
class idFile {
public:
	std::string name; std::string data; size_t pos; bool writing;
	idFile() : pos(0), writing(false) {}
	int Write( const void *buffer, int len );
	int Read( void *buffer, int len );
	void Flush();
	void ForceFlush();
	int Printf( const char *fmt, ... );
	int Length() { return (int)data.size(); }
	long Timestamp() { return 0; }
	const char *GetFullPath() { return name.c_str(); }
};

// the types that the real Event.h and Class.h mention
struct trace_s { int fraction; };
typedef struct trace_s trace_t;
class idEntity;
template< class type > class idEntityPtr { public: int spawnId; };
#include "../gamefw/Event.h"
#include "../gamefw/Class.h"

#endif
