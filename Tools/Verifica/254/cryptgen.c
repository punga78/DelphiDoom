/*
 * Issue #254, phase 3: what the REAL code of Quake III writes for the connection between a client and a server:
 * Com_HashKey, CL_WritePacket + CL_Netchan_Encode/Transmit (client to server), SV_Netchan_Encode + Netchan_Transmit
 * (server to client) and the decoders on the other side (SV_Netchan_Decode, CL_Netchan_Decode). The code is cut
 * out of the real files by build-crypt.sh (nothing retyped) over the msg.c, huffman.c and net_chan.c of
 * Tools/Verifica/121. Tests\Source\DelphiDoom.Tests.Q3Host.NetCrypt.pas does the same scenarios with the Delphi
 * classes and compares line by line. The golden is Tests/Data/Q3Host/netcrypt.golden.txt:
 *   H  <string hex> <maxlen> <hash>
 *   CW <k> <challenge> <serverId> <msgSeq> <cmdSeq> <relAck> <relSeq> <feed> <outSeq> <cmdNumber> <dup> <nodelta>
 *      <snapvalid> <snapmsgnum> <qport> <count of commands> <the commands hex> <datagram hex> <server decode hex>
 *   SE <k> <challenge> <outSeq> <lastcommand number> <payload hex> <datagram hex> <client decode hex>
 * The commands of the server are text(n, 1), the client commands text(n, 2).
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

#define MAX_RELIABLE_COMMANDS 64
#define PACKET_BACKUP 32
#define PACKET_MASK (PACKET_BACKUP - 1)
#define CMD_BACKUP 64
#define CMD_MASK (CMD_BACKUP - 1)
#define MAX_PACKET_USERCMDS 32
#define CA_CINEMATIC 8
#define SV_ENCODE_START 4
#define SV_DECODE_START 12
#define CL_ENCODE_START 12
#define CL_DECODE_START 4

enum clc_ops_e { clc_bad, clc_nop, clc_move, clc_moveNoDelta, clc_clientCommand, clc_EOF };

/* the parts of client_t, clientConnection_t, clientActive_t and clientStatic_t that the real functions read */
typedef struct {
	netchan_t netchan;
	char lastClientCommandString[1024];
	int challenge;
	char reliableCommands[MAX_RELIABLE_COMMANDS][1024];
} client_t;

typedef struct { int p_cmdNumber; int p_serverTime; int p_realtime; } outPacket_t;
static struct {
	int challenge;
	qboolean demoplaying, demowaiting;
	int serverMessageSequence, serverCommandSequence, reliableAcknowledge, reliableSequence, checksumFeed;
	int lastPacketSentTime;
	char reliableCommands[MAX_RELIABLE_COMMANDS][1024];
	char serverCommands[MAX_RELIABLE_COMMANDS][1024];
	netchan_t netchan;
} clc;
static struct {
	int serverId, cmdNumber;
	usercmd_t cmds[CMD_BACKUP];
	outPacket_t outPackets[PACKET_BACKUP];
	struct { qboolean valid; int messageNum; } snap;
} cl;
static struct { int state, realtime; } cls;
static cvar_t cl_packetdup_v, cl_showSend_v, cl_nodelta_v;
static cvar_t *cl_packetdup = &cl_packetdup_v, *cl_showSend = &cl_showSend_v, *cl_nodelta = &cl_nodelta_v;
static void Cvar_Set(const char *name, const char *value) { }
static int newsize;
#define svc_EOF 8
#define Com_DPrintf Com_Printf
static void CL_Netchan_TransmitNextFragment(netchan_t *chan) { Netchan_TransmitNextFragment(chan); }

#include "crypt_real.inc"

static void hex(const byte *p, int n) {
	int i;
	for (i = 0; i < n; i++) printf("%02x", p[i]);
	if (n == 0) printf("-");
}
static unsigned rs = 0x2468ace1u;
static unsigned rnd(void) {
	rs ^= rs << 13;
	rs ^= rs >> 17;
	rs ^= rs << 5;
	return rs;
}
static void text(char *buf, int n, int variant) {
	sprintf(buf, "cs %d v%d", n, variant);
	if (n % 3 == 0) strcat(buf, "%x");
	if (n % 5 == 0) strcat(buf, "\xe9z");
}

static void scenarioHash(void) {
	static const char *strings[] = { "", "a", "say hello", "cs 12 \"x\"", "%%%", "\xe9\xff\x80z", "scores 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20" };
	int i, m;
	for (i = 0; i < (int)(sizeof(strings) / sizeof(strings[0])); i++) {
		for (m = 0; m < 3; m++) {
			int maxlen = m == 0 ? 32 : (m == 1 ? 3 : 1000);
			printf("H ");
			hex((const byte *)strings[i], (int)strlen(strings[i]));
			printf(" %d %d\n", maxlen, Com_HashKey((char *)strings[i], maxlen));
		}
	}
}

static void scenarioClient(int k) {
	netadr_t adr;
	msg_t datagram, srvmsg;
	byte srvbuf[MAX_MSGLEN + 4];
	int i, n, outSeq, first, qportNumber;
	client_t sv;
	netchan_t svchan;

	memset(&clc, 0, sizeof(clc));
	memset(&cl, 0, sizeof(cl));
	memset(&cls, 0, sizeof(cls));
	memset(&adr, 0, sizeof(adr));
	adr.type = NA_LOOPBACK;
	qportNumber = 1000 + k;
	qport_value.integer = qportNumber;
	Netchan_Setup(NS_CLIENT, &clc.netchan, adr, qportNumber);
	clc.challenge = (int)rnd();
	cl.serverId = (int)(rnd() & 0xffff);
	clc.serverMessageSequence = k + 3;
	clc.serverCommandSequence = 5 + k;
	clc.reliableSequence = 2 + k;
	clc.reliableAcknowledge = k % 2;
	clc.checksumFeed = (int)rnd();
	outSeq = 7 + k;
	clc.netchan.outgoingSequence = outSeq;
	cl.cmdNumber = 6 + k;
	cl_packetdup_v.integer = k % 3;
	cl_nodelta_v.integer = (k == 4);
	cl.snap.valid = (k != 2);
	cl.snap.messageNum = (k == 3) ? clc.serverMessageSequence + 1 : clc.serverMessageSequence;
	for (i = 1; i <= 64; i++) {
		text(clc.serverCommands[i & (MAX_RELIABLE_COMMANDS - 1)], i, 1);
		text(clc.reliableCommands[i & (MAX_RELIABLE_COMMANDS - 1)], i, 2);
	}
	for (i = 0; i < CMD_BACKUP; i++) {
		usercmd_t *c = &cl.cmds[i];
		c->serverTime = 1000 + i * 8 + (int)(rnd() % 4);
		c->angles[0] = (int)(rnd() % 65536); c->angles[1] = (int)(rnd() % 65536); c->angles[2] = 0;
		c->buttons = (int)(rnd() % 8);
		c->weapon = (byte)(rnd() % 9);
		c->forwardmove = (signed char)((int)(rnd() % 255) - 127);
		c->rightmove = (signed char)((int)(rnd() % 255) - 127);
		c->upmove = (signed char)((int)(rnd() % 3) - 1);
	}
	/* the packets before this one remember how far their commands went */
	for (i = 0; i < PACKET_BACKUP; i++) cl.outPackets[i].p_cmdNumber = cl.cmdNumber - 1 - (i % 5);
	capturedCount = 0;
	if (setjmp(errjmp) == 0) {
		CL_WritePacket();
	} else {
		printf("CW %d error %s\n", k, errtext);
		return;
	}
	/* how many commands the packet has: the real function does the sums; recompute it from the same state */
	{
		int oldPacketNum = (outSeq - 1 - cl_packetdup_v.integer) & PACKET_MASK;
		n = cl.cmdNumber - cl.outPackets[oldPacketNum].p_cmdNumber;
		if (n > MAX_PACKET_USERCMDS) n = MAX_PACKET_USERCMDS;
		if (n < 0) n = 0;
	}
	printf("CW %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d ", k, clc.challenge, cl.serverId,
		clc.serverMessageSequence, clc.serverCommandSequence, clc.reliableAcknowledge, clc.reliableSequence,
		clc.checksumFeed, outSeq, cl.cmdNumber, cl_packetdup_v.integer, cl_nodelta_v.integer, cl.snap.valid,
		cl.snap.messageNum, qportNumber, n);
	first = cl.cmdNumber - n + 1;
	/* the commands that went in the packet, 24 bytes each, as the Delphi record lays them out */
	for (i = 0; i < n; i++) {
		usercmd_t *c = &cl.cmds[(first + i) & CMD_MASK];
		byte raw[24];
		memset(raw, 0, sizeof(raw));
		memcpy(raw + 0, &c->serverTime, 4);
		memcpy(raw + 4, &c->angles[0], 4);
		memcpy(raw + 8, &c->angles[1], 4);
		memcpy(raw + 12, &c->angles[2], 4);
		memcpy(raw + 16, &c->buttons, 4);
		raw[20] = c->weapon;
		raw[21] = (byte)c->forwardmove;
		raw[22] = (byte)c->rightmove;
		raw[23] = (byte)c->upmove;
		hex(raw, 24);
		if (i + 1 < n) printf(",");
	}
	if (n == 0) printf("-");
	printf(" ");
	hex(captured[0].data, captured[0].length);
	/* the server reads the datagram: Netchan_Process, SV_Netchan_Decode with its own copy of the commands */
	memset(&sv, 0, sizeof(sv));
	Netchan_Setup(NS_SERVER, &sv.netchan, adr, qportNumber);
	sv.netchan.incomingSequence = outSeq - 1;
	sv.challenge = clc.challenge;
	for (i = 1; i <= 64; i++) text(sv.reliableCommands[i & (MAX_RELIABLE_COMMANDS - 1)], i, 1);
	memset(srvbuf, 0, sizeof(srvbuf));
	MSG_Init(&srvmsg, srvbuf, sizeof(srvbuf));
	memcpy(srvbuf, captured[0].data, captured[0].length);
	srvmsg.cursize = captured[0].length;
	(void)datagram;
	(void)svchan;
	if (SV_Netchan_Process(&sv, &srvmsg)) {
		printf(" ");
		hex(srvbuf + srvmsg.readcount, srvmsg.cursize - srvmsg.readcount);
	} else printf(" rejected");
	printf("\n");
}

static void scenarioServer(int k) {
	netadr_t adr;
	msg_t msg, back;
	byte buf[MAX_MSGLEN + 4], backbuf[MAX_MSGLEN + 4], payload[1024];
	client_t sv;
	int i, size, outSeq, lastCmd;

	memset(&adr, 0, sizeof(adr));
	adr.type = NA_LOOPBACK;
	memset(&sv, 0, sizeof(sv));
	Netchan_Setup(NS_SERVER, &sv.netchan, adr, 1234);
	outSeq = 3 + k * 2;
	sv.netchan.outgoingSequence = outSeq;
	sv.challenge = (int)rnd();
	lastCmd = 4 + k;
	text(sv.lastClientCommandString, lastCmd, 2);
	/* the payload: reliableAcknowledge as the message writes it, then bytes */
	size = 1 + (int)(rnd() % (k == 5 ? 1200 : 150));
	MSG_Init(&msg, buf, sizeof(buf));
	msg.allowoverflow = qtrue;
	MSG_Bitstream(&msg);
	MSG_WriteLong(&msg, lastCmd);
	for (i = 0; i < size; i++) payload[i % 1024] = (byte)rnd();
	MSG_WriteData(&msg, payload, size < 1024 ? size : 1024);
	MSG_WriteByte(&msg, svc_EOF);
	capturedCount = 0;
	{
		byte plain[MAX_MSGLEN];
		int plainLen = msg.cursize;
		memcpy(plain, msg.data, plainLen);
		SV_Netchan_Encode(&sv, &msg);
		Netchan_Transmit(&sv.netchan, msg.cursize, msg.data);
		printf("SE %d %d %d %d ", k, sv.challenge, outSeq, lastCmd);
		hex(plain, plainLen);
	}
	printf(" ");
	hex(captured[0].data, captured[0].length);
	/* the client reads it (a message that was fragmented is not read: the first fragment is not the message) */
	memset(&clc, 0, sizeof(clc));
	Netchan_Setup(NS_CLIENT, &clc.netchan, adr, 1234);
	clc.challenge = sv.challenge;
	for (i = 1; i <= 64; i++) text(clc.reliableCommands[i & (MAX_RELIABLE_COMMANDS - 1)], i, 2);
	memset(backbuf, 0, sizeof(backbuf));
	MSG_Init(&back, backbuf, sizeof(backbuf));
	memcpy(backbuf, captured[0].data, captured[0].length);
	back.cursize = captured[0].length;
	if (CL_Netchan_Process(&clc.netchan, &back)) {
		printf(" ");
		hex(backbuf + back.readcount, back.cursize - back.readcount);
	} else printf(" rejected");
	printf("\n");
}

int main(void) {
	int k;
	showpackets = &showpackets_value;
	showdrop = &showdrop_value;
	qport = &qport_value;
	scenarioHash();
	for (k = 0; k < 6; k++) scenarioClient(k);
	for (k = 0; k < 6; k++) scenarioServer(k);
	return 0;
}
