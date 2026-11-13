// Parity harness of the containers (issues #97/#98): runs the REAL idList, idStaticList and idHashTable of
// Doom 3 with random series of operations and prints the state after every step. The Delphi tests
// (Tests\Source\DelphiDoom.Tests.IdLib.Containers.ListCases.pas) run the same series and compare line by line.
// Usage: harness <output file>
#include "precompiled.h"
#include <string>
#include <new>

// every allocation is zeroed (new int[n] is uninitialised in C++ and the Delphi arrays start at 0)
void *operator new(size_t n) { void *p = calloc(1, n ? n : 1); if (!p) throw std::bad_alloc(); return p; }
void *operator new[](size_t n) { void *p = calloc(1, n ? n : 1); if (!p) throw std::bad_alloc(); return p; }
void operator delete(void *p) noexcept { free(p); }
void operator delete[](void *p) noexcept { free(p); }
void operator delete(void *p, size_t) noexcept { free(p); }
void operator delete[](void *p, size_t) noexcept { free(p); }

#include "idlib/containers/List.h"
#include "idlib/containers/StaticList.h"
#include "idlib/containers/HashTable.h"

static unsigned gState;
static int Rnd() {
	gState = gState * 1664525u + 1013904223u;
	return (int)(gState >> 16);
}

static FILE *out;

static void DumpList(const char *name, const idList<int> &l) {
	fprintf(out, "  %s %d/%d/%d [", name, l.Num(), l.NumAllocated(), l.GetGranularity());
	for (int i = 0; i < l.Num(); i++) fprintf(out, "%s%d", i ? " " : "", l[i]);
	fprintf(out, "]\n");
}

static void ListScenario(int variant, int granularity) {
	idList<int> a(granularity), b(granularity);
	gState = 0x1234567u + (unsigned)variant * 7919u;
	fprintf(out, "variant %d granularity %d\n", variant, granularity);
	for (int step = 0; step < 300; step++) {
		int op = Rnd() % 22, v = Rnd() % 12, r = 0;
		switch (op) {
		case 0: r = a.Append(v); break;
		case 1: { int idx = Rnd() % (a.Num() + 5) - 2; r = a.Insert(v, idx); break; }
		case 2: { int idx = Rnd() % (a.Num() + 3) - 1; r = a.RemoveIndex(idx); break; }
		case 3: r = a.Remove(v); break;
		case 4: r = a.AddUnique(v); break;
		case 5: r = a.FindIndex(v); break;
		case 6: { int n = Rnd() % 20; bool rs = (Rnd() & 1) != 0; a.SetNum(n, rs); break; }
		case 7: a.Resize(Rnd() % 20); break;
		case 8: { int n = Rnd() % 20; int g = 1 + Rnd() % 6; a.Resize(n, g); break; }
		case 9: a.Condense(); break;
		case 10: a.SetGranularity(1 + Rnd() % 7); break;
		case 11: a.AssureSize(Rnd() % 20); break;
		case 12: a.AssureSize(Rnd() % 20, v); break;
		case 13: { int before = a.Num(); a.Alloc() = v; r = before; break; }
		case 14: r = a.Append(b); break;
		case 15: a.Swap(b); break;
		case 16: a.Sort(); break;
		case 17: { int s = Rnd() % 8 - 1; int e = Rnd() % 20; a.SortSubSection(s, e); break; }
		case 18: a.Clear(); break;
		case 19: a = b; break;
		case 20: b.Append(v); b.Append(Rnd() % 12); break;
		case 21: b.Insert(v, Rnd() % 4); break;
		}
		fprintf(out, "step %d op %d v %d ret %d\n", step, op, v, r);
		DumpList("A", a);
		DumpList("B", b);
	}
}

typedef idStaticList<int, 8> StaticInts;

static void DumpStatic(const char *name, const StaticInts &l) {
	fprintf(out, "  %s %d/%d [", name, l.Num(), l.Max());
	for (int i = 0; i < l.Num(); i++) fprintf(out, "%s%d", i ? " " : "", l[i]);
	fprintf(out, "]\n");
}

static void StaticScenario(int variant) {
	// heap objects: the array of an idStaticList is not initialised and a stack object would show leftovers
	StaticInts &a = *new StaticInts, &b = *new StaticInts;
	gState = 0xABCDEFu + (unsigned)variant * 104729u;
	fprintf(out, "variant %d\n", variant);
	for (int step = 0; step < 300; step++) {
		int op = Rnd() % 14, v = Rnd() % 12, r = 0;
		switch (op) {
		case 0: r = a.Append(v); break;
		case 1: { int idx = Rnd() % (a.Num() + 5) - 2; r = a.Insert(v, idx < 0 ? 0 : idx); break; }
		case 2: { int idx = Rnd() % (a.Num() + 3) - 1; r = a.RemoveIndex(idx); break; }
		case 3: r = a.Remove(v); break;
		case 4: r = a.AddUnique(v); break;
		case 5: r = a.FindIndex(v); break;
		case 6: a.SetNum(Rnd() % 9); break;
		case 7: { int *p = a.Alloc(); if (p) { *p = v; r = a.Num() - 1; } else r = -1; break; }
		case 8: r = a.Append(b); break;
		case 9: a.Swap(b); break;
		case 10: a.Clear(); break;
		case 11: a = b; break;
		case 12: b.Append(v); b.Append(Rnd() % 12); break;
		case 13: b.Insert(v, Rnd() % 3); break;
		}
		fprintf(out, "step %d op %d v %d ret %d\n", step, op, v, r);
		DumpStatic("A", a);
		DumpStatic("B", b);
	}
}

static const char *keyPool[] = {
	"a", "A", "b", "foo", "Foo", "FOO", "bar", "Bar", "baz", "x1", "x2", "x3", "x10", "key", "Key", "zz",
	"", "ab", "ba", "Ab", "aB", "mm", "MM", "q"
};

static void DumpTable(const char *name, const idHashTable<int> &t) {
	fprintf(out, "  %s num %d [", name, t.Num());
	for (int i = 0; i < t.Num(); i++) {
		int *p = t.GetIndex(i);
		fprintf(out, "%s%d", i ? " " : "", p ? *p : -1);
	}
	fprintf(out, "]\n");
}

static void TableScenario(int variant, int tableSize) {
	idHashTable<int> t(tableSize);
	gState = 0x600DF00Du + (unsigned)variant * 15485863u;
	fprintf(out, "variant %d size %d\n", variant, tableSize);
	for (int step = 0; step < 300; step++) {
		int op = Rnd() % 8, k = Rnd() % 24, r = 0, v = step;
		switch (op) {
		case 0: case 1: case 2: t.Set(keyPool[k], v); break;
		case 3: { int *p = 0; r = t.Get(keyPool[k], &p) ? (p ? *p : -2) : -1; break; }
		case 4: r = t.Remove(keyPool[k]); break;
		case 5: { int *p = t.GetIndex(Rnd() % (t.Num() + 2)); r = p ? *p : -1; break; }
		case 6: { if (Rnd() % 8 == 0) t.Clear(); break; }
		case 7: {
			idHashTable<int> c(t);
			DumpTable("COPY", c);
			break;
		}
		}
		fprintf(out, "step %d op %d key %d ret %d\n", step, op, k, r);
		DumpTable("T", t);
	}
}

int main(int argc, char **argv) {
	out = fopen(argc > 1 ? argv[1] : "lists.golden.txt", "wb");
	if (!out) return 1;
	fprintf(out, "== list\n");
	static const int grans[] = { 1, 2, 3, 5, 8, 16 };
	for (int v = 0; v < 6; v++) ListScenario(v, grans[v]);
	fprintf(out, "== staticlist\n");
	for (int v = 0; v < 4; v++) StaticScenario(v);
	fprintf(out, "== hashtable\n");
	static const int sizes[] = { 1, 4, 16, 256 };
	for (int v = 0; v < 4; v++) TableScenario(v, sizes[v]);
	fclose(out);
	return 0;
}
