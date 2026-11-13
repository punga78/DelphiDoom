/*
 * Driver of the parity tool of the info strings of Quake III (issue #121): runs the REAL Info_* functions of
 * q_shared.c (included as q3_info.inc) on crafted and random strings and prints one line per call, every
 * string in hexadecimal (they hold backslashes, quotes and, in the printed messages, newlines).
 * Tests\Source\DelphiDoom.Tests.Net.Q3.InfoString.pas reads the inputs from the lines and compares the outputs.
 */
#include "stubs.h"

#define MAX_INFO_STRING 1024
#define MAX_INFO_KEY 1024
#define MAX_INFO_VALUE 1024
#define BIG_INFO_STRING 8192
#define BIG_INFO_KEY 8192
#define BIG_INFO_VALUE 8192

static jmp_buf errjmp;
static void Com_Error(int code, const char *fmt, ...) { longjmp(errjmp, 1); }
static char printbuf[4096];
static void Com_Printf(const char *fmt, ...) {
	va_list ap;
	size_t n = strlen(printbuf);
	va_start(ap, fmt);
	vsnprintf(printbuf + n, sizeof(printbuf) - n, fmt, ap);
	va_end(ap);
}

#include "q3_info.inc"

/*
 * A string as text: bytes in hexadecimal, "-" for the empty string, and a run of 8 or more equal bytes as
 * "r<byte>x<count>"; the pieces are separated by dots (the long strings of the limit cases are runs).
 */
static void hex(const char *p) {
	int first = 1;
	if (!*p) { printf("-"); return; }
	while (*p) {
		int run = 1;
		while (p[run] == *p) run++;
		if (!first) printf(".");
		first = 0;
		if (run >= 8) {
			printf("r%02xx%d", (unsigned char)*p, run);
			p += run;
		} else {
			while (*p && !(p[0] == p[1] && p[1] == p[2] && p[2] == p[3] && p[3] == p[4] && p[4] == p[5] && p[5] == p[6] && p[6] == p[7])) {
				printf("%02x", (unsigned char)*p);
				p++;
			}
		}
	}
}

static unsigned rs = 0x2718281u;
static unsigned rnd(void) {
	rs ^= rs << 13;
	rs ^= rs >> 17;
	rs ^= rs << 5;
	return rs;
}

static const char *infos[] = {
	"", "\\a\\1", "\\a\\1\\b\\2\\c\\3", "a\\1", "\\a", "\\a\\", "\\\\", "\\a\\1\\A\\2", "\\key\\value\\trailing",
	"\\name\\Player One\\rate\\25000\\snaps\\20", "\\a\\\\b\\2", "x"
};
static const char *keys[] = {"a", "A", "c", "", "x\\y", "a;b", "q\"", "name"};
static const char *values[] = {"", "v", "1\\2", "s;e", "q\"", "25000"};
#define NI (int)(sizeof(infos) / sizeof(infos[0]))
#define NK (int)(sizeof(keys) / sizeof(keys[0]))
#define NV (int)(sizeof(values) / sizeof(values[0]))

static char work[2 * BIG_INFO_STRING];

static void endLine(int err) {
	char *p;
	for (p = printbuf; *p; p++) ;
	printf(" => err=%d prints=", err);
	hex(printbuf);
	printf("\n");
	printbuf[0] = 0;
}

static void caseValue(const char *info, const char *key) {
	int err = 0;
	const char *r = "";
	printf("value ");
	hex(info); printf(" "); hex(key);
	if (setjmp(errjmp)) err = 1;
	else r = Info_ValueForKey(info, key);
	printf(" result="); hex(err ? "" : r);
	endLine(err);
}

static void caseRemove(const char *info, const char *key, int big) {
	int err = 0;
	strcpy(work, info);
	printf(big ? "removebig " : "remove ");
	hex(info); printf(" "); hex(key);
	if (setjmp(errjmp)) err = 1;
	else if (big) Info_RemoveKey_Big(work, key);
	else Info_RemoveKey(work, key);
	printf(" result="); hex(work);
	endLine(err);
}

static void caseSet(const char *info, const char *key, const char *value, int big) {
	int err = 0;
	strcpy(work, info);
	printf(big ? "setbig " : "set ");
	hex(info); printf(" "); hex(key); printf(" "); hex(value);
	if (setjmp(errjmp)) err = 1;
	else if (big) Info_SetValueForKey_Big(work, key, value);
	else Info_SetValueForKey(work, key, value);
	printf(" result="); hex(work);
	endLine(err);
}

static void caseValidate(const char *info) {
	printf("validate ");
	hex(info);
	printf(" result=%d\n", Info_Validate(info));
}

static void casePairs(const char *info) {
	const char *head = info;
	char key[BIG_INFO_KEY], value[BIG_INFO_VALUE];
	int n = 0;
	printf("pairs ");
	hex(info);
	printf(" result=");
	while (*head && n < 20) {
		Info_NextPair(&head, key, value);
		hex(key); printf(":"); hex(value); printf(";");
		n++;
	}
	printf(" end=%d\n", (int)(head - info));
}

int main(void) {
	int i, k, v, n;
	static char longInfo[BIG_INFO_STRING + 8];
	for (i = 0; i < NI; i++) {
		caseValidate(infos[i]);
		casePairs(infos[i]);
		for (k = 0; k < NK; k++) {
			caseValue(infos[i], keys[k]);
			caseRemove(infos[i], keys[k], 0);
			caseRemove(infos[i], keys[k], 1);
			for (v = 0; v < NV; v++) {
				caseSet(infos[i], keys[k], values[v], 0);
				if (i < 5) caseSet(infos[i], keys[k], values[v], 1);
			}
		}
	}
	/* random strings of pairs, and every one changed in a few ways */
	for (n = 0; n < 40; n++) {
		char s[600];
		int pairs = rnd() % 8;
		s[0] = 0;
		for (i = 0; i < pairs; i++) {
			char part[40];
			sprintf(part, "\\%s%d\\%s%d", (rnd() & 1) ? "K" : "k", (int)(rnd() % 5), (rnd() & 1) ? "V" : "v", (int)(rnd() % 100));
			strcat(s, part);
		}
		if (rnd() % 5 == 0) strcat(s, "\\dangling");
		caseValidate(s);
		casePairs(s);
		for (k = 0; k < 6; k++) {
			char key[16];
			sprintf(key, "%s%d", (rnd() & 1) ? "K" : "k", (int)(rnd() % 5));
			caseValue(s, key);
			caseRemove(s, key, rnd() & 1);
			caseSet(s, key, (rnd() & 1) ? "new" : "", rnd() & 1);
		}
	}
	/* the limits: strings of 1022 to 1025 characters, and 8190 to 8193 for the big ones */
	for (n = 1020; n <= 1025; n++) {
		memset(longInfo, 'x', n);
		longInfo[0] = '\\';
		longInfo[1] = 'a';
		longInfo[2] = '\\';
		longInfo[n] = 0;
		caseValue(longInfo, "a");
		caseRemove(longInfo, "a", 0);
		caseSet(longInfo, "k", "1", 0);
		caseSet(longInfo, "kk", "value", 0);
	}
	for (n = 8188; n <= 8193; n++) {
		memset(longInfo, 'x', n);
		longInfo[0] = '\\';
		longInfo[1] = 'a';
		longInfo[2] = '\\';
		longInfo[n] = 0;
		caseValue(longInfo, "a");
		caseRemove(longInfo, "a", 1);
		caseSet(longInfo, "k", "1", 1);
		caseSet(longInfo, "kk", "value", 1);
	}
	/* a pair that does not fit in a buffer: Com_sprintf prints its overflow and truncates */
	{
		static char longValue[2000];
		memset(longValue, 'y', 1990);
		longValue[1990] = 0;
		caseSet("", "key", longValue, 0);
		caseSet("\\a\\1", "key", longValue, 0);
		caseSet("", "key", longValue, 1);
		memset(longValue, 'z', 1030);
		longValue[1030] = 0;
		caseSet("", "k", longValue, 0);
	}
	return 0;
}
