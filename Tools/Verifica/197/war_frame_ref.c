/*
  Issue #197: harness di riferimento per il disegno e l'interfaccia di Libs\War (scene, UI immediata, pannello, mappa).

  Il remake in C (acoto87/war1, zlib License, (C) 2019 Alejandro Coto Gutierrez) e' una "unity build": src\war1.c include
  tutti i .c. Qui si include war1.c INTERO e ORIGINALE (con main rinominato), e lo si collega alla SDL3 VERA
  (deps\lib\win32\SDL3.dll): il rasterizzatore e' il renderer software di SDL su una SDL_Surface RGBA32 di 320 x 200 (la
  stessa risoluzione logica del gioco), senza finestra: e' deterministico e da' i pixel veri.

  Cio' che e' nostro (versione modificata del remake solo per far girare quel codice senza finestra, audio e tempo di parete):
    - l'inizializzazione (wg_initGame senza finestra ne' audio, con il renderer software; fonts, DATA.WAR);
    - SDL_rand/SDL_randf: il generatore di Warcraft non e' ripetibile, qui e' l'LCG con seme di TWarSeededRandom;
    - il tempo: ogni fotogramma dura 1/60 s (come wg_beginFrame con una durata fissa);
    - l'ingresso: eventi scritti con wg_setInputButton/wg_setInputKey come wg_processGameEvent, da uno script.

  Lo script (stesso file letto dalla prova di Delphi) ha una riga per comando:
    scene blizzard|menu|download         scena (wg_setNextScene con ritardo 0)
    briefing human|orc MAPTYPE           scena del briefing
    campaign human|orc MISSION           mappa della campagna (wmap_createMap)
    custom INDEX                         mappa personalizzata (wmap_createCustomMap con le opzioni predefinite)
    move X Y | lbutton down|up | rbutton down|up | key NAME down|up | text STRINGA
    run N [K]                            N fotogrammi; una riga H ogni K (K = 0: nessuna; predefinito 1)
    hash                                 una riga H del fotogramma corrente
    png FILE | rgba FILE                 scrive il fotogramma
    trace on|off                         scrive ogni chiamata di disegno su stderr
  Uscita: "H n fnv1a32" (n = numero del fotogramma, impronta FNV-1a dei 320 x 200 x 4 byte RGBA).
*/
#include <SDL3/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef Uint32 refu32;

static refu32 gGameState = 1;
static int gTraceOn = 0;

static refu32 lcgNext(refu32* state)
{
    *state = *state * 1664525u + 1013904223u;
    return *state >> 8;
}

static Sint32 war_ref_rand(Sint32 n)
{
    /* per cercare chi estrae: WAR_REF_RNGWHO=1 scrive l'indirizzo di chi chiama (addr2line con una compilazione -g) */
    if (getenv("WAR_REF_RNGWHO"))
        fprintf(stderr, "rand %p %p %p\n", __builtin_return_address(0), __builtin_return_address(1), __builtin_return_address(2));
    return n <= 0 ? 0 : (Sint32)(lcgNext(&gGameState) % (refu32)n);
}

static float war_ref_randf(void)
{
    return (float)war_ref_rand(16777216) / 16777216.0f;
}

#define SDL_rand war_ref_rand
#define SDL_randf war_ref_randf

/* ogni chiamata di disegno si scrive prima di eseguirla (trace on) */
static bool trace_RenderTexture(SDL_Renderer* r, SDL_Texture* t, const SDL_FRect* s, const SDL_FRect* d)
{
    if (gTraceOn)
    {
        Uint8 a = 0, cr = 0, cg = 0, cb = 0; SDL_BlendMode bm = 0;
        SDL_GetTextureAlphaMod(t, &a); SDL_GetTextureColorMod(t, &cr, &cg, &cb); SDL_GetTextureBlendMode(t, &bm);
        fprintf(stderr, "T %p %.9g %.9g %.9g %.9g > %.9g %.9g %.9g %.9g a%d c%d,%d,%d b%u\n", (void*)t,
                s ? s->x : 0, s ? s->y : 0, s ? s->w : 0, s ? s->h : 0, d ? d->x : 0, d ? d->y : 0, d ? d->w : 0, d ? d->h : 0,
                a, cr, cg, cb, (unsigned)bm);
    }
    return SDL_RenderTexture(r, t, s, d);
}
static bool trace_RenderTextureRotated(SDL_Renderer* r, SDL_Texture* t, const SDL_FRect* s, const SDL_FRect* d, double angle,
                                       const SDL_FPoint* c, SDL_FlipMode f)
{
    if (gTraceOn)
    {
        Uint8 a = 0, cr = 0, cg = 0, cb = 0; SDL_BlendMode bm = 0;
        SDL_GetTextureAlphaMod(t, &a); SDL_GetTextureColorMod(t, &cr, &cg, &cb); SDL_GetTextureBlendMode(t, &bm);
        fprintf(stderr, "R %p %.9g %.9g %.9g %.9g > %.9g %.9g %.9g %.9g a%d c%d,%d,%d b%u f%d\n", (void*)t,
                s ? s->x : 0, s ? s->y : 0, s ? s->w : 0, s ? s->h : 0, d ? d->x : 0, d ? d->y : 0, d ? d->w : 0, d ? d->h : 0,
                a, cr, cg, cb, (unsigned)bm, (int)f);
    }
    return SDL_RenderTextureRotated(r, t, s, d, angle, c, f);
}
static bool trace_RenderFillRect(SDL_Renderer* r, const SDL_FRect* d)
{
    if (gTraceOn)
    {
        Uint8 cr, cg, cb, ca;
        SDL_GetRenderDrawColor(r, &cr, &cg, &cb, &ca);
        fprintf(stderr, "F %.9g %.9g %.9g %.9g c%d,%d,%d,%d\n", d->x, d->y, d->w, d->h, cr, cg, cb, ca);
    }
    return SDL_RenderFillRect(r, d);
}
static bool trace_RenderRect(SDL_Renderer* r, const SDL_FRect* d)
{
    if (gTraceOn)
    {
        Uint8 cr, cg, cb, ca;
        SDL_GetRenderDrawColor(r, &cr, &cg, &cb, &ca);
        fprintf(stderr, "S %.9g %.9g %.9g %.9g c%d,%d,%d,%d\n", d->x, d->y, d->w, d->h, cr, cg, cb, ca);
    }
    return SDL_RenderRect(r, d);
}
static bool trace_RenderLine(SDL_Renderer* r, float x1, float y1, float x2, float y2)
{
    if (gTraceOn)
    {
        Uint8 cr, cg, cb, ca;
        SDL_GetRenderDrawColor(r, &cr, &cg, &cb, &ca);
        fprintf(stderr, "L %.9g %.9g %.9g %.9g c%d,%d,%d,%d\n", x1, y1, x2, y2, cr, cg, cb, ca);
    }
    return SDL_RenderLine(r, x1, y1, x2, y2);
}
#define SDL_RenderTexture trace_RenderTexture
#define SDL_RenderTextureRotated trace_RenderTextureRotated
#define SDL_RenderFillRect trace_RenderFillRect
#define SDL_RenderRect trace_RenderRect
#define SDL_RenderLine trace_RenderLine

#define main war_unused_main
#include "war1.c"
#undef main

/* ------------------------------------------------------------------------------------------------------------------ */

#define FIXED_DT (1.0f / 60.0f)

static SDL_Surface* gSurface;

static bool initHeadless(WarContext* context, int argc, char** argv)
{
    if (!wm_allocInit(PERM_SIZE, FRAME_SIZE, AUDIO_SIZE)) return false;
    wlog_init(SDL_LOG_PRIORITY_ERROR);
    if (!SDL_Init(0)) return false;
    memset(context, 0, sizeof(WarContext));
    if (!wg_parseCommandLine(context, argc, argv)) return false;

    context->globalScale = 3;
    context->globalSpeed = 1;
    context->originalWindowWidth = 320;
    context->originalWindowHeight = 200;
    context->windowWidth = 960;
    context->windowHeight = 600;
    wstr_assignCString(&context->windowTitle, "War 1");

    gSurface = SDL_CreateSurface(320, 200, SDL_PIXELFORMAT_RGBA32);
    context->renderer = SDL_CreateSoftwareRenderer(gSurface);
    if (!context->renderer) return false;
    if (!SDL_SetRenderLogicalPresentation(context->renderer, 320, 200, SDL_LOGICAL_PRESENTATION_INTEGER_SCALE)) return false;

    wr_init(context);
    context->transitionEndRealTime = 0.0;
    context->cheatsEnabled = true;
    context->__mutex = SDL_CreateMutex();

    context->fontSprites[0] = wfont_loadFontSprite(context, wsv_fromCString("./war1_font_1.png"));
    context->fontSprites[1] = wfont_loadFontSprite(context, wsv_fromCString("./war1_font_2.png"));
    if (!wg_loadDataFile(context)) return false;
    wact_initUnitActionDefs();

    context->realTime = 0.0;
    context->realDeltaTime = 0.0f;
    context->gameTime = 0.0;
    context->gameDeltaTime = 0.0f;
    return true;
}

/* wg_beginFrame con una durata fissa */
static void beginFrame(WarContext* context)
{
    context->realDeltaTime = FIXED_DT;
    context->realTime += context->realDeltaTime;

    f32 gameSpeedScale = context->globalSpeed;
    if (context->map)
    {
        WarMap* map = context->map;
        f32 speedScale = 1.0f;
        if (map->settings.gameSpeed < WAR_SPEED_NORMAL)
            speedScale = 1.0f - (WAR_SPEED_NORMAL - map->settings.gameSpeed) * 0.25f;
        else if (map->settings.gameSpeed > WAR_SPEED_NORMAL)
            speedScale = 1.0f + (map->settings.gameSpeed - WAR_SPEED_NORMAL) * 0.5f;
        gameSpeedScale *= speedScale;
    }
    if (context->paused)
        context->gameDeltaTime = 0.0f;
    else
    {
        context->gameDeltaTime = context->realDeltaTime * gameSpeedScale;
        context->gameTime += context->gameDeltaTime;
    }
}

static refu32 fnv1a(const Uint8* p, size_t n)
{
    refu32 h = 2166136261u;
    for (size_t i = 0; i < n; i++) { h ^= p[i]; h *= 16777619u; }
    return h;
}

static SDL_Surface* gLast;

static void grabFrame(WarContext* context)
{
    if (gLast) SDL_DestroySurface(gLast);
    gLast = SDL_RenderReadPixels(context->renderer, NULL);
}

static refu32 frameHash(void)
{
    SDL_Surface* s = gLast;
    refu32 h = 2166136261u;
    for (int y = 0; y < s->h; y++)
    {
        const Uint8* row = (const Uint8*)s->pixels + (size_t)y * s->pitch;
        for (int x = 0; x < s->w * 4; x++) { h ^= row[x]; h *= 16777619u; }
    }
    return h;
}

typedef struct { const char* name; WarKeys key; } KeyName;

static WarKeys keyFromName(const char* n)
{
    static const KeyName table[] = {
        {"enter", WAR_KEY_ENTER}, {"esc", WAR_KEY_ESC}, {"space", WAR_KEY_SPACE}, {"tab", WAR_KEY_TAB},
        {"backspace", WAR_KEY_BACKSPACE}, {"left", WAR_KEY_LEFT}, {"right", WAR_KEY_RIGHT}, {"up", WAR_KEY_UP},
        {"down", WAR_KEY_DOWN}, {"shift", WAR_KEY_SHIFT}, {"ctrl", WAR_KEY_CTRL}, {"alt", WAR_KEY_ALT},
        {"a", WAR_KEY_A}, {"b", WAR_KEY_B}, {"c", WAR_KEY_C}, {"d", WAR_KEY_D}, {"e", WAR_KEY_E}, {"f", WAR_KEY_F},
        {"g", WAR_KEY_G}, {"h", WAR_KEY_H}, {"i", WAR_KEY_I}, {"j", WAR_KEY_J}, {"k", WAR_KEY_K}, {"l", WAR_KEY_L},
        {"m", WAR_KEY_M}, {"n", WAR_KEY_N}, {"o", WAR_KEY_O}, {"p", WAR_KEY_P}, {"q", WAR_KEY_Q}, {"r", WAR_KEY_R},
        {"s", WAR_KEY_S}, {"t", WAR_KEY_T}, {"u", WAR_KEY_U}, {"v", WAR_KEY_V}, {"w", WAR_KEY_W}, {"x", WAR_KEY_X},
        {"y", WAR_KEY_Y}, {"z", WAR_KEY_Z},
        {"0", WAR_KEY_0}, {"1", WAR_KEY_1}, {"2", WAR_KEY_2}, {"3", WAR_KEY_3}, {"4", WAR_KEY_4}, {"5", WAR_KEY_5},
        {"6", WAR_KEY_6}, {"7", WAR_KEY_7}, {"8", WAR_KEY_8}, {"9", WAR_KEY_9},
        {"f1", WAR_KEY_F1}, {"f2", WAR_KEY_F2}, {"f3", WAR_KEY_F3}, {"f4", WAR_KEY_F4}, {"f5", WAR_KEY_F5},
        {"f6", WAR_KEY_F6}, {"f7", WAR_KEY_F7}, {"f8", WAR_KEY_F8}, {"f9", WAR_KEY_F9}, {"f10", WAR_KEY_F10},
        {"f11", WAR_KEY_F11}, {"f12", WAR_KEY_F12},
        {"delete", WAR_KEY_DELETE}, {"home", WAR_KEY_HOME}, {"end", WAR_KEY_END}, {"insert", WAR_KEY_INSERT},
    };
    for (size_t i = 0; i < sizeof(table) / sizeof(table[0]); i++)
        if (strcmp(table[i].name, n) == 0) return table[i].key;
    fprintf(stderr, "tasto sconosciuto: %s\n", n);
    exit(3);
}

static void runFrame(WarContext* context)
{
    /* wg_beginFrame, wg_beginInputFrame; gli eventi dello script sono gia' applicati (vedi sotto: si applicano dopo) */
    beginFrame(context);
    wg_updateGame(context);
    wg_renderGame(context);
    grabFrame(context);
    context->frameCount++;
}

int main(int argc, char** argv)
{
    /* argv[1] = script; il resto = parametri di war1 (--race human --mission 1 ...) per wg_parseCommandLine */
    if (argc < 2) { fprintf(stderr, "uso: war_frame_ref script\n"); return 1; }
    if (getenv("WAR_REF_RNGWHO")) fprintf(stderr, "main %p\n", (void*)main);
    FILE* f = fopen(argv[1], "r");
    if (!f) { fprintf(stderr, "script non trovato\n"); return 1; }

    WarContext* context = (WarContext*)calloc(1, sizeof(WarContext));
    static char* noArgs[] = { "war1" };
    if (!initHeadless(context, 1, noArgs)) { fprintf(stderr, "inizializzazione fallita\n"); return 2; }

    char line[1024];
    while (fgets(line, sizeof(line), f))
    {
        size_t len = strlen(line);
        while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r')) line[--len] = 0;
        if (len == 0 || line[0] == '#') continue;
        char cmd[64] = {0}, a1[256] = {0}, a2[256] = {0};
        sscanf(line, "%63s %255s %255s", cmd, a1, a2);

        if (!strcmp(cmd, "scene"))
        {
            WarSceneType type = !strcmp(a1, "blizzard") ? WAR_SCENE_BLIZZARD : !strcmp(a1, "download") ? WAR_SCENE_DOWNLOAD : WAR_SCENE_MAIN_MENU;
            wg_setNextScene(context, wsc_createScene(context, type), 0.0f);
        }
        else if (!strcmp(cmd, "briefing"))
        {
            WarScene* scene = wsc_createScene(context, WAR_SCENE_BRIEFING);
            scene->briefing.race = !strcmp(a1, "human") ? WAR_RACE_HUMANS : WAR_RACE_ORCS;
            scene->briefing.mapType = (WarCampaignMapType)atoi(a2);
            wg_setNextScene(context, scene, 0.0f);
        }
        else if (!strcmp(cmd, "campaign"))
        {
            WarRace race = !strcmp(a1, "human") ? WAR_RACE_HUMANS : WAR_RACE_ORCS;
            WarCampaignMapType mapType;
            if (!wcamp_tryGetMapType(race, atoi(a2), &mapType)) { fprintf(stderr, "campagna non valida\n"); return 4; }
            context->launch.campaignRace = race;
            WarMap* map = wmap_createMap(context, mapType);
            wg_setNextMap(context, map, 0.0f);
        }
        else if (!strcmp(cmd, "custom"))
        {
            WarMap* map = wmap_createCustomMap(context, atoi(a1), &context->launch.customGame);
            context->launch.customGame = map->customGame;
            wg_setNextMap(context, map, 0.0f);
        }
        else if (!strcmp(cmd, "move"))
        {
            context->input.pos = vec2f((f32)floorf((float)atof(a1)), (f32)floorf((float)atof(a2)));
        }
        else if (!strcmp(cmd, "lbutton") || !strcmp(cmd, "rbutton"))
        {
            wg_setInputButton(context, cmd[0] == 'l' ? WAR_MOUSE_LEFT : WAR_MOUSE_RIGHT, !strcmp(a1, "down"));
        }
        else if (!strcmp(cmd, "key"))
        {
            WarKeys key = keyFromName(a1);
            wg_setInputKey(context, key, !strcmp(a2, "down"));
        }
        else if (!strcmp(cmd, "text"))
        {
            const char* p = strstr(line, "text ") + 5;
            appendCheatTextInput(context, wsv_fromCString(p));
        }
        else if (!strcmp(cmd, "run"))
        {
            int n = atoi(a1);
            int every = a2[0] ? atoi(a2) : 1;
            for (int i = 0; i < n; i++)
            {
                runFrame(context);
                /* le transizioni dei tasti valgono per un solo fotogramma (wg_beginInputFrame del giro dopo) */
                if (every > 0 && (i + 1) % every == 0)
                    printf("H %d %08x\n", context->frameCount, frameHash());
                /* per cercare una differenza: WAR_REF_RNGTRACE=1 scrive lo stato del generatore a ogni fotogramma (non e' nei golden) */
                if (getenv("WAR_REF_RNGTRACE"))
                    printf("D %d %08x\n", context->frameCount, gGameState);
                wg_beginInputFrame(context);
            }
        }
        else if (!strcmp(cmd, "fog"))
        {
            /* prova delle prestazioni: la nebbia spenta (tutta la mappa si disegna) */
            if (context->map) context->map->fowEnabled = !strcmp(a1, "on");
        }
        else if (!strcmp(cmd, "spawn"))
        {
            /* prova delle prestazioni: N fanti del giocatore 0, fermi, su una griglia di tegole di tutta la mappa */
            int n = atoi(a1);
            for (int i = 0; i < n; i++)
            {
                s32 x = 1 + (i * 3) % 62;
                s32 y = 1 + ((i * 3) / 62) * 3 % 62;
                WarEntity* e = we_createUnit(context, CREATE_UNIT_ARGS_INIT(.type = WAR_UNIT_FOOTMAN, .x = x, .y = y, .player = 0, .addToMap = true));
                we_setInitialIdleState(context, e);
            }
        }
        else if (!strcmp(cmd, "unit") && context->map)
        {
            /* parte C (comandi con bersaglio, incantesimi): "unit TIPO SX SY GIOCATORE": un'unita' (numero di WarUnitType) sulla tegola
               sotto il punto SX SY dello schermo, ferma */
            char a3[64] = {0};
            sscanf(line, "%*s %*s %*s %63s", a3);
            vec2 point = wmap_screenToMapCoordinatesV(context, vec2f((f32)atof(a2), (f32)atof(a3)));
            char a4[64] = {0};
            sscanf(line, "%*s %*s %*s %*s %63s", a4);
            vec2 tile = wmap_mapToTileCoordinatesV(point);
            WarEntity* e = we_createUnit(context, CREATE_UNIT_ARGS_INIT(.type = (WarUnitType)atoi(a1), .x = (s32)tile.x, .y = (s32)tile.y, .player = (u8)atoi(a4), .addToMap = true));
            we_setInitialIdleState(context, e);
        }
        else if (!strcmp(cmd, "building") && context->map)
        {
            /* "building TIPO SX SY GIOCATORE": un edificio finito (we_createBuilding) con l'angolo sulla tegola sotto il punto */
            char a3[64] = {0}, a4[64] = {0};
            sscanf(line, "%*s %*s %*s %63s %63s", a3, a4);
            vec2 point = wmap_screenToMapCoordinatesV(context, vec2f((f32)atof(a2), (f32)atof(a3)));
            vec2 tile = wmap_mapToTileCoordinatesV(point);
            we_createBuilding(context, CREATE_UNIT_ARGS_INIT(.type = (WarUnitType)atoi(a1), .x = (s32)tile.x, .y = (s32)tile.y, .player = (u8)atoi(a4), .isGoingToBuild = false));
        }
        else if (!strcmp(cmd, "upgrade") && context->map)
        {
            /* "upgrade INDICE PERMESSO LIVELLO": miglioramento (WarUpgradeType) del giocatore 0 */
            char a3[64] = {0};
            sscanf(line, "%*s %*s %*s %63s", a3);
            WarPlayerInfo* p = &context->map->players[0];
            p->upgrades[atoi(a1) / 2].allowed = (u8)atoi(a2);
            p->upgrades[atoi(a1) / 2].level = (u8)atoi(a3);
        }
        else if (!strcmp(cmd, "feature") && context->map)
        {
            /* "feature INDICE VALORE": capacita' (WarFeatureType) del giocatore 0 */
            context->map->players[0].features[atoi(a1) / 2] = (u8)atoi(a2);
        }
        else if (!strcmp(cmd, "gold") && context->map)
        {
            /* "gold ORO LEGNA": le risorse del giocatore 0 */
            context->map->players[0].gold = atoi(a1);
            context->map->players[0].wood = atoi(a2);
        }
        else if (!strcmp(cmd, "time") || !strcmp(cmd, "timerender"))
        {
            /* prova delle prestazioni: N fotogrammi (con "timerender" solo il disegno); una riga TIME con minimo, mediana e media in microsecondi */
            int n = atoi(a1);
            int renderOnly = !strcmp(cmd, "timerender");
            double* t = (double*)malloc(sizeof(double) * (size_t)n);
            double sum = 0;
            for (int i = 0; i < n; i++)
            {
                Uint64 t0 = SDL_GetPerformanceCounter();
                if (renderOnly)
                {
                    beginFrame(context);
                    wg_renderGame(context);
                    context->frameCount++;
                }
                else
                {
                    beginFrame(context);
                    wg_updateGame(context);
                    wg_renderGame(context);
                    context->frameCount++;
                }
                Uint64 t1 = SDL_GetPerformanceCounter();
                t[i] = (double)(t1 - t0) * 1e6 / (double)SDL_GetPerformanceFrequency();
                sum += t[i];
                wg_beginInputFrame(context);
            }
            for (int i = 0; i < n; i++) for (int j = i + 1; j < n; j++) if (t[j] < t[i]) { double x = t[i]; t[i] = t[j]; t[j] = x; }
            printf("TIME %s %d min %.1f median %.1f mean %.1f\n", cmd, n, t[0], t[n / 2], sum / n);
            free(t);
        }
        else if (!strcmp(cmd, "hash"))
        {
            printf("H %d %08x\n", context->frameCount, frameHash());
        }
        else if (!strcmp(cmd, "png"))
        {
            stbi_write_png(a1, gLast->w, gLast->h, 4, gLast->pixels, gLast->pitch);
        }
        else if (!strcmp(cmd, "rgba"))
        {
            FILE* o = fopen(a1, "wb");
            for (int y = 0; y < gLast->h; y++) fwrite((Uint8*)gLast->pixels + (size_t)y * gLast->pitch, 1, 4 * gLast->w, o);
            fclose(o);
        }
        else if (!strcmp(cmd, "trace"))
        {
            gTraceOn = !strcmp(a1, "on");
        }
        else
        {
            fprintf(stderr, "comando sconosciuto: %s\n", cmd);
            return 5;
        }
    }
    fflush(stdout);
    return 0;
}
