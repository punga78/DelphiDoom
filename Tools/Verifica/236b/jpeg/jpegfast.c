/*
 * Parity tool of the JPEG frames of Doom 3 (issue #236, part B, #114): decodes the streams of a pack with
 * the REAL jpeg-6 of Doom 3 (neo/renderer/jpeg-6, unchanged: RGB_PIXELSIZE 4, JDCT_FASTEST = JDCT_FLOAT)
 * with the settings of JPEGBlit in Cinematic.cpp (dct_method = JDCT_FASTEST, do_fancy_upsampling = FALSE)
 * and prints one line per stream: name, size, number of components, result and the FNV-1a hash of the
 * pixels (three bytes R, G, B for a color image, one byte for a gray one).
 *   jpegfast.exe cases.pack [mode] > golden.txt
 * mode: "doom3" (default) or "default" (the accurate integer DCT and fancy upsampling, as libjpeg 6b).
 * Pack: for each stream uint32 name length, name, uint32 data length, data (little endian).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include "jinclude.h"
#include "jpeglib.h"
#include "jerror.h"
#ifndef RGB_PIXELSIZE
#define RGB_PIXELSIZE 4 /* jmorecfg.h of Doom 3 (not visible from jpeglib.h) */
#endif

#include <stdarg.h>
/* what the jerror.c of Doom 3 asks of the engine */
void jpg_Error(const char *fmt, ...) { }
void jpg_Printf(const char *fmt, ...) { }

static jmp_buf failure;
static char lastMessage[JMSG_LENGTH_MAX];

static void errorExit(j_common_ptr cinfo) {
	(*cinfo->err->format_message)(cinfo, lastMessage);
	longjmp(failure, 1);
}
static void silent(j_common_ptr cinfo, int level) { }
static void silentMessage(j_common_ptr cinfo) { }

/* a source in memory: when the bytes end the decoder gets an EOI marker, again and again */
static void srcInit(j_decompress_ptr cinfo) { }
static boolean srcFill(j_decompress_ptr cinfo) {
	static const JOCTET eoi[2] = { 0xFF, JPEG_EOI };
	cinfo->src->next_input_byte = eoi;
	cinfo->src->bytes_in_buffer = 2;
	return TRUE;
}
static void srcSkip(j_decompress_ptr cinfo, long count) {
	if (count > 0) {
		while (count > (long)cinfo->src->bytes_in_buffer) {
			count -= (long)cinfo->src->bytes_in_buffer;
			srcFill(cinfo);
		}
		cinfo->src->next_input_byte += (size_t)count;
		cinfo->src->bytes_in_buffer -= (size_t)count;
	}
}
static void srcTerm(j_decompress_ptr cinfo) { }

static unsigned hash32(unsigned h, const unsigned char *p, size_t n) {
	size_t i;
	for (i = 0; i < n; i++) { h ^= p[i]; h *= 16777619u; }
	return h;
}

static FILE *dumpFile;
static unsigned emit(unsigned h, const unsigned char *p, size_t n) {
	if (dumpFile) fwrite(p, 1, n, dumpFile);
	return hash32(h, p, n);
}

static unsigned readU32(FILE *f, int *ok) {
	unsigned char b[4];
	if (fread(b, 1, 4, f) != 4) { *ok = 0; return 0; }
	return (unsigned)b[0] | ((unsigned)b[1] << 8) | ((unsigned)b[2] << 16) | ((unsigned)b[3] << 24);
}

int main(int argc, char **argv) {
	FILE *f = fopen(argv[1], "rb");
	int doom3 = !(argc > 2 && !strcmp(argv[2], "default"));
	int ok = 1;
	if (!f) { fprintf(stderr, "no pack\n"); return 1; }
	for (;;) {
		unsigned nameLen = readU32(f, &ok), dataLen;
		char name[256];
		unsigned char *data;
		struct jpeg_decompress_struct cinfo;
		struct jpeg_error_mgr jerr;
		struct jpeg_source_mgr src;
		unsigned h = 2166136261u;
		int rc = 0, comps = 0, width = 0, height = 0;
		if (!ok) break;
		if (nameLen > 255 || fread(name, 1, nameLen, f) != nameLen) break;
		name[nameLen] = 0;
		dataLen = readU32(f, &ok);
		data = (unsigned char *)malloc(dataLen + 1);
		if (fread(data, 1, dataLen, f) != dataLen) break;
		cinfo.err = jpeg_std_error(&jerr);
		jerr.error_exit = errorExit;
		jerr.emit_message = silent;
		jerr.output_message = silentMessage;
		if (setjmp(failure)) {
			rc = 1;
			fprintf(stderr, "%s: %s (%d)\n", name, lastMessage, jerr.msg_code);
			jpeg_destroy_decompress(&cinfo);
			printf("%s|%d|%d|%d|%d|%08X\n", name, width, height, comps, rc, 0u);
			free(data);
			continue;
		}
		jpeg_create_decompress(&cinfo);
		src.init_source = srcInit;
		src.fill_input_buffer = srcFill;
		src.skip_input_data = srcSkip;
		src.resync_to_restart = jpeg_resync_to_restart;
		src.term_source = srcTerm;
		src.next_input_byte = data;
		src.bytes_in_buffer = dataLen;
		cinfo.src = &src;
		jpeg_read_header(&cinfo, TRUE);
		if (doom3) {
			cinfo.dct_method = JDCT_FASTEST;
			cinfo.dither_mode = JDITHER_NONE;
			cinfo.do_fancy_upsampling = FALSE;
		}
		if (argc > 3 && !strcmp(argv[3], name)) { char path[300]; sprintf(path, "%s.raw", name); dumpFile = fopen(path, "wb"); }
		jpeg_start_decompress(&cinfo);
		width = cinfo.output_width;
		height = cinfo.output_height;
		comps = cinfo.out_color_space == JCS_RGB ? 3 : cinfo.output_components;
		{
			int stride = cinfo.output_width * cinfo.output_components;
			unsigned char *row = (unsigned char *)calloc(1, stride + 8);
			JSAMPROW rows[1];
			rows[0] = row;
			while (cinfo.output_scanline < cinfo.output_height) {
				memset(row, 0, stride);
				jpeg_read_scanlines(&cinfo, rows, 1);
				if (cinfo.out_color_space == JCS_RGB) {
					unsigned x;
					if (cinfo.jpeg_color_space == JCS_RGB) {
						/* the copy of an RGB stream is packed: three bytes a pixel in a row of four */
						h = emit(h, row, cinfo.output_width * 3);
					} else {
						for (x = 0; x < cinfo.output_width; x++) h = emit(h, row + x * RGB_PIXELSIZE, 3);
					}
				} else {
					h = emit(h, row, stride);
				}
			}
			free(row);
		}
		if (dumpFile) { fclose(dumpFile); dumpFile = NULL; }
		jpeg_finish_decompress(&cinfo);
		jpeg_destroy_decompress(&cinfo);
		printf("%s|%d|%d|%d|%d|%08X\n", name, width, height, comps, rc, h);
		free(data);
	}
	fclose(f);
	return 0;
}
