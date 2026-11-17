// Issue #255 (Doom 3, phases 2a-2c: keys, edit field, usercmd, console, idCommon life cycle): stub of
// idlib/precompiled.h for the second parity harness. Written for this repository. It declares what the REAL
// framework\KeyInput.cpp, EditField.cpp, UsercmdGen.cpp and the REAL bodies of Console.cpp and Common.cpp (life cycle)
// need from the rest of the engine as fakes that the driver (harness_host.cpp) implements and traces, and then includes
// the real idlib headers of the scratch copy. The first four virtual functions of idCommon have the same layout as in
// precompiled.h (the idlib objects are shared by the two harnesses). See Build-Harness-Host.ps1.
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

// ---- the engine interfaces that the real code calls: fakes, traced by the driver ----
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
typedef void (*cmdFunction_t)( const idCmdArgs &args );
#define CMD_FL_SYSTEM 2

class idCVar {
public:
	idCVar( const char *name, const char *value, int flags, const char *description, float valueMin = 1, float valueMax = -1, argCompletion_t valueCompletion = 0 );
	const char *GetName() const { return n.c_str(); }
	int GetInteger() const { return atoi( v.c_str() ); }
	float GetFloat() const { return (float)atof( v.c_str() ); }
	bool GetBool() const { return atoi( v.c_str() ) != 0; }
	const char *GetString() const { return v.c_str(); }
	void SetString( const char *s ) { v = s; modified = true; }
	void SetBool( bool b ) { v = b ? "1" : "0"; modified = true; }
	void SetInteger( int i ) { char t[32]; sprintf( t, "%d", i ); v = t; modified = true; }
	bool IsModified() const { return modified; }
	void ClearModified() { modified = false; }
	static void RegisterStaticVars();
	std::string n, v; bool modified;
};
class idCVarSystem {
public:
	void Init(); void Shutdown(); bool IsInitialized() const;
	int GetCVarInteger( const char *name ) const;
	bool GetCVarBool( const char *name ) const;
	const char *GetCVarString( const char *name ) const;
	void SetCVarString( const char *name, const char *value, int flags = 0 );
	void SetCVarBool( const char *name, const bool value, int flags = 0 );
	void SetCVarInteger( const char *name, const int value, int flags = 0 );
	void CommandCompletion( void(*callback)( const char *s ) );
	void ArgCompletion( const char *cmdString, void(*callback)( const char *s ) );
	void SetModifiedFlags( int flags );
	int GetModifiedFlags() const;
	void ClearModifiedFlags( int flags );
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

typedef enum { CMD_EXEC_NOW, CMD_EXEC_INSERT, CMD_EXEC_APPEND } cmdExecution_t;
class idCmdSystem {
public:
	void Init(); void Shutdown();
	void AddCommand( const char *cmdName, cmdFunction_t function, int flags, const char *description, argCompletion_t argCompletion = NULL );
	void RemoveCommand( const char *cmdName );
	void BufferCommandText( cmdExecution_t exec, const char *text );
	void ExecuteCommandBuffer();
	void CommandCompletion( void(*callback)( const char *s ) );
	void ArgCompletion( const char *cmdString, void(*callback)( const char *s ) );
	template<int min, int max> static void ArgCompletion_Integer( const idCmdArgs &args, void(*callback)( const char *s ) ) {}
};
extern idCmdSystem *cmdSystem;

#include "../hostfw/sys_enums.h"
#include "../hostfw/UsercmdGen.h"
class idMaterial;
#include "../hostfw/KeyInput.h"
#include "../hostfw/EditField.h"
#include "../hostfw/Console.h"

int Sys_Milliseconds( void );
sysEvent_t Sys_GetEvent( void );
void Sys_Printf( const char *fmt, ... );
void Sys_DebugPrintf( const char *fmt, ... );
void Sys_Quit( void );
void Sys_Error( const char *error, ... );
void Sys_Init( void ); void Sys_InitNetworking( void ); bool Sys_AlreadyRunning( void ); void Sys_Shutdown( void );
void Sys_DoPreferences( void ); void Sys_GenerateEvents( void );
void Sys_EnterCriticalSection( int index = 0 ); void Sys_LeaveCriticalSection( int index = 0 );
bool Sys_FPU_StackIsEmpty( void ); const char *Sys_FPU_GetState( void );
int Sys_GetConsoleKey( bool shifted );
void Sys_GrabMouseCursor( bool grabIt );
char *Sys_GetClipboardData( void );
unsigned char Sys_MapCharForKey( int key );
int Sys_PollKeyboardInputEvents( void ); int Sys_ReturnKeyboardInputEvent( const int n, int &ch, bool &state ); void Sys_EndKeyboardInputEvents( void );
int Sys_PollMouseInputEvents( void ); int Sys_ReturnMouseInputEvent( const int n, int &action, int &value ); void Sys_EndMouseInputEvents( void );

// a file: written text, or bytes
class idFile {
public:
	std::string name; std::string data; size_t pos; bool writing;
	idFile() : pos(0), writing(false) {}
	int Write( const void *buffer, int len ); int Read( void *buffer, int len ); void Flush(); void ForceFlush();
	int Length() { return (int)data.size(); } long Timestamp() { return 0; } const char *GetFullPath() { return name.c_str(); }
	int Printf( const char *fmt, ... );
};
class idFileSystem {
public:
	void Init(); void Shutdown( bool reloading );
	idFile *OpenFileWrite( const char *relativePath, const char *basePath = "fs_savepath" );
	idFile *OpenExplicitFileRead( const char *OSPath );
	const char *RelativePathToOSPath( const char *relativePath, const char *basePath = "fs_devpath" );
	void CloseFile( idFile *f );
};
extern idFileSystem *fileSystem;

class idEventLoop { public: void Init(); void Shutdown(); int RunEventLoop( bool commandExecution = true ); int Milliseconds(); };
extern idEventLoop *eventLoop;
class idSessionFake {
public:
	void Init(); void Shutdown(); void Stop(); void UpdateScreen( bool outOfSequence = true ); void StartMenu( bool playIntro = false );
	void Frame(); void GuiFrameEvents(); void WriteCDKey();
};
extern idSessionFake *session;
class idRenderSystemFake { public: void Init(); void Shutdown(); void GetCardCaps( bool &oldCard, bool &nv10or20 ); };
extern idRenderSystemFake *renderSystem;
class idSoundWorld { public: void StopAllSounds(); };
class idSoundSystemFake {
public:
	void Init(); void Shutdown(); void ClearBuffer(); idSoundWorld *GetPlayingSoundWorld();
	void AsyncUpdate( int inTime ); void AsyncUpdateWrite( int inTime );
};
extern idSoundSystemFake *soundSystem;
class idDeclManagerFake { public: void Init(); void Shutdown(); };
extern idDeclManagerFake *declManager;
class idUIManagerFake { public: void Init(); void Shutdown(); };
extern idUIManagerFake *uiManager;
class idAsyncServerFake { public: void Kill(); void InitPort(); };
class idAsyncClientFake { public: void Shutdown(); };
class idAsyncNetwork {
public:
	static void Init(); static void Shutdown(); static void RunFrame(); static bool IsActive();
	static idCVar serverDedicated;
	static idAsyncServerFake server; static idAsyncClientFake client;
};
class idSIMDFake { public: static void InitProcessor( const char *module, bool forceGeneric ); };
void Mem_EnableLeakTest( const char *name );
void Com_ExecMachineSpec_f( const idCmdArgs &args );
extern int com_editors;
struct versionFake { char string[256]; };
extern versionFake version;

#define GAME_NAME "DOOM 3"
#define CONFIG_SPEC "config.spec"
#define CONFIG_FILE "DoomConfig.cfg"
#endif
