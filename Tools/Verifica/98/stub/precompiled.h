// Minimal stand-in for idlib/precompiled.h of Doom 3, written for the parity harness of issue #98.
// It declares just enough of idLib (idStr, idVec3, idMath, idDict, idFile, common, idHashIndex) for the
// REAL BitMsg.cpp and Compressor.cpp to compile unchanged. The real sources are copied from
// Reference\doom3 by Build-Harness.ps1 at build time; none of them is in the repository.
#ifndef STUB_PRECOMPILED_H
#define STUB_PRECOMPILED_H

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdarg>
#include <cassert>
#include <cmath>
#include <ctime>
#include <string>
#include <vector>
#include <stdexcept>
#include <algorithm>

typedef unsigned char byte;
typedef unsigned int dword;
#define ID_INLINE inline
#define ID_TIME_T time_t
#define MAX_STRING_CHARS 1024
#define IEEE_FLT_MANTISSA_BITS 23
#define IEEE_FLT_EXPONENT_BITS 8
#define IEEE_FLT_EXPONENT_BIAS 127
#define IEEE_FLT_SIGN_BIT 31
#define INTSIGNBITSET(i) (((const unsigned long)(i)) >> 31)
#define FLOATSIGNBITSET(f) ((*(const unsigned long *)&(f)) >> 31)

template<class T> inline T Max(T a, T b) { return a > b ? a : b; }
template<class T> inline T Min(T a, T b) { return a < b ? a : b; }

class idMath {
public:
	static int FloatToBits(float f, int exponentBits, int mantissaBits);
	static float BitsToFloat(int i, int exponentBits, int mantissaBits);
	static int Ftoi(float f) { return (int)f; }
	// the original uses fistp (round to nearest even), the same as lrintf
	static int FtoiFast(float f) { return (int)lrintf(f); }
	static float Fabs(float f) { return fabsf(f); }
	static bool IsPowerOfTwo(int x) { return (x & (x - 1)) == 0 && x > 0; }
	// copied from Math.h of the original
	static float RSqrt(float x) {
		long i;
		float y, r;
		y = x * 0.5f;
		i = *reinterpret_cast<long *>(&x);
		i = 0x5f3759df - (i >> 1);
		r = *reinterpret_cast<float *>(&i);
		r = r * (1.5f - r * r * y);
		return r;
	}
};

#define ANGLE2SHORT(x) (idMath::FtoiFast((x) * 65536.0f / 360.0f) & 65535)
#define SHORT2ANGLE(x) ((x) * (360.0f / 65536.0f))
#define ANGLE2BYTE(x) (idMath::FtoiFast((x) * 256.0f / 360.0f) & 255)
#define BYTE2ANGLE(x) ((x) * (360.0f / 256.0f))

class idVec3 {
public:
	float x, y, z;
	idVec3() : x(0), y(0), z(0) {}
	idVec3(float X, float Y, float Z) : x(X), y(Y), z(Z) {}
	float operator[](int i) const { return (&x)[i]; }
	float LengthSqr() const { return x * x + y * y + z * z; }
	float NormalizeFast() {
		float lengthSqr, invLength;
		lengthSqr = x * x + y * y + z * z;
		invLength = idMath::RSqrt(lengthSqr);
		x *= invLength;
		y *= invLength;
		z *= invLength;
		return invLength * lengthSqr;
	}
};

class idStr {
	std::string s;
public:
	idStr() {}
	idStr(const char *c) : s(c) {}
	operator const char *() const { return s.c_str(); }
	static int Length(const char *c) { return (int)strlen(c); }
	static int Cmp(const char *a, const char *b) { return strcmp(a, b); }
	static int Icmp(const char *a, const char *b) {
		for (;; a++, b++) {
			int ca = (unsigned char)*a, cb = (unsigned char)*b;
			if (ca >= 'A' && ca <= 'Z') ca += 32;
			if (cb >= 'A' && cb <= 'Z') cb += 32;
			if (ca != cb) return ca < cb ? -1 : 1;
			if (!ca) return 0;
		}
	}
	int Icmp(const char *o) const { return Icmp(s.c_str(), o); }
	static int Hash(const char *) { return 0; }
	static int IHash(const char *) { return 0; }
	static void Copynz(char *dest, const char *src, int destsize) {
		strncpy(dest, src, destsize - 1);
		dest[destsize - 1] = 0;
	}
};

class idKeyValue {
	idStr key, value;
public:
	idKeyValue(const char *k, const char *v) : key(k), value(v) {}
	const idStr &GetKey() const { return key; }
	const idStr &GetValue() const { return value; }
	void SetValue(const char *v) { value = v; }
};

class idDict {
	std::vector<idKeyValue> kv;
public:
	void Clear() { kv.clear(); }
	int GetNumKeyVals() const { return (int)kv.size(); }
	const idKeyValue *GetKeyVal(int i) const { return &kv[i]; }
	const idKeyValue *FindKey(const char *key) const {
		for (size_t i = 0; i < kv.size(); i++)
			if (idStr::Icmp(kv[i].GetKey(), key) == 0) return &kv[i];
		return NULL;
	}
	void Set(const char *key, const char *value) {
		if (!key[0]) return;
		for (size_t i = 0; i < kv.size(); i++)
			if (idStr::Icmp(kv[i].GetKey(), key) == 0) { kv[i].SetValue(value); return; }
		kv.push_back(idKeyValue(key, value));
	}
	void Delete(const char *key) {
		for (size_t i = 0; i < kv.size(); i++)
			if (idStr::Icmp(kv[i].GetKey(), key) == 0) { kv.erase(kv.begin() + i); return; }
	}
};

typedef enum { NA_BAD, NA_LOOPBACK, NA_BROADCAST, NA_IP } netadrtype_t;
typedef struct { netadrtype_t type; unsigned char ip[4]; unsigned short port; } netadr_t;

typedef enum { FS_SEEK_CUR, FS_SEEK_END, FS_SEEK_SET } fsOrigin_t;

class idFile {
public:
	virtual ~idFile() {}
	virtual const char *GetName(void) { return ""; }
	virtual const char *GetFullPath(void) { return ""; }
	virtual int Read(void *buffer, int len) = 0;
	virtual int Write(const void *buffer, int len) = 0;
	virtual int Length(void) = 0;
	virtual ID_TIME_T Timestamp(void) { return 0; }
	virtual int Tell(void) = 0;
	virtual void ForceFlush(void) {}
	virtual void Flush(void) {}
	virtual int Seek(long offset, fsOrigin_t origin) = 0;
};

class idCommon {
public:
	void Printf(const char *, ...) {}
	void Warning(const char *, ...) {}
	void Error(const char *fmt, ...) {
		char buf[512];
		va_list a; va_start(a, fmt); vsnprintf(buf, sizeof(buf), fmt, a); va_end(a);
		throw std::runtime_error(buf);
	}
	void FatalError(const char *fmt, ...) {
		char buf[512];
		va_list a; va_start(a, fmt); vsnprintf(buf, sizeof(buf), fmt, a); va_end(a);
		throw std::runtime_error(buf);
	}
};
extern idCommon *common;
namespace idLib { using ::common; }

#include "containers/HashIndex.h"
#include "BitMsg.h"
#include "../framework/Compressor.h"

#endif
