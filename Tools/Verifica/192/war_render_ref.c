/*
  Issue #192 (seconda fetta): harness di riferimento per il testo e gli sprite di Libs\War.
  Compila il codice ORIGINALE di acoto87/war1 (zlib License, (C) 2019 Alejandro Coto Gutierrez) estratto alla lettera da
  Compila-RenderRef.ps1 (file *.inc): war_font.c (le funzioni di misura, di divisione in righe e di disegno del testo),
  war_render.c (la pila delle trasformazioni e wr_subImage), war_sprites.c intero e le funzioni wres_* che leggono i
  record grafici. Qui ci sono solo gli stub di SDL (le texture e le chiamate di disegno REGISTRANO cio' che ricevono),
  di Tracy, del log e di StringView (wsv_slice come in shl/wstr.h). Questo file e' una versione modificata del remake
  solo per far girare quel codice.

  Uso:  war_render_ref - text              scenari di testo con seme fisso: misure e, per ogni disegno, la lista dei blit
        war_render_ref DATA.WAR sprites    WarSprite di ogni immagine, sprite e cursore (con e senza sottoinsieme di fotogrammi)
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <strings.h>
#include <math.h>

typedef int32_t s32;
typedef int64_t s64;
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef float f32;

#define NOT_USED(expr) do { (void)(expr); } while (0)
#define arrayLength(arr) (sizeof(arr) / sizeof((arr)[0]))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))

#include "war_defines.inc"

typedef struct { const char* data; size_t length; } StringView;
static const char* wsv_data(StringView v) { return v.data; }
static size_t wsv_length(StringView v) { return v.length; }
static StringView wsv_fromCString(const char* s)
{
    StringView v;
    v.data = s;
    v.length = s ? strlen(s) : 0;
    return v;
}
static StringView wsv_slice(StringView view, size_t index, size_t length)
{
    StringView empty = { NULL, 0 };
    if (index >= view.length) return empty;
    size_t available = view.length - index;
    if (length > available) length = available;
    StringView r = { view.data + index, length };
    return r;
}
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

#define wm_alloc(sz) calloc(1, ((sz) > 0 ? (sz) : 1))
#define wm_allocFrame(sz) calloc(1, ((sz) > 0 ? (sz) : 1))
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
typedef struct _WarSprite WarSprite;
typedef struct _WarSpriteResourceRef WarSpriteResourceRef;
typedef struct _WarFontData WarFontData;
typedef int WarUnitType;
typedef int WarResourceKind;
typedef int WarConstructType;
typedef int WarRace;

typedef union {
    uint32_t packed;
    uint8_t rgba[4];
    struct { uint8_t r, g, b, a; };
} WarColor;
#define WAR_COLOR_RGBA_INIT(r_, g_, b_, a_) {.r = r_, .g = g_, .b = b_, .a = a_}
#define WAR_COLOR_PACKED_INIT(value) { .packed = (uint32_t)(value) }
#define WAR_COLOR_PACKED(value) ((WarColor)WAR_COLOR_PACKED_INIT(value))
#define WAR_COLOR_GREEN_SELECTION WAR_COLOR_PACKED(0xFF00C700)
#define WAR_COLOR_RED_SELECTION WAR_COLOR_PACKED(0xFF0000C7)

void wfile_freeWarFile(WarFile* warFile);

#include "war_types.inc"
#include "war_enums.inc"
#include "war_resource_type.inc"
#include "war_sprite_frame.inc"
#include "war_types2.inc"
#include "war_core.inc"
#include "war_database_copy.h"

typedef struct { f32 x, y; } vec2;
typedef struct { f32 x, y, width, height; } rect;
#define VEC2_ZERO ((vec2){0.0f, 0.0f})
#define VEC2_ONE ((vec2){1.0f, 1.0f})
#define VEC2_IS_ZERO(v) ((v).x == 0.0f && (v).y == 0.0f)
static vec2 vec2f(f32 x, f32 y) { vec2 v; v.x = x; v.y = y; return v; }
static vec2 vec2i(s32 x, s32 y) { vec2 v; v.x = (f32)x; v.y = (f32)y; return v; }
static rect rectf(f32 x, f32 y, f32 w, f32 h) { rect r = { x, y, w, h }; return r; }
static rect rectv(vec2 pos, vec2 size) { rect r = { pos.x, pos.y, size.x, size.y }; return r; }

typedef enum { WAR_TEXT_ALIGN_LEFT, WAR_TEXT_ALIGN_CENTER, WAR_TEXT_ALIGN_RIGHT, WAR_TEXT_ALIGN_TOP, WAR_TEXT_ALIGN_MIDDLE,
               WAR_TEXT_ALIGN_BOTTOM, WAR_TEXT_ALIGN_COUNT } WarTextAlignment;
typedef enum { WAR_TEXT_WRAP_NONE, WAR_TEXT_WRAP_CHAR } WarTextWrapping;
typedef enum { WAR_TEXT_TRIM_NONE, WAR_TEXT_TRIM_SPACES, WAR_TEXT_TRIM_ALL } WarTextTrimming;
enum { WAR_DEBUG_RENDER_FONT, WAR_DEBUG_RENDER_COUNT };

/* ---- SDL: le texture e le chiamate di disegno registrano cio' che ricevono ---- */
typedef struct { f32 x, y, w, h; } SDL_FRect;
typedef struct
{
    s32 width, height;
    u8 colorR, colorG, colorB, alphaMod;
    u8* pixels;
} SDL_Texture;
typedef struct { s32 dummy; } SDL_Renderer;
typedef int SDL_FlipMode;
#define SDL_FLIP_NONE 0
#define SDL_FLIP_HORIZONTAL 1
#define SDL_FLIP_VERTICAL 2
#define SDL_PIXELFORMAT_RGBA32 0
#define SDL_TEXTUREACCESS_STREAMING 0
#define SDL_SCALEMODE_NEAREST 0
#define SDL_BLENDMODE_BLEND 1

static SDL_Texture* SDL_CreateTexture(SDL_Renderer* r, int format, int access, int w, int h)
{
    NOT_USED(r); NOT_USED(format); NOT_USED(access);
    SDL_Texture* t = (SDL_Texture*)calloc(1, sizeof(SDL_Texture));
    t->width = w;
    t->height = h;
    t->colorR = t->colorG = t->colorB = 255;
    t->alphaMod = 255;
    return t;
}
static void SDL_SetTextureScaleMode(SDL_Texture* t, int m) { NOT_USED(t); NOT_USED(m); }
static void SDL_UpdateTexture(SDL_Texture* t, void* r, const void* d, int pitch) { NOT_USED(t); NOT_USED(r); NOT_USED(d); NOT_USED(pitch); }
static void SDL_DestroyTexture(SDL_Texture* t) { free(t); }
static void SDL_SetTextureColorMod(SDL_Texture* t, u8 r, u8 g, u8 b) { t->colorR = r; t->colorG = g; t->colorB = b; }
static void SDL_SetTextureAlphaMod(SDL_Texture* t, u8 a) { t->alphaMod = a; }
static void SDL_SetTextureBlendMode(SDL_Texture* t, int m) { NOT_USED(t); NOT_USED(m); }
static void SDL_SetRenderDrawColor(SDL_Renderer* r, u8 a, u8 b, u8 c, u8 d) { NOT_USED(r); NOT_USED(a); NOT_USED(b); NOT_USED(c); NOT_USED(d); }
static void SDL_SetRenderDrawBlendMode(SDL_Renderer* r, int m) { NOT_USED(r); NOT_USED(m); }
static void SDL_RenderFillRect(SDL_Renderer* r, const SDL_FRect* d) { NOT_USED(r); NOT_USED(d); }
static void SDL_RenderRect(SDL_Renderer* r, const SDL_FRect* d) { NOT_USED(r); NOT_USED(d); }
static void SDL_RenderLine(SDL_Renderer* r, f32 a, f32 b, f32 c, f32 d) { NOT_USED(r); NOT_USED(a); NOT_USED(b); NOT_USED(c); NOT_USED(d); }

typedef struct { f32 sx, sy, sw, sh, dx, dy, dw, dh; int flip; u8 r, g, b, a; } Blit;
static Blit blits[100000];
static s32 blitCount;
static void recordBlit(SDL_Texture* t, const SDL_FRect* s, const SDL_FRect* d, int flip)
{
    Blit* b = &blits[blitCount++];
    b->sx = s->x; b->sy = s->y; b->sw = s->w; b->sh = s->h;
    b->dx = d->x; b->dy = d->y; b->dw = d->w; b->dh = d->h;
    b->flip = flip;
    b->r = t->colorR; b->g = t->colorG; b->b = t->colorB; b->a = t->alphaMod;
}
static void SDL_RenderTexture(SDL_Renderer* r, SDL_Texture* t, const SDL_FRect* s, const SDL_FRect* d)
{
    NOT_USED(r);
    recordBlit(t, s, d, SDL_FLIP_NONE);
}
static void SDL_RenderTextureRotated(SDL_Renderer* r, SDL_Texture* t, const SDL_FRect* s, const SDL_FRect* d, double angle,
                                     const void* center, SDL_FlipMode flip)
{
    NOT_USED(r); NOT_USED(angle); NOT_USED(center);
    recordBlit(t, s, d, flip);
}

struct _WarRenderState { f32 offsetX, offsetY, scaleX, scaleY, alpha; };
typedef struct _WarRenderState WarRenderState;
typedef struct { bool flags[WAR_DEBUG_RENDER_COUNT]; } WarDebugRenderFlags;

struct _WarContext
{
    SDL_Renderer* renderer;
    WarRenderState renderState[MAX_RENDER_STATE_STACK];
    s32 renderStateTop;
    WarDebugRenderFlags debugRender;
    WarFile* warFile;
    WarResource* resources;
};

#include "war_read_macros.inc"
#include "war_res_a.inc"
#include "war_res_tiles.inc"
#include "war_res_cursor.inc"

#include "war_render.inc"

struct _WarSprite
{
    SDL_Texture* texture;
    s32 frameWidth;
    s32 frameHeight;
    s32 framesCount;
    WarSpriteFrame frames[MAX_SPRITE_FRAME_COUNT];
};
#include "war_sprites_header.inc"
#include "war_sprites_body.inc"

#include "war_font_defines.inc"
#include "war_font_header.inc"
#include "war_font_table.inc"
#include "war_font_funcs.inc"

/* ---- impronte ---- */
static u32 crc_table[256];
static void crc_init(void)
{
    for (u32 i = 0; i < 256; ++i)
    {
        u32 c = i;
        for (int k = 0; k < 8; ++k) c = (c & 1) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
        crc_table[i] = c;
    }
}
static u32 crc_update(u32 c, const u8* p, size_t n)
{
    for (size_t i = 0; i < n; ++i) c = crc_table[(c ^ p[i]) & 0xFF] ^ (c >> 8);
    return c;
}
static u32 crc32_of(const u8* p, size_t n) { return crc_update(0xFFFFFFFFu, p, n) ^ 0xFFFFFFFFu; }

static u32 rngState;
static void rngSeed(u32 seed) { rngState = seed; }
static u32 rngNext(void)
{
    rngState = rngState * 1103515245u + 12345u;
    return (rngState >> 16) & 0x7FFFu;
}
static s32 rngRange(s32 n) { return (s32)(rngNext() % (u32)n); }

static u32 f32bits(f32 v) { u32 u; memcpy(&u, &v, 4); return u; }

static void put32(u32* crc, u32 v) { u8 b[4] = { (u8)v, (u8)(v >> 8), (u8)(v >> 16), (u8)(v >> 24) }; *crc = crc_update(*crc, b, 4); }

static u32 blitsCrc(s32 from)
{
    u32 crc = 0xFFFFFFFFu;
    for (s32 i = from; i < blitCount; i++)
    {
        Blit* b = &blits[i];
        put32(&crc, f32bits(b->sx)); put32(&crc, f32bits(b->sy)); put32(&crc, f32bits(b->sw)); put32(&crc, f32bits(b->sh));
        put32(&crc, f32bits(b->dx)); put32(&crc, f32bits(b->dy)); put32(&crc, f32bits(b->dw)); put32(&crc, f32bits(b->dh));
        put32(&crc, (u32)b->flip);
        u8 c[4] = { b->r, b->g, b->b, b->a };
        crc = crc_update(crc, c, 4);
    }
    return crc ^ 0xFFFFFFFFu;
}

static SDL_Texture fontTexture;

static void runText(void)
{
    crc_init();
    WarContext context = {0};
    wr_init(&context);
    static const char alphabet[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~";
    static const f32 sizes[] = { 48.0f, 24.0f, 36.0f, 64.0f, 96.0f, 13.5f, 72.0f };
    fontTexture.width = 512; fontTexture.height = 512;
    for (int s = 0; s < 240; s++)
    {
        rngSeed(11000 + (u32)s);
        char text[128];
        int n = rngRange(70);
        for (int i = 0; i < n; i++)
        {
            int t = rngRange(24);
            if (t == 0) text[i] = '\n';
            else if (t == 1) text[i] = '\t';
            else if (t < 5) text[i] = ' ';
            else if (t == 5 && rngRange(8) == 0) text[i] = (char)(0xE0 + rngRange(16));
            else text[i] = alphabet[rngRange((int)(sizeof(alphabet) - 1))];
        }
        text[n] = 0;
        WarFontParams p;
        memset(&p, 0, sizeof(p));
        int fontIndex = rngRange(2);
        p.fontIndex = fontIndex;
        p.fontData = fontsData[fontIndex];
        p.fontSize = sizes[rngRange((int)arrayLength(sizes))];
        p.lineHeight = rngRange(3) == 0 ? (f32)(20 + rngRange(60)) : 0.0f;
        p.fontColor.packed = 0xFFDBFFEFu;
        p.highlightColor.packed = 0xFF49E3FFu;
        p.fontColor.r = (u8)(rngRange(2) == 0 ? 0xEF : rngRange(256));
        int hmode = rngRange(4);
        p.highlightIndex = hmode == 0 ? -1 : hmode == 1 ? -2 : rngRange(n + 1);
        /* il C legge text.data[hi + hc - 1]: oltre la fine del testo legge memoria non definita (il terminatore e
           poi la pila): gli scenari restano dentro il testo, la libreria fuori dal testo da' EWarException */
        int maxCount = n - (p.highlightIndex >= 0 ? p.highlightIndex : 0);
        p.highlightCount = rngRange(MIN(12, maxCount + 1));
        if (rngRange(3) != 0)
        {
            p.boundings.x = (f32)(40 + rngRange(400));
            p.boundings.y = (f32)(30 + rngRange(300));
        }
        p.horizontalAlign = (WarTextAlignment)rngRange(3);
        p.verticalAlign = (WarTextAlignment)(3 + rngRange(3));
        p.lineAlign = (WarTextAlignment)rngRange(3);
        p.wrapping = (WarTextWrapping)rngRange(2);
        p.trimming = (WarTextTrimming)rngRange(3);
        p.fontSprite.texture = &fontTexture;
        f32 px = (f32)rngRange(300);
        f32 py = (f32)rngRange(200);

        StringView sv = wsv_fromCString(text);
        vec2 m1 = wfont_measureSingleSpriteText(sv, -1, p);
        vec2 m2 = wfont_measureMultiSpriteText(sv, p.boundings.x, p);
        vec2 m3 = wfont_measureSingleSpriteText(sv, n / 2, p);
        printf("M %d %08x %08x %08x %08x %08x %08x\n", s, f32bits(m1.x), f32bits(m1.y), f32bits(m2.x), f32bits(m2.y),
               f32bits(m3.x), f32bits(m3.y));

        s32 from = blitCount;
        wfont_renderSingleSpriteText(&context, sv, px, py, p);
        printf("R %d %d %08x\n", s, blitCount - from, blitsCrc(from));
        from = blitCount;
        wfont_renderMultiSpriteText(&context, sv, px, py, p);
        printf("L %d %d %08x\n", s, blitCount - from, blitsCrc(from));
        if (s < 6 && blitCount > from)
        {
            Blit* b = &blits[from];
            printf("B %d %08x %08x %08x %08x %08x %08x %08x %08x %d %d %d %d %d\n", s, f32bits(b->sx), f32bits(b->sy),
                   f32bits(b->sw), f32bits(b->sh), f32bits(b->dx), f32bits(b->dy), f32bits(b->dw), f32bits(b->dh), b->flip,
                   b->r, b->g, b->b, b->a);
        }
        if (context.renderStateTop != 0) printf("E pila %d\n", context.renderStateTop);
        blitCount = 0;
    }
    /* il testo corto: i casi dell'allineamento a destra (lo stesso del centro nel C) */
    WarFontParams q;
    memset(&q, 0, sizeof(q));
    q.fontData = fontsData[0];
    q.fontSize = 48.0f;
    q.boundings.x = 300.0f;
    q.boundings.y = 100.0f;
    q.horizontalAlign = WAR_TEXT_ALIGN_RIGHT;
    q.verticalAlign = WAR_TEXT_ALIGN_BOTTOM;
    q.highlightIndex = -1;
    q.fontSprite.texture = &fontTexture;
    vec2 o = wfont_getAlignmentOffset(q.horizontalAlign, q.verticalAlign, q.boundings, vec2f(100.0f, 30.0f));
    printf("A %08x %08x\n", f32bits(o.x), f32bits(o.y));
}

static void dumpSprite(const char* tag, s32 index, WarSprite* s)
{
    u32 head = 0xFFFFFFFFu, pool = 0xFFFFFFFFu;
    size_t fsz = (size_t)s->frameWidth * s->frameHeight * 4;
    for (s32 k = 0; k < s->framesCount; ++k)
    {
        WarSpriteFrame* fr = &s->frames[k];
        u8 h[8] = { (u8)fr->dx, (u8)(fr->dx >> 8), (u8)fr->dy, (u8)(fr->dy >> 8), (u8)fr->w, (u8)(fr->w >> 8), (u8)fr->h, (u8)(fr->h >> 8) };
        head = crc_update(head, h, 8);
        pool = crc_update(pool, fr->data, fsz);
    }
    printf("%s %d %d %d %d %08x %08x\n", tag, index, s->frameWidth, s->frameHeight, s->framesCount, head ^ 0xFFFFFFFFu, pool ^ 0xFFFFFFFFu);
}

static void runSprites(const char* path)
{
    crc_init();
    bool skipDecompress[MAX_RESOURCES_COUNT];
    memset(skipDecompress, 0, sizeof(skipDecompress));
    for (size_t i = 0; i < arrayLength(assets); ++i)
        if (assets[i].type == DB_ENTRY_TYPE_UNKNOWN)
            skipDecompress[assets[i].index] = true;
    WarContext context = {0};
    wr_init(&context);
    context.warFile = wfile_loadWarFile(NULL, wsv_fromCString(path), skipDecompress);
    if (!context.warFile)
    {
        printf("FAIL\n");
        exit(1);
    }
    context.resources = (WarResource*)calloc(MAX_RESOURCES_COUNT, sizeof(WarResource));
    for (size_t i = 0; i < arrayLength(assets); ++i)
    {
        DatabaseEntry entry = assets[i];
        switch (entry.type)
        {
            case DB_ENTRY_TYPE_PALETTE: wres_loadPaletteResource(&context, &entry); break;
            case DB_ENTRY_TYPE_IMAGE: wres_loadImageResource(&context, &entry); break;
            case DB_ENTRY_TYPE_SPRITE: wres_loadSpriteResource(&context, &entry); break;
            case DB_ENTRY_TYPE_TILES: wres_loadTiles(&context, &entry); break;
            case DB_ENTRY_TYPE_CURSOR: wres_loadCursor(&context, &entry); break;
            default: break;
        }
    }
    for (size_t i = 0; i < arrayLength(assets); ++i)
    {
        s32 index = assets[i].index;
        WarResource* r = &context.resources[index];
        if (r->type != WAR_RESOURCE_TYPE_IMAGE && r->type != WAR_RESOURCE_TYPE_SPRITE && r->type != WAR_RESOURCE_TYPE_CURSOR)
            continue;
        WarSprite all = wspr_createSpriteFromResource(&context, r, 0, NULL);
        dumpSprite("W", index, &all);
        if (r->type == WAR_RESOURCE_TYPE_SPRITE)
        {
            s32 count = (s32)r->spriteData.framesCount;
            s32 pick[4];
            s32 k = 0;
            pick[k++] = count - 1;
            if (count > 1) pick[k++] = 0;
            if (count > 2) pick[k++] = count / 2;
            if (count > 3) pick[k++] = 1;
            WarSprite sub = wspr_createSpriteFromResource(&context, r, k, pick);
            dumpSprite("U", index, &sub);
            /* un fotogramma letto da wspr_getSpriteFrame */
            WarSpriteFrame fr = wspr_getSpriteFrame(&context, sub, k - 1);
            printf("G %d %u %u %u %u\n", index, fr.dx, fr.dy, fr.w, fr.h);
        }
        /* disegno: i blit con la scala del fotogramma, specchiata e ingrandita */
        s32 from = blitCount;
        wr_save(&context);
        wr_translate(&context, 10.0f, 20.0f);
        wspr_renderSprite(&context, all, vec2f(3.0f, 4.0f), VEC2_ONE);
        wspr_renderSprite(&context, all, vec2f(3.0f, 4.0f), vec2f(-1.0f, 1.0f));
        wspr_renderSprite(&context, all, vec2f(3.0f, 4.0f), vec2f(1.0f, -1.0f));
        wspr_renderSprite(&context, all, vec2f(3.0f, 4.0f), vec2f(-2.0f, -2.5f));
        wr_scale(&context, -1.0f, 1.0f);
        wr_globalAlpha(&context, 0.5f);
        wspr_renderSubSprite(&context, all, rectf(1.0f, 2.0f, 5.0f, 6.0f), rectf(7.0f, 8.0f, 5.0f, 6.0f), vec2f(2.0f, 2.0f));
        wr_restore(&context);
        printf("D %d %d %08x\n", index, blitCount - from, blitsCrc(from));
        blitCount = 0;
    }
}

int main(int argc, char** argv)
{
    if (argc < 3)
    {
        printf("uso: war_render_ref - text | DATA.WAR sprites\n");
        return 2;
    }
    if (strcmp(argv[2], "text") == 0) runText();
    else if (strcmp(argv[2], "sprites") == 0) runSprites(argv[1]);
    else return 2;
    return 0;
}
