/*
  Issue #192: harness di riferimento per la parte grafica di Libs\War.
  Compila il codice ORIGINALE di acoto87/war1 (zlib License, (C) 2019 Alejandro Coto Gutierrez): le funzioni di
  war_resources.c che decodificano palette, immagini, sprite, cursori, tiles e tileset (wres_getPalette,
  wres_loadPaletteResource, wres_loadImageResource, wres_loadSpriteResource, wres_loadTileset, wres_loadTiles,
  wres_loadCursor), la tabella fontsData[] di war_font.c e il lettore di DATA.WAR di war_file.c sono estratti alla
  lettera da Compila-GfxRef.ps1 (file *.inc): qui ci sono solo gli stub di SDL, Tracy, wm_alloc, del log e della
  struct WarContext. Questo file e' una versione modificata del remake solo per far girare quel codice.

  Uso:  war_gfx_ref DATA.WAR gfx      una riga per ogni risorsa grafica, nell'ordine di assets[] (come
                                      wg_loadDataFile: prima le palette di quelle che le usano, per ordine della tabella)
        war_gfx_ref - fonts           la tabella dei glifi dei due font
        war_gfx_ref DATA.WAR dump N file   i byte RGBA della risorsa N (immagine, cursore, tileset)
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <strings.h>

typedef int32_t s32;
typedef int64_t s64;
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef float f32;

#define NOT_USED(expr) do { (void)(expr); } while (0)
#define arrayLength(arr) (sizeof(arr) / sizeof((arr)[0]))

#include "war_defines.inc"

typedef struct { const char* data; size_t length; } StringView;
static const char* wsv_data(StringView v) { return v.data; }
static StringView wsv_fromCString(const char* s) { StringView v; v.data = s; v.length = strlen(s); return v; }
static bool wsv_equalsIgnoreCase(StringView a, StringView b)
{
    return a.length == b.length && strncasecmp(a.data, b.data, a.length) == 0;
}

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
#define logInfo(...) ((void)0)
#define logDebug(...) ((void)0)
#define logWarning(...) ((void)0)

/* wm_alloc del remake usa una memory zone; qui calloc (come la zone, a zero) */
#define wm_alloc(sz) calloc(1, ((sz) > 0 ? (sz) : 1))
#define wm_free(p) free(p)
#define wm_realloc(p, sz) realloc((p), (sz))

typedef enum _WarFileType
{
    WAR_FILE_TYPE_UNKNOWN,
    WAR_FILE_TYPE_DEMO,
    WAR_FILE_TYPE_RETAIL
} WarFileType;

typedef struct _WarRawResource WarRawResource;
typedef struct _WarFile WarFile;
typedef struct _WarSpriteFrame WarSpriteFrame;
typedef struct _WarResource WarResource;
typedef struct _WarLevelUnit WarLevelUnit;
typedef struct _WarLevelConstruct WarLevelConstruct;
typedef struct _WarCustomMapConfiguration WarCustomMapConfiguration;
typedef int WarUnitType;
typedef int WarResourceKind;
typedef int WarConstructType;
typedef int WarRace;

void wfile_freeWarFile(WarFile* warFile);

#include "war_types.inc"
#include "war_enums.inc"
#include "war_resource_type.inc"
#include "war_sprite_frame.inc"
#include "war_types2.inc"
#include "war_core.inc"
#include "war_database_copy.h"

struct _WarContext
{
    WarFile* warFile;
    WarResource* resources;
};

#include "war_read_macros.inc"
#include "war_res_a.inc"
#include "war_res_b.inc"
#include "war_res_c.inc"

typedef struct { f32 x, y; f32 width, height; } rect;
struct _WarFontData
{
    s32 spriteWidth;
    s32 spriteHeight;
    s32 lineHeight;
    s32 advance;
    rect data[95];
};
typedef struct _WarFontData WarFontData;
#include "war_font_data.inc"

static u32 crc_table[256];
static void crc_init(void)
{
    for (u32 i = 0; i < 256; ++i)
    {
        u32 c = i;
        for (int k = 0; k < 8; ++k)
            c = (c & 1) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
        crc_table[i] = c;
    }
}
static u32 crc_update(u32 c, const u8* p, size_t n)
{
    for (size_t i = 0; i < n; ++i)
        c = crc_table[(c ^ p[i]) & 0xFF] ^ (c >> 8);
    return c;
}
static u32 crc32_of(const u8* p, size_t n) { return crc_update(0xFFFFFFFFu, p, n) ^ 0xFFFFFFFFu; }

static void loadOne(WarContext* context, DatabaseEntry* entry)
{
    switch (entry->type)
    {
        case DB_ENTRY_TYPE_PALETTE: wres_loadPaletteResource(context, entry); break;
        case DB_ENTRY_TYPE_IMAGE: wres_loadImageResource(context, entry); break;
        case DB_ENTRY_TYPE_SPRITE: wres_loadSpriteResource(context, entry); break;
        case DB_ENTRY_TYPE_TILESET: wres_loadTileset(context, entry); break;
        case DB_ENTRY_TYPE_TILES: wres_loadTiles(context, entry); break;
        case DB_ENTRY_TYPE_CURSOR: wres_loadCursor(context, entry); break;
        default: break;
    }
}

int main(int argc, char** argv)
{
    crc_init();
    if (argc >= 3 && strcmp(argv[2], "fonts") == 0)
    {
        for (int f = 0; f < 2; ++f)
        {
            printf("F %d %d %d %d %d\n", f, fontsData[f].spriteWidth, fontsData[f].spriteHeight,
                   fontsData[f].lineHeight, fontsData[f].advance);
            for (int g = 0; g < 95; ++g)
                printf("G %d %d %d %d %d %d\n", f, g, (int)fontsData[f].data[g].x, (int)fontsData[f].data[g].y,
                       (int)fontsData[f].data[g].width, (int)fontsData[f].data[g].height);
        }
        return 0;
    }
    if (argc < 3)
        return 2;

    bool skipDecompress[MAX_RESOURCES_COUNT];
    memset(skipDecompress, 0, sizeof(skipDecompress));
    for (size_t i = 0; i < arrayLength(assets); ++i)
        if (assets[i].type == DB_ENTRY_TYPE_UNKNOWN)
            skipDecompress[assets[i].index] = true;

    WarContext context = {0};
    context.warFile = wfile_loadWarFile(NULL, wsv_fromCString(argv[1]), skipDecompress);
    if (!context.warFile)
    {
        printf("FAIL\n");
        return 1;
    }
    context.resources = (WarResource*)calloc(MAX_RESOURCES_COUNT, sizeof(WarResource));

    /* come wg_loadDataFile: tutte le voci di assets[], nell'ordine della tabella */
    for (size_t i = 0; i < arrayLength(assets); ++i)
    {
        DatabaseEntry entry = assets[i];
        loadOne(&context, &entry);
    }

    if (strcmp(argv[2], "dump") == 0 && argc >= 5)
    {
        int n = atoi(argv[3]);
        WarResource* r = &context.resources[n];
        FILE* f = fopen(argv[4], "wb");
        if (r->type == WAR_RESOURCE_TYPE_IMAGE)
            fwrite(r->imageData.pixels, 1, r->imageData.width * r->imageData.height * 4, f);
        else if (r->type == WAR_RESOURCE_TYPE_CURSOR)
            fwrite(r->cursor.pixels, 1, r->cursor.width * r->cursor.height * 4, f);
        else if (r->type == WAR_RESOURCE_TYPE_TILESET)
            fwrite(r->tilesetData.data, 1, TILESET_WIDTH * TILESET_HEIGHT * 4, f);
        fclose(f);
        return 0;
    }

    for (size_t i = 0; i < arrayLength(assets); ++i)
    {
        s32 index = assets[i].index;
        WarResource* r = &context.resources[index];
        WarRawResource* raw = &context.warFile->resources[index];
        switch (r->type)
        {
            case WAR_RESOURCE_TYPE_PALETTE:
                printf("P %d %08x\n", index, crc32_of(r->paletteData.colors, PALETTE_LENGTH));
                break;
            case WAR_RESOURCE_TYPE_IMAGE:
                printf("I %d %u %u %08x\n", index, r->imageData.width, r->imageData.height,
                       crc32_of(r->imageData.pixels, (size_t)r->imageData.width * r->imageData.height * 4));
                break;
            case WAR_RESOURCE_TYPE_SPRITE:
            {
                u32 head = 0xFFFFFFFFu, pool = 0xFFFFFFFFu;
                size_t fsz = (size_t)r->spriteData.frameWidth * r->spriteData.frameHeight * 4;
                for (u32 k = 0; k < r->spriteData.framesCount; ++k)
                {
                    WarSpriteFrame* fr = &r->spriteData.frames[k];
                    u8 h[8] = { (u8)fr->dx, (u8)fr->dy, (u8)fr->w, (u8)fr->h,
                                (u8)fr->off, (u8)(fr->off >> 8), (u8)(fr->off >> 16), (u8)(fr->off >> 24) };
                    head = crc_update(head, h, 8);
                    pool = crc_update(pool, fr->data, fsz);
                }
                printf("S %d %u %u %u %08x %08x\n", index, r->spriteData.framesCount, r->spriteData.frameWidth,
                       r->spriteData.frameHeight, head ^ 0xFFFFFFFFu, pool ^ 0xFFFFFFFFu);
                break;
            }
            case WAR_RESOURCE_TYPE_CURSOR:
                printf("C %d %u %u %u %u %08x\n", index, r->cursor.hotx, r->cursor.hoty, r->cursor.width,
                       r->cursor.height, crc32_of(r->cursor.pixels, (size_t)r->cursor.width * r->cursor.height * 4));
                break;
            case WAR_RESOURCE_TYPE_TILES:
                printf("T %d %u %u %u %08x\n", index, r->tilesData.palette1, r->tilesData.palette2, raw->length,
                       crc32_of(r->tilesData.data, raw->length));
                break;
            case WAR_RESOURCE_TYPE_TILESET:
                printf("X %d %u %08x\n", index, r->tilesetData.tilesCount,
                       crc32_of(r->tilesetData.data, TILESET_WIDTH * TILESET_HEIGHT * 4));
                break;
            default:
                break;
        }
    }
    return 0;
}
