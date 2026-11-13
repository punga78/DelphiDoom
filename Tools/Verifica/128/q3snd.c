/*
 * Parity driver of the issue #128: runs a script of operations on the sound code of
 * Quake III (the functions of snd_original.inc, which are the original ones) and prints
 * what it did, so that Libs\Audio can be compared with it.
 *
 *   q3snd gen <scenario 0..3> <seed>   writes a script (random but fixed by the seed)
 *   q3snd run <script>                 runs a script and prints the golden lines
 *
 * Floats in the script are the hexadecimal bits of the single precision value.
 */
#include "stubs.h"
#include "snd_original.inc"

typedef unsigned long long u64;

static unsigned g_lcg;
static unsigned lcg(void) { g_lcg = g_lcg * 1103515245u + 12345u; return g_lcg >> 16; }
static int rnd(int lo, int hi) { return lo + (int)(lcg() % (unsigned)(hi - lo + 1)); }

static unsigned fbits(float f) { unsigned u; memcpy(&u, &f, 4); return u; }
static float bitsf(unsigned u) { float f; memcpy(&f, &u, 4); return f; }

/* FNV-1a 64 bit */
static u64 fnv(u64 h, const void *data, size_t n) {
	const byte *p = (const byte *)data;
	size_t i;
	for (i = 0; i < n; i++) { h ^= p[i]; h *= 0x100000001b3ULL; }
	return h;
}
#define FNV0 0xcbf29ce484222325ULL
static u64 fint(u64 h, int v) { return fnv(h, &v, 4); }
static u64 ffloat(u64 h, float v) { unsigned u = fbits(v); return fnv(h, &u, 4); }

static int sfxIndex(sfx_t *s) { return s ? (int)(s - s_knownSfx) : -1; }

static u64 digestChannels(void) {
	u64 h = FNV0;
	int i;
	for (i = 0; i < MAX_CHANNELS; i++) {
		channel_t *c = &s_channels[i];
		if (!c->thesfx) continue;
		h = fint(h, i); h = fint(h, c->allocTime); h = fint(h, c->startSample);
		h = fint(h, c->entnum); h = fint(h, c->entchannel); h = fint(h, c->leftvol);
		h = fint(h, c->rightvol); h = fint(h, c->master_vol); h = fint(h, c->fixed_origin);
		if (c->fixed_origin) { h = ffloat(h, c->origin[0]); h = ffloat(h, c->origin[1]); h = ffloat(h, c->origin[2]); }
		h = fint(h, sfxIndex(c->thesfx)); h = fint(h, c->doppler);
	}
	return h;
}

static u64 digestLoops(void) {
	u64 h = FNV0;
	int i;
	h = fint(h, numLoopChannels);
	for (i = 0; i < numLoopChannels; i++) {
		channel_t *c = &loop_channels[i];
		h = fint(h, c->master_vol); h = fint(h, c->leftvol); h = fint(h, c->rightvol);
		h = fint(h, sfxIndex(c->thesfx)); h = fint(h, c->doppler);
		h = ffloat(h, c->dopplerScale); h = ffloat(h, c->oldDopplerScale);
	}
	return h;
}

static u64 digestDma(void) {
	return fnv(FNV0, dma.buffer, (size_t)dma.samples * dma.samplebits / 8);
}

static u64 digestRaw(void) {
	return fnv(FNV0, s_rawsamples, sizeof(s_rawsamples));
}

/* ---------------------------------------------------------------- generator */

static void genvec(FILE *o, const char *name, int a, int b, int c) {
	fprintf(o, "%s", name);
	(void)a; (void)b; (void)c;
}

static void gen(int scenario, unsigned seed) {
	FILE *o = stdout;
	int ms = 1000, frame = 10, pos = 0, steps, i, n, dirty = 0, moved = 0;
	int dmaCh = 2, dmaSamples = 16384, dmaBits = 16, dmaSpeed = 22050, dmaChunk = 1024;
	int rates[5] = { 11025, 22050, 44100, 8000, 33075 };
	float vol = 0.8f, ahead = 0.2f, prestep = 0.05f;
	int doppler = 1, entMax = 8, sfxCount = 8, bigVel = 0;
	g_lcg = seed;
	if (scenario == 1) { dmaCh = 1; dmaSamples = 4096; dmaBits = 8; dmaSpeed = 11025; dmaChunk = 256; vol = 0.5f; }
	if (scenario == 2) { dmaSamples = 8192; dmaChunk = 128; entMax = 3; sfxCount = 4; }
	if (scenario == 4) { sfxCount = 8; entMax = 12; steps = 900; }
	if (scenario == 3) { dmaSamples = 32768; bigVel = 1; vol = 1.0f; dmaBits = 8; }
	if (scenario != 4) steps = 500;
	fprintf(o, "dma %d %d %d %d %d\n", dmaCh, dmaSamples, dmaBits, dmaSpeed, dmaChunk);
	fprintf(o, "cvar %08x %08x %08x %d 0\n", fbits(vol), fbits(ahead), fbits(prestep), doppler);
	for (i = 0; i < sfxCount; i++)
		fprintf(o, "sfx %d %d %d %d %u\n", i, rates[rnd(0, 4)], rnd(1, 2), rnd(300, 3000), lcg());
	fprintf(o, "init\n");
	fprintf(o, "time %d %d\n", ms, frame);
	for (i = 0; i < steps; i++) {
		int w = rnd(0, 99);
		if (scenario == 4) {
			/* channel pressure: many starts, few mixes, so that the 96 channels fill up */
			if (w < 75) {
				fprintf(o, "start %d %d %d %d %08x %08x %08x\n", rnd(0, 5), rnd(0, 7), rnd(0, sfxCount - 1), rnd(0, 1),
					fbits((float)rnd(-900, 900)), fbits((float)rnd(-900, 900)), fbits((float)rnd(-100, 100)));
				dirty = 1;
			} else if (w < 85) {
				ms += rnd(30, 200); frame++;
				fprintf(o, "time %d %d\n", ms, frame);
			} else if (w < 92) {
				fprintf(o, "listener %d %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x\n", rnd(0, 5),
					fbits((float)rnd(-200, 200)), fbits((float)rnd(-200, 200)), fbits(0), fbits(1), fbits(0), fbits(0),
					fbits(0), fbits(1), fbits(0), fbits(0), fbits(0), fbits(1));
			} else if (w < 96) {
				fprintf(o, "update\n");
			} else {
				pos = (pos + rnd(1000, 6000)) % dmaSamples; moved = 1;
				fprintf(o, "dmapos %d\n", pos);
			}
			continue;
		}
		if (w < 10) {
			ms += rnd(1, 120); frame++;
			fprintf(o, "time %d %d\n", ms, frame);
		} else if (w < 16) {
			pos = (pos + rnd(100, 1500)) % dmaSamples; moved = 1;
			fprintf(o, "dmapos %d\n", pos);
		} else if (w < 22) {
			float yaw = rnd(0, 359) * 3.14159265f / 180.0f;
			float c = cosf(yaw), s = sinf(yaw);
			/* axis[0] forward, axis[1] left, axis[2] up */
			fprintf(o, "listener %d %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x\n",
				rnd(0, entMax - 1), fbits((float)rnd(-200, 200)), fbits((float)rnd(-200, 200)), fbits((float)rnd(-50, 50)),
				fbits(c), fbits(s), fbits(0), fbits(-s), fbits(c), fbits(0), fbits(0), fbits(0), fbits(1));
		} else if (w < 40) {
			int hasOrigin = rnd(0, 1);
			fprintf(o, "start %d %d %d %d %08x %08x %08x\n", rnd(0, entMax - 1), rnd(0, 7), rnd(0, sfxCount - 1), hasOrigin,
				fbits((float)rnd(-900, 900)), fbits((float)rnd(-900, 900)), fbits((float)rnd(-100, 100)));
			dirty = 1;
		} else if (w < 44) {
			fprintf(o, "local %d %d\n", rnd(0, sfxCount - 1), rnd(0, 7));
			dirty = 1;
		} else if (w < 56) {
			int vel = rnd(0, 2) == 0 ? 0 : (bigVel ? 4000 : 300);
			fprintf(o, "%s %d %d %08x %08x %08x %08x %08x %08x\n", rnd(0, 3) ? "loop" : "rloop", rnd(0, entMax + 3), rnd(0, sfxCount - 1),
				fbits((float)rnd(100, 700) * (rnd(0, 1) ? 1 : -1)), fbits((float)rnd(100, 700)), fbits((float)rnd(-50, 50)),
				fbits((float)(vel ? rnd(-vel, vel) : 0)), fbits((float)(vel ? rnd(-vel, vel) : 0)), fbits(0.0f));
		} else if (w < 59) {
			fprintf(o, "clearloop %d\n", rnd(0, 4) == 0);
		} else if (w < 62) {
			fprintf(o, "stoploop %d\n", rnd(0, entMax + 3));
		} else if (w < 64) {
			fprintf(o, "entpos %d %08x %08x %08x\n", rnd(0, entMax + 3), fbits((float)rnd(-500, 500)), fbits((float)rnd(-500, 500)), fbits(0.0f));
		} else if (w < 69) {
			fprintf(o, "raw %d %d %d %d %u %08x\n", rnd(1, 600), rates[rnd(0, 4)], rnd(1, 2), rnd(1, 2), lcg(), fbits(rnd(0, 1) ? 1.0f : 0.25f));
		} else if (w < 73) {
			fprintf(o, "spatial %08x %08x %08x %d\n", fbits((float)rnd(-3000, 3000)), fbits((float)rnd(-3000, 3000)), fbits((float)rnd(-300, 300)), rnd(0, 1) ? 127 : 90);
		} else if (w < 74) {
			fprintf(o, "clearbuf\n");
			dirty = 0;
		} else if (w < 77 && !dirty) {
			fprintf(o, "paint %d\n", rnd(1, 6000));
		} else {
			fprintf(o, "update\n");
			if (moved) dirty = 0;
			moved = 0;
		}
	}
	(void)n; (void)genvec;
}

/* ---------------------------------------------------------------- runner */

static void printState(int op) {
	int i, active = 0, doppler = 0;
	for (i = 0; i < MAX_CHANNELS; i++) if (s_channels[i].thesfx) active++;
	for (i = 0; i < numLoopChannels; i++) if (loop_channels[i].doppler) doppler++;
	printf("op %d chan %016llx loop %016llx active %d num %d doppler %d painted %d soundtime %d rawend %d\n", op,
		digestChannels(), digestLoops(), active, numLoopChannels, doppler, s_paintedtime, s_soundtime, s_rawend);
	if (getenv("Q3SND_VERBOSE"))
		for (i = 0; i < numLoopChannels; i++)
			printf("  loop %d master %d left %d right %d sfx %d doppler %d scale %08x old %08x\n", i,
				loop_channels[i].master_vol, loop_channels[i].leftvol, loop_channels[i].rightvol,
				sfxIndex(loop_channels[i].thesfx), loop_channels[i].doppler,
				fbits(loop_channels[i].dopplerScale), fbits(loop_channels[i].oldDopplerScale));
}

static int run(const char *path) {
	FILE *f = fopen(path, "r");
	char word[32];
	int op = 0;
	if (!f) { fprintf(stderr, "cannot open %s\n", path); return 1; }
	s_volume = calloc(1, sizeof(cvar_t)); s_testsound = calloc(1, sizeof(cvar_t));
	s_show = calloc(1, sizeof(cvar_t)); s_mixahead = calloc(1, sizeof(cvar_t));
	s_mixPreStep = calloc(1, sizeof(cvar_t)); s_doppler = calloc(1, sizeof(cvar_t));
	while (fscanf(f, "%31s", word) == 1) {
		op++; fflush(stdout);
		if (!strcmp(word, "dma")) {
			fscanf(f, "%d %d %d %d %d", &dma.channels, &dma.samples, &dma.samplebits, &dma.speed, &dma.submission_chunk);
			dma.buffer = calloc(dma.samples, 2);
			continue;
		} else if (!strcmp(word, "cvar")) {
			unsigned a, b, c; int d, e;
			fscanf(f, "%x %x %x %d %d", &a, &b, &c, &d, &e);
			s_volume->value = bitsf(a); s_mixahead->value = bitsf(b); s_mixPreStep->value = bitsf(c);
			s_doppler->integer = d; s_testsound->integer = e;
			continue;
		} else if (!strcmp(word, "sfx")) {
			int idx, rate, width, count; unsigned seed, k;
			byte *data; sfx_t *s;
			fscanf(f, "%d %d %d %d %u", &idx, &rate, &width, &count, &seed);
			data = malloc((size_t)count * width);
			g_lcg = seed;
			for (k = 0; k < (unsigned)(count * width); k++) data[k] = (byte)lcg();
			s = &s_knownSfx[idx];
			memset(s, 0, sizeof(*s));
			sprintf(s->soundName, "s%d", idx);
			s->inMemory = qtrue;
			s->soundLength = count;
			ResampleSfx(s, rate, width, data, qfalse);
			free(data);
			if (idx + 1 > s_numSfx) s_numSfx = idx + 1;
			printf("op %d sfx %d length %d\n", op, idx, s->soundLength);
			continue;
		} else if (!strcmp(word, "init")) {
			s_soundStarted = 1; s_soundMuted = 0; s_soundtime = 0; s_paintedtime = 0;
			S_ClearSoundBuffer();
		} else if (!strcmp(word, "time")) {
			fscanf(f, "%d %d", &g_ms, &cls.framecount);
		} else if (!strcmp(word, "dmapos")) {
			fscanf(f, "%d", &g_dmapos);
		} else if (!strcmp(word, "listener")) {
			unsigned b[12]; int ent, k; vec3_t head; vec3_t axis[3];
			fscanf(f, "%d", &ent);
			for (k = 0; k < 12; k++) fscanf(f, "%x", &b[k]);
			head[0] = bitsf(b[0]); head[1] = bitsf(b[1]); head[2] = bitsf(b[2]);
			for (k = 0; k < 9; k++) axis[k / 3][k % 3] = bitsf(b[3 + k]);
			S_Respatialize(ent, head, axis, 0);
		} else if (!strcmp(word, "entpos")) {
			int ent; unsigned x, y, z; vec3_t o;
			fscanf(f, "%d %x %x %x", &ent, &x, &y, &z);
			o[0] = bitsf(x); o[1] = bitsf(y); o[2] = bitsf(z);
			S_UpdateEntityPosition(ent, o);
		} else if (!strcmp(word, "start")) {
			int ent, chan, sfx, has; unsigned x, y, z; vec3_t o;
			fscanf(f, "%d %d %d %d %x %x %x", &ent, &chan, &sfx, &has, &x, &y, &z);
			o[0] = bitsf(x); o[1] = bitsf(y); o[2] = bitsf(z);
			S_StartSound(has ? o : NULL, ent, chan, sfx);
		} else if (!strcmp(word, "local")) {
			int sfx, chan;
			fscanf(f, "%d %d", &sfx, &chan);
			S_StartLocalSound(sfx, chan);
		} else if (!strcmp(word, "loop") || !strcmp(word, "rloop")) {
			int ent, sfx; unsigned b[6]; int k; vec3_t o, v;
			fscanf(f, "%d %d", &ent, &sfx);
			for (k = 0; k < 6; k++) fscanf(f, "%x", &b[k]);
			o[0] = bitsf(b[0]); o[1] = bitsf(b[1]); o[2] = bitsf(b[2]);
			v[0] = bitsf(b[3]); v[1] = bitsf(b[4]); v[2] = bitsf(b[5]);
			if (!strcmp(word, "loop")) S_AddLoopingSound(ent, o, v, sfx);
			else S_AddRealLoopingSound(ent, o, v, sfx);
		} else if (!strcmp(word, "clearloop")) {
			int k; fscanf(f, "%d", &k);
			S_ClearLoopingSounds(k);
		} else if (!strcmp(word, "stoploop")) {
			int k; fscanf(f, "%d", &k);
			S_StopLoopingSound(k);
		} else if (!strcmp(word, "raw")) {
			int n, rate, width, ch, k; unsigned seed, vb; byte *data;
			fscanf(f, "%d %d %d %d %u %x", &n, &rate, &width, &ch, &seed, &vb);
			data = malloc((size_t)n * width * ch);
			g_lcg = seed;
			for (k = 0; k < n * width * ch; k++) data[k] = (byte)lcg();
			S_RawSamples(n, rate, width, ch, data, bitsf(vb));
			free(data);
			printState(op);
			printf("op %d raw %016llx\n", op, digestRaw());
			continue;
		} else if (!strcmp(word, "spatial")) {
			unsigned x, y, z; int master, l, r; vec3_t o;
			fscanf(f, "%x %x %x %d", &x, &y, &z, &master);
			o[0] = bitsf(x); o[1] = bitsf(y); o[2] = bitsf(z);
			S_SpatializeOrigin(o, master, &l, &r);
			printf("op %d spatial %d %d\n", op, l, r);
			continue;
		} else if (!strcmp(word, "clearbuf")) {
			S_ClearSoundBuffer();
			printState(op);
			printf("op %d dma %016llx\n", op, digestDma());
			continue;
		} else if (!strcmp(word, "update")) {
			S_Update_();
			printState(op);
			printf("op %d dma %016llx\n", op, digestDma());
			continue;
		} else if (!strcmp(word, "paint")) {
			int rel;
			fscanf(f, "%d", &rel);
			S_PaintChannels(s_paintedtime + rel);
			printState(op);
			printf("op %d dma %016llx\n", op, digestDma());
			continue;
		} else {
			fprintf(stderr, "bad word %s\n", word);
			return 2;
		}
		printState(op);
	}
	fclose(f);
	return 0;
}

int main(int argc, char **argv) {
	if (argc == 4 && !strcmp(argv[1], "gen")) { gen(atoi(argv[2]), (unsigned)strtoul(argv[3], NULL, 10)); return 0; }
	if (argc == 3 && !strcmp(argv[1], "run")) { return run(argv[2]); }
	fprintf(stderr, "usage: q3snd gen <scenario> <seed> | run <script>\n");
	return 1;
}
