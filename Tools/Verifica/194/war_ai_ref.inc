/*
  Issue #196: gli scenari dell'IA del remake (war_ai.c INTERO, originale) sul mondo di war_full_ref.inc.

  Si include in war_model_ref.c dopo war_full_ref.inc (ne usa pickWhere, fEnemyBuilding, fAlive, spawnBuilding, spawnDude,
  selectOnly, wcmd_tryPlaceBuilding, i testi di dumpFull). Il codice del remake (acoto87/war1, zlib License, (C) 2019 Alejandro
  Coto Gutierrez) e' quello ORIGINALE: war_ai.c e' incluso intero da war_model_ref.c (wai_initAIPlayer, wai_updateAIPlayers,
  wai_applyUnitRequestProgress chiamata da wst_applyTrainTransaction di war_state_machine_train.c).

  Cio' che e' nostro: il tempo "reale" (context->realTime e' il tempo di parete del gioco; qui avanza di delta * un fattore
  per scenario piu' le pause di aiOpTime, in modo che sia ripetibile), le operazioni dello scenario (economia del giocatore 1,
  fattorie, centri urbani, ordini del giocatore agli edifici dell'IA, annullamenti, danni, il trucco del tempo) e la riga
  "I" dell'impronta (stato dell'IA: id dei comandi, copione, stato dei comandi, comandi nei stati di addestramento).

  Uso:  war_model_ref ai-tables                      cio' che il C da' per i produttori e per il copione di ogni razza
        war_model_ref ai [n] | lines ai SEME | dump ai SEME TIC | fullstats ai [n]   come gli scenari "full"
        war_model_ref benchai [giocatori] [tic]      costo per tic dell'IA (wai_updateAIPlayers)
*/

#define AI_TICS 3000

/* ------------------------------------------------------------------------------------------------------------------ */
/* le tabelle                                                                                                         */
/* ------------------------------------------------------------------------------------------------------------------ */

static void printAiTables(void)
{
    worldInit(1, 1);
    printf("# AI command types: E request wait attack defend sleep count\n");
    printf("E %d %d %d %d %d %d\n", (s32)WAR_AI_COMMAND_REQUEST, (s32)WAR_AI_COMMAND_WAIT, (s32)WAR_AI_COMMAND_ATTACK,
           (s32)WAR_AI_COMMAND_DEFEND, (s32)WAR_AI_COMMAND_SLEEP, (s32)WAR_AI_COMMAND_COUNT);
    printf("# AI statuses: Z created started completed\n");
    printf("Z %d %d %d\n", (s32)WAR_AI_COMMAND_STATUS_CREATED, (s32)WAR_AI_COMMAND_STATUS_STARTED,
           (s32)WAR_AI_COMMAND_STATUS_COMPLETED);
    printf("# producers (wu_getProducerUnitOfType): P unitType producer valid dude building\n");
    for (s32 type = 0; type < WAR_UNIT_COUNT; type++)
    {
        WarUnitType producer = wu_getProducerUnitOfType((WarUnitType)type);
        printf("P %d %d %d %d %d\n", type, (s32)producer, wu_isValidUnitType(producer) ? 1 : 0,
               wu_isDudeUnitType((WarUnitType)type) ? 1 : 0, wu_isBuildingUnitType((WarUnitType)type) ? 1 : 0);
    }
    printf("# the script of wai_initAI for each race: S race index kind unitType count\n");
    for (s32 race = 0; race < 3; race++)
    {
        WarPlayerInfo* player = &gMap->players[1];
        player->race = (WarRace)race;
        player->ai = NULL;
        wai_initAIPlayer(gContext, player);
        WarAICustomData* data = (WarAICustomData*)player->ai->customData;
        for (s32 i = 0; i < data->commands.count; i++)
        {
            WarAICommand* command = data->commands.items[i];
            WarUnitType unitType = command->type == WAR_AI_COMMAND_REQUEST ? command->request.unitType : command->wait.unitType;
            s32 count = command->type == WAR_AI_COMMAND_REQUEST ? command->request.count : command->wait.count;
            printf("S %d %d %d %d %d\n", race, i, (s32)command->type, (s32)unitType, count);
        }
    }
    printf("# K idleSleepSeconds idsStartAt\n");
    printf("K %d %d\n", 10, 1);
    worldFree();
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* l'impronta dell'IA                                                                                                  */
/* ------------------------------------------------------------------------------------------------------------------ */

static void dumpAi(Text* t)
{
    WarAI* ai = gMap->players[1].ai;
    u32 lo, hi;
    if (!ai)
        return;
    WarAICustomData* data = (WarAICustomData*)ai->customData;
    dbits(gContext->realTime, &lo, &hi);
    textAdd(t, "I id=%u idx=%d rt=%08x%08x cur=%d nxt=%d", ai->staticCommandId, data->index, hi, lo,
            ai->currentCommands.count, ai->nextCommands.count);
    for (s32 i = 0; i < ai->currentCommands.count; i++)
    {
        WarAICommand* c = ai->currentCommands.items[i];
        textAdd(t, " %u,%d,%d,", c->id, (s32)c->type, (s32)c->status);
        if (c->type == WAR_AI_COMMAND_SLEEP)
        {
            dbits(c->sleep.endRealTime, &lo, &hi);
            textAdd(t, "%08x%08x", hi, lo);
        }
        else
        {
            textAdd(t, "%d,%d", (s32)c->request.unitType, c->request.count);
        }
    }
    textAdd(t, "\n");
    WarStateStorage* storage = &gMap->entityManager.stateStorage;
    textAdd(t, "J");
    for (s32 i = 0; i < MAX_STATES_PER_TYPE; i++)
        if (storage->occupied[WAR_STATE_TRAIN][i])
            textAdd(t, " %d:%u", i, storage->train[i].aiCommand ? storage->train[i].aiCommand->id : 0u);
    textAdd(t, "\n");
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* le operazioni (solo nel modo "ia")                                                                                  */
/* ------------------------------------------------------------------------------------------------------------------ */

static bool fAiFarm(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player == 1 && (u->type == WAR_UNIT_FARM_HUMANS || u->type == WAR_UNIT_FARM_ORCS) && fAlive(e);
}

static bool fAiHall(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player == 1 && (u->type == WAR_UNIT_TOWNHALL_HUMANS || u->type == WAR_UNIT_TOWNHALL_ORCS) && fAlive(e);
}

static void aiOpEconomy(void)
{
    u32 kind = scriptBelow(4);
    s32 gold = (s32)scriptBelow(900);
    s32 wood = (s32)scriptBelow(900);
    WarPlayerInfo* player = &gMap->players[1];
    if (kind == 0)
    {
        player->gold = gold;
        player->wood = wood;
    }
    else if (kind == 1)
    {
        player->gold += 400;
        player->wood += 200;
    }
    else if (kind == 2)
        player->gold = 0;
    else
    {
        player->gold = 5000;
        player->wood = 5000;
    }
}

static void aiOpFarm(void)
{
    u32 kind = scriptBelow(3);
    u32 col = scriptBelow(6);
    u32 row = scriptBelow(3);
    WarUnitType farm = wu_getUnitTypeForRace(WAR_UNIT_FARM_HUMANS, gMap->players[1].race);
    if (kind == 0)
    {
        spawnBuilding(farm, 1, 36 + 3 * (s32)col, 41 + 3 * (s32)row);
        return;
    }
    WarEntity* e = pickWhere(fAiFarm);
    if (!e)
        return;
    if (kind == 1)
        we_removeEntityById(gContext, e->id);
    else
        we_takeDamage(gContext, e, 200, 200);
}

static void aiOpHall(void)
{
    u32 kind = scriptBelow(2);
    u32 col = scriptBelow(5);
    u32 row = scriptBelow(3);
    WarRace race = gMap->players[1].race;
    WarUnitType hall = wu_getUnitTypeForRace(WAR_UNIT_TOWNHALL_HUMANS, race);
    s32 x = 34 + 4 * (s32)col;
    s32 y = 44 + 4 * (s32)row;
    if (kind == 0)
    {
        spawnBuilding(hall, 1, x, y);
        return;
    }
    /* un centro urbano in costruzione: un lavoratore del giocatore 1 lo piazza (wcmd_tryPlaceBuilding) */
    WarEntity* worker = spawnDude(wu_getUnitTypeForRace(WAR_UNIT_PEON, race), 1, x - 2, y);
    if (!worker)
        return;
    const WarBuildingStats* stats = wu_getBuildingStats(hall);
    if (we_checkTileToBuild(gContext, hall, x, y))
    {
        WarPlayerInfo* player = wu_getOwningPlayer(gContext, worker);
        wcmd_tryPlaceBuilding(gContext, worker, player, hall, vec2i(x, y), stats);
    }
    else
    {
        wa_createAudio(gContext, CREATE_AUDIO_ARGS_INIT(.audioId = WAR_UI_CANCEL, .loop = false));
    }
}

/* un ordine DEL GIOCATORE all'edificio dell'IA: le stesse quattro chiamate di wcmd_executeCommand (TRAIN), con la causa del giocatore */
static void aiOpPreempt(void)
{
    WarEntity* b = pickWhere(fEnemyBuilding);
    if (!b)
        return;
    WarUnitComponent* unit = we_getUnitComponent(gContext, b);
    WarUnitType type;
    if (unit->type == WAR_UNIT_TOWNHALL_ORCS) type = WAR_UNIT_PEON;
    else if (unit->type == WAR_UNIT_TOWNHALL_HUMANS) type = WAR_UNIT_PEASANT;
    else if (unit->type == WAR_UNIT_BARRACKS_ORCS) type = WAR_UNIT_GRUNT;
    else if (unit->type == WAR_UNIT_BARRACKS_HUMANS) type = WAR_UNIT_FOOTMAN;
    else return;
    if (wst_canSubmitTransition(gContext, b, WAR_INTERRUPT_PLAYER_ORDER))
    {
        WarPlayerInfo* player = wu_getOwningPlayer(gContext, b);
        const WarUnitStats* stats = wu_getUnitStats(type);
        if (we_checkFarmFood(gContext, player) && we_enoughPlayerResources(gContext, player, stats->goldCost, stats->woodCost))
        {
            WarStateTrain* train = wst_createTrainState(gContext, b, type, (f32)stats->buildTime, stats->goldCost, stats->woodCost, NULL);
            wst_resetState(gContext, b, (WarStateBase*)train, WAR_TRANSITION_CAUSE_PLAYER_ORDER);
        }
    }
}

static void aiOpCancel(void)
{
    WarEntity* b = pickWhere(fEnemyBuilding);
    if (!b)
        return;
    selectOnly(b);
    wcmd_cancel(gContext, b);
}

static void aiOpDamage(void)
{
    s32 minDamage = (s32)scriptBelow(300);
    s32 rndDamage = (s32)scriptBelow(400);
    u32 which = scriptBelow(2);
    WarEntity* e = pickWhere(which ? fAiHall : fEnemyBuilding);
    if (!e)
        return;
    we_takeDamage(gContext, e, minDamage, rndDamage);
}

static void aiOpTime(void)
{
    gContext->realTime += (f64)scriptBelow(20);
}

static void aiOpHurry(void)
{
    gMap->hurryUp = !gMap->hurryUp;
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* il costo di wai_updateAIPlayers per tic                                                                             */
/* ------------------------------------------------------------------------------------------------------------------ */

static void benchAi(s32 tics)
{
    long long freq, t0, t1, acc = 0;
    worldInit(777, 888);
    gSpawnedCount = 0;
    gContext->realTime = 0;
    gMap->players[1].race = WAR_RACE_ORCS;
    for (s32 i = 0; i < 4; i++)
        spawnBuilding(WAR_UNIT_TOWNHALL_ORCS, 1, 4 + 6 * i, 4);
    for (s32 i = 0; i < 2; i++)
        spawnBuilding(WAR_UNIT_FARM_ORCS, 1, 4 + 3 * i, 20);
    wai_initAIPlayers(gContext);
    QueryPerformanceFrequency(&freq);
    /* il costo di una coppia di letture del contatore, tolto dalla misura */
    long long overhead = 0;
    for (s32 k = 0; k < 100000; k++)
    {
        QueryPerformanceCounter(&t0);
        QueryPerformanceCounter(&t1);
        overhead += t1 - t0;
    }
    const f32 delta = 1.0f / 60.0f;
    for (s32 t = 0; t < tics; t++)
    {
        gContext->gameDeltaTime = delta;
        gContext->gameTime += (f64)delta;
        gContext->realTime += (f64)delta * 10.0;
        /* oro e legna sempre pieni: l'IA ha sempre qualcosa da fare finche' il copione dura; poi dorme */
        gMap->players[1].gold = 5000;
        gMap->players[1].wood = 5000;
        QueryPerformanceCounter(&t0);
        wai_updateAIPlayers(gContext);
        QueryPerformanceCounter(&t1);
        acc += t1 - t0;
        wst_processPendingTransitions(gContext);
        wst_updateTrainStates(gContext);
    }
    double perTic = 1e6 * ((double)acc - (double)overhead / 100000.0 * tics) / (double)freq / tics;
    printf("C %d tic, 1 giocatore IA (us per tic, solo wai_updateAIPlayers, tolto il contatore): %.4f\n", tics, perTic);
    worldFree();
}
