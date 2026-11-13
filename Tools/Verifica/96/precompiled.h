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
class idSys { public: virtual int GetProcessorId(void) { return 2; } virtual void FPU_SetFTZ(bool) {} virtual void FPU_SetDAZ(bool) {} virtual double GetClockTicks(void) { return 0; } virtual double ClockTicksPerSecond(void) { return 1; } virtual void LockMemory(void*,int){} virtual void UnlockMemory(void*,int){} };
class idCommon { public: virtual void Printf(const char *, ...) {} virtual void Warning(const char *, ...) {} virtual void Error(const char *, ...) {} virtual void FatalError(const char *, ...) {} };
#include "Lib.h"
#endif
