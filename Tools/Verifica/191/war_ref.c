/*
  Issue #191: harness di riferimento per Libs\War.
  Compila il codice ORIGINALE di acoto87/war1 (zlib License, (C) 2019 Alejandro Coto Gutierrez):
  wfile_loadWarFile e wfile_freeWarFile di src\war_file.c, la struttura WarFile di src\war_resources.h,
  la tabella assets[] di src\war_database.h e DatabaseEntryType di src\war_enums.h sono estratti
  alla lettera da Compila-WarRef.ps1 (war_core.inc, war_types.inc, war_enums.inc, war_database_copy.h):
  qui ci sono solo gli stub di SDL, Tracy, wm_alloc e del log che quel codice chiama.
  Questo file e' una modifica che serve solo a far girare quel codice: non e' il remake.

  Uso:  war_ref DATA.WAR list [noskip]   righe H/R: intestazione e un record per voce (come wg_loadDataFile)
        war_ref DATA.WAR dump N file     scrive i byte decompressi del record N
        war_ref - catalog                righe C: la tabella assets[]
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>

typedef int32_t s32;
typedef int64_t s64;
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

#define NOT_USED(expr) do { (void)(expr); } while (0)
#define arrayLength(arr) (sizeof(arr) / sizeof((arr)[0]))
#define MAX_RESOURCES_COUNT 586

typedef struct { const char* data; size_t length; } StringView;
static const char* wsv_data(StringView v) { return v.data; }
static StringView wsv_fromCString(const char* s) { StringView v; v.data = s; v.length = strlen(s); return v; }

typedef struct _WarContext WarContext;

#define TracyCZoneN(ctx, name, active)
#define TracyCZoneEnd(ctx)

typedef FILE SDL_IOStream;
static const char* SDL_GetError(void) { return "(stub)"; }
static SDL_IOStream* SDL_IOFromFile(const char* path, const char* mode) { return fopen(path, mode); }
static s64 SDL_GetIOSize(SDL_IOStream* s)
{
    long cur = ftell(s);
    fseek(s, 0, SEEK_END);
    long size = ftell(s);
    fseek(s, cur, SEEK_SET);
    return size;
}
static size_t SDL_ReadIO(SDL_IOStream* s, void* p, size_t n) { return fread(p, 1, n, s); }
static void SDL_CloseIO(SDL_IOStream* s) { fclose(s); }

static void logError(const char* fmt, ...)
{
    va_list ap;
    printf("E ");
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
    printf("\n");
}

/* wm_alloc del remake usa una memory zone; qui calloc (il contenuto non inizializzato non e' un'uscita) */
#define wm_alloc(sz) calloc(1, ((sz) > 0 ? (sz) : 1))
#define wm_free(p) free(p)

typedef enum _WarFileType
{
    WAR_FILE_TYPE_UNKNOWN,
    WAR_FILE_TYPE_DEMO,
    WAR_FILE_TYPE_RETAIL
} WarFileType;

typedef struct _WarRawResource WarRawResource;
typedef struct _WarFile WarFile;

void wfile_freeWarFile(WarFile* warFile);

#include "war_types.inc"
#include "war_enums.inc"
#include "war_core.inc"
#include "war_database_copy.h"

static u32 crc32_of(const u8* p, u32 n)
{
    static u32 table[256];
    static int init = 0;
    if (!init)
    {
        for (u32 i = 0; i < 256; ++i)
        {
            u32 c = i;
            for (int k = 0; k < 8; ++k)
                c = (c & 1) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
            table[i] = c;
        }
        init = 1;
    }
    u32 c = 0xFFFFFFFFu;
    for (u32 i = 0; i < n; ++i)
        c = table[(c ^ p[i]) & 0xFF] ^ (c >> 8);
    return c ^ 0xFFFFFFFFu;
}

int main(int argc, char** argv)
{
    if (argc >= 3 && strcmp(argv[2], "catalog") == 0)
    {
        for (size_t i = 0; i < arrayLength(assets); ++i)
            printf("C %d %d %s %u %u %u\n", assets[i].index, (int)assets[i].type, assets[i].name,
                   (unsigned)assets[i].param1, (unsigned)assets[i].param2, (unsigned)assets[i].param3);
        return 0;
    }

    if (argc < 3)
        return 2;

    bool skipDecompress[MAX_RESOURCES_COUNT];
    memset(skipDecompress, 0, sizeof(skipDecompress));
    bool useSkip = !(argc >= 4 && strcmp(argv[3], "noskip") == 0);
    if (useSkip)
    {
        for (size_t i = 0; i < arrayLength(assets); ++i)
        {
            if (assets[i].type == DB_ENTRY_TYPE_UNKNOWN)
                skipDecompress[assets[i].index] = true;
        }
    }

    WarFile* warFile = wfile_loadWarFile(NULL, wsv_fromCString(argv[1]), skipDecompress);
    if (!warFile)
    {
        printf("FAIL\n");
        return 1;
    }

    if (strcmp(argv[2], "dump") == 0 && argc >= 5)
    {
        int n = atoi(argv[3]);
        FILE* f = fopen(argv[4], "wb");
        fwrite(warFile->resources[n].data, 1, warFile->resources[n].length, f);
        fclose(f);
        return 0;
    }

    printf("H %u %u %d\n", warFile->archiveID, warFile->numberOfEntries, (int)warFile->type);
    for (u32 i = 0; i < warFile->numberOfEntries; ++i)
    {
        WarRawResource* r = &warFile->resources[i];
        if (r->placeholder)
        {
            printf("R %u P offset=%u\n", i, warFile->offsets[i]);
        }
        else
        {
            printf("R %u D offset=%u compressed=%d clen=%u length=%u crc=%08x\n", i, r->offset, r->compressed ? 1 : 0,
                   r->compressedLength, r->length, crc32_of(r->data, r->length));
        }
    }

    wfile_freeWarFile(warFile);
    return 0;
}
