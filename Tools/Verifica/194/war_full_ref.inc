/*
  Issue #194 (completamento): gli scenari dei comandi, degli incantesimi e del tic intero del modello di gioco di Libs\War.
  Si include in war_model_ref.c dopo war_construction_ref.inc (ne usa pickWhere, selectOnly, cOpTrain, cOpUpgrade, cOpCancel,
  cOpDamageBuilding, cOpWallDamage, e di war_model_ref.c worldInit, spawnDude/spawnBuilding, gatherForest, opEconomy, opRemove,
  dumpWorld).

  Il codice del remake (acoto87/war1, zlib License, (C) 2019 Alejandro Coto Gutierrez) e' quello ORIGINALE, incluso intero:
  gli ordini passano dai VERI wcmd_executeCommand (con un clic sintetico: input->pos, il tasto sinistro "appena premuto", il
  pannello della mappa grande quanto la mappa; il punto dello schermo e' quello della mappa meno l'origine della vista, che
  non e' in alto a sinistra perche' la pioggia di fuoco parte da sopra la vista), updateCommandFromRightClick (clic destro), updateSelectionFromList e updateSelectionGroups (selezione e
  gruppi), wcmd_cancel; il tic e' l'ordine intero di wmap_updateMap: stati, griglia, azioni, wanim_updateAnimations,
  proiettili, updateMagic, updateSpells (tickFull).

  Cio' che e' nostro: la scelta delle operazioni (stesso generatore con seme degli altri scenari), la potatura della selezione
  dalle entita' che non esistono piu' (il remake si fermerebbe su un assert: difetto non conservato, in Delphi e' EWarException),
  l'ordine di addestramento "dell'IA" (le stesse quattro chiamate di war_ai.c con WAR_TRANSITION_CAUSE_AI_ORDER, senza includere
  war_ai.c: l'IA e' la #196) e il testo in piu' dello stato (animazioni, incantesimi, strade, selezione, foreste).

  Uso:  war_model_ref commands [n] | spells [n] | full [n]      n scenari (default 12) di 900 tic: una riga per tic
        war_model_ref dump commands|spells|full SEME TIC        il testo dello stato a quel tic
        war_model_ref fullstats commands|spells|full [n]        copertura: tic con almeno uno stato per tipo, entita' per tipo
        war_model_ref lines commands|spells|full SEME           le righe di un solo scenario
        war_model_ref command-tables                            cio' che ogni wcmd_train*, wcmd_upgrade*, wcmd_build* mette nel comando
*/

#define FULL_TICS 900
static const f32 kFullDeltas[4] = { 1.0f / 60.0f, 1.0f / 30.0f, 0.1f, 0.25f };

static int gFullMode;          /* 0 comandi, 1 incantesimi, 2 tutto */
static f32 gFullDelta;
static WarEntity* gRoadEntity;
static WarEntityId gFullForest;
static WarEntityId gFullMine;

/* ------------------------------------------------------------------------------------------------------------------ */
/* il testo in piu' dello stato                                                                                       */
/* ------------------------------------------------------------------------------------------------------------------ */

static s32 animKind(WarSpriteAnimation* anim)
{
    StringView name = wstr_view(&anim->name);
    char c = name.length > 0 ? name.data[0] : '?';
    switch (c)
    {
        case 'l': return 1;
        case 'h': return 2;
        case 'c': return 3;
        case 'e': return anim->frames.count == 3 ? 5 : 4;
        case 's': return 6;
        case 'p': return 7;
        default: return 0;
    }
}

static void dumpFull(Text* t)
{
    WarEntityManager* m = &gMap->entityManager;
    textAdd(t, "U vy=%08x sel=%d", fbits(gMap->camera.viewport.y), gMap->selectedEntities.count);
    for (s32 i = 0; i < gMap->selectedEntities.count; i++)
        textAdd(t, " %d", gMap->selectedEntities.items[i]);
    for (s32 g = 0; g < MAX_SELECTION_GROUPS; g++)
    {
        textAdd(t, " g%d=%d", g, gMap->selectionGroups[g].count);
        for (s32 i = 0; i < gMap->selectionGroups[g].count; i++)
            textAdd(t, ":%d", gMap->selectionGroups[g].items[i]);
    }
    textAdd(t, "\n");
    WarRoadComponent* road = we_getRoadComponent(gContext, gRoadEntity);
    textAdd(t, "D %d", road->pieces.count);
    for (s32 i = 0; i < road->pieces.count; i++)
        textAdd(t, " %d,%d,%d,%d", road->pieces.items[i].type, road->pieces.items[i].tilex, road->pieces.items[i].tiley,
                road->pieces.items[i].player);
    textAdd(t, "\n");
    textAdd(t, "M n=%u h=%08x\n", gTileWrites, gTileHash);
    WarEntityList* forests = we_getEntitiesOfType(gContext, WAR_ENTITY_TYPE_FOREST);
    for (s32 i = 0; i < forests->count; i++)
    {
        WarEntity* forest = forests->items[i];
        WarForestComponent* fc = we_getForestComponent(gContext, forest);
        textAdd(t, "F id=%d n=%d", forest->id, fc->trees.count);
        for (s32 k = 0; k < fc->trees.count; k++)
        {
            WarTree* tree = &fc->trees.items[k];
            textAdd(t, " %d,%d,%d,%d", tree->tilex, tree->tiley, tree->amount, (s32)tree->type);
        }
        textAdd(t, "\n");
    }
    for (s32 i = 1; i < MAX_ENTITIES_COUNT; i++)
    {
        WarEntity* e = &m->entities[i];
        if (e->id == 0)
            continue;
        WarAnimationsComponent* anims = we_getAnimationsComponent(gContext, e);
        if (anims && anims->animations.count > 0)
        {
            textAdd(t, "A slot=%d n=%d", i, anims->animations.count);
            for (s32 k = 0; k < anims->animations.count; k++)
            {
                WarSpriteAnimation* a = &anims->animations.items[k];
                textAdd(t, " %d,%d,%d,%d,%08x,%08x,%08x", animKind(a), a->loop ? 1 : 0, (s32)a->status, a->frames.count,
                        fbits(a->frameDelay), fbits(a->animTime), fbits(a->loopTime));
            }
            textAdd(t, "\n");
        }
        WarSightComponent* sight = we_getSightComponent(gContext, e);
        if (sight)
            textAdd(t, "S slot=%d %08x,%08x %08x\n", i, fbits(sight->position.x), fbits(sight->position.y), fbits(sight->time));
        WarPoisonCloudComponent* cloud = we_getPoisonCloudComponent(gContext, e);
        if (cloud)
            textAdd(t, "Q slot=%d %08x,%08x %08x %08x\n", i, fbits(cloud->tile.x), fbits(cloud->tile.y), fbits(cloud->time),
                    fbits(cloud->damageTime));
        if (wu_isUnit(e))
        {
            WarSpriteComponent* sprite = we_getSpriteComponent(gContext, e);
            textAdd(t, "K %d spr=%d\n", e->id, sprite ? sprite->resourceIndex : -1);
        }
    }
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* la scelta delle entita'                                                                                            */
/* ------------------------------------------------------------------------------------------------------------------ */

static bool fAlive(WarEntity* e)
{
    return !wst_isDead(gContext, e) && !wst_isGoingToDie(gContext, e) && !wst_isCollapsing(gContext, e) &&
           !wst_isGoingToCollapse(gContext, e);
}

static bool fOwnDude(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player == 0 && wu_isDudeUnit(gContext, e) && fAlive(e);
}

static bool fOwnWorker(WarEntity* e)
{
    return fOwnDude(e) && wu_isWorkerUnit(gContext, e) && !wst_isInsideBuilding(gContext, e);
}

static bool fOwnWarrior(WarEntity* e)
{
    return fOwnDude(e) && wu_isWarriorUnit(gContext, e);
}

static bool fOwnConjurer(WarEntity* e)
{
    return fOwnDude(e) && wu_isConjurerOrWarlockUnit(gContext, e);
}

static bool fOwnCleric(WarEntity* e)
{
    return fOwnDude(e) && wu_isClericOrNecrolyteUnit(gContext, e);
}

static bool fOwnBuilding(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player == 0 && wu_isBuildingUnit(gContext, e) && fAlive(e);
}

static bool fOwnTownHall(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player == 0 && u->type == WAR_UNIT_TOWNHALL_HUMANS && fAlive(e);
}

static bool fEnemy(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player == 1 && fAlive(e);
}

static bool fEnemyBuilding(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player == 1 && wu_isBuildingUnit(gContext, e) && fAlive(e);
}

static bool fAnyLive(WarEntity* e)
{
    WarUnitComponent* u = we_getUnitComponent(gContext, e);
    return u && u->player != 4 && fAlive(e);
}

static bool fCorpse(WarEntity* e)
{
    return we_getUnitComponent(gContext, e) && wu_isCorpseUnit(gContext, e);
}

/* il remake si ferma su un assert se una entita' selezionata non esiste piu': lo scenario la toglie prima di ogni passo */
static void fPrune(void)
{
    WarEntityIdList* sel = &gMap->selectedEntities;
    for (s32 i = sel->count - 1; i >= 0; i--)
        if (!we_findEntity(gContext, sel->items[i]))
            WarEntityIdListRemoveAt(sel, i);
}

static void fSelectMany(bool (*pred)(WarEntity*), u32 max)
{
    u32 n = 1 + scriptBelow(max);
    WarEntityList list;
    WarEntityListInit(&list, wm_frameAllocator());
    for (u32 i = 0; i < n; i++)
    {
        WarEntity* e = pickWhere(pred);
        if (e)
            WarEntityListAdd(&list, e);
    }
    updateSelectionFromList(gContext, &list);
    WarEntityListFree(&list);
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* i clic                                                                                                             */
/* ------------------------------------------------------------------------------------------------------------------ */

static void fClick(WarUnitCommandType type, vec2 point, bool shift)
{
    WarInput* in = &gContext->input;
    gMap->commandState.command.type = type;
    /* la vista non e' in alto a sinistra (la pioggia di fuoco parte da sopra la vista): il punto dello schermo e' quello della mappa meno la vista */
    in->pos = vec2f(point.x - gMap->camera.viewport.x, point.y - gMap->camera.viewport.y);
    in->buttons[WAR_MOUSE_LEFT].justPressed = true;
    in->keys[WAR_KEY_SHIFT].held = shift;
    wcmd_executeCommand(gContext);
    in->buttons[WAR_MOUSE_LEFT].justPressed = false;
    in->keys[WAR_KEY_SHIFT].held = false;
    gMap->commandState.command.type = WAR_COMMAND_NONE;
}

static void fRightClick(vec2 point, bool shift)
{
    WarInput* in = &gContext->input;
    gMap->commandState.command.type = WAR_COMMAND_NONE;
    /* la vista non e' in alto a sinistra (la pioggia di fuoco parte da sopra la vista): il punto dello schermo e' quello della mappa meno la vista */
    in->pos = vec2f(point.x - gMap->camera.viewport.x, point.y - gMap->camera.viewport.y);
    in->buttons[WAR_MOUSE_RIGHT].justPressed = true;
    in->keys[WAR_KEY_SHIFT].held = shift;
    updateCommandFromRightClick(gContext);
    in->buttons[WAR_MOUSE_RIGHT].justPressed = false;
    in->keys[WAR_KEY_SHIFT].held = false;
}

static vec2 fRandomPoint(void)
{
    s32 x = 64 + (s32)scriptBelow(880);
    s32 y = 64 + (s32)scriptBelow(880);
    return vec2i(x, y);
}

static vec2 fTilePoint(s32 x, s32 y)
{
    return wmap_tileToMapCoordinatesV(vec2i(x, y), true);
}

static s32 fCountType(WarUnitType type)
{
    s32 count = 0;
    WarEntityList* units = we_getEntitiesOfType(gContext, WAR_ENTITY_TYPE_UNIT);
    for (s32 i = 0; i < units->count; i++)
        if (wu_isUnitOfType(gContext, units->items[i], type))
            count++;
    return count;
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* le operazioni                                                                                                      */
/* ------------------------------------------------------------------------------------------------------------------ */

static void fOpSelDudes(void) { fSelectMany(fOwnDude, 5); }
static void fOpSelWarriors(void) { fSelectMany(fOwnWarrior, 4); }
static void fOpSelWorkers(void) { fSelectMany(fOwnWorker, 3); }

static void fOpMove(void)
{
    bool shift = scriptBelow(4) == 0;
    vec2 p = fRandomPoint();
    fClick(WAR_COMMAND_MOVE, p, shift);
}

static void fOpStop(void)
{
    gMap->commandState.command.type = WAR_COMMAND_STOP;
    wcmd_executeCommand(gContext);
    gMap->commandState.command.type = WAR_COMMAND_NONE;
}

/* DIFETTO DEL REMAKE NON CONSERVATO: l'attacco di un punto (anche quello di un bersaglio che non occupa piu' la casella) e'
   dato a ogni unita' propria, edifici compresi, e wst_updateAttackState si ferma su un assert per un edificio (non ha
   statistiche di unita'). Ogni attacco si ordina ai soli guerrieri (in Delphi l'edificio non riceve l'ordine) */
static void fOpAttackUnit(void)
{
    fSelectMany(fOwnWarrior, 4);
    WarEntity* e = pickWhere(fEnemy);
    if (!e)
        return;
    fClick(WAR_COMMAND_ATTACK, wu_getUnitCenterPosition(gContext, e), false);
}

/* DIFETTO DEL REMAKE NON CONSERVATO: un lavoratore a cui si ordina di attaccare un muro o una casella di foresta "segue"
   un'entita' senza posizione e wst_updateFollowState si ferma su un assert. Gli attacchi a un punto e al muro si ordinano ai
   soli guerrieri (in Delphi il lavoratore non riceve l'ordine) */
static void fOpAttackPoint(void)
{
    fSelectMany(fOwnWarrior, 4);
    vec2 p = fRandomPoint();
    fClick(WAR_COMMAND_ATTACK, p, false);
}

static bool fWallPoint(vec2* point)
{
    WarWallComponent* walls = we_getWallComponent(gContext, gWallEntity);
    u32 index = scriptBelow(walls->pieces.count > 0 ? (u32)walls->pieces.count : 1u);
    if (walls->pieces.count == 0)
        return false;
    *point = fTilePoint(walls->pieces.items[index].tilex, walls->pieces.items[index].tiley);
    return true;
}

static void fOpAttackWall(void)
{
    fSelectMany(fOwnWarrior, 4);
    vec2 p;
    if (fWallPoint(&p))
        fClick(WAR_COMMAND_ATTACK, p, false);
}

static bool fMinePoint(vec2* point)
{
    WarEntity* mine = we_findEntity(gContext, gFullMine);
    if (!mine)
        return false;
    *point = wu_getUnitCenterPosition(gContext, mine);
    return true;
}

static bool fTreePoint(vec2* point)
{
    u32 pick = scriptBelow(40);
    WarEntity* forest = we_findEntity(gContext, gFullForest);
    if (!forest)
        return false;
    WarForestComponent* fc = we_getForestComponent(gContext, forest);
    if (fc->trees.count == 0)
        return false;
    WarTree* tree = &fc->trees.items[pick % (u32)fc->trees.count];
    *point = fTilePoint(tree->tilex, tree->tiley);
    return true;
}

static void fOpHarvestMine(void)
{
    vec2 p;
    if (fMinePoint(&p))
        fClick(WAR_COMMAND_HARVEST, p, false);
}

static void fOpHarvestTree(void)
{
    vec2 p;
    if (fTreePoint(&p))
        fClick(WAR_COMMAND_HARVEST, p, false);
}

/* la consegna senza bersaglio cerca il municipio della razza di ogni unita' e il remake si ferma su un assert se non c'e':
   si ordina ai soli lavoratori e solo se ci sono i due municipi */
static void fOpDeliver(void)
{
    fSelectMany(fOwnWorker, 3);
    if (fCountType(WAR_UNIT_TOWNHALL_HUMANS) == 0 || fCountType(WAR_UNIT_TOWNHALL_ORCS) == 0)
        return;
    gMap->commandState.command.type = WAR_COMMAND_DELIVER;
    wcmd_executeCommand(gContext);
    gMap->commandState.command.type = WAR_COMMAND_NONE;
}

static void fOpRepair(void)
{
    WarEntity* b = pickWhere(fOwnBuilding);
    if (!b)
        return;
    fClick(WAR_COMMAND_REPAIR, wu_getUnitCenterPosition(gContext, b), false);
}

static void fOpRight(void)
{
    fSelectMany(fOwnDude, 3);
    u32 kind = scriptBelow(7);
    bool shift = scriptBelow(4) == 0;
    vec2 p = fRandomPoint();
    WarEntity* e = NULL;
    switch (kind)
    {
        case 1: e = pickWhere(fEnemy); break;
        /* DIFETTO DEL REMAKE NON CONSERVATO: "segui" e' dato a ogni unita' propria, edifici compresi, e lo stato di movimento di
           un edificio si ferma su un assert (non ha statistiche di unita'): il clic destro si da' alle sole unita' mobili
           (fSelectMany all'inizio dell'operazione) */
        case 2: e = pickWhere(fOwnDude); break;
        case 3: fMinePoint(&p); break;
        case 4: fTreePoint(&p); break;
        case 5: e = pickWhere(fOwnTownHall); break;
        case 6: fWallPoint(&p); break;
        default: break;
    }
    if (e)
        p = wu_getUnitCenterPosition(gContext, e);
    fRightClick(p, shift);
}

static void fOpBuild(void)
{
    WarEntity* worker = pickWhere(fOwnWorker);
    u32 typeIndex = scriptBelow(16);
    u32 row = scriptBelow(4);
    if (!worker)
        return;
    WarUnitType buildingType = kBuildTypes[typeIndex];
    const WarUnitData* data = wu_getUnitData(buildingType);
    vec2 workerTile = wu_getUnitCenterTile(gContext, worker);
    s32 tx = (s32)workerTile.x + 1;
    s32 ty = MAX((s32)workerTile.y - (s32)(row % (u32)data->sizey), 0);
    selectOnly(worker);
    wcmd_buildBuilding(gContext, (WarUnitCommandType)(WAR_COMMAND_BUILD_FARM_HUMANS + typeIndex), buildingType);
    fClick(gMap->commandState.command.type, fTilePoint(tx, ty), false);
}

static void fOpWallOrRoad(bool wall)
{
    WarEntity* th = pickWhere(fOwnTownHall);
    u32 nearRoll = scriptBelow(100);
    u32 dir = scriptBelow(4);
    s32 x = 6 + (s32)scriptBelow(40);
    s32 y = (wall ? 30 : 42) + (s32)scriptBelow(8);
    static const s32 dx[4] = { 0, 1, 0, -1 };
    static const s32 dy[4] = { -1, 0, 1, 0 };
    if (!th)
        return;
    if (nearRoll < 70)
    {
        if (wall)
        {
            WarWallComponent* walls = we_getWallComponent(gContext, gWallEntity);
            if (walls->pieces.count > 0)
            {
                WarWallPiece* last = &walls->pieces.items[walls->pieces.count - 1];
                x = last->tilex + dx[dir];
                y = last->tiley + dy[dir];
            }
        }
        else
        {
            WarRoadComponent* road = we_getRoadComponent(gContext, gRoadEntity);
            if (road->pieces.count > 0)
            {
                WarRoadPiece* last = &road->pieces.items[road->pieces.count - 1];
                x = last->tilex + dx[dir];
                y = last->tiley + dy[dir];
            }
        }
    }
    x = CLAMP(x, 0, MAP_TILES_WIDTH - 1);
    y = CLAMP(y, 0, MAP_TILES_HEIGHT - 1);
    selectOnly(th);
    fClick(wall ? WAR_COMMAND_BUILD_WALL : WAR_COMMAND_BUILD_ROAD, fTilePoint(x, y), false);
}

static void fOpWall(void) { fOpWallOrRoad(true); }
static void fOpRoad(void) { fOpWallOrRoad(false); }

static void fOpGroup(void)
{
    u32 g = scriptBelow(MAX_SELECTION_GROUPS);
    bool store = scriptBelow(3) == 0;
    WarInput* in = &gContext->input;
    in->keys[WAR_KEY_1 + g].justPressed = true;
    in->keys[WAR_KEY_CTRL].held = store;
    updateSelectionGroups(gContext);
    in->keys[WAR_KEY_1 + g].justPressed = false;
    in->keys[WAR_KEY_CTRL].held = false;
}

static void fOpHurt(void)
{
    WarEntity* e = pickWhere(fAnyLive);
    s32 minDamage = (s32)scriptBelow(40);
    s32 rndDamage = (s32)scriptBelow(60);
    if (!e)
        return;
    we_takeDamage(gContext, e, minDamage, rndDamage);
}

/* il punto d'ingresso dei comandi dell'IA (#196): lo stesso ordine di addestramento, con la causa dell'IA */
static void fOpAi(void)
{
    WarEntity* b = pickWhere(fEnemyBuilding);
    if (!b)
        return;
    WarUnitComponent* unit = we_getUnitComponent(gContext, b);
    WarUnitType type;
    if (unit->type == WAR_UNIT_TOWNHALL_ORCS) type = WAR_UNIT_PEON;
    else if (unit->type == WAR_UNIT_BARRACKS_ORCS) type = WAR_UNIT_GRUNT;
    else return;
    if (wst_canSubmitTransition(gContext, b, WAR_INTERRUPT_AI_ORDER))
    {
        WarPlayerInfo* player = wu_getOwningPlayer(gContext, b);
        const WarUnitStats* stats = wu_getUnitStats(type);
        if (we_checkFarmFood(gContext, player) && we_enoughPlayerResources(gContext, player, stats->goldCost, stats->woodCost))
        {
            WarStateTrain* train = wst_createTrainState(gContext, b, type, (f32)stats->buildTime, stats->goldCost, stats->woodCost, NULL);
            wst_resetState(gContext, b, (WarStateBase*)train, WAR_TRANSITION_CAUSE_AI_ORDER);
        }
    }
}

/* gli incantesimi */

static void fOpSummon(void)
{
    fSelectMany(fOwnConjurer, 2);
    u32 k = scriptBelow(4);
    /* la piscina delle entita' e' finita e il remake non lo controlla: non si evoca quando e' quasi piena */
    if (gMap->entityManager.entityCount > 800)
        return;
    gMap->commandState.command.type = (WarUnitCommandType)(WAR_COMMAND_SUMMON_SPIDER + k);
    wcmd_executeCommand(gContext);
    gMap->commandState.command.type = WAR_COMMAND_NONE;
}

static vec2 fEnemyOrRandomPoint(void)
{
    u32 kind = scriptBelow(3);
    vec2 p = fRandomPoint();
    WarEntity* e = pickWhere(fEnemy);
    if (kind != 0 && e)
        p = wu_getUnitCenterPosition(gContext, e);
    return p;
}

static void fOpRain(void)
{
    fSelectMany(fOwnConjurer, 2);
    vec2 p = fEnemyOrRandomPoint();
    if (gMap->entityManager.entityCount > 800)
        return;
    fClick(WAR_COMMAND_SPELL_RAIN_OF_FIRE, p, false);
}

static void fOpPoison(void)
{
    fSelectMany(fOwnConjurer, 2);
    vec2 p = fEnemyOrRandomPoint();
    fClick(WAR_COMMAND_SPELL_POISON_CLOUD, p, false);
}

static void fOpOnFriend(WarUnitCommandType type)
{
    fSelectMany(fOwnCleric, 2);
    WarEntity* e = pickWhere(fOwnDude);
    if (!e)
        return;
    fClick(type, wu_getUnitCenterPosition(gContext, e), false);
}

static void fOpHeal(void) { fOpOnFriend(WAR_COMMAND_SPELL_HEALING); }
static void fOpInvisibility(void) { fOpOnFriend(WAR_COMMAND_SPELL_INVISIBILITY); }
static void fOpUnholy(void) { fOpOnFriend(WAR_COMMAND_SPELL_UNHOLY_ARMOR); }

static void fOpRaise(void)
{
    fSelectMany(fOwnCleric, 2);
    vec2 p = fRandomPoint();
    WarEntity* corpse = pickWhere(fCorpse);
    if (corpse)
        p = wu_getUnitCenterPosition(gContext, corpse);
    if (gMap->entityManager.entityCount > 800)
        return;
    fClick(WAR_COMMAND_SPELL_RAISE_DEAD, p, false);
}

static void fOpSight(void)
{
    fSelectMany(fOwnCleric, 2);
    vec2 p = fRandomPoint();
    fClick(WAR_COMMAND_SPELL_FAR_SIGHT, p, false);
}

/* il mana torna pieno a chi lancia (la rigenerazione vera e' di un punto al secondo: gli scenari durano poco) */
static void fOpMana(void)
{
    WarEntity* e = pickWhere(fOwnDude);
    if (!e)
        return;
    WarUnitComponent* unit = we_getUnitComponent(gContext, e);
    if (wu_isMagicUnit(gContext, e) && !wu_isSummonUnit(gContext, e))
        unit->mana = unit->maxMana;
}

typedef struct { void (*op)(void); u16 weight[3]; } FullOp;
static const FullOp kFullOps[] = {
    /*                         comandi incantesimi tutto */
    { fOpSelDudes,           {  40,  10,  25 } },
    { fOpSelWarriors,        {  30,  10,  20 } },
    { fOpSelWorkers,         {  30,   0,  15 } },
    { fOpMove,               {  25,   6,  12 } },
    { fOpStop,               {   6,   2,   3 } },
    { fOpAttackUnit,         {  20,  10,  12 } },
    { fOpAttackPoint,        {   8,   0,   4 } },
    { fOpAttackWall,         {  10,   0,   5 } },
    { fOpHarvestMine,        {  12,   0,   8 } },
    { fOpHarvestTree,        {  12,   0,   8 } },
    { fOpDeliver,            {   6,   0,   3 } },
    { fOpRepair,             {   8,   0,   4 } },
    { fOpRight,              {  30,   4,  14 } },
    { cOpTrain,              {   6,   0,   4 } },
    { cOpUpgrade,            {   3,   0,   2 } },
    { cOpCancel,             {   3,   0,   2 } },
    { fOpBuild,              {   5,   0,   3 } },
    { fOpWall,               {   5,   0,   3 } },
    { fOpRoad,               {   5,   0,   3 } },
    { fOpGroup,              {  10,   2,   5 } },
    { fOpHurt,               {  15,  25,  18 } },
    { cOpDamageBuilding,     {   5,   0,   4 } },
    { cOpWallDamage,         {   2,   0,   1 } },
    { fOpAi,                 {   5,   0,   3 } },
    { opEconomy,             {   2,   0,   1 } },
    { opRemove,              {   1,   1,   1 } },
    { fOpSummon,             {   0,   8,   4 } },
    { fOpRain,               {   0,  10,   5 } },
    { fOpPoison,             {   0,   8,   4 } },
    { fOpHeal,               {   0,  10,   5 } },
    { fOpInvisibility,       {   0,   8,   4 } },
    { fOpUnholy,             {   0,   8,   4 } },
    { fOpRaise,              {   0,  10,   5 } },
    { fOpSight,              {   0,   8,   4 } },
    { fOpMana,               {   0,  10,   5 } }
};

static void fullScriptStep(void)
{
    fPrune();
    u32 r = scriptBelow(1000);
    u32 acc = 0;
    for (s32 i = 0; i < (s32)arrayLength(kFullOps); i++)
    {
        acc += kFullOps[i].weight[gFullMode];
        if (r < acc)
        {
            kFullOps[i].op();
            return;
        }
    }
}

/* ------------------------------------------------------------------------------------------------------------------ */
/* il mondo                                                                                                           */
/* ------------------------------------------------------------------------------------------------------------------ */

static const BaseBuilding kFullBase[] = {
    { WAR_UNIT_TOWNHALL_HUMANS, 6, 6 }, { WAR_UNIT_BARRACKS_HUMANS, 11, 6 }, { WAR_UNIT_CHURCH, 16, 6 },
    { WAR_UNIT_TOWER_HUMANS, 21, 6 }, { WAR_UNIT_FARM_HUMANS, 26, 6 }, { WAR_UNIT_FARM_HUMANS, 29, 6 },
    { WAR_UNIT_FARM_HUMANS, 32, 6 }, { WAR_UNIT_FARM_HUMANS, 35, 6 }, { WAR_UNIT_LUMBERMILL_HUMANS, 6, 11 },
    { WAR_UNIT_BLACKSMITH_HUMANS, 11, 11 }
};
static const BaseBuilding kFullDudes[] = {
    { WAR_UNIT_PEASANT, 6, 18 }, { WAR_UNIT_PEASANT, 8, 18 }, { WAR_UNIT_PEASANT, 10, 18 }, { WAR_UNIT_PEON, 12, 18 },
    { WAR_UNIT_FOOTMAN, 14, 18 }, { WAR_UNIT_FOOTMAN, 16, 18 }, { WAR_UNIT_ARCHER, 18, 18 }, { WAR_UNIT_KNIGHT, 20, 18 },
    { WAR_UNIT_CATAPULT_HUMANS, 22, 18 }, { WAR_UNIT_CONJURER, 6, 21 }, { WAR_UNIT_CONJURER, 8, 21 },
    { WAR_UNIT_WARLOCK, 10, 21 }, { WAR_UNIT_WARLOCK, 12, 21 }, { WAR_UNIT_CLERIC, 14, 21 }, { WAR_UNIT_CLERIC, 16, 21 },
    { WAR_UNIT_NECROLYTE, 18, 21 }, { WAR_UNIT_NECROLYTE, 20, 21 }
};
static const BaseBuilding kFullEnemyBase[] = {
    { WAR_UNIT_TOWNHALL_ORCS, 40, 30 }, { WAR_UNIT_BARRACKS_ORCS, 45, 30 }, { WAR_UNIT_FARM_ORCS, 40, 35 },
    { WAR_UNIT_FARM_ORCS, 43, 35 }
};
static const BaseBuilding kFullEnemyDudes[] = {
    { WAR_UNIT_GRUNT, 30, 26 }, { WAR_UNIT_GRUNT, 32, 26 }, { WAR_UNIT_GRUNT, 34, 26 }, { WAR_UNIT_SPEARMAN, 36, 26 },
    { WAR_UNIT_PEON, 38, 26 }, { WAR_UNIT_RAIDER, 30, 28 }
};

static void fullInit(u32 seed, int mode)
{
    worldInit(seed ^ 0xC3C3C3C3u, seed * 2654435761u + 4242u + (u32)mode * 977u);
    gAudioMix = 0;
    gConstructionDump = 1;
    gExtended = 1;
    gFullDump = 1;
    gTileStub = true;
    gTileWrites = 0;
    gTileHash = 2166136261u;
    gFullMode = mode;
    gFullDelta = kFullDeltas[seed % 4];
    gSpawnedCount = 0;
    gMap->ui.mapPanel = rectf(0, 0, 1024, 1024);
    gMap->camera.viewport = rectf(0, (f32)(16 * (s32)(seed % 5)), 320, 200);
    gMap->players[0].gold = 3000 + (s32)scriptBelow(6000);
    gMap->players[0].wood = 2000 + (s32)scriptBelow(4000);

    /* la mappa crea prima la foresta, poi la strada, il muro (con il suo stato) e le rovine, poi le unita' */
    WarEntity* forest = gatherForest(46, 8, 6, 5);
    gFullForest = forest->id;
    gRoadEntity = we_createRoad(gContext);
    gMap->editing.road = gRoadEntity;
    gWallEntity = we_createWall(gContext);
    we_addStateMachineComponent(gContext, gWallEntity);
    WarStateIdle* wallIdle = wst_createIdleState(gContext, gWallEntity, false);
    wst_resetState(gContext, gWallEntity, (WarStateBase*)wallIdle, WAR_TRANSITION_CAUSE_INITIALIZATION);
    gMap->editing.wall = gWallEntity;
    gRuinEntity = we_createRuins(gContext);
    gMap->editing.ruin = gRuinEntity;

    for (s32 i = 0; i < (s32)arrayLength(kFullBase); i++)
        spawnBuilding(kFullBase[i].type, 0, kFullBase[i].x, kFullBase[i].y);
    s32 amount = 300 + (s32)scriptBelow(400);
    WarEntity* mine = we_createUnit(gContext, CREATE_UNIT_ARGS_INIT(.type = WAR_UNIT_GOLDMINE, .x = 16, .y = 12, .player = 4,
                                                                    .resourceKind = WAR_RESOURCE_GOLD, .amount = (u32)amount));
    we_setInitialIdleState(gContext, mine);
    gFullMine = mine->id;
    for (s32 i = 0; i < (s32)arrayLength(kFullDudes); i++)
        spawnDude(kFullDudes[i].type, 0, kFullDudes[i].x, kFullDudes[i].y);
    for (s32 i = 0; i < (s32)arrayLength(kFullEnemyBase); i++)
        spawnBuilding(kFullEnemyBase[i].type, 1, kFullEnemyBase[i].x, kFullEnemyBase[i].y);
    for (s32 i = 0; i < (s32)arrayLength(kFullEnemyDudes); i++)
        spawnDude(kFullEnemyDudes[i].type, 1, kFullEnemyDudes[i].x, kFullEnemyDudes[i].y);

    /* un tratto di muro gia' in piedi tra le due basi */
    for (s32 x = 28; x <= 33; x++)
    {
        WarWallPiece* piece = we_addWallPiece(gContext, gWallEntity, x, 23, 0);
        piece->hp = WAR_WALL_MAX_HP;
        piece->maxhp = WAR_WALL_MAX_HP;
    }
    we_determineWallTypes(gContext, gWallEntity);
}

/* il tic intero di wmap_updateMap, nel suo ordine (senza l'interfaccia, la nebbia, l'IA e gli strumenti dell'editor) */
static void tickFull(void (*scriptStep)(void), f32 delta)
{
    if (gTrace)
        fprintf(stderr, "T\n");
    gContext->gameDeltaTime = delta;
    gContext->gameTime += (f64)delta;

    scriptStep();

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

    wgrid_build(gContext);
    updateActions(gContext);
    wanim_updateAnimations(gContext);
    updateProjectiles(gContext);
    updateMagic(gContext);
    updateSpells(gContext);
}

static void runFull(int mode, u32 seed, s32 dumpTic, bool perTic, bool stats)
{
    fullInit(seed, mode);
    s32 cover[WAR_STATE_COUNT] = {0};
    s32 kinds[WAR_ENTITY_TYPE_COUNT] = {0};
    for (s32 tic = 0; tic < FULL_TICS; tic++)
    {
        tickFull(fullScriptStep, gFullDelta);
        for (s32 k = 0; k < WAR_STATE_COUNT; k++)
            if (gMap->entityManager.stateStorage.activeCounts[k] > 0)
                cover[k]++;
        for (s32 i = 1; i < MAX_ENTITIES_COUNT; i++)
        {
            WarEntity* e = &gMap->entityManager.entities[i];
            if (e->id != 0 && e->type < WAR_ENTITY_TYPE_COUNT && kinds[e->type] >= 0)
                kinds[e->type] = -kinds[e->type] - 1;
        }
        for (s32 k = 0; k < WAR_ENTITY_TYPE_COUNT; k++)
            if (kinds[k] < 0)
                kinds[k] = -kinds[k];
        Text text = {0};
        if (perTic || tic == dumpTic)
            dumpWorld(&text, tic);
        if (dumpTic >= 0 && tic == dumpTic)
            printf("%s", text.data);
        else if (perTic)
            printf("%c %u %d %08x %d\n", "OIA"[mode], seed, tic, fnv1a(text.data, text.length), gMap->entityManager.entityCount);
        free(text.data);
    }
    if (stats)
    {
        printf("Q %u states", seed);
        for (s32 k = 0; k < WAR_STATE_COUNT; k++)
            printf(" %d", cover[k]);
        printf(" | entities");
        for (s32 k = 0; k < WAR_ENTITY_TYPE_COUNT; k++)
            printf(" %d", kinds[k]);
        printf(" | audio %u flash %u ents %d draws %u\n", gAudioCount, gFlashCount, gMap->entityManager.entityCount, gGameDraws);
    }
    gConstructionDump = 0;
    gExtended = 0;
    gFullDump = 0;
    gTileStub = false;
    worldFree();
}

/* le tabelle dei comandi: cio' che ogni wcmd_train*, wcmd_upgrade* e wcmd_build* mette nel comando corrente, l'incantesimo di
   ogni comando di incantesimo e le costanti dei comandi */
typedef void (*CommandSetter)(WarContext*, WarEntity*);

static void printCommandTables(void)
{
    static const CommandSetter trains[14] = {
        wcmd_trainFootman, wcmd_trainGrunt, wcmd_trainPeasant, wcmd_trainPeon, wcmd_trainHumanCatapult, wcmd_trainOrcCatapult,
        wcmd_trainKnight, wcmd_trainRaider, wcmd_trainArcher, wcmd_trainSpearman, wcmd_trainConjurer, wcmd_trainWarlock,
        wcmd_trainCleric, wcmd_trainNecrolyte
    };
    static const CommandSetter upgrades[20] = {
        wcmd_upgradeSwords, wcmd_upgradeAxes, wcmd_upgradeHumanShields, wcmd_upgradeOrcsShields, wcmd_upgradeArrows,
        wcmd_upgradeSpears, wcmd_upgradeHorses, wcmd_upgradeWolves, wcmd_upgradeScorpions, wcmd_upgradeSpiders,
        wcmd_upgradeRainOfFire, wcmd_upgradePoisonCloud, wcmd_upgradeWaterElemental, wcmd_upgradeDaemon, wcmd_upgradeHealing,
        wcmd_upgradeRaiseDead, wcmd_upgradeFarSight, wcmd_upgradeDarkVision, wcmd_upgradeInvisibility, wcmd_upgradeUnholyArmor
    };
    static const CommandSetter builds[16] = {
        wcmd_buildFarmHumans, wcmd_buildFarmOrcs, wcmd_buildBarracksHumans, wcmd_buildBarracksOrcs, wcmd_buildChurch,
        wcmd_buildTemple, wcmd_buildTowerHumans, wcmd_buildTowerOrcs, wcmd_buildTownHallHumans, wcmd_buildTownHallOrcs,
        wcmd_buildLumbermillHumans, wcmd_buildLumbermillOrcs, wcmd_buildStable, wcmd_buildKennel, wcmd_buildBlacksmithHumans,
        wcmd_buildBlacksmithOrcs
    };
    worldInit(1, 1);
    WarUnitCommand* command = &gMap->commandState.command;
    printf("# train commands: T command unit building\n");
    for (s32 i = 0; i < 14; i++)
    {
        trains[i](gContext, NULL);
        printf("T %d %d %d\n", (s32)command->type, (s32)command->train.unitToTrain, (s32)command->train.buildingUnit);
    }
    printf("# upgrade commands: U command upgrade\n");
    for (s32 i = 0; i < 20; i++)
    {
        upgrades[i](gContext, NULL);
        printf("U %d %d\n", (s32)command->type, (s32)command->upgrade.upgradeToBuild);
    }
    printf("# build commands: B command building\n");
    for (s32 i = 0; i < 16; i++)
    {
        builds[i](gContext, NULL);
        printf("B %d %d\n", (s32)command->type, (s32)command->build.buildingToBuild);
    }
    printf("# spell commands: S command spell\n");
    for (s32 c = WAR_COMMAND_SPELL_HEALING; c <= WAR_COMMAND_SUMMON_WATER_ELEMENTAL; c++)
        printf("S %d %d\n", c, (s32)wu_getCommandMapping((WarUnitCommandType)c)->mappedType);
    printf("# constants: K roadGold roadWood maxSelected groups poisonDamage normalSpell cancel\n");
    printf("K %d %d %d %d %d %d %d\n", WAR_ROAD_GOLD_COST, WAR_ROAD_WOOD_COST, MAX_SELECTED_ENTITIES_COUNT, MAX_SELECTION_GROUPS,
           POISON_CLOUD_DAMAGE, (s32)WAR_NORMAL_SPELL, (s32)WAR_COMMAND_CANCEL);
    printf("# basic commands: C none move stop harvest deliver repair attack buildBasic buildAdvanced buildRoad buildWall\n");
    printf("C %d %d %d %d %d %d %d %d %d %d %d\n", (s32)WAR_COMMAND_NONE, (s32)WAR_COMMAND_MOVE, (s32)WAR_COMMAND_STOP,
           (s32)WAR_COMMAND_HARVEST, (s32)WAR_COMMAND_DELIVER, (s32)WAR_COMMAND_REPAIR, (s32)WAR_COMMAND_ATTACK,
           (s32)WAR_COMMAND_BUILD_BASIC, (s32)WAR_COMMAND_BUILD_ADVANCED, (s32)WAR_COMMAND_BUILD_ROAD, (s32)WAR_COMMAND_BUILD_WALL);
    worldFree();
}

static int fullModeOf(const char* name)
{
    if (strcmp(name, "commands") == 0) return 0;
    if (strcmp(name, "spells") == 0) return 1;
    if (strcmp(name, "full") == 0) return 2;
    return -1;
}
