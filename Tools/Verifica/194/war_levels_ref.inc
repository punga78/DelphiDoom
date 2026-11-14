/*
  Issue #195: percorsi sui livelli veri di DATA.WAR (incluso da war_model_ref.c dopo war_path_ref.inc).

  Il file si legge con wfile_loadWarFile ORIGINALE (war_file.c incluso intero: directory, decompressione) e le mappe dei passaggi
  dei livelli sono i record DB_ENTRY_TYPE_LEVEL_PASSABLE di assets[] (war_database.h originale), letti come
  wres_loadLevelPassable li legge (readu16 su i * 2). I soli stub sono i quattro SDL_*IO* di war_file.c, scritti con fopen.
  Su ogni mappa girano le funzioni vere di war_pathfinder.c: A star su coppie di caselle e campi di flusso.

  Uso:  war_model_ref levelpaths DATA.WAR      una riga per ricerca (A) e per campo (F), come `paths`
*/
#include "war_database.h"
#include "war_file.c"

/* la macro di war_resources.c (riga 19) con cui wres_loadLevelPassable legge i 4096 passaggi */
#define readu16(arr, index) (*(u16*)((arr) + (index)))

SDL_IOStream* SDL_IOFromFile(const char* file, const char* mode) { return (SDL_IOStream*)fopen(file, mode); }
Sint64 SDL_GetIOSize(SDL_IOStream* context)
{
    FILE* f = (FILE*)context;
    long here = ftell(f);
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, here, SEEK_SET);
    return (Sint64)size;
}
size_t SDL_ReadIO(SDL_IOStream* context, void* ptr, size_t size) { return fread(ptr, 1, size, (FILE*)context); }
bool SDL_CloseIO(SDL_IOStream* context) { return fclose((FILE*)context) == 0; }
const char* SDL_GetError(void) { return "errore di lettura"; }

#define LEVEL_ASTARS 8
#define LEVEL_FIELDS 3

static void runLevelPaths(const char* dataWar)
{
    wm_allocInit(256ull * 1024 * 1024, 8ull * 1024 * 1024, 1ull * 1024 * 1024);
    gRealPaths = 1;
    static bool skip[MAX_RESOURCES_COUNT];
    for (s32 i = 0; i < MAX_RESOURCES_COUNT; i++)
        skip[i] = true;
    s32 total = (s32)(sizeof(assets) / sizeof(assets[0]));
    for (s32 a = 0; a < total; a++)
        if (assets[a].type == DB_ENTRY_TYPE_LEVEL_PASSABLE && assets[a].index < MAX_RESOURCES_COUNT)
            skip[assets[a].index] = false;
    WarContext context;
    memset(&context, 0, sizeof(context));
    WarFile* warFile = wfile_loadWarFile(&context, wsv_fromCString(dataWar), skip);
    if (!warFile)
    {
        fprintf(stderr, "DATA.WAR non letto\n");
        exit(2);
    }
    gMap = (WarMap*)wm_alloc(sizeof(WarMap));
    for (s32 a = 0; a < total; a++)
    {
        if (assets[a].type != DB_ENTRY_TYPE_LEVEL_PASSABLE)
            continue;
        WarRawResource raw = warFile->resources[assets[a].index];
        if (raw.placeholder)
        {
            printf("L %d placeholder\n", assets[a].index);
            continue;
        }
        u16 passable[MAP_TILES_WIDTH * MAP_TILES_HEIGHT];
        for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
            passable[i] = readu16(raw.data, i * 2);
        memset(gMap, 0, sizeof(WarMap));
        gMap->finder = wpath_initPathFinder(passable);
        gScriptState = (u32)assets[a].index * 2654435761u + 9090u;
        s32 statics = 0;
        for (s32 i = 0; i < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; i++)
            if (gMap->finder.data[i] != 0)
                statics++;
        printf("L %d statics=%d\n", assets[a].index, statics);
        for (s32 i = 0; i < LEVEL_ASTARS; i++)
        {
            s32 sx = (s32)scriptBelow(MAP_TILES_WIDTH), sy = (s32)scriptBelow(MAP_TILES_HEIGHT);
            s32 ex = (s32)scriptBelow(MAP_TILES_WIDTH), ey = (s32)scriptBelow(MAP_TILES_HEIGHT);
            memset(&gPathResult, 0, sizeof(gPathResult));
            wpath_astar(&gMap->finder, sx, sy, ex, ey, &gPathResult);
            printf("A %d %d %d,%d,%d,%d n=%d h=%08x\n", assets[a].index, i, sx, sy, ex, ey, gPathResult.count,
                   pathHashNodes(&gPathResult));
        }
        for (s32 j = 0; j < LEVEL_FIELDS; j++)
        {
            s32 gx = (s32)scriptBelow(MAP_TILES_WIDTH), gy = (s32)scriptBelow(MAP_TILES_HEIGHT);
            WarMapFlowField* field = wpath_computeFlowField(&gMap->finder, gx, gy);
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
            printf("F %d %d %d,%d reach=%d max=%d c=%08x d=%08x\n", assets[a].index, j, gx, gy, reach, maxCost, hc, hd);
        }
        /* i campi di questo livello non servono ai prossimi: la mappa si rifa */
        for (s32 k = 0; k < MAP_TILES_WIDTH * MAP_TILES_HEIGHT; k++)
            if (gMap->finder.fields[k])
            {
                wm_free(gMap->finder.fields[k]);
                gMap->finder.fields[k] = NULL;
            }
    }
    gRealPaths = 0;
    wm_allocFree();
    gMap = NULL;
}
