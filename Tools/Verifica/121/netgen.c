/*
 * Driver of the parity tool of the issue #121: runs scenarios on the REAL code of Quake III
 * (huffman.c, msg.c, net_chan.c, included as q3_original.inc) and prints one text line per result.
 * Tests\Source\DelphiDoom.Tests.Net.Q3Parity.pas runs the same scenarios with the Delphi classes
 * and compares line by line.
 */
#include "stubs.h"
#include "q3_types.inc"

static cvar_t cl_shownet_value = {0};
static cvar_t *cl_shownet = &cl_shownet_value;
static cvar_t showpackets_value = {0}, showdrop_value = {0}, qport_value = {0};

static jmp_buf errjmp;
static char errtext[256];
static void Com_Error(int code, const char *fmt, ...) {
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(errtext, sizeof(errtext), fmt, ap);
	va_end(ap);
	longjmp(errjmp, 1);
}
static char printbuf[4096];
static void Com_Printf(const char *fmt, ...) {
	va_list ap;
	size_t n = strlen(printbuf);
	va_start(ap, fmt);
	vsnprintf(printbuf + n, sizeof(printbuf) - n, fmt, ap);
	va_end(ap);
}
static void Q_strncpyz(char *dest, const char *src, int destsize) {
	strncpy(dest, src, destsize - 1);
	dest[destsize - 1] = 0;
}

#define MAX_CAPTURED 64
static struct { int sock; int length; byte data[2000]; } captured[MAX_CAPTURED];
static int capturedCount;
static void NET_SendPacket(netsrc_t sock, int length, const void *data, netadr_t to) {
	captured[capturedCount].sock = sock;
	captured[capturedCount].length = length;
	memcpy(captured[capturedCount].data, data, length);
	capturedCount++;
}
static const char *NET_AdrToString(netadr_t a) { return "adr"; }

#include "q3_original.inc"

/* ------------------------------------------------------------------------ helpers */

static unsigned fnv(const byte *p, int n) {
	unsigned h = 2166136261u;
	int i;
	for (i = 0; i < n; i++) {
		h ^= p[i];
		h *= 16777619u;
	}
	return h;
}

static void hex(const byte *p, int n) {
	int i;
	for (i = 0; i < n; i++) printf("%02x", p[i]);
}

static unsigned rs = 0x12345678u;
static unsigned rnd(void) {
	rs ^= rs << 13;
	rs ^= rs >> 17;
	rs ^= rs << 5;
	return rs;
}

static float asFloat(int bits) { float f; memcpy(&f, &bits, 4); return f; }
static int asBits(float f) { int b; memcpy(&b, &f, 4); return b; }

static void flushPrints(const char *tag) {
	if (printbuf[0]) {
		printf("%s print %s\n", tag, printbuf);
		printbuf[0] = 0;
	}
}

static void dump(const char *tag, msg_t *m) {
	printf("%s size=%d bit=%d overflowed=%d hex=", tag, m->cursize, m->bit, m->overflowed);
	hex(m->data, m->cursize);
	printf("\n");
	flushPrints(tag);
}

/* printing reads one at a time: the order of evaluation of the arguments of printf is not defined */
static void pBits(msg_t *m, const char *n, int bits) { int v = MSG_ReadBits(m, bits); printf(" %s=%d", n, v); }
static void pByte(msg_t *m, const char *n) { int v = MSG_ReadByte(m); printf(" %s=%d", n, v); }
static void pChar(msg_t *m, const char *n) { int v = MSG_ReadChar(m); printf(" %s=%d", n, v); }
static void pShort(msg_t *m, const char *n) { int v = MSG_ReadShort(m); printf(" %s=%d", n, v); }
static void pLong(msg_t *m, const char *n) { int v = MSG_ReadLong(m); printf(" %s=%d", n, v); }
static void pFloat(msg_t *m, const char *n) { int v = asBits(MSG_ReadFloat(m)); printf(" %s=%08x", n, v); }
static void pString(msg_t *m, const char *n) { char *v = MSG_ReadString(m); printf(" %s=[%s]", n, v); }
static void pLine(msg_t *m, const char *n) { char *v = MSG_ReadStringLine(m); printf(" %s=[%s]", n, v); }
static void pBig(msg_t *m, const char *n) { char *v = MSG_ReadBigString(m); printf(" %s=[%s]", n, v); }
static void pDelta(msg_t *m, const char *n, int old, int bits) { int v = MSG_ReadDelta(m, old, bits); printf(" %s=%d", n, v); }
static void pDeltaFloat(msg_t *m, const char *n, float old) { int v = asBits(MSG_ReadDeltaFloat(m, old)); printf(" %s=%08x", n, v); }
static void pDeltaKey(msg_t *m, const char *n, int key, int old, int bits) { int v = MSG_ReadDeltaKey(m, key, old, bits); printf(" %s=%d", n, v); }
static void pDeltaKeyFloat(msg_t *m, const char *n, int key, float old) { int v = asBits(MSG_ReadDeltaKeyFloat(m, key, old)); printf(" %s=%08x", n, v); }

/* ------------------------------------------------------------------------ scenario: bits */

static void scenarioBits(void) {
	byte buf[160];
	msg_t m;
	int i, v;
	char *s;
	byte data[3] = {1, 2, 0xff};
	byte got[3];

	memset(buf, 0, sizeof(buf));
	overflows = 0;
	MSG_Init(&m, buf, 128);
	MSG_WriteByte(&m, 0xAB);
	MSG_WriteChar(&m, -5);
	MSG_WriteShort(&m, -1234);
	MSG_WriteLong(&m, 0x12345678);
	MSG_WriteFloat(&m, 3.5f);
	MSG_WriteFloat(&m, -0.0f);
	MSG_WriteString(&m, "hello%\xff world");
	MSG_WriteBigString(&m, "big\xff%s");
	MSG_WriteAngle(&m, 90.0f);
	MSG_WriteAngle(&m, -45.5f);
	MSG_WriteAngle16(&m, 180.0f);
	MSG_WriteBits(&m, 5, 3);
	MSG_WriteBits(&m, -3, -4);
	MSG_WriteBits(&m, 0x1234, 13);
	MSG_WriteBits(&m, 0x7fffffff, 31);
	MSG_WriteBits(&m, -1, 32);
	MSG_WriteBits(&m, 1000, -12);
	MSG_WriteBits(&m, 2047, -12);
	MSG_WriteBits(&m, -3, -12);
	MSG_WriteBits(&m, 40000, -16);
	MSG_WriteBits(&m, 200, -8);
	MSG_WriteBits(&m, 300, 8);
	MSG_WriteData(&m, data, 3);
	MSG_WriteString(&m, NULL);
	dump("bits.write", &m);

	MSG_BeginReading(&m);
	printf("bits.read");
	pByte(&m, "byte"); pChar(&m, "char"); pShort(&m, "short"); pLong(&m, "long");
	pFloat(&m, "f1"); pFloat(&m, "f2"); pString(&m, "str"); pBig(&m, "big");
	pByte(&m, "angle1"); pByte(&m, "angle2"); pShort(&m, "a16");
	pBits(&m, "b3", 3); pBits(&m, "b4s", -4); pBits(&m, "b13", 13); pBits(&m, "b31", 31); pBits(&m, "b32", 32);
	pBits(&m, "s12a", -12); pBits(&m, "s12b", -12); pBits(&m, "s12c", -12); pBits(&m, "s16", -16); pBits(&m, "s8", -8); pBits(&m, "u8", 8);
	MSG_ReadData(&m, got, 3);
	printf(" data=%d,%d,%d", got[0], got[1], got[2]);
	pString(&m, "empty");
	printf(" readcount=%d bit=%d\n", m.readcount, m.bit);
	printf("bits.end");
	pByte(&m, "byte"); pChar(&m, "char"); pShort(&m, "short"); pLong(&m, "long"); pFloat(&m, "float"); pString(&m, "str"); pLine(&m, "line");
	printf("\n");

	/* a line with a newline, and a long string cut at 1023 */
	MSG_Init(&m, buf, 128);
	MSG_WriteData(&m, "ab\ncd%e", 8);
	MSG_BeginReading(&m);
	s = MSG_ReadStringLine(&m);
	printf("bits.line [%s]", s);
	s = MSG_ReadStringLine(&m);
	printf(" [%s]\n", s);
	{
		static byte big[4000];
		static char longs[1200];
		msg_t b;
		memset(longs, 'x', 1100);
		longs[1100] = 0;
		MSG_Init(&b, big, 4000);
		MSG_WriteString(&b, longs);
		printf("bits.longstring size=%d bit=%d\n", b.cursize, b.bit);
		MSG_WriteBigString(&b, longs);
		MSG_BeginReading(&b);
		s = MSG_ReadBigString(&b);
		printf("bits.longbig len=%d size=%d bit=%d\n", (int)strlen(s), b.cursize, b.bit);
		flushPrints("bits.long");
		memset(longs, 'y', 1100);
		MSG_Init(&b, big, 4000);
		MSG_WriteBigString(&b, longs);
		MSG_BeginReading(&b);
		s = MSG_ReadString(&b);
		printf(" readstring len=%d readcount=%d\n", (int)strlen(s), b.readcount);
	}

	/* the error and the overflow of WriteBits */
	MSG_Init(&m, buf, 128);
	if (setjmp(errjmp) == 0) MSG_WriteBits(&m, 1, 0); else printf("bits.err0 %s\n", errtext);
	if (setjmp(errjmp) == 0) MSG_WriteBits(&m, 1, 33); else printf("bits.err33 %s\n", errtext);
	if (setjmp(errjmp) == 0) MSG_WriteBits(&m, 1, -32); else printf("bits.err-32 %s\n", errtext);
	overflows = 0;
	MSG_WriteBits(&m, 8, 3);
	MSG_WriteBits(&m, -1, 8);
	MSG_WriteBits(&m, 40000, -16);
	MSG_WriteBits(&m, -40000, -16);
	MSG_WriteBits(&m, 300, -8);
	printf("bits.overflows %d\n", overflows);

	/* overflow of a small buffer: writes until the message refuses */
	for (v = 8; v <= 24; v += 8) {
		memset(buf, 0, sizeof(buf));
		MSG_Init(&m, buf, v);
		for (i = 0; i < 40; i++) MSG_WriteByte(&m, i * 7);
		printf("bits.small%d ", v);
		dump("", &m);
	}
	MSG_Init(&m, buf, 16);
	MSG_WriteLong(&m, 1);
	MSG_Clear(&m);
	printf("bits.clear size=%d bit=%d ovf=%d\n", m.cursize, m.bit, m.overflowed);
}

/* ------------------------------------------------------------------------ scenario: oob */

static void scenarioOob(void) {
	byte buf[64];
	msg_t m;
	memset(buf, 0, sizeof(buf));
	MSG_InitOOB(&m, buf, 64);
	MSG_WriteBits(&m, 0x1ff, 8);
	MSG_WriteBits(&m, 0x12345, 16);
	MSG_WriteBits(&m, 0xdeadbeef, 32);
	MSG_WriteByte(&m, 7);
	MSG_WriteShort(&m, -2);
	MSG_WriteLong(&m, -3);
	MSG_WriteFloat(&m, 1.5f);
	if (setjmp(errjmp) == 0) MSG_WriteBits(&m, 1, 12); else printf("oob.err12 %s\n", errtext);
	dump("oob.write", &m);
	MSG_BeginReadingOOB(&m);
	printf("oob.read");
	pBits(&m, "b", 8); pBits(&m, "s", 16); pBits(&m, "l", 32); pByte(&m, "byte"); pShort(&m, "short"); pLong(&m, "long"); pFloat(&m, "float");
	printf(" readcount=%d bit=%d\n", m.readcount, m.bit);
	if (setjmp(errjmp) == 0) MSG_ReadBits(&m, 12); else printf("oob.errread12 %s\n", errtext);
	MSG_BeginReadingOOB(&m);
	printf("oob.signed");
	pBits(&m, "a", -8); pBits(&m, "b", -16);
	printf("\n");
	/* bitstream after oob */
	MSG_Init(&m, buf, 64);
	MSG_WriteByte(&m, 1);
	MSG_Bitstream(&m);
	MSG_WriteByte(&m, 2);
	dump("oob.bitstream", &m);
}

/* ------------------------------------------------------------------------ scenario: deltas */

static void scenarioDelta(void) {
	byte buf[512];
	msg_t m;
	usercmd_t a, b, c, d;
	int key;
	memset(buf, 0, sizeof(buf));
	MSG_Init(&m, buf, 512);
	MSG_WriteDelta(&m, 5, 5, 8);
	MSG_WriteDelta(&m, 5, 9, 8);
	MSG_WriteDelta(&m, 5, 300, 16);
	MSG_WriteDeltaFloat(&m, 1.0f, 1.0f);
	MSG_WriteDeltaFloat(&m, 1.0f, 2.5f);
	MSG_WriteDeltaKey(&m, 0x5a5a, 3, 3, 12);
	MSG_WriteDeltaKey(&m, 0x5a5a, 3, 4, 12);
	MSG_WriteDeltaKey(&m, 0x12345678, 3, 4, 31);
	MSG_WriteDeltaKeyFloat(&m, 0x1234, 1.0f, 1.0f);
	MSG_WriteDeltaKeyFloat(&m, 0x1234, 1.0f, -7.25f);
	dump("delta.write", &m);
	MSG_BeginReading(&m);
	printf("delta.read");
	pDelta(&m, "a", 5, 8); pDelta(&m, "b", 5, 8); pDelta(&m, "c", 5, 16);
	pDeltaFloat(&m, "d", 1.0f); pDeltaFloat(&m, "e", 1.0f);
	pDeltaKey(&m, "f", 0x5a5a, 3, 12); pDeltaKey(&m, "g", 0x5a5a, 3, 12); pDeltaKey(&m, "h", 0x12345678, 3, 31);
	pDeltaKeyFloat(&m, "i", 0x1234, 1.0f); pDeltaKeyFloat(&m, "j", 0x1234, 1.0f);
	printf("\n");

	/* usercmd */
	memset(&a, 0, sizeof(a));
	memset(&b, 0, sizeof(b));
	memset(&c, 0, sizeof(c));
	a.serverTime = 1000; a.angles[0] = 100; a.angles[1] = 200; a.angles[2] = 0; a.buttons = 1; a.weapon = 3; a.forwardmove = 127; a.rightmove = -128; a.upmove = 0;
	b = a; b.serverTime = 1050; b.angles[1] = 65535; b.buttons = 3; b.forwardmove = -1;
	c = a; c.serverTime = 5000; c.weapon = 9; c.upmove = -90;
	d = a; d.serverTime = 1000;
	printf("usercmd size=%d\n", (int)sizeof(usercmd_t));
	MSG_Init(&m, buf, 512);
	MSG_WriteDeltaUsercmd(&m, &a, &b);
	MSG_WriteDeltaUsercmd(&m, &a, &c);
	MSG_WriteDeltaUsercmd(&m, &a, &d);
	dump("usercmd.write", &m);
	MSG_BeginReading(&m);
	{
		usercmd_t r[3];
		int i;
		memset(r, 0x55, sizeof(r));
		MSG_ReadDeltaUsercmd(&m, &a, &r[0]);
		MSG_ReadDeltaUsercmd(&m, &a, &r[1]);
		MSG_ReadDeltaUsercmd(&m, &a, &r[2]);
		for (i = 0; i < 3; i++)
			printf("usercmd.read %d t=%d a=%d,%d,%d b=%d w=%d m=%d,%d,%d\n", i, r[i].serverTime, r[i].angles[0], r[i].angles[1], r[i].angles[2], r[i].buttons, r[i].weapon, r[i].forwardmove, r[i].rightmove, r[i].upmove);
	}
	key = 0x6d2b79f5;
	MSG_Init(&m, buf, 512);
	MSG_WriteDeltaUsercmdKey(&m, key, &a, &b);
	MSG_WriteDeltaUsercmdKey(&m, key, &a, &c);
	MSG_WriteDeltaUsercmdKey(&m, key, &a, &d);
	dump("usercmdkey.write", &m);
	MSG_BeginReading(&m);
	{
		usercmd_t r[3];
		int i;
		memset(r, 0x55, sizeof(r));
		MSG_ReadDeltaUsercmdKey(&m, key, &a, &r[0]);
		MSG_ReadDeltaUsercmdKey(&m, key, &a, &r[1]);
		MSG_ReadDeltaUsercmdKey(&m, key, &a, &r[2]);
		for (i = 0; i < 3; i++)
			printf("usercmdkey.read %d t=%d a=%d,%d,%d b=%d w=%d m=%d,%d,%d\n", i, r[i].serverTime, r[i].angles[0], r[i].angles[1], r[i].angles[2], r[i].buttons, r[i].weapon, r[i].forwardmove, r[i].rightmove, r[i].upmove);
	}
}

/* ------------------------------------------------------------------------ scenario: entity and player state */

static const float fpal[] = {0.0f, -0.0f, 1.0f, -1.0f, 100.0f, 4095.0f, -4096.0f, 4096.0f, -4097.0f, 3.14159f, 1e10f, -2.5f, 0.5f, 123456.0f, 2147483648.0f, -2147483648.0f};

static void randomField(int *p, netField_t *f) {
	unsigned v;
	if (f->bits == 0) {
		*p = asBits(fpal[rnd() % (sizeof(fpal) / sizeof(fpal[0]))]);
		return;
	}
	if (rnd() % 4 == 0) { *p = 0; return; }
	v = rnd();
	if (f->bits == 32) { *p = (int)v; return; }
	if (f->bits > 0) { *p = (int)(v & ((1u << f->bits) - 1)); return; }
	{
		int b = -f->bits;
		int x = (int)(v & ((1u << b) - 1));
		if (x & (1 << (b - 1))) x |= -1 ^ ((1 << b) - 1);
		*p = x;
	}
}

static void printFields(const char *name, netField_t *fields, int n) {
	int i;
	for (i = 0; i < n; i++) printf("%s %d %s %d %d\n", name, i, fields[i].name, fields[i].offset, fields[i].bits);
}

static void scenarioEntity(void) {
	byte buf[4096];
	msg_t m;
	entityState_t from, to, dec;
	int i, k, j, num, force, n, nf;
	nf = sizeof(entityStateFields) / sizeof(entityStateFields[0]);
	printf("entity sizeof=%d fields=%d\n", (int)sizeof(entityState_t), nf);
	printFields("entity.field", entityStateFields, nf);
	rs = 0x2545F491u;
	for (i = 0; i < 80; i++) {
		memset(&from, 0, sizeof(from));
		for (j = 0; j < nf; j++) {
			if (rnd() % 3 == 0) continue;
			randomField((int *)((byte *)&from + entityStateFields[j].offset), &entityStateFields[j]);
		}
		to = from;
		k = (i < 10) ? i : rnd() % 8;
		if (i >= 60) k = 51;
		for (j = 0; j < k; j++) {
			n = rnd() % nf;
			if (i >= 60) n = j;
			randomField((int *)((byte *)&to + entityStateFields[n].offset), &entityStateFields[n]);
		}
		num = rnd() % 1023;
		from.number = to.number = num;
		force = rnd() & 1;
		memset(buf, 0, sizeof(buf));
		MSG_Init(&m, buf, 4096);
		MSG_WriteDeltaEntity(&m, &from, &to, (qboolean)force);
		printf("entity.case %d num=%d force=%d size=%d bit=%d fnv=%08x", i, num, force, m.cursize, m.bit, fnv(m.data, m.cursize));
		if (m.cursize > 0) {
			memset(&dec, 0xaa, sizeof(dec));
			MSG_BeginReading(&m);
			n = MSG_ReadBits(&m, GENTITYNUM_BITS);
			MSG_ReadDeltaEntity(&m, &from, &dec, n);
			printf(" n=%d dec=%08x eq=%d readcount=%d bit=%d", n, fnv((byte *)&dec, sizeof(dec)), memcmp(&dec, &to, sizeof(dec)) == 0, m.readcount, m.bit);
		}
		printf("\n");
	}
	/* removal */
	memset(&from, 0, sizeof(from));
	from.number = 77;
	MSG_Init(&m, buf, 4096);
	MSG_WriteDeltaEntity(&m, &from, NULL, qfalse);
	MSG_WriteDeltaEntity(&m, NULL, NULL, qfalse);
	dump("entity.remove", &m);
	MSG_BeginReading(&m);
	n = MSG_ReadBits(&m, GENTITYNUM_BITS);
	memset(&dec, 0xaa, sizeof(dec));
	MSG_ReadDeltaEntity(&m, &from, &dec, n);
	printf("entity.removed n=%d number=%d fnv=%08x\n", n, dec.number, fnv((byte *)&dec, sizeof(dec)));
	/* hand made floats */
	memset(&from, 0, sizeof(from));
	to = from;
	from.number = to.number = 5;
	to.origin[0] = 3.0f; to.origin[1] = -4096.0f; to.origin[2] = 4096.0f; to.angles[0] = -0.0f; to.angles[1] = 2.5f;
	to.pos.trBase[0] = 8191.0f; to.pos.trBase[1] = -4095.0f; to.angles2[2] = asFloat(0x7fc00000);
	to.pos.trBase[2] = 1e30f; to.apos.trBase[0] = -2147483648.0f; to.apos.trBase[1] = 2147483648.0f;
	MSG_Init(&m, buf, 4096);
	MSG_WriteDeltaEntity(&m, &from, &to, qtrue);
	dump("entity.floats", &m);
	MSG_BeginReading(&m);
	n = MSG_ReadBits(&m, GENTITYNUM_BITS);
	MSG_ReadDeltaEntity(&m, &from, &dec, n);
	printf("entity.floats.dec fnv=%08x\n", fnv((byte *)&dec, sizeof(dec)));
	/* an entity number out of range */
	to.number = 1024;
	MSG_Init(&m, buf, 4096);
	if (setjmp(errjmp) == 0) MSG_WriteDeltaEntity(&m, &from, &to, qtrue); else printf("entity.err %s\n", errtext);
	if (setjmp(errjmp) == 0) MSG_ReadDeltaEntity(&m, &from, &dec, -1); else printf("entity.errread %s\n", errtext);
}

static void scenarioPlayer(void) {
	byte buf[4096];
	msg_t m;
	playerState_t from, to, dec, zero;
	int i, k, j, n, nf;
	nf = sizeof(playerStateFields) / sizeof(playerStateFields[0]);
	printf("player sizeof=%d fields=%d\n", (int)sizeof(playerState_t), nf);
	printFields("player.field", playerStateFields, nf);
	rs = 0x9E3779B9u;
	for (i = 0; i < 80; i++) {
		memset(&from, 0, sizeof(from));
		for (j = 0; j < nf; j++) {
			if (rnd() % 3 == 0) continue;
			randomField((int *)((byte *)&from + playerStateFields[j].offset), &playerStateFields[j]);
		}
		for (j = 0; j < 16; j++) {
			if (rnd() % 3 == 0) from.stats[j] = (int)(rnd() & 0x7fff);
			if (rnd() % 3 == 0) from.persistant[j] = (int)(rnd() & 0x7fff) - 100;
			if (rnd() % 3 == 0) from.ammo[j] = (int)(rnd() & 0x3ff);
			if (rnd() % 3 == 0) from.powerups[j] = (int)rnd();
		}
		to = from;
		k = (i < 10) ? i : rnd() % 8;
		if (i >= 60) k = nf;
		for (j = 0; j < k; j++) {
			n = rnd() % nf;
			if (i >= 60) n = j;
			randomField((int *)((byte *)&to + playerStateFields[n].offset), &playerStateFields[n]);
		}
		if (i % 4 != 0) {
			for (j = 0; j < 16; j++) {
				if (rnd() % 6 == 0) to.stats[j] = (int)(rnd() & 0x7fff);
				if (rnd() % 6 == 0) to.persistant[j] = (int)(rnd() & 0x7fff) - 100;
				if (rnd() % 6 == 0) to.ammo[j] = (int)(rnd() & 0x3ff);
				if (rnd() % 6 == 0) to.powerups[j] = (int)rnd();
			}
		}
		/* fields that are not transmitted */
		to.ping = (int)rnd(); to.pmove_framecount = 9; to.jumppad_frame = 3; to.entityEventSequence = 4; to.externalEventTime = 11;
		memset(buf, 0, sizeof(buf));
		MSG_Init(&m, buf, 4096);
		MSG_WriteDeltaPlayerstate(&m, &from, &to);
		printf("player.case %d size=%d bit=%d fnv=%08x", i, m.cursize, m.bit, fnv(m.data, m.cursize));
		memset(&dec, 0xaa, sizeof(dec));
		MSG_BeginReading(&m);
		MSG_ReadDeltaPlayerstate(&m, &from, &dec);
		printf(" dec=%08x readcount=%d bit=%d\n", fnv((byte *)&dec, sizeof(dec)), m.readcount, m.bit);
	}
	/* from NULL (a zero state) */
	memset(&zero, 0, sizeof(zero));
	to = zero;
	to.commandTime = 1234; to.origin[0] = 100.0f; to.viewangles[1] = 90.5f; to.stats[1] = 100; to.powerups[3] = 99999;
	MSG_Init(&m, buf, 4096);
	MSG_WriteDeltaPlayerstate(&m, NULL, &to);
	dump("player.fromnull", &m);
	MSG_BeginReading(&m);
	MSG_ReadDeltaPlayerstate(&m, NULL, &dec);
	printf("player.fromnull.dec fnv=%08x\n", fnv((byte *)&dec, sizeof(dec)));
	/* nothing changed */
	MSG_Init(&m, buf, 4096);
	MSG_WriteDeltaPlayerstate(&m, &to, &to);
	dump("player.same", &m);
}

/* ------------------------------------------------------------------------ scenario: huffman */

static void scrubStack(void) {
	volatile byte scratch[200000];
	int i;
	for (i = 0; i < (int)sizeof(scratch); i++) scratch[i] = 0;
}

static void huffCase(const char *tag, byte *payload, int len, int offset) {
	static byte data[20000];
	msg_t m;
	int bits, csize;
	memset(data, 0x77, sizeof(data));
	memcpy(data + offset, payload, len);
	MSG_Init(&m, data, 16384);
	m.cursize = len + offset;
	scrubStack();
	Huff_Compress(&m, offset);
	csize = m.cursize;
	printf("%s compressed size=%d fnv=%08x head=", tag, csize, fnv(m.data, csize));
	hex(m.data, csize < 24 ? csize : 24);
	printf("\n");
	scrubStack();
	Huff_Decompress(&m, offset);
	printf("%s decompressed size=%d fnv=%08x same=%d\n", tag, m.cursize, fnv(m.data + offset, m.cursize - offset), m.cursize == len + offset && memcmp(m.data + offset, payload, len) == 0);
}

static void scenarioHuffman(void) {
	static byte payload[5000];
	byte buf[1024];
	msg_t m;
	int i, n;
	/* code lengths of the static tree */
	printf("huffman.bits");
	for (i = 0; i < 256; i++) {
		MSG_Init(&m, buf, 64);
		MSG_WriteBits(&m, i, 8);
		printf(" %d", m.bit);
	}
	printf("\n");
	MSG_Init(&m, buf, 1024);
	for (i = 0; i < 100; i++) MSG_WriteByte(&m, i * 2);
	for (i = 0; i < 100; i++) MSG_WriteByte(&m, 255 - i);
	dump("huffman.run", &m);
	MSG_BeginReading(&m);
	n = 0;
	for (i = 0; i < 200; i++) n += MSG_ReadByte(&m) * (i + 1);
	printf("huffman.runread %d readcount=%d bit=%d\n", n, m.readcount, m.bit);

	strcpy((char *)payload, "Hello, Quake III Arena! Hello, Quake III Arena!");
	huffCase("huffman.text", payload, 47, 0);
	memset(payload, 0, 300);
	huffCase("huffman.zeros", payload, 300, 5);
	for (i = 0; i < 512; i++) payload[i] = (byte)i;
	huffCase("huffman.ramp", payload, 512, 0);
	rs = 0xCAFEBABEu;
	for (i = 0; i < 3000; i++) payload[i] = (byte)(rnd() >> 24);
	huffCase("huffman.random", payload, 3000, 0);
	for (i = 0; i < 5000; i++) payload[i] = (byte)((rnd() >> 24) % 7);
	huffCase("huffman.skewed", payload, 5000, 12);
	payload[0] = 0;
	huffCase("huffman.one", payload, 1, 0);
	/* empty and truncated */
	{
		static byte data[64];
		MSG_Init(&m, data, 64);
		m.cursize = 4;
		Huff_Compress(&m, 4);
		printf("huffman.empty size=%d\n", m.cursize);
		Huff_Decompress(&m, 4);
		printf("huffman.emptyd size=%d\n", m.cursize);
		/* a truncated stream: claims 100 bytes but carries 3 */
		memset(data, 0, sizeof(data));
		data[0] = 0; data[1] = 100; data[2] = 0xff; data[3] = 0x13; data[4] = 0x55;
		MSG_Init(&m, data, 64);
		m.cursize = 5;
		scrubStack();
		Huff_Decompress(&m, 0);
		printf("huffman.truncated size=%d fnv=%08x\n", m.cursize, fnv(m.data, m.cursize));
		/* claims more than the buffer */
		memset(data, 0, sizeof(data));
		data[0] = 0xff; data[1] = 0xff; data[2] = 0x80;
		MSG_Init(&m, data, 64);
		m.cursize = 3;
		scrubStack();
		Huff_Decompress(&m, 0);
		printf("huffman.huge size=%d fnv=%08x\n", m.cursize, fnv(m.data, m.cursize));
	}
}

/* ------------------------------------------------------------------------ scenario: netchan */

static netadr_t addr;
static netchan_t cli, srv;

static void pattern(byte *p, int n, int seed) {
	int i;
	for (i = 0; i < n; i++) p[i] = (byte)(seed * 31 + i * 7 + (i >> 8));
}

static void printCaptured(const char *tag, int from) {
	int i;
	for (i = from; i < capturedCount; i++) {
		printf("%s packet %d sock=%d len=%d fnv=%08x head=", tag, i - from, captured[i].sock, captured[i].length, fnv(captured[i].data, captured[i].length));
		hex(captured[i].data, captured[i].length < 16 ? captured[i].length : 16);
		printf("\n");
	}
}

/* 4 bytes more than MAX_MSGLEN: the reassembled message is 4 bytes (sequence) + the fragments */
static byte processBuf[MAX_MSGLEN + 16];

static int process(const char *tag, netchan_t *chan, int idx) {
	msg_t m;
	int ret;
	memset(processBuf, 0, sizeof(processBuf));
	MSG_Init(&m, processBuf, MAX_MSGLEN);
	memcpy(processBuf, captured[idx].data, captured[idx].length);
	m.cursize = captured[idx].length;
	ret = Netchan_Process(chan, &m);
	printf("%s process %d -> %d dropped=%d in=%d fragseq=%d fraglen=%d size=%d readcount=%d bit=%d fnv=%08x\n", tag, idx, ret,
		chan->dropped, chan->incomingSequence, chan->fragmentSequence, chan->fragmentLength, m.cursize, m.readcount, m.bit, fnv(m.data, m.cursize));
	flushPrints(tag);
	return ret;
}

static void sendAll(netchan_t *chan, int len, int seed) {
	static byte payload[MAX_MSGLEN + 100];
	pattern(payload, len, seed);
	Netchan_Transmit(chan, len, payload);
	while (chan->unsentFragments) Netchan_TransmitNextFragment(chan);
}

static void scenarioNetchan(void) {
	int start, i;
	memset(&addr, 0, sizeof(addr));
	addr.type = NA_IP;
	addr.ip[0] = 127; addr.ip[3] = 1;
	addr.port = 27960;
	showpackets = &showpackets_value;
	showdrop = &showdrop_value;
	qport = &qport_value;
	qport->integer = 4242;

	Netchan_Setup(NS_CLIENT, &cli, addr, 4242);
	Netchan_Setup(NS_SERVER, &srv, addr, 0);
	printf("netchan.setup sock=%d qport=%d in=%d out=%d unsent=%d\n", cli.sock, cli.qport, cli.incomingSequence, cli.outgoingSequence, cli.unsentFragments);

	/* small messages in order, a duplicate, an empty one */
	capturedCount = 0;
	sendAll(&cli, 100, 1);
	sendAll(&cli, 0, 2);
	sendAll(&cli, 1299, 3);
	printCaptured("small", 0);
	for (i = 0; i < capturedCount; i++) process("small", &srv, i);
	process("small.dup", &srv, 1);
	printf("netchan.state out=%d unsentStart=%d\n", cli.outgoingSequence, cli.unsentFragmentStart);

	/* dropped packets: three sent, the last delivered */
	capturedCount = 0;
	sendAll(&cli, 10, 4);
	sendAll(&cli, 10, 5);
	sendAll(&cli, 10, 6);
	process("drop", &srv, 2);

	/* a big message in fragments */
	capturedCount = 0;
	sendAll(&cli, 3000, 7);
	printCaptured("big", 0);
	for (i = 0; i < capturedCount; i++) process("big", &srv, i);
	printf("netchan.state out=%d unsent=%d unsentStart=%d unsentLength=%d\n", cli.outgoingSequence, cli.unsentFragments, cli.unsentFragmentStart, cli.unsentLength);

	/* exact multiples of the fragment size */
	capturedCount = 0;
	sendAll(&cli, 2600, 8);
	printCaptured("exact", 0);
	for (i = 0; i < capturedCount; i++) process("exact", &srv, i);
	capturedCount = 0;
	sendAll(&cli, 1300, 9);
	printCaptured("one", 0);
	for (i = 0; i < capturedCount; i++) process("one", &srv, i);
	capturedCount = 0;
	sendAll(&cli, 16384, 10);
	printf("netchan.max packets=%d\n", capturedCount);
	for (i = 0; i < capturedCount; i++) process("max", &srv, i);

	/* fragments out of order: the second first, then the first, the second, the third */
	capturedCount = 0;
	sendAll(&cli, 3000, 11);
	process("order", &srv, 1);
	process("order", &srv, 0);
	process("order", &srv, 2);
	process("order", &srv, 1);
	process("order", &srv, 2);
	process("order", &srv, 2);

	/* a lost fragment, then the next message completes */
	capturedCount = 0;
	sendAll(&cli, 3000, 12);
	start = capturedCount;
	sendAll(&cli, 500, 13);
	process("lost", &srv, 0);
	process("lost", &srv, 2);
	process("lost", &srv, start);

	/* a bogus fragment length */
	capturedCount = 0;
	sendAll(&cli, 3000, 14);
	captured[0].data[8] = 0xff; captured[0].data[9] = 0x7f;
	process("bogus", &srv, 0);
	captured[1].data[6] = 0xff;
	process("bogus2", &srv, 1);
	captured[0].data[8] = 0xff; captured[0].data[9] = 0xff;
	process("bogus3", &srv, 0);

	/* the server sends to the client: no qport */
	capturedCount = 0;
	sendAll(&srv, 50, 15);
	sendAll(&srv, 2000, 16);
	printCaptured("server", 0);
	for (i = 0; i < capturedCount; i++) process("client", &cli, i);

	/* a too long message */
	if (setjmp(errjmp) == 0) Netchan_Transmit(&cli, MAX_MSGLEN + 1, processBuf); else printf("netchan.err %s\n", errtext);
	/* a packet shorter than the header */
	capturedCount = 0;
	captured[0].length = 3;
	memset(captured[0].data, 0, 8);
	capturedCount = 1;
	Netchan_Setup(NS_SERVER, &srv, addr, 0);
	process("short", &srv, 0);
	srv.incomingSequence = 2147483646;
	capturedCount = 0;
	cli.outgoingSequence = 2147483646;
	sendAll(&cli, 5, 17);
	sendAll(&cli, 5, 18);
	printCaptured("wrap", 0);
	for (i = 0; i < capturedCount; i++) process("wrap", &srv, i);
}

int main(void) {
	scenarioBits();
	scenarioOob();
	scenarioDelta();
	scenarioEntity();
	scenarioPlayer();
	scenarioHuffman();
	scenarioNetchan();
	return 0;
}
