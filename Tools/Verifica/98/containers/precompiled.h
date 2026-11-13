// Minimal stand-in for idlib/precompiled.h of Doom 3, for the parity harness of the containers (issues #97/#98).
// The REAL List.h, StaticList.h and HashTable.h are copied from Reference\doom3 by Build-Containers.ps1 at
// build time (none is in the repository); this header gives them what they include.
#ifndef STUB_PRECOMPILED_H
#define STUB_PRECOMPILED_H

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cassert>

#define ID_INLINE inline

class idMath {
public:
	static bool IsPowerOfTwo(int x) { return (x & (x - 1)) == 0 && x > 0; }
};

// the members of idStr that HashTable.h uses (idStr::Hash as in Str.cpp)
class idStr {
	char *data;
public:
	idStr() : data(strdup("")) {}
	idStr(const char *c) : data(strdup(c)) {}
	idStr(const idStr &o) : data(strdup(o.data)) {}
	idStr &operator=(const idStr &o) { free(data); data = strdup(o.data); return *this; }
	~idStr() { free(data); }
	int Cmp(const char *text) const { return strcmp(data, text); }
	bool operator==(const char *text) const { return strcmp(data, text) == 0; }
	static int Hash(const char *string) {
		int i, hash = 0;
		for (i = 0; *string != '\0'; i++) {
			hash += (*string++) * (i + 119);
		}
		return hash;
	}
};

#endif
