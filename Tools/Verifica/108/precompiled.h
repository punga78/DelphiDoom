// Stub precompiled.h for the Doom 3 collision harness (issue #108). Only what idlib, framework\File and neo\cm need.
#ifndef __PRECOMPILED_H__
#define __PRECOMPILED_H__
#define NDEBUG
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#include <ctype.h>
#include <errno.h>
#include <math.h>
#include <new>
#define ID_TIME_T time_t
#define ID_INLINE inline
#define ALIGN16(x) x
#define ASSERT assert
#define __cdecl
#define id_attribute(x)
#include <malloc.h>
#define _alloca16(x) ((void *)((((int)_alloca((x)+15))+15)&~15))
#define S_COLOR_RED ""
#define MAX_OSPATH 256
typedef enum { CPUID_NONE = 0, CPUID_GENERIC = 2 } cpuid_t;
class idSys { public: virtual const char *GetCallStackCurStr(int) { return ""; } virtual void DebugPrintf(const char *, ...) {} virtual int GetProcessorId(void) { return 2; } virtual void FPU_SetFTZ(bool) {} virtual void FPU_SetDAZ(bool) {} virtual double GetClockTicks(void) { return 0; } virtual double ClockTicksPerSecond(void) { return 1; } virtual void LockMemory(void*,int){} virtual void UnlockMemory(void*,int){} };
class idCommon { public: virtual void Printf(const char *, ...); virtual void DPrintf(const char *, ...) {} virtual void Warning(const char *, ...); virtual void DWarning(const char *, ...) {} virtual void Error(const char *, ...); virtual void FatalError(const char *, ...); virtual void SetRefreshOnPrint(bool) {} };
class idCVarSystem { public: virtual const char *GetCVarString(const char *) { return ""; } };
class idCVar { public: idCVar(const char *, const char *, int, const char *, float = 0, float = 0) {} bool GetBool(void) const { return false; } int GetInteger(void) const { return 0; } };
#define CVAR_SYSTEM 0
#define CVAR_BOOL 0
#define CVAR_RENDERER 0
#define CVAR_INTEGER 0
typedef struct { int ip; } netadr_t;
#include "Lib.h"
#include "../framework/File.h"
#include "../harness/engine.h"
#endif
