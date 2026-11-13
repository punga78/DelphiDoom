/*
 * Driver of the parity tool of the server message parser (issue #121, second slice).
 * It is a small "server": it writes the messages of a demo (a gamestate, snapshots delta-compressed from
 * earlier ones, server commands, bad messages) with the REAL writers of msg.c, hands them to the REAL
 * CL_ParseServerMessage of cl_parse.c and prints, after every message, what the client state is.
 * Tests\Source\DelphiDoom.Tests.Net.ServerMessageParity.pas reads the messages (hex) from the output,
 * parses them with TQ3ServerMessageParser and compares the state line by line.
 */
#include "stubs.h"
#include "q3_types.inc"
#include "q3_parse_types.inc"

#define PACKET_BACKUP 32
#define PACKET_MASK (PACKET_BACKUP - 1)
#define MAX_PARSE_ENTITIES 2048
#define MAX_RELIABLE_COMMANDS 64
#define MAX_MAP_AREA_BYTES 32

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
static void NET_SendPacket(netsrc_t sock, int length, const void *data, netadr_t to) {}
static const char *NET_AdrToString(netadr_t a) { return "adr"; }

#include "q3_original.inc"

/* ------------------------------------------------------------------------ the client state */

typedef struct {
	qboolean		valid;
	int				snapFlags;
	int				serverTime;
	int				messageNum;
	int				deltaNum;
	int				ping;
	byte			areamask[MAX_MAP_AREA_BYTES];
	int				cmdNum;
	playerState_t	ps;
	int				numEntities;
	int				parseEntitiesNum;
	int				serverCommandNum;
} clSnapshot_t;

typedef struct {
	int p_cmdNumber;
	int p_serverTime;
	int p_realtime;
} outPacket_t;

typedef struct {
	clSnapshot_t	snap;
	qboolean		newSnapshots;
	gameState_t		gameState;
	outPacket_t		outPackets[PACKET_BACKUP];
	clSnapshot_t	snapshots[PACKET_BACKUP];
	entityState_t	entityBaselines[MAX_GENTITIES];
	entityState_t	parseEntities[MAX_PARSE_ENTITIES];
	int				parseEntitiesNum;
} clientActive_t;

typedef struct {
	int		serverCommandSequence;
	int		serverMessageSequence;
	qboolean demowaiting;
	int		reliableAcknowledge;
	int		reliableSequence;
	int		clientNum;
	int		checksumFeed;
	int		connectPacketCount;
	char	serverCommands[MAX_RELIABLE_COMMANDS][MAX_STRING_CHARS];
	struct { int outgoingSequence; } netchan;
} clientConnection_t;

typedef struct { int realtime; } clientStatic_t;

static clientActive_t cl;
static clientConnection_t clc;
static clientStatic_t cls;

#define SHOWNET(m, s)
static void Con_Close(void) {}
static void CL_ClearState(void) { memset(&cl, 0, sizeof(cl)); }
static void CL_SystemInfoChanged(void) {}
static void FS_ConditionalRestart(int checksumFeed) {}
static void CL_InitDownloads(void) {}
static void Cvar_Set(const char *name, const char *value) {}
static void CL_ParseDownload(msg_t *msg) {}

#include "q3_parse.inc"

/* ------------------------------------------------------------------------ helpers */

static unsigned fnvu(unsigned h, const byte *p, int n) {
	int i;
	for (i = 0; i < n; i++) {
		h ^= p[i];
		h *= 16777619u;
	}
	return h;
}
#define FNV_START 2166136261u

static void hex(const byte *p, int n) {
	int i;
	for (i = 0; i < n; i++) printf("%02x", p[i]);
}

static unsigned rs = 0x31415926u;
static unsigned rnd(void) {
	rs ^= rs << 13;
	rs ^= rs >> 17;
	rs ^= rs << 5;
	return rs;
}

static int asBits(float f) { int b; memcpy(&b, &f, 4); return b; }

static const float fpal[] = {0.0f, -0.0f, 1.0f, -1.0f, 100.0f, 4095.0f, -4096.0f, 4096.0f, -4097.0f, 3.14159f, 1e10f, -2.5f, 0.5f, 123456.0f};

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

static int entityFieldCount(void) { return sizeof(entityStateFields) / sizeof(entityStateFields[0]); }
static int playerFieldCount(void) { return sizeof(playerStateFields) / sizeof(playerStateFields[0]); }

static void randomEntity(entityState_t *s, int number, int all) {
	int j, nf = entityFieldCount();
	memset(s, 0, sizeof(*s));
	for (j = 0; j < nf; j++) {
		if (!all && rnd() % 2) continue;
		randomField((int *)((byte *)s + entityStateFields[j].offset), &entityStateFields[j]);
	}
	s->number = number;
}

static void mutateEntity(entityState_t *s) {
	int j, k = 1 + rnd() % 4, nf = entityFieldCount();
	for (j = 0; j < k; j++) {
		int n = rnd() % nf;
		randomField((int *)((byte *)s + entityStateFields[n].offset), &entityStateFields[n]);
	}
}

static void mutatePlayer(playerState_t *p) {
	int j, k = 1 + rnd() % 6, nf = playerFieldCount();
	for (j = 0; j < k; j++) {
		int n = rnd() % nf;
		randomField((int *)((byte *)p + playerStateFields[n].offset), &playerStateFields[n]);
	}
	for (j = 0; j < MAX_STATS; j++) if (rnd() % 5 == 0) p->stats[j] = (int)(rnd() % 2000) - 1000;
	for (j = 0; j < MAX_PERSISTANT; j++) if (rnd() % 5 == 0) p->persistant[j] = (int)(rnd() % 100000) - 50000;
	for (j = 0; j < MAX_POWERUPS; j++) if (rnd() % 7 == 0) p->powerups[j] = (int)rnd();
	for (j = 0; j < MAX_WEAPONS; j++) if (rnd() % 5 == 0) p->ammo[j] = (int)(rnd() % 400) - 100;
}

/* ------------------------------------------------------------------------ the server */

#define MAX_FRAME_ENTITIES 64
typedef struct {
	int n;
	entityState_t e[MAX_FRAME_ENTITIES];
	playerState_t ps;
} frame_t;

static entityState_t base[MAX_GENTITIES];
static frame_t hist[PACKET_BACKUP];
static frame_t current;
static byte msgData[MAX_MSGLEN];
static msg_t msg;
static int msgIndex;

static void startMessage(int ack) {
	memset(msgData, 0, sizeof(msgData));
	MSG_Init(&msg, msgData, sizeof(msgData));
	MSG_WriteLong(&msg, ack);
}

static void writeCommand(int seq, const char *text) {
	MSG_WriteByte(&msg, svc_serverCommand);
	MSG_WriteLong(&msg, seq);
	MSG_WriteString(&msg, text);
}

static void writeGamestate(int commandSeq, int clientNum, int checksumFeed, int bad) {
	int i;
	char big[700];
	MSG_WriteByte(&msg, svc_gamestate);
	MSG_WriteLong(&msg, commandSeq);
	MSG_WriteByte(&msg, svc_configstring);
	MSG_WriteShort(&msg, 0);
	MSG_WriteBigString(&msg, "\\sv_hostname\\test\\g_gametype\\3\\mapname\\q3dm1");
	MSG_WriteByte(&msg, svc_configstring);
	MSG_WriteShort(&msg, 1);
	MSG_WriteBigString(&msg, "\\sv_serverid\\1234\\timescale\\1");
	MSG_WriteByte(&msg, svc_configstring);
	MSG_WriteShort(&msg, 5);
	MSG_WriteBigString(&msg, "first");
	for (i = 0; i < 650; i++) big[i] = (char)('a' + (i % 26));
	big[650] = 0;
	MSG_WriteByte(&msg, svc_configstring);
	MSG_WriteShort(&msg, 33);
	MSG_WriteBigString(&msg, big);
	MSG_WriteByte(&msg, svc_configstring);
	MSG_WriteShort(&msg, 5);
	MSG_WriteBigString(&msg, "second");
	memset(base, 0, sizeof(base));
	{
		static const int numbers[3] = {10, 11, 200};
		for (i = 0; i < 3; i++) {
			entityState_t nullstate;
			memset(&nullstate, 0, sizeof(nullstate));
			randomEntity(&base[numbers[i]], numbers[i], 0);
			MSG_WriteByte(&msg, svc_baseline);
			MSG_WriteDeltaEntity(&msg, &nullstate, &base[numbers[i]], qtrue);
		}
	}
	if (bad == 1) {
		MSG_WriteByte(&msg, svc_configstring);
		MSG_WriteShort(&msg, 2000);
		MSG_WriteBigString(&msg, "out of range");
	}
	if (bad == 2) MSG_WriteByte(&msg, 77);
	MSG_WriteByte(&msg, svc_EOF);
	MSG_WriteLong(&msg, clientNum);
	MSG_WriteLong(&msg, checksumFeed);
}

static void emitSnapshot(int seq, int deltaNum, int flags, const frame_t *from) {
	int newIndex = 0, oldIndex = 0, oldCount = from ? from->n : 0;
	static const byte areaFill[4] = {0x00, 0xff, 0xaa, 0x55};
	byte area[MAX_MAP_AREA_BYTES];
	int i;
	MSG_WriteByte(&msg, svc_snapshot);
	MSG_WriteLong(&msg, seq * 50);
	MSG_WriteByte(&msg, deltaNum);
	MSG_WriteByte(&msg, flags);
	for (i = 0; i < MAX_MAP_AREA_BYTES; i++) area[i] = areaFill[(i + seq) % 4];
	MSG_WriteByte(&msg, MAX_MAP_AREA_BYTES);
	MSG_WriteData(&msg, area, MAX_MAP_AREA_BYTES);
	MSG_WriteDeltaPlayerstate(&msg, from ? &from->ps : NULL, &current.ps);
	while (newIndex < current.n || oldIndex < oldCount) {
		entityState_t *newent = newIndex < current.n ? &current.e[newIndex] : NULL;
		entityState_t *oldent = oldIndex < oldCount ? (entityState_t *)&from->e[oldIndex] : NULL;
		int newnum = newent ? newent->number : 9999;
		int oldnum = oldent ? oldent->number : 9999;
		if (newnum == oldnum) {
			MSG_WriteDeltaEntity(&msg, oldent, newent, qfalse);
			newIndex++;
			oldIndex++;
		} else if (newnum < oldnum) {
			MSG_WriteDeltaEntity(&msg, &base[newnum], newent, qtrue);
			newIndex++;
		} else {
			MSG_WriteDeltaEntity(&msg, oldent, NULL, qtrue);
			oldIndex++;
		}
	}
	MSG_WriteBits(&msg, MAX_GENTITIES - 1, GENTITYNUM_BITS);
}

/* a new frame: the previous one with some entities changed, removed and added */
static void evolve(int first) {
	int i, j;
	frame_t next;
	if (first) {
		memset(&current, 0, sizeof(current));
		for (i = 1; i <= 120 && current.n < 12; i++)
			if (rnd() % 8 == 0) randomEntity(&current.e[current.n++], i, 0);
		mutatePlayer(&current.ps);
		return;
	}
	memset(&next, 0, sizeof(next));
	next.ps = current.ps;
	for (i = 0; i < current.n; i++) {
		unsigned r = rnd() % 6;
		if (r == 0) continue; /* removed */
		next.e[next.n] = current.e[i];
		if (r < 3) mutateEntity(&next.e[next.n]);
		next.n++;
	}
	for (j = 0; j < 3 && next.n < MAX_FRAME_ENTITIES - 4; j++) {
		int num = 1 + rnd() % 230, at, dup = 0;
		for (i = 0; i < next.n; i++) if (next.e[i].number == num) dup = 1;
		if (dup || rnd() % 2) continue;
		for (at = 0; at < next.n && next.e[at].number < num; at++) ;
		memmove(&next.e[at + 1], &next.e[at], (next.n - at) * sizeof(entityState_t));
		randomEntity(&next.e[at], num, 0);
		next.n++;
	}
	if (rnd() % 3) mutatePlayer(&next.ps);
	current = next;
}

/* ------------------------------------------------------------------------ the client */

static unsigned hashConfigStrings(int *count) {
	unsigned h = FNV_START;
	int i;
	*count = 0;
	for (i = 0; i < MAX_CONFIGSTRINGS; i++) {
		if (cl.gameState.stringOffsets[i]) {
			const char *s = cl.gameState.stringData + cl.gameState.stringOffsets[i];
			byte idx[4];
			idx[0] = (byte)i; idx[1] = (byte)(i >> 8); idx[2] = 0; idx[3] = 0;
			h = fnvu(h, idx, 4);
			h = fnvu(h, (const byte *)s, (int)strlen(s) + 1);
			(*count)++;
		}
	}
	return h;
}

static void deliver(int seq) {
	int err = 0, n, i;
	unsigned h, he;
	byte zero[sizeof(entityState_t)];
	msg_t in;
	byte inData[MAX_MSGLEN];
	printf("demo.message %d seq=%d len=%d hex=", msgIndex, seq, msg.cursize);
	hex(msg.data, msg.cursize);
	printf("\n");
	memset(inData, 0, sizeof(inData));
	MSG_Init(&in, inData, sizeof(inData));
	memcpy(inData, msg.data, msg.cursize);
	in.cursize = msg.cursize;
	in.readcount = 0;
	clc.serverMessageSequence = seq;
	printbuf[0] = 0;
	if (setjmp(errjmp)) err = 1;
	else CL_ParseServerMessage(&in);
	{
		char *p;
		for (p = printbuf; *p; p++)
			if (*p == '\n') *p = '|';
	}
	printf("demo.parse %d err=%d prints=[%s]\n", msgIndex, err, printbuf);
	printf("demo.state %d ack=%d scs=%d cmd=[%s] dc=%d cn=%d cf=%d pe=%d\n", msgIndex, clc.reliableAcknowledge,
		clc.serverCommandSequence, clc.serverCommands[clc.serverCommandSequence & (MAX_RELIABLE_COMMANDS - 1)],
		cl.gameState.dataCount, clc.clientNum, clc.checksumFeed, cl.parseEntitiesNum);
	h = hashConfigStrings(&n);
	printf("demo.cs %d n=%d fnv=%08x\n", msgIndex, n, h);
	h = FNV_START;
	n = 0;
	memset(zero, 0, sizeof(zero));
	for (i = 0; i < MAX_GENTITIES; i++) {
		h = fnvu(h, (const byte *)&cl.entityBaselines[i], sizeof(entityState_t));
		if (memcmp(&cl.entityBaselines[i], zero, sizeof(zero))) n++;
	}
	printf("demo.bl %d n=%d fnv=%08x\n", msgIndex, n, h);
	he = FNV_START;
	for (i = 0; i < cl.snap.numEntities; i++)
		he = fnvu(he, (const byte *)&cl.parseEntities[(cl.snap.parseEntitiesNum + i) & (MAX_PARSE_ENTITIES - 1)], sizeof(entityState_t));
	printf("demo.snap %d valid=%d flags=%d time=%d msg=%d delta=%d scn=%d ne=%d pen=%d area=%08x ps=%08x ents=%08x\n",
		msgIndex, cl.snap.valid, cl.snap.snapFlags, cl.snap.serverTime, cl.snap.messageNum, cl.snap.deltaNum,
		cl.snap.serverCommandNum, cl.snap.numEntities, cl.snap.parseEntitiesNum,
		fnvu(FNV_START, cl.snap.areamask, MAX_MAP_AREA_BYTES), fnvu(FNV_START, (const byte *)&cl.snap.ps, sizeof(playerState_t)), he);
	msgIndex++;
}

/* one snapshot message: deltaFrom is the message number the server deltas from (0 = nothing) */
static void sendSnapshot(int seq, int deltaFrom, int deltaByte, int flags, int mutate) {
	const frame_t *from = deltaFrom ? &hist[deltaFrom & PACKET_MASK] : NULL;
	startMessage(seq * 3);
	if (mutate) evolve(0);
	emitSnapshot(seq, deltaByte, flags, from);
	MSG_WriteByte(&msg, svc_EOF);
	hist[seq & PACKET_MASK] = current;
	deliver(seq);
}

int main(void) {
	int seq, i;
	/* message 0: a server command, a nop and the gamestate */
	startMessage(3);
	writeCommand(1, "cs 3 \"abc\"");
	MSG_WriteByte(&msg, svc_nop);
	writeGamestate(5, 7, 0x12345678, 0);
	MSG_WriteByte(&msg, svc_EOF);
	deliver(1);

	/* the first snapshot has nothing to delta from */
	evolve(1);
	startMessage(6);
	emitSnapshot(2, 0, 1, NULL);
	MSG_WriteByte(&msg, svc_EOF);
	hist[2 & PACKET_MASK] = current;
	deliver(2);

	/* a command that is new (6), one already seen (5), and snapshots delta-compressed from the previous one */
	for (seq = 3; seq <= 14; seq++) {
		int from = (seq % 4 == 0) ? seq - 2 : seq - 1;
		if (from < 2) from = 2;
		startMessage(seq * 3);
		if (seq == 5) writeCommand(6, "chat \"hi\"");
		if (seq == 8) writeCommand(5, "old command");
		if (seq == 9) writeCommand(7, "print \"x\\n\"");
		evolve(0);
		emitSnapshot(seq, seq - from, seq % 3, &hist[from & PACKET_MASK]);
		MSG_WriteByte(&msg, svc_EOF);
		hist[seq & PACKET_MASK] = current;
		deliver(seq);
	}
	/* messages 14 to 19 were lost: a delta from 14 */
	sendSnapshot(20, 14, 6, 0, 1);
	/* a jump of more than PACKET_BACKUP messages: the old snapshots are invalidated */
	evolve(1);
	startMessage(180);
	emitSnapshot(60, 0, 4, NULL);
	MSG_WriteByte(&msg, svc_EOF);
	hist[60 & PACKET_MASK] = current;
	deliver(60);
	sendSnapshot(61, 60, 1, 0, 1);
	/* a delta from an invalid frame (the server writes full states) and from a frame that is too old */
	startMessage(186);
	evolve(0);
	emitSnapshot(62, 22, 0, NULL);
	MSG_WriteByte(&msg, svc_EOF);
	hist[62 & PACKET_MASK] = current;
	deliver(62);
	startMessage(189);
	evolve(0);
	emitSnapshot(63, 11, 0, NULL);
	MSG_WriteByte(&msg, svc_EOF);
	hist[63 & PACKET_MASK] = current;
	deliver(63);
	sendSnapshot(64, 0, 36, 0, 1);
	sendSnapshot(65, 0, 0, 0, 1);
	for (i = 66; i < 75; i++) sendSnapshot(i, i - 1, 1, i & 3, 1);
	/* bad messages */
	startMessage(300);
	MSG_WriteByte(&msg, 99);
	deliver(75);
	startMessage(300);
	writeGamestate(9, 1, 2, 1);
	MSG_WriteByte(&msg, svc_EOF);
	deliver(76);
	startMessage(300);
	writeGamestate(9, 1, 2, 2);
	MSG_WriteByte(&msg, svc_EOF);
	deliver(77);
	startMessage(300);
	MSG_WriteByte(&msg, svc_nop);
	deliver(78);
	/* a second gamestate (new map) and its first snapshot */
	startMessage(400);
	writeGamestate(20, 3, 0x7fffffff, 0);
	MSG_WriteByte(&msg, svc_EOF);
	deliver(80);
	evolve(1);
	startMessage(403);
	emitSnapshot(81, 0, 4, NULL);
	MSG_WriteByte(&msg, svc_EOF);
	hist[81 & PACKET_MASK] = current;
	deliver(81);
	sendSnapshot(82, 81, 1, 0, 1);
	return 0;
}
