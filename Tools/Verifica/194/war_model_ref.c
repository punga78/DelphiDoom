/*
  Issue #194 (prima fetta): harness di riferimento per il modello di gioco di Libs\War (entita', unita', macchina a stati,
  economia, danni).

  Il remake in C (acoto87/war1, zlib License, (C) 2019 Alejandro Coto Gutierrez) e' una "unity build": un solo file che
  include tutti i .c. Qui si fa lo stesso con i soli .c che servono (war_log, war_alloc, war_math, war_collections,
  war_actions, war_units, war_entities, war_pathfinder, war_rvo, war_map, tutti i war_state_machine*): il codice del remake e'
  quello ORIGINALE, incluso cosi' com'e', senza estrarre pezzi. Le intestazioni arrivano da tests\test_main.c (estratte da
  Compila-ModelRef.ps1 in war_head.inc).

  Cio' che e' nostro (versione modificata del remake solo per far girare quel codice):
    - gli stub di SDL (SDL_rand: il generatore di Warcraft non e' ripetibile, qui e' un LCG con seme; SDL_LockMutex ...),
      della grafica (wspr_*), dell'audio (wa_*), dell'interfaccia (wmui_*) e dei comandi;
    - il flusso dei campi (wpath_ensureFlowField, wpath_flowFieldSample, wpath_computeFlowField) e la ricerca dei vicini di
      wrvo_gatherNeighbours: il remake sa girare attorno agli ostacoli e alle altre unita' (#195); qui valgono "nessun
      ostacolo" (campo di flusso nullo: il movimento va in linea retta verso il prossimo punto) e "nessun vicino". Le
      definizioni originali sono rinominate con #define prima di includere il loro file;
    - gli scenari, l'impronta dello stato e il programma principale.

  Uso:  war_model_ref tables                 tabelle del database, classificazione, azioni
        war_model_ref scenarios [n]          n scenari amichevoli (default 20): una riga per tic con l'impronta dello stato
        war_model_ref hostile [n]            n scenari con due fazioni: si fermano al primo ordine di attacco
        war_model_ref dump friendly SEED TIC il testo dello stato dello scenario a quel tic (per cercare una differenza)
        war_model_ref dump hostile SEED TIC
        war_model_ref gather [n]             n scenari di raccolta (default 10, 1800 tic): oro, legna, consegna, miniere, alberi
        war_model_ref gather-tables          i passi dell'azione di raccolta e le immagini dei trasportatori
        war_model_ref dump gather SEED TIC
*/
#include <time.h>
#include "war_head.inc"

#include "war_ui.h"
#include "war_projectiles.h"
#include "war_commands.h"
#include "war_file.h"
#include "war_animations.h"
#include "war_audio.h"

/* funzioni che war_map.c chiama e che il remake dichiara solo nei suoi .c (qui non servono: si dichiara soltanto) */
void wcmd_executeMoveCommand(WarContext* context, vec2 targetPosition);
void wcmd_executeFollowCommand(WarContext* context, WarEntity* targetEntity);
void wcmd_executeHarvestCommand(WarContext* context, WarEntity* targetEntity, vec2 targetTile);
void wcmd_executeDeliverCommand(WarContext* context, WarEntity* targetEntity);
void wcmd_executeAttackCommand(WarContext* context, WarEntity* targetEntity, vec2 targetPosition);
void wproj_updateProjectile(WarContext* context, WarEntity* entity);

#include "war_log.c"
#include "war_alloc.c"
#include "war_math.c"
#include "war_collections.c"
#include "war_actions.c"
#include "war_animations.c"
#include "war_roads.c"
#include "war_walls.c"
#include "war_ruins.c"
#include "war_trees.c"
#include "war_units.c"
/* DIFETTO DEL REMAKE NON CONSERVATO: we_addSpriteComponent non toglie lo sprite che l'entita' ha gia' e ne lascia uno orfano
   nell'array denso; alla prima we_removeSpriteComponent che sposta l'ultimo elemento l'orfano (stesso proprietario) torna a
   essere lo sprite dell'entita': un lavoratore che esce dalla miniera che ha esaurito (wst_exitMiningState aggiunge lo sprite
   normale senza togliere quello che porta l'oro) mostra poi l'immagine sbagliata. Qui lo sprite che c'e' si toglie prima di
   aggiungerne un altro (e cosi' in Delphi: l'immagine che si aggiunge sostituisce quella che c'e'). */
#define we_addSpriteComponentFromResource we_addSpriteComponentFromResource_orig
#include "war_entities.c"
#undef we_addSpriteComponentFromResource
WarSpriteComponent* we_addSpriteComponentFromResource(WarContext* context, WarEntity* entity, WarSpriteResourceRef spriteResourceRef)
{
    if (entity && entity->components[COMP_SPRITE] != INVALID_COMP_INDEX)
        we_removeSpriteComponent(context, entity);
    return we_addSpriteComponentFromResource_orig(context, entity, spriteResourceRef);
}

/* il percorso: il remake sa girare attorno agli ostacoli (#195); qui le tre funzioni del campo di flusso sono sostituite
   da stub (piu' sotto) e le definizioni originali restano con un altro nome */
#define wpath_ensureFlowField wpath_ensureFlowField_orig
#define wpath_flowFieldSample wpath_flowFieldSample_orig
#define wpath_computeFlowField wpath_computeFlowField_orig
#include "war_pathfinder.c"
#undef wpath_ensureFlowField
#undef wpath_flowFieldSample
#undef wpath_computeFlowField

#define wrvo_gatherNeighbours wrvo_gatherNeighbours_orig
#include "war_rvo.c"
#undef wrvo_gatherNeighbours

#include "war_state_machine_idle.c"
#include "war_state_machine_move.c"
#include "war_state_machine_follow.c"
#include "war_state_machine_patrol.c"
#include "war_state_machine_attack.c"
#include "war_state_machine_death.c"
/* il crollo e' di un'altra fetta (#194, costruzione e crollo): qui l'ingresso nello stato non fa nulla (il remake chiede una
   mappa con le rovine e un'animazione) e il giro di aggiornamento del crollo non si chiama negli scenari di raccolta; il
   modello di Delphi non registra procedure per questo tipo di stato */
#define wst_enterCollapseState wst_enterCollapseState_orig
#include "war_state_machine_collapse.c"
#undef wst_enterCollapseState
#include "war_state_machine_wait.c"
#include "war_state_machine_gather_gold.c"
#include "war_state_machine_mining.c"
#include "war_state_machine_gather_wood.c"
#include "war_state_machine_chopping.c"
#include "war_state_machine_deliver.c"
#include "war_state_machine_train.c"
#include "war_state_machine_upgrade.c"
#include "war_state_machine_build.c"
#include "war_state_machine_repair.c"
#include "war_state_machine_repairing.c"
#include "war_state_machine_cast.c"
#include "war_state_machine.c"
#include "war_map_grid.c"
/* la tessera della mappa visiva: il remake la scrive nelle risorse del livello (qui non ci sono); si registra la scrittura */
#define wmap_setMapTileIndex wmap_setMapTileIndex_orig
#include "war_map.c"
#undef wmap_setMapTileIndex


/* ------------------------------------------------------------------------------------------------------------------ */
/* stub                                                                                                               */
/* ------------------------------------------------------------------------------------------------------------------ */

/* il generatore del gioco: stesso algoritmo di TWarSeededRandom (Libs\War\DelphiDoom.War.Sound.SeededRandom.pas) */
static u32 gGameState = 0;
static u32 gGameDraws = 0;
static u32 gGameSum = 0;
static int gTrace = 0;

static u32 lcgNext(u32* state)
{
    *state = *state * 1664525u + 1013904223u;
    return *state >> 8;
}

Sint32 SDL_rand(Sint32 n)
{
    Sint32 r = n <= 0 ? 0 : (Sint32)(lcgNext(&gGameState) % (u32)n);
    gGameDraws++;
    if (gTrace)
        fprintf(stderr, "r %d %d\n", (int)n, (int)r);
    gGameSum = gGameSum * 31u + (u32)r + 1u;
    return r;
}

void SDL_LockMutex(SDL_Mutex* mutex) { (void)mutex; }
void SDL_UnlockMutex(SDL_Mutex* mutex) { (void)mutex; }
void SDL_SetLogPriority(int category, SDL_LogPriority priority) { (void)category; (void)priority; }
void SDL_LogMessage(int category, SDL_LogPriority priority, SDL_PRINTF_FORMAT_STRING const char* fmt, ...)
{
    (void)category; (void)priority; (void)fmt;
}
int SDL_vsnprintf(char* text, size_t maxlen, const char* fmt, va_list ap) { return vsnprintf(text, maxlen, fmt, ap); }

/* la grafica: lo sprite di una unita' non e' stato di gioco */
WarSprite wspr_createSpriteFromResourceIndex(WarContext* context, WarSpriteResourceRef ref)
{
    (void)context; (void)ref;
    return (WarSprite){0};
}
void wspr_freeSprite(WarContext* context, WarSprite sprite) { (void)context; (void)sprite; }

/* l'interfaccia, l'audio e le animazioni (si contano soltanto, perche' fanno parte dell'impronta) */
static u32 gFlashCount = 0;
void wmui_setFlashStatus(WarContext* context, f32 time, String text)
{
    (void)context; (void)time; (void)text;
    gFlashCount++;
}
static u32 gAudioCount = 0;
WarEntity* wa_createAudioWithPosition(WarContext* context, const CreateAudioArgs* args) { (void)context; (void)args; gAudioCount++; return NULL; }
WarEntity* wa_createAudioRandomWithPosition(WarContext* context, const CreateAudioArgs* args) { (void)context; (void)args; gAudioCount++; return NULL; }

/* war_ui.c non e' incluso: wui_isUIEntity e' una funzione di sola lettura del tipo dell'entita' (le unita' non sono dell'interfaccia) */
bool wui_isUIEntity(WarEntity* entity)
{
    switch (entity->type)
    {
        case WAR_ENTITY_TYPE_IMAGE:
        case WAR_ENTITY_TYPE_TEXT:
        case WAR_ENTITY_TYPE_RECT:
        case WAR_ENTITY_TYPE_BUTTON:
        case WAR_ENTITY_TYPE_CURSOR:
        case WAR_ENTITY_TYPE_MINIMAP:
            return true;
        default:
            return false;
    }
}

/* il percorso: nessun ostacolo, il campo di flusso e' nullo e il passo e' verso il prossimo punto */
static WarMapFlowField gNullFlowField;
WarMapFlowField* wpath_ensureFlowField(WarPathFinder* finder, s32 x, s32 y) { (void)finder; (void)x; (void)y; return &gNullFlowField; }
vec2 wpath_flowFieldSample(WarMapFlowField* flowField, s32 x, s32 y) { (void)flowField; (void)x; (void)y; return VEC2_ZERO; }
WarMapFlowField* wpath_computeFlowField(WarPathFinder* finder, s32 x, s32 y) { (void)finder; (void)x; (void)y; return &gNullFlowField; }
s32 wrvo_gatherNeighbours(WarContext* context, s32 selfId, vec2 centrePixel, f32 radiusPx, WarRvoNeighbour out[RVO_MAX_NB])
{
    (void)context; (void)selfId; (void)centrePixel; (void)radiusPx; (void)out;
    return 0;
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* il mondo                                                                                                           */
/* ------------------------------------------------------------------------------------------------------------------ */

static WarContext* gContext;
static WarMap* gMap;
static u32 gScriptState;
static u32 gResults;

static u32 scriptBelow(u32 n) { return n == 0 ? 0 : lcgNext(&gScriptState) % n; }

static void resultMix(u32 value) { gResults = gResults * 16777619u ^ value; }

static void worldInit(u32 gameSeed, u32 scriptSeed)
{
    gGameState = gameSeed;
    gGameDraws = 0;
    gGameSum = 0;
    gScriptState = scriptSeed;
    gResults = 2166136261u;
    gFlashCount = 0;
    gAudioCount = 0;

    wm_allocInit(256ull * 1024 * 1024, 8ull * 1024 * 1024, 1ull * 1024 * 1024);

    gContext = (WarContext*)wm_alloc(sizeof(WarContext));
    memset(gContext, 0, sizeof(WarContext));
    gContext->globalSpeed = 1.0f;
    gContext->globalScale = 1.0f;
    gContext->gameTime = 0.0;
    gContext->gameDeltaTime = 0.0f;

    gMap = (WarMap*)wm_alloc(sizeof(WarMap));
    memset(gMap, 0, sizeof(WarMap));
    gContext->map = gMap;
    gMap->settings.gameSpeed = WAR_SPEED_NORMAL;

    we_initEntityManager(gContext, &gMap->entityManager);
    WarEntityIdListInit(&gMap->selectedEntities, wm_globalAllocator());
    for (s32 i = 0; i < MAX_SELECTION_GROUPS; i++)
        WarEntityIdListInit(&gMap->selectionGroups[i], wm_globalAllocator());

    u16 passable[MAP_TILES_WIDTH * MAP_TILES_HEIGHT];
    memset(passable, 0, sizeof(passable));
    gMap->finder = wpath_initPathFinder(passable);
    gMap->playing = true;
    gMap->fowEnabled = false;

    wact_initUnitActionDefs();

    for (s32 i = 0; i < MAX_PLAYERS_COUNT; i++)
    {
        gMap->players[i].index = (u8)i;
        gMap->players[i].race = i == 0 ? WAR_RACE_HUMANS : (i == 4 ? WAR_RACE_NEUTRAL : WAR_RACE_ORCS);
        gMap->players[i].gold = 5000;
        gMap->players[i].wood = 5000;
        for (s32 u = 0; u < MAX_UPGRADES_COUNT; u++)
            gMap->players[i].upgrades[u].allowed = 2;
    }
    gMap->playersCount = MAX_PLAYERS_COUNT;
}

static void worldFree(void)
{
    wm_allocFree();
    gContext = NULL;
    gMap = NULL;
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* l'impronta dello stato: un testo, uguale a quello di Tests\Source\DelphiDoom.Tests.War.ModelDump.pas               */
/* ------------------------------------------------------------------------------------------------------------------ */

typedef struct { char* data; size_t length; size_t capacity; } Text;

static void textAdd(Text* t, const char* fmt, ...)
{
    char line[1024];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(line, sizeof(line), fmt, ap);
    va_end(ap);
    if (n < 0) return;
    if (t->length + (size_t)n + 1 > t->capacity)
    {
        t->capacity = (t->capacity + (size_t)n + 1) * 2;
        t->data = (char*)realloc(t->data, t->capacity);
    }
    memcpy(t->data + t->length, line, (size_t)n);
    t->length += (size_t)n;
    t->data[t->length] = 0;
}

static u32 fbits(f32 v)
{
    u32 b;
    memcpy(&b, &v, 4);
    return b;
}

static void dbits(f64 v, u32* lo, u32* hi)
{
    u64 b;
    memcpy(&b, &v, 8);
    *lo = (u32)(b & 0xFFFFFFFFu);
    *hi = (u32)(b >> 32);
}

static u32 fnv1a(const char* data, size_t length)
{
    u32 h = 2166136261u;
    for (size_t i = 0; i < length; i++)
    {
        h ^= (u8)data[i];
        h *= 16777619u;
    }
    return h;
}

static void dumpState(Text* t, WarStateBase* s, WarStateRef ref)
{
    u32 tlo, thi;
    dbits(s->nextUpdateGameTime, &tlo, &thi);
    textAdd(t, " S%d.%d.%u e=%d nx=%08x%08x dl=%08x", ref.type, ref.idx, ref.generation, s->entityId, thi, tlo, fbits(s->delay));
    switch (s->type)
    {
        case WAR_STATE_IDLE:
            textAdd(t, " look=%d", ((WarStateIdle*)s)->lookAround ? 1 : 0);
            break;
        case WAR_STATE_MOVE:
        {
            WarStateMove* m = (WarStateMove*)s;
            textAdd(t, " wi=%d wc=%d chk=%d", m->waypointsIndex, m->waypointsCount, m->checkForAttacks ? 1 : 0);
            for (s32 i = 0; i < m->waypointsCount; i++)
                textAdd(t, " w%d=%08x,%08x", i, fbits(m->waypoints[i].x), fbits(m->waypoints[i].y));
            textAdd(t, " rv=%08x,%08x pb=%08x np=%08x lv=%08x ra=%d", fbits(m->rvoVelocity.x), fbits(m->rvoVelocity.y),
                    fbits(m->progress.bestDistanceSq), fbits(m->progress.noProgressTime), fbits(m->progress.lowVelocityTime),
                    m->progress.recoveryAttempt);
            textAdd(t, " pg=%08x,%08x pw=%d pv=%08x,%08x av=%08x,%08x", fbits(m->progressGoalPosition.x), fbits(m->progressGoalPosition.y),
                    m->progressWaypointIndex, fbits(m->rvoPreferredVelocity.x), fbits(m->rvoPreferredVelocity.y),
                    fbits(m->rvoAdjustedVelocity.x), fbits(m->rvoAdjustedVelocity.y));
            break;
        }
        case WAR_STATE_FOLLOW:
        {
            WarStateFollow* f = (WarStateFollow*)s;
            textAdd(t, " tg=%d tp=%08x,%08x td=%d", f->targetEntityId, fbits(f->targetPosition.x), fbits(f->targetPosition.y),
                    f->targetDistance);
            break;
        }
        case WAR_STATE_GOLD:
            textAdd(t, " gm=%d", ((WarStateGold*)s)->goldmineId);
            break;
        case WAR_STATE_MINING:
            textAdd(t, " gm=%d mt=%08x", ((WarStateMining*)s)->goldmineId, fbits(((WarStateMining*)s)->miningTime));
            break;
        case WAR_STATE_WOOD:
            textAdd(t, " fo=%d fp=%08x,%08x", ((WarStateWood*)s)->forestId, fbits(((WarStateWood*)s)->position.x),
                    fbits(((WarStateWood*)s)->position.y));
            break;
        case WAR_STATE_CHOPPING:
            textAdd(t, " fo=%d fp=%08x,%08x", ((WarStateChopping*)s)->forestId, fbits(((WarStateChopping*)s)->position.x),
                    fbits(((WarStateChopping*)s)->position.y));
            break;
        case WAR_STATE_DELIVER:
        {
            WarStateDeliver* d = (WarStateDeliver*)s;
            textAdd(t, " th=%d in=%d cy=%d sk=%d si=%d sp=%08x,%08x", d->townHallId, d->insideBuilding ? 1 : 0, d->cycle ? 1 : 0,
                    (s32)d->sourceKind, d->sourceId, fbits(d->sourcePosition.x), fbits(d->sourcePosition.y));
            break;
        }
        case WAR_STATE_ATTACK:
        {
            WarStateAttack* a = (WarStateAttack*)s;
            textAdd(t, " tg=%d tp=%08x,%08x", a->targetEntityId, fbits(a->targetPosition.x), fbits(a->targetPosition.y));
            break;
        }
        case WAR_STATE_WAIT:
        {
            u32 lo, hi;
            dbits(((WarStateWait*)s)->waitEndGameTime, &lo, &hi);
            textAdd(t, " we=%08x%08x", hi, lo);
            break;
        }
        default:
            break;
    }
}

static void dumpWorld(Text* t, s32 tic)
{
    WarEntityManager* m = &gMap->entityManager;
    u32 tlo, thi;
    dbits(gContext->gameTime, &tlo, &thi);
    textAdd(t, "W tic=%d time=%08x%08x ents=%d next=%d draws=%u sum=%08x flash=%u audio=%u res=%08x\n", tic, thi, tlo,
            m->entityCount, m->nextEntityId, gGameDraws, gGameSum, gFlashCount, gAudioCount, gResults);
    for (s32 p = 0; p < MAX_PLAYERS_COUNT; p++)
    {
        WarPlayerInfo* pl = &gMap->players[p];
        textAdd(t, "P%d gold=%d wood=%d up=", p, pl->gold, pl->wood);
        for (s32 u = 0; u < MAX_UPGRADES_COUNT; u++)
            textAdd(t, "%d,", pl->upgrades[u].level);
        textAdd(t, "\n");
    }
    textAdd(t, "Z act=");
    for (s32 k = 0; k < WAR_STATE_COUNT; k++)
        textAdd(t, "%d,", m->stateStorage.activeCounts[k]);
    textAdd(t, " free=");
    for (s32 k = 0; k < WAR_STATE_COUNT; k++)
        textAdd(t, "%d,", m->stateStorage.freeCounts[k]);
    textAdd(t, "\n");

    WarEntityList* units = we_getEntitiesOfType(gContext, WAR_ENTITY_TYPE_UNIT);
    textAdd(t, "L");
    for (s32 i = 0; i < units->count; i++)
        textAdd(t, " %d", units->items[i]->id);
    textAdd(t, "\n");

    u32 gridHash = 2166136261u;
    for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
    {
        gridHash ^= gMap->finder.data[i];
        gridHash *= 16777619u;
    }
    textAdd(t, "G %08x\n", gridHash);

    for (s32 i = 1; i < MAX_ENTITIES_COUNT; i++)
    {
        WarEntity* e = &m->entities[i];
        if (e->id == 0)
            continue;
        textAdd(t, "E slot=%d id=%d type=%d", i, e->id, e->type);
        WarTransformComponent* tr = we_getTransformComponent(gContext, e);
        if (tr)
            textAdd(t, " pos=%08x,%08x", fbits(tr->position.x), fbits(tr->position.y));
        WarUnitComponent* u = we_getUnitComponent(gContext, e);
        if (u)
        {
            textAdd(t, " u=%d dir=%d tile=%d,%d size=%d,%d pl=%d rk=%d am=%d bd=%d bp=%08x hp=%d/%d mn=%d/%d ar=%d rg=%d dm=%d+%d dc=%d inv=%d%d seen=%d sp=%d act=%d mt=%08x it=%08x vt=%08x",
                    u->type, u->direction, u->tilex, u->tiley, u->sizex, u->sizey, u->player, u->resourceKind, u->amount,
                    u->building ? 1 : 0, fbits(u->buildPercent), u->hp, u->maxhp, u->mana, u->maxMana, u->armor, u->range,
                    u->minDamage, u->rndDamage, u->decay, u->invisible ? 1 : 0, u->invulnerable ? 1 : 0, u->hasBeenSeen ? 1 : 0,
                    u->speed, u->actionType, fbits(u->manaTime), fbits(u->invisibilityTime), fbits(u->invulnerabilityTime));
            for (s32 a = 0; a < WAR_ACTION_TYPE_COUNT; a++)
                textAdd(t, " a%d=%d,%08x,%d", a, u->actions[a].status, fbits(u->actions[a].scale), u->actions[a].stepIndex);
        }
        WarStateMachineComponent* sm = we_getStateMachineComponent(gContext, e);
        if (sm)
        {
            textAdd(t, " sm=%d seq=%u", sm->depth, (u32)sm->nextTransitionSequence);
            for (s32 d = 0; d < sm->depth; d++)
            {
                WarStateBase* s = wst_deref(gContext, sm->stack[d]);
                if (s)
                    dumpState(t, s, sm->stack[d]);
                else
                    textAdd(t, " S?");
            }
            WarTransitionRequest* p = &sm->pending;
            textAdd(t, " pend=%d,%d,%d,%u,%d ref=%d.%d.%u can=%d.%d.%u", p->operation, p->cause, p->result, (u32)p->sequence,
                    p->cancellation ? 1 : 0, p->stateRef.type, p->stateRef.idx, p->stateRef.generation,
                    p->cancellationTargetRef.type, p->cancellationTargetRef.idx, p->cancellationTargetRef.generation);
            if (p->operation != WAR_STATE_OP_NONE)
            {
                WarStateBase* s = wst_deref(gContext, p->stateRef);
                if (s)
                    dumpState(t, s, p->stateRef);
            }
        }
        textAdd(t, "\n");
    }
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* gli scenari                                                                                                        */
/* ------------------------------------------------------------------------------------------------------------------ */

static const WarUnitType kDudePool[12] = {
    WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_PEASANT, WAR_UNIT_PEON, WAR_UNIT_ARCHER, WAR_UNIT_KNIGHT,
    WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_CONJURER, WAR_UNIT_CLERIC, WAR_UNIT_SPIDER, WAR_UNIT_SKELETON, WAR_UNIT_OGRE
};
static const WarUnitType kBuildingPool[5] = {
    WAR_UNIT_FARM_HUMANS, WAR_UNIT_TOWNHALL_ORCS, WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_TEMPLE, WAR_UNIT_GOLDMINE
};

#define MAX_SPAWNED 256
static WarEntityId gSpawned[MAX_SPAWNED];
static s32 gSpawnedCount;

static WarEntity* spawnDude(WarUnitType type, u8 player, s32 x, s32 y)
{
    WarEntity* e = we_createDude(gContext, CREATE_UNIT_ARGS_INIT(.type = type, .x = x, .y = y, .player = player));
    if (e)
    {
        we_setInitialIdleState(gContext, e);
        if (gSpawnedCount < MAX_SPAWNED)
            gSpawned[gSpawnedCount++] = e->id;
    }
    return e;
}

static WarEntity* spawnBuilding(WarUnitType type, u8 player, s32 x, s32 y)
{
    WarEntity* e = we_createBuilding(gContext, CREATE_UNIT_ARGS_INIT(.type = type, .x = x, .y = y, .player = player));
    if (e && gSpawnedCount < MAX_SPAWNED)
        gSpawned[gSpawnedCount++] = e->id;
    return e;
}

static void spawnRandom(u32 hostile)
{
    u32 kind = scriptBelow(100);
    s32 x = 6 + (s32)scriptBelow(40);
    s32 y = 6 + (s32)scriptBelow(40);
    if (kind < 80)
    {
        u32 type = scriptBelow(12);
        u8 player = 0;
        if (hostile)
        {
            /* due schieramenti lontani (piu' di 5 caselle, il raggio con cui un guerriero nota un nemico) */
            player = (u8)scriptBelow(2);
            x = (player == 0 ? 10 : 25) + (x % 8);
        }
        spawnDude(kDudePool[type], player, x, y);
    }
    else
    {
        u32 type = scriptBelow(5);
        u8 player = kBuildingPool[type] == WAR_UNIT_GOLDMINE ? 4 : 0;
        spawnBuilding(kBuildingPool[type], player, x, y);
    }
}

static WarEntity* pickSpawned(void)
{
    u32 index = scriptBelow(gSpawnedCount > 0 ? (u32)gSpawnedCount : 1u);
    if (gSpawnedCount == 0)
        return NULL;
    return we_findEntity(gContext, gSpawned[index]);
}

static void opMove(u32 hostile)
{
    WarEntity* e = pickSpawned();
    s32 tx = (s32)scriptBelow(60);
    s32 ty = (s32)scriptBelow(60);
    u32 mid = scriptBelow(2);
    s32 mx = (s32)scriptBelow(60);
    s32 my = (s32)scriptBelow(60);
    u32 check = scriptBelow(2);
    if (!e || !wu_isDudeUnit(gContext, e) || wst_isDead(gContext, e) || wst_isGoingToDie(gContext, e))
        return;
    if (hostile)
    {
        /* verso lo schieramento avversario */
        WarUnitComponent* own = we_getUnitComponent(gContext, e);
        tx = (own->player == 0 ? 25 : 10) + tx % 8;
        mx = (own->player == 0 ? 25 : 10) + mx % 8;
    }
    vec2 positions[3];
    s32 n = 0;
    positions[n++] = wu_getUnitCenterPosition(gContext, e);
    if (mid)
        positions[n++] = vec2f((f32)(mx * MEGA_TILE_WIDTH + MINI_TILE_WIDTH), (f32)(my * MEGA_TILE_HEIGHT + MINI_TILE_HEIGHT));
    positions[n++] = vec2f((f32)(tx * MEGA_TILE_WIDTH + MINI_TILE_WIDTH), (f32)(ty * MEGA_TILE_HEIGHT + MINI_TILE_HEIGHT));
    WarStateMove* state = wst_createMoveState(gContext, e, n, positions, check != 0);
    wst_resetState(gContext, e, (WarStateBase*)state, WAR_TRANSITION_CAUSE_PLAYER_ORDER);
}

static void opDamage(void)
{
    WarEntity* e = pickSpawned();
    s32 minDamage = (s32)scriptBelow(5);
    s32 rndDamage = (s32)scriptBelow(80);
    if (!e || !wu_isUnit(e) || wu_isBuildingUnit(gContext, e))
        return;
    we_takeDamage(gContext, e, minDamage, rndDamage);
}

static void opWait(void)
{
    WarEntity* e = pickSpawned();
    f32 time = 1.0f + (f32)scriptBelow(5) * 0.5f;
    if (!e || !wu_isDudeUnit(gContext, e) || wst_isDead(gContext, e) || wst_isGoingToDie(gContext, e))
        return;
    WarStateWait* state = wst_createWaitState(gContext, e, time);
    wst_pushState(gContext, e, (WarStateBase*)state, WAR_TRANSITION_CAUSE_AI_ORDER);
}

static void opPop(void)
{
    WarEntity* e = pickSpawned();
    if (!e || !wu_isDudeUnit(gContext, e))
        return;
    wst_popState(gContext, e, WAR_TRANSITION_CAUSE_PLAYER_ORDER, WAR_STATE_RESULT_SUCCESS);
}

static void opHeal(void)
{
    WarEntity* e = pickSpawned();
    s32 hp = (s32)scriptBelow(30);
    u32 mana = scriptBelow(2);
    s32 amount = (s32)scriptBelow(60);
    if (!e || !wu_isUnit(e))
        return;
    we_increaseUnitHp(gContext, e, hp);
    if (mana)
        we_increaseUnitMana(gContext, e, amount);
    else
        resultMix(we_decreaseUnitMana(gContext, e, amount) ? 1 : 0);
}

static void opEconomy(void)
{
    u32 p = scriptBelow(5);
    s32 gold = (s32)scriptBelow(300);
    s32 wood = (s32)scriptBelow(300);
    u32 kind = scriptBelow(3);
    WarPlayerInfo* player = &gMap->players[p];
    if (kind == 0)
        we_increasePlayerResources(gContext, player, gold, wood);
    else if (kind == 1)
        resultMix(we_decreasePlayerResources(gContext, player, gold * 8, wood * 8) ? 1 : 0);
    else
        resultMix(we_enoughPlayerResources(gContext, player, gold * 4, wood * 4) ? 1 : 0);
}

static void opRemove(void)
{
    WarEntity* e = pickSpawned();
    if (!e)
        return;
    we_removeEntityById(gContext, e->id);
}

static void opUpgrade(void)
{
    u32 p = scriptBelow(2);
    u32 upgrade = scriptBelow(19);
    WarPlayerInfo* player = &gMap->players[p];
    if (hasRemainingUpgrade(player, (WarUpgradeType)upgrade))
        we_increaseUpgradeLevel(gContext, player, (WarUpgradeType)upgrade);
}

static void opFood(void)
{
    u32 p = scriptBelow(4);
    resultMix(we_enoughFarmFood(gContext, &gMap->players[p]) ? 1 : 0);
}

static void scriptStep(u32 hostile)
{
    u32 r = scriptBelow(100);
    if (hostile ? r < 20 : r < 8) opMove(hostile);
    else if (r < 12) opDamage();
    else if (r < 14) opWait();
    else if (r < 16) opPop();
    else if (r < 18) opHeal();
    else if (r < 20) opEconomy();
    else if (r < 21) opRemove();
    else if (r < 24) spawnRandom(hostile);
    else if (r < 25) opUpgrade();
    else if (r < 27) opFood();
}

static void tickWorld(u32 hostile)
{
    const f32 delta = 1.0f / 60.0f;
    if (gTrace)
        fprintf(stderr, "T\n");
    gContext->gameDeltaTime = delta;
    gContext->gameTime += (f64)delta;

    scriptStep(hostile);

    wst_processPendingTransitions(gContext);
    wst_updateIdleStates(gContext);
    wst_updateMoveStates(gContext);
    wst_updatePatrolStates(gContext);
    wst_updateFollowStates(gContext);
    wst_updateAttackStates(gContext);
    wst_updateGoldStates(gContext);
    wst_updateMiningStates(gContext);
    wst_updateWoodStates(gContext);
    wst_updateChoppingStates(gContext);
    wst_updateDeliverStates(gContext);
    wst_updateDeathStates(gContext);
    wst_updateCollapseStates(gContext);
    wst_updateTrainStates(gContext);
    wst_updateUpgradeStates(gContext);
    wst_updateBuildStates(gContext);
    wst_updateRepairStates(gContext);
    wst_updateRepairingStates(gContext);
    wst_updateCastStates(gContext);
    wst_updateWaitStates(gContext);
}

static void initialUnits(u32 hostile)
{
    gSpawnedCount = 0;
    s32 count = 6 + (s32)scriptBelow(7);
    for (s32 i = 0; i < count; i++)
        spawnRandom(hostile);
}

static bool anyAttack(void)
{
    WarEntityManager* m = &gMap->entityManager;
    for (s32 i = 1; i < MAX_ENTITIES_COUNT; i++)
    {
        WarEntity* e = &m->entities[i];
        if (e->id == 0)
            continue;
        if (wst_containsState(gContext, e, WAR_STATE_ATTACK) || wst_isGoingToAttack(gContext, e))
            return true;
    }
    return false;
}

#define FRIENDLY_TICS 300
#define HOSTILE_TICS 900

static void runScenario(u32 hostile, u32 seed, s32 dumpTic, bool perTic)
{
    worldInit(seed ^ 0xA5A5A5A5u, seed * 2654435761u + 12345u);
    initialUnits(hostile);

    s32 limit = hostile ? HOSTILE_TICS : FRIENDLY_TICS;
    s32 lastTic = -1;
    for (s32 tic = 0; tic < limit; tic++)
    {
        tickWorld(hostile);
        lastTic = tic;
        bool stop = hostile && anyAttack();
        Text text = {0};
        if (perTic || tic == dumpTic || stop)
            dumpWorld(&text, tic);
        if (dumpTic >= 0 && tic == dumpTic)
            printf("%s", text.data);
        else if (perTic)
            printf("%c %u %d %08x %d\n", hostile ? 'H' : 'F', seed, tic, fnv1a(text.data, text.length),
                   gMap->entityManager.entityCount);
        if (stop && dumpTic < 0)
            printf("S %u %d\n", seed, tic);
        free(text.data);
        if (stop)
            break;
    }
    (void)lastTic;
    worldFree();
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* gli scenari di raccolta (#194, seconda fetta): contadini e peoni che raccolgono oro e legna e consegnano               */
/* ------------------------------------------------------------------------------------------------------------------ */

static u32 gTileWrites;
static u32 gTileHash;

/* la tessera scritta nella mappa visiva (un albero abbattuto): si registra in ordine; l'impronta e' FNV-1a di (x, y, tessera) */
void wmap_setMapTileIndex(WarContext* context, s32 x, s32 y, s32 tile)
{
    (void)context;
    gTileWrites++;
    gTileHash = (gTileHash ^ (u32)x) * 16777619u;
    gTileHash = (gTileHash ^ (u32)y) * 16777619u;
    gTileHash = (gTileHash ^ (u32)tile) * 16777619u;
}

/* l'ingresso nel crollo (la miniera esaurita): nulla, vedi sopra */
void wst_enterCollapseState(WarContext* context, WarEntity* entity, WarState* state)
{
    (void)context; (void)entity; (void)state;
}

#define GATHER_TICS 1800
#define GATHER_WORKERS 6
static WarEntityId gTownHalls[2];
static WarEntityId gMines[2];
static WarEntityId gForests[2];
static s32 gForestX[2];
static s32 gForestY[2];
static WarEntityId gWorkers[GATHER_WORKERS];

static WarEntity* gatherForest(s32 fx, s32 fy, s32 w, s32 h)
{
    WarEntity* forest = we_createForest(gContext);
    WarForestComponent* fc = we_getForestComponent(gContext, forest);
    for (s32 y = 0; y < h; y++)
    {
        for (s32 x = 0; x < w; x++)
        {
            u32 present = scriptBelow(100);
            s32 amount = 2 + (s32)scriptBelow(15);
            if (present >= 85)
                continue;
            WarTree tree = createTree(fx + x, fy + y, amount);
            WarTreeListAdd(&fc->trees, tree);
            wpath_setStaticEntity(&gMap->finder, fx + x, fy + y, 1, 1, forest->id);
        }
    }
    we_determineTreeTiles(gContext, forest);
    return forest;
}

static void gatherOrderGold(WarEntity* e, u32 mine)
{
    if (!e || !wu_isDudeUnit(gContext, e) || wst_isDead(gContext, e) || wst_isGoingToDie(gContext, e))
        return;
    WarStateGold* state = wst_createGatherGoldState(gContext, e, gMines[mine]);
    wst_resetState(gContext, e, (WarStateBase*)state, WAR_TRANSITION_CAUSE_PLAYER_ORDER);
}

static void gatherOrderWood(WarEntity* e, u32 f, u32 pick)
{
    if (!e || !wu_isDudeUnit(gContext, e) || wst_isDead(gContext, e) || wst_isGoingToDie(gContext, e))
        return;
    s32 tx = gForestX[f];
    s32 ty = gForestY[f];
    WarEntity* forest = we_findEntity(gContext, gForests[f]);
    if (forest)
    {
        WarForestComponent* fc = we_getForestComponent(gContext, forest);
        if (fc->trees.count > 0)
        {
            WarTree* tree = &fc->trees.items[pick % (u32)fc->trees.count];
            tx = tree->tilex;
            ty = tree->tiley;
        }
    }
    vec2 position = wmap_tileToMapCoordinatesV(vec2i(tx, ty), true);
    WarStateWood* state = wst_createGatherWoodState(gContext, e, gForests[f], position);
    wst_resetState(gContext, e, (WarStateBase*)state, WAR_TRANSITION_CAUSE_PLAYER_ORDER);
}

static void gatherOrderDeliver(WarEntity* e, u32 townHall)
{
    if (!e || !wu_isDudeUnit(gContext, e) || wst_isDead(gContext, e) || wst_isGoingToDie(gContext, e))
        return;
    WarStateDeliver* state = wst_createDeliverState(gContext, e, gTownHalls[townHall]);
    wst_resetState(gContext, e, (WarStateBase*)state, WAR_TRANSITION_CAUSE_PLAYER_ORDER);
}

static WarEntity* gatherPickWorker(void)
{
    u32 index = scriptBelow(GATHER_WORKERS);
    return we_findEntity(gContext, gWorkers[index]);
}

static void gatherSetup(u32 seed)
{
    worldInit(seed ^ 0xB7B7B7B7u, seed * 2654435761u + 777u);
    gTileWrites = 0;
    gTileHash = 2166136261u;
    gSpawnedCount = 0;
    for (s32 f = 0; f < 2; f++)
    {
        s32 bx = f == 0 ? 6 : 38;
        s32 by = 8 + (s32)scriptBelow(6);
        WarEntity* th = we_createBuilding(gContext, CREATE_UNIT_ARGS_INIT(.type = f == 0 ? WAR_UNIT_TOWNHALL_HUMANS : WAR_UNIT_TOWNHALL_ORCS,
                                                                          .x = bx, .y = by, .player = (u8)f));
        gTownHalls[f] = th->id;

        s32 mx = bx + 5 + (s32)scriptBelow(3);
        s32 my = by + (s32)scriptBelow(3);
        s32 amount = 100 + (s32)scriptBelow(300);
        WarEntity* mine = we_createUnit(gContext, CREATE_UNIT_ARGS_INIT(.type = WAR_UNIT_GOLDMINE, .x = mx, .y = my, .player = 4,
                                                                        .resourceKind = WAR_RESOURCE_GOLD, .amount = (u32)amount));
        we_setInitialIdleState(gContext, mine);
        gMines[f] = mine->id;

        s32 fx = bx + (s32)scriptBelow(4);
        s32 fy = by + 8 + (s32)scriptBelow(3);
        s32 fw = 4 + (s32)scriptBelow(3);
        s32 fh = 3 + (s32)scriptBelow(3);
        WarEntity* forest = gatherForest(fx, fy, fw, fh);
        gForests[f] = forest->id;
        gForestX[f] = fx;
        gForestY[f] = fy;

        for (s32 i = 0; i < GATHER_WORKERS / 2; i++)
        {
            u32 carryKind = scriptBelow(4);
            s32 carry = 60 + (s32)scriptBelow(41);
            WarEntity* w = spawnDude(f == 0 ? WAR_UNIT_PEASANT : WAR_UNIT_PEON, (u8)f, bx + i * 2, by + 5 + (s32)(i % 2));
            gWorkers[f * (GATHER_WORKERS / 2) + i] = w->id;
            WarUnitComponent* unit = we_getUnitComponent(gContext, w);
            if (carryKind == 0)
            {
                unit->resourceKind = WAR_RESOURCE_WOOD;
                unit->amount = carry;
            }
            else if (carryKind == 1)
            {
                unit->resourceKind = WAR_RESOURCE_GOLD;
                unit->amount = carry;
            }
        }
    }
    /* i primi ordini: ogni lavoratore ne riceve uno */
    for (s32 i = 0; i < GATHER_WORKERS; i++)
    {
        u32 what = scriptBelow(3);
        u32 gate = scriptBelow(4);
        u32 pick = scriptBelow(40);
        u32 own = (u32)(i / (GATHER_WORKERS / 2));
        u32 where = gate == 0 ? 1 - own : own;
        WarEntity* e = we_findEntity(gContext, gWorkers[i]);
        if (what == 0) gatherOrderGold(e, where);
        else if (what == 1) gatherOrderWood(e, where, pick);
        else gatherOrderDeliver(e, where);
    }
}

static void gatherScriptStep(void)
{
    u32 r = scriptBelow(1000);
    if (r < 3)
    {
        WarEntity* e = gatherPickWorker();
        u32 gate = scriptBelow(4);
        u32 own = e ? (u32)we_getUnitComponent(gContext, e)->player : 0;
        gatherOrderGold(e, gate == 0 ? 1 - own : own);
    }
    else if (r < 6)
    {
        WarEntity* e = gatherPickWorker();
        u32 gate = scriptBelow(4);
        u32 pick = scriptBelow(40);
        u32 own = e ? (u32)we_getUnitComponent(gContext, e)->player : 0;
        gatherOrderWood(e, gate == 0 ? 1 - own : own, pick);
    }
    else if (r < 8)
    {
        WarEntity* e = gatherPickWorker();
        u32 gate = scriptBelow(4);
        u32 own = e ? (u32)we_getUnitComponent(gContext, e)->player : 0;
        gatherOrderDeliver(e, gate == 0 ? 1 - own : own);
    }
    else if (r < 10)
    {
        WarEntity* e = gatherPickWorker();
        u32 gate = scriptBelow(2);
        s32 minDamage = (s32)scriptBelow(3);
        s32 rndDamage = (s32)scriptBelow(40);
        if (e && gate == 0 && wu_isUnit(e))
            we_takeDamage(gContext, e, minDamage, rndDamage);
    }
    else if (r < 12)
    {
        WarEntity* e = gatherPickWorker();
        if (e && wu_isDudeUnit(gContext, e))
            wst_popState(gContext, e, WAR_TRANSITION_CAUSE_PLAYER_ORDER, WAR_STATE_RESULT_SUCCESS);
    }
    else if (r < 14)
    {
        opMove(0);
    }
    else if (r < 20)
    {
        opEconomy();
    }
    else if (r < 26)
    {
        opHeal();
    }
    else if (r < 28)
    {
        u32 gate = scriptBelow(4);
        u32 which = scriptBelow(4);
        WarEntityId id = which < 2 ? gMines[which] : gTownHalls[which - 2];
        if (gate == 0)
            we_removeEntityById(gContext, id);
    }
}

/* il seguimento (war_state_machine_follow.c) non e' portato: lo stato si mette e basta; lo scenario fa arrivare l'unita' sul
   bersaglio come farebbe il seguimento e toglie lo stato con lo stesso passo del remake (wst_popState, COMPLETION) */
static void gatherResolveFollows(void)
{
    WarEntityManager* m = &gMap->entityManager;
    for (s32 i = 1; i < MAX_ENTITIES_COUNT; i++)
    {
        WarEntity* e = &m->entities[i];
        if (e->id == 0 || !wu_isUnit(e))
            continue;
        WarStateBase* active = wst_getActiveState(gContext, e);
        if (!active || active->type != WAR_STATE_FOLLOW)
            continue;
        WarStateFollow* f = (WarStateFollow*)active;
        WarEntity* target = we_findEntity(gContext, f->targetEntityId);
        if (!target)
        {
            wst_popState(gContext, e, WAR_TRANSITION_CAUSE_COMPLETION, WAR_STATE_RESULT_TARGET_INVALID);
            continue;
        }
        vec2 end = wu_unitPointOnTarget(gContext, e, target);
        wu_setUnitCenterPosition(gContext, e, end);
        wst_popState(gContext, e, WAR_TRANSITION_CAUSE_COMPLETION, WAR_STATE_RESULT_SUCCESS);
    }
}

static void gatherUpdateHarvestActions(void)
{
    WarEntityList* units = we_getEntitiesOfType(gContext, WAR_ENTITY_TYPE_UNIT);
    for (s32 i = 0; i < units->count; i++)
    {
        WarEntity* e = units->items[i];
        if (!e)
            continue;
        WarUnitComponent* unit = we_getUnitComponent(gContext, e);
        if (unit && unit->actionType == WAR_ACTION_TYPE_HARVEST)
            wact_updateAction(gContext, e);
    }
}

static void gatherTick(void)
{
    const f32 delta = 1.0f / 60.0f;
    if (gTrace)
        fprintf(stderr, "T\n");
    gContext->gameDeltaTime = delta;
    gContext->gameTime += (f64)delta;

    gatherScriptStep();

    wst_processPendingTransitions(gContext);
    gatherResolveFollows();
    wst_updateIdleStates(gContext);
    wst_updateMoveStates(gContext);
    wst_updateGoldStates(gContext);
    wst_updateMiningStates(gContext);
    wst_updateWoodStates(gContext);
    wst_updateChoppingStates(gContext);
    wst_updateDeliverStates(gContext);
    wst_updateDeathStates(gContext);
    wst_updateWaitStates(gContext);
    gatherUpdateHarvestActions();
}

static void dumpGather(Text* t, s32 tic)
{
    dumpWorld(t, tic);
    textAdd(t, "M n=%u h=%08x\n", gTileWrites, gTileHash);
    WarEntityList* forests = we_getEntitiesOfType(gContext, WAR_ENTITY_TYPE_FOREST);
    for (s32 i = 0; i < forests->count; i++)
    {
        WarEntity* forest = forests->items[i];
        if (!forest)
            continue;
        WarForestComponent* fc = we_getForestComponent(gContext, forest);
        textAdd(t, "F id=%d n=%d", forest->id, fc->trees.count);
        for (s32 k = 0; k < fc->trees.count; k++)
        {
            WarTree* tree = &fc->trees.items[k];
            textAdd(t, " %d,%d,%d,%d", tree->tilex, tree->tiley, tree->amount, (s32)tree->type);
        }
        textAdd(t, "\n");
    }
    WarEntityManager* m = &gMap->entityManager;
    for (s32 i = 1; i < MAX_ENTITIES_COUNT; i++)
    {
        WarEntity* e = &m->entities[i];
        if (e->id == 0 || !wu_isUnit(e))
            continue;
        WarSpriteComponent* sprite = we_getSpriteComponent(gContext, e);
        WarTransformComponent* tr = we_getTransformComponent(gContext, e);
        textAdd(t, "K %d spr=%d en=%d fr=%d mx=%d\n", e->id, sprite ? sprite->resourceIndex : -1,
                sprite && we_isComponentEnabled(gContext, e, COMP_SPRITE) ? 1 : 0, sprite ? sprite->frameIndex : -1,
                tr && tr->scale.x < 0 ? 1 : 0);
    }
}

static void runGather(u32 seed, s32 dumpTic, bool perTic)
{
    gatherSetup(seed);
    for (s32 tic = 0; tic < GATHER_TICS; tic++)
    {
        gatherTick();
        Text text = {0};
        if (perTic || tic == dumpTic)
            dumpGather(&text, tic);
        if (dumpTic >= 0 && tic == dumpTic)
            printf("%s", text.data);
        else if (perTic)
            printf("G %u %d %08x %d\n", seed, tic, fnv1a(text.data, text.length), gMap->entityManager.entityCount);
        free(text.data);
    }
    if (perTic)
    {
        /* il riassunto: quanto lo scenario ha fatto (e il conto che il golden verifica) */
        s32 trees[2] = {0, 0};
        for (s32 f = 0; f < 2; f++)
        {
            WarEntity* forest = we_findEntity(gContext, gForests[f]);
            if (forest)
                trees[f] = we_getForestComponent(gContext, forest)->trees.count;
        }
        s32 mineAmount[2] = {-1, -1};
        for (s32 f = 0; f < 2; f++)
        {
            WarEntity* mine = we_findEntity(gContext, gMines[f]);
            if (mine)
                mineAmount[f] = we_getUnitComponent(gContext, mine)->amount;
        }
        printf("Q %u gold=%d,%d wood=%d,%d mines=%d,%d trees=%d,%d tiles=%u\n", seed, gMap->players[0].gold, gMap->players[1].gold,
               gMap->players[0].wood, gMap->players[1].wood, mineAmount[0], mineAmount[1], trees[0], trees[1], gTileWrites);
    }
    worldFree();
}

/* le tabelle della raccolta: i passi dell'azione di raccolta e le immagini dei trasportatori */
static void printGatherTables(void)
{
    wm_allocInit(64ull * 1024 * 1024, 4ull * 1024 * 1024, 1ull * 1024 * 1024);
    wact_initUnitActionDefs();
    printf("# harvest: type directional loop count (stepType:param)*\n");
    for (s32 t = 0; t < WAR_UNIT_COUNT; t++)
    {
        const WarUnitActionDef* def = &gUnitActionDefs[t][WAR_ACTION_TYPE_HARVEST];
        if (def->type == WAR_ACTION_TYPE_NONE)
            continue;
        printf("H %d %d %d %d", t, def->directional ? 1 : 0, def->loop ? 1 : 0, def->steps.count);
        for (s32 i = 0; i < def->steps.count; i++)
            printf(" %d:%d", (s32)def->steps.items[i].type, def->steps.items[i].param);
        printf("\n");
    }
    printf("# workers: type carryingWoodResource carryingGoldResource\n");
    for (s32 i = 0; i < (s32)arrayLength(workersData); i++)
        printf("W %d %d %d\n", workersData[i].type, workersData[i].carryingWoodResource, workersData[i].carryingGoldResource);
    wm_allocFree();
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* le tabelle                                                                                                         */
/* ------------------------------------------------------------------------------------------------------------------ */

static void printTables(void)
{
    wm_allocInit(64ull * 1024 * 1024, 4ull * 1024 * 1024, 1ull * 1024 * 1024);
    wact_initUnitActionDefs();

    printf("# unitStats: type range sight armor hp mana minDamage rndDamage buildTime goldCost woodCost decay speeds(bits)\n");
    for (s32 i = 0; i < (s32)arrayLength(unitStats); i++)
    {
        const WarUnitStats* s = &unitStats[i];
        printf("U %d %d %d %d %d %d %d %d %d %d %d %d %08x %08x %08x\n", s->type, s->range, s->sight, s->armor, s->hp, s->mana,
               s->minDamage, s->rndDamage, s->buildTime, s->goldCost, s->woodCost, s->decay, fbits(s->speeds[0]),
               fbits(s->speeds[1]), fbits(s->speeds[2]));
    }
    printf("# buildingStats: type armor sight hp buildTime goldCost woodCost\n");
    for (s32 i = 0; i < (s32)arrayLength(buildingStats); i++)
    {
        const WarBuildingStats* s = &buildingStats[i];
        printf("B %d %d %d %d %d %d %d\n", s->type, s->armor, s->sight, s->hp, s->buildTime, s->goldCost, s->woodCost);
    }
    printf("# upgradeStats: type buildTime gold1 gold2 maxLevel\n");
    for (s32 i = 0; i < (s32)arrayLength(upgradeStats); i++)
    {
        const WarUpgradeStats* s = &upgradeStats[i];
        const WarUpgradeData* d = wu_getUpgradeData(s->type);
        printf("G %d %d %d %d %d\n", s->type, s->buildTime, s->goldCost[0], s->goldCost[1], d->maxLevelAllowed);
    }
    printf("# spellStats: type manaCost time(bits) range mappedUnit\n");
    for (s32 i = 0; i < (s32)arrayLength(spellStats); i++)
    {
        const WarSpellStats* s = &spellStats[i];
        const WarSpellMapping* m = NULL;
        for (s32 k = 0; k < (s32)arrayLength(spellMappings); k++)
            if (spellMappings[k].type == s->type)
                m = &spellMappings[k];
        printf("P %d %d %08x %d %d\n", s->type, s->manaCost, fbits(s->time), s->range, m ? m->mappedType : -1);
    }
    printf("# classification: type dude building worker warrior range melee fist sword magic corpse catapult conjOrWarlock clericOrNecro summon race forHumans forOrcs\n");
    for (s32 t = 0; t < WAR_UNIT_COUNT; t++)
    {
        printf("C %d %d%d%d%d%d%d%d%d%d%d%d%d%d%d %d %d %d\n", t, wu_isDudeUnitType(t), wu_isBuildingUnitType(t),
               wu_isWorkerUnitType(t), wu_isWarriorUnitType(t), wu_isRangeUnitType(t), wu_isMeleeUnitType(t),
               wu_isFistUnitType(t), wu_isSwordUnitType(t), wu_isMagicUnitType(t), wu_isCorpseUnitType(t),
               wu_isCatapultUnitType(t), wu_isConjurerOrWarlockUnitType(t), wu_isClericOrNecrolyteUnitType(t),
               wu_isSummonUnitType(t), wu_getUnitTypeRace(t), wu_getUnitTypeForRace(t, WAR_RACE_HUMANS),
               wu_getUnitTypeForRace(t, WAR_RACE_ORCS));
    }
    printf("# actions: type (action present duration)*7 in the order idle walk attack death harvest repair build\n");
    for (s32 t = 0; t < WAR_UNIT_COUNT; t++)
    {
        printf("A %d", t);
        for (s32 a = 0; a < WAR_ACTION_TYPE_COUNT; a++)
        {
            bool present = gUnitActionDefs[t][a].type != WAR_ACTION_TYPE_NONE;
            s32 duration = 0;
            if (present)
            {
                for (s32 i = 0; i < gUnitActionDefs[t][a].steps.count; i++)
                    if (gUnitActionDefs[t][a].steps.items[i].type == WAR_ACTION_STEP_WAIT)
                        duration += gUnitActionDefs[t][a].steps.items[i].param;
            }
            printf(" %d,%d", present ? 1 : 0, duration);
        }
        printf("\n");
    }
    printf("# scaled time: gameSpeed globalSpeed t -> bits (wmap_getMapScaledTime)\n");
    WarContext* context = (WarContext*)wm_alloc(sizeof(WarContext));
    WarMap* map = (WarMap*)wm_alloc(sizeof(WarMap));
    memset(context, 0, sizeof(WarContext));
    memset(map, 0, sizeof(WarMap));
    context->map = map;
    for (s32 speed = 0; speed < 5; speed++)
    {
        for (s32 g = 0; g < 3; g++)
        {
            f32 globalSpeed = g == 0 ? 1.0f : (g == 1 ? 1.5f : 0.75f);
            for (s32 k = 0; k < 4; k++)
            {
                f32 t = (f32)((k + 1) * 7) / 60.0f;
                map->settings.gameSpeed = (WarMapSpeed)speed;
                context->globalSpeed = globalSpeed;
                printf("T %d %08x %08x %08x\n", speed, fbits(globalSpeed), fbits(t), fbits(wmap_getMapScaledTime(context, t)));
            }
        }
    }
    wm_allocFree();
}

/* misura: unita' che marciano (il percorso caldo): tic al secondo e microsecondi per unita' e per tic */
static void bench(s32 units, s32 tics)
{
    worldInit(12345, 678);
    gSpawnedCount = 0;
    for (s32 i = 0; i < units; i++)
    {
        WarEntity* e = spawnDude(WAR_UNIT_FOOTMAN, 0, 2 + (i % 56), 2 + (i / 56) * 4);
        if (!e)
            break;
        vec2 positions[2];
        positions[0] = wu_getUnitCenterPosition(gContext, e);
        positions[1] = vec2f(60 * 16 + 8, positions[0].y);
        WarStateMove* state = wst_createMoveState(gContext, e, 2, positions, false);
        wst_resetState(gContext, e, (WarStateBase*)state, WAR_TRANSITION_CAUSE_PLAYER_ORDER);
    }
    clock_t start = clock();
    const f32 delta = 1.0f / 60.0f;
    for (s32 t = 0; t < tics; t++)
    {
        gContext->gameDeltaTime = delta;
        gContext->gameTime += (f64)delta;
        wst_processPendingTransitions(gContext);
        wst_updateIdleStates(gContext);
        wst_updateMoveStates(gContext);
    }
    double ms = 1000.0 * (double)(clock() - start) / CLOCKS_PER_SEC;
    printf("C %d unita', %d tic: %.1f ms, %.3f us per unita' e tic\n", gMap->entityManager.entityCount, tics, ms,
           1000.0 * ms / ((double)gMap->entityManager.entityCount * tics));
    worldFree();
}
int main(int argc, char** argv)
{
    gTrace = getenv("WAR_REF_TRACE") != NULL;
    if (argc < 2)
    {
        fprintf(stderr, "uso: war_model_ref tables | scenarios [n] | hostile [n] | dump friendly|hostile SEED TIC\n");
        return 1;
    }
    if (strcmp(argv[1], "tables") == 0)
    {
        printTables();
        return 0;
    }
    if (strcmp(argv[1], "bench") == 0)
    {
        bench(argc > 2 ? atoi(argv[2]) : 400, argc > 3 ? atoi(argv[3]) : 1500);
        return 0;
    }
    if (strcmp(argv[1], "scenarios") == 0)
    {
        u32 n = argc > 2 ? (u32)atoi(argv[2]) : 20;
        for (u32 seed = 1; seed <= n; seed++)
            runScenario(0, seed, -1, true);
        return 0;
    }
    if (strcmp(argv[1], "hostile") == 0)
    {
        u32 n = argc > 2 ? (u32)atoi(argv[2]) : 10;
        for (u32 seed = 1; seed <= n; seed++)
            runScenario(1, seed, -1, true);
        return 0;
    }
    if (strcmp(argv[1], "gather-tables") == 0)
    {
        printGatherTables();
        return 0;
    }
    if (strcmp(argv[1], "gather") == 0)
    {
        u32 n = argc > 2 ? (u32)atoi(argv[2]) : 10;
        for (u32 seed = 1; seed <= n; seed++)
            runGather(seed, -1, true);
        return 0;
    }
    if (strcmp(argv[1], "dump") == 0 && argc >= 5 && strcmp(argv[2], "gather") == 0)
    {
        runGather((u32)atoi(argv[3]), atoi(argv[4]), false);
        return 0;
    }
    if (strcmp(argv[1], "dump") == 0 && argc >= 5)
    {
        runScenario(strcmp(argv[2], "hostile") == 0 ? 1 : 0, (u32)atoi(argv[3]), atoi(argv[4]), false);
        return 0;
    }
    fprintf(stderr, "comando sconosciuto\n");
    return 1;
}
