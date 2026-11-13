<#
  Issue #193 (seconda fetta): compila il codice ORIGINALE del remake (acoto87/war1, zlib) che istanzia un livello in
  una mappa di gioco (wmap_enterMap: percorso, tegole, minimappa, boschi, strade, muri, rovine, giocatori e unita'
  iniziali), il fog of war (updateFoW, determineFoWTypes), la minimappa (renderMinimap) e gli alberi (war_trees.c
  intero: piantare, abbattere, tagliare, cercare un albero raggiungibile). Niente e' modificato in Reference\: gli
  estratti e il programma stanno in -Out (una cartella NUOVA fuori da Reference e dal repository).

  Uso:
    powershell -NoProfile -File Compila-MapRef.ps1 -Out <cartella> [-War1 <...\Reference\war1>] [-Gcc <gcc.exe>]

  Estratti alla lettera (per testo, non per numero di riga): war_file.c (lettore), war_resources.h/.c (struct, palette,
  tiles, tileset, livelli), war_enums.h (enum), war_database.h, war_units.c (tabelle e le funzioni wu_* che servono),
  war_pathfinder.c (le funzioni wpath_* della griglia), war_map.c (da wmap_getMapTileState a prima di
  wmap_getMapScaledTime, le funzioni init* e create* di wmap_enterMap, updateFoW, determineFoWTypes), war_entities.c
  (we_createUnit e il ciclo di renderMinimap), war_roads.c, war_walls.c, war_ruins.c, war_trees.c (interi).
  Gli stub (war_map_ref.c): SDL, Tracy, log, liste, il gestore delle entita', gli stati degli stati, we_setInitialIdleState
  (le due righe di wst_enterIdleState che occupano la griglia) e il sorteggio della direzione di un'unita' (a 0).
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1',
  [string]$Gcc = 'C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin\gcc.exe'
)
$ErrorActionPreference = 'Stop'
if ((Test-Path $Out) -and (Get-ChildItem $Out -Force | Select-Object -First 1)) { throw "La cartella $Out non e' vuota." }
New-Item -ItemType Directory -Force $Out | Out-Null

function Slice([string]$File, [string]$From, [string]$Before) {
  $lines = [IO.File]::ReadAllLines($File)
  $a = ($lines | Select-String -SimpleMatch $From | Select-Object -First 1).LineNumber - 1
  if ($a -lt 0) { throw "Inizio non trovato in ${File}: $From" }
  $rest = $lines[($a + 1)..($lines.Count - 1)]
  $bHit = $rest | Select-String -SimpleMatch $Before | Select-Object -First 1
  if (-not $bHit) { throw "Fine non trovata in ${File}: $Before" }
  $b = $a + 1 + $bHit.LineNumber - 1
  $lines[$a..($b - 1)]
}
# una funzione: dalla riga con la firma alla prima riga "}" a colonna 0
function Fn([string]$File, [string]$Sig) {
  $lines = [IO.File]::ReadAllLines($File)
  $a = ($lines | Select-String -SimpleMatch $Sig | Select-Object -First 1).LineNumber - 1
  if ($a -lt 0) { throw "Funzione non trovata in ${File}: $Sig" }
  $b = $a
  while ($lines[$b] -ne '}') { $b++ }
  $lines[$a..$b]
}
function Put([string]$Name, $Lines) { $Lines | Set-Content (Join-Path $Out $Name) -Encoding ASCII }
function EnumBlock([string]$File, [string]$Name) {
  $lines = [IO.File]::ReadAllLines($File)
  $e = ($lines | Select-String -SimpleMatch "} $Name;" | Select-Object -First 1).LineNumber - 1
  if ($e -lt 0) { throw "Enum $Name non trovato" }
  $s = $e
  while ($s -ge 0 -and $lines[$s] -notmatch '^typedef enum') { $s-- }
  $lines[$s..$e]
}
function Table([string]$File, [string]$Start) {
  $lines = [IO.File]::ReadAllLines($File)
  $a = ($lines | Select-String -SimpleMatch $Start | Select-Object -First 1).LineNumber - 1
  if ($a -lt 0) { throw "Tabella non trovata: $Start" }
  $b = $a
  while ($lines[$b] -ne '};') { $b++ }
  $lines[$a..$b]
}

$src = Join-Path $War1 'src'
Put 'war_core.inc' (Slice (Join-Path $src 'war_file.c') '// Safe little-endian integer reads' '// .w1m custom map loading')
Put 'war_types.inc' (Slice (Join-Path $src 'war_resources.h') 'struct _WarRawResource' 'struct _WarLevelUnit')
Put 'war_types2.inc' (Slice (Join-Path $src 'war_resources.h') 'struct _WarLevelUnit' 'WarResource* wres_getOrCreateResource')
$enums = Join-Path $src 'war_enums.h'
Put 'war_enums.inc' (EnumBlock $enums 'DatabaseEntryType')
Put 'war_resource_type.inc' (EnumBlock $enums 'WarResourceType')
foreach ($n in 'WarRace','WarDirection','WarUnitType','WarResourceKind','WarConstructType','WarCampaignMapType','WarLevelResult','WarAudioId',
               'WarEntityType','WarRoadPieceType','WarWallPieceType','WarRuinPieceType','WarTreeTileType','WarPathFinderDataType',
               'WarMapTilesetType','WarFogPieceType','WarFogBoundaryType','WarUnitPortraits','WarMapTileState') {
  Put "enum_$n.inc" (EnumBlock $enums $n)
}
Put 'war_database_copy.h' ([IO.File]::ReadAllLines((Join-Path $src 'war_database.h')) | Where-Object { $_ -notmatch '^#include|^#pragma once' })
Put 'war_sprite_frame.inc' (Slice (Join-Path $src 'war_sprites.h') 'struct _WarSpriteFrame' 'struct _WarSprite')

$res = Join-Path $src 'war_resources.c'
Put 'war_read_macros.inc' (Slice $res '#define readu8' 'static void buildRgbaLut')
Put 'war_res_a.inc' (Slice $res 'static void buildRgbaLut' 's32 wres_loadStartEntities')
Put 'war_res_levels.inc' (Slice $res 's32 wres_loadStartEntities' 'void wres_loadTileset')
Put 'war_res_tiles.inc' (Slice $res 'void wres_loadTileset' 'void wres_loadText')

$wanted = 'MAX_RESOURCES_COUNT|MAX_SPRITE_FRAME_COUNT|MAX_CUSTOM_MAP_CONFIGURATIONS_COUNT|PALETTE_LENGTH|MINI_TILE_WIDTH|MINI_TILE_HEIGHT|MEGA_TILE_WIDTH|MEGA_TILE_HEIGHT|TILESET_WIDTH|TILESET_HEIGHT|TILESET_TILES_PER_ROW|MAX_OBJECTIVES_LENGTH|MAX_PLAYERS_COUNT|MAX_FEATURES_COUNT|MAX_UPGRADES_COUNT|MAX_ENTITIES_COUNT|MAX_CONSTRUCTS_COUNT|MAX_CUSTOM_MAP_GOLDMINES_COUNT|MAX_CUSTOM_MAP_ENTITIES_COUNT|MAP_WIDTH|MAP_HEIGHT|MAP_TILES_WIDTH|MAP_TILES_HEIGHT|MINIMAP_WIDTH|MINIMAP_HEIGHT|MAP_VIEWPORT_WIDTH|MAP_VIEWPORT_HEIGHT|TREE_MAX_WOOD'
Put 'war_defines.inc' ([IO.File]::ReadAllLines((Join-Path $src 'war.h')) | Where-Object { $_ -match "^#define ($wanted) " })
Put 'war_wall_hp.inc' ([IO.File]::ReadAllLines((Join-Path $src 'war_units.h')) | Where-Object { $_ -match '^#define (WAR_WALL_MAX_HP|__bts)' })

$units = Join-Path $src 'war_units.c'
$tables = @()
foreach ($t in 'const WarUnitData unitsData[]','const WarUnitStats unitStats[]','const WarBuildingStats buildingStats[]',
               'const WarRoadData roadsData[]','const WarWallData wallsData[]','const WarRuinData ruinsData[]','const WarTreeData treesData[]',
               'const WarRoadPieceType roadTileTypeMap[16]','const WarWallPieceType wallTileTypeMap[16]',
               'const WarRuinPieceType ruinTileTypeMap[256]','const WarTreeTileType treeTileTypeMap[256]',
               'const WarFogPieceType fogTileTypeMap[256]') {
  $tables += (Table $units $t)
}
Put 'war_tables.inc' $tables
$u = @()
foreach ($f in 'bool wu_isUnit(const WarEntity* entity)','bool wu_isDudeUnitType(WarUnitType type)','bool wu_isBuildingUnitType(WarUnitType type)',
               'bool wu_isSummonUnitType(WarUnitType type)','bool wu_isCorpseUnitType(WarUnitType type)',
               'bool wu_isDudeUnit(WarContext* context, WarEntity* entity)','bool wu_isBuildingUnit(WarContext* context, WarEntity* entity)',
               'bool wu_isSummonUnit(WarContext* context, WarEntity* entity)','bool wu_isCorpseUnit(WarContext* context, WarEntity* entity)',
               'vec2 wu_getUnitSize(WarContext* context, WarEntity* entity)','vec2 wu_getUnitPosition(WarContext* context, WarEntity* entity)',
               'vec2 wu_getUnitTile(WarContext* context, WarEntity* entity)','rect wu_getUnitRectTiles(WarContext* context, WarEntity* entity)',
               's32 wu_getUnitSightRange(WarContext* context, WarEntity* entity)','bool wu_isFriendlyUnit(WarContext* context, WarEntity* entity)',
               'bool wu_displayUnitOnMinimap(WarContext* context, WarEntity* entity)',
               'WarColor wu_getUnitColorOnMinimap(WarContext* context, WarEntity* entity)') {
  $u += (Fn $units $f); $u += ''
}
Put 'war_wu_funcs.inc' $u
$find = [IO.File]::ReadAllLines($units)
$fa = ($find | Select-String -SimpleMatch '#define FIND_BY_TYPE' | Select-Object -First 1).LineNumber - 1
$fb = $fa; while ($find[$fb] -ne '    return &array[index];') { $fb++ }
Put 'war_find_by_type.inc' $find[$fa..$fb]
$g = @()
foreach ($f in 'const WarUnitData* wu_getUnitData(WarUnitType type)','const WarUnitStats* wu_getUnitStats(WarUnitType type)',
               'const WarBuildingStats* wu_getBuildingStats(WarUnitType type)','const WarTreeData* wu_getTreeData(WarTreeTileType type)') {
  $g += (Fn $units $f); $g += ''
}
Put 'war_wu_getters.inc' $g

# il percorso
$pf = Join-Path $src 'war_pathfinder.c'
$p = @((Slice $pf "static const s32 wpath_dirC" "static const s32 wpath_dirY" ) + ([IO.File]::ReadAllLines($pf) | Where-Object { $_ -match "^static const s32 wpath_dirY" }))
foreach ($f in 'WarPathFinder wpath_initPathFinder','bool wpath_isInside','bool wpath_isTileAccesible','u16 wpath_getTileValue','void wpath_setTilesValue',
               'void wpath_setFreeTiles','void wpath_setStaticEntity','WarPathFinderDataType wpath_getTileValueType','WarEntityId wpath_getTileEntityId',
               'bool wpath_isEmpty','bool wpath_isStatic') {
  $p += (Fn $pf $f); $p += ''
}
Put 'war_path.inc' $p

# la mappa
$mp = Join-Path $src 'war_map.c'
Put 'war_map_tile.inc' (Fn $mp 'vec2 wmap_mapToTileCoordinatesV(vec2 v)')
Put 'war_map_state.inc' (Slice $mp 'WarMapTile* wmap_getMapTileState' 'f32 wmap_getMapScaledTime')
Put 'war_map_init.inc' (Slice $mp 'static void initCamera' 'void wmap_addEntityToSelection')
Put 'war_map_fog.inc' ((Fn $mp 'void updateFoW(WarContext* context)') + '' + (Fn $mp 'void determineFoWTypes(WarContext* context)'))

# le entita'
$en = Join-Path $src 'war_entities.c'
Put 'war_create_unit.inc' (Fn $en 'WarEntity* we_createUnit(WarContext* context, const CreateUnitArgs* args)')
Put 'war_minimap_loop.inc' (Slice $en '    // copy the minimap base to the first frame' '    wr_save(context);')

Put 'war_roads.inc' (Slice (Join-Path $src 'war_roads.c') 'bool we_hasRoadPieceAtPosition' 'WarEntity* we_createRoad')
$ruinLines = [IO.File]::ReadAllLines((Join-Path $src 'war_ruins.c'))
$rt = ($ruinLines | Select-String -SimpleMatch 'void we_addRuinsPieces' | Select-Object -First 1).LineNumber - 1
Put 'war_ruins_tail.inc' $ruinLines[$rt..($ruinLines.Count - 1)]
Put 'war_walls.inc' (Slice (Join-Path $src 'war_walls.c') 'bool we_hasWallPieceAtPosition' 'WarEntity* we_createWall')
Put 'war_ruins.inc' (Slice (Join-Path $src 'war_ruins.c') 'bool we_hasRuinPieceAtPosition' 'WarEntity* we_createRuins')
Put 'war_create_road.inc' (Fn (Join-Path $src 'war_roads.c') 'WarEntity* we_createRoad(WarContext* context)')
Put 'war_create_wall.inc' (Fn (Join-Path $src 'war_walls.c') 'WarEntity* we_createWall(WarContext* context)')
Put 'war_create_ruins.inc' (Fn (Join-Path $src 'war_ruins.c') 'WarEntity* we_createRuins(WarContext* context)')
Put 'war_trees.inc' ([IO.File]::ReadAllLines((Join-Path $src 'war_trees.c')) | Where-Object { $_ -notmatch '^#include' })

Copy-Item (Join-Path $PSScriptRoot 'war_map_ref.c') (Join-Path $Out 'war_map_ref.c')
$ErrorActionPreference = 'Continue'   # gcc scrive gli avvisi su stderr
& $Gcc -O1 -std=gnu11 -o (Join-Path $Out 'war_map_ref.exe') (Join-Path $Out 'war_map_ref.c') "-I$Out" -Wno-unused-function -Wno-int-conversion -Wno-pointer-sign 2>&1 | Out-String
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Out 'war_map_ref.exe'))) { throw 'Compilazione fallita' }
"Compilato: $(Join-Path $Out 'war_map_ref.exe')"
