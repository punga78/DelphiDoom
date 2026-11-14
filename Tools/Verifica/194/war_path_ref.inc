/*
  Issue #195: percorsi, evitamento tra unita' e nebbia di guerra (incluso da war_model_ref.c dopo war_full_ref.inc).

  Il codice del remake e' l'ORIGINALE: war_pathfinder.c (wpath_astar, wpath_flowField, wpath_computeFlowField,
  wpath_ensureFlowField, wpath_flowFieldSample), war_rvo.c (wrvo_computeNewVelocity, wrvo_gatherNeighbours), updateFoW e
  determineFoWTypes di war_map.c, e gli stati che li usano. Questo file e' nostro: gli scenari, le righe di testo e gli
  interruttori che accendono le funzioni vere al posto degli stub della #194 (gRealPaths: campi di flusso e vicini
  dell'evitamento; gRealFog: nebbia di guerra a ogni tic, come in wmap_updateMap dopo updateSpells).

  Comandi (vedi main): paths, rvo, move, real combat|commands|spells|full, dump paths|rvo|move ..., benchmove.
*/

/* ------------------------------------------------------------------------------------------------------------------ */
/* l'impronta dei campi di flusso e della nebbia                                                                       */
/* ------------------------------------------------------------------------------------------------------------------ */

static void mixField(WarMapFlowField* field, s32 index)
{
    u32 h = 2166136261u;
    for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
    {
        h ^= (u32)field->cost[i];
        h *= 16777619u;
    }
    for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
    {
        h ^= (u32)field->dirs[i];
        h *= 16777619u;
    }
    gFieldMix = (gFieldMix ^ (u32)index) * 16777619u;
    gFieldMix = (gFieldMix ^ h) * 16777619u;
    gFieldComputes++;
}

/* le funzioni vere con l'impronta di ogni campo calcolato (in ordine): sostituiscono quelle di sopra quando gRealPaths e' acceso */
static WarMapFlowField* realComputeFlowField(WarPathFinder* finder, s32 x, s32 y)
{
    WarMapFlowField* field = wpath_computeFlowField_orig(finder, x, y);
    if (field)
        mixField(field, y * MAP_TILES_WIDTH + x);
    return field;
}

static WarMapFlowField* realEnsureFlowField(WarPathFinder* finder, s32 x, s32 y)
{
    s32 index = y * MAP_TILES_WIDTH + x;
    bool had = index >= 0 && index < MAP_TILES_WIDTH * MAP_TILES_HEIGHT && finder->fields[index] != NULL;
    WarMapFlowField* field = wpath_ensureFlowField_orig(finder, x, y);
    if (field && !had)
        mixField(field, index);
    return field;
}

static void dumpReal(Text* t)
{
    if (gRealPaths)
    {
        s32 n = 0;
        for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
            if (gMap->finder.fields[i])
                n++;
        textAdd(t, "PF c=%u mix=%08x n=%d\n", gFieldComputes, gFieldMix, n);
    }
    if (gRealFog)
    {
        s32 unknown = 0, fog = 0, visible = 0;
        u32 h = 2166136261u;
        for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
        {
            WarMapTile* tile = &gMap->tiles[i];
            if (tile->state == MAP_TILE_STATE_UNKNOWN) unknown++;
            else if (tile->state == MAP_TILE_STATE_FOG) fog++;
            else if (tile->state == MAP_TILE_STATE_VISIBLE) visible++;
            h = (h ^ (u32)tile->state) * 16777619u;
            h = (h ^ (u32)tile->type) * 16777619u;
            h = (h ^ (u32)tile->boundary) * 16777619u;
        }
        textAdd(t, "FG v=%d f=%d u=%d h=%08x\n", visible, fog, unknown, h);
    }
}

/* wmap_updateMap: la nebbia sta alla fine del tic, dopo updateSpells */
static void realFogUpdate(void)
{
    if (!gRealFog)
        return;
    updateFoW(gContext);
    determineFoWTypes(gContext);
}

/* le caselle di una mappa con la nebbia: tutte sconosciute, come all'ingresso nella mappa */
static void realWorldSetup(void)
{
    gRealPaths = 1;
    gRealFog = 1;
    gFieldComputes = 0;
    gFieldMix = 2166136261u;
    wgrid_clear(gContext);
    for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
    {
        gMap->tiles[i].state = MAP_TILE_STATE_UNKNOWN;
        gMap->tiles[i].type = WAR_FOG_PIECE_NONE;
        gMap->tiles[i].boundary = WAR_FOG_BOUNDARY_NONE;
    }
    gMap->fowEnabled = true;
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* le mappe sintetiche                                                                                                 */
/* ------------------------------------------------------------------------------------------------------------------ */

/* il tipo di mappa dipende dal seme: rumore (varie densita'), rettangoli, stanze con porte, campo libero (tutti pari), anello chiuso
   attorno a un punto (irraggiungibile: i candidati a pari distanza decidono) */
static void pathPassable(u32 kind, u16 passable[MAP_TILES_WIDTH * MAP_TILES_HEIGHT], s32* ringX, s32* ringY)
{
    memset(passable, 0, sizeof(u16) * MAP_TILES_WIDTH * MAP_TILES_HEIGHT);
    *ringX = -1;
    *ringY = -1;
    switch (kind % 6)
    {
        case 0: /* rumore */
        {
            u32 density = 4 + scriptBelow(36);
            for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
                if (scriptBelow(100) < density)
                    passable[i] = scriptBelow(2) ? 128 : 64;
            break;
        }
        case 1: /* rettangoli */
        {
            u32 n = 4 + scriptBelow(8);
            for (u32 r = 0; r < n; r++)
            {
                s32 w = 1 + (s32)scriptBelow(14), h = 1 + (s32)scriptBelow(14);
                s32 x = (s32)scriptBelow(MAP_TILES_WIDTH), y = (s32)scriptBelow(MAP_TILES_HEIGHT);
                for (s32 yy = y; yy < y + h && yy < MAP_TILES_HEIGHT; yy++)
                    for (s32 xx = x; xx < x + w && xx < MAP_TILES_WIDTH; xx++)
                        passable[yy * MAP_TILES_WIDTH + xx] = 128;
            }
            break;
        }
        case 2: /* stanze: pareti ogni 16 caselle con una porta a caso */
        {
            for (s32 k = 16; k < MAP_TILES_WIDTH; k += 16)
            {
                s32 doorV = (s32)scriptBelow(MAP_TILES_HEIGHT - 3), doorH = (s32)scriptBelow(MAP_TILES_WIDTH - 3);
                for (s32 i = 0; i < MAP_TILES_WIDTH; i++)
                {
                    if (i < doorV || i >= doorV + 3)
                        passable[i * MAP_TILES_WIDTH + k] = 128;
                    if (i < doorH || i >= doorH + 3)
                        passable[k * MAP_TILES_WIDTH + i] = 64;
                }
            }
            break;
        }
        case 3: /* campo libero */
            break;
        case 4: /* rumore leggero e un anello chiuso */
        {
            for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
                if (scriptBelow(100) < 6)
                    passable[i] = 128;
            s32 cx = 8 + (s32)scriptBelow(MAP_TILES_WIDTH - 16), cy = 8 + (s32)scriptBelow(MAP_TILES_HEIGHT - 16);
            s32 radius = 2 + (s32)scriptBelow(4);
            for (s32 y = cy - radius; y <= cy + radius; y++)
                for (s32 x = cx - radius; x <= cx + radius; x++)
                    if (x == cx - radius || x == cx + radius || y == cy - radius || y == cy + radius)
                        passable[y * MAP_TILES_WIDTH + x] = 128;
            *ringX = cx;
            *ringY = cy;
            break;
        }
        default: /* una striscia con una sola apertura stretta */
        {
            s32 y = 20 + (s32)scriptBelow(24);
            s32 gap = (s32)scriptBelow(MAP_TILES_WIDTH);
            for (s32 x = 0; x < MAP_TILES_WIDTH; x++)
                if (x != gap)
                    passable[y * MAP_TILES_WIDTH + x] = 128;
            break;
        }
    }
}

static u32 pathHashNodes(const WarMapPath* path)
{
    u32 h = 2166136261u;
    for (s32 i = 0; i < path->count; i++)
    {
        h = (h ^ (u32)(s32)path->nodes[i].x) * 16777619u;
        h = (h ^ (u32)(s32)path->nodes[i].y) * 16777619u;
    }
    return h;
}

static WarMapPath gPathResult;

/* ------------------------------------------------------------------------------------------------------------------ */
/* paths: A star e campi di flusso su mappe sintetiche (le funzioni pure)                                             */
/* ------------------------------------------------------------------------------------------------------------------ */

#define PATH_ASTARS 20
#define PATH_FIELDS 6
#define PATH_SAMPLES 4

static void pathScenarioInit(u32 seed, s32* ringX, s32* ringY)
{
    gScriptState = seed * 2654435761u + 5150u;
    gRealPaths = 1;
    wm_allocInit(256ull * 1024 * 1024, 8ull * 1024 * 1024, 1ull * 1024 * 1024);
    u16 passable[MAP_TILES_WIDTH * MAP_TILES_HEIGHT];
    pathPassable(seed, passable, ringX, ringY);
    gMap = (WarMap*)wm_alloc(sizeof(WarMap));
    memset(gMap, 0, sizeof(WarMap));
    gMap->finder = wpath_initPathFinder(passable);
    /* qualche rettangolo occupato da un'entita' fissa (un edificio, un'unita' ferma) */
    u32 blocks = scriptBelow(4);
    for (u32 b = 0; b < blocks; b++)
    {
        s32 bx = (s32)scriptBelow(MAP_TILES_WIDTH);
        s32 by = (s32)scriptBelow(MAP_TILES_HEIGHT);
        s32 bw = 1 + (s32)scriptBelow(5);
        s32 bh = 1 + (s32)scriptBelow(5);
        WarEntityId bid = (WarEntityId)(1 + scriptBelow(1000));
        wpath_setStaticEntity(&gMap->finder, bx, by, bw, bh, bid);
    }
}

static void pathPoint(s32 ringX, s32 ringY, s32* x, s32* y)
{
    if (ringX >= 0 && scriptBelow(3) == 0)
    {
        /* dentro l'anello (irraggiungibile) o attorno */
        *x = ringX + (s32)scriptBelow(3) - 1;
        *y = ringY + (s32)scriptBelow(3) - 1;
        return;
    }
    *x = (s32)scriptBelow(MAP_TILES_WIDTH);
    *y = (s32)scriptBelow(MAP_TILES_HEIGHT);
}

static void runPaths(u32 seed, s32 dumpIndex)
{
    s32 ringX, ringY;
    pathScenarioInit(seed, &ringX, &ringY);
    WarPathFinder* finder = &gMap->finder;
    for (s32 i = 0; i < PATH_ASTARS; i++)
    {
        s32 sx, sy, ex, ey;
        pathPoint(ringX, ringY, &sx, &sy);
        pathPoint(ringX, ringY, &ex, &ey);
        /* una coppia su due ha l'arrivo accanto alla partenza o uguale (percorsi cortissimi e il percorso di un solo punto) */
        if (scriptBelow(8) == 0)
        {
            ex = sx;
            ey = sy;
        }
        memset(&gPathResult, 0, sizeof(gPathResult));
        wpath_astar(finder, sx, sy, ex, ey, &gPathResult);
        if (dumpIndex == i)
        {
            printf("A %u %d %d,%d -> %d,%d count=%d\n", seed, i, sx, sy, ex, ey, gPathResult.count);
            for (s32 k = 0; k < gPathResult.count; k++)
                printf("  %d,%d\n", (s32)gPathResult.nodes[k].x, (s32)gPathResult.nodes[k].y);
        }
        else if (dumpIndex < 0)
            printf("A %u %d %d,%d,%d,%d n=%d h=%08x\n", seed, i, sx, sy, ex, ey, gPathResult.count, pathHashNodes(&gPathResult));
    }
    for (s32 j = 0; j < PATH_FIELDS; j++)
    {
        s32 gx, gy;
        pathPoint(ringX, ringY, &gx, &gy);
        WarMapFlowField* field = wpath_computeFlowField(finder, gx, gy);
        u32 hc = 2166136261u, hd = 2166136261u;
        s32 reach = 0, maxCost = 0;
        for (s32 k = 0; k < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; k++)
        {
            hc = (hc ^ (u32)field->cost[k]) * 16777619u;
            hd = (hd ^ (u32)field->dirs[k]) * 16777619u;
            if (field->dirs[k] < WAR_DIRECTION_COUNT)
            {
                reach++;
                if (field->cost[k] > maxCost)
                    maxCost = field->cost[k];
            }
        }
        if (dumpIndex == PATH_ASTARS + j)
        {
            printf("F %u %d goal %d,%d reach=%d\n", seed, j, gx, gy, reach);
            for (s32 y = 0; y < MAP_TILES_HEIGHT; y++)
            {
                for (s32 x = 0; x < MAP_TILES_WIDTH; x++)
                    printf("%d", (s32)field->dirs[y * MAP_TILES_WIDTH + x]);
                printf("\n");
            }
        }
        else if (dumpIndex < 0)
        {
            printf("F %u %d %d,%d reach=%d max=%d c=%08x d=%08x s=", seed, j, gx, gy, reach, maxCost, hc, hd);
            for (s32 s = 0; s < PATH_SAMPLES; s++)
            {
                s32 sx = (s32)scriptBelow(MAP_TILES_WIDTH), sy = (s32)scriptBelow(MAP_TILES_HEIGHT);
                vec2 v = wpath_flowFieldSample(field, sx, sy);
                printf("%08x,%08x;", fbits(v.x), fbits(v.y));
            }
            printf("\n");
        }
        else
            for (s32 s = 0; s < PATH_SAMPLES; s++)
            {
                scriptBelow(MAP_TILES_WIDTH);
                scriptBelow(MAP_TILES_HEIGHT);
            }
    }
    wm_allocFree();
    gMap = NULL;
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* rvo: la scelta della velocita' (la funzione pura)                                                                   */
/* ------------------------------------------------------------------------------------------------------------------ */

#define RVO_CASES 120

/* tutti i numeri generati sono multipli di 1/16: esatti in 32 bit, il generatore e' identico in Delphi */
static f32 rvoNumber(s32 range)
{
    return (f32)((s32)scriptBelow((u32)(2 * range * 16 + 1)) - range * 16) / 16.0f;
}

static void runRvo(u32 seed, s32 dumpIndex)
{
    gScriptState = seed * 2654435761u + 777u;
    for (s32 i = 0; i < RVO_CASES; i++)
    {
        f32 maxSpeed = (f32)(6 + scriptBelow(40));
        f32 radiusA = scriptBelow(2) ? (f32)MEGA_TILE_WIDTH * 0.45f : (f32)MEGA_TILE_WIDTH * 0.60f;
        f32 ax = rvoNumber(60);
        f32 ay = rvoNumber(60);
        vec2 posA = vec2f(ax + 400.0f, ay + 400.0f);
        f32 vx = rvoNumber(20);
        f32 vy = rvoNumber(20);
        vec2 velA = vec2f(vx * 0.5f, vy * 0.5f);
        vec2 preferred;
        u32 mode = scriptBelow(6);
        if (mode == 0)
            preferred = vec2f(0.0f, 0.0f);
        else if (mode == 1)
        {
            f32 px = rvoNumber(2);
            f32 py = rvoNumber(2);
            preferred = vec2f(px * 0.0625f, py * 0.0625f);
        }
        else
        {
            f32 px = rvoNumber(40);
            f32 py = rvoNumber(40);
            preferred = vec2f(px, py);
        }
        s32 n = (s32)scriptBelow(RVO_MAX_NB + 1);
        WarRvoNeighbour nb[RVO_MAX_NB];
        for (s32 k = 0; k < n; k++)
        {
            f32 dx = rvoNumber(40);
            f32 dy = rvoNumber(40);
            f32 ux = rvoNumber(20);
            f32 uy = rvoNumber(20);
            nb[k].position = vec2f(posA.x + dx, posA.y + dy);
            nb[k].velocity = vec2f(ux, uy);
            nb[k].radius = (f32)MEGA_TILE_WIDTH * 0.45f;
        }
        vec2 cand[RVO_MAX_CANDIDATES];
        s32 num = 0, best = 0;
        bool had[RVO_MAX_CANDIDATES] = { 0 };
        vec2 r = wrvo_computeNewVelocity(preferred, posA, velA, radiusA, maxSpeed, 1.0f / 60.0f, nb, n, cand, &num, &best, had);
        u64 mask = 0;
        u32 h = 2166136261u;
        for (s32 k = 0; k < num; k++)
        {
            if (had[k])
                mask |= 1ull << k;
            h = (h ^ fbits(cand[k].x)) * 16777619u;
            h = (h ^ fbits(cand[k].y)) * 16777619u;
        }
        if (dumpIndex == i)
        {
            printf("R %u %d n=%d best=%d r=%08x,%08x mask=%llx\n", seed, i, n, best, fbits(r.x), fbits(r.y), (unsigned long long)mask);
            for (s32 k = 0; k < num; k++)
                printf("  %d %08x,%08x %d\n", k, fbits(cand[k].x), fbits(cand[k].y), had[k] ? 1 : 0);
        }
        else if (dumpIndex < 0)
            printf("R %u %d n=%d best=%d r=%08x,%08x mask=%llx h=%08x\n", seed, i, n, best, fbits(r.x), fbits(r.y),
                   (unsigned long long)mask, h);
    }
}

/* i 32 candidati degli anelli (coseno e seno a 32 bit) con velocita' massima 1: gli angoli non dipendono dalla velocita' */
static void printRvoTables(void)
{
    vec2 cand[RVO_MAX_CANDIDATES];
    s32 num = 0, best = 0;
    wrvo_computeNewVelocity(vec2f(0.0f, 0.0f), vec2f(0.0f, 0.0f), vec2f(0.0f, 0.0f), 7.2f, 1.0f, 1.0f / 60.0f, NULL, 0, cand, &num, &best, NULL);
    printf("# anelli: T indice cosf sinf (bit); velocita' massima 1\n");
    for (s32 k = 0; k < RVO_RING_N; k++)
        printf("T %d %08x %08x\n", k, fbits(cand[1 + k].x), fbits(cand[1 + k].y));
    printf("# costanti: K maxNeighbours ringN candidates horizon collisionW deviationW (bit)\n");
    printf("K %d %d %d %08x %08x %08x\n", RVO_MAX_NB, RVO_RING_N, RVO_MAX_CANDIDATES, fbits(RVO_TIME_HORIZON), fbits(RVO_COLLISION_W),
           fbits(RVO_DEVIATION_W));
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* move: gruppi di unita' che si incrociano su una mappa con ostacoli (il tic intero, la nebbia, i campi di flusso)    */
/* ------------------------------------------------------------------------------------------------------------------ */

static const WarUnitType kMovePool[14] = {
    WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_PEASANT, WAR_UNIT_PEON, WAR_UNIT_ARCHER, WAR_UNIT_KNIGHT, WAR_UNIT_CATAPULT_ORCS,
    WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CONJURER, WAR_UNIT_OGRE, WAR_UNIT_SPIDER, WAR_UNIT_SKELETON, WAR_UNIT_CLERIC, WAR_UNIT_WARLOCK
};
static const f32 kMoveDeltas[4] = { 1.0f / 60.0f, 1.0f / 30.0f, 0.1f, 0.25f };
#define MOVE_TICS 600
static f32 gMoveDelta;
static s32 gMoveTic;

static vec2 moveTilePoint(s32 x, s32 y)
{
    return vec2f((f32)(x * MEGA_TILE_WIDTH + MINI_TILE_WIDTH), (f32)(y * MEGA_TILE_HEIGHT + MINI_TILE_HEIGHT));
}

static void moveOrder(WarEntity* e, s32 tx, s32 ty, bool via, s32 mx, s32 my, bool check)
{
    vec2 positions[3];
    s32 n = 0;
    positions[n++] = wu_getUnitCenterPosition(gContext, e);
    if (via)
        positions[n++] = moveTilePoint(mx, my);
    positions[n++] = moveTilePoint(tx, ty);
    WarStateMove* state = wst_createMoveState(gContext, e, n, positions, check);
    wst_resetState(gContext, e, (WarStateBase*)state, WAR_TRANSITION_CAUSE_PLAYER_ORDER);
}

static void moveScriptStep(void)
{
    /* il tic 0 da' gli ordini a tutti, poi un ordine ogni tanto: nuove mete, fermate, ritardi, danni */
    if (gMoveTic == 0)
    {
        for (s32 i = 0; i < gSpawnedCount; i++)
        {
            WarEntity* e = we_findEntity(gContext, gSpawned[i]);
            if (!e || !wu_isDudeUnit(gContext, e))
                continue;
            WarUnitComponent* unit = we_getUnitComponent(gContext, e);
            bool left = unit->player == 0;
            s32 tx = (left ? 38 : 4) + (s32)scriptBelow(22);
            s32 ty = 4 + (s32)scriptBelow(56);
            bool via = scriptBelow(3) == 0;
            s32 mx = 4 + (s32)scriptBelow(56), my = 4 + (s32)scriptBelow(56);
            bool check = scriptBelow(2) == 0;
            moveOrder(e, tx, ty, via, mx, my, check);
        }
        return;
    }
    if (scriptBelow(6) != 0)
        return;
    u32 index = scriptBelow(gSpawnedCount > 0 ? (u32)gSpawnedCount : 1u);
    u32 op = scriptBelow(100);
    s32 tx = (s32)scriptBelow(MAP_TILES_WIDTH), ty = (s32)scriptBelow(MAP_TILES_HEIGHT);
    bool via = scriptBelow(3) == 0;
    s32 mx = (s32)scriptBelow(MAP_TILES_WIDTH), my = (s32)scriptBelow(MAP_TILES_HEIGHT);
    bool check = scriptBelow(2) == 0;
    s32 damage = (s32)scriptBelow(60);
    if (gSpawnedCount == 0)
        return;
    WarEntity* e = we_findEntity(gContext, gSpawned[index]);
    if (!e || !wu_isDudeUnit(gContext, e) || wst_isDead(gContext, e) || wst_isGoingToDie(gContext, e))
        return;
    if (op < 70)
        moveOrder(e, tx, ty, via, mx, my, check);
    else if (op < 82)
        wst_popState(gContext, e, WAR_TRANSITION_CAUSE_PLAYER_ORDER, WAR_STATE_RESULT_SUCCESS);
    else if (op < 92)
    {
        WarStateWait* state = wst_createWaitState(gContext, e, 1.0f + (f32)(damage % 5) * 0.5f);
        wst_pushState(gContext, e, (WarStateBase*)state, WAR_TRANSITION_CAUSE_AI_ORDER);
    }
    else
        we_takeDamage(gContext, e, 1, damage);
}

static void moveInit(u32 seed)
{
    worldInit(seed ^ 0xD1D1D1D1u, seed * 2654435761u + 31337u);
    realWorldSetup();
    gExtended = 1;
    gMoveDelta = kMoveDeltas[seed % 4];
    gSpawnedCount = 0;
    s32 ringX, ringY;
    u16 passable[MAP_TILES_WIDTH * MAP_TILES_HEIGHT];
    /* mappa con ostacoli di una densita' limitata (i tipi del seme: rumore, rettangoli, stanze, campo libero, striscia) */
    u32 kind = seed % 6;
    if (kind == 4)
        kind = 0;
    pathPassable(kind, passable, &ringX, &ringY);
    /* le zone di partenza libere */
    for (s32 y = 0; y < MAP_TILES_HEIGHT; y++)
        for (s32 x = 0; x < 24; x++)
        {
            passable[y * MAP_TILES_WIDTH + x] = 0;
            passable[y * MAP_TILES_WIDTH + (MAP_TILES_WIDTH - 1 - x)] = 0;
        }
    gMap->finder = wpath_initPathFinder(passable);
    gMap->ui.mapPanel = rectf(0, 0, 1024, 1024);
    gMap->camera.viewport = rectf(0, 0, 320, 200);
    s32 count = 14 + (s32)scriptBelow(14);
    for (s32 i = 0; i < count; i++)
    {
        u8 player = (u8)(i % 2);
        WarUnitType type = kMovePool[scriptBelow(14)];
        s32 x = (player == 0 ? 2 : 41) + (s32)scriptBelow(20);
        s32 y = 3 + (s32)scriptBelow(58);
        if (wpath_isEmpty(&gMap->finder, x, y))
            spawnDude(type, player, x, y);
    }
    /* qualche edificio come ostacolo (anche tra i gruppi) */
    for (u32 b = 0; b < 3; b++)
    {
        s32 bx = 26 + (s32)scriptBelow(10);
        s32 by = 5 + (s32)scriptBelow(50);
        spawnBuilding(WAR_UNIT_FARM_HUMANS, 0, bx, by);
    }
    gFullDump = 0;
}

static void runMove(u32 seed, s32 dumpTic, bool perTic)
{
    moveInit(seed);
    for (s32 tic = 0; tic < MOVE_TICS; tic++)
    {
        gMoveTic = tic;
        tickFull(moveScriptStep, gMoveDelta);
        Text text = {0};
        if (perTic || tic == dumpTic)
            dumpWorld(&text, tic);
        if (dumpTic >= 0 && tic == dumpTic)
            printf("%s", text.data);
        else if (perTic)
            printf("M %u %d %08x %d\n", seed, tic, fnv1a(text.data, text.length), gMap->entityManager.entityCount);
        free(text.data);
    }
    gExtended = 0;
    worldFree();
}

/* il costo di una ricerca (per confrontarlo con Delphi: DELPHIDOOM_WAR_BENCH_PATH): A star e campi di flusso su 20 mappe */
static void benchPaths(s32 rounds)
{
    long long freq, t0, t1;
    QueryPerformanceFrequency(&freq);
    double astarTime = 0, fieldTime = 0;
    s32 astars = 0, fields = 0;
    u32 sum = 0;
    for (s32 r = 0; r < rounds; r++)
        for (u32 seed = 1; seed <= 20; seed++)
        {
            s32 ringX, ringY;
            pathScenarioInit(seed, &ringX, &ringY);
            for (s32 i = 0; i < 10; i++)
            {
                s32 sx = (s32)scriptBelow(MAP_TILES_WIDTH), sy = (s32)scriptBelow(MAP_TILES_HEIGHT);
                s32 ex = (s32)scriptBelow(MAP_TILES_WIDTH), ey = (s32)scriptBelow(MAP_TILES_HEIGHT);
                memset(&gPathResult, 0, sizeof(gPathResult));
                QueryPerformanceCounter(&t0);
                wpath_astar(&gMap->finder, sx, sy, ex, ey, &gPathResult);
                QueryPerformanceCounter(&t1);
                astarTime += (double)(t1 - t0) / (double)freq;
                astars++;
                sum += (u32)gPathResult.count;
            }
            for (s32 i = 0; i < 4; i++)
            {
                s32 gx = (s32)scriptBelow(MAP_TILES_WIDTH), gy = (s32)scriptBelow(MAP_TILES_HEIGHT);
                QueryPerformanceCounter(&t0);
                WarMapFlowField* f = wpath_computeFlowField_orig(&gMap->finder, gx, gy);
                QueryPerformanceCounter(&t1);
                fieldTime += (double)(t1 - t0) / (double)freq;
                fields++;
                sum += (u32)f->cost[0];
            }
            wm_allocFree();
            gMap = NULL;
        }
    printf("C A star: %d ricerche, %.1f us per ricerca; campi di flusso: %d, %.1f us per campo (somma di controllo %u)\n", astars,
           1e6 * astarTime / astars, fields, 1e6 * fieldTime / fields, sum);
}

/* il costo del movimento per unita' e per tic: 200 unita' che attraversano la mappa con ostacoli, il tic intero senza il resto */
static void benchMove(s32 units, s32 tics)
{
    long long freq, t0, t1;
    QueryPerformanceFrequency(&freq);
    worldInit(12345, 678);
    realWorldSetup();
    gSpawnedCount = 0;
    u16 passable[MAP_TILES_WIDTH * MAP_TILES_HEIGHT];
    s32 ringX, ringY;
    gScriptState = 4242;
    pathPassable(0, passable, &ringX, &ringY);
    for (s32 y = 0; y < MAP_TILES_HEIGHT; y++)
        for (s32 x = 0; x < 6; x++)
        {
            passable[y * MAP_TILES_WIDTH + x] = 0;
            passable[y * MAP_TILES_WIDTH + (MAP_TILES_WIDTH - 1 - x)] = 0;
        }
    gMap->finder = wpath_initPathFinder(passable);
    for (s32 i = 0; i < units; i++)
        if (!spawnDude(WAR_UNIT_FOOTMAN, 0, 1 + (i % 4), 1 + (i / 4) % 62))
            break;
    for (s32 i = 0; i < gSpawnedCount; i++)
    {
        WarEntity* e = we_findEntity(gContext, gSpawned[i]);
        if (e)
            moveOrder(e, 58 + (i % 4), 1 + (i / 4) % 62, false, 0, 0, false);
    }
    const f32 delta = 1.0f / 60.0f;
    double states = 0, rest = 0;
    for (s32 t = 0; t < tics; t++)
    {
        gContext->gameDeltaTime = delta;
        gContext->gameTime += (f64)delta;
        QueryPerformanceCounter(&t0);
        wst_processPendingTransitions(gContext);
        wst_updateIdleStates(gContext);
        wst_updateMoveStates(gContext);
        wst_updatePatrolStates(gContext);
        wst_updateFollowStates(gContext);
        wst_updateAttackStates(gContext);
        wst_updateWaitStates(gContext);
        QueryPerformanceCounter(&t1);
        states += (double)(t1 - t0) / (double)freq;
        QueryPerformanceCounter(&t0);
        wgrid_build(gContext);
        updateActions(gContext);
        realFogUpdate();
        QueryPerformanceCounter(&t1);
        rest += (double)(t1 - t0) / (double)freq;
    }
    s32 moving = gMap->entityManager.stateStorage.activeCounts[WAR_STATE_MOVE];
    s32 count = we_getEntitiesOfType(gContext, WAR_ENTITY_TYPE_UNIT)->count;
    printf("C %d unita', %d tic, %d in marcia alla fine: stati %.4f us, griglia+azioni+nebbia %.4f us per unita' e tic; %u campi\n", count, tics,
           moving, 1e6 * states / ((double)count * tics), 1e6 * rest / ((double)count * tics), gFieldComputes);
    worldFree();
}
