/*
  Issue #193: harness di riferimento per i livelli, le campagne e i raccordi di Libs\War.
  Compila il codice ORIGINALE di acoto87/war1 (zlib License, (C) 2019 Alejandro Coto Gutierrez): le funzioni di
  war_resources.c che leggono i livelli (wres_loadLevelInfo, wres_loadLevelVisual, wres_loadLevelPassable e le
  funzioni di unita', strade, muri e miniere), war_campaigns.c intero, le tabelle di war_units.c, le funzioni dei
  pezzi di war_roads.c, war_walls.c, war_ruins.c, war_trees.c e war_map_grid.c, e il lettore di DATA.WAR di war_file.c
  sono estratti alla lettera da Compila-LevelRef.ps1 (file *.inc): qui ci sono solo gli stub di SDL, Tracy, wm_alloc,
  del log, delle liste di shl e delle poche funzioni del motore che le funzioni estratte chiamano. Questo file e' una
  versione modificata del remake solo per far girare quel codice.

  Uso:  war_lvl_ref DATA.WAR levels   le righe di ogni livello (L F U R O E D W G K V A), nell'ordine di assets[]
        war_lvl_ref - campaigns       la tabella delle campagne, wcamp_tryGetMapType
        war_lvl_ref - objectives      le condizioni di vittoria su scenari casuali (seme fisso)
        war_lvl_ref - tables          le tabelle dei raccordi
        war_lvl_ref - autotile        strade, muri, rovine e alberi su scenari casuali (seme fisso)
        war_lvl_ref - grid            la griglia spaziale su scenari casuali (seme fisso)
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
#define inRange(x, a, b) ((x) >= (a) && (x) < (b))
#define SIGN(x) ((x) < 0 ? -1 : 1)
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#include "war_defines.inc"

typedef struct { const char* data; size_t length; } StringView;
static const char* wsv_data(StringView v) { return v.data; }
static StringView wsv_fromCString(const char* s)
{
    StringView v;
    v.data = s;
    v.length = s ? strlen(s) : 0;   /* come wsv_fromCString del remake: NULL e' la vista vuota */
    return v;
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
typedef struct _WarMapGrid WarMapGrid;
typedef struct _WarMap WarMap;
typedef struct _WarPlayerInfo WarPlayerInfo;
typedef struct _WarEntity WarEntity;
typedef int WarMapTilesetType;

#include "enum_WarRace.inc"
#include "enum_WarUnitType.inc"
#include "enum_WarResourceKind.inc"
#include "enum_WarConstructType.inc"
#include "enum_WarCampaignMapType.inc"
#include "enum_WarLevelResult.inc"
#include "enum_WarAudioId.inc"
#include "enum_WarRoadPieceType.inc"
#include "enum_WarWallPieceType.inc"
#include "enum_WarRuinPieceType.inc"
#include "enum_WarTreeTileType.inc"
#include "enum_WarFogPieceType.inc"

void wfile_freeWarFile(WarFile* warFile);

#include "war_types.inc"
#include "war_enums.inc"
#include "war_resource_type.inc"
#include "war_sprite_frame.inc"
#include "war_types2.inc"
#include "war_core.inc"
#include "war_database_copy.h"

struct _WarPlayerInfo
{
    s32 index;
    WarRace race;
};
#define isHumanPlayer(player) ((player)->race == WAR_RACE_HUMANS)

typedef struct { f32 x, y; } vec2;
static vec2 vec2i(s32 x, s32 y) { vec2 v; v.x = (f32)x; v.y = (f32)y; return v; }

/* le entita' dei pezzi (war_entities.h, solo quanto serve) */
struct _WarEntity
{
    s32 type;
    bool enabled;
    bool dying;
    bool collapsing;
    vec2 tile;
    s32 forestId;
};
typedef struct { WarEntity entities[MAX_ENTITIES_COUNT]; } WarEntityManager;
typedef struct { s32 count; WarEntity* items[MAX_ENTITIES_COUNT]; } WarEntityList;

struct _WarMapGrid
{
    s32 head[(MAP_TILES_WIDTH / 4) * (MAP_TILES_HEIGHT / 4)];
    s32 next[MAX_ENTITIES_COUNT];
};

typedef struct { s32 dummy; } WarPathFinder;
typedef s32 WarEntityId;

struct _WarMap
{
    WarPathFinder finder;
    WarPlayerInfo players[5];
    WarMapGrid grid;
    WarEntityManager entityManager;
    WarEntityList units;
};

struct _WarContext
{
    WarFile* warFile;
    WarResource* resources;
    WarMap* map;
};

#include "war_read_macros.inc"
#include "war_res_a.inc"
#include "war_res_levels.inc"

/* ---- campagne: war_campaigns.c intero ---- */
typedef enum { WAR_ENTITY_TYPE_UNIT = 1, WAR_ENTITY_TYPE_ROAD, WAR_ENTITY_TYPE_WALL, WAR_ENTITY_TYPE_RUIN, WAR_ENTITY_TYPE_FOREST } WarEntityType;

typedef WarLevelResult (*WarCheckObjectivesFunc)(WarContext* context);
typedef WarCampaignMapType WarCampaignMapTypeAlias;
typedef struct _WarCampaignMapData WarCampaignMapData;
typedef WarAudioId WarAudioIdAlias;
#define WAR_CAMPAIGN_MAP_DATA_DEFINED

struct _WarCampaignMapData
{
    WarCampaignMapType type;
    WarCheckObjectivesFunc checkObjectivesFunc;
    StringView objectives;
    WarAudioId briefingAudioId;
    StringView briefingText;
    f32 briefingDuration;
};

/* conteggi dei giocatori: un finto guidato dallo scenario */
typedef struct
{
    s32 totalUnits[5];
    s32 totalDudes[5];
    s32 buildings[5][WAR_UNIT_COUNT];
} Census;
static Census census;

static s32 wu_getTotalNumberOfUnits(WarContext* context, u8 player) { NOT_USED(context); return census.totalUnits[player]; }
static s32 wu_getTotalNumberOfDudes(WarContext* context, u8 player) { NOT_USED(context); return census.totalDudes[player]; }
static s32 wu_getNumberOfBuildingsOfType(WarContext* context, u8 player, WarUnitType unitType, bool alreadyBuilt)
{
    NOT_USED(context); NOT_USED(alreadyBuilt);
    return census.buildings[player][unitType];
}

#include "war_campaigns_orig.c"

/* ---- tabelle ---- */
typedef struct { WarRoadPieceType type; s32 tileIndexForest; s32 tileIndexSwamp; } WarRoadData;
typedef struct { WarWallPieceType type; s32 tileForest; s32 tileDamagedForest; s32 tileDestroyedForest;
                 s32 tileSwamp; s32 tileDamagedSwamp; s32 tileDestroyedSwamp; } WarWallData;
typedef struct { WarRuinPieceType type; s32 tileIndexForest; s32 tileIndexSwamp; } WarRuinData;
typedef struct { WarTreeTileType type; s32 tileIndexForest; s32 tileIndexSwamp; } WarTreeData;
#include "war_tables.inc"

/* ---- pezzi ---- */
typedef struct _WarRoadPiece { WarRoadPieceType type; s32 tilex, tiley; u8 player; } WarRoadPiece;
typedef struct _WarWallPiece { WarWallPieceType type; s32 hp; s32 maxhp; s32 tilex, tiley; u8 player; } WarWallPiece;
typedef struct _WarRuinPiece { WarRuinPieceType type; s32 tilex, tiley; } WarRuinPiece;
typedef struct _WarTree { WarTreeTileType type; s32 tilex, tiley; s32 amount; } WarTree;

#define createRoadPiece(x, y, player) ((WarRoadPiece){0, (x), (y), (u8)(player)})
#define createWallPiece(x, y, player) ((WarWallPiece){0, 0, 0, (x), (y), (u8)(player)})
#define createRuinPiece(x, y) ((WarRuinPiece){0, (x), (y)})
#define createTree(x, y, amount) ((WarTree){0, (x), (y), (amount)})

#define PIECE_LIST(typeName, itemType, equalsName) \
    typedef struct { s32 count; itemType items[8192]; } typeName; \
    static void typeName ## Add(typeName* l, itemType v) { l->items[l->count++] = v; } \
    static void typeName ## RemoveAt(typeName* l, s32 i) \
    { \
        if (i < 0 || i >= l->count) return; \
        memmove(l->items + i, l->items + i + 1, (l->count - i - 1) * sizeof(itemType)); \
        l->count -= 1; \
    } \
    static void typeName ## Remove(typeName* l, itemType v, bool (*eq)(const itemType, const itemType)) \
    { \
        for (s32 i = 0; i < l->count; i++) if (eq(l->items[i], v)) { typeName ## RemoveAt(l, i); return; } \
    }
PIECE_LIST(WarRoadPieceList, WarRoadPiece, we_equalsRoadPiece)
PIECE_LIST(WarWallPieceList, WarWallPiece, we_equalsWallPiece)
PIECE_LIST(WarRuinPieceList, WarRuinPiece, we_equalsRuinPiece)
PIECE_LIST(WarTreeList, WarTree, we_equalsTree)

/* lo stesso corpo di war_entities.c */
static bool we_equalsRoadPiece(const WarRoadPiece r1, const WarRoadPiece r2)
{
    return r1.type == r2.type && r1.player == r2.player && r1.tilex == r2.tilex && r1.tiley == r2.tiley;
}
static bool we_equalsWallPiece(const WarWallPiece w1, const WarWallPiece w2)
{
    return w1.type == w2.type && w1.player == w2.player && w1.tilex == w2.tilex && w1.tiley == w2.tiley;
}
static bool we_equalsRuinPiece(const WarRuinPiece r1, const WarRuinPiece r2)
{
    return r1.type == r2.type && r1.tilex == r2.tilex && r1.tiley == r2.tiley;
}
static bool we_equalsTree(const WarTree t1, const WarTree t2) { return t1.tilex == t2.tilex && t1.tiley == t2.tiley; }

typedef struct { s32 count; s32 items[8192]; } S32List;
static void S32ListInit(S32List* l, void* alloc) { NOT_USED(alloc); l->count = 0; }
static void S32ListAdd(S32List* l, s32 v) { l->items[l->count++] = v; }
static void S32ListFree(S32List* l) { l->count = 0; }
static void* wm_frameAllocator(void) { return NULL; }

typedef struct { WarRoadPieceList pieces; } WarRoadComponent;
typedef struct { WarWallPieceList pieces; } WarWallComponent;
typedef struct { WarRuinPieceList pieces; } WarRuinComponent;
typedef struct { WarTreeList trees; } WarForestComponent;

static WarRoadComponent theRoad;
static WarWallComponent theWall;
static WarRuinComponent theRuin;
static WarForestComponent theForest;
static WarEntity roadEntity, wallEntity, ruinEntity, forestEntity;

static WarRoadComponent* we_getRoadComponent(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return &theRoad; }
static WarWallComponent* we_getWallComponent(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return &theWall; }
static WarRuinComponent* we_getRuinComponent(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return &theRuin; }
static WarForestComponent* we_getForestComponent(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return &theForest; }

static WarEntityList* we_getEntitiesOfType(WarContext* context, s32 type);
static bool wpath_isInside(s32 x, s32 y)
{
    return inRange(x, 0, MAP_TILES_WIDTH) && inRange(y, 0, MAP_TILES_HEIGHT);
}

/* una tegola ha l'entita' bosco (id 1) se c'e' un albero */
static WarEntityId wpath_getTileEntityId(WarPathFinder* f, s32 x, s32 y)
{
    NOT_USED(f);
    for (s32 i = 0; i < theForest.trees.count; i++)
        if (theForest.trees.items[i].tilex == x && theForest.trees.items[i].tiley == y)
            return 1;
    return 0;
}
static WarEntity* we_findEntity(WarContext* c, WarEntityId id) { NOT_USED(c); return id == 1 ? &forestEntity : NULL; }

#include "war_roads.inc"
#include "war_walls.inc"
#include "war_ruins.inc"

#include "war_ruins_tail.inc"
#include "war_trees.inc"
#include "war_trees_valid.inc"

/* ---- griglia ---- */
#define MAP_GRID_TILE_SIZE 4
#define MAP_GRID_TILES_WIDTH (MAP_TILES_WIDTH/MAP_GRID_TILE_SIZE)
#define MAP_GRID_TILES_HEIGHT (MAP_TILES_HEIGHT/MAP_GRID_TILE_SIZE)
#define MAP_GRID_CELLS (MAP_GRID_TILES_WIDTH * MAP_GRID_TILES_HEIGHT)
vec2 wgrid_tileFromMapTile(vec2 tilePosition);
s32 wgrid_getTileIndex(vec2 tile);
static WarEntityList* we_getEntitiesOfType(WarContext* context, s32 type) { NOT_USED(type); return &context->map->units; }
static bool we_isComponentEnabled(WarContext* c, WarEntity* e, s32 comp) { NOT_USED(c); NOT_USED(comp); return e->enabled; }
#define COMP_TRANSFORM 0
static bool wst_isGoingToDie(WarContext* c, WarEntity* e) { NOT_USED(c); return e->dying; }
static bool wst_isCollapsing(WarContext* c, WarEntity* e) { NOT_USED(c); return e->collapsing; }
static bool wst_isGoingToCollapse(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return false; }
static vec2 wu_getUnitCenterTile(WarContext* c, WarEntity* e) { NOT_USED(c); return e->tile; }
#include "war_map_grid.inc"

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

/* generatore di scenari: lo stesso in Pascal */
static u32 rngState;
static void rngSeed(u32 seed) { rngState = seed; }
static u32 rngNext(void)
{
    rngState = rngState * 1103515245u + 12345u;
    return (rngState >> 16) & 0x7FFFu;
}
static s32 rngRange(s32 n) { return (s32)(rngNext() % (u32)n); }

/* ---------- livelli ---------- */
static void unitBytes(u32* crc, const WarLevelUnit* u)
{
    u8 b[7] = { u->x, u->y, (u8)u->type, u->player, (u8)u->resourceKind, (u8)(u->amount & 0xFF), (u8)(u->amount >> 8) };
    *crc = crc_update(*crc, b, 7);
}
static void constructBytes(u32* crc, const WarLevelConstruct* c)
{
    u8 b[6] = { (u8)c->type, c->x1, c->y1, c->x2, c->y2, c->player };
    *crc = crc_update(*crc, b, 6);
}

static void dumpLevel(WarContext* context, s32 index)
{
    WarResource* r = &context->resources[index];
    if (r->type == WAR_RESOURCE_TYPE_LEVEL_INFO)
    {
        printf("L %d %u %d %08x %u %u %u %u %u %u %u %u\n", index, r->levelInfo.tilesetType, r->levelInfo.customMap,
               r->levelInfo.allowId, r->levelInfo.startX, r->levelInfo.startY, r->levelInfo.nextLevelIndex,
               r->levelInfo.visualIndex, r->levelInfo.passableIndex, r->levelInfo.paletteIndex,
               r->levelInfo.tilesIndex, r->levelInfo.tilesetIndex);
        printf("F %d %d %d %08x\n", index, r->levelInfo.allowedHumanUnits, r->levelInfo.allowedOrcsUnits,
               crc32_of(r->levelInfo.allowedFeatures, MAX_FEATURES_COUNT));
        printf("U %d %08x\n", index, crc32_of((const u8*)r->levelInfo.allowedUpgrades, MAX_UPGRADES_COUNT * MAX_PLAYERS_COUNT));
        printf("R %d", index);
        for (int i = 0; i < 5; i++) printf(" %u", r->levelInfo.lumber[i]);
        for (int i = 0; i < 5; i++) printf(" %u", r->levelInfo.gold[i]);
        for (int i = 0; i < 5; i++) printf(" %d", (int)r->levelInfo.races[i]);
        printf("\n");
        printf("O %d %u %08x\n", index, (u32)strlen(r->levelInfo.objectives),
               crc32_of((const u8*)r->levelInfo.objectives, strlen(r->levelInfo.objectives)));
        u32 crc = 0xFFFFFFFFu;
        for (u32 i = 0; i < r->levelInfo.startEntitiesCount; i++) unitBytes(&crc, &r->levelInfo.startEntities[i]);
        printf("E %d %u %08x\n", index, r->levelInfo.startEntitiesCount, crc ^ 0xFFFFFFFFu);
        crc = 0xFFFFFFFFu;
        for (u32 i = 0; i < r->levelInfo.startRoadsCount; i++) constructBytes(&crc, &r->levelInfo.startRoads[i]);
        printf("D %d %u %08x\n", index, r->levelInfo.startRoadsCount, crc ^ 0xFFFFFFFFu);
        crc = 0xFFFFFFFFu;
        for (u32 i = 0; i < r->levelInfo.startWallsCount; i++) constructBytes(&crc, &r->levelInfo.startWalls[i]);
        printf("W %d %u %08x\n", index, r->levelInfo.startWallsCount, crc ^ 0xFFFFFFFFu);
        crc = 0xFFFFFFFFu;
        for (u32 i = 0; i < r->levelInfo.startGoldminesCount; i++) unitBytes(&crc, &r->levelInfo.startGoldmines[i]);
        printf("G %d %u %08x\n", index, r->levelInfo.startGoldminesCount, crc ^ 0xFFFFFFFFu);
        printf("K %d %u", index, r->levelInfo.startConfigurationsCount);
        for (u32 k = 0; k < r->levelInfo.startConfigurationsCount; k++)
        {
            crc = 0xFFFFFFFFu;
            WarCustomMapConfiguration* cf = &r->levelInfo.startConfigurations[k];
            for (u32 i = 0; i < cf->startEntitiesCount; i++) unitBytes(&crc, &cf->startEntities[i]);
            printf(" %u:%08x", cf->startEntitiesCount, crc ^ 0xFFFFFFFFu);
        }
        printf("\n");
    }
    else if (r->type == WAR_RESOURCE_TYPE_LEVEL_VISUAL)
        printf("V %d %08x\n", index, crc32_of((const u8*)r->levelVisual.data, MAP_TILES_WIDTH * MAP_TILES_HEIGHT * 2));
    else if (r->type == WAR_RESOURCE_TYPE_LEVEL_PASSABLE)
        printf("A %d %08x\n", index, crc32_of((const u8*)r->levelPassable.data, MAP_TILES_WIDTH * MAP_TILES_HEIGHT * 2));
}

static void runLevels(const char* path)
{
    bool skipDecompress[MAX_RESOURCES_COUNT];
    memset(skipDecompress, 0, sizeof(skipDecompress));
    for (size_t i = 0; i < arrayLength(assets); ++i)
        if (assets[i].type == DB_ENTRY_TYPE_UNKNOWN)
            skipDecompress[assets[i].index] = true;

    WarContext context = {0};
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
            case DB_ENTRY_TYPE_LEVEL_INFO: wres_loadLevelInfo(&context, &entry); break;
            case DB_ENTRY_TYPE_LEVEL_VISUAL: wres_loadLevelVisual(&context, &entry); break;
            case DB_ENTRY_TYPE_LEVEL_PASSABLE: wres_loadLevelPassable(&context, &entry); break;
            default: break;
        }
    }
    for (size_t i = 0; i < arrayLength(assets); ++i)
    {
        switch (assets[i].type)
        {
            case DB_ENTRY_TYPE_LEVEL_INFO:
            case DB_ENTRY_TYPE_LEVEL_VISUAL:
            case DB_ENTRY_TYPE_LEVEL_PASSABLE:
                dumpLevel(&context, assets[i].index);
                break;
            default: break;
        }
    }
}

/* ---------- campagne ---------- */
static void printEscaped(const char* s)
{
    putchar('"');
    for (; s && *s; s++)
    {
        if (*s == '\n') printf("\\n");
        else if (*s == '\t') printf("\\t");
        else if (*s == '"') printf("\\\"");
        else if (*s == '\\') printf("\\\\");
        else putchar(*s);
    }
    putchar('"');
}

static void runCampaigns(void)
{
    printf("N unit goldmine=%d farmH=%d farmO=%d barrH=%d barrO=%d count=%d\n", WAR_UNIT_GOLDMINE,
           WAR_UNIT_FARM_HUMANS, WAR_UNIT_FARM_ORCS, WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_BARRACKS_ORCS, WAR_UNIT_COUNT);
    for (int t = WAR_CAMPAIGN_HUMANS_01; t <= WAR_CAMPAIGN_CUSTOM; t++)
    {
        WarCampaignMapData d = wcamp_getCampaignData((WarCampaignMapType)t);
        printf("K %d ", d.type);
        printEscaped(d.objectives.data);
        printf(" %d ", d.briefingAudioId);
        printEscaped(d.briefingText.data);
        printf(" %g %d\n", (double)d.briefingDuration, d.checkObjectivesFunc != NULL);
    }
    for (int race = 0; race <= 3; race++)
        for (int mission = 0; mission <= 13; mission++)
        {
            WarCampaignMapType mt = 0;
            bool ok = wcamp_tryGetMapType((WarRace)race, mission, &mt);
            printf("M %d %d %d %d\n", race, mission, ok, ok ? (int)mt : 0);
        }
    WarCampaignMapType mt;
    printf("M null %d\n", wcamp_tryGetMapType(WAR_RACE_HUMANS, 1, NULL) ? 1 : 0);
    NOT_USED(mt);
}

static void runObjectives(void)
{
    static WarMap map;
    WarContext ctx = {0};
    ctx.map = &map;
    for (int p = 0; p < 5; p++) map.players[p].index = p;
    const WarCampaignMapType types[] = { WAR_CAMPAIGN_HUMANS_01, WAR_CAMPAIGN_ORCS_01, WAR_CAMPAIGN_HUMANS_02,
                                         WAR_CAMPAIGN_ORCS_02, WAR_CAMPAIGN_CUSTOM };
    for (size_t k = 0; k < arrayLength(types); k++)
    {
        rngSeed(1000 + (u32)k);
        printf("O %d ", types[k]);
        for (int s = 0; s < 400; s++)
        {
            memset(&census, 0, sizeof(census));
            map.players[0].race = (WarRace)(1 + rngRange(2));
            map.players[1].race = map.players[0].race == WAR_RACE_HUMANS ? WAR_RACE_ORCS : WAR_RACE_HUMANS;
            for (int p = 0; p < 2; p++)
            {
                census.totalUnits[p] = rngRange(4) == 0 ? 0 : rngRange(10);
                census.totalDudes[p] = rngRange(3) == 0 ? 0 : rngRange(6);
            }
            census.buildings[0][WAR_UNIT_FARM_HUMANS] = rngRange(9);
            census.buildings[0][WAR_UNIT_FARM_ORCS] = rngRange(9);
            census.buildings[0][WAR_UNIT_BARRACKS_HUMANS] = rngRange(3);
            census.buildings[0][WAR_UNIT_BARRACKS_ORCS] = rngRange(3);
            WarCampaignMapData d = wcamp_getCampaignData(types[k]);
            int result = d.checkObjectivesFunc ? (int)d.checkObjectivesFunc(&ctx) : -1;
            putchar(result < 0 ? 'x' : '0' + result);
        }
        printf("\n");
    }
}

/* ---------- tabelle ---------- */
static void runTables(void)
{
    for (size_t i = 0; i < arrayLength(roadsData); i++)
        printf("TR %d %d %d\n", roadsData[i].type, roadsData[i].tileIndexForest, roadsData[i].tileIndexSwamp);
    for (size_t i = 0; i < arrayLength(wallsData); i++)
        printf("TW %d %d %d %d %d %d %d\n", wallsData[i].type, wallsData[i].tileForest, wallsData[i].tileDamagedForest,
               wallsData[i].tileDestroyedForest, wallsData[i].tileSwamp, wallsData[i].tileDamagedSwamp,
               wallsData[i].tileDestroyedSwamp);
    for (size_t i = 0; i < arrayLength(ruinsData); i++)
        printf("TU %d %d %d\n", ruinsData[i].type, ruinsData[i].tileIndexForest, ruinsData[i].tileIndexSwamp);
    for (size_t i = 0; i < arrayLength(treesData); i++)
        printf("TT %d %d %d\n", treesData[i].type, treesData[i].tileIndexForest, treesData[i].tileIndexSwamp);
    printf("MR");
    for (int i = 0; i < 16; i++) printf(" %d", roadTileTypeMap[i]);
    printf("\nMW");
    for (int i = 0; i < 16; i++) printf(" %d", wallTileTypeMap[i]);
    printf("\nMU");
    for (int i = 0; i < 256; i++) printf(" %d", ruinTileTypeMap[i]);
    printf("\nMT");
    for (int i = 0; i < 256; i++) printf(" %d", treeTileTypeMap[i]);
    printf("\nMF");
    for (int i = 0; i < 256; i++) printf(" %d", fogTileTypeMap[i]);
    printf("\n");
}

/* ---------- pezzi ---------- */
static void randomConstruct(WarLevelConstruct* c, WarConstructType type)
{
    c->type = type;
    c->x1 = (u8)rngRange(70);
    c->y1 = (u8)rngRange(70);
    c->x2 = (u8)rngRange(70);
    c->y2 = (u8)rngRange(70);
    c->player = (u8)rngRange(5);
}

static void runAutotile(void)
{
    static WarMap map;
    WarContext ctx = {0};
    ctx.map = &map;
    roadEntity.type = WAR_ENTITY_TYPE_ROAD;
    wallEntity.type = WAR_ENTITY_TYPE_WALL;
    ruinEntity.type = WAR_ENTITY_TYPE_RUIN;
    forestEntity.type = WAR_ENTITY_TYPE_FOREST;
    for (int s = 0; s < 120; s++)
    {
        rngSeed(5000 + (u32)s);
        memset(&theRoad, 0, sizeof(theRoad));
        memset(&theWall, 0, sizeof(theWall));
        int n = 1 + rngRange(4);
        for (int i = 0; i < n; i++)
        {
            WarLevelConstruct c;
            randomConstruct(&c, WAR_CONSTRUCT_ROAD);
            we_addRoadPiecesFromConstruct(&ctx, &roadEntity, &c);
            randomConstruct(&c, WAR_CONSTRUCT_WALL);
            we_addWallPiecesFromConstruct(&ctx, &wallEntity, &c);
        }
        we_determineRoadTypes(&ctx, &roadEntity);
        we_determineWallTypes(&ctx, &wallEntity);
        u32 crc = 0xFFFFFFFFu;
        for (int i = 0; i < theRoad.pieces.count; i++)
        {
            WarRoadPiece* p = &theRoad.pieces.items[i];
            u8 b[4] = { (u8)p->type, (u8)p->tilex, (u8)p->tiley, p->player };
            crc = crc_update(crc, b, 4);
        }
        printf("R %d %d %08x\n", s, theRoad.pieces.count, crc ^ 0xFFFFFFFFu);
        crc = 0xFFFFFFFFu;
        for (int i = 0; i < theWall.pieces.count; i++)
        {
            WarWallPiece* p = &theWall.pieces.items[i];
            u8 b[4] = { (u8)p->type, (u8)p->tilex, (u8)p->tiley, p->player };
            crc = crc_update(crc, b, 4);
        }
        printf("W %d %d %08x\n", s, theWall.pieces.count, crc ^ 0xFFFFFFFFu);
        /* una pezzo cercato e rimosso */
        if (theRoad.pieces.count > 0)
        {
            WarRoadPiece* p = we_getRoadPieceAtPosition(&ctx, &roadEntity, theRoad.pieces.items[0].tilex, theRoad.pieces.items[0].tiley);
            printf("r %d %d %d %d\n", s, p ? p->type : -1, we_hasRoadPieceAtPosition(&ctx, &roadEntity, 99, 99),
                   we_hasRoadPieceAtPosition(&ctx, &roadEntity, theRoad.pieces.items[0].tilex, theRoad.pieces.items[0].tiley));
            WarRoadPiece first = theRoad.pieces.items[0];
            we_removeRoadPiece(&ctx, &roadEntity, &first);
            printf("rr %d %d\n", s, theRoad.pieces.count);
        }
        /* rovine */
        memset(&theRuin, 0, sizeof(theRuin));
        int m = 1 + rngRange(4);
        for (int i = 0; i < m; i++)
            we_addRuinsPieces(&ctx, &ruinEntity, rngRange(66), rngRange(66), 1 + rngRange(5));
        int before = theRuin.pieces.count;
        we_determineRuinTypes(&ctx, &ruinEntity);
        crc = 0xFFFFFFFFu;
        for (int i = 0; i < theRuin.pieces.count; i++)
        {
            WarRuinPiece* p = &theRuin.pieces.items[i];
            u8 b[3] = { (u8)p->type, (u8)p->tilex, (u8)p->tiley };
            crc = crc_update(crc, b, 3);
        }
        printf("U %d %d %d %08x\n", s, before, theRuin.pieces.count, crc ^ 0xFFFFFFFFu);
        /* alberi */
        memset(&theForest, 0, sizeof(theForest));
        int t = 5 + rngRange(120);
        for (int i = 0; i < t; i++)
        {
            WarTree tr = createTree(rngRange(66) - 1, rngRange(66) - 1, rngRange(4));
            if (rngRange(8) == 0) tr.type = WAR_TREE_CHOPPED;
            if (!we_hasTreeAtPosition(&ctx, &forestEntity, tr.tilex, tr.tiley))
                WarTreeListAdd(&theForest.trees, tr);
        }
        before = theForest.trees.count;
        we_determineTreeTiles(&ctx, &forestEntity);
        crc = 0xFFFFFFFFu;
        for (int i = 0; i < theForest.trees.count; i++)
        {
            WarTree* p = &theForest.trees.items[i];
            u8 b[4] = { (u8)p->type, (u8)p->tilex, (u8)p->tiley, (u8)p->amount };
            crc = crc_update(crc, b, 4);
        }
        printf("T %d %d %d %08x\n", s, before, theForest.trees.count, crc ^ 0xFFFFFFFFu);
        if (theForest.trees.count > 0)
        {
            WarTree* p = &theForest.trees.items[0];
            printf("v %d %d\n", s, we_validTree(&ctx, &forestEntity, p));
        }
    }
}

/* ---------- griglia ---------- */
static void runGrid(void)
{
    static WarMap map;
    WarContext ctx = {0};
    ctx.map = &map;
    for (int s = 0; s < 60; s++)
    {
        rngSeed(9000 + (u32)s);
        memset(&map, 0, sizeof(map));
        int n = rngRange(200);
        map.units.count = 0;
        for (int i = 0; i < n; i++)
        {
            /* un'entita' a caso in uno slot a caso (slot unici crescenti con salti) */
            int slot = (i * 5 + rngRange(5)) % MAX_ENTITIES_COUNT;
            WarEntity* e = &map.entityManager.entities[slot];
            e->enabled = rngRange(8) != 0;
            e->dying = rngRange(10) == 0;
            e->collapsing = rngRange(12) == 0;
            e->tile.x = (f32)(rngRange(75) - 5) + (f32)rngRange(4) * 0.25f;
            e->tile.y = (f32)(rngRange(75) - 5) + (f32)rngRange(4) * 0.25f;
            map.units.items[map.units.count++] = e;
        }
        wgrid_build(&ctx);
        u32 crc = 0xFFFFFFFFu;
        for (int i = 0; i < MAP_GRID_CELLS; i++)
        {
            u8 b[4] = { (u8)map.grid.head[i], (u8)(map.grid.head[i] >> 8), 0, 0 };
            crc = crc_update(crc, b, 4);
        }
        for (int i = 0; i < MAX_ENTITIES_COUNT; i++)
        {
            u8 b[4] = { (u8)map.grid.next[i], (u8)(map.grid.next[i] >> 8), 0, 0 };
            crc = crc_update(crc, b, 4);
        }
        printf("B %d %d %08x\n", s, n, crc ^ 0xFFFFFFFFu);
        wgrid_clear(&ctx);
        int nonempty = 0;
        for (int i = 0; i < MAP_GRID_CELLS; i++) nonempty += map.grid.head[i] != -1;
        printf("b %d %d\n", s, nonempty);
    }
    printf("X");
    const f32 coords[] = { -1.0f, -0.5f, 0.0f, 3.9f, 4.0f, 15.75f, 63.0f, 63.99f, 64.0f, 70.0f };
    for (size_t i = 0; i < arrayLength(coords); i++)
    {
        vec2 g = wgrid_tileFromMapTile(vec2i((s32)coords[i], (s32)coords[(i + 3) % arrayLength(coords)]));
        vec2 raw; raw.x = coords[i]; raw.y = coords[(i + 3) % arrayLength(coords)];
        vec2 g2 = wgrid_tileFromMapTile(raw);
        printf(" %d,%d:%d:%d", (int)g.x, (int)g.y, wgrid_getTileIndex(g), wgrid_getTileIndex(g2));
    }
    printf("\n");
}

int main(int argc, char** argv)
{
    crc_init();
    if (argc < 3)
        return 2;
    if (strcmp(argv[2], "levels") == 0) runLevels(argv[1]);
    else if (strcmp(argv[2], "campaigns") == 0) runCampaigns();
    else if (strcmp(argv[2], "objectives") == 0) runObjectives();
    else if (strcmp(argv[2], "tables") == 0) runTables();
    else if (strcmp(argv[2], "autotile") == 0) runAutotile();
    else if (strcmp(argv[2], "grid") == 0) runGrid();
    else return 2;
    return 0;
}
