/*
  Issue #193 (seconda fetta): harness di riferimento per la mappa di gioco di Libs\War.
  Compila il codice ORIGINALE di acoto87/war1 (zlib License, (C) 2019 Alejandro Coto Gutierrez) estratto alla lettera da
  Compila-MapRef.ps1 (file *.inc): wmap_enterMap (le funzioni init* e create*), le funzioni di stato delle tegole di
  war_map.c, updateFoW, determineFoWTypes, il ciclo di renderMinimap, we_createUnit, le funzioni wpath_* della griglia, le
  funzioni wu_* delle unita', le tabelle di war_units.c e war_trees.c intero (piantare, abbattere, tagliare). Qui ci sono
  solo gli stub di SDL, Tracy, del log, delle liste di shl, del gestore delle entita' e dei loro componenti, degli stati
  delle unita' (nessuna e' morta o in crollo) e due scorciatoie dichiarate: we_setInitialIdleState fa le due righe di
  wst_enterIdleState che occupano la griglia, e randomi (la direzione iniziale di un'unita', che non e' un dato del
  livello) vale sempre 0. Questo file e' una versione modificata del remake solo per far girare quel codice.

  Uso:  war_map_ref DATA.WAR maps     per ogni livello: la mappa appena creata, il fog dopo il primo aggiornamento, la minimappa
        war_map_ref DATA.WAR trees    scenari di alberi con seme fisso (piantare, tagliare, cercare)
        war_map_ref DATA.WAR tables   le tabelle delle unita' (dati del generatore Make-WarMapTables.ps1)
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
#define inRange(x, a, b) ((x) >= (a) && (x) < (b))
#define SIGN(x) ((x) < 0 ? -1 : 1)
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define CLAMP(x, a, b) ((x) < (a) ? (a) : ((x) > (b) ? (b) : (x)))

#include "war_defines.inc"
#include "war_wall_hp.inc"

typedef struct { const char* data; size_t length; } StringView;
#define WSV_INIT(s) { s, sizeof(s) - 1 }
static const char* wsv_data(StringView v) { return v.data; }
static StringView wsv_fromCString(const char* s)
{
    StringView v;
    v.data = s;
    v.length = s ? strlen(s) : 0;
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
typedef struct _WarMap WarMap;
typedef struct _WarEntity WarEntity;
typedef struct _WarUnitData WarUnitData;
typedef struct _WarUnitStats WarUnitStats;
typedef struct _WarBuildingStats WarBuildingStats;
typedef struct _WarTreeData WarTreeData;
typedef int WarUnitActionType;

/* war_color.h (solo il tipo e le macro che servono) */
typedef union {
    uint32_t packed;
    uint8_t rgba[4];
    struct { uint8_t r, g, b, a; };
} WarColor;
#define WAR_COLOR_RGBA_INIT(r_, g_, b_, a_) {.r = r_, .g = g_, .b = b_, .a = a_}
#define WAR_COLOR_RGBA(r_, g_, b_, a_) ((WarColor)WAR_COLOR_RGBA_INIT(r_, g_, b_, a_))
#define WAR_COLOR_RGB(r_, g_, b_) WAR_COLOR_RGBA(r_, g_, b_, 255)
#define WAR_COLOR_PACKED_INIT(value) { .packed = (uint32_t)(value) }
#define WAR_COLOR_PACKED(value) ((WarColor)WAR_COLOR_PACKED_INIT(value))
#define WAR_COLOR_BLACK WAR_COLOR_PACKED(0xFF000000)

#include "enum_WarRace.inc"
#include "enum_WarDirection.inc"
#include "enum_WarUnitType.inc"
#include "enum_WarResourceKind.inc"
#include "enum_WarConstructType.inc"
#include "enum_WarCampaignMapType.inc"
#include "enum_WarLevelResult.inc"
#include "enum_WarAudioId.inc"
#include "enum_WarEntityType.inc"
#include "enum_WarRoadPieceType.inc"
#include "enum_WarWallPieceType.inc"
#include "enum_WarRuinPieceType.inc"
#include "enum_WarTreeTileType.inc"
#include "enum_WarPathFinderDataType.inc"
#include "enum_WarMapTilesetType.inc"
#include "enum_WarFogPieceType.inc"
#include "enum_WarFogBoundaryType.inc"
#include "enum_WarUnitPortraits.inc"
#include "enum_WarMapTileState.inc"

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
#define VEC2_ONE ((vec2){1.0f, 1.0f})
static vec2 vec2i(s32 x, s32 y) { vec2 v; v.x = (f32)x; v.y = (f32)y; return v; }
static rect recti(s32 x, s32 y, s32 width, s32 height) { return (rect){(f32)x, (f32)y, (f32)width, (f32)height}; }
static rect rectv(vec2 pos, vec2 size) { return (rect){pos.x, pos.y, size.x, size.y}; }
static rect rect_expand(rect r, f32 dx, f32 dy)
{
    r.x -= dx;
    r.y -= dy;
    r.width += dx * 2;
    r.height += dy * 2;
    return r;
}

typedef uint16_t WarEntityId;

/* ---- tabelle e strutture di war_units.h ---- */
struct _WarUnitData { WarUnitType type; s32 resourceIndex; s32 portraitFrameIndex; s32 sizex; s32 sizey; StringView name; };
struct _WarUnitStats
{
    WarUnitType type; s32 range; s32 sight; s32 armor; s32 hp; s32 mana; s32 minDamage; s32 rndDamage;
    s32 buildTime; s32 goldCost; s32 woodCost; s32 decay; f32 speeds[3];
};
struct _WarBuildingStats { WarUnitType type; s32 armor; s32 sight; s32 hp; s32 buildTime; s32 goldCost; s32 woodCost; };
typedef struct { WarRoadPieceType type; s32 tileIndexForest; s32 tileIndexSwamp; } WarRoadData;
typedef struct { WarWallPieceType type; s32 tileForest; s32 tileDamagedForest; s32 tileDestroyedForest;
                 s32 tileSwamp; s32 tileDamagedSwamp; s32 tileDestroyedSwamp; } WarWallData;
typedef struct { WarRuinPieceType type; s32 tileIndexForest; s32 tileIndexSwamp; } WarRuinData;
struct _WarTreeData { WarTreeTileType type; s32 tileIndexForest; s32 tileIndexSwamp; };
#include "war_tables.inc"

/* ---- pezzi e liste ---- */
typedef struct _WarRoadPiece { WarRoadPieceType type; s32 tilex, tiley; u8 player; } WarRoadPiece;
typedef struct _WarWallPiece { WarWallPieceType type; s32 hp; s32 maxhp; s32 tilex, tiley; u8 player; } WarWallPiece;
typedef struct _WarRuinPiece { WarRuinPieceType type; s32 tilex, tiley; } WarRuinPiece;
typedef struct _WarTree { WarTreeTileType type; s32 tilex, tiley; s32 amount; } WarTree;

#define createRoadPiece(x, y, player) ((WarRoadPiece){0, (x), (y), (u8)(player)})
#define createWallPiece(x, y, player) ((WarWallPiece){0, 0, 0, (x), (y), (u8)(player)})
#define createRuinPiece(x, y) ((WarRuinPiece){0, (x), (y)})
#define createTree(x, y, amount) ((WarTree){0, (x), (y), (amount)})

/* una lista come shlDeclareList/shlDefineList (list.h): IndexOf, Remove e RemoveAt hanno la stessa semantica */
#define DECL_LIST(typeName, itemType) \
    typedef struct { s32 count; s32 capacity; itemType* items; } typeName; \
    static void typeName ## Init(typeName* l, void* a) { NOT_USED(a); l->count = 0; l->capacity = 0; l->items = NULL; } \
    static void typeName ## Add(typeName* l, itemType v) \
    { \
        if (l->count == l->capacity) \
        { \
            l->capacity = l->capacity ? l->capacity * 2 : 8; \
            l->items = (itemType*)realloc(l->items, (size_t)l->capacity * sizeof(itemType)); \
        } \
        l->items[l->count++] = v; \
    } \
    static void typeName ## RemoveAt(typeName* l, s32 i) \
    { \
        if (!l->items || i < 0 || i >= l->count) return; \
        memmove(l->items + i, l->items + i + 1, (size_t)(l->count - i - 1) * sizeof(itemType)); \
        l->count -= 1; \
    } \
    static s32 typeName ## IndexOf(typeName* l, itemType v, bool (*eq)(const itemType, const itemType)) \
    { \
        if (!l->items || !eq) return -1; \
        for (s32 i = 0; i < l->count; i++) if (eq(l->items[i], v)) return i; \
        return -1; \
    } \
    static bool typeName ## Contains(typeName* l, itemType v, bool (*eq)(const itemType, const itemType)) \
    { return typeName ## IndexOf(l, v, eq) >= 0; } \
    static void typeName ## Remove(typeName* l, itemType v, bool (*eq)(const itemType, const itemType)) \
    { s32 i = typeName ## IndexOf(l, v, eq); if (i >= 0) typeName ## RemoveAt(l, i); } \
    static void typeName ## Free(typeName* l) { free(l->items); l->items = NULL; l->count = 0; l->capacity = 0; }

DECL_LIST(WarRoadPieceList, WarRoadPiece)
DECL_LIST(WarWallPieceList, WarWallPiece)
DECL_LIST(WarRuinPieceList, WarRuinPiece)
DECL_LIST(WarTreeList, WarTree)
DECL_LIST(S32List, s32)
DECL_LIST(Vec2List, vec2)
DECL_LIST(WarEntityList, WarEntity*)

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
static bool equalsVec2(const vec2 v1, const vec2 v2) { return v1.x == v2.x && v1.y == v2.y; }
static void* wm_frameAllocator(void) { return NULL; }
static void* wm_globalAllocator(void) { return NULL; }

/* ---- sprite (solo i dati: nessuna texture) ---- */
typedef struct _WarSprite
{
    s32 frameWidth;
    s32 frameHeight;
    s32 framesCount;
    WarSpriteFrame frames[MAX_SPRITE_FRAME_COUNT];
} WarSprite;

static WarSprite wspr_createSprite(WarContext* context, u32 width, u32 height, u8 data[])
{
    NOT_USED(context);
    WarSprite sprite = (WarSprite){0};
    sprite.frameWidth = (s32)width;
    sprite.frameHeight = (s32)height;
    sprite.framesCount = 1;
    sprite.frames[0].w = (u16)width;
    sprite.frames[0].h = (u16)height;
    sprite.frames[0].data = (u8*)wm_alloc(width * height * 4);
    if (data) memcpy(sprite.frames[0].data, data, width * height * 4);
    return sprite;
}

#define FRAME_SLACK (16 * MINIMAP_WIDTH * 4)   /* margine dopo il fotogramma: si controlla che resti zero (scritture fuori dal buffer) */
static WarSprite wspr_createSpriteFromFrames(WarContext* context, u32 frameWidth, u32 frameHeight, u32 frameCount, WarSpriteFrame frames[])
{
    NOT_USED(context);
    WarSprite sprite = (WarSprite){0};
    sprite.frameWidth = (s32)frameWidth;
    sprite.frameHeight = (s32)frameHeight;
    sprite.framesCount = (s32)frameCount;
    for (u32 i = 0; i < frameCount; i++)
    {
        sprite.frames[i].dx = frames[i].dx;
        sprite.frames[i].dy = frames[i].dy;
        sprite.frames[i].w = frames[i].w;
        sprite.frames[i].h = frames[i].h;
        sprite.frames[i].off = 0;
        sprite.frames[i].data = (u8*)wm_alloc(frameWidth * frameHeight * 4 + FRAME_SLACK);
        if (frames[i].data) memcpy(sprite.frames[i].data, frames[i].data, frameWidth * frameHeight * 4);
    }
    return sprite;
}

/* ---- la mappa e il contesto ---- */
typedef struct _WarMapTile { WarMapTileState state; WarFogPieceType type; WarFogBoundaryType boundary; } WarMapTile;
typedef struct { u8 allowed; u8 level; } WarUpgrade;
typedef struct _WarPlayerInfo
{
    u8 index;
    WarRace race;
    s32 gold;
    s32 wood;
    bool godMode;
    bool features[MAX_FEATURES_COUNT];
    WarUpgrade upgrades[MAX_UPGRADES_COUNT];
} WarPlayerInfo;
#define isNeutralPlayer(p) ((p)->race == WAR_RACE_NEUTRAL)

typedef struct { u16 data[MAP_TILES_WIDTH * MAP_TILES_HEIGHT]; } WarPathFinder;
typedef struct { bool enabled; bool hasGold; s32 gold; bool hasWood; s32 wood; } WarCustomGameOptions;

typedef struct { vec2 position; vec2 rotation; vec2 scale; } WarTransformComponent;
typedef struct
{
    WarUnitType type; s32 direction; s32 tilex, tiley; s32 sizex, sizey; u8 player; WarResourceKind resourceKind; s32 amount;
    s32 maxhp, hp, maxMana, mana, armor, range, minDamage, rndDamage, decay; f32 manaTime;
    bool hasBeenSeen;
} WarUnitComponent;
typedef struct { WarRoadPieceList pieces; } WarRoadComponent;
typedef struct { WarWallPieceList pieces; } WarWallComponent;
typedef struct { WarRuinPieceList pieces; } WarRuinComponent;
typedef struct { WarTreeList trees; } WarForestComponent;
typedef struct { vec2 position; } WarSightComponent;

struct _WarEntity
{
    WarEntityId id;
    u16 type;
    WarTransformComponent transform;
    WarUnitComponent unit;
    WarRoadComponent road;
    WarWallComponent wall;
    WarRuinComponent ruin;
    WarForestComponent forest;
};

typedef struct { WarEntity* forest; WarEntity* road; WarEntity* wall; WarEntity* ruin; } WarMapEditing;
typedef struct { s32 dummy; } WarUnitMap;
typedef struct { WarUnitMap unitsByType; } WarEntityManager;
typedef struct { rect viewport; bool isScrolling; bool wasScrolling; } WarCamera;

struct _WarMap
{
    s32 levelInfoIndex;
    bool custom;
    bool playing;
    s32 tilesetType;
    s32 result;
    f32 objectivesTime;
    WarCustomGameOptions customGame;
    bool hasCustomCameraStart;
    s32 customCameraCenterX, customCameraCenterY;
    WarCamera camera;
    WarPathFinder finder;
    WarSprite sprite;
    WarSprite minimapSprite;
    WarSprite blackSprite;
    WarMapTile tiles[MAP_TILES_WIDTH * MAP_TILES_HEIGHT];
    WarMapEditing editing;
    WarEntityManager entityManager;
    WarPlayerInfo players[MAX_PLAYERS_COUNT];
    s32 playersCount;
    bool fowEnabled;
    /* el gestor delle entita' */
    WarEntity* entitiesById[65536];
    WarEntityList entitiesOfType[WAR_ENTITY_TYPE_COUNT];
    u32 nextEntityId;
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
#include "war_res_tiles.inc"

/* ---- il gestore delle entita' (stub) ---- */
static WarEntity* we_createEntity(WarContext* context, WarEntityType type, bool addToScene)
{
    WarMap* map = context->map;
    WarEntity* entity = (WarEntity*)calloc(1, sizeof(WarEntity));
    entity->id = (u16)++map->nextEntityId;
    entity->type = (u16)type;
    if (addToScene)
    {
        map->entitiesById[entity->id] = entity;
        WarEntityListAdd(&map->entitiesOfType[type], entity);
    }
    return entity;
}
static WarEntity* we_findEntity(WarContext* context, WarEntityId id) { return context->map->entitiesById[id]; }
static WarEntityList* we_getEntitiesOfType(WarContext* context, s32 type) { return &context->map->entitiesOfType[type]; }

static WarUnitComponent* we_getUnitComponent(WarContext* c, const WarEntity* e) { NOT_USED(c); return e->type == WAR_ENTITY_TYPE_UNIT ? (WarUnitComponent*)&e->unit : NULL; }
static WarTransformComponent* we_getTransformComponent(WarContext* c, const WarEntity* e) { NOT_USED(c); return (WarTransformComponent*)&e->transform; }
static WarRoadComponent* we_getRoadComponent(WarContext* c, WarEntity* e) { NOT_USED(c); return &e->road; }
static WarWallComponent* we_getWallComponent(WarContext* c, WarEntity* e) { NOT_USED(c); return &e->wall; }
static WarRuinComponent* we_getRuinComponent(WarContext* c, WarEntity* e) { NOT_USED(c); return &e->ruin; }
static WarForestComponent* we_getForestComponent(WarContext* c, WarEntity* e) { NOT_USED(c); return &e->forest; }
static void we_addRoadComponent(WarContext* c, WarEntity* e, WarRoadPieceList pieces) { NOT_USED(c); e->road.pieces = pieces; }
static void we_addWallComponent(WarContext* c, WarEntity* e, WarWallPieceList pieces) { NOT_USED(c); e->wall.pieces = pieces; }
static void we_addRuinComponent(WarContext* c, WarEntity* e, WarRuinPieceList pieces) { NOT_USED(c); e->ruin.pieces = pieces; }
static void we_addForestComponent(WarContext* c, WarEntity* e, WarTreeList trees) { NOT_USED(c); e->forest.trees = trees; }
static void we_addTransformComponent(WarContext* c, WarEntity* e, WarTransformComponent t) { NOT_USED(c); e->transform = t; }
static void we_addUnitComponent(WarContext* c, WarEntity* e, WarUnitComponent u) { NOT_USED(c); e->unit = u; }
#define WAR_TRANSFORM_COMPONENT_INIT(...) ((WarTransformComponent){__VA_ARGS__})
#define WAR_UNIT_COMPONENT_INIT(...) ((WarUnitComponent){__VA_ARGS__})
#define WAR_SPRITE_COMPONENT_INIT(...) 0
static void we_addSpriteComponent(WarContext* c, WarEntity* e, int s) { NOT_USED(c); NOT_USED(e); NOT_USED(s); }
#define imageResourceRef(i) (i)
static void we_addSpriteComponentFromResource(WarContext* c, WarEntity* e, int r) { NOT_USED(c); NOT_USED(e); NOT_USED(r); }
static void wact_addUnitActions(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); }
static void we_addAnimationsComponent(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); }
static void we_addStateMachineComponent(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); }
static s32 randomi(s32 min, s32 max) { NOT_USED(min); NOT_USED(max); return 0; }   /* la direzione iniziale: non e' un dato del livello */

static WarEntityList theUnitsOfType;
static WarEntityList* WarUnitMapGet(WarUnitMap* m, WarUnitType t) { NOT_USED(m); NOT_USED(t); return &theUnitsOfType; }

typedef struct { WarUnitType type; s32 x; s32 y; u8 player; WarResourceKind resourceKind; u32 amount; bool addToMap; bool isGoingToTrain; bool isGoingToBuild; } CreateUnitArgs;
#define CREATE_UNIT_ARGS_INIT(...) (&(CreateUnitArgs){__VA_ARGS__})

/* gli stati delle unita': all'inizio nessuna e' morta, in crollo o in attacco */
static bool wst_isDead(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return false; }
static bool wst_isGoingToDie(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return false; }
static bool wst_isCollapsing(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return false; }
static bool wst_isGoingToCollapse(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return false; }
typedef struct { WarEntityId targetEntityId; vec2 targetPosition; } WarStateAttack;
static WarStateAttack* wst_getAttackState(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return NULL; }
static WarEntity* we_getAttacker(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return NULL; }
static bool wu_unitInRange(WarContext* c, WarEntity* a, WarEntity* b, s32 range) { NOT_USED(c); NOT_USED(a); NOT_USED(b); NOT_USED(range); return false; }
static bool wu_tileInRange(WarContext* c, WarEntity* a, vec2 t, s32 range) { NOT_USED(c); NOT_USED(a); NOT_USED(t); NOT_USED(range); return false; }
static bool wu_isWall(const WarEntity* e) { return e->type == WAR_ENTITY_TYPE_WALL; }
static WarSightComponent* we_getSightComponent(WarContext* c, WarEntity* e) { NOT_USED(c); NOT_USED(e); return NULL; }
static void wmap_removeEntityFromSelection(WarContext* c, WarEntityId id) { NOT_USED(c); NOT_USED(id); }
static void we_setInitialIdleState(WarContext* context, WarEntity* entity);

#include "war_find_by_type.inc"
#include "war_wu_getters.inc"
bool wpath_isEmpty(WarPathFinder* finder, s32 x, s32 y);
#include "war_path.inc"
#include "war_map_tile.inc"
#include "war_wu_funcs.inc"
#include "war_map_state.inc"

#include "war_roads.inc"
#include "war_walls.inc"
#include "war_ruins.inc"
#include "war_ruins_tail.inc"
#include "war_create_road.inc"
#include "war_create_wall.inc"
#include "war_create_ruins.inc"
#include "war_trees.inc"

/* we_createUnit: la funzione originale */
#include "war_create_unit.inc"

static void we_setInitialIdleState(WarContext* context, WarEntity* entity)
{
    /* wst_enterIdleState: la sola parte che tocca la mappa */
    WarMap* map = context->map;
    if (wu_isUnit(entity))
    {
        vec2 tile = wu_getUnitTile(context, entity);
        vec2 unitSize = wu_getUnitSize(context, entity);
        wpath_setStaticEntity(&map->finder, (s32)tile.x, (s32)tile.y, (s32)unitSize.x, (s32)unitSize.y, entity->id);
    }
}

/* wst_createIdleState e wst_resetState del muro: non toccano i dati che si controllano */
static void* wst_createIdleState(WarContext* c, WarEntity* e, bool lookAround) { NOT_USED(c); NOT_USED(e); NOT_USED(lookAround); return NULL; }
#define WAR_TRANSITION_CAUSE_INITIALIZATION 0
static void wst_resetState(WarContext* c, WarEntity* e, void* s, int cause) { NOT_USED(c); NOT_USED(e); NOT_USED(s); NOT_USED(cause); }
typedef struct { int x; } WarStateBase;
typedef struct { int y; } WarStateIdle;

#include "war_map_init.inc"
#include "war_map_fog.inc"

/* we_addRoadPiecesFromConstruct e le altre sono nei file *.inc; qui il corpo di wmap_enterMap senza camera UI, IA e audio */
static void enterMap(WarContext* context, s32 levelInfoIndex)
{
    WarMap* map = (WarMap*)calloc(1, sizeof(WarMap));
    map->levelInfoIndex = levelInfoIndex;
    context->map = map;

    WarResource* levelInfo = wres_getOrCreateResource(context, levelInfoIndex);
    assert(levelInfo && levelInfo->type == WAR_RESOURCE_TYPE_LEVEL_INFO);

    WarResource* levelPassable = wres_getOrCreateResource(context, levelInfo->levelInfo.passableIndex);
    assert(levelPassable && levelPassable->type == WAR_RESOURCE_TYPE_LEVEL_PASSABLE);

    map->playing = true;
    map->custom = levelInfo->levelInfo.customMap;
    map->tilesetType = levelInfo->levelInfo.tilesetType;
    map->fowEnabled = true;
    map->result = 0;
    map->objectivesTime = 1;

    initCamera(map, levelInfo);
    initPathFinder(map, levelPassable);
    initBlackSprite(context, map);
    setInitialTileState(map);
    createMapAndMinimapSprites(context, map, levelInfo);
    createForestEntities(context, map, levelPassable);
    createStartingRoads(context, map, levelInfo);
    createStartingWalls(context, map, levelInfo);
    createRuinEntity(context, map);
    initPlayersInfo(map, levelInfo);
    createStartingEntities(context, levelInfo);
}

/* il ciclo di renderMinimap: copia le tegole viste e disegna le unita' */
static void composeMinimap(WarContext* context)
{
    WarMap* map = context->map;
    WarSpriteFrame* frame0 = &map->minimapSprite.frames[0];
    WarSpriteFrame* frame1 = &map->minimapSprite.frames[1];
#include "war_minimap_loop.inc"
}

/* ---- impronte ---- */
static u32 crc_table[256];
static void crc_init(void)
{
    for (u32 i = 0; i < 256; i++)
    {
        u32 c = i;
        for (int k = 0; k < 8; k++) c = (c & 1) ? 0xEDB88320u ^ (c >> 1) : c >> 1;
        crc_table[i] = c;
    }
}
static u32 crc_update(u32 c, const u8* p, size_t n)
{
    for (size_t i = 0; i < n; i++) c = crc_table[(c ^ p[i]) & 0xFF] ^ (c >> 8);
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

static void put32(u32* crc, u32 v) { u8 b[4] = { (u8)v, (u8)(v >> 8), (u8)(v >> 16), (u8)(v >> 24) }; *crc = crc_update(*crc, b, 4); }

static u32 forestCrc(WarEntity* f)
{
    u32 crc = 0xFFFFFFFFu;
    put32(&crc, (u32)f->forest.trees.count);
    for (s32 i = 0; i < f->forest.trees.count; i++)
    {
        WarTree* t = &f->forest.trees.items[i];
        put32(&crc, (u32)t->type); put32(&crc, (u32)t->tilex); put32(&crc, (u32)t->tiley); put32(&crc, (u32)t->amount);
    }
    return crc ^ 0xFFFFFFFFu;
}

static u32 allForestsCrc(WarContext* context, s32* count, s32* trees)
{
    u32 crc = 0xFFFFFFFFu;
    WarEntityList* forests = we_getEntitiesOfType(context, WAR_ENTITY_TYPE_FOREST);
    *count = forests->count;
    *trees = 0;
    for (s32 i = 0; i < forests->count; i++)
    {
        put32(&crc, forests->items[i]->id);
        put32(&crc, forestCrc(forests->items[i]));
        *trees += forests->items[i]->forest.trees.count;
    }
    return crc ^ 0xFFFFFFFFu;
}

static u32 unitsCrc(WarContext* context, s32* count)
{
    u32 crc = 0xFFFFFFFFu;
    WarEntityList* units = we_getEntitiesOfType(context, WAR_ENTITY_TYPE_UNIT);
    *count = units->count;
    for (s32 i = 0; i < units->count; i++)
    {
        WarEntity* e = units->items[i];
        WarUnitComponent* u = &e->unit;
        put32(&crc, e->id); put32(&crc, (u32)u->type); put32(&crc, (u32)u->direction);
        put32(&crc, (u32)u->tilex); put32(&crc, (u32)u->tiley); put32(&crc, (u32)u->sizex); put32(&crc, (u32)u->sizey);
        put32(&crc, u->player); put32(&crc, (u32)u->resourceKind); put32(&crc, (u32)u->amount);
        put32(&crc, (u32)u->maxhp); put32(&crc, (u32)u->hp); put32(&crc, (u32)u->maxMana); put32(&crc, (u32)u->mana);
        put32(&crc, (u32)u->armor); put32(&crc, (u32)u->range); put32(&crc, (u32)u->minDamage); put32(&crc, (u32)u->rndDamage);
        put32(&crc, (u32)u->decay); put32(&crc, (u32)u->manaTime); put32(&crc, u->hasBeenSeen);
        put32(&crc, (u32)(e->transform.position.x)); put32(&crc, (u32)(e->transform.position.y));
    }
    return crc ^ 0xFFFFFFFFu;
}

static u32 tilesCrc(WarMap* map, int what)
{
    u32 crc = 0xFFFFFFFFu;
    for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
    {
        u8 b = (u8)(what == 0 ? map->tiles[i].state : what == 1 ? map->tiles[i].type : map->tiles[i].boundary);
        crc = crc_update(crc, &b, 1);
    }
    return crc ^ 0xFFFFFFFFu;
}

static bool slackDirty(WarSpriteFrame* f)
{
    for (s32 i = 0; i < FRAME_SLACK; i++) if (f->data[MINIMAP_WIDTH * MINIMAP_HEIGHT * 4 + i] != 0) return true;
    return false;
}

static WarContext theContext;
static u16* pristineVisual[MAX_RESOURCES_COUNT];

static void loadAll(const char* path)
{
    bool skipDecompress[MAX_RESOURCES_COUNT];
    memset(skipDecompress, 0, sizeof(skipDecompress));
    for (size_t i = 0; i < arrayLength(assets); ++i)
        if (assets[i].type == DB_ENTRY_TYPE_UNKNOWN)
            skipDecompress[assets[i].index] = true;

    theContext.warFile = wfile_loadWarFile(NULL, wsv_fromCString(path), skipDecompress);
    if (!theContext.warFile)
    {
        printf("FAIL\n");
        exit(1);
    }
    theContext.resources = (WarResource*)calloc(MAX_RESOURCES_COUNT, sizeof(WarResource));
    for (int pass = 0; pass < 3; pass++)
        for (size_t i = 0; i < arrayLength(assets); ++i)
        {
            DatabaseEntry entry = assets[i];
            if (pass == 0)
            {
                if (entry.type == DB_ENTRY_TYPE_PALETTE) wres_loadPaletteResource(&theContext, &entry);
                else if (entry.type == DB_ENTRY_TYPE_TILES) wres_loadTiles(&theContext, &entry);
            }
            else if (pass == 1)
            {
                if (entry.type == DB_ENTRY_TYPE_TILESET) wres_loadTileset(&theContext, &entry);
                else if (entry.type == DB_ENTRY_TYPE_LEVEL_INFO) wres_loadLevelInfo(&theContext, &entry);
                else if (entry.type == DB_ENTRY_TYPE_LEVEL_VISUAL) wres_loadLevelVisual(&theContext, &entry);
                else if (entry.type == DB_ENTRY_TYPE_LEVEL_PASSABLE) wres_loadLevelPassable(&theContext, &entry);
            }
        }
    for (int i = 0; i < MAX_RESOURCES_COUNT; i++)
        if (theContext.resources[i].type == WAR_RESOURCE_TYPE_LEVEL_VISUAL)
        {
            pristineVisual[i] = (u16*)malloc(MAP_TILES_WIDTH * MAP_TILES_HEIGHT * 2);
            memcpy(pristineVisual[i], theContext.resources[i].levelVisual.data, MAP_TILES_WIDTH * MAP_TILES_HEIGHT * 2);
        }
}

static void restoreVisual(s32 levelInfoIndex)
{
    WarResource* info = &theContext.resources[levelInfoIndex];
    s32 v = info->levelInfo.visualIndex;
    memcpy(theContext.resources[v].levelVisual.data, pristineVisual[v], MAP_TILES_WIDTH * MAP_TILES_HEIGHT * 2);
}

/* l'originale si ferma con un assert (FIND_BY_TYPE) se il tipo non e' nelle tabelle: lo si rileva prima di entrare */
static s32 unsupportedStartUnit(WarResource* info)
{
    for (u32 i = 0; i < info->levelInfo.startEntitiesCount; i++)
    {
        WarUnitType t = info->levelInfo.startEntities[i].type;
        bool inData = false, inStats = false;
        for (size_t k = 0; k < arrayLength(unitsData); k++) if (unitsData[k].type == t) inData = true;
        if (wu_isBuildingUnitType(t))
        {
            for (size_t k = 0; k < arrayLength(buildingStats); k++) if (buildingStats[k].type == t) inStats = true;
        }
        else
        {
            for (size_t k = 0; k < arrayLength(unitStats); k++) if (unitStats[k].type == t) inStats = true;
        }
        if (!inData || !inStats) return (s32)t;
    }
    return -1;
}

static void dumpMap(s32 index)
{
    WarContext* context = &theContext;
    WarMap* map = context->map;
    WarResource* info = &context->resources[index];
    WarResource* visual = &context->resources[info->levelInfo.visualIndex];
    s32 fc, tc, uc;
    u32 forests = allForestsCrc(context, &fc, &tc);
    u32 crc = 0xFFFFFFFFu;
    printf("M %d %d %d %d %d %d\n", index, map->playersCount, map->custom, map->tilesetType,
           (s32)map->camera.viewport.x, (s32)map->camera.viewport.y);
    for (int p = 0; p < MAX_PLAYERS_COUNT; p++)
    {
        WarPlayerInfo* pl = &map->players[p];
        u32 fcrc = crc32_of((const u8*)pl->features, MAX_FEATURES_COUNT);
        u32 ucrc = crc32_of((const u8*)pl->upgrades, sizeof(pl->upgrades));
        printf("P %d %d %d %d %d %d %08x %08x\n", index, p, pl->index, (s32)pl->race, pl->gold, pl->wood, fcrc, ucrc);
    }
    printf("T %d %d %d %08x\n", index, fc, tc, forests);
    printf("TE %d %u %08x\n", index, (u32)map->editing.forest->id, forestCrc(map->editing.forest));
    crc = 0xFFFFFFFFu;
    WarEntity* road = map->editing.road;
    for (s32 i = 0; i < road->road.pieces.count; i++)
    {
        WarRoadPiece* p = &road->road.pieces.items[i];
        u8 b[4] = { (u8)p->type, (u8)p->tilex, (u8)p->tiley, p->player };
        crc = crc_update(crc, b, 4);
    }
    printf("Q %d %u %d %08x\n", index, (u32)road->id, road->road.pieces.count, crc ^ 0xFFFFFFFFu);
    crc = 0xFFFFFFFFu;
    WarEntity* wall = map->editing.wall;
    for (s32 i = 0; i < wall->wall.pieces.count; i++)
    {
        WarWallPiece* p = &wall->wall.pieces.items[i];
        u8 b[6] = { (u8)p->type, (u8)p->tilex, (u8)p->tiley, p->player, (u8)p->hp, (u8)p->maxhp };
        crc = crc_update(crc, b, 6);
    }
    printf("W %d %u %d %08x\n", index, (u32)wall->id, wall->wall.pieces.count, crc ^ 0xFFFFFFFFu);
    printf("R %d %u %d\n", index, (u32)map->editing.ruin->id, map->editing.ruin->ruin.pieces.count);
    u32 units = unitsCrc(context, &uc);
    printf("N %d %d %08x %u\n", index, uc, units, map->nextEntityId);
    printf("H %d %08x\n", index, crc32_of((const u8*)map->finder.data, sizeof(map->finder.data)));
    printf("S %d %08x\n", index, tilesCrc(map, 0));
    printf("V %d %08x\n", index, crc32_of((const u8*)visual->levelVisual.data, MAP_TILES_WIDTH * MAP_TILES_HEIGHT * 2));
    printf("I %d %08x %08x\n", index,
           crc32_of(map->minimapSprite.frames[0].data, MINIMAP_WIDTH * MINIMAP_HEIGHT * 4),
           crc32_of(map->minimapSprite.frames[1].data, MINIMAP_WIDTH * MINIMAP_HEIGHT * 4));
}

static void dumpFog(s32 index)
{
    WarMap* map = theContext.map;
    s32 visible = 0, fog = 0, unknown = 0;
    for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
    {
        if (map->tiles[i].state == MAP_TILE_STATE_VISIBLE) visible++;
        else if (map->tiles[i].state == MAP_TILE_STATE_FOG) fog++;
        else unknown++;
    }
    printf("F %d %d %d %d %08x %08x %08x\n", index, visible, fog, unknown, tilesCrc(map, 0), tilesCrc(map, 1), tilesCrc(map, 2));
}

static void dumpMinimap(s32 index, const char* tag)
{
    WarMap* map = theContext.map;
    printf("%s %d %08x %d\n", tag, index, crc32_of(map->minimapSprite.frames[0].data, MINIMAP_WIDTH * MINIMAP_HEIGHT * 4),
           slackDirty(&map->minimapSprite.frames[0]));
}

static void runMaps(const char* path)
{
    loadAll(path);
    for (size_t i = 0; i < arrayLength(assets); ++i)
    {
        if (assets[i].type != DB_ENTRY_TYPE_LEVEL_INFO) continue;
        s32 index = assets[i].index;
        WarResource* info = &theContext.resources[index];
        if (info->type != WAR_RESOURCE_TYPE_LEVEL_INFO) continue;
        if (theContext.resources[info->levelInfo.tilesetIndex].type != WAR_RESOURCE_TYPE_TILESET) continue;
        restoreVisual(index);
        s32 bad = unsupportedStartUnit(info);
        if (bad >= 0)
        {
            printf("Z %d %d\n", index, bad);
            continue;
        }
        enterMap(&theContext, index);
        dumpMap(index);
        /* il primo aggiornamento del fog: le unita' del giocatore vedono */
        updateFoW(&theContext);
        determineFoWTypes(&theContext);
        dumpFog(index);
        composeMinimap(&theContext);
        dumpMinimap(index, "B");
        theContext.map->fowEnabled = false;
        composeMinimap(&theContext);
        dumpMinimap(index, "b");
    }
}

static void runTrees(const char* path)
{
    loadAll(path);
    s32 levels[128];
    s32 levelCount = 0;
    for (size_t i = 0; i < arrayLength(assets); ++i)
    {
        if (assets[i].type != DB_ENTRY_TYPE_LEVEL_INFO) continue;
        WarResource* info = &theContext.resources[assets[i].index];
        if (info->type != WAR_RESOURCE_TYPE_LEVEL_INFO) continue;
        if (theContext.resources[info->levelInfo.tilesetIndex].type != WAR_RESOURCE_TYPE_TILESET) continue;
        if (unsupportedStartUnit(info) >= 0) continue;
        levels[levelCount++] = assets[i].index;
    }
    for (int s = 0; s < 60; s++)
    {
        rngSeed(7000 + (u32)s);
        s32 index = levels[s % levelCount];
        restoreVisual(index);
        enterMap(&theContext, index);
        WarContext* context = &theContext;
        WarMap* map = context->map;
        updateFoW(context);
        determineFoWTypes(context);
        printf("X %d %d\n", s, index);
        int ops = 6 + rngRange(10);
        for (int k = 0; k < ops; k++)
        {
            int op = rngRange(4);
            WarEntityList* forests = we_getEntitiesOfType(context, WAR_ENTITY_TYPE_FOREST);
            s32 fc, tc;
            if (op == 0)
            {
                /* piantare: sul bosco di modifica, vicino a un albero o a caso */
                s32 x = rngRange(MAP_TILES_WIDTH);
                s32 y = rngRange(MAP_TILES_HEIGHT);
                if (rngRange(2) == 0 && forests->count > 0)
                {
                    WarEntity* f = forests->items[rngRange(forests->count)];
                    if (f->forest.trees.count > 0)
                    {
                        WarTree* t = &f->forest.trees.items[rngRange(f->forest.trees.count)];
                        s32 dx = rngRange(5) - 2;
                        s32 dy = rngRange(5) - 2;
                        x = CLAMP(t->tilex + dx, 0, MAP_TILES_WIDTH - 1);
                        y = CLAMP(t->tiley + dy, 0, MAP_TILES_HEIGHT - 1);
                    }
                }
                we_plantTree(context, map->editing.forest, x, y);
                we_determineTreeTiles(context, map->editing.forest);
                printf("t %d %d P %d %d", s, k, x, y);
            }
            else if (op == 1 || op == 2)
            {
                WarEntity* f = forests->items[rngRange(forests->count)];
                s32 amount = rngRange(2) == 0 ? 100 + rngRange(21) : 1 + rngRange(60);   /* la meta' abbatte l'albero */
                if (f->forest.trees.count == 0)
                {
                    printf("t %d %d C empty", s, k);
                }
                else
                {
                    s32 ti = rngRange(f->forest.trees.count);
                    WarTree* t = &f->forest.trees.items[ti];
                    s32 tx = t->tilex, ty = t->tiley;
                    s32 got = we_chopTree(context, f, t, amount);
                    printf("t %d %d C %d %d %d %d", s, k, tx, ty, amount, got);
                }
            }
            else
            {
                WarEntity* f = forests->items[rngRange(forests->count)];
                s32 x = rngRange(MAP_TILES_WIDTH);
                s32 y = rngRange(MAP_TILES_HEIGHT);
                if (f->forest.trees.count > 0 && rngRange(3) != 0)
                {
                    WarTree* t = &f->forest.trees.items[rngRange(f->forest.trees.count)];
                    x = t->tilex;
                    y = t->tiley;
                }
                WarEntityList* units = we_getEntitiesOfType(context, WAR_ENTITY_TYPE_UNIT);
                if (units->count > 0 && f->forest.trees.count > 0 && rngRange(2) == 0)
                {
                    /* l'albero del bosco piu' vicino alla prima unita': e' quello che si vede */
                    WarEntity* u = units->items[0];
                    s32 best = 0x7FFFFFFF;
                    for (s32 i = 0; i < f->forest.trees.count; i++)
                    {
                        s32 ddx = f->forest.trees.items[i].tilex - u->unit.tilex;
                        s32 ddy = f->forest.trees.items[i].tiley - u->unit.tiley;
                        if (ddx * ddx + ddy * ddy < best)
                        {
                            best = ddx * ddx + ddy * ddy;
                            x = f->forest.trees.items[i].tilex;
                            y = f->forest.trees.items[i].tiley;
                        }
                    }
                }
                WarTree* r = we_findAccesibleTree(context, f, vec2i(x, y));
                printf("t %d %d A %d %d %d %d %d", s, k, x, y, r ? r->tilex : -1, r ? r->tiley : -1, r ? r->amount : -1);
            }
            u32 forestsCrc = allForestsCrc(context, &fc, &tc);
            WarResource* visual = &context->resources[context->resources[index].levelInfo.visualIndex];
            printf(" | %d %d %08x %08x %08x %08x %08x\n", fc, tc, forestsCrc, forestCrc(map->editing.forest),
                   crc32_of((const u8*)map->finder.data, sizeof(map->finder.data)),
                   crc32_of((const u8*)visual->levelVisual.data, MAP_TILES_WIDTH * MAP_TILES_HEIGHT * 2),
                   crc32_of(map->minimapSprite.frames[1].data, MINIMAP_WIDTH * MINIMAP_HEIGHT * 4));
        }
    }
}

static void runTables(void)
{
    for (size_t i = 0; i < arrayLength(unitsData); i++)
        printf("D %d %d %d %d\n", unitsData[i].type, unitsData[i].resourceIndex, unitsData[i].sizex, unitsData[i].sizey);
    for (size_t i = 0; i < arrayLength(unitStats); i++)
    {
        const WarUnitStats* u = &unitStats[i];
        printf("S %d %d %d %d %d %d %d %d %d\n", u->type, u->range, u->sight, u->armor, u->hp, u->mana, u->minDamage, u->rndDamage, u->decay);
    }
    for (size_t i = 0; i < arrayLength(buildingStats); i++)
    {
        const WarBuildingStats* b = &buildingStats[i];
        printf("B %d %d %d %d\n", b->type, b->armor, b->sight, b->hp);
    }
}

int main(int argc, char** argv)
{
    if (argc < 3)
    {
        printf("uso: war_map_ref DATA.WAR maps|trees|tables\n");
        return 2;
    }
    crc_init();
    if (strcmp(argv[2], "maps") == 0) runMaps(argv[1]);
    else if (strcmp(argv[2], "trees") == 0) runTrees(argv[1]);
    else if (strcmp(argv[2], "tables") == 0) runTables();
    else return 2;
    return 0;
}
