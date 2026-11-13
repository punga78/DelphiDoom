<#
  Issue #193: compila il codice ORIGINALE del remake (acoto87/war1, zlib) che legge i livelli di DATA.WAR, le
  campagne e le condizioni di vittoria, le tabelle dei raccordi (strade, muri, rovine, alberi) e le funzioni che
  li calcolano, e lo fa girare per produrre i golden di Libs\War. Niente e' modificato in Reference\: si
  leggono i sorgenti e si scrivono estratti e programma in -Out (una cartella NUOVA fuori da Reference e dal repository).

  Uso:
    powershell -NoProfile -File Compila-LevelRef.ps1 -Out <cartella> [-War1 <...\Reference\war1>] [-Gcc <gcc.exe>]

  Estrae alla lettera (per intervalli di righe cercati per testo, non per numero):
    war_file.c      : letture little endian, wfile_loadWarFile, wfile_freeWarFile      (come #191 e #192)
    war_resources.h : le struct dei record                                              (come #192)
    war_enums.h     : DatabaseEntryType, WarResourceType e gli enum che servono (WarRace, WarUnitType, WarResourceKind,
                      WarConstructType, WarCampaignMapType, WarLevelResult, WarAudioId, i tipi dei pezzi)
    war_database.h  : copia intera senza le #include (la tabella assets[])
    war_resources.c : #define readXX; da "static void buildRgbaLut" a "s32 wres_loadStartEntities" (come #192) e da
                      "s32 wres_loadStartEntities" a "void wres_loadTileset" (i livelli: wres_loadLevelInfo,
                      wres_loadLevelVisual, wres_loadLevelPassable e le funzioni che leggono unita', strade, muri)
    war_units.c     : le tabelle roadsData, wallsData, ruinsData, treesData, roadTileTypeMap, wallTileTypeMap,
                      ruinTileTypeMap, treeTileTypeMap, fogTileTypeMap
    war_campaigns.c : il file INTERO (tabella delle campagne, wcamp_tryGetMapType, wcamp_getCampaignData e le tre
                      funzioni delle condizioni di vittoria); gli include sono sostituiti da intestazioni finte in shim\
    war_roads.c, war_walls.c, war_ruins.c, war_trees.c : fino alla funzione we_create* (we_determine*, we_add*...)
    war_map_grid.c  : intero (meno gli include)
  e compila war_lvl_ref.c con gcc (w64devkit). I soli stub sono SDL, Tracy, wm_alloc, il log, le liste di shl e le
  poche funzioni del motore che le funzioni estratte chiamano (conteggi dei giocatori, ricerca delle entita').
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1',
  [string]$Gcc = 'C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin\gcc.exe'
)
$ErrorActionPreference = 'Stop'
if ((Test-Path $Out) -and (Get-ChildItem $Out -Force | Select-Object -First 1)) { throw "La cartella $Out non e' vuota." }
New-Item -ItemType Directory -Force $Out | Out-Null
New-Item -ItemType Directory -Force (Join-Path $Out 'shim') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $Out 'shim\shl') | Out-Null

function Slice([string]$File, [string]$From, [string]$Before) {
  $lines = [IO.File]::ReadAllLines($File)
  $a = ($lines | Select-String -SimpleMatch $From | Select-Object -First 1).LineNumber - 1
  $rest = $lines[($a + 1)..($lines.Count - 1)]
  $bHit = $rest | Select-String -SimpleMatch $Before | Select-Object -First 1
  if ($a -lt 0 -or -not $bHit) { throw "Intervallo non trovato in ${File}: $From .. $Before" }
  $b = $a + 1 + $bHit.LineNumber - 1
  $lines[$a..($b - 1)]
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
foreach ($n in 'WarRace','WarUnitType','WarResourceKind','WarConstructType','WarCampaignMapType','WarLevelResult','WarAudioId',
               'WarRoadPieceType','WarWallPieceType','WarRuinPieceType','WarTreeTileType','WarFogPieceType') {
  Put "enum_$n.inc" (EnumBlock $enums $n)
}
Put 'war_database_copy.h' ([IO.File]::ReadAllLines((Join-Path $src 'war_database.h')) | Where-Object { $_ -notmatch '^#include|^#pragma once' })
Put 'war_sprite_frame.inc' (Slice (Join-Path $src 'war_sprites.h') 'struct _WarSpriteFrame' 'struct _WarSprite')

$res = Join-Path $src 'war_resources.c'
Put 'war_read_macros.inc' (Slice $res '#define readu8' 'static void buildRgbaLut')
Put 'war_res_a.inc' (Slice $res 'static void buildRgbaLut' 's32 wres_loadStartEntities')
Put 'war_res_levels.inc' (Slice $res 's32 wres_loadStartEntities' 'void wres_loadTileset')

$wanted = 'MAX_RESOURCES_COUNT|MAX_SPRITE_FRAME_COUNT|MAX_CUSTOM_MAP_CONFIGURATIONS_COUNT|PALETTE_LENGTH|MINI_TILE_WIDTH|MINI_TILE_HEIGHT|MEGA_TILE_WIDTH|MEGA_TILE_HEIGHT|TILESET_WIDTH|TILESET_HEIGHT|TILESET_TILES_PER_ROW|MAX_OBJECTIVES_LENGTH|MAX_PLAYERS_COUNT|MAX_FEATURES_COUNT|MAX_UPGRADES_COUNT|MAX_ENTITIES_COUNT|MAX_CONSTRUCTS_COUNT|MAX_CUSTOM_MAP_GOLDMINES_COUNT|MAX_CUSTOM_MAP_ENTITIES_COUNT|MAP_WIDTH|MAP_HEIGHT|MAP_TILES_WIDTH|MAP_TILES_HEIGHT'
Put 'war_defines.inc' ([IO.File]::ReadAllLines((Join-Path $src 'war.h')) | Where-Object { $_ -match "^#define ($wanted) " })

$units = Join-Path $src 'war_units.c'
$tables = @()
foreach ($t in 'const WarRoadData roadsData[]','const WarWallData wallsData[]','const WarRuinData ruinsData[]','const WarTreeData treesData[]',
               'const WarRoadPieceType roadTileTypeMap[16]','const WarWallPieceType wallTileTypeMap[16]',
               'const WarRuinPieceType ruinTileTypeMap[256]','const WarTreeTileType treeTileTypeMap[256]',
               'const WarFogPieceType fogTileTypeMap[256]') {
  $tables += (Table $units $t)
}
Put 'war_tables.inc' $tables

# le funzioni estratte dei pezzi (fino alla creazione dell'entita')
Put 'war_roads.inc' (Slice (Join-Path $src 'war_roads.c') 'bool we_hasRoadPieceAtPosition' 'WarEntity* we_createRoad')
$ruinLines = [IO.File]::ReadAllLines((Join-Path $src 'war_ruins.c'))
$rt = ($ruinLines | Select-String -SimpleMatch 'void we_addRuinsPieces' | Select-Object -First 1).LineNumber - 1
Put 'war_ruins_tail.inc' $ruinLines[$rt..($ruinLines.Count - 1)]
Put 'war_walls.inc'(Slice (Join-Path $src 'war_walls.c') 'bool we_hasWallPieceAtPosition' 'WarEntity* we_createWall')
Put 'war_ruins.inc' (Slice (Join-Path $src 'war_ruins.c') 'bool we_hasRuinPieceAtPosition' 'WarEntity* we_createRuins')
Put 'war_trees.inc' (Slice (Join-Path $src 'war_trees.c') 'bool we_hasTreeAtPosition' 'WarTree* we_findAccesibleTree')
$treeTail = Slice (Join-Path $src 'war_trees.c') 'bool we_validTree' 'void we_takeTreeDown'
Put 'war_trees_valid.inc' $treeTail
Put 'war_map_grid.inc' ([IO.File]::ReadAllLines((Join-Path $src 'war_map_grid.c')) | Where-Object { $_ -notmatch '^#include' })

# war_campaigns.c intero, senza BOM
(Get-Content (Join-Path $src 'war_campaigns.c') -Raw -Encoding UTF8) | Set-Content (Join-Path $Out 'war_campaigns_orig.c') -Encoding ASCII

# intestazioni finte per war_campaigns.c
Set-Content (Join-Path $Out 'shim\war_campaigns.h') '/* shim */' -Encoding ASCII
Set-Content (Join-Path $Out 'shim\war_entities.h') '/* shim */' -Encoding ASCII
Set-Content (Join-Path $Out 'shim\war_units.h') '/* shim */' -Encoding ASCII
Set-Content (Join-Path $Out 'shim\shl\wstr.h') '/* shim */' -Encoding ASCII

Copy-Item (Join-Path $PSScriptRoot 'war_lvl_ref.c') (Join-Path $Out 'war_lvl_ref.c')

$ErrorActionPreference = 'Continue'   # gcc scrive gli avvisi su stderr
& $Gcc -O1 -std=gnu11 -o (Join-Path $Out 'war_lvl_ref.exe') (Join-Path $Out 'war_lvl_ref.c') "-I$Out" "-I$(Join-Path $Out 'shim')" -Wno-unused-function -Wno-int-conversion -Wno-pointer-sign 2>&1 | Out-String
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Out 'war_lvl_ref.exe'))) { throw 'Compilazione fallita' }
"Compilato: $(Join-Path $Out 'war_lvl_ref.exe')"
