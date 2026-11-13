/*
  Issue #198: harness di riferimento per il tempo e gli eventi della musica di Libs\War.
  Compila il codice ORIGINALE di acoto87/war1 (zlib License, (C) 2019 Alejandro Coto Gutierrez): wa_playMidi di
  war_audio.c e' estratto alla lettera da Compila-MusicRef.ps1 (war_play_midi.inc), con la struct WarAudioComponent
  (war_audio.h) e WarAudioType (war_enums.h); il lettore di file MIDI e' tml.h di TinySoundFont (zlib License,
  (c) 2017, 2018 Bernhard Schelling), usato come sta in Reference\war1\deps\include. Qui ci sono solo gli stub:
  il sintetizzatore (tsf_*) non suona, SCRIVE le chiamate che wa_playMidi gli fa, con la posizione (in campioni)
  del blocco da 64 in cui sono avvenute. Questo file e' una versione modificata del remake solo per far girare quel codice.

  Uso:  war_music_ref scenarios        gli scenari (file MIDI generati qui con un seme fisso) e le chiamate al synth

  Righe:
    # chunks 441 1000 64 8192 37 4410     le dimensioni delle chiamate a wa_playMidi, in ordine e a ripetizione
    S id tracce divisione loop campioni bit-del-volume smf-in-esadecimale
    E posizione PC canale programma batteria         tsf_channel_set_presetnumber
    E posizione ON canale tasto bit-della-velocita'  tsf_channel_note_on (velocity * volume, float in esadecimale)
    E posizione OF canale tasto                       tsf_channel_note_off
    E posizione PB canale valore                      tsf_channel_set_pitchwheel
    E posizione CC canale controller valore           tsf_channel_midi_control
    E posizione AO                                    tsf_note_off_all
    X id finito posizione                             wa_playMidi ha detto "finito" (1) alla fine della chiamata che finisce a posizione
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

typedef int32_t s32;
typedef int8_t s8;
typedef uint8_t u8;
typedef uint16_t u16;
typedef int16_t s16;
typedef uint32_t u32;
typedef float f32;

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#include "war_defines.inc"

#include "TinySoundFont/tsf.h"
/* definite da tsf.h solo nella parte di implementazione, che qui non serve: gli stessi valori */
#define TSF_RENDER_EFFECTSAMPLEBLOCK 64
#define TSF_TRUE 1
#define TML_IMPLEMENTATION
#include "TinySoundFont/tml.h"

#include "war_audio_enums.inc"

typedef struct _WarContext WarContext;
typedef struct _WarEntity WarEntity;
typedef struct _WarAudioComponent WarAudioComponent;
typedef int WarResourceKind;

#include "war_audio_component.inc"

struct _WarContext { tsf* soundFont; };
struct _WarEntity { WarAudioComponent audio; };

static WarAudioComponent* we_getAudioComponent(WarContext* context, WarEntity* entity)
{
    (void)context;
    return &entity->audio;
}

#define assert(x) ((void)0)

/* il sintetizzatore finto: scrive le chiamate */
static long g_pos;
static int g_event_scenario;
static void ev(const char* fmt, ...) __attribute__((format(printf, 1, 2)));
#include <stdarg.h>
static void ev(const char* fmt, ...)
{
    va_list args;
    printf("E %ld ", g_pos);
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    printf("\n");
}
static unsigned f32bits(float v)
{
    unsigned u;
    memcpy(&u, &v, 4);
    return u;
}

int tsf_channel_set_presetnumber(tsf* f, int channel, int preset_number, int flag_mididrums)
{
    (void)f;
    ev("PC %d %d %d", channel, preset_number, flag_mididrums);
    return 1;
}
void tsf_channel_note_on(tsf* f, int channel, int key, float vel)
{
    (void)f;
    ev("ON %d %d %08x", channel, key, f32bits(vel));
}
void tsf_channel_note_off(tsf* f, int channel, int key)
{
    (void)f;
    ev("OF %d %d", channel, key);
}
void tsf_channel_set_pitchwheel(tsf* f, int channel, int pitch_wheel)
{
    (void)f;
    ev("PB %d %d", channel, pitch_wheel);
}
void tsf_channel_midi_control(tsf* f, int channel, int controller, int control_value)
{
    (void)f;
    ev("CC %d %d %d", channel, controller, control_value);

}
void tsf_note_off_all(tsf* f, int quick)
{
    (void)f;
    (void)quick;
    ev("AO");
}
void tsf_render_short(tsf* f, short* buffer, int samples, int flag_mixing)
{
    (void)f;
    (void)buffer;
    (void)flag_mixing;
    g_pos += samples;
}

#include "war_play_midi.inc"

/* ---- il generatore dei file MIDI (nessun materiale commerciale) ---- */
static u32 g_seed;
static u32 rnd(void)
{
    g_seed = g_seed * 1664525u + 1013904223u;
    return g_seed >> 8;
}

typedef struct { u8* data; int size, cap; } Buf;
static void put(Buf* b, int v)
{
    if (b->size == b->cap)
    {
        b->cap = b->cap ? b->cap * 2 : 256;
        b->data = (u8*)realloc(b->data, b->cap);
    }
    b->data[b->size++] = (u8)v;
}
static void putvlq(Buf* b, u32 v)
{
    u8 tmp[5];
    int n = 0;
    tmp[n++] = v & 0x7F;
    while ((v >>= 7) != 0)
        tmp[n++] = (v & 0x7F) | 0x80;
    while (n)
        put(b, tmp[--n]);
}

#define MAX_TRACKS 4

/* Gli scenari evitano i difetti di tml e di wa_playMidi che Libs\War non conserva (vedi il README di Libs\War):
   - eventi a tick globali distinti fra tracce diverse (con un pareggio l'ordine di fusione puo' essere diverso);
   - il primo evento e' della traccia 0 (altrimenti tml_load perde messaggi);
   - EOT con delta 0 nei brani che non si ripetono (con un delta tml lo tiene nella lista e l'EOT di una traccia
     fermerebbe le altre); nei brani che si ripetono una sola traccia e EOT con delta: senza un messaggio EOT nella
     lista wa_playMidi non ricomincia mai (finisce in silenzio) e con piu' tracce il primo EOT ferma il giro;
   - nessun evento meta o sysex (il sequencer di Libs\Midi non li da': il tempo fino all'ultimo messaggio sarebbe
     diverso) */
static Buf makeSmf(u32 seed, int tracks, int division, int events, int lastKind, int eotDelta)
{
    Buf out = { 0, 0, 0 };
    Buf trk[MAX_TRACKS];
    u32 lastTick[MAX_TRACKS];
    int last = 0, i, t;
    u32 tick = 0;
    memset(trk, 0, sizeof(trk));
    memset(lastTick, 0, sizeof(lastTick));
    g_seed = seed;
    for (i = 0; i < events; i++)
    {
        u32 delta = (rnd() % 4 == 0) ? 0 : 1 + rnd() % (u32)(division * 2);
        int track = last, kind, ch;
        if (delta != 0)
            track = (int)(rnd() % (u32)tracks);
        else if (i == 0)
            delta = 1;
        /* il primo evento della canzone e' sempre della traccia 0: se fosse di un'altra, tml_load scambia il suo primo messaggio con quello (ancora da leggere) della traccia 0 e ne perde eventi (difetto di tml, vedi il README di Libs/War) */
        if (i == 0)
            track = 0;
        tick += delta;
        ch = (int)(rnd() % 16);
        kind = (int)(rnd() % 10);
        if (i == events - 1)
            kind = lastKind;
        putvlq(&trk[track], tick - lastTick[track]);
        lastTick[track] = tick;
        switch (kind)
        {
            case 0: case 1: case 2:
                put(&trk[track], 0x90 | ch); put(&trk[track], (int)(rnd() % 128)); put(&trk[track], (int)(rnd() % 128));
                break;
            case 3: case 4:
                put(&trk[track], 0x80 | ch); put(&trk[track], (int)(rnd() % 128)); put(&trk[track], (int)(rnd() % 128));
                break;
            case 5:
                put(&trk[track], 0xC0 | ch); put(&trk[track], (int)(rnd() % 128));
                break;
            case 6:
                put(&trk[track], 0xB0 | ch); put(&trk[track], (int)(rnd() % 128)); put(&trk[track], (int)(rnd() % 128));
                break;
            case 7:
                put(&trk[track], 0xE0 | ch); put(&trk[track], (int)(rnd() % 128)); put(&trk[track], (int)(rnd() % 128));
                break;
            case 8:
            {
                u32 tempo = 250000 + rnd() % 750000;
                put(&trk[track], 0xFF); put(&trk[track], 0x51); put(&trk[track], 3);
                put(&trk[track], (int)(tempo >> 16)); put(&trk[track], (int)((tempo >> 8) & 255)); put(&trk[track], (int)(tempo & 255));
                break;
            }
            default:
                if (rnd() % 2) { put(&trk[track], 0xA0 | ch); put(&trk[track], (int)(rnd() % 128)); put(&trk[track], (int)(rnd() % 128)); }
                else { put(&trk[track], 0xD0 | ch); put(&trk[track], (int)(rnd() % 128)); }
                break;
        }
        last = track;
    }
    for (t = 0; t < tracks; t++)
    {
        putvlq(&trk[t], (u32)eotDelta); put(&trk[t], 0xFF); put(&trk[t], 0x2F); put(&trk[t], 0);
    }
    put(&out, 'M'); put(&out, 'T'); put(&out, 'h'); put(&out, 'd');
    put(&out, 0); put(&out, 0); put(&out, 0); put(&out, 6);
    put(&out, 0); put(&out, tracks > 1 ? 1 : 0);
    put(&out, 0); put(&out, tracks);
    put(&out, division >> 8); put(&out, division & 255);
    for (t = 0; t < tracks; t++)
    {
        put(&out, 'M'); put(&out, 'T'); put(&out, 'r'); put(&out, 'k');
        put(&out, (trk[t].size >> 24) & 255); put(&out, (trk[t].size >> 16) & 255);
        put(&out, (trk[t].size >> 8) & 255); put(&out, trk[t].size & 255);
        for (i = 0; i < trk[t].size; i++)
            put(&out, trk[t].data[i]);
        free(trk[t].data);
    }
    return out;
}

static const int chunks[] = { 441, 1000, 64, 8192, 37, 4410 };

typedef struct { u32 seed; int tracks, division, events, loop, lastKind; long samples; float volume; } Scenario;

static const Scenario scenarios[] = {
    { 1, 1, 96, 40, 0, 3, 44100L * 150, 1.0f },
    { 2, 1, 120, 60, 0, 6, 44100L * 150, 0.5f },
    { 3, 2, 480, 80, 0, 4, 44100L * 150, 0.73f },
    { 4, 3, 96, 100, 0, 9, 44100L * 150, 1.0f },
    { 5, 1, 192, 50, 1, 3, 44100L * 40, 1.0f },
    { 6, 1, 96, 30, 1, 8, 44100L * 40, 0.25f },
    { 7, 1, 240, 120, 1, 4, 44100L * 40, 0.9f },
    { 8, 1, 60, 70, 0, 3, 44100L * 150, 0.6f },
    { 9, 1, 60, 90, 1, 9, 44100L * 40, 1.0f },
    { 10, 1, 1000, 25, 0, 5, 44100L * 150, 0.33f },
    { 11, 1, 15, 45, 1, 3, 44100L * 40, 1.0f },
    { 12, 3, 384, 150, 0, 3, 44100L * 150, 0.8f },
};

int main(int argc, char** argv)
{
    size_t k;
    if (argc < 2 || strcmp(argv[1], "scenarios") != 0)
    {
        fprintf(stderr, "uso: war_music_ref scenarios\n");
        return 2;
    }
    printf("# chunks");
    for (k = 0; k < sizeof(chunks) / sizeof(chunks[0]); k++)
        printf(" %d", chunks[k]);
    printf("\n");
    for (k = 0; k < sizeof(scenarios) / sizeof(scenarios[0]); k++)
    {
        const Scenario* sc = &scenarios[k];
        Buf smf = makeSmf(sc->seed, sc->tracks, sc->division, sc->events, sc->lastKind, sc->loop ? sc->division : 0);
        tml_message* first = tml_load_memory(smf.data, smf.size);
        static char fake[64];
        WarContext context;
        WarEntity entity;
        long done = 0;
        int c = 0, finished = 0, i;
        printf("S %d %d %d %d %ld %08x ", (int)(k + 1), sc->tracks, sc->division, sc->loop, sc->samples, f32bits(sc->volume));
        for (i = 0; i < smf.size; i++)
            printf("%02x", smf.data[i]);
        printf("\n");
        if (!first)
        {
            printf("X %d 0 0\n", (int)(k + 1));
            free(smf.data);
            continue;
        }
        memset(fake, 0, sizeof(fake));
        context.soundFont = (tsf*)fake;
        memset(&entity, 0, sizeof(entity));
        entity.audio.enabled = true;
        entity.audio.loop = sc->loop != 0;
        entity.audio.firstMessage = first;
        entity.audio.currentMessage = first;
        g_pos = 0;
        while (done < sc->samples)
        {
            long n = chunks[c++ % (int)(sizeof(chunks) / sizeof(chunks[0]))];
            if (n > sc->samples - done)
                n = sc->samples - done;
            finished = wa_playMidi(&context, &entity, (u32)n, NULL, sc->volume);
            done += n;
            if (finished)
                break;
        }
        printf("X %d %d %ld\n", (int)(k + 1), finished, g_pos);
        tml_free(first);
        free(smf.data);
    }
    return 0;
}
