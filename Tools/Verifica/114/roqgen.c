/*
 * Generator of small synthetic RoQ files for the parity tests of the issue #114.
 * The content is random (fixed seeds) and made by this program: there is no
 * commercial material. The files only use what the decoder of the original
 * accepts without reading outside of its buffers (the motion vectors that
 * would are not generated).
 *
 *   roqgen basic|wide|stereo out.roq
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned char byte;

static unsigned int g_seed = 1;
static unsigned int rnd(void) {
	g_seed = g_seed * 1664525u + 1013904223u;
	return g_seed >> 8;
}

static byte g_out[1 << 20];
static int g_outPos = 0;

static void put8(byte *b, int *p, int v) { b[(*p)++] = (byte)v; }

static void chunk_begin(int id, int flags, int *start) {
	*start = g_outPos;
	put8(g_out, &g_outPos, id & 255);
	put8(g_out, &g_outPos, id >> 8);
	g_outPos += 4; /* size, filled by chunk_end */
	put8(g_out, &g_outPos, flags & 255);
	put8(g_out, &g_outPos, (flags >> 8) & 255);
}

static void chunk_end(int start) {
	int size = g_outPos - start - 8;
	g_out[start + 2] = size & 255;
	g_out[start + 3] = (size >> 8) & 255;
	g_out[start + 4] = (size >> 16) & 255;
	g_out[start + 5] = (size >> 24) & 255;
}

static int g_width, g_height, g_numQuads = -1;

static void info(int w, int h) {
	int s;
	chunk_begin(0x1001, 0, &s);
	put8(g_out, &g_outPos, w & 255); put8(g_out, &g_outPos, w >> 8);
	put8(g_out, &g_outPos, h & 255); put8(g_out, &g_outPos, h >> 8);
	put8(g_out, &g_outPos, 8); put8(g_out, &g_outPos, 0);
	put8(g_out, &g_outPos, 4); put8(g_out, &g_outPos, 0);
	chunk_end(s);
	/* the numQuads of the original */
	if (g_numQuads == -1) { g_width = w; g_height = h; }
	if (g_numQuads != 1) g_numQuads = 0;
}

static int g_effectiveTwo = 0;

static void codebook(int two, int four) {
	int s, i, flags, eff;
	if (two == 0 && four == 0) { flags = 0; eff = 256; four = 256; }
	else { flags = (two << 8) | four; eff = two ? two : 256; }
	chunk_begin(0x1002, flags, &s);
	for (i = 0; i < eff; i++) {
		int k;
		for (k = 0; k < 6; k++) put8(g_out, &g_outPos, rnd() & 255);
	}
	for (i = 0; i < four * 2 * 2; i++) put8(g_out, &g_outPos, rnd() % eff);
	chunk_end(s);
	if (g_effectiveTwo < eff) g_effectiveTwo = eff;
}

static void audio(int id, int size, int flags) {
	int s, i;
	chunk_begin(id, flags, &s);
	for (i = 0; i < size; i++) put8(g_out, &g_outPos, rnd() & 255);
	chunk_end(s);
}

/* bit packer of the codes of a frame */
static byte g_f[65536];
static int g_fPos, g_fCodes, g_fSlot, g_fWord;

static void emit_code(int code) {
	if ((g_fCodes & 7) == 0) { g_fSlot = g_fPos; g_fPos += 2; g_fWord = 0; }
	g_fWord |= (code & 3) << (14 - 2 * (g_fCodes & 7));
	g_f[g_fSlot] = g_fWord & 255;
	g_f[g_fSlot + 1] = g_fWord >> 8;
	g_fCodes++;
}

static int g_xoff, g_yoff, g_frameBase, g_other;

/* is a motion vector byte valid for a block whose first pixel is at dst */
static int motion_ok(int m, int dst, int side) {
	int x = m >> 4, y = m & 15;
	int i = g_width, j = 1;
	int disp, src;
	if (g_width == g_height * 4) { i += i; j += j; }
	disp = g_other - ((y + g_yoff - 8) * i + (x + g_xoff - 8) * j);
	src = dst + disp;
	return src >= 0 && src + (side - 1) * g_width + side <= 2 * g_width * g_height;
}

static void block4(int dst) {
	int r = rnd() % 8;
	if (r < 2) { emit_code(2); g_f[g_fPos++] = rnd() & 255; }
	else if (r < 4) {
		int k; emit_code(3);
		for (k = 0; k < 4; k++) g_f[g_fPos++] = rnd() & 255;
	} else if (r < 6) {
		int m = rnd() & 255;
		if (motion_ok(m, dst, 4)) { emit_code(1); g_f[g_fPos++] = m; } else emit_code(0);
	} else emit_code(0);
}

static void block8(int x, int y) {
	int dst = g_frameBase + y * g_width + x;
	int r = rnd() % 10;
	if (r < 3) { emit_code(2); g_f[g_fPos++] = rnd() & 255; }
	else if (r == 3) emit_code(0);
	else if (r < 6) {
		int m = rnd() & 255;
		if (motion_ok(m, dst, 8)) { emit_code(1); g_f[g_fPos++] = m; } else emit_code(0);
	} else {
		emit_code(3);
		block4(g_frameBase + y * g_width + x);
		block4(g_frameBase + y * g_width + x + 4);
		block4(g_frameBase + (y + 4) * g_width + x);
		block4(g_frameBase + (y + 4) * g_width + x + 4);
	}
}

static void frame(int xoff, int yoff) {
	int s, mx, my, qx, qy;
	g_xoff = xoff; g_yoff = yoff;
	if (g_numQuads & 1) { g_frameBase = g_width * g_height; g_other = -g_width * g_height; }
	else { g_frameBase = 0; g_other = g_width * g_height; }
	g_fPos = 0; g_fCodes = 0;
	for (my = 0; my < g_height; my += 16)
		for (mx = 0; mx < g_width; mx += 16)
			for (qy = 0; qy < 2; qy++)
				for (qx = 0; qx < 2; qx++)
					block8(mx + qx * 8, my + qy * 8);
	chunk_begin(0x1011, ((xoff & 255) << 8) | (yoff & 255), &s);
	memcpy(g_out + g_outPos, g_f, g_fPos);
	g_outPos += g_fPos;
	chunk_end(s);
	g_numQuads++;
}

static void file_header(int fps) {
	g_outPos = 0;
	put8(g_out, &g_outPos, 0x84); put8(g_out, &g_outPos, 0x10);
	put8(g_out, &g_outPos, 255); put8(g_out, &g_outPos, 255);
	put8(g_out, &g_outPos, 255); put8(g_out, &g_outPos, 255);
	put8(g_out, &g_outPos, fps & 255); put8(g_out, &g_outPos, fps >> 8);
}

int main(int argc, char **argv) {
	FILE *f;
	int s;
	if (argc < 3) return 2;
	file_header(24);
	if (strcmp(argv[1], "basic") == 0) {
		g_seed = 1234;
		info(32, 32);
		codebook(20, 10);
		audio(0x1020, 100, 0x1234);
		frame(0, 0);
		frame(0, 0);
		audio(0x1020, 64, 0xF000);
		frame(3, -2);
		info(32, 32);               /* numQuads is not 1: the next frame is a first one */
		frame(0, 0);
		codebook(5, 3);             /* replaces the first entries only */
		frame(-5, 7);
		frame(0, 0);
	} else if (strcmp(argv[1], "wide") == 0) {
		g_seed = 77;
		info(64, 16);               /* four times wider than high: the motion doubles */
		codebook(30, 12);
		frame(0, 0);
		frame(1, 1);
		frame(-1, 0);
		frame(0, 0);
	} else if (strcmp(argv[1], "stereo") == 0) {
		g_seed = 4242;
		info(48, 32);
		codebook(0, 0);             /* flags 0: 256 and 256 */
		audio(0x1021, 160, 0x8040);
		frame(0, 0);
		audio(0x1021, 80, 0x00FF);
		frame(2, 2);
		codebook(0, 4);             /* the high byte 0 means 256 */
		frame(0, 0);
	} else return 2;
	/* an empty chunk and the zeros that follow end the data for the original */
	chunk_begin(0x1013, 0, &s); chunk_end(s);
	f = fopen(argv[2], "wb");
	fwrite(g_out, 1, g_outPos, f);
	fclose(f);
	return 0;
}
