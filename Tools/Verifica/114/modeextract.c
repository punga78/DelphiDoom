/*
 * Extractor of the fingerprints of the codebook of Quake III Arena in all of its modes
 * (code/client/cl_cin.c, GPL v2 or later, Copyright (C) 1999-2005 Id Software, Inc.). Issue #114.
 *
 * roq_original.inc is built by build.sh with the lines of the original file (not retyped);
 * stubs.h replaces the engine. Only the driver below is new: for every combination of
 * samplesPerPixel (4, 2, 1), half and smootheddouble it feeds three codebook chunks (flags 0,
 * 16 and 4, 256 and 3) of bytes made by a fixed generator to decodeCodeBook, the function of the
 * original, and prints a CRC-32 of vq2, vq4 and vq8 (the whole static buffers: 32 KB, 128 KB and
 * 512 KB) after each chunk. The gray table, which the original never fills (it reads it through
 * a nil pointer), is gray[i] = (i * 37 + 11) & 255.
 *
 * The first line, "yuv565 crc", is a CRC-32 of yuv_to_rgb (the 16 bit colors) over all the
 * 16777216 triples.
 *
 *   modeextract > modes.golden.txt
 */
#include "stubs.h"
#include "roq_original.inc"

static unsigned int crc_table[256];

static void crc_init(void) {
	unsigned int c, n, k;
	for (n = 0; n < 256; n++) {
		c = n;
		for (k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
		crc_table[n] = c;
	}
}

static unsigned int crc32(const byte *data, long size) {
	unsigned int c = 0xFFFFFFFFu;
	long i;
	for (i = 0; i < size; i++) c = crc_table[(c ^ data[i]) & 0xFF] ^ (c >> 8);
	return c ^ 0xFFFFFFFFu;
}

static void scenario(int pixelSize, int half, int smoothed) {
	static const unsigned short flags[3] = { 0x0000, 0x1004, 0x0003 };
	static byte gray[256];
	static byte input[4096];
	cin_cache *c = &cinTable[0];
	unsigned int x = 987654321u;
	int i, k;

	for (i = 0; i < 256; i++) gray[i] = (byte)((i * 37 + 11) & 255);
	memset(vq2, 0, sizeof(vq2));
	memset(vq4, 0, sizeof(vq4));
	memset(vq8, 0, sizeof(vq8));
	c->samplesPerPixel = pixelSize;
	c->half = half;
	c->smootheddouble = smoothed;
	c->gray = gray;
	for (k = 0; k < 3; k++) {
		for (i = 0; i < 4096; i++) { x = x * 1664525u + 1013904223u; input[i] = (byte)(x >> 16); }
		decodeCodeBook(input, flags[k]);
		printf("mode size %d half %d smooth %d chunk %d flags %04x vq2 %08x vq4 %08x vq8 %08x\n",
			pixelSize, half, smoothed, k, flags[k],
			crc32((byte *)vq2, sizeof(vq2)), crc32((byte *)vq4, sizeof(vq4)),
			crc32((byte *)vq8, sizeof(vq8)));
	}
}

/* the 16 bit colors: yuv_to_rgb of all the 16777216 triples (y, u, v), as 16 bit little endian */
static void yuv565_mode(void) {
	unsigned int c = 0xFFFFFFFFu;
	long y, u, v;
	for (y = 0; y < 256; y++)
		for (u = 0; u < 256; u++)
			for (v = 0; v < 256; v++) {
				unsigned short p = yuv_to_rgb(y, u, v);
				c = crc_table[(c ^ (p & 0xFF)) & 0xFF] ^ (c >> 8);
				c = crc_table[(c ^ (p >> 8)) & 0xFF] ^ (c >> 8);
			}
	printf("yuv565 crc %08x\n", c ^ 0xFFFFFFFFu);
}

int main(void) {
	static const int sizes[3] = { 4, 2, 1 };
	int s, m;

	crc_init();
	currentHandle = 0;
	memset(&cinTable[0], 0, sizeof(cinTable[0]));
	initRoQ();
	yuv565_mode();
	for (s = 0; s < 3; s++)
		for (m = 0; m < 3; m++)
			scenario(sizes[s], m == 2, m == 1);
	/* half wins over smootheddouble in the original */
	scenario(4, 1, 1);
	return 0;
}
