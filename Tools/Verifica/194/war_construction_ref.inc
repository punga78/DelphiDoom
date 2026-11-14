/*
  Issue #194 (seconda fetta): gli scenari di costruzione e addestramento del modello di gioco di Libs\War.
  Si include in war_model_ref.c (dopo gli scenari della prima fetta, prima di main): usa le sue funzioni (worldInit, textAdd,
  spawnDude/spawnBuilding, opEconomy, opRemove, dumpWorld ...) e il codice ORIGINALE del remake, incluso intero.

  Il remake (acoto87/war1, zlib License, (C) 2019 Alejandro Coto Gutierrez) fa questi ordini da `wcmd_executeCommand` con il
  mouse; qui si chiamano le STESSE funzioni (wcmd_tryPlaceBuilding, wcmd_executeRepairCommand, wcmd_cancel e i casi TRAIN e
  UPGRADE di wcmd_executeCommand, con la selezione e il comando messi a mano), tranne il clic sulla mappa che sceglie la
  casella: li' si fanno le stesse due chiamate (we_checkTileToBuild e wcmd_tryPlaceBuilding, o il suono di annullamento).

  Uso:  war_model_ref construction-tables           i passi delle azioni (wact_*) e le risorse delle immagini di costruzione
        war_model_ref construction [n]              n scenari: una riga per tic con l'impronta dello stato
        war_model_ref dump construction SEME TIC    il testo dello stato a quel tic
*/

static const WarUnitType kBuildTypes[16] = {
    WAR_UNIT_FARM_HUMANS, WAR_UNIT_FARM_ORCS, WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_BARRACKS_ORCS, WAR_UNIT_CHURCH,
    WAR_UNIT_TEMPLE, WAR_UNIT_TOWER_HUMANS, WAR_UNIT_TOWER_ORCS, WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_TOWNHALL_ORCS,
    WAR_UNIT_LUMBERMILL_HUMANS, WAR_UNIT_LUMBERMILL_ORCS, WAR_UNIT_STABLE, WAR_UNIT_KENNEL, WAR_UNIT_BLACKSMITH_HUMANS,
    WAR_UNIT_BLACKSMITH_ORCS
};

typedef struct { WarUnitCommandType command; WarUnitType unit; WarUnitType building; } TrainEntry;
static const TrainEntry kTrain[14] = {
    { WAR_COMMAND_TRAIN_FOOTMAN, WAR_UNIT_FOOTMAN, WAR_UNIT_BARRACKS_HUMANS },
    { WAR_COMMAND_TRAIN_GRUNT, WAR_UNIT_GRUNT, WAR_UNIT_BARRACKS_ORCS },
    { WAR_COMMAND_TRAIN_PEASANT, WAR_UNIT_PEASANT, WAR_UNIT_TOWNHALL_HUMANS },
    { WAR_COMMAND_TRAIN_PEON, WAR_UNIT_PEON, WAR_UNIT_TOWNHALL_ORCS },
    { WAR_COMMAND_TRAIN_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_BARRACKS_HUMANS },
    { WAR_COMMAND_TRAIN_CATAPULT_ORCS, WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_BARRACKS_ORCS },
    { WAR_COMMAND_TRAIN_KNIGHT, WAR_UNIT_KNIGHT, WAR_UNIT_BARRACKS_HUMANS },
    { WAR_COMMAND_TRAIN_RAIDER, WAR_UNIT_RAIDER, WAR_UNIT_BARRACKS_ORCS },
    { WAR_COMMAND_TRAIN_ARCHER, WAR_UNIT_ARCHER, WAR_UNIT_BARRACKS_HUMANS },
    { WAR_COMMAND_TRAIN_SPEARMAN, WAR_UNIT_SPEARMAN, WAR_UNIT_BARRACKS_ORCS },
    { WAR_COMMAND_TRAIN_CONJURER, WAR_UNIT_CONJURER, WAR_UNIT_TOWER_HUMANS },
    { WAR_COMMAND_TRAIN_WARLOCK, WAR_UNIT_WARLOCK, WAR_UNIT_TOWER_ORCS },
    { WAR_COMMAND_TRAIN_CLERIC, WAR_UNIT_CLERIC, WAR_UNIT_CHURCH },
    { WAR_COMMAND_TRAIN_NECROLYTE, WAR_UNIT_NECROLYTE, WAR_UNIT_TEMPLE }
};

/* i quattro tipi di tic degli scenari: la durata (secondi) dipende dal seme */
static const f32 kConstructionDeltas[4] = { 1.0f / 60.0f, 0.25f, 2.0f, 5.0f };
#define CONSTRUCTION_TICS 400

static WarEntity* gWallEntity;
static WarEntity* gRuinEntity;
static f32 gConstructionDelta;

/* ------------------------------------------------------------------------------------------------------------------ */
/* le tabelle: i passi delle azioni e le risorse delle immagini di costruzione                                        */
/* ------------------------------------------------------------------------------------------------------------------ */

static void printConstructionTables(void)
{
    wm_allocInit(64ull * 1024 * 1024, 4ull * 1024 * 1024, 1ull * 1024 * 1024);
    wact_initUnitActionDefs();

    printf("# steps: S type action loop directional count (step:param)*count  (step 1 frame, 2 wait, 3 attack, 4.. sounds)\n");
    for (s32 t = 0; t < WAR_UNIT_COUNT; t++)
    {
        for (s32 a = 0; a < WAR_ACTION_TYPE_COUNT; a++)
        {
            const WarUnitActionDef* def = &gUnitActionDefs[t][a];
            if (def->type == WAR_ACTION_TYPE_NONE)
                continue;
            printf("S %d %d %d %d %d", t, a, def->loop ? 1 : 0, def->directional ? 1 : 0, def->steps.count);
            for (s32 i = 0; i < def->steps.count; i++)
                printf(" %d:%d", def->steps.items[i].type, def->steps.items[i].param);
            printf("\n");
        }
    }
    printf("# construction resources: R type buildingResource resourceIndex\n");
    for (s32 i = 0; i < (s32)arrayLength(buildingsData); i++)
    {
        const WarBuildingData* d = &buildingsData[i];
        printf("R %d %d %d\n", d->type, d->buildingResource, wu_getUnitData(d->type)->resourceIndex);
    }
    printf("# costs: K wall gold wood maxhp  road gold wood\n");
    printf("K %d %d %d %d %d\n", WAR_WALL_GOLD_COST, WAR_WALL_WOOD_COST, WAR_WALL_MAX_HP, WAR_ROAD_GOLD_COST, WAR_ROAD_WOOD_COST);
    printf("# cheat: H hurry-up factor bits\n");
    printf("H %08x\n", fbits(CHEAT_SPEED_UP_FACTOR));
    wm_allocFree();
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* le righe in piu' dell'impronta                                                                                     */
/* ------------------------------------------------------------------------------------------------------------------ */

static void dumpConstruction(Text* t)
{
    textAdd(t, "X audio=%u mix=%08x hurry=%d\n", gAudioCount, gAudioMix, gMap->hurryUp ? 1 : 0);
    WarEntityManager* m = &gMap->entityManager;
    for (s32 i = 1; i < MAX_ENTITIES_COUNT; i++)
    {
        WarEntity* e = &m->entities[i];
        if (e->id == 0)
            continue;
        if (!we_getUnitComponent(gContext, e))
            continue;
        WarSpriteComponent* sprite = we_getSpriteComponent(gContext, e);
        WarTransformComponent* tr = we_getTransformComponent(gContext, e);
        textAdd(t, "Y slot=%d", i);
        if (sprite)
            textAdd(t, " en=%d fr=%d fi=%d", we_isComponentEnabled(gContext, e, COMP_SPRITE) ? 1 : 0, sprite->sprite.framesCount,
                    sprite->frameIndex);
        else
            textAdd(t, " nosprite");
        if (tr)
            textAdd(t, " sx=%08x", fbits(tr->scale.x));
        textAdd(t, "\n");
    }
    WarRuinComponent* ruins = we_getRuinComponent(gContext, gRuinEntity);
    textAdd(t, "R %d", ruins->pieces.count);
    for (s32 i = 0; i < ruins->pieces.count; i++)
        textAdd(t, " %d,%d,%d", ruins->pieces.items[i].type, ruins->pieces.items[i].tilex, ruins->pieces.items[i].tiley);
    textAdd(t, "\n");
    WarWallComponent* walls = we_getWallComponent(gContext, gWallEntity);
    textAdd(t, "V %d", walls->pieces.count);
    for (s32 i = 0; i < walls->pieces.count; i++)
    {
        WarWallPiece* p = &walls->pieces.items[i];
        textAdd(t, " %d,%d/%d,%d,%d,%d", p->type, p->hp, p->maxhp, p->tilex, p->tiley, p->player);
    }
    textAdd(t, "\n");
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* la scelta delle entita': dal punto estratto a caso (una sola estrazione) si cerca in avanti la prima che va bene      */
/* ------------------------------------------------------------------------------------------------------------------ */

static bool predWorker(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player == 0 && wu_isDudeUnit(gContext, e) && wu_isWorkerUnit(gContext, e) && !wst_isDead(gContext, e) &&
           !wst_isGoingToDie(gContext, e);
}

static bool predBuilding(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player == 0 && wu_isBuildingUnit(gContext, e);
}

static bool predAnyOwn(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player == 0;
}

static WarEntity* pickWhere(bool (*pred)(WarEntity*))
{
    WarEntityList* units = we_getEntitiesOfType(gContext, WAR_ENTITY_TYPE_UNIT);
    u32 start = scriptBelow(units->count > 0 ? (u32)units->count : 1u);
    for (s32 k = 0; k < units->count; k++)
    {
        WarEntity* e = units->items[((s32)start + k) % units->count];
        if (e && pred(e))
            return e;
    }
    return NULL;
}

static void selectOnly(WarEntity* e)
{
    WarEntityIdListClear(&gMap->selectedEntities);
    WarEntityIdListAdd(&gMap->selectedEntities, e->id);
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* le operazioni                                                                                                      */
/* ------------------------------------------------------------------------------------------------------------------ */

static void cOpBuild(void)
{
    WarEntity* worker = pickWhere(predWorker);
    u32 typeIndex = scriptBelow(16);
    u32 row = scriptBelow(4);
    if (!worker)
        return;
    WarUnitType buildingType = kBuildTypes[typeIndex];
    const WarUnitData* data = wu_getUnitData(buildingType);
    vec2 workerTile = wu_getUnitCenterTile(gContext, worker);
    /* a destra del contadino, con la sua riga dentro il lato del nuovo edificio: e' a distanza 1, quindi nel raggio */
    s32 tx = (s32)workerTile.x + 1;
    s32 ty = MAX((s32)workerTile.y - (s32)(row % (u32)data->sizey), 0);
    const WarBuildingStats* stats = wu_getBuildingStats(buildingType);
    if (we_checkTileToBuild(gContext, buildingType, tx, ty))
    {
        WarPlayerInfo* player = wu_getOwningPlayer(gContext, worker);
        resultMix(wcmd_tryPlaceBuilding(gContext, worker, player, buildingType, vec2i(tx, ty), stats) ? 1 : 0);
    }
    else
    {
        wa_createAudio(gContext, CREATE_AUDIO_ARGS_INIT(.audioId = WAR_UI_CANCEL, .loop = false));
    }
}

static void cOpTrain(void)
{
    WarEntity* building = pickWhere(predBuilding);
    u32 k = scriptBelow(4);
    if (!building)
        return;
    WarUnitComponent* unit = we_getUnitComponent(gContext, building);
    const TrainEntry* matches[14];
    s32 count = 0;
    for (s32 i = 0; i < 14; i++)
        if (kTrain[i].building == unit->type)
            matches[count++] = &kTrain[i];
    if (count == 0)
        return;
    const TrainEntry* entry = matches[k % (u32)count];
    selectOnly(building);
    gMap->commandState.command.type = entry->command;
    gMap->commandState.command.train.unitToTrain = entry->unit;
    gMap->commandState.command.train.buildingUnit = entry->building;
    resultMix(wcmd_executeCommand(gContext) ? 1 : 0);
}

/* i miglioramenti della stessa coppia (frecce/lance, spade/asce, ...) condividono un livello: due in corso insieme farebbero
   salire il livello oltre il massimo e il C si ferma su un assert in we_increaseUpgradeLevel. Lo scenario non lo provoca: il port
   lo rifiuta (vedi README, "difetti del C") */
static s32 upgradesInProgress(s32 pair)
{
    s32 count = 0;
    WarEntityManager* m = &gMap->entityManager;
    for (s32 i = 1; i < MAX_ENTITIES_COUNT; i++)
    {
        WarEntity* e = &m->entities[i];
        if (e->id == 0)
            continue;
        WarStateMachineComponent* sm = we_getStateMachineComponent(gContext, e);
        if (!sm)
            continue;
        for (s32 d = 0; d < sm->depth; d++)
        {
            WarStateBase* s = wst_deref(gContext, sm->stack[d]);
            if (s && s->type == WAR_STATE_UPGRADE && !((WarStateUpgrade*)s)->cancelled &&
                ((WarStateUpgrade*)s)->upgradeToBuild / 2 == pair)
                count++;
        }
        if (sm->pending.operation != WAR_STATE_OP_NONE && sm->pending.stateRef.type == WAR_STATE_UPGRADE)
        {
            WarStateBase* s = wst_deref(gContext, sm->pending.stateRef);
            if (s && ((WarStateUpgrade*)s)->upgradeToBuild / 2 == pair)
                count++;
        }
    }
    return count;
}

static void cOpUpgrade(void)
{
    WarEntity* building = pickWhere(predBuilding);
    u32 upgrade = scriptBelow(19);
    if (!building)
        return;
    WarPlayerInfo* player = &gMap->players[0];
    if (!hasRemainingUpgrade(player, upgrade))
        return;
    if (getUpgradeLevel(player, upgrade) + upgradesInProgress((s32)upgrade / 2) >= player->upgrades[upgrade / 2].allowed)
        return;
    WarUnitComponent* unit = we_getUnitComponent(gContext, building);
    selectOnly(building);
    gMap->commandState.command.type = WAR_COMMAND_UPGRADE_SWORDS;
    gMap->commandState.command.upgrade.upgradeToBuild = (WarUpgradeType)upgrade;
    gMap->commandState.command.upgrade.buildingUnit = unit->type;
    resultMix(wcmd_executeCommand(gContext) ? 1 : 0);
}

static void cOpCancel(void)
{
    WarEntity* building = pickWhere(predBuilding);
    if (!building)
        return;
    selectOnly(building);
    wcmd_cancel(gContext, building);
}

static void cOpRepair(void)
{
    WarEntity* building = pickWhere(predBuilding);
    u32 kind = scriptBelow(2);
    u32 side = scriptBelow(4);
    if (!building)
        return;
    WarUnitComponent* unit = we_getUnitComponent(gContext, building);
    /* un contadino nuovo a sinistra dell'edificio, nel raggio: un contadino lontano chiederebbe l'inseguimento (follow), che
       questa fetta non porta */
    s32 sx = unit->tilex - 1;
    s32 sy = unit->tiley + (s32)(side % (u32)unit->sizey);
    if (sx < 0)
        return;
    WarEntity* worker = spawnDude(kind ? WAR_UNIT_PEON : WAR_UNIT_PEASANT, 0, sx, sy);
    if (!worker)
        return;
    selectOnly(worker);
    wcmd_executeRepairCommand(gContext, building);
}

static void cOpDamageBuilding(void)
{
    WarEntity* building = pickWhere(predBuilding);
    s32 minDamage = (s32)scriptBelow(200);
    s32 rndDamage = (s32)scriptBelow(300);
    if (!building)
        return;
    we_takeDamage(gContext, building, minDamage, rndDamage);
}

static void cOpWall(void)
{
    u32 nearRoll = scriptBelow(100);
    u32 dir = scriptBelow(4);
    s32 rx = 6 + (s32)scriptBelow(40);
    s32 ry = 30 + (s32)scriptBelow(10);
    WarWallComponent* walls = we_getWallComponent(gContext, gWallEntity);
    s32 x = rx;
    s32 y = ry;
    if (nearRoll < 70 && walls->pieces.count > 0)
    {
        /* accanto all'ultimo pezzo, per fare file di mura */
        WarWallPiece* last = &walls->pieces.items[walls->pieces.count - 1];
        static const s32 dx[4] = { 0, 1, 0, -1 };
        static const s32 dy[4] = { -1, 0, 1, 0 };
        x = last->tilex + dx[dir];
        y = last->tiley + dy[dir];
    }
    WarPlayerInfo* player = &gMap->players[0];
    if (we_checkTileToBuildRoadOrWall(gContext, x, y))
    {
        if (we_decreasePlayerResources(gContext, player, WAR_WALL_GOLD_COST, WAR_WALL_WOOD_COST))
        {
            WarWallPiece* piece = we_addWallPiece(gContext, gWallEntity, x, y, 0);
            piece->hp = WAR_WALL_MAX_HP;
            piece->maxhp = WAR_WALL_MAX_HP;
            we_determineWallTypes(gContext, gWallEntity);
            wa_createAudio(gContext, CREATE_AUDIO_ARGS_INIT(.audioId = WAR_BUILD_ROAD, .loop = false));
        }
    }
    else
    {
        wa_createAudio(gContext, CREATE_AUDIO_ARGS_INIT(.audioId = WAR_UI_CANCEL, .loop = false));
    }
}

static void cOpWallDamage(void)
{
    WarWallComponent* walls = we_getWallComponent(gContext, gWallEntity);
    u32 index = scriptBelow(walls->pieces.count > 0 ? (u32)walls->pieces.count : 1u);
    s32 minDamage = (s32)scriptBelow(60);
    s32 rndDamage = (s32)scriptBelow(60);
    if (walls->pieces.count == 0)
        return;
    we_takeWallDamage(gContext, gWallEntity, &walls->pieces.items[index], minDamage, rndDamage);
}

static void cOpPopAny(void)
{
    WarEntity* e = pickWhere(predAnyOwn);
    if (!e)
        return;
    wst_popState(gContext, e, WAR_TRANSITION_CAUSE_PLAYER_ORDER, WAR_STATE_RESULT_CANCELLED);
}

static void cScriptStep(void)
{
    u32 r = scriptBelow(100);
    if (r < 6) cOpBuild();
    else if (r < 13) cOpTrain();
    else if (r < 16) cOpUpgrade();
    else if (r < 18) cOpCancel();
    else if (r < 20) cOpRepair();
    else if (r < 26) cOpDamageBuilding();
    else if (r < 29) cOpWall();
    else if (r < 31) cOpWallDamage();
    else if (r < 33) opEconomy();
    else if (r < 34) opRemove();
    else if (r < 36) cOpPopAny();
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* il mondo                                                                                                           */
/* ------------------------------------------------------------------------------------------------------------------ */

typedef struct { WarUnitType type; s32 x; s32 y; } BaseBuilding;
static const BaseBuilding kBase[] = {
    { WAR_UNIT_TOWNHALL_HUMANS, 6, 6 }, { WAR_UNIT_BARRACKS_HUMANS, 11, 6 }, { WAR_UNIT_BARRACKS_ORCS, 16, 6 },
    { WAR_UNIT_CHURCH, 21, 6 }, { WAR_UNIT_TEMPLE, 26, 6 }, { WAR_UNIT_FARM_HUMANS, 31, 6 },
    { WAR_UNIT_TOWER_HUMANS, 6, 12 }, { WAR_UNIT_TOWER_ORCS, 11, 12 }, { WAR_UNIT_BLACKSMITH_HUMANS, 16, 12 },
    { WAR_UNIT_BLACKSMITH_ORCS, 21, 12 }, { WAR_UNIT_TOWNHALL_ORCS, 26, 12 }, { WAR_UNIT_FARM_ORCS, 31, 12 },
    { WAR_UNIT_FARM_HUMANS, 35, 6 }, { WAR_UNIT_FARM_HUMANS, 35, 9 }, { WAR_UNIT_FARM_ORCS, 35, 12 },
    { WAR_UNIT_FARM_ORCS, 35, 15 }, { WAR_UNIT_LUMBERMILL_HUMANS, 6, 16 }
};
static const BaseBuilding kBaseDudes[] = {
    { WAR_UNIT_PEASANT, 6, 20 }, { WAR_UNIT_PEASANT, 9, 20 }, { WAR_UNIT_PEON, 12, 20 }, { WAR_UNIT_FOOTMAN, 15, 20 },
    { WAR_UNIT_GRUNT, 18, 20 }
};

static void constructionInit(u32 seed)
{
    worldInit(seed ^ 0xA5A5A5A5u, seed * 2654435761u + 12345u);
    gAudioMix = 0;
    gConstructionDump = 1;
    gConstructionDelta = kConstructionDeltas[seed % 4];
    gMap->hurryUp = (seed % 3 == 0) || (seed % 4 == 0);
    gSpawnedCount = 0;
    gMap->players[0].gold = 1500 + (s32)scriptBelow(9000);
    gMap->players[0].wood = 800 + (s32)scriptBelow(6000);

    /* la mappa crea l'entita' delle mura (con il suo stato) e quella delle rovine prima delle unita' */
    gWallEntity = we_createWall(gContext);
    we_addStateMachineComponent(gContext, gWallEntity);
    WarStateIdle* wallIdle = wst_createIdleState(gContext, gWallEntity, false);
    wst_resetState(gContext, gWallEntity, (WarStateBase*)wallIdle, WAR_TRANSITION_CAUSE_INITIALIZATION);
    gMap->editing.wall = gWallEntity;
    gRuinEntity = we_createRuins(gContext);
    gMap->editing.ruin = gRuinEntity;

    for (s32 i = 0; i < (s32)arrayLength(kBase); i++)
        spawnBuilding(kBase[i].type, 0, kBase[i].x, kBase[i].y);
    for (s32 i = 0; i < (s32)arrayLength(kBaseDudes); i++)
        spawnDude(kBaseDudes[i].type, 0, kBaseDudes[i].x, kBaseDudes[i].y);
}

static void constructionTick(void)
{
    gContext->gameDeltaTime = gConstructionDelta;
    gContext->gameTime += (f64)gConstructionDelta;

    cScriptStep();

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
    /* updateActions de wmap_updateMap (static in war_map.c, che e' incluso qui sopra) */
    updateActions(gContext);
}

static void runConstruction(u32 seed, s32 dumpTic, bool perTic)
{
    constructionInit(seed);
    /* WAR_REF_COVER=1: per ogni scenario, su stderr, in quanti tic c'era almeno uno stato di ogni tipo */
    s32 cover[WAR_STATE_COUNT] = {0};
    for (s32 tic = 0; tic < CONSTRUCTION_TICS; tic++)
    {
        constructionTick();
        for (s32 k = 0; k < WAR_STATE_COUNT; k++)
            if (gMap->entityManager.stateStorage.activeCounts[k] > 0)
                cover[k]++;
        Text text = {0};
        if (perTic || tic == dumpTic)
            dumpWorld(&text, tic);
        if (dumpTic >= 0 && tic == dumpTic)
            printf("%s", text.data);
        else if (perTic)
            printf("C %u %d %08x %d\n", seed, tic, fnv1a(text.data, text.length), gMap->entityManager.entityCount);
        free(text.data);
    }
    if (getenv("WAR_REF_COVER"))
    {
        fprintf(stderr, "cover %u", seed);
        for (s32 k = 0; k < WAR_STATE_COUNT; k++)
            fprintf(stderr, " %d", cover[k]);
        fprintf(stderr, " | audio %u flash %u ents %d\n", gAudioCount, gFlashCount, gMap->entityManager.entityCount);
    }
    gConstructionDump = 0;
    worldFree();
}
