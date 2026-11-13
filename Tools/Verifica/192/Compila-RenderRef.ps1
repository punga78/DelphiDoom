<#
  Issue #192 (seconda fetta): compila il codice ORIGINALE del remake (acoto87/war1, zlib) che misura e disegna il testo
  (war_font.c), la pila delle trasformazioni e wr_subImage (war_render.c) e crea i WarSprite (war_sprites.c), e lo fa
  girare per produrre i golden di Libs\War. Niente e' modificato in Reference\: gli estratti e il programma stanno in -Out
  (una cartella NUOVA fuori da Reference e dal repository).

  Uso:
    powershell -NoProfile -File Compila-RenderRef.ps1 -Out <cartella> [-War1 <...\Reference\war1>] [-Gcc <gcc.exe>]
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
function Rest([string]$File, [string]$From) {
  $lines = [IO.File]::ReadAllLines($File)
  $a = ($lines | Select-String -SimpleMatch $From | Select-Object -First 1).LineNumber - 1
  if ($a -lt 0) { throw "Inizio non trovato in ${File}: $From" }
  $lines[$a..($lines.Count - 1)]
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

$src = Join-Path $War1 'src'
Put 'war_core.inc' (Slice (Join-Path $src 'war_file.c') '// Safe little-endian integer reads' '// .w1m custom map loading')
Put 'war_types.inc' (Slice (Join-Path $src 'war_resources.h') 'struct _WarRawResource' 'struct _WarLevelUnit')
Put 'war_types2.inc' (Slice (Join-Path $src 'war_resources.h') 'struct _WarLevelUnit' 'WarResource* wres_getOrCreateResource')
$enums = Join-Path $src 'war_enums.h'
Put 'war_enums.inc' (EnumBlock $enums 'DatabaseEntryType')
Put 'war_resource_type.inc' (EnumBlock $enums 'WarResourceType')
Put 'war_database_copy.h' ([IO.File]::ReadAllLines((Join-Path $src 'war_database.h')) | Where-Object { $_ -notmatch '^#include|^#pragma once' })
Put 'war_sprite_frame.inc' (Slice (Join-Path $src 'war_sprites.h') 'struct _WarSpriteFrame' 'struct _WarSprite')

$res = Join-Path $src 'war_resources.c'
Put 'war_read_macros.inc' (Slice $res '#define readu8' 'static void buildRgbaLut')
Put 'war_res_a.inc' (Slice $res 'static void buildRgbaLut' 's32 wres_loadStartEntities')
Put 'war_res_tiles.inc' (Slice $res 'void wres_loadTileset' 'void wres_loadText')
Put 'war_res_cursor.inc' (Slice $res 'void wres_loadCursor' 'void wres_loadResource')

$wanted = 'MAX_RESOURCES_COUNT|MAX_SPRITE_FRAME_COUNT|MAX_CUSTOM_MAP_CONFIGURATIONS_COUNT|PALETTE_LENGTH|MINI_TILE_WIDTH|MINI_TILE_HEIGHT|MEGA_TILE_WIDTH|MEGA_TILE_HEIGHT|TILESET_WIDTH|TILESET_HEIGHT|TILESET_TILES_PER_ROW|MAX_OBJECTIVES_LENGTH|MAX_PLAYERS_COUNT|MAX_FEATURES_COUNT|MAX_UPGRADES_COUNT|MAX_ENTITIES_COUNT|MAX_CONSTRUCTS_COUNT|MAX_CUSTOM_MAP_GOLDMINES_COUNT|MAX_CUSTOM_MAP_ENTITIES_COUNT|MAP_WIDTH|MAP_HEIGHT|MAP_TILES_WIDTH|MAP_TILES_HEIGHT|MAX_RENDER_STATE_STACK'
Put 'war_defines.inc' ([IO.File]::ReadAllLines((Join-Path $src 'war.h')) | Where-Object { $_ -match "^#define ($wanted) " })

Put 'war_render.inc' (Slice (Join-Path $src 'war_render.c') 'void wr_init(WarContext* context)' 'WarColor wr_getColorFromList(s32 index)')
Put 'war_sprites_header.inc' (Slice (Join-Path $src 'war_sprites.h') 'struct _WarSpriteResourceRef' 'WarSprite wspr_createSprite(WarContext* context')
Put 'war_sprites_body.inc' ([IO.File]::ReadAllLines((Join-Path $src 'war_sprites.c')) | Where-Object { $_ -notmatch '^(\xEF\xBB\xBF|\uFEFF)?#include' })
Put 'war_font_defines.inc' ([IO.File]::ReadAllLines((Join-Path $src 'war_font.h')) | Where-Object { $_ -match '^#define (NO_HIGHLIGHT|ALL_HIGHLIGHT|TAB_WIDTH|MAX_LINES) ' })
Put 'war_font_header.inc'(Slice (Join-Path $src 'war_font.h') 'struct _WarFontData' 'WarSprite wfont_loadFontSprite')
Put 'war_font_table.inc' (Slice (Join-Path $src 'war_font.c') 'WarFontData fontsData[2]' 'WarSprite wfont_loadFontSprite')
Put 'war_font_funcs.inc' (Rest (Join-Path $src 'war_font.c') 'WarFontData getFontData(s32 fontIndex)')

Copy-Item (Join-Path $PSScriptRoot 'war_render_ref.c') (Join-Path $Out 'war_render_ref.c')
$ErrorActionPreference = 'Continue'   # gcc scrive gli avvisi su stderr
& $Gcc -O1 -std=gnu11 -o (Join-Path $Out 'war_render_ref.exe') (Join-Path $Out 'war_render_ref.c') "-I$Out" -Wno-unused-function -Wno-int-conversion -Wno-pointer-sign 2>&1 | Out-String
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Out 'war_render_ref.exe'))) { throw 'Compilazione fallita' }
"Compilato: $(Join-Path $Out 'war_render_ref.exe')"
