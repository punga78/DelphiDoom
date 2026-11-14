// Issue #110 (id Tech 4 script): stub of idlib/precompiled.h for the parity harness. Written for this repository:
// it only declares what the REAL idlib and game/script sources of Doom 3 need from the engine (common, sys, file
// system) and then includes the real idlib headers of the scratch copy. See Build-Harness.ps1.
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
#include <string>
#include <map>
#include <vector>

// the driver prints the private state of the program, of the interpreter and of the threads
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
// x86: every event argument is passed as an int (Class.cpp, no Callbacks.cpp)
#define CPU_EASYARGS 1
typedef unsigned char byte; typedef unsigned short word; typedef unsigned int dword; typedef unsigned int uint; typedef unsigned long ulong;
class idVec3; class idVec4; class idFile;
#ifndef BIT
#define BIT(num) (1<<(num))
#endif
class idException { public: char error[MAX_STRING_CHARS]; idException(const char*t=""){strncpy(error,t,MAX_STRING_CHARS-1);error[MAX_STRING_CHARS-1]=0;} };
template<class T> ID_INLINE T Max(T x,T y){return (x>y)?x:y;}
template<class T> ID_INLINE T Min(T x,T y){return (x<y)?x:y;}

// common->Error and gameLocal.Error throw this; the driver catches it and prints "ERROR <text>"
struct harnessError { char text[4096]; };

class idCommon {
public:
	void Printf(const char*,...); void DPrintf(const char*,...); void Warning(const char*,...); void DWarning(const char*,...);
	void Error(const char*,...); void FatalError(const char*,...);
};
class idSys {
public:
	const char* GetCallStackCurStr(int){return "";} void LockMemory(void*,int){} void UnlockMemory(void*,int){}
	// idTimer: the compile time is never printed as a number (see the Printf of the driver)
	double GetClockTicks(){return 0.0;} double ClockTicksPerSecond(){return 1000.0;}
};
class idFileSystem;
class idLib { public: static idSys* sys; static idCommon* common; static idFileSystem* fileSystem; static void Error(const char*fmt,...); static void Warning(const char*fmt,...); };
typedef int cpuid_t; enum { CPUID_NONE=0, CPUID_GENERIC=0 };
#define MAX_WORLD_COORD (128*1024)
#define PATHSEPERATOR_STR "\\"
#define STRTABLE_ID "#str_"
#define STRTABLE_ID_LENGTH 5
inline int LittleLong(int l) { return l; }
extern idCommon* common;
extern idSys* sys;
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

// ---- files: a file read from the fake root, or a memory buffer that the driver prints when it is closed ----
typedef enum { FS_READ = 0, FS_WRITE = 1, FS_APPEND = 2 } fsMode_t;
class idFile {
public:
	std::string rd; size_t pos; std::string name; std::string full; std::string out; bool writing;
	idFile() : pos(0), writing(false) {}
	int Length() { return (int)rd.size(); }
	int Read(void *b, int l) { if (pos + l > rd.size()) l = (int)(rd.size() - pos); memcpy(b, rd.data() + pos, l); pos += l; return l; }
	int Write(const void *b, int l) { out.append((const char *)b, l); return l; }
	const char *GetFullPath() { return full.c_str(); }
	long Timestamp() { return 0; }
	int Printf(const char *fmt, ...) { char buf[8192]; va_list ap; va_start(ap, fmt); vsprintf(buf, fmt, ap); va_end(ap); out.append(buf); return 0; }
	int WriteFloatString(const char *fmt, ...) { char buf[8192]; va_list ap; va_start(ap, fmt); vsprintf(buf, fmt, ap); va_end(ap); out.append(buf); return 0; }
};
// The fake file system: a relative path R is the file <root>/R; its OS path is "/base/" + R (documented in
// main.cpp). OpenFileRead does not accept an OS path, like the real one.
class idFileSystem {
public:
	idFile *OpenFileRead(const char *n);
	idFile *OpenExplicitFileRead(const char *n);
	idFile *OpenFileWrite(const char *n);
	idFile *OpenFileByMode(const char *n, fsMode_t mode);
	void CloseFile(idFile *f);
	int ReadFile(const char *n, void **b, ID_TIME_T *t = 0);
	void FreeFile(void *b);
	const char *RelativePathToOSPath(const char *rel);
	const char *OSPathToRelativePath(const char *os);
};
extern idFileSystem *fileSystem;
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
#endif
