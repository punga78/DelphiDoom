/*
  Issue #198: harness di riferimento per l'audio di Libs\War.
  Compila il codice ORIGINALE di acoto87/war1 (zlib License, (C) 2019 Alejandro Coto Gutierrez; i tre convertitori
  shl/voc.h, shl/wav.h e shl/xmi2mid.h sono MIT, (c) 2026 Alejandro Coto Gutierrez): wres_loadXmi, wres_loadWave,
  wres_loadVoc di war_resources.c, wa_playWave di war_audio.c e le tre funzioni di war_math.c del volume
  posizionale sono estratti alla lettera da Compila-AudioRef.ps1 (file *.inc); qui ci sono solo gli stub di SDL,
  Tracy, wm_alloc, del log e della struct WarContext. Questo file e' una versione modificata del remake solo per far
  girare quel codice.

  Uso:  war_audio_ref DATA.WAR list        una riga per ogni risorsa audio (XMID, WAVE, VOC) nell'ordine di assets[]
        war_audio_ref DATA.WAR dump N file i byte della risorsa N dopo il caricamento (MIDI o PCM a 44100)
        war_audio_ref - synth              i casi sintetici di VOC e WAV (costruiti qui) e i convertitori
        war_audio_ref - mix                gli scenari del mixer (wa_playWave) su una risorsa sintetica
        war_audio_ref - position           il volume posizionale (il calcolo di audioDataCallback)
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <math.h>
#include <strings.h>

typedef int32_t s32;
typedef int64_t s64;
typedef uint8_t u8;
typedef uint16_t u16;
typedef int16_t s16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef float f32;
typedef size_t size32;

#define NOT_USED(expr) do { (void)(expr); } while (0)
#define arrayLength(arr) (sizeof(arr) / sizeof((arr)[0]))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define CLAMP(x, a, b) (MAX(MIN(x, b), a))

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
    NOT_USED(fmt);
}
#define logInfo(...) ((void)0)
#define logDebug(...) ((void)0)
#define logWarning(...) ((void)0)

#define wm_alloc(sz) calloc(1, ((sz) > 0 ? (sz) : 1))
#define wm_free(p) free(p)
#define wm_realloc(p, sz) realloc((p), (sz))

/* i tre convertitori del remake (MIT), come sono */
#define MINIVOC_IMPLEMENTATION
#include "shl/voc.h"
#define MINIWAVE_IMPLEMENTATION
#include "shl/wav.h"
#define XMI2MID_IMPLEMENTATION
#include "shl/xmi2mid.h"

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
#include "war_audio_enums.inc"
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
#include "war_res_audio.inc"

/* war_audio.h: il componente audio (senza i puntatori a tml, che qui non servono) */
typedef struct tml_message tml_message;
#include "war_audio_component.inc"
typedef struct _WarAudioComponent WarAudioComponent;
typedef struct { s32 id; WarAudioComponent audio; } WarEntity;
static WarAudioComponent* we_getAudioComponent(WarContext* context, const WarEntity* entity)
{
    NOT_USED(context);
    return (WarAudioComponent*)&entity->audio;
}
#include "war_audio_wave.inc"

/* war_math.h/.c: vec2, rect e le tre funzioni del volume posizionale */
typedef struct { f32 x, y; } vec2;
typedef struct { f32 x, y; f32 width, height; } rect;
static vec2 vec2f(f32 x, f32 y) { vec2 v = { x, y }; return v; }
#include "war_math_pos.inc"

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

static u32 floatBits(f32 f) { u32 u; memcpy(&u, &f, 4); return u; }

/* Riassunto di un file MIDI standard, indipendente da come e' scritto (ordine, running status, formato, divisione):
   gli eventi di canale che non sono un Note Off (Note On con velocita' > 0, program, controller, pressioni, pitch)
   come multiinsieme (le chiavi stato/dato1/dato2 ordinate, CRC-32), quanti Note On e Note Off (anche Note On con
   velocita' 0), e l'istante in microsecondi dell'ultimo Note On (i tempi si integrano con la mappa dei tempi del file). */
static int cmpU32(const void* a, const void* b)
{
    u32 x = *(const u32*)a, y = *(const u32*)b;
    return x < y ? -1 : (x > y ? 1 : 0);
}

static u32 midiReadVar(const u8* b, size_t* p)
{
    u32 v = 0;
    u8 c;
    do { c = b[(*p)++]; v = (v << 7) | (c & 0x7F); } while (c & 0x80);
    return v;
}

static void midiSummary(const u8* b, size_t n, u32* nOn, u32* nOff, u32* nOther, u32* eventsCrc, double* lastOnUs)
{
    u32* keys = (u32*)malloc(sizeof(u32) * (n + 1));
    size_t count = 0;
    *nOn = *nOff = *nOther = 0;
    *lastOnUs = 0;
    u32 division = (u32)(b[12] << 8 | b[13]);
    size_t p = 14;
    while (p + 8 <= n)
    {
        u32 len = (u32)b[p + 4] << 24 | (u32)b[p + 5] << 16 | (u32)b[p + 6] << 8 | b[p + 7];
        p += 8;
        size_t end = p + len;
        u32 tempo = 500000;
        double timeUs = 0;
        u32 running = 0;
        while (p < end)
        {
            u32 delta = midiReadVar(b, &p);
            timeUs += (double)delta * tempo / division;
            u32 status = b[p];
            if (status >= 0x80) p++; else status = running;
            if (status == 0xFF)
            {
                u8 type = b[p++];
                u32 l = midiReadVar(b, &p);
                if (type == 0x51 && l >= 3) tempo = (u32)b[p] << 16 | (u32)b[p + 1] << 8 | b[p + 2];
                p += l;
                continue;
            }
            if (status == 0xF0 || status == 0xF7) { u32 l = midiReadVar(b, &p); p += l; continue; }
            running = status;
            u32 d1 = b[p++], d2 = 0;
            if ((status & 0xF0) != 0xC0 && (status & 0xF0) != 0xD0) d2 = b[p++];
            u32 kind = status & 0xF0;
            if (kind == 0x80 || (kind == 0x90 && d2 == 0)) { (*nOff)++; continue; }
            if (kind == 0x90) { (*nOn)++; if (timeUs > *lastOnUs) *lastOnUs = timeUs; }
            else (*nOther)++;
            keys[count++] = status << 16 | d1 << 8 | d2;
        }
    }
    qsort(keys, count, sizeof(u32), cmpU32);
    *eventsCrc = crc32_of((const u8*)keys, count * sizeof(u32));
    free(keys);
}

/* il ricampionatore del remake legge oltre il buffer? (difetto del C: l'ultimo campione e' letto a src_idx1 == totale) */
static u32 resampleReadsPastEnd(u32 srcRate, u32 dstRate, u32 channels, u32 bits, u32 dataLength)
{
    if (srcRate == dstRate) return 0;
    u32 bps = (bits / 8) * channels;
    if (bps == 0) return 0;
    s32 totalSrc = dataLength / bps;
    if (channels == 1 && bits == 8)
    {
        if (dstRate == srcRate * 2 || dstRate == srcRate * 4 || srcRate == dstRate * 2 || srcRate == dstRate * 4)
            return 0;
    }
    double ratio = (double)srcRate / (double)dstRate;
    s32 totalDst = (s32)((double)totalSrc / ratio);
    u32 step = (u32)((ratio * 65536.0) + 0.5);
    u32 pos = 0, past = 0;
    for (s32 i = 0; i < totalDst; i++)
    {
        s32 idx1 = (s32)(pos >> 16);
        if (idx1 >= totalSrc) past++;
        pos += step;
    }
    return past * bps;
}

/* ---- casi sintetici ---- */

static u8* put16(u8* p, u32 v) { p[0] = (u8)v; p[1] = (u8)(v >> 8); return p + 2; }
static u8* put24(u8* p, u32 v) { p[0] = (u8)v; p[1] = (u8)(v >> 8); p[2] = (u8)(v >> 16); return p + 3; }
static u8* put32(u8* p, u32 v) { p[0] = (u8)v; p[1] = (u8)(v >> 8); p[2] = (u8)(v >> 16); p[3] = (u8)(v >> 24); return p + 4; }
static u8* putData(u8* p, u32 len) { for (u32 i = 0; i < len; ++i) *p++ = (u8)(i * 13 + 7); return p; }

typedef struct { const char* name; int kind; u32 a, b, c, len; } SynthCase;

static u8* buildVoc(const SynthCase* k, size_t* size)
{
    u8* buf = (u8*)calloc(1, 64 + k->len * 2 + 64);
    u8* p = buf;
    memcpy(p, "Creative Voice File\x1A", 20); p += 20;
    p = put16(p, 26);
    u32 version = 0x010A;
    p = put16(p, version);
    p = put16(p, (u16)(~version + 0x1234));
    switch (k->kind)
    {
        case 1: /* un blocco 0x01: a = divisore, len = byte */
            *p++ = 1; p = put24(p, k->len + 2); *p++ = (u8)k->a; *p++ = 0; p = putData(p, k->len); *p++ = 0; break;
        case 8: /* 0x08 (a = codice divisore, b = modo) e poi 0x01 */
            *p++ = 8; p = put24(p, 4); p = put16(p, k->a); *p++ = 0; *p++ = (u8)k->b;
            *p++ = 1; p = put24(p, k->len + 2); *p++ = 0; *p++ = 0; p = putData(p, k->len); *p++ = 0; break;
        case 9: /* 0x09: a = frequenza, b = bit, c = canali */
            *p++ = 9; p = put24(p, k->len + 12); p = put32(p, k->a); *p++ = (u8)k->b; *p++ = (u8)k->c;
            p = put16(p, 0); p = put32(p, 0); p = putData(p, k->len); *p++ = 0; break;
        case 10: /* due blocchi 0x01 con divisori diversi (il secondo decide la frequenza) e un blocco ignorato */
            *p++ = 1; p = put24(p, k->len + 2); *p++ = (u8)k->a; *p++ = 0; p = putData(p, k->len);
            *p++ = 6; p = put24(p, 2); *p++ = 1; *p++ = 2;
            *p++ = 1; p = put24(p, k->len / 2 + 2); *p++ = (u8)k->b; *p++ = 0; p = putData(p, k->len / 2); *p++ = 0; break;
        case 11: /* somma di controllo sbagliata */
            p[-1] ^= 0x55; *p++ = 1; p = put24(p, k->len + 2); *p++ = (u8)k->a; *p++ = 0; p = putData(p, k->len); *p++ = 0; break;
        case 12: /* compressione 1 */
            *p++ = 1; p = put24(p, k->len + 2); *p++ = (u8)k->a; *p++ = 1; p = putData(p, k->len); *p++ = 0; break;
        case 13: /* blocco piu' lungo di quello che resta */
            *p++ = 1; p = put24(p, k->len + 2 + 50); *p++ = (u8)k->a; *p++ = 0; p = putData(p, k->len); break;
        case 14: /* solo il terminatore */
            *p++ = 0; break;
        case 15: /* intestazione sola, 10 byte */
            p = buf + 10; break;
        case 16: /* 0x09 con formato 2 */
            *p++ = 9; p = put24(p, k->len + 12); p = put32(p, k->a); *p++ = (u8)k->b; *p++ = (u8)k->c;
            p = put16(p, 2); p = put32(p, 0); p = putData(p, k->len); *p++ = 0; break;
        case 17: /* 0x09 con formato 4 (accettato come 0) */
            *p++ = 9; p = put24(p, k->len + 12); p = put32(p, k->a); *p++ = (u8)k->b; *p++ = (u8)k->c;
            p = put16(p, 4); p = put32(p, 0); p = putData(p, k->len); *p++ = 0; break;
        case 18: /* data_offset oltre la fine */
            put16(buf + 20, 5000); *p++ = 0; break;
    }
    *size = (size_t)(p - buf);
    return buf;
}

static u8* buildWav(const SynthCase* k, size_t* size)
{
    /* a = frequenza, b = bit, c = canali; kind 1 canonico, 2 con un chunk LIST prima, 3 fmt da 18, 4 RIFF sbagliato,
       5 dati oltre la fine, 6 senza chunk data, 7 header troppo corto */
    u8* buf = (u8*)calloc(1, 128 + k->len + 64);
    u8* p = buf;
    u32 align = (k->b / 8) * k->c;
    memcpy(p, "RIFF", 4); p += 4; p = put32(p, 36 + k->len);
    memcpy(p, "WAVE", 4); p += 4;
    memcpy(p, "fmt ", 4); p += 4;
    p = put32(p, k->kind == 3 ? 18 : 16);
    p = put16(p, 1); p = put16(p, k->c); p = put32(p, k->a); p = put32(p, k->a * align); p = put16(p, align); p = put16(p, k->b);
    if (k->kind == 3) p = put16(p, 0);
    if (k->kind == 2) { memcpy(p, "LIST", 4); p += 4; p = put32(p, 6); for (int i = 0; i < 6; ++i) *p++ = (u8)(0x30 + i); }
    if (k->kind != 6)
    {
        memcpy(p, "data", 4); p += 4;
        p = put32(p, k->kind == 5 ? k->len + 40 : k->len);
    }
    p = putData(p, k->len);
    if (k->kind == 4) memcpy(buf, "RIFX", 4);
    *size = (size_t)(p - buf);
    if (k->kind == 7) *size = 30;
    return buf;
}

#include "war_synth_cases.inc"

static void printSpec(const char* tag, const SynthCase* k)
{
    printf("%s %s %d %u %u %u %u ", tag, k->name, k->kind, k->a, k->b, k->c, k->len);
}

static void runSynth(void)
{
    for (size_t i = 0; i < arrayLength(vocCases); ++i)
    {
        size_t size;
        u8* buf = buildVoc(&vocCases[i], &size);
        mv_audio_buffer a = {0}, b = {0};
        printSpec("V", &vocCases[i]);
        if (!mv_read_memory(buf, size, &a)) { printf("FAIL\n"); free(buf); continue; }
        u32 rawCrc = crc32_of(a.data, a.data_length);
        u32 oob = resampleReadsPastEnd(a.sample_rate, 44100, a.channels, a.bits_per_sample, a.data_length);
        if (a.channels == 0 || a.bits_per_sample < 8)
        {
            printf("UNSAFE\n");
            mv_free_buffer(&a); free(buf); continue;
        }
        if (!mv_resample_pcm(&a, &b, 44100)) { printf("RESAMPLEFAIL\n"); mv_free_buffer(&a); free(buf); continue; }
        printf("%u %u %u %u %08x %u %08x %d\n", a.channels, a.sample_rate, a.bits_per_sample,
               a.data_length, rawCrc, b.data_length, crc32_of(b.data, b.data_length - oob), oob);
        mv_free_buffer(&a); mv_free_buffer(&b); free(buf);
    }
    for (size_t i = 0; i < arrayLength(wavCases); ++i)
    {
        size_t size;
        u8* buf = buildWav(&wavCases[i], &size);
        mw_audio_buffer a = {0}, b = {0};
        printSpec("W", &wavCases[i]);
        if (!mw_read_memory(buf, size, &a)) { printf("FAIL\n"); free(buf); continue; }
        u32 rawCrc = crc32_of(a.data, a.data_length);
        u32 oob = resampleReadsPastEnd(a.sample_rate, 44100, a.channels, a.bits_per_sample, a.data_length);
        if (a.channels == 0 || a.bits_per_sample < 8)
        {
            printf("UNSAFE\n");
            mw_free_buffer(&a); free(buf); continue;
        }
        if (!mw_resample_pcm(&a, &b, 44100)) { printf("RESAMPLEFAIL\n"); mw_free_buffer(&a); free(buf); continue; }
        printf("%u %u %u %u %08x %u %08x %d\n", a.channels, a.sample_rate, a.bits_per_sample,
               a.data_length, rawCrc, b.data_length, crc32_of(b.data, b.data_length - oob), oob);
        mw_free_buffer(&a); mw_free_buffer(&b); free(buf);
    }
}

/* ---- mixer: wa_playWave sull'originale, su una risorsa sintetica ---- */

typedef struct { f32 volume; int loop; int calls; u32 counts[6]; } MixCase;

static void runMix(void)
{
    static const MixCase cases[] = {
        { 1.0f,        0, 4, { 1000, 1000, 1000, 1000 } },
        { 0.5f,        1, 3, { 4096, 8192, 77 } },
        { 0.75f,       0, 3, { 2999, 1, 1 } },
        { 0.3333333f,  1, 1, { 5000 } },
        { 1.5f,        0, 1, { 100 } },
        { 0.0f,        0, 1, { 50 } },
        { 0.1f,        0, 2, { 3000, 1 } },
        { 1.0f,        1, 2, { 2999, 3 } },
        { 0.9f,        0, 5, { 600, 600, 600, 600, 600 } },
    };
    u8 wave[3000];
    for (int i = 0; i < 3000; ++i) wave[i] = (u8)((i * 37) ^ (i >> 3));
    WarResource resources[2];
    memset(resources, 0, sizeof(resources));
    resources[1].type = WAR_RESOURCE_TYPE_VOC;
    resources[1].audio.data = wave;
    resources[1].audio.length = 3000;
    WarContext context = {0};
    context.resources = resources;
    static s16 out[10000];
    for (size_t c = 0; c < arrayLength(cases); ++c)
    {
        WarEntity entity;
        memset(&entity, 0, sizeof(entity));
        entity.audio.resourceIndex = 1;
        entity.audio.loop = cases[c].loop != 0;
        for (int call = 0; call < cases[c].calls; ++call)
        {
            u32 n = cases[c].counts[call];
            for (u32 i = 0; i < n; ++i) out[i] = (s16)((i + call * 11) * 7919u);
            bool r = wa_playWave(&context, &entity, n, out, cases[c].volume);
            printf("A %zu %d %d %d %08x %08x\n", c, call, r ? 1 : 0, entity.audio.sampleIndex,
                   floatBits(entity.audio.playbackTime), crc32_of((u8*)out, n * 2));
        }
    }
}

static void runPosition(void)
{
    rect viewport = { 100.0f, 50.0f, 240.0f, 160.0f };
    static const f32 pts[][2] = {
        { 220, 130 }, { 100, 50 }, { 340, 210 }, { 99, 130 }, { 341, 130 }, { 220, 49 }, { 220, 211 },
        { 60, 130 }, { 20, 130 }, { 0, 0 }, { 500, 400 }, { 340, 340 }, { 400, 130 }, { 420, 130 }, { 438.5f, 131 },
        { 300, 300 }, { 150, 250 }, { 1024, 1024 }, { 241, 130 }, { 339.9f, 130.25f },
    };
    static const f32 vols[] = { 1.0f, 0.6f, 0.0f };
    for (size_t v = 0; v < arrayLength(vols); ++v)
        for (size_t i = 0; i < arrayLength(pts); ++i)
        {
            f32 volume = vols[v];
            vec2 position = vec2f(pts[i][0], pts[i][1]);
            /* come audioDataCallback di war_audio.c (le sue righe, con il volume iniziale) */
            if (!rect_containsf(viewport, position.x, position.y))
            {
                vec2 viewportCenter = rect_center(viewport);
                f32 distance = vec2_distance(position, viewportCenter);
                volume = 0.75f * (1 - ((distance - 120) / 80));
                volume = MAX(volume, 0);
            }
            printf("P %zu %zu %08x\n", v, i, floatBits(volume));
        }
}

static void loadAudio(WarContext* context, DatabaseEntry* entry)
{
    switch (entry->type)
    {
        case DB_ENTRY_TYPE_XMID: wres_loadXmi(context, entry); break;
        case DB_ENTRY_TYPE_WAVE: wres_loadWave(context, entry); break;
        case DB_ENTRY_TYPE_VOC: wres_loadVoc(context, entry); break;
        default: break;
    }
}

int main(int argc, char** argv)
{
    crc_init();
    if (argc < 3)
        return 2;
    if (strcmp(argv[2], "synth") == 0) { runSynth(); return 0; }
    if (strcmp(argv[2], "mix") == 0) { runMix(); return 0; }
    if (strcmp(argv[2], "position") == 0) { runPosition(); return 0; }

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

    for (size_t i = 0; i < arrayLength(assets); ++i)
    {
        DatabaseEntry entry = assets[i];
        loadAudio(&context, &entry);
    }

    if (strcmp(argv[2], "dump") == 0 && argc >= 5)
    {
        int n = atoi(argv[3]);
        WarResource* r = &context.resources[n];
        FILE* f = fopen(argv[4], "wb");
        fwrite(r->audio.data, 1, r->audio.length, f);
        fclose(f);
        return 0;
    }

    for (size_t i = 0; i < arrayLength(assets); ++i)
    {
        s32 index = assets[i].index;
        WarResource* r = &context.resources[index];
        WarRawResource* raw = &context.warFile->resources[index];
        if (assets[i].type != DB_ENTRY_TYPE_XMID && assets[i].type != DB_ENTRY_TYPE_WAVE && assets[i].type != DB_ENTRY_TYPE_VOC)
            continue;
        if (raw->placeholder) { printf("N %d placeholder\n", index); continue; }
        switch (r->type)
        {
            case WAR_RESOURCE_TYPE_XMID:
            {
                u32 nOn, nOff, nOther, evCrc;
                double lastOn;
                midiSummary(r->audio.data, r->audio.length, &nOn, &nOff, &nOther, &evCrc, &lastOn);
                printf("M %d %u %08x %d %08x %u %u %u %08x %.0f\n", index, (u32)raw->length,
                       crc32_of(raw->data, raw->length), r->audio.length, crc32_of(r->audio.data, r->audio.length),
                       nOn, nOff, nOther, evCrc, lastOn);
                break;
            }
            case WAR_RESOURCE_TYPE_WAVE:
            {
                mw_audio_buffer a = {0};
                mw_read_memory(raw->data, raw->length, &a);
                printf("W %d %u %u %u %u %08x %d %08x %d\n", index, a.channels, a.sample_rate, a.bits_per_sample,
                       a.data_length, crc32_of(a.data, a.data_length), r->audio.length,
                       crc32_of(r->audio.data, r->audio.length - resampleReadsPastEnd(a.sample_rate, 44100, a.channels, a.bits_per_sample, a.data_length)),
                       resampleReadsPastEnd(a.sample_rate, 44100, a.channels, a.bits_per_sample, a.data_length));
                mw_free_buffer(&a);
                break;
            }
            case WAR_RESOURCE_TYPE_VOC:
            {
                mv_audio_buffer a = {0};
                mv_read_memory(raw->data, raw->length, &a);
                printf("V %d %u %u %u %u %08x %d %08x %d\n", index, a.channels, a.sample_rate, a.bits_per_sample,
                       a.data_length, crc32_of(a.data, a.data_length), r->audio.length,
                       crc32_of(r->audio.data, r->audio.length - resampleReadsPastEnd(a.sample_rate, 44100, a.channels, a.bits_per_sample, a.data_length)),
                       resampleReadsPastEnd(a.sample_rate, 44100, a.channels, a.bits_per_sample, a.data_length));
                mv_free_buffer(&a);
                break;
            }
            default:
                printf("E %d not loaded\n", index);
                break;
        }
    }
    return 0;
}
