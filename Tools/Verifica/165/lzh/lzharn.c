/* Harness of the LZH of Keen Dreams (issue #165, K12): the original lzhuf.c (compiled with Open Watcom 16 bit, with
   its compressor turned on: LZHUF_P.C is lzhuf.c with INCLUDE_LZH_COMP 1, made by Run-LzhParity.ps1) compresses a
   few made up buffers and writes the compressed bytes. The port expands them (DelphiDoom.Tests.Keen.Lzh) and must
   give back the buffers, that the test makes again with the same generator. Each buffer is also expanded here
   with the original lzhDecompress, to be sure that the stream is good. See Tools\Verifica\165\LEGGIMI.md */
#include "LZHUF_P.C"
#include <malloc.h>

#define CASES 7

/* jam_io.c reads from a buffered file with this function of gelib.c: the harness only uses memory */
int bio_readch(void *bio)
{
	return 0;
}

static unsigned long seed;

static unsigned next(void)
{
	seed = seed * 1664525UL + 1013904223UL;
	return (unsigned)(seed >> 24);
}

static long sizes[CASES] = { 1, 100, 3000, 5000, 40000L, 2000, 31 };

static void fill(int kind, unsigned char huge *p, long size)
{
	long i;
	unsigned v;
	seed = 12345UL + kind;
	for (i = 0; i < size; i++)
	{
		v = next();
		switch (kind)
		{
		case 0: p[i] = 'K'; break;
		case 1: p[i] = 'A'; break;
		case 2: p[i] = "the quick brown "[v & 15]; break;
		case 3: p[i] = (unsigned char)v; break;
		case 4: p[i] = (v & 0xc0) ? (unsigned char)(v & 0x3f) : (unsigned char)(i >> 8); break;
		case 5: p[i] = (unsigned char)("abcdefg"[i % 7] + ((i / 700) & 1)); break;
		default: p[i] = (unsigned char)(i * 3); break;
		}
	}
}

void main(void)
{
	int c;
	long i, clen, n;
	unsigned long h;
	unsigned char huge *src, huge *dst, huge *back;

	src = halloc(41000L, 1);
	dst = halloc(60000L, 1);
	back = halloc(41000L, 1);
	if (!src || !dst || !back)
	{
		printf("QUIT no memory\n");
		exit(1);
	}
	for (c = 0; c < CASES; c++)
	{
		fill(c, src, sizes[c]);
		putbuf = 0;
		putlen = 0;
		clen = lzhCompress(src, dst, sizes[c], SRC_MEM | DEST_MEM);
		h = 2166136261UL;
		for (i = 0; i < sizes[c]; i++)
			h = (h ^ src[i]) * 16777619UL;
		printf("C %d %ld %ld %08lX\n", c, sizes[c], clen, h);
		for (i = 0; i < clen; i++)
		{
			if ((i & 31) == 0)
				printf("H ");
			printf("%02X", (unsigned)dst[i]);
			if ((i & 31) == 31 || i == clen - 1)
				printf("\n");
		}
		n = lzhDecompress(dst, back, sizes[c], clen, SRC_MEM | DEST_MEM);
		for (i = 0; i < sizes[c]; i++)
			if (back[i] != src[i])
				break;
		printf("D %d %ld %s\n", c, n, i == sizes[c] ? "same" : "DIFFERENT");
	}
	printf("E\n");
}
