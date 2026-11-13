/*
 * Extractor of the fingerprints of a RoQ file, made with the decoder of
 * Quake III Arena (code/client/cl_cin.c, GPL v2 or later, Copyright (C)
 * 1999-2005 Id Software, Inc.). Issue #114.
 *
 * roq_original.inc is built by build.sh with the lines of the original file
 * (not retyped); stubs.h replaces the engine. Only the driver below is new:
 * it feeds the file to RoQInterrupt, the function of the original, and prints
 * a CRC-32 of every frame and of every block of audio that the decoder gives.
 *
 *   roqextract file.roq > golden.txt
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

static int g_audioCount = 0;

/* what the mixer would be given; for the mono chunks the original passes the
 * data as stereo (two copies of every sample) but says that there is one
 * channel, so the mixer reads half of them: both CRCs are printed */
static void S_RawSamples(int samples, int rate, int width, int channels, const byte *data, float volume) {
	(void)volume;
	if (channels == 1) {
		printf("audio %d channels 1 rate %d samples %d consumed %08x full %08x\n", g_audioCount++, rate,
			samples, crc32(data, (long)samples * width * 1), crc32(data, (long)samples * width * 2));
	} else {
		printf("audio %d channels %d rate %d samples %d consumed %08x full %08x\n", g_audioCount++, channels,
			rate, samples, crc32(data, (long)samples * width * channels),
			crc32(data, (long)samples * width * channels));
	}
}

/* the colors: yuv_to_rgb24 of all the 16777216 triples (y, u, v), as 32 bit little endian */
static void yuv_mode(void) {
	unsigned int c = 0xFFFFFFFFu;
	long y, u, v;
	for (y = 0; y < 256; y++)
		for (u = 0; u < 256; u++)
			for (v = 0; v < 256; v++) {
				unsigned int p = yuv_to_rgb24(y, u, v);
				int k;
				for (k = 0; k < 4; k++) c = crc_table[(c ^ ((p >> (8 * k)) & 0xFF)) & 0xFF] ^ (c >> 8);
			}
	printf("yuv crc %08x\n", c ^ 0xFFFFFFFFu);
}

/* the DPCM decoders on a buffer of bytes made by a generator that the tests repeat */
static void rll_mode(void) {
	static const unsigned short flags[4] = { 0x0000, 0x1234, 0xFFFF, 0x8000 };
	byte data[4096];
	short out[4096];
	unsigned int x = 12345;
	int i, k;
	for (i = 0; i < 4096; i++) { x = x * 1664525u + 1013904223u; data[i] = (byte)(x >> 16); }
	for (k = 0; k < 4; k++) {
		long n;
		n = RllDecodeMonoToMono(data, out, 1000, 0, flags[k]);
		printf("rll monomono flags %04x n %ld crc %08x\n", flags[k], n, crc32((byte *)out, 1000 * 2));
		n = RllDecodeMonoToStereo(data, out, 1000, 0, flags[k]);
		printf("rll monostereo flags %04x n %ld crc %08x\n", flags[k], n, crc32((byte *)out, 1000 * 4));
		n = RllDecodeStereoToStereo(data, out, 1000, 0, flags[k]);
		printf("rll stereostereo flags %04x n %ld crc %08x\n", flags[k], n, crc32((byte *)out, 1000 * 2));
		n = RllDecodeStereoToMono(data, out, 1000, 0, flags[k]);
		printf("rll stereomono flags %04x n %ld crc %08x\n", flags[k], n, crc32((byte *)out, 1000 * 2));
	}
}

int main(int argc, char **argv) {
	FILE *f;
	byte *bytes;
	long size;
	int frame = 0;
	int guard = 0;
	cin_cache *c;

	if (argc >= 2 && strcmp(argv[1], "--tables") == 0) {
		currentHandle = 0;
		crc_init();
		initRoQ();
		yuv_mode();
		rll_mode();
		return 0;
	}
	if (argc < 2) { fprintf(stderr, "usage: roqextract file.roq | --tables\n"); return 2; }
	f = fopen(argv[1], "rb");
	if (!f) { fprintf(stderr, "cannot open %s\n", argv[1]); return 2; }
	fseek(f, 0, SEEK_END); size = ftell(f); fseek(f, 0, SEEK_SET);
	bytes = (byte *)malloc(size + 65536);
	memset(bytes, 0, size + 65536);
	if (fread(bytes, 1, size, f) != (size_t)size) return 2;
	fclose(f);
	g_file = bytes;
	g_fileSize = size;
	crc_init();

	currentHandle = 0;
	c = &cinTable[0];
	memset(c, 0, sizeof(*c));
	initRoQ();
	c->ROQSize = FS_FOpenFileRead("x", &c->iFile, qtrue);
	c->status = FMV_PLAY;
	c->silent = qfalse;
	c->looping = qfalse;
	c->holdAtEnd = qfalse;
	Sys_StreamedRead(cin.file, 16, 1, c->iFile);
	RoQ_init();
	printf("fps %ld\n", c->roqFPS);

	while (c->status == FMV_PLAY && guard++ < 100000) {
		c->dirty = qfalse;
		RoQInterrupt();
		if (c->dirty) {
			if (frame == 0) printf("size %ld %ld\n", (long)c->CIN_WIDTH, (long)c->CIN_HEIGHT);
			printf("frame %d crc %08x\n", frame++,
				crc32(c->buf, (long)c->CIN_WIDTH * c->CIN_HEIGHT * 4));
		}
	}
	printf("frames %d audio %d\n", frame, g_audioCount);
	return 0;
}
