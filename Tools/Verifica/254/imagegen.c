/*
 * imagegen.c - the REAL LoadTGA and LoadJPG of renderer/tr_image.c of Quake III (issue #254, renderer phase R0).
 *
 * build-image.sh cuts the two functions out of tr_image.c by line (q3_image_real.inc, nothing is edited), copies the
 * jpeg-6 of Quake III (the one with RGB_PIXELSIZE 4 and JDCT_FLOAT as the default) and gives it a renderer stub
 * (renderer/tr_local.h: the `ri` import table). The program decodes the files named on the command line:
 *
 *     imagegen tga:<file> jpg:<file> ...
 *
 * and writes one line per file:
 *     tga <name> ok <width> <height> <FNV-1a 64 of the RGBA bytes>
 *     tga <name> error <first line of the message>
 *     tga <name> none                       (LoadTGA returned no picture)
 *
 * Licensed under the GNU General Public License, version 2 or later (it includes code of the Quake III Arena GPL
 * Source Code, id Software).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include <stdarg.h>

#include "renderer/tr_local.h"
#include "jpeg-6/jpeglib.h"
#include "q3_typedefs.inc"

refimport_t ri;

static jmp_buf g_error;
static char g_message[1024];
static int g_warnings;

static void ri_printf(int level, const char *fmt, ...) {
	char buffer[1024];
	va_list args;
	va_start(args, fmt);
	vsnprintf(buffer, sizeof(buffer), fmt, args);
	va_end(args);
	if (level == PRINT_WARNING) {
		g_warnings++;
	}
}

static void ri_error(int level, const char *fmt, ...) {
	va_list args;
	char *end;
	va_start(args, fmt);
	vsnprintf(g_message, sizeof(g_message), fmt, args);
	va_end(args);
	end = strchr(g_message, '\n');
	if (end) {
		*end = 0;
	}
	/* the file name is the path of the machine that made the golden: the messages end before it */
	end = strstr(g_message, " in file '");
	if (end) {
		*end = 0;
	}
	longjmp(g_error, 1);
}

static void *ri_malloc(int size) {
	/* ri.Malloc is Z_Malloc: zeroed memory */
	return calloc(1, size > 0 ? size : 1);
}

static void ri_free(void *p) {
	free(p);
}

static unsigned char *g_file;

/* the file plus 16 K of zeros: the Q3 jdatasrc.c copies a whole 4096 byte block even past the end of the file */
static int ri_readfile(const char *name, void **buffer) {
	FILE *f = fopen(name, "rb");
	long length;
	unsigned char *data;
	*buffer = NULL;
	if (!f) {
		return -1;
	}
	fseek(f, 0, SEEK_END);
	length = ftell(f);
	fseek(f, 0, SEEK_SET);
	data = (unsigned char *)calloc(1, length + 16384);
	if (length > 0 && fread(data, 1, length, f) != (size_t)length) {
		fclose(f);
		free(data);
		return -1;
	}
	fclose(f);
	*buffer = data;
	g_file = data;
	return (int)length;
}

static void ri_freefile(void *buffer) {
	free(buffer);
	g_file = NULL;
}

/* LoadJPG ends with jpeg_destroy_compress (a quirk of the original: the object is a decompressor); the compression
   half of the library is not linked, so the call is the plain jpeg_destroy of jcomapi.c */
void jpeg_destroy_compress(j_compress_ptr cinfo) {
	jpeg_destroy((j_common_ptr)cinfo);
}

#include "q3_image_real.inc"

static void print_hash(const byte *pic, int count) {
	unsigned long long hash = 14695981039346656037ULL;
	int i;
	for (i = 0; i < count; i++) {
		hash ^= pic[i];
		hash *= 1099511628211ULL;
	}
	printf("%016llx", hash);
}

static const char *base_name(const char *path) {
	const char *slash = strrchr(path, '/');
	const char *back = strrchr(path, '\\');
	if (back && (!slash || back > slash)) {
		slash = back;
	}
	return slash ? slash + 1 : path;
}

int main(int argc, char **argv) {
	int i;
	ri.Printf = ri_printf;
	ri.Error = ri_error;
	ri.Malloc = ri_malloc;
	ri.Free = ri_free;
	ri.FS_ReadFile = ri_readfile;
	ri.FS_FreeFile = ri_freefile;
	for (i = 1; i < argc; i++) {
		const char *arg = argv[i];
		int is_tga = strncmp(arg, "tga:", 4) == 0;
		const char *path = arg + 4;
		byte *pic = NULL;
		int width = 0, height = 0;
		g_warnings = 0;
		if (setjmp(g_error)) {
			printf("%s %s error %s\n", is_tga ? "tga" : "jpg", base_name(path), g_message);
			continue;
		}
		if (is_tga) {
			LoadTGA(path, &pic, &width, &height);
		} else {
			LoadJPG(path, &pic, &width, &height);
		}
		if (!pic) {
			printf("%s %s none\n", is_tga ? "tga" : "jpg", base_name(path));
			continue;
		}
		if (getenv("IMAGEGEN_DUMP")) {
			/* IMAGEGEN_DUMP=<folder>: the RGBA bytes of every picture, to look at the pixels that differ */
			char target[1024];
			FILE *dump;
			snprintf(target, sizeof(target), "%s/%s.rgba", getenv("IMAGEGEN_DUMP"), base_name(path));
			dump = fopen(target, "wb");
			if (dump) {
				fwrite(pic, 1, (size_t)width * height * 4, dump);
				fclose(dump);
			}
		}
		printf("%s %s ok %d %d ", is_tga ? "tga" : "jpg", base_name(path), width, height);
		print_hash(pic, width * height * 4);
		{
			/* the sum of the bytes: the float DCT of the JPEG is not the same in every build of the C (x87 or SSE, -O0
			   or -O2 give three different hashes for one file of OpenArena); the sum says how far apart they are */
			unsigned long long sum = 0;
			int k;
			for (k = 0; k < width * height * 4; k++) {
				sum += pic[k];
			}
			printf(" sum=%llu", sum);
		}
		printf(" warnings=%d\n", g_warnings);
		free(pic);
	}
	return 0;
}
