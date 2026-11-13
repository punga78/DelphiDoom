/*
  Issue #198 / #194: harness di riferimento per la SCELTA dei suoni di Libs\War.
  Compila il codice ORIGINALE di acoto87/war1 (zlib License, (C) 2019 Alejandro Coto Gutierrez): wa_playAttackSound,
  wa_playDudeSelectionSound, wa_playBuildingSelectionSound e wa_playAcknowledgementSound di war_audio.c sono estratti
  alla lettera da Compila-SoundRef.ps1 (war_play_sounds.inc), con le enumerazioni (war_enums.h) e CreateAudioArgs
  (war_audio.h). Qui ci sono solo gli stub: wa_createAudio* (scrivono quello che l'originale chiede: un suono o un
  intervallo da cui sceglie a caso), le funzioni che dicono di che razza e' una unita' e in che stato e' un edificio.
  Questo file e' una versione modificata del remake solo per far girare quel codice.

  Uso:  war_sound_ref tables       gli esiti di ogni funzione per ogni ingresso possibile

  Righe di "tables":
    A passo               F id | R primo ultimo | N        wa_playAttackSound (passo 0..10)
    D umano solo          F id | R primo ultimo | N        wa_playDudeSelectionSound (razza umana 1/0, e' l'unico selezionato 1/0)
    B costruzione hp max tipo    F id | R primo ultimo     wa_playBuildingSelectionSound
    K umano               F id | R primo ultimo | N        wa_playAcknowledgementSound (primo suono dopo l'intervallo)
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
typedef uint32_t u32;
typedef float f32;
typedef double f64;
typedef uint16_t WarEntityId;

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define PERCENTF(x) ((x) * 100)
#define PERCENTI(x) ((s32)PERCENTF(x))
#define PERCENTF01(a, b) ((f32)(a)/(b))
#define PERCENTABI(a, b) PERCENTI(PERCENTF01(a, b))
#define logWarning(...) ((void)0)
#define assert(x) ((void)0)
#define MIN_ACK_SOUND_INTERVAL 0.15f

#include "war_race_enum.inc"
#include "war_unit_enum.inc"
#include "war_step_enum.inc"
#include "war_audio_enums.inc"

typedef struct _WarContext WarContext;
typedef struct _WarEntity WarEntity;
typedef struct _WarPlayerInfo WarPlayerInfo;
typedef struct _WarMap WarMap;
typedef struct _WarUnitComponent WarUnitComponent;
typedef struct { float x, y; } vec2;

#include "war_create_audio_args.inc"

struct _WarEntity { int id; };
struct _WarPlayerInfo { WarRace race; };
struct _WarUnitComponent { s32 hp; s32 maxhp; WarUnitType type; };
struct _WarMap
{
    f64 lastAcknowledgementRealTime;
    struct { int count; WarEntityId items[8]; } selectedEntities;
};
struct _WarContext { WarMap* map; f64 realTime; };

#define isHumanPlayer(player) ((player)->race == WAR_RACE_HUMANS)

/* lo "stato" del mondo che le funzioni leggono: lo decide il pilota */
static WarEntity g_entity = { 7 };
static WarUnitComponent g_unit;
static bool g_human, g_isDude, g_isBuilding, g_goingToBuild;
static WarEntity g_created;

static bool wu_isDudeUnit(WarContext* c, WarEntity* e) { (void)c; (void)e; return g_isDude; }
static bool wu_isBuildingUnit(WarContext* c, WarEntity* e) { (void)c; (void)e; return !g_isDude; }
static bool wu_isHumanUnit(WarContext* c, WarEntity* e) { (void)c; (void)e; return g_human; }
static bool wst_isBuilding(WarContext* c, WarEntity* e) { (void)c; (void)e; return g_isBuilding; }
static bool wst_isGoingToBuild(WarContext* c, WarEntity* e) { (void)c; (void)e; return g_goingToBuild; }
static WarUnitComponent* we_getUnitComponent(WarContext* c, WarEntity* e) { (void)c; (void)e; return &g_unit; }

/* wa_createAudio*: scrivono la richiesta e danno un'entita' qualunque (non NULL) */
static char g_last[96];
static WarEntity* wa_createAudio(WarContext* c, const CreateAudioArgs* a)
{
    (void)c;
    sprintf(g_last, "F %d", (int)a->audioId);
    return &g_created;
}
static WarEntity* wa_createAudioWithPosition(WarContext* c, const CreateAudioArgs* a) { return wa_createAudio(c, a); }
static WarEntity* wa_createAudioRandom(WarContext* c, const CreateAudioArgs* a)
{
    (void)c;
    sprintf(g_last, "R %d %d", (int)a->randomFromId, (int)a->randomToId);
    return &g_created;
}
static WarEntity* wa_createAudioRandomWithPosition(WarContext* c, const CreateAudioArgs* a) { return wa_createAudioRandom(c, a); }

#include "war_play_sounds.inc"

static void report(char tag, int a, int b, int c, int d, WarEntity* r)
{
    printf("%c %d %d %d %d ", tag, a, b, c, d);
    if (r)
        printf("%s\n", g_last);
    else
        printf("N\n");
}

int main(int argc, char** argv)
{
    WarContext ctx;
    WarMap map;
    WarPlayerInfo human, orc;
    int step, human_i, solo, constr, hp, unit;
    static const int hps[][2] = { {100, 100}, {34, 100}, {33, 100}, {32, 100}, {1, 100}, {0, 100}, {50, 150}, {49, 150}, {51, 150}, {300, 900} };
    if (argc < 2 || strcmp(argv[1], "tables") != 0)
    {
        fprintf(stderr, "uso: war_sound_ref tables\n");
        return 2;
    }
    memset(&map, 0, sizeof(map));
    ctx.map = &map;
    ctx.realTime = 0;
    human.race = WAR_RACE_HUMANS;
    orc.race = WAR_RACE_ORCS;
    for (step = 0; step <= 10; step++)
    {
        g_last[0] = 0;
        report('A', step, 0, 0, 0, wa_playAttackSound(&ctx, (vec2){0}, (WarUnitActionStepType)step));
    }
    g_isDude = true;
    for (human_i = 0; human_i < 2; human_i++)
        for (solo = 0; solo < 2; solo++)
        {
            g_human = human_i != 0;
            map.selectedEntities.count = solo ? 1 : 2;
            map.selectedEntities.items[0] = solo ? (WarEntityId)g_entity.id : (WarEntityId)(g_entity.id + 1);
            report('D', human_i, solo, 0, 0, wa_playDudeSelectionSound(&ctx, &g_entity));
        }
    g_isDude = false;
    for (constr = 0; constr < 3; constr++)
        for (hp = 0; hp < (int)(sizeof(hps) / sizeof(hps[0])); hp++)
            for (unit = WAR_UNIT_FARM_HUMANS; unit <= WAR_UNIT_BLACKSMITH_ORCS; unit++)
            {
                g_isBuilding = constr == 1;
                g_goingToBuild = constr == 2;
                g_unit.hp = hps[hp][0];
                g_unit.maxhp = hps[hp][1];
                g_unit.type = unit;
                printf("B %d %d %d %d ", constr, hps[hp][0], hps[hp][1], unit);
                printf("%s\n", (g_last[0] = 0, wa_playBuildingSelectionSound(&ctx, &g_entity)) ? g_last : "N");
            }
    for (human_i = 0; human_i < 2; human_i++)
    {
        map.lastAcknowledgementRealTime = 0;
        ctx.realTime = 1.0;
        g_last[0] = 0;
        report('K', human_i, 0, 0, 0, wa_playAcknowledgementSound(&ctx, human_i ? &human : &orc));
    }
    return 0;
}
