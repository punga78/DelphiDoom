/*
 * Makes the small FLIC files of the parity tests (issue #199): random content with fixed
 * seeds, every kind of chunk, no commercial material.
 *
 *   flcgen basic|fli|wide|tall out.flc
 *
 * The streams are valid (every packet stays inside its row, every BRUN row adds up to the
 * width), so that the decoder of OpenXcom and the Delphi one read the same bytes. The file
 * "wide" also has a COLOR_256 chunk with several packets and a first skip other than 0,
 * where the decoder of OpenXcom does not follow the format (see Libs\Cinematic\CLAUDE.md).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

typedef struct { u8 *d; size_t n, cap; } Buf;

static unsigned int seed = 1;
static unsigned int rnd(void)
{
	seed = seed * 1103515245u + 12345u;
	return (seed >> 16) & 0x7FFF;
}
static int range(int lo, int hi) { return lo + (int)(rnd() % (unsigned)(hi - lo + 1)); }

static void put8(Buf *b, u8 v)
{
	if (b->n == b->cap)
	{
		b->cap = b->cap ? b->cap * 2 : 1024;
		b->d = realloc(b->d, b->cap);
	}
	b->d[b->n++] = v;
}
static void put16(Buf *b, u16 v) { put8(b, v & 0xFF); put8(b, v >> 8); }
static void put32(Buf *b, u32 v) { put16(b, v & 0xFFFF); put16(b, v >> 16); }
static void patch32(Buf *b, size_t at, u32 v)
{
	b->d[at] = v & 0xFF; b->d[at + 1] = (v >> 8) & 0xFF; b->d[at + 2] = (v >> 16) & 0xFF; b->d[at + 3] = v >> 24;
}
static void patch16(Buf *b, size_t at, u16 v) { b->d[at] = v & 0xFF; b->d[at + 1] = v >> 8; }

static int W, H;

static size_t chunk_begin(Buf *b, u16 type)
{
	size_t at = b->n;
	put32(b, 0);
	put16(b, type);
	return at;
}
static void chunk_end(Buf *b, size_t at) { patch32(b, at, (u32)(b->n - at)); }

static void color256(Buf *b, int packets, int firstSkip)
{
	size_t at = chunk_begin(b, 4);
	int p, i;
	put16(b, packets);
	for (p = 0; p < packets; p++)
	{
		int count = range(1, 40);
		put8(b, p == 0 ? firstSkip : range(0, 5));
		put8(b, count);
		for (i = 0; i < count * 3; i++)
			put8(b, rnd() & 0xFF);
	}
	chunk_end(b, at);
}
static void color64(Buf *b)
{
	size_t at = chunk_begin(b, 11);
	int packets = range(1, 3), p, i;
	put16(b, packets);
	for (p = 0; p < packets; p++)
	{
		int count = range(1, 50);
		put8(b, range(0, 150));
		put8(b, count);
		for (i = 0; i < count * 3; i++)
			put8(b, rnd() & 63);
	}
	chunk_end(b, at);
}
static void brun(Buf *b)
{
	size_t at = chunk_begin(b, 15);
	int y;
	for (y = 0; y < H; y++)
	{
		int x = 0;
		put8(b, 0);
		while (x < W)
		{
			int n = range(1, W - x < 127 ? W - x : 127), i;
			if (rnd() & 1)
			{
				put8(b, n);
				put8(b, rnd() & 0xFF);
			}
			else
			{
				put8(b, (u8)(-n));
				for (i = 0; i < n; i++)
					put8(b, rnd() & 0xFF);
			}
			x += n;
		}
	}
	chunk_end(b, at);
}
static void copy_chunk(Buf *b)
{
	size_t at = chunk_begin(b, 16);
	int i;
	for (i = 0; i < W * H; i++)
		put8(b, rnd() & 0xFF);
	chunk_end(b, at);
}
static void black(Buf *b)
{
	size_t at = chunk_begin(b, 13);
	chunk_end(b, at);
}
static void lc(Buf *b)
{
	size_t at = chunk_begin(b, 12);
	int y0 = range(0, H / 2), lines = range(1, H - y0), l;
	put16(b, y0);
	put16(b, lines);
	for (l = 0; l < lines; l++)
	{
		int col = 0, packets = range(0, 4), p, i;
		put8(b, packets);
		for (p = 0; p < packets; p++)
		{
			int room = W - col, skip, n;
			if (room < 2) { /* nothing fits: an empty packet */ put8(b, 0); put8(b, 0); continue; }
			skip = range(0, room / 2 < 255 ? room / 2 : 255);
			room -= skip;
			n = range(1, room < 127 ? room : 127);
			put8(b, skip);
			if (rnd() & 1)
			{
				put8(b, n);
				for (i = 0; i < n; i++)
					put8(b, rnd() & 0xFF);
			}
			else
			{
				put8(b, (u8)(-n));
				put8(b, rnd() & 0xFF);
			}
			col += skip + n;
		}
	}
	chunk_end(b, at);
}
static void ss2(Buf *b)
{
	size_t at = chunk_begin(b, 7), count_at;
	int y = 0, lines = 0;
	put16(b, 0);
	count_at = at + 6;
	while (y < H)
	{
		int r = range(0, 9);
		if (r == 0 && y < H - 1)
		{
			int skip = range(1, H - 1 - y);
			put16(b, (u16)(-skip));
			y += skip;
			continue;
		}
		{
			int col = 0, packets = range(0, 3), p, i, last = (r == 1);
			/* the byte stays below 0x80: readS16 of OpenXcom reads the low byte as a signed char, so
			   with a byte of 0x80 or more the word has all its high bits set and the line is taken
			   as a skip of lines (it also does so for a packet count with such a low byte) */
			if (last)
				put16(b, 0x8000 | (rnd() & 0x7F));
			put16(b, packets);
			for (p = 0; p < packets; p++)
			{
				int room = (W - col) / 2, skip, n;
				if (room < 1) { put8(b, 0); put8(b, 0); continue; }
				skip = range(0, (W - col) - 2 < 255 ? (W - col) - 2 : 255);
				room = (W - col - skip) / 2;
				if (room < 1) { skip = 0; room = (W - col) / 2; }
				n = range(1, room < 127 ? room : 127);
				put8(b, skip);
				if (rnd() & 1)
				{
					put8(b, n);
					for (i = 0; i < n * 2; i++)
						put8(b, rnd() & 0xFF);
				}
				else
				{
					put8(b, (u8)(-n));
					put8(b, rnd() & 0xFF);
					put8(b, rnd() & 0xFF);
				}
				col += skip + n * 2;
			}
			lines++;
			y++;
		}
	}
	patch16(b, count_at, lines);
	chunk_end(b, at);
}
static void thumbnail(Buf *b)
{
	size_t at = chunk_begin(b, 18);
	int i;
	for (i = 0; i < 10; i++)
		put8(b, rnd() & 0xFF);
	chunk_end(b, at);
}
static void unknown(Buf *b)
{
	size_t at = chunk_begin(b, 99);
	put16(b, 0x1234);
	chunk_end(b, at);
}

/* a frame: kinds is a list of chunk letters */
static void frame(Buf *b, const char *kinds, int delay, int multiPackets, int firstSkip)
{
	size_t at = b->n;
	const char *k;
	int count = (int)strlen(kinds);
	put32(b, 0);
	put16(b, 0xF1FA);
	put16(b, count);
	put16(b, delay);
	put32(b, 0);
	put16(b, 0);
	for (k = kinds; *k; k++)
		switch (*k)
		{
		case 'p': color256(b, multiPackets, firstSkip); break;
		case 'q': color64(b); break;
		case 'b': brun(b); break;
		case 'c': copy_chunk(b); break;
		case 'k': black(b); break;
		case 'l': lc(b); break;
		case 's': ss2(b); break;
		case 't': thumbnail(b); break;
		case 'u': unknown(b); break;
		}
	patch32(b, at, (u32)(b->n - at));
}
static void prefix(Buf *b)
{
	int i;
	put32(b, 40);
	put16(b, 0xF100);
	put16(b, 0);
	for (i = 0; i < 32; i++)
		put8(b, 0);
}

int main(int argc, char **argv)
{
	Buf b = { 0, 0, 0 };
	const char *kind;
	int i, flc = 1, speed = 70, frames = 0;
	FILE *f;
	if (argc < 3)
		return 2;
	kind = argv[1];
	if (!strcmp(kind, "basic")) { W = 64; H = 48; seed = 101; }
	else if (!strcmp(kind, "fli")) { W = 32; H = 32; seed = 202; flc = 0; speed = 3; }
	else if (!strcmp(kind, "wide")) { W = 100; H = 30; seed = 303; }
	else if (!strcmp(kind, "tall")) { W = 24; H = 40; seed = 404; }
	else return 2;
	for (i = 0; i < 128; i++)
		put8(&b, 0);
	if (!strcmp(kind, "basic"))
	{
		prefix(&b);
		frame(&b, "pb", 0, 1, 0);
		frame(&b, "s", 0, 1, 0);
		frame(&b, "qs", 0, 1, 0);
		frame(&b, "l", 0, 1, 0);
		frame(&b, "tsu", 0, 1, 0);
		frame(&b, "c", 0, 1, 0);
		frame(&b, "k", 0, 1, 0);
		frame(&b, "", 0, 1, 0);
		frame(&b, "s", 0, 1, 0);
		frame(&b, "ls", 0, 1, 0);
		frame(&b, "s", 0, 1, 0);
		frames = 11;
	}
	else if (!strcmp(kind, "fli"))
	{
		frame(&b, "qb", 0, 1, 0);
		frame(&b, "l", 7, 1, 0);
		frame(&b, "l", 0, 1, 0);
		frame(&b, "c", 2, 1, 0);
		frame(&b, "k", 0, 1, 0);
		frame(&b, "lc", 0, 1, 0);
		frame(&b, "l", 1, 1, 0);
		frames = 6;
	}
	else if (!strcmp(kind, "wide"))
	{
		prefix(&b);
		frame(&b, "pb", 0, 3, 4);
		for (i = 0; i < 12; i++)
			frame(&b, "s", 0, 1, 0);
		frame(&b, "ql", 0, 1, 0);
		frame(&b, "s", 0, 1, 0);
		frames = 14;
	}
	else
	{
		frame(&b, "pb", 0, 1, 0);
		for (i = 0; i < 6; i++)
			frame(&b, (i & 1) ? "l" : "s", 0, 1, 0);
		frame(&b, "c", 0, 1, 0);
		frame(&b, "s", 0, 1, 0);
		frames = 8;
	}
	patch32(&b, 0, (u32)b.n);
	patch16(&b, 4, flc ? 0xAF12 : 0xAF11);
	patch16(&b, 6, frames);
	patch16(&b, 8, W);
	patch16(&b, 10, H);
	patch16(&b, 12, 8);
	patch16(&b, 14, flc ? 3 : 0);
	patch32(&b, 16, speed);
	f = fopen(argv[2], "wb");
	if (!f)
		return 1;
	fwrite(b.d, 1, b.n, f);
	fclose(f);
	return 0;
}
